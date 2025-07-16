# 📋 SUBAGENT TASK: Table Documentation Batch 008 - Shift Exchange System

## 🎯 Task Information
- **Task ID**: DOC_TABLES_008
- **Priority**: High
- **Estimated Time**: 40 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 5 shift exchange system tables with proper API contracts:

1. **shift_exchanges** - Core shift exchange requests with approval workflow
2. **exchange_requests** - Detailed exchange request specifications and metadata
3. **exchange_responses** - Exchange response handling and notification system
4. **exchange_history** - Complete audit trail of all exchange activities
5. **exchange_system_integration** - Cross-system orchestration including 1C ZUP integration

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/shift-exchange%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('shift_exchanges', 'exchange_requests', 'exchange_responses', 'exchange_history', 'exchange_system_integration')
ORDER BY relname;"
```

### Step 2: Apply Proper API Contracts

Execute these commands in order:

#### Table 1: shift_exchanges
```sql
COMMENT ON TABLE shift_exchanges IS 
'API Contract: GET /api/v1/shift-exchanges
params: {requester_id?: UUID, target_id?: UUID, status?: string, shift_date?: YYYY-MM-DD}
returns: [{
    id: UUID,
    requester_id: UUID,
    target_id: UUID,
    shift_date: date,
    original_shift_start: timestamp,
    original_shift_end: timestamp,
    requested_shift_start: timestamp,
    requested_shift_end: timestamp,
    exchange_type: string,
    status: string,
    reason: string,
    exchange_code: string,
    created_at: timestamp,
    approved_by: UUID,
    approved_at: timestamp,
    rejected_reason: string,
    priority_level: string
}]

POST /api/v1/shift-exchanges
expects: {
    target_id: UUID,
    shift_date: date,
    original_shift_start: timestamp,
    original_shift_end: timestamp,
    requested_shift_start?: timestamp,
    requested_shift_end?: timestamp,
    exchange_type: string,
    reason: string,
    priority_level?: string
}
returns: {id: UUID, exchange_code: string, status: string, created_at: timestamp}

PUT /api/v1/shift-exchanges/:id/approve
expects: {
    approval_comments?: string
}
returns: {id: UUID, status: string, approved_at: timestamp, notification_sent: boolean}

PUT /api/v1/shift-exchanges/:id/reject
expects: {
    rejection_reason: string
}
returns: {id: UUID, status: string, rejected_at: timestamp}

Helper Queries:
-- Get shift exchanges with employee details
SELECT 
    se.id::text as id,
    se.requester_id::text as requester_id,
    se.target_id::text as target_id,
    se.shift_date,
    se.original_shift_start,
    se.original_shift_end,
    se.requested_shift_start,
    se.requested_shift_end,
    se.exchange_type,
    se.status,
    se.reason,
    se.exchange_code,
    se.created_at,
    se.approved_by::text as approved_by,
    se.approved_at,
    se.rejected_reason,
    se.priority_level,
    u1.first_name || '' '' || u1.last_name as requester_name,
    u2.first_name || '' '' || u2.last_name as target_name,
    u3.first_name || '' '' || u3.last_name as approved_by_name,
    CASE 
        WHEN se.status = ''pending'' AND se.created_at < CURRENT_TIMESTAMP - INTERVAL ''24 hours'' THEN ''urgent''
        WHEN se.priority_level = ''high'' THEN ''high''
        ELSE ''normal''
    END as urgency_status
FROM shift_exchanges se
LEFT JOIN employees u1 ON se.requester_id = u1.id
LEFT JOIN employees u2 ON se.target_id = u2.id
LEFT JOIN employees u3 ON se.approved_by = u3.id
WHERE ($1::uuid IS NULL OR se.requester_id = $1)
    AND ($2::uuid IS NULL OR se.target_id = $2)
    AND ($3 IS NULL OR se.status = $3)
    AND ($4::date IS NULL OR se.shift_date = $4)
ORDER BY se.created_at DESC;

-- Create shift exchange request
INSERT INTO shift_exchanges (
    requester_id,
    target_id,
    shift_date,
    original_shift_start,
    original_shift_end,
    requested_shift_start,
    requested_shift_end,
    exchange_type,
    reason,
    priority_level,
    exchange_code
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, generate_exchange_code())
RETURNING id, exchange_code, status, created_at;';
```

#### Table 2: exchange_requests
```sql
COMMENT ON TABLE exchange_requests IS
'API Contract: GET /api/v1/shift-exchange/requests
params: {employee_id?: UUID, department_id?: UUID, request_type?: string, status?: string}
returns: [{
    id: UUID,
    employee_id: UUID,
    department_id: UUID,
    request_type: string,
    shift_date: date,
    preferred_shift_start: timestamp,
    preferred_shift_end: timestamp,
    alternative_dates: array,
    constraints: object,
    compensation_offered: object,
    request_details: object,
    status: string,
    match_criteria: object,
    auto_match_enabled: boolean,
    expiry_date: timestamp,
    created_at: timestamp,
    updated_at: timestamp
}]

POST /api/v1/shift-exchange/requests
expects: {
    shift_date: date,
    preferred_shift_start: timestamp,
    preferred_shift_end: timestamp,
    request_type: string,
    alternative_dates?: array,
    constraints?: object,
    compensation_offered?: object,
    match_criteria?: object,
    auto_match_enabled?: boolean,
    expiry_date?: timestamp
}
returns: {id: UUID, status: string, match_count: int, created_at: timestamp}

PUT /api/v1/shift-exchange/requests/:id/criteria
expects: {
    match_criteria: object,
    auto_match_enabled: boolean,
    constraints?: object
}
returns: {id: UUID, updated_at: timestamp, new_matches: int}

Helper Queries:
-- Get exchange requests with matching analysis
SELECT 
    er.id::text as id,
    er.employee_id::text as employee_id,
    er.department_id::text as department_id,
    er.request_type,
    er.shift_date,
    er.preferred_shift_start,
    er.preferred_shift_end,
    er.alternative_dates,
    er.constraints,
    er.compensation_offered,
    er.request_details,
    er.status,
    er.match_criteria,
    er.auto_match_enabled,
    er.expiry_date,
    er.created_at,
    er.updated_at,
    e.first_name || '' '' || e.last_name as employee_name,
    d.name as department_name,
    CASE 
        WHEN er.expiry_date < CURRENT_TIMESTAMP THEN ''expired''
        WHEN er.status = ''active'' AND er.auto_match_enabled THEN ''auto_matching''
        ELSE er.status
    END as effective_status,
    (
        SELECT COUNT(*) 
        FROM exchange_requests er2 
        WHERE er2.department_id = er.department_id 
            AND er2.shift_date = er.shift_date 
            AND er2.id != er.id 
            AND er2.status = ''active''
    ) as potential_matches
FROM exchange_requests er
LEFT JOIN employees e ON er.employee_id = e.id
LEFT JOIN departments d ON er.department_id = d.id
WHERE ($1::uuid IS NULL OR er.employee_id = $1)
    AND ($2::uuid IS NULL OR er.department_id = $2)
    AND ($3 IS NULL OR er.request_type = $3)
    AND ($4 IS NULL OR er.status = $4)
ORDER BY er.created_at DESC;

-- Create exchange request with auto-matching
INSERT INTO exchange_requests (
    employee_id,
    department_id,
    request_type,
    shift_date,
    preferred_shift_start,
    preferred_shift_end,
    alternative_dates,
    constraints,
    compensation_offered,
    match_criteria,
    auto_match_enabled,
    expiry_date
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
RETURNING id, status, created_at, 
    (SELECT find_exchange_matches(id)) as match_count;';
```

#### Table 3: exchange_responses
```sql
COMMENT ON TABLE exchange_responses IS
'API Contract: GET /api/v1/shift-exchange/responses
params: {exchange_id?: UUID, responder_id?: UUID, response_type?: string, status?: string}
returns: [{
    id: UUID,
    exchange_id: UUID,
    responder_id: UUID,
    response_type: string,
    response_details: object,
    counter_offer: object,
    acceptance_conditions: object,
    notification_preferences: object,
    response_timestamp: timestamp,
    status: string,
    processing_notes: string,
    auto_generated: boolean
}]

POST /api/v1/shift-exchange/responses
expects: {
    exchange_id: UUID,
    response_type: string,
    response_details?: object,
    counter_offer?: object,
    acceptance_conditions?: object,
    notification_preferences?: object
}
returns: {id: UUID, status: string, response_timestamp: timestamp, processing_status: string}

PUT /api/v1/shift-exchange/responses/:id/process
expects: {
    processing_action: string,
    processing_notes?: string
}
returns: {id: UUID, status: string, exchange_status: string, notifications_sent: array}

Helper Queries:
-- Get exchange responses with detailed context
SELECT 
    er.id::text as id,
    er.exchange_id::text as exchange_id,
    er.responder_id::text as responder_id,
    er.response_type,
    er.response_details,
    er.counter_offer,
    er.acceptance_conditions,
    er.notification_preferences,
    er.response_timestamp,
    er.status,
    er.processing_notes,
    er.auto_generated,
    e.first_name || '' '' || e.last_name as responder_name,
    se.exchange_code,
    se.shift_date,
    se.status as exchange_status,
    req.first_name || '' '' || req.last_name as requester_name,
    CASE 
        WHEN er.response_type = ''accept'' AND er.status = ''pending'' THEN ''ready_to_process''
        WHEN er.response_type = ''counter'' AND er.status = ''pending'' THEN ''requires_review''
        WHEN er.response_type = ''decline'' THEN ''closed''
        ELSE er.status
    END as processing_status
FROM exchange_responses er
LEFT JOIN employees e ON er.responder_id = e.id
LEFT JOIN shift_exchanges se ON er.exchange_id = se.id
LEFT JOIN employees req ON se.requester_id = req.id
WHERE ($1::uuid IS NULL OR er.exchange_id = $1)
    AND ($2::uuid IS NULL OR er.responder_id = $2)
    AND ($3 IS NULL OR er.response_type = $3)
    AND ($4 IS NULL OR er.status = $4)
ORDER BY er.response_timestamp DESC;

-- Process exchange response
SELECT process_exchange_response($1, $2, $3);';
```

#### Table 4: exchange_history
```sql
COMMENT ON TABLE exchange_history IS
'API Contract: GET /api/v1/shift-exchange/history
params: {employee_id?: UUID, exchange_id?: UUID, action_type?: string, date_from?: YYYY-MM-DD}
returns: [{
    id: UUID,
    exchange_id: UUID,
    employee_id: UUID,
    action_type: string,
    action_details: object,
    system_data: object,
    timestamp: timestamp,
    ip_address: string,
    user_agent: string,
    session_id: string,
    correlation_id: string
}]

POST /api/v1/shift-exchange/history
expects: {
    exchange_id: UUID,
    action_type: string,
    action_details: object,
    system_data?: object
}
returns: {id: UUID, timestamp: timestamp, correlation_id: string}

Helper Queries:
-- Get exchange history with employee and exchange details
SELECT 
    eh.id::text as id,
    eh.exchange_id::text as exchange_id,
    eh.employee_id::text as employee_id,
    eh.action_type,
    eh.action_details,
    eh.system_data,
    eh.timestamp,
    eh.ip_address,
    eh.user_agent,
    eh.session_id,
    eh.correlation_id,
    e.first_name || '' '' || e.last_name as employee_name,
    se.exchange_code,
    se.shift_date,
    se.status as current_exchange_status,
    CASE 
        WHEN eh.action_type IN (''created'', ''approved'', ''completed'') THEN ''success''
        WHEN eh.action_type IN (''rejected'', ''cancelled'', ''expired'') THEN ''failure''
        WHEN eh.action_type IN (''modified'', ''responded'') THEN ''update''
        ELSE ''info''
    END as action_category,
    LAG(eh.timestamp) OVER (PARTITION BY eh.exchange_id ORDER BY eh.timestamp) as previous_action_time,
    EXTRACT(epoch FROM (eh.timestamp - LAG(eh.timestamp) OVER (PARTITION BY eh.exchange_id ORDER BY eh.timestamp)))/60 as minutes_since_previous
FROM exchange_history eh
LEFT JOIN employees e ON eh.employee_id = e.id
LEFT JOIN shift_exchanges se ON eh.exchange_id = se.id
WHERE ($1::uuid IS NULL OR eh.employee_id = $1)
    AND ($2::uuid IS NULL OR eh.exchange_id = $2)
    AND ($3 IS NULL OR eh.action_type = $3)
    AND ($4::date IS NULL OR eh.timestamp::date >= $4)
ORDER BY eh.timestamp DESC;

-- Log exchange action
INSERT INTO exchange_history (
    exchange_id,
    employee_id,
    action_type,
    action_details,
    system_data,
    ip_address,
    user_agent,
    session_id,
    correlation_id
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, generate_correlation_id())
RETURNING id, timestamp, correlation_id;';
```

#### Table 5: exchange_system_integration
```sql
COMMENT ON TABLE exchange_system_integration IS
'API Contract: GET /api/v1/shift-exchange/system-integration
params: {integration_type?: string, status?: string, external_system?: string}
returns: [{
    id: UUID,
    exchange_id: UUID,
    integration_type: string,
    external_system: string,
    external_reference_id: string,
    payload_sent: object,
    response_received: object,
    status: string,
    retry_count: int,
    last_retry_at: timestamp,
    next_retry_at: timestamp,
    error_details: object,
    success_timestamp: timestamp,
    created_at: timestamp,
    updated_at: timestamp
}]

POST /api/v1/shift-exchange/system-integration
expects: {
    exchange_id: UUID,
    integration_type: string,
    external_system: string,
    payload_sent: object,
    retry_policy?: object
}
returns: {id: UUID, status: string, external_reference_id: string, created_at: timestamp}

PUT /api/v1/shift-exchange/system-integration/:id/retry
expects: {
    force_retry?: boolean,
    updated_payload?: object
}
returns: {id: UUID, retry_count: int, next_retry_at: timestamp, status: string}

Helper Queries:
-- Get system integration status with retry management
SELECT 
    esi.id::text as id,
    esi.exchange_id::text as exchange_id,
    esi.integration_type,
    esi.external_system,
    esi.external_reference_id,
    esi.payload_sent,
    esi.response_received,
    esi.status,
    esi.retry_count,
    esi.last_retry_at,
    esi.next_retry_at,
    esi.error_details,
    esi.success_timestamp,
    esi.created_at,
    esi.updated_at,
    se.exchange_code,
    se.shift_date,
    se.status as exchange_status,
    CASE 
        WHEN esi.status = ''success'' THEN ''completed''
        WHEN esi.status = ''failed'' AND esi.retry_count >= 3 THEN ''abandoned''
        WHEN esi.status = ''failed'' AND esi.next_retry_at <= CURRENT_TIMESTAMP THEN ''ready_for_retry''
        WHEN esi.status = ''pending'' THEN ''in_progress''
        ELSE esi.status
    END as processing_status,
    CASE 
        WHEN esi.success_timestamp IS NOT NULL THEN 
            EXTRACT(epoch FROM (esi.success_timestamp - esi.created_at))/60
        ELSE NULL
    END as processing_duration_minutes
FROM exchange_system_integration esi
LEFT JOIN shift_exchanges se ON esi.exchange_id = se.id
WHERE ($1 IS NULL OR esi.integration_type = $1)
    AND ($2 IS NULL OR esi.status = $2)
    AND ($3 IS NULL OR esi.external_system = $3)
ORDER BY esi.created_at DESC;

-- Create integration record
INSERT INTO exchange_system_integration (
    exchange_id,
    integration_type,
    external_system,
    payload_sent,
    external_reference_id
) VALUES ($1, $2, $3, $4, generate_external_reference())
RETURNING id, status, external_reference_id, created_at;

-- Schedule integration retry
UPDATE exchange_system_integration 
SET retry_count = retry_count + 1,
    last_retry_at = CURRENT_TIMESTAMP,
    next_retry_at = CURRENT_TIMESTAMP + (INTERVAL ''1 hour'' * retry_count),
    status = ''pending''
WHERE id = $1 AND status = ''failed'' AND retry_count < 3
RETURNING id, retry_count, next_retry_at, status;';
```

### Step 3: Create Test Data for Shift Exchange System
```sql
-- Insert test shift exchange
INSERT INTO shift_exchanges (
    requester_id,
    target_id,
    shift_date,
    original_shift_start,
    original_shift_end,
    requested_shift_start,
    requested_shift_end,
    exchange_type,
    status,
    reason,
    exchange_code,
    priority_level
)
SELECT 
    e1.id as requester_id,
    e2.id as target_id,
    CURRENT_DATE + INTERVAL '3 days' as shift_date,
    (CURRENT_DATE + INTERVAL '3 days')::timestamp + INTERVAL '9 hours' as original_shift_start,
    (CURRENT_DATE + INTERVAL '3 days')::timestamp + INTERVAL '17 hours' as original_shift_end,
    (CURRENT_DATE + INTERVAL '3 days')::timestamp + INTERVAL '13 hours' as requested_shift_start,
    (CURRENT_DATE + INTERVAL '3 days')::timestamp + INTERVAL '21 hours' as requested_shift_end,
    'shift_swap',
    'pending'::exchange_status,
    'Medical appointment conflicts with current shift',
    'EXC-' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-001',
    'high'
FROM employees e1, employees e2
WHERE e1.username = 'system' AND e2.username = 'admin'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test exchange request
INSERT INTO exchange_requests (
    employee_id,
    department_id,
    request_type,
    shift_date,
    preferred_shift_start,
    preferred_shift_end,
    alternative_dates,
    constraints,
    compensation_offered,
    request_details,
    status,
    match_criteria,
    auto_match_enabled,
    expiry_date
)
SELECT 
    e.id,
    d.id,
    'time_swap',
    CURRENT_DATE + INTERVAL '5 days',
    (CURRENT_DATE + INTERVAL '5 days')::timestamp + INTERVAL '14 hours',
    (CURRENT_DATE + INTERVAL '5 days')::timestamp + INTERVAL '22 hours',
    ARRAY[CURRENT_DATE + INTERVAL '6 days', CURRENT_DATE + INTERVAL '7 days'],
    '{
        "skill_requirements": ["customer_support", "technical_support"],
        "department_restrictions": ["Customer Support"],
        "seniority_level": "any"
    }'::jsonb,
    '{
        "overtime_compensation": true,
        "premium_rate": 1.5,
        "additional_benefits": ["preferred_parking"]
    }'::jsonb,
    '{
        "reason": "Family event attendance",
        "urgency": "high",
        "flexibility": "moderate"
    }'::jsonb,
    'active',
    '{
        "same_department": true,
        "similar_skills": true,
        "experience_level": "any"
    }'::jsonb,
    true,
    CURRENT_DATE + INTERVAL '10 days'
FROM employees e
JOIN departments d ON d.name = 'Customer Support'
WHERE e.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test exchange response
INSERT INTO exchange_responses (
    exchange_id,
    responder_id,
    response_type,
    response_details,
    counter_offer,
    acceptance_conditions,
    notification_preferences,
    status,
    auto_generated
)
SELECT 
    se.id,
    e.id,
    'accept',
    '{
        "response_reason": "Happy to help colleague",
        "availability_confirmed": true,
        "skills_verified": true
    }'::jsonb,
    '{
        "additional_compensation": false,
        "future_favor": true
    }'::jsonb,
    '{
        "manager_approval": true,
        "written_confirmation": true
    }'::jsonb,
    '{
        "email": true,
        "sms": false,
        "push_notification": true
    }'::jsonb,
    'pending',
    false
FROM shift_exchanges se, employees e
WHERE se.exchange_code LIKE 'EXC-%' 
    AND e.username = 'admin'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test exchange history
INSERT INTO exchange_history (
    exchange_id,
    employee_id,
    action_type,
    action_details,
    system_data,
    ip_address,
    user_agent,
    session_id,
    correlation_id
)
SELECT 
    se.id,
    se.requester_id,
    'created',
    '{
        "action_description": "Shift exchange request created",
        "form_data": {"reason": "Medical appointment", "priority": "high"},
        "validation_status": "passed"
    }'::jsonb,
    '{
        "application_version": "1.0.0",
        "feature_flags": ["shift_exchange_v2", "auto_matching"],
        "performance_metrics": {"response_time": 245}
    }'::jsonb,
    '192.168.1.100',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'sess_' || generate_random_uuid()::text,
    'corr_' || generate_random_uuid()::text
FROM shift_exchanges se
WHERE se.exchange_code LIKE 'EXC-%'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test system integration
INSERT INTO exchange_system_integration (
    exchange_id,
    integration_type,
    external_system,
    external_reference_id,
    payload_sent,
    response_received,
    status,
    retry_count,
    success_timestamp
)
SELECT 
    se.id,
    'schedule_update',
    '1C ZUP',
    '1C-REF-' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS'),
    '{
        "exchange_id": "' || se.id || '",
        "employee_data": {
            "requester": {"id": "' || se.requester_id || '", "name": "Test Employee"},
            "target": {"id": "' || se.target_id || '", "name": "Test Admin"}
        },
        "schedule_changes": {
            "date": "' || se.shift_date || '",
            "original_shift": "09:00-17:00",
            "new_shift": "13:00-21:00"
        }
    }'::jsonb,
    '{
        "status": "success",
        "transaction_id": "TXN-12345",
        "updated_at": "' || CURRENT_TIMESTAMP || '",
        "confirmation_code": "CONF-67890"
    }'::jsonb,
    'success',
    0,
    CURRENT_TIMESTAMP
FROM shift_exchanges se
WHERE se.exchange_code LIKE 'EXC-%'
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/shift-exchange%' 
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
WHERE relname IN ('shift_exchanges', 'exchange_requests', 'exchange_responses', 'exchange_history', 'exchange_system_integration')
ORDER BY relname;"
```

### Step 5: Test Sample Queries
```sql
-- Test shift exchanges with employee details
SELECT 
    se.exchange_code,
    se.shift_date,
    se.status,
    se.exchange_type,
    se.priority_level,
    CASE 
        WHEN se.status = 'pending' AND se.created_at < CURRENT_TIMESTAMP - INTERVAL '24 hours' THEN 'Urgent'
        WHEN se.priority_level = 'high' THEN 'High Priority'
        ELSE 'Normal'
    END as urgency_status
FROM shift_exchanges se
ORDER BY se.created_at DESC
LIMIT 3;

-- Test exchange requests with matching analysis
SELECT 
    er.request_type,
    er.shift_date,
    er.status,
    er.auto_match_enabled,
    CASE 
        WHEN er.expiry_date < CURRENT_TIMESTAMP THEN 'Expired'
        WHEN er.status = 'active' AND er.auto_match_enabled THEN 'Auto Matching'
        ELSE er.status
    END as effective_status
FROM exchange_requests er
ORDER BY er.created_at DESC
LIMIT 3;

-- Test exchange responses with processing status
SELECT 
    er.response_type,
    er.status,
    er.response_timestamp,
    er.auto_generated,
    CASE 
        WHEN er.response_type = 'accept' AND er.status = 'pending' THEN 'Ready to Process'
        WHEN er.response_type = 'counter' AND er.status = 'pending' THEN 'Requires Review'
        WHEN er.response_type = 'decline' THEN 'Closed'
        ELSE er.status
    END as processing_status
FROM exchange_responses er
ORDER BY er.response_timestamp DESC
LIMIT 3;

-- Test system integration status
SELECT 
    esi.integration_type,
    esi.external_system,
    esi.status,
    esi.retry_count,
    CASE 
        WHEN esi.status = 'success' THEN 'Completed'
        WHEN esi.status = 'failed' AND esi.retry_count >= 3 THEN 'Abandoned'
        WHEN esi.status = 'failed' AND esi.next_retry_at <= CURRENT_TIMESTAMP THEN 'Ready for Retry'
        WHEN esi.status = 'pending' THEN 'In Progress'
        ELSE esi.status
    END as processing_status
FROM exchange_system_integration esi
ORDER BY esi.created_at DESC
LIMIT 3;
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 5 tables have specific shift exchange API contract comments
- [ ] Each table has GET and POST/PUT endpoints documented 
- [ ] Helper queries include proper parameter binding ($1, $2, etc.)
- [ ] Test data exists demonstrating complete exchange workflow lifecycle
- [ ] Verification query shows ✅ for all tables
- [ ] Sample queries execute successfully
- [ ] Exchange functions are available (generate_exchange_code, process_exchange_response, etc.)

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_008: Complete - 5 shift exchange system tables documented with proper API contracts and workflow automation" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If foreign key references fail:
- Check that referenced tables (employees, departments, shift_exchanges) exist
- Use existing records for test data

If functions are missing:
- Check that exchange functions (generate_exchange_code, process_exchange_response, etc.) exist
- Document any missing functions

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Key Features Documented

1. **Shift Exchange Management**: Core exchange requests with approval workflow and priority handling
2. **Request Matching**: Automated matching system with configurable criteria and constraints
3. **Response Processing**: Comprehensive response handling including counter-offers and acceptance conditions
4. **Audit Trail**: Complete history tracking with correlation IDs and system metadata
5. **System Integration**: 1C ZUP integration with retry policies and error handling
6. **Workflow Automation**: End-to-end automation from request creation to system synchronization

This completes the shift exchange system documentation with production-ready API contracts and comprehensive workflow automation capabilities.