-- Schema 127: Comprehensive Workflow & Business Process Management Engine
-- Based on BDD scenarios from 13-business-process-management-workflows.feature and 04-requests-section-detailed.feature
-- Implements 42 critical workflow tables for complete workflow automation

-- Drop existing tables if they exist
DROP TABLE IF EXISTS workflow_audit_trail CASCADE;
DROP TABLE IF EXISTS workflow_metrics CASCADE;
DROP TABLE IF EXISTS workflow_performance_stats CASCADE;
DROP TABLE IF EXISTS process_task_dependencies CASCADE;
DROP TABLE IF EXISTS process_task_assignments CASCADE;
DROP TABLE IF EXISTS process_events CASCADE;
DROP TABLE IF EXISTS process_tasks CASCADE;
DROP TABLE IF EXISTS process_instances CASCADE;
DROP TABLE IF EXISTS process_definitions CASCADE;
DROP TABLE IF EXISTS rule_exceptions CASCADE;
DROP TABLE IF EXISTS rule_actions CASCADE;
DROP TABLE IF EXISTS rule_conditions CASCADE;
DROP TABLE IF EXISTS business_rules CASCADE;
DROP TABLE IF EXISTS escalation_history CASCADE;
DROP TABLE IF EXISTS escalation_rules CASCADE;
DROP TABLE IF EXISTS approval_notifications CASCADE;
DROP TABLE IF EXISTS approval_delegates CASCADE;
DROP TABLE IF EXISTS approval_history CASCADE;
DROP TABLE IF EXISTS approval_tasks CASCADE;
DROP TABLE IF EXISTS approval_chains CASCADE;
DROP TABLE IF EXISTS approval_rules CASCADE;
DROP TABLE IF EXISTS workflow_task_assignments CASCADE;
DROP TABLE IF EXISTS workflow_task_comments CASCADE;
DROP TABLE IF EXISTS workflow_task_attachments CASCADE;
DROP TABLE IF EXISTS workflow_tasks CASCADE;
DROP TABLE IF EXISTS workflow_transition_history CASCADE;
DROP TABLE IF EXISTS workflow_transitions CASCADE;
DROP TABLE IF EXISTS workflow_state_configurations CASCADE;
DROP TABLE IF EXISTS workflow_states CASCADE;
DROP TABLE IF EXISTS workflow_instance_data CASCADE;
DROP TABLE IF EXISTS workflow_instances CASCADE;
DROP TABLE IF EXISTS workflow_participant_roles CASCADE;
DROP TABLE IF EXISTS workflow_definitions CASCADE;
DROP TABLE IF EXISTS workflow_categories CASCADE;
DROP TABLE IF EXISTS workflow_templates CASCADE;

-- Core workflow foundation tables

-- 1. Workflow Categories (Типы бизнес-процессов)
CREATE TABLE workflow_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    name_ru VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    description_ru TEXT,
    icon VARCHAR(50),
    color VARCHAR(7), -- Hex color code
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Workflow Templates (Шаблоны процессов)
CREATE TABLE workflow_templates (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES workflow_categories(id),
    name VARCHAR(200) NOT NULL,
    name_ru VARCHAR(200) NOT NULL,
    description TEXT,
    description_ru TEXT,
    template_config JSONB NOT NULL, -- Template configuration
    is_system_template BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Workflow Definitions (Определения процессов)
CREATE TABLE workflow_definitions (
    id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES workflow_templates(id),
    name VARCHAR(200) NOT NULL,
    name_ru VARCHAR(200) NOT NULL,
    description TEXT,
    description_ru TEXT,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    process_definition JSONB NOT NULL, -- Full process definition
    is_active BOOLEAN DEFAULT TRUE,
    effective_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name, version)
);

-- 4. Workflow Participant Roles (Роли участников)
CREATE TABLE workflow_participant_roles (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    role_name VARCHAR(100) NOT NULL,
    role_name_ru VARCHAR(100) NOT NULL,
    description TEXT,
    description_ru TEXT,
    permissions JSONB NOT NULL, -- Role permissions
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Workflow Instances (Экземпляры процессов)
CREATE TABLE workflow_instances (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    instance_name VARCHAR(200) NOT NULL,
    instance_name_ru VARCHAR(200) NOT NULL,
    current_state VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'SUSPENDED', 'COMPLETED', 'TERMINATED', 'ERROR')),
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10), -- 1=highest, 10=lowest
    initiated_by INTEGER REFERENCES employees(id),
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    due_date TIMESTAMP,
    context_data JSONB, -- Instance-specific data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Workflow Instance Data (Данные экземпляров)
CREATE TABLE workflow_instance_data (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    data_key VARCHAR(100) NOT NULL,
    data_value JSONB NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    is_sensitive BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workflow_instance_id, data_key)
);

-- 7. Workflow States (Состояния процесса)
CREATE TABLE workflow_states (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    state_name VARCHAR(100) NOT NULL,
    state_name_ru VARCHAR(100) NOT NULL,
    state_type VARCHAR(20) NOT NULL CHECK (state_type IN ('START', 'TASK', 'DECISION', 'PARALLEL', 'END')),
    description TEXT,
    description_ru TEXT,
    position_x INTEGER, -- For visual workflow designer
    position_y INTEGER,
    configuration JSONB, -- State-specific configuration
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workflow_definition_id, state_name)
);

-- 8. Workflow State Configurations (Конфигурации состояний)
CREATE TABLE workflow_state_configurations (
    id SERIAL PRIMARY KEY,
    workflow_state_id INTEGER REFERENCES workflow_states(id),
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    config_type VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workflow_state_id, config_key)
);

-- 9. Workflow Transitions (Переходы между состояниями)
CREATE TABLE workflow_transitions (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    from_state_id INTEGER REFERENCES workflow_states(id),
    to_state_id INTEGER REFERENCES workflow_states(id),
    transition_name VARCHAR(100) NOT NULL,
    transition_name_ru VARCHAR(100) NOT NULL,
    condition_expression TEXT, -- SQL or logic expression
    action_expression TEXT, -- Actions to execute
    is_default BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Workflow Transition History (История переходов)
CREATE TABLE workflow_transition_history (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    transition_id INTEGER REFERENCES workflow_transitions(id),
    from_state VARCHAR(100) NOT NULL,
    to_state VARCHAR(100) NOT NULL,
    executed_by INTEGER REFERENCES employees(id),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_context JSONB, -- Context data at transition time
    execution_result VARCHAR(20) NOT NULL CHECK (execution_result IN ('SUCCESS', 'FAILED', 'SKIPPED')),
    error_message TEXT
);

-- 11. Workflow Tasks (Задачи процесса)
CREATE TABLE workflow_tasks (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    workflow_state_id INTEGER REFERENCES workflow_states(id),
    task_name VARCHAR(200) NOT NULL,
    task_name_ru VARCHAR(200) NOT NULL,
    task_type VARCHAR(50) NOT NULL CHECK (task_type IN ('APPROVAL', 'REVIEW', 'NOTIFICATION', 'SYSTEM', 'MANUAL')),
    description TEXT,
    description_ru TEXT,
    assigned_to INTEGER REFERENCES employees(id),
    assigned_role VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ESCALATED')),
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    due_date TIMESTAMP,
    escalation_date TIMESTAMP,
    task_data JSONB, -- Task-specific data
    result_data JSONB, -- Task completion results
    completion_notes TEXT
);

-- 12. Workflow Task Attachments (Вложения задач)
CREATE TABLE workflow_task_attachments (
    id SERIAL PRIMARY KEY,
    workflow_task_id INTEGER REFERENCES workflow_tasks(id),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    file_type VARCHAR(100),
    mime_type VARCHAR(100),
    uploaded_by INTEGER REFERENCES employees(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 13. Workflow Task Comments (Комментарии к задачам)
CREATE TABLE workflow_task_comments (
    id SERIAL PRIMARY KEY,
    workflow_task_id INTEGER REFERENCES workflow_tasks(id),
    comment_text TEXT NOT NULL,
    comment_type VARCHAR(20) NOT NULL CHECK (comment_type IN ('COMMENT', 'APPROVAL', 'REJECTION', 'QUESTION', 'ANSWER')),
    is_internal BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    parent_comment_id INTEGER REFERENCES workflow_task_comments(id)
);

-- 14. Workflow Task Assignments (Назначения задач)
CREATE TABLE workflow_task_assignments (
    id SERIAL PRIMARY KEY,
    workflow_task_id INTEGER REFERENCES workflow_tasks(id),
    assigned_to INTEGER REFERENCES employees(id),
    assigned_by INTEGER REFERENCES employees(id),
    assignment_type VARCHAR(20) NOT NULL CHECK (assignment_type IN ('PRIMARY', 'DELEGATE', 'ESCALATION', 'PARALLEL')),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Approval system tables

-- 15. Approval Rules (Правила утверждения)
CREATE TABLE approval_rules (
    id SERIAL PRIMARY KEY,
    rule_name VARCHAR(200) NOT NULL,
    rule_name_ru VARCHAR(200) NOT NULL,
    entity_type VARCHAR(100) NOT NULL, -- What type of entity (schedule, request, etc.)
    condition_expression TEXT, -- When this rule applies
    approval_type VARCHAR(20) NOT NULL CHECK (approval_type IN ('SEQUENTIAL', 'PARALLEL', 'SINGLE', 'MAJORITY', 'UNANIMOUS')),
    escalation_timeout_hours INTEGER DEFAULT 24,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Approval Chains (Цепочки утверждения)
CREATE TABLE approval_chains (
    id SERIAL PRIMARY KEY,
    approval_rule_id INTEGER REFERENCES approval_rules(id),
    step_number INTEGER NOT NULL,
    step_name VARCHAR(200) NOT NULL,
    step_name_ru VARCHAR(200) NOT NULL,
    approver_type VARCHAR(20) NOT NULL CHECK (approver_type IN ('SPECIFIC_USER', 'ROLE', 'DEPARTMENT', 'DYNAMIC')),
    approver_id INTEGER REFERENCES employees(id), -- For SPECIFIC_USER
    approver_role VARCHAR(100), -- For ROLE
    approver_department INTEGER, -- For DEPARTMENT
    approver_expression TEXT, -- For DYNAMIC
    is_required BOOLEAN DEFAULT TRUE,
    can_delegate BOOLEAN DEFAULT TRUE,
    timeout_hours INTEGER DEFAULT 24,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(approval_rule_id, step_number)
);

-- 17. Approval Tasks (Задачи утверждения)
CREATE TABLE approval_tasks (
    id SERIAL PRIMARY KEY,
    approval_chain_id INTEGER REFERENCES approval_chains(id),
    entity_type VARCHAR(100) NOT NULL,
    entity_id INTEGER NOT NULL,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    assigned_to INTEGER REFERENCES employees(id),
    assigned_by INTEGER REFERENCES employees(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'DELEGATED', 'ESCALATED')),
    decision VARCHAR(20) CHECK (decision IN ('APPROVE', 'REJECT', 'REQUEST_CHANGES', 'DELEGATE')),
    decision_comment TEXT,
    decision_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    escalation_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 18. Approval History (История утверждений)
CREATE TABLE approval_history (
    id SERIAL PRIMARY KEY,
    approval_task_id INTEGER REFERENCES approval_tasks(id),
    previous_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    action_taken VARCHAR(100) NOT NULL,
    action_taken_ru VARCHAR(100) NOT NULL,
    performed_by INTEGER REFERENCES employees(id),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comments TEXT,
    additional_data JSONB
);

-- 19. Approval Delegates (Делегаты утверждения)
CREATE TABLE approval_delegates (
    id SERIAL PRIMARY KEY,
    delegator_id INTEGER REFERENCES employees(id),
    delegate_id INTEGER REFERENCES employees(id),
    delegation_type VARCHAR(20) NOT NULL CHECK (delegation_type IN ('TEMPORARY', 'PERMANENT', 'SPECIFIC_PROCESS', 'EMERGENCY')),
    effective_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP,
    workflow_types TEXT[], -- Array of workflow types for delegation
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 20. Approval Notifications (Уведомления утверждения)
CREATE TABLE approval_notifications (
    id SERIAL PRIMARY KEY,
    approval_task_id INTEGER REFERENCES approval_tasks(id),
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('EMAIL', 'SMS', 'PUSH', 'SYSTEM')),
    recipient_id INTEGER REFERENCES employees(id),
    subject VARCHAR(200),
    message TEXT,
    sent_at TIMESTAMP,
    delivery_status VARCHAR(20) DEFAULT 'PENDING' CHECK (delivery_status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Business Rules Engine

-- 21. Business Rules (Бизнес-правила)
CREATE TABLE business_rules (
    id SERIAL PRIMARY KEY,
    rule_name VARCHAR(200) NOT NULL,
    rule_name_ru VARCHAR(200) NOT NULL,
    rule_category VARCHAR(100) NOT NULL,
    rule_type VARCHAR(20) NOT NULL CHECK (rule_type IN ('VALIDATION', 'CONSTRAINT', 'CALCULATION', 'NOTIFICATION', 'ESCALATION')),
    description TEXT,
    description_ru TEXT,
    rule_expression TEXT NOT NULL, -- SQL or business logic expression
    error_message TEXT,
    error_message_ru TEXT,
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    is_active BOOLEAN DEFAULT TRUE,
    effective_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 22. Rule Conditions (Условия правил)
CREATE TABLE rule_conditions (
    id SERIAL PRIMARY KEY,
    business_rule_id INTEGER REFERENCES business_rules(id),
    condition_name VARCHAR(100) NOT NULL,
    condition_expression TEXT NOT NULL,
    condition_type VARCHAR(20) NOT NULL CHECK (condition_type IN ('PRECONDITION', 'POSTCONDITION', 'TRIGGER')),
    logical_operator VARCHAR(10) DEFAULT 'AND' CHECK (logical_operator IN ('AND', 'OR', 'NOT')),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 23. Rule Actions (Действия правил)
CREATE TABLE rule_actions (
    id SERIAL PRIMARY KEY,
    business_rule_id INTEGER REFERENCES business_rules(id),
    action_name VARCHAR(100) NOT NULL,
    action_name_ru VARCHAR(100) NOT NULL,
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('EXECUTE', 'NOTIFY', 'ESCALATE', 'BLOCK', 'TRANSFORM')),
    action_expression TEXT NOT NULL,
    action_parameters JSONB,
    execution_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 24. Rule Exceptions (Исключения правил)
CREATE TABLE rule_exceptions (
    id SERIAL PRIMARY KEY,
    business_rule_id INTEGER REFERENCES business_rules(id),
    entity_type VARCHAR(100) NOT NULL,
    entity_id INTEGER NOT NULL,
    exception_reason TEXT NOT NULL,
    exception_reason_ru TEXT NOT NULL,
    granted_by INTEGER REFERENCES employees(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Process Management

-- 25. Process Definitions (Определения процессов)
CREATE TABLE process_definitions (
    id SERIAL PRIMARY KEY,
    process_name VARCHAR(200) NOT NULL,
    process_name_ru VARCHAR(200) NOT NULL,
    process_type VARCHAR(50) NOT NULL,
    description TEXT,
    description_ru TEXT,
    process_schema JSONB NOT NULL, -- Process definition schema
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(process_name, version)
);

-- 26. Process Instances (Экземпляры процессов)
CREATE TABLE process_instances (
    id SERIAL PRIMARY KEY,
    process_definition_id INTEGER REFERENCES process_definitions(id),
    instance_name VARCHAR(200) NOT NULL,
    instance_name_ru VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('RUNNING', 'SUSPENDED', 'COMPLETED', 'TERMINATED', 'ERROR')),
    current_step VARCHAR(100),
    initiated_by INTEGER REFERENCES employees(id),
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    process_data JSONB, -- Instance-specific data
    error_log TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 27. Process Tasks (Задачи процесса)
CREATE TABLE process_tasks (
    id SERIAL PRIMARY KEY,
    process_instance_id INTEGER REFERENCES process_instances(id),
    task_name VARCHAR(200) NOT NULL,
    task_name_ru VARCHAR(200) NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    description TEXT,
    description_ru TEXT,
    assigned_to INTEGER REFERENCES employees(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    due_date TIMESTAMP,
    task_data JSONB,
    result_data JSONB
);

-- 28. Process Events (События процесса)
CREATE TABLE process_events (
    id SERIAL PRIMARY KEY,
    process_instance_id INTEGER REFERENCES process_instances(id),
    event_name VARCHAR(100) NOT NULL,
    event_name_ru VARCHAR(100) NOT NULL,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('START', 'END', 'INTERMEDIATE', 'BOUNDARY', 'ERROR')),
    event_data JSONB,
    triggered_by INTEGER REFERENCES employees(id),
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    handled_at TIMESTAMP,
    is_handled BOOLEAN DEFAULT FALSE
);

-- 29. Process Task Assignments (Назначения задач процесса)
CREATE TABLE process_task_assignments (
    id SERIAL PRIMARY KEY,
    process_task_id INTEGER REFERENCES process_tasks(id),
    assigned_to INTEGER REFERENCES employees(id),
    assigned_by INTEGER REFERENCES employees(id),
    assignment_type VARCHAR(20) NOT NULL CHECK (assignment_type IN ('PRIMARY', 'DELEGATE', 'ESCALATION')),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 30. Process Task Dependencies (Зависимости задач)
CREATE TABLE process_task_dependencies (
    id SERIAL PRIMARY KEY,
    predecessor_task_id INTEGER REFERENCES process_tasks(id),
    successor_task_id INTEGER REFERENCES process_tasks(id),
    dependency_type VARCHAR(20) NOT NULL CHECK (dependency_type IN ('FINISH_TO_START', 'START_TO_START', 'FINISH_TO_FINISH', 'START_TO_FINISH')),
    lag_time_hours INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(predecessor_task_id, successor_task_id)
);

-- Escalation Management

-- 31. Escalation Rules (Правила эскалации)
CREATE TABLE escalation_rules (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(100) NOT NULL,
    rule_name VARCHAR(200) NOT NULL,
    rule_name_ru VARCHAR(200) NOT NULL,
    condition_expression TEXT NOT NULL,
    escalation_level INTEGER NOT NULL CHECK (escalation_level BETWEEN 1 AND 5),
    timeout_hours INTEGER NOT NULL,
    escalation_action VARCHAR(20) NOT NULL CHECK (escalation_action IN ('NOTIFY', 'REASSIGN', 'ESCALATE_TO_MANAGER', 'EMERGENCY_OVERRIDE')),
    target_role VARCHAR(100),
    target_user_id INTEGER REFERENCES employees(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 32. Escalation History (История эскалации)
CREATE TABLE escalation_history (
    id SERIAL PRIMARY KEY,
    escalation_rule_id INTEGER REFERENCES escalation_rules(id),
    entity_type VARCHAR(100) NOT NULL,
    entity_id INTEGER NOT NULL,
    escalation_level INTEGER NOT NULL,
    escalated_from INTEGER REFERENCES employees(id),
    escalated_to INTEGER REFERENCES employees(id),
    escalation_reason TEXT NOT NULL,
    escalation_reason_ru TEXT NOT NULL,
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    is_resolved BOOLEAN DEFAULT FALSE
);

-- Workflow Audit and Metrics

-- 33. Workflow Performance Stats (Статистика производительности)
CREATE TABLE workflow_performance_stats (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    measurement_date DATE NOT NULL,
    total_instances INTEGER DEFAULT 0,
    completed_instances INTEGER DEFAULT 0,
    avg_completion_time_hours DECIMAL(10,2),
    median_completion_time_hours DECIMAL(10,2),
    escalation_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2), -- Percentage
    bottleneck_state VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workflow_definition_id, measurement_date)
);

-- 34. Workflow Metrics (Метрики процессов)
CREATE TABLE workflow_metrics (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,6) NOT NULL,
    metric_unit VARCHAR(20),
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    measurement_context JSONB
);

-- 35. Workflow Audit Trail (Аудиторский след)
CREATE TABLE workflow_audit_trail (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    audit_event VARCHAR(50) NOT NULL,
    audit_event_ru VARCHAR(50) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id INTEGER,
    old_value JSONB,
    new_value JSONB,
    performed_by INTEGER REFERENCES employees(id),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    additional_info JSONB
);

-- Specialized workflow support tables

-- 36. Workflow Integration Points (Точки интеграции)
CREATE TABLE workflow_integration_points (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    integration_name VARCHAR(100) NOT NULL,
    integration_type VARCHAR(20) NOT NULL CHECK (integration_type IN ('API', 'DATABASE', 'FILE', 'EMAIL', 'WEBHOOK')),
    endpoint_url VARCHAR(500),
    configuration JSONB NOT NULL,
    authentication_method VARCHAR(20) CHECK (authentication_method IN ('NONE', 'BASIC', 'BEARER', 'OAUTH2', 'API_KEY')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 37. Workflow Notifications (Уведомления процесса)
CREATE TABLE workflow_notifications (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('EMAIL', 'SMS', 'PUSH', 'SYSTEM')),
    recipient_id INTEGER REFERENCES employees(id),
    subject VARCHAR(200),
    message TEXT,
    template_name VARCHAR(100),
    template_data JSONB,
    sent_at TIMESTAMP,
    delivery_status VARCHAR(20) DEFAULT 'PENDING' CHECK (delivery_status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 38. Workflow Parallel Tasks (Параллельные задачи)
CREATE TABLE workflow_parallel_tasks (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    parallel_group_id UUID NOT NULL,
    task_id INTEGER REFERENCES workflow_tasks(id),
    completion_requirement VARCHAR(20) NOT NULL CHECK (completion_requirement IN ('ALL', 'MAJORITY', 'ANY', 'QUORUM')),
    quorum_count INTEGER,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 39. Workflow Emergency Overrides (Экстренные переопределения)
CREATE TABLE workflow_emergency_overrides (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    override_type VARCHAR(20) NOT NULL CHECK (override_type IN ('SKIP_STEP', 'COMPLETE_WORKFLOW', 'ESCALATE_IMMEDIATELY', 'CANCEL_WORKFLOW')),
    justification TEXT NOT NULL,
    justification_ru TEXT NOT NULL,
    authorized_by INTEGER REFERENCES employees(id),
    authorized_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    emergency_level INTEGER CHECK (emergency_level BETWEEN 1 AND 5),
    affected_tasks INTEGER[] -- Array of task IDs affected
);

-- 40. Workflow Compliance Reports (Отчеты соответствия)
CREATE TABLE workflow_compliance_reports (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    compliance_type VARCHAR(100) NOT NULL,
    compliance_result VARCHAR(20) NOT NULL CHECK (compliance_result IN ('COMPLIANT', 'NON_COMPLIANT', 'PARTIALLY_COMPLIANT', 'PENDING_REVIEW')),
    violations JSONB, -- Array of violations found
    recommendations JSONB, -- Array of recommendations
    assessed_by INTEGER REFERENCES employees(id),
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    next_review_date DATE
);

-- 41. Workflow SLA Tracking (Отслеживание SLA)
CREATE TABLE workflow_sla_tracking (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER REFERENCES workflow_instances(id),
    sla_metric VARCHAR(100) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    actual_value DECIMAL(10,2),
    measurement_unit VARCHAR(20) NOT NULL,
    is_met BOOLEAN,
    violation_reason TEXT,
    violation_reason_ru TEXT,
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 42. Workflow Custom Fields (Пользовательские поля)
CREATE TABLE workflow_custom_fields (
    id SERIAL PRIMARY KEY,
    workflow_definition_id INTEGER REFERENCES workflow_definitions(id),
    field_name VARCHAR(100) NOT NULL,
    field_name_ru VARCHAR(100) NOT NULL,
    field_type VARCHAR(20) NOT NULL CHECK (field_type IN ('TEXT', 'NUMBER', 'DATE', 'BOOLEAN', 'SELECT', 'MULTISELECT', 'FILE')),
    field_options JSONB, -- For SELECT/MULTISELECT types
    is_required BOOLEAN DEFAULT FALSE,
    default_value TEXT,
    validation_rules TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workflow_definition_id, field_name)
);

-- Indexes for performance optimization

-- Core workflow indexes
CREATE INDEX idx_workflow_instances_status ON workflow_instances(status);
CREATE INDEX idx_workflow_instances_current_state ON workflow_instances(current_state);
CREATE INDEX idx_workflow_instances_definition_id ON workflow_instances(workflow_definition_id);
CREATE INDEX idx_workflow_instances_initiated_by ON workflow_instances(initiated_by);
CREATE INDEX idx_workflow_instances_due_date ON workflow_instances(due_date);

-- Task-related indexes
CREATE INDEX idx_workflow_tasks_instance_id ON workflow_tasks(workflow_instance_id);
CREATE INDEX idx_workflow_tasks_assigned_to ON workflow_tasks(assigned_to);
CREATE INDEX idx_workflow_tasks_status ON workflow_tasks(status);
CREATE INDEX idx_workflow_tasks_due_date ON workflow_tasks(due_date);
CREATE INDEX idx_workflow_tasks_escalation_date ON workflow_tasks(escalation_date);

-- Approval system indexes
CREATE INDEX idx_approval_tasks_assigned_to ON approval_tasks(assigned_to);
CREATE INDEX idx_approval_tasks_status ON approval_tasks(status);
CREATE INDEX idx_approval_tasks_entity ON approval_tasks(entity_type, entity_id);
CREATE INDEX idx_approval_tasks_due_date ON approval_tasks(due_date);

-- Audit and performance indexes
CREATE INDEX idx_workflow_audit_trail_instance_id ON workflow_audit_trail(workflow_instance_id);
CREATE INDEX idx_workflow_audit_trail_performed_by ON workflow_audit_trail(performed_by);
CREATE INDEX idx_workflow_audit_trail_performed_at ON workflow_audit_trail(performed_at);

-- JSONB indexes for efficient queries
CREATE INDEX idx_workflow_instances_context_data ON workflow_instances USING GIN (context_data);
CREATE INDEX idx_workflow_tasks_task_data ON workflow_tasks USING GIN (task_data);
CREATE INDEX idx_workflow_instance_data_value ON workflow_instance_data USING GIN (data_value);

-- Composite indexes for common queries
CREATE INDEX idx_workflow_tasks_assigned_status ON workflow_tasks(assigned_to, status);
CREATE INDEX idx_approval_tasks_entity_status ON approval_tasks(entity_type, entity_id, status);
CREATE INDEX idx_workflow_instances_def_status ON workflow_instances(workflow_definition_id, status);

-- Insert initial workflow categories
INSERT INTO workflow_categories (name, name_ru, description, description_ru, icon, color, sort_order) VALUES
('Schedule Management', 'Управление расписанием', 'Workflow for schedule approval and management', 'Процессы утверждения и управления расписанием', 'schedule', '#4CAF50', 1),
('Employee Requests', 'Заявки сотрудников', 'Employee request processing workflows', 'Процессы обработки заявок сотрудников', 'request', '#2196F3', 2),
('Vacation Management', 'Управление отпусками', 'Vacation request and planning workflows', 'Процессы заявок и планирования отпусков', 'vacation', '#FF9800', 3),
('Shift Exchange', 'Обмен сменами', 'Shift exchange approval workflows', 'Процессы утверждения обмена сменами', 'exchange', '#9C27B0', 4),
('Administrative', 'Административные', 'Administrative and system workflows', 'Административные и системные процессы', 'admin', '#607D8B', 5);

-- Insert workflow templates for schedule approval
INSERT INTO workflow_templates (category_id, name, name_ru, description, description_ru, template_config, is_system_template, created_by) VALUES
(1, 'Schedule Approval Workflow', 'Процесс утверждения расписания', 'Standard workflow for schedule approval', 'Стандартный процесс утверждения расписания', 
'{"stages": ["supervisor_review", "planning_review", "operator_confirmation", "final_application"], "timeout_hours": 24, "escalation_levels": 3}', 
TRUE, 1),
(2, 'Employee Request Workflow', 'Процесс обработки заявок', 'Standard workflow for employee requests', 'Стандартный процесс обработки заявок сотрудников',
'{"stages": ["initial_review", "approval", "implementation"], "timeout_hours": 48, "escalation_levels": 2}',
TRUE, 1),
(3, 'Vacation Approval Workflow', 'Процесс утверждения отпуска', 'Standard workflow for vacation requests', 'Стандартный процесс утверждения отпусков',
'{"stages": ["supervisor_approval", "coverage_planning", "hr_approval", "final_confirmation"], "timeout_hours": 72, "escalation_levels": 3}',
TRUE, 1);

-- Insert sample business rules
INSERT INTO business_rules (rule_name, rule_name_ru, rule_category, rule_type, description, description_ru, rule_expression, error_message, error_message_ru, created_by) VALUES
('Schedule Coverage Check', 'Проверка покрытия расписания', 'Schedule', 'VALIDATION', 'Ensure minimum staffing levels are maintained', 'Обеспечить минимальные уровни персонала', 
'coverage_ratio >= 0.8', 'Coverage ratio must be at least 80%', 'Коэффициент покрытия должен быть не менее 80%', 1),
('Vacation Balance Check', 'Проверка баланса отпуска', 'Vacation', 'VALIDATION', 'Verify employee has sufficient vacation days', 'Проверить достаточность дней отпуска', 
'vacation_balance >= requested_days', 'Insufficient vacation balance', 'Недостаточный баланс отпуска', 1),
('Overtime Compliance', 'Соответствие сверхурочным', 'Schedule', 'CONSTRAINT', 'Ensure overtime regulations are met', 'Обеспечить соблюдение норм сверхурочных', 
'weekly_hours <= 40 + max_overtime', 'Weekly hours exceed maximum allowed', 'Недельные часы превышают максимально разрешенные', 1);

-- Insert sample escalation rules
INSERT INTO escalation_rules (entity_type, rule_name, rule_name_ru, condition_expression, escalation_level, timeout_hours, escalation_action, target_role, created_by) VALUES
('workflow_task', 'Task Overdue Level 1', 'Просроченная задача уровень 1', 'due_date < CURRENT_TIMESTAMP - INTERVAL ''24 hours''', 1, 24, 'NOTIFY', 'supervisor', 1),
('workflow_task', 'Task Overdue Level 2', 'Просроченная задача уровень 2', 'due_date < CURRENT_TIMESTAMP - INTERVAL ''48 hours''', 2, 48, 'ESCALATE_TO_MANAGER', 'manager', 1),
('approval_task', 'Approval Overdue', 'Просроченное утверждение', 'due_date < CURRENT_TIMESTAMP - INTERVAL ''72 hours''', 3, 72, 'REASSIGN', 'backup_approver', 1);

-- Insert sample workflow definition for schedule approval
INSERT INTO workflow_definitions (template_id, name, name_ru, description, description_ru, version, process_definition, created_by) VALUES
(1, 'Schedule Approval Process v1.0', 'Процесс утверждения расписания v1.0', 'Complete schedule approval workflow', 'Полный процесс утверждения расписания', '1.0',
'{"states": [
    {"name": "supervisor_review", "name_ru": "Проверка руководителя", "type": "TASK", "participants": ["department_head"], "actions": ["approve", "reject", "request_changes"]},
    {"name": "planning_review", "name_ru": "Проверка планирования", "type": "TASK", "participants": ["planning_specialist"], "actions": ["update", "return", "forward"]},
    {"name": "operator_confirmation", "name_ru": "Подтверждение операторов", "type": "PARALLEL", "participants": ["affected_operators"], "actions": ["acknowledge"]},
    {"name": "final_application", "name_ru": "Финальное применение", "type": "TASK", "participants": ["planning_specialist"], "actions": ["apply", "send_to_1c"]}
], "transitions": [
    {"from": "supervisor_review", "to": "planning_review", "condition": "decision = ''approved''"},
    {"from": "planning_review", "to": "operator_confirmation", "condition": "decision = ''forwarded''"},
    {"from": "operator_confirmation", "to": "final_application", "condition": "all_acknowledged = true"}
]}', 1);

-- Insert workflow states for the schedule approval process
INSERT INTO workflow_states (workflow_definition_id, state_name, state_name_ru, state_type, description, description_ru, position_x, position_y, configuration) VALUES
(1, 'supervisor_review', 'Проверка руководителя', 'TASK', 'Supervisor reviews schedule variant', 'Руководитель проверяет вариант расписания', 100, 100, '{"timeout_hours": 24, "escalation_level": 1}'),
(1, 'planning_review', 'Проверка планирования', 'TASK', 'Planning specialist reviews and updates', 'Специалист по планированию проверяет и обновляет', 300, 100, '{"timeout_hours": 48, "escalation_level": 2}'),
(1, 'operator_confirmation', 'Подтверждение операторов', 'PARALLEL', 'All operators acknowledge schedule', 'Все операторы подтверждают расписание', 500, 100, '{"completion_requirement": "ALL", "timeout_hours": 72}'),
(1, 'final_application', 'Финальное применение', 'TASK', 'Apply schedule and send to 1C ZUP', 'Применить расписание и отправить в 1С ЗУП', 700, 100, '{"integration_required": true, "api_endpoint": "sendSchedule"}');

-- Insert workflow transitions
INSERT INTO workflow_transitions (workflow_definition_id, from_state_id, to_state_id, transition_name, transition_name_ru, condition_expression, action_expression, is_default, sort_order) VALUES
(1, 1, 2, 'Approve and Forward', 'Утвердить и переслать', 'decision = ''approved''', 'notify_next_participant', FALSE, 1),
(1, 2, 3, 'Forward to Operators', 'Переслать операторам', 'decision = ''forwarded''', 'create_parallel_tasks', FALSE, 1),
(1, 3, 4, 'All Acknowledged', 'Все подтвердили', 'all_participants_completed = true', 'prepare_final_application', FALSE, 1),
(1, 1, 1, 'Request Changes', 'Запросить изменения', 'decision = ''request_changes''', 'return_to_creator', FALSE, 2),
(1, 2, 1, 'Return to Supervisor', 'Вернуть руководителю', 'decision = ''return''', 'notify_supervisor', FALSE, 2);

-- Insert sample approval rules
INSERT INTO approval_rules (rule_name, rule_name_ru, entity_type, condition_expression, approval_type, escalation_timeout_hours, created_by) VALUES
('Schedule Approval Rule', 'Правило утверждения расписания', 'schedule', 'schedule_type = ''monthly''', 'SEQUENTIAL', 24, 1),
('Vacation Request Rule', 'Правило заявки на отпуск', 'vacation_request', 'vacation_days > 0', 'SEQUENTIAL', 48, 1),
('Shift Exchange Rule', 'Правило обмена сменами', 'shift_exchange', 'both_employees_agree = true', 'PARALLEL', 72, 1);

-- Insert approval chains
INSERT INTO approval_chains (approval_rule_id, step_number, step_name, step_name_ru, approver_type, approver_role, is_required, can_delegate, timeout_hours) VALUES
(1, 1, 'Supervisor Review', 'Проверка руководителя', 'ROLE', 'department_head', TRUE, TRUE, 24),
(1, 2, 'Planning Specialist Review', 'Проверка специалиста по планированию', 'ROLE', 'planning_specialist', TRUE, TRUE, 48),
(1, 3, 'Final Authorization', 'Финальное утверждение', 'ROLE', 'department_manager', TRUE, FALSE, 24),
(2, 1, 'Direct Supervisor', 'Непосредственный руководитель', 'ROLE', 'supervisor', TRUE, TRUE, 24),
(2, 2, 'HR Representative', 'Представитель HR', 'ROLE', 'hr_specialist', TRUE, TRUE, 48),
(3, 1, 'Team Lead Review', 'Проверка руководителя группы', 'ROLE', 'team_lead', TRUE, TRUE, 24),
(3, 2, 'Schedule Validation', 'Проверка расписания', 'ROLE', 'planning_specialist', TRUE, TRUE, 48);

-- Add table comments for documentation
COMMENT ON TABLE workflow_definitions IS 'Определения бизнес-процессов и workflows';
COMMENT ON TABLE workflow_instances IS 'Активные экземпляры workflows';
COMMENT ON TABLE workflow_tasks IS 'Задачи в рамках workflows';
COMMENT ON TABLE approval_tasks IS 'Задачи утверждения';
COMMENT ON TABLE business_rules IS 'Бизнес-правила для автоматизации';
COMMENT ON TABLE escalation_rules IS 'Правила эскалации для просроченных задач';
COMMENT ON TABLE workflow_audit_trail IS 'Аудиторский след всех действий в workflows';

-- Performance optimization with additional indexes
CREATE INDEX idx_workflow_instances_priority ON workflow_instances(priority);
CREATE INDEX idx_workflow_tasks_type ON workflow_tasks(task_type);
CREATE INDEX idx_approval_tasks_workflow_id ON approval_tasks(workflow_instance_id);
CREATE INDEX idx_business_rules_category ON business_rules(rule_category);
CREATE INDEX idx_escalation_history_level ON escalation_history(escalation_level);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Success message
SELECT 'Schema 127: Comprehensive Workflow & Business Process Management Engine created successfully with 42 tables' AS status;