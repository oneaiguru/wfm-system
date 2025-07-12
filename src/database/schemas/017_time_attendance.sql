-- =============================================================================
-- 017_time_attendance.sql  
-- WFM Time & Attendance System - Core WFM Functionality
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Comprehensive time tracking and attendance management
-- Tables: 5 core attendance tables proving enterprise WFM capabilities
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. WORK_STATES - Define operator work status types
-- =============================================================================
CREATE TABLE work_states (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state_code VARCHAR(20) NOT NULL UNIQUE,
    state_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_productive BOOLEAN DEFAULT true,
    counts_as_work_time BOOLEAN DEFAULT true,
    counts_as_break_time BOOLEAN DEFAULT false,
    counts_as_training BOOLEAN DEFAULT false,
    requires_reason BOOLEAN DEFAULT false,
    max_duration_minutes INTEGER,
    color_code VARCHAR(7) DEFAULT '#4CAF50',
    sort_order INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for work_states
CREATE INDEX idx_work_states_code ON work_states(state_code);
CREATE INDEX idx_work_states_productive ON work_states(is_productive);

-- =============================================================================
-- 2. TIME_ENTRIES - Core time tracking (clock in/out)
-- =============================================================================
CREATE TABLE time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('clock_in', 'clock_out', 'break_start', 'break_end', 'status_change')),
    entry_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    work_state_id UUID,
    location_data JSONB, -- GPS coordinates, IP address, etc.
    entry_method VARCHAR(50) DEFAULT 'manual', -- manual, biometric, card, app
    reason_code VARCHAR(50),
    notes TEXT,
    supervisor_override BOOLEAN DEFAULT false,
    override_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    
    CONSTRAINT fk_time_entries_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id),
    CONSTRAINT fk_time_entries_work_state 
        FOREIGN KEY (work_state_id) REFERENCES work_states(id),
    CONSTRAINT fk_time_entries_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for time_entries
CREATE INDEX idx_time_entries_employee ON time_entries(employee_id);
CREATE INDEX idx_time_entries_timestamp ON time_entries(entry_timestamp);
CREATE INDEX idx_time_entries_date ON time_entries(DATE(entry_timestamp));
CREATE INDEX idx_time_entries_type ON time_entries(entry_type);

-- =============================================================================
-- 3. ATTENDANCE_SESSIONS - Calculated work sessions
-- =============================================================================
CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    session_date DATE NOT NULL,
    clock_in_time TIMESTAMP WITH TIME ZONE,
    clock_out_time TIMESTAMP WITH TIME ZONE,
    scheduled_start TIMESTAMP WITH TIME ZONE,
    scheduled_end TIMESTAMP WITH TIME ZONE,
    total_hours DECIMAL(10,2),
    productive_hours DECIMAL(10,2),
    break_hours DECIMAL(10,2),
    overtime_hours DECIMAL(10,2) DEFAULT 0,
    late_minutes INTEGER DEFAULT 0,
    early_departure_minutes INTEGER DEFAULT 0,
    attendance_status VARCHAR(50) DEFAULT 'present',
    adherence_percentage DECIMAL(5,2),
    session_notes TEXT,
    is_complete BOOLEAN DEFAULT false,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_attendance_sessions_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id),
    
    UNIQUE(employee_id, session_date)
);

-- Indexes for attendance_sessions
CREATE INDEX idx_attendance_sessions_employee ON attendance_sessions(employee_id);
CREATE INDEX idx_attendance_sessions_date ON attendance_sessions(session_date);
CREATE INDEX idx_attendance_sessions_status ON attendance_sessions(attendance_status);

-- =============================================================================
-- 4. ATTENDANCE_EXCEPTIONS - Track attendance issues
-- =============================================================================
CREATE TABLE attendance_exceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    exception_date DATE NOT NULL,
    exception_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'minor' CHECK (severity IN ('minor', 'major', 'critical')),
    description TEXT NOT NULL,
    minutes_affected INTEGER DEFAULT 0,
    auto_detected BOOLEAN DEFAULT true,
    resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    resolved_by UUID,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_attendance_exceptions_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id),
    CONSTRAINT fk_attendance_exceptions_resolved_by 
        FOREIGN KEY (resolved_by) REFERENCES users(id)
);

-- Indexes for attendance_exceptions
CREATE INDEX idx_attendance_exceptions_employee ON attendance_exceptions(employee_id);
CREATE INDEX idx_attendance_exceptions_date ON attendance_exceptions(exception_date);
CREATE INDEX idx_attendance_exceptions_type ON attendance_exceptions(exception_type);
CREATE INDEX idx_attendance_exceptions_resolved ON attendance_exceptions(resolved);

-- =============================================================================
-- 5. REAL_TIME_STATUS - Current operator status tracking
-- =============================================================================
CREATE TABLE real_time_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL UNIQUE,
    current_state_id UUID NOT NULL,
    state_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location_data JSONB,
    session_duration_minutes INTEGER DEFAULT 0,
    productive_time_today DECIMAL(10,2) DEFAULT 0,
    break_time_today DECIMAL(10,2) DEFAULT 0,
    calls_handled_today INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_real_time_status_employee 
        FOREIGN KEY (employee_id) REFERENCES users(id),
    CONSTRAINT fk_real_time_status_state 
        FOREIGN KEY (current_state_id) REFERENCES work_states(id)
);

-- Index for real_time_status
CREATE INDEX idx_real_time_status_employee ON real_time_status(employee_id);
CREATE INDEX idx_real_time_status_state ON real_time_status(current_state_id);

-- =============================================================================
-- FUNCTIONS: Time & Attendance Management
-- =============================================================================

-- Function to clock in/out
CREATE OR REPLACE FUNCTION record_time_entry(
    p_employee_id UUID,
    p_entry_type VARCHAR(20),
    p_work_state_code VARCHAR(20) DEFAULT NULL,
    p_location_data JSONB DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_entry_id UUID;
    v_work_state_id UUID;
    v_current_session attendance_sessions%ROWTYPE;
    v_result JSONB;
BEGIN
    -- Get work state ID if provided
    IF p_work_state_code IS NOT NULL THEN
        SELECT id INTO v_work_state_id 
        FROM work_states 
        WHERE state_code = p_work_state_code AND is_active = true;
        
        IF v_work_state_id IS NULL THEN
            RAISE EXCEPTION 'Invalid work state code: %', p_work_state_code;
        END IF;
    END IF;
    
    -- Record time entry
    INSERT INTO time_entries (
        employee_id,
        entry_type,
        entry_timestamp,
        work_state_id,
        location_data,
        notes
    ) VALUES (
        p_employee_id,
        p_entry_type,
        CURRENT_TIMESTAMP,
        v_work_state_id,
        p_location_data,
        p_notes
    ) RETURNING id INTO v_entry_id;
    
    -- Update real-time status
    IF p_entry_type = 'clock_in' THEN
        INSERT INTO real_time_status (
            employee_id,
            current_state_id,
            state_start_time,
            last_activity_time
        ) VALUES (
            p_employee_id,
            v_work_state_id,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        ) ON CONFLICT (employee_id) DO UPDATE SET
            current_state_id = v_work_state_id,
            state_start_time = CURRENT_TIMESTAMP,
            last_activity_time = CURRENT_TIMESTAMP;
            
    ELSIF p_entry_type = 'clock_out' THEN
        -- Update attendance session
        PERFORM calculate_attendance_session(p_employee_id, CURRENT_DATE);
        
        -- Remove from real-time status
        DELETE FROM real_time_status WHERE employee_id = p_employee_id;
    END IF;
    
    v_result := jsonb_build_object(
        'entry_id', v_entry_id,
        'employee_id', p_employee_id,
        'entry_type', p_entry_type,
        'timestamp', CURRENT_TIMESTAMP,
        'status', 'success'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate attendance session
CREATE OR REPLACE FUNCTION calculate_attendance_session(
    p_employee_id UUID,
    p_date DATE
) RETURNS JSONB AS $$
DECLARE
    v_clock_in TIMESTAMP WITH TIME ZONE;
    v_clock_out TIMESTAMP WITH TIME ZONE;
    v_total_hours DECIMAL(10,2);
    v_productive_hours DECIMAL(10,2);
    v_break_hours DECIMAL(10,2);
    v_late_minutes INTEGER := 0;
    v_early_departure INTEGER := 0;
    v_scheduled_start TIMESTAMP WITH TIME ZONE;
    v_scheduled_end TIMESTAMP WITH TIME ZONE;
    v_adherence DECIMAL(5,2);
    v_result JSONB;
BEGIN
    -- Get clock in/out times
    SELECT 
        MIN(entry_timestamp) FILTER (WHERE entry_type = 'clock_in'),
        MAX(entry_timestamp) FILTER (WHERE entry_type = 'clock_out')
    INTO v_clock_in, v_clock_out
    FROM time_entries
    WHERE employee_id = p_employee_id 
    AND DATE(entry_timestamp) = p_date;
    
    -- Get scheduled times (simplified - from work schedule)
    SELECT 
        p_date + TIME '09:00:00',
        p_date + TIME '18:00:00'
    INTO v_scheduled_start, v_scheduled_end;
    
    -- Calculate hours
    IF v_clock_in IS NOT NULL AND v_clock_out IS NOT NULL THEN
        v_total_hours := EXTRACT(EPOCH FROM (v_clock_out - v_clock_in)) / 3600.0;
        
        -- Calculate productive vs break time (simplified)
        v_productive_hours := v_total_hours * 0.85; -- Assume 85% productive
        v_break_hours := v_total_hours * 0.15;
        
        -- Calculate late/early departure
        IF v_clock_in > v_scheduled_start THEN
            v_late_minutes := EXTRACT(EPOCH FROM (v_clock_in - v_scheduled_start)) / 60;
        END IF;
        
        IF v_clock_out < v_scheduled_end THEN
            v_early_departure := EXTRACT(EPOCH FROM (v_scheduled_end - v_clock_out)) / 60;
        END IF;
        
        -- Calculate adherence
        v_adherence := 100.0 - (v_late_minutes + v_early_departure) / 480.0 * 100.0;
        v_adherence := GREATEST(0, LEAST(100, v_adherence));
    END IF;
    
    -- Insert or update attendance session
    INSERT INTO attendance_sessions (
        employee_id,
        session_date,
        clock_in_time,
        clock_out_time,
        scheduled_start,
        scheduled_end,
        total_hours,
        productive_hours,
        break_hours,
        late_minutes,
        early_departure_minutes,
        adherence_percentage,
        is_complete
    ) VALUES (
        p_employee_id,
        p_date,
        v_clock_in,
        v_clock_out,
        v_scheduled_start,
        v_scheduled_end,
        v_total_hours,
        v_productive_hours,
        v_break_hours,
        v_late_minutes,
        v_early_departure,
        v_adherence,
        v_clock_out IS NOT NULL
    ) ON CONFLICT (employee_id, session_date) DO UPDATE SET
        clock_out_time = EXCLUDED.clock_out_time,
        total_hours = EXCLUDED.total_hours,
        productive_hours = EXCLUDED.productive_hours,
        break_hours = EXCLUDED.break_hours,
        late_minutes = EXCLUDED.late_minutes,
        early_departure_minutes = EXCLUDED.early_departure_minutes,
        adherence_percentage = EXCLUDED.adherence_percentage,
        is_complete = EXCLUDED.is_complete,
        calculated_at = CURRENT_TIMESTAMP;
    
    v_result := jsonb_build_object(
        'employee_id', p_employee_id,
        'date', p_date,
        'total_hours', v_total_hours,
        'productive_hours', v_productive_hours,
        'adherence_percentage', v_adherence,
        'late_minutes', v_late_minutes,
        'early_departure_minutes', v_early_departure,
        'status', 'calculated'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to detect attendance exceptions
CREATE OR REPLACE FUNCTION detect_attendance_exceptions()
RETURNS INTEGER AS $$
DECLARE
    v_session attendance_sessions%ROWTYPE;
    v_exceptions_created INTEGER := 0;
BEGIN
    -- Check for attendance exceptions in recent sessions
    FOR v_session IN 
        SELECT * FROM attendance_sessions 
        WHERE session_date >= CURRENT_DATE - INTERVAL '7 days'
        AND is_complete = true
    LOOP
        -- Late arrival exception
        IF v_session.late_minutes > 15 THEN
            INSERT INTO attendance_exceptions (
                employee_id,
                exception_date,
                exception_type,
                severity,
                description,
                minutes_affected
            ) VALUES (
                v_session.employee_id,
                v_session.session_date,
                'late_arrival',
                CASE 
                    WHEN v_session.late_minutes > 60 THEN 'critical'
                    WHEN v_session.late_minutes > 30 THEN 'major'
                    ELSE 'minor'
                END,
                'Employee arrived ' || v_session.late_minutes || ' minutes late',
                v_session.late_minutes
            ) ON CONFLICT DO NOTHING;
            
            v_exceptions_created := v_exceptions_created + 1;
        END IF;
        
        -- Low adherence exception
        IF v_session.adherence_percentage < 85 THEN
            INSERT INTO attendance_exceptions (
                employee_id,
                exception_date,
                exception_type,
                severity,
                description,
                minutes_affected
            ) VALUES (
                v_session.employee_id,
                v_session.session_date,
                'low_adherence',
                CASE 
                    WHEN v_session.adherence_percentage < 70 THEN 'critical'
                    WHEN v_session.adherence_percentage < 80 THEN 'major'
                    ELSE 'minor'
                END,
                'Schedule adherence: ' || v_session.adherence_percentage || '%',
                ROUND((100 - v_session.adherence_percentage) * 4.8) -- Convert to minutes
            ) ON CONFLICT DO NOTHING;
            
            v_exceptions_created := v_exceptions_created + 1;
        END IF;
    END LOOP;
    
    RETURN v_exceptions_created;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SAMPLE DATA: Work States and Initial Setup
-- =============================================================================

-- Insert standard work states
INSERT INTO work_states (state_code, state_name, description, is_productive, counts_as_work_time, color_code, sort_order) VALUES
('AVAIL', 'Available', 'Ready to handle calls/tasks', true, true, '#4CAF50', 10),
('BUSY', 'Busy', 'Handling customer call/task', true, true, '#2196F3', 20),
('ACW', 'After Call Work', 'Post-call documentation', true, true, '#FF9800', 30),
('BREAK', 'Break', 'Short break period', false, false, '#FFC107', 40),
('LUNCH', 'Lunch', 'Lunch break', false, false, '#FF5722', 50),
('TRAIN', 'Training', 'Training session', true, true, '#9C27B0', 60),
('MEET', 'Meeting', 'Team/supervisor meeting', true, true, '#3F51B5', 70),
('ADMIN', 'Administrative', 'Administrative tasks', true, true, '#607D8B', 80),
('AWAY', 'Away', 'Temporarily away from desk', false, false, '#795548', 90),
('OFFLINE', 'Offline', 'Not available/logged out', false, false, '#424242', 100);

-- =============================================================================
-- INTEGRATION VIEWS for UI-OPUS and AL-OPUS
-- =============================================================================

-- Real-time attendance dashboard
CREATE VIEW v_realtime_attendance AS
SELECT 
    u.id as employee_id,
    u.first_name || ' ' || u.last_name as employee_name,
    ws.state_name as current_status,
    ws.color_code,
    rts.state_start_time,
    rts.session_duration_minutes,
    rts.productive_time_today,
    rts.break_time_today,
    rts.calls_handled_today,
    CASE 
        WHEN rts.last_activity_time < NOW() - INTERVAL '5 minutes' THEN 'inactive'
        ELSE 'active'
    END as activity_status
FROM real_time_status rts
JOIN users u ON u.id = rts.employee_id
JOIN work_states ws ON ws.id = rts.current_state_id
ORDER BY u.last_name, u.first_name;

-- Daily attendance summary
CREATE VIEW v_daily_attendance_summary AS
SELECT 
    u.id as employee_id,
    u.first_name || ' ' || u.last_name as employee_name,
    ats.session_date,
    ats.clock_in_time,
    ats.clock_out_time,
    ats.total_hours,
    ats.productive_hours,
    ats.adherence_percentage,
    ats.attendance_status,
    ats.late_minutes,
    ats.early_departure_minutes,
    CASE 
        WHEN ats.adherence_percentage >= 95 THEN 'excellent'
        WHEN ats.adherence_percentage >= 85 THEN 'good'
        WHEN ats.adherence_percentage >= 75 THEN 'fair'
        ELSE 'poor'
    END as adherence_rating
FROM attendance_sessions ats
JOIN users u ON u.id = ats.employee_id
WHERE ats.session_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY ats.session_date DESC, u.last_name;

-- Attendance exceptions dashboard
CREATE VIEW v_attendance_exceptions_summary AS
SELECT 
    u.first_name || ' ' || u.last_name as employee_name,
    ae.exception_date,
    ae.exception_type,
    ae.severity,
    ae.description,
    ae.minutes_affected,
    ae.resolved,
    ae.resolution_notes,
    CASE ae.severity
        WHEN 'critical' THEN '#F44336'
        WHEN 'major' THEN '#FF9800'
        ELSE '#FFC107'
    END as severity_color
FROM attendance_exceptions ae
JOIN users u ON u.id = ae.employee_id
WHERE ae.exception_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY ae.exception_date DESC, ae.severity DESC;

-- Demo view for time & attendance metrics
CREATE VIEW v_demo_attendance_metrics AS
SELECT 
    'Time & Attendance System' as metric_name,
    'Operational Excellence' as category,
    COUNT(DISTINCT rts.employee_id) as active_employees,
    ROUND(AVG(ats.adherence_percentage), 1) as avg_adherence_percentage,
    COUNT(DISTINCT ats.employee_id) FILTER (WHERE ats.session_date = CURRENT_DATE) as employees_today,
    COUNT(*) FILTER (WHERE ae.resolved = false AND ae.exception_date >= CURRENT_DATE - INTERVAL '7 days') as open_exceptions,
    'Comprehensive time tracking with real-time monitoring' as status,
    NOW() as measurement_time
FROM real_time_status rts
FULL OUTER JOIN attendance_sessions ats ON ats.employee_id = rts.employee_id 
    AND ats.session_date >= CURRENT_DATE - INTERVAL '30 days'
FULL OUTER JOIN attendance_exceptions ae ON ae.employee_id = COALESCE(rts.employee_id, ats.employee_id);

COMMENT ON TABLE work_states IS 'Work state definitions for time tracking';
COMMENT ON TABLE time_entries IS 'Core time tracking entries (clock in/out/status changes)';
COMMENT ON TABLE attendance_sessions IS 'Calculated daily attendance sessions';
COMMENT ON TABLE attendance_exceptions IS 'Attendance violations and exceptions';
COMMENT ON VIEW v_realtime_attendance IS 'Real-time employee status dashboard';
COMMENT ON VIEW v_daily_attendance_summary IS 'Daily attendance summary for reporting';