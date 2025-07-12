-- =====================================================================================
-- Comparison Report Generation Framework
-- Module: Report Generation and Analytics
-- Purpose: Comprehensive comparison reports for multi-project WFM analysis
-- Features: 
--   - Visual dashboard data feeds
--   - Executive summaries
--   - Detailed accuracy reports
--   - Performance benchmarking
--   - Trend analysis
--   - Multiple export formats
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "tablefunc";
CREATE EXTENSION IF NOT EXISTS "plpython3u"; -- For advanced analytics

-- =====================================================================================
-- 1. REPORT TEMPLATE AND CONFIGURATION TABLES
-- =====================================================================================

-- Report template registry
CREATE TABLE IF NOT EXISTS report_templates (
    template_id SERIAL PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    template_name VARCHAR(200) NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- 'daily_summary', 'project_analysis', 'multi_skill', 'benchmark', 'trend'
    report_category VARCHAR(50) NOT NULL, -- 'operational', 'strategic', 'executive', 'technical'
    
    -- Template configuration
    config_json JSONB NOT NULL DEFAULT '{}',
    default_parameters JSONB DEFAULT '{}',
    
    -- Visual configuration
    chart_types TEXT[], -- ['line', 'bar', 'heatmap', 'scatter', 'gauge']
    dashboard_layout JSONB, -- Grid layout configuration
    
    -- Access control
    required_role VARCHAR(50) DEFAULT 'analyst',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by VARCHAR(100),
    description TEXT
);

-- Report execution history
CREATE TABLE IF NOT EXISTS report_execution_history (
    execution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id INTEGER REFERENCES report_templates(template_id),
    
    -- Execution details
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    execution_time_ms INTEGER,
    
    -- Parameters used
    parameters JSONB NOT NULL DEFAULT '{}',
    
    -- Results
    record_count INTEGER,
    output_format VARCHAR(20), -- 'json', 'csv', 'excel', 'pdf'
    output_location TEXT,
    report_data JSONB, -- Cached report data for quick retrieval
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed', 'cancelled'
    error_message TEXT,
    
    -- User info
    requested_by VARCHAR(100),
    ip_address INET
);

-- Report subscriptions for automated delivery
CREATE TABLE IF NOT EXISTS report_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES report_templates(template_id),
    
    -- Schedule
    schedule_type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'custom'
    schedule_cron VARCHAR(100), -- Cron expression for custom schedules
    next_run_time TIMESTAMPTZ,
    last_run_time TIMESTAMPTZ,
    
    -- Delivery configuration
    delivery_method VARCHAR(20) NOT NULL, -- 'email', 'sftp', 'api', 'dashboard'
    delivery_config JSONB NOT NULL, -- Email addresses, SFTP details, etc.
    output_formats TEXT[] DEFAULT '{json,csv}',
    
    -- Subscription details
    subscriber_email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================================
-- 2. COMPARISON METRICS AND CALCULATION TABLES
-- =====================================================================================

-- Comparison metrics catalog
CREATE TABLE IF NOT EXISTS comparison_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_code VARCHAR(50) UNIQUE NOT NULL,
    metric_name VARCHAR(200) NOT NULL,
    metric_category VARCHAR(50) NOT NULL, -- 'volume', 'performance', 'quality', 'efficiency'
    
    -- Calculation details
    calculation_sql TEXT NOT NULL,
    aggregation_type VARCHAR(20) DEFAULT 'sum', -- 'sum', 'avg', 'max', 'min', 'percentile'
    
    -- Thresholds for status determination
    threshold_excellent DECIMAL,
    threshold_good DECIMAL,
    threshold_warning DECIMAL,
    threshold_critical DECIMAL,
    
    -- Display configuration
    display_format VARCHAR(20) DEFAULT 'number', -- 'number', 'percentage', 'time', 'currency'
    decimal_places INTEGER DEFAULT 2,
    unit_label VARCHAR(20), -- 'calls', 'seconds', '%', etc.
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pre-calculated comparison results cache
CREATE TABLE IF NOT EXISTS comparison_results_cache (
    cache_id BIGSERIAL PRIMARY KEY,
    cache_key VARCHAR(255) UNIQUE NOT NULL,
    
    -- Comparison parameters
    comparison_type VARCHAR(50) NOT NULL,
    project_codes TEXT[],
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    interval_type VARCHAR(10), -- '15m', '30m', '1h', 'daily'
    
    -- Cached results
    result_data JSONB NOT NULL,
    summary_stats JSONB,
    
    -- Cache management
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    hit_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for cache lookup
CREATE INDEX idx_comparison_cache_key ON comparison_results_cache(cache_key);
CREATE INDEX idx_comparison_cache_expiry ON comparison_results_cache(expires_at) WHERE expires_at IS NOT NULL;

-- =====================================================================================
-- 3. REPORT GENERATION PROCEDURES
-- =====================================================================================

-- Main report generation orchestrator
CREATE OR REPLACE FUNCTION generate_comparison_report(
    p_template_code VARCHAR,
    p_parameters JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_execution_id UUID;
    v_template_id INTEGER;
    v_template_config JSONB;
    v_report_data JSONB;
    v_start_time TIMESTAMPTZ;
BEGIN
    v_start_time := clock_timestamp();
    v_execution_id := uuid_generate_v4();
    
    -- Get template configuration
    SELECT template_id, config_json
    INTO v_template_id, v_template_config
    FROM report_templates
    WHERE template_code = p_template_code
    AND is_active = TRUE;
    
    IF v_template_id IS NULL THEN
        RAISE EXCEPTION 'Report template % not found or inactive', p_template_code;
    END IF;
    
    -- Create execution record
    INSERT INTO report_execution_history (
        execution_id, template_id, parameters, 
        status, started_at, requested_by
    )
    VALUES (
        v_execution_id, v_template_id, p_parameters,
        'running', NOW(), current_user
    );
    
    -- Generate report based on template type
    CASE p_template_code
        WHEN 'DAILY_COMPARISON' THEN
            v_report_data := generate_daily_comparison_report(p_parameters);
        WHEN 'PROJECT_ANALYSIS' THEN
            v_report_data := generate_project_analysis_report(p_parameters);
        WHEN 'MULTI_SKILL_ACCURACY' THEN
            v_report_data := generate_multi_skill_accuracy_report(p_parameters);
        WHEN 'PERFORMANCE_BENCHMARK' THEN
            v_report_data := generate_performance_benchmark_report(p_parameters);
        WHEN 'FAILURE_PATTERN' THEN
            v_report_data := generate_failure_pattern_report(p_parameters);
        WHEN 'TREND_ANALYSIS' THEN
            v_report_data := generate_trend_analysis_report(p_parameters);
        WHEN 'QUEUE_COMPARISON' THEN
            v_report_data := generate_queue_comparison_report(p_parameters);
        ELSE
            RAISE EXCEPTION 'Unknown report template: %', p_template_code;
    END CASE;
    
    -- Update execution record with results
    UPDATE report_execution_history
    SET 
        completed_at = NOW(),
        execution_time_ms = EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER,
        status = 'completed',
        report_data = v_report_data,
        record_count = (v_report_data->>'total_records')::INTEGER
    WHERE execution_id = v_execution_id;
    
    RETURN v_execution_id;
    
EXCEPTION WHEN OTHERS THEN
    -- Log error and update status
    UPDATE report_execution_history
    SET 
        status = 'failed',
        error_message = SQLERRM,
        completed_at = NOW()
    WHERE execution_id = v_execution_id;
    
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. DAILY COMPARISON SUMMARY REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_daily_comparison_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date DATE;
    v_projects TEXT[];
    v_result JSONB;
    v_summary JSONB;
    v_details JSONB[];
BEGIN
    -- Extract parameters
    v_date := COALESCE((p_parameters->>'date')::DATE, CURRENT_DATE - 1);
    v_projects := COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(p_parameters->'projects')),
        ARRAY['B', 'F', 'I', 'VTM'] -- Default to all projects
    );
    
    -- Generate summary metrics
    WITH daily_metrics AS (
        SELECT 
            p.project_code,
            p.project_name,
            COUNT(DISTINCT pq.queue_id) as queue_count,
            -- Aggregate metrics from staging tables
            COALESCE(SUM(ps.cdo), 0) as total_calls_offered,
            COALESCE(SUM(ps.hc), 0) as total_calls_handled,
            COALESCE(SUM(ps.ac), 0) as total_calls_abandoned,
            COALESCE(AVG(ps.sl), 0) as avg_service_level,
            COALESCE(AVG(ps.aht), 0) as avg_handle_time,
            COALESCE(AVG(ps.awt_hc), 0) as avg_wait_time,
            COALESCE(SUM(ps.tt) / 3600.0, 0) as total_talk_hours,
            -- Calculated KPIs
            CASE 
                WHEN SUM(ps.cdo) > 0 
                THEN (SUM(ps.ac)::DECIMAL / SUM(ps.cdo) * 100)
                ELSE 0 
            END as abandonment_rate,
            -- Queue distribution
            jsonb_object_agg(
                pq.queue_code,
                jsonb_build_object(
                    'calls_offered', COALESCE(ps.cdo, 0),
                    'service_level', COALESCE(ps.sl, 0),
                    'avg_handle_time', COALESCE(ps.aht, 0)
                )
            ) as queue_details
        FROM projects p
        INNER JOIN project_queues pq ON p.project_id = pq.project_id
        LEFT JOIN LATERAL (
            -- Join with appropriate staging table based on project
            SELECT * FROM get_project_staging_data(p.project_code, v_date)
        ) ps ON TRUE
        WHERE p.project_code = ANY(v_projects)
        GROUP BY p.project_code, p.project_name
    ),
    comparison_summary AS (
        SELECT 
            jsonb_build_object(
                'report_date', v_date,
                'total_projects', COUNT(DISTINCT project_code),
                'total_queues', SUM(queue_count),
                'total_calls', SUM(total_calls_offered),
                'avg_service_level', AVG(avg_service_level),
                'best_performer', (
                    SELECT project_name 
                    FROM daily_metrics 
                    ORDER BY avg_service_level DESC 
                    LIMIT 1
                ),
                'highest_volume', (
                    SELECT project_name 
                    FROM daily_metrics 
                    ORDER BY total_calls_offered DESC 
                    LIMIT 1
                )
            ) as summary
        FROM daily_metrics
    )
    SELECT 
        jsonb_build_object(
            'report_type', 'daily_comparison',
            'generated_at', NOW(),
            'parameters', p_parameters,
            'summary', (SELECT summary FROM comparison_summary),
            'projects', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'project_code', project_code,
                        'project_name', project_name,
                        'metrics', jsonb_build_object(
                            'queue_count', queue_count,
                            'total_calls_offered', total_calls_offered,
                            'total_calls_handled', total_calls_handled,
                            'total_calls_abandoned', total_calls_abandoned,
                            'service_level', ROUND(avg_service_level::NUMERIC, 2),
                            'avg_handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                            'avg_wait_time', ROUND(avg_wait_time::NUMERIC, 1),
                            'abandonment_rate', ROUND(abandonment_rate::NUMERIC, 2),
                            'talk_hours', ROUND(total_talk_hours::NUMERIC, 2)
                        ),
                        'queue_performance', queue_details,
                        'status', CASE
                            WHEN avg_service_level >= 90 THEN 'excellent'
                            WHEN avg_service_level >= 80 THEN 'good'
                            WHEN avg_service_level >= 70 THEN 'warning'
                            ELSE 'critical'
                        END
                    )
                )
                FROM daily_metrics
            ),
            'total_records', (SELECT COUNT(*) FROM daily_metrics)
        ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. PROJECT-SPECIFIC ANALYSIS REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_project_analysis_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_project_code VARCHAR;
    v_date_from DATE;
    v_date_to DATE;
    v_interval VARCHAR;
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_project_code := p_parameters->>'project_code';
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 7);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_interval := COALESCE(p_parameters->>'interval', '1h');
    
    -- Generate detailed project analysis
    WITH project_timeline AS (
        SELECT 
            date_trunc('day', ps.period_timestamp) as analysis_date,
            EXTRACT(HOUR FROM ps.period_timestamp) as hour,
            -- Hourly aggregates
            SUM(ps.cdo) as calls_offered,
            SUM(ps.hc) as calls_handled,
            AVG(ps.sl) as service_level,
            AVG(ps.aht) as avg_handle_time,
            AVG(ps.awt_hc) as avg_wait_time,
            -- Peak identification
            MAX(ps.cdo) as peak_calls,
            -- Efficiency metrics
            SUM(ps.tt) / NULLIF(SUM(ps.hc), 0) as actual_talk_time,
            SUM(ps.acw) / NULLIF(SUM(ps.hc), 0) as actual_wrap_time
        FROM get_project_staging_data(v_project_code, v_date_from, v_date_to) ps
        GROUP BY date_trunc('day', ps.period_timestamp), EXTRACT(HOUR FROM ps.period_timestamp)
    ),
    daily_patterns AS (
        SELECT 
            analysis_date,
            jsonb_agg(
                jsonb_build_object(
                    'hour', hour,
                    'calls', calls_offered,
                    'service_level', ROUND(service_level::NUMERIC, 2),
                    'aht', ROUND(avg_handle_time::NUMERIC, 0)
                ) ORDER BY hour
            ) as hourly_data,
            -- Daily statistics
            SUM(calls_offered) as daily_volume,
            AVG(service_level) as daily_sl,
            MAX(peak_calls) as daily_peak
        FROM project_timeline
        GROUP BY analysis_date
    ),
    queue_performance AS (
        SELECT 
            pq.queue_code,
            pq.queue_name,
            COUNT(DISTINCT DATE(ps.period_timestamp)) as active_days,
            AVG(ps.sl) as avg_service_level,
            AVG(ps.aht) as avg_handle_time,
            SUM(ps.cdo) as total_volume,
            -- Performance variability
            STDDEV(ps.sl) as sl_variance,
            PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ps.aht) as p90_handle_time
        FROM project_queues pq
        LEFT JOIN get_project_staging_data(v_project_code, v_date_from, v_date_to) ps 
            ON pq.queue_id = ps.queue_id
        WHERE pq.project_id = (SELECT project_id FROM projects WHERE project_code = v_project_code)
        GROUP BY pq.queue_code, pq.queue_name
    )
    SELECT jsonb_build_object(
        'report_type', 'project_analysis',
        'project_code', v_project_code,
        'analysis_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to,
            'days', v_date_to - v_date_from + 1
        ),
        'summary', jsonb_build_object(
            'total_calls', (SELECT SUM(daily_volume) FROM daily_patterns),
            'avg_daily_volume', (SELECT AVG(daily_volume) FROM daily_patterns),
            'avg_service_level', (SELECT AVG(daily_sl) FROM daily_patterns),
            'peak_hour_calls', (SELECT MAX(daily_peak) FROM daily_patterns),
            'total_queues', (SELECT COUNT(*) FROM queue_performance)
        ),
        'daily_trends', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'date', analysis_date,
                    'volume', daily_volume,
                    'service_level', ROUND(daily_sl::NUMERIC, 2),
                    'peak_calls', daily_peak,
                    'hourly_pattern', hourly_data
                ) ORDER BY analysis_date
            ) FROM daily_patterns
        ),
        'queue_analysis', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'queue_code', queue_code,
                    'queue_name', queue_name,
                    'metrics', jsonb_build_object(
                        'active_days', active_days,
                        'total_volume', total_volume,
                        'avg_service_level', ROUND(avg_service_level::NUMERIC, 2),
                        'avg_handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                        'sl_consistency', ROUND((100 - sl_variance)::NUMERIC, 2),
                        'p90_handle_time', ROUND(p90_handle_time::NUMERIC, 0)
                    )
                ) ORDER BY total_volume DESC
            ) FROM queue_performance
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. MULTI-SKILL ACCURACY REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_multi_skill_accuracy_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date_from DATE;
    v_date_to DATE;
    v_projects TEXT[];
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 30);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_projects := COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(p_parameters->'projects')),
        ARRAY['B', 'F', 'I', 'VTM']
    );
    
    -- Analyze multi-skill routing accuracy
    WITH skill_performance AS (
        SELECT 
            p.project_code,
            s.skill_code,
            s.skill_name,
            s.skill_category,
            -- Calculate skill-based metrics
            COUNT(DISTINCT sr.queue_id) as queues_requiring_skill,
            COUNT(DISTINCT aa.agent_id) as agents_with_skill,
            -- Performance by skill
            AVG(ps.sl) as avg_service_level,
            AVG(ps.aht) as avg_handle_time,
            SUM(ps.hc) as calls_handled_with_skill,
            -- Skill utilization
            CASE 
                WHEN COUNT(DISTINCT aa.agent_id) > 0 
                THEN SUM(aa.skill_time) / (COUNT(DISTINCT aa.agent_id) * (v_date_to - v_date_from + 1) * 8 * 3600) * 100
                ELSE 0 
            END as skill_utilization_rate
        FROM projects p
        INNER JOIN skill_requirements sr ON p.project_id = sr.project_id
        INNER JOIN skills s ON sr.skill_id = s.skill_id
        LEFT JOIN agent_assignments aa ON sr.skill_id = aa.skill_id
        LEFT JOIN get_project_staging_data(p.project_code, v_date_from, v_date_to) ps ON TRUE
        WHERE p.project_code = ANY(v_projects)
        AND s.is_active = TRUE
        GROUP BY p.project_code, s.skill_code, s.skill_name, s.skill_category
    ),
    skill_coverage AS (
        SELECT 
            project_code,
            skill_category,
            COUNT(DISTINCT skill_code) as skills_in_category,
            AVG(agents_with_skill) as avg_agents_per_skill,
            AVG(skill_utilization_rate) as avg_utilization,
            -- Coverage analysis
            COUNT(DISTINCT skill_code) FILTER (WHERE agents_with_skill >= queues_requiring_skill) as fully_covered,
            COUNT(DISTINCT skill_code) FILTER (WHERE agents_with_skill < queues_requiring_skill * 0.8) as under_covered
        FROM skill_performance
        GROUP BY project_code, skill_category
    ),
    routing_accuracy AS (
        SELECT 
            sp.project_code,
            -- Overall accuracy metrics
            AVG(CASE 
                WHEN sp.agents_with_skill >= sp.queues_requiring_skill THEN 100.0
                ELSE (sp.agents_with_skill::DECIMAL / NULLIF(sp.queues_requiring_skill, 0) * 100)
            END) as skill_coverage_accuracy,
            -- Performance correlation
            CORR(sp.agents_with_skill, sp.avg_service_level) as skill_sl_correlation,
            CORR(sp.skill_utilization_rate, sp.avg_handle_time) as utilization_aht_correlation
        FROM skill_performance sp
        GROUP BY sp.project_code
    )
    SELECT jsonb_build_object(
        'report_type', 'multi_skill_accuracy',
        'analysis_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to
        ),
        'summary', jsonb_build_object(
            'total_skills_analyzed', (SELECT COUNT(DISTINCT skill_code) FROM skill_performance),
            'total_projects', (SELECT COUNT(DISTINCT project_code) FROM skill_performance),
            'avg_coverage_accuracy', (SELECT AVG(skill_coverage_accuracy) FROM routing_accuracy),
            'critical_skills', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'skill', skill_name,
                        'project', project_code,
                        'coverage_ratio', ROUND((agents_with_skill::DECIMAL / NULLIF(queues_requiring_skill, 0))::NUMERIC, 2)
                    )
                ) 
                FROM skill_performance 
                WHERE agents_with_skill < queues_requiring_skill * 0.5
                LIMIT 10
            )
        ),
        'project_skill_analysis', (
            SELECT jsonb_object_agg(
                project_code,
                jsonb_build_object(
                    'skill_categories', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'category', skill_category,
                                'total_skills', skills_in_category,
                                'avg_agents', ROUND(avg_agents_per_skill::NUMERIC, 1),
                                'utilization', ROUND(avg_utilization::NUMERIC, 2),
                                'coverage_status', jsonb_build_object(
                                    'fully_covered', fully_covered,
                                    'under_covered', under_covered
                                )
                            )
                        )
                        FROM skill_coverage sc
                        WHERE sc.project_code = ra.project_code
                    ),
                    'accuracy_metrics', jsonb_build_object(
                        'coverage_accuracy', ROUND(skill_coverage_accuracy::NUMERIC, 2),
                        'skill_sl_correlation', ROUND(skill_sl_correlation::NUMERIC, 3),
                        'utilization_aht_correlation', ROUND(utilization_aht_correlation::NUMERIC, 3)
                    )
                )
            )
            FROM routing_accuracy ra
        ),
        'skill_details', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'project', project_code,
                    'skill_code', skill_code,
                    'skill_name', skill_name,
                    'category', skill_category,
                    'metrics', jsonb_build_object(
                        'queues_requiring', queues_requiring_skill,
                        'agents_available', agents_with_skill,
                        'calls_handled', calls_handled_with_skill,
                        'avg_service_level', ROUND(avg_service_level::NUMERIC, 2),
                        'avg_handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                        'utilization_rate', ROUND(skill_utilization_rate::NUMERIC, 2)
                    ),
                    'status', CASE
                        WHEN agents_with_skill >= queues_requiring_skill THEN 'optimal'
                        WHEN agents_with_skill >= queues_requiring_skill * 0.8 THEN 'adequate'
                        WHEN agents_with_skill >= queues_requiring_skill * 0.5 THEN 'warning'
                        ELSE 'critical'
                    END
                )
                ORDER BY calls_handled_with_skill DESC
            )
            FROM skill_performance
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. PERFORMANCE BENCHMARK REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_performance_benchmark_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date_from DATE;
    v_date_to DATE;
    v_benchmark_type VARCHAR;
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 90);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_benchmark_type := COALESCE(p_parameters->>'benchmark_type', 'industry');
    
    -- Generate comprehensive benchmarks
    WITH project_metrics AS (
        SELECT 
            p.project_code,
            p.project_name,
            p.project_type,
            -- Volume metrics
            SUM(ps.cdo) as total_calls,
            AVG(ps.cdo) as avg_interval_calls,
            MAX(ps.cdo) as peak_interval_calls,
            -- Performance metrics
            AVG(ps.sl) as avg_service_level,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ps.sl) as median_service_level,
            PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ps.sl) as p90_service_level,
            -- Efficiency metrics
            AVG(ps.aht) as avg_handle_time,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ps.aht) as median_handle_time,
            AVG(ps.awt_hc) as avg_wait_time,
            AVG(ps.lcr) as avg_abandon_rate,
            -- Productivity
            SUM(ps.hc) / NULLIF(COUNT(DISTINCT DATE(ps.period_timestamp)), 0) as calls_per_day,
            SUM(ps.tt) / NULLIF(SUM(ps.hc), 0) as avg_talk_time,
            -- Variability
            STDDEV(ps.sl) as sl_variance,
            STDDEV(ps.aht) as aht_variance
        FROM projects p
        LEFT JOIN get_all_project_staging_data(v_date_from, v_date_to) ps ON p.project_id = ps.project_id
        GROUP BY p.project_code, p.project_name, p.project_type
    ),
    industry_benchmarks AS (
        SELECT 
            project_type,
            -- Calculate industry averages by project type
            AVG(avg_service_level) as industry_avg_sl,
            AVG(avg_handle_time) as industry_avg_aht,
            AVG(avg_abandon_rate) as industry_avg_abandon,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_service_level) as industry_top_quartile_sl,
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_handle_time) as industry_top_quartile_aht
        FROM project_metrics
        GROUP BY project_type
    ),
    benchmark_comparison AS (
        SELECT 
            pm.*,
            ib.industry_avg_sl,
            ib.industry_avg_aht,
            -- Performance indices (100 = industry average)
            (pm.avg_service_level / NULLIF(ib.industry_avg_sl, 0) * 100) as sl_index,
            (ib.industry_avg_aht / NULLIF(pm.avg_handle_time, 0) * 100) as aht_index,
            (ib.industry_avg_abandon / NULLIF(pm.avg_abandon_rate, 0) * 100) as abandon_index,
            -- Ranking
            RANK() OVER (ORDER BY pm.avg_service_level DESC) as sl_rank,
            RANK() OVER (ORDER BY pm.avg_handle_time ASC) as aht_rank,
            RANK() OVER (ORDER BY pm.total_calls DESC) as volume_rank
        FROM project_metrics pm
        LEFT JOIN industry_benchmarks ib ON pm.project_type = ib.project_type
    )
    SELECT jsonb_build_object(
        'report_type', 'performance_benchmark',
        'benchmark_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to,
            'days', v_date_to - v_date_from + 1
        ),
        'summary', jsonb_build_object(
            'projects_benchmarked', (SELECT COUNT(*) FROM project_metrics),
            'best_service_level', jsonb_build_object(
                'project', (SELECT project_name FROM benchmark_comparison ORDER BY avg_service_level DESC LIMIT 1),
                'value', (SELECT ROUND(avg_service_level::NUMERIC, 2) FROM benchmark_comparison ORDER BY avg_service_level DESC LIMIT 1)
            ),
            'best_efficiency', jsonb_build_object(
                'project', (SELECT project_name FROM benchmark_comparison ORDER BY avg_handle_time ASC LIMIT 1),
                'value', (SELECT ROUND(avg_handle_time::NUMERIC, 0) FROM benchmark_comparison ORDER BY avg_handle_time ASC LIMIT 1)
            ),
            'highest_volume', jsonb_build_object(
                'project', (SELECT project_name FROM benchmark_comparison ORDER BY total_calls DESC LIMIT 1),
                'value', (SELECT total_calls FROM benchmark_comparison ORDER BY total_calls DESC LIMIT 1)
            )
        ),
        'benchmarks', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'project_code', project_code,
                    'project_name', project_name,
                    'project_type', project_type,
                    'metrics', jsonb_build_object(
                        'total_calls', total_calls,
                        'avg_service_level', ROUND(avg_service_level::NUMERIC, 2),
                        'median_service_level', ROUND(median_service_level::NUMERIC, 2),
                        'p90_service_level', ROUND(p90_service_level::NUMERIC, 2),
                        'avg_handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                        'median_handle_time', ROUND(median_handle_time::NUMERIC, 0),
                        'avg_wait_time', ROUND(avg_wait_time::NUMERIC, 1),
                        'abandon_rate', ROUND(avg_abandon_rate::NUMERIC, 2),
                        'calls_per_day', ROUND(calls_per_day::NUMERIC, 0)
                    ),
                    'performance_indices', jsonb_build_object(
                        'service_level_index', ROUND(sl_index::NUMERIC, 1),
                        'efficiency_index', ROUND(aht_index::NUMERIC, 1),
                        'abandon_index', ROUND(abandon_index::NUMERIC, 1)
                    ),
                    'rankings', jsonb_build_object(
                        'service_level_rank', sl_rank,
                        'efficiency_rank', aht_rank,
                        'volume_rank', volume_rank
                    ),
                    'variability', jsonb_build_object(
                        'sl_consistency', ROUND((100 - sl_variance)::NUMERIC, 2),
                        'aht_consistency', ROUND((100 - aht_variance)::NUMERIC, 2)
                    )
                )
                ORDER BY sl_rank
            )
            FROM benchmark_comparison
        ),
        'industry_averages', (
            SELECT jsonb_object_agg(
                project_type,
                jsonb_build_object(
                    'avg_service_level', ROUND(industry_avg_sl::NUMERIC, 2),
                    'avg_handle_time', ROUND(industry_avg_aht::NUMERIC, 0),
                    'avg_abandon_rate', ROUND(industry_avg_abandon::NUMERIC, 2),
                    'top_quartile_sl', ROUND(industry_top_quartile_sl::NUMERIC, 2),
                    'top_quartile_aht', ROUND(industry_top_quartile_aht::NUMERIC, 0)
                )
            )
            FROM industry_benchmarks
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 8. FAILURE PATTERN ANALYSIS REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_failure_pattern_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date_from DATE;
    v_date_to DATE;
    v_threshold_sl DECIMAL;
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 30);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_threshold_sl := COALESCE((p_parameters->>'threshold_sl')::DECIMAL, 80.0);
    
    -- Analyze failure patterns
    WITH failure_events AS (
        SELECT 
            p.project_code,
            pq.queue_code,
            ps.period_timestamp,
            EXTRACT(DOW FROM ps.period_timestamp) as day_of_week,
            EXTRACT(HOUR FROM ps.period_timestamp) as hour_of_day,
            ps.sl as service_level,
            ps.lcr as abandon_rate,
            ps.awt_hc as wait_time,
            ps.cdo as call_volume,
            -- Identify failure types
            CASE 
                WHEN ps.sl < v_threshold_sl THEN 'sl_failure'
                WHEN ps.lcr > 10 THEN 'abandon_failure'
                WHEN ps.awt_hc > 300 THEN 'wait_failure'
                ELSE 'normal'
            END as failure_type,
            -- Context for pattern analysis
            LAG(ps.sl) OVER (PARTITION BY pq.queue_id ORDER BY ps.period_timestamp) as prev_sl,
            LEAD(ps.sl) OVER (PARTITION BY pq.queue_id ORDER BY ps.period_timestamp) as next_sl
        FROM projects p
        INNER JOIN project_queues pq ON p.project_id = pq.project_id
        INNER JOIN get_all_project_staging_data(v_date_from, v_date_to) ps ON pq.queue_id = ps.queue_id
    ),
    failure_patterns AS (
        SELECT 
            project_code,
            failure_type,
            COUNT(*) as occurrence_count,
            -- Temporal patterns
            MODE() WITHIN GROUP (ORDER BY day_of_week) as most_common_day,
            MODE() WITHIN GROUP (ORDER BY hour_of_day) as most_common_hour,
            -- Severity metrics
            AVG(v_threshold_sl - service_level) as avg_sl_gap,
            MAX(abandon_rate) as max_abandon_rate,
            MAX(wait_time) as max_wait_time,
            -- Pattern characteristics
            AVG(call_volume) as avg_volume_during_failure,
            STDDEV(service_level) as sl_volatility,
            -- Recovery analysis
            AVG(next_sl - service_level) as avg_recovery_improvement
        FROM failure_events
        WHERE failure_type != 'normal'
        GROUP BY project_code, failure_type
    ),
    root_cause_analysis AS (
        SELECT 
            fe.project_code,
            fe.queue_code,
            fe.failure_type,
            -- Volume spike detection
            CASE 
                WHEN fe.call_volume > AVG(fe.call_volume) OVER (PARTITION BY fe.queue_code) * 1.5 
                THEN 'volume_spike'
                ELSE NULL
            END as volume_factor,
            -- Sequential failure detection
            CASE 
                WHEN fe.prev_sl < v_threshold_sl AND fe.service_level < v_threshold_sl 
                THEN 'cascading_failure'
                ELSE NULL
            END as cascade_factor,
            -- Time-based patterns
            CASE 
                WHEN fe.hour_of_day BETWEEN 11 AND 14 THEN 'lunch_hours'
                WHEN fe.hour_of_day BETWEEN 8 AND 10 THEN 'morning_peak'
                WHEN fe.hour_of_day BETWEEN 16 AND 18 THEN 'evening_peak'
                ELSE 'off_peak'
            END as time_factor
        FROM failure_events fe
        WHERE fe.failure_type != 'normal'
    ),
    mitigation_recommendations AS (
        SELECT 
            project_code,
            jsonb_agg(DISTINCT
                CASE 
                    WHEN occurrence_count > 100 AND most_common_hour BETWEEN 11 AND 14 
                    THEN 'Implement staggered lunch schedules'
                    WHEN avg_volume_during_failure > 1000 
                    THEN 'Increase staffing during high-volume periods'
                    WHEN sl_volatility > 20 
                    THEN 'Implement real-time monitoring and alerting'
                    WHEN max_abandon_rate > 15 
                    THEN 'Review and optimize IVR messaging and queue priorities'
                    WHEN max_wait_time > 600 
                    THEN 'Consider callback options for long wait times'
                    ELSE 'Review staffing and skill allocation'
                END
            ) as recommendations
        FROM failure_patterns
        GROUP BY project_code
    )
    SELECT jsonb_build_object(
        'report_type', 'failure_pattern_analysis',
        'analysis_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to,
            'threshold_sl', v_threshold_sl
        ),
        'summary', jsonb_build_object(
            'total_failures', (SELECT COUNT(*) FROM failure_events WHERE failure_type != 'normal'),
            'affected_projects', (SELECT COUNT(DISTINCT project_code) FROM failure_patterns),
            'most_common_failure', (
                SELECT failure_type 
                FROM failure_patterns 
                GROUP BY failure_type 
                ORDER BY SUM(occurrence_count) DESC 
                LIMIT 1
            ),
            'critical_time_periods', (
                SELECT jsonb_agg(DISTINCT
                    jsonb_build_object(
                        'hour', most_common_hour,
                        'day', CASE most_common_day
                            WHEN 0 THEN 'Sunday'
                            WHEN 1 THEN 'Monday'
                            WHEN 2 THEN 'Tuesday'
                            WHEN 3 THEN 'Wednesday'
                            WHEN 4 THEN 'Thursday'
                            WHEN 5 THEN 'Friday'
                            WHEN 6 THEN 'Saturday'
                        END
                    )
                )
                FROM failure_patterns
                WHERE occurrence_count > 50
            )
        ),
        'failure_patterns', (
            SELECT jsonb_object_agg(
                project_code,
                jsonb_build_object(
                    'failure_breakdown', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'type', failure_type,
                                'occurrences', occurrence_count,
                                'avg_severity', ROUND(avg_sl_gap::NUMERIC, 2),
                                'peak_time', most_common_hour || ':00',
                                'peak_day', CASE most_common_day
                                    WHEN 0 THEN 'Sunday'
                                    WHEN 1 THEN 'Monday'
                                    WHEN 2 THEN 'Tuesday'
                                    WHEN 3 THEN 'Wednesday'
                                    WHEN 4 THEN 'Thursday'
                                    WHEN 5 THEN 'Friday'
                                    WHEN 6 THEN 'Saturday'
                                END,
                                'characteristics', jsonb_build_object(
                                    'avg_volume', ROUND(avg_volume_during_failure::NUMERIC, 0),
                                    'sl_volatility', ROUND(sl_volatility::NUMERIC, 2),
                                    'recovery_rate', ROUND(avg_recovery_improvement::NUMERIC, 2)
                                )
                            )
                        )
                        FROM failure_patterns fp
                        WHERE fp.project_code = p.project_code
                    ),
                    'root_causes', (
                        SELECT jsonb_build_object(
                            'volume_spikes', COUNT(*) FILTER (WHERE volume_factor = 'volume_spike'),
                            'cascading_failures', COUNT(*) FILTER (WHERE cascade_factor = 'cascading_failure'),
                            'time_based', jsonb_object_agg(
                                time_factor,
                                count_by_time
                            )
                        )
                        FROM (
                            SELECT 
                                time_factor,
                                COUNT(*) as count_by_time
                            FROM root_cause_analysis rca
                            WHERE rca.project_code = p.project_code
                            GROUP BY time_factor
                        ) time_analysis
                    ),
                    'recommendations', (
                        SELECT recommendations 
                        FROM mitigation_recommendations mr
                        WHERE mr.project_code = p.project_code
                    )
                )
            )
            FROM (SELECT DISTINCT project_code FROM failure_patterns) p
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. TREND ANALYSIS REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_trend_analysis_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date_from DATE;
    v_date_to DATE;
    v_trend_interval VARCHAR;
    v_projects TEXT[];
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 90);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_trend_interval := COALESCE(p_parameters->>'trend_interval', 'weekly');
    v_projects := COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(p_parameters->'projects')),
        ARRAY['B', 'F', 'I', 'VTM']
    );
    
    -- Generate trend analysis
    WITH time_series_data AS (
        SELECT 
            p.project_code,
            DATE_TRUNC(v_trend_interval, ps.period_timestamp) as trend_period,
            -- Aggregate metrics
            SUM(ps.cdo) as total_calls,
            AVG(ps.sl) as avg_service_level,
            AVG(ps.aht) as avg_handle_time,
            AVG(ps.awt_hc) as avg_wait_time,
            AVG(ps.lcr) as avg_abandon_rate,
            -- Efficiency metrics
            SUM(ps.hc) / NULLIF(SUM(ps.cdo), 0) * 100 as answer_rate,
            SUM(ps.tt) / NULLIF(SUM(ps.hc), 0) as productivity_rate
        FROM projects p
        INNER JOIN get_all_project_staging_data(v_date_from, v_date_to) ps ON p.project_id = ps.project_id
        WHERE p.project_code = ANY(v_projects)
        GROUP BY p.project_code, DATE_TRUNC(v_trend_interval, ps.period_timestamp)
    ),
    trend_calculations AS (
        SELECT 
            project_code,
            trend_period,
            total_calls,
            avg_service_level,
            avg_handle_time,
            -- Calculate moving averages
            AVG(avg_service_level) OVER (
                PARTITION BY project_code 
                ORDER BY trend_period 
                ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
            ) as sl_moving_avg,
            -- Calculate trend direction
            avg_service_level - LAG(avg_service_level) OVER (
                PARTITION BY project_code ORDER BY trend_period
            ) as sl_change,
            -- Calculate growth rates
            (total_calls - LAG(total_calls) OVER (
                PARTITION BY project_code ORDER BY trend_period
            )) / NULLIF(LAG(total_calls) OVER (
                PARTITION BY project_code ORDER BY trend_period
            ), 0) * 100 as volume_growth_rate,
            -- Rank periods by performance
            RANK() OVER (
                PARTITION BY project_code ORDER BY avg_service_level DESC
            ) as sl_rank
        FROM time_series_data
    ),
    trend_summary AS (
        SELECT 
            project_code,
            -- Overall trends
            CASE 
                WHEN AVG(sl_change) > 1 THEN 'improving'
                WHEN AVG(sl_change) < -1 THEN 'declining'
                ELSE 'stable'
            END as sl_trend,
            AVG(volume_growth_rate) as avg_volume_growth,
            -- Volatility
            STDDEV(avg_service_level) as sl_volatility,
            -- Best and worst periods
            MAX(avg_service_level) as peak_service_level,
            MIN(avg_service_level) as lowest_service_level,
            -- Correlation analysis
            CORR(total_calls, avg_service_level) as volume_sl_correlation,
            CORR(avg_handle_time, avg_service_level) as aht_sl_correlation
        FROM trend_calculations
        GROUP BY project_code
    ),
    forecast_data AS (
        -- Simple linear regression for basic forecasting
        SELECT 
            project_code,
            -- Calculate slope and intercept for SL forecast
            REGR_SLOPE(avg_service_level, EXTRACT(EPOCH FROM trend_period)) as sl_slope,
            REGR_INTERCEPT(avg_service_level, EXTRACT(EPOCH FROM trend_period)) as sl_intercept,
            -- Calculate slope for volume forecast
            REGR_SLOPE(total_calls, EXTRACT(EPOCH FROM trend_period)) as volume_slope,
            REGR_INTERCEPT(total_calls, EXTRACT(EPOCH FROM trend_period)) as volume_intercept
        FROM trend_calculations
        GROUP BY project_code
    )
    SELECT jsonb_build_object(
        'report_type', 'trend_analysis',
        'analysis_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to,
            'interval', v_trend_interval
        ),
        'summary', jsonb_build_object(
            'projects_analyzed', (SELECT COUNT(DISTINCT project_code) FROM trend_summary),
            'improving_projects', (
                SELECT jsonb_agg(project_code) 
                FROM trend_summary 
                WHERE sl_trend = 'improving'
            ),
            'declining_projects', (
                SELECT jsonb_agg(project_code) 
                FROM trend_summary 
                WHERE sl_trend = 'declining'
            ),
            'highest_growth', (
                SELECT jsonb_build_object(
                    'project', project_code,
                    'growth_rate', ROUND(avg_volume_growth::NUMERIC, 2)
                )
                FROM trend_summary
                ORDER BY avg_volume_growth DESC NULLS LAST
                LIMIT 1
            )
        ),
        'project_trends', (
            SELECT jsonb_object_agg(
                ts.project_code,
                jsonb_build_object(
                    'trend_direction', sl_trend,
                    'metrics', jsonb_build_object(
                        'avg_volume_growth', ROUND(avg_volume_growth::NUMERIC, 2),
                        'sl_volatility', ROUND(sl_volatility::NUMERIC, 2),
                        'peak_sl', ROUND(peak_service_level::NUMERIC, 2),
                        'lowest_sl', ROUND(lowest_service_level::NUMERIC, 2),
                        'sl_range', ROUND((peak_service_level - lowest_service_level)::NUMERIC, 2)
                    ),
                    'correlations', jsonb_build_object(
                        'volume_impact_on_sl', ROUND(volume_sl_correlation::NUMERIC, 3),
                        'aht_impact_on_sl', ROUND(aht_sl_correlation::NUMERIC, 3)
                    ),
                    'forecast', jsonb_build_object(
                        'next_period_sl', ROUND(
                            (fd.sl_slope * EXTRACT(EPOCH FROM v_date_to + INTERVAL '1 ' || v_trend_interval) + fd.sl_intercept)::NUMERIC, 
                            2
                        ),
                        'next_period_volume', ROUND(
                            (fd.volume_slope * EXTRACT(EPOCH FROM v_date_to + INTERVAL '1 ' || v_trend_interval) + fd.volume_intercept)::NUMERIC, 
                            0
                        )
                    ),
                    'time_series', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'period', trend_period,
                                'total_calls', total_calls,
                                'service_level', ROUND(avg_service_level::NUMERIC, 2),
                                'handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                                'sl_moving_avg', ROUND(sl_moving_avg::NUMERIC, 2),
                                'sl_change', ROUND(sl_change::NUMERIC, 2),
                                'volume_growth', ROUND(volume_growth_rate::NUMERIC, 2)
                            )
                            ORDER BY trend_period
                        )
                        FROM trend_calculations tc
                        WHERE tc.project_code = ts.project_code
                    )
                )
            )
            FROM trend_summary ts
            LEFT JOIN forecast_data fd ON ts.project_code = fd.project_code
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 10. QUEUE-LEVEL COMPARISON REPORT
-- =====================================================================================

CREATE OR REPLACE FUNCTION generate_queue_comparison_report(
    p_parameters JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_date_from DATE;
    v_date_to DATE;
    v_queue_filter TEXT[];
    v_comparison_metric VARCHAR;
    v_result JSONB;
BEGIN
    -- Extract parameters
    v_date_from := COALESCE((p_parameters->>'date_from')::DATE, CURRENT_DATE - 7);
    v_date_to := COALESCE((p_parameters->>'date_to')::DATE, CURRENT_DATE);
    v_queue_filter := COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(p_parameters->'queues')),
        ARRAY[]::TEXT[]
    );
    v_comparison_metric := COALESCE(p_parameters->>'metric', 'service_level');
    
    -- Generate queue-level comparisons
    WITH queue_metrics AS (
        SELECT 
            p.project_code,
            p.project_name,
            pq.queue_code,
            pq.queue_name,
            pq.queue_type,
            pq.service_level_target,
            -- Performance metrics
            COUNT(DISTINCT DATE(ps.period_timestamp)) as active_days,
            SUM(ps.cdo) as total_calls,
            AVG(ps.sl) as avg_service_level,
            AVG(ps.aht) as avg_handle_time,
            AVG(ps.awt_hc) as avg_wait_time,
            AVG(ps.lcr) as abandon_rate,
            -- Peak metrics
            MAX(ps.cdo) as peak_calls,
            MAX(ps.awt_hc) as peak_wait_time,
            -- Consistency metrics
            STDDEV(ps.sl) as sl_consistency,
            COUNT(*) FILTER (WHERE ps.sl >= pq.service_level_target) as intervals_meeting_target,
            COUNT(*) as total_intervals
        FROM projects p
        INNER JOIN project_queues pq ON p.project_id = pq.project_id
        LEFT JOIN get_all_project_staging_data(v_date_from, v_date_to) ps ON pq.queue_id = ps.queue_id
        WHERE (cardinality(v_queue_filter) = 0 OR pq.queue_code = ANY(v_queue_filter))
        GROUP BY p.project_code, p.project_name, pq.queue_code, pq.queue_name, 
                 pq.queue_type, pq.service_level_target
    ),
    queue_rankings AS (
        SELECT 
            *,
            -- Calculate target achievement rate
            intervals_meeting_target::DECIMAL / NULLIF(total_intervals, 0) * 100 as target_achievement_rate,
            -- Rank queues by different metrics
            RANK() OVER (ORDER BY avg_service_level DESC NULLS LAST) as sl_rank,
            RANK() OVER (ORDER BY avg_handle_time ASC NULLS LAST) as aht_rank,
            RANK() OVER (ORDER BY total_calls DESC NULLS LAST) as volume_rank,
            RANK() OVER (ORDER BY abandon_rate ASC NULLS LAST) as abandon_rank,
            -- Performance score (composite)
            (
                (COALESCE(avg_service_level, 0) / 100.0 * 0.4) +
                (CASE WHEN avg_handle_time > 0 THEN (300.0 / avg_handle_time * 0.3) ELSE 0 END) +
                (CASE WHEN abandon_rate > 0 THEN ((10.0 - abandon_rate) / 10.0 * 0.3) ELSE 0.3 END)
            ) * 100 as performance_score
        FROM queue_metrics
    ),
    hourly_patterns AS (
        SELECT 
            pq.queue_code,
            EXTRACT(HOUR FROM ps.period_timestamp) as hour,
            AVG(ps.sl) as hourly_sl,
            AVG(ps.cdo) as hourly_volume,
            AVG(ps.aht) as hourly_aht
        FROM project_queues pq
        INNER JOIN get_all_project_staging_data(v_date_from, v_date_to) ps ON pq.queue_id = ps.queue_id
        WHERE (cardinality(v_queue_filter) = 0 OR pq.queue_code = ANY(v_queue_filter))
        GROUP BY pq.queue_code, EXTRACT(HOUR FROM ps.period_timestamp)
    )
    SELECT jsonb_build_object(
        'report_type', 'queue_comparison',
        'comparison_period', jsonb_build_object(
            'from', v_date_from,
            'to', v_date_to
        ),
        'summary', jsonb_build_object(
            'total_queues', (SELECT COUNT(*) FROM queue_rankings),
            'total_projects', (SELECT COUNT(DISTINCT project_code) FROM queue_rankings),
            'best_performing_queue', (
                SELECT jsonb_build_object(
                    'queue', queue_name,
                    'project', project_name,
                    'performance_score', ROUND(performance_score::NUMERIC, 2),
                    'service_level', ROUND(avg_service_level::NUMERIC, 2)
                )
                FROM queue_rankings
                ORDER BY performance_score DESC
                LIMIT 1
            ),
            'highest_volume_queue', (
                SELECT jsonb_build_object(
                    'queue', queue_name,
                    'project', project_name,
                    'total_calls', total_calls,
                    'daily_average', ROUND((total_calls / NULLIF(active_days, 0))::NUMERIC, 0)
                )
                FROM queue_rankings
                ORDER BY total_calls DESC
                LIMIT 1
            )
        ),
        'queue_comparisons', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'project', project_name,
                    'queue_code', queue_code,
                    'queue_name', queue_name,
                    'queue_type', queue_type,
                    'metrics', jsonb_build_object(
                        'total_calls', total_calls,
                        'active_days', active_days,
                        'avg_service_level', ROUND(avg_service_level::NUMERIC, 2),
                        'target_achievement', ROUND(target_achievement_rate::NUMERIC, 2),
                        'avg_handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                        'avg_wait_time', ROUND(avg_wait_time::NUMERIC, 1),
                        'abandon_rate', ROUND(abandon_rate::NUMERIC, 2),
                        'peak_calls_interval', peak_calls,
                        'peak_wait_seconds', ROUND(peak_wait_time::NUMERIC, 0)
                    ),
                    'rankings', jsonb_build_object(
                        'service_level_rank', sl_rank,
                        'efficiency_rank', aht_rank,
                        'volume_rank', volume_rank,
                        'abandon_rank', abandon_rank,
                        'overall_score', ROUND(performance_score::NUMERIC, 2)
                    ),
                    'consistency', jsonb_build_object(
                        'sl_variance', ROUND(sl_consistency::NUMERIC, 2),
                        'intervals_meeting_target', intervals_meeting_target,
                        'total_intervals', total_intervals
                    ),
                    'hourly_pattern', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'hour', hour,
                                'service_level', ROUND(hourly_sl::NUMERIC, 2),
                                'volume', ROUND(hourly_volume::NUMERIC, 0),
                                'handle_time', ROUND(hourly_aht::NUMERIC, 0)
                            )
                            ORDER BY hour
                        )
                        FROM hourly_patterns hp
                        WHERE hp.queue_code = qr.queue_code
                    )
                )
                ORDER BY performance_score DESC
            )
            FROM queue_rankings qr
        ),
        'top_performers', jsonb_build_object(
            'by_service_level', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'queue', queue_name,
                        'project', project_name,
                        'value', ROUND(avg_service_level::NUMERIC, 2)
                    )
                    ORDER BY avg_service_level DESC
                )
                FROM queue_rankings
                LIMIT 5
            ),
            'by_efficiency', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'queue', queue_name,
                        'project', project_name,
                        'value', ROUND(avg_handle_time::NUMERIC, 0)
                    )
                    ORDER BY avg_handle_time ASC
                )
                FROM queue_rankings
                WHERE avg_handle_time IS NOT NULL
                LIMIT 5
            ),
            'by_volume', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'queue', queue_name,
                        'project', project_name,
                        'value', total_calls
                    )
                    ORDER BY total_calls DESC
                )
                FROM queue_rankings
                LIMIT 5
            )
        ),
        'generated_at', NOW()
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 11. EXPORT FUNCTIONS
-- =====================================================================================

-- Export report to CSV format
CREATE OR REPLACE FUNCTION export_report_to_csv(
    p_execution_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_report_data JSONB;
    v_csv_output TEXT;
    v_template_type VARCHAR;
BEGIN
    -- Get report data and type
    SELECT 
        reh.report_data,
        rt.template_type
    INTO v_report_data, v_template_type
    FROM report_execution_history reh
    INNER JOIN report_templates rt ON reh.template_id = rt.template_id
    WHERE reh.execution_id = p_execution_id;
    
    IF v_report_data IS NULL THEN
        RAISE EXCEPTION 'Report execution % not found', p_execution_id;
    END IF;
    
    -- Generate CSV based on report type
    CASE v_template_type
        WHEN 'daily_summary' THEN
            v_csv_output := export_daily_summary_csv(v_report_data);
        WHEN 'project_analysis' THEN
            v_csv_output := export_project_analysis_csv(v_report_data);
        WHEN 'multi_skill' THEN
            v_csv_output := export_multi_skill_csv(v_report_data);
        ELSE
            v_csv_output := export_generic_csv(v_report_data);
    END CASE;
    
    RETURN v_csv_output;
END;
$$ LANGUAGE plpgsql;

-- Generic CSV export for any JSON report
CREATE OR REPLACE FUNCTION export_generic_csv(
    p_report_data JSONB
)
RETURNS TEXT AS $$
DECLARE
    v_csv TEXT := '';
    v_headers TEXT[];
    v_row JSONB;
BEGIN
    -- Extract headers from first data row
    IF p_report_data->'projects' IS NOT NULL AND jsonb_array_length(p_report_data->'projects') > 0 THEN
        v_headers := ARRAY(
            SELECT jsonb_object_keys(p_report_data->'projects'->0->'metrics')
        );
        
        -- Add header row
        v_csv := 'project_code,project_name,' || array_to_string(v_headers, ',') || E'\n';
        
        -- Add data rows
        FOR v_row IN SELECT * FROM jsonb_array_elements(p_report_data->'projects')
        LOOP
            v_csv := v_csv || 
                     v_row->>'project_code' || ',' ||
                     v_row->>'project_name' || ',';
            
            FOR i IN 1..array_length(v_headers, 1) LOOP
                v_csv := v_csv || COALESCE(v_row->'metrics'->>v_headers[i], '') || 
                        CASE WHEN i < array_length(v_headers, 1) THEN ',' ELSE E'\n' END;
            END LOOP;
        END LOOP;
    END IF;
    
    RETURN v_csv;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 12. DASHBOARD DATA FEED VIEWS
-- =====================================================================================

-- Real-time dashboard feed
CREATE OR REPLACE VIEW v_dashboard_realtime_feed AS
WITH latest_data AS (
    SELECT DISTINCT ON (p.project_code, pq.queue_code)
        p.project_code,
        p.project_name,
        pq.queue_code,
        pq.queue_name,
        ps.period_timestamp,
        ps.cdo as calls_offered,
        ps.hc as calls_handled,
        ps.sl as service_level,
        ps.aht as handle_time,
        ps.awt_hc as wait_time,
        ps.lcr as abandon_rate
    FROM projects p
    INNER JOIN project_queues pq ON p.project_id = pq.project_id
    LEFT JOIN LATERAL (
        SELECT * FROM get_latest_staging_data(p.project_code)
    ) ps ON pq.queue_id = ps.queue_id
    ORDER BY p.project_code, pq.queue_code, ps.period_timestamp DESC
)
SELECT 
    project_code,
    project_name,
    jsonb_agg(
        jsonb_build_object(
            'queue_code', queue_code,
            'queue_name', queue_name,
            'last_update', period_timestamp,
            'metrics', jsonb_build_object(
                'calls_offered', calls_offered,
                'service_level', ROUND(service_level::NUMERIC, 2),
                'handle_time', handle_time,
                'wait_time', ROUND(wait_time::NUMERIC, 1),
                'abandon_rate', ROUND(abandon_rate::NUMERIC, 2)
            ),
            'status', CASE
                WHEN service_level >= 90 THEN 'green'
                WHEN service_level >= 80 THEN 'yellow'
                WHEN service_level >= 70 THEN 'orange'
                ELSE 'red'
            END
        )
    ) as queues
FROM latest_data
GROUP BY project_code, project_name;

-- Executive summary dashboard view
CREATE OR REPLACE VIEW v_dashboard_executive_summary AS
WITH daily_summary AS (
    SELECT 
        p.project_code,
        p.project_name,
        p.priority_level,
        COUNT(DISTINCT pq.queue_id) as queue_count,
        SUM(ps.cdo) as total_calls,
        AVG(ps.sl) as avg_service_level,
        AVG(ps.aht) as avg_handle_time,
        SUM(ps.ac) / NULLIF(SUM(ps.cdo), 0) * 100 as abandon_rate
    FROM projects p
    INNER JOIN project_queues pq ON p.project_id = pq.project_id
    LEFT JOIN get_today_staging_data() ps ON pq.queue_id = ps.queue_id
    GROUP BY p.project_code, p.project_name, p.priority_level
)
SELECT 
    jsonb_build_object(
        'generated_at', NOW(),
        'summary_date', CURRENT_DATE,
        'total_projects', COUNT(*),
        'total_queues', SUM(queue_count),
        'total_calls_today', SUM(total_calls),
        'overall_service_level', AVG(avg_service_level),
        'projects', jsonb_agg(
            jsonb_build_object(
                'code', project_code,
                'name', project_name,
                'priority', priority_level,
                'queues', queue_count,
                'calls', total_calls,
                'service_level', ROUND(avg_service_level::NUMERIC, 2),
                'handle_time', ROUND(avg_handle_time::NUMERIC, 0),
                'abandon_rate', ROUND(abandon_rate::NUMERIC, 2)
            )
            ORDER BY priority_level DESC, total_calls DESC
        )
    ) as dashboard_data
FROM daily_summary;

-- =====================================================================================
-- 13. UTILITY FUNCTIONS
-- =====================================================================================

-- Function to get staging data for any project
CREATE OR REPLACE FUNCTION get_project_staging_data(
    p_project_code VARCHAR,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
)
RETURNS TABLE (
    queue_id INTEGER,
    period_timestamp TIMESTAMPTZ,
    cdo INTEGER,
    hc INTEGER,
    sl DECIMAL,
    aht INTEGER,
    awt_hc DECIMAL,
    ac INTEGER,
    lcr DECIMAL,
    tt BIGINT,
    acw BIGINT
) AS $$
BEGIN
    -- Route to appropriate staging table based on project code
    CASE p_project_code
        WHEN 'I' THEN
            RETURN QUERY
            SELECT 
                1 as queue_id, -- Placeholder, would map to actual queues
                period_timestamp,
                cdo, hc, sl, aht, awt_hc, ac, lcr, tt, acw
            FROM project_i_staging
            WHERE is_processed = TRUE
            AND (p_date_from IS NULL OR period_timestamp >= p_date_from)
            AND (p_date_to IS NULL OR period_timestamp <= p_date_to);
            
        WHEN 'VTM' THEN
            RETURN QUERY
            SELECT 
                1 as queue_id, -- Placeholder
                period_timestamp,
                cdo, hc, shc as sl, aht, awt_hc, ac, lcr, tt, acw
            FROM stg_vtm_metrics
            WHERE processed = TRUE
            AND (p_date_from IS NULL OR period_timestamp >= p_date_from)
            AND (p_date_to IS NULL OR period_timestamp <= p_date_to);
            
        WHEN 'B' THEN
            RETURN QUERY
            SELECT 
                1 as queue_id, -- Placeholder
                period_timestamp,
                cdo_calls as cdo, handled_calls as hc, service_level as sl, 
                aht_seconds as aht, avg_wait_handled as awt_hc, 
                abandoned_calls as ac, abandon_rate as lcr, 
                total_talk_time as tt, total_acw_time as acw
            FROM staging_project_b_processed
            WHERE (p_date_from IS NULL OR period_timestamp >= p_date_from)
            AND (p_date_to IS NULL OR period_timestamp <= p_date_to);
            
        ELSE
            -- Generic staging table fallback
            RETURN QUERY
            SELECT 
                1 as queue_id,
                NOW() as period_timestamp,
                0, 0, 0::DECIMAL, 0, 0::DECIMAL, 0, 0::DECIMAL, 0::BIGINT, 0::BIGINT
            WHERE FALSE; -- Return empty
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 14. REPORT TEMPLATE INITIALIZATION
-- =====================================================================================

-- Insert default report templates
INSERT INTO report_templates (template_code, template_name, template_type, report_category, config_json, chart_types)
VALUES 
    ('DAILY_COMPARISON', 'Daily Multi-Project Comparison', 'daily_summary', 'operational', 
     '{"default_projects": ["B", "F", "I", "VTM"], "metrics": ["sl", "aht", "volume"]}',
     '{"bar", "line", "gauge"}'),
     
    ('PROJECT_ANALYSIS', 'Detailed Project Analysis', 'project_analysis', 'strategic',
     '{"default_interval": "1h", "trend_days": 7, "include_queues": true}',
     '{"line", "heatmap", "bar"}'),
     
    ('MULTI_SKILL_ACCURACY', 'Multi-Skill Routing Accuracy', 'multi_skill', 'technical',
     '{"skill_categories": ["language", "technical", "product"], "min_utilization": 50}',
     '{"scatter", "bar", "heatmap"}'),
     
    ('PERFORMANCE_BENCHMARK', 'Performance Benchmarking Report', 'benchmark', 'executive',
     '{"benchmark_types": ["industry", "internal", "historical"], "metrics": ["sl", "aht", "abandon"]}',
     '{"bar", "gauge", "spider"}'),
     
    ('FAILURE_PATTERN', 'Failure Pattern Analysis', 'trend', 'technical',
     '{"failure_types": ["sl_failure", "abandon_failure", "wait_failure"], "threshold_sl": 80}',
     '{"heatmap", "line", "scatter"}'),
     
    ('TREND_ANALYSIS', 'Trend Analysis and Forecasting', 'trend', 'strategic',
     '{"trend_intervals": ["daily", "weekly", "monthly"], "forecast_periods": 3}',
     '{"line", "area", "forecast"}'),
     
    ('QUEUE_COMPARISON', 'Queue-Level Performance Comparison', 'queue_comparison', 'operational',
     '{"comparison_metrics": ["sl", "aht", "volume", "abandon"], "top_n": 20}',
     '{"bar", "scatter", "table"}')
ON CONFLICT (template_code) DO UPDATE
SET 
    template_name = EXCLUDED.template_name,
    config_json = EXCLUDED.config_json,
    updated_at = NOW();

-- Insert default comparison metrics
INSERT INTO comparison_metrics (metric_code, metric_name, metric_category, calculation_sql, display_format, unit_label)
VALUES 
    ('SL_ACHIEVEMENT', 'Service Level Achievement', 'performance', 
     'AVG(CASE WHEN sl >= target THEN 100 ELSE sl / target * 100 END)', 'percentage', '%'),
     
    ('AHT_EFFICIENCY', 'Handle Time Efficiency', 'efficiency',
     'AVG(CASE WHEN aht <= 300 THEN 100 ELSE 300 / aht * 100 END)', 'percentage', '%'),
     
    ('VOLUME_CAPACITY', 'Volume Capacity Utilization', 'volume',
     'SUM(cdo) / MAX(capacity) * 100', 'percentage', '%'),
     
    ('ABANDON_PERFORMANCE', 'Abandonment Performance', 'quality',
     '100 - AVG(lcr)', 'percentage', '%'),
     
    ('WAIT_TIME_SCORE', 'Wait Time Performance', 'quality',
     'AVG(CASE WHEN awt_hc <= 30 THEN 100 ELSE 30 / awt_hc * 100 END)', 'percentage', '%')
ON CONFLICT (metric_code) DO NOTHING;

-- =====================================================================================
-- 15. PERMISSIONS AND MAINTENANCE
-- =====================================================================================

-- Grant permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_readonly_user;
GRANT SELECT, INSERT, UPDATE ON report_execution_history TO wfm_analyst_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_analyst_user;

-- Create indexes for performance
CREATE INDEX idx_report_execution_status ON report_execution_history(status, requested_at);
CREATE INDEX idx_report_execution_template ON report_execution_history(template_id, completed_at);
CREATE INDEX idx_comparison_metrics_category ON comparison_metrics(metric_category, is_active);

-- Maintenance procedure for cleaning old data
CREATE OR REPLACE FUNCTION maintain_report_tables()
RETURNS VOID AS $$
BEGIN
    -- Clean old execution history (keep 90 days)
    DELETE FROM report_execution_history
    WHERE completed_at < NOW() - INTERVAL '90 days';
    
    -- Clean expired cache entries
    DELETE FROM comparison_results_cache
    WHERE expires_at < NOW();
    
    -- Update cache statistics
    UPDATE comparison_results_cache
    SET hit_count = 0,
        last_accessed = NOW() - INTERVAL '30 days'
    WHERE last_accessed < NOW() - INTERVAL '30 days';
    
    -- Vacuum tables
    VACUUM ANALYZE report_execution_history;
    VACUUM ANALYZE comparison_results_cache;
END;
$$ LANGUAGE plpgsql;

-- Schedule maintenance (would be done via pg_cron)
-- SELECT cron.schedule('maintain-reports', '0 3 * * *', 'SELECT maintain_report_tables();');

-- =====================================================================================
-- END OF COMPARISON REPORT GENERATION FRAMEWORK
-- =====================================================================================