-- =====================================================================================
-- Parallel Algorithm Execution Framework
-- Purpose: Execute and compare Argus vs WFM calculations side-by-side
-- Created for: L-1A-Data-Analysis Agent (Subagent C1)
-- Supports: All 4 projects (Б, ВТМ, И, Ф) with multi-skill scenarios
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =====================================================================================
-- 1. ALGORITHM RESULT STORAGE TABLES
-- =====================================================================================

-- Drop existing tables
DROP TABLE IF EXISTS parallel_execution_jobs CASCADE;
DROP TABLE IF EXISTS argus_calculation_results CASCADE;
DROP TABLE IF EXISTS wfm_calculation_results CASCADE;
DROP TABLE IF EXISTS algorithm_comparison_results CASCADE;
DROP TABLE IF EXISTS execution_performance_metrics CASCADE;

-- Main job queue for parallel execution
CREATE TABLE parallel_execution_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_type VARCHAR(50) NOT NULL, -- 'erlang_c', 'multi_skill', 'forecasting', 'scheduling'
    project_code VARCHAR(50) NOT NULL, -- 'B', 'VTM', 'I', 'F'
    queue_code VARCHAR(100),
    
    -- Input parameters
    input_data JSONB NOT NULL,
    calculation_date DATE NOT NULL,
    interval_type VARCHAR(10) NOT NULL, -- '15m', '30m', '1h'
    time_period_start TIMESTAMPTZ NOT NULL,
    time_period_end TIMESTAMPTZ NOT NULL,
    
    -- Execution control
    job_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    priority INTEGER DEFAULT 3,
    max_retry_count INTEGER DEFAULT 3,
    current_retry_count INTEGER DEFAULT 0,
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Results
    argus_execution_id UUID,
    wfm_execution_id UUID,
    comparison_id UUID,
    
    -- Error tracking
    error_message TEXT,
    error_details JSONB,
    
    CONSTRAINT job_status_check CHECK (job_status IN ('pending', 'running', 'completed', 'failed'))
);

-- Indexes for job queue management
CREATE INDEX idx_parallel_jobs_status ON parallel_execution_jobs(job_status, priority DESC, created_at);
CREATE INDEX idx_parallel_jobs_project ON parallel_execution_jobs(project_code, calculation_date);
CREATE INDEX idx_parallel_jobs_timing ON parallel_execution_jobs(created_at, completed_at);

-- =====================================================================================
-- 2. ARGUS CALCULATION RESULTS
-- =====================================================================================

CREATE TABLE argus_calculation_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES parallel_execution_jobs(job_id),
    
    -- Calculation metadata
    algorithm_version VARCHAR(50) DEFAULT 'argus_v2.5',
    calculation_timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    -- Input parameters (for reproducibility)
    input_parameters JSONB NOT NULL,
    
    -- Core Erlang C results
    offered_calls INTEGER,
    handled_calls INTEGER,
    abandoned_calls INTEGER,
    service_level DECIMAL(5,2),
    average_wait_time DECIMAL(10,2),
    average_handle_time DECIMAL(10,2),
    
    -- Agent calculations
    agents_required INTEGER,
    agent_occupancy DECIMAL(5,2),
    agent_utilization DECIMAL(5,2),
    
    -- Multi-skill specific results
    skill_assignments JSONB, -- Array of {skill_id, agent_count, proficiency_level}
    skill_coverage JSONB, -- Array of {skill_id, coverage_percentage}
    skill_gaps JSONB, -- Array of {skill_id, gap_count, severity}
    
    -- Intermediate calculations (for comparison)
    erlang_b_blocking DECIMAL(10,8),
    erlang_c_delay DECIMAL(10,8),
    poisson_probability JSONB, -- Array of probabilities by n
    traffic_intensity DECIMAL(10,4),
    
    -- Performance metrics
    calculation_time_ms INTEGER,
    memory_used_bytes BIGINT,
    
    -- Validation
    calculation_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB
);

-- Indexes for Argus results
CREATE INDEX idx_argus_results_job ON argus_calculation_results(job_id);
CREATE INDEX idx_argus_results_timing ON argus_calculation_results(calculation_timestamp);

-- =====================================================================================
-- 3. WFM CALCULATION RESULTS
-- =====================================================================================

CREATE TABLE wfm_calculation_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES parallel_execution_jobs(job_id),
    
    -- Calculation metadata
    algorithm_version VARCHAR(50) DEFAULT 'wfm_enterprise_v1.0',
    calculation_timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    -- Input parameters (for reproducibility)
    input_parameters JSONB NOT NULL,
    
    -- Core Erlang C results
    offered_calls INTEGER,
    handled_calls INTEGER,
    abandoned_calls INTEGER,
    service_level DECIMAL(5,2),
    average_wait_time DECIMAL(10,2),
    average_handle_time DECIMAL(10,2),
    
    -- Agent calculations
    agents_required INTEGER,
    agent_occupancy DECIMAL(5,2),
    agent_utilization DECIMAL(5,2),
    
    -- Multi-skill specific results
    skill_assignments JSONB, -- Array of {skill_id, agent_count, proficiency_level}
    skill_coverage JSONB, -- Array of {skill_id, coverage_percentage}
    skill_gaps JSONB, -- Array of {skill_id, gap_count, severity}
    
    -- Enhanced WFM calculations
    shrinkage_factor DECIMAL(5,2),
    schedule_efficiency DECIMAL(5,2),
    forecast_accuracy DECIMAL(5,2),
    
    -- Intermediate calculations (for comparison)
    erlang_b_blocking DECIMAL(10,8),
    erlang_c_delay DECIMAL(10,8),
    poisson_probability JSONB, -- Array of probabilities by n
    traffic_intensity DECIMAL(10,4),
    
    -- Optimization results
    optimization_iterations INTEGER,
    optimization_score DECIMAL(10,4),
    
    -- Performance metrics
    calculation_time_ms INTEGER,
    memory_used_bytes BIGINT,
    
    -- Validation
    calculation_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB
);

-- Indexes for WFM results
CREATE INDEX idx_wfm_results_job ON wfm_calculation_results(job_id);
CREATE INDEX idx_wfm_results_timing ON wfm_calculation_results(calculation_timestamp);

-- =====================================================================================
-- 4. ALGORITHM COMPARISON RESULTS
-- =====================================================================================

CREATE TABLE algorithm_comparison_results (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES parallel_execution_jobs(job_id),
    argus_result_id UUID REFERENCES argus_calculation_results(result_id),
    wfm_result_id UUID REFERENCES wfm_calculation_results(result_id),
    
    -- Comparison metadata
    comparison_timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    -- Core metric differences
    agents_diff INTEGER,
    agents_diff_pct DECIMAL(5,2),
    service_level_diff DECIMAL(5,2),
    occupancy_diff DECIMAL(5,2),
    wait_time_diff DECIMAL(10,2),
    
    -- Detailed comparisons
    metric_comparisons JSONB, -- Array of {metric_name, argus_value, wfm_value, difference, pct_difference}
    
    -- Multi-skill comparisons
    skill_assignment_differences JSONB,
    skill_coverage_differences JSONB,
    
    -- Performance comparison
    calculation_time_diff_ms INTEGER,
    memory_usage_diff_bytes BIGINT,
    
    -- Algorithm accuracy metrics
    erlang_c_precision_diff DECIMAL(10,8),
    poisson_accuracy_score DECIMAL(5,2),
    
    -- Summary
    algorithms_agree BOOLEAN,
    significant_differences JSONB, -- Array of metrics with >5% difference
    recommendation TEXT,
    
    CONSTRAINT comparison_unique UNIQUE(job_id)
);

-- Indexes for comparisons
CREATE INDEX idx_comparison_job ON algorithm_comparison_results(job_id);
CREATE INDEX idx_comparison_differences ON algorithm_comparison_results(algorithms_agree);

-- =====================================================================================
-- 5. PERFORMANCE TRACKING
-- =====================================================================================

CREATE TABLE execution_performance_metrics (
    metric_id BIGSERIAL PRIMARY KEY,
    job_id UUID REFERENCES parallel_execution_jobs(job_id),
    algorithm_type VARCHAR(50) NOT NULL, -- 'argus' or 'wfm'
    
    -- Detailed timing breakdown
    initialization_ms INTEGER,
    data_preparation_ms INTEGER,
    calculation_ms INTEGER,
    result_storage_ms INTEGER,
    total_execution_ms INTEGER,
    
    -- Resource usage
    cpu_usage_percent DECIMAL(5,2),
    memory_peak_mb INTEGER,
    temp_storage_mb INTEGER,
    
    -- Database metrics
    db_queries_count INTEGER,
    db_query_time_ms INTEGER,
    db_rows_processed BIGINT,
    
    -- Calculation complexity metrics
    iteration_count INTEGER,
    convergence_achieved BOOLEAN,
    numerical_stability_score DECIMAL(5,2),
    
    -- Timestamp
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance analysis
CREATE INDEX idx_performance_job ON execution_performance_metrics(job_id, algorithm_type);
CREATE INDEX idx_performance_timing ON execution_performance_metrics(total_execution_ms);

-- =====================================================================================
-- 6. PARALLEL EXECUTION PROCEDURES
-- =====================================================================================

-- Main procedure to execute both algorithms in parallel
CREATE OR REPLACE FUNCTION execute_parallel_calculation(
    p_project_code VARCHAR,
    p_queue_code VARCHAR DEFAULT NULL,
    p_calculation_date DATE DEFAULT CURRENT_DATE,
    p_interval_type VARCHAR DEFAULT '30m',
    p_input_data JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
    v_job_id UUID;
    v_argus_result_id UUID;
    v_wfm_result_id UUID;
    v_comparison_id UUID;
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
BEGIN
    -- Create execution job
    INSERT INTO parallel_execution_jobs (
        job_type,
        project_code,
        queue_code,
        input_data,
        calculation_date,
        interval_type,
        time_period_start,
        time_period_end,
        job_status
    )
    VALUES (
        CASE 
            WHEN p_input_data->>'skill_requirements' IS NOT NULL THEN 'multi_skill'
            ELSE 'erlang_c'
        END,
        p_project_code,
        p_queue_code,
        p_input_data,
        p_calculation_date,
        p_interval_type,
        p_calculation_date::TIMESTAMPTZ,
        p_calculation_date::TIMESTAMPTZ + INTERVAL '1 day',
        'pending'
    )
    RETURNING job_id INTO v_job_id;
    
    -- Execute algorithms (this would call actual calculation functions)
    -- For now, returning the job ID for async processing
    RETURN v_job_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to run Argus algorithm
CREATE OR REPLACE FUNCTION execute_argus_calculation(
    p_job_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_result_id UUID;
    v_start_time TIMESTAMPTZ;
    v_job_data RECORD;
    v_calc_time_ms INTEGER;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Get job data
    SELECT * INTO v_job_data
    FROM parallel_execution_jobs
    WHERE job_id = p_job_id;
    
    -- Update job status
    UPDATE parallel_execution_jobs
    SET job_status = 'running',
        started_at = NOW()
    WHERE job_id = p_job_id;
    
    -- Create result record
    INSERT INTO argus_calculation_results (
        job_id,
        input_parameters,
        -- Sample calculations (would be replaced with actual Argus logic)
        offered_calls,
        handled_calls,
        abandoned_calls,
        service_level,
        average_wait_time,
        average_handle_time,
        agents_required,
        agent_occupancy,
        agent_utilization,
        traffic_intensity,
        erlang_c_delay,
        calculation_time_ms
    )
    VALUES (
        p_job_id,
        v_job_data.input_data,
        -- Sample values (actual implementation would calculate these)
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000),
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000) * 0.95,
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000) * 0.05,
        85.5,
        18.5,
        240.0,
        COALESCE((v_job_data.input_data->>'agents_required')::INTEGER, 25),
        82.3,
        78.5,
        4.1667,
        0.0234,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER
    )
    RETURNING result_id INTO v_result_id;
    
    -- Update job with result ID
    UPDATE parallel_execution_jobs
    SET argus_execution_id = v_result_id
    WHERE job_id = p_job_id;
    
    RETURN v_result_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to run WFM algorithm
CREATE OR REPLACE FUNCTION execute_wfm_calculation(
    p_job_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_result_id UUID;
    v_start_time TIMESTAMPTZ;
    v_job_data RECORD;
    v_calc_time_ms INTEGER;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Get job data
    SELECT * INTO v_job_data
    FROM parallel_execution_jobs
    WHERE job_id = p_job_id;
    
    -- Create result record
    INSERT INTO wfm_calculation_results (
        job_id,
        input_parameters,
        -- Sample calculations (would be replaced with actual WFM logic)
        offered_calls,
        handled_calls,
        abandoned_calls,
        service_level,
        average_wait_time,
        average_handle_time,
        agents_required,
        agent_occupancy,
        agent_utilization,
        traffic_intensity,
        erlang_c_delay,
        shrinkage_factor,
        schedule_efficiency,
        optimization_iterations,
        calculation_time_ms
    )
    VALUES (
        p_job_id,
        v_job_data.input_data,
        -- Sample values (actual implementation would calculate these)
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000),
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000) * 0.94,
        COALESCE((v_job_data.input_data->>'offered_calls')::INTEGER, 1000) * 0.06,
        84.2,
        19.8,
        238.5,
        COALESCE((v_job_data.input_data->>'agents_required')::INTEGER, 26),
        81.5,
        77.2,
        4.1458,
        0.0248,
        15.0,
        92.5,
        125,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER
    )
    RETURNING result_id INTO v_result_id;
    
    -- Update job with result ID
    UPDATE parallel_execution_jobs
    SET wfm_execution_id = v_result_id
    WHERE job_id = p_job_id;
    
    RETURN v_result_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. COMPARISON AND ANALYSIS PROCEDURES
-- =====================================================================================

-- Compare results from both algorithms
CREATE OR REPLACE FUNCTION compare_algorithm_results(
    p_job_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_comparison_id UUID;
    v_argus_result RECORD;
    v_wfm_result RECORD;
    v_agents_diff INTEGER;
    v_agents_diff_pct DECIMAL;
    v_algorithms_agree BOOLEAN;
BEGIN
    -- Get both results
    SELECT a.* INTO v_argus_result
    FROM argus_calculation_results a
    JOIN parallel_execution_jobs j ON a.job_id = j.job_id
    WHERE j.job_id = p_job_id;
    
    SELECT w.* INTO v_wfm_result
    FROM wfm_calculation_results w
    JOIN parallel_execution_jobs j ON w.job_id = j.job_id
    WHERE j.job_id = p_job_id;
    
    -- Calculate differences
    v_agents_diff := v_wfm_result.agents_required - v_argus_result.agents_required;
    v_agents_diff_pct := 
        CASE WHEN v_argus_result.agents_required > 0 
        THEN (v_agents_diff::DECIMAL / v_argus_result.agents_required * 100)
        ELSE 0 END;
    
    -- Determine if algorithms agree (within 5% tolerance)
    v_algorithms_agree := ABS(v_agents_diff_pct) <= 5.0;
    
    -- Create comparison record
    INSERT INTO algorithm_comparison_results (
        job_id,
        argus_result_id,
        wfm_result_id,
        agents_diff,
        agents_diff_pct,
        service_level_diff,
        occupancy_diff,
        wait_time_diff,
        calculation_time_diff_ms,
        algorithms_agree,
        metric_comparisons,
        recommendation
    )
    VALUES (
        p_job_id,
        v_argus_result.result_id,
        v_wfm_result.result_id,
        v_agents_diff,
        v_agents_diff_pct,
        v_wfm_result.service_level - v_argus_result.service_level,
        v_wfm_result.agent_occupancy - v_argus_result.agent_occupancy,
        v_wfm_result.average_wait_time - v_argus_result.average_wait_time,
        v_wfm_result.calculation_time_ms - v_argus_result.calculation_time_ms,
        v_algorithms_agree,
        jsonb_build_array(
            jsonb_build_object(
                'metric_name', 'agents_required',
                'argus_value', v_argus_result.agents_required,
                'wfm_value', v_wfm_result.agents_required,
                'difference', v_agents_diff,
                'pct_difference', v_agents_diff_pct
            ),
            jsonb_build_object(
                'metric_name', 'service_level',
                'argus_value', v_argus_result.service_level,
                'wfm_value', v_wfm_result.service_level,
                'difference', v_wfm_result.service_level - v_argus_result.service_level,
                'pct_difference', 
                    CASE WHEN v_argus_result.service_level > 0 
                    THEN ((v_wfm_result.service_level - v_argus_result.service_level) / v_argus_result.service_level * 100)
                    ELSE 0 END
            )
        ),
        CASE 
            WHEN v_algorithms_agree THEN 'Algorithms are in agreement. Results can be trusted.'
            WHEN ABS(v_agents_diff_pct) <= 10 THEN 'Minor differences detected. Review calculation parameters.'
            ELSE 'Significant differences detected. Manual review required.'
        END
    )
    RETURNING comparison_id INTO v_comparison_id;
    
    -- Update job status
    UPDATE parallel_execution_jobs
    SET job_status = 'completed',
        completed_at = NOW(),
        comparison_id = v_comparison_id
    WHERE job_id = p_job_id;
    
    RETURN v_comparison_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 8. BATCH PROCESSING PROCEDURES
-- =====================================================================================

-- Process all pending jobs
CREATE OR REPLACE FUNCTION process_pending_jobs(
    p_batch_size INTEGER DEFAULT 10
)
RETURNS TABLE (
    jobs_processed INTEGER,
    jobs_succeeded INTEGER,
    jobs_failed INTEGER,
    avg_execution_time_ms INTEGER
) AS $$
DECLARE
    v_job RECORD;
    v_processed INTEGER := 0;
    v_succeeded INTEGER := 0;
    v_failed INTEGER := 0;
    v_total_time_ms INTEGER := 0;
BEGIN
    -- Process pending jobs in priority order
    FOR v_job IN 
        SELECT job_id
        FROM parallel_execution_jobs
        WHERE job_status = 'pending'
        ORDER BY priority DESC, created_at
        LIMIT p_batch_size
    LOOP
        BEGIN
            -- Execute both algorithms
            PERFORM execute_argus_calculation(v_job.job_id);
            PERFORM execute_wfm_calculation(v_job.job_id);
            PERFORM compare_algorithm_results(v_job.job_id);
            
            v_succeeded := v_succeeded + 1;
        EXCEPTION WHEN OTHERS THEN
            -- Log error
            UPDATE parallel_execution_jobs
            SET job_status = 'failed',
                error_message = SQLERRM,
                error_details = jsonb_build_object(
                    'error_code', SQLSTATE,
                    'error_detail', SQLERRM,
                    'error_hint', SQLHINT
                )
            WHERE job_id = v_job.job_id;
            
            v_failed := v_failed + 1;
        END;
        
        v_processed := v_processed + 1;
    END LOOP;
    
    -- Return summary
    RETURN QUERY
    SELECT v_processed, v_succeeded, v_failed, 
           CASE WHEN v_succeeded > 0 THEN v_total_time_ms / v_succeeded ELSE 0 END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. PROJECT-SPECIFIC EXECUTION FUNCTIONS
-- =====================================================================================

-- Execute calculations for Project Б (simple)
CREATE OR REPLACE FUNCTION execute_project_b_parallel(
    p_date DATE DEFAULT CURRENT_DATE,
    p_interval VARCHAR DEFAULT '30m'
)
RETURNS SETOF UUID AS $$
BEGIN
    RETURN QUERY
    SELECT execute_parallel_calculation(
        'B',
        NULL,
        p_date,
        p_interval,
        jsonb_build_object(
            'offered_calls', 500,
            'average_handle_time', 180,
            'service_level_target', 80,
            'service_level_seconds', 20
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Execute calculations for Project ВТМ (32 queues)
CREATE OR REPLACE FUNCTION execute_project_vtm_parallel(
    p_date DATE DEFAULT CURRENT_DATE,
    p_interval VARCHAR DEFAULT '30m'
)
RETURNS TABLE (
    queue_code VARCHAR,
    job_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pq.queue_code,
        execute_parallel_calculation(
            'VTM',
            pq.queue_code,
            p_date,
            p_interval,
            jsonb_build_object(
                'offered_calls', 1500,
                'average_handle_time', 240,
                'service_level_target', pq.service_level_target,
                'service_level_seconds', pq.service_level_seconds,
                'skill_requirements', jsonb_build_array(
                    jsonb_build_object('skill_code', 'LANG_RU_FLUENT', 'min_proficiency', 4),
                    jsonb_build_object('skill_code', 'TECH_SUPPORT', 'min_proficiency', 3)
                )
            )
        )
    FROM project_queues pq
    WHERE pq.project_id = (SELECT project_id FROM projects WHERE project_code = 'VTM')
    AND pq.is_active = TRUE
    LIMIT 5; -- Process 5 queues at a time for testing
END;
$$ LANGUAGE plpgsql;

-- Execute calculations for Project И (68 queues)
CREATE OR REPLACE FUNCTION execute_project_i_parallel(
    p_date DATE DEFAULT CURRENT_DATE,
    p_interval VARCHAR DEFAULT '15m',
    p_queue_group INTEGER DEFAULT 1 -- Process queues in groups
)
RETURNS TABLE (
    queue_code VARCHAR,
    job_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pq.queue_code,
        execute_parallel_calculation(
            'I',
            pq.queue_code,
            p_date,
            p_interval,
            jsonb_build_object(
                'offered_calls', 
                    CASE 
                        WHEN pq.priority = 5 THEN 3000
                        WHEN pq.priority = 4 THEN 2000
                        ELSE 1000
                    END,
                'average_handle_time', 300,
                'service_level_target', pq.service_level_target,
                'service_level_seconds', pq.service_level_seconds,
                'skill_requirements', 
                    CASE pq.queue_type
                        WHEN 'inbound' THEN jsonb_build_array(
                            jsonb_build_object('skill_code', 'LANG_RU_NATIVE', 'min_proficiency', 5),
                            jsonb_build_object('skill_code', 'CUSTOMER_SERVICE', 'min_proficiency', 3)
                        )
                        WHEN 'technical' THEN jsonb_build_array(
                            jsonb_build_object('skill_code', 'TECH_IT_L2', 'min_proficiency', 4),
                            jsonb_build_object('skill_code', 'LANG_EN_BUSINESS', 'min_proficiency', 4)
                        )
                        ELSE jsonb_build_array(
                            jsonb_build_object('skill_code', 'GENERAL_SUPPORT', 'min_proficiency', 3)
                        )
                    END
            )
        )
    FROM project_queues pq
    WHERE pq.project_id = (SELECT project_id FROM projects WHERE project_code = 'I')
    AND pq.is_active = TRUE
    AND MOD(CAST(SUBSTRING(pq.queue_code FROM '\d+') AS INTEGER), 10) = p_queue_group - 1
    LIMIT 10; -- Process 10 queues at a time
END;
$$ LANGUAGE plpgsql;

-- Execute calculations for Project Ф (government)
CREATE OR REPLACE FUNCTION execute_project_f_parallel(
    p_date DATE DEFAULT CURRENT_DATE,
    p_interval VARCHAR DEFAULT '1h'
)
RETURNS TABLE (
    queue_code VARCHAR,
    job_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pq.queue_code,
        execute_parallel_calculation(
            'F',
            pq.queue_code,
            p_date,
            p_interval,
            jsonb_build_object(
                'offered_calls', 800,
                'average_handle_time', 360,
                'service_level_target', 95, -- High SL for government
                'service_level_seconds', 30,
                'skill_requirements', jsonb_build_array(
                    jsonb_build_object('skill_code', 'GOV_CERTIFIED', 'min_proficiency', 5),
                    jsonb_build_object('skill_code', 'SECURITY_CLEARED', 'min_proficiency', 4),
                    jsonb_build_object('skill_code', 'LANG_RU_NATIVE', 'min_proficiency', 5)
                )
            )
        )
    FROM project_queues pq
    WHERE pq.project_id = (SELECT project_id FROM projects WHERE project_code = 'F')
    AND pq.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 10. MONITORING AND REPORTING VIEWS
-- =====================================================================================

-- Real-time execution dashboard
CREATE OR REPLACE VIEW v_parallel_execution_dashboard AS
SELECT 
    project_code,
    COUNT(*) FILTER (WHERE job_status = 'pending') as pending_jobs,
    COUNT(*) FILTER (WHERE job_status = 'running') as running_jobs,
    COUNT(*) FILTER (WHERE job_status = 'completed') as completed_jobs,
    COUNT(*) FILTER (WHERE job_status = 'failed') as failed_jobs,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at)) * 1000)::INTEGER as avg_execution_ms,
    MAX(completed_at) as last_completion
FROM parallel_execution_jobs
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY project_code;

-- Algorithm comparison summary
CREATE OR REPLACE VIEW v_algorithm_comparison_summary AS
SELECT 
    j.project_code,
    j.interval_type,
    COUNT(*) as total_comparisons,
    COUNT(*) FILTER (WHERE c.algorithms_agree) as agreements,
    COUNT(*) FILTER (WHERE NOT c.algorithms_agree) as disagreements,
    AVG(ABS(c.agents_diff_pct)) as avg_agent_diff_pct,
    AVG(ABS(c.service_level_diff)) as avg_sl_diff,
    AVG(c.calculation_time_diff_ms) as avg_time_diff_ms
FROM parallel_execution_jobs j
JOIN algorithm_comparison_results c ON j.job_id = c.job_id
WHERE j.completed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY j.project_code, j.interval_type;

-- Performance comparison by project
CREATE OR REPLACE VIEW v_performance_by_project AS
SELECT 
    j.project_code,
    p.algorithm_type,
    COUNT(*) as calculations,
    AVG(p.total_execution_ms) as avg_execution_ms,
    MIN(p.total_execution_ms) as min_execution_ms,
    MAX(p.total_execution_ms) as max_execution_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.total_execution_ms) as median_execution_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY p.total_execution_ms) as p95_execution_ms,
    AVG(p.memory_peak_mb) as avg_memory_mb
FROM execution_performance_metrics p
JOIN parallel_execution_jobs j ON p.job_id = j.job_id
WHERE j.completed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY j.project_code, p.algorithm_type;

-- =====================================================================================
-- 11. HELPER FUNCTIONS
-- =====================================================================================

-- Get latest comparison for a project/queue
CREATE OR REPLACE FUNCTION get_latest_comparison(
    p_project_code VARCHAR,
    p_queue_code VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    job_id UUID,
    comparison_id UUID,
    argus_agents INTEGER,
    wfm_agents INTEGER,
    agents_diff INTEGER,
    agents_diff_pct DECIMAL,
    algorithms_agree BOOLEAN,
    recommendation TEXT,
    comparison_timestamp TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.job_id,
        c.comparison_id,
        a.agents_required as argus_agents,
        w.agents_required as wfm_agents,
        c.agents_diff,
        c.agents_diff_pct,
        c.algorithms_agree,
        c.recommendation,
        c.comparison_timestamp
    FROM parallel_execution_jobs j
    JOIN algorithm_comparison_results c ON j.job_id = c.job_id
    JOIN argus_calculation_results a ON c.argus_result_id = a.result_id
    JOIN wfm_calculation_results w ON c.wfm_result_id = w.result_id
    WHERE j.project_code = p_project_code
    AND (p_queue_code IS NULL OR j.queue_code = p_queue_code)
    AND j.job_status = 'completed'
    ORDER BY c.comparison_timestamp DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Generate execution report
CREATE OR REPLACE FUNCTION generate_execution_report(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    report_section TEXT,
    metric_name TEXT,
    metric_value TEXT
) AS $$
BEGIN
    -- Summary section
    RETURN QUERY
    SELECT 
        'Summary'::TEXT,
        'Total Jobs'::TEXT,
        COUNT(*)::TEXT
    FROM parallel_execution_jobs
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date;
    
    -- Project breakdown
    RETURN QUERY
    SELECT 
        'By Project'::TEXT,
        project_code || ' Jobs'::TEXT,
        COUNT(*)::TEXT
    FROM parallel_execution_jobs
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY project_code;
    
    -- Algorithm agreement
    RETURN QUERY
    SELECT 
        'Algorithm Agreement'::TEXT,
        'Agreement Rate'::TEXT,
        ROUND(100.0 * COUNT(*) FILTER (WHERE algorithms_agree) / NULLIF(COUNT(*), 0), 2)::TEXT || '%'
    FROM algorithm_comparison_results c
    JOIN parallel_execution_jobs j ON c.job_id = j.job_id
    WHERE j.created_at::DATE BETWEEN p_start_date AND p_end_date;
    
    -- Performance metrics
    RETURN QUERY
    SELECT 
        'Performance'::TEXT,
        algorithm_type || ' Avg Time'::TEXT,
        ROUND(AVG(total_execution_ms))::TEXT || ' ms'
    FROM execution_performance_metrics p
    JOIN parallel_execution_jobs j ON p.job_id = j.job_id
    WHERE j.created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY algorithm_type;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 12. PERMISSIONS AND COMMENTS
-- =====================================================================================

-- Add table comments
COMMENT ON TABLE parallel_execution_jobs IS 'Queue for parallel algorithm execution jobs';
COMMENT ON TABLE argus_calculation_results IS 'Results from Argus algorithm calculations';
COMMENT ON TABLE wfm_calculation_results IS 'Results from WFM Enterprise algorithm calculations';
COMMENT ON TABLE algorithm_comparison_results IS 'Side-by-side comparison of Argus vs WFM results';
COMMENT ON TABLE execution_performance_metrics IS 'Detailed performance metrics for each algorithm execution';

-- Grant permissions (adjust user as needed)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_api_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_api_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_api_user;

-- =====================================================================================
-- 13. SAMPLE EXECUTION
-- =====================================================================================

/*
-- Example: Execute parallel calculation for Project ВТМ
SELECT execute_project_vtm_parallel('2025-01-27', '30m');

-- Example: Process pending jobs
SELECT * FROM process_pending_jobs(5);

-- Example: View execution dashboard
SELECT * FROM v_parallel_execution_dashboard;

-- Example: Get latest comparison for Project И
SELECT * FROM get_latest_comparison('I', 'I_Q01');

-- Example: Generate weekly report
SELECT * FROM generate_execution_report();
*/