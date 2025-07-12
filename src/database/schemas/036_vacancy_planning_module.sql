-- =============================================================================
-- 036_vacancy_planning_module.sql
-- EXACT BDD Implementation: Vacancy Planning Module - Comprehensive Staffing Gap Analysis
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 27-vacancy-planning-module.feature (428 lines)
-- Purpose: Complete staffing gap analysis and optimization for workforce expansion
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ACCESS CONTROL AND PERMISSIONS
-- =============================================================================

-- Vacancy planning role permissions from BDD lines 22-44
CREATE TABLE vacancy_planning_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50) NOT NULL,
    permission_type VARCHAR(50) NOT NULL CHECK (permission_type IN (
        'System_AccessVacancyPlanning', 'Planning Settings', 'Task Execution', 
        'Results Analysis', 'Report Generation', 'Exchange Integration'
    )),
    access_level VARCHAR(20) NOT NULL CHECK (access_level IN ('Full Access', 'Read Only', 'Denied')),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    granted_by VARCHAR(50) NOT NULL,
    
    CONSTRAINT unique_user_permission UNIQUE(user_id, permission_type)
);

-- Security audit trail for access attempts
CREATE TABLE vacancy_planning_access_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50) NOT NULL,
    attempted_action VARCHAR(100) NOT NULL,
    access_granted BOOLEAN NOT NULL,
    ip_address INET,
    session_id VARCHAR(100),
    access_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    denial_reason TEXT
);

-- =============================================================================
-- 2. CONFIGURATION AND SETTINGS
-- =============================================================================

-- Planning configuration from BDD lines 49-62
CREATE TABLE vacancy_planning_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_name VARCHAR(200) NOT NULL,
    
    -- Core planning parameters from BDD lines 54-59
    minimum_vacancy_efficiency DECIMAL(5,2) DEFAULT 85.0 CHECK (minimum_vacancy_efficiency BETWEEN 1 AND 100),
    analysis_period_days INTEGER DEFAULT 30 CHECK (analysis_period_days BETWEEN 1 AND 365),
    forecast_confidence_pct DECIMAL(5,2) DEFAULT 95.0 CHECK (forecast_confidence_pct BETWEEN 50 AND 99),
    work_rule_optimization BOOLEAN DEFAULT true,
    integration_with_exchange BOOLEAN DEFAULT true,
    
    -- Validation and business logic
    configuration_valid BOOLEAN DEFAULT true,
    validation_errors JSONB,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Work rule optimization parameters from BDD lines 63-75
CREATE TABLE work_rule_optimization_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_id UUID NOT NULL REFERENCES vacancy_planning_configuration(id) ON DELETE CASCADE,
    
    -- Optimization parameters from BDD lines 68-72
    shift_flexibility VARCHAR(20) NOT NULL CHECK (shift_flexibility IN ('Fixed', 'Flexible', 'Hybrid')),
    overtime_allowance_hours INTEGER DEFAULT 0 CHECK (overtime_allowance_hours BETWEEN 0 AND 20),
    cross_training_utilization_pct DECIMAL(5,2) DEFAULT 0 CHECK (cross_training_utilization_pct BETWEEN 0 AND 100),
    schedule_rotation_frequency VARCHAR(20) NOT NULL CHECK (schedule_rotation_frequency IN ('Daily', 'Weekly', 'Monthly')),
    
    -- Impact analysis
    substitution_possibilities JSONB,
    staffing_needs_reduction JSONB,
    multi_skill_coverage JSONB,
    planning_accuracy_impact JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. VACANCY PLANNING ANALYSIS ENGINE
-- =============================================================================

-- Analysis tasks from BDD lines 80-96
CREATE TABLE vacancy_planning_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_name VARCHAR(200) NOT NULL,
    configuration_id UUID NOT NULL REFERENCES vacancy_planning_configuration(id),
    
    -- Task execution tracking
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Running', 'Completed', 'Failed', 'Cancelled')),
    progress_percentage DECIMAL(5,2) DEFAULT 0.0 CHECK (progress_percentage BETWEEN 0 AND 100),
    current_step VARCHAR(100),
    estimated_completion TIMESTAMP WITH TIME ZONE,
    
    -- Data sources and periods
    staffing_data_source VARCHAR(100),
    forecast_period_start DATE NOT NULL,
    forecast_period_end DATE NOT NULL,
    
    -- Results storage
    analysis_results JSONB,
    calculation_steps JSONB,
    
    started_by VARCHAR(50) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_date_range CHECK (forecast_period_end > forecast_period_start)
);

-- Detailed deficit analysis from BDD lines 97-109
CREATE TABLE staffing_deficit_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id) ON DELETE CASCADE,
    
    -- Analysis categories from BDD lines 102-106
    analysis_category VARCHAR(50) NOT NULL CHECK (analysis_category IN (
        'Position Deficit', 'Skill Gap Analysis', 'Shift Coverage Gaps', 'Seasonal Variations'
    )),
    
    -- Metrics and calculations
    metric_value DECIMAL(10,2) NOT NULL,
    calculation_method TEXT NOT NULL,
    business_impact TEXT NOT NULL,
    
    -- Position deficit specifics
    position_title VARCHAR(200),
    required_fte DECIMAL(6,2),
    current_fte DECIMAL(6,2),
    deficit_fte DECIMAL(6,2),
    
    -- Skill gap analysis
    skill_coverage_pct DECIMAL(5,2),
    available_skills JSONB,
    required_skills JSONB,
    training_requirements JSONB,
    
    -- Shift coverage gaps
    uncovered_time_periods JSONB,
    forecast_load DECIMAL(10,2),
    available_capacity DECIMAL(10,2),
    service_level_risk TEXT,
    
    -- Seasonal variations
    fluctuation_patterns JSONB,
    historical_trends JSONB,
    temporary_staffing_needs JSONB,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Efficiency optimization calculations from BDD lines 111-124
CREATE TABLE efficiency_optimization_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id) ON DELETE CASCADE,
    position_title VARCHAR(200) NOT NULL,
    
    -- Efficiency factors from BDD lines 116-120
    position_utilization_pct DECIMAL(5,2) NOT NULL, -- Forecast hours / Available hours
    skill_overlap_opportunities JSONB, -- Cross-training possibilities
    schedule_flexibility_rating DECIMAL(3,2), -- Shift rotation options
    growth_trajectory_score DECIMAL(5,2), -- Trend analysis
    
    -- Decision impact
    cost_benefit_ratio DECIMAL(8,2),
    efficiency_rating DECIMAL(5,2),
    meets_minimum_threshold BOOLEAN,
    
    -- Recommendations
    alternative_solutions JSONB,
    cost_benefit_analysis JSONB,
    long_term_viability TEXT,
    
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. TASK EXECUTION AND MONITORING
-- =============================================================================

-- Real-time progress tracking from BDD lines 129-142
CREATE TABLE task_execution_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id) ON DELETE CASCADE,
    
    -- Progress indicators from BDD lines 134-138
    overall_progress_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
    estimated_time_remaining INTERVAL,
    current_step_name VARCHAR(200),
    current_step_details TEXT,
    records_processed INTEGER DEFAULT 0,
    total_records INTEGER,
    processing_speed DECIMAL(8,2), -- Records per second
    
    -- Error and status tracking
    error_count INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0,
    last_error_message TEXT,
    
    -- User interaction capabilities
    can_cancel BOOLEAN DEFAULT true,
    can_view_details BOOLEAN DEFAULT true,
    
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Multi-task management from BDD lines 143-156
CREATE TABLE task_queue_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id),
    
    -- Queue management from BDD lines 148-152
    queue_position INTEGER NOT NULL,
    priority_level VARCHAR(10) NOT NULL CHECK (priority_level IN ('High', 'Medium', 'Low')),
    
    -- Resource allocation
    cpu_allocation_pct DECIMAL(5,2),
    memory_allocation_mb INTEGER,
    
    -- Scheduling
    scheduled_start_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    queue_status VARCHAR(20) DEFAULT 'Queued' CHECK (queue_status IN ('Queued', 'Running', 'Completed', 'Archived')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT max_concurrent_tasks CHECK (
        (SELECT COUNT(*) FROM task_queue_management WHERE queue_status = 'Running') <= 5
    )
);

-- =============================================================================
-- 5. RESULTS ANALYSIS AND VISUALIZATION
-- =============================================================================

-- Comprehensive visualization data from BDD lines 161-174
CREATE TABLE vacancy_results_visualization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id) ON DELETE CASCADE,
    
    -- Visualization types from BDD lines 166-170
    visualization_type VARCHAR(50) NOT NULL CHECK (visualization_type IN (
        'Staffing Gap Chart', 'Service Level Impact', 'Hiring Timeline', 'Cost Analysis'
    )),
    
    -- Data presentation
    chart_data JSONB NOT NULL,
    interactive_features JSONB,
    export_formats TEXT[] DEFAULT ARRAY['PDF', 'Excel', 'PNG'],
    
    -- Filtering capabilities
    filter_options JSONB, -- Department, skill, period filters
    drill_down_data JSONB,
    
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Hiring recommendations from BDD lines 175-193
CREATE TABLE hiring_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id) ON DELETE CASCADE,
    
    -- Recommendation categories from BDD lines 180-184
    recommendation_category VARCHAR(50) NOT NULL CHECK (recommendation_category IN (
        'Immediate Hiring Needs', 'Planned Positions', 'Contingency Staffing', 'Skill Development'
    )),
    priority_level VARCHAR(10) NOT NULL CHECK (priority_level IN ('Critical', 'High', 'Medium', 'Low')),
    implementation_timeline VARCHAR(20) NOT NULL,
    
    -- Position details from BDD lines 186-191
    position_title VARCHAR(200) NOT NULL,
    position_quantity INTEGER NOT NULL,
    skill_requirements JSONB NOT NULL,
    work_schedule_requirements JSONB,
    salary_range_min DECIMAL(10,2),
    salary_range_max DECIMAL(10,2),
    recommended_start_date DATE,
    
    -- Business justification
    business_impact_score DECIMAL(5,2),
    business_justification TEXT NOT NULL,
    urgency_ranking INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. INTEGRATION WITH EXCHANGE SYSTEM
-- =============================================================================

-- Exchange system integration from BDD lines 198-212
CREATE TABLE exchange_system_integration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id),
    
    -- Data transfer tracking from BDD lines 204-208
    transfer_type VARCHAR(50) NOT NULL CHECK (transfer_type IN (
        'Staffing Gaps', 'Skill Requirements', 'Schedule Needs', 'Priority Levels'
    )),
    
    -- Exchange system data
    exchange_data JSONB NOT NULL,
    validation_status VARCHAR(20) DEFAULT 'Pending' CHECK (validation_status IN ('Pending', 'Valid', 'Invalid', 'Error')),
    validation_errors JSONB,
    
    -- Transfer tracking
    transfer_initiated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transfer_completed_at TIMESTAMP WITH TIME ZONE,
    exchange_confirmation_received BOOLEAN DEFAULT false,
    
    -- Audit logging
    transfer_logged BOOLEAN DEFAULT true,
    retry_count INTEGER DEFAULT 0,
    last_error_message TEXT
);

-- Personnel synchronization from BDD lines 213-226
CREATE TABLE personnel_sync_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Personnel data categories from BDD lines 218-222
    data_category VARCHAR(50) NOT NULL CHECK (data_category IN (
        'Employee Count', 'Skill Assignments', 'Position Changes', 'Availability Status'
    )),
    source_system VARCHAR(100) NOT NULL,
    update_frequency VARCHAR(20) NOT NULL,
    
    -- Synchronization status
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'Pending' CHECK (sync_status IN ('Pending', 'In Progress', 'Completed', 'Failed')),
    records_synchronized INTEGER DEFAULT 0,
    data_conflicts_detected INTEGER DEFAULT 0,
    
    -- Impact on analysis
    analysis_impact TEXT,
    
    -- Error handling
    sync_errors JSONB,
    administrator_alerted BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. REPORTING AND ANALYTICS
-- =============================================================================

-- Comprehensive reporting from BDD lines 231-249
CREATE TABLE vacancy_planning_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id),
    
    -- Report types from BDD lines 236-240
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'Executive Summary', 'Detailed Analysis', 'Hiring Justification', 'Implementation Plan'
    )),
    target_audience VARCHAR(50) NOT NULL,
    format_options TEXT[] DEFAULT ARRAY['PDF'],
    
    -- Report content sections from BDD lines 242-247
    current_state_data JSONB, -- Existing staffing levels
    gap_analysis_data JSONB, -- Specific deficits/surpluses
    recommendations_data JSONB, -- Actionable hiring plan
    financial_impact_data JSONB, -- Cost-benefit analysis
    implementation_timeline_data JSONB, -- Phased hiring schedule
    
    -- Report metadata
    report_version INTEGER DEFAULT 1,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(50) NOT NULL,
    file_path TEXT,
    file_size_bytes INTEGER
);

-- Trend analysis from BDD lines 250-263
CREATE TABLE vacancy_trend_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Trend analysis categories from BDD lines 255-259
    trend_category VARCHAR(50) NOT NULL CHECK (trend_category IN (
        'Staffing Levels', 'Gap Frequency', 'Hiring Effectiveness', 'Cost Trends'
    )),
    analysis_period VARCHAR(20) NOT NULL,
    
    -- Metrics and insights
    historical_data JSONB NOT NULL,
    trend_patterns JSONB,
    insights_generated JSONB,
    predictive_model_data JSONB,
    
    -- Business value
    seasonal_patterns_identified BOOLEAN DEFAULT false,
    chronic_understaffing_areas JSONB,
    recruitment_success_metrics JSONB,
    budget_optimization_opportunities JSONB,
    
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. ADVANCED FEATURES AND SCENARIO MODELING
-- =============================================================================

-- What-if scenario analysis from BDD lines 268-281
CREATE TABLE scenario_modeling (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    base_task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id),
    scenario_name VARCHAR(200) NOT NULL,
    
    -- Scenario types from BDD lines 273-277
    scenario_type VARCHAR(50) NOT NULL CHECK (scenario_type IN (
        'Budget Constraints', 'Service Level Changes', 'Forecast Variations', 'Skill Development'
    )),
    
    -- Variable parameters
    variable_parameters JSONB NOT NULL,
    modified_hiring_plan JSONB,
    analysis_output JSONB,
    decision_support_data JSONB,
    
    -- Scenario comparison
    comparison_with_base JSONB,
    best_case_scenario BOOLEAN DEFAULT false,
    worst_case_scenario BOOLEAN DEFAULT false,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    saved_for_future_reference BOOLEAN DEFAULT true
);

-- Multi-site analysis from BDD lines 282-295
CREATE TABLE multi_site_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_name VARCHAR(200) NOT NULL,
    
    -- Multi-site features from BDD lines 287-291
    analysis_type VARCHAR(50) NOT NULL CHECK (analysis_type IN (
        'Consolidated Analysis', 'Resource Sharing', 'Site Prioritization', 'Comparative Analysis'
    )),
    
    -- Site coordination
    included_sites JSONB NOT NULL,
    consolidated_view_data JSONB,
    cross_site_opportunities JSONB,
    
    -- Resource optimization
    resource_sharing_analysis JSONB,
    skill_transfer_opportunities JSONB,
    budget_allocation_recommendations JSONB,
    
    -- Comparative metrics
    site_performance_comparison JSONB,
    best_practices_identified JSONB,
    standardized_metrics JSONB,
    
    analyzed_by VARCHAR(50) NOT NULL,
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. ERROR HANDLING AND VALIDATION
-- =============================================================================

-- Data validation errors from BDD lines 300-313
CREATE TABLE validation_error_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES vacancy_planning_tasks(id),
    
    -- Error types from BDD lines 305-309
    error_type VARCHAR(50) NOT NULL CHECK (error_type IN (
        'Missing Forecast Data', 'Incomplete Personnel Data', 'Invalid Configuration', 'Insufficient Permissions'
    )),
    validation_check VARCHAR(200) NOT NULL,
    error_message TEXT NOT NULL,
    recovery_action TEXT NOT NULL,
    
    -- Error handling
    user_friendly_message TEXT,
    recovery_suggestions JSONB,
    error_resolved BOOLEAN DEFAULT false,
    
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Calculation failure handling from BDD lines 314-327
CREATE TABLE calculation_failure_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES vacancy_planning_tasks(id),
    
    -- Failure types from BDD lines 319-323
    failure_type VARCHAR(50) NOT NULL CHECK (failure_type IN (
        'Memory Overflow', 'Data Corruption', 'Timeout Errors', 'Network Failures'
    )),
    detection_method VARCHAR(100) NOT NULL,
    response_action TEXT NOT NULL,
    user_notification TEXT,
    
    -- Recovery tracking
    automatic_recovery_attempted BOOLEAN DEFAULT false,
    recovery_successful BOOLEAN DEFAULT false,
    manual_intervention_required BOOLEAN DEFAULT false,
    
    -- Detailed logging
    error_details JSONB NOT NULL,
    system_state_at_failure JSONB,
    
    failed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- 10. COMPLIANCE AND BUSINESS RULES
-- =============================================================================

-- Labor regulation compliance from BDD lines 364-377
CREATE TABLE labor_compliance_validation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES hiring_recommendations(id),
    
    -- Compliance areas from BDD lines 369-373
    compliance_area VARCHAR(50) NOT NULL CHECK (compliance_area IN (
        'Maximum Work Hours', 'Overtime Limitations', 'Rest Period Requirements', 'Vacation Entitlements'
    )),
    regulation_reference TEXT NOT NULL,
    
    -- Validation results
    compliance_status VARCHAR(20) NOT NULL CHECK (compliance_status IN ('Compliant', 'Violation', 'Warning')),
    validation_method TEXT,
    violation_details TEXT,
    alternative_solutions JSONB,
    
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Budget management controls from BDD lines 378-391
CREATE TABLE budget_compliance_validation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES hiring_recommendations(id),
    
    -- Budget controls from BDD lines 383-387
    budget_control_type VARCHAR(50) NOT NULL CHECK (budget_control_type IN (
        'Hiring Budget Limit', 'Department Budget', 'Position-specific Costs', 'Training Budget'
    )),
    constraint_type VARCHAR(100) NOT NULL,
    budget_limit DECIMAL(12,2),
    estimated_cost DECIMAL(12,2),
    
    -- Compliance validation
    within_budget BOOLEAN NOT NULL,
    variance_amount DECIMAL(12,2),
    override_required BOOLEAN DEFAULT false,
    override_approval_process TEXT,
    
    -- Cost projections
    associated_expenses JSONB, -- All hiring expenses
    cost_breakdown JSONB,
    
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate staffing deficit
CREATE OR REPLACE FUNCTION calculate_staffing_deficit(
    p_task_id UUID,
    p_required_fte DECIMAL,
    p_current_fte DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    v_deficit DECIMAL;
BEGIN
    v_deficit := p_required_fte - p_current_fte;
    
    -- Insert deficit analysis record
    INSERT INTO staffing_deficit_analysis (
        task_id, analysis_category, metric_value, calculation_method,
        business_impact, required_fte, current_fte, deficit_fte
    ) VALUES (
        p_task_id, 'Position Deficit', v_deficit, 'Required FTE - Current FTE',
        'Direct hiring needs', p_required_fte, p_current_fte, v_deficit
    );
    
    RETURN v_deficit;
END;
$$ LANGUAGE plpgsql;

-- Function to check access permissions
CREATE OR REPLACE FUNCTION check_vacancy_planning_access(
    p_user_id VARCHAR(50),
    p_permission_type VARCHAR(50)
) RETURNS BOOLEAN AS $$
DECLARE
    v_access_level VARCHAR(20);
BEGIN
    SELECT access_level INTO v_access_level
    FROM vacancy_planning_permissions
    WHERE user_id = p_user_id AND permission_type = p_permission_type;
    
    -- Log access attempt
    INSERT INTO vacancy_planning_access_log (
        user_id, attempted_action, access_granted
    ) VALUES (
        p_user_id, p_permission_type, (v_access_level = 'Full Access')
    );
    
    RETURN (v_access_level = 'Full Access');
END;
$$ LANGUAGE plpgsql;

-- Function to update task progress
CREATE OR REPLACE FUNCTION update_task_progress(
    p_task_id UUID,
    p_progress_pct DECIMAL,
    p_current_step VARCHAR(100)
) RETURNS void AS $$
BEGIN
    -- Update main task progress
    UPDATE vacancy_planning_tasks
    SET progress_percentage = p_progress_pct,
        current_step = p_current_step,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_task_id;
    
    -- Update monitoring record
    INSERT INTO task_execution_monitoring (
        task_id, overall_progress_pct, current_step_name
    ) VALUES (
        p_task_id, p_progress_pct, p_current_step
    )
    ON CONFLICT (task_id) DO UPDATE SET
        overall_progress_pct = EXCLUDED.overall_progress_pct,
        current_step_name = EXCLUDED.current_step_name,
        last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Task and monitoring indexes
CREATE INDEX idx_vacancy_tasks_status ON vacancy_planning_tasks(status);
CREATE INDEX idx_vacancy_tasks_started_by ON vacancy_planning_tasks(started_by);
CREATE INDEX idx_task_monitoring_task_id ON task_execution_monitoring(task_id);

-- Analysis indexes
CREATE INDEX idx_deficit_analysis_task ON staffing_deficit_analysis(task_id);
CREATE INDEX idx_deficit_analysis_category ON staffing_deficit_analysis(analysis_category);
CREATE INDEX idx_efficiency_analysis_task ON efficiency_optimization_analysis(task_id);

-- Recommendations indexes
CREATE INDEX idx_hiring_recommendations_task ON hiring_recommendations(task_id);
CREATE INDEX idx_hiring_recommendations_priority ON hiring_recommendations(priority_level);
CREATE INDEX idx_hiring_recommendations_category ON hiring_recommendations(recommendation_category);

-- Integration indexes
CREATE INDEX idx_exchange_integration_task ON exchange_system_integration(task_id);
CREATE INDEX idx_personnel_sync_category ON personnel_sync_tracking(data_category);

-- Access control indexes
CREATE INDEX idx_vacancy_permissions_user ON vacancy_planning_permissions(user_id);
CREATE INDEX idx_access_log_user_timestamp ON vacancy_planning_access_log(user_id, access_timestamp);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample configuration
INSERT INTO vacancy_planning_configuration (
    configuration_name, minimum_vacancy_efficiency, analysis_period_days,
    forecast_confidence_pct, created_by
) VALUES (
    'Standard Vacancy Planning Config', 85.0, 30, 95.0, 'admin'
);

-- Sample permissions
INSERT INTO vacancy_planning_permissions (user_id, permission_type, access_level, granted_by) VALUES
('admin', 'System_AccessVacancyPlanning', 'Full Access', 'system'),
('manager01', 'System_AccessVacancyPlanning', 'Full Access', 'admin'),
('analyst01', 'Results Analysis', 'Full Access', 'admin');

-- Sample work rule optimization
INSERT INTO work_rule_optimization_config (
    configuration_id, shift_flexibility, overtime_allowance_hours,
    cross_training_utilization_pct, schedule_rotation_frequency
) SELECT 
    id, 'Flexible', 10, 75.0, 'Weekly'
FROM vacancy_planning_configuration 
WHERE configuration_name = 'Standard Vacancy Planning Config';

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to auto-update task monitoring
CREATE OR REPLACE FUNCTION update_task_monitoring_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert or update monitoring record when task progress changes
    INSERT INTO task_execution_monitoring (
        task_id, overall_progress_pct, current_step_name
    ) VALUES (
        NEW.id, NEW.progress_percentage, NEW.current_step
    )
    ON CONFLICT (task_id) DO UPDATE SET
        overall_progress_pct = EXCLUDED.overall_progress_pct,
        current_step_name = EXCLUDED.current_step_name,
        last_updated = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_monitoring
    AFTER INSERT OR UPDATE ON vacancy_planning_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_monitoring_trigger();

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_planners;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_planners;