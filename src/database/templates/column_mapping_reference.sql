-- =====================================================================================
-- Argus to WFM Database Column Mapping Reference
-- Created for: DATABASE-OPUS Agent
-- Purpose: Comprehensive mapping guide for Argus Excel columns to WFM database schema
-- Reference: BDD Specification Table 1 and multi-skill planning schema
-- =====================================================================================

-- =====================================================================================
-- ARGUS EXCEL FORMAT SPECIFICATION (From BDD Table 1)
-- =====================================================================================

/*
Argus Excel Column Structure:
- Column A: Start time (DD.MM.YYYY HH:MM:SS) - Beginning of measurement interval
- Column B: Unique incoming - Count of unique calls received
- Column C: Non-unique incoming - Total calls including repeats (≥ Column B)
- Column D: Average talk time - Average conversation duration in seconds
- Column E: Post-processing - Average wrap-up/after-call work time in seconds
*/

-- =====================================================================================
-- PRIMARY TABLE MAPPINGS
-- =====================================================================================

-- 1. CONTACT_STATISTICS TABLE MAPPING
/*
Argus Column -> contact_statistics columns:

A (Start time)        -> interval_start_time (TIMESTAMPTZ)
                      -> interval_end_time (calculated: start + interval duration)
                      
B (Unique incoming)   -> received_calls (INTEGER)
                      -> treated_calls (INTEGER) - assumes all received are treated
                      
C (Non-unique)        -> not_unique_received (INTEGER)
                      -> not_unique_treated (INTEGER) - assumes all received are treated
                      
D (Talk time)         -> talk_time (INTEGER) - converted from seconds to milliseconds
                      -> Part of aht calculation
                      
E (Post-processing)   -> post_processing (INTEGER) - converted from seconds to milliseconds
                      -> Part of aht calculation

Calculated fields:
- aht = (talk_time + post_processing) - Average Handling Time in milliseconds
- miss_calls = 0 (not provided in Argus format)
- not_unique_missed = 0 (not provided in Argus format)
- service_level = 100.00 (assumed for imports, actual SL calculated separately)
- abandonment_rate = 0.00 (not provided in Argus format)
- occupancy_rate = (talk_time / interval_duration) * 100
*/

-- =====================================================================================
-- MAPPING FUNCTIONS
-- =====================================================================================

-- Function to demonstrate column mapping
CREATE OR REPLACE FUNCTION show_argus_mapping()
RETURNS TABLE (
    argus_column CHAR(1),
    argus_name TEXT,
    argus_type TEXT,
    argus_example TEXT,
    maps_to_table TEXT,
    maps_to_columns TEXT[],
    transformation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        -- Column A mapping
        ('A'::CHAR(1), 
         'Start time'::TEXT, 
         'DD.MM.YYYY HH:MM:SS'::TEXT,
         '01.01.2024 09:00:00'::TEXT,
         'contact_statistics'::TEXT,
         ARRAY['interval_start_time', 'interval_end_time']::TEXT[],
         'Parse date, round to interval boundary, calculate end time'::TEXT),
         
        -- Column B mapping
        ('B'::CHAR(1), 
         'Unique incoming'::TEXT, 
         'INTEGER'::TEXT,
         '10'::TEXT,
         'contact_statistics'::TEXT,
         ARRAY['received_calls', 'treated_calls']::TEXT[],
         'Direct copy (assumes all calls are treated)'::TEXT),
         
        -- Column C mapping
        ('C'::CHAR(1), 
         'Non-unique incoming'::TEXT, 
         'INTEGER (≥ B)'::TEXT,
         '15'::TEXT,
         'contact_statistics'::TEXT,
         ARRAY['not_unique_received', 'not_unique_treated']::TEXT[],
         'Direct copy (assumes all calls are treated)'::TEXT),
         
        -- Column D mapping
        ('D'::CHAR(1), 
         'Average talk time'::TEXT, 
         'SECONDS'::TEXT,
         '300'::TEXT,
         'contact_statistics'::TEXT,
         ARRAY['talk_time', 'aht (partial)']::TEXT[],
         'Multiply by 1000 to convert seconds to milliseconds'::TEXT),
         
        -- Column E mapping
        ('E'::CHAR(1), 
         'Post-processing'::TEXT, 
         'SECONDS'::TEXT,
         '30'::TEXT,
         'contact_statistics'::TEXT,
         ARRAY['post_processing', 'aht (partial)']::TEXT[],
         'Multiply by 1000 to convert seconds to milliseconds'::TEXT)
    ) AS t(argus_column, argus_name, argus_type, argus_example, maps_to_table, maps_to_columns, transformation);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- PROJECT AND SERVICE MAPPING
-- =====================================================================================

-- Function to map Argus project names to database IDs
CREATE OR REPLACE FUNCTION get_project_mapping()
RETURNS TABLE (
    argus_project_name TEXT,
    project_code VARCHAR,
    project_id INTEGER,
    queue_count INTEGER,
    import_notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE p.project_code
            WHEN 'B' THEN 'Бизнес'
            WHEN 'VTM' THEN 'ВТМ'
            WHEN 'I' THEN 'И'
            WHEN 'F' THEN 'Ф' 
            ELSE p.project_name
        END as argus_project_name,
        p.project_code,
        p.project_id,
        p.queue_count,
        CASE 
            WHEN p.queue_count = 1 THEN 'Single queue - import at project level'
            WHEN p.queue_count > 1 THEN 'Multiple queues - specify queue_code for accurate mapping'
            ELSE 'No queues defined'
        END as import_notes
    FROM projects p
    WHERE p.is_active = TRUE
    ORDER BY p.project_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- DATA TYPE CONVERSIONS
-- =====================================================================================

-- Reference table for data type conversions
CREATE OR REPLACE FUNCTION show_data_conversions()
RETURNS TABLE (
    argus_field TEXT,
    argus_format TEXT,
    database_field TEXT,
    database_type TEXT,
    conversion_rule TEXT,
    sql_example TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        ('Start time'::TEXT,
         'DD.MM.YYYY HH:MM:SS'::TEXT,
         'interval_start_time'::TEXT,
         'TIMESTAMPTZ'::TEXT,
         'Parse and round to interval boundary'::TEXT,
         'to_timestamp(''01.01.2024 09:00:00'', ''DD.MM.YYYY HH24:MI:SS'')'::TEXT),
         
        ('Unique incoming'::TEXT,
         'Integer string'::TEXT,
         'received_calls'::TEXT,
         'INTEGER'::TEXT,
         'Cast to integer'::TEXT,
         '''10''::INTEGER'::TEXT),
         
        ('Talk time (seconds)'::TEXT,
         'Integer string'::TEXT,
         'talk_time'::TEXT,
         'INTEGER (milliseconds)'::TEXT,
         'Cast and multiply by 1000'::TEXT,
         '''300''::INTEGER * 1000'::TEXT),
         
        ('Interval duration'::TEXT,
         'Implicit from filename'::TEXT,
         'interval_end_time'::TEXT,
         'TIMESTAMPTZ'::TEXT,
         'Add interval to start time'::TEXT,
         'interval_start + INTERVAL ''15 minutes'''::TEXT)
    ) AS t(argus_field, argus_format, database_field, database_type, conversion_rule, sql_example);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- VALIDATION RULES MAPPING
-- =====================================================================================

-- Map Argus validation rules to database constraints
CREATE OR REPLACE FUNCTION show_validation_mapping()
RETURNS TABLE (
    argus_rule TEXT,
    database_implementation TEXT,
    constraint_type TEXT,
    error_handling TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        ('Non-unique ≥ Unique'::TEXT,
         'CHECK (not_unique_received >= received_calls)'::TEXT,
         'Business rule validation'::TEXT,
         'Reject row with error message'::TEXT),
         
        ('Positive integers only'::TEXT,
         'CHECK (received_calls >= 0)'::TEXT,
         'Column constraint'::TEXT,
         'Reject row with error message'::TEXT),
         
        ('Valid timestamp format'::TEXT,
         'to_timestamp() with exception handling'::TEXT,
         'Function validation'::TEXT,
         'Log to import_errors table'::TEXT),
         
        ('15-minute boundaries'::TEXT,
         'round_to_15min_interval() function'::TEXT,
         'Automatic adjustment'::TEXT,
         'Round to nearest boundary'::TEXT),
         
        ('Required columns A-E'::TEXT,
         'NOT NULL validation in import'::TEXT,
         'Import validation'::TEXT,
         'Reject entire batch if missing'::TEXT)
    ) AS t(argus_rule, database_implementation, constraint_type, error_handling);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- MULTI-SKILL MAPPING EXTENSIONS
-- =====================================================================================

-- Extended mapping for multi-skill planning integration
CREATE OR REPLACE FUNCTION show_skill_mapping_extensions()
RETURNS TABLE (
    mapping_scenario TEXT,
    source_data TEXT,
    target_tables TEXT[],
    mapping_logic TEXT,
    example_query TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        ('Project to Skills'::TEXT,
         'Project code from filename'::TEXT,
         ARRAY['projects', 'skill_requirements']::TEXT[],
         'Map project to required skills via skill_requirements table'::TEXT,
         'SELECT sr.* FROM skill_requirements sr 
          JOIN projects p ON sr.project_id = p.project_id 
          WHERE p.project_code = ''VTM'''::TEXT),
         
        ('Queue Assignment'::TEXT,
         'Queue identifier in filename or parameter'::TEXT,
         ARRAY['project_queues', 'multi_skill_assignments']::TEXT[],
         'Map to specific queue within project'::TEXT,
         'SELECT * FROM project_queues 
          WHERE project_id = 2 AND queue_code = ''VTM_TECH_01'''::TEXT),
         
        ('Time-based Skills'::TEXT,
         'Interval time from Column A'::TEXT,
         ARRAY['multi_skill_assignments']::TEXT[],
         'Match time slots with skill assignments'::TEXT,
         'SELECT * FROM multi_skill_assignments 
          WHERE time_slot_start <= ''2024-01-01 09:00:00''::TIMESTAMPTZ 
          AND time_slot_end > ''2024-01-01 09:00:00''::TIMESTAMPTZ'::TEXT),
         
        ('Agent Allocation'::TEXT,
         'Derived from call volume'::TEXT,
         ARRAY['agent_skills', 'multi_skill_assignments']::TEXT[],
         'Calculate required agents based on volume'::TEXT,
         'SELECT COUNT(DISTINCT agent_id) FROM multi_skill_assignments 
          WHERE project_id = 2 AND assignment_date = ''2024-01-01'''::TEXT)
    ) AS t(mapping_scenario, source_data, target_tables, mapping_logic, example_query);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- IMPORT WORKFLOW REFERENCE
-- =====================================================================================

-- Complete import workflow with column mappings
CREATE OR REPLACE FUNCTION show_import_workflow()
RETURNS TABLE (
    step_number INTEGER,
    step_name TEXT,
    input_columns CHAR(1)[],
    output_tables TEXT[],
    key_transformations TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (VALUES
        (1, 'Parse Excel Data', 
         ARRAY['A','B','C','D','E']::CHAR(1)[], 
         ARRAY['excel_import_staging']::TEXT[],
         'Store raw text values for validation'::TEXT),
         
        (2, 'Validate Format', 
         ARRAY['A','B','C','D','E']::CHAR(1)[], 
         ARRAY['import_errors']::TEXT[],
         'Check date format, numeric values, business rules'::TEXT),
         
        (3, 'Transform Data', 
         ARRAY['A','B','C','D','E']::CHAR(1)[], 
         ARRAY['contact_statistics']::TEXT[],
         'Convert dates, multiply times by 1000, calculate intervals'::TEXT),
         
        (4, 'Aggregate Intervals', 
         NULL::CHAR(1)[], 
         ARRAY['hourly_contact_stats', 'daily_agent_performance']::TEXT[],
         'Create materialized views for reporting'::TEXT),
         
        (5, 'Update Skills', 
         NULL::CHAR(1)[], 
         ARRAY['skill_gaps', 'multi_skill_assignments']::TEXT[],
         'Analyze gaps and update assignments based on volume'::TEXT)
    ) AS t(step_number, step_name, input_columns, output_tables, key_transformations)
    ORDER BY step_number;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================================
-- USAGE EXAMPLES
-- =====================================================================================

/*
-- View all column mappings
SELECT * FROM show_argus_mapping();

-- View project mappings
SELECT * FROM get_project_mapping();

-- View data type conversions
SELECT * FROM show_data_conversions();

-- View validation rules
SELECT * FROM show_validation_mapping();

-- View multi-skill extensions
SELECT * FROM show_skill_mapping_extensions();

-- View complete workflow
SELECT * FROM show_import_workflow();

-- Example: Find what database columns are populated from Argus Column C
SELECT 
    argus_column,
    argus_name,
    maps_to_columns
FROM show_argus_mapping()
WHERE argus_column = 'C';

-- Example: Get conversion rule for talk time
SELECT 
    argus_field,
    database_field,
    conversion_rule,
    sql_example
FROM show_data_conversions()
WHERE argus_field = 'Talk time (seconds)';
*/

-- =====================================================================================
-- DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION show_argus_mapping IS 'Comprehensive mapping of Argus Excel columns to WFM database fields.
Shows which Argus columns (A-E) map to which database columns and how they are transformed.';

COMMENT ON FUNCTION get_project_mapping IS 'Maps Argus project names (Cyrillic) to database project codes and IDs.
Essential for determining correct service_id and project_id during import.';

COMMENT ON FUNCTION show_data_conversions IS 'Details the data type conversions required during import.
Includes SQL examples for each conversion type.';

COMMENT ON FUNCTION show_validation_mapping IS 'Maps Argus business rules to database validation constraints.
Shows how each validation rule is implemented and how errors are handled.';

COMMENT ON FUNCTION show_skill_mapping_extensions IS 'Advanced mappings for multi-skill planning integration.
Shows how imported data can be used with the skill management tables.';

COMMENT ON FUNCTION show_import_workflow IS 'Step-by-step import workflow showing data flow from Excel to database.
Useful for understanding the complete import process and troubleshooting.';