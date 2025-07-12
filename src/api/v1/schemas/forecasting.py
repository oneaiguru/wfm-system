"""
Pydantic schemas for Forecasting & Planning API
Complete implementation of all 25 endpoints schemas
"""

from typing import List, Dict, Any, Optional, Union
from datetime import datetime, date, time
from uuid import UUID
from pydantic import BaseModel, Field, validator
from enum import Enum


# Enums for type safety
class ForecastType(str, Enum):
    call_volume = "call_volume"
    aht = "aht"
    shrinkage = "shrinkage"
    occupancy = "occupancy"
    service_level = "service_level"


class ForecastMethod(str, Enum):
    manual = "manual"
    ml = "ml"
    hybrid = "hybrid"
    imported = "imported"


class Granularity(str, Enum):
    fifteen_min = "15min"
    thirty_min = "30min"
    one_hour = "1hour"
    one_day = "1day"


class ForecastStatus(str, Enum):
    draft = "draft"
    generating = "generating"
    active = "active"
    archived = "archived"


class ModelType(str, Enum):
    arima = "arima"
    lstm = "lstm"
    prophet = "prophet"
    ensemble = "ensemble"


class ModelStatus(str, Enum):
    training = "training"
    active = "active"
    deprecated = "deprecated"


class ScenarioType(str, Enum):
    what_if = "what_if"
    sensitivity = "sensitivity"
    stress = "stress"


# Base schemas
class ForecastBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    forecast_type: ForecastType
    method: ForecastMethod = ForecastMethod.ml
    granularity: Granularity = Granularity.thirty_min
    start_date: datetime
    end_date: datetime
    department_id: Optional[UUID] = None
    service_id: Optional[str] = None

    @validator('end_date')
    def validate_end_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class ForecastCreate(ForecastBase):
    data: Optional[List[Dict[str, Any]]] = None
    metadata: Optional[Dict[str, Any]] = None


class ForecastUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    data: Optional[List[Dict[str, Any]]] = None
    metadata: Optional[Dict[str, Any]] = None
    status: Optional[ForecastStatus] = None


class ForecastResponse(ForecastBase):
    id: UUID
    status: ForecastStatus
    version: int
    accuracy_metrics: Optional[Dict[str, Any]] = None
    data_points_count: int = 0
    organization_id: Optional[UUID] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


# Forecast Data Point schemas
class ForecastDataPointBase(BaseModel):
    timestamp: datetime
    predicted_value: float
    actual_value: Optional[float] = None
    confidence_interval_lower: Optional[float] = None
    confidence_interval_upper: Optional[float] = None
    seasonal_factor: float = 1.0
    trend_factor: float = 1.0
    holiday_factor: float = 1.0


class ForecastDataPointResponse(ForecastDataPointBase):
    id: UUID
    forecast_id: UUID
    date: date
    time_of_day: time
    day_of_week: int
    week_of_year: int
    month: int
    quarter: int
    year: int
    
    class Config:
        orm_mode = True


# Forecast Generation schemas
class ForecastGenerate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    forecast_type: ForecastType
    start_date: datetime
    end_date: datetime
    department_id: UUID
    service_id: Optional[str] = None
    granularity: Granularity = Granularity.thirty_min
    model_type: str = "auto"  # auto, arima, lstm, prophet, ensemble
    use_historical_data: bool = True
    historical_months: int = Field(12, ge=1, le=36)
    include_holidays: bool = True
    seasonal_adjustment: bool = True
    
    @validator('end_date')
    def validate_end_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class ForecastImport(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    forecast_type: ForecastType
    granularity: Granularity
    data: List[Dict[str, Any]] = Field(..., min_items=1)
    metadata: Optional[Dict[str, Any]] = None
    
    @validator('data')
    def validate_data_format(cls, v):
        required_fields = ['timestamp', 'value']
        for item in v:
            for field in required_fields:
                if field not in item:
                    raise ValueError(f'Each data item must contain {field}')
        return v


class ForecastExport(BaseModel):
    forecast_id: UUID
    format: str = Field("json", regex="^(json|csv|excel)$")
    include_metadata: bool = True
    date_range: Optional[Dict[str, datetime]] = None


class GrowthFactorApplication(BaseModel):
    forecast_id: UUID
    growth_factor: float = Field(..., gt=0)
    apply_to_period: str = Field("all", regex="^(all|specific_dates|weekdays|weekends)$")
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    
    @validator('end_date')
    def validate_end_date(cls, v, values):
        if v and 'start_date' in values and values['start_date'] and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class SeasonalAdjustment(BaseModel):
    forecast_id: UUID
    seasonal_factors: Dict[str, float] = Field(..., min_items=1)
    adjustment_type: str = Field("multiplicative", regex="^(multiplicative|additive)$")
    
    @validator('seasonal_factors')
    def validate_seasonal_factors(cls, v):
        valid_keys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
                     'january', 'february', 'march', 'april', 'may', 'june',
                     'july', 'august', 'september', 'october', 'november', 'december']
        for key in v.keys():
            if key.lower() not in valid_keys:
                raise ValueError(f'Invalid seasonal factor key: {key}')
        return v


class ForecastComparison(BaseModel):
    forecast_ids: List[UUID] = Field(..., min_items=2, max_items=10)
    comparison_metrics: List[str] = Field(["mape", "rmse", "mad"], min_items=1)
    comparison_period: Optional[str] = None


class ForecastAccuracy(BaseModel):
    forecast_id: UUID
    actual_data: List[Dict[str, Any]] = Field(..., min_items=1)
    metrics: List[str] = Field(["mape", "rmse", "mad", "bias"], min_items=1)
    
    @validator('actual_data')
    def validate_actual_data(cls, v):
        for item in v:
            if 'timestamp' not in item or 'value' not in item:
                raise ValueError('Each actual data item must contain timestamp and value')
        return v


# Staffing and Planning schemas
class StaffingCalculation(BaseModel):
    forecast_id: UUID
    service_level_target: float = Field(..., ge=0.0, le=1.0)
    max_wait_time: int = Field(..., ge=0)  # seconds
    shrinkage_factor: float = Field(0.30, ge=0.0, le=1.0)
    skill_requirements: Optional[Dict[str, Any]] = None
    cost_parameters: Optional[Dict[str, Any]] = None


class ErlangCCalculation(BaseModel):
    call_volume: int = Field(..., ge=0)
    average_handle_time: int = Field(..., ge=1)  # seconds
    service_level_target: float = Field(..., ge=0.0, le=1.0)
    max_wait_time: int = Field(..., ge=0)  # seconds


class ErlangCResponse(BaseModel):
    required_agents: int
    service_level: float
    average_speed_to_answer: float
    occupancy: float
    probability_of_wait: float
    calculations: Dict[str, Any]


class MultiSkillOptimization(BaseModel):
    forecast_data: List[Dict[str, Any]] = Field(..., min_items=1)
    skill_matrix: Dict[str, List[str]] = Field(..., min_items=1)  # employee_id -> skills
    service_level_targets: Dict[str, float] = Field(..., min_items=1)  # skill -> target
    max_wait_times: Dict[str, int] = Field(..., min_items=1)  # skill -> max_wait_seconds
    
    @validator('service_level_targets')
    def validate_service_levels(cls, v):
        for skill, target in v.items():
            if not (0.0 <= target <= 1.0):
                raise ValueError(f'Service level target for {skill} must be between 0.0 and 1.0')
        return v


class StaffingPlanBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    forecast_id: UUID
    department_id: Optional[UUID] = None
    service_level_target: float = Field(..., ge=0.0, le=1.0)
    max_wait_time: int = Field(..., ge=0)
    shrinkage_factor: float = Field(0.30, ge=0.0, le=1.0)


class StaffingPlanCreate(StaffingPlanBase):
    pass


class StaffingPlanResponse(StaffingPlanBase):
    id: UUID
    staffing_data: Optional[Dict[str, Any]] = None
    total_fte: Optional[float] = None
    peak_staff: Optional[int] = None
    estimated_cost: Optional[float] = None
    cost_breakdown: Optional[Dict[str, Any]] = None
    status: str
    approved_by: Optional[UUID] = None
    approved_at: Optional[datetime] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class PlanValidation(BaseModel):
    staffing_plan_id: UUID
    validation_type: str = Field("feasibility", regex="^(feasibility|cost|compliance)$")
    parameters: Optional[Dict[str, Any]] = None


# ML Integration schemas
class MLModelTraining(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    model_type: ModelType
    training_data_start: datetime
    training_data_end: datetime
    hyperparameters: Optional[Dict[str, Any]] = None
    cross_validation: bool = True
    auto_tune: bool = True
    
    @validator('training_data_end')
    def validate_training_end(cls, v, values):
        if 'training_data_start' in values and v <= values['training_data_start']:
            raise ValueError('training_data_end must be after training_data_start')
        return v


class MLModelResponse(BaseModel):
    id: UUID
    name: str
    model_type: ModelType
    algorithm: str
    version: str
    accuracy_metrics: Dict[str, Any]
    status: ModelStatus
    is_default: bool
    created_by: Optional[UUID] = None
    created_at: datetime
    trained_at: Optional[datetime] = None
    last_used: Optional[datetime] = None
    
    class Config:
        orm_mode = True


class MLPrediction(BaseModel):
    model_id: UUID
    start_date: datetime
    end_date: datetime
    granularity: Granularity = Granularity.thirty_min
    confidence_intervals: bool = True
    
    @validator('end_date')
    def validate_end_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class MLModelPerformance(BaseModel):
    model_id: UUID
    test_data_start: datetime
    test_data_end: datetime
    metrics: List[str] = Field(["mape", "rmse", "mae", "r2"], min_items=1)


# What-if Analysis schemas
class ScenarioAnalysis(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    scenario_type: ScenarioType
    base_forecast_id: UUID
    parameters: Dict[str, Any] = Field(..., min_items=1)
    what_if_changes: List[Dict[str, Any]] = Field(..., min_items=1)
    
    @validator('what_if_changes')
    def validate_what_if_changes(cls, v):
        for change in v:
            if 'parameter' not in change or 'value' not in change:
                raise ValueError('Each what-if change must contain parameter and value')
        return v


class ScenarioComparison(BaseModel):
    scenario_ids: List[UUID] = Field(..., min_items=2, max_items=5)
    comparison_metrics: List[str] = Field(["staffing_impact", "cost_impact", "service_level"], min_items=1)


class ScenarioResponse(BaseModel):
    id: UUID
    name: str
    scenario_type: ScenarioType
    forecast_id: UUID
    parameters: Dict[str, Any]
    results: Optional[Dict[str, Any]] = None
    impact_analysis: Optional[Dict[str, Any]] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    
    class Config:
        orm_mode = True


# Planning Recommendations schemas
class PlanningRecommendations(BaseModel):
    department_id: UUID
    forecast_id: UUID
    optimization_goals: List[str] = Field(["minimize_cost", "maximize_service_level"], min_items=1)
    constraints: Optional[Dict[str, Any]] = None
    
    @validator('optimization_goals')
    def validate_goals(cls, v):
        valid_goals = ['minimize_cost', 'maximize_service_level', 'minimize_staff', 'maximize_efficiency']
        for goal in v:
            if goal not in valid_goals:
                raise ValueError(f'Invalid optimization goal: {goal}')
        return v


class RecommendationResponse(BaseModel):
    recommendations: List[Dict[str, Any]]
    analysis: Dict[str, Any]
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    generated_at: datetime


# Request and Response models for legacy endpoint compatibility
class GrowthFactorRequest(BaseModel):
    service_id: str
    growth_factor: float = Field(..., gt=0)
    start_date: datetime
    end_date: datetime


class GrowthFactorResponse(BaseModel):
    status: str
    data: List[Dict[str, Any]]
    summary: Dict[str, Any]
    timestamp: str


class ForecastCalculationRequest(BaseModel):
    service_id: str
    forecast_calls: int = Field(..., ge=0)
    avg_handle_time: int = Field(..., ge=1)
    service_level_target: float = Field(0.8, ge=0.0, le=1.0)
    target_wait_time: int = Field(20, ge=0)


class ForecastCalculationResponse(BaseModel):
    status: str
    data: Dict[str, Any]
    timestamp: str


class MLForecastRequest(BaseModel):
    service_id: str
    forecast_days: int = Field(30, ge=1, le=365)
    include_seasonality: bool = True
    include_holidays: bool = True


class MLForecastResponse(BaseModel):
    status: str
    data: Dict[str, Any]
    timestamp: str


# Batch operation schemas
class BatchForecastGenerate(BaseModel):
    forecasts: List[ForecastGenerate] = Field(..., min_items=1, max_items=10)
    batch_name: str = Field(..., min_length=1, max_length=255)


class BatchOperationResponse(BaseModel):
    batch_id: UUID
    total_items: int
    successful_items: int
    failed_items: int
    results: List[Dict[str, Any]]
    status: str
    created_at: datetime


# List and pagination schemas
class ForecastListQuery(BaseModel):
    skip: int = Field(0, ge=0)
    limit: int = Field(100, ge=1, le=1000)
    forecast_type: Optional[ForecastType] = None
    department_id: Optional[UUID] = None
    service_id: Optional[str] = None
    status: Optional[ForecastStatus] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None


class ModelListQuery(BaseModel):
    skip: int = Field(0, ge=0)
    limit: int = Field(100, ge=1, le=1000)
    model_type: Optional[ModelType] = None
    status: Optional[ModelStatus] = None
    is_default: Optional[bool] = None


class PaginatedResponse(BaseModel):
    items: List[Dict[str, Any]]
    total: int
    skip: int
    limit: int
    has_next: bool
    has_previous: bool


# Error response schemas
class ErrorResponse(BaseModel):
    error: str
    message: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime


class ValidationErrorResponse(BaseModel):
    error: str = "validation_error"
    message: str
    field_errors: Dict[str, List[str]]
    timestamp: datetime