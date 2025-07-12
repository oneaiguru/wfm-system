-- =====================================================================================
-- Performance Validation Queries for WFM Database
-- Task ID: DB-INT-003
-- Created for: DATABASE-OPUS Agent  
-- Purpose: Validate system meets 100K+ calls/day with sub-second response times
-- Target SLAs: <10ms point queries, <100ms range queries, <500ms aggregations
-- =====================================================================================

-- Enable query timing
\timing on

-- =====================================================================================
-- 1. RESPONSE TIME VALIDATION
-- =====================================================================================

-- Validate query performance against SLA targets
CREATE OR REPLACE FUNCTION validate_query_performance()
RETURNS TABLE(
    query_type TEXT,
    test_description TEXT,
    avg_ms NUMERIC,
    p95_ms NUMERIC,
    p99_ms NUMERIC,
    max_ms NUMERIC,
    sample_size INTEGER,
    meets_sla BOOLEAN,
    sla_target_ms INTEGER
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_durations NUMERIC[];
    v_duration_ms NUMERIC;
    i INTEGER;
BEGIN
    -- Test 1: Point query (target: <10ms)
    v_durations := ARRAY[]::NUMERIC[];
    FOR i IN 1..100 LOOP
        v_start_time := clock_timestamp();
        PERFORM * FROM contact_statistics 
        WHERE interval_start_time = CURRENT_DATE + (i || ' hours')::INTERVAL
          AND service_id = 1 
        LIMIT 1;
        v_end_time := clock_timestamp();
        v_duration_ms := EXTRACT(MILLISECOND FROM v_end_time - v_start_time);
        v_durations := array_append(v_durations, v_duration_ms);
    END LOOP;
    
    RETURN QUERY
    SELECT 
        'point_query'::TEXT,
        'Single interval lookup by time and service'::TEXT,
        ROUND(AVG(d), 2),
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d), 2),
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY d), 2),
        ROUND(MAX(d), 2),
        100,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d) < 10,
        10
    FROM unnest(v_durations) d;
    
    -- Test 2: Range query (target: <100ms)
    v_durations := ARRAY[]::NUMERIC[];
    FOR i IN 1..50 LOOP
        v_start_time := clock_timestamp();
        PERFORM * FROM contact_statistics 
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 day'
          AND interval_start_time < CURRENT_DATE
          AND service_id = (i % 10) + 1;
        v_end_time := clock_timestamp();
        v_duration_ms := EXTRACT(MILLISECOND FROM v_end_time - v_start_time);
        v_durations := array_append(v_durations, v_duration_ms);
    END LOOP;
    
    RETURN QUERY
    SELECT 
        'range_query'::TEXT,
        '24-hour range scan by service'::TEXT,
        ROUND(AVG(d), 2),
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d), 2),
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY d), 2),
        ROUND(MAX(d), 2),
        50,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d) < 100,
        100
    FROM unnest(v_durations) d;
    
    -- Test 3: Aggregation query (target: <500ms)
    v_durations := ARRAY[]::NUMERIC[];
    FOR i IN 1..20 LOOP
        v_start_time := clock_timestamp();
        PERFORM 
            service_id,
            SUM(received_calls),
            AVG(service_level),
            MAX(aht)
        FROM contact_statistics 
        WHERE interval_start_time >= CURRENT_DATE - (i || ' days')::INTERVAL
        GROUP BY service_id;
        v_end_time := clock_timestamp();
        v_duration_ms := EXTRACT(MILLISECOND FROM v_end_time - v_start_time);
        v_durations := array_append(v_durations, v_duration_ms);
    END LOOP;
    
    RETURN QUERY
    SELECT 
        'aggregation_query'::TEXT,
        'Multi-day aggregation by service'::TEXT,
        ROUND(AVG(d), 2),
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d), 2),
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY d), 2),
        ROUND(MAX(d), 2),
        20,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d) < 500,
        500
    FROM unnest(v_durations) d;
    
    -- Test 4: API integration query
    v_durations := ARRAY[]::NUMERIC[];
    FOR i IN 1..30 LOOP
        v_start_time := clock_timestamp();
        PERFORM * FROM api_get_calls_by_interval(
            CURRENT_DATE - INTERVAL '1 day',
            CURRENT_DATE,
            15,
            ARRAY[1, 2, 3],
            NULL
        );
        v_end_time := clock_timestamp();
        v_duration_ms := EXTRACT(MILLISECOND FROM v_end_time - v_start_time);
        v_durations := array_append(v_durations, v_duration_ms);
    END LOOP;
    
    RETURN QUERY
    SELECT 
        'api_integration'::TEXT,
        'API function with multi-service data'::TEXT,
        ROUND(AVG(d), 2),
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d), 2),
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY d), 2),
        ROUND(MAX(d), 2),
        30,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d) < 200,
        200
    FROM unnest(v_durations) d;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 2. THROUGHPUT VALIDATION
-- =====================================================================================

-- Validate system can handle 100K+ calls per day
CREATE OR REPLACE FUNCTION validate_throughput_capacity()
RETURNS TABLE(
    test_name TEXT,
    metric TEXT,
    value NUMERIC,
    unit TEXT,
    meets_requirement BOOLEAN,
    notes TEXT
) AS $$
DECLARE
    v_daily_capacity INTEGER;
    v_peak_hour_capacity INTEGER;
    v_batch_insert_rate NUMERIC;
    v_concurrent_queries INTEGER;
    v_start_time TIMESTAMPTZ;
    v_duration_ms NUMERIC;
BEGIN
    -- Test daily capacity based on current data
    SELECT COUNT(*) * 96 INTO v_daily_capacity -- 96 intervals per day
    FROM contact_statistics
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 hour'
      AND interval_start_time < CURRENT_DATE;
    
    RETURN QUERY
    SELECT 
        'daily_capacity'::TEXT,
        'Estimated daily record capacity'::TEXT,
        v_daily_capacity::NUMERIC,
        'records/day'::TEXT,
        v_daily_capacity > 100000,
        'Based on current hour extrapolation'::TEXT;
    
    -- Test peak hour handling
    SELECT MAX(hourly_calls) INTO v_peak_hour_capacity
    FROM (
        SELECT 
            date_trunc('hour', interval_start_time) as hour,
            SUM(received_calls) as hourly_calls
        FROM contact_statistics
        WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY hour
    ) hourly;
    
    RETURN QUERY
    SELECT 
        'peak_hour_capacity'::TEXT,
        'Maximum calls in one hour'::TEXT,
        COALESCE(v_peak_hour_capacity, 0)::NUMERIC,
        'calls/hour'::TEXT,
        COALESCE(v_peak_hour_capacity, 0) > 10000,
        'Should handle 10% of daily volume in peak hour'::TEXT;
    
    -- Test batch insert performance
    v_start_time := clock_timestamp();
    PERFORM api_batch_insert_calls(
        jsonb_build_array(
            jsonb_build_object(
                'interval_start_time', NOW(),
                'service_id', 1,
                'group_id', 1,
                'received_calls', 100,
                'treated_calls', 95,
                'miss_calls', 5,
                'aht_ms', 180000,
                'talk_time_ms', 150000,
                'post_time_ms', 30000
            )
        )
    );
    v_duration_ms := EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time);
    v_batch_insert_rate := 1000.0 / v_duration_ms; -- inserts per second
    
    RETURN QUERY
    SELECT 
        'batch_insert_rate'::TEXT,
        'Batch insert performance'::TEXT,
        ROUND(v_batch_insert_rate, 2),
        'inserts/second'::TEXT,
        v_batch_insert_rate > 100,
        'Should handle 100+ inserts/second'::TEXT;
    
    -- Test concurrent query handling
    SELECT COUNT(*) INTO v_concurrent_queries
    FROM pg_stat_activity
    WHERE state = 'active'
      AND query NOT LIKE '%pg_stat_activity%';
    
    RETURN QUERY
    SELECT 
        'concurrent_queries'::TEXT,
        'Current active queries'::TEXT,
        v_concurrent_queries::NUMERIC,
        'queries'::TEXT,
        v_concurrent_queries < 50,
        'System should handle 50+ concurrent queries'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. RESOURCE MONITORING
-- =====================================================================================

-- Monitor database resource utilization
CREATE OR REPLACE FUNCTION monitor_resource_usage()
RETURNS TABLE(
    resource_type TEXT,
    metric_name TEXT,
    current_value NUMERIC,
    threshold NUMERIC,
    status TEXT,
    recommendation TEXT
) AS $$
BEGIN
    -- Index usage statistics
    RETURN QUERY
    WITH index_stats AS (
        SELECT 
            schemaname,
            tablename,
            indexname,
            idx_scan,
            idx_tup_read,
            idx_tup_fetch
        FROM pg_stat_user_indexes
        WHERE schemaname = 'public'
    )
    SELECT 
        'index_usage'::TEXT,
        'Unused indexes count'::TEXT,
        COUNT(*)::NUMERIC,
        0::NUMERIC,
        CASE WHEN COUNT(*) > 0 THEN 'WARNING' ELSE 'OK' END,
        CASE WHEN COUNT(*) > 0 
            THEN 'Consider dropping unused indexes: ' || string_agg(indexname, ', ')
            ELSE 'All indexes are being used'
        END
    FROM index_stats
    WHERE idx_scan = 0
    GROUP BY 1;
    
    -- Cache hit ratio
    RETURN QUERY
    SELECT 
        'cache_performance'::TEXT,
        'Buffer cache hit ratio'::TEXT,
        ROUND(
            100.0 * SUM(heap_blks_hit) / 
            NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 
            2
        ),
        95::NUMERIC,
        CASE 
            WHEN 100.0 * SUM(heap_blks_hit) / 
                 NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) >= 95 
            THEN 'OK' 
            ELSE 'WARNING' 
        END,
        'Cache hit ratio should be > 95% for optimal performance'::TEXT
    FROM pg_statio_user_tables;
    
    -- Lock contention
    RETURN QUERY
    WITH lock_stats AS (
        SELECT 
            COUNT(*) as lock_count,
            MAX(EXTRACT(EPOCH FROM NOW() - query_start)) as max_wait_seconds
        FROM pg_stat_activity
        WHERE wait_event_type = 'Lock'
    )
    SELECT 
        'lock_contention'::TEXT,
        'Queries waiting on locks'::TEXT,
        lock_count::NUMERIC,
        5::NUMERIC,
        CASE WHEN lock_count > 5 THEN 'WARNING' ELSE 'OK' END,
        CASE 
            WHEN lock_count > 5 
            THEN 'High lock contention detected. Max wait: ' || max_wait_seconds || ' seconds'
            ELSE 'Lock contention within acceptable limits'
        END
    FROM lock_stats;
    
    -- Partition pruning effectiveness
    RETURN QUERY
    WITH partition_stats AS (
        SELECT 
            parent.relname as parent_table,
            COUNT(child.relname) as total_partitions,
            SUM(CASE WHEN pg_stat_user_tables.n_tup_ins > 0 THEN 1 ELSE 0 END) as active_partitions
        FROM pg_inherits
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        LEFT JOIN pg_stat_user_tables ON pg_stat_user_tables.relname = child.relname
        WHERE parent.relname = 'contact_statistics'
        GROUP BY parent.relname
    )
    SELECT 
        'partition_efficiency'::TEXT,
        'Active partition ratio'::TEXT,
        ROUND(100.0 * active_partitions / NULLIF(total_partitions, 0), 2),
        30::NUMERIC,
        CASE 
            WHEN 100.0 * active_partitions / NULLIF(total_partitions, 0) <= 30 
            THEN 'OK' 
            ELSE 'WARNING' 
        END,
        'Only ' || active_partitions || ' of ' || total_partitions || 
        ' partitions active. Good partition pruning.'::TEXT
    FROM partition_stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. INTEGRATION PERFORMANCE TESTING
-- =====================================================================================

-- Test cross-module integration performance
CREATE OR REPLACE FUNCTION test_integration_performance()
RETURNS TABLE(
    integration_point TEXT,
    operation TEXT,
    avg_latency_ms NUMERIC,
    throughput_per_sec NUMERIC,
    status TEXT
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_duration_ms NUMERIC;
    v_test_size INTEGER := 1000;
    v_batch_result RECORD;
BEGIN
    -- Test API query performance
    v_start_time := clock_timestamp();
    PERFORM * FROM api_get_calls_by_interval(
        CURRENT_DATE - INTERVAL '7 days',
        CURRENT_DATE,
        15,
        NULL,
        NULL
    );
    v_duration_ms := EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time);
    
    RETURN QUERY
    SELECT 
        'api_endpoint'::TEXT,
        'Weekly data retrieval'::TEXT,
        ROUND(v_duration_ms, 2),
        ROUND(1000.0 / v_duration_ms, 2),
        CASE WHEN v_duration_ms < 500 THEN 'PASS' ELSE 'FAIL' END;
    
    -- Test bulk upload performance
    v_start_time := clock_timestamp();
    SELECT * INTO v_batch_result FROM api_batch_insert_calls(
        (SELECT jsonb_agg(
            jsonb_build_object(
                'interval_start_time', CURRENT_TIMESTAMP - (s || ' minutes')::INTERVAL,
                'service_id', (s % 10) + 1,
                'group_id', (s % 5) + 1,
                'received_calls', 50 + (s % 50),
                'treated_calls', 45 + (s % 45),
                'miss_calls', 5 + (s % 5),
                'aht_ms', 180000 + (s * 1000),
                'talk_time_ms', 150000 + (s * 800),
                'post_time_ms', 30000 + (s * 200)
            )
        ) FROM generate_series(1, 100) s)
    );
    v_duration_ms := v_batch_result.duration_ms;
    
    RETURN QUERY
    SELECT 
        'bulk_upload'::TEXT,
        '100 record batch insert'::TEXT,
        ROUND(v_duration_ms / 100.0, 2),
        ROUND(100000.0 / v_duration_ms, 2),
        CASE WHEN v_duration_ms < 1000 THEN 'PASS' ELSE 'FAIL' END;
    
    -- Test real-time stats retrieval
    v_start_time := clock_timestamp();
    PERFORM * FROM api_get_realtime_stats(NULL, 60);
    v_duration_ms := EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time);
    
    RETURN QUERY
    SELECT 
        'realtime_stats'::TEXT,
        'Current hour statistics'::TEXT,
        ROUND(v_duration_ms, 2),
        ROUND(1000.0 / v_duration_ms, 2),
        CASE WHEN v_duration_ms < 50 THEN 'PASS' ELSE 'FAIL' END;
    
    -- Test materialized view performance
    v_start_time := clock_timestamp();
    PERFORM * FROM mv_hourly_stats 
    WHERE hour_start >= CURRENT_DATE - INTERVAL '1 day';
    v_duration_ms := EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time);
    
    RETURN QUERY
    SELECT 
        'materialized_view'::TEXT,
        'Hourly stats lookup'::TEXT,
        ROUND(v_duration_ms, 2),
        ROUND(1000.0 / v_duration_ms, 2),
        CASE WHEN v_duration_ms < 10 THEN 'PASS' ELSE 'FAIL' END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. HEALTH CHECK DASHBOARD
-- =====================================================================================

-- Comprehensive health check for monitoring
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(
    check_category TEXT,
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Performance SLA check
    RETURN QUERY
    WITH perf_check AS (
        SELECT * FROM validate_query_performance()
    )
    SELECT 
        'performance'::TEXT,
        query_type || '_sla'::TEXT,
        CASE WHEN meets_sla THEN 'HEALTHY' ELSE 'DEGRADED' END,
        'Avg: ' || avg_ms || 'ms, P95: ' || p95_ms || 'ms, Target: ' || sla_target_ms || 'ms'
    FROM perf_check;
    
    -- Throughput check
    RETURN QUERY
    WITH throughput AS (
        SELECT * FROM validate_throughput_capacity()
    )
    SELECT 
        'throughput'::TEXT,
        test_name,
        CASE WHEN meets_requirement THEN 'HEALTHY' ELSE 'WARNING' END,
        value || ' ' || unit || ' - ' || notes
    FROM throughput;
    
    -- Resource usage check
    RETURN QUERY
    WITH resources AS (
        SELECT * FROM monitor_resource_usage()
    )
    SELECT 
        'resources'::TEXT,
        metric_name,
        status,
        recommendation
    FROM resources;
    
    -- Data freshness check
    RETURN QUERY
    SELECT 
        'data_freshness'::TEXT,
        'Latest data age'::TEXT,
        CASE 
            WHEN MAX(interval_start_time) > NOW() - INTERVAL '1 hour' THEN 'HEALTHY'
            WHEN MAX(interval_start_time) > NOW() - INTERVAL '4 hours' THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        'Last data: ' || AGE(NOW(), MAX(interval_start_time))::TEXT || ' ago'
    FROM contact_statistics;
    
    -- Connection pool check
    RETURN QUERY
    WITH connection_stats AS (
        SELECT 
            COUNT(*) as total_connections,
            COUNT(*) FILTER (WHERE state = 'active') as active_connections,
            COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
        FROM pg_stat_activity
        WHERE backend_type = 'client backend'
    )
    SELECT 
        'connections'::TEXT,
        'Connection pool status'::TEXT,
        CASE 
            WHEN active_connections > 80 THEN 'WARNING'
            WHEN active_connections > 90 THEN 'CRITICAL'
            ELSE 'HEALTHY'
        END,
        'Active: ' || active_connections || ', Idle: ' || idle_connections || 
        ', Total: ' || total_connections
    FROM connection_stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. AUTOMATED VALIDATION RUNNER
-- =====================================================================================

-- Run all validation tests and return summary
CREATE OR REPLACE FUNCTION run_all_validations()
RETURNS TABLE(
    validation_suite TEXT,
    total_tests INTEGER,
    passed INTEGER,
    failed INTEGER,
    warnings INTEGER,
    overall_status TEXT
) AS $$
BEGIN
    -- Create temporary table for results
    CREATE TEMP TABLE IF NOT EXISTS validation_results (
        suite TEXT,
        test TEXT,
        status TEXT
    ) ON COMMIT DROP;
    
    -- Run performance validation
    INSERT INTO validation_results
    SELECT 'performance', query_type, 
           CASE WHEN meets_sla THEN 'PASS' ELSE 'FAIL' END
    FROM validate_query_performance();
    
    -- Run throughput validation
    INSERT INTO validation_results
    SELECT 'throughput', test_name,
           CASE WHEN meets_requirement THEN 'PASS' ELSE 'FAIL' END
    FROM validate_throughput_capacity();
    
    -- Run resource monitoring
    INSERT INTO validation_results
    SELECT 'resources', metric_name, status
    FROM monitor_resource_usage();
    
    -- Run integration tests
    INSERT INTO validation_results
    SELECT 'integration', integration_point, status
    FROM test_integration_performance();
    
    -- Summarize results
    RETURN QUERY
    SELECT 
        suite,
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE status IN ('PASS', 'OK', 'HEALTHY'))::INTEGER,
        COUNT(*) FILTER (WHERE status IN ('FAIL', 'CRITICAL', 'DEGRADED'))::INTEGER,
        COUNT(*) FILTER (WHERE status = 'WARNING')::INTEGER,
        CASE 
            WHEN COUNT(*) FILTER (WHERE status IN ('FAIL', 'CRITICAL')) > 0 THEN 'CRITICAL'
            WHEN COUNT(*) FILTER (WHERE status IN ('WARNING', 'DEGRADED')) > 0 THEN 'WARNING'
            ELSE 'HEALTHY'
        END
    FROM validation_results
    GROUP BY suite
    
    UNION ALL
    
    SELECT 
        'OVERALL',
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE status IN ('PASS', 'OK', 'HEALTHY'))::INTEGER,
        COUNT(*) FILTER (WHERE status IN ('FAIL', 'CRITICAL', 'DEGRADED'))::INTEGER,
        COUNT(*) FILTER (WHERE status = 'WARNING')::INTEGER,
        CASE 
            WHEN COUNT(*) FILTER (WHERE status IN ('FAIL', 'CRITICAL')) > 0 THEN 'CRITICAL'
            WHEN COUNT(*) FILTER (WHERE status IN ('WARNING', 'DEGRADED')) > 0 THEN 'WARNING'
            ELSE 'HEALTHY'
        END
    FROM validation_results;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. USAGE INSTRUCTIONS
-- =====================================================================================

-- Quick health check
-- SELECT * FROM database_health_check();

-- Full validation suite
-- SELECT * FROM run_all_validations();

-- Individual test suites
-- SELECT * FROM validate_query_performance();
-- SELECT * FROM validate_throughput_capacity();
-- SELECT * FROM monitor_resource_usage();
-- SELECT * FROM test_integration_performance();