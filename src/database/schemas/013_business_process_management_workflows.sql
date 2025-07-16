-- =============================================================================
-- 013_business_process_management_workflows.sql
-- EXACT BDD Implementation: Business Process Management and Workflow Automation
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 13-business-process-management-workflows.feature (271 lines)
-- Purpose: Comprehensive BPMS workflow automation with 1C ZUP integration
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. BUSINESS PROCESSES
-- =============================================================================

-- Business process definitions from BDD lines 11-22
CREATE TABLE business_processes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_id VARCHAR(50) NOT NULL UNIQUE,
    process_name VARCHAR(200) NOT NULL,
    process_description TEXT,
    
    -- Process definition from BDD lines 15-21
    process_version VARCHAR(20) DEFAULT '1.0',
    process_definition JSONB NOT NULL, -- Complete process structure
    
    -- Process components from BDD lines 16-21
    process_stages JSONB NOT NULL, -- Sequential workflow steps
    participant_roles JSONB NOT NULL, -- Role-based authorization
    available_actions JSONB NOT NULL, -- Stage-specific permissions
    transition_rules JSONB NOT NULL, -- Workflow logic
    notification_settings JSONB DEFAULT '{}', -- Communication automation
    
    -- Process classification
    process_type VARCHAR(30) NOT NULL CHECK (process_type IN (
        'schedule_approval', 'vacation_approval', 'shift_exchange', 
        'general_approval', 'emergency_override'
    )),
    process_category VARCHAR(30) DEFAULT 'approval' CHECK (process_category IN (
        'approval', 'notification', 'automation', 'integration', 'review'
    )),
    
    -- Process behavior
    requires_sequential_execution BOOLEAN DEFAULT true,
    supports_parallel_approval BOOLEAN DEFAULT false,
    allows_delegation BOOLEAN DEFAULT true,
    timeout_escalation_enabled BOOLEAN DEFAULT true,
    
    -- Integration configuration from BDD lines 233-271
    has_external_integration BOOLEAN DEFAULT false,
    integration_endpoints JSONB DEFAULT '{}',
    integration_error_handling JSONB DEFAULT '{}',
    
    -- Process status
    is_active BOOLEAN DEFAULT true,
    deployment_status VARCHAR(20) DEFAULT 'draft' CHECK (deployment_status IN (
        'draft', 'testing', 'active', 'deprecated', 'retired'
    )),
    
    -- Process metadata
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
-- 2. WORKFLOW STAGES
-- =============================================================================

-- Individual workflow stages from BDD lines 28-40, 83-95
CREATE TABLE workflow_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stage_id VARCHAR(50) NOT NULL UNIQUE,
    process_id VARCHAR(50) NOT NULL,
    stage_name VARCHAR(200) NOT NULL,
    stage_description TEXT,
    
    -- Stage positioning
    stage_order INTEGER NOT NULL,
    is_start_stage BOOLEAN DEFAULT false,
    is_end_stage BOOLEAN DEFAULT false,
    
    -- Stage participants from BDD lines 29-33, 84-88
    participant_roles JSONB NOT NULL, -- Who can participate
    required_participants JSONB DEFAULT '[]', -- Must participate
    optional_participants JSONB DEFAULT '[]', -- Can participate
    
    -- Stage actions from BDD lines 29-33, 51-59
    available_actions JSONB NOT NULL, -- Edit/Approve/Reject/Delegate
    default_action VARCHAR(30),
    
    -- Stage rules from BDD lines 34-39
    role_authorization_required BOOLEAN DEFAULT true,
    completion_requirements JSONB DEFAULT '{}',
    timeout_hours INTEGER DEFAULT 24,
    escalation_enabled BOOLEAN DEFAULT true,
    
    -- Parallel approval configuration from BDD lines 146-162
    parallel_approval_type VARCHAR(30) DEFAULT 'sequential' CHECK (parallel_approval_type IN (
        'sequential', 'all_must_approve', 'majority_approval', 
        'quorum_with_majority', 'any_can_approve'
    )),
    parallel_completion_criteria JSONB DEFAULT '{}',
    
    -- Stage behavior
    allows_comments BOOLEAN DEFAULT true,
    allows_attachments BOOLEAN DEFAULT true,
    allows_delegation BOOLEAN DEFAULT true,
    auto_advance_conditions JSONB DEFAULT '{}',
    
    -- Integration hooks from BDD lines 233-255
    has_integration_trigger BOOLEAN DEFAULT false,
    integration_config JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (process_id) REFERENCES business_processes(process_id) ON DELETE CASCADE,
    
    UNIQUE(process_id, stage_order)
);

-- =============================================================================
-- 3. PROCESS TRANSITIONS
-- =============================================================================

-- Stage transitions and routing logic from BDD lines 20, 28-40
CREATE TABLE process_transitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transition_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Transition definition
    source_stage_id VARCHAR(50) NOT NULL,
    target_stage_id VARCHAR(50) NOT NULL,
    transition_name VARCHAR(200) NOT NULL,
    
    -- Transition trigger from BDD lines 54-59
    trigger_action VARCHAR(30) NOT NULL CHECK (trigger_action IN (
        'approve', 'reject', 'delegate', 'request_info', 'timeout', 'escalate'
    )),
    
    -- Transition conditions
    transition_conditions JSONB DEFAULT '{}',
    requires_validation BOOLEAN DEFAULT true,
    validation_rules JSONB DEFAULT '{}',
    
    -- Transition behavior
    is_automatic BOOLEAN DEFAULT false,
    notification_required BOOLEAN DEFAULT true,
    update_object_status BOOLEAN DEFAULT true,
    
    -- Business rule enforcement from BDD lines 89-94
    business_rules JSONB DEFAULT '{}',
    validation_checks JSONB DEFAULT '{}',
    error_handling JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (source_stage_id) REFERENCES workflow_stages(stage_id) ON DELETE CASCADE,
    FOREIGN KEY (target_stage_id) REFERENCES workflow_stages(stage_id) ON DELETE CASCADE
);

-- =============================================================================
-- 4. WORKFLOW INSTANCES
-- =============================================================================

-- Active workflow instances
CREATE TABLE workflow_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id VARCHAR(50) NOT NULL UNIQUE,
    process_id VARCHAR(50) NOT NULL,
    
    -- Instance context from BDD lines 46-53
    workflow_object_type VARCHAR(50) NOT NULL, -- Schedule, Vacation Request, etc.
    workflow_object_id VARCHAR(50) NOT NULL,
    workflow_object_name VARCHAR(200) NOT NULL,
    
    -- Current status
    current_stage_id VARCHAR(50) NOT NULL,
    instance_status VARCHAR(20) DEFAULT 'active' CHECK (instance_status IN (
        'active', 'completed', 'cancelled', 'failed', 'escalated'
    )),
    
    -- Timeline tracking
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Participants and assignment
    initiated_by UUID NOT NULL,
    current_assignees JSONB DEFAULT '[]',
    completed_participants JSONB DEFAULT '[]',
    
    -- Instance data
    workflow_data JSONB DEFAULT '{}', -- Context-specific data
    business_context JSONB DEFAULT '{}',
    
    -- Performance tracking from BDD lines 163-180
    cycle_time_minutes INTEGER,
    escalation_count INTEGER DEFAULT 0,
    stage_completion_times JSONB DEFAULT '{}',
    
    -- Integration status from BDD lines 233-255
    integration_status VARCHAR(20) DEFAULT 'pending' CHECK (integration_status IN (
        'pending', 'processing', 'completed', 'failed', 'queued_retry'
    )),
    integration_results JSONB DEFAULT '{}',
    integration_errors JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (process_id) REFERENCES business_processes(process_id) ON DELETE RESTRICT,
    FOREIGN KEY (current_stage_id) REFERENCES workflow_stages(stage_id) ON DELETE RESTRICT,
    FOREIGN KEY (initiated_by) REFERENCES employees(id) ON DELETE RESTRICT
);

-- =============================================================================
-- 5. WORKFLOW TASKS
-- =============================================================================

-- Individual workflow tasks from BDD lines 41-60
CREATE TABLE workflow_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id VARCHAR(50) NOT NULL UNIQUE,
    instance_id VARCHAR(50) NOT NULL,
    stage_id VARCHAR(50) NOT NULL,
    
    -- Task assignment
    assigned_to UUID NOT NULL,
    assigned_role VARCHAR(100),
    assignment_type VARCHAR(20) DEFAULT 'direct' CHECK (assignment_type IN (
        'direct', 'delegated', 'escalated', 'automatic'
    )),
    
    -- Task details from BDD lines 46-53
    task_type VARCHAR(50) NOT NULL, -- e.g., "Supervisor confirmation"
    task_description TEXT,
    task_priority VARCHAR(20) DEFAULT 'medium' CHECK (task_priority IN (
        'low', 'medium', 'high', 'urgent'
    )),
    
    -- Task actions from BDD lines 54-59
    available_actions JSONB NOT NULL,
    selected_action VARCHAR(30),
    action_comments TEXT,
    action_attachments JSONB DEFAULT '[]',
    
    -- Task status and timing
    task_status VARCHAR(20) DEFAULT 'pending' CHECK (task_status IN (
        'pending', 'in_progress', 'completed', 'delegated', 'escalated', 'cancelled'
    )),
    due_date TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Delegation tracking from BDD lines 129-145
    delegated_from UUID,
    delegation_reason TEXT,
    delegation_scope JSONB DEFAULT '{}',
    
    -- Task results
    task_result VARCHAR(30), -- approve, reject, delegate, etc.
    result_data JSONB DEFAULT '{}',
    next_assignees JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (instance_id) REFERENCES workflow_instances(instance_id) ON DELETE CASCADE,
    FOREIGN KEY (stage_id) REFERENCES workflow_stages(stage_id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_to) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (delegated_from) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 6. WORKFLOW NOTIFICATIONS
-- =============================================================================

-- Process notifications from BDD lines 61-78
CREATE TABLE workflow_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id VARCHAR(50) NOT NULL UNIQUE,
    instance_id VARCHAR(50) NOT NULL,
    task_id VARCHAR(50),
    
    -- Notification configuration from BDD lines 65-70
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN (
        'task_assigned', 'task_due', 'task_escalated', 'process_completed', 
        'approval_required', 'process_cancelled'
    )),
    
    -- Notification channels from BDD lines 66-70
    notification_channels JSONB NOT NULL DEFAULT '["system"]',
    
    -- Notification content from BDD lines 71-77
    notification_title VARCHAR(200) NOT NULL,
    notification_message TEXT NOT NULL,
    process_name VARCHAR(200),
    task_description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    direct_link VARCHAR(500),
    escalation_warning TEXT,
    
    -- Recipient management
    recipient_id UUID NOT NULL,
    recipient_type VARCHAR(20) DEFAULT 'user' CHECK (recipient_type IN (
        'user', 'role', 'group', 'department'
    )),
    
    -- Delivery tracking
    notification_status VARCHAR(20) DEFAULT 'pending' CHECK (notification_status IN (
        'pending', 'sent', 'delivered', 'failed', 'cancelled'
    )),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivery_attempts INTEGER DEFAULT 0,
    delivery_errors JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (instance_id) REFERENCES workflow_instances(instance_id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES workflow_tasks(task_id) ON DELETE SET NULL,
    FOREIGN KEY (recipient_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- =============================================================================
-- 7. ESCALATION MANAGEMENT
-- =============================================================================

-- Escalation handling from BDD lines 112-128
CREATE TABLE workflow_escalations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    escalation_id VARCHAR(50) NOT NULL UNIQUE,
    task_id VARCHAR(50) NOT NULL,
    
    -- Escalation configuration from BDD lines 117-121
    escalation_level INTEGER NOT NULL CHECK (escalation_level >= 1 AND escalation_level <= 4),
    trigger_hours INTEGER NOT NULL,
    escalation_action VARCHAR(50) NOT NULL,
    
    -- Escalation targets
    escalation_to UUID,
    escalation_role VARCHAR(100),
    backup_approvers JSONB DEFAULT '[]',
    
    -- Escalation status
    escalation_status VARCHAR(20) DEFAULT 'pending' CHECK (escalation_status IN (
        'pending', 'triggered', 'resolved', 'cancelled'
    )),
    triggered_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Escalation details from BDD lines 122-127
    escalation_reason TEXT,
    automatic_reassignment BOOLEAN DEFAULT false,
    executive_notification_sent BOOLEAN DEFAULT false,
    emergency_override_used BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (task_id) REFERENCES workflow_tasks(task_id) ON DELETE CASCADE,
    FOREIGN KEY (escalation_to) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 8. DELEGATION MANAGEMENT
-- =============================================================================

-- Task delegation from BDD lines 129-145
CREATE TABLE workflow_delegations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegation_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Delegation parties
    delegator_id UUID NOT NULL,
    delegate_id UUID NOT NULL,
    
    -- Delegation scope from BDD lines 134-138
    delegation_type VARCHAR(30) NOT NULL CHECK (delegation_type IN (
        'temporary', 'specific_process', 'emergency', 'automatic'
    )),
    
    -- Delegation period
    effective_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_end TIMESTAMP WITH TIME ZONE,
    
    -- Scope configuration from BDD lines 134-138
    process_scope JSONB DEFAULT '[]', -- Specific processes
    role_scope JSONB DEFAULT '[]', -- Specific roles
    automatic_triggers JSONB DEFAULT '{}', -- Out-of-office triggers
    
    -- Delegation status
    delegation_status VARCHAR(20) DEFAULT 'active' CHECK (delegation_status IN (
        'active', 'expired', 'revoked', 'suspended'
    )),
    
    -- Accountability tracking from BDD lines 140-144
    authorization_required BOOLEAN DEFAULT true,
    authorized_by UUID,
    delegation_reason TEXT,
    audit_trail JSONB DEFAULT '[]',
    
    -- Usage tracking
    tasks_delegated INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (delegator_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (delegate_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (authorized_by) REFERENCES employees(id) ON DELETE SET NULL
);

-- =============================================================================
-- 9. PROCESS PERFORMANCE METRICS
-- =============================================================================

-- Process monitoring from BDD lines 163-180
CREATE TABLE process_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Measurement period
    measurement_date DATE NOT NULL,
    process_id VARCHAR(50) NOT NULL,
    
    -- Performance metrics from BDD lines 168-173
    average_cycle_time_hours DECIMAL(8,2),
    stage_bottleneck_analysis JSONB DEFAULT '{}',
    approval_rate_percentage DECIMAL(5,2),
    escalation_frequency_percentage DECIMAL(5,2),
    participant_utilization JSONB DEFAULT '{}',
    
    -- Process statistics
    total_instances INTEGER DEFAULT 0,
    completed_instances INTEGER DEFAULT 0,
    escalated_instances INTEGER DEFAULT 0,
    cancelled_instances INTEGER DEFAULT 0,
    
    -- Timing analysis
    fastest_completion_hours DECIMAL(8,2),
    slowest_completion_hours DECIMAL(8,2),
    median_completion_hours DECIMAL(8,2),
    
    -- Quality metrics
    first_time_approval_rate DECIMAL(5,2),
    rework_instances INTEGER DEFAULT 0,
    compliance_score DECIMAL(5,2),
    
    -- Optimization recommendations from BDD lines 174-179
    bottleneck_stages JSONB DEFAULT '[]',
    improvement_actions JSONB DEFAULT '[]',
    resource_allocation_suggestions JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (process_id) REFERENCES business_processes(process_id) ON DELETE CASCADE
);

-- =============================================================================
-- 10. EXTERNAL SYSTEM INTEGRATIONS
-- =============================================================================

-- Integration management from BDD lines 233-271
CREATE TABLE external_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Integration configuration from BDD lines 260-265
    system_name VARCHAR(100) NOT NULL,
    integration_type VARCHAR(30) NOT NULL CHECK (integration_type IN (
        '1c_zup_schedule', 'calendar_integration', 'document_management', 
        'notification_integration', 'custom_api'
    )),
    integration_purpose TEXT,
    
    -- API configuration
    endpoint_url VARCHAR(500),
    authentication_method VARCHAR(30) DEFAULT 'api_key',
    authentication_config JSONB DEFAULT '{}',
    
    -- Integration behavior from BDD lines 238-254
    trigger_stage_id VARCHAR(50),
    trigger_action VARCHAR(30),
    data_transformation_rules JSONB DEFAULT '{}',
    
    -- Error handling from BDD lines 244-254, 266-271
    retry_attempts INTEGER DEFAULT 3,
    retry_delay_minutes INTEGER DEFAULT 5,
    fallback_procedure JSONB DEFAULT '{}',
    error_escalation_enabled BOOLEAN DEFAULT true,
    
    -- Integration status
    is_active BOOLEAN DEFAULT true,
    last_successful_call TIMESTAMP WITH TIME ZONE,
    last_error_message TEXT,
    consecutive_failures INTEGER DEFAULT 0,
    
    -- Performance tracking
    total_calls INTEGER DEFAULT 0,
    successful_calls INTEGER DEFAULT 0,
    failed_calls INTEGER DEFAULT 0,
    average_response_time_ms INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trigger_stage_id) REFERENCES workflow_stages(stage_id) ON DELETE SET NULL
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Business processes queries
CREATE INDEX idx_business_processes_type ON business_processes(process_type);
CREATE INDEX idx_business_processes_active ON business_processes(is_active) WHERE is_active = true;
CREATE INDEX idx_business_processes_status ON business_processes(deployment_status);

-- Workflow stages queries
CREATE INDEX idx_workflow_stages_process ON workflow_stages(process_id);
CREATE INDEX idx_workflow_stages_order ON workflow_stages(process_id, stage_order);

-- Process transitions queries
CREATE INDEX idx_process_transitions_source ON process_transitions(source_stage_id);
CREATE INDEX idx_process_transitions_target ON process_transitions(target_stage_id);
CREATE INDEX idx_process_transitions_action ON process_transitions(trigger_action);

-- Workflow instances queries
CREATE INDEX idx_workflow_instances_process ON workflow_instances(process_id);
CREATE INDEX idx_workflow_instances_status ON workflow_instances(instance_status);
CREATE INDEX idx_workflow_instances_current_stage ON workflow_instances(current_stage_id);
CREATE INDEX idx_workflow_instances_object ON workflow_instances(workflow_object_type, workflow_object_id);
CREATE INDEX idx_workflow_instances_initiated_by ON workflow_instances(initiated_by);
CREATE INDEX idx_workflow_instances_due_date ON workflow_instances(due_date) WHERE due_date IS NOT NULL;

-- Workflow tasks queries
CREATE INDEX idx_workflow_tasks_instance ON workflow_tasks(instance_id);
CREATE INDEX idx_workflow_tasks_assigned_to ON workflow_tasks(assigned_to);
CREATE INDEX idx_workflow_tasks_status ON workflow_tasks(task_status);
CREATE INDEX idx_workflow_tasks_due_date ON workflow_tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_workflow_tasks_delegated_from ON workflow_tasks(delegated_from) WHERE delegated_from IS NOT NULL;

-- Workflow notifications queries
CREATE INDEX idx_workflow_notifications_instance ON workflow_notifications(instance_id);
CREATE INDEX idx_workflow_notifications_recipient ON workflow_notifications(recipient_id);
CREATE INDEX idx_workflow_notifications_status ON workflow_notifications(notification_status);
CREATE INDEX idx_workflow_notifications_type ON workflow_notifications(notification_type);

-- Escalation queries
CREATE INDEX idx_workflow_escalations_task ON workflow_escalations(task_id);
CREATE INDEX idx_workflow_escalations_status ON workflow_escalations(escalation_status);
CREATE INDEX idx_workflow_escalations_level ON workflow_escalations(escalation_level);

-- Delegation queries
CREATE INDEX idx_workflow_delegations_delegator ON workflow_delegations(delegator_id);
CREATE INDEX idx_workflow_delegations_delegate ON workflow_delegations(delegate_id);
CREATE INDEX idx_workflow_delegations_status ON workflow_delegations(delegation_status);
CREATE INDEX idx_workflow_delegations_active ON workflow_delegations(delegation_status) WHERE delegation_status = 'active';

-- Performance metrics queries
CREATE INDEX idx_process_performance_metrics_date ON process_performance_metrics(measurement_date);
CREATE INDEX idx_process_performance_metrics_process ON process_performance_metrics(process_id);

-- External integrations queries
CREATE INDEX idx_external_integrations_type ON external_integrations(integration_type);
CREATE INDEX idx_external_integrations_active ON external_integrations(is_active) WHERE is_active = true;
CREATE INDEX idx_external_integrations_trigger_stage ON external_integrations(trigger_stage_id);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_workflow_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER business_processes_update_trigger
    BEFORE UPDATE ON business_processes
    FOR EACH ROW EXECUTE FUNCTION update_workflow_timestamp();

CREATE TRIGGER workflow_instances_update_trigger
    BEFORE UPDATE ON workflow_instances
    FOR EACH ROW EXECUTE FUNCTION update_workflow_timestamp();

CREATE TRIGGER workflow_tasks_update_trigger
    BEFORE UPDATE ON workflow_tasks
    FOR EACH ROW EXECUTE FUNCTION update_workflow_timestamp();

CREATE TRIGGER workflow_delegations_update_trigger
    BEFORE UPDATE ON workflow_delegations
    FOR EACH ROW EXECUTE FUNCTION update_workflow_timestamp();

CREATE TRIGGER external_integrations_update_trigger
    BEFORE UPDATE ON external_integrations
    FOR EACH ROW EXECUTE FUNCTION update_workflow_timestamp();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Active workflow instances with current tasks
CREATE VIEW v_active_workflow_instances AS
SELECT 
    wi.instance_id,
    wi.workflow_object_name,
    bp.process_name,
    ws.stage_name as current_stage,
    wi.instance_status,
    wi.started_at,
    wi.due_date,
    e.full_name as initiated_by_name,
    COUNT(wt.id) as pending_tasks
FROM workflow_instances wi
JOIN business_processes bp ON wi.process_id = bp.process_id
JOIN workflow_stages ws ON wi.current_stage_id = ws.stage_id
JOIN employees e ON wi.initiated_by = e.id
LEFT JOIN workflow_tasks wt ON wi.instance_id = wt.instance_id AND wt.task_status = 'pending'
WHERE wi.instance_status = 'active'
GROUP BY wi.instance_id, wi.workflow_object_name, bp.process_name, ws.stage_name, 
         wi.instance_status, wi.started_at, wi.due_date, e.full_name
ORDER BY wi.due_date ASC NULLS LAST;

-- User task summary
CREATE VIEW v_user_task_summary AS
SELECT 
    e.id as user_id,
    e.full_name,
    COUNT(CASE WHEN wt.task_status = 'pending' THEN 1 END) as pending_tasks,
    COUNT(CASE WHEN wt.task_status = 'in_progress' THEN 1 END) as in_progress_tasks,
    COUNT(CASE WHEN wt.due_date < CURRENT_TIMESTAMP THEN 1 END) as overdue_tasks,
    MIN(wt.due_date) as earliest_due_date
FROM employees e
LEFT JOIN workflow_tasks wt ON e.id = wt.assigned_to
WHERE wt.task_status IN ('pending', 'in_progress') OR wt.id IS NULL
GROUP BY e.id, e.full_name
ORDER BY pending_tasks DESC, overdue_tasks DESC;

-- Process performance summary
CREATE VIEW v_process_performance_summary AS
SELECT 
    bp.process_name,
    COUNT(wi.id) as total_instances,
    COUNT(CASE WHEN wi.instance_status = 'completed' THEN 1 END) as completed_instances,
    COUNT(CASE WHEN wi.instance_status = 'active' THEN 1 END) as active_instances,
    AVG(wi.cycle_time_minutes) as avg_cycle_time_minutes,
    AVG(wi.escalation_count) as avg_escalations
FROM business_processes bp
LEFT JOIN workflow_instances wi ON bp.process_id = wi.process_id
WHERE wi.started_at >= CURRENT_DATE - INTERVAL '30 days' OR wi.id IS NULL
GROUP BY bp.process_id, bp.process_name
ORDER BY total_instances DESC;

-- =============================================================================
-- SAMPLE DATA FOR TESTING (5 workflow examples)
-- =============================================================================

-- Insert sample business processes
INSERT INTO business_processes (process_id, process_name, process_type, process_stages, participant_roles, available_actions, transition_rules, has_external_integration, created_by) VALUES
('schedule_approval', 'Work Schedule Approval Process', 'schedule_approval', 
'[{"stage": "supervisor_review", "order": 1}, {"stage": "planning_review", "order": 2}, {"stage": "operator_confirmation", "order": 3}, {"stage": "apply_schedule", "order": 4}]',
'["department_heads", "planning_specialist", "operators"]',
'["edit", "approve", "reject", "apply"]',
'[{"from": "supervisor_review", "to": "planning_review", "action": "approve"}, {"from": "planning_review", "to": "operator_confirmation", "action": "forward"}, {"from": "operator_confirmation", "to": "apply_schedule", "action": "acknowledge"}, {"from": "apply_schedule", "to": "complete", "action": "apply"}]',
true,
(SELECT id FROM employees LIMIT 1));

INSERT INTO business_processes (process_id, process_name, process_type, process_stages, participant_roles, available_actions, transition_rules, created_by) VALUES
('vacation_approval', 'Employee Vacation Request Approval', 'vacation_approval',
'[{"stage": "initial_review", "order": 1}, {"stage": "coverage_planning", "order": 2}, {"stage": "hr_approval", "order": 3}, {"stage": "final_confirmation", "order": 4}]',
'["direct_supervisor", "planning_specialist", "hr_representative"]',
'["approve", "reject", "request_changes"]',
'[{"from": "initial_review", "to": "coverage_planning", "action": "approve"}, {"from": "coverage_planning", "to": "hr_approval", "action": "confirm_coverage"}, {"from": "hr_approval", "to": "final_confirmation", "action": "approve"}, {"from": "final_confirmation", "to": "complete", "action": "approve"}]',
(SELECT id FROM employees LIMIT 1));

-- Insert workflow stages for schedule approval
INSERT INTO workflow_stages (stage_id, process_id, stage_name, stage_order, participant_roles, available_actions, timeout_hours, has_integration_trigger) VALUES
('supervisor_review', 'schedule_approval', 'Supervisor Review', 1, '["department_heads"]', '["edit", "approve", "reject"]', 24, false),
('planning_review', 'schedule_approval', 'Planning Review', 2, '["planning_specialist"]', '["update", "return", "forward"]', 48, false),
('operator_confirmation', 'schedule_approval', 'Operator Confirmation', 3, '["operators"]', '["view", "acknowledge"]', 72, false),
('apply_schedule', 'schedule_approval', 'Apply Schedule', 4, '["planning_specialist"]', '["apply"]', 24, true);

-- Insert sample external integration (1C ZUP)
INSERT INTO external_integrations (integration_id, system_name, integration_type, integration_purpose, endpoint_url, trigger_stage_id, trigger_action, retry_attempts) VALUES
('zup_schedule_integration', '1C ZUP System', '1c_zup_schedule', 'Send approved schedules to 1C ZUP via sendSchedule API', 'http://1c-server/sendSchedule', 'apply_schedule', 'apply', 3);

-- =============================================================================
-- COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE business_processes IS 'BDD Lines 11-22: Business process definitions with complete workflow structure and rules';
COMMENT ON TABLE workflow_stages IS 'BDD Lines 28-40, 83-95: Individual workflow stages with participants and actions';
COMMENT ON TABLE process_transitions IS 'BDD Lines 20, 28-40: Stage transitions and routing logic with business rules';
COMMENT ON TABLE workflow_instances IS 'Active workflow instances with current status and performance tracking';
COMMENT ON TABLE workflow_tasks IS 'BDD Lines 41-60: Individual workflow tasks with actions and delegation support';
COMMENT ON TABLE workflow_notifications IS 'BDD Lines 61-78: Process notifications with multi-channel delivery';
COMMENT ON TABLE workflow_escalations IS 'BDD Lines 112-128: Escalation handling with automatic reassignment';
COMMENT ON TABLE workflow_delegations IS 'BDD Lines 129-145: Task delegation with accountability tracking';
COMMENT ON TABLE process_performance_metrics IS 'BDD Lines 163-180: Process monitoring and performance analysis';
COMMENT ON TABLE external_integrations IS 'BDD Lines 233-271: External system integrations with error handling';