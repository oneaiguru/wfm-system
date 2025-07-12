-- =====================================================================================
-- Argus Import Template: 30-Minute Intervals
-- Created for: DATABASE-OPUS Agent
-- Purpose: Standardized import template for Argus 30-minute interval data
-- Target Tables: contact_statistics with automatic aggregation to 30-minute intervals
-- =====================================================================================

-- =====================================================================================
-- 30-MINUTE INTERVAL IMPORT TEMPLATE
-- =====================================================================================

-- Template function for importing Argus 30-minute data
CREATE OR REPLACE FUNCTION import_argus_30min_data(
    p_filename VARCHAR,
    p_project_code VARCHAR,
    p_queue_code VARCHAR DEFAULT NULL,
    p_data JSONB,
    p_validate_only BOOLEAN DEFAULT FALSE
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
    v_15min_start1 TIMESTAMPTZ;
    v_15min_start2 TIMESTAMPTZ;
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
    VALUES (v_batch_id, p_filename, 'processing', v_validation_result.total_rows, 'argus_30min_import');
    
    -- Import each row (30-minute data split into two 15-minute intervals)
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        BEGIN
            -- Parse timestamp and ensure 30-minute alignment
            v_interval_start := to_timestamp(v_row->>'A', 'DD.MM.YYYY HH24:MI:SS');
            v_interval_start := round_to_30min_interval(v_interval_start);
            v_interval_end := v_interval_start + INTERVAL '30 minutes';
            
            -- Calculate two 15-minute interval starts
            v_15min_start1 := v_interval_start;
            v_15min_start2 := v_interval_start + INTERVAL '15 minutes';
            
            -- Split 30-minute data evenly into two 15-minute intervals
            -- Insert first 15-minute interval
            INSERT INTO contact_statistics (
                interval_start_time,
                interval_end_time,
                service_id,
                group_id,
                received_calls,        -- Split evenly
                not_unique_received,   -- Split evenly
                treated_calls,         -- Split evenly
                not_unique_treated,    -- Split evenly
                miss_calls,            
                not_unique_missed,     
                aht,                   -- Keep same AHT
                talk_time,             -- Keep same talk time
                post_processing,       -- Keep same post-processing
                service_level,         
                abandonment_rate,      
                occupancy_rate,        
                import_batch_id,
                created_at,
                updated_at
            ) VALUES (
                v_15min_start1,
                v_15min_start1 + INTERVAL '15 minutes',
                v_service_id,
                v_queue_id,
                CEIL((v_row->>'B')::NUMERIC / 2)::INTEGER,     -- Half of unique calls (rounded up)
                CEIL((v_row->>'C')::NUMERIC / 2)::INTEGER,     -- Half of non-unique calls (rounded up)
                CEIL((v_row->>'B')::NUMERIC / 2)::INTEGER,     -- Treated = received
                CEIL((v_row->>'C')::NUMERIC / 2)::INTEGER,     -- Non-unique treated
                0,                                              -- No missed calls
                0,                                              -- No non-unique missed
                ((v_row->>'D')::INTEGER + (v_row->>'E')::INTEGER) * 1000, -- AHT in ms
                (v_row->>'D')::INTEGER * 1000,                 -- Talk time in ms
                (v_row->>'E')::INTEGER * 1000,                 -- Post-processing in ms
                100.00,                                         -- Assume 100% SL
                0.00,                                           -- No abandonment
                CASE 
                    WHEN (v_row->>'B')::INTEGER > 0 THEN
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
            
            -- Insert second 15-minute interval
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
                v_15min_start2,
                v_15min_start2 + INTERVAL '15 minutes',
                v_service_id,
                v_queue_id,
                FLOOR((v_row->>'B')::NUMERIC / 2)::INTEGER,    -- Half of unique calls (rounded down)
                FLOOR((v_row->>'C')::NUMERIC / 2)::INTEGER,    -- Half of non-unique calls (rounded down)
                FLOOR((v_row->>'B')::NUMERIC / 2)::INTEGER,    -- Treated = received
                FLOOR((v_row->>'C')::NUMERIC / 2)::INTEGER,    -- Non-unique treated
                0,                                              -- No missed calls
                0,                                              -- No non-unique missed
                ((v_row->>'D')::INTEGER + (v_row->>'E')::INTEGER) * 1000, -- AHT in ms
                (v_row->>'D')::INTEGER * 1000,                 -- Talk time in ms
                (v_row->>'E')::INTEGER * 1000,                 -- Post-processing in ms
                100.00,                                         -- Assume 100% SL
                0.00,                                           -- No abandonment
                CASE 
                    WHEN (v_row->>'B')::INTEGER > 0 THEN
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
-- Example 1: Import 30-minute data for Project B
SELECT * FROM import_argus_30min_data(
    p_filename := 'ОтчетВходящиеПроекты-Бизнес-30м.xlsx',
    p_project_code := 'B',
    p_data := '[
        {"A": "01.01.2024 09:00:00", "B": "20", "C": "30", "D": "300", "E": "30"},
        {"A": "01.01.2024 09:30:00", "B": "24", "C": "36", "D": "280", "E": "25"},
        {"A": "01.01.2024 10:00:00", "B": "16", "C": "24", "D": "320", "E": "35"}
    ]'::JSONB
);

-- Example 2: Query aggregated 30-minute data after import
SELECT 
    DATE_TRUNC('hour', interval_start_time) + 
        (FLOOR(EXTRACT(MINUTE FROM interval_start_time) / 30) * 30 || ' minutes')::INTERVAL as interval_30min,
    SUM(received_calls) as total_calls,
    SUM(not_unique_received) as total_non_unique,
    AVG(aht) as avg_aht,
    AVG(occupancy_rate) as avg_occupancy
FROM contact_statistics
WHERE service_id = 1
  AND interval_start_time >= '2024-01-01'
  AND interval_start_time < '2024-01-02'
GROUP BY interval_30min
ORDER BY interval_30min;
*/

-- =====================================================================================
-- HELPER FUNCTION: Round to 30-minute interval
-- =====================================================================================

CREATE OR REPLACE FUNCTION round_to_30min_interval(input_timestamp TIMESTAMPTZ)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    minute_part INTEGER;
    rounded_minute INTEGER;
BEGIN
    -- Extract the minute part
    minute_part := EXTRACT(MINUTE FROM input_timestamp);
    
    -- Round down to nearest 30-minute interval (0 or 30)
    rounded_minute := (minute_part / 30) * 30;
    
    -- Return timestamp rounded to 30-minute boundary with seconds set to 0
    RETURN DATE_TRUNC('hour', input_timestamp) + (rounded_minute || ' minutes')::INTERVAL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- AGGREGATION VIEW: 30-minute intervals
-- =====================================================================================

CREATE OR REPLACE VIEW contact_statistics_30min AS
SELECT 
    DATE_TRUNC('hour', interval_start_time) + 
        (FLOOR(EXTRACT(MINUTE FROM interval_start_time) / 30) * 30 || ' minutes')::INTERVAL as interval_start_time,
    DATE_TRUNC('hour', interval_start_time) + 
        (FLOOR(EXTRACT(MINUTE FROM interval_start_time) / 30) * 30 || ' minutes')::INTERVAL + 
        INTERVAL '30 minutes' as interval_end_time,
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
    AVG(occupancy_rate) as occupancy_rate
FROM contact_statistics
GROUP BY 
    DATE_TRUNC('hour', interval_start_time) + 
        (FLOOR(EXTRACT(MINUTE FROM interval_start_time) / 30) * 30 || ' minutes')::INTERVAL,
    service_id,
    group_id;

COMMENT ON FUNCTION import_argus_30min_data IS 'Imports Argus data in 30-minute intervals.
The function automatically splits 30-minute data into two 15-minute intervals for storage.

Column mapping:
- A: Start time (DD.MM.YYYY HH:MM:SS) -> interval_start_time
- B: Unique incoming -> received_calls, treated_calls (split 50/50)
- C: Non-unique incoming -> not_unique_received, not_unique_treated (split 50/50)
- D: Average talk time (seconds) -> talk_time (converted to ms)
- E: Post-processing (seconds) -> post_processing (converted to ms)

Distribution logic:
- First 15-min interval: CEIL(value/2) - gets the extra call if odd number
- Second 15-min interval: FLOOR(value/2) - ensures total matches original

Use the contact_statistics_30min view to query aggregated 30-minute data.';