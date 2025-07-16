-- =====================================================================================
-- Schema 106: Workflow State Machines - Advanced Workflow Engine Infrastructure
-- =====================================================================================
-- Tasks 6-10: Advanced workflow engine with state machine support, dynamic approval
-- routing, escalation management, process tracking, and performance analytics
-- 
-- Part 1/5: Core State Machine and Workflow Definitions
-- =====================================================================================

-- Task 6: Workflow State Machines with JSONB configuration
CREATE TABLE workflow_definitions (
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
    CONSTRAINT chk_workflow_type CHECK (workflow_type IN (
        'vacation', 'overtime', 'shift_exchange', 'absence', 'schedule_change', 
        'training', 'performance_review', 'equipment_request', 'custom'
    ))
);

-- Index for performance
CREATE INDEX idx_workflow_definitions_type ON workflow_definitions(workflow_type);
CREATE INDEX idx_workflow_definitions_active ON workflow_definitions(is_active);
CREATE INDEX idx_workflow_definitions_name ON workflow_definitions(workflow_name);

-- State definitions for each workflow
CREATE TABLE workflow_states (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id) ON DELETE CASCADE,
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
    
    CONSTRAINT chk_state_type CHECK (state_type IN ('initial', 'intermediate', 'final', 'error'))
);

-- Index for performance
CREATE INDEX idx_workflow_states_workflow ON workflow_states(workflow_id);
CREATE INDEX idx_workflow_states_key ON workflow_states(workflow_id, state_key);

-- Transition definitions between states
CREATE TABLE workflow_transitions (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id) ON DELETE CASCADE,
    from_state_id INTEGER NOT NULL REFERENCES workflow_states(id) ON DELETE CASCADE,
    to_state_id INTEGER NOT NULL REFERENCES workflow_states(id) ON DELETE CASCADE,
    transition_key VARCHAR(50) NOT NULL, -- 'approve', 'reject', 'escalate', 'return'
    transition_name_ru TEXT NOT NULL,
    
    -- Transition conditions and rules
    conditions JSONB NOT NULL DEFAULT '{}', -- When this transition is available
    
    -- Actions to perform during transition
    actions JSONB NOT NULL DEFAULT '{}', -- Notifications, data updates, external calls
    
    -- Authorization rules
    required_roles JSONB NOT NULL DEFAULT '[]', -- Roles that can perform this transition
    required_permissions JSONB NOT NULL DEFAULT '[]',
    
    -- Configuration
    auto_transition BOOLEAN NOT NULL DEFAULT false, -- Automatic transition based on conditions
    timeout_minutes INTEGER, -- Auto-transition after timeout
    
    -- Display
    button_text_ru TEXT,
    button_color VARCHAR(7),
    icon_name VARCHAR(50),
    sort_order INTEGER,
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(workflow_id, from_state_id, transition_key)
);

-- Indexes for performance
CREATE INDEX idx_workflow_transitions_workflow ON workflow_transitions(workflow_id);
CREATE INDEX idx_workflow_transitions_from ON workflow_transitions(from_state_id);
CREATE INDEX idx_workflow_transitions_auto ON workflow_transitions(auto_transition, timeout_minutes);

-- Task 7: Dynamic Approval Routing with Business Rules
CREATE TABLE approval_routing_rules (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id) ON DELETE CASCADE,
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
CREATE INDEX idx_approval_routing_rules_workflow ON approval_routing_rules(workflow_id);
CREATE INDEX idx_approval_routing_rules_priority ON approval_routing_rules(workflow_id, priority);
CREATE INDEX idx_approval_routing_rules_active ON approval_routing_rules(is_active);
CREATE INDEX idx_approval_routing_rules_effective ON approval_routing_rules(effective_from, effective_to);

-- Task 8: Escalation Management with Time-based and Condition-based Rules
CREATE TABLE escalation_rules (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id) ON DELETE CASCADE,
    state_id INTEGER REFERENCES workflow_states(id) ON DELETE CASCADE, -- NULL = applies to all states
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
    next_escalation_id INTEGER REFERENCES escalation_rules(id),
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    priority INTEGER NOT NULL DEFAULT 100,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_escalation_trigger CHECK (trigger_type IN (
        'time_based', 'condition_based', 'manual', 'external'
    ))
);

-- Indexes for escalation processing
CREATE INDEX idx_escalation_rules_workflow ON escalation_rules(workflow_id);
CREATE INDEX idx_escalation_rules_state ON escalation_rules(state_id);
CREATE INDEX idx_escalation_rules_trigger ON escalation_rules(trigger_type);
CREATE INDEX idx_escalation_rules_timeout ON escalation_rules(timeout_minutes) WHERE timeout_minutes IS NOT NULL;
CREATE INDEX idx_escalation_rules_active ON escalation_rules(is_active);

-- Comment on schema purpose
COMMENT ON TABLE workflow_definitions IS 'Основные определения рабочих процессов с конфигурацией конечных автоматов';
COMMENT ON TABLE workflow_states IS 'Состояния рабочих процессов с настройками отображения и поведения';
COMMENT ON TABLE workflow_transitions IS 'Переходы между состояниями с условиями и действиями';
COMMENT ON TABLE approval_routing_rules IS 'Динамические правила маршрутизации согласований на основе бизнес-логики';
COMMENT ON TABLE escalation_rules IS 'Правила эскалации с временными и условными триггерами';

-- Insert sample workflow definitions for vacation requests
INSERT INTO workflow_definitions (workflow_name, workflow_type, display_name_ru, description_ru, state_machine_config, business_rules, default_settings, created_by) VALUES
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

-- Test the workflow engine with verification query
SELECT 
    wd.workflow_name,
    wd.display_name_ru,
    wd.workflow_type,
    jsonb_pretty(wd.state_machine_config) as state_config,
    wd.is_active
FROM workflow_definitions wd
ORDER BY wd.workflow_type, wd.workflow_name;