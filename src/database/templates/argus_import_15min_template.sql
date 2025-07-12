-- =====================================================================================
-- Argus Import Template: 15-Minute Intervals
-- Created for: DATABASE-OPUS Agent
-- Purpose: Standardized import template for Argus 15-minute interval data
-- Target Tables: contact_statistics, multi_skill_assignments
-- =====================================================================================

-- =====================================================================================
-- 15-MINUTE INTERVAL IMPORT TEMPLATE
-- =====================================================================================

-- Template function for importing Argus 15-minute data
CREATE OR REPLACE FUNCTION import_argus_15min_data(
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
    VALUES (v_batch_id, p_filename, 'processing', v_validation_result.total_rows, 'argus_15min_import');
    
    -- Import each row
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        BEGIN
            -- Parse timestamp and ensure 15-minute alignment
            v_interval_start := to_timestamp(v_row->>'A', 'DD.MM.YYYY HH24:MI:SS');
            v_interval_start := round_to_15min_interval(v_interval_start);
            v_interval_end := v_interval_start + INTERVAL '15 minutes';
            
            -- Insert into contact_statistics
            INSERT INTO contact_statistics (
                interval_start_time,
                interval_end_time,
                service_id,
                group_id,
                received_calls,        -- Column B: Unique incoming
                not_unique_received,   -- Column C: Non-unique incoming  
                treated_calls,         -- Same as received for import
                not_unique_treated,    -- Same as non-unique received
                miss_calls,            -- Zero for imported data
                not_unique_missed,     -- Zero for imported data
                aht,                   -- Column D: Average handling time (ms)
                talk_time,             -- Column D: Talk time component (ms)
                post_processing,       -- Column E: Post-processing time (ms)
                service_level,         -- Calculate based on project SLA
                abandonment_rate,      -- Zero for imported data
                occupancy_rate,        -- Calculate from times
                import_batch_id,
                created_at,
                updated_at
            ) VALUES (
                v_interval_start,
                v_interval_end,
                v_service_id,
                v_queue_id,
                (v_row->>'B')::INTEGER,                    -- Unique incoming
                (v_row->>'C')::INTEGER,                    -- Non-unique incoming
                (v_row->>'B')::INTEGER,                    -- Treated = received
                (v_row->>'C')::INTEGER,                    -- Non-unique treated
                0,                                         -- No missed calls
                0,                                         -- No non-unique missed
                ((v_row->>'D')::INTEGER + (v_row->>'E')::INTEGER) * 1000, -- AHT in ms
                (v_row->>'D')::INTEGER * 1000,            -- Talk time in ms
                (v_row->>'E')::INTEGER * 1000,            -- Post-processing in ms
                100.00,                                    -- Assume 100% SL for imports
                0.00,                                      -- No abandonment
                CASE 
                    WHEN (v_row->>'B')::INTEGER > 0 THEN
                        ROUND(((v_row->>'D')::INTEGER::DECIMAL / 900) * 100, 2)
                    ELSE 0.00
                END,                                       -- Occupancy rate
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
-- Example 1: Import 15-minute data for Project B
SELECT * FROM import_argus_15min_data(
    p_filename := 'ОтчетВходящиеПроекты-Бизнес-15м.xlsx',
    p_project_code := 'B',
    p_data := '[
        {"A": "01.01.2024 09:00:00", "B": "10", "C": "15", "D": "300", "E": "30"},
        {"A": "01.01.2024 09:15:00", "B": "12", "C": "18", "D": "280", "E": "25"},
        {"A": "01.01.2024 09:30:00", "B": "8", "C": "12", "D": "320", "E": "35"}
    ]'::JSONB
);

-- Example 2: Import with queue specification for Project VTM
SELECT * FROM import_argus_15min_data(
    p_filename := 'ОтчетВходящиеПроекты-ВТМ-15м.xlsx',
    p_project_code := 'VTM',
    p_queue_code := 'VTM_TECH_01',
    p_data := '...'::JSONB
);

-- Example 3: Validate only (no import)
SELECT * FROM import_argus_15min_data(
    p_filename := 'test_file.xlsx',
    p_project_code := 'B',
    p_data := '...'::JSONB,
    p_validate_only := TRUE
);
*/

-- =====================================================================================
-- HELPER FUNCTION: Round to 15-minute interval
-- =====================================================================================

CREATE OR REPLACE FUNCTION round_to_15min_interval(input_timestamp TIMESTAMPTZ)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    minute_part INTEGER;
    rounded_minute INTEGER;
BEGIN
    -- Extract the minute part
    minute_part := EXTRACT(MINUTE FROM input_timestamp);
    
    -- Round down to nearest 15-minute interval
    rounded_minute := (minute_part / 15) * 15;
    
    -- Return timestamp rounded to 15-minute boundary with seconds set to 0
    RETURN DATE_TRUNC('hour', input_timestamp) + (rounded_minute || ' minutes')::INTERVAL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION import_argus_15min_data IS 'Imports Argus data in 15-minute intervals.
Column mapping:
- A: Start time (DD.MM.YYYY HH:MM:SS) -> interval_start_time
- B: Unique incoming -> received_calls, treated_calls
- C: Non-unique incoming -> not_unique_received, not_unique_treated
- D: Average talk time (seconds) -> talk_time (converted to ms)
- E: Post-processing (seconds) -> post_processing (converted to ms)

The function automatically:
- Rounds timestamps to 15-minute boundaries
- Converts seconds to milliseconds for time fields
- Calculates AHT as talk_time + post_processing
- Handles conflicts by aggregating values
- Tracks import batch for audit trail';