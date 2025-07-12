-- =====================================================================================
-- Demo Real-time Metrics Views
-- Purpose: Create refreshable views for live demo updates
-- Usage: SELECT * FROM mv_realtime_queue_status; -- For WebSocket updates
-- =====================================================================================

-- Real-time Queue Status (materialized view for performance)
CREATE MATERIALIZED VIEW mv_realtime_queue_status AS
SELECT 
    queue_name,
    calls_waiting,
    avg_wait_time,
    service_level,
    CASE 
        WHEN service_level < 70 THEN 'critical'
        WHEN service_level < 80 THEN 'warning'
        ELSE 'healthy'
    END as status,
    CASE 
        WHEN service_level < 70 THEN '#ef4444'  -- red
        WHEN service_level < 80 THEN '#f59e0b'  -- amber
        ELSE '#10b981'                           -- green
    END as status_color,
    NOW() as last_updated
FROM (
    SELECT 
        queue as queue_name,
        FLOOR(random() * 15) as calls_waiting,
        FLOOR(random() * 45 + 15) as avg_wait_time,
        CASE 
            WHEN queue LIKE '%VIP%' THEN 90 + (random() * 8)::INT
            WHEN queue LIKE '%Priority%' THEN 85 + (random() * 10)::INT
            ELSE 75 + (random() * 15)::INT
        END as service_level
    FROM (
        SELECT DISTINCT queue 
        FROM demo_scenario1_calls 
        LIMIT 20
    ) q
) live_data;

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX idx_mv_realtime_queue_status_queue 
ON mv_realtime_queue_status (queue_name);

-- Real-time Agent Utilization
CREATE MATERIALIZED VIEW mv_agent_utilization AS
WITH agent_stats AS (
    SELECT 
        employee_id,
        name,
        efficiency,
        skills,
        CASE 
            WHEN efficiency > 1.1 THEN 'high_performer'
            WHEN efficiency > 0.9 THEN 'standard'
            ELSE 'needs_support'
        END as performance_tier,
        FLOOR(random() * 100) as current_utilization,
        CASE 
            WHEN random() < 0.8 THEN 'ready'
            WHEN random() < 0.95 THEN 'busy'
            ELSE 'not_ready'
        END as current_status
    FROM demo_scenario1_employees
    LIMIT 50
)
SELECT 
    employee_id,
    name,
    efficiency,
    skills,
    performance_tier,
    current_utilization,
    current_status,
    CASE 
        WHEN current_status = 'ready' THEN '#10b981'      -- green
        WHEN current_status = 'busy' THEN '#f59e0b'       -- amber
        ELSE '#6b7280'                                     -- gray
    END as status_color,
    CASE 
        WHEN current_utilization > 90 THEN 'overloaded'
        WHEN current_utilization > 75 THEN 'optimal'
        WHEN current_utilization > 50 THEN 'underutilized'
        ELSE 'idle'
    END as utilization_status,
    NOW() as last_updated
FROM agent_stats;

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX idx_mv_agent_utilization_employee 
ON mv_agent_utilization (employee_id);

-- Real-time Skill Coverage
CREATE MATERIALIZED VIEW mv_skill_coverage AS
WITH skill_demand AS (
    SELECT 
        unnest(string_to_array(skills_required, ',')) as skill,
        SUM(offered_calls) as total_demand
    FROM demo_scenario1_calls
    WHERE datetime >= NOW() - INTERVAL '1 hour'
    GROUP BY skill
),
skill_supply AS (
    SELECT 
        unnest(string_to_array(skills, ',')) as skill,
        COUNT(*) as available_agents
    FROM demo_scenario1_employees
    GROUP BY skill
)
SELECT 
    d.skill,
    d.total_demand,
    COALESCE(s.available_agents, 0) as available_agents,
    CASE 
        WHEN COALESCE(s.available_agents, 0) = 0 THEN 'critical_gap'
        WHEN d.total_demand / NULLIF(COALESCE(s.available_agents, 0), 0) > 100 THEN 'high_pressure'
        WHEN d.total_demand / NULLIF(COALESCE(s.available_agents, 0), 0) > 50 THEN 'medium_pressure'
        ELSE 'manageable'
    END as coverage_status,
    CASE 
        WHEN COALESCE(s.available_agents, 0) = 0 THEN '#ef4444'  -- red
        WHEN d.total_demand / NULLIF(COALESCE(s.available_agents, 0), 0) > 100 THEN '#f59e0b'  -- amber
        ELSE '#10b981'  -- green
    END as status_color,
    ROUND(d.total_demand / NULLIF(COALESCE(s.available_agents, 0), 0), 2) as demand_ratio,
    NOW() as last_updated
FROM skill_demand d
LEFT JOIN skill_supply s ON d.skill = s.skill
ORDER BY d.total_demand DESC;

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX idx_mv_skill_coverage_skill 
ON mv_skill_coverage (skill);

-- Master refresh function for all real-time views
CREATE OR REPLACE FUNCTION refresh_realtime_metrics()
RETURNS void AS $$
BEGIN
    -- Refresh all materialized views concurrently
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_realtime_queue_status;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_agent_utilization;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_skill_coverage;
    
    -- Log refresh operation
    INSERT INTO demo_refresh_log (refresh_type, refresh_time, status)
    VALUES ('realtime_metrics', NOW(), 'success');
    
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail
    INSERT INTO demo_refresh_log (refresh_type, refresh_time, status, error_message)
    VALUES ('realtime_metrics', NOW(), 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Create refresh log table if it doesn't exist
CREATE TABLE IF NOT EXISTS demo_refresh_log (
    id SERIAL PRIMARY KEY,
    refresh_type VARCHAR(50) NOT NULL,
    refresh_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Live Performance Metrics View (non-materialized for instant updates)
CREATE OR REPLACE VIEW v_live_performance_metrics AS
WITH current_performance AS (
    SELECT 
        COUNT(*) as active_connections,
        (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active') as active_queries,
        (SELECT COALESCE(AVG(mean_exec_time), 0) FROM pg_stat_statements WHERE query LIKE '%demo_%') as avg_query_time,
        (SELECT COUNT(*) FROM mv_realtime_queue_status WHERE status = 'healthy') as healthy_queues,
        (SELECT COUNT(*) FROM mv_realtime_queue_status WHERE status = 'critical') as critical_queues
    FROM pg_stat_activity
    WHERE application_name = 'wfm_demo'
)
SELECT 
    'Database Performance' as metric_category,
    jsonb_build_object(
        'active_connections', active_connections,
        'active_queries', active_queries,
        'avg_query_time_ms', ROUND(avg_query_time::numeric, 2),
        'healthy_queues', healthy_queues,
        'critical_queues', critical_queues,
        'overall_health', CASE 
            WHEN avg_query_time < 10 AND critical_queues = 0 THEN 'excellent'
            WHEN avg_query_time < 50 AND critical_queues < 3 THEN 'good'
            WHEN avg_query_time < 100 AND critical_queues < 5 THEN 'fair'
            ELSE 'needs_attention'
        END
    ) as metrics,
    NOW() as timestamp
FROM current_performance;

-- Real-time Event Stream for WebSocket
CREATE OR REPLACE VIEW v_realtime_event_stream AS
WITH recent_changes AS (
    SELECT 
        'queue_update' as event_type,
        queue_name as entity_id,
        jsonb_build_object(
            'queue_name', queue_name,
            'calls_waiting', calls_waiting,
            'service_level', service_level,
            'status', status,
            'status_color', status_color
        ) as event_data,
        last_updated as event_timestamp
    FROM mv_realtime_queue_status
    WHERE last_updated > NOW() - INTERVAL '5 seconds'
    
    UNION ALL
    
    SELECT 
        'agent_status_change' as event_type,
        employee_id as entity_id,
        jsonb_build_object(
            'employee_id', employee_id,
            'name', name,
            'current_status', current_status,
            'current_utilization', current_utilization,
            'performance_tier', performance_tier
        ) as event_data,
        last_updated as event_timestamp
    FROM mv_agent_utilization
    WHERE last_updated > NOW() - INTERVAL '5 seconds'
      AND current_utilization > 85  -- Only high utilization events
    
    UNION ALL
    
    SELECT 
        'skill_coverage_alert' as event_type,
        skill as entity_id,
        jsonb_build_object(
            'skill', skill,
            'coverage_status', coverage_status,
            'demand_ratio', demand_ratio,
            'available_agents', available_agents
        ) as event_data,
        last_updated as event_timestamp
    FROM mv_skill_coverage
    WHERE last_updated > NOW() - INTERVAL '5 seconds'
      AND coverage_status IN ('critical_gap', 'high_pressure')
)
SELECT 
    gen_random_uuid() as event_id,
    event_type,
    entity_id,
    event_data,
    event_timestamp,
    'wfm_demo' as source_system
FROM recent_changes
ORDER BY event_timestamp DESC
LIMIT 50;

-- Grant permissions
GRANT SELECT ON mv_realtime_queue_status TO demo_user;
GRANT SELECT ON mv_agent_utilization TO demo_user;
GRANT SELECT ON mv_skill_coverage TO demo_user;
GRANT SELECT ON v_live_performance_metrics TO demo_user;
GRANT SELECT ON v_realtime_event_stream TO demo_user;
GRANT SELECT ON demo_refresh_log TO demo_user;