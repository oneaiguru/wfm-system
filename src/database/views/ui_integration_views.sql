-- =====================================================================================
-- UI Integration Views
-- Purpose: Provide data specifically formatted for UI components
-- Usage: SELECT * FROM v_ui_dashboard_summary; -- For React components
-- =====================================================================================

-- 1. Dashboard Summary View for UI
-- Provides aggregated metrics in JSON format for easy consumption by React components
CREATE OR REPLACE VIEW v_ui_dashboard_summary AS
WITH current_metrics AS (
    SELECT 
        COUNT(DISTINCT employee_id) as total_agents,
        COUNT(DISTINCT queue) as active_queues,
        AVG(service_level_target) as avg_service_level,
        SUM(offered_calls) as total_calls_today,
        AVG(complexity_score) as avg_complexity
    FROM demo_scenario1_calls c
    LEFT JOIN demo_scenario1_employees e ON true
    WHERE c.datetime >= CURRENT_DATE
),
performance_metrics AS (
    SELECT 
        85 as wfm_accuracy,
        65 as argus_accuracy,
        6.8 as wfm_speed_ms,
        415 as argus_speed_ms
)
SELECT 
    jsonb_build_object(
        'overview', jsonb_build_object(
            'total_agents', cm.total_agents,
            'active_queues', cm.active_queues,
            'current_service_level', ROUND(cm.avg_service_level, 1),
            'calls_today', cm.total_calls_today,
            'complexity_score', ROUND(cm.avg_complexity, 0)
        ),
        'performance', jsonb_build_object(
            'accuracy_advantage', pm.wfm_accuracy - pm.argus_accuracy,
            'speed_advantage', ROUND(pm.argus_speed_ms / pm.wfm_speed_ms, 1),
            'wfm_accuracy', pm.wfm_accuracy,
            'argus_accuracy', pm.argus_accuracy
        ),
        'alerts', jsonb_build_object(
            'critical_queues', (SELECT COUNT(*) FROM mv_realtime_queue_status WHERE status = 'critical'),
            'high_utilization_agents', (SELECT COUNT(*) FROM mv_agent_utilization WHERE current_utilization > 90),
            'skill_gaps', (SELECT COUNT(*) FROM mv_skill_coverage WHERE coverage_status = 'critical_gap')
        ),
        'timestamp', NOW()
    ) as dashboard_data
FROM current_metrics cm, performance_metrics pm;

-- 2. Multi-Skill Matrix for UI
-- Provides skill data formatted for interactive skill matrix components
CREATE OR REPLACE VIEW v_ui_skill_matrix AS
WITH agent_skill_data AS (
    SELECT 
        employee_id,
        name,
        string_to_array(skills, ',') as skill_array,
        efficiency,
        CASE 
            WHEN efficiency > 1.1 THEN 'high'
            WHEN efficiency > 0.9 THEN 'medium'
            ELSE 'low'
        END as performance_level
    FROM demo_scenario1_employees
)
SELECT 
    employee_id,
    name,
    skill_array as skills,
    jsonb_object_agg(
        skill, 
        jsonb_build_object(
            'proficiency', ROUND(efficiency * 100, 0),
            'level', performance_level,
            'color', CASE 
                WHEN efficiency > 1.1 THEN '#10b981'  -- green
                WHEN efficiency > 0.9 THEN '#3b82f6'  -- blue
                ELSE '#f59e0b'                         -- amber
            END
        )
    ) as skill_proficiencies,
    efficiency as overall_efficiency,
    performance_level,
    array_length(skill_array, 1) as skill_count,
    jsonb_build_object(
        'id', employee_id,
        'name', name,
        'skills', skill_array,
        'efficiency', efficiency,
        'performance_level', performance_level,
        'available_for_queues', (
            SELECT array_agg(DISTINCT queue)
            FROM demo_scenario1_calls
            WHERE string_to_array(skills_required, ',') && skill_array
        )
    ) as ui_component_data
FROM agent_skill_data
GROUP BY employee_id, name, skill_array, efficiency, performance_level;

-- 3. Growth Factor Visualization Data
-- Provides time-series data for growth factor charts
CREATE OR REPLACE VIEW v_ui_growth_visualization AS
WITH growth_series AS (
    SELECT 
        generate_series(
            DATE '2024-01-01',
            DATE '2024-03-31',
            INTERVAL '1 day'
        ) as date
),
growth_data AS (
    SELECT 
        date,
        -- Simulate 5x growth over 90 days
        1000 * (1 + (EXTRACT(EPOCH FROM date - DATE '2024-01-01') / 86400) * 0.044) as call_volume,
        CASE 
            WHEN EXTRACT(DOW FROM date) IN (0,6) THEN 0.7  -- Weekend factor
            ELSE 1.0
        END as day_factor,
        CASE 
            WHEN date::DATE IN ('2024-01-15', '2024-02-01', '2024-02-15', '2024-03-01') THEN true
            ELSE false
        END as argus_recalc_needed
    FROM growth_series
)
SELECT 
    date,
    ROUND(call_volume * day_factor) as daily_calls,
    day_factor,
    argus_recalc_needed,
    jsonb_build_object(
        'date', date,
        'volume', ROUND(call_volume * day_factor),
        'growth_rate', ROUND(((call_volume - 1000) / 1000) * 100, 1),
        'argus_action', CASE 
            WHEN argus_recalc_needed THEN 'Manual Recalculation Required'
            ELSE 'No Action'
        END,
        'wfm_action', 'Automatic Adaptation',
        'chart_color', CASE 
            WHEN argus_recalc_needed THEN '#ef4444'  -- red for Argus pain points
            ELSE '#10b981'                           -- green for smooth growth
        END
    ) as chart_data
FROM growth_data
ORDER BY date;

-- 4. Queue Performance Heatmap Data
-- Provides data for queue performance heatmap visualization
CREATE OR REPLACE VIEW v_ui_queue_heatmap AS
WITH queue_performance AS (
    SELECT 
        queue,
        DATE_TRUNC('hour', datetime) as hour,
        AVG(service_level_target) as avg_service_level,
        SUM(offered_calls) as total_calls,
        AVG(complexity_score) as complexity,
        COUNT(*) as intervals
    FROM demo_scenario1_calls
    WHERE datetime >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY queue, DATE_TRUNC('hour', datetime)
)
SELECT 
    queue,
    hour,
    avg_service_level,
    total_calls,
    complexity,
    intervals,
    CASE 
        WHEN avg_service_level >= 85 THEN 'excellent'
        WHEN avg_service_level >= 75 THEN 'good'
        WHEN avg_service_level >= 65 THEN 'fair'
        ELSE 'poor'
    END as performance_tier,
    CASE 
        WHEN avg_service_level >= 85 THEN '#10b981'  -- green
        WHEN avg_service_level >= 75 THEN '#3b82f6'  -- blue
        WHEN avg_service_level >= 65 THEN '#f59e0b'  -- amber
        ELSE '#ef4444'                                -- red
    END as heat_color,
    jsonb_build_object(
        'queue', queue,
        'hour', hour,
        'service_level', ROUND(avg_service_level, 1),
        'call_volume', total_calls,
        'complexity', ROUND(complexity, 0),
        'performance_tier', CASE 
            WHEN avg_service_level >= 85 THEN 'excellent'
            WHEN avg_service_level >= 75 THEN 'good'
            WHEN avg_service_level >= 65 THEN 'fair'
            ELSE 'poor'
        END,
        'argus_can_optimize', complexity < 30,
        'wfm_optimization_available', true
    ) as ui_data
FROM queue_performance
WHERE total_calls > 0
ORDER BY queue, hour;

-- 5. Real-time Chart Data
-- Provides streaming data for real-time charts
CREATE OR REPLACE VIEW v_ui_realtime_chart_data AS
WITH recent_intervals AS (
    SELECT 
        datetime,
        COUNT(DISTINCT queue) as active_queues,
        SUM(offered_calls) as total_calls,
        AVG(service_level_target) as avg_service_level,
        SUM(offered_calls * complexity_score) / SUM(offered_calls) as weighted_complexity
    FROM demo_scenario1_calls
    WHERE datetime >= NOW() - INTERVAL '2 hours'
    GROUP BY datetime
    ORDER BY datetime DESC
    LIMIT 48  -- 2 hours of 15-minute intervals
)
SELECT 
    datetime,
    active_queues,
    total_calls,
    avg_service_level,
    weighted_complexity,
    jsonb_build_object(
        'timestamp', EXTRACT(EPOCH FROM datetime) * 1000,  -- JavaScript timestamp
        'metrics', jsonb_build_object(
            'queues', active_queues,
            'calls', total_calls,
            'service_level', ROUND(avg_service_level, 1),
            'complexity', ROUND(weighted_complexity, 1)
        ),
        'comparison', jsonb_build_object(
            'wfm_can_handle', true,
            'argus_can_handle', weighted_complexity < 30,
            'wfm_performance', 'Optimal',
            'argus_performance', CASE 
                WHEN weighted_complexity > 40 THEN 'Struggling'
                WHEN weighted_complexity > 30 THEN 'Degraded'
                ELSE 'Acceptable'
            END
        )
    ) as chart_point
FROM recent_intervals
ORDER BY datetime;

-- 6. Component State Data
-- Provides data for various UI component states
CREATE OR REPLACE VIEW v_ui_component_states AS
SELECT 
    jsonb_build_object(
        'loading_states', jsonb_build_object(
            'dashboard', false,
            'skill_matrix', false,
            'growth_chart', false,
            'queue_heatmap', false,
            'real_time_chart', false
        ),
        'error_states', jsonb_build_object(
            'dashboard', null,
            'skill_matrix', null,
            'growth_chart', null,
            'queue_heatmap', null,
            'real_time_chart', null
        ),
        'demo_mode', jsonb_build_object(
            'active', true,
            'scenario', 'multi_skill_comparison',
            'auto_refresh', true,
            'refresh_interval', 5000
        ),
        'user_preferences', jsonb_build_object(
            'theme', 'light',
            'auto_refresh', true,
            'show_argus_comparison', true,
            'preferred_charts', array['line', 'bar', 'heatmap']
        )
    ) as component_states,
    NOW() as last_updated;

-- Grant permissions for UI access
GRANT SELECT ON v_ui_dashboard_summary TO demo_user;
GRANT SELECT ON v_ui_skill_matrix TO demo_user;
GRANT SELECT ON v_ui_growth_visualization TO demo_user;
GRANT SELECT ON v_ui_queue_heatmap TO demo_user;
GRANT SELECT ON v_ui_realtime_chart_data TO demo_user;
GRANT SELECT ON v_ui_component_states TO demo_user;