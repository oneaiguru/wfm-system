-- =====================================================================================
-- Argus Format Validation and Import Procedures
-- Task ID: DB-ARGUS-001
-- Created for: DATABASE-OPUS Agent
-- Purpose: Ensure exact compliance with Argus data formats from BDD specifications
-- Reference: 08-load-forecasting-demand-planning.feature (Table 1)
-- =====================================================================================

-- =====================================================================================
-- 1. ARGUS FORMAT VALIDATION TYPES
-- =====================================================================================

-- Create custom types for validation results
DO $$ BEGIN
    CREATE TYPE argus_validation_result AS (
        is_valid BOOLEAN,
        column_letter CHAR(1),
        column_name TEXT,
        error_message TEXT,
        row_number INTEGER
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================================================
-- 2. EXACT ARGUS FORMAT VALIDATION PROCEDURE
-- =====================================================================================

-- Validate Excel import format according to Table 1 from BDD spec
-- Purpose: Ensures strict compliance with Argus Excel format from BDD specification
-- Reference: 08-load-forecasting-demand-planning.feature, Table 1
-- Usage: SELECT * FROM validate_argus_format('[{"A":"01.01.2024 09:00:00","B":"10",...}]'::JSONB);
-- Format Requirements:
--   Column A: DD.MM.YYYY HH:MM:SS (Start time) - Required
--   Column B: Positive integer (Unique incoming calls) - Required
--   Column C: Positive integer (Non-unique incoming, must be >= B) - Required
--   Column D: Positive integer (Average talk time in seconds) - Required
--   Column E: Positive integer (Post-processing time in seconds) - Required
-- Returns: Validation result with detailed error information for each invalid row
CREATE OR REPLACE FUNCTION validate_argus_format(
    p_data JSONB
) RETURNS TABLE (
    is_valid BOOLEAN,
    total_rows INTEGER,
    valid_rows INTEGER,
    errors JSONB
) AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_row JSONB;
    v_row_num INTEGER := 0;
    v_valid_rows INTEGER := 0;
    v_error JSONB;
    v_start_time TEXT;
    v_unique_incoming TEXT;
    v_non_unique_incoming TEXT;
    v_avg_talk_time TEXT;
    v_post_processing TEXT;
BEGIN
    -- Validate each row according to exact Argus format
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        v_row_num := v_row_num + 1;
        
        -- Extract values as text for validation
        v_start_time := v_row->>'A';
        v_unique_incoming := v_row->>'B';
        v_non_unique_incoming := v_row->>'C';
        v_avg_talk_time := v_row->>'D';
        v_post_processing := v_row->>'E';
        
        -- Validate Column A: Start time (DD.MM.YYYY HH:MM:SS format)
        BEGIN
            IF v_start_time IS NULL OR v_start_time = '' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'A',
                    'error', 'Start time is required',
                    'value', v_start_time
                );
                v_errors := v_errors || v_error;
            ELSIF NOT v_start_time ~ '^\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2}$' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'A',
                    'error', 'Invalid date format. Expected: DD.MM.YYYY HH:MM:SS',
                    'value', v_start_time
                );
                v_errors := v_errors || v_error;
            ELSE
                -- Try to parse the date
                PERFORM to_timestamp(v_start_time, 'DD.MM.YYYY HH24:MI:SS');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error := jsonb_build_object(
                'row', v_row_num,
                'column', 'A',
                'error', 'Invalid date: ' || SQLERRM,
                'value', v_start_time
            );
            v_errors := v_errors || v_error;
        END;
        
        -- Validate Column B: Unique incoming (positive integer)
        BEGIN
            IF v_unique_incoming IS NULL OR v_unique_incoming = '' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'B',
                    'error', 'Unique incoming is required',
                    'value', v_unique_incoming
                );
                v_errors := v_errors || v_error;
            ELSIF NOT v_unique_incoming ~ '^\d+$' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'B',
                    'error', 'Must be a positive integer',
                    'value', v_unique_incoming
                );
                v_errors := v_errors || v_error;
            ELSIF v_unique_incoming::INTEGER < 0 THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'B',
                    'error', 'Must be a positive number',
                    'value', v_unique_incoming
                );
                v_errors := v_errors || v_error;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error := jsonb_build_object(
                'row', v_row_num,
                'column', 'B',
                'error', 'Invalid number format',
                'value', v_unique_incoming
            );
            v_errors := v_errors || v_error;
        END;
        
        -- Validate Column C: Non-unique incoming (integer >= Column B)
        BEGIN
            IF v_non_unique_incoming IS NULL OR v_non_unique_incoming = '' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'C',
                    'error', 'Non-unique incoming is required',
                    'value', v_non_unique_incoming
                );
                v_errors := v_errors || v_error;
            ELSIF NOT v_non_unique_incoming ~ '^\d+$' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'C',
                    'error', 'Must be a positive integer',
                    'value', v_non_unique_incoming
                );
                v_errors := v_errors || v_error;
            ELSIF v_unique_incoming ~ '^\d+$' AND v_non_unique_incoming::INTEGER < v_unique_incoming::INTEGER THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'C',
                    'error', 'Non-unique incoming must be >= unique incoming',
                    'value', v_non_unique_incoming
                );
                v_errors := v_errors || v_error;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error := jsonb_build_object(
                'row', v_row_num,
                'column', 'C',
                'error', 'Invalid number format',
                'value', v_non_unique_incoming
            );
            v_errors := v_errors || v_error;
        END;
        
        -- Validate Column D: Average talk time (positive seconds)
        BEGIN
            IF v_avg_talk_time IS NULL OR v_avg_talk_time = '' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'D',
                    'error', 'Average talk time is required',
                    'value', v_avg_talk_time
                );
                v_errors := v_errors || v_error;
            ELSIF NOT v_avg_talk_time ~ '^\d+$' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'D',
                    'error', 'Must be a positive integer (seconds)',
                    'value', v_avg_talk_time
                );
                v_errors := v_errors || v_error;
            ELSIF v_avg_talk_time::INTEGER < 0 THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'D',
                    'error', 'Must be a positive number',
                    'value', v_avg_talk_time
                );
                v_errors := v_errors || v_error;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error := jsonb_build_object(
                'row', v_row_num,
                'column', 'D',
                'error', 'Invalid number format',
                'value', v_avg_talk_time
            );
            v_errors := v_errors || v_error;
        END;
        
        -- Validate Column E: Post-processing (positive seconds)
        BEGIN
            IF v_post_processing IS NULL OR v_post_processing = '' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'E',
                    'error', 'Post-processing time is required',
                    'value', v_post_processing
                );
                v_errors := v_errors || v_error;
            ELSIF NOT v_post_processing ~ '^\d+$' THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'E',
                    'error', 'Must be a positive integer (seconds)',
                    'value', v_post_processing
                );
                v_errors := v_errors || v_error;
            ELSIF v_post_processing::INTEGER < 0 THEN
                v_error := jsonb_build_object(
                    'row', v_row_num,
                    'column', 'E',
                    'error', 'Must be a positive number',
                    'value', v_post_processing
                );
                v_errors := v_errors || v_error;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error := jsonb_build_object(
                'row', v_row_num,
                'column', 'E',
                'error', 'Invalid number format',
                'value', v_post_processing
            );
            v_errors := v_errors || v_error;
        END;
        
        -- Count valid rows
        IF jsonb_array_length(v_errors) = 0 OR 
           NOT EXISTS (
               SELECT 1 FROM jsonb_array_elements(v_errors) e 
               WHERE (e->>'row')::INTEGER = v_row_num
           ) THEN
            v_valid_rows := v_valid_rows + 1;
        END IF;
    END LOOP;
    
    RETURN QUERY
    SELECT 
        jsonb_array_length(v_errors) = 0,
        v_row_num,
        v_valid_rows,
        v_errors;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. ARGUS FORMAT IMPORT PROCEDURE (UPDATED)
-- =====================================================================================

-- Import Argus format data with exact format compliance
-- Purpose: Imports call data in strict Argus format with validation and error handling
-- Usage: SELECT * FROM import_argus_format_data(jsonb_data, service_id, group_id, validate_only);
-- Process Flow:
--   1. Validates all data against Argus format requirements
--   2. Creates import batch for audit trail
--   3. Imports valid rows with conflict resolution
--   4. Records any import errors for debugging
-- Parameters:
--   p_data: JSONB array of Argus format records
--   p_service_id: Target service for import
--   p_group_id: Optional group assignment
--   p_validate_only: If TRUE, only validates without importing
-- Returns: Import summary with batch ID, counts, and any validation errors
-- Note: On conflict, updates existing records (upsert behavior)
CREATE OR REPLACE FUNCTION import_argus_format_data(
    p_data JSONB,
    p_service_id INTEGER,
    p_group_id INTEGER DEFAULT NULL,
    p_validate_only BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
    batch_id UUID,
    status TEXT,
    rows_processed INTEGER,
    rows_imported INTEGER,
    validation_errors JSONB,
    duration_ms INTEGER
) AS $$
DECLARE
    v_batch_id UUID;
    v_validation_result RECORD;
    v_start_time TIMESTAMPTZ;
    v_row JSONB;
    v_imported INTEGER := 0;
    v_interval_start TIMESTAMPTZ;
    v_interval_end TIMESTAMPTZ;
BEGIN
    v_start_time := clock_timestamp();
    v_batch_id := uuid_generate_v4();
    
    -- Step 1: Validate format
    SELECT * INTO v_validation_result 
    FROM validate_argus_format(p_data);
    
    -- If validation fails or validate_only mode, return early
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
            EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
        RETURN;
    END IF;
    
    -- Step 2: Create import batch
    INSERT INTO import_batches (id, source_type, status, total_rows)
    VALUES (v_batch_id, 'argus_excel', 'processing', v_validation_result.total_rows);
    
    -- Step 3: Import valid data
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        BEGIN
            -- Parse Argus date format (DD.MM.YYYY HH:MM:SS)
            v_interval_start := to_timestamp(v_row->>'A', 'DD.MM.YYYY HH24:MI:SS');
            v_interval_end := v_interval_start + INTERVAL '15 minutes';
            
            -- Insert into contact_statistics
            INSERT INTO contact_statistics (
                interval_start_time,
                interval_end_time,
                service_id,
                group_id,
                received_calls,        -- Column B: Unique incoming
                not_unique_received,   -- Column C: Non-unique incoming
                treated_calls,         -- Assume all received are treated for import
                not_unique_treated,    -- Assume all non-unique are treated
                miss_calls,            -- Zero for imported data
                not_unique_missed,     -- Zero for imported data
                aht,                   -- Column D: Average talk time (convert to milliseconds)
                talk_time,             -- Same as AHT for imported data
                post_processing,       -- Column E: Post-processing (convert to milliseconds)
                import_batch_id,
                created_at,
                updated_at
            ) VALUES (
                v_interval_start,
                v_interval_end,
                p_service_id,
                p_group_id,
                (v_row->>'B')::INTEGER,                    -- Unique incoming
                (v_row->>'C')::INTEGER,                    -- Non-unique incoming
                (v_row->>'B')::INTEGER,                    -- Treated = received for import
                (v_row->>'C')::INTEGER,                    -- Non-unique treated
                0,                                         -- No missed calls in import
                0,                                         -- No non-unique missed
                (v_row->>'D')::INTEGER * 1000,            -- Convert seconds to milliseconds
                (v_row->>'D')::INTEGER * 1000,            -- Talk time = AHT
                (v_row->>'E')::INTEGER * 1000,            -- Convert seconds to milliseconds
                v_batch_id,
                NOW(),
                NOW()
            )
            ON CONFLICT (interval_start_time, service_id, group_id) 
            DO UPDATE SET
                received_calls = EXCLUDED.received_calls,
                not_unique_received = EXCLUDED.not_unique_received,
                treated_calls = EXCLUDED.treated_calls,
                not_unique_treated = EXCLUDED.not_unique_treated,
                aht = EXCLUDED.aht,
                talk_time = EXCLUDED.talk_time,
                post_processing = EXCLUDED.post_processing,
                updated_at = NOW(),
                import_batch_id = EXCLUDED.import_batch_id;
            
            v_imported := v_imported + 1;
        EXCEPTION WHEN OTHERS THEN
            -- Log import error but continue
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
    
    -- Step 4: Update batch status
    UPDATE import_batches 
    SET status = 'completed',
        processed_rows = v_imported,
        completed_at = clock_timestamp()
    WHERE id = v_batch_id;
    
    RETURN QUERY
    SELECT 
        v_batch_id,
        'completed'::TEXT,
        v_validation_result.total_rows,
        v_imported,
        NULL::JSONB,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. VALIDATION HELPER FUNCTIONS
-- =====================================================================================

-- Get Argus format template for user download
-- Purpose: Provides exact Argus format specification for user reference
-- Usage: SELECT * FROM get_argus_import_template();
-- Returns: Template with column definitions matching BDD Table 1
-- Use Case: Generate template file for users to ensure format compliance
CREATE OR REPLACE FUNCTION get_argus_import_template()
RETURNS TABLE (
    column_letter CHAR(1),
    header_name TEXT,
    format_description TEXT,
    example_value TEXT,
    is_required BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        ('A'::CHAR(1), 'Start time'::TEXT, 'DD.MM.YYYY HH:MM:SS'::TEXT, '01.01.2024 09:00:00'::TEXT, TRUE),
        ('B'::CHAR(1), 'Unique incoming'::TEXT, 'Integer'::TEXT, '10'::TEXT, TRUE),
        ('C'::CHAR(1), 'Non-unique incoming'::TEXT, 'Integer'::TEXT, '15'::TEXT, TRUE),
        ('D'::CHAR(1), 'Average talk time'::TEXT, 'Seconds'::TEXT, '300'::TEXT, TRUE),
        ('E'::CHAR(1), 'Post-processing'::TEXT, 'Seconds'::TEXT, '30'::TEXT, TRUE)
    ) AS t(column_letter, header_name, format_description, example_value, is_required);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Validate single Argus date string
CREATE OR REPLACE FUNCTION validate_argus_date(p_date_string TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check format pattern
    IF NOT p_date_string ~ '^\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2}$' THEN
        RETURN FALSE;
    END IF;
    
    -- Try to parse
    PERFORM to_timestamp(p_date_string, 'DD.MM.YYYY HH24:MI:SS');
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- 5. PREVIEW AND VALIDATION VIEWS
-- =====================================================================================

-- Create view for import preview
CREATE OR REPLACE FUNCTION preview_argus_import(
    p_data JSONB,
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    row_num INTEGER,
    start_time TEXT,
    start_time_parsed TIMESTAMPTZ,
    unique_incoming INTEGER,
    non_unique_incoming INTEGER,
    avg_talk_time_seconds INTEGER,
    post_processing_seconds INTEGER,
    validation_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH numbered_rows AS (
        SELECT 
            row_number() OVER () as rn,
            value as row_data
        FROM jsonb_array_elements(p_data)
        LIMIT p_limit
    )
    SELECT 
        rn::INTEGER,
        row_data->>'A',
        CASE 
            WHEN validate_argus_date(row_data->>'A') 
            THEN to_timestamp(row_data->>'A', 'DD.MM.YYYY HH24:MI:SS')
            ELSE NULL
        END,
        (row_data->>'B')::INTEGER,
        (row_data->>'C')::INTEGER,
        (row_data->>'D')::INTEGER,
        (row_data->>'E')::INTEGER,
        CASE
            WHEN NOT validate_argus_date(row_data->>'A') THEN 'Invalid date format'
            WHEN (row_data->>'B')::INTEGER < 0 THEN 'Negative unique incoming'
            WHEN (row_data->>'C')::INTEGER < (row_data->>'B')::INTEGER THEN 'Non-unique < unique'
            WHEN (row_data->>'D')::INTEGER < 0 THEN 'Negative talk time'
            WHEN (row_data->>'E')::INTEGER < 0 THEN 'Negative post-processing'
            ELSE 'Valid'
        END
    FROM numbered_rows;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. USAGE EXAMPLES AND DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION validate_argus_format IS 'Validates Excel data against exact Argus format from BDD Table 1:
- Column A: Start time (DD.MM.YYYY HH:MM:SS)
- Column B: Unique incoming (positive integer)
- Column C: Non-unique incoming (integer >= Column B)
- Column D: Average talk time in seconds
- Column E: Post-processing time in seconds';

COMMENT ON FUNCTION import_argus_format_data IS 'Imports data in exact Argus format with validation.
Usage: SELECT * FROM import_argus_format_data(
    p_data := ''[{"A":"01.01.2024 09:00:00","B":"10","C":"15","D":"300","E":"30"}]''::JSONB,
    p_service_id := 1,
    p_group_id := NULL,
    p_validate_only := FALSE
);';

COMMENT ON FUNCTION get_argus_import_template IS 'Returns the exact Argus import template specification for user reference';