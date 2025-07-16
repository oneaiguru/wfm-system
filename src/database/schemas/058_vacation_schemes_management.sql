-- =============================================================================
-- 058_vacation_schemes_management.sql
-- EXACT BDD Implementation: Vacation Schemes Management with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 31-vacation-schemes-management.feature (130 lines)
-- Purpose: Comprehensive vacation schemes management with multi-language support and event scheduling
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. VACATION SCHEME TYPES
-- =============================================================================

-- Vacation scheme types from BDD lines 15-20
CREATE TABLE vacation_scheme_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_type_id VARCHAR(50) NOT NULL UNIQUE,
    scheme_type_name VARCHAR(100) NOT NULL,
    scheme_description TEXT,
    
    -- Vacation entitlements from BDD lines 16-20
    annual_vacation_days INTEGER NOT NULL CHECK (annual_vacation_days > 0),
    max_periods_per_year INTEGER NOT NULL CHECK (max_periods_per_year > 0),
    
    -- Period configuration from BDD lines 22-27
    min_duration_days INTEGER DEFAULT 7 CHECK (min_duration_days >= 7 AND min_duration_days <= 21),
    max_duration_days INTEGER DEFAULT 28 CHECK (max_duration_days >= 14 AND max_duration_days <= 28),
    min_gap_days INTEGER DEFAULT 30 CHECK (min_gap_days >= 30 AND min_gap_days <= 90),
    allow_carry_over BOOLEAN DEFAULT true,
    expiry_period_months INTEGER DEFAULT 12 CHECK (expiry_period_months >= 6 AND expiry_period_months <= 18),
    
    -- Additional scheme parameters
    pro_rata_calculation BOOLEAN DEFAULT true,
    accrual_method VARCHAR(20) DEFAULT 'monthly' CHECK (accrual_method IN ('daily', 'weekly', 'monthly', 'yearly')),
    minimum_service_months INTEGER DEFAULT 6,
    
    -- Business rules
    requires_approval BOOLEAN DEFAULT true,
    advance_notice_days INTEGER DEFAULT 14,
    blackout_periods_apply BOOLEAN DEFAULT true,
    can_split_periods BOOLEAN DEFAULT true,
    
    -- Employee scope
    applies_to_employee_types JSONB DEFAULT '[]',
    applies_to_departments JSONB DEFAULT '[]',
    applies_to_locations JSONB DEFAULT '[]',
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    created_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Ensure logical constraints
    CHECK (max_duration_days >= min_duration_days),
    CHECK (expiry_date IS NULL OR expiry_date > effective_date)
);

-- =============================================================================
-- 2. EMPLOYEE VACATION ENTITLEMENTS
-- =============================================================================

-- Employee vacation entitlements based on schemes
CREATE TABLE employee_vacation_entitlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entitlement_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    scheme_type_id VARCHAR(50) NOT NULL,
    
    -- Entitlement period
    entitlement_year INTEGER NOT NULL CHECK (entitlement_year >= 2020 AND entitlement_year <= 2050),
    
    -- Calculated entitlements
    entitled_days DECIMAL(4,1) NOT NULL DEFAULT 0.0,
    carried_over_days DECIMAL(4,1) DEFAULT 0.0,
    total_available_days DECIMAL(4,1) NOT NULL DEFAULT 0.0,
    
    -- Usage tracking
    used_days DECIMAL(4,1) DEFAULT 0.0,
    pending_requests_days DECIMAL(4,1) DEFAULT 0.0,
    remaining_days DECIMAL(4,1) NOT NULL DEFAULT 0.0,
    
    -- Period tracking
    periods_used INTEGER DEFAULT 0,
    periods_remaining INTEGER NOT NULL,
    
    -- Pro-rata calculations
    pro_rata_factor DECIMAL(5,4) DEFAULT 1.0,
    service_start_date DATE,
    service_months INTEGER DEFAULT 0,
    
    -- Expiry tracking
    expiry_date DATE,
    days_to_expire DECIMAL(4,1) DEFAULT 0.0,
    expiry_warning_sent BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_recalculated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (scheme_type_id) REFERENCES vacation_scheme_types(scheme_type_id) ON DELETE RESTRICT,
    
    UNIQUE(employee_id, entitlement_year),
    
    -- Ensure data consistency
    CHECK (total_available_days = entitled_days + carried_over_days),
    CHECK (remaining_days = total_available_days - used_days - pending_requests_days),
    CHECK (periods_remaining >= 0)
);

-- =============================================================================
-- 3. MULTI-LANGUAGE INTERFACE SUPPORT
-- =============================================================================

-- Multi-language support from BDD lines 29-48
CREATE TABLE system_localization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    localization_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Language configuration from BDD lines 33-35
    language_code VARCHAR(5) NOT NULL CHECK (language_code IN ('ru', 'en')),
    language_name VARCHAR(50) NOT NULL,
    coverage_percentage DECIMAL(5,2) DEFAULT 100.0 CHECK (coverage_percentage >= 0.0 AND coverage_percentage <= 100.0),
    is_default BOOLEAN DEFAULT false,
    
    -- Interface elements from BDD lines 37-43
    menu_translations JSONB DEFAULT '{}',
    form_label_translations JSONB DEFAULT '{}',
    error_message_translations JSONB DEFAULT '{}',
    help_text_translations JSONB DEFAULT '{}',
    
    -- Regional formatting from BDD lines 42-43
    date_format VARCHAR(20) DEFAULT 'DD.MM.YYYY',
    time_format VARCHAR(20) DEFAULT 'HH:MM',
    number_format VARCHAR(20) DEFAULT '1 234,56',
    currency_format VARCHAR(20) DEFAULT '1 234,56 ₽',
    
    -- Locale settings
    locale_code VARCHAR(10) NOT NULL,
    timezone_default VARCHAR(50) DEFAULT 'Europe/Moscow',
    first_day_of_week INTEGER DEFAULT 1 CHECK (first_day_of_week >= 1 AND first_day_of_week <= 7),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    translation_completeness DECIMAL(5,2) DEFAULT 100.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(language_code)
);

-- =============================================================================
-- 4. USER LANGUAGE PREFERENCES
-- =============================================================================

-- User language preferences from BDD lines 44-48
CREATE TABLE user_language_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- Language preferences from BDD lines 45-48
    preferred_language_code VARCHAR(5) NOT NULL,
    regional_settings JSONB DEFAULT '{}',
    date_time_format_preference VARCHAR(50),
    
    -- Preference storage from BDD lines 45-47
    storage_type VARCHAR(20) DEFAULT 'user_profile' CHECK (storage_type IN (
        'user_profile', 'browser_session', 'system_default'
    )),
    persistence_level VARCHAR(20) DEFAULT 'permanent' CHECK (persistence_level IN (
        'permanent', 'session', 'configurable'
    )),
    
    -- Session tracking
    last_language_switch TIMESTAMP WITH TIME ZONE,
    session_language_overrides JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (preferred_language_code) REFERENCES system_localization(language_code) ON DELETE RESTRICT,
    
    UNIQUE(user_id)
);

-- =============================================================================
-- 5. BROWSER COMPATIBILITY TRACKING
-- =============================================================================

-- Browser compatibility from BDD lines 50-66
CREATE TABLE browser_compatibility_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compatibility_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Browser information from BDD lines 55-59
    browser_name VARCHAR(50) NOT NULL CHECK (browser_name IN (
        'Mozilla Firefox', 'Microsoft Edge', 'Google Chrome', 'Opera', 'Safari', 'Other'
    )),
    browser_version VARCHAR(20) NOT NULL,
    compatibility_level VARCHAR(20) DEFAULT 'full' CHECK (compatibility_level IN (
        'full', 'partial', 'limited', 'unsupported'
    )),
    
    -- Feature support from BDD lines 61-66
    authentication_support BOOLEAN DEFAULT true,
    form_submission_support BOOLEAN DEFAULT true,
    file_upload_support BOOLEAN DEFAULT true,
    date_picker_support BOOLEAN DEFAULT true,
    responsive_design_support BOOLEAN DEFAULT true,
    
    -- Additional features
    javascript_support BOOLEAN DEFAULT true,
    css3_support BOOLEAN DEFAULT true,
    html5_support BOOLEAN DEFAULT true,
    websocket_support BOOLEAN DEFAULT true,
    local_storage_support BOOLEAN DEFAULT true,
    
    -- Version requirements
    minimum_supported_version VARCHAR(20),
    recommended_version VARCHAR(20),
    latest_tested_version VARCHAR(20),
    
    -- Testing metadata
    last_tested_date DATE,
    test_results JSONB DEFAULT '{}',
    known_issues JSONB DEFAULT '[]',
    
    -- Status
    is_supported BOOLEAN DEFAULT true,
    support_level VARCHAR(20) DEFAULT 'full',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(browser_name, browser_version)
);

-- =============================================================================
-- 6. EVENT REGULARITY CONFIGURATION
-- =============================================================================

-- Event regularity from BDD lines 68-88
CREATE TABLE event_regularity_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id VARCHAR(50) NOT NULL UNIQUE,
    pattern_name VARCHAR(100) NOT NULL,
    
    -- Frequency options from BDD lines 73-77
    frequency_type VARCHAR(20) NOT NULL CHECK (frequency_type IN (
        'daily', 'weekly', 'monthly', 'yearly'
    )),
    frequency_description TEXT,
    
    -- Frequency-specific settings from BDD lines 79-83
    frequency_interval INTEGER DEFAULT 1,
    days_of_week JSONB DEFAULT '[]',
    day_of_month INTEGER CHECK (day_of_month >= 1 AND day_of_month <= 31),
    month_of_year INTEGER CHECK (month_of_year >= 1 AND month_of_year <= 12),
    
    -- Additional settings from BDD lines 80-83
    skip_weekends BOOLEAN DEFAULT false,
    skip_holidays BOOLEAN DEFAULT false,
    week_interval INTEGER DEFAULT 1 CHECK (week_interval >= 1 AND week_interval <= 4),
    
    -- Recurrence limits from BDD lines 85-88
    recurrence_limit_type VARCHAR(20) DEFAULT 'no_end' CHECK (recurrence_limit_type IN (
        'end_date', 'occurrence_count', 'no_end'
    )),
    recurrence_end_date DATE,
    max_occurrences INTEGER,
    
    -- Pattern configuration
    time_of_day TIME,
    duration_minutes INTEGER,
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure logical constraints
    CHECK (
        (recurrence_limit_type = 'end_date' AND recurrence_end_date IS NOT NULL) OR
        (recurrence_limit_type = 'occurrence_count' AND max_occurrences IS NOT NULL) OR
        (recurrence_limit_type = 'no_end')
    )
);

-- =============================================================================
-- 7. WEEKDAY SELECTION CONFIGURATION
-- =============================================================================

-- Weekday selection from BDD lines 90-107
CREATE TABLE weekday_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    weekday_id VARCHAR(3) NOT NULL UNIQUE,
    weekday_name VARCHAR(20) NOT NULL,
    
    -- Weekday properties from BDD lines 95-102
    weekday_code VARCHAR(3) NOT NULL,
    is_business_day BOOLEAN NOT NULL,
    day_number INTEGER NOT NULL CHECK (day_number >= 1 AND day_number <= 7),
    
    -- Localization
    display_name_ru VARCHAR(20),
    display_name_en VARCHAR(20),
    short_name_ru VARCHAR(3),
    short_name_en VARCHAR(3),
    
    -- Business configuration
    default_working_hours DECIMAL(3,1) DEFAULT 8.0,
    overtime_multiplier DECIMAL(3,2) DEFAULT 1.0,
    is_premium_day BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(day_number)
);

-- =============================================================================
-- 8. EVENT TYPE CONFIGURATION
-- =============================================================================

-- Event types from BDD lines 109-128
CREATE TABLE event_type_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type_id VARCHAR(50) NOT NULL UNIQUE,
    event_type_name VARCHAR(100) NOT NULL,
    event_description TEXT,
    
    -- Event properties from BDD lines 114-120
    default_duration_minutes INTEGER NOT NULL,
    participant_type VARCHAR(20) NOT NULL CHECK (participant_type IN ('individual', 'group')),
    
    -- Type-specific configuration from BDD lines 122-128
    required_fields JSONB NOT NULL,
    optional_fields JSONB DEFAULT '{}',
    
    -- Event characteristics
    allows_overlap BOOLEAN DEFAULT false,
    requires_room BOOLEAN DEFAULT false,
    requires_equipment BOOLEAN DEFAULT false,
    supports_remote BOOLEAN DEFAULT true,
    
    -- Scheduling constraints
    min_advance_notice_hours INTEGER DEFAULT 1,
    max_advance_booking_days INTEGER DEFAULT 365,
    can_be_cancelled BOOLEAN DEFAULT true,
    cancellation_notice_hours INTEGER DEFAULT 2,
    
    -- Business rules
    affects_availability BOOLEAN DEFAULT true,
    counts_as_productive_time BOOLEAN DEFAULT true,
    requires_manager_approval BOOLEAN DEFAULT false,
    
    -- Display configuration
    color_code VARCHAR(7) DEFAULT '#007bff',
    icon_name VARCHAR(50),
    display_priority INTEGER DEFAULT 1,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. VACATION SCHEME ASSIGNMENTS
-- =============================================================================

-- Employee vacation scheme assignments
CREATE TABLE employee_scheme_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    scheme_type_id VARCHAR(50) NOT NULL,
    
    -- Assignment period
    assignment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    
    -- Assignment reason and context
    assignment_reason VARCHAR(100),
    assigned_by UUID,
    assignment_notes TEXT,
    
    -- Transition handling
    previous_scheme_id VARCHAR(50),
    transition_method VARCHAR(20) DEFAULT 'immediate' CHECK (transition_method IN (
        'immediate', 'end_of_year', 'anniversary_date', 'manual'
    )),
    
    -- Override settings
    custom_entitlement_days INTEGER,
    custom_periods INTEGER,
    custom_rules JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (scheme_type_id) REFERENCES vacation_scheme_types(scheme_type_id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (previous_scheme_id) REFERENCES vacation_scheme_types(scheme_type_id) ON DELETE SET NULL,
    
    -- Ensure valid date ranges
    CHECK (end_date IS NULL OR end_date >= effective_date)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Vacation scheme queries
CREATE INDEX idx_vacation_scheme_types_active ON vacation_scheme_types(is_active) WHERE is_active = true;
CREATE INDEX idx_vacation_scheme_types_effective ON vacation_scheme_types(effective_date, expiry_date);

-- Employee entitlement queries
CREATE INDEX idx_employee_vacation_entitlements_employee ON employee_vacation_entitlements(employee_id);
CREATE INDEX idx_employee_vacation_entitlements_year ON employee_vacation_entitlements(entitlement_year);
CREATE INDEX idx_employee_vacation_entitlements_scheme ON employee_vacation_entitlements(scheme_type_id);
CREATE INDEX idx_employee_vacation_entitlements_active ON employee_vacation_entitlements(is_active) WHERE is_active = true;
CREATE INDEX idx_employee_vacation_entitlements_expiry ON employee_vacation_entitlements(expiry_date) WHERE expiry_date IS NOT NULL;

-- Localization queries
CREATE INDEX idx_system_localization_language ON system_localization(language_code);
CREATE INDEX idx_system_localization_default ON system_localization(is_default) WHERE is_default = true;
CREATE INDEX idx_system_localization_active ON system_localization(is_active) WHERE is_active = true;

-- User preference queries
CREATE INDEX idx_user_language_preferences_user ON user_language_preferences(user_id);
CREATE INDEX idx_user_language_preferences_language ON user_language_preferences(preferred_language_code);
CREATE INDEX idx_user_language_preferences_active ON user_language_preferences(is_active) WHERE is_active = true;

-- Browser compatibility queries
CREATE INDEX idx_browser_compatibility_browser ON browser_compatibility_tracking(browser_name);
CREATE INDEX idx_browser_compatibility_version ON browser_compatibility_tracking(browser_name, browser_version);
CREATE INDEX idx_browser_compatibility_supported ON browser_compatibility_tracking(is_supported) WHERE is_supported = true;

-- Event pattern queries
CREATE INDEX idx_event_regularity_patterns_frequency ON event_regularity_patterns(frequency_type);
CREATE INDEX idx_event_regularity_patterns_active ON event_regularity_patterns(is_active) WHERE is_active = true;

-- Weekday configuration queries
CREATE INDEX idx_weekday_configuration_business ON weekday_configuration(is_business_day);
CREATE INDEX idx_weekday_configuration_day ON weekday_configuration(day_number);
CREATE INDEX idx_weekday_configuration_active ON weekday_configuration(is_active) WHERE is_active = true;

-- Event type queries
CREATE INDEX idx_event_type_configuration_type ON event_type_configuration(event_type_id);
CREATE INDEX idx_event_type_configuration_participant ON event_type_configuration(participant_type);
CREATE INDEX idx_event_type_configuration_active ON event_type_configuration(is_active) WHERE is_active = true;

-- Assignment queries
CREATE INDEX idx_employee_scheme_assignments_employee ON employee_scheme_assignments(employee_id);
CREATE INDEX idx_employee_scheme_assignments_scheme ON employee_scheme_assignments(scheme_type_id);
CREATE INDEX idx_employee_scheme_assignments_effective ON employee_scheme_assignments(effective_date, end_date);
CREATE INDEX idx_employee_scheme_assignments_active ON employee_scheme_assignments(is_active) WHERE is_active = true;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_vacation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER vacation_scheme_types_update_trigger
    BEFORE UPDATE ON vacation_scheme_types
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER employee_vacation_entitlements_update_trigger
    BEFORE UPDATE ON employee_vacation_entitlements
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER system_localization_update_trigger
    BEFORE UPDATE ON system_localization
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER user_language_preferences_update_trigger
    BEFORE UPDATE ON user_language_preferences
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER browser_compatibility_tracking_update_trigger
    BEFORE UPDATE ON browser_compatibility_tracking
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER event_regularity_patterns_update_trigger
    BEFORE UPDATE ON event_regularity_patterns
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER event_type_configuration_update_trigger
    BEFORE UPDATE ON event_type_configuration
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

CREATE TRIGGER employee_scheme_assignments_update_trigger
    BEFORE UPDATE ON employee_scheme_assignments
    FOR EACH ROW EXECUTE FUNCTION update_vacation_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active vacation schemes with details
CREATE VIEW v_active_vacation_schemes AS
SELECT 
    vst.scheme_type_id,
    vst.scheme_type_name,
    vst.scheme_description,
    vst.annual_vacation_days,
    vst.max_periods_per_year,
    vst.min_duration_days,
    vst.max_duration_days,
    vst.allow_carry_over,
    vst.effective_date,
    vst.expiry_date
FROM vacation_scheme_types vst
WHERE vst.is_active = true
  AND vst.effective_date <= CURRENT_DATE
  AND (vst.expiry_date IS NULL OR vst.expiry_date > CURRENT_DATE)
ORDER BY vst.scheme_type_name;

-- Employee vacation entitlements summary
CREATE VIEW v_employee_vacation_summary AS
SELECT 
    e.id as employee_id,
    e.full_name,
    eve.entitlement_year,
    vst.scheme_type_name,
    eve.total_available_days,
    eve.used_days,
    eve.pending_requests_days,
    eve.remaining_days,
    eve.periods_used,
    eve.periods_remaining,
    eve.expiry_date,
    CASE 
        WHEN eve.expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon'
        WHEN eve.remaining_days < eve.total_available_days * 0.2 THEN 'Low Balance'
        ELSE 'Normal'
    END as status
FROM employee_vacation_entitlements eve
JOIN employees e ON eve.employee_id = e.id
JOIN vacation_scheme_types vst ON eve.scheme_type_id = vst.scheme_type_id
WHERE eve.is_active = true
  AND eve.entitlement_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY e.full_name;

-- Browser compatibility matrix
CREATE VIEW v_browser_compatibility_matrix AS
SELECT 
    bct.browser_name,
    bct.browser_version,
    bct.compatibility_level,
    bct.authentication_support,
    bct.form_submission_support,
    bct.file_upload_support,
    bct.date_picker_support,
    bct.responsive_design_support,
    bct.last_tested_date
FROM browser_compatibility_tracking bct
WHERE bct.is_supported = true
ORDER BY bct.browser_name, bct.browser_version DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert vacation scheme types from BDD lines 16-20
INSERT INTO vacation_scheme_types (scheme_type_id, scheme_type_name, scheme_description, annual_vacation_days, max_periods_per_year) VALUES
('standard', 'Standard', 'Regular employees', 28, 2),
('senior', 'Senior', 'Senior employees', 35, 3),
('management', 'Management', 'Management level', 42, 4),
('probation', 'Probation', 'New employees', 14, 1);

-- Insert localization data from BDD lines 33-35
INSERT INTO system_localization (localization_id, language_code, language_name, is_default, locale_code) VALUES
('ru_localization', 'ru', 'Russian', true, 'ru_RU'),
('en_localization', 'en', 'English', false, 'en_US');

-- Insert weekday configuration from BDD lines 95-102
INSERT INTO weekday_configuration (weekday_id, weekday_name, weekday_code, is_business_day, day_number, display_name_ru, display_name_en) VALUES
('MON', 'Monday', 'MON', true, 1, 'Понедельник', 'Monday'),
('TUE', 'Tuesday', 'TUE', true, 2, 'Вторник', 'Tuesday'),
('WED', 'Wednesday', 'WED', true, 3, 'Среда', 'Wednesday'),
('THU', 'Thursday', 'THU', true, 4, 'Четверг', 'Thursday'),
('FRI', 'Friday', 'FRI', true, 5, 'Пятница', 'Friday'),
('SAT', 'Saturday', 'SAT', false, 6, 'Суббота', 'Saturday'),
('SUN', 'Sunday', 'SUN', false, 7, 'Воскресенье', 'Sunday');

-- Insert event types from BDD lines 114-120
INSERT INTO event_type_configuration (event_type_id, event_type_name, event_description, default_duration_minutes, participant_type, required_fields) VALUES
('training', 'Training', 'Training session', 120, 'group', '["duration", "participants"]'),
('meeting', 'Meeting', 'Team meeting', 60, 'group', '["duration", "participants"]'),
('break', 'Break', 'Rest period', 15, 'individual', '["duration"]'),
('lunch', 'Lunch', 'Lunch break', 60, 'individual', '["duration"]'),
('project', 'Project', 'Project work', 480, 'group', '["duration", "participants"]'),
('call_center', 'Call Center', 'Intraday activity', 60, 'group', '["duration", "service"]');

-- Insert browser compatibility data from BDD lines 55-59
INSERT INTO browser_compatibility_tracking (compatibility_id, browser_name, browser_version, compatibility_level, minimum_supported_version) VALUES
('firefox_compatibility', 'Mozilla Firefox', '90+', 'full', '90'),
('edge_compatibility', 'Microsoft Edge', '88+', 'full', '88'),
('chrome_compatibility', 'Google Chrome', '90+', 'full', '90'),
('opera_compatibility', 'Opera', '76+', 'full', '76');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE vacation_scheme_types IS 'BDD Lines 15-27: Vacation scheme types with duration and period configuration';
COMMENT ON TABLE employee_vacation_entitlements IS 'Employee vacation entitlements calculated from schemes with usage tracking';
COMMENT ON TABLE system_localization IS 'BDD Lines 29-48: Multi-language interface support with Russian and English';
COMMENT ON TABLE user_language_preferences IS 'BDD Lines 44-48: User language preferences with persistence configuration';
COMMENT ON TABLE browser_compatibility_tracking IS 'BDD Lines 50-66: Multi-browser compatibility tracking and testing';
COMMENT ON TABLE event_regularity_patterns IS 'BDD Lines 68-88: Event regularity configuration with recurrence patterns';
COMMENT ON TABLE weekday_configuration IS 'BDD Lines 90-107: Weekday selection configuration with business day validation';
COMMENT ON TABLE event_type_configuration IS 'BDD Lines 109-128: Event type configuration with type-specific fields';
COMMENT ON TABLE employee_scheme_assignments IS 'Employee vacation scheme assignments with transition management';