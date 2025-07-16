-- DATABASE-OPUS Phase 2 Verification Queries
-- Purpose: Expose mock data patterns and verify operational readiness

-- ============================================
-- TEST 1: Employee Data Reality Check
-- ============================================
SELECT 'TEST 1: Employee Data Patterns' as test_name;

WITH employee_analysis AS (
    SELECT 
        COUNT(*) as total_employees,
        COUNT(CASE WHEN email LIKE '%@company.com' THEN 1 END) as generic_emails,
        COUNT(CASE WHEN email LIKE '%test%' OR email LIKE '%demo%' THEN 1 END) as test_emails,
        COUNT(CASE WHEN first_name = 'Employee' THEN 1 END) as generic_first_names,
        COUNT(CASE WHEN last_name LIKE 'CS%' THEN 1 END) as cs_pattern_names,
        COUNT(CASE WHEN first_name ~ '[А-Яа-я]' OR last_name ~ '[А-Яа-я]' THEN 1 END) as russian_names
    FROM employees
)
SELECT 
    total_employees,
    generic_emails,
    test_emails,
    generic_first_names,
    cs_pattern_names,
    russian_names,
    CASE 
        WHEN generic_emails = total_employees THEN 'ALL MOCK DATA'
        WHEN generic_emails > total_employees * 0.8 THEN 'MOSTLY MOCK DATA'
        ELSE 'MIXED DATA'
    END as verdict
FROM employee_analysis;

-- Sample employee data
SELECT 'Sample Employees:' as info;
SELECT id, first_name, last_name, email 
FROM employees 
ORDER BY id 
LIMIT 5;

-- ============================================
-- TEST 2: Workflow Data Flow Check
-- ============================================
SELECT 'TEST 2: Workflow Data Flow' as test_name;

SELECT 
    'Employee Requests Flow' as workflow,
    (SELECT COUNT(*) FROM employees) as employees,
    (SELECT COUNT(*) FROM employee_requests) as requests,
    (SELECT COUNT(*) FROM request_approvals) as approvals,
    (SELECT COUNT(*) FROM approval_history) as history,
    CASE 
        WHEN (SELECT COUNT(*) FROM employee_requests) = 0 THEN 'NO WORKFLOW DATA'
        ELSE 'HAS WORKFLOW DATA'
    END as status;

-- ============================================
-- TEST 3: Schedule Management Reality
-- ============================================
SELECT 'TEST 3: Schedule Management' as test_name;

SELECT 
    'Scheduling System' as system,
    (SELECT COUNT(*) FROM schedules) as schedules,
    (SELECT COUNT(*) FROM schedules WHERE schedule_date >= CURRENT_DATE) as future_schedules,
    (SELECT COUNT(*) FROM schedules WHERE schedule_date < CURRENT_DATE - INTERVAL '30 days') as old_schedules,
    (SELECT COUNT(DISTINCT employee_id) FROM schedules) as scheduled_employees;

-- ============================================
-- TEST 4: Real-time Monitoring Status
-- ============================================
SELECT 'TEST 4: Real-time Monitoring' as test_name;

SELECT 
    table_name,
    record_count,
    last_update,
    age_hours,
    CASE 
        WHEN record_count = 0 THEN 'EMPTY'
        WHEN age_hours IS NULL THEN 'NO TIMESTAMPS'
        WHEN age_hours < 1 THEN 'ACTIVE'
        WHEN age_hours < 24 THEN 'RECENT'
        ELSE 'STALE'
    END as data_freshness
FROM (
    SELECT 
        'agent_current_status' as table_name,
        COUNT(*) as record_count,
        MAX(last_heartbeat) as last_update,
        EXTRACT(EPOCH FROM (NOW() - MAX(last_heartbeat)))/3600 as age_hours
    FROM agent_current_status
    
    UNION ALL
    
    SELECT 
        'queue_metrics',
        COUNT(*),
        MAX(timestamp),
        EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/3600
    FROM queue_metrics
) monitoring_data;

-- ============================================
-- TEST 5: Performance Data Patterns
-- ============================================
SELECT 'TEST 5: Performance Data Analysis' as test_name;

WITH perf_analysis AS (
    SELECT 
        data_source,
        source_system,
        COUNT(*) as records,
        COUNT(DISTINCT metric_value) as unique_values,
        MIN(metric_value) as min_value,
        MAX(metric_value) as max_value,
        STDDEV(metric_value) as std_deviation
    FROM performance_realtime_data
    GROUP BY data_source, source_system
)
SELECT 
    *,
    CASE 
        WHEN unique_values < records * 0.5 THEN 'LOW VARIANCE - LIKELY MOCK'
        WHEN std_deviation < 10 THEN 'ARTIFICIAL PATTERN'
        ELSE 'REALISTIC VARIANCE'
    END as data_quality
FROM perf_analysis
ORDER BY records DESC;

-- ============================================
-- TEST 6: Foreign Key Integrity
-- ============================================
SELECT 'TEST 6: Foreign Key Relationships' as test_name;

-- Check orphaned records
SELECT 
    'employee_requests without valid employee' as check_type,
    COUNT(*) as orphaned_records
FROM employee_requests er
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.id = er.employee_id)

UNION ALL

SELECT 
    'request_approvals without valid request',
    COUNT(*)
FROM request_approvals ra
WHERE NOT EXISTS (SELECT 1 FROM employee_requests er WHERE er.id = ra.request_id);

-- ============================================
-- TEST 7: Business Rule Implementation
-- ============================================
SELECT 'TEST 7: Business Rules' as test_name;

SELECT 
    COUNT(*) as total_rules,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_rules,
    COUNT(CASE WHEN rule_definition IS NOT NULL THEN 1 END) as defined_rules,
    COUNT(CASE WHEN rule_definition::text LIKE '%mock%' THEN 1 END) as mock_rules,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as rules_with_creator
FROM business_rules;

-- ============================================
-- TEST 8: Data Volume Analysis
-- ============================================
SELECT 'TEST 8: Data Volume by Module' as test_name;

WITH module_volumes AS (
    SELECT 'Employee Management' as module, COUNT(*) as tables, SUM(n_live_tup) as total_records
    FROM pg_stat_user_tables
    WHERE relname LIKE 'employee%' OR relname LIKE 'approval%'
    
    UNION ALL
    
    SELECT 'Scheduling', COUNT(*), SUM(n_live_tup)
    FROM pg_stat_user_tables
    WHERE relname LIKE 'schedule%' OR relname LIKE 'shift%'
    
    UNION ALL
    
    SELECT 'Performance Analytics', COUNT(*), SUM(n_live_tup)
    FROM pg_stat_user_tables
    WHERE relname LIKE 'performance%'
    
    UNION ALL
    
    SELECT 'Real-time Monitoring', COUNT(*), SUM(n_live_tup)
    FROM pg_stat_user_tables
    WHERE relname LIKE 'agent_%' OR relname LIKE 'queue_%'
)
SELECT 
    module,
    tables,
    COALESCE(total_records, 0) as total_records,
    CASE 
        WHEN COALESCE(total_records, 0) = 0 THEN 'NO DATA'
        WHEN total_records < 100 THEN 'MINIMAL DATA'
        WHEN total_records < 1000 THEN 'LOW VOLUME'
        ELSE 'OPERATIONAL VOLUME'
    END as data_status
FROM module_volumes
ORDER BY total_records DESC;

-- ============================================
-- TEST 9: Integration Points
-- ============================================
SELECT 'TEST 9: Integration Status' as test_name;

-- Check for 1C ZUP integration data
SELECT 
    'zup_integration_stub' as integration,
    COUNT(*) as records,
    COUNT(CASE WHEN integration_data::text LIKE '%mock%' THEN 1 END) as mock_records
FROM zup_integration_stub

UNION ALL

-- Check for external system references
SELECT 
    'external_system_mappings',
    COUNT(*),
    COUNT(CASE WHEN external_system_name LIKE '%test%' THEN 1 END)
FROM external_system_mappings;

-- ============================================
-- TEST 10: Summary Verdict
-- ============================================
SELECT 'TEST 10: Overall Database Status' as test_name;

WITH status_summary AS (
    SELECT 
        (SELECT COUNT(*) FROM employees WHERE email NOT LIKE '%@company.com') as real_employees,
        (SELECT COUNT(*) FROM employee_requests) as total_requests,
        (SELECT COUNT(*) FROM schedules WHERE schedule_date >= CURRENT_DATE) as active_schedules,
        (SELECT COUNT(*) FROM agent_current_status WHERE last_heartbeat > NOW() - INTERVAL '1 hour') as active_agents,
        (SELECT COUNT(DISTINCT table_name) FROM information_schema.tables WHERE table_schema = 'public') as total_tables
)
SELECT 
    total_tables,
    real_employees,
    total_requests,
    active_schedules,
    active_agents,
    CASE 
        WHEN real_employees = 0 AND total_requests = 0 AND active_schedules = 0 AND active_agents = 0 
        THEN 'PURE MOCK ENVIRONMENT - NO OPERATIONAL DATA'
        WHEN real_employees > 0 OR active_agents > 0
        THEN 'MIXED ENVIRONMENT - SOME REAL DATA'
        ELSE 'UNKNOWN STATUS'
    END as database_verdict
FROM status_summary;