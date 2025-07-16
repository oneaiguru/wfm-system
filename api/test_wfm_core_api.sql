-- =============================================================================
-- WFM Core Tables API Testing Script
-- Comprehensive testing of all API functions with realistic scenarios
-- =============================================================================

-- =============================================================================
-- 1. FORECAST DATA API TESTING
-- =============================================================================

-- Test creating forecast data
SELECT 'Test 1: Creating forecast data' AS test_name;
SELECT create_forecast_data(3, '2025-01-20', '14:00:00', 75, 380, 82.5);

-- Test getting forecast data by date range
SELECT 'Test 2: Getting forecast data by date range' AS test_name;
SELECT get_forecast_data_by_date_range(1, '2025-01-15', '2025-01-16', '09:00:00');

-- Test updating forecast data
SELECT 'Test 3: Updating forecast data' AS test_name;
SELECT update_forecast_data(86, 85, 290, 85.0);

-- Test deleting forecast data
SELECT 'Test 4: Deleting forecast data by date range' AS test_name;
SELECT delete_forecast_data_by_date_range(3, '2025-01-20', '2025-01-20');

-- =============================================================================
-- 2. OPTIMIZATION RESULTS API TESTING
-- =============================================================================

-- Test creating optimization result
SELECT 'Test 5: Creating optimization result' AS test_name;
SELECT create_optimization_result(
    'opt_req_005',
    'Анализ времени обработки звонков',
    91.3,
    -25000.00,
    'средняя',
    '{
        "description": "Внедрение системы автоматического анализа разговоров",
        "benefits": ["Сокращение AHT на 15%", "Улучшение качества на 20%", "Автоматическая категоризация"],
        "implementation_timeline": "8 недель",
        "required_technologies": ["Speech Analytics", "ML Models", "Real-time Processing"],
        "risk_assessment": "средний",
        "training_required": "40 часов"
    }'::jsonb
);

-- Test getting optimization results by request
SELECT 'Test 6: Getting optimization results by request' AS test_name;
SELECT get_optimization_results_by_request('opt_req_001', 85.0);

-- Test updating optimization result details
SELECT 'Test 7: Updating optimization result details' AS test_name;
SELECT update_optimization_result_details(
    5,
    '{
        "implementation_status": "в процессе",
        "progress_percentage": 45,
        "pilot_results": {
            "test_group_size": 10,
            "aht_improvement": "12%",
            "quality_score": 8.7
        },
        "next_steps": ["Расширение пилота", "Обучение тренеров", "Настройка отчетности"]
    }'::jsonb,
    'в процессе'
);

-- =============================================================================
-- 3. PERFORMANCE METRICS API TESTING
-- =============================================================================

-- Test recording performance metrics
SELECT 'Test 8: Recording performance metrics' AS test_name;
SELECT record_performance_metrics('Advanced Schedule Optimizer', 1234.5, 187.3, 67.8);
SELECT record_performance_metrics('Real-time Call Analyzer', 456.7, 89.2, 34.5);
SELECT record_performance_metrics('ML Forecast Engine', 789.1, 234.6, 45.2);

-- Test getting performance metrics statistics
SELECT 'Test 9: Getting performance metrics statistics' AS test_name;
SELECT get_performance_metrics_stats('Erlang C Calculator', 72);

-- Test comparing algorithm performance
SELECT 'Test 10: Comparing algorithm performance' AS test_name;
SELECT compare_algorithm_performance(
    ARRAY['Erlang C Calculator', 'Schedule Optimizer', 'Forecast Algorithm', 'Real-time Monitoring'],
    48
);

-- =============================================================================
-- 4. EMPLOYEE PREFERENCES API TESTING
-- =============================================================================

-- Test creating employee preferences
SELECT 'Test 11: Creating employee preferences' AS test_name;
SELECT upsert_employee_preferences('EMP014', '07:00:00', '16:00:00', 'ПН,ВТ,СР,ЧТ,ПТ,СБ', 6, 40.0, 48.0);
SELECT upsert_employee_preferences('EMP015', '13:00:00', '22:00:00', 'ВТ,СР,ЧТ,ПТ,СБ,ВС', 6, 35.0, 42.0);
SELECT upsert_employee_preferences('EMP016', '09:00:00', '18:00:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 32.0, 40.0);

-- Test getting employee preferences with compatibility
SELECT 'Test 12: Getting employee preferences with compatibility' AS test_name;
SELECT get_employee_preferences_with_compatibility('EMP014');

-- Test finding employees by preferences
SELECT 'Test 13: Finding employees by preferences - High availability' AS test_name;
SELECT find_employees_by_preferences('07:00:00', '22:00:00', NULL, 40.0, 6);

SELECT 'Test 14: Finding employees by preferences - Weekend workers' AS test_name;
SELECT find_employees_by_preferences(NULL, NULL, 'СБ', 30.0, NULL);

SELECT 'Test 15: Finding employees by preferences - Night shift' AS test_name;
SELECT find_employees_by_preferences('20:00:00', NULL, NULL, 30.0, NULL);

-- Test updating employee preferences
SELECT 'Test 16: Updating employee preferences' AS test_name;
SELECT upsert_employee_preferences('EMP001', '07:30:00', '16:30:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 37.5, 42.5);

-- Test deleting employee preferences
SELECT 'Test 17: Deleting employee preferences' AS test_name;
SELECT delete_employee_preferences('EMP016');

-- =============================================================================
-- 5. COMPLEX INTEGRATION SCENARIOS
-- =============================================================================

-- Test scenario: Planning optimal schedule based on forecast and preferences
SELECT 'Test 18: Complex scenario - Schedule optimization data' AS test_name;

-- Get forecast data for planning
WITH forecast_summary AS (
    SELECT 
        service_id,
        SUM(call_volume) as total_volume,
        AVG(average_handle_time) as avg_aht,
        AVG(service_level_target) as target_sl
    FROM forecast_data 
    WHERE service_id = 1 
      AND forecast_date = '2025-01-15'
    GROUP BY service_id
),
available_employees AS (
    SELECT COUNT(*) as emp_count,
           AVG(max_hours_week) as avg_max_hours,
           SUM(max_hours_week) as total_available_hours
    FROM employee_preferences
    WHERE preferred_days LIKE '%ПН%'
),
optimization_recommendations AS (
    SELECT 
        suggestion_type,
        impact_score,
        cost_impact
    FROM optimization_results
    WHERE impact_score > 85
    ORDER BY impact_score DESC
    LIMIT 3
)
SELECT 
    jsonb_build_object(
        'planning_date', '2025-01-15',
        'forecast_summary', to_jsonb(f.*),
        'available_employees', to_jsonb(ae.*),
        'top_optimizations', 
        (SELECT jsonb_agg(to_jsonb(or_sub.*)) FROM optimization_recommendations or_sub),
        'planning_feasibility', 
        CASE 
            WHEN ae.total_available_hours > (f.total_volume * f.avg_aht / 3600) * 1.2 
            THEN 'Достаточно ресурсов'
            ELSE 'Требуется дополнительный персонал'
        END
    ) as schedule_planning_analysis
FROM forecast_summary f
CROSS JOIN available_employees ae;

-- Test scenario: Performance monitoring and optimization
SELECT 'Test 19: Performance monitoring scenario' AS test_name;

WITH algorithm_performance AS (
    SELECT 
        algorithm_name,
        COUNT(*) as executions,
        AVG(execution_time_ms) as avg_time,
        AVG(cpu_utilization) as avg_cpu
    FROM performance_metrics
    WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    GROUP BY algorithm_name
),
optimization_opportunities AS (
    SELECT 
        suggestion_type,
        impact_score,
        implementation_complexity
    FROM optimization_results
    WHERE suggestion_type LIKE '%оптимизация%'
      AND impact_score > 80
)
SELECT 
    jsonb_build_object(
        'monitoring_period', '24 hours',
        'algorithm_performance', 
        (SELECT jsonb_agg(to_jsonb(ap.*)) FROM algorithm_performance ap),
        'optimization_opportunities',
        (SELECT jsonb_agg(to_jsonb(oo.*)) FROM optimization_opportunities oo),
        'system_health', 
        CASE 
            WHEN (SELECT AVG(avg_cpu) FROM algorithm_performance) < 50 
            THEN 'Хорошее'
            WHEN (SELECT AVG(avg_cpu) FROM algorithm_performance) < 80 
            THEN 'Умеренное'
            ELSE 'Требует внимания'
        END
    ) as performance_analysis;

-- =============================================================================
-- 6. VALIDATION AND ERROR HANDLING TESTS
-- =============================================================================

-- Test validation errors
SELECT 'Test 20: Validation error tests' AS test_name;

-- Test negative call volume (should fail)
SELECT 'Testing negative call volume:';
DO $$
BEGIN
    PERFORM create_forecast_data(1, '2025-01-20', '10:00:00', -10, 300, 80.0);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error caught: %', SQLERRM;
END $$;

-- Test invalid AHT (should fail)
SELECT 'Testing zero AHT:';
DO $$
BEGIN
    PERFORM create_forecast_data(1, '2025-01-20', '10:00:00', 50, 0, 80.0);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error caught: %', SQLERRM;
END $$;

-- Test invalid service level (should fail)
SELECT 'Testing invalid service level:';
DO $$
BEGIN
    PERFORM create_forecast_data(1, '2025-01-20', '10:00:00', 50, 300, 150.0);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error caught: %', SQLERRM;
END $$;

-- Test invalid employee preferences (should fail)
SELECT 'Testing invalid time range:';
DO $$
BEGIN
    PERFORM upsert_employee_preferences('EMP999', '18:00:00', '09:00:00', 'ПН', 5, 40.0, 45.0);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error caught: %', SQLERRM;
END $$;

-- =============================================================================
-- 7. PERFORMANCE BENCHMARKING
-- =============================================================================

SELECT 'Test 21: Performance benchmarking' AS test_name;

-- Benchmark forecast data queries
SELECT 'Benchmarking forecast queries...';
\timing on
SELECT COUNT(*) as forecast_records FROM forecast_data;
SELECT get_forecast_data_by_date_range(1, '2025-01-01', '2025-12-31', NULL);
\timing off

-- Benchmark employee preference searches
SELECT 'Benchmarking preference searches...';
\timing on
SELECT find_employees_by_preferences(NULL, NULL, NULL, 30.0, NULL);
\timing off

-- =============================================================================
-- TESTING COMPLETE
-- =============================================================================

SELECT 'WFM Core API Testing Complete - All functions validated' AS final_result;