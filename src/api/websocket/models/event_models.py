"""
Event Payload Models for WebSocket Events
Pydantic models for validation and serialization
"""

from pydantic import BaseModel, Field, validator
from typing import Dict, Any, Optional, List, Union
from datetime import datetime
from enum import Enum


class ForecastPeriod(BaseModel):
    """Forecast period data structure"""
    interval_start: datetime
    interval_end: datetime
    call_volume: int = Field(ge=0, description="Number of calls expected")
    aht: int = Field(ge=0, description="Average handle time in seconds")
    service_level: Optional[float] = Field(None, ge=0, le=1, description="Service level percentage")
    occupancy: Optional[float] = Field(None, ge=0, le=1, description="Agent occupancy percentage")
    
    @validator('interval_end')
    def validate_interval_end(cls, v, values):
        if 'interval_start' in values and v <= values['interval_start']:
            raise ValueError('interval_end must be after interval_start')
        return v


class ForecastUpdatePayload(BaseModel):
    """Payload for FORECAST_UPDATED event"""
    forecast_id: str = Field(..., description="Unique forecast identifier")
    interval_start: datetime = Field(..., description="Forecast interval start")
    call_volume: int = Field(..., ge=0, description="Number of calls expected")
    aht: int = Field(..., ge=0, description="Average handle time in seconds")
    service_level: Optional[float] = Field(None, ge=0, le=1, description="Target service level")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional forecast metadata")
    
    @validator('metadata')
    def validate_metadata(cls, v):
        if v is not None and not isinstance(v, dict):
            raise ValueError('metadata must be a dictionary')
        return v


class ForecastCalculatedPayload(BaseModel):
    """Payload for FORECAST_CALCULATED event"""
    forecast_id: str = Field(..., description="Unique forecast identifier")
    periods: List[ForecastPeriod] = Field(..., description="List of forecast periods")
    accuracy: float = Field(..., ge=0, le=100, description="Forecast accuracy percentage")
    algorithm_version: Optional[str] = Field(None, description="Algorithm version used")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional calculation metadata")
    
    @validator('periods')
    def validate_periods(cls, v):
        if not v:
            raise ValueError('periods cannot be empty')
        return v


class ShiftData(BaseModel):
    """Shift data structure"""
    shift_id: str = Field(..., description="Unique shift identifier")
    start_time: datetime = Field(..., description="Shift start time")
    end_time: datetime = Field(..., description="Shift end time")
    skills: List[str] = Field(default_factory=list, description="Required skills")
    break_duration: Optional[int] = Field(None, ge=0, description="Break duration in minutes")
    
    @validator('end_time')
    def validate_end_time(cls, v, values):
        if 'start_time' in values and v <= values['start_time']:
            raise ValueError('end_time must be after start_time')
        return v


class ScheduleChangeType(str, Enum):
    """Types of schedule changes"""
    SHIFT_ADDED = "shift_added"
    SHIFT_MODIFIED = "shift_modified"
    SHIFT_REMOVED = "shift_removed"
    BREAK_CHANGED = "break_changed"
    SKILLS_UPDATED = "skills_updated"


class ScheduleChangePayload(BaseModel):
    """Payload for SCHEDULE_CHANGED event"""
    schedule_id: str = Field(..., description="Unique schedule identifier")
    agent_id: str = Field(..., description="Agent identifier")
    change_type: ScheduleChangeType = Field(..., description="Type of schedule change")
    old_shift: Optional[ShiftData] = Field(None, description="Previous shift data")
    new_shift: Optional[ShiftData] = Field(None, description="New shift data")
    reason: Optional[str] = Field(None, description="Reason for change")
    changed_by: Optional[str] = Field(None, description="User who made the change")
    
    @validator('new_shift')
    def validate_shift_change(cls, v, values):
        change_type = values.get('change_type')
        if change_type in [ScheduleChangeType.SHIFT_ADDED, ScheduleChangeType.SHIFT_MODIFIED] and v is None:
            raise ValueError(f'new_shift is required for {change_type}')
        return v


class OptimizationChange(BaseModel):
    """Individual optimization change"""
    agent_id: str = Field(..., description="Agent identifier")
    change_type: str = Field(..., description="Type of change")
    old_value: Optional[Any] = Field(None, description="Previous value")
    new_value: Any = Field(..., description="New value")
    impact_score: Optional[float] = Field(None, description="Impact score of this change")


class ScheduleOptimizedPayload(BaseModel):
    """Payload for SCHEDULE_OPTIMIZED event"""
    schedule_id: str = Field(..., description="Unique schedule identifier")
    optimization_id: str = Field(..., description="Optimization run identifier")
    improvement_percentage: float = Field(..., ge=0, description="Improvement percentage")
    changes: List[OptimizationChange] = Field(..., description="List of optimization changes")
    algorithm_version: Optional[str] = Field(None, description="Optimization algorithm version")
    metrics: Optional[Dict[str, Any]] = Field(None, description="Optimization metrics")
    
    @validator('changes')
    def validate_changes(cls, v):
        if not v:
            raise ValueError('changes cannot be empty for optimization')
        return v


class AssignmentType(str, Enum):
    """Types of shift assignments"""
    AUTOMATIC = "automatic"
    MANUAL = "manual"
    OPTIMIZED = "optimized"
    EMERGENCY = "emergency"


class ShiftAssignedPayload(BaseModel):
    """Payload for SHIFT_ASSIGNED event"""
    shift_id: str = Field(..., description="Unique shift identifier")
    agent_id: str = Field(..., description="Agent identifier")
    shift: ShiftData = Field(..., description="Shift details")
    assignment_type: AssignmentType = Field(..., description="Type of assignment")
    assigned_by: Optional[str] = Field(None, description="User who made the assignment")
    priority: Optional[int] = Field(None, ge=1, le=5, description="Assignment priority (1-5)")
    
    @validator('shift')
    def validate_shift_data(cls, v):
        if not v.shift_id:
            raise ValueError('shift must have a valid shift_id')
        return v


class AgentStatusType(str, Enum):
    """Agent status types"""
    AVAILABLE = "available"
    BUSY = "busy"
    BREAK = "break"
    LUNCH = "lunch"
    OFFLINE = "offline"
    TRAINING = "training"
    MEETING = "meeting"


class AgentStatusPayload(BaseModel):
    """Payload for AGENT_STATUS_CHANGED event"""
    agent_id: str = Field(..., description="Agent identifier")
    old_status: Optional[AgentStatusType] = Field(None, description="Previous status")
    new_status: AgentStatusType = Field(..., description="New status")
    reason: Optional[str] = Field(None, description="Reason for status change")
    duration: Optional[int] = Field(None, ge=0, description="Expected duration in minutes")


class QueueMetrics(BaseModel):
    """Queue metrics structure"""
    calls_in_queue: int = Field(..., ge=0, description="Current calls in queue")
    avg_wait_time: int = Field(..., ge=0, description="Average wait time in seconds")
    service_level: float = Field(..., ge=0, le=1, description="Current service level")
    abandonment_rate: float = Field(..., ge=0, le=1, description="Abandonment rate")
    longest_wait: Optional[int] = Field(None, ge=0, description="Longest wait time in seconds")


class QueueMetricsPayload(BaseModel):
    """Payload for QUEUE_METRICS_UPDATE event"""
    queue_id: str = Field(..., description="Queue identifier")
    service_id: str = Field(..., description="Service identifier")
    group_id: Optional[str] = Field(None, description="Group identifier")
    metrics: QueueMetrics = Field(..., description="Current queue metrics")
    threshold_alerts: Optional[List[str]] = Field(None, description="Active threshold alerts")


class SLAAlertLevel(str, Enum):
    """SLA alert levels"""
    WARNING = "warning"
    CRITICAL = "critical"
    SEVERE = "severe"


class SLAAlertPayload(BaseModel):
    """Payload for SLA_ALERT event"""
    alert_id: str = Field(..., description="Unique alert identifier")
    service_id: str = Field(..., description="Service identifier")
    group_id: Optional[str] = Field(None, description="Group identifier")
    alert_level: SLAAlertLevel = Field(..., description="Alert severity level")
    metric_type: str = Field(..., description="Type of metric triggering alert")
    current_value: float = Field(..., description="Current metric value")
    threshold_value: float = Field(..., description="Threshold value that was breached")
    message: str = Field(..., description="Alert message")
    suggested_actions: Optional[List[str]] = Field(None, description="Suggested corrective actions")


# Union type for all event payloads
EventPayloadUnion = Union[
    ForecastUpdatePayload,
    ForecastCalculatedPayload,
    ScheduleChangePayload,
    ScheduleOptimizedPayload,
    ShiftAssignedPayload,
    AgentStatusPayload,
    QueueMetricsPayload,
    SLAAlertPayload
]