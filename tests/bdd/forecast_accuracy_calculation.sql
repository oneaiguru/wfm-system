-- Test: Forecast accuracy MAPE/WAPE calculation for BDD scenario
-- Based on: 12-reporting-analytics-system.feature lines 59-78
-- Expected: MAPE <15%, WAPE <12%

\echo 'Starting BDD Forecast Accuracy Test...'

BEGIN;

-- Insert test forecasts into the forecasts table
INSERT INTO forecasts (
    id,
    organization_id,
    department_id,
    name,
    forecast_type,
    method,
    granularity,
    start_date,
    end_date,
    status,
    parameters,
    results,
    created_at
) VALUES
    (
        gen_random_uuid(),
        'deddb32a-9feb-4e75-8ecb-793d397a10b6'::uuid,
        '1fad76c5-2217-4718-8b31-68241797dbd7'::uuid,
        'Sales Queue Daily Forecast',
        'call_volume',
        'ml',
        '30min',
        '2025-01-15 09:00:00',
        '2025-01-15 09:15:00',
        'completed',
        '{"model": "v2.1", "queue": "Q-SALES"}',
        '{"predicted_volume": 1000, "confidence": 0.85}',
        '2024-03-15 08:00:00'
    ),
    (
        gen_random_uuid(),
        'deddb32a-9feb-4e75-8ecb-793d397a10b6'::uuid,
        '1fad76c5-2217-4718-8b31-68241797dbd7'::uuid,
        'Sales Queue Daily Forecast',
        'call_volume',
        'ml',
        '30min',
        '2025-01-16 09:00:00',
        '2025-01-16 09:15:00',
        'completed',
        '{"model": "v2.1", "queue": "Q-SALES"}',
        '{"predicted_volume": 1200, "confidence": 0.90}',
        '2024-03-16 08:00:00'
    );

-- Insert actual values into contact_statistics
INSERT INTO contact_statistics (
    id,
    interval_start_time,
    interval_end_time,
    service_id,
    group_id,
    received_calls,
    treated_calls,
    miss_calls,
    aht,
    talk_time,
    post_processing,
    service_level,
    abandonment_rate,
    occupancy_rate,
    created_at
) VALUES
    (
        1001,
        '2025-01-15 09:00:00+00',
        '2025-01-15 09:15:00+00',
        1,
        1,
        950,  -- Actual: 950 (vs predicted 1000)
        945,
        5,
        175,
        150,
        25,
        95.5,
        0.5,
        85.2,
        '2024-03-15 09:35:00+00'
    ),
    (
        1002,
        '2025-01-16 09:00:00+00',
        '2025-01-16 09:15:00+00',
        1,
        1,
        1300,  -- Actual: 1300 (vs predicted 1200)
        1290,
        10,
        190,
        165,
        25,
        94.2,
        0.8,
        87.5,
        '2024-03-16 09:35:00+00'
    );

\echo 'Test data inserted successfully'

-- Calculate Individual Errors for verification
\echo 'Calculating individual errors...'
WITH accuracy_calc AS (
    SELECT 
        DATE(f.start_date) as forecast_date,
        (f.results->>'predicted_volume')::integer as predicted_volume,
        c.received_calls as actual_volume,
        ABS((f.results->>'predicted_volume')::integer - c.received_calls) as absolute_error,
        100.0 * ABS((f.results->>'predicted_volume')::integer - c.received_calls) / c.received_calls as percentage_error
    FROM forecasts f
    JOIN contact_statistics c 
        ON DATE(f.start_date) = DATE(c.interval_start_time)
        AND f.parameters->>'queue' = 'Q-SALES'
    WHERE f.parameters->>'queue' = 'Q-SALES'
    AND DATE(f.start_date) IN ('2025-01-15', '2025-01-16')
)
SELECT 
    forecast_date,
    predicted_volume,
    actual_volume,
    absolute_error,
    ROUND(percentage_error, 2) as ape
FROM accuracy_calc
ORDER BY forecast_date;

-- Calculate and Insert MAPE (Mean Absolute Percentage Error)
\echo 'Calculating MAPE...'
WITH mape_calc AS (
    SELECT 
        DATE(f.start_date) as forecast_date,
        (f.results->>'predicted_volume')::integer as predicted_volume,
        c.received_calls as actual_volume,
        100.0 * ABS((f.results->>'predicted_volume')::integer - c.received_calls) / c.received_calls as ape
    FROM forecasts f
    JOIN contact_statistics c 
        ON DATE(f.start_date) = DATE(c.interval_start_time)
        AND f.parameters->>'queue' = 'Q-SALES'
    WHERE f.parameters->>'queue' = 'Q-SALES'
    AND DATE(f.start_date) IN ('2025-01-15', '2025-01-16')
)
INSERT INTO forecast_accuracy_analysis (
    id,
    analysis_period_start,
    analysis_period_end,
    granularity_level,
    mape,
    drill_down_data,
    calculated_at
)
SELECT 
    gen_random_uuid(),
    '2025-01-15'::date,
    '2025-01-16'::date,
    'Daily',
    ROUND(AVG(ape), 2),
    jsonb_build_object(
        'formula', 'AVG(|forecast - actual| / actual * 100)',
        'period', '2024-03-15 to 2024-03-16',
        'queue', 'Q-SALES',
        'details', jsonb_agg(
            jsonb_build_object(
                'date', forecast_date,
                'predicted', predicted_volume,
                'actual', actual_volume,
                'ape', ROUND(ape, 2)
            )
        )
    ),
    NOW()
FROM mape_calc;

-- Calculate and Insert WAPE (Weighted Absolute Percentage Error)
\echo 'Calculating WAPE...'
WITH wape_calc AS (
    SELECT 
        SUM(ABS((f.results->>'predicted_volume')::integer - c.received_calls)) as total_absolute_error,
        SUM(c.received_calls) as total_actual_volume
    FROM forecasts f
    JOIN contact_statistics c 
        ON DATE(f.start_date) = DATE(c.interval_start_time)
        AND f.parameters->>'queue' = 'Q-SALES'
    WHERE f.parameters->>'queue' = 'Q-SALES'
    AND DATE(f.start_date) IN ('2025-01-15', '2025-01-16')
)
INSERT INTO forecast_accuracy_analysis (
    id,
    analysis_period_start,
    analysis_period_end,
    granularity_level,
    wape,
    drill_down_data,
    calculated_at
)
SELECT 
    gen_random_uuid(),
    '2025-01-15'::date,
    '2025-01-16'::date,
    'Daily',
    ROUND(100.0 * total_absolute_error / total_actual_volume, 2),
    jsonb_build_object(
        'formula', 'SUM(|forecast - actual|) / SUM(actual) * 100',
        'period', '2024-03-15 to 2024-03-16',
        'queue', 'Q-SALES',
        'total_error', total_absolute_error,
        'total_volume', total_actual_volume
    ),
    NOW()
FROM wape_calc;

-- Verify Calculated Metrics
\echo 'Verifying calculated metrics...'
SELECT 
    granularity_level,
    COALESCE(mape, 0) as mape,
    COALESCE(wape, 0) as wape,
    mape_target_met,
    wape_target_met,
    drill_down_data->>'formula' as formula,
    analysis_period_start,
    analysis_period_end
FROM forecast_accuracy_analysis
WHERE analysis_period_start = '2025-01-15'
AND analysis_period_end = '2025-01-16'
ORDER BY id;

-- Expected Results Verification
\echo 'Expected vs Actual Results:'
\echo 'Date 1: |1000 - 950| / 950 * 100 = 5.26%'
\echo 'Date 2: |1200 - 1300| / 1300 * 100 = 7.69%'
\echo 'MAPE: (5.26 + 7.69) / 2 = 6.48%'
\echo 'WAPE: (50 + 100) / (950 + 1300) * 100 = 6.67%'

-- Performance Test (BDD requirement: fast calculation)
\echo 'Performance timing test...'
\timing on
WITH performance_test AS (
    SELECT 
        COUNT(*) as forecast_count,
        AVG(100.0 * ABS((f.results->>'predicted_volume')::integer - c.received_calls) / c.received_calls) as avg_mape,
        100.0 * SUM(ABS((f.results->>'predicted_volume')::integer - c.received_calls)) / SUM(c.received_calls) as wape
    FROM forecasts f
    JOIN contact_statistics c 
        ON DATE(f.start_date) = DATE(c.interval_start_time)
    WHERE f.parameters->>'queue' = 'Q-SALES'
    AND DATE(f.start_date) IN ('2025-01-15', '2025-01-16')
)
SELECT 
    forecast_count,
    ROUND(avg_mape, 2) as calculated_mape,
    ROUND(wape, 2) as calculated_wape,
    CASE 
        WHEN avg_mape < 15 THEN 'PASS: MAPE < 15%'
        ELSE 'FAIL: MAPE >= 15%'
    END as mape_result,
    CASE 
        WHEN wape < 12 THEN 'PASS: WAPE < 12%'
        ELSE 'FAIL: WAPE >= 12%'
    END as wape_result
FROM performance_test;
\timing off

\echo 'BDD Forecast Accuracy Test Complete!'

-- Cleanup test data
ROLLBACK;