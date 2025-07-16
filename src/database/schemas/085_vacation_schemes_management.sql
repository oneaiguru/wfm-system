-- Schema 085: Vacation Schemes Management (BDD 31)
-- HR vacation entitlement schemes with Russian compliance
-- Multi-period vacation planning and carry-over rules

-- 1. Vacation Scheme Definitions
CREATE TABLE vacation_schemes (
    scheme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_code VARCHAR(50) NOT NULL UNIQUE,
    scheme_name VARCHAR(255) NOT NULL,
    scheme_name_ru VARCHAR(255),
    scheme_type VARCHAR(50), -- standard, senior, management, probation
    total_days_annual INTEGER NOT NULL,
    max_periods INTEGER DEFAULT 2,
    min_days_per_period INTEGER DEFAULT 7,
    max_days_per_period INTEGER DEFAULT 21,
    min_gap_between_periods INTEGER DEFAULT 30, -- Days
    allow_carry_over BOOLEAN DEFAULT true,
    carry_over_limit_days INTEGER DEFAULT 14,
    expiry_months INTEGER DEFAULT 12,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Employee Vacation Entitlements
CREATE TABLE employee_vacation_entitlements (
    entitlement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    scheme_id UUID REFERENCES vacation_schemes(scheme_id),
    entitlement_year INTEGER NOT NULL,
    total_days_entitled INTEGER NOT NULL,
    days_used INTEGER DEFAULT 0,
    days_scheduled INTEGER DEFAULT 0,
    days_available INTEGER GENERATED ALWAYS AS (total_days_entitled - days_used - days_scheduled) STORED,
    carry_over_days INTEGER DEFAULT 0,
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, entitlement_year)
);

-- 3. Vacation Period Planning
CREATE TABLE vacation_periods (
    period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    entitlement_id UUID REFERENCES employee_vacation_entitlements(entitlement_id),
    period_number INTEGER NOT NULL, -- 1st, 2nd, 3rd period
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'planned', -- planned, approved, taken, cancelled
    approved_by VARCHAR(255),
    approved_date TIMESTAMP,
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_period CHECK (end_date >= start_date)
);

-- 4. Vacation Scheme Rules
CREATE TABLE vacation_scheme_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_id UUID REFERENCES vacation_schemes(scheme_id),
    rule_type VARCHAR(50), -- eligibility, accrual, usage, expiry
    rule_name VARCHAR(255),
    rule_condition TEXT, -- SQL condition or formula
    rule_action TEXT, -- Action to take
    priority INTEGER DEFAULT 100,
    is_mandatory BOOLEAN DEFAULT true,
    error_message TEXT,
    error_message_ru TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Vacation Accrual History
CREATE TABLE vacation_accrual_history (
    accrual_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    accrual_date DATE NOT NULL,
    accrual_type VARCHAR(50), -- monthly, annual, adjustment, carry_over
    days_accrued DECIMAL(5,2),
    balance_before DECIMAL(5,2),
    balance_after DECIMAL(5,2),
    reference_period VARCHAR(20), -- YYYY-MM
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Multi-Language Support
CREATE TABLE system_translations (
    translation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    language_code VARCHAR(5) NOT NULL, -- ru, en
    translation_key VARCHAR(255) NOT NULL,
    translation_value TEXT NOT NULL,
    context VARCHAR(100), -- menu, form, error, help
    module VARCHAR(100), -- vacation, scheduling, reporting
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(language_code, translation_key, context)
);

-- 7. User Language Preferences
CREATE TABLE user_language_preferences (
    preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,
    language_code VARCHAR(5) DEFAULT 'ru',
    date_format VARCHAR(20) DEFAULT 'DD.MM.YYYY',
    number_format VARCHAR(20) DEFAULT '1 234,56',
    time_zone VARCHAR(50) DEFAULT 'Europe/Moscow',
    first_day_of_week INTEGER DEFAULT 1, -- 1=Monday, 0=Sunday
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Browser Compatibility Tracking
CREATE TABLE browser_compatibility_tests (
    test_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    browser_name VARCHAR(50) NOT NULL, -- Firefox, Edge, Chrome, Opera
    browser_version VARCHAR(20) NOT NULL,
    test_category VARCHAR(50), -- authentication, forms, upload, responsive
    test_result VARCHAR(20), -- pass, fail, partial
    test_date DATE NOT NULL,
    issues_found TEXT,
    tested_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Recurring Event Configuration
CREATE TABLE recurring_event_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(255) NOT NULL,
    frequency_type VARCHAR(20), -- daily, weekly, monthly, yearly
    interval_value INTEGER DEFAULT 1, -- Every N days/weeks/months
    days_of_week INTEGER[], -- 1-7 for weekly
    day_of_month INTEGER, -- 1-31 for monthly
    month_of_year INTEGER, -- 1-12 for yearly
    skip_weekends BOOLEAN DEFAULT false,
    skip_holidays BOOLEAN DEFAULT false,
    start_date DATE NOT NULL,
    end_date DATE,
    occurrences_limit INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Vacation Planning Constraints
CREATE TABLE vacation_planning_constraints (
    constraint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    constraint_type VARCHAR(50), -- blackout, minimum_coverage, peak_season
    department_id UUID,
    location_id UUID,
    start_date DATE,
    end_date DATE,
    min_staff_required INTEGER,
    max_vacation_percent DECIMAL(5,2), -- Max % of staff on vacation
    priority VARCHAR(20), -- critical, high, medium, low
    override_allowed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default vacation schemes
INSERT INTO vacation_schemes (scheme_code, scheme_name, scheme_name_ru, scheme_type, total_days_annual, max_periods)
VALUES 
    ('STD-28', 'Standard Scheme', 'Стандартная схема', 'standard', 28, 2),
    ('SEN-35', 'Senior Scheme', 'Схема для старших', 'senior', 35, 3),
    ('MGT-42', 'Management Scheme', 'Схема для руководителей', 'management', 42, 4),
    ('PRB-14', 'Probation Scheme', 'Схема для испытательного срока', 'probation', 14, 1);

-- Insert system translations
INSERT INTO system_translations (language_code, translation_key, translation_value, context, module)
VALUES 
    ('ru', 'vacation.request', 'Заявка на отпуск', 'menu', 'vacation'),
    ('en', 'vacation.request', 'Vacation Request', 'menu', 'vacation'),
    ('ru', 'vacation.balance', 'Остаток отпуска', 'form', 'vacation'),
    ('en', 'vacation.balance', 'Vacation Balance', 'form', 'vacation'),
    ('ru', 'error.insufficient_days', 'Недостаточно дней отпуска', 'error', 'vacation'),
    ('en', 'error.insufficient_days', 'Insufficient vacation days', 'error', 'vacation');

-- Insert browser compatibility test results
INSERT INTO browser_compatibility_tests (browser_name, browser_version, test_category, test_result, test_date)
VALUES 
    ('Mozilla Firefox', '90+', 'authentication', 'pass', CURRENT_DATE),
    ('Microsoft Edge', '88+', 'authentication', 'pass', CURRENT_DATE),
    ('Google Chrome', '90+', 'authentication', 'pass', CURRENT_DATE),
    ('Opera', '76+', 'authentication', 'pass', CURRENT_DATE);

-- Create indexes
CREATE INDEX idx_vacation_entitlements_employee ON employee_vacation_entitlements(employee_id, entitlement_year);
CREATE INDEX idx_vacation_periods_dates ON vacation_periods(start_date, end_date);
CREATE INDEX idx_vacation_periods_status ON vacation_periods(status);
CREATE INDEX idx_translations_lookup ON system_translations(language_code, translation_key);
CREATE INDEX idx_recurring_patterns_freq ON recurring_event_patterns(frequency_type, start_date);

-- Verify vacation management tables
SELECT COUNT(*) as vacation_tables FROM information_schema.tables 
WHERE table_name LIKE '%vacation%' OR table_name LIKE '%translation%' OR table_name LIKE '%browser%';