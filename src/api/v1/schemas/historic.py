from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from uuid import UUID


class ServiceGroupDataInterval(BaseModel):
    """Service group metrics for a specific time interval"""
    model_config = ConfigDict(from_attributes=True)
    
    start_interval: datetime = Field(..., description="Interval start time")
    end_interval: datetime = Field(..., description="Interval end time")
    calls_offered: int = Field(..., description="Number of calls offered (received_calls)")
    calls_handled: int = Field(..., description="Number of calls handled (treated_calls)")
    calls_missed: int = Field(..., description="Number of calls missed (miss_calls)")
    not_unique_received: int = Field(..., description="Non-unique contacts received")
    not_unique_treated: int = Field(..., description="Non-unique contacts treated")
    not_unique_missed: int = Field(..., description="Non-unique contacts missed")
    aht: int = Field(..., description="Average handle time in milliseconds")
    post_processing: int = Field(..., description="Post-processing time in milliseconds")
    
    @property
    def service_level(self) -> float:
        """Calculate service level percentage"""
        if self.calls_offered == 0:
            return 0.0
        return (self.calls_handled / self.calls_offered) * 100


class ServiceGroupDataResponse(BaseModel):
    """Response for service group historical metrics"""
    model_config = ConfigDict(from_attributes=True)
    
    service_id: str = Field(..., description="Service identifier")
    group_id: str = Field(..., description="Group identifier")
    intervals: List[ServiceGroupDataInterval] = Field(..., description="Time intervals with metrics")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "service_id": "service_1",
                "group_id": "group_1",
                "intervals": [
                    {
                        "start_interval": "2024-01-01T10:00:00Z",
                        "end_interval": "2024-01-01T10:15:00Z",
                        "calls_offered": 150,
                        "calls_handled": 140,
                        "calls_missed": 10,
                        "not_unique_received": 145,
                        "not_unique_treated": 135,
                        "not_unique_missed": 10,
                        "aht": 180000,
                        "post_processing": 30000
                    }
                ]
            }
        }


class AgentStatusDataResponse(BaseModel):
    """Agent status history response"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    status: str = Field(..., description="Agent status code")
    status_name: str = Field(..., description="Agent status name")
    start_time: datetime = Field(..., description="Status start time")
    end_time: datetime = Field(..., description="Status end time")
    duration: int = Field(..., description="Status duration in milliseconds")
    service_id: Optional[str] = Field(None, description="Service identifier")
    group_id: Optional[str] = Field(None, description="Group identifier")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "status": "AVAILABLE",
                "status_name": "Available",
                "start_time": "2024-01-01T10:00:00Z",
                "end_time": "2024-01-01T10:30:00Z",
                "duration": 1800000,
                "service_id": "service_1",
                "group_id": "group_1"
            }
        }


class AgentLoginDataResponse(BaseModel):
    """Agent login session response"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    login_time: datetime = Field(..., description="Login timestamp")
    logout_time: datetime = Field(..., description="Logout timestamp")
    session_duration: int = Field(..., description="Session duration in milliseconds")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "login_time": "2024-01-01T08:00:00Z",
                "logout_time": "2024-01-01T17:00:00Z",
                "session_duration": 32400000
            }
        }


class AgentCallsDataResponse(BaseModel):
    """Agent calls data response"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    contact_id: str = Field(..., description="Contact/call identifier")
    service_id: str = Field(..., description="Service identifier")
    group_id: str = Field(..., description="Group identifier")
    start_time: datetime = Field(..., description="Call start time")
    end_time: datetime = Field(..., description="Call end time")
    handle_time: int = Field(..., description="Call handle time in milliseconds")
    wrap_time: int = Field(..., description="Wrap-up time in milliseconds")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "contact_id": "call_12345",
                "service_id": "service_1",
                "group_id": "group_1",
                "start_time": "2024-01-01T10:00:00Z",
                "end_time": "2024-01-01T10:05:00Z",
                "handle_time": 240000,
                "wrap_time": 60000
            }
        }


class AgentChatsWorkTimeResponse(BaseModel):
    """Agent chat work time response"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    chat_id: str = Field(..., description="Chat identifier")
    work_start: datetime = Field(..., description="Work start date")
    work_end: datetime = Field(..., description="Work end date")
    overlapped_time: int = Field(..., description="Time with at least 1 chat in milliseconds")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "chat_id": "chat_day_2024-01-01",
                "work_start": "2024-01-01T00:00:00Z",
                "work_end": "2024-01-01T23:59:59Z",
                "overlapped_time": 28800000
            }
        }