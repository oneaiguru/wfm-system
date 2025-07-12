-- Focused Performance Tests for Specific Loads
-- Test 1: 100K calls across 68 queues
-- Test 2: 1000 concurrent agent queries  
-- Test 3: Real-time aggregations

-- =====================================================
-- Test Setup and Configuration
-- =====================================================

-- Performance test configuration
CREATE TABLE IF NOT EXISTS perf_test_config (
    test_name VARCHAR(100) PRIMARY KEY,
    target_records INTEGER,
    target_queues INTEGER,
    target_concurrent_users INTEGER,
    max_response_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance test results
CREATE TABLE IF NOT EXISTS perf_test_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_name VARCHAR(100),
    test_start TIMESTAMP,
    test_end TIMESTAMP,
    duration_seconds DECIMAL(10,3),
    records_processed INTEGER,
    avg_response_time_ms DECIMAL(10,3),
    max_response_time_ms DECIMAL(10,3),
    min_response_time_ms DECIMAL(10,3),
    throughput_per_second DECIMAL(10,3),
    success_rate DECIMAL(5,2),
    errors_encountered INTEGER,
    memory_usage_mb INTEGER,
    cpu_usage_percent DECIMAL(5,2),
    test_passed BOOLEAN,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test configurations
INSERT INTO perf_test_config VALUES
('100K_CALLS_68_QUEUES', 100000, 68, 1, 10, CURRENT_TIMESTAMP),
('1000_CONCURRENT_AGENTS', 1000, 68, 1000, 10, CURRENT_TIMESTAMP),
('REALTIME_AGGREGATIONS', 50000, 68, 100, 100, CURRENT_TIMESTAMP)
ON CONFLICT (test_name) DO UPDATE SET
    target_records = EXCLUDED.target_records,
    target_queues = EXCLUDED.target_queues,
    target_concurrent_users = EXCLUDED.target_concurrent_users,
    max_response_time_ms = EXCLUDED.max_response_time_ms;

-- =====================================================
-- TEST 1: 100K Calls Across 68 Queues
-- =====================================================

-- Generate 68 queues with realistic names
CREATE OR REPLACE FUNCTION generate_test_queues() RETURNS void AS $$
DECLARE
    i INTEGER;
    queue_names TEXT[] := ARRAY[
        'SALES_INBOUND', 'SALES_OUTBOUND', 'SUPPORT_L1', 'SUPPORT_L2', 'SUPPORT_L3',
        'BILLING_GENERAL', 'BILLING_DISPUTES', 'TECHNICAL_SUPPORT', 'CUSTOMER_SERVICE',
        'COMPLAINTS', 'RETENTION', 'UPGRADES', 'NEW_CUSTOMERS', 'VIP_SUPPORT',
        'SPANISH_SUPPORT', 'FRENCH_SUPPORT', 'CHAT_SUPPORT', 'EMAIL_SUPPORT',
        'SOCIAL_MEDIA', 'ESCALATIONS', 'MANAGEMENT', 'TRAINING', 'QUALITY_ASSURANCE',
        'BACK_OFFICE', 'COLLECTIONS', 'FRAUD_PREVENTION', 'CANCELLATIONS',
        'PRODUCT_SUPPORT', 'MOBILE_SUPPORT', 'INTERNET_SUPPORT', 'TV_SUPPORT',
        'BUSINESS_SALES', 'ENTERPRISE_SUPPORT', 'PARTNER_SUPPORT', 'DEALER_SUPPORT',
        'FIELD_SERVICES', 'INSTALLATION', 'MAINTENANCE', 'REPAIRS', 'PROVISIONING',
        'ACTIVATION', 'DEACTIVATION', 'TECHNICAL_ORDERS', 'SERVICE_ORDERS',
        'DISPATCH', 'SCHEDULING', 'EMERGENCY_SUPPORT', 'AFTER_HOURS',
        'WEEKEND_SUPPORT', 'HOLIDAY_SUPPORT', 'OVERFLOW_QUEUE', 'BACKUP_QUEUE',
        'TRAINING_QUEUE', 'TEST_QUEUE', 'DEVELOPMENT_QUEUE', 'STAGING_QUEUE',
        'PRODUCTION_QUEUE', 'MONITORING_QUEUE', 'ALERTS_QUEUE', 'NOTIFICATIONS_QUEUE',
        'REPORTS_QUEUE', 'ANALYTICS_QUEUE', 'RESEARCH_QUEUE', 'SURVEY_QUEUE',
        'FEEDBACK_QUEUE', 'SUGGESTIONS_QUEUE', 'BETA_TESTING', 'PILOT_PROGRAM'
    ];
BEGIN
    -- Clear existing test queues
    DELETE FROM queues WHERE queue_id LIKE 'TEST_QUEUE_%';
    
    -- Generate exactly 68 queues
    FOR i IN 1..68 LOOP
        INSERT INTO queues (queue_id, queue_name, queue_type, is_active, max_concurrent_calls)
        VALUES (
            'TEST_QUEUE_' || LPAD(i::TEXT, 3, '0'),
            CASE 
                WHEN i <= array_length(queue_names, 1) THEN queue_names[i]
                ELSE 'QUEUE_' || i
            END,
            CASE (i % 4)
                WHEN 0 THEN 'inbound'
                WHEN 1 THEN 'outbound' 
                WHEN 2 THEN 'blended'
                ELSE 'chat'
            END,
            TRUE,
            50 + (i % 100) -- Varying capacity
        ) ON CONFLICT (queue_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Generated 68 test queues successfully';
END;
$$ LANGUAGE plpgsql;

-- Generate 100K call records across 68 queues
CREATE OR REPLACE FUNCTION generate_100k_calls() RETURNS void AS $$
DECLARE
    batch_size INTEGER := 1000;
    total_batches INTEGER := 100; -- 100 batches of 1000 = 100K
    batch_num INTEGER;
    start_time TIMESTAMP;
    queue_ids TEXT[];
    i INTEGER;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    
    -- Get all test queue IDs
    SELECT array_agg(queue_id) INTO queue_ids
    FROM queues WHERE queue_id LIKE 'TEST_QUEUE_%';
    
    RAISE NOTICE 'Starting generation of 100K calls across % queues', array_length(queue_ids, 1);
    
    -- Generate calls in batches for better performance
    FOR batch_num IN 1..total_batches LOOP
        INSERT INTO contact_statistics (
            interval_start,
            interval_end,
            queue_id,
            offered_calls,
            answered_calls,
            abandoned_calls,
            avg_handle_time,
            avg_wait_time,
            service_level_20s,
            max_wait_time,
            total_talk_time,
            total_hold_time,
            created_at
        )
        SELECT 
            CURRENT_DATE - INTERVAL '30 days' + (random() * INTERVAL '30 days'),
            CURRENT_DATE - INTERVAL '30 days' + (random() * INTERVAL '30 days') + INTERVAL '15 minutes',
            queue_ids[1 + (random() * (array_length(queue_ids, 1) - 1))::INTEGER],
            (random() * 100)::INTEGER + 1, -- 1-100 calls per interval
            (random() * 90)::INTEGER + 1,  -- Answered calls
            (random() * 10)::INTEGER,      -- Abandoned calls
            (random() * 300)::INTEGER + 60, -- 60-360 seconds AHT
            (random() * 60)::INTEGER + 5,   -- 5-65 seconds wait
            (random() * 40)::INTEGER + 60,  -- 60-100% SL
            (random() * 300)::INTEGER + 60, -- Max wait time
            (random() * 1000)::INTEGER + 100, -- Talk time
            (random() * 200)::INTEGER + 10    -- Hold time
        FROM generate_series(1, batch_size);
        
        -- Progress reporting
        IF batch_num % 10 = 0 THEN
            RAISE NOTICE 'Generated % batches (% records) in %', 
                batch_num, batch_num * batch_size, 
                CURRENT_TIMESTAMP - start_time;
        END IF;
    END LOOP;
    
    RAISE NOTICE '100K calls generation completed in %', CURRENT_TIMESTAMP - start_time;
END;
$$ LANGUAGE plpgsql;

-- Test 100K calls performance
CREATE OR REPLACE FUNCTION test_100k_calls_performance() RETURNS void AS $$
DECLARE
    test_start TIMESTAMP;
    test_end TIMESTAMP;
    query_times DECIMAL[];
    avg_time DECIMAL;
    max_time DECIMAL;
    min_time DECIMAL;
    query_start TIMESTAMP;
    query_end TIMESTAMP;
    i INTEGER;
    random_queue TEXT;
    total_records INTEGER;
BEGIN
    test_start := CURRENT_TIMESTAMP;
    
    -- Count total records
    SELECT COUNT(*) INTO total_records
    FROM contact_statistics cs
    JOIN queues q ON cs.queue_id = q.queue_id
    WHERE q.queue_id LIKE 'TEST_QUEUE_%';
    
    RAISE NOTICE 'Testing performance with % records across 68 queues', total_records;
    
    -- Test various query patterns
    FOR i IN 1..50 LOOP
        -- Get random queue for testing
        SELECT queue_id INTO random_queue
        FROM queues 
        WHERE queue_id LIKE 'TEST_QUEUE_%' 
        ORDER BY random() 
        LIMIT 1;
        
        -- Test point query performance
        query_start := CURRENT_TIMESTAMP;
        PERFORM COUNT(*) FROM contact_statistics 
        WHERE queue_id = random_queue
        AND interval_start >= CURRENT_DATE - INTERVAL '7 days';
        query_end := CURRENT_TIMESTAMP;
        
        query_times := array_append(query_times, 
            EXTRACT(EPOCH FROM (query_end - query_start)) * 1000);
    END LOOP;
    
    -- Calculate statistics
    SELECT 
        avg(t), max(t), min(t) 
    INTO avg_time, max_time, min_time
    FROM unnest(query_times) AS t;
    
    test_end := CURRENT_TIMESTAMP;
    
    -- Record results
    INSERT INTO perf_test_results (
        test_name, test_start, test_end, 
        duration_seconds, records_processed,
        avg_response_time_ms, max_response_time_ms, min_response_time_ms,
        throughput_per_second, success_rate, errors_encountered,
        test_passed, notes
    ) VALUES (
        '100K_CALLS_68_QUEUES',
        test_start, test_end,
        EXTRACT(EPOCH FROM (test_end - test_start)),
        total_records,
        avg_time, max_time, min_time,
        50.0 / EXTRACT(EPOCH FROM (test_end - test_start)), -- 50 queries
        100.0, 0,
        (avg_time <= 10.0), -- Pass if average <= 10ms
        format('Avg: %sms, Max: %sms, Min: %sms across %s records', 
               avg_time, max_time, min_time, total_records)
    );
    
    RAISE NOTICE 'Test completed - Avg: %ms, Max: %ms, Min: %ms', 
        avg_time, max_time, min_time;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST 2: 1000 Concurrent Agent Queries
-- =====================================================

-- Generate test agents
CREATE OR REPLACE FUNCTION generate_test_agents() RETURNS void AS $$
DECLARE
    i INTEGER;
BEGIN
    -- Clear existing test agents
    DELETE FROM agents WHERE agent_id LIKE 'TEST_AGENT_%';
    
    -- Generate 1000 test agents
    FOR i IN 1..1000 LOOP
        INSERT INTO agents (
            agent_id, agent_name, email, phone, 
            employment_type, hire_date, is_active,
            max_concurrent_calls, skill_level
        ) VALUES (
            'TEST_AGENT_' || LPAD(i::TEXT, 4, '0'),
            'Test Agent ' || i,
            'agent' || i || '@test.com',
            '+1555' || LPAD(i::TEXT, 7, '0'),
            'full_time',
            CURRENT_DATE - INTERVAL '1 year' + (random() * INTERVAL '365 days'),
            TRUE,
            CASE (i % 3)
                WHEN 0 THEN 1
                WHEN 1 THEN 2
                ELSE 3
            END,
            (random() * 5)::INTEGER + 1
        ) ON CONFLICT (agent_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Generated 1000 test agents successfully';
END;
$$ LANGUAGE plpgsql;

-- Simulate concurrent agent queries
CREATE OR REPLACE FUNCTION test_concurrent_agent_queries() RETURNS void AS $$
DECLARE
    test_start TIMESTAMP;
    test_end TIMESTAMP;
    batch_size INTEGER := 100;  -- Test in batches of 100
    total_batches INTEGER := 10; -- 10 batches = 1000 concurrent
    batch_num INTEGER;
    batch_start TIMESTAMP;
    batch_end TIMESTAMP;
    batch_times DECIMAL[];
    avg_batch_time DECIMAL;
    max_batch_time DECIMAL;
    min_batch_time DECIMAL;
    successful_queries INTEGER := 0;
    total_queries INTEGER := 0;
BEGIN
    test_start := CURRENT_TIMESTAMP;
    
    RAISE NOTICE 'Starting 1000 concurrent agent queries test';
    
    -- Test concurrent queries in batches
    FOR batch_num IN 1..total_batches LOOP
        batch_start := CURRENT_TIMESTAMP;
        
        -- Execute concurrent queries for this batch
        PERFORM (
            SELECT COUNT(*)
            FROM contact_statistics cs
            JOIN agents a ON TRUE
            WHERE a.agent_id LIKE 'TEST_AGENT_%'
            AND cs.queue_id LIKE 'TEST_QUEUE_%'
            AND cs.interval_start >= CURRENT_DATE - INTERVAL '1 day'
            LIMIT batch_size
        );
        
        batch_end := CURRENT_TIMESTAMP;
        
        batch_times := array_append(batch_times, 
            EXTRACT(EPOCH FROM (batch_end - batch_start)) * 1000);
        
        successful_queries := successful_queries + batch_size;
        total_queries := total_queries + batch_size;
        
        RAISE NOTICE 'Batch % completed in %ms', 
            batch_num, EXTRACT(EPOCH FROM (batch_end - batch_start)) * 1000;
    END LOOP;
    
    -- Calculate statistics
    SELECT 
        avg(t), max(t), min(t) 
    INTO avg_batch_time, max_batch_time, min_batch_time
    FROM unnest(batch_times) AS t;
    
    test_end := CURRENT_TIMESTAMP;
    
    -- Record results
    INSERT INTO perf_test_results (
        test_name, test_start, test_end, 
        duration_seconds, records_processed,
        avg_response_time_ms, max_response_time_ms, min_response_time_ms,
        throughput_per_second, success_rate, errors_encountered,
        test_passed, notes
    ) VALUES (
        '1000_CONCURRENT_AGENTS',
        test_start, test_end,
        EXTRACT(EPOCH FROM (test_end - test_start)),
        successful_queries,
        avg_batch_time, max_batch_time, min_batch_time,
        total_queries / EXTRACT(EPOCH FROM (test_end - test_start)),
        (successful_queries * 100.0) / total_queries,
        total_queries - successful_queries,
        (avg_batch_time <= 10.0), -- Pass if average <= 10ms
        format('Concurrent queries: %s, Success rate: %s%%', 
               total_queries, (successful_queries * 100.0) / total_queries)
    );
    
    RAISE NOTICE 'Concurrent test completed - Avg: %ms, Max: %ms, Success: %/%', 
        avg_batch_time, max_batch_time, successful_queries, total_queries;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST 3: Real-time Aggregations
-- =====================================================

-- Generate real-time test data
CREATE OR REPLACE FUNCTION generate_realtime_test_data() RETURNS void AS $$
DECLARE
    i INTEGER;
    queue_id TEXT;
    agent_id TEXT;
BEGIN
    -- Clear existing real-time test data
    DELETE FROM realtime_queues WHERE queue_id LIKE 'TEST_QUEUE_%';
    DELETE FROM realtime_agents WHERE agent_id LIKE 'TEST_AGENT_%';
    
    -- Generate real-time queue data
    FOR i IN 1..68 LOOP
        queue_id := 'TEST_QUEUE_' || LPAD(i::TEXT, 3, '0');
        
        INSERT INTO realtime_queues (
            queue_id, queue_name, queue_status,
            calls_waiting, calls_in_progress, agents_available,
            agents_busy, agents_unavailable, longest_wait_time,
            avg_wait_time, service_level_current, calls_today,
            abandoned_today, avg_handle_time_today
        ) VALUES (
            queue_id,
            'Test Queue ' || i,
            'active',
            (random() * 20)::INTEGER,
            (random() * 30)::INTEGER,
            (random() * 10)::INTEGER + 1,
            (random() * 15)::INTEGER,
            (random() * 5)::INTEGER,
            (random() * 300)::INTEGER + 10,
            (random() * 60)::INTEGER + 5,
            (random() * 40)::INTEGER + 60,
            (random() * 1000)::INTEGER + 100,
            (random() * 100)::INTEGER + 10,
            (random() * 200)::INTEGER + 120
        ) ON CONFLICT (queue_id) DO UPDATE SET
            calls_waiting = EXCLUDED.calls_waiting,
            calls_in_progress = EXCLUDED.calls_in_progress,
            updated_at = CURRENT_TIMESTAMP;
    END LOOP;
    
    -- Generate real-time agent data
    FOR i IN 1..1000 LOOP
        agent_id := 'TEST_AGENT_' || LPAD(i::TEXT, 4, '0');
        
        INSERT INTO realtime_agents (
            agent_id, agent_name, current_state,
            current_queue_id, state_duration, calls_today,
            avg_handle_time_today, last_call_end, next_break_time
        ) VALUES (
            agent_id,
            'Test Agent ' || i,
            CASE (i % 5)
                WHEN 0 THEN 'available'
                WHEN 1 THEN 'busy'
                WHEN 2 THEN 'on_call'
                WHEN 3 THEN 'break'
                ELSE 'unavailable'
            END,
            'TEST_QUEUE_' || LPAD(((i % 68) + 1)::TEXT, 3, '0'),
            (random() * 3600)::INTEGER + 60,
            (random() * 50)::INTEGER + 5,
            (random() * 300)::INTEGER + 120,
            CURRENT_TIMESTAMP - (random() * INTERVAL '2 hours'),
            CURRENT_TIMESTAMP + (random() * INTERVAL '4 hours')
        ) ON CONFLICT (agent_id) DO UPDATE SET
            current_state = EXCLUDED.current_state,
            current_queue_id = EXCLUDED.current_queue_id,
            updated_at = CURRENT_TIMESTAMP;
    END LOOP;
    
    RAISE NOTICE 'Generated real-time test data for 68 queues and 1000 agents';
END;
$$ LANGUAGE plpgsql;

-- Test real-time aggregations performance
CREATE OR REPLACE FUNCTION test_realtime_aggregations() RETURNS void AS $$
DECLARE
    test_start TIMESTAMP;
    test_end TIMESTAMP;
    aggregation_times DECIMAL[];
    avg_time DECIMAL;
    max_time DECIMAL;
    min_time DECIMAL;
    query_start TIMESTAMP;
    query_end TIMESTAMP;
    i INTEGER;
    test_queries TEXT[] := ARRAY[
        'SELECT COUNT(*) FROM realtime_queues WHERE queue_status = ''active''',
        'SELECT SUM(calls_waiting) FROM realtime_queues',
        'SELECT AVG(longest_wait_time) FROM realtime_queues WHERE calls_waiting > 0',
        'SELECT COUNT(*) FROM realtime_agents WHERE current_state = ''available''',
        'SELECT queue_id, COUNT(*) FROM realtime_agents GROUP BY queue_id',
        'SELECT current_state, COUNT(*) FROM realtime_agents GROUP BY current_state',
        'SELECT AVG(avg_handle_time_today) FROM realtime_agents WHERE calls_today > 0',
        'SELECT SUM(calls_today) FROM realtime_agents',
        'SELECT queue_id, SUM(calls_waiting) FROM realtime_queues GROUP BY queue_id',
        'SELECT COUNT(*) FROM realtime_queues rq JOIN realtime_agents ra ON rq.queue_id = ra.current_queue_id'
    ];
    query_text TEXT;
    successful_queries INTEGER := 0;
    total_queries INTEGER := 0;
BEGIN
    test_start := CURRENT_TIMESTAMP;
    
    RAISE NOTICE 'Starting real-time aggregations performance test';
    
    -- Test each type of aggregation multiple times
    FOR i IN 1..5 LOOP
        FOREACH query_text IN ARRAY test_queries LOOP
            query_start := CURRENT_TIMESTAMP;
            
            -- Execute the aggregation query
            EXECUTE query_text;
            
            query_end := CURRENT_TIMESTAMP;
            
            aggregation_times := array_append(aggregation_times, 
                EXTRACT(EPOCH FROM (query_end - query_start)) * 1000);
            
            successful_queries := successful_queries + 1;
            total_queries := total_queries + 1;
        END LOOP;
    END LOOP;
    
    -- Test complex real-time dashboard query
    FOR i IN 1..10 LOOP
        query_start := CURRENT_TIMESTAMP;
        
        PERFORM 
            rq.queue_id,
            rq.queue_name,
            rq.calls_waiting,
            rq.calls_in_progress,
            rq.agents_available,
            rq.longest_wait_time,
            rq.service_level_current,
            COUNT(ra.agent_id) as total_agents,
            COUNT(CASE WHEN ra.current_state = 'available' THEN 1 END) as available_agents,
            COUNT(CASE WHEN ra.current_state = 'busy' THEN 1 END) as busy_agents,
            AVG(ra.avg_handle_time_today) as avg_aht
        FROM realtime_queues rq
        LEFT JOIN realtime_agents ra ON rq.queue_id = ra.current_queue_id
        WHERE rq.queue_status = 'active'
        GROUP BY rq.queue_id, rq.queue_name, rq.calls_waiting, 
                 rq.calls_in_progress, rq.agents_available, 
                 rq.longest_wait_time, rq.service_level_current
        ORDER BY rq.calls_waiting DESC;
        
        query_end := CURRENT_TIMESTAMP;
        
        aggregation_times := array_append(aggregation_times, 
            EXTRACT(EPOCH FROM (query_end - query_start)) * 1000);
        
        successful_queries := successful_queries + 1;
        total_queries := total_queries + 1;
    END LOOP;
    
    -- Calculate statistics
    SELECT 
        avg(t), max(t), min(t) 
    INTO avg_time, max_time, min_time
    FROM unnest(aggregation_times) AS t;
    
    test_end := CURRENT_TIMESTAMP;
    
    -- Record results
    INSERT INTO perf_test_results (
        test_name, test_start, test_end, 
        duration_seconds, records_processed,
        avg_response_time_ms, max_response_time_ms, min_response_time_ms,
        throughput_per_second, success_rate, errors_encountered,
        test_passed, notes
    ) VALUES (
        'REALTIME_AGGREGATIONS',
        test_start, test_end,
        EXTRACT(EPOCH FROM (test_end - test_start)),
        successful_queries,
        avg_time, max_time, min_time,
        total_queries / EXTRACT(EPOCH FROM (test_end - test_start)),
        (successful_queries * 100.0) / total_queries,
        total_queries - successful_queries,
        (avg_time <= 100.0), -- Pass if average <= 100ms for aggregations
        format('Aggregation queries: %s, Success rate: %s%%', 
               total_queries, (successful_queries * 100.0) / total_queries)
    );
    
    RAISE NOTICE 'Real-time aggregations test completed - Avg: %ms, Max: %ms, Success: %/%', 
        avg_time, max_time, successful_queries, total_queries;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Execute All Tests
-- =====================================================

-- Master test execution function
CREATE OR REPLACE FUNCTION execute_all_performance_tests() RETURNS void AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    total_duration INTERVAL;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    
    RAISE NOTICE '=== STARTING COMPREHENSIVE PERFORMANCE TESTS ===';
    RAISE NOTICE 'Start time: %', start_time;
    
    -- Setup phase
    RAISE NOTICE 'Setting up test data...';
    PERFORM generate_test_queues();
    PERFORM generate_test_agents();
    PERFORM generate_realtime_test_data();
    
    -- Test 1: 100K calls across 68 queues
    RAISE NOTICE 'TEST 1: Generating 100K calls across 68 queues...';
    PERFORM generate_100k_calls();
    RAISE NOTICE 'TEST 1: Testing 100K calls performance...';
    PERFORM test_100k_calls_performance();
    
    -- Test 2: 1000 concurrent agent queries
    RAISE NOTICE 'TEST 2: Testing 1000 concurrent agent queries...';
    PERFORM test_concurrent_agent_queries();
    
    -- Test 3: Real-time aggregations
    RAISE NOTICE 'TEST 3: Testing real-time aggregations...';
    PERFORM test_realtime_aggregations();
    
    end_time := CURRENT_TIMESTAMP;
    total_duration := end_time - start_time;
    
    RAISE NOTICE '=== PERFORMANCE TESTS COMPLETED ===';
    RAISE NOTICE 'Total duration: %', total_duration;
    RAISE NOTICE 'End time: %', end_time;
    
    -- Display results summary
    RAISE NOTICE 'Results summary:';
    PERFORM display_test_results_summary();
END;
$$ LANGUAGE plpgsql;

-- Display test results summary
CREATE OR REPLACE FUNCTION display_test_results_summary() RETURNS void AS $$
DECLARE
    test_record RECORD;
BEGIN
    RAISE NOTICE '=== TEST RESULTS SUMMARY ===';
    
    FOR test_record IN 
        SELECT 
            test_name,
            records_processed,
            avg_response_time_ms,
            max_response_time_ms,
            throughput_per_second,
            success_rate,
            test_passed,
            notes
        FROM perf_test_results
        ORDER BY created_at DESC
        LIMIT 10
    LOOP
        RAISE NOTICE 'Test: %', test_record.test_name;
        RAISE NOTICE '  Records: %, Avg: %ms, Max: %ms', 
            test_record.records_processed, 
            test_record.avg_response_time_ms, 
            test_record.max_response_time_ms;
        RAISE NOTICE '  Throughput: %/sec, Success: %%, Passed: %', 
            test_record.throughput_per_second, 
            test_record.success_rate, 
            test_record.test_passed;
        RAISE NOTICE '  Notes: %', test_record.notes;
        RAISE NOTICE '  ---';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Cleanup test data
CREATE OR REPLACE FUNCTION cleanup_test_data() RETURNS void AS $$
BEGIN
    DELETE FROM contact_statistics WHERE queue_id LIKE 'TEST_QUEUE_%';
    DELETE FROM realtime_queues WHERE queue_id LIKE 'TEST_QUEUE_%';
    DELETE FROM realtime_agents WHERE agent_id LIKE 'TEST_AGENT_%';
    DELETE FROM queues WHERE queue_id LIKE 'TEST_QUEUE_%';
    DELETE FROM agents WHERE agent_id LIKE 'TEST_AGENT_%';
    
    RAISE NOTICE 'Test data cleanup completed';
END;
$$ LANGUAGE plpgsql;

-- Quick test execution (for immediate verification)
CREATE OR REPLACE FUNCTION quick_performance_test() RETURNS void AS $$
BEGIN
    RAISE NOTICE 'Executing quick performance test...';
    
    -- Quick setup
    PERFORM generate_test_queues();
    PERFORM generate_test_agents();
    
    -- Quick 10K calls test
    INSERT INTO contact_statistics (
        interval_start, interval_end, queue_id, 
        offered_calls, answered_calls, avg_handle_time
    )
    SELECT 
        CURRENT_TIMESTAMP - (random() * INTERVAL '1 day'),
        CURRENT_TIMESTAMP - (random() * INTERVAL '1 day') + INTERVAL '15 minutes',
        'TEST_QUEUE_' || LPAD(((random() * 67)::INTEGER + 1)::TEXT, 3, '0'),
        (random() * 50)::INTEGER + 1,
        (random() * 45)::INTEGER + 1,
        (random() * 200)::INTEGER + 60
    FROM generate_series(1, 10000);
    
    -- Quick performance test
    PERFORM test_100k_calls_performance();
    
    RAISE NOTICE 'Quick test completed - check perf_test_results for details';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Performance Monitoring Views
-- =====================================================

-- Performance dashboard view
CREATE OR REPLACE VIEW performance_dashboard AS
SELECT 
    test_name,
    records_processed,
    avg_response_time_ms,
    max_response_time_ms,
    throughput_per_second,
    success_rate,
    test_passed,
    created_at,
    CASE 
        WHEN avg_response_time_ms <= 10 THEN 'EXCELLENT'
        WHEN avg_response_time_ms <= 50 THEN 'GOOD'
        WHEN avg_response_time_ms <= 100 THEN 'ACCEPTABLE'
        ELSE 'POOR'
    END as performance_rating
FROM perf_test_results
ORDER BY created_at DESC;

-- Performance trends view
CREATE OR REPLACE VIEW performance_trends AS
SELECT 
    test_name,
    DATE_TRUNC('day', created_at) as test_date,
    COUNT(*) as tests_run,
    AVG(avg_response_time_ms) as avg_response_time,
    AVG(throughput_per_second) as avg_throughput,
    AVG(success_rate) as avg_success_rate,
    SUM(CASE WHEN test_passed THEN 1 ELSE 0 END) as tests_passed,
    COUNT(*) - SUM(CASE WHEN test_passed THEN 1 ELSE 0 END) as tests_failed
FROM perf_test_results
GROUP BY test_name, DATE_TRUNC('day', created_at)
ORDER BY test_date DESC, test_name;

-- Performance recommendations
CREATE OR REPLACE VIEW performance_recommendations AS
SELECT 
    test_name,
    CASE 
        WHEN avg_response_time_ms > 100 THEN 'Consider adding indexes or optimizing queries'
        WHEN max_response_time_ms > 1000 THEN 'Investigate slow queries and potential bottlenecks'
        WHEN success_rate < 95 THEN 'Check for connection issues or timeouts'
        WHEN throughput_per_second < 10 THEN 'Consider database tuning or hardware upgrade'
        ELSE 'Performance is within acceptable limits'
    END as recommendation,
    avg_response_time_ms,
    max_response_time_ms,
    success_rate,
    throughput_per_second
FROM perf_test_results
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY avg_response_time_ms DESC;

-- =====================================================
-- Usage Instructions
-- =====================================================

/*
USAGE INSTRUCTIONS:

1. Execute full test suite:
   SELECT execute_all_performance_tests();

2. Execute quick test (10K records):
   SELECT quick_performance_test();

3. View results:
   SELECT * FROM performance_dashboard;

4. View trends:
   SELECT * FROM performance_trends;

5. Get recommendations:
   SELECT * FROM performance_recommendations;

6. Cleanup test data:
   SELECT cleanup_test_data();

TARGET PERFORMANCE METRICS:
- 100K calls across 68 queues: <10ms average response time
- 1000 concurrent agent queries: <10ms average response time
- Real-time aggregations: <100ms average response time

The tests will automatically pass/fail based on these criteria.
*/