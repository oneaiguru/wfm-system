-- =====================================================================================
-- Argus Import Template: 1-Hour Intervals
-- Created for: DATABASE-OPUS Agent
-- Purpose: Standardized import template for Argus 1-hour interval data
-- Target Tables: contact_statistics with automatic distribution to 15-minute intervals
-- =====================================================================================

-- =====================================================================================
-- 1-HOUR INTERVAL IMPORT TEMPLATE
-- =====================================================================================

-- Template function for importing Argus 1-hour data
CREATE OR REPLACE FUNCTION import_argus_1hour_data(
    p_filename VARCHAR,
    p_project_code VARCHAR,
    p_queue_code VARCHAR DEFAULT NULL,
    p_data JSONB,
    p_validate_only BOOLEAN DEFAULT FALSE,
    p_distribution_method VARCHAR DEFAULT 'even'  -- 'even', 'weighted', 'peak'
) RETURNS TABLE (
    batch_id UUID,
    status TEXT,
    rows_processed INTEGER,
    rows_imported INTEGER,
    validation_errors JSONB,
    project_id INTEGER,
    queue_id INTEGER,
    duration_ms INTEGER
) AS $$
DECLARE
    v_batch_id UUID;
    v_project_id INTEGER;
    v_queue_id INTEGER;
    v_service_id INTEGER;
    v_start_time TIMESTAMPTZ;
    v_validation_result RECORD;
    v_imported INTEGER := 0;
    v_row JSONB;
    v_interval_start TIMESTAMPTZ;
    v_interval_end TIMESTAMPTZ;
    v_15min_intervals TIMESTAMPTZ[];
    v_distribution NUMERIC[];
    v_i INTEGER;
    v_calls_per_interval INTEGER[];
    v_non_unique_per_interval INTEGER[];
BEGIN
    v_start_time := clock_timestamp();
    v_batch_id := uuid_generate_v4();
    
    -- Resolve project and queue IDs
    SELECT project_id INTO v_project_id 
    FROM projects 
    WHERE project_code = p_project_code AND is_active = TRUE;
    
    IF v_project_id IS NULL THEN
        RAISE EXCEPTION 'Project not found: %', p_project_code;
    END IF;
    
    -- If queue code provided, resolve queue ID
    IF p_queue_code IS NOT NULL THEN
        SELECT queue_id INTO v_queue_id
        FROM project_queues
        WHERE project_id = v_project_id 
          AND queue_code = p_queue_code 
          AND is_active = TRUE;
          
        IF v_queue_id IS NULL THEN
            RAISE EXCEPTION 'Queue not found: % in project %', p_queue_code, p_project_code;
        END IF;
    END IF;
    
    -- Use project_id as service_id for backward compatibility
    v_service_id := v_project_id;
    
    -- Validate Argus format
    SELECT * INTO v_validation_result 
    FROM validate_argus_format(p_data);
    
    IF NOT v_validation_result.is_valid OR p_validate_only THEN
        RETURN QUERY
        SELECT 
            v_batch_id,
            CASE 
                WHEN p_validate_only THEN 'validation_only'
                ELSE 'validation_failed'
            END,
            v_validation_result.total_rows,
            0,
            v_validation_result.errors,
            v_project_id,
            v_queue_id,
            EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
        RETURN;
    END IF;
    
    -- Create import batch
    INSERT INTO import_batches (id, filename, status, records_processed, created_by)
    VALUES (v_batch_id, p_filename, 'processing', v_validation_result.total_rows, 'argus_1hour_import');
    
    -- Import each row (1-hour data split into four 15-minute intervals)
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        BEGIN
            -- Parse timestamp and ensure hour alignment
            v_interval_start := to_timestamp(v_row->>'A', 'DD.MM.YYYY HH24:MI:SS');
            v_interval_start := DATE_TRUNC('hour', v_interval_start);
            v_interval_end := v_interval_start + INTERVAL '1 hour';
            
            -- Create array of four 15-minute interval starts
            v_15min_intervals := ARRAY[
                v_interval_start,
                v_interval_start + INTERVAL '15 minutes',
                v_interval_start + INTERVAL '30 minutes',
                v_interval_start + INTERVAL '45 minutes'
            ];
            
            -- Determine distribution based on method
            CASE p_distribution_method
                WHEN 'weighted' THEN
                    -- Weighted distribution: more calls during middle intervals
                    v_distribution := ARRAY[0.20, 0.30, 0.30, 0.20];
                WHEN 'peak' THEN
                    -- Peak distribution: most calls in first half hour
                    v_distribution := ARRAY[0.35, 0.35, 0.15, 0.15];
                ELSE -- 'even'
                    -- Even distribution across all intervals
                    v_distribution := ARRAY[0.25, 0.25, 0.25, 0.25];
            END CASE;
            
            -- Calculate calls per interval based on distribution
            v_calls_per_interval := ARRAY[]::INTEGER[];
            v_non_unique_per_interval := ARRAY[]::INTEGER[];
            
            FOR v_i IN 1..4 LOOP
                IF v_i < 4 THEN
                    v_calls_per_interval[v_i] := ROUND((v_row->>'B')::NUMERIC * v_distribution[v_i])::INTEGER;
                    v_non_unique_per_interval[v_i] := ROUND((v_row->>'C')::NUMERIC * v_distribution[v_i])::INTEGER;
                ELSE
                    -- Last interval gets remainder to ensure totals match
                    v_calls_per_interval[v_i] := (v_row->>'B')::INTEGER - 
                        (v_calls_per_interval[1] + v_calls_per_interval[2] + v_calls_per_interval[3]);
                    v_non_unique_per_interval[v_i] := (v_row->>'C')::INTEGER - 
                        (v_non_unique_per_interval[1] + v_non_unique_per_interval[2] + v_non_unique_per_interval[3]);
                END IF;
            END LOOP;
            
            -- Insert four 15-minute intervals
            FOR v_i IN 1..4 LOOP
                INSERT INTO contact_statistics (
                    interval_start_time,
                    interval_end_time,
                    service_id,
                    group_id,
                    received_calls,        
                    not_unique_received,   
                    treated_calls,         
                    not_unique_treated,    
                    miss_calls,            
                    not_unique_missed,     
                    aht,                   
                    talk_time,             
                    post_processing,       
                    service_level,         
                    abandonment_rate,      
                    occupancy_rate,        
                    import_batch_id,
                    created_at,
                    updated_at
                ) VALUES (
                    v_15min_intervals[v_i],
                    v_15min_intervals[v_i] + INTERVAL '15 minutes',
                    v_service_id,
                    v_queue_id,
                    v_calls_per_interval[v_i],                      -- Distributed unique calls
                    v_non_unique_per_interval[v_i],                 -- Distributed non-unique calls
                    v_calls_per_interval[v_i],                      -- Treated = received
                    v_non_unique_per_interval[v_i],                 -- Non-unique treated
                    0,                                              -- No missed calls
                    0,                                              -- No non-unique missed
                    ((v_row->>'D')::INTEGER + (v_row->>'E')::INTEGER) * 1000, -- AHT in ms
                    (v_row->>'D')::INTEGER * 1000,                 -- Talk time in ms
                    (v_row->>'E')::INTEGER * 1000,                 -- Post-processing in ms
                    100.00,                                         -- Assume 100% SL
                    0.00,                                           -- No abandonment
                    CASE 
                        WHEN v_calls_per_interval[v_i] > 0 THEN
                            ROUND(((v_row->>'D')::INTEGER::DECIMAL / 900) * 100, 2)
                        ELSE 0.00
                    END,                                            -- Occupancy rate
                    v_batch_id,
                    NOW(),
                    NOW()
                )
                ON CONFLICT (interval_start_time, service_id, COALESCE(group_id, -1))
                DO UPDATE SET
                    received_calls = contact_statistics.received_calls + EXCLUDED.received_calls,
                    not_unique_received = contact_statistics.not_unique_received + EXCLUDED.not_unique_received,
                    treated_calls = contact_statistics.treated_calls + EXCLUDED.treated_calls,
                    not_unique_treated = contact_statistics.not_unique_treated + EXCLUDED.not_unique_treated,
                    talk_time = contact_statistics.talk_time + EXCLUDED.talk_time,
                    post_processing = contact_statistics.post_processing + EXCLUDED.post_processing,
                    aht = CASE 
                        WHEN (contact_statistics.treated_calls + EXCLUDED.treated_calls) > 0 THEN
                            (contact_statistics.talk_time + contact_statistics.post_processing + 
                             EXCLUDED.talk_time + EXCLUDED.post_processing) / 
                            (contact_statistics.treated_calls + EXCLUDED.treated_calls)
                        ELSE 0
                    END,
                    updated_at = NOW(),
                    import_batch_id = EXCLUDED.import_batch_id;
            END LOOP;
            
            v_imported := v_imported + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Log error and continue
            INSERT INTO import_errors (
                import_batch_id,
                row_number,
                error_type,
                error_message,
                error_details
            ) VALUES (
                v_batch_id,
                v_imported + 1,
                'import_error',
                SQLERRM,
                v_row
            );
        END;
    END LOOP;
    
    -- Update batch status
    UPDATE import_batches 
    SET status = 'completed',
        records_processed = v_imported,
        processing_completed_at = clock_timestamp()
    WHERE id = v_batch_id;
    
    RETURN QUERY
    SELECT 
        v_batch_id,
        'completed'::TEXT,
        v_validation_result.total_rows,
        v_imported,
        NULL::JSONB,
        v_project_id,
        v_queue_id,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- USAGE EXAMPLES
-- =====================================================================================

/*
-- Example 1: Import 1-hour data with even distribution
SELECT * FROM import_argus_1hour_data(
    p_filename := 'ОтчетВходящиеПроекты-Бизнес-1ч.xlsx',
    p_project_code := 'B',
    p_data := '[
        {"A": "01.01.2024 09:00:00", "B": "40", "C": "60", "D": "300", "E": "30"},
        {"A": "01.01.2024 10:00:00", "B": "48", "C": "72", "D": "280", "E": "25"},
        {"A": "01.01.2024 11:00:00", "B": "32", "C": "48", "D": "320", "E": "35"}
    ]'::JSONB
);

-- Example 2: Import with weighted distribution (more calls mid-hour)
SELECT * FROM import_argus_1hour_data(
    p_filename := 'ОтчетВходящиеПроекты-ВТМ-1ч.xlsx',
    p_project_code := 'VTM',
    p_queue_code := 'VTM_SALES_01',
    p_data := '...'::JSONB,
    p_distribution_method := 'weighted'
);

-- Example 3: Import with peak distribution (more calls early in hour)
SELECT * FROM import_argus_1hour_data(
    p_filename := 'ОтчетВходящиеПроекты-И-1ч.xlsx',
    p_project_code := 'I',
    p_data := '...'::JSONB,
    p_distribution_method := 'peak'
);

-- Example 4: Query hourly aggregated data
SELECT 
    DATE_TRUNC('hour', interval_start_time) as hour_start,
    SUM(received_calls) as total_calls,
    SUM(not_unique_received) as total_non_unique,
    AVG(aht) as avg_aht,
    AVG(occupancy_rate) as avg_occupancy,
    COUNT(*) as intervals_count
FROM contact_statistics
WHERE service_id = 1
  AND interval_start_time >= '2024-01-01'
  AND interval_start_time < '2024-01-02'
GROUP BY DATE_TRUNC('hour', interval_start_time)
ORDER BY hour_start;
*/

-- =====================================================================================
-- AGGREGATION VIEW: Hourly intervals
-- =====================================================================================

CREATE OR REPLACE VIEW contact_statistics_hourly AS
SELECT 
    DATE_TRUNC('hour', interval_start_time) as interval_start_time,
    DATE_TRUNC('hour', interval_start_time) + INTERVAL '1 hour' as interval_end_time,
    service_id,
    group_id,
    SUM(not_unique_received) as not_unique_received,
    SUM(not_unique_treated) as not_unique_treated,
    SUM(not_unique_missed) as not_unique_missed,
    SUM(received_calls) as received_calls,
    SUM(treated_calls) as treated_calls,
    SUM(miss_calls) as miss_calls,
    CASE 
        WHEN SUM(treated_calls) > 0 THEN
            ROUND(SUM(talk_time + post_processing) / SUM(treated_calls))
        ELSE 0
    END as aht,
    SUM(talk_time) as talk_time,
    SUM(post_processing) as post_processing,
    AVG(service_level) as service_level,
    AVG(abandonment_rate) as abandonment_rate,
    AVG(occupancy_rate) as occupancy_rate,
    COUNT(*) as intervals_15min_count
FROM contact_statistics
GROUP BY 
    DATE_TRUNC('hour', interval_start_time),
    service_id,
    group_id;

-- =====================================================================================
-- DISTRIBUTION ANALYSIS FUNCTION
-- =====================================================================================

CREATE OR REPLACE FUNCTION analyze_hourly_distribution(
    p_service_id INTEGER,
    p_date DATE
) RETURNS TABLE (
    hour_start TIMESTAMPTZ,
    interval_15min TIMESTAMPTZ,
    calls_count INTEGER,
    distribution_pct NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH hourly_totals AS (
        SELECT 
            DATE_TRUNC('hour', interval_start_time) as hour_start,
            SUM(received_calls) as hour_total
        FROM contact_statistics
        WHERE service_id = p_service_id
          AND interval_start_time >= p_date
          AND interval_start_time < p_date + INTERVAL '1 day'
        GROUP BY DATE_TRUNC('hour', interval_start_time)
    )
    SELECT 
        ht.hour_start,
        cs.interval_start_time as interval_15min,
        cs.received_calls as calls_count,
        CASE 
            WHEN ht.hour_total > 0 THEN
                ROUND((cs.received_calls::NUMERIC / ht.hour_total) * 100, 2)
            ELSE 0
        END as distribution_pct
    FROM contact_statistics cs
    JOIN hourly_totals ht ON DATE_TRUNC('hour', cs.interval_start_time) = ht.hour_start
    WHERE cs.service_id = p_service_id
      AND cs.interval_start_time >= p_date
      AND cs.interval_start_time < p_date + INTERVAL '1 day'
    ORDER BY cs.interval_start_time;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION import_argus_1hour_data IS 'Imports Argus data in 1-hour intervals.
The function automatically splits hourly data into four 15-minute intervals.

Column mapping:
- A: Start time (DD.MM.YYYY HH:MM:SS) -> interval_start_time
- B: Unique incoming -> received_calls, treated_calls (distributed)
- C: Non-unique incoming -> not_unique_received, not_unique_treated (distributed)
- D: Average talk time (seconds) -> talk_time (converted to ms)
- E: Post-processing (seconds) -> post_processing (converted to ms)

Distribution methods:
- even: 25% to each 15-minute interval
- weighted: 20%, 30%, 30%, 20% (more calls mid-hour)
- peak: 35%, 35%, 15%, 15% (more calls early in hour)

Use contact_statistics_hourly view for aggregated hourly queries.
Use analyze_hourly_distribution() to review distribution patterns.';