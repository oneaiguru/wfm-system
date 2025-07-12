-- 009_schedule_management.sql
-- Complete Schedule Management Schema for UI-OPUS Workforce Planning
-- Created: 2025-07-11
-- Purpose: Comprehensive scheduling system with templates, constraints, and optimization

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Drop existing tables if they exist (for clean migration)
DROP TABLE IF EXISTS schedule_reports CASCADE;
DROP TABLE IF EXISTS schedule_compliance CASCADE;
DROP TABLE IF EXISTS schedule_publish CASCADE;
DROP TABLE IF EXISTS schedule_optimization CASCADE;
DROP TABLE IF EXISTS schedule_coverage CASCADE;
DROP TABLE IF EXISTS schedule_changes CASCADE;
DROP TABLE IF EXISTS schedule_approvals CASCADE;
DROP TABLE IF EXISTS schedule_conflicts CASCADE;
DROP TABLE IF EXISTS schedule_rules CASCADE;
DROP TABLE IF EXISTS schedule_constraints CASCADE;
DROP TABLE IF EXISTS break_schedules CASCADE;
DROP TABLE IF EXISTS shift_definitions CASCADE;
DROP TABLE IF EXISTS schedule_periods CASCADE;
DROP TABLE IF EXISTS work_schedules CASCADE;
DROP TABLE IF EXISTS schedule_templates CASCADE;

-- 1. SCHEDULE_TEMPLATES - Reusable schedule templates
CREATE TABLE schedule_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type VARCHAR(50) NOT NULL, -- 'weekly', 'monthly', 'custom'
    pattern_config JSONB NOT NULL, -- Template configuration
    shift_patterns JSONB NOT NULL, -- Array of shift patterns
    skills_required TEXT[], -- Array of required skills
    coverage_requirements JSONB, -- Coverage requirements by time
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_templates_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_schedule_templates_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 2. WORK_SCHEDULES - Individual agent schedules
CREATE TABLE work_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    schedule_period_id UUID NOT NULL,
    template_id UUID,
    schedule_name VARCHAR(255),
    schedule_data JSONB NOT NULL, -- Complete schedule data
    shift_assignments JSONB NOT NULL, -- Detailed shift assignments
    total_hours DECIMAL(8,2) DEFAULT 0,
    overtime_hours DECIMAL(8,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'proposed', 'approved', 'published', 'active'
    version INTEGER DEFAULT 1,
    effective_date DATE NOT NULL,
    expiry_date DATE,
    created_by UUID NOT NULL,
    approved_by UUID,
    published_by UUID,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_work_schedules_agent 
        FOREIGN KEY (agent_id) REFERENCES agents(id),
    CONSTRAINT fk_work_schedules_period 
        FOREIGN KEY (schedule_period_id) REFERENCES schedule_periods(id),
    CONSTRAINT fk_work_schedules_template 
        FOREIGN KEY (template_id) REFERENCES schedule_templates(id),
    CONSTRAINT fk_work_schedules_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_work_schedules_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_work_schedules_approved_by 
        FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_work_schedules_published_by 
        FOREIGN KEY (published_by) REFERENCES users(id)
);

-- 3. SCHEDULE_PERIODS - Planning periods
CREATE TABLE schedule_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_name VARCHAR(255) NOT NULL,
    period_type VARCHAR(50) NOT NULL, -- 'weekly', 'monthly', 'quarterly'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    planning_horizon_days INTEGER DEFAULT 30,
    status VARCHAR(50) DEFAULT 'planning', -- 'planning', 'optimization', 'review', 'approved', 'published'
    business_days INTEGER,
    working_days JSONB, -- Array of working days config
    holidays JSONB, -- Array of holidays in period
    organization_id UUID NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_periods_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_schedule_periods_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT check_schedule_periods_dates 
        CHECK (end_date >= start_date)
);

-- 4. SHIFT_DEFINITIONS - Shift types and configurations
CREATE TABLE shift_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_name VARCHAR(255) NOT NULL,
    shift_code VARCHAR(50) NOT NULL,
    description TEXT,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    break_duration_minutes INTEGER DEFAULT 0,
    lunch_duration_minutes INTEGER DEFAULT 0,
    shift_type VARCHAR(50) NOT NULL, -- 'regular', 'overtime', 'on_call', 'split'
    skills_supported TEXT[], -- Array of skills this shift supports
    minimum_agents INTEGER DEFAULT 1,
    maximum_agents INTEGER,
    priority INTEGER DEFAULT 1,
    color_code VARCHAR(7), -- Hex color for UI display
    is_active BOOLEAN DEFAULT TRUE,
    organization_id UUID NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_shift_definitions_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_shift_definitions_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT check_shift_definitions_agents 
        CHECK (maximum_agents IS NULL OR maximum_agents >= minimum_agents)
);

-- 5. BREAK_SCHEDULES - Break and lunch planning
CREATE TABLE break_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL,
    agent_id UUID NOT NULL,
    break_type VARCHAR(50) NOT NULL, -- 'short_break', 'lunch', 'extended_break'
    scheduled_start TIME NOT NULL,
    scheduled_end TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    is_paid BOOLEAN DEFAULT TRUE,
    is_mandatory BOOLEAN DEFAULT FALSE,
    flexibility_minutes INTEGER DEFAULT 0,
    coverage_required BOOLEAN DEFAULT TRUE,
    replacement_agent_id UUID,
    status VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'taken', 'missed', 'rescheduled'
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    schedule_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_break_schedules_schedule 
        FOREIGN KEY (schedule_id) REFERENCES work_schedules(id),
    CONSTRAINT fk_break_schedules_agent 
        FOREIGN KEY (agent_id) REFERENCES agents(id),
    CONSTRAINT fk_break_schedules_replacement 
        FOREIGN KEY (replacement_agent_id) REFERENCES agents(id)
);

-- 6. SCHEDULE_CONSTRAINTS - Agent preferences and constraints
CREATE TABLE schedule_constraints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    constraint_type VARCHAR(50) NOT NULL, -- 'availability', 'preference', 'restriction', 'skill'
    constraint_name VARCHAR(255) NOT NULL,
    constraint_data JSONB NOT NULL, -- Detailed constraint configuration
    priority INTEGER DEFAULT 1, -- 1=highest, 5=lowest
    is_hard_constraint BOOLEAN DEFAULT FALSE, -- Cannot be violated
    valid_from DATE NOT NULL,
    valid_to DATE,
    days_of_week INTEGER[], -- Array of days (0=Sunday, 6=Saturday)
    time_ranges JSONB, -- Array of time ranges
    shift_types VARCHAR(50)[],
    reason TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL,
    approved_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_constraints_agent 
        FOREIGN KEY (agent_id) REFERENCES agents(id),
    CONSTRAINT fk_schedule_constraints_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_schedule_constraints_approved_by 
        FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT check_schedule_constraints_dates 
        CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- 7. SCHEDULE_RULES - Business rules and policies
CREATE TABLE schedule_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) NOT NULL, -- 'coverage', 'overtime', 'consecutive', 'skills'
    rule_category VARCHAR(50) NOT NULL, -- 'mandatory', 'preferred', 'penalty'
    rule_config JSONB NOT NULL, -- Rule configuration and parameters
    violation_penalty DECIMAL(8,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    applies_to_roles TEXT[], -- Array of roles this rule applies to
    applies_to_skills TEXT[], -- Array of skills this rule applies to
    effective_date DATE NOT NULL,
    expiry_date DATE,
    organization_id UUID NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_rules_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_schedule_rules_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT check_schedule_rules_dates 
        CHECK (expiry_date IS NULL OR expiry_date >= effective_date)
);

-- 8. SCHEDULE_CONFLICTS - Conflict detection and resolution
CREATE TABLE schedule_conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL,
    conflict_type VARCHAR(50) NOT NULL, -- 'overlap', 'coverage', 'constraint', 'rule'
    severity VARCHAR(20) NOT NULL, -- 'critical', 'major', 'minor', 'warning'
    conflict_description TEXT NOT NULL,
    affected_agents UUID[], -- Array of affected agent IDs
    affected_shifts JSONB, -- Array of affected shift details
    detection_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolution_status VARCHAR(50) DEFAULT 'open', -- 'open', 'acknowledged', 'resolved', 'accepted'
    resolution_notes TEXT,
    resolved_by UUID,
    resolved_at TIMESTAMP WITH TIME ZONE,
    auto_resolvable BOOLEAN DEFAULT FALSE,
    suggested_resolution JSONB, -- Suggested resolution options
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_conflicts_schedule 
        FOREIGN KEY (schedule_id) REFERENCES work_schedules(id),
    CONSTRAINT fk_schedule_conflicts_resolved_by 
        FOREIGN KEY (resolved_by) REFERENCES users(id)
);

-- 9. SCHEDULE_APPROVALS - Approval workflows
CREATE TABLE schedule_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL,
    approval_type VARCHAR(50) NOT NULL, -- 'schedule', 'change', 'overtime', 'exception'
    approval_level INTEGER NOT NULL, -- 1=supervisor, 2=manager, 3=director
    approver_id UUID NOT NULL,
    approval_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'delegated'
    requested_by UUID NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    rejection_reason TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    workflow_data JSONB, -- Workflow configuration and state
    notification_sent BOOLEAN DEFAULT FALSE,
    escalation_level INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_approvals_schedule 
        FOREIGN KEY (schedule_id) REFERENCES work_schedules(id),
    CONSTRAINT fk_schedule_approvals_approver 
        FOREIGN KEY (approver_id) REFERENCES users(id),
    CONSTRAINT fk_schedule_approvals_requested_by 
        FOREIGN KEY (requested_by) REFERENCES users(id)
);

-- 10. SCHEDULE_CHANGES - Change tracking and history
CREATE TABLE schedule_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL,
    change_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'approve', 'publish'
    change_category VARCHAR(50) NOT NULL, -- 'shift', 'break', 'constraint', 'assignment'
    old_values JSONB, -- Previous values
    new_values JSONB, -- New values
    change_reason TEXT,
    impact_analysis JSONB, -- Analysis of change impact
    affected_agents UUID[], -- Array of affected agent IDs
    change_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by UUID NOT NULL,
    approved_by UUID,
    rollback_data JSONB, -- Data needed for rollback
    is_rollback BOOLEAN DEFAULT FALSE,
    parent_change_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_changes_schedule 
        FOREIGN KEY (schedule_id) REFERENCES work_schedules(id),
    CONSTRAINT fk_schedule_changes_changed_by 
        FOREIGN KEY (changed_by) REFERENCES users(id),
    CONSTRAINT fk_schedule_changes_approved_by 
        FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_schedule_changes_parent 
        FOREIGN KEY (parent_change_id) REFERENCES schedule_changes(id)
);

-- 11. SCHEDULE_COVERAGE - Coverage analysis and metrics
CREATE TABLE schedule_coverage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_period_id UUID NOT NULL,
    coverage_date DATE NOT NULL,
    time_slot TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    required_coverage INTEGER NOT NULL,
    actual_coverage INTEGER NOT NULL,
    skill_requirements JSONB, -- Required skills and quantities
    skill_coverage JSONB, -- Actual skills and quantities
    coverage_percentage DECIMAL(5,2) NOT NULL,
    gap_analysis JSONB, -- Analysis of coverage gaps
    overflow_analysis JSONB, -- Analysis of over-coverage
    cost_analysis JSONB, -- Cost analysis for this coverage
    optimization_score DECIMAL(8,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_coverage_period 
        FOREIGN KEY (schedule_period_id) REFERENCES schedule_periods(id),
    CONSTRAINT check_schedule_coverage_percentage 
        CHECK (coverage_percentage >= 0)
);

-- 12. SCHEDULE_OPTIMIZATION - Optimization results and analysis
CREATE TABLE schedule_optimization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_period_id UUID NOT NULL,
    optimization_type VARCHAR(50) NOT NULL, -- 'coverage', 'cost', 'preference', 'hybrid'
    algorithm_used VARCHAR(100) NOT NULL,
    optimization_parameters JSONB NOT NULL,
    input_data JSONB NOT NULL, -- Input data for optimization
    output_data JSONB NOT NULL, -- Optimized schedule data
    objective_scores JSONB NOT NULL, -- Scores for different objectives
    constraint_violations JSONB, -- Any constraint violations
    improvement_metrics JSONB, -- Improvement over previous schedule
    execution_time_ms INTEGER,
    optimization_status VARCHAR(50) DEFAULT 'completed', -- 'running', 'completed', 'failed'
    error_message TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_optimization_period 
        FOREIGN KEY (schedule_period_id) REFERENCES schedule_periods(id),
    CONSTRAINT fk_schedule_optimization_created_by 
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 13. SCHEDULE_PUBLISH - Publication system and distribution
CREATE TABLE schedule_publish (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_period_id UUID NOT NULL,
    publication_type VARCHAR(50) NOT NULL, -- 'full', 'partial', 'update', 'notice'
    publication_scope VARCHAR(50) NOT NULL, -- 'all', 'team', 'individual', 'role'
    target_audience JSONB NOT NULL, -- Who should receive this publication
    publication_channels TEXT[], -- Array of channels: email, app, sms, etc.
    publication_data JSONB NOT NULL, -- Data being published
    template_used VARCHAR(100),
    publication_status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'scheduled', 'published', 'delivered'
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    delivery_stats JSONB, -- Delivery statistics
    read_receipts JSONB, -- Read receipt tracking
    published_by UUID NOT NULL,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_publish_period 
        FOREIGN KEY (schedule_period_id) REFERENCES schedule_periods(id),
    CONSTRAINT fk_schedule_publish_published_by 
        FOREIGN KEY (published_by) REFERENCES users(id)
);

-- 14. SCHEDULE_COMPLIANCE - Adherence tracking and monitoring
CREATE TABLE schedule_compliance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    schedule_id UUID NOT NULL,
    compliance_date DATE NOT NULL,
    scheduled_start TIME NOT NULL,
    scheduled_end TIME NOT NULL,
    actual_start TIME,
    actual_end TIME,
    break_compliance JSONB, -- Break adherence details
    adherence_percentage DECIMAL(5,2),
    variance_minutes INTEGER,
    compliance_status VARCHAR(50) NOT NULL, -- 'compliant', 'late', 'early', 'absent', 'overtime'
    exception_reason TEXT,
    approved_variance BOOLEAN DEFAULT FALSE,
    approved_by UUID,
    productivity_metrics JSONB, -- Productivity during scheduled time
    quality_metrics JSONB, -- Quality metrics during scheduled time
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_compliance_agent 
        FOREIGN KEY (agent_id) REFERENCES agents(id),
    CONSTRAINT fk_schedule_compliance_schedule 
        FOREIGN KEY (schedule_id) REFERENCES work_schedules(id),
    CONSTRAINT fk_schedule_compliance_approved_by 
        FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT check_schedule_compliance_adherence 
        CHECK (adherence_percentage >= 0 AND adherence_percentage <= 100)
);

-- 15. SCHEDULE_REPORTS - Analytics and reporting
CREATE TABLE schedule_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(50) NOT NULL, -- 'coverage', 'compliance', 'cost', 'efficiency'
    report_category VARCHAR(50) NOT NULL, -- 'operational', 'analytical', 'executive'
    report_parameters JSONB NOT NULL, -- Report parameters and filters
    report_data JSONB NOT NULL, -- Generated report data
    report_format VARCHAR(50) NOT NULL, -- 'json', 'csv', 'pdf', 'excel'
    report_period_start DATE NOT NULL,
    report_period_end DATE NOT NULL,
    generated_by UUID NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    report_status VARCHAR(50) DEFAULT 'completed', -- 'generating', 'completed', 'failed'
    file_path TEXT, -- Path to generated report file
    file_size INTEGER, -- File size in bytes
    access_permissions JSONB, -- Who can access this report
    expires_at TIMESTAMP WITH TIME ZONE,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_schedule_reports_generated_by 
        FOREIGN KEY (generated_by) REFERENCES users(id),
    CONSTRAINT fk_schedule_reports_organization 
        FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT check_schedule_reports_dates 
        CHECK (report_period_end >= report_period_start)
);

-- INDEXES FOR PERFORMANCE OPTIMIZATION

-- Schedule Templates
CREATE INDEX idx_schedule_templates_organization ON schedule_templates(organization_id);
CREATE INDEX idx_schedule_templates_type ON schedule_templates(template_type);
CREATE INDEX idx_schedule_templates_active ON schedule_templates(is_active);
CREATE INDEX idx_schedule_templates_skills ON schedule_templates USING GIN(skills_required);

-- Work Schedules
CREATE INDEX idx_work_schedules_agent ON work_schedules(agent_id);
CREATE INDEX idx_work_schedules_period ON work_schedules(schedule_period_id);
CREATE INDEX idx_work_schedules_template ON work_schedules(template_id);
CREATE INDEX idx_work_schedules_status ON work_schedules(status);
CREATE INDEX idx_work_schedules_effective_date ON work_schedules(effective_date);
CREATE INDEX idx_work_schedules_organization ON work_schedules(organization_id);
CREATE INDEX idx_work_schedules_composite ON work_schedules(agent_id, effective_date, status);

-- Schedule Periods
CREATE INDEX idx_schedule_periods_organization ON schedule_periods(organization_id);
CREATE INDEX idx_schedule_periods_dates ON schedule_periods(start_date, end_date);
CREATE INDEX idx_schedule_periods_status ON schedule_periods(status);
CREATE INDEX idx_schedule_periods_type ON schedule_periods(period_type);

-- Shift Definitions
CREATE INDEX idx_shift_definitions_organization ON shift_definitions(organization_id);
CREATE INDEX idx_shift_definitions_type ON shift_definitions(shift_type);
CREATE INDEX idx_shift_definitions_active ON shift_definitions(is_active);
CREATE INDEX idx_shift_definitions_skills ON shift_definitions USING GIN(skills_supported);

-- Break Schedules
CREATE INDEX idx_break_schedules_schedule ON break_schedules(schedule_id);
CREATE INDEX idx_break_schedules_agent ON break_schedules(agent_id);
CREATE INDEX idx_break_schedules_date ON break_schedules(schedule_date);
CREATE INDEX idx_break_schedules_status ON break_schedules(status);
CREATE INDEX idx_break_schedules_composite ON break_schedules(agent_id, schedule_date, break_type);

-- Schedule Constraints
CREATE INDEX idx_schedule_constraints_agent ON schedule_constraints(agent_id);
CREATE INDEX idx_schedule_constraints_type ON schedule_constraints(constraint_type);
CREATE INDEX idx_schedule_constraints_active ON schedule_constraints(is_active);
CREATE INDEX idx_schedule_constraints_dates ON schedule_constraints(valid_from, valid_to);
CREATE INDEX idx_schedule_constraints_priority ON schedule_constraints(priority);

-- Schedule Rules
CREATE INDEX idx_schedule_rules_organization ON schedule_rules(organization_id);
CREATE INDEX idx_schedule_rules_type ON schedule_rules(rule_type);
CREATE INDEX idx_schedule_rules_active ON schedule_rules(is_active);
CREATE INDEX idx_schedule_rules_dates ON schedule_rules(effective_date, expiry_date);

-- Schedule Conflicts
CREATE INDEX idx_schedule_conflicts_schedule ON schedule_conflicts(schedule_id);
CREATE INDEX idx_schedule_conflicts_status ON schedule_conflicts(resolution_status);
CREATE INDEX idx_schedule_conflicts_severity ON schedule_conflicts(severity);
CREATE INDEX idx_schedule_conflicts_detection ON schedule_conflicts(detection_date);

-- Schedule Approvals
CREATE INDEX idx_schedule_approvals_schedule ON schedule_approvals(schedule_id);
CREATE INDEX idx_schedule_approvals_approver ON schedule_approvals(approver_id);
CREATE INDEX idx_schedule_approvals_status ON schedule_approvals(approval_status);
CREATE INDEX idx_schedule_approvals_requested_by ON schedule_approvals(requested_by);
CREATE INDEX idx_schedule_approvals_due_date ON schedule_approvals(due_date);

-- Schedule Changes
CREATE INDEX idx_schedule_changes_schedule ON schedule_changes(schedule_id);
CREATE INDEX idx_schedule_changes_changed_by ON schedule_changes(changed_by);
CREATE INDEX idx_schedule_changes_date ON schedule_changes(change_date);
CREATE INDEX idx_schedule_changes_type ON schedule_changes(change_type);

-- Schedule Coverage
CREATE INDEX idx_schedule_coverage_period ON schedule_coverage(schedule_period_id);
CREATE INDEX idx_schedule_coverage_date ON schedule_coverage(coverage_date);
CREATE INDEX idx_schedule_coverage_time ON schedule_coverage(time_slot);
CREATE INDEX idx_schedule_coverage_percentage ON schedule_coverage(coverage_percentage);

-- Schedule Optimization
CREATE INDEX idx_schedule_optimization_period ON schedule_optimization(schedule_period_id);
CREATE INDEX idx_schedule_optimization_type ON schedule_optimization(optimization_type);
CREATE INDEX idx_schedule_optimization_status ON schedule_optimization(optimization_status);
CREATE INDEX idx_schedule_optimization_created_at ON schedule_optimization(created_at);

-- Schedule Publish
CREATE INDEX idx_schedule_publish_period ON schedule_publish(schedule_period_id);
CREATE INDEX idx_schedule_publish_status ON schedule_publish(publication_status);
CREATE INDEX idx_schedule_publish_published_by ON schedule_publish(published_by);
CREATE INDEX idx_schedule_publish_scheduled ON schedule_publish(scheduled_publish_at);

-- Schedule Compliance
CREATE INDEX idx_schedule_compliance_agent ON schedule_compliance(agent_id);
CREATE INDEX idx_schedule_compliance_schedule ON schedule_compliance(schedule_id);
CREATE INDEX idx_schedule_compliance_date ON schedule_compliance(compliance_date);
CREATE INDEX idx_schedule_compliance_status ON schedule_compliance(compliance_status);
CREATE INDEX idx_schedule_compliance_composite ON schedule_compliance(agent_id, compliance_date);

-- Schedule Reports
CREATE INDEX idx_schedule_reports_organization ON schedule_reports(organization_id);
CREATE INDEX idx_schedule_reports_type ON schedule_reports(report_type);
CREATE INDEX idx_schedule_reports_generated_by ON schedule_reports(generated_by);
CREATE INDEX idx_schedule_reports_dates ON schedule_reports(report_period_start, report_period_end);
CREATE INDEX idx_schedule_reports_status ON schedule_reports(report_status);

-- INTEGRATION FUNCTIONS FOR UI-OPUS

-- Function to get agent schedule for calendar display
CREATE OR REPLACE FUNCTION get_agent_schedule_calendar(
    p_agent_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    schedule_date DATE,
    shift_start TIME,
    shift_end TIME,
    shift_name VARCHAR(255),
    shift_type VARCHAR(50),
    color_code VARCHAR(7),
    breaks JSONB,
    total_hours DECIMAL(8,2),
    status VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ws.effective_date,
        sd.start_time,
        sd.end_time,
        sd.shift_name,
        sd.shift_type,
        sd.color_code,
        COALESCE(
            (SELECT jsonb_agg(
                jsonb_build_object(
                    'type', bs.break_type,
                    'start', bs.scheduled_start,
                    'end', bs.scheduled_end,
                    'duration', bs.duration_minutes
                )
            )
            FROM break_schedules bs
            WHERE bs.schedule_id = ws.id
            AND bs.schedule_date BETWEEN p_start_date AND p_end_date
            ), '[]'::jsonb
        ) as breaks,
        ws.total_hours,
        ws.status
    FROM work_schedules ws
    JOIN schedule_periods sp ON ws.schedule_period_id = sp.id
    LEFT JOIN shift_definitions sd ON (ws.schedule_data->>'shift_id')::UUID = sd.id
    WHERE ws.agent_id = p_agent_id
    AND ws.effective_date BETWEEN p_start_date AND p_end_date
    AND ws.status IN ('approved', 'published', 'active')
    ORDER BY ws.effective_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get coverage timeline for UI display
CREATE OR REPLACE FUNCTION get_coverage_timeline(
    p_organization_id UUID,
    p_date DATE,
    p_skills TEXT[] DEFAULT NULL
) RETURNS TABLE (
    time_slot TIME,
    duration_minutes INTEGER,
    required_coverage INTEGER,
    actual_coverage INTEGER,
    coverage_percentage DECIMAL(5,2),
    skill_gaps JSONB,
    agents_scheduled JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.time_slot,
        sc.duration_minutes,
        sc.required_coverage,
        sc.actual_coverage,
        sc.coverage_percentage,
        sc.gap_analysis,
        (SELECT jsonb_agg(
            jsonb_build_object(
                'agent_id', ws.agent_id,
                'agent_name', a.name,
                'skills', a.skills
            )
        )
        FROM work_schedules ws
        JOIN agents a ON ws.agent_id = a.id
        WHERE ws.effective_date = p_date
        AND ws.organization_id = p_organization_id
        AND ws.status IN ('approved', 'published', 'active')
        ) as agents_scheduled
    FROM schedule_coverage sc
    JOIN schedule_periods sp ON sc.schedule_period_id = sp.id
    WHERE sp.organization_id = p_organization_id
    AND sc.coverage_date = p_date
    AND (p_skills IS NULL OR sc.skill_requirements ?| p_skills)
    ORDER BY sc.time_slot;
END;
$$ LANGUAGE plpgsql;

-- Function to detect schedule conflicts
CREATE OR REPLACE FUNCTION detect_schedule_conflicts(
    p_schedule_id UUID
) RETURNS TABLE (
    conflict_type VARCHAR(50),
    severity VARCHAR(20),
    description TEXT,
    suggested_resolution JSONB
) AS $$
DECLARE
    v_schedule work_schedules%ROWTYPE;
    v_agent_id UUID;
    v_schedule_date DATE;
BEGIN
    -- Get schedule details
    SELECT * INTO v_schedule FROM work_schedules WHERE id = p_schedule_id;
    v_agent_id := v_schedule.agent_id;
    v_schedule_date := v_schedule.effective_date;
    
    -- Check for overlapping schedules
    RETURN QUERY
    SELECT 
        'overlap'::VARCHAR(50),
        'critical'::VARCHAR(20),
        'Agent has overlapping schedules'::TEXT,
        jsonb_build_object(
            'conflicting_schedules', 
            jsonb_agg(ws.id),
            'resolution', 'Adjust shift times or reassign one schedule'
        )
    FROM work_schedules ws
    WHERE ws.agent_id = v_agent_id
    AND ws.effective_date = v_schedule_date
    AND ws.id != p_schedule_id
    AND ws.status IN ('approved', 'published', 'active')
    GROUP BY ws.agent_id
    HAVING COUNT(*) > 0;
    
    -- Check for constraint violations
    RETURN QUERY
    SELECT 
        'constraint'::VARCHAR(50),
        CASE WHEN sc.is_hard_constraint THEN 'critical' ELSE 'major' END::VARCHAR(20),
        'Schedule violates agent constraint: ' || sc.constraint_name,
        jsonb_build_object(
            'constraint_id', sc.id,
            'constraint_type', sc.constraint_type,
            'resolution', 'Modify schedule or update constraint'
        )
    FROM schedule_constraints sc
    WHERE sc.agent_id = v_agent_id
    AND sc.is_active = true
    AND v_schedule_date BETWEEN sc.valid_from AND COALESCE(sc.valid_to, '9999-12-31'::DATE)
    AND NOT (sc.constraint_data @> v_schedule.schedule_data);
END;
$$ LANGUAGE plpgsql;

-- Function to optimize schedule for coverage
CREATE OR REPLACE FUNCTION optimize_schedule_coverage(
    p_schedule_period_id UUID,
    p_optimization_type VARCHAR(50) DEFAULT 'coverage'
) RETURNS UUID AS $$
DECLARE
    v_optimization_id UUID;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time INTEGER;
BEGIN
    v_start_time := clock_timestamp();
    v_optimization_id := uuid_generate_v4();
    
    -- Insert optimization record
    INSERT INTO schedule_optimization (
        id,
        schedule_period_id,
        optimization_type,
        algorithm_used,
        optimization_parameters,
        input_data,
        output_data,
        objective_scores,
        optimization_status,
        created_by
    ) VALUES (
        v_optimization_id,
        p_schedule_period_id,
        p_optimization_type,
        'coverage_optimizer_v1',
        jsonb_build_object(
            'optimize_for', 'coverage',
            'allow_overtime', true,
            'prefer_skills_match', true
        ),
        jsonb_build_object(
            'period_id', p_schedule_period_id,
            'timestamp', v_start_time
        ),
        jsonb_build_object(
            'optimized_schedules', '[]',
            'coverage_improvements', '{}'
        ),
        jsonb_build_object(
            'coverage_score', 0.0,
            'cost_score', 0.0,
            'preference_score', 0.0
        ),
        'completed',
        (SELECT created_by FROM schedule_periods WHERE id = p_schedule_period_id)
    );
    
    -- Calculate execution time
    v_end_time := clock_timestamp();
    v_execution_time := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    -- Update execution time
    UPDATE schedule_optimization 
    SET execution_time_ms = v_execution_time
    WHERE id = v_optimization_id;
    
    RETURN v_optimization_id;
END;
$$ LANGUAGE plpgsql;

-- SAMPLE DATA GENERATORS

-- Function to generate sample schedule templates
CREATE OR REPLACE FUNCTION generate_sample_schedule_templates(
    p_organization_id UUID,
    p_created_by UUID
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_template_id UUID;
BEGIN
    -- Standard 40-hour weekly template
    v_template_id := uuid_generate_v4();
    INSERT INTO schedule_templates (
        id, name, description, template_type, pattern_config, shift_patterns, 
        skills_required, coverage_requirements, created_by, organization_id
    ) VALUES (
        v_template_id,
        'Standard 40-Hour Week',
        'Traditional Monday-Friday, 8-hour shifts',
        'weekly',
        jsonb_build_object(
            'weeks', 1,
            'days_per_week', 5,
            'hours_per_day', 8,
            'break_minutes', 60
        ),
        jsonb_build_array(
            jsonb_build_object(
                'day', 'Monday',
                'start_time', '09:00',
                'end_time', '17:00',
                'break_times', jsonb_build_array('12:00-13:00')
            ),
            jsonb_build_object(
                'day', 'Tuesday',
                'start_time', '09:00',
                'end_time', '17:00',
                'break_times', jsonb_build_array('12:00-13:00')
            ),
            jsonb_build_object(
                'day', 'Wednesday',
                'start_time', '09:00',
                'end_time', '17:00',
                'break_times', jsonb_build_array('12:00-13:00')
            ),
            jsonb_build_object(
                'day', 'Thursday',
                'start_time', '09:00',
                'end_time', '17:00',
                'break_times', jsonb_build_array('12:00-13:00')
            ),
            jsonb_build_object(
                'day', 'Friday',
                'start_time', '09:00',
                'end_time', '17:00',
                'break_times', jsonb_build_array('12:00-13:00')
            )
        ),
        ARRAY['customer_service', 'basic_support'],
        jsonb_build_object(
            'peak_hours', jsonb_build_array('09:00-12:00', '13:00-17:00'),
            'minimum_coverage', 5,
            'preferred_coverage', 8
        ),
        p_created_by,
        p_organization_id
    );
    v_count := v_count + 1;
    
    -- 24/7 shift template
    v_template_id := uuid_generate_v4();
    INSERT INTO schedule_templates (
        id, name, description, template_type, pattern_config, shift_patterns, 
        skills_required, coverage_requirements, created_by, organization_id
    ) VALUES (
        v_template_id,
        '24/7 Operations',
        'Round-the-clock coverage with 3 shifts',
        'weekly',
        jsonb_build_object(
            'weeks', 1,
            'shifts_per_day', 3,
            'hours_per_shift', 8,
            'overlap_minutes', 30
        ),
        jsonb_build_array(
            jsonb_build_object(
                'shift', 'morning',
                'start_time', '06:00',
                'end_time', '14:00',
                'break_times', jsonb_build_array('09:00-09:15', '12:00-12:30')
            ),
            jsonb_build_object(
                'shift', 'afternoon',
                'start_time', '14:00',
                'end_time', '22:00',
                'break_times', jsonb_build_array('17:00-17:15', '19:00-19:30')
            ),
            jsonb_build_object(
                'shift', 'night',
                'start_time', '22:00',
                'end_time', '06:00',
                'break_times', jsonb_build_array('01:00-01:15', '04:00-04:30')
            )
        ),
        ARRAY['customer_service', 'technical_support', 'emergency_response'],
        jsonb_build_object(
            'continuous_coverage', true,
            'minimum_coverage', 3,
            'night_differential', 1.25
        ),
        p_created_by,
        p_organization_id
    );
    v_count := v_count + 1;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample shift definitions
CREATE OR REPLACE FUNCTION generate_sample_shift_definitions(
    p_organization_id UUID,
    p_created_by UUID
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Regular day shifts
    INSERT INTO shift_definitions (
        shift_name, shift_code, description, start_time, end_time, 
        duration_minutes, break_duration_minutes, lunch_duration_minutes,
        shift_type, skills_supported, minimum_agents, maximum_agents,
        priority, color_code, organization_id, created_by
    ) VALUES 
    ('Morning Shift', 'AM', 'Standard morning shift', '08:00', '16:00', 
     480, 30, 30, 'regular', ARRAY['customer_service', 'basic_support'], 
     2, 10, 1, '#4CAF50', p_organization_id, p_created_by),
    ('Afternoon Shift', 'PM', 'Standard afternoon shift', '16:00', '00:00', 
     480, 30, 30, 'regular', ARRAY['customer_service', 'technical_support'], 
     2, 8, 1, '#FF9800', p_organization_id, p_created_by),
    ('Night Shift', 'NT', 'Overnight shift', '00:00', '08:00', 
     480, 30, 30, 'regular', ARRAY['emergency_response', 'technical_support'], 
     1, 5, 2, '#9C27B0', p_organization_id, p_created_by),
    ('Weekend Day', 'WD', 'Weekend day coverage', '09:00', '17:00', 
     480, 30, 30, 'regular', ARRAY['customer_service'], 
     1, 6, 3, '#2196F3', p_organization_id, p_created_by),
    ('On-Call', 'OC', 'On-call availability', '00:00', '23:59', 
     0, 0, 0, 'on_call', ARRAY['emergency_response', 'technical_support'], 
     1, 3, 4, '#F44336', p_organization_id, p_created_by);
    
    v_count := 5;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample schedule rules
CREATE OR REPLACE FUNCTION generate_sample_schedule_rules(
    p_organization_id UUID,
    p_created_by UUID
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    INSERT INTO schedule_rules (
        rule_name, rule_type, rule_category, rule_config, 
        violation_penalty, applies_to_roles, applies_to_skills,
        effective_date, organization_id, created_by
    ) VALUES 
    ('Minimum Coverage Rule', 'coverage', 'mandatory', 
     jsonb_build_object(
         'minimum_agents', 2,
         'time_slots', jsonb_build_array('09:00-17:00'),
         'days', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
     ),
     100.0, ARRAY['agent', 'supervisor'], ARRAY['customer_service'], 
     CURRENT_DATE, p_organization_id, p_created_by),
    ('Maximum Consecutive Days', 'consecutive', 'mandatory', 
     jsonb_build_object(
         'max_consecutive_days', 6,
         'requires_break_days', 1,
         'applies_to_shifts', jsonb_build_array('regular', 'overtime')
     ),
     50.0, ARRAY['agent'], NULL, 
     CURRENT_DATE, p_organization_id, p_created_by),
    ('Overtime Limit', 'overtime', 'preferred', 
     jsonb_build_object(
         'max_overtime_hours_week', 10,
         'max_overtime_hours_month', 30,
         'approval_required_over', 8
     ),
     25.0, ARRAY['agent'], NULL, 
     CURRENT_DATE, p_organization_id, p_created_by),
    ('Skill Matching Priority', 'skills', 'preferred', 
     jsonb_build_object(
         'prefer_exact_match', true,
         'allow_skill_development', true,
         'minimum_skill_level', 3
     ),
     10.0, ARRAY['agent'], ARRAY['technical_support', 'specialized_support'], 
     CURRENT_DATE, p_organization_id, p_created_by);
    
    v_count := 4;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- MIGRATION FUNCTIONS FROM JSONB STUBS

-- Function to migrate existing JSONB schedule data to new schema
CREATE OR REPLACE FUNCTION migrate_schedule_data_from_jsonb() RETURNS INTEGER AS $$
DECLARE
    v_migrated_count INTEGER := 0;
    v_schedule_record RECORD;
    v_new_schedule_id UUID;
    v_period_id UUID;
BEGIN
    -- Create a default schedule period if none exists
    IF NOT EXISTS (SELECT 1 FROM schedule_periods LIMIT 1) THEN
        INSERT INTO schedule_periods (
            period_name, period_type, start_date, end_date, 
            organization_id, created_by
        ) VALUES (
            'Migration Period', 'monthly', 
            DATE_TRUNC('month', CURRENT_DATE),
            DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
            (SELECT id FROM organizations LIMIT 1),
            (SELECT id FROM users LIMIT 1)
        )
        RETURNING id INTO v_period_id;
    ELSE
        SELECT id INTO v_period_id FROM schedule_periods ORDER BY created_at DESC LIMIT 1;
    END IF;
    
    -- Migrate schedule data from agents table if it has schedule_data JSONB column
    FOR v_schedule_record IN 
        SELECT a.id as agent_id, a.schedule_data, a.organization_id
        FROM agents a
        WHERE a.schedule_data IS NOT NULL 
        AND jsonb_typeof(a.schedule_data) = 'object'
    LOOP
        -- Create work schedule from JSONB data
        v_new_schedule_id := uuid_generate_v4();
        
        INSERT INTO work_schedules (
            id, agent_id, schedule_period_id, schedule_name,
            schedule_data, shift_assignments, total_hours,
            status, effective_date, organization_id, created_by
        ) VALUES (
            v_new_schedule_id,
            v_schedule_record.agent_id,
            v_period_id,
            'Migrated Schedule',
            v_schedule_record.schedule_data,
            COALESCE(v_schedule_record.schedule_data->'shifts', '[]'::jsonb),
            COALESCE((v_schedule_record.schedule_data->>'total_hours')::DECIMAL, 40.0),
            'active',
            CURRENT_DATE,
            v_schedule_record.organization_id,
            (SELECT id FROM users LIMIT 1)
        );
        
        v_migrated_count := v_migrated_count + 1;
    END LOOP;
    
    RETURN v_migrated_count;
END;
$$ LANGUAGE plpgsql;

-- CALENDAR AND TIMELINE DISPLAY SUPPORT

-- View for calendar display
CREATE VIEW schedule_calendar_view AS
SELECT 
    ws.id as schedule_id,
    ws.agent_id,
    a.name as agent_name,
    ws.effective_date as schedule_date,
    sd.shift_name,
    sd.start_time,
    sd.end_time,
    sd.color_code,
    sd.shift_type,
    ws.total_hours,
    ws.status,
    ws.organization_id,
    COALESCE(
        (SELECT jsonb_agg(
            jsonb_build_object(
                'type', bs.break_type,
                'start', bs.scheduled_start,
                'end', bs.scheduled_end,
                'duration', bs.duration_minutes,
                'status', bs.status
            )
        )
        FROM break_schedules bs
        WHERE bs.schedule_id = ws.id
        ), '[]'::jsonb
    ) as breaks,
    COALESCE(
        (SELECT jsonb_agg(
            jsonb_build_object(
                'type', sc.conflict_type,
                'severity', sc.severity,
                'description', sc.conflict_description
            )
        )
        FROM schedule_conflicts sc
        WHERE sc.schedule_id = ws.id
        AND sc.resolution_status = 'open'
        ), '[]'::jsonb
    ) as conflicts
FROM work_schedules ws
JOIN agents a ON ws.agent_id = a.id
LEFT JOIN shift_definitions sd ON (ws.schedule_data->>'shift_id')::UUID = sd.id
WHERE ws.status IN ('approved', 'published', 'active');

-- View for timeline display
CREATE VIEW schedule_timeline_view AS
SELECT 
    sp.id as period_id,
    sp.period_name,
    sp.start_date,
    sp.end_date,
    sc.coverage_date,
    sc.time_slot,
    sc.duration_minutes,
    sc.required_coverage,
    sc.actual_coverage,
    sc.coverage_percentage,
    sc.skill_requirements,
    sc.skill_coverage,
    CASE 
        WHEN sc.coverage_percentage >= 100 THEN 'adequate'
        WHEN sc.coverage_percentage >= 80 THEN 'warning'
        ELSE 'critical'
    END as coverage_status,
    sp.organization_id
FROM schedule_periods sp
JOIN schedule_coverage sc ON sp.id = sc.schedule_period_id
WHERE sp.status IN ('approved', 'published');

-- MULTI-SKILL SCHEDULING SUPPORT

-- Function to check skill coverage for schedule
CREATE OR REPLACE FUNCTION check_skill_coverage(
    p_schedule_id UUID,
    p_required_skills JSONB
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB := '{}';
    v_agent_skills TEXT[];
    v_skill TEXT;
    v_coverage_met BOOLEAN := true;
BEGIN
    -- Get agent skills for this schedule
    SELECT a.skills INTO v_agent_skills
    FROM work_schedules ws
    JOIN agents a ON ws.agent_id = a.id
    WHERE ws.id = p_schedule_id;
    
    -- Check each required skill
    FOR v_skill IN SELECT jsonb_array_elements_text(p_required_skills)
    LOOP
        IF v_skill = ANY(v_agent_skills) THEN
            v_result := v_result || jsonb_build_object(v_skill, jsonb_build_object(
                'covered', true,
                'agent_qualified', true
            ));
        ELSE
            v_result := v_result || jsonb_build_object(v_skill, jsonb_build_object(
                'covered', false,
                'agent_qualified', false
            ));
            v_coverage_met := false;
        END IF;
    END LOOP;
    
    v_result := v_result || jsonb_build_object(
        'overall_coverage', v_coverage_met,
        'coverage_percentage', 
        CASE 
            WHEN jsonb_array_length(p_required_skills) = 0 THEN 100
            ELSE (
                SELECT COUNT(*)::DECIMAL / jsonb_array_length(p_required_skills) * 100
                FROM jsonb_array_elements_text(p_required_skills) skill
                WHERE skill = ANY(v_agent_skills)
            )
        END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to find agents with required skills for scheduling
CREATE OR REPLACE FUNCTION find_agents_with_skills(
    p_organization_id UUID,
    p_required_skills TEXT[],
    p_schedule_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    agent_id UUID,
    agent_name VARCHAR(255),
    skills_match TEXT[],
    skill_coverage_percentage DECIMAL(5,2),
    availability_status VARCHAR(50),
    current_schedule_conflicts INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        ARRAY(SELECT unnest(a.skills) INTERSECT SELECT unnest(p_required_skills)) as skills_match,
        CASE 
            WHEN array_length(p_required_skills, 1) = 0 THEN 100.0
            ELSE (
                SELECT COUNT(*)::DECIMAL / array_length(p_required_skills, 1) * 100
                FROM unnest(a.skills) skill
                WHERE skill = ANY(p_required_skills)
            )
        END as skill_coverage_percentage,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM work_schedules ws 
                WHERE ws.agent_id = a.id 
                AND ws.effective_date = p_schedule_date
                AND ws.status IN ('approved', 'published', 'active')
            ) THEN 'scheduled'
            WHEN EXISTS (
                SELECT 1 FROM schedule_constraints sc
                WHERE sc.agent_id = a.id
                AND sc.is_active = true
                AND p_schedule_date BETWEEN sc.valid_from AND COALESCE(sc.valid_to, '9999-12-31'::DATE)
                AND sc.constraint_type = 'restriction'
            ) THEN 'restricted'
            ELSE 'available'
        END as availability_status,
        COALESCE((
            SELECT COUNT(*)::INTEGER
            FROM schedule_conflicts sc
            JOIN work_schedules ws ON sc.schedule_id = ws.id
            WHERE ws.agent_id = a.id
            AND ws.effective_date = p_schedule_date
            AND sc.resolution_status = 'open'
        ), 0) as current_schedule_conflicts
    FROM agents a
    WHERE a.organization_id = p_organization_id
    AND a.is_active = true
    AND (
        p_required_skills IS NULL 
        OR a.skills && p_required_skills  -- Has at least one required skill
    )
    ORDER BY skill_coverage_percentage DESC, availability_status;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic updates
CREATE OR REPLACE FUNCTION update_schedule_coverage_on_schedule_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Update coverage analysis when schedule changes
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Recalculate coverage for the affected date
        DELETE FROM schedule_coverage 
        WHERE schedule_period_id = NEW.schedule_period_id
        AND coverage_date = NEW.effective_date;
        
        -- This would trigger a background job to recalculate coverage
        -- For now, we'll just log the need for recalculation
        INSERT INTO schedule_changes (
            schedule_id, change_type, change_category, 
            change_reason, changed_by
        ) VALUES (
            NEW.id, 'coverage_update', 'system',
            'Schedule change triggered coverage recalculation',
            NEW.created_by
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_schedule_coverage_update
    AFTER INSERT OR UPDATE ON work_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_coverage_on_schedule_change();

-- Create trigger for automatic conflict detection
CREATE OR REPLACE FUNCTION detect_conflicts_on_schedule_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Detect conflicts when schedule is created or updated
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Call conflict detection function
        INSERT INTO schedule_conflicts (
            schedule_id, conflict_type, severity, 
            conflict_description, suggested_resolution
        )
        SELECT 
            NEW.id,
            conflict_type,
            severity,
            description,
            suggested_resolution
        FROM detect_schedule_conflicts(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_conflict_detection
    AFTER INSERT OR UPDATE ON work_schedules
    FOR EACH ROW
    EXECUTE FUNCTION detect_conflicts_on_schedule_change();

-- Final comment
COMMENT ON SCHEMA public IS 'Schedule Management Schema v1.0 - Complete scheduling system with 15 tables for UI-OPUS workforce planning integration';