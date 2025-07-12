"""
BDD Reference Data Management and Configuration API
Based on: 17-reference-data-management-configuration.feature
"""

from fastapi import APIRouter, HTTPException, Query, Path, Body
from typing import List, Dict, Optional, Any, Union
from datetime import datetime, date, time, timedelta
from pydantic import BaseModel, Field, constr, validator
from enum import Enum
import uuid
import random

router = APIRouter()

# Enums
class WorkRuleMode(str, Enum):
    WITH_ROTATION = "with_rotation"
    WITHOUT_ROTATION = "without_rotation"

class ShiftType(str, Enum):
    MORNING = "morning"
    AFTERNOON = "afternoon"
    EVENING = "evening"
    NIGHT = "night"

class EventRegularity(str, Enum):
    ONCE = "once"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class VacationSchemeType(str, Enum):
    STANDARD_ANNUAL = "standard_annual"
    SENIOR_EMPLOYEE = "senior_employee"
    PART_TIME = "part_time"
    PROBATIONARY = "probationary"

class AbsenceCategory(str, Enum):
    SICK_LEAVE = "SICK"
    VACATION = "VAC"
    PERSONAL_LEAVE = "PTO"
    TRAINING = "TRN"
    JURY_DUTY = "JURY"
    BEREAVEMENT = "BER"
    MEDICAL_APPOINTMENT = "MED"
    EMERGENCY = "EMG"

class ChannelType(str, Enum):
    VOICE_INBOUND = "voice_inbound"
    VOICE_OUTBOUND = "voice_outbound"
    EMAIL = "email"
    CHAT = "chat"
    SOCIAL_MEDIA = "social_media"
    VIDEO = "video"

class RoleCategory(str, Enum):
    SYSTEM = "system"
    BUSINESS = "business"

class StatusCategory(str, Enum):
    PRODUCTIVE = "productive"
    NECESSARY_NON_PRODUCTIVE = "necessary_non_productive"
    ADMINISTRATIVE = "administrative"
    UNAVAILABLE = "unavailable"

# Models
class ShiftPattern(BaseModel):
    shift_type: ShiftType
    start_time: str = Field(pattern=r'^\d{2}:\d{2}$')
    start_time_range_end: Optional[str] = Field(None, pattern=r'^\d{2}:\d{2}$')
    duration_hours: float = Field(ge=1, le=12)
    duration_range_end: Optional[float] = Field(None, ge=1, le=12)
    break_integration: bool = True

class RotationPattern(BaseModel):
    pattern_type: str = Field(description="simple, complex, or flexible")
    pattern_code: Optional[str] = Field(None, description="e.g., WWWWWRR for 5 work 2 rest")
    description: str
    demand_driven: bool = False

class WorkRuleConstraints(BaseModel):
    min_hours_between_shifts: int = Field(default=11, ge=8, le=24)
    max_consecutive_hours: int = Field(default=40, ge=8, le=60)
    max_consecutive_days: int = Field(default=6, ge=1, le=14)
    shift_distance_rules: Optional[Dict[str, Any]] = None

class WorkRule(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    rule_name: str
    mode: WorkRuleMode
    consider_holidays: bool = True
    time_zone: str = Field(default="Europe/Moscow")
    mandatory_shifts_by_day: bool = False
    shift_patterns: List[ShiftPattern]
    rotation_patterns: Optional[List[RotationPattern]] = None
    constraints: WorkRuleConstraints
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = Field(default_factory=datetime.now)

class TrainingEvent(BaseModel):
    event_name: str
    regularity: EventRegularity
    weekdays: List[str] = Field(description="Monday, Tuesday, etc.")
    time_interval: str = Field(pattern=r'^\d{2}:\d{2}-\d{2}:\d{2}$')
    duration_minutes: int = Field(ge=15, le=480)
    participation_type: str = Field(description="Group or Individual")
    participant_range: str = Field(description="e.g., 5-10")
    skill_requirement: Optional[str] = None

class MeetingActivity(BaseModel):
    meeting_type: str = Field(description="daily, weekly, monthly")
    mandatory_attendance: bool
    combine_with_others: bool = False
    find_common_time: bool = True
    resource_requirements: Optional[List[str]] = None

class ProjectActivity(BaseModel):
    project_name: str
    project_mode: str = Field(description="inbound_priority or outbound_priority")
    priority_level: int = Field(ge=1, le=100)
    target_duration_minutes: int
    work_plan_volume: int
    project_period: Dict[str, date]

class Event(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str = Field(description="training, meeting, or project")
    training_config: Optional[TrainingEvent] = None
    meeting_config: Optional[MeetingActivity] = None
    project_config: Optional[ProjectActivity] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class VacationScheme(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    scheme_name: str
    scheme_type: VacationSchemeType
    total_days: int = Field(ge=0, le=365)
    periods: int = Field(default=1, ge=1, le=4)
    minimum_block_days: int = Field(default=7, ge=1)
    maximum_block_days: int = Field(default=28, ge=1)
    notice_period_days: int = Field(default=14, ge=1)
    approval_chain: List[str] = Field(default=["supervisor", "hr", "director"])
    blackout_periods: List[Dict[str, str]] = Field(default=[])
    carryover_allowed: bool = False
    carryover_days: Optional[int] = Field(None, ge=0, le=14)
    calculation_method: str = Field(default="calendar_days")
    accumulation_rate: Optional[float] = Field(None, description="Days per month")
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = Field(default_factory=datetime.now)
    is_active: bool = True

class AbsenceReason(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    category: AbsenceCategory
    code: str
    description: str
    impact_on_schedule: str
    payroll_integration: str
    advance_notice_required: str
    documentation_required: str = Field(description="Yes/No/Sometimes")
    approval_level: str = Field(description="Supervisor/HR/Director")
    maximum_duration_days: Optional[int] = None
    frequency_limits: Optional[Dict[str, int]] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class ServiceGroup(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    service_level: str = Field(description="top_level or group_level")
    name: str
    parent_service_id: Optional[str] = None
    channel_type: ChannelType
    skill_requirements: List[str] = Field(default=[])
    service_level_target: Dict[str, int] = Field(default={"percentage": 80, "seconds": 20})
    operating_hours: Dict[str, str] = Field(default={})
    capacity_limits: Optional[int] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class ServiceLevelConfig(BaseModel):
    service_level_target: float = Field(ge=70, le=95, default=80)
    answer_time_target: int = Field(ge=10, le=60, default=20)
    threshold_warning: float = Field(ge=60, le=85, default=75)
    threshold_critical: float = Field(ge=50, le=75, default=65)
    measurement_period: str = Field(default="30min")
    alert_frequency: str = Field(default="1min")
    group_id: Optional[str] = None
    override_parent: bool = False

    @validator('threshold_warning')
    def validate_warning_threshold(cls, v, values):
        if 'service_level_target' in values and v >= values['service_level_target']:
            raise ValueError('Warning threshold must be less than target')
        return v

    @validator('threshold_critical')
    def validate_critical_threshold(cls, v, values):
        if 'threshold_warning' in values and v >= values['threshold_warning']:
            raise ValueError('Critical threshold must be less than warning threshold')
        return v

class SystemRole(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    role_category: RoleCategory
    role_name: str
    scope: str = Field(description="global, multi-department, personal, geographic, department, team")
    permissions: List[str] = Field(default=[])
    parent_role_id: Optional[str] = None
    inherit_permissions: bool = True
    time_based_access: Optional[Dict[str, Any]] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class CommunicationChannel(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    channel_category: str
    channel_type: ChannelType
    characteristics: str
    concurrent_handling: str = Field(description="single or multiple")
    response_time_sla: Dict[str, int] = Field(default={})
    skill_requirements: List[str] = Field(default=[])
    priority_level: int = Field(ge=1, le=5, default=3)
    escalation_paths: List[Dict[str, Any]] = Field(default=[])
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class Holiday(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    holiday_name: str
    holiday_date: date
    holiday_type: str = Field(description="national, religious, company, regional")
    is_working_day: bool = False
    pay_rate_multiplier: float = Field(default=1.0, ge=1.0, le=3.0)
    regions: List[str] = Field(default=[])
    substitution_allowed: bool = False
    substitute_date: Optional[date] = None

class ProductionCalendar(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    calendar_year: int
    holidays: List[Holiday]
    pre_holiday_schedule_adjustment: bool = True
    post_holiday_schedule_adjustment: bool = True
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = Field(default_factory=datetime.now)

class AgentStatusType(BaseModel):
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    status_name: str
    status_category: StatusCategory
    productivity_impact: str = Field(description="positive, neutral, negative")
    reporting_classification: str
    maximum_duration_minutes: Optional[int] = None
    approval_required: bool = False
    auto_transition_enabled: bool = False
    auto_transition_to: Optional[str] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

# Endpoints

@router.post("/references/work-rules", response_model=WorkRule, tags=["references"])
async def create_work_rule(work_rule: WorkRule):
    """
    Configure Work Rules with Rotation Patterns
    BDD: Scenario: Configure Work Rules with Rotation Patterns (lines 12-39)
    """
    # Validate rotation patterns if mode is with_rotation
    if work_rule.mode == WorkRuleMode.WITH_ROTATION and not work_rule.rotation_patterns:
        raise HTTPException(status_code=422, detail="Rotation patterns required for rotation mode")
    
    # Simulate saving to database
    work_rule.id = str(uuid.uuid4())
    work_rule.created_at = datetime.now()
    work_rule.updated_at = datetime.now()
    
    return work_rule

@router.get("/references/work-rules", response_model=List[WorkRule], tags=["references"])
async def get_work_rules():
    """Get all work rules"""
    # Return sample work rules
    return [
        WorkRule(
            rule_name="Standard 5/2",
            mode=WorkRuleMode.WITH_ROTATION,
            shift_patterns=[
                ShiftPattern(
                    shift_type=ShiftType.MORNING,
                    start_time="09:00",
                    duration_hours=8
                )
            ],
            rotation_patterns=[
                RotationPattern(
                    pattern_type="simple",
                    pattern_code="WWWWWRR",
                    description="5 work days, 2 rest days"
                )
            ],
            constraints=WorkRuleConstraints()
        ),
        WorkRule(
            rule_name="Flexible Shifts",
            mode=WorkRuleMode.WITHOUT_ROTATION,
            shift_patterns=[
                ShiftPattern(
                    shift_type=ShiftType.MORNING,
                    start_time="08:00",
                    start_time_range_end="10:00",
                    duration_hours=7,
                    duration_range_end=9
                )
            ],
            constraints=WorkRuleConstraints()
        )
    ]

@router.post("/references/events", response_model=Event, tags=["references"])
async def create_event(event: Event):
    """
    Configure Events and Internal Activities
    BDD: Scenario: Configure Events and Internal Activities (lines 41-69)
    """
    # Validate that exactly one config type is provided
    config_count = sum([
        event.training_config is not None,
        event.meeting_config is not None,
        event.project_config is not None
    ])
    
    if config_count != 1:
        raise HTTPException(
            status_code=422,
            detail="Exactly one event configuration must be provided"
        )
    
    # Set event type based on config
    if event.training_config:
        event.event_type = "training"
    elif event.meeting_config:
        event.event_type = "meeting"
    elif event.project_config:
        event.event_type = "project"
    
    event.id = str(uuid.uuid4())
    event.created_at = datetime.now()
    
    return event

@router.get("/references/events", response_model=List[Event], tags=["references"])
async def get_events(event_type: Optional[str] = Query(None)):
    """Get all events, optionally filtered by type"""
    # Return sample events
    events = [
        Event(
            event_type="training",
            training_config=TrainingEvent(
                event_name="Weekly English Training",
                regularity=EventRegularity.WEEKLY,
                weekdays=["Monday", "Wednesday"],
                time_interval="14:00-16:00",
                duration_minutes=120,
                participation_type="Group",
                participant_range="5-10",
                skill_requirement="English Level B1+"
            )
        ),
        Event(
            event_type="meeting",
            meeting_config=MeetingActivity(
                meeting_type="daily",
                mandatory_attendance=True,
                combine_with_others=False,
                find_common_time=True,
                resource_requirements=["Conference Room", "Projector"]
            )
        )
    ]
    
    if event_type:
        events = [e for e in events if e.event_type == event_type]
    
    return events

@router.post("/references/vacation-schemes", response_model=VacationScheme, tags=["references"])
async def create_vacation_scheme(scheme: VacationScheme):
    """
    Configure Vacation Schemes and Policies
    BDD: Scenario: Configure Vacation Schemes and Policies (lines 71-94)
    """
    # Validate minimum <= maximum block days
    if scheme.minimum_block_days > scheme.maximum_block_days:
        raise HTTPException(
            status_code=422,
            detail="Minimum block days cannot exceed maximum block days"
        )
    
    # Validate carryover days if enabled
    if scheme.carryover_allowed and not scheme.carryover_days:
        scheme.carryover_days = 7  # Default carryover
    
    scheme.id = str(uuid.uuid4())
    scheme.created_at = datetime.now()
    scheme.updated_at = datetime.now()
    
    return scheme

@router.put("/references/vacation-schemes/{scheme_id}", response_model=VacationScheme, tags=["references"])
async def update_vacation_scheme(
    scheme_id: str = Path(description="Vacation scheme ID"),
    scheme: VacationScheme = Body()
):
    """
    Edit existing vacation scheme
    BDD: Scenario: Edit existing vacation scheme (lines 96-106)
    """
    # Simulate finding existing scheme
    scheme.id = scheme_id
    scheme.updated_at = datetime.now()
    
    # In real implementation, would preserve employee assignments
    # and log changes to audit trail
    
    return scheme

@router.delete("/references/vacation-schemes/{scheme_id}", tags=["references"])
async def delete_vacation_scheme(
    scheme_id: str = Path(description="Vacation scheme ID"),
    action: str = Query(description="delete, archive, or reassign")
):
    """
    Delete vacation scheme with validation
    BDD: Scenario: Delete vacation scheme with validation (lines 108-121)
    """
    # Simulate validation checks
    validation_results = {
        "employee_assignments": random.choice([0, 5, 10]),
        "future_vacations": random.choice([0, 3, 7]),
        "historical_data": True
    }
    
    if validation_results["employee_assignments"] > 0 and action == "delete":
        raise HTTPException(
            status_code=409,
            detail=f"Cannot delete: {validation_results['employee_assignments']} employees assigned"
        )
    
    if action == "archive":
        return {
            "message": "Vacation scheme archived",
            "scheme_id": scheme_id,
            "archived_at": datetime.now()
        }
    elif action == "reassign":
        return {
            "message": "Ready for reassignment",
            "scheme_id": scheme_id,
            "employees_to_reassign": validation_results["employee_assignments"]
        }
    else:
        return {
            "message": "Vacation scheme deleted",
            "scheme_id": scheme_id,
            "deleted_at": datetime.now()
        }

@router.post("/references/absence-reasons", response_model=AbsenceReason, tags=["references"])
async def create_absence_reason(reason: AbsenceReason):
    """
    Configure Absence Reason Categories
    BDD: Scenario: Configure Absence Reason Categories (lines 135-155)
    """
    reason.id = str(uuid.uuid4())
    reason.created_at = datetime.now()
    
    # Set default frequency limits if not provided
    if not reason.frequency_limits:
        reason.frequency_limits = {
            "per_month": 2,
            "per_year": 10
        }
    
    return reason

@router.get("/references/absence-reasons", response_model=List[AbsenceReason], tags=["references"])
async def get_absence_reasons():
    """Get all absence reason configurations"""
    return [
        AbsenceReason(
            category=AbsenceCategory.SICK_LEAVE,
            code="SICK",
            description="Sick leave",
            impact_on_schedule="Unplanned replacement",
            payroll_integration="Paid/Unpaid based on policy",
            advance_notice_required="None",
            documentation_required="Yes",
            approval_level="Supervisor",
            maximum_duration_days=30
        ),
        AbsenceReason(
            category=AbsenceCategory.VACATION,
            code="VAC",
            description="Annual vacation",
            impact_on_schedule="Planned coverage",
            payroll_integration="Paid time off",
            advance_notice_required="14 days",
            documentation_required="No",
            approval_level="Supervisor"
        )
    ]

@router.post("/references/service-groups", response_model=ServiceGroup, tags=["references"])
async def create_service_group(group: ServiceGroup):
    """
    Configure Services and Service Groups
    BDD: Scenario: Configure Services and Service Groups (lines 157-177)
    """
    # Validate parent service exists if group level
    if group.service_level == "group_level" and not group.parent_service_id:
        raise HTTPException(
            status_code=422,
            detail="Group level services must have a parent service"
        )
    
    group.id = str(uuid.uuid4())
    group.created_at = datetime.now()
    
    return group

@router.get("/references/service-groups", response_model=List[ServiceGroup], tags=["references"])
async def get_service_groups(service_level: Optional[str] = Query(None)):
    """Get service groups, optionally filtered by level"""
    groups = [
        ServiceGroup(
            service_level="top_level",
            name="Technical Support",
            channel_type=ChannelType.VOICE_INBOUND,
            skill_requirements=["technical_knowledge"],
            service_level_target={"percentage": 80, "seconds": 20}
        ),
        ServiceGroup(
            service_level="group_level",
            name="Level 1 Support",
            parent_service_id="tech_support_001",
            channel_type=ChannelType.VOICE_INBOUND,
            skill_requirements=["basic_troubleshooting"],
            capacity_limits=50
        )
    ]
    
    if service_level:
        groups = [g for g in groups if g.service_level == service_level]
    
    return groups

@router.post("/configuration/service-level-settings", response_model=ServiceLevelConfig, tags=["references"])
async def configure_service_level(config: ServiceLevelConfig):
    """
    Configure 80/20 Format Service Level Settings with UI Components
    BDD: Scenario: Configure 80/20 Format Service Level Settings (lines 179-206)
    """
    # Additional validation is handled by Pydantic validators
    
    # Calculate achievability score
    achievability_score = 100.0
    if config.service_level_target > 90:
        achievability_score -= 20
    if config.answer_time_target < 15:
        achievability_score -= 15
    
    return {
        **config.dict(),
        "achievability_score": achievability_score,
        "estimated_operator_requirement": random.randint(45, 65)
    }

@router.post("/references/roles", response_model=SystemRole, tags=["references"])
async def create_system_role(role: SystemRole):
    """
    Configure System Roles and Permissions
    BDD: Scenario: Configure System Roles and Permissions (lines 208-231)
    """
    role.id = str(uuid.uuid4())
    role.created_at = datetime.now()
    
    # If inheriting from parent, add parent permissions
    if role.inherit_permissions and role.parent_role_id:
        # In real implementation, would fetch parent permissions
        parent_permissions = ["System_AccessWorkerList", "System_ViewReports"]
        role.permissions = list(set(role.permissions + parent_permissions))
    
    return role

@router.get("/references/roles", response_model=List[SystemRole], tags=["references"])
async def get_system_roles(category: Optional[RoleCategory] = Query(None)):
    """Get system roles, optionally filtered by category"""
    roles = [
        SystemRole(
            role_category=RoleCategory.SYSTEM,
            role_name="Administrator",
            scope="global",
            permissions=["System_*"]  # All permissions
        ),
        SystemRole(
            role_category=RoleCategory.BUSINESS,
            role_name="Regional Manager",
            scope="geographic",
            permissions=[
                "System_AccessForecastList",
                "System_AccessWorkerList",
                "System_ViewReports"
            ]
        )
    ]
    
    if category:
        roles = [r for r in roles if r.role_category == category]
    
    return roles

@router.post("/references/channels", response_model=CommunicationChannel, tags=["references"])
async def create_communication_channel(channel: CommunicationChannel):
    """
    Configure Communication Channels and Types
    BDD: Scenario: Configure Communication Channels and Types (lines 233-251)
    """
    channel.id = str(uuid.uuid4())
    channel.created_at = datetime.now()
    
    # Set default response time SLA based on channel type
    if not channel.response_time_sla:
        if channel.channel_type == ChannelType.EMAIL:
            channel.response_time_sla = {"hours": 4}
        elif channel.channel_type == ChannelType.CHAT:
            channel.response_time_sla = {"minutes": 2}
        else:
            channel.response_time_sla = {"seconds": 20}
    
    return channel

@router.post("/references/calendars", response_model=ProductionCalendar, tags=["references"])
async def create_production_calendar(calendar: ProductionCalendar):
    """
    Configure Production Calendar and Holidays
    BDD: Scenario: Configure Production Calendar and Holidays (lines 253-273)
    """
    calendar.id = str(uuid.uuid4())
    calendar.created_at = datetime.now()
    calendar.updated_at = datetime.now()
    
    # Validate holiday dates are within calendar year
    for holiday in calendar.holidays:
        if holiday.holiday_date.year != calendar.calendar_year:
            raise HTTPException(
                status_code=422,
                detail=f"Holiday {holiday.holiday_name} date must be in year {calendar.calendar_year}"
            )
    
    return calendar

@router.get("/references/calendars/{year}", response_model=ProductionCalendar, tags=["references"])
async def get_production_calendar(year: int = Path(description="Calendar year")):
    """Get production calendar for specific year"""
    # Return sample calendar
    holidays = [
        Holiday(
            holiday_name="New Year's Day",
            holiday_date=date(year, 1, 1),
            holiday_type="national",
            is_working_day=False,
            pay_rate_multiplier=2.0
        ),
        Holiday(
            holiday_name="International Women's Day",
            holiday_date=date(year, 3, 8),
            holiday_type="national",
            is_working_day=False,
            pay_rate_multiplier=1.5
        )
    ]
    
    return ProductionCalendar(
        calendar_year=year,
        holidays=holidays
    )

@router.post("/references/agent-status-types", response_model=AgentStatusType, tags=["references"])
async def create_agent_status_type(status_type: AgentStatusType):
    """
    Configure Agent Status Types for Productivity Measurement
    BDD: Scenario: Configure Agent Status Types (lines 355-382)
    """
    status_type.id = str(uuid.uuid4())
    status_type.created_at = datetime.now()
    
    # Set default maximum duration based on category
    if not status_type.maximum_duration_minutes:
        if status_type.status_category == StatusCategory.NECESSARY_NON_PRODUCTIVE:
            if "break" in status_type.status_name.lower():
                status_type.maximum_duration_minutes = 15
            elif "lunch" in status_type.status_name.lower():
                status_type.maximum_duration_minutes = 60
    
    return status_type

@router.get("/references/agent-status-types", response_model=List[AgentStatusType], tags=["references"])
async def get_agent_status_types(category: Optional[StatusCategory] = Query(None)):
    """Get agent status types, optionally filtered by category"""
    status_types = [
        AgentStatusType(
            status_name="Available",
            status_category=StatusCategory.PRODUCTIVE,
            productivity_impact="positive",
            reporting_classification="Revenue-generating"
        ),
        AgentStatusType(
            status_name="Break",
            status_category=StatusCategory.NECESSARY_NON_PRODUCTIVE,
            productivity_impact="neutral",
            reporting_classification="Required overhead",
            maximum_duration_minutes=15
        ),
        AgentStatusType(
            status_name="Training",
            status_category=StatusCategory.ADMINISTRATIVE,
            productivity_impact="neutral",
            reporting_classification="Operational support",
            approval_required=True
        )
    ]
    
    if category:
        status_types = [s for s in status_types if s.status_category == category]
    
    return status_types

@router.get("/references/absenteeism/calculate", tags=["references"])
async def calculate_absenteeism(
    period_type: str = Query(description="daily, weekly, monthly, quarterly"),
    department_id: Optional[str] = Query(None),
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None)
):
    """
    Configure Absenteeism Percentage Tracking with Calculation Formulas
    BDD: Scenario: Configure Absenteeism Percentage Tracking (lines 297-324)
    """
    # Simulate calculation based on period
    base_rate = random.uniform(3, 15)
    trend_direction = random.choice(["increasing", "decreasing", "stable"])
    trend_value = random.uniform(-3, 3) if trend_direction != "stable" else 0
    
    # Determine alert level based on rate
    alert_level = "none"
    action_required = "Monitor only"
    
    if base_rate > 15:
        alert_level = "critical"
        action_required = "Management escalation"
    elif base_rate > 10:
        alert_level = "red"
        action_required = "HR intervention"
    elif base_rate > 5:
        alert_level = "yellow"
        action_required = "Supervisor notification"
    
    return {
        "period_type": period_type,
        "calculation_period": {
            "start": start_date or date.today() - timedelta(days=30),
            "end": end_date or date.today()
        },
        "absenteeism_rate": round(base_rate, 2),
        "formula_used": "(Total Absent Hours / Total Scheduled Hours) * 100",
        "trend_analysis": {
            "direction": trend_direction,
            "change_percentage": round(trend_value, 2),
            "previous_period_rate": round(base_rate - trend_value, 2)
        },
        "threshold_status": {
            "alert_level": alert_level,
            "action_required": action_required
        },
        "department_average": round(base_rate + random.uniform(-2, 2), 2) if department_id else None,
        "seasonal_adjustment": {
            "factor": 1.2 if date.today().month in [12, 1, 7] else 1.0,
            "adjusted_rate": round(base_rate * (1.2 if date.today().month in [12, 1, 7] else 1.0), 2)
        }
    }

@router.get("/references/employment-rates/monthly", tags=["references"])
async def get_monthly_employment_rates(
    year: int = Query(description="Year for employment rates"),
    month: int = Query(ge=1, le=12, description="Month (1-12)"),
    department_id: Optional[str] = Query(None)
):
    """
    Configure Employment Rate by Month for Workforce Planning
    BDD: Scenario: Configure Employment Rate by Month (lines 326-353)
    """
    # Generate sample employment rates
    employees = []
    
    for i in range(10):
        base_rate = 100 if random.random() > 0.3 else random.choice([50, 75])
        employees.append({
            "employee_id": f"EMP{i+1:03d}",
            "employee_name": f"Employee {i+1}",
            "employment_type": "full_time" if base_rate == 100 else "part_time",
            "base_rate": base_rate,
            "monthly_rate": base_rate * random.uniform(0.9, 1.1),
            "actual_hours": random.randint(140, 180),
            "standard_hours": 168,
            "rate_calculation": "actual_hours / standard_hours * 100"
        })
    
    # Calculate aggregates
    avg_rate = sum(e["monthly_rate"] for e in employees) / len(employees)
    
    return {
        "period": {
            "year": year,
            "month": month,
            "month_name": datetime(year, month, 1).strftime("%B")
        },
        "employment_rates": employees,
        "summary": {
            "average_rate": round(avg_rate, 2),
            "minimum_rate": round(min(e["monthly_rate"] for e in employees), 2),
            "maximum_rate": round(max(e["monthly_rate"] for e in employees), 2),
            "total_employees": len(employees),
            "compliance_status": "compliant" if avg_rate >= 80 else "below_minimum"
        },
        "planning_rules": {
            "minimum_department_rate": 80,
            "maximum_individual_rate": 120,
            "approval_required_above": 110
        },
        "seasonal_factors": {
            "current_month_factor": 1.1 if month in [7, 8, 12] else 1.0,
            "next_month_projection": avg_rate * (1.1 if (month + 1) in [7, 8, 12] else 1.0)
        }
    }

# Additional endpoints for remaining scenarios would follow the same pattern...