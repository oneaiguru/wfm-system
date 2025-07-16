# 📋 SUBAGENT TASK: Table Documentation Batch 003

## 🎯 Task Information
- **Task ID**: DOC_TABLES_003
- **Priority**: High
- **Estimated Time**: 20 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 4 tables with API contracts:

1. **service_level_settings**
2. **services**
3. **shift_assignments**
4. **shift_exchanges**

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    obj_description(oid, 'pg_class') as current_comment
FROM pg_class 
WHERE relname IN ('service_level_settings', 'services', 'shift_assignments', 'shift_exchanges')
ORDER BY relname;"
```

### Step 2: Apply API Contracts

Execute these commands in order:

#### Table 1: service_level_settings
```sql
COMMENT ON TABLE service_level_settings IS 
'API Contract: GET /api/v1/service-levels
params: {service_id?: UUID, active?: boolean}
returns: [{id: UUID, service_id: UUID, target_seconds: int, target_percentage: float, calculation_method: string}]

Helper Queries:
-- Get service level settings
SELECT 
    id::text as id,
    service_id::text as service_id,
    target_seconds,
    target_percentage,
    calculation_method
FROM service_level_settings
WHERE ($1::uuid IS NULL OR service_id = $1)
    AND ($2::boolean IS NULL OR is_active = $2)
ORDER BY service_id;

-- Update service level
UPDATE service_level_settings
SET target_seconds = $2,
    target_percentage = $3,
    updated_at = NOW()
WHERE id = $1
RETURNING *;';
```

#### Table 2: services
```sql
COMMENT ON TABLE services IS
'API Contract: GET /api/v1/services
params: {site_id?: UUID, status?: string}
returns: [{id: UUID, service_name: string, service_type: string, site_id: UUID, status: string}]

Helper Queries:
-- Get all services
SELECT 
    s.id::text as id,
    s.service_name,
    s.service_type,
    s.site_id::text as site_id,
    s.status
FROM services s
WHERE ($1::uuid IS NULL OR s.site_id = $1)
    AND ($2 IS NULL OR s.status = $2)
ORDER BY s.service_name;

-- Get service with metrics
SELECT 
    s.id::text as id,
    s.service_name,
    sl.target_seconds,
    sl.target_percentage
FROM services s
LEFT JOIN service_level_settings sl ON s.id = sl.service_id
WHERE s.id = $1;';
```

#### Table 3: shift_assignments
```sql
COMMENT ON TABLE shift_assignments IS
'API Contract: GET /api/v1/shift-assignments
params: {agent_id?: UUID, date?: YYYY-MM-DD, status?: string}
returns: [{id: UUID, agent_id: UUID, shift_id: UUID, assignment_date: date, status: string}]

POST /api/v1/shift-assignments
expects: {agent_id: UUID, shift_id: UUID, assignment_date: date}
returns: {id: UUID, agent_id: UUID, shift_id: UUID, assignment_date: date, status: string}

Helper Queries:
-- Get agent shift assignments
SELECT 
    sa.id::text as id,
    sa.agent_id::text as agent_id,
    sa.shift_id::text as shift_id,
    sa.assignment_date::text as assignment_date,
    sa.status,
    s.start_time,
    s.end_time
FROM shift_assignments sa
JOIN shifts s ON sa.shift_id = s.id
WHERE ($1::uuid IS NULL OR sa.agent_id = $1)
    AND ($2::date IS NULL OR sa.assignment_date = $2)
    AND ($3 IS NULL OR sa.status = $3)
ORDER BY sa.assignment_date, s.start_time;

-- Create shift assignment
INSERT INTO shift_assignments (agent_id, shift_id, assignment_date, status)
VALUES ($1, $2, $3, ''assigned'')
RETURNING id, agent_id, shift_id, assignment_date, status;';
```

#### Table 4: shift_exchanges
```sql
COMMENT ON TABLE shift_exchanges IS
'API Contract: GET /api/v1/shift-exchanges
params: {requester_id?: UUID, status?: string}
returns: [{id: UUID, requester_id: UUID, target_id: UUID, shift_date: date, status: string, reason: string}]

POST /api/v1/shift-exchanges
expects: {requester_id: UUID, target_id: UUID, shift_date: date, reason: string}
returns: {id: UUID, exchange_code: string, status: string}

Helper Queries:
-- Get shift exchange requests
SELECT 
    se.id::text as id,
    se.requester_id::text as requester_id,
    se.target_id::text as target_id,
    se.shift_date::text as shift_date,
    se.status,
    se.reason,
    se.exchange_code
FROM shift_exchanges se
WHERE ($1::uuid IS NULL OR se.requester_id = $1 OR se.target_id = $1)
    AND ($2 IS NULL OR se.status = $2)
ORDER BY se.created_at DESC;

-- Approve shift exchange
UPDATE shift_exchanges
SET status = ''approved'',
    approved_by = $2,
    approved_at = NOW()
WHERE id = $1 AND status = ''pending''
RETURNING *;';
```

### Step 3: Create Test Data
```sql
-- Insert test service
INSERT INTO services (service_name, service_type, status)
VALUES ('Техническая поддержка', 'inbound', 'active')
ON CONFLICT DO NOTHING;

-- Insert service level settings
INSERT INTO service_level_settings (service_id, target_seconds, target_percentage, calculation_method)
SELECT 
    id as service_id,
    20 as target_seconds,
    80.0 as target_percentage,
    '80/20' as calculation_method
FROM services
WHERE service_name = 'Техническая поддержка'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test shift assignment
INSERT INTO shift_assignments (agent_id, shift_id, assignment_date, status)
SELECT 
    e.id as agent_id,
    s.id as shift_id,
    CURRENT_DATE as assignment_date,
    'assigned' as status
FROM employees e
CROSS JOIN shifts s
WHERE e.first_name = 'Анна'
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract:%' 
        THEN '✅ Documented'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('service_level_settings', 'services', 'shift_assignments', 'shift_exchanges')
ORDER BY relname;"
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 4 tables have API contract comments
- [ ] Helper queries are included in comments
- [ ] Test data exists for services and shifts
- [ ] Verification query shows ✅ for all tables

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_003: Complete - 4 tables documented" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Next Task
After completion, proceed to: SUBAGENT_TASK_DOC_TABLES_004.md