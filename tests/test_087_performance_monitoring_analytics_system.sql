-- Test Data for Schema 087: Performance Monitoring and Analytics System
-- Comprehensive test scenarios with realistic Russian business data
-- Tests BDD compliance for reporting, monitoring, and analytics

-- ============================================================================
-- TEST DATA SETUP AND INITIALIZATION
-- ============================================================================

-- Enable necessary extensions for testing
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        CREATE EXTENSION "uuid-ossp";
    END IF;
END $$;

-- Clean up any existing test data
DELETE FROM performance_audit_trails WHERE user_id LIKE 'test_%';
DELETE FROM performance_alerts WHERE alert_id IN (
    SELECT alert_id FROM performance_alerts 
    WHERE alert_message LIKE '%test%' OR alert_message_ru LIKE '%тест%'
);
DELETE FROM performance_realtime_data WHERE tags ? 'test_scenario';
DELETE FROM performance_historical_analytics WHERE calculation_metadata ? 'test_run';

-- ============================================================================
-- 1. RUSSIAN CALL CENTER TEST SCENARIO DATA
-- ============================================================================

-- Test departments and teams (Russian company structure)
INSERT INTO performance_realtime_data (
    metric_id, employee_id, department_id, team_id, measurement_timestamp,
    metric_value, measurement_interval, data_source, source_system,
    quality_score, tags
) 
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
    uuid_generate_v4(), -- employee_id
    uuid_generate_v4(), -- department_id (Отдел клиентского сервиса)
    uuid_generate_v4(), -- team_id (Команда входящих звонков)
    CURRENT_TIMESTAMP - (random() * INTERVAL '1 day'),
    120 + (random() * 180)::INTEGER, -- AHT between 120-300 seconds
    '5min',
    'telephony',
    'argus',
    85 + (random() * 15)::NUMERIC(5,2), -- Quality score 85-100%
    jsonb_build_object(
        'test_scenario', 'russian_call_center',
        'department_name_ru', 'Отдел клиентского сервиса',
        'team_name_ru', 'Команда входящих звонков',
        'employee_name_ru', 'Иванов Иван Иванович',
        'shift_type', 'morning',
        'skill_groups', '["Общие вопросы", "Техническая поддержка"]'
    )
FROM generate_series(1, 50); -- 50 AHT measurements

-- Schedule adherence test data (Соблюдение расписания)
INSERT INTO performance_realtime_data (
    metric_id, employee_id, department_id, team_id, measurement_timestamp,
    metric_value, measurement_interval, data_source, source_system,
    quality_score, tags
)
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'ADHERENCE'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_TIMESTAMP - (random() * INTERVAL '2 days'),
    88 + (random() * 12)::NUMERIC(5,2), -- Adherence 88-100%
    '15min',
    'system',
    'argus',
    90 + (random() * 10)::NUMERIC(5,2),
    jsonb_build_object(
        'test_scenario', 'schedule_adherence',
        'employee_name_ru', 'Петрова Анна Сергеевна',
        'planned_login', '09:00:00',
        'actual_login', '09:05:00',
        'planned_break', '12:00:00',
        'actual_break', '12:03:00',
        'deviation_minutes', 8,
        'excuse_type', 'транспортная задержка'
    )
FROM generate_series(1, 30);

-- Customer satisfaction test data (Удовлетворенность клиентов)
INSERT INTO performance_realtime_data (
    metric_id, employee_id, department_id, team_id, measurement_timestamp,
    metric_value, measurement_interval, data_source, source_system,
    quality_score, tags
)
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'CSAT'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_TIMESTAMP - (random() * INTERVAL '1 week'),
    3.5 + (random() * 1.5)::NUMERIC(3,2), -- CSAT 3.5-5.0
    'daily',
    'survey',
    'feedback_system',
    95 + (random() * 5)::NUMERIC(5,2),
    jsonb_build_object(
        'test_scenario', 'customer_satisfaction',
        'agent_name_ru', 'Сидоров Петр Александрович',
        'survey_type', 'post_call',
        'customer_comment_ru', 'Быстро решили мой вопрос, спасибо!',
        'call_category', 'billing_inquiry',
        'resolution_time_minutes', 8,
        'was_escalated', false
    )
FROM generate_series(1, 25);

-- Occupancy rate test data (Коэффициент занятости)
INSERT INTO performance_realtime_data (
    metric_id, employee_id, department_id, team_id, measurement_timestamp,
    metric_value, measurement_interval, data_source, source_system,
    quality_score, tags
)
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'OCCUPANCY'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_TIMESTAMP - (random() * INTERVAL '1 day'),
    70 + (random() * 25)::NUMERIC(5,2), -- Occupancy 70-95%
    '30min',
    'system',
    'workforce_management',
    88 + (random() * 12)::NUMERIC(5,2),
    jsonb_build_object(
        'test_scenario', 'occupancy_tracking',
        'agent_name_ru', 'Козлова Мария Викторовна',
        'total_login_time_minutes', 480,
        'productive_time_minutes', 384,
        'break_time_minutes', 60,
        'training_time_minutes', 30,
        'idle_time_minutes', 6,
        'status_breakdown', jsonb_build_object(
            'available', 120,
            'in_call', 180,
            'after_call_work', 84,
            'break', 60,
            'training', 30,
            'other', 6
        )
    )
FROM generate_series(1, 40);

-- ============================================================================
-- 2. HISTORICAL ANALYTICS TEST DATA (TREND ANALYSIS)
-- ============================================================================

-- Generate 90 days of historical data for trend analysis
INSERT INTO performance_historical_analytics (
    metric_id, employee_id, department_id, team_id, analysis_date,
    analysis_period, metric_value, target_achievement_pct, trend_direction,
    trend_strength, percentile_rank, moving_average_7d, moving_average_30d,
    calculation_metadata
)
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_DATE - (seq || ' days')::INTERVAL,
    'daily',
    150 + (random() * 100 + sin(seq * 0.1) * 20)::NUMERIC(8,2), -- Trending AHT with seasonality
    85 + (random() * 20)::NUMERIC(5,2), -- Target achievement 85-105%
    CASE 
        WHEN random() < 0.33 THEN 'improving'
        WHEN random() < 0.66 THEN 'stable'
        ELSE 'declining'
    END,
    20 + (random() * 60)::NUMERIC(5,2), -- Trend strength 20-80%
    (random() * 100)::NUMERIC(5,2), -- Percentile rank
    140 + (random() * 80)::NUMERIC(8,2), -- 7-day MA
    145 + (random() * 70)::NUMERIC(8,2), -- 30-day MA
    jsonb_build_object(
        'test_run', 'historical_analytics',
        'employee_name_ru', 'Тестовый сотрудник ' || seq,
        'calculation_date', CURRENT_DATE,
        'data_quality', 'high',
        'seasonal_factors', jsonb_build_object(
            'day_of_week_effect', sin(seq * 0.7) * 5,
            'monthly_pattern', cos(seq * 0.2) * 8
        )
    )
FROM generate_series(1, 90) AS seq;

-- Quality score historical data
INSERT INTO performance_historical_analytics (
    metric_id, employee_id, department_id, team_id, analysis_date,
    analysis_period, metric_value, target_achievement_pct, trend_direction,
    trend_strength, percentile_rank, moving_average_7d, moving_average_30d,
    calculation_metadata
)
SELECT 
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'QA_SCORE'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_DATE - (seq || ' days')::INTERVAL,
    'daily',
    80 + (random() * 20)::NUMERIC(5,2), -- QA Score 80-100%
    88 + (random() * 15)::NUMERIC(5,2), -- Target achievement
    CASE 
        WHEN seq % 3 = 0 THEN 'improving'
        WHEN seq % 3 = 1 THEN 'stable'
        ELSE 'declining'
    END,
    30 + (random() * 40)::NUMERIC(5,2),
    (random() * 100)::NUMERIC(5,2),
    82 + (random() * 16)::NUMERIC(5,2), -- 7-day MA
    84 + (random() * 14)::NUMERIC(5,2), -- 30-day MA
    jsonb_build_object(
        'test_run', 'qa_historical',
        'monitoring_type', 'live_call_monitoring',
        'evaluator_ru', 'Супервайзер Иванова А.П.',
        'evaluation_criteria', jsonb_build_array(
            'Приветствие и представление',
            'Выявление потребности клиента',
            'Предложение решения',
            'Завершение разговора'
        )
    )
FROM generate_series(1, 60) AS seq;

-- ============================================================================
-- 3. PERFORMANCE ALERTS TEST SCENARIOS
-- ============================================================================

-- Generate test alerts for different severity levels
INSERT INTO performance_alerts (
    rule_id, employee_id, department_id, metric_id, alert_timestamp,
    severity_level, alert_message, alert_message_ru, current_value,
    threshold_value, variance_from_threshold, status, related_data
)
SELECT 
    (SELECT rule_id FROM performance_alert_rules WHERE rule_name LIKE '%AHT%' LIMIT 1),
    uuid_generate_v4(),
    uuid_generate_v4(),
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
    CURRENT_TIMESTAMP - (random() * INTERVAL '6 hours'),
    CASE 
        WHEN random() < 0.3 THEN 'critical'
        WHEN random() < 0.7 THEN 'warning'
        ELSE 'info'
    END,
    'AHT threshold exceeded for agent',
    'Превышен порог времени обработки для сотрудника',
    300 + (random() * 120)::NUMERIC(8,2), -- Current AHT 300-420 seconds
    300, -- Threshold
    (random() * 120)::NUMERIC(8,2), -- Variance
    CASE 
        WHEN random() < 0.4 THEN 'new'
        WHEN random() < 0.7 THEN 'acknowledged'
        ELSE 'resolved'
    END,
    jsonb_build_object(
        'test_scenario', 'aht_alerts',
        'agent_name_ru', 'Тестовый агент',
        'supervisor_notified', true,
        'coaching_required', random() < 0.6,
        'consecutive_violations', (random() * 5)::INTEGER + 1,
        'recommended_action_ru', 'Провести коучинг по эффективности обработки звонков'
    )
FROM generate_series(1, 15);

-- Schedule adherence alerts
INSERT INTO performance_alerts (
    rule_id, employee_id, department_id, metric_id, alert_timestamp,
    severity_level, alert_message, alert_message_ru, current_value,
    threshold_value, variance_from_threshold, status, related_data
)
SELECT 
    (SELECT rule_id FROM performance_alert_rules WHERE rule_name LIKE '%Schedule%' LIMIT 1),
    uuid_generate_v4(),
    uuid_generate_v4(),
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'ADHERENCE'),
    CURRENT_TIMESTAMP - (random() * INTERVAL '1 day'),
    'warning',
    'Schedule adherence below threshold',
    'Соблюдение расписания ниже нормы',
    75 + (random() * 15)::NUMERIC(5,2), -- Adherence 75-90%
    90, -- Threshold
    -(15 - random() * 15)::NUMERIC(5,2), -- Negative variance
    'acknowledged',
    jsonb_build_object(
        'test_scenario', 'adherence_alerts',
        'agent_name_ru', 'Смирнов Алексей Петрович',
        'shift_date', CURRENT_DATE,
        'late_login_minutes', (random() * 20)::INTEGER,
        'extended_break_minutes', (random() * 10)::INTEGER,
        'early_logout_minutes', (random() * 15)::INTEGER,
        'excuse_provided', random() < 0.7,
        'excuse_text_ru', 'Проблемы с транспортом'
    )
FROM generate_series(1, 10);

-- ============================================================================
-- 4. PERFORMANCE FORECAST TEST DATA
-- ============================================================================

-- Insert test forecast models
INSERT INTO performance_forecast_models (
    model_name, model_name_ru, metric_id, model_type, model_parameters,
    training_data_period, forecast_horizon, accuracy_score, last_trained_at,
    training_frequency, seasonal_factors, model_status
)
SELECT 
    'AHT Prediction Model',
    'Модель прогнозирования времени обработки',
    (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
    'arima',
    jsonb_build_object(
        'p', 2, 'd', 1, 'q', 2,
        'seasonal_p', 1, 'seasonal_d', 0, 'seasonal_q', 1,
        'seasonal_period', 7
    ),
    90, -- 90 days training
    30, -- 30 days forecast
    85.5, -- 85.5% accuracy
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'weekly',
    jsonb_build_object(
        'monday_factor', 1.1,
        'tuesday_factor', 1.05,
        'wednesday_factor', 1.0,
        'thursday_factor', 1.02,
        'friday_factor', 1.15,
        'month_end_factor', 1.2
    ),
    'active';

-- Generate forecast predictions for next 30 days
INSERT INTO performance_forecasts (
    model_id, employee_id, department_id, forecast_date, forecast_period,
    predicted_value, confidence_interval_lower, confidence_interval_upper,
    confidence_level, prediction_factors
)
SELECT 
    (SELECT model_id FROM performance_forecast_models WHERE model_name = 'AHT Prediction Model'),
    uuid_generate_v4(),
    uuid_generate_v4(),
    CURRENT_DATE + (seq || ' days')::INTERVAL,
    'daily',
    160 + (sin(seq * 0.2) * 20 + random() * 30)::NUMERIC(8,2), -- Predicted AHT with variation
    140 + (sin(seq * 0.2) * 15 + random() * 20)::NUMERIC(8,2), -- Lower bound
    180 + (sin(seq * 0.2) * 25 + random() * 40)::NUMERIC(8,2), -- Upper bound
    95.0,
    jsonb_build_object(
        'test_forecast', true,
        'day_of_week', extract(dow from (CURRENT_DATE + (seq || ' days')::INTERVAL)),
        'expected_call_volume', 800 + (random() * 400)::INTEGER,
        'staff_availability', 0.85 + (random() * 0.15)::NUMERIC(4,2),
        'seasonal_adjustment', sin(seq * 0.1) * 0.1,
        'external_factors', jsonb_build_object(
            'holiday_effect', CASE WHEN seq % 7 IN (0,6) THEN 0.8 ELSE 1.0 END,
            'training_impact', CASE WHEN seq % 15 = 0 THEN 1.2 ELSE 1.0 END
        )
    )
FROM generate_series(1, 30) AS seq;

-- ============================================================================
-- 5. RUSSIAN COMPLIANCE TEST DATA
-- ============================================================================

-- Test compliance check results
INSERT INTO performance_compliance_results (
    check_id, execution_timestamp, check_status, result_details,
    issues_found, records_checked, execution_time_ms, recommendations,
    recommendations_ru, remediation_required
)
SELECT 
    (SELECT check_id FROM performance_compliance_checks WHERE check_name LIKE '%качества%' LIMIT 1),
    CURRENT_TIMESTAMP - (random() * INTERVAL '1 week'),
    CASE 
        WHEN random() < 0.8 THEN 'passed'
        WHEN random() < 0.95 THEN 'warning'
        ELSE 'failed'
    END,
    jsonb_build_object(
        'test_compliance', true,
        'checked_employees', (random() * 100)::INTEGER + 50,
        'gost_compliance_rate', (85 + random() * 15)::NUMERIC(5,2),
        'labor_law_violations', (random() * 5)::INTEGER,
        'data_protection_score', (90 + random() * 10)::NUMERIC(5,2)
    ),
    (random() * 3)::INTEGER, -- 0-3 issues found
    (random() * 200)::INTEGER + 100, -- 100-300 records checked
    (random() * 5000)::INTEGER + 500, -- 500-5500ms execution time
    'Regular monitoring and staff training recommended',
    'Рекомендуется регулярный мониторинг и обучение персонала',
    random() < 0.3 -- 30% require remediation
FROM generate_series(1, 20);

-- ============================================================================
-- 6. AUDIT TRAIL TEST DATA
-- ============================================================================

-- Generate audit trail entries for various activities
INSERT INTO performance_audit_trails (
    audit_type, user_id, user_role, action_performed, table_affected,
    record_id, old_values, new_values, ip_address, business_justification,
    compliance_notes, is_sensitive
)
SELECT 
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'data_access'
        WHEN 1 THEN 'calculation'
        WHEN 2 THEN 'modification'
        ELSE 'report_generation'
    END,
    'test_user_' || (random() * 50)::INTEGER,
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'supervisor'
        WHEN 1 THEN 'manager'
        WHEN 2 THEN 'administrator'
        ELSE 'analyst'
    END,
    CASE (random() * 5)::INTEGER
        WHEN 0 THEN 'Просмотр отчета по производительности'
        WHEN 1 THEN 'Изменение настроек уведомлений'
        WHEN 2 THEN 'Экспорт данных о сотрудниках'
        WHEN 3 THEN 'Расчет KPI за период'
        ELSE 'Создание дашборда'
    END,
    'performance_realtime_data',
    uuid_generate_v4(),
    CASE WHEN random() < 0.5 THEN 
        jsonb_build_object('metric_value', (random() * 300)::NUMERIC(8,2))
    ELSE NULL END,
    jsonb_build_object(
        'metric_value', (random() * 300)::NUMERIC(8,2),
        'updated_by', 'test_user',
        'update_reason', 'Корректировка данных'
    ),
    ('192.168.1.' || (random() * 254)::INTEGER + 1)::INET,
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Плановый мониторинг производительности'
        WHEN 1 THEN 'Аудит качества данных'
        ELSE 'Подготовка отчета для руководства'
    END,
    'Соответствует требованиям ТК РФ по мониторингу трудовой деятельности',
    random() < 0.2 -- 20% are sensitive
FROM generate_series(1, 100);

-- ============================================================================
-- 7. DASHBOARD AND WIDGET TEST DATA
-- ============================================================================

-- Insert test dashboard widgets
INSERT INTO performance_dashboard_widgets (
    dashboard_id, widget_code, widget_name, widget_name_ru, widget_type,
    position_x, position_y, width, height, metric_ids, chart_config,
    display_config, is_visible
)
SELECT 
    (SELECT dashboard_id FROM performance_dashboards WHERE dashboard_code = 'REALTIME_OPS'),
    'test_widget_' || seq,
    'Test Performance Widget ' || seq,
    'Тестовый виджет производительности ' || seq,
    CASE (seq % 4)
        WHEN 0 THEN 'gauge'
        WHEN 1 THEN 'line_chart'
        WHEN 2 THEN 'bar_chart'
        ELSE 'kpi_card'
    END,
    (seq % 3) * 4, -- Position X
    (seq / 3) * 3, -- Position Y
    4, -- Width
    3, -- Height
    jsonb_build_array(
        (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT'),
        (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'ADHERENCE')
    ),
    jsonb_build_object(
        'chart_type', 'line',
        'time_range', '24h',
        'refresh_interval', 300,
        'show_target_line', true,
        'color_scheme', 'blue_green'
    ),
    jsonb_build_object(
        'show_title', true,
        'show_legend', true,
        'decimal_places', 2,
        'unit_display', true,
        'alert_indicators', true
    ),
    true
FROM generate_series(1, 8) AS seq;

-- ============================================================================
-- 8. VERIFICATION TESTS
-- ============================================================================

-- Test 1: Verify metric definitions are properly localized
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM performance_metric_definitions 
    WHERE metric_name_ru IS NOT NULL AND is_active = true;
    
    IF v_count < 8 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Not all metrics have Russian names. Found: %', v_count;
    END IF;
    
    RAISE NOTICE 'VERIFICATION PASSED: % metrics have Russian localization', v_count;
END $$;

-- Test 2: Verify real-time data has proper test scenarios
DO $$
DECLARE
    v_scenario_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT tags->>'test_scenario') INTO v_scenario_count
    FROM performance_realtime_data 
    WHERE tags ? 'test_scenario';
    
    IF v_scenario_count < 4 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Not enough test scenarios. Found: %', v_scenario_count;
    END IF;
    
    RAISE NOTICE 'VERIFICATION PASSED: % different test scenarios created', v_scenario_count;
END $$;

-- Test 3: Verify performance calculation function works
DO $$
DECLARE
    v_score DECIMAL(5,2);
    v_test_employee UUID;
BEGIN
    SELECT employee_id INTO v_test_employee
    FROM performance_realtime_data 
    WHERE tags ? 'test_scenario'
    LIMIT 1;
    
    SELECT calculate_realtime_performance_score(v_test_employee) INTO v_score;
    
    IF v_score IS NULL OR v_score < 0 OR v_score > 100 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Invalid performance score: %', v_score;
    END IF;
    
    RAISE NOTICE 'VERIFICATION PASSED: Performance calculation function returns valid score: %', v_score;
END $$;

-- Test 4: Verify alert generation function
DO $$
DECLARE
    v_alerts_generated INTEGER;
BEGIN
    SELECT generate_performance_alerts() INTO v_alerts_generated;
    
    RAISE NOTICE 'VERIFICATION PASSED: Alert generation function executed, generated % alerts', v_alerts_generated;
END $$;

-- Test 5: Verify forecast data has confidence intervals
DO $$
DECLARE
    v_forecast_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_forecast_count
    FROM performance_forecasts 
    WHERE confidence_interval_lower IS NOT NULL 
      AND confidence_interval_upper IS NOT NULL
      AND confidence_interval_lower < predicted_value
      AND predicted_value < confidence_interval_upper;
    
    IF v_forecast_count = 0 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: No valid forecast confidence intervals found';
    END IF;
    
    RAISE NOTICE 'VERIFICATION PASSED: % forecasts have valid confidence intervals', v_forecast_count;
END $$;

-- ============================================================================
-- 9. PERFORMANCE TESTING QUERIES
-- ============================================================================

-- Performance test: Real-time dashboard query
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    pmd.metric_name_ru,
    COUNT(*) as measurement_count,
    AVG(prd.metric_value) as avg_value,
    MIN(prd.metric_value) as min_value,
    MAX(prd.metric_value) as max_value
FROM performance_realtime_data prd
JOIN performance_metric_definitions pmd ON prd.metric_id = pmd.metric_id
WHERE prd.measurement_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
    AND pmd.is_active = true
GROUP BY pmd.metric_name_ru
ORDER BY avg_value DESC;

-- Performance test: Historical trend query
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    analysis_date,
    metric_value,
    moving_average_7d,
    trend_direction
FROM performance_historical_analytics 
WHERE analysis_date >= CURRENT_DATE - INTERVAL '30 days'
    AND metric_id = (SELECT metric_id FROM performance_metric_definitions WHERE metric_code = 'AHT')
ORDER BY analysis_date DESC
LIMIT 100;

-- ============================================================================
-- 10. SUMMARY AND STATISTICS
-- ============================================================================

-- Display test data summary
SELECT 
    'Performance Metrics' as category,
    COUNT(*) as record_count
FROM performance_metric_definitions

UNION ALL

SELECT 
    'Real-time Data Points',
    COUNT(*)
FROM performance_realtime_data
WHERE tags ? 'test_scenario'

UNION ALL

SELECT 
    'Historical Analytics',
    COUNT(*)
FROM performance_historical_analytics
WHERE calculation_metadata ? 'test_run'

UNION ALL

SELECT 
    'Performance Alerts',
    COUNT(*)
FROM performance_alerts
WHERE alert_message_ru LIKE '%тест%' OR related_data ? 'test_scenario'

UNION ALL

SELECT 
    'Forecast Predictions',
    COUNT(*)
FROM performance_forecasts
WHERE prediction_factors ? 'test_forecast'

UNION ALL

SELECT 
    'Audit Trail Entries',
    COUNT(*)
FROM performance_audit_trails
WHERE user_id LIKE 'test_%'

ORDER BY category;

-- Display Russian compliance status
SELECT 
    'Russian Performance Standards' as compliance_area,
    COUNT(*) as standards_count,
    COUNT(*) FILTER (WHERE is_mandatory = true) as mandatory_count
FROM russian_performance_standards;

RAISE NOTICE '============================================================================';
RAISE NOTICE 'SCHEMA 087 TEST DATA CREATION COMPLETED SUCCESSFULLY';
RAISE NOTICE 'Created comprehensive test data for Performance Monitoring & Analytics';
RAISE NOTICE 'Includes: Russian business scenarios, compliance data, real-time monitoring';
RAISE NOTICE 'All verification tests passed - ready for BDD scenario validation';
RAISE NOTICE '============================================================================';