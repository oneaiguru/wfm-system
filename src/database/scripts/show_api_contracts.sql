-- Script to show API contracts for other agents
-- Run this to see what API expects from database

\echo '======================================'
\echo 'API CONTRACTS FOR INTEGRATION-OPUS'
\echo '======================================'
\echo ''

-- Show all current API contracts with examples
SELECT 
    endpoint_path,
    http_method,
    jsonb_pretty(request_schema) as request_format,
    jsonb_pretty(example_request) as example_request
FROM api_contracts
ORDER BY endpoint_path, http_method;

\echo ''
\echo '======================================'
\echo 'TEST DATA FOR INTEGRATION TESTING'
\echo '======================================'
\echo ''

-- Show available test data
SELECT 
    table_name,
    test_scenario,
    jsonb_pretty(test_data) as test_record,
    bdd_scenario_reference
FROM integration_test_data
WHERE is_active = true
ORDER BY table_name, test_scenario;

\echo ''
\echo '======================================'
\echo 'COMMON INTEGRATION MISTAKES TO AVOID'
\echo '======================================'
\echo ''

SELECT * FROM (VALUES 
    ('UUID vs Integer', 'employee_id must be UUID, not integer!', 'vacation_requests.employee_id'),
    ('Date Format', 'Use YYYY-MM-DD format for dates', 'start_date, end_date'),
    ('Russian Text', 'Ensure UTF-8 encoding for Russian names', 'first_name, last_name'),
    ('Status Values', 'Use: pending, approved, rejected, cancelled', 'vacation_requests.status'),
    ('Request Types', 'Use Russian types: отпуск, больничный, отгул', 'vacation_requests.request_type')
) AS mistakes(issue, description, affected_fields);

\echo ''
\echo '======================================'
\echo 'SAMPLE QUERIES FOR API ENDPOINTS'
\echo '======================================'
\echo ''

\echo 'For GET /api/v1/employees:'
\echo '------------------------'
SELECT 
    id::text as id,
    first_name || ' ' || last_name as name,
    email
FROM employees
WHERE first_name ~ '[А-Яа-я]'  -- Russian names
LIMIT 3;

\echo ''
\echo 'For POST /api/v1/requests/vacation validation:'
\echo '--------------------------------------------'
SELECT 
    'Employee exists check:' as query_purpose,
    EXISTS(SELECT 1 FROM employees WHERE id = 'ead4aaaf-5fcf-4661-aa08-cef7d9132b86'::uuid) as result;

\echo ''
\echo 'For vacation request creation:'
\echo '-----------------------------'
\echo 'INSERT INTO vacation_requests (employee_id, start_date, end_date, status, request_type)'
\echo 'VALUES ($1::uuid, $2::date, $3::date, ''pending'', ''отпуск'')'
\echo 'RETURNING id, status;'