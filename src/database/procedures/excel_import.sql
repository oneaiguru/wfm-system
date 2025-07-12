-- =====================================================================================
-- Excel Import Stored Procedures
-- Task ID: DB-002
-- Created for: DATABASE-OPUS Agent
-- Purpose: Handle Excel data import for Argus format (timestamp, calls, talk_time, post_time)
-- Performance: 100,000+ daily records in <60 seconds
-- =====================================================================================

-- Enable required extensions if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- 1. ERROR LOGGING TABLE
-- =====================================================================================

-- Import error tracking table
CREATE TABLE IF NOT EXISTS import_errors (
    id BIGSERIAL PRIMARY KEY,
    import_batch_id UUID NOT NULL REFERENCES import_batches(id),
    row_number INTEGER,
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    error_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient error retrieval
CREATE INDEX IF NOT EXISTS idx_import_errors_batch_id 
    ON import_errors (import_batch_id);

-- =====================================================================================
-- 2. HELPER FUNCTIONS
-- =====================================================================================

-- Helper function to parse timestamp from various Excel formats
CREATE OR REPLACE FUNCTION parse_excel_timestamp(timestamp_text TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    result TIMESTAMPTZ;
BEGIN
    -- Handle null or empty strings
    IF timestamp_text IS NULL OR TRIM(timestamp_text) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Try common timestamp formats
    BEGIN
        -- ISO format: 2024-01-15 14:30:00
        result := timestamp_text::TIMESTAMPTZ;
        RETURN result;
    EXCEPTION WHEN OTHERS THEN
        -- Continue to next format
    END;
    
    BEGIN
        -- Excel date format: 15/01/2024 14:30:00
        result := TO_TIMESTAMP(timestamp_text, 'DD/MM/YYYY HH24:MI:SS');
        RETURN result;
    EXCEPTION WHEN OTHERS THEN
        -- Continue to next format
    END;
    
    BEGIN
        -- Alternative format: 2024-01-15T14:30:00
        result := TO_TIMESTAMP(timestamp_text, 'YYYY-MM-DD"T"HH24:MI:SS');
        RETURN result;
    EXCEPTION WHEN OTHERS THEN
        -- Continue to next format
    END;
    
    -- If all formats fail, return NULL
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Helper function to parse integer values from Excel
CREATE OR REPLACE FUNCTION parse_excel_integer(value_text TEXT)
RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    -- Handle null or empty strings
    IF value_text IS NULL OR TRIM(value_text) = '' THEN
        RETURN 0;
    END IF;
    
    -- Remove any whitespace and convert
    BEGIN
        result := TRIM(value_text)::INTEGER;
        RETURN COALESCE(result, 0);
    EXCEPTION WHEN OTHERS THEN
        RETURN 0;
    END;
END;
$$ LANGUAGE plpgsql;

-- Helper function to round timestamp to 15-minute intervals
CREATE OR REPLACE FUNCTION round_to_15min_interval(input_timestamp TIMESTAMPTZ)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    minute_part INTEGER;
    rounded_minute INTEGER;
BEGIN
    -- Extract the minute part
    minute_part := EXTRACT(MINUTE FROM input_timestamp);
    
    -- Round to nearest 15-minute interval
    rounded_minute := (minute_part / 15) * 15;
    
    -- Return timestamp rounded to 15-minute boundary with seconds set to 0
    RETURN DATE_TRUNC('hour', input_timestamp) + (rounded_minute || ' minutes')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. VALIDATION PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION validate_staging_data(p_batch_id UUID)
RETURNS TABLE (
    row_number INTEGER,
    error_type VARCHAR,
    error_message TEXT
) AS $$
BEGIN
    -- Clear previous errors for this batch
    DELETE FROM import_errors WHERE import_batch_id = p_batch_id;
    
    -- Validate and return errors for timestamp format
    RETURN QUERY
    SELECT 
        s.row_number,
        'TIMESTAMP_FORMAT'::VARCHAR,
        'Invalid or missing timestamp format'::TEXT
    FROM excel_import_staging s
    WHERE s.import_batch_id = p_batch_id
      AND (s.timestamp_raw IS NULL 
           OR TRIM(s.timestamp_raw) = '' 
           OR parse_excel_timestamp(s.timestamp_raw) IS NULL);
    
    -- Validate service_id
    RETURN QUERY
    SELECT 
        s.row_number,
        'INVALID_SERVICE'::VARCHAR,
        'Invalid or missing service ID'::TEXT
    FROM excel_import_staging s
    WHERE s.import_batch_id = p_batch_id
      AND (s.service_id_raw IS NULL 
           OR TRIM(s.service_id_raw) = ''
           OR parse_excel_integer(s.service_id_raw) NOT IN (SELECT id FROM services WHERE is_active = TRUE));
    
    -- Validate numeric values are non-negative
    RETURN QUERY
    SELECT 
        s.row_number,
        'NEGATIVE_VALUES'::VARCHAR,
        'Calls, talk_time, or post_time cannot be negative'::TEXT
    FROM excel_import_staging s
    WHERE s.import_batch_id = p_batch_id
      AND (parse_excel_integer(s.calls_raw) < 0 
           OR parse_excel_integer(s.talk_time_raw) < 0 
           OR parse_excel_integer(s.post_time_raw) < 0);
    
    -- Validate reasonable time values (talk_time and post_time should be reasonable)
    RETURN QUERY
    SELECT 
        s.row_number,
        'UNREASONABLE_TIME'::VARCHAR,
        'Talk time or post time exceeds reasonable limits (>8 hours)'::TEXT
    FROM excel_import_staging s
    WHERE s.import_batch_id = p_batch_id
      AND (parse_excel_integer(s.talk_time_raw) > 28800 -- 8 hours in seconds
           OR parse_excel_integer(s.post_time_raw) > 28800);
    
    -- Log all errors to import_errors table
    INSERT INTO import_errors (import_batch_id, row_number, error_type, error_message)
    SELECT 
        p_batch_id,
        validation_errors.row_number,
        validation_errors.error_type,
        validation_errors.error_message
    FROM validate_staging_data(p_batch_id) validation_errors;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. TRANSFORM AND LOAD PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION transform_staging_to_contact_stats(p_batch_id UUID)
RETURNS INTEGER AS $$
DECLARE
    records_inserted INTEGER := 0;
    staging_record RECORD;
    interval_start TIMESTAMPTZ;
    interval_end TIMESTAMPTZ;
BEGIN
    -- Process each valid staging record
    FOR staging_record IN
        SELECT 
            s.*,
            parse_excel_timestamp(s.timestamp_raw) as parsed_timestamp,
            parse_excel_integer(s.calls_raw) as parsed_calls,
            parse_excel_integer(s.talk_time_raw) as parsed_talk_time,
            parse_excel_integer(s.post_time_raw) as parsed_post_time,
            parse_excel_integer(s.service_id_raw) as parsed_service_id,
            CASE 
                WHEN s.group_id_raw IS NOT NULL AND TRIM(s.group_id_raw) != '' 
                THEN parse_excel_integer(s.group_id_raw) 
                ELSE NULL 
            END as parsed_group_id
        FROM excel_import_staging s
        WHERE s.import_batch_id = p_batch_id
          AND s.is_valid = TRUE
          AND NOT s.is_processed
    LOOP
        -- Calculate 15-minute interval boundaries
        interval_start := round_to_15min_interval(staging_record.parsed_timestamp);
        interval_end := interval_start + INTERVAL '15 minutes';
        
        -- Insert or update contact statistics using ON CONFLICT
        INSERT INTO contact_statistics (
            interval_start_time,
            interval_end_time,
            service_id,
            group_id,
            not_unique_received,
            not_unique_treated,
            not_unique_missed,
            received_calls,
            treated_calls,
            miss_calls,
            talk_time,
            post_processing,
            aht,
            import_batch_id,
            created_at
        )
        VALUES (
            interval_start,
            interval_end,
            staging_record.parsed_service_id,
            staging_record.parsed_group_id,
            staging_record.parsed_calls,
            staging_record.parsed_calls,
            0, -- assuming no missed calls in this basic import
            staging_record.parsed_calls,
            staging_record.parsed_calls,
            0, -- assuming no missed calls in this basic import
            staging_record.parsed_talk_time,
            staging_record.parsed_post_time,
            staging_record.parsed_talk_time + staging_record.parsed_post_time,
            p_batch_id,
            NOW()
        )
        ON CONFLICT (interval_start_time, service_id, COALESCE(group_id, -1))
        DO UPDATE SET
            not_unique_received = contact_statistics.not_unique_received + EXCLUDED.not_unique_received,
            not_unique_treated = contact_statistics.not_unique_treated + EXCLUDED.not_unique_treated,
            received_calls = contact_statistics.received_calls + EXCLUDED.received_calls,
            treated_calls = contact_statistics.treated_calls + EXCLUDED.treated_calls,
            talk_time = contact_statistics.talk_time + EXCLUDED.talk_time,
            post_processing = contact_statistics.post_processing + EXCLUDED.post_processing,
            aht = (contact_statistics.talk_time + contact_statistics.post_processing + 
                   EXCLUDED.talk_time + EXCLUDED.post_processing) / 
                  GREATEST(contact_statistics.treated_calls + EXCLUDED.treated_calls, 1),
            updated_at = NOW();
        
        -- Mark staging record as processed
        UPDATE excel_import_staging 
        SET is_processed = TRUE, processed_at = NOW()
        WHERE id = staging_record.id;
        
        records_inserted := records_inserted + 1;
    END LOOP;
    
    RETURN records_inserted;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. MAIN IMPORT PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION import_excel_batch(
    p_batch_id UUID,
    p_source_file VARCHAR
)
RETURNS TABLE (
    success BOOLEAN,
    records_processed INTEGER,
    records_failed INTEGER,
    error_messages TEXT[]
) AS $$
DECLARE
    total_records INTEGER := 0;
    valid_records INTEGER := 0;
    processed_records INTEGER := 0;
    failed_records INTEGER := 0;
    error_list TEXT[] := ARRAY[]::TEXT[];
    error_record RECORD;
    batch_exists BOOLEAN := FALSE;
BEGIN
    -- Check if batch exists
    SELECT TRUE INTO batch_exists 
    FROM import_batches 
    WHERE id = p_batch_id;
    
    IF NOT batch_exists THEN
        RETURN QUERY SELECT 
            FALSE,
            0,
            0,
            ARRAY['Import batch not found']::TEXT[];
        RETURN;
    END IF;
    
    -- Start transaction and update batch status
    BEGIN
        -- Update batch status to processing
        UPDATE import_batches 
        SET status = 'processing',
            processing_started_at = NOW(),
            updated_at = NOW()
        WHERE id = p_batch_id;
        
        -- Count total records in staging
        SELECT COUNT(*) INTO total_records
        FROM excel_import_staging
        WHERE import_batch_id = p_batch_id;
        
        IF total_records = 0 THEN
            UPDATE import_batches 
            SET status = 'failed',
                error_summary = 'No records found in staging table',
                processing_completed_at = NOW(),
                updated_at = NOW()
            WHERE id = p_batch_id;
            
            RETURN QUERY SELECT 
                FALSE,
                0,
                0,
                ARRAY['No records found in staging table']::TEXT[];
            RETURN;
        END IF;
        
        -- Parse and validate all staging data
        UPDATE excel_import_staging
        SET 
            timestamp_parsed = parse_excel_timestamp(timestamp_raw),
            calls_parsed = parse_excel_integer(calls_raw),
            talk_time_parsed = parse_excel_integer(talk_time_raw),
            post_time_parsed = parse_excel_integer(post_time_raw),
            service_id_parsed = parse_excel_integer(service_id_raw),
            group_id_parsed = CASE 
                WHEN group_id_raw IS NOT NULL AND TRIM(group_id_raw) != '' 
                THEN parse_excel_integer(group_id_raw) 
                ELSE NULL 
            END
        WHERE import_batch_id = p_batch_id;
        
        -- Run validation and collect errors
        FOR error_record IN
            SELECT * FROM validate_staging_data(p_batch_id)
        LOOP
            error_list := array_append(error_list, 
                'Row ' || error_record.row_number || ': ' || error_record.error_message);
        END LOOP;
        
        -- Mark valid records
        UPDATE excel_import_staging
        SET is_valid = TRUE
        WHERE import_batch_id = p_batch_id
          AND id NOT IN (
              SELECT DISTINCT e.row_number 
              FROM import_errors e 
              WHERE e.import_batch_id = p_batch_id
          );
        
        -- Count valid records
        SELECT COUNT(*) INTO valid_records
        FROM excel_import_staging
        WHERE import_batch_id = p_batch_id
          AND is_valid = TRUE;
        
        failed_records := total_records - valid_records;
        
        -- If no valid records, fail the batch
        IF valid_records = 0 THEN
            UPDATE import_batches 
            SET status = 'failed',
                records_processed = 0,
                records_failed = failed_records,
                error_summary = 'No valid records found',
                processing_completed_at = NOW(),
                updated_at = NOW()
            WHERE id = p_batch_id;
            
            RETURN QUERY SELECT 
                FALSE,
                0,
                failed_records,
                error_list;
            RETURN;
        END IF;
        
        -- Transform and load valid records
        SELECT transform_staging_to_contact_stats(p_batch_id) INTO processed_records;
        
        -- Update batch status to completed
        UPDATE import_batches 
        SET status = 'completed',
            records_processed = processed_records,
            records_failed = failed_records,
            processing_completed_at = NOW(),
            updated_at = NOW(),
            error_summary = CASE 
                WHEN array_length(error_list, 1) > 0 
                THEN array_to_string(error_list[1:10], '; ') || 
                     CASE WHEN array_length(error_list, 1) > 10 
                     THEN '... and ' || (array_length(error_list, 1) - 10) || ' more errors' 
                     ELSE '' END
                ELSE NULL 
            END
        WHERE id = p_batch_id;
        
        -- Return success result
        RETURN QUERY SELECT 
            TRUE,
            processed_records,
            failed_records,
            error_list;
            
    EXCEPTION WHEN OTHERS THEN
        -- Handle any errors during processing
        UPDATE import_batches 
        SET status = 'failed',
            error_summary = SQLERRM,
            processing_completed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_batch_id;
        
        RETURN QUERY SELECT 
            FALSE,
            0,
            total_records,
            ARRAY['Processing failed: ' || SQLERRM]::TEXT[];
        
        -- Re-raise the exception to rollback transaction
        RAISE;
    END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. ADDITIONAL HELPER PROCEDURES
-- =====================================================================================

-- Procedure to bulk insert staging data from external source
CREATE OR REPLACE FUNCTION bulk_insert_staging_data(
    p_batch_id UUID,
    p_data JSONB
)
RETURNS INTEGER AS $$
DECLARE
    record_count INTEGER := 0;
    data_record JSONB;
    row_num INTEGER := 0;
BEGIN
    -- Loop through JSON array and insert records
    FOR data_record IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        row_num := row_num + 1;
        
        INSERT INTO excel_import_staging (
            import_batch_id,
            row_number,
            timestamp_raw,
            calls_raw,
            talk_time_raw,
            post_time_raw,
            service_id_raw,
            group_id_raw
        )
        VALUES (
            p_batch_id,
            row_num,
            data_record->>'timestamp',
            data_record->>'calls',
            data_record->>'talk_time',
            data_record->>'post_time',
            data_record->>'service_id',
            data_record->>'group_id'
        );
        
        record_count := record_count + 1;
    END LOOP;
    
    RETURN record_count;
END;
$$ LANGUAGE plpgsql;

-- Procedure to clean up old staging data
CREATE OR REPLACE FUNCTION cleanup_old_staging_data(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete staging data older than specified days
    DELETE FROM excel_import_staging
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete import errors for old batches
    DELETE FROM import_errors
    WHERE import_batch_id IN (
        SELECT id FROM import_batches 
        WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL
    );
    
    -- Delete old import batches
    DELETE FROM import_batches
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. PERFORMANCE INDEXES
-- =====================================================================================

-- Additional indexes for staging table performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excel_staging_batch_valid_processed 
    ON excel_import_staging (import_batch_id, is_valid, is_processed);

-- Composite index for contact_statistics conflicts
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_interval_service_group 
    ON contact_statistics (interval_start_time, service_id, COALESCE(group_id, -1));

-- =====================================================================================
-- 8. SAMPLE USAGE
-- =====================================================================================

/*
-- Example usage of the import procedures:

-- 1. Create a new import batch
INSERT INTO import_batches (filename, created_by) 
VALUES ('daily_stats_2024_01_15.xlsx', 'admin') 
RETURNING id;

-- 2. Insert staging data (example with single record)
INSERT INTO excel_import_staging (
    import_batch_id, row_number, timestamp_raw, calls_raw, 
    talk_time_raw, post_time_raw, service_id_raw, group_id_raw
) VALUES (
    'your-batch-id-here', 1, '2024-01-15 14:30:00', '5', 
    '1200', '300', '1', '1'
);

-- 3. Run the import process
SELECT * FROM import_excel_batch('your-batch-id-here', 'daily_stats_2024_01_15.xlsx');

-- 4. Check results
SELECT 
    filename,
    status,
    records_processed,
    records_failed,
    error_summary
FROM import_batches 
WHERE id = 'your-batch-id-here';

-- 5. View any errors
SELECT 
    row_number,
    error_type,
    error_message
FROM import_errors 
WHERE import_batch_id = 'your-batch-id-here'
ORDER BY row_number;
*/

-- =====================================================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION import_excel_batch(UUID, VARCHAR) IS 
    'Main import procedure for Excel data. Handles validation, transformation, and loading of Argus format data into contact_statistics table.';

COMMENT ON FUNCTION validate_staging_data(UUID) IS 
    'Validates staging data for timestamp format, service IDs, and numeric values. Returns validation errors.';

COMMENT ON FUNCTION transform_staging_to_contact_stats(UUID) IS 
    'Transforms validated staging data into 15-minute intervals and loads into contact_statistics table with aggregation.';

COMMENT ON FUNCTION parse_excel_timestamp(TEXT) IS 
    'Helper function to parse various Excel timestamp formats into PostgreSQL TIMESTAMPTZ.';

COMMENT ON FUNCTION round_to_15min_interval(TIMESTAMPTZ) IS 
    'Rounds timestamps to 15-minute interval boundaries (00, 15, 30, 45 minutes).';

COMMENT ON TABLE import_errors IS 
    'Stores detailed error information for failed import records with row-level granularity.';

-- =====================================================================================
-- FINAL SETUP MESSAGE
-- =====================================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Excel Import Procedures Installation Complete';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Available procedures:';
    RAISE NOTICE '- import_excel_batch(): Main import procedure';
    RAISE NOTICE '- validate_staging_data(): Data validation';
    RAISE NOTICE '- transform_staging_to_contact_stats(): Data transformation';
    RAISE NOTICE '- bulk_insert_staging_data(): Bulk data insertion';
    RAISE NOTICE '- cleanup_old_staging_data(): Maintenance procedure';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Performance features:';
    RAISE NOTICE '- Batch processing for 100,000+ records';
    RAISE NOTICE '- Transaction safety with rollback on errors';
    RAISE NOTICE '- Detailed error tracking and reporting';
    RAISE NOTICE '- 15-minute interval aggregation';
    RAISE NOTICE '- Optimized indexes for fast processing';
    RAISE NOTICE '=================================================================';
END $$;