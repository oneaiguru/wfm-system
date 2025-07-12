"""
Algorithm API schemas for request/response models.
Integrates with ALGORITHM-OPUS implementations.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field, ConfigDict, validator
from datetime import datetime


# Import existing schemas from algorithm.py
from .algorithm import (
    ErlangCRequest as BaseErlangCRequest,
    ErlangCResponse as BaseErlangCResponse,
    ForecastRequest,
    ForecastResponse,
    ScheduleOptimizationRequest,
    ScheduleOptimizationResponse as ScheduleGenerationResponse,
    AgentSchedule,
    ScheduleConstraint,
    AgentSchedulePreference
)


# Enhanced Erlang C schemas matching our implementation
class ErlangCRequest(BaseModel):
    """Enhanced Erlang C request with service level corridor support"""
    model_config = ConfigDict(from_attributes=True)
    
    service_id: str = Field(..., description="Service identifier")
    forecast_calls: int = Field(..., gt=0, description="Predicted number of calls per hour")
    avg_handle_time: int = Field(..., gt=0, description="Average handle time in seconds")
    service_level_target: float = Field(0.8, ge=0, le=1, description="Service level target (0.8 = 80%)")
    target_wait_time: int = Field(20, gt=0, description="Target wait time in seconds")
    multi_channel: bool = Field(True, description="Enable multi-channel calculations")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "service_id": "service_001",
                "forecast_calls": 1000,
                "avg_handle_time": 180,
                "service_level_target": 0.85,
                "target_wait_time": 20,
                "multi_channel": True
            }
        }


class ErlangCResponse(BaseModel):
    """Enhanced Erlang C response with performance metrics"""
    model_config = ConfigDict(from_attributes=True)
    
    status: str = Field(..., description="Response status")
    data: Dict[str, Any] = Field(..., description="Calculation results")
    timestamp: datetime = Field(..., description="Response timestamp")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "status": "success",
                "data": {
                    "total_agents_required": 45,
                    "channel_breakdown": [
                        {
                            "channel": "voice",
                            "forecast_calls": 700,
                            "agents_required": 35,
                            "service_level": 0.87,
                            "utilization": 0.82,
                            "wait_time": 15.2
                        }
                    ],
                    "performance_metrics": {
                        "processing_time_ms": 23.5,
                        "sub_100ms_target": True,
                        "calculations_per_second": 42.5
                    }
                },
                "timestamp": "2024-01-01T10:00:00Z"
            }
        }


# Multi-skill optimization schemas
class SkillRequirementSpec(BaseModel):
    """Skill requirement specification"""
    model_config = ConfigDict(from_attributes=True)
    
    skills: List[str] = Field(..., description="Required skills")
    min_level: int = Field(3, ge=1, le=5, description="Minimum skill level")
    priority: int = Field(1, ge=1, le=10, description="Queue priority")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "skills": ["english", "technical"],
                "min_level": 3,
                "priority": 1
            }
        }


class MultiSkillOptimizationRequest(BaseModel):
    """Multi-skill optimization request"""
    model_config = ConfigDict(from_attributes=True)
    
    service_id: str = Field(..., description="Service identifier")
    skill_requirements: Dict[str, SkillRequirementSpec] = Field(..., description="Required skills per queue")
    agent_skills: Dict[str, List[str]] = Field(..., description="Agent skill assignments")
    optimization_objective: str = Field("service_level", description="Optimization target")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "service_id": "service_001",
                "skill_requirements": {
                    "queue_001": {
                        "skills": ["english", "technical"],
                        "min_level": 3,
                        "priority": 1
                    }
                },
                "agent_skills": {
                    "agent_001": ["english", "technical", "sales"]
                },
                "optimization_objective": "service_level"
            }
        }


class MultiSkillOptimizationResponse(BaseModel):
    """Multi-skill optimization response"""
    model_config = ConfigDict(from_attributes=True)
    
    status: str = Field(..., description="Response status")
    data: Dict[str, Any] = Field(..., description="Optimization results")
    timestamp: datetime = Field(..., description="Response timestamp")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "status": "success",
                "data": {
                    "optimization_result": {
                        "allocations": [
                            {
                                "agent_id": "agent_001",
                                "queue_id": "queue_001",
                                "score": 0.95
                            }
                        ],
                        "skill_coverage": 0.98
                    },
                    "routing_rules": [
                        {
                            "agent_id": "agent_001",
                            "primary_queue": "queue_001",
                            "skill_match_score": 0.95,
                            "routing_priority": 1
                        }
                    ],
                    "validation": {
                        "valid": True,
                        "violations": [],
                        "coverage_score": 0.98
                    },
                    "performance_impact": {
                        "service_level_improvement": 0.15,
                        "utilization_improvement": 0.10,
                        "cost_reduction": 0.08
                    }
                },
                "timestamp": "2024-01-01T10:00:00Z"
            }
        }


# ML prediction schemas
class MLModelPredictionRequest(BaseModel):
    """ML model prediction request"""
    model_config = ConfigDict(from_attributes=True)
    
    service_id: str = Field(..., description="Service identifier")
    prediction_horizon: int = Field(24, gt=0, description="Hours to predict ahead")
    include_external_factors: bool = Field(True, description="Include external factors")
    prediction_type: str = Field("workload", description="Type of prediction")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "service_id": "service_001",
                "prediction_horizon": 24,
                "include_external_factors": True,
                "prediction_type": "workload"
            }
        }


class MLModelPredictionResponse(BaseModel):
    """ML model prediction response"""
    model_config = ConfigDict(from_attributes=True)
    
    status: str = Field(..., description="Response status")
    data: Dict[str, Any] = Field(..., description="Prediction results")
    timestamp: datetime = Field(..., description="Response timestamp")
    
    model_config = ConfigDict()
        json_schema_extra = {
            "example": {
                "status": "success",
                "data": {
                    "predictions": [120, 135, 150, 140],
                    "confidence_intervals": {
                        "lower": [110, 125, 140, 130],
                        "upper": [130, 145, 160, 150]
                    },
                    "prediction_quality": {
                        "accuracy_score": 0.85,
                        "confidence_level": 0.9,
                        "model_performance": "excellent"
                    },
                    "actionable_insights": [
                        {
                            "insight": "Increase staffing by 15% during peak hours",
                            "confidence": 0.85,
                            "impact": "high"
                        }
                    ]
                },
                "timestamp": "2024-01-01T10:00:00Z"
            }
        }


# Schedule generation request (reuse existing but add alias)
class ScheduleGenerationRequest(ScheduleOptimizationRequest):
    """Schedule generation request - alias for optimization request"""
    pass