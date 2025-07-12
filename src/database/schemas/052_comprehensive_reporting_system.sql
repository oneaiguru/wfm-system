-- =============================================================================
-- 052_comprehensive_reporting_system.sql
-- EXACT BDD Implementation: Comprehensive Reporting System with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 23-comprehensive-reporting-system.feature (702 lines)
-- Purpose: Complete enterprise reporting coverage with flexible report editor
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. REPORT EDITOR INFRASTRUCTURE
-- =============================================================================

-- Report catalog and editor from BDD lines 22-28
CREATE TABLE report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id VARCHAR(50) NOT NULL UNIQUE,
    report_name VARCHAR(200) NOT NULL,
    report_description TEXT,
    
    -- Status from BDD line 25
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'blocked', 'archived')),
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'operational', 'personnel', 'performance', 'planning', 'administrative'
    )),
    
    -- Data source method from BDD lines 30-32
    data_source_method VARCHAR(20) NOT NULL CHECK (data_source_method IN ('sql', 'groovy')),
    query_definition TEXT NOT NULL,
    
    -- Editor configuration
    is_searchable BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 1,
    icon_name VARCHAR(50),
    
    -- Permissions and security
    required_role VARCHAR(50) DEFAULT 'user',
    data_sensitivity VARCHAR(20) DEFAULT 'normal' CHECK (data_sensitivity IN ('public', 'normal', 'sensitive', 'confidential')),
    
    -- Version control
    version VARCHAR(20) DEFAULT '1.0',
    parent_report_id UUID,
    
    -- Lifecycle
    created_by UUID NOT NULL,
    last_modified_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_report_id) REFERENCES report_definitions(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. REPORT INPUT PARAMETERS
-- =============================================================================

-- Report parameters from BDD lines 38-49
CREATE TABLE report_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    param_id VARCHAR(50) NOT NULL,
    report_id VARCHAR(50) NOT NULL,
    parameter_name VARCHAR(100) NOT NULL,
    
    -- Parameter types from BDD lines 39-45
    parameter_type VARCHAR(30) NOT NULL CHECK (parameter_type IN (
        'date', 'numeric_fractional', 'numeric_integer', 'logical', 'text', 'query_result'
    )),
    
    -- Requirements from BDD lines 47-49
    is_mandatory BOOLEAN DEFAULT false,
    default_value TEXT,
    
    -- Parameter configuration
    validation_rules JSONB DEFAULT '{}',
    display_order INTEGER DEFAULT 1,
    parameter_description TEXT,
    
    -- For query_result type parameters
    lookup_query TEXT,
    lookup_value_field VARCHAR(50),
    lookup_display_field VARCHAR(50),
    
    -- UI configuration
    input_control VARCHAR(30) DEFAULT 'textbox' CHECK (input_control IN (
        'textbox', 'dropdown', 'checkbox', 'radio', 'datepicker', 'textarea'
    )),
    placeholder_text VARCHAR(200),
    help_text TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE CASCADE,
    
    UNIQUE(report_id, param_id)
);

-- =============================================================================
-- 3. EXPORT TEMPLATES
-- =============================================================================

-- Export templates from BDD lines 55-62
CREATE TABLE report_export_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id VARCHAR(50) NOT NULL UNIQUE,
    report_id VARCHAR(50) NOT NULL,
    template_name VARCHAR(200) NOT NULL,
    
    -- Export formats from BDD lines 56-61
    export_format VARCHAR(20) NOT NULL CHECK (export_format IN (
        'xlsx', 'docx', 'html', 'xslm', 'pdf', 'csv', 'json'
    )),
    
    -- Template configuration
    template_file_path VARCHAR(500),
    template_content BYTEA,
    use_case VARCHAR(100),
    features_description TEXT,
    
    -- Template settings
    auto_formatting BOOLEAN DEFAULT true,
    include_charts BOOLEAN DEFAULT false,
    page_orientation VARCHAR(20) DEFAULT 'portrait' CHECK (page_orientation IN ('portrait', 'landscape')),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE CASCADE
);

-- =============================================================================
-- 4. OPERATIONAL REPORTS CONFIGURATION
-- =============================================================================

-- Login/logout report configuration from BDD lines 72-89
CREATE TABLE operational_reports_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'login_logout', 'schedule_adherence', 'lateness', 'absenteeism'
    )),
    
    -- Configuration parameters from BDD scenarios
    required_parameters JSONB NOT NULL,
    optional_parameters JSONB DEFAULT '{}',
    
    -- Report-specific settings
    date_range_constraints JSONB DEFAULT '{}',
    detailing_constraints JSONB DEFAULT '{}',
    
    -- Output configuration
    output_fields JSONB NOT NULL,
    summary_fields JSONB DEFAULT '{}',
    
    -- Calculation rules
    calculation_formulas JSONB DEFAULT '{}',
    business_rules JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. PERSONNEL REPORTS CONFIGURATION
-- =============================================================================

-- Personnel reports from BDD lines 158-258
CREATE TABLE personnel_reports_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'existing_employees', 'vacation_summary', 'vacation_upload', 'job_changes', 'skill_changes'
    )),
    
    -- Employee data configuration from BDD lines 168-184
    employee_fields JSONB NOT NULL,
    summary_fields JSONB DEFAULT '{}',
    
    -- Report tabs configuration
    tab_configuration JSONB DEFAULT '{}',
    
    -- Calculation rules from BDD lines 199-203
    calculation_rules JSONB DEFAULT '{}',
    
    -- Data source integration
    data_source_systems JSONB DEFAULT '[]',
    integration_rules JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. PERFORMANCE REPORTS CONFIGURATION
-- =============================================================================

-- Performance reports from BDD lines 264-340
CREATE TABLE performance_reports_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'aht_analysis', 'ready_percentage', 'load_comparison'
    )),
    
    -- AHT configuration from BDD lines 273-287
    aht_calculation_formulas JSONB DEFAULT '{}',
    aht_display_precision INTEGER DEFAULT 3,
    
    -- Ready percentage configuration from BDD lines 299-313
    ready_calculation_rules JSONB DEFAULT '{}',
    overlap_handling_method VARCHAR(50) DEFAULT 'merge_unique',
    
    -- Load comparison configuration from BDD lines 324-339
    data_type_options JSONB DEFAULT '[]',
    summary_calculations JSONB DEFAULT '{}',
    
    -- General configuration
    tab_structure JSONB DEFAULT '{}',
    aggregation_levels JSONB DEFAULT '[]',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. PLANNING REPORTS CONFIGURATION
-- =============================================================================

-- Planning reports from BDD lines 345-466
CREATE TABLE planning_reports_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'forecast_export', 'budget_assessment', 'graph_analysis', 'employee_schedule', 'preferences_analysis'
    )),
    
    -- Forecast configuration from BDD lines 354-366
    interval_settings JSONB DEFAULT '{}',
    forecast_fields JSONB DEFAULT '{}',
    
    -- Budget configuration from BDD lines 377-389
    budget_formulas JSONB DEFAULT '{}',
    plan_calculations JSONB DEFAULT '{}',
    
    -- Schedule configuration from BDD lines 420-434
    schedule_display_rules JSONB DEFAULT '{}',
    color_coding_rules JSONB DEFAULT '{}',
    
    -- Preferences configuration from BDD lines 449-465
    preference_calculations JSONB DEFAULT '{}',
    consideration_formulas JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. ADMINISTRATIVE REPORTS CONFIGURATION
-- =============================================================================

-- Administrative reports from BDD lines 471-547
CREATE TABLE administrative_reports_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'system_logging', 'acknowledgment_tracking', 'notification_status', 'forecast_plan_analysis'
    )),
    
    -- Logging configuration from BDD lines 479-487
    retention_period_years INTEGER DEFAULT 3,
    log_grouping_rules JSONB DEFAULT '{}',
    
    -- Acknowledgment configuration from BDD lines 498-504
    acknowledgment_fields JSONB DEFAULT '{}',
    
    -- Notification configuration from BDD lines 515-523
    notification_tracking_fields JSONB DEFAULT '{}',
    
    -- Forecast/plan analysis from BDD lines 536-547
    analysis_calculations JSONB DEFAULT '{}',
    rounding_precision INTEGER DEFAULT 2,
    timezone_handling JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. REPORT ACCESS CONTROL
-- =============================================================================

-- Access control from BDD lines 557-569
CREATE TABLE report_access_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    access_id VARCHAR(50) NOT NULL UNIQUE,
    report_id VARCHAR(50) NOT NULL,
    
    -- Role-based access from BDD lines 558-563
    user_role VARCHAR(50) NOT NULL CHECK (user_role IN (
        'system_administrator', 'hr_manager', 'department_manager', 'team_leader', 'operator'
    )),
    access_scope VARCHAR(50) NOT NULL CHECK (access_scope IN (
        'system_wide', 'all_employees', 'department_employees', 'team_members', 'own_data'
    )),
    
    -- Permissions
    can_view BOOLEAN DEFAULT true,
    can_export BOOLEAN DEFAULT false,
    can_schedule BOOLEAN DEFAULT false,
    can_modify BOOLEAN DEFAULT false,
    
    -- Restrictions
    parameter_restrictions JSONB DEFAULT '{}',
    data_restrictions JSONB DEFAULT '{}',
    time_restrictions JSONB DEFAULT '{}',
    
    -- Security measures from BDD lines 565-569
    require_encryption BOOLEAN DEFAULT true,
    audit_access BOOLEAN DEFAULT true,
    validate_parameters BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE CASCADE
);

-- =============================================================================
-- 10. REPORT EXECUTION HISTORY
-- =============================================================================

-- Report execution tracking and audit
CREATE TABLE report_execution_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id VARCHAR(50) NOT NULL UNIQUE,
    report_id VARCHAR(50) NOT NULL,
    
    -- Execution details
    executed_by UUID NOT NULL,
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_duration_seconds INTEGER,
    
    -- Parameters used
    parameter_values JSONB DEFAULT '{}',
    export_format VARCHAR(20),
    
    -- Results
    execution_status VARCHAR(20) DEFAULT 'running' CHECK (execution_status IN (
        'running', 'completed', 'failed', 'cancelled', 'timeout'
    )),
    result_record_count INTEGER,
    result_file_size_bytes BIGINT,
    result_file_path VARCHAR(500),
    
    -- Performance metrics
    query_execution_time_ms INTEGER,
    data_processing_time_ms INTEGER,
    export_generation_time_ms INTEGER,
    
    -- Error information
    error_message TEXT,
    error_details JSONB,
    
    -- Access audit from BDD line 567
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE CASCADE,
    FOREIGN KEY (executed_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 11. REPORT PERFORMANCE MONITORING
-- =============================================================================

-- Performance monitoring from BDD lines 596-624
CREATE TABLE report_performance_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monitoring_id VARCHAR(50) NOT NULL UNIQUE,
    report_id VARCHAR(50) NOT NULL,
    
    -- Performance metrics from BDD lines 597-601
    generation_time_seconds INTEGER,
    concurrent_user_count INTEGER,
    dataset_record_count BIGINT,
    export_time_seconds INTEGER,
    
    -- Resource utilization
    memory_usage_mb INTEGER,
    cpu_usage_percentage DECIMAL(5,2),
    database_connections_used INTEGER,
    
    -- Performance targets from BDD lines 597-601
    meets_generation_target BOOLEAN DEFAULT true, -- <30 seconds
    meets_export_target BOOLEAN DEFAULT true, -- <60 seconds
    
    -- Monitoring timestamp
    monitoring_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    monitoring_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    monitoring_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Optimization recommendations
    optimization_needed BOOLEAN DEFAULT false,
    optimization_recommendations TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE CASCADE
);

-- =============================================================================
-- 12. DATA SOURCE INTEGRATION
-- =============================================================================

-- Data source integration from BDD lines 634-646
CREATE TABLE report_data_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id VARCHAR(50) NOT NULL UNIQUE,
    source_name VARCHAR(200) NOT NULL,
    
    -- Data source types from BDD lines 635-640
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN (
        'personnel_database', 'call_center_integration', 'planning_system', 
        'time_tracking', 'external_system'
    )),
    
    -- Integration method from BDD line 635
    integration_method VARCHAR(50) NOT NULL CHECK (integration_method IN (
        'direct_database_queries', 'real_time_api_calls', 'planning_database_access',
        'status_data_integration', 'external_system_sync'
    )),
    
    -- Connection configuration
    connection_string VARCHAR(500),
    api_endpoint VARCHAR(500),
    authentication_config JSONB DEFAULT '{}',
    
    -- Data consistency from BDD lines 642-646
    consistency_type VARCHAR(30) DEFAULT 'real_time' CHECK (consistency_type IN (
        'real_time', 'historical_accuracy', 'cross_system_sync', 'audit_trail'
    )),
    
    -- Health monitoring
    is_active BOOLEAN DEFAULT true,
    last_successful_connection TIMESTAMP WITH TIME ZONE,
    connection_status VARCHAR(20) DEFAULT 'unknown' CHECK (connection_status IN (
        'connected', 'disconnected', 'error', 'unknown'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 13. REAL-TIME REPORTING CONFIGURATION
-- =============================================================================

-- Real-time reporting from BDD lines 652-663
CREATE TABLE realtime_reporting_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    report_type VARCHAR(50) NOT NULL,
    
    -- Update frequency from BDD lines 653-657
    update_frequency VARCHAR(30) NOT NULL CHECK (update_frequency IN (
        'real_time', '5_minute_intervals', '15_minute_intervals', 'configurable_intervals'
    )),
    
    -- Data source from BDD lines 653-657
    data_source VARCHAR(50) NOT NULL CHECK (data_source IN (
        'live_status_api', 'operational_database', 'authentication_system', 'aggregated_metrics'
    )),
    
    -- Performance requirements from BDD lines 659-663
    max_data_latency_seconds INTEGER DEFAULT 30,
    max_response_time_seconds INTEGER DEFAULT 2,
    max_concurrent_users INTEGER DEFAULT 50,
    
    -- Configuration
    refresh_schedule JSONB DEFAULT '{}',
    caching_strategy VARCHAR(30) DEFAULT 'none' CHECK (caching_strategy IN (
        'none', 'memory', 'redis', 'database'
    )),
    cache_ttl_seconds INTEGER DEFAULT 60,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_update_check TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 14. ERROR HANDLING AND RELIABILITY
-- =============================================================================

-- Error handling from BDD lines 673-685
CREATE TABLE report_error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error_id VARCHAR(50) NOT NULL UNIQUE,
    report_id VARCHAR(50),
    execution_id VARCHAR(50),
    
    -- Error classification from BDD lines 674-679
    error_type VARCHAR(50) NOT NULL CHECK (error_type IN (
        'database_connection_failure', 'query_timeout', 'invalid_parameters',
        'insufficient_permissions', 'data_export_failure'
    )),
    
    -- Error details from BDD lines 681-685
    error_message TEXT NOT NULL,
    error_details JSONB,
    stack_trace TEXT,
    
    -- User context from BDD line 682
    user_id UUID,
    session_context JSONB,
    
    -- System state from BDD line 683
    system_state JSONB,
    performance_metrics JSONB,
    
    -- Error handling
    retry_count INTEGER DEFAULT 0,
    is_resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    FOREIGN KEY (report_id) REFERENCES report_definitions(report_id) ON DELETE SET NULL,
    FOREIGN KEY (execution_id) REFERENCES report_execution_history(execution_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 15. BACKUP AND RECOVERY CONFIGURATION
-- =============================================================================

-- Backup and recovery from BDD lines 691-701
CREATE TABLE report_backup_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    backup_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Backup components from BDD lines 692-696
    backup_component VARCHAR(50) NOT NULL CHECK (backup_component IN (
        'report_definitions', 'generated_reports', 'user_configurations', 'system_settings'
    )),
    
    -- Frequency and retention from BDD lines 692-696
    backup_frequency VARCHAR(20) NOT NULL CHECK (backup_frequency IN (
        'daily', 'weekly', 'after_changes'
    )),
    retention_days INTEGER NOT NULL,
    retention_versions INTEGER,
    
    -- Recovery targets from BDD lines 698-701
    rto_hours INTEGER, -- Recovery Time Objective
    rpo_hours INTEGER, -- Recovery Point Objective
    
    -- Backup configuration
    backup_location VARCHAR(500),
    compression_enabled BOOLEAN DEFAULT true,
    encryption_enabled BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_status VARCHAR(20) DEFAULT 'pending' CHECK (backup_status IN (
        'pending', 'running', 'completed', 'failed'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Report definition queries
CREATE INDEX idx_report_definitions_status ON report_definitions(status) WHERE status = 'published';
CREATE INDEX idx_report_definitions_category ON report_definitions(category);
CREATE INDEX idx_report_definitions_searchable ON report_definitions(is_searchable) WHERE is_searchable = true;

-- Parameter queries
CREATE INDEX idx_report_parameters_report ON report_parameters(report_id);
CREATE INDEX idx_report_parameters_mandatory ON report_parameters(is_mandatory) WHERE is_mandatory = true;

-- Export template queries
CREATE INDEX idx_report_export_templates_report ON report_export_templates(report_id);
CREATE INDEX idx_report_export_templates_format ON report_export_templates(export_format);
CREATE INDEX idx_report_export_templates_active ON report_export_templates(is_active) WHERE is_active = true;

-- Access control queries
CREATE INDEX idx_report_access_control_report ON report_access_control(report_id);
CREATE INDEX idx_report_access_control_role ON report_access_control(user_role);
CREATE INDEX idx_report_access_control_active ON report_access_control(is_active) WHERE is_active = true;

-- Execution history queries
CREATE INDEX idx_report_execution_history_report ON report_execution_history(report_id);
CREATE INDEX idx_report_execution_history_user ON report_execution_history(executed_by);
CREATE INDEX idx_report_execution_history_timestamp ON report_execution_history(execution_timestamp);
CREATE INDEX idx_report_execution_history_status ON report_execution_history(execution_status);

-- Performance monitoring queries
CREATE INDEX idx_report_performance_monitoring_report ON report_performance_monitoring(report_id);
CREATE INDEX idx_report_performance_monitoring_timestamp ON report_performance_monitoring(monitoring_timestamp);
CREATE INDEX idx_report_performance_monitoring_optimization ON report_performance_monitoring(optimization_needed) WHERE optimization_needed = true;

-- Data source queries
CREATE INDEX idx_report_data_sources_type ON report_data_sources(source_type);
CREATE INDEX idx_report_data_sources_status ON report_data_sources(connection_status);
CREATE INDEX idx_report_data_sources_active ON report_data_sources(is_active) WHERE is_active = true;

-- Real-time configuration queries
CREATE INDEX idx_realtime_reporting_config_frequency ON realtime_reporting_config(update_frequency);
CREATE INDEX idx_realtime_reporting_config_active ON realtime_reporting_config(is_active) WHERE is_active = true;

-- Error log queries
CREATE INDEX idx_report_error_logs_type ON report_error_logs(error_type);
CREATE INDEX idx_report_error_logs_occurred ON report_error_logs(occurred_at);
CREATE INDEX idx_report_error_logs_unresolved ON report_error_logs(is_resolved) WHERE is_resolved = false;

-- Backup configuration queries
CREATE INDEX idx_report_backup_config_component ON report_backup_config(backup_component);
CREATE INDEX idx_report_backup_config_frequency ON report_backup_config(backup_frequency);
CREATE INDEX idx_report_backup_config_active ON report_backup_config(is_active) WHERE is_active = true;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_report_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER report_definitions_update_trigger
    BEFORE UPDATE ON report_definitions
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER report_export_templates_update_trigger
    BEFORE UPDATE ON report_export_templates
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER operational_reports_config_update_trigger
    BEFORE UPDATE ON operational_reports_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER personnel_reports_config_update_trigger
    BEFORE UPDATE ON personnel_reports_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER performance_reports_config_update_trigger
    BEFORE UPDATE ON performance_reports_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER planning_reports_config_update_trigger
    BEFORE UPDATE ON planning_reports_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER administrative_reports_config_update_trigger
    BEFORE UPDATE ON administrative_reports_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER report_access_control_update_trigger
    BEFORE UPDATE ON report_access_control
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER report_data_sources_update_trigger
    BEFORE UPDATE ON report_data_sources
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER realtime_reporting_config_update_trigger
    BEFORE UPDATE ON realtime_reporting_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

CREATE TRIGGER report_backup_config_update_trigger
    BEFORE UPDATE ON report_backup_config
    FOR EACH ROW EXECUTE FUNCTION update_report_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Published reports with access control
CREATE VIEW v_published_reports AS
SELECT 
    rd.id,
    rd.report_id,
    rd.report_name,
    rd.report_description,
    rd.category,
    rd.data_source_method,
    rd.required_role,
    rd.data_sensitivity,
    COUNT(rp.id) as parameter_count,
    COUNT(ret.id) as template_count
FROM report_definitions rd
LEFT JOIN report_parameters rp ON rd.report_id = rp.report_id
LEFT JOIN report_export_templates ret ON rd.report_id = ret.report_id AND ret.is_active = true
WHERE rd.status = 'published'
GROUP BY rd.id, rd.report_id, rd.report_name, rd.report_description, rd.category, 
         rd.data_source_method, rd.required_role, rd.data_sensitivity
ORDER BY rd.category, rd.report_name;

-- Report execution performance summary
CREATE VIEW v_report_performance_summary AS
SELECT 
    reh.report_id,
    rd.report_name,
    COUNT(*) as total_executions,
    AVG(reh.execution_duration_seconds) as avg_duration_seconds,
    MAX(reh.execution_duration_seconds) as max_duration_seconds,
    COUNT(CASE WHEN reh.execution_status = 'completed' THEN 1 END) as successful_executions,
    COUNT(CASE WHEN reh.execution_status = 'failed' THEN 1 END) as failed_executions,
    (COUNT(CASE WHEN reh.execution_status = 'completed' THEN 1 END)::DECIMAL / COUNT(*) * 100) as success_rate
FROM report_execution_history reh
JOIN report_definitions rd ON reh.report_id = rd.report_id
WHERE reh.execution_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY reh.report_id, rd.report_name
ORDER BY total_executions DESC;

-- Active data sources health status
CREATE VIEW v_data_sources_health AS
SELECT 
    rds.source_id,
    rds.source_name,
    rds.source_type,
    rds.integration_method,
    rds.connection_status,
    rds.last_successful_connection,
    EXTRACT(HOURS FROM CURRENT_TIMESTAMP - rds.last_successful_connection) as hours_since_last_connection
FROM report_data_sources rds
WHERE rds.is_active = true
ORDER BY rds.connection_status DESC, rds.last_successful_connection DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert sample report definitions
INSERT INTO report_definitions (report_id, report_name, report_description, category, data_source_method, query_definition, created_by) VALUES
('login_logout_report', 'Actual Operator Login/Logout Report', 'Shows login and logout information for employees', 'operational', 'sql', 'SELECT * FROM employee_login_logout_view WHERE date BETWEEN $date_from AND $date_to', (SELECT id FROM employees LIMIT 1)),
('schedule_adherence_report', 'Keeping to the Schedule Report', 'Views planned and actual employee break times', 'operational', 'sql', 'SELECT * FROM schedule_adherence_view WHERE period BETWEEN $period_start AND $period_end', (SELECT id FROM employees LIMIT 1)),
('employee_data_report', 'Report on Existing Employees', 'Comprehensive employee information', 'personnel', 'sql', 'SELECT * FROM existing_employees_view WHERE fired_from >= $fired_from', (SELECT id FROM employees LIMIT 1));

-- Insert sample parameters
INSERT INTO report_parameters (param_id, report_id, parameter_name, parameter_type, is_mandatory) VALUES
('date_from', 'login_logout_report', 'Date from', 'date', true),
('date_to', 'login_logout_report', 'Date to', 'date', true),
('direction_group', 'login_logout_report', 'Direction/Group', 'query_result', true),
('period_start', 'schedule_adherence_report', 'Period Start', 'date', true),
('period_end', 'schedule_adherence_report', 'Period End', 'date', true),
('detailing', 'schedule_adherence_report', 'Detailing', 'numeric_integer', true);

-- Insert sample export templates
INSERT INTO report_export_templates (template_id, report_id, template_name, export_format, use_case) VALUES
('login_logout_xlsx', 'login_logout_report', 'Login/Logout Excel Export', 'xlsx', 'Excel spreadsheets with formulas'),
('login_logout_pdf', 'login_logout_report', 'Login/Logout PDF Export', 'pdf', 'Print-ready documents'),
('schedule_adherence_html', 'schedule_adherence_report', 'Schedule Adherence Web View', 'html', 'Web display with interactive elements');

-- Insert operational reports configuration
INSERT INTO operational_reports_config (config_id, report_type, required_parameters, output_fields) VALUES
('login_logout_config', 'login_logout', '{"date_from": "required", "date_to": "required", "direction_group": "required"}', '{"date": "Date", "direction": "Direction", "full_name": "Full name", "system": "System", "login_time": "Login time", "exit_time": "Time of exit"}'),
('schedule_adherence_config', 'schedule_adherence', '{"period": "required", "detailing": "required", "full_name": "required"}', '{"full_name": "Full name", "avg_sh_adh": "AVG-SH-ADH", "percent_sh_adh": "%SH-ADH", "schedule": "Schedule", "fact": "Fact"}');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE report_definitions IS 'BDD Lines 22-32: Report editor infrastructure with searchable catalog and query builder';
COMMENT ON TABLE report_parameters IS 'BDD Lines 38-49: Report input parameters with all supported types and validation';
COMMENT ON TABLE report_export_templates IS 'BDD Lines 55-62: Export templates for multiple output formats';
COMMENT ON TABLE operational_reports_config IS 'BDD Lines 68-151: Operational reports configuration for login, schedule, lateness, and absenteeism';
COMMENT ON TABLE personnel_reports_config IS 'BDD Lines 157-258: Personnel reports for employee data, vacations, and changes';
COMMENT ON TABLE performance_reports_config IS 'BDD Lines 264-340: Performance reports for AHT, ready percentage, and load analysis';
COMMENT ON TABLE planning_reports_config IS 'BDD Lines 345-466: Planning reports for forecasts, budget, schedules, and preferences';
COMMENT ON TABLE administrative_reports_config IS 'BDD Lines 471-547: Administrative reports for logging, notifications, and acknowledgments';
COMMENT ON TABLE report_access_control IS 'BDD Lines 557-569: Role-based access control and security measures';
COMMENT ON TABLE report_execution_history IS 'Report execution tracking and audit trail for compliance';
COMMENT ON TABLE report_performance_monitoring IS 'BDD Lines 596-624: Performance monitoring for enterprise scale';
COMMENT ON TABLE report_data_sources IS 'BDD Lines 634-646: Integration with all system data sources';
COMMENT ON TABLE realtime_reporting_config IS 'BDD Lines 652-663: Real-time reporting capabilities configuration';
COMMENT ON TABLE report_error_logs IS 'BDD Lines 673-685: Comprehensive error handling and logging';
COMMENT ON TABLE report_backup_config IS 'BDD Lines 691-701: Backup and recovery configuration';