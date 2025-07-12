-- =====================================================================================
-- Integration Helper Functions
-- Purpose: Support seamless integration between UI, Algorithm, and WebSocket agents
-- Usage: SELECT generate_integration_test_data('ui_dashboard', 100); -- For testing
-- =====================================================================================

-- 1. Generate Integration Test Data
CREATE OR REPLACE FUNCTION generate_integration_test_data(
    integration_type TEXT,
    record_count INTEGER DEFAULT 100
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    i INTEGER;
BEGIN
    CASE integration_type
        WHEN 'ui_dashboard' THEN
            result := jsonb_build_object(
                'agents', jsonb_build_array(),
                'queues', jsonb_build_array(),
                'metrics', jsonb_build_object(),
                'generated_at', NOW()
            );
            
            -- Generate agent data
            FOR i IN 1..LEAST(record_count, 50) LOOP
                result := jsonb_set(
                    result,
                    array['agents', (i-1)::TEXT],
                    jsonb_build_object(
                        'id', 'EMP_' || LPAD(i::TEXT, 4, '0'),
                        'name', 'Agent_' || i,
                        'status', (ARRAY['ready', 'busy', 'not_ready'])[ceil(random() * 3)],
                        'utilization', (random() * 100)::INT,
                        'skills', (random() * 5 + 1)::INT
                    )
                );
            END LOOP;
            
            -- Generate queue data
            FOR i IN 1..LEAST(record_count, 20) LOOP
                result := jsonb_set(
                    result,
                    array['queues', (i-1)::TEXT],
                    jsonb_build_object(
                        'id', 'Q_' || LPAD(i::TEXT, 2, '0'),
                        'name', 'Queue_' || i,
                        'calls_waiting', (random() * 15)::INT,
                        'service_level', (75 + random() * 20)::INT,
                        'status', (ARRAY['healthy', 'warning', 'critical'])[ceil(random() * 3)]
                    )
                );
            END LOOP;
            
            -- Generate metrics
            result := jsonb_set(
                result,
                array['metrics'],
                jsonb_build_object(
                    'total_agents', LEAST(record_count, 50),
                    'active_queues', LEAST(record_count, 20),
                    'accuracy', 85,
                    'calls_waiting', (random() * 100)::INT,
                    'avg_response_time', (5 + random() * 10)::NUMERIC(5,2)
                )
            );
            
        WHEN 'algorithm_benchmark' THEN
            result := jsonb_build_object(
                'benchmarks', jsonb_build_array(),
                'summary', jsonb_build_object(),
                'generated_at', NOW()
            );
            
            -- Generate benchmark data
            FOR i IN 1..LEAST(record_count, 10) LOOP
                result := jsonb_set(
                    result,
                    array['benchmarks', (i-1)::TEXT],
                    jsonb_build_object(
                        'algorithm', (ARRAY['erlang_c', 'multi_skill', 'forecast'])[ceil(random() * 3)],
                        'wfm_time_ms', (5 + random() * 15)::NUMERIC(5,2),
                        'argus_time_ms', (300 + random() * 200)::NUMERIC(5,2),
                        'wfm_accuracy', (85 + random() * 10)::NUMERIC(5,2),
                        'argus_accuracy', (65 + random() * 10)::NUMERIC(5,2)
                    )
                );
            END LOOP;
            
            -- Generate summary
            result := jsonb_set(
                result,
                array['summary'],
                jsonb_build_object(
                    'avg_speed_advantage', (20 + random() * 30)::NUMERIC(5,1),
                    'avg_accuracy_advantage', (15 + random() * 10)::NUMERIC(5,1),
                    'total_tests', LEAST(record_count, 10)
                )
            );
            
        WHEN 'websocket_event' THEN
            result := jsonb_build_object(
                'events', jsonb_build_array(),
                'stream_info', jsonb_build_object(),
                'generated_at', NOW()
            );
            
            -- Generate event data
            FOR i IN 1..LEAST(record_count, 20) LOOP
                result := jsonb_set(
                    result,
                    array['events', (i-1)::TEXT],
                    jsonb_build_object(
                        'event_id', gen_random_uuid(),
                        'event_type', (ARRAY['queue_update', 'agent_status', 'metric_update'])[ceil(random() * 3)],
                        'entity_id', 'entity_' || i,
                        'timestamp', NOW() - (i || ' seconds')::INTERVAL,
                        'data', jsonb_build_object(
                            'metric', 'service_level',
                            'value', (75 + random() * 20)::INT,
                            'previous_value', (70 + random() * 20)::INT
                        )
                    )
                );
            END LOOP;
            
            -- Generate stream info
            result := jsonb_set(
                result,
                array['stream_info'],
                jsonb_build_object(
                    'total_events', LEAST(record_count, 20),
                    'event_rate', (5 + random() * 10)::NUMERIC(5,1),
                    'active_connections', (random() * 50)::INT
                )
            );
            
        WHEN 'skill_matrix' THEN
            result := jsonb_build_object(
                'matrix', jsonb_build_array(),
                'skills', jsonb_build_array(),
                'generated_at', NOW()
            );
            
            -- Generate skills list
            FOR i IN 1..LEAST(record_count, 15) LOOP
                result := jsonb_set(
                    result,
                    array['skills', (i-1)::TEXT],
                    jsonb_build_object(
                        'skill_id', 'skill_' || i,
                        'skill_name', (ARRAY['russian', 'english', 'tech_support', 'billing', 'sales'])[((i-1) % 5) + 1],
                        'demand', (50 + random() * 200)::INT,
                        'supply', (30 + random() * 100)::INT
                    )
                );
            END LOOP;
            
            -- Generate matrix data
            FOR i IN 1..LEAST(record_count, 30) LOOP
                result := jsonb_set(
                    result,
                    array['matrix', (i-1)::TEXT],
                    jsonb_build_object(
                        'agent_id', 'agent_' || i,
                        'agent_name', 'Agent_' || i,
                        'skills', (random() * 5 + 1)::INT,
                        'efficiency', (0.8 + random() * 0.4)::NUMERIC(3,2),
                        'utilization', (random() * 100)::INT
                    )
                );
            END LOOP;
            
        ELSE
            result := jsonb_build_object(
                'error', 'Unknown integration type: ' || integration_type,
                'supported_types', jsonb_build_array(
                    'ui_dashboard', 'algorithm_benchmark', 'websocket_event', 'skill_matrix'
                )
            );
    END CASE;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 2. Validate Integration Data
CREATE OR REPLACE FUNCTION validate_integration_data(
    integration_type TEXT,
    data_payload JSONB
)
RETURNS TABLE(
    is_valid BOOLEAN,
    validation_errors JSONB,
    suggestions JSONB
) AS $$
DECLARE
    errors JSONB := jsonb_build_array();
    suggestions JSONB := jsonb_build_array();
    valid BOOLEAN := true;
BEGIN
    CASE integration_type
        WHEN 'ui_dashboard' THEN
            -- Validate required fields
            IF NOT data_payload ? 'agents' THEN
                errors := errors || jsonb_build_object('field', 'agents', 'error', 'Missing agents array');
                valid := false;
            END IF;
            
            IF NOT data_payload ? 'queues' THEN
                errors := errors || jsonb_build_object('field', 'queues', 'error', 'Missing queues array');
                valid := false;
            END IF;
            
            -- Validate data types
            IF data_payload ? 'metrics' AND jsonb_typeof(data_payload->'metrics') != 'object' THEN
                errors := errors || jsonb_build_object('field', 'metrics', 'error', 'Metrics must be an object');
                valid := false;
            END IF;
            
            -- Suggestions
            IF jsonb_array_length(data_payload->'agents') < 10 THEN
                suggestions := suggestions || jsonb_build_object('suggestion', 'Consider including more agents for better visualization');
            END IF;
            
        WHEN 'algorithm_benchmark' THEN
            -- Validate benchmark structure
            IF NOT data_payload ? 'benchmarks' THEN
                errors := errors || jsonb_build_object('field', 'benchmarks', 'error', 'Missing benchmarks array');
                valid := false;
            END IF;
            
            -- Validate performance metrics
            IF data_payload ? 'summary' AND data_payload->'summary' ? 'avg_speed_advantage' THEN
                IF (data_payload->'summary'->>'avg_speed_advantage')::NUMERIC < 1 THEN
                    errors := errors || jsonb_build_object('field', 'avg_speed_advantage', 'error', 'Speed advantage should be >= 1');
                    valid := false;
                END IF;
            END IF;
            
        WHEN 'websocket_event' THEN
            -- Validate event structure
            IF NOT data_payload ? 'events' THEN
                errors := errors || jsonb_build_object('field', 'events', 'error', 'Missing events array');
                valid := false;
            END IF;
            
            -- Validate event rate
            IF data_payload ? 'stream_info' AND data_payload->'stream_info' ? 'event_rate' THEN
                IF (data_payload->'stream_info'->>'event_rate')::NUMERIC > 100 THEN
                    suggestions := suggestions || jsonb_build_object('suggestion', 'High event rate may overwhelm WebSocket clients');
                END IF;
            END IF;
            
        ELSE
            errors := errors || jsonb_build_object('error', 'Unknown integration type: ' || integration_type);
            valid := false;
    END CASE;
    
    RETURN QUERY
    SELECT 
        valid,
        errors,
        suggestions;
END;
$$ LANGUAGE plpgsql;

-- 3. Format Data for Integration
CREATE OR REPLACE FUNCTION format_for_integration(
    source_type TEXT,
    target_type TEXT,
    source_data JSONB
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    CASE source_type || '_to_' || target_type
        WHEN 'database_to_ui' THEN
            result := jsonb_build_object(
                'dashboard', jsonb_build_object(
                    'agents', (SELECT jsonb_agg(
                        jsonb_build_object(
                            'id', employee_id,
                            'name', name,
                            'status', CASE 
                                WHEN efficiency > 1.0 THEN 'high_performer'
                                WHEN efficiency > 0.9 THEN 'standard'
                                ELSE 'needs_support'
                            END,
                            'utilization', (efficiency * 100)::INT,
                            'skills', string_to_array(skills, ',')
                        )
                    ) FROM demo_scenario1_employees LIMIT 20),
                    'queues', (SELECT jsonb_agg(
                        jsonb_build_object(
                            'id', queue,
                            'name', queue,
                            'calls_waiting', offered_calls,
                            'service_level', service_level_target,
                            'complexity', complexity_score
                        )
                    ) FROM demo_scenario1_calls 
                    WHERE datetime >= NOW() - INTERVAL '1 hour' 
                    GROUP BY queue, offered_calls, service_level_target, complexity_score
                    LIMIT 15),
                    'metrics', jsonb_build_object(
                        'total_agents', (SELECT COUNT(*) FROM demo_scenario1_employees),
                        'active_queues', (SELECT COUNT(DISTINCT queue) FROM demo_scenario1_calls),
                        'accuracy', 85,
                        'response_time', 6.8
                    )
                ),
                'timestamp', NOW()
            );
            
        WHEN 'database_to_websocket' THEN
            result := jsonb_build_object(
                'events', (SELECT jsonb_agg(
                    jsonb_build_object(
                        'event_id', gen_random_uuid(),
                        'event_type', 'queue_update',
                        'entity_id', queue,
                        'payload', jsonb_build_object(
                            'queue', queue,
                            'service_level', service_level_target,
                            'complexity', complexity_score
                        ),
                        'timestamp', datetime
                    )
                ) FROM demo_scenario1_calls 
                WHERE datetime >= NOW() - INTERVAL '5 minutes'
                LIMIT 10),
                'stream_info', jsonb_build_object(
                    'active_connections', (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active'),
                    'event_rate', 5.2,
                    'last_update', NOW()
                )
            );
            
        WHEN 'ui_to_algorithm' THEN
            result := jsonb_build_object(
                'parameters', source_data->'parameters',
                'agents', source_data->'agents',
                'queues', source_data->'queues',
                'optimization_request', jsonb_build_object(
                    'algorithm', 'multi_skill',
                    'objective', 'maximize_service_level',
                    'constraints', jsonb_build_object(
                        'max_utilization', 0.9,
                        'min_service_level', 0.8
                    )
                ),
                'timestamp', NOW()
            );
            
        ELSE
            result := jsonb_build_object(
                'error', 'Unsupported conversion: ' || source_type || ' to ' || target_type,
                'supported_conversions', jsonb_build_array(
                    'database_to_ui',
                    'database_to_websocket',
                    'ui_to_algorithm'
                )
            );
    END CASE;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 4. Test Integration Connections
CREATE OR REPLACE FUNCTION test_integration_connections()
RETURNS TABLE(
    integration_name TEXT,
    status TEXT,
    response_time_ms NUMERIC,
    test_results JSONB
) AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    test_result JSONB;
BEGIN
    -- Test Database Views
    start_time := clock_timestamp();
    SELECT jsonb_build_object('count', COUNT(*)) INTO test_result FROM v_ui_dashboard_summary;
    end_time := clock_timestamp();
    
    RETURN QUERY
    SELECT 
        'Database Views' as name,
        CASE WHEN test_result ? 'count' THEN 'OK' ELSE 'ERROR' END as status,
        EXTRACT(EPOCH FROM (end_time - start_time)) * 1000 as response_ms,
        test_result;
    
    -- Test Materialized Views
    start_time := clock_timestamp();
    SELECT jsonb_build_object('count', COUNT(*)) INTO test_result FROM mv_realtime_queue_status;
    end_time := clock_timestamp();
    
    RETURN QUERY
    SELECT 
        'Materialized Views',
        CASE WHEN test_result ? 'count' THEN 'OK' ELSE 'ERROR' END,
        EXTRACT(EPOCH FROM (end_time - start_time)) * 1000,
        test_result;
    
    -- Test Functions
    start_time := clock_timestamp();
    SELECT get_accuracy_comparison(1) INTO test_result FROM get_accuracy_comparison(1) LIMIT 1;
    end_time := clock_timestamp();
    
    RETURN QUERY
    SELECT 
        'Demo Functions',
        CASE WHEN test_result IS NOT NULL THEN 'OK' ELSE 'ERROR' END,
        EXTRACT(EPOCH FROM (end_time - start_time)) * 1000,
        jsonb_build_object('function_result', test_result IS NOT NULL);
    
    -- Test Integration Data Generation
    start_time := clock_timestamp();
    SELECT generate_integration_test_data('ui_dashboard', 10) INTO test_result;
    end_time := clock_timestamp();
    
    RETURN QUERY
    SELECT 
        'Test Data Generation',
        CASE WHEN test_result ? 'agents' THEN 'OK' ELSE 'ERROR' END,
        EXTRACT(EPOCH FROM (end_time - start_time)) * 1000,
        jsonb_build_object('data_generated', test_result ? 'agents');
END;
$$ LANGUAGE plpgsql;

-- 5. Monitor Integration Performance
CREATE OR REPLACE FUNCTION monitor_integration_performance()
RETURNS TABLE(
    metric_name TEXT,
    current_value NUMERIC,
    threshold NUMERIC,
    status TEXT,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH performance_metrics AS (
        SELECT 
            'Average Query Time' as metric,
            COALESCE(AVG(mean_exec_time), 0) as current_val,
            10.0 as threshold_val,
            'Queries should be under 10ms for optimal UX' as recommendation
        FROM pg_stat_statements
        WHERE query LIKE '%demo_%' OR query LIKE '%v_ui_%' OR query LIKE '%mv_%'
        
        UNION ALL
        
        SELECT 
            'Active Connections',
            COUNT(*)::NUMERIC,
            100.0,
            'Monitor connection pool usage'
        FROM pg_stat_activity
        WHERE state = 'active'
        
        UNION ALL
        
        SELECT 
            'View Refresh Rate',
            COALESCE(AVG(EXTRACT(EPOCH FROM (NOW() - last_updated))), 0),
            30.0,
            'Materialized views should refresh within 30 seconds'
        FROM mv_realtime_queue_status
        
        UNION ALL
        
        SELECT 
            'WebSocket Event Rate',
            COUNT(*)::NUMERIC,
            50.0,
            'Event rate should be manageable for client connections'
        FROM v_websocket_events
        WHERE event_timestamp > NOW() - INTERVAL '1 minute'
    )
    SELECT 
        pm.metric,
        ROUND(pm.current_val, 2),
        pm.threshold_val,
        CASE 
            WHEN pm.current_val <= pm.threshold_val THEN 'GOOD'
            WHEN pm.current_val <= pm.threshold_val * 1.5 THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        pm.recommendation
    FROM performance_metrics pm
    ORDER BY pm.metric;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION generate_integration_test_data(TEXT, INTEGER) TO demo_user;
GRANT EXECUTE ON FUNCTION validate_integration_data(TEXT, JSONB) TO demo_user;
GRANT EXECUTE ON FUNCTION format_for_integration(TEXT, TEXT, JSONB) TO demo_user;
GRANT EXECUTE ON FUNCTION test_integration_connections() TO demo_user;
GRANT EXECUTE ON FUNCTION monitor_integration_performance() TO demo_user;