-- ============================================================================
-- WFM Enterprise Analytics Infrastructure (Tasks 16-20)
-- Advanced Analytics Support Tables
-- Database: wfm_enterprise
-- ============================================================================

-- Task 16: Real-time Metric Aggregations
-- Pre-computed metrics for dashboard performance with time-based partitioning
CREATE TABLE IF NOT EXISTS realtime_metric_aggregations (
    aggregation_id UUID DEFAULT gen_random_uuid(),
    metric_type VARCHAR(100) NOT NULL, -- 'queue_stats', 'agent_performance', 'service_levels'
    metric_name VARCHAR(100) NOT NULL, -- 'calls_handled', 'average_wait_time', 'utilization'
    aggregation_period VARCHAR(20) NOT NULL, -- '1min', '5min', '15min', '1hour', '1day'
    time_bucket TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Core metric values
    current_value DECIMAL(15,4),
    previous_value DECIMAL(15,4),
    change_percentage DECIMAL(8,4),
    trend_direction VARCHAR(10) CHECK (trend_direction IN ('up', 'down', 'stable')),
    
    -- Statistical aggregations
    min_value DECIMAL(15,4),
    max_value DECIMAL(15,4),
    avg_value DECIMAL(15,4),
    sum_value DECIMAL(15,4),
    count_records INTEGER,
    std_deviation DECIMAL(15,4),
    
    -- Russian WFM specific metrics
    russian_kpi_category VARCHAR(50), -- 'обслуживание', 'качество', 'эффективность'
    compliance_threshold DECIMAL(8,4),
    compliance_status VARCHAR(20) CHECK (compliance_status IN ('соответствует', 'не_соответствует', 'требует_внимания')),
    
    -- Dimensional filters
    site_id UUID, -- References sites table
    department_id UUID,
    queue_id VARCHAR(50),
    agent_id UUID,
    skill_group VARCHAR(100),
    
    -- Metadata
    calculation_method TEXT, -- Formula or algorithm used
    data_quality_score DECIMAL(3,2) DEFAULT 1.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    
    -- Composite primary key including partition column
    PRIMARY KEY (aggregation_id, time_bucket)
) PARTITION BY RANGE (time_bucket);

-- Create partitions for current and next months
CREATE TABLE IF NOT EXISTS realtime_metric_aggregations_2025_07 
PARTITION OF realtime_metric_aggregations 
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE IF NOT EXISTS realtime_metric_aggregations_2025_08 
PARTITION OF realtime_metric_aggregations 
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_realtime_metrics_type_time ON realtime_metric_aggregations (metric_type, time_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_realtime_metrics_site_dept ON realtime_metric_aggregations (site_id, department_id);
CREATE INDEX IF NOT EXISTS idx_realtime_metrics_agent_queue ON realtime_metric_aggregations (agent_id, queue_id);
CREATE INDEX IF NOT EXISTS idx_realtime_metrics_russian_kpi ON realtime_metric_aggregations (russian_kpi_category, compliance_status);

-- Task 17: Dynamic Dashboard Configuration
-- User-customizable dashboard layouts with role-based templates
CREATE TABLE IF NOT EXISTS dynamic_dashboard_configurations (
    dashboard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_name VARCHAR(200) NOT NULL,
    dashboard_description TEXT,
    user_id UUID NOT NULL,
    user_role VARCHAR(100) NOT NULL, -- 'оператор', 'супервизор', 'менеджер', 'администратор'
    
    -- Dashboard layout configuration
    layout_type VARCHAR(50) NOT NULL DEFAULT 'grid', -- 'grid', 'flex', 'masonry'
    grid_columns INTEGER DEFAULT 12,
    grid_rows INTEGER DEFAULT 8,
    refresh_interval INTEGER DEFAULT 30, -- seconds
    auto_refresh BOOLEAN DEFAULT true,
    
    -- Dashboard widgets configuration (JSONB for flexibility)
    widgets_config JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- Example: [{"type": "metric_card", "position": {"x": 0, "y": 0, "w": 3, "h": 2}, "config": {"metric": "calls_waiting"}}]
    
    -- Filters and personalization
    default_filters JSONB DEFAULT '{}'::jsonb,
    time_range_default VARCHAR(50) DEFAULT 'today', -- 'today', 'this_week', 'this_month'
    theme_settings JSONB DEFAULT '{"theme": "light", "colors": "default"}'::jsonb,
    
    -- Russian localization
    language_preference VARCHAR(10) DEFAULT 'ru',
    timezone_setting VARCHAR(50) DEFAULT 'Europe/Moscow',
    date_format VARCHAR(50) DEFAULT 'DD.MM.YYYY',
    time_format VARCHAR(20) DEFAULT 'HH:mm',
    
    -- Access control
    is_public BOOLEAN DEFAULT false,
    is_template BOOLEAN DEFAULT false,
    template_category VARCHAR(100), -- 'операционный', 'аналитический', 'управленческий'
    
    -- Version control
    version_number INTEGER DEFAULT 1,
    parent_dashboard_id UUID REFERENCES dynamic_dashboard_configurations(dashboard_id),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001'
);

-- Indexes for dashboard performance
CREATE INDEX IF NOT EXISTS idx_dashboard_user_role ON dynamic_dashboard_configurations (user_id, user_role);
CREATE INDEX IF NOT EXISTS idx_dashboard_template ON dynamic_dashboard_configurations (is_template, template_category);
CREATE INDEX IF NOT EXISTS idx_dashboard_public ON dynamic_dashboard_configurations (is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets ON dynamic_dashboard_configurations USING GIN (widgets_config);

-- Task 18: Advanced KPI Definitions
-- Flexible KPI calculation engine with Russian business metrics
CREATE TABLE IF NOT EXISTS advanced_kpi_definitions (
    kpi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_code VARCHAR(100) UNIQUE NOT NULL, -- 'SLA_LEVEL_80_20', 'AGENT_UTILIZATION', 'КАЧЕСТВО_ОБСЛУЖИВАНИЯ'
    kpi_name_ru VARCHAR(200) NOT NULL, -- Russian name
    kpi_name_en VARCHAR(200), -- English name
    kpi_description TEXT,
    
    -- KPI categorization
    kpi_category VARCHAR(100) NOT NULL, -- 'операционный', 'качественный', 'эффективность', 'соответствие'
    kpi_subcategory VARCHAR(100),
    business_domain VARCHAR(100), -- 'контакт_центр', 'планирование', 'управление_персоналом'
    
    -- Calculation configuration
    calculation_formula TEXT NOT NULL, -- SQL-like formula or reference to stored procedure
    calculation_type VARCHAR(50) NOT NULL, -- 'percentage', 'ratio', 'count', 'duration', 'rate'
    data_sources JSONB NOT NULL, -- Tables and fields required for calculation
    calculation_frequency VARCHAR(50) DEFAULT 'real_time', -- 'real_time', 'hourly', 'daily', 'weekly'
    
    -- Target and threshold configuration
    target_value DECIMAL(15,4),
    threshold_green DECIMAL(15,4), -- Excellent performance
    threshold_yellow DECIMAL(15,4), -- Acceptable performance  
    threshold_red DECIMAL(15,4), -- Poor performance
    threshold_direction VARCHAR(10) CHECK (threshold_direction IN ('higher_better', 'lower_better')),
    
    -- Russian regulatory compliance
    regulatory_requirement BOOLEAN DEFAULT false,
    regulatory_standard VARCHAR(200), -- Reference to Russian standard or regulation
    compliance_mandatory BOOLEAN DEFAULT false,
    reporting_frequency VARCHAR(50), -- How often must be reported to authorities
    
    -- Dimensional applicability
    applies_to_agents BOOLEAN DEFAULT true,
    applies_to_queues BOOLEAN DEFAULT true,
    applies_to_departments BOOLEAN DEFAULT true,
    applies_to_sites BOOLEAN DEFAULT true,
    skill_specific BOOLEAN DEFAULT false,
    
    -- Display configuration
    display_format VARCHAR(50) DEFAULT 'decimal', -- 'decimal', 'percentage', 'duration', 'count'
    decimal_places INTEGER DEFAULT 2,
    unit_of_measure VARCHAR(50), -- '%', 'сек', 'мин', 'шт', 'руб'
    chart_type VARCHAR(50) DEFAULT 'line', -- 'line', 'bar', 'gauge', 'scorecard'
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version_number INTEGER DEFAULT 1,
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001'
);

-- Indexes for KPI definitions
CREATE INDEX IF NOT EXISTS idx_kpi_category ON advanced_kpi_definitions (kpi_category, kpi_subcategory);
CREATE INDEX IF NOT EXISTS idx_kpi_domain ON advanced_kpi_definitions (business_domain);
CREATE INDEX IF NOT EXISTS idx_kpi_regulatory ON advanced_kpi_definitions (regulatory_requirement) WHERE regulatory_requirement = true;
CREATE INDEX IF NOT EXISTS idx_kpi_active ON advanced_kpi_definitions (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_kpi_sources ON advanced_kpi_definitions USING GIN (data_sources);

-- Task 19: Intelligent Alert System
-- Smart alerting with machine learning insights and escalation
CREATE TABLE IF NOT EXISTS intelligent_alert_system (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_code VARCHAR(100) NOT NULL, -- 'SLA_BREACH_PREDICTED', 'AGENT_OVERTIME_RISK'
    alert_name VARCHAR(200) NOT NULL,
    alert_description TEXT,
    
    -- Alert trigger configuration
    trigger_type VARCHAR(50) NOT NULL, -- 'threshold', 'ml_prediction', 'pattern_anomaly', 'trend_change'
    trigger_condition TEXT NOT NULL, -- Condition that triggers the alert
    trigger_severity VARCHAR(20) NOT NULL CHECK (trigger_severity IN ('low', 'medium', 'high', 'critical')),
    
    -- Machine learning configuration
    ml_model_type VARCHAR(100), -- 'anomaly_detection', 'predictive_model', 'pattern_recognition'
    ml_confidence_threshold DECIMAL(5,4) DEFAULT 0.8, -- Minimum confidence for ML-triggered alerts
    ml_prediction_horizon INTEGER, -- Minutes ahead for predictive alerts
    historical_data_window INTEGER DEFAULT 30, -- Days of historical data for ML training
    
    -- Alert targeting
    target_entity_type VARCHAR(50) NOT NULL, -- 'agent', 'queue', 'department', 'site', 'system'
    target_entity_ids JSONB, -- Specific entities this alert applies to
    target_roles JSONB DEFAULT '["супервизор", "менеджер"]'::jsonb, -- Roles that should receive this alert
    
    -- Alert thresholds (for threshold-based alerts)
    warning_threshold DECIMAL(15,4),
    critical_threshold DECIMAL(15,4),
    threshold_comparison VARCHAR(20), -- 'greater_than', 'less_than', 'equals', 'not_equals'
    
    -- Escalation configuration
    escalation_enabled BOOLEAN DEFAULT true,
    escalation_levels JSONB DEFAULT '[
        {"level": 1, "delay_minutes": 5, "recipients": ["супервизор"]},
        {"level": 2, "delay_minutes": 15, "recipients": ["менеджер"]},
        {"level": 3, "delay_minutes": 30, "recipients": ["директор"]}
    ]'::jsonb,
    
    -- Russian business context
    business_impact VARCHAR(100), -- 'высокий', 'средний', 'низкий'
    russian_compliance_impact BOOLEAN DEFAULT false,
    recommended_actions JSONB, -- Suggested actions in Russian
    
    -- Alert delivery configuration
    delivery_channels JSONB DEFAULT '["email", "web_notification"]'::jsonb, -- 'email', 'sms', 'web_notification', 'mobile_push'
    notification_template TEXT, -- Template for alert message
    suppress_similar_alerts_minutes INTEGER DEFAULT 15, -- Prevent alert spam
    
    -- Performance tracking
    false_positive_rate DECIMAL(5,4) DEFAULT 0.0,
    alert_effectiveness_score DECIMAL(3,2) DEFAULT 0.0,
    last_triggered TIMESTAMP WITH TIME ZONE,
    trigger_count INTEGER DEFAULT 0,
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001'
);

-- Indexes for alert system
CREATE INDEX IF NOT EXISTS idx_alert_trigger_type ON intelligent_alert_system (trigger_type, trigger_severity);
CREATE INDEX IF NOT EXISTS idx_alert_entity_type ON intelligent_alert_system (target_entity_type);
CREATE INDEX IF NOT EXISTS idx_alert_active ON intelligent_alert_system (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_alert_ml_model ON intelligent_alert_system (ml_model_type) WHERE ml_model_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_alert_targets ON intelligent_alert_system USING GIN (target_entity_ids);
CREATE INDEX IF NOT EXISTS idx_alert_roles ON intelligent_alert_system USING GIN (target_roles);

-- Task 20: Custom Report Engine
-- Advanced reporting with dynamic generation and Russian templates
CREATE TABLE IF NOT EXISTS custom_report_engine (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_code VARCHAR(100) UNIQUE NOT NULL, -- 'MONTHLY_PERFORMANCE', 'SLA_COMPLIANCE'
    report_name VARCHAR(200) NOT NULL,
    report_description TEXT,
    
    -- Report categorization
    report_category VARCHAR(100) NOT NULL, -- 'операционный', 'аналитический', 'регулятивный', 'управленческий'
    report_type VARCHAR(50) NOT NULL, -- 'scheduled', 'on_demand', 'real_time', 'interactive'
    business_area VARCHAR(100), -- 'планирование', 'операции', 'качество', 'соответствие'
    
    -- Report configuration
    data_sources JSONB NOT NULL, -- Tables, views, and external sources
    report_sql_query TEXT, -- SQL query for data extraction
    report_parameters JSONB DEFAULT '{}'::jsonb, -- Configurable parameters
    default_filters JSONB DEFAULT '{}'::jsonb, -- Default filter values
    
    -- Russian compliance and formatting
    regulatory_report BOOLEAN DEFAULT false,
    regulatory_standard VARCHAR(200), -- Russian regulatory requirement reference
    required_signatures JSONB, -- Required approvals for regulatory reports
    official_template BOOLEAN DEFAULT false, -- Uses official Russian government template
    
    -- Output configuration
    output_formats JSONB DEFAULT '["pdf", "excel"]'::jsonb, -- 'pdf', 'excel', 'csv', 'json', 'html'
    template_file_path VARCHAR(500), -- Path to report template file
    styling_config JSONB DEFAULT '{}'::jsonb, -- Fonts, colors, logos for Russian corporate style
    page_orientation VARCHAR(20) DEFAULT 'portrait', -- 'portrait', 'landscape'
    
    -- Scheduling configuration
    schedule_enabled BOOLEAN DEFAULT false,
    schedule_frequency VARCHAR(50), -- 'daily', 'weekly', 'monthly', 'quarterly'
    schedule_time TIME DEFAULT '09:00:00',
    schedule_timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    schedule_recipients JSONB DEFAULT '[]'::jsonb,
    
    -- Distribution and access
    auto_distribution BOOLEAN DEFAULT false,
    distribution_list JSONB DEFAULT '[]'::jsonb, -- Email addresses and roles
    access_roles JSONB DEFAULT '["менеджер"]'::jsonb, -- Roles allowed to run this report
    security_classification VARCHAR(50) DEFAULT 'internal', -- 'public', 'internal', 'confidential', 'restricted'
    
    -- Performance and caching
    estimated_runtime_minutes INTEGER DEFAULT 5,
    cache_enabled BOOLEAN DEFAULT true,
    cache_duration_minutes INTEGER DEFAULT 60,
    max_data_age_hours INTEGER DEFAULT 24, -- Maximum age of data for report
    
    -- Localization
    language_template VARCHAR(10) DEFAULT 'ru',
    date_format VARCHAR(50) DEFAULT 'DD.MM.YYYY',
    number_format VARCHAR(50) DEFAULT 'russian', -- Russian number formatting (spaces as thousands separator)
    currency_symbol VARCHAR(10) DEFAULT '₽',
    
    -- Version and approval tracking
    version_number INTEGER DEFAULT 1,
    approval_status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'pending_approval', 'approved', 'deprecated'
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Usage analytics
    run_count INTEGER DEFAULT 0,
    last_run_at TIMESTAMP WITH TIME ZONE,
    average_runtime_seconds DECIMAL(8,2),
    success_rate DECIMAL(5,4) DEFAULT 1.0,
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001'
);

-- Indexes for report engine
CREATE INDEX IF NOT EXISTS idx_report_category ON custom_report_engine (report_category, report_type);
CREATE INDEX IF NOT EXISTS idx_report_regulatory ON custom_report_engine (regulatory_report) WHERE regulatory_report = true;
CREATE INDEX IF NOT EXISTS idx_report_scheduled ON custom_report_engine (schedule_enabled) WHERE schedule_enabled = true;
CREATE INDEX IF NOT EXISTS idx_report_approval ON custom_report_engine (approval_status);
CREATE INDEX IF NOT EXISTS idx_report_access ON custom_report_engine USING GIN (access_roles);
CREATE INDEX IF NOT EXISTS idx_report_sources ON custom_report_engine USING GIN (data_sources);

-- ============================================================================
-- Sample Data for Russian WFM Operations
-- ============================================================================

-- Sample KPI Definitions for Russian WFM
INSERT INTO advanced_kpi_definitions (kpi_code, kpi_name_ru, kpi_name_en, kpi_category, calculation_formula, calculation_type, data_sources, target_value, threshold_green, threshold_yellow, threshold_red, threshold_direction, unit_of_measure) VALUES
('SLA_80_20', 'Уровень обслуживания 80/20', 'Service Level 80/20', 'операционный', 'SELECT (COUNT(*) FILTER (WHERE answer_time <= 20) * 100.0 / COUNT(*)) FROM calls WHERE date = CURRENT_DATE', 'percentage', '{"tables": ["calls"], "fields": ["answer_time", "date"]}', 80.0, 85.0, 80.0, 75.0, 'higher_better', '%'),
('AGENT_UTILIZATION', 'Загрузка агентов', 'Agent Utilization', 'эффективность', 'SELECT (SUM(talk_time + hold_time + acw_time) * 100.0 / SUM(logged_time)) FROM agent_activity WHERE date = CURRENT_DATE', 'percentage', '{"tables": ["agent_activity"], "fields": ["talk_time", "hold_time", "acw_time", "logged_time"]}', 85.0, 90.0, 85.0, 75.0, 'higher_better', '%'),
('QUALITY_SCORE', 'Оценка качества', 'Quality Score', 'качественный', 'SELECT AVG(quality_score) FROM quality_monitoring WHERE date >= CURRENT_DATE - INTERVAL ''7 days''', 'percentage', '{"tables": ["quality_monitoring"], "fields": ["quality_score", "date"]}', 90.0, 95.0, 90.0, 80.0, 'higher_better', '%'),
('ABANDONMENT_RATE', 'Процент отказов', 'Abandonment Rate', 'операционный', 'SELECT (COUNT(*) FILTER (WHERE status = ''abandoned'') * 100.0 / COUNT(*)) FROM calls WHERE date = CURRENT_DATE', 'percentage', '{"tables": ["calls"], "fields": ["status", "date"]}', 5.0, 3.0, 5.0, 8.0, 'lower_better', '%');

-- Sample Dashboard Templates for Russian Roles
INSERT INTO dynamic_dashboard_configurations (dashboard_name, user_id, user_role, template_category, widgets_config, is_template, language_preference) VALUES
('Операционная панель супервизора', '00000000-0000-0000-0000-000000000001', 'супервизор', 'операционный', 
'[
  {"type": "metric_card", "position": {"x": 0, "y": 0, "w": 3, "h": 2}, "config": {"metric": "calls_waiting", "title": "Звонки в очереди"}},
  {"type": "metric_card", "position": {"x": 3, "y": 0, "w": 3, "h": 2}, "config": {"metric": "sla_current", "title": "Текущий SLA"}},
  {"type": "chart", "position": {"x": 0, "y": 2, "w": 6, "h": 4}, "config": {"type": "line", "metric": "calls_volume", "title": "Динамика звонков"}},
  {"type": "agent_grid", "position": {"x": 6, "y": 0, "w": 6, "h": 6}, "config": {"title": "Статус агентов"}}
]', true, 'ru'),
('Аналитическая панель менеджера', '00000000-0000-0000-0000-000000000001', 'менеджер', 'аналитический',
'[
  {"type": "kpi_scorecard", "position": {"x": 0, "y": 0, "w": 12, "h": 2}, "config": {"kpis": ["SLA_80_20", "AGENT_UTILIZATION", "QUALITY_SCORE", "ABANDONMENT_RATE"]}},
  {"type": "chart", "position": {"x": 0, "y": 2, "w": 6, "h": 4}, "config": {"type": "column", "metric": "hourly_performance", "title": "Часовая производительность"}},
  {"type": "heatmap", "position": {"x": 6, "y": 2, "w": 6, "h": 4}, "config": {"metric": "queue_performance", "title": "Производительность очередей"}}
]', true, 'ru');

-- Sample Alert Configurations
INSERT INTO intelligent_alert_system (alert_code, alert_name, trigger_type, trigger_condition, trigger_severity, target_entity_type, target_roles, recommended_actions) VALUES
('SLA_BREACH_RISK', 'Риск нарушения SLA', 'ml_prediction', 'predicted_sla < 80 AND confidence > 0.85', 'high', 'queue', '["супервизор", "менеджер"]', '["Добавить агентов в очередь", "Проверить навыки агентов", "Активировать резервный план"]'),
('LONG_WAIT_TIME', 'Длительное время ожидания', 'threshold', 'average_wait_time > 120', 'medium', 'queue', '["супервизор"]', '["Перенаправить звонки", "Уведомить агентов", "Проверить техническое состояние"]'),
('AGENT_OVERTIME_RISK', 'Риск переработки агента', 'threshold', 'worked_hours > 7.5', 'medium', 'agent', '["супервизор", "менеджер"]', '["Планировать замену", "Контролировать нагрузку", "Соблюдать трудовое законодательство"]');

-- Sample Report Templates
INSERT INTO custom_report_engine (report_code, report_name, report_category, report_type, regulatory_report, output_formats, access_roles, schedule_frequency, data_sources) VALUES
('DAILY_OPERATIONS', 'Ежедневный операционный отчет', 'операционный', 'scheduled', false, '["pdf", "excel"]', '["супервизор", "менеджер"]', 'daily', '{"tables": ["agent_activity", "call_statistics"]}'),
('MONTHLY_SLA', 'Месячный отчет по SLA', 'регулятивный', 'scheduled', true, '["pdf"]', '["менеджер", "директор"]', 'monthly', '{"tables": ["service_level_metrics"]}'),
('QUALITY_ANALYSIS', 'Анализ качества обслуживания', 'аналитический', 'on_demand', false, '["excel", "pdf"]', '["менеджер", "специалист_качества"]', NULL, '{"tables": ["quality_monitoring"]}'),
('LABOR_COMPLIANCE', 'Соответствие трудовому законодательству', 'регулятивный', 'scheduled', true, '["pdf"]', '["директор", "кадровик"]', 'weekly', '{"tables": ["work_schedule", "time_tracking"]}');

-- ============================================================================
-- Verification and Performance Functions
-- ============================================================================

-- Function to verify analytics infrastructure
CREATE OR REPLACE FUNCTION verify_analytics_infrastructure()
RETURNS TABLE(
    component TEXT,
    status TEXT,
    record_count BIGINT,
    last_update TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Real-time Metrics'::TEXT, 'Active'::TEXT, 
           COUNT(*), MAX(created_at)
    FROM realtime_metric_aggregations
    UNION ALL
    SELECT 'Dashboard Configs'::TEXT, 'Active'::TEXT,
           COUNT(*), MAX(created_at)
    FROM dynamic_dashboard_configurations
    UNION ALL
    SELECT 'KPI Definitions'::TEXT, 'Active'::TEXT,
           COUNT(*), MAX(created_at)
    FROM advanced_kpi_definitions
    UNION ALL
    SELECT 'Alert System'::TEXT, 'Active'::TEXT,
           COUNT(*), MAX(created_at)
    FROM intelligent_alert_system
    UNION ALL
    SELECT 'Report Engine'::TEXT, 'Active'::TEXT,
           COUNT(*), MAX(created_at)
    FROM custom_report_engine;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE realtime_metric_aggregations IS 'Task 16: Pre-computed real-time metrics for high-performance dashboards with Russian WFM KPIs';
COMMENT ON TABLE dynamic_dashboard_configurations IS 'Task 17: Flexible dashboard configuration system supporting Russian role-based layouts';
COMMENT ON TABLE advanced_kpi_definitions IS 'Task 18: Comprehensive KPI calculation engine with Russian business metrics and compliance tracking';
COMMENT ON TABLE intelligent_alert_system IS 'Task 19: ML-powered alert system with escalation and Russian business context';
COMMENT ON TABLE custom_report_engine IS 'Task 20: Advanced reporting platform with Russian regulatory compliance and templates';