"""
Pydantic schemas for WFM API v1
"""

from .personnel import (
    Service,
    ServiceBase,
    Group,
    GroupBase,
    Agent,
    AgentBase,
    PersonnelResponse
)

from .historic import (
    ServiceGroupDataInterval,
    ServiceGroupDataResponse,
    AgentStatusDataResponse,
    AgentLoginDataResponse,
    AgentCallsDataResponse,
    AgentChatsWorkTimeResponse
)

from .online import (
    AgentStatusResponse,
    GroupOnlineLoadResponse
)

from .status import (
    AgentStatusUpdate,
    AgentStatusUpdateResponse
)

from .algorithm import (
    ErlangCRequest,
    ErlangCResponse,
    ForecastDataPoint,
    ForecastRequest,
    ForecastResponse,
    ScheduleConstraint,
    AgentSchedulePreference,
    ScheduleOptimizationRequest,
    AgentSchedule,
    ScheduleOptimizationResponse
)

__all__ = [
    # Personnel
    "Service",
    "ServiceBase", 
    "Group",
    "GroupBase",
    "Agent",
    "AgentBase",
    "PersonnelResponse",
    
    # Historic
    "ServiceGroupDataInterval",
    "ServiceGroupDataResponse",
    "AgentStatusDataResponse",
    "AgentLoginDataResponse",
    "AgentCallsDataResponse",
    "AgentChatsWorkTimeResponse",
    
    # Online
    "AgentStatusResponse",
    "GroupOnlineLoadResponse",
    
    # Status
    "AgentStatusUpdate",
    "AgentStatusUpdateResponse",
    
    # Algorithm
    "ErlangCRequest",
    "ErlangCResponse",
    "ForecastDataPoint",
    "ForecastRequest",
    "ForecastResponse",
    "ScheduleConstraint",
    "AgentSchedulePreference",
    "ScheduleOptimizationRequest",
    "AgentSchedule",
    "ScheduleOptimizationResponse",
]