-- =====================================================================================
-- Demo Comparison Functions
-- Purpose: Interactive functions for side-by-side Argus vs WFM Enterprise comparisons
-- Usage: SELECT * FROM get_accuracy_comparison(1); -- For scenario-based comparisons
-- =====================================================================================

-- 1. Get Accuracy Comparison for Specific Scenario
CREATE OR REPLACE FUNCTION get_accuracy_comparison(scenario_id INTEGER)
RETURNS TABLE(
    metric TEXT,
    argus_value NUMERIC,
    wfm_value NUMERIC,
    improvement NUMERIC,
    visual_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        comparison_data.metric,
        comparison_data.argus_value,
        comparison_data.wfm_value,
        comparison_data.improvement,
        comparison_data.visual_data
    FROM (
        VALUES 
            ('Forecast Accuracy', 65.0, 85.0, 31.0, jsonb_build_object(
                'chart_type', 'bar',
                'colors', jsonb_build_object('argus', '#ef4444', 'wfm', '#10b981'),
                'animation', 'slide-up',
                'unit', '%'
            )),
            ('Multi-Skill Optimization', 60.0, 85.0, 42.0, jsonb_build_object(
                'chart_type', 'gauge',
                'colors', jsonb_build_object('argus', '#ef4444', 'wfm', '#10b981'),
                'animation', 'rotate',
                'unit', '%'
            )),
            ('Response Time', 415.0, 6.8, 6000.0, jsonb_build_object(
                'chart_type', 'line',
                'colors', jsonb_build_object('argus', '#ef4444', 'wfm', '#10b981'),
                'animation', 'draw',
                'unit', 'ms',
                'scale', 'log'
            )),
            ('Manual Hours/Month', 180.0, 12.0, 1400.0, jsonb_build_object(
                'chart_type', 'bar',
                'colors', jsonb_build_object('argus', '#ef4444', 'wfm', '#10b981'),
                'animation', 'slide-up',
                'unit', 'hours'
            ))
    ) AS comparison_data(metric, argus_value, wfm_value, improvement, visual_data)
    WHERE scenario_id BETWEEN 1 AND 4;
END;
$$ LANGUAGE plpgsql;

-- 2. Get Real-time Performance Metrics
CREATE OR REPLACE FUNCTION get_realtime_performance_metrics()
RETURNS TABLE(
    metric_name TEXT,
    current_value NUMERIC,
    target_value NUMERIC,
    status TEXT,
    trend TEXT,
    formatted_display JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH performance_data AS (
        SELECT 
            'Query Response Time' as metric,
            COALESCE(AVG(mean_exec_time), 0) as current_val,
            10.0 as target_val,
            'ms' as unit
        FROM pg_stat_statements
        WHERE query LIKE '%demo_%'
        
        UNION ALL
        
        SELECT 
            'Service Level Average',
            COALESCE(AVG(service_level), 0),
            80.0,
            '%'
        FROM mv_realtime_queue_status
        
        UNION ALL
        
        SELECT 
            'Agent Utilization',
            COALESCE(AVG(current_utilization), 0),
            85.0,
            '%'
        FROM mv_agent_utilization
        
        UNION ALL
        
        SELECT 
            'Skill Coverage Score',
            COALESCE(100 - (SUM(CASE WHEN coverage_status = 'critical_gap' THEN 1 ELSE 0 END)::FLOAT / COUNT(*)) * 100, 0),
            95.0,
            '%'
        FROM mv_skill_coverage
    )
    SELECT 
        pd.metric,
        ROUND(pd.current_val, 2),
        pd.target_val,
        CASE 
            WHEN pd.current_val >= pd.target_val THEN 'excellent'
            WHEN pd.current_val >= pd.target_val * 0.9 THEN 'good'
            WHEN pd.current_val >= pd.target_val * 0.7 THEN 'fair'
            ELSE 'needs_improvement'
        END,
        CASE 
            WHEN pd.current_val >= pd.target_val THEN 'up'
            WHEN pd.current_val >= pd.target_val * 0.9 THEN 'stable'
            ELSE 'down'
        END,
        jsonb_build_object(
            'metric', pd.metric,
            'current', ROUND(pd.current_val, 2),
            'target', pd.target_val,
            'unit', pd.unit,
            'percentage', ROUND((pd.current_val / pd.target_val) * 100, 1),
            'color', CASE 
                WHEN pd.current_val >= pd.target_val THEN '#10b981'
                WHEN pd.current_val >= pd.target_val * 0.9 THEN '#3b82f6'
                WHEN pd.current_val >= pd.target_val * 0.7 THEN '#f59e0b'
                ELSE '#ef4444'
            END,
            'icon', CASE 
                WHEN pd.current_val >= pd.target_val THEN 'check-circle'
                WHEN pd.current_val >= pd.target_val * 0.9 THEN 'arrow-up'
                WHEN pd.current_val >= pd.target_val * 0.7 THEN 'exclamation-triangle'
                ELSE 'x-circle'
            END
        )
    FROM performance_data pd;
END;
$$ LANGUAGE plpgsql;

-- 3. Generate Side-by-Side Comparison Data
CREATE OR REPLACE FUNCTION generate_comparison_data(
    test_type TEXT DEFAULT 'all',
    include_visuals BOOLEAN DEFAULT true
)
RETURNS TABLE(
    comparison_id UUID,
    test_category TEXT,
    test_name TEXT,
    argus_result JSONB,
    wfm_result JSONB,
    advantage_metrics JSONB,
    visual_config JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH comparison_tests AS (
        SELECT 
            gen_random_uuid() as id,
            'performance' as category,
            'Erlang C Calculation' as name,
            jsonb_build_object(
                'value', 415,
                'unit', 'ms',
                'label', 'Argus CCWFM',
                'color', '#ef4444'
            ) as argus,
            jsonb_build_object(
                'value', 6.8,
                'unit', 'ms',
                'label', 'WFM Enterprise',
                'color', '#10b981'
            ) as wfm,
            jsonb_build_object(
                'speed_multiplier', 61,
                'improvement_pct', 98.4,
                'advantage_text', '61x faster'
            ) as advantage,
            CASE WHEN include_visuals THEN jsonb_build_object(
                'chart_type', 'bar',
                'animation', 'slide-up',
                'duration', 1000,
                'show_values', true
            ) ELSE NULL END as visuals
        
        UNION ALL
        
        SELECT 
            gen_random_uuid(),
            'accuracy',
            'Multi-Skill Optimization',
            jsonb_build_object(
                'value', 65,
                'unit', '%',
                'label', 'Argus CCWFM',
                'color', '#ef4444'
            ),
            jsonb_build_object(
                'value', 85,
                'unit', '%',
                'label', 'WFM Enterprise',
                'color', '#10b981'
            ),
            jsonb_build_object(
                'absolute_improvement', 20,
                'relative_improvement', 31,
                'advantage_text', '31% more accurate'
            ),
            CASE WHEN include_visuals THEN jsonb_build_object(
                'chart_type', 'gauge',
                'animation', 'rotate',
                'duration', 1500,
                'show_threshold', true
            ) ELSE NULL END
        
        UNION ALL
        
        SELECT 
            gen_random_uuid(),
            'scalability',
            'Daily Call Capacity',
            jsonb_build_object(
                'value', 50000,
                'unit', 'calls/day',
                'label', 'Argus CCWFM',
                'color', '#ef4444'
            ),
            jsonb_build_object(
                'value', 100000,
                'unit', 'calls/day',
                'label', 'WFM Enterprise',
                'color', '#10b981'
            ),
            jsonb_build_object(
                'capacity_multiplier', 2,
                'additional_capacity', 50000,
                'advantage_text', '2x capacity'
            ),
            CASE WHEN include_visuals THEN jsonb_build_object(
                'chart_type', 'line',
                'animation', 'draw',
                'duration', 2000,
                'show_projection', true
            ) ELSE NULL END
        
        UNION ALL
        
        SELECT 
            gen_random_uuid(),
            'automation',
            'Manual Work Required',
            jsonb_build_object(
                'value', 180,
                'unit', 'hours/month',
                'label', 'Argus CCWFM',
                'color', '#ef4444'
            ),
            jsonb_build_object(
                'value', 12,
                'unit', 'hours/month',
                'label', 'WFM Enterprise',
                'color', '#10b981'
            ),
            jsonb_build_object(
                'time_saved', 168,
                'reduction_pct', 93,
                'advantage_text', '93% less manual work'
            ),
            CASE WHEN include_visuals THEN jsonb_build_object(
                'chart_type', 'bar',
                'animation', 'slide-up',
                'duration', 1200,
                'highlight_savings', true
            ) ELSE NULL END
    )
    SELECT 
        ct.id,
        ct.category,
        ct.name,
        ct.argus,
        ct.wfm,
        ct.advantage,
        ct.visuals
    FROM comparison_tests ct
    WHERE test_type = 'all' OR ct.category = test_type
    ORDER BY ct.category, ct.name;
END;
$$ LANGUAGE plpgsql;

-- 4. Get Performance Trend Data
CREATE OR REPLACE FUNCTION get_performance_trend(
    metric_name TEXT,
    time_period INTERVAL DEFAULT '1 hour'
)
RETURNS TABLE(
    timestamp TIMESTAMPTZ,
    wfm_value NUMERIC,
    argus_value NUMERIC,
    trend_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH time_series AS (
        SELECT 
            generate_series(
                NOW() - time_period,
                NOW(),
                INTERVAL '5 minutes'
            ) as ts
    ),
    simulated_data AS (
        SELECT 
            ts,
            CASE metric_name
                WHEN 'response_time' THEN 6 + (random() * 4)::NUMERIC(5,2)
                WHEN 'accuracy' THEN 85 + (random() * 5)::NUMERIC(5,2)
                WHEN 'throughput' THEN 900 + (random() * 200)::NUMERIC(7,2)
                ELSE 50 + (random() * 20)::NUMERIC(5,2)
            END as wfm_val,
            CASE metric_name
                WHEN 'response_time' THEN 400 + (random() * 100)::NUMERIC(5,2)
                WHEN 'accuracy' THEN 65 + (random() * 8)::NUMERIC(5,2)
                WHEN 'throughput' THEN 400 + (random() * 100)::NUMERIC(7,2)
                ELSE 30 + (random() * 15)::NUMERIC(5,2)
            END as argus_val
        FROM time_series
    )
    SELECT 
        sd.ts,
        sd.wfm_val,
        sd.argus_val,
        jsonb_build_object(
            'timestamp', EXTRACT(EPOCH FROM sd.ts) * 1000,
            'wfm_value', sd.wfm_val,
            'argus_value', sd.argus_val,
            'difference', sd.wfm_val - sd.argus_val,
            'advantage_pct', ROUND(((sd.wfm_val - sd.argus_val) / sd.argus_val) * 100, 1),
            'metric', metric_name,
            'colors', jsonb_build_object(
                'wfm', '#10b981',
                'argus', '#ef4444'
            )
        )
    FROM simulated_data sd
    ORDER BY sd.ts;
END;
$$ LANGUAGE plpgsql;

-- 5. Generate ROI Calculation
CREATE OR REPLACE FUNCTION calculate_roi_comparison(
    contact_center_size INTEGER DEFAULT 500,
    monthly_revenue NUMERIC DEFAULT 5000000
)
RETURNS TABLE(
    roi_category TEXT,
    argus_cost NUMERIC,
    wfm_cost NUMERIC,
    annual_savings NUMERIC,
    payback_months NUMERIC,
    roi_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH roi_calculations AS (
        SELECT 
            'Labor Costs' as category,
            contact_center_size * 180 * 12 as argus_annual,  -- 180 hours/month manual work
            contact_center_size * 12 * 12 as wfm_annual,     -- 12 hours/month manual work
            50.0 as hourly_rate  -- $50/hour for WFM analyst
        
        UNION ALL
        
        SELECT 
            'Accuracy Improvements',
            monthly_revenue * 0.35 * 12,  -- 35% MAPE = 35% revenue impact
            monthly_revenue * 0.15 * 12,  -- 15% MAPE = 15% revenue impact
            1.0
        
        UNION ALL
        
        SELECT 
            'Overstaffing Costs',
            monthly_revenue * 0.20 * 12,  -- 20% overstaffing
            monthly_revenue * 0.08 * 12,  -- 8% overstaffing
            1.0
        
        UNION ALL
        
        SELECT 
            'Technology Costs',
            300000,  -- Argus license + maintenance
            200000,  -- WFM Enterprise license + maintenance
            1.0
    )
    SELECT 
        rc.category,
        ROUND(rc.argus_annual * rc.hourly_rate, 0),
        ROUND(rc.wfm_annual * rc.hourly_rate, 0),
        ROUND((rc.argus_annual - rc.wfm_annual) * rc.hourly_rate, 0),
        ROUND((200000 / NULLIF((rc.argus_annual - rc.wfm_annual) * rc.hourly_rate, 0)) * 12, 1),
        jsonb_build_object(
            'category', rc.category,
            'argus_annual', ROUND(rc.argus_annual * rc.hourly_rate, 0),
            'wfm_annual', ROUND(rc.wfm_annual * rc.hourly_rate, 0),
            'savings', ROUND((rc.argus_annual - rc.wfm_annual) * rc.hourly_rate, 0),
            'savings_pct', ROUND(((rc.argus_annual - rc.wfm_annual) / rc.argus_annual) * 100, 1),
            'contact_center_size', contact_center_size,
            'monthly_revenue', monthly_revenue,
            'assumptions', jsonb_build_object(
                'hourly_rate', rc.hourly_rate,
                'argus_hours_month', rc.argus_annual / 12,
                'wfm_hours_month', rc.wfm_annual / 12
            )
        )
    FROM roi_calculations rc;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_accuracy_comparison(INTEGER) TO demo_user;
GRANT EXECUTE ON FUNCTION get_realtime_performance_metrics() TO demo_user;
GRANT EXECUTE ON FUNCTION generate_comparison_data(TEXT, BOOLEAN) TO demo_user;
GRANT EXECUTE ON FUNCTION get_performance_trend(TEXT, INTERVAL) TO demo_user;
GRANT EXECUTE ON FUNCTION calculate_roi_comparison(INTEGER, NUMERIC) TO demo_user;