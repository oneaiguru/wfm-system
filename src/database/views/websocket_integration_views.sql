-- =====================================================================================
-- WebSocket Integration Views
-- Purpose: Generate data for real-time WebSocket updates and event streams
-- Usage: SELECT * FROM v_websocket_events; -- For real-time updates
-- =====================================================================================

-- 1. Real-time Event Stream
-- Generates events for WebSocket broadcasting
CREATE OR REPLACE VIEW v_websocket_events AS
WITH recent_queue_changes AS (
    SELECT 
        'queue_update' as event_type,
        queue_name as entity_id,
        jsonb_build_object(
            'queue_name', queue_name,
            'calls_waiting', calls_waiting,
            'service_level', service_level,
            'status', status,
            'status_color', status_color,
            'avg_wait_time', avg_wait_time
        ) as payload,
        last_updated as event_timestamp,
        1 as priority
    FROM mv_realtime_queue_status
    WHERE last_updated > NOW() - INTERVAL '10 seconds'
),
recent_agent_changes AS (
    SELECT 
        'agent_status_change' as event_type,
        employee_id as entity_id,
        jsonb_build_object(
            'employee_id', employee_id,
            'name', name,
            'current_status', current_status,
            'current_utilization', current_utilization,
            'performance_tier', performance_tier,
            'status_color', status_color,
            'utilization_status', utilization_status
        ) as payload,
        last_updated as event_timestamp,
        CASE 
            WHEN current_utilization > 95 THEN 3  -- High priority
            WHEN current_utilization > 85 THEN 2  -- Medium priority
            ELSE 1                                -- Low priority
        END as priority
    FROM mv_agent_utilization
    WHERE last_updated > NOW() - INTERVAL '10 seconds'
      AND (current_utilization > 85 OR current_status = 'not_ready')
),
recent_skill_alerts AS (
    SELECT 
        'skill_coverage_alert' as event_type,
        skill as entity_id,
        jsonb_build_object(
            'skill', skill,
            'coverage_status', coverage_status,
            'demand_ratio', demand_ratio,
            'available_agents', available_agents,
            'total_demand', total_demand,
            'status_color', status_color,
            'severity', CASE 
                WHEN coverage_status = 'critical_gap' THEN 'critical'
                WHEN coverage_status = 'high_pressure' THEN 'warning'
                ELSE 'info'
            END
        ) as payload,
        last_updated as event_timestamp,
        CASE 
            WHEN coverage_status = 'critical_gap' THEN 3
            WHEN coverage_status = 'high_pressure' THEN 2
            ELSE 1
        END as priority
    FROM mv_skill_coverage
    WHERE last_updated > NOW() - INTERVAL '10 seconds'
      AND coverage_status IN ('critical_gap', 'high_pressure')
),
performance_updates AS (
    SELECT 
        'performance_update' as event_type,
        'system_performance' as entity_id,
        jsonb_build_object(
            'avg_query_time_ms', (SELECT COALESCE(AVG(mean_exec_time), 0) FROM pg_stat_statements WHERE query LIKE '%demo_%'),
            'active_connections', (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active'),
            'cache_hit_ratio', (SELECT ROUND(100 * sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)), 2) FROM pg_statio_user_tables),
            'timestamp', NOW()
        ) as payload,
        NOW() as event_timestamp,
        1 as priority
    WHERE EXISTS (SELECT 1 FROM pg_stat_statements WHERE query LIKE '%demo_%' AND last_call > NOW() - INTERVAL '5 seconds')
),
all_events AS (
    SELECT * FROM recent_queue_changes
    UNION ALL
    SELECT * FROM recent_agent_changes
    UNION ALL
    SELECT * FROM recent_skill_alerts
    UNION ALL
    SELECT * FROM performance_updates
)
SELECT 
    gen_random_uuid() as event_id,
    event_type,
    entity_id,
    payload,
    event_timestamp,
    priority,
    'wfm_demo' as source_system,
    CASE 
        WHEN event_type = 'queue_update' THEN 'queue'
        WHEN event_type = 'agent_status_change' THEN 'agent'
        WHEN event_type = 'skill_coverage_alert' THEN 'skill'
        WHEN event_type = 'performance_update' THEN 'system'
        ELSE 'general'
    END as event_category
FROM all_events
ORDER BY priority DESC, event_timestamp DESC
LIMIT 100;

-- 2. Agent Status Changes for WebSocket
-- Tracks agent status changes for real-time notifications
CREATE OR REPLACE VIEW v_websocket_agent_updates AS
WITH agent_status_simulation AS (
    SELECT 
        employee_id,
        name,
        current_status,
        current_utilization,
        performance_tier,
        -- Simulate previous status
        CASE 
            WHEN current_status = 'ready' THEN 'busy'
            WHEN current_status = 'busy' THEN 'ready'
            ELSE 'ready'
        END as previous_status,
        -- Simulate status duration
        FLOOR(random() * 1800 + 300) as status_duration_seconds,
        last_updated
    FROM mv_agent_utilization
    WHERE last_updated > NOW() - INTERVAL '30 seconds'
)
SELECT 
    employee_id,
    name,
    previous_status,
    current_status,
    status_duration_seconds,
    current_utilization,
    performance_tier,
    jsonb_build_object(
        'event', 'agent_status_change',
        'agent_id', employee_id,
        'agent_name', name,
        'status_change', jsonb_build_object(
            'from', previous_status,
            'to', current_status,
            'duration_seconds', status_duration_seconds,
            'duration_formatted', CASE 
                WHEN status_duration_seconds >= 3600 THEN (status_duration_seconds / 3600)::INT || 'h ' || ((status_duration_seconds % 3600) / 60)::INT || 'm'
                WHEN status_duration_seconds >= 60 THEN (status_duration_seconds / 60)::INT || 'm ' || (status_duration_seconds % 60)::INT || 's'
                ELSE status_duration_seconds::INT || 's'
            END
        ),
        'utilization', current_utilization,
        'performance_tier', performance_tier,
        'timestamp', last_updated,
        'alert_level', CASE 
            WHEN current_utilization > 95 THEN 'critical'
            WHEN current_utilization > 85 THEN 'warning'
            WHEN current_status = 'not_ready' THEN 'info'
            ELSE 'normal'
        END
    ) as websocket_payload
FROM agent_status_simulation
ORDER BY last_updated DESC;

-- 3. Real-time Metrics Stream
-- Provides streaming metrics for dashboards
CREATE OR REPLACE VIEW v_websocket_metrics_stream AS
WITH current_metrics AS (
    SELECT 
        COUNT(*) as total_queues,
        SUM(CASE WHEN status = 'healthy' THEN 1 ELSE 0 END) as healthy_queues,
        SUM(CASE WHEN status = 'critical' THEN 1 ELSE 0 END) as critical_queues,
        SUM(calls_waiting) as total_calls_waiting,
        AVG(service_level) as avg_service_level
    FROM mv_realtime_queue_status
),
agent_metrics AS (
    SELECT 
        COUNT(*) as total_agents,
        SUM(CASE WHEN current_status = 'ready' THEN 1 ELSE 0 END) as ready_agents,
        SUM(CASE WHEN current_status = 'busy' THEN 1 ELSE 0 END) as busy_agents,
        SUM(CASE WHEN current_utilization > 90 THEN 1 ELSE 0 END) as overloaded_agents,
        AVG(current_utilization) as avg_utilization
    FROM mv_agent_utilization
),
skill_metrics AS (
    SELECT 
        COUNT(*) as total_skills,
        SUM(CASE WHEN coverage_status = 'critical_gap' THEN 1 ELSE 0 END) as critical_skills,
        SUM(CASE WHEN coverage_status = 'high_pressure' THEN 1 ELSE 0 END) as high_pressure_skills,
        AVG(demand_ratio) as avg_demand_ratio
    FROM mv_skill_coverage
),
performance_metrics AS (
    SELECT 
        COALESCE(AVG(mean_exec_time), 0) as avg_query_time,
        COUNT(*) as recent_queries,
        SUM(CASE WHEN mean_exec_time < 10 THEN 1 ELSE 0 END) as fast_queries
    FROM pg_stat_statements
    WHERE query LIKE '%demo_%'
      AND last_call > NOW() - INTERVAL '1 minute'
)
SELECT 
    jsonb_build_object(
        'timestamp', NOW(),
        'queues', jsonb_build_object(
            'total', cm.total_queues,
            'healthy', cm.healthy_queues,
            'critical', cm.critical_queues,
            'calls_waiting', cm.total_calls_waiting,
            'avg_service_level', ROUND(cm.avg_service_level, 1),
            'health_score', ROUND((cm.healthy_queues::FLOAT / NULLIF(cm.total_queues, 0)) * 100, 1)
        ),
        'agents', jsonb_build_object(
            'total', am.total_agents,
            'ready', am.ready_agents,
            'busy', am.busy_agents,
            'overloaded', am.overloaded_agents,
            'avg_utilization', ROUND(am.avg_utilization, 1),
            'efficiency_score', ROUND((am.busy_agents::FLOAT / NULLIF(am.total_agents, 0)) * 100, 1)
        ),
        'skills', jsonb_build_object(
            'total', sm.total_skills,
            'critical_gaps', sm.critical_skills,
            'high_pressure', sm.high_pressure_skills,
            'avg_demand_ratio', ROUND(sm.avg_demand_ratio, 2),
            'coverage_score', ROUND(100 - (sm.critical_skills::FLOAT / NULLIF(sm.total_skills, 0)) * 100, 1)
        ),
        'performance', jsonb_build_object(
            'avg_query_time_ms', ROUND(pm.avg_query_time, 2),
            'recent_queries', pm.recent_queries,
            'fast_queries', pm.fast_queries,
            'performance_score', ROUND((pm.fast_queries::FLOAT / NULLIF(pm.recent_queries, 0)) * 100, 1)
        ),
        'overall_health', jsonb_build_object(
            'status', CASE 
                WHEN cm.critical_queues = 0 AND am.overloaded_agents = 0 AND sm.critical_skills = 0 THEN 'excellent'
                WHEN cm.critical_queues <= 2 AND am.overloaded_agents <= 3 AND sm.critical_skills <= 1 THEN 'good'
                WHEN cm.critical_queues <= 5 AND am.overloaded_agents <= 8 AND sm.critical_skills <= 3 THEN 'fair'
                ELSE 'needs_attention'
            END,
            'score', ROUND((
                COALESCE((cm.healthy_queues::FLOAT / NULLIF(cm.total_queues, 0)) * 100, 0) +
                COALESCE((am.busy_agents::FLOAT / NULLIF(am.total_agents, 0)) * 100, 0) +
                COALESCE(100 - (sm.critical_skills::FLOAT / NULLIF(sm.total_skills, 0)) * 100, 0) +
                COALESCE((pm.fast_queries::FLOAT / NULLIF(pm.recent_queries, 0)) * 100, 0)
            ) / 4, 1)
        )
    ) as metrics_payload
FROM current_metrics cm, agent_metrics am, skill_metrics sm, performance_metrics pm;

-- 4. Alert Stream for WebSocket
-- Generates alerts for immediate notification
CREATE OR REPLACE VIEW v_websocket_alert_stream AS
WITH alert_conditions AS (
    SELECT 
        'queue_critical' as alert_type,
        queue_name as entity_id,
        'Critical service level: ' || service_level || '% for queue ' || queue_name as message,
        'critical' as severity,
        status_color as color,
        jsonb_build_object(
            'queue_name', queue_name,
            'service_level', service_level,
            'calls_waiting', calls_waiting,
            'recommended_action', 'Immediate staff reallocation needed'
        ) as alert_data,
        last_updated as alert_timestamp
    FROM mv_realtime_queue_status
    WHERE status = 'critical' AND last_updated > NOW() - INTERVAL '1 minute'
    
    UNION ALL
    
    SELECT 
        'agent_overload' as alert_type,
        employee_id as entity_id,
        'Agent ' || name || ' utilization at ' || current_utilization || '%' as message,
        'warning' as severity,
        '#f59e0b' as color,
        jsonb_build_object(
            'employee_id', employee_id,
            'name', name,
            'utilization', current_utilization,
            'recommended_action', 'Consider break or task redistribution'
        ) as alert_data,
        last_updated as alert_timestamp
    FROM mv_agent_utilization
    WHERE current_utilization > 95 AND last_updated > NOW() - INTERVAL '1 minute'
    
    UNION ALL
    
    SELECT 
        'skill_gap' as alert_type,
        skill as entity_id,
        'Critical skill gap: ' || skill || ' (ratio: ' || demand_ratio || ')' as message,
        'critical' as severity,
        '#ef4444' as color,
        jsonb_build_object(
            'skill', skill,
            'demand_ratio', demand_ratio,
            'available_agents', available_agents,
            'total_demand', total_demand,
            'recommended_action', 'Urgent: Deploy cross-trained agents'
        ) as alert_data,
        last_updated as alert_timestamp
    FROM mv_skill_coverage
    WHERE coverage_status = 'critical_gap' AND last_updated > NOW() - INTERVAL '1 minute'
)
SELECT 
    gen_random_uuid() as alert_id,
    alert_type,
    entity_id,
    message,
    severity,
    color,
    alert_data,
    alert_timestamp,
    jsonb_build_object(
        'alert_id', gen_random_uuid(),
        'type', alert_type,
        'entity', entity_id,
        'message', message,
        'severity', severity,
        'color', color,
        'data', alert_data,
        'timestamp', alert_timestamp,
        'auto_dismiss', CASE 
            WHEN alert_type = 'queue_critical' THEN false
            WHEN alert_type = 'skill_gap' THEN false
            ELSE true
        END,
        'dismiss_timeout', CASE 
            WHEN severity = 'critical' THEN null
            WHEN severity = 'warning' THEN 300000  -- 5 minutes
            ELSE 60000  -- 1 minute
        END
    ) as websocket_alert
FROM alert_conditions
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        ELSE 3
    END,
    alert_timestamp DESC
LIMIT 50;

-- Grant permissions for WebSocket access
GRANT SELECT ON v_websocket_events TO demo_user;
GRANT SELECT ON v_websocket_agent_updates TO demo_user;
GRANT SELECT ON v_websocket_metrics_stream TO demo_user;
GRANT SELECT ON v_websocket_alert_stream TO demo_user;