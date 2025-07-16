-- =============================================================================
-- 061_advanced_mobile_apis.sql
-- Advanced Mobile APIs Database Schema (Tasks 61-65)
-- Enterprise-grade mobile features with security and compliance
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-14
-- Purpose: Support advanced mobile APIs with push notifications, location tracking,
--         offline sync, device management, and biometric authentication
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================================================
-- TASK 61: PUSH NOTIFICATION SYSTEM
-- =============================================================================

-- Push notification campaigns for targeting and A/B testing
CREATE TABLE IF NOT EXISTS push_notification_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- schedule_reminder, break_reminder, etc.
    priority VARCHAR(20) NOT NULL DEFAULT 'normal', -- low, normal, high, urgent
    
    -- Campaign content
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    action_text VARCHAR(50),
    deep_link VARCHAR(200),
    custom_data JSONB,
    
    -- Targeting
    targeting_criteria JSONB,
    target_count INTEGER DEFAULT 0,
    
    -- A/B Testing
    ab_test_variants JSONB, -- Array of variant definitions
    
    -- Scheduling
    send_immediately BOOLEAN DEFAULT true,
    scheduled_send_time TIMESTAMP WITH TIME ZONE,
    respect_quiet_hours BOOLEAN DEFAULT true,
    
    -- Delivery settings
    require_delivery_confirmation BOOLEAN DEFAULT false,
    max_retry_attempts INTEGER DEFAULT 3,
    frequency_cap INTEGER, -- Max notifications per employee
    
    -- Status and tracking
    status VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, CREATED, QUEUED, SENDING, COMPLETED, FAILED
    created_by_tab_n VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    queued_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Device tokens for push notifications
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    device_id VARCHAR(200) NOT NULL,
    device_type VARCHAR(50) NOT NULL, -- iOS, Android, Web
    push_token TEXT NOT NULL,
    
    -- Token metadata
    token_type VARCHAR(20) DEFAULT 'FCM', -- FCM, APNS, Web Push
    app_version VARCHAR(20),
    os_version VARCHAR(50),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_used TIMESTAMP WITH TIME ZONE,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_device_token UNIQUE(employee_tab_n, device_id)
);

-- Notification delivery queue with detailed tracking
CREATE TABLE IF NOT EXISTS notification_delivery_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID REFERENCES push_notification_campaigns(id),
    employee_tab_n VARCHAR(50) NOT NULL,
    device_id VARCHAR(200) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    
    -- Variant information for A/B testing
    variant_id VARCHAR(50) NOT NULL,
    
    -- Notification content
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    action_text VARCHAR(50),
    deep_link VARCHAR(200),
    push_token TEXT NOT NULL,
    
    -- Delivery settings
    priority VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    custom_data JSONB,
    
    -- Scheduling
    scheduled_delivery_time TIMESTAMP WITH TIME ZONE NOT NULL,
    max_retry_attempts INTEGER DEFAULT 3,
    require_confirmation BOOLEAN DEFAULT false,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'QUEUED', -- QUEUED, PROCESSING, SENT, DELIVERED, FAILED
    delivery_status VARCHAR(20), -- SENT, DELIVERED, FAILED, BOUNCED
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    
    -- Error handling
    retry_count INTEGER DEFAULT 0,
    failure_reason TEXT,
    last_retry_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- TASK 62: LOCATION TRACKING SYSTEM
-- =============================================================================

-- Location tracking preferences per employee
CREATE TABLE IF NOT EXISTS location_tracking_preferences (
    employee_tab_n VARCHAR(50) PRIMARY KEY,
    
    -- Tracking settings
    tracking_mode VARCHAR(20) DEFAULT 'work_hours_only', -- disabled, work_hours_only, always, on_demand
    location_precision VARCHAR(20) DEFAULT 'medium', -- high, medium, low
    privacy_level VARCHAR(20) DEFAULT 'manager_only', -- public, manager_only, admin_only, private
    
    -- Update frequency (minutes)
    update_frequency_working INTEGER DEFAULT 5,
    update_frequency_break INTEGER DEFAULT 15,
    update_frequency_idle INTEGER DEFAULT 30,
    
    -- Battery optimization
    low_battery_mode BOOLEAN DEFAULT true,
    background_tracking BOOLEAN DEFAULT true,
    wifi_only_sync BOOLEAN DEFAULT false,
    
    -- Privacy and retention
    location_history_retention_days INTEGER DEFAULT 90,
    share_location_with_colleagues BOOLEAN DEFAULT false,
    emergency_override_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Location tracking sessions
CREATE TABLE IF NOT EXISTS location_tracking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    
    -- Session details
    session_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Tracking settings for this session
    precision_level VARCHAR(20) NOT NULL,
    started_by_tab_n VARCHAR(50),
    
    -- Statistics
    total_locations_recorded INTEGER DEFAULT 0,
    last_update TIMESTAMP WITH TIME ZONE,
    average_accuracy FLOAT,
    battery_optimization_active BOOLEAN DEFAULT false,
    
    -- Latest position cache
    latest_latitude DECIMAL(10, 8),
    latest_longitude DECIMAL(11, 8),
    latest_accuracy FLOAT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Detailed location history
CREATE TABLE IF NOT EXISTS location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    session_id UUID REFERENCES location_tracking_sessions(id),
    
    -- Location data
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    altitude FLOAT,
    accuracy FLOAT, -- meters
    
    -- Context information
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_working BOOLEAN DEFAULT true,
    current_activity VARCHAR(100),
    
    -- Movement data
    speed_kmh FLOAT,
    heading INTEGER, -- degrees
    
    -- Geofencing status
    geofence_status JSONB, -- Which geofences are active
    inside_geofences TEXT[], -- Array of geofence IDs
    
    -- Device information
    device_info JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Geofences for location-based alerts
CREATE TABLE IF NOT EXISTS geofences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    geofence_type VARCHAR(50) NOT NULL, -- workplace, break_area, customer_site, restricted_area, emergency_zone
    
    -- Geographic definition
    center_lat DECIMAL(10, 8) NOT NULL,
    center_lng DECIMAL(11, 8) NOT NULL,
    radius_meters FLOAT NOT NULL,
    
    -- Alert settings
    entry_alert BOOLEAN DEFAULT true,
    exit_alert BOOLEAN DEFAULT true,
    dwell_time_alert_minutes INTEGER,
    
    -- Schedule constraints
    active_days INTEGER[] DEFAULT ARRAY[0,1,2,3,4,5,6], -- 0=Monday
    active_time_start TIME,
    active_time_end TIME,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_by_tab_n VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Geofence assignments to employees/departments
CREATE TABLE IF NOT EXISTS geofence_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    geofence_id UUID REFERENCES geofences(id),
    
    -- Assignment target (either employee or department)
    employee_tab_n VARCHAR(50),
    department_code VARCHAR(20),
    
    assigned_by_tab_n VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT geofence_assignment_target CHECK (
        (employee_tab_n IS NOT NULL AND department_code IS NULL) OR
        (employee_tab_n IS NULL AND department_code IS NOT NULL)
    )
);

-- Geofence events log
CREATE TABLE IF NOT EXISTS geofence_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    geofence_id UUID REFERENCES geofences(id),
    geofence_name VARCHAR(100) NOT NULL,
    
    -- Event details
    event_type VARCHAR(20) NOT NULL, -- ENTRY, EXIT, DWELL
    event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Location at event
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    distance_meters FLOAT,
    
    -- Additional context
    dwell_duration_minutes INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- TASK 63: OFFLINE SYNCHRONIZATION SYSTEM
-- =============================================================================

-- Sync sessions for tracking synchronization operations
CREATE TABLE IF NOT EXISTS sync_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    device_id VARCHAR(200) NOT NULL,
    
    -- Session metadata
    client_version VARCHAR(20) NOT NULL,
    total_items INTEGER NOT NULL,
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Sync preferences
    validate_integrity BOOLEAN DEFAULT true,
    atomic_sync BOOLEAN DEFAULT true,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'PROCESSING', -- PROCESSING, COMPLETED, FAILED
    successful_syncs INTEGER DEFAULT 0,
    failed_syncs INTEGER DEFAULT 0,
    conflicts INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Individual sync items
CREATE TABLE IF NOT EXISTS sync_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_session_id UUID REFERENCES sync_sessions(id),
    
    -- Entity information
    entity_type VARCHAR(50) NOT NULL, -- employee_request, schedule_preference, etc.
    entity_id VARCHAR(50) NOT NULL,
    operation VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DELETE, MERGE
    
    -- Data payload
    entity_data JSONB NOT NULL,
    client_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    offline_hash VARCHAR(64) NOT NULL, -- SHA-256 hash for integrity
    
    -- Conflict resolution
    conflict_strategy VARCHAR(20) DEFAULT 'timestamp_based',
    force_overwrite BOOLEAN DEFAULT false,
    
    -- Status
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, PROCESSING, COMPLETED, FAILED, CONFLICT
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Sync conflicts requiring resolution
CREATE TABLE IF NOT EXISTS sync_conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_session_id UUID REFERENCES sync_sessions(id),
    sync_item_id VARCHAR(50) NOT NULL, -- References sync_items.entity_id
    
    -- Conflict details
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(50) NOT NULL,
    conflict_type VARCHAR(50) NOT NULL, -- DATA_CONFLICT, VERSION_CONFLICT, etc.
    
    -- Conflicting data
    client_data JSONB NOT NULL,
    server_data JSONB NOT NULL,
    conflict_fields JSONB, -- List of specific conflicting fields
    
    -- Resolution tracking
    auto_resolution_attempted BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, RESOLVED
    resolution_strategy VARCHAR(20),
    resolved_data JSONB,
    resolution_notes TEXT,
    
    resolved_by_tab_n VARCHAR(50),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Offline sync queue for failed items
CREATE TABLE IF NOT EXISTS offline_sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    device_id VARCHAR(200) NOT NULL,
    
    -- Sync item details
    entity_type VARCHAR(50) NOT NULL,
    entity_data JSONB NOT NULL,
    operation VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DELETE
    
    -- Sync management
    created_offline_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sync_priority INTEGER DEFAULT 1,
    sync_attempts INTEGER DEFAULT 0,
    last_sync_attempt TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, RETRYING, FAILED, COMPLETED
    sync_error TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- TASK 64: DEVICE MANAGEMENT SYSTEM
-- =============================================================================

-- Registered devices for enterprise management
CREATE TABLE IF NOT EXISTS registered_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    
    -- Device information
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL, -- iPhone, Android, Tablet, Desktop, Web Browser
    os_version VARCHAR(50) NOT NULL,
    app_version VARCHAR(20) NOT NULL,
    hardware_model VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(50) NOT NULL,
    unique_identifier VARCHAR(200) NOT NULL, -- IMEI, Serial, etc.
    
    -- Network information
    carrier VARCHAR(50),
    phone_number VARCHAR(20),
    
    -- Security features status
    passcode_enabled BOOLEAN DEFAULT false,
    biometric_enabled BOOLEAN DEFAULT false,
    encryption_enabled BOOLEAN DEFAULT false,
    vpn_enabled BOOLEAN DEFAULT false,
    jailbroken_rooted BOOLEAN DEFAULT false,
    
    -- Device capabilities
    gps_enabled BOOLEAN DEFAULT true,
    camera_enabled BOOLEAN DEFAULT true,
    microphone_enabled BOOLEAN DEFAULT true,
    network_type VARCHAR(20) DEFAULT 'WiFi+Cellular',
    
    -- Registration details
    registration_reason TEXT,
    emergency_contact VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending_approval', -- pending_approval, active, suspended, blocked, retired, lost_stolen
    
    -- Policy assignment
    assigned_policy_id UUID,
    policy_compliance_status VARCHAR(20) DEFAULT 'unknown', -- compliant, non_compliant, pending_check, unknown
    last_compliance_check TIMESTAMP WITH TIME ZONE,
    
    -- Management tracking
    registered_by_tab_n VARCHAR(50) NOT NULL,
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_date TIMESTAMP WITH TIME ZONE,
    approved_by_tab_n VARCHAR(50),
    self_registered BOOLEAN DEFAULT true,
    
    -- Status tracking
    last_seen TIMESTAMP WITH TIME ZONE,
    last_action VARCHAR(50),
    last_action_time TIMESTAMP WITH TIME ZONE,
    
    -- Policy updates
    policy_updated_at TIMESTAMP WITH TIME ZONE,
    policy_updated_by_tab_n VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_device_identifier UNIQUE(unique_identifier)
);

-- Security policies for device management
CREATE TABLE IF NOT EXISTS security_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL,
    security_level VARCHAR(20) NOT NULL, -- basic, standard, high, maximum
    description TEXT,
    
    -- Password requirements
    require_passcode BOOLEAN DEFAULT true,
    min_passcode_length INTEGER DEFAULT 6,
    require_alphanumeric BOOLEAN DEFAULT false,
    passcode_expiry_days INTEGER,
    
    -- Biometric settings
    allow_biometric BOOLEAN DEFAULT true,
    require_biometric BOOLEAN DEFAULT false,
    
    -- Device security
    require_encryption BOOLEAN DEFAULT true,
    allow_jailbreak_root BOOLEAN DEFAULT false,
    require_remote_wipe BOOLEAN DEFAULT true,
    max_failed_attempts INTEGER DEFAULT 5,
    
    -- Application restrictions
    allowed_apps JSONB, -- Array of allowed app IDs
    blocked_apps JSONB, -- Array of blocked app IDs
    allow_personal_apps BOOLEAN DEFAULT true,
    
    -- Network and data
    require_vpn BOOLEAN DEFAULT false,
    allow_personal_hotspot BOOLEAN DEFAULT true,
    data_usage_limit_mb INTEGER,
    
    -- Compliance checking
    compliance_check_interval_hours INTEGER DEFAULT 24,
    auto_remediation BOOLEAN DEFAULT true,
    non_compliance_action VARCHAR(20) DEFAULT 'warn', -- warn, restrict, block, wipe
    
    -- Location and tracking
    location_tracking_required BOOLEAN DEFAULT false,
    geofencing_enabled BOOLEAN DEFAULT false,
    
    -- Audit and monitoring
    audit_app_usage BOOLEAN DEFAULT true,
    audit_location BOOLEAN DEFAULT false,
    audit_communication BOOLEAN DEFAULT false,
    
    -- Policy management
    device_types JSONB, -- Array of applicable device types
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_by_tab_n VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Device access tokens for API authentication
CREATE TABLE IF NOT EXISTS device_access_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES registered_devices(id),
    
    -- Token details
    access_token TEXT NOT NULL,
    token_hash VARCHAR(64) NOT NULL, -- SHA-256 hash
    
    -- Validity
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by_tab_n VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_device_token_hash UNIQUE(token_hash)
);

-- Device approval workflow
CREATE TABLE IF NOT EXISTS device_approval_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES registered_devices(id),
    employee_tab_n VARCHAR(50) NOT NULL,
    requested_by_tab_n VARCHAR(50) NOT NULL,
    manager_tab_n VARCHAR(50),
    
    -- Approval status
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    approval_notes TEXT,
    approved_by_tab_n VARCHAR(50),
    approved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Remote device actions
CREATE TABLE IF NOT EXISTS device_remote_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES registered_devices(id),
    
    -- Action details
    action_type VARCHAR(20) NOT NULL, -- lock, unlock, wipe, locate, alarm, restrict
    action_reason TEXT NOT NULL,
    emergency_action BOOLEAN DEFAULT false,
    
    -- Scheduling
    scheduled_execution TIMESTAMP WITH TIME ZONE,
    
    -- Action parameters
    wipe_external_storage BOOLEAN DEFAULT true,
    lock_message VARCHAR(200),
    alarm_duration_seconds INTEGER,
    
    -- Execution tracking
    requested_by_tab_n VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, EXECUTED, FAILED, CANCELLED
    executed_at TIMESTAMP WITH TIME ZONE,
    execution_result TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Compliance violations tracking
CREATE TABLE IF NOT EXISTS compliance_violations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES registered_devices(id),
    
    -- Violation details
    violation_type VARCHAR(50) NOT NULL, -- POLICY_VIOLATION, SECURITY_RISK, etc.
    violation_description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
    
    -- Detection and resolution
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_action TEXT,
    resolved_by_tab_n VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- TASK 65: BIOMETRIC AUTHENTICATION SYSTEM
-- =============================================================================

-- Biometric enrollments per employee
CREATE TABLE IF NOT EXISTS biometric_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    
    -- Enrollment settings
    security_level VARCHAR(20) DEFAULT 'standard', -- standard, high, maximum, critical
    enrollment_reason TEXT,
    backup_authentication BOOLEAN DEFAULT true,
    multi_factor_required BOOLEAN DEFAULT false,
    
    -- Lockout settings
    max_failed_attempts INTEGER DEFAULT 5,
    lockout_duration_minutes INTEGER DEFAULT 30,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    enrolled_by_tab_n VARCHAR(50) NOT NULL,
    enrollment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Biometric templates storage
CREATE TABLE IF NOT EXISTS biometric_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID REFERENCES biometric_enrollments(id),
    
    -- Template details
    biometric_type VARCHAR(20) NOT NULL, -- fingerprint, face_id, touch_id, voice_print, iris_scan, palm_print
    template_data TEXT NOT NULL, -- Base64 encoded biometric template
    template_hash VARCHAR(64) NOT NULL, -- SHA-256 hash for integrity
    template_version VARCHAR(10) DEFAULT '1.0',
    extraction_algorithm VARCHAR(50) NOT NULL,
    quality_score DECIMAL(3,2) NOT NULL, -- 0.00 to 1.00
    
    -- Device and enrollment context
    device_id VARCHAR(200) NOT NULL,
    enrollment_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Usage tracking
    last_verification TIMESTAMP WITH TIME ZONE,
    verification_count INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    deactivated_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Security tokens for authenticated sessions
CREATE TABLE IF NOT EXISTS security_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    
    -- Token details
    token_type VARCHAR(20) NOT NULL, -- session, transaction, access, refresh
    token_hash VARCHAR(64) NOT NULL, -- SHA-256 hash
    
    -- Validity
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    scope JSONB, -- Array of allowed operations
    additional_data JSONB,
    
    -- Usage tracking
    last_used TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    issued_by_tab_n VARCHAR(50) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_token_hash UNIQUE(token_hash)
);

-- Biometric verification audit log
CREATE TABLE IF NOT EXISTS biometric_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    
    -- Action details
    action_type VARCHAR(20) NOT NULL, -- VERIFICATION, ENROLLMENT, TEMPLATE_UPDATE, etc.
    biometric_types JSONB, -- Array of biometric types involved
    
    -- Device and network context
    device_id VARCHAR(200),
    ip_address INET,
    user_agent TEXT,
    
    -- Result
    success BOOLEAN NOT NULL,
    details JSONB, -- Additional context and results
    
    -- Session tracking
    session_id UUID,
    risk_level VARCHAR(20), -- low, medium, high, critical
    
    -- Audit metadata
    performed_by_tab_n VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Biometric lockouts for failed attempts
CREATE TABLE IF NOT EXISTS biometric_lockouts (
    employee_tab_n VARCHAR(50) NOT NULL,
    device_id VARCHAR(200) NOT NULL,
    
    -- Lockout tracking
    failed_attempts INTEGER DEFAULT 0,
    first_failed_attempt TIMESTAMP WITH TIME ZONE,
    last_failed_attempt TIMESTAMP WITH TIME ZONE,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (employee_tab_n, device_id)
);

-- Employee PINs for multi-factor authentication
CREATE TABLE IF NOT EXISTS employee_pins (
    employee_tab_n VARCHAR(50) PRIMARY KEY,
    pin_hash VARCHAR(64) NOT NULL, -- SHA-256 hash
    
    -- PIN policy
    expires_at TIMESTAMP WITH TIME ZONE,
    failed_attempts INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_used TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Push notifications indexes
CREATE INDEX IF NOT EXISTS idx_push_campaigns_status ON push_notification_campaigns(status, created_at);
CREATE INDEX IF NOT EXISTS idx_push_campaigns_category ON push_notification_campaigns(category);
CREATE INDEX IF NOT EXISTS idx_device_tokens_employee ON device_tokens(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON device_tokens(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_delivery_queue(status, scheduled_delivery_time);
CREATE INDEX IF NOT EXISTS idx_notification_queue_employee ON notification_delivery_queue(employee_tab_n);

-- Location tracking indexes
CREATE INDEX IF NOT EXISTS idx_location_history_employee_time ON location_history(employee_tab_n, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_history_session ON location_history(session_id);
CREATE INDEX IF NOT EXISTS idx_location_sessions_employee ON location_tracking_sessions(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_location_sessions_active ON location_tracking_sessions(is_active, session_start);
CREATE INDEX IF NOT EXISTS idx_geofences_active ON geofences(is_active);
CREATE INDEX IF NOT EXISTS idx_geofence_assignments_employee ON geofence_assignments(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_geofence_events_employee_time ON geofence_events(employee_tab_n, event_time DESC);

-- Sync system indexes
CREATE INDEX IF NOT EXISTS idx_sync_sessions_employee_device ON sync_sessions(employee_tab_n, device_id);
CREATE INDEX IF NOT EXISTS idx_sync_sessions_status ON sync_sessions(status, created_at);
CREATE INDEX IF NOT EXISTS idx_sync_items_session ON sync_items(sync_session_id);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_status ON sync_conflicts(status, created_at);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_employee_device ON offline_sync_queue(employee_tab_n, device_id);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_status ON offline_sync_queue(sync_status, sync_priority);

-- Device management indexes
CREATE INDEX IF NOT EXISTS idx_registered_devices_employee ON registered_devices(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_registered_devices_status ON registered_devices(status);
CREATE INDEX IF NOT EXISTS idx_registered_devices_compliance ON registered_devices(policy_compliance_status);
CREATE INDEX IF NOT EXISTS idx_registered_devices_policy ON registered_devices(assigned_policy_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_device ON device_access_tokens(device_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_hash ON device_access_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_device_actions_device ON device_remote_actions(device_id);
CREATE INDEX IF NOT EXISTS idx_compliance_violations_device ON compliance_violations(device_id, detected_at);

-- Biometric system indexes
CREATE INDEX IF NOT EXISTS idx_biometric_enrollments_employee ON biometric_enrollments(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_biometric_templates_enrollment ON biometric_templates(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_biometric_templates_type_active ON biometric_templates(biometric_type, is_active);
CREATE INDEX IF NOT EXISTS idx_security_tokens_employee ON security_tokens(employee_tab_n);
CREATE INDEX IF NOT EXISTS idx_security_tokens_hash ON security_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_security_tokens_active ON security_tokens(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_biometric_audit_employee_time ON biometric_audit_log(employee_tab_n, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_biometric_lockouts_employee_device ON biometric_lockouts(employee_tab_n, device_id);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers where needed
CREATE TRIGGER update_location_preferences_timestamp
    BEFORE UPDATE ON location_tracking_preferences
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_offline_sync_queue_timestamp
    BEFORE UPDATE ON offline_sync_queue
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_employee_pins_timestamp
    BEFORE UPDATE ON employee_pins
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert sample security policy
INSERT INTO security_policies (
    id, policy_name, security_level, description,
    require_passcode, min_passcode_length, require_encryption,
    device_types, is_default, is_active, created_by_tab_n
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'Standard Mobile Policy',
    'standard',
    'Standard security policy for mobile devices',
    true, 6, true,
    '["iPhone", "Android"]'::jsonb,
    true, true, 'SYSTEM'
) ON CONFLICT (id) DO NOTHING;

-- Insert sample notification settings for existing users
INSERT INTO push_notification_settings (employee_tab_n)
SELECT tab_n FROM zup_agent_data WHERE tab_n IN ('00001', 'TS001', 'TS002')
ON CONFLICT (employee_tab_n) DO NOTHING;

-- Insert sample location tracking preferences
INSERT INTO location_tracking_preferences (employee_tab_n, tracking_mode, privacy_level)
VALUES 
('00001', 'work_hours_only', 'manager_only'),
('TS001', 'on_demand', 'private'),
('TS002', 'always', 'public')
ON CONFLICT (employee_tab_n) DO NOTHING;

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions (adjust role names as needed)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_mobile_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_mobile_app;