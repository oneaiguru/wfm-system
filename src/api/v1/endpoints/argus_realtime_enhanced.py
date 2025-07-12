"""
Enhanced Real-time/Online Endpoints for Argus API Replication
Implements high-performance real-time endpoints with WebSocket support
"""
from typing import List, Optional, Dict, Any, Set
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field, ConfigDict, field_validator
import asyncio
import json
from asyncio import Queue
from collections import defaultdict
import time

from src.api.core.database import get_db
from src.api.services.online_service import OnlineService
from src.api.utils.cache import cache_decorator
from src.api.middleware.monitoring import monitor_endpoint_performance


router = APIRouter(prefix="/api/v1", tags=["Real-time Data Enhanced"])


# ============================================================================
# PERFORMANCE CONFIGURATION
# ============================================================================

# Connection pooling for high throughput
CONNECTION_POOL_SIZE = 100
MAX_CONNECTIONS_PER_CLIENT = 10

# WebSocket management
active_websockets: Dict[str, Set[WebSocket]] = defaultdict(set)
message_queues: Dict[str, Queue] = {}

# Performance monitoring
performance_metrics = {
    "avg_response_time": 0,
    "total_requests": 0,
    "active_connections": 0,
    "messages_per_second": 0
}


# ============================================================================
# ENHANCED PYDANTIC MODELS WITH BDD COMPLIANCE
# ============================================================================

class AgentStatusEvent(BaseModel):
    """BDD-compliant real-time status event"""
    model_config = ConfigDict(from_attributes=True)
    
    workerId: str = Field(..., description="Unique employee identifier")
    stateName: str = Field(..., description="Human-readable status")
    stateCode: str = Field(..., description="System status code")
    systemId: str = Field(..., description="Source system identifier")
    actionTime: int = Field(..., description="Unix timestamp")
    action: int = Field(..., description="1=entry, 0=exit")
    
    @field_validator('action')
    def validate_action(cls, v):
        if v not in [0, 1]:
            raise ValueError("action must be 0 (exit) or 1 (entry)")
        return v
    
    @field_validator('actionTime')
    def validate_timestamp(cls, v):
        if v < 0:
            raise ValueError("actionTime must be a positive Unix timestamp")
        return v


class AgentOnlineStatus(BaseModel):
    """BDD-compliant current agent status"""
    model_config = ConfigDict(from_attributes=True)
    
    agentId: str = Field(..., description="Agent identifier")
    stateCode: str = Field(..., description="Current status code")
    stateName: str = Field(..., description="Status description")
    startDate: datetime = Field(..., description="Current status start time")
    duration: Optional[int] = Field(None, description="Duration in current status (milliseconds)")
    
    @property
    def duration_seconds(self) -> int:
        """Calculate duration in seconds"""
        if self.duration:
            return self.duration // 1000
        return int((datetime.now(timezone.utc) - self.startDate).total_seconds())


class GroupOnlineLoad(BaseModel):
    """BDD-compliant real-time group metrics"""
    model_config = ConfigDict(from_attributes=True)
    
    serviceId: str = Field(..., description="Service identifier")
    groupId: str = Field(..., description="Group identifier")
    callNumber: int = Field(..., ge=0, description="Contacts in queue now")
    operatorNumber: int = Field(..., ge=0, description="Available operators")
    callReceived: Optional[int] = Field(None, ge=0, description="Contacts received today")
    aht: Optional[int] = Field(None, ge=0, description="Average handle time today (ms)")
    acd: Optional[float] = Field(None, ge=0, le=100, description="Percentage answered today")
    awt: Optional[int] = Field(None, ge=0, description="Average wait time (ms)")
    callAnswered: Optional[int] = Field(None, ge=0, description="Calls answered today")
    callAnsweredTst: Optional[int] = Field(None, ge=0, description="Calls answered within 80/20 format")
    callProcessing: Optional[int] = Field(None, ge=0, description="Calls being processed now")
    lastUpdate: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class QueueMetrics(BaseModel):
    """Enhanced queue metrics for real-time monitoring"""
    model_config = ConfigDict(from_attributes=True)
    
    queueId: str = Field(..., description="Queue identifier")
    queueDepth: int = Field(..., ge=0, description="Current queue size")
    longestWaitTime: int = Field(..., ge=0, description="Longest wait time in queue (ms)")
    estimatedWaitTime: int = Field(..., ge=0, description="Estimated wait time for new calls (ms)")
    serviceLevelNow: float = Field(..., ge=0, le=100, description="Current service level %")
    abandonmentRate: float = Field(..., ge=0, le=100, description="Current abandonment rate %")


class AgentStateChange(BaseModel):
    """WebSocket notification for agent state changes"""
    model_config = ConfigDict(from_attributes=True)
    
    eventType: str = Field("agentStateChange", const=True)
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    agentId: str = Field(..., description="Agent identifier")
    previousState: str = Field(..., description="Previous state code")
    newState: str = Field(..., description="New state code")
    stateName: str = Field(..., description="New state name")
    groupId: Optional[str] = Field(None, description="Group context if applicable")


# ============================================================================
# PERFORMANCE MONITORING DECORATOR
# ============================================================================

def track_performance(func):
    """Track endpoint performance metrics"""
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            response_time = (time.time() - start_time) * 1000  # Convert to ms
            
            # Update metrics
            performance_metrics["total_requests"] += 1
            performance_metrics["avg_response_time"] = (
                (performance_metrics["avg_response_time"] * (performance_metrics["total_requests"] - 1) + 
                 response_time) / performance_metrics["total_requests"]
            )
            
            # Check performance threshold
            if response_time > 500:
                print(f"WARNING: Endpoint {func.__name__} exceeded 500ms threshold: {response_time:.2f}ms")
                
            return result
        except Exception as e:
            raise e
    return wrapper


# ============================================================================
# REAL-TIME STATUS ENDPOINTS
# ============================================================================

@router.post("/ccwfm/api/rest/status",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {"description": "Status update accepted (fire-and-forget)"},
        400: {"description": "Invalid status data"},
        500: {"description": "Server error"}
    }
)
@track_performance
async def post_agent_status_update(
    status_event: AgentStatusEvent,
    db: AsyncSession = Depends(get_db),
):
    """
    Real-time agent status transmission - Fire-and-forget pattern
    
    Processing Rules:
    - Event pairs: Entry + exit events create complete status periods
    - Immediate processing: No response required
    - No data integrity control: Send without confirmation
    - High throughput: Optimized for <500ms processing
    """
    try:
        # Convert Unix timestamp to datetime
        event_time = datetime.fromtimestamp(status_event.actionTime, tz=timezone.utc)
        
        # Process status update asynchronously (fire-and-forget)
        asyncio.create_task(_process_status_update(status_event, event_time, db))
        
        # Notify WebSocket subscribers
        await _notify_status_change(status_event)
        
        # Return immediately (no content)
        return None
        
    except Exception as e:
        # Log error but don't fail (fire-and-forget pattern)
        print(f"Error processing status update: {e}")
        return None


async def _process_status_update(status_event: AgentStatusEvent, event_time: datetime, db: AsyncSession):
    """Process status update in background"""
    try:
        service = OnlineService(db)
        await service.process_status_event(
            worker_id=status_event.workerId,
            state_code=status_event.stateCode,
            state_name=status_event.stateName,
            action=status_event.action,
            event_time=event_time,
            system_id=status_event.systemId
        )
    except Exception as e:
        print(f"Background status processing error: {e}")


async def _notify_status_change(status_event: AgentStatusEvent):
    """Notify WebSocket subscribers of status change"""
    notification = AgentStateChange(
        agentId=status_event.workerId,
        previousState="",  # Would need to track this
        newState=status_event.stateCode,
        stateName=status_event.stateName
    )
    
    # Send to all subscribed WebSockets
    agent_key = f"agent:{status_event.workerId}"
    if agent_key in active_websockets:
        message = notification.model_dump_json()
        for websocket in active_websockets[agent_key]:
            try:
                await websocket.send_text(message)
            except:
                # Remove dead connections
                active_websockets[agent_key].discard(websocket)


@router.get("/online/agentStatus",
    response_model=List[AgentOnlineStatus],
    responses={
        200: {"description": "Current agent statuses"},
        400: {"description": "Invalid parameters"},
        404: {"description": "No agents found"},
        500: {"description": "Server error"}
    }
)
@track_performance
@cache_decorator(expire=10)  # 10-second cache for performance
async def get_current_agent_status(
    agentId: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    groupId: Optional[str] = Query(None, description="Comma-separated group IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve current agent status information - <500ms response time
    
    Returns:
    - All currently active agents if no parameters
    - Filtered by agent IDs or group IDs if provided
    - Real-time current state with duration
    """
    try:
        # Parse parameters
        agent_ids = None
        group_ids = None
        
        if agentId:
            agent_ids = [aid.strip() for aid in agentId.split(",") if aid.strip()]
        if groupId:
            group_ids = [gid.strip() for gid in groupId.split(",") if gid.strip()]
        
        # Get current statuses
        service = OnlineService(db)
        statuses = await service.get_current_agent_statuses(
            agent_ids=agent_ids,
            group_ids=group_ids
        )
        
        if not statuses:
            raise HTTPException(status_code=404)
        
        # Convert to response model
        result = []
        for status in statuses:
            result.append(AgentOnlineStatus(
                agentId=status['agentId'],
                stateCode=status['stateCode'],
                stateName=status['stateName'],
                startDate=status['startDate'],
                duration=status.get('duration')
            ))
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "field": "database",
                "message": "Database connection failed",
                "description": str(e)
            }
        )


@router.get("/online/groupsOnlineLoad",
    response_model=List[GroupOnlineLoad],
    responses={
        200: {"description": "Current group metrics"},
        400: {"description": "Invalid parameters"},
        404: {"description": "No data found"},
        500: {"description": "Server error"}
    }
)
@track_performance
@cache_decorator(expire=5)  # 5-second cache for real-time data
async def get_groups_online_load(
    groupId: Optional[str] = Query(None, description="Comma-separated group IDs"),
    serviceId: Optional[str] = Query(None, description="Comma-separated service IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve real-time group metrics for live monitoring - <500ms response
    
    Update Frequencies:
    - Queue metrics: Real-time
    - Agent counts: Real-time
    - Daily totals: Hourly
    - AHT: Every 5 minutes
    """
    try:
        # Parse parameters
        group_ids = None
        service_ids = None
        
        if groupId:
            group_ids = [gid.strip() for gid in groupId.split(",") if gid.strip()]
        if serviceId:
            service_ids = [sid.strip() for sid in serviceId.split(",") if sid.strip()]
        
        # Get metrics
        service = OnlineService(db)
        metrics = await service.get_group_online_metrics(
            group_ids=group_ids,
            service_ids=service_ids
        )
        
        if not metrics:
            raise HTTPException(status_code=404)
        
        # Convert to response model
        result = []
        for metric in metrics:
            result.append(GroupOnlineLoad(
                serviceId=metric['serviceId'],
                groupId=metric['groupId'],
                callNumber=metric['callNumber'],
                operatorNumber=metric['operatorNumber'],
                callReceived=metric.get('callReceived'),
                aht=metric.get('aht'),
                acd=metric.get('acd'),
                awt=metric.get('awt'),
                callAnswered=metric.get('callAnswered'),
                callAnsweredTst=metric.get('callAnsweredTst'),
                callProcessing=metric.get('callProcessing')
            ))
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "field": "integration",
                "message": "External system error",
                "description": f"Source system unavailable: {str(e)}"
            }
        )


# ============================================================================
# ENHANCED QUEUE METRICS ENDPOINT
# ============================================================================

@router.get("/online/queueMetrics",
    response_model=List[QueueMetrics],
    responses={
        200: {"description": "Current queue metrics"},
        404: {"description": "No queues found"}
    }
)
@track_performance
@cache_decorator(expire=5)
async def get_queue_metrics(
    queueId: Optional[str] = Query(None, description="Comma-separated queue IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Enhanced queue metrics with advanced calculations
    
    Provides:
    - Real-time queue depth
    - Longest wait time
    - Estimated wait time for new calls
    - Current service level
    - Abandonment rate
    """
    try:
        queue_ids = None
        if queueId:
            queue_ids = [qid.strip() for qid in queueId.split(",") if qid.strip()]
        
        service = OnlineService(db)
        metrics = await service.get_enhanced_queue_metrics(queue_ids=queue_ids)
        
        if not metrics:
            raise HTTPException(status_code=404)
        
        return [QueueMetrics(**metric) for metric in metrics]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "field": "processing",
                "message": "Metrics calculation error",
                "description": str(e)
            }
        )


# ============================================================================
# WEBSOCKET ENDPOINTS FOR STREAMING UPDATES
# ============================================================================

@router.websocket("/ws/agent-status/{agent_id}")
async def websocket_agent_status(
    websocket: WebSocket,
    agent_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for real-time agent status updates
    
    Sends:
    - Initial status on connection
    - Status changes as they occur
    - Heartbeat every 30 seconds
    """
    await websocket.accept()
    
    # Track connection
    agent_key = f"agent:{agent_id}"
    active_websockets[agent_key].add(websocket)
    performance_metrics["active_connections"] += 1
    
    try:
        # Send initial status
        service = OnlineService(db)
        current_status = await service.get_agent_current_status(agent_id)
        if current_status:
            await websocket.send_json({
                "eventType": "initialStatus",
                "data": current_status
            })
        
        # Keep connection alive with heartbeat
        while True:
            try:
                # Wait for client messages or timeout for heartbeat
                message = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=30.0
                )
                
                # Handle client messages if needed
                if message == "ping":
                    await websocket.send_text("pong")
                    
            except asyncio.TimeoutError:
                # Send heartbeat
                await websocket.send_json({
                    "eventType": "heartbeat",
                    "timestamp": datetime.now(timezone.utc).isoformat()
                })
                
    except WebSocketDisconnect:
        pass
    finally:
        # Clean up connection
        active_websockets[agent_key].discard(websocket)
        performance_metrics["active_connections"] -= 1


@router.websocket("/ws/queue-metrics/{group_id}")
async def websocket_queue_metrics(
    websocket: WebSocket,
    group_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for real-time queue metrics streaming
    
    Sends updates every 5 seconds with:
    - Queue depth changes
    - Wait time updates
    - Service level changes
    """
    await websocket.accept()
    
    # Track connection
    queue_key = f"queue:{group_id}"
    active_websockets[queue_key].add(websocket)
    
    try:
        service = OnlineService(db)
        
        while True:
            # Get current metrics
            metrics = await service.get_group_online_metrics(
                group_ids=[group_id]
            )
            
            if metrics:
                await websocket.send_json({
                    "eventType": "metricsUpdate",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "data": metrics[0]
                })
            
            # Wait 5 seconds before next update
            await asyncio.sleep(5)
            
    except WebSocketDisconnect:
        pass
    finally:
        active_websockets[queue_key].discard(websocket)


# ============================================================================
# PERFORMANCE MONITORING ENDPOINT
# ============================================================================

@router.get("/online/performance-metrics",
    responses={
        200: {"description": "Current performance metrics"}
    }
)
async def get_performance_metrics():
    """
    Get current API performance metrics
    
    Returns:
    - Average response time
    - Total requests processed
    - Active WebSocket connections
    - Messages per second rate
    """
    return {
        "avgResponseTime": f"{performance_metrics['avg_response_time']:.2f}ms",
        "totalRequests": performance_metrics["total_requests"],
        "activeConnections": performance_metrics["active_connections"],
        "messagesPerSecond": performance_metrics["messages_per_second"],
        "connectionPoolSize": CONNECTION_POOL_SIZE,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


# ============================================================================
# BATCH STATUS UPDATE ENDPOINT
# ============================================================================

@router.post("/online/batch-status-update",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        204: {"description": "Batch update accepted"},
        400: {"description": "Invalid batch data"}
    }
)
@track_performance
async def batch_status_update(
    updates: List[AgentStatusEvent],
    db: AsyncSession = Depends(get_db),
):
    """
    High-performance batch status update endpoint
    
    Processes multiple status updates in a single request
    for improved throughput
    """
    try:
        # Process all updates asynchronously
        tasks = []
        for update in updates:
            event_time = datetime.fromtimestamp(update.actionTime, tz=timezone.utc)
            tasks.append(_process_status_update(update, event_time, db))
            tasks.append(_notify_status_change(update))
        
        # Execute all tasks concurrently
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # Update metrics
        performance_metrics["messages_per_second"] = len(updates)
        
        return None
        
    except Exception as e:
        print(f"Batch update error: {e}")
        return None