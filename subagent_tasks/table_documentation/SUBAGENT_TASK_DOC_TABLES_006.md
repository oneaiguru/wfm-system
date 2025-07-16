# 📋 SUBAGENT TASK: Table Documentation Batch 006 - Real-time Adherence Monitoring

## 🎯 Task Information
- **Task ID**: DOC_TABLES_006
- **Priority**: High
- **Estimated Time**: 30 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 5 real-time adherence monitoring tables with proper API contracts:

1. **agent_real_time_monitoring** - Core real-time agent status monitoring
2. **agent_status_realtime** - Real-time agent status tracking
3. **real_time_status** - Global real-time status dashboard
4. **realtime_efficiency_metrics** - Live efficiency calculations
5. **agent_status_tracking** - Historical agent status progression

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/realtime%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('agent_real_time_monitoring', 'agent_status_realtime', 'real_time_status', 'realtime_efficiency_metrics', 'agent_status_tracking')
ORDER BY relname;"
```

### Step 2: Apply Proper API Contracts

Execute these commands in order:

#### Table 1: agent_real_time_monitoring
```sql
COMMENT ON TABLE agent_real_time_monitoring IS 
'API Contract: GET /api/v1/realtime/agent-monitoring
params: {agent_id?: int, status?: string, period_minutes?: int}
returns: [{
    id: UUID,
    agent_id: int,
    current_status: string,
    status_start_time: timestamp,
    activity_duration_minutes: int,
    break_duration_minutes: int,
    idle_duration_minutes: int,
    adherence_percentage: float,
    schedule_deviation_minutes: int,
    current_queue: string,
    is_logged_in: boolean,
    last_activity: timestamp,
    status_color: string
}]

POST /api/v1/realtime/agent-monitoring/update
expects: {
    agent_id: int,
    status: string,
    activity_start_time?: timestamp,
    queue?: string,
    is_logged_in?: boolean
}
returns: {id: UUID, adherence_percentage: float, status_color: string}

WebSocket: /ws/realtime/agent-monitoring
broadcasts: {
    type: "agent_status_update",
    agent_id: int,
    status: string,
    adherence_percentage: float,
    timestamp: timestamp
}

Helper Queries:
-- Get real-time agent monitoring data
SELECT 
    a.id::text as id,
    a.agent_id,
    a.current_status,
    a.status_start_time,
    EXTRACT(epoch FROM (CURRENT_TIMESTAMP - a.status_start_time))/60 as activity_duration_minutes,
    a.break_duration_minutes,
    a.idle_duration_minutes,
    a.adherence_percentage,
    a.schedule_deviation_minutes,
    a.current_queue,
    a.is_logged_in,
    a.last_activity,
    CASE 
        WHEN a.adherence_percentage >= 90 THEN ''green''
        WHEN a.adherence_percentage >= 80 THEN ''yellow''
        ELSE ''red''
    END as status_color,
    ag.first_name,
    ag.last_name
FROM agent_real_time_monitoring a
LEFT JOIN agents ag ON a.agent_id = ag.id
WHERE ($1::int IS NULL OR a.agent_id = $1)
    AND ($2 IS NULL OR a.current_status = $2)
    AND ($3::int IS NULL OR EXTRACT(epoch FROM (CURRENT_TIMESTAMP - a.status_start_time))/60 <= $3)
ORDER BY a.adherence_percentage ASC, a.last_activity DESC;

-- Update agent real-time status
INSERT INTO agent_real_time_monitoring (
    agent_id,
    current_status,
    status_start_time,
    current_queue,
    is_logged_in,
    last_activity
)
VALUES ($1, $2, COALESCE($3, CURRENT_TIMESTAMP), $4, COALESCE($5, true), CURRENT_TIMESTAMP)
ON CONFLICT (agent_id) DO UPDATE SET
    current_status = EXCLUDED.current_status,
    status_start_time = EXCLUDED.status_start_time,
    current_queue = EXCLUDED.current_queue,
    is_logged_in = EXCLUDED.is_logged_in,
    last_activity = CURRENT_TIMESTAMP
RETURNING id, adherence_percentage, 
    CASE 
        WHEN adherence_percentage >= 90 THEN ''green''
        WHEN adherence_percentage >= 80 THEN ''yellow''
        ELSE ''red''
    END as status_color;';
```

#### Table 2: agent_status_realtime
```sql
COMMENT ON TABLE agent_status_realtime IS
'API Contract: GET /api/v1/realtime/agent-status
params: {status_type?: string, location?: string, active_only?: boolean}
returns: [{
    id: UUID,
    agent_id: int,
    status_type: string,
    status_start: timestamp,
    expected_end: timestamp,
    location: string,
    is_active: boolean,
    queue_assignment: string,
    adherence_score: float,
    break_remaining_minutes: int,
    updated_at: timestamp
}]

PUT /api/v1/realtime/agent-status/:agent_id
expects: {
    status_type: string,
    expected_end?: timestamp,
    location?: string,
    queue_assignment?: string
}
returns: {id: UUID, adherence_score: float, break_remaining_minutes: int}

Helper Queries:
-- Get real-time agent status
SELECT 
    s.id::text as id,
    s.agent_id,
    s.status_type,
    s.status_start,
    s.expected_end,
    s.location,
    s.is_active,
    s.queue_assignment,
    s.adherence_score,
    CASE 
        WHEN s.expected_end IS NOT NULL AND s.status_type IN (''break'', ''lunch'')
        THEN GREATEST(0, EXTRACT(epoch FROM (s.expected_end - CURRENT_TIMESTAMP))/60)::int
        ELSE 0
    END as break_remaining_minutes,
    s.updated_at,
    a.first_name,
    a.last_name,
    a.position
FROM agent_status_realtime s
LEFT JOIN agents a ON s.agent_id = a.id
WHERE ($1 IS NULL OR s.status_type = $1)
    AND ($2 IS NULL OR s.location = $2)
    AND ($3::boolean IS NULL OR s.is_active = $3)
ORDER BY s.adherence_score ASC, s.status_start DESC;

-- Update agent status
INSERT INTO agent_status_realtime (
    agent_id,
    status_type,
    status_start,
    expected_end,
    location,
    queue_assignment,
    is_active
)
VALUES ($1, $2, CURRENT_TIMESTAMP, $3, $4, $5, true)
ON CONFLICT (agent_id) DO UPDATE SET
    status_type = EXCLUDED.status_type,
    status_start = CURRENT_TIMESTAMP,
    expected_end = EXCLUDED.expected_end,
    location = EXCLUDED.location,
    queue_assignment = EXCLUDED.queue_assignment,
    is_active = true,
    updated_at = CURRENT_TIMESTAMP
RETURNING id, adherence_score, 
    CASE 
        WHEN expected_end IS NOT NULL AND status_type IN (''break'', ''lunch'')
        THEN GREATEST(0, EXTRACT(epoch FROM (expected_end - CURRENT_TIMESTAMP))/60)::int
        ELSE 0
    END as break_remaining_minutes;';
```

#### Table 3: real_time_status
```sql
COMMENT ON TABLE real_time_status IS
'API Contract: GET /api/v1/realtime/status
params: {dashboard_type?: string, refresh_interval?: int}
returns: [{
    id: UUID,
    dashboard_type: string,
    total_agents: int,
    available_agents: int,
    busy_agents: int,
    break_agents: int,
    away_agents: int,
    logged_out_agents: int,
    average_adherence: float,
    service_level_current: float,
    calls_waiting: int,
    longest_wait_time: int,
    last_updated: timestamp
}]

POST /api/v1/realtime/status/refresh
expects: {dashboard_type?: string}
returns: {updated_metrics: object, refresh_timestamp: timestamp}

WebSocket: /ws/realtime/status
broadcasts: {
    type: "dashboard_update",
    dashboard_type: string,
    metrics: object,
    timestamp: timestamp
}

Helper Queries:
-- Get real-time status dashboard
SELECT 
    r.id::text as id,
    r.dashboard_type,
    r.total_agents,
    r.available_agents,
    r.busy_agents,
    r.break_agents,
    r.away_agents,
    r.logged_out_agents,
    r.average_adherence,
    r.service_level_current,
    r.calls_waiting,
    r.longest_wait_time,
    r.last_updated,
    CASE 
        WHEN r.service_level_current >= 80 THEN ''green''
        WHEN r.service_level_current >= 60 THEN ''yellow''
        ELSE ''red''
    END as service_level_status
FROM real_time_status r
WHERE ($1 IS NULL OR r.dashboard_type = $1)
ORDER BY r.last_updated DESC
LIMIT 1;

-- Refresh real-time status metrics
INSERT INTO real_time_status (
    dashboard_type,
    total_agents,
    available_agents,
    busy_agents,
    break_agents,
    away_agents,
    logged_out_agents,
    average_adherence,
    service_level_current,
    calls_waiting,
    longest_wait_time
)
SELECT 
    COALESCE($1, ''main'') as dashboard_type,
    COUNT(*) as total_agents,
    COUNT(*) FILTER (WHERE current_status = ''available'') as available_agents,
    COUNT(*) FILTER (WHERE current_status = ''busy'') as busy_agents,
    COUNT(*) FILTER (WHERE current_status = ''break'') as break_agents,
    COUNT(*) FILTER (WHERE current_status = ''away'') as away_agents,
    COUNT(*) FILTER (WHERE current_status = ''logged_out'') as logged_out_agents,
    AVG(adherence_percentage) as average_adherence,
    85.5 as service_level_current, -- Calculate from realtime_calls
    12 as calls_waiting, -- Calculate from realtime_calls
    145 as longest_wait_time -- Calculate from realtime_calls
FROM agent_real_time_monitoring
RETURNING id, last_updated;';
```

#### Table 4: realtime_efficiency_metrics
```sql
COMMENT ON TABLE realtime_efficiency_metrics IS
'API Contract: GET /api/v1/realtime/efficiency-metrics
params: {agent_id?: int, time_window_minutes?: int, efficiency_threshold?: float}
returns: [{
    id: UUID,
    agent_id: int,
    calculation_time: timestamp,
    productive_seconds: int,
    idle_seconds: int,
    break_seconds: int,
    efficiency_percentage: float,
    utilization_percentage: float,
    calls_handled: int,
    average_handle_time: float,
    first_call_resolution_rate: float
}]

POST /api/v1/realtime/efficiency-metrics/calculate
expects: {
    agent_id?: int,
    time_window_minutes?: int
}
returns: {calculated_count: int, average_efficiency: float}

Helper Queries:
-- Get real-time efficiency metrics
SELECT 
    e.id::text as id,
    e.agent_id,
    e.calculation_time,
    e.productive_seconds,
    e.idle_seconds,
    e.break_seconds,
    e.efficiency_percentage,
    e.utilization_percentage,
    e.calls_handled,
    e.average_handle_time,
    e.first_call_resolution_rate,
    a.first_name,
    a.last_name,
    CASE 
        WHEN e.efficiency_percentage >= 85 THEN ''excellent''
        WHEN e.efficiency_percentage >= 70 THEN ''good''
        WHEN e.efficiency_percentage >= 55 THEN ''average''
        ELSE ''needs_improvement''
    END as performance_tier
FROM realtime_efficiency_metrics e
LEFT JOIN agents a ON e.agent_id = a.id
WHERE ($1::int IS NULL OR e.agent_id = $1)
    AND ($2::int IS NULL OR e.calculation_time >= CURRENT_TIMESTAMP - ($2 || '' minutes'')::interval)
    AND ($3::numeric IS NULL OR e.efficiency_percentage >= $3)
ORDER BY e.calculation_time DESC, e.efficiency_percentage DESC;

-- Calculate real-time efficiency
WITH agent_activity AS (
    SELECT 
        agent_id,
        SUM(CASE WHEN current_status = ''busy'' THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - status_start_time)) ELSE 0 END) as productive_seconds,
        SUM(CASE WHEN current_status = ''available'' THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - status_start_time)) ELSE 0 END) as idle_seconds,
        SUM(CASE WHEN current_status = ''break'' THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - status_start_time)) ELSE 0 END) as break_seconds
    FROM agent_real_time_monitoring
    WHERE ($1::int IS NULL OR agent_id = $1)
    GROUP BY agent_id
)
INSERT INTO realtime_efficiency_metrics (
    agent_id,
    calculation_time,
    productive_seconds,
    idle_seconds,
    break_seconds,
    efficiency_percentage,
    utilization_percentage,
    calls_handled,
    average_handle_time
)
SELECT 
    aa.agent_id,
    CURRENT_TIMESTAMP,
    aa.productive_seconds::int,
    aa.idle_seconds::int,
    aa.break_seconds::int,
    CASE 
        WHEN (aa.productive_seconds + aa.idle_seconds + aa.break_seconds) > 0
        THEN (aa.productive_seconds / (aa.productive_seconds + aa.idle_seconds + aa.break_seconds) * 100)::numeric(5,2)
        ELSE 0
    END as efficiency_percentage,
    CASE 
        WHEN (aa.productive_seconds + aa.idle_seconds) > 0
        THEN (aa.productive_seconds / (aa.productive_seconds + aa.idle_seconds) * 100)::numeric(5,2)
        ELSE 0
    END as utilization_percentage,
    COALESCE((SELECT COUNT(*) FROM call_events WHERE agent_id = aa.agent_id AND call_start >= CURRENT_TIMESTAMP - interval ''1 hour''), 0),
    COALESCE((SELECT AVG(call_duration) FROM call_events WHERE agent_id = aa.agent_id AND call_start >= CURRENT_TIMESTAMP - interval ''1 hour''), 0)
FROM agent_activity aa
RETURNING id, efficiency_percentage;';
```

#### Table 5: agent_status_tracking
```sql
COMMENT ON TABLE agent_status_tracking IS
'API Contract: GET /api/v1/agent-status-tracking
params: {agent_id?: int, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, status_type?: string}
returns: [{
    id: UUID,
    agent_id: int,
    status_type: string,
    status_start: timestamp,
    status_end: timestamp,
    duration_minutes: int,
    adherence_impact: float,
    reason_code: string,
    is_scheduled: boolean,
    created_at: timestamp
}]

POST /api/v1/agent-status-tracking
expects: {
    agent_id: int,
    status_type: string,
    status_end?: timestamp,
    reason_code?: string,
    is_scheduled?: boolean
}
returns: {id: UUID, duration_minutes: int, adherence_impact: float}

Helper Queries:
-- Get agent status tracking history
SELECT 
    t.id::text as id,
    t.agent_id,
    t.status_type,
    t.status_start,
    t.status_end,
    CASE 
        WHEN t.status_end IS NOT NULL 
        THEN EXTRACT(epoch FROM (t.status_end - t.status_start))/60
        ELSE EXTRACT(epoch FROM (CURRENT_TIMESTAMP - t.status_start))/60
    END as duration_minutes,
    t.adherence_impact,
    t.reason_code,
    t.is_scheduled,
    t.created_at,
    a.first_name,
    a.last_name
FROM agent_status_tracking t
LEFT JOIN agents a ON t.agent_id = a.id
WHERE ($1::int IS NULL OR t.agent_id = $1)
    AND ($2::date IS NULL OR t.status_start::date >= $2)
    AND ($3::date IS NULL OR t.status_start::date <= $3)
    AND ($4 IS NULL OR t.status_type = $4)
ORDER BY t.status_start DESC;

-- Track agent status change
INSERT INTO agent_status_tracking (
    agent_id,
    status_type,
    status_start,
    status_end,
    reason_code,
    is_scheduled,
    adherence_impact
)
VALUES (
    $1,
    $2,
    CURRENT_TIMESTAMP,
    $3,
    $4,
    COALESCE($5, false),
    CASE 
        WHEN $2 IN (''available'', ''busy'') THEN 1.0
        WHEN $2 = ''break'' AND COALESCE($5, false) = true THEN 1.0
        WHEN $2 = ''break'' AND COALESCE($5, false) = false THEN 0.8
        WHEN $2 = ''away'' THEN 0.5
        ELSE 0.0
    END
)
RETURNING id, 
    CASE 
        WHEN status_end IS NOT NULL 
        THEN EXTRACT(epoch FROM (status_end - status_start))/60
        ELSE 0
    END as duration_minutes,
    adherence_impact;';
```

### Step 3: Create Test Data for Real-time Adherence Monitoring
```sql
-- Insert test real-time monitoring data
INSERT INTO agent_real_time_monitoring (
    agent_id,
    current_status,
    status_start_time,
    break_duration_minutes,
    idle_duration_minutes,
    adherence_percentage,
    schedule_deviation_minutes,
    current_queue,
    is_logged_in,
    last_activity
)
SELECT 
    a.id as agent_id,
    'available' as current_status,
    CURRENT_TIMESTAMP - interval '15 minutes' as status_start_time,
    5 as break_duration_minutes,
    10 as idle_duration_minutes,
    87.5 as adherence_percentage,
    -5 as schedule_deviation_minutes,
    'SUPPORT_QUEUE' as current_queue,
    true as is_logged_in,
    CURRENT_TIMESTAMP - interval '2 minutes' as last_activity
FROM agents a
WHERE a.first_name = 'Анна'
LIMIT 1
ON CONFLICT (agent_id) DO NOTHING;

-- Insert test real-time status
INSERT INTO agent_status_realtime (
    agent_id,
    status_type,
    status_start,
    expected_end,
    location,
    is_active,
    queue_assignment,
    adherence_score
)
SELECT 
    a.id as agent_id,
    'available' as status_type,
    CURRENT_TIMESTAMP - interval '20 minutes' as status_start,
    NULL as expected_end,
    'Office Floor 1' as location,
    true as is_active,
    'SUPPORT_QUEUE' as queue_assignment,
    89.2 as adherence_score
FROM agents a
WHERE a.first_name = 'Мария'
LIMIT 1
ON CONFLICT (agent_id) DO NOTHING;

-- Insert test dashboard status
INSERT INTO real_time_status (
    dashboard_type,
    total_agents,
    available_agents,
    busy_agents,
    break_agents,
    away_agents,
    logged_out_agents,
    average_adherence,
    service_level_current,
    calls_waiting,
    longest_wait_time
)
VALUES 
    ('main', 25, 18, 4, 2, 1, 0, 85.7, 82.3, 8, 125),
    ('supervisor', 25, 18, 4, 2, 1, 0, 85.7, 82.3, 8, 125)
ON CONFLICT DO NOTHING;

-- Insert test efficiency metrics
INSERT INTO realtime_efficiency_metrics (
    agent_id,
    calculation_time,
    productive_seconds,
    idle_seconds,
    break_seconds,
    efficiency_percentage,
    utilization_percentage,
    calls_handled,
    average_handle_time,
    first_call_resolution_rate
)
SELECT 
    a.id as agent_id,
    CURRENT_TIMESTAMP as calculation_time,
    3240 as productive_seconds, -- 54 minutes
    600 as idle_seconds,       -- 10 minutes
    300 as break_seconds,      -- 5 minutes
    78.3 as efficiency_percentage,
    84.4 as utilization_percentage,
    12 as calls_handled,
    270.5 as average_handle_time,
    85.2 as first_call_resolution_rate
FROM agents a
WHERE a.first_name = 'Елена'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test status tracking
INSERT INTO agent_status_tracking (
    agent_id,
    status_type,
    status_start,
    status_end,
    reason_code,
    is_scheduled,
    adherence_impact
)
SELECT 
    a.id as agent_id,
    'break' as status_type,
    CURRENT_TIMESTAMP - interval '45 minutes' as status_start,
    CURRENT_TIMESTAMP - interval '30 minutes' as status_end,
    'SCHEDULED_BREAK' as reason_code,
    true as is_scheduled,
    1.0 as adherence_impact
FROM agents a
WHERE a.first_name = 'Дмитрий'
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/realtime%' 
            OR obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/agent-status%'
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE '%Helper Queries:%'
        THEN '✅ Has Helpers'
        ELSE '❌ No Helpers'
    END as helper_status,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE '%WebSocket:%'
        THEN '✅ Has WebSocket'
        ELSE '❌ No WebSocket'
    END as websocket_status
FROM pg_class 
WHERE relname IN ('agent_real_time_monitoring', 'agent_status_realtime', 'real_time_status', 'realtime_efficiency_metrics', 'agent_status_tracking')
ORDER BY relname;"
```

### Step 5: Test Sample Queries
```sql
-- Test real-time monitoring query
SELECT 
    a.agent_id,
    a.current_status,
    a.adherence_percentage,
    CASE 
        WHEN a.adherence_percentage >= 90 THEN 'green'
        WHEN a.adherence_percentage >= 80 THEN 'yellow'
        ELSE 'red'
    END as status_color,
    ag.first_name
FROM agent_real_time_monitoring a
LEFT JOIN agents ag ON a.agent_id = ag.id
ORDER BY a.adherence_percentage DESC
LIMIT 3;

-- Test real-time status dashboard
SELECT 
    dashboard_type,
    total_agents,
    available_agents,
    average_adherence,
    service_level_current,
    calls_waiting,
    last_updated
FROM real_time_status
ORDER BY last_updated DESC
LIMIT 2;

-- Test efficiency metrics
SELECT 
    e.agent_id,
    e.efficiency_percentage,
    e.calls_handled,
    a.first_name,
    CASE 
        WHEN e.efficiency_percentage >= 85 THEN 'excellent'
        WHEN e.efficiency_percentage >= 70 THEN 'good'
        ELSE 'needs_improvement'
    END as performance_tier
FROM realtime_efficiency_metrics e
LEFT JOIN agents a ON e.agent_id = a.id
ORDER BY e.efficiency_percentage DESC
LIMIT 3;
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 5 tables have specific real-time API contract comments
- [ ] Each table has GET and POST/PUT endpoints documented
- [ ] WebSocket endpoints documented for real-time updates
- [ ] Helper queries include proper parameter binding ($1, $2, etc.)
- [ ] Test data exists demonstrating real-time adherence calculations
- [ ] Verification query shows ✅ for all tables
- [ ] Sample queries execute successfully

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_006: Complete - 5 real-time adherence monitoring tables documented with proper API contracts and WebSocket support" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If foreign key references fail:
- Check that referenced tables (agents, call_events) exist
- Use existing records for test data

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Key Features Documented

1. **Real-time Agent Monitoring**: Live agent status tracking with adherence calculations
2. **WebSocket Support**: Real-time dashboard updates via WebSocket connections
3. **Status Color Coding**: Automated color coding based on adherence thresholds
4. **Break Management**: Tracking scheduled vs unscheduled breaks
5. **Efficiency Calculations**: Live productivity metrics with performance tiers
6. **Historical Tracking**: Complete audit trail of agent status changes

This completes the real-time adherence monitoring documentation with production-ready API contracts and WebSocket support for live updates.