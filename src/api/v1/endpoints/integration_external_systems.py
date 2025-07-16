"""
Enterprise Integration API - Task 73: External System Integration Management
GET /api/v1/integration/external/systems

Features:
- System discovery and health monitoring
- API versioning and connection pooling
- Integration configuration management
- Database: external_systems, integration_configs, api_mappings
"""

from fastapi import APIRouter, HTTPException, Depends, Query, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, HttpUrl, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime, timedelta
from enum import Enum
import asyncpg
import asyncio
import json
import uuid
import aiohttp
import ssl
from urllib.parse import urlparse

# Database connection
from ...core.database import get_db_connection

security = HTTPBearer()

router = APIRouter(prefix="/api/v1/integration/external", tags=["Enterprise Integration - External Systems"])

class SystemType(str, Enum):
    HR_SYSTEM = "hr_system"
    CONTACT_CENTER = "contact_center"
    CHAT_PLATFORM = "chat_platform"
    ERP = "erp"
    CRM = "crm"
    TELEPHONY = "telephony"
    REPORTING = "reporting"
    CUSTOM = "custom"

class ConnectionStatus(str, Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    DEGRADED = "degraded"
    UNKNOWN = "unknown"

class APIVersion(str, Enum):
    V1 = "v1"
    V2 = "v2"
    V3 = "v3"
    LEGACY = "legacy"

class AuthenticationType(str, Enum):
    JWT = "jwt"
    API_KEY = "api_key"
    BASIC = "basic"
    OAUTH2 = "oauth2"
    CERTIFICATE = "certificate"
    NONE = "none"

class ExternalSystemResponse(BaseModel):
    """External system information response"""
    system_id: str
    name: str
    system_type: SystemType
    description: Optional[str] = None
    base_url: str
    api_version: str
    status: ConnectionStatus
    health_score: float
    last_health_check: Optional[datetime] = None
    response_time_ms: Optional[int] = None
    uptime_percentage: float
    total_requests_24h: int
    failed_requests_24h: int
    connection_pool_size: int
    active_connections: int
    rate_limit_per_minute: Optional[int] = None
    capabilities: List[str]
    supported_operations: List[str]
    metadata: Dict[str, Any]
    created_at: datetime
    updated_at: datetime

class SystemDiscoveryRequest(BaseModel):
    """System discovery request"""
    name: str
    system_type: SystemType
    base_url: HttpUrl
    authentication: Dict[str, Any]
    discovery_endpoints: List[str] = ["/health", "/status", "/api/info", "/version"]
    timeout_seconds: int = 30
    
class IntegrationConfig(BaseModel):
    """Integration configuration"""
    config_id: str
    system_id: str
    config_name: str
    config_type: str
    configuration: Dict[str, Any]
    active: bool
    created_at: datetime
    updated_at: datetime

class APIMapping(BaseModel):
    """API mapping configuration"""
    mapping_id: str
    system_id: str
    local_endpoint: str
    remote_endpoint: str
    method: str
    request_transform: Optional[Dict[str, Any]] = None
    response_transform: Optional[Dict[str, Any]] = None
    active: bool
    created_at: datetime

async def verify_enterprise_auth(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Verify enterprise authentication"""
    token = credentials.credentials
    if not token or len(token) < 20:
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    return token

async def discover_system_capabilities(base_url: str, auth_config: Dict[str, Any], 
                                     discovery_endpoints: List[str], timeout: int) -> Dict[str, Any]:
    """Discover external system capabilities"""
    capabilities = []
    metadata = {}
    api_version = "unknown"
    
    try:
        # Setup authentication headers
        headers = {"User-Agent": "WFM-Enterprise-Discovery/1.0"}
        
        if auth_config.get("type") == "api_key":
            headers[auth_config.get("header", "Authorization")] = f"Bearer {auth_config.get('key')}"
        elif auth_config.get("type") == "basic":
            import base64
            credentials = base64.b64encode(f"{auth_config.get('username')}:{auth_config.get('password')}".encode()).decode()
            headers["Authorization"] = f"Basic {credentials}"
        
        timeout_config = aiohttp.ClientTimeout(total=timeout)
        
        async with aiohttp.ClientSession(timeout=timeout_config) as session:
            # Try discovery endpoints
            for endpoint in discovery_endpoints:
                try:
                    full_url = f"{base_url.rstrip('/')}{endpoint}"
                    async with session.get(full_url, headers=headers) as response:
                        if response.status == 200:
                            data = await response.json()
                            
                            # Extract capabilities
                            if "capabilities" in data:
                                capabilities.extend(data["capabilities"])
                            
                            # Extract version
                            if "version" in data:
                                api_version = data["version"]
                            elif "api_version" in data:
                                api_version = data["api_version"]
                            
                            # Store metadata
                            metadata[endpoint] = data
                            
                except Exception:
                    continue
            
            # Try to discover API endpoints through common patterns
            api_discovery_paths = ["/api", "/api/v1", "/api/v2", "/swagger.json", "/openapi.json"]
            for path in api_discovery_paths:
                try:
                    full_url = f"{base_url.rstrip('/')}{path}"
                    async with session.get(full_url, headers=headers) as response:
                        if response.status == 200:
                            data = await response.json()
                            if "paths" in data:  # OpenAPI/Swagger format
                                capabilities.extend(list(data["paths"].keys()))
                            metadata[f"discovery_{path}"] = data
                except Exception:
                    continue
    
    except Exception as e:
        metadata["discovery_error"] = str(e)
    
    return {
        "capabilities": list(set(capabilities)),
        "api_version": api_version,
        "metadata": metadata
    }

async def check_system_health(conn: asyncpg.Connection, system_id: str) -> Dict[str, Any]:
    """Check system health and update metrics"""
    
    # Get system configuration
    system = await conn.fetchrow("""
        SELECT system_id, base_url, authentication, health_check_endpoint, timeout_seconds
        FROM external_systems WHERE system_id = $1 AND active = true
    """, system_id)
    
    if not system:
        return {"status": "unknown", "error": "System not found"}
    
    start_time = datetime.utcnow()
    health_data = {
        "status": "unknown",
        "response_time_ms": None,
        "error": None,
        "details": {}
    }
    
    try:
        auth_config = json.loads(system['authentication']) if system['authentication'] else {}
        health_endpoint = system['health_check_endpoint'] or "/health"
        base_url = system['base_url']
        timeout = system['timeout_seconds'] or 30
        
        # Setup headers
        headers = {"User-Agent": "WFM-Enterprise-Health-Check/1.0"}
        if auth_config.get("type") == "api_key":
            headers[auth_config.get("header", "Authorization")] = f"Bearer {auth_config.get('key')}"
        
        timeout_config = aiohttp.ClientTimeout(total=timeout)
        
        async with aiohttp.ClientSession(timeout=timeout_config) as session:
            health_url = f"{base_url.rstrip('/')}{health_endpoint}"
            
            async with session.get(health_url, headers=headers) as response:
                end_time = datetime.utcnow()
                response_time = int((end_time - start_time).total_seconds() * 1000)
                
                health_data["response_time_ms"] = response_time
                
                if response.status == 200:
                    health_data["status"] = "connected"
                    try:
                        response_data = await response.json()
                        health_data["details"] = response_data
                    except:
                        health_data["details"] = {"text": await response.text()}
                elif response.status in [500, 502, 503, 504]:
                    health_data["status"] = "degraded"
                    health_data["error"] = f"HTTP {response.status}"
                else:
                    health_data["status"] = "disconnected"
                    health_data["error"] = f"HTTP {response.status}"
    
    except asyncio.TimeoutError:
        health_data["status"] = "disconnected"
        health_data["error"] = "Connection timeout"
    except Exception as e:
        health_data["status"] = "disconnected"
        health_data["error"] = str(e)
    
    # Update health metrics in database
    await conn.execute("""
        UPDATE external_systems 
        SET last_health_check = $1, current_status = $2, 
            last_response_time_ms = $3, health_details = $4
        WHERE system_id = $5
    """, datetime.utcnow(), health_data["status"], 
    health_data["response_time_ms"], json.dumps(health_data["details"]), system_id)
    
    # Log health check
    await conn.execute("""
        INSERT INTO system_health_logs (
            log_id, system_id, check_time, status, response_time_ms, details
        ) VALUES ($1, $2, $3, $4, $5, $6)
    """, str(uuid.uuid4()), system_id, datetime.utcnow(), 
    health_data["status"], health_data["response_time_ms"], json.dumps(health_data))
    
    return health_data

async def calculate_system_metrics(conn: asyncpg.Connection, system_id: str) -> Dict[str, Any]:
    """Calculate system performance metrics"""
    
    # Get 24-hour metrics
    since_24h = datetime.utcnow() - timedelta(hours=24)
    
    metrics = await conn.fetchrow("""
        SELECT 
            COUNT(*) as total_requests,
            COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_requests,
            AVG(CASE WHEN response_time_ms IS NOT NULL THEN response_time_ms END) as avg_response_time,
            COUNT(CASE WHEN status = 'connected' THEN 1 END) * 100.0 / COUNT(*) as uptime_percentage
        FROM system_health_logs 
        WHERE system_id = $1 AND check_time > $2
    """, system_id, since_24h)
    
    if not metrics:
        return {
            "total_requests_24h": 0,
            "failed_requests_24h": 0,
            "avg_response_time_ms": 0,
            "uptime_percentage": 0.0
        }
    
    return {
        "total_requests_24h": metrics['total_requests'] or 0,
        "failed_requests_24h": metrics['failed_requests'] or 0,
        "avg_response_time_ms": int(metrics['avg_response_time']) if metrics['avg_response_time'] else 0,
        "uptime_percentage": float(metrics['uptime_percentage']) if metrics['uptime_percentage'] else 0.0
    }

@router.get("/systems", response_model=List[ExternalSystemResponse])
async def list_external_systems(
    system_type: Optional[SystemType] = Query(None, description="Filter by system type"),
    status: Optional[ConnectionStatus] = Query(None, description="Filter by connection status"),
    include_metrics: bool = Query(True, description="Include performance metrics"),
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    List external systems with monitoring and health status
    
    - System discovery and registration
    - Real-time health monitoring
    - Performance metrics and analytics
    - Connection pool status
    """
    
    conn = await get_db_connection()
    try:
        # Build query with filters
        query = """
            SELECT 
                es.system_id, es.name, es.system_type, es.description,
                es.base_url, es.api_version, es.current_status,
                es.last_health_check, es.last_response_time_ms,
                es.connection_pool_size, es.active_connections,
                es.rate_limit_per_minute, es.capabilities, es.supported_operations,
                es.metadata, es.created_at, es.updated_at
            FROM external_systems es
            WHERE es.active = true
        """
        
        params = []
        param_count = 0
        
        if system_type:
            param_count += 1
            query += f" AND es.system_type = ${param_count}"
            params.append(system_type.value)
        
        if status:
            param_count += 1
            query += f" AND es.current_status = ${param_count}"
            params.append(status.value)
        
        query += " ORDER BY es.name"
        
        systems = await conn.fetch(query, *params)
        
        results = []
        for system in systems:
            # Calculate metrics if requested
            metrics = {}
            if include_metrics:
                metrics = await calculate_system_metrics(conn, system['system_id'])
            
            # Calculate health score based on uptime and response time
            health_score = 1.0
            if metrics.get('uptime_percentage') is not None:
                health_score = metrics['uptime_percentage'] / 100.0
                
                # Adjust for response time
                if metrics.get('avg_response_time_ms', 0) > 1000:
                    health_score *= 0.8  # Penalty for slow response
                elif metrics.get('avg_response_time_ms', 0) > 5000:
                    health_score *= 0.5  # Larger penalty for very slow response
            
            results.append(ExternalSystemResponse(
                system_id=system['system_id'],
                name=system['name'],
                system_type=SystemType(system['system_type']),
                description=system['description'],
                base_url=system['base_url'],
                api_version=system['api_version'] or "unknown",
                status=ConnectionStatus(system['current_status']) if system['current_status'] else ConnectionStatus.UNKNOWN,
                health_score=round(health_score, 3),
                last_health_check=system['last_health_check'],
                response_time_ms=system['last_response_time_ms'],
                uptime_percentage=metrics.get('uptime_percentage', 0.0),
                total_requests_24h=metrics.get('total_requests_24h', 0),
                failed_requests_24h=metrics.get('failed_requests_24h', 0),
                connection_pool_size=system['connection_pool_size'] or 10,
                active_connections=system['active_connections'] or 0,
                rate_limit_per_minute=system['rate_limit_per_minute'],
                capabilities=json.loads(system['capabilities']) if system['capabilities'] else [],
                supported_operations=json.loads(system['supported_operations']) if system['supported_operations'] else [],
                metadata=json.loads(system['metadata']) if system['metadata'] else {},
                created_at=system['created_at'],
                updated_at=system['updated_at']
            ))
        
        return results
        
    finally:
        await conn.close()

@router.post("/systems/discover")
async def discover_external_system(
    discovery_request: SystemDiscoveryRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    Discover and register new external system
    
    - Automatic capability detection
    - API version discovery
    - Health check configuration
    - Security validation
    """
    
    conn = await get_db_connection()
    try:
        # Discover system capabilities
        discovery_data = await discover_system_capabilities(
            str(discovery_request.base_url),
            discovery_request.authentication,
            discovery_request.discovery_endpoints,
            discovery_request.timeout_seconds
        )
        
        # Generate system ID
        system_id = str(uuid.uuid4())
        
        # Register system
        await conn.execute("""
            INSERT INTO external_systems (
                system_id, name, system_type, base_url, api_version,
                authentication, capabilities, supported_operations, metadata,
                timeout_seconds, connection_pool_size, active_connections,
                current_status, active, created_by, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, true, $14, $15, $16)
        """, 
        system_id, discovery_request.name, discovery_request.system_type.value,
        str(discovery_request.base_url), discovery_data['api_version'],
        json.dumps(discovery_request.authentication),
        json.dumps(discovery_data['capabilities']),
        json.dumps(discovery_data['capabilities']),  # Initially same as capabilities
        json.dumps(discovery_data['metadata']),
        discovery_request.timeout_seconds, 10, 0,  # Default pool size
        "unknown", user_id, datetime.utcnow(), datetime.utcnow())
        
        # Schedule initial health check
        background_tasks.add_task(check_system_health, conn, system_id)
        
        return {
            "system_id": system_id,
            "message": "System discovered and registered successfully",
            "discovered_capabilities": discovery_data['capabilities'],
            "api_version": discovery_data['api_version'],
            "metadata": discovery_data['metadata']
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"System discovery failed: {str(e)}")
    finally:
        await conn.close()

@router.get("/systems/{system_id}/health")
async def check_system_health_endpoint(
    system_id: str,
    force_check: bool = Query(False, description="Force immediate health check"),
    user_id: str = Depends(verify_enterprise_auth)
):
    """Check specific system health status"""
    
    conn = await get_db_connection()
    try:
        if force_check:
            health_data = await check_system_health(conn, system_id)
        else:
            # Get latest health data
            health_row = await conn.fetchrow("""
                SELECT check_time, status, response_time_ms, details
                FROM system_health_logs 
                WHERE system_id = $1 
                ORDER BY check_time DESC 
                LIMIT 1
            """, system_id)
            
            if health_row:
                health_data = {
                    "status": health_row['status'],
                    "response_time_ms": health_row['response_time_ms'],
                    "last_check": health_row['check_time'],
                    "details": json.loads(health_row['details']) if health_row['details'] else {}
                }
            else:
                health_data = {"status": "unknown", "error": "No health data available"}
        
        return health_data
        
    finally:
        await conn.close()

@router.get("/systems/{system_id}/configs", response_model=List[IntegrationConfig])
async def get_system_configurations(
    system_id: str,
    config_type: Optional[str] = Query(None, description="Filter by configuration type"),
    user_id: str = Depends(verify_enterprise_auth)
):
    """Get integration configurations for a system"""
    
    conn = await get_db_connection()
    try:
        query = """
            SELECT config_id, system_id, config_name, config_type, configuration,
                   active, created_at, updated_at
            FROM integration_configs
            WHERE system_id = $1
        """
        
        params = [system_id]
        if config_type:
            query += " AND config_type = $2"
            params.append(config_type)
        
        query += " ORDER BY config_name"
        
        configs = await conn.fetch(query, *params)
        
        return [
            IntegrationConfig(
                config_id=config['config_id'],
                system_id=config['system_id'],
                config_name=config['config_name'],
                config_type=config['config_type'],
                configuration=json.loads(config['configuration']),
                active=config['active'],
                created_at=config['created_at'],
                updated_at=config['updated_at']
            )
            for config in configs
        ]
        
    finally:
        await conn.close()

@router.get("/systems/{system_id}/mappings", response_model=List[APIMapping])
async def get_api_mappings(
    system_id: str,
    user_id: str = Depends(verify_enterprise_auth)
):
    """Get API endpoint mappings for a system"""
    
    conn = await get_db_connection()
    try:
        mappings = await conn.fetch("""
            SELECT mapping_id, system_id, local_endpoint, remote_endpoint, method,
                   request_transform, response_transform, active, created_at
            FROM api_mappings
            WHERE system_id = $1 AND active = true
            ORDER BY local_endpoint
        """, system_id)
        
        return [
            APIMapping(
                mapping_id=mapping['mapping_id'],
                system_id=mapping['system_id'],
                local_endpoint=mapping['local_endpoint'],
                remote_endpoint=mapping['remote_endpoint'],
                method=mapping['method'],
                request_transform=json.loads(mapping['request_transform']) if mapping['request_transform'] else None,
                response_transform=json.loads(mapping['response_transform']) if mapping['response_transform'] else None,
                active=mapping['active'],
                created_at=mapping['created_at']
            )
            for mapping in mappings
        ]
        
    finally:
        await conn.close()

@router.delete("/systems/{system_id}")
async def remove_external_system(
    system_id: str,
    force: bool = Query(False, description="Force removal even with active integrations"),
    user_id: str = Depends(verify_enterprise_auth)
):
    """Remove external system and cleanup integrations"""
    
    conn = await get_db_connection()
    try:
        # Check for active integrations
        if not force:
            active_configs = await conn.fetchval("""
                SELECT COUNT(*) FROM integration_configs 
                WHERE system_id = $1 AND active = true
            """, system_id)
            
            if active_configs > 0:
                raise HTTPException(
                    status_code=400, 
                    detail=f"System has {active_configs} active integrations. Use force=true to remove anyway."
                )
        
        # Remove system and related data
        async with conn.transaction():
            # Deactivate configurations
            await conn.execute("""
                UPDATE integration_configs SET active = false 
                WHERE system_id = $1
            """, system_id)
            
            # Deactivate API mappings
            await conn.execute("""
                UPDATE api_mappings SET active = false 
                WHERE system_id = $1
            """, system_id)
            
            # Archive health logs (don't delete for audit trail)
            await conn.execute("""
                UPDATE system_health_logs SET archived = true
                WHERE system_id = $1
            """, system_id)
            
            # Remove system
            await conn.execute("""
                UPDATE external_systems SET active = false, updated_at = $1
                WHERE system_id = $2
            """, datetime.utcnow(), system_id)
        
        return {"message": "External system removed successfully", "system_id": system_id}
        
    finally:
        await conn.close()