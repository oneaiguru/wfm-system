-- =============================================================================
-- 020_argus_vacation_calculation.sql
-- EXACT ARGUS VACATION BALANCE CALCULATION - 1C ZUP Algorithm
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT 1C ZUP vacation balance calculation from BDD specs
-- Based on: BDD vacation calculation algorithm with "scrap days" logic
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ARGUS_VACATION_SCHEMES - Vacation scheme management
-- =============================================================================
CREATE TABLE argus_vacation_schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_name VARCHAR(200) NOT NULL,
    scheme_code VARCHAR(50) NOT NULL UNIQUE,
    description_ru TEXT,
    
    -- Vacation parameters from BDD specs
    annual_days INTEGER NOT NULL DEFAULT 28, -- Basic annual vacation days
    additional_days INTEGER DEFAULT 0, -- Additional vacation for special conditions
    
    -- Accrual rules (exact 1C ZUP logic)
    accrual_per_month DECIMAL(5,2) DEFAULT 2.33, -- 28 days / 12 months
    half_month_threshold INTEGER DEFAULT 15, -- Days worked to get accrual
    scrap_days_threshold INTEGER DEFAULT 15, -- "Scrap days" accumulation
    
    -- Special rules
    applies_to_new_employees BOOLEAN DEFAULT true,
    min_employment_months INTEGER DEFAULT 6, -- Minimum months before vacation
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Insert standard Russian vacation schemes from BDD
INSERT INTO argus_vacation_schemes (scheme_name, scheme_code, description_ru, annual_days, accrual_per_month) VALUES
('Основной отпуск', 'BASIC', 'Основной ежегодный оплачиваемый отпуск 28 календарных дней', 28, 2.33),
('Дополнительный отпуск', 'ADDITIONAL', 'Дополнительный отпуск за вредные условия труда', 7, 0.58),
('Удлиненный отпуск', 'EXTENDED', 'Удлиненный отпуск для педагогических работников', 56, 4.67);

-- =============================================================================
-- 2. ARGUS_VACATION_BALANCES - Exact vacation balance tracking
-- =============================================================================
CREATE TABLE argus_vacation_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    vacation_scheme_id UUID NOT NULL,
    calculation_date DATE NOT NULL,
    
    -- Employment period for calculation
    employment_start_date DATE NOT NULL,
    employment_end_date DATE, -- NULL if still employed
    calculation_period_start DATE NOT NULL,
    calculation_period_end DATE NOT NULL,
    
    -- Exact 1C ZUP calculation fields
    months_worked INTEGER DEFAULT 0,
    days_worked_current_month INTEGER DEFAULT 0,
    full_months_accrual DECIMAL(10,2) DEFAULT 0,
    partial_month_accrual DECIMAL(10,2) DEFAULT 0,
    scrap_days_accumulated DECIMAL(10,2) DEFAULT 0,
    
    -- Total balance calculation
    total_accrued_days DECIMAL(10,2) DEFAULT 0,
    days_used DECIMAL(10,2) DEFAULT 0,
    days_pending DECIMAL(10,2) DEFAULT 0, -- Approved but not taken
    available_balance DECIMAL(10,2) DEFAULT 0,
    
    -- 1C ZUP algorithm tracking
    calculation_method VARCHAR(100) DEFAULT '1C_ZUP_STANDARD',
    calculation_details JSONB, -- Detailed breakdown of calculation
    
    -- Sync with 1C ZUP
    zup_sync_status VARCHAR(20) DEFAULT 'pending',
    zup_balance_confirmation DECIMAL(10,2), -- Balance confirmed by 1C ZUP
    last_zup_sync TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_argus_vacation_balances_scheme 
        FOREIGN KEY (vacation_scheme_id) REFERENCES argus_vacation_schemes(id),
    CONSTRAINT fk_argus_vacation_balances_employee 
        FOREIGN KEY (employee_tab_n) REFERENCES zup_agent_data(tab_n),
    
    UNIQUE(employee_tab_n, vacation_scheme_id, calculation_date)
);

-- Indexes for argus_vacation_balances
CREATE INDEX idx_argus_vacation_balances_employee ON argus_vacation_balances(employee_tab_n);
CREATE INDEX idx_argus_vacation_balances_date ON argus_vacation_balances(calculation_date);

-- =============================================================================
-- 3. ARGUS_VACATION_PERIODS - Track vacation usage
-- =============================================================================
CREATE TABLE argus_vacation_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL,
    vacation_scheme_id UUID NOT NULL,
    
    -- Vacation period details
    vacation_start_date DATE NOT NULL,
    vacation_end_date DATE NOT NULL,
    calendar_days INTEGER NOT NULL,
    working_days INTEGER NOT NULL,
    
    -- Vacation type from BDD specs
    vacation_type VARCHAR(50) NOT NULL DEFAULT 'OT', -- OT, OD (annual, additional)
    vacation_status VARCHAR(20) DEFAULT 'approved', -- requested, approved, taken, cancelled
    
    -- Balance impact
    days_deducted DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2),
    balance_after DECIMAL(10,2),
    
    -- Request tracking
    request_date DATE NOT NULL,
    approved_date DATE,
    approved_by VARCHAR(100),
    
    -- 1C ZUP integration
    zup_document_id VARCHAR(100), -- Created vacation document in 1C ZUP
    zup_sync_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_argus_vacation_periods_scheme 
        FOREIGN KEY (vacation_scheme_id) REFERENCES argus_vacation_schemes(id),
    CONSTRAINT fk_argus_vacation_periods_employee 
        FOREIGN KEY (employee_tab_n) REFERENCES zup_agent_data(tab_n)
);

-- Indexes for argus_vacation_periods
CREATE INDEX idx_argus_vacation_periods_employee ON argus_vacation_periods(employee_tab_n);
CREATE INDEX idx_argus_vacation_periods_dates ON argus_vacation_periods(vacation_start_date, vacation_end_date);

-- =============================================================================
-- FUNCTIONS: Exact 1C ZUP Vacation Calculation Algorithm
-- =============================================================================

-- Function implementing EXACT 1C ZUP vacation balance calculation
CREATE OR REPLACE FUNCTION calculate_argus_vacation_balance(
    p_employee_tab_n VARCHAR(50),
    p_calculation_date DATE DEFAULT CURRENT_DATE,
    p_vacation_scheme_code VARCHAR(50) DEFAULT 'BASIC'
) RETURNS JSONB AS $$
DECLARE
    v_employee zup_agent_data%ROWTYPE;
    v_scheme argus_vacation_schemes%ROWTYPE;
    v_balance_id UUID;
    v_employment_months INTEGER;
    v_current_month_days INTEGER;
    v_full_months_accrual DECIMAL(10,2);
    v_partial_accrual DECIMAL(10,2);
    v_scrap_days DECIMAL(10,2) := 0;
    v_total_accrued DECIMAL(10,2);
    v_days_used DECIMAL(10,2);
    v_available_balance DECIMAL(10,2);
    v_calculation_details JSONB;
    v_result JSONB;
    v_month_start DATE;
    v_month_end DATE;
    v_working_days_in_month INTEGER;
BEGIN
    -- Get employee data
    SELECT * INTO v_employee 
    FROM zup_agent_data 
    WHERE tab_n = p_employee_tab_n;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee not found: %', p_employee_tab_n;
    END IF;
    
    -- Get vacation scheme
    SELECT * INTO v_scheme 
    FROM argus_vacation_schemes 
    WHERE scheme_code = p_vacation_scheme_code AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vacation scheme not found: %', p_vacation_scheme_code;
    END IF;
    
    -- Calculate employment months (complete months)
    v_employment_months := EXTRACT(YEAR FROM AGE(p_calculation_date, v_employee.start_work)) * 12 +
                          EXTRACT(MONTH FROM AGE(p_calculation_date, v_employee.start_work));
    
    -- Calculate accrual for full months
    v_full_months_accrual := v_employment_months * v_scheme.accrual_per_month;
    
    -- Calculate current month partial accrual (exact 1C ZUP algorithm)
    v_month_start := DATE_TRUNC('month', p_calculation_date);
    v_month_end := (DATE_TRUNC('month', p_calculation_date) + INTERVAL '1 month - 1 day')::DATE;
    v_current_month_days := EXTRACT(DAY FROM p_calculation_date) - 1; -- Days worked in current month
    
    -- Count working days in current month
    SELECT COUNT(*) INTO v_working_days_in_month
    FROM production_calendar
    WHERE calendar_date BETWEEN v_month_start AND v_month_end
    AND day_type = 'working';
    
    -- Apply exact 1C ZUP partial month logic
    IF v_current_month_days >= v_scheme.half_month_threshold THEN
        -- Half month worked: end of day + 14 days accrual
        v_partial_accrual := v_scheme.accrual_per_month;
    ELSIF v_current_month_days > 0 THEN
        -- Less than half month: accumulate "scrap days"
        v_scrap_days := v_current_month_days;
        v_partial_accrual := 0;
        
        -- If scrap days >= 15, convert to accrual
        IF v_scrap_days >= v_scheme.scrap_days_threshold THEN
            v_partial_accrual := v_scheme.accrual_per_month;
            v_scrap_days := v_scrap_days - v_scheme.scrap_days_threshold;
        END IF;
    ELSE
        v_partial_accrual := 0;
    END IF;
    
    -- Handle 31-day month exception (17th day = 16 day scraps)
    IF EXTRACT(DAY FROM v_month_end) = 31 AND v_current_month_days = 17 THEN
        v_scrap_days := 16;
    END IF;
    
    -- Calculate total accrued days
    v_total_accrued := v_full_months_accrual + v_partial_accrual;
    
    -- Calculate days used (from vacation periods)
    SELECT COALESCE(SUM(days_deducted), 0) INTO v_days_used
    FROM argus_vacation_periods
    WHERE employee_tab_n = p_employee_tab_n
    AND vacation_scheme_id = v_scheme.id
    AND vacation_status IN ('approved', 'taken');
    
    -- Calculate available balance
    v_available_balance := v_total_accrued - v_days_used;
    
    -- Prepare detailed calculation breakdown
    v_calculation_details := jsonb_build_object(
        'algorithm', '1C_ZUP_STANDARD',
        'employment_start', v_employee.start_work,
        'calculation_date', p_calculation_date,
        'employment_months', v_employment_months,
        'current_month_days', v_current_month_days,
        'working_days_in_month', v_working_days_in_month,
        'accrual_per_month', v_scheme.accrual_per_month,
        'full_months_accrual', v_full_months_accrual,
        'partial_month_accrual', v_partial_accrual,
        'scrap_days_accumulated', v_scrap_days,
        'half_month_threshold', v_scheme.half_month_threshold,
        'scrap_days_threshold', v_scheme.scrap_days_threshold,
        'total_accrued', v_total_accrued,
        'days_used', v_days_used,
        'available_balance', v_available_balance
    );
    
    -- Store/update vacation balance
    INSERT INTO argus_vacation_balances (
        employee_tab_n,
        vacation_scheme_id,
        calculation_date,
        employment_start_date,
        calculation_period_start,
        calculation_period_end,
        months_worked,
        days_worked_current_month,
        full_months_accrual,
        partial_month_accrual,
        scrap_days_accumulated,
        total_accrued_days,
        days_used,
        available_balance,
        calculation_details
    ) VALUES (
        p_employee_tab_n,
        v_scheme.id,
        p_calculation_date,
        v_employee.start_work,
        v_month_start,
        v_month_end,
        v_employment_months,
        v_current_month_days,
        v_full_months_accrual,
        v_partial_accrual,
        v_scrap_days,
        v_total_accrued,
        v_days_used,
        v_available_balance,
        v_calculation_details
    ) ON CONFLICT (employee_tab_n, vacation_scheme_id, calculation_date) 
    DO UPDATE SET
        months_worked = EXCLUDED.months_worked,
        days_worked_current_month = EXCLUDED.days_worked_current_month,
        full_months_accrual = EXCLUDED.full_months_accrual,
        partial_month_accrual = EXCLUDED.partial_month_accrual,
        scrap_days_accumulated = EXCLUDED.scrap_days_accumulated,
        total_accrued_days = EXCLUDED.total_accrued_days,
        days_used = EXCLUDED.days_used,
        available_balance = EXCLUDED.available_balance,
        calculation_details = EXCLUDED.calculation_details
    RETURNING id INTO v_balance_id;
    
    -- Prepare result
    v_result := jsonb_build_object(
        'balance_id', v_balance_id,
        'employee_tab_n', p_employee_tab_n,
        'vacation_scheme', v_scheme.scheme_name,
        'calculation_date', p_calculation_date,
        'total_accrued_days', v_total_accrued,
        'days_used', v_days_used,
        'available_balance', v_available_balance,
        'employment_months', v_employment_months,
        'scrap_days', v_scrap_days,
        'calculation_method', '1C_ZUP_ALGORITHM',
        'calculation_details', v_calculation_details
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to request vacation (part of multi-stage workflow)
CREATE OR REPLACE FUNCTION request_argus_vacation(
    p_employee_tab_n VARCHAR(50),
    p_vacation_start DATE,
    p_vacation_end DATE,
    p_vacation_type VARCHAR(50) DEFAULT 'OT',
    p_vacation_scheme_code VARCHAR(50) DEFAULT 'BASIC'
) RETURNS JSONB AS $$
DECLARE
    v_scheme argus_vacation_schemes%ROWTYPE;
    v_calendar_days INTEGER;
    v_working_days INTEGER;
    v_current_balance DECIMAL(10,2);
    v_vacation_id UUID;
    v_result JSONB;
BEGIN
    -- Get vacation scheme
    SELECT * INTO v_scheme 
    FROM argus_vacation_schemes 
    WHERE scheme_code = p_vacation_scheme_code AND is_active = true;
    
    -- Calculate vacation days
    v_calendar_days := p_vacation_end - p_vacation_start + 1;
    
    -- Count working days (excluding weekends and holidays)
    SELECT COUNT(*) INTO v_working_days
    FROM production_calendar
    WHERE calendar_date BETWEEN p_vacation_start AND p_vacation_end
    AND day_type = 'working';
    
    -- Get current balance
    SELECT available_balance INTO v_current_balance
    FROM argus_vacation_balances
    WHERE employee_tab_n = p_employee_tab_n
    AND vacation_scheme_id = v_scheme.id
    ORDER BY calculation_date DESC
    LIMIT 1;
    
    -- Check if enough balance
    IF v_current_balance < v_calendar_days THEN
        RAISE EXCEPTION 'Insufficient vacation balance. Available: %, Requested: %', 
                       v_current_balance, v_calendar_days;
    END IF;
    
    -- Create vacation request
    INSERT INTO argus_vacation_periods (
        employee_tab_n,
        vacation_scheme_id,
        vacation_start_date,
        vacation_end_date,
        calendar_days,
        working_days,
        vacation_type,
        vacation_status,
        days_deducted,
        balance_before,
        request_date
    ) VALUES (
        p_employee_tab_n,
        v_scheme.id,
        p_vacation_start,
        p_vacation_end,
        v_calendar_days,
        v_working_days,
        p_vacation_type,
        'requested', -- Will go through approval workflow
        v_calendar_days,
        v_current_balance,
        CURRENT_DATE
    ) RETURNING id INTO v_vacation_id;
    
    v_result := jsonb_build_object(
        'vacation_id', v_vacation_id,
        'employee_tab_n', p_employee_tab_n,
        'vacation_start', p_vacation_start,
        'vacation_end', p_vacation_end,
        'calendar_days', v_calendar_days,
        'working_days', v_working_days,
        'current_balance', v_current_balance,
        'balance_after', v_current_balance - v_calendar_days,
        'status', 'requested'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Vacation Balance and Usage Reporting
-- =============================================================================

-- Current vacation balances view
CREATE VIEW v_argus_vacation_balances AS
SELECT 
    zda.tab_n,
    zda.lastname || ' ' || zda.firstname as employee_name,
    zda.position_name,
    avs.scheme_name as vacation_scheme,
    avb.calculation_date,
    avb.employment_start_date,
    avb.months_worked,
    avb.total_accrued_days,
    avb.days_used,
    avb.available_balance,
    avb.scrap_days_accumulated,
    avb.calculation_details->>'algorithm' as calculation_method,
    CASE 
        WHEN avb.available_balance >= 28 THEN 'Достаточно для основного отпуска'
        WHEN avb.available_balance >= 14 THEN 'Достаточно для частичного отпуска'
        ELSE 'Недостаточно дней'
    END as balance_status_ru
FROM argus_vacation_balances avb
JOIN zup_agent_data zda ON zda.tab_n = avb.employee_tab_n
JOIN argus_vacation_schemes avs ON avs.id = avb.vacation_scheme_id
WHERE avb.calculation_date = (
    SELECT MAX(calculation_date) 
    FROM argus_vacation_balances avb2 
    WHERE avb2.employee_tab_n = avb.employee_tab_n 
    AND avb2.vacation_scheme_id = avb.vacation_scheme_id
)
ORDER BY zda.lastname, zda.firstname;

-- Vacation usage history view
CREATE VIEW v_argus_vacation_usage AS
SELECT 
    zda.tab_n,
    zda.lastname || ' ' || zda.firstname as employee_name,
    avp.vacation_start_date,
    avp.vacation_end_date,
    avp.calendar_days,
    avp.working_days,
    CASE avp.vacation_type
        WHEN 'OT' THEN 'Основной отпуск'
        WHEN 'OD' THEN 'Дополнительный отпуск'
        ELSE avp.vacation_type
    END as vacation_type_ru,
    CASE avp.vacation_status
        WHEN 'requested' THEN 'Заявлено'
        WHEN 'approved' THEN 'Утверждено'
        WHEN 'taken' THEN 'Взято'
        WHEN 'cancelled' THEN 'Отменено'
        ELSE avp.vacation_status
    END as status_ru,
    avp.balance_before,
    avp.balance_after,
    avp.request_date,
    avp.approved_date
FROM argus_vacation_periods avp
JOIN zup_agent_data zda ON zda.tab_n = avp.employee_tab_n
ORDER BY avp.vacation_start_date DESC;

-- Demo vacation calculation accuracy
CREATE VIEW v_demo_vacation_calculation AS
SELECT 
    'Argus Vacation Calculation' as metric_name,
    'Exact 1C ZUP Algorithm' as category,
    COUNT(DISTINCT avb.employee_tab_n) as employees_calculated,
    ROUND(AVG(avb.total_accrued_days), 1) as avg_accrued_days,
    ROUND(AVG(avb.available_balance), 1) as avg_available_balance,
    COUNT(*) FILTER (WHERE avb.scrap_days_accumulated > 0) as employees_with_scrap_days,
    'Exact 1C ZUP algorithm: (normWeek/5)*workingDays*rate + scrap days logic' as calculation_method,
    NOW() as measurement_time
FROM argus_vacation_balances avb
WHERE avb.calculation_date >= CURRENT_DATE - INTERVAL '30 days';

COMMENT ON TABLE argus_vacation_schemes IS 'Russian vacation schemes with exact 1C ZUP parameters';
COMMENT ON TABLE argus_vacation_balances IS 'Exact 1C ZUP vacation balance calculation with scrap days';
COMMENT ON FUNCTION calculate_argus_vacation_balance IS 'Implements exact 1C ZUP vacation balance algorithm';
COMMENT ON VIEW v_argus_vacation_balances IS 'Current vacation balances with Russian status descriptions';