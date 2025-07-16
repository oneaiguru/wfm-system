-- =============================================================================
-- 010_monthly_intraday_activity_planning.sql
-- EXACT BDD Implementation: Monthly Intraday Activity Planning and Timetable Management
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 10-monthly-intraday-activity-planning.feature (406 lines)
-- Purpose: Comprehensive intraday activity planning, timetable management, and notifications
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. INTRADAY ACTIVITIES
-- =============================================================================

-- Core activity management from BDD lines 81-99, 116-131
CREATE TABLE intraday_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id VARCHAR(50) NOT NULL UNIQUE,
    activity_name VARCHAR(200) NOT NULL,
    activity_description TEXT,
    
    -- Activity classification from BDD lines 120-127
    activity_type VARCHAR(30) NOT NULL CHECK (activity_type IN (
        'work_attendance', 'downtime', 'project_assignment', 'lunch_break', 
        'short_break', 'training', 'meeting', 'event'
    )),
    activity_category VARCHAR(30) DEFAULT 'operational' CHECK (activity_category IN (
        'operational', 'administrative', 'development', 'break', 'project'
    )),
    
    -- Duration and timing from BDD lines 137-141
    default_duration_minutes INTEGER NOT NULL,
    minimum_duration_minutes INTEGER DEFAULT 15,
    maximum_duration_minutes INTEGER DEFAULT 480,
    allows_interruption BOOLEAN DEFAULT false,
    
    -- Scheduling rules from BDD lines 142-149
    regularity VARCHAR(20) DEFAULT 'on_demand' CHECK (regularity IN (
        'daily', 'weekly', 'monthly', 'on_demand'
    )),
    participation_type VARCHAR(20) DEFAULT 'individual' CHECK (participation_type IN (
        'individual', 'group', 'team', 'department'
    )),
    combine_with_others BOOLEAN DEFAULT true,
    find_common_time BOOLEAN DEFAULT false,
    
    -- Service impact from BDD lines 128-131
    affects_service_level BOOLEAN DEFAULT true,
    service_level_impact DECIMAL(5,3) DEFAULT 1.0, -- Impact coefficient
    requires_replacement BOOLEAN DEFAULT true,
    
    -- Skills and assignments from BDD lines 100-115
    required_skills JSONB DEFAULT '[]',
    skill_priority JSONB DEFAULT '{}', -- Primary, secondary skill assignments
    
    -- Notifications from BDD lines 12-25
    notification_required BOOLEAN DEFAULT false,
    notification_timing_minutes INTEGER DEFAULT 15,
    notification_methods JSONB DEFAULT '["system"]',
    
    -- Business rules
    requires_approval BOOLEAN DEFAULT false,
    cancellation_allowed BOOLEAN DEFAULT true,
    min_advance_notice_minutes INTEGER DEFAULT 60,
    max_concurrent_assignments INTEGER DEFAULT 1,
    
    -- Cost and productivity from BDD lines 210-222
    cost_rate_multiplier DECIMAL(5,3) DEFAULT 1.0,
    productivity_credit BOOLEAN DEFAULT true,
    billable_activity BOOLEAN DEFAULT true,
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. ACTIVITY TEMPLATES
-- =============================================================================

-- Activity templates for recurring activities from BDD lines 85-99, 132-150
CREATE TABLE activity_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id VARCHAR(50) NOT NULL UNIQUE,
    template_name VARCHAR(200) NOT NULL,
    template_description TEXT,
    
    -- Template configuration from BDD lines 85-90
    planning_criteria VARCHAR(100), -- e.g., "80/20 format (80% calls in 20 seconds)"
    break_optimization_enabled BOOLEAN DEFAULT true,
    lunch_scheduling_automated BOOLEAN DEFAULT true,
    
    -- Multi-skill optimization from BDD lines 100-115
    supports_multiskill BOOLEAN DEFAULT false,
    skill_distribution_rules JSONB DEFAULT '{}',
    assignment_priority_rules JSONB DEFAULT '{}',
    
    -- Load distribution from BDD lines 92-98
    distribution_method VARCHAR(30) DEFAULT 'forecast_based' CHECK (distribution_method IN (
        'forecast_based', 'equal_distribution', 'skill_weighted', 'manual'
    )),
    optimization_targets JSONB DEFAULT '{}',
    
    -- Template activities
    included_activities JSONB NOT NULL, -- Array of activity configurations
    default_break_rules JSONB DEFAULT '{}',
    
    -- Usage and effectiveness
    usage_count INTEGER DEFAULT 0,
    last_used_date DATE,
    effectiveness_score DECIMAL(3,2),
    
    -- Template metadata
    is_public BOOLEAN DEFAULT false,
    organization_scope VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. COVERAGE IMPACTS
-- =============================================================================

-- Coverage impact analysis from BDD lines 168-181, 312-335
CREATE TABLE coverage_impacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    impact_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Coverage measurement period
    measurement_date DATE NOT NULL,
    measurement_hour INTEGER CHECK (measurement_hour >= 0 AND measurement_hour <= 23),
    measurement_interval INTEGER DEFAULT 15, -- 15-minute intervals
    
    -- Coverage metrics from BDD lines 316-322
    required_operators INTEGER NOT NULL,
    scheduled_operators INTEGER NOT NULL,
    available_operators INTEGER NOT NULL,
    coverage_percentage DECIMAL(5,2) NOT NULL,
    
    -- Service level impact from BDD lines 172-176
    service_level_target DECIMAL(5,2) DEFAULT 80.0,
    projected_service_level DECIMAL(5,2),
    service_level_status VARCHAR(20) DEFAULT 'optimal' CHECK (service_level_status IN (
        'optimal', 'adequate', 'shortage', 'surplus'
    )),
    
    -- Skill-specific coverage from BDD lines 319
    skill_group VARCHAR(100),
    skill_coverage_percentage DECIMAL(5,2),
    skilled_operators_required INTEGER,
    skilled_operators_available INTEGER,
    
    -- Department and location
    department VARCHAR(100),
    location VARCHAR(100),
    
    -- Coverage analysis from BDD lines 323-334
    coverage_gap_minutes INTEGER DEFAULT 0,
    surplus_minutes INTEGER DEFAULT 0,
    utilization_percentage DECIMAL(5,2),
    
    -- Recommendations from BDD lines 330-334
    recommended_action VARCHAR(50),
    recommended_adjustment INTEGER, -- Number of operators
    automation_applied BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. ABSENCE REASONS
-- =============================================================================

-- Absence reasons configuration from BDD lines 43-80
CREATE TABLE absence_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reason_id VARCHAR(50) NOT NULL UNIQUE,
    reason_name VARCHAR(200) NOT NULL,
    reason_code VARCHAR(10) NOT NULL UNIQUE,
    
    -- Reason configuration from BDD lines 48-54
    is_active BOOLEAN DEFAULT true,
    include_in_absenteeism_report BOOLEAN DEFAULT true,
    reason_comments TEXT,
    
    -- Localization support
    reason_name_ru VARCHAR(200),
    reason_name_en VARCHAR(200),
    
    -- Absence impact from BDD lines 364-383
    planned_absence BOOLEAN DEFAULT false,
    requires_advance_notice BOOLEAN DEFAULT true,
    requires_replacement BOOLEAN DEFAULT true,
    affects_productivity BOOLEAN DEFAULT true,
    
    -- Business rules
    requires_documentation BOOLEAN DEFAULT false,
    max_consecutive_days INTEGER,
    max_annual_days INTEGER,
    approval_required BOOLEAN DEFAULT false,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    last_used_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. TIMETABLE SCHEDULES
-- =============================================================================

-- Detailed timetable schedules from BDD lines 81-99, 182-195
CREATE TABLE timetable_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timetable_id VARCHAR(50) NOT NULL UNIQUE,
    timetable_name VARCHAR(200) NOT NULL,
    
    -- Schedule period from BDD lines 85-87
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    total_duration_minutes INTEGER NOT NULL,
    
    -- Employee assignment
    employee_id UUID NOT NULL,
    department VARCHAR(100),
    skill_group VARCHAR(100),
    
    -- Activity details from BDD lines 92-98
    primary_activity_id VARCHAR(50) NOT NULL,
    activity_assignments JSONB NOT NULL, -- Detailed time blocks
    
    -- Break scheduling from BDD lines 274-287
    total_break_minutes INTEGER DEFAULT 0,
    paid_break_minutes INTEGER DEFAULT 0,
    unpaid_break_minutes INTEGER DEFAULT 0,
    lunch_break_minutes INTEGER DEFAULT 60,
    
    -- Load and coverage from BDD lines 168-181
    expected_workload DECIMAL(8,2),
    coverage_target DECIMAL(5,2),
    utilization_target DECIMAL(5,2),
    
    -- Service level impact from BDD lines 128-131
    service_level_contribution DECIMAL(5,2),
    quality_target DECIMAL(5,2),
    
    -- Timetable status
    timetable_status VARCHAR(20) DEFAULT 'draft' CHECK (timetable_status IN (
        'draft', 'approved', 'active', 'completed', 'cancelled'
    )),
    requires_approval BOOLEAN DEFAULT false,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Change tracking from BDD lines 182-195
    original_timetable_id VARCHAR(50),
    change_reason TEXT,
    manual_adjustments_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (primary_activity_id) REFERENCES intraday_activities(activity_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (original_timetable_id) REFERENCES timetable_schedules(timetable_id) ON DELETE SET NULL,
    
    -- Ensure valid time range
    CHECK (end_time > start_time),
    CHECK (total_duration_minutes > 0)
);

-- =============================================================================
-- 6. NOTIFICATION CONFIGURATIONS
-- =============================================================================

-- Notification system from BDD lines 12-42
CREATE TABLE notification_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Event type configuration from BDD lines 16-22
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN (
        'break_reminder', 'lunch_reminder', 'meeting_reminder', 'training_start',
        'schedule_change', 'shift_start', 'system_alert'
    )),
    event_description TEXT,
    
    -- Recipients configuration from BDD line 16-22
    recipient_type VARCHAR(30) NOT NULL CHECK (recipient_type IN (
        'individual_employee', 'participants', 'affected_employees', 'trainees',
        'instructors', 'supervisors', 'administrators'
    )),
    
    -- Notification methods from BDD lines 16-22, 31-39
    notification_methods JSONB NOT NULL DEFAULT '["system"]',
    timing_minutes_before INTEGER NOT NULL,
    
    -- Global notification settings from BDD lines 31-41
    email_server VARCHAR(100),
    sms_gateway VARCHAR(100),
    mobile_push_service VARCHAR(100),
    retention_days INTEGER DEFAULT 30,
    escalation_attempts INTEGER DEFAULT 3,
    
    -- Quiet hours from BDD line 38
    quiet_hours_enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '08:00',
    
    -- Delivery tracking
    delivery_success_rate DECIMAL(5,2),
    average_delivery_time_seconds INTEGER,
    escalation_triggered_count INTEGER DEFAULT 0,
    
    -- Configuration metadata
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 7. PROJECT ASSIGNMENTS
-- =============================================================================

-- Project assignments from BDD lines 151-167
CREATE TABLE project_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Project details from BDD lines 154-158
    project_name VARCHAR(200) NOT NULL,
    project_type VARCHAR(30) NOT NULL CHECK (project_type IN (
        'outbound_calls', 'warm_leads', 'retention', 'survey', 'follow_up'
    )),
    project_priority INTEGER CHECK (project_priority >= 1 AND project_priority <= 100),
    
    -- Project timing from BDD lines 161
    project_start_date DATE NOT NULL,
    project_end_date DATE NOT NULL,
    
    -- Work plan from BDD lines 156-158
    target_calls INTEGER,
    average_call_duration_minutes INTEGER,
    work_plan_details JSONB,
    
    -- Resource allocation from BDD lines 162-164
    team_capacity_percentage DECIMAL(5,2),
    performance_target DECIMAL(8,2), -- Calls per hour
    quality_requirements DECIMAL(5,2), -- Accuracy percentage
    
    -- Employee assignment
    employee_id UUID NOT NULL,
    assignment_percentage DECIMAL(5,2) DEFAULT 100.0,
    skill_match_score DECIMAL(3,2),
    
    -- Assignment status
    assignment_status VARCHAR(20) DEFAULT 'assigned' CHECK (assignment_status IN (
        'assigned', 'active', 'completed', 'cancelled', 'on_hold'
    )),
    
    -- Performance tracking
    calls_completed INTEGER DEFAULT 0,
    quality_score DECIMAL(5,2),
    productivity_score DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    
    -- Ensure valid date range
    CHECK (project_end_date >= project_start_date)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Intraday activities queries
CREATE INDEX idx_intraday_activities_type ON intraday_activities(activity_type);
CREATE INDEX idx_intraday_activities_category ON intraday_activities(activity_category);
CREATE INDEX idx_intraday_activities_active ON intraday_activities(is_active) WHERE is_active = true;
CREATE INDEX idx_intraday_activities_regularity ON intraday_activities(regularity);
CREATE INDEX idx_intraday_activities_skills ON intraday_activities USING gin(required_skills);

-- Activity templates queries
CREATE INDEX idx_activity_templates_active ON activity_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_activity_templates_multiskill ON activity_templates(supports_multiskill) WHERE supports_multiskill = true;
CREATE INDEX idx_activity_templates_public ON activity_templates(is_public) WHERE is_public = true;
CREATE INDEX idx_activity_templates_usage ON activity_templates(usage_count);

-- Coverage impacts queries
CREATE INDEX idx_coverage_impacts_date ON coverage_impacts(measurement_date);
CREATE INDEX idx_coverage_impacts_hour ON coverage_impacts(measurement_date, measurement_hour);
CREATE INDEX idx_coverage_impacts_department ON coverage_impacts(department);
CREATE INDEX idx_coverage_impacts_skill ON coverage_impacts(skill_group);
CREATE INDEX idx_coverage_impacts_status ON coverage_impacts(service_level_status);

-- Absence reasons queries
CREATE INDEX idx_absence_reasons_active ON absence_reasons(is_active) WHERE is_active = true;
CREATE INDEX idx_absence_reasons_code ON absence_reasons(reason_code);
CREATE INDEX idx_absence_reasons_report ON absence_reasons(include_in_absenteeism_report) WHERE include_in_absenteeism_report = true;

-- Timetable schedules queries
CREATE INDEX idx_timetable_schedules_date ON timetable_schedules(schedule_date);
CREATE INDEX idx_timetable_schedules_employee ON timetable_schedules(employee_id);
CREATE INDEX idx_timetable_schedules_department ON timetable_schedules(department);
CREATE INDEX idx_timetable_schedules_status ON timetable_schedules(timetable_status);
CREATE INDEX idx_timetable_schedules_activity ON timetable_schedules(primary_activity_id);
CREATE INDEX idx_timetable_schedules_time_range ON timetable_schedules(schedule_date, start_time, end_time);

-- Notification configurations queries
CREATE INDEX idx_notification_configurations_event ON notification_configurations(event_type);
CREATE INDEX idx_notification_configurations_recipient ON notification_configurations(recipient_type);
CREATE INDEX idx_notification_configurations_active ON notification_configurations(is_active) WHERE is_active = true;

-- Project assignments queries
CREATE INDEX idx_project_assignments_employee ON project_assignments(employee_id);
CREATE INDEX idx_project_assignments_type ON project_assignments(project_type);
CREATE INDEX idx_project_assignments_status ON project_assignments(assignment_status);
CREATE INDEX idx_project_assignments_dates ON project_assignments(project_start_date, project_end_date);
CREATE INDEX idx_project_assignments_active ON project_assignments(assignment_status) WHERE assignment_status = 'active';

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_intraday_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER intraday_activities_update_trigger
    BEFORE UPDATE ON intraday_activities
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

CREATE TRIGGER activity_templates_update_trigger
    BEFORE UPDATE ON activity_templates
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

CREATE TRIGGER absence_reasons_update_trigger
    BEFORE UPDATE ON absence_reasons
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

CREATE TRIGGER timetable_schedules_update_trigger
    BEFORE UPDATE ON timetable_schedules
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

CREATE TRIGGER notification_configurations_update_trigger
    BEFORE UPDATE ON notification_configurations
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

CREATE TRIGGER project_assignments_update_trigger
    BEFORE UPDATE ON project_assignments
    FOR EACH ROW EXECUTE FUNCTION update_intraday_timestamp();

-- Calculate timetable duration trigger
CREATE OR REPLACE FUNCTION calculate_timetable_duration()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_duration_minutes = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 60;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER timetable_schedules_duration_trigger
    BEFORE INSERT OR UPDATE ON timetable_schedules
    FOR EACH ROW EXECUTE FUNCTION calculate_timetable_duration();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active timetables summary
CREATE VIEW v_active_timetables AS
SELECT 
    ts.timetable_id,
    ts.timetable_name,
    ts.schedule_date,
    ts.start_time,
    ts.end_time,
    e.full_name as employee_name,
    ts.department,
    ia.activity_name as primary_activity,
    ts.service_level_contribution,
    ts.timetable_status
FROM timetable_schedules ts
JOIN employees e ON ts.employee_id = e.id
JOIN intraday_activities ia ON ts.primary_activity_id = ia.activity_id
WHERE ts.timetable_status = 'active'
  AND ts.schedule_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY ts.schedule_date, ts.start_time;

-- Coverage analysis summary
CREATE VIEW v_coverage_analysis AS
SELECT 
    ci.measurement_date,
    ci.measurement_hour,
    ci.department,
    ci.skill_group,
    AVG(ci.coverage_percentage) as avg_coverage,
    AVG(ci.projected_service_level) as avg_service_level,
    COUNT(CASE WHEN ci.service_level_status = 'shortage' THEN 1 END) as shortage_intervals,
    COUNT(CASE WHEN ci.service_level_status = 'optimal' THEN 1 END) as optimal_intervals
FROM coverage_impacts ci
WHERE ci.measurement_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ci.measurement_date, ci.measurement_hour, ci.department, ci.skill_group
ORDER BY ci.measurement_date DESC, ci.measurement_hour;

-- Activity utilization summary
CREATE VIEW v_activity_utilization AS
SELECT 
    ia.activity_name,
    ia.activity_type,
    COUNT(ts.id) as scheduled_instances,
    AVG(ts.total_duration_minutes) as avg_duration_minutes,
    SUM(ts.total_duration_minutes) as total_duration_minutes,
    AVG(ts.service_level_contribution) as avg_service_contribution
FROM intraday_activities ia
LEFT JOIN timetable_schedules ts ON ia.activity_id = ts.primary_activity_id
WHERE ia.is_active = true
  AND (ts.schedule_date IS NULL OR ts.schedule_date >= CURRENT_DATE - INTERVAL '30 days')
GROUP BY ia.activity_id, ia.activity_name, ia.activity_type
ORDER BY total_duration_minutes DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING (15-minute activities for 100 operators)
-- =============================================================================

-- Insert core intraday activities
INSERT INTO intraday_activities (activity_id, activity_name, activity_type, default_duration_minutes, notification_required, notification_timing_minutes) VALUES
('work_calls', 'Handle Customer Calls', 'work_attendance', 15, false, 0),
('lunch_break', 'Lunch Break', 'lunch_break', 60, true, 10),
('short_break', 'Short Break', 'short_break', 15, true, 5),
('training_session', 'Training Session', 'training', 120, true, 30),
('team_meeting', 'Team Meeting', 'meeting', 30, true, 15),
('project_work', 'Project Assignment', 'project_assignment', 60, false, 0);

-- Insert absence reasons (Russian examples from BDD)
INSERT INTO absence_reasons (reason_id, reason_name, reason_code, reason_name_ru, include_in_absenteeism_report, reason_comments) VALUES
('med_exam', 'Medical Examination', 'MED', 'Медицинский осмотр', false, 'Planned medical examination'),
('family_emergency', 'Family Emergency', 'FAM', 'Семейные обстоятельства', true, 'Family emergency situations'),
('education_leave', 'Educational Leave', 'EDU', 'Учебный отпуск', false, 'Educational leave');

-- Insert activity template
INSERT INTO activity_templates (template_id, template_name, planning_criteria, break_optimization_enabled, included_activities, created_by) VALUES
('tech_support_template', 'Technical Support Teams', '80/20 format (80% calls in 20 seconds)', true, 
'[{"activity": "work_calls", "percentage": 70}, {"activity": "training_session", "percentage": 20}, {"activity": "team_meeting", "percentage": 10}]',
(SELECT id FROM employees LIMIT 1));

-- Insert notification configurations
INSERT INTO notification_configurations (config_id, event_type, recipient_type, notification_methods, timing_minutes_before) VALUES
('break_reminder_config', 'break_reminder', 'individual_employee', '["system", "mobile"]', 5),
('lunch_reminder_config', 'lunch_reminder', 'individual_employee', '["system", "mobile"]', 10),
('meeting_reminder_config', 'meeting_reminder', 'participants', '["email", "system"]', 15);

-- Insert sample coverage impacts (15-minute intervals)
INSERT INTO coverage_impacts (impact_id, measurement_date, measurement_hour, measurement_interval, required_operators, scheduled_operators, available_operators, coverage_percentage, service_level_target, projected_service_level, skill_group, department) VALUES
('coverage_001', CURRENT_DATE, 9, 15, 25, 24, 23, 92.0, 80.0, 85.0, 'Level 1 Support', 'Customer Service'),
('coverage_002', CURRENT_DATE, 10, 15, 30, 28, 27, 90.0, 80.0, 82.0, 'Level 1 Support', 'Customer Service'),
('coverage_003', CURRENT_DATE, 11, 15, 35, 33, 32, 91.4, 80.0, 83.5, 'Level 1 Support', 'Customer Service');

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE intraday_activities IS 'BDD Lines 81-131: Core intraday activities with scheduling rules and service impact';
COMMENT ON TABLE activity_templates IS 'BDD Lines 85-99, 132-150: Reusable activity templates for recurring scheduling patterns';
COMMENT ON TABLE coverage_impacts IS 'BDD Lines 168-181, 312-335: Coverage analysis and service level impact tracking';
COMMENT ON TABLE absence_reasons IS 'BDD Lines 43-80: Configurable absence reasons with Russian localization support';
COMMENT ON TABLE timetable_schedules IS 'BDD Lines 81-99, 182-195: Detailed timetable schedules with break optimization';
COMMENT ON TABLE notification_configurations IS 'BDD Lines 12-42: Comprehensive notification system for events and schedules';
COMMENT ON TABLE project_assignments IS 'BDD Lines 151-167: Project assignments with resource allocation and performance tracking';