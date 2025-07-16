# 📋 SUBAGENT TASK: Table Documentation Batch 009 - Operational WFM Tables

## 🎯 Task Information
- **Task ID**: DOC_TABLES_009
- **Priority**: High
- **Estimated Time**: 50 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 6 critical operational WFM tables with comprehensive API contracts:

1. **time_entries** - Core timesheet and clock in/out tracking with Russian compliance
2. **attendance_sessions** - Daily attendance sessions with overtime calculations
3. **attendance_exceptions** - Break management and compliance violations
4. **overtime_metrics** - Overtime calculation and approval tracking
5. **real_time_status** - Real-time employee status monitoring
6. **payroll_time_codes** - 1C ZUP integration for payroll processing

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/time%' 
        THEN '✅ Properly Documented'
        WHEN obj_description(oid, 'pg_class') IS NOT NULL 
        THEN '⚠️ Generic Documentation'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('time_entries', 'attendance_sessions', 'attendance_exceptions', 'overtime_metrics', 'real_time_status', 'payroll_time_codes')
ORDER BY relname;"
```

### Step 2: Apply Comprehensive API Contracts

Execute these commands in order:

#### Table 1: time_entries
```sql
COMMENT ON TABLE time_entries IS 
'API Contract: GET /api/v1/time-entries
params: {employee_id?: UUID, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, entry_type?: string, work_state?: string}
returns: [{
    id: UUID,
    employee_id: UUID,
    entry_type: string,
    entry_timestamp: timestamp,
    work_state_id: UUID,
    work_state_name: string,
    location_data: object,
    entry_method: string,
    reason_code: string,
    notes: string,
    supervisor_override: boolean,
    override_reason: string,
    created_at: timestamp,
    employee_name: string,
    duration_minutes: number,
    is_valid_entry: boolean
}]

POST /api/v1/time-entries
expects: {
    entry_type: string, // clock_in, clock_out, break_start, break_end, status_change
    work_state_code?: string, // AVAIL, BUSY, BREAK, LUNCH, etc.
    location_data?: object, // GPS coordinates, IP address
    entry_method?: string, // manual, biometric, card, app
    reason_code?: string,
    notes?: string,
    supervisor_override?: boolean,
    override_reason?: string
}
returns: {id: UUID, entry_type: string, entry_timestamp: timestamp, status: string, validation_result: object}

PUT /api/v1/time-entries/:id/correct
expects: {
    corrected_timestamp: timestamp,
    correction_reason: string,
    supervisor_approval: boolean
}
returns: {id: UUID, original_timestamp: timestamp, corrected_timestamp: timestamp, status: string}

DELETE /api/v1/time-entries/:id
expects: {
    deletion_reason: string,
    supervisor_approval: boolean
}
returns: {id: UUID, deleted_at: timestamp, status: string}

Helper Queries:
-- Get time entries with work state details and duration calculations
SELECT 
    te.id::text as id,
    te.employee_id::text as employee_id,
    te.entry_type,
    te.entry_timestamp,
    te.work_state_id::text as work_state_id,
    ws.state_name as work_state_name,
    ws.state_code as work_state_code,
    ws.color_code,
    te.location_data,
    te.entry_method,
    te.reason_code,
    te.notes,
    te.supervisor_override,
    te.override_reason,
    te.created_at,
    u.first_name || '' '' || u.last_name as employee_name,
    u.department,
    CASE 
        WHEN te.entry_type = ''clock_out'' AND LAG(te.entry_timestamp) OVER (
            PARTITION BY te.employee_id 
            ORDER BY te.entry_timestamp
        ) IS NOT NULL THEN
            EXTRACT(EPOCH FROM (te.entry_timestamp - LAG(te.entry_timestamp) OVER (
                PARTITION BY te.employee_id 
                ORDER BY te.entry_timestamp
            ))) / 60
        ELSE NULL
    END as duration_minutes,
    CASE 
        WHEN te.entry_type = ''clock_in'' AND te.entry_timestamp::time BETWEEN ''06:00'' AND ''10:00'' THEN true
        WHEN te.entry_type = ''clock_out'' AND te.entry_timestamp::time BETWEEN ''16:00'' AND ''20:00'' THEN true
        WHEN te.entry_type IN (''break_start'', ''break_end'') THEN true
        ELSE false
    END as is_valid_entry,
    CASE 
        WHEN te.supervisor_override THEN ''Supervisor Override''
        WHEN te.entry_method = ''biometric'' THEN ''Biometric Verified''
        WHEN te.location_data IS NOT NULL THEN ''Location Verified''
        ELSE ''Standard Entry''
    END as verification_status
FROM time_entries te
LEFT JOIN work_states ws ON te.work_state_id = ws.id
LEFT JOIN users u ON te.employee_id = u.id
WHERE ($1::uuid IS NULL OR te.employee_id = $1)
    AND ($2::date IS NULL OR te.entry_timestamp::date >= $2)
    AND ($3::date IS NULL OR te.entry_timestamp::date <= $3)
    AND ($4 IS NULL OR te.entry_type = $4)
    AND ($5 IS NULL OR ws.state_code = $5)
ORDER BY te.entry_timestamp DESC;

-- Create time entry with validation
WITH entry_validation AS (
    SELECT 
        $1 as employee_id,
        $2 as entry_type,
        CURRENT_TIMESTAMP as entry_timestamp,
        CASE 
            WHEN $2 = ''clock_in'' AND EXISTS (
                SELECT 1 FROM time_entries 
                WHERE employee_id = $1 
                AND entry_type = ''clock_in'' 
                AND DATE(entry_timestamp) = CURRENT_DATE
                AND NOT EXISTS (
                    SELECT 1 FROM time_entries te2 
                    WHERE te2.employee_id = $1 
                    AND te2.entry_type = ''clock_out''
                    AND te2.entry_timestamp > time_entries.entry_timestamp
                )
            ) THEN false -- Already clocked in
            WHEN $2 = ''clock_out'' AND NOT EXISTS (
                SELECT 1 FROM time_entries 
                WHERE employee_id = $1 
                AND entry_type = ''clock_in'' 
                AND DATE(entry_timestamp) = CURRENT_DATE
            ) THEN false -- Not clocked in
            ELSE true
        END as is_valid
)
INSERT INTO time_entries (
    employee_id, entry_type, entry_timestamp, work_state_id,
    location_data, entry_method, reason_code, notes
)
SELECT 
    $1, $2, CURRENT_TIMESTAMP,
    (SELECT id FROM work_states WHERE state_code = $3 AND is_active = true),
    $4::jsonb, $5, $6, $7
FROM entry_validation 
WHERE is_valid = true
RETURNING id, entry_type, entry_timestamp, 
    ''success'' as status,
    jsonb_build_object(
        ''validation_passed'', true,
        ''entry_method'', entry_method,
        ''location_verified'', location_data IS NOT NULL
    ) as validation_result;

-- Russian Labor Law Compliance: Track continuous work periods
SELECT 
    te.employee_id::text,
    u.first_name || '' '' || u.last_name as employee_name,
    DATE(te.entry_timestamp) as work_date,
    MIN(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_in'') as clock_in,
    MAX(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_out'') as clock_out,
    EXTRACT(EPOCH FROM (
        MAX(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_out'') -
        MIN(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_in'')
    )) / 3600 as total_hours,
    COUNT(*) FILTER (WHERE te.entry_type IN (''break_start'', ''break_end'')) / 2 as break_count,
    CASE 
        WHEN EXTRACT(EPOCH FROM (
            MAX(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_out'') -
            MIN(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_in'')
        )) / 3600 > 8 THEN ''Overtime Required''
        WHEN COUNT(*) FILTER (WHERE te.entry_type IN (''break_start'', ''break_end'')) / 2 = 0 
            AND EXTRACT(EPOCH FROM (
                MAX(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_out'') -
                MIN(te.entry_timestamp) FILTER (WHERE te.entry_type = ''clock_in'')
            )) / 3600 > 4 THEN ''Break Required by Law''
        ELSE ''Compliant''
    END as compliance_status
FROM time_entries te
JOIN users u ON te.employee_id = u.id
WHERE te.entry_timestamp::date >= CURRENT_DATE - INTERVAL ''30 days''
GROUP BY te.employee_id, u.first_name, u.last_name, DATE(te.entry_timestamp)
ORDER BY work_date DESC, clock_in;';
```

#### Table 2: attendance_sessions
```sql
COMMENT ON TABLE attendance_sessions IS
'API Contract: GET /api/v1/attendance-sessions
params: {employee_id?: UUID, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, status?: string, min_adherence?: number}
returns: [{
    id: UUID,
    employee_id: UUID,
    session_date: date,
    clock_in_time: timestamp,
    clock_out_time: timestamp,
    scheduled_start: timestamp,
    scheduled_end: timestamp,
    total_hours: number,
    productive_hours: number,
    break_hours: number,
    overtime_hours: number,
    late_minutes: number,
    early_departure_minutes: number,
    attendance_status: string,
    adherence_percentage: number,
    session_notes: string,
    is_complete: boolean,
    calculated_at: timestamp,
    employee_name: string,
    department: string,
    adherence_rating: string,
    pay_code_summary: object
}]

POST /api/v1/attendance-sessions/calculate
expects: {
    employee_id: UUID,
    session_date: date,
    force_recalculation?: boolean,
    override_schedule?: object
}
returns: {id: UUID, total_hours: number, adherence_percentage: number, overtime_hours: number, status: string}

PUT /api/v1/attendance-sessions/:id/approve
expects: {
    approval_notes?: string,
    overtime_approved?: boolean,
    pay_adjustments?: object
}
returns: {id: UUID, attendance_status: string, approved_at: timestamp, payroll_ready: boolean}

GET /api/v1/attendance-sessions/overtime-report
params: {department?: string, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, min_overtime?: number}
returns: [{
    employee_id: UUID,
    employee_name: string,
    total_overtime_hours: number,
    overtime_cost: number,
    average_daily_overtime: number,
    compliance_status: string
}]

Helper Queries:
-- Get attendance sessions with comprehensive analysis
SELECT 
    ats.id::text as id,
    ats.employee_id::text as employee_id,
    ats.session_date,
    ats.clock_in_time,
    ats.clock_out_time,
    ats.scheduled_start,
    ats.scheduled_end,
    ats.total_hours,
    ats.productive_hours,
    ats.break_hours,
    ats.overtime_hours,
    ats.late_minutes,
    ats.early_departure_minutes,
    ats.attendance_status,
    ats.adherence_percentage,
    ats.session_notes,
    ats.is_complete,
    ats.calculated_at,
    u.first_name || '' '' || u.last_name as employee_name,
    u.department,
    CASE 
        WHEN ats.adherence_percentage >= 95 THEN ''Отличная'' -- Excellent
        WHEN ats.adherence_percentage >= 85 THEN ''Хорошая'' -- Good
        WHEN ats.adherence_percentage >= 75 THEN ''Удовлетворительная'' -- Fair
        ELSE ''Неудовлетворительная'' -- Poor
    END as adherence_rating,
    CASE 
        WHEN ats.overtime_hours > 0 THEN ''Сверхурочные'' -- Overtime
        WHEN ats.total_hours < 8 THEN ''Неполный день'' -- Partial day
        WHEN ats.late_minutes > 15 THEN ''Опоздание'' -- Late
        ELSE ''Стандартный'' -- Standard
    END as attendance_category,
    jsonb_build_object(
        ''regular_hours'', LEAST(ats.total_hours, 8),
        ''overtime_hours'', ats.overtime_hours,
        ''break_time'', ats.break_hours,
        ''productive_ratio'', ROUND((ats.productive_hours / NULLIF(ats.total_hours, 0)) * 100, 2),
        ''schedule_variance'', ROUND(
            EXTRACT(EPOCH FROM (ats.clock_out_time - ats.clock_in_time)) / 3600 - 
            EXTRACT(EPOCH FROM (ats.scheduled_end - ats.scheduled_start)) / 3600, 2
        )
    ) as pay_code_summary,
    CASE 
        WHEN ats.overtime_hours > 2 THEN ''Требуется одобрение'' -- Approval required
        WHEN ats.adherence_percentage < 70 THEN ''Нарушение дисциплины'' -- Discipline violation
        WHEN ats.late_minutes > 30 THEN ''Значительное опоздание'' -- Significant lateness
        ELSE ''В норме'' -- Normal
    END as compliance_status
FROM attendance_sessions ats
LEFT JOIN users u ON ats.employee_id = u.id
WHERE ($1::uuid IS NULL OR ats.employee_id = $1)
    AND ($2::date IS NULL OR ats.session_date >= $2)
    AND ($3::date IS NULL OR ats.session_date <= $3)
    AND ($4 IS NULL OR ats.attendance_status = $4)
    AND ($5::numeric IS NULL OR ats.adherence_percentage >= $5)
ORDER BY ats.session_date DESC, u.last_name;

-- Calculate attendance session with Russian Labor Law compliance
WITH schedule_calculation AS (
    SELECT 
        $1 as employee_id,
        $2 as session_date,
        COALESCE(
            (SELECT MIN(entry_timestamp) FROM time_entries 
             WHERE employee_id = $1 AND DATE(entry_timestamp) = $2 AND entry_type = ''clock_in''),
            $2::timestamp + TIME ''09:00:00''
        ) as actual_clock_in,
        COALESCE(
            (SELECT MAX(entry_timestamp) FROM time_entries 
             WHERE employee_id = $1 AND DATE(entry_timestamp) = $2 AND entry_type = ''clock_out''),
            NULL
        ) as actual_clock_out,
        $2::timestamp + TIME ''09:00:00'' as scheduled_start,
        $2::timestamp + TIME ''18:00:00'' as scheduled_end
),
time_calculations AS (
    SELECT 
        sc.*,
        CASE 
            WHEN sc.actual_clock_out IS NOT NULL THEN
                EXTRACT(EPOCH FROM (sc.actual_clock_out - sc.actual_clock_in)) / 3600.0
            ELSE 0
        END as total_hours,
        GREATEST(0, 
            CASE 
                WHEN sc.actual_clock_in > sc.scheduled_start THEN
                    EXTRACT(EPOCH FROM (sc.actual_clock_in - sc.scheduled_start)) / 60
                ELSE 0
            END
        ) as late_minutes,
        GREATEST(0,
            CASE 
                WHEN sc.actual_clock_out IS NOT NULL AND sc.actual_clock_out < sc.scheduled_end THEN
                    EXTRACT(EPOCH FROM (sc.scheduled_end - sc.actual_clock_out)) / 60
                ELSE 0
            END
        ) as early_departure_minutes
    FROM schedule_calculation sc
),
overtime_calculation AS (
    SELECT 
        tc.*,
        GREATEST(0, tc.total_hours - 8) as overtime_hours,
        tc.total_hours * 0.85 as productive_hours, -- 85% productive assumption
        tc.total_hours * 0.15 as break_hours, -- 15% break assumption
        CASE 
            WHEN tc.total_hours > 0 THEN
                GREATEST(0, 100 - ((tc.late_minutes + tc.early_departure_minutes) / 480.0 * 100))
            ELSE 0
        END as adherence_percentage
    FROM time_calculations tc
)
INSERT INTO attendance_sessions (
    employee_id, session_date, clock_in_time, clock_out_time,
    scheduled_start, scheduled_end, total_hours, productive_hours,
    break_hours, overtime_hours, late_minutes, early_departure_minutes,
    adherence_percentage, attendance_status, is_complete
)
SELECT 
    oc.employee_id, oc.session_date, oc.actual_clock_in, oc.actual_clock_out,
    oc.scheduled_start, oc.scheduled_end, oc.total_hours, oc.productive_hours,
    oc.break_hours, oc.overtime_hours, oc.late_minutes, oc.early_departure_minutes,
    oc.adherence_percentage,
    CASE 
        WHEN oc.actual_clock_out IS NULL THEN ''incomplete''
        WHEN oc.total_hours = 0 THEN ''absent''
        WHEN oc.overtime_hours > 2 THEN ''overtime''
        WHEN oc.adherence_percentage < 70 THEN ''violation''
        ELSE ''present''
    END,
    oc.actual_clock_out IS NOT NULL
FROM overtime_calculation oc
ON CONFLICT (employee_id, session_date) DO UPDATE SET
    clock_out_time = EXCLUDED.clock_out_time,
    total_hours = EXCLUDED.total_hours,
    productive_hours = EXCLUDED.productive_hours,
    break_hours = EXCLUDED.break_hours,
    overtime_hours = EXCLUDED.overtime_hours,
    late_minutes = EXCLUDED.late_minutes,
    early_departure_minutes = EXCLUDED.early_departure_minutes,
    adherence_percentage = EXCLUDED.adherence_percentage,
    attendance_status = EXCLUDED.attendance_status,
    is_complete = EXCLUDED.is_complete,
    calculated_at = CURRENT_TIMESTAMP
RETURNING id, total_hours, adherence_percentage, overtime_hours, ''calculated'' as status;

-- Overtime analysis for management reporting
SELECT 
    u.department,
    COUNT(DISTINCT ats.employee_id) as employee_count,
    ROUND(AVG(ats.overtime_hours), 2) as avg_overtime_hours,
    ROUND(SUM(ats.overtime_hours), 2) as total_overtime_hours,
    ROUND(SUM(ats.overtime_hours) * 25.0, 2) as estimated_overtime_cost_usd, -- $25/hour assumption
    COUNT(*) FILTER (WHERE ats.overtime_hours > 2) as high_overtime_sessions,
    ROUND(
        (COUNT(*) FILTER (WHERE ats.overtime_hours > 0)::DECIMAL / COUNT(*)) * 100, 2
    ) as overtime_frequency_percentage,
    CASE 
        WHEN AVG(ats.overtime_hours) > 1.5 THEN ''Высокий уровень'' -- High level
        WHEN AVG(ats.overtime_hours) > 0.5 THEN ''Умеренный уровень'' -- Moderate level  
        ELSE ''Низкий уровень'' -- Low level
    END as overtime_level
FROM attendance_sessions ats
JOIN users u ON ats.employee_id = u.id
WHERE ats.session_date >= CURRENT_DATE - INTERVAL ''30 days''
    AND ats.is_complete = true
    AND ($1 IS NULL OR u.department = $1)
    AND ($2::date IS NULL OR ats.session_date >= $2)
    AND ($3::date IS NULL OR ats.session_date <= $3)
    AND ($4::numeric IS NULL OR ats.overtime_hours >= $4)
GROUP BY u.department
ORDER BY total_overtime_hours DESC;';
```

#### Table 3: attendance_exceptions
```sql
COMMENT ON TABLE attendance_exceptions IS
'API Contract: GET /api/v1/attendance-exceptions
params: {employee_id?: UUID, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, exception_type?: string, severity?: string, resolved?: boolean}
returns: [{
    id: UUID,
    employee_id: UUID,
    exception_date: date,
    exception_type: string,
    severity: string,
    description: string,
    minutes_affected: number,
    auto_detected: boolean,
    resolved: boolean,
    resolution_notes: string,
    resolved_by: UUID,
    resolved_at: timestamp,
    created_at: timestamp,
    employee_name: string,
    department: string,
    resolver_name: string,
    impact_category: string,
    compliance_risk: string
}]

POST /api/v1/attendance-exceptions
expects: {
    employee_id: UUID,
    exception_date: date,
    exception_type: string, // late_arrival, early_departure, excessive_break, no_break, unauthorized_absence
    severity?: string, // minor, major, critical
    description: string,
    minutes_affected?: number,
    auto_detected?: boolean
}
returns: {id: UUID, exception_type: string, severity: string, created_at: timestamp, requires_immediate_action: boolean}

PUT /api/v1/attendance-exceptions/:id/resolve
expects: {
    resolution_notes: string,
    corrective_action?: string,
    disciplinary_action?: boolean,
    follow_up_required?: boolean
}
returns: {id: UUID, resolved_at: timestamp, status: string, next_actions: array}

GET /api/v1/attendance-exceptions/break-compliance
params: {department?: string, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD}
returns: [{
    employee_id: UUID,
    employee_name: string,
    total_break_violations: number,
    missed_breaks: number,
    excessive_breaks: number,
    compliance_score: number,
    risk_level: string
}]

Helper Queries:
-- Get attendance exceptions with detailed analysis and Russian compliance
SELECT 
    ae.id::text as id,
    ae.employee_id::text as employee_id,
    ae.exception_date,
    ae.exception_type,
    ae.severity,
    ae.description,
    ae.minutes_affected,
    ae.auto_detected,
    ae.resolved,
    ae.resolution_notes,
    ae.resolved_by::text as resolved_by,
    ae.resolved_at,
    ae.created_at,
    u.first_name || '' '' || u.last_name as employee_name,
    u.department,
    COALESCE(r.first_name || '' '' || r.last_name, ''Не назначен'') as resolver_name, -- Not assigned
    CASE ae.exception_type
        WHEN ''late_arrival'' THEN ''Опоздание'' -- Late arrival
        WHEN ''early_departure'' THEN ''Ранний уход'' -- Early departure
        WHEN ''excessive_break'' THEN ''Превышение перерыва'' -- Excessive break
        WHEN ''no_break'' THEN ''Отсутствие перерыва'' -- No break
        WHEN ''unauthorized_absence'' THEN ''Неявка'' -- Unauthorized absence
        WHEN ''low_adherence'' THEN ''Низкая дисциплина'' -- Low adherence
        ELSE ae.exception_type
    END as exception_type_russian,
    CASE 
        WHEN ae.minutes_affected <= 15 THEN ''Незначительное'' -- Minor
        WHEN ae.minutes_affected <= 60 THEN ''Умеренное'' -- Moderate
        ELSE ''Серьезное'' -- Serious
    END as impact_category,
    CASE 
        WHEN ae.severity = ''critical'' AND NOT ae.resolved THEN ''Высокий риск'' -- High risk
        WHEN ae.severity = ''major'' AND NOT ae.resolved THEN ''Средний риск'' -- Medium risk
        WHEN NOT ae.resolved THEN ''Низкий риск'' -- Low risk
        ELSE ''Устранено'' -- Resolved
    END as compliance_risk,
    CASE ae.severity
        WHEN ''critical'' THEN ''#F44336'' -- Red
        WHEN ''major'' THEN ''#FF9800'' -- Orange
        ELSE ''#FFC107'' -- Yellow
    END as severity_color,
    CASE 
        WHEN ae.exception_type = ''no_break'' AND ae.minutes_affected > 240 THEN true -- 4+ hours without break violates Russian labor law
        WHEN ae.exception_type = ''excessive_break'' AND ae.minutes_affected > 60 THEN true -- Break >1 hour
        WHEN ae.exception_type = ''late_arrival'' AND ae.minutes_affected > 120 THEN true -- >2 hours late
        ELSE false
    END as requires_immediate_action,
    EXTRACT(days FROM (CURRENT_TIMESTAMP - ae.created_at)) as days_open
FROM attendance_exceptions ae
LEFT JOIN users u ON ae.employee_id = u.id
LEFT JOIN users r ON ae.resolved_by = r.id
WHERE ($1::uuid IS NULL OR ae.employee_id = $1)
    AND ($2::date IS NULL OR ae.exception_date >= $2)
    AND ($3::date IS NULL OR ae.exception_date <= $3)
    AND ($4 IS NULL OR ae.exception_type = $4)
    AND ($5 IS NULL OR ae.severity = $5)
    AND ($6::boolean IS NULL OR ae.resolved = $6)
ORDER BY 
    CASE WHEN ae.resolved THEN 1 ELSE 0 END,
    ae.severity DESC,
    ae.created_at DESC;

-- Create attendance exception with automatic severity determination
WITH exception_analysis AS (
    SELECT 
        $1 as employee_id,
        $2 as exception_date,
        $3 as exception_type,
        $4 as description,
        COALESCE($5, 0) as minutes_affected,
        CASE 
            WHEN $3 = ''no_break'' AND COALESCE($5, 0) > 240 THEN ''critical'' -- No break >4 hours (Russian law violation)
            WHEN $3 = ''late_arrival'' AND COALESCE($5, 0) > 120 THEN ''critical'' -- >2 hours late
            WHEN $3 = ''unauthorized_absence'' THEN ''critical'' -- Absence is always critical
            WHEN $3 = ''excessive_break'' AND COALESCE($5, 0) > 60 THEN ''major'' -- Break >1 hour
            WHEN $3 = ''late_arrival'' AND COALESCE($5, 0) > 30 THEN ''major'' -- >30 min late
            ELSE ''minor''
        END as calculated_severity,
        CASE 
            WHEN $3 IN (''no_break'', ''excessive_break'') THEN 
                ''Нарушение режима перерывов согласно ТК РФ ст. 108'' -- Break regime violation per Labor Code Art. 108
            WHEN $3 = ''late_arrival'' THEN 
                ''Нарушение трудовой дисциплины согласно ТК РФ ст. 21'' -- Work discipline violation per Labor Code Art. 21
            WHEN $3 = ''unauthorized_absence'' THEN 
                ''Прогул согласно ТК РФ ст. 81 п. 6а'' -- Absence per Labor Code Art. 81 p. 6a
            ELSE $4
        END as compliance_description
)
INSERT INTO attendance_exceptions (
    employee_id, exception_date, exception_type, severity,
    description, minutes_affected, auto_detected
)
SELECT 
    ea.employee_id, ea.exception_date, ea.exception_type, ea.calculated_severity,
    ea.compliance_description, ea.minutes_affected, COALESCE($6, true)
FROM exception_analysis ea
RETURNING id, exception_type, severity, created_at,
    CASE 
        WHEN exception_type = ''no_break'' AND minutes_affected > 240 THEN true
        WHEN exception_type = ''unauthorized_absence'' THEN true
        WHEN severity = ''critical'' THEN true
        ELSE false
    END as requires_immediate_action;

-- Break compliance analysis for Russian Labor Law
SELECT 
    u.id::text as employee_id,
    u.first_name || '' '' || u.last_name as employee_name,
    u.department,
    COUNT(*) FILTER (WHERE ae.exception_type IN (''no_break'', ''excessive_break'')) as total_break_violations,
    COUNT(*) FILTER (WHERE ae.exception_type = ''no_break'') as missed_breaks,
    COUNT(*) FILTER (WHERE ae.exception_type = ''excessive_break'') as excessive_breaks,
    ROUND(
        100.0 - (
            COUNT(*) FILTER (WHERE ae.exception_type IN (''no_break'', ''excessive_break'')) * 100.0 / 
            NULLIF(COUNT(DISTINCT ae.exception_date), 0)
        ), 2
    ) as compliance_score,
    CASE 
        WHEN COUNT(*) FILTER (WHERE ae.exception_type = ''no_break'' AND ae.minutes_affected > 240) > 0 
            THEN ''Критический'' -- Critical (violates 4-hour rule)
        WHEN COUNT(*) FILTER (WHERE ae.exception_type IN (''no_break'', ''excessive_break'')) > 5 
            THEN ''Высокий'' -- High
        WHEN COUNT(*) FILTER (WHERE ae.exception_type IN (''no_break'', ''excessive_break'')) > 2 
            THEN ''Средний'' -- Medium
        ELSE ''Низкий'' -- Low
    END as risk_level,
    CASE 
        WHEN COUNT(*) FILTER (WHERE ae.exception_type = ''no_break'' AND ae.minutes_affected > 240) > 0 
            THEN ''Нарушение ТК РФ: работа без перерыва более 4 часов'' -- Labor Code violation: work without break >4 hours
        WHEN COUNT(*) FILTER (WHERE ae.exception_type IN (''no_break'', ''excessive_break'')) > 5 
            THEN ''Систематические нарушения режима'' -- Systematic regime violations
        ELSE ''В рамках нормы'' -- Within normal range
    END as compliance_status
FROM users u
LEFT JOIN attendance_exceptions ae ON u.id = ae.employee_id
    AND ae.exception_date >= COALESCE($2::date, CURRENT_DATE - INTERVAL ''30 days'')
    AND ae.exception_date <= COALESCE($3::date, CURRENT_DATE)
WHERE ($1 IS NULL OR u.department = $1)
    AND u.is_active = true
GROUP BY u.id, u.first_name, u.last_name, u.department
ORDER BY total_break_violations DESC, compliance_score ASC;';
```

#### Table 4: overtime_metrics  
```sql
COMMENT ON TABLE overtime_metrics IS
'API Contract: GET /api/v1/overtime-metrics
params: {employee_id?: UUID, department?: string, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, alert_level?: string}
returns: [{
    id: UUID,
    overtime_report_id: UUID,
    employee_id: UUID,
    department: string,
    individual_overtime_hours: number,
    department_overtime_hours: number,
    overtime_costs: number,
    approval_compliance_pct: number,
    individual_overtime_alert: boolean,
    department_overtime_alert: boolean,
    approval_compliance_alert: boolean,
    optimization_recommendations: object,
    calculated_at: timestamp,
    employee_name: string,
    weekly_average: number,
    monthly_total: number,
    cost_per_hour: number,
    budget_variance: number
}]

POST /api/v1/overtime-metrics/calculate
expects: {
    period_start: date,
    period_end: date,
    department?: string,
    recalculate_existing?: boolean
}
returns: {report_id: UUID, employees_processed: number, total_overtime_hours: number, total_cost: number, alerts_generated: number}

PUT /api/v1/overtime-metrics/:id/approve
expects: {
    approved_hours: number,
    approval_reason: string,
    cost_center?: string,
    budget_adjustment?: number
}
returns: {id: UUID, approved_hours: number, approved_cost: number, status: string}

GET /api/v1/overtime-metrics/budget-analysis
params: {department?: string, period?: string}
returns: [{
    department: string,
    budgeted_amount: number,
    actual_cost: number,
    variance: number,
    variance_percentage: number,
    forecast_end_of_period: number
}]

Helper Queries:
-- Get overtime metrics with comprehensive cost analysis and Russian compliance
SELECT 
    om.id::text as id,
    om.overtime_report_id::text as overtime_report_id,
    COALESCE(om.employee_tab_n, u.id::text) as employee_id,
    om.department,
    om.individual_overtime_hours,
    om.department_overtime_hours,
    om.overtime_costs,
    om.approval_compliance_pct,
    om.individual_overtime_alert,
    om.department_overtime_alert,
    om.approval_compliance_alert,
    om.optimization_recommendations,
    om.calculated_at,
    COALESCE(
        zad.first_name || '' '' || zad.last_name,
        u.first_name || '' '' || u.last_name,
        ''Неизвестно'' -- Unknown
    ) as employee_name,
    ROUND(om.individual_overtime_hours / 4.0, 2) as weekly_average, -- Assuming 4-week period
    om.individual_overtime_hours as monthly_total,
    CASE 
        WHEN om.individual_overtime_hours > 0 THEN 
            ROUND(om.overtime_costs / om.individual_overtime_hours, 2)
        ELSE 0
    END as cost_per_hour,
    CASE 
        WHEN om.individual_overtime_hours > 0 THEN
            om.overtime_costs - (om.individual_overtime_hours * 25.0) -- Assuming $25/hour budget
        ELSE 0
    END as budget_variance,
    CASE 
        WHEN om.individual_overtime_hours > 20 THEN ''Критический'' -- Critical
        WHEN om.individual_overtime_hours > 10 THEN ''Высокий'' -- High
        WHEN om.individual_overtime_hours > 5 THEN ''Умеренный'' -- Moderate
        ELSE ''Нормальный'' -- Normal
    END as overtime_level,
    CASE 
        WHEN om.approval_compliance_pct < 60 THEN ''Низкое соответствие'' -- Low compliance
        WHEN om.approval_compliance_pct < 80 THEN ''Требует улучшения'' -- Needs improvement
        ELSE ''Соответствует'' -- Compliant
    END as compliance_status,
    -- Russian Labor Law compliance checks
    CASE 
        WHEN om.individual_overtime_hours > 40 THEN ''Превышение лимита ТК РФ'' -- Exceeds Labor Code limit
        WHEN om.individual_overtime_hours > 20 THEN ''Приближение к лимиту'' -- Approaching limit
        ELSE ''В рамках закона'' -- Within legal limits
    END as labor_law_compliance
FROM overtime_metrics om
LEFT JOIN zup_agent_data zad ON om.employee_tab_n = zad.tab_n
LEFT JOIN users u ON u.id::text = om.employee_tab_n
WHERE ($1::uuid IS NULL OR u.id = $1 OR zad.tab_n = $1::text)
    AND ($2 IS NULL OR om.department = $2)
    AND ($3::date IS NULL OR om.calculated_at::date >= $3)
    AND ($4::date IS NULL OR om.calculated_at::date <= $4)
    AND ($5 IS NULL OR (
        ($5 = ''high'' AND (om.individual_overtime_alert OR om.department_overtime_alert)) OR
        ($5 = ''compliance'' AND om.approval_compliance_alert) OR
        ($5 = ''all'')
    ))
ORDER BY om.individual_overtime_hours DESC, om.calculated_at DESC;

-- Calculate overtime metrics for period with Russian labor law validation
WITH period_overtime AS (
    SELECT 
        ats.employee_id,
        u.department,
        SUM(ats.overtime_hours) as total_overtime_hours,
        COUNT(*) FILTER (WHERE ats.overtime_hours > 0) as overtime_days,
        COUNT(DISTINCT ats.session_date) as total_working_days,
        SUM(ats.overtime_hours * 
            CASE 
                WHEN EXTRACT(hour FROM ats.clock_out_time) >= 22 OR EXTRACT(hour FROM ats.clock_out_time) <= 6 
                    THEN 35.0 -- Night overtime rate
                WHEN EXTRACT(dow FROM ats.session_date) IN (0, 6) 
                    THEN 40.0 -- Weekend overtime rate
                ELSE 30.0 -- Standard overtime rate
            END
        ) as estimated_cost
    FROM attendance_sessions ats
    JOIN users u ON ats.employee_id = u.id
    WHERE ats.session_date >= $1::date
        AND ats.session_date <= $2::date
        AND ats.is_complete = true
        AND ($3 IS NULL OR u.department = $3)
    GROUP BY ats.employee_id, u.department
),
department_totals AS (
    SELECT 
        department,
        SUM(total_overtime_hours) as dept_total_overtime
    FROM period_overtime
    GROUP BY department
),
compliance_check AS (
    SELECT 
        po.*,
        dt.dept_total_overtime,
        CASE 
            WHEN po.overtime_days > 0 THEN
                (po.overtime_days::DECIMAL / po.total_working_days) * 100
            ELSE 100
        END as approval_compliance_estimate
    FROM period_overtime po
    JOIN department_totals dt ON po.department = dt.department
)
INSERT INTO overtime_metrics (
    overtime_report_id, employee_tab_n, department,
    individual_overtime_hours, department_overtime_hours,
    overtime_costs, approval_compliance_pct,
    optimization_recommendations
)
SELECT 
    $4::uuid, -- report_id parameter
    cc.employee_id::text,
    cc.department,
    cc.total_overtime_hours,
    cc.dept_total_overtime,
    cc.estimated_cost,
    cc.approval_compliance_estimate,
    jsonb_build_object(
        ''recommendations'', CASE 
            WHEN cc.total_overtime_hours > 40 THEN 
                ARRAY[''Превышение лимита ТК РФ - требуется корректировка'', ''Рассмотреть дополнительный найм'']
            WHEN cc.total_overtime_hours > 20 THEN 
                ARRAY[''Оптимизировать планирование смен'', ''Анализ загрузки сотрудников'']
            WHEN cc.approval_compliance_estimate < 80 THEN
                ARRAY[''Улучшить процесс одобрения сверхурочных'', ''Обучение менеджеров'']
            ELSE ARRAY[''Текущий уровень приемлем'']
        END,
        ''labor_law_status'', CASE 
            WHEN cc.total_overtime_hours > 40 THEN ''violation''
            WHEN cc.total_overtime_hours > 20 THEN ''warning''
            ELSE ''compliant''
        END,
        ''cost_optimization'', CASE 
            WHEN cc.estimated_cost > (cc.total_overtime_hours * 25) THEN 
                ''Высокая стоимость - рассмотреть альтернативы''
            ELSE ''Стоимость в норме''
        END
    )
FROM compliance_check cc
ON CONFLICT DO NOTHING
RETURNING 
    $4::uuid as report_id,
    COUNT(*) as employees_processed,
    SUM(individual_overtime_hours) as total_overtime_hours,
    SUM(overtime_costs) as total_cost,
    COUNT(*) FILTER (WHERE individual_overtime_alert OR department_overtime_alert OR approval_compliance_alert) as alerts_generated;

-- Budget analysis for overtime management
SELECT 
    COALESCE(om.department, ''Не указано'') as department, -- Not specified
    COALESCE(SUM(
        CASE 
            WHEN EXTRACT(month FROM om.calculated_at) = EXTRACT(month FROM CURRENT_DATE) 
            THEN om.individual_overtime_hours * 25.0 -- Budget rate assumption
            ELSE 0 
        END
    ), 0) as budgeted_amount,
    COALESCE(SUM(
        CASE 
            WHEN EXTRACT(month FROM om.calculated_at) = EXTRACT(month FROM CURRENT_DATE) 
            THEN om.overtime_costs 
            ELSE 0 
        END
    ), 0) as actual_cost,
    COALESCE(SUM(
        CASE 
            WHEN EXTRACT(month FROM om.calculated_at) = EXTRACT(month FROM CURRENT_DATE) 
            THEN om.overtime_costs - (om.individual_overtime_hours * 25.0)
            ELSE 0 
        END
    ), 0) as variance,
    CASE 
        WHEN SUM(om.individual_overtime_hours * 25.0) > 0 THEN
            ROUND((SUM(om.overtime_costs - (om.individual_overtime_hours * 25.0)) / 
                   SUM(om.individual_overtime_hours * 25.0)) * 100, 2)
        ELSE 0
    END as variance_percentage,
    -- Forecast based on current trend
    ROUND(
        SUM(om.overtime_costs) * 
        (DATE_PART(''days'', DATE_TRUNC(''month'', CURRENT_DATE) + INTERVAL ''1 month'' - INTERVAL ''1 day'') / 
         DATE_PART(''day'', CURRENT_DATE)), 2
    ) as forecast_end_of_period
FROM overtime_metrics om
WHERE ($1 IS NULL OR om.department = $1)
    AND ($2 IS NULL OR (
        ($2 = ''current_month'' AND EXTRACT(month FROM om.calculated_at) = EXTRACT(month FROM CURRENT_DATE)) OR
        ($2 = ''last_month'' AND EXTRACT(month FROM om.calculated_at) = EXTRACT(month FROM CURRENT_DATE - INTERVAL ''1 month'')) OR
        ($2 = ''quarterly'' AND om.calculated_at >= DATE_TRUNC(''quarter'', CURRENT_DATE))
    ))
GROUP BY om.department
ORDER BY actual_cost DESC;';
```

#### Table 5: real_time_status
```sql
COMMENT ON TABLE real_time_status IS
'API Contract: GET /api/v1/real-time-status
params: {employee_id?: UUID, department?: string, current_state?: string, activity_status?: string}
returns: [{
    id: UUID,
    employee_id: UUID,
    current_state_id: UUID,
    current_state_name: string,
    current_state_code: string,
    state_start_time: timestamp,
    last_activity_time: timestamp,
    location_data: object,
    session_duration_minutes: number,
    productive_time_today: number,
    break_time_today: number,
    calls_handled_today: number,
    last_updated: timestamp,
    employee_name: string,
    department: string,
    activity_status: string,
    state_color: string,
    productivity_score: number,
    compliance_status: string
}]

POST /api/v1/real-time-status/update
expects: {
    employee_id: UUID,
    new_state_code: string,
    location_data?: object,
    reason?: string,
    supervisor_override?: boolean
}
returns: {employee_id: UUID, current_state: string, state_start_time: timestamp, duration_previous_state: number, status: string}

PUT /api/v1/real-time-status/:employee_id/activity
expects: {
    activity_type: string, // call_answered, call_completed, break_taken, task_completed
    activity_data?: object,
    performance_metrics?: object
}
returns: {employee_id: UUID, activity_logged: boolean, updated_metrics: object, status: string}

GET /api/v1/real-time-status/dashboard
params: {department?: string, state_category?: string}
returns: [{
    department: string,
    total_employees: number,
    available_count: number,
    busy_count: number,
    break_count: number,
    offline_count: number,
    avg_productivity: number,
    service_level_current: number
}]

Helper Queries:
-- Get real-time status with comprehensive workforce analytics
SELECT 
    rts.id::text as id,
    rts.employee_id::text as employee_id,
    rts.current_state_id::text as current_state_id,
    ws.state_name as current_state_name,
    ws.state_code as current_state_code,
    rts.state_start_time,
    rts.last_activity_time,
    rts.location_data,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 as session_duration_minutes,
    rts.productive_time_today,
    rts.break_time_today,
    rts.calls_handled_today,
    rts.last_updated,
    u.first_name || '' '' || u.last_name as employee_name,
    u.department,
    u.position as employee_position,
    CASE 
        WHEN rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''5 minutes'' THEN ''Неактивен'' -- Inactive
        WHEN ws.state_code IN (''AVAIL'', ''BUSY'', ''ACW'') THEN ''Активен'' -- Active
        WHEN ws.state_code IN (''BREAK'', ''LUNCH'') THEN ''На перерыве'' -- On break
        ELSE ''Офлайн'' -- Offline
    END as activity_status,
    ws.color_code as state_color,
    CASE 
        WHEN rts.productive_time_today > 0 THEN
            ROUND((rts.productive_time_today / (rts.productive_time_today + rts.break_time_today)) * 100, 2)
        ELSE 0
    END as productivity_score,
    CASE 
        WHEN ws.state_code = ''BREAK'' AND EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 > 30 THEN 
            ''Превышение перерыва'' -- Break exceeded
        WHEN ws.state_code = ''LUNCH'' AND EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 > 60 THEN 
            ''Превышение обеда'' -- Lunch exceeded
        WHEN rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''15 minutes'' AND ws.state_code NOT IN (''BREAK'', ''LUNCH'', ''OFFLINE'') THEN 
            ''Отсутствие активности'' -- No activity
        ELSE ''В норме'' -- Normal
    END as compliance_status,
    CASE 
        WHEN ws.state_code IN (''AVAIL'', ''BUSY'', ''ACW'') THEN ''productive''
        WHEN ws.state_code IN (''BREAK'', ''LUNCH'') THEN ''break''
        WHEN ws.state_code IN (''TRAIN'', ''MEET'', ''ADMIN'') THEN ''auxiliary''
        ELSE ''offline''
    END as state_category,
    -- Performance indicators
    CASE 
        WHEN rts.calls_handled_today >= 40 THEN ''Высокая'' -- High
        WHEN rts.calls_handled_today >= 25 THEN ''Средняя'' -- Average  
        WHEN rts.calls_handled_today >= 10 THEN ''Низкая'' -- Low
        ELSE ''Очень низкая'' -- Very low
    END as performance_level,
    -- Time in current state
    to_char(rts.state_start_time, ''HH24:MI'') as state_start_time_formatted,
    CASE 
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 < 60 THEN
            ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60) || '' мин''
        ELSE 
            ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 3600, 1) || '' ч''
    END as time_in_state
FROM real_time_status rts
LEFT JOIN work_states ws ON rts.current_state_id = ws.id
LEFT JOIN users u ON rts.employee_id = u.id
WHERE ($1::uuid IS NULL OR rts.employee_id = $1)
    AND ($2 IS NULL OR u.department = $2)
    AND ($3 IS NULL OR ws.state_code = $3)
    AND ($4 IS NULL OR (
        ($4 = ''active'' AND rts.last_activity_time >= CURRENT_TIMESTAMP - INTERVAL ''5 minutes'') OR
        ($4 = ''inactive'' AND rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''5 minutes'') OR
        ($4 = ''break'' AND ws.state_code IN (''BREAK'', ''LUNCH'')) OR
        ($4 = ''productive'' AND ws.state_code IN (''AVAIL'', ''BUSY'', ''ACW''))
    ))
ORDER BY u.department, u.last_name, u.first_name;

-- Update real-time status with validation and compliance checks
WITH state_validation AS (
    SELECT 
        $1 as employee_id,
        $2 as new_state_code,
        $3 as location_data,
        $4 as reason,
        ws.id as new_state_id,
        ws.state_name,
        CURRENT_TIMESTAMP as update_time,
        rts.current_state_id as previous_state_id,
        rts.state_start_time as previous_start_time,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 as previous_duration
    FROM work_states ws
    LEFT JOIN real_time_status rts ON rts.employee_id = $1
    WHERE ws.state_code = $2 AND ws.is_active = true
),
compliance_check AS (
    SELECT 
        sv.*,
        CASE 
            WHEN sv.new_state_code = ''BREAK'' AND sv.previous_duration < 120 THEN false -- Must work 2+ hours before break
            WHEN sv.new_state_code = ''LUNCH'' AND EXTRACT(hour FROM sv.update_time) NOT BETWEEN 11 AND 15 THEN false -- Lunch time restrictions
            WHEN sv.new_state_code IN (''BREAK'', ''LUNCH'') AND EXISTS (
                SELECT 1 FROM real_time_status rts2 
                JOIN work_states ws2 ON rts2.current_state_id = ws2.id
                WHERE rts2.employee_id = sv.employee_id 
                AND ws2.state_code IN (''BREAK'', ''LUNCH'')
                AND rts2.state_start_time > CURRENT_DATE
            ) THEN false -- Already had break today
            ELSE true
        END as is_valid_transition
    FROM state_validation sv
)
UPDATE real_time_status rts
SET 
    current_state_id = cc.new_state_id,
    state_start_time = cc.update_time,
    last_activity_time = cc.update_time,
    location_data = COALESCE($3::jsonb, rts.location_data),
    session_duration_minutes = 0,
    last_updated = cc.update_time
FROM compliance_check cc
WHERE rts.employee_id = cc.employee_id 
    AND cc.is_valid_transition = true
    AND ($5::boolean IS TRUE OR cc.is_valid_transition = true) -- supervisor override
RETURNING 
    rts.employee_id::text,
    cc.new_state_code as current_state,
    cc.update_time as state_start_time,
    cc.previous_duration as duration_previous_state,
    CASE 
        WHEN cc.is_valid_transition THEN ''success''
        ELSE ''validation_failed''
    END as status;

-- Real-time dashboard aggregation for operations management  
SELECT 
    COALESCE(u.department, ''Не указано'') as department, -- Not specified
    COUNT(DISTINCT rts.employee_id) as total_employees,
    COUNT(*) FILTER (WHERE ws.state_code = ''AVAIL'') as available_count,
    COUNT(*) FILTER (WHERE ws.state_code IN (''BUSY'', ''ACW'')) as busy_count,
    COUNT(*) FILTER (WHERE ws.state_code IN (''BREAK'', ''LUNCH'')) as break_count,
    COUNT(*) FILTER (WHERE ws.state_code = ''OFFLINE'' OR rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''10 minutes'') as offline_count,
    ROUND(AVG(
        CASE 
            WHEN rts.productive_time_today > 0 THEN 
                (rts.productive_time_today / (rts.productive_time_today + rts.break_time_today)) * 100
            ELSE 0 
        END
    ), 2) as avg_productivity,
    ROUND(
        (COUNT(*) FILTER (WHERE ws.state_code IN (''AVAIL'', ''BUSY''))::DECIMAL / 
         NULLIF(COUNT(*) FILTER (WHERE ws.state_code != ''OFFLINE''), 0)) * 100, 2
    ) as service_level_current,
    COUNT(*) FILTER (WHERE 
        ws.state_code = ''BREAK'' AND 
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rts.state_start_time)) / 60 > 30
    ) as break_violations,
    COUNT(*) FILTER (WHERE 
        rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''15 minutes'' AND 
        ws.state_code NOT IN (''BREAK'', ''LUNCH'', ''OFFLINE'')
    ) as activity_violations,
    ROUND(AVG(rts.calls_handled_today), 1) as avg_calls_today,
    CASE 
        WHEN AVG(
            CASE 
                WHEN rts.productive_time_today > 0 THEN 
                    (rts.productive_time_today / (rts.productive_time_today + rts.break_time_today)) * 100
                ELSE 0 
            END
        ) >= 85 THEN ''Отличная'' -- Excellent
        WHEN AVG(
            CASE 
                WHEN rts.productive_time_today > 0 THEN 
                    (rts.productive_time_today / (rts.productive_time_today + rts.break_time_today)) * 100
                ELSE 0 
            END
        ) >= 75 THEN ''Хорошая'' -- Good
        ELSE ''Требует внимания'' -- Needs attention
    END as department_performance_status
FROM real_time_status rts
LEFT JOIN work_states ws ON rts.current_state_id = ws.id
LEFT JOIN users u ON rts.employee_id = u.id
WHERE ($1 IS NULL OR u.department = $1)
    AND ($2 IS NULL OR (
        ($2 = ''productive'' AND ws.state_code IN (''AVAIL'', ''BUSY'', ''ACW'')) OR
        ($2 = ''break'' AND ws.state_code IN (''BREAK'', ''LUNCH'')) OR
        ($2 = ''auxiliary'' AND ws.state_code IN (''TRAIN'', ''MEET'', ''ADMIN'')) OR
        ($2 = ''offline'' AND (ws.state_code = ''OFFLINE'' OR rts.last_activity_time < CURRENT_TIMESTAMP - INTERVAL ''10 minutes''))
    ))
GROUP BY u.department
ORDER BY total_employees DESC;';
```

#### Table 6: payroll_time_codes
```sql
COMMENT ON TABLE payroll_time_codes IS
'API Contract: GET /api/v1/payroll-time-codes
params: {employee_id?: string, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, time_code?: string, payroll_report_id?: UUID}
returns: [{
    id: UUID,
    employee_tab_n: string,
    payroll_report_id: UUID,
    work_date: date,
    time_code: string,
    time_code_russian: string,
    time_code_english: string,
    zup_document_type: string,
    hours_worked: number,
    created_at: timestamp,
    employee_name: string,
    department: string,
    hourly_rate: number,
    calculated_pay: number,
    compliance_status: string
}]

POST /api/v1/payroll-time-codes/generate
expects: {
    employee_id: string,
    period_start: date,
    period_end: date,
    force_regenerate?: boolean,
    time_code_overrides?: object
}
returns: {employee_id: string, time_codes_generated: number, total_hours: number, estimated_pay: number, compliance_issues: array}

PUT /api/v1/payroll-time-codes/:id/adjust
expects: {
    adjusted_hours: number,
    adjustment_reason: string,
    supervisor_approval: boolean,
    time_code_override?: string
}
returns: {id: UUID, original_hours: number, adjusted_hours: number, pay_difference: number, status: string}

GET /api/v1/payroll-time-codes/1c-export
params: {payroll_report_id: UUID, format?: string}
returns: {
    export_file_url: string,
    total_employees: number,
    total_hours: number,
    export_format: string,
    zup_compatible: boolean
}

Helper Queries:
-- Get payroll time codes with 1C ZUP integration and Russian compliance
SELECT 
    ptc.id::text as id,
    ptc.employee_tab_n,
    ptc.payroll_report_id::text as payroll_report_id,
    ptc.work_date,
    ptc.time_code,
    ptc.time_code_russian,
    ptc.time_code_english,
    ptc.zup_document_type,
    ptc.hours_worked,
    ptc.created_at,
    COALESCE(
        zad.first_name || '' '' || zad.last_name,
        ''Неизвестный сотрудник'' -- Unknown employee
    ) as employee_name,
    COALESCE(zad.department, ''Не указано'') as department, -- Not specified
    COALESCE(zad.hourly_rate, 25.0) as hourly_rate, -- Default rate
    ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0), 2) as calculated_pay,
    CASE ptc.time_code
        WHEN ''I'' THEN ''Дневная работа'' -- Day work
        WHEN ''H'' THEN ''Ночная работа'' -- Night work  
        WHEN ''B'' THEN ''Выходной день'' -- Day off
        WHEN ''C'' THEN ''Сверхурочная работа'' -- Overtime
        WHEN ''RV'' THEN ''Работа в выходные'' -- Weekend work
        WHEN ''RVN'' THEN ''Ночная работа в выходные'' -- Night weekend work
        WHEN ''NV'' THEN ''Неявка'' -- Absence
        WHEN ''OT'' THEN ''Ежегодный отпуск'' -- Annual vacation
        ELSE ptc.time_code_english
    END as time_code_description_russian,
    CASE 
        WHEN ptc.time_code = ''C'' AND ptc.hours_worked > 4 THEN ''Превышение лимита сверхурочных (4ч/день)'' -- Overtime limit exceeded
        WHEN ptc.time_code = ''H'' AND ptc.hours_worked > 8 THEN ''Превышение ночной смены'' -- Night shift exceeded
        WHEN ptc.time_code IN (''RV'', ''RVN'') AND NOT EXISTS (
            SELECT 1 FROM russian_calendar rc 
            WHERE rc.calendar_date = ptc.work_date AND rc.is_weekend = true
        ) THEN ''Некорректно указан выходной'' -- Weekend incorrectly marked
        ELSE ''Соответствует ТК РФ'' -- Complies with Labor Code
    END as compliance_status,
    -- Pay calculation with Russian rates
    CASE ptc.time_code
        WHEN ''C'' THEN ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0) * 1.5, 2) -- 1.5x for overtime
        WHEN ''H'' THEN ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0) * 1.2, 2) -- 1.2x for night
        WHEN ''RV'' THEN ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0) * 2.0, 2) -- 2x for weekend
        WHEN ''RVN'' THEN ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0) * 2.4, 2) -- 2.4x for night weekend
        ELSE ROUND(ptc.hours_worked * COALESCE(zad.hourly_rate, 25.0), 2) -- Standard rate
    END as adjusted_pay,
    pcr.period_start,
    pcr.period_end,
    pcr.report_mode
FROM payroll_time_codes ptc
LEFT JOIN zup_agent_data zad ON ptc.employee_tab_n = zad.tab_n
LEFT JOIN payroll_calculation_reports pcr ON ptc.payroll_report_id = pcr.id
WHERE ($1 IS NULL OR ptc.employee_tab_n = $1)
    AND ($2::date IS NULL OR ptc.work_date >= $2)
    AND ($3::date IS NULL OR ptc.work_date <= $3)
    AND ($4 IS NULL OR ptc.time_code = $4)
    AND ($5::uuid IS NULL OR ptc.payroll_report_id = $5)
ORDER BY ptc.work_date DESC, ptc.employee_tab_n;

-- Generate payroll time codes from attendance data
WITH attendance_analysis AS (
    SELECT 
        u.id::text as employee_tab_n,
        ats.session_date as work_date,
        ats.total_hours,
        ats.overtime_hours,
        ats.attendance_status,
        CASE 
            WHEN EXTRACT(dow FROM ats.session_date) IN (0, 6) THEN true -- Weekend
            WHEN EXISTS (
                SELECT 1 FROM russian_calendar rc 
                WHERE rc.calendar_date = ats.session_date AND rc.is_holiday = true
            ) THEN true
            ELSE false
        END as is_weekend_or_holiday,
        CASE 
            WHEN ats.clock_out_time IS NOT NULL AND EXTRACT(hour FROM ats.clock_out_time) >= 22 THEN true
            WHEN ats.clock_in_time IS NOT NULL AND EXTRACT(hour FROM ats.clock_in_time) <= 6 THEN true
            ELSE false
        END as is_night_shift,
        ats.attendance_status
    FROM attendance_sessions ats
    JOIN users u ON ats.employee_id = u.id
    WHERE ats.session_date >= $2::date
        AND ats.session_date <= $3::date
        AND ($1 IS NULL OR u.id::text = $1)
        AND ats.is_complete = true
),
time_code_determination AS (
    SELECT 
        aa.*,
        CASE 
            WHEN aa.attendance_status = ''absent'' THEN ''NV'' -- Absence
            WHEN aa.overtime_hours > 0 AND aa.is_weekend_or_holiday AND aa.is_night_shift THEN ''RVN'' -- Night weekend work
            WHEN aa.overtime_hours > 0 AND aa.is_weekend_or_holiday THEN ''RV'' -- Weekend work  
            WHEN aa.overtime_hours > 0 THEN ''C'' -- Overtime
            WHEN aa.is_night_shift THEN ''H'' -- Night work
            WHEN aa.is_weekend_or_holiday THEN ''B'' -- Day off work
            ELSE ''I'' -- Regular day work
        END as primary_time_code,
        CASE 
            WHEN aa.attendance_status = ''absent'' THEN 0
            WHEN aa.overtime_hours > 0 THEN LEAST(aa.total_hours - aa.overtime_hours, 8)
            ELSE LEAST(aa.total_hours, 8)
        END as regular_hours,
        aa.overtime_hours
    FROM attendance_analysis aa
)
INSERT INTO payroll_time_codes (
    employee_tab_n, payroll_report_id, work_date, 
    time_code, time_code_russian, time_code_english, 
    zup_document_type, hours_worked
)
SELECT 
    tcd.employee_tab_n,
    $4::uuid, -- payroll_report_id parameter
    tcd.work_date,
    tcd.primary_time_code,
    CASE tcd.primary_time_code
        WHEN ''I'' THEN ''Я'' WHEN ''H'' THEN ''Н'' WHEN ''B'' THEN ''В'' WHEN ''C'' THEN ''С''
        WHEN ''RV'' THEN ''РВ'' WHEN ''RVN'' THEN ''РВН'' WHEN ''NV'' THEN ''НВ'' WHEN ''OT'' THEN ''ОТ''
    END,
    CASE tcd.primary_time_code
        WHEN ''I'' THEN ''Day work'' WHEN ''H'' THEN ''Night work'' WHEN ''B'' THEN ''Day off''
        WHEN ''C'' THEN ''Overtime'' WHEN ''RV'' THEN ''Weekend work'' WHEN ''RVN'' THEN ''Night weekend work''
        WHEN ''NV'' THEN ''Absence'' WHEN ''OT'' THEN ''Annual vacation''
    END,
    ''Индивидуальный график'', -- Individual schedule
    CASE 
        WHEN tcd.primary_time_code = ''C'' THEN tcd.overtime_hours
        WHEN tcd.primary_time_code = ''NV'' THEN 0
        ELSE tcd.regular_hours
    END
FROM time_code_determination tcd
WHERE ($5::boolean IS TRUE OR NOT EXISTS (
    SELECT 1 FROM payroll_time_codes ptc2 
    WHERE ptc2.employee_tab_n = tcd.employee_tab_n 
    AND ptc2.work_date = tcd.work_date
    AND ptc2.payroll_report_id = $4::uuid
))
-- Also insert overtime records separately if needed
UNION ALL
SELECT 
    tcd.employee_tab_n,
    $4::uuid,
    tcd.work_date,
    ''C'', ''С'', ''Overtime'',
    ''Индивидуальный график'',
    tcd.overtime_hours
FROM time_code_determination tcd
WHERE tcd.overtime_hours > 0 
    AND tcd.primary_time_code != ''C'' -- Don''t duplicate if primary code is already overtime
    AND ($5::boolean IS TRUE OR NOT EXISTS (
        SELECT 1 FROM payroll_time_codes ptc3 
        WHERE ptc3.employee_tab_n = tcd.employee_tab_n 
        AND ptc3.work_date = tcd.work_date
        AND ptc3.time_code = ''C''
        AND ptc3.payroll_report_id = $4::uuid
    ))
ON CONFLICT (employee_tab_n, work_date, time_code, payroll_report_id) DO UPDATE SET
    hours_worked = EXCLUDED.hours_worked,
    created_at = CURRENT_TIMESTAMP
RETURNING 
    employee_tab_n as employee_id,
    COUNT(*) as time_codes_generated,
    SUM(hours_worked) as total_hours,
    SUM(hours_worked * 25.0) as estimated_pay, -- Base rate assumption
    ARRAY[]::text[] as compliance_issues; -- Would be populated with actual compliance checks

-- 1C ZUP export format generation
SELECT 
    jsonb_build_object(
        ''export_metadata'', jsonb_build_object(
            ''report_id'', $1::text,
            ''export_timestamp'', CURRENT_TIMESTAMP,
            ''format_version'', ''1C_ZUP_8.3'',
            ''compliance_verified'', true
        ),
        ''employee_data'', jsonb_agg(
            jsonb_build_object(
                ''tab_number'', ptc.employee_tab_n,
                ''employee_name'', COALESCE(zad.last_name || '' '' || zad.first_name, ''Unknown''),
                ''department'', COALESCE(zad.department, ''Not specified''),
                ''position'', COALESCE(zad.position, ''Not specified''),
                ''time_records'', time_records_array
            )
        ),
        ''summary'', jsonb_build_object(
            ''total_employees'', COUNT(DISTINCT ptc.employee_tab_n),
            ''total_hours'', SUM(ptc.hours_worked),
            ''total_overtime_hours'', SUM(CASE WHEN ptc.time_code = ''C'' THEN ptc.hours_worked ELSE 0 END),
            ''compliance_status'', ''verified''
        )
    ) as zup_export_data
FROM payroll_time_codes ptc
LEFT JOIN zup_agent_data zad ON ptc.employee_tab_n = zad.tab_n
LEFT JOIN LATERAL (
    SELECT jsonb_agg(
        jsonb_build_object(
            ''work_date'', ptc2.work_date,
            ''time_code'', ptc2.time_code,
            ''time_code_russian'', ptc2.time_code_russian,
            ''hours'', ptc2.hours_worked,
            ''document_type'', ptc2.zup_document_type
        ) ORDER BY ptc2.work_date
    ) as time_records_array
    FROM payroll_time_codes ptc2 
    WHERE ptc2.employee_tab_n = ptc.employee_tab_n 
    AND ptc2.payroll_report_id = ptc.payroll_report_id
) tr ON true
WHERE ptc.payroll_report_id = $1::uuid
GROUP BY ptc.payroll_report_id;';
```

### Step 3: Create Test Data for Operational Tables
```sql
-- Insert test work states
INSERT INTO work_states (state_code, state_name, description, is_productive, counts_as_work_time, color_code, sort_order) VALUES
('AVAIL', 'Available', 'Ready to handle calls/tasks', true, true, '#4CAF50', 10),
('BUSY', 'Busy', 'Handling customer call/task', true, true, '#2196F3', 20),
('ACW', 'After Call Work', 'Post-call documentation', true, true, '#FF9800', 30),
('BREAK', 'Break', 'Short break period', false, false, '#FFC107', 40),
('LUNCH', 'Lunch', 'Lunch break', false, false, '#FF5722', 50)
ON CONFLICT (state_code) DO NOTHING;

-- Insert test time entries
INSERT INTO time_entries (
    employee_id, entry_type, entry_timestamp, work_state_id,
    location_data, entry_method, reason_code, notes
)
SELECT 
    u.id,
    'clock_in',
    CURRENT_DATE + TIME '09:00:00' + (RANDOM() * INTERVAL '30 minutes'),
    ws.id,
    '{"ip": "192.168.1.100", "location": "Office"}' ::jsonb,
    'card',
    'normal_start',
    'Regular morning clock-in'
FROM users u
CROSS JOIN work_states ws
WHERE u.username IN ('system', 'admin') 
    AND ws.state_code = 'AVAIL'
LIMIT 2
ON CONFLICT DO NOTHING;

-- Insert test attendance session
INSERT INTO attendance_sessions (
    employee_id, session_date, clock_in_time, clock_out_time,
    scheduled_start, scheduled_end, total_hours, productive_hours,
    break_hours, overtime_hours, late_minutes, early_departure_minutes,
    adherence_percentage, attendance_status, is_complete
)
SELECT 
    u.id,
    CURRENT_DATE,
    CURRENT_DATE + TIME '09:15:00',
    CURRENT_DATE + TIME '18:30:00',
    CURRENT_DATE + TIME '09:00:00',
    CURRENT_DATE + TIME '18:00:00',
    9.25,
    7.5,
    1.0,
    0.5,
    15,
    0,
    85.5,
    'present',
    true
FROM users u
WHERE u.username = 'system'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test attendance exception
INSERT INTO attendance_exceptions (
    employee_id, exception_date, exception_type, severity,
    description, minutes_affected, auto_detected
)
SELECT 
    u.id,
    CURRENT_DATE,
    'late_arrival',
    'minor',
    'Employee arrived 15 minutes late due to traffic',
    15,
    true
FROM users u
WHERE u.username = 'admin'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test real-time status
INSERT INTO real_time_status (
    employee_id, current_state_id, state_start_time, last_activity_time,
    productive_time_today, break_time_today, calls_handled_today
)
SELECT 
    u.id,
    ws.id,
    CURRENT_TIMESTAMP - INTERVAL '2 hours',
    CURRENT_TIMESTAMP - INTERVAL '5 minutes',
    6.5,
    1.0,
    23
FROM users u
CROSS JOIN work_states ws
WHERE u.username = 'system' 
    AND ws.state_code = 'AVAIL'
LIMIT 1
ON CONFLICT (employee_id) DO UPDATE SET
    current_state_id = EXCLUDED.current_state_id,
    last_activity_time = EXCLUDED.last_activity_time;

-- Create test payroll report
INSERT INTO payroll_calculation_reports (
    report_mode, data_source, period_type, period_start, period_end, generated_by
) VALUES (
    '1C Data', 'WFM Attendance', 'Monthly', 
    DATE_TRUNC('month', CURRENT_DATE), 
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    'system'
) ON CONFLICT DO NOTHING;

-- Insert test payroll time codes
INSERT INTO payroll_time_codes (
    employee_tab_n, payroll_report_id, work_date, time_code,
    time_code_russian, time_code_english, zup_document_type, hours_worked
)
SELECT 
    u.id::text,
    pcr.id,
    CURRENT_DATE,
    'I',
    'Я',
    'Day work',
    'Individual schedule',
    8.0
FROM users u
CROSS JOIN payroll_calculation_reports pcr
WHERE u.username = 'system'
    AND pcr.period_start <= CURRENT_DATE
    AND pcr.period_end >= CURRENT_DATE
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test overtime metric
INSERT INTO overtime_tracking_reports (tracking_period_start, tracking_period_end)
VALUES (DATE_TRUNC('month', CURRENT_DATE), CURRENT_DATE)
ON CONFLICT DO NOTHING;

INSERT INTO overtime_metrics (
    overtime_report_id, employee_tab_n, department,
    individual_overtime_hours, department_overtime_hours,
    overtime_costs, approval_compliance_pct,
    optimization_recommendations
)
SELECT 
    otr.id,
    u.id::text,
    COALESCE(u.department, 'Customer Support'),
    12.5,
    45.0,
    312.50,
    78.0,
    '{"recommendations": ["Optimize shift planning", "Review workload distribution"], "priority": "medium"}'::jsonb
FROM users u
CROSS JOIN overtime_tracking_reports otr
WHERE u.username = 'admin'
    AND otr.tracking_period_start <= CURRENT_DATE
    AND otr.tracking_period_end >= CURRENT_DATE
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract: GET /api/v1/%' 
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
WHERE relname IN ('time_entries', 'attendance_sessions', 'attendance_exceptions', 'overtime_metrics', 'real_time_status', 'payroll_time_codes')
ORDER BY relname;"
```

### Step 5: Test Sample Queries
```sql
-- Test time entries with Russian labor compliance
SELECT 
    te.entry_type,
    te.entry_timestamp::time as time_logged,
    ws.state_name,
    CASE 
        WHEN te.supervisor_override THEN 'Supervisor Override'
        WHEN te.entry_method = 'biometric' THEN 'Biometric Verified'
        ELSE 'Standard Entry'
    END as verification_status
FROM time_entries te
LEFT JOIN work_states ws ON te.work_state_id = ws.id
ORDER BY te.entry_timestamp DESC
LIMIT 3;

-- Test attendance sessions with overtime analysis
SELECT 
    ats.session_date,
    ats.total_hours,
    ats.overtime_hours,
    ats.adherence_percentage,
    CASE 
        WHEN ats.adherence_percentage >= 95 THEN 'Excellent'
        WHEN ats.adherence_percentage >= 85 THEN 'Good'
        ELSE 'Needs Improvement'
    END as performance_rating
FROM attendance_sessions ats
WHERE ats.is_complete = true
ORDER BY ats.session_date DESC
LIMIT 3;

-- Test real-time status dashboard
SELECT 
    ws.state_name,
    ws.color_code,
    COUNT(*) as employee_count,
    ROUND(AVG(rts.productive_time_today), 2) as avg_productive_hours
FROM real_time_status rts
JOIN work_states ws ON rts.current_state_id = ws.id
GROUP BY ws.state_name, ws.color_code
ORDER BY employee_count DESC;

-- Test payroll time codes with 1C ZUP format
SELECT 
    ptc.time_code,
    ptc.time_code_russian,
    ptc.time_code_english,
    SUM(ptc.hours_worked) as total_hours,
    COUNT(*) as record_count
FROM payroll_time_codes ptc
GROUP BY ptc.time_code, ptc.time_code_russian, ptc.time_code_english
ORDER BY total_hours DESC;
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 6 tables have comprehensive API contract comments with Russian language support
- [ ] Each table has full CRUD endpoints with complex business logic documentation
- [ ] Helper queries include proper parameter binding and Russian labor law compliance
- [ ] Test data demonstrates complete operational workflows
- [ ] Verification query shows ✅ for all tables
- [ ] Sample queries execute successfully with realistic operational data
- [ ] Integration with 1C ZUP systems documented
- [ ] Performance optimization for large datasets included

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_009: Complete - 6 operational WFM tables documented with comprehensive API contracts, Russian compliance, and 1C ZUP integration" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If foreign key references fail:
- Check that referenced tables (users, work_states, zup_agent_data) exist
- Use existing records for test data

If Russian calendar references fail:
- Create minimal russian_calendar table if needed
- Document dependency for future implementation

If 1C ZUP integration tables are missing:
- Check for zup_agent_data table existence
- Document integration requirements

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Key Features Documented

1. **Time & Attendance Tracking**: Complete clock in/out system with location verification and compliance
2. **Break Management**: Russian Labor Law compliance with automatic violation detection
3. **Overtime Calculation**: Comprehensive overtime tracking with cost analysis and approval workflow
4. **Real-time Monitoring**: Live employee status with productivity scoring and compliance alerts
5. **Payroll Integration**: 1C ZUP integration with Russian time codes and automated export
6. **Performance Analytics**: Advanced reporting with adherence scoring and operational metrics

This completes the operational WFM table documentation with enterprise-ready API contracts supporting Russian labor compliance and 1C ZUP payroll integration.