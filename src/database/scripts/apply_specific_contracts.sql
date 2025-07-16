-- Apply specific API contracts to key table types

-- Update employee-related tables with proper contracts
UPDATE pg_description
SET description = 'API Contract: GET /api/v1/employees/{id}/schedule
params: {date_from: YYYY-MM-DD, date_to: YYYY-MM-DD}
returns: [{date: YYYY-MM-DD, shift_start: HH:MM, shift_end: HH:MM, break_minutes: int}]

Helper Queries:
-- Get employee schedule
SELECT 
    schedule_date::text as date,
    shift_start_time::text as shift_start,
    shift_end_time::text as shift_end,
    break_duration as break_minutes
FROM employee_schedules
WHERE employee_id = $1 
    AND schedule_date BETWEEN $2 AND $3
ORDER BY schedule_date;'
WHERE objoid = 'employee_schedules'::regclass;

-- Update forecast-related tables
UPDATE pg_description
SET description = 'API Contract: POST /api/v1/forecast/calculate
expects: {queue_id: UUID, date_from: YYYY-MM-DD, date_to: YYYY-MM-DD, algorithm?: string}
returns: {forecast_id: UUID, status: string, results?: array}

Helper Queries:
-- Create forecast request
INSERT INTO forecast_requests (queue_id, start_date, end_date, algorithm_type, status)
VALUES ($1, $2, $3, COALESCE($4, ''erlang_c''), ''processing'')
RETURNING id as forecast_id, status;

-- Get forecast results
SELECT 
    fr.id as forecast_id,
    fr.status,
    json_agg(
        json_build_object(
            ''date'', fd.forecast_date,
            ''hour'', fd.hour,
            ''volume'', fd.predicted_volume,
            ''aht'', fd.predicted_aht
        ) ORDER BY fd.forecast_date, fd.hour
    ) as results
FROM forecast_requests fr
JOIN forecast_data fd ON fr.id = fd.forecast_id
WHERE fr.id = $1
GROUP BY fr.id;'
WHERE objoid IN (
    SELECT oid FROM pg_class WHERE relname LIKE 'forecast%' AND relkind = 'r'
);

-- Update request workflow tables
UPDATE pg_description
SET description = 'API Contract: GET /api/v1/requests/{id}/workflow
returns: {request_id: UUID, current_state: string, available_actions: array, history: array}

Helper Queries:
-- Get workflow state
SELECT 
    r.id as request_id,
    r.status as current_state,
    array_agg(DISTINCT wa.action_name) as available_actions
FROM employee_requests r
LEFT JOIN workflow_actions wa ON wa.from_state = r.status
WHERE r.id = $1
GROUP BY r.id;

-- Get workflow history
SELECT 
    request_id,
    from_state,
    to_state,
    action_taken,
    actor_id,
    timestamp
FROM workflow_history
WHERE request_id = $1
ORDER BY timestamp;'
WHERE objoid IN (
    SELECT oid FROM pg_class WHERE relname LIKE '%workflow%' AND relkind = 'r'
);

-- Add test data creation helpers
COMMENT ON TABLE employees IS
'API Contract: GET /api/v1/employees
returns: [{id: UUID, name: string, email: string, department: string}]

Helper Queries:
-- Get all active employees
SELECT 
    e.id::text as id,
    e.first_name || '' '' || e.last_name as name,
    e.email,
    d.name as department
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
WHERE e.is_active = true
ORDER BY e.last_name, e.first_name;

-- Get employee by ID
SELECT * FROM employees WHERE id = $1;

Test Data Available:
- Иван Иванов (id: ead4aaaf-5fcf-4661-aa08-cef7d9132b86)
- Петр Петров (id: 0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212)
- Мария Петрова (id: cf8194cb-1eae-48a9-8126-f502b0ac7707)';

-- Show tables with enhanced contracts
SELECT 
    c.relname as table_name,
    CASE 
        WHEN length(obj_description(c.oid, 'pg_class')) > 200 THEN 'Enhanced Contract ✅'
        WHEN obj_description(c.oid, 'pg_class') LIKE 'API Contract:%' THEN 'Basic Contract ⚡'
        ELSE 'No Contract ❌'
    END as contract_quality
FROM pg_class c
WHERE c.relkind = 'r'
    AND c.relname IN ('employees', 'employee_schedules', 'vacation_requests', 
                      'forecast_requests', 'employee_requests')
ORDER BY c.relname;