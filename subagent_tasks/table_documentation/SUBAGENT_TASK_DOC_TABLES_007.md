# 📋 SUBAGENT TASK: Table Documentation Batch 007 - Business Process Management Workflows

## 🎯 Task Information
- **Task ID**: DOC_TABLES_007
- **Priority**: High
- **Estimated Time**: 40 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 6 business process management workflow tables with proper API contracts:

1. **business_process_definitions** - Core workflow templates with process stages and business rules
2. **process_instance_tracking** - Active workflow execution monitoring and status tracking
3. **process_tasks** - Individual workflow tasks with assignment and escalation management
4. **task_actions** - Audit trail of all actions performed on workflow tasks
5. **process_performance_metrics** - Workflow efficiency measurement and bottleneck analysis
6. **process_integration_points** - Cross-system orchestration including 1C ZUP integration

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/business-process%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('business_process_definitions', 'process_instance_tracking', 'process_tasks', 'task_actions', 'process_performance_metrics', 'process_integration_points')
ORDER BY relname;"
```

### Step 2: Apply Proper API Contracts

Execute these commands in order:

#### Table 1: business_process_definitions
```sql
COMMENT ON TABLE business_process_definitions IS 
'API Contract: GET /api/v1/business-process/definitions
params: {category?: string, status?: string, department_id?: UUID}
returns: [{
    id: UUID,
    name: string,
    description: string,
    version: string,
    category: string,
    status: string,
    process_definition: object,
    notification_settings: object,
    timeout_settings: object,
    business_rules: object,
    department_id: UUID,
    created_at: timestamp,
    created_by: UUID
}]

POST /api/v1/business-process/definitions
expects: {
    name: string,
    description?: string,
    category: string,
    process_definition: object,
    notification_settings?: object,
    timeout_settings?: object,
    business_rules?: object,
    department_id?: UUID
}
returns: {id: UUID, status: string, version: string}

PUT /api/v1/business-process/definitions/:id
expects: {
    status?: string,
    process_definition?: object,
    notification_settings?: object,
    timeout_settings?: object,
    business_rules?: object
}
returns: {id: UUID, version: string, updated_at: timestamp}

Helper Queries:
-- Get business process definitions with filters
SELECT 
    bpd.id::text as id,
    bpd.name,
    bpd.description,
    bpd.version,
    bpd.category,
    bpd.status,
    bpd.process_definition,
    bpd.notification_settings,
    bpd.timeout_settings,
    bpd.business_rules,
    bpd.department_id::text as department_id,
    bpd.created_at,
    bpd.created_by::text as created_by,
    d.name as department_name,
    u.first_name || '' '' || u.last_name as created_by_name
FROM business_process_definitions bpd
LEFT JOIN departments d ON bpd.department_id = d.id
LEFT JOIN users u ON bpd.created_by = u.id
WHERE ($1 IS NULL OR bpd.category = $1)
    AND ($2 IS NULL OR bpd.status = $2::workflow_status)
    AND ($3::uuid IS NULL OR bpd.department_id = $3)
ORDER BY bpd.created_at DESC;

-- Create new process definition
INSERT INTO business_process_definitions (
    name,
    description,
    category,
    process_definition,
    notification_settings,
    timeout_settings,
    business_rules,
    department_id,
    created_by
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING id, version, created_at;';
```

#### Table 2: process_instance_tracking
```sql
COMMENT ON TABLE process_instance_tracking IS
'API Contract: GET /api/v1/business-process/instances
params: {status?: string, initiated_by?: UUID, process_definition_id?: UUID, date_from?: YYYY-MM-DD}
returns: [{
    id: UUID,
    process_definition_id: UUID,
    instance_name: string,
    context_data: object,
    current_stage: string,
    current_step_order: int,
    status: string,
    started_at: timestamp,
    completed_at: timestamp,
    due_date: timestamp,
    initiated_by: UUID,
    current_assignees: object,
    completed_steps: object,
    pending_steps: object,
    integration_status: string
}]

POST /api/v1/business-process/instances
expects: {
    process_definition_id: UUID,
    instance_name: string,
    context_data: object,
    due_date?: timestamp
}
returns: {id: UUID, status: string, current_stage: string}

PUT /api/v1/business-process/instances/:id/advance
expects: {
    stage_action: string,
    comments?: string,
    decision_data?: object
}
returns: {id: UUID, current_stage: string, status: string, next_assignees: array}

Helper Queries:
-- Get process instances with details
SELECT 
    pit.id::text as id,
    pit.process_definition_id::text as process_definition_id,
    pit.instance_name,
    pit.context_data,
    pit.current_stage,
    pit.current_step_order,
    pit.status,
    pit.started_at,
    pit.completed_at,
    pit.due_date,
    pit.initiated_by::text as initiated_by,
    pit.current_assignees,
    pit.completed_steps,
    pit.pending_steps,
    pit.integration_status,
    bpd.name as process_name,
    bpd.category as process_category,
    u.first_name || '' '' || u.last_name as initiated_by_name,
    CASE 
        WHEN pit.due_date < CURRENT_TIMESTAMP AND pit.status != ''completed'' THEN true
        ELSE false
    END as is_overdue
FROM process_instance_tracking pit
LEFT JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
LEFT JOIN users u ON pit.initiated_by = u.id
WHERE ($1 IS NULL OR pit.status = $1::process_instance_status)
    AND ($2::uuid IS NULL OR pit.initiated_by = $2)
    AND ($3::uuid IS NULL OR pit.process_definition_id = $3)
    AND ($4::date IS NULL OR pit.started_at::date >= $4)
ORDER BY pit.started_at DESC;

-- Start new process instance
SELECT start_process_instance($1, $2, $3, $4, $5);';
```

#### Table 3: process_tasks
```sql
COMMENT ON TABLE process_tasks IS
'API Contract: GET /api/v1/business-process/tasks
params: {assigned_to?: UUID, status?: string, escalation_level?: string, due_before?: timestamp}
returns: [{
    id: UUID,
    process_instance_id: UUID,
    task_name: string,
    task_description: string,
    task_type: string,
    assigned_to: UUID,
    assigned_role: string,
    status: string,
    available_actions: array,
    created_at: timestamp,
    due_date: timestamp,
    completed_at: timestamp,
    task_data: object,
    escalation_level: string,
    escalated_at: timestamp
}]

POST /api/v1/business-process/tasks/:id/complete
expects: {
    action: string,
    comments?: string,
    decision_data?: object,
    delegation_info?: object
}
returns: {id: UUID, status: string, next_stage: string, workflow_status: string}

PUT /api/v1/business-process/tasks/:id/delegate
expects: {
    delegate_to: UUID,
    delegation_reason: string,
    delegation_type: string
}
returns: {id: UUID, assigned_to: UUID, delegation_id: UUID}

Helper Queries:
-- Get tasks with process and user details
SELECT 
    pt.id::text as id,
    pt.process_instance_id::text as process_instance_id,
    pt.task_name,
    pt.task_description,
    pt.task_type,
    pt.assigned_to::text as assigned_to,
    pt.assigned_role,
    pt.status,
    pt.available_actions,
    pt.created_at,
    pt.due_date,
    pt.completed_at,
    pt.task_data,
    pt.escalation_level,
    pt.escalated_at,
    pit.instance_name,
    pit.current_stage,
    bpd.name as process_name,
    u.first_name || '' '' || u.last_name as assigned_to_name,
    CASE 
        WHEN pt.due_date < CURRENT_TIMESTAMP AND pt.status = ''pending'' THEN true
        ELSE false
    END as is_overdue,
    EXTRACT(epoch FROM (pt.due_date - CURRENT_TIMESTAMP))/3600 as hours_until_due
FROM process_tasks pt
LEFT JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
LEFT JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
LEFT JOIN users u ON pt.assigned_to = u.id
WHERE ($1::uuid IS NULL OR pt.assigned_to = $1)
    AND ($2 IS NULL OR pt.status = $2::task_status)
    AND ($3 IS NULL OR pt.escalation_level = $3::escalation_level)
    AND ($4::timestamp IS NULL OR pt.due_date <= $4)
ORDER BY pt.due_date ASC, pt.escalation_level DESC NULLS LAST;

-- Complete task with action
SELECT complete_task($1, $2, $3::task_action, $4, $5);';
```

#### Table 4: task_actions
```sql
COMMENT ON TABLE task_actions IS
'API Contract: GET /api/v1/business-process/task-actions
params: {task_id?: UUID, performed_by?: UUID, action_type?: string, date_from?: YYYY-MM-DD}
returns: [{
    id: UUID,
    task_id: UUID,
    action_type: string,
    performed_by: UUID,
    performed_at: timestamp,
    comments: string,
    decision_rationale: string,
    delegated_to: UUID,
    delegation_reason: string,
    attachments: object
}]

POST /api/v1/business-process/task-actions
expects: {
    task_id: UUID,
    action_type: string,
    comments?: string,
    decision_rationale?: string,
    delegated_to?: UUID,
    delegation_reason?: string,
    attachments?: object
}
returns: {id: UUID, performed_at: timestamp, task_status: string}

Helper Queries:
-- Get task actions audit trail
SELECT 
    ta.id::text as id,
    ta.task_id::text as task_id,
    ta.action_type,
    ta.performed_by::text as performed_by,
    ta.performed_at,
    ta.comments,
    ta.decision_rationale,
    ta.delegated_to::text as delegated_to,
    ta.delegation_reason,
    ta.attachments,
    u1.first_name || '' '' || u1.last_name as performed_by_name,
    u2.first_name || '' '' || u2.last_name as delegated_to_name,
    pt.task_name,
    pit.instance_name,
    bpd.name as process_name
FROM task_actions ta
LEFT JOIN users u1 ON ta.performed_by = u1.id
LEFT JOIN users u2 ON ta.delegated_to = u2.id
LEFT JOIN process_tasks pt ON ta.task_id = pt.id
LEFT JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
LEFT JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
WHERE ($1::uuid IS NULL OR ta.task_id = $1)
    AND ($2::uuid IS NULL OR ta.performed_by = $2)
    AND ($3 IS NULL OR ta.action_type = $3::task_action)
    AND ($4::date IS NULL OR ta.performed_at::date >= $4)
ORDER BY ta.performed_at DESC;

-- Record task action
INSERT INTO task_actions (
    task_id,
    action_type,
    performed_by,
    comments,
    decision_rationale,
    delegated_to,
    delegation_reason,
    attachments
) VALUES ($1, $2::task_action, $3, $4, $5, $6, $7, $8)
RETURNING id, performed_at, 
    (SELECT status FROM process_tasks WHERE id = $1) as task_status;';
```

#### Table 5: process_performance_metrics
```sql
COMMENT ON TABLE process_performance_metrics IS
'API Contract: GET /api/v1/business-process/performance-metrics
params: {process_definition_id?: UUID, period_start?: YYYY-MM-DD, period_end?: YYYY-MM-DD}
returns: [{
    id: UUID,
    process_definition_id: UUID,
    measurement_period_start: timestamp,
    measurement_period_end: timestamp,
    average_cycle_time: string,
    median_cycle_time: string,
    min_cycle_time: string,
    max_cycle_time: string,
    stage_performance: object,
    bottleneck_stages: object,
    total_instances: int,
    approved_instances: int,
    rejected_instances: int,
    approval_rate: float,
    escalation_count: int,
    escalation_rate: float,
    participant_utilization: object,
    calculated_at: timestamp
}]

POST /api/v1/business-process/performance-metrics/calculate
expects: {
    process_definition_id: UUID,
    period_start: timestamp,
    period_end: timestamp
}
returns: {id: UUID, metrics_calculated: object, calculation_time: timestamp}

Helper Queries:
-- Get process performance metrics
SELECT 
    ppm.id::text as id,
    ppm.process_definition_id::text as process_definition_id,
    ppm.measurement_period_start,
    ppm.measurement_period_end,
    ppm.average_cycle_time::text as average_cycle_time,
    ppm.median_cycle_time::text as median_cycle_time,
    ppm.min_cycle_time::text as min_cycle_time,
    ppm.max_cycle_time::text as max_cycle_time,
    ppm.stage_performance,
    ppm.bottleneck_stages,
    ppm.total_instances,
    ppm.approved_instances,
    ppm.rejected_instances,
    ppm.approval_rate,
    ppm.escalation_count,
    ppm.escalation_rate,
    ppm.participant_utilization,
    ppm.calculated_at,
    bpd.name as process_name,
    bpd.category as process_category,
    CASE 
        WHEN ppm.approval_rate >= 90 THEN ''excellent''
        WHEN ppm.approval_rate >= 75 THEN ''good''
        WHEN ppm.approval_rate >= 60 THEN ''average''
        ELSE ''needs_improvement''
    END as performance_rating
FROM process_performance_metrics ppm
LEFT JOIN business_process_definitions bpd ON ppm.process_definition_id = bpd.id
WHERE ($1::uuid IS NULL OR ppm.process_definition_id = $1)
    AND ($2::date IS NULL OR ppm.measurement_period_start::date >= $2)
    AND ($3::date IS NULL OR ppm.measurement_period_end::date <= $3)
ORDER BY ppm.measurement_period_start DESC;

-- Calculate performance metrics
SELECT calculate_process_performance($1, $2, $3);';
```

#### Table 6: process_integration_points
```sql
COMMENT ON TABLE process_integration_points IS
'API Contract: GET /api/v1/business-process/integration-points
params: {process_definition_id?: UUID, integration_type?: string, active?: boolean}
returns: [{
    id: UUID,
    process_definition_id: UUID,
    integration_name: string,
    integration_type: string,
    external_system: string,
    endpoint_url: string,
    trigger_stage: string,
    active: boolean,
    last_executed: timestamp,
    execution_count: int,
    success_count: int,
    failure_count: int,
    success_rate: float,
    created_at: timestamp
}]

POST /api/v1/business-process/integration-points
expects: {
    process_definition_id: UUID,
    integration_name: string,
    integration_type: string,
    external_system: string,
    endpoint_url?: string,
    authentication_config?: object,
    request_format?: object,
    trigger_stage: string,
    retry_policy?: object
}
returns: {id: UUID, active: boolean, created_at: timestamp}

PUT /api/v1/business-process/integration-points/:id/test
expects: {
    test_data?: object
}
returns: {success: boolean, response_time: int, response_data: object, error_details?: object}

Helper Queries:
-- Get integration points with performance data
SELECT 
    pip.id::text as id,
    pip.process_definition_id::text as process_definition_id,
    pip.integration_name,
    pip.integration_type,
    pip.external_system,
    pip.endpoint_url,
    pip.trigger_stage,
    pip.active,
    pip.last_executed,
    pip.execution_count,
    pip.success_count,
    pip.failure_count,
    CASE 
        WHEN pip.execution_count > 0 THEN (pip.success_count::decimal / pip.execution_count * 100)::numeric(5,2)
        ELSE 0
    END as success_rate,
    pip.created_at,
    bpd.name as process_name,
    pip.authentication_config,
    pip.request_format,
    pip.retry_policy,
    CASE 
        WHEN pip.success_count::decimal / NULLIF(pip.execution_count, 0) >= 0.95 THEN ''excellent''
        WHEN pip.success_count::decimal / NULLIF(pip.execution_count, 0) >= 0.85 THEN ''good''
        WHEN pip.success_count::decimal / NULLIF(pip.execution_count, 0) >= 0.70 THEN ''average''
        ELSE ''needs_attention''
    END as reliability_rating
FROM process_integration_points pip
LEFT JOIN business_process_definitions bpd ON pip.process_definition_id = bpd.id
WHERE ($1::uuid IS NULL OR pip.process_definition_id = $1)
    AND ($2 IS NULL OR pip.integration_type = $2)
    AND ($3::boolean IS NULL OR pip.active = $3)
ORDER BY pip.last_executed DESC NULLS LAST;

-- Create integration point
INSERT INTO process_integration_points (
    process_definition_id,
    integration_name,
    integration_type,
    external_system,
    endpoint_url,
    authentication_config,
    request_format,
    trigger_stage,
    retry_policy,
    created_by
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING id, active, created_at;';
```

### Step 3: Create Test Data for Business Process Workflows
```sql
-- Insert test business process definition
INSERT INTO business_process_definitions (
    name,
    description,
    category,
    status,
    process_definition,
    notification_settings,
    business_rules,
    created_by
)
SELECT 
    'Test Schedule Approval',
    'Test workflow for schedule approval process',
    'Schedule Management',
    'active'::workflow_status,
    '{
        "stages": [
            {"name": "Supervisor Review", "order": 1, "participants": ["supervisor"], "actions": ["approve", "reject"]},
            {"name": "Planning Validation", "order": 2, "participants": ["planner"], "actions": ["validate", "return"]},
            {"name": "Final Approval", "order": 3, "participants": ["manager"], "actions": ["approve", "deny"]}
        ]
    }'::jsonb,
    '{
        "channels": ["system", "email"],
        "triggers": ["task_assigned", "escalation"]
    }'::jsonb,
    '{
        "authorization_rules": [{"rule": "role_based_access"}],
        "validation_rules": [{"rule": "schedule_completeness"}]
    }'::jsonb,
    u.id
FROM users u
WHERE u.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test process instance
INSERT INTO process_instance_tracking (
    process_definition_id,
    instance_name,
    context_data,
    current_stage,
    current_step_order,
    status,
    initiated_by
)
SELECT 
    bpd.id,
    'Weekly Schedule - Week 15',
    '{
        "schedule_period": "2024-04-08 to 2024-04-14",
        "department": "Customer Support",
        "total_shifts": 35,
        "affected_agents": 12
    }'::jsonb,
    'Supervisor Review',
    1,
    'in_progress'::process_instance_status,
    u.id
FROM business_process_definitions bpd, users u
WHERE bpd.name = 'Test Schedule Approval'
    AND u.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test process task
INSERT INTO process_tasks (
    process_instance_id,
    task_name,
    task_description,
    task_type,
    assigned_role,
    status,
    available_actions,
    task_data,
    due_date
)
SELECT 
    pit.id,
    'Review Weekly Schedule',
    'Review and approve weekly schedule for Customer Support department',
    'approval',
    'supervisor',
    'pending'::task_status,
    '["approve", "reject", "request_changes"]'::jsonb,
    '{
        "schedule_data": {"total_hours": 280, "coverage_gaps": 0},
        "review_criteria": ["adequate_coverage", "compliance_check", "cost_optimization"]
    }'::jsonb,
    CURRENT_TIMESTAMP + INTERVAL '24 hours'
FROM process_instance_tracking pit
JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
WHERE bpd.name = 'Test Schedule Approval'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test task action
INSERT INTO task_actions (
    task_id,
    action_type,
    performed_by,
    comments,
    decision_rationale
)
SELECT 
    pt.id,
    'approve'::task_action,
    u.id,
    'Schedule approved - adequate coverage maintained',
    'All coverage requirements met, no compliance issues identified'
FROM process_tasks pt, users u
WHERE pt.task_name = 'Review Weekly Schedule'
    AND u.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test integration point
INSERT INTO process_integration_points (
    process_definition_id,
    integration_name,
    integration_type,
    external_system,
    endpoint_url,
    trigger_stage,
    active,
    execution_count,
    success_count,
    failure_count,
    created_by
)
SELECT 
    bpd.id,
    'Test 1C ZUP Schedule Upload',
    'api_call',
    '1C ZUP Test',
    'http://test-1c-server/api/sendSchedule',
    'Final Approval',
    true,
    25,
    23,
    2,
    u.id
FROM business_process_definitions bpd, users u
WHERE bpd.name = 'Test Schedule Approval'
    AND u.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test performance metrics
INSERT INTO process_performance_metrics (
    process_definition_id,
    measurement_period_start,
    measurement_period_end,
    average_cycle_time,
    median_cycle_time,
    total_instances,
    approved_instances,
    rejected_instances,
    approval_rate,
    escalation_count,
    escalation_rate,
    stage_performance
)
SELECT 
    bpd.id,
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE,
    INTERVAL '2 days 4 hours',
    INTERVAL '1 day 18 hours',
    45,
    41,
    4,
    91.11,
    3,
    6.67,
    '{
        "Supervisor Review": {"average_duration": 8.5, "instance_count": 45},
        "Planning Validation": {"average_duration": 12.2, "instance_count": 42},
        "Final Approval": {"average_duration": 4.1, "instance_count": 41}
    }'::jsonb
FROM business_process_definitions bpd
WHERE bpd.name = 'Test Schedule Approval'
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/business-process%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE '%Helper Queries:%'
        THEN '✅ Has Helpers'
        ELSE '❌ No Helpers'
    END as helper_status
FROM pg_class 
WHERE relname IN ('business_process_definitions', 'process_instance_tracking', 'process_tasks', 'task_actions', 'process_performance_metrics', 'process_integration_points')
ORDER BY relname;"
```

### Step 5: Test Sample Queries
```sql
-- Test business process definitions query
SELECT 
    name,
    category,
    status,
    version,
    created_at,
    CASE 
        WHEN status = 'active' THEN 'Available'
        WHEN status = 'draft' THEN 'In Development'
        ELSE 'Not Available'
    END as availability_status
FROM business_process_definitions
ORDER BY created_at DESC
LIMIT 3;

-- Test process instances with workflow details
SELECT 
    pit.instance_name,
    pit.current_stage,
    pit.status,
    bpd.name as process_name,
    CASE 
        WHEN pit.due_date < CURRENT_TIMESTAMP AND pit.status != 'completed' THEN 'Overdue'
        WHEN pit.status = 'completed' THEN 'Completed'
        ELSE 'On Track'
    END as timeline_status
FROM process_instance_tracking pit
LEFT JOIN business_process_definitions bpd ON pit.process_definition_id = bpd.id
ORDER BY pit.started_at DESC
LIMIT 3;

-- Test task management query
SELECT 
    pt.task_name,
    pt.status,
    pt.assigned_role,
    pit.instance_name,
    CASE 
        WHEN pt.due_date < CURRENT_TIMESTAMP AND pt.status = 'pending' THEN 'Overdue'
        WHEN pt.escalation_level IS NOT NULL THEN 'Escalated'
        ELSE 'Normal'
    END as urgency_status
FROM process_tasks pt
LEFT JOIN process_instance_tracking pit ON pt.process_instance_id = pit.id
ORDER BY pt.due_date DESC
LIMIT 3;
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 6 tables have specific business process API contract comments
- [ ] Each table has GET and POST/PUT endpoints documented 
- [ ] Helper queries include proper parameter binding ($1, $2, etc.)
- [ ] Test data exists demonstrating complete workflow lifecycle
- [ ] Verification query shows ✅ for all tables
- [ ] Sample queries execute successfully
- [ ] Process functions are available (start_process_instance, complete_task, etc.)

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_007: Complete - 6 business process management workflow tables documented with proper API contracts and workflow functions" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If foreign key references fail:
- Check that referenced tables (users, departments, business_process_definitions) exist
- Use existing records for test data

If functions are missing:
- Check that process functions (start_process_instance, complete_task, etc.) exist
- Document any missing functions

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Key Features Documented

1. **Workflow Definition**: Template-based process configuration with stages and business rules
2. **Process Orchestration**: End-to-end workflow execution with monitoring and status tracking
3. **Task Management**: Assignment, delegation, and escalation with audit trails
4. **Performance Analytics**: Cycle time analysis, bottleneck identification, and approval metrics
5. **Cross-system Integration**: 1C ZUP integration with retry policies and execution logging
6. **Business Rule Engine**: Validation and authorization rules with flexible configuration

This completes the business process management workflow documentation with production-ready API contracts and comprehensive workflow automation capabilities.