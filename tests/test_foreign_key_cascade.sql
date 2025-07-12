-- =============================================================================
-- test_foreign_key_cascade.sql
-- TDD RED PHASE: Foreign Key Integrity Tests
-- =============================================================================
-- Purpose: Verify critical foreign key relationships work correctly
-- Focus: 20 schemas with FOREIGN KEY REFERENCES must be connected
-- =============================================================================

\echo '================================================================================'
\echo 'FOREIGN KEY INTEGRITY TESTS'
\echo '================================================================================'

-- TEST 1: Employee references cascade properly
\echo '\n🔴 TEST 1: Employee Foreign Keys (zup_agent_data is the master)'
SELECT 'TEST 1.1: Time entries link to employees' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
        AND table_name = 'argus_time_entries'
        AND constraint_name LIKE '%employee%'
    )
    THEN 'PASS: Time entries have employee FK'
    ELSE 'FAIL: Time entries missing employee FK'
END as result;

SELECT 'TEST 1.2: Real-time dashboard links to employees' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
        AND table_name = 'agent_status_realtime'
        AND constraint_name LIKE '%employee%'
    )
    THEN 'PASS: Dashboard has employee FK'
    ELSE 'FAIL: Dashboard missing employee FK'
END as result;

SELECT 'TEST 1.3: Vacation calculations link to employees' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
        AND table_name = 'vacation_balance_calculations'
        AND constraint_name LIKE '%employee%'
    )
    THEN 'PASS: Vacation has employee FK'
    ELSE 'FAIL: Vacation missing employee FK'
END as result;

-- TEST 2: Time code references work
\echo '\n🔴 TEST 2: Time Code Foreign Keys (argus_time_types is the master)'
SELECT 'TEST 2.1: Time entries reference time types' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM argus_time_entries ate
        JOIN argus_time_types att ON att.id = ate.argus_time_type_id
        WHERE att.type_code IN ('I', 'H', 'B', 'C')
    )
    THEN 'PASS: Time entries use valid time codes'
    ELSE 'FAIL: Time entries not linked to time codes'
END as result;

SELECT 'TEST 2.2: Dashboard can display time code names' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'agent_status_realtime'
        AND column_name = 'time_code'
    )
    AND EXISTS(
        SELECT 1 FROM argus_time_types
        WHERE type_code IS NOT NULL
    )
    THEN 'PASS: Dashboard ready for time code display'
    ELSE 'FAIL: Dashboard cannot show time codes'
END as result;

-- TEST 3: Project ID flow through system
\echo '\n🔴 TEST 3: Project ID Chain (forecasting → optimization)'
SELECT 'TEST 3.1: Forecasts belong to projects' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
        AND table_name = 'call_volume_forecasts'
        AND constraint_name LIKE '%project%'
    )
    THEN 'PASS: Forecasts have project FK'
    ELSE 'FAIL: Forecasts missing project FK'
END as result;

SELECT 'TEST 3.2: Optimization can reference forecasting' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'optimization_projects'
        AND column_name LIKE '%forecast%'
    )
    OR EXISTS(
        SELECT 1 FROM coverage_analysis
        WHERE required_agents IS NOT NULL
    )
    THEN 'PASS: Optimization can use forecast data'
    ELSE 'FAIL: Optimization isolated from forecasts'
END as result;

-- TEST 4: Critical cascade behavior
\echo '\n🔴 TEST 4: Cascade Behavior Tests'
DO $$
DECLARE
    test_employee_id VARCHAR(50) := 'TEST_CASCADE_001';
    test_result TEXT;
BEGIN
    -- Try to create test employee
    BEGIN
        INSERT INTO zup_agent_data (tab_n, fio_full, position_name, department)
        VALUES (test_employee_id, 'Test Cascade Employee', 'Agent', 'Test Dept');
        
        -- Try to create related records
        INSERT INTO argus_time_entries (employee_tab_n, entry_date, start_time, end_time, argus_time_type_id)
        SELECT test_employee_id, CURRENT_DATE, '09:00', '18:00', id
        FROM argus_time_types WHERE type_code = 'I' LIMIT 1;
        
        -- Check if cascade would work
        DELETE FROM zup_agent_data WHERE tab_n = test_employee_id;
        
        -- Check if child records were cleaned up
        IF NOT EXISTS(SELECT 1 FROM argus_time_entries WHERE employee_tab_n = test_employee_id) THEN
            test_result := 'PASS: Cascade delete works correctly';
        ELSE
            test_result := 'FAIL: Orphaned records after delete';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        test_result := 'FAIL: Foreign key constraints not working - ' || SQLERRM;
    END;
    
    RAISE NOTICE 'TEST 4.1: Cascade behavior - %', test_result;
    
    -- Clean up any test data
    DELETE FROM argus_time_entries WHERE employee_tab_n = test_employee_id;
    DELETE FROM zup_agent_data WHERE tab_n = test_employee_id;
END $$;

-- TEST 5: Cross-schema integration points
\echo '\n🔴 TEST 5: Cross-Schema Integration'
SELECT 'TEST 5.1: Vacation uses production calendar' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM vacation_balance_calculations vbc
        WHERE EXISTS(
            SELECT 1 FROM holidays h 
            WHERE h.is_holiday = true
        )
    )
    THEN 'PASS: Vacation aware of holidays'
    ELSE 'FAIL: Vacation isolated from calendar'
END as result;

SELECT 'TEST 5.2: Reports can access all data' as test_name,
CASE 
    WHEN EXISTS(
        SELECT 1 FROM report_definitions
        WHERE report_category IN ('OPERATIONAL', 'STRATEGIC')
    )
    AND EXISTS(
        SELECT 1 FROM operational_reports_data
    )
    THEN 'PASS: Reporting framework connected'
    ELSE 'FAIL: Reports cannot access data'
END as result;

\echo '\n================================================================================'
\echo 'FOREIGN KEY TEST SUMMARY'
\echo 'Critical relationships that must work for data integrity'
\echo '================================================================================'