-- =============================================================================
-- test_critical_integration_path.sql
-- TDD RED PHASE: Critical Integration Tests for Demo Path
-- =============================================================================
-- Purpose: Test the money-making path that demos well
-- Focus: Employee → Time Tracking → Forecasting → Optimization → Dashboard
-- =============================================================================

\echo '================================================================================'
\echo 'CRITICAL PATH INTEGRATION TESTS - These must work for demo!'
\echo '================================================================================'

-- TEST 1: Can we track an employee end-to-end?
\echo '\n🔴 TEST 1: Employee Journey (zup_agent_data → time_entries → realtime_dashboard)'
SELECT 'TEST 1.1: Employee exists in system' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM zup_agent_data 
        WHERE tab_n = '00001' 
        AND finish_work IS NULL
    )
    THEN 'PASS: Active employee found'
    ELSE 'FAIL: No active employee with tab_n 00001'
END as result;

SELECT 'TEST 1.2: Employee has time entries today' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM argus_time_entries ate
        JOIN zup_agent_data zad ON zad.tab_n = ate.employee_tab_n
        WHERE ate.employee_tab_n = '00001'
        AND ate.entry_date = CURRENT_DATE
    )
    THEN 'PASS: Time entries found for today'
    ELSE 'FAIL: No time entries for employee today'
END as result;

SELECT 'TEST 1.3: Employee appears in real-time dashboard' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM agent_status_realtime asr
        WHERE asr.employee_tab_n = '00001'
        AND asr.last_updated > CURRENT_TIMESTAMP - INTERVAL '5 minutes'
    )
    THEN 'PASS: Employee visible in real-time dashboard'
    ELSE 'FAIL: Employee missing from real-time dashboard'
END as result;

-- TEST 2: Does forecasting actually use real data?
\echo '\n🔴 TEST 2: Forecasting Chain (historical → forecasts → requirements)'
SELECT 'TEST 2.1: Historical data exists' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM historical_data 
        WHERE data_datetime >= CURRENT_DATE - INTERVAL '30 days'
    )
    THEN 'PASS: Recent historical data found'
    ELSE 'FAIL: No recent historical data'
END as result;

SELECT 'TEST 2.2: Forecasts generated from historical data' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM call_volume_forecasts cvf
        JOIN forecasting_projects fp ON fp.id = cvf.project_id
        WHERE cvf.forecast_datetime::date >= CURRENT_DATE
        AND fp.project_status = 'COMPLETED'
    )
    THEN 'PASS: Active forecasts found'
    ELSE 'FAIL: No active forecasts from projects'
END as result;

SELECT 'TEST 2.3: Operator requirements calculated' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM operator_forecasts of
        JOIN forecasting_projects fp ON fp.id = of.project_id
        WHERE of.interval_datetime::date = CURRENT_DATE
        AND of.operator_requirement > 0
    )
    THEN 'PASS: Operator requirements calculated'
    ELSE 'FAIL: No operator requirements found'
END as result;

-- TEST 3: Can optimization read forecasts?
\echo '\n🔴 TEST 3: Optimization Chain (forecasts → optimization → schedules)'
SELECT 'TEST 3.1: Optimization project exists' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM optimization_projects
        WHERE project_status = 'ACTIVE'
        AND optimization_date >= CURRENT_DATE
    )
    THEN 'PASS: Active optimization project found'
    ELSE 'FAIL: No active optimization project'
END as result;

SELECT 'TEST 3.2: Optimization uses forecast data' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM coverage_analysis ca
        JOIN optimization_projects op ON op.id = ca.optimization_project_id
        JOIN operator_forecasts of ON of.interval_datetime = ca.time_interval
        WHERE ca.required_agents = of.operator_requirement
    )
    THEN 'PASS: Optimization linked to forecasts'
    ELSE 'FAIL: Optimization not using forecast data'
END as result;

SELECT 'TEST 3.3: Schedule suggestions generated' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM schedule_suggestions ss
        JOIN optimization_projects op ON op.id = ss.optimization_project_id
        WHERE ss.suggestion_status = 'PENDING'
        AND op.optimization_date >= CURRENT_DATE
    )
    THEN 'PASS: Schedule suggestions available'
    ELSE 'FAIL: No schedule suggestions generated'
END as result;

-- TEST 4: Do dashboards show real metrics?
\echo '\n🔴 TEST 4: Dashboard Integration (all data → executive KPIs)'
SELECT 'TEST 4.1: Service level calculated from real data' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM service_level_monitoring
        WHERE calculation_time > CURRENT_TIMESTAMP - INTERVAL '15 minutes'
        AND calls_offered > 0
        AND current_service_level BETWEEN 0 AND 100
    )
    THEN 'PASS: Service level shows real metrics'
    ELSE 'FAIL: Service level not calculating'
END as result;

SELECT 'TEST 4.2: Coverage analysis reflects staffing' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM coverage_analysis_realtime car
        WHERE car.analysis_time > CURRENT_TIMESTAMP - INTERVAL '15 minutes'
        AND car.required_agents > 0
        AND car.available_agents > 0
    )
    THEN 'PASS: Coverage analysis working'
    ELSE 'FAIL: Coverage analysis broken'
END as result;

SELECT 'TEST 4.3: Executive KPIs aggregate correctly' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM executive_kpi_dashboard
        WHERE last_calculated > CURRENT_TIMESTAMP - INTERVAL '30 minutes'
        AND kpi_name IN ('Service Level', 'Agent Utilization', 'Forecast Accuracy')
        AND kpi_value IS NOT NULL
    )
    THEN 'PASS: Executive KPIs calculating'
    ELSE 'FAIL: Executive KPIs not aggregating'
END as result;

-- TEST 5: Time code integration
\echo '\n🔴 TEST 5: Time Code Display (Russian compliance)'
SELECT 'TEST 5.1: Time codes properly linked' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM v_realtime_dashboard
        WHERE time_code_display LIKE '%-%'
        AND time_code_display IS NOT NULL
    )
    THEN 'PASS: Time codes display with descriptions'
    ELSE 'FAIL: Time codes not properly linked'
END as result;

-- Performance test
\echo '\n🔴 TEST 6: Performance Requirements'
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate dashboard query joining all critical tables
    PERFORM COUNT(*) FROM agent_status_realtime asr
    JOIN zup_agent_data zad ON zad.tab_n = asr.employee_tab_n
    JOIN service_level_monitoring slm ON true
    JOIN coverage_analysis_realtime car ON true
    JOIN executive_kpi_dashboard ekd ON true
    LIMIT 1;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
    
    RAISE NOTICE 'TEST 6: Dashboard query performance - Duration: %ms', duration_ms;
    
    IF duration_ms < 10 THEN
        RAISE NOTICE 'PASS: Dashboard query < 10ms (%ms)', duration_ms;
    ELSE
        RAISE NOTICE 'FAIL: Dashboard query too slow: %ms (target < 10ms)', duration_ms;
    END IF;
END $$;

\echo '\n================================================================================'
\echo 'CRITICAL PATH TEST SUMMARY'
\echo 'These integration points MUST work for successful demo!'
\echo '================================================================================'