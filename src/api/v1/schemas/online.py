from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class AgentStatusResponse(BaseModel):
    """Real-time agent status response"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    current_status: str = Field(..., description="Current status code")
    status_name: str = Field(..., description="Current status name")
    status_duration: int = Field(..., description="Duration in current status (milliseconds)")
    last_update: datetime = Field(..., description="Last status update timestamp")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "current_status": "AVAILABLE",
                "status_name": "Available",
                "status_duration": 1800000,
                "last_update": "2024-01-01T10:30:00Z"
            }
        }


class GroupOnlineLoadResponse(BaseModel):
    """Real-time group load and performance metrics"""
    model_config = ConfigDict(from_attributes=True)
    
    group_id: str = Field(..., description="Group identifier")
    service_id: str = Field(..., description="Service identifier")
    
    # Queue metrics
    queue_depth: int = Field(..., description="Number of contacts in queue")
    average_wait_time: int = Field(..., description="Average wait time in milliseconds")
    calls_processing: int = Field(..., description="Calls currently being processed")
    
    # Agent availability
    agents_available: int = Field(..., description="Number of available agents")
    agents_busy: int = Field(..., description="Number of busy agents")
    
    # Daily performance metrics
    sla_percentage: float = Field(..., description="Service level agreement percentage")
    calls_received_today: int = Field(..., description="Calls received today")
    calls_answered_today: int = Field(..., description="Calls answered today")
    calls_answered_within_sla: int = Field(..., description="Calls answered within SLA")
    average_handle_time: int = Field(..., description="Average handle time today (milliseconds)")
    
    last_update: datetime = Field(..., description="Last metrics update timestamp")
    
    @property
    def total_agents(self) -> int:
        """Total number of agents in the group"""
        return self.agents_available + self.agents_busy
    
    @property
    def utilization_rate(self) -> float:
        """Agent utilization rate percentage"""
        if self.total_agents == 0:
            return 0.0
        return (self.agents_busy / self.total_agents) * 100
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "group_id": "group_1",
                "service_id": "service_1",
                "queue_depth": 5,
                "average_wait_time": 45000,
                "calls_processing": 8,
                "agents_available": 3,
                "agents_busy": 8,
                "sla_percentage": 85.5,
                "calls_received_today": 450,
                "calls_answered_today": 420,
                "calls_answered_within_sla": 359,
                "average_handle_time": 180000,
                "last_update": "2024-01-01T10:30:00Z"
            }
        }