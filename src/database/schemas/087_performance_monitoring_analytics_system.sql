-- Schema 087: Performance Monitoring and Analytics System
-- Comprehensive real-time performance tracking with Russian compliance
-- Integrates BDD scenarios: reporting, monitoring, efficiency, forecasting
-- Enterprise-scale analytics with multi-dimensional performance metrics

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================================================
-- 1. PERFORMANCE METRIC DEFINITIONS
-- ============================================================================

-- Define all performance metrics that can be tracked
CREATE TABLE performance_metric_definitions (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_code VARCHAR(100) UNIQUE NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    metric_name_ru VARCHAR(255) NOT NULL,
    metric_category VARCHAR(50) NOT NULL, -- productivity, quality, efficiency, compliance, forecast_accuracy
    metric_type VARCHAR(50) NOT NULL, -- percentage, count, duration, ratio, score
    measurement_unit VARCHAR(50), -- seconds, minutes, percentage, count, rubles
    measurement_unit_ru VARCHAR(50),
    calculation_formula TEXT, -- Formula for calculated metrics
    target_value DECIMAL(10,4), -- Target/threshold value
    threshold_critical DECIMAL(10,4), -- Critical threshold
    threshold_warning DECIMAL(10,4), -- Warning threshold
    is_realtime BOOLEAN DEFAULT false, -- Can be calculated in real-time
    aggregation_level VARCHAR(50), -- individual, team, department, company
    description TEXT,
    description_ru TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. REAL-TIME PERFORMANCE MONITORING
-- ============================================================================

-- Real-time performance data collection
CREATE TABLE performance_realtime_data (
    data_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    employee_id UUID, -- NULL for aggregate metrics
    department_id UUID,
    team_id UUID,
    measurement_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metric_value DECIMAL(15,4) NOT NULL,
    measurement_interval VARCHAR(20), -- 1min, 5min, 15min, 30min, 1hour
    data_source VARCHAR(100), -- telephony, manual, calculated, system
    source_system VARCHAR(100), -- argus, 1c, cvc, custom
    session_id VARCHAR(255), -- For tracking related measurements
    quality_score DECIMAL(5,2), -- Data quality score (0-100)
    tags JSONB, -- Additional metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_perf_realtime_timestamp (measurement_timestamp),
    INDEX idx_perf_realtime_employee (employee_id, measurement_timestamp),
    INDEX idx_perf_realtime_metric (metric_id, measurement_timestamp)
);

-- Partition the real-time data table by measurement_timestamp for performance
-- This enables efficient querying of recent data
CREATE TABLE performance_realtime_data_current 
    PARTITION OF performance_realtime_data 
    FOR VALUES FROM (CURRENT_DATE) TO (CURRENT_DATE + INTERVAL '1 day');

-- ============================================================================
-- 3. HISTORICAL PERFORMANCE ANALYTICS
-- ============================================================================

-- Aggregated historical performance data for analytics
CREATE TABLE performance_historical_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    employee_id UUID,
    department_id UUID,
    team_id UUID,
    analysis_date DATE NOT NULL,
    analysis_period VARCHAR(20), -- daily, weekly, monthly, quarterly, yearly
    metric_value DECIMAL(15,4) NOT NULL,
    target_achievement_pct DECIMAL(5,2), -- Percentage of target achieved
    trend_direction VARCHAR(20), -- improving, declining, stable
    trend_strength DECIMAL(5,2), -- Strength of trend (0-100)
    percentile_rank DECIMAL(5,2), -- Rank within peer group
    z_score DECIMAL(10,4), -- Standard deviations from mean
    moving_average_7d DECIMAL(15,4), -- 7-day moving average
    moving_average_30d DECIMAL(15,4), -- 30-day moving average
    seasonal_adjustment DECIMAL(10,4), -- Seasonal factor
    data_quality_flags VARCHAR(500), -- Quality indicators
    calculation_metadata JSONB, -- Additional calculation details
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_perf_historical_date (analysis_date, metric_id),
    INDEX idx_perf_historical_employee (employee_id, analysis_date)
);

-- ============================================================================
-- 4. PERFORMANCE BENCHMARKING AND COMPARISONS
-- ============================================================================

-- Benchmark data for performance comparisons
CREATE TABLE performance_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    benchmark_type VARCHAR(50), -- industry, company, department, team, historical
    benchmark_name VARCHAR(255) NOT NULL,
    benchmark_name_ru VARCHAR(255),
    benchmark_value DECIMAL(15,4) NOT NULL,
    benchmark_percentile DECIMAL(5,2), -- Which percentile this represents
    data_source VARCHAR(100),
    effective_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    geographic_scope VARCHAR(100), -- russia, moscow, regions, etc.
    industry_sector VARCHAR(100),
    company_size_category VARCHAR(50), -- small, medium, large, enterprise
    notes TEXT,
    notes_ru TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance comparison results
CREATE TABLE performance_comparisons (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    benchmark_id UUID REFERENCES performance_benchmarks(benchmark_id),
    comparison_date DATE DEFAULT CURRENT_DATE,
    employee_value DECIMAL(15,4) NOT NULL,
    benchmark_value DECIMAL(15,4) NOT NULL,
    variance_absolute DECIMAL(15,4), -- Absolute difference
    variance_percentage DECIMAL(10,2), -- Percentage difference
    performance_rating VARCHAR(50), -- excellent, good, average, below_average, poor
    improvement_target DECIMAL(15,4), -- Suggested improvement target
    gap_analysis TEXT, -- Analysis of performance gap
    gap_analysis_ru TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 5. PERFORMANCE ALERTS AND NOTIFICATIONS
-- ============================================================================

-- Performance alert rules configuration
CREATE TABLE performance_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255) NOT NULL,
    rule_name_ru VARCHAR(255),
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    alert_condition VARCHAR(50), -- above_threshold, below_threshold, outside_range, trend_change
    threshold_value DECIMAL(15,4),
    threshold_upper DECIMAL(15,4), -- For range conditions
    threshold_lower DECIMAL(15,4), -- For range conditions
    severity_level VARCHAR(20), -- info, warning, critical
    trigger_frequency VARCHAR(50), -- immediate, daily, weekly, monthly
    notification_channels VARCHAR(500), -- email, sms, push, dashboard
    target_roles VARCHAR(500), -- JSON array of role codes
    target_users VARCHAR(500), -- JSON array of user IDs
    escalation_rules JSONB, -- Escalation configuration
    is_active BOOLEAN DEFAULT true,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance alerts generated by the system
CREATE TABLE performance_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID REFERENCES performance_alert_rules(rule_id),
    employee_id UUID,
    department_id UUID,
    team_id UUID,
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    alert_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    severity_level VARCHAR(20),
    alert_message TEXT NOT NULL,
    alert_message_ru TEXT,
    current_value DECIMAL(15,4),
    threshold_value DECIMAL(15,4),
    variance_from_threshold DECIMAL(15,4),
    status VARCHAR(50) DEFAULT 'new', -- new, acknowledged, resolved, escalated
    acknowledged_by VARCHAR(255),
    acknowledged_at TIMESTAMP,
    resolved_by VARCHAR(255),
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    escalated_to VARCHAR(255),
    escalated_at TIMESTAMP,
    notification_sent BOOLEAN DEFAULT false,
    related_data JSONB, -- Additional context data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 6. PERFORMANCE DASHBOARD CONFIGURATIONS
-- ============================================================================

-- Dashboard configurations for performance monitoring
CREATE TABLE performance_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_code VARCHAR(100) UNIQUE NOT NULL,
    dashboard_name VARCHAR(255) NOT NULL,
    dashboard_name_ru VARCHAR(255),
    dashboard_type VARCHAR(50), -- realtime, analytical, executive, operational
    target_audience VARCHAR(100), -- agents, supervisors, managers, executives
    refresh_interval INTEGER DEFAULT 300, -- Seconds
    layout_config JSONB, -- Dashboard layout configuration
    widget_config JSONB, -- Widget configurations
    filter_config JSONB, -- Default filter settings
    access_permissions JSONB, -- Role-based access control
    is_public BOOLEAN DEFAULT false,
    is_default BOOLEAN DEFAULT false,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Widget definitions for dashboards
CREATE TABLE performance_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID REFERENCES performance_dashboards(dashboard_id) ON DELETE CASCADE,
    widget_code VARCHAR(100) NOT NULL,
    widget_name VARCHAR(255) NOT NULL,
    widget_name_ru VARCHAR(255),
    widget_type VARCHAR(50), -- chart, gauge, table, kpi, trend, comparison
    position_x INTEGER DEFAULT 0,
    position_y INTEGER DEFAULT 0,
    width INTEGER DEFAULT 4,
    height INTEGER DEFAULT 3,
    metric_ids JSONB, -- Array of metric IDs to display
    chart_config JSONB, -- Chart-specific configuration
    display_config JSONB, -- Display options
    filter_config JSONB, -- Widget-specific filters
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 7. PERFORMANCE FORECASTING AND PREDICTIONS
-- ============================================================================

-- Performance forecast models configuration
CREATE TABLE performance_forecast_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(255) NOT NULL,
    model_name_ru VARCHAR(255),
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    model_type VARCHAR(50), -- linear_regression, arima, seasonal, ml_ensemble
    model_parameters JSONB, -- Model-specific parameters
    training_data_period INTEGER DEFAULT 90, -- Days of historical data
    forecast_horizon INTEGER DEFAULT 30, -- Days to forecast ahead
    accuracy_score DECIMAL(5,2), -- Model accuracy percentage
    last_trained_at TIMESTAMP,
    training_frequency VARCHAR(50), -- daily, weekly, monthly
    seasonal_factors JSONB, -- Seasonal adjustment factors
    external_factors JSONB, -- External variables considered
    model_status VARCHAR(50) DEFAULT 'active', -- active, training, deprecated
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance forecasts generated by models
CREATE TABLE performance_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID REFERENCES performance_forecast_models(model_id),
    employee_id UUID,
    department_id UUID,
    team_id UUID,
    forecast_date DATE NOT NULL,
    forecast_period VARCHAR(20), -- daily, weekly, monthly
    predicted_value DECIMAL(15,4) NOT NULL,
    confidence_interval_lower DECIMAL(15,4),
    confidence_interval_upper DECIMAL(15,4),
    confidence_level DECIMAL(5,2) DEFAULT 95.0, -- 95% confidence interval
    prediction_factors JSONB, -- Factors influencing prediction
    actual_value DECIMAL(15,4), -- Filled when actual data becomes available
    forecast_accuracy DECIMAL(5,2), -- Accuracy once actual is known
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_perf_forecast_date (forecast_date, model_id),
    INDEX idx_perf_forecast_employee (employee_id, forecast_date)
);

-- ============================================================================
-- 8. PERFORMANCE REPORTING FRAMEWORK
-- ============================================================================

-- Performance report templates
CREATE TABLE performance_report_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_code VARCHAR(100) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    template_name_ru VARCHAR(255),
    report_category VARCHAR(100), -- operational, analytical, compliance, executive
    template_type VARCHAR(50), -- tabular, chart, mixed, executive_summary
    metric_definitions JSONB, -- Metrics included in report
    layout_template TEXT, -- HTML/template layout
    calculation_logic JSONB, -- Calculation procedures
    filter_options JSONB, -- Available filter options
    export_formats VARCHAR(200), -- Supported export formats
    schedule_options JSONB, -- Scheduling configuration
    recipients_config JSONB, -- Default recipients
    is_standard BOOLEAN DEFAULT false, -- Standard system template
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance report instances/executions
CREATE TABLE performance_report_instances (
    instance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID REFERENCES performance_report_templates(template_id),
    report_name VARCHAR(255) NOT NULL,
    report_period_start DATE NOT NULL,
    report_period_end DATE NOT NULL,
    generation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(255),
    report_parameters JSONB, -- Parameters used for generation
    report_data JSONB, -- Generated report data
    report_file_path TEXT, -- Path to generated file
    export_format VARCHAR(20), -- Final export format
    file_size_bytes BIGINT,
    generation_duration_ms INTEGER, -- Time taken to generate
    status VARCHAR(50) DEFAULT 'generating', -- generating, completed, failed
    error_message TEXT,
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP,
    expires_at TIMESTAMP, -- Report expiration date
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 9. PERFORMANCE AUDIT AND COMPLIANCE
-- ============================================================================

-- Performance audit trails for compliance
CREATE TABLE performance_audit_trails (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    audit_type VARCHAR(50), -- data_access, calculation, modification, report_generation
    user_id VARCHAR(255) NOT NULL,
    user_role VARCHAR(100),
    action_performed VARCHAR(255) NOT NULL,
    table_affected VARCHAR(100),
    record_id UUID,
    old_values JSONB, -- Before values
    new_values JSONB, -- After values
    calculation_details JSONB, -- For calculation audits
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    business_justification TEXT, -- Why the action was performed
    compliance_notes TEXT, -- Compliance-related notes
    retention_period INTEGER DEFAULT 2555, -- Days to retain (7 years default)
    is_sensitive BOOLEAN DEFAULT false, -- Contains sensitive data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance compliance checks
CREATE TABLE performance_compliance_checks (
    check_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    check_name VARCHAR(255) NOT NULL,
    check_name_ru VARCHAR(255),
    compliance_framework VARCHAR(100), -- gdpr, russian_labor_law, iso27001, internal
    check_type VARCHAR(50), -- data_protection, access_control, calculation_accuracy, audit_trail
    check_description TEXT,
    check_description_ru TEXT,
    check_query TEXT, -- SQL query to perform the check
    success_criteria TEXT, -- What constitutes a successful check
    failure_action VARCHAR(100), -- What to do if check fails
    check_frequency VARCHAR(50), -- daily, weekly, monthly, quarterly
    last_executed_at TIMESTAMP,
    next_execution_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Results of compliance checks
CREATE TABLE performance_compliance_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    check_id UUID REFERENCES performance_compliance_checks(check_id),
    execution_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_status VARCHAR(50), -- passed, failed, warning, error
    result_details JSONB, -- Detailed results
    issues_found INTEGER DEFAULT 0,
    records_checked INTEGER,
    execution_time_ms INTEGER,
    recommendations TEXT, -- Recommendations for failed checks
    recommendations_ru TEXT,
    remediation_required BOOLEAN DEFAULT false,
    remediation_deadline DATE,
    remediated_by VARCHAR(255),
    remediated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 10. INDEXES FOR OPTIMAL PERFORMANCE
-- ============================================================================

-- Indexes for real-time data queries
CREATE INDEX CONCURRENTLY idx_perf_realtime_employee_metric 
    ON performance_realtime_data (employee_id, metric_id, measurement_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_perf_realtime_dept_timestamp 
    ON performance_realtime_data (department_id, measurement_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_perf_realtime_tags 
    ON performance_realtime_data USING GIN (tags);

-- Indexes for historical analytics
CREATE INDEX CONCURRENTLY idx_perf_historical_employee_period 
    ON performance_historical_analytics (employee_id, analysis_period, analysis_date DESC);

CREATE INDEX CONCURRENTLY idx_perf_historical_metric_date 
    ON performance_historical_analytics (metric_id, analysis_date DESC);

-- Indexes for forecasting
CREATE INDEX CONCURRENTLY idx_perf_forecast_model_date 
    ON performance_forecasts (model_id, forecast_date);

CREATE INDEX CONCURRENTLY idx_perf_forecast_employee_future 
    ON performance_forecasts (employee_id, forecast_date) 
    WHERE forecast_date >= CURRENT_DATE;

-- Indexes for alerts
CREATE INDEX CONCURRENTLY idx_perf_alerts_status_timestamp 
    ON performance_alerts (status, alert_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_perf_alerts_employee_recent 
    ON performance_alerts (employee_id, alert_timestamp DESC) 
    WHERE status IN ('new', 'acknowledged');

-- Indexes for audit trails
CREATE INDEX CONCURRENTLY idx_perf_audit_user_timestamp 
    ON performance_audit_trails (user_id, audit_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_perf_audit_table_timestamp 
    ON performance_audit_trails (table_affected, audit_timestamp DESC);

-- ============================================================================
-- 11. VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Real-time performance summary view
CREATE VIEW performance_realtime_summary AS
SELECT 
    prd.employee_id,
    pmd.metric_code,
    pmd.metric_name_ru,
    prd.metric_value,
    pmd.target_value,
    CASE 
        WHEN pmd.target_value IS NOT NULL THEN 
            ROUND((prd.metric_value / pmd.target_value * 100)::NUMERIC, 2)
        ELSE NULL 
    END as target_achievement_pct,
    CASE 
        WHEN prd.metric_value >= pmd.threshold_critical THEN 'excellent'
        WHEN prd.metric_value >= pmd.threshold_warning THEN 'good'
        ELSE 'needs_improvement'
    END as performance_rating,
    prd.measurement_timestamp,
    prd.data_source
FROM performance_realtime_data prd
JOIN performance_metric_definitions pmd ON prd.metric_id = pmd.metric_id
WHERE prd.measurement_timestamp >= CURRENT_DATE
    AND pmd.is_active = true;

-- Department performance dashboard view
CREATE VIEW performance_department_dashboard AS
SELECT 
    prd.department_id,
    pmd.metric_category,
    pmd.metric_name_ru,
    COUNT(*) as measurement_count,
    AVG(prd.metric_value) as avg_value,
    MIN(prd.metric_value) as min_value,
    MAX(prd.metric_value) as max_value,
    STDDEV(prd.metric_value) as std_deviation,
    AVG(CASE WHEN pmd.target_value IS NOT NULL 
        THEN (prd.metric_value / pmd.target_value * 100) 
        ELSE NULL END) as avg_target_achievement,
    DATE_TRUNC('hour', prd.measurement_timestamp) as hour_period
FROM performance_realtime_data prd
JOIN performance_metric_definitions pmd ON prd.metric_id = pmd.metric_id
WHERE prd.measurement_timestamp >= CURRENT_DATE - INTERVAL '24 hours'
    AND prd.department_id IS NOT NULL
    AND pmd.is_active = true
GROUP BY prd.department_id, pmd.metric_category, pmd.metric_name_ru, 
         DATE_TRUNC('hour', prd.measurement_timestamp);

-- Performance trend analysis view
CREATE VIEW performance_trend_analysis AS
SELECT 
    pha.employee_id,
    pha.metric_id,
    pmd.metric_name_ru,
    pha.analysis_date,
    pha.metric_value,
    pha.moving_average_7d,
    pha.moving_average_30d,
    pha.trend_direction,
    pha.trend_strength,
    LAG(pha.metric_value, 1) OVER (
        PARTITION BY pha.employee_id, pha.metric_id 
        ORDER BY pha.analysis_date
    ) as previous_value,
    CASE 
        WHEN LAG(pha.metric_value, 1) OVER (
            PARTITION BY pha.employee_id, pha.metric_id 
            ORDER BY pha.analysis_date
        ) IS NOT NULL THEN
            ROUND(
                ((pha.metric_value - LAG(pha.metric_value, 1) OVER (
                    PARTITION BY pha.employee_id, pha.metric_id 
                    ORDER BY pha.analysis_date
                )) / LAG(pha.metric_value, 1) OVER (
                    PARTITION BY pha.employee_id, pha.metric_id 
                    ORDER BY pha.analysis_date
                ) * 100)::NUMERIC, 2
            )
        ELSE NULL
    END as daily_change_pct
FROM performance_historical_analytics pha
JOIN performance_metric_definitions pmd ON pha.metric_id = pmd.metric_id
WHERE pha.analysis_date >= CURRENT_DATE - INTERVAL '90 days'
    AND pmd.is_active = true;

-- ============================================================================
-- 12. RUSSIAN BUSINESS COMPLIANCE AND LOCALIZATION
-- ============================================================================

-- Russian performance standards table
CREATE TABLE russian_performance_standards (
    standard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    standard_code VARCHAR(100) UNIQUE NOT NULL,
    standard_name_ru VARCHAR(255) NOT NULL,
    regulatory_framework VARCHAR(100), -- trudovoy_kodeks, gost, industry_standard
    metric_id UUID REFERENCES performance_metric_definitions(metric_id),
    minimum_value DECIMAL(15,4), -- Minimum required by law/standard
    recommended_value DECIMAL(15,4), -- Recommended best practice
    measurement_frequency VARCHAR(50), -- How often to measure
    reporting_requirement VARCHAR(200), -- Reporting obligations
    penalty_for_non_compliance TEXT, -- Consequences of non-compliance
    effective_date DATE DEFAULT CURRENT_DATE,
    revision_date DATE,
    authority_source VARCHAR(200), -- Which authority issued the standard
    documentation_link TEXT, -- Link to official documentation
    is_mandatory BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 13. COMMENTS AND DOCUMENTATION
-- ============================================================================

-- Add comprehensive comments for documentation
COMMENT ON TABLE performance_metric_definitions IS 'Defines all performance metrics that can be tracked in the system';
COMMENT ON TABLE performance_realtime_data IS 'Real-time performance measurements with partitioning for scalability';
COMMENT ON TABLE performance_historical_analytics IS 'Aggregated historical performance data for trend analysis';
COMMENT ON TABLE performance_alerts IS 'System-generated performance alerts and notifications';
COMMENT ON TABLE performance_dashboards IS 'Dashboard configurations for performance monitoring interfaces';
COMMENT ON TABLE performance_forecasts IS 'AI/ML-generated performance predictions and forecasts';
COMMENT ON TABLE performance_audit_trails IS 'Complete audit trail for compliance and security';
COMMENT ON TABLE russian_performance_standards IS 'Russian regulatory compliance and performance standards';

-- ============================================================================
-- 14. RUSSIAN LANGUAGE SUPPORT AND SAMPLE DATA
-- ============================================================================

-- Insert sample performance metrics with Russian localization
INSERT INTO performance_metric_definitions (
    metric_code, metric_name, metric_name_ru, metric_category, metric_type,
    measurement_unit, measurement_unit_ru, target_value, threshold_critical, threshold_warning,
    is_realtime, aggregation_level, description, description_ru, is_active
) VALUES 
-- Productivity metrics
('AHT', 'Average Handle Time', 'Среднее время обработки', 'productivity', 'duration', 
 'seconds', 'секунды', 180, 300, 240, true, 'individual', 
 'Average time to handle customer requests', 'Среднее время обработки обращений клиентов', true),

('FCR', 'First Call Resolution', 'Решение с первого обращения', 'quality', 'percentage', 
 'percentage', 'процент', 85, 95, 90, true, 'individual',
 'Percentage of issues resolved on first contact', 'Процент вопросов, решенных с первого обращения', true),

('OCCUPANCY', 'Occupancy Rate', 'Коэффициент занятости', 'efficiency', 'percentage',
 'percentage', 'процент', 80, 90, 85, true, 'individual',
 'Percentage of logged time spent on productive activities', 'Процент рабочего времени в продуктивных статусах', true),

('ADHERENCE', 'Schedule Adherence', 'Соблюдение расписания', 'compliance', 'percentage',
 'percentage', 'процент', 95, 98, 96, true, 'individual',
 'Percentage of time following scheduled activities', 'Процент соблюдения запланированного расписания', true),

-- Quality metrics  
('CSAT', 'Customer Satisfaction', 'Удовлетворенность клиентов', 'quality', 'score',
 'score', 'балл', 4.5, 4.8, 4.6, false, 'individual',
 'Customer satisfaction rating (1-5 scale)', 'Оценка удовлетворенности клиентов (шкала 1-5)', true),

('QA_SCORE', 'Quality Assurance Score', 'Оценка качества', 'quality', 'percentage',
 'percentage', 'процент', 90, 95, 92, false, 'individual',
 'Quality assessment score from monitoring', 'Оценка качества по результатам мониторинга', true),

-- Efficiency metrics
('CALLS_PER_HOUR', 'Calls Per Hour', 'Звонков в час', 'productivity', 'count',
 'calls', 'звонки', 12, 15, 13, true, 'individual',
 'Number of calls handled per hour', 'Количество обработанных звонков в час', true),

('WRAP_TIME', 'After Call Work Time', 'Время послеобработки', 'productivity', 'duration',
 'seconds', 'секунды', 60, 30, 45, true, 'individual',
 'Time spent on after-call activities', 'Время на послеобработку после звонка', true);

-- Insert sample dashboard configurations
INSERT INTO performance_dashboards (
    dashboard_code, dashboard_name, dashboard_name_ru, dashboard_type, target_audience,
    refresh_interval, layout_config, is_public, is_default
) VALUES 
('REALTIME_OPS', 'Real-time Operations Dashboard', 'Панель оперативного мониторинга', 
 'realtime', 'supervisors', 60, 
 '{"grid_size": "12x8", "widgets": ["current_metrics", "alerts", "team_status"]}', 
 true, true),

('EXECUTIVE_SUMMARY', 'Executive Performance Summary', 'Сводка для руководства',
 'executive', 'executives', 3600,
 '{"grid_size": "12x6", "widgets": ["kpi_summary", "trends", "forecasts"]}',
 false, false),

('AGENT_PERSONAL', 'Agent Personal Dashboard', 'Личная панель сотрудника',
 'analytical', 'agents', 300,
 '{"grid_size": "8x6", "widgets": ["personal_metrics", "goals", "development"]}',
 true, false);

-- Insert sample alert rules
INSERT INTO performance_alert_rules (
    rule_name, rule_name_ru, metric_id, alert_condition, threshold_value,
    severity_level, trigger_frequency, notification_channels, is_active
) VALUES 
('AHT Critical Threshold', 'Критический порог времени обработки',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
 'above_threshold', 300, 'critical', 'immediate', 'email,dashboard', true),

('Low Schedule Adherence', 'Низкое соблюдение расписания',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'ADHERENCE'),
 'below_threshold', 90, 'warning', 'daily', 'email,push', true),

('Quality Score Alert', 'Предупреждение по качеству',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'QA_SCORE'),
 'below_threshold', 85, 'warning', 'weekly', 'email', true);

-- Insert Russian performance standards
INSERT INTO russian_performance_standards (
    standard_code, standard_name_ru, regulatory_framework, metric_id,
    minimum_value, recommended_value, measurement_frequency, reporting_requirement,
    is_mandatory
) VALUES 
('TK_WORK_EFFICIENCY', 'Эффективность трудовой деятельности', 'trudovoy_kodeks',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'OCCUPANCY'),
 75, 85, 'daily', 'Monthly reporting to management', true),

('GOST_QUALITY_STANDARD', 'Стандарт качества обслуживания', 'gost',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'CSAT'),
 4.0, 4.5, 'weekly', 'Quarterly compliance reports', true),

('SCHEDULE_COMPLIANCE', 'Соблюдение трудового распорядка', 'trudovoy_kodeks',
 (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'ADHERENCE'),
 90, 95, 'daily', 'Incident reports for violations', true);

-- ============================================================================
-- 15. PERFORMANCE OPTIMIZATION FUNCTIONS
-- ============================================================================

-- Function to calculate real-time performance scores
CREATE OR REPLACE FUNCTION calculate_realtime_performance_score(
    p_employee_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_score DECIMAL(5,2) := 0;
    v_metric_count INTEGER := 0;
    v_weighted_sum DECIMAL(10,4) := 0;
    metric_record RECORD;
BEGIN
    -- Calculate weighted performance score based on all metrics
    FOR metric_record IN 
        SELECT 
            pmd.metric_code,
            pmd.target_value,
            prd.metric_value,
            CASE pmd.metric_category
                WHEN 'quality' THEN 0.3
                WHEN 'productivity' THEN 0.25
                WHEN 'efficiency' THEN 0.25
                WHEN 'compliance' THEN 0.2
                ELSE 0.1
            END as weight
        FROM performance_realtime_data prd
        JOIN performance_metric_definitions pmd ON prd.metric_id = pmd.metric_id
        WHERE prd.employee_id = p_employee_id
            AND DATE(prd.measurement_timestamp) = p_calculation_date
            AND pmd.target_value IS NOT NULL
            AND pmd.is_active = true
        ORDER BY prd.measurement_timestamp DESC
    LOOP
        v_metric_count := v_metric_count + 1;
        
        -- Calculate achievement percentage for this metric
        v_weighted_sum := v_weighted_sum + 
            (LEAST(metric_record.metric_value / metric_record.target_value, 1.2) * 100 * metric_record.weight);
    END LOOP;
    
    -- Return weighted average score (max 100)
    IF v_metric_count > 0 THEN
        v_score := LEAST(v_weighted_sum, 100);
    END IF;
    
    RETURN ROUND(v_score, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to generate performance alerts
CREATE OR REPLACE FUNCTION generate_performance_alerts() RETURNS INTEGER AS $$
DECLARE
    v_alerts_generated INTEGER := 0;
    alert_rule RECORD;
    current_value DECIMAL(15,4);
    should_alert BOOLEAN := false;
BEGIN
    -- Check all active alert rules
    FOR alert_rule IN 
        SELECT 
            par.rule_id,
            par.rule_name,
            par.metric_id,
            par.alert_condition,
            par.threshold_value,
            par.threshold_upper,
            par.threshold_lower,
            par.severity_level,
            pmd.metric_name_ru
        FROM performance_alert_rules par
        JOIN performance_metric_definitions pmd ON par.metric_id = pmd.metric_id
        WHERE par.is_active = true
    LOOP
        -- Get latest metric values that might trigger alerts
        FOR current_value IN 
            SELECT prd.metric_value
            FROM performance_realtime_data prd
            WHERE prd.metric_id = alert_rule.metric_id
                AND prd.measurement_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
            ORDER BY prd.measurement_timestamp DESC
            LIMIT 10
        LOOP
            should_alert := false;
            
            -- Check alert condition
            CASE alert_rule.alert_condition
                WHEN 'above_threshold' THEN
                    should_alert := current_value > alert_rule.threshold_value;
                WHEN 'below_threshold' THEN
                    should_alert := current_value < alert_rule.threshold_value;
                WHEN 'outside_range' THEN
                    should_alert := current_value < alert_rule.threshold_lower 
                                 OR current_value > alert_rule.threshold_upper;
            END CASE;
            
            -- Generate alert if condition is met
            IF should_alert THEN
                INSERT INTO performance_alerts (
                    rule_id, metric_id, alert_timestamp, severity_level,
                    alert_message, alert_message_ru, current_value, threshold_value,
                    variance_from_threshold
                ) VALUES (
                    alert_rule.rule_id,
                    alert_rule.metric_id,
                    CURRENT_TIMESTAMP,
                    alert_rule.severity_level,
                    format('Performance alert: %s threshold exceeded', alert_rule.rule_name),
                    format('Предупреждение: превышен порог для %s', alert_rule.metric_name_ru),
                    current_value,
                    alert_rule.threshold_value,
                    current_value - alert_rule.threshold_value
                );
                
                v_alerts_generated := v_alerts_generated + 1;
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN v_alerts_generated;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SCHEMA SUMMARY
-- ============================================================================

/*
Schema 087: Performance Monitoring and Analytics System

This comprehensive schema implements:

1. Real-time Performance Monitoring
   - Live metric collection with partitioning
   - Multi-dimensional performance tracking
   - Configurable alert system

2. Historical Analytics and Trends
   - Aggregated performance data
   - Trend analysis with moving averages
   - Comparative benchmarking

3. Performance Forecasting
   - ML-based prediction models
   - Confidence intervals and accuracy tracking
   - Seasonal adjustment factors

4. Dashboard and Reporting Framework
   - Configurable performance dashboards
   - Flexible report templates
   - Multi-format export capabilities

5. Russian Business Compliance
   - Russian regulatory standards integration
   - Localized metrics and descriptions
   - Compliance checking and reporting

6. Enterprise Features
   - Comprehensive audit trails
   - Role-based access control
   - Performance optimization indexes

Key Benefits:
- Real-time performance visibility
- Predictive analytics capabilities
- Russian regulatory compliance
- Scalable architecture for enterprise use
- Comprehensive audit and security features

This schema supports BDD scenarios from:
- Comprehensive Reporting System (BDD 23)
- Real-time Monitoring (BDD 15)
- Work Time Efficiency (BDD 29)
- Performance Analytics requirements

Total Tables: 16 core tables + 3 views
Estimated Storage: Scalable with partitioning
Performance: Optimized with 15+ indexes
*/