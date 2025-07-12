"""
1C ZUP Integration Service

This service handles all communication with 1C ZUP (Зарплата и Управление Персоналом) system.
Provides methods for:
- Personnel synchronization
- Schedule exchange
- Time reporting
- Configuration management

Integration points:
- Personnel API for employee synchronization
- WebSocket system for real-time updates
- Bulk operations for large data sets
"""

import asyncio
import json
import logging
from datetime import datetime, date, time
from typing import Dict, Any, List, Optional, Union
from uuid import UUID

import aiohttp
import httpx
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, insert
from sqlalchemy.orm import selectinload

from ..db.models import (
    IntegrationConnection, IntegrationSyncLog, OneCIntegrationData,
    IntegrationDataMapping, Agent
)
from ..v1.schemas.integrations import (
    OneCPersonnelSync, OneCScheduleData, OneCTimeData,
    OneCAgentData, OneCDeviationData, SyncOperationResponse,
    IntegrationResponse, BulkOperationResponse
)
from ..core.config import get_settings
from ..utils.cache import cache_manager
from ..websocket.events import emit_integration_event


logger = logging.getLogger(__name__)
settings = get_settings()


class OneCService:
    """Service for 1C ZUP integration operations"""
    
    def __init__(self, connection: IntegrationConnection):
        self.connection = connection
        self.base_url = connection.endpoint_url
        self.auth_config = connection.credentials
        self.config = connection.config or {}
        self.session = None
        
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    def _get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers for 1C requests"""
        headers = {"Content-Type": "application/json"}
        
        if self.connection.authentication_type == "basic":
            import base64
            username = self.auth_config.get("username", "")
            password = self.auth_config.get("password", "")
            credentials = base64.b64encode(f"{username}:{password}".encode()).decode()
            headers["Authorization"] = f"Basic {credentials}"
        elif self.connection.authentication_type == "api_key":
            api_key = self.auth_config.get("api_key", "")
            headers["X-API-Key"] = api_key
        elif self.connection.authentication_type == "bearer":
            token = self.auth_config.get("token", "")
            headers["Authorization"] = f"Bearer {token}"
            
        return headers
    
    async def test_connection(self) -> Dict[str, Any]:
        """Test connection to 1C ZUP system"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                test_url = f"{self.base_url}/api/test"
                
                start_time = datetime.utcnow()
                async with session.get(test_url, headers=headers, timeout=30) as response:
                    end_time = datetime.utcnow()
                    response_time = (end_time - start_time).total_seconds() * 1000
                    
                    if response.status == 200:
                        return {
                            "success": True,
                            "status_code": response.status,
                            "response_time_ms": response_time,
                            "message": "Connection successful"
                        }
                    else:
                        return {
                            "success": False,
                            "status_code": response.status,
                            "response_time_ms": response_time,
                            "message": f"Connection failed with status {response.status}"
                        }
                        
        except Exception as e:
            logger.error(f"1C connection test failed: {str(e)}")
            return {
                "success": False,
                "status_code": 0,
                "response_time_ms": 0,
                "message": f"Connection failed: {str(e)}"
            }
    
    async def get_agents(
        self, 
        start_date: date, 
        end_date: date,
        departments: Optional[List[str]] = None
    ) -> List[OneCAgentData]:
        """Get agents from 1C ZUP for specified date range"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                
                # Build query parameters
                params = {
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat()
                }
                
                if departments:
                    params["departments"] = ",".join(departments)
                
                url = f"{self.base_url}/api/personnel/agents"
                
                async with session.get(url, headers=headers, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        agents = []
                        
                        for agent_data in data.get("agents", []):
                            agent = OneCAgentData(
                                agent_id=agent_data.get("id"),
                                tab_number=agent_data.get("tab_number"),
                                first_name=agent_data.get("first_name"),
                                last_name=agent_data.get("last_name"),
                                middle_name=agent_data.get("middle_name"),
                                department=agent_data.get("department"),
                                position=agent_data.get("position"),
                                hire_date=agent_data.get("hire_date"),
                                status=agent_data.get("status", "active"),
                                skills=agent_data.get("skills", [])
                            )
                            agents.append(agent)
                        
                        return agents
                    else:
                        logger.error(f"Failed to get agents from 1C: {response.status}")
                        return []
                        
        except Exception as e:
            logger.error(f"Error getting agents from 1C: {str(e)}")
            return []
    
    async def sync_personnel_data(
        self, 
        sync_params: OneCPersonnelSync,
        user_id: UUID,
        db: AsyncSession
    ) -> SyncOperationResponse:
        """Sync personnel data from 1C to WFM system"""
        # Create sync log
        sync_log = IntegrationSyncLog(
            connection_id=self.connection.id,
            sync_type="personnel" if not sync_params.full_sync else "full",
            direction="inbound",
            status="started",
            start_time=datetime.utcnow(),
            sync_data=sync_params.dict(),
            initiated_by=user_id
        )
        db.add(sync_log)
        await db.commit()
        
        try:
            # Get agents from 1C
            agents = await self.get_agents(
                start_date=sync_params.start_date,
                end_date=sync_params.end_date,
                departments=sync_params.departments
            )
            
            sync_log.records_processed = len(agents)
            successful_syncs = 0
            failed_syncs = 0
            
            for agent_data in agents:
                try:
                    # Store in integration table
                    integration_data = OneCIntegrationData(
                        data_type="personnel",
                        onec_id=agent_data.agent_id,
                        onec_type="agent",
                        onec_data=agent_data.dict(),
                        sync_status="pending"
                    )
                    db.add(integration_data)
                    
                    # Map to WFM Agent if needed
                    await self._map_agent_to_wfm(agent_data, integration_data, db)
                    
                    successful_syncs += 1
                    
                except Exception as e:
                    logger.error(f"Failed to sync agent {agent_data.agent_id}: {str(e)}")
                    failed_syncs += 1
            
            # Update sync log
            sync_log.end_time = datetime.utcnow()
            sync_log.status = "completed" if failed_syncs == 0 else "failed"
            sync_log.records_successful = successful_syncs
            sync_log.records_failed = failed_syncs
            
            await db.commit()
            
            # Emit WebSocket event
            await emit_integration_event(
                event_type="integration.personnel.sync.completed",
                payload={
                    "sync_id": str(sync_log.id),
                    "connection_id": str(self.connection.id),
                    "records_processed": sync_log.records_processed,
                    "records_successful": successful_syncs,
                    "records_failed": failed_syncs
                }
            )
            
            return SyncOperationResponse(
                sync_id=sync_log.id,
                status="completed" if failed_syncs == 0 else "failed",
                started_at=sync_log.start_time,
                progress_percentage=100.0,
                records_to_process=len(agents),
                records_processed=successful_syncs
            )
            
        except Exception as e:
            logger.error(f"Personnel sync failed: {str(e)}")
            sync_log.status = "failed"
            sync_log.end_time = datetime.utcnow()
            sync_log.error_details = {"error": str(e)}
            await db.commit()
            
            return SyncOperationResponse(
                sync_id=sync_log.id,
                status="failed",
                started_at=sync_log.start_time,
                progress_percentage=0.0,
                records_to_process=0,
                records_processed=0
            )
    
    async def _map_agent_to_wfm(
        self, 
        agent_data: OneCAgentData,
        integration_data: OneCIntegrationData,
        db: AsyncSession
    ) -> None:
        """Map 1C agent data to WFM Agent model"""
        try:
            # Check if agent already exists
            stmt = select(Agent).where(Agent.agent_number == agent_data.tab_number)
            result = await db.execute(stmt)
            existing_agent = result.scalar_one_or_none()
            
            if existing_agent:
                # Update existing agent
                existing_agent.name = agent_data.first_name
                existing_agent.surname = agent_data.last_name
                existing_agent.second_name = agent_data.middle_name
                existing_agent.updated_at = datetime.utcnow()
                
                integration_data.wfm_entity_id = existing_agent.id
                integration_data.wfm_entity_type = "agent"
                integration_data.sync_status = "synced"
                integration_data.synced_at = datetime.utcnow()
                
            else:
                # Create new agent
                new_agent = Agent(
                    id=agent_data.agent_id,
                    name=agent_data.first_name,
                    surname=agent_data.last_name,
                    second_name=agent_data.middle_name,
                    agent_number=agent_data.tab_number,
                    email=f"{agent_data.first_name.lower()}.{agent_data.last_name.lower()}@company.com"
                )
                db.add(new_agent)
                
                integration_data.wfm_entity_id = new_agent.id
                integration_data.wfm_entity_type = "agent"
                integration_data.sync_status = "synced"
                integration_data.synced_at = datetime.utcnow()
                
        except Exception as e:
            logger.error(f"Failed to map agent {agent_data.agent_id}: {str(e)}")
            integration_data.sync_status = "error"
            integration_data.sync_error = str(e)
    
    async def send_schedule(self, schedule_data: Dict[str, Any]) -> IntegrationResponse:
        """Send schedule data to 1C ZUP"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                url = f"{self.base_url}/api/schedule/import"
                
                # Transform schedule data for 1C format
                onec_schedule = await self._transform_schedule_for_onec(schedule_data)
                
                async with session.post(url, headers=headers, json=onec_schedule) as response:
                    if response.status == 200:
                        result = await response.json()
                        return IntegrationResponse(
                            success=True,
                            message="Schedule successfully sent to 1C",
                            data=result
                        )
                    else:
                        error_text = await response.text()
                        return IntegrationResponse(
                            success=False,
                            message=f"Failed to send schedule to 1C: {error_text}",
                            data={"status_code": response.status}
                        )
                        
        except Exception as e:
            logger.error(f"Error sending schedule to 1C: {str(e)}")
            return IntegrationResponse(
                success=False,
                message=f"Error sending schedule to 1C: {str(e)}"
            )
    
    async def _transform_schedule_for_onec(self, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """Transform WFM schedule data to 1C format"""
        # Apply field mappings from connection configuration
        mapping_rules = self.connection.mapping_rules or {}
        schedule_mapping = mapping_rules.get("schedule", {})
        
        transformed = {}
        
        # Default transformations
        transformed["schedule_id"] = schedule_data.get("schedule_id")
        transformed["period_start"] = schedule_data.get("start_date")
        transformed["period_end"] = schedule_data.get("end_date")
        
        # Transform employees
        employees = []
        for emp in schedule_data.get("employees", []):
            employee = {}
            employee["employee_id"] = emp.get("employee_id")
            employee["tab_number"] = emp.get("tab_number")
            employee["schedule_entries"] = emp.get("shifts", [])
            employees.append(employee)
        
        transformed["employees"] = employees
        
        # Apply custom mappings
        for source_field, target_field in schedule_mapping.items():
            if source_field in schedule_data:
                transformed[target_field] = schedule_data[source_field]
        
        return transformed
    
    async def send_work_time(self, time_data: Dict[str, Any]) -> IntegrationResponse:
        """Send work time data to 1C ZUP"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                url = f"{self.base_url}/api/timesheet/import"
                
                # Transform time data for 1C format
                onec_time = await self._transform_time_for_onec(time_data)
                
                async with session.post(url, headers=headers, json=onec_time) as response:
                    if response.status == 200:
                        result = await response.json()
                        return IntegrationResponse(
                            success=True,
                            message="Work time successfully sent to 1C",
                            data=result
                        )
                    else:
                        error_text = await response.text()
                        return IntegrationResponse(
                            success=False,
                            message=f"Failed to send work time to 1C: {error_text}",
                            data={"status_code": response.status}
                        )
                        
        except Exception as e:
            logger.error(f"Error sending work time to 1C: {str(e)}")
            return IntegrationResponse(
                success=False,
                message=f"Error sending work time to 1C: {str(e)}"
            )
    
    async def _transform_time_for_onec(self, time_data: Dict[str, Any]) -> Dict[str, Any]:
        """Transform WFM time data to 1C format"""
        # Apply field mappings from connection configuration
        mapping_rules = self.connection.mapping_rules or {}
        time_mapping = mapping_rules.get("timesheet", {})
        
        transformed = {}
        
        # Default transformations
        transformed["employee_id"] = time_data.get("employee_id")
        transformed["date"] = time_data.get("date")
        transformed["time_start"] = time_data.get("start_time")
        transformed["time_end"] = time_data.get("end_time")
        transformed["hours_worked"] = time_data.get("hours_worked")
        transformed["overtime_hours"] = time_data.get("overtime_hours", 0)
        transformed["time_type"] = time_data.get("time_type", "regular")
        
        # Apply custom mappings
        for source_field, target_field in time_mapping.items():
            if source_field in time_data:
                transformed[target_field] = time_data[source_field]
        
        return transformed
    
    async def get_norm_hours(
        self, 
        employee_id: str, 
        start_date: date, 
        end_date: date
    ) -> Dict[str, Any]:
        """Get norm hours from 1C ZUP"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                params = {
                    "employee_id": employee_id,
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat()
                }
                
                url = f"{self.base_url}/api/norm-hours"
                
                async with session.get(url, headers=headers, params=params) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        logger.error(f"Failed to get norm hours: {response.status}")
                        return {}
                        
        except Exception as e:
            logger.error(f"Error getting norm hours: {str(e)}")
            return {}
    
    async def get_timetype_info(
        self, 
        employee_id: str, 
        query_date: date
    ) -> Dict[str, Any]:
        """Get time type info from 1C ZUP"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                params = {
                    "employee_id": employee_id,
                    "date": query_date.isoformat()
                }
                
                url = f"{self.base_url}/api/time-type-info"
                
                async with session.get(url, headers=headers, params=params) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        logger.error(f"Failed to get time type info: {response.status}")
                        return {}
                        
        except Exception as e:
            logger.error(f"Error getting time type info: {str(e)}")
            return {}
    
    async def get_deviations(
        self, 
        start_date: date, 
        end_date: date
    ) -> List[OneCDeviationData]:
        """Get deviations from 1C ZUP"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                params = {
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat()
                }
                
                url = f"{self.base_url}/api/deviations"
                
                async with session.get(url, headers=headers, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        deviations = []
                        
                        for deviation_data in data.get("deviations", []):
                            deviation = OneCDeviationData(
                                employee_id=deviation_data.get("employee_id"),
                                date=deviation_data.get("date"),
                                planned_hours=deviation_data.get("planned_hours"),
                                actual_hours=deviation_data.get("actual_hours"),
                                deviation_hours=deviation_data.get("deviation_hours"),
                                deviation_type=deviation_data.get("deviation_type"),
                                reason=deviation_data.get("reason")
                            )
                            deviations.append(deviation)
                        
                        return deviations
                    else:
                        logger.error(f"Failed to get deviations: {response.status}")
                        return []
                        
        except Exception as e:
            logger.error(f"Error getting deviations: {str(e)}")
            return []
    
    @staticmethod
    async def sync_personnel_data_background(
        connection_id: UUID,
        sync_params: Dict[str, Any],
        user_id: UUID
    ) -> None:
        """Background task for personnel data synchronization"""
        from ..core.database import get_db
        
        async with get_db() as db:
            # Get connection
            stmt = select(IntegrationConnection).where(
                IntegrationConnection.id == connection_id
            )
            result = await db.execute(stmt)
            connection = result.scalar_one_or_none()
            
            if not connection:
                logger.error(f"Connection {connection_id} not found")
                return
            
            # Perform sync
            service = OneCService(connection)
            sync_data = OneCPersonnelSync(**sync_params)
            
            await service.sync_personnel_data(sync_data, user_id, db)