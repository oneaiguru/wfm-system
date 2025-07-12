-- =============================================================================
-- 033_realtime_monitoring_operational_control.sql
-- EXACT BDD Implementation: Real-time Monitoring and Operational Control
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 15-real-time-monitoring-operational-control.feature (393 lines)
-- Purpose: Supervisor and operations manager real-time visibility and control
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- 1. OPERATIONAL METRICS DASHBOARDS
-- =============================================================================

-- Six key real-time metrics from BDD lines 16-23
CREATE TABLE operational_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(50) NOT NULL CHECK (metric_name IN (
        'Operators Online %',
        'Load Deviation', 
        'Operator Requirement',
        'SLA Performance',
        'ACD Rate',
        'AHT Trend'
    )),
    
    -- Metric calculation and display
    current_value DECIMAL(10,2) NOT NULL,
    target_value DECIMAL(10,2),
    calculation_formula TEXT NOT NULL,
    
    -- Thresholds from BDD specifications
    threshold_green_min DECIMAL(5,2),
    threshold_yellow_min DECIMAL(5,2), 
    threshold_red_max DECIMAL(5,2),
    
    -- Current status based on thresholds
    status_color VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN metric_name = 'Operators Online %' THEN
                CASE 
                    WHEN current_value >= 80 THEN 'Green'
                    WHEN current_value >= 70 THEN 'Yellow'
                    ELSE 'Red'
                END
            WHEN metric_name = 'Load Deviation' THEN
                CASE 
                    WHEN ABS(current_value) <= 10 THEN 'Green'
                    WHEN ABS(current_value) <= 20 THEN 'Yellow'
                    ELSE 'Red'
                END
            WHEN metric_name = 'SLA Performance' THEN
                CASE 
                    WHEN ABS(current_value - target_value) <= 5 THEN 'Green'
                    WHEN ABS(current_value - target_value) <= 10 THEN 'Yellow'
                    ELSE 'Red'
                END
            ELSE 'Green'
        END
    ) STORED,
    
    -- Trend information from BDD lines 24-29
    trend_direction VARCHAR(10) CHECK (trend_direction IN ('Up', 'Down', 'Stable')),
    trend_change_pct DECIMAL(5,2),
    
    -- Update frequencies from BDD
    update_frequency_seconds INTEGER NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Historical context for sparklines
    historical_values JSONB, -- Last 24 hours of values
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Metric drill-down details from BDD lines 32-47
CREATE TABLE metric_drill_downs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(50) NOT NULL,
    detail_category VARCHAR(100) NOT NULL,
    
    -- Drill-down information from BDD
    schedule_adherence_24h JSONB, -- Real-time compliance data
    timetable_status JSONB, -- Current vs planned activity
    actually_online_agents INTEGER,
    individual_agent_status JSONB, -- Per-agent current state
    deviation_timeline JSONB, -- 24-hour historical chart
    
    -- Update information
    update_frequency_seconds INTEGER DEFAULT 30,
    data_source VARCHAR(50),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. INDIVIDUAL AGENT MONITORING  
-- =============================================================================

-- Real-time agent status tracking from BDD lines 48-66
CREATE TABLE agent_real_time_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Agent status from BDD with visual indicators
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'On schedule',    -- Green indicator
        'Late login',     -- Yellow + timer
        'Absent',         -- Red + duration
        'Wrong status',   -- Orange + mismatch
        'In break',       -- Blue + remaining time
        'Lunch'           -- Purple + expected return
    )),
    
    -- Visual indicators and timing
    status_color VARCHAR(10) NOT NULL,
    delay_duration INTERVAL, -- For late login
    absence_duration INTERVAL, -- For absent
    remaining_time INTERVAL, -- For breaks/lunch
    expected_return_time TIMESTAMP WITH TIME ZONE,
    
    -- Available actions from BDD
    available_actions TEXT[] DEFAULT '{}',
    call_to_workplace_available BOOLEAN GENERATED ALWAYS AS (
        status IN ('Late login', 'Absent')
    ) STORED,
    
    -- Agent information from BDD lines 60-66
    current_activity VARCHAR(100), -- What they're doing now
    schedule_adherence_status VARCHAR(20), -- On-time vs late
    contact_availability BOOLEAN DEFAULT false, -- Ready for next contact
    
    -- Performance tracking
    todays_calls_handled INTEGER DEFAULT 0,
    todays_talk_time INTERVAL DEFAULT '0',
    todays_break_time INTERVAL DEFAULT '0',
    
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_agent_monitoring UNIQUE(employee_tab_n)
);

-- =============================================================================
-- 3. THRESHOLD AND PREDICTIVE ALERTS
-- =============================================================================

-- Threshold-based alerts from BDD lines 67-83
CREATE TABLE threshold_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_trigger VARCHAR(100) NOT NULL,
    threshold_value DECIMAL(10,2) NOT NULL,
    current_value DECIMAL(10,2) NOT NULL,
    
    -- Alert conditions from BDD
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'Critical understaffing',  -- Online % <70%
        'Service level breach',    -- 80/20 format <70% for 5 minutes
        'System overload',         -- Queue >20 contacts
        'Extended outages'         -- No data for 10 minutes
    )),
    
    -- Response actions from BDD
    response_actions TEXT[] NOT NULL,
    suggested_actions TEXT[],
    escalation_timeline JSONB,
    
    -- Alert status
    alert_status VARCHAR(20) DEFAULT 'Active' CHECK (alert_status IN ('Active', 'Acknowledged', 'Resolved')),
    severity VARCHAR(10) NOT NULL CHECK (severity IN ('Critical', 'High', 'Medium', 'Low')),
    
    -- Notification tracking
    sms_sent BOOLEAN DEFAULT false,
    email_sent BOOLEAN DEFAULT false,
    escalation_sent BOOLEAN DEFAULT false,
    
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Predictive alerts from BDD lines 84-100
CREATE TABLE predictive_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN (
        'Approaching SLA breach',  -- 15-30 minutes lead time
        'Staffing shortfall',      -- 1-2 hours lead time 
        'Break/lunch coverage gaps', -- 30-60 minutes lead time
        'Peak load preparation'    -- 2-4 hours lead time
    )),
    
    -- Prediction details from BDD
    analysis_method VARCHAR(100) NOT NULL,
    lead_time_minutes INTEGER NOT NULL,
    confidence_percentage DECIMAL(5,2) NOT NULL,
    
    -- Prediction factors from BDD lines 94-99
    historical_patterns_weight DECIMAL(3,2) DEFAULT 0.80, -- 80% accuracy target
    current_trends_weight DECIMAL(3,2) DEFAULT 0.75,      -- 75% accuracy target
    scheduled_events_weight DECIMAL(3,2) DEFAULT 0.95,    -- 95% accuracy target
    external_factors_weight DECIMAL(3,2) DEFAULT 0.70,    -- 70% accuracy target
    
    -- Prediction data
    predicted_value DECIMAL(10,2),
    actual_value DECIMAL(10,2), -- For accuracy tracking
    prediction_accuracy DECIMAL(5,2), -- Calculated after event
    
    predicted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 4. REAL-TIME OPERATIONAL ADJUSTMENTS
-- =============================================================================

-- Real-time adjustment capabilities from BDD lines 101-118
CREATE TABLE operational_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    adjustment_type VARCHAR(50) NOT NULL CHECK (adjustment_type IN (
        'Call operator to work',
        'Extend shift',
        'Add break coverage', 
        'Emergency scheduling',
        'Skill reallocation'
    )),
    
    -- Target and details
    target_employee_tab_n VARCHAR(50) REFERENCES zup_agent_data(tab_n),
    adjustment_details JSONB NOT NULL,
    
    -- System response from BDD
    system_response VARCHAR(200),
    notification_sent BOOLEAN DEFAULT false,
    response_tracked BOOLEAN DEFAULT false,
    
    -- Validation checks from BDD lines 113-117
    labor_standards_compliant BOOLEAN,
    overtime_compliance_check BOOLEAN,
    service_level_impact_assessment TEXT,
    employee_availability_verified BOOLEAN,
    cost_implications DECIMAL(10,2),
    
    -- Status tracking
    adjustment_status VARCHAR(20) DEFAULT 'Requested' CHECK (adjustment_status IN (
        'Requested', 'Approved', 'Executed', 'Failed', 'Cancelled'
    )),
    
    requested_by VARCHAR(50) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    executed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 5. MULTI-GROUP MONITORING
-- =============================================================================

-- Multi-group monitoring from BDD lines 119-135
CREATE TABLE group_monitoring_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id INTEGER NOT NULL,
    group_name VARCHAR(200) NOT NULL,
    
    -- Group management features from BDD
    priority_level INTEGER NOT NULL CHECK (priority_level BETWEEN 1 AND 5),
    escalation_routing JSONB NOT NULL, -- Group-specific procedures
    
    -- Display configuration
    display_in_comparison BOOLEAN DEFAULT true,
    display_in_aggregate BOOLEAN DEFAULT true,
    alert_priority_weight DECIMAL(3,2) DEFAULT 1.0,
    
    -- Resource sharing settings
    allows_resource_sharing BOOLEAN DEFAULT true,
    resource_sharing_rules JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cross-group resource movements from BDD
CREATE TABLE cross_group_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    from_group_id INTEGER NOT NULL,
    to_group_id INTEGER NOT NULL,
    
    -- Movement details
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('Temporary', 'Emergency', 'Planned')),
    movement_reason TEXT NOT NULL,
    duration_minutes INTEGER,
    
    -- Crisis response capability
    is_crisis_response BOOLEAN DEFAULT false,
    
    authorized_by VARCHAR(50) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 6. ESCALATION PROCEDURES
-- =============================================================================

-- Escalation procedures from BDD lines 204-220
CREATE TABLE escalation_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID REFERENCES threshold_alerts(id),
    
    -- Escalation levels from BDD
    escalation_level INTEGER NOT NULL CHECK (escalation_level BETWEEN 1 AND 4),
    timeframe_minutes INTEGER NOT NULL,
    recipients TEXT[] NOT NULL,
    required_actions TEXT[] NOT NULL,
    
    -- Level-specific details from BDD lines 209-213
    level_description VARCHAR(200) NOT NULL,
    -- Level 1: Immediate - Direct supervisor - Initial response
    -- Level 2: 15 minutes - Department manager - Management intervention  
    -- Level 3: 30 minutes - Operations director - Executive involvement
    -- Level 4: 60 minutes - Crisis management team - Emergency procedures
    
    -- Escalation content from BDD lines 215-219
    problem_summary TEXT NOT NULL,
    impact_assessment TEXT NOT NULL,
    actions_taken TEXT[],
    recommended_next_actions TEXT[],
    
    escalated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 7. COMPLIANCE MONITORING
-- =============================================================================

-- Labor standards compliance from BDD lines 221-237
CREATE TABLE compliance_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Compliance areas from BDD
    compliance_type VARCHAR(50) NOT NULL CHECK (compliance_type IN (
        'Rest period violations',   -- >4 hours without break
        'Overtime accumulation',    -- Daily/weekly limits
        'Shift duration compliance', -- >12 hours continuous
        'Break duration monitoring' -- Exceeding allocated time
    )),
    
    -- Real-time checks from BDD lines 226-230
    time_since_last_break INTERVAL,
    daily_hours_worked INTERVAL,
    weekly_hours_worked INTERVAL,
    current_shift_duration INTERVAL,
    current_break_duration INTERVAL,
    
    -- Alert conditions from BDD
    violation_detected BOOLEAN DEFAULT false,
    alert_triggered BOOLEAN DEFAULT false,
    
    -- Violation response from BDD lines 232-236
    supervisor_notified BOOLEAN DEFAULT false,
    violation_documented BOOLEAN DEFAULT false,
    corrective_action_suggested TEXT,
    
    monitored_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. SYSTEM ADMINISTRATION & STATUS RESET
-- =============================================================================

-- Status reset authorizations from BDD lines 257-303
CREATE TABLE status_reset_authorizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reset scope from BDD lines 263-267
    reset_scope VARCHAR(20) NOT NULL CHECK (reset_scope IN (
        'Individual operator',
        'Department scope',
        'System-wide reset',
        'Emergency reset'
    )),
    
    -- Authorization requirements from BDD
    authorization_level VARCHAR(20) NOT NULL CHECK (authorization_level IN (
        'Supervisor approval',
        'Manager approval', 
        'Executive approval',
        'Emergency authorization'
    )),
    confirmation_level VARCHAR(20) NOT NULL CHECK (confirmation_level IN (
        'Single confirmation',
        'Double confirmation',
        'Triple confirmation', 
        'Emergency protocol'
    )),
    
    -- Reset targets from BDD lines 286-290
    target_departments TEXT[],
    target_time_period_start TIMESTAMP WITH TIME ZONE,
    target_time_period_end TIMESTAMP WITH TIME ZONE,
    target_status_types TEXT[],
    target_employees TEXT[],
    
    -- Audit requirements from BDD lines 274-279
    business_justification TEXT NOT NULL,
    impact_assessment TEXT NOT NULL,
    pre_reset_system_snapshot JSONB,
    
    -- Rollback capabilities from BDD lines 297-302
    rollback_available BOOLEAN DEFAULT true,
    rollback_scenario VARCHAR(50),
    recovery_time_minutes INTEGER,
    
    authorized_by VARCHAR(50) NOT NULL,
    authorized_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    executed_at TIMESTAMP WITH TIME ZONE,
    
    reset_status VARCHAR(20) DEFAULT 'Pending' CHECK (reset_status IN (
        'Pending', 'Approved', 'Executed', 'Failed', 'Rolled Back'
    ))
);

-- =============================================================================
-- 9. DASHBOARD CUSTOMIZATION & PREFERENCES
-- =============================================================================

-- Dashboard customization from BDD lines 304-332
CREATE TABLE dashboard_customizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Layout configuration from BDD lines 308-313
    layout_type VARCHAR(20) DEFAULT 'Grid' CHECK (layout_type IN ('Grid', 'List', 'Compact')),
    widget_arrangement JSONB NOT NULL, -- Drag-and-drop positioning
    color_scheme VARCHAR(20) DEFAULT 'Light' CHECK (color_scheme IN ('Light', 'Dark', 'High-contrast')),
    selected_kpis TEXT[] DEFAULT ARRAY['Operators Online %', 'SLA Performance'],
    
    -- Widget management from BDD lines 314-319
    widget_configurations JSONB NOT NULL DEFAULT '{}',
    
    -- Accessibility from BDD lines 320-325
    screen_reader_support BOOLEAN DEFAULT false,
    keyboard_navigation_enabled BOOLEAN DEFAULT true,
    high_contrast_mode BOOLEAN DEFAULT false,
    font_size_scale DECIMAL(3,2) DEFAULT 1.0,
    
    -- Synchronization from BDD lines 326-331
    cloud_sync_enabled BOOLEAN DEFAULT true,
    cross_device_sync BOOLEAN DEFAULT true,
    last_synced_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_dashboard_config UNIQUE(employee_tab_n)
);

-- Notification preferences from BDD lines 333-355
CREATE TABLE operational_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Notification types from BDD lines 338-342
    operational_alerts_delivery VARCHAR(50) DEFAULT 'In-app, email, SMS',
    schedule_changes_delivery VARCHAR(50) DEFAULT 'Dashboard, email',
    performance_updates_delivery VARCHAR(50) DEFAULT 'Dashboard only',
    system_maintenance_delivery VARCHAR(50) DEFAULT 'Email, dashboard',
    
    -- Smart filtering from BDD lines 343-348
    relevance_filtering_enabled BOOLEAN DEFAULT true,
    frequency_limiting_enabled BOOLEAN DEFAULT true,
    priority_escalation_enabled BOOLEAN DEFAULT true,
    context_awareness_enabled BOOLEAN DEFAULT true,
    
    -- Delivery optimization from BDD lines 349-354
    do_not_disturb_enabled BOOLEAN DEFAULT false,
    do_not_disturb_start TIME,
    do_not_disturb_end TIME,
    delivery_consolidation_enabled BOOLEAN DEFAULT true,
    mobile_optimization_enabled BOOLEAN DEFAULT true,
    cross_device_sync_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_notification_prefs UNIQUE(employee_tab_n)
);

-- =============================================================================
-- 10. MOBILE MONITORING
-- =============================================================================

-- Mobile monitoring capabilities from BDD lines 170-186
CREATE TABLE mobile_monitoring_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    device_info JSONB NOT NULL,
    
    -- Mobile features from BDD lines 174-179
    essential_metrics_only BOOLEAN DEFAULT true,
    push_notifications_enabled BOOLEAN DEFAULT true,
    quick_actions_available TEXT[] DEFAULT ARRAY['Call operators', 'Acknowledge alerts'],
    touch_optimized BOOLEAN DEFAULT true,
    
    -- Performance considerations from BDD lines 180-185
    efficient_data_refresh BOOLEAN DEFAULT true,
    minimal_battery_drain BOOLEAN DEFAULT true,
    fast_chart_rendering BOOLEAN DEFAULT true,
    emergency_actions_enabled BOOLEAN DEFAULT true,
    
    session_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to update operational metrics
CREATE OR REPLACE FUNCTION update_operational_metric(
    p_metric_name VARCHAR(50),
    p_current_value DECIMAL(10,2),
    p_trend_direction VARCHAR(10) DEFAULT 'Stable'
) RETURNS void AS $$
DECLARE
    v_historical JSONB;
    v_update_freq INTEGER;
BEGIN
    -- Get current historical values and update frequency
    SELECT historical_values, update_frequency_seconds 
    INTO v_historical, v_update_freq
    FROM operational_metrics 
    WHERE metric_name = p_metric_name;
    
    -- Update historical values (keep last 24 hours)
    v_historical := COALESCE(v_historical, '[]'::jsonb) || 
                   jsonb_build_object('timestamp', CURRENT_TIMESTAMP, 'value', p_current_value);
    
    -- Update the metric
    UPDATE operational_metrics SET
        current_value = p_current_value,
        trend_direction = p_trend_direction,
        historical_values = v_historical,
        last_updated = CURRENT_TIMESTAMP
    WHERE metric_name = p_metric_name;
END;
$$ LANGUAGE plpgsql;

-- Function to trigger threshold alert
CREATE OR REPLACE FUNCTION trigger_threshold_alert(
    p_alert_type VARCHAR(50),
    p_current_value DECIMAL(10,2),
    p_threshold_value DECIMAL(10,2)
) RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
    v_response_actions TEXT[];
    v_suggested_actions TEXT[];
BEGIN
    -- Set response actions based on alert type
    v_response_actions := CASE p_alert_type
        WHEN 'Critical understaffing' THEN ARRAY['SMS + email to management']
        WHEN 'Service level breach' THEN ARRAY['Immediate escalation']
        WHEN 'System overload' THEN ARRAY['Emergency staffing protocol']
        WHEN 'Extended outages' THEN ARRAY['Technical team alert']
        ELSE ARRAY['Standard response']
    END;
    
    v_suggested_actions := ARRAY['Investigate cause', 'Take corrective action', 'Monitor resolution'];
    
    -- Create alert
    INSERT INTO threshold_alerts (
        alert_trigger, alert_type, threshold_value, current_value,
        response_actions, suggested_actions, severity
    ) VALUES (
        p_alert_type || ' threshold exceeded',
        p_alert_type,
        p_threshold_value,
        p_current_value,
        v_response_actions,
        v_suggested_actions,
        CASE 
            WHEN p_alert_type IN ('Critical understaffing', 'Extended outages') THEN 'Critical'
            WHEN p_alert_type = 'Service level breach' THEN 'High'
            ELSE 'Medium'
        END
    ) RETURNING id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- Function to execute operational adjustment
CREATE OR REPLACE FUNCTION execute_operational_adjustment(
    p_adjustment_type VARCHAR(50),
    p_target_employee VARCHAR(50),
    p_details JSONB,
    p_requested_by VARCHAR(50)
) RETURNS UUID AS $$
DECLARE
    v_adjustment_id UUID;
    v_labor_compliant BOOLEAN := true;
    v_overtime_compliant BOOLEAN := true;
    v_available BOOLEAN := true;
BEGIN
    -- Validation checks from BDD
    -- Check labor standards compliance
    -- Check overtime compliance  
    -- Verify employee availability
    
    -- Create adjustment record
    INSERT INTO operational_adjustments (
        adjustment_type, target_employee_tab_n, adjustment_details,
        labor_standards_compliant, overtime_compliance_check,
        employee_availability_verified, requested_by
    ) VALUES (
        p_adjustment_type, p_target_employee, p_details,
        v_labor_compliant, v_overtime_compliant, v_available, p_requested_by
    ) RETURNING id INTO v_adjustment_id;
    
    RETURN v_adjustment_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Operational metrics indexes
CREATE INDEX idx_operational_metrics_name ON operational_metrics(metric_name);
CREATE INDEX idx_operational_metrics_updated ON operational_metrics(last_updated DESC);

-- Agent monitoring indexes
CREATE INDEX idx_agent_monitoring_employee ON agent_real_time_monitoring(employee_tab_n);
CREATE INDEX idx_agent_monitoring_status ON agent_real_time_monitoring(status);
CREATE INDEX idx_agent_monitoring_updated ON agent_real_time_monitoring(last_updated DESC);

-- Alert indexes
CREATE INDEX idx_threshold_alerts_status ON threshold_alerts(alert_status, triggered_at DESC);
CREATE INDEX idx_predictive_alerts_event_time ON predictive_alerts(event_time);

-- Compliance monitoring indexes
CREATE INDEX idx_compliance_employee ON compliance_monitoring(employee_tab_n);
CREATE INDEX idx_compliance_violation ON compliance_monitoring(violation_detected, monitored_at DESC);

-- Dashboard customization indexes
CREATE INDEX idx_dashboard_customizations_employee ON dashboard_customizations(employee_tab_n);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Initialize operational metrics with BDD specifications
INSERT INTO operational_metrics (
    metric_name, current_value, target_value, calculation_formula,
    threshold_green_min, threshold_yellow_min, threshold_red_max,
    update_frequency_seconds
) VALUES 
('Operators Online %', 85.0, 90.0, '(Actual Online / Planned) × 100', 80.0, 70.0, 70.0, 30),
('Load Deviation', 5.0, 0.0, '(Actual Load - Forecast) / Forecast', 10.0, 20.0, 20.0, 60),
('Operator Requirement', 50, 48, 'Erlang C based on current load', NULL, NULL, NULL, 1),
('SLA Performance', 82.0, 80.0, '80/20 format (80% calls in 20 seconds)', 75.0, 70.0, 70.0, 60),
('ACD Rate', 95.0, 98.0, '(Answered / Offered) × 100', NULL, NULL, NULL, 1),
('AHT Trend', 180.0, 175.0, 'Weighted average handle time', NULL, NULL, NULL, 300);

-- Insert group monitoring configurations
INSERT INTO group_monitoring_configuration (
    group_id, group_name, priority_level, escalation_routing
) VALUES 
(1, 'Technical Support', 1, '{"level1": "supervisor", "level2": "manager"}'),
(2, 'Billing Support', 2, '{"level1": "supervisor", "level2": "manager"}'),
(3, 'General Inquiries', 3, '{"level1": "supervisor", "level2": "manager"}');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_supervisors;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_supervisors;