-- =============================================================================
-- 018_argus_time_classification.sql
-- EXACT ARGUS TIME TYPE CLASSIFICATION SYSTEM
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Replicate EXACT Argus time type system with 1C ZUP integration
-- Based on: BDD specifications - exact time codes I/H/B/C/RV/RVN/NV/OT/etc.
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ARGUS_TIME_TYPES - Exact time type codes from BDD specs
-- =============================================================================
CREATE TABLE argus_time_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_code VARCHAR(10) NOT NULL UNIQUE, -- I, H, B, C, RV, RVN, NV, etc.
    type_code_ru VARCHAR(10) NOT NULL UNIQUE, -- Я, Н, В, С, РВ, РВН, НВ, etc.
    type_name_en VARCHAR(100) NOT NULL,
    type_name_ru VARCHAR(100) NOT NULL,
    description_en TEXT,
    description_ru TEXT,
    
    -- Classification according to Argus BDD specs
    is_work_time BOOLEAN DEFAULT true,
    is_night_work BOOLEAN DEFAULT false,
    is_weekend_work BOOLEAN DEFAULT false,
    is_overtime BOOLEAN DEFAULT false,
    is_absence BOOLEAN DEFAULT false,
    is_vacation BOOLEAN DEFAULT false,
    
    -- Time range specifications from BDD
    time_range_start TIME, -- e.g., 22:00 for night work
    time_range_end TIME,   -- e.g., 05:59 for night work
    
    -- 1C ZUP integration fields
    zup_document_type VARCHAR(100), -- Document type created in 1C ZUP
    auto_create_document BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT false,
    
    -- Calculation parameters
    rate_multiplier DECIMAL(5,2) DEFAULT 1.0, -- Overtime multiplier
    counts_toward_norm BOOLEAN DEFAULT true,
    excludes_from_schedule BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Insert EXACT Argus time types from BDD specifications
INSERT INTO argus_time_types (
    type_code, type_code_ru, type_name_en, type_name_ru, description_en, description_ru,
    is_work_time, is_night_work, is_weekend_work, is_overtime, is_absence, is_vacation,
    time_range_start, time_range_end, zup_document_type, auto_create_document, rate_multiplier
) VALUES
-- Core work time types
('I', 'Я', 'Day work', 'Дневная работа', 'Day work (06:00-21:59)', 'Дневная работа (06:00-21:59)', 
 true, false, false, false, false, false, '06:00', '21:59', 'Individual Schedule', true, 1.0),

('H', 'Н', 'Night work', 'Ночная работа', 'Night work (22:00-05:59)', 'Ночная работа (22:00-05:59)', 
 true, true, false, false, false, false, '22:00', '05:59', 'Individual Schedule', true, 1.2),

('B', 'В', 'Day off', 'Выходной день', 'Day off (no shift scheduled)', 'Выходной день (смена не назначена)', 
 false, false, false, false, false, false, NULL, NULL, NULL, false, 0.0),

-- Overtime and weekend work
('C', 'С', 'Overtime work', 'Сверхурочная работа', 'Overtime hours above norm', 'Сверхурочные часы сверх нормы', 
 true, false, false, true, false, false, NULL, NULL, 'Overtime Document', true, 1.5),

('RV', 'РВ', 'Weekend work', 'Работа в выходной', 'Weekend day work (unplanned)', 'Работа в выходной день (внеплановая)', 
 true, false, true, false, false, false, '06:00', '21:59', 'Work on Weekend Document', true, 2.0),

('RVN', 'РВН', 'Night weekend work', 'Ночная работа в выходной', 'Night weekend work (unplanned)', 'Ночная работа в выходной (внеплановая)', 
 true, true, true, false, false, false, '22:00', '05:59', 'Work on Weekend Document', true, 2.4),

-- Absence types
('NV', 'НВ', 'Absence', 'Неявка', 'Unexplained absence', 'Необъяснимая неявка', 
 false, false, false, false, true, false, NULL, NULL, 'Absence Document', true, 0.0),

('PR', 'ПР', 'Truancy', 'Прогул', 'Truancy/Absenteeism', 'Прогул/Абсентеизм', 
 false, false, false, false, true, false, NULL, NULL, 'Absence Document', true, 0.0),

-- Vacation types
('OT', 'ОТ', 'Annual vacation', 'Ежегодный отпуск', 'Annual vacation', 'Ежегодный оплачиваемый отпуск', 
 false, false, false, false, false, true, NULL, NULL, 'Vacation Document', true, 1.0),

('OD', 'ОД', 'Additional vacation', 'Дополнительный отпуск', 'Additional vacation', 'Дополнительный отпуск', 
 false, false, false, false, false, true, NULL, NULL, 'Vacation Document', true, 1.0),

-- Special types
('PC', 'ПК', 'Professional development', 'Повышение квалификации', 'Professional development/Training', 'Повышение квалификации/Обучение', 
 true, false, false, false, false, false, NULL, NULL, 'Training Document', true, 1.0),

('G', 'Г', 'Public duties', 'Государственные обязанности', 'Public duties/Civic obligations', 'Государственные/Общественные обязанности', 
 true, false, false, false, false, false, NULL, NULL, 'Public Duty Document', true, 1.0);

-- Indexes for argus_time_types
CREATE INDEX idx_argus_time_types_code ON argus_time_types(type_code);
CREATE INDEX idx_argus_time_types_code_ru ON argus_time_types(type_code_ru);
CREATE INDEX idx_argus_time_types_work ON argus_time_types(is_work_time);

-- =============================================================================
-- 2. ARGUS_TIME_ENTRIES - Time entries with EXACT Argus classification
-- =============================================================================
CREATE TABLE argus_time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    entry_date DATE NOT NULL,
    argus_time_type_id UUID NOT NULL,
    
    -- Exact time recording as per Argus BDD specs
    planned_start_time TIME,
    planned_end_time TIME,
    actual_start_time TIME,
    actual_end_time TIME,
    break_duration_minutes INTEGER DEFAULT 0,
    
    -- Calculated fields following Argus logic
    planned_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    norm_hours DECIMAL(10,2), -- From production calendar
    deviation_hours DECIMAL(10,2), -- actual - planned
    overtime_hours DECIMAL(10,2) DEFAULT 0,
    
    -- 1C ZUP integration fields
    personnel_number VARCHAR(50), -- tabN from personnel API
    zup_document_id VARCHAR(100), -- Created document ID in 1C ZUP
    zup_sync_status VARCHAR(20) DEFAULT 'pending', -- pending, synced, failed
    zup_sync_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Approval workflow (multi-stage as per BDD)
    approval_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    approved_by UUID,
    approval_timestamp TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Request origin (if from employee request)
    request_id UUID, -- Links to employee requests
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    
    CONSTRAINT fk_argus_time_entries_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id),
    CONSTRAINT fk_argus_time_entries_type 
        FOREIGN KEY (argus_time_type_id) REFERENCES argus_time_types(id),
    CONSTRAINT fk_argus_time_entries_approved_by 
        FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_argus_time_entries_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE(employee_id, entry_date, argus_time_type_id)
);

-- Indexes for argus_time_entries
CREATE INDEX idx_argus_time_entries_employee ON argus_time_entries(employee_id);
CREATE INDEX idx_argus_time_entries_date ON argus_time_entries(entry_date);
CREATE INDEX idx_argus_time_entries_type ON argus_time_entries(argus_time_type_id);
CREATE INDEX idx_argus_time_entries_sync_status ON argus_time_entries(zup_sync_status);

-- =============================================================================
-- 3. ARGUS_TIME_DEVIATIONS - Deviation tracking for 1C ZUP integration
-- =============================================================================
CREATE TABLE argus_time_deviations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    deviation_date DATE NOT NULL,
    personnel_number VARCHAR(50) NOT NULL, -- tabN
    
    -- Deviation details as per BDD specs
    planned_type_code VARCHAR(10), -- Original planned type (I/H/B)
    actual_type_code VARCHAR(10), -- Actual worked type (C/RV/RVN/NV)
    deviation_reason VARCHAR(200),
    
    -- Time calculations
    planned_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    deviation_hours DECIMAL(10,2),
    rate_multiplier DECIMAL(5,2),
    compensation_amount DECIMAL(12,2),
    
    -- 1C ZUP document creation
    requires_zup_document BOOLEAN DEFAULT true,
    zup_document_type VARCHAR(100),
    zup_document_created BOOLEAN DEFAULT false,
    zup_document_id VARCHAR(100),
    
    -- Automatic detection flags
    auto_detected BOOLEAN DEFAULT true,
    detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_argus_time_deviations_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id)
);

-- Index for argus_time_deviations
CREATE INDEX idx_argus_time_deviations_employee ON argus_time_deviations(employee_id);
CREATE INDEX idx_argus_time_deviations_date ON argus_time_deviations(deviation_date);
CREATE INDEX idx_argus_time_deviations_processed ON argus_time_deviations(processed);

-- =============================================================================
-- FUNCTIONS: Argus Time Classification Logic
-- =============================================================================

-- Function to determine time type based on work hours (exact Argus logic)
CREATE OR REPLACE FUNCTION determine_argus_time_type(
    p_start_time TIME,
    p_end_time TIME,
    p_work_date DATE,
    p_is_scheduled BOOLEAN DEFAULT true
) RETURNS VARCHAR(10) AS $$
DECLARE
    v_time_type VARCHAR(10);
    v_is_weekend BOOLEAN;
    v_is_holiday BOOLEAN;
BEGIN
    -- Check if date is weekend or holiday
    SELECT 
        EXTRACT(DOW FROM p_work_date) IN (0, 6),
        EXISTS(SELECT 1 FROM holidays WHERE holiday_date = p_work_date)
    INTO v_is_weekend, v_is_holiday;
    
    -- Determine time type following Argus BDD specs
    IF NOT p_is_scheduled THEN
        -- Unscheduled work
        IF v_is_weekend OR v_is_holiday THEN
            -- Weekend/holiday work
            IF p_start_time >= '22:00' OR p_end_time <= '05:59' THEN
                v_time_type := 'RVN'; -- Night weekend work
            ELSE
                v_time_type := 'RV'; -- Day weekend work
            END IF;
        ELSE
            v_time_type := 'C'; -- Overtime on regular day
        END IF;
    ELSE
        -- Scheduled work
        IF p_start_time IS NULL AND p_end_time IS NULL THEN
            v_time_type := 'B'; -- Day off
        ELSIF p_start_time >= '22:00' OR p_end_time <= '05:59' THEN
            v_time_type := 'H'; -- Night work
        ELSE
            v_time_type := 'I'; -- Day work
        END IF;
    END IF;
    
    RETURN v_time_type;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate norm hours with production calendar (exact Argus formula)
CREATE OR REPLACE FUNCTION calculate_norm_hours(
    p_employee_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_norm_week INTEGER;
    v_employment_rate DECIMAL(3,2);
    v_working_days INTEGER;
    v_pre_holiday_hours INTEGER;
    v_norm_hours DECIMAL(10,2);
BEGIN
    -- Get employee norm parameters
    SELECT 
        COALESCE(norm_week, 40),
        COALESCE(employment_rate, 1.0)
    INTO v_norm_week, v_employment_rate
    FROM users 
    WHERE id = p_employee_id;
    
    -- Count working days and pre-holiday hours from production calendar
    SELECT 
        COUNT(*) FILTER (WHERE day_type = 'working'),
        COALESCE(SUM(CASE WHEN day_type = 'pre_holiday' THEN 1 ELSE 0 END), 0)
    INTO v_working_days, v_pre_holiday_hours
    FROM production_calendar
    WHERE calendar_date BETWEEN p_start_date AND p_end_date;
    
    -- Apply exact Argus formula from BDD specs:
    -- Formula: (normWeek / 5) * workingDays - preHolidayHours * employeeRate
    v_norm_hours := (v_norm_week::DECIMAL / 5.0) * v_working_days - v_pre_holiday_hours;
    v_norm_hours := v_norm_hours * v_employment_rate;
    
    RETURN ROUND(v_norm_hours, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to detect and create deviations for 1C ZUP
CREATE OR REPLACE FUNCTION detect_time_deviations(
    p_employee_id UUID,
    p_date_from DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_date_to DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
    v_entry argus_time_entries%ROWTYPE;
    v_deviations_created INTEGER := 0;
    v_time_type argus_time_types%ROWTYPE;
BEGIN
    -- Process all time entries in the period
    FOR v_entry IN 
        SELECT * FROM argus_time_entries 
        WHERE employee_id = p_employee_id
        AND entry_date BETWEEN p_date_from AND p_date_to
        AND zup_sync_status = 'pending'
    LOOP
        -- Get time type details
        SELECT * INTO v_time_type 
        FROM argus_time_types 
        WHERE id = v_entry.argus_time_type_id;
        
        -- Check for deviations requiring 1C ZUP documents
        IF v_entry.deviation_hours != 0 OR v_time_type.auto_create_document THEN
            INSERT INTO argus_time_deviations (
                employee_id,
                deviation_date,
                personnel_number,
                actual_type_code,
                deviation_hours,
                rate_multiplier,
                zup_document_type,
                requires_zup_document
            ) VALUES (
                v_entry.employee_id,
                v_entry.entry_date,
                v_entry.personnel_number,
                v_time_type.type_code,
                v_entry.deviation_hours,
                v_time_type.rate_multiplier,
                v_time_type.zup_document_type,
                v_time_type.auto_create_document
            ) ON CONFLICT DO NOTHING;
            
            v_deviations_created := v_deviations_created + 1;
        END IF;
    END LOOP;
    
    RETURN v_deviations_created;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Argus Time Classification Integration
-- =============================================================================

-- View for 1C ZUP time type information (exact API format from BDD)
CREATE VIEW v_argus_zup_timetypes AS
SELECT 
    att.type_code,
    att.type_code_ru,
    att.type_name_ru as name,
    att.description_ru as description,
    att.is_work_time,
    att.is_night_work,
    att.is_overtime,
    att.rate_multiplier,
    att.time_range_start,
    att.time_range_end,
    att.zup_document_type,
    att.auto_create_document
FROM argus_time_types att
WHERE att.is_active = true
ORDER BY att.type_code;

-- View for timesheet report (Табель учета рабочего времени)
CREATE VIEW v_argus_timesheet_report AS
SELECT 
    u.personnel_number as "tabN",
    u.last_name || ' ' || u.first_name || COALESCE(' ' || u.middle_name, '') as "ФИО",
    ate.entry_date as "Дата",
    att.type_code_ru as "Код времени",
    att.type_name_ru as "Тип времени",
    ate.actual_hours as "Часы",
    ate.norm_hours as "Норма часов",
    ate.deviation_hours as "Отклонение",
    CASE 
        WHEN ate.approval_status = 'approved' THEN 'Утверждено'
        WHEN ate.approval_status = 'pending' THEN 'На рассмотрении'
        ELSE 'Отклонено'
    END as "Статус",
    ate.zup_sync_status as "Статус 1C"
FROM argus_time_entries ate
JOIN users u ON u.id = ate.employee_id
JOIN argus_time_types att ON att.id = ate.argus_time_type_id
WHERE ate.entry_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY u.personnel_number, ate.entry_date, att.type_code;

-- Demo view showing Argus time classification accuracy
CREATE VIEW v_demo_argus_time_classification AS
SELECT 
    'Argus Time Classification System' as metric_name,
    'Exact Argus Replication' as category,
    COUNT(DISTINCT att.type_code) as total_time_types,
    COUNT(DISTINCT ate.employee_id) as employees_tracked,
    COUNT(*) FILTER (WHERE ate.zup_sync_status = 'synced') as synced_entries,
    COUNT(*) FILTER (WHERE ate.approval_status = 'approved') as approved_entries,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ate.zup_sync_status = 'synced') / COUNT(*), 1) as sync_success_rate,
    'Exact Argus time codes: I/H/B/C/RV/RVN/NV/OT/OD/PR/PC/G' as time_codes_supported,
    NOW() as measurement_time
FROM argus_time_entries ate
JOIN argus_time_types att ON att.id = ate.argus_time_type_id
WHERE ate.entry_date >= CURRENT_DATE - INTERVAL '30 days';

COMMENT ON TABLE argus_time_types IS 'Exact Argus time type classification system from BDD specs';
COMMENT ON TABLE argus_time_entries IS 'Time entries using exact Argus time type codes';
COMMENT ON TABLE argus_time_deviations IS 'Time deviations for 1C ZUP document creation';
COMMENT ON VIEW v_argus_timesheet_report IS 'Russian timesheet report (Табель учета рабочего времени)';