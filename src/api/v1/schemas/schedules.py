"""
Schedule Management Schemas
Pydantic models for schedule management API endpoints
"""

from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from datetime import datetime, date, time
from decimal import Decimal
from enum import Enum
import uuid


# Enums for better type safety
class ScheduleStatus(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ACTIVE = "active"
    ARCHIVED = "archived"


class ScheduleType(str, Enum):
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    DAILY = "daily"
    CUSTOM = "custom"


class ShiftType(str, Enum):
    REGULAR = "regular"
    OVERTIME = "overtime"
    HOLIDAY = "holiday"
    ON_CALL = "on_call"


class ConflictSeverity(str, Enum):
    CRITICAL = "critical"
    MAJOR = "major"
    MINOR = "minor"
    WARNING = "warning"


class ConflictStatus(str, Enum):
    OPEN = "open"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    IGNORED = "ignored"


# Base schemas
class ScheduleBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    start_date: date
    end_date: date
    schedule_type: ScheduleType = ScheduleType.WEEKLY
    department_id: Optional[uuid.UUID] = None
    template_id: Optional[uuid.UUID] = None
    configuration: Optional[Dict[str, Any]] = None

    @validator('end_date')
    def validate_end_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('End date must be after start date')
        return v


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    schedule_type: Optional[ScheduleType] = None
    status: Optional[ScheduleStatus] = None
    department_id: Optional[uuid.UUID] = None
    template_id: Optional[uuid.UUID] = None
    configuration: Optional[Dict[str, Any]] = None


class ScheduleResponse(ScheduleBase):
    id: uuid.UUID
    status: ScheduleStatus
    organization_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    published_at: Optional[datetime] = None
    shift_count: int = 0
    employee_count: int = 0
    created_by: uuid.UUID
    published_by: Optional[uuid.UUID] = None

    class Config:
        orm_mode = True


# Shift schemas
class ShiftBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    code: str = Field(..., min_length=1, max_length=20)
    description: Optional[str] = None
    start_time: time
    end_time: time
    duration_minutes: int = Field(..., ge=0)
    break_duration_minutes: int = Field(0, ge=0)
    break_start_time: Optional[time] = None
    lunch_duration_minutes: int = Field(0, ge=0)
    lunch_start_time: Optional[time] = None
    shift_type: ShiftType = ShiftType.REGULAR
    min_staff: int = Field(1, ge=1)
    max_staff: Optional[int] = Field(None, ge=1)
    required_skills: Optional[List[str]] = None
    skill_requirements: Optional[Dict[str, Any]] = None
    color_code: str = Field("#3498db", regex=r'^#[0-9A-Fa-f]{6}$')
    display_order: int = Field(0, ge=0)

    @validator('max_staff')
    def validate_max_staff(cls, v, values):
        if v is not None and 'min_staff' in values and v < values['min_staff']:
            raise ValueError('max_staff must be greater than or equal to min_staff')
        return v


class ShiftCreate(ShiftBase):
    pass


class ShiftUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    code: Optional[str] = Field(None, min_length=1, max_length=20)
    description: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    duration_minutes: Optional[int] = Field(None, ge=0)
    break_duration_minutes: Optional[int] = Field(None, ge=0)
    break_start_time: Optional[time] = None
    lunch_duration_minutes: Optional[int] = Field(None, ge=0)
    lunch_start_time: Optional[time] = None
    shift_type: Optional[ShiftType] = None
    min_staff: Optional[int] = Field(None, ge=1)
    max_staff: Optional[int] = Field(None, ge=1)
    required_skills: Optional[List[str]] = None
    skill_requirements: Optional[Dict[str, Any]] = None
    color_code: Optional[str] = Field(None, regex=r'^#[0-9A-Fa-f]{6}$')
    display_order: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ShiftResponse(ShiftBase):
    id: uuid.UUID
    organization_id: uuid.UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


# Schedule shift schemas
class ScheduleShiftBase(BaseModel):
    employee_id: uuid.UUID
    shift_id: uuid.UUID
    date: date
    start_time: time
    end_time: time
    override_start_time: Optional[time] = None
    override_end_time: Optional[time] = None
    override_reason: Optional[str] = None
    notes: Optional[str] = None
    break_times: Optional[List[Dict[str, Any]]] = None


class ScheduleShiftCreate(ScheduleShiftBase):
    pass


class ScheduleShiftUpdate(BaseModel):
    employee_id: Optional[uuid.UUID] = None
    shift_id: Optional[uuid.UUID] = None
    date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    override_start_time: Optional[time] = None
    override_end_time: Optional[time] = None
    override_reason: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    break_times: Optional[List[Dict[str, Any]]] = None


class ScheduleShiftResponse(ScheduleShiftBase):
    id: uuid.UUID
    schedule_id: uuid.UUID
    status: str
    employee_name: str
    shift_name: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


# Schedule generation and optimization schemas
class ScheduleGenerate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    start_date: date
    end_date: date
    department_id: Optional[uuid.UUID] = None
    template_id: Optional[uuid.UUID] = None
    optimization_level: str = Field("standard", regex=r'^(basic|standard|advanced)$')
    constraints: Dict[str, Any] = Field(default_factory=dict)
    preferences: Dict[str, Any] = Field(default_factory=dict)
    coverage_requirements: Optional[Dict[str, Any]] = None

    @validator('end_date')
    def validate_end_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('End date must be after start date')
        return v


class ScheduleOptimize(BaseModel):
    optimization_goals: List[str] = Field(default=["minimize_cost", "maximize_coverage"])
    constraints: Dict[str, Any] = Field(default_factory=dict)
    max_iterations: int = Field(100, ge=1, le=1000)
    optimization_level: str = Field("standard", regex=r'^(basic|standard|advanced)$')
    preserve_assignments: bool = Field(True)
    allow_overtime: bool = Field(False)
    
    @validator('optimization_goals')
    def validate_goals(cls, v):
        valid_goals = [
            "minimize_cost", "maximize_coverage", "maximize_satisfaction",
            "minimize_overtime", "balance_workload", "optimize_skills"
        ]
        for goal in v:
            if goal not in valid_goals:
                raise ValueError(f"Invalid optimization goal: {goal}")
        return v


class ScheduleValidate(BaseModel):
    schedule_data: Dict[str, Any]
    validation_rules: Optional[List[str]] = None
    strict_validation: bool = Field(True)


class ScheduleBulkUpdate(BaseModel):
    operations: List[Dict[str, Any]] = Field(..., min_items=1)
    validate_before_apply: bool = Field(True)
    rollback_on_error: bool = Field(True)


class ScheduleCopy(BaseModel):
    source_schedule_id: uuid.UUID
    name: str = Field(..., min_length=1, max_length=255)
    start_date: date
    end_date: date
    copy_assignments: bool = Field(True)
    copy_constraints: bool = Field(True)
    target_department_id: Optional[uuid.UUID] = None


class ScheduleMerge(BaseModel):
    source_schedule_ids: List[uuid.UUID] = Field(..., min_items=2)
    name: str = Field(..., min_length=1, max_length=255)
    merge_strategy: str = Field("combine", regex=r'^(combine|overlay|priority)$')
    conflict_resolution: str = Field("manual", regex=r'^(manual|auto|priority)$')
    priority_order: Optional[List[uuid.UUID]] = None


class ScheduleTemplate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    template_type: str = Field("weekly", regex=r'^(weekly|monthly|custom)$')
    pattern_config: Dict[str, Any]
    shift_patterns: List[Dict[str, Any]]
    skills_required: Optional[List[str]] = None
    coverage_requirements: Optional[Dict[str, Any]] = None
    is_active: bool = Field(True)


# Conflict management schemas
class ScheduleConflictBase(BaseModel):
    conflict_type: str = Field(..., min_length=1, max_length=50)
    severity: ConflictSeverity
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1)
    affected_employees: Optional[List[str]] = None
    affected_shifts: Optional[List[Dict[str, Any]]] = None
    affected_dates: Optional[List[date]] = None
    suggested_resolution: Optional[Dict[str, Any]] = None


class ScheduleConflictResponse(ScheduleConflictBase):
    id: uuid.UUID
    schedule_id: uuid.UUID
    status: ConflictStatus
    resolution_notes: Optional[str] = None
    detected_at: datetime
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[uuid.UUID] = None

    class Config:
        orm_mode = True


class ConflictResolution(BaseModel):
    resolution_type: str = Field(..., min_length=1, max_length=50)
    resolution_data: Dict[str, Any]
    resolution_notes: Optional[str] = None
    apply_immediately: bool = Field(True)


# Schedule variant schemas
class ScheduleVariantBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    variant_data: Dict[str, Any]
    changes_summary: Optional[Dict[str, Any]] = None


class ScheduleVariantCreate(ScheduleVariantBase):
    pass


class ScheduleVariantUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    variant_data: Optional[Dict[str, Any]] = None
    changes_summary: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None


class ScheduleVariantResponse(ScheduleVariantBase):
    id: uuid.UUID
    schedule_id: uuid.UUID
    cost_impact: Optional[Decimal] = None
    coverage_impact: Optional[Decimal] = None
    employee_satisfaction: Optional[Decimal] = None
    is_active: bool
    is_approved: bool
    created_by: uuid.UUID
    created_at: datetime
    approved_by: Optional[uuid.UUID] = None
    approved_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Employee schedule access schemas
class EmployeeScheduleResponse(BaseModel):
    employee_id: uuid.UUID
    employee_name: str
    schedule_data: List[Dict[str, Any]]
    total_hours: Optional[Decimal] = None
    overtime_hours: Optional[Decimal] = None
    conflicts: List[Dict[str, Any]] = Field(default_factory=list)
    last_updated: datetime

    class Config:
        orm_mode = True


class EmployeeScheduleMonthly(BaseModel):
    employee_id: uuid.UUID
    month: int = Field(..., ge=1, le=12)
    year: int = Field(..., ge=2020, le=2030)
    schedule_data: List[Dict[str, Any]]
    monthly_summary: Dict[str, Any]


class EmployeeScheduleWeekly(BaseModel):
    employee_id: uuid.UUID
    week_start: date
    week_end: date
    schedule_data: List[Dict[str, Any]]
    weekly_summary: Dict[str, Any]


class ScheduleAcknowledgment(BaseModel):
    schedule_id: uuid.UUID
    acknowledged_at: datetime = Field(default_factory=datetime.utcnow)
    comments: Optional[str] = None


# Publication schemas
class SchedulePublishRequest(BaseModel):
    publication_type: str = Field("full", regex=r'^(full|partial|update)$')
    target_audience: Dict[str, Any]
    channels: List[str] = Field(default=["email", "app"])
    scheduled_at: Optional[datetime] = None
    template_name: Optional[str] = None
    custom_message: Optional[str] = None
    include_changes: bool = Field(True)

    @validator('channels')
    def validate_channels(cls, v):
        valid_channels = ["email", "app", "sms", "push", "portal"]
        for channel in v:
            if channel not in valid_channels:
                raise ValueError(f"Invalid channel: {channel}")
        return v


class SchedulePublishResponse(BaseModel):
    id: uuid.UUID
    schedule_id: uuid.UUID
    publication_type: str
    status: str
    target_audience: Dict[str, Any]
    channels: List[str]
    scheduled_at: Optional[datetime] = None
    published_at: Optional[datetime] = None
    delivery_stats: Optional[Dict[str, Any]] = None
    created_by: uuid.UUID
    created_at: datetime

    class Config:
        orm_mode = True


# Constraint schemas
class ScheduleConstraintBase(BaseModel):
    constraint_type: str = Field(..., min_length=1, max_length=50)
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    constraint_data: Dict[str, Any]
    priority: int = Field(1, ge=1, le=5)
    is_hard_constraint: bool = Field(False)
    valid_from: date
    valid_to: Optional[date] = None
    days_of_week: Optional[List[int]] = Field(None, min_items=1, max_items=7)
    time_ranges: Optional[List[Dict[str, Any]]] = None

    @validator('days_of_week')
    def validate_days_of_week(cls, v):
        if v is not None:
            for day in v:
                if not 0 <= day <= 6:
                    raise ValueError('Days of week must be between 0 (Sunday) and 6 (Saturday)')
        return v

    @validator('valid_to')
    def validate_valid_to(cls, v, values):
        if v is not None and 'valid_from' in values and v <= values['valid_from']:
            raise ValueError('valid_to must be after valid_from')
        return v


class ScheduleConstraintCreate(ScheduleConstraintBase):
    employee_id: uuid.UUID


class ScheduleConstraintUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    constraint_data: Optional[Dict[str, Any]] = None
    priority: Optional[int] = Field(None, ge=1, le=5)
    is_hard_constraint: Optional[bool] = None
    valid_from: Optional[date] = None
    valid_to: Optional[date] = None
    days_of_week: Optional[List[int]] = Field(None, min_items=1, max_items=7)
    time_ranges: Optional[List[Dict[str, Any]]] = None
    is_active: Optional[bool] = None


class ScheduleConstraintResponse(ScheduleConstraintBase):
    id: uuid.UUID
    employee_id: uuid.UUID
    employee_name: str
    is_active: bool
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime
    approved_by: Optional[uuid.UUID] = None
    approved_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Rule schemas
class ScheduleRuleBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    rule_type: str = Field(..., min_length=1, max_length=50)
    rule_category: str = Field(..., min_length=1, max_length=50)
    rule_config: Dict[str, Any]
    violation_penalty: Decimal = Field(Decimal('0.00'), ge=0)
    priority: int = Field(1, ge=1, le=5)
    applies_to: str = Field("all", regex=r'^(all|department|role|employee)$')
    scope_ids: Optional[List[str]] = None
    effective_date: date
    expiry_date: Optional[date] = None


class ScheduleRuleCreate(ScheduleRuleBase):
    pass


class ScheduleRuleUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    rule_config: Optional[Dict[str, Any]] = None
    violation_penalty: Optional[Decimal] = Field(None, ge=0)
    priority: Optional[int] = Field(None, ge=1, le=5)
    applies_to: Optional[str] = Field(None, regex=r'^(all|department|role|employee)$')
    scope_ids: Optional[List[str]] = None
    effective_date: Optional[date] = None
    expiry_date: Optional[date] = None
    is_active: Optional[bool] = None


class ScheduleRuleResponse(ScheduleRuleBase):
    id: uuid.UUID
    organization_id: uuid.UUID
    is_active: bool
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


# Optimization result schemas
class OptimizationResult(BaseModel):
    optimization_id: uuid.UUID
    schedule_id: uuid.UUID
    status: str
    algorithm_used: str
    objective_scores: Dict[str, Any]
    execution_time_ms: Optional[int] = None
    iterations: Optional[int] = None
    improvement_percentage: Optional[Decimal] = None
    created_at: datetime
    completed_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Analytics and reporting schemas
class ScheduleAnalytics(BaseModel):
    schedule_id: uuid.UUID
    coverage_metrics: Dict[str, Any]
    cost_metrics: Dict[str, Any]
    employee_metrics: Dict[str, Any]
    compliance_metrics: Dict[str, Any]
    generated_at: datetime


class ScheduleReportRequest(BaseModel):
    report_type: str = Field(..., min_length=1, max_length=50)
    period_start: date
    period_end: date
    parameters: Dict[str, Any] = Field(default_factory=dict)
    format: str = Field("json", regex=r'^(json|csv|pdf|excel)$')
    include_details: bool = Field(True)

    @validator('period_end')
    def validate_period_end(cls, v, values):
        if 'period_start' in values and v <= values['period_start']:
            raise ValueError('period_end must be after period_start')
        return v


class ScheduleReportResponse(BaseModel):
    id: uuid.UUID
    name: str
    report_type: str
    category: str
    status: str
    file_path: Optional[str] = None
    file_size: Optional[int] = None
    period_start: date
    period_end: date
    generated_by: uuid.UUID
    generated_at: datetime
    expires_at: Optional[datetime] = None

    class Config:
        orm_mode = True


# Validation response schemas
class ValidationResult(BaseModel):
    is_valid: bool
    errors: List[Dict[str, Any]] = Field(default_factory=list)
    warnings: List[Dict[str, Any]] = Field(default_factory=list)
    suggestions: List[Dict[str, Any]] = Field(default_factory=list)
    validation_summary: Dict[str, Any]


class BulkOperationResult(BaseModel):
    total_operations: int
    successful_operations: int
    failed_operations: int
    results: List[Dict[str, Any]]
    errors: List[Dict[str, Any]] = Field(default_factory=list)
    execution_time_ms: Optional[int] = None