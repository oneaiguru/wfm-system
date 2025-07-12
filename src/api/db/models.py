from sqlalchemy import Column, String, Integer, DateTime, Boolean, ForeignKey, Table, Text, JSON, Index, func, Float, Date, Time
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from datetime import datetime
import uuid

from ..core.database import Base


# Many-to-many relationship table for Agent-Group assignments
agent_group_table = Table(
    'agent_groups',
    Base.metadata,
    Column('agent_id', String, ForeignKey('agents.id'), primary_key=True),
    Column('group_id', String, ForeignKey('groups.id'), primary_key=True),
    Column('created_at', DateTime, default=datetime.utcnow),
    Index('idx_agent_group_agent', 'agent_id'),
    Index('idx_agent_group_group', 'group_id')
)


class Service(Base):
    __tablename__ = 'services'
    
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    status = Column(String, default='ACTIVE')  # ACTIVE, INACTIVE
    is_static = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    groups = relationship("Group", back_populates="service", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_service_status', 'status'),
        Index('idx_service_name', 'name'),
    )


class Group(Base):
    __tablename__ = 'groups'
    
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    service_id = Column(String, ForeignKey('services.id'), nullable=False)
    status = Column(String, default='ACTIVE')  # ACTIVE, INACTIVE
    channel_type = Column(String, nullable=True)  # CHATS,MAILS,INCOMING_CALLS,OUTGOING_CALLS
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    service = relationship("Service", back_populates="groups")
    agents = relationship("Agent", secondary=agent_group_table, back_populates="groups")
    
    __table_args__ = (
        Index('idx_group_service', 'service_id'),
        Index('idx_group_status', 'status'),
        Index('idx_group_name', 'name'),
    )


class Agent(Base):
    __tablename__ = 'agents'
    
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    surname = Column(String, nullable=True)
    second_name = Column(String, nullable=True)
    agent_number = Column(String, nullable=True)
    login_sso = Column(String, nullable=True)
    email = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    groups = relationship("Group", secondary=agent_group_table, back_populates="agents")
    
    __table_args__ = (
        Index('idx_agent_name', 'name'),
        Index('idx_agent_number', 'agent_number'),
        Index('idx_agent_login_sso', 'login_sso'),
        Index('idx_agent_email', 'email'),
    )


# Historical Data Models (Time-Series)
class ServiceGroupMetrics(Base):
    __tablename__ = 'service_group_metrics'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_id = Column(String, ForeignKey('services.id'), nullable=False)
    group_id = Column(String, ForeignKey('groups.id'), nullable=False)
    start_interval = Column(DateTime, nullable=False)
    end_interval = Column(DateTime, nullable=False)
    
    # Contact metrics
    not_unique_received = Column(Integer, default=0)
    not_unique_treated = Column(Integer, default=0)
    not_unique_missed = Column(Integer, default=0)
    received_calls = Column(Integer, default=0)
    treated_calls = Column(Integer, default=0)
    miss_calls = Column(Integer, default=0)
    
    # Performance metrics (in milliseconds)
    aht = Column(Integer, default=0)
    post_processing = Column(Integer, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_sgm_service_group', 'service_id', 'group_id'),
        Index('idx_sgm_interval', 'start_interval', 'end_interval'),
        Index('idx_sgm_time_range', 'start_interval'),
        # Partitioning would be configured at database level
    )


class AgentStatusHistory(Base):
    __tablename__ = 'agent_status_history'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    agent_id = Column(String, ForeignKey('agents.id'), nullable=False)
    service_id = Column(String, ForeignKey('services.id'), nullable=True)
    group_id = Column(String, ForeignKey('groups.id'), nullable=True)
    
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    state_code = Column(String, nullable=False)
    state_name = Column(String, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_ash_agent', 'agent_id'),
        Index('idx_ash_dates', 'start_date', 'end_date'),
        Index('idx_ash_state', 'state_code'),
        Index('idx_ash_agent_time', 'agent_id', 'start_date'),
    )


class AgentLoginHistory(Base):
    __tablename__ = 'agent_login_history'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    agent_id = Column(String, ForeignKey('agents.id'), nullable=False)
    
    login_date = Column(DateTime, nullable=False)
    logout_date = Column(DateTime, nullable=False)
    duration = Column(Integer, nullable=False)  # milliseconds
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_alh_agent', 'agent_id'),
        Index('idx_alh_login_date', 'login_date'),
        Index('idx_alh_agent_date', 'agent_id', 'login_date'),
    )


class AgentCallsData(Base):
    __tablename__ = 'agent_calls_data'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    agent_id = Column(String, ForeignKey('agents.id'), nullable=False)
    service_id = Column(String, ForeignKey('services.id'), nullable=False)
    group_id = Column(String, ForeignKey('groups.id'), nullable=False)
    
    start_call = Column(DateTime, nullable=False)
    end_call = Column(DateTime, nullable=False)
    duration = Column(Integer, nullable=False)  # milliseconds
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_acd_agent', 'agent_id'),
        Index('idx_acd_start_call', 'start_call'),
        Index('idx_acd_agent_date', 'agent_id', 'start_call'),
        Index('idx_acd_service_group', 'service_id', 'group_id'),
    )


class AgentChatsWorkTime(Base):
    __tablename__ = 'agent_chats_work_time'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    agent_id = Column(String, ForeignKey('agents.id'), nullable=False)
    work_date = Column(DateTime, nullable=False)  # Date only
    work_time = Column(Integer, nullable=False)  # milliseconds with at least 1 chat
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_acwt_agent', 'agent_id'),
        Index('idx_acwt_work_date', 'work_date'),
        Index('idx_acwt_agent_date', 'agent_id', 'work_date'),
    )


# Real-Time Models
class AgentCurrentStatus(Base):
    __tablename__ = 'agent_current_status'
    
    agent_id = Column(String, ForeignKey('agents.id'), primary_key=True)
    state_code = Column(String, nullable=False)
    state_name = Column(String, nullable=False)
    start_date = Column(DateTime, nullable=False)
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_acs_state', 'state_code'),
        Index('idx_acs_start_date', 'start_date'),
    )


class GroupOnlineMetrics(Base):
    __tablename__ = 'group_online_metrics'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_id = Column(String, ForeignKey('services.id'), nullable=False)
    group_id = Column(String, ForeignKey('groups.id'), nullable=False)
    
    # Real-time metrics
    call_number = Column(Integer, default=0)  # Contacts in queue now
    operator_number = Column(Integer, default=0)  # Available operators
    awt = Column(Integer, default=0)  # Average wait time (ms)
    call_processing = Column(Integer, default=0)  # Calls being processed now
    
    # Daily metrics (reset at midnight)
    call_received = Column(Integer, default=0)  # Contacts received today
    call_answered = Column(Integer, default=0)  # Calls answered today
    call_answered_tst = Column(Integer, default=0)  # Calls answered within 80/20 format
    aht = Column(Integer, default=0)  # Average handle time today (ms)
    acd = Column(Integer, default=0)  # Percentage answered today
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_gom_service_group', 'service_id', 'group_id'),
        Index('idx_gom_updated', 'updated_at'),
    )


# Forecasting and Planning Models
class Forecast(Base):
    __tablename__ = "forecasts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Forecast metadata
    forecast_type = Column(String(50), nullable=False)  # call_volume, aht, shrinkage
    method = Column(String(50), nullable=False)  # manual, ml, hybrid
    granularity = Column(String(20), nullable=False)  # 15min, 30min, 1hour, 1day
    
    # Time range
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    
    # Organizational context
    department_id = Column(UUID(as_uuid=True), nullable=True)
    service_id = Column(String, ForeignKey("services.id"), nullable=True)
    organization_id = Column(UUID(as_uuid=True), nullable=True)
    
    # Forecast data
    data = Column(JSON)  # Time series data
    metadata = Column(JSON)  # Model parameters, accuracy metrics, etc.
    
    # Status
    status = Column(String(20), default="draft")  # draft, active, archived
    version = Column(Integer, default=1)
    
    # Accuracy tracking
    accuracy_metrics = Column(JSON)
    last_validation = Column(DateTime)
    
    # Relationships
    data_points = relationship("ForecastDataPoint", back_populates="forecast", cascade="all, delete-orphan")
    scenarios = relationship("ForecastScenario", back_populates="forecast", cascade="all, delete-orphan")
    staffing_plans = relationship("StaffingPlan", back_populates="forecast")
    
    # Audit
    created_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_forecast_service', 'service_id'),
        Index('idx_forecast_type', 'forecast_type'),
        Index('idx_forecast_status', 'status'),
        Index('idx_forecast_date_range', 'start_date', 'end_date'),
        Index('idx_forecast_organization', 'organization_id'),
    )


class ForecastDataPoint(Base):
    __tablename__ = "forecast_data_points"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    forecast_id = Column(UUID(as_uuid=True), ForeignKey("forecasts.id"), nullable=False)
    
    # Time dimension
    timestamp = Column(DateTime, nullable=False)
    date = Column(Date, nullable=False)
    time_of_day = Column(Time, nullable=False)
    day_of_week = Column(Integer, nullable=False)
    week_of_year = Column(Integer, nullable=False)
    month = Column(Integer, nullable=False)
    quarter = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    
    # Forecast values
    predicted_value = Column(Float, nullable=False)
    actual_value = Column(Float, nullable=True)
    confidence_interval_lower = Column(Float, nullable=True)
    confidence_interval_upper = Column(Float, nullable=True)
    
    # Seasonality factors
    seasonal_factor = Column(Float, default=1.0)
    trend_factor = Column(Float, default=1.0)
    holiday_factor = Column(Float, default=1.0)
    
    # Relationships
    forecast = relationship("Forecast", back_populates="data_points")
    
    # Index for time series queries
    __table_args__ = (
        Index('idx_forecast_timestamp', 'forecast_id', 'timestamp'),
        Index('idx_forecast_date', 'forecast_id', 'date'),
        Index('idx_forecast_time_components', 'forecast_id', 'day_of_week', 'month'),
    )


class ForecastModel(Base):
    __tablename__ = "forecast_models"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Model metadata
    model_type = Column(String(50), nullable=False)  # arima, lstm, prophet, ensemble
    algorithm = Column(String(50), nullable=False)
    version = Column(String(20), nullable=False)
    
    # Model parameters
    parameters = Column(JSON)
    hyperparameters = Column(JSON)
    
    # Performance metrics
    accuracy_metrics = Column(JSON)
    validation_results = Column(JSON)
    
    # Model artifacts
    model_path = Column(String(500))  # Path to saved model
    model_size_mb = Column(Float)
    
    # Training data
    training_data_start = Column(DateTime)
    training_data_end = Column(DateTime)
    training_samples = Column(Integer)
    
    # Status
    status = Column(String(20), default="training")  # training, active, deprecated
    is_default = Column(Boolean, default=False)
    
    # Audit
    created_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    trained_at = Column(DateTime)
    last_used = Column(DateTime)
    
    __table_args__ = (
        Index('idx_model_type', 'model_type'),
        Index('idx_model_status', 'status'),
        Index('idx_model_default', 'is_default'),
    )


class StaffingPlan(Base):
    __tablename__ = "staffing_plans"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Plan metadata
    forecast_id = Column(UUID(as_uuid=True), ForeignKey("forecasts.id"), nullable=False)
    department_id = Column(UUID(as_uuid=True), nullable=True)
    
    # Planning parameters
    service_level_target = Column(Float, nullable=False)  # e.g., 0.80 for 80%
    max_wait_time = Column(Integer, nullable=False)  # seconds
    shrinkage_factor = Column(Float, default=0.30)  # 30% default
    
    # Calculation results
    staffing_data = Column(JSON)  # Time series staffing requirements
    total_fte = Column(Float)
    peak_staff = Column(Integer)
    
    # Cost estimates
    estimated_cost = Column(Float)
    cost_breakdown = Column(JSON)
    
    # Status
    status = Column(String(20), default="draft")
    approved_by = Column(UUID(as_uuid=True), nullable=True)
    approved_at = Column(DateTime)
    
    # Relationships
    forecast = relationship("Forecast", back_populates="staffing_plans")
    requirements = relationship("StaffingRequirement", back_populates="plan", cascade="all, delete-orphan")
    
    # Audit
    created_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_staffing_forecast', 'forecast_id'),
        Index('idx_staffing_department', 'department_id'),
        Index('idx_staffing_status', 'status'),
    )


class StaffingRequirement(Base):
    __tablename__ = "staffing_requirements"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staffing_plan_id = Column(UUID(as_uuid=True), ForeignKey("staffing_plans.id"), nullable=False)
    
    # Time dimension
    timestamp = Column(DateTime, nullable=False)
    
    # Staffing requirements
    required_staff = Column(Integer, nullable=False)
    skill_requirements = Column(JSON)  # Skills needed
    
    # Calculations
    call_volume = Column(Integer)
    average_handle_time = Column(Integer)  # seconds
    service_level = Column(Float)
    occupancy = Column(Float)
    
    # Relationships
    plan = relationship("StaffingPlan", back_populates="requirements")
    
    __table_args__ = (
        Index('idx_staffing_req_plan', 'staffing_plan_id'),
        Index('idx_staffing_req_timestamp', 'timestamp'),
    )


class ForecastScenario(Base):
    __tablename__ = "forecast_scenarios"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    forecast_id = Column(UUID(as_uuid=True), ForeignKey("forecasts.id"), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Scenario parameters
    scenario_type = Column(String(50), nullable=False)  # what_if, sensitivity, stress
    parameters = Column(JSON)
    
    # Results
    results = Column(JSON)
    impact_analysis = Column(JSON)
    
    # Relationships
    forecast = relationship("Forecast", back_populates="scenarios")
    
    # Audit
    created_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_scenario_forecast', 'forecast_id'),
        Index('idx_scenario_type', 'scenario_type'),
    )


class Organization(Base):
    __tablename__ = "organizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(20), unique=True, nullable=False)
    description = Column(Text)
    
    # Configuration
    settings = Column(JSON)
    
    # Status
    status = Column(String(20), default="active")
    
    # Audit
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_organization_code', 'code'),
        Index('idx_organization_status', 'status'),
    )


class Department(Base):
    __tablename__ = "departments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=False)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Configuration
    settings = Column(JSON)
    
    # Status
    status = Column(String(20), default="active")
    
    # Audit
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_department_organization', 'organization_id'),
        Index('idx_department_code', 'code'),
    )


class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(100), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    
    # Authentication
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    
    # Organization context
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=True)
    
    # Audit
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime)
    
    __table_args__ = (
        Index('idx_user_username', 'username'),
        Index('idx_user_email', 'email'),
        Index('idx_user_organization', 'organization_id'),
    )


# ============================================================================
# INTEGRATION MODELS
# ============================================================================

class IntegrationConnection(Base):
    __tablename__ = "integration_connections"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    integration_type = Column(String(50), nullable=False)  # 1c, contact_center, ldap
    
    # Connection details
    endpoint_url = Column(String(1000), nullable=False)
    authentication_type = Column(String(50), nullable=False)  # basic, oauth, api_key
    credentials = Column(JSON)  # Encrypted credentials
    
    # Configuration
    config = Column(JSON)  # Integration-specific settings
    mapping_rules = Column(JSON)  # Field mappings
    
    # Status
    status = Column(String(20), default="inactive")  # active, inactive, error
    last_sync = Column(DateTime)
    last_error = Column(Text)
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True))
    
    # Relationships
    sync_logs = relationship("IntegrationSyncLog", back_populates="connection")
    
    # Audit
    created_by = Column(UUID(as_uuid=True))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_ic_type', 'integration_type'),
        Index('idx_ic_status', 'status'),
        Index('idx_ic_organization', 'organization_id'),
    )


class IntegrationSyncLog(Base):
    __tablename__ = "integration_sync_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    connection_id = Column(UUID(as_uuid=True), ForeignKey("integration_connections.id"), nullable=False)
    
    # Sync details
    sync_type = Column(String(50), nullable=False)  # full, incremental, real_time
    direction = Column(String(20), nullable=False)  # inbound, outbound, bidirectional
    
    # Status
    status = Column(String(20), nullable=False)  # started, completed, failed
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime)
    
    # Metrics
    records_processed = Column(Integer, default=0)
    records_successful = Column(Integer, default=0)
    records_failed = Column(Integer, default=0)
    
    # Data
    sync_data = Column(JSON)  # Sync parameters
    error_details = Column(JSON)  # Error information
    
    # Relationships
    connection = relationship("IntegrationConnection", back_populates="sync_logs")
    
    # Audit
    initiated_by = Column(UUID(as_uuid=True))
    
    __table_args__ = (
        Index('idx_isl_connection', 'connection_id'),
        Index('idx_isl_start_time', 'start_time'),
        Index('idx_isl_status', 'status'),
    )


class IntegrationDataMapping(Base):
    __tablename__ = "integration_data_mappings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    connection_id = Column(UUID(as_uuid=True), ForeignKey("integration_connections.id"), nullable=False)
    
    # Mapping details
    source_entity = Column(String(100), nullable=False)  # e.g., "employee", "schedule"
    target_entity = Column(String(100), nullable=False)
    
    # Field mappings
    field_mappings = Column(JSON)  # source_field -> target_field
    transformation_rules = Column(JSON)  # Data transformation rules
    
    # Validation
    validation_rules = Column(JSON)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    connection = relationship("IntegrationConnection")
    
    __table_args__ = (
        Index('idx_idm_connection', 'connection_id'),
        Index('idx_idm_source_entity', 'source_entity'),
        Index('idx_idm_target_entity', 'target_entity'),
    )


class ContactCenterData(Base):
    __tablename__ = "contact_center_data"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Data type
    data_type = Column(String(50), nullable=False)  # agent_status, queue_metrics, etc.
    
    # Time dimensions
    timestamp = Column(DateTime, nullable=False)
    date = Column(Date, nullable=False)
    interval_start = Column(DateTime, nullable=False)
    interval_end = Column(DateTime, nullable=False)
    
    # Agent/Queue identification
    agent_id = Column(String(100))
    queue_id = Column(String(100))
    service_group = Column(String(100))
    
    # Metrics data
    metrics = Column(JSON)  # All metrics for this interval
    
    # Metadata
    source_system = Column(String(50), default="argus")
    raw_data = Column(JSON)  # Original data for debugging
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_cc_timestamp', 'timestamp'),
        Index('idx_cc_agent_date', 'agent_id', 'date'),
        Index('idx_cc_queue_date', 'queue_id', 'date'),
        Index('idx_cc_data_type', 'data_type', 'date'),
    )


class OneCIntegrationData(Base):
    __tablename__ = "onec_integration_data"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Data type
    data_type = Column(String(50), nullable=False)  # personnel, schedule, timesheet
    
    # 1C specific identifiers
    onec_id = Column(String(100), nullable=False)
    onec_type = Column(String(50), nullable=False)
    
    # WFM mapping
    wfm_entity_id = Column(UUID(as_uuid=True))
    wfm_entity_type = Column(String(50))
    
    # Data
    onec_data = Column(JSON)  # Original 1C data
    mapped_data = Column(JSON)  # Mapped to WFM format
    
    # Sync status
    sync_status = Column(String(20), default="pending")  # pending, synced, error
    sync_error = Column(Text)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    synced_at = Column(DateTime)
    
    __table_args__ = (
        Index('idx_oid_data_type', 'data_type'),
        Index('idx_oid_onec_id', 'onec_id'),
        Index('idx_oid_sync_status', 'sync_status'),
        Index('idx_oid_entity', 'wfm_entity_id', 'wfm_entity_type'),
    )


class WebhookEndpoint(Base):
    __tablename__ = "webhook_endpoints"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    
    # Webhook configuration
    url = Column(String(1000), nullable=False)
    method = Column(String(10), default="POST")
    headers = Column(JSON)  # Custom headers
    
    # Event subscription
    event_types = Column(JSON)  # List of event types to subscribe to
    
    # Security
    secret = Column(String(255))  # For signature verification
    auth_type = Column(String(50))  # none, basic, bearer
    auth_credentials = Column(JSON)  # Encrypted auth data
    
    # Configuration
    timeout_seconds = Column(Integer, default=30)
    retry_attempts = Column(Integer, default=3)
    retry_delay_seconds = Column(Integer, default=60)
    
    # Status
    is_active = Column(Boolean, default=True)
    last_triggered = Column(DateTime)
    success_count = Column(Integer, default=0)
    failure_count = Column(Integer, default=0)
    
    # Organizational context
    organization_id = Column(UUID(as_uuid=True))
    
    # Audit
    created_by = Column(UUID(as_uuid=True))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_we_organization', 'organization_id'),
        Index('idx_we_active', 'is_active'),
    )


class WebhookDelivery(Base):
    __tablename__ = "webhook_deliveries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    webhook_id = Column(UUID(as_uuid=True), ForeignKey("webhook_endpoints.id"), nullable=False)
    
    # Event details
    event_type = Column(String(100), nullable=False)
    event_data = Column(JSON)
    
    # Delivery details
    delivery_status = Column(String(20), nullable=False)  # pending, delivered, failed
    http_status = Column(Integer)
    response_body = Column(Text)
    error_message = Column(Text)
    
    # Timing
    created_at = Column(DateTime, default=datetime.utcnow)
    delivered_at = Column(DateTime)
    retry_count = Column(Integer, default=0)
    next_retry_at = Column(DateTime)
    
    # Relationships
    webhook = relationship("WebhookEndpoint")
    
    __table_args__ = (
        Index('idx_wd_webhook', 'webhook_id'),
        Index('idx_wd_status', 'delivery_status'),
        Index('idx_wd_created', 'created_at'),
        Index('idx_wd_retry', 'next_retry_at'),
    )