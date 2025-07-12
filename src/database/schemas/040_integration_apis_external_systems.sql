-- =============================================================================
-- 040_integration_apis_external_systems.sql
-- EXACT BDD Implementation: System Integration and API Management
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 11-system-integration-api-management.feature (829 lines)
-- Purpose: Complete REST API integration for seamless data flow between ARGUS WFM and external systems
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. EXTERNAL SYSTEM CONFIGURATION
-- =============================================================================

-- External system registry from BDD lines 20-62
CREATE TABLE external_system_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR(200) NOT NULL UNIQUE,
    system_type VARCHAR(50) NOT NULL CHECK (system_type IN (
        'HR_SYSTEM', 'CONTACT_CENTER', 'CHAT_PLATFORM', 'ERP', 'SSO', 'CUSTOM'
    )),
    
    -- Connection settings from BDD lines 423-438
    base_url VARCHAR(500) NOT NULL,
    port_number INTEGER DEFAULT 443,
    protocol VARCHAR(10) DEFAULT 'HTTPS' CHECK (protocol IN ('HTTP', 'HTTPS')),
    
    -- WFMCC configuration from BDD lines 422-443
    wfmcc_ip_address INET,
    wfmcc_port INTEGER DEFAULT 8080,
    wfmcc_endpoint_path VARCHAR(200) DEFAULT '/ccwfm/api/rest/status',
    
    -- Authentication from BDD lines 606-621
    auth_type VARCHAR(50) NOT NULL CHECK (auth_type IN (
        'JWT', 'API_KEY', 'BASIC', 'OAUTH2', 'NONE'
    )),
    auth_credentials JSONB, -- Encrypted credentials
    
    -- Service configuration
    service_id VARCHAR(200) DEFAULT 'External system', -- For static service handling
    is_active BOOLEAN DEFAULT true,
    has_service_concept BOOLEAN DEFAULT true, -- Some systems lack "service" concept
    
    -- Monitoring and health checks
    health_check_endpoint VARCHAR(200),
    health_check_interval_seconds INTEGER DEFAULT 60,
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20),
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. API ENDPOINT DEFINITIONS
-- =============================================================================

-- API endpoint registry from BDD lines 581-601
CREATE TABLE api_endpoint_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id) ON DELETE CASCADE,
    
    -- Endpoint configuration
    endpoint_name VARCHAR(200) NOT NULL,
    endpoint_path VARCHAR(500) NOT NULL,
    http_method VARCHAR(10) NOT NULL CHECK (http_method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
    
    -- URL patterns from BDD lines 581-595
    endpoint_category VARCHAR(50) NOT NULL CHECK (endpoint_category IN (
        'PERSONNEL_DATA', 'HISTORICAL_DATA', 'REAL_TIME_DATA', 'STATUS_TRANSMISSION'
    )),
    
    -- Data flow mapping from BDD lines 551-579
    data_direction VARCHAR(20) NOT NULL CHECK (data_direction IN (
        'EXTERNAL_TO_WFM', 'WFM_TO_EXTERNAL', 'BIDIRECTIONAL'
    )),
    update_frequency VARCHAR(50) NOT NULL CHECK (update_frequency IN (
        'REAL_TIME', 'DAILY', 'HOURLY', 'ON_DEMAND', 'SCHEDULED'
    )),
    
    -- Request/response schemas
    request_schema JSONB,
    response_schema JSONB,
    
    -- Performance settings from BDD lines 645-661
    timeout_seconds INTEGER DEFAULT 30,
    retry_attempts INTEGER DEFAULT 3,
    retry_delay_ms INTEGER DEFAULT 1000,
    circuit_breaker_threshold INTEGER DEFAULT 5,
    
    is_enabled BOOLEAN DEFAULT true,
    
    CONSTRAINT unique_system_endpoint UNIQUE(system_id, endpoint_name)
);

-- =============================================================================
-- 3. PERSONNEL STRUCTURE INTEGRATION
-- =============================================================================

-- Personnel synchronization from BDD lines 20-62
CREATE TABLE personnel_sync_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    
    -- Sync settings
    sync_enabled BOOLEAN DEFAULT true,
    sync_schedule JSONB, -- Cron-like schedule
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    next_sync_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Field mapping from BDD lines 28-40 and 45-61
    service_field_mapping JSONB DEFAULT '{
        "id": "id",
        "name": "name",
        "status": "status",
        "serviceGroups": "serviceGroups"
    }'::jsonb,
    
    agent_field_mapping JSONB DEFAULT '{
        "id": "id",
        "name": "name",
        "surname": "surname",
        "secondName": "secondName",
        "agentNumber": "agentNumber",
        "agentGroups": "agentGroups",
        "loginSSO": "loginSSO"
    }'::jsonb,
    
    -- Business rules from BDD lines 57-61
    exclude_agents_without_groups BOOLEAN DEFAULT true,
    use_single_name_field BOOLEAN DEFAULT false,
    enforce_unique_identifiers BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. HISTORICAL DATA INTEGRATION
-- =============================================================================

-- Service group historical data from BDD lines 79-112
CREATE TABLE historical_data_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN (
        'SERVICE_GROUP_DATA', 'AGENT_STATUS_DATA', 'AGENT_LOGIN_DATA', 
        'AGENT_CALLS_DATA', 'AGENT_CHATS_WORK_TIME'
    )),
    
    -- Request parameters from BDD lines 84-88
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    step_milliseconds INTEGER, -- Interval size (e.g., 300000 = 5 minutes)
    entity_ids TEXT[], -- Group IDs or Agent IDs
    
    -- Request tracking
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_received TIMESTAMP WITH TIME ZONE,
    response_status INTEGER,
    error_message TEXT,
    
    -- Response data storage
    response_data JSONB,
    
    requested_by VARCHAR(50) NOT NULL,
    
    CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- Historical metrics storage from BDD lines 100-112
CREATE TABLE historical_interval_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    service_id VARCHAR(200),
    group_id VARCHAR(200),
    
    -- Interval boundaries
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Contact metrics from BDD lines 101-111
    not_unique_received INTEGER DEFAULT 0, -- All contacts received
    not_unique_treated INTEGER DEFAULT 0,  -- All contacts processed
    not_unique_missed INTEGER DEFAULT 0,   -- All contacts missed
    received_calls INTEGER DEFAULT 0,      -- Unique contacts received
    treated_calls INTEGER DEFAULT 0,       -- Unique contacts processed
    miss_calls INTEGER DEFAULT 0,          -- Unique contacts missed
    
    -- Time metrics (milliseconds)
    aht_milliseconds INTEGER,              -- Average handling time
    post_processing_milliseconds INTEGER,   -- Post-processing time
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_interval_metric UNIQUE(system_id, service_id, group_id, interval_start)
);

-- =============================================================================
-- 5. AGENT STATUS TRACKING
-- =============================================================================

-- Agent status integration from BDD lines 137-157
CREATE TABLE agent_status_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    agent_id VARCHAR(200) NOT NULL,
    service_id VARCHAR(200),
    group_id VARCHAR(200),
    
    -- Status period from BDD lines 152-156
    status_start TIMESTAMP WITH TIME ZONE NOT NULL,
    status_end TIMESTAMP WITH TIME ZONE,
    state_code VARCHAR(100) NOT NULL,
    state_name VARCHAR(200) NOT NULL,
    
    -- Status scope from BDD lines 158-172
    status_scope VARCHAR(50) CHECK (status_scope IN (
        'SERVICE_GROUP', 'ALL_GROUPS', 'NO_GROUP'
    )),
    
    -- Status formation rules
    status_reason_id VARCHAR(100),
    status_reason_name VARCHAR(200),
    
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_status_period UNIQUE(system_id, agent_id, status_start)
);

-- =============================================================================
-- 6. REAL-TIME STATUS TRANSMISSION
-- =============================================================================

-- Real-time status updates from BDD lines 393-421
CREATE TABLE realtime_status_transmissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    
    -- Required fields from BDD lines 399-405
    worker_id VARCHAR(200) NOT NULL,
    state_name VARCHAR(200) NOT NULL,
    state_code VARCHAR(100) NOT NULL,
    system_identifier VARCHAR(200) NOT NULL,
    action_timestamp BIGINT NOT NULL, -- Unix timestamp
    action_type INTEGER NOT NULL CHECK (action_type IN (0, 1)), -- 0=exit, 1=entry
    
    -- Transmission tracking
    transmission_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transmission_status VARCHAR(20) CHECK (transmission_status IN (
        'PENDING', 'SENT', 'FAILED', 'QUEUED', 'RETRY'
    )),
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    
    -- Processing rules from BDD lines 416-421
    is_paired BOOLEAN DEFAULT false, -- Entry + exit events
    processing_mode VARCHAR(20) DEFAULT 'IMMEDIATE', -- Fire-and-forget
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. CHAT PLATFORM INTEGRATION
-- =============================================================================

-- Chat work time tracking from BDD lines 221-257
CREATE TABLE chat_work_time_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    agent_id VARCHAR(200) NOT NULL,
    
    -- Work time calculation from BDD lines 232-235
    work_date DATE NOT NULL,
    work_time_milliseconds BIGINT NOT NULL, -- Time with at least 1 chat
    
    -- Chat sessions for calculation from BDD lines 244-256
    chat_sessions JSONB, -- Array of {start, end} timestamps
    overlapping_time_handled BOOLEAN DEFAULT true,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_agent_work_date UNIQUE(system_id, agent_id, work_date)
);

-- =============================================================================
-- 8. API AUTHENTICATION AND SECURITY
-- =============================================================================

-- API access credentials from BDD lines 606-638
CREATE TABLE api_access_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    
    -- Authentication details
    credential_type VARCHAR(50) NOT NULL CHECK (credential_type IN (
        'JWT_TOKEN', 'API_KEY', 'BASIC_AUTH', 'OAUTH2_CLIENT'
    )),
    credential_name VARCHAR(200) NOT NULL,
    
    -- Encrypted storage
    credential_value_encrypted BYTEA NOT NULL, -- pgcrypto encrypted
    credential_metadata JSONB, -- Additional auth data
    
    -- Access control from BDD lines 623-638
    permission_level VARCHAR(50) NOT NULL CHECK (permission_level IN (
        'READ_ONLY', 'OPERATIONAL', 'ADMINISTRATIVE', 'INTEGRATION_SPECIFIC'
    )),
    allowed_endpoints TEXT[],
    data_scope_filters JSONB,
    
    -- Validity
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Security settings
    ip_whitelist INET[],
    rate_limit_per_minute INTEGER DEFAULT 1000,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. ERROR HANDLING AND MONITORING
-- =============================================================================

-- API error tracking from BDD lines 482-546
CREATE TABLE api_error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    endpoint_id UUID REFERENCES api_endpoint_definitions(id),
    
    -- Error details from BDD lines 489-496
    http_status_code INTEGER NOT NULL,
    error_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Error structure from BDD lines 491-496
    error_field VARCHAR(200),
    error_message TEXT NOT NULL,
    error_description TEXT,
    
    -- Request context
    request_method VARCHAR(10),
    request_path TEXT,
    request_parameters JSONB,
    request_body JSONB,
    
    -- Error categorization from BDD lines 498-546
    error_category VARCHAR(50) CHECK (error_category IN (
        'VALIDATION_ERROR', 'NO_DATA_FOUND', 'SYSTEM_ERROR', 
        'AUTHENTICATION_ERROR', 'AUTHORIZATION_ERROR', 'RATE_LIMIT_ERROR'
    )),
    
    -- System state for debugging
    system_state JSONB,
    stack_trace TEXT,
    
    -- Retention from BDD line 545
    retention_days INTEGER DEFAULT 30
);

-- =============================================================================
-- 10. PERFORMANCE MONITORING
-- =============================================================================

-- API performance metrics from BDD lines 662-678
CREATE TABLE api_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    endpoint_id UUID REFERENCES api_endpoint_definitions(id),
    
    -- Performance measurements from BDD lines 667-671
    metric_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_time_ms INTEGER NOT NULL,
    request_size_bytes INTEGER,
    response_size_bytes INTEGER,
    
    -- Throughput tracking
    requests_per_minute INTEGER,
    concurrent_requests INTEGER,
    
    -- Success/failure rates
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    timeout_count INTEGER DEFAULT 0,
    
    -- 80/20 format compliance from BDD lines 673-677
    percentile_95_response_time_ms INTEGER,
    sla_compliance_percentage DECIMAL(5,2),
    
    -- Resource utilization
    cpu_usage_percent DECIMAL(5,2),
    memory_usage_mb INTEGER,
    
    aggregation_period VARCHAR(20) CHECK (aggregation_period IN (
        'MINUTE', 'HOUR', 'DAY', 'WEEK', 'MONTH'
    ))
);

-- =============================================================================
-- 11. DATA VALIDATION RULES
-- =============================================================================

-- Input/output validation from BDD lines 682-715
CREATE TABLE api_validation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    endpoint_id UUID NOT NULL REFERENCES api_endpoint_definitions(id),
    
    -- Validation configuration from BDD lines 687-698
    validation_type VARCHAR(50) NOT NULL CHECK (validation_type IN (
        'REQUIRED_FIELDS', 'DATA_TYPES', 'FORMAT_VALIDATION', 
        'VALUE_RANGES', 'BUSINESS_RULES'
    )),
    
    field_name VARCHAR(200),
    validation_rule JSONB NOT NULL, -- Rule definition
    error_message TEXT NOT NULL,
    error_description TEXT,
    
    -- Validation scope
    applies_to VARCHAR(20) CHECK (applies_to IN ('REQUEST', 'RESPONSE', 'BOTH')),
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 12. INTEGRATION AUDIT TRAIL
-- =============================================================================

-- Comprehensive audit logging from BDD lines 760-776
CREATE TABLE integration_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_system_configurations(id),
    
    -- Audit information from BDD lines 763-769
    operation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation_type VARCHAR(50) NOT NULL,
    endpoint_path TEXT,
    http_method VARCHAR(10),
    
    -- Request/response details
    request_parameters JSONB,
    request_body JSONB,
    response_status INTEGER,
    response_body JSONB,
    
    -- User identification
    user_id VARCHAR(200),
    user_role VARCHAR(100),
    source_ip INET,
    
    -- Error information
    error_occurred BOOLEAN DEFAULT false,
    error_details JSONB,
    
    -- Compliance from BDD lines 771-775
    retention_years INTEGER DEFAULT 7,
    data_classification VARCHAR(50),
    contains_personal_data BOOLEAN DEFAULT false,
    
    -- Immutability
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) -- SHA-256 of record for tamper detection
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to handle contact uniqueness calculation from BDD lines 261-282
CREATE OR REPLACE FUNCTION calculate_contact_uniqueness(
    p_contacts JSONB,
    p_calculation_date DATE
) RETURNS JSONB AS $$
DECLARE
    v_unique_contacts JSONB;
    v_customer_ids JSONB;
BEGIN
    -- Extract unique customer IDs for the day
    SELECT jsonb_agg(DISTINCT contact->>'customerId')
    INTO v_customer_ids
    FROM jsonb_array_elements(p_contacts) AS contact
    WHERE (contact->>'startTime')::DATE = p_calculation_date;
    
    -- Return unique contact metrics
    RETURN jsonb_build_object(
        'uniqueContacts', jsonb_array_length(v_customer_ids),
        'totalContacts', jsonb_array_length(p_contacts),
        'calculationDate', p_calculation_date
    );
END;
$$ LANGUAGE plpgsql;

-- Function to calculate chat work time from BDD lines 242-256
CREATE OR REPLACE FUNCTION calculate_chat_work_time(
    p_chat_sessions JSONB,
    p_work_date DATE
) RETURNS BIGINT AS $$
DECLARE
    v_work_seconds INTEGER := 0;
    v_time_slots BOOLEAN[];
    v_session JSONB;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    i INTEGER;
BEGIN
    -- Initialize 86400 second slots for the day
    v_time_slots := array_fill(false, ARRAY[86400]);
    
    -- Mark slots with active chats
    FOR v_session IN SELECT * FROM jsonb_array_elements(p_chat_sessions)
    LOOP
        v_start_time := (v_session->>'start')::TIMESTAMP;
        v_end_time := (v_session->>'end')::TIMESTAMP;
        
        -- Calculate seconds within the work date
        FOR i IN GREATEST(0, EXTRACT(EPOCH FROM v_start_time - p_work_date::TIMESTAMP))::INTEGER
              .. LEAST(86399, EXTRACT(EPOCH FROM v_end_time - p_work_date::TIMESTAMP))::INTEGER
        LOOP
            v_time_slots[i + 1] := true;
        END LOOP;
    END LOOP;
    
    -- Count true slots
    SELECT COUNT(*) INTO v_work_seconds
    FROM unnest(v_time_slots) AS slot
    WHERE slot = true;
    
    RETURN v_work_seconds * 1000; -- Convert to milliseconds
END;
$$ LANGUAGE plpgsql;

-- Function to encrypt API credentials
CREATE OR REPLACE FUNCTION encrypt_credential(
    p_credential TEXT,
    p_key TEXT
) RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(p_credential, p_key);
END;
$$ LANGUAGE plpgsql;

-- Function to decrypt API credentials
CREATE OR REPLACE FUNCTION decrypt_credential(
    p_encrypted BYTEA,
    p_key TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(p_encrypted, p_key);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_integration_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_external_systems_timestamp
    BEFORE UPDATE ON external_system_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_integration_timestamps();

-- Trigger to generate audit checksum
CREATE OR REPLACE FUNCTION generate_audit_checksum()
RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum = encode(
        digest(
            NEW.operation_timestamp::TEXT || 
            NEW.operation_type || 
            COALESCE(NEW.request_body::TEXT, '') ||
            COALESCE(NEW.response_body::TEXT, ''),
            'sha256'
        ),
        'hex'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_audit_log_checksum
    BEFORE INSERT ON integration_audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION generate_audit_checksum();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- System configuration indexes
CREATE INDEX idx_external_systems_active ON external_system_configurations(is_active);
CREATE INDEX idx_external_systems_type ON external_system_configurations(system_type);

-- API endpoint indexes
CREATE INDEX idx_api_endpoints_system ON api_endpoint_definitions(system_id);
CREATE INDEX idx_api_endpoints_category ON api_endpoint_definitions(endpoint_category);
CREATE INDEX idx_api_endpoints_enabled ON api_endpoint_definitions(is_enabled);

-- Historical data indexes
CREATE INDEX idx_historical_requests_system ON historical_data_requests(system_id);
CREATE INDEX idx_historical_requests_date ON historical_data_requests(start_date, end_date);
CREATE INDEX idx_historical_metrics_interval ON historical_interval_metrics(interval_start, interval_end);
CREATE INDEX idx_historical_metrics_group ON historical_interval_metrics(system_id, group_id);

-- Real-time transmission indexes
CREATE INDEX idx_realtime_status_pending ON realtime_status_transmissions(transmission_status) 
    WHERE transmission_status IN ('PENDING', 'QUEUED', 'RETRY');
CREATE INDEX idx_realtime_status_timestamp ON realtime_status_transmissions(action_timestamp);

-- Performance monitoring indexes
CREATE INDEX idx_performance_metrics_time ON api_performance_metrics(metric_timestamp);
CREATE INDEX idx_performance_metrics_endpoint ON api_performance_metrics(endpoint_id);

-- Audit trail indexes
CREATE INDEX idx_audit_logs_timestamp ON integration_audit_logs(operation_timestamp);
CREATE INDEX idx_audit_logs_system ON integration_audit_logs(system_id);
CREATE INDEX idx_audit_logs_user ON integration_audit_logs(user_id);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample external system configuration
INSERT INTO external_system_configurations (
    system_name, system_type, base_url, auth_type, 
    service_id, has_service_concept, created_by
) VALUES 
('1C ZUP HR System', 'HR_SYSTEM', 'https://1c.company.ru/api', 'API_KEY', 
 '1C-ZUP', true, 'admin'),
('Oktell Contact Center', 'CONTACT_CENTER', 'https://oktell.company.ru/api', 'JWT',
 'Oktell', true, 'admin'),
('Chat Platform', 'CHAT_PLATFORM', 'https://chat.company.ru/api', 'OAUTH2',
 'ChatSystem', false, 'admin');

-- Sample API endpoints
INSERT INTO api_endpoint_definitions (
    system_id, endpoint_name, endpoint_path, http_method,
    endpoint_category, data_direction, update_frequency
) VALUES
((SELECT id FROM external_system_configurations WHERE system_name = '1C ZUP HR System'),
 'Get Personnel', '/personnel', 'GET', 'PERSONNEL_DATA', 'EXTERNAL_TO_WFM', 'DAILY'),
((SELECT id FROM external_system_configurations WHERE system_name = 'Oktell Contact Center'),
 'Get Historical Data', '/historic/serviceGroupData', 'GET', 'HISTORICAL_DATA', 'EXTERNAL_TO_WFM', 'ON_DEMAND'),
((SELECT id FROM external_system_configurations WHERE system_name = 'Oktell Contact Center'),
 'Send Status Update', '/ccwfm/api/rest/status', 'POST', 'STATUS_TRANSMISSION', 'WFM_TO_EXTERNAL', 'REAL_TIME');

-- Sample validation rules
INSERT INTO api_validation_rules (
    endpoint_id, validation_type, field_name, validation_rule,
    error_message, applies_to
) VALUES
((SELECT id FROM api_endpoint_definitions WHERE endpoint_name = 'Get Historical Data'),
 'REQUIRED_FIELDS', 'startDate', '{"required": true, "format": "ISO8601"}'::jsonb,
 'startDate is required and must be in ISO 8601 format', 'REQUEST'),
((SELECT id FROM api_endpoint_definitions WHERE endpoint_name = 'Get Historical Data'),
 'VALUE_RANGES', 'step', '{"min": 60000, "max": 3600000}'::jsonb,
 'step must be between 60000 and 3600000 milliseconds', 'REQUEST');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_integration_service;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_readonly;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_integration_service;