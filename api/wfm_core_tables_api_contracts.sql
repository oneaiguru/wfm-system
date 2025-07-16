-- =============================================================================
-- WFM Core Tables API Contracts
-- Tables: forecast_data, optimization_results, performance_metrics, employee_preferences
-- =============================================================================
-- Comprehensive API helper functions for core WFM operations
-- Includes Russian language support and realistic test data
-- =============================================================================

-- =============================================================================
-- 1. FORECAST DATA API (forecast_data table)
-- =============================================================================

-- Create forecast data with validation
CREATE OR REPLACE FUNCTION create_forecast_data(
    p_service_id INTEGER,
    p_forecast_date DATE,
    p_interval_start TIME,
    p_call_volume INTEGER,
    p_average_handle_time INTEGER,
    p_service_level_target NUMERIC(5,2) DEFAULT 80.00
) RETURNS JSONB AS $$
DECLARE
    v_forecast_id INTEGER;
    v_result JSONB;
BEGIN
    -- Validate input parameters
    IF p_call_volume < 0 THEN
        RAISE EXCEPTION 'Call volume cannot be negative';
    END IF;
    
    IF p_average_handle_time <= 0 THEN
        RAISE EXCEPTION 'Average handle time must be positive';
    END IF;
    
    IF p_service_level_target < 0 OR p_service_level_target > 100 THEN
        RAISE EXCEPTION 'Service level target must be between 0 and 100';
    END IF;
    
    -- Insert forecast data
    INSERT INTO forecast_data (
        service_id, forecast_date, interval_start, call_volume,
        average_handle_time, service_level_target
    ) VALUES (
        p_service_id, p_forecast_date, p_interval_start, p_call_volume,
        p_average_handle_time, p_service_level_target
    ) RETURNING id INTO v_forecast_id;
    
    v_result := jsonb_build_object(
        'forecast_id', v_forecast_id,
        'service_id', p_service_id,
        'forecast_date', p_forecast_date,
        'interval_start', p_interval_start,
        'call_volume', p_call_volume,
        'average_handle_time', p_average_handle_time,
        'service_level_target', p_service_level_target,
        'status', 'created',
        'message', 'Forecast data created successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Get forecast data by date range
CREATE OR REPLACE FUNCTION get_forecast_data_by_date_range(
    p_service_id INTEGER,
    p_start_date DATE,
    p_end_date DATE,
    p_interval_filter TIME DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_forecast_data JSONB;
    v_total_records INTEGER;
    v_total_volume INTEGER;
    v_avg_handle_time NUMERIC;
BEGIN
    -- Get forecast data with aggregations
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'forecast_id', id,
                'service_id', service_id,
                'forecast_date', forecast_date,
                'interval_start', interval_start,
                'call_volume', call_volume,
                'average_handle_time', average_handle_time,
                'service_level_target', service_level_target,
                'created_at', created_at
            ) ORDER BY forecast_date, interval_start
        ),
        COUNT(*),
        SUM(call_volume),
        AVG(average_handle_time)
    INTO v_forecast_data, v_total_records, v_total_volume, v_avg_handle_time
    FROM forecast_data
    WHERE service_id = p_service_id
      AND forecast_date BETWEEN p_start_date AND p_end_date
      AND (p_interval_filter IS NULL OR interval_start = p_interval_filter);
    
    RETURN jsonb_build_object(
        'service_id', p_service_id,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'total_records', COALESCE(v_total_records, 0),
        'total_volume', COALESCE(v_total_volume, 0),
        'average_handle_time', COALESCE(v_avg_handle_time, 0),
        'forecast_data', COALESCE(v_forecast_data, '[]'::jsonb),
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql;

-- Update forecast data with validation
CREATE OR REPLACE FUNCTION update_forecast_data(
    p_forecast_id INTEGER,
    p_call_volume INTEGER DEFAULT NULL,
    p_average_handle_time INTEGER DEFAULT NULL,
    p_service_level_target NUMERIC(5,2) DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_old_record RECORD;
    v_result JSONB;
BEGIN
    -- Get existing record
    SELECT * INTO v_old_record FROM forecast_data WHERE id = p_forecast_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Forecast record with ID % not found', p_forecast_id;
    END IF;
    
    -- Validate parameters
    IF p_call_volume IS NOT NULL AND p_call_volume < 0 THEN
        RAISE EXCEPTION 'Call volume cannot be negative';
    END IF;
    
    IF p_average_handle_time IS NOT NULL AND p_average_handle_time <= 0 THEN
        RAISE EXCEPTION 'Average handle time must be positive';
    END IF;
    
    -- Update record
    UPDATE forecast_data SET
        call_volume = COALESCE(p_call_volume, call_volume),
        average_handle_time = COALESCE(p_average_handle_time, average_handle_time),
        service_level_target = COALESCE(p_service_level_target, service_level_target)
    WHERE id = p_forecast_id;
    
    v_result := jsonb_build_object(
        'forecast_id', p_forecast_id,
        'old_call_volume', v_old_record.call_volume,
        'new_call_volume', COALESCE(p_call_volume, v_old_record.call_volume),
        'old_average_handle_time', v_old_record.average_handle_time,
        'new_average_handle_time', COALESCE(p_average_handle_time, v_old_record.average_handle_time),
        'old_service_level_target', v_old_record.service_level_target,
        'new_service_level_target', COALESCE(p_service_level_target, v_old_record.service_level_target),
        'status', 'updated',
        'message', 'Forecast data updated successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Delete forecast data by date range
CREATE OR REPLACE FUNCTION delete_forecast_data_by_date_range(
    p_service_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
) RETURNS JSONB AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM forecast_data 
    WHERE service_id = p_service_id 
      AND forecast_date BETWEEN p_start_date AND p_end_date;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'service_id', p_service_id,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'deleted_records', v_deleted_count,
        'status', 'success',
        'message', v_deleted_count || ' forecast records deleted'
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 2. OPTIMIZATION RESULTS API (optimization_results table)
-- =============================================================================

-- Create optimization result
CREATE OR REPLACE FUNCTION create_optimization_result(
    p_request_id VARCHAR(100),
    p_suggestion_type VARCHAR(100),
    p_impact_score DOUBLE PRECISION,
    p_cost_impact DOUBLE PRECISION,
    p_implementation_complexity VARCHAR(50),
    p_details JSONB
) RETURNS JSONB AS $$
DECLARE
    v_result_id INTEGER;
    v_result JSONB;
BEGIN
    -- Validate input parameters
    IF p_impact_score < 0 OR p_impact_score > 100 THEN
        RAISE EXCEPTION 'Impact score must be between 0 and 100';
    END IF;
    
    IF p_implementation_complexity NOT IN ('low', 'medium', 'high', 'очень низкая', 'низкая', 'средняя', 'высокая') THEN
        RAISE EXCEPTION 'Implementation complexity must be low, medium, or high (or Russian equivalents)';
    END IF;
    
    -- Insert optimization result
    INSERT INTO optimization_results (
        request_id, suggestion_type, impact_score, cost_impact,
        implementation_complexity, details
    ) VALUES (
        p_request_id, p_suggestion_type, p_impact_score, p_cost_impact,
        p_implementation_complexity, p_details
    ) RETURNING result_id INTO v_result_id;
    
    v_result := jsonb_build_object(
        'result_id', v_result_id,
        'request_id', p_request_id,
        'suggestion_type', p_suggestion_type,
        'impact_score', p_impact_score,
        'cost_impact', p_cost_impact,
        'implementation_complexity', p_implementation_complexity,
        'details', p_details,
        'status', 'created',
        'message', 'Optimization result created successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Get optimization results by request
CREATE OR REPLACE FUNCTION get_optimization_results_by_request(
    p_request_id VARCHAR(100),
    p_min_impact_score DOUBLE PRECISION DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
    v_results JSONB;
    v_total_count INTEGER;
    v_avg_impact NUMERIC;
    v_total_cost_impact NUMERIC;
BEGIN
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'result_id', result_id,
                'suggestion_type', suggestion_type,
                'impact_score', impact_score,
                'cost_impact', cost_impact,
                'implementation_complexity', implementation_complexity,
                'details', details,
                'created_at', created_at
            ) ORDER BY impact_score DESC
        ),
        COUNT(*),
        AVG(impact_score),
        SUM(cost_impact)
    INTO v_results, v_total_count, v_avg_impact, v_total_cost_impact
    FROM optimization_results
    WHERE request_id = p_request_id
      AND impact_score >= p_min_impact_score;
    
    RETURN jsonb_build_object(
        'request_id', p_request_id,
        'total_results', COALESCE(v_total_count, 0),
        'average_impact_score', COALESCE(v_avg_impact, 0),
        'total_cost_impact', COALESCE(v_total_cost_impact, 0),
        'results', COALESCE(v_results, '[]'::jsonb),
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql;

-- Update optimization result status
CREATE OR REPLACE FUNCTION update_optimization_result_details(
    p_result_id INTEGER,
    p_new_details JSONB,
    p_implementation_status VARCHAR(50) DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_old_details JSONB;
    v_updated_details JSONB;
BEGIN
    -- Get existing details
    SELECT details INTO v_old_details FROM optimization_results WHERE result_id = p_result_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Optimization result with ID % not found', p_result_id;
    END IF;
    
    -- Merge details
    v_updated_details := COALESCE(v_old_details, '{}'::jsonb) || p_new_details;
    
    -- Add implementation status if provided
    IF p_implementation_status IS NOT NULL THEN
        v_updated_details := v_updated_details || jsonb_build_object('implementation_status', p_implementation_status);
    END IF;
    
    -- Update record
    UPDATE optimization_results 
    SET details = v_updated_details
    WHERE result_id = p_result_id;
    
    RETURN jsonb_build_object(
        'result_id', p_result_id,
        'old_details', v_old_details,
        'new_details', v_updated_details,
        'status', 'updated',
        'message', 'Optimization result details updated successfully'
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 3. PERFORMANCE METRICS API (performance_metrics table)
-- =============================================================================

-- Record performance metrics
CREATE OR REPLACE FUNCTION record_performance_metrics(
    p_algorithm_name VARCHAR(100),
    p_execution_time_ms DOUBLE PRECISION,
    p_memory_usage_mb DOUBLE PRECISION,
    p_cpu_utilization DOUBLE PRECISION
) RETURNS JSONB AS $$
DECLARE
    v_metric_id INTEGER;
    v_result JSONB;
BEGIN
    -- Validate input parameters
    IF p_execution_time_ms < 0 THEN
        RAISE EXCEPTION 'Execution time cannot be negative';
    END IF;
    
    IF p_memory_usage_mb < 0 THEN
        RAISE EXCEPTION 'Memory usage cannot be negative';
    END IF;
    
    IF p_cpu_utilization < 0 OR p_cpu_utilization > 100 THEN
        RAISE EXCEPTION 'CPU utilization must be between 0 and 100';
    END IF;
    
    -- Insert performance metrics
    INSERT INTO performance_metrics (
        algorithm_name, execution_time_ms, memory_usage_mb, cpu_utilization
    ) VALUES (
        p_algorithm_name, p_execution_time_ms, p_memory_usage_mb, p_cpu_utilization
    ) RETURNING metric_id INTO v_metric_id;
    
    v_result := jsonb_build_object(
        'metric_id', v_metric_id,
        'algorithm_name', p_algorithm_name,
        'execution_time_ms', p_execution_time_ms,
        'memory_usage_mb', p_memory_usage_mb,
        'cpu_utilization', p_cpu_utilization,
        'timestamp', CURRENT_TIMESTAMP,
        'status', 'recorded',
        'message', 'Performance metrics recorded successfully'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Get performance metrics statistics
CREATE OR REPLACE FUNCTION get_performance_metrics_stats(
    p_algorithm_name VARCHAR(100),
    p_hours_back INTEGER DEFAULT 24
) RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_recent_metrics JSONB;
    v_total_records INTEGER;
BEGIN
    -- Get aggregated statistics
    WITH metrics_stats AS (
        SELECT 
            COUNT(*) as total_executions,
            AVG(execution_time_ms) as avg_execution_time,
            MIN(execution_time_ms) as min_execution_time,
            MAX(execution_time_ms) as max_execution_time,
            AVG(memory_usage_mb) as avg_memory_usage,
            MAX(memory_usage_mb) as peak_memory_usage,
            AVG(cpu_utilization) as avg_cpu_utilization,
            MAX(cpu_utilization) as peak_cpu_utilization
        FROM performance_metrics
        WHERE algorithm_name = p_algorithm_name
          AND timestamp >= CURRENT_TIMESTAMP - (p_hours_back || ' hours')::INTERVAL
    ),
    recent_executions AS (
        SELECT jsonb_agg(
            jsonb_build_object(
                'metric_id', metric_id,
                'execution_time_ms', execution_time_ms,
                'memory_usage_mb', memory_usage_mb,
                'cpu_utilization', cpu_utilization,
                'timestamp', timestamp
            ) ORDER BY timestamp DESC
        ) as recent_data
        FROM (
            SELECT * FROM performance_metrics
            WHERE algorithm_name = p_algorithm_name
              AND timestamp >= CURRENT_TIMESTAMP - (p_hours_back || ' hours')::INTERVAL
            ORDER BY timestamp DESC
            LIMIT 20
        ) recent
    )
    SELECT 
        jsonb_build_object(
            'algorithm_name', p_algorithm_name,
            'hours_analyzed', p_hours_back,
            'total_executions', COALESCE(ms.total_executions, 0),
            'avg_execution_time_ms', COALESCE(ROUND(ms.avg_execution_time::NUMERIC, 2), 0),
            'min_execution_time_ms', COALESCE(ms.min_execution_time, 0),
            'max_execution_time_ms', COALESCE(ms.max_execution_time, 0),
            'avg_memory_usage_mb', COALESCE(ROUND(ms.avg_memory_usage::NUMERIC, 2), 0),
            'peak_memory_usage_mb', COALESCE(ms.peak_memory_usage, 0),
            'avg_cpu_utilization', COALESCE(ROUND(ms.avg_cpu_utilization::NUMERIC, 2), 0),
            'peak_cpu_utilization', COALESCE(ms.peak_cpu_utilization, 0)
        ),
        re.recent_data,
        COALESCE(ms.total_executions, 0)
    INTO v_stats, v_recent_metrics, v_total_records
    FROM metrics_stats ms
    CROSS JOIN recent_executions re;
    
    RETURN jsonb_build_object(
        'statistics', v_stats,
        'recent_metrics', COALESCE(v_recent_metrics, '[]'::jsonb),
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql;

-- Compare algorithm performance
CREATE OR REPLACE FUNCTION compare_algorithm_performance(
    p_algorithm_names VARCHAR(100)[],
    p_hours_back INTEGER DEFAULT 24
) RETURNS JSONB AS $$
DECLARE
    v_comparison JSONB;
    alg_name VARCHAR(100);
BEGIN
    -- Build comparison data
    WITH algorithm_stats AS (
        SELECT 
            algorithm_name,
            COUNT(*) as total_executions,
            ROUND(AVG(execution_time_ms)::NUMERIC, 2) as avg_execution_time_ms,
            ROUND(AVG(memory_usage_mb)::NUMERIC, 2) as avg_memory_usage_mb,
            ROUND(AVG(cpu_utilization)::NUMERIC, 2) as avg_cpu_utilization,
            ROUND(
                (100 - (AVG(execution_time_ms) / 1000 + AVG(memory_usage_mb) / 100 + AVG(cpu_utilization)) / 3)::NUMERIC, 2
            ) as performance_score
        FROM performance_metrics
        WHERE algorithm_name = ANY(p_algorithm_names)
          AND timestamp >= CURRENT_TIMESTAMP - (p_hours_back || ' hours')::INTERVAL
        GROUP BY algorithm_name
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'algorithm_name', algorithm_name,
            'total_executions', total_executions,
            'avg_execution_time_ms', avg_execution_time_ms,
            'avg_memory_usage_mb', avg_memory_usage_mb,
            'avg_cpu_utilization', avg_cpu_utilization,
            'performance_score', performance_score
        ) ORDER BY total_executions DESC
    ) INTO v_comparison
    FROM algorithm_stats;
    
    RETURN jsonb_build_object(
        'algorithms_compared', array_length(p_algorithm_names, 1),
        'hours_analyzed', p_hours_back,
        'comparison_data', COALESCE(v_comparison, '[]'::jsonb),
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 4. EMPLOYEE PREFERENCES API (employee_preferences table)
-- =============================================================================

-- Create or update employee preferences
CREATE OR REPLACE FUNCTION upsert_employee_preferences(
    p_employee_id VARCHAR(50),
    p_preferred_start TIME,
    p_preferred_end TIME,
    p_preferred_days VARCHAR(20),
    p_max_consecutive_days INTEGER,
    p_min_hours_week DOUBLE PRECISION,
    p_max_hours_week DOUBLE PRECISION
) RETURNS JSONB AS $$
DECLARE
    v_preference_id INTEGER;
    v_is_update BOOLEAN := false;
    v_result JSONB;
BEGIN
    -- Validate input parameters
    IF p_preferred_start >= p_preferred_end THEN
        RAISE EXCEPTION 'Preferred start time must be before end time';
    END IF;
    
    IF p_max_consecutive_days <= 0 OR p_max_consecutive_days > 31 THEN
        RAISE EXCEPTION 'Max consecutive days must be between 1 and 31';
    END IF;
    
    IF p_min_hours_week < 0 OR p_min_hours_week > 168 THEN
        RAISE EXCEPTION 'Min hours per week must be between 0 and 168';
    END IF;
    
    IF p_max_hours_week < 0 OR p_max_hours_week > 168 THEN
        RAISE EXCEPTION 'Max hours per week must be between 0 and 168';
    END IF;
    
    IF p_min_hours_week > p_max_hours_week THEN
        RAISE EXCEPTION 'Min hours per week cannot exceed max hours per week';
    END IF;
    
    -- Check if preferences already exist
    SELECT preference_id INTO v_preference_id 
    FROM employee_preferences 
    WHERE employee_id = p_employee_id;
    
    IF FOUND THEN
        v_is_update := true;
        -- Update existing preferences
        UPDATE employee_preferences SET
            preferred_start = p_preferred_start,
            preferred_end = p_preferred_end,
            preferred_days = p_preferred_days,
            max_consecutive_days = p_max_consecutive_days,
            min_hours_week = p_min_hours_week,
            max_hours_week = p_max_hours_week
        WHERE employee_id = p_employee_id;
    ELSE
        -- Insert new preferences
        INSERT INTO employee_preferences (
            employee_id, preferred_start, preferred_end, preferred_days,
            max_consecutive_days, min_hours_week, max_hours_week
        ) VALUES (
            p_employee_id, p_preferred_start, p_preferred_end, p_preferred_days,
            p_max_consecutive_days, p_min_hours_week, p_max_hours_week
        ) RETURNING preference_id INTO v_preference_id;
    END IF;
    
    v_result := jsonb_build_object(
        'preference_id', v_preference_id,
        'employee_id', p_employee_id,
        'preferred_start', p_preferred_start,
        'preferred_end', p_preferred_end,
        'preferred_days', p_preferred_days,
        'max_consecutive_days', p_max_consecutive_days,
        'min_hours_week', p_min_hours_week,
        'max_hours_week', p_max_hours_week,
        'operation', CASE WHEN v_is_update THEN 'updated' ELSE 'created' END,
        'status', 'success',
        'message', CASE WHEN v_is_update THEN 'Employee preferences updated successfully' 
                        ELSE 'Employee preferences created successfully' END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Get employee preferences with schedule compatibility
CREATE OR REPLACE FUNCTION get_employee_preferences_with_compatibility(
    p_employee_id VARCHAR(50)
) RETURNS JSONB AS $$
DECLARE
    v_preferences RECORD;
    v_result JSONB;
    v_weekly_hours_range JSONB;
    v_availability_summary JSONB;
BEGIN
    -- Get employee preferences
    SELECT * INTO v_preferences 
    FROM employee_preferences 
    WHERE employee_id = p_employee_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'employee_id', p_employee_id,
            'preferences_found', false,
            'status', 'not_found',
            'message', 'No preferences found for employee ' || p_employee_id
        );
    END IF;
    
    -- Calculate weekly hours range
    v_weekly_hours_range := jsonb_build_object(
        'min_hours', v_preferences.min_hours_week,
        'max_hours', v_preferences.max_hours_week,
        'range_flexibility', v_preferences.max_hours_week - v_preferences.min_hours_week,
        'daily_avg_min', ROUND((v_preferences.min_hours_week / 7)::NUMERIC, 2),
        'daily_avg_max', ROUND((v_preferences.max_hours_week / 7)::NUMERIC, 2)
    );
    
    -- Create availability summary
    v_availability_summary := jsonb_build_object(
        'preferred_shift_duration', 
        EXTRACT(EPOCH FROM (v_preferences.preferred_end - v_preferences.preferred_start)) / 3600,
        'preferred_days', v_preferences.preferred_days,
        'max_consecutive_work_days', v_preferences.max_consecutive_days,
        'schedule_flexibility', 
        CASE 
            WHEN v_preferences.max_consecutive_days >= 6 AND 
                 (v_preferences.max_hours_week - v_preferences.min_hours_week) >= 20 
            THEN 'высокая'
            WHEN v_preferences.max_consecutive_days >= 4 AND 
                 (v_preferences.max_hours_week - v_preferences.min_hours_week) >= 10 
            THEN 'средняя'
            ELSE 'низкая'
        END
    );
    
    v_result := jsonb_build_object(
        'preference_id', v_preferences.preference_id,
        'employee_id', v_preferences.employee_id,
        'preferred_start', v_preferences.preferred_start,
        'preferred_end', v_preferences.preferred_end,
        'preferred_days', v_preferences.preferred_days,
        'max_consecutive_days', v_preferences.max_consecutive_days,
        'weekly_hours', v_weekly_hours_range,
        'availability_summary', v_availability_summary,
        'preferences_found', true,
        'status', 'success'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Get employees by preference criteria
CREATE OR REPLACE FUNCTION find_employees_by_preferences(
    p_required_start_time TIME DEFAULT NULL,
    p_required_end_time TIME DEFAULT NULL,
    p_required_days VARCHAR(20) DEFAULT NULL,
    p_min_availability_hours DOUBLE PRECISION DEFAULT NULL,
    p_max_consecutive_days INTEGER DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_matching_employees JSONB;
    v_total_matches INTEGER;
BEGIN
    WITH filtered_preferences AS (
        SELECT 
            ep.*,
            EXTRACT(EPOCH FROM (ep.preferred_end - ep.preferred_start)) / 3600 as daily_availability_hours
        FROM employee_preferences ep
        WHERE (p_required_start_time IS NULL OR ep.preferred_start <= p_required_start_time)
          AND (p_required_end_time IS NULL OR ep.preferred_end >= p_required_end_time)
          AND (p_required_days IS NULL OR ep.preferred_days LIKE '%' || p_required_days || '%')
          AND (p_min_availability_hours IS NULL OR ep.max_hours_week >= p_min_availability_hours)
          AND (p_max_consecutive_days IS NULL OR ep.max_consecutive_days >= p_max_consecutive_days)
    )
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'employee_id', employee_id,
                'preferred_start', preferred_start,
                'preferred_end', preferred_end,
                'preferred_days', preferred_days,
                'max_consecutive_days', max_consecutive_days,
                'min_hours_week', min_hours_week,
                'max_hours_week', max_hours_week,
                'daily_availability_hours', daily_availability_hours,
                'flexibility_score', 
                    ROUND(((max_hours_week - min_hours_week) / 10 + max_consecutive_days * 2 + daily_availability_hours)::NUMERIC, 2)
            ) ORDER BY max_hours_week DESC, max_consecutive_days DESC
        ),
        COUNT(*)
    INTO v_matching_employees, v_total_matches
    FROM filtered_preferences;
    
    RETURN jsonb_build_object(
        'search_criteria', jsonb_build_object(
            'required_start_time', p_required_start_time,
            'required_end_time', p_required_end_time,
            'required_days', p_required_days,
            'min_availability_hours', p_min_availability_hours,
            'max_consecutive_days', p_max_consecutive_days
        ),
        'total_matches', COALESCE(v_total_matches, 0),
        'matching_employees', COALESCE(v_matching_employees, '[]'::jsonb),
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql;

-- Delete employee preferences
CREATE OR REPLACE FUNCTION delete_employee_preferences(
    p_employee_id VARCHAR(50)
) RETURNS JSONB AS $$
DECLARE
    v_deleted_count INTEGER;
    v_old_preferences RECORD;
BEGIN
    -- Get existing preferences for confirmation
    SELECT * INTO v_old_preferences 
    FROM employee_preferences 
    WHERE employee_id = p_employee_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'employee_id', p_employee_id,
            'status', 'not_found',
            'message', 'No preferences found for employee ' || p_employee_id
        );
    END IF;
    
    -- Delete preferences
    DELETE FROM employee_preferences WHERE employee_id = p_employee_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'employee_id', p_employee_id,
        'deleted_preferences', jsonb_build_object(
            'preference_id', v_old_preferences.preference_id,
            'preferred_start', v_old_preferences.preferred_start,
            'preferred_end', v_old_preferences.preferred_end,
            'preferred_days', v_old_preferences.preferred_days,
            'max_consecutive_days', v_old_preferences.max_consecutive_days,
            'min_hours_week', v_old_preferences.min_hours_week,
            'max_hours_week', v_old_preferences.max_hours_week
        ),
        'records_deleted', v_deleted_count,
        'status', 'deleted',
        'message', 'Employee preferences deleted successfully'
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- REALISTIC TEST DATA GENERATION (Russian WFM Environment)
-- =============================================================================

-- Insert realistic forecast data
INSERT INTO forecast_data (service_id, forecast_date, interval_start, call_volume, average_handle_time, service_level_target) VALUES
-- Техническая поддержка (Service ID 1) - рабочий день
(1, '2025-01-15', '09:00:00', 45, 320, 80.00),
(1, '2025-01-15', '09:30:00', 52, 315, 80.00),
(1, '2025-01-15', '10:00:00', 61, 310, 80.00),
(1, '2025-01-15', '10:30:00', 68, 325, 80.00),
(1, '2025-01-15', '11:00:00', 72, 330, 80.00),
(1, '2025-01-15', '11:30:00', 75, 335, 80.00),
(1, '2025-01-15', '12:00:00', 58, 340, 80.00), -- Обеденный спад
(1, '2025-01-15', '12:30:00', 49, 345, 80.00),
(1, '2025-01-15', '13:00:00', 41, 350, 80.00),
(1, '2025-01-15', '13:30:00', 38, 340, 80.00),
(1, '2025-01-15', '14:00:00', 55, 335, 80.00), -- Пост-обеденный рост
(1, '2025-01-15', '14:30:00', 67, 330, 80.00),
(1, '2025-01-15', '15:00:00', 71, 325, 80.00),
(1, '2025-01-15', '15:30:00', 69, 320, 80.00),
(1, '2025-01-15', '16:00:00', 64, 315, 80.00),
(1, '2025-01-15', '16:30:00', 58, 310, 80.00),
(1, '2025-01-15', '17:00:00', 51, 305, 80.00),
(1, '2025-01-15', '17:30:00', 43, 300, 80.00),

-- Отдел продаж (Service ID 2) - интенсивный график
(2, '2025-01-15', '09:00:00', 89, 480, 85.00),
(2, '2025-01-15', '09:30:00', 95, 475, 85.00),
(2, '2025-01-15', '10:00:00', 103, 470, 85.00),
(2, '2025-01-15', '10:30:00', 112, 485, 85.00),
(2, '2025-01-15', '11:00:00', 118, 490, 85.00),
(2, '2025-01-15', '11:30:00', 125, 495, 85.00),
(2, '2025-01-15', '12:00:00', 98, 500, 85.00),
(2, '2025-01-15', '12:30:00', 87, 505, 85.00),
(2, '2025-01-15', '13:00:00', 76, 510, 85.00),
(2, '2025-01-15', '13:30:00', 82, 500, 85.00),
(2, '2025-01-15', '14:00:00', 94, 495, 85.00),
(2, '2025-01-15', '14:30:00', 108, 490, 85.00),
(2, '2025-01-15', '15:00:00', 121, 485, 85.00),
(2, '2025-01-15', '15:30:00', 119, 480, 85.00),
(2, '2025-01-15', '16:00:00', 115, 475, 85.00),
(2, '2025-01-15', '16:30:00', 109, 470, 85.00),
(2, '2025-01-15', '17:00:00', 98, 465, 85.00),
(2, '2025-01-15', '17:30:00', 91, 460, 85.00);

-- Insert optimization results
INSERT INTO optimization_results (request_id, suggestion_type, impact_score, cost_impact, implementation_complexity, details) VALUES
('opt_req_001', 'Перераспределение смен', 87.5, -15000.00, 'средняя', '{
    "description": "Оптимизация расписания технической поддержки",
    "current_agents": 12,
    "recommended_agents": 10,
    "time_slots_affected": ["09:00-11:00", "14:00-16:00"],
    "expected_service_level": 82.3,
    "implementation_steps": ["Анализ нагрузки", "Перераспределение", "Тестирование"],
    "risk_level": "низкий"
}'::jsonb),
('opt_req_001', 'Гибкие рабочие часы', 92.1, -22000.00, 'высокая', '{
    "description": "Внедрение гибкого графика для отдела продаж",
    "affected_employees": 25,
    "flexibility_options": ["Скользящий график", "Удаленная работа", "Частичная занятость"],
    "expected_productivity_increase": 15.8,
    "customer_satisfaction_impact": 8.5,
    "training_required_hours": 40
}'::jsonb),
('opt_req_002', 'Автоматизация маршрутизации', 78.9, -8500.00, 'низкая', '{
    "description": "Улучшение алгоритма распределения звонков",
    "current_routing_efficiency": 68.4,
    "predicted_efficiency": 84.7,
    "technologies": ["Machine Learning", "Real-time Analytics"],
    "implementation_time_weeks": 6,
    "roi_months": 8
}'::jsonb),
('opt_req_003', 'Обучение персонала', 85.3, -12000.00, 'средняя', '{
    "description": "Программа повышения квалификации операторов",
    "target_groups": ["Новые сотрудники", "Технические специалисты"],
    "training_modules": ["Продуктовое обучение", "Soft skills", "Системы CRM"],
    "expected_aht_reduction": 25,
    "quality_score_improvement": 12.5,
    "training_duration_days": 5
}'::jsonb);

-- Insert performance metrics
INSERT INTO performance_metrics (algorithm_name, execution_time_ms, memory_usage_mb, cpu_utilization) VALUES
('Erlang C Calculator', 125.7, 45.2, 23.5),
('Erlang C Calculator', 118.9, 43.8, 21.2),
('Erlang C Calculator', 132.1, 46.7, 25.8),
('Erlang C Calculator', 119.3, 44.1, 22.1),
('Erlang C Calculator', 127.8, 45.9, 24.3),
('Schedule Optimizer', 2847.3, 256.8, 78.9),
('Schedule Optimizer', 2923.1, 261.4, 82.1),
('Schedule Optimizer', 2789.5, 248.7, 76.3),
('Schedule Optimizer', 3012.8, 267.2, 85.4),
('Schedule Optimizer', 2856.9, 253.9, 79.7),
('Forecast Algorithm', 567.2, 89.3, 45.6),
('Forecast Algorithm', 589.7, 92.1, 47.8),
('Forecast Algorithm', 545.8, 86.7, 43.2),
('Forecast Algorithm', 576.3, 90.5, 46.1),
('Forecast Algorithm', 558.9, 88.2, 44.9),
('Real-time Monitoring', 89.4, 28.7, 15.3),
('Real-time Monitoring', 92.1, 29.3, 16.1),
('Real-time Monitoring', 87.6, 27.9, 14.8),
('Real-time Monitoring', 94.3, 30.1, 17.2),
('Real-time Monitoring', 90.8, 28.5, 15.7),
('Gap Analysis Engine', 1234.5, 123.4, 56.7),
('Gap Analysis Engine', 1289.7, 128.9, 59.2),
('Gap Analysis Engine', 1198.3, 119.8, 54.1),
('Gap Analysis Engine', 1267.1, 126.7, 58.4),
('Gap Analysis Engine', 1221.9, 122.2, 55.8);

-- Insert employee preferences
INSERT INTO employee_preferences (employee_id, preferred_start, preferred_end, preferred_days, max_consecutive_days, min_hours_week, max_hours_week) VALUES
('EMP001', '08:00:00', '17:00:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 35.0, 40.0),
('EMP002', '09:00:00', '18:00:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 40.0, 45.0),
('EMP003', '10:00:00', '19:00:00', 'ВТ,СР,ЧТ,ПТ,СБ', 6, 32.0, 38.0),
('EMP004', '07:00:00', '16:00:00', 'ПН,ВТ,СР,ЧТ,ПТ,СБ', 6, 38.0, 42.0),
('EMP005', '11:00:00', '20:00:00', 'СР,ЧТ,ПТ,СБ,ВС', 5, 30.0, 35.0),
('EMP006', '08:30:00', '17:30:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 40.0, 40.0),
('EMP007', '12:00:00', '21:00:00', 'ЧТ,ПТ,СБ,ВС,ПН', 7, 35.0, 45.0),
('EMP008', '06:00:00', '15:00:00', 'ПН,ВТ,СР,ЧТ,ПТ,СБ', 6, 42.0, 48.0),
('EMP009', '14:00:00', '23:00:00', 'ВТ,СР,ЧТ,ПТ,СБ', 5, 30.0, 40.0),
('EMP010', '09:30:00', '18:30:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 37.5, 42.5),
('EMP011', '13:00:00', '22:00:00', 'СР,ЧТ,ПТ,СБ,ВС,ПН', 6, 32.0, 36.0),
('EMP012', '07:30:00', '16:30:00', 'ПН,ВТ,СР,ЧТ,ПТ,СБ', 6, 40.0, 45.0);

-- =============================================================================
-- EXAMPLE API USAGE AND TESTING
-- =============================================================================

-- Test forecast data operations
SELECT create_forecast_data(1, '2025-01-16', '09:00:00', 55, 300, 82.5);
SELECT get_forecast_data_by_date_range(1, '2025-01-15', '2025-01-16', NULL);
SELECT update_forecast_data(1, 60, 295, 83.0);

-- Test optimization results
SELECT create_optimization_result(
    'opt_req_004', 
    'Оптимизация перерывов', 
    89.2, 
    -18000.00, 
    'низкая',
    '{"description": "Система автоматического планирования перерывов", "benefit": "Улучшение работы персонала"}'::jsonb
);
SELECT get_optimization_results_by_request('opt_req_001', 80.0);

-- Test performance metrics
SELECT record_performance_metrics('New Algorithm Test', 345.6, 67.8, 34.2);
SELECT get_performance_metrics_stats('Erlang C Calculator', 24);
SELECT compare_algorithm_performance(ARRAY['Erlang C Calculator', 'Schedule Optimizer', 'Forecast Algorithm'], 48);

-- Test employee preferences
SELECT upsert_employee_preferences('EMP013', '08:00:00', '17:00:00', 'ПН,ВТ,СР,ЧТ,ПТ', 5, 40.0, 44.0);
SELECT get_employee_preferences_with_compatibility('EMP001');
SELECT find_employees_by_preferences('08:00:00', '18:00:00', 'ПН', 35.0, 5);

-- =============================================================================
-- API CONTRACT DOCUMENTATION AND COMMENTS
-- =============================================================================

COMMENT ON FUNCTION create_forecast_data IS 'Создает новую запись прогноза с валидацией параметров и ограничениями целостности данных';
COMMENT ON FUNCTION get_forecast_data_by_date_range IS 'Получает данные прогнозов за указанный диапазон дат с агрегированной статистикой';
COMMENT ON FUNCTION update_forecast_data IS 'Обновляет существующие данные прогноза с отслеживанием изменений и валидацией';
COMMENT ON FUNCTION delete_forecast_data_by_date_range IS 'Удаляет данные прогнозов за указанный период с подтверждением количества удаленных записей';

COMMENT ON FUNCTION create_optimization_result IS 'Создает результат оптимизации с валидацией оценки влияния и сложности реализации';
COMMENT ON FUNCTION get_optimization_results_by_request IS 'Получает результаты оптимизации по запросу с фильтрацией по минимальной оценке влияния';
COMMENT ON FUNCTION update_optimization_result_details IS 'Обновляет детали результата оптимизации с объединением JSONB данных';

COMMENT ON FUNCTION record_performance_metrics IS 'Записывает метрики производительности алгоритма с валидацией ресурсных показателей';
COMMENT ON FUNCTION get_performance_metrics_stats IS 'Получает статистику производительности алгоритма за указанный период с агрегацией';
COMMENT ON FUNCTION compare_algorithm_performance IS 'Сравнивает производительность нескольких алгоритмов с расчетом интегрального показателя';

COMMENT ON FUNCTION upsert_employee_preferences IS 'Создает или обновляет предпочтения сотрудника с полной валидацией рабочего времени';
COMMENT ON FUNCTION get_employee_preferences_with_compatibility IS 'Получает предпочтения сотрудника с анализом совместимости расписания';
COMMENT ON FUNCTION find_employees_by_preferences IS 'Находит сотрудников по критериям предпочтений с оценкой гибкости графика';
COMMENT ON FUNCTION delete_employee_preferences IS 'Удаляет предпочтения сотрудника с подтверждением и архивированием данных';

-- =============================================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- =============================================================================

-- Forecast data indexes for time-series queries
CREATE INDEX IF NOT EXISTS idx_forecast_data_service_date_interval ON forecast_data (service_id, forecast_date, interval_start);
CREATE INDEX IF NOT EXISTS idx_forecast_data_date_volume ON forecast_data (forecast_date, call_volume);

-- Optimization results indexes for request-based queries
CREATE INDEX IF NOT EXISTS idx_optimization_results_request_impact ON optimization_results (request_id, impact_score DESC);
CREATE INDEX IF NOT EXISTS idx_optimization_results_suggestion_type ON optimization_results (suggestion_type, created_at DESC);

-- Performance metrics indexes for algorithm analysis
CREATE INDEX IF NOT EXISTS idx_performance_metrics_algorithm_timestamp ON performance_metrics (algorithm_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_execution_time ON performance_metrics (execution_time_ms, memory_usage_mb);

-- Employee preferences indexes for scheduling queries
CREATE INDEX IF NOT EXISTS idx_employee_preferences_employee_id ON employee_preferences (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_time_range ON employee_preferences (preferred_start, preferred_end);
CREATE INDEX IF NOT EXISTS idx_employee_preferences_hours_flexibility ON employee_preferences (max_hours_week DESC, max_consecutive_days DESC);

-- =============================================================================
-- INTEGRATION POINTS WITH OTHER WFM SYSTEMS
-- =============================================================================

COMMENT ON TABLE forecast_data IS 'Интеграция: Argus WFM (импорт прогнозов), 1C ZUP (экспорт планов), Dashboard (визуализация)';
COMMENT ON TABLE optimization_results IS 'Интеграция: ML Engine (результаты), Business Intelligence (отчеты), Manager Dashboard (рекомендации)';
COMMENT ON TABLE performance_metrics IS 'Интеграция: Monitoring System (метрики), DevOps Dashboard (производительность), Capacity Planning (планирование)';
COMMENT ON TABLE employee_preferences IS 'Интеграция: HR System (профили), Schedule Builder (ограничения), Mobile App (пользовательские настройки)';