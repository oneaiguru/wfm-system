-- Schema 042: Business Process Management Workflows
-- Implementation of BDD specifications from 13-business-process-management-workflows.feature
-- Provides comprehensive workflow automation with business rule engine and cross-system integration

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types for workflow management
CREATE TYPE workflow_status AS ENUM ('draft', 'active', 'suspended', 'archived');
CREATE TYPE process_instance_status AS ENUM ('pending', 'in_progress', 'completed', 'failed', 'cancelled', 'escalated');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'rejected', 'delegated', 'escalated');
CREATE TYPE task_action AS ENUM ('approve', 'reject', 'delegate', 'request_info', 'edit', 'acknowledge', 'apply');
CREATE TYPE notification_channel AS ENUM ('system', 'email', 'mobile_push', 'sms');
CREATE TYPE escalation_level AS ENUM ('level_1', 'level_2', 'level_3', 'level_4');
CREATE TYPE delegation_type AS ENUM ('temporary', 'specific_process', 'emergency', 'automatic');
CREATE TYPE parallel_approval_type AS ENUM ('all_must_approve', 'majority_approval', 'quorum_with_majority', 'any_can_approve');
CREATE TYPE integration_status AS ENUM ('success', 'pending', 'failed', 'queued');

-- Business Process Definitions (Workflow Templates)
CREATE TABLE business_process_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL DEFAULT '1.0',
    category VARCHAR(100),
    status workflow_status DEFAULT 'draft',
    
    -- Process configuration
    process_definition JSONB NOT NULL, -- Process stages, roles, actions, transition rules
    notification_settings JSONB, -- Notification configuration per stage
    timeout_settings JSONB, -- Stage timeouts and escalation rules
    business_rules JSONB, -- Validation rules and conditions
    
    -- Customization support
    department_id UUID REFERENCES departments(id),
    geographic_region VARCHAR(100),
    process_template_id UUID REFERENCES business_process_definitions(id),
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id),
    
    -- Constraints
    CONSTRAINT unique_process_name_version UNIQUE (name, version)
);

-- Process Step Automation (Automated Task Execution)
CREATE TABLE process_step_automation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL REFERENCES business_process_definitions(id),
    step_name VARCHAR(255) NOT NULL,
    step_order INTEGER NOT NULL,
    
    -- Automation configuration
    automation_type VARCHAR(100) NOT NULL, -- 'api_call', 'notification', 'validation', 'calculation'
    automation_config JSONB NOT NULL, -- Step-specific configuration
    
    -- Prerequisites and conditions
    prerequisites JSONB, -- Required conditions for execution
    success_criteria JSONB, -- Conditions for successful completion
    failure_handling JSONB, -- Error handling and recovery
    
    -- Parallel execution
    parallel_group VARCHAR(100), -- Group for parallel execution
    parallel_type parallel_approval_type,
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(id),
    
    -- Constraints
    CONSTRAINT unique_process_step_order UNIQUE (process_definition_id, step_order)
);

-- Business Rule Engine (Decision Logic Implementation)
CREATE TABLE business_rule_engine (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL REFERENCES business_process_definitions(id),
    rule_name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(100) NOT NULL, -- 'validation', 'authorization', 'routing', 'escalation'
    
    -- Rule definition
    rule_expression TEXT NOT NULL, -- Logical expression for rule evaluation
    rule_parameters JSONB, -- Parameters for rule execution
    priority INTEGER DEFAULT 0, -- Rule execution priority
    
    -- Rule activation
    active BOOLEAN DEFAULT true,
    effective_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiration_date TIMESTAMP,
    
    -- Error handling
    error_handling JSONB, -- Actions on rule failure
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

-- Process Instance Tracking (Workflow Execution Monitoring)
CREATE TABLE process_instance_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL REFERENCES business_process_definitions(id),
    instance_name VARCHAR(255) NOT NULL,
    
    -- Instance details
    context_data JSONB NOT NULL, -- Process context and variables
    current_stage VARCHAR(255),
    current_step_order INTEGER,
    status process_instance_status DEFAULT 'pending',
    
    -- Timing information
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    due_date TIMESTAMP,
    
    -- Participants
    initiated_by UUID NOT NULL REFERENCES users(id),
    current_assignees JSONB, -- Current task assignees
    
    -- Progress tracking
    completed_steps JSONB, -- Completed steps with timestamps
    pending_steps JSONB, -- Pending steps and assignees
    
    -- Integration status
    integration_status integration_status DEFAULT 'pending',
    integration_details JSONB, -- External system integration details
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Process Tasks (Individual workflow tasks)
CREATE TABLE process_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID NOT NULL REFERENCES process_instance_tracking(id),
    step_automation_id UUID REFERENCES process_step_automation(id),
    
    -- Task details
    task_name VARCHAR(255) NOT NULL,
    task_description TEXT,
    task_type VARCHAR(100) NOT NULL, -- 'approval', 'review', 'acknowledgment', 'data_entry'
    
    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_role VARCHAR(100),
    delegation_id UUID, -- Reference to delegation record
    
    -- Task status
    status task_status DEFAULT 'pending',
    available_actions JSONB, -- Available actions for this task
    
    -- Timing
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Task data
    task_data JSONB, -- Task-specific data
    decision_data JSONB, -- Decision and rationale
    attachments JSONB, -- Supporting documents
    
    -- Escalation
    escalation_level escalation_level,
    escalated_at TIMESTAMP,
    escalated_to UUID REFERENCES users(id)
);

-- Task Actions (Actions performed on tasks)
CREATE TABLE task_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES process_tasks(id),
    action_type task_action NOT NULL,
    
    -- Action details
    performed_by UUID NOT NULL REFERENCES users(id),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comments TEXT,
    decision_rationale TEXT,
    
    -- Delegation details
    delegated_to UUID REFERENCES users(id),
    delegation_reason TEXT,
    
    -- Attachments
    attachments JSONB
);

-- Process Performance Metrics (Efficiency Measurement)
CREATE TABLE process_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL REFERENCES business_process_definitions(id),
    measurement_period_start TIMESTAMP NOT NULL,
    measurement_period_end TIMESTAMP NOT NULL,
    
    -- Cycle time metrics
    average_cycle_time INTERVAL,
    median_cycle_time INTERVAL,
    min_cycle_time INTERVAL,
    max_cycle_time INTERVAL,
    
    -- Stage performance
    stage_performance JSONB, -- Performance per stage
    bottleneck_stages JSONB, -- Identified bottlenecks
    
    -- Approval metrics
    total_instances INTEGER DEFAULT 0,
    approved_instances INTEGER DEFAULT 0,
    rejected_instances INTEGER DEFAULT 0,
    approval_rate DECIMAL(5,2),
    
    -- Escalation metrics
    escalation_count INTEGER DEFAULT 0,
    escalation_rate DECIMAL(5,2),
    
    -- Participant metrics
    participant_utilization JSONB, -- Workload distribution
    
    -- Calculated fields
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calculated_by UUID REFERENCES users(id)
);

-- Process Integration Points (Cross-system Orchestration)
CREATE TABLE process_integration_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL REFERENCES business_process_definitions(id),
    integration_name VARCHAR(255) NOT NULL,
    integration_type VARCHAR(100) NOT NULL, -- 'api_call', 'file_transfer', 'database_sync', 'notification'
    
    -- Integration configuration
    external_system VARCHAR(255) NOT NULL,
    endpoint_url TEXT,
    authentication_config JSONB,
    request_format JSONB,
    response_mapping JSONB,
    
    -- Execution settings
    trigger_stage VARCHAR(255), -- When to execute integration
    retry_policy JSONB, -- Retry configuration
    timeout_seconds INTEGER DEFAULT 300,
    
    -- Status tracking
    active BOOLEAN DEFAULT true,
    last_executed TIMESTAMP,
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

-- Integration Execution Log
CREATE TABLE integration_execution_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_point_id UUID NOT NULL REFERENCES process_integration_points(id),
    process_instance_id UUID NOT NULL REFERENCES process_instance_tracking(id),
    
    -- Execution details
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_duration INTERVAL,
    status integration_status,
    
    -- Request/Response
    request_data JSONB,
    response_data JSONB,
    error_details JSONB,
    
    -- Retry information
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP
);

-- Process Notifications
CREATE TABLE process_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID NOT NULL REFERENCES process_instance_tracking(id),
    task_id UUID REFERENCES process_tasks(id),
    
    -- Notification details
    recipient_id UUID NOT NULL REFERENCES users(id),
    notification_type VARCHAR(100) NOT NULL,
    channel notification_channel NOT NULL,
    
    -- Content
    subject VARCHAR(500),
    message TEXT,
    action_url TEXT,
    
    -- Status
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    
    -- Retry information
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP,
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Process Delegations
CREATE TABLE process_delegations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegator_id UUID NOT NULL REFERENCES users(id),
    delegate_id UUID NOT NULL REFERENCES users(id),
    
    -- Delegation scope
    delegation_type delegation_type NOT NULL,
    process_definition_id UUID REFERENCES business_process_definitions(id),
    
    -- Timing
    effective_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP,
    
    -- Configuration
    delegation_reason TEXT,
    authorization_required BOOLEAN DEFAULT false,
    authorized_by UUID REFERENCES users(id),
    authorized_at TIMESTAMP,
    
    -- Status
    active BOOLEAN DEFAULT true,
    revoked_at TIMESTAMP,
    revoked_by UUID REFERENCES users(id),
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Emergency Overrides
CREATE TABLE emergency_overrides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID NOT NULL REFERENCES process_instance_tracking(id),
    
    -- Override details
    override_type VARCHAR(100) NOT NULL, -- 'skip_approval', 'expedite', 'bypass_validation'
    justification TEXT NOT NULL,
    
    -- Authorization
    authorized_by UUID NOT NULL REFERENCES users(id),
    authorized_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    executive_approval BOOLEAN DEFAULT false,
    executive_approved_by UUID REFERENCES users(id),
    
    -- Audit requirements
    retroactive_review_required BOOLEAN DEFAULT true,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    review_outcome TEXT
);

-- Create indexes for performance optimization
CREATE INDEX idx_process_definitions_status ON business_process_definitions(status);
CREATE INDEX idx_process_definitions_category ON business_process_definitions(category);
CREATE INDEX idx_process_definitions_department ON business_process_definitions(department_id);

CREATE INDEX idx_process_instance_status ON process_instance_tracking(status);
CREATE INDEX idx_process_instance_current_stage ON process_instance_tracking(current_stage);
CREATE INDEX idx_process_instance_due_date ON process_instance_tracking(due_date);
CREATE INDEX idx_process_instance_definition ON process_instance_tracking(process_definition_id);

CREATE INDEX idx_process_tasks_status ON process_tasks(status);
CREATE INDEX idx_process_tasks_assigned_to ON process_tasks(assigned_to);
CREATE INDEX idx_process_tasks_due_date ON process_tasks(due_date);
CREATE INDEX idx_process_tasks_process_instance ON process_tasks(process_instance_id);

CREATE INDEX idx_task_actions_task_id ON task_actions(task_id);
CREATE INDEX idx_task_actions_performed_by ON task_actions(performed_by);
CREATE INDEX idx_task_actions_performed_at ON task_actions(performed_at);

CREATE INDEX idx_process_notifications_recipient ON process_notifications(recipient_id);
CREATE INDEX idx_process_notifications_sent_at ON process_notifications(sent_at);
CREATE INDEX idx_process_notifications_channel ON process_notifications(channel);

CREATE INDEX idx_process_delegations_delegator ON process_delegations(delegator_id);
CREATE INDEX idx_process_delegations_delegate ON process_delegations(delegate_id);
CREATE INDEX idx_process_delegations_active ON process_delegations(active);

CREATE INDEX idx_integration_execution_log_integration_point ON integration_execution_log(integration_point_id);
CREATE INDEX idx_integration_execution_log_process_instance ON integration_execution_log(process_instance_id);
CREATE INDEX idx_integration_execution_log_executed_at ON integration_execution_log(executed_at);

-- Sample Process Definitions and Business Rules

-- Sample: Schedule Approval Process
INSERT INTO business_process_definitions (name, description, category, status, process_definition, notification_settings, timeout_settings, business_rules, created_by)
VALUES (
    'Schedule Approval Process',
    'Automated workflow for work schedule approval with supervisor review, planning validation, operator confirmation, and 1C ZUP integration',
    'Schedule Management',
    'active',
    '{
        "stages": [
            {
                "name": "Supervisor Review",
                "order": 1,
                "participants": ["department_head"],
                "actions": ["edit", "approve", "reject"],
                "next_stage": "Planning Review"
            },
            {
                "name": "Planning Review", 
                "order": 2,
                "participants": ["planning_specialist"],
                "actions": ["update", "return", "forward"],
                "next_stage": "Operator Confirmation"
            },
            {
                "name": "Operator Confirmation",
                "order": 3,
                "participants": ["affected_operators"],
                "actions": ["view", "acknowledge"],
                "next_stage": "Final Application",
                "parallel_type": "all_must_approve"
            },
            {
                "name": "Final Application",
                "order": 4,
                "participants": ["planning_specialist"],
                "actions": ["apply"],
                "next_stage": "Complete"
            }
        ],
        "transition_rules": {
            "sequential_order": true,
            "completion_requirements": "all_participants_must_act",
            "timeout_handling": "automatic_escalation"
        }
    }',
    '{
        "channels": ["system", "email"],
        "triggers": ["task_assigned", "task_overdue", "stage_complete"],
        "templates": {
            "task_assigned": "You have a new task: {task_name} for {object_name}",
            "escalation_warning": "Task {task_name} escalates in {hours} hours"
        }
    }',
    '{
        "stage_timeouts": {
            "Supervisor Review": "24 hours",
            "Planning Review": "48 hours", 
            "Operator Confirmation": "72 hours",
            "Final Application": "24 hours"
        },
        "escalation_levels": [
            {"level": 1, "hours": 24, "action": "reminder"},
            {"level": 2, "hours": 48, "action": "notify_supervisor"},
            {"level": 3, "hours": 72, "action": "auto_assign_backup"},
            {"level": 4, "hours": 96, "action": "executive_escalation"}
        ]
    }',
    '{
        "authorization_rules": [
            {"rule": "role_based_access", "enforcement": "check_user_permissions"},
            {"rule": "sequential_completion", "enforcement": "prevent_skipping_stages"}
        ],
        "validation_rules": [
            {"rule": "schedule_completeness", "validation": "all_shifts_assigned"},
            {"rule": "coverage_requirements", "validation": "minimum_staffing_met"}
        ]
    }',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
);

-- Sample: Vacation Approval Process
INSERT INTO business_process_definitions (name, description, category, status, process_definition, business_rules, created_by)
VALUES (
    'Vacation Approval Process',
    'Employee vacation request approval with coverage planning and HR validation',
    'Human Resources',
    'active',
    '{
        "stages": [
            {
                "name": "Initial Review",
                "order": 1,
                "participants": ["direct_supervisor"],
                "actions": ["approve", "reject", "request_changes"],
                "criteria": "check_team_coverage"
            },
            {
                "name": "Coverage Planning",
                "order": 2,
                "participants": ["planning_specialist"],
                "actions": ["confirm_coverage", "request_adjustments"],
                "criteria": "verify_replacement_plan"
            },
            {
                "name": "HR Approval",
                "order": 3,
                "participants": ["hr_representative"],
                "actions": ["approve", "flag_issues"],
                "criteria": "validate_entitlements"
            },
            {
                "name": "Final Confirmation",
                "order": 4,
                "participants": ["original_supervisor"],
                "actions": ["approve", "deny"],
                "criteria": "final_authorization"
            }
        ]
    }',
    '{
        "business_rules": [
            {
                "rule": "sufficient_vacation_days",
                "validation": "check_accumulated_balance",
                "error_handling": "block_if_insufficient"
            },
            {
                "rule": "notice_period",
                "validation": "minimum_advance_notice",
                "error_handling": "warn_if_too_short"
            },
            {
                "rule": "team_coverage",
                "validation": "minimum_staffing_levels",
                "error_handling": "reject_if_understaffed"
            },
            {
                "rule": "blackout_periods",
                "validation": "restricted_vacation_times",
                "error_handling": "block_prohibited_dates"
            }
        ]
    }',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
);

-- Sample Business Rules for Schedule Approval
INSERT INTO business_rule_engine (process_definition_id, rule_name, rule_type, rule_expression, rule_parameters, created_by)
VALUES
(
    (SELECT id FROM business_process_definitions WHERE name = 'Schedule Approval Process'),
    'Role Authorization Check',
    'authorization',
    'user.role IN process_stage.allowed_roles AND user.department = schedule.department',
    '{"allowed_roles": ["department_head", "planning_specialist", "operator"]}',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
),
(
    (SELECT id FROM business_process_definitions WHERE name = 'Schedule Approval Process'),
    'Sequential Order Enforcement',
    'routing',
    'current_stage.order = previous_stage.order + 1 AND previous_stage.status = "completed"',
    '{"strict_order": true}',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
),
(
    (SELECT id FROM business_process_definitions WHERE name = 'Schedule Approval Process'),
    'Completion Requirements',
    'validation',
    'stage.participants.all(p => p.status = "completed") OR stage.completion_type = "any"',
    '{"completion_types": ["all", "majority", "any"]}',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
);

-- Sample Integration Point for 1C ZUP
INSERT INTO process_integration_points (process_definition_id, integration_name, integration_type, external_system, endpoint_url, authentication_config, request_format, trigger_stage, retry_policy, created_by)
VALUES (
    (SELECT id FROM business_process_definitions WHERE name = 'Schedule Approval Process'),
    '1C ZUP Schedule Upload',
    'api_call',
    '1C ZUP',
    'http://1c-zup-server/api/sendSchedule',
    '{"type": "basic_auth", "username": "wfm_system", "password_env": "1C_ZUP_PASSWORD"}',
    '{
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "body_template": {
            "schedule_data": "{schedule_json}",
            "employees": "{employee_schedules}",
            "time_types": {"I": "Работа", "H": "Отдых", "B": "Болезнь"}
        }
    }',
    'Final Application',
    '{
        "max_retries": 3,
        "retry_delay": "5 minutes",
        "backoff_multiplier": 2,
        "timeout_seconds": 300
    }',
    (SELECT id FROM users WHERE username = 'system' LIMIT 1)
);

-- Functions for Workflow Execution and Monitoring

-- Function: Start Process Instance
CREATE OR REPLACE FUNCTION start_process_instance(
    p_process_definition_id UUID,
    p_instance_name VARCHAR(255),
    p_context_data JSONB,
    p_initiated_by UUID,
    p_due_date TIMESTAMP DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_instance_id UUID;
    v_process_def RECORD;
    v_first_stage JSONB;
BEGIN
    -- Get process definition
    SELECT * INTO v_process_def
    FROM business_process_definitions
    WHERE id = p_process_definition_id AND status = 'active';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Process definition not found or not active';
    END IF;
    
    -- Create process instance
    INSERT INTO process_instance_tracking (
        process_definition_id,
        instance_name,
        context_data,
        initiated_by,
        due_date,
        current_stage,
        current_step_order,
        status
    ) VALUES (
        p_process_definition_id,
        p_instance_name,
        p_context_data,
        p_initiated_by,
        p_due_date,
        (v_process_def.process_definition->'stages'->0->>'name'),
        1,
        'in_progress'
    ) RETURNING id INTO v_instance_id;
    
    -- Create initial tasks
    PERFORM create_stage_tasks(v_instance_id, 1);
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Create Stage Tasks
CREATE OR REPLACE FUNCTION create_stage_tasks(
    p_instance_id UUID,
    p_stage_order INTEGER
) RETURNS VOID AS $$
DECLARE
    v_instance RECORD;
    v_process_def RECORD;
    v_stage JSONB;
    v_participant VARCHAR(255);
    v_task_id UUID;
BEGIN
    -- Get process instance and definition
    SELECT pit.*, bpd.process_definition
    INTO v_instance
    FROM process_instance_tracking pit
    JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
    WHERE pit.id = p_instance_id;
    
    -- Get stage definition
    SELECT stage INTO v_stage
    FROM jsonb_array_elements(v_instance.process_definition->'stages') AS stage
    WHERE (stage->>'order')::INTEGER = p_stage_order;
    
    -- Create tasks for each participant
    FOR v_participant IN 
        SELECT jsonb_array_elements_text(v_stage->'participants')
    LOOP
        INSERT INTO process_tasks (
            process_instance_id,
            task_name,
            task_description,
            task_type,
            assigned_role,
            status,
            available_actions,
            due_date
        ) VALUES (
            p_instance_id,
            v_stage->>'name',
            'Task for ' || v_instance.instance_name,
            'approval',
            v_participant,
            'pending',
            v_stage->'actions',
            CURRENT_TIMESTAMP + INTERVAL '24 hours'
        ) RETURNING id INTO v_task_id;
        
        -- Send notification
        PERFORM send_task_notification(v_task_id, 'task_assigned');
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Complete Task
CREATE OR REPLACE FUNCTION complete_task(
    p_task_id UUID,
    p_user_id UUID,
    p_action task_action,
    p_comments TEXT DEFAULT NULL,
    p_decision_data JSONB DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_task RECORD;
    v_instance RECORD;
    v_all_completed BOOLEAN;
BEGIN
    -- Get task and instance
    SELECT pt.*, pit.id as instance_id, pit.current_step_order
    INTO v_task
    FROM process_tasks pt
    JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
    WHERE pt.id = p_task_id;
    
    -- Validate task can be completed
    IF v_task.status != 'pending' THEN
        RAISE EXCEPTION 'Task is not in pending status';
    END IF;
    
    -- Record action
    INSERT INTO task_actions (
        task_id,
        action_type,
        performed_by,
        comments,
        decision_rationale
    ) VALUES (
        p_task_id,
        p_action,
        p_user_id,
        p_comments,
        p_decision_data->>'rationale'
    );
    
    -- Update task status
    UPDATE process_tasks
    SET status = 'completed',
        completed_at = CURRENT_TIMESTAMP,
        decision_data = p_decision_data
    WHERE id = p_task_id;
    
    -- Check if all tasks for current stage are completed
    SELECT COUNT(*) = 0 INTO v_all_completed
    FROM process_tasks
    WHERE process_instance_id = v_task.instance_id
    AND status IN ('pending', 'in_progress');
    
    -- Advance to next stage if all tasks completed
    IF v_all_completed THEN
        PERFORM advance_to_next_stage(v_task.instance_id);
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Advance to Next Stage
CREATE OR REPLACE FUNCTION advance_to_next_stage(p_instance_id UUID) RETURNS VOID AS $$
DECLARE
    v_instance RECORD;
    v_process_def RECORD;
    v_next_stage JSONB;
    v_next_order INTEGER;
BEGIN
    -- Get current instance and process definition
    SELECT pit.*, bpd.process_definition
    INTO v_instance
    FROM process_instance_tracking pit
    JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
    WHERE pit.id = p_instance_id;
    
    v_next_order := v_instance.current_step_order + 1;
    
    -- Get next stage
    SELECT stage INTO v_next_stage
    FROM jsonb_array_elements(v_instance.process_definition->'stages') AS stage
    WHERE (stage->>'order')::INTEGER = v_next_order;
    
    IF v_next_stage IS NULL THEN
        -- Process complete
        UPDATE process_instance_tracking
        SET status = 'completed',
            completed_at = CURRENT_TIMESTAMP
        WHERE id = p_instance_id;
        
        -- Trigger final integrations
        PERFORM execute_process_integrations(p_instance_id, 'Final Application');
    ELSE
        -- Advance to next stage
        UPDATE process_instance_tracking
        SET current_stage = v_next_stage->>'name',
            current_step_order = v_next_order
        WHERE id = p_instance_id;
        
        -- Create tasks for next stage
        PERFORM create_stage_tasks(p_instance_id, v_next_order);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Execute Process Integrations
CREATE OR REPLACE FUNCTION execute_process_integrations(
    p_instance_id UUID,
    p_stage_name VARCHAR(255)
) RETURNS VOID AS $$
DECLARE
    v_integration RECORD;
    v_instance RECORD;
    v_execution_id UUID;
BEGIN
    -- Get process instance
    SELECT * INTO v_instance
    FROM process_instance_tracking
    WHERE id = p_instance_id;
    
    -- Execute integrations for this stage
    FOR v_integration IN
        SELECT * FROM process_integration_points
        WHERE process_definition_id = v_instance.process_definition_id
        AND trigger_stage = p_stage_name
        AND active = true
    LOOP
        -- Log integration execution
        INSERT INTO integration_execution_log (
            integration_point_id,
            process_instance_id,
            status,
            request_data
        ) VALUES (
            v_integration.id,
            p_instance_id,
            'pending',
            v_instance.context_data
        ) RETURNING id INTO v_execution_id;
        
        -- For 1C ZUP integration, simulate the sendSchedule API call
        IF v_integration.integration_name = '1C ZUP Schedule Upload' THEN
            PERFORM simulate_1c_zup_integration(v_execution_id, v_instance.context_data);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Simulate 1C ZUP Integration
CREATE OR REPLACE FUNCTION simulate_1c_zup_integration(
    p_execution_id UUID,
    p_schedule_data JSONB
) RETURNS VOID AS $$
DECLARE
    v_success BOOLEAN;
    v_response JSONB;
BEGIN
    -- Simulate API call result (in real implementation, this would call external API)
    v_success := random() > 0.1; -- 90% success rate for simulation
    
    IF v_success THEN
        v_response := '{
            "status": "success",
            "message": "Schedule uploaded successfully",
            "documents_created": 15,
            "time_types_assigned": ["I", "H", "B"]
        }';
        
        UPDATE integration_execution_log
        SET status = 'success',
            response_data = v_response,
            execution_duration = INTERVAL '2 seconds'
        WHERE id = p_execution_id;
    ELSE
        v_response := '{
            "status": "error",
            "message": "Production calendar missing",
            "error_code": "CALENDAR_MISSING"
        }';
        
        UPDATE integration_execution_log
        SET status = 'failed',
            error_details = v_response,
            retry_count = 0,
            next_retry_at = CURRENT_TIMESTAMP + INTERVAL '5 minutes'
        WHERE id = p_execution_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Send Task Notification
CREATE OR REPLACE FUNCTION send_task_notification(
    p_task_id UUID,
    p_notification_type VARCHAR(100)
) RETURNS VOID AS $$
DECLARE
    v_task RECORD;
    v_users RECORD;
BEGIN
    -- Get task details
    SELECT pt.*, pit.instance_name, pit.context_data
    INTO v_task
    FROM process_tasks pt
    JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
    WHERE pt.id = p_task_id;
    
    -- Get users for the assigned role
    FOR v_users IN
        SELECT u.id, u.email, u.notification_preferences
        FROM users u
        JOIN user_roles ur ON u.id = ur.user_id
        JOIN roles r ON ur.role_id = r.id
        WHERE r.name = v_task.assigned_role
    LOOP
        -- Create system notification
        INSERT INTO process_notifications (
            process_instance_id,
            task_id,
            recipient_id,
            notification_type,
            channel,
            subject,
            message,
            action_url
        ) VALUES (
            v_task.process_instance_id,
            p_task_id,
            v_users.id,
            p_notification_type,
            'system',
            'New Task: ' || v_task.task_name,
            'You have a new task for ' || v_task.instance_name,
            '/tasks/' || p_task_id
        );
        
        -- Create email notification if enabled
        IF v_users.notification_preferences->>'email' = 'true' THEN
            INSERT INTO process_notifications (
                process_instance_id,
                task_id,
                recipient_id,
                notification_type,
                channel,
                subject,
                message,
                action_url
            ) VALUES (
                v_task.process_instance_id,
                p_task_id,
                v_users.id,
                p_notification_type,
                'email',
                'Task Assignment: ' || v_task.task_name,
                'You have been assigned a task: ' || v_task.task_name || ' for ' || v_task.instance_name,
                '/tasks/' || p_task_id
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Check and Handle Task Escalations
CREATE OR REPLACE FUNCTION check_task_escalations() RETURNS VOID AS $$
DECLARE
    v_task RECORD;
    v_escalation_hours INTEGER;
BEGIN
    -- Check for overdue tasks
    FOR v_task IN
        SELECT pt.*, pit.process_definition_id
        FROM process_tasks pt
        JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
        WHERE pt.status = 'pending'
        AND pt.due_date < CURRENT_TIMESTAMP
        AND (pt.escalation_level IS NULL OR pt.escalation_level != 'level_4')
    LOOP
        -- Determine escalation level based on how long overdue
        SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_task.due_date)) / 3600 INTO v_escalation_hours;
        
        IF v_escalation_hours >= 96 THEN
            -- Level 4: Executive escalation
            UPDATE process_tasks
            SET escalation_level = 'level_4',
                escalated_at = CURRENT_TIMESTAMP
            WHERE id = v_task.id;
            
            PERFORM send_task_notification(v_task.id, 'executive_escalation');
            
        ELSIF v_escalation_hours >= 72 THEN
            -- Level 3: Auto-assign to backup
            UPDATE process_tasks
            SET escalation_level = 'level_3',
                escalated_at = CURRENT_TIMESTAMP
            WHERE id = v_task.id;
            
            PERFORM auto_assign_backup_approver(v_task.id);
            
        ELSIF v_escalation_hours >= 48 THEN
            -- Level 2: Notify supervisor
            UPDATE process_tasks
            SET escalation_level = 'level_2',
                escalated_at = CURRENT_TIMESTAMP
            WHERE id = v_task.id;
            
            PERFORM send_task_notification(v_task.id, 'supervisor_notification');
            
        ELSIF v_escalation_hours >= 24 THEN
            -- Level 1: Reminder
            UPDATE process_tasks
            SET escalation_level = 'level_1',
                escalated_at = CURRENT_TIMESTAMP
            WHERE id = v_task.id;
            
            PERFORM send_task_notification(v_task.id, 'overdue_reminder');
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-assign Backup Approver
CREATE OR REPLACE FUNCTION auto_assign_backup_approver(p_task_id UUID) RETURNS VOID AS $$
DECLARE
    v_task RECORD;
    v_backup_user_id UUID;
BEGIN
    -- Get task details
    SELECT * INTO v_task FROM process_tasks WHERE id = p_task_id;
    
    -- Find backup approver (simplified logic)
    SELECT u.id INTO v_backup_user_id
    FROM users u
    JOIN user_roles ur ON u.id = ur.user_id
    JOIN roles r ON ur.role_id = r.id
    WHERE r.name = 'backup_approver'
    AND u.active = true
    LIMIT 1;
    
    IF v_backup_user_id IS NOT NULL THEN
        -- Assign to backup approver
        UPDATE process_tasks
        SET assigned_to = v_backup_user_id,
            escalated_to = v_backup_user_id
        WHERE id = p_task_id;
        
        -- Send notification
        PERFORM send_task_notification(p_task_id, 'backup_assignment');
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate Process Performance Metrics
CREATE OR REPLACE FUNCTION calculate_process_performance(
    p_process_definition_id UUID,
    p_start_date TIMESTAMP,
    p_end_date TIMESTAMP
) RETURNS VOID AS $$
DECLARE
    v_metrics RECORD;
    v_stage_performance JSONB;
    v_bottlenecks JSONB;
BEGIN
    -- Calculate basic metrics
    SELECT
        COUNT(*) as total_instances,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_instances,
        AVG(EXTRACT(EPOCH FROM (completed_at - started_at)) * INTERVAL '1 second') as avg_cycle_time,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (completed_at - started_at))) * INTERVAL '1 second' as median_cycle_time,
        MIN(completed_at - started_at) as min_cycle_time,
        MAX(completed_at - started_at) as max_cycle_time
    INTO v_metrics
    FROM process_instance_tracking
    WHERE process_definition_id = p_process_definition_id
    AND started_at BETWEEN p_start_date AND p_end_date;
    
    -- Calculate stage performance
    SELECT jsonb_object_agg(
        current_stage,
        jsonb_build_object(
            'average_duration', AVG(EXTRACT(EPOCH FROM (completed_at - started_at))),
            'instance_count', COUNT(*)
        )
    ) INTO v_stage_performance
    FROM process_instance_tracking
    WHERE process_definition_id = p_process_definition_id
    AND started_at BETWEEN p_start_date AND p_end_date
    GROUP BY current_stage;
    
    -- Identify bottlenecks (stages taking longer than average)
    SELECT jsonb_agg(
        jsonb_build_object(
            'stage', current_stage,
            'avg_duration', AVG(EXTRACT(EPOCH FROM (completed_at - started_at))),
            'bottleneck_factor', AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) / v_metrics.avg_cycle_time::NUMERIC
        )
    ) INTO v_bottlenecks
    FROM process_instance_tracking
    WHERE process_definition_id = p_process_definition_id
    AND started_at BETWEEN p_start_date AND p_end_date
    GROUP BY current_stage
    HAVING AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) > EXTRACT(EPOCH FROM v_metrics.avg_cycle_time);
    
    -- Insert metrics
    INSERT INTO process_performance_metrics (
        process_definition_id,
        measurement_period_start,
        measurement_period_end,
        total_instances,
        approved_instances,
        average_cycle_time,
        median_cycle_time,
        min_cycle_time,
        max_cycle_time,
        approval_rate,
        stage_performance,
        bottleneck_stages
    ) VALUES (
        p_process_definition_id,
        p_start_date,
        p_end_date,
        v_metrics.total_instances,
        v_metrics.completed_instances,
        v_metrics.avg_cycle_time,
        v_metrics.median_cycle_time,
        v_metrics.min_cycle_time,
        v_metrics.max_cycle_time,
        CASE WHEN v_metrics.total_instances > 0 
             THEN (v_metrics.completed_instances::DECIMAL / v_metrics.total_instances * 100) 
             ELSE 0 END,
        v_stage_performance,
        v_bottlenecks
    );
END;
$$ LANGUAGE plpgsql;

-- Create views for common queries

-- View: My Tasks
CREATE VIEW my_tasks AS
SELECT 
    pt.id,
    pt.task_name,
    pt.task_description,
    pt.status,
    pt.due_date,
    pt.assigned_at,
    pt.escalation_level,
    pit.instance_name,
    pit.current_stage,
    bpd.name as process_name,
    pt.available_actions
FROM process_tasks pt
JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
WHERE pt.assigned_to = current_user_id() -- Assuming current_user_id() function exists
AND pt.status IN ('pending', 'in_progress');

-- View: Process Performance Dashboard
CREATE VIEW process_performance_dashboard AS
SELECT 
    bpd.name as process_name,
    bpd.category,
    COUNT(pit.id) as total_instances,
    COUNT(CASE WHEN pit.status = 'completed' THEN 1 END) as completed_instances,
    COUNT(CASE WHEN pit.status = 'in_progress' THEN 1 END) as in_progress_instances,
    AVG(EXTRACT(EPOCH FROM (pit.completed_at - pit.started_at))/3600) as avg_cycle_time_hours,
    COUNT(CASE WHEN pt.escalation_level IS NOT NULL THEN 1 END) as escalated_tasks
FROM business_process_definitions bpd
LEFT JOIN process_instance_tracking pit ON bpd.id = pit.process_definition_id
LEFT JOIN process_tasks pt ON pit.id = pt.process_instance_id
WHERE bpd.status = 'active'
GROUP BY bpd.id, bpd.name, bpd.category;

-- View: Active Delegations
CREATE VIEW active_delegations AS
SELECT 
    pd.id,
    u1.first_name || ' ' || u1.last_name as delegator_name,
    u2.first_name || ' ' || u2.last_name as delegate_name,
    pd.delegation_type,
    pd.effective_from,
    pd.effective_to,
    bpd.name as process_name,
    pd.delegation_reason
FROM process_delegations pd
JOIN users u1 ON pd.delegator_id = u1.id
JOIN users u2 ON pd.delegate_id = u2.id
LEFT JOIN business_process_definitions bpd ON pd.process_definition_id = bpd.id
WHERE pd.active = true
AND (pd.effective_to IS NULL OR pd.effective_to > CURRENT_TIMESTAMP);

-- Comments for documentation
COMMENT ON SCHEMA public IS 'Schema 042: Business Process Management Workflows - Comprehensive workflow automation system with business rule engine, process monitoring, and cross-system integration capabilities';

COMMENT ON TABLE business_process_definitions IS 'Core workflow templates defining process stages, participants, actions, and business rules';
COMMENT ON TABLE process_step_automation IS 'Automated task execution configuration for workflow steps';
COMMENT ON TABLE business_rule_engine IS 'Decision logic implementation for workflow validation and routing';
COMMENT ON TABLE process_instance_tracking IS 'Active workflow execution monitoring and status tracking';
COMMENT ON TABLE process_performance_metrics IS 'Workflow efficiency measurement and bottleneck analysis';
COMMENT ON TABLE process_integration_points IS 'Cross-system orchestration configuration including 1C ZUP integration';
COMMENT ON TABLE process_tasks IS 'Individual workflow tasks with assignment and escalation management';
COMMENT ON TABLE task_actions IS 'Audit trail of all actions performed on workflow tasks';
COMMENT ON TABLE integration_execution_log IS 'Log of external system integration calls and responses';
COMMENT ON TABLE process_notifications IS 'Multi-channel notification system for workflow events';
COMMENT ON TABLE process_delegations IS 'Task delegation and substitution management';
COMMENT ON TABLE emergency_overrides IS 'Emergency workflow bypass with audit trail and executive approval';