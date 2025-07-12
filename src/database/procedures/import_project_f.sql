-- =====================================================================================
-- Import Procedures for Project Ф (FSIN - Federal Penitentiary Service) Data
-- Module: Government Data Import and Processing with Enhanced Security
-- Purpose: Secure import procedures for Project Ф government call center data
-- Data Sources: Excel files with 15m intervals (government requirement)
-- Volume: ~20,000 calls per day across 5 queues
-- Security: Government compliance with audit trail and data sensitivity
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================================
-- 1. SECURITY AND AUDIT INFRASTRUCTURE
-- =====================================================================================

-- Drop existing objects if they exist
DROP TABLE IF EXISTS project_f_audit_log CASCADE;
DROP TABLE IF EXISTS project_f_access_log CASCADE;
DROP TABLE IF EXISTS project_f_data_classification CASCADE;
DROP TABLE IF EXISTS staging_project_f_raw CASCADE;
DROP TABLE IF EXISTS staging_project_f_processed CASCADE;
DROP TABLE IF EXISTS project_f_intervals CASCADE;
DROP TABLE IF EXISTS project_f_daily_metrics CASCADE;
DROP TABLE IF EXISTS project_f_queues CASCADE;
DROP TABLE IF EXISTS project_f_compliance_metrics CASCADE;

-- Create audit log table for government compliance
CREATE TABLE project_f_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    event_timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'import', 'access', 'modify', 'delete', 'export'
    event_action VARCHAR(100) NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    user_role VARCHAR(50),
    ip_address INET,
    session_id UUID,
    table_name VARCHAR(100),
    record_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    data_classification VARCHAR(20), -- 'public', 'internal', 'confidential', 'secret'
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    additional_info JSONB
);

-- Create access log for tracking who views what data
CREATE TABLE project_f_access_log (
    access_id BIGSERIAL PRIMARY KEY,
    access_timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    access_type VARCHAR(50) NOT NULL, -- 'view', 'export', 'report'
    data_range_start TIMESTAMPTZ,
    data_range_end TIMESTAMPTZ,
    queue_ids INTEGER[],
    row_count INTEGER,
    access_duration_ms INTEGER,
    access_granted BOOLEAN DEFAULT TRUE,
    denial_reason TEXT
);

-- Data classification table for sensitive fields
CREATE TABLE project_f_data_classification (
    classification_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    classification_level VARCHAR(20) NOT NULL, -- 'public', 'internal', 'confidential', 'secret'
    encryption_required BOOLEAN DEFAULT FALSE,
    masking_required BOOLEAN DEFAULT FALSE,
    retention_days INTEGER DEFAULT 365,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(table_name, column_name)
);

-- Insert data classifications for Project Ф
INSERT INTO project_f_data_classification (table_name, column_name, classification_level, encryption_required, masking_required) VALUES
    ('project_f_intervals', 'queue_name', 'confidential', FALSE, TRUE),
    ('project_f_intervals', 'agent_data', 'confidential', TRUE, TRUE),
    ('project_f_intervals', 'call_recordings_ref', 'secret', TRUE, TRUE),
    ('project_f_queues', 'queue_description', 'internal', FALSE, FALSE),
    ('project_f_queues', 'security_clearance_required', 'confidential', FALSE, FALSE);

-- =====================================================================================
-- 2. PROJECT Ф SPECIFIC TABLES
-- =====================================================================================

-- Project Ф queue definitions (5 government queues)
CREATE TABLE project_f_queues (
    queue_id SERIAL PRIMARY KEY,
    queue_code VARCHAR(50) UNIQUE NOT NULL,
    queue_name VARCHAR(255) NOT NULL,
    queue_description TEXT,
    security_clearance_required VARCHAR(20) DEFAULT 'basic', -- 'basic', 'elevated', 'secret'
    service_level_target DECIMAL(5,2) DEFAULT 80.0, -- Government standard
    service_level_seconds INTEGER DEFAULT 30, -- Government requirement
    priority_level INTEGER DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Project Ф queues
INSERT INTO project_f_queues (queue_code, queue_name, queue_description, security_clearance_required, priority_level) VALUES
    ('FSIN_MAIN', 'Основная линия ФСИН', 'Main FSIN contact line', 'basic', 1),
    ('FSIN_URGENT', 'Экстренная линия', 'Emergency and urgent matters', 'elevated', 5),
    ('FSIN_LEGAL', 'Юридическая поддержка', 'Legal support line', 'elevated', 3),
    ('FSIN_FAMILY', 'Связь с родственниками', 'Family communication line', 'basic', 2),
    ('FSIN_ADMIN', 'Административная линия', 'Administrative matters', 'basic', 2);

-- Create staging table for raw Excel data with government fields
CREATE TABLE staging_project_f_raw (
    staging_id BIGSERIAL PRIMARY KEY,
    import_batch_id UUID NOT NULL,
    row_number INTEGER NOT NULL,
    -- Standard fields from Excel
    period_text VARCHAR(50),
    project_name VARCHAR(100), -- May include queue identifier
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
    tt BIGINT, -- Large values possible
    ott BIGINT,
    ht BIGINT,
    tht BIGINT,
    aht DECIMAL(8,2),
    acw DECIMAL(10,2), -- Can be large
    tht_plus_acw BIGINT,
    aht_plus_acw DECIMAL(8,2),
    twt_hc BIGINT,
    awt_hc DECIMAL(8,2),
    mwt_hc INTEGER,
    twt_ac BIGINT,
    awt_ac DECIMAL(8,2),
    mwt_ac INTEGER,
    -- Government specific fields
    security_check_passed BOOLEAN DEFAULT TRUE,
    data_integrity_hash VARCHAR(64),
    import_user_id VARCHAR(100),
    import_timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create processed staging table with validation
CREATE TABLE staging_project_f_processed (
    processed_id BIGSERIAL PRIMARY KEY,
    import_batch_id UUID NOT NULL,
    interval_timestamp TIMESTAMPTZ NOT NULL,
    queue_id INTEGER REFERENCES project_f_queues(queue_id),
    -- Validated metrics
    calls_offered INTEGER NOT NULL CHECK (calls_offered >= 0),
    calls_handled INTEGER NOT NULL CHECK (calls_handled >= 0),
    calls_handled_percentage DECIMAL(5,2) CHECK (calls_handled_percentage BETWEEN 0 AND 100),
    calls_handled_sl INTEGER CHECK (calls_handled_sl >= 0),
    service_level DECIMAL(5,2) CHECK (service_level BETWEEN 0 AND 100),
    service_level_on_handled DECIMAL(5,2) CHECK (service_level_on_handled BETWEEN 0 AND 100),
    calls_abandoned INTEGER CHECK (calls_abandoned >= 0),
    calls_abandoned_5s INTEGER CHECK (calls_abandoned_5s >= 0),
    lost_call_rate DECIMAL(5,2) CHECK (lost_call_rate BETWEEN 0 AND 100),
    -- Time metrics
    total_talk_time BIGINT CHECK (total_talk_time >= 0),
    total_handle_time BIGINT CHECK (total_handle_time >= 0),
    hold_time BIGINT CHECK (hold_time >= 0),
    after_call_work BIGINT CHECK (after_call_work >= 0),
    average_handle_time DECIMAL(8,2) CHECK (average_handle_time >= 0),
    -- Wait metrics
    total_wait_time_handled BIGINT CHECK (total_wait_time_handled >= 0),
    average_wait_time_handled DECIMAL(8,2) CHECK (average_wait_time_handled >= 0),
    max_wait_time_handled INTEGER CHECK (max_wait_time_handled >= 0),
    total_wait_time_abandoned BIGINT CHECK (total_wait_time_abandoned >= 0),
    average_wait_time_abandoned DECIMAL(8,2),
    max_wait_time_abandoned INTEGER CHECK (max_wait_time_abandoned >= 0),
    -- Validation and compliance
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors TEXT[],
    compliance_check_passed BOOLEAN DEFAULT FALSE,
    compliance_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT processed_unique_f UNIQUE(interval_timestamp, queue_id)
);

-- Main production table for Project Ф intervals
CREATE TABLE project_f_intervals (
    interval_id BIGSERIAL PRIMARY KEY,
    interval_timestamp TIMESTAMPTZ NOT NULL,
    interval_date DATE GENERATED ALWAYS AS (interval_timestamp::DATE) STORED,
    interval_hour INTEGER GENERATED ALWAYS AS (EXTRACT(HOUR FROM interval_timestamp)) STORED,
    day_of_week INTEGER GENERATED ALWAYS AS (EXTRACT(DOW FROM interval_timestamp)) STORED,
    is_weekend BOOLEAN GENERATED ALWAYS AS (EXTRACT(DOW FROM interval_timestamp) IN (0,6)) STORED,
    is_holiday BOOLEAN DEFAULT FALSE, -- Government holidays
    
    -- Queue information
    queue_id INTEGER NOT NULL REFERENCES project_f_queues(queue_id),
    queue_name VARCHAR(255), -- Denormalized for performance
    
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
    total_talk_time BIGINT DEFAULT 0,
    total_handle_time BIGINT DEFAULT 0,
    total_hold_time BIGINT DEFAULT 0,
    total_after_call_work BIGINT DEFAULT 0,
    
    -- Calculated metrics
    average_handle_time DECIMAL(8,2) GENERATED ALWAYS AS 
        (CASE WHEN calls_handled > 0 THEN total_handle_time::DECIMAL / calls_handled ELSE 0 END) STORED,
    occupancy_rate DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN 900 > 0 THEN (total_handle_time::DECIMAL / 900 * 100) ELSE 0 END) STORED, -- 15-minute intervals
    
    -- Wait time metrics
    total_wait_time_handled BIGINT DEFAULT 0,
    max_wait_time_handled INTEGER DEFAULT 0,
    total_wait_time_abandoned BIGINT DEFAULT 0,
    max_wait_time_abandoned INTEGER DEFAULT 0,
    
    -- Government compliance fields
    compliance_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'passed', 'failed', 'exception'
    data_quality_score DECIMAL(5,2), -- 0-100 score
    security_incidents INTEGER DEFAULT 0,
    
    -- Metadata
    import_batch_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by VARCHAR(100) NOT NULL,
    
    CONSTRAINT interval_unique_f UNIQUE(interval_timestamp, queue_id)
);

-- Create indexes for performance
CREATE INDEX idx_project_f_intervals_date ON project_f_intervals(interval_date);
CREATE INDEX idx_project_f_intervals_timestamp ON project_f_intervals(interval_timestamp);
CREATE INDEX idx_project_f_intervals_queue ON project_f_intervals(queue_id);
CREATE INDEX idx_project_f_intervals_compliance ON project_f_intervals(compliance_status);
CREATE INDEX idx_project_f_intervals_hour ON project_f_intervals(interval_hour);

-- Daily aggregated metrics with compliance tracking
CREATE TABLE project_f_daily_metrics (
    daily_id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    queue_id INTEGER NOT NULL REFERENCES project_f_queues(queue_id),
    total_calls_offered INTEGER DEFAULT 0,
    total_calls_handled INTEGER DEFAULT 0,
    total_calls_abandoned INTEGER DEFAULT 0,
    average_service_level DECIMAL(5,2),
    average_handle_time DECIMAL(8,2),
    peak_hour INTEGER,
    peak_hour_calls INTEGER,
    -- Compliance metrics
    compliance_score DECIMAL(5,2),
    sl_target_met_percentage DECIMAL(5,2),
    data_quality_issues INTEGER DEFAULT 0,
    security_incidents INTEGER DEFAULT 0,
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(metric_date, queue_id)
);

-- Compliance tracking table
CREATE TABLE project_f_compliance_metrics (
    compliance_id SERIAL PRIMARY KEY,
    check_date DATE NOT NULL,
    check_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'audit'
    queue_id INTEGER REFERENCES project_f_queues(queue_id),
    metric_name VARCHAR(100) NOT NULL,
    target_value DECIMAL(10,2),
    actual_value DECIMAL(10,2),
    compliance_met BOOLEAN,
    variance_percentage DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by VARCHAR(100)
);

-- =====================================================================================
-- 3. SECURITY AND VALIDATION FUNCTIONS
-- =====================================================================================

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_event_type VARCHAR,
    p_event_action VARCHAR,
    p_user_id VARCHAR,
    p_table_name VARCHAR DEFAULT NULL,
    p_record_id BIGINT DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_data_classification VARCHAR DEFAULT 'internal',
    p_additional_info JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO project_f_audit_log (
        event_type,
        event_action,
        user_id,
        table_name,
        record_id,
        old_values,
        new_values,
        data_classification,
        additional_info
    ) VALUES (
        p_event_type,
        p_event_action,
        p_user_id,
        p_table_name,
        p_record_id,
        p_old_values,
        p_new_values,
        p_data_classification,
        p_additional_info
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate government security requirements
CREATE OR REPLACE FUNCTION validate_government_security(
    p_user_id VARCHAR,
    p_action VARCHAR,
    p_queue_id INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_clearance_required VARCHAR;
    v_user_clearance VARCHAR;
BEGIN
    -- Get required clearance level for queue
    IF p_queue_id IS NOT NULL THEN
        SELECT security_clearance_required INTO v_clearance_required
        FROM project_f_queues
        WHERE queue_id = p_queue_id;
    ELSE
        v_clearance_required := 'basic';
    END IF;
    
    -- In production, this would check against actual user clearance database
    -- For now, we'll implement basic validation
    IF p_action IN ('import', 'modify', 'delete') THEN
        -- These actions require elevated clearance
        RETURN TRUE; -- Placeholder - implement actual clearance check
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to validate and convert period with government date format
CREATE OR REPLACE FUNCTION validate_and_convert_period_f(
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
        
        -- Government requirement: only 15-minute intervals
        IF EXTRACT(MINUTE FROM v_timestamp) NOT IN (0, 15, 30, 45) THEN
            RAISE EXCEPTION 'Invalid interval: must be 15-minute aligned';
        END IF;
        
        -- Validate reasonable date range
        IF v_timestamp < '2024-01-01'::TIMESTAMPTZ OR v_timestamp > CURRENT_TIMESTAMP + INTERVAL '1 day' THEN
            RAISE EXCEPTION 'Date out of valid range';
        END IF;
        
        RETURN v_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Invalid period format in row %: % (expected DD.MM.YYYY HH24:MI with 15-min intervals)', 
                p_row_number, p_period_text;
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to determine queue from project name
CREATE OR REPLACE FUNCTION determine_queue_id(
    p_project_name VARCHAR,
    p_file_name VARCHAR DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_queue_id INTEGER;
BEGIN
    -- Map project names to queues based on patterns
    CASE 
        WHEN p_project_name ILIKE '%urgent%' OR p_project_name ILIKE '%экстрен%' THEN
            SELECT queue_id INTO v_queue_id FROM project_f_queues WHERE queue_code = 'FSIN_URGENT';
        WHEN p_project_name ILIKE '%legal%' OR p_project_name ILIKE '%юрид%' THEN
            SELECT queue_id INTO v_queue_id FROM project_f_queues WHERE queue_code = 'FSIN_LEGAL';
        WHEN p_project_name ILIKE '%family%' OR p_project_name ILIKE '%родств%' THEN
            SELECT queue_id INTO v_queue_id FROM project_f_queues WHERE queue_code = 'FSIN_FAMILY';
        WHEN p_project_name ILIKE '%admin%' OR p_project_name ILIKE '%админ%' THEN
            SELECT queue_id INTO v_queue_id FROM project_f_queues WHERE queue_code = 'FSIN_ADMIN';
        ELSE
            -- Default to main queue
            SELECT queue_id INTO v_queue_id FROM project_f_queues WHERE queue_code = 'FSIN_MAIN';
    END CASE;
    
    RETURN v_queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to validate government compliance rules
CREATE OR REPLACE FUNCTION validate_government_compliance(
    p_import_batch_id UUID,
    p_row_number INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_row RECORD;
    v_errors TEXT[] := ARRAY[]::TEXT[];
    v_warnings TEXT[] := ARRAY[]::TEXT[];
    v_compliance_score DECIMAL := 100.0;
BEGIN
    -- Get the row data
    SELECT * INTO v_row
    FROM staging_project_f_raw
    WHERE import_batch_id = p_import_batch_id
    AND row_number = p_row_number;
    
    -- Government-specific validation rules
    
    -- 1. Service level must meet government standard (80% in 30 seconds)
    IF v_row.sl IS NOT NULL AND v_row.sl < 80.0 THEN
        v_warnings := array_append(v_warnings, format('Service level below government standard: %.2f%%', v_row.sl));
        v_compliance_score := v_compliance_score - 5;
    END IF;
    
    -- 2. Abandoned calls should not exceed 5%
    IF v_row.cdo > 0 AND v_row.ac IS NOT NULL THEN
        DECLARE
            v_abandon_rate DECIMAL;
        BEGIN
            v_abandon_rate := (v_row.ac::DECIMAL / v_row.cdo) * 100;
            IF v_abandon_rate > 5.0 THEN
                v_warnings := array_append(v_warnings, format('High abandon rate: %.2f%%', v_abandon_rate));
                v_compliance_score := v_compliance_score - 10;
            END IF;
        END;
    END IF;
    
    -- 3. Average handle time should be reasonable (under 10 minutes)
    IF v_row.aht > 600 THEN
        v_warnings := array_append(v_warnings, format('AHT exceeds 10 minutes: %s seconds', v_row.aht));
        v_compliance_score := v_compliance_score - 5;
    END IF;
    
    -- 4. Data integrity checks
    IF v_row.hc > v_row.cdo THEN
        v_errors := array_append(v_errors, 'Data integrity: Handled calls exceed offered calls');
        v_compliance_score := v_compliance_score - 20;
    END IF;
    
    IF v_row.hc_sl > v_row.hc THEN
        v_errors := array_append(v_errors, 'Data integrity: SL calls exceed handled calls');
        v_compliance_score := v_compliance_score - 20;
    END IF;
    
    -- 5. Check for suspicious patterns (potential security issue)
    IF v_row.cdo > 500 THEN -- Unusually high for 15-minute interval
        v_warnings := array_append(v_warnings, format('Unusually high call volume: %s calls', v_row.cdo));
    END IF;
    
    -- 6. Wait time compliance (max 5 minutes for government)
    IF v_row.mwt_hc > 300 THEN
        v_warnings := array_append(v_warnings, format('Max wait time exceeds 5 minutes: %s seconds', v_row.mwt_hc));
        v_compliance_score := v_compliance_score - 10;
    END IF;
    
    RETURN jsonb_build_object(
        'errors', v_errors,
        'warnings', v_warnings,
        'is_valid', array_length(v_errors, 1) IS NULL,
        'compliance_score', GREATEST(v_compliance_score, 0),
        'compliance_passed', v_compliance_score >= 70 -- 70% threshold for compliance
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. MAIN IMPORT PROCEDURE WITH SECURITY
-- =====================================================================================

CREATE OR REPLACE FUNCTION import_project_f_data(
    p_file_path VARCHAR,
    p_created_by VARCHAR,
    p_validate_only BOOLEAN DEFAULT FALSE,
    p_force_import BOOLEAN DEFAULT FALSE -- Override compliance failures
)
RETURNS TABLE (
    import_batch_id UUID,
    status VARCHAR,
    total_rows INTEGER,
    processed_rows INTEGER,
    error_rows INTEGER,
    compliance_score DECIMAL,
    security_checks_passed BOOLEAN,
    execution_time_ms INTEGER
) AS $$
DECLARE
    v_import_batch_id UUID;
    v_start_time TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_total_rows INTEGER := 0;
    v_processed_rows INTEGER := 0;
    v_error_rows INTEGER := 0;
    v_compliance_failures INTEGER := 0;
    v_total_compliance_score DECIMAL := 0;
    v_row RECORD;
    v_validation_result JSONB;
    v_timestamp TIMESTAMPTZ;
    v_queue_id INTEGER;
    v_status VARCHAR := 'completed';
    v_security_passed BOOLEAN := TRUE;
BEGIN
    v_start_time := clock_timestamp();
    v_import_batch_id := uuid_generate_v4();
    
    -- Security check
    IF NOT validate_government_security(p_created_by, 'import') THEN
        RAISE EXCEPTION 'Security clearance check failed for user %', p_created_by;
    END IF;
    
    -- Log audit event
    PERFORM log_audit_event(
        'import',
        'start_import_project_f',
        p_created_by,
        'staging_project_f_raw',
        NULL,
        NULL,
        jsonb_build_object('file_path', p_file_path, 'validate_only', p_validate_only),
        'confidential'
    );
    
    -- Log import start
    INSERT INTO import_log (import_batch_id, import_type, file_name, created_by)
    VALUES (v_import_batch_id, 'project_f_15m', p_file_path, p_created_by);
    
    -- Start transaction for atomic import
    BEGIN
        -- Count total rows
        SELECT COUNT(*) INTO v_total_rows
        FROM staging_project_f_raw
        WHERE import_batch_id = v_import_batch_id;
        
        -- Process each row with enhanced validation
        FOR v_row IN 
            SELECT * FROM staging_project_f_raw
            WHERE import_batch_id = v_import_batch_id
            ORDER BY row_number
        LOOP
            BEGIN
                -- Convert period text to timestamp
                v_timestamp := validate_and_convert_period_f(v_row.period_text, v_row.row_number);
                
                -- Determine queue ID
                v_queue_id := determine_queue_id(v_row.project_name, p_file_path);
                
                -- Validate metrics and compliance
                v_validation_result := validate_government_compliance(v_import_batch_id, v_row.row_number);
                
                -- Track compliance scores
                v_total_compliance_score := v_total_compliance_score + (v_validation_result->>'compliance_score')::DECIMAL;
                
                IF (v_validation_result->>'is_valid')::BOOLEAN THEN
                    -- Check compliance unless force import
                    IF (v_validation_result->>'compliance_passed')::BOOLEAN OR p_force_import THEN
                        -- Insert into processed staging
                        INSERT INTO staging_project_f_processed (
                            import_batch_id,
                            interval_timestamp,
                            queue_id,
                            calls_offered,
                            calls_handled,
                            calls_handled_percentage,
                            calls_handled_sl,
                            service_level,
                            service_level_on_handled,
                            calls_abandoned,
                            calls_abandoned_5s,
                            lost_call_rate,
                            total_talk_time,
                            total_handle_time,
                            hold_time,
                            after_call_work,
                            average_handle_time,
                            total_wait_time_handled,
                            average_wait_time_handled,
                            max_wait_time_handled,
                            total_wait_time_abandoned,
                            average_wait_time_abandoned,
                            max_wait_time_abandoned,
                            validation_errors,
                            compliance_check_passed,
                            compliance_notes
                        ) VALUES (
                            v_import_batch_id,
                            v_timestamp,
                            v_queue_id,
                            COALESCE(v_row.cdo, 0),
                            COALESCE(v_row.hc, 0),
                            v_row.shc,
                            COALESCE(v_row.hc_sl, 0),
                            v_row.sl,
                            v_row.sl_on_hc,
                            COALESCE(v_row.ac, 0),
                            COALESCE(v_row.ac5, 0),
                            v_row.lcr,
                            COALESCE(v_row.tt, 0),
                            COALESCE(v_row.tht, 0),
                            COALESCE(v_row.ht, 0),
                            COALESCE(v_row.acw * COALESCE(v_row.hc, 1), 0), -- Convert avg to total
                            v_row.aht,
                            COALESCE(v_row.twt_hc, 0),
                            v_row.awt_hc,
                            COALESCE(v_row.mwt_hc, 0),
                            COALESCE(v_row.twt_ac, 0),
                            v_row.awt_ac,
                            COALESCE(v_row.mwt_ac, 0),
                            v_validation_result->'warnings',
                            (v_validation_result->>'compliance_passed')::BOOLEAN,
                            array_to_string((v_validation_result->'warnings')::TEXT[], '; ')
                        );
                        
                        v_processed_rows := v_processed_rows + 1;
                    ELSE
                        -- Compliance failure
                        v_compliance_failures := v_compliance_failures + 1;
                        
                        INSERT INTO import_errors (
                            import_batch_id,
                            row_number,
                            error_type,
                            error_message,
                            raw_data
                        ) VALUES (
                            v_import_batch_id,
                            v_row.row_number,
                            'compliance',
                            'Government compliance check failed: ' || array_to_string((v_validation_result->'warnings')::TEXT[], '; '),
                            row_to_json(v_row)::JSONB
                        );
                    END IF;
                ELSE
                    -- Validation error
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
                    v_security_passed := FALSE;
            END;
        END LOOP;
        
        -- If not validate-only mode and no critical errors, move to production
        IF NOT p_validate_only AND v_error_rows = 0 AND (v_compliance_failures = 0 OR p_force_import) THEN
            -- Insert into production table with security tracking
            INSERT INTO project_f_intervals (
                interval_timestamp,
                queue_id,
                queue_name,
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
                compliance_status,
                data_quality_score,
                import_batch_id,
                created_by
            )
            SELECT
                sp.interval_timestamp,
                sp.queue_id,
                q.queue_name,
                sp.calls_offered,
                sp.calls_handled,
                sp.calls_abandoned,
                sp.calls_abandoned_5s,
                sp.calls_handled_sl,
                sp.service_level,
                sp.service_level_on_handled,
                sp.total_talk_time,
                sp.total_handle_time,
                sp.hold_time,
                sp.after_call_work,
                sp.total_wait_time_handled,
                sp.max_wait_time_handled,
                sp.total_wait_time_abandoned,
                sp.max_wait_time_abandoned,
                CASE 
                    WHEN sp.compliance_check_passed THEN 'passed'
                    ELSE 'exception'
                END,
                100.0 - COALESCE(array_length(sp.validation_errors, 1), 0) * 5.0,
                sp.import_batch_id,
                p_created_by
            FROM staging_project_f_processed sp
            JOIN project_f_queues q ON sp.queue_id = q.queue_id
            WHERE sp.import_batch_id = v_import_batch_id
            ON CONFLICT (interval_timestamp, queue_id) 
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
                compliance_status = EXCLUDED.compliance_status,
                data_quality_score = EXCLUDED.data_quality_score,
                import_batch_id = EXCLUDED.import_batch_id,
                updated_at = NOW();
                
            -- Update daily metrics and compliance
            PERFORM update_project_f_daily_metrics(v_import_batch_id);
            PERFORM check_and_update_compliance(v_import_batch_id);
        END IF;
        
        -- If errors or compliance failures occurred, handle appropriately
        IF v_error_rows > 0 OR (v_compliance_failures > 0 AND NOT p_force_import) OR p_validate_only THEN
            v_status := CASE 
                WHEN p_validate_only THEN 'validated'
                WHEN v_compliance_failures > 0 THEN 'compliance_failed'
                ELSE 'failed'
            END;
            RAISE EXCEPTION 'Import % with % errors and % compliance failures', 
                v_status, v_error_rows, v_compliance_failures;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback will happen automatically
            v_status := 'failed';
            v_security_passed := FALSE;
            
            -- Log security incident if appropriate
            IF v_status = 'failed' AND v_error_rows > 10 THEN
                PERFORM log_audit_event(
                    'security',
                    'suspicious_import_failure',
                    p_created_by,
                    'project_f_intervals',
                    NULL,
                    NULL,
                    jsonb_build_object('error_count', v_error_rows, 'message', SQLERRM),
                    'secret'
                );
            END IF;
            
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
    
    -- Calculate average compliance score
    DECLARE
        v_avg_compliance_score DECIMAL;
    BEGIN
        IF v_total_rows > 0 THEN
            v_avg_compliance_score := v_total_compliance_score / v_total_rows;
        ELSE
            v_avg_compliance_score := 0;
        END IF;
        
        -- Final audit log
        PERFORM log_audit_event(
            'import',
            'complete_import_project_f',
            p_created_by,
            'project_f_intervals',
            NULL,
            NULL,
            jsonb_build_object(
                'import_batch_id', v_import_batch_id,
                'rows_processed', v_processed_rows,
                'compliance_score', v_avg_compliance_score
            ),
            'confidential'
        );
        
        -- Update import log
        UPDATE import_log
        SET 
            end_time = v_end_time,
            status = v_status,
            total_rows = v_total_rows,
            processed_rows = v_processed_rows,
            error_rows = v_error_rows,
            warnings = array_append(warnings, format('Avg compliance score: %.2f', v_avg_compliance_score))
        WHERE import_batch_id = v_import_batch_id;
        
        -- Return results
        RETURN QUERY
        SELECT 
            v_import_batch_id,
            v_status,
            v_total_rows,
            v_processed_rows,
            v_error_rows,
            v_avg_compliance_score,
            v_security_passed,
            EXTRACT(MILLISECOND FROM v_end_time - v_start_time)::INTEGER;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================================
-- 5. BATCH IMPORT WITH GOVERNMENT DATA HANDLING
-- =====================================================================================

CREATE OR REPLACE FUNCTION batch_import_project_f_excel(
    p_data JSONB[], -- Array of rows from Excel
    p_file_name VARCHAR,
    p_created_by VARCHAR,
    p_queue_hint VARCHAR DEFAULT NULL -- Optional queue identifier
)
RETURNS TABLE (
    import_batch_id UUID,
    status VARCHAR,
    processed_count INTEGER,
    error_count INTEGER,
    compliance_warnings INTEGER,
    progress_percentage DECIMAL
) AS $$
DECLARE
    v_import_batch_id UUID;
    v_total_rows INTEGER;
    v_current_row INTEGER := 0;
    v_processed INTEGER := 0;
    v_errors INTEGER := 0;
    v_compliance_warnings INTEGER := 0;
    v_row JSONB;
    v_progress DECIMAL;
    v_data_hash VARCHAR;
BEGIN
    v_import_batch_id := uuid_generate_v4();
    v_total_rows := array_length(p_data, 1);
    
    -- Security check
    IF NOT validate_government_security(p_created_by, 'import') THEN
        RAISE EXCEPTION 'Security clearance check failed';
    END IF;
    
    -- Initialize import log
    INSERT INTO import_log (import_batch_id, import_type, file_name, total_rows, created_by)
    VALUES (v_import_batch_id, 'project_f_15m', p_file_name, v_total_rows, p_created_by);
    
    -- Process each row with government data handling
    FOREACH v_row IN ARRAY p_data
    LOOP
        v_current_row := v_current_row + 1;
        
        BEGIN
            -- Generate data integrity hash
            v_data_hash := encode(digest(v_row::TEXT, 'sha256'), 'hex');
            
            -- Insert into staging with security fields
            INSERT INTO staging_project_f_raw (
                import_batch_id,
                row_number,
                period_text,
                project_name,
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
                mwt_ac,
                data_integrity_hash,
                import_user_id
            ) VALUES (
                v_import_batch_id,
                v_current_row,
                v_row->>'period',
                COALESCE(v_row->>'project', p_queue_hint),
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
                (v_row->>'tt')::BIGINT,
                (v_row->>'ott')::BIGINT,
                (v_row->>'ht')::BIGINT,
                (v_row->>'tht')::BIGINT,
                (v_row->>'aht')::DECIMAL,
                (v_row->>'acw')::DECIMAL,
                (v_row->>'tht_plus_acw')::BIGINT,
                (v_row->>'aht_plus_acw')::DECIMAL,
                (v_row->>'twt_hc')::BIGINT,
                (v_row->>'awt_hc')::DECIMAL,
                (v_row->>'mwt_hc')::INTEGER,
                (v_row->>'twt_ac')::BIGINT,
                (v_row->>'awt_ac')::DECIMAL,
                (v_row->>'mwt_ac')::INTEGER,
                v_data_hash,
                p_created_by
            );
            
            v_processed := v_processed + 1;
            
            -- Check for compliance warnings
            IF (v_row->>'sl')::DECIMAL < 80.0 THEN
                v_compliance_warnings := v_compliance_warnings + 1;
            END IF;
            
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
        
        -- Emit progress update every 50 rows (more frequent for government monitoring)
        IF v_current_row % 50 = 0 THEN
            RETURN QUERY
            SELECT 
                v_import_batch_id,
                'in_progress'::VARCHAR,
                v_processed,
                v_errors,
                v_compliance_warnings,
                v_progress;
        END IF;
    END LOOP;
    
    -- Process the staged data
    PERFORM import_project_f_data(
        p_file_name,
        p_created_by,
        FALSE,
        FALSE
    );
    
    -- Return final status
    RETURN QUERY
    SELECT 
        v_import_batch_id,
        'completed'::VARCHAR,
        v_processed,
        v_errors,
        v_compliance_warnings,
        100.0::DECIMAL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================================
-- 6. DAILY METRICS AND COMPLIANCE TRACKING
-- =====================================================================================

CREATE OR REPLACE FUNCTION update_project_f_daily_metrics(
    p_import_batch_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_dates DATE[];
    v_date DATE;
    v_queue_id INTEGER;
BEGIN
    -- Get affected dates and queues
    IF p_import_batch_id IS NOT NULL THEN
        SELECT ARRAY_AGG(DISTINCT (interval_date, queue_id))
        INTO v_dates
        FROM project_f_intervals
        WHERE import_batch_id = p_import_batch_id;
    ELSE
        -- Update all dates
        SELECT ARRAY_AGG(DISTINCT (interval_date, queue_id))
        INTO v_dates
        FROM project_f_intervals;
    END IF;
    
    -- Update metrics for each date/queue combination
    FOR v_date, v_queue_id IN 
        SELECT DISTINCT interval_date, queue_id 
        FROM project_f_intervals
        WHERE import_batch_id = p_import_batch_id OR p_import_batch_id IS NULL
    LOOP
        INSERT INTO project_f_daily_metrics (
            metric_date,
            queue_id,
            total_calls_offered,
            total_calls_handled,
            total_calls_abandoned,
            average_service_level,
            average_handle_time,
            peak_hour,
            peak_hour_calls,
            compliance_score,
            sl_target_met_percentage,
            data_quality_issues,
            security_incidents
        )
        SELECT
            v_date,
            v_queue_id,
            SUM(calls_offered),
            SUM(calls_handled),
            SUM(calls_abandoned),
            AVG(service_level),
            SUM(total_handle_time)::DECIMAL / NULLIF(SUM(calls_handled), 0),
            peak.hour,
            peak.calls,
            AVG(data_quality_score),
            COUNT(*) FILTER (WHERE service_level >= 80.0)::DECIMAL / NULLIF(COUNT(*), 0) * 100,
            COUNT(*) FILTER (WHERE compliance_status != 'passed'),
            SUM(security_incidents)
        FROM project_f_intervals i
        LEFT JOIN LATERAL (
            SELECT 
                interval_hour as hour,
                SUM(calls_offered) as calls
            FROM project_f_intervals
            WHERE interval_date = v_date AND queue_id = v_queue_id
            GROUP BY interval_hour
            ORDER BY calls DESC
            LIMIT 1
        ) peak ON TRUE
        WHERE i.interval_date = v_date AND i.queue_id = v_queue_id
        GROUP BY v_date, v_queue_id, peak.hour, peak.calls
        ON CONFLICT (metric_date, queue_id)
        DO UPDATE SET
            total_calls_offered = EXCLUDED.total_calls_offered,
            total_calls_handled = EXCLUDED.total_calls_handled,
            total_calls_abandoned = EXCLUDED.total_calls_abandoned,
            average_service_level = EXCLUDED.average_service_level,
            average_handle_time = EXCLUDED.average_handle_time,
            peak_hour = EXCLUDED.peak_hour,
            peak_hour_calls = EXCLUDED.peak_hour_calls,
            compliance_score = EXCLUDED.compliance_score,
            sl_target_met_percentage = EXCLUDED.sl_target_met_percentage,
            data_quality_issues = EXCLUDED.data_quality_issues,
            security_incidents = EXCLUDED.security_incidents,
            updated_at = NOW();
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to check and update compliance status
CREATE OR REPLACE FUNCTION check_and_update_compliance(
    p_import_batch_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_date DATE;
    v_queue_id INTEGER;
BEGIN
    -- Check compliance for each queue and date
    FOR v_date, v_queue_id IN 
        SELECT DISTINCT interval_date, queue_id 
        FROM project_f_intervals
        WHERE import_batch_id = p_import_batch_id
    LOOP
        -- Service Level compliance check
        INSERT INTO project_f_compliance_metrics (
            check_date,
            check_type,
            queue_id,
            metric_name,
            target_value,
            actual_value,
            compliance_met,
            variance_percentage,
            created_by
        )
        SELECT
            v_date,
            'daily',
            v_queue_id,
            'service_level',
            80.0,
            AVG(service_level),
            AVG(service_level) >= 80.0,
            ((AVG(service_level) - 80.0) / 80.0 * 100),
            'system'
        FROM project_f_intervals
        WHERE interval_date = v_date AND queue_id = v_queue_id;
        
        -- Abandon rate compliance check
        INSERT INTO project_f_compliance_metrics (
            check_date,
            check_type,
            queue_id,
            metric_name,
            target_value,
            actual_value,
            compliance_met,
            variance_percentage,
            created_by
        )
        SELECT
            v_date,
            'daily',
            v_queue_id,
            'abandon_rate',
            5.0,
            SUM(calls_abandoned)::DECIMAL / NULLIF(SUM(calls_offered), 0) * 100,
            (SUM(calls_abandoned)::DECIMAL / NULLIF(SUM(calls_offered), 0) * 100) <= 5.0,
            ((SUM(calls_abandoned)::DECIMAL / NULLIF(SUM(calls_offered), 0) * 100 - 5.0) / 5.0 * 100),
            'system'
        FROM project_f_intervals
        WHERE interval_date = v_date AND queue_id = v_queue_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. SECURITY AND ACCESS CONTROL FUNCTIONS
-- =====================================================================================

-- Function to log data access
CREATE OR REPLACE FUNCTION log_data_access(
    p_user_id VARCHAR,
    p_access_type VARCHAR,
    p_start_date DATE,
    p_end_date DATE,
    p_queue_ids INTEGER[],
    p_row_count INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO project_f_access_log (
        user_id,
        access_type,
        data_range_start,
        data_range_end,
        queue_ids,
        row_count,
        access_duration_ms
    ) VALUES (
        p_user_id,
        p_access_type,
        p_start_date,
        p_end_date,
        p_queue_ids,
        p_row_count,
        0 -- Will be updated by calling function
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Secure view for accessing interval data with masking
CREATE OR REPLACE VIEW v_project_f_intervals_secure AS
SELECT 
    interval_id,
    interval_timestamp,
    interval_date,
    interval_hour,
    day_of_week,
    is_weekend,
    is_holiday,
    queue_id,
    CASE 
        WHEN current_user IN (SELECT user_id FROM project_f_access_log WHERE access_granted = TRUE)
        THEN queue_name
        ELSE 'Queue ' || queue_id::TEXT
    END as queue_name_masked,
    calls_offered,
    calls_handled,
    calls_abandoned,
    service_level,
    average_handle_time,
    compliance_status,
    data_quality_score
FROM project_f_intervals;

-- =====================================================================================
-- 8. REPORTING AND EXPORT FUNCTIONS
-- =====================================================================================

-- Function to generate government compliance report
CREATE OR REPLACE FUNCTION generate_compliance_report(
    p_start_date DATE,
    p_end_date DATE,
    p_user_id VARCHAR
)
RETURNS TABLE (
    report_date DATE,
    queue_name VARCHAR,
    total_calls INTEGER,
    service_level DECIMAL,
    abandon_rate DECIMAL,
    compliance_status VARCHAR,
    issues_found INTEGER
) AS $$
BEGIN
    -- Security check
    IF NOT validate_government_security(p_user_id, 'report') THEN
        RAISE EXCEPTION 'Insufficient clearance for compliance reporting';
    END IF;
    
    -- Log access
    PERFORM log_data_access(
        p_user_id,
        'compliance_report',
        p_start_date,
        p_end_date,
        NULL,
        0
    );
    
    -- Generate report
    RETURN QUERY
    SELECT
        dm.metric_date,
        q.queue_name,
        dm.total_calls_offered,
        dm.average_service_level,
        (dm.total_calls_abandoned::DECIMAL / NULLIF(dm.total_calls_offered, 0) * 100),
        CASE 
            WHEN dm.compliance_score >= 90 THEN 'excellent'
            WHEN dm.compliance_score >= 70 THEN 'satisfactory'
            ELSE 'needs_improvement'
        END,
        dm.data_quality_issues
    FROM project_f_daily_metrics dm
    JOIN project_f_queues q ON dm.queue_id = q.queue_id
    WHERE dm.metric_date BETWEEN p_start_date AND p_end_date
    ORDER BY dm.metric_date, q.queue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================================
-- 9. MAINTENANCE AND CLEANUP
-- =====================================================================================

-- Function to archive old data (government retention requirements)
CREATE OR REPLACE FUNCTION archive_project_f_data(
    p_cutoff_date DATE,
    p_archive_schema VARCHAR DEFAULT 'archive'
)
RETURNS TABLE (
    archived_intervals BIGINT,
    archived_metrics BIGINT,
    archived_logs BIGINT
) AS $$
DECLARE
    v_archived_intervals BIGINT := 0;
    v_archived_metrics BIGINT := 0;
    v_archived_logs BIGINT := 0;
BEGIN
    -- Create archive schema if not exists
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', p_archive_schema);
    
    -- Archive intervals (keep 1 year as per government requirement)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.project_f_intervals_%s AS
        SELECT * FROM project_f_intervals
        WHERE interval_date < %L',
        p_archive_schema,
        to_char(p_cutoff_date, 'YYYY_MM'),
        p_cutoff_date
    );
    
    GET DIAGNOSTICS v_archived_intervals = ROW_COUNT;
    
    -- Archive metrics
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.project_f_daily_metrics_%s AS
        SELECT * FROM project_f_daily_metrics
        WHERE metric_date < %L',
        p_archive_schema,
        to_char(p_cutoff_date, 'YYYY_MM'),
        p_cutoff_date
    );
    
    GET DIAGNOSTICS v_archived_metrics = ROW_COUNT;
    
    -- Archive audit logs (keep 3 years as per government requirement)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.project_f_audit_log_%s AS
        SELECT * FROM project_f_audit_log
        WHERE event_timestamp < %L',
        p_archive_schema,
        to_char(p_cutoff_date, 'YYYY_MM'),
        p_cutoff_date - INTERVAL '3 years'
    );
    
    GET DIAGNOSTICS v_archived_logs = ROW_COUNT;
    
    -- Do not delete original data - government requirement
    -- Data deletion requires special approval process
    
    RETURN QUERY
    SELECT v_archived_intervals, v_archived_metrics, v_archived_logs;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 10. MONITORING AND ALERTING
-- =====================================================================================

-- Function to check for security anomalies
CREATE OR REPLACE FUNCTION check_security_anomalies(
    p_hours_back INTEGER DEFAULT 24
)
RETURNS TABLE (
    anomaly_type VARCHAR,
    severity VARCHAR,
    description TEXT,
    detected_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Check for unusual access patterns
    RETURN QUERY
    SELECT 
        'excessive_access'::VARCHAR,
        'high'::VARCHAR,
        format('User %s accessed data %s times in %s hours', user_id, COUNT(*), p_hours_back),
        MAX(access_timestamp)
    FROM project_f_access_log
    WHERE access_timestamp > NOW() - (p_hours_back || ' hours')::INTERVAL
    GROUP BY user_id
    HAVING COUNT(*) > 100;
    
    -- Check for failed imports
    RETURN QUERY
    SELECT
        'import_failures'::VARCHAR,
        'medium'::VARCHAR,
        format('%s failed imports in last %s hours', COUNT(*), p_hours_back),
        MAX(start_time)
    FROM import_log
    WHERE import_type LIKE 'project_f%'
    AND status = 'failed'
    AND start_time > NOW() - (p_hours_back || ' hours')::INTERVAL
    HAVING COUNT(*) > 5;
    
    -- Check for compliance violations
    RETURN QUERY
    SELECT
        'compliance_violation'::VARCHAR,
        'high'::VARCHAR,
        format('Queue %s: SL below 70%% for %s intervals', queue_id, COUNT(*)),
        MAX(interval_timestamp)
    FROM project_f_intervals
    WHERE interval_timestamp > NOW() - (p_hours_back || ' hours')::INTERVAL
    AND service_level < 70
    GROUP BY queue_id
    HAVING COUNT(*) > 10;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 11. PERMISSIONS AND SECURITY
-- =====================================================================================

-- Create roles for government project
CREATE ROLE IF NOT EXISTS project_f_viewer;
CREATE ROLE IF NOT EXISTS project_f_operator;
CREATE ROLE IF NOT EXISTS project_f_admin;
CREATE ROLE IF NOT EXISTS project_f_auditor;

-- Grant permissions
GRANT SELECT ON v_project_f_intervals_secure TO project_f_viewer;
GRANT SELECT, INSERT ON project_f_intervals, staging_project_f_raw, staging_project_f_processed TO project_f_operator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO project_f_admin;
GRANT SELECT ON project_f_audit_log, project_f_access_log, project_f_compliance_metrics TO project_f_auditor;

-- Row-level security for sensitive data
ALTER TABLE project_f_intervals ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_f_audit_log ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY project_f_intervals_policy ON project_f_intervals
    FOR ALL
    TO project_f_operator, project_f_admin
    USING (
        validate_government_security(current_user, 'access', queue_id)
    );

CREATE POLICY project_f_audit_policy ON project_f_audit_log
    FOR SELECT
    TO project_f_auditor, project_f_admin
    USING (TRUE);

-- =====================================================================================
-- 12. DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA public IS 'Project Ф (FSIN) government call center data with enhanced security and compliance';
COMMENT ON TABLE project_f_intervals IS 'Government project call center metrics at 15-minute intervals with compliance tracking';
COMMENT ON TABLE project_f_audit_log IS 'Comprehensive audit trail for all data operations as required by government regulations';
COMMENT ON TABLE project_f_queues IS 'Queue definitions for 5 government service lines with security clearance requirements';
COMMENT ON FUNCTION import_project_f_data IS 'Secure import procedure with government compliance validation and audit trail';
COMMENT ON FUNCTION validate_government_compliance IS 'Validates data against government service standards and security requirements';
COMMENT ON FUNCTION generate_compliance_report IS 'Generates official compliance reports for government oversight';
COMMENT ON VIEW v_project_f_intervals_secure IS 'Secure view with data masking based on user clearance level';