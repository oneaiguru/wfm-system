-- =====================================================================================
-- Schema 107: Process Instance Tracking & Workflow Performance Analytics  
-- =====================================================================================
-- Tasks 9-10: Detailed workflow execution tracking and performance analytics
-- 
-- Part 2/5: Process execution tracking, audit trails, and performance metrics
-- =====================================================================================

-- Task 9: Process Instance Tracking - Detailed workflow execution tracking
CREATE TABLE workflow_instances (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id),
    instance_key VARCHAR(100) NOT NULL, -- Unique identifier for this process instance
    
    -- Request details
    request_type VARCHAR(50) NOT NULL,
    requester_id INTEGER NOT NULL,
    requester_name VARCHAR(100) NOT NULL,
    department_id INTEGER,
    
    -- Current state
    current_state_id INTEGER REFERENCES workflow_states(id),
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
    
    CONSTRAINT chk_workflow_status CHECK (status IN (
        'active', 'completed', 'cancelled', 'escalated', 'suspended'
    )),
    CONSTRAINT chk_business_impact CHECK (business_impact IN (
        'low', 'medium', 'high', 'critical'
    )),
    CONSTRAINT chk_urgency CHECK (urgency IN (
        'low', 'medium', 'high', 'urgent'
    ))
);

-- Indexes for process tracking performance
CREATE INDEX idx_workflow_instances_workflow ON workflow_instances(workflow_id);
CREATE INDEX idx_workflow_instances_status ON workflow_instances(status);
CREATE INDEX idx_workflow_instances_requester ON workflow_instances(requester_id);
CREATE INDEX idx_workflow_instances_assignee ON workflow_instances(current_assignee_id);
CREATE INDEX idx_workflow_instances_state ON workflow_instances(current_state_id);
CREATE INDEX idx_workflow_instances_dates ON workflow_instances(started_at, completed_at);
CREATE INDEX idx_workflow_instances_due ON workflow_instances(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_workflow_instances_priority ON workflow_instances(priority, status);

-- Workflow execution history - detailed audit trail
CREATE TABLE workflow_execution_history (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
    
    -- Transition details
    from_state_id INTEGER REFERENCES workflow_states(id),
    to_state_id INTEGER NOT NULL REFERENCES workflow_states(id),
    transition_id INTEGER REFERENCES workflow_transitions(id),
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
    
    CONSTRAINT chk_action_type CHECK (action_type IN (
        'transition', 'escalation', 'delegation', 'comment', 'data_update', 'notification', 'timeout'
    ))
);

-- Indexes for audit trail queries
CREATE INDEX idx_workflow_history_instance ON workflow_execution_history(instance_id);
CREATE INDEX idx_workflow_history_actor ON workflow_execution_history(actor_id);
CREATE INDEX idx_workflow_history_executed ON workflow_execution_history(executed_at);
CREATE INDEX idx_workflow_history_action ON workflow_execution_history(action_type);
CREATE INDEX idx_workflow_history_transition ON workflow_execution_history(transition_id);

-- Current assignments and workload tracking
CREATE TABLE workflow_assignments (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
    assignee_id INTEGER NOT NULL,
    assignee_name VARCHAR(100) NOT NULL,
    assignee_role VARCHAR(50),
    
    -- Assignment details
    assignment_type VARCHAR(20) NOT NULL, -- 'approval', 'review', 'information', 'escalation'
    assigned_by INTEGER NOT NULL, -- Who made the assignment
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'delegated', 'escalated'
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Delegation information
    delegated_to INTEGER, -- If delegated
    delegation_reason TEXT,
    delegated_at TIMESTAMP WITH TIME ZONE,
    
    -- Escalation tracking
    escalation_level INTEGER DEFAULT 0,
    escalated_to INTEGER,
    escalated_at TIMESTAMP WITH TIME ZONE,
    escalation_reason TEXT,
    
    -- Performance tracking
    response_time_minutes INTEGER, -- Time to first action
    completion_time_minutes INTEGER, -- Total time to complete
    
    -- Notification tracking
    reminder_count INTEGER DEFAULT 0,
    last_reminder_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT chk_assignment_type CHECK (assignment_type IN (
        'approval', 'review', 'information', 'escalation'
    )),
    CONSTRAINT chk_assignment_status CHECK (status IN (
        'pending', 'in_progress', 'completed', 'delegated', 'escalated'
    ))
);

-- Indexes for workload management
CREATE INDEX idx_workflow_assignments_assignee ON workflow_assignments(assignee_id, status);
CREATE INDEX idx_workflow_assignments_instance ON workflow_assignments(instance_id);
CREATE INDEX idx_workflow_assignments_due ON workflow_assignments(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_workflow_assignments_status ON workflow_assignments(status);
CREATE INDEX idx_workflow_assignments_escalation ON workflow_assignments(escalation_level) WHERE escalation_level > 0;

-- Task 10: Workflow Performance Analytics - Comprehensive performance tracking
CREATE TABLE workflow_performance_metrics (
    id SERIAL PRIMARY KEY,
    
    -- Time period
    metric_date DATE NOT NULL,
    metric_hour INTEGER, -- NULL for daily metrics, 0-23 for hourly
    
    -- Scope
    workflow_id INTEGER REFERENCES workflow_definitions(id),
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
CREATE INDEX idx_workflow_metrics_date ON workflow_performance_metrics(metric_date);
CREATE INDEX idx_workflow_metrics_workflow ON workflow_performance_metrics(workflow_id);
CREATE INDEX idx_workflow_metrics_type ON workflow_performance_metrics(workflow_type);
CREATE INDEX idx_workflow_metrics_dept ON workflow_performance_metrics(department_id);
CREATE INDEX idx_workflow_metrics_hourly ON workflow_performance_metrics(metric_date, metric_hour) WHERE metric_hour IS NOT NULL;

-- Bottleneck analysis table
CREATE TABLE workflow_bottleneck_analysis (
    id SERIAL PRIMARY KEY,
    analysis_date DATE NOT NULL,
    workflow_id INTEGER NOT NULL REFERENCES workflow_definitions(id),
    
    -- Bottleneck identification
    bottleneck_state_id INTEGER REFERENCES workflow_states(id),
    bottleneck_transition_id INTEGER REFERENCES workflow_transitions(id),
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
CREATE INDEX idx_bottleneck_analysis_date ON workflow_bottleneck_analysis(analysis_date);
CREATE INDEX idx_bottleneck_analysis_workflow ON workflow_bottleneck_analysis(workflow_id);
CREATE INDEX idx_bottleneck_analysis_priority ON workflow_bottleneck_analysis(priority, status);

-- Comments on analytics tables
COMMENT ON TABLE workflow_instances IS 'Экземпляры рабочих процессов с детальным отслеживанием выполнения';
COMMENT ON TABLE workflow_execution_history IS 'Полная история выполнения рабочих процессов для аудита';
COMMENT ON TABLE workflow_assignments IS 'Назначения задач и отслеживание рабочей нагрузки';
COMMENT ON TABLE workflow_performance_metrics IS 'Метрики производительности рабочих процессов для анализа';
COMMENT ON TABLE workflow_bottleneck_analysis IS 'Анализ узких мест в рабочих процессах';

-- Update trigger for workflow_instances
CREATE OR REPLACE FUNCTION update_workflow_instance_timing()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the updated_at timestamp
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    -- Calculate total processing time if completed
    IF NEW.status = 'completed' AND NEW.completed_at IS NOT NULL THEN
        NEW.total_processing_time_minutes = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) / 60;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_workflow_instance_update
    BEFORE UPDATE ON workflow_instances
    FOR EACH ROW
    EXECUTE FUNCTION update_workflow_instance_timing();

-- Sample workflow instance for testing
INSERT INTO workflow_instances (
    workflow_id, instance_key, request_type, requester_id, requester_name, 
    current_state_key, process_data, business_impact, urgency
) VALUES (
    1, 'VAC-2025-001', 'vacation', 101, 'Иванов Иван Иванович',
    'draft', '{"vacation_start": "2025-08-01", "vacation_end": "2025-08-14", "days": 14}',
    'medium', 'medium'
);

-- Test query to verify process tracking
SELECT 
    wi.instance_key,
    wi.request_type,
    wi.requester_name,
    wi.current_state_key,
    wi.status,
    wi.business_impact,
    jsonb_pretty(wi.process_data) as request_details
FROM workflow_instances wi
ORDER BY wi.created_at DESC
LIMIT 5;