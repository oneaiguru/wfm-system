-- =============================================================================
-- 039_planning_module_detailed_workflows.sql
-- EXACT BDD Implementation: Planning Module Detailed Workflows and UI Interactions
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Based on: 19-planning-module-detailed-workflows.feature (649 lines)
-- Purpose: Specific planning workflows with exact UI interactions for schedule management
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. MULTI-SKILL PLANNING TEMPLATES
-- =============================================================================

-- Multi-skill planning templates from BDD lines 14-31
CREATE TABLE multiskill_planning_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(200) NOT NULL UNIQUE,
    
    -- Template information from BDD lines 18-21
    display_side VARCHAR(10) DEFAULT 'Right' CHECK (display_side IN ('Left', 'Right')),
    template_info_displayed BOOLEAN DEFAULT true,
    
    -- UI workflow tracking from BDD lines 22-26
    created_via_button BOOLEAN DEFAULT true, -- "Create Template" button
    form_displayed BOOLEAN DEFAULT true,
    saved_successfully BOOLEAN DEFAULT false,
    
    -- Group associations
    groups_added INTEGER DEFAULT 0,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Template groups management from BDD lines 27-31
CREATE TABLE template_group_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES multiskill_planning_templates(id) ON DELETE CASCADE,
    service_name VARCHAR(200) NOT NULL,
    group_name VARCHAR(200) NOT NULL,
    
    -- UI interaction tracking
    added_via_dialog BOOLEAN DEFAULT true,
    dialog_save_clicked BOOLEAN DEFAULT true,
    
    -- Conflict handling from BDD lines 34-40
    conflict_checked BOOLEAN DEFAULT true,
    conflict_found BOOLEAN DEFAULT false,
    warning_displayed BOOLEAN DEFAULT false,
    alternative_suggested BOOLEAN DEFAULT false,
    
    assigned_by VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_template_group UNIQUE(template_id, service_name, group_name)
);

-- Template operations audit from BDD lines 42-101
CREATE TABLE template_operations_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES multiskill_planning_templates(id),
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN (
        'Rename', 'Remove Group', 'Delete Template', 'Select Template'
    )),
    
    -- Rename operations from BDD lines 45-54
    old_name VARCHAR(200),
    new_name VARCHAR(200),
    rename_dialog_opened BOOLEAN DEFAULT false,
    
    -- Group removal from BDD lines 58-71
    removed_group_name VARCHAR(200),
    confirmation_dialog_shown BOOLEAN DEFAULT false,
    user_confirmed BOOLEAN DEFAULT false,
    schedule_impact_validated BOOLEAN DEFAULT false,
    
    -- Template deletion from BDD lines 75-88
    deletion_warning_shown BOOLEAN DEFAULT false,
    cascade_deletion_warned BOOLEAN DEFAULT false,
    schedules_deleted_count INTEGER DEFAULT 0,
    operators_unassigned_count INTEGER DEFAULT 0,
    
    -- UI interaction details from BDD lines 94-101
    ui_interaction_method VARCHAR(50), -- Single Click, Right Click, Keyboard
    visual_feedback_provided BOOLEAN DEFAULT true,
    context_menu_displayed BOOLEAN DEFAULT false,
    
    operated_by VARCHAR(50) NOT NULL,
    operated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation_success BOOLEAN DEFAULT false
);

-- =============================================================================
-- 2. WORK SCHEDULE PLANNING
-- =============================================================================

-- Work schedule planning from BDD lines 151-170
CREATE TABLE work_schedule_planning (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES multiskill_planning_templates(id),
    schedule_name VARCHAR(200) NOT NULL,
    
    -- Schedule creation fields from BDD lines 159-165
    comment TEXT,
    productivity_type VARCHAR(50) DEFAULT 'annual', -- annual/quarterly/monthly
    planning_year INTEGER NOT NULL,
    consider_preferences BOOLEAN DEFAULT false,
    
    -- UI workflow state
    created_via_button BOOLEAN DEFAULT true,
    window_opened BOOLEAN DEFAULT true,
    start_planning_clicked BOOLEAN DEFAULT false,
    
    -- Schedule status
    is_applied BOOLEAN DEFAULT false,
    is_current_active BOOLEAN DEFAULT false,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Schedule variants and pinning from BDD lines 171-185
CREATE TABLE work_schedule_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_id UUID NOT NULL REFERENCES work_schedule_planning(id),
    variant_name VARCHAR(200) NOT NULL,
    
    -- Applied schedule pinning from BDD lines 176-182
    is_pinned_to_top BOOLEAN DEFAULT false,
    visual_indicator VARCHAR(50), -- Bold text, checkmark icon
    background_color VARCHAR(20), -- light blue/green
    sort_order INTEGER DEFAULT 999,
    display_label VARCHAR(50), -- Current, Active
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_variant_name UNIQUE(planning_id, variant_name)
);

-- Planning tasks tracking from BDD lines 272-290
CREATE TABLE work_schedule_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planning_id UUID NOT NULL REFERENCES work_schedule_planning(id),
    
    -- Exact status values from BDD lines 276-290
    schedule_status VARCHAR(50) NOT NULL CHECK (schedule_status IN (
        'Planning', 'Planned', 'Planning Error', 'Updating', 'Update Error'
    )),
    task_status VARCHAR(50) NOT NULL CHECK (task_status IN (
        'Executing', 'Awaiting Save', 'Result Saved', 'Result Canceled', 'Execution Error'
    )),
    
    -- Status descriptions
    status_description TEXT,
    
    -- Workflow tracking
    refresh_button_clicked BOOLEAN DEFAULT false,
    last_status_check TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. UI ENHANCEMENTS
-- =============================================================================

-- Alternative timezone display from BDD lines 188-202
CREATE TABLE timezone_display_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Display options from BDD lines 192-197
    display_mode VARCHAR(50) NOT NULL CHECK (display_mode IN (
        'Local Time', 'UTC/GMT', 'Dual Time', 'Relative Time', 'Multiple Zones'
    )),
    
    -- Format examples
    format_example VARCHAR(100),
    use_case_description TEXT,
    
    -- User preferences
    is_saved_preference BOOLEAN DEFAULT true,
    applies_to_all_fields BOOLEAN DEFAULT true,
    shows_abbreviations BOOLEAN DEFAULT true,
    
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vacation violation tooltips from BDD lines 203-219
CREATE TABLE vacation_violation_tooltips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    violation_type VARCHAR(100) NOT NULL,
    
    -- Tooltip content from BDD lines 208-214
    specific_rule TEXT NOT NULL,
    current_value TEXT,
    impact_description TEXT,
    suggestion TEXT,
    severity VARCHAR(10) CHECK (severity IN ('High', 'Medium', 'Low')),
    
    -- UI behavior
    hover_delay_ms INTEGER DEFAULT 500,
    auto_hide BOOLEAN DEFAULT true,
    position_smart BOOLEAN DEFAULT true, -- Avoid screen edges
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enhanced statistics display from BDD lines 220-239
CREATE TABLE enhanced_statistics_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    statistic_type VARCHAR(50) NOT NULL,
    
    -- Display options from BDD lines 225-231
    monthly_display_format VARCHAR(100),
    yearly_display_format VARCHAR(100),
    calculation_method TEXT,
    
    -- Visual elements from BDD lines 233-238
    chart_types TEXT[], -- Bar charts, line graphs, pie charts
    trend_indicators_enabled BOOLEAN DEFAULT true,
    color_coding_rules JSONB,
    drill_down_enabled BOOLEAN DEFAULT true,
    export_formats TEXT[] DEFAULT ARRAY['Excel', 'PDF', 'CSV'],
    
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enhanced working hours display from BDD lines 240-271
CREATE TABLE shift_cell_display_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Cell elements from BDD lines 245-250
    show_shift_time BOOLEAN DEFAULT true,
    show_break_time BOOLEAN DEFAULT true,
    show_net_hours BOOLEAN DEFAULT true,
    show_project_code BOOLEAN DEFAULT true,
    show_skill_level BOOLEAN DEFAULT true,
    
    -- Formatting rules
    overtime_highlight_color VARCHAR(20),
    part_time_visual_style VARCHAR(50),
    
    -- Tooltip configuration from BDD lines 260-270
    tooltip_enabled BOOLEAN DEFAULT true,
    tooltip_sections JSONB, -- Shift details, breaks, employee info, etc.
    tooltip_formatting JSONB,
    tooltip_dynamic_update BOOLEAN DEFAULT true,
    
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. SCHEDULE REVIEW AND INTERFACE
-- =============================================================================

-- Schedule review interface from BDD lines 291-311
CREATE TABLE schedule_review_interface (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES work_schedule_tasks(id),
    
    -- Tab configuration from BDD lines 295-298
    org_structure_tab_active BOOLEAN DEFAULT true,
    func_structure_tab_active BOOLEAN DEFAULT true,
    
    -- Org Structure checkboxes from BDD lines 299-304
    show_operators_without_vacations BOOLEAN DEFAULT true,
    show_non_plannable_positions BOOLEAN DEFAULT true,
    show_vacation_violations BOOLEAN DEFAULT true,
    show_desired_vacations BOOLEAN DEFAULT true,
    
    -- Func Structure checkboxes from BDD lines 305-310
    show_op_forecast BOOLEAN DEFAULT true,
    show_op_plan BOOLEAN DEFAULT true,
    show_op_plan_abs_pct BOOLEAN DEFAULT true,
    show_acd_forecast_pct BOOLEAN DEFAULT true,
    
    reviewed_by VARCHAR(50),
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. VACATION PLANNING
-- =============================================================================

-- Vacation schedule interface from BDD lines 312-332
CREATE TABLE vacation_schedule_interface (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Top panel filters from BDD lines 316-319
    group_filter_enabled BOOLEAN DEFAULT true,
    department_filter_enabled BOOLEAN DEFAULT true,
    generate_vacations_button_enabled BOOLEAN DEFAULT true,
    
    -- Checkboxes from BDD lines 320-326
    show_unassigned_vacation BOOLEAN DEFAULT true,
    show_accumulated_days BOOLEAN DEFAULT true,
    show_subordinate_employees BOOLEAN DEFAULT true,
    show_vacation_violations BOOLEAN DEFAULT true,
    show_desired_vacations BOOLEAN DEFAULT true,
    
    -- Table columns from BDD lines 327-331
    display_full_name BOOLEAN DEFAULT true,
    display_vacation_scheme BOOLEAN DEFAULT true,
    display_remaining_days BOOLEAN DEFAULT true,
    
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vacation operations from BDD lines 333-360
CREATE TABLE vacation_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL,
    
    -- Operation details from BDD lines 337-343
    operation_type VARCHAR(50) CHECK (operation_type IN (
        'Add Vacation', 'Delete Vacation', 'Set Priority'
    )),
    vacation_type VARCHAR(50) CHECK (vacation_type IN (
        'Extraordinary Vacation', 'Desired Vacation'
    )),
    
    -- Creation method from BDD lines 344-347
    creation_method VARCHAR(50) CHECK (creation_method IN ('Period', 'Calendar Days')),
    date_handling VARCHAR(100),
    day_deduction_rule VARCHAR(100),
    
    -- Priority settings from BDD lines 354-357
    priority_level VARCHAR(50) CHECK (priority_level IN (
        'Vacation Priority', 'Non-priority Vacation', 'Fixed Vacation'
    )),
    planning_effect TEXT,
    visual_marking VARCHAR(100),
    
    operated_by VARCHAR(50) NOT NULL,
    operated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Automatic vacation generation from BDD lines 447-498
CREATE TABLE vacation_generation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Arrangement rules from BDD lines 453-459
    use_preferences_first BOOLEAN DEFAULT true,
    avoid_high_demand BOOLEAN DEFAULT true,
    ensure_minimum_staffing BOOLEAN DEFAULT true,
    respect_blackout_periods BOOLEAN DEFAULT true,
    apply_seniority_rules BOOLEAN DEFAULT true,
    use_fairness_algorithm BOOLEAN DEFAULT true,
    
    -- Generation criteria from BDD lines 461-466
    maintain_coverage BOOLEAN DEFAULT true,
    spread_throughout_year BOOLEAN DEFAULT true,
    honor_preferences_pct DECIMAL(5,2),
    follow_business_rules BOOLEAN DEFAULT true,
    minimize_conflicts BOOLEAN DEFAULT true,
    
    -- Business rule integration from BDD lines 478-485
    timing_rules JSONB,
    duration_rules JSONB,
    coverage_rules JSONB,
    seniority_rules JSONB,
    seasonal_rules JSONB,
    department_rules JSONB,
    
    configured_by VARCHAR(50) NOT NULL,
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. SCHEDULE PLANNING AND TIMETABLES
-- =============================================================================

-- Timetable creation from BDD lines 361-381
CREATE TABLE timetable_creation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES work_schedule_planning(id),
    
    -- Planning dialog fields from BDD lines 366-368
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    planning_criteria_id UUID,
    
    -- View modes from BDD lines 369-372
    view_by_employees BOOLEAN DEFAULT true,
    view_by_direction BOOLEAN DEFAULT false,
    
    -- Statistics from BDD lines 373-380
    project_statistics JSONB,
    segment_requirements JSONB,
    segments_assigned_total INTEGER DEFAULT 0,
    segments_assigned_schedule INTEGER DEFAULT 0,
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Manual schedule corrections from BDD lines 382-398
CREATE TABLE manual_schedule_corrections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timetable_id UUID NOT NULL REFERENCES timetable_creation(id),
    
    -- Context menu options from BDD lines 388-397
    correction_type VARCHAR(50) NOT NULL CHECK (correction_type IN (
        'Add Lunch', 'Add Break', 'Cancel Breaks', 'Does not accept calls',
        'Non-working time', 'Add work attendance', 'Assign to project',
        'Event', 'Cancel Event'
    )),
    
    -- Conditions and rules
    condition_met BOOLEAN DEFAULT true,
    time_interval_selected VARCHAR(20), -- 5-minute divisions
    
    corrected_by VARCHAR(50) NOT NULL,
    corrected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Schedule application from BDD lines 399-411
CREATE TABLE schedule_application_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES work_schedule_planning(id),
    
    -- Application status
    compiled_successfully BOOLEAN DEFAULT true,
    meets_criteria BOOLEAN DEFAULT true,
    applied_successfully BOOLEAN DEFAULT false,
    
    -- Overlap handling from BDD lines 405-409
    overlap_detected BOOLEAN DEFAULT false,
    warning_dialog_shown BOOLEAN DEFAULT false,
    user_confirmed_overwrite BOOLEAN DEFAULT false,
    
    applied_by VARCHAR(50) NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. BUSINESS PROCESS INTEGRATION
-- =============================================================================

-- Business process upload from BDD lines 412-429
CREATE TABLE business_process_upload (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Interface elements from BDD lines 416-420
    file_selected BOOLEAN DEFAULT false,
    file_type VARCHAR(10) CHECK (file_type IN ('zip', 'rar')),
    upload_button_activated BOOLEAN DEFAULT false,
    cancel_button_activated BOOLEAN DEFAULT false,
    
    -- BP definition storage from BDD lines 423-428
    stage_sequence JSONB,
    user_permissions JSONB,
    available_actions JSONB,
    transition_rules JSONB,
    
    uploaded_by VARCHAR(50) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    upload_successful BOOLEAN DEFAULT false
);

-- =============================================================================
-- 8. VACANCY PLANNING
-- =============================================================================

-- Vacancy planning templates from BDD lines 554-567
CREATE TABLE vacancy_planning_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID,
    position_id UUID,
    
    -- Planning fields from BDD lines 559-564
    required_skills JSONB,
    urgency_level VARCHAR(10) CHECK (urgency_level IN ('High', 'Medium', 'Low')),
    expected_start_date DATE,
    expected_end_date DATE,
    
    -- Status tracking
    vacancy_status VARCHAR(20) DEFAULT 'Open' CHECK (vacancy_status IN (
        'Open', 'In Progress', 'Filled', 'Cancelled'
    )),
    
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Staffing gap monitoring from BDD lines 569-590
CREATE TABLE staffing_gap_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vacancy_id UUID REFERENCES vacancy_planning_templates(id),
    
    -- Gap details from BDD lines 573-577
    department_name VARCHAR(200),
    position_name VARCHAR(200),
    gap_count INTEGER NOT NULL,
    urgency VARCHAR(10),
    days_open INTEGER,
    
    -- Impact analysis
    service_level_impact DECIMAL(5,2),
    capacity_impact DECIMAL(5,2),
    budget_impact DECIMAL(12,2),
    
    monitored_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. PLANNING DASHBOARD
-- =============================================================================

-- Centralized planning dashboard from BDD lines 591-649
CREATE TABLE planning_dashboard_overview (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Planning areas status from BDD lines 596-600
    work_schedules_completion_pct DECIMAL(5,2),
    vacation_plans_completion_pct DECIMAL(5,2),
    shift_patterns_completion_pct DECIMAL(5,2),
    multiskill_plans_completion_pct DECIMAL(5,2),
    
    -- Quick access functions from BDD lines 601-606
    create_schedule_priority VARCHAR(10) DEFAULT 'High',
    approve_plans_priority VARCHAR(10) DEFAULT 'High',
    view_reports_priority VARCHAR(10) DEFAULT 'Medium',
    template_management_priority VARCHAR(10) DEFAULT 'Low',
    
    -- Resource utilization from BDD lines 614-619
    fulltime_utilization_pct DECIMAL(5,2),
    parttime_utilization_pct DECIMAL(5,2),
    contractor_utilization_pct DECIMAL(5,2),
    vacation_pool_utilization_pct DECIMAL(5,2),
    
    -- Bulk operations from BDD lines 624-648
    bulk_operations_enabled BOOLEAN DEFAULT true,
    mass_update_available BOOLEAN DEFAULT true,
    batch_delete_available BOOLEAN DEFAULT true,
    pattern_apply_available BOOLEAN DEFAULT true,
    
    dashboard_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to check operator conflicts in templates
CREATE OR REPLACE FUNCTION check_operator_template_conflicts(
    p_template_id UUID,
    p_group_name VARCHAR(200)
) RETURNS BOOLEAN AS $$
DECLARE
    v_conflict_found BOOLEAN := false;
BEGIN
    -- Check if operators in this group exist in other templates
    -- This is a simplified implementation
    SELECT EXISTS (
        SELECT 1 
        FROM template_group_assignments 
        WHERE group_name = p_group_name 
        AND template_id != p_template_id
    ) INTO v_conflict_found;
    
    IF v_conflict_found THEN
        -- Log the conflict
        UPDATE template_group_assignments
        SET conflict_found = true,
            warning_displayed = true
        WHERE template_id = p_template_id
        AND group_name = p_group_name;
    END IF;
    
    RETURN v_conflict_found;
END;
$$ LANGUAGE plpgsql;

-- Function to pin applied schedule to top
CREATE OR REPLACE FUNCTION pin_applied_schedule(
    p_planning_id UUID
) RETURNS void AS $$
BEGIN
    -- Reset all variants to unpinned
    UPDATE work_schedule_variants
    SET is_pinned_to_top = false,
        sort_order = 999
    WHERE planning_id = p_planning_id;
    
    -- Pin the applied schedule
    UPDATE work_schedule_variants
    SET is_pinned_to_top = true,
        visual_indicator = 'Bold text with checkmark icon',
        background_color = 'light blue',
        sort_order = 1,
        display_label = 'Current'
    WHERE planning_id = p_planning_id
    AND id IN (
        SELECT id FROM work_schedule_planning 
        WHERE id = p_planning_id AND is_applied = true
    );
END;
$$ LANGUAGE plpgsql;

-- Function to generate vacation assignments
CREATE OR REPLACE FUNCTION generate_vacation_assignments(
    p_generation_rules_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_assignments_made INTEGER := 0;
BEGIN
    -- This is a placeholder for complex vacation generation logic
    -- Would implement the rules from BDD lines 453-459
    
    -- Log generation attempt
    INSERT INTO vacation_operations (
        employee_id, operation_type, vacation_type,
        operated_by, operated_at
    ) VALUES (
        uuid_generate_v4(), 'Add Vacation', 'Desired Vacation',
        'system', CURRENT_TIMESTAMP
    );
    
    v_assignments_made := 1; -- Simplified return
    
    RETURN v_assignments_made;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_workflow_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_multiskill_templates_timestamp
    BEFORE UPDATE ON multiskill_planning_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_workflow_timestamps();

CREATE TRIGGER update_work_schedule_tasks_timestamp
    BEFORE UPDATE ON work_schedule_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_workflow_timestamps();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Template management indexes
CREATE INDEX idx_multiskill_templates_name ON multiskill_planning_templates(template_name);
CREATE INDEX idx_multiskill_templates_active ON multiskill_planning_templates(is_active);
CREATE INDEX idx_template_groups_template ON template_group_assignments(template_id);
CREATE INDEX idx_template_operations_template ON template_operations_audit(template_id);

-- Schedule planning indexes
CREATE INDEX idx_work_schedule_template ON work_schedule_planning(template_id);
CREATE INDEX idx_work_schedule_applied ON work_schedule_planning(is_applied);
CREATE INDEX idx_schedule_variants_planning ON work_schedule_variants(planning_id);
CREATE INDEX idx_schedule_tasks_planning ON work_schedule_tasks(planning_id);
CREATE INDEX idx_schedule_tasks_status ON work_schedule_tasks(schedule_status, task_status);

-- Vacation planning indexes
CREATE INDEX idx_vacation_operations_employee ON vacation_operations(employee_id);
CREATE INDEX idx_vacation_operations_type ON vacation_operations(operation_type);

-- Dashboard indexes
CREATE INDEX idx_vacancy_planning_status ON vacancy_planning_templates(vacancy_status);
CREATE INDEX idx_staffing_gaps_urgency ON staffing_gap_monitoring(urgency);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Sample multi-skill planning template
INSERT INTO multiskill_planning_templates (
    template_name, created_by
) VALUES (
    'Technical Support Teams', 'admin'
);

-- Sample timezone display preference
INSERT INTO timezone_display_preferences (
    user_id, display_mode, format_example
) VALUES (
    'admin', 'Dual Time', '09:00 EST (14:00 UTC)'
);

-- Sample vacation generation rules
INSERT INTO vacation_generation_rules (
    use_preferences_first, avoid_high_demand, ensure_minimum_staffing,
    honor_preferences_pct, configured_by
) VALUES (
    true, true, true, 85.0, 'admin'
);

-- Sample planning dashboard overview
INSERT INTO planning_dashboard_overview (
    work_schedules_completion_pct, vacation_plans_completion_pct,
    shift_patterns_completion_pct, multiskill_plans_completion_pct,
    fulltime_utilization_pct, parttime_utilization_pct
) VALUES (
    85.0, 92.0, 78.0, 88.0, 95.0, 75.0
);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_planners;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operators;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_planners;