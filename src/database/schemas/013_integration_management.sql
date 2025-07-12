-- ===================================================================================
-- INTEGRATION MANAGEMENT SCHEMA
-- Schema: 013_integration_management.sql
-- Purpose: External system connectivity and data integration
-- Author: Subagent 6
-- Dependencies: 001_initial_schema.sql
-- ===================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ===================================================================================
-- TABLE 1: INTEGRATION_ENDPOINTS
-- External system endpoints configuration
-- ===================================================================================

CREATE TABLE integration_endpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    endpoint_type VARCHAR(50) NOT NULL CHECK (endpoint_type IN ('REST_API', 'SOAP', 'DATABASE', 'FILE_SYSTEM', 'QUEUE', 'WEBHOOK')),
    base_url VARCHAR(500),
    system_code VARCHAR(50) NOT NULL, -- '1C_ZUP', 'TELEPHONY', 'INTEGRATION_OPUS', etc.
    environment VARCHAR(20) NOT NULL DEFAULT 'production' CHECK (environment IN ('development', 'staging', 'production')),
    is_active BOOLEAN DEFAULT true,
    timeout_seconds INTEGER DEFAULT 30,
    retry_count INTEGER DEFAULT 3,
    
    -- Configuration details
    config_json JSONB NOT NULL DEFAULT '{}',
    headers_json JSONB DEFAULT '{}',
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance', 'error')),
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'unhealthy', 'unknown')),
    
    -- Security
    requires_auth BOOLEAN DEFAULT true,
    auth_config_id UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(name, environment),
    CHECK (base_url IS NOT NULL OR endpoint_type = 'DATABASE')
);

-- Indexes for integration_endpoints
CREATE INDEX idx_integration_endpoints_system_code ON integration_endpoints(system_code);
CREATE INDEX idx_integration_endpoints_type ON integration_endpoints(endpoint_type);
CREATE INDEX idx_integration_endpoints_active ON integration_endpoints(is_active) WHERE is_active = true;
CREATE INDEX idx_integration_endpoints_status ON integration_endpoints(status);
CREATE INDEX idx_integration_endpoints_health ON integration_endpoints(health_status);
CREATE INDEX idx_integration_endpoints_config ON integration_endpoints USING gin(config_json);

-- ===================================================================================
-- TABLE 2: INTEGRATION_MAPPINGS
-- Data mapping configurations between systems
-- ===================================================================================

CREATE TABLE integration_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mapping_name VARCHAR(255) NOT NULL,
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    entity_type VARCHAR(100) NOT NULL, -- 'employee', 'schedule', 'timesheet', etc.
    
    -- Mapping configuration
    source_schema JSONB NOT NULL,
    target_schema JSONB NOT NULL,
    field_mappings JSONB NOT NULL,
    transformation_rules JSONB DEFAULT '{}',
    
    -- Validation rules
    validation_rules JSONB DEFAULT '{}',
    required_fields TEXT[],
    
    -- Sync configuration
    sync_direction VARCHAR(20) DEFAULT 'bidirectional' CHECK (sync_direction IN ('source_to_target', 'target_to_source', 'bidirectional')),
    conflict_resolution VARCHAR(30) DEFAULT 'manual' CHECK (conflict_resolution IN ('source_wins', 'target_wins', 'latest_wins', 'manual')),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(mapping_name, version),
    CHECK (source_system != target_system)
);

-- Indexes for integration_mappings
CREATE INDEX idx_integration_mappings_systems ON integration_mappings(source_system, target_system);
CREATE INDEX idx_integration_mappings_entity ON integration_mappings(entity_type);
CREATE INDEX idx_integration_mappings_active ON integration_mappings(is_active) WHERE is_active = true;
CREATE INDEX idx_integration_mappings_source_schema ON integration_mappings USING gin(source_schema);
CREATE INDEX idx_integration_mappings_target_schema ON integration_mappings USING gin(target_schema);
CREATE INDEX idx_integration_mappings_field_mappings ON integration_mappings USING gin(field_mappings);

-- ===================================================================================
-- TABLE 3: INTEGRATION_SYNC
-- Synchronization tracking and status
-- ===================================================================================

CREATE TABLE integration_sync (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_name VARCHAR(255) NOT NULL,
    mapping_id UUID NOT NULL REFERENCES integration_mappings(id),
    source_endpoint_id UUID REFERENCES integration_endpoints(id),
    target_endpoint_id UUID REFERENCES integration_endpoints(id),
    
    -- Sync configuration
    sync_type VARCHAR(30) NOT NULL CHECK (sync_type IN ('full_sync', 'incremental', 'real_time', 'batch', 'manual')),
    sync_mode VARCHAR(20) NOT NULL CHECK (sync_mode IN ('push', 'pull', 'bidirectional')),
    
    -- Status tracking
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled', 'paused')),
    
    -- Timing
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    
    -- Progress tracking
    total_records INTEGER DEFAULT 0,
    processed_records INTEGER DEFAULT 0,
    successful_records INTEGER DEFAULT 0,
    failed_records INTEGER DEFAULT 0,
    skipped_records INTEGER DEFAULT 0,
    
    -- Results
    sync_result JSONB DEFAULT '{}',
    error_summary TEXT,
    
    -- Performance metrics
    duration_seconds INTEGER,
    records_per_second DECIMAL(10,2),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    
    -- Constraints
    CHECK (completed_at IS NULL OR completed_at >= started_at),
    CHECK (started_at IS NULL OR started_at >= scheduled_at)
);

-- Indexes for integration_sync
CREATE INDEX idx_integration_sync_mapping ON integration_sync(mapping_id);
CREATE INDEX idx_integration_sync_status ON integration_sync(status);
CREATE INDEX idx_integration_sync_scheduled ON integration_sync(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_integration_sync_next_run ON integration_sync(next_run_at) WHERE next_run_at IS NOT NULL;
CREATE INDEX idx_integration_sync_type ON integration_sync(sync_type);
CREATE INDEX idx_integration_sync_endpoints ON integration_sync(source_endpoint_id, target_endpoint_id);
CREATE INDEX idx_integration_sync_created ON integration_sync(created_at);
CREATE INDEX idx_integration_sync_result ON integration_sync USING gin(sync_result);

-- ===================================================================================
-- TABLE 4: INTEGRATION_ERRORS
-- Error logging and handling
-- ===================================================================================

CREATE TABLE integration_errors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_id UUID REFERENCES integration_sync(id),
    endpoint_id UUID REFERENCES integration_endpoints(id),
    
    -- Error classification
    error_type VARCHAR(50) NOT NULL CHECK (error_type IN ('connection', 'authentication', 'authorization', 'data_validation', 'transformation', 'business_logic', 'timeout', 'rate_limit', 'system')),
    error_severity VARCHAR(20) NOT NULL CHECK (error_severity IN ('low', 'medium', 'high', 'critical')),
    error_code VARCHAR(50),
    
    -- Error details
    error_message TEXT NOT NULL,
    error_details JSONB DEFAULT '{}',
    stack_trace TEXT,
    
    -- Context
    entity_type VARCHAR(100),
    entity_id VARCHAR(255),
    record_data JSONB,
    
    -- Resolution
    resolution_status VARCHAR(30) DEFAULT 'new' CHECK (resolution_status IN ('new', 'investigating', 'resolved', 'ignored', 'permanent_failure')),
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    
    -- Retry information
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for integration_errors
CREATE INDEX idx_integration_errors_sync ON integration_errors(sync_id);
CREATE INDEX idx_integration_errors_endpoint ON integration_errors(endpoint_id);
CREATE INDEX idx_integration_errors_type ON integration_errors(error_type);
CREATE INDEX idx_integration_errors_severity ON integration_errors(error_severity);
CREATE INDEX idx_integration_errors_status ON integration_errors(resolution_status);
CREATE INDEX idx_integration_errors_occurred ON integration_errors(occurred_at);
CREATE INDEX idx_integration_errors_retry ON integration_errors(next_retry_at) WHERE next_retry_at IS NOT NULL;
CREATE INDEX idx_integration_errors_entity ON integration_errors(entity_type, entity_id);
CREATE INDEX idx_integration_errors_details ON integration_errors USING gin(error_details);

-- ===================================================================================
-- TABLE 5: INTEGRATION_QUEUE
-- Message queue for asynchronous processing
-- ===================================================================================

CREATE TABLE integration_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_name VARCHAR(255) NOT NULL,
    
    -- Message details
    message_type VARCHAR(100) NOT NULL,
    message_payload JSONB NOT NULL,
    message_headers JSONB DEFAULT '{}',
    
    -- Source information
    source_system VARCHAR(50),
    source_endpoint_id UUID REFERENCES integration_endpoints(id),
    correlation_id UUID,
    
    -- Processing details
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'retrying', 'dead_letter')),
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processing_started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Retry logic
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    
    -- Processing results
    processing_result JSONB DEFAULT '{}',
    error_message TEXT,
    
    -- TTL and cleanup
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    processed_by VARCHAR(255), -- Worker/process identifier
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for integration_queue
CREATE INDEX idx_integration_queue_status ON integration_queue(status);
CREATE INDEX idx_integration_queue_scheduled ON integration_queue(scheduled_at) WHERE status IN ('pending', 'retrying');
CREATE INDEX idx_integration_queue_priority ON integration_queue(priority DESC, scheduled_at ASC) WHERE status = 'pending';
CREATE INDEX idx_integration_queue_name ON integration_queue(queue_name);
CREATE INDEX idx_integration_queue_type ON integration_queue(message_type);
CREATE INDEX idx_integration_queue_correlation ON integration_queue(correlation_id);
CREATE INDEX idx_integration_queue_source ON integration_queue(source_system);
CREATE INDEX idx_integration_queue_expires ON integration_queue(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_integration_queue_payload ON integration_queue USING gin(message_payload);

-- ===================================================================================
-- TABLE 6: INTEGRATION_TRANSFORMS
-- Data transformation rules and functions
-- ===================================================================================

CREATE TABLE integration_transforms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transform_name VARCHAR(255) NOT NULL,
    transform_type VARCHAR(50) NOT NULL CHECK (transform_type IN ('field_mapping', 'data_conversion', 'aggregation', 'validation', 'enrichment', 'custom_function')),
    
    -- Source and target
    source_field VARCHAR(255),
    target_field VARCHAR(255),
    
    -- Transformation logic
    transform_expression TEXT, -- SQL expression or function call
    transform_function VARCHAR(255), -- Function name
    transform_parameters JSONB DEFAULT '{}',
    
    -- Validation
    validation_rule TEXT,
    default_value TEXT,
    
    -- Conditions
    condition_expression TEXT, -- When to apply this transform
    
    -- Error handling
    error_handling VARCHAR(30) DEFAULT 'fail' CHECK (error_handling IN ('fail', 'skip', 'default', 'ignore')),
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    execution_order INTEGER DEFAULT 1,
    description TEXT,
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(transform_name, version)
);

-- Indexes for integration_transforms
CREATE INDEX idx_integration_transforms_name ON integration_transforms(transform_name);
CREATE INDEX idx_integration_transforms_type ON integration_transforms(transform_type);
CREATE INDEX idx_integration_transforms_active ON integration_transforms(is_active) WHERE is_active = true;
CREATE INDEX idx_integration_transforms_fields ON integration_transforms(source_field, target_field);
CREATE INDEX idx_integration_transforms_order ON integration_transforms(execution_order);
CREATE INDEX idx_integration_transforms_function ON integration_transforms(transform_function);
CREATE INDEX idx_integration_transforms_parameters ON integration_transforms USING gin(transform_parameters);

-- ===================================================================================
-- TABLE 7: INTEGRATION_SCHEDULES
-- Scheduled synchronization operations
-- ===================================================================================

CREATE TABLE integration_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_name VARCHAR(255) NOT NULL,
    mapping_id UUID NOT NULL REFERENCES integration_mappings(id),
    
    -- Schedule configuration
    schedule_type VARCHAR(30) NOT NULL CHECK (schedule_type IN ('cron', 'interval', 'manual', 'event_triggered')),
    cron_expression VARCHAR(255), -- For cron schedules
    interval_minutes INTEGER, -- For interval schedules
    
    -- Timing
    start_date DATE,
    end_date DATE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Event triggers
    trigger_events TEXT[], -- Array of event names
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'disabled', 'error')),
    
    -- Execution tracking
    last_run_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    last_run_status VARCHAR(30),
    last_run_duration_seconds INTEGER,
    
    -- Run history limits
    max_concurrent_runs INTEGER DEFAULT 1,
    run_timeout_minutes INTEGER DEFAULT 60,
    
    -- Failure handling
    failure_threshold INTEGER DEFAULT 3,
    consecutive_failures INTEGER DEFAULT 0,
    failure_notification_emails TEXT[],
    
    -- Configuration
    schedule_config JSONB DEFAULT '{}',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CHECK ((schedule_type = 'cron' AND cron_expression IS NOT NULL) OR 
           (schedule_type = 'interval' AND interval_minutes IS NOT NULL) OR 
           (schedule_type IN ('manual', 'event_triggered'))),
    CHECK (start_date IS NULL OR end_date IS NULL OR start_date <= end_date)
);

-- Indexes for integration_schedules
CREATE INDEX idx_integration_schedules_mapping ON integration_schedules(mapping_id);
CREATE INDEX idx_integration_schedules_active ON integration_schedules(is_active) WHERE is_active = true;
CREATE INDEX idx_integration_schedules_next_run ON integration_schedules(next_run_at) WHERE next_run_at IS NOT NULL;
CREATE INDEX idx_integration_schedules_type ON integration_schedules(schedule_type);
CREATE INDEX idx_integration_schedules_status ON integration_schedules(status);
CREATE INDEX idx_integration_schedules_events ON integration_schedules USING gin(trigger_events);
CREATE INDEX idx_integration_schedules_config ON integration_schedules USING gin(schedule_config);

-- ===================================================================================
-- TABLE 8: INTEGRATION_AUTH
-- Authentication configurations
-- ===================================================================================

CREATE TABLE integration_auth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_name VARCHAR(255) NOT NULL,
    auth_type VARCHAR(50) NOT NULL CHECK (auth_type IN ('basic', 'bearer_token', 'api_key', 'oauth2', 'oauth1', 'certificate', 'ntlm', 'custom')),
    
    -- Basic auth
    username VARCHAR(255),
    password_encrypted TEXT, -- Encrypted password
    
    -- API Key
    api_key_encrypted TEXT, -- Encrypted API key
    api_key_header VARCHAR(100) DEFAULT 'X-API-Key',
    
    -- Bearer token
    bearer_token_encrypted TEXT, -- Encrypted bearer token
    
    -- OAuth2
    oauth2_config JSONB DEFAULT '{}', -- client_id, client_secret, scope, etc.
    access_token_encrypted TEXT,
    refresh_token_encrypted TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Certificate
    certificate_path VARCHAR(500),
    certificate_password_encrypted TEXT,
    
    -- Custom headers
    custom_headers JSONB DEFAULT '{}',
    
    -- Security
    encryption_key_id VARCHAR(255), -- Reference to encryption key
    
    -- Token refresh
    auto_refresh BOOLEAN DEFAULT false,
    refresh_threshold_minutes INTEGER DEFAULT 30,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_validated_at TIMESTAMP WITH TIME ZONE,
    validation_status VARCHAR(30) DEFAULT 'unknown' CHECK (validation_status IN ('valid', 'invalid', 'expired', 'unknown')),
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(auth_name)
);

-- Indexes for integration_auth
CREATE INDEX idx_integration_auth_name ON integration_auth(auth_name);
CREATE INDEX idx_integration_auth_type ON integration_auth(auth_type);
CREATE INDEX idx_integration_auth_active ON integration_auth(is_active) WHERE is_active = true;
CREATE INDEX idx_integration_auth_validation ON integration_auth(validation_status);
CREATE INDEX idx_integration_auth_expires ON integration_auth(token_expires_at) WHERE token_expires_at IS NOT NULL;
CREATE INDEX idx_integration_auth_config ON integration_auth USING gin(oauth2_config);

-- Add foreign key constraint to integration_endpoints
ALTER TABLE integration_endpoints 
ADD CONSTRAINT fk_integration_endpoints_auth 
FOREIGN KEY (auth_config_id) REFERENCES integration_auth(id);

-- ===================================================================================
-- TABLE 9: INTEGRATION_LOGS
-- Detailed operation logs
-- ===================================================================================

CREATE TABLE integration_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_id UUID REFERENCES integration_sync(id),
    endpoint_id UUID REFERENCES integration_endpoints(id),
    
    -- Log classification
    log_level VARCHAR(20) NOT NULL CHECK (log_level IN ('debug', 'info', 'warning', 'error', 'critical')),
    log_category VARCHAR(50) NOT NULL, -- 'authentication', 'data_processing', 'transformation', etc.
    
    -- Log content
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    
    -- Context
    entity_type VARCHAR(100),
    entity_id VARCHAR(255),
    operation VARCHAR(100),
    
    -- Performance metrics
    duration_ms INTEGER,
    memory_usage_mb INTEGER,
    
    -- Request/Response data
    request_data JSONB,
    response_data JSONB,
    
    -- Correlation
    correlation_id UUID,
    trace_id UUID,
    
    -- Timestamp
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Additional metadata
    source_system VARCHAR(50),
    user_id UUID,
    session_id VARCHAR(255)
);

-- Indexes for integration_logs
CREATE INDEX idx_integration_logs_sync ON integration_logs(sync_id);
CREATE INDEX idx_integration_logs_endpoint ON integration_logs(endpoint_id);
CREATE INDEX idx_integration_logs_level ON integration_logs(log_level);
CREATE INDEX idx_integration_logs_category ON integration_logs(log_category);
CREATE INDEX idx_integration_logs_logged_at ON integration_logs(logged_at);
CREATE INDEX idx_integration_logs_entity ON integration_logs(entity_type, entity_id);
CREATE INDEX idx_integration_logs_operation ON integration_logs(operation);
CREATE INDEX idx_integration_logs_correlation ON integration_logs(correlation_id);
CREATE INDEX idx_integration_logs_trace ON integration_logs(trace_id);
CREATE INDEX idx_integration_logs_details ON integration_logs USING gin(details);

-- ===================================================================================
-- TABLE 10: INTEGRATION_CONFLICTS
-- Conflict resolution and tracking
-- ===================================================================================

CREATE TABLE integration_conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_id UUID NOT NULL REFERENCES integration_sync(id),
    mapping_id UUID NOT NULL REFERENCES integration_mappings(id),
    
    -- Conflict identification
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(255) NOT NULL,
    conflict_type VARCHAR(50) NOT NULL CHECK (conflict_type IN ('duplicate_key', 'data_mismatch', 'timestamp_conflict', 'business_rule', 'validation_error', 'reference_conflict')),
    
    -- Conflict data
    source_data JSONB NOT NULL,
    target_data JSONB NOT NULL,
    conflicting_fields TEXT[],
    
    -- Resolution
    resolution_strategy VARCHAR(50) DEFAULT 'manual' CHECK (resolution_strategy IN ('source_wins', 'target_wins', 'latest_wins', 'merge', 'manual', 'skip')),
    resolution_status VARCHAR(30) DEFAULT 'pending' CHECK (resolution_status IN ('pending', 'resolved', 'skipped', 'failed')),
    resolution_data JSONB,
    resolution_notes TEXT,
    
    -- Timing
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Resolution metadata
    resolved_by UUID,
    auto_resolved BOOLEAN DEFAULT false,
    
    -- Priority
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for integration_conflicts
CREATE INDEX idx_integration_conflicts_sync ON integration_conflicts(sync_id);
CREATE INDEX idx_integration_conflicts_mapping ON integration_conflicts(mapping_id);
CREATE INDEX idx_integration_conflicts_entity ON integration_conflicts(entity_type, entity_id);
CREATE INDEX idx_integration_conflicts_type ON integration_conflicts(conflict_type);
CREATE INDEX idx_integration_conflicts_status ON integration_conflicts(resolution_status);
CREATE INDEX idx_integration_conflicts_detected ON integration_conflicts(detected_at);
CREATE INDEX idx_integration_conflicts_priority ON integration_conflicts(priority DESC, detected_at ASC);
CREATE INDEX idx_integration_conflicts_pending ON integration_conflicts(resolution_status) WHERE resolution_status = 'pending';
CREATE INDEX idx_integration_conflicts_fields ON integration_conflicts USING gin(conflicting_fields);

-- ===================================================================================
-- TABLE 11: API_CONFIGURATIONS
-- API endpoint configurations
-- ===================================================================================

CREATE TABLE api_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_name VARCHAR(255) NOT NULL,
    api_version VARCHAR(50) NOT NULL DEFAULT 'v1',
    endpoint_id UUID NOT NULL REFERENCES integration_endpoints(id),
    
    -- API specification
    specification_type VARCHAR(20) NOT NULL CHECK (specification_type IN ('openapi', 'swagger', 'raml', 'blueprint', 'custom')),
    specification_url VARCHAR(500),
    specification_content JSONB,
    
    -- Rate limiting
    rate_limit_per_minute INTEGER,
    rate_limit_per_hour INTEGER,
    rate_limit_per_day INTEGER,
    concurrent_requests_limit INTEGER DEFAULT 10,
    
    -- Request/Response configuration
    default_headers JSONB DEFAULT '{}',
    default_query_params JSONB DEFAULT '{}',
    request_timeout_seconds INTEGER DEFAULT 30,
    
    -- Response handling
    success_status_codes INTEGER[] DEFAULT ARRAY[200, 201, 202, 204],
    retry_status_codes INTEGER[] DEFAULT ARRAY[429, 500, 502, 503, 504],
    
    -- Data format
    request_format VARCHAR(20) DEFAULT 'json' CHECK (request_format IN ('json', 'xml', 'form', 'multipart')),
    response_format VARCHAR(20) DEFAULT 'json' CHECK (response_format IN ('json', 'xml', 'csv', 'text')),
    
    -- Pagination
    supports_pagination BOOLEAN DEFAULT false,
    pagination_config JSONB DEFAULT '{}',
    
    -- Caching
    cache_enabled BOOLEAN DEFAULT false,
    cache_ttl_seconds INTEGER DEFAULT 300,
    
    -- Monitoring
    health_check_endpoint VARCHAR(255),
    health_check_interval_minutes INTEGER DEFAULT 15,
    
    -- Security
    requires_https BOOLEAN DEFAULT true,
    allowed_origins TEXT[],
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(api_name, api_version)
);

-- Indexes for api_configurations
CREATE INDEX idx_api_configurations_endpoint ON api_configurations(endpoint_id);
CREATE INDEX idx_api_configurations_name ON api_configurations(api_name);
CREATE INDEX idx_api_configurations_version ON api_configurations(api_version);
CREATE INDEX idx_api_configurations_active ON api_configurations(is_active) WHERE is_active = true;
CREATE INDEX idx_api_configurations_spec ON api_configurations USING gin(specification_content);
CREATE INDEX idx_api_configurations_headers ON api_configurations USING gin(default_headers);
CREATE INDEX idx_api_configurations_pagination ON api_configurations USING gin(pagination_config);

-- ===================================================================================
-- TABLE 12: WEBHOOK_SUBSCRIPTIONS
-- Webhook management and subscriptions
-- ===================================================================================

CREATE TABLE webhook_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_name VARCHAR(255) NOT NULL,
    endpoint_id UUID REFERENCES integration_endpoints(id),
    
    -- Webhook configuration
    webhook_url VARCHAR(500) NOT NULL,
    webhook_method VARCHAR(10) DEFAULT 'POST' CHECK (webhook_method IN ('POST', 'PUT', 'PATCH')),
    
    -- Event configuration
    event_types TEXT[] NOT NULL, -- Array of event types to subscribe to
    event_filters JSONB DEFAULT '{}', -- Additional filters for events
    
    -- Security
    secret_key_encrypted TEXT, -- For webhook signature verification
    signature_header VARCHAR(100) DEFAULT 'X-Webhook-Signature',
    signature_algorithm VARCHAR(20) DEFAULT 'sha256' CHECK (signature_algorithm IN ('sha1', 'sha256', 'sha512')),
    
    -- Headers and payload
    custom_headers JSONB DEFAULT '{}',
    payload_template JSONB DEFAULT '{}',
    include_metadata BOOLEAN DEFAULT true,
    
    -- Retry configuration
    retry_enabled BOOLEAN DEFAULT true,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    retry_backoff_multiplier DECIMAL(3,2) DEFAULT 2.0,
    
    -- Status and health
    is_active BOOLEAN DEFAULT true,
    status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'failed', 'suspended')),
    
    -- Delivery tracking
    total_deliveries INTEGER DEFAULT 0,
    successful_deliveries INTEGER DEFAULT 0,
    failed_deliveries INTEGER DEFAULT 0,
    last_delivery_at TIMESTAMP WITH TIME ZONE,
    last_delivery_status VARCHAR(30),
    last_delivery_response_code INTEGER,
    
    -- Rate limiting
    rate_limit_per_minute INTEGER,
    
    -- Timeout
    timeout_seconds INTEGER DEFAULT 30,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    UNIQUE(subscription_name)
);

-- Indexes for webhook_subscriptions
CREATE INDEX idx_webhook_subscriptions_endpoint ON webhook_subscriptions(endpoint_id);
CREATE INDEX idx_webhook_subscriptions_active ON webhook_subscriptions(is_active) WHERE is_active = true;
CREATE INDEX idx_webhook_subscriptions_status ON webhook_subscriptions(status);
CREATE INDEX idx_webhook_subscriptions_events ON webhook_subscriptions USING gin(event_types);
CREATE INDEX idx_webhook_subscriptions_url ON webhook_subscriptions(webhook_url);
CREATE INDEX idx_webhook_subscriptions_last_delivery ON webhook_subscriptions(last_delivery_at);
CREATE INDEX idx_webhook_subscriptions_filters ON webhook_subscriptions USING gin(event_filters);

-- ===================================================================================
-- INTEGRATION FUNCTIONS FOR INTEGRATION-OPUS
-- ===================================================================================

-- Function to create INTEGRATION-OPUS compatible endpoint
CREATE OR REPLACE FUNCTION create_integration_opus_endpoint(
    p_name VARCHAR(255),
    p_base_url VARCHAR(500),
    p_auth_config JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    v_endpoint_id UUID;
    v_auth_id UUID;
BEGIN
    -- Create authentication configuration if provided
    IF p_auth_config IS NOT NULL AND p_auth_config != '{}' THEN
        INSERT INTO integration_auth (
            auth_name,
            auth_type,
            oauth2_config,
            is_active
        ) VALUES (
            p_name || '_auth',
            'oauth2',
            p_auth_config,
            true
        ) RETURNING id INTO v_auth_id;
    END IF;
    
    -- Create endpoint
    INSERT INTO integration_endpoints (
        name,
        description,
        endpoint_type,
        base_url,
        system_code,
        auth_config_id,
        config_json,
        is_active
    ) VALUES (
        p_name,
        'INTEGRATION-OPUS endpoint for ' || p_name,
        'REST_API',
        p_base_url,
        'INTEGRATION_OPUS',
        v_auth_id,
        jsonb_build_object(
            'supports_batch', true,
            'max_batch_size', 100,
            'compression', 'gzip'
        ),
        true
    ) RETURNING id INTO v_endpoint_id;
    
    -- Create API configuration
    INSERT INTO api_configurations (
        api_name,
        api_version,
        endpoint_id,
        specification_type,
        rate_limit_per_minute,
        concurrent_requests_limit,
        default_headers,
        supports_pagination,
        pagination_config
    ) VALUES (
        p_name || '_api',
        'v1',
        v_endpoint_id,
        'openapi',
        1000,
        20,
        jsonb_build_object(
            'Content-Type', 'application/json',
            'Accept', 'application/json'
        ),
        true,
        jsonb_build_object(
            'type', 'offset',
            'limit_param', 'limit',
            'offset_param', 'offset',
            'default_limit', 50,
            'max_limit', 1000
        )
    );
    
    RETURN v_endpoint_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create 1C ZUP integration mapping
CREATE OR REPLACE FUNCTION create_1c_zup_employee_mapping() RETURNS UUID AS $$
DECLARE
    v_mapping_id UUID;
BEGIN
    INSERT INTO integration_mappings (
        mapping_name,
        source_system,
        target_system,
        entity_type,
        source_schema,
        target_schema,
        field_mappings,
        transformation_rules,
        validation_rules,
        required_fields,
        is_active
    ) VALUES (
        '1C_ZUP_Employee_Mapping',
        '1C_ZUP',
        'WFM',
        'employee',
        jsonb_build_object(
            'Код', 'string',
            'Наименование', 'string',
            'Подразделение', 'string',
            'Должность', 'string',
            'ТабельныйНомер', 'string',
            'ДатаПриема', 'date',
            'ДатаУвольнения', 'date',
            'Телефон', 'string',
            'Email', 'string'
        ),
        jsonb_build_object(
            'employee_id', 'string',
            'full_name', 'string',
            'department', 'string',
            'position', 'string',
            'employee_number', 'string',
            'hire_date', 'date',
            'termination_date', 'date',
            'phone', 'string',
            'email', 'string',
            'is_active', 'boolean'
        ),
        jsonb_build_object(
            'employee_id', 'source.Код',
            'full_name', 'source.Наименование',
            'department', 'source.Подразделение',
            'position', 'source.Должность',
            'employee_number', 'source.ТабельныйНомер',
            'hire_date', 'source.ДатаПриема',
            'termination_date', 'source.ДатаУвольнения',
            'phone', 'source.Телефон',
            'email', 'source.Email',
            'is_active', 'source.ДатаУвольнения IS NULL'
        ),
        jsonb_build_object(
            'date_format', 'DD.MM.YYYY',
            'phone_format', 'normalize_phone',
            'email_validation', 'email_regex'
        ),
        jsonb_build_object(
            'email_pattern', '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
            'phone_pattern', '^\+?[1-9]\d{1,14}$'
        ),
        ARRAY['employee_id', 'full_name', 'department', 'position'],
        true
    ) RETURNING id INTO v_mapping_id;
    
    RETURN v_mapping_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create telephony integration endpoint
CREATE OR REPLACE FUNCTION create_telephony_endpoint(
    p_name VARCHAR(255),
    p_base_url VARCHAR(500),
    p_system_type VARCHAR(50) DEFAULT 'ASTERISK'
) RETURNS UUID AS $$
DECLARE
    v_endpoint_id UUID;
    v_auth_id UUID;
BEGIN
    -- Create basic auth for telephony
    INSERT INTO integration_auth (
        auth_name,
        auth_type,
        username,
        password_encrypted,
        is_active
    ) VALUES (
        p_name || '_auth',
        'basic',
        'admin',
        crypt('admin', gen_salt('bf')),
        true
    ) RETURNING id INTO v_auth_id;
    
    -- Create telephony endpoint
    INSERT INTO integration_endpoints (
        name,
        description,
        endpoint_type,
        base_url,
        system_code,
        auth_config_id,
        config_json,
        is_active
    ) VALUES (
        p_name,
        'Telephony system endpoint for ' || p_system_type,
        'REST_API',
        p_base_url,
        'TELEPHONY',
        v_auth_id,
        jsonb_build_object(
            'system_type', p_system_type,
            'supports_realtime', true,
            'call_monitoring', true,
            'recording_enabled', true
        ),
        true
    ) RETURNING id INTO v_endpoint_id;
    
    -- Create webhook subscription for call events
    INSERT INTO webhook_subscriptions (
        subscription_name,
        endpoint_id,
        webhook_url,
        event_types,
        event_filters,
        custom_headers,
        is_active
    ) VALUES (
        p_name || '_call_events',
        v_endpoint_id,
        p_base_url || '/api/webhooks/call-events',
        ARRAY['call_started', 'call_ended', 'call_answered', 'call_missed'],
        jsonb_build_object(
            'call_direction', 'both',
            'min_duration', 0
        ),
        jsonb_build_object(
            'X-System-Type', p_system_type,
            'X-Event-Source', 'telephony'
        ),
        true
    );
    
    RETURN v_endpoint_id;
END;
$$ LANGUAGE plpgsql;

-- Function to process integration queue
CREATE OR REPLACE FUNCTION process_integration_queue(
    p_queue_name VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE(
    processed_count INTEGER,
    success_count INTEGER,
    failure_count INTEGER
) AS $$
DECLARE
    v_processed_count INTEGER := 0;
    v_success_count INTEGER := 0;
    v_failure_count INTEGER := 0;
    v_record RECORD;
BEGIN
    FOR v_record IN 
        SELECT *
        FROM integration_queue
        WHERE (p_queue_name IS NULL OR queue_name = p_queue_name)
        AND status = 'pending'
        AND scheduled_at <= CURRENT_TIMESTAMP
        ORDER BY priority DESC, scheduled_at ASC
        LIMIT p_limit
    LOOP
        BEGIN
            -- Update status to processing
            UPDATE integration_queue 
            SET status = 'processing',
                processing_started_at = CURRENT_TIMESTAMP,
                processed_by = 'system_processor'
            WHERE id = v_record.id;
            
            -- Process the message (this would be implemented based on message_type)
            -- For now, we'll just mark as completed
            UPDATE integration_queue 
            SET status = 'completed',
                completed_at = CURRENT_TIMESTAMP,
                processing_result = jsonb_build_object(
                    'processed_at', CURRENT_TIMESTAMP,
                    'success', true
                )
            WHERE id = v_record.id;
            
            v_processed_count := v_processed_count + 1;
            v_success_count := v_success_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Handle processing failure
            UPDATE integration_queue 
            SET status = CASE 
                WHEN retry_count < max_retries THEN 'retrying'
                ELSE 'failed'
            END,
            retry_count = retry_count + 1,
            error_message = SQLERRM,
            scheduled_at = CASE 
                WHEN retry_count < max_retries THEN 
                    CURRENT_TIMESTAMP + (retry_delay_seconds * INTERVAL '1 second')
                ELSE scheduled_at
            END
            WHERE id = v_record.id;
            
            v_processed_count := v_processed_count + 1;
            v_failure_count := v_failure_count + 1;
        END;
    END LOOP;
    
    RETURN QUERY SELECT v_processed_count, v_success_count, v_failure_count;
END;
$$ LANGUAGE plpgsql;

-- Function to resolve integration conflicts
CREATE OR REPLACE FUNCTION resolve_integration_conflict(
    p_conflict_id UUID,
    p_resolution_strategy VARCHAR(50),
    p_resolution_data JSONB DEFAULT NULL,
    p_resolved_by UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_conflict RECORD;
    v_success BOOLEAN := false;
BEGIN
    -- Get conflict details
    SELECT * INTO v_conflict 
    FROM integration_conflicts 
    WHERE id = p_conflict_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Apply resolution strategy
    CASE p_resolution_strategy
        WHEN 'source_wins' THEN
            -- Use source data
            UPDATE integration_conflicts 
            SET resolution_status = 'resolved',
                resolution_data = v_conflict.source_data,
                resolved_at = CURRENT_TIMESTAMP,
                resolved_by = p_resolved_by,
                auto_resolved = true
            WHERE id = p_conflict_id;
            v_success := true;
            
        WHEN 'target_wins' THEN
            -- Use target data
            UPDATE integration_conflicts 
            SET resolution_status = 'resolved',
                resolution_data = v_conflict.target_data,
                resolved_at = CURRENT_TIMESTAMP,
                resolved_by = p_resolved_by,
                auto_resolved = true
            WHERE id = p_conflict_id;
            v_success := true;
            
        WHEN 'merge' THEN
            -- Merge data (custom logic would be implemented here)
            UPDATE integration_conflicts 
            SET resolution_status = 'resolved',
                resolution_data = COALESCE(p_resolution_data, v_conflict.source_data),
                resolved_at = CURRENT_TIMESTAMP,
                resolved_by = p_resolved_by,
                auto_resolved = false
            WHERE id = p_conflict_id;
            v_success := true;
            
        WHEN 'skip' THEN
            -- Skip this conflict
            UPDATE integration_conflicts 
            SET resolution_status = 'skipped',
                resolved_at = CURRENT_TIMESTAMP,
                resolved_by = p_resolved_by,
                auto_resolved = true
            WHERE id = p_conflict_id;
            v_success := true;
            
        ELSE
            -- Manual resolution with provided data
            UPDATE integration_conflicts 
            SET resolution_status = 'resolved',
                resolution_data = p_resolution_data,
                resolved_at = CURRENT_TIMESTAMP,
                resolved_by = p_resolved_by,
                auto_resolved = false
            WHERE id = p_conflict_id;
            v_success := true;
    END CASE;
    
    RETURN v_success;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================================
-- SAMPLE DATA GENERATORS
-- ===================================================================================

-- Function to generate sample integration endpoints
CREATE OR REPLACE FUNCTION generate_sample_integration_endpoints() RETURNS INTEGER AS $$
DECLARE
    v_auth_id UUID;
    v_count INTEGER := 0;
BEGIN
    -- Create sample authentication configs
    INSERT INTO integration_auth (auth_name, auth_type, api_key_encrypted, is_active)
    VALUES ('sample_api_key', 'api_key', crypt('sample_key_123', gen_salt('bf')), true)
    RETURNING id INTO v_auth_id;
    
    -- Sample INTEGRATION-OPUS endpoint
    INSERT INTO integration_endpoints (
        name, description, endpoint_type, base_url, system_code, auth_config_id, is_active
    ) VALUES (
        'INTEGRATION-OPUS Main',
        'Main INTEGRATION-OPUS endpoint',
        'REST_API',
        'https://api.integration-opus.com/v1',
        'INTEGRATION_OPUS',
        v_auth_id,
        true
    );
    v_count := v_count + 1;
    
    -- Sample 1C ZUP endpoint
    INSERT INTO integration_endpoints (
        name, description, endpoint_type, base_url, system_code, is_active
    ) VALUES (
        '1C ZUP HR System',
        '1C ZUP integration for HR data',
        'REST_API',
        'http://1c-server:8080/hr/api',
        '1C_ZUP',
        true
    );
    v_count := v_count + 1;
    
    -- Sample telephony endpoint
    INSERT INTO integration_endpoints (
        name, description, endpoint_type, base_url, system_code, is_active
    ) VALUES (
        'Asterisk PBX',
        'Asterisk telephony system',
        'REST_API',
        'http://pbx.company.com:8088/ari',
        'TELEPHONY',
        true
    );
    v_count := v_count + 1;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample integration mappings
CREATE OR REPLACE FUNCTION generate_sample_integration_mappings() RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Employee mapping
    INSERT INTO integration_mappings (
        mapping_name, source_system, target_system, entity_type,
        source_schema, target_schema, field_mappings, is_active
    ) VALUES (
        'Employee Sync Mapping',
        '1C_ZUP',
        'WFM',
        'employee',
        '{"id": "string", "name": "string", "department": "string"}'::jsonb,
        '{"employee_id": "string", "full_name": "string", "dept_name": "string"}'::jsonb,
        '{"employee_id": "source.id", "full_name": "source.name", "dept_name": "source.department"}'::jsonb,
        true
    );
    v_count := v_count + 1;
    
    -- Schedule mapping
    INSERT INTO integration_mappings (
        mapping_name, source_system, target_system, entity_type,
        source_schema, target_schema, field_mappings, is_active
    ) VALUES (
        'Schedule Sync Mapping',
        'WFM',
        'INTEGRATION_OPUS',
        'schedule',
        '{"schedule_id": "string", "employee_id": "string", "date": "date", "hours": "number"}'::jsonb,
        '{"id": "string", "employee": "string", "work_date": "date", "duration": "number"}'::jsonb,
        '{"id": "source.schedule_id", "employee": "source.employee_id", "work_date": "source.date", "duration": "source.hours"}'::jsonb,
        true
    );
    v_count := v_count + 1;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample queue messages
CREATE OR REPLACE FUNCTION generate_sample_queue_messages() RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Employee sync message
    INSERT INTO integration_queue (
        queue_name, message_type, message_payload, source_system, priority, status
    ) VALUES (
        'employee_sync',
        'employee_update',
        '{"employee_id": "EMP001", "action": "update", "data": {"name": "John Doe", "department": "IT"}}'::jsonb,
        '1C_ZUP',
        5,
        'pending'
    );
    v_count := v_count + 1;
    
    -- Schedule sync message
    INSERT INTO integration_queue (
        queue_name, message_type, message_payload, source_system, priority, status
    ) VALUES (
        'schedule_sync',
        'schedule_create',
        '{"schedule_id": "SCH001", "employee_id": "EMP001", "date": "2024-01-15", "hours": 8}'::jsonb,
        'WFM',
        3,
        'pending'
    );
    v_count := v_count + 1;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ===================================================================================

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER tr_integration_endpoints_updated_at
    BEFORE UPDATE ON integration_endpoints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_mappings_updated_at
    BEFORE UPDATE ON integration_mappings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_sync_updated_at
    BEFORE UPDATE ON integration_sync
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_errors_updated_at
    BEFORE UPDATE ON integration_errors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_queue_updated_at
    BEFORE UPDATE ON integration_queue
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_transforms_updated_at
    BEFORE UPDATE ON integration_transforms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_schedules_updated_at
    BEFORE UPDATE ON integration_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_auth_updated_at
    BEFORE UPDATE ON integration_auth
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_integration_conflicts_updated_at
    BEFORE UPDATE ON integration_conflicts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_api_configurations_updated_at
    BEFORE UPDATE ON api_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_webhook_subscriptions_updated_at
    BEFORE UPDATE ON webhook_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================================================================
-- CLEANUP AND MAINTENANCE FUNCTIONS
-- ===================================================================================

-- Function to clean up old logs
CREATE OR REPLACE FUNCTION cleanup_integration_logs(
    p_days_to_keep INTEGER DEFAULT 30
) RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM integration_logs 
    WHERE logged_at < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired queue messages
CREATE OR REPLACE FUNCTION cleanup_expired_queue_messages() RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM integration_queue 
    WHERE expires_at IS NOT NULL 
    AND expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update endpoint health status
CREATE OR REPLACE FUNCTION update_endpoint_health_status(
    p_endpoint_id UUID,
    p_health_status VARCHAR(20)
) RETURNS VOID AS $$
BEGIN
    UPDATE integration_endpoints 
    SET health_status = p_health_status,
        last_health_check = CURRENT_TIMESTAMP
    WHERE id = p_endpoint_id;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================================
-- INITIAL SAMPLE DATA
-- ===================================================================================

-- Generate initial sample data
SELECT generate_sample_integration_endpoints() as endpoints_created;
SELECT generate_sample_integration_mappings() as mappings_created;
SELECT generate_sample_queue_messages() as messages_created;

-- Create sample 1C ZUP mapping
SELECT create_1c_zup_employee_mapping() as zup_mapping_id;

-- ===================================================================================
-- COMMENTS AND DOCUMENTATION
-- ===================================================================================

COMMENT ON SCHEMA public IS 'Integration Management Schema - External system connectivity and data integration';

COMMENT ON TABLE integration_endpoints IS 'External system endpoints configuration';
COMMENT ON TABLE integration_mappings IS 'Data mapping configurations between systems';
COMMENT ON TABLE integration_sync IS 'Synchronization tracking and status';
COMMENT ON TABLE integration_errors IS 'Error logging and handling';
COMMENT ON TABLE integration_queue IS 'Message queue for asynchronous processing';
COMMENT ON TABLE integration_transforms IS 'Data transformation rules and functions';
COMMENT ON TABLE integration_schedules IS 'Scheduled synchronization operations';
COMMENT ON TABLE integration_auth IS 'Authentication configurations';
COMMENT ON TABLE integration_logs IS 'Detailed operation logs';
COMMENT ON TABLE integration_conflicts IS 'Conflict resolution and tracking';
COMMENT ON TABLE api_configurations IS 'API endpoint configurations';
COMMENT ON TABLE webhook_subscriptions IS 'Webhook management and subscriptions';

-- ===================================================================================
-- END OF SCHEMA
-- ===================================================================================