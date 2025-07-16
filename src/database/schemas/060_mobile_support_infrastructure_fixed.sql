-- Schema 060: Mobile Support Infrastructure (Tasks 1-5) - CORRECTED VERSION
-- Enhanced mobile functionality for WFM Enterprise
-- Author: DATABASE-OPUS Agent
-- Created: 2025-07-14

-- Task 1: Enhanced Mobile Session Management (UPDATE existing table)
-- Add additional columns to existing mobile_sessions table
ALTER TABLE mobile_sessions 
ADD COLUMN IF NOT EXISTS device_fingerprint JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS device_type VARCHAR(50) CHECK (device_type IN ('ios', 'android', 'tablet', 'web')),
ADD COLUMN IF NOT EXISTS device_model VARCHAR(100),
ADD COLUMN IF NOT EXISTS os_version VARCHAR(50),
ADD COLUMN IF NOT EXISTS logout_timestamp TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS session_duration INTERVAL GENERATED ALWAYS AS (logout_timestamp - login_time) STORED,
ADD COLUMN IF NOT EXISTS ip_address INET,
ADD COLUMN IF NOT EXISTS user_agent TEXT,
ADD COLUMN IF NOT EXISTS security_level VARCHAR(20) DEFAULT 'standard' CHECK (security_level IN ('basic', 'standard', 'high', 'biometric')),
ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS failed_auth_attempts INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS location_permission BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS camera_permission BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS notification_permission BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Task 2: Push Notification Queue System
CREATE TABLE IF NOT EXISTS push_notification_queue (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('individual', 'group', 'department', 'all')),
    target_ids UUID[] DEFAULT '{}',
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN (
        'schedule_change', 'shift_reminder', 'break_reminder', 'overtime_alert',
        'vacation_approved', 'vacation_denied', 'emergency_alert', 'system_maintenance',
        'new_message', 'task_assigned', 'deadline_approaching', 'weather_alert'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    title_ru VARCHAR(255),
    message_ru TEXT,
    priority VARCHAR(10) NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    payload JSONB DEFAULT '{}',
    scheduled_for TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    deep_link VARCHAR(500),
    badge_count INTEGER DEFAULT 0,
    sound VARCHAR(50) DEFAULT 'default',
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ
);

-- Task 3: Offline Sync Tracking
CREATE TABLE IF NOT EXISTS mobile_offline_sync (
    sync_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES mobile_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    sync_type VARCHAR(30) NOT NULL CHECK (sync_type IN (
        'full_sync', 'incremental', 'schedule_sync', 'timesheet_sync',
        'request_sync', 'message_sync', 'settings_sync'
    )),
    last_sync_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    next_sync_due TIMESTAMPTZ,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (sync_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'partial'
    )),
    data_version VARCHAR(50),
    items_to_sync INTEGER DEFAULT 0,
    items_synced INTEGER DEFAULT 0,
    items_failed INTEGER DEFAULT 0,
    sync_duration INTERVAL,
    error_details JSONB DEFAULT '{}',
    offline_changes JSONB DEFAULT '{}',
    conflict_resolution JSONB DEFAULT '{}',
    data_size_kb INTEGER DEFAULT 0,
    connection_type VARCHAR(20) DEFAULT 'wifi' CHECK (connection_type IN ('wifi', '4g', '5g', '3g', 'edge')),
    battery_level INTEGER CHECK (battery_level BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Task 4: Geofencing Boundaries
CREATE TABLE IF NOT EXISTS geofencing_boundaries (
    boundary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_name VARCHAR(255) NOT NULL,
    location_name_ru VARCHAR(255),
    location_type VARCHAR(30) NOT NULL CHECK (location_type IN (
        'office', 'warehouse', 'retail_store', 'service_center', 'home_office', 'client_site'
    )),
    center_latitude DECIMAL(10, 8) NOT NULL,
    center_longitude DECIMAL(11, 8) NOT NULL,
    radius_meters INTEGER NOT NULL CHECK (radius_meters > 0),
    boundary_polygon JSONB, -- For complex shapes
    is_active BOOLEAN NOT NULL DEFAULT true,
    attendance_required BOOLEAN NOT NULL DEFAULT true,
    check_in_enabled BOOLEAN NOT NULL DEFAULT true,
    check_out_enabled BOOLEAN NOT NULL DEFAULT true,
    break_tracking BOOLEAN NOT NULL DEFAULT false,
    wifi_ssids TEXT[] DEFAULT '{}',
    allowed_departments UUID[] DEFAULT '{}',
    time_zone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    working_hours JSONB DEFAULT '{"monday": {"start": "09:00", "end": "18:00"}}',
    emergency_override BOOLEAN DEFAULT false,
    address VARCHAR(500),
    address_ru VARCHAR(500),
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Task 5: Mobile Performance Metrics
CREATE TABLE IF NOT EXISTS mobile_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES mobile_sessions(id) ON DELETE CASCADE,
    user_id UUID,
    metric_type VARCHAR(30) NOT NULL CHECK (metric_type IN (
        'app_launch', 'page_load', 'api_response', 'sync_performance',
        'crash_report', 'memory_usage', 'battery_drain', 'network_usage'
    )),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10, 3),
    metric_unit VARCHAR(20) DEFAULT 'ms',
    additional_data JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    network_info JSONB DEFAULT '{}',
    app_state VARCHAR(20) DEFAULT 'foreground' CHECK (app_state IN ('foreground', 'background', 'suspended')),
    user_action VARCHAR(100),
    screen_name VARCHAR(100),
    error_details TEXT,
    stack_trace TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Attendance check-ins linked to geofencing
CREATE TABLE IF NOT EXISTS mobile_attendance_checkins (
    checkin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    session_id UUID REFERENCES mobile_sessions(id),
    boundary_id UUID REFERENCES geofencing_boundaries(boundary_id),
    checkin_type VARCHAR(20) NOT NULL CHECK (checkin_type IN ('check_in', 'check_out', 'break_start', 'break_end')),
    checkin_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(6, 2),
    is_within_boundary BOOLEAN NOT NULL,
    distance_from_center DECIMAL(8, 2),
    method VARCHAR(20) DEFAULT 'gps' CHECK (method IN ('gps', 'wifi', 'manual', 'beacon')),
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'overridden')),
    photo_url VARCHAR(500),
    notes TEXT,
    notes_ru TEXT,
    override_reason TEXT,
    approved_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Push notification delivery tracking
CREATE TABLE IF NOT EXISTS push_notification_delivery (
    delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES push_notification_queue(notification_id) ON DELETE CASCADE,
    session_id UUID REFERENCES mobile_sessions(id),
    user_id UUID NOT NULL,
    delivery_status VARCHAR(20) NOT NULL CHECK (delivery_status IN ('sent', 'delivered', 'opened', 'dismissed', 'failed')),
    delivery_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    opened_timestamp TIMESTAMPTZ,
    dismissed_timestamp TIMESTAMPTZ,
    failure_reason TEXT,
    device_response JSONB DEFAULT '{}'
);

-- INDEXES for performance
CREATE INDEX IF NOT EXISTS idx_mobile_sessions_user_active ON mobile_sessions(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_mobile_sessions_device_enhanced ON mobile_sessions(device_id, device_type);

CREATE INDEX IF NOT EXISTS idx_push_queue_status_priority ON push_notification_queue(status, priority, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_push_queue_user ON push_notification_queue(user_id, notification_type);
CREATE INDEX IF NOT EXISTS idx_push_queue_target ON push_notification_queue USING GIN(target_ids);

CREATE INDEX IF NOT EXISTS idx_offline_sync_session ON mobile_offline_sync(session_id, sync_type);
CREATE INDEX IF NOT EXISTS idx_offline_sync_user_status ON mobile_offline_sync(user_id, sync_status);
CREATE INDEX IF NOT EXISTS idx_offline_sync_timestamp ON mobile_offline_sync(last_sync_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_geofencing_location ON geofencing_boundaries(center_latitude, center_longitude);
CREATE INDEX IF NOT EXISTS idx_geofencing_active ON geofencing_boundaries(is_active, location_type);

CREATE INDEX IF NOT EXISTS idx_performance_session ON mobile_performance_metrics(session_id, metric_type);
CREATE INDEX IF NOT EXISTS idx_performance_timestamp ON mobile_performance_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_performance_user ON mobile_performance_metrics(user_id, metric_type);

CREATE INDEX IF NOT EXISTS idx_checkins_user_date ON mobile_attendance_checkins(user_id, DATE(checkin_timestamp));
CREATE INDEX IF NOT EXISTS idx_checkins_boundary ON mobile_attendance_checkins(boundary_id, checkin_type);
CREATE INDEX IF NOT EXISTS idx_checkins_verification ON mobile_attendance_checkins(verification_status, checkin_timestamp);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_status ON push_notification_delivery(notification_id, delivery_status);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_user ON push_notification_delivery(user_id, delivery_timestamp);

-- Sample data for testing
-- Update existing mobile_sessions with enhanced data
UPDATE mobile_sessions 
SET device_fingerprint = '{"browser": "Safari", "screen": "1179x2556", "timezone": "Europe/Moscow"}'::jsonb,
    device_type = 'ios',
    device_model = 'iPhone 14 Pro',
    os_version = '17.2.1',
    security_level = 'biometric',
    biometric_enabled = true,
    location_permission = true,
    notification_permission = true
WHERE device_id LIKE '%IOS%' OR platform = 'ios'
LIMIT 1;

UPDATE mobile_sessions 
SET device_fingerprint = '{"browser": "Chrome", "screen": "1080x2400", "timezone": "Europe/Moscow"}'::jsonb,
    device_type = 'android',
    device_model = 'Samsung Galaxy S23',
    os_version = '14.0',
    security_level = 'standard',
    biometric_enabled = false,
    location_permission = true,
    notification_permission = true
WHERE device_id LIKE '%ANDROID%' OR platform = 'android'
LIMIT 1;

-- Sample geofencing boundaries
INSERT INTO geofencing_boundaries (location_name, location_name_ru, location_type, center_latitude, center_longitude, radius_meters, is_active, attendance_required, address, address_ru, working_hours) VALUES
('TechnoService HQ', 'ТехноСервис Главный Офис', 'office', 55.7558, 37.6176, 100, true, true, 'Red Square, 1, Moscow', 'Красная площадь, 1, Москва', '{"monday": {"start": "09:00", "end": "18:00"}, "tuesday": {"start": "09:00", "end": "18:00"}, "wednesday": {"start": "09:00", "end": "18:00"}, "thursday": {"start": "09:00", "end": "18:00"}, "friday": {"start": "09:00", "end": "17:00"}}'),
('Service Center North', 'Сервисный Центр Север', 'service_center', 55.8304, 37.6329, 150, true, true, 'Sokolnicheskaya 45, Moscow', 'Сокольническая 45, Москва', '{"monday": {"start": "08:00", "end": "20:00"}, "tuesday": {"start": "08:00", "end": "20:00"}, "wednesday": {"start": "08:00", "end": "20:00"}, "thursday": {"start": "08:00", "end": "20:00"}, "friday": {"start": "08:00", "end": "20:00"}, "saturday": {"start": "10:00", "end": "18:00"}}'),
('Warehouse South', 'Склад Южный', 'warehouse', 55.6037, 37.7201, 200, true, true, 'Industrial Zone 15, Moscow', 'Промзона 15, Москва', '{"monday": {"start": "06:00", "end": "22:00"}, "tuesday": {"start": "06:00", "end": "22:00"}, "wednesday": {"start": "06:00", "end": "22:00"}, "thursday": {"start": "06:00", "end": "22:00"}, "friday": {"start": "06:00", "end": "22:00"}}');

-- Sample push notifications
INSERT INTO push_notification_queue (user_id, target_type, notification_type, title, message, title_ru, message_ru, priority, payload, deep_link) VALUES
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1), 'individual', 'schedule_change', 'Schedule Updated', 'Your shift for tomorrow has been changed to 10:00-19:00', 'Расписание обновлено', 'Ваша смена на завтра изменена на 10:00-19:00', 'high', '{"shift_id": "12345", "new_start": "10:00", "new_end": "19:00"}', 'wfm://schedule/details/12345'),
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), 'individual', 'break_reminder', 'Break Time', 'Time for your scheduled break', 'Время перерыва', 'Время вашего запланированного перерыва', 'normal', '{"break_duration": 15}', 'wfm://break/start'),
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), 'individual', 'overtime_alert', 'Overtime Alert', 'You are approaching overtime hours', 'Предупреждение о сверхурочных', 'Вы приближаетесь к сверхурочным часам', 'high', '{"current_hours": 7.5, "limit": 8}', 'wfm://timesheet/current');

-- Sample offline sync records
INSERT INTO mobile_offline_sync (session_id, user_id, sync_type, sync_status, items_to_sync, items_synced, data_size_kb, connection_type, battery_level) VALUES
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1), 'schedule_sync', 'completed', 25, 25, 156, 'wifi', 85),
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), 'timesheet_sync', 'in_progress', 12, 8, 89, '4g', 67),
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), 'full_sync', 'failed', 150, 0, 0, '3g', 23);

-- Sample performance metrics
INSERT INTO mobile_performance_metrics (session_id, user_id, metric_type, metric_name, metric_value, metric_unit, additional_data, screen_name) VALUES
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1), 'app_launch', 'cold_start', 2.1, 'seconds', '{"memory_usage": 45, "cpu_usage": 12}', 'login'),
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), 'api_response', 'schedule_load', 456, 'ms', '{"endpoint": "/api/v1/schedule", "status": 200}', 'schedule'),
((SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), (SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), 'page_load', 'timesheet_view', 1.8, 'seconds', '{"data_rows": 30, "charts": 3}', 'timesheet');

-- Sample attendance check-ins
INSERT INTO mobile_attendance_checkins (user_id, session_id, boundary_id, checkin_type, location_latitude, location_longitude, location_accuracy, is_within_boundary, distance_from_center, method, verification_status) VALUES
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1), (SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1), (SELECT boundary_id FROM geofencing_boundaries LIMIT 1), 'check_in', 55.7559, 37.6177, 5.2, true, 15.3, 'gps', 'verified'),
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), (SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 1), (SELECT boundary_id FROM geofencing_boundaries LIMIT 1 OFFSET 1), 'check_in', 55.8305, 37.6330, 8.1, true, 23.7, 'gps', 'verified'),
((SELECT user_id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), (SELECT id FROM mobile_sessions WHERE is_active = true LIMIT 1 OFFSET 2), (SELECT boundary_id FROM geofencing_boundaries LIMIT 1 OFFSET 2), 'check_out', 55.6038, 37.7202, 12.4, true, 45.2, 'wifi', 'pending');

-- Views for mobile app workflows
CREATE OR REPLACE VIEW mobile_active_sessions AS
SELECT 
    ms.id as session_id,
    ms.user_id,
    ms.device_type,
    ms.device_model,
    ms.app_version,
    ms.last_activity,
    ms.security_level,
    ms.biometric_enabled,
    CASE 
        WHEN ms.last_activity > CURRENT_TIMESTAMP - INTERVAL '5 minutes' THEN 'active'
        WHEN ms.last_activity > CURRENT_TIMESTAMP - INTERVAL '30 minutes' THEN 'idle'
        ELSE 'inactive'
    END as session_status
FROM mobile_sessions ms
WHERE ms.is_active = true
  AND ms.logout_timestamp IS NULL;

CREATE OR REPLACE VIEW mobile_notification_summary AS
SELECT 
    pnq.user_id,
    COUNT(*) FILTER (WHERE pnq.status = 'pending') as pending_notifications,
    COUNT(*) FILTER (WHERE pnq.status = 'sent') as sent_notifications,
    COUNT(*) FILTER (WHERE pnq.priority = 'urgent') as urgent_notifications,
    MAX(pnq.created_at) as last_notification
FROM push_notification_queue pnq
WHERE pnq.created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY pnq.user_id;

CREATE OR REPLACE VIEW mobile_geofencing_status AS
SELECT 
    gb.boundary_id,
    gb.location_name,
    gb.location_name_ru,
    gb.location_type,
    COUNT(mac.checkin_id) FILTER (WHERE mac.checkin_timestamp::date = CURRENT_DATE) as todays_checkins,
    COUNT(mac.checkin_id) FILTER (WHERE mac.checkin_type = 'check_in' AND mac.checkin_timestamp::date = CURRENT_DATE) as todays_checkins_in,
    COUNT(mac.checkin_id) FILTER (WHERE mac.checkin_type = 'check_out' AND mac.checkin_timestamp::date = CURRENT_DATE) as todays_checkins_out,
    AVG(mac.distance_from_center) FILTER (WHERE mac.checkin_timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days') as avg_distance_week
FROM geofencing_boundaries gb
LEFT JOIN mobile_attendance_checkins mac ON gb.boundary_id = mac.boundary_id
WHERE gb.is_active = true
GROUP BY gb.boundary_id, gb.location_name, gb.location_name_ru, gb.location_type;

-- Performance optimization functions
CREATE OR REPLACE FUNCTION cleanup_old_mobile_data()
RETURNS void AS $$
BEGIN
    -- Clean up old sessions (older than 90 days)
    DELETE FROM mobile_sessions 
    WHERE logout_timestamp < CURRENT_TIMESTAMP - INTERVAL '90 days'
       OR (is_active = false AND login_time < CURRENT_TIMESTAMP - INTERVAL '90 days');
    
    -- Clean up old performance metrics (older than 30 days)
    DELETE FROM mobile_performance_metrics 
    WHERE timestamp < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    -- Clean up old notifications (older than 60 days)
    DELETE FROM push_notification_queue 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '60 days';
    
    -- Clean up old sync records (older than 30 days)
    DELETE FROM mobile_offline_sync 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_activity on mobile_sessions
CREATE OR REPLACE FUNCTION update_mobile_session_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE mobile_sessions 
    SET last_activity = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_session_activity
    AFTER INSERT ON mobile_performance_metrics
    FOR EACH ROW
    WHEN (NEW.session_id IS NOT NULL)
    EXECUTE FUNCTION update_mobile_session_activity();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO wfm_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO wfm_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_user;

-- Comments for documentation
COMMENT ON TABLE mobile_sessions IS 'Enhanced mobile session management with device fingerprinting and security levels (Task 1)';
COMMENT ON TABLE push_notification_queue IS 'Real-time push notification management system with multi-language support (Task 2)';
COMMENT ON TABLE mobile_offline_sync IS 'Mobile offline synchronization tracking and conflict resolution (Task 3)';
COMMENT ON TABLE geofencing_boundaries IS 'Location-based attendance verification boundaries (Task 4)';
COMMENT ON TABLE mobile_performance_metrics IS 'Mobile app performance monitoring and analytics (Task 5)';
COMMENT ON TABLE mobile_attendance_checkins IS 'GPS-based attendance verification linked to geofencing';
COMMENT ON TABLE push_notification_delivery IS 'Push notification delivery tracking and analytics';

-- Success message
SELECT 'Mobile Support Infrastructure (Schema 060) created successfully' as status,
       'Tasks 1-5 completed: Enhanced Sessions, Push Notifications, Offline Sync, Geofencing, Performance Metrics' as details;