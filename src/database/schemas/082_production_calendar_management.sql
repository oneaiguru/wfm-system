-- Schema 082: Production Calendar Management (BDD 28)
-- Russian Federation production calendar with XML import support
-- Holiday management and vacation planning integration

-- 1. Production Calendar Years
CREATE TABLE production_calendar_years (
    calendar_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_year INTEGER NOT NULL UNIQUE,
    country_code VARCHAR(2) DEFAULT 'RU',
    region_code VARCHAR(10), -- For regional calendars
    total_days INTEGER NOT NULL DEFAULT 365,
    working_days INTEGER NOT NULL,
    holidays INTEGER NOT NULL,
    weekends INTEGER NOT NULL,
    pre_holidays INTEGER NOT NULL,
    import_source VARCHAR(50), -- xml, manual, api
    import_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_year CHECK (calendar_year BETWEEN 2020 AND 2030)
);

-- 2. Calendar Days Detail
CREATE TABLE production_calendar_days (
    day_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_id UUID REFERENCES production_calendar_years(calendar_id),
    calendar_date DATE NOT NULL,
    day_type VARCHAR(20) NOT NULL, -- working, holiday, weekend, pre_holiday
    day_name VARCHAR(100), -- Monday, Tuesday, etc.
    day_name_ru VARCHAR(100), -- Понедельник, Вторник, etc.
    is_transferred BOOLEAN DEFAULT false, -- Transferred working day
    transferred_from DATE, -- Original date if transferred
    working_hours DECIMAL(4,2) DEFAULT 8.0, -- Normal or shortened
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(calendar_id, calendar_date)
);

-- 3. Holiday Definitions
CREATE TABLE holiday_definitions (
    holiday_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_name VARCHAR(255) NOT NULL,
    holiday_name_ru VARCHAR(255) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(50) NOT NULL, -- federal, regional, religious, professional
    is_recurring BOOLEAN DEFAULT true,
    recurrence_rule VARCHAR(50), -- yearly, monthly, custom
    country_code VARCHAR(2) DEFAULT 'RU',
    region_code VARCHAR(10), -- For regional holidays
    description TEXT,
    description_ru TEXT,
    is_paid BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(holiday_name, holiday_date)
);

-- 4. Calendar Import History
CREATE TABLE calendar_import_history (
    import_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_year INTEGER NOT NULL,
    import_type VARCHAR(50), -- xml, csv, api, manual
    file_name VARCHAR(255),
    file_content TEXT, -- Store XML content for audit
    import_status VARCHAR(50), -- pending, processing, completed, failed
    records_processed INTEGER,
    records_imported INTEGER,
    validation_errors JSONB,
    imported_by VARCHAR(255),
    import_start TIMESTAMP,
    import_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Calendar Editing Audit
CREATE TABLE calendar_editing_audit (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_date DATE NOT NULL,
    old_day_type VARCHAR(20),
    new_day_type VARCHAR(20),
    change_reason TEXT,
    affected_schedules INTEGER,
    changed_by VARCHAR(255),
    change_approved_by VARCHAR(255),
    rollback_available BOOLEAN DEFAULT true,
    rollback_data JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Pre-Holiday Configuration
CREATE TABLE pre_holiday_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255),
    applies_to VARCHAR(50), -- before_holiday, before_weekend, custom
    shortened_hours DECIMAL(4,2) DEFAULT 1.0, -- Hours to reduce
    standard_hours DECIMAL(4,2) DEFAULT 8.0,
    resulting_hours DECIMAL(4,2) DEFAULT 7.0,
    applies_to_shifts JSONB, -- Which shifts are affected
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Calendar Display Settings
CREATE TABLE calendar_display_settings (
    setting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID, -- NULL for system defaults
    show_holidays BOOLEAN DEFAULT true,
    show_weekends BOOLEAN DEFAULT true,
    show_pre_holidays BOOLEAN DEFAULT true,
    color_working VARCHAR(7) DEFAULT '#90EE90', -- Light green
    color_holiday VARCHAR(7) DEFAULT '#FF6B6B', -- Red
    color_weekend VARCHAR(7) DEFAULT '#D3D3D3', -- Gray
    color_pre_holiday VARCHAR(7) DEFAULT '#FFD93D', -- Yellow
    default_view VARCHAR(20) DEFAULT 'year', -- year, month, list
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Vacation Planning Integration
CREATE TABLE vacation_calendar_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_type VARCHAR(50), -- holiday_adjacency, bridge_days, peak_season
    rule_name VARCHAR(255),
    rule_description TEXT,
    priority INTEGER DEFAULT 100,
    calculation_formula TEXT,
    applies_from DATE,
    applies_to DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Regional Calendar Variations
CREATE TABLE regional_calendar_overrides (
    override_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_id UUID REFERENCES production_calendar_years(calendar_id),
    region_code VARCHAR(10) NOT NULL,
    region_name VARCHAR(100),
    override_date DATE NOT NULL,
    original_type VARCHAR(20),
    override_type VARCHAR(20),
    override_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(calendar_id, region_code, override_date)
);

-- 10. Calendar Synchronization Status
CREATE TABLE calendar_sync_status (
    sync_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_source VARCHAR(100), -- government_api, manual_update, import_file
    sync_year INTEGER,
    last_sync_date TIMESTAMP,
    next_sync_date TIMESTAMP,
    sync_status VARCHAR(50),
    changes_detected INTEGER,
    changes_applied INTEGER,
    error_log TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert 2025 Russian holidays
INSERT INTO holiday_definitions (holiday_name, holiday_name_ru, holiday_date, holiday_type, is_recurring)
VALUES 
    ('New Year', 'Новый год', '2025-01-01', 'federal', true),
    ('Orthodox Christmas', 'Рождество Христово', '2025-01-07', 'federal', true),
    ('Defender of the Fatherland Day', 'День защитника Отечества', '2025-02-23', 'federal', true),
    ('International Women''s Day', 'Международный женский день', '2025-03-08', 'federal', true),
    ('Spring and Labour Day', 'Праздник Весны и Труда', '2025-05-01', 'federal', true),
    ('Victory Day', 'День Победы', '2025-05-09', 'federal', true),
    ('Russia Day', 'День России', '2025-06-12', 'federal', true),
    ('Unity Day', 'День народного единства', '2025-11-04', 'federal', true);

-- Insert 2025 calendar year summary
INSERT INTO production_calendar_years (calendar_year, working_days, holidays, weekends, pre_holidays)
VALUES (2025, 247, 12, 104, 4);

-- Insert pre-holiday rules
INSERT INTO pre_holiday_rules (rule_name, applies_to, shortened_hours, standard_hours, resulting_hours)
VALUES 
    ('Pre-holiday workday', 'before_holiday', 1.0, 8.0, 7.0),
    ('Friday before holiday', 'before_weekend', 1.0, 8.0, 7.0);

-- Create indexes
CREATE INDEX idx_calendar_days_date ON production_calendar_days(calendar_date);
CREATE INDEX idx_calendar_days_type ON production_calendar_days(day_type);
CREATE INDEX idx_holidays_date ON holiday_definitions(holiday_date);
CREATE INDEX idx_calendar_year ON production_calendar_years(calendar_year);

-- Verify calendar tables
SELECT COUNT(*) as calendar_tables FROM information_schema.tables 
WHERE table_name LIKE '%calendar%' OR table_name LIKE '%holiday%';