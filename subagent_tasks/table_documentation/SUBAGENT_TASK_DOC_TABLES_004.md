# 📋 SUBAGENT TASK: Table Documentation Batch 004 - Forecast Accuracy Metrics

## 🎯 Task Information
- **Task ID**: DOC_TABLES_004
- **Priority**: High
- **Estimated Time**: 25 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 4 forecast accuracy metrics tables with proper API contracts:

1. **forecast_accuracy_analysis** - Core forecast accuracy analysis with MAPE/WAPE/MFA/WFA metrics
2. **forecast_accuracy_tracking** - Individual prediction tracking and error calculation
3. **adherence_metrics** - Employee schedule adherence tracking
4. **efficiency_metrics** - Agent productivity and utilization metrics

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/forecast-accuracy%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('forecast_accuracy_analysis', 'forecast_accuracy_tracking', 'adherence_metrics', 'efficiency_metrics')
ORDER BY relname;"
```

### Step 2: Apply Proper API Contracts

Execute these commands in order:

#### Table 1: forecast_accuracy_analysis
```sql
COMMENT ON TABLE forecast_accuracy_analysis IS 
'API Contract: GET /api/v1/forecast-accuracy/analysis
params: {period_start?: YYYY-MM-DD, period_end?: YYYY-MM-DD, granularity?: string}
returns: [{
    id: UUID, 
    analysis_period_start: date, 
    analysis_period_end: date,
    granularity_level: string,
    mape: float,
    wape: float, 
    mfa: float,
    wfa: float,
    bias: float,
    tracking_signal: float,
    targets_met: {
        mape: boolean, 
        wape: boolean, 
        mfa: boolean, 
        wfa: boolean, 
        bias: boolean, 
        tracking_signal: boolean
    },
    drill_down_data: object
}]

POST /api/v1/forecast-accuracy/calculate
expects: {period_start: date, period_end: date, granularity: string}
returns: {analysis_id: UUID, status: string, metrics: object}

Helper Queries:
-- Get forecast accuracy analysis
SELECT 
    id::text as id,
    analysis_period_start::text as period_start,
    analysis_period_end::text as period_end,
    granularity_level,
    mape,
    wape,
    mfa,
    wfa,
    bias,
    tracking_signal,
    json_build_object(
        ''mape'', mape_target_met,
        ''wape'', wape_target_met,
        ''mfa'', mfa_target_met,
        ''wfa'', wfa_target_met,
        ''bias'', bias_target_met,
        ''tracking_signal'', tracking_signal_target_met
    ) as targets_met,
    drill_down_data,
    calculated_at
FROM forecast_accuracy_analysis
WHERE ($1::date IS NULL OR analysis_period_start >= $1)
    AND ($2::date IS NULL OR analysis_period_end <= $2)
    AND ($3 IS NULL OR granularity_level = $3)
ORDER BY analysis_period_start DESC;

-- Calculate accuracy metrics
INSERT INTO forecast_accuracy_analysis (
    analysis_period_start, 
    analysis_period_end, 
    granularity_level,
    mape, 
    wape, 
    mfa, 
    wfa, 
    bias, 
    tracking_signal,
    drill_down_data
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING id, mape_target_met, wape_target_met, mfa_target_met, wfa_target_met;';
```

#### Table 2: forecast_accuracy_tracking
```sql
COMMENT ON TABLE forecast_accuracy_tracking IS
'API Contract: GET /api/v1/forecast-accuracy/tracking
params: {model_id?: UUID, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, accuracy_threshold?: float}
returns: [{
    id: UUID,
    model_id: UUID,
    prediction_date: date,
    actual_value: float,
    predicted_value: float,
    accuracy_percentage: float,
    error_margin: float,
    calculated_at: timestamp
}]

POST /api/v1/forecast-accuracy/track
expects: {model_id: UUID, prediction_date: date, actual_value: float, predicted_value: float}
returns: {id: UUID, accuracy_percentage: float, error_margin: float}

Helper Queries:
-- Get forecast accuracy tracking
SELECT 
    t.id::text as id,
    t.model_id::text as model_id,
    t.prediction_date::text as prediction_date,
    t.actual_value,
    t.predicted_value,
    t.accuracy_percentage,
    t.error_margin,
    t.calculated_at,
    m.algorithm_type,
    m.training_date
FROM forecast_accuracy_tracking t
LEFT JOIN forecast_models m ON t.model_id = m.id
WHERE ($1::uuid IS NULL OR t.model_id = $1)
    AND ($2::date IS NULL OR t.prediction_date >= $2)
    AND ($3::date IS NULL OR t.prediction_date <= $3)
    AND ($4::numeric IS NULL OR t.accuracy_percentage >= $4)
ORDER BY t.prediction_date DESC;

-- Track prediction accuracy
INSERT INTO forecast_accuracy_tracking (
    model_id, 
    prediction_date, 
    actual_value, 
    predicted_value,
    accuracy_percentage,
    error_margin
)
VALUES (
    $1, 
    $2, 
    $3, 
    $4,
    CASE WHEN $4 > 0 THEN 100 - ABS(($3 - $4) / $4 * 100) ELSE NULL END,
    ABS($3 - $4)
)
RETURNING id, accuracy_percentage, error_margin;';
```

#### Table 3: adherence_metrics
```sql
COMMENT ON TABLE adherence_metrics IS
'API Contract: GET /api/v1/adherence-metrics
params: {employee_tab_n?: string, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, color?: string}
returns: [{
    id: UUID,
    employee_tab_n: string,
    report_date: date,
    individual_adherence_pct: float,
    planned_schedule_time: string,
    actual_worked_time: string,
    productive_time: string,
    auxiliary_time: string,
    adherence_color: string,
    calculated_at: timestamp
}]

POST /api/v1/adherence-metrics
expects: {
    employee_tab_n: string,
    report_date: date,
    planned_schedule_time: string,
    actual_worked_time: string,
    productive_time?: string,
    auxiliary_time?: string
}
returns: {id: UUID, individual_adherence_pct: float, adherence_color: string}

Helper Queries:
-- Get adherence metrics
SELECT 
    a.id::text as id,
    a.employee_tab_n,
    a.report_date::text as report_date,
    a.individual_adherence_pct,
    EXTRACT(epoch FROM a.planned_schedule_time)::int as planned_seconds,
    EXTRACT(epoch FROM a.actual_worked_time)::int as actual_seconds,
    EXTRACT(epoch FROM a.productive_time)::int as productive_seconds,
    EXTRACT(epoch FROM a.auxiliary_time)::int as auxiliary_seconds,
    a.adherence_color,
    a.calculated_at,
    z.full_name,
    z.position
FROM adherence_metrics a
LEFT JOIN zup_agent_data z ON a.employee_tab_n = z.tab_n
WHERE ($1 IS NULL OR a.employee_tab_n = $1)
    AND ($2::date IS NULL OR a.report_date >= $2)
    AND ($3::date IS NULL OR a.report_date <= $3)
    AND ($4 IS NULL OR a.adherence_color = $4)
ORDER BY a.report_date DESC, a.individual_adherence_pct DESC;

-- Calculate adherence percentage
INSERT INTO adherence_metrics (
    employee_tab_n,
    report_date,
    individual_adherence_pct,
    planned_schedule_time,
    actual_worked_time,
    productive_time,
    auxiliary_time
)
VALUES (
    $1,
    $2,
    CASE 
        WHEN EXTRACT(epoch FROM $3::interval) > 0 
        THEN (EXTRACT(epoch FROM $4::interval) / EXTRACT(epoch FROM $3::interval) * 100)::numeric(5,2)
        ELSE 0
    END,
    $3::interval,
    $4::interval,
    $5::interval,
    $6::interval
)
ON CONFLICT (employee_tab_n, report_date) 
DO UPDATE SET
    individual_adherence_pct = EXCLUDED.individual_adherence_pct,
    actual_worked_time = EXCLUDED.actual_worked_time,
    productive_time = EXCLUDED.productive_time,
    auxiliary_time = EXCLUDED.auxiliary_time,
    calculated_at = CURRENT_TIMESTAMP
RETURNING id, individual_adherence_pct, adherence_color;';
```

#### Table 4: efficiency_metrics
```sql
COMMENT ON TABLE efficiency_metrics IS
'API Contract: GET /api/v1/efficiency-metrics
params: {agent_id?: int, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, min_efficiency?: float}
returns: [{
    id: UUID,
    agent_id: int,
    metric_date: date,
    productive_time_minutes: int,
    idle_time_minutes: int,
    break_time_minutes: int,
    efficiency_score: float,
    utilization_rate: float,
    created_at: timestamp
}]

POST /api/v1/efficiency-metrics
expects: {
    agent_id: int,
    metric_date: date,
    productive_time_minutes: int,
    idle_time_minutes?: int,
    break_time_minutes?: int
}
returns: {id: UUID, efficiency_score: float, utilization_rate: float}

Helper Queries:
-- Get efficiency metrics with agent details
SELECT 
    e.id::text as id,
    e.agent_id,
    e.metric_date::text as metric_date,
    e.productive_time_minutes,
    e.idle_time_minutes,
    e.break_time_minutes,
    e.efficiency_score,
    e.utilization_rate,
    e.created_at,
    a.first_name,
    a.last_name,
    a.position
FROM efficiency_metrics e
LEFT JOIN agents a ON e.agent_id = a.id
WHERE ($1::int IS NULL OR e.agent_id = $1)
    AND ($2::date IS NULL OR e.metric_date >= $2)
    AND ($3::date IS NULL OR e.metric_date <= $3)
    AND ($4::numeric IS NULL OR e.efficiency_score >= $4)
ORDER BY e.metric_date DESC, e.efficiency_score DESC;

-- Calculate and insert efficiency metrics
INSERT INTO efficiency_metrics (
    agent_id,
    metric_date,
    productive_time_minutes,
    idle_time_minutes,
    break_time_minutes,
    efficiency_score,
    utilization_rate
)
VALUES (
    $1,
    $2,
    $3,
    COALESCE($4, 0),
    COALESCE($5, 0),
    CASE 
        WHEN ($3 + COALESCE($4, 0) + COALESCE($5, 0)) > 0 
        THEN ($3::numeric / ($3 + COALESCE($4, 0) + COALESCE($5, 0)) * 100)::numeric(5,2)
        ELSE 0
    END,
    CASE 
        WHEN ($3 + COALESCE($4, 0)) > 0 
        THEN ($3::numeric / ($3 + COALESCE($4, 0)) * 100)::numeric(5,2)
        ELSE 0
    END
)
RETURNING id, efficiency_score, utilization_rate;';
```

### Step 3: Create Test Data Demonstrating Forecast Accuracy Calculations
```sql
-- Insert test forecast accuracy analysis
INSERT INTO forecast_accuracy_analysis (
    analysis_period_start,
    analysis_period_end,
    granularity_level,
    mape,
    wape,
    mfa,
    wfa,
    bias,
    tracking_signal,
    drill_down_data
)
VALUES 
    ('2024-01-01', '2024-01-31', 'Daily', 12.5, 8.3, 87.2, 91.7, -2.1, 1.8, 
     '{"queues": [{"id": "Q001", "mape": 10.2}, {"id": "Q002", "mape": 14.8}]}'::jsonb),
    ('2024-02-01', '2024-02-29', 'Daily', 9.8, 6.5, 90.1, 93.5, 1.3, -0.9,
     '{"queues": [{"id": "Q001", "mape": 8.1}, {"id": "Q002", "mape": 11.5}]}'::jsonb)
ON CONFLICT DO NOTHING;

-- Insert test forecast accuracy tracking
INSERT INTO forecast_accuracy_tracking (
    model_id,
    prediction_date,
    actual_value,
    predicted_value,
    accuracy_percentage,
    error_margin
)
SELECT 
    fm.id as model_id,
    '2024-01-15'::date as prediction_date,
    1250.00 as actual_value,
    1180.00 as predicted_value,
    94.4 as accuracy_percentage,
    70.00 as error_margin
FROM forecast_models fm
WHERE fm.algorithm_type = 'erlang_c'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test adherence metrics
INSERT INTO adherence_metrics (
    employee_tab_n,
    report_date,
    individual_adherence_pct,
    planned_schedule_time,
    actual_worked_time,
    productive_time,
    auxiliary_time
)
SELECT 
    zad.tab_n,
    CURRENT_DATE - 1 as report_date,
    85.5 as individual_adherence_pct,
    '8 hours'::interval as planned_schedule_time,
    '7 hours 50 minutes'::interval as actual_worked_time,
    '6 hours 30 minutes'::interval as productive_time,
    '1 hour 20 minutes'::interval as auxiliary_time
FROM zup_agent_data zad
WHERE zad.full_name LIKE '%Анна%'
LIMIT 1
ON CONFLICT (employee_tab_n, report_date) DO NOTHING;

-- Insert test efficiency metrics
INSERT INTO efficiency_metrics (
    agent_id,
    metric_date,
    productive_time_minutes,
    idle_time_minutes,
    break_time_minutes,
    efficiency_score,
    utilization_rate
)
SELECT 
    a.id as agent_id,
    CURRENT_DATE - 1 as metric_date,
    420 as productive_time_minutes,
    45 as idle_time_minutes,
    15 as break_time_minutes,
    87.5 as efficiency_score,
    90.3 as utilization_rate
FROM agents a
WHERE a.first_name = 'Анна'
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/forecast-accuracy%' 
            OR obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/adherence-metrics%'
            OR obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/efficiency-metrics%'
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
WHERE relname IN ('forecast_accuracy_analysis', 'forecast_accuracy_tracking', 'adherence_metrics', 'efficiency_metrics')
ORDER BY relname;"
```

### Step 5: Test Sample Queries
```sql
-- Test forecast accuracy analysis query
SELECT 
    id::text as id,
    analysis_period_start::text as period_start,
    granularity_level,
    mape,
    wape,
    json_build_object(
        'mape', mape_target_met,
        'wape', wape_target_met,
        'mfa', mfa_target_met,
        'wfa', wfa_target_met
    ) as targets_met
FROM forecast_accuracy_analysis
ORDER BY analysis_period_start DESC
LIMIT 3;

-- Test adherence metrics with employee data
SELECT 
    a.employee_tab_n,
    a.individual_adherence_pct,
    a.adherence_color,
    z.full_name
FROM adherence_metrics a
LEFT JOIN zup_agent_data z ON a.employee_tab_n = z.tab_n
ORDER BY a.report_date DESC
LIMIT 3;
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 4 tables have specific API contract comments (not generic)
- [ ] Each table has GET and POST endpoints documented
- [ ] Helper queries include proper parameter binding ($1, $2, etc.)
- [ ] Test data exists demonstrating forecast accuracy calculations
- [ ] Verification query shows ✅ for all tables
- [ ] Sample queries execute successfully

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_004: Complete - 4 forecast accuracy metrics tables documented with proper API contracts" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If foreign key references fail:
- Check that referenced tables (forecast_models, agents, zup_agent_data) exist
- Use existing records for test data

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Key Features Documented

1. **MAPE/WAPE/MFA/WFA Metrics**: Industry-standard forecast accuracy measurements
2. **Target Achievement**: Automated boolean calculations for accuracy targets
3. **Drill-down Data**: JSONB support for detailed breakdowns
4. **Real-time Tracking**: Individual prediction vs actual value tracking
5. **Schedule Adherence**: Employee schedule compliance monitoring
6. **Efficiency Scoring**: Productivity and utilization calculations

This completes the forecast accuracy metrics documentation with production-ready API contracts.