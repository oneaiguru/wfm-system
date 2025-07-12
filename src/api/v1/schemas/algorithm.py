from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field, ConfigDict, validator
from datetime import datetime


class ErlangCRequest(BaseModel):
    """Request schema for Erlang C calculations"""
    model_config = ConfigDict(from_attributes=True)
    
    arrival_rate: float = Field(..., gt=0, description="Call arrival rate (calls per hour)")
    service_time: float = Field(..., gt=0, description="Average service time (minutes)")
    agents: int = Field(..., gt=0, description="Number of agents")
    target_service_level: float = Field(..., ge=0, le=100, description="Target service level percentage")
    
    @validator('target_service_level')
    def validate_service_level(cls, v):
        if not 0 <= v <= 100:
            raise ValueError('Service level must be between 0 and 100')
        return v
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "arrival_rate": 120,
                "service_time": 3.5,
                "agents": 15,
                "target_service_level": 80
            }
        }


class ErlangCResponse(BaseModel):
    """Response schema for Erlang C calculations"""
    model_config = ConfigDict(from_attributes=True)
    
    utilization: float = Field(..., description="System utilization percentage")
    probability_wait: float = Field(..., description="Probability of waiting (0-1)")
    average_wait_time: float = Field(..., description="Average wait time (minutes)")
    service_level: float = Field(..., description="Achieved service level percentage")
    agents_required: int = Field(..., description="Agents required for target service level")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "utilization": 70.5,
                "probability_wait": 0.15,
                "average_wait_time": 0.8,
                "service_level": 82.3,
                "agents_required": 14
            }
        }


class ForecastDataPoint(BaseModel):
    """Single forecast data point"""
    model_config = ConfigDict(from_attributes=True)
    
    timestamp: datetime = Field(..., description="Time point")
    value: float = Field(..., description="Historical or predicted value")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "timestamp": "2024-01-01T10:00:00Z",
                "value": 125.5
            }
        }


class ForecastRequest(BaseModel):
    """Request schema for forecasting"""
    model_config = ConfigDict(from_attributes=True)
    
    historical_data: List[ForecastDataPoint] = Field(..., description="Historical data points")
    forecast_horizon: int = Field(..., gt=0, description="Number of periods to forecast")
    seasonality: Optional[str] = Field("auto", description="Seasonality pattern (auto, daily, weekly, monthly)")
    confidence_level: float = Field(0.95, ge=0.8, le=0.99, description="Confidence level for intervals")
    
    @validator('historical_data')
    def validate_historical_data(cls, v):
        if len(v) < 10:
            raise ValueError('At least 10 historical data points required')
        return v
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "historical_data": [
                    {"timestamp": "2024-01-01T10:00:00Z", "value": 120},
                    {"timestamp": "2024-01-01T11:00:00Z", "value": 135}
                ],
                "forecast_horizon": 24,
                "seasonality": "daily",
                "confidence_level": 0.95
            }
        }


class ForecastResponse(BaseModel):
    """Response schema for forecasting"""
    model_config = ConfigDict(from_attributes=True)
    
    timestamps: List[datetime] = Field(..., description="Forecast timestamps")
    predicted_values: List[float] = Field(..., description="Predicted values")
    confidence_intervals: List[Dict[str, float]] = Field(..., description="Confidence intervals (lower, upper)")
    model_accuracy: float = Field(..., description="Model accuracy score")
    seasonality_detected: str = Field(..., description="Detected seasonality pattern")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "timestamps": ["2024-01-02T10:00:00Z", "2024-01-02T11:00:00Z"],
                "predicted_values": [125.5, 140.2],
                "confidence_intervals": [
                    {"lower": 115.0, "upper": 136.0},
                    {"lower": 128.5, "upper": 152.0}
                ],
                "model_accuracy": 0.85,
                "seasonality_detected": "daily"
            }
        }


class ScheduleConstraint(BaseModel):
    """Schedule constraint definition"""
    model_config = ConfigDict(from_attributes=True)
    
    constraint_type: str = Field(..., description="Constraint type (min_agents, max_agents, skill_requirement)")
    time_period: str = Field(..., description="Time period (hourly, daily, weekly)")
    value: float = Field(..., description="Constraint value")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "constraint_type": "min_agents",
                "time_period": "hourly",
                "value": 5
            }
        }


class AgentSchedulePreference(BaseModel):
    """Agent schedule preference"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    preferred_shifts: List[str] = Field(..., description="Preferred shift times")
    unavailable_periods: List[Dict[str, datetime]] = Field(default=[], description="Unavailable periods")
    max_hours_per_week: int = Field(40, description="Maximum hours per week")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "preferred_shifts": ["08:00-16:00", "09:00-17:00"],
                "unavailable_periods": [
                    {"start": "2024-01-01T14:00:00Z", "end": "2024-01-01T15:00:00Z"}
                ],
                "max_hours_per_week": 40
            }
        }


class ScheduleOptimizationRequest(BaseModel):
    """Request schema for schedule optimization"""
    model_config = ConfigDict(from_attributes=True)
    
    agents: List[AgentSchedulePreference] = Field(..., description="Agent preferences")
    requirements: List[ForecastDataPoint] = Field(..., description="Staffing requirements by time period")
    constraints: List[ScheduleConstraint] = Field(..., description="Scheduling constraints")
    optimization_objective: str = Field("minimize_cost", description="Optimization objective")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agents": [
                    {
                        "agent_id": "agent_1",
                        "preferred_shifts": ["08:00-16:00"],
                        "unavailable_periods": [],
                        "max_hours_per_week": 40
                    }
                ],
                "requirements": [
                    {"timestamp": "2024-01-01T10:00:00Z", "value": 15}
                ],
                "constraints": [
                    {
                        "constraint_type": "min_agents",
                        "time_period": "hourly",
                        "value": 5
                    }
                ],
                "optimization_objective": "minimize_cost"
            }
        }


class AgentSchedule(BaseModel):
    """Individual agent schedule"""
    model_config = ConfigDict(from_attributes=True)
    
    agent_id: str = Field(..., description="Agent identifier")
    shifts: List[Dict[str, Any]] = Field(..., description="Scheduled shifts")
    total_hours: float = Field(..., description="Total scheduled hours")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "agent_id": "agent_1",
                "shifts": [
                    {
                        "date": "2024-01-01",
                        "start": "08:00",
                        "end": "16:00",
                        "duration": 8
                    }
                ],
                "total_hours": 40
            }
        }


class ScheduleOptimizationResponse(BaseModel):
    """Response schema for schedule optimization"""
    model_config = ConfigDict(from_attributes=True)
    
    schedules: List[AgentSchedule] = Field(..., description="Optimized agent schedules")
    coverage_metrics: Dict[str, float] = Field(..., description="Coverage metrics")
    optimization_score: float = Field(..., description="Optimization score (0-1)")
    constraints_satisfied: bool = Field(..., description="Whether all constraints are satisfied")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "schedules": [
                    {
                        "agent_id": "agent_1",
                        "shifts": [
                            {
                                "date": "2024-01-01",
                                "start": "08:00",
                                "end": "16:00",
                                "duration": 8
                            }
                        ],
                        "total_hours": 40
                    }
                ],
                "coverage_metrics": {
                    "average_coverage": 95.5,
                    "peak_coverage": 100.0,
                    "off_peak_coverage": 90.0
                },
                "optimization_score": 0.92,
                "constraints_satisfied": True
            }
        }