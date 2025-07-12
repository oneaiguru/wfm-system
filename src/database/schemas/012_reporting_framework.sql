-- =============================================================================
-- 012_reporting_framework.sql
-- WFM Multi-Agent Intelligence Framework - Reporting Framework Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Complete business intelligence and reporting framework
-- Tables: 12 core reporting tables with full BI capabilities
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- =============================================================================
-- 1. REPORT_DEFINITIONS - Report configurations and metadata
-- =============================================================================
CREATE TABLE report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('tabular', 'chart', 'dashboard', 'pivot', 'summary')),
    query_template TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    visualization_config JSONB DEFAULT '{}',
    access_level VARCHAR(20) DEFAULT 'private' CHECK (access_level IN ('public', 'private', 'restricted')),
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    execution_timeout INTEGER DEFAULT 300, -- seconds
    max_rows INTEGER DEFAULT 10000,
    cache_duration INTEGER DEFAULT 3600, -- seconds
    
    -- Metadata for UI-OPUS integration
    ui_config JSONB DEFAULT '{}',
    sorting_config JSONB DEFAULT '{}',
    filtering_config JSONB DEFAULT '{}',
    
    CONSTRAINT fk_report_definitions_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for report_definitions
CREATE INDEX idx_report_definitions_category ON report_definitions(category);
CREATE INDEX idx_report_definitions_type ON report_definitions(report_type);
CREATE INDEX idx_report_definitions_created_by ON report_definitions(created_by);
CREATE INDEX idx_report_definitions_tags ON report_definitions USING GIN(tags);
CREATE INDEX idx_report_definitions_active ON report_definitions(is_active) WHERE is_active = true;

-- =============================================================================
-- 2. REPORT_TEMPLATES - Reusable report templates
-- =============================================================================
CREATE TABLE report_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('sql', 'json', 'xml', 'html')),
    template_content TEXT NOT NULL,
    parameter_schema JSONB DEFAULT '{}',
    default_values JSONB DEFAULT '{}',
    category VARCHAR(100),
    is_system_template BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    
    -- Template styling and layout
    style_config JSONB DEFAULT '{}',
    layout_config JSONB DEFAULT '{}',
    
    CONSTRAINT fk_report_templates_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for report_templates
CREATE INDEX idx_report_templates_type ON report_templates(template_type);
CREATE INDEX idx_report_templates_category ON report_templates(category);
CREATE INDEX idx_report_templates_system ON report_templates(is_system_template);
CREATE INDEX idx_report_templates_usage ON report_templates(usage_count DESC);

-- =============================================================================
-- 3. REPORT_SCHEDULES - Automated report scheduling
-- =============================================================================
CREATE TABLE report_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL,
    schedule_name VARCHAR(255) NOT NULL,
    cron_expression VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT true,
    output_format VARCHAR(20) DEFAULT 'pdf' CHECK (output_format IN ('pdf', 'excel', 'csv', 'json')),
    delivery_method VARCHAR(20) DEFAULT 'email' CHECK (delivery_method IN ('email', 'ftp', 'api', 'storage')),
    delivery_config JSONB DEFAULT '{}',
    recipients TEXT[] DEFAULT '{}',
    parameters JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_run_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    max_failures INTEGER DEFAULT 3,
    
    -- Advanced scheduling options
    run_conditions JSONB DEFAULT '{}',
    retry_config JSONB DEFAULT '{}',
    
    CONSTRAINT fk_report_schedules_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_schedules_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for report_schedules
CREATE INDEX idx_report_schedules_report_id ON report_schedules(report_id);
CREATE INDEX idx_report_schedules_active ON report_schedules(is_active) WHERE is_active = true;
CREATE INDEX idx_report_schedules_next_run ON report_schedules(next_run_at) WHERE is_active = true;

-- =============================================================================
-- 4. REPORT_EXECUTIONS - Execution tracking and history
-- =============================================================================
CREATE TABLE report_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL,
    schedule_id UUID,
    executed_by UUID,
    execution_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled')),
    parameters JSONB DEFAULT '{}',
    result_summary JSONB DEFAULT '{}',
    error_message TEXT,
    row_count INTEGER,
    execution_time_ms INTEGER,
    memory_usage_mb INTEGER,
    output_size_bytes BIGINT,
    cache_hit BOOLEAN DEFAULT false,
    
    -- Performance metrics
    query_execution_time_ms INTEGER,
    data_processing_time_ms INTEGER,
    export_time_ms INTEGER,
    
    -- Audit trail
    client_ip INET,
    user_agent TEXT,
    
    CONSTRAINT fk_report_executions_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_executions_schedule_id 
        FOREIGN KEY (schedule_id) REFERENCES report_schedules(id) ON DELETE SET NULL,
    CONSTRAINT fk_report_executions_executed_by 
        FOREIGN KEY (executed_by) REFERENCES users(id)
);

-- Indexes for report_executions
CREATE INDEX idx_report_executions_report_id ON report_executions(report_id);
CREATE INDEX idx_report_executions_status ON report_executions(status);
CREATE INDEX idx_report_executions_start_time ON report_executions(execution_start DESC);
CREATE INDEX idx_report_executions_executed_by ON report_executions(executed_by);

-- =============================================================================
-- 5. REPORT_EXPORTS - Export history and format management
-- =============================================================================
CREATE TABLE report_exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL,
    export_format VARCHAR(20) NOT NULL CHECK (export_format IN ('pdf', 'excel', 'csv', 'json', 'xml')),
    file_path TEXT,
    file_size_bytes BIGINT,
    file_hash VARCHAR(64),
    export_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    export_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    error_message TEXT,
    download_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Export configuration
    export_config JSONB DEFAULT '{}',
    compression_type VARCHAR(20),
    password_protected BOOLEAN DEFAULT false,
    
    -- Storage information
    storage_provider VARCHAR(50) DEFAULT 'local',
    storage_config JSONB DEFAULT '{}',
    
    CONSTRAINT fk_report_exports_execution_id 
        FOREIGN KEY (execution_id) REFERENCES report_executions(id) ON DELETE CASCADE
);

-- Indexes for report_exports
CREATE INDEX idx_report_exports_execution_id ON report_exports(execution_id);
CREATE INDEX idx_report_exports_format ON report_exports(export_format);
CREATE INDEX idx_report_exports_status ON report_exports(status);
CREATE INDEX idx_report_exports_expires_at ON report_exports(expires_at) WHERE expires_at IS NOT NULL;

-- =============================================================================
-- 6. REPORT_SUBSCRIPTIONS - User subscriptions and notifications
-- =============================================================================
CREATE TABLE report_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    report_id UUID NOT NULL,
    subscription_type VARCHAR(20) DEFAULT 'email' CHECK (subscription_type IN ('email', 'webhook', 'push', 'sms')),
    frequency VARCHAR(20) DEFAULT 'daily' CHECK (frequency IN ('real-time', 'hourly', 'daily', 'weekly', 'monthly')),
    delivery_config JSONB DEFAULT '{}',
    filter_conditions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_delivery_at TIMESTAMP WITH TIME ZONE,
    delivery_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    
    -- Notification preferences
    format_preference VARCHAR(20) DEFAULT 'pdf',
    include_summary BOOLEAN DEFAULT true,
    include_charts BOOLEAN DEFAULT true,
    
    CONSTRAINT fk_report_subscriptions_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_subscriptions_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE,
    CONSTRAINT uq_report_subscriptions_user_report 
        UNIQUE(user_id, report_id)
);

-- Indexes for report_subscriptions
CREATE INDEX idx_report_subscriptions_user_id ON report_subscriptions(user_id);
CREATE INDEX idx_report_subscriptions_report_id ON report_subscriptions(report_id);
CREATE INDEX idx_report_subscriptions_active ON report_subscriptions(is_active) WHERE is_active = true;
CREATE INDEX idx_report_subscriptions_frequency ON report_subscriptions(frequency);

-- =============================================================================
-- 7. REPORT_PERMISSIONS - Role-based access control
-- =============================================================================
CREATE TABLE report_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL,
    permission_type VARCHAR(20) NOT NULL CHECK (permission_type IN ('user', 'role', 'group')),
    permission_target VARCHAR(255) NOT NULL, -- user_id, role_name, or group_name
    access_level VARCHAR(20) DEFAULT 'read' CHECK (access_level IN ('read', 'write', 'execute', 'admin')),
    granted_by UUID NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Permission constraints
    allowed_actions TEXT[] DEFAULT '{}',
    denied_actions TEXT[] DEFAULT '{}',
    row_level_filters JSONB DEFAULT '{}',
    column_restrictions TEXT[] DEFAULT '{}',
    
    CONSTRAINT fk_report_permissions_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_permissions_granted_by 
        FOREIGN KEY (granted_by) REFERENCES users(id),
    CONSTRAINT uq_report_permissions_target 
        UNIQUE(report_id, permission_type, permission_target)
);

-- Indexes for report_permissions
CREATE INDEX idx_report_permissions_report_id ON report_permissions(report_id);
CREATE INDEX idx_report_permissions_type_target ON report_permissions(permission_type, permission_target);
CREATE INDEX idx_report_permissions_active ON report_permissions(is_active) WHERE is_active = true;

-- =============================================================================
-- 8. DASHBOARD_CONFIGS - Dashboard layouts and configurations
-- =============================================================================
CREATE TABLE dashboard_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    layout_config JSONB NOT NULL DEFAULT '{}',
    widget_configs JSONB NOT NULL DEFAULT '[]',
    theme VARCHAR(50) DEFAULT 'default',
    is_public BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    
    -- Dashboard settings
    auto_refresh_interval INTEGER DEFAULT 300, -- seconds
    full_screen_mode BOOLEAN DEFAULT false,
    show_filters BOOLEAN DEFAULT true,
    show_export_options BOOLEAN DEFAULT true,
    
    -- Mobile responsiveness
    mobile_config JSONB DEFAULT '{}',
    tablet_config JSONB DEFAULT '{}',
    
    CONSTRAINT fk_dashboard_configs_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for dashboard_configs
CREATE INDEX idx_dashboard_configs_created_by ON dashboard_configs(created_by);
CREATE INDEX idx_dashboard_configs_public ON dashboard_configs(is_public) WHERE is_public = true;
CREATE INDEX idx_dashboard_configs_view_count ON dashboard_configs(view_count DESC);

-- =============================================================================
-- 9. KPI_DEFINITIONS - Key Performance Indicators
-- =============================================================================
CREATE TABLE kpi_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    calculation_formula TEXT NOT NULL,
    data_source VARCHAR(255) NOT NULL,
    unit_of_measure VARCHAR(50),
    target_value DECIMAL(15,4),
    threshold_config JSONB DEFAULT '{}',
    trend_analysis JSONB DEFAULT '{}',
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    -- KPI metadata
    business_owner VARCHAR(255),
    update_frequency VARCHAR(20) DEFAULT 'daily',
    data_quality_rules JSONB DEFAULT '{}',
    
    -- Visualization preferences
    chart_type VARCHAR(50) DEFAULT 'line',
    color_scheme VARCHAR(50) DEFAULT 'default',
    display_format VARCHAR(50) DEFAULT 'number',
    
    CONSTRAINT fk_kpi_definitions_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for kpi_definitions
CREATE INDEX idx_kpi_definitions_category ON kpi_definitions(category);
CREATE INDEX idx_kpi_definitions_created_by ON kpi_definitions(created_by);
CREATE INDEX idx_kpi_definitions_active ON kpi_definitions(is_active) WHERE is_active = true;

-- =============================================================================
-- 10. DATA_SOURCES - Data source configurations
-- =============================================================================
CREATE TABLE data_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('database', 'api', 'file', 'stream')),
    connection_config JSONB NOT NULL DEFAULT '{}',
    authentication_config JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_tested_at TIMESTAMP WITH TIME ZONE,
    test_status VARCHAR(20) DEFAULT 'unknown' CHECK (test_status IN ('unknown', 'success', 'failed')),
    
    -- Performance and reliability
    timeout_seconds INTEGER DEFAULT 30,
    retry_count INTEGER DEFAULT 3,
    rate_limit_config JSONB DEFAULT '{}',
    
    -- Data quality
    schema_validation JSONB DEFAULT '{}',
    data_quality_rules JSONB DEFAULT '{}',
    
    -- Monitoring
    health_check_config JSONB DEFAULT '{}',
    monitoring_enabled BOOLEAN DEFAULT true,
    
    CONSTRAINT fk_data_sources_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for data_sources
CREATE INDEX idx_data_sources_type ON data_sources(source_type);
CREATE INDEX idx_data_sources_active ON data_sources(is_active) WHERE is_active = true;
CREATE INDEX idx_data_sources_created_by ON data_sources(created_by);

-- =============================================================================
-- 11. REPORT_CACHE - Performance optimization cache
-- =============================================================================
CREATE TABLE report_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(255) NOT NULL UNIQUE,
    report_id UUID NOT NULL,
    parameters_hash VARCHAR(64) NOT NULL,
    cached_data JSONB,
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    hit_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_size_bytes BIGINT,
    generation_time_ms INTEGER,
    
    -- Cache metadata
    cache_version INTEGER DEFAULT 1,
    compression_type VARCHAR(20),
    cache_tags TEXT[] DEFAULT '{}',
    
    CONSTRAINT fk_report_cache_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE
);

-- Indexes for report_cache
CREATE INDEX idx_report_cache_report_id ON report_cache(report_id);
CREATE INDEX idx_report_cache_expires_at ON report_cache(expires_at);
CREATE INDEX idx_report_cache_hit_count ON report_cache(hit_count DESC);
CREATE INDEX idx_report_cache_tags ON report_cache USING GIN(cache_tags);

-- =============================================================================
-- 12. REPORT_ALERTS - Threshold-based alerts and notifications
-- =============================================================================
CREATE TABLE report_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    report_id UUID,
    kpi_id UUID,
    alert_type VARCHAR(20) NOT NULL CHECK (alert_type IN ('threshold', 'trend', 'anomaly', 'schedule')),
    condition_config JSONB NOT NULL DEFAULT '{}',
    notification_config JSONB NOT NULL DEFAULT '{}',
    recipients TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    trigger_count INTEGER DEFAULT 0,
    
    -- Alert settings
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    cooldown_period INTEGER DEFAULT 3600, -- seconds
    escalation_config JSONB DEFAULT '{}',
    
    -- Suppression rules
    suppression_rules JSONB DEFAULT '{}',
    is_suppressed BOOLEAN DEFAULT false,
    suppressed_until TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT fk_report_alerts_report_id 
        FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_alerts_kpi_id 
        FOREIGN KEY (kpi_id) REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_alerts_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT chk_report_alerts_source 
        CHECK ((report_id IS NOT NULL) OR (kpi_id IS NOT NULL))
);

-- Indexes for report_alerts
CREATE INDEX idx_report_alerts_report_id ON report_alerts(report_id);
CREATE INDEX idx_report_alerts_kpi_id ON report_alerts(kpi_id);
CREATE INDEX idx_report_alerts_active ON report_alerts(is_active) WHERE is_active = true;
CREATE INDEX idx_report_alerts_severity ON report_alerts(severity);
CREATE INDEX idx_report_alerts_suppressed ON report_alerts(is_suppressed) WHERE is_suppressed = false;

-- =============================================================================
-- VIEWS FOR UI-OPUS INTEGRATION
-- =============================================================================

-- Report execution summary view
CREATE VIEW v_report_execution_summary AS
SELECT 
    rd.id as report_id,
    rd.name as report_name,
    rd.category,
    rd.report_type,
    COUNT(re.id) as total_executions,
    COUNT(CASE WHEN re.status = 'completed' THEN 1 END) as successful_executions,
    COUNT(CASE WHEN re.status = 'failed' THEN 1 END) as failed_executions,
    AVG(re.execution_time_ms) as avg_execution_time_ms,
    MAX(re.execution_start) as last_execution,
    SUM(re.row_count) as total_rows_processed
FROM report_definitions rd
LEFT JOIN report_executions re ON rd.id = re.report_id
WHERE rd.is_active = true
GROUP BY rd.id, rd.name, rd.category, rd.report_type;

-- Dashboard widget view
CREATE VIEW v_dashboard_widgets AS
SELECT 
    dc.id as dashboard_id,
    dc.name as dashboard_name,
    jsonb_array_elements(dc.widget_configs) as widget_config,
    dc.created_by,
    dc.view_count,
    dc.last_viewed_at
FROM dashboard_configs dc
WHERE dc.is_public = true OR dc.created_by = current_user_id();

-- KPI performance view
CREATE VIEW v_kpi_performance AS
SELECT 
    kd.id as kpi_id,
    kd.name as kpi_name,
    kd.category,
    kd.target_value,
    kd.unit_of_measure,
    kd.threshold_config,
    COUNT(ra.id) as active_alerts
FROM kpi_definitions kd
LEFT JOIN report_alerts ra ON kd.id = ra.kpi_id AND ra.is_active = true
WHERE kd.is_active = true
GROUP BY kd.id, kd.name, kd.category, kd.target_value, kd.unit_of_measure, kd.threshold_config;

-- =============================================================================
-- FUNCTIONS FOR UI-OPUS INTEGRATION
-- =============================================================================

-- Function to get user's accessible reports
CREATE OR REPLACE FUNCTION get_user_accessible_reports(p_user_id UUID)
RETURNS TABLE (
    report_id UUID,
    report_name VARCHAR(255),
    category VARCHAR(100),
    report_type VARCHAR(50),
    access_level VARCHAR(20),
    can_execute BOOLEAN,
    can_modify BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rd.id,
        rd.name,
        rd.category,
        rd.report_type,
        COALESCE(rp.access_level, 'read') as access_level,
        CASE 
            WHEN rd.access_level = 'public' THEN true
            WHEN rd.created_by = p_user_id THEN true
            WHEN rp.access_level IN ('execute', 'admin') THEN true
            ELSE false
        END as can_execute,
        CASE 
            WHEN rd.created_by = p_user_id THEN true
            WHEN rp.access_level IN ('write', 'admin') THEN true
            ELSE false
        END as can_modify
    FROM report_definitions rd
    LEFT JOIN report_permissions rp ON rd.id = rp.report_id 
        AND rp.permission_type = 'user' 
        AND rp.permission_target = p_user_id::TEXT
        AND rp.is_active = true
    WHERE rd.is_active = true
    ORDER BY rd.name;
END;
$$ LANGUAGE plpgsql;

-- Function to execute report with caching
CREATE OR REPLACE FUNCTION execute_report_with_cache(
    p_report_id UUID,
    p_user_id UUID,
    p_parameters JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
    v_cache_key VARCHAR(255);
    v_cache_result JSONB;
    v_execution_id UUID;
    v_report_config RECORD;
BEGIN
    -- Get report configuration
    SELECT * INTO v_report_config 
    FROM report_definitions 
    WHERE id = p_report_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Report not found or inactive';
    END IF;
    
    -- Generate cache key
    v_cache_key := 'report_' || p_report_id || '_' || md5(p_parameters::TEXT);
    
    -- Check cache first
    SELECT cached_data INTO v_cache_result
    FROM report_cache
    WHERE cache_key = v_cache_key 
        AND expires_at > CURRENT_TIMESTAMP;
    
    IF v_cache_result IS NOT NULL THEN
        -- Update cache statistics
        UPDATE report_cache 
        SET hit_count = hit_count + 1,
            last_accessed_at = CURRENT_TIMESTAMP
        WHERE cache_key = v_cache_key;
        
        RETURN v_cache_result;
    END IF;
    
    -- Create execution record
    INSERT INTO report_executions (report_id, executed_by, parameters, status)
    VALUES (p_report_id, p_user_id, p_parameters, 'running')
    RETURNING id INTO v_execution_id;
    
    -- Return execution ID for async processing
    RETURN jsonb_build_object(
        'execution_id', v_execution_id,
        'status', 'running',
        'message', 'Report execution started'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to clean expired cache
CREATE OR REPLACE FUNCTION clean_expired_cache()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM report_cache 
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get report execution status
CREATE OR REPLACE FUNCTION get_report_execution_status(p_execution_id UUID)
RETURNS TABLE (
    execution_id UUID,
    status VARCHAR(20),
    progress_percentage INTEGER,
    row_count INTEGER,
    error_message TEXT,
    result_summary JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        re.id,
        re.status,
        CASE 
            WHEN re.status = 'completed' THEN 100
            WHEN re.status = 'failed' THEN 0
            ELSE 50  -- running
        END as progress_percentage,
        re.row_count,
        re.error_message,
        re.result_summary
    FROM report_executions re
    WHERE re.id = p_execution_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SAMPLE DATA GENERATORS
-- =============================================================================

-- Function to generate sample report definitions
CREATE OR REPLACE FUNCTION generate_sample_report_definitions()
RETURNS VOID AS $$
BEGIN
    INSERT INTO report_definitions (name, description, category, report_type, query_template, created_by)
    VALUES 
        ('Employee Attendance Summary', 'Monthly attendance report for all employees', 'HR', 'tabular', 
         'SELECT * FROM employee_attendance WHERE month = {{month}} AND year = {{year}}', 
         (SELECT id FROM users LIMIT 1)),
        ('Workforce Capacity Analysis', 'Analysis of workforce capacity vs demand', 'Planning', 'chart',
         'SELECT date, capacity, demand FROM workforce_capacity WHERE date >= {{start_date}} AND date <= {{end_date}}',
         (SELECT id FROM users LIMIT 1)),
        ('Schedule Adherence Dashboard', 'Real-time schedule adherence monitoring', 'Operations', 'dashboard',
         'SELECT * FROM schedule_adherence WHERE date = CURRENT_DATE',
         (SELECT id FROM users LIMIT 1));
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample KPI definitions
CREATE OR REPLACE FUNCTION generate_sample_kpi_definitions()
RETURNS VOID AS $$
BEGIN
    INSERT INTO kpi_definitions (name, description, category, calculation_formula, data_source, unit_of_measure, target_value, created_by)
    VALUES 
        ('Schedule Adherence Rate', 'Percentage of time agents adhere to schedule', 'Performance', 
         'SUM(adherent_time) / SUM(scheduled_time) * 100', 'schedule_adherence', '%', 85.0,
         (SELECT id FROM users LIMIT 1)),
        ('Average Handle Time', 'Average time to handle customer interactions', 'Efficiency',
         'AVG(handle_time_seconds)', 'interaction_logs', 'seconds', 300.0,
         (SELECT id FROM users LIMIT 1)),
        ('First Call Resolution', 'Percentage of issues resolved on first contact', 'Quality',
         'COUNT(resolved_first_call) / COUNT(total_calls) * 100', 'call_resolution', '%', 75.0,
         (SELECT id FROM users LIMIT 1));
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample dashboard configurations
CREATE OR REPLACE FUNCTION generate_sample_dashboard_configs()
RETURNS VOID AS $$
BEGIN
    INSERT INTO dashboard_configs (name, description, layout_config, widget_configs, created_by)
    VALUES 
        ('Operations Dashboard', 'Real-time operations monitoring', 
         '{"columns": 3, "rows": 2, "responsive": true}',
         '[{"type": "chart", "title": "Schedule Adherence", "span": 2}, {"type": "kpi", "title": "AHT", "span": 1}]',
         (SELECT id FROM users LIMIT 1)),
        ('HR Analytics Dashboard', 'Human resources analytics and insights',
         '{"columns": 2, "rows": 3, "responsive": true}',
         '[{"type": "table", "title": "Attendance Summary", "span": 1}, {"type": "chart", "title": "Workforce Trends", "span": 1}]',
         (SELECT id FROM users LIMIT 1));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- EXPORT FORMAT SUPPORT FUNCTIONS
-- =============================================================================

-- Function to export report as CSV
CREATE OR REPLACE FUNCTION export_report_csv(
    p_execution_id UUID,
    p_file_path TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_export_id UUID;
BEGIN
    INSERT INTO report_exports (execution_id, export_format, file_path, status)
    VALUES (p_execution_id, 'csv', p_file_path, 'processing')
    RETURNING id INTO v_export_id;
    
    -- Async processing would happen here
    -- For now, mark as completed
    UPDATE report_exports 
    SET status = 'completed', 
        export_end = CURRENT_TIMESTAMP
    WHERE id = v_export_id;
    
    RETURN v_export_id;
END;
$$ LANGUAGE plpgsql;

-- Function to export report as PDF
CREATE OR REPLACE FUNCTION export_report_pdf(
    p_execution_id UUID,
    p_template_id UUID DEFAULT NULL,
    p_file_path TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_export_id UUID;
BEGIN
    INSERT INTO report_exports (execution_id, export_format, file_path, status, export_config)
    VALUES (p_execution_id, 'pdf', p_file_path, 'processing', 
            jsonb_build_object('template_id', p_template_id))
    RETURNING id INTO v_export_id;
    
    -- Async processing would happen here
    UPDATE report_exports 
    SET status = 'completed', 
        export_end = CURRENT_TIMESTAMP
    WHERE id = v_export_id;
    
    RETURN v_export_id;
END;
$$ LANGUAGE plpgsql;

-- Function to export report as Excel
CREATE OR REPLACE FUNCTION export_report_excel(
    p_execution_id UUID,
    p_include_charts BOOLEAN DEFAULT true,
    p_file_path TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_export_id UUID;
BEGIN
    INSERT INTO report_exports (execution_id, export_format, file_path, status, export_config)
    VALUES (p_execution_id, 'excel', p_file_path, 'processing', 
            jsonb_build_object('include_charts', p_include_charts))
    RETURNING id INTO v_export_id;
    
    -- Async processing would happen here
    UPDATE report_exports 
    SET status = 'completed', 
        export_end = CURRENT_TIMESTAMP
    WHERE id = v_export_id;
    
    RETURN v_export_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PERFORMANCE OPTIMIZATION FUNCTIONS
-- =============================================================================

-- Function to optimize report cache
CREATE OR REPLACE FUNCTION optimize_report_cache()
RETURNS TABLE (
    action VARCHAR(50),
    affected_rows INTEGER,
    details TEXT
) AS $$
DECLARE
    v_expired_count INTEGER;
    v_unused_count INTEGER;
    v_large_count INTEGER;
BEGIN
    -- Clean expired cache
    DELETE FROM report_cache WHERE expires_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS v_expired_count = ROW_COUNT;
    
    -- Clean unused cache (not accessed in 30 days)
    DELETE FROM report_cache 
    WHERE last_accessed_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
        AND hit_count = 0;
    GET DIAGNOSTICS v_unused_count = ROW_COUNT;
    
    -- Clean large cache entries (>100MB) older than 7 days
    DELETE FROM report_cache 
    WHERE data_size_bytes > 100 * 1024 * 1024
        AND cached_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
    GET DIAGNOSTICS v_large_count = ROW_COUNT;
    
    RETURN QUERY VALUES 
        ('expired_cleanup', v_expired_count, 'Removed expired cache entries'),
        ('unused_cleanup', v_unused_count, 'Removed unused cache entries'),
        ('large_cleanup', v_large_count, 'Removed large old cache entries');
END;
$$ LANGUAGE plpgsql;

-- Function to analyze report performance
CREATE OR REPLACE FUNCTION analyze_report_performance(p_days INTEGER DEFAULT 7)
RETURNS TABLE (
    report_id UUID,
    report_name VARCHAR(255),
    execution_count INTEGER,
    avg_execution_time_ms INTEGER,
    success_rate DECIMAL(5,2),
    cache_hit_rate DECIMAL(5,2),
    recommendations TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rd.id,
        rd.name,
        COUNT(re.id)::INTEGER as execution_count,
        AVG(re.execution_time_ms)::INTEGER as avg_execution_time_ms,
        (COUNT(CASE WHEN re.status = 'completed' THEN 1 END) * 100.0 / COUNT(re.id))::DECIMAL(5,2) as success_rate,
        (COUNT(CASE WHEN re.cache_hit = true THEN 1 END) * 100.0 / COUNT(re.id))::DECIMAL(5,2) as cache_hit_rate,
        CASE 
            WHEN AVG(re.execution_time_ms) > 30000 THEN 'Consider query optimization'
            WHEN COUNT(CASE WHEN re.cache_hit = true THEN 1 END) * 100.0 / COUNT(re.id) < 30 THEN 'Increase cache duration'
            WHEN COUNT(CASE WHEN re.status = 'failed' THEN 1 END) > 0 THEN 'Review error patterns'
            ELSE 'Performance is optimal'
        END as recommendations
    FROM report_definitions rd
    LEFT JOIN report_executions re ON rd.id = re.report_id
        AND re.execution_start > CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days
    WHERE rd.is_active = true
    GROUP BY rd.id, rd.name
    HAVING COUNT(re.id) > 0
    ORDER BY execution_count DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS FOR AUDIT AND AUTOMATION
-- =============================================================================

-- Trigger to update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all relevant tables
CREATE TRIGGER tr_report_definitions_updated_at
    BEFORE UPDATE ON report_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_report_templates_updated_at
    BEFORE UPDATE ON report_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_report_schedules_updated_at
    BEFORE UPDATE ON report_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_report_subscriptions_updated_at
    BEFORE UPDATE ON report_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_dashboard_configs_updated_at
    BEFORE UPDATE ON dashboard_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_kpi_definitions_updated_at
    BEFORE UPDATE ON kpi_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_data_sources_updated_at
    BEFORE UPDATE ON data_sources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_report_alerts_updated_at
    BEFORE UPDATE ON report_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE report_definitions IS 'Core report configurations and metadata';
COMMENT ON TABLE report_templates IS 'Reusable report templates for consistent formatting';
COMMENT ON TABLE report_schedules IS 'Automated report scheduling with cron expressions';
COMMENT ON TABLE report_executions IS 'Execution tracking and performance metrics';
COMMENT ON TABLE report_exports IS 'Export history and file management';
COMMENT ON TABLE report_subscriptions IS 'User subscriptions and notification preferences';
COMMENT ON TABLE report_permissions IS 'Role-based access control for reports';
COMMENT ON TABLE dashboard_configs IS 'Dashboard layouts and widget configurations';
COMMENT ON TABLE kpi_definitions IS 'Key Performance Indicator definitions and targets';
COMMENT ON TABLE data_sources IS 'Data source configurations and connection details';
COMMENT ON TABLE report_cache IS 'Performance optimization through result caching';
COMMENT ON TABLE report_alerts IS 'Threshold-based alerts and notifications';

-- =============================================================================
-- INITIAL SETUP AND SAMPLE DATA
-- =============================================================================

-- Generate sample data (only if no data exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM report_definitions LIMIT 1) THEN
        PERFORM generate_sample_report_definitions();
        PERFORM generate_sample_kpi_definitions();
        PERFORM generate_sample_dashboard_configs();
    END IF;
END $$;

-- =============================================================================
-- SCHEMA COMPLETION
-- =============================================================================

-- Grant permissions for application roles
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_application;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_application;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_application;

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_report_executions_composite 
    ON report_executions(report_id, execution_start DESC, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_report_cache_composite 
    ON report_cache(report_id, parameters_hash, expires_at);

-- Final comment
COMMENT ON SCHEMA public IS 'WFM Reporting Framework Schema v1.0 - Complete business intelligence solution';

-- =============================================================================
-- END OF SCHEMA: 012_reporting_framework.sql
-- =============================================================================