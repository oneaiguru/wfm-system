-- =====================================================================================
-- Schema 111: Advanced Workflow Engine (Tasks 6-10) - Non-conflicting Implementation
-- =====================================================================================
-- Complete workflow engine infrastructure working around existing table conflicts
-- =====================================================================================

-- Task 6: Advanced Workflow State Machines with JSONB configuration
CREATE TABLE wfm_workflow_definitions (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100) NOT NULL UNIQUE,
    workflow_type VARCHAR(50) NOT NULL, -- 'vacation', 'overtime', 'shift_exchange', 'absence', 'schedule_change'
    display_name_ru TEXT NOT NULL,
    description_ru TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- State machine configuration as JSONB
    state_machine_config JSONB NOT NULL, -- States, transitions, conditions
    
    -- Business rules and conditions
    business_rules JSONB NOT NULL DEFAULT '{}', -- Approval rules, validation rules
    
    -- Default configuration
    default_settings JSONB NOT NULL DEFAULT '{}', -- Default timeouts, escalation rules
    
    -- Metadata
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT chk_wfm_workflow_type CHECK (workflow_type IN (
        'vacation', 'overtime', 'shift_exchange', 'absence', 'schedule_change', 
        'training', 'performance_review', 'equipment_request', 'custom'
    ))
);

-- Index for performance
CREATE INDEX idx_wfm_workflow_definitions_type ON wfm_workflow_definitions(workflow_type);
CREATE INDEX idx_wfm_workflow_definitions_active ON wfm_workflow_definitions(is_active);
CREATE INDEX idx_wfm_workflow_definitions_name ON wfm_workflow_definitions(workflow_name);

-- State definitions for each workflow
CREATE TABLE wfm_workflow_states (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id) ON DELETE CASCADE,
    state_key VARCHAR(50) NOT NULL, -- 'draft', 'pending_supervisor', 'pending_hr', 'approved', 'rejected'
    state_name_ru TEXT NOT NULL,
    description_ru TEXT,
    state_type VARCHAR(20) NOT NULL, -- 'initial', 'intermediate', 'final', 'error'
    
    -- State configuration
    state_config JSONB NOT NULL DEFAULT '{}', -- Timeout settings, notifications, actions
    
    -- Display configuration
    color_code VARCHAR(7), -- Hex color for UI
    icon_name VARCHAR(50),
    sort_order INTEGER,
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(workflow_id, state_key),
    
    CONSTRAINT chk_wfm_state_type CHECK (state_type IN ('initial', 'intermediate', 'final', 'error'))
);

-- Index for performance
CREATE INDEX idx_wfm_workflow_states_workflow ON wfm_workflow_states(workflow_id);
CREATE INDEX idx_wfm_workflow_states_key ON wfm_workflow_states(workflow_id, state_key);

-- Task 7: Dynamic Approval Routing with Business Rules
CREATE TABLE wfm_approval_routing_rules (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id) ON DELETE CASCADE,
    rule_name VARCHAR(100) NOT NULL,
    rule_name_ru TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 100, -- Lower = higher priority
    
    -- Conditions when this rule applies
    conditions JSONB NOT NULL, -- Complex business logic conditions
    
    -- Approval chain definition
    approval_chain JSONB NOT NULL, -- Ordered list of approval steps
    
    -- Parallel approval configuration
    parallel_approval_config JSONB DEFAULT '{}',
    
    -- Escalation rules
    escalation_rules JSONB DEFAULT '{}',
    
    -- Special handling
    bypass_conditions JSONB DEFAULT '{}', -- When to bypass this rule
    delegation_rules JSONB DEFAULT '{}', -- Delegation handling
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_from DATE,
    effective_to DATE,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(workflow_id, rule_name)
);

-- Index for rule evaluation performance
CREATE INDEX idx_wfm_approval_routing_rules_workflow ON wfm_approval_routing_rules(workflow_id);
CREATE INDEX idx_wfm_approval_routing_rules_priority ON wfm_approval_routing_rules(workflow_id, priority);
CREATE INDEX idx_wfm_approval_routing_rules_active ON wfm_approval_routing_rules(is_active);

-- Task 8: Escalation Management with Time-based and Condition-based Rules
CREATE TABLE wfm_escalation_rules (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id) ON DELETE CASCADE,
    state_id INTEGER REFERENCES wfm_workflow_states(id) ON DELETE CASCADE, -- NULL = applies to all states
    escalation_name VARCHAR(100) NOT NULL,
    escalation_name_ru TEXT NOT NULL,
    
    -- Escalation triggers
    trigger_type VARCHAR(20) NOT NULL, -- 'time_based', 'condition_based', 'manual', 'external'
    
    -- Time-based escalation
    timeout_minutes INTEGER, -- Time before escalation
    business_hours_only BOOLEAN DEFAULT true,
    exclude_weekends BOOLEAN DEFAULT true,
    exclude_holidays BOOLEAN DEFAULT true,
    
    -- Condition-based escalation
    escalation_conditions JSONB DEFAULT '{}', -- Complex conditions for escalation
    
    -- Escalation actions
    escalation_actions JSONB NOT NULL, -- What to do when escalating
    
    -- Notification configuration
    notification_config JSONB DEFAULT '{}',
    
    -- Escalation levels (can chain escalations)
    escalation_level INTEGER NOT NULL DEFAULT 1,
    next_escalation_id INTEGER REFERENCES wfm_escalation_rules(id),
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    priority INTEGER NOT NULL DEFAULT 100,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_wfm_escalation_trigger CHECK (trigger_type IN (
        'time_based', 'condition_based', 'manual', 'external'
    ))
);

-- Indexes for escalation processing
CREATE INDEX idx_wfm_escalation_rules_workflow ON wfm_escalation_rules(workflow_id);
CREATE INDEX idx_wfm_escalation_rules_state ON wfm_escalation_rules(state_id);
CREATE INDEX idx_wfm_escalation_rules_trigger ON wfm_escalation_rules(trigger_type);
CREATE INDEX idx_wfm_escalation_rules_timeout ON wfm_escalation_rules(timeout_minutes) WHERE timeout_minutes IS NOT NULL;
CREATE INDEX idx_wfm_escalation_rules_active ON wfm_escalation_rules(is_active);

-- Task 9: Process Instance Tracking - Detailed workflow execution tracking
CREATE TABLE wfm_workflow_process_instances (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id),
    instance_key VARCHAR(100) NOT NULL UNIQUE, -- Unique identifier for this process instance
    
    -- Request details
    request_type VARCHAR(50) NOT NULL,
    requester_id INTEGER NOT NULL,
    requester_name VARCHAR(100) NOT NULL,
    department_id INTEGER,
    
    -- Current state
    current_state_id INTEGER REFERENCES wfm_workflow_states(id),
    current_state_key VARCHAR(50) NOT NULL,
    current_assignee_id INTEGER, -- Current person responsible for action
    current_assignee_role VARCHAR(50),
    
    -- Process data
    process_data JSONB NOT NULL DEFAULT '{}', -- All request data and context
    metadata JSONB NOT NULL DEFAULT '{}', -- Additional metadata
    
    -- Timing information
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    escalated_at TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'completed', 'cancelled', 'escalated', 'suspended'
    priority INTEGER NOT NULL DEFAULT 100, -- Lower = higher priority
    
    -- Business impact
    business_impact VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    urgency VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    
    -- Performance metrics
    total_processing_time_minutes INTEGER,
    approval_time_minutes INTEGER,
    escalation_count INTEGER DEFAULT 0,
    
    -- Final outcome
    final_decision VARCHAR(20), -- 'approved', 'rejected', 'cancelled', 'withdrawn'
    final_decision_reason TEXT,
    final_decision_by INTEGER,
    final_decision_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_wfm_workflow_status CHECK (status IN (
        'active', 'completed', 'cancelled', 'escalated', 'suspended'
    )),
    CONSTRAINT chk_wfm_business_impact CHECK (business_impact IN (
        'low', 'medium', 'high', 'critical'
    )),
    CONSTRAINT chk_wfm_urgency CHECK (urgency IN (
        'low', 'medium', 'high', 'urgent'
    ))
);

-- Indexes for process tracking performance
CREATE INDEX idx_wfm_process_instances_workflow ON wfm_workflow_process_instances(workflow_id);
CREATE INDEX idx_wfm_process_instances_status ON wfm_workflow_process_instances(status);
CREATE INDEX idx_wfm_process_instances_requester ON wfm_workflow_process_instances(requester_id);
CREATE INDEX idx_wfm_process_instances_assignee ON wfm_workflow_process_instances(current_assignee_id);
CREATE INDEX idx_wfm_process_instances_state ON wfm_workflow_process_instances(current_state_id);
CREATE INDEX idx_wfm_process_instances_dates ON wfm_workflow_process_instances(started_at, completed_at);
CREATE INDEX idx_wfm_process_instances_due ON wfm_workflow_process_instances(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_wfm_process_instances_priority ON wfm_workflow_process_instances(priority, status);

-- Workflow execution history - detailed audit trail
CREATE TABLE wfm_workflow_execution_history (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES wfm_workflow_process_instances(id) ON DELETE CASCADE,
    
    -- Transition details
    from_state_id INTEGER REFERENCES wfm_workflow_states(id),
    to_state_id INTEGER NOT NULL REFERENCES wfm_workflow_states(id),
    transition_key VARCHAR(50),
    
    -- Actor information
    actor_id INTEGER NOT NULL, -- Who performed the action
    actor_name VARCHAR(100) NOT NULL,
    actor_role VARCHAR(50),
    
    -- Action details
    action_type VARCHAR(50) NOT NULL, -- 'transition', 'escalation', 'delegation', 'comment', 'data_update'
    action_description_ru TEXT,
    
    -- Decision information
    decision VARCHAR(20), -- 'approved', 'rejected', 'returned', 'escalated', 'delegated'
    decision_reason TEXT,
    comments TEXT,
    
    -- Data changes
    data_before JSONB, -- State before action
    data_after JSONB, -- State after action
    data_changes JSONB, -- Specific changes made
    
    -- Context information
    ip_address INET,
    user_agent TEXT,
    session_info JSONB,
    
    -- Timing
    processing_time_seconds INTEGER, -- Time spent on this step
    scheduled_for TIMESTAMP WITH TIME ZONE, -- For scheduled actions
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Notification tracking
    notifications_sent JSONB DEFAULT '[]', -- Record of notifications sent
    
    CONSTRAINT chk_wfm_action_type CHECK (action_type IN (
        'transition', 'escalation', 'delegation', 'comment', 'data_update', 'notification', 'timeout'
    ))
);

-- Indexes for audit trail queries
CREATE INDEX idx_wfm_workflow_history_instance ON wfm_workflow_execution_history(instance_id);
CREATE INDEX idx_wfm_workflow_history_actor ON wfm_workflow_execution_history(actor_id);
CREATE INDEX idx_wfm_workflow_history_executed ON wfm_workflow_execution_history(executed_at);
CREATE INDEX idx_wfm_workflow_history_action ON wfm_workflow_execution_history(action_type);

-- Task 10: Workflow Performance Analytics - Comprehensive performance tracking
CREATE TABLE wfm_workflow_performance_metrics (
    id SERIAL PRIMARY KEY,
    
    -- Time period
    metric_date DATE NOT NULL,
    metric_hour INTEGER, -- NULL for daily metrics, 0-23 for hourly
    
    -- Scope
    workflow_id INTEGER REFERENCES wfm_workflow_definitions(id),
    workflow_type VARCHAR(50),
    department_id INTEGER,
    
    -- Volume metrics
    instances_started INTEGER DEFAULT 0,
    instances_completed INTEGER DEFAULT 0,
    instances_cancelled INTEGER DEFAULT 0,
    instances_escalated INTEGER DEFAULT 0,
    
    -- Time metrics (in minutes)
    avg_processing_time INTEGER,
    median_processing_time INTEGER,
    min_processing_time INTEGER,
    max_processing_time INTEGER,
    p95_processing_time INTEGER, -- 95th percentile
    
    -- Approval metrics
    avg_approval_time INTEGER,
    median_approval_time INTEGER,
    approval_rate DECIMAL(5,2), -- Percentage approved
    rejection_rate DECIMAL(5,2), -- Percentage rejected
    escalation_rate DECIMAL(5,2), -- Percentage escalated
    
    -- Efficiency metrics
    first_pass_approval_rate DECIMAL(5,2), -- Approved without returns
    avg_approval_steps INTEGER,
    avg_escalations_per_instance DECIMAL(3,2),
    
    -- Workload metrics
    avg_queue_size INTEGER, -- Average pending instances
    max_queue_size INTEGER, -- Peak pending instances
    avg_assignee_workload INTEGER, -- Average assignments per person
    
    -- SLA metrics
    sla_met_count INTEGER DEFAULT 0,
    sla_missed_count INTEGER DEFAULT 0,
    sla_compliance_rate DECIMAL(5,2),
    
    -- Quality metrics
    return_rate DECIMAL(5,2), -- Percentage returned for corrections
    avg_comments_per_instance DECIMAL(3,2),
    data_quality_score DECIMAL(3,2), -- Based on validation results
    
    -- Business impact
    high_priority_percentage DECIMAL(5,2),
    critical_priority_percentage DECIMAL(5,2),
    business_hours_percentage DECIMAL(5,2),
    
    -- System performance
    avg_response_time_ms INTEGER, -- System response time
    error_count INTEGER DEFAULT 0,
    timeout_count INTEGER DEFAULT 0,
    
    -- Metadata
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    calculation_version VARCHAR(20) DEFAULT 'v1.0',
    
    UNIQUE(metric_date, metric_hour, workflow_id, department_id)
);

-- Indexes for analytics queries
CREATE INDEX idx_wfm_workflow_metrics_date ON wfm_workflow_performance_metrics(metric_date);
CREATE INDEX idx_wfm_workflow_metrics_workflow ON wfm_workflow_performance_metrics(workflow_id);
CREATE INDEX idx_wfm_workflow_metrics_type ON wfm_workflow_performance_metrics(workflow_type);
CREATE INDEX idx_wfm_workflow_metrics_dept ON wfm_workflow_performance_metrics(department_id);
CREATE INDEX idx_wfm_workflow_metrics_hourly ON wfm_workflow_performance_metrics(metric_date, metric_hour) WHERE metric_hour IS NOT NULL;

-- Bottleneck analysis table
CREATE TABLE wfm_workflow_bottleneck_analysis (
    id SERIAL PRIMARY KEY,
    analysis_date DATE NOT NULL,
    workflow_id INTEGER NOT NULL REFERENCES wfm_workflow_definitions(id),
    
    -- Bottleneck identification
    bottleneck_state_id INTEGER REFERENCES wfm_workflow_states(id),
    bottleneck_assignee_role VARCHAR(50),
    
    -- Bottleneck metrics
    avg_wait_time_minutes INTEGER NOT NULL,
    instance_count INTEGER NOT NULL,
    impact_score DECIMAL(5,2), -- Calculated impact on overall process
    
    -- Root cause analysis
    primary_cause VARCHAR(100), -- 'workload', 'complexity', 'dependencies', 'training', 'system'
    contributing_factors JSONB,
    
    -- Recommendations
    recommended_actions JSONB,
    priority INTEGER NOT NULL DEFAULT 100,
    
    -- Status
    status VARCHAR(20) DEFAULT 'identified', -- 'identified', 'analyzing', 'addressed', 'resolved'
    addressed_by INTEGER,
    addressed_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for bottleneck tracking
CREATE INDEX idx_wfm_bottleneck_analysis_date ON wfm_workflow_bottleneck_analysis(analysis_date);
CREATE INDEX idx_wfm_bottleneck_analysis_workflow ON wfm_workflow_bottleneck_analysis(workflow_id);
CREATE INDEX idx_wfm_bottleneck_analysis_priority ON wfm_workflow_bottleneck_analysis(priority, status);

-- Comments on schema purpose
COMMENT ON TABLE wfm_workflow_definitions IS 'Основные определения рабочих процессов с конфигурацией конечных автоматов';
COMMENT ON TABLE wfm_workflow_states IS 'Состояния рабочих процессов с настройками отображения и поведения';
COMMENT ON TABLE wfm_approval_routing_rules IS 'Динамические правила маршрутизации согласований на основе бизнес-логики';
COMMENT ON TABLE wfm_escalation_rules IS 'Правила эскалации с временными и условными триггерами';
COMMENT ON TABLE wfm_workflow_process_instances IS 'Экземпляры рабочих процессов с детальным отслеживанием выполнения';
COMMENT ON TABLE wfm_workflow_execution_history IS 'Полная история выполнения рабочих процессов для аудита';
COMMENT ON TABLE wfm_workflow_performance_metrics IS 'Метрики производительности рабочих процессов для анализа';
COMMENT ON TABLE wfm_workflow_bottleneck_analysis IS 'Анализ узких мест в рабочих процессах';

-- Insert sample workflow definitions for vacation, overtime, and shift exchange
INSERT INTO wfm_workflow_definitions (workflow_name, workflow_type, display_name_ru, description_ru, state_machine_config, business_rules, default_settings, created_by) VALUES
('vacation_standard', 'vacation', 'Стандартный отпуск', 'Стандартный процесс согласования отпуска', 
'{"states": ["draft", "pending_supervisor", "pending_hr", "approved", "rejected"], "initial_state": "draft"}',
'{"min_advance_days": 14, "max_vacation_days": 28, "requires_coverage": true}',
'{"approval_timeout_hours": 48, "escalation_timeout_hours": 72}', 1),

('overtime_standard', 'overtime', 'Стандартная сверхурочная работа', 'Процесс согласования сверхурочной работы',
'{"states": ["draft", "pending_supervisor", "pending_manager", "approved", "rejected"], "initial_state": "draft"}',
'{"max_daily_overtime": 4, "max_weekly_overtime": 12, "requires_justification": true}',
'{"approval_timeout_hours": 24, "escalation_timeout_hours": 48}', 1),

('shift_exchange', 'shift_exchange', 'Обмен сменами', 'Процесс обмена сменами между сотрудниками',
'{"states": ["draft", "pending_counterpart", "pending_supervisor", "approved", "rejected"], "initial_state": "draft"}',
'{"advance_notice_hours": 24, "skill_level_match": true, "coverage_maintained": true}',
'{"approval_timeout_hours": 12, "escalation_timeout_hours": 24}', 1);

-- Insert states for workflows
INSERT INTO wfm_workflow_states (workflow_id, state_key, state_name_ru, description_ru, state_type, state_config, color_code, icon_name, sort_order) VALUES
-- Vacation workflow states (workflow_id = 1)
(1, 'draft', 'Черновик', 'Заявка создана, но не отправлена', 'initial', '{"editable": true, "timeout_hours": 24}', '#F3F4F6', 'edit', 1),
(1, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования непосредственного руководителя', 'intermediate', '{"timeout_hours": 48, "escalation_hours": 72}', '#FEF3C7', 'clock', 2),
(1, 'pending_hr', 'Ожидает HR', 'Ожидает согласования отдела кадров', 'intermediate', '{"timeout_hours": 24, "escalation_hours": 48}', '#DBEAFE', 'users', 3),
(1, 'approved', 'Одобрено', 'Заявка одобрена и обработана', 'final', '{"notify_requester": true, "update_calendar": true}', '#D1FAE5', 'check-circle', 4),
(1, 'rejected', 'Отклонено', 'Заявка отклонена', 'final', '{"notify_requester": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),

-- Overtime workflow states (workflow_id = 2)
(2, 'draft', 'Черновик', 'Заявка на сверхурочную работу создана', 'initial', '{"editable": true, "timeout_hours": 12}', '#F3F4F6', 'edit', 1),
(2, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования руководителя', 'intermediate', '{"timeout_hours": 24, "escalation_hours": 36}', '#FEF3C7', 'clock', 2),
(2, 'pending_manager', 'Ожидает менеджера', 'Ожидает согласования менеджера отдела', 'intermediate', '{"timeout_hours": 12, "escalation_hours": 24}', '#DBEAFE', 'briefcase', 3),
(2, 'approved', 'Одобрено', 'Сверхурочная работа одобрена', 'final', '{"notify_requester": true, "update_schedule": true}', '#D1FAE5', 'check-circle', 4),
(2, 'rejected', 'Отклонено', 'Заявка на сверхурочную работу отклонена', 'final', '{"notify_requester": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),

-- Shift exchange workflow states (workflow_id = 3)
(3, 'draft', 'Черновик', 'Предложение обмена сменами создано', 'initial', '{"editable": true, "timeout_hours": 6}', '#F3F4F6', 'edit', 1),
(3, 'pending_counterpart', 'Ожидает согласия коллеги', 'Ожидает согласия от второй стороны обмена', 'intermediate', '{"timeout_hours": 12, "auto_remind_hours": 6}', '#FEF3C7', 'user-plus', 2),
(3, 'pending_supervisor', 'Ожидает руководителя', 'Ожидает согласования руководителя', 'intermediate', '{"timeout_hours": 8, "escalation_hours": 16}', '#DBEAFE', 'clock', 3),
(3, 'approved', 'Одобрено', 'Обмен сменами одобрен', 'final', '{"notify_both_parties": true, "update_schedules": true}', '#D1FAE5', 'check-circle', 4),
(3, 'rejected', 'Отклонено', 'Обмен сменами отклонен', 'final', '{"notify_both_parties": true, "require_reason": true}', '#FEE2E2', 'x-circle', 5),
(3, 'counterpart_declined', 'Коллега отказался', 'Вторая сторона отказалась от обмена', 'final', '{"notify_requester": true}', '#FEE2E2', 'user-x', 6);

-- Test the workflow engine with verification query
SELECT 
    wd.workflow_name,
    wd.display_name_ru,
    wd.workflow_type,
    jsonb_pretty(wd.state_machine_config) as state_config,
    wd.is_active,
    COUNT(ws.id) as states_count
FROM wfm_workflow_definitions wd
LEFT JOIN wfm_workflow_states ws ON wd.id = ws.workflow_id
GROUP BY wd.id, wd.workflow_name, wd.display_name_ru, wd.workflow_type, wd.state_machine_config, wd.is_active
ORDER BY wd.workflow_type, wd.workflow_name;