-- =============================================================================
-- 022_basic_forecasting.sql
-- BASIC FORECASTING CAPABILITY - Demo Critical Feature
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Basic forecasting to prevent looking incomplete in demo
-- Strategy: Simple but functional - shows we understand WFM fundamentals
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. FORECAST_HISTORICAL_DATA - Store imported historical data
-- =============================================================================
CREATE TABLE forecast_historical_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Data identification
    service_name VARCHAR(200) NOT NULL,
    skill_group VARCHAR(200),
    
    -- Time period (exact format from BDD Excel template)
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_end TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_duration INTEGER DEFAULT 15, -- 15, 30, or 60 minutes
    
    -- Volume metrics (from BDD Table 1 format)
    unique_incoming INTEGER NOT NULL, -- Column B: Unique calls
    non_unique_incoming INTEGER NOT NULL, -- Column C: Total calls (includes repeats)
    
    -- Performance metrics
    average_talk_time INTEGER NOT NULL, -- Column D: In seconds
    after_call_work_time INTEGER NOT NULL, -- Column E: Post-processing seconds
    average_handle_time INTEGER GENERATED ALWAYS AS (average_talk_time + after_call_work_time) STORED,
    
    -- Calculated metrics
    calls_handled INTEGER,
    service_level_percent DECIMAL(5,2),
    abandonment_rate DECIMAL(5,2),
    
    -- Import tracking
    import_date DATE DEFAULT CURRENT_DATE,
    import_source VARCHAR(50) DEFAULT 'manual', -- manual, integration, api
    import_filename VARCHAR(255),
    imported_by VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure no duplicate data
    UNIQUE(service_name, skill_group, interval_start)
);

-- Indexes for historical data
CREATE INDEX idx_forecast_historical_service ON forecast_historical_data(service_name);
CREATE INDEX idx_forecast_historical_interval ON forecast_historical_data(interval_start);
CREATE INDEX idx_forecast_historical_date ON forecast_historical_data(DATE(interval_start));

-- =============================================================================
-- 2. FORECAST_PATTERNS - Store calculated patterns for forecasting
-- =============================================================================
CREATE TABLE forecast_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Pattern identification
    service_name VARCHAR(200) NOT NULL,
    skill_group VARCHAR(200),
    pattern_type VARCHAR(50) NOT NULL, -- daily, weekly, monthly, seasonal
    
    -- Time pattern
    day_of_week INTEGER, -- 0=Sunday, 6=Saturday
    hour_of_day INTEGER, -- 0-23
    week_of_month INTEGER, -- 1-5
    month_of_year INTEGER, -- 1-12
    
    -- Pattern metrics (averages)
    avg_volume DECIMAL(10,2) NOT NULL,
    avg_handle_time INTEGER NOT NULL,
    volume_std_dev DECIMAL(10,2),
    
    -- Pattern strength
    sample_size INTEGER NOT NULL, -- How many data points
    confidence_level DECIMAL(5,2), -- Statistical confidence
    last_updated DATE DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(service_name, skill_group, pattern_type, day_of_week, hour_of_day)
);

-- Indexes for patterns
CREATE INDEX idx_forecast_patterns_service ON forecast_patterns(service_name);
CREATE INDEX idx_forecast_patterns_type ON forecast_patterns(pattern_type);

-- =============================================================================
-- 3. FORECAST_CALCULATIONS - Store forecast results
-- =============================================================================
CREATE TABLE forecast_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Forecast identification
    forecast_name VARCHAR(200) NOT NULL,
    service_name VARCHAR(200) NOT NULL,
    skill_group VARCHAR(200),
    
    -- Forecast period
    forecast_start_date DATE NOT NULL,
    forecast_end_date DATE NOT NULL,
    interval_minutes INTEGER DEFAULT 30,
    
    -- Forecast parameters
    forecast_method VARCHAR(50) DEFAULT 'moving_average', -- moving_average, weekly_pattern, growth_trend
    lookback_days INTEGER DEFAULT 28, -- How much history to use
    growth_factor DECIMAL(5,2) DEFAULT 1.0, -- Growth multiplier
    
    -- Forecast results (aggregated)
    total_forecast_volume INTEGER,
    peak_hour_volume INTEGER,
    avg_daily_volume DECIMAL(10,2),
    
    -- Staffing calculations
    target_service_level DECIMAL(5,2) DEFAULT 80.0, -- 80/20 standard
    target_answer_time INTEGER DEFAULT 20, -- seconds
    
    -- Metadata
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved BOOLEAN DEFAULT false,
    approved_by VARCHAR(100),
    approved_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for calculations
CREATE INDEX idx_forecast_calculations_service ON forecast_calculations(service_name);
CREATE INDEX idx_forecast_calculations_dates ON forecast_calculations(forecast_start_date, forecast_end_date);

-- =============================================================================
-- 4. FORECAST_INTERVALS - Detailed interval-level forecast
-- =============================================================================
CREATE TABLE forecast_intervals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_id UUID NOT NULL,
    
    -- Time interval
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Forecast values
    forecast_volume DECIMAL(10,2) NOT NULL,
    forecast_aht INTEGER NOT NULL, -- seconds
    
    -- Required staffing calculation
    required_agents DECIMAL(10,2) NOT NULL,
    shrinkage_factor DECIMAL(5,2) DEFAULT 1.15, -- 15% shrinkage
    scheduled_agents DECIMAL(10,2) GENERATED ALWAYS AS (required_agents * shrinkage_factor) STORED,
    
    -- Confidence
    confidence_level DECIMAL(5,2) DEFAULT 85.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_forecast_intervals_forecast 
        FOREIGN KEY (forecast_id) REFERENCES forecast_calculations(id) ON DELETE CASCADE,
    
    UNIQUE(forecast_id, interval_start)
);

-- Indexes for intervals
CREATE INDEX idx_forecast_intervals_forecast ON forecast_intervals(forecast_id);
CREATE INDEX idx_forecast_intervals_time ON forecast_intervals(interval_start);

-- =============================================================================
-- FUNCTIONS: Basic Forecasting Logic
-- =============================================================================

-- Function to import historical data from Excel format (BDD Table 1)
CREATE OR REPLACE FUNCTION import_forecast_historical_data(
    p_service_name VARCHAR(200),
    p_data JSONB,
    p_imported_by VARCHAR(100) DEFAULT 'system'
) RETURNS JSONB AS $$
DECLARE
    v_row JSONB;
    v_imported INTEGER := 0;
    v_errors INTEGER := 0;
    v_result JSONB;
BEGIN
    -- Process each row from Excel import
    FOR v_row IN SELECT jsonb_array_elements(p_data)
    LOOP
        BEGIN
            INSERT INTO forecast_historical_data (
                service_name,
                interval_start,
                interval_end,
                unique_incoming,
                non_unique_incoming,
                average_talk_time,
                after_call_work_time,
                import_source,
                imported_by
            ) VALUES (
                p_service_name,
                (v_row->>'start_time')::TIMESTAMP WITH TIME ZONE,
                (v_row->>'start_time')::TIMESTAMP WITH TIME ZONE + INTERVAL '30 minutes',
                (v_row->>'unique_incoming')::INTEGER,
                (v_row->>'non_unique_incoming')::INTEGER,
                (v_row->>'average_talk_time')::INTEGER,
                (v_row->>'post_processing')::INTEGER,
                'excel_import',
                p_imported_by
            ) ON CONFLICT (service_name, skill_group, interval_start) 
            DO UPDATE SET
                unique_incoming = EXCLUDED.unique_incoming,
                non_unique_incoming = EXCLUDED.non_unique_incoming,
                average_talk_time = EXCLUDED.average_talk_time,
                after_call_work_time = EXCLUDED.after_call_work_time;
            
            v_imported := v_imported + 1;
        EXCEPTION WHEN OTHERS THEN
            v_errors := v_errors + 1;
        END;
    END LOOP;
    
    -- Calculate patterns after import
    PERFORM calculate_forecast_patterns(p_service_name);
    
    v_result := jsonb_build_object(
        'service', p_service_name,
        'rows_imported', v_imported,
        'errors', v_errors,
        'status', CASE WHEN v_errors = 0 THEN 'success' ELSE 'partial' END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate patterns from historical data
CREATE OR REPLACE FUNCTION calculate_forecast_patterns(
    p_service_name VARCHAR(200)
) RETURNS INTEGER AS $$
DECLARE
    v_patterns_created INTEGER := 0;
BEGIN
    -- Calculate daily patterns (by hour)
    INSERT INTO forecast_patterns (
        service_name,
        pattern_type,
        day_of_week,
        hour_of_day,
        avg_volume,
        avg_handle_time,
        volume_std_dev,
        sample_size
    )
    SELECT 
        service_name,
        'daily',
        EXTRACT(DOW FROM interval_start)::INTEGER,
        EXTRACT(HOUR FROM interval_start)::INTEGER,
        AVG(non_unique_incoming),
        AVG(average_handle_time),
        STDDEV(non_unique_incoming),
        COUNT(*)
    FROM forecast_historical_data
    WHERE service_name = p_service_name
    AND interval_start >= CURRENT_DATE - INTERVAL '28 days'
    GROUP BY service_name, EXTRACT(DOW FROM interval_start), EXTRACT(HOUR FROM interval_start)
    ON CONFLICT (service_name, skill_group, pattern_type, day_of_week, hour_of_day) 
    DO UPDATE SET
        avg_volume = EXCLUDED.avg_volume,
        avg_handle_time = EXCLUDED.avg_handle_time,
        volume_std_dev = EXCLUDED.volume_std_dev,
        sample_size = EXCLUDED.sample_size,
        last_updated = CURRENT_DATE;
    
    GET DIAGNOSTICS v_patterns_created = ROW_COUNT;
    
    RETURN v_patterns_created;
END;
$$ LANGUAGE plpgsql;

-- Function to create basic forecast (moving average method)
CREATE OR REPLACE FUNCTION create_basic_forecast(
    p_service_name VARCHAR(200),
    p_start_date DATE,
    p_end_date DATE,
    p_forecast_name VARCHAR(200) DEFAULT NULL,
    p_created_by VARCHAR(100) DEFAULT 'system'
) RETURNS UUID AS $$
DECLARE
    v_forecast_id UUID;
    v_current_date DATE;
    v_current_time TIMESTAMP WITH TIME ZONE;
    v_pattern forecast_patterns%ROWTYPE;
    v_volume DECIMAL(10,2);
    v_aht INTEGER;
    v_required_agents DECIMAL(10,2);
    v_total_volume INTEGER := 0;
BEGIN
    -- Create forecast header
    INSERT INTO forecast_calculations (
        forecast_name,
        service_name,
        forecast_start_date,
        forecast_end_date,
        forecast_method,
        created_by
    ) VALUES (
        COALESCE(p_forecast_name, p_service_name || ' Forecast ' || p_start_date),
        p_service_name,
        p_start_date,
        p_end_date,
        'moving_average',
        p_created_by
    ) RETURNING id INTO v_forecast_id;
    
    -- Generate forecast for each interval
    v_current_date := p_start_date;
    WHILE v_current_date <= p_end_date LOOP
        -- Generate 30-minute intervals for the day
        FOR hour IN 0..23 LOOP
            FOR minute IN 0..1 LOOP -- 0 = :00, 1 = :30
                v_current_time := v_current_date + (hour || ' hours')::INTERVAL + (minute * 30 || ' minutes')::INTERVAL;
                
                -- Get pattern for this time
                SELECT * INTO v_pattern
                FROM forecast_patterns
                WHERE service_name = p_service_name
                AND pattern_type = 'daily'
                AND day_of_week = EXTRACT(DOW FROM v_current_time)
                AND hour_of_day = EXTRACT(HOUR FROM v_current_time);
                
                -- Use pattern or default
                v_volume := COALESCE(v_pattern.avg_volume, 10);
                v_aht := COALESCE(v_pattern.avg_handle_time, 300);
                
                -- Simple Erlang C approximation for required agents
                -- Required agents = (Volume * AHT) / (Interval seconds * Occupancy)
                v_required_agents := (v_volume * v_aht) / (1800.0 * 0.85); -- 30 min * 85% occupancy
                
                INSERT INTO forecast_intervals (
                    forecast_id,
                    interval_start,
                    interval_end,
                    forecast_volume,
                    forecast_aht,
                    required_agents
                ) VALUES (
                    v_forecast_id,
                    v_current_time,
                    v_current_time + INTERVAL '30 minutes',
                    v_volume,
                    v_aht,
                    GREATEST(v_required_agents, 1) -- At least 1 agent
                );
                
                v_total_volume := v_total_volume + v_volume;
            END LOOP;
        END LOOP;
        
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;
    
    -- Update forecast summary
    UPDATE forecast_calculations SET
        total_forecast_volume = v_total_volume,
        avg_daily_volume = v_total_volume::DECIMAL / (p_end_date - p_start_date + 1),
        peak_hour_volume = (
            SELECT MAX(sum_volume) FROM (
                SELECT SUM(forecast_volume) as sum_volume
                FROM forecast_intervals
                WHERE forecast_id = v_forecast_id
                GROUP BY DATE_TRUNC('hour', interval_start)
            ) hourly
        )
    WHERE id = v_forecast_id;
    
    RETURN v_forecast_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Forecasting Dashboards
-- =============================================================================

-- View for forecast summary
CREATE VIEW v_forecast_summary AS
SELECT 
    fc.id as forecast_id,
    fc.forecast_name,
    fc.service_name,
    fc.forecast_start_date,
    fc.forecast_end_date,
    fc.total_forecast_volume,
    fc.avg_daily_volume,
    fc.peak_hour_volume,
    fc.forecast_method,
    fc.created_by,
    fc.created_at,
    fc.approved,
    COUNT(DISTINCT DATE(fi.interval_start)) as days_forecasted,
    ROUND(AVG(fi.required_agents), 1) as avg_required_agents,
    ROUND(MAX(fi.required_agents), 0) as peak_required_agents,
    ROUND(AVG(fi.forecast_aht), 0) as avg_handle_time
FROM forecast_calculations fc
LEFT JOIN forecast_intervals fi ON fi.forecast_id = fc.id
GROUP BY fc.id;

-- View for daily forecast breakdown
CREATE VIEW v_forecast_daily_summary AS
SELECT 
    fc.forecast_name,
    fc.service_name,
    DATE(fi.interval_start) as forecast_date,
    TO_CHAR(DATE(fi.interval_start), 'Day') as day_name,
    SUM(fi.forecast_volume) as daily_volume,
    ROUND(AVG(fi.forecast_aht), 0) as avg_handle_time,
    ROUND(AVG(fi.required_agents), 1) as avg_agents_required,
    ROUND(MAX(fi.required_agents), 0) as peak_agents_required,
    ROUND(SUM(fi.forecast_volume * fi.forecast_aht) / 3600.0, 1) as total_work_hours
FROM forecast_calculations fc
JOIN forecast_intervals fi ON fi.forecast_id = fc.id
GROUP BY fc.forecast_name, fc.service_name, DATE(fi.interval_start)
ORDER BY forecast_date;

-- View for real-time forecast vs actual comparison
CREATE VIEW v_forecast_accuracy AS
WITH actual_data AS (
    SELECT 
        DATE_TRUNC('hour', ate.entry_date + ate.actual_start_time::TIME) as actual_hour,
        COUNT(DISTINCT ate.employee_id) as actual_agents,
        COUNT(*) as actual_volume
    FROM argus_time_entries ate
    WHERE ate.entry_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY DATE_TRUNC('hour', ate.entry_date + ate.actual_start_time::TIME)
),
forecast_data AS (
    SELECT 
        DATE_TRUNC('hour', fi.interval_start) as forecast_hour,
        AVG(fi.required_agents) as forecast_agents,
        SUM(fi.forecast_volume) as forecast_volume
    FROM forecast_intervals fi
    JOIN forecast_calculations fc ON fc.id = fi.forecast_id
    WHERE fi.interval_start >= CURRENT_DATE - INTERVAL '7 days'
    AND fi.interval_start < CURRENT_DATE
    GROUP BY DATE_TRUNC('hour', fi.interval_start)
)
SELECT 
    COALESCE(a.actual_hour, f.forecast_hour) as hour,
    f.forecast_agents,
    a.actual_agents,
    f.forecast_volume,
    a.actual_volume,
    CASE 
        WHEN a.actual_agents IS NOT NULL AND f.forecast_agents IS NOT NULL 
        THEN ROUND(100.0 - (100.0 * ABS(a.actual_agents - f.forecast_agents) / f.forecast_agents), 1)
        ELSE NULL 
    END as agent_accuracy_percent,
    CASE 
        WHEN a.actual_volume IS NOT NULL AND f.forecast_volume IS NOT NULL 
        THEN ROUND(100.0 - (100.0 * ABS(a.actual_volume - f.forecast_volume) / f.forecast_volume), 1)
        ELSE NULL 
    END as volume_accuracy_percent
FROM actual_data a
FULL OUTER JOIN forecast_data f ON a.actual_hour = f.forecast_hour
ORDER BY hour DESC;

-- Demo view showing forecasting capability
CREATE VIEW v_demo_forecasting_capability AS
SELECT 
    'Basic Forecasting System' as feature_name,
    'Phase 1 Implementation' as status,
    COUNT(DISTINCT service_name) as services_configured,
    COUNT(*) as historical_data_points,
    COUNT(DISTINCT DATE(interval_start)) as days_of_history,
    ROUND(AVG(average_handle_time), 0) as avg_handle_time_seconds,
    ROUND(AVG(non_unique_incoming), 1) as avg_volume_per_interval,
    'Moving average with daily patterns' as forecast_method,
    'Excel import + basic calculation' as current_capabilities,
    NOW() as report_time
FROM forecast_historical_data
WHERE interval_start >= CURRENT_DATE - INTERVAL '30 days';

-- =============================================================================
-- SAMPLE DATA: Demo forecast data
-- =============================================================================

-- Insert sample historical data for demo
INSERT INTO forecast_historical_data (
    service_name, interval_start, interval_end,
    unique_incoming, non_unique_incoming, 
    average_talk_time, after_call_work_time
)
SELECT 
    'Technical Support' as service_name,
    ts as interval_start,
    ts + INTERVAL '30 minutes' as interval_end,
    15 + FLOOR(RANDOM() * 30 * 
        CASE 
            WHEN EXTRACT(HOUR FROM ts) BETWEEN 9 AND 11 THEN 1.5
            WHEN EXTRACT(HOUR FROM ts) BETWEEN 14 AND 16 THEN 1.3
            ELSE 1.0
        END
    )::INTEGER as unique_incoming,
    20 + FLOOR(RANDOM() * 40 * 
        CASE 
            WHEN EXTRACT(HOUR FROM ts) BETWEEN 9 AND 11 THEN 1.5
            WHEN EXTRACT(HOUR FROM ts) BETWEEN 14 AND 16 THEN 1.3
            ELSE 1.0
        END
    )::INTEGER as non_unique_incoming,
    240 + FLOOR(RANDOM() * 120)::INTEGER as average_talk_time,
    30 + FLOOR(RANDOM() * 30)::INTEGER as after_call_work_time
FROM generate_series(
    CURRENT_DATE - INTERVAL '28 days',
    CURRENT_DATE - INTERVAL '1 day',
    INTERVAL '30 minutes'
) ts
WHERE EXTRACT(HOUR FROM ts) BETWEEN 8 AND 20;

-- Calculate patterns from sample data
SELECT calculate_forecast_patterns('Technical Support');

-- Create a demo forecast
SELECT create_basic_forecast(
    'Technical Support',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'Demo Weekly Forecast',
    'demo_user'
);

COMMENT ON TABLE forecast_historical_data IS 'Historical data for forecasting - Excel import format from BDD';
COMMENT ON TABLE forecast_patterns IS 'Calculated patterns for basic forecasting';
COMMENT ON TABLE forecast_calculations IS 'Forecast headers and parameters';
COMMENT ON TABLE forecast_intervals IS 'Detailed interval-level forecasts';
COMMENT ON FUNCTION create_basic_forecast IS 'Simple moving average forecast - shows WFM fundamentals';