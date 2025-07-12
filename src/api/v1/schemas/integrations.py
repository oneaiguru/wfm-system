"""
Integration API Schemas

This module contains Pydantic models for integration API endpoints:
- 1C ZUP Integration schemas
- Contact Center Integration schemas
- Webhook management schemas
- Integration connection schemas

All schemas support proper validation and serialization for the 25 integration endpoints.
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any, List, Union
from datetime import datetime, date, time
from uuid import UUID
from enum import Enum


# ============================================================================
# BASE INTEGRATION SCHEMAS
# ============================================================================

class IntegrationTypeEnum(str, Enum):
    ONEC = "1c"
    CONTACT_CENTER = "contact_center"
    LDAP = "ldap"
    WEBHOOK = "webhook"


class AuthTypeEnum(str, Enum):
    BASIC = "basic"
    OAUTH = "oauth"
    API_KEY = "api_key"
    BEARER = "bearer"
    NONE = "none"


class SyncTypeEnum(str, Enum):
    FULL = "full"
    INCREMENTAL = "incremental"
    REAL_TIME = "real_time"


class SyncStatusEnum(str, Enum):
    STARTED = "started"
    COMPLETED = "completed"
    FAILED = "failed"
    PENDING = "pending"


class ConnectionStatusEnum(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    ERROR = "error"


# ============================================================================
# INTEGRATION CONNECTION SCHEMAS
# ============================================================================

class IntegrationConnectionBase(BaseModel):
    name: str = Field(..., description="Human-readable name for the connection")
    integration_type: IntegrationTypeEnum = Field(..., description="Type of integration")
    endpoint_url: str = Field(..., description="URL endpoint for the integration")
    authentication_type: AuthTypeEnum = Field(..., description="Authentication method")
    config: Optional[Dict[str, Any]] = Field(None, description="Integration-specific configuration")
    mapping_rules: Optional[Dict[str, Any]] = Field(None, description="Field mapping rules")


class IntegrationConnectionCreate(IntegrationConnectionBase):
    credentials: Dict[str, Any] = Field(..., description="Authentication credentials")


class IntegrationConnectionUpdate(BaseModel):
    name: Optional[str] = None
    endpoint_url: Optional[str] = None
    credentials: Optional[Dict[str, Any]] = None
    config: Optional[Dict[str, Any]] = None
    mapping_rules: Optional[Dict[str, Any]] = None
    status: Optional[ConnectionStatusEnum] = None


class IntegrationConnectionResponse(IntegrationConnectionBase):
    id: UUID
    status: ConnectionStatusEnum
    last_sync: Optional[datetime] = None
    last_error: Optional[str] = None
    organization_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


# ============================================================================
# 1C ZUP INTEGRATION SCHEMAS
# ============================================================================

class OneCPersonnelSync(BaseModel):
    start_date: date = Field(..., description="Start date for personnel sync")
    end_date: date = Field(..., description="End date for personnel sync")
    full_sync: bool = Field(False, description="Whether to perform full sync")
    departments: Optional[List[str]] = Field(None, description="Specific departments to sync")
    
    @validator('end_date')
    def validate_date_range(cls, v, values):
        if 'start_date' in values and v < values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class OneCScheduleData(BaseModel):
    schedule_id: UUID = Field(..., description="WFM Schedule ID")
    start_date: date = Field(..., description="Schedule start date")
    end_date: date = Field(..., description="Schedule end date")
    employees: List[Dict[str, Any]] = Field(..., description="Employee schedule data")
    shifts: List[Dict[str, Any]] = Field(..., description="Shift definitions")
    
    @validator('employees')
    def validate_employees(cls, v):
        if not v:
            raise ValueError('employees list cannot be empty')
        return v


class OneCTimeData(BaseModel):
    employee_id: str = Field(..., description="Employee identifier")
    date: date = Field(..., description="Work date")
    start_time: time = Field(..., description="Work start time")
    end_time: time = Field(..., description="Work end time")
    hours_worked: float = Field(..., ge=0, le=24, description="Hours worked")
    overtime_hours: float = Field(0.0, ge=0, description="Overtime hours")
    break_time: float = Field(0.0, ge=0, description="Break time in hours")
    time_type: str = Field("regular", description="Time type (regular, overtime, etc.)")
    
    @validator('end_time')
    def validate_time_range(cls, v, values):
        if 'start_time' in values and v <= values['start_time']:
            raise ValueError('end_time must be after start_time')
        return v


class OneCNormHoursRequest(BaseModel):
    employee_id: str = Field(..., description="Employee identifier")
    start_date: date = Field(..., description="Period start date")
    end_date: date = Field(..., description="Period end date")
    calculation_type: str = Field("standard", description="Calculation type")


class OneCTimetypeInfoRequest(BaseModel):
    employee_id: str = Field(..., description="Employee identifier")
    date: date = Field(..., description="Query date")
    time_type_codes: Optional[List[str]] = Field(None, description="Specific time type codes")


class OneCAgentData(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    tab_number: str = Field(..., description="Employee tab number")
    first_name: str = Field(..., description="First name")
    last_name: str = Field(..., description="Last name")
    middle_name: Optional[str] = Field(None, description="Middle name")
    department: Optional[str] = Field(None, description="Department")
    position: Optional[str] = Field(None, description="Position")
    hire_date: Optional[date] = Field(None, description="Hire date")
    status: str = Field("active", description="Employee status")
    skills: Optional[List[str]] = Field(None, description="Employee skills")


class OneCDeviationData(BaseModel):
    employee_id: str = Field(..., description="Employee identifier")
    date: date = Field(..., description="Deviation date")
    planned_hours: float = Field(..., description="Planned work hours")
    actual_hours: float = Field(..., description="Actual work hours")
    deviation_hours: float = Field(..., description="Deviation in hours")
    deviation_type: str = Field(..., description="Type of deviation")
    reason: Optional[str] = Field(None, description="Reason for deviation")


# ============================================================================
# CONTACT CENTER INTEGRATION SCHEMAS
# ============================================================================

class ContactCenterHistoricRequest(BaseModel):
    start_date: datetime = Field(..., description="Start datetime for historic data")
    end_date: datetime = Field(..., description="End datetime for historic data")
    interval_minutes: int = Field(30, ge=1, le=1440, description="Interval in minutes")
    service_groups: Optional[List[str]] = Field(None, description="Filter by service groups")
    agents: Optional[List[str]] = Field(None, description="Filter by agent IDs")
    data_types: Optional[List[str]] = Field(None, description="Types of data to retrieve")
    
    @validator('end_date')
    def validate_datetime_range(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class ContactCenterRealtimeData(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    status: str = Field(..., description="Current agent status")
    queue_id: Optional[str] = Field(None, description="Queue identifier")
    service_group: Optional[str] = Field(None, description="Service group")
    start_time: datetime = Field(..., description="Status start time")
    duration_seconds: Optional[int] = Field(None, ge=0, description="Duration in seconds")
    calls_handled: Optional[int] = Field(None, ge=0, description="Number of calls handled")
    additional_data: Optional[Dict[str, Any]] = Field(None, description="Additional metrics")


class ContactCenterBulkImport(BaseModel):
    data_type: str = Field(..., description="Type of data being imported")
    data: List[Dict[str, Any]] = Field(..., description="Data records to import")
    validate_before_import: bool = Field(True, description="Validate data before import")
    update_existing: bool = Field(False, description="Update existing records")
    batch_size: int = Field(1000, ge=1, le=10000, description="Batch processing size")
    
    @validator('data')
    def validate_data_not_empty(cls, v):
        if not v:
            raise ValueError('data list cannot be empty')
        return v


class ContactCenterExportRequest(BaseModel):
    data_type: str = Field(..., description="Type of data to export")
    start_date: datetime = Field(..., description="Export start date")
    end_date: datetime = Field(..., description="Export end date")
    format: str = Field("json", description="Export format")
    filters: Optional[Dict[str, Any]] = Field(None, description="Additional filters")
    include_raw_data: bool = Field(False, description="Include raw data in export")


class ContactCenterValidationRequest(BaseModel):
    data_type: str = Field(..., description="Type of data to validate")
    data: List[Dict[str, Any]] = Field(..., description="Data to validate")
    validation_rules: Optional[Dict[str, Any]] = Field(None, description="Custom validation rules")
    strict_mode: bool = Field(False, description="Strict validation mode")


class ContactCenterServiceGroupData(BaseModel):
    service_id: str = Field(..., description="Service identifier")
    group_id: str = Field(..., description="Group identifier")
    interval_start: datetime = Field(..., description="Interval start time")
    interval_end: datetime = Field(..., description="Interval end time")
    metrics: Dict[str, Any] = Field(..., description="Service group metrics")


class ContactCenterAgentStatusData(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    start_date: datetime = Field(..., description="Status start time")
    end_date: datetime = Field(..., description="Status end time")
    state_code: str = Field(..., description="Status code")
    state_name: str = Field(..., description="Status name")
    service_id: Optional[str] = Field(None, description="Service identifier")
    group_id: Optional[str] = Field(None, description="Group identifier")


class ContactCenterAgentLoginData(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    login_date: datetime = Field(..., description="Login timestamp")
    logout_date: datetime = Field(..., description="Logout timestamp")
    duration: int = Field(..., ge=0, description="Session duration in milliseconds")


class ContactCenterAgentCallsData(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    service_id: str = Field(..., description="Service identifier")
    group_id: str = Field(..., description="Group identifier")
    start_call: datetime = Field(..., description="Call start time")
    end_call: datetime = Field(..., description="Call end time")
    duration: int = Field(..., ge=0, description="Call duration in milliseconds")
    call_type: Optional[str] = Field(None, description="Type of call")


class ContactCenterAgentChatsWorkTime(BaseModel):
    agent_id: str = Field(..., description="Agent identifier")
    work_date: date = Field(..., description="Work date")
    work_time: int = Field(..., ge=0, description="Work time in milliseconds")
    chat_sessions: Optional[int] = Field(None, ge=0, description="Number of chat sessions")


# ============================================================================
# WEBHOOK SCHEMAS
# ============================================================================

class WebhookEndpointBase(BaseModel):
    name: str = Field(..., description="Webhook name")
    url: str = Field(..., description="Webhook URL")
    method: str = Field("POST", description="HTTP method")
    headers: Optional[Dict[str, str]] = Field(None, description="Custom headers")
    event_types: List[str] = Field(..., description="Event types to subscribe to")
    secret: Optional[str] = Field(None, description="Webhook secret for verification")
    timeout_seconds: int = Field(30, ge=1, le=300, description="Request timeout")
    retry_attempts: int = Field(3, ge=0, le=10, description="Retry attempts")
    retry_delay_seconds: int = Field(60, ge=1, description="Retry delay in seconds")
    
    @validator('url')
    def validate_url(cls, v):
        if not v.startswith(('http://', 'https://')):
            raise ValueError('URL must start with http:// or https://')
        return v


class WebhookEndpointCreate(WebhookEndpointBase):
    auth_type: AuthTypeEnum = Field(AuthTypeEnum.NONE, description="Authentication type")
    auth_credentials: Optional[Dict[str, Any]] = Field(None, description="Authentication credentials")


class WebhookEndpointUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    method: Optional[str] = None
    headers: Optional[Dict[str, str]] = None
    event_types: Optional[List[str]] = None
    secret: Optional[str] = None
    timeout_seconds: Optional[int] = None
    retry_attempts: Optional[int] = None
    retry_delay_seconds: Optional[int] = None
    is_active: Optional[bool] = None


class WebhookEndpointResponse(WebhookEndpointBase):
    id: UUID
    is_active: bool
    last_triggered: Optional[datetime] = None
    success_count: int
    failure_count: int
    organization_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class WebhookDeliveryResponse(BaseModel):
    id: UUID
    webhook_id: UUID
    event_type: str
    event_data: Dict[str, Any]
    delivery_status: str
    http_status: Optional[int] = None
    response_body: Optional[str] = None
    error_message: Optional[str] = None
    created_at: datetime
    delivered_at: Optional[datetime] = None
    retry_count: int
    next_retry_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True


# ============================================================================
# INTEGRATION SYNC SCHEMAS
# ============================================================================

class IntegrationSyncLogResponse(BaseModel):
    id: UUID
    connection_id: UUID
    sync_type: SyncTypeEnum
    direction: str
    status: SyncStatusEnum
    start_time: datetime
    end_time: Optional[datetime] = None
    records_processed: int
    records_successful: int
    records_failed: int
    error_details: Optional[Dict[str, Any]] = None
    initiated_by: Optional[UUID] = None
    
    class Config:
        orm_mode = True


class IntegrationTestConnection(BaseModel):
    connection_id: UUID = Field(..., description="Connection ID to test")
    test_type: str = Field("basic", description="Type of test to perform")
    test_parameters: Optional[Dict[str, Any]] = Field(None, description="Test-specific parameters")


class IntegrationStatus(BaseModel):
    connection_id: UUID
    status: ConnectionStatusEnum
    last_sync: Optional[datetime] = None
    next_sync: Optional[datetime] = None
    health_check: Dict[str, Any]
    error_count: int
    success_rate: float
    performance_metrics: Optional[Dict[str, Any]] = None


class IntegrationDataMappingResponse(BaseModel):
    id: UUID
    connection_id: UUID
    source_entity: str
    target_entity: str
    field_mappings: Dict[str, Any]
    transformation_rules: Optional[Dict[str, Any]] = None
    validation_rules: Optional[Dict[str, Any]] = None
    is_active: bool
    
    class Config:
        orm_mode = True


# ============================================================================
# RESPONSE SCHEMAS
# ============================================================================

class IntegrationResponse(BaseModel):
    """Generic integration response schema"""
    success: bool = Field(..., description="Operation success status")
    message: str = Field(..., description="Response message")
    data: Optional[Dict[str, Any]] = Field(None, description="Response data")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Response timestamp")
    request_id: Optional[str] = Field(None, description="Request identifier")


class BulkOperationResponse(BaseModel):
    """Response for bulk operations"""
    total_records: int = Field(..., description="Total records processed")
    successful_records: int = Field(..., description="Successfully processed records")
    failed_records: int = Field(..., description="Failed records")
    errors: Optional[List[Dict[str, Any]]] = Field(None, description="Error details")
    processing_time_ms: int = Field(..., description="Processing time in milliseconds")
    batch_id: Optional[str] = Field(None, description="Batch identifier")


class SyncOperationResponse(BaseModel):
    """Response for synchronization operations"""
    sync_id: UUID = Field(..., description="Synchronization operation ID")
    status: SyncStatusEnum = Field(..., description="Sync status")
    started_at: datetime = Field(..., description="Sync start time")
    estimated_completion: Optional[datetime] = Field(None, description="Estimated completion time")
    progress_percentage: Optional[float] = Field(None, ge=0, le=100, description="Progress percentage")
    records_to_process: Optional[int] = Field(None, description="Total records to process")
    records_processed: int = Field(0, description="Records processed so far")


class ConnectionTestResponse(BaseModel):
    """Response for connection tests"""
    connection_id: UUID = Field(..., description="Connection ID")
    test_type: str = Field(..., description="Type of test performed")
    success: bool = Field(..., description="Test success status")
    response_time_ms: int = Field(..., description="Response time in milliseconds")
    test_results: Dict[str, Any] = Field(..., description="Detailed test results")
    recommendations: Optional[List[str]] = Field(None, description="Optimization recommendations")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Test timestamp")


class HealthCheckResponse(BaseModel):
    """Response for health checks"""
    service_name: str = Field(..., description="Service name")
    status: str = Field(..., description="Health status")
    version: str = Field(..., description="Service version")
    uptime_seconds: int = Field(..., description="Uptime in seconds")
    active_connections: int = Field(..., description="Number of active connections")
    last_sync_times: Dict[str, datetime] = Field(..., description="Last sync times by type")
    performance_metrics: Dict[str, float] = Field(..., description="Performance metrics")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Health check timestamp")