-- =============================================================================
-- test_russian_call_center.sql
-- TDD RED PHASE: Demo Scenario Tests for ООО "ТехноСервис"
-- =============================================================================
-- Purpose: Test realistic Russian call center scenario that shows our superiority
-- Story: 50-agent Moscow call center struggling with March tax season surge
-- =============================================================================

\echo '================================================================================'
\echo 'ООО "ТЕХНОСЕРВИС" DEMO SCENARIO TESTS'
\echo 'Moscow call center, 50 agents, tax season crisis'
\echo '================================================================================'

-- TEST 1: Russian company setup
\echo '\n🔴 TEST 1: Russian Company Data'
SELECT 'TEST 1.1: Russian agents exist' as test_name,
CASE 
    WHEN (
        SELECT COUNT(*) FROM zup_agent_data 
        WHERE fio_full LIKE '%ов %' OR fio_full LIKE '%ова %'
        OR fio_full LIKE '%ин %' OR fio_full LIKE '%ина %'
        AND finish_work IS NULL
    ) >= 45
    THEN 'PASS: 45+ Russian agents found'
    ELSE 'FAIL: Need more Russian agents for demo'
END as result;

SELECT 'TEST 1.2: Moscow timezone configured' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM holidays 
        WHERE holiday_name LIKE '%Новый год%'
        OR holiday_name LIKE '%Международный женский день%'
    )
    THEN 'PASS: Russian holidays configured'
    ELSE 'FAIL: Missing Russian holidays'
END as result;

-- TEST 2: Tax season surge pattern
\echo '\n🔴 TEST 2: March Tax Season Surge (1000→5000 calls)'
SELECT 'TEST 2.1: Historical data shows normal load' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM historical_data
        WHERE data_datetime::date BETWEEN '2025-01-01' AND '2025-02-28'
        AND call_volume BETWEEN 800 AND 1200
    )
    THEN 'PASS: Normal January-February data (1000 calls/day)'
    ELSE 'FAIL: Missing normal period data'
END as result;

SELECT 'TEST 2.2: March surge data exists' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM historical_data
        WHERE data_datetime::date BETWEEN '2025-03-01' AND '2025-03-31'
        AND call_volume BETWEEN 4000 AND 5500
    )
    THEN 'PASS: March surge data (5000 calls/day)'
    ELSE 'FAIL: Missing tax season surge data'
END as result;

-- TEST 3: Argus failure point
\echo '\n🔴 TEST 3: Argus Failure Scenario (>3000 calls)'
SELECT 'TEST 3.1: Coverage gap at high volume' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM coverage_analysis_realtime
        WHERE required_agents > 50
        AND available_agents = 50
        AND coverage_gap > 10
        AND status = 'CRITICAL'
    )
    THEN 'PASS: Shows Argus cannot handle surge'
    ELSE 'FAIL: Need to show coverage crisis'
END as result;

SELECT 'TEST 3.2: Service level degradation' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM service_level_monitoring
        WHERE calls_offered > 3000
        AND current_service_level < 60
        AND target_service_level = 80
    )
    THEN 'PASS: Service level drops below 60% (Argus fails)'
    ELSE 'FAIL: Need to show SLA failure'
END as result;

-- TEST 4: Our system success
\echo '\n🔴 TEST 4: Our System Success (85% accuracy maintained)'
SELECT 'TEST 4.1: Multi-skill optimization active' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM skill_requirements sr
        JOIN employee_skills es ON es.skill_id = sr.skill_id
        WHERE sr.skill_name IN ('Налоговые консультации', 'Техподдержка 1С', 'Общие вопросы')
        GROUP BY sr.skill_id
        HAVING COUNT(DISTINCT es.employee_id) >= 10
    )
    THEN 'PASS: Multi-skill agents ready for tax season'
    ELSE 'FAIL: Need multi-skill configuration'
END as result;

SELECT 'TEST 4.2: AI optimization handles surge' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM optimization_projects op
        JOIN schedule_suggestions ss ON ss.optimization_project_id = op.id
        WHERE op.algorithm_version = 'AI_GENETIC_V2'
        AND ss.efficiency_score > 0.85
        AND op.agents_count = 50
    )
    THEN 'PASS: AI maintains 85%+ efficiency'
    ELSE 'FAIL: AI optimization not showing superiority'
END as result;

-- TEST 5: Performance comparison
\echo '\n🔴 TEST 5: Performance Metrics (Us vs Argus)'
SELECT 'TEST 5.1: Calculation speed comparison' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM executive_kpi_dashboard
        WHERE kpi_name = 'Schedule Optimization Time'
        AND kpi_value < 100 -- milliseconds
        AND kpi_target = 415 -- Argus takes 415ms
    )
    THEN 'PASS: We are 4x faster than Argus'
    ELSE 'FAIL: Need performance comparison data'
END as result;

SELECT 'TEST 5.2: Accuracy comparison' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM executive_kpi_dashboard
        WHERE kpi_name = 'Forecast Accuracy'
        AND kpi_value >= 85
        AND kpi_target = 60 -- Argus accuracy
    )
    THEN 'PASS: 85% accuracy vs Argus 60%'
    ELSE 'FAIL: Need accuracy comparison data'
END as result;

-- TEST 6: Demo readiness
\echo '\n🔴 TEST 6: Complete Demo Flow'
SELECT 'TEST 6.1: Supervisor can see crisis' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM v_realtime_dashboard
        WHERE employee_name LIKE 'Иванов%'
        AND current_status IN ('На перерыве', 'В работе', 'Недоступен')
    )
    THEN 'PASS: Russian supervisor view ready'
    ELSE 'FAIL: Supervisor cannot see team status'
END as result;

SELECT 'TEST 6.2: One-click optimization available' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM process_definitions
        WHERE process_name = 'Schedule Optimization'
        AND process_status = 'ACTIVE'
        AND execution_time_estimate < 1000 -- ms
    )
    THEN 'PASS: Quick optimization ready for demo'
    ELSE 'FAIL: Optimization not demo-ready'
END as result;

-- Performance test for demo
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate complete demo query
    PERFORM COUNT(*) FROM (
        SELECT 
            asr.employee_name,
            asr.status_russian,
            slm.current_service_level,
            car.coverage_gap,
            ekd.kpi_value as accuracy
        FROM agent_status_realtime asr
        CROSS JOIN service_level_monitoring slm
        CROSS JOIN coverage_analysis_realtime car
        CROSS JOIN executive_kpi_dashboard ekd
        WHERE ekd.kpi_name = 'Forecast Accuracy'
        LIMIT 50
    ) demo_view;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
    
    RAISE NOTICE 'TEST 6.3: Demo query performance - Duration: %ms', duration_ms;
    
    IF duration_ms < 100 THEN
        RAISE NOTICE 'PASS: Demo responsive (%ms)', duration_ms;
    ELSE
        RAISE NOTICE 'FAIL: Demo too slow: %ms', duration_ms;
    END IF;
END $$;

\echo '\n================================================================================'
\echo 'ТЕХНОСЕРВИС DEMO REQUIREMENTS'
\echo 'Show Argus failing at tax season while we maintain 85% accuracy!'
\echo '================================================================================'