-- =============================================================================
-- 045_1c_zup_integration.sql
-- EXACT BDD Implementation: Complete 1C ZUP Integration - Bidirectional Data Exchange
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 21-1c-zup-integration.feature (715 lines)
-- Purpose: Complete bidirectional integration with 1C Salary and Personnel Management
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. 1C ZUP SYSTEM CONFIGURATION
-- =============================================================================

-- 1C ZUP configuration requirements from BDD lines 16-38
CREATE TABLE zup_system_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_area VARCHAR(100) NOT NULL,
    setting_name VARCHAR(200) NOT NULL,
    
    -- Configuration details from BDD lines 21-30
    setting_value TEXT,
    requirement_description TEXT NOT NULL,
    validation_rule TEXT,
    
    -- API configuration
    http_service_name VARCHAR(200) DEFAULT 'wfm_Energosbyt_ExchangeWFM',
    endpoint_path VARCHAR(500),
    
    -- 1C specific settings from BDD lines 31-38
    setting_path TEXT,
    configuration_purpose TEXT,
    
    -- Status
    is_configured BOOLEAN DEFAULT false,
    last_validated TIMESTAMP WITH TIME ZONE,
    validation_status VARCHAR(20) CHECK (validation_status IN ('valid', 'invalid', 'pending')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Time types configuration from BDD lines 25-26
CREATE TABLE zup_time_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time_type_code VARCHAR(10) NOT NULL UNIQUE,
    time_type_name_ru VARCHAR(100) NOT NULL,
    time_type_name_en VARCHAR(100) NOT NULL,
    
    -- Type categorization from BDD lines 340-360
    category VARCHAR(50) CHECK (category IN (
        'work', 'absence', 'vacation', 'sick_leave', 'overtime', 'special'
    )),
    
    -- Documentation creation
    creates_document BOOLEAN DEFAULT false,
    document_type VARCHAR(100),
    
    -- Priority for conflict resolution from BDD lines 382-397
    priority_level INTEGER DEFAULT 5 CHECK (priority_level BETWEEN 1 AND 10),
    priority_description VARCHAR(50),
    
    -- Integration settings
    sync_to_wfm BOOLEAN DEFAULT true,
    sync_from_wfm BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. PERSONNEL STRUCTURE INTEGRATION
-- =============================================================================

-- Personnel data synchronization from BDD lines 44-67
CREATE TABLE zup_personnel_sync (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- API call parameters from BDD lines 47-50
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    api_endpoint VARCHAR(100) DEFAULT '/agents',
    
    -- Sync status
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'partial'
    )),
    
    -- Results
    services_received INTEGER DEFAULT 0,
    agents_received INTEGER DEFAULT 0,
    agents_processed INTEGER DEFAULT 0,
    errors_count INTEGER DEFAULT 0,
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    sync_log JSONB DEFAULT '[]'
);

-- Employee data structure from BDD lines 68-92
CREATE TABLE zup_employee_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_session_id UUID REFERENCES zup_personnel_sync(id),
    
    -- Required employee fields from BDD lines 73-91
    employee_id VARCHAR(100) NOT NULL, -- 1C ZUP id
    tab_number VARCHAR(50) NOT NULL, -- Personnel number
    lastname VARCHAR(100) NOT NULL,
    firstname VARCHAR(100) NOT NULL,
    secondname VARCHAR(100),
    
    -- Employment details
    start_work DATE NOT NULL,
    finish_work DATE,
    position_id VARCHAR(100) NOT NULL,
    position_title VARCHAR(200) NOT NULL,
    position_change_date DATE,
    department_id VARCHAR(100) NOT NULL,
    
    -- Work parameters
    employment_rate DECIMAL(3,2), -- 0.5, 0.75, 1.0, etc.
    login_sso VARCHAR(100),
    norm_week INTEGER NOT NULL, -- 20, 30, 40, etc.
    norm_week_change_date DATE NOT NULL,
    
    -- Additional fields
    additional_field_1 VARCHAR(200), -- SN
    external_db_id VARCHAR(100), -- Db_ID
    area VARCHAR(100),
    
    -- Filtering rules from BDD lines 114-132
    is_exchange_eligible BOOLEAN DEFAULT true,
    exclusion_reason VARCHAR(200),
    
    -- Integration tracking
    wfm_employee_id UUID, -- Link to local employee record
    last_synced TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'new',
    
    CONSTRAINT unique_employee_per_sync UNIQUE(sync_session_id, employee_id)
);

-- =============================================================================
-- 3. VACATION BALANCE CALCULATION
-- =============================================================================

-- Vacation balance tracking from BDD lines 93-112
CREATE TABLE zup_vacation_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id VARCHAR(100) NOT NULL REFERENCES zup_employee_data(employee_id),
    
    -- Balance calculation from BDD lines 97-103
    accrual_date DATE NOT NULL,
    accumulated_days DECIMAL(5,2) NOT NULL,
    
    -- Calculation details
    monthly_entitlement DECIMAL(4,2),
    basic_days DECIMAL(4,2),
    additional_days DECIMAL(4,2),
    
    -- 1C ZUP calculation rules from BDD lines 107-111
    calculation_rule VARCHAR(50) CHECK (calculation_rule IN (
        'half_month_worked', 'less_than_half_month', 'month_31_day_exception'
    )),
    calculation_notes TEXT,
    
    -- Period tracking
    accrual_period VARCHAR(7), -- YYYY-MM format
    hire_date_adjusted BOOLEAN DEFAULT false,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_accrual UNIQUE(employee_id, accrual_date)
);

-- =============================================================================
-- 4. VACATION SCHEDULE EXPORT
-- =============================================================================

-- Vacation schedule Excel export from BDD lines 133-158
CREATE TABLE zup_vacation_schedule_export (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    export_name VARCHAR(200) NOT NULL,
    export_year INTEGER NOT NULL,
    
    -- Export configuration
    file_format VARCHAR(20) DEFAULT 'excel',
    encoding VARCHAR(20) DEFAULT 'UTF-8 with BOM',
    sheet_name VARCHAR(100), -- "График отпусков YYYY"
    
    -- Export parameters
    department_filter VARCHAR(200)[],
    employee_filter VARCHAR(100)[],
    vacation_types VARCHAR(50)[],
    
    -- Excel structure from BDD lines 138-147
    column_mapping JSONB DEFAULT '{
        "A": {"field": "tab_number", "header_ru": "Табельный номер", "header_en": "Personnel Number"},
        "B": {"field": "full_name", "header_ru": "ФИО", "header_en": "Full Name"},
        "C": {"field": "department", "header_ru": "Подразделение", "header_en": "Department"},
        "D": {"field": "position", "header_ru": "Должность", "header_en": "Position"},
        "E": {"field": "start_date", "header_ru": "Дата начала", "header_en": "Start Date"},
        "F": {"field": "end_date", "header_ru": "Дата окончания", "header_en": "End Date"},
        "G": {"field": "days_count", "header_ru": "Количество дней", "header_en": "Days Count"},
        "H": {"field": "vacation_type", "header_ru": "Тип отпуска", "header_en": "Vacation Type"}
    }'::jsonb,
    
    -- Export status
    export_status VARCHAR(20) DEFAULT 'pending',
    file_path VARCHAR(500),
    file_size_bytes BIGINT,
    records_exported INTEGER,
    
    exported_at TIMESTAMP WITH TIME ZONE,
    exported_by UUID, -- User who requested export
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vacation type mapping from BDD lines 153-157
CREATE TABLE zup_vacation_type_mapping (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wfm_type VARCHAR(100) NOT NULL,
    zup_type VARCHAR(100) NOT NULL,
    excel_value VARCHAR(100) NOT NULL,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. TIME NORMS CALCULATION
-- =============================================================================

-- Time norms calculation from BDD lines 163-231
CREATE TABLE zup_time_norms_calculation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calculation_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- API parameters from BDD lines 166-172
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    calculation_mode VARCHAR(20) NOT NULL CHECK (calculation_mode IN ('month', 'quarter', 'year')),
    
    -- Employee parameters
    employee_id VARCHAR(100) NOT NULL,
    weekly_norm INTEGER NOT NULL, -- 40, 36, 30, etc.
    employment_rate DECIMAL(3,2) NOT NULL, -- 1.0, 0.5, 0.25, etc.
    norm_change_date DATE,
    
    -- Production calendar data from BDD lines 179-183
    working_days INTEGER NOT NULL,
    pre_holiday_hours INTEGER DEFAULT 0,
    
    -- Calculation formula from BDD lines 178-201
    base_calculation DECIMAL(8,2), -- (weeklyNorm / 5) * workingDays
    holiday_reduction DECIMAL(8,2), -- - preHolidayHours
    rate_adjustment DECIMAL(8,2), -- × rate
    calculated_norm_hours DECIMAL(8,2) NOT NULL,
    
    -- Period adjustments from BDD lines 212-231
    hire_date DATE,
    termination_date DATE,
    adjusted_start_date DATE,
    adjusted_end_date DATE,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_calculation UNIQUE(calculation_id, employee_id)
);

-- =============================================================================
-- 6. WORK SCHEDULE INTEGRATION
-- =============================================================================

-- Work schedule upload from BDD lines 236-307
CREATE TABLE zup_work_schedule_upload (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- Upload parameters from BDD lines 239-244
    employee_id VARCHAR(100) NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Upload status
    upload_status VARCHAR(20) DEFAULT 'pending' CHECK (upload_status IN (
        'pending', 'processing', 'completed', 'failed', 'partial'
    )),
    
    -- Schedule data
    shifts_count INTEGER DEFAULT 0,
    documents_created INTEGER DEFAULT 0,
    
    -- Error handling from BDD lines 276-291
    validation_errors JSONB DEFAULT '[]',
    business_rule_violations JSONB DEFAULT '[]',
    
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    
    upload_log JSONB DEFAULT '[]'
);

-- Individual shift data from BDD lines 245-274
CREATE TABLE zup_work_schedule_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_session_id UUID REFERENCES zup_work_schedule_upload(upload_session_id),
    employee_id VARCHAR(100) NOT NULL,
    
    -- Shift details from BDD lines 246-250
    shift_date DATE NOT NULL,
    shift_start TIMESTAMP WITH TIME ZONE NOT NULL,
    shift_end TIMESTAMP WITH TIME ZONE,
    
    -- Time calculations
    daily_hours_ms BIGINT NOT NULL, -- Milliseconds after unpaid break deduction
    night_hours_ms BIGINT DEFAULT 0, -- Milliseconds after unpaid break deduction
    
    -- Time type determination from BDD lines 257-274
    time_type_code VARCHAR(10) NOT NULL,
    time_type_determined_by VARCHAR(50) DEFAULT 'shift_start_time',
    
    -- Transitional shift handling from BDD lines 266-269
    is_transitional_shift BOOLEAN DEFAULT false,
    date_assignment DATE, -- Which date gets the hours
    hours_assignment INTEGER, -- Hours assigned to the date
    
    -- Processing status
    processed BOOLEAN DEFAULT false,
    zup_document_created BOOLEAN DEFAULT false,
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_shift_date UNIQUE(upload_session_id, employee_id, shift_date)
);

-- =============================================================================
-- 7. TIMESHEET INTEGRATION
-- =============================================================================

-- Timesheet data retrieval from BDD lines 312-380
CREATE TABLE zup_timesheet_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- Request parameters from BDD lines 315-319
    date_start DATE NOT NULL,
    date_end DATE NOT NULL,
    employee_id VARCHAR(100) NOT NULL,
    
    -- Timesheet summary from BDD lines 320-328
    half1_days INTEGER DEFAULT 0, -- 1st-15th work days
    half1_hours DECIMAL(6,2) DEFAULT 0, -- 1st-15th work hours
    half2_days INTEGER DEFAULT 0, -- 16th-end work days
    half2_hours DECIMAL(6,2) DEFAULT 0, -- 16th-end work hours
    
    -- Request metadata
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_received_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_employee_timesheet_period UNIQUE(request_id, employee_id, date_start, date_end)
);

-- Daily time type data from BDD lines 329-334
CREATE TABLE zup_timesheet_daily_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timesheet_id UUID REFERENCES zup_timesheet_data(id) ON DELETE CASCADE,
    
    -- Daily data from BDD lines 330-333
    work_date DATE NOT NULL,
    time_type_code VARCHAR(10) NOT NULL,
    hours_worked DECIMAL(6,2) DEFAULT 0,
    
    -- Time type details
    time_type_name_ru VARCHAR(100),
    time_type_category VARCHAR(50),
    
    CONSTRAINT unique_timesheet_date_type UNIQUE(timesheet_id, work_date, time_type_code)
);

-- Absence summary data from BDD lines 362-380
CREATE TABLE zup_timesheet_absence_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timesheet_id UUID REFERENCES zup_timesheet_data(id) ON DELETE CASCADE,
    
    -- Absence data from BDD lines 366-369
    absence_type_code VARCHAR(10) NOT NULL,
    absence_format VARCHAR(20), -- "days_only", "days_hours", "hours_only"
    
    -- Formatted values from BDD lines 370-374
    days_count INTEGER DEFAULT 0,
    hours_count DECIMAL(4,1) DEFAULT 0,
    formatted_value VARCHAR(20), -- e.g., "14", "2(5)", "8"
    
    CONSTRAINT unique_timesheet_absence_type UNIQUE(timesheet_id, absence_type_code)
);

-- =============================================================================
-- 8. ACTUAL WORK TIME INTEGRATION
-- =============================================================================

-- Actual work time upload table
CREATE TABLE zup_actual_work_time (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- Employee and period
    employee_id VARCHAR(100) NOT NULL,
    work_date DATE NOT NULL,
    
    -- Actual time data
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    actual_hours_worked DECIMAL(6,2),
    break_time_minutes INTEGER DEFAULT 0,
    
    -- Deviation tracking
    scheduled_hours DECIMAL(6,2),
    hours_variance DECIMAL(6,2), -- actual - scheduled
    is_overtime BOOLEAN DEFAULT false,
    overtime_hours DECIMAL(6,2) DEFAULT 0,
    
    -- Upload status
    uploaded_to_zup BOOLEAN DEFAULT false,
    upload_timestamp TIMESTAMP WITH TIME ZONE,
    upload_response JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_work_date UNIQUE(upload_session_id, employee_id, work_date)
);

-- =============================================================================
-- 9. INTEGRATION MONITORING AND LOGGING
-- =============================================================================

-- API call logging
CREATE TABLE zup_api_call_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_endpoint VARCHAR(200) NOT NULL,
    http_method VARCHAR(10) NOT NULL,
    
    -- Request details
    request_parameters JSONB,
    request_body JSONB,
    request_headers JSONB,
    
    -- Response details
    response_status INTEGER,
    response_body JSONB,
    response_headers JSONB,
    
    -- Timing
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_timestamp TIMESTAMP WITH TIME ZONE,
    response_time_ms INTEGER,
    
    -- Error tracking
    error_occurred BOOLEAN DEFAULT false,
    error_message TEXT,
    retry_attempt INTEGER DEFAULT 0,
    
    -- Session tracking
    session_id UUID,
    user_id UUID
);

-- Integration health monitoring
CREATE TABLE zup_integration_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    health_check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Service availability
    zup_service_available BOOLEAN,
    api_response_time_ms INTEGER,
    
    -- Data freshness
    last_personnel_sync TIMESTAMP WITH TIME ZONE,
    last_schedule_upload TIMESTAMP WITH TIME ZONE,
    last_timesheet_request TIMESTAMP WITH TIME ZONE,
    
    -- Error rates
    api_error_rate_24h DECIMAL(5,2),
    sync_failure_rate_24h DECIMAL(5,2),
    
    -- Performance metrics
    avg_response_time_24h INTEGER,
    total_api_calls_24h INTEGER,
    
    health_status VARCHAR(20) CHECK (health_status IN ('healthy', 'degraded', 'unhealthy'))
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate time norms using 1C ZUP formula
CREATE OR REPLACE FUNCTION calculate_zup_time_norm(
    p_weekly_norm INTEGER,
    p_employment_rate DECIMAL,
    p_working_days INTEGER,
    p_pre_holiday_hours INTEGER DEFAULT 0
) RETURNS DECIMAL(8,2) AS $$
DECLARE
    v_base_calculation DECIMAL(8,2);
    v_holiday_reduction DECIMAL(8,2);
    v_final_norm DECIMAL(8,2);
BEGIN
    -- Base calculation: (weeklyNorm / 5) * workingDays
    v_base_calculation := (p_weekly_norm::DECIMAL / 5) * p_working_days;
    
    -- Holiday reduction: subtract pre-holiday hours
    v_holiday_reduction := v_base_calculation - p_pre_holiday_hours;
    
    -- Rate adjustment: apply employment rate
    v_final_norm := v_holiday_reduction * p_employment_rate;
    
    RETURN ROUND(v_final_norm, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to determine time type based on shift start time
CREATE OR REPLACE FUNCTION determine_time_type_by_shift_start(
    p_shift_start_time TIME
) RETURNS VARCHAR(10) AS $$
BEGIN
    -- Time type determination rules from BDD lines 262-265
    IF p_shift_start_time >= '22:00:00' OR p_shift_start_time <= '05:59:59' THEN
        RETURN 'H'; -- Night
    ELSIF p_shift_start_time >= '06:00:00' AND p_shift_start_time <= '21:59:59' THEN
        RETURN 'I'; -- Day
    ELSE
        RETURN 'B'; -- Day off (fallback)
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to validate schedule upload eligibility
CREATE OR REPLACE FUNCTION validate_schedule_upload_eligibility(
    p_employee_id VARCHAR,
    p_period_start DATE,
    p_period_end DATE
) RETURNS TABLE (
    is_eligible BOOLEAN,
    error_message TEXT,
    validation_details JSONB
) AS $$
DECLARE
    v_employee RECORD;
    v_errors TEXT[] := '{}';
    v_details JSONB := '{}';
BEGIN
    -- Get employee data
    SELECT * INTO v_employee 
    FROM zup_employee_data 
    WHERE employee_id = p_employee_id
    ORDER BY last_synced DESC 
    LIMIT 1;
    
    -- Check if employee exists
    IF v_employee.employee_id IS NULL THEN
        v_errors := array_append(v_errors, 'Employee not found in 1C ZUP');
    END IF;
    
    -- Check employment period from BDD lines 293-306
    IF v_employee.start_work > p_period_start THEN
        v_errors := array_append(v_errors, 'Schedule period starts before hire date');
    END IF;
    
    IF v_employee.finish_work IS NOT NULL AND v_employee.finish_work < p_period_end THEN
        v_errors := array_append(v_errors, 'Schedule period extends beyond termination date');
    END IF;
    
    -- Check for past period modification from BDD lines 280-285
    IF p_period_start < DATE_TRUNC('month', CURRENT_DATE) THEN
        v_errors := array_append(v_errors, 'It is forbidden to modify schedules for past periods');
    END IF;
    
    -- Build validation details
    v_details := jsonb_build_object(
        'employee_hire_date', v_employee.start_work,
        'employee_termination_date', v_employee.finish_work,
        'period_start', p_period_start,
        'period_end', p_period_end,
        'errors', v_errors
    );
    
    RETURN QUERY
    SELECT 
        array_length(v_errors, 1) IS NULL AS is_eligible,
        array_to_string(v_errors, '; ') AS error_message,
        v_details AS validation_details;
END;
$$ LANGUAGE plpgsql;

-- Function to format absence data for timesheet
CREATE OR REPLACE FUNCTION format_absence_data(
    p_days INTEGER,
    p_hours DECIMAL
) RETURNS TEXT AS $$
BEGIN
    -- Formatting rules from BDD lines 370-374
    IF p_hours = 0 AND p_days > 0 THEN
        RETURN p_days::TEXT; -- Days only: "14"
    ELSIF p_days > 0 AND p_hours > 0 THEN
        RETURN p_days::TEXT || '(' || p_hours::TEXT || ')'; -- Days(Hours): "2(5)"
    ELSIF p_days = 0 AND p_hours > 0 THEN
        RETURN p_hours::TEXT; -- Hours only: "8"
    ELSE
        RETURN '0';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_zup_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_zup_system_config_timestamp
    BEFORE UPDATE ON zup_system_configuration
    FOR EACH ROW
    EXECUTE FUNCTION update_zup_timestamps();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Configuration indexes
CREATE INDEX idx_zup_config_area ON zup_system_configuration(configuration_area);
CREATE INDEX idx_zup_config_status ON zup_system_configuration(validation_status);

-- Personnel sync indexes
CREATE INDEX idx_zup_personnel_sync_session ON zup_employee_data(sync_session_id);
CREATE INDEX idx_zup_personnel_employee_id ON zup_employee_data(employee_id);
CREATE INDEX idx_zup_personnel_tab_number ON zup_employee_data(tab_number);
CREATE INDEX idx_zup_personnel_eligible ON zup_employee_data(is_exchange_eligible);

-- Vacation balance indexes
CREATE INDEX idx_zup_vacation_employee ON zup_vacation_balances(employee_id);
CREATE INDEX idx_zup_vacation_date ON zup_vacation_balances(accrual_date);

-- Schedule upload indexes
CREATE INDEX idx_zup_schedule_upload_session ON zup_work_schedule_shifts(upload_session_id);
CREATE INDEX idx_zup_schedule_employee_date ON zup_work_schedule_shifts(employee_id, shift_date);
CREATE INDEX idx_zup_schedule_time_type ON zup_work_schedule_shifts(time_type_code);

-- Timesheet indexes
CREATE INDEX idx_zup_timesheet_employee_period ON zup_timesheet_data(employee_id, date_start, date_end);
CREATE INDEX idx_zup_timesheet_daily_date ON zup_timesheet_daily_data(work_date);

-- API logging indexes
CREATE INDEX idx_zup_api_log_timestamp ON zup_api_call_log(request_timestamp DESC);
CREATE INDEX idx_zup_api_log_endpoint ON zup_api_call_log(api_endpoint);
CREATE INDEX idx_zup_api_log_status ON zup_api_call_log(response_status);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert 1C ZUP configuration requirements
INSERT INTO zup_system_configuration (configuration_area, setting_name, setting_value, requirement_description, setting_path, configuration_purpose) VALUES
('HTTP Services', 'Publication', 'Web server enabled', 'Web server must be enabled for API access', 'Administration > HTTP Services', 'API access'),
('Exchange Plans', 'WFM Exchange', 'Created and active', 'Exchange node must exist for data synchronization', NULL, 'Data synchronization'),
('Users', 'WFMSystem', 'Full access rights', 'Integration user must have full permissions', NULL, 'API authentication'),
('Time Types', 'Work types', 'I, H, B configured', 'Basic work time types must be configured', NULL, 'Time tracking'),
('Time Types', 'Deviations', 'RV, RVN, NV, C active', 'Deviation time types must be active', NULL, 'Document creation'),
('Salary Settings', 'Time tracking', 'Summarized time tracking', 'Monthly period time tracking', 'Salary > Settings > Time tracking', 'Monthly periods'),
('Personnel Settings', 'Schedules', 'Individual schedules allowed', 'Per-employee schedule configuration', 'Personnel > Settings > Schedules', 'Per-employee scheduling'),
('Salary Calculation', 'Night work premium', '20%', 'Compliance with labor law', 'Salary > Calculation > Types', 'Legal compliance'),
('Personnel Calculation', 'Overtime', 'Auto-calculation enabled', 'Automatic overtime calculation', 'Personnel > Calculation > Overtime', 'Deviation tracking');

-- Insert time type codes from BDD lines 340-360
INSERT INTO zup_time_types (time_type_code, time_type_name_ru, time_type_name_en, category, priority_level, priority_description) VALUES
('I', 'Я', 'Day work', 'work', 4, 'Low'),
('H', 'Н', 'Night work', 'work', 4, 'Low'),
('B', 'В', 'Day off', 'work', 4, 'Low'),
('PR', 'ПР', 'Truancy', 'absence', 1, 'Lowest'),
('RP', 'РП', 'Downtime - employer fault', 'absence', 6, 'Medium'),
('PC', 'ПК', 'Professional development', 'absence', 6, 'Medium'),
('OT', 'ОТ', 'Annual vacation', 'vacation', 8, 'High'),
('OD', 'ОД', 'Additional vacation', 'vacation', 8, 'High'),
('U', 'У', 'Paid study leave', 'vacation', 7, 'Medium'),
('UD', 'УД', 'Unpaid study leave', 'vacation', 7, 'Medium'),
('P', 'Р', 'Maternity leave', 'sick_leave', 10, 'Highest'),
('OW', 'ОВ', 'Parental leave', 'special', 9, 'High'),
('DO', 'ДО', 'Unpaid leave - employer', 'absence', 3, 'Low'),
('B', 'Б', 'Sick leave', 'sick_leave', 10, 'Highest'),
('T', 'Т', 'Unpaid sick leave', 'absence', 2, 'Low'),
('G', 'Г', 'Public duties', 'absence', 7, 'Medium'),
('C', 'С', 'Overtime', 'overtime', 5, 'Medium'),
('RV', 'РВ', 'Weekend work', 'overtime', 5, 'Medium'),
('RVN', 'РВН', 'Night weekend work', 'overtime', 5, 'Medium'),
('NV', 'НВ', 'Absence', 'absence', 2, 'Low');

-- Insert vacation type mappings
INSERT INTO zup_vacation_type_mapping (wfm_type, zup_type, excel_value) VALUES
('Regular vacation', 'ОсновнойОтпуск', 'Основной'),
('Additional vacation', 'ДополнительныйОтпуск', 'Дополнительный'),
('Unpaid leave', 'ОтпускБезСохранения', 'Без сохранения');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_integration_service;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operator;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_integration_service;