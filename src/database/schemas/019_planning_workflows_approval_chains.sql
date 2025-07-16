-- =============================================================================
-- 019_planning_workflows_approval_chains.sql
-- EXACT BDD Implementation: Planning Workflows and Approval Chains
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: Planning module detailed workflows with multi-level approval chains
-- Purpose: Comprehensive planning workflow management with version control and approval chains
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. PLANNING WORKFLOWS
-- =============================================================================

-- Planning workflow definitions and management
CREATE TABLE planning_workflows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id VARCHAR(50) NOT NULL UNIQUE,
    workflow_name VARCHAR(200) NOT NULL,
    workflow_description TEXT,
    
    -- Workflow classification
    workflow_type VARCHAR(30) NOT NULL CHECK (workflow_type IN (
        'schedule_planning', 'forecast_planning', 'capacity_planning', 
        'vacation_planning', 'shift_planning', 'resource_planning'
    )),
    workflow_category VARCHAR(30) DEFAULT 'operational' CHECK (workflow_category IN (
        'operational', 'strategic', 'tactical', 'administrative'
    )),
    
    -- Workflow scope and timing
    planning_horizon_days INTEGER NOT NULL,
    planning_frequency VARCHAR(20) NOT NULL CHECK (planning_frequency IN (
        'daily', 'weekly', 'bi_weekly', 'monthly', 'quarterly', 'annual'
    )),
    advance_planning_days INTEGER DEFAULT 14,
    
    -- Workflow stages and participants
    workflow_stages JSONB NOT NULL, -- Ordered list of stages
    participant_roles JSONB NOT NULL, -- Roles involved in planning
    approval_chain_required BOOLEAN DEFAULT true,
    parallel_processing_allowed BOOLEAN DEFAULT false,
    
    -- Planning constraints
    business_rules JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    mandatory_inputs JSONB DEFAULT '[]',
    optional_inputs JSONB DEFAULT '[]',
    
    -- Workflow behavior
    auto_progression_enabled BOOLEAN DEFAULT false,
    timeout_escalation_enabled BOOLEAN DEFAULT true,
    rollback_supported BOOLEAN DEFAULT true,
    emergency_override_allowed BOOLEAN DEFAULT false,
    
    -- Integration points
    data_sources JSONB DEFAULT '[]', -- External data sources
    output_destinations JSONB DEFAULT '[]', -- Where results go
    api_integrations JSONB DEFAULT '{}',
    
    -- Workflow status
    is_active BOOLEAN DEFAULT true,
    is_template BOOLEAN DEFAULT false,
    version VARCHAR(20) DEFAULT '1.0',
    
    -- Metadata
    created_by UUID NOT NULL,
    approved_by UUID,
    last_modified_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (last_modified_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 2. PLANNING VERSIONS
-- =============================================================================

-- Planning version management and iteration tracking
CREATE TABLE planning_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_id VARCHAR(50) NOT NULL UNIQUE,
    workflow_id VARCHAR(50) NOT NULL,
    
    -- Version identification
    version_number VARCHAR(20) NOT NULL,
    version_name VARCHAR(200),
    version_description TEXT,
    
    -- Version scope and period
    planning_period_start DATE NOT NULL,
    planning_period_end DATE NOT NULL,
    version_scope VARCHAR(30) NOT NULL CHECK (version_scope IN (
        'full_period', 'partial_period', 'department', 'location', 'skill_group'
    )),
    affected_entities JSONB DEFAULT '{}', -- Departments, locations, etc.
    
    -- Version status and lifecycle
    version_status VARCHAR(20) DEFAULT 'draft' CHECK (version_status IN (
        'draft', 'in_review', 'approved', 'published', 'active', 'superseded', 'archived'
    )),
    is_baseline_version BOOLEAN DEFAULT false,
    is_current_active BOOLEAN DEFAULT false,
    
    -- Version relationships
    parent_version_id VARCHAR(50),
    baseline_version_id VARCHAR(50),
    supersedes_version_id VARCHAR(50),
    
    -- Planning data
    planning_data JSONB NOT NULL, -- Core planning content
    planning_assumptions JSONB DEFAULT '{}',
    scenario_parameters JSONB DEFAULT '{}',
    
    -- Version metrics
    coverage_percentage DECIMAL(5,2),
    confidence_score DECIMAL(3,2),
    variance_from_baseline DECIMAL(5,2),
    quality_score DECIMAL(3,2),
    
    -- Approval tracking
    requires_approval BOOLEAN DEFAULT true,
    approval_level_required INTEGER DEFAULT 1,
    current_approval_level INTEGER DEFAULT 0,
    
    -- Timing and performance
    planning_start_time TIMESTAMP WITH TIME ZONE,
    planning_completion_time TIMESTAMP WITH TIME ZONE,
    total_planning_hours DECIMAL(6,2),
    
    -- Change tracking
    change_summary TEXT,
    change_impact_assessment JSONB DEFAULT '{}',
    rollback_data JSONB DEFAULT '{}',
    
    -- Metadata
    created_by UUID NOT NULL,
    locked_by UUID,
    lock_timestamp TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (workflow_id) REFERENCES planning_workflows(workflow_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_version_id) REFERENCES planning_versions(version_id) ON DELETE SET NULL,
    FOREIGN KEY (baseline_version_id) REFERENCES planning_versions(version_id) ON DELETE SET NULL,
    FOREIGN KEY (supersedes_version_id) REFERENCES planning_versions(version_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (locked_by) REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Ensure valid date range
    CHECK (planning_period_end >= planning_period_start)
);

-- =============================================================================
-- 3. APPROVAL CHAINS
-- =============================================================================

-- Multi-level approval chain definitions
CREATE TABLE approval_chains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chain_id VARCHAR(50) NOT NULL UNIQUE,
    chain_name VARCHAR(200) NOT NULL,
    chain_description TEXT,
    
    -- Chain scope and applicability
    applies_to_workflow_types JSONB NOT NULL, -- Which workflow types use this chain
    applies_to_departments JSONB DEFAULT '[]',
    applies_to_locations JSONB DEFAULT '[]',
    applies_to_value_thresholds JSONB DEFAULT '{}',
    
    -- Chain structure
    approval_levels JSONB NOT NULL, -- Ordered approval levels
    total_levels INTEGER NOT NULL,
    parallel_approval_levels JSONB DEFAULT '[]', -- Which levels can be parallel
    
    -- Chain behavior
    requires_sequential_approval BOOLEAN DEFAULT true,
    allows_level_skipping BOOLEAN DEFAULT false,
    allows_delegation BOOLEAN DEFAULT true,
    emergency_bypass_allowed BOOLEAN DEFAULT false,
    
    -- Approval criteria
    unanimous_required_levels JSONB DEFAULT '[]',
    majority_sufficient_levels JSONB DEFAULT '[]',
    quorum_requirements JSONB DEFAULT '{}',
    
    -- Timeout and escalation
    level_timeout_hours JSONB DEFAULT '{}', -- Timeout per level
    escalation_rules JSONB DEFAULT '{}',
    auto_approval_conditions JSONB DEFAULT '{}',
    
    -- Chain status
    is_active BOOLEAN DEFAULT true,
    is_default_chain BOOLEAN DEFAULT false,
    
    -- Metadata
    created_by UUID NOT NULL,
    approved_by UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 4. PLANNING APPROVAL INSTANCES
-- =============================================================================

-- Active approval instances for planning versions
CREATE TABLE planning_approval_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id VARCHAR(50) NOT NULL UNIQUE,
    version_id VARCHAR(50) NOT NULL,
    chain_id VARCHAR(50) NOT NULL,
    
    -- Approval instance status
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN (
        'pending', 'in_progress', 'approved', 'rejected', 'cancelled', 'escalated'
    )),
    current_approval_level INTEGER DEFAULT 1,
    
    -- Instance timeline
    approval_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approval_completed_at TIMESTAMP WITH TIME ZONE,
    total_approval_time_hours DECIMAL(6,2),
    
    -- Approval participants
    initiated_by UUID NOT NULL,
    current_approvers JSONB DEFAULT '[]',
    completed_approvers JSONB DEFAULT '[]',
    pending_approvers JSONB DEFAULT '[]',
    
    -- Approval data
    approval_request_data JSONB DEFAULT '{}',
    supporting_documents JSONB DEFAULT '[]',
    approval_comments JSONB DEFAULT '[]',
    
    -- Business context
    business_justification TEXT,
    impact_assessment JSONB DEFAULT '{}',
    risk_assessment JSONB DEFAULT '{}',
    
    -- Approval results
    final_decision VARCHAR(20),
    decision_rationale TEXT,
    conditional_approvals JSONB DEFAULT '[]',
    
    -- Emergency and escalation
    emergency_approval_used BOOLEAN DEFAULT false,
    escalation_count INTEGER DEFAULT 0,
    escalation_history JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (version_id) REFERENCES planning_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (chain_id) REFERENCES approval_chains(chain_id) ON DELETE RESTRICT,
    FOREIGN KEY (initiated_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 5. APPROVAL LEVEL RESPONSES
-- =============================================================================

-- Individual approval responses at each level
CREATE TABLE approval_level_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id VARCHAR(50) NOT NULL UNIQUE,
    instance_id VARCHAR(50) NOT NULL,
    
    -- Approval level details
    approval_level INTEGER NOT NULL,
    approver_id UUID NOT NULL,
    approver_role VARCHAR(100),
    
    -- Response details
    response_type VARCHAR(20) NOT NULL CHECK (response_type IN (
        'approve', 'reject', 'conditional_approve', 'request_changes', 'delegate'
    )),
    response_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Response content
    response_comments TEXT,
    conditions JSONB DEFAULT '[]',
    requested_changes JSONB DEFAULT '[]',
    supporting_documents JSONB DEFAULT '[]',
    
    -- Delegation (if applicable)
    delegated_to UUID,
    delegation_reason TEXT,
    delegation_scope JSONB DEFAULT '{}',
    
    -- Response metadata
    response_method VARCHAR(30) DEFAULT 'manual' CHECK (response_method IN (
        'manual', 'automatic', 'delegated', 'escalated'
    )),
    confidence_level VARCHAR(20) DEFAULT 'high',
    
    -- Impact assessment by approver
    approver_risk_assessment JSONB DEFAULT '{}',
    business_impact_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (instance_id) REFERENCES planning_approval_instances(instance_id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (delegated_to) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. PLANNING CYCLES
-- =============================================================================

-- Planning cycle management and scheduling
CREATE TABLE planning_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_id VARCHAR(50) NOT NULL UNIQUE,
    cycle_name VARCHAR(200) NOT NULL,
    
    -- Cycle definition
    workflow_id VARCHAR(50) NOT NULL,
    cycle_type VARCHAR(30) NOT NULL CHECK (cycle_type IN (
        'regular', 'ad_hoc', 'emergency', 'revision', 'adjustment'
    )),
    
    -- Cycle timeline
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE NOT NULL,
    planning_cutoff_date DATE NOT NULL,
    approval_deadline DATE NOT NULL,
    implementation_date DATE NOT NULL,
    
    -- Cycle scope
    planning_scope VARCHAR(30) NOT NULL CHECK (planning_scope IN (
        'full_organization', 'department', 'location', 'skill_group', 'project'
    )),
    scope_entities JSONB DEFAULT '{}',
    
    -- Cycle parameters
    planning_assumptions JSONB DEFAULT '{}',
    business_constraints JSONB DEFAULT '{}',
    success_criteria JSONB DEFAULT '{}',
    
    -- Cycle status
    cycle_status VARCHAR(20) DEFAULT 'planned' CHECK (cycle_status IN (
        'planned', 'active', 'in_approval', 'approved', 'implemented', 'completed', 'cancelled'
    )),
    
    -- Cycle participants
    cycle_owner UUID NOT NULL,
    planning_team JSONB DEFAULT '[]',
    stakeholders JSONB DEFAULT '[]',
    
    -- Cycle results
    planning_accuracy DECIMAL(5,2),
    approval_efficiency DECIMAL(5,2),
    implementation_success DECIMAL(5,2),
    lessons_learned JSONB DEFAULT '[]',
    
    -- Change management
    change_requests JSONB DEFAULT '[]',
    adjustments_made JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (workflow_id) REFERENCES planning_workflows(workflow_id) ON DELETE RESTRICT,
    FOREIGN KEY (cycle_owner) REFERENCES employees(id) ON DELETE RESTRICT,
    
    -- Ensure logical date sequence
    CHECK (cycle_end_date >= cycle_start_date),
    CHECK (planning_cutoff_date <= approval_deadline),
    CHECK (approval_deadline <= implementation_date)
);

-- =============================================================================
-- 7. WORKFLOW STAGE EXECUTIONS
-- =============================================================================

-- Execution tracking for workflow stages
CREATE TABLE workflow_stage_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id VARCHAR(50) NOT NULL UNIQUE,
    version_id VARCHAR(50) NOT NULL,
    cycle_id VARCHAR(50) NOT NULL,
    
    -- Stage identification
    stage_name VARCHAR(200) NOT NULL,
    stage_order INTEGER NOT NULL,
    stage_type VARCHAR(30) NOT NULL CHECK (stage_type IN (
        'data_collection', 'analysis', 'planning', 'review', 'approval', 'implementation'
    )),
    
    -- Stage execution
    execution_status VARCHAR(20) DEFAULT 'pending' CHECK (execution_status IN (
        'pending', 'in_progress', 'completed', 'failed', 'skipped', 'cancelled'
    )),
    
    -- Stage timeline
    planned_start_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    planned_end_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    
    -- Stage participants
    assigned_to UUID,
    participants JSONB DEFAULT '[]',
    responsible_role VARCHAR(100),
    
    -- Stage data and results
    input_data JSONB DEFAULT '{}',
    output_data JSONB DEFAULT '{}',
    stage_metrics JSONB DEFAULT '{}',
    quality_checks JSONB DEFAULT '{}',
    
    -- Stage issues and resolution
    issues_encountered JSONB DEFAULT '[]',
    resolution_actions JSONB DEFAULT '[]',
    escalations JSONB DEFAULT '[]',
    
    -- Performance tracking
    planned_effort_hours DECIMAL(6,2),
    actual_effort_hours DECIMAL(6,2),
    efficiency_score DECIMAL(3,2),
    quality_score DECIMAL(3,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (version_id) REFERENCES planning_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (cycle_id) REFERENCES planning_cycles(cycle_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 8. PLANNING DEPENDENCIES
-- =============================================================================

-- Dependencies between planning elements
CREATE TABLE planning_dependencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dependency_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Dependency relationship
    source_version_id VARCHAR(50) NOT NULL,
    target_version_id VARCHAR(50) NOT NULL,
    dependency_type VARCHAR(30) NOT NULL CHECK (dependency_type IN (
        'prerequisite', 'blocks', 'influences', 'synchronizes', 'validates'
    )),
    
    -- Dependency details
    dependency_description TEXT,
    dependency_strength VARCHAR(20) DEFAULT 'strong' CHECK (dependency_strength IN (
        'weak', 'medium', 'strong', 'critical'
    )),
    
    -- Dependency conditions
    trigger_conditions JSONB DEFAULT '{}',
    satisfaction_criteria JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    
    -- Dependency status
    dependency_status VARCHAR(20) DEFAULT 'active' CHECK (dependency_status IN (
        'active', 'satisfied', 'violated', 'inactive', 'obsolete'
    )),
    last_check_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Impact assessment
    impact_on_timeline BOOLEAN DEFAULT false,
    impact_on_quality BOOLEAN DEFAULT false,
    impact_on_resources BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (source_version_id) REFERENCES planning_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (target_version_id) REFERENCES planning_versions(version_id) ON DELETE CASCADE,
    
    -- Prevent self-dependencies
    CHECK (source_version_id != target_version_id)
);

-- =============================================================================
-- 9. PLANNING PERFORMANCE METRICS
-- =============================================================================

-- Performance metrics for planning processes
CREATE TABLE planning_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Metric scope
    measurement_date DATE NOT NULL,
    workflow_id VARCHAR(50),
    cycle_id VARCHAR(50),
    department VARCHAR(100),
    
    -- Planning efficiency metrics
    average_planning_time_hours DECIMAL(8,2),
    planning_accuracy_percentage DECIMAL(5,2),
    first_time_approval_rate DECIMAL(5,2),
    revision_cycles_average DECIMAL(4,1),
    
    -- Approval efficiency metrics
    average_approval_time_hours DECIMAL(8,2),
    approval_bottleneck_levels JSONB DEFAULT '[]',
    escalation_rate_percentage DECIMAL(5,2),
    unanimous_approval_rate DECIMAL(5,2),
    
    -- Quality metrics
    planning_quality_score DECIMAL(3,2),
    stakeholder_satisfaction_score DECIMAL(3,2),
    implementation_success_rate DECIMAL(5,2),
    variance_from_plan_percentage DECIMAL(5,2),
    
    -- Resource utilization
    planner_utilization_percentage DECIMAL(5,2),
    approver_utilization_percentage DECIMAL(5,2),
    resource_efficiency_score DECIMAL(3,2),
    
    -- Business impact
    cost_effectiveness_score DECIMAL(3,2),
    business_value_delivered DECIMAL(10,2),
    roi_percentage DECIMAL(5,2),
    
    -- Improvement opportunities
    identified_bottlenecks JSONB DEFAULT '[]',
    optimization_recommendations JSONB DEFAULT '[]',
    automation_opportunities JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (workflow_id) REFERENCES planning_workflows(workflow_id) ON DELETE SET NULL,
    FOREIGN KEY (cycle_id) REFERENCES planning_cycles(cycle_id) ON DELETE SET NULL
);

-- =============================================================================
-- 10. PLANNING NOTIFICATIONS
-- =============================================================================

-- Notifications for planning workflow events
CREATE TABLE planning_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Notification context
    workflow_id VARCHAR(50),
    version_id VARCHAR(50),
    instance_id VARCHAR(50),
    cycle_id VARCHAR(50),
    
    -- Notification details
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN (
        'planning_started', 'stage_completed', 'approval_required', 'deadline_approaching',
        'escalation_triggered', 'planning_completed', 'changes_required'
    )),
    notification_priority VARCHAR(20) DEFAULT 'medium' CHECK (notification_priority IN (
        'low', 'medium', 'high', 'urgent'
    )),
    
    -- Notification content
    notification_title VARCHAR(200) NOT NULL,
    notification_message TEXT NOT NULL,
    action_required TEXT,
    deadline TIMESTAMP WITH TIME ZONE,
    
    -- Notification recipients
    recipient_id UUID NOT NULL,
    recipient_type VARCHAR(20) DEFAULT 'user' CHECK (recipient_type IN (
        'user', 'role', 'team', 'department'
    )),
    
    -- Delivery details
    delivery_channels JSONB DEFAULT '["system"]',
    delivery_status VARCHAR(20) DEFAULT 'pending' CHECK (delivery_status IN (
        'pending', 'sent', 'delivered', 'read', 'failed'
    )),
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Notification response
    response_required BOOLEAN DEFAULT false,
    response_received BOOLEAN DEFAULT false,
    response_data JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (workflow_id) REFERENCES planning_workflows(workflow_id) ON DELETE SET NULL,
    FOREIGN KEY (version_id) REFERENCES planning_versions(version_id) ON DELETE SET NULL,
    FOREIGN KEY (instance_id) REFERENCES planning_approval_instances(instance_id) ON DELETE SET NULL,
    FOREIGN KEY (cycle_id) REFERENCES planning_cycles(cycle_id) ON DELETE SET NULL,
    FOREIGN KEY (recipient_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Planning workflows queries
CREATE INDEX idx_planning_workflows_type ON planning_workflows(workflow_type);
CREATE INDEX idx_planning_workflows_active ON planning_workflows(is_active) WHERE is_active = true;
CREATE INDEX idx_planning_workflows_frequency ON planning_workflows(planning_frequency);

-- Planning versions queries
CREATE INDEX idx_planning_versions_workflow ON planning_versions(workflow_id);
CREATE INDEX idx_planning_versions_status ON planning_versions(version_status);
CREATE INDEX idx_planning_versions_period ON planning_versions(planning_period_start, planning_period_end);
CREATE INDEX idx_planning_versions_current ON planning_versions(is_current_active) WHERE is_current_active = true;
CREATE INDEX idx_planning_versions_baseline ON planning_versions(is_baseline_version) WHERE is_baseline_version = true;

-- Approval chains queries
CREATE INDEX idx_approval_chains_active ON approval_chains(is_active) WHERE is_active = true;
CREATE INDEX idx_approval_chains_default ON approval_chains(is_default_chain) WHERE is_default_chain = true;

-- Planning approval instances queries
CREATE INDEX idx_planning_approval_instances_version ON planning_approval_instances(version_id);
CREATE INDEX idx_planning_approval_instances_chain ON planning_approval_instances(chain_id);
CREATE INDEX idx_planning_approval_instances_status ON planning_approval_instances(approval_status);
CREATE INDEX idx_planning_approval_instances_level ON planning_approval_instances(current_approval_level);
CREATE INDEX idx_planning_approval_instances_initiated ON planning_approval_instances(initiated_by);

-- Approval level responses queries
CREATE INDEX idx_approval_level_responses_instance ON approval_level_responses(instance_id);
CREATE INDEX idx_approval_level_responses_approver ON approval_level_responses(approver_id);
CREATE INDEX idx_approval_level_responses_level ON approval_level_responses(approval_level);
CREATE INDEX idx_approval_level_responses_type ON approval_level_responses(response_type);

-- Planning cycles queries
CREATE INDEX idx_planning_cycles_workflow ON planning_cycles(workflow_id);
CREATE INDEX idx_planning_cycles_status ON planning_cycles(cycle_status);
CREATE INDEX idx_planning_cycles_dates ON planning_cycles(cycle_start_date, cycle_end_date);
CREATE INDEX idx_planning_cycles_owner ON planning_cycles(cycle_owner);

-- Workflow stage executions queries
CREATE INDEX idx_workflow_stage_executions_version ON workflow_stage_executions(version_id);
CREATE INDEX idx_workflow_stage_executions_cycle ON workflow_stage_executions(cycle_id);
CREATE INDEX idx_workflow_stage_executions_status ON workflow_stage_executions(execution_status);
CREATE INDEX idx_workflow_stage_executions_assigned ON workflow_stage_executions(assigned_to);

-- Planning dependencies queries
CREATE INDEX idx_planning_dependencies_source ON planning_dependencies(source_version_id);
CREATE INDEX idx_planning_dependencies_target ON planning_dependencies(target_version_id);
CREATE INDEX idx_planning_dependencies_type ON planning_dependencies(dependency_type);
CREATE INDEX idx_planning_dependencies_status ON planning_dependencies(dependency_status);

-- Planning performance metrics queries
CREATE INDEX idx_planning_performance_metrics_date ON planning_performance_metrics(measurement_date);
CREATE INDEX idx_planning_performance_metrics_workflow ON planning_performance_metrics(workflow_id);
CREATE INDEX idx_planning_performance_metrics_cycle ON planning_performance_metrics(cycle_id);

-- Planning notifications queries
CREATE INDEX idx_planning_notifications_recipient ON planning_notifications(recipient_id);
CREATE INDEX idx_planning_notifications_type ON planning_notifications(notification_type);
CREATE INDEX idx_planning_notifications_status ON planning_notifications(delivery_status);
CREATE INDEX idx_planning_notifications_deadline ON planning_notifications(deadline) WHERE deadline IS NOT NULL;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_planning_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER planning_workflows_update_trigger
    BEFORE UPDATE ON planning_workflows
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER planning_versions_update_trigger
    BEFORE UPDATE ON planning_versions
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER approval_chains_update_trigger
    BEFORE UPDATE ON approval_chains
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER planning_approval_instances_update_trigger
    BEFORE UPDATE ON planning_approval_instances
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER planning_cycles_update_trigger
    BEFORE UPDATE ON planning_cycles
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER workflow_stage_executions_update_trigger
    BEFORE UPDATE ON workflow_stage_executions
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

CREATE TRIGGER planning_dependencies_update_trigger
    BEFORE UPDATE ON planning_dependencies
    FOR EACH ROW EXECUTE FUNCTION update_planning_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active planning approval summary
CREATE VIEW v_active_planning_approvals AS
SELECT 
    pai.instance_id,
    pv.version_name,
    pw.workflow_name,
    pai.approval_status,
    pai.current_approval_level,
    ac.total_levels,
    e.full_name as initiated_by_name,
    pai.approval_started_at,
    COUNT(alr.id) as responses_received
FROM planning_approval_instances pai
JOIN planning_versions pv ON pai.version_id = pv.version_id
JOIN planning_workflows pw ON pv.workflow_id = pw.workflow_id
JOIN approval_chains ac ON pai.chain_id = ac.chain_id
JOIN employees e ON pai.initiated_by = e.id
LEFT JOIN approval_level_responses alr ON pai.instance_id = alr.instance_id
WHERE pai.approval_status IN ('pending', 'in_progress')
GROUP BY pai.instance_id, pv.version_name, pw.workflow_name, pai.approval_status, 
         pai.current_approval_level, ac.total_levels, e.full_name, pai.approval_started_at
ORDER BY pai.approval_started_at ASC;

-- Planning cycle performance summary
CREATE VIEW v_planning_cycle_performance AS
SELECT 
    pc.cycle_id,
    pc.cycle_name,
    pw.workflow_name,
    pc.cycle_status,
    pc.planning_accuracy,
    pc.approval_efficiency,
    pc.implementation_success,
    COUNT(pv.id) as total_versions,
    COUNT(CASE WHEN pv.version_status = 'approved' THEN 1 END) as approved_versions,
    AVG(pai.total_approval_time_hours) as avg_approval_time_hours
FROM planning_cycles pc
JOIN planning_workflows pw ON pc.workflow_id = pw.workflow_id
LEFT JOIN planning_versions pv ON pw.workflow_id = pv.workflow_id
LEFT JOIN planning_approval_instances pai ON pv.version_id = pai.version_id
WHERE pc.cycle_start_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY pc.cycle_id, pc.cycle_name, pw.workflow_name, pc.cycle_status,
         pc.planning_accuracy, pc.approval_efficiency, pc.implementation_success
ORDER BY pc.cycle_start_date DESC;

-- User approval workload summary
CREATE VIEW v_user_approval_workload AS
SELECT 
    e.id as user_id,
    e.full_name,
    COUNT(CASE WHEN pai.approval_status = 'pending' AND pai.current_approval_level = alr.approval_level THEN 1 END) as pending_approvals,
    COUNT(CASE WHEN alr.response_timestamp >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_responses,
    AVG(EXTRACT(EPOCH FROM (alr.response_timestamp - pai.approval_started_at))/3600) as avg_response_time_hours,
    COUNT(CASE WHEN alr.response_type = 'approve' THEN 1 END) as total_approvals,
    COUNT(CASE WHEN alr.response_type = 'reject' THEN 1 END) as total_rejections
FROM employees e
LEFT JOIN approval_level_responses alr ON e.id = alr.approver_id
LEFT JOIN planning_approval_instances pai ON alr.instance_id = pai.instance_id
GROUP BY e.id, e.full_name
HAVING COUNT(alr.id) > 0
ORDER BY pending_approvals DESC, recent_responses DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING (Planning cycles with approvals)
-- =============================================================================

-- Insert sample planning workflows
INSERT INTO planning_workflows (workflow_id, workflow_name, workflow_type, planning_horizon_days, planning_frequency, workflow_stages, participant_roles, created_by) VALUES
('schedule_planning_wf', 'Weekly Schedule Planning Workflow', 'schedule_planning', 14, 'weekly',
'[{"stage": "data_collection", "order": 1}, {"stage": "analysis", "order": 2}, {"stage": "planning", "order": 3}, {"stage": "review", "order": 4}, {"stage": "approval", "order": 5}]',
'["planners", "supervisors", "managers"]',
(SELECT id FROM employees LIMIT 1)),
('capacity_planning_wf', 'Monthly Capacity Planning Workflow', 'capacity_planning', 30, 'monthly',
'[{"stage": "forecast_analysis", "order": 1}, {"stage": "capacity_modeling", "order": 2}, {"stage": "scenario_planning", "order": 3}, {"stage": "stakeholder_review", "order": 4}, {"stage": "executive_approval", "order": 5}]',
'["capacity_planners", "department_heads", "executives"]',
(SELECT id FROM employees LIMIT 1));

-- Insert sample approval chains
INSERT INTO approval_chains (chain_id, chain_name, applies_to_workflow_types, approval_levels, total_levels, created_by) VALUES
('standard_approval', 'Standard Three-Level Approval Chain', '["schedule_planning", "capacity_planning"]',
'[{"level": 1, "role": "supervisor", "timeout_hours": 24}, {"level": 2, "role": "manager", "timeout_hours": 48}, {"level": 3, "role": "director", "timeout_hours": 72}]',
3,
(SELECT id FROM employees LIMIT 1)),
('expedited_approval', 'Expedited Two-Level Approval Chain', '["schedule_planning"]',
'[{"level": 1, "role": "manager", "timeout_hours": 12}, {"level": 2, "role": "director", "timeout_hours": 24}]',
2,
(SELECT id FROM employees LIMIT 1));

-- Insert sample planning cycle
INSERT INTO planning_cycles (cycle_id, cycle_name, workflow_id, cycle_type, cycle_start_date, cycle_end_date, planning_cutoff_date, approval_deadline, implementation_date, planning_scope, cycle_owner) VALUES
('cycle_2025_01', 'January 2025 Planning Cycle', 'schedule_planning_wf', 'regular', '2025-01-01', '2025-01-07', '2025-01-05', '2025-01-06', '2025-01-07', 'full_organization',
(SELECT id FROM employees LIMIT 1));

-- Insert sample planning version
INSERT INTO planning_versions (version_id, workflow_id, version_number, version_name, planning_period_start, planning_period_end, version_scope, planning_data, created_by) VALUES
('version_2025_01_v1', 'schedule_planning_wf', '1.0', 'January 2025 Schedule V1', '2025-01-01', '2025-01-07', 'full_period',
'{"schedules": [{"employee": "emp1", "shifts": ["morning", "afternoon"]}, {"employee": "emp2", "shifts": ["afternoon", "evening"]}]}',
(SELECT id FROM employees LIMIT 1));

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE planning_workflows IS 'Planning workflow definitions with stages, participants, and business rules';
COMMENT ON TABLE planning_versions IS 'Planning version management with iteration tracking and approval status';
COMMENT ON TABLE approval_chains IS 'Multi-level approval chain definitions with timeout and escalation rules';
COMMENT ON TABLE planning_approval_instances IS 'Active approval instances for planning versions with participant tracking';
COMMENT ON TABLE approval_level_responses IS 'Individual approval responses at each level with delegation support';
COMMENT ON TABLE planning_cycles IS 'Planning cycle management with timeline and scope definition';
COMMENT ON TABLE workflow_stage_executions IS 'Execution tracking for workflow stages with performance metrics';
COMMENT ON TABLE planning_dependencies IS 'Dependencies between planning elements with impact assessment';
COMMENT ON TABLE planning_performance_metrics IS 'Performance metrics for planning processes and approval efficiency';
COMMENT ON TABLE planning_notifications IS 'Notifications for planning workflow events with multi-channel delivery';