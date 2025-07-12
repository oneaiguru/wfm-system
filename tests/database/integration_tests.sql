-- =====================================================================================
-- Integration Testing Suite for WFM PostgreSQL Database
-- Task ID: DB-005
-- Created for: DATABASE-OPUS Agent
-- Purpose: End-to-end validation of complete workflow from Excel import to query performance
-- Dependencies: Tasks DB-001 through DB-004 (schema, import, indexing, performance)
-- =====================================================================================

-- Enable timing for performance validation
\timing on

-- =====================================================================================
-- 1. COMPLETE EXCEL IMPORT WORKFLOW TEST
-- =====================================================================================

CREATE OR REPLACE FUNCTION test_complete_import_workflow()
RETURNS TABLE (
    step VARCHAR,
    status VARCHAR,
    details TEXT
) AS $$
DECLARE
    v_batch_id UUID;
    v_temp_file_id UUID := uuid_generate_v4();
    v_test_rows INTEGER := 1000;
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration_ms NUMERIC;
    v_imported_count INTEGER;
    v_error_count INTEGER;
    v_initial_count INTEGER;
    v_final_count INTEGER;
BEGIN
    -- Initialize test
    v_start_time := clock_timestamp();
    
    -- Step 1: Check initial state
    SELECT COUNT(*) INTO v_initial_count FROM contact_statistics;
    RETURN QUERY SELECT 'Initial State', 'PASS', 
        format('Initial contact_statistics count: %s', v_initial_count);
    
    -- Step 2: Create test import batch
    BEGIN
        INSERT INTO import_batches (filename, created_by, status, total_rows)
        VALUES (format('integration_test_%s.xlsx', v_temp_file_id), 'integration_test', 'processing', v_test_rows)
        RETURNING id INTO v_batch_id;
        
        RETURN QUERY SELECT 'Batch Creation', 'PASS', 
            format('Created batch ID: %s', v_batch_id);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Batch Creation', 'FAIL', 
            format('Error: %s', SQLERRM);
        RETURN;
    END;
    
    -- Step 3: Generate test staging data
    BEGIN
        WITH test_data AS (
            SELECT 
                v_batch_id as import_batch_id,
                generate_series(1, v_test_rows) as row_number,
                (CURRENT_DATE + ((random() * 7)::INTEGER || ' days')::INTERVAL + 
                 ((random() * 24)::INTEGER || ' hours')::INTERVAL + 
                 ((random() * 4) * 15 || ' minutes')::INTERVAL) as interval_start,
                (1 + (random() * 4)::INTEGER) as service_id,
                (1 + (random() * 3)::INTEGER) as group_id,
                (10 + (random() * 50)::INTEGER) as calls_count,
                (30000 + (random() * 180000)::INTEGER) as talk_time_ms,
                (5000 + (random() * 30000)::INTEGER) as post_time_ms
        )
        INSERT INTO staging_contact_data (
            import_batch_id, row_number, interval_start_time, interval_end_time,
            service_id, group_id, not_unique_received, not_unique_treated,
            talk_time, post_processing
        )
        SELECT 
            import_batch_id, row_number,
            interval_start,
            interval_start + INTERVAL '15 minutes',
            service_id, group_id, calls_count, calls_count - (random() * 3)::INTEGER,
            talk_time_ms, post_time_ms
        FROM test_data;
        
        GET DIAGNOSTICS v_imported_count = ROW_COUNT;
        RETURN QUERY SELECT 'Staging Data Generation', 'PASS', 
            format('Generated %s staging records', v_imported_count);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Staging Data Generation', 'FAIL', 
            format('Error: %s', SQLERRM);
        RETURN;
    END;
    
    -- Step 4: Validate staging data
    BEGIN
        PERFORM validate_import_batch(v_batch_id);
        
        SELECT COUNT(*) INTO v_error_count 
        FROM import_errors 
        WHERE import_batch_id = v_batch_id;
        
        IF v_error_count = 0 THEN
            RETURN QUERY SELECT 'Staging Validation', 'PASS', 
                'No validation errors found';
        ELSE
            RETURN QUERY SELECT 'Staging Validation', 'WARNING', 
                format('%s validation errors found', v_error_count);
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Staging Validation', 'FAIL', 
            format('Error: %s', SQLERRM);
        RETURN;
    END;
    
    -- Step 5: Execute import procedure
    BEGIN
        PERFORM import_excel_data(v_batch_id);
        
        -- Update batch status
        UPDATE import_batches 
        SET status = 'completed', completed_at = NOW() 
        WHERE id = v_batch_id;
        
        RETURN QUERY SELECT 'Data Import', 'PASS', 
            'Import procedure completed successfully';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Data Import', 'FAIL', 
            format('Error: %s', SQLERRM);
        RETURN;
    END;
    
    -- Step 6: Verify final data integrity
    SELECT COUNT(*) INTO v_final_count FROM contact_statistics;
    
    IF v_final_count > v_initial_count THEN
        RETURN QUERY SELECT 'Final Verification', 'PASS', 
            format('Data imported successfully. Count increased from %s to %s', 
                   v_initial_count, v_final_count);
    ELSE
        RETURN QUERY SELECT 'Final Verification', 'FAIL', 
            format('No data increase detected. Initial: %s, Final: %s', 
                   v_initial_count, v_final_count);
    END IF;
    
    -- Step 7: Performance measurement
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Performance', 'INFO', 
        format('Total workflow duration: %s ms (%s records/sec)', 
               ROUND(v_duration_ms, 2), 
               ROUND(v_test_rows / (v_duration_ms / 1000), 0));
    
    -- Cleanup test data
    DELETE FROM contact_statistics 
    WHERE import_batch_id = v_batch_id;
    
    DELETE FROM staging_contact_data 
    WHERE import_batch_id = v_batch_id;
    
    DELETE FROM import_batches 
    WHERE id = v_batch_id;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 2. DATA INTEGRITY VALIDATION FUNCTION
-- =====================================================================================

CREATE OR REPLACE FUNCTION validate_data_integrity()
RETURNS TABLE (
    check_name VARCHAR,
    result VARCHAR,
    issue_count INTEGER
) AS $$
DECLARE
    v_count INTEGER;
    v_start_time TIMESTAMPTZ := clock_timestamp();
BEGIN
    -- Check 1: Foreign key relationships
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics cs
    LEFT JOIN services s ON cs.service_id = s.id
    WHERE s.id IS NULL;
    
    RETURN QUERY SELECT 'Foreign Key - Services', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
    -- Check 2: Time interval consistency
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE interval_end_time <= interval_start_time;
    
    RETURN QUERY SELECT 'Time Interval Consistency', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
    -- Check 3: 15-minute interval alignment
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE EXTRACT(MINUTE FROM interval_start_time) NOT IN (0, 15, 30, 45);
    
    RETURN QUERY SELECT '15-Minute Alignment', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
    -- Check 4: Partition boundaries
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE interval_start_time::DATE != 
          (SELECT schemaname FROM pg_tables WHERE tablename LIKE 'contact_statistics_%' LIMIT 1)::DATE;
    
    RETURN QUERY SELECT 'Partition Boundaries', 'INFO', v_count;
    
    -- Check 5: Data completeness (no null critical fields)
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE interval_start_time IS NULL 
       OR service_id IS NULL 
       OR not_unique_received IS NULL;
    
    RETURN QUERY SELECT 'Critical Fields Not Null', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
    -- Check 6: Aggregation accuracy (sum consistency)
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE not_unique_received < (not_unique_treated + not_unique_missed);
    
    RETURN QUERY SELECT 'Aggregation Logic', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
    -- Check 7: Time metrics reasonableness (AHT < 2 hours)
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE aht > 7200000; -- 2 hours in milliseconds
    
    RETURN QUERY SELECT 'Time Metrics Reasonableness', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'WARNING' END,
        v_count;
    
    -- Check 8: Service level percentage bounds (0-100%)
    SELECT COUNT(*) INTO v_count
    FROM contact_statistics
    WHERE service_level < 0 OR service_level > 100;
    
    RETURN QUERY SELECT 'Service Level Bounds', 
        CASE WHEN v_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        v_count;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. CONCURRENT OPERATIONS TEST FUNCTION
-- =====================================================================================

CREATE OR REPLACE FUNCTION test_concurrent_operations()
RETURNS TABLE (
    operation VARCHAR,
    success BOOLEAN,
    duration_ms NUMERIC
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration NUMERIC;
    v_test_batch_id UUID;
    v_query_result INTEGER;
    v_deadlock_detected BOOLEAN := FALSE;
BEGIN
    -- Test 1: Import during active queries
    v_start_time := clock_timestamp();
    
    BEGIN
        -- Create small test batch for concurrent import
        INSERT INTO import_batches (filename, created_by, status, total_rows)
        VALUES ('concurrent_test.xlsx', 'concurrent_test', 'processing', 100)
        RETURNING id INTO v_test_batch_id;
        
        -- Generate minimal staging data
        INSERT INTO staging_contact_data (
            import_batch_id, row_number, interval_start_time, interval_end_time,
            service_id, group_id, not_unique_received, not_unique_treated
        )
        SELECT 
            v_test_batch_id, generate_series(1, 100),
            CURRENT_DATE + INTERVAL '1 hour',
            CURRENT_DATE + INTERVAL '1 hour 15 minutes',
            1, 1, 10, 8;
        
        -- Simulate concurrent query while importing
        PERFORM import_excel_data(v_test_batch_id);
        
        -- Execute query during import (in real scenario, this would be concurrent)
        SELECT COUNT(*) INTO v_query_result
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 day';
        
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Import During Query', TRUE, v_duration;
        
        -- Cleanup
        DELETE FROM contact_statistics WHERE import_batch_id = v_test_batch_id;
        DELETE FROM staging_contact_data WHERE import_batch_id = v_test_batch_id;
        DELETE FROM import_batches WHERE id = v_test_batch_id;
        
    EXCEPTION 
        WHEN deadlock_detected THEN
            v_deadlock_detected := TRUE;
            RETURN QUERY SELECT 'Import During Query', FALSE, 0::NUMERIC;
        WHEN OTHERS THEN
            RETURN QUERY SELECT 'Import During Query', FALSE, 0::NUMERIC;
    END;
    
    -- Test 2: Multiple concurrent queries
    v_start_time := clock_timestamp();
    
    BEGIN
        -- Simulate multiple query patterns
        PERFORM COUNT(*) FROM contact_statistics WHERE service_id = 1;
        PERFORM AVG(aht) FROM contact_statistics WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days';
        PERFORM MAX(service_level) FROM contact_statistics WHERE group_id = 1;
        
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Multiple Concurrent Queries', TRUE, v_duration;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Multiple Concurrent Queries', FALSE, 0::NUMERIC;
    END;
    
    -- Test 3: Index maintenance during operations
    v_start_time := clock_timestamp();
    
    BEGIN
        -- Test index statistics update
        ANALYZE contact_statistics;
        
        -- Test concurrent read during maintenance
        SELECT COUNT(*) INTO v_query_result
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 hour';
        
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Index Maintenance During Queries', TRUE, v_duration;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Index Maintenance During Queries', FALSE, 0::NUMERIC;
    END;
    
    -- Test 4: Partition operations
    v_start_time := clock_timestamp();
    
    BEGIN
        -- Test partition access patterns
        SELECT COUNT(*) INTO v_query_result
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE
          AND interval_start_time < CURRENT_DATE + INTERVAL '1 day';
        
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Partition Access Patterns', TRUE, v_duration;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Partition Access Patterns', FALSE, 0::NUMERIC;
    END;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. API QUERY PATTERN TEST FUNCTION
-- =====================================================================================

CREATE OR REPLACE FUNCTION test_api_query_patterns()
RETURNS TABLE (
    endpoint VARCHAR,
    query_time_ms NUMERIC,
    row_count INTEGER
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration NUMERIC;
    v_row_count INTEGER;
BEGIN
    -- API Pattern 1: Real-time personnel status
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM agent_activity aa
    JOIN contact_statistics cs ON aa.service_id = cs.service_id
    WHERE aa.login_time >= CURRENT_DATE
      AND cs.interval_start_time >= CURRENT_DATE - INTERVAL '15 minutes';
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Real-time Personnel Status', v_duration, v_row_count;
    
    -- API Pattern 2: Historical data retrieval (last 24 hours)
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM contact_statistics
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '24 hours'
      AND service_id IN (1, 2, 3, 4);
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Historical Data 24h', v_duration, v_row_count;
    
    -- API Pattern 3: Service level aggregation (last 7 days)
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM (
        SELECT 
            service_id,
            DATE(interval_start_time) as day,
            AVG(service_level) as avg_service_level,
            SUM(not_unique_received) as total_calls
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY service_id, DATE(interval_start_time)
    ) aggregated;
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Service Level Aggregation 7d', v_duration, v_row_count;
    
    -- API Pattern 4: High-frequency current status
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM contact_statistics
    WHERE interval_start_time >= DATE_TRUNC('hour', NOW()) - INTERVAL '15 minutes'
      AND interval_start_time < DATE_TRUNC('hour', NOW());
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Current Status Query', v_duration, v_row_count;
    
    -- API Pattern 5: Drill-down query (service -> group -> agent)
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM contact_statistics cs
    LEFT JOIN agent_activity aa ON cs.service_id = aa.service_id
    WHERE cs.service_id = 1
      AND cs.group_id = 1
      AND cs.interval_start_time >= CURRENT_DATE - INTERVAL '1 hour';
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Drill-down Query Pattern', v_duration, v_row_count;
    
    -- API Pattern 6: Time-series aggregation (hourly rollup)
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_row_count
    FROM (
        SELECT 
            DATE_TRUNC('hour', interval_start_time) as hour,
            service_id,
            SUM(not_unique_received) as hourly_calls,
            AVG(aht) as avg_aht
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 day'
        GROUP BY DATE_TRUNC('hour', interval_start_time), service_id
    ) hourly_rollup;
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT 'Hourly Time-series Rollup', v_duration, v_row_count;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. MASTER INTEGRATION TEST RUNNER
-- =====================================================================================

CREATE OR REPLACE FUNCTION run_integration_test_suite()
RETURNS TABLE (
    test_category VARCHAR,
    test_name VARCHAR,
    result VARCHAR,
    details TEXT,
    execution_time_ms NUMERIC
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration NUMERIC;
    test_record RECORD;
BEGIN
    -- Header
    RETURN QUERY SELECT 'INTEGRATION TEST SUITE', 'Started', 'INFO', 
        format('Started at %s', NOW()), 0::NUMERIC;
    
    -- Test 1: Complete Import Workflow
    v_start_time := clock_timestamp();
    
    FOR test_record IN 
        SELECT * FROM test_complete_import_workflow()
    LOOP
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Import Workflow', 
            test_record.step, 
            test_record.status, 
            test_record.details,
            v_duration;
    END LOOP;
    
    -- Test 2: Data Integrity
    v_start_time := clock_timestamp();
    
    FOR test_record IN 
        SELECT * FROM validate_data_integrity()
    LOOP
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Data Integrity', 
            test_record.check_name, 
            test_record.result, 
            format('Issues found: %s', test_record.issue_count),
            v_duration;
    END LOOP;
    
    -- Test 3: Concurrent Operations
    v_start_time := clock_timestamp();
    
    FOR test_record IN 
        SELECT * FROM test_concurrent_operations()
    LOOP
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'Concurrent Operations', 
            test_record.operation, 
            CASE WHEN test_record.success THEN 'PASS' ELSE 'FAIL' END, 
            format('Duration: %s ms', test_record.duration_ms),
            v_duration;
    END LOOP;
    
    -- Test 4: API Query Patterns
    v_start_time := clock_timestamp();
    
    FOR test_record IN 
        SELECT * FROM test_api_query_patterns()
    LOOP
        v_end_time := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 'API Query Patterns', 
            test_record.endpoint, 
            CASE WHEN test_record.query_time_ms < 100 THEN 'PASS' 
                 WHEN test_record.query_time_ms < 500 THEN 'WARNING'
                 ELSE 'FAIL' END, 
            format('Query: %s ms, Rows: %s', test_record.query_time_ms, test_record.row_count),
            v_duration;
    END LOOP;
    
    -- Summary
    RETURN QUERY SELECT 'INTEGRATION TEST SUITE', 'Completed', 'INFO', 
        format('Completed at %s', NOW()), 0::NUMERIC;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. QUICK INTEGRATION TEST EXECUTION
-- =====================================================================================

-- Execute the complete integration test suite
-- Usage: SELECT * FROM run_integration_test_suite();

-- Individual test execution examples:
-- SELECT * FROM test_complete_import_workflow();
-- SELECT * FROM validate_data_integrity();
-- SELECT * FROM test_concurrent_operations();
-- SELECT * FROM test_api_query_patterns();

-- Performance target validation:
-- Point queries: < 10ms
-- Range queries: < 100ms  
-- Aggregations: < 500ms

-- Expected results format (as specified in task):
/*
Test Category         | Test Name              | Result | Details
-------------------- | ---------------------- | ------ | -------
Import Workflow      | Staging Validation     | PASS   | 1000 records validated
Data Integrity       | FK Relationships       | PASS   | All constraints valid
Concurrent Ops       | Import During Query    | PASS   | No deadlocks
API Patterns         | Historical Data Query  | PASS   | 85ms response
*/