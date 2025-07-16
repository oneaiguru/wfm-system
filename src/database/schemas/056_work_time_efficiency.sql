-- =============================================================================
-- 056_work_time_efficiency.sql
-- EXACT BDD Implementation: Work Time Efficiency Configuration with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 29-work-time-efficiency.feature (32 lines)
-- Purpose: Work time efficiency parameter configuration for productivity monitoring
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. WORK STATUS DEFINITIONS
-- =============================================================================

-- Work status types from BDD lines 15-24
CREATE TABLE work_status_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_id VARCHAR(10) NOT NULL UNIQUE,
    status_type VARCHAR(50) NOT NULL,
    status_code VARCHAR(10) NOT NULL UNIQUE,
    status_description TEXT NOT NULL,
    
    -- Productivity classification from BDD lines 16-24
    productivity_type VARCHAR(20) NOT NULL CHECK (productivity_type IN ('productive', 'non_productive')),
    
    -- Status parameters from BDD lines 26-31
    is_productive_time BOOLEAN NOT NULL DEFAULT true,
    counts_toward_net_load BOOLEAN NOT NULL DEFAULT false,
    counts_as_talk_time BOOLEAN NOT NULL DEFAULT false,
    counts_as_break_time BOOLEAN NOT NULL DEFAULT false,
    counts_in_timesheet BOOLEAN NOT NULL DEFAULT true,
    
    -- Status configuration
    color_code VARCHAR(7) DEFAULT '#ffffff',
    display_order INTEGER DEFAULT 1,
    icon_name VARCHAR(50),
    
    -- Business rules
    requires_reason BOOLEAN DEFAULT false,
    auto_timeout_minutes INTEGER,
    max_duration_minutes INTEGER,
    min_duration_seconds INTEGER DEFAULT 1,
    
    -- Integration settings
    maps_to_external_system VARCHAR(100),
    external_system_code VARCHAR(20),
    sync_with_phone_system BOOLEAN DEFAULT false,
    
    -- Status metadata
    is_system_status BOOLEAN DEFAULT false,
    is_user_selectable BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. PRODUCTIVITY CALCULATION RULES
-- =============================================================================

-- Productivity calculation configuration
CREATE TABLE productivity_calculation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(200) NOT NULL,
    rule_description TEXT,
    
    -- Calculation parameters
    calculation_type VARCHAR(30) NOT NULL CHECK (calculation_type IN (
        'productive_time_percentage', 'net_load_percentage', 'talk_time_percentage',
        'break_time_percentage', 'availability_percentage', 'efficiency_score'
    )),
    
    -- Formula configuration
    numerator_statuses JSONB NOT NULL,
    denominator_statuses JSONB NOT NULL,
    calculation_formula TEXT NOT NULL,
    
    -- Time window settings
    calculation_period VARCHAR(20) DEFAULT 'daily' CHECK (calculation_period IN (
        'real_time', 'hourly', 'daily', 'weekly', 'monthly'
    )),
    minimum_time_threshold_minutes INTEGER DEFAULT 1,
    
    -- Thresholds and targets
    target_percentage DECIMAL(5,2),
    warning_threshold_percentage DECIMAL(5,2),
    critical_threshold_percentage DECIMAL(5,2),
    
    -- Rule scope
    applies_to_departments JSONB DEFAULT '[]',
    applies_to_roles JSONB DEFAULT '[]',
    applies_to_skills JSONB DEFAULT '[]',
    
    -- Status and versioning
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    version VARCHAR(20) DEFAULT '1.0',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. EMPLOYEE STATUS TRACKING
-- =============================================================================

-- Employee status tracking with productivity measurement
CREATE TABLE employee_status_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    
    -- Status information
    status_code VARCHAR(10) NOT NULL,
    status_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status_end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- Context information
    reason_code VARCHAR(50),
    reason_description TEXT,
    set_by_user BOOLEAN DEFAULT true,
    set_by_system BOOLEAN DEFAULT false,
    set_by_supervisor BOOLEAN DEFAULT false,
    
    -- Source tracking
    source_system VARCHAR(50) DEFAULT 'wfm',
    source_device VARCHAR(100),
    source_ip_address INET,
    session_id VARCHAR(100),
    
    -- Productivity calculations
    is_productive_time BOOLEAN NOT NULL,
    counts_toward_net_load BOOLEAN NOT NULL,
    counts_as_talk_time BOOLEAN NOT NULL,
    counts_as_break_time BOOLEAN NOT NULL,
    counts_in_timesheet BOOLEAN NOT NULL,
    
    -- Performance metadata
    scheduled_status VARCHAR(10),
    adherence_status VARCHAR(20) DEFAULT 'compliant' CHECK (adherence_status IN (
        'compliant', 'non_compliant', 'excused', 'unknown'
    )),
    variance_seconds INTEGER DEFAULT 0,
    
    -- Data quality
    data_quality_score DECIMAL(3,2) DEFAULT 1.0,
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN (
        'valid', 'invalid', 'pending', 'corrected'
    )),
    correction_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (status_code) REFERENCES work_status_types(status_code) ON DELETE RESTRICT
);

-- =============================================================================
-- 4. PRODUCTIVITY METRICS CALCULATION
-- =============================================================================

-- Calculated productivity metrics
CREATE TABLE productivity_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metrics_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    
    -- Time period
    calculation_date DATE NOT NULL,
    calculation_period VARCHAR(20) NOT NULL,
    period_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Basic time calculations
    total_time_seconds INTEGER NOT NULL,
    productive_time_seconds INTEGER NOT NULL DEFAULT 0,
    non_productive_time_seconds INTEGER NOT NULL DEFAULT 0,
    talk_time_seconds INTEGER NOT NULL DEFAULT 0,
    break_time_seconds INTEGER NOT NULL DEFAULT 0,
    net_load_time_seconds INTEGER NOT NULL DEFAULT 0,
    
    -- Productivity percentages
    productive_time_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    talk_time_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    break_time_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    net_load_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    availability_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    
    -- Efficiency scores
    overall_efficiency_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    productivity_efficiency_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    time_management_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    
    -- Target comparisons
    meets_productivity_target BOOLEAN DEFAULT false,
    productivity_variance_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Status counts
    status_change_count INTEGER DEFAULT 0,
    unique_statuses_used INTEGER DEFAULT 0,
    longest_status_duration_seconds INTEGER DEFAULT 0,
    shortest_status_duration_seconds INTEGER DEFAULT 0,
    
    -- Calculation metadata
    calculation_rule_id VARCHAR(50),
    calculation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calculation_version VARCHAR(20) DEFAULT '1.0',
    data_completeness_percentage DECIMAL(5,2) DEFAULT 100.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (calculation_rule_id) REFERENCES productivity_calculation_rules(rule_id) ON DELETE SET NULL,
    
    UNIQUE(employee_id, calculation_date, calculation_period)
);

-- =============================================================================
-- 5. STATUS TRANSITION RULES
-- =============================================================================

-- Status transition validation and rules
CREATE TABLE status_transition_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(200) NOT NULL,
    
    -- Transition definition
    from_status_code VARCHAR(10) NOT NULL,
    to_status_code VARCHAR(10) NOT NULL,
    
    -- Transition validation
    is_allowed BOOLEAN DEFAULT true,
    requires_reason BOOLEAN DEFAULT false,
    requires_supervisor_approval BOOLEAN DEFAULT false,
    minimum_duration_seconds INTEGER DEFAULT 0,
    maximum_duration_seconds INTEGER,
    
    -- Business rules
    allowed_time_windows JSONB DEFAULT '{}',
    restricted_days JSONB DEFAULT '[]',
    employee_role_restrictions JSONB DEFAULT '[]',
    
    -- Automatic transitions
    auto_transition_enabled BOOLEAN DEFAULT false,
    auto_transition_delay_seconds INTEGER,
    auto_transition_target_status VARCHAR(10),
    
    -- Validation rules
    validation_rules JSONB DEFAULT '{}',
    warning_conditions JSONB DEFAULT '{}',
    error_conditions JSONB DEFAULT '{}',
    
    -- Rule metadata
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (from_status_code) REFERENCES work_status_types(status_code) ON DELETE CASCADE,
    FOREIGN KEY (to_status_code) REFERENCES work_status_types(status_code) ON DELETE CASCADE,
    FOREIGN KEY (auto_transition_target_status) REFERENCES work_status_types(status_code) ON DELETE SET NULL,
    
    UNIQUE(from_status_code, to_status_code)
);

-- =============================================================================
-- 6. EFFICIENCY CONFIGURATION
-- =============================================================================

-- Work time efficiency configuration
CREATE TABLE efficiency_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL UNIQUE,
    config_name VARCHAR(200) NOT NULL,
    
    -- Department/role scope
    applies_to_department_id UUID,
    applies_to_role VARCHAR(100),
    applies_to_skill_group VARCHAR(100),
    
    -- Efficiency targets
    target_productive_time_percentage DECIMAL(5,2) DEFAULT 85.0,
    target_talk_time_percentage DECIMAL(5,2) DEFAULT 60.0,
    target_break_time_percentage DECIMAL(5,2) DEFAULT 15.0,
    target_availability_percentage DECIMAL(5,2) DEFAULT 90.0,
    
    -- Warning thresholds
    warning_productive_time_percentage DECIMAL(5,2) DEFAULT 75.0,
    warning_talk_time_percentage DECIMAL(5,2) DEFAULT 50.0,
    warning_break_time_percentage DECIMAL(5,2) DEFAULT 25.0,
    warning_availability_percentage DECIMAL(5,2) DEFAULT 80.0,
    
    -- Critical thresholds
    critical_productive_time_percentage DECIMAL(5,2) DEFAULT 65.0,
    critical_talk_time_percentage DECIMAL(5,2) DEFAULT 40.0,
    critical_break_time_percentage DECIMAL(5,2) DEFAULT 35.0,
    critical_availability_percentage DECIMAL(5,2) DEFAULT 70.0,
    
    -- Calculation settings
    calculation_frequency VARCHAR(20) DEFAULT 'daily' CHECK (calculation_frequency IN (
        'real_time', 'hourly', 'daily', 'weekly'
    )),
    minimum_measurement_hours DECIMAL(3,1) DEFAULT 4.0,
    exclude_weekends BOOLEAN DEFAULT false,
    exclude_holidays BOOLEAN DEFAULT false,
    
    -- Alerting configuration
    enable_real_time_alerts BOOLEAN DEFAULT true,
    enable_daily_reports BOOLEAN DEFAULT true,
    enable_weekly_summaries BOOLEAN DEFAULT true,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (applies_to_department_id) REFERENCES departments(id) ON DELETE CASCADE
);

-- =============================================================================
-- 7. REAL-TIME PRODUCTIVITY MONITORING
-- =============================================================================

-- Real-time productivity monitoring
CREATE TABLE real_time_productivity_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monitoring_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    
    -- Current status
    current_status_code VARCHAR(10) NOT NULL,
    current_status_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    current_status_duration_seconds INTEGER DEFAULT 0,
    
    -- Today's metrics (rolling)
    today_total_time_seconds INTEGER DEFAULT 0,
    today_productive_time_seconds INTEGER DEFAULT 0,
    today_talk_time_seconds INTEGER DEFAULT 0,
    today_break_time_seconds INTEGER DEFAULT 0,
    
    -- Real-time percentages
    current_productive_time_percentage DECIMAL(5,2) DEFAULT 0.0,
    current_talk_time_percentage DECIMAL(5,2) DEFAULT 0.0,
    current_break_time_percentage DECIMAL(5,2) DEFAULT 0.0,
    current_availability_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Target variance
    productive_time_variance DECIMAL(5,2) DEFAULT 0.0,
    talk_time_variance DECIMAL(5,2) DEFAULT 0.0,
    break_time_variance DECIMAL(5,2) DEFAULT 0.0,
    
    -- Alert status
    has_active_alerts BOOLEAN DEFAULT false,
    alert_level VARCHAR(20) DEFAULT 'normal' CHECK (alert_level IN ('normal', 'warning', 'critical')),
    last_alert_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Monitoring metadata
    last_update_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_freshness_seconds INTEGER DEFAULT 0,
    monitoring_status VARCHAR(20) DEFAULT 'active' CHECK (monitoring_status IN ('active', 'paused', 'stopped')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (current_status_code) REFERENCES work_status_types(status_code) ON DELETE RESTRICT,
    
    UNIQUE(employee_id)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Work status queries
CREATE INDEX idx_work_status_types_code ON work_status_types(status_code);
CREATE INDEX idx_work_status_types_productive ON work_status_types(productivity_type);
CREATE INDEX idx_work_status_types_active ON work_status_types(is_active) WHERE is_active = true;
CREATE INDEX idx_work_status_types_selectable ON work_status_types(is_user_selectable) WHERE is_user_selectable = true;

-- Productivity rule queries
CREATE INDEX idx_productivity_calculation_rules_type ON productivity_calculation_rules(calculation_type);
CREATE INDEX idx_productivity_calculation_rules_active ON productivity_calculation_rules(is_active) WHERE is_active = true;
CREATE INDEX idx_productivity_calculation_rules_period ON productivity_calculation_rules(calculation_period);

-- Status tracking queries
CREATE INDEX idx_employee_status_tracking_employee ON employee_status_tracking(employee_id);
CREATE INDEX idx_employee_status_tracking_status ON employee_status_tracking(status_code);
CREATE INDEX idx_employee_status_tracking_start_time ON employee_status_tracking(status_start_time);
CREATE INDEX idx_employee_status_tracking_date ON employee_status_tracking(DATE(status_start_time));
CREATE INDEX idx_employee_status_tracking_productive ON employee_status_tracking(is_productive_time);
CREATE INDEX idx_employee_status_tracking_active ON employee_status_tracking(status_end_time) WHERE status_end_time IS NULL;

-- Productivity metrics queries
CREATE INDEX idx_productivity_metrics_employee ON productivity_metrics(employee_id);
CREATE INDEX idx_productivity_metrics_date ON productivity_metrics(calculation_date);
CREATE INDEX idx_productivity_metrics_period ON productivity_metrics(calculation_period);
CREATE INDEX idx_productivity_metrics_employee_date ON productivity_metrics(employee_id, calculation_date);
CREATE INDEX idx_productivity_metrics_target ON productivity_metrics(meets_productivity_target);

-- Transition rule queries
CREATE INDEX idx_status_transition_rules_from ON status_transition_rules(from_status_code);
CREATE INDEX idx_status_transition_rules_to ON status_transition_rules(to_status_code);
CREATE INDEX idx_status_transition_rules_allowed ON status_transition_rules(is_allowed) WHERE is_allowed = true;
CREATE INDEX idx_status_transition_rules_active ON status_transition_rules(is_active) WHERE is_active = true;

-- Configuration queries
CREATE INDEX idx_efficiency_configuration_department ON efficiency_configuration(applies_to_department_id);
CREATE INDEX idx_efficiency_configuration_role ON efficiency_configuration(applies_to_role);
CREATE INDEX idx_efficiency_configuration_active ON efficiency_configuration(is_active) WHERE is_active = true;

-- Real-time monitoring queries
CREATE INDEX idx_real_time_productivity_employee ON real_time_productivity_monitoring(employee_id);
CREATE INDEX idx_real_time_productivity_status ON real_time_productivity_monitoring(current_status_code);
CREATE INDEX idx_real_time_productivity_alerts ON real_time_productivity_monitoring(has_active_alerts) WHERE has_active_alerts = true;
CREATE INDEX idx_real_time_productivity_update ON real_time_productivity_monitoring(last_update_timestamp);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_efficiency_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER work_status_types_update_trigger
    BEFORE UPDATE ON work_status_types
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

CREATE TRIGGER productivity_calculation_rules_update_trigger
    BEFORE UPDATE ON productivity_calculation_rules
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

CREATE TRIGGER employee_status_tracking_update_trigger
    BEFORE UPDATE ON employee_status_tracking
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

CREATE TRIGGER status_transition_rules_update_trigger
    BEFORE UPDATE ON status_transition_rules
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

CREATE TRIGGER efficiency_configuration_update_trigger
    BEFORE UPDATE ON efficiency_configuration
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

CREATE TRIGGER real_time_productivity_monitoring_update_trigger
    BEFORE UPDATE ON real_time_productivity_monitoring
    FOR EACH ROW EXECUTE FUNCTION update_efficiency_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active work status types
CREATE VIEW v_active_work_status_types AS
SELECT 
    status_code,
    status_type,
    status_description,
    productivity_type,
    is_productive_time,
    counts_toward_net_load,
    counts_as_talk_time,
    counts_as_break_time,
    color_code,
    display_order
FROM work_status_types
WHERE is_active = true
  AND is_user_selectable = true
ORDER BY display_order, status_type;

-- Current employee status view
CREATE VIEW v_current_employee_status AS
SELECT 
    e.id as employee_id,
    e.full_name,
    est.status_code,
    wst.status_type,
    wst.productivity_type,
    est.status_start_time,
    EXTRACT(EPOCH FROM CURRENT_TIMESTAMP - est.status_start_time)::INTEGER as current_duration_seconds,
    est.reason_description,
    wst.color_code
FROM employees e
LEFT JOIN employee_status_tracking est ON e.id = est.employee_id 
    AND est.status_end_time IS NULL
LEFT JOIN work_status_types wst ON est.status_code = wst.status_code
WHERE e.is_active = true
ORDER BY e.full_name;

-- Daily productivity summary
CREATE VIEW v_daily_productivity_summary AS
SELECT 
    pm.employee_id,
    e.full_name,
    pm.calculation_date,
    pm.productive_time_percentage,
    pm.talk_time_percentage,
    pm.break_time_percentage,
    pm.availability_percentage,
    pm.overall_efficiency_score,
    pm.meets_productivity_target,
    CASE 
        WHEN pm.productive_time_percentage >= ec.target_productive_time_percentage THEN 'target'
        WHEN pm.productive_time_percentage >= ec.warning_productive_time_percentage THEN 'warning'
        ELSE 'critical'
    END as performance_level
FROM productivity_metrics pm
JOIN employees e ON pm.employee_id = e.id
LEFT JOIN efficiency_configuration ec ON (ec.applies_to_department_id IS NULL OR ec.applies_to_department_id = e.department_id)
WHERE pm.calculation_period = 'daily'
  AND pm.calculation_date >= CURRENT_DATE - INTERVAL '7 days'
  AND ec.is_active = true
ORDER BY pm.calculation_date DESC, e.full_name;

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert work status types from BDD lines 16-24
INSERT INTO work_status_types (status_code, status_type, status_description, productivity_type, is_productive_time, counts_toward_net_load, counts_as_talk_time, counts_as_break_time, color_code, display_order) VALUES
('AVL', 'Available', 'Ready for calls', 'productive', true, false, false, false, '#00ff00', 1),
('CALL', 'In Call', 'Handling customer', 'productive', true, true, true, false, '#0066ff', 2),
('ACW', 'After Call Work', 'Post-call processing', 'productive', true, false, false, false, '#3366ff', 3),
('BRK', 'Break', 'Rest period', 'non_productive', false, false, false, true, '#ffcc00', 4),
('LUN', 'Lunch', 'Lunch break', 'non_productive', false, false, false, true, '#ff9900', 5),
('TRN', 'Training', 'Training session', 'productive', true, false, false, false, '#9966ff', 6),
('MTG', 'Meeting', 'Team meeting', 'productive', true, false, false, false, '#ff6699', 7),
('OFF', 'Offline', 'Not available', 'non_productive', false, false, false, false, '#cccccc', 8);

-- Insert productivity calculation rules
INSERT INTO productivity_calculation_rules (rule_id, rule_name, calculation_type, numerator_statuses, denominator_statuses, calculation_formula) VALUES
('productive_time_daily', 'Daily Productive Time Percentage', 'productive_time_percentage', 
 '["AVL", "CALL", "ACW", "TRN", "MTG"]', '["AVL", "CALL", "ACW", "BRK", "LUN", "TRN", "MTG", "OFF"]', 
 '(productive_seconds / total_seconds) * 100'),
('talk_time_daily', 'Daily Talk Time Percentage', 'talk_time_percentage',
 '["CALL"]', '["AVL", "CALL", "ACW", "BRK", "LUN", "TRN", "MTG", "OFF"]',
 '(talk_seconds / total_seconds) * 100'),
('break_time_daily', 'Daily Break Time Percentage', 'break_time_percentage',
 '["BRK", "LUN"]', '["AVL", "CALL", "ACW", "BRK", "LUN", "TRN", "MTG", "OFF"]',
 '(break_seconds / total_seconds) * 100');

-- Insert efficiency configuration
INSERT INTO efficiency_configuration (config_id, config_name, target_productive_time_percentage, target_talk_time_percentage, target_break_time_percentage) VALUES
('default_config', 'Default Efficiency Configuration', 85.0, 60.0, 15.0);

-- Insert sample status transition rules
INSERT INTO status_transition_rules (rule_id, rule_name, from_status_code, to_status_code, is_allowed, requires_reason) VALUES
('avl_to_call', 'Available to In Call', 'AVL', 'CALL', true, false),
('call_to_acw', 'In Call to After Call Work', 'CALL', 'ACW', true, false),
('acw_to_avl', 'After Call Work to Available', 'ACW', 'AVL', true, false),
('avl_to_brk', 'Available to Break', 'AVL', 'BRK', true, false),
('brk_to_avl', 'Break to Available', 'BRK', 'AVL', true, false),
('avl_to_off', 'Available to Offline', 'AVL', 'OFF', true, true);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE work_status_types IS 'BDD Lines 15-31: Work status parameter configuration with productivity classification';
COMMENT ON TABLE productivity_calculation_rules IS 'Productivity calculation rules for different time efficiency metrics';
COMMENT ON TABLE employee_status_tracking IS 'Employee status tracking with productivity measurement and adherence monitoring';
COMMENT ON TABLE productivity_metrics IS 'Calculated productivity metrics with efficiency scores and target comparisons';
COMMENT ON TABLE status_transition_rules IS 'Status transition validation and business rules';
COMMENT ON TABLE efficiency_configuration IS 'Work time efficiency configuration with targets and thresholds';
COMMENT ON TABLE real_time_productivity_monitoring IS 'Real-time productivity monitoring with alert management';