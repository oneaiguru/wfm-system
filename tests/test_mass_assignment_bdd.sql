-- Test Script for Mass Assignment Operations (BDD 32)
-- Comprehensive testing of all BDD scenarios
-- Tests filtering, validation, assignment execution, and audit trails

-- Clean existing test data
TRUNCATE mass_assignment_jobs CASCADE;
TRUNCATE mass_assignment_employee_preview CASCADE;

-- Test Scenario 1: Mass business rules assignment with filtering
-- BDD: "Given I navigate to mass assignment page When I select 'Business Rules' assignment type"
BEGIN;

INSERT INTO mass_assignment_jobs (job_name, assignment_type, created_by, status, filter_criteria, assignment_parameters)
VALUES (
    'Test Business Rules Assignment', 
    'business_rules', 
    'admin@test.com', 
    'created',
    '{"department": ["Customer Service"], "employee_type": ["Office"], "status": ["Active"]}'::jsonb,
    '{"rule_name": "Standard Lunch Break", "override_existing": false}'::jsonb
);

-- Get the job ID for testing
\set job_id `psql -U postgres -d postgres -t -c "SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1;"`

-- Test employee filtering and preview generation
SELECT 'Testing Employee Filtering and Preview Generation...' as test_step;

SELECT generate_employee_preview(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1),
    '{"department": ["Customer Service"], "employee_type": ["Office"], "status": ["Active"]}'::jsonb
);

-- Verify preview was created
SELECT 
    'Employee Preview Results:' as description,
    COUNT(*) as total_employees,
    COUNT(*) FILTER (WHERE assignment_preview_status = 'will_apply') as will_apply,
    COUNT(*) FILTER (WHERE assignment_preview_status = 'will_override') as will_override,
    COUNT(*) FILTER (WHERE assignment_preview_status = 'conflict') as conflicts
FROM mass_assignment_employee_preview 
WHERE job_id = (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1);

-- Test assignment execution
SELECT 'Testing Assignment Execution...' as test_step;

SELECT * FROM execute_mass_assignment(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1)
);

-- Verify job completion status
SELECT 
    job_name,
    status,
    total_employees,
    processed_employees,
    successful_assignments,
    failed_assignments,
    CASE WHEN completed_at IS NOT NULL THEN 'COMPLETED' ELSE 'PENDING' END as completion_status
FROM mass_assignment_jobs 
WHERE job_name = 'Test Business Rules Assignment';

-- Verify audit trail was created
SELECT 
    event_type,
    affected_employees,
    performed_by,
    event_details
FROM mass_assignment_audit 
WHERE job_id = (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1);

-- Verify business rule assignments were logged
SELECT 
    COUNT(*) as assignments_logged,
    assignment_result,
    rule_name
FROM mass_business_rule_assignments 
WHERE job_id = (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Business Rules Assignment' LIMIT 1)
GROUP BY assignment_result, rule_name;

COMMIT;

-- Test Scenario 2: Mass vacation schemes assignment with validation
-- BDD: "When I select 'Vacation Schemes' assignment type"
BEGIN;

INSERT INTO mass_assignment_jobs (job_name, assignment_type, created_by, status, filter_criteria, assignment_parameters)
VALUES (
    'Test Vacation Schemes Assignment', 
    'vacation_schemes', 
    'hr@test.com', 
    'created',
    '{"segment": ["Senior"], "status": ["Active"]}'::jsonb,
    '{"scheme_name": "Standard Annual Leave", "min_days_between": 30, "allow_multiple": true}'::jsonb
);

-- Generate preview and execute
SELECT generate_employee_preview(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Vacation Schemes Assignment' LIMIT 1),
    '{"segment": ["Senior"], "status": ["Active"]}'::jsonb
);

SELECT * FROM execute_mass_assignment(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Vacation Schemes Assignment' LIMIT 1)
);

-- Verify vacation scheme assignments
SELECT 
    COUNT(*) as vacation_assignments,
    scheme_name,
    assignment_result
FROM mass_vacation_scheme_assignments 
WHERE job_id = (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Vacation Schemes Assignment' LIMIT 1)
GROUP BY scheme_name, assignment_result;

COMMIT;

-- Test Scenario 3: Mass work hours assignment for reporting periods
-- BDD: "When I select 'Work Hours' assignment type"
BEGIN;

INSERT INTO mass_assignment_jobs (job_name, assignment_type, created_by, status, filter_criteria, assignment_parameters)
VALUES (
    'Test Work Hours Assignment', 
    'work_hours', 
    'planning@test.com', 
    'created',
    '{"department": ["Call Center"], "status": ["Active"]}'::jsonb,
    '{"period": "2024-Q1", "monthly_hours": {"2024-01": 168, "2024-02": 160, "2024-03": 176}}'::jsonb
);

-- Generate preview and execute
SELECT generate_employee_preview(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Work Hours Assignment' LIMIT 1),
    '{"department": ["Call Center"], "status": ["Active"]}'::jsonb
);

SELECT * FROM execute_mass_assignment(
    (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Work Hours Assignment' LIMIT 1)
);

-- Verify work hours assignments
SELECT 
    COUNT(*) as work_hour_assignments,
    assignment_period,
    total_hours,
    assignment_result
FROM mass_work_hours_assignments 
WHERE job_id = (SELECT job_id FROM mass_assignment_jobs WHERE job_name = 'Test Work Hours Assignment' LIMIT 1)
GROUP BY assignment_period, total_hours, assignment_result;

COMMIT;

-- Test Scenario 4: Employee list filtering
-- BDD: "When I access employee filtering interface"
SELECT 'Testing Employee Filtering Options...' as test_step;

-- Test available filter definitions
SELECT 
    filter_name,
    display_name,
    display_name_ru,
    parameter_type,
    available_values
FROM employee_filter_definitions 
WHERE is_active = true
ORDER BY display_order;

-- Test search functionality
INSERT INTO employee_search_configuration (search_type, search_term, search_operator, match_count)
VALUES 
    ('surname', 'Smith', 'like', 2),
    ('personnel_number', '12345', 'equals', 1),
    ('department', 'Customer Service', 'equals', 25);

-- Verify search configurations
SELECT 
    search_type,
    search_term,
    search_operator,
    match_count
FROM employee_search_configuration
ORDER BY last_used DESC;

-- Test Scenario 5: Template usage and reusability
-- BDD: Testing assignment templates for efficiency
SELECT 'Testing Assignment Templates...' as test_step;

-- Verify available templates
SELECT 
    template_name,
    template_name_ru,
    assignment_type,
    template_description,
    filter_configuration,
    assignment_configuration
FROM mass_assignment_templates 
WHERE is_active = true;

-- Test template usage (simulate using a template)
UPDATE mass_assignment_templates 
SET usage_count = usage_count + 1,
    last_used_at = CURRENT_TIMESTAMP
WHERE template_name = 'Standard Office Workers - Business Rules';

-- Test validation rules
SELECT 'Testing Validation Rules...' as test_step;

-- Verify validation rules are properly configured
SELECT 
    rule_name,
    assignment_type,
    validation_category,
    error_message,
    error_message_ru,
    severity,
    is_blocking
FROM mass_assignment_validation_rules 
WHERE is_active = true
ORDER BY assignment_type, priority;

-- Test validation compatibility function
SELECT 
    'business_rules' as assignment_type,
    is_valid,
    validation_errors,
    requires_override
FROM validate_assignment_compatibility(
    'business_rules', 
    uuid_generate_v4(), 
    '{"rule_id": "test-rule", "rule_type": "lunch_break"}'::jsonb
);

-- Performance test: Check query performance on indexed tables
SELECT 'Testing Query Performance...' as test_step;

EXPLAIN (ANALYZE, BUFFERS) 
SELECT COUNT(*) 
FROM mass_assignment_jobs j
JOIN mass_assignment_employee_preview p ON j.job_id = p.job_id
WHERE j.assignment_type = 'business_rules'
AND j.status = 'completed';

-- Summary of test results
SELECT 'TEST SUMMARY' as section, '==================' as separator;

SELECT 
    'Jobs Created' as metric,
    COUNT(*) as value
FROM mass_assignment_jobs;

SELECT 
    'Employee Previews Generated' as metric,
    COUNT(*) as value
FROM mass_assignment_employee_preview;

SELECT 
    'Business Rule Assignments' as metric,
    COUNT(*) as value
FROM mass_business_rule_assignments;

SELECT 
    'Vacation Scheme Assignments' as metric,
    COUNT(*) as value
FROM mass_vacation_scheme_assignments;

SELECT 
    'Work Hours Assignments' as metric,
    COUNT(*) as value
FROM mass_work_hours_assignments;

SELECT 
    'Audit Events Logged' as metric,
    COUNT(*) as value
FROM mass_assignment_audit;

SELECT 
    'Filter Definitions Available' as metric,
    COUNT(*) as value
FROM employee_filter_definitions WHERE is_active = true;

SELECT 
    'Templates Available' as metric,
    COUNT(*) as value
FROM mass_assignment_templates WHERE is_active = true;

SELECT 
    'Validation Rules Active' as metric,
    COUNT(*) as value
FROM mass_assignment_validation_rules WHERE is_active = true;

-- Verify all BDD scenarios pass
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM mass_assignment_jobs WHERE status = 'completed') 
        THEN '✓ PASS: Mass assignment execution works'
        ELSE '✗ FAIL: Mass assignment execution failed'
    END as bdd_scenario_1;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM mass_assignment_employee_preview) 
        THEN '✓ PASS: Employee filtering and preview generation works'
        ELSE '✗ FAIL: Employee filtering failed'
    END as bdd_scenario_2;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM mass_assignment_audit WHERE event_type = 'assignment_executed') 
        THEN '✓ PASS: Audit trail logging works'
        ELSE '✗ FAIL: Audit trail logging failed'
    END as bdd_scenario_3;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM employee_filter_definitions WHERE is_active = true) >= 6
        THEN '✓ PASS: Employee filtering options complete'
        ELSE '✗ FAIL: Employee filtering options incomplete'
    END as bdd_scenario_4;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM mass_assignment_templates WHERE is_active = true) >= 3
        THEN '✓ PASS: Assignment templates available'
        ELSE '✗ FAIL: Assignment templates missing'
    END as bdd_scenario_5;

SELECT 'Mass Assignment Operations BDD Testing Complete!' as final_result;