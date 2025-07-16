-- =============================================================================
-- 055_production_calendar_management.sql
-- EXACT BDD Implementation: Production Calendar Management with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 28-production-calendar-management.feature (90 lines)
-- Purpose: Production calendar management with holiday tracking and vacation integration
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. PRODUCTION CALENDAR YEARS
-- =============================================================================

-- Calendar year management from BDD lines 15-25
CREATE TABLE production_calendar_years (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL UNIQUE CHECK (year >= 2020 AND year <= 2030),
    
    -- Calendar statistics from BDD lines 38-41
    total_days INTEGER NOT NULL,
    working_days_count INTEGER NOT NULL,
    holidays_count INTEGER NOT NULL,
    pre_holidays_count INTEGER NOT NULL,
    weekends_count INTEGER NOT NULL,
    
    -- Import metadata from BDD lines 12-31
    imported_from_xml BOOLEAN DEFAULT false,
    xml_source_file VARCHAR(500),
    xml_import_date TIMESTAMP WITH TIME ZONE,
    xml_validation_status VARCHAR(20) DEFAULT 'pending' CHECK (xml_validation_status IN (
        'pending', 'valid', 'invalid', 'warning'
    )),
    xml_validation_errors JSONB DEFAULT '[]',
    
    -- Calendar status
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    
    -- Version control
    calendar_version VARCHAR(20) DEFAULT '1.0',
    last_modified_by UUID,
    modification_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. PRODUCTION CALENDAR DAYS
-- =============================================================================

-- Individual calendar days from BDD lines 36-46
CREATE TABLE production_calendar_days (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_year INTEGER NOT NULL,
    calendar_date DATE NOT NULL,
    
    -- Day type from BDD lines 38-41 and 51-58
    day_type VARCHAR(20) NOT NULL CHECK (day_type IN (
        'working', 'holiday', 'pre_holiday', 'weekend'
    )),
    original_day_type VARCHAR(20), -- Before any manual edits
    
    -- Day metadata
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
    week_of_year INTEGER NOT NULL CHECK (week_of_year >= 1 AND week_of_year <= 53),
    month_of_year INTEGER NOT NULL CHECK (month_of_year >= 1 AND month_of_year <= 12),
    quarter_of_year INTEGER NOT NULL CHECK (quarter_of_year >= 1 AND quarter_of_year <= 4),
    
    -- Display configuration from BDD lines 42-46
    display_color VARCHAR(10) DEFAULT '#ffffff',
    is_visible BOOLEAN DEFAULT true,
    display_priority INTEGER DEFAULT 1,
    
    -- Edit tracking from BDD lines 51-58
    is_manually_edited BOOLEAN DEFAULT false,
    edited_by UUID,
    edited_at TIMESTAMP WITH TIME ZONE,
    edit_reason TEXT,
    schedules_affected_count INTEGER DEFAULT 0,
    change_confirmed BOOLEAN DEFAULT false,
    
    -- Holiday-specific fields
    holiday_id UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE,
    FOREIGN KEY (edited_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (holiday_id) REFERENCES holiday_events(id) ON DELETE SET NULL,
    
    UNIQUE(calendar_year, calendar_date)
);

-- =============================================================================
-- 3. HOLIDAY EVENTS
-- =============================================================================

-- Holiday event specification from BDD lines 61-74
CREATE TABLE holiday_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_id VARCHAR(50) NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    
    -- Holiday details from BDD lines 65-69
    holiday_name VARCHAR(200) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(20) NOT NULL CHECK (holiday_type IN ('federal', 'regional', 'local', 'custom')),
    description TEXT,
    
    -- Holiday metadata
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern JSONB DEFAULT '{}',
    observance_rules JSONB DEFAULT '{}',
    
    -- Regional configuration
    applies_to_regions JSONB DEFAULT '[]',
    applies_to_locations JSONB DEFAULT '[]',
    
    -- Holiday impact
    affects_vacation_planning BOOLEAN DEFAULT true,
    extends_vacation_periods BOOLEAN DEFAULT true,
    requires_schedule_adjustment BOOLEAN DEFAULT true,
    
    -- Status and validation
    is_active BOOLEAN DEFAULT true,
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN ('valid', 'invalid', 'pending')),
    validation_errors JSONB DEFAULT '[]',
    
    -- Version control
    created_by UUID,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Validation constraints from BDD lines 71-74
    UNIQUE(calendar_year, holiday_name),
    CHECK (holiday_date >= (calendar_year || '-01-01')::DATE),
    CHECK (holiday_date <= (calendar_year || '-12-31')::DATE)
);

-- =============================================================================
-- 4. CALENDAR DISPLAY CONFIGURATION
-- =============================================================================

-- Display options from BDD lines 42-46
CREATE TABLE calendar_display_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID,
    calendar_year INTEGER,
    
    -- Toggle options from BDD lines 43-46
    show_holidays BOOLEAN DEFAULT true,
    show_weekends BOOLEAN DEFAULT true,
    show_pre_holidays BOOLEAN DEFAULT true,
    show_working_days BOOLEAN DEFAULT true,
    
    -- Display formatting
    holiday_color VARCHAR(10) DEFAULT '#ff4444',
    weekend_color VARCHAR(10) DEFAULT '#cccccc',
    pre_holiday_color VARCHAR(10) DEFAULT '#ffcc00',
    working_day_color VARCHAR(10) DEFAULT '#44ff44',
    
    -- View preferences
    default_view VARCHAR(20) DEFAULT 'month' CHECK (default_view IN ('day', 'week', 'month', 'year')),
    highlight_today BOOLEAN DEFAULT true,
    show_week_numbers BOOLEAN DEFAULT false,
    first_day_of_week INTEGER DEFAULT 1 CHECK (first_day_of_week >= 1 AND first_day_of_week <= 7),
    
    -- Language and locale
    locale VARCHAR(10) DEFAULT 'ru_RU',
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    date_format VARCHAR(20) DEFAULT 'dd.MM.yyyy',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE
);

-- =============================================================================
-- 5. VACATION PLANNING INTEGRATION
-- =============================================================================

-- Vacation planning integration from BDD lines 77-89
CREATE TABLE vacation_calendar_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(200) NOT NULL,
    
    -- Calendar factors from BDD lines 81-84
    calendar_factor VARCHAR(30) NOT NULL CHECK (calendar_factor IN (
        'holidays', 'pre_holidays', 'weekends', 'working_days'
    )),
    impact_type VARCHAR(30) NOT NULL CHECK (impact_type IN (
        'extend_vacation', 'shorten_workday', 'skip_counting', 'adjust_calculation'
    )),
    behavior_description TEXT NOT NULL,
    
    -- Extension rules from BDD lines 86-89
    rule_conditions JSONB NOT NULL,
    rule_actions JSONB NOT NULL,
    auto_apply BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT false,
    
    -- Rule configuration
    priority INTEGER DEFAULT 1,
    is_mandatory BOOLEAN DEFAULT true,
    applies_to_regions JSONB DEFAULT '[]',
    applies_to_employee_types JSONB DEFAULT '[]',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. CALENDAR IMPORT HISTORY
-- =============================================================================

-- XML import tracking from BDD lines 12-31
CREATE TABLE calendar_import_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    import_id VARCHAR(50) NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    
    -- Import source
    source_type VARCHAR(30) DEFAULT 'xml' CHECK (source_type IN ('xml', 'manual', 'api', 'system')),
    source_file_name VARCHAR(500),
    source_file_path VARCHAR(1000),
    source_file_size_bytes BIGINT,
    
    -- Import processing from BDD lines 15-25
    import_status VARCHAR(20) DEFAULT 'pending' CHECK (import_status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled'
    )),
    import_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    import_end_time TIMESTAMP WITH TIME ZONE,
    import_duration_seconds INTEGER,
    
    -- Processing results
    total_days_processed INTEGER,
    working_days_imported INTEGER,
    holidays_imported INTEGER,
    pre_holidays_imported INTEGER,
    weekends_generated INTEGER,
    
    -- Validation results from BDD lines 21-30
    validation_errors JSONB DEFAULT '[]',
    validation_warnings JSONB DEFAULT '[]',
    edge_cases_handled JSONB DEFAULT '[]',
    duplicate_dates_merged INTEGER DEFAULT 0,
    missing_weekends_added INTEGER DEFAULT 0,
    
    -- Import metadata
    imported_by UUID NOT NULL,
    import_reason TEXT,
    backup_created BOOLEAN DEFAULT false,
    rollback_available BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE,
    FOREIGN KEY (imported_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 7. CALENDAR VALIDATION RULES
-- =============================================================================

-- Validation rules from BDD lines 21-30
CREATE TABLE calendar_validation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(200) NOT NULL,
    
    -- Validation configuration from BDD lines 22-25
    validation_type VARCHAR(30) NOT NULL CHECK (validation_type IN (
        'date_format', 'year_range', 'holiday_names', 'duplicate_dates', 'data_consistency'
    )),
    validation_rule TEXT NOT NULL,
    error_message_template TEXT NOT NULL,
    
    -- Rule parameters
    rule_parameters JSONB DEFAULT '{}',
    severity VARCHAR(20) DEFAULT 'error' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    is_blocking BOOLEAN DEFAULT true,
    
    -- Rule scope
    applies_to_import BOOLEAN DEFAULT true,
    applies_to_manual_edit BOOLEAN DEFAULT true,
    applies_to_api BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. SCHEDULE IMPACT TRACKING
-- =============================================================================

-- Schedule impact from BDD lines 54-57
CREATE TABLE calendar_schedule_impact (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    impact_id VARCHAR(50) NOT NULL UNIQUE,
    calendar_date DATE NOT NULL,
    calendar_year INTEGER NOT NULL,
    
    -- Change details
    old_day_type VARCHAR(20) NOT NULL,
    new_day_type VARCHAR(20) NOT NULL,
    change_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by UUID NOT NULL,
    
    -- Impact assessment from BDD lines 55-57
    affected_schedules_count INTEGER DEFAULT 0,
    affected_employees_count INTEGER DEFAULT 0,
    affected_departments_count INTEGER DEFAULT 0,
    
    -- Impact details
    schedule_adjustments_required JSONB DEFAULT '[]',
    vacation_periods_affected JSONB DEFAULT '[]',
    shift_patterns_affected JSONB DEFAULT '[]',
    
    -- Change management
    impact_assessment_completed BOOLEAN DEFAULT false,
    user_confirmation_required BOOLEAN DEFAULT true,
    user_confirmed BOOLEAN DEFAULT false,
    confirmation_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Rollback capability from BDD line 57
    rollback_available BOOLEAN DEFAULT true,
    rollback_data JSONB,
    rollback_executed BOOLEAN DEFAULT false,
    rollback_timestamp TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 9. REGIONAL CALENDAR VARIATIONS
-- =============================================================================

-- Regional calendar support
CREATE TABLE regional_calendar_variations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    variation_id VARCHAR(50) NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    
    -- Regional identification
    region_code VARCHAR(10) NOT NULL,
    region_name VARCHAR(200) NOT NULL,
    country_code VARCHAR(3) DEFAULT 'RU',
    
    -- Regional holidays
    additional_holidays JSONB DEFAULT '[]',
    excluded_holidays JSONB DEFAULT '[]',
    modified_holidays JSONB DEFAULT '[]',
    
    -- Regional rules
    working_hours_per_day DECIMAL(3,1) DEFAULT 8.0,
    pre_holiday_hours_reduction DECIMAL(3,1) DEFAULT 1.0,
    weekend_work_allowed BOOLEAN DEFAULT false,
    
    -- Regional metadata
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    locale VARCHAR(10) DEFAULT 'ru_RU',
    first_day_of_week INTEGER DEFAULT 1,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (calendar_year) REFERENCES production_calendar_years(year) ON DELETE CASCADE,
    
    UNIQUE(calendar_year, region_code)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Calendar year queries
CREATE INDEX idx_production_calendar_years_active ON production_calendar_years(is_active) WHERE is_active = true;
CREATE INDEX idx_production_calendar_years_default ON production_calendar_years(is_default) WHERE is_default = true;
CREATE INDEX idx_production_calendar_years_year ON production_calendar_years(year);

-- Calendar day queries
CREATE INDEX idx_production_calendar_days_year ON production_calendar_days(calendar_year);
CREATE INDEX idx_production_calendar_days_date ON production_calendar_days(calendar_date);
CREATE INDEX idx_production_calendar_days_type ON production_calendar_days(day_type);
CREATE INDEX idx_production_calendar_days_month ON production_calendar_days(calendar_year, month_of_year);
CREATE INDEX idx_production_calendar_days_quarter ON production_calendar_days(calendar_year, quarter_of_year);
CREATE INDEX idx_production_calendar_days_edited ON production_calendar_days(is_manually_edited) WHERE is_manually_edited = true;

-- Holiday event queries
CREATE INDEX idx_holiday_events_year ON holiday_events(calendar_year);
CREATE INDEX idx_holiday_events_date ON holiday_events(holiday_date);
CREATE INDEX idx_holiday_events_type ON holiday_events(holiday_type);
CREATE INDEX idx_holiday_events_active ON holiday_events(is_active) WHERE is_active = true;
CREATE INDEX idx_holiday_events_name ON holiday_events(calendar_year, holiday_name);

-- Display configuration queries
CREATE INDEX idx_calendar_display_config_user ON calendar_display_config(user_id);
CREATE INDEX idx_calendar_display_config_year ON calendar_display_config(calendar_year);
CREATE INDEX idx_calendar_display_config_active ON calendar_display_config(is_active) WHERE is_active = true;

-- Vacation rule queries
CREATE INDEX idx_vacation_calendar_rules_factor ON vacation_calendar_rules(calendar_factor);
CREATE INDEX idx_vacation_calendar_rules_active ON vacation_calendar_rules(is_active) WHERE is_active = true;
CREATE INDEX idx_vacation_calendar_rules_priority ON vacation_calendar_rules(priority);

-- Import history queries
CREATE INDEX idx_calendar_import_history_year ON calendar_import_history(calendar_year);
CREATE INDEX idx_calendar_import_history_status ON calendar_import_history(import_status);
CREATE INDEX idx_calendar_import_history_date ON calendar_import_history(import_start_time);
CREATE INDEX idx_calendar_import_history_user ON calendar_import_history(imported_by);

-- Validation rule queries
CREATE INDEX idx_calendar_validation_rules_type ON calendar_validation_rules(validation_type);
CREATE INDEX idx_calendar_validation_rules_active ON calendar_validation_rules(is_active) WHERE is_active = true;
CREATE INDEX idx_calendar_validation_rules_severity ON calendar_validation_rules(severity);

-- Impact tracking queries
CREATE INDEX idx_calendar_schedule_impact_date ON calendar_schedule_impact(calendar_date);
CREATE INDEX idx_calendar_schedule_impact_year ON calendar_schedule_impact(calendar_year);
CREATE INDEX idx_calendar_schedule_impact_user ON calendar_schedule_impact(changed_by);
CREATE INDEX idx_calendar_schedule_impact_confirmed ON calendar_schedule_impact(user_confirmed);

-- Regional variation queries
CREATE INDEX idx_regional_calendar_variations_year ON regional_calendar_variations(calendar_year);
CREATE INDEX idx_regional_calendar_variations_region ON regional_calendar_variations(region_code);
CREATE INDEX idx_regional_calendar_variations_active ON regional_calendar_variations(is_active) WHERE is_active = true;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_calendar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER production_calendar_years_update_trigger
    BEFORE UPDATE ON production_calendar_years
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER production_calendar_days_update_trigger
    BEFORE UPDATE ON production_calendar_days
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER holiday_events_update_trigger
    BEFORE UPDATE ON holiday_events
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER calendar_display_config_update_trigger
    BEFORE UPDATE ON calendar_display_config
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER vacation_calendar_rules_update_trigger
    BEFORE UPDATE ON vacation_calendar_rules
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER calendar_validation_rules_update_trigger
    BEFORE UPDATE ON calendar_validation_rules
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

CREATE TRIGGER regional_calendar_variations_update_trigger
    BEFORE UPDATE ON regional_calendar_variations
    FOR EACH ROW EXECUTE FUNCTION update_calendar_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active calendar with statistics
CREATE VIEW v_active_production_calendar AS
SELECT 
    pcy.year,
    pcy.working_days_count,
    pcy.holidays_count,
    pcy.pre_holidays_count,
    pcy.weekends_count,
    pcy.total_days,
    pcy.imported_from_xml,
    pcy.xml_import_date,
    pcy.calendar_version
FROM production_calendar_years pcy
WHERE pcy.is_active = true
ORDER BY pcy.year DESC;

-- Holiday calendar view
CREATE VIEW v_holiday_calendar AS
SELECT 
    he.calendar_year,
    he.holiday_date,
    he.holiday_name,
    he.holiday_type,
    he.description,
    pcd.day_type,
    pcd.display_color
FROM holiday_events he
JOIN production_calendar_days pcd ON he.holiday_date = pcd.calendar_date
WHERE he.is_active = true
  AND pcd.calendar_year = he.calendar_year
ORDER BY he.holiday_date;

-- Vacation planning calendar view
CREATE VIEW v_vacation_planning_calendar AS
SELECT 
    pcd.calendar_date,
    pcd.day_type,
    pcd.calendar_year,
    he.holiday_name,
    he.holiday_type,
    CASE 
        WHEN pcd.day_type = 'holiday' THEN 'extends_vacation'
        WHEN pcd.day_type = 'pre_holiday' THEN 'shortens_workday'
        WHEN pcd.day_type = 'weekend' THEN 'skip_counting'
        ELSE 'normal'
    END as vacation_impact
FROM production_calendar_days pcd
LEFT JOIN holiday_events he ON pcd.holiday_id = he.id
WHERE pcd.calendar_year >= EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY pcd.calendar_date;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert 2025 calendar year
INSERT INTO production_calendar_years (year, total_days, working_days_count, holidays_count, pre_holidays_count, weekends_count) 
VALUES (2025, 365, 247, 12, 4, 104);

-- Insert sample validation rules
INSERT INTO calendar_validation_rules (rule_id, rule_name, validation_type, validation_rule, error_message_template) VALUES
('date_format_iso', 'ISO 8601 Date Format', 'date_format', 'YYYY-MM-DD format required', 'Invalid date format'),
('year_range_2020_2030', 'Year Range Validation', 'year_range', 'Year must be between 2020 and 2030', 'Year out of range'),
('russian_holiday_names', 'Russian Holiday Names', 'holiday_names', 'Holiday names must be in Russian', 'Invalid holiday name');

-- Insert sample vacation rules
INSERT INTO vacation_calendar_rules (rule_id, rule_name, calendar_factor, impact_type, behavior_description, rule_conditions, rule_actions) VALUES
('holiday_extension', 'Holiday Vacation Extension', 'holidays', 'extend_vacation', 'Auto-extend periods', '{"vacation_includes_holiday": true}', '{"extend_by_days": 1}'),
('weekend_bridge', 'Weekend Bridge Rule', 'weekends', 'extend_vacation', 'Fill gap automatically', '{"holiday_weekend_gap": true}', '{"fill_gap": true}'),
('pre_holiday_inclusion', 'Pre-holiday Inclusion', 'pre_holidays', 'extend_vacation', 'Include in vacation', '{"vacation_starts_pre_holiday": true}', '{"include_in_vacation": true}');

-- Insert sample holidays for 2025
INSERT INTO holiday_events (holiday_id, calendar_year, holiday_name, holiday_date, holiday_type, description) VALUES
('new_year_2025', 2025, 'Новый год', '2025-01-01', 'federal', 'New Year Day'),
('orthodox_christmas_2025', 2025, 'Рождество Христово', '2025-01-07', 'federal', 'Orthodox Christmas'),
('defender_day_2025', 2025, 'День защитника Отечества', '2025-02-23', 'federal', 'Defender of the Fatherland Day'),
('womens_day_2025', 2025, 'Международный женский день', '2025-03-08', 'federal', 'International Women''s Day'),
('labor_day_2025', 2025, 'Праздник Весны и Труда', '2025-05-01', 'federal', 'Labor Day'),
('victory_day_2025', 2025, 'День Победы', '2025-05-09', 'federal', 'Victory Day');

-- Insert sample display configuration
INSERT INTO calendar_display_config (config_id, calendar_year, show_holidays, show_weekends, show_pre_holidays) VALUES
('default_2025', 2025, true, true, true);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE production_calendar_years IS 'BDD Lines 15-25: Production calendar year management with XML import validation';
COMMENT ON TABLE production_calendar_days IS 'BDD Lines 36-58: Individual calendar days with type management and edit tracking';
COMMENT ON TABLE holiday_events IS 'BDD Lines 61-74: Holiday event specification with validation and regional support';
COMMENT ON TABLE calendar_display_config IS 'BDD Lines 42-46: Calendar display configuration with toggle options';
COMMENT ON TABLE vacation_calendar_rules IS 'BDD Lines 77-89: Vacation planning integration with calendar factors';
COMMENT ON TABLE calendar_import_history IS 'BDD Lines 12-31: XML import tracking with validation and edge case handling';
COMMENT ON TABLE calendar_validation_rules IS 'BDD Lines 21-30: Validation rules for import and edit operations';
COMMENT ON TABLE calendar_schedule_impact IS 'BDD Lines 54-57: Schedule impact tracking with confirmation and rollback';
COMMENT ON TABLE regional_calendar_variations IS 'Regional calendar support for different Russian regions';