-- =============================================================================
-- 032_mobile_personal_cabinet.sql
-- EXACT BDD Implementation: Mobile Applications and Personal Cabinet
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 14-mobile-personal-cabinet.feature (326 lines)
-- Purpose: Employee self-service via mobile app and web personal cabinet
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. MOBILE AUTHENTICATION & SESSIONS
-- =============================================================================

-- Mobile app sessions with JWT token management
CREATE TABLE mobile_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    device_id VARCHAR(200) NOT NULL,
    device_type VARCHAR(50) NOT NULL CHECK (device_type IN ('iOS', 'Android', 'Web')),
    jwt_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    
    -- Biometric authentication settings
    biometric_enabled BOOLEAN DEFAULT false,
    biometric_type VARCHAR(50), -- 'TouchID', 'FaceID', 'Fingerprint'
    
    -- Push notification registration
    push_token TEXT,
    push_enabled BOOLEAN DEFAULT true,
    
    -- Session management
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    
    -- Unique constraint on device
    CONSTRAINT unique_device_session UNIQUE(employee_tab_n, device_id)
);

-- =============================================================================
-- 2. PERSONAL CALENDAR VIEWS
-- =============================================================================

-- Calendar view preferences and settings
CREATE TABLE calendar_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- View preferences from BDD
    default_view VARCHAR(20) DEFAULT 'Monthly' CHECK (default_view IN ('Monthly', 'Weekly', '4-day', 'Daily')),
    time_format VARCHAR(10) DEFAULT '24-hour' CHECK (time_format IN ('12-hour', '24-hour')),
    date_format VARCHAR(20) DEFAULT 'DD.MM.YYYY',
    
    -- Calendar customization
    show_breaks BOOLEAN DEFAULT true,
    show_lunches BOOLEAN DEFAULT true,
    show_events BOOLEAN DEFAULT true,
    color_by_channel BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Personal schedule cache for mobile viewing
CREATE TABLE personal_schedule_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    cache_date DATE NOT NULL,
    
    -- Schedule data for offline access
    schedule_data JSONB NOT NULL, -- Complete schedule information
    shift_details JSONB NOT NULL, -- Detailed shift info with breaks
    channel_assignments JSONB, -- Intraday channel assignments
    special_notes TEXT,
    
    -- Cache management
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    CONSTRAINT unique_employee_date_cache UNIQUE(employee_tab_n, cache_date)
);

-- =============================================================================
-- 3. EMPLOYEE PREFERENCES
-- =============================================================================

-- Work schedule preferences (priority and regular)
CREATE TABLE employee_schedule_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    preference_period_start DATE NOT NULL,
    preference_period_end DATE NOT NULL,
    
    -- Preference details from BDD
    preference_date DATE NOT NULL,
    preference_type VARCHAR(20) NOT NULL CHECK (preference_type IN ('Priority', 'Regular')),
    day_type VARCHAR(20) NOT NULL CHECK (day_type IN ('Work day', 'Day off')),
    
    -- Time parameters (optional)
    preferred_start_time TIME,
    preferred_end_time TIME,
    preferred_duration INTERVAL,
    
    -- Tracking
    submission_deadline DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_preference_date UNIQUE(employee_tab_n, preference_date)
);

-- Vacation preferences and desired dates
CREATE TABLE employee_vacation_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    vacation_year INTEGER NOT NULL,
    
    -- Vacation scheme reference
    vacation_scheme_id UUID,
    entitled_days INTEGER NOT NULL,
    
    -- Desired vacation periods
    desired_periods JSONB NOT NULL, -- Array of date ranges with priorities
    blackout_periods JSONB, -- Restricted periods
    
    -- Balance tracking
    days_used INTEGER DEFAULT 0,
    days_remaining INTEGER GENERATED ALWAYS AS (entitled_days - days_used) STORED,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_vacation_year UNIQUE(employee_tab_n, vacation_year)
);

-- =============================================================================
-- 4. REQUEST CREATION AND MANAGEMENT
-- =============================================================================

-- Enhanced employee requests for mobile (extends existing table concept)
CREATE TABLE mobile_employee_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Request types from BDD with Russian terms
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN (
        'Sick leave', -- больничный
        'Day off', -- отгул
        'Unscheduled vacation' -- внеочередной отпуск
    )),
    request_type_ru VARCHAR(50) NOT NULL,
    
    -- Request details
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    duration_days INTEGER GENERATED ALWAYS AS (date_to - date_from + 1) STORED,
    reason_comment TEXT,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Cancelled')),
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Mobile-specific fields
    created_via VARCHAR(20) NOT NULL CHECK (created_via IN ('Mobile', 'Web', 'Desktop')),
    is_draft BOOLEAN DEFAULT false, -- For offline creation
    sync_status VARCHAR(20) DEFAULT 'Synced',
    
    -- Actions
    can_cancel BOOLEAN GENERATED ALWAYS AS (status = 'Pending') STORED
);

-- =============================================================================
-- 5. SHIFT EXCHANGE SYSTEM INTEGRATION
-- =============================================================================

-- Mobile-optimized shift exchange view
CREATE VIEW v_mobile_shift_exchanges AS
SELECT 
    se.id,
    se.employee_tab_n as requester_tab_n,
    zad1.fio_full as requester_name,
    se.shift_date as original_shift_date,
    se.exchange_date as proposed_work_date,
    se.status,
    se.status_ru,
    
    -- Response information
    ser.employee_tab_n as responder_tab_n,
    zad2.fio_full as responder_name,
    ser.response_status,
    
    -- Mobile display fields
    CASE 
        WHEN se.status = 'ACTIVE' THEN true
        ELSE false
    END as is_available,
    
    se.created_at
FROM shift_exchange_requests se
LEFT JOIN shift_exchange_responses ser ON ser.request_id = se.id
LEFT JOIN zup_agent_data zad1 ON zad1.tab_n = se.employee_tab_n
LEFT JOIN zup_agent_data zad2 ON zad2.tab_n = ser.employee_tab_n;

-- =============================================================================
-- 6. NOTIFICATION SYSTEM
-- =============================================================================

-- Push notification settings per employee
CREATE TABLE push_notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Notification categories from BDD
    schedule_reminders BOOLEAN DEFAULT true, -- Shift start alerts
    break_reminders BOOLEAN DEFAULT true, -- 5 minutes before break
    lunch_reminders BOOLEAN DEFAULT true, -- 10 minutes before lunch
    request_updates BOOLEAN DEFAULT true, -- Status changes
    exchange_notifications BOOLEAN DEFAULT true, -- Trading opportunities
    emergency_alerts BOOLEAN DEFAULT true, -- Urgent changes
    
    -- Quiet hours configuration
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    -- Delivery preferences
    batch_similar BOOLEAN DEFAULT true, -- Group related alerts
    vibration_enabled BOOLEAN DEFAULT true,
    sound_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_notification_settings UNIQUE(employee_tab_n)
);

-- Notification queue for delivery
CREATE TABLE notification_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Notification details
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    
    -- Delivery methods from BDD
    delivery_methods TEXT[] DEFAULT ARRAY['in-app'], -- 'push', 'email', 'in-app'
    
    -- Deep linking
    deep_link_section VARCHAR(100), -- Where to navigate in app
    related_entity_id UUID, -- Related request/exchange/shift ID
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'Pending',
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Quick actions
    quick_actions JSONB, -- Available immediate responses
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. SCHEDULE ACKNOWLEDGMENTS
-- =============================================================================

-- Employee schedule acknowledgments tracking
CREATE TABLE schedule_acknowledgments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    schedule_period_start DATE NOT NULL,
    schedule_period_end DATE NOT NULL,
    
    -- Acknowledgment details
    schedule_version INTEGER NOT NULL,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledgment_method VARCHAR(20), -- 'Mobile', 'Web', 'Desktop'
    
    -- Comments/feedback
    employee_comments TEXT,
    
    -- Status
    is_acknowledged BOOLEAN DEFAULT false,
    requires_acknowledgment BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_schedule_ack UNIQUE(employee_tab_n, schedule_period_start, schedule_version)
);

-- =============================================================================
-- 8. OFFLINE SYNC MANAGEMENT
-- =============================================================================

-- Offline sync queue for mobile app
CREATE TABLE offline_sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    device_id VARCHAR(200) NOT NULL,
    
    -- Sync item details
    entity_type VARCHAR(50) NOT NULL, -- 'request', 'preference', 'acknowledgment'
    entity_data JSONB NOT NULL, -- Complete entity data
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
    
    -- Sync management
    created_offline_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sync_priority INTEGER DEFAULT 1,
    sync_attempts INTEGER DEFAULT 0,
    last_sync_attempt TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'Pending',
    sync_error TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. INTERFACE CUSTOMIZATION
-- =============================================================================

-- User interface customization settings
CREATE TABLE interface_customization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Theme and appearance
    theme_mode VARCHAR(20) DEFAULT 'Light' CHECK (theme_mode IN ('Light', 'Dark', 'Auto')),
    color_scheme VARCHAR(50) DEFAULT 'Default',
    
    -- Language and localization
    interface_language VARCHAR(20) DEFAULT 'Russian' CHECK (interface_language IN ('Russian', 'English')),
    
    -- Display preferences
    font_size VARCHAR(20) DEFAULT 'Medium' CHECK (font_size IN ('Small', 'Medium', 'Large', 'Extra Large')),
    high_contrast_mode BOOLEAN DEFAULT false,
    
    -- Behavior preferences
    auto_sync_enabled BOOLEAN DEFAULT true,
    sync_on_wifi_only BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_customization UNIQUE(employee_tab_n)
);

-- =============================================================================
-- 10. CALENDAR EXPORT FUNCTIONALITY
-- =============================================================================

-- Calendar export tracking
CREATE TABLE calendar_exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Export details
    export_format VARCHAR(20) NOT NULL CHECK (export_format IN ('ics', 'email', 'sync', 'feed')),
    export_range_start DATE NOT NULL,
    export_range_end DATE NOT NULL,
    
    -- Export configuration
    include_breaks BOOLEAN DEFAULT true,
    include_lunches BOOLEAN DEFAULT true,
    include_training BOOLEAN DEFAULT true,
    include_timeoff BOOLEAN DEFAULT true,
    
    -- For calendar feed subscriptions
    feed_url TEXT,
    feed_token VARCHAR(100),
    
    exported_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to create mobile session with JWT
CREATE OR REPLACE FUNCTION create_mobile_session(
    p_employee_tab_n VARCHAR(50),
    p_device_id VARCHAR(200),
    p_device_type VARCHAR(50),
    p_push_token TEXT DEFAULT NULL
) RETURNS TABLE(jwt_token TEXT, refresh_token TEXT, expires_at TIMESTAMP WITH TIME ZONE) AS $$
DECLARE
    v_jwt_token TEXT;
    v_refresh_token TEXT;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Generate tokens (simplified - in production use proper JWT library)
    v_jwt_token := encode(digest(p_employee_tab_n || p_device_id || CURRENT_TIMESTAMP::text, 'sha256'), 'hex');
    v_refresh_token := encode(digest(v_jwt_token || 'refresh', 'sha256'), 'hex');
    v_expires_at := CURRENT_TIMESTAMP + INTERVAL '7 days';
    
    -- Create or update session
    INSERT INTO mobile_sessions (
        employee_tab_n, device_id, device_type, 
        jwt_token, refresh_token, push_token, expires_at
    ) VALUES (
        p_employee_tab_n, p_device_id, p_device_type,
        v_jwt_token, v_refresh_token, p_push_token, v_expires_at
    )
    ON CONFLICT (employee_tab_n, device_id) DO UPDATE SET
        jwt_token = EXCLUDED.jwt_token,
        refresh_token = EXCLUDED.refresh_token,
        push_token = COALESCE(EXCLUDED.push_token, mobile_sessions.push_token),
        last_activity = CURRENT_TIMESTAMP,
        expires_at = EXCLUDED.expires_at,
        is_active = true;
    
    RETURN QUERY SELECT v_jwt_token, v_refresh_token, v_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Function to send notification with deep linking
CREATE OR REPLACE FUNCTION send_push_notification(
    p_employee_tab_n VARCHAR(50),
    p_notification_type VARCHAR(50),
    p_title VARCHAR(200),
    p_body TEXT,
    p_deep_link VARCHAR(100) DEFAULT NULL,
    p_related_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
    v_delivery_methods TEXT[];
BEGIN
    -- Check notification preferences
    SELECT 
        CASE 
            WHEN pns.schedule_reminders AND p_notification_type = 'schedule_reminder' THEN ARRAY['push', 'in-app']
            WHEN pns.break_reminders AND p_notification_type = 'break_reminder' THEN ARRAY['push', 'in-app']
            WHEN pns.lunch_reminders AND p_notification_type = 'lunch_reminder' THEN ARRAY['push', 'in-app']
            WHEN pns.request_updates AND p_notification_type = 'request_update' THEN ARRAY['email', 'in-app']
            WHEN pns.exchange_notifications AND p_notification_type = 'exchange_notification' THEN ARRAY['push', 'in-app']
            WHEN pns.emergency_alerts AND p_notification_type = 'emergency_alert' THEN ARRAY['push', 'email', 'in-app']
            ELSE ARRAY['in-app']
        END INTO v_delivery_methods
    FROM push_notification_settings pns
    WHERE pns.employee_tab_n = p_employee_tab_n;
    
    -- Create notification
    INSERT INTO notification_queue (
        employee_tab_n, notification_type, title, body,
        delivery_methods, deep_link_section, related_entity_id
    ) VALUES (
        p_employee_tab_n, p_notification_type, p_title, p_body,
        COALESCE(v_delivery_methods, ARRAY['in-app']), p_deep_link, p_related_id
    ) RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- Function to cache schedule for offline access
CREATE OR REPLACE FUNCTION cache_personal_schedule(
    p_employee_tab_n VARCHAR(50),
    p_start_date DATE,
    p_end_date DATE
) RETURNS void AS $$
DECLARE
    v_current_date DATE;
    v_schedule_data JSONB;
BEGIN
    v_current_date := p_start_date;
    
    WHILE v_current_date <= p_end_date LOOP
        -- Build schedule data (simplified - would include actual schedule queries)
        v_schedule_data := jsonb_build_object(
            'date', v_current_date,
            'shifts', jsonb_build_array(),
            'breaks', jsonb_build_array(),
            'events', jsonb_build_array()
        );
        
        -- Cache the schedule
        INSERT INTO personal_schedule_cache (
            employee_tab_n, cache_date, schedule_data, 
            shift_details, expires_at
        ) VALUES (
            p_employee_tab_n, v_current_date, v_schedule_data,
            jsonb_build_object('details', 'Shift information'),
            CURRENT_TIMESTAMP + INTERVAL '30 days'
        )
        ON CONFLICT (employee_tab_n, cache_date) DO UPDATE SET
            schedule_data = EXCLUDED.schedule_data,
            shift_details = EXCLUDED.shift_details,
            cached_at = CURRENT_TIMESTAMP,
            expires_at = EXCLUDED.expires_at;
        
        v_current_date := v_current_date + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Mobile session indexes
CREATE INDEX idx_mobile_sessions_employee ON mobile_sessions(employee_tab_n);
CREATE INDEX idx_mobile_sessions_active ON mobile_sessions(is_active, expires_at);

-- Notification indexes
CREATE INDEX idx_notification_queue_employee ON notification_queue(employee_tab_n);
CREATE INDEX idx_notification_queue_status ON notification_queue(status, created_at);

-- Preference indexes
CREATE INDEX idx_schedule_preferences_employee_period ON employee_schedule_preferences(employee_tab_n, preference_period_start);
CREATE INDEX idx_vacation_preferences_employee_year ON employee_vacation_preferences(employee_tab_n, vacation_year);

-- Request indexes
CREATE INDEX idx_mobile_requests_employee ON mobile_employee_requests(employee_tab_n);
CREATE INDEX idx_mobile_requests_status ON mobile_employee_requests(status);

-- Acknowledgment indexes
CREATE INDEX idx_acknowledgments_employee ON schedule_acknowledgments(employee_tab_n);
CREATE INDEX idx_acknowledgments_required ON schedule_acknowledgments(requires_acknowledgment, is_acknowledged);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Insert sample notification settings
INSERT INTO push_notification_settings (employee_tab_n) 
SELECT tab_n FROM zup_agent_data LIMIT 5;

-- Insert sample calendar preferences
INSERT INTO calendar_preferences (employee_tab_n, default_view, time_format)
SELECT tab_n, 'Monthly', '24-hour' FROM zup_agent_data LIMIT 5;

-- Insert sample interface customization
INSERT INTO interface_customization (employee_tab_n, theme_mode, interface_language)
VALUES 
('00001', 'Dark', 'Russian'),
('TS001', 'Light', 'English'),
('TS002', 'Auto', 'Russian');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions (adjust role names as needed)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_mobile_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_mobile_app;