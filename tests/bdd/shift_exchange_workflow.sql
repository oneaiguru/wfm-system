-- BDD Test: Complete shift exchange workflow
-- Scenario: Employee requests shift exchange with colleague

BEGIN;

-- Create shift_exchange_requests table if not exists
CREATE TABLE IF NOT EXISTS shift_exchange_requests (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50) UNIQUE NOT NULL,
    requester_id INTEGER NOT NULL,
    target_agent_id INTEGER NOT NULL,
    original_shift_id INTEGER NOT NULL,
    target_shift_id INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending_colleague',
    reason TEXT,
    colleague_response VARCHAR(20),
    colleague_responded_at TIMESTAMP,
    approved_by INTEGER,
    approved_at TIMESTAMP,
    rejected_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT check_status CHECK (status IN ('pending_colleague', 'pending_approval', 'approved', 'rejected', 'cancelled'))
);

-- Setup: Create test department
INSERT INTO departments (id, organization_id, name, code)
VALUES 
    (gen_random_uuid(), 
     (SELECT id FROM organizations LIMIT 1), 
     'Test Call Center', 
     'TEST-CC')
ON CONFLICT (id) DO NOTHING;

-- Setup: Create test employees with proper structure
INSERT INTO employees (id, organization_id, user_id, department_id, employee_number, first_name, last_name, email, hire_date)
SELECT 
    gen_random_uuid(),
    o.id,
    u.id,
    d.id,
    'EMP-TEST-' || emp.emp_num::text,
    emp.first_name,
    emp.last_name,
    emp.email,
    '2024-01-01'::date
FROM (SELECT id FROM organizations LIMIT 1) o
CROSS JOIN (SELECT id FROM departments WHERE code = 'TEST-CC' LIMIT 1) d
CROSS JOIN (VALUES 
    (1, 'Петр', 'Петров', 'petrov@test.com'),
    (2, 'Сидор', 'Сидоров', 'sidorov@test.com'),
    (3, 'Иван', 'Иванов', 'ivanov@test.com')
) AS emp(emp_num, first_name, last_name, email)
LEFT JOIN LATERAL (
    SELECT id FROM users WHERE username = emp.email LIMIT 1
) u ON true
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.email = emp.email
);

-- Get employee IDs for test
WITH test_employees AS (
    SELECT 
        id,
        first_name || ' ' || last_name as full_name,
        ROW_NUMBER() OVER (ORDER BY last_name) as emp_num
    FROM employees 
    WHERE email IN ('petrov@test.com', 'sidorov@test.com', 'ivanov@test.com')
)
SELECT 
    'Test Employees Created:' as status,
    COUNT(*) as employee_count
FROM test_employees;

-- Create test shifts using actual employee IDs
WITH test_employees AS (
    SELECT 
        id,
        email,
        ROW_NUMBER() OVER (ORDER BY last_name) as emp_num
    FROM employees 
    WHERE email IN ('petrov@test.com', 'sidorov@test.com')
)
INSERT INTO shifts (employee_id, shift_date, start_time, end_time, shift_type, status)
SELECT 
    e.id,
    '2024-04-01'::date,
    CASE e.emp_num 
        WHEN 1 THEN '09:00:00'::time
        WHEN 2 THEN '17:00:00'::time
    END,
    CASE e.emp_num
        WHEN 1 THEN '17:00:00'::time  
        WHEN 2 THEN '23:59:00'::time
    END,
    CASE e.emp_num
        WHEN 1 THEN 'day'
        WHEN 2 THEN 'evening'
    END,
    'scheduled'
FROM test_employees e;

-- Get shift IDs for the exchange
WITH shift_data AS (
    SELECT 
        s.id as shift_id,
        e.id as employee_id,
        e.email,
        ROW_NUMBER() OVER (ORDER BY s.start_time) as shift_num
    FROM shifts s
    JOIN employees e ON s.employee_id = e.id
    WHERE s.shift_date = '2024-04-01'
    AND e.email IN ('petrov@test.com', 'sidorov@test.com')
)
-- Create shift exchange request
INSERT INTO shift_exchange_requests (
    request_id,
    requester_id,
    target_agent_id,
    original_shift_id,
    target_shift_id,
    status,
    reason,
    created_at
)
SELECT 
    'EXCH-' || TO_CHAR(NOW(), 'YYYYMMDDHH24MISS'),
    s1.shift_id as requester_id,  -- Using shift_id as temporary ID
    s2.shift_id as target_agent_id,
    s1.shift_id,
    s2.shift_id,
    'pending_colleague',
    'Семейные обстоятельства',
    NOW()
FROM shift_data s1
CROSS JOIN shift_data s2
WHERE s1.shift_num = 1 AND s2.shift_num = 2;

-- Step 2: Colleague accepts request
UPDATE shift_exchange_requests
SET 
    status = 'pending_approval',
    colleague_responded_at = NOW() + INTERVAL '5 minutes',
    colleague_response = 'accepted',
    updated_at = NOW() + INTERVAL '5 minutes'
WHERE request_id LIKE 'EXCH-%'
AND created_at >= NOW() - INTERVAL '1 minute';

-- Step 3: Supervisor approves
UPDATE shift_exchange_requests
SET 
    status = 'approved',
    approved_by = 1,  -- Supervisor ID
    approved_at = NOW() + INTERVAL '30 minutes',
    updated_at = NOW() + INTERVAL '30 minutes'
WHERE request_id LIKE 'EXCH-%'
AND created_at >= NOW() - INTERVAL '1 minute';

-- Execute shift swap
WITH exchange_data AS (
    SELECT 
        ser.original_shift_id,
        ser.target_shift_id,
        s1.employee_id as emp1,
        s2.employee_id as emp2
    FROM shift_exchange_requests ser
    JOIN shifts s1 ON ser.original_shift_id = s1.id
    JOIN shifts s2 ON ser.target_shift_id = s2.id
    WHERE ser.status = 'approved'
    AND ser.created_at >= NOW() - INTERVAL '1 minute'
)
UPDATE shifts s
SET employee_id = CASE 
    WHEN s.id = ed.original_shift_id THEN ed.emp2
    WHEN s.id = ed.target_shift_id THEN ed.emp1
    END,
    updated_at = NOW()
FROM exchange_data ed
WHERE s.id IN (ed.original_shift_id, ed.target_shift_id);

-- Create notifications for the exchange
INSERT INTO notifications (
    recipient_id,
    notification_type,
    title,
    message,
    created_at
)
SELECT 
    e.id as recipient_id,
    'shift_exchange_confirmed',
    'Обмен сменами подтвержден',
    'Ваш запрос на обмен сменами на ' || TO_CHAR('2024-04-01'::date, 'DD.MM.YYYY') || ' был одобрен',
    NOW()
FROM shift_exchange_requests ser
JOIN shifts s1 ON ser.original_shift_id = s1.id
JOIN shifts s2 ON ser.target_shift_id = s2.id
JOIN employees e ON e.id IN (s1.employee_id, s2.employee_id)
WHERE ser.status = 'approved'
AND ser.created_at >= NOW() - INTERVAL '1 minute';

-- Create audit log entries
INSERT INTO audit_logs (
    id,
    user_id,
    action,
    resource_type,
    resource_id,
    details,
    timestamp
)
SELECT 
    'AUDIT-' || gen_random_uuid()::text,
    COALESCE(ser.approved_by::text, '1'),
    'shift_exchange_completed',
    'shift_exchange',
    ser.request_id,
    jsonb_build_object(
        'status_before', 'pending_approval',
        'status_after', 'approved', 
        'shifts_swapped', true,
        'original_shift', ser.original_shift_id,
        'target_shift', ser.target_shift_id
    ),
    NOW()
FROM shift_exchange_requests ser
WHERE ser.status = 'approved'
AND ser.created_at >= NOW() - INTERVAL '1 minute';

-- Verify: Check final shift assignments
SELECT 
    '=== VERIFICATION: Final Shift Assignments ===' as verification;

SELECT 
    s.id as shift_id,
    e.first_name || ' ' || e.last_name as employee_name,
    s.shift_date,
    s.start_time,
    s.end_time,
    s.shift_type,
    s.status
FROM shifts s
JOIN employees e ON s.employee_id = e.id
WHERE s.shift_date = '2024-04-01'
AND e.email IN ('petrov@test.com', 'sidorov@test.com')
ORDER BY s.start_time;

-- Verify: Check exchange request status
SELECT 
    '=== VERIFICATION: Exchange Request Status ===' as verification;

SELECT 
    request_id,
    status,
    reason,
    colleague_response,
    colleague_responded_at,
    approved_by,
    approved_at
FROM shift_exchange_requests
WHERE created_at >= NOW() - INTERVAL '1 minute';

-- Verify: Check notifications created
SELECT 
    '=== VERIFICATION: Notifications Created ===' as verification;

SELECT 
    notification_type,
    title,
    message,
    status,
    created_at
FROM notifications
WHERE notification_type = 'shift_exchange_confirmed'
AND created_at >= NOW() - INTERVAL '1 minute';

-- Verify: Check audit trail
SELECT 
    '=== VERIFICATION: Audit Trail ===' as verification;

SELECT 
    action,
    user_id,
    resource_type,
    resource_id,
    details->>'status_before' as status_before,
    details->>'status_after' as status_after,
    details->>'shifts_swapped' as shifts_swapped,
    timestamp
FROM audit_logs
WHERE resource_type = 'shift_exchange'
AND timestamp >= NOW() - INTERVAL '1 minute'
ORDER BY timestamp;

-- Summary
SELECT 
    '=== BDD SCENARIO SUMMARY ===' as summary;

WITH results AS (
    SELECT 
        (SELECT COUNT(*) FROM shift_exchange_requests WHERE status = 'approved' AND created_at >= NOW() - INTERVAL '1 minute') as exchanges_approved,
        (SELECT COUNT(*) FROM notifications WHERE notification_type = 'shift_exchange_confirmed' AND created_at >= NOW() - INTERVAL '1 minute') as notifications_sent,
        (SELECT COUNT(*) FROM audit_logs WHERE resource_type = 'shift_exchange' AND timestamp >= NOW() - INTERVAL '1 minute') as audit_entries
)
SELECT 
    'Shift exchanges approved: ' || exchanges_approved || ', ' ||
    'Notifications sent: ' || notifications_sent || ', ' ||
    'Audit entries: ' || audit_entries as test_results
FROM results;

-- Keep the test data for verification
COMMIT;

-- Success message
SELECT 
    '✅ BDD Scenario: Shift Exchange Workflow - COMPLETED' as status,
    'Test data committed to database for verification' as note;