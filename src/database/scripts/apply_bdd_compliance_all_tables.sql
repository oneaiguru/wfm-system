-- Automated BDD Compliance Script for All Tables
-- This script generates API contract templates for all tables

-- Function to generate API contract for a table
CREATE OR REPLACE FUNCTION generate_api_contract(p_table_name TEXT)
RETURNS TEXT AS $$
DECLARE
    v_columns TEXT;
    v_primary_key TEXT;
    v_foreign_keys TEXT;
    v_contract TEXT;
BEGIN
    -- Get primary key column
    SELECT a.attname INTO v_primary_key
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = p_table_name::regclass AND i.indisprimary;
    
    -- Get column list for SELECT
    SELECT string_agg(
        CASE 
            WHEN data_type = 'uuid' THEN column_name || '::text as ' || column_name
            ELSE column_name
        END, ', ' ORDER BY ordinal_position
    ) INTO v_columns
    FROM information_schema.columns
    WHERE table_name = p_table_name
    AND table_schema = 'public';
    
    -- Generate contract based on table name patterns
    v_contract := 'API Contract: ';
    
    -- Determine endpoint based on table name
    IF p_table_name LIKE '%request%' THEN
        v_contract := v_contract || 'POST /api/v1/' || regexp_replace(p_table_name, '_', '-', 'g') || E'\n';
        v_contract := v_contract || 'expects: {employee_id: UUID, ...}' || E'\n';
        v_contract := v_contract || 'returns: {id: UUID, status: string}' || E'\n\n';
        v_contract := v_contract || 'Helper Queries:' || E'\n';
        v_contract := v_contract || '-- Create ' || p_table_name || E'\n';
        v_contract := v_contract || 'INSERT INTO ' || p_table_name || ' (...) VALUES (...) RETURNING id, status;' || E'\n\n';
        v_contract := v_contract || '-- Get with details' || E'\n';
        v_contract := v_contract || 'SELECT ' || v_columns || ' FROM ' || p_table_name || ' WHERE ' || COALESCE(v_primary_key, 'id') || ' = $1;';
    ELSE
        v_contract := v_contract || 'GET /api/v1/' || regexp_replace(p_table_name, '_', '-', 'g') || E'\n';
        v_contract := v_contract || 'returns: [{' || COALESCE(v_primary_key, 'id') || ': UUID, ...}]' || E'\n\n';
        v_contract := v_contract || 'Helper Queries:' || E'\n';
        v_contract := v_contract || '-- Get all ' || p_table_name || E'\n';
        v_contract := v_contract || 'SELECT ' || v_columns || ' FROM ' || p_table_name || ' ORDER BY ' || COALESCE(v_primary_key, 'id') || ';';
    END IF;
    
    RETURN v_contract;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables that don't have API contracts yet
DO $$
DECLARE
    r RECORD;
    v_contract TEXT;
    v_count INTEGER := 0;
BEGIN
    FOR r IN 
        SELECT c.relname as table_name
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r' 
        AND n.nspname = 'public'
        AND c.relname NOT IN ('schema_versions', 'api_contracts', 'integration_test_data', 
                              'contract_validations', 'agent_dependencies', 'integration_health_metrics')
        AND (obj_description(c.oid, 'pg_class') IS NULL 
             OR obj_description(c.oid, 'pg_class') NOT LIKE 'API Contract:%')
        ORDER BY c.relname
        LIMIT 20  -- Process 20 at a time
    LOOP
        v_contract := generate_api_contract(r.table_name);
        EXECUTE format('COMMENT ON TABLE %I IS %L', r.table_name, v_contract);
        v_count := v_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Applied API contracts to % tables', v_count;
END $$;

-- Show progress
SELECT 
    COUNT(*) FILTER (WHERE obj_description(c.oid, 'pg_class') LIKE 'API Contract:%') as documented,
    COUNT(*) FILTER (WHERE obj_description(c.oid, 'pg_class') IS NULL 
                       OR obj_description(c.oid, 'pg_class') NOT LIKE 'API Contract:%') as remaining,
    COUNT(*) as total,
    ROUND(COUNT(*) FILTER (WHERE obj_description(c.oid, 'pg_class') LIKE 'API Contract:%')::numeric / COUNT(*) * 100, 1) as percent_complete
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public';