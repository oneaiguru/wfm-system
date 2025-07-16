-- =================================================================
-- Forecast Accuracy MAPE/WAPE Calculation Implementation
-- BDD Scenario: Analyze Forecast Accuracy Performance
-- =================================================================

-- Function to calculate MAPE (Mean Absolute Percentage Error)
CREATE OR REPLACE FUNCTION calculate_mape(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_mape NUMERIC(5,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0  -- Avoid division by zero
    ),
    percentage_errors AS (
        SELECT 
            ABS(forecast_value - actual_value) / actual_value::numeric * 100 as percentage_error
        FROM forecast_vs_actual
        WHERE actual_value > 0
    )
    SELECT ROUND(AVG(percentage_error), 2) INTO v_mape
    FROM percentage_errors;
    
    RETURN COALESCE(v_mape, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate WAPE (Weighted Absolute Percentage Error)
CREATE OR REPLACE FUNCTION calculate_wape(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_wape NUMERIC(5,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0
    )
    SELECT ROUND(
        (SUM(ABS(forecast_value - actual_value)) / SUM(actual_value)::numeric) * 100, 
        2
    ) INTO v_wape
    FROM forecast_vs_actual
    WHERE actual_value > 0;
    
    RETURN COALESCE(v_wape, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate MFA (Mean Forecast Accuracy)
CREATE OR REPLACE FUNCTION calculate_mfa(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_mfa NUMERIC(5,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0
    ),
    accuracy_values AS (
        SELECT 
            100 - (ABS(forecast_value - actual_value) / actual_value::numeric * 100) as accuracy
        FROM forecast_vs_actual
        WHERE actual_value > 0
    )
    SELECT ROUND(AVG(accuracy), 2) INTO v_mfa
    FROM accuracy_values;
    
    RETURN COALESCE(v_mfa, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate WFA (Weighted Forecast Accuracy)
CREATE OR REPLACE FUNCTION calculate_wfa(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_wfa NUMERIC(5,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0
    )
    SELECT ROUND(
        100 - ((SUM(ABS(forecast_value - actual_value)) / SUM(actual_value)::numeric) * 100), 
        2
    ) INTO v_wfa
    FROM forecast_vs_actual
    WHERE actual_value > 0;
    
    RETURN COALESCE(v_wfa, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate Bias
CREATE OR REPLACE FUNCTION calculate_bias(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_bias NUMERIC(5,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0
    ),
    bias_values AS (
        SELECT 
            (forecast_value - actual_value) / actual_value::numeric * 100 as bias_pct
        FROM forecast_vs_actual
        WHERE actual_value > 0
    )
    SELECT ROUND(AVG(bias_pct), 2) INTO v_bias
    FROM bias_values;
    
    RETURN COALESCE(v_bias, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate Tracking Signal
CREATE OR REPLACE FUNCTION calculate_tracking_signal(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_tracking_signal NUMERIC(5,2);
    v_cumulative_bias NUMERIC(10,2);
    v_mad NUMERIC(10,2);
BEGIN
    WITH forecast_vs_actual AS (
        SELECT 
            f.forecast_date,
            f.call_volume as forecast_value,
            COALESCE(cs.received_calls, 0) as actual_value
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
            AND cs.received_calls > 0
        ORDER BY f.forecast_date
    ),
    error_calculations AS (
        SELECT 
            forecast_value - actual_value as error,
            ABS(forecast_value - actual_value) as abs_error
        FROM forecast_vs_actual
        WHERE actual_value > 0
    ),
    error_stats AS (
        SELECT 
            SUM(error) as cumulative_bias,
            AVG(abs_error) as mean_abs_deviation
        FROM error_calculations
    )
    SELECT 
        cumulative_bias,
        mean_abs_deviation
    INTO v_cumulative_bias, v_mad
    FROM error_stats;
    
    IF v_mad > 0 THEN
        v_tracking_signal := v_cumulative_bias / v_mad;
    ELSE
        v_tracking_signal := 0;
    END IF;
    
    RETURN ROUND(v_tracking_signal, 2);
END;
$$ LANGUAGE plpgsql;

-- Main function to run complete forecast accuracy analysis
CREATE OR REPLACE FUNCTION run_forecast_accuracy_analysis(
    p_start_date DATE,
    p_end_date DATE,
    p_granularity VARCHAR(20) DEFAULT 'Daily'
) RETURNS UUID AS $$
DECLARE
    v_analysis_id UUID;
    v_mape NUMERIC(5,2);
    v_wape NUMERIC(5,2);
    v_mfa NUMERIC(5,2);
    v_wfa NUMERIC(5,2);
    v_bias NUMERIC(5,2);
    v_tracking_signal NUMERIC(5,2);
    v_drill_down_data JSONB;
BEGIN
    -- Generate new analysis ID
    v_analysis_id := uuid_generate_v4();
    
    -- Calculate all metrics
    v_mape := calculate_mape(p_start_date, p_end_date, p_granularity);
    v_wape := calculate_wape(p_start_date, p_end_date, p_granularity);
    v_mfa := calculate_mfa(p_start_date, p_end_date, p_granularity);
    v_wfa := calculate_wfa(p_start_date, p_end_date, p_granularity);
    v_bias := calculate_bias(p_start_date, p_end_date, p_granularity);
    v_tracking_signal := calculate_tracking_signal(p_start_date, p_end_date, p_granularity);
    
    -- Generate drill-down data
    SELECT jsonb_build_object(
        'interval_analysis', interval_drill_down.data,
        'daily_analysis', daily_drill_down.data,
        'weekly_analysis', weekly_drill_down.data,
        'monthly_analysis', monthly_drill_down.data,
        'channel_analysis', channel_drill_down.data
    ) INTO v_drill_down_data
    FROM (
        -- 15-minute interval analysis
        SELECT jsonb_agg(
            jsonb_build_object(
                'interval_start', interval_start_time,
                'forecast', f.call_volume,
                'actual', cs.received_calls,
                'error_pct', CASE 
                    WHEN cs.received_calls > 0 
                    THEN ROUND(ABS(f.call_volume - cs.received_calls) / cs.received_calls * 100, 2)
                    ELSE 0 
                END
            )
        ) as data
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
        LIMIT 100  -- Limit for performance
    ) interval_drill_down,
    (
        -- Daily analysis
        SELECT jsonb_agg(
            jsonb_build_object(
                'date', forecast_date,
                'forecast_total', SUM(f.call_volume),
                'actual_total', SUM(COALESCE(cs.received_calls, 0)),
                'daily_mape', ROUND(AVG(
                    CASE 
                        WHEN cs.received_calls > 0 
                        THEN ABS(f.call_volume - cs.received_calls) / cs.received_calls * 100
                        ELSE 0 
                    END
                ), 2)
            )
        ) as data
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
        GROUP BY forecast_date
        ORDER BY forecast_date
    ) daily_drill_down,
    (
        -- Weekly analysis
        SELECT jsonb_agg(
            jsonb_build_object(
                'week_start', DATE_TRUNC('week', forecast_date),
                'forecast_total', SUM(f.call_volume),
                'actual_total', SUM(COALESCE(cs.received_calls, 0)),
                'weekly_mape', ROUND(AVG(
                    CASE 
                        WHEN cs.received_calls > 0 
                        THEN ABS(f.call_volume - cs.received_calls) / cs.received_calls * 100
                        ELSE 0 
                    END
                ), 2)
            )
        ) as data
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
        GROUP BY DATE_TRUNC('week', forecast_date)
        ORDER BY DATE_TRUNC('week', forecast_date)
    ) weekly_drill_down,
    (
        -- Monthly analysis
        SELECT jsonb_agg(
            jsonb_build_object(
                'month', DATE_TRUNC('month', forecast_date),
                'forecast_total', SUM(f.call_volume),
                'actual_total', SUM(COALESCE(cs.received_calls, 0)),
                'monthly_mape', ROUND(AVG(
                    CASE 
                        WHEN cs.received_calls > 0 
                        THEN ABS(f.call_volume - cs.received_calls) / cs.received_calls * 100
                        ELSE 0 
                    END
                ), 2)
            )
        ) as data
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
        GROUP BY DATE_TRUNC('month', forecast_date)
        ORDER BY DATE_TRUNC('month', forecast_date)
    ) monthly_drill_down,
    (
        -- Channel analysis
        SELECT jsonb_agg(
            jsonb_build_object(
                'service_id', f.service_id,
                'forecast_total', SUM(f.call_volume),
                'actual_total', SUM(COALESCE(cs.received_calls, 0)),
                'channel_mape', ROUND(AVG(
                    CASE 
                        WHEN cs.received_calls > 0 
                        THEN ABS(f.call_volume - cs.received_calls) / cs.received_calls * 100
                        ELSE 0 
                    END
                ), 2)
            )
        ) as data
        FROM forecast_data f
        LEFT JOIN contact_statistics cs ON 
            f.service_id = cs.service_id 
            AND DATE(cs.interval_start_time) = f.forecast_date
        WHERE f.forecast_date BETWEEN p_start_date AND p_end_date
        GROUP BY f.service_id
        ORDER BY f.service_id
    ) channel_drill_down;
    
    -- Insert analysis results
    INSERT INTO forecast_accuracy_analysis (
        id,
        analysis_period_start,
        analysis_period_end,
        granularity_level,
        mape,
        wape,
        mfa,
        wfa,
        bias,
        tracking_signal,
        drill_down_data
    ) VALUES (
        v_analysis_id,
        p_start_date,
        p_end_date,
        p_granularity,
        v_mape,
        v_wape,
        v_mfa,
        v_wfa,
        v_bias,
        v_tracking_signal,
        v_drill_down_data
    );
    
    RETURN v_analysis_id;
END;
$$ LANGUAGE plpgsql;

-- View for easy access to latest forecast accuracy results
CREATE OR REPLACE VIEW v_latest_forecast_accuracy AS
SELECT 
    faa.*,
    CASE 
        WHEN faa.mape IS NOT NULL AND faa.mape < 15 THEN 'EXCELLENT'
        WHEN faa.mape IS NOT NULL AND faa.mape < 20 THEN 'GOOD'
        WHEN faa.mape IS NOT NULL AND faa.mape < 30 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_IMPROVEMENT'
    END as mape_rating,
    CASE 
        WHEN faa.wape IS NOT NULL AND faa.wape < 12 THEN 'EXCELLENT'
        WHEN faa.wape IS NOT NULL AND faa.wape < 18 THEN 'GOOD'
        WHEN faa.wape IS NOT NULL AND faa.wape < 25 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_IMPROVEMENT'
    END as wape_rating,
    CASE 
        WHEN faa.mfa IS NOT NULL AND faa.mfa > 85 THEN 'EXCELLENT'
        WHEN faa.mfa IS NOT NULL AND faa.mfa > 75 THEN 'GOOD'
        WHEN faa.mfa IS NOT NULL AND faa.mfa > 65 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_IMPROVEMENT'
    END as mfa_rating
FROM forecast_accuracy_analysis faa
WHERE faa.calculated_at = (
    SELECT MAX(calculated_at) 
    FROM forecast_accuracy_analysis faa2 
    WHERE faa2.granularity_level = faa.granularity_level
);

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_mape(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION calculate_wape(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION calculate_mfa(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION calculate_wfa(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION calculate_bias(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION calculate_tracking_signal(DATE, DATE, VARCHAR) TO wfm_user;
GRANT EXECUTE ON FUNCTION run_forecast_accuracy_analysis(DATE, DATE, VARCHAR) TO wfm_user;
GRANT SELECT ON v_latest_forecast_accuracy TO wfm_user;

-- Example usage comments
/*
-- Run forecast accuracy analysis for last month
SELECT run_forecast_accuracy_analysis(
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE,
    'Daily'
);

-- View latest results
SELECT * FROM v_latest_forecast_accuracy 
WHERE granularity_level = 'Daily';

-- Get specific metric
SELECT calculate_mape(CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE);
SELECT calculate_wape(CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE);
*/