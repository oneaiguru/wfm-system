-- =============================================================================
-- 080_enterprise_integration_apis.sql
-- Enterprise Integration APIs Database Schema (Tasks 71-75)
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-14
-- Purpose: Database schemas for Tasks 71-75 Enterprise Integration APIs
-- APIs: Webhooks, SSO, External Systems, Data Transform, Compliance Audit
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TASK 71: WEBHOOK REGISTRATION AND MANAGEMENT
-- =============================================================================

-- Webhook registrations table
CREATE TABLE webhook_registrations (
    webhook_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    endpoint_url VARCHAR(1000) NOT NULL,
    secret_token VARCHAR(500) NOT NULL, -- Encrypted webhook secret
    active BOOLEAN DEFAULT true,
    
    -- Retry and delivery configuration
    retry_policy VARCHAR(20) NOT NULL CHECK (retry_policy IN ('exponential', 'linear', 'fixed')),
    max_retries INTEGER DEFAULT 5 CHECK (max_retries BETWEEN 1 AND 10),
    timeout_seconds INTEGER DEFAULT 30 CHECK (timeout_seconds BETWEEN 5 AND 300),
    rate_limit_per_minute INTEGER DEFAULT 100,
    
    -- Request configuration
    headers JSONB DEFAULT '{}',
    
    -- Monitoring and metrics
    total_deliveries BIGINT DEFAULT 0,
    successful_deliveries BIGINT DEFAULT 0,
    failed_deliveries BIGINT DEFAULT 0,
    last_delivery_at TIMESTAMPTZ,
    last_success_at TIMESTAMPTZ,
    last_failure_at TIMESTAMPTZ,
    
    -- Audit fields
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    CONSTRAINT webhook_name_unique UNIQUE (name, created_by)
);

-- Event subscriptions for webhooks
CREATE TABLE event_subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL REFERENCES webhook_registrations(webhook_id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    active BOOLEAN DEFAULT true,
    
    -- Event filtering
    filter_conditions JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT event_subscription_unique UNIQUE (webhook_id, event_type)
);

-- Webhook delivery logs
CREATE TABLE delivery_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL REFERENCES webhook_registrations(webhook_id),
    event_type VARCHAR(100) NOT NULL,
    
    -- Delivery details
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'success', 'failed', 'retrying')),
    http_status_code INTEGER,
    response_body TEXT,
    error_message TEXT,
    
    -- Timing
    attempt_number INTEGER DEFAULT 1,
    delivery_duration_ms INTEGER,
    next_retry_at TIMESTAMPTZ,
    
    -- Payload
    payload JSONB,
    headers_sent JSONB,
    
    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    archived BOOLEAN DEFAULT false,
    
    -- Indexes for performance
    CONSTRAINT delivery_logs_webhook_date_idx UNIQUE (webhook_id, created_at, log_id)
) PARTITION BY RANGE (created_at);

-- Create partitions for delivery logs (monthly)
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
    month_offset INTEGER;
BEGIN
    FOR month_offset IN 0..12 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'delivery_logs_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE %I PARTITION OF delivery_logs 
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, start_date, end_date);
        
        start_date := end_date;
    END LOOP;
END $$;

-- =============================================================================
-- TASK 72: SSO AUTHENTICATION SYSTEM (Enhanced)
-- =============================================================================

-- Identity mappings for SSO users
CREATE TABLE identity_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL, -- Reference to users table
    external_id VARCHAR(500) NOT NULL, -- External system user ID
    
    -- User attributes from external system
    external_attributes JSONB DEFAULT '{}',
    
    -- Login tracking
    first_login_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    login_count INTEGER DEFAULT 1,
    
    -- Status
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT identity_mapping_unique UNIQUE (provider_id, external_id),
    CONSTRAINT identity_user_provider_unique UNIQUE (user_id, provider_id)
);

-- Authentication sessions
CREATE TABLE authentication_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    provider_id VARCHAR(100),
    
    -- Session data
    session_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    logged_out_at TIMESTAMPTZ,
    
    -- Status
    active BOOLEAN DEFAULT true,
    
    -- Security
    session_hash VARCHAR(64), -- For session invalidation
    
    -- Constraints
    CONSTRAINT session_expires_check CHECK (expires_at > created_at)
);

-- =============================================================================
-- TASK 73: EXTERNAL SYSTEMS MANAGEMENT (Enhanced)
-- =============================================================================

-- Enhanced external systems table
CREATE TABLE IF NOT EXISTS external_systems (
    system_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    system_type VARCHAR(50) NOT NULL CHECK (system_type IN (
        'hr_system', 'contact_center', 'chat_platform', 'erp', 
        'crm', 'telephony', 'reporting', 'custom'
    )),
    description TEXT,
    
    -- Connection configuration
    base_url VARCHAR(1000) NOT NULL,
    api_version VARCHAR(50) DEFAULT 'unknown',
    authentication JSONB, -- Encrypted authentication details
    
    -- Capabilities and features
    capabilities JSONB DEFAULT '[]',
    supported_operations JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    
    -- Health monitoring
    health_check_endpoint VARCHAR(500) DEFAULT '/health',
    timeout_seconds INTEGER DEFAULT 30,
    current_status VARCHAR(20) DEFAULT 'unknown' CHECK (current_status IN (
        'connected', 'disconnected', 'degraded', 'unknown'
    )),
    last_health_check TIMESTAMPTZ,
    last_response_time_ms INTEGER,
    health_details JSONB DEFAULT '{}',
    
    -- Connection pooling
    connection_pool_size INTEGER DEFAULT 10,
    active_connections INTEGER DEFAULT 0,
    max_concurrent_requests INTEGER DEFAULT 100,
    rate_limit_per_minute INTEGER,
    
    -- Monitoring metrics
    total_requests_24h INTEGER DEFAULT 0,
    failed_requests_24h INTEGER DEFAULT 0,
    average_response_time_ms INTEGER DEFAULT 0,
    uptime_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Audit
    active BOOLEAN DEFAULT true,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT external_system_name_unique UNIQUE (name)
);

-- System health monitoring logs
CREATE TABLE system_health_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_systems(system_id),
    
    -- Health check results
    check_time TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) NOT NULL CHECK (status IN ('connected', 'disconnected', 'degraded', 'unknown')),
    response_time_ms INTEGER,
    error_message TEXT,
    details JSONB DEFAULT '{}',
    
    -- Audit
    archived BOOLEAN DEFAULT false
) PARTITION BY RANGE (check_time);

-- Create partitions for health logs (monthly)
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
    month_offset INTEGER;
BEGIN
    FOR month_offset IN 0..12 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'system_health_logs_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE %I PARTITION OF system_health_logs 
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, start_date, end_date);
        
        start_date := end_date;
    END LOOP;
END $$;

-- Integration configurations
CREATE TABLE integration_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_systems(system_id),
    config_name VARCHAR(200) NOT NULL,
    config_type VARCHAR(100) NOT NULL,
    
    -- Configuration data
    configuration JSONB NOT NULL DEFAULT '{}',
    
    -- Validation and schema
    config_schema JSONB,
    validation_rules JSONB DEFAULT '[]',
    
    -- Status
    active BOOLEAN DEFAULT true,
    last_validated_at TIMESTAMPTZ,
    validation_errors JSONB,
    
    -- Audit
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT integration_config_unique UNIQUE (system_id, config_name)
);

-- API endpoint mappings
CREATE TABLE api_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES external_systems(system_id),
    
    -- Endpoint mapping
    local_endpoint VARCHAR(500) NOT NULL,
    remote_endpoint VARCHAR(500) NOT NULL,
    method VARCHAR(10) NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
    
    -- Data transformation
    request_transform JSONB, -- Request transformation rules
    response_transform JSONB, -- Response transformation rules
    
    -- Caching and performance
    cache_ttl_seconds INTEGER DEFAULT 0,
    rate_limit_per_minute INTEGER,
    timeout_seconds INTEGER DEFAULT 30,
    
    -- Status and monitoring
    active BOOLEAN DEFAULT true,
    total_requests BIGINT DEFAULT 0,
    failed_requests BIGINT DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    average_response_time_ms INTEGER DEFAULT 0,
    
    -- Audit
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT api_mapping_unique UNIQUE (system_id, local_endpoint, method)
);

-- =============================================================================
-- TASK 74: DATA TRANSFORMATION ENGINE
-- =============================================================================

-- Transformation rules
CREATE TABLE transformation_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Transformation configuration
    transformation_type VARCHAR(50) NOT NULL CHECK (transformation_type IN (
        'etl', 'field_mapping', 'format_conversion', 'data_validation', 
        'aggregation', 'enrichment'
    )),
    source_format VARCHAR(50) NOT NULL CHECK (source_format IN (
        'json', 'xml', 'csv', 'excel', 'fixed_width', 'delimited', 
        'argus_format', 'wfm_standard'
    )),
    target_format VARCHAR(50) NOT NULL CHECK (target_format IN (
        'json', 'xml', 'csv', 'excel', 'fixed_width', 'delimited', 
        'argus_format', 'wfm_standard'
    )),
    
    -- Transformation logic
    field_mappings JSONB NOT NULL DEFAULT '[]',
    validation_rules JSONB DEFAULT '[]',
    transformation_logic JSONB DEFAULT '{}',
    
    -- Performance settings
    batch_size INTEGER DEFAULT 1000,
    parallel_processing BOOLEAN DEFAULT false,
    timeout_seconds INTEGER DEFAULT 300,
    
    -- Quality metrics
    success_rate DECIMAL(5,2) DEFAULT 0.0,
    average_execution_time_ms INTEGER DEFAULT 0,
    total_executions BIGINT DEFAULT 0,
    
    -- Status
    active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ,
    
    -- Audit
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT transformation_rule_name_unique UNIQUE (rule_name, created_by)
);

-- Field mappings (detailed configuration)
CREATE TABLE field_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES transformation_rules(rule_id) ON DELETE CASCADE,
    
    -- Field mapping details
    source_field VARCHAR(200) NOT NULL,
    target_field VARCHAR(200) NOT NULL,
    transformation_function VARCHAR(100),
    transformation_params JSONB DEFAULT '{}',
    default_value TEXT,
    
    -- Validation
    validation_rules JSONB DEFAULT '[]',
    required BOOLEAN DEFAULT false,
    
    -- Status
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT field_mapping_unique UNIQUE (rule_id, source_field, target_field)
);

-- Data format specifications
CREATE TABLE data_formats (
    format_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    format_name VARCHAR(100) NOT NULL UNIQUE,
    format_type VARCHAR(50) NOT NULL,
    
    -- Format specification
    schema_definition JSONB NOT NULL,
    sample_data TEXT,
    validation_schema JSONB,
    
    -- Metadata
    description TEXT,
    version VARCHAR(20) DEFAULT '1.0',
    
    -- Status
    active BOOLEAN DEFAULT true,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transformation execution logs
CREATE TABLE transformation_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transformation_id UUID NOT NULL, -- From API request
    transformation_name VARCHAR(200),
    
    -- System context
    source_system_id UUID,
    target_system_id UUID,
    
    -- Transformation details
    transformation_type VARCHAR(50) NOT NULL,
    source_format VARCHAR(50) NOT NULL,
    target_format VARCHAR(50) NOT NULL,
    
    -- Execution metrics
    records_processed INTEGER DEFAULT 0,
    records_successful INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    execution_time_ms INTEGER DEFAULT 0,
    
    -- Results and errors
    validation_errors JSONB,
    transformation_summary JSONB,
    error_message TEXT,
    
    -- Audit
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT transformation_logs_check CHECK (records_processed >= 0)
) PARTITION BY RANGE (created_at);

-- Create partitions for transformation logs (monthly)
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
    month_offset INTEGER;
BEGIN
    FOR month_offset IN 0..12 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'transformation_logs_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE %I PARTITION OF transformation_logs 
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, start_date, end_date);
        
        start_date := end_date;
    END LOOP;
END $$;

-- =============================================================================
-- TASK 75: COMPLIANCE AND AUDIT SYSTEM
-- =============================================================================

-- Comprehensive audit events
CREATE TABLE audit_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Event classification
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'data_access', 'data_modification', 'data_export', 'data_deletion',
        'system_integration', 'user_authentication', 'permission_change',
        'configuration_change', 'compliance_violation'
    )),
    event_description TEXT NOT NULL,
    
    -- Context
    user_id VARCHAR(100),
    system_id UUID,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(200) NOT NULL,
    action_performed VARCHAR(200) NOT NULL,
    
    -- Data changes
    data_before JSONB,
    data_after JSONB,
    
    -- Network context
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    
    -- Compliance classification
    severity_level VARCHAR(20) NOT NULL CHECK (severity_level IN (
        'critical', 'high', 'medium', 'low', 'info'
    )),
    compliance_impact JSONB DEFAULT '[]', -- Array of compliance standards affected
    data_classification VARCHAR(20) NOT NULL CHECK (data_classification IN (
        'public', 'internal', 'confidential', 'restricted', 'pii', 'financial'
    )),
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    -- Audit trail integrity
    event_hash VARCHAR(64), -- For tamper detection
    previous_event_hash VARCHAR(64),
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Archival
    archived BOOLEAN DEFAULT false,
    archived_at TIMESTAMPTZ
) PARTITION BY RANGE (created_at);

-- Create partitions for audit events (monthly)
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
    month_offset INTEGER;
BEGIN
    FOR month_offset IN 0..12 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'audit_events_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE %I PARTITION OF audit_events 
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, start_date, end_date);
        
        start_date := end_date;
    END LOOP;
END $$;

-- Compliance reports
CREATE TABLE compliance_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_type VARCHAR(100) NOT NULL,
    compliance_standard VARCHAR(50) NOT NULL CHECK (compliance_standard IN (
        'gdpr', 'sox', 'hipaa', 'pci_dss', 'iso_27001', 
        'russian_labor_law', 'data_protection', 'financial_services'
    )),
    
    -- Evaluation period
    evaluation_start TIMESTAMPTZ NOT NULL,
    evaluation_end TIMESTAMPTZ NOT NULL,
    
    -- Results
    overall_status VARCHAR(30) NOT NULL CHECK (overall_status IN (
        'compliant', 'non_compliant', 'pending_review', 'remediation_required', 'exempt'
    )),
    compliance_score DECIMAL(5,2) CHECK (compliance_score BETWEEN 0 AND 100),
    violations_count INTEGER DEFAULT 0,
    critical_violations INTEGER DEFAULT 0,
    
    -- Report content
    recommendations JSONB DEFAULT '[]',
    controls_assessed JSONB DEFAULT '[]',
    data_lineage_summary JSONB DEFAULT '{}',
    executive_summary TEXT,
    
    -- Report metadata
    report_format VARCHAR(20) DEFAULT 'json',
    report_data JSONB,
    report_file_path VARCHAR(1000),
    
    -- Audit
    generated_by VARCHAR(100) NOT NULL,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    approved_by VARCHAR(100),
    approved_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT compliance_report_dates_check CHECK (evaluation_end > evaluation_start)
);

-- Data lineage tracking
CREATE TABLE data_lineage_tracking (
    lineage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Data element identification
    data_element VARCHAR(500) NOT NULL,
    source_system VARCHAR(200),
    target_system VARCHAR(200),
    source_resource_type VARCHAR(100),
    source_resource_id VARCHAR(200),
    target_resource_type VARCHAR(100),
    target_resource_id VARCHAR(200),
    
    -- Transformation details
    transformation_type VARCHAR(100),
    transformation_steps JSONB DEFAULT '[]',
    
    -- Data governance
    data_classification VARCHAR(20) NOT NULL CHECK (data_classification IN (
        'public', 'internal', 'confidential', 'restricted', 'pii', 'financial'
    )),
    retention_policy JSONB DEFAULT '{}',
    access_controls JSONB DEFAULT '[]',
    compliance_tags JSONB DEFAULT '[]',
    
    -- Quality metrics
    data_quality_score DECIMAL(5,2),
    completeness_percentage DECIMAL(5,2),
    accuracy_percentage DECIMAL(5,2),
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed TIMESTAMPTZ,
    
    -- Status
    active BOOLEAN DEFAULT true
);

-- Privacy controls
CREATE TABLE privacy_controls (
    control_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    control_name VARCHAR(200) NOT NULL,
    control_type VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Compliance mapping
    applicable_standards JSONB NOT NULL DEFAULT '[]', -- Array of compliance standards
    control_category VARCHAR(100),
    control_objective TEXT,
    
    -- Implementation
    implementation_status VARCHAR(50) NOT NULL CHECK (implementation_status IN (
        'not_implemented', 'partially_implemented', 'fully_implemented', 'under_review'
    )),
    implementation_details JSONB DEFAULT '{}',
    
    -- Effectiveness assessment
    effectiveness_rating DECIMAL(5,2) CHECK (effectiveness_rating BETWEEN 0 AND 100),
    last_assessment TIMESTAMPTZ,
    next_review_date DATE,
    assessment_notes TEXT,
    
    -- Risk and impact
    risk_level VARCHAR(20) CHECK (risk_level IN ('critical', 'high', 'medium', 'low')),
    business_impact VARCHAR(20) CHECK (business_impact IN ('critical', 'high', 'medium', 'low')),
    
    -- Ownership and responsibility
    control_owner VARCHAR(100),
    responsible_party VARCHAR(100),
    
    -- Status
    active BOOLEAN DEFAULT true,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT privacy_control_name_unique UNIQUE (control_name)
);

-- Regulatory tracking
CREATE TABLE regulatory_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    regulation_name VARCHAR(200) NOT NULL,
    regulation_type VARCHAR(100) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    
    -- Regulation details
    effective_date DATE,
    compliance_deadline DATE,
    regulation_summary TEXT,
    requirements JSONB DEFAULT '[]',
    
    -- Implementation tracking
    implementation_status VARCHAR(50) NOT NULL CHECK (implementation_status IN (
        'not_started', 'in_progress', 'completed', 'non_applicable'
    )),
    implementation_progress DECIMAL(5,2) DEFAULT 0.0,
    implementation_notes TEXT,
    
    -- Impact assessment
    business_impact_assessment TEXT,
    technical_impact_assessment TEXT,
    cost_estimate DECIMAL(15,2),
    
    -- Responsibility
    responsible_team VARCHAR(100),
    project_manager VARCHAR(100),
    legal_contact VARCHAR(100),
    
    -- Status
    active BOOLEAN DEFAULT true,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT regulatory_tracking_unique UNIQUE (regulation_name, jurisdiction)
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================

-- Webhook performance indexes
CREATE INDEX idx_webhook_registrations_active ON webhook_registrations(active, created_by);
CREATE INDEX idx_event_subscriptions_webhook ON event_subscriptions(webhook_id, active);
CREATE INDEX idx_delivery_logs_webhook_status ON delivery_logs(webhook_id, status, created_at);
CREATE INDEX idx_delivery_logs_retry ON delivery_logs(next_retry_at) WHERE status = 'retrying';

-- SSO performance indexes
CREATE INDEX idx_identity_mappings_provider_external ON identity_mappings(provider_id, external_id);
CREATE INDEX idx_identity_mappings_user ON identity_mappings(user_id, active);
CREATE INDEX idx_authentication_sessions_active ON authentication_sessions(active, expires_at);
CREATE INDEX idx_authentication_sessions_user ON authentication_sessions(user_id, active);

-- External systems performance indexes
CREATE INDEX idx_external_systems_type_status ON external_systems(system_type, current_status, active);
CREATE INDEX idx_system_health_logs_system_time ON system_health_logs(system_id, check_time);
CREATE INDEX idx_integration_configs_system ON integration_configs(system_id, active);
CREATE INDEX idx_api_mappings_system_endpoint ON api_mappings(system_id, local_endpoint, active);

-- Data transformation performance indexes
CREATE INDEX idx_transformation_rules_type_format ON transformation_rules(transformation_type, source_format, target_format, active);
CREATE INDEX idx_field_mappings_rule ON field_mappings(rule_id, active);
CREATE INDEX idx_transformation_logs_user_time ON transformation_logs(created_by, created_at);
CREATE INDEX idx_transformation_logs_system ON transformation_logs(source_system_id, target_system_id);

-- Compliance and audit performance indexes
CREATE INDEX idx_audit_events_user_time ON audit_events(user_id, created_at);
CREATE INDEX idx_audit_events_resource ON audit_events(resource_type, resource_id, created_at);
CREATE INDEX idx_audit_events_severity ON audit_events(severity_level, created_at);
CREATE INDEX idx_audit_events_compliance ON audit_events USING GIN(compliance_impact);
CREATE INDEX idx_compliance_reports_standard_time ON compliance_reports(compliance_standard, generated_at);
CREATE INDEX idx_data_lineage_tracking_source ON data_lineage_tracking(source_resource_type, source_resource_id);
CREATE INDEX idx_data_lineage_tracking_target ON data_lineage_tracking(target_resource_type, target_resource_id);
CREATE INDEX idx_privacy_controls_standards ON privacy_controls USING GIN(applicable_standards);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function to update webhook metrics
CREATE OR REPLACE FUNCTION update_webhook_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'success' THEN
        UPDATE webhook_registrations 
        SET successful_deliveries = successful_deliveries + 1,
            total_deliveries = total_deliveries + 1,
            last_delivery_at = NEW.created_at,
            last_success_at = NEW.created_at
        WHERE webhook_id = NEW.webhook_id;
    ELSIF NEW.status = 'failed' THEN
        UPDATE webhook_registrations 
        SET failed_deliveries = failed_deliveries + 1,
            total_deliveries = total_deliveries + 1,
            last_delivery_at = NEW.created_at,
            last_failure_at = NEW.created_at
        WHERE webhook_id = NEW.webhook_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for webhook metrics
CREATE TRIGGER trigger_update_webhook_metrics
    AFTER INSERT ON delivery_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_webhook_metrics();

-- Function to generate audit event hash for integrity
CREATE OR REPLACE FUNCTION generate_audit_event_hash()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate hash for tamper detection
    NEW.event_hash := encode(
        digest(
            CONCAT(
                NEW.event_type, NEW.user_id, NEW.resource_type, 
                NEW.resource_id, NEW.action_performed, NEW.created_at
            ), 
            'sha256'
        ), 
        'hex'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for audit event integrity
CREATE TRIGGER trigger_generate_audit_event_hash
    BEFORE INSERT ON audit_events
    FOR EACH ROW
    EXECUTE FUNCTION generate_audit_event_hash();

-- Function to update transformation rule metrics
CREATE OR REPLACE FUNCTION update_transformation_rule_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update rule metrics if rule_id is available in transformation_logs
    -- This would be enhanced with proper rule tracking
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INITIAL DATA AND CONFIGURATIONS
-- =============================================================================

-- Insert default privacy controls
INSERT INTO privacy_controls (
    control_id, control_name, control_type, description, applicable_standards,
    implementation_status, effectiveness_rating, last_assessment, next_review_date,
    control_owner, active, created_by
) VALUES 
(
    uuid_generate_v4(),
    'Data Encryption at Rest',
    'technical',
    'All sensitive data must be encrypted when stored in databases',
    '["gdpr", "pci_dss", "data_protection"]',
    'fully_implemented',
    95.0,
    NOW(),
    CURRENT_DATE + INTERVAL '1 year',
    'security_team',
    true,
    'system'
),
(
    uuid_generate_v4(),
    'Access Control Matrix',
    'administrative',
    'Role-based access controls for all system resources',
    '["gdpr", "sox", "data_protection"]',
    'fully_implemented',
    90.0,
    NOW(),
    CURRENT_DATE + INTERVAL '6 months',
    'security_team',
    true,
    'system'
),
(
    uuid_generate_v4(),
    'Audit Logging',
    'technical',
    'Comprehensive logging of all data access and modifications',
    '["gdpr", "sox", "hipaa", "data_protection"]',
    'fully_implemented',
    98.0,
    NOW(),
    CURRENT_DATE + INTERVAL '1 year',
    'security_team',
    true,
    'system'
);

-- Insert default data formats
INSERT INTO data_formats (
    format_id, format_name, format_type, schema_definition, description, created_by
) VALUES 
(
    uuid_generate_v4(),
    'WFM Standard JSON',
    'json',
    '{"type": "object", "properties": {"timestamp": {"type": "string"}, "data": {"type": "object"}}}',
    'Standard WFM data exchange format',
    'system'
),
(
    uuid_generate_v4(),
    'Argus Import Format',
    'delimited',
    '{"delimiter": "\t", "headers": true, "encoding": "utf-8"}',
    'Argus system data import format',
    'system'
);

-- =============================================================================
-- GRANTS AND PERMISSIONS
-- =============================================================================

-- Grant permissions to application user (adjust as needed)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_app_user;

-- =============================================================================
-- SCHEMA COMPLETION
-- =============================================================================

-- Log schema creation
INSERT INTO schema_migrations (migration_name, applied_at) 
VALUES ('080_enterprise_integration_apis', NOW())
ON CONFLICT (migration_name) DO NOTHING;