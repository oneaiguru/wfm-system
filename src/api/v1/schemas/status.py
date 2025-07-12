from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class AgentStatusUpdate(BaseModel):
    """Schema for updating agent status"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    new_status: str = Field(..., description="New status code")
    status_name: str = Field(..., description="New status name")
    timestamp: datetime = Field(..., description="Status change timestamp")
    reason_code: Optional[str] = Field(None, description="Reason for status change")
    service_id: Optional[str] = Field(None, description="Service context")
    group_id: Optional[str] = Field(None, description="Group context")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "new_status": "BREAK",
                "status_name": "Break",
                "timestamp": "2024-01-01T10:30:00Z",
                "reason_code": "SCHEDULED_BREAK",
                "service_id": "service_1",
                "group_id": "group_1"
            }
        }


class AgentStatusUpdateResponse(BaseModel):
    """Response for status update operation"""
    model_config = ConfigDict(from_attributes=True)
    
    success: bool = Field(..., description="Update success status")
    message: str = Field(..., description="Response message")
    agent_id: str = Field(..., description="Agent identifier")
    previous_status: str = Field(..., description="Previous status code")
    new_status: str = Field(..., description="New status code")
    timestamp: datetime = Field(..., description="Update timestamp")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "Agent status updated successfully",
                "agent_id": "agent_1",
                "previous_status": "AVAILABLE",
                "new_status": "BREAK",
                "timestamp": "2024-01-01T10:30:00Z"
            }
        }