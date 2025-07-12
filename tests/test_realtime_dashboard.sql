-- =============================================================================
-- test_realtime_dashboard.sql
-- TDD/BDD FAILING TESTS - Real-time Dashboard Implementation
-- =============================================================================
-- RED PHASE: Write failing tests for BDD scenarios
-- Purpose: Ensure real-time dashboard actually works before demo
-- =============================================================================

-- Test 1: FAILING - Real-time agent status data exists
SELECT 'TEST 1: Real-time agent status' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM agent_status_realtime WHERE last_updated > CURRENT_TIMESTAMP - INTERVAL '1 minute')
    THEN 'PASS: Recent status data found'
    ELSE 'FAIL: No recent status data'
END as result;

-- Test 2: FAILING - Service level monitoring shows current SLA
SELECT 'TEST 2: Service level monitoring' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM service_level_monitoring WHERE calculation_time > CURRENT_TIMESTAMP - INTERVAL '5 minutes')
    THEN 'PASS: Recent SLA calculation found'
    ELSE 'FAIL: No recent SLA data'
END as result;

-- Test 3: FAILING - Coverage analysis shows current gaps
SELECT 'TEST 3: Coverage analysis' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM coverage_analysis_realtime WHERE analysis_time > CURRENT_TIMESTAMP - INTERVAL '15 minutes')
    THEN 'PASS: Recent coverage analysis found'
    ELSE 'FAIL: No recent coverage analysis'
END as result;

-- Test 4: FAILING - Executive dashboard has current KPIs
SELECT 'TEST 4: Executive KPI dashboard' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM executive_kpi_dashboard WHERE last_calculated > CURRENT_TIMESTAMP - INTERVAL '30 minutes')
    THEN 'PASS: Recent KPI data found'
    ELSE 'FAIL: No recent KPI data'
END as result;

-- Test 5: FAILING - Russian status descriptions display correctly
SELECT 'TEST 5: Russian status display' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM v_agent_status_russian WHERE status_russian IS NOT NULL)
    THEN 'PASS: Russian status descriptions found'
    ELSE 'FAIL: No Russian status descriptions'
END as result;

-- Test 6: FAILING - Time code integration works with dashboard
SELECT 'TEST 6: Time code integration' as test_name,
CASE 
    WHEN EXISTS(SELECT 1 FROM v_realtime_dashboard WHERE time_code_display IS NOT NULL)
    THEN 'PASS: Time codes display in dashboard'
    ELSE 'FAIL: No time code display'
END as result;

-- Test 7: FAILING - Dashboard responds within 2 seconds
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate dashboard query
    PERFORM COUNT(*) FROM agent_status_realtime 
    JOIN service_level_monitoring ON true
    JOIN coverage_analysis_realtime ON true;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
    
    RAISE NOTICE 'TEST 7: Dashboard performance - Duration: %ms', duration_ms;
    
    IF duration_ms < 2000 THEN
        RAISE NOTICE 'PASS: Dashboard responds in %ms (< 2 seconds)', duration_ms;
    ELSE
        RAISE NOTICE 'FAIL: Dashboard too slow: %ms (> 2 seconds)', duration_ms;
    END IF;
END $$;

-- Test 8: FAILING - Demo scenario data exists and makes sense
SELECT 'TEST 8: Demo scenario data' as test_name,
CASE 
    WHEN (SELECT COUNT(*) FROM zup_agent_data WHERE finish_work IS NULL) >= 5
    AND EXISTS(SELECT 1 FROM argus_time_entries WHERE entry_date = CURRENT_DATE)
    AND EXISTS(SELECT 1 FROM call_volume_forecasts WHERE forecast_datetime::date = CURRENT_DATE)
    THEN 'PASS: Sufficient demo data exists'
    ELSE 'FAIL: Insufficient demo data'
END as result;

-- Test 9: FAILING - All 30 schemas can be queried without errors
DO $$
DECLARE
    schema_test_result TEXT := 'PASS: All schemas accessible';
BEGIN
    -- Test core foundation schemas
    PERFORM COUNT(*) FROM holidays LIMIT 1;
    PERFORM COUNT(*) FROM zup_agent_data LIMIT 1;
    PERFORM COUNT(*) FROM argus_time_types LIMIT 1;
    PERFORM COUNT(*) FROM zup_api_endpoints LIMIT 1;
    
    -- Test business process schemas
    PERFORM COUNT(*) FROM vacation_balance_calculations LIMIT 1;
    PERFORM COUNT(*) FROM employee_requests LIMIT 1;
    
    -- Test forecasting schemas
    PERFORM COUNT(*) FROM forecasting_projects LIMIT 1;
    PERFORM COUNT(*) FROM call_volume_forecasts LIMIT 1;
    
    -- Test optimization schemas
    PERFORM COUNT(*) FROM optimization_projects LIMIT 1;
    PERFORM COUNT(*) FROM schedule_suggestions LIMIT 1;
    
    -- Test reporting schemas
    PERFORM COUNT(*) FROM report_definitions LIMIT 1;
    PERFORM COUNT(*) FROM tabel_t13_headers LIMIT 1;
    
    -- Test process management schemas
    PERFORM COUNT(*) FROM process_definitions LIMIT 1;
    PERFORM COUNT(*) FROM workflow_tasks LIMIT 1;
    
    RAISE NOTICE 'TEST 9: Schema accessibility - %', schema_test_result;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 9: FAIL - Schema error: %', SQLERRM;
END $$;

-- Test 10: FAILING - Demo workflows can be executed end-to-end
SELECT 'TEST 10: End-to-end workflow test' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM process_definitions pd
        JOIN process_instances pi ON pi.process_definition_id = pd.id
        JOIN workflow_tasks wt ON wt.process_instance_id = pi.id
        WHERE pd.process_status = 'ACTIVE'
        AND pi.process_status = 'ACTIVE'
        AND wt.task_status IN ('PENDING', 'IN_PROGRESS')
    )
    THEN 'PASS: Active workflows found'
    ELSE 'FAIL: No active workflows for demo'
END as result;

-- EXPECTED RESULTS: ALL TESTS SHOULD FAIL INITIALLY
-- This proves our TDD approach - we build to make these pass!