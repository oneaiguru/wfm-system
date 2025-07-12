-- =============================================================================
-- 026_exact_tabel_t13.sql
-- EXACT ТАБЕЛЬ УЧЕТА РАБОЧЕГО ВРЕМЕНИ (Т-13) FORMAT
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT Russian Т-13 timesheet format as specified in BDD
-- Based on: 1C ZUP integration requirements and Russian labor law compliance
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. TABEL_T13_HEADERS - Timesheet document headers (exact Т-13 format)
-- =============================================================================
CREATE TABLE tabel_t13_headers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Document identification (exact Т-13 requirements)
    document_number VARCHAR(50) NOT NULL UNIQUE,
    document_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    
    -- Organization details (exact Russian format)
    organization_name VARCHAR(500) NOT NULL DEFAULT 'ООО "Компания"',
    organization_okpo VARCHAR(20), -- ОКПО код
    organization_okved VARCHAR(20), -- ОКВЭД код
    structural_unit VARCHAR(200) DEFAULT 'Контакт-центр', -- Структурное подразделение
    
    -- Document status
    document_status VARCHAR(20) DEFAULT 'DRAFT' CHECK (
        document_status IN ('DRAFT', 'APPROVED', 'SUBMITTED', 'ARCHIVED')
    ),
    
    -- Approval workflow (Russian official process)
    prepared_by VARCHAR(200), -- Составил
    prepared_position VARCHAR(200), -- Должность составителя
    prepared_date DATE,
    
    checked_by VARCHAR(200), -- Проверил
    checked_position VARCHAR(200), -- Должность проверяющего
    checked_date DATE,
    
    approved_by VARCHAR(200), -- Утвердил
    approved_position VARCHAR(200), -- Должность утверждающего
    approved_date DATE,
    
    -- Totals for document
    total_employees INTEGER DEFAULT 0,
    total_working_days INTEGER DEFAULT 0,
    total_working_hours DECIMAL(12,2) DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for tabel_t13_headers
CREATE INDEX idx_tabel_t13_headers_period ON tabel_t13_headers(reporting_period_start, reporting_period_end);
CREATE INDEX idx_tabel_t13_headers_status ON tabel_t13_headers(document_status);

-- =============================================================================
-- 2. TABEL_T13_EMPLOYEES - Employee list for timesheet (exact Т-13 structure)
-- =============================================================================
CREATE TABLE tabel_t13_employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tabel_header_id UUID NOT NULL,
    
    -- Employee identification (exact Т-13 columns)
    row_number INTEGER NOT NULL, -- Порядковый номер
    personnel_number VARCHAR(50) NOT NULL, -- Табельный номер
    employee_full_name VARCHAR(500) NOT NULL, -- Фамилия, имя, отчество
    position_name VARCHAR(300) NOT NULL, -- Должность (специальность, профессия)
    tariff_rate VARCHAR(20), -- Тарифная ставка, оклад
    
    -- Monthly totals (exact Т-13 calculations)
    days_worked DECIMAL(5,2) DEFAULT 0, -- Отработано дней
    hours_worked DECIMAL(8,2) DEFAULT 0, -- Отработано часов
    
    -- Time type breakdowns (exact 1C ZUP codes)
    days_i DECIMAL(5,2) DEFAULT 0, -- Я - дневная работа
    hours_i DECIMAL(8,2) DEFAULT 0,
    days_h DECIMAL(5,2) DEFAULT 0, -- Н - ночная работа  
    hours_h DECIMAL(8,2) DEFAULT 0,
    days_c DECIMAL(5,2) DEFAULT 0, -- С - сверхурочная работа
    hours_c DECIMAL(8,2) DEFAULT 0,
    days_rv DECIMAL(5,2) DEFAULT 0, -- РВ - работа в выходной
    hours_rv DECIMAL(8,2) DEFAULT 0,
    days_rvn DECIMAL(5,2) DEFAULT 0, -- РВН - ночная работа в выходной
    hours_rvn DECIMAL(8,2) DEFAULT 0,
    days_ot DECIMAL(5,2) DEFAULT 0, -- ОТ - отпуск
    days_b DECIMAL(5,2) DEFAULT 0, -- Б - больничный
    days_nv DECIMAL(5,2) DEFAULT 0, -- НВ - неявка
    
    -- Additional codes
    days_additional_vacation DECIMAL(5,2) DEFAULT 0, -- ОД - дополнительный отпуск
    days_training DECIMAL(5,2) DEFAULT 0, -- ПК - повышение квалификации
    days_public_duty DECIMAL(5,2) DEFAULT 0, -- Г - исполнение государственных обязанностей
    
    CONSTRAINT fk_tabel_t13_employees_header 
        FOREIGN KEY (tabel_header_id) REFERENCES tabel_t13_headers(id) ON DELETE CASCADE,
    CONSTRAINT fk_tabel_t13_employees_personnel 
        FOREIGN KEY (personnel_number) REFERENCES zup_agent_data(tab_n),
    
    UNIQUE(tabel_header_id, personnel_number)
);

-- Index for tabel_t13_employees
CREATE INDEX idx_tabel_t13_employees_header ON tabel_t13_employees(tabel_header_id);
CREATE INDEX idx_tabel_t13_employees_personnel ON tabel_t13_employees(personnel_number);

-- =============================================================================
-- 3. TABEL_T13_DAILY_DATA - Daily time tracking data (exact Т-13 daily grid)
-- =============================================================================
CREATE TABLE tabel_t13_daily_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tabel_employee_id UUID NOT NULL,
    
    -- Date and time codes (exact Т-13 daily structure)
    work_date DATE NOT NULL,
    day_of_month INTEGER NOT NULL, -- 1-31
    
    -- Time codes (exact 1C ZUP codes from BDD)
    time_code_1 VARCHAR(10), -- First time code for the day
    hours_1 DECIMAL(5,2), -- Hours for first code
    time_code_2 VARCHAR(10), -- Second time code (for split days)
    hours_2 DECIMAL(5,2), -- Hours for second code
    
    -- Detailed time tracking
    start_time TIME,
    end_time TIME,
    break_time_minutes INTEGER DEFAULT 0,
    actual_hours DECIMAL(5,2),
    
    -- Special markings
    is_holiday BOOLEAN DEFAULT false,
    is_weekend BOOLEAN DEFAULT false,
    is_pre_holiday BOOLEAN DEFAULT false,
    
    -- Comments and notes
    daily_notes VARCHAR(200),
    
    CONSTRAINT fk_tabel_t13_daily_employee 
        FOREIGN KEY (tabel_employee_id) REFERENCES tabel_t13_employees(id) ON DELETE CASCADE,
    
    UNIQUE(tabel_employee_id, work_date)
);

-- Index for tabel_t13_daily_data
CREATE INDEX idx_tabel_t13_daily_employee_date ON tabel_t13_daily_data(tabel_employee_id, work_date);
CREATE INDEX idx_tabel_t13_daily_date ON tabel_t13_daily_data(work_date);

-- =============================================================================
-- FUNCTIONS: Т-13 Timesheet Generation
-- =============================================================================

-- Function to generate Т-13 timesheet for period
CREATE OR REPLACE FUNCTION generate_tabel_t13(
    p_period_start DATE,
    p_period_end DATE,
    p_organization_name VARCHAR(500) DEFAULT 'ООО "Компания"',
    p_structural_unit VARCHAR(200) DEFAULT 'Контакт-центр'
) RETURNS UUID AS $$
DECLARE
    v_header_id UUID;
    v_document_number VARCHAR(50);
    v_employee zup_agent_data%ROWTYPE;
    v_employee_id UUID;
    v_row_number INTEGER := 0;
    v_current_date DATE;
    v_time_entry argus_time_entries%ROWTYPE;
    v_time_type argus_time_types%ROWTYPE;
    v_total_employees INTEGER := 0;
    v_total_hours DECIMAL(12,2) := 0;
BEGIN
    -- Generate document number
    v_document_number := 'Т-13-' || TO_CHAR(p_period_start, 'YYYY-MM') || '-' || 
                         EXTRACT(DAY FROM CURRENT_TIMESTAMP)::TEXT;
    
    -- Create timesheet header
    INSERT INTO tabel_t13_headers (
        document_number,
        reporting_period_start,
        reporting_period_end,
        organization_name,
        structural_unit,
        prepared_by,
        prepared_position,
        prepared_date
    ) VALUES (
        v_document_number,
        p_period_start,
        p_period_end,
        p_organization_name,
        p_structural_unit,
        'Система WFM',
        'Автоматизированная система',
        CURRENT_DATE
    ) RETURNING id INTO v_header_id;
    
    -- Process each active employee
    FOR v_employee IN 
        SELECT * FROM zup_agent_data 
        WHERE finish_work IS NULL OR finish_work > p_period_end
        ORDER BY lastname, firstname
    LOOP
        v_row_number := v_row_number + 1;
        v_total_employees := v_total_employees + 1;
        
        -- Create employee record in timesheet
        INSERT INTO tabel_t13_employees (
            tabel_header_id,
            row_number,
            personnel_number,
            employee_full_name,
            position_name,
            tariff_rate
        ) VALUES (
            v_header_id,
            v_row_number,
            v_employee.tab_n,
            v_employee.lastname || ' ' || v_employee.firstname || 
            COALESCE(' ' || v_employee.secondname, ''),
            v_employee.position_name,
            'По тарифу'
        ) RETURNING id INTO v_employee_id;
        
        -- Process daily data for this employee
        v_current_date := p_period_start;
        WHILE v_current_date <= p_period_end LOOP
            -- Get time entry for this date
            SELECT * INTO v_time_entry
            FROM argus_time_entries
            WHERE personnel_number = v_employee.tab_n
            AND entry_date = v_current_date
            ORDER BY created_at DESC
            LIMIT 1;
            
            IF FOUND THEN
                -- Get time type details
                SELECT * INTO v_time_type
                FROM argus_time_types
                WHERE id = v_time_entry.argus_time_type_id;
                
                -- Insert daily data
                INSERT INTO tabel_t13_daily_data (
                    tabel_employee_id,
                    work_date,
                    day_of_month,
                    time_code_1,
                    hours_1,
                    start_time,
                    end_time,
                    actual_hours,
                    is_holiday,
                    is_weekend
                ) VALUES (
                    v_employee_id,
                    v_current_date,
                    EXTRACT(DAY FROM v_current_date),
                    v_time_type.type_code_ru,
                    v_time_entry.actual_hours,
                    v_time_entry.actual_start_time,
                    v_time_entry.actual_end_time,
                    v_time_entry.actual_hours,
                    EXISTS(SELECT 1 FROM holidays WHERE holiday_date = v_current_date),
                    EXTRACT(DOW FROM v_current_date) IN (0, 6)
                );
                
                v_total_hours := v_total_hours + COALESCE(v_time_entry.actual_hours, 0);
            ELSE
                -- No time entry - insert default (day off or weekend)
                INSERT INTO tabel_t13_daily_data (
                    tabel_employee_id,
                    work_date,
                    day_of_month,
                    time_code_1,
                    hours_1,
                    actual_hours,
                    is_holiday,
                    is_weekend
                ) VALUES (
                    v_employee_id,
                    v_current_date,
                    EXTRACT(DAY FROM v_current_date),
                    CASE 
                        WHEN EXISTS(SELECT 1 FROM holidays WHERE holiday_date = v_current_date) THEN 'В'
                        WHEN EXTRACT(DOW FROM v_current_date) IN (0, 6) THEN 'В'
                        ELSE 'НВ'
                    END,
                    0,
                    0,
                    EXISTS(SELECT 1 FROM holidays WHERE holiday_date = v_current_date),
                    EXTRACT(DOW FROM v_current_date) IN (0, 6)
                );
            END IF;
            
            v_current_date := v_current_date + INTERVAL '1 day';
        END LOOP;
        
        -- Calculate employee totals and update
        PERFORM update_tabel_t13_employee_totals(v_employee_id);
    END LOOP;
    
    -- Update header totals
    UPDATE tabel_t13_headers SET
        total_employees = v_total_employees,
        total_working_hours = v_total_hours,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_header_id;
    
    RETURN v_header_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update employee totals in Т-13
CREATE OR REPLACE FUNCTION update_tabel_t13_employee_totals(
    p_employee_id UUID
) RETURNS VOID AS $$
DECLARE
    v_totals RECORD;
BEGIN
    -- Calculate totals from daily data
    SELECT 
        SUM(CASE WHEN time_code_1 IN ('Я', 'I') THEN 1 ELSE 0 END) as days_i,
        SUM(CASE WHEN time_code_1 IN ('Я', 'I') THEN COALESCE(hours_1, 0) ELSE 0 END) as hours_i,
        SUM(CASE WHEN time_code_1 IN ('Н', 'H') THEN 1 ELSE 0 END) as days_h,
        SUM(CASE WHEN time_code_1 IN ('Н', 'H') THEN COALESCE(hours_1, 0) ELSE 0 END) as hours_h,
        SUM(CASE WHEN time_code_1 IN ('С', 'C') THEN 1 ELSE 0 END) as days_c,
        SUM(CASE WHEN time_code_1 IN ('С', 'C') THEN COALESCE(hours_1, 0) ELSE 0 END) as hours_c,
        SUM(CASE WHEN time_code_1 IN ('РВ', 'RV') THEN 1 ELSE 0 END) as days_rv,
        SUM(CASE WHEN time_code_1 IN ('РВ', 'RV') THEN COALESCE(hours_1, 0) ELSE 0 END) as hours_rv,
        SUM(CASE WHEN time_code_1 IN ('РВН', 'RVN') THEN 1 ELSE 0 END) as days_rvn,
        SUM(CASE WHEN time_code_1 IN ('РВН', 'RVN') THEN COALESCE(hours_1, 0) ELSE 0 END) as hours_rvn,
        SUM(CASE WHEN time_code_1 IN ('ОТ', 'OT') THEN 1 ELSE 0 END) as days_ot,
        SUM(CASE WHEN time_code_1 IN ('Б', 'B') THEN 1 ELSE 0 END) as days_b,
        SUM(CASE WHEN time_code_1 IN ('НВ', 'NV') THEN 1 ELSE 0 END) as days_nv,
        SUM(CASE WHEN time_code_1 IN ('ОД', 'OD') THEN 1 ELSE 0 END) as days_od,
        SUM(CASE WHEN time_code_1 IN ('ПК', 'PC') THEN 1 ELSE 0 END) as days_pk,
        SUM(CASE WHEN time_code_1 IN ('Г', 'G') THEN 1 ELSE 0 END) as days_g,
        SUM(CASE WHEN time_code_1 IN ('Я', 'I', 'Н', 'H', 'С', 'C', 'РВ', 'RV', 'РВН', 'RVN') THEN 1 ELSE 0 END) as total_days_worked,
        SUM(CASE WHEN time_code_1 IN ('Я', 'I', 'Н', 'H', 'С', 'C', 'РВ', 'RV', 'РВН', 'RVN') THEN COALESCE(hours_1, 0) ELSE 0 END) as total_hours_worked
    INTO v_totals
    FROM tabel_t13_daily_data
    WHERE tabel_employee_id = p_employee_id;
    
    -- Update employee record
    UPDATE tabel_t13_employees SET
        days_worked = v_totals.total_days_worked,
        hours_worked = v_totals.total_hours_worked,
        days_i = v_totals.days_i,
        hours_i = v_totals.hours_i,
        days_h = v_totals.days_h,
        hours_h = v_totals.hours_h,
        days_c = v_totals.days_c,
        hours_c = v_totals.hours_c,
        days_rv = v_totals.days_rv,
        hours_rv = v_totals.hours_rv,
        days_rvn = v_totals.days_rvn,
        hours_rvn = v_totals.hours_rvn,
        days_ot = v_totals.days_ot,
        days_b = v_totals.days_b,
        days_nv = v_totals.days_nv,
        days_additional_vacation = v_totals.days_od,
        days_training = v_totals.days_pk,
        days_public_duty = v_totals.days_g
    WHERE id = p_employee_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Exact Т-13 Display Format
-- =============================================================================

-- Main Т-13 timesheet view (exact Russian format)
CREATE VIEW v_tabel_t13_main AS
SELECT 
    h.document_number as "Номер документа",
    h.document_date as "Дата документа",
    TO_CHAR(h.reporting_period_start, 'DD.MM.YYYY') || ' - ' || 
    TO_CHAR(h.reporting_period_end, 'DD.MM.YYYY') as "Отчетный период",
    h.organization_name as "Организация",
    h.structural_unit as "Структурное подразделение",
    
    -- Employee details
    e.row_number as "№ п/п",
    e.personnel_number as "Табельный номер",
    e.employee_full_name as "Фамилия, имя, отчество",
    e.position_name as "Должность",
    e.tariff_rate as "Тарифная ставка",
    
    -- Working time totals
    e.days_worked as "Отработано дней",
    e.hours_worked as "Отработано часов",
    
    -- Time code breakdowns
    e.days_i as "Дни (Я)",
    e.hours_i as "Часы (Я)",
    e.days_h as "Дни (Н)",
    e.hours_h as "Часы (Н)",
    e.days_c as "Дни (С)",
    e.hours_c as "Часы (С)",
    e.days_rv as "Дни (РВ)",
    e.hours_rv as "Часы (РВ)",
    e.days_rvn as "Дни (РВН)",
    e.hours_rvn as "Часы (РВН)",
    e.days_ot as "Отпуск (ОТ)",
    e.days_b as "Больничный (Б)",
    e.days_nv as "Неявки (НВ)",
    
    -- Document metadata
    h.prepared_by as "Составил",
    h.checked_by as "Проверил",
    h.approved_by as "Утвердил",
    h.document_status as "Статус документа",
    
    -- Internal IDs
    h.id as header_id,
    e.id as employee_id
    
FROM tabel_t13_headers h
JOIN tabel_t13_employees e ON e.tabel_header_id = h.id
ORDER BY h.reporting_period_start DESC, e.row_number;

-- Daily time tracking grid (exact Т-13 daily format)
CREATE VIEW v_tabel_t13_daily_grid AS
SELECT 
    h.document_number,
    e.row_number,
    e.personnel_number,
    e.employee_full_name,
    
    -- Daily data columns (1-31 days of month)
    MAX(CASE WHEN d.day_of_month = 1 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "01",
    MAX(CASE WHEN d.day_of_month = 2 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "02",
    MAX(CASE WHEN d.day_of_month = 3 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "03",
    MAX(CASE WHEN d.day_of_month = 4 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "04",
    MAX(CASE WHEN d.day_of_month = 5 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "05",
    MAX(CASE WHEN d.day_of_month = 6 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "06",
    MAX(CASE WHEN d.day_of_month = 7 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "07",
    MAX(CASE WHEN d.day_of_month = 8 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "08",
    MAX(CASE WHEN d.day_of_month = 9 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "09",
    MAX(CASE WHEN d.day_of_month = 10 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "10",
    MAX(CASE WHEN d.day_of_month = 11 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "11",
    MAX(CASE WHEN d.day_of_month = 12 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "12",
    MAX(CASE WHEN d.day_of_month = 13 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "13",
    MAX(CASE WHEN d.day_of_month = 14 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "14",
    MAX(CASE WHEN d.day_of_month = 15 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "15",
    MAX(CASE WHEN d.day_of_month = 16 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "16",
    MAX(CASE WHEN d.day_of_month = 17 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "17",
    MAX(CASE WHEN d.day_of_month = 18 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "18",
    MAX(CASE WHEN d.day_of_month = 19 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "19",
    MAX(CASE WHEN d.day_of_month = 20 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "20",
    MAX(CASE WHEN d.day_of_month = 21 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "21",
    MAX(CASE WHEN d.day_of_month = 22 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "22",
    MAX(CASE WHEN d.day_of_month = 23 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "23",
    MAX(CASE WHEN d.day_of_month = 24 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "24",
    MAX(CASE WHEN d.day_of_month = 25 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "25",
    MAX(CASE WHEN d.day_of_month = 26 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "26",
    MAX(CASE WHEN d.day_of_month = 27 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "27",
    MAX(CASE WHEN d.day_of_month = 28 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "28",
    MAX(CASE WHEN d.day_of_month = 29 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "29",
    MAX(CASE WHEN d.day_of_month = 30 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "30",
    MAX(CASE WHEN d.day_of_month = 31 THEN d.time_code_1 || COALESCE('/' || d.hours_1::TEXT, '') END) as "31",
    
    -- Monthly totals
    e.days_worked as "Дней",
    e.hours_worked as "Часов"
    
FROM tabel_t13_headers h
JOIN tabel_t13_employees e ON e.tabel_header_id = h.id
LEFT JOIN tabel_t13_daily_data d ON d.tabel_employee_id = e.id
GROUP BY h.document_number, e.row_number, e.personnel_number, e.employee_full_name, 
         e.days_worked, e.hours_worked
ORDER BY e.row_number;

-- Т-13 summary report view
CREATE VIEW v_tabel_t13_summary AS
SELECT 
    h.document_number as "Номер документа",
    h.organization_name as "Организация",
    h.structural_unit as "Подразделение",
    TO_CHAR(h.reporting_period_start, 'Month YYYY') as "Отчетный период",
    h.total_employees as "Всего сотрудников",
    ROUND(h.total_working_hours, 1) as "Всего отработано часов",
    ROUND(h.total_working_hours / NULLIF(h.total_employees, 0), 1) as "Среднее часов на сотрудника",
    
    -- Document approval status
    CASE h.document_status
        WHEN 'DRAFT' THEN 'Черновик'
        WHEN 'APPROVED' THEN 'Утвержден'
        WHEN 'SUBMITTED' THEN 'Подан'
        WHEN 'ARCHIVED' THEN 'Архив'
    END as "Статус документа",
    
    h.prepared_by as "Составил",
    h.approved_by as "Утвердил",
    h.created_at as "Дата создания",
    
    -- Compliance indicators
    'Форма Т-13 по приказу Госкомстата России' as "Нормативная база",
    'Соответствует требованиям 1С ЗУП' as "Система соответствия",
    
    h.id as header_id
FROM tabel_t13_headers h
ORDER BY h.reporting_period_start DESC;

-- =============================================================================
-- Sample data generation
-- =============================================================================

-- Generate sample Т-13 for current month
SELECT generate_tabel_t13(
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day',
    'ООО "Энергосбыт"',
    'Контакт-центр'
);

COMMENT ON TABLE tabel_t13_headers IS 'Exact Russian Т-13 timesheet headers with official format';
COMMENT ON TABLE tabel_t13_employees IS 'Employee records in Т-13 with exact time code breakdowns';
COMMENT ON TABLE tabel_t13_daily_data IS 'Daily time tracking grid matching official Т-13 layout';
COMMENT ON VIEW v_tabel_t13_main IS 'Complete Т-13 timesheet in official Russian format';
COMMENT ON VIEW v_tabel_t13_daily_grid IS 'Daily time grid with 31-day columns (exact Т-13 format)';
COMMENT ON FUNCTION generate_tabel_t13 IS 'Generate official Т-13 timesheet for specified period';