-- =====================================================================================
-- Project ВТМ Import Procedures
-- Purpose: Import and process Project ВТМ data from Argus Excel files
-- Characteristics:
--   - 32 queues (complex structure)
--   - 60 projects in data
--   - 15m, 30m, 1h intervals available
--   - ~50,000 calls per day volume
--   - Complex skill requirements
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- 1. STAGING TABLES FOR VTM DATA
-- =====================================================================================

-- Drop existing staging tables
DROP TABLE IF EXISTS stg_vtm_metrics CASCADE;
DROP TABLE IF EXISTS stg_vtm_queue_mapping CASCADE;
DROP TABLE IF EXISTS stg_vtm_skill_requirements CASCADE;

-- Staging table for raw VTM metrics data
CREATE TABLE stg_vtm_metrics (
    staging_id BIGSERIAL PRIMARY KEY,
    -- File metadata
    file_name VARCHAR(255) NOT NULL,
    file_date TIMESTAMPTZ DEFAULT NOW(),
    interval_type VARCHAR(10) NOT NULL, -- '15m', '30m', '1h'
    
    -- Data columns from Excel
    period_text VARCHAR(50) NOT NULL, -- Original text format: DD.MM.YYYY HH:MM
    period_timestamp TIMESTAMPTZ, -- Parsed timestamp
    project_name VARCHAR(100), -- For files with Проект column
    queue_code VARCHAR(100), -- For future queue-specific imports
    
    -- Metrics (matching Argus format)
    cdo INTEGER, -- Calls Delivered to Operator
    hc INTEGER, -- Handled Calls
    shc DECIMAL(5,1), -- Service Level (%)
    shc_minus_ac5 DECIMAL(5,1), -- Service Level excluding calls < 5 sec
    hc_sl INTEGER, -- Handled Calls within Service Level
    sl DECIMAL(5,1), -- Service Level percentage
    sl_on_hc DECIMAL(5,1), -- Service Level based on Handled Calls
    ac INTEGER, -- Abandoned Calls
    ac5 INTEGER, -- Abandoned Calls within 5 seconds
    lcr DECIMAL(5,1), -- Lost Call Rate (%)
    fc INTEGER, -- Failed Calls
    tt BIGINT, -- Total Talk Time (seconds)
    ott BIGINT, -- Outbound Talk Time (seconds)
    ht BIGINT, -- Hold Time (seconds)
    tht BIGINT, -- Total Handle Time (seconds)
    aht INTEGER, -- Average Handle Time (seconds)
    acw BIGINT, -- After Call Work time (seconds)
    tht_plus_acw BIGINT, -- Total Handle Time including ACW
    aht_plus_acw INTEGER, -- Average Handle Time including ACW
    twt_hc BIGINT, -- Total Wait Time for Handled Calls
    awt_hc DECIMAL(10,1), -- Average Wait Time for Handled Calls
    mwt_hc INTEGER, -- Maximum Wait Time for Handled Calls
    twt_ac BIGINT, -- Total Wait Time for Abandoned Calls
    awt_ac DECIMAL(10,1), -- Average Wait Time for Abandoned Calls
    mwt_ac INTEGER, -- Maximum Wait Time for Abandoned Calls
    
    -- Processing metadata
    import_batch_id UUID DEFAULT uuid_generate_v4(),
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    error_message TEXT,
    
    -- Constraints
    CONSTRAINT stg_vtm_metrics_unique UNIQUE(period_timestamp, queue_code, interval_type)
);

-- Index for processing
CREATE INDEX idx_stg_vtm_metrics_processing ON stg_vtm_metrics(processed, import_batch_id);
CREATE INDEX idx_stg_vtm_metrics_period ON stg_vtm_metrics(period_timestamp, interval_type);

-- Queue mapping table for VTM's 32 queues
CREATE TABLE stg_vtm_queue_mapping (
    queue_mapping_id SERIAL PRIMARY KEY,
    queue_code VARCHAR(100) UNIQUE NOT NULL,
    queue_name VARCHAR(255) NOT NULL,
    queue_group VARCHAR(100), -- Grouping for related queues
    service_type VARCHAR(50), -- 'sales', 'support', 'technical', etc.
    priority_level INTEGER DEFAULT 3,
    skill_requirements TEXT[], -- Array of required skills
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Skill requirements for VTM queues
CREATE TABLE stg_vtm_skill_requirements (
    requirement_id SERIAL PRIMARY KEY,
    queue_code VARCHAR(100) NOT NULL,
    skill_code VARCHAR(50) NOT NULL,
    min_proficiency INTEGER DEFAULT 3,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(queue_code, skill_code)
);

-- =====================================================================================
-- 2. IMPORT FUNCTION FOR EXCEL DATA
-- =====================================================================================

-- Function to parse and import VTM Excel data
CREATE OR REPLACE FUNCTION import_vtm_excel_data(
    p_file_path VARCHAR,
    p_interval_type VARCHAR,
    p_has_project_column BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    rows_imported INTEGER,
    rows_failed INTEGER,
    batch_id UUID,
    error_count INTEGER
) AS $$
DECLARE
    v_batch_id UUID;
    v_rows_imported INTEGER := 0;
    v_rows_failed INTEGER := 0;
    v_error_count INTEGER := 0;
BEGIN
    -- Generate batch ID for this import
    v_batch_id := uuid_generate_v4();
    
    -- Note: Actual Excel reading would be done by external Python script
    -- This function processes data already loaded into staging table
    
    -- Parse period text to timestamp
    UPDATE stg_vtm_metrics
    SET period_timestamp = TO_TIMESTAMP(period_text, 'DD.MM.YYYY HH24:MI')
    WHERE import_batch_id = v_batch_id
      AND period_timestamp IS NULL;
    
    -- Validate data
    UPDATE stg_vtm_metrics
    SET error_message = CASE
        WHEN cdo < 0 THEN 'CDO cannot be negative'
        WHEN hc > cdo THEN 'HC cannot exceed CDO'
        WHEN shc < 0 OR shc > 100 THEN 'SHC must be between 0 and 100'
        WHEN lcr < 0 OR lcr > 100 THEN 'LCR must be between 0 and 100'
        WHEN aht < 0 THEN 'AHT cannot be negative'
        ELSE NULL
    END
    WHERE import_batch_id = v_batch_id;
    
    -- Count results
    SELECT COUNT(*) INTO v_rows_imported
    FROM stg_vtm_metrics
    WHERE import_batch_id = v_batch_id
      AND error_message IS NULL;
    
    SELECT COUNT(*) INTO v_rows_failed
    FROM stg_vtm_metrics
    WHERE import_batch_id = v_batch_id
      AND error_message IS NOT NULL;
    
    RETURN QUERY
    SELECT v_rows_imported, v_rows_failed, v_batch_id, v_error_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. QUEUE-SPECIFIC PROCESSING
-- =====================================================================================

-- Initialize VTM queue mappings (32 queues)
CREATE OR REPLACE FUNCTION init_vtm_queues()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Insert sample queue mappings for VTM's 32 queues
    -- In production, this would be loaded from configuration
    INSERT INTO stg_vtm_queue_mapping (queue_code, queue_name, queue_group, service_type, priority_level, skill_requirements)
    VALUES
        ('VTM_SALES_01', 'ВТМ Продажи 1', 'Sales', 'sales', 4, ARRAY['russian_native', 'sales_experience']),
        ('VTM_SALES_02', 'ВТМ Продажи 2', 'Sales', 'sales', 4, ARRAY['russian_native', 'sales_experience']),
        ('VTM_SUPPORT_01', 'ВТМ Поддержка 1', 'Support', 'support', 3, ARRAY['russian_native', 'technical_knowledge']),
        ('VTM_SUPPORT_02', 'ВТМ Поддержка 2', 'Support', 'support', 3, ARRAY['russian_native', 'technical_knowledge']),
        ('VTM_TECH_01', 'ВТМ Техническая 1', 'Technical', 'technical', 5, ARRAY['russian_native', 'it_expertise']),
        ('VTM_VIP_01', 'ВТМ VIP', 'VIP', 'vip_support', 5, ARRAY['russian_native', 'english_b2', 'vip_handling'])
    ON CONFLICT (queue_code) DO NOTHING;
    
    -- Add remaining queues (simplified for demo)
    FOR v_count IN 7..32 LOOP
        INSERT INTO stg_vtm_queue_mapping (queue_code, queue_name, queue_group, service_type)
        VALUES (
            'VTM_QUEUE_' || LPAD(v_count::TEXT, 2, '0'),
            'ВТМ Очередь ' || v_count,
            'General',
            'general'
        )
        ON CONFLICT (queue_code) DO NOTHING;
    END LOOP;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. MULTI-SKILL INTEGRATION
-- =====================================================================================

-- Function to process VTM data and create skill requirements
CREATE OR REPLACE FUNCTION process_vtm_skill_requirements(
    p_batch_id UUID DEFAULT NULL
)
RETURNS TABLE (
    queues_processed INTEGER,
    skills_created INTEGER,
    requirements_created INTEGER
) AS $$
DECLARE
    v_queues_processed INTEGER := 0;
    v_skills_created INTEGER := 0;
    v_requirements_created INTEGER := 0;
    v_queue RECORD;
BEGIN
    -- Process each queue's skill requirements
    FOR v_queue IN 
        SELECT DISTINCT queue_code, skill_requirements
        FROM stg_vtm_queue_mapping
        WHERE is_active = TRUE
    LOOP
        -- Ensure skills exist in main skills table
        INSERT INTO skills (skill_code, skill_name, skill_category)
        SELECT 
            unnest(v_queue.skill_requirements),
            CASE 
                WHEN unnest(v_queue.skill_requirements) LIKE '%russian%' THEN 'Русский язык'
                WHEN unnest(v_queue.skill_requirements) LIKE '%english%' THEN 'English'
                WHEN unnest(v_queue.skill_requirements) LIKE '%sales%' THEN 'Продажи'
                WHEN unnest(v_queue.skill_requirements) LIKE '%technical%' THEN 'Техническая поддержка'
                ELSE 'Общие навыки'
            END,
            CASE 
                WHEN unnest(v_queue.skill_requirements) LIKE '%russian%' OR 
                     unnest(v_queue.skill_requirements) LIKE '%english%' THEN 'language'
                WHEN unnest(v_queue.skill_requirements) LIKE '%sales%' OR 
                     unnest(v_queue.skill_requirements) LIKE '%technical%' THEN 'technical'
                ELSE 'soft_skill'
            END
        ON CONFLICT (skill_code) DO NOTHING;
        
        v_skills_created := v_skills_created + 1;
        
        -- Create skill requirements for project queues
        INSERT INTO skill_requirements (project_id, queue_id, skill_id, min_agents, min_proficiency_level)
        SELECT 
            p.project_id,
            pq.queue_id,
            s.skill_id,
            CASE 
                WHEN v_queue.queue_code LIKE '%VIP%' THEN 5
                WHEN v_queue.queue_code LIKE '%TECH%' THEN 10
                ELSE 15
            END,
            CASE 
                WHEN v_queue.queue_code LIKE '%VIP%' THEN 4
                WHEN v_queue.queue_code LIKE '%TECH%' THEN 4
                ELSE 3
            END
        FROM projects p
        CROSS JOIN LATERAL unnest(v_queue.skill_requirements) AS skill_req
        JOIN skills s ON s.skill_code = skill_req
        LEFT JOIN project_queues pq ON pq.project_id = p.project_id 
            AND pq.queue_code = v_queue.queue_code
        WHERE p.project_code = 'VTM'
        ON CONFLICT (project_id, queue_id, skill_id, valid_from) DO NOTHING;
        
        v_requirements_created := v_requirements_created + 1;
        v_queues_processed := v_queues_processed + 1;
    END LOOP;
    
    RETURN QUERY
    SELECT v_queues_processed, v_skills_created, v_requirements_created;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. HIGH-VOLUME DATA PROCESSING
-- =====================================================================================

-- Optimized function for processing high-volume VTM data (50K calls/day)
CREATE OR REPLACE FUNCTION process_vtm_metrics_batch(
    p_batch_id UUID,
    p_target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    metrics_processed INTEGER,
    hourly_aggregates_created INTEGER,
    daily_summary_created BOOLEAN,
    processing_time_ms INTEGER
) AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_metrics_processed INTEGER := 0;
    v_hourly_created INTEGER := 0;
    v_daily_created BOOLEAN := FALSE;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Create temporary table for faster processing
    CREATE TEMP TABLE tmp_vtm_metrics AS
    SELECT * FROM stg_vtm_metrics
    WHERE import_batch_id = p_batch_id
      AND DATE(period_timestamp) = p_target_date
      AND error_message IS NULL;
    
    -- Create indexes for temp table
    CREATE INDEX idx_tmp_vtm_period ON tmp_vtm_metrics(period_timestamp);
    CREATE INDEX idx_tmp_vtm_queue ON tmp_vtm_metrics(queue_code);
    
    -- Process metrics into permanent tables
    INSERT INTO call_metrics (
        project_id,
        queue_id,
        interval_start,
        interval_end,
        interval_type,
        calls_offered,
        calls_handled,
        calls_abandoned,
        service_level,
        average_handle_time,
        average_wait_time,
        max_wait_time,
        created_at
    )
    SELECT 
        (SELECT project_id FROM projects WHERE project_code = 'VTM'),
        pq.queue_id,
        period_timestamp,
        period_timestamp + CASE 
            WHEN interval_type = '15m' THEN INTERVAL '15 minutes'
            WHEN interval_type = '30m' THEN INTERVAL '30 minutes'
            WHEN interval_type = '1h' THEN INTERVAL '1 hour'
        END,
        interval_type,
        cdo,
        hc,
        ac,
        sl,
        aht,
        awt_hc,
        mwt_hc,
        NOW()
    FROM tmp_vtm_metrics t
    LEFT JOIN project_queues pq ON pq.queue_code = t.queue_code
        AND pq.project_id = (SELECT project_id FROM projects WHERE project_code = 'VTM')
    ON CONFLICT (project_id, queue_id, interval_start, interval_type) 
    DO UPDATE SET
        calls_offered = EXCLUDED.calls_offered,
        calls_handled = EXCLUDED.calls_handled,
        calls_abandoned = EXCLUDED.calls_abandoned,
        service_level = EXCLUDED.service_level,
        average_handle_time = EXCLUDED.average_handle_time,
        average_wait_time = EXCLUDED.average_wait_time,
        max_wait_time = EXCLUDED.max_wait_time,
        updated_at = NOW();
    
    GET DIAGNOSTICS v_metrics_processed = ROW_COUNT;
    
    -- Create hourly aggregates for performance
    INSERT INTO call_metrics_hourly (
        project_id,
        queue_id,
        hour_start,
        total_calls,
        total_handled,
        total_abandoned,
        avg_service_level,
        avg_handle_time,
        peak_calls
    )
    SELECT 
        (SELECT project_id FROM projects WHERE project_code = 'VTM'),
        pq.queue_id,
        date_trunc('hour', period_timestamp),
        SUM(cdo),
        SUM(hc),
        SUM(ac),
        AVG(sl),
        AVG(aht),
        MAX(cdo)
    FROM tmp_vtm_metrics t
    LEFT JOIN project_queues pq ON pq.queue_code = t.queue_code
    GROUP BY pq.queue_id, date_trunc('hour', period_timestamp)
    ON CONFLICT (project_id, queue_id, hour_start) 
    DO UPDATE SET
        total_calls = EXCLUDED.total_calls,
        total_handled = EXCLUDED.total_handled,
        total_abandoned = EXCLUDED.total_abandoned,
        avg_service_level = EXCLUDED.avg_service_level,
        avg_handle_time = EXCLUDED.avg_handle_time,
        peak_calls = EXCLUDED.peak_calls,
        updated_at = NOW();
    
    GET DIAGNOSTICS v_hourly_created = ROW_COUNT;
    
    -- Mark staging records as processed
    UPDATE stg_vtm_metrics
    SET processed = TRUE,
        processed_at = NOW()
    WHERE import_batch_id = p_batch_id
      AND DATE(period_timestamp) = p_target_date
      AND error_message IS NULL;
    
    -- Clean up temp table
    DROP TABLE tmp_vtm_metrics;
    
    RETURN QUERY
    SELECT 
        v_metrics_processed,
        v_hourly_created,
        v_daily_created,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start_time)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. QUEUE ROUTING RULES
-- =====================================================================================

-- Table for VTM queue routing rules
CREATE TABLE IF NOT EXISTS vtm_routing_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(255) NOT NULL,
    source_queue_code VARCHAR(100),
    target_queue_code VARCHAR(100),
    routing_condition JSONB, -- Flexible conditions
    priority INTEGER DEFAULT 50,
    time_based_rules JSONB, -- Time-of-day routing
    skill_based_rules JSONB, -- Skill requirements for routing
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to apply VTM routing rules
CREATE OR REPLACE FUNCTION apply_vtm_routing_rules(
    p_timestamp TIMESTAMPTZ,
    p_call_attributes JSONB
)
RETURNS VARCHAR AS $$
DECLARE
    v_target_queue VARCHAR;
    v_rule RECORD;
BEGIN
    -- Find applicable routing rule
    FOR v_rule IN 
        SELECT * FROM vtm_routing_rules
        WHERE is_active = TRUE
        ORDER BY priority DESC
    LOOP
        -- Check time-based rules
        IF v_rule.time_based_rules IS NOT NULL THEN
            -- Complex time-based routing logic
            CONTINUE WHEN NOT check_time_routing(p_timestamp, v_rule.time_based_rules);
        END IF;
        
        -- Check skill-based rules
        IF v_rule.skill_based_rules IS NOT NULL THEN
            -- Complex skill-based routing logic
            CONTINUE WHEN NOT check_skill_routing(p_call_attributes, v_rule.skill_based_rules);
        END IF;
        
        -- Rule matches, return target queue
        RETURN v_rule.target_queue_code;
    END LOOP;
    
    -- Default queue if no rules match
    RETURN 'VTM_DEFAULT';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Partitioned table for high-volume VTM metrics
CREATE TABLE IF NOT EXISTS vtm_metrics_partitioned (
    metric_id BIGSERIAL,
    period_timestamp TIMESTAMPTZ NOT NULL,
    queue_code VARCHAR(100),
    metric_data JSONB,
    PRIMARY KEY (metric_id, period_timestamp)
) PARTITION BY RANGE (period_timestamp);

-- Create monthly partitions
CREATE OR REPLACE FUNCTION create_vtm_monthly_partitions(
    p_start_date DATE,
    p_months INTEGER DEFAULT 12
)
RETURNS INTEGER AS $$
DECLARE
    v_partition_date DATE;
    v_partition_name TEXT;
    v_count INTEGER := 0;
BEGIN
    FOR i IN 0..p_months-1 LOOP
        v_partition_date := p_start_date + (i || ' months')::INTERVAL;
        v_partition_name := 'vtm_metrics_' || TO_CHAR(v_partition_date, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF vtm_metrics_partitioned
            FOR VALUES FROM (%L) TO (%L)',
            v_partition_name,
            v_partition_date,
            v_partition_date + INTERVAL '1 month'
        );
        
        -- Create indexes on partition
        EXECUTE format(
            'CREATE INDEX IF NOT EXISTS idx_%I_timestamp ON %I (period_timestamp)',
            v_partition_name, v_partition_name
        );
        
        EXECUTE format(
            'CREATE INDEX IF NOT EXISTS idx_%I_queue ON %I (queue_code)',
            v_partition_name, v_partition_name
        );
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Optimized query function for complex VTM analysis
CREATE OR REPLACE FUNCTION analyze_vtm_performance(
    p_start_date DATE,
    p_end_date DATE,
    p_queue_codes VARCHAR[] DEFAULT NULL,
    p_metric_type VARCHAR DEFAULT 'all'
)
RETURNS TABLE (
    analysis_date DATE,
    queue_code VARCHAR,
    total_calls BIGINT,
    service_level_avg DECIMAL,
    handle_time_avg DECIMAL,
    abandon_rate DECIMAL,
    peak_hour INTEGER,
    peak_volume INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_metrics AS (
        SELECT 
            DATE(period_timestamp) as metric_date,
            queue_code,
            SUM(cdo) as daily_calls,
            AVG(sl) as avg_sl,
            AVG(aht) as avg_aht,
            SUM(ac)::DECIMAL / NULLIF(SUM(cdo), 0) * 100 as abandon_pct,
            EXTRACT(HOUR FROM period_timestamp) as hour_of_day,
            MAX(cdo) as max_calls
        FROM stg_vtm_metrics
        WHERE period_timestamp >= p_start_date
          AND period_timestamp < p_end_date + INTERVAL '1 day'
          AND (p_queue_codes IS NULL OR queue_code = ANY(p_queue_codes))
          AND processed = TRUE
        GROUP BY DATE(period_timestamp), queue_code, EXTRACT(HOUR FROM period_timestamp)
    ),
    peak_hours AS (
        SELECT 
            metric_date,
            queue_code,
            hour_of_day,
            max_calls,
            ROW_NUMBER() OVER (PARTITION BY metric_date, queue_code ORDER BY max_calls DESC) as rn
        FROM daily_metrics
    )
    SELECT 
        dm.metric_date,
        dm.queue_code,
        SUM(dm.daily_calls),
        AVG(dm.avg_sl),
        AVG(dm.avg_aht),
        AVG(dm.abandon_pct),
        ph.hour_of_day::INTEGER,
        ph.max_calls::INTEGER
    FROM daily_metrics dm
    LEFT JOIN peak_hours ph ON dm.metric_date = ph.metric_date 
        AND dm.queue_code = ph.queue_code 
        AND ph.rn = 1
    GROUP BY dm.metric_date, dm.queue_code, ph.hour_of_day, ph.max_calls
    ORDER BY dm.metric_date, dm.queue_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 8. HELPER FUNCTIONS
-- =====================================================================================

-- Function to validate time-based routing rules
CREATE OR REPLACE FUNCTION check_time_routing(
    p_timestamp TIMESTAMPTZ,
    p_rules JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Implementation for time-based routing validation
    RETURN TRUE; -- Placeholder
END;
$$ LANGUAGE plpgsql;

-- Function to validate skill-based routing rules
CREATE OR REPLACE FUNCTION check_skill_routing(
    p_attributes JSONB,
    p_rules JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Implementation for skill-based routing validation
    RETURN TRUE; -- Placeholder
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. MAINTENANCE PROCEDURES
-- =====================================================================================

-- Clean up old staging data
CREATE OR REPLACE FUNCTION cleanup_vtm_staging(
    p_days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM stg_vtm_metrics
    WHERE processed = TRUE
      AND processed_at < NOW() - (p_days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    
    -- Vacuum the table to reclaim space
    EXECUTE 'VACUUM ANALYZE stg_vtm_metrics';
    
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 10. REPORTING VIEWS
-- =====================================================================================

-- View for VTM queue performance
CREATE OR REPLACE VIEW v_vtm_queue_performance AS
SELECT 
    q.queue_code,
    q.queue_name,
    q.service_type,
    DATE(m.period_timestamp) as report_date,
    COUNT(*) as interval_count,
    SUM(m.cdo) as total_calls,
    SUM(m.hc) as total_handled,
    AVG(m.sl) as avg_service_level,
    AVG(m.aht) as avg_handle_time,
    SUM(m.ac)::DECIMAL / NULLIF(SUM(m.cdo), 0) * 100 as abandon_rate
FROM stg_vtm_queue_mapping q
LEFT JOIN stg_vtm_metrics m ON q.queue_code = m.queue_code
WHERE m.processed = TRUE
GROUP BY q.queue_code, q.queue_name, q.service_type, DATE(m.period_timestamp);

-- View for VTM skill coverage analysis
CREATE OR REPLACE VIEW v_vtm_skill_coverage AS
SELECT 
    sr.queue_code,
    sr.skill_code,
    sr.min_proficiency,
    COUNT(DISTINCT asa.agent_id) as agents_assigned,
    AVG(asa.utilization_target) as avg_utilization,
    MAX(asa.time_slot_end) as last_assignment
FROM stg_vtm_skill_requirements sr
LEFT JOIN multi_skill_assignments asa ON 
    asa.skill_id = (SELECT skill_id FROM skills WHERE skill_code = sr.skill_code)
    AND asa.project_id = (SELECT project_id FROM projects WHERE project_code = 'VTM')
GROUP BY sr.queue_code, sr.skill_code, sr.min_proficiency;

-- =====================================================================================
-- 11. INITIALIZATION
-- =====================================================================================

-- Initialize VTM project data
DO $$
BEGIN
    -- Ensure VTM project exists
    INSERT INTO projects (project_code, project_name, client_name, project_type, queue_count, priority_level)
    VALUES ('VTM', 'Project ВТМ', 'VTM Corporation', 'complex', 32, 4)
    ON CONFLICT (project_code) DO UPDATE
    SET queue_count = 32,
        priority_level = 4,
        updated_at = NOW();
    
    -- Initialize queues
    PERFORM init_vtm_queues();
    
    -- Create initial partitions
    PERFORM create_vtm_monthly_partitions(DATE_TRUNC('month', CURRENT_DATE), 12);
    
    RAISE NOTICE 'VTM import procedures initialized successfully';
END;
$$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON stg_vtm_metrics TO wfm_api_user;
GRANT SELECT ON stg_vtm_queue_mapping TO wfm_api_user;
GRANT SELECT ON stg_vtm_skill_requirements TO wfm_api_user;
GRANT EXECUTE ON FUNCTION import_vtm_excel_data TO wfm_api_user;
GRANT EXECUTE ON FUNCTION process_vtm_metrics_batch TO wfm_api_user;
GRANT EXECUTE ON FUNCTION analyze_vtm_performance TO wfm_api_user;