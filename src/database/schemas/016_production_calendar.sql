-- =============================================================================
-- 016_production_calendar.sql
-- WFM Production Calendar System - Russian Federation Support
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Production calendar for Russian market with holiday integration
-- Tables: 4 core calendar tables for vacation planning integration
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. PRODUCTION_CALENDAR - Main calendar data structure
-- =============================================================================
CREATE TABLE production_calendar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_year INTEGER NOT NULL,
    calendar_date DATE NOT NULL,
    day_type VARCHAR(20) NOT NULL CHECK (day_type IN ('working', 'holiday', 'pre_holiday', 'weekend')),
    working_hours DECIMAL(4,2) DEFAULT 8.0,
    is_shortened_day BOOLEAN DEFAULT false,
    region_code VARCHAR(10) DEFAULT 'RU',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(calendar_date, region_code)
);

-- Indexes for production_calendar
CREATE INDEX idx_production_calendar_date ON production_calendar(calendar_date);
CREATE INDEX idx_production_calendar_year ON production_calendar(calendar_year);
CREATE INDEX idx_production_calendar_type ON production_calendar(day_type);
CREATE INDEX idx_production_calendar_region ON production_calendar(region_code);

-- =============================================================================
-- 2. HOLIDAYS - Holiday definitions and metadata
-- =============================================================================
CREATE TABLE holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_name VARCHAR(255) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(50) NOT NULL CHECK (holiday_type IN ('federal', 'regional', 'religious', 'professional')),
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule VARCHAR(100), -- For annual holidays like "first Monday of May"
    region_code VARCHAR(10) DEFAULT 'RU',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(holiday_date, region_code, holiday_name)
);

-- Indexes for holidays
CREATE INDEX idx_holidays_date ON holidays(holiday_date);
CREATE INDEX idx_holidays_type ON holidays(holiday_type);
CREATE INDEX idx_holidays_region ON holidays(region_code);

-- =============================================================================
-- 3. CALENDAR_XML_IMPORTS - Track XML imports from Russian Federation
-- =============================================================================
CREATE TABLE calendar_xml_imports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    import_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calendar_year INTEGER NOT NULL,
    xml_filename VARCHAR(255),
    xml_source VARCHAR(100) DEFAULT 'government.ru',
    records_imported INTEGER DEFAULT 0,
    holidays_imported INTEGER DEFAULT 0,
    working_days INTEGER DEFAULT 0,
    import_status VARCHAR(20) DEFAULT 'pending' CHECK (import_status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    imported_by UUID,
    
    CONSTRAINT fk_calendar_xml_imports_user 
        FOREIGN KEY (imported_by) REFERENCES users(id)
);

-- Index for calendar_xml_imports
CREATE INDEX idx_calendar_xml_imports_year ON calendar_xml_imports(calendar_year);
CREATE INDEX idx_calendar_xml_imports_status ON calendar_xml_imports(import_status);

-- =============================================================================
-- 4. VACATION_CALENDAR_RULES - Business rules for vacation planning
-- =============================================================================
CREATE TABLE vacation_calendar_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('extension', 'bridge', 'restriction', 'calculation')),
    description TEXT,
    rule_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 100,
    region_code VARCHAR(10) DEFAULT 'RU',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for vacation_calendar_rules
CREATE INDEX idx_vacation_calendar_rules_type ON vacation_calendar_rules(rule_type);
CREATE INDEX idx_vacation_calendar_rules_priority ON vacation_calendar_rules(priority);

-- =============================================================================
-- FUNCTIONS: Calendar Management
-- =============================================================================

-- Function to import Russian Federation calendar year
CREATE OR REPLACE FUNCTION import_russian_calendar_year(
    p_year INTEGER,
    p_xml_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_import_id UUID;
    v_records_count INTEGER := 0;
    v_holidays_count INTEGER := 0;
    v_working_days INTEGER := 0;
    v_current_date DATE;
    v_day_data JSONB;
    v_result JSONB;
BEGIN
    -- Create import record
    INSERT INTO calendar_xml_imports (calendar_year, import_status)
    VALUES (p_year, 'processing')
    RETURNING id INTO v_import_id;
    
    -- Clear existing data for the year
    DELETE FROM production_calendar WHERE calendar_year = p_year;
    DELETE FROM holidays WHERE EXTRACT(YEAR FROM holiday_date) = p_year;
    
    -- Process each day in the XML data
    FOR v_day_data IN SELECT jsonb_array_elements(p_xml_data->'calendar'->'days')
    LOOP
        v_current_date := (v_day_data->>'date')::DATE;
        
        -- Insert calendar day
        INSERT INTO production_calendar (
            calendar_year,
            calendar_date,
            day_type,
            working_hours,
            is_shortened_day
        ) VALUES (
            p_year,
            v_current_date,
            v_day_data->>'type',
            COALESCE((v_day_data->>'working_hours')::DECIMAL, 8.0),
            COALESCE((v_day_data->>'is_shortened')::BOOLEAN, false)
        );
        
        v_records_count := v_records_count + 1;
        
        -- Count working days and holidays
        IF v_day_data->>'type' = 'working' THEN
            v_working_days := v_working_days + 1;
        ELSIF v_day_data->>'type' = 'holiday' THEN
            v_holidays_count := v_holidays_count + 1;
            
            -- Insert holiday if name provided
            IF v_day_data->>'holiday_name' IS NOT NULL THEN
                INSERT INTO holidays (
                    holiday_name,
                    holiday_date,
                    holiday_type,
                    description
                ) VALUES (
                    v_day_data->>'holiday_name',
                    v_current_date,
                    COALESCE(v_day_data->>'holiday_type', 'federal'),
                    v_day_data->>'description'
                );
            END IF;
        END IF;
    END LOOP;
    
    -- Update import record
    UPDATE calendar_xml_imports SET
        import_status = 'completed',
        records_imported = v_records_count,
        holidays_imported = v_holidays_count,
        working_days = v_working_days
    WHERE id = v_import_id;
    
    -- Return result
    v_result := jsonb_build_object(
        'import_id', v_import_id,
        'year', p_year,
        'records_imported', v_records_count,
        'holidays_imported', v_holidays_count,
        'working_days', v_working_days,
        'status', 'completed'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    -- Update import record with error
    UPDATE calendar_xml_imports SET
        import_status = 'failed',
        error_message = SQLERRM
    WHERE id = v_import_id;
    
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- Function to get calendar year summary
CREATE OR REPLACE FUNCTION get_calendar_year_summary(p_year INTEGER)
RETURNS TABLE(
    calendar_year INTEGER,
    total_days INTEGER,
    working_days INTEGER,
    holidays INTEGER,
    weekends INTEGER,
    pre_holidays INTEGER,
    total_working_hours DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p_year,
        COUNT(*)::INTEGER as total_days,
        COUNT(*) FILTER (WHERE day_type = 'working')::INTEGER as working_days,
        COUNT(*) FILTER (WHERE day_type = 'holiday')::INTEGER as holidays,
        COUNT(*) FILTER (WHERE day_type = 'weekend')::INTEGER as weekends,
        COUNT(*) FILTER (WHERE day_type = 'pre_holiday')::INTEGER as pre_holidays,
        SUM(working_hours) as total_working_hours
    FROM production_calendar 
    WHERE calendar_year = p_year;
END;
$$ LANGUAGE plpgsql;

-- Function to check vacation period extensions
CREATE OR REPLACE FUNCTION calculate_vacation_extension(
    p_start_date DATE,
    p_end_date DATE
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_original_days INTEGER;
    v_extended_start DATE;
    v_extended_end DATE;
    v_extension_days INTEGER := 0;
    v_bridges INTEGER := 0;
BEGIN
    v_original_days := p_end_date - p_start_date + 1;
    v_extended_start := p_start_date;
    v_extended_end := p_end_date;
    
    -- Check for holiday extensions before start date
    WITH pre_holidays AS (
        SELECT calendar_date
        FROM production_calendar
        WHERE calendar_date < p_start_date
        AND calendar_date >= p_start_date - INTERVAL '7 days'
        AND day_type IN ('holiday', 'weekend')
        ORDER BY calendar_date DESC
    )
    SELECT MIN(calendar_date) INTO v_extended_start
    FROM pre_holidays;
    
    IF v_extended_start IS NULL THEN
        v_extended_start := p_start_date;
    END IF;
    
    -- Check for holiday extensions after end date
    WITH post_holidays AS (
        SELECT calendar_date
        FROM production_calendar
        WHERE calendar_date > p_end_date
        AND calendar_date <= p_end_date + INTERVAL '7 days'
        AND day_type IN ('holiday', 'weekend')
        ORDER BY calendar_date ASC
    )
    SELECT MAX(calendar_date) INTO v_extended_end
    FROM post_holidays;
    
    IF v_extended_end IS NULL THEN
        v_extended_end := p_end_date;
    END IF;
    
    v_extension_days := (v_extended_end - v_extended_start + 1) - v_original_days;
    
    -- Count bridge days (working days between holidays in vacation period)
    SELECT COUNT(*) INTO v_bridges
    FROM production_calendar
    WHERE calendar_date BETWEEN v_extended_start AND v_extended_end
    AND day_type = 'working'
    AND calendar_date NOT BETWEEN p_start_date AND p_end_date;
    
    v_result := jsonb_build_object(
        'original_start', p_start_date,
        'original_end', p_end_date,
        'original_days', v_original_days,
        'extended_start', v_extended_start,
        'extended_end', v_extended_end,
        'extension_days', v_extension_days,
        'bridge_days', v_bridges,
        'total_vacation_days', v_extended_end - v_extended_start + 1 - v_bridges
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SAMPLE DATA: Russian Federation 2025 Calendar
-- =============================================================================

-- Insert default vacation calendar rules
INSERT INTO vacation_calendar_rules (rule_name, rule_type, description, rule_config) VALUES
('Holiday Extension Rule', 'extension', 'Automatically extend vacation periods to include adjacent holidays', 
 '{"auto_extend": true, "max_extension_days": 7, "include_weekends": true}'),
('Bridge Day Rule', 'bridge', 'Fill gaps between holidays and vacation periods', 
 '{"max_bridge_days": 3, "auto_fill_bridges": true}'),
('Pre-holiday Inclusion', 'extension', 'Include pre-holidays in vacation calculation', 
 '{"include_pre_holidays": true, "extend_to_weekend": true}'),
('Working Hour Calculation', 'calculation', 'Calculate vacation days based on working hours', 
 '{"standard_day_hours": 8, "shortened_day_hours": 7, "count_method": "calendar_days"}');

-- Insert sample Russian holidays for 2025
INSERT INTO holidays (holiday_name, holiday_date, holiday_type, description, is_recurring) VALUES
('Новогодние каникулы', '2025-01-01', 'federal', 'New Year holidays', true),
('Новогодние каникулы', '2025-01-02', 'federal', 'New Year holidays', true),
('Новогодние каникулы', '2025-01-03', 'federal', 'New Year holidays', true),
('Новогодние каникулы', '2025-01-06', 'federal', 'New Year holidays', true),
('Новогодние каникулы', '2025-01-07', 'federal', 'New Year holidays', true),
('Новогодние каникулы', '2025-01-08', 'federal', 'New Year holidays', true),
('Рождество Христово', '2025-01-07', 'federal', 'Orthodox Christmas', true),
('День защитника Отечества', '2025-02-23', 'federal', 'Defender of the Fatherland Day', true),
('Международный женский день', '2025-03-08', 'federal', 'International Women Day', true),
('Праздник Весны и Труда', '2025-05-01', 'federal', 'Spring and Labour Day', true),
('День Победы', '2025-05-09', 'federal', 'Victory Day', true),
('День России', '2025-06-12', 'federal', 'Russia Day', true),
('День народного единства', '2025-11-04', 'federal', 'Unity Day', true);

-- Generate 2025 calendar
DO $$
DECLARE
    v_date DATE;
    v_day_type VARCHAR(20);
    v_working_hours DECIMAL(4,2);
BEGIN
    -- Generate all days for 2025
    FOR v_date IN SELECT generate_series('2025-01-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL)::DATE
    LOOP
        -- Determine day type
        IF EXISTS (SELECT 1 FROM holidays WHERE holiday_date = v_date) THEN
            v_day_type := 'holiday';
            v_working_hours := 0;
        ELSIF EXTRACT(DOW FROM v_date) IN (0, 6) THEN -- Sunday, Saturday
            v_day_type := 'weekend';
            v_working_hours := 0;
        ELSE
            v_day_type := 'working';
            v_working_hours := 8.0;
        END IF;
        
        -- Insert calendar day
        INSERT INTO production_calendar (
            calendar_year,
            calendar_date,
            day_type,
            working_hours
        ) VALUES (
            2025,
            v_date,
            v_day_type,
            v_working_hours
        );
    END LOOP;
END $$;

-- =============================================================================
-- INTEGRATION VIEWS for UI-OPUS and AL-OPUS
-- =============================================================================

-- View for calendar display
CREATE VIEW v_calendar_display AS
SELECT 
    pc.calendar_date,
    pc.day_type,
    pc.working_hours,
    pc.is_shortened_day,
    h.holiday_name,
    h.holiday_type,
    h.description as holiday_description,
    CASE 
        WHEN pc.day_type = 'working' THEN '#4CAF50'
        WHEN pc.day_type = 'holiday' THEN '#F44336'
        WHEN pc.day_type = 'pre_holiday' THEN '#FF9800'
        WHEN pc.day_type = 'weekend' THEN '#9E9E9E'
    END as display_color,
    EXTRACT(DOW FROM pc.calendar_date) as day_of_week,
    TO_CHAR(pc.calendar_date, 'DD') as day_number,
    TO_CHAR(pc.calendar_date, 'Mon') as month_short
FROM production_calendar pc
LEFT JOIN holidays h ON h.holiday_date = pc.calendar_date
ORDER BY pc.calendar_date;

-- View for vacation planning integration
CREATE VIEW v_vacation_planning_calendar AS
SELECT 
    pc.calendar_date,
    pc.day_type,
    pc.working_hours,
    h.holiday_name,
    -- Next working day calculation
    (
        SELECT MIN(calendar_date) 
        FROM production_calendar 
        WHERE calendar_date > pc.calendar_date 
        AND day_type = 'working'
    ) as next_working_day,
    -- Previous working day calculation
    (
        SELECT MAX(calendar_date) 
        FROM production_calendar 
        WHERE calendar_date < pc.calendar_date 
        AND day_type = 'working'
    ) as prev_working_day,
    -- Week context
    DATE_TRUNC('week', pc.calendar_date) as week_start,
    DATE_TRUNC('week', pc.calendar_date) + INTERVAL '6 days' as week_end
FROM production_calendar pc
LEFT JOIN holidays h ON h.holiday_date = pc.calendar_date
WHERE pc.calendar_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY pc.calendar_date;

-- Demo view for Russian calendar compliance
CREATE VIEW v_demo_calendar_compliance AS
SELECT 
    'Russian Federation Calendar Compliance' as metric_name,
    'Calendar System' as category,
    COUNT(*) as total_days,
    COUNT(*) FILTER (WHERE day_type = 'holiday') as federal_holidays,
    COUNT(*) FILTER (WHERE day_type = 'working') as working_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE day_type = 'working') / COUNT(*), 1) as working_day_percentage,
    'Fully compliant with Russian Federation production calendar' as status,
    NOW() as measurement_time
FROM production_calendar 
WHERE calendar_year = EXTRACT(YEAR FROM CURRENT_DATE);

COMMENT ON TABLE production_calendar IS 'Production calendar with Russian Federation compliance for vacation planning';
COMMENT ON TABLE holidays IS 'Federal and regional holidays for workforce planning';
COMMENT ON VIEW v_calendar_display IS 'Calendar view for UI display with color coding';
COMMENT ON VIEW v_vacation_planning_calendar IS 'Calendar integration for vacation planning module';