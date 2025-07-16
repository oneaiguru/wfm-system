-- Schema 084: Special Events Forecasting (BDD 30)
-- Unforecastable events impact on load predictions
-- Load coefficients and service group targeting

-- 1. Special Event Definitions
CREATE TABLE special_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(255) NOT NULL,
    event_name_ru VARCHAR(255),
    event_type VARCHAR(50) NOT NULL, -- city_holiday, mass_event, weather_event, technical_event, marketing_event
    event_category VARCHAR(50), -- planned, unplanned, recurring
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    load_coefficient DECIMAL(5,2) NOT NULL DEFAULT 1.0, -- Impact multiplier (0.5 = 50% reduction, 2.0 = 200% increase)
    confidence_level DECIMAL(5,2) DEFAULT 80.0, -- Prediction confidence
    location_id UUID, -- Affected location
    is_confirmed BOOLEAN DEFAULT false,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (end_date >= start_date),
    CONSTRAINT valid_coefficient CHECK (load_coefficient > 0 AND load_coefficient <= 5)
);

-- 2. Event Service Group Impacts
CREATE TABLE event_service_impacts (
    impact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES special_events(event_id) ON DELETE CASCADE,
    service_group_id UUID NOT NULL, -- References service groups
    impact_coefficient DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    impact_type VARCHAR(50), -- volume, aht, both
    impact_start_offset INTEGER DEFAULT 0, -- Minutes before event start
    impact_end_offset INTEGER DEFAULT 0, -- Minutes after event end
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, service_group_id)
);

-- 3. Event Impact Patterns
CREATE TABLE event_impact_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_name VARCHAR(255) NOT NULL,
    event_type VARCHAR(50),
    hour_offset INTEGER NOT NULL, -- Hours from event start
    impact_multiplier DECIMAL(5,2) NOT NULL,
    pattern_description TEXT,
    is_template BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Historical Event Analysis
CREATE TABLE historical_event_impacts (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES special_events(event_id),
    analysis_date DATE NOT NULL,
    predicted_volume INTEGER,
    actual_volume INTEGER,
    predicted_aht DECIMAL(10,2),
    actual_aht DECIMAL(10,2),
    accuracy_percent DECIMAL(5,2),
    coefficient_used DECIMAL(5,2),
    coefficient_optimal DECIMAL(5,2), -- Calculated post-event
    lessons_learned TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Event Templates Library
CREATE TABLE event_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) NOT NULL,
    template_name_ru VARCHAR(255),
    event_type VARCHAR(50) NOT NULL,
    typical_duration_hours INTEGER,
    typical_coefficient DECIMAL(5,2),
    impact_pattern JSONB, -- Hour-by-hour impact pattern
    applicable_services JSONB, -- Service types typically affected
    best_practices TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Weather Event Integration
CREATE TABLE weather_event_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    weather_type VARCHAR(50), -- snow, storm, heat_wave, flooding
    severity_level VARCHAR(20), -- mild, moderate, severe, extreme
    base_coefficient DECIMAL(5,2),
    service_impacts JSONB, -- Service-specific impacts
    threshold_values JSONB, -- Temperature, precipitation thresholds
    auto_detection_enabled BOOLEAN DEFAULT false,
    api_endpoint VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Marketing Campaign Events
CREATE TABLE marketing_campaign_events (
    campaign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES special_events(event_id),
    campaign_type VARCHAR(50), -- sale, promotion, announcement, launch
    target_audience_size INTEGER,
    expected_response_rate DECIMAL(5,2),
    channels JSONB, -- TV, radio, online, SMS
    budget_amount DECIMAL(12,2),
    roi_coefficient DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Event Notification Rules
CREATE TABLE event_notification_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50),
    notification_trigger VARCHAR(50), -- event_created, X_days_before, event_started
    trigger_offset_hours INTEGER,
    recipient_roles TEXT[],
    notification_template TEXT,
    notification_channel VARCHAR(50), -- email, sms, system, push
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Load Coefficient Calculations
CREATE TABLE load_coefficient_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calculation_date DATE NOT NULL,
    base_forecast_volume INTEGER,
    event_adjustments JSONB, -- Array of event impacts
    final_coefficient DECIMAL(5,2),
    final_forecast_volume INTEGER,
    calculation_method VARCHAR(50), -- multiplicative, additive, weighted
    confidence_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Event Conflict Resolution
CREATE TABLE event_conflicts (
    conflict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event1_id UUID REFERENCES special_events(event_id),
    event2_id UUID REFERENCES special_events(event_id),
    conflict_type VARCHAR(50), -- overlapping, contradictory, resource
    overlap_start TIMESTAMP,
    overlap_end TIMESTAMP,
    resolution_method VARCHAR(50), -- higher_priority, combine, manual
    resolved_coefficient DECIMAL(5,2),
    resolved_by VARCHAR(255),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert event type templates
INSERT INTO event_templates (template_name, template_name_ru, event_type, typical_duration_hours, typical_coefficient)
VALUES 
    ('City Day Holiday', 'День города', 'city_holiday', 24, 0.7),
    ('Major Concert', 'Большой концерт', 'mass_event', 6, 1.5),
    ('Heavy Snowfall', 'Сильный снегопад', 'weather_event', 12, 0.6),
    ('System Outage', 'Сбой системы', 'technical_event', 4, 3.0),
    ('Black Friday Sale', 'Черная пятница', 'marketing_event', 48, 2.5);

-- Insert weather configurations
INSERT INTO weather_event_configs (weather_type, severity_level, base_coefficient, threshold_values)
VALUES 
    ('snow', 'severe', 0.5, '{"snowfall_cm": 20, "temperature_c": -15}'::jsonb),
    ('heat_wave', 'extreme', 0.8, '{"temperature_c": 35, "duration_days": 3}'::jsonb),
    ('storm', 'moderate', 1.3, '{"wind_speed_kmh": 80, "precipitation_mm": 50}'::jsonb);

-- Insert impact patterns
INSERT INTO event_impact_patterns (pattern_name, event_type, hour_offset, impact_multiplier)
VALUES 
    ('Concert Pre-Event', 'mass_event', -2, 1.2),
    ('Concert Peak', 'mass_event', 0, 1.8),
    ('Concert Post-Event', 'mass_event', 2, 1.4),
    ('Holiday Morning', 'city_holiday', 0, 0.5),
    ('Holiday Afternoon', 'city_holiday', 6, 0.7);

-- Create indexes
CREATE INDEX idx_special_events_dates ON special_events(start_date, end_date);
CREATE INDEX idx_event_impacts_service ON event_service_impacts(service_group_id);
CREATE INDEX idx_historical_analysis_event ON historical_event_impacts(event_id, analysis_date);
CREATE INDEX idx_event_type ON special_events(event_type);

-- Verify special events tables
SELECT COUNT(*) as special_events_tables FROM information_schema.tables 
WHERE table_name LIKE '%event%' OR table_name LIKE '%coefficient%';