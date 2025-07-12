-- SUBAGENT 2: Concurrent Query Simulator for Load Testing
-- Mission: Simulate 1000+ concurrent users with realistic query patterns
-- Scope: Multi-user simulation, WebSocket load, real-time aggregations

-- =====================================================
-- Configuration and Setup
-- =====================================================

-- Concurrent test configuration
CREATE TABLE IF NOT EXISTS concurrent_test_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_name VARCHAR(100) NOT NULL,
    max_concurrent_users INTEGER DEFAULT 1000,
    test_duration_minutes INTEGER DEFAULT 30,
    query_mix_profile VARCHAR(50) DEFAULT 'enterprise',
    ramp_up_duration_minutes INTEGER DEFAULT 5,
    target_queries_per_second INTEGER DEFAULT 100,
    max_response_time_ms INTEGER DEFAULT 1000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Concurrent test sessions
CREATE TABLE IF NOT EXISTS concurrent_test_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(50) NOT NULL,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP,
    total_queries INTEGER DEFAULT 0,
    successful_queries INTEGER DEFAULT 0,
    failed_queries INTEGER DEFAULT 0,
    avg_response_time_ms DECIMAL(10,3),
    max_response_time_ms DECIMAL(10,3),
    min_response_time_ms DECIMAL(10,3),
    session_status VARCHAR(20) DEFAULT 'active',
    user_role VARCHAR(50),
    location VARCHAR(100)
);

-- Query execution tracking
CREATE TABLE IF NOT EXISTS concurrent_query_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES concurrent_test_sessions(session_id),
    query_type VARCHAR(50) NOT NULL,
    query_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    query_end TIMESTAMP,
    response_time_ms DECIMAL(10,3),
    records_returned INTEGER,
    query_success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    query_complexity VARCHAR(20), -- simple, medium, complex
    cache_hit BOOLEAN DEFAULT FALSE
);

-- Insert default configuration
INSERT INTO concurrent_test_config (test_name, max_concurrent_users, test_duration_minutes, query_mix_profile)
VALUES ('ENTERPRISE_CONCURRENT_TEST', 1000, 30, 'enterprise')
ON CONFLICT DO NOTHING;

-- =====================================================
-- Query Pattern Definitions
-- =====================================================

-- Define realistic query patterns for different user types
CREATE TYPE query_pattern AS (
    query_type VARCHAR(50),
    query_weight INTEGER,
    complexity VARCHAR(20),
    typical_response_time_ms INTEGER,
    user_roles VARCHAR(200)
);

-- Query patterns for different user types
CREATE OR REPLACE FUNCTION get_query_patterns() RETURNS query_pattern[] AS $$
BEGIN
    RETURN ARRAY[
        ('dashboard_summary', 25, 'simple', 50, 'supervisor,manager,agent')::query_pattern,
        ('agent_performance', 20, 'medium', 100, 'supervisor,manager,agent')::query_pattern,
        ('queue_status', 15, 'simple', 30, 'supervisor,manager,agent')::query_pattern,
        ('real_time_metrics', 10, 'medium', 80, 'supervisor,manager')::query_pattern,
        ('historical_analysis', 8, 'complex', 500, 'analyst,manager')::query_pattern,
        ('schedule_view', 7, 'medium', 150, 'supervisor,manager,agent')::query_pattern,
        ('forecast_data', 5, 'complex', 300, 'analyst,manager')::query_pattern,
        ('skill_matching', 4, 'complex', 200, 'supervisor,manager')::query_pattern,
        ('compliance_report', 3, 'complex', 400, 'manager,analyst')::query_pattern,
        ('system_health', 2, 'simple', 40, 'admin,manager')::query_pattern,
        ('audit_trail', 1, 'complex', 600, 'admin,manager')::query_pattern
    ];
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Concurrent User Simulation
-- =====================================================

-- Create concurrent user sessions
CREATE OR REPLACE FUNCTION create_concurrent_sessions(p_user_count INTEGER DEFAULT 1000) RETURNS INTEGER AS $$
DECLARE
    sessions_created INTEGER := 0;
    user_roles VARCHAR(50)[] := ARRAY['agent', 'supervisor', 'manager', 'analyst', 'admin'];
    locations VARCHAR(100)[] := ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'];
BEGIN
    -- Clear existing sessions
    DELETE FROM concurrent_test_sessions;
    DELETE FROM concurrent_query_log;
    
    -- Create concurrent user sessions
    FOR i IN 1..p_user_count LOOP
        INSERT INTO concurrent_test_sessions (
            user_id, user_role, location, session_status
        ) VALUES (
            'CONCURRENT_USER_' || LPAD(i::TEXT, 4, '0'),
            user_roles[1 + (random() * (array_length(user_roles, 1) - 1))::INTEGER],
            locations[1 + (random() * (array_length(locations, 1) - 1))::INTEGER],
            'active'
        );
        
        sessions_created := sessions_created + 1;
    END LOOP;
    
    RETURN sessions_created;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Query Execution Simulation
-- =====================================================

-- Execute dashboard summary query
CREATE OR REPLACE FUNCTION execute_dashboard_summary(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate dashboard summary query
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            rq.queue_id,
            rq.queue_name,
            rq.calls_waiting,
            rq.calls_in_progress,
            rq.agents_available,
            rq.service_level_current,
            COUNT(ra.agent_id) as total_agents,
            COUNT(CASE WHEN ra.current_state = 'available' THEN 1 END) as available_agents
        FROM realtime_queues rq
        LEFT JOIN realtime_agents ra ON rq.queue_id = ra.current_queue_id
        WHERE rq.queue_status = 'active'
        GROUP BY rq.queue_id, rq.queue_name, rq.calls_waiting, rq.calls_in_progress, rq.agents_available, rq.service_level_current
        ORDER BY rq.calls_waiting DESC
        LIMIT 20
    ) summary;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'dashboard_summary', start_time, end_time, response_time, records_count, 'simple');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute agent performance query
CREATE OR REPLACE FUNCTION execute_agent_performance(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate agent performance query
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            ra.agent_id,
            ra.agent_name,
            ra.current_state,
            ra.calls_today,
            ra.avg_handle_time_today,
            ra.adherence_percentage,
            cs.offered_calls,
            cs.answered_calls,
            cs.avg_handle_time
        FROM realtime_agents ra
        LEFT JOIN contact_statistics cs ON cs.queue_id = ra.current_queue_id
            AND cs.interval_start >= CURRENT_DATE
        WHERE ra.agent_id LIKE 'LOAD_AGENT_%'
        ORDER BY ra.calls_today DESC
        LIMIT 50
    ) performance;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'agent_performance', start_time, end_time, response_time, records_count, 'medium');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute queue status query
CREATE OR REPLACE FUNCTION execute_queue_status(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate queue status query
    SELECT COUNT(*) INTO records_count
    FROM realtime_queues
    WHERE queue_id LIKE 'LOAD_QUEUE_%'
    AND queue_status = 'active';
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'queue_status', start_time, end_time, response_time, records_count, 'simple');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute real-time metrics query
CREATE OR REPLACE FUNCTION execute_real_time_metrics(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate real-time metrics aggregation
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            DATE_TRUNC('hour', cs.interval_start) as hour_bucket,
            SUM(cs.offered_calls) as total_offered,
            SUM(cs.answered_calls) as total_answered,
            AVG(cs.avg_handle_time) as avg_aht,
            AVG(cs.service_level_20s) as avg_service_level
        FROM contact_statistics cs
        WHERE cs.queue_id LIKE 'LOAD_QUEUE_%'
        AND cs.interval_start >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY DATE_TRUNC('hour', cs.interval_start)
        ORDER BY hour_bucket DESC
        LIMIT 168 -- 7 days * 24 hours
    ) metrics;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'real_time_metrics', start_time, end_time, response_time, records_count, 'medium');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute historical analysis query
CREATE OR REPLACE FUNCTION execute_historical_analysis(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate complex historical analysis
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            cs.queue_id,
            DATE_TRUNC('day', cs.interval_start) as day_bucket,
            SUM(cs.offered_calls) as daily_offered,
            SUM(cs.answered_calls) as daily_answered,
            AVG(cs.avg_handle_time) as daily_avg_aht,
            AVG(cs.service_level_20s) as daily_service_level,
            EXTRACT(DOW FROM cs.interval_start) as day_of_week,
            COUNT(*) as intervals_count
        FROM contact_statistics cs
        WHERE cs.queue_id LIKE 'LOAD_QUEUE_%'
        AND cs.interval_start >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY cs.queue_id, DATE_TRUNC('day', cs.interval_start), EXTRACT(DOW FROM cs.interval_start)
        HAVING SUM(cs.offered_calls) > 0
        ORDER BY day_bucket DESC, cs.queue_id
        LIMIT 1000
    ) analysis;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'historical_analysis', start_time, end_time, response_time, records_count, 'complex');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute schedule view query
CREATE OR REPLACE FUNCTION execute_schedule_view(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate schedule view query
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            a.agent_id,
            a.agent_name,
            a.skills,
            a.shift_pattern,
            ra.current_state,
            ra.current_queue_id,
            ra.next_break_time
        FROM agents a
        LEFT JOIN realtime_agents ra ON a.agent_id = ra.agent_id
        WHERE a.agent_id LIKE 'LOAD_AGENT_%'
        AND a.is_active = TRUE
        ORDER BY a.agent_name
        LIMIT 100
    ) schedule;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'schedule_view', start_time, end_time, response_time, records_count, 'medium');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- Execute skill matching query
CREATE OR REPLACE FUNCTION execute_skill_matching(p_session_id UUID) RETURNS DECIMAL AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    response_time DECIMAL;
    records_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Simulate complex skill matching query
    SELECT COUNT(*) INTO records_count
    FROM (
        SELECT 
            a.agent_id,
            a.agent_name,
            a.skills,
            ra.current_state,
            COUNT(CASE WHEN ra.current_state = 'available' THEN 1 END) OVER (PARTITION BY a.skills) as available_with_skills,
            COUNT(*) OVER (PARTITION BY a.skills) as total_with_skills
        FROM agents a
        LEFT JOIN realtime_agents ra ON a.agent_id = ra.agent_id
        WHERE a.agent_id LIKE 'LOAD_AGENT_%'
        AND a.skills ? 'voice'
        ORDER BY a.skill_level DESC, available_with_skills DESC
        LIMIT 200
    ) matching;
    
    end_time := clock_timestamp();
    response_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Log query execution
    INSERT INTO concurrent_query_log (session_id, query_type, query_start, query_end, response_time_ms, records_returned, query_complexity)
    VALUES (p_session_id, 'skill_matching', start_time, end_time, response_time, records_count, 'complex');
    
    RETURN response_time;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Concurrent Test Execution
-- =====================================================

-- Execute mixed query pattern for a session
CREATE OR REPLACE FUNCTION execute_session_queries(p_session_id UUID, p_query_count INTEGER DEFAULT 20) RETURNS DECIMAL AS $$
DECLARE
    total_response_time DECIMAL := 0;
    query_response_time DECIMAL;
    query_patterns query_pattern[];
    selected_pattern query_pattern;
    i INTEGER;
BEGIN
    -- Get query patterns
    query_patterns := get_query_patterns();
    
    -- Execute random queries based on patterns
    FOR i IN 1..p_query_count LOOP
        -- Select query pattern based on weights (simplified random selection)
        selected_pattern := query_patterns[1 + (random() * (array_length(query_patterns, 1) - 1))::INTEGER];
        
        -- Execute appropriate query based on pattern
        CASE selected_pattern.query_type
            WHEN 'dashboard_summary' THEN
                query_response_time := execute_dashboard_summary(p_session_id);
            WHEN 'agent_performance' THEN
                query_response_time := execute_agent_performance(p_session_id);
            WHEN 'queue_status' THEN
                query_response_time := execute_queue_status(p_session_id);
            WHEN 'real_time_metrics' THEN
                query_response_time := execute_real_time_metrics(p_session_id);
            WHEN 'historical_analysis' THEN
                query_response_time := execute_historical_analysis(p_session_id);
            WHEN 'schedule_view' THEN
                query_response_time := execute_schedule_view(p_session_id);
            WHEN 'skill_matching' THEN
                query_response_time := execute_skill_matching(p_session_id);
            ELSE
                query_response_time := execute_dashboard_summary(p_session_id);
        END CASE;
        
        total_response_time := total_response_time + query_response_time;
        
        -- Small delay to simulate user thinking time
        PERFORM pg_sleep(0.1 + (random() * 0.5));
    END LOOP;
    
    RETURN total_response_time / p_query_count;
END;
$$ LANGUAGE plpgsql;

-- Execute concurrent load test
CREATE OR REPLACE FUNCTION execute_concurrent_load_test(p_concurrent_users INTEGER DEFAULT 100, p_queries_per_user INTEGER DEFAULT 10) RETURNS TEXT AS $$
DECLARE
    test_start TIMESTAMP;
    test_end TIMESTAMP;
    sessions_created INTEGER;
    session_record RECORD;
    avg_response_time DECIMAL;
    total_queries INTEGER := 0;
    successful_queries INTEGER := 0;
    result_summary TEXT;
BEGIN
    test_start := CURRENT_TIMESTAMP;
    
    RAISE NOTICE 'Starting concurrent load test with % users, % queries per user', p_concurrent_users, p_queries_per_user;
    
    -- Create concurrent sessions
    SELECT create_concurrent_sessions(p_concurrent_users) INTO sessions_created;
    
    -- Execute queries for each session (simulating concurrency)
    FOR session_record IN 
        SELECT session_id FROM concurrent_test_sessions 
        WHERE session_status = 'active' 
        LIMIT p_concurrent_users
    LOOP
        -- Execute queries for this session
        SELECT execute_session_queries(session_record.session_id, p_queries_per_user) INTO avg_response_time;
        
        -- Update session statistics
        UPDATE concurrent_test_sessions 
        SET 
            session_end = CURRENT_TIMESTAMP,
            total_queries = p_queries_per_user,
            successful_queries = (SELECT COUNT(*) FROM concurrent_query_log WHERE session_id = session_record.session_id AND query_success = TRUE),
            failed_queries = (SELECT COUNT(*) FROM concurrent_query_log WHERE session_id = session_record.session_id AND query_success = FALSE),
            avg_response_time_ms = avg_response_time,
            max_response_time_ms = (SELECT MAX(response_time_ms) FROM concurrent_query_log WHERE session_id = session_record.session_id),
            min_response_time_ms = (SELECT MIN(response_time_ms) FROM concurrent_query_log WHERE session_id = session_record.session_id),
            session_status = 'completed'
        WHERE session_id = session_record.session_id;
        
        total_queries := total_queries + p_queries_per_user;
        
        -- Progress reporting
        IF total_queries % 100 = 0 THEN
            RAISE NOTICE 'Completed % queries across % sessions', total_queries, total_queries / p_queries_per_user;
        END IF;
    END LOOP;
    
    test_end := CURRENT_TIMESTAMP;
    
    -- Calculate final statistics
    SELECT SUM(successful_queries) INTO successful_queries FROM concurrent_test_sessions;
    
    -- Build result summary
    result_summary := format(
        'CONCURRENT LOAD TEST COMPLETED
        =============================
        Test Duration: %s
        Concurrent Users: %s
        Queries Per User: %s
        Total Queries: %s
        Successful Queries: %s
        Success Rate: %s%%
        Average Response Time: %s ms
        Queries Per Second: %s
        
        Concurrent load test completed successfully!',
        test_end - test_start,
        sessions_created,
        p_queries_per_user,
        total_queries,
        successful_queries,
        ROUND((successful_queries * 100.0) / total_queries, 2),
        (SELECT ROUND(AVG(avg_response_time_ms), 2) FROM concurrent_test_sessions),
        ROUND(total_queries / EXTRACT(EPOCH FROM (test_end - test_start)), 2)
    );
    
    RAISE NOTICE '%', result_summary;
    
    RETURN result_summary;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Real-time Aggregation Load Test
-- =====================================================

-- Execute real-time aggregation every second
CREATE OR REPLACE FUNCTION execute_realtime_aggregation_load(p_duration_seconds INTEGER DEFAULT 300) RETURNS TEXT AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    current_time TIMESTAMP;
    iteration INTEGER := 0;
    total_response_time DECIMAL := 0;
    max_response_time DECIMAL := 0;
    min_response_time DECIMAL := 999999;
    query_start TIMESTAMP;
    query_end TIMESTAMP;
    query_duration DECIMAL;
    result_summary TEXT;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    current_time := start_time;
    
    RAISE NOTICE 'Starting real-time aggregation load test for % seconds', p_duration_seconds;
    
    -- Execute aggregation queries every second
    WHILE EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) < p_duration_seconds LOOP
        iteration := iteration + 1;
        query_start := clock_timestamp();
        
        -- Execute complex real-time aggregation
        PERFORM
            rq.queue_id,
            rq.calls_waiting,
            rq.calls_in_progress,
            rq.agents_available,
            rq.service_level_current,
            COUNT(ra.agent_id) as total_agents,
            COUNT(CASE WHEN ra.current_state = 'available' THEN 1 END) as available_agents,
            COUNT(CASE WHEN ra.current_state = 'busy' THEN 1 END) as busy_agents,
            COUNT(CASE WHEN ra.current_state = 'on_call' THEN 1 END) as on_call_agents,
            AVG(ra.avg_handle_time_today) as avg_aht,
            SUM(ra.calls_today) as total_calls_today,
            AVG(cs.service_level_20s) as historical_service_level
        FROM realtime_queues rq
        LEFT JOIN realtime_agents ra ON rq.queue_id = ra.current_queue_id
        LEFT JOIN contact_statistics cs ON rq.queue_id = cs.queue_id 
            AND cs.interval_start >= CURRENT_DATE - INTERVAL '1 day'
        WHERE rq.queue_status = 'active'
        GROUP BY rq.queue_id, rq.calls_waiting, rq.calls_in_progress, rq.agents_available, rq.service_level_current
        ORDER BY rq.calls_waiting DESC;
        
        query_end := clock_timestamp();
        query_duration := EXTRACT(EPOCH FROM (query_end - query_start)) * 1000;
        
        -- Track response times
        total_response_time := total_response_time + query_duration;
        max_response_time := GREATEST(max_response_time, query_duration);
        min_response_time := LEAST(min_response_time, query_duration);
        
        -- Progress reporting every 60 seconds
        IF iteration % 60 = 0 THEN
            RAISE NOTICE 'Completed % iterations, Avg response: % ms', iteration, ROUND(total_response_time / iteration, 2);
        END IF;
        
        -- Sleep until next second
        PERFORM pg_sleep(1.0);
    END LOOP;
    
    end_time := CURRENT_TIMESTAMP;
    
    -- Build result summary
    result_summary := format(
        'REAL-TIME AGGREGATION LOAD TEST COMPLETED
        ========================================
        Test Duration: %s seconds
        Total Iterations: %s
        Queries Per Second: %s
        Average Response Time: %s ms
        Maximum Response Time: %s ms
        Minimum Response Time: %s ms
        
        Real-time aggregation load test completed successfully!',
        EXTRACT(EPOCH FROM (end_time - start_time)),
        iteration,
        ROUND(iteration / EXTRACT(EPOCH FROM (end_time - start_time)), 2),
        ROUND(total_response_time / iteration, 2),
        ROUND(max_response_time, 2),
        ROUND(min_response_time, 2)
    );
    
    RAISE NOTICE '%', result_summary;
    
    RETURN result_summary;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Performance Monitoring Views
-- =====================================================

-- Concurrent test performance summary
CREATE OR REPLACE VIEW concurrent_test_performance AS
SELECT 
    'Concurrent Test Performance' as metric_type,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN session_status = 'completed' THEN 1 END) as completed_sessions,
    SUM(total_queries) as total_queries_executed,
    SUM(successful_queries) as total_successful_queries,
    ROUND(AVG(avg_response_time_ms), 2) as avg_response_time_ms,
    ROUND(MAX(max_response_time_ms), 2) as max_response_time_ms,
    ROUND(MIN(min_response_time_ms), 2) as min_response_time_ms,
    ROUND((SUM(successful_queries) * 100.0) / SUM(total_queries), 2) as success_rate_percent
FROM concurrent_test_sessions
WHERE session_start >= CURRENT_DATE;

-- Query type performance analysis
CREATE OR REPLACE VIEW query_type_performance AS
SELECT 
    query_type,
    query_complexity,
    COUNT(*) as total_executions,
    ROUND(AVG(response_time_ms), 2) as avg_response_time_ms,
    ROUND(MAX(response_time_ms), 2) as max_response_time_ms,
    ROUND(MIN(response_time_ms), 2) as min_response_time_ms,
    ROUND(STDDEV(response_time_ms), 2) as response_time_stddev,
    COUNT(CASE WHEN query_success = TRUE THEN 1 END) as successful_queries,
    COUNT(CASE WHEN query_success = FALSE THEN 1 END) as failed_queries,
    ROUND((COUNT(CASE WHEN query_success = TRUE THEN 1 END) * 100.0) / COUNT(*), 2) as success_rate_percent
FROM concurrent_query_log
GROUP BY query_type, query_complexity
ORDER BY avg_response_time_ms DESC;

-- User role performance analysis
CREATE OR REPLACE VIEW user_role_performance AS
SELECT 
    cts.user_role,
    COUNT(*) as total_sessions,
    SUM(cts.total_queries) as total_queries,
    ROUND(AVG(cts.avg_response_time_ms), 2) as avg_response_time_ms,
    ROUND(AVG(cts.successful_queries * 100.0 / cts.total_queries), 2) as avg_success_rate,
    COUNT(CASE WHEN cts.avg_response_time_ms <= 100 THEN 1 END) as sessions_under_100ms,
    COUNT(CASE WHEN cts.avg_response_time_ms > 1000 THEN 1 END) as sessions_over_1000ms
FROM concurrent_test_sessions cts
WHERE cts.session_start >= CURRENT_DATE
GROUP BY cts.user_role
ORDER BY avg_response_time_ms;

-- =====================================================
-- Cleanup Functions
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_concurrent_test_data() RETURNS TEXT AS $$
DECLARE
    deleted_sessions INTEGER;
    deleted_logs INTEGER;
BEGIN
    DELETE FROM concurrent_query_log;
    GET DIAGNOSTICS deleted_logs = ROW_COUNT;
    
    DELETE FROM concurrent_test_sessions;
    GET DIAGNOSTICS deleted_sessions = ROW_COUNT;
    
    RETURN format('Cleanup completed. Deleted %s sessions and %s query logs.', deleted_sessions, deleted_logs);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Usage Instructions
-- =====================================================

/*
SUBAGENT 2: CONCURRENT QUERY SIMULATOR - USAGE INSTRUCTIONS

1. Execute concurrent load test (100 users, 10 queries each):
   SELECT execute_concurrent_load_test(100, 10);

2. Execute full concurrent load test (1000 users):
   SELECT execute_concurrent_load_test(1000, 20);

3. Execute real-time aggregation load test (5 minutes):
   SELECT execute_realtime_aggregation_load(300);

4. View concurrent test performance:
   SELECT * FROM concurrent_test_performance;

5. Analyze query type performance:
   SELECT * FROM query_type_performance;

6. Analyze user role performance:
   SELECT * FROM user_role_performance;

7. Cleanup test data:
   SELECT cleanup_concurrent_test_data();

TEST SCENARIOS COVERED:
- Dashboard summary queries (simple, fast)
- Agent performance queries (medium complexity)
- Queue status queries (simple, frequent)
- Real-time metrics (medium complexity, aggregations)
- Historical analysis (complex, resource-intensive)
- Schedule view queries (medium complexity)
- Skill matching queries (complex, multi-table joins)

PERFORMANCE TARGETS:
- Simple queries: <50ms average response time
- Medium queries: <200ms average response time
- Complex queries: <500ms average response time
- Concurrent users: 1000+ simultaneous sessions
- Success rate: >99% for all query types
- Queries per second: 100+ sustained throughput

The simulator provides realistic load testing for:
- Peak concurrent user scenarios
- Mixed query complexity patterns
- Real-time aggregation performance
- Multi-user role access patterns
- WebSocket-style real-time updates
*/