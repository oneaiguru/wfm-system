-- =====================================================================================
-- Import Procedures for Project Б (Business) Data
-- Module: Data Import and Processing
-- Purpose: Comprehensive import procedures for Project Б call center data
-- Data Sources: Excel files with 15m, 30m, 1h intervals
-- Volume: ~10,000 calls per day
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- 1. STAGING TABLES FOR RAW DATA IMPORT
-- =====================================================================================

-- Drop existing staging tables if they exist
DROP TABLE IF EXISTS staging_project_b_raw CASCADE;
DROP TABLE IF EXISTS staging_project_b_processed CASCADE;
DROP TABLE IF EXISTS import_log CASCADE;
DROP TABLE IF EXISTS import_errors CASCADE;

-- Create import log table
CREATE TABLE import_log (
    log_id SERIAL PRIMARY KEY,
    import_batch_id UUID DEFAULT uuid_generate_v4(),
    import_type VARCHAR(50) NOT NULL, -- 'project_b_15m', 'project_b_30m', 'project_b_1h'
    file_name VARCHAR(255),
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed', 'rolled_back'
    total_rows INTEGER,
    processed_rows INTEGER,
    error_rows INTEGER,
    warnings TEXT[],
    created_by VARCHAR(100)
);

-- Create import errors table
CREATE TABLE import_errors (
    error_id SERIAL PRIMARY KEY,
    import_batch_id UUID,
    row_number INTEGER,
    error_type VARCHAR(50), -- 'validation', 'parsing', 'constraint', 'business_rule'
    error_message TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create staging table for raw Excel data
CREATE TABLE staging_project_b_raw (
    staging_id BIGSERIAL PRIMARY KEY,
    import_batch_id UUID,
    row_number INTEGER,
    period_text VARCHAR(50),
    cdo INTEGER,
    hc INTEGER,
    shc DECIMAL(5,2),
    shc_minus_ac5 DECIMAL(5,2),
    hc_sl INTEGER,
    sl DECIMAL(5,2),
    sl_on_hc DECIMAL(5,2),
    ac INTEGER,
    ac5 INTEGER,
    lcr DECIMAL(5,2),
    fc INTEGER,
    tt INTEGER,
    ott INTEGER,
    ht INTEGER,
    tht INTEGER,
    aht DECIMAL(8,2),
    acw DECIMAL(8,2),
    tht_plus_acw INTEGER,
    aht_plus_acw DECIMAL(8,2),
    twt_hc INTEGER,
    awt_hc DECIMAL(8,2),
    mwt_hc INTEGER,
    twt_ac INTEGER,
    awt_ac DECIMAL(8,2),
    mwt_ac INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create processed staging table with proper data types
CREATE TABLE staging_project_b_processed (
    processed_id BIGSERIAL PRIMARY KEY,
    import_batch_id UUID,
    interval_timestamp TIMESTAMPTZ NOT NULL,
    interval_duration INTEGER NOT NULL, -- 15, 30, or 60 minutes
    calls_offered INTEGER NOT NULL,
    calls_handled INTEGER NOT NULL,
    calls_handled_percentage DECIMAL(5,2),
    calls_handled_sl INTEGER,
    service_level DECIMAL(5,2),
    service_level_on_handled DECIMAL(5,2),
    calls_abandoned INTEGER,
    calls_abandoned_5s INTEGER,
    lost_call_rate DECIMAL(5,2),
    forecast_calls INTEGER,
    total_talk_time INTEGER,
    total_other_time INTEGER,
    hold_time INTEGER,
    total_handle_time INTEGER,
    average_handle_time DECIMAL(8,2),
    after_call_work DECIMAL(8,2),
    total_handle_time_with_acw INTEGER,
    average_handle_time_with_acw DECIMAL(8,2),
    total_wait_time_handled INTEGER,
    average_wait_time_handled DECIMAL(8,2),
    max_wait_time_handled INTEGER,
    total_wait_time_abandoned INTEGER,
    average_wait_time_abandoned DECIMAL(8,2),
    max_wait_time_abandoned INTEGER,
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT processed_unique UNIQUE(interval_timestamp, interval_duration)
);

-- Create indexes for performance
CREATE INDEX idx_staging_raw_batch ON staging_project_b_raw(import_batch_id);
CREATE INDEX idx_staging_processed_batch ON staging_project_b_processed(import_batch_id);
CREATE INDEX idx_staging_processed_timestamp ON staging_project_b_processed(interval_timestamp);
CREATE INDEX idx_import_errors_batch ON import_errors(import_batch_id);

-- =====================================================================================
-- 2. MAIN PRODUCTION TABLES
-- =====================================================================================

-- Create main project_b_intervals table
CREATE TABLE IF NOT EXISTS project_b_intervals (
    interval_id BIGSERIAL PRIMARY KEY,
    interval_timestamp TIMESTAMPTZ NOT NULL,
    interval_duration INTEGER NOT NULL CHECK (interval_duration IN (15, 30, 60)),
    interval_date DATE GENERATED ALWAYS AS (interval_timestamp::DATE) STORED,
    interval_hour INTEGER GENERATED ALWAYS AS (EXTRACT(HOUR FROM interval_timestamp)) STORED,
    day_of_week INTEGER GENERATED ALWAYS AS (EXTRACT(DOW FROM interval_timestamp)) STORED,
    is_weekend BOOLEAN GENERATED ALWAYS AS (EXTRACT(DOW FROM interval_timestamp) IN (0,6)) STORED,
    
    -- Call metrics
    calls_offered INTEGER NOT NULL DEFAULT 0,
    calls_handled INTEGER NOT NULL DEFAULT 0,
    calls_abandoned INTEGER NOT NULL DEFAULT 0,
    calls_abandoned_5s INTEGER NOT NULL DEFAULT 0,
    
    -- Service level metrics
    calls_handled_sl INTEGER NOT NULL DEFAULT 0,
    service_level DECIMAL(5,2) DEFAULT 0,
    service_level_on_handled DECIMAL(5,2) DEFAULT 0,
    
    -- Time metrics (in seconds)
    total_talk_time INTEGER DEFAULT 0,
    total_handle_time INTEGER DEFAULT 0,
    total_hold_time INTEGER DEFAULT 0,
    total_after_call_work INTEGER DEFAULT 0,
    
    -- Calculated metrics
    average_handle_time DECIMAL(8,2) GENERATED ALWAYS AS 
        (CASE WHEN calls_handled > 0 THEN total_handle_time::DECIMAL / calls_handled ELSE 0 END) STORED,
    occupancy_rate DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN interval_duration > 0 THEN (total_handle_time::DECIMAL / (interval_duration * 60) * 100) ELSE 0 END) STORED,
    
    -- Wait time metrics
    total_wait_time_handled INTEGER DEFAULT 0,
    max_wait_time_handled INTEGER DEFAULT 0,
    total_wait_time_abandoned INTEGER DEFAULT 0,
    max_wait_time_abandoned INTEGER DEFAULT 0,
    
    -- Metadata
    import_batch_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT interval_unique UNIQUE(interval_timestamp, interval_duration)
);

-- Create indexes for query performance
CREATE INDEX idx_project_b_intervals_date ON project_b_intervals(interval_date);
CREATE INDEX idx_project_b_intervals_timestamp ON project_b_intervals(interval_timestamp);
CREATE INDEX idx_project_b_intervals_hour ON project_b_intervals(interval_hour);
CREATE INDEX idx_project_b_intervals_duration ON project_b_intervals(interval_duration);
CREATE INDEX idx_project_b_intervals_weekend ON project_b_intervals(is_weekend);

-- Daily aggregated metrics table
CREATE TABLE IF NOT EXISTS project_b_daily_metrics (
    daily_id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL UNIQUE,
    total_calls_offered INTEGER DEFAULT 0,
    total_calls_handled INTEGER DEFAULT 0,
    total_calls_abandoned INTEGER DEFAULT 0,
    average_service_level DECIMAL(5,2),
    average_handle_time DECIMAL(8,2),
    peak_hour INTEGER,
    peak_hour_calls INTEGER,
    total_agent_hours DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================================
-- 3. VALIDATION FUNCTIONS
-- =====================================================================================

-- Function to validate period text and convert to timestamp
CREATE OR REPLACE FUNCTION validate_and_convert_period(
    p_period_text VARCHAR,
    p_row_number INTEGER
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    v_timestamp TIMESTAMPTZ;
BEGIN
    -- Expected format: 'DD.MM.YYYY HH24:MI'
    BEGIN
        v_timestamp := TO_TIMESTAMP(p_period_text, 'DD.MM.YYYY HH24:MI');
        
        -- Validate reasonable date range (2020-2030)
        IF v_timestamp < '2020-01-01'::TIMESTAMPTZ OR v_timestamp > '2030-12-31'::TIMESTAMPTZ THEN
            RAISE EXCEPTION 'Date out of valid range';
        END IF;
        
        RETURN v_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Invalid period format in row %: % (expected DD.MM.YYYY HH24:MI)', 
                p_row_number, p_period_text;
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to validate call metrics
CREATE OR REPLACE FUNCTION validate_call_metrics(
    p_import_batch_id UUID,
    p_row_number INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_row RECORD;
    v_errors TEXT[] := ARRAY[]::TEXT[];
    v_warnings TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Get the row data
    SELECT * INTO v_row
    FROM staging_project_b_raw
    WHERE import_batch_id = p_import_batch_id
    AND row_number = p_row_number;
    
    -- Validation rules
    
    -- 1. Calls handled cannot exceed calls offered
    IF v_row.hc > v_row.cdo THEN
        v_errors := array_append(v_errors, 'Handled calls exceed offered calls');
    END IF;
    
    -- 2. Service level should be between 0 and 100
    IF v_row.sl IS NOT NULL AND (v_row.sl < 0 OR v_row.sl > 100) THEN
        v_errors := array_append(v_errors, 'Service level out of range (0-100)');
    END IF;
    
    -- 3. Average handle time validation
    IF v_row.aht IS NOT NULL AND v_row.aht < 0 THEN
        v_errors := array_append(v_errors, 'Negative average handle time');
    END IF;
    
    -- 4. Check for unusually high values (potential data errors)
    IF v_row.cdo > 1000 THEN
        v_warnings := array_append(v_warnings, format('Unusually high calls offered: %s', v_row.cdo));
    END IF;
    
    IF v_row.aht > 3600 THEN
        v_warnings := array_append(v_warnings, format('AHT exceeds 1 hour: %s seconds', v_row.aht));
    END IF;
    
    -- 5. Lost call rate validation
    IF v_row.lcr IS NOT NULL AND (v_row.lcr < 0 OR v_row.lcr > 100) THEN
        v_errors := array_append(v_errors, 'Lost call rate out of range (0-100)');
    END IF;
    
    RETURN jsonb_build_object(
        'errors', v_errors,
        'warnings', v_warnings,
        'is_valid', array_length(v_errors, 1) IS NULL
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. MAIN IMPORT PROCEDURE
-- =====================================================================================

CREATE OR REPLACE FUNCTION import_project_b_data(
    p_file_path VARCHAR,
    p_interval_type VARCHAR, -- '15m', '30m', '1h'
    p_created_by VARCHAR DEFAULT 'system',
    p_validate_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    import_batch_id UUID,
    status VARCHAR,
    total_rows INTEGER,
    processed_rows INTEGER,
    error_rows INTEGER,
    execution_time_ms INTEGER
) AS $$
DECLARE
    v_import_batch_id UUID;
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_total_rows INTEGER := 0;
    v_processed_rows INTEGER := 0;
    v_error_rows INTEGER := 0;
    v_interval_duration INTEGER;
    v_row RECORD;
    v_validation_result JSONB;
    v_timestamp TIMESTAMPTZ;
    v_status VARCHAR := 'completed';
BEGIN
    v_start_time := clock_timestamp();
    v_import_batch_id := uuid_generate_v4();
    
    -- Determine interval duration
    v_interval_duration := CASE p_interval_type
        WHEN '15m' THEN 15
        WHEN '30m' THEN 30
        WHEN '1h' THEN 60
        ELSE NULL
    END;
    
    IF v_interval_duration IS NULL THEN
        RAISE EXCEPTION 'Invalid interval type: %. Must be 15m, 30m, or 1h', p_interval_type;
    END IF;
    
    -- Log import start
    INSERT INTO import_log (import_batch_id, import_type, file_name, created_by)
    VALUES (v_import_batch_id, 'project_b_' || p_interval_type, p_file_path, p_created_by);
    
    -- Start transaction for atomic import
    BEGIN
        -- Note: Actual Excel file reading would be done by external process
        -- This assumes data is already loaded into staging_project_b_raw
        
        -- Count total rows
        SELECT COUNT(*) INTO v_total_rows
        FROM staging_project_b_raw
        WHERE import_batch_id = v_import_batch_id;
        
        -- Process each row
        FOR v_row IN 
            SELECT * FROM staging_project_b_raw
            WHERE import_batch_id = v_import_batch_id
            ORDER BY row_number
        LOOP
            BEGIN
                -- Convert period text to timestamp
                v_timestamp := validate_and_convert_period(v_row.period_text, v_row.row_number);
                
                -- Validate metrics
                v_validation_result := validate_call_metrics(v_import_batch_id, v_row.row_number);
                
                IF (v_validation_result->>'is_valid')::BOOLEAN THEN
                    -- Insert into processed staging
                    INSERT INTO staging_project_b_processed (
                        import_batch_id,
                        interval_timestamp,
                        interval_duration,
                        calls_offered,
                        calls_handled,
                        calls_handled_percentage,
                        calls_handled_sl,
                        service_level,
                        service_level_on_handled,
                        calls_abandoned,
                        calls_abandoned_5s,
                        lost_call_rate,
                        forecast_calls,
                        total_talk_time,
                        total_other_time,
                        hold_time,
                        total_handle_time,
                        average_handle_time,
                        after_call_work,
                        total_handle_time_with_acw,
                        average_handle_time_with_acw,
                        total_wait_time_handled,
                        average_wait_time_handled,
                        max_wait_time_handled,
                        total_wait_time_abandoned,
                        average_wait_time_abandoned,
                        max_wait_time_abandoned,
                        validation_errors
                    ) VALUES (
                        v_import_batch_id,
                        v_timestamp,
                        v_interval_duration,
                        COALESCE(v_row.cdo, 0),
                        COALESCE(v_row.hc, 0),
                        v_row.shc,
                        COALESCE(v_row.hc_sl, 0),
                        v_row.sl,
                        v_row.sl_on_hc,
                        COALESCE(v_row.ac, 0),
                        COALESCE(v_row.ac5, 0),
                        v_row.lcr,
                        v_row.fc,
                        COALESCE(v_row.tt, 0),
                        COALESCE(v_row.ott, 0),
                        COALESCE(v_row.ht, 0),
                        COALESCE(v_row.tht, 0),
                        v_row.aht,
                        v_row.acw,
                        v_row.tht_plus_acw,
                        v_row.aht_plus_acw,
                        COALESCE(v_row.twt_hc, 0),
                        v_row.awt_hc,
                        COALESCE(v_row.mwt_hc, 0),
                        COALESCE(v_row.twt_ac, 0),
                        v_row.awt_ac,
                        COALESCE(v_row.mwt_ac, 0),
                        v_validation_result->'warnings'
                    );
                    
                    v_processed_rows := v_processed_rows + 1;
                ELSE
                    -- Log error
                    INSERT INTO import_errors (
                        import_batch_id,
                        row_number,
                        error_type,
                        error_message,
                        raw_data
                    ) VALUES (
                        v_import_batch_id,
                        v_row.row_number,
                        'validation',
                        array_to_string((v_validation_result->'errors')::TEXT[], '; '),
                        row_to_json(v_row)::JSONB
                    );
                    
                    v_error_rows := v_error_rows + 1;
                END IF;
                
            EXCEPTION
                WHEN OTHERS THEN
                    -- Log any unexpected errors
                    INSERT INTO import_errors (
                        import_batch_id,
                        row_number,
                        error_type,
                        error_message,
                        raw_data
                    ) VALUES (
                        v_import_batch_id,
                        v_row.row_number,
                        'processing',
                        SQLERRM,
                        row_to_json(v_row)::JSONB
                    );
                    
                    v_error_rows := v_error_rows + 1;
            END;
        END LOOP;
        
        -- If not validate-only mode, move to production tables
        IF NOT p_validate_only AND v_error_rows = 0 THEN
            -- Insert into production table
            INSERT INTO project_b_intervals (
                interval_timestamp,
                interval_duration,
                calls_offered,
                calls_handled,
                calls_abandoned,
                calls_abandoned_5s,
                calls_handled_sl,
                service_level,
                service_level_on_handled,
                total_talk_time,
                total_handle_time,
                total_hold_time,
                total_after_call_work,
                total_wait_time_handled,
                max_wait_time_handled,
                total_wait_time_abandoned,
                max_wait_time_abandoned,
                import_batch_id
            )
            SELECT
                interval_timestamp,
                interval_duration,
                calls_offered,
                calls_handled,
                calls_abandoned,
                calls_abandoned_5s,
                calls_handled_sl,
                service_level,
                service_level_on_handled,
                total_talk_time,
                total_handle_time,
                hold_time,
                COALESCE(after_call_work, 0) * calls_handled, -- Convert avg to total
                total_wait_time_handled,
                max_wait_time_handled,
                total_wait_time_abandoned,
                max_wait_time_abandoned,
                import_batch_id
            FROM staging_project_b_processed
            WHERE import_batch_id = v_import_batch_id
            ON CONFLICT (interval_timestamp, interval_duration) 
            DO UPDATE SET
                calls_offered = EXCLUDED.calls_offered,
                calls_handled = EXCLUDED.calls_handled,
                calls_abandoned = EXCLUDED.calls_abandoned,
                calls_abandoned_5s = EXCLUDED.calls_abandoned_5s,
                calls_handled_sl = EXCLUDED.calls_handled_sl,
                service_level = EXCLUDED.service_level,
                service_level_on_handled = EXCLUDED.service_level_on_handled,
                total_talk_time = EXCLUDED.total_talk_time,
                total_handle_time = EXCLUDED.total_handle_time,
                total_hold_time = EXCLUDED.total_hold_time,
                total_after_call_work = EXCLUDED.total_after_call_work,
                total_wait_time_handled = EXCLUDED.total_wait_time_handled,
                max_wait_time_handled = EXCLUDED.max_wait_time_handled,
                total_wait_time_abandoned = EXCLUDED.total_wait_time_abandoned,
                max_wait_time_abandoned = EXCLUDED.max_wait_time_abandoned,
                import_batch_id = EXCLUDED.import_batch_id,
                updated_at = NOW();
                
            -- Update daily metrics
            PERFORM update_project_b_daily_metrics(v_import_batch_id);
        END IF;
        
        -- If errors occurred or validate-only, rollback
        IF v_error_rows > 0 OR p_validate_only THEN
            v_status := CASE 
                WHEN p_validate_only THEN 'validated'
                ELSE 'failed'
            END;
            RAISE EXCEPTION 'Import % with % errors', v_status, v_error_rows;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback will happen automatically
            v_status := 'failed';
            
            -- Update import log
            UPDATE import_log
            SET 
                end_time = clock_timestamp(),
                status = v_status,
                total_rows = v_total_rows,
                processed_rows = v_processed_rows,
                error_rows = v_error_rows
            WHERE import_batch_id = v_import_batch_id;
            
            -- Re-raise the exception
            RAISE;
    END;
    
    v_end_time := clock_timestamp();
    
    -- Update import log
    UPDATE import_log
    SET 
        end_time = v_end_time,
        status = v_status,
        total_rows = v_total_rows,
        processed_rows = v_processed_rows,
        error_rows = v_error_rows
    WHERE import_batch_id = v_import_batch_id;
    
    -- Return results
    RETURN QUERY
    SELECT 
        v_import_batch_id,
        v_status,
        v_total_rows,
        v_processed_rows,
        v_error_rows,
        EXTRACT(MILLISECOND FROM v_end_time - v_start_time)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. BATCH IMPORT WITH PROGRESS TRACKING
-- =====================================================================================

CREATE OR REPLACE FUNCTION batch_import_project_b_excel(
    p_data JSONB[], -- Array of rows from Excel
    p_interval_type VARCHAR,
    p_file_name VARCHAR,
    p_created_by VARCHAR DEFAULT 'system'
)
RETURNS TABLE (
    import_batch_id UUID,
    status VARCHAR,
    processed_count INTEGER,
    error_count INTEGER,
    progress_percentage DECIMAL
) AS $$
DECLARE
    v_import_batch_id UUID;
    v_total_rows INTEGER;
    v_current_row INTEGER := 0;
    v_processed INTEGER := 0;
    v_errors INTEGER := 0;
    v_row JSONB;
    v_progress DECIMAL;
BEGIN
    v_import_batch_id := uuid_generate_v4();
    v_total_rows := array_length(p_data, 1);
    
    -- Initialize import log
    INSERT INTO import_log (import_batch_id, import_type, file_name, total_rows, created_by)
    VALUES (v_import_batch_id, 'project_b_' || p_interval_type, p_file_name, v_total_rows, p_created_by);
    
    -- Process each row
    FOREACH v_row IN ARRAY p_data
    LOOP
        v_current_row := v_current_row + 1;
        
        BEGIN
            -- Insert into staging
            INSERT INTO staging_project_b_raw (
                import_batch_id,
                row_number,
                period_text,
                cdo,
                hc,
                shc,
                shc_minus_ac5,
                hc_sl,
                sl,
                sl_on_hc,
                ac,
                ac5,
                lcr,
                fc,
                tt,
                ott,
                ht,
                tht,
                aht,
                acw,
                tht_plus_acw,
                aht_plus_acw,
                twt_hc,
                awt_hc,
                mwt_hc,
                twt_ac,
                awt_ac,
                mwt_ac
            ) VALUES (
                v_import_batch_id,
                v_current_row,
                v_row->>'period',
                (v_row->>'cdo')::INTEGER,
                (v_row->>'hc')::INTEGER,
                (v_row->>'shc')::DECIMAL,
                (v_row->>'shc_minus_ac5')::DECIMAL,
                (v_row->>'hc_sl')::INTEGER,
                (v_row->>'sl')::DECIMAL,
                (v_row->>'sl_on_hc')::DECIMAL,
                (v_row->>'ac')::INTEGER,
                (v_row->>'ac5')::INTEGER,
                (v_row->>'lcr')::DECIMAL,
                (v_row->>'fc')::INTEGER,
                (v_row->>'tt')::INTEGER,
                (v_row->>'ott')::INTEGER,
                (v_row->>'ht')::INTEGER,
                (v_row->>'tht')::INTEGER,
                (v_row->>'aht')::DECIMAL,
                (v_row->>'acw')::DECIMAL,
                (v_row->>'tht_plus_acw')::INTEGER,
                (v_row->>'aht_plus_acw')::DECIMAL,
                (v_row->>'twt_hc')::INTEGER,
                (v_row->>'awt_hc')::DECIMAL,
                (v_row->>'mwt_hc')::INTEGER,
                (v_row->>'twt_ac')::INTEGER,
                (v_row->>'awt_ac')::DECIMAL,
                (v_row->>'mwt_ac')::INTEGER
            );
            
            v_processed := v_processed + 1;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_errors := v_errors + 1;
                
                INSERT INTO import_errors (
                    import_batch_id,
                    row_number,
                    error_type,
                    error_message,
                    raw_data
                ) VALUES (
                    v_import_batch_id,
                    v_current_row,
                    'parsing',
                    SQLERRM,
                    v_row
                );
        END;
        
        -- Calculate and emit progress
        v_progress := (v_current_row::DECIMAL / v_total_rows) * 100;
        
        -- Emit progress update every 100 rows
        IF v_current_row % 100 = 0 THEN
            RETURN QUERY
            SELECT 
                v_import_batch_id,
                'in_progress'::VARCHAR,
                v_processed,
                v_errors,
                v_progress;
        END IF;
    END LOOP;
    
    -- Process the staged data
    PERFORM import_project_b_data(
        p_file_name,
        p_interval_type,
        p_created_by,
        FALSE
    );
    
    -- Return final status
    RETURN QUERY
    SELECT 
        v_import_batch_id,
        'completed'::VARCHAR,
        v_processed,
        v_errors,
        100.0::DECIMAL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. DAILY METRICS AGGREGATION
-- =====================================================================================

CREATE OR REPLACE FUNCTION update_project_b_daily_metrics(
    p_import_batch_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_dates DATE[];
    v_date DATE;
BEGIN
    -- Get affected dates
    IF p_import_batch_id IS NOT NULL THEN
        SELECT ARRAY_AGG(DISTINCT interval_date)
        INTO v_dates
        FROM project_b_intervals
        WHERE import_batch_id = p_import_batch_id;
    ELSE
        -- Update all dates
        SELECT ARRAY_AGG(DISTINCT interval_date)
        INTO v_dates
        FROM project_b_intervals;
    END IF;
    
    -- Update metrics for each date
    FOREACH v_date IN ARRAY v_dates
    LOOP
        INSERT INTO project_b_daily_metrics (
            metric_date,
            total_calls_offered,
            total_calls_handled,
            total_calls_abandoned,
            average_service_level,
            average_handle_time,
            peak_hour,
            peak_hour_calls,
            total_agent_hours
        )
        SELECT
            v_date,
            SUM(calls_offered),
            SUM(calls_handled),
            SUM(calls_abandoned),
            AVG(service_level),
            SUM(total_handle_time)::DECIMAL / NULLIF(SUM(calls_handled), 0),
            peak.hour,
            peak.calls,
            SUM(total_handle_time)::DECIMAL / 3600
        FROM project_b_intervals i
        LEFT JOIN LATERAL (
            SELECT 
                interval_hour as hour,
                SUM(calls_offered) as calls
            FROM project_b_intervals
            WHERE interval_date = v_date
            GROUP BY interval_hour
            ORDER BY calls DESC
            LIMIT 1
        ) peak ON TRUE
        WHERE i.interval_date = v_date
        GROUP BY v_date, peak.hour, peak.calls
        ON CONFLICT (metric_date)
        DO UPDATE SET
            total_calls_offered = EXCLUDED.total_calls_offered,
            total_calls_handled = EXCLUDED.total_calls_handled,
            total_calls_abandoned = EXCLUDED.total_calls_abandoned,
            average_service_level = EXCLUDED.average_service_level,
            average_handle_time = EXCLUDED.average_handle_time,
            peak_hour = EXCLUDED.peak_hour,
            peak_hour_calls = EXCLUDED.peak_hour_calls,
            total_agent_hours = EXCLUDED.total_agent_hours,
            updated_at = NOW();
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. PERFORMANCE OPTIMIZATION INDEXES
-- =====================================================================================

-- Create partitioning for high-volume interval data
-- Note: Requires PostgreSQL 11+
DO $$
BEGIN
    -- Check if partitioning is supported
    IF current_setting('server_version_num')::INTEGER >= 110000 THEN
        -- Create partitioned table
        EXECUTE 'CREATE TABLE IF NOT EXISTS project_b_intervals_partitioned (
            LIKE project_b_intervals INCLUDING ALL
        ) PARTITION BY RANGE (interval_date)';
        
        -- Create monthly partitions for current year
        FOR i IN 0..11 LOOP
            EXECUTE format('
                CREATE TABLE IF NOT EXISTS project_b_intervals_y%s_m%s 
                PARTITION OF project_b_intervals_partitioned
                FOR VALUES FROM (%L) TO (%L)',
                EXTRACT(YEAR FROM CURRENT_DATE),
                LPAD((i+1)::TEXT, 2, '0'),
                DATE_TRUNC('month', CURRENT_DATE) + (i || ' months')::INTERVAL,
                DATE_TRUNC('month', CURRENT_DATE) + ((i+1) || ' months')::INTERVAL
            );
        END LOOP;
    END IF;
END
$$;

-- =====================================================================================
-- 8. MONITORING AND MAINTENANCE PROCEDURES
-- =====================================================================================

-- Function to check import health
CREATE OR REPLACE FUNCTION check_import_health(
    p_days_back INTEGER DEFAULT 7
)
RETURNS TABLE (
    check_date DATE,
    imports_count INTEGER,
    success_rate DECIMAL,
    avg_rows_per_import INTEGER,
    total_errors INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(start_time) as check_date,
        COUNT(*) as imports_count,
        (COUNT(*) FILTER (WHERE status = 'completed'))::DECIMAL / NULLIF(COUNT(*), 0) * 100 as success_rate,
        AVG(processed_rows)::INTEGER as avg_rows_per_import,
        SUM(error_rows)::INTEGER as total_errors
    FROM import_log
    WHERE start_time >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
    GROUP BY DATE(start_time)
    ORDER BY check_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old staging data
CREATE OR REPLACE FUNCTION cleanup_staging_data(
    p_days_to_keep INTEGER DEFAULT 30
)
RETURNS TABLE (
    tables_cleaned TEXT[],
    rows_deleted BIGINT
) AS $$
DECLARE
    v_deleted BIGINT := 0;
    v_temp BIGINT;
    v_tables TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Clean staging_project_b_raw
    DELETE FROM staging_project_b_raw
    WHERE created_at < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS v_temp = ROW_COUNT;
    v_deleted := v_deleted + v_temp;
    IF v_temp > 0 THEN
        v_tables := array_append(v_tables, 'staging_project_b_raw');
    END IF;
    
    -- Clean staging_project_b_processed
    DELETE FROM staging_project_b_processed
    WHERE created_at < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS v_temp = ROW_COUNT;
    v_deleted := v_deleted + v_temp;
    IF v_temp > 0 THEN
        v_tables := array_append(v_tables, 'staging_project_b_processed');
    END IF;
    
    -- Clean old import errors
    DELETE FROM import_errors
    WHERE created_at < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS v_temp = ROW_COUNT;
    v_deleted := v_deleted + v_temp;
    IF v_temp > 0 THEN
        v_tables := array_append(v_tables, 'import_errors');
    END IF;
    
    RETURN QUERY
    SELECT v_tables, v_deleted;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. ROLLBACK CAPABILITIES
-- =====================================================================================

CREATE OR REPLACE FUNCTION rollback_import_batch(
    p_import_batch_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (
    deleted_intervals INTEGER,
    status VARCHAR
) AS $$
DECLARE
    v_deleted_intervals INTEGER := 0;
    v_status VARCHAR;
BEGIN
    -- Check if batch exists and is completed
    SELECT status INTO v_status
    FROM import_log
    WHERE import_batch_id = p_import_batch_id;
    
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'Import batch % not found', p_import_batch_id;
    END IF;
    
    IF v_status != 'completed' THEN
        RAISE EXCEPTION 'Can only rollback completed imports. Current status: %', v_status;
    END IF;
    
    -- Delete from production tables
    DELETE FROM project_b_intervals
    WHERE import_batch_id = p_import_batch_id;
    GET DIAGNOSTICS v_deleted_intervals = ROW_COUNT;
    
    -- Update import log
    UPDATE import_log
    SET 
        status = 'rolled_back',
        warnings = array_append(warnings, 'Rolled back: ' || COALESCE(p_reason, 'No reason provided'))
    WHERE import_batch_id = p_import_batch_id;
    
    -- Recalculate daily metrics for affected dates
    PERFORM update_project_b_daily_metrics();
    
    RETURN QUERY
    SELECT v_deleted_intervals, 'rolled_back'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 10. HELPER VIEWS AND FUNCTIONS
-- =====================================================================================

-- View for import status dashboard
CREATE OR REPLACE VIEW v_import_status AS
SELECT
    l.import_batch_id,
    l.import_type,
    l.file_name,
    l.start_time,
    l.end_time,
    l.status,
    l.total_rows,
    l.processed_rows,
    l.error_rows,
    EXTRACT(EPOCH FROM (COALESCE(l.end_time, NOW()) - l.start_time)) as duration_seconds,
    l.processed_rows::DECIMAL / NULLIF(l.total_rows, 0) * 100 as success_rate,
    l.created_by,
    COUNT(e.error_id) as error_details_count
FROM import_log l
LEFT JOIN import_errors e ON l.import_batch_id = e.import_batch_id
GROUP BY l.import_batch_id, l.import_type, l.file_name, l.start_time, 
         l.end_time, l.status, l.total_rows, l.processed_rows, l.error_rows, l.created_by
ORDER BY l.start_time DESC;

-- Function to get import summary
CREATE OR REPLACE FUNCTION get_import_summary(
    p_import_batch_id UUID
)
RETURNS TABLE (
    metric_name VARCHAR,
    metric_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH batch_data AS (
        SELECT * FROM import_log WHERE import_batch_id = p_import_batch_id
    ),
    interval_stats AS (
        SELECT
            COUNT(*) as interval_count,
            MIN(interval_timestamp) as min_timestamp,
            MAX(interval_timestamp) as max_timestamp,
            SUM(calls_offered) as total_calls,
            AVG(service_level) as avg_sl
        FROM project_b_intervals
        WHERE import_batch_id = p_import_batch_id
    )
    SELECT 'Status', status::TEXT FROM batch_data
    UNION ALL
    SELECT 'Total Rows', total_rows::TEXT FROM batch_data
    UNION ALL
    SELECT 'Processed Rows', processed_rows::TEXT FROM batch_data
    UNION ALL
    SELECT 'Error Rows', error_rows::TEXT FROM batch_data
    UNION ALL
    SELECT 'Date Range', min_timestamp::DATE || ' to ' || max_timestamp::DATE FROM interval_stats
    UNION ALL
    SELECT 'Total Calls', total_calls::TEXT FROM interval_stats
    UNION ALL
    SELECT 'Average Service Level', ROUND(avg_sl, 2) || '%' FROM interval_stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 11. PERMISSIONS
-- =====================================================================================

-- Grant appropriate permissions (adjust as needed)
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_readonly;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_api_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_api_user;

-- =====================================================================================
-- 12. DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION import_project_b_data IS 'Main import function for Project Б data. Handles validation, staging, and production table updates with full transaction control.';
COMMENT ON FUNCTION batch_import_project_b_excel IS 'Batch import function with progress tracking for large Excel files. Returns progress updates during processing.';
COMMENT ON FUNCTION rollback_import_batch IS 'Safely rollback a completed import batch, removing all associated data and recalculating metrics.';
COMMENT ON TABLE project_b_intervals IS 'Main production table for Project Б interval data. Stores all call center metrics at 15m, 30m, or 1h intervals.';
COMMENT ON TABLE project_b_daily_metrics IS 'Aggregated daily metrics for Project Б. Updated automatically after each import.';
COMMENT ON VIEW v_import_status IS 'Dashboard view for monitoring import status and success rates.';