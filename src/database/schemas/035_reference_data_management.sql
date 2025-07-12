-- =============================================================================
-- 035_reference_data_management.sql
-- EXACT BDD Implementation: Reference Data Management and Configuration
-- =============================================================================
-- Version: 1.0
-- Created: 2025-01-17
-- Based on: 17-reference-data-management-configuration.feature (437 lines)
-- Purpose: Foundation reference data for all WFM operations
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. WORK RULES CONFIGURATION
-- =============================================================================

-- Work rules with rotation patterns from BDD lines 11-39
CREATE TABLE work_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(200) NOT NULL UNIQUE,
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('With rotation', 'Without rotation')),
    consider_holidays BOOLEAN DEFAULT true,
    time_zone VARCHAR(100) NOT NULL,
    mandatory_shifts_by_day BOOLEAN DEFAULT false,
    
    -- Constraints from BDD lines 34-38
    min_hours_between_shifts INTEGER DEFAULT 11, -- Labor law compliance
    max_consecutive_hours INTEGER DEFAULT 40, -- Fatigue prevention
    max_consecutive_days INTEGER DEFAULT 6, -- Rest requirement
    shift_distance_rules JSONB, -- Geographic considerations
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Shift types configuration from BDD lines 22-27
CREATE TABLE shift_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    work_rule_id UUID NOT NULL REFERENCES work_rules(id) ON DELETE CASCADE,
    shift_name VARCHAR(100) NOT NULL,
    shift_category VARCHAR(20) CHECK (shift_category IN ('Morning', 'Afternoon', 'Evening', 'Night')),
    
    -- Time configuration (fixed or range)
    start_time_fixed TIME,
    start_time_range_begin TIME,
    start_time_range_end TIME,
    
    -- Duration configuration (fixed or range)
    duration_fixed INTERVAL,
    duration_range_min INTERVAL,
    duration_range_max INTERVAL,
    
    -- Break integration
    automatic_break_scheduling BOOLEAN DEFAULT true,
    break_compliance_rules JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_shift_times CHECK (
        (start_time_fixed IS NOT NULL AND start_time_range_begin IS NULL AND start_time_range_end IS NULL) OR
        (start_time_fixed IS NULL AND start_time_range_begin IS NOT NULL AND start_time_range_end IS NOT NULL)
    ),
    
    CONSTRAINT max_shift_types_per_rule CHECK (
        (SELECT COUNT(*) FROM shift_types WHERE work_rule_id = NEW.work_rule_id) < 10
    )
);

-- Rotation patterns from BDD lines 28-32
CREATE TABLE rotation_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    work_rule_id UUID NOT NULL REFERENCES work_rules(id) ON DELETE CASCADE,
    pattern_type VARCHAR(20) NOT NULL CHECK (pattern_type IN ('Simple rotation', 'Complex rotation', 'Flexible rotation')),
    pattern_code VARCHAR(100), -- e.g., 'WWWWWRR' (5 work days, 2 rest)
    pattern_description TEXT,
    is_demand_driven BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. EVENTS AND INTERNAL ACTIVITIES
-- =============================================================================

-- Internal events configuration from BDD lines 40-69
CREATE TABLE internal_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(200) NOT NULL,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('Training', 'Meeting', 'Project')),
    
    -- Common properties
    regularity VARCHAR(50), -- 'Once a week', 'Daily', 'Monthly'
    weekdays TEXT[], -- Array of weekdays
    time_interval_start TIME,
    time_interval_end TIME,
    duration_minutes INTEGER NOT NULL,
    
    -- Participation settings
    participation_type VARCHAR(20) CHECK (participation_type IN ('Group', 'Individual')),
    min_participants INTEGER,
    max_participants INTEGER,
    
    -- Training-specific fields from BDD lines 44-53
    skill_requirement VARCHAR(200), -- e.g., 'English Level B1+'
    
    -- Meeting-specific fields from BDD lines 54-60
    meeting_type VARCHAR(20), -- Daily, Weekly, Monthly
    mandatory_attendance BOOLEAN DEFAULT false,
    combine_with_others BOOLEAN DEFAULT false,
    find_common_time BOOLEAN DEFAULT false,
    resource_requirements JSONB, -- Room, equipment
    
    -- Project-specific fields from BDD lines 61-68
    project_mode VARCHAR(20), -- Inbound/Outbound priority
    priority_level INTEGER CHECK (priority_level BETWEEN 1 AND 100),
    target_duration_per_contact INTEGER, -- in minutes
    work_plan_volume INTEGER, -- Total scope
    project_period_start DATE,
    project_period_end DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 3. VACATION SCHEMES AND POLICIES
-- =============================================================================

-- Vacation schemes from BDD lines 70-94
CREATE TABLE vacation_schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_name VARCHAR(200) NOT NULL UNIQUE,
    scheme_type VARCHAR(50) NOT NULL CHECK (scheme_type IN (
        'Standard Annual', 'Senior Employee', 'Part-time Employee', 'Probationary Period'
    )),
    
    -- Entitlement configuration from BDD lines 75-79
    annual_days INTEGER NOT NULL,
    carryover_allowed BOOLEAN DEFAULT false,
    carryover_max_days INTEGER DEFAULT 0,
    proration_enabled BOOLEAN DEFAULT false,
    
    -- Vacation rules from BDD lines 80-87
    minimum_vacation_block INTEGER DEFAULT 7, -- Consecutive days
    maximum_vacation_block INTEGER DEFAULT 28, -- Continuous period
    notice_period_days INTEGER DEFAULT 14, -- Advance request time
    approval_chain JSONB NOT NULL, -- Routing sequence
    blackout_periods JSONB, -- Restricted dates
    carryover_policy VARCHAR(20) DEFAULT 'Use or lose',
    
    -- Calculation methods from BDD lines 88-93
    calculation_type VARCHAR(20) NOT NULL CHECK (calculation_type IN (
        'Calendar days', 'Working days'
    )),
    accumulation_rate DECIMAL(4,2) DEFAULT 2.33, -- Days per month
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Vacation period ordering from BDD lines 122-133
CREATE TABLE vacation_period_ordering (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vacation_scheme_id UUID NOT NULL REFERENCES vacation_schemes(id) ON DELETE CASCADE,
    period_name VARCHAR(50) NOT NULL,
    priority INTEGER NOT NULL,
    alternation_rule VARCHAR(50), -- 'Every 2 years', 'Every 3 years'
    constraint_period VARCHAR(50), -- 'June-August', 'December-February'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_scheme_priority UNIQUE(vacation_scheme_id, priority)
);

-- =============================================================================
-- 4. ABSENCE REASON CATEGORIES
-- =============================================================================

-- Absence reasons from BDD lines 134-155
CREATE TABLE absence_reason_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(50) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    impact_on_schedule VARCHAR(50) NOT NULL,
    payroll_integration VARCHAR(50) NOT NULL,
    
    -- Properties from BDD lines 149-154
    advance_notice_required_hours INTEGER,
    documentation_required VARCHAR(20) CHECK (documentation_required IN ('Yes', 'No', 'Sometimes')),
    approval_level VARCHAR(20) CHECK (approval_level IN ('Supervisor', 'HR', 'Director')),
    maximum_duration_days INTEGER,
    frequency_limit_per_year INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Insert standard absence categories from BDD lines 139-147
INSERT INTO absence_reason_codes (category, code, impact_on_schedule, payroll_integration) VALUES
('Sick Leave', 'SICK', 'Unplanned replacement', 'Paid/Unpaid based on policy'),
('Vacation', 'VAC', 'Planned coverage', 'Paid time off'),
('Personal Leave', 'PTO', 'Semi-planned coverage', 'Usually unpaid'),
('Training', 'TRN', 'Productive activity', 'Paid development time'),
('Jury Duty', 'JURY', 'Legal obligation', 'Paid civic duty'),
('Bereavement', 'BER', 'Emergency leave', 'Paid compassionate leave'),
('Medical Appointment', 'MED', 'Short absence', 'Flexible scheduling'),
('Emergency', 'EMG', 'Immediate absence', 'Case-by-case evaluation');

-- =============================================================================
-- 5. SERVICE GROUPS HIERARCHY
-- =============================================================================

-- Services (top level) from BDD lines 156-177
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(200) NOT NULL UNIQUE,
    service_purpose VARCHAR(200),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Service groups from BDD lines 161-176
CREATE TABLE service_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    group_name VARCHAR(200) NOT NULL,
    group_level VARCHAR(50) NOT NULL,
    
    -- Group properties from BDD lines 170-176
    channel_type VARCHAR(20) CHECK (channel_type IN ('Voice', 'Email', 'Chat')),
    skill_requirements JSONB, -- Competency levels
    service_level_targets JSONB, -- 80/20 format definitions
    operating_hours JSONB, -- Schedule constraints
    capacity_limits INTEGER, -- Maximum agents
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 6. SERVICE LEVEL CONFIGURATION (80/20 FORMAT)
-- =============================================================================

-- Service level settings from BDD lines 178-206
CREATE TABLE service_level_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_name VARCHAR(200) NOT NULL,
    
    -- 80/20 format configuration from BDD lines 183-189
    service_level_target_pct DECIMAL(5,2) NOT NULL CHECK (service_level_target_pct BETWEEN 70 AND 95),
    answer_time_target_seconds INTEGER NOT NULL CHECK (answer_time_target_seconds BETWEEN 10 AND 60),
    threshold_warning_pct DECIMAL(5,2) NOT NULL CHECK (threshold_warning_pct BETWEEN 60 AND 85),
    threshold_critical_pct DECIMAL(5,2) NOT NULL CHECK (threshold_critical_pct BETWEEN 50 AND 75),
    measurement_period VARCHAR(20) DEFAULT '30min' CHECK (measurement_period IN ('15min', '30min', '1hour')),
    alert_frequency VARCHAR(20) DEFAULT '1min' CHECK (alert_frequency IN ('Real-time', '1min', '5min')),
    
    -- Group-specific settings from BDD lines 196-200
    applies_to_level VARCHAR(20) CHECK (applies_to_level IN ('Organization', 'Department', 'Team', 'Individual')),
    override_parent BOOLEAN DEFAULT false,
    
    -- Preview calculations from BDD lines 201-205
    impact_calculator_data JSONB, -- Estimated operator requirements
    historical_comparison_data JSONB, -- Previous vs new settings
    achievability_score DECIMAL(5,2), -- Percentage likelihood
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Validation from BDD lines 191-195
    CONSTRAINT service_level_hierarchy CHECK (
        service_level_target_pct >= threshold_warning_pct AND
        threshold_warning_pct >= threshold_critical_pct
    )
);

-- =============================================================================
-- 7. ROLES AND PERMISSIONS
-- =============================================================================

-- System roles from BDD lines 207-231
CREATE TABLE system_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_category VARCHAR(20) NOT NULL CHECK (role_category IN ('System Roles', 'Business Roles')),
    role_name VARCHAR(100) NOT NULL UNIQUE,
    role_scope VARCHAR(50) NOT NULL,
    
    -- Inheritance settings from BDD lines 226-230
    parent_role_id UUID REFERENCES system_roles(id),
    allows_override BOOLEAN DEFAULT true,
    is_time_based BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Role permissions from BDD lines 219-225
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES system_roles(id) ON DELETE CASCADE,
    permission_category VARCHAR(50) NOT NULL,
    permission_name VARCHAR(100) NOT NULL,
    is_granted BOOLEAN NOT NULL DEFAULT false,
    scope_limitation VARCHAR(200), -- e.g., "Limited to own team"
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_role_permission UNIQUE(role_id, permission_name)
);

-- =============================================================================
-- 8. COMMUNICATION CHANNELS
-- =============================================================================

-- Communication channels from BDD lines 232-251
CREATE TABLE communication_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_category VARCHAR(20) NOT NULL CHECK (channel_category IN ('Voice Channels', 'Digital Channels')),
    channel_type VARCHAR(50) NOT NULL,
    
    -- Channel characteristics from BDD lines 237-243
    customer_initiated BOOLEAN DEFAULT true,
    synchronous_communication BOOLEAN DEFAULT true,
    
    -- Channel properties from BDD lines 244-250
    concurrent_handling VARCHAR(20) CHECK (concurrent_handling IN ('Single', 'Multiple')),
    response_time_sla_minutes INTEGER,
    skill_requirements JSONB,
    priority_level INTEGER CHECK (priority_level BETWEEN 1 AND 5),
    escalation_paths JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 9. PRODUCTION CALENDAR AND HOLIDAYS
-- =============================================================================

-- Holiday configuration from BDD lines 252-273
CREATE TABLE holiday_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_type VARCHAR(50) NOT NULL CHECK (holiday_type IN (
        'National holidays', 'Religious holidays', 'Company holidays', 'Regional holidays'
    )),
    holiday_name VARCHAR(200) NOT NULL,
    
    -- Holiday dates
    fixed_date DATE,
    variable_date_rule VARCHAR(200), -- For religious/lunar holidays
    
    -- Holiday rules from BDD lines 262-267
    holiday_pay_rate_multiplier DECIMAL(3,2) DEFAULT 1.5,
    work_on_holiday_allowed BOOLEAN DEFAULT true,
    work_on_holiday_prohibited BOOLEAN DEFAULT false,
    holiday_substitution_allowed BOOLEAN DEFAULT true,
    pre_post_holiday_schedule_adjustment JSONB,
    
    -- Regional variations from BDD lines 268-272
    applies_to_regions TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 10. PLANNING CRITERIA AND OPTIMIZATION
-- =============================================================================

-- Planning criteria from BDD lines 274-295
CREATE TABLE planning_criteria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    criteria_name VARCHAR(200) NOT NULL,
    
    -- Optimization objectives from BDD lines 278-283
    service_level_weight DECIMAL(3,2) DEFAULT 0.30,
    cost_efficiency_weight DECIMAL(3,2) DEFAULT 0.25,
    employee_satisfaction_weight DECIMAL(3,2) DEFAULT 0.25,
    operational_flexibility_weight DECIMAL(3,2) DEFAULT 0.20,
    
    -- Planning constraints from BDD lines 284-289
    enforce_labor_standards BOOLEAN DEFAULT true,
    budget_limit_flexibility VARCHAR(20) DEFAULT 'Flexible',
    enforce_skill_requirements BOOLEAN DEFAULT true,
    honor_employee_preferences VARCHAR(20) DEFAULT 'Best effort',
    
    -- Algorithm settings from BDD lines 290-294
    algorithm_type VARCHAR(50) CHECK (algorithm_type IN (
        'Genetic algorithm', 'Linear programming', 'Heuristic rules'
    )),
    algorithm_parameters JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT weights_sum_to_one CHECK (
        service_level_weight + cost_efficiency_weight + 
        employee_satisfaction_weight + operational_flexibility_weight = 1.0
    )
);

-- =============================================================================
-- 11. ABSENTEEISM TRACKING
-- =============================================================================

-- Absenteeism tracking rules from BDD lines 296-324
CREATE TABLE absenteeism_tracking_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(200) NOT NULL,
    
    -- Calculation periods from BDD lines 300-305
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('Daily', 'Weekly', 'Monthly', 'Quarterly')),
    calculation_formula TEXT NOT NULL,
    update_frequency VARCHAR(20) NOT NULL,
    
    -- Threshold levels from BDD lines 306-311
    threshold_normal_max DECIMAL(5,2) DEFAULT 5.0,
    threshold_warning_max DECIMAL(5,2) DEFAULT 10.0,
    threshold_critical_max DECIMAL(5,2) DEFAULT 15.0,
    threshold_emergency_min DECIMAL(5,2) DEFAULT 15.0,
    
    -- Alert automation from BDD lines 318-323
    alert_enabled BOOLEAN DEFAULT true,
    alert_recipients JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Absenteeism calculation formulas from BDD lines 312-317
CREATE TABLE absenteeism_formulas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    formula_name VARCHAR(100) NOT NULL,
    formula_component VARCHAR(50) NOT NULL,
    calculation TEXT NOT NULL,
    example TEXT,
    validation_rule TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 12. EMPLOYMENT RATES
-- =============================================================================

-- Employment rate templates from BDD lines 325-353
CREATE TABLE employment_rate_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN (
        'Full-time Standard', 'Part-time Standard', 'Seasonal Workers', 'Contract Workers'
    )),
    template_description TEXT,
    default_rate DECIMAL(5,2),
    adjustment_factors JSONB,
    
    -- Rate calculations from BDD lines 335-340
    calculation_method VARCHAR(50) CHECK (calculation_method IN (
        'Simple Rate', 'Weighted Average', 'Seasonal Adjustment', 'Forecast Projection'
    )),
    
    -- Planning rules from BDD lines 341-346
    minimum_rate_pct DECIMAL(5,2) DEFAULT 80.0,
    maximum_rate_pct DECIMAL(5,2) DEFAULT 120.0,
    month_to_month_variance_limit DECIMAL(5,2) DEFAULT 20.0,
    approval_required_above DECIMAL(5,2) DEFAULT 110.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 13. AGENT STATUS TYPES
-- =============================================================================

-- Agent status types from BDD lines 354-382
CREATE TABLE agent_status_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_category VARCHAR(50) NOT NULL CHECK (status_category IN (
        'Productive', 'Necessary Non-Productive', 'Administrative', 'Unavailable'
    )),
    status_name VARCHAR(100) NOT NULL UNIQUE,
    status_examples TEXT[],
    productivity_impact VARCHAR(20) CHECK (productivity_impact IN ('Positive', 'Neutral', 'Negative')),
    reporting_classification VARCHAR(50),
    
    -- Business rules from BDD lines 364-369
    maximum_duration_minutes INTEGER,
    approval_required BOOLEAN DEFAULT false,
    auto_transition_enabled BOOLEAN DEFAULT false,
    auto_transition_rules JSONB,
    
    -- Valid transitions
    valid_transition_to TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 14. EXTERNAL SYSTEM INTEGRATION MAPPINGS
-- =============================================================================

-- Integration mappings from BDD lines 383-399
CREATE TABLE external_system_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_system VARCHAR(100) NOT NULL,
    external_field VARCHAR(100) NOT NULL,
    wfm_field VARCHAR(100) NOT NULL,
    transformation_rule TEXT,
    
    -- Synchronization rules from BDD lines 393-398
    sync_frequency VARCHAR(20) CHECK (sync_frequency IN ('Real-time', 'Hourly', 'Daily')),
    conflict_resolution VARCHAR(50) DEFAULT 'Master system priority',
    error_handling VARCHAR(20) CHECK (error_handling IN ('Retry', 'Log', 'Alert')),
    data_validation_rules JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT unique_system_field_mapping UNIQUE(external_system, external_field)
);

-- =============================================================================
-- 15. NOTIFICATION TEMPLATES
-- =============================================================================

-- Notification templates from BDD lines 400-422
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_category VARCHAR(50) NOT NULL CHECK (template_category IN (
        'Schedule Notifications', 'Request Notifications', 'Alert Notifications', 'Reminder Notifications'
    )),
    template_name VARCHAR(200) NOT NULL UNIQUE,
    template_purpose TEXT,
    
    -- Delivery methods from BDD lines 405-409
    delivery_methods TEXT[] DEFAULT ARRAY['Email'],
    
    -- Content configuration from BDD lines 410-415
    subject_line_template TEXT NOT NULL,
    message_body_html TEXT,
    message_body_plain TEXT NOT NULL,
    call_to_action_enabled BOOLEAN DEFAULT true,
    attachments_allowed BOOLEAN DEFAULT false,
    
    -- Delivery rules from BDD lines 416-421
    delivery_timing VARCHAR(20) CHECK (delivery_timing IN ('Immediate', 'Scheduled')),
    retry_logic_enabled BOOLEAN DEFAULT true,
    opt_out_allowed BOOLEAN DEFAULT true,
    tracking_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- 16. QUALITY STANDARDS AND KPIs
-- =============================================================================

-- Quality standards from BDD lines 423-437
CREATE TABLE quality_standards_kpis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_category VARCHAR(50) NOT NULL CHECK (kpi_category IN (
        'Productivity', 'Quality', 'Efficiency', 'Development'
    )),
    metric_name VARCHAR(200) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    measurement_unit VARCHAR(50) NOT NULL,
    measurement_type VARCHAR(50) NOT NULL,
    
    -- Measurement rules from BDD lines 433-437
    calculation_period VARCHAR(20) CHECK (calculation_period IN ('Daily', 'Weekly', 'Monthly')),
    weighting_factor DECIMAL(3,2) DEFAULT 1.0,
    trending_enabled BOOLEAN DEFAULT true,
    benchmark_update_frequency VARCHAR(20) DEFAULT 'Quarterly',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to validate rotation pattern
CREATE OR REPLACE FUNCTION validate_rotation_pattern(p_pattern VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if pattern contains only W (work) and R (rest) characters
    RETURN p_pattern ~ '^[WR]+$';
END;
$$ LANGUAGE plpgsql;

-- Function to calculate absenteeism percentage
CREATE OR REPLACE FUNCTION calculate_absenteeism_percentage(
    p_absent_hours DECIMAL,
    p_scheduled_hours DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    IF p_scheduled_hours = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND((p_absent_hours / p_scheduled_hours) * 100, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to check service level hierarchy
CREATE OR REPLACE FUNCTION check_service_level_hierarchy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.service_level_target_pct < NEW.threshold_warning_pct OR
       NEW.threshold_warning_pct < NEW.threshold_critical_pct THEN
        RAISE EXCEPTION 'Service level hierarchy must be maintained: Target >= Warning >= Critical';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_service_level_hierarchy
    BEFORE INSERT OR UPDATE ON service_level_settings
    FOR EACH ROW
    EXECUTE FUNCTION check_service_level_hierarchy();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Work rules indexes
CREATE INDEX idx_work_rules_active ON work_rules(is_active);
CREATE INDEX idx_shift_types_work_rule ON shift_types(work_rule_id);

-- Events indexes
CREATE INDEX idx_internal_events_type ON internal_events(event_type);
CREATE INDEX idx_internal_events_active ON internal_events(is_active);

-- Vacation indexes
CREATE INDEX idx_vacation_schemes_active ON vacation_schemes(is_active);
CREATE INDEX idx_vacation_schemes_type ON vacation_schemes(scheme_type);

-- Service hierarchy indexes
CREATE INDEX idx_service_groups_service ON service_groups(service_id);
CREATE INDEX idx_service_groups_channel ON service_groups(channel_type);

-- Role indexes
CREATE INDEX idx_system_roles_category ON system_roles(role_category);
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);

-- Status types indexes
CREATE INDEX idx_agent_status_types_category ON agent_status_types(status_category);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample work rule with rotation
INSERT INTO work_rules (rule_name, mode, time_zone, consider_holidays) VALUES
('Standard 5x2 Rotation', 'With rotation', 'Europe/Moscow', true);

-- Sample rotation pattern (5 work days, 2 rest days)
INSERT INTO rotation_patterns (work_rule_id, pattern_type, pattern_code, pattern_description)
SELECT id, 'Simple rotation', 'WWWWWRR', '5 work days, 2 rest days'
FROM work_rules WHERE rule_name = 'Standard 5x2 Rotation';

-- Sample services
INSERT INTO services (service_name, service_purpose) VALUES
('Technical Support', 'Main service category'),
('Sales', 'Revenue generation');

-- Sample service groups
INSERT INTO service_groups (service_id, group_name, group_level, channel_type)
SELECT s.id, 'Level 1 Support', 'First-line assistance', 'Voice'
FROM services s WHERE s.service_name = 'Technical Support';

-- Sample system roles from BDD
INSERT INTO system_roles (role_category, role_name, role_scope) VALUES
('System Roles', 'Administrator', 'Global'),
('System Roles', 'Senior Operator', 'Multi-department'),
('System Roles', 'Operator', 'Personal'),
('Business Roles', 'Regional Manager', 'Geographic region'),
('Business Roles', 'Department Head', 'Department'),
('Business Roles', 'Team Lead', 'Team/Group');

-- Sample 80/20 service level setting
INSERT INTO service_level_settings (
    setting_name, service_level_target_pct, answer_time_target_seconds,
    threshold_warning_pct, threshold_critical_pct
) VALUES (
    'Standard 80/20', 80.0, 20, 75.0, 65.0
);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_administrators;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operators;