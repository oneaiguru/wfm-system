-- =============================================================================
-- 038_monthly_intraday_activity_planning.sql
-- EXACT BDD Implementation: Monthly Intraday Activity Planning and Timetable Management
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 10-monthly-intraday-activity-planning.feature (406 lines)
-- Purpose: Detailed daily timetables with optimal break placement and activity scheduling
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. NOTIFICATION CONFIGURATION
-- =============================================================================

-- Event and schedule notifications from BDD lines 12-41
CREATE TABLE notification_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'Break Reminder', 'Lunch Reminder', 'Meeting Reminder', 'Training Start',
        'Schedule Change', 'Shift Start'
    )),
    
    -- Notification settings from BDD lines 16-22
    recipients_type VARCHAR(50) NOT NULL, -- Individual Employee, Participants, etc.
    notification_methods TEXT[] NOT NULL, -- System, Mobile, Email
    timing_before_minutes INTEGER NOT NULL, -- 5, 10, 15, 30 minutes
    
    -- System-wide settings from BDD lines 31-38
    email_server VARCHAR(200) DEFAULT 'smtp.company.com',
    sms_gateway VARCHAR(200) DEFAULT 'provider.sms.com',
    mobile_push_service VARCHAR(100) DEFAULT 'Firebase FCM',
    notification_retention_days INTEGER DEFAULT 30,
    escalation_attempts INTEGER DEFAULT 3,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '08:00',
    
    -- Tracking and compliance
    notification_history_tracked BOOLEAN DEFAULT true,
    last_test_delivery TIMESTAMP WITH TIME ZONE,
    delivery_verified BOOLEAN DEFAULT false,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_event_type_notification UNIQUE(event_type)
);

-- =============================================================================
-- 2. ABSENCE REASONS CONFIGURATION
-- =============================================================================

-- Absence reasons from BDD lines 43-79
CREATE TABLE absence_reasons_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    name_russian VARCHAR(200), -- Медицинский осмотр, Семейные обстоятельства
    
    -- Configuration from BDD lines 48-53
    is_active BOOLEAN DEFAULT true,
    included_in_absenteeism_report BOOLEAN DEFAULT true,
    comments TEXT,
    
    -- Filtering support from BDD lines 69-78
    filter_status VARCHAR(20) GENERATED ALWAYS AS (
        CASE WHEN is_active THEN 'Active' ELSE 'Inactive' END
    ) STORED,
    
    -- Audit tracking
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    original_settings_preserved JSONB -- For existing time records
);

-- =============================================================================
-- 3. TIMETABLE PLANNING
-- =============================================================================

-- Monthly planning templates from BDD lines 81-99
CREATE TABLE monthly_planning_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(200) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Planning criteria from BDD lines 87-91
    planning_criteria VARCHAR(100) DEFAULT '80/20 format (80% calls in 20 seconds)',
    service_level_target_pct DECIMAL(5,2) DEFAULT 80.0,
    response_time_target_seconds INTEGER DEFAULT 20,
    break_optimization_enabled BOOLEAN DEFAULT true,
    lunch_scheduling_automated BOOLEAN DEFAULT true,
    
    -- Optimization rules from BDD lines 93-97
    work_share_distribution_rule VARCHAR(100) DEFAULT 'Distribute based on load forecast',
    break_placement_rule VARCHAR(100) DEFAULT 'Optimize for coverage gaps',
    lunch_scheduling_rule VARCHAR(100) DEFAULT 'Maintain 80/20 format targets',
    activity_assignment_rule VARCHAR(100) DEFAULT 'Balance workload across team',
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_planning_period CHECK (period_end > period_start)
);

-- Intraday activity schedules from BDD lines 81-99
CREATE TABLE intraday_activity_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_template_id UUID NOT NULL REFERENCES monthly_planning_templates(id),
    employee_id UUID NOT NULL,
    schedule_date DATE NOT NULL,
    
    -- 15-minute interval scheduling
    interval_start_time TIME NOT NULL,
    interval_end_time TIME NOT NULL,
    interval_duration_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (interval_end_time - interval_start_time)) / 60
    ) STORED,
    
    -- Activity assignment
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN (
        'Work Attendance', 'Break', 'Lunch', 'Training', 'Meeting', 
        'Project', 'Downtime', 'Event'
    )),
    activity_details JSONB,
    
    -- Multi-skill assignments from BDD lines 100-115
    assigned_skill VARCHAR(200),
    skill_priority VARCHAR(20) CHECK (skill_priority IN ('Primary', 'Secondary', 'Overflow')),
    load_distribution_pct DECIMAL(5,2),
    
    -- Service level tracking
    impacts_service_level BOOLEAN DEFAULT true,
    service_level_impact_calculated DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(50),
    modified_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_employee_interval UNIQUE(employee_id, schedule_date, interval_start_time),
    CONSTRAINT valid_interval_duration CHECK (
        interval_duration_minutes IN (15, 30, 45, 60, 90, 120)
    )
);

-- Multi-skill operator planning from BDD lines 100-115
CREATE TABLE multiskill_operator_distribution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    employee_name VARCHAR(200) NOT NULL, -- Cyrillic support: Иванов И.И.
    
    -- Skill distribution from BDD lines 104-107
    primary_skill VARCHAR(200) NOT NULL,
    secondary_skills TEXT[],
    load_distribution JSONB NOT NULL, -- {"primary": 70, "secondary": [20, 10]}
    
    -- Assignment priority from BDD lines 109-114
    assignment_priority INTEGER NOT NULL,
    assignment_rules JSONB,
    proficiency_requirements_met BOOLEAN DEFAULT true,
    
    planning_template_id UUID REFERENCES monthly_planning_templates(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. MANUAL TIMETABLE ADJUSTMENTS
-- =============================================================================

-- Manual timetable adjustments from BDD lines 116-131
CREATE TABLE timetable_manual_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES intraday_activity_schedules(id),
    
    -- Adjustment types from BDD lines 120-127
    adjustment_type VARCHAR(50) NOT NULL CHECK (adjustment_type IN (
        'Add work attendance', 'Mark downtime', 'Assign to project',
        'Add lunch break', 'Add short break', 'Cancel breaks', 'Schedule event'
    )),
    
    -- Validation requirements
    validation_type VARCHAR(100) NOT NULL,
    validation_passed BOOLEAN DEFAULT false,
    validation_message TEXT,
    
    -- Impact assessment
    minimum_coverage_checked BOOLEAN,
    service_impact_verified BOOLEAN,
    compliance_validated BOOLEAN,
    
    -- Notifications
    operator_notified BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Service level impact from BDD line 130
    service_level_impact_before DECIMAL(5,2),
    service_level_impact_after DECIMAL(5,2),
    impact_displayed_to_user BOOLEAN DEFAULT true,
    
    adjusted_by VARCHAR(50) NOT NULL,
    adjusted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. TRAINING AND EVENT MANAGEMENT
-- =============================================================================

-- Training and development events from BDD lines 132-149
CREATE TABLE training_events_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(200) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    
    -- Event details from BDD lines 137-140
    duration_minutes INTEGER NOT NULL,
    min_participants INTEGER,
    max_participants INTEGER,
    scheduling_rules JSONB NOT NULL, -- Day, time, frequency
    
    -- Configuration parameters from BDD lines 142-146
    regularity VARCHAR(50) NOT NULL, -- Weekly/Daily/Monthly/By appointment
    participation_type VARCHAR(20) NOT NULL CHECK (participation_type IN ('Group', 'Individual')),
    combine_with_others BOOLEAN DEFAULT false,
    find_common_time BOOLEAN DEFAULT true,
    
    -- Automation
    auto_scheduled BOOLEAN DEFAULT true,
    calendar_invitations_sent BOOLEAN DEFAULT false,
    timetable_reserved BOOLEAN DEFAULT false,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 6. PROJECT ASSIGNMENTS
-- =============================================================================

-- Outbound project configuration from BDD lines 151-166
CREATE TABLE project_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(200) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    
    -- Project parameters from BDD lines 155-158
    priority_pct DECIMAL(5,2) NOT NULL,
    duration_per_contact_minutes DECIMAL(4,1) NOT NULL,
    total_work_plan_count INTEGER NOT NULL,
    
    -- Configuration from BDD lines 160-164
    project_period_start DATE NOT NULL,
    project_period_end DATE NOT NULL,
    operator_allocation_pct DECIMAL(5,2) DEFAULT 20.0,
    performance_target_per_hour DECIMAL(5,2),
    quality_requirement_pct DECIMAL(5,2) DEFAULT 80.0,
    
    -- Impact on planning
    affects_load_distribution BOOLEAN DEFAULT true,
    skill_requirements JSONB,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_project_period CHECK (project_period_end > project_period_start)
);

-- =============================================================================
-- 7. TIMETABLE STATISTICS AND ANALYSIS
-- =============================================================================

-- Coverage analysis from BDD lines 168-180
CREATE TABLE timetable_coverage_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_template_id UUID NOT NULL REFERENCES monthly_planning_templates(id),
    analysis_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Metrics and visualization from BDD lines 172-177
    forecast_vs_planned_status JSONB, -- Color-coded intervals
    coverage_gaps_identified JSONB, -- Red highlighting for shortages
    service_level_projection_pct DECIMAL(5,2),
    break_distribution_analysis JSONB,
    utilization_rate_by_operator JSONB,
    
    -- Analysis insights
    optimization_insights TEXT[],
    attention_required_periods JSONB,
    resource_allocation_recommendations JSONB,
    
    analyzed_by VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Real-time timetable updates from BDD lines 196-209
CREATE TABLE realtime_timetable_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trigger_event VARCHAR(100) NOT NULL,
    
    -- Response types from BDD lines 200-205
    required_response VARCHAR(100) NOT NULL,
    system_action_taken VARCHAR(200) NOT NULL,
    
    -- Update tracking
    timetables_updated INTEGER DEFAULT 0,
    operators_notified INTEGER DEFAULT 0,
    service_continuity_maintained BOOLEAN DEFAULT true,
    
    -- Timestamp tracking
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    initiated_by VARCHAR(50) NOT NULL
);

-- =============================================================================
-- 8. COST AND RESOURCE OPTIMIZATION
-- =============================================================================

-- Cost calculation from BDD lines 210-223
CREATE TABLE timetable_cost_optimization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_template_id UUID NOT NULL REFERENCES monthly_planning_templates(id),
    
    -- Cost components from BDD lines 214-218
    regular_hours_cost DECIMAL(12,2),
    overtime_hours_cost DECIMAL(12,2),
    break_time_cost DECIMAL(12,2),
    training_time_cost DECIMAL(12,2),
    project_time_cost DECIMAL(12,2),
    
    -- Optimization opportunities
    optimization_opportunities JSONB,
    efficiency_recommendations JSONB,
    budget_impact_analysis JSONB,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calculated_by VARCHAR(50)
);

-- =============================================================================
-- 9. COMPLIANCE MONITORING
-- =============================================================================

-- Labor standards compliance from BDD lines 224-237
CREATE TABLE timetable_compliance_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    monitoring_date DATE NOT NULL,
    
    -- Compliance checks from BDD lines 228-233
    rest_period_hours DECIMAL(4,1),
    rest_period_compliant BOOLEAN,
    daily_work_hours DECIMAL(4,1),
    daily_work_compliant BOOLEAN,
    weekly_work_hours DECIMAL(4,1),
    weekly_work_compliant BOOLEAN,
    break_requirements_met BOOLEAN,
    lunch_requirements_met BOOLEAN,
    
    -- Violation handling
    violations_flagged INTEGER DEFAULT 0,
    supervisor_notified BOOLEAN DEFAULT false,
    corrective_actions_suggested JSONB,
    
    monitored_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_date_compliance UNIQUE(employee_id, monitoring_date)
);

-- =============================================================================
-- 10. ENHANCED STATISTICS
-- =============================================================================

-- Working days statistics from BDD lines 238-261
CREATE TABLE working_days_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    calculation_period VARCHAR(20) NOT NULL CHECK (calculation_period IN (
        'Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom Period'
    )),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Calculation factors from BDD lines 249-255
    total_calendar_days INTEGER NOT NULL,
    weekend_days INTEGER DEFAULT 0,
    holiday_days INTEGER DEFAULT 0,
    vacation_days INTEGER DEFAULT 0,
    sick_leave_days INTEGER DEFAULT 0,
    training_days INTEGER DEFAULT 0,
    
    -- Statistics from BDD lines 257-261
    scheduled_work_days INTEGER NOT NULL,
    actual_work_days INTEGER NOT NULL,
    absence_days INTEGER GENERATED ALWAYS AS (scheduled_work_days - actual_work_days) STORED,
    utilization_rate_pct DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN scheduled_work_days > 0 
        THEN (actual_work_days::DECIMAL / scheduled_work_days) * 100 
        ELSE 0 END
    ) STORED,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Planned hours calculation from BDD lines 263-286
CREATE TABLE planned_hours_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    calculation_date DATE NOT NULL,
    
    -- Hour types from BDD lines 268-273
    gross_hours DECIMAL(5,2) NOT NULL,
    break_hours DECIMAL(5,2) NOT NULL,
    net_hours DECIMAL(5,2) GENERATED ALWAYS AS (gross_hours - break_hours) STORED,
    paid_hours DECIMAL(5,2) NOT NULL,
    productive_hours DECIMAL(5,2) NOT NULL,
    
    -- Break details from BDD lines 275-279
    lunch_break_minutes INTEGER DEFAULT 0,
    short_break_minutes INTEGER DEFAULT 0,
    rest_break_minutes INTEGER DEFAULT 0,
    technical_break_minutes INTEGER DEFAULT 0,
    
    -- Hour breakdown from BDD lines 281-286
    scheduled_hours DECIMAL(5,2) NOT NULL,
    break_deduction DECIMAL(5,2) NOT NULL,
    net_work_hours DECIMAL(5,2) NOT NULL,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    total_paid_hours DECIMAL(5,2) NOT NULL,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_date_hours UNIQUE(employee_id, calculation_date)
);

-- Overtime detection from BDD lines 288-310
CREATE TABLE overtime_detection_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    detection_period VARCHAR(20) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Overtime types from BDD lines 293-298
    daily_overtime_hours DECIMAL(5,2) DEFAULT 0,
    weekly_overtime_hours DECIMAL(5,2) DEFAULT 0,
    holiday_overtime_hours DECIMAL(5,2) DEFAULT 0,
    weekend_overtime_hours DECIMAL(5,2) DEFAULT 0,
    emergency_overtime_hours DECIMAL(5,2) DEFAULT 0,
    
    -- Overtime rates
    daily_overtime_rate DECIMAL(3,2) DEFAULT 1.5,
    holiday_overtime_rate DECIMAL(3,2) DEFAULT 2.0,
    weekend_overtime_rate DECIMAL(3,2) DEFAULT 1.5,
    emergency_overtime_rate DECIMAL(3,2) DEFAULT 2.0,
    
    -- Analytics from BDD lines 306-310
    overtime_trend_analysis JSONB,
    overtime_cost_analysis JSONB,
    overtime_distribution JSONB,
    compliance_status VARCHAR(20),
    
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Coverage analysis from BDD lines 312-334
CREATE TABLE coverage_analysis_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_date DATE NOT NULL,
    department_id UUID,
    
    -- Coverage metrics from BDD lines 317-322
    operator_coverage_pct DECIMAL(5,2) NOT NULL,
    skill_coverage_pct DECIMAL(5,2) NOT NULL,
    time_coverage_pct DECIMAL(5,2) NOT NULL,
    service_level_achievement_pct DECIMAL(5,2) NOT NULL,
    utilization_pct DECIMAL(5,2) NOT NULL,
    
    -- Status indicators
    operator_coverage_status VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN operator_coverage_pct >= 95 THEN 'Green'
            WHEN operator_coverage_pct >= 85 THEN 'Yellow'
            ELSE 'Red'
        END
    ) STORED,
    
    -- Analysis visualizations from BDD lines 324-328
    hourly_coverage_data JSONB,
    daily_coverage_data JSONB,
    skill_coverage_data JSONB,
    department_coverage_heatmap JSONB,
    
    -- Recommendations from BDD lines 330-334
    staffing_recommendations JSONB,
    
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate timetable compliance
CREATE OR REPLACE FUNCTION validate_timetable_compliance(
    p_employee_id UUID,
    p_date DATE
) RETURNS BOOLEAN AS $$
DECLARE
    v_compliant BOOLEAN := true;
    v_daily_hours DECIMAL(4,1);
    v_rest_hours DECIMAL(4,1);
BEGIN
    -- Check daily work limits
    SELECT SUM(interval_duration_minutes) / 60.0 INTO v_daily_hours
    FROM intraday_activity_schedules
    WHERE employee_id = p_employee_id 
    AND schedule_date = p_date
    AND activity_type = 'Work Attendance';
    
    IF v_daily_hours > 12 THEN
        v_compliant := false;
    END IF;
    
    -- Log compliance check
    INSERT INTO timetable_compliance_monitoring (
        employee_id, monitoring_date, daily_work_hours, daily_work_compliant
    ) VALUES (
        p_employee_id, p_date, v_daily_hours, v_compliant
    ) ON CONFLICT (employee_id, monitoring_date) DO UPDATE SET
        daily_work_hours = EXCLUDED.daily_work_hours,
        daily_work_compliant = EXCLUDED.daily_work_compliant;
    
    RETURN v_compliant;
END;
$$ LANGUAGE plpgsql;

-- Function to optimize break placement
CREATE OR REPLACE FUNCTION optimize_break_placement(
    p_template_id UUID,
    p_date DATE
) RETURNS void AS $$
BEGIN
    -- Implementation would analyze coverage gaps and place breaks optimally
    -- This is a placeholder for the complex optimization logic
    
    -- Log optimization run
    INSERT INTO timetable_coverage_statistics (
        planning_template_id, 
        optimization_insights
    ) VALUES (
        p_template_id,
        ARRAY['Break optimization completed for ' || p_date::TEXT]
    );
END;
$$ LANGUAGE plpgsql;

-- Function to calculate service level impact
CREATE OR REPLACE FUNCTION calculate_service_level_impact(
    p_schedule_id UUID,
    p_adjustment_type VARCHAR(50)
) RETURNS DECIMAL AS $$
DECLARE
    v_impact DECIMAL(5,2);
BEGIN
    -- Calculate impact based on adjustment type and current coverage
    -- This is a simplified implementation
    v_impact := CASE p_adjustment_type
        WHEN 'Add work attendance' THEN 2.5
        WHEN 'Mark downtime' THEN -5.0
        WHEN 'Cancel breaks' THEN 1.5
        ELSE 0.0
    END;
    
    -- Update the schedule with impact
    UPDATE intraday_activity_schedules
    SET service_level_impact_calculated = v_impact
    WHERE id = p_schedule_id;
    
    RETURN v_impact;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notification_configurations_updated_at
    BEFORE UPDATE ON notification_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_absence_reasons_updated_at
    BEFORE UPDATE ON absence_reasons_configuration
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Performance indexes for time-series data
CREATE INDEX idx_intraday_schedules_date ON intraday_activity_schedules(schedule_date);
CREATE INDEX idx_intraday_schedules_employee_date ON intraday_activity_schedules(employee_id, schedule_date);
CREATE INDEX idx_intraday_schedules_activity ON intraday_activity_schedules(activity_type);
CREATE INDEX idx_intraday_schedules_interval ON intraday_activity_schedules(interval_start_time, interval_end_time);

-- Multi-skill optimization indexes
CREATE INDEX idx_multiskill_employee ON multiskill_operator_distribution(employee_id);
CREATE INDEX idx_multiskill_primary ON multiskill_operator_distribution(primary_skill);

-- Compliance monitoring indexes
CREATE INDEX idx_compliance_employee_date ON timetable_compliance_monitoring(employee_id, monitoring_date);
CREATE INDEX idx_compliance_violations ON timetable_compliance_monitoring(violations_flagged) WHERE violations_flagged > 0;

-- Statistics indexes
CREATE INDEX idx_working_days_employee_period ON working_days_statistics(employee_id, period_start, period_end);
CREATE INDEX idx_planned_hours_employee_date ON planned_hours_statistics(employee_id, calculation_date);
CREATE INDEX idx_overtime_employee_period ON overtime_detection_statistics(employee_id, period_start, period_end);
CREATE INDEX idx_coverage_analysis_date ON coverage_analysis_statistics(analysis_date);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample notification configurations
INSERT INTO notification_configurations (event_type, recipients_type, notification_methods, timing_before_minutes, created_by) VALUES
('Break Reminder', 'Individual Employee', ARRAY['System', 'Mobile'], 5, 'admin'),
('Lunch Reminder', 'Individual Employee', ARRAY['System', 'Mobile'], 10, 'admin'),
('Meeting Reminder', 'Participants', ARRAY['Email', 'System'], 15, 'admin'),
('Training Start', 'Trainees + Instructor', ARRAY['System'], 30, 'admin'),
('Schedule Change', 'Affected Employees', ARRAY['Email', 'System'], 0, 'admin'),
('Shift Start', 'Individual Employee', ARRAY['Mobile'], 30, 'admin');

-- Sample absence reasons
INSERT INTO absence_reasons_configuration (code, name, name_russian, is_active, included_in_absenteeism_report, comments, created_by) VALUES
('MED', 'Medical examination', 'Медицинский осмотр', true, false, 'Planned medical examination', 'admin'),
('FAM', 'Family circumstances', 'Семейные обстоятельства', true, true, 'Family emergency situations', 'admin'),
('EDU', 'Educational leave', 'Учебный отпуск', true, false, 'Educational leave', 'admin');

-- Sample planning template
INSERT INTO monthly_planning_templates (
    template_name, period_start, period_end, 
    service_level_target_pct, response_time_target_seconds,
    created_by
) VALUES (
    'Technical Support Teams', '2025-01-01', '2025-01-31',
    80.0, 20, 'admin'
);

-- Sample training events
INSERT INTO training_events_management (
    event_name, event_type, duration_minutes, min_participants, max_participants,
    scheduling_rules, regularity, participation_type, created_by
) VALUES
('Weekly English Training', 'Training', 120, 5, 10, 
 '{"days": ["Monday", "Wednesday"], "time": "14:00-16:00"}'::jsonb, 'Weekly', 'Group', 'admin'),
('Daily Team Sync', 'Meeting', 30, 10, 20,
 '{"days": ["All"], "time": "09:00-09:30"}'::jsonb, 'Daily', 'Group', 'admin'),
('Monthly Quality Review', 'Meeting', 60, 15, 20,
 '{"days": ["First Monday"], "time": "10:00-11:00"}'::jsonb, 'Monthly', 'Group', 'admin'),
('Skills Assessment', 'Training', 90, 1, 1,
 '{"days": ["By appointment"], "time": "Flexible"}'::jsonb, 'By appointment', 'Individual', 'admin');

-- Sample project assignments
INSERT INTO project_assignments (
    project_name, project_type, priority_pct, duration_per_contact_minutes,
    total_work_plan_count, project_period_start, project_period_end,
    operator_allocation_pct, created_by
) VALUES
('Customer Survey Q1', 'Outbound calls', 80.0, 5.0, 5000, '2025-01-01', '2025-03-31', 20.0, 'admin'),
('Sales Follow-up', 'Warm leads', 90.0, 8.0, 2000, '2025-01-01', '2025-03-31', 20.0, 'admin'),
('Win-back Campaign', 'Retention', 70.0, 10.0, 1500, '2025-01-01', '2025-03-31', 20.0, 'admin');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_planners;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operators;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_planners;