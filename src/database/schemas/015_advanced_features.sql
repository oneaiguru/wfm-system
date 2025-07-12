-- ============================================================================
-- Advanced Features Schema - AI, Naumen Integration, and Workflow Automation
-- File: 015_advanced_features.sql
-- Version: 1.0
-- Author: Subagent 8
-- Description: Complete schema for advanced features including AI assistant,
--              Naumen integration, workflow automation, and system monitoring
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- 1. AI Configurations Table
-- ============================================================================

CREATE TABLE ai_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Configuration Identity
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    version VARCHAR(50) NOT NULL DEFAULT '1.0',
    
    -- AI Model Configuration
    model_provider VARCHAR(100) NOT NULL CHECK (model_provider IN ('openai', 'anthropic', 'azure', 'google', 'local')),
    model_name VARCHAR(255) NOT NULL,
    model_version VARCHAR(100),
    
    -- API Configuration
    api_endpoint TEXT,
    api_key_encrypted TEXT,
    api_headers JSONB DEFAULT '{}',
    
    -- Model Parameters
    temperature DECIMAL(3,2) DEFAULT 0.7 CHECK (temperature >= 0 AND temperature <= 2),
    max_tokens INTEGER DEFAULT 4000 CHECK (max_tokens > 0),
    top_p DECIMAL(3,2) DEFAULT 1.0 CHECK (top_p >= 0 AND top_p <= 1),
    frequency_penalty DECIMAL(3,2) DEFAULT 0.0 CHECK (frequency_penalty >= -2 AND frequency_penalty <= 2),
    presence_penalty DECIMAL(3,2) DEFAULT 0.0 CHECK (presence_penalty >= -2 AND presence_penalty <= 2),
    
    -- Context and Prompts
    system_prompt TEXT,
    context_window INTEGER DEFAULT 8000,
    conversation_memory INTEGER DEFAULT 10,
    
    -- Capabilities
    supports_functions BOOLEAN DEFAULT FALSE,
    supports_vision BOOLEAN DEFAULT FALSE,
    supports_streaming BOOLEAN DEFAULT TRUE,
    supports_json_mode BOOLEAN DEFAULT FALSE,
    
    -- Usage Limits
    rate_limit_requests INTEGER DEFAULT 100,
    rate_limit_period INTEGER DEFAULT 3600, -- seconds
    daily_token_limit INTEGER,
    monthly_cost_limit DECIMAL(10,2),
    
    -- Status and Metadata
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 1,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Configuration metadata
    config_metadata JSONB DEFAULT '{}',
    
    CONSTRAINT unique_default_config UNIQUE (is_default) WHERE is_default = TRUE
);

-- ============================================================================
-- 2. AI Conversations Table
-- ============================================================================

CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Conversation Identity
    conversation_id VARCHAR(255) NOT NULL,
    session_id UUID,
    thread_id VARCHAR(255),
    
    -- Participant Information
    user_id UUID REFERENCES users(id),
    ai_config_id UUID REFERENCES ai_configurations(id),
    
    -- Message Details
    message_type VARCHAR(50) NOT NULL CHECK (message_type IN ('user', 'assistant', 'system', 'function')),
    message_content TEXT NOT NULL,
    message_tokens INTEGER,
    
    -- Context and Metadata
    conversation_context JSONB DEFAULT '{}',
    message_metadata JSONB DEFAULT '{}',
    
    -- Function Calling
    function_name VARCHAR(255),
    function_arguments JSONB,
    function_result JSONB,
    
    -- Processing Information
    processing_time_ms INTEGER,
    cost_cents INTEGER,
    model_used VARCHAR(255),
    
    -- Quality Metrics
    confidence_score DECIMAL(3,2),
    sentiment_score DECIMAL(3,2),
    toxicity_score DECIMAL(3,2),
    
    -- Status and Flags
    is_flagged BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    
    -- Indexing hints
    search_vector TSVECTOR
);

-- ============================================================================
-- 3. AI Learning Data Table
-- ============================================================================

CREATE TABLE ai_learning_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Data Classification
    data_type VARCHAR(100) NOT NULL CHECK (data_type IN ('conversation', 'feedback', 'correction', 'training', 'evaluation')),
    data_source VARCHAR(100) NOT NULL CHECK (data_source IN ('user_feedback', 'system_log', 'manual_entry', 'automated_collection')),
    data_category VARCHAR(100),
    
    -- Content
    input_data JSONB NOT NULL,
    expected_output JSONB,
    actual_output JSONB,
    
    -- Quality Metrics
    quality_score DECIMAL(3,2),
    accuracy_score DECIMAL(3,2),
    relevance_score DECIMAL(3,2),
    
    -- Learning Context
    conversation_id UUID REFERENCES ai_conversations(id),
    user_id UUID REFERENCES users(id),
    ai_config_id UUID REFERENCES ai_configurations(id),
    
    -- Feedback Information
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('positive', 'negative', 'neutral', 'correction')),
    feedback_details TEXT,
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    
    -- Training Status
    is_training_ready BOOLEAN DEFAULT FALSE,
    training_weight DECIMAL(3,2) DEFAULT 1.0,
    training_priority INTEGER DEFAULT 1,
    
    -- Privacy and Compliance
    contains_pii BOOLEAN DEFAULT FALSE,
    anonymized BOOLEAN DEFAULT FALSE,
    retention_policy VARCHAR(100),
    
    -- Metadata
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Validation
    is_validated BOOLEAN DEFAULT FALSE,
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- 4. Naumen Integration Table
-- ============================================================================

CREATE TABLE naumen_integration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Integration Identity
    integration_name VARCHAR(255) NOT NULL UNIQUE,
    naumen_instance VARCHAR(255) NOT NULL,
    connection_type VARCHAR(50) NOT NULL CHECK (connection_type IN ('api', 'database', 'webhook', 'file_sync')),
    
    -- Connection Configuration
    endpoint_url TEXT NOT NULL,
    authentication_type VARCHAR(50) NOT NULL CHECK (authentication_type IN ('api_key', 'oauth2', 'basic_auth', 'certificate')),
    credentials_encrypted TEXT,
    
    -- API Configuration
    api_version VARCHAR(50),
    rate_limit_requests INTEGER DEFAULT 1000,
    rate_limit_period INTEGER DEFAULT 3600,
    timeout_seconds INTEGER DEFAULT 30,
    
    -- Data Mapping
    field_mappings JSONB DEFAULT '{}',
    data_transformations JSONB DEFAULT '{}',
    sync_configuration JSONB DEFAULT '{}',
    
    -- Synchronization Settings
    sync_enabled BOOLEAN DEFAULT TRUE,
    sync_direction VARCHAR(20) CHECK (sync_direction IN ('push', 'pull', 'bidirectional')),
    sync_frequency INTEGER DEFAULT 3600, -- seconds
    last_sync_at TIMESTAMP WITH TIME ZONE,
    next_sync_at TIMESTAMP WITH TIME ZONE,
    
    -- Error Handling
    retry_attempts INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    failure_threshold INTEGER DEFAULT 5,
    
    -- Status Monitoring
    is_active BOOLEAN DEFAULT TRUE,
    connection_status VARCHAR(50) DEFAULT 'pending',
    last_error TEXT,
    error_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    
    -- Performance Metrics
    avg_response_time_ms INTEGER,
    total_requests INTEGER DEFAULT 0,
    failed_requests INTEGER DEFAULT 0,
    
    -- Data Volume
    records_synced INTEGER DEFAULT 0,
    last_record_count INTEGER DEFAULT 0,
    data_size_bytes BIGINT DEFAULT 0,
    
    -- Audit and Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Integration metadata
    integration_metadata JSONB DEFAULT '{}',
    
    -- Webhook configuration
    webhook_secret TEXT,
    webhook_events TEXT[]
);

-- ============================================================================
-- 5. Workflow Automation Table
-- ============================================================================

CREATE TABLE workflow_automation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Workflow Identity
    workflow_name VARCHAR(255) NOT NULL UNIQUE,
    workflow_description TEXT,
    workflow_version VARCHAR(50) DEFAULT '1.0',
    
    -- Workflow Configuration
    workflow_type VARCHAR(100) NOT NULL CHECK (workflow_type IN ('scheduled', 'triggered', 'manual', 'conditional')),
    trigger_events TEXT[],
    trigger_conditions JSONB DEFAULT '{}',
    
    -- Execution Configuration
    execution_order INTEGER DEFAULT 1,
    parallel_execution BOOLEAN DEFAULT FALSE,
    max_concurrent_runs INTEGER DEFAULT 1,
    timeout_minutes INTEGER DEFAULT 60,
    
    -- Schedule Configuration
    schedule_enabled BOOLEAN DEFAULT FALSE,
    schedule_cron VARCHAR(255),
    schedule_timezone VARCHAR(100) DEFAULT 'UTC',
    next_run_at TIMESTAMP WITH TIME ZONE,
    
    -- Workflow Definition
    workflow_steps JSONB NOT NULL,
    input_schema JSONB DEFAULT '{}',
    output_schema JSONB DEFAULT '{}',
    
    -- Error Handling
    error_handling JSONB DEFAULT '{}',
    retry_policy JSONB DEFAULT '{"max_retries": 3, "retry_delay": 60}',
    failure_actions JSONB DEFAULT '{}',
    
    -- Dependencies
    depends_on UUID[],
    blocks_workflows UUID[],
    
    -- Status and Control
    is_active BOOLEAN DEFAULT TRUE,
    is_paused BOOLEAN DEFAULT FALSE,
    execution_priority INTEGER DEFAULT 1,
    
    -- Execution History
    total_executions INTEGER DEFAULT 0,
    successful_executions INTEGER DEFAULT 0,
    failed_executions INTEGER DEFAULT 0,
    last_execution_at TIMESTAMP WITH TIME ZONE,
    last_execution_status VARCHAR(50),
    last_execution_duration_ms INTEGER,
    
    -- Performance Metrics
    avg_execution_time_ms INTEGER,
    min_execution_time_ms INTEGER,
    max_execution_time_ms INTEGER,
    
    -- Notifications
    notification_settings JSONB DEFAULT '{}',
    notify_on_success BOOLEAN DEFAULT FALSE,
    notify_on_failure BOOLEAN DEFAULT TRUE,
    notification_channels TEXT[],
    
    -- Audit and Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Workflow metadata
    workflow_metadata JSONB DEFAULT '{}',
    tags TEXT[]
);

-- ============================================================================
-- 6. System Notifications Table
-- ============================================================================

CREATE TABLE system_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Notification Identity
    notification_type VARCHAR(100) NOT NULL CHECK (notification_type IN ('info', 'warning', 'error', 'success', 'alert')),
    notification_category VARCHAR(100) NOT NULL,
    notification_source VARCHAR(100) NOT NULL,
    
    -- Content
    title VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    
    -- Targeting
    target_type VARCHAR(50) NOT NULL CHECK (target_type IN ('user', 'role', 'department', 'system', 'broadcast')),
    target_id UUID,
    target_criteria JSONB DEFAULT '{}',
    
    -- Delivery Configuration
    delivery_channels TEXT[] DEFAULT '{"in_app"}',
    delivery_priority INTEGER DEFAULT 1 CHECK (delivery_priority >= 1 AND delivery_priority <= 5),
    delivery_attempts INTEGER DEFAULT 0,
    max_delivery_attempts INTEGER DEFAULT 3,
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status Tracking
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed', 'expired')),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- User Interaction
    is_read BOOLEAN DEFAULT FALSE,
    is_dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    user_action TEXT,
    user_response JSONB,
    
    -- Aggregation
    is_aggregate BOOLEAN DEFAULT FALSE,
    aggregate_count INTEGER DEFAULT 1,
    aggregate_key VARCHAR(255),
    
    -- Rich Content
    action_url TEXT,
    action_label VARCHAR(255),
    icon_name VARCHAR(100),
    color_scheme VARCHAR(50),
    
    -- Metadata
    source_reference UUID,
    correlation_id VARCHAR(255),
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Delivery tracking
    delivery_log JSONB DEFAULT '[]'
);

-- ============================================================================
-- 7. Feature Flags Table
-- ============================================================================

CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Feature Identity
    feature_key VARCHAR(255) NOT NULL UNIQUE,
    feature_name VARCHAR(255) NOT NULL,
    feature_description TEXT,
    feature_category VARCHAR(100),
    
    -- Flag Configuration
    flag_type VARCHAR(50) NOT NULL DEFAULT 'boolean' CHECK (flag_type IN ('boolean', 'string', 'number', 'json')),
    default_value JSONB NOT NULL,
    
    -- Targeting and Rollout
    is_enabled BOOLEAN DEFAULT FALSE,
    rollout_percentage DECIMAL(5,2) DEFAULT 0.0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    rollout_strategy VARCHAR(50) DEFAULT 'percentage' CHECK (rollout_strategy IN ('percentage', 'user_list', 'attribute_based', 'gradual')),
    
    -- Targeting Rules
    targeting_rules JSONB DEFAULT '[]',
    user_targeting JSONB DEFAULT '{}',
    segment_targeting JSONB DEFAULT '{}',
    
    -- Environment Configuration
    environment VARCHAR(50) NOT NULL DEFAULT 'production',
    environment_overrides JSONB DEFAULT '{}',
    
    -- Variations
    variations JSONB DEFAULT '[]',
    default_variation VARCHAR(255),
    
    -- Dependencies
    depends_on_flags UUID[],
    prerequisite_flags JSONB DEFAULT '{}',
    
    -- Lifecycle Management
    lifecycle_stage VARCHAR(50) DEFAULT 'development' CHECK (lifecycle_stage IN ('development', 'testing', 'staging', 'production', 'deprecated')),
    permanent BOOLEAN DEFAULT FALSE,
    temporary BOOLEAN DEFAULT TRUE,
    
    -- Scheduling
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    
    -- Monitoring
    usage_count INTEGER DEFAULT 0,
    evaluation_count INTEGER DEFAULT 0,
    last_evaluated_at TIMESTAMP WITH TIME ZONE,
    
    -- Alerts and Notifications
    alert_on_change BOOLEAN DEFAULT FALSE,
    notify_users TEXT[],
    
    -- Tags and Organization
    tags TEXT[],
    owner_team VARCHAR(255),
    responsible_user UUID REFERENCES users(id),
    
    -- Audit and Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    
    -- Feature metadata
    feature_metadata JSONB DEFAULT '{}',
    
    -- Change tracking
    change_log JSONB DEFAULT '[]'
);

-- ============================================================================
-- 8. System Health Table
-- ============================================================================

CREATE TABLE system_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Health Check Identity
    check_name VARCHAR(255) NOT NULL,
    check_type VARCHAR(100) NOT NULL CHECK (check_type IN ('database', 'api', 'service', 'infrastructure', 'application', 'integration')),
    check_category VARCHAR(100) NOT NULL,
    
    -- Service Information
    service_name VARCHAR(255) NOT NULL,
    service_version VARCHAR(100),
    service_endpoint TEXT,
    
    -- Health Status
    status VARCHAR(50) NOT NULL CHECK (status IN ('healthy', 'warning', 'critical', 'unknown', 'maintenance')),
    previous_status VARCHAR(50),
    status_changed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metrics
    response_time_ms INTEGER,
    cpu_usage_percent DECIMAL(5,2),
    memory_usage_percent DECIMAL(5,2),
    disk_usage_percent DECIMAL(5,2),
    
    -- Custom Metrics
    custom_metrics JSONB DEFAULT '{}',
    
    -- Thresholds
    warning_threshold JSONB DEFAULT '{}',
    critical_threshold JSONB DEFAULT '{}',
    
    -- Check Results
    check_result JSONB DEFAULT '{}',
    error_message TEXT,
    error_details JSONB,
    
    -- Timing
    check_started_at TIMESTAMP WITH TIME ZONE,
    check_completed_at TIMESTAMP WITH TIME ZONE,
    check_duration_ms INTEGER,
    
    -- Dependencies
    depends_on_services TEXT[],
    affects_services TEXT[],
    
    -- Alerting
    alert_sent BOOLEAN DEFAULT FALSE,
    alert_acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    
    -- Incident Management
    incident_id UUID,
    incident_severity VARCHAR(50),
    resolution_status VARCHAR(50),
    
    -- Metadata
    environment VARCHAR(50) NOT NULL DEFAULT 'production',
    region VARCHAR(100),
    datacenter VARCHAR(100),
    
    -- Tags and Organization
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Unique constraint for active checks
    CONSTRAINT unique_active_check UNIQUE (check_name, service_name, environment)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- AI Configurations Indexes
CREATE INDEX idx_ai_configurations_provider ON ai_configurations(model_provider);
CREATE INDEX idx_ai_configurations_active ON ai_configurations(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_ai_configurations_default ON ai_configurations(is_default) WHERE is_default = TRUE;
CREATE INDEX idx_ai_configurations_name_search ON ai_configurations USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- AI Conversations Indexes
CREATE INDEX idx_ai_conversations_user ON ai_conversations(user_id);
CREATE INDEX idx_ai_conversations_config ON ai_conversations(ai_config_id);
CREATE INDEX idx_ai_conversations_conversation_id ON ai_conversations(conversation_id);
CREATE INDEX idx_ai_conversations_created_at ON ai_conversations(created_at);
CREATE INDEX idx_ai_conversations_search ON ai_conversations USING GIN(search_vector);
CREATE INDEX idx_ai_conversations_session ON ai_conversations(session_id);

-- AI Learning Data Indexes
CREATE INDEX idx_ai_learning_data_type ON ai_learning_data(data_type);
CREATE INDEX idx_ai_learning_data_source ON ai_learning_data(data_source);
CREATE INDEX idx_ai_learning_data_conversation ON ai_learning_data(conversation_id);
CREATE INDEX idx_ai_learning_data_training_ready ON ai_learning_data(is_training_ready) WHERE is_training_ready = TRUE;
CREATE INDEX idx_ai_learning_data_quality ON ai_learning_data(quality_score);
CREATE INDEX idx_ai_learning_data_tags ON ai_learning_data USING GIN(tags);

-- Naumen Integration Indexes
CREATE INDEX idx_naumen_integration_name ON naumen_integration(integration_name);
CREATE INDEX idx_naumen_integration_instance ON naumen_integration(naumen_instance);
CREATE INDEX idx_naumen_integration_active ON naumen_integration(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_naumen_integration_sync_due ON naumen_integration(next_sync_at) WHERE sync_enabled = TRUE;
CREATE INDEX idx_naumen_integration_status ON naumen_integration(connection_status);

-- Workflow Automation Indexes
CREATE INDEX idx_workflow_automation_name ON workflow_automation(workflow_name);
CREATE INDEX idx_workflow_automation_type ON workflow_automation(workflow_type);
CREATE INDEX idx_workflow_automation_active ON workflow_automation(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_workflow_automation_scheduled ON workflow_automation(next_run_at) WHERE schedule_enabled = TRUE;
CREATE INDEX idx_workflow_automation_priority ON workflow_automation(execution_priority);
CREATE INDEX idx_workflow_automation_tags ON workflow_automation USING GIN(tags);

-- System Notifications Indexes
CREATE INDEX idx_system_notifications_type ON system_notifications(notification_type);
CREATE INDEX idx_system_notifications_category ON system_notifications(notification_category);
CREATE INDEX idx_system_notifications_target ON system_notifications(target_type, target_id);
CREATE INDEX idx_system_notifications_status ON system_notifications(status);
CREATE INDEX idx_system_notifications_scheduled ON system_notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;
CREATE INDEX idx_system_notifications_unread ON system_notifications(target_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_system_notifications_created_at ON system_notifications(created_at);

-- Feature Flags Indexes
CREATE INDEX idx_feature_flags_key ON feature_flags(feature_key);
CREATE INDEX idx_feature_flags_enabled ON feature_flags(is_enabled) WHERE is_enabled = TRUE;
CREATE INDEX idx_feature_flags_environment ON feature_flags(environment);
CREATE INDEX idx_feature_flags_category ON feature_flags(feature_category);
CREATE INDEX idx_feature_flags_lifecycle ON feature_flags(lifecycle_stage);
CREATE INDEX idx_feature_flags_tags ON feature_flags USING GIN(tags);
CREATE INDEX idx_feature_flags_owner ON feature_flags(owner_team);

-- System Health Indexes
CREATE INDEX idx_system_health_service ON system_health(service_name);
CREATE INDEX idx_system_health_check_type ON system_health(check_type);
CREATE INDEX idx_system_health_status ON system_health(status);
CREATE INDEX idx_system_health_environment ON system_health(environment);
CREATE INDEX idx_system_health_created_at ON system_health(created_at);
CREATE INDEX idx_system_health_critical ON system_health(status, created_at) WHERE status IN ('critical', 'warning');
CREATE INDEX idx_system_health_tags ON system_health USING GIN(tags);

-- ============================================================================
-- FUNCTIONS AND PROCEDURES
-- ============================================================================

-- Function to update search vector for AI conversations
CREATE OR REPLACE FUNCTION update_ai_conversation_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = to_tsvector('english', NEW.message_content);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to encrypt sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
    IF data IS NULL OR data = '' THEN
        RETURN NULL;
    END IF;
    RETURN encode(encrypt(data::bytea, 'wfm_encryption_key', 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

-- Function to decrypt sensitive data
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data TEXT)
RETURNS TEXT AS $$
BEGIN
    IF encrypted_data IS NULL OR encrypted_data = '' THEN
        RETURN NULL;
    END IF;
    RETURN convert_from(decrypt(decode(encrypted_data, 'base64'), 'wfm_encryption_key', 'aes'), 'UTF8');
END;
$$ LANGUAGE plpgsql;

-- Function to calculate next workflow run time
CREATE OR REPLACE FUNCTION calculate_next_workflow_run(cron_expression TEXT, timezone_name TEXT DEFAULT 'UTC')
RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
    next_run TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Simple cron calculation - in production, use pg_cron or similar
    -- This is a placeholder implementation
    CASE 
        WHEN cron_expression LIKE '0 * * * *' THEN
            next_run = date_trunc('hour', NOW() AT TIME ZONE timezone_name) + INTERVAL '1 hour';
        WHEN cron_expression LIKE '0 0 * * *' THEN
            next_run = date_trunc('day', NOW() AT TIME ZONE timezone_name) + INTERVAL '1 day';
        WHEN cron_expression LIKE '0 0 * * 0' THEN
            next_run = date_trunc('week', NOW() AT TIME ZONE timezone_name) + INTERVAL '1 week';
        ELSE
            next_run = NOW() + INTERVAL '1 hour';
    END CASE;
    
    RETURN next_run AT TIME ZONE timezone_name;
END;
$$ LANGUAGE plpgsql;

-- Function to evaluate feature flag
CREATE OR REPLACE FUNCTION evaluate_feature_flag(flag_key TEXT, user_id UUID DEFAULT NULL, attributes JSONB DEFAULT '{}')
RETURNS JSONB AS $$
DECLARE
    flag_record feature_flags%ROWTYPE;
    result JSONB;
    random_value DECIMAL(5,2);
BEGIN
    SELECT * INTO flag_record FROM feature_flags WHERE feature_key = flag_key AND is_enabled = TRUE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('enabled', false, 'value', null, 'reason', 'flag_not_found');
    END IF;
    
    -- Simple percentage-based evaluation
    IF flag_record.rollout_strategy = 'percentage' THEN
        random_value = random() * 100;
        IF random_value <= flag_record.rollout_percentage THEN
            result = jsonb_build_object('enabled', true, 'value', flag_record.default_value, 'reason', 'percentage_match');
        ELSE
            result = jsonb_build_object('enabled', false, 'value', null, 'reason', 'percentage_miss');
        END IF;
    ELSE
        result = jsonb_build_object('enabled', flag_record.is_enabled, 'value', flag_record.default_value, 'reason', 'default');
    END IF;
    
    -- Update usage count
    UPDATE feature_flags 
    SET usage_count = usage_count + 1, 
        evaluation_count = evaluation_count + 1, 
        last_evaluated_at = CURRENT_TIMESTAMP
    WHERE feature_key = flag_key;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to check system health status
CREATE OR REPLACE FUNCTION get_system_health_summary()
RETURNS JSONB AS $$
DECLARE
    health_summary JSONB;
    total_checks INTEGER;
    healthy_checks INTEGER;
    warning_checks INTEGER;
    critical_checks INTEGER;
BEGIN
    SELECT 
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'healthy') as healthy,
        COUNT(*) FILTER (WHERE status = 'warning') as warning,
        COUNT(*) FILTER (WHERE status = 'critical') as critical
    INTO total_checks, healthy_checks, warning_checks, critical_checks
    FROM system_health
    WHERE created_at > NOW() - INTERVAL '1 hour';
    
    health_summary = jsonb_build_object(
        'total_checks', total_checks,
        'healthy_checks', healthy_checks,
        'warning_checks', warning_checks,
        'critical_checks', critical_checks,
        'overall_status', 
        CASE 
            WHEN critical_checks > 0 THEN 'critical'
            WHEN warning_checks > 0 THEN 'warning'
            ELSE 'healthy'
        END,
        'last_updated', CURRENT_TIMESTAMP
    );
    
    RETURN health_summary;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger for AI conversation search vector
CREATE TRIGGER trigger_ai_conversation_search_vector
    BEFORE INSERT OR UPDATE ON ai_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_conversation_search_vector();

-- Trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER trigger_ai_configurations_updated_at
    BEFORE UPDATE ON ai_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_ai_learning_data_updated_at
    BEFORE UPDATE ON ai_learning_data
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_naumen_integration_updated_at
    BEFORE UPDATE ON naumen_integration
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_workflow_automation_updated_at
    BEFORE UPDATE ON workflow_automation
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_system_notifications_updated_at
    BEFORE UPDATE ON system_notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_feature_flags_updated_at
    BEFORE UPDATE ON feature_flags
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_system_health_updated_at
    BEFORE UPDATE ON system_health
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

-- ============================================================================
-- SAMPLE DATA GENERATORS
-- ============================================================================

-- Function to generate sample AI configuration
CREATE OR REPLACE FUNCTION generate_sample_ai_config(config_name TEXT DEFAULT 'sample_config')
RETURNS UUID AS $$
DECLARE
    config_id UUID;
BEGIN
    INSERT INTO ai_configurations (
        name, description, model_provider, model_name, model_version,
        temperature, max_tokens, system_prompt, is_active, is_default,
        created_by
    ) VALUES (
        config_name,
        'Sample AI configuration for testing',
        'openai',
        'gpt-4',
        '0613',
        0.7,
        4000,
        'You are a helpful AI assistant for workforce management.',
        TRUE,
        FALSE,
        (SELECT id FROM users LIMIT 1)
    ) RETURNING id INTO config_id;
    
    RETURN config_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample workflow
CREATE OR REPLACE FUNCTION generate_sample_workflow(workflow_name TEXT DEFAULT 'sample_workflow')
RETURNS UUID AS $$
DECLARE
    workflow_id UUID;
BEGIN
    INSERT INTO workflow_automation (
        workflow_name, workflow_description, workflow_type, 
        workflow_steps, is_active, created_by
    ) VALUES (
        workflow_name,
        'Sample workflow for testing automation',
        'scheduled',
        '[
            {"step": 1, "action": "fetch_data", "parameters": {"source": "database"}},
            {"step": 2, "action": "process_data", "parameters": {"method": "transform"}},
            {"step": 3, "action": "send_notification", "parameters": {"channel": "email"}}
        ]'::JSONB,
        TRUE,
        (SELECT id FROM users LIMIT 1)
    ) RETURNING id INTO workflow_id;
    
    RETURN workflow_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample feature flag
CREATE OR REPLACE FUNCTION generate_sample_feature_flag(flag_key TEXT DEFAULT 'sample_feature')
RETURNS UUID AS $$
DECLARE
    flag_id UUID;
BEGIN
    INSERT INTO feature_flags (
        feature_key, feature_name, feature_description, 
        flag_type, default_value, is_enabled, rollout_percentage,
        created_by
    ) VALUES (
        flag_key,
        'Sample Feature Flag',
        'Sample feature flag for testing',
        'boolean',
        'true'::JSONB,
        TRUE,
        50.0,
        (SELECT id FROM users LIMIT 1)
    ) RETURNING id INTO flag_id;
    
    RETURN flag_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample system health check
CREATE OR REPLACE FUNCTION generate_sample_health_check()
RETURNS UUID AS $$
DECLARE
    health_id UUID;
BEGIN
    INSERT INTO system_health (
        check_name, check_type, check_category, service_name,
        status, response_time_ms, cpu_usage_percent, memory_usage_percent,
        check_result, check_started_at, check_completed_at
    ) VALUES (
        'Database Connection Check',
        'database',
        'infrastructure',
        'postgresql',
        'healthy',
        15,
        25.5,
        45.2,
        '{"connection": "successful", "query_time": 15}'::JSONB,
        CURRENT_TIMESTAMP - INTERVAL '1 minute',
        CURRENT_TIMESTAMP
    ) RETURNING id INTO health_id;
    
    RETURN health_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- AI Configuration Summary View
CREATE VIEW ai_config_summary AS
SELECT 
    model_provider,
    COUNT(*) as total_configs,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_configs,
    AVG(temperature) as avg_temperature,
    AVG(max_tokens) as avg_max_tokens
FROM ai_configurations
GROUP BY model_provider;

-- Workflow Automation Status View
CREATE VIEW workflow_status_summary AS
SELECT 
    workflow_type,
    COUNT(*) as total_workflows,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_workflows,
    COUNT(*) FILTER (WHERE is_paused = TRUE) as paused_workflows,
    AVG(successful_executions::decimal / NULLIF(total_executions, 0)) * 100 as success_rate
FROM workflow_automation
GROUP BY workflow_type;

-- System Health Dashboard View
CREATE VIEW system_health_dashboard AS
SELECT 
    service_name,
    check_type,
    status,
    response_time_ms,
    cpu_usage_percent,
    memory_usage_percent,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY service_name ORDER BY created_at DESC) as rn
FROM system_health
WHERE created_at > NOW() - INTERVAL '1 hour';

-- Feature Flag Usage View
CREATE VIEW feature_flag_usage AS
SELECT 
    feature_key,
    feature_name,
    is_enabled,
    rollout_percentage,
    usage_count,
    evaluation_count,
    last_evaluated_at,
    CASE 
        WHEN usage_count = 0 THEN 'unused'
        WHEN usage_count < 10 THEN 'low_usage'
        WHEN usage_count < 100 THEN 'medium_usage'
        ELSE 'high_usage'
    END as usage_category
FROM feature_flags
WHERE created_at > NOW() - INTERVAL '30 days';

-- ============================================================================
-- PERFORMANCE MONITORING
-- ============================================================================

-- Create materialized view for performance metrics
CREATE MATERIALIZED VIEW ai_performance_metrics AS
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    ai_config_id,
    COUNT(*) as total_conversations,
    AVG(message_tokens) as avg_tokens,
    AVG(processing_time_ms) as avg_processing_time,
    SUM(cost_cents) as total_cost_cents,
    COUNT(*) FILTER (WHERE is_flagged = TRUE) as flagged_count
FROM ai_conversations
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', created_at), ai_config_id;

-- Create index on materialized view
CREATE INDEX idx_ai_performance_metrics_hour ON ai_performance_metrics(hour);

-- Function to refresh performance metrics
CREATE OR REPLACE FUNCTION refresh_ai_performance_metrics()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW ai_performance_metrics;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE ai_configurations IS 'Configuration settings for AI models and assistants';
COMMENT ON TABLE ai_conversations IS 'Chat history and conversation context for AI interactions';
COMMENT ON TABLE ai_learning_data IS 'Machine learning training data and user feedback';
COMMENT ON TABLE naumen_integration IS 'Integration configuration and status for Naumen systems';
COMMENT ON TABLE workflow_automation IS 'Automated workflow definitions and execution tracking';
COMMENT ON TABLE system_notifications IS 'System-wide notifications and user alerts';
COMMENT ON TABLE feature_flags IS 'Feature toggle management and rollout control';
COMMENT ON TABLE system_health IS 'System health monitoring and status tracking';

-- ============================================================================
-- SECURITY POLICIES (Row Level Security)
-- ============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE ai_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_learning_data ENABLE ROW LEVEL SECURITY;

-- Policy for AI configurations - users can only see active configs
CREATE POLICY ai_config_user_policy ON ai_configurations
    FOR SELECT
    TO authenticated_users
    USING (is_active = TRUE);

-- Policy for AI conversations - users can only see their own conversations
CREATE POLICY ai_conversation_user_policy ON ai_conversations
    FOR ALL
    TO authenticated_users
    USING (user_id = current_user_id());

-- Policy for AI learning data - users can only see their own data
CREATE POLICY ai_learning_data_user_policy ON ai_learning_data
    FOR ALL
    TO authenticated_users
    USING (user_id = current_user_id());

-- ============================================================================
-- MAINTENANCE PROCEDURES
-- ============================================================================

-- Procedure to cleanup old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS VOID AS $$
BEGIN
    -- Clean up old conversations (older than 6 months)
    DELETE FROM ai_conversations 
    WHERE created_at < NOW() - INTERVAL '6 months' 
    AND is_archived = FALSE;
    
    -- Clean up old system health records (older than 30 days)
    DELETE FROM system_health 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Clean up old notifications (older than 90 days)
    DELETE FROM system_notifications 
    WHERE created_at < NOW() - INTERVAL '90 days' 
    AND (status = 'delivered' OR status = 'read');
    
    -- Archive old learning data
    UPDATE ai_learning_data 
    SET metadata = metadata || '{"archived": true}'::jsonb
    WHERE created_at < NOW() - INTERVAL '1 year' 
    AND is_training_ready = FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Create default AI configuration
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get admin user ID
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@wfm.com' LIMIT 1;
    
    -- Create default AI configuration if admin user exists
    IF admin_user_id IS NOT NULL THEN
        INSERT INTO ai_configurations (
            name, description, model_provider, model_name, 
            system_prompt, is_active, is_default, created_by
        ) VALUES (
            'default_assistant',
            'Default AI assistant for WFM system',
            'openai',
            'gpt-4',
            'You are a helpful AI assistant for workforce management. You help users with scheduling, planning, and operational tasks.',
            TRUE,
            TRUE,
            admin_user_id
        ) ON CONFLICT (name) DO NOTHING;
    END IF;
END $$;

-- ============================================================================
-- FINAL VALIDATION
-- ============================================================================

-- Validate schema creation
DO $$
DECLARE
    table_count INTEGER;
    index_count INTEGER;
    function_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name IN (
        'ai_configurations', 'ai_conversations', 'ai_learning_data', 
        'naumen_integration', 'workflow_automation', 'system_notifications',
        'feature_flags', 'system_health'
    );
    
    SELECT COUNT(*) INTO index_count FROM pg_indexes 
    WHERE schemaname = 'public' AND tablename IN (
        'ai_configurations', 'ai_conversations', 'ai_learning_data', 
        'naumen_integration', 'workflow_automation', 'system_notifications',
        'feature_flags', 'system_health'
    );
    
    SELECT COUNT(*) INTO function_count FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name IN (
        'update_ai_conversation_search_vector', 'encrypt_sensitive_data',
        'decrypt_sensitive_data', 'evaluate_feature_flag', 'get_system_health_summary'
    );
    
    RAISE NOTICE 'Schema validation complete:';
    RAISE NOTICE 'Tables created: %', table_count;
    RAISE NOTICE 'Indexes created: %', index_count;
    RAISE NOTICE 'Functions created: %', function_count;
    
    IF table_count = 8 THEN
        RAISE NOTICE 'SUCCESS: All 8 tables created successfully';
    ELSE
        RAISE EXCEPTION 'FAILED: Expected 8 tables, found %', table_count;
    END IF;
END $$;

-- ============================================================================
-- END OF ADVANCED FEATURES SCHEMA
-- ============================================================================