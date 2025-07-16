# 📋 SUBAGENT TASK: Table Documentation Batch 002

## 🎯 Task Information
- **Task ID**: DOC_TABLES_002
- **Priority**: High
- **Estimated Time**: 20 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 4 tables with API contracts:

1. **activity_logs**
2. **agent_activity**
3. **agent_groups**
4. **agent_performance_metrics**

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    obj_description(oid, 'pg_class') as current_comment
FROM pg_class 
WHERE relname IN ('activity_logs', 'agent_activity', 'agent_groups', 'agent_performance_metrics')
ORDER BY relname;"
```

### Step 2: Apply API Contracts

#### Table 1: activity_logs
```sql
COMMENT ON TABLE activity_logs IS 
'API Contract: GET /api/v1/activity-logs
params: {agent_id?: UUID, date?: YYYY-MM-DD, activity_type?: string}
returns: [{id: UUID, agent_id: UUID, activity_type: string, start_time: timestamp, duration_seconds: int}]

Helper Queries:
-- Get agent activities for date
SELECT 
    id::text as id,
    agent_id::text as agent_id,
    activity_type,
    start_time,
    duration_seconds
FROM activity_logs
WHERE ($1::uuid IS NULL OR agent_id = $1)
    AND ($2::date IS NULL OR start_time::date = $2)
    AND ($3 IS NULL OR activity_type = $3)
ORDER BY start_time DESC;';
```

#### Table 2: agent_activity
```sql
COMMENT ON TABLE agent_activity IS
'API Contract: GET /api/v1/agents/{agent_id}/current-activity
returns: {agent_id: UUID, current_status: string, current_queue?: UUID, last_update: timestamp}

Helper Queries:
-- Get current agent status
SELECT 
    agent_id::text as agent_id,
    current_status,
    current_queue::text as current_queue,
    last_update
FROM agent_activity
WHERE agent_id = $1;

-- Update agent status
UPDATE agent_activity 
SET current_status = $2, 
    current_queue = $3, 
    last_update = NOW()
WHERE agent_id = $1
RETURNING *;';
```

#### Table 3: agent_groups
```sql
COMMENT ON TABLE agent_groups IS
'API Contract: GET /api/v1/agent-groups
returns: [{id: UUID, group_name: string, description: string, member_count: int}]

Helper Queries:
-- Get all groups with member count
SELECT 
    ag.id::text as id,
    ag.group_name,
    ag.description,
    COUNT(agm.agent_id) as member_count
FROM agent_groups ag
LEFT JOIN agent_group_members agm ON ag.id = agm.group_id
GROUP BY ag.id
ORDER BY ag.group_name;

-- Get agents in group
SELECT 
    e.id::text as agent_id,
    e.first_name || '' '' || e.last_name as agent_name
FROM agent_group_members agm
JOIN employees e ON agm.agent_id = e.id
WHERE agm.group_id = $1;';
```

#### Table 4: agent_performance_metrics
```sql
COMMENT ON TABLE agent_performance_metrics IS
'API Contract: GET /api/v1/agents/{agent_id}/performance
params: {date_from: YYYY-MM-DD, date_to: YYYY-MM-DD}
returns: {agent_id: UUID, metrics: [{date: YYYY-MM-DD, aht: float, occupancy: float, adherence: float}]}

Helper Queries:
-- Get agent performance metrics
SELECT 
    agent_id::text as agent_id,
    metric_date::text as date,
    avg_handle_time as aht,
    occupancy_rate as occupancy,
    schedule_adherence as adherence
FROM agent_performance_metrics
WHERE agent_id = $1
    AND metric_date BETWEEN $2 AND $3
ORDER BY metric_date;

-- Calculate average performance
SELECT 
    agent_id::text as agent_id,
    AVG(avg_handle_time) as avg_aht,
    AVG(occupancy_rate) as avg_occupancy,
    AVG(schedule_adherence) as avg_adherence
FROM agent_performance_metrics
WHERE agent_id = $1
    AND metric_date BETWEEN $2 AND $3
GROUP BY agent_id;';
```

### Step 3: Create Test Data
```sql
-- Insert test agent activity
INSERT INTO agent_activity (agent_id, current_status, last_update)
SELECT 
    id as agent_id,
    'available' as current_status,
    NOW() as last_update
FROM employees
WHERE first_name = 'Петр'
LIMIT 1
ON CONFLICT (agent_id) DO UPDATE 
SET current_status = 'available', last_update = NOW();

-- Insert test performance metrics
INSERT INTO agent_performance_metrics (agent_id, metric_date, avg_handle_time, occupancy_rate, schedule_adherence)
SELECT 
    id as agent_id,
    CURRENT_DATE as metric_date,
    180.5 as avg_handle_time,
    85.2 as occupancy_rate,
    92.5 as schedule_adherence
FROM employees
WHERE first_name = 'Петр'
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
WHERE relname IN ('activity_logs', 'agent_activity', 'agent_groups', 'agent_performance_metrics')
ORDER BY relname;"
```

## ✅ Success Criteria

- [ ] All 4 tables have API contract comments
- [ ] Helper queries test with real agent IDs
- [ ] Test data exists for agent_activity
- [ ] Performance metrics include Russian agent

## 📊 Progress Update

```bash
echo "DOC_TABLES_002: Complete - 4 tables documented" >> /project/subagent_tasks/progress_tracking/completed.log
```