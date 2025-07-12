"""
WebSocket message schemas for validation and documentation
"""

from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field
from datetime import datetime

class WebSocketConnectionRequest(BaseModel):
    """Request to establish WebSocket connection"""
    client_id: Optional[str] = Field(None, description="Client identifier")
    user_id: Optional[str] = Field(None, description="User identifier for authentication")
    subscriptions: Optional[List[str]] = Field(default_factory=list, description="Initial event subscriptions")
    rooms: Optional[List[str]] = Field(default_factory=list, description="Initial rooms to join")

class WebSocketSubscriptionRequest(BaseModel):
    """Request to subscribe/unsubscribe from events"""
    event_types: List[str] = Field(..., description="Event types to subscribe to")
    action: str = Field(..., description="'subscribe' or 'unsubscribe'")

class WebSocketRoomRequest(BaseModel):
    """Request to join/leave rooms"""
    rooms: List[str] = Field(..., description="Room names")
    action: str = Field(..., description="'join' or 'leave'")

# Event payload schemas
class ForecastEventPayload(BaseModel):
    """Forecast-related event payload"""
    forecast_id: str
    interval_start: datetime
    call_volume: Optional[int] = None
    aht: Optional[float] = None
    staffing_requirement: Optional[int] = None
    accuracy_metrics: Optional[Dict[str, float]] = None
    error_message: Optional[str] = None

class ScheduleEventPayload(BaseModel):
    """Schedule-related event payload"""
    schedule_id: str
    agent_id: Optional[str] = None
    change_type: str  # 'shift_modified', 'shift_added', 'shift_removed', 'optimized'
    shift_details: Optional[Dict[str, Any]] = None
    optimization_metrics: Optional[Dict[str, float]] = None

class AgentStatusEventPayload(BaseModel):
    """Agent status event payload"""
    agent_id: str
    status: str  # 'available', 'busy', 'break', 'offline'
    previous_status: Optional[str] = None
    timestamp: datetime
    location: Optional[str] = None
    skills: Optional[List[str]] = None

class QueueMetricsEventPayload(BaseModel):
    """Queue metrics event payload"""
    queue_id: str
    group_id: Optional[str] = None
    metrics: Dict[str, Union[int, float]] = Field(
        ..., 
        description="Metrics like calls_in_queue, avg_wait_time, service_level, abandonment"
    )
    timestamp: datetime
    thresholds: Optional[Dict[str, float]] = None

class SLAAlertEventPayload(BaseModel):
    """SLA alert event payload"""
    alert_id: str
    alert_type: str  # 'service_level', 'abandonment', 'wait_time'
    current_value: float
    threshold: float
    queue_id: Optional[str] = None
    group_id: Optional[str] = None
    severity: str  # 'low', 'medium', 'high', 'critical'
    timestamp: datetime

class SkillEventPayload(BaseModel):
    """Skill management event payload"""
    agent_id: str
    skill: str
    action: str  # 'assigned', 'removed', 'level_changed'
    skill_level: Optional[int] = None
    previous_level: Optional[int] = None
    timestamp: datetime

class VacancyEventPayload(BaseModel):
    """Vacancy management event payload"""
    vacancy_id: str
    position: str
    department: Optional[str] = None
    required_skills: List[str]
    status: str  # 'created', 'filled', 'cancelled'
    agent_id: Optional[str] = None  # For filled vacancies
    timestamp: datetime

class StaffingGapEventPayload(BaseModel):
    """Staffing gap detection event payload"""
    gap_id: str
    interval_start: datetime
    interval_end: datetime
    required_agents: int
    available_agents: int
    gap_size: int
    skills_affected: List[str]
    priority: str  # 'low', 'medium', 'high', 'critical'
    suggested_actions: List[str]

class AlgorithmEventPayload(BaseModel):
    """Algorithm calculation event payload"""
    calculation_id: str
    algorithm_type: str  # 'erlang', 'optimization', 'accuracy'
    input_parameters: Dict[str, Any]
    results: Dict[str, Any]
    execution_time_ms: float
    timestamp: datetime
    accuracy_score: Optional[float] = None

# Combined event payload type
EventPayload = Union[
    ForecastEventPayload,
    ScheduleEventPayload,
    AgentStatusEventPayload,
    QueueMetricsEventPayload,
    SLAAlertEventPayload,
    SkillEventPayload,
    VacancyEventPayload,
    StaffingGapEventPayload,
    AlgorithmEventPayload,
    Dict[str, Any]  # Fallback for custom payloads
]

class WebSocketEventMessage(BaseModel):
    """Complete WebSocket event message"""
    type: str = Field(..., description="Event type identifier")
    payload: EventPayload = Field(..., description="Event-specific payload")
    timestamp: float = Field(..., description="Unix timestamp")
    client_id: Optional[str] = Field(None, description="Source client ID")
    room: Optional[str] = Field(None, description="Target room")
    correlation_id: Optional[str] = Field(None, description="Request correlation ID")

class WebSocketResponse(BaseModel):
    """Standard WebSocket response"""
    success: bool
    message: str
    data: Optional[Any] = None
    timestamp: float

class WebSocketStatsResponse(BaseModel):
    """WebSocket connection statistics"""
    total_connections: int
    active_rooms: int
    room_details: Dict[str, int]
    event_handlers: int
    heartbeat_active: bool
    uptime_seconds: float