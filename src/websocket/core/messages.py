"""
WebSocket Message Models
High-performance message serialization and validation
"""

import json
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, Union
from enum import Enum
from pydantic import BaseModel, Field
import orjson


class WebSocketEventType(str, Enum):
    """WebSocket event types for real-time WFM operations"""
    
    # System events
    CONNECTION_ESTABLISHED = "connection.established"
    CONNECTION_CLOSED = "connection.closed"
    PING = "ping"
    PONG = "pong"
    ERROR = "error"
    
    # Forecasting events
    FORECAST_UPDATED = "forecast.updated"
    FORECAST_CALCULATED = "forecast.calculated"
    FORECAST_ERROR = "forecast.error"
    
    # Schedule events
    SCHEDULE_CHANGED = "schedule.changed"
    SCHEDULE_OPTIMIZED = "schedule.optimized"
    SHIFT_ASSIGNED = "shift.assigned"
    SHIFT_SWAPPED = "shift.swapped"
    
    # Real-time monitoring
    AGENT_STATUS_CHANGED = "agent.status.changed"
    QUEUE_METRICS_UPDATE = "queue.metrics.update"
    SLA_ALERT = "sla.alert"
    SYSTEM_HEALTH = "system.health"
    
    # Skill management
    SKILL_ASSIGNED = "skill.assigned"
    SKILL_REMOVED = "skill.removed"
    SKILL_LEVEL_CHANGED = "skill.level.changed"
    
    # Vacancy events
    VACANCY_CREATED = "vacancy.created"
    VACANCY_FILLED = "vacancy.filled"
    STAFFING_GAP_DETECTED = "staffing.gap.detected"
    
    # Algorithm calculation events
    ALGORITHM_STARTED = "algorithm.started"
    ALGORITHM_COMPLETED = "algorithm.completed"
    ALGORITHM_ERROR = "algorithm.error"
    ERLANG_CALCULATION_COMPLETE = "erlang.calculation.complete"
    OPTIMIZATION_COMPLETE = "optimization.complete"
    ACCURACY_METRICS_READY = "accuracy.metrics.ready"
    
    # Subscription management
    SUBSCRIPTION_CONFIRMED = "subscription.confirmed"
    UNSUBSCRIPTION_CONFIRMED = "unsubscription.confirmed"
    ROOM_JOINED = "room.joined"
    ROOM_LEFT = "room.left"


class WebSocketMessage(BaseModel):
    """
    High-performance WebSocket message model
    Optimized for <100ms serialization/deserialization
    """
    
    type: str = Field(..., description="Message type")
    payload: Dict[str, Any] = Field(default_factory=dict, description="Message payload")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Message metadata")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Message timestamp")
    correlation_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Correlation ID")
    
    class Config:
        """Pydantic configuration for performance"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
        # Use orjson for faster JSON serialization
        json_loads = orjson.loads
        json_dumps = orjson.dumps
    
    def to_json(self) -> str:
        """
        Fast JSON serialization using orjson
        ~5x faster than standard json.dumps
        """
        return orjson.dumps(self.dict()).decode('utf-8')
    
    @classmethod
    def from_json(cls, json_str: str) -> 'WebSocketMessage':
        """
        Fast JSON deserialization using orjson
        ~5x faster than standard json.loads
        """
        try:
            data = orjson.loads(json_str)
            return cls(**data)
        except orjson.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON: {e}")
    
    def to_bytes(self) -> bytes:
        """Convert message to bytes for efficient transmission"""
        return orjson.dumps(self.dict())
    
    @classmethod
    def from_bytes(cls, data: bytes) -> 'WebSocketMessage':
        """Create message from bytes"""
        try:
            json_data = orjson.loads(data)
            return cls(**json_data)
        except orjson.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON bytes: {e}")


class WebSocketError(BaseModel):
    """WebSocket error message structure"""
    
    error_code: str = Field(..., description="Error code")
    error_message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Error details")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    def to_websocket_message(self) -> WebSocketMessage:
        """Convert to WebSocket message format"""
        return WebSocketMessage(
            type=WebSocketEventType.ERROR.value,
            payload=self.dict(),
            timestamp=self.timestamp
        )


class WebSocketCommand(BaseModel):
    """WebSocket command message structure"""
    
    command: str = Field(..., description="Command name")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Command parameters")
    
    def to_websocket_message(self) -> WebSocketMessage:
        """Convert to WebSocket message format"""
        return WebSocketMessage(
            type=f"command.{self.command}",
            payload=self.dict()
        )


class WebSocketSubscription(BaseModel):
    """WebSocket subscription request structure"""
    
    event_types: list[str] = Field(..., description="Event types to subscribe to")
    rooms: list[str] = Field(default_factory=list, description="Rooms to join")
    filters: Dict[str, Any] = Field(default_factory=dict, description="Event filters")
    
    def to_websocket_message(self) -> WebSocketMessage:
        """Convert to WebSocket message format"""
        return WebSocketMessage(
            type="subscription.request",
            payload=self.dict()
        )


# Pre-defined message templates for common operations
PING_MESSAGE = WebSocketMessage(
    type=WebSocketEventType.PING.value,
    payload={"timestamp": datetime.utcnow().isoformat()}
)

PONG_MESSAGE = WebSocketMessage(
    type=WebSocketEventType.PONG.value,
    payload={"timestamp": datetime.utcnow().isoformat()}
)

CONNECTION_ESTABLISHED_MESSAGE = WebSocketMessage(
    type=WebSocketEventType.CONNECTION_ESTABLISHED.value,
    payload={"status": "connected", "timestamp": datetime.utcnow().isoformat()}
)


def create_error_message(error_code: str, error_message: str, details: Optional[Dict[str, Any]] = None) -> WebSocketMessage:
    """Create standardized error message"""
    error = WebSocketError(
        error_code=error_code,
        error_message=error_message,
        details=details or {}
    )
    return error.to_websocket_message()


def create_event_message(event_type: WebSocketEventType, payload: Dict[str, Any]) -> WebSocketMessage:
    """Create standardized event message"""
    return WebSocketMessage(
        type=event_type.value,
        payload=payload
    )


def create_response_message(request_id: str, success: bool, data: Optional[Dict[str, Any]] = None) -> WebSocketMessage:
    """Create standardized response message"""
    return WebSocketMessage(
        type="response",
        payload={
            "request_id": request_id,
            "success": success,
            "data": data or {}
        }
    )