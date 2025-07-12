"""
Schedule Management Models
SQLAlchemy models for comprehensive schedule management system
"""

from sqlalchemy import Column, String, Integer, DateTime, Boolean, ForeignKey, Text, Date, Time, Numeric, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSON, ARRAY
from datetime import datetime, date, time
import uuid

from ..core.database import Base


class Schedule(Base):
    """Main schedule entity"""
    __tablename__ = "schedules"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Schedule metadata
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    schedule_type = Column(String(50), nullable=False)  # weekly, monthly, daily, custom
    status = Column(String(20), default="draft")  # draft, published, active, archived
    
    # Organizational context
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"), nullable=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Template and configuration
    template_id = Column(UUID(as_uuid=True), ForeignKey("schedule_templates.id"), nullable=True)
    configuration = Column(JSON, nullable=True)  # Schedule configuration
    
    # Audit fields
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    published_at = Column(DateTime, nullable=True)
    published_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    
    # Relationships
    shifts = relationship("ScheduleShift", back_populates="schedule", cascade="all, delete-orphan")
    variants = relationship("ScheduleVariant", back_populates="schedule", cascade="all, delete-orphan")
    conflicts = relationship("ScheduleConflict", back_populates="schedule", cascade="all, delete-orphan")
    template = relationship("ScheduleTemplate")
    
    # Computed properties
    @property
    def shift_count(self):
        return len(self.shifts)
    
    @property
    def employee_count(self):
        return len(set(shift.employee_id for shift in self.shifts))
    
    __table_args__ = (
        Index('idx_schedule_organization', 'organization_id'),
        Index('idx_schedule_department', 'department_id'),
        Index('idx_schedule_dates', 'start_date', 'end_date'),
        Index('idx_schedule_status', 'status'),
        Index('idx_schedule_type', 'schedule_type'),
    )


class ScheduleTemplate(Base):
    """Reusable schedule templates"""
    __tablename__ = "schedule_templates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Template configuration
    template_type = Column(String(50), nullable=False)  # weekly, monthly, custom
    pattern_config = Column(JSON, nullable=False)  # Template pattern configuration
    shift_patterns = Column(JSON, nullable=False)  # Shift pattern definitions
    
    # Requirements
    skills_required = Column(ARRAY(String), nullable=True)
    coverage_requirements = Column(JSON, nullable=True)
    
    # Validity
    valid_from = Column(DateTime, default=datetime.utcnow)
    valid_to = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    schedules = relationship("Schedule", back_populates="template")
    
    __table_args__ = (
        Index('idx_schedule_template_organization', 'organization_id'),
        Index('idx_schedule_template_type', 'template_type'),
        Index('idx_schedule_template_active', 'is_active'),
    )


class Shift(Base):
    """Shift type definitions"""
    __tablename__ = "shifts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    code = Column(String(20), nullable=False)
    description = Column(Text, nullable=True)
    
    # Shift timing
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    
    # Break information
    break_duration_minutes = Column(Integer, default=0)
    break_start_time = Column(Time, nullable=True)
    lunch_duration_minutes = Column(Integer, default=0)
    lunch_start_time = Column(Time, nullable=True)
    
    # Shift properties
    shift_type = Column(String(50), nullable=False)  # regular, overtime, holiday, on_call
    min_staff = Column(Integer, default=1)
    max_staff = Column(Integer, nullable=True)
    
    # Skills and requirements
    required_skills = Column(ARRAY(String), nullable=True)
    skill_requirements = Column(JSON, nullable=True)  # Detailed skill requirements
    
    # UI and display
    color_code = Column(String(7), default="#3498db")
    display_order = Column(Integer, default=0)
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Status
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    schedule_shifts = relationship("ScheduleShift", back_populates="shift")
    
    __table_args__ = (
        Index('idx_shift_organization', 'organization_id'),
        Index('idx_shift_type', 'shift_type'),
        Index('idx_shift_active', 'is_active'),
        Index('idx_shift_code', 'code'),
    )


class ScheduleShift(Base):
    """Individual shift assignments in schedules"""
    __tablename__ = "schedule_shifts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Core relationships
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    shift_id = Column(UUID(as_uuid=True), ForeignKey("shifts.id"), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False)
    
    # Assignment details
    date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    
    # Override capabilities
    override_start_time = Column(Time, nullable=True)
    override_end_time = Column(Time, nullable=True)
    override_reason = Column(Text, nullable=True)
    
    # Status and metadata
    status = Column(String(20), default="assigned")  # assigned, confirmed, swapped, cancelled
    notes = Column(Text, nullable=True)
    
    # Breaks
    break_times = Column(JSON, nullable=True)  # Break schedule
    
    # Audit
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    schedule = relationship("Schedule", back_populates="shifts")
    shift = relationship("Shift", back_populates="schedule_shifts")
    employee = relationship("Employee")
    
    __table_args__ = (
        Index('idx_schedule_shift_schedule', 'schedule_id'),
        Index('idx_schedule_shift_employee', 'employee_id'),
        Index('idx_schedule_shift_date', 'date'),
        Index('idx_schedule_shift_composite', 'schedule_id', 'employee_id', 'date'),
    )


class ScheduleVariant(Base):
    """Schedule variants for what-if scenarios"""
    __tablename__ = "schedule_variants"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    
    # Variant data
    variant_data = Column(JSON, nullable=False)  # Complete variant configuration
    changes_summary = Column(JSON, nullable=True)  # Summary of changes from base
    
    # Metrics
    cost_impact = Column(Numeric(10, 2), nullable=True)
    coverage_impact = Column(Numeric(5, 2), nullable=True)
    employee_satisfaction = Column(Numeric(5, 2), nullable=True)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_approved = Column(Boolean, default=False)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime, nullable=True)
    
    # Relationships
    schedule = relationship("Schedule", back_populates="variants")
    
    __table_args__ = (
        Index('idx_schedule_variant_schedule', 'schedule_id'),
        Index('idx_schedule_variant_active', 'is_active'),
    )


class ScheduleRule(Base):
    """Business rules for schedule validation"""
    __tablename__ = "schedule_rules"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    
    # Rule definition
    rule_type = Column(String(50), nullable=False)  # coverage, overtime, consecutive, skills
    rule_category = Column(String(50), nullable=False)  # mandatory, preferred, penalty
    rule_config = Column(JSON, nullable=False)  # Rule parameters
    
    # Penalty and priority
    violation_penalty = Column(Numeric(8, 2), default=0)
    priority = Column(Integer, default=1)
    
    # Scope
    applies_to = Column(String(50), default="all")  # all, department, role, employee
    scope_ids = Column(ARRAY(String), nullable=True)  # Specific IDs if applicable
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Status and timing
    is_active = Column(Boolean, default=True)
    effective_date = Column(Date, nullable=False)
    expiry_date = Column(Date, nullable=True)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_schedule_rule_organization', 'organization_id'),
        Index('idx_schedule_rule_type', 'rule_type'),
        Index('idx_schedule_rule_active', 'is_active'),
    )


class ScheduleConflict(Base):
    """Schedule conflicts and violations"""
    __tablename__ = "schedule_conflicts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    
    # Conflict details
    conflict_type = Column(String(50), nullable=False)  # overlap, coverage, rule, constraint
    severity = Column(String(20), nullable=False)  # critical, major, minor, warning
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    
    # Affected entities
    affected_employees = Column(ARRAY(String), nullable=True)
    affected_shifts = Column(JSON, nullable=True)
    affected_dates = Column(ARRAY(Date), nullable=True)
    
    # Resolution
    status = Column(String(20), default="open")  # open, acknowledged, resolved, ignored
    resolution_notes = Column(Text, nullable=True)
    suggested_resolution = Column(JSON, nullable=True)
    
    # Audit
    detected_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    resolved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    
    # Relationships
    schedule = relationship("Schedule", back_populates="conflicts")
    
    __table_args__ = (
        Index('idx_schedule_conflict_schedule', 'schedule_id'),
        Index('idx_schedule_conflict_severity', 'severity'),
        Index('idx_schedule_conflict_status', 'status'),
        Index('idx_schedule_conflict_type', 'conflict_type'),
    )


class ScheduleConstraint(Base):
    """Employee scheduling constraints and preferences"""
    __tablename__ = "schedule_constraints"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False)
    
    # Constraint details
    constraint_type = Column(String(50), nullable=False)  # availability, preference, restriction
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Constraint configuration
    constraint_data = Column(JSON, nullable=False)  # Detailed constraint parameters
    
    # Priority and enforcement
    priority = Column(Integer, default=1)  # 1=highest, 5=lowest
    is_hard_constraint = Column(Boolean, default=False)  # Cannot be violated
    
    # Validity period
    valid_from = Column(Date, nullable=False)
    valid_to = Column(Date, nullable=True)
    
    # Days and times
    days_of_week = Column(ARRAY(Integer), nullable=True)  # 0=Sunday, 6=Saturday
    time_ranges = Column(JSON, nullable=True)  # Time range specifications
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime, nullable=True)
    
    # Relationships
    employee = relationship("Employee")
    
    __table_args__ = (
        Index('idx_schedule_constraint_employee', 'employee_id'),
        Index('idx_schedule_constraint_type', 'constraint_type'),
        Index('idx_schedule_constraint_active', 'is_active'),
        Index('idx_schedule_constraint_dates', 'valid_from', 'valid_to'),
    )


class ScheduleOptimization(Base):
    """Schedule optimization results and history"""
    __tablename__ = "schedule_optimizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    
    # Optimization configuration
    optimization_type = Column(String(50), nullable=False)  # coverage, cost, satisfaction
    algorithm_used = Column(String(100), nullable=False)
    parameters = Column(JSON, nullable=False)
    
    # Results
    input_data = Column(JSON, nullable=False)
    output_data = Column(JSON, nullable=False)
    objective_scores = Column(JSON, nullable=False)
    
    # Performance metrics
    execution_time_ms = Column(Integer, nullable=True)
    iterations = Column(Integer, nullable=True)
    improvement_percentage = Column(Numeric(5, 2), nullable=True)
    
    # Status
    status = Column(String(20), default="completed")  # running, completed, failed
    error_message = Column(Text, nullable=True)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    
    # Relationships
    schedule = relationship("Schedule")
    
    __table_args__ = (
        Index('idx_schedule_optimization_schedule', 'schedule_id'),
        Index('idx_schedule_optimization_type', 'optimization_type'),
        Index('idx_schedule_optimization_status', 'status'),
    )


class SchedulePublication(Base):
    """Schedule publication tracking"""
    __tablename__ = "schedule_publications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    
    # Publication details
    publication_type = Column(String(50), nullable=False)  # full, partial, update
    target_audience = Column(JSON, nullable=False)  # Who receives this publication
    channels = Column(ARRAY(String), nullable=False)  # email, app, sms, etc.
    
    # Content
    publication_data = Column(JSON, nullable=False)
    template_used = Column(String(100), nullable=True)
    
    # Status and timing
    status = Column(String(20), default="draft")  # draft, scheduled, published, delivered
    scheduled_at = Column(DateTime, nullable=True)
    published_at = Column(DateTime, nullable=True)
    
    # Delivery tracking
    delivery_stats = Column(JSON, nullable=True)
    read_receipts = Column(JSON, nullable=True)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    schedule = relationship("Schedule")
    
    __table_args__ = (
        Index('idx_schedule_publication_schedule', 'schedule_id'),
        Index('idx_schedule_publication_status', 'status'),
        Index('idx_schedule_publication_published', 'published_at'),
    )


class ScheduleChangeLog(Base):
    """Schedule change tracking"""
    __tablename__ = "schedule_change_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id"), nullable=False)
    
    # Change details
    change_type = Column(String(50), nullable=False)  # create, update, delete, publish
    entity_type = Column(String(50), nullable=False)  # schedule, shift, constraint
    entity_id = Column(String(100), nullable=True)
    
    # Change data
    old_values = Column(JSON, nullable=True)
    new_values = Column(JSON, nullable=True)
    change_summary = Column(Text, nullable=True)
    
    # Impact
    affected_employees = Column(ARRAY(String), nullable=True)
    impact_level = Column(String(20), default="low")  # low, medium, high, critical
    
    # Audit
    changed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    changed_at = Column(DateTime, default=datetime.utcnow)
    reason = Column(Text, nullable=True)
    
    # Relationships
    schedule = relationship("Schedule")
    
    __table_args__ = (
        Index('idx_schedule_change_schedule', 'schedule_id'),
        Index('idx_schedule_change_type', 'change_type'),
        Index('idx_schedule_change_date', 'changed_at'),
    )


class ScheduleReport(Base):
    """Schedule analytics and reporting"""
    __tablename__ = "schedule_reports"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Report details
    name = Column(String(255), nullable=False)
    report_type = Column(String(50), nullable=False)  # coverage, compliance, cost
    category = Column(String(50), nullable=False)  # operational, analytical, executive
    
    # Parameters and data
    parameters = Column(JSON, nullable=False)
    report_data = Column(JSON, nullable=False)
    
    # Format and file
    format = Column(String(20), nullable=False)  # json, csv, pdf, excel
    file_path = Column(String(500), nullable=True)
    file_size = Column(Integer, nullable=True)
    
    # Period
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    
    # Status
    status = Column(String(20), default="completed")  # generating, completed, failed
    
    # Access control
    access_permissions = Column(JSON, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Audit
    generated_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    generated_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_schedule_report_organization', 'organization_id'),
        Index('idx_schedule_report_type', 'report_type'),
        Index('idx_schedule_report_period', 'period_start', 'period_end'),
    )