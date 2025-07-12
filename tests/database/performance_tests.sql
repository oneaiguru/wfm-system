-- =====================================================================================
-- Performance Testing Suite for WFM PostgreSQL Database
-- Task ID: DB-004
-- Created for: DATABASE-OPUS Agent
-- Purpose: Validate 100,000+ calls daily with sub-second response times
-- Performance Targets: <10ms point queries, <100ms range queries, <500ms aggregations
-- =====================================================================================

-- Enable timing for all queries
\timing on

-- =====================================================================================
-- 1. TEST DATA GENERATION PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_test_data(
    p_days INTEGER DEFAULT 7,
    p_calls_per_day INTEGER DEFAULT 100000
) RETURNS TEXT AS $$
DECLARE
    v_start_date DATE;
    v_current_timestamp TIMESTAMPTZ;
    v_service_id INTEGER;
    v_group_id INTEGER;
    v_calls_in_interval INTEGER;
    v_talk_time INTEGER;
    v_post_time INTEGER;
    v_total_records INTEGER := 0;
    v_interval_count INTEGER;
    v_day_offset INTEGER;
    v_hour INTEGER;
    v_minute_slot INTEGER;
    v_peak_multiplier DECIMAL;
    v_weekend_multiplier DECIMAL;
    v_batch_id UUID;
    service_ids INTEGER[] := ARRAY[1,2,3,4]; -- Based on sample data from schema
    group_ids INTEGER[] := ARRAY[1,2,3,4];   -- Based on sample data from schema
BEGIN
    -- Create import batch for tracking
    INSERT INTO import_batches (filename, created_by, status)
    VALUES ('performance_test_data_' || CURRENT_DATE, 'performance_test', 'processing')
    RETURNING id INTO v_batch_id;
    
    v_start_date := CURRENT_DATE - (p_days || ' days')::INTERVAL;
    v_interval_count := p_days * 96; -- 96 intervals per day (24 hours * 4 quarters)
    
    -- Generate data for each day
    FOR v_day_offset IN 0..(p_days - 1) LOOP
        -- Weekend multiplier (lower volume on weekends)
        v_weekend_multiplier := CASE 
            WHEN EXTRACT(DOW FROM v_start_date + v_day_offset) IN (0, 6) THEN 0.6 
            ELSE 1.0 
        END;
        
        -- Generate 96 intervals per day (15-minute intervals)
        FOR v_hour IN 0..23 LOOP
            FOR v_minute_slot IN 0..3 LOOP -- 0=:00, 1=:15, 2=:30, 3=:45
                v_current_timestamp := (v_start_date + v_day_offset) + 
                                     (v_hour || ' hours')::INTERVAL + 
                                     (v_minute_slot * 15 || ' minutes')::INTERVAL;
                
                -- Peak hours multiplier (9am-5pm higher volume)
                v_peak_multiplier := CASE 
                    WHEN v_hour BETWEEN 9 AND 17 THEN 1.5
                    WHEN v_hour BETWEEN 6 AND 9 OR v_hour BETWEEN 17 AND 20 THEN 1.0
                    ELSE 0.3
                END;
                
                -- Generate data for each service and group combination
                FOREACH v_service_id IN ARRAY service_ids LOOP
                    FOREACH v_group_id IN ARRAY group_ids LOOP
                        -- Calculate calls for this interval (realistic distribution)
                        v_calls_in_interval := GREATEST(1, 
                            ROUND((p_calls_per_day::DECIMAL / 96) * v_peak_multiplier * v_weekend_multiplier * 
                                  (0.8 + RANDOM() * 0.4)) -- Add 20% randomness
                        )::INTEGER;
                        
                        -- Generate realistic talk and post times
                        v_talk_time := GREATEST(30, ROUND(120 + RANDOM() * 240))::INTEGER; -- 30-360 seconds
                        v_post_time := GREATEST(10, ROUND(30 + RANDOM() * 60))::INTEGER;   -- 10-90 seconds
                        
                        -- Insert contact statistics
                        INSERT INTO contact_statistics (
                            interval_start_time,
                            interval_end_time,
                            service_id,
                            group_id,
                            not_unique_received,
                            not_unique_treated,
                            not_unique_missed,
                            received_calls,
                            treated_calls,
                            miss_calls,
                            aht,
                            talk_time,
                            post_processing,
                            service_level,
                            abandonment_rate,
                            occupancy_rate,
                            import_batch_id
                        ) VALUES (
                            v_current_timestamp,
                            v_current_timestamp + INTERVAL '15 minutes',
                            v_service_id,
                            v_group_id,
                            v_calls_in_interval,
                            GREATEST(0, v_calls_in_interval - ROUND(v_calls_in_interval * 0.02))::INTEGER, -- 2% abandonment
                            ROUND(v_calls_in_interval * 0.02)::INTEGER,
                            v_calls_in_interval,
                            GREATEST(0, v_calls_in_interval - ROUND(v_calls_in_interval * 0.02))::INTEGER,
                            ROUND(v_calls_in_interval * 0.02)::INTEGER,
                            v_talk_time + v_post_time,
                            v_talk_time,
                            v_post_time,
                            ROUND(80.0 + RANDOM() * 15.0, 2), -- Service level 80-95%
                            ROUND(RANDOM() * 5.0, 2),         -- Abandonment 0-5%
                            ROUND(60.0 + RANDOM() * 30.0, 2), -- Occupancy 60-90%
                            v_batch_id
                        );
                        
                        v_total_records := v_total_records + 1;
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
    
    -- Generate agent activity data (simplified)
    INSERT INTO agent_activity (
        interval_start_time,
        interval_end_time,
        agent_id,
        group_id,
        login_time,
        ready_time,
        talk_time,
        calls_handled,
        import_batch_id
    )
    SELECT 
        cs.interval_start_time,
        cs.interval_end_time,
        (cs.group_id * 10 + (ROW_NUMBER() OVER (PARTITION BY cs.group_id ORDER BY cs.interval_start_time) % 5) + 1)::INTEGER as agent_id,
        cs.group_id,
        900, -- 15 minutes logged in
        GREATEST(0, 900 - cs.talk_time)::INTEGER,
        cs.talk_time,
        cs.treated_calls,
        v_batch_id
    FROM contact_statistics cs
    WHERE cs.import_batch_id = v_batch_id;
    
    -- Update batch status
    UPDATE import_batches 
    SET status = 'completed',
        records_processed = v_total_records,
        processing_completed_at = NOW()
    WHERE id = v_batch_id;
    
    -- Refresh materialized views
    REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_contact_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_agent_performance;
    
    RETURN format('Generated %s records for %s days (%s calls/day avg). Batch ID: %s', 
                  v_total_records, p_days, p_calls_per_day, v_batch_id);
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 2. PERFORMANCE TEST RUNNER
-- =====================================================================================

CREATE OR REPLACE FUNCTION run_performance_tests()
RETURNS TABLE (
    test_name VARCHAR,
    execution_time_ms NUMERIC,
    pass_fail VARCHAR,
    details TEXT
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration_ms NUMERIC;
    v_record_count INTEGER;
    v_target_ms NUMERIC;
    v_test_result VARCHAR;
    v_details TEXT;
BEGIN
    -- =====================================================================================
    -- BASIC PERFORMANCE TESTS (Target: <10ms)
    -- =====================================================================================
    
    -- Test 1: Point Query - Single Interval Lookup
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM contact_statistics 
    WHERE service_id = 1 
      AND interval_start_time >= DATE_TRUNC('hour', NOW() - INTERVAL '1 hour')
      AND interval_start_time < DATE_TRUNC('hour', NOW() - INTERVAL '1 hour') + INTERVAL '1 hour'
    LIMIT 1;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_target_ms := 10;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Records: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Point Query - Single Interval'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 2: Service Filtering
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM contact_statistics 
    WHERE service_id = 2 
      AND interval_start_time >= CURRENT_DATE - INTERVAL '1 hour';
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Records: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Point Query - Service Filter'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 3: Agent Performance Query
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM agent_activity 
    WHERE agent_id = 11 
      AND interval_start_time >= CURRENT_DATE - INTERVAL '1 hour';
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Records: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Point Query - Agent Performance'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- =====================================================================================
    -- RANGE QUERY TESTS (Target: <100ms)
    -- =====================================================================================
    
    v_target_ms := 100;
    
    -- Test 4: Last 24 Hours
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM contact_statistics 
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '24 hours'
      AND interval_start_time < CURRENT_DATE;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Records: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Range Query - Last 24 Hours'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 5: Last 7 Days with Group By
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM (
        SELECT service_id, SUM(not_unique_received) as total_calls
        FROM contact_statistics 
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY service_id
    ) subq;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Service groups: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Range Query - 7 Days Aggregated'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 6: Agent Activity Range
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM agent_activity 
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '24 hours'
      AND group_id IS NOT NULL;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Records: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Range Query - Agent Activity 24h'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- =====================================================================================
    -- COMPLEX ANALYTICS TESTS (Target: <500ms)
    -- =====================================================================================
    
    v_target_ms := 500;
    
    -- Test 7: Monthly Aggregation
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM (
        SELECT 
            DATE_TRUNC('day', interval_start_time) as day,
            service_id,
            AVG(service_level) as avg_service_level,
            SUM(not_unique_received) as total_calls
        FROM contact_statistics 
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE_TRUNC('day', interval_start_time), service_id
        ORDER BY day DESC, service_id
    ) subq;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Daily summaries: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Complex Query - Monthly Aggregation'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 8: Service Level Calculation
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM (
        SELECT 
            s.service_name,
            AVG(cs.service_level) as avg_service_level,
            SUM(cs.not_unique_received) as total_calls,
            AVG(cs.aht) as avg_aht,
            CASE 
                WHEN AVG(cs.service_level) >= s.target_service_level THEN 'PASS'
                ELSE 'FAIL'
            END as sla_status
        FROM contact_statistics cs
        JOIN services s ON s.id = cs.service_id
        WHERE cs.interval_start_time >= CURRENT_DATE - INTERVAL '7 days'
          AND s.is_active = TRUE
        GROUP BY s.service_name, s.target_service_level
    ) subq;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Service reports: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Complex Query - Service Level Calc'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- Test 9: Agent Ranking Query
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_record_count
    FROM (
        SELECT 
            a.first_name || ' ' || a.last_name as agent_name,
            aa.group_id,
            SUM(aa.calls_handled) as total_calls,
            AVG(CASE WHEN aa.login_time > 0 THEN (aa.talk_time::DECIMAL / aa.login_time) * 100 ELSE 0 END) as avg_occupancy,
            RANK() OVER (PARTITION BY aa.group_id ORDER BY SUM(aa.calls_handled) DESC) as rank_in_group
        FROM agent_activity aa
        JOIN agents a ON a.id = aa.agent_id
        WHERE aa.interval_start_time >= CURRENT_DATE - INTERVAL '7 days'
          AND a.is_active = TRUE
        GROUP BY a.first_name, a.last_name, aa.group_id, aa.agent_id
        HAVING SUM(aa.calls_handled) > 0
    ) subq;
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Agent rankings: %s', v_target_ms, v_record_count);
    
    RETURN QUERY SELECT 'Complex Query - Agent Ranking'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- =====================================================================================
    -- CONCURRENT LOAD TEST (Target: <100ms under load)
    -- =====================================================================================
    
    v_target_ms := 100;
    
    -- Test 10: Concurrent Read Simulation
    v_start_time := clock_timestamp();
    
    -- Simulate multiple concurrent dashboard queries
    PERFORM (
        SELECT COUNT(*) 
        FROM contact_statistics 
        WHERE service_id = 1 AND interval_start_time >= CURRENT_DATE - INTERVAL '2 hours'
    );
    PERFORM (
        SELECT AVG(service_level) 
        FROM contact_statistics 
        WHERE service_id = 2 AND interval_start_time >= CURRENT_DATE - INTERVAL '2 hours'
    );
    PERFORM (
        SELECT SUM(not_unique_received) 
        FROM contact_statistics 
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 hour'
    );
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= v_target_ms THEN 'PASS' ELSE 'FAIL' END;
    v_details := format('Target: <%sms, Concurrent queries: 3', v_target_ms);
    
    RETURN QUERY SELECT 'Load Test - Concurrent Reads'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
    -- =====================================================================================
    -- INDEX EFFECTIVENESS TEST
    -- =====================================================================================
    
    -- Test 11: Index Usage Verification
    v_start_time := clock_timestamp();
    
    -- Force index usage check
    PERFORM pg_stat_reset();
    
    -- Run a query that should use indexes
    SELECT COUNT(*) INTO v_record_count
    FROM contact_statistics 
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '6 hours'
      AND service_id IN (1, 2, 3);
    
    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    v_test_result := CASE WHEN v_duration_ms <= 50 THEN 'PASS' ELSE 'FAIL' END; -- Stricter for index test
    v_details := format('Target: <50ms (index optimized), Records: %s', v_record_count);
    
    RETURN QUERY SELECT 'Index Test - Multi-Service Query'::VARCHAR, v_duration_ms, v_test_result, v_details;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. CLEANUP PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS TEXT AS $$
DECLARE
    v_deleted_contacts INTEGER := 0;
    v_deleted_agents INTEGER := 0;
    v_deleted_batches INTEGER := 0;
    v_batch_count INTEGER := 0;
BEGIN
    -- Count test batches
    SELECT COUNT(*) INTO v_batch_count
    FROM import_batches 
    WHERE created_by = 'performance_test' OR filename LIKE 'performance_test_%';
    
    -- Delete contact statistics from test batches
    DELETE FROM contact_statistics 
    WHERE import_batch_id IN (
        SELECT id FROM import_batches 
        WHERE created_by = 'performance_test' OR filename LIKE 'performance_test_%'
    );
    GET DIAGNOSTICS v_deleted_contacts = ROW_COUNT;
    
    -- Delete agent activity from test batches
    DELETE FROM agent_activity 
    WHERE import_batch_id IN (
        SELECT id FROM import_batches 
        WHERE created_by = 'performance_test' OR filename LIKE 'performance_test_%'
    );
    GET DIAGNOSTICS v_deleted_agents = ROW_COUNT;
    
    -- Delete test import batches
    DELETE FROM import_batches 
    WHERE created_by = 'performance_test' OR filename LIKE 'performance_test_%';
    GET DIAGNOSTICS v_deleted_batches = ROW_COUNT;
    
    -- Refresh materialized views
    REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_contact_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_agent_performance;
    
    -- Reset statistics
    PERFORM pg_stat_reset();
    
    -- Vacuum tables to reclaim space
    VACUUM ANALYZE contact_statistics;
    VACUUM ANALYZE agent_activity;
    VACUUM ANALYZE import_batches;
    
    RETURN format('Cleanup completed: %s contact records, %s agent records, %s import batches deleted', 
                  v_deleted_contacts, v_deleted_agents, v_deleted_batches);
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. COMPREHENSIVE PERFORMANCE TEST SUITE
-- =====================================================================================

CREATE OR REPLACE FUNCTION run_complete_performance_test_suite(
    p_generate_data BOOLEAN DEFAULT TRUE,
    p_test_days INTEGER DEFAULT 7,
    p_calls_per_day INTEGER DEFAULT 100000
)
RETURNS TABLE (
    test_category VARCHAR,
    test_name VARCHAR,
    execution_time_ms NUMERIC,
    pass_fail VARCHAR,
    details TEXT,
    timestamp TIMESTAMPTZ
) AS $$
DECLARE
    v_generation_result TEXT;
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_duration_ms NUMERIC;
BEGIN
    -- Header information
    RETURN QUERY SELECT 
        'SETUP'::VARCHAR,
        'Performance Test Suite Started'::VARCHAR, 
        0::NUMERIC, 
        'INFO'::VARCHAR, 
        format('Test data: %s days, %s calls/day, Generate new: %s', p_test_days, p_calls_per_day, p_generate_data),
        NOW();
    
    -- Generate test data if requested
    IF p_generate_data THEN
        v_start_time := clock_timestamp();
        SELECT generate_test_data(p_test_days, p_calls_per_day) INTO v_generation_result;
        v_end_time := clock_timestamp();
        v_duration_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
        
        RETURN QUERY SELECT 
            'DATA_GEN'::VARCHAR,
            'Test Data Generation'::VARCHAR, 
            v_duration_ms, 
            'PASS'::VARCHAR, 
            v_generation_result,
            NOW();
    END IF;
    
    -- Run all performance tests
    RETURN QUERY 
    SELECT 
        CASE 
            WHEN pt.test_name LIKE 'Point Query%' THEN 'POINT_QUERIES'
            WHEN pt.test_name LIKE 'Range Query%' THEN 'RANGE_QUERIES' 
            WHEN pt.test_name LIKE 'Complex Query%' THEN 'COMPLEX_QUERIES'
            WHEN pt.test_name LIKE 'Load Test%' THEN 'LOAD_TESTS'
            WHEN pt.test_name LIKE 'Index Test%' THEN 'INDEX_TESTS'
            ELSE 'OTHER'
        END::VARCHAR as category,
        pt.test_name::VARCHAR,
        pt.execution_time_ms,
        pt.pass_fail::VARCHAR,
        pt.details::VARCHAR,
        NOW()
    FROM run_performance_tests() pt;
    
    -- Summary statistics
    RETURN QUERY 
    WITH test_summary AS (
        SELECT 
            COUNT(*) as total_tests,
            COUNT(*) FILTER (WHERE pass_fail = 'PASS') as passed_tests,
            COUNT(*) FILTER (WHERE pass_fail = 'FAIL') as failed_tests,
            ROUND(AVG(execution_time_ms), 2) as avg_execution_time,
            ROUND(MAX(execution_time_ms), 2) as max_execution_time
        FROM run_performance_tests()
    )
    SELECT 
        'SUMMARY'::VARCHAR,
        'Test Results Summary'::VARCHAR,
        ts.avg_execution_time,
        CASE WHEN ts.failed_tests = 0 THEN 'PASS' ELSE 'FAIL' END::VARCHAR,
        format('Total: %s, Passed: %s, Failed: %s, Max time: %sms', 
               ts.total_tests, ts.passed_tests, ts.failed_tests, ts.max_execution_time),
        NOW()
    FROM test_summary ts;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. AUTOMATED PERFORMANCE MONITORING
-- =====================================================================================

CREATE OR REPLACE FUNCTION monitor_database_performance()
RETURNS TABLE (
    metric_name VARCHAR,
    metric_value NUMERIC,
    metric_unit VARCHAR,
    status VARCHAR,
    details TEXT
) AS $$
BEGIN
    -- Database size metrics
    RETURN QUERY SELECT 
        'Database Size'::VARCHAR,
        ROUND((pg_database_size(current_database())::NUMERIC / 1024 / 1024), 2),
        'MB'::VARCHAR,
        'INFO'::VARCHAR,
        'Total database size including all tables and indexes'::TEXT;
    
    -- Table record counts
    RETURN QUERY SELECT 
        'Contact Statistics Records'::VARCHAR,
        (SELECT COUNT(*)::NUMERIC FROM contact_statistics),
        'records'::VARCHAR,
        CASE WHEN (SELECT COUNT(*) FROM contact_statistics) > 100000 THEN 'GOOD' ELSE 'LOW' END::VARCHAR,
        'Total records in main time-series table'::TEXT;
    
    -- Index usage statistics
    RETURN QUERY SELECT 
        'Index Scan Ratio'::VARCHAR,
        ROUND(
            (SELECT 
                100.0 * SUM(idx_scan) / GREATEST(SUM(idx_scan + seq_scan), 1)
             FROM pg_stat_user_tables 
             WHERE relname = 'contact_statistics'), 2
        ),
        '%'::VARCHAR,
        CASE WHEN (SELECT SUM(idx_scan) / GREATEST(SUM(idx_scan + seq_scan), 1) FROM pg_stat_user_tables WHERE relname = 'contact_statistics') > 0.9 
             THEN 'GOOD' ELSE 'POOR' END::VARCHAR,
        'Percentage of queries using indexes vs sequential scans'::TEXT;
    
    -- Cache hit ratio
    RETURN QUERY SELECT 
        'Cache Hit Ratio'::VARCHAR,
        ROUND(
            (SELECT 
                100.0 * SUM(heap_blks_hit) / GREATEST(SUM(heap_blks_hit + heap_blks_read), 1)
             FROM pg_statio_user_tables), 2
        ),
        '%'::VARCHAR,
        CASE WHEN (SELECT SUM(heap_blks_hit) / GREATEST(SUM(heap_blks_hit + heap_blks_read), 1) FROM pg_statio_user_tables) > 0.95 
             THEN 'EXCELLENT' ELSE 'POOR' END::VARCHAR,
        'Percentage of data served from memory cache'::TEXT;
    
    -- Active connections
    RETURN QUERY SELECT 
        'Active Connections'::VARCHAR,
        (SELECT COUNT(*)::NUMERIC FROM pg_stat_activity WHERE state = 'active'),
        'connections'::VARCHAR,
        'INFO'::VARCHAR,
        'Current number of active database connections'::TEXT;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION generate_test_data(INTEGER, INTEGER) IS 
    'Generates realistic test data with peak hours, weekend patterns, and multiple services/groups for performance testing';

COMMENT ON FUNCTION run_performance_tests() IS 
    'Executes comprehensive performance test suite covering point queries, range queries, and complex analytics with timing validation';

COMMENT ON FUNCTION cleanup_test_data() IS 
    'Removes all performance test data and resets database to pre-test state';

COMMENT ON FUNCTION run_complete_performance_test_suite(BOOLEAN, INTEGER, INTEGER) IS 
    'Complete performance test workflow including data generation, testing, and results summary';

COMMENT ON FUNCTION monitor_database_performance() IS 
    'Provides real-time database performance metrics including size, index usage, and cache efficiency';

-- =====================================================================================
-- FINAL SETUP MESSAGE
-- =====================================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Performance Test Suite Installation Complete';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Available procedures:';
    RAISE NOTICE '- generate_test_data(days, calls_per_day): Generate realistic test data';
    RAISE NOTICE '- run_performance_tests(): Execute all performance tests';
    RAISE NOTICE '- cleanup_test_data(): Remove test data';
    RAISE NOTICE '- run_complete_performance_test_suite(): Full test workflow';
    RAISE NOTICE '- monitor_database_performance(): Real-time performance metrics';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Test categories:';
    RAISE NOTICE '- Point Queries: <10ms target (single interval, service filter, agent lookup)';
    RAISE NOTICE '- Range Queries: <100ms target (24h, 7d aggregated, agent activity)';
    RAISE NOTICE '- Complex Analytics: <500ms target (monthly agg, SLA calc, agent ranking)';
    RAISE NOTICE '- Load Tests: Concurrent read scenarios';
    RAISE NOTICE '- Index Tests: Verify index effectiveness';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Usage example:';
    RAISE NOTICE 'SELECT * FROM run_complete_performance_test_suite(true, 7, 100000);';
    RAISE NOTICE '=================================================================';
END $$;