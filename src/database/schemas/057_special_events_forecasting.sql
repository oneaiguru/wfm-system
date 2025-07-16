-- =============================================================================
-- 057_special_events_forecasting.sql
-- EXACT BDD Implementation: Special Events for Forecasting with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 30-special-events-forecasting.feature (30 lines)
-- Purpose: Special events configuration for unforecastable events affecting load predictions
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SPECIAL EVENT TYPES
-- =============================================================================

-- Event type definitions from BDD lines 15-21
CREATE TABLE special_event_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type_id VARCHAR(50) NOT NULL UNIQUE,
    event_type_name VARCHAR(100) NOT NULL,
    event_description TEXT NOT NULL,
    
    -- Impact characteristics from BDD lines 16-21
    typical_impact VARCHAR(30) NOT NULL CHECK (typical_impact IN (
        'load_reduction', 'load_increase', 'load_variation', 'load_spike'
    )),
    examples TEXT,
    
    -- Default configuration
    default_load_coefficient DECIMAL(5,3) DEFAULT 1.0,
    default_duration_hours INTEGER DEFAULT 24,
    typical_advance_notice_days INTEGER DEFAULT 7,
    
    -- Impact patterns
    impact_pattern JSONB DEFAULT '{}',
    seasonal_factors JSONB DEFAULT '{}',
    time_of_day_factors JSONB DEFAULT '{}',
    
    -- Forecasting parameters
    affects_short_term_forecast BOOLEAN DEFAULT true,
    affects_long_term_forecast BOOLEAN DEFAULT false,
    requires_manual_review BOOLEAN DEFAULT true,
    auto_apply_coefficient BOOLEAN DEFAULT false,
    
    -- Business rules
    can_overlap_with_other_events BOOLEAN DEFAULT true,
    max_coefficient_multiplier DECIMAL(5,3) DEFAULT 3.0,
    min_coefficient_multiplier DECIMAL(5,3) DEFAULT 0.1,
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. SPECIAL EVENTS
-- =============================================================================

-- Special event instances from BDD lines 22-29
CREATE TABLE special_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Event identification from BDD lines 24-25
    event_name VARCHAR(200) NOT NULL,
    event_type_id VARCHAR(50) NOT NULL,
    
    -- Event timing from BDD lines 26-27
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    
    -- Load impact from BDD line 28
    load_coefficient DECIMAL(5,3) NOT NULL CHECK (load_coefficient >= 0.0 AND load_coefficient <= 10.0),
    
    -- Service scope from BDD line 29
    affected_service_groups JSONB NOT NULL,
    affected_channels JSONB DEFAULT '[]',
    affected_locations JSONB DEFAULT '[]',
    
    -- Event details
    event_description TEXT,
    external_event_id VARCHAR(100),
    event_source VARCHAR(50) DEFAULT 'manual' CHECK (event_source IN (
        'manual', 'imported', 'automated', 'system', 'external_api'
    )),
    
    -- Impact configuration
    hourly_coefficients JSONB DEFAULT '{}',
    daily_coefficients JSONB DEFAULT '{}',
    granular_impact_pattern JSONB DEFAULT '{}',
    
    -- Confidence and validation
    confidence_level VARCHAR(20) DEFAULT 'medium' CHECK (confidence_level IN ('low', 'medium', 'high', 'confirmed')),
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'validated', 'rejected', 'expired'
    )),
    validation_notes TEXT,
    
    -- Business metadata
    business_justification TEXT,
    impact_assessment TEXT,
    stakeholder_approval BOOLEAN DEFAULT false,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Recurrence
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern JSONB DEFAULT '{}',
    parent_event_id UUID,
    
    -- Status tracking
    event_status VARCHAR(20) DEFAULT 'scheduled' CHECK (event_status IN (
        'scheduled', 'active', 'completed', 'cancelled', 'postponed'
    )),
    is_active BOOLEAN DEFAULT true,
    
    -- Change management
    created_by UUID NOT NULL,
    last_modified_by UUID,
    modification_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_type_id) REFERENCES special_event_types(event_type_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_event_id) REFERENCES special_events(id) ON DELETE SET NULL,
    
    -- Ensure valid date range
    CHECK (end_date >= start_date),
    CHECK (end_time IS NULL OR start_time IS NULL OR end_time >= start_time OR end_date > start_date)
);

-- =============================================================================
-- 3. EVENT IMPACT TRACKING
-- =============================================================================

-- Track actual impact vs predicted impact
CREATE TABLE event_impact_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_id VARCHAR(50) NOT NULL UNIQUE,
    event_id VARCHAR(50) NOT NULL,
    
    -- Measurement period
    impact_date DATE NOT NULL,
    measurement_hour INTEGER CHECK (measurement_hour >= 0 AND measurement_hour <= 23),
    service_group VARCHAR(100) NOT NULL,
    
    -- Predicted vs actual
    predicted_load_coefficient DECIMAL(5,3) NOT NULL,
    actual_load_coefficient DECIMAL(5,3),
    baseline_volume INTEGER,
    predicted_volume INTEGER,
    actual_volume INTEGER,
    
    -- Variance analysis
    coefficient_variance_percentage DECIMAL(5,2),
    volume_variance_percentage DECIMAL(5,2),
    absolute_variance INTEGER,
    
    -- Impact classification
    impact_accuracy VARCHAR(20) CHECK (impact_accuracy IN ('accurate', 'overestimated', 'underestimated', 'unknown')),
    variance_category VARCHAR(20) CHECK (variance_category IN ('minimal', 'acceptable', 'significant', 'major')),
    
    -- Data quality
    data_completeness DECIMAL(3,2) DEFAULT 1.0,
    measurement_confidence VARCHAR(20) DEFAULT 'medium' CHECK (measurement_confidence IN ('low', 'medium', 'high')),
    data_source VARCHAR(50),
    
    -- Analysis metadata
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    analysis_completed BOOLEAN DEFAULT false,
    analysis_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES special_events(event_id) ON DELETE CASCADE,
    
    UNIQUE(event_id, impact_date, measurement_hour, service_group)
);

-- =============================================================================
-- 4. FORECASTING ADJUSTMENTS
-- =============================================================================

-- Track how events affect forecasting calculations
CREATE TABLE forecasting_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    adjustment_id VARCHAR(50) NOT NULL UNIQUE,
    event_id VARCHAR(50) NOT NULL,
    
    -- Forecast context
    forecast_date DATE NOT NULL,
    forecast_hour INTEGER CHECK (forecast_hour >= 0 AND forecast_hour <= 23),
    service_group VARCHAR(100) NOT NULL,
    channel VARCHAR(50),
    
    -- Adjustment details
    original_forecast_value INTEGER NOT NULL,
    adjustment_coefficient DECIMAL(5,3) NOT NULL,
    adjusted_forecast_value INTEGER NOT NULL,
    adjustment_amount INTEGER NOT NULL,
    
    -- Adjustment rationale
    adjustment_type VARCHAR(30) NOT NULL CHECK (adjustment_type IN (
        'coefficient_multiplier', 'additive_adjustment', 'replacement_value', 'percentage_change'
    )),
    adjustment_method VARCHAR(30) DEFAULT 'automatic' CHECK (adjustment_method IN (
        'automatic', 'manual', 'hybrid', 'override'
    )),
    adjustment_reason TEXT,
    
    -- Quality and confidence
    confidence_score DECIMAL(3,2) DEFAULT 0.8,
    quality_score DECIMAL(3,2) DEFAULT 1.0,
    manual_review_required BOOLEAN DEFAULT false,
    
    -- Approval workflow
    requires_approval BOOLEAN DEFAULT false,
    approved BOOLEAN DEFAULT false,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Application status
    applied_to_forecast BOOLEAN DEFAULT false,
    application_timestamp TIMESTAMP WITH TIME ZONE,
    rollback_available BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES special_events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    UNIQUE(event_id, forecast_date, forecast_hour, service_group, channel)
);

-- =============================================================================
-- 5. EVENT TEMPLATES
-- =============================================================================

-- Reusable event templates for common events
CREATE TABLE special_event_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id VARCHAR(50) NOT NULL UNIQUE,
    template_name VARCHAR(200) NOT NULL,
    template_description TEXT,
    
    -- Template configuration
    event_type_id VARCHAR(50) NOT NULL,
    default_duration_days INTEGER DEFAULT 1,
    default_load_coefficient DECIMAL(5,3) DEFAULT 1.0,
    default_affected_services JSONB DEFAULT '[]',
    
    -- Template patterns
    typical_timing_pattern JSONB DEFAULT '{}',
    seasonal_occurrence JSONB DEFAULT '{}',
    impact_pattern_template JSONB DEFAULT '{}',
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    last_used_date DATE,
    average_accuracy_score DECIMAL(3,2),
    
    -- Template metadata
    is_active BOOLEAN DEFAULT true,
    is_public BOOLEAN DEFAULT false,
    created_by UUID NOT NULL,
    organization_scope VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_type_id) REFERENCES special_event_types(event_type_id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 6. EVENT NOTIFICATIONS AND ALERTS
-- =============================================================================

-- Event-related notifications and alerts
CREATE TABLE event_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id VARCHAR(50) NOT NULL UNIQUE,
    event_id VARCHAR(50) NOT NULL,
    
    -- Notification configuration
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN (
        'event_created', 'event_starting', 'event_ending', 'impact_deviation', 'validation_required'
    )),
    notification_priority VARCHAR(20) DEFAULT 'medium' CHECK (notification_priority IN (
        'low', 'medium', 'high', 'urgent'
    )),
    
    -- Recipient configuration
    recipient_roles JSONB DEFAULT '[]',
    recipient_users JSONB DEFAULT '[]',
    recipient_groups JSONB DEFAULT '[]',
    
    -- Notification content
    notification_title VARCHAR(200) NOT NULL,
    notification_message TEXT NOT NULL,
    notification_data JSONB DEFAULT '{}',
    
    -- Delivery configuration
    delivery_channels JSONB DEFAULT '["email"]',
    delivery_schedule TIMESTAMP WITH TIME ZONE,
    advance_notice_minutes INTEGER DEFAULT 60,
    
    -- Status tracking
    notification_status VARCHAR(20) DEFAULT 'pending' CHECK (notification_status IN (
        'pending', 'sent', 'delivered', 'failed', 'cancelled'
    )),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivery_attempts INTEGER DEFAULT 0,
    delivery_errors JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (event_id) REFERENCES special_events(event_id) ON DELETE CASCADE
);

-- =============================================================================
-- 7. EVENT ANALYTICS AND REPORTING
-- =============================================================================

-- Analytics for event effectiveness and accuracy
CREATE TABLE event_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analytics_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Analysis scope
    analysis_period_start DATE NOT NULL,
    analysis_period_end DATE NOT NULL,
    event_type_filter VARCHAR(50),
    service_group_filter VARCHAR(100),
    
    -- Event statistics
    total_events_analyzed INTEGER NOT NULL,
    events_with_impact_data INTEGER NOT NULL,
    data_completeness_percentage DECIMAL(5,2) NOT NULL,
    
    -- Accuracy metrics
    average_coefficient_accuracy DECIMAL(5,2),
    average_volume_accuracy DECIMAL(5,2),
    prediction_accuracy_score DECIMAL(3,2),
    
    -- Performance metrics
    events_overestimated INTEGER DEFAULT 0,
    events_underestimated INTEGER DEFAULT 0,
    events_accurate INTEGER DEFAULT 0,
    average_variance_percentage DECIMAL(5,2),
    
    -- Business impact
    total_forecast_adjustments INTEGER DEFAULT 0,
    total_volume_impact INTEGER DEFAULT 0,
    forecast_improvement_score DECIMAL(3,2),
    
    -- Recommendations
    accuracy_trends JSONB DEFAULT '{}',
    improvement_recommendations JSONB DEFAULT '[]',
    model_tuning_suggestions JSONB DEFAULT '[]',
    
    -- Analysis metadata
    analysis_completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    analysis_version VARCHAR(20) DEFAULT '1.0',
    analyzed_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (analyzed_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    CHECK (analysis_period_end >= analysis_period_start)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Event type queries
CREATE INDEX idx_special_event_types_active ON special_event_types(is_active) WHERE is_active = true;
CREATE INDEX idx_special_event_types_impact ON special_event_types(typical_impact);

-- Special event queries
CREATE INDEX idx_special_events_type ON special_events(event_type_id);
CREATE INDEX idx_special_events_dates ON special_events(start_date, end_date);
CREATE INDEX idx_special_events_status ON special_events(event_status);
CREATE INDEX idx_special_events_active ON special_events(is_active) WHERE is_active = true;
CREATE INDEX idx_special_events_date_range ON special_events(start_date) WHERE event_status IN ('scheduled', 'active');
CREATE INDEX idx_special_events_validation ON special_events(validation_status);
CREATE INDEX idx_special_events_created_by ON special_events(created_by);

-- Impact tracking queries
CREATE INDEX idx_event_impact_tracking_event ON event_impact_tracking(event_id);
CREATE INDEX idx_event_impact_tracking_date ON event_impact_tracking(impact_date);
CREATE INDEX idx_event_impact_tracking_service ON event_impact_tracking(service_group);
CREATE INDEX idx_event_impact_tracking_accuracy ON event_impact_tracking(impact_accuracy);
CREATE INDEX idx_event_impact_tracking_variance ON event_impact_tracking(variance_category);

-- Forecasting adjustment queries
CREATE INDEX idx_forecasting_adjustments_event ON forecasting_adjustments(event_id);
CREATE INDEX idx_forecasting_adjustments_date ON forecasting_adjustments(forecast_date);
CREATE INDEX idx_forecasting_adjustments_service ON forecasting_adjustments(service_group);
CREATE INDEX idx_forecasting_adjustments_applied ON forecasting_adjustments(applied_to_forecast);
CREATE INDEX idx_forecasting_adjustments_approval ON forecasting_adjustments(requires_approval, approved);

-- Template queries
CREATE INDEX idx_special_event_templates_type ON special_event_templates(event_type_id);
CREATE INDEX idx_special_event_templates_active ON special_event_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_special_event_templates_public ON special_event_templates(is_public) WHERE is_public = true;
CREATE INDEX idx_special_event_templates_usage ON special_event_templates(usage_count);

-- Notification queries
CREATE INDEX idx_event_notifications_event ON event_notifications(event_id);
CREATE INDEX idx_event_notifications_type ON event_notifications(notification_type);
CREATE INDEX idx_event_notifications_status ON event_notifications(notification_status);
CREATE INDEX idx_event_notifications_schedule ON event_notifications(delivery_schedule);
CREATE INDEX idx_event_notifications_pending ON event_notifications(notification_status) WHERE notification_status = 'pending';

-- Analytics queries
CREATE INDEX idx_event_analytics_period ON event_analytics(analysis_period_start, analysis_period_end);
CREATE INDEX idx_event_analytics_type ON event_analytics(event_type_filter);
CREATE INDEX idx_event_analytics_completed ON event_analytics(analysis_completed_at);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_events_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER special_event_types_update_trigger
    BEFORE UPDATE ON special_event_types
    FOR EACH ROW EXECUTE FUNCTION update_events_timestamp();

CREATE TRIGGER special_events_update_trigger
    BEFORE UPDATE ON special_events
    FOR EACH ROW EXECUTE FUNCTION update_events_timestamp();

CREATE TRIGGER special_event_templates_update_trigger
    BEFORE UPDATE ON special_event_templates
    FOR EACH ROW EXECUTE FUNCTION update_events_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active special events
CREATE VIEW v_active_special_events AS
SELECT 
    se.event_id,
    se.event_name,
    set.event_type_name,
    set.typical_impact,
    se.start_date,
    se.end_date,
    se.load_coefficient,
    se.affected_service_groups,
    se.event_status,
    se.confidence_level
FROM special_events se
JOIN special_event_types set ON se.event_type_id = set.event_type_id
WHERE se.is_active = true
  AND se.event_status IN ('scheduled', 'active')
  AND se.end_date >= CURRENT_DATE
ORDER BY se.start_date, se.event_name;

-- Upcoming events requiring attention
CREATE VIEW v_upcoming_events_requiring_attention AS
SELECT 
    se.event_id,
    se.event_name,
    set.event_type_name,
    se.start_date,
    se.validation_status,
    se.confidence_level,
    CASE 
        WHEN se.validation_status = 'pending' THEN 'Validation Required'
        WHEN se.confidence_level = 'low' THEN 'Low Confidence'
        WHEN se.stakeholder_approval = false AND set.requires_manual_review THEN 'Approval Required'
        ELSE 'Ready'
    END as attention_reason
FROM special_events se
JOIN special_event_types set ON se.event_type_id = set.event_type_id
WHERE se.is_active = true
  AND se.event_status = 'scheduled'
  AND se.start_date <= CURRENT_DATE + INTERVAL '30 days'
  AND (se.validation_status = 'pending' 
       OR se.confidence_level = 'low' 
       OR (se.stakeholder_approval = false AND set.requires_manual_review))
ORDER BY se.start_date, se.event_name;

-- Event impact accuracy summary
CREATE VIEW v_event_impact_accuracy_summary AS
SELECT 
    se.event_type_id,
    set.event_type_name,
    COUNT(eit.id) as total_measurements,
    AVG(eit.coefficient_variance_percentage) as avg_coefficient_variance,
    AVG(eit.volume_variance_percentage) as avg_volume_variance,
    COUNT(CASE WHEN eit.impact_accuracy = 'accurate' THEN 1 END) as accurate_predictions,
    COUNT(CASE WHEN eit.impact_accuracy = 'overestimated' THEN 1 END) as overestimated_predictions,
    COUNT(CASE WHEN eit.impact_accuracy = 'underestimated' THEN 1 END) as underestimated_predictions,
    (COUNT(CASE WHEN eit.impact_accuracy = 'accurate' THEN 1 END)::DECIMAL / COUNT(eit.id) * 100) as accuracy_percentage
FROM special_events se
JOIN special_event_types set ON se.event_type_id = set.event_type_id
LEFT JOIN event_impact_tracking eit ON se.event_id = eit.event_id
WHERE eit.impact_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY se.event_type_id, set.event_type_name
HAVING COUNT(eit.id) > 0
ORDER BY accuracy_percentage DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert event types from BDD lines 16-21
INSERT INTO special_event_types (event_type_id, event_type_name, event_description, typical_impact, examples, default_load_coefficient) VALUES
('city_holiday', 'City Holiday', 'Local holiday', 'load_reduction', 'City Day', 0.7),
('mass_event', 'Mass Event', 'Large gathering', 'load_increase', 'Concert, Sports', 1.3),
('weather_event', 'Weather Event', 'Severe weather', 'load_variation', 'Storm, Snow', 1.2),
('technical_event', 'Technical Event', 'System outage', 'load_spike', 'Service disruption', 2.0),
('marketing_event', 'Marketing Event', 'Promotion campaign', 'load_increase', 'Sale announcement', 1.5);

-- Insert sample event templates
INSERT INTO special_event_templates (template_id, template_name, template_description, event_type_id, default_duration_days, default_load_coefficient, default_affected_services) VALUES
('city_day_template', 'City Day Template', 'Template for annual city day celebrations', 'city_holiday', 1, 0.6, '["customer_service", "billing_support"]'),
('black_friday_template', 'Black Friday Template', 'Template for Black Friday sales events', 'marketing_event', 1, 2.5, '["customer_service", "order_support", "billing_support"]'),
('winter_storm_template', 'Winter Storm Template', 'Template for severe winter weather events', 'weather_event', 2, 1.4, '["emergency_support", "customer_service"]');

-- Insert sample special event
INSERT INTO special_events (event_id, event_name, event_type_id, start_date, end_date, load_coefficient, affected_service_groups, event_description, created_by) VALUES
('new_year_2025', 'New Year 2025 Celebration', 'city_holiday', '2025-01-01', '2025-01-01', 0.5, '["customer_service", "billing_support"]', 'New Year public holiday with reduced call volume', (SELECT id FROM employees LIMIT 1));

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE special_event_types IS 'BDD Lines 15-21: Event type definitions with impact characteristics and forecasting parameters';
COMMENT ON TABLE special_events IS 'BDD Lines 22-29: Special event instances with load coefficients and service group configurations';
COMMENT ON TABLE event_impact_tracking IS 'Tracking actual vs predicted impact for event accuracy measurement';
COMMENT ON TABLE forecasting_adjustments IS 'Forecasting adjustments applied due to special events';
COMMENT ON TABLE special_event_templates IS 'Reusable event templates for common recurring events';
COMMENT ON TABLE event_notifications IS 'Event-related notifications and alerts system';
COMMENT ON TABLE event_analytics IS 'Analytics for event effectiveness and forecasting accuracy';