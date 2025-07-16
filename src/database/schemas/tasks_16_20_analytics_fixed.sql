-- ============================================================================
-- WFM Enterprise Analytics Infrastructure (Tasks 16-20) - Fixed Version
-- Advanced Analytics Support Tables
-- Database: wfm_enterprise
-- ============================================================================

-- Drop existing realtime_metric_aggregations if it exists
DROP TABLE IF EXISTS realtime_metric_aggregations CASCADE;

-- Task 16: Real-time Metric Aggregations (Simplified)
-- Pre-computed metrics for dashboard performance
CREATE TABLE realtime_metric_aggregations (
    aggregation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    created_by UUID DEFAULT '00000000-0000-0000-0000-000000000001'
);

-- Indexes for performance
CREATE INDEX idx_realtime_metrics_type_time ON realtime_metric_aggregations (metric_type, time_bucket DESC);
CREATE INDEX idx_realtime_metrics_site_dept ON realtime_metric_aggregations (site_id, department_id);
CREATE INDEX idx_realtime_metrics_agent_queue ON realtime_metric_aggregations (agent_id, queue_id);
CREATE INDEX idx_realtime_metrics_russian_kpi ON realtime_metric_aggregations (russian_kpi_category, compliance_status);

-- Insert sample real-time metrics
INSERT INTO realtime_metric_aggregations 
(metric_type, metric_name, aggregation_period, time_bucket, current_value, russian_kpi_category, compliance_status, calculation_method) VALUES
('queue_stats', 'calls_waiting', '1min', CURRENT_TIMESTAMP, 12, 'обслуживание', 'требует_внимания', 'COUNT(*) FROM call_queue WHERE status = ''waiting'''),
('agent_performance', 'utilization_rate', '15min', CURRENT_TIMESTAMP, 87.5, 'эффективность', 'соответствует', 'SUM(talk_time + acw_time) / SUM(available_time) * 100'),
('service_levels', 'sla_achievement', '1hour', CURRENT_TIMESTAMP, 82.3, 'обслуживание', 'соответствует', 'Calls answered within 20 seconds / Total calls * 100');

-- ============================================================================
-- Sample KPI Definitions for Russian WFM (Add to existing table)
-- ============================================================================

-- Insert additional Russian KPIs
INSERT INTO advanced_kpi_definitions (kpi_code, kpi_name_ru, kpi_name_en, kpi_category, calculation_formula, calculation_type, data_sources, target_value, threshold_green, threshold_yellow, threshold_red, threshold_direction, unit_of_measure) VALUES
('FCR', 'Решение с первого звонка', 'First Call Resolution', 'качественный', 'SELECT (COUNT(*) FILTER (WHERE resolution_status = ''first_call'') * 100.0 / COUNT(*)) FROM call_resolution WHERE date = CURRENT_DATE', 'percentage', '{"tables": ["call_resolution"], "fields": ["resolution_status", "date"]}', 85.0, 90.0, 85.0, 75.0, 'higher_better', '%'),
('AHT', 'Среднее время обработки', 'Average Handle Time', 'эффективность', 'SELECT AVG(talk_time + hold_time + acw_time) FROM calls WHERE date = CURRENT_DATE', 'duration', '{"tables": ["calls"], "fields": ["talk_time", "hold_time", "acw_time", "date"]}', 300.0, 270.0, 300.0, 360.0, 'lower_better', 'сек'),
('SCH_ADH', 'Соблюдение расписания', 'Schedule Adherence', 'соответствие', 'SELECT (SUM(scheduled_time - ABS(actual_time - scheduled_time)) / SUM(scheduled_time) * 100) FROM schedule_tracking WHERE date = CURRENT_DATE', 'percentage', '{"tables": ["schedule_tracking"], "fields": ["scheduled_time", "actual_time", "date"]}', 95.0, 98.0, 95.0, 90.0, 'higher_better', '%');

-- ============================================================================
-- Sample Dashboard Templates (Add to existing table)
-- ============================================================================

INSERT INTO dynamic_dashboard_configurations (dashboard_name, user_id, user_role, template_category, widgets_config, is_template, language_preference) VALUES
('Панель директора', '00000000-0000-0000-0000-000000000001', 'директор', 'управленческий',
'[
  {"type": "executive_summary", "position": {"x": 0, "y": 0, "w": 12, "h": 3}, "config": {"title": "Сводка руководства", "metrics": ["revenue_per_call", "customer_satisfaction", "operational_efficiency"]}},
  {"type": "trend_chart", "position": {"x": 0, "y": 3, "w": 6, "h": 3}, "config": {"title": "Динамика ключевых показателей", "period": "monthly"}},
  {"type": "compliance_status", "position": {"x": 6, "y": 3, "w": 6, "h": 3}, "config": {"title": "Соответствие требованиям", "regulations": ["labor_law", "data_protection"]}}
]', true, 'ru'),
('Панель оператора', '00000000-0000-0000-0000-000000000001', 'оператор', 'операционный',
'[
  {"type": "personal_metrics", "position": {"x": 0, "y": 0, "w": 6, "h": 2}, "config": {"title": "Мои показатели", "metrics": ["calls_handled", "avg_talk_time", "quality_score"]}},
  {"type": "schedule_widget", "position": {"x": 6, "y": 0, "w": 6, "h": 2}, "config": {"title": "Расписание", "view": "today"}},
  {"type": "queue_status", "position": {"x": 0, "y": 2, "w": 12, "h": 3}, "config": {"title": "Статус очередей", "assigned_queues_only": true}}
]', true, 'ru');

-- ============================================================================
-- Sample Alert Configurations (Add to existing table)
-- ============================================================================

INSERT INTO intelligent_alert_system (alert_code, alert_name, trigger_type, trigger_condition, trigger_severity, target_entity_type, target_roles, recommended_actions, business_impact) VALUES
('QUALITY_DECLINE', 'Снижение качества обслуживания', 'threshold', 'quality_score < 85', 'high', 'department', '["менеджер", "специалист_качества"]', '["Провести дополнительное обучение", "Анализ записей разговоров", "Пересмотреть процедуры"]', 'высокий'),
('SCHEDULE_DEVIATION', 'Отклонение от расписания', 'pattern_anomaly', 'schedule_adherence < 90', 'medium', 'agent', '["супервизор"]', '["Связаться с агентом", "Проверить причины отклонения", "Скорректировать расписание"]', 'средний'),
('HIGH_ABANDONMENT', 'Высокий процент отказов', 'threshold', 'abandonment_rate > 8', 'critical', 'queue', '["супервизор", "менеджер"]', '["Экстренное увеличение персонала", "Активация резервного плана", "Уведомление руководства"]', 'высокий');

-- ============================================================================
-- Sample Report Templates (Add to existing table)
-- ============================================================================

INSERT INTO custom_report_engine (report_code, report_name, report_category, report_type, regulatory_report, output_formats, access_roles, schedule_frequency, data_sources, business_area) VALUES
('AGENT_PERF_DETAILED', 'Детальная производительность агентов', 'аналитический', 'scheduled', false, '["excel", "pdf"]', '["менеджер", "супервизор"]', 'weekly', '{"tables": ["agent_activity", "quality_scores", "schedule_adherence"]}', 'управление_персоналом'),
('CUSTOMER_SAT_SURVEY', 'Опрос удовлетворенности клиентов', 'аналитический', 'on_demand', false, '["pdf", "excel"]', '["менеджер", "директор"]', NULL, '{"tables": ["customer_feedback", "quality_monitoring"]}', 'качество'),
('REGULATORY_COMP_NEW', 'Новые нормативные требования', 'регулятивный', 'scheduled', true, '["pdf"]', '["директор", "юрист"]', 'monthly', '{"tables": ["work_schedule", "time_tracking", "break_compliance"]}', 'соответствие'),
('COST_ANALYSIS_DETAIL', 'Детальный анализ затрат', 'управленческий', 'scheduled', false, '["excel"]', '["менеджер", "финансист"]', 'monthly', '{"tables": ["payroll_data", "overtime_tracking", "productivity_metrics"]}', 'финансы');

-- ============================================================================
-- Verification Function
-- ============================================================================

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

-- Add comments
COMMENT ON TABLE realtime_metric_aggregations IS 'Task 16: Pre-computed real-time metrics for high-performance dashboards with Russian WFM KPIs';
COMMENT ON TABLE dynamic_dashboard_configurations IS 'Task 17: Flexible dashboard configuration system supporting Russian role-based layouts';
COMMENT ON TABLE advanced_kpi_definitions IS 'Task 18: Comprehensive KPI calculation engine with Russian business metrics and compliance tracking';
COMMENT ON TABLE intelligent_alert_system IS 'Task 19: ML-powered alert system with escalation and Russian business context';
COMMENT ON TABLE custom_report_engine IS 'Task 20: Advanced reporting platform with Russian regulatory compliance and templates';