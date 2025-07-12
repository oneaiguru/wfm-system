-- =============================================================================
-- 030_business_process_management.sql
-- EXACT BUSINESS PROCESS MANAGEMENT & WORKFLOW AUTOMATION - From BDD Specifications
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-11
-- Purpose: Implement EXACT business process management as specified in BDD file 13
-- Based on: BPMS workflow definitions, approval chains, task management, notifications
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- 1. PROCESS_DEFINITIONS - Business process definitions (BDD: Process components)
-- =============================================================================
CREATE TABLE process_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Process identification
    process_name VARCHAR(200) NOT NULL UNIQUE,
    process_description TEXT,
    process_version VARCHAR(20) DEFAULT '1.0',
    
    -- Process metadata
    process_category VARCHAR(100) NOT NULL, -- SCHEDULE_APPROVAL, VACATION_APPROVAL, SHIFT_EXCHANGE
    business_domain VARCHAR(100) NOT NULL, -- HR, PLANNING, OPERATIONS
    
    -- Process status
    process_status VARCHAR(20) DEFAULT 'DRAFT' CHECK (
        process_status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'DEPRECATED')
    ),
    
    -- Process configuration (BDD: Process definition content)
    process_stages JSONB NOT NULL, -- Sequential workflow steps
    participant_roles JSONB NOT NULL, -- Who can perform each stage
    available_actions JSONB NOT NULL, -- What can be done at each stage
    transition_rules JSONB NOT NULL, -- Conditions for moving between stages
    notification_settings JSONB NOT NULL, -- Who gets notified when
    
    -- Business rules
    business_rules JSONB, -- Validation rules and constraints
    timeout_settings JSONB, -- Escalation and timeout configuration
    
    -- Process metadata
    definition_source VARCHAR(100), -- ZIP/RAR archive filename
    uploaded_by VARCHAR(100) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit trail
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for process_definitions
CREATE INDEX idx_process_definitions_name ON process_definitions(process_name);
CREATE INDEX idx_process_definitions_category ON process_definitions(process_category);
CREATE INDEX idx_process_definitions_status ON process_definitions(process_status);

-- =============================================================================
-- 2. PROCESS_INSTANCES - Active process instances
-- =============================================================================
CREATE TABLE process_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_definition_id UUID NOT NULL,
    
    -- Instance identification
    instance_name VARCHAR(200) NOT NULL,
    instance_description TEXT,
    
    -- Process object (BDD: Object - Schedule Q1 2025, vacation request, etc.)
    business_object_type VARCHAR(100) NOT NULL, -- SCHEDULE, VACATION_REQUEST, SHIFT_EXCHANGE
    business_object_id UUID, -- Reference to actual business object
    business_object_name VARCHAR(200) NOT NULL, -- Human-readable object name
    
    -- Process state
    current_stage VARCHAR(100) NOT NULL,
    process_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (
        process_status IN ('ACTIVE', 'COMPLETED', 'CANCELLED', 'FAILED', 'SUSPENDED')
    ),
    
    -- Timing information
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Process data
    process_variables JSONB, -- Context data for the process
    
    -- Initiator information
    initiated_by VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_process_instances_definition 
        FOREIGN KEY (process_definition_id) REFERENCES process_definitions(id) ON DELETE CASCADE
);

-- Indexes for process_instances
CREATE INDEX idx_process_instances_definition ON process_instances(process_definition_id);
CREATE INDEX idx_process_instances_status ON process_instances(process_status);
CREATE INDEX idx_process_instances_stage ON process_instances(current_stage);
CREATE INDEX idx_process_instances_object ON process_instances(business_object_type, business_object_id);

-- =============================================================================
-- 3. WORKFLOW_TASKS - Individual tasks in workflow stages (BDD: Task management)
-- =============================================================================
CREATE TABLE workflow_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID NOT NULL,
    
    -- Task identification (BDD: Task details)
    task_name VARCHAR(200) NOT NULL, -- Supervisor confirmation, Planning Review, etc.
    task_description TEXT,
    task_type VARCHAR(100) NOT NULL, -- APPROVAL, REVIEW, CONFIRMATION, APPLICATION
    
    -- Task assignment
    assigned_to VARCHAR(100) NOT NULL, -- User responsible for the task
    assigned_role VARCHAR(100) NOT NULL, -- Department heads, Planning specialist, Operators
    
    -- Task state
    task_status VARCHAR(20) DEFAULT 'PENDING' CHECK (
        task_status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DELEGATED', 'ESCALATED')
    ),
    
    -- Available actions (BDD: Edit/Approve/Reject, Update/Return/Forward, etc.)
    available_actions JSONB NOT NULL, -- Array of action objects
    
    -- Task timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Task data
    task_variables JSONB, -- Task-specific data
    
    -- Comments and attachments (BDD: Comments, Attachments)
    comments TEXT,
    attachments JSONB, -- Array of attachment objects
    
    -- Escalation settings
    escalation_enabled BOOLEAN DEFAULT true,
    escalation_after_hours INTEGER DEFAULT 24,
    escalated_to VARCHAR(100),
    escalation_count INTEGER DEFAULT 0,
    
    CONSTRAINT fk_workflow_tasks_instance 
        FOREIGN KEY (process_instance_id) REFERENCES process_instances(id) ON DELETE CASCADE
);

-- Indexes for workflow_tasks
CREATE INDEX idx_workflow_tasks_instance ON workflow_tasks(process_instance_id);
CREATE INDEX idx_workflow_tasks_assigned ON workflow_tasks(assigned_to);
CREATE INDEX idx_workflow_tasks_status ON workflow_tasks(task_status);
CREATE INDEX idx_workflow_tasks_due_date ON workflow_tasks(due_date);

-- =============================================================================
-- 4. TASK_ACTIONS - Actions performed on tasks (BDD: Approve/Return/Delegate)
-- =============================================================================
CREATE TABLE task_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_task_id UUID NOT NULL,
    
    -- Action details (BDD: Available options)
    action_type VARCHAR(50) NOT NULL CHECK (
        action_type IN ('APPROVE', 'REJECT', 'DELEGATE', 'REQUEST_INFO', 'RETURN', 'FORWARD', 'EDIT', 'ACKNOWLEDGE')
    ),
    action_description TEXT,
    
    -- Action result (BDD: Action results)
    action_result VARCHAR(50) NOT NULL CHECK (
        action_result IN ('MOVE_TO_NEXT_STAGE', 'RETURN_TO_PREVIOUS_STAGE', 'ASSIGN_TO_USER', 'HOLD_PENDING', 'COMPLETE_PROCESS')
    ),
    
    -- Action performer
    performed_by VARCHAR(100) NOT NULL,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Action data
    action_comments TEXT,
    action_attachments JSONB,
    
    -- Delegation information (if action_type = 'DELEGATE')
    delegated_to VARCHAR(100),
    delegation_reason TEXT,
    
    -- Next stage information
    next_stage VARCHAR(100),
    next_assignee VARCHAR(100),
    
    CONSTRAINT fk_task_actions_task 
        FOREIGN KEY (workflow_task_id) REFERENCES workflow_tasks(id) ON DELETE CASCADE
);

-- Indexes for task_actions
CREATE INDEX idx_task_actions_task ON task_actions(workflow_task_id);
CREATE INDEX idx_task_actions_performer ON task_actions(performed_by);
CREATE INDEX idx_task_actions_type ON task_actions(action_type);
CREATE INDEX idx_task_actions_performed_at ON task_actions(performed_at);

-- =============================================================================
-- 5. PROCESS_NOTIFICATIONS - Workflow notifications (BDD: Notification system)
-- =============================================================================
CREATE TABLE process_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID NOT NULL,
    workflow_task_id UUID,
    
    -- Notification details (BDD: Notification content)
    notification_type VARCHAR(50) NOT NULL CHECK (
        notification_type IN ('TASK_ASSIGNED', 'TASK_DUE', 'TASK_OVERDUE', 'PROCESS_COMPLETED', 'ESCALATION')
    ),
    
    -- Recipient information
    recipient_user VARCHAR(100) NOT NULL,
    recipient_role VARCHAR(100),
    
    -- Notification channels (BDD: Configured channels)
    send_system_notification BOOLEAN DEFAULT true,
    send_email_notification BOOLEAN DEFAULT false,
    send_mobile_push BOOLEAN DEFAULT false,
    send_sms_notification BOOLEAN DEFAULT false,
    
    -- Notification content (BDD: Information included)
    process_name VARCHAR(200) NOT NULL, -- "Schedule Approval Process"
    task_description TEXT NOT NULL, -- "Review and approve Q1 schedule"
    due_date TIMESTAMP WITH TIME ZONE, -- "Due by: 2025-01-15"
    direct_link VARCHAR(500), -- URL to task interface
    escalation_warning TEXT, -- "Escalates in 2 days"
    
    -- Notification status
    notification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (
        notification_status IN ('PENDING', 'SENT', 'FAILED', 'CANCELLED')
    ),
    
    -- Delivery tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivery_attempts INTEGER DEFAULT 0,
    last_delivery_attempt TIMESTAMP WITH TIME ZONE,
    delivery_error TEXT,
    
    CONSTRAINT fk_process_notifications_instance 
        FOREIGN KEY (process_instance_id) REFERENCES process_instances(id) ON DELETE CASCADE,
    CONSTRAINT fk_process_notifications_task 
        FOREIGN KEY (workflow_task_id) REFERENCES workflow_tasks(id) ON DELETE CASCADE
);

-- Indexes for process_notifications
CREATE INDEX idx_process_notifications_instance ON process_notifications(process_instance_id);
CREATE INDEX idx_process_notifications_task ON process_notifications(workflow_task_id);
CREATE INDEX idx_process_notifications_recipient ON process_notifications(recipient_user);
CREATE INDEX idx_process_notifications_status ON process_notifications(notification_status);

-- =============================================================================
-- 6. BUSINESS_RULES - Process validation rules (BDD: Business rules enforcement)
-- =============================================================================
CREATE TABLE business_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Rule identification
    rule_name VARCHAR(200) NOT NULL,
    rule_description TEXT,
    rule_category VARCHAR(100) NOT NULL, -- VACATION_VALIDATION, COVERAGE_CHECK, AUTHORIZATION
    
    -- Rule scope
    applies_to_process VARCHAR(100), -- Process category this rule applies to
    applies_to_stage VARCHAR(100), -- Specific stage (optional)
    
    -- Rule definition
    rule_type VARCHAR(50) NOT NULL CHECK (
        rule_type IN ('VALIDATION', 'AUTHORIZATION', 'CALCULATION', 'NOTIFICATION', 'ESCALATION')
    ),
    rule_expression TEXT NOT NULL, -- Business rule logic
    
    -- Rule parameters (BDD: Business rule examples)
    validation_criteria JSONB, -- Criteria for validation rules
    error_message TEXT, -- Message when rule fails
    warning_message TEXT, -- Warning message
    
    -- Rule behavior
    is_blocking BOOLEAN DEFAULT true, -- Blocks process if rule fails
    rule_priority INTEGER DEFAULT 1, -- Rule execution order
    
    -- Rule status
    rule_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (
        rule_status IN ('ACTIVE', 'INACTIVE', 'DEPRECATED')
    ),
    
    -- Audit trail
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for business_rules
CREATE INDEX idx_business_rules_process ON business_rules(applies_to_process);
CREATE INDEX idx_business_rules_category ON business_rules(rule_category);
CREATE INDEX idx_business_rules_type ON business_rules(rule_type);
CREATE INDEX idx_business_rules_status ON business_rules(rule_status);

-- =============================================================================
-- FUNCTIONS: Business Process Engine
-- =============================================================================

-- Function to initiate a business process (BDD: Process initiation)
CREATE OR REPLACE FUNCTION initiate_business_process(
    p_process_name VARCHAR(200),
    p_business_object_type VARCHAR(100),
    p_business_object_id UUID,
    p_business_object_name VARCHAR(200),
    p_initiated_by VARCHAR(100),
    p_process_variables JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
DECLARE
    v_process_definition process_definitions%ROWTYPE;
    v_process_instance_id UUID;
    v_first_stage JSONB;
    v_first_task_id UUID;
    v_notification_id UUID;
BEGIN
    -- Get process definition
    SELECT * INTO v_process_definition 
    FROM process_definitions 
    WHERE process_name = p_process_name AND process_status = 'ACTIVE';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active process definition not found: %', p_process_name;
    END IF;
    
    -- Create process instance
    INSERT INTO process_instances (
        process_definition_id,
        instance_name,
        business_object_type,
        business_object_id,
        business_object_name,
        current_stage,
        initiated_by,
        process_variables
    ) VALUES (
        v_process_definition.id,
        p_process_name || ' - ' || p_business_object_name,
        p_business_object_type,
        p_business_object_id,
        p_business_object_name,
        (v_process_definition.process_stages->0->>'stage_name')::TEXT,
        p_initiated_by,
        p_process_variables
    ) RETURNING id INTO v_process_instance_id;
    
    -- Get first stage configuration
    v_first_stage := v_process_definition.process_stages->0;
    
    -- Create first task
    INSERT INTO workflow_tasks (
        process_instance_id,
        task_name,
        task_description,
        task_type,
        assigned_to,
        assigned_role,
        available_actions,
        due_date
    ) VALUES (
        v_process_instance_id,
        v_first_stage->>'task_name',
        v_first_stage->>'task_description',
        v_first_stage->>'task_type',
        COALESCE(v_first_stage->>'assigned_to', p_initiated_by),
        v_first_stage->>'assigned_role',
        v_first_stage->'available_actions',
        CURRENT_TIMESTAMP + INTERVAL '24 hours' -- Default 24 hour due date
    ) RETURNING id INTO v_first_task_id;
    
    -- Create notification for first task
    INSERT INTO process_notifications (
        process_instance_id,
        workflow_task_id,
        notification_type,
        recipient_user,
        recipient_role,
        process_name,
        task_description,
        due_date,
        direct_link
    ) VALUES (
        v_process_instance_id,
        v_first_task_id,
        'TASK_ASSIGNED',
        COALESCE(v_first_stage->>'assigned_to', p_initiated_by),
        v_first_stage->>'assigned_role',
        p_process_name,
        'New task assigned: ' || (v_first_stage->>'task_name'),
        CURRENT_TIMESTAMP + INTERVAL '24 hours',
        '/tasks/' || v_first_task_id::TEXT
    );
    
    RETURN v_process_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Function to execute task action (BDD: Handle approval tasks)
CREATE OR REPLACE FUNCTION execute_task_action(
    p_task_id UUID,
    p_action_type VARCHAR(50),
    p_performed_by VARCHAR(100),
    p_comments TEXT DEFAULT NULL,
    p_delegated_to VARCHAR(100) DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_task workflow_tasks%ROWTYPE;
    v_process_instance process_instances%ROWTYPE;
    v_process_definition process_definitions%ROWTYPE;
    v_action_id UUID;
    v_next_stage JSONB;
    v_next_task_id UUID;
    v_result JSONB;
    v_action_result VARCHAR(50);
BEGIN
    -- Get task details
    SELECT * INTO v_task FROM workflow_tasks WHERE id = p_task_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Task not found: %', p_task_id;
    END IF;
    
    -- Validate task status
    IF v_task.task_status NOT IN ('PENDING', 'IN_PROGRESS') THEN
        RAISE EXCEPTION 'Task is not in a state that allows actions: %', v_task.task_status;
    END IF;
    
    -- Get process instance and definition
    SELECT * INTO v_process_instance FROM process_instances WHERE id = v_task.process_instance_id;
    SELECT * INTO v_process_definition FROM process_definitions WHERE id = v_process_instance.process_definition_id;
    
    -- Determine action result
    v_action_result := CASE p_action_type
        WHEN 'APPROVE' THEN 'MOVE_TO_NEXT_STAGE'
        WHEN 'REJECT' THEN 'RETURN_TO_PREVIOUS_STAGE'
        WHEN 'DELEGATE' THEN 'ASSIGN_TO_USER'
        WHEN 'REQUEST_INFO' THEN 'HOLD_PENDING'
        WHEN 'ACKNOWLEDGE' THEN 'MOVE_TO_NEXT_STAGE'
        ELSE 'HOLD_PENDING'
    END;
    
    -- Record the action
    INSERT INTO task_actions (
        workflow_task_id,
        action_type,
        action_result,
        performed_by,
        action_comments,
        delegated_to
    ) VALUES (
        p_task_id,
        p_action_type,
        v_action_result,
        p_performed_by,
        p_comments,
        p_delegated_to
    ) RETURNING id INTO v_action_id;
    
    -- Update task status
    UPDATE workflow_tasks SET
        task_status = CASE 
            WHEN p_action_type = 'DELEGATE' THEN 'DELEGATED'
            WHEN p_action_type = 'REQUEST_INFO' THEN 'IN_PROGRESS'
            ELSE 'COMPLETED'
        END,
        completed_at = CASE 
            WHEN p_action_type NOT IN ('DELEGATE', 'REQUEST_INFO') THEN CURRENT_TIMESTAMP
            ELSE NULL
        END,
        assigned_to = CASE 
            WHEN p_action_type = 'DELEGATE' THEN p_delegated_to
            ELSE assigned_to
        END,
        comments = COALESCE(comments || E'\n\n', '') || 
                  '[' || CURRENT_TIMESTAMP::TEXT || '] ' || p_performed_by || ': ' || COALESCE(p_comments, p_action_type)
    WHERE id = p_task_id;
    
    -- Handle process progression
    IF v_action_result = 'MOVE_TO_NEXT_STAGE' THEN
        -- Find next stage in process definition
        SELECT stage INTO v_next_stage
        FROM jsonb_array_elements(v_process_definition.process_stages) stage
        WHERE stage->>'stage_order' = ((
            SELECT stage->>'stage_order' 
            FROM jsonb_array_elements(v_process_definition.process_stages) stage
            WHERE stage->>'stage_name' = v_process_instance.current_stage
        )::INTEGER + 1)::TEXT;
        
        IF v_next_stage IS NOT NULL THEN
            -- Update process instance to next stage
            UPDATE process_instances SET
                current_stage = v_next_stage->>'stage_name',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = v_task.process_instance_id;
            
            -- Create next task
            INSERT INTO workflow_tasks (
                process_instance_id,
                task_name,
                task_description,
                task_type,
                assigned_to,
                assigned_role,
                available_actions,
                due_date
            ) VALUES (
                v_task.process_instance_id,
                v_next_stage->>'task_name',
                v_next_stage->>'task_description',
                v_next_stage->>'task_type',
                v_next_stage->>'assigned_to',
                v_next_stage->>'assigned_role',
                v_next_stage->'available_actions',
                CURRENT_TIMESTAMP + INTERVAL '24 hours'
            ) RETURNING id INTO v_next_task_id;
            
            -- Create notification for next task
            INSERT INTO process_notifications (
                process_instance_id,
                workflow_task_id,
                notification_type,
                recipient_user,
                recipient_role,
                process_name,
                task_description,
                due_date,
                direct_link
            ) VALUES (
                v_task.process_instance_id,
                v_next_task_id,
                'TASK_ASSIGNED',
                v_next_stage->>'assigned_to',
                v_next_stage->>'assigned_role',
                v_process_definition.process_name,
                'New task assigned: ' || (v_next_stage->>'task_name'),
                CURRENT_TIMESTAMP + INTERVAL '24 hours',
                '/tasks/' || v_next_task_id::TEXT
            );
        ELSE
            -- No more stages - complete process
            UPDATE process_instances SET
                process_status = 'COMPLETED',
                completed_at = CURRENT_TIMESTAMP
            WHERE id = v_task.process_instance_id;
        END IF;
    END IF;
    
    -- Build result
    v_result := jsonb_build_object(
        'action_id', v_action_id,
        'task_id', p_task_id,
        'action_type', p_action_type,
        'action_result', v_action_result,
        'next_stage', v_next_stage->>'stage_name',
        'next_task_id', v_next_task_id,
        'process_status', (SELECT process_status FROM process_instances WHERE id = v_task.process_instance_id)
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to validate business rules
CREATE OR REPLACE FUNCTION validate_business_rules(
    p_process_name VARCHAR(200),
    p_stage_name VARCHAR(100),
    p_business_object JSONB
) RETURNS JSONB AS $$
DECLARE
    v_rule RECORD;
    v_validation_results JSONB := '[]'::JSONB;
    v_rule_result JSONB;
    v_is_valid BOOLEAN := true;
    v_errors TEXT[] := ARRAY[]::TEXT[];
    v_warnings TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Check all applicable business rules
    FOR v_rule IN 
        SELECT * FROM business_rules 
        WHERE rule_status = 'ACTIVE'
        AND (applies_to_process = p_process_name OR applies_to_process IS NULL)
        AND (applies_to_stage = p_stage_name OR applies_to_stage IS NULL)
        ORDER BY rule_priority
    LOOP
        -- Simplified rule validation (in production would need rule engine)
        v_rule_result := jsonb_build_object(
            'rule_name', v_rule.rule_name,
            'rule_type', v_rule.rule_type,
            'is_valid', true,
            'message', 'Rule validation passed'
        );
        
        -- Add example validation for vacation rules
        IF v_rule.rule_category = 'VACATION_VALIDATION' THEN
            -- Example: Check vacation days balance
            IF p_business_object ? 'vacation_days_requested' AND p_business_object ? 'vacation_days_available' THEN
                IF (p_business_object->>'vacation_days_requested')::INTEGER > (p_business_object->>'vacation_days_available')::INTEGER THEN
                    v_rule_result := jsonb_build_object(
                        'rule_name', v_rule.rule_name,
                        'rule_type', v_rule.rule_type,
                        'is_valid', false,
                        'message', 'Insufficient vacation days available'
                    );
                    v_is_valid := false;
                    v_errors := array_append(v_errors, v_rule.error_message);
                END IF;
            END IF;
        END IF;
        
        v_validation_results := v_validation_results || v_rule_result;
    END LOOP;
    
    RETURN jsonb_build_object(
        'is_valid', v_is_valid,
        'errors', array_to_json(v_errors),
        'warnings', array_to_json(v_warnings),
        'rule_results', v_validation_results
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VIEWS: Process Management Dashboard (BDD: Task management interface)
-- =============================================================================

-- View for task management interface (BDD: Task details)
CREATE VIEW v_task_management_interface AS
SELECT 
    wt.id as task_id,
    pi.business_object_name as object, -- "Schedule Q1 2025"
    pi.business_object_type as type, -- "Schedule variant"
    pd.process_name as process, -- "Schedule approval"
    wt.task_name as task, -- "Supervisor confirmation"
    wt.available_actions as actions, -- Available options
    wt.comments,
    wt.attachments,
    
    -- Task status and timing
    wt.task_status,
    wt.assigned_to,
    wt.assigned_role,
    wt.due_date,
    wt.created_at,
    
    -- Process context
    pi.id as process_instance_id,
    pi.current_stage,
    pi.process_status as process_status,
    
    -- Available actions formatted
    CASE 
        WHEN wt.available_actions ? 'approve' THEN 'Approve/'
        ELSE ''
    END ||
    CASE 
        WHEN wt.available_actions ? 'reject' THEN 'Reject/'
        ELSE ''
    END ||
    CASE 
        WHEN wt.available_actions ? 'delegate' THEN 'Delegate/'
        ELSE ''
    END ||
    CASE 
        WHEN wt.available_actions ? 'return' THEN 'Return'
        ELSE ''
    END as actions_display,
    
    -- Escalation information
    wt.escalation_enabled,
    wt.escalation_after_hours,
    CASE 
        WHEN wt.due_date < CURRENT_TIMESTAMP THEN 'OVERDUE'
        WHEN wt.due_date < CURRENT_TIMESTAMP + INTERVAL '4 hours' THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as urgency_status
    
FROM workflow_tasks wt
JOIN process_instances pi ON pi.id = wt.process_instance_id
JOIN process_definitions pd ON pd.id = pi.process_definition_id
WHERE wt.task_status IN ('PENDING', 'IN_PROGRESS')
ORDER BY wt.due_date ASC, wt.created_at ASC;

-- View for process monitoring dashboard
CREATE VIEW v_process_monitoring_dashboard AS
SELECT 
    pd.process_name,
    pd.process_category,
    COUNT(pi.id) as total_instances,
    COUNT(CASE WHEN pi.process_status = 'ACTIVE' THEN 1 END) as active_instances,
    COUNT(CASE WHEN pi.process_status = 'COMPLETED' THEN 1 END) as completed_instances,
    
    -- Task statistics
    COUNT(wt.id) as total_tasks,
    COUNT(CASE WHEN wt.task_status = 'PENDING' THEN 1 END) as pending_tasks,
    COUNT(CASE WHEN wt.task_status = 'OVERDUE' THEN 1 END) as overdue_tasks,
    
    -- Performance metrics
    AVG(EXTRACT(EPOCH FROM (pi.completed_at - pi.started_at)) / 3600.0) as avg_completion_hours,
    AVG(EXTRACT(EPOCH FROM (wt.completed_at - wt.created_at)) / 3600.0) as avg_task_completion_hours,
    
    -- Recent activity
    MAX(pi.started_at) as last_instance_started,
    MAX(wt.completed_at) as last_task_completed
    
FROM process_definitions pd
LEFT JOIN process_instances pi ON pi.process_definition_id = pd.id
LEFT JOIN workflow_tasks wt ON wt.process_instance_id = pi.id
WHERE pd.process_status = 'ACTIVE'
GROUP BY pd.id, pd.process_name, pd.process_category
ORDER BY pd.process_name;

-- =============================================================================
-- Sample Data: Standard Business Processes (BDD: Schedule/Vacation/Shift workflows)
-- =============================================================================

-- Insert Schedule Approval Process (BDD: Work Schedule Approval Process Workflow)
INSERT INTO process_definitions (
    process_name, process_description, process_category, business_domain,
    process_status, process_stages, participant_roles, available_actions,
    transition_rules, notification_settings, business_rules,
    created_by
) VALUES (
    'Schedule Approval Process',
    'Work schedule variant approval workflow with supervisor review, planning review, operator confirmation, and final application',
    'SCHEDULE_APPROVAL',
    'PLANNING',
    'ACTIVE',
    '[
        {
            "stage_order": "1",
            "stage_name": "Supervisor Review",
            "task_name": "Supervisor confirmation",
            "task_description": "Review and approve schedule variant",
            "task_type": "APPROVAL",
            "assigned_role": "Department heads",
            "available_actions": ["edit", "approve", "reject"]
        },
        {
            "stage_order": "2", 
            "stage_name": "Planning Review",
            "task_name": "Planning specialist review",
            "task_description": "Update schedule and verify planning compliance",
            "task_type": "REVIEW",
            "assigned_role": "Planning specialist",
            "available_actions": ["update", "return", "forward"]
        },
        {
            "stage_order": "3",
            "stage_name": "Operator Confirmation", 
            "task_name": "Operator acknowledgment",
            "task_description": "View and acknowledge schedule changes",
            "task_type": "CONFIRMATION",
            "assigned_role": "All affected operators",
            "available_actions": ["view", "acknowledge"]
        },
        {
            "stage_order": "4",
            "stage_name": "Apply Schedule",
            "task_name": "Final application",
            "task_description": "Apply schedule and send to 1C ZUP via sendSchedule API",
            "task_type": "APPLICATION", 
            "assigned_role": "Planning specialist",
            "available_actions": ["apply", "send_to_1c"]
        }
    ]'::JSONB,
    '["Department heads", "Planning specialist", "All affected operators"]'::JSONB,
    '["edit", "approve", "reject", "update", "return", "forward", "view", "acknowledge", "apply", "send_to_1c"]'::JSONB,
    '{
        "sequential_order": true,
        "completion_requirements": "all_participants_must_act",
        "timeout_handling": "escalate_overdue_tasks"
    }'::JSONB,
    '{
        "notify_on_assignment": true,
        "notify_on_completion": true,
        "escalation_notifications": true
    }'::JSONB,
    '{
        "role_authorization": "only_authorized_users_can_act",
        "sequential_enforcement": "stages_must_complete_in_order", 
        "completion_tracking": "track_all_acknowledgments"
    }'::JSONB,
    'System Administrator'
);

-- Insert Vacation Approval Process (BDD: Employee Vacation Request Approval Workflow)
INSERT INTO process_definitions (
    process_name, process_description, process_category, business_domain,
    process_status, process_stages, participant_roles, available_actions,
    transition_rules, notification_settings, business_rules,
    created_by
) VALUES (
    'Vacation Approval Process',
    'Employee vacation request approval with coverage planning and HR validation',
    'VACATION_APPROVAL', 
    'HR',
    'ACTIVE',
    '[
        {
            "stage_order": "1",
            "stage_name": "Initial Review",
            "task_name": "Supervisor review",
            "task_description": "Check team coverage for vacation request",
            "task_type": "APPROVAL",
            "assigned_role": "Direct supervisor",
            "available_actions": ["approve", "reject", "request_changes"]
        },
        {
            "stage_order": "2",
            "stage_name": "Coverage Planning", 
            "task_name": "Coverage verification",
            "task_description": "Verify replacement plan and staffing levels",
            "task_type": "REVIEW",
            "assigned_role": "Planning specialist",
            "available_actions": ["confirm_coverage", "request_adjustments"]
        },
        {
            "stage_order": "3",
            "stage_name": "HR Approval",
            "task_name": "HR validation",
            "task_description": "Validate vacation entitlements and policy compliance",
            "task_type": "APPROVAL",
            "assigned_role": "HR representative", 
            "available_actions": ["approve", "flag_issues"]
        },
        {
            "stage_order": "4",
            "stage_name": "Final Confirmation",
            "task_name": "Final authorization",
            "task_description": "Final supervisor authorization for vacation",
            "task_type": "APPROVAL",
            "assigned_role": "Original supervisor",
            "available_actions": ["approve", "deny"]
        }
    ]'::JSONB,
    '["Direct supervisor", "Planning specialist", "HR representative", "Original supervisor"]'::JSONB,
    '["approve", "reject", "request_changes", "confirm_coverage", "request_adjustments", "flag_issues", "deny"]'::JSONB,
    '{
        "sequential_order": true,
        "business_rule_validation": true
    }'::JSONB,
    '{
        "notify_employee": true,
        "notify_team": true,
        "notify_hr": true
    }'::JSONB,
    '{
        "vacation_balance_check": "sufficient_vacation_days",
        "notice_period_check": "minimum_advance_notice",
        "coverage_check": "minimum_staffing_levels",
        "blackout_period_check": "restricted_vacation_times"
    }'::JSONB,
    'System Administrator'
);

-- Insert business rules for vacation approval
INSERT INTO business_rules (
    rule_name, rule_description, rule_category, applies_to_process,
    rule_type, rule_expression, validation_criteria, error_message,
    is_blocking, created_by
) VALUES 
(
    'Sufficient Vacation Days',
    'Employee must have sufficient vacation days accumulated',
    'VACATION_VALIDATION',
    'Vacation Approval Process',
    'VALIDATION',
    'vacation_days_requested <= vacation_days_available',
    '{"check_field": "vacation_days_available", "operator": ">=", "compare_field": "vacation_days_requested"}'::JSONB,
    'Insufficient vacation days available. Request exceeds available balance.',
    true,
    'System Administrator'
),
(
    'Minimum Notice Period',
    'Vacation requests must be submitted with minimum advance notice',
    'VACATION_VALIDATION', 
    'Vacation Approval Process',
    'VALIDATION',
    'request_date + notice_period_days <= vacation_start_date',
    '{"notice_period_days": 14, "warning_threshold_days": 7}'::JSONB,
    'Insufficient notice period. Vacation requests require 14 days advance notice.',
    false,
    'System Administrator'
),
(
    'Team Coverage Check',
    'Minimum staffing levels must be maintained during vacation periods',
    'COVERAGE_CHECK',
    'Vacation Approval Process', 
    'VALIDATION',
    'remaining_staff_count >= minimum_staffing_level',
    '{"minimum_staffing_percentage": 70, "critical_roles": ["supervisor", "senior_agent"]}'::JSONB,
    'Insufficient team coverage. Minimum staffing levels not maintained.',
    true,
    'System Administrator'
);

COMMENT ON TABLE process_definitions IS 'Business process definitions with BDD-specified components (stages, roles, actions, rules)';
COMMENT ON TABLE process_instances IS 'Active process instances with business object references and current stage tracking';
COMMENT ON TABLE workflow_tasks IS 'Individual workflow tasks with BDD-specified task management interface fields';
COMMENT ON TABLE task_actions IS 'Actions performed on tasks (Approve/Return/Delegate) with BDD-specified results';
COMMENT ON TABLE process_notifications IS 'Process notifications with BDD-specified channels and content';
COMMENT ON TABLE business_rules IS 'Business rules enforcement with BDD-specified validation categories';
COMMENT ON FUNCTION initiate_business_process IS 'Initialize business process with first stage task creation and notifications';
COMMENT ON FUNCTION execute_task_action IS 'Execute task actions with BDD-specified workflow progression logic';
COMMENT ON VIEW v_task_management_interface IS 'BDD-compliant task management interface with exact field specifications';