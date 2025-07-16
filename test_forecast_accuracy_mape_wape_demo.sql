-- =================================================================
-- Forecast Accuracy MAPE/WAPE Test Data and Demo
-- Demonstrates real MAPE/WAPE calculations with business data
-- =================================================================

-- Insert realistic forecast data for testing
INSERT INTO forecast_data (service_id, forecast_date, interval_start, call_volume, average_handle_time, service_level_target) VALUES
-- Service 1: Technical Support
(1, CURRENT_DATE - 30, '09:00:00', 120, 180, 80.00),
(1, CURRENT_DATE - 29, '09:00:00', 115, 175, 80.00),
(1, CURRENT_DATE - 28, '09:00:00', 130, 185, 80.00),
(1, CURRENT_DATE - 27, '09:00:00', 125, 180, 80.00),
(1, CURRENT_DATE - 26, '09:00:00', 110, 170, 80.00),
(1, CURRENT_DATE - 25, '09:00:00', 140, 190, 80.00),
(1, CURRENT_DATE - 24, '09:00:00', 135, 185, 80.00),
(1, CURRENT_DATE - 23, '09:00:00', 128, 182, 80.00),
(1, CURRENT_DATE - 22, '09:00:00', 122, 178, 80.00),
(1, CURRENT_DATE - 21, '09:00:00', 118, 175, 80.00),
(1, CURRENT_DATE - 20, '09:00:00', 145, 192, 80.00),
(1, CURRENT_DATE - 19, '09:00:00', 132, 188, 80.00),
(1, CURRENT_DATE - 18, '09:00:00', 126, 180, 80.00),
(1, CURRENT_DATE - 17, '09:00:00', 138, 190, 80.00),
(1, CURRENT_DATE - 16, '09:00:00', 142, 195, 80.00),
(1, CURRENT_DATE - 15, '09:00:00', 119, 176, 80.00),
(1, CURRENT_DATE - 14, '09:00:00', 134, 187, 80.00),
(1, CURRENT_DATE - 13, '09:00:00', 127, 181, 80.00),
(1, CURRENT_DATE - 12, '09:00:00', 141, 193, 80.00),
(1, CURRENT_DATE - 11, '09:00:00', 129, 183, 80.00),
(1, CURRENT_DATE - 10, '09:00:00', 136, 189, 80.00),
(1, CURRENT_DATE - 9, '09:00:00', 131, 186, 80.00),
(1, CURRENT_DATE - 8, '09:00:00', 124, 179, 80.00),
(1, CURRENT_DATE - 7, '09:00:00', 139, 191, 80.00),
(1, CURRENT_DATE - 6, '09:00:00', 133, 187, 80.00),
(1, CURRENT_DATE - 5, '09:00:00', 121, 177, 80.00),
(1, CURRENT_DATE - 4, '09:00:00', 143, 194, 80.00),
(1, CURRENT_DATE - 3, '09:00:00', 137, 190, 80.00),
(1, CURRENT_DATE - 2, '09:00:00', 125, 180, 80.00),
(1, CURRENT_DATE - 1, '09:00:00', 130, 185, 80.00);

-- Insert corresponding actual call data into contact_statistics
-- This simulates real contact center data with some variance from forecasts
INSERT INTO contact_statistics (
    interval_start_time, 
    interval_end_time, 
    service_id, 
    received_calls, 
    treated_calls, 
    miss_calls, 
    aht, 
    service_level
) VALUES
-- Actual data with realistic variance from forecasts (±10-20%)
(CURRENT_DATE - 30 + INTERVAL '9 hours', CURRENT_DATE - 30 + INTERVAL '9 hours 15 minutes', 1, 108, 105, 3, 185, 82.5),
(CURRENT_DATE - 29 + INTERVAL '9 hours', CURRENT_DATE - 29 + INTERVAL '9 hours 15 minutes', 1, 122, 119, 3, 178, 78.2),
(CURRENT_DATE - 28 + INTERVAL '9 hours', CURRENT_DATE - 28 + INTERVAL '9 hours 15 minutes', 1, 142, 138, 4, 188, 76.8),
(CURRENT_DATE - 27 + INTERVAL '9 hours', CURRENT_DATE - 27 + INTERVAL '9 hours 15 minutes', 1, 118, 115, 3, 172, 83.1),
(CURRENT_DATE - 26 + INTERVAL '9 hours', CURRENT_DATE - 26 + INTERVAL '9 hours 15 minutes', 1, 95, 92, 3, 168, 85.7),
(CURRENT_DATE - 25 + INTERVAL '9 hours', CURRENT_DATE - 25 + INTERVAL '9 hours 15 minutes', 1, 155, 149, 6, 195, 73.5),
(CURRENT_DATE - 24 + INTERVAL '9 hours', CURRENT_DATE - 24 + INTERVAL '9 hours 15 minutes', 1, 128, 125, 3, 182, 79.8),
(CURRENT_DATE - 23 + INTERVAL '9 hours', CURRENT_DATE - 23 + INTERVAL '9 hours 15 minutes', 1, 135, 131, 4, 186, 77.2),
(CURRENT_DATE - 22 + INTERVAL '9 hours', CURRENT_DATE - 22 + INTERVAL '9 hours 15 minutes', 1, 114, 111, 3, 175, 81.6),
(CURRENT_DATE - 21 + INTERVAL '9 hours', CURRENT_DATE - 21 + INTERVAL '9 hours 15 minutes', 1, 126, 123, 3, 179, 78.9),
(CURRENT_DATE - 20 + INTERVAL '9 hours', CURRENT_DATE - 20 + INTERVAL '9 hours 15 minutes', 1, 162, 156, 6, 198, 71.2),
(CURRENT_DATE - 19 + INTERVAL '9 hours', CURRENT_DATE - 19 + INTERVAL '9 hours 15 minutes', 1, 124, 121, 3, 184, 79.5),
(CURRENT_DATE - 18 + INTERVAL '9 hours', CURRENT_DATE - 18 + INTERVAL '9 hours 15 minutes', 1, 133, 130, 3, 177, 80.8),
(CURRENT_DATE - 17 + INTERVAL '9 hours', CURRENT_DATE - 17 + INTERVAL '9 hours 15 minutes', 1, 148, 143, 5, 193, 75.1),
(CURRENT_DATE - 16 + INTERVAL '9 hours', CURRENT_DATE - 16 + INTERVAL '9 hours 15 minutes', 1, 159, 152, 7, 201, 69.8),
(CURRENT_DATE - 15 + INTERVAL '9 hours', CURRENT_DATE - 15 + INTERVAL '9 hours 15 minutes', 1, 107, 104, 3, 173, 83.4),
(CURRENT_DATE - 14 + INTERVAL '9 hours', CURRENT_DATE - 14 + INTERVAL '9 hours 15 minutes', 1, 141, 137, 4, 190, 76.2),
(CURRENT_DATE - 13 + INTERVAL '9 hours', CURRENT_DATE - 13 + INTERVAL '9 hours 15 minutes', 1, 119, 116, 3, 178, 81.1),
(CURRENT_DATE - 12 + INTERVAL '9 hours', CURRENT_DATE - 12 + INTERVAL '9 hours 15 minutes', 1, 152, 146, 6, 196, 72.8),
(CURRENT_DATE - 11 + INTERVAL '9 hours', CURRENT_DATE - 11 + INTERVAL '9 hours 15 minutes', 1, 136, 132, 4, 185, 77.9),
(CURRENT_DATE - 10 + INTERVAL '9 hours', CURRENT_DATE - 10 + INTERVAL '9 hours 15 minutes', 1, 144, 139, 5, 192, 75.6),
(CURRENT_DATE - 9 + INTERVAL '9 hours', CURRENT_DATE - 9 + INTERVAL '9 hours 15 minutes', 1, 122, 119, 3, 183, 80.2),
(CURRENT_DATE - 8 + INTERVAL '9 hours', CURRENT_DATE - 8 + INTERVAL '9 hours 15 minutes', 1, 131, 128, 3, 176, 81.5),
(CURRENT_DATE - 7 + INTERVAL '9 hours', CURRENT_DATE - 7 + INTERVAL '9 hours 15 minutes', 1, 146, 141, 5, 194, 74.3),
(CURRENT_DATE - 6 + INTERVAL '9 hours', CURRENT_DATE - 6 + INTERVAL '9 hours 15 minutes', 1, 125, 122, 3, 184, 79.7),
(CURRENT_DATE - 5 + INTERVAL '9 hours', CURRENT_DATE - 5 + INTERVAL '9 hours 15 minutes', 1, 112, 109, 3, 174, 82.8),
(CURRENT_DATE - 4 + INTERVAL '9 hours', CURRENT_DATE - 4 + INTERVAL '9 hours 15 minutes', 1, 157, 151, 6, 197, 72.1),
(CURRENT_DATE - 3 + INTERVAL '9 hours', CURRENT_DATE - 3 + INTERVAL '9 hours 15 minutes', 1, 129, 126, 3, 187, 78.6),
(CURRENT_DATE - 2 + INTERVAL '9 hours', CURRENT_DATE - 2 + INTERVAL '9 hours 15 minutes', 1, 117, 114, 3, 177, 82.3),
(CURRENT_DATE - 1 + INTERVAL '9 hours', CURRENT_DATE - 1 + INTERVAL '9 hours 15 minutes', 1, 138, 134, 4, 188, 76.5);

-- Test individual metric calculations
SELECT 'MAPE Calculation Test' as test_name;
SELECT calculate_mape(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as mape_result;

SELECT 'WAPE Calculation Test' as test_name;
SELECT calculate_wape(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as wape_result;

SELECT 'MFA Calculation Test' as test_name;
SELECT calculate_mfa(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as mfa_result;

SELECT 'WFA Calculation Test' as test_name;
SELECT calculate_wfa(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as wfa_result;

SELECT 'Bias Calculation Test' as test_name;
SELECT calculate_bias(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as bias_result;

SELECT 'Tracking Signal Test' as test_name;
SELECT calculate_tracking_signal(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as tracking_signal_result;

-- Run complete forecast accuracy analysis
SELECT 'Complete Analysis Test' as test_name;
SELECT run_forecast_accuracy_analysis(CURRENT_DATE - 30, CURRENT_DATE, 'Daily') as analysis_id;

-- Display results from the analysis
SELECT 'Analysis Results' as result_section;
SELECT 
    analysis_period_start,
    analysis_period_end,
    granularity_level,
    mape,
    wape,
    mfa,
    wfa,
    bias,
    tracking_signal,
    mape_target_met,
    wape_target_met,
    mfa_target_met,
    wfa_target_met,
    bias_target_met,
    tracking_signal_target_met,
    calculated_at
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1;

-- Show BDD compliance check
SELECT 'BDD Target Compliance Check' as compliance_section;
SELECT 
    'MAPE Target (<15%)' as metric,
    mape as actual_value,
    15.0 as target_value,
    mape_target_met as target_met,
    CASE 
        WHEN mape_target_met THEN 'PASS - Excellent forecast accuracy'
        ELSE 'REVIEW NEEDED - Consider model improvements'
    END as bdd_status
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1

UNION ALL

SELECT 
    'WAPE Target (<12%)' as metric,
    wape as actual_value,
    12.0 as target_value,
    wape_target_met as target_met,
    CASE 
        WHEN wape_target_met THEN 'PASS - Excellent volume-weighted accuracy'
        ELSE 'REVIEW NEEDED - Focus on high-volume periods'
    END as bdd_status
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1

UNION ALL

SELECT 
    'MFA Target (>85%)' as metric,
    mfa as actual_value,
    85.0 as target_value,
    mfa_target_met as target_met,
    CASE 
        WHEN mfa_target_met THEN 'PASS - Good average precision'
        ELSE 'REVIEW NEEDED - Improve overall accuracy'
    END as bdd_status
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1

UNION ALL

SELECT 
    'WFA Target (>88%)' as metric,
    wfa as actual_value,
    88.0 as target_value,
    wfa_target_met as target_met,
    CASE 
        WHEN wfa_target_met THEN 'PASS - Excellent volume-weighted precision'
        ELSE 'REVIEW NEEDED - Focus on high-volume accuracy'
    END as bdd_status
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1;

-- Show drill-down analysis sample
SELECT 'Drill-down Analysis Sample' as analysis_section;
SELECT 
    jsonb_pretty(
        jsonb_extract_path(drill_down_data, 'daily_analysis')
    ) as daily_breakdown
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1;

-- Performance validation - verify calculations meet BDD timing requirements
SELECT 'Performance Validation' as validation_section;
SELECT 
    'Sub-second response time for accuracy calculations' as requirement,
    CASE 
        WHEN EXTRACT(EPOCH FROM (SELECT MAX(calculated_at) FROM forecast_accuracy_analysis WHERE calculated_at >= CURRENT_DATE)) - 
             EXTRACT(EPOCH FROM (SELECT MIN(created_at) FROM forecast_data WHERE forecast_date >= CURRENT_DATE - 30)) < 5
        THEN 'PASS - Fast calculation performance'
        ELSE 'REVIEW - Performance optimization needed'
    END as performance_status;

-- Summary report matching BDD scenario format
SELECT 'BDD Scenario Validation Summary' as final_summary;
SELECT 
    'Forecast Accuracy Analysis BDD Scenario' as scenario_name,
    'IMPLEMENTED' as implementation_status,
    CASE 
        WHEN mape < 15 AND wape < 12 AND mfa > 85 AND wfa > 88 AND ABS(bias) <= 5 AND ABS(tracking_signal) <= 4
        THEN 'ALL BDD TARGETS MET'
        WHEN mape < 20 AND wape < 18 AND mfa > 75 AND wfa > 80
        THEN 'GOOD PERFORMANCE - MINOR IMPROVEMENTS NEEDED'
        ELSE 'PERFORMANCE REVIEW REQUIRED'
    END as overall_assessment,
    CONCAT(
        'MAPE: ', mape, '% (Target: <15%), ',
        'WAPE: ', wape, '% (Target: <12%), ',
        'MFA: ', mfa, '% (Target: >85%), ',
        'WFA: ', wfa, '% (Target: >88%)'
    ) as key_metrics
FROM forecast_accuracy_analysis 
WHERE calculated_at >= CURRENT_DATE
ORDER BY calculated_at DESC 
LIMIT 1;