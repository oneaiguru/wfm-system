-- =============================================================================
-- verify_dashboard_works.sql
-- VERIFY PHASE: Test that our TDD implementation actually works
-- =============================================================================

-- Run the original failing tests to see if they now pass
\echo 'RUNNING VERIFICATION TESTS...'
\echo '================================'

-- Test 1: Real-time agent status data exists
\echo 'TEST 1: Real-time agent status'
SELECT 
    COUNT(*) as agent_count,
    MAX(last_updated) as latest_update,
    CASE 
        WHEN MAX(last_updated) > CURRENT_TIMESTAMP - INTERVAL '1 minute'
        THEN '✅ PASS: Recent status data found'
        ELSE '❌ FAIL: No recent status data'
    END as result
FROM agent_status_realtime;

-- Test 2: Service level monitoring shows current SLA
\echo 'TEST 2: Service level monitoring'
SELECT 
    COUNT(*) as service_count,
    AVG(current_service_level) as avg_service_level,
    CASE 
        WHEN MAX(calculation_time) > CURRENT_TIMESTAMP - INTERVAL '5 minutes'
        THEN '✅ PASS: Recent SLA calculation found'
        ELSE '❌ FAIL: No recent SLA data'
    END as result
FROM service_level_monitoring;

-- Test 3: Coverage analysis shows current gaps
\echo 'TEST 3: Coverage analysis'
SELECT 
    COUNT(*) as coverage_records,
    AVG(coverage_percentage) as avg_coverage,
    CASE 
        WHEN MAX(analysis_time) > CURRENT_TIMESTAMP - INTERVAL '15 minutes'
        THEN '✅ PASS: Recent coverage analysis found'
        ELSE '❌ FAIL: No recent coverage analysis'
    END as result
FROM coverage_analysis_realtime;

-- Test 4: Executive dashboard has current KPIs
\echo 'TEST 4: Executive KPI dashboard'
SELECT 
    COUNT(*) as kpi_count,
    CASE 
        WHEN MAX(last_calculated) > CURRENT_TIMESTAMP - INTERVAL '30 minutes'
        THEN '✅ PASS: Recent KPI data found'
        ELSE '❌ FAIL: No recent KPI data'
    END as result
FROM executive_kpi_dashboard;

-- Test 5: Russian status descriptions display correctly
\echo 'TEST 5: Russian status display'
SELECT 
    COUNT(*) as russian_status_count,
    string_agg(DISTINCT status_russian, ', ') as sample_statuses,
    CASE 
        WHEN COUNT(*) > 0 AND MIN(length(status_russian)) > 0
        THEN '✅ PASS: Russian status descriptions found'
        ELSE '❌ FAIL: No Russian status descriptions'
    END as result
FROM v_agent_status_russian;

-- Test 6: Time code integration works with dashboard
\echo 'TEST 6: Time code integration'
SELECT 
    COUNT(*) as dashboard_records,
    COUNT(DISTINCT time_code_display) as unique_time_codes,
    CASE 
        WHEN COUNT(*) > 0 AND COUNT(time_code_display) > 0
        THEN '✅ PASS: Time codes display in dashboard'
        ELSE '❌ FAIL: No time code display'
    END as result
FROM v_realtime_dashboard;

-- Test 7: Dashboard performance test
\echo 'TEST 7: Dashboard performance'
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate full dashboard query
    PERFORM COUNT(*) FROM v_realtime_dashboard;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
    
    RAISE NOTICE 'Dashboard query duration: %ms', duration_ms;
    
    IF duration_ms < 2000 THEN
        RAISE NOTICE '✅ PASS: Dashboard responds in %ms (< 2 seconds)', duration_ms;
    ELSE
        RAISE NOTICE '❌ FAIL: Dashboard too slow: %ms (> 2 seconds)', duration_ms;
    END IF;
END $$;

-- Test 8: Demo scenario data exists and makes sense
\echo 'TEST 8: Demo scenario data'
SELECT 
    (SELECT COUNT(*) FROM zup_agent_data WHERE finish_work IS NULL) as active_employees,
    (SELECT COUNT(*) FROM argus_time_entries WHERE entry_date = CURRENT_DATE) as todays_time_entries,
    (SELECT COUNT(*) FROM call_volume_forecasts WHERE forecast_datetime::date = CURRENT_DATE) as todays_forecasts,
    CASE 
        WHEN (SELECT COUNT(*) FROM zup_agent_data WHERE finish_work IS NULL) >= 5
        AND EXISTS(SELECT 1 FROM argus_time_entries WHERE entry_date = CURRENT_DATE)
        AND EXISTS(SELECT 1 FROM call_volume_forecasts WHERE forecast_datetime::date = CURRENT_DATE)
        THEN '✅ PASS: Sufficient demo data exists'
        ELSE '❌ FAIL: Insufficient demo data'
    END as result;

-- Test 9: Critical schema accessibility test
\echo 'TEST 9: Schema accessibility'
DO $$
DECLARE
    schema_test_result TEXT := '✅ PASS: All critical schemas accessible';
    error_details TEXT;
BEGIN
    -- Test critical tables exist and are queryable
    PERFORM COUNT(*) FROM zup_agent_data LIMIT 1;
    PERFORM COUNT(*) FROM argus_time_types LIMIT 1;
    PERFORM COUNT(*) FROM agent_status_realtime LIMIT 1;
    PERFORM COUNT(*) FROM service_level_monitoring LIMIT 1;
    PERFORM COUNT(*) FROM executive_kpi_dashboard LIMIT 1;
    PERFORM COUNT(*) FROM v_realtime_dashboard LIMIT 1;
    
    RAISE NOTICE '%', schema_test_result;
    
EXCEPTION WHEN OTHERS THEN
    error_details := SQLERRM;
    RAISE NOTICE '❌ FAIL: Schema error: %', error_details;
END $$;

-- Test 10: Demo workflows are ready
\echo 'TEST 10: Demo workflow readiness'
SELECT 
    COUNT(DISTINCT pd.process_name) as active_process_types,
    COUNT(pi.id) as active_instances,
    COUNT(wt.id) as pending_tasks,
    CASE 
        WHEN COUNT(pi.id) > 0 AND COUNT(wt.id) > 0
        THEN '✅ PASS: Active workflows available for demo'
        ELSE '❌ FAIL: No active workflows for demo'
    END as result
FROM process_definitions pd
LEFT JOIN process_instances pi ON pi.process_definition_id = pd.id AND pi.process_status = 'ACTIVE'
LEFT JOIN workflow_tasks wt ON wt.process_instance_id = pi.id AND wt.task_status IN ('PENDING', 'IN_PROGRESS');

-- BONUS: Show sample dashboard data for verification
\echo 'BONUS: Sample dashboard data preview'
SELECT 
    'AGENT STATUS' as data_type,
    employee_name,
    status_russian,
    time_code_display,
    to_char(last_updated, 'HH24:MI:SS') as last_update_time
FROM v_realtime_dashboard 
LIMIT 5;

SELECT 
    'SERVICE LEVELS' as data_type,
    service_name,
    current_service_level || '%' as current_sl,
    target_service_level || '%' as target_sl,
    calls_offered || ' offered' as call_stats
FROM service_level_monitoring
LIMIT 3;

SELECT 
    'EXECUTIVE KPIs' as data_type,
    kpi_name,
    kpi_value || ' ' || COALESCE(kpi_unit, '') as current_value,
    kpi_target || ' ' || COALESCE(kpi_unit, '') as target_value,
    kpi_status
FROM executive_kpi_dashboard
WHERE kpi_name IN ('Service Level Achievement', 'Agent Utilization', 'Customer Satisfaction')
LIMIT 3;

\echo '================================'
\echo 'VERIFICATION COMPLETE!'