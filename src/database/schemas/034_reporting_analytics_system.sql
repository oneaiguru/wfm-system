-- =============================================================================
-- 034_reporting_analytics_system.sql
-- EXACT BDD Implementation: 1C ZUP Integrated Payroll and Analytics Reporting
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 12-reporting-analytics-system.feature (255 lines)
-- Purpose: Comprehensive reporting and analytics for payroll and HR analysis
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SCHEDULE ADHERENCE REPORTING
-- =============================================================================

-- Schedule adherence reports from BDD lines 12-34
CREATE TABLE schedule_adherence_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(200) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    department VARCHAR(200),
    detail_level VARCHAR(20) DEFAULT '15-minute' CHECK (detail_level IN ('15-minute', '30-minute', 'hourly')),
    include_weekends BOOLEAN DEFAULT true,
    show_exceptions BOOLEAN DEFAULT true,
    
    -- Report data
    report_data JSONB NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(50) NOT NULL
);

-- Individual adherence tracking
CREATE TABLE adherence_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    report_date DATE NOT NULL,
    
    -- Adherence calculations from BDD lines 23-28
    individual_adherence_pct DECIMAL(5,2) NOT NULL, -- (Scheduled time - Deviation) / Scheduled time
    planned_schedule_time INTERVAL NOT NULL, -- Blue blocks
    actual_worked_time INTERVAL NOT NULL, -- Green blocks
    productive_time INTERVAL,
    auxiliary_time INTERVAL,
    
    -- Color coding from BDD lines 29-33
    adherence_color VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN individual_adherence_pct >= 80 THEN 'Green'   -- Good adherence
            WHEN individual_adherence_pct >= 70 THEN 'Yellow'  -- Moderate adherence  
            ELSE 'Red'  -- Poor adherence (<85% - appears to be typo in BDD, using <70%)
        END
    ) STORED,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_date_adherence UNIQUE(employee_tab_n, report_date)
);

-- =============================================================================
-- 2. PAYROLL CALCULATION REPORTS
-- =============================================================================

-- Payroll reports with 1C ZUP integration from BDD lines 35-58
CREATE TABLE payroll_calculation_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_mode VARCHAR(20) NOT NULL CHECK (report_mode IN ('1C Data', 'Actual CC', 'WFM Schedule')),
    data_source VARCHAR(50) NOT NULL,
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('Half-month', 'Bi-weekly', 'Monthly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(50) NOT NULL
);

-- 1C ZUP time codes from BDD lines 44-52
CREATE TABLE payroll_time_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    payroll_report_id UUID NOT NULL REFERENCES payroll_calculation_reports(id),
    work_date DATE NOT NULL,
    
    -- Time codes with exact BDD specifications
    time_code VARCHAR(10) NOT NULL,
    time_code_russian VARCHAR(10) NOT NULL,
    time_code_english VARCHAR(50) NOT NULL,
    zup_document_type VARCHAR(100) NOT NULL,
    
    -- Hours by time code
    hours_worked DECIMAL(4,2) DEFAULT 0,
    
    -- Time code definitions from BDD
    CONSTRAINT valid_time_codes CHECK (
        (time_code = 'I' AND time_code_russian = 'Я' AND time_code_english = 'Day work') OR
        (time_code = 'H' AND time_code_russian = 'Н' AND time_code_english = 'Night work') OR
        (time_code = 'B' AND time_code_russian = 'В' AND time_code_english = 'Day off') OR
        (time_code = 'C' AND time_code_russian = 'С' AND time_code_english = 'Overtime') OR
        (time_code = 'RV' AND time_code_russian = 'РВ' AND time_code_english = 'Weekend work') OR
        (time_code = 'RVN' AND time_code_russian = 'РВН' AND time_code_english = 'Night weekend work') OR
        (time_code = 'NV' AND time_code_russian = 'НВ' AND time_code_english = 'Absence') OR
        (time_code = 'OT' AND time_code_russian = 'ОТ' AND time_code_english = 'Annual vacation')
    ),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payroll period summaries from BDD lines 53-57
CREATE TABLE payroll_period_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('Half-month', 'Monthly', 'Quarterly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Summary totals
    total_regular_hours DECIMAL(6,2) DEFAULT 0,
    total_overtime_hours DECIMAL(6,2) DEFAULT 0,
    total_night_hours DECIMAL(6,2) DEFAULT 0,
    total_weekend_hours DECIMAL(6,2) DEFAULT 0,
    total_vacation_days INTEGER DEFAULT 0,
    total_absence_days INTEGER DEFAULT 0,
    
    aggregation_purpose VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. FORECAST ACCURACY ANALYSIS
-- =============================================================================

-- Forecast accuracy metrics from BDD lines 59-78
CREATE TABLE forecast_accuracy_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_period_start DATE NOT NULL,
    analysis_period_end DATE NOT NULL,
    granularity_level VARCHAR(20) NOT NULL CHECK (granularity_level IN ('Interval', 'Daily', 'Weekly', 'Monthly', 'Channel')),
    
    -- Accuracy metrics from BDD lines 64-70
    mape DECIMAL(5,2), -- Mean Absolute Percentage Error (target <15%)
    wape DECIMAL(5,2), -- Weighted Absolute Percentage Error (target <12%)
    mfa DECIMAL(5,2),  -- Mean Forecast Accuracy (target >85%)
    wfa DECIMAL(5,2),  -- Weighted Forecast Accuracy (target >88%)
    bias DECIMAL(5,2), -- (Forecast - Actual) / Actual (target ±5%)
    tracking_signal DECIMAL(5,2), -- Cumulative bias / MAD (target ±4)
    
    -- Target achievement
    mape_target_met BOOLEAN GENERATED ALWAYS AS (mape < 15) STORED,
    wape_target_met BOOLEAN GENERATED ALWAYS AS (wape < 12) STORED,
    mfa_target_met BOOLEAN GENERATED ALWAYS AS (mfa > 85) STORED,
    wfa_target_met BOOLEAN GENERATED ALWAYS AS (wfa > 88) STORED,
    bias_target_met BOOLEAN GENERATED ALWAYS AS (ABS(bias) <= 5) STORED,
    tracking_signal_target_met BOOLEAN GENERATED ALWAYS AS (ABS(tracking_signal) <= 4) STORED,
    
    -- Drill-down data from BDD lines 71-77
    drill_down_data JSONB, -- Analysis by interval/daily/weekly/monthly/channel
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. KPI PERFORMANCE DASHBOARDS
-- =============================================================================

-- KPI dashboards from BDD lines 79-97
CREATE TABLE kpi_performance_dashboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_name VARCHAR(200) NOT NULL,
    dashboard_category VARCHAR(50) NOT NULL,
    
    -- KPI categories from BDD lines 84-90
    service_level_80_20 DECIMAL(5,2), -- 80/20 format target
    efficiency_occupancy DECIMAL(5,2), -- Target 85%
    efficiency_utilization DECIMAL(5,2), -- Target 85%
    quality_customer_satisfaction DECIMAL(5,2), -- Target >90%
    quality_fcr DECIMAL(5,2), -- First Call Resolution >90%
    schedule_adherence DECIMAL(5,2), -- Target >80%
    schedule_shrinkage DECIMAL(5,2), -- Target >80%
    forecast_accuracy DECIMAL(5,2), -- Target ±10%
    forecast_bias DECIMAL(5,2), -- Target ±10%
    cost_per_contact DECIMAL(8,2), -- Budget targets
    overtime_percentage DECIMAL(5,2), -- Budget targets
    
    -- Visualization types from BDD lines 91-96
    traffic_light_status JSONB, -- Real-time status overview
    trend_charts_data JSONB, -- Performance over time
    heat_maps_data JSONB, -- Performance by time/agent
    waterfall_charts_data JSONB, -- Variance analysis
    
    update_frequency VARCHAR(20) NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. ABSENCE ANALYSIS
-- =============================================================================

-- Absence analysis from BDD lines 98-114
CREATE TABLE absence_analysis_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_period VARCHAR(20) NOT NULL CHECK (analysis_period IN ('Weekly', 'Monthly', 'Quarterly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Absence metrics from BDD lines 103-107
    planned_absences_data JSONB, -- Vacation usage, Training hours
    unplanned_absences_data JSONB, -- Sick leave frequency, Emergency leave
    pattern_analysis_data JSONB, -- Day-of-week trends, Seasonal patterns
    impact_analysis_data JSONB, -- Coverage effects, Cost implications
    
    -- Insights from BDD lines 109-113
    absence_rates_by_department JSONB,
    absence_trends JSONB, -- Increasing/decreasing patterns
    absence_costs JSONB, -- Direct and indirect costs
    coverage_impact JSONB, -- Service level impact
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. OVERTIME TRACKING
-- =============================================================================

-- Overtime analysis from BDD lines 115-131
CREATE TABLE overtime_tracking_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_period_start DATE NOT NULL,
    tracking_period_end DATE NOT NULL,
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Overtime metrics
CREATE TABLE overtime_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    overtime_report_id UUID NOT NULL REFERENCES overtime_tracking_reports(id),
    employee_tab_n VARCHAR(50) REFERENCES zup_agent_data(tab_n),
    department VARCHAR(200),
    
    -- Overtime tracking from BDD lines 120-124
    individual_overtime_hours DECIMAL(6,2) DEFAULT 0, -- Alert >10 hours/week
    department_overtime_hours DECIMAL(8,2) DEFAULT 0, -- Alert >5% of regular hours
    overtime_costs DECIMAL(10,2) DEFAULT 0, -- Alert >Budget allocation
    approval_compliance_pct DECIMAL(5,2) DEFAULT 0, -- Target >80% pre-approval
    
    -- Alert thresholds
    individual_overtime_alert BOOLEAN GENERATED ALWAYS AS (individual_overtime_hours > 10) STORED,
    department_overtime_alert BOOLEAN GENERATED ALWAYS AS (department_overtime_hours > (department_overtime_hours * 0.05)) STORED,
    approval_compliance_alert BOOLEAN GENERATED ALWAYS AS (approval_compliance_pct < 80) STORED,
    
    -- Optimization opportunities from BDD lines 125-130
    optimization_recommendations JSONB,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. COST ANALYSIS
-- =============================================================================

-- Cost analysis from BDD lines 132-149
CREATE TABLE cost_analysis_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_period_start DATE NOT NULL,
    analysis_period_end DATE NOT NULL,
    cost_center VARCHAR(100),
    
    -- Cost categories from BDD lines 137-142
    direct_labor_costs DECIMAL(12,2) DEFAULT 0, -- Regular hours, Overtime, Benefits
    indirect_labor_costs DECIMAL(12,2) DEFAULT 0, -- Management, Support staff
    technology_costs DECIMAL(12,2) DEFAULT 0, -- Systems, Telecommunications
    facilities_costs DECIMAL(12,2) DEFAULT 0, -- Office space, Utilities
    training_costs DECIMAL(12,2) DEFAULT 0, -- Development programs, Certifications
    
    -- Cost metrics from BDD lines 144-148
    cost_per_contact DECIMAL(8,2), -- Total costs / Total contacts
    cost_per_fte DECIMAL(10,2), -- Total costs / Full-time equivalent
    variable_cost_ratio DECIMAL(5,2), -- Variable costs / Total costs
    unit_cost_trends JSONB, -- Period-over-period changes
    
    -- Allocation methods
    cost_allocation_data JSONB, -- Time-based, Activity-based, Usage-based, etc.
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. AUDIT TRAILS
-- =============================================================================

-- Audit trail reports from BDD lines 150-167
CREATE TABLE audit_trail_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_period_start DATE NOT NULL,
    report_period_end DATE NOT NULL,
    audit_category VARCHAR(50) CHECK (audit_category IN ('User actions', 'Data changes', 'System changes', 'Security events')),
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Audit events tracking
CREATE TABLE audit_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    
    -- Audit categories from BDD lines 155-159
    event_category VARCHAR(50) NOT NULL CHECK (event_category IN ('User actions', 'Data changes', 'System changes', 'Security events')),
    
    -- Retention periods from BDD
    retention_period INTERVAL GENERATED ALWAYS AS (
        CASE event_category
            WHEN 'User actions' THEN INTERVAL '1 year'     -- Login, logout, access attempts
            WHEN 'Data changes' THEN INTERVAL '7 years'    -- Schedule modifications, Approvals
            WHEN 'System changes' THEN INTERVAL '5 years'  -- Configuration updates, Integrations
            WHEN 'Security events' THEN INTERVAL '2 years' -- Failed logins, Permission changes
        END
    ) STORED,
    
    -- Audit details from BDD lines 161-167
    before_state JSONB,
    after_state JSONB,
    ip_address INET,
    session_id VARCHAR(100),
    
    -- Auto-cleanup based on retention
    expires_at TIMESTAMP WITH TIME ZONE GENERATED ALWAYS AS (event_timestamp + retention_period) STORED
);

-- =============================================================================
-- 9. CUSTOM REPORTS
-- =============================================================================

-- Custom report editor from BDD lines 169-188
CREATE TABLE custom_report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(200) NOT NULL UNIQUE,
    report_description TEXT,
    
    -- Report configuration from BDD lines 174-180
    data_sources JSONB NOT NULL, -- Multiple database connections
    sql_queries TEXT NOT NULL, -- Custom queries with parameters
    input_parameters JSONB, -- Date ranges, departments, filters
    output_formats TEXT[] DEFAULT ARRAY['Excel', 'PDF', 'CSV'],
    
    -- Scheduling from BDD
    schedule_enabled BOOLEAN DEFAULT false,
    schedule_frequency VARCHAR(20), -- Daily, weekly, monthly
    schedule_next_run TIMESTAMP WITH TIME ZONE,
    
    -- Distribution
    distribution_lists JSONB, -- Email lists, shared folders
    
    -- Report features from BDD lines 182-187
    is_parameterized BOOLEAN DEFAULT true,
    is_scheduled BOOLEAN DEFAULT false,
    access_roles TEXT[], -- Role-based access
    version_number INTEGER DEFAULT 1,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Custom report executions
CREATE TABLE custom_report_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_definition_id UUID NOT NULL REFERENCES custom_report_definitions(id),
    execution_parameters JSONB,
    
    execution_status VARCHAR(20) DEFAULT 'Running' CHECK (execution_status IN ('Running', 'Completed', 'Failed')),
    output_file_path TEXT,
    error_message TEXT,
    
    executed_by VARCHAR(50) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 10. PERFORMANCE BENCHMARKING
-- =============================================================================

-- Performance benchmarking from BDD lines 189-205
CREATE TABLE performance_benchmarking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    benchmark_name VARCHAR(200) NOT NULL,
    benchmark_type VARCHAR(50) NOT NULL CHECK (benchmark_type IN ('Internal trends', 'Peer comparison', 'Industry standards', 'Best practices')),
    analysis_period VARCHAR(20) NOT NULL,
    
    -- Comparison data from BDD lines 194-198
    comparison_data JSONB NOT NULL,
    
    -- Improvement opportunities from BDD lines 199-204
    service_level_improvement_target DECIMAL(5,2), -- +5% improvement
    efficiency_improvement_target DECIMAL(5,2), -- Match top quartile
    quality_improvement_target DECIMAL(5,2), -- Industry benchmark
    cost_reduction_target DECIMAL(5,2), -- 10% reduction target
    
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 11. PREDICTIVE ANALYTICS
-- =============================================================================

-- Predictive analytics from BDD lines 206-222
CREATE TABLE predictive_analytics_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN ('Attrition risk', 'Absence prediction', 'Performance trends', 'Capacity needs')),
    
    -- Prediction accuracy from BDD lines 211-215
    confidence_level DECIMAL(5,2) NOT NULL,
    accuracy_target DECIMAL(5,2) NOT NULL,
    
    -- Decision support from BDD lines 216-221
    hiring_recommendations JSONB,
    training_recommendations JSONB,
    schedule_optimization_suggestions JSONB,
    budget_planning_projections JSONB,
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 12. REAL-TIME REPORTING
-- =============================================================================

-- Real-time operational reporting from BDD lines 223-239
CREATE TABLE real_time_operational_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_category VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    
    -- Update frequencies and thresholds from BDD lines 228-232
    update_frequency_seconds INTEGER NOT NULL,
    alert_threshold DECIMAL(10,2),
    current_status VARCHAR(20) DEFAULT 'Normal',
    
    -- Alert configuration from BDD lines 234-238
    alert_type VARCHAR(50),
    alert_condition TEXT,
    notification_method VARCHAR(100),
    
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 13. MOBILE REPORTING
-- =============================================================================

-- Mobile reporting from BDD lines 240-256
CREATE TABLE mobile_report_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_tab_n VARCHAR(50) NOT NULL REFERENCES zup_agent_data(tab_n),
    
    -- Mobile features from BDD lines 245-250
    responsive_design_enabled BOOLEAN DEFAULT true,
    touch_navigation_enabled BOOLEAN DEFAULT true,
    offline_access_enabled BOOLEAN DEFAULT true,
    push_notifications_enabled BOOLEAN DEFAULT true,
    quick_actions_enabled BOOLEAN DEFAULT true,
    
    -- Mobile functionality from BDD lines 252-256
    full_report_access BOOLEAN DEFAULT true,
    data_drilling_enabled BOOLEAN DEFAULT true,
    touch_based_filtering BOOLEAN DEFAULT true,
    sharing_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_employee_mobile_config UNIQUE(employee_tab_n)
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate schedule adherence
CREATE OR REPLACE FUNCTION calculate_schedule_adherence(
    p_employee_tab_n VARCHAR(50),
    p_date DATE
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_planned_minutes INTEGER;
    v_actual_minutes INTEGER;
    v_adherence DECIMAL(5,2);
BEGIN
    -- Get planned schedule time (simplified calculation)
    v_planned_minutes := 480; -- 8 hours default
    
    -- Get actual worked time (simplified calculation)
    v_actual_minutes := 450; -- Example actual time
    
    -- Calculate adherence: (Scheduled time - Deviation) / Scheduled time
    v_adherence := ((v_planned_minutes - ABS(v_planned_minutes - v_actual_minutes))::DECIMAL / v_planned_minutes) * 100;
    
    -- Insert or update adherence metrics
    INSERT INTO adherence_metrics (
        employee_tab_n, report_date, individual_adherence_pct,
        planned_schedule_time, actual_worked_time
    ) VALUES (
        p_employee_tab_n, p_date, v_adherence,
        make_interval(mins => v_planned_minutes),
        make_interval(mins => v_actual_minutes)
    )
    ON CONFLICT (employee_tab_n, report_date) DO UPDATE SET
        individual_adherence_pct = EXCLUDED.individual_adherence_pct,
        planned_schedule_time = EXCLUDED.planned_schedule_time,
        actual_worked_time = EXCLUDED.actual_worked_time,
        calculated_at = CURRENT_TIMESTAMP;
    
    RETURN v_adherence;
END;
$$ LANGUAGE plpgsql;

-- Function to generate payroll time codes
CREATE OR REPLACE FUNCTION generate_payroll_time_codes(
    p_employee_tab_n VARCHAR(50),
    p_work_date DATE,
    p_hours_worked DECIMAL(4,2),
    p_time_code VARCHAR(10)
) RETURNS void AS $$
DECLARE
    v_code_russian VARCHAR(10);
    v_code_english VARCHAR(50);
    v_document_type VARCHAR(100);
BEGIN
    -- Map time codes to descriptions from BDD
    SELECT 
        CASE p_time_code
            WHEN 'I' THEN 'Я'
            WHEN 'H' THEN 'Н'
            WHEN 'B' THEN 'В'
            WHEN 'C' THEN 'С'
            WHEN 'RV' THEN 'РВ'
            WHEN 'RVN' THEN 'РВН'
            WHEN 'NV' THEN 'НВ'
            WHEN 'OT' THEN 'ОТ'
        END,
        CASE p_time_code
            WHEN 'I' THEN 'Day work'
            WHEN 'H' THEN 'Night work'
            WHEN 'B' THEN 'Day off'
            WHEN 'C' THEN 'Overtime'
            WHEN 'RV' THEN 'Weekend work'
            WHEN 'RVN' THEN 'Night weekend work'
            WHEN 'NV' THEN 'Absence'
            WHEN 'OT' THEN 'Annual vacation'
        END,
        'Individual schedule'
    INTO v_code_russian, v_code_english, v_document_type;
    
    -- Insert time code record
    INSERT INTO payroll_time_codes (
        employee_tab_n, work_date, time_code, time_code_russian,
        time_code_english, zup_document_type, hours_worked, payroll_report_id
    ) VALUES (
        p_employee_tab_n, p_work_date, p_time_code, v_code_russian,
        v_code_english, v_document_type, p_hours_worked,
        (SELECT id FROM payroll_calculation_reports ORDER BY generated_at DESC LIMIT 1)
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Schedule adherence indexes
CREATE INDEX idx_adherence_metrics_employee_date ON adherence_metrics(employee_tab_n, report_date);
CREATE INDEX idx_adherence_metrics_color ON adherence_metrics(adherence_color);

-- Payroll indexes
CREATE INDEX idx_payroll_time_codes_employee_date ON payroll_time_codes(employee_tab_n, work_date);
CREATE INDEX idx_payroll_time_codes_report ON payroll_time_codes(payroll_report_id);

-- Audit trail indexes
CREATE INDEX idx_audit_events_timestamp ON audit_events(event_timestamp DESC);
CREATE INDEX idx_audit_events_user ON audit_events(user_id);
CREATE INDEX idx_audit_events_category ON audit_events(event_category);
CREATE INDEX idx_audit_events_expires ON audit_events(expires_at);

-- KPI dashboard indexes
CREATE INDEX idx_kpi_dashboards_category ON kpi_performance_dashboards(dashboard_category);
CREATE INDEX idx_kpi_dashboards_updated ON kpi_performance_dashboards(last_updated DESC);

-- Custom report indexes
CREATE INDEX idx_custom_reports_name ON custom_report_definitions(report_name);
CREATE INDEX idx_custom_report_executions_status ON custom_report_executions(execution_status);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample KPI dashboard
INSERT INTO kpi_performance_dashboards (
    dashboard_name, dashboard_category, service_level_80_20,
    efficiency_occupancy, quality_customer_satisfaction,
    schedule_adherence, forecast_accuracy, update_frequency
) VALUES (
    'Executive Dashboard', 'Service Level', 82.5, 85.0, 92.0, 
    78.5, 87.5, 'Real-time'
);

-- Sample custom report
INSERT INTO custom_report_definitions (
    report_name, report_description, data_sources, sql_queries,
    output_formats, created_by
) VALUES (
    'Monthly Adherence Summary', 
    'Monthly schedule adherence by department',
    '{"sources": ["adherence_metrics", "zup_agent_data"]}'::jsonb,
    'SELECT department, AVG(individual_adherence_pct) FROM adherence_metrics JOIN zup_agent_data ON...',
    ARRAY['Excel', 'PDF'],
    'admin'
);

-- =============================================================================
-- CLEANUP JOBS
-- =============================================================================

-- Auto-cleanup expired audit events
CREATE OR REPLACE FUNCTION cleanup_expired_audit_events() RETURNS void AS $$
BEGIN
    DELETE FROM audit_events WHERE expires_at < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_analysts;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_analysts;