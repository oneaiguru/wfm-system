-- DATABASE-OPUS Archive Analysis
-- Categorizes all tables for archival per ARCHIVE_INNOVATION_DIRECTIVE.md

WITH table_categories AS (
    SELECT 
        relname as table_name,
        n_live_tup as row_count,
        CASE 
            -- Advanced/Experimental Features to Archive
            WHEN relname LIKE '%ml_%' THEN 'ARCHIVE: ML/AI Advanced'
            WHEN relname LIKE '%ai_%' THEN 'ARCHIVE: ML/AI Advanced'
            WHEN relname LIKE '%quantum%' THEN 'ARCHIVE: Quantum Computing'
            WHEN relname LIKE '%blockchain%' THEN 'ARCHIVE: Blockchain'
            WHEN relname LIKE '%experimental%' THEN 'ARCHIVE: Experimental'
            WHEN relname LIKE '%advanced_%' THEN 'ARCHIVE: Advanced Features'
            WHEN relname LIKE '%performance_%' AND relname NOT IN ('performance_metrics', 'performance_reports') THEN 'ARCHIVE: Advanced Performance'
            WHEN relname LIKE '%analytics%' AND relname NOT LIKE '%report%' THEN 'ARCHIVE: Advanced Analytics'
            WHEN relname LIKE '%cache%' THEN 'ARCHIVE: Caching Layer'
            WHEN relname LIKE '%oauth%' THEN 'ARCHIVE: OAuth (if not in BDD)'
            WHEN relname LIKE '%saml%' THEN 'ARCHIVE: SAML (if not in BDD)'
            WHEN relname LIKE '%ab_test%' THEN 'ARCHIVE: A/B Testing'
            
            -- Core BDD Features to Keep
            WHEN relname IN ('employees', 'departments', 'organizations', 'positions', 'roles') THEN 'KEEP: Core Organization'
            WHEN relname IN ('schedules', 'shifts', 'shift_templates', 'shift_patterns') THEN 'KEEP: Core Scheduling'
            WHEN relname IN ('employee_requests', 'request_types', 'request_approvals') THEN 'KEEP: Core Requests'
            WHEN relname IN ('forecasts', 'forecast_models', 'forecast_data') THEN 'KEEP: Core Forecasting'
            WHEN relname IN ('agents', 'agent_skills', 'skills', 'agent_activity') THEN 'KEEP: Core Agent Management'
            WHEN relname IN ('workflows', 'workflow_definitions', 'workflow_instances') THEN 'KEEP: Core Workflows'
            WHEN relname LIKE '%1c%' OR relname LIKE '%zup%' THEN 'KEEP: 1C ZUP Integration'
            WHEN relname LIKE '%vacation%' AND relname NOT LIKE '%advanced%' THEN 'KEEP: Vacation Management'
            WHEN relname LIKE '%production_calendar%' THEN 'KEEP: Production Calendar'
            
            -- Test Data
            WHEN relname LIKE 'bdd_%' THEN 'TEST: BDD Test Data'
            
            -- Mass Assignment (Check if in BDD)
            WHEN relname LIKE 'mass_assignment%' THEN 'CHECK: Mass Assignment (verify BDD)'
            
            -- Unmapped Tables
            ELSE 'UNMAPPED: Review Required'
        END as category,
        CASE 
            WHEN n_live_tup > 0 THEN 'Has Data'
            ELSE 'Empty'
        END as data_status
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
)
SELECT 
    category,
    COUNT(*) as table_count,
    COUNT(*) FILTER (WHERE data_status = 'Has Data') as with_data,
    COUNT(*) FILTER (WHERE data_status = 'Empty') as empty,
    STRING_AGG(
        table_name || ' (' || row_count || ')', 
        ', ' 
        ORDER BY row_count DESC
    ) FILTER (WHERE row_count > 0) as tables_with_data
FROM table_categories
GROUP BY category
ORDER BY 
    CASE 
        WHEN category LIKE 'ARCHIVE:%' THEN 1
        WHEN category LIKE 'KEEP:%' THEN 2
        WHEN category LIKE 'CHECK:%' THEN 3
        WHEN category LIKE 'TEST:%' THEN 4
        ELSE 5
    END,
    category;

-- Summary counts
WITH counts AS (
    SELECT 
        COUNT(*) FILTER (WHERE relname LIKE '%ml_%' OR relname LIKE '%ai_%' OR relname LIKE '%advanced_%' OR relname LIKE '%experimental%' OR relname LIKE '%quantum%' OR relname LIKE '%blockchain%' OR relname LIKE '%performance_%' OR relname LIKE '%analytics%' OR relname LIKE '%cache%' OR relname LIKE '%oauth%' OR relname LIKE '%saml%' OR relname LIKE '%ab_test%') as to_archive,
        COUNT(*) as total_tables
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
)
SELECT 
    'ARCHIVE SUMMARY' as category,
    to_archive as tables_to_archive,
    total_tables - to_archive as tables_to_keep,
    total_tables,
    ROUND(100.0 * to_archive / total_tables, 1) as archive_percentage
FROM counts;