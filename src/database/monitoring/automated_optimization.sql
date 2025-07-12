-- =====================================================================================
-- Automated Database Optimization System
-- Purpose: Self-tuning database optimization and maintenance automation
-- Features: Index analysis, query optimization, maintenance scheduling
-- =====================================================================================

-- =====================================================================================
-- 1. OPTIMIZATION TRACKING TABLES
-- =====================================================================================

-- Track optimization recommendations and actions
CREATE TABLE IF NOT EXISTS db_optimization_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_type VARCHAR(50) NOT NULL, -- 'index', 'query', 'maintenance', 'configuration'
    priority VARCHAR(20) NOT NULL, -- 'high', 'medium', 'low'
    target_object VARCHAR(200), -- table name, index name, etc.
    current_state JSONB,
    recommended_action TEXT NOT NULL,
    recommended_sql TEXT,
    expected_benefit TEXT,
    estimated_impact_score NUMERIC(5,2),
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'applied', 'rejected'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    applied_at TIMESTAMPTZ,
    applied_by VARCHAR(100),
    results JSONB,
    notes TEXT
);

-- Track optimization actions and their outcomes
CREATE TABLE IF NOT EXISTS db_optimization_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID REFERENCES db_optimization_recommendations(id),
    action_type VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMPTZ DEFAULT NOW(),
    action_sql TEXT,
    execution_time_ms NUMERIC,
    before_metrics JSONB,
    after_metrics JSONB,
    success BOOLEAN,
    error_message TEXT,
    impact_analysis JSONB
);

-- Track maintenance schedules and execution
CREATE TABLE IF NOT EXISTS db_maintenance_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_type VARCHAR(50) NOT NULL, -- 'vacuum', 'analyze', 'reindex', 'cleanup'
    target_schema VARCHAR(100),
    target_table VARCHAR(100),
    schedule_cron VARCHAR(100), -- Cron expression for scheduling
    is_active BOOLEAN DEFAULT true,
    last_run TIMESTAMPTZ,
    next_run TIMESTAMPTZ,
    average_duration_minutes NUMERIC(8,2),
    last_status VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    configuration JSONB
);

-- =====================================================================================
-- 2. INDEX ANALYSIS AND OPTIMIZATION
-- =====================================================================================

-- Analyze index usage and recommend optimizations
CREATE OR REPLACE FUNCTION analyze_index_usage()
RETURNS JSONB AS $$
DECLARE
    unused_indexes JSONB;
    missing_indexes JSONB;
    duplicate_indexes JSONB;
    result JSONB;
    rec_count INTEGER := 0;
BEGIN
    -- Find unused indexes
    WITH unused_idx AS (
        SELECT 
            schemaname,
            tablename,
            indexname,
            pg_size_pretty(pg_relation_size(indexrelid)) as size,
            idx_scan
        FROM pg_stat_user_indexes
        WHERE idx_scan = 0
        AND schemaname = 'public'
        AND NOT indexname LIKE '%_pkey' -- Exclude primary keys
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'schema', schemaname,
            'table', tablename,
            'index', indexname,
            'size', size,
            'scans', idx_scan
        )
    ) INTO unused_indexes
    FROM unused_idx;
    
    -- Generate recommendations for unused indexes
    IF unused_indexes IS NOT NULL THEN
        INSERT INTO db_optimization_recommendations (
            recommendation_type, priority, target_object, 
            recommended_action, recommended_sql, expected_benefit, estimated_impact_score
        )
        SELECT 
            'index',
            'medium',
            idx->>'index',
            'Drop unused index: ' || (idx->>'index'),
            'DROP INDEX IF EXISTS ' || (idx->>'index') || ';',
            'Reduce storage usage and improve write performance',
            2.5
        FROM jsonb_array_elements(unused_indexes) AS idx
        WHERE NOT EXISTS (
            SELECT 1 FROM db_optimization_recommendations 
            WHERE target_object = idx->>'index' 
            AND recommendation_type = 'index'
            AND status = 'pending'
        );
        
        GET DIAGNOSTICS rec_count = ROW_COUNT;
    END IF;
    
    -- Find potentially missing indexes (tables with high seq_scan/seq_tup_read ratio)
    WITH missing_idx AS (
        SELECT 
            schemaname,
            tablename,
            seq_scan,
            seq_tup_read,
            idx_scan,
            idx_tup_fetch,
            n_tup_ins + n_tup_upd + n_tup_del as write_activity,
            CASE 
                WHEN seq_scan > 0 THEN seq_tup_read / seq_scan
                ELSE 0
            END as avg_rows_per_seq_scan
        FROM pg_stat_user_tables
        WHERE schemaname = 'public'
        AND seq_scan > 100 -- Tables with significant sequential scans
        AND seq_tup_read > idx_tup_fetch * 2 -- More sequential reads than index reads
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'schema', schemaname,
            'table', tablename,
            'seq_scans', seq_scan,
            'seq_reads', seq_tup_read,
            'avg_rows_per_scan', avg_rows_per_seq_scan,
            'write_activity', write_activity
        )
    ) INTO missing_indexes
    FROM missing_idx;
    
    -- Generate recommendations for missing indexes
    IF missing_indexes IS NOT NULL THEN
        INSERT INTO db_optimization_recommendations (
            recommendation_type, priority, target_object,
            recommended_action, expected_benefit, estimated_impact_score
        )
        SELECT 
            'index',
            'high',
            idx->>'table',
            'Analyze query patterns and consider adding indexes to table: ' || (idx->>'table'),
            'Reduce sequential scans and improve query performance',
            CASE 
                WHEN (idx->>'avg_rows_per_scan')::NUMERIC > 10000 THEN 4.5
                WHEN (idx->>'avg_rows_per_scan')::NUMERIC > 1000 THEN 3.5
                ELSE 2.5
            END
        FROM jsonb_array_elements(missing_indexes) AS idx
        WHERE NOT EXISTS (
            SELECT 1 FROM db_optimization_recommendations 
            WHERE target_object = idx->>'table' 
            AND recommendation_type = 'index'
            AND recommended_action LIKE '%consider adding indexes%'
            AND status = 'pending'
        );
    END IF;
    
    result := jsonb_build_object(
        'timestamp', NOW(),
        'unused_indexes', COALESCE(unused_indexes, jsonb_build_array()),
        'missing_indexes', COALESCE(missing_indexes, jsonb_build_array()),
        'recommendations_created', rec_count
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. QUERY OPTIMIZATION ANALYSIS
-- =====================================================================================

-- Analyze slow queries and recommend optimizations
CREATE OR REPLACE FUNCTION analyze_slow_queries()
RETURNS JSONB AS $$
DECLARE
    slow_queries JSONB;
    result JSONB;
    rec_count INTEGER := 0;
BEGIN
    -- Find slow queries from pg_stat_statements
    WITH slow_query_analysis AS (
        SELECT 
            query,
            calls,
            total_exec_time,
            mean_exec_time,
            stddev_exec_time,
            rows,
            100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) as cache_hit_percent,
            shared_blks_read,
            shared_blks_written,
            temp_blks_read,
            temp_blks_written
        FROM pg_stat_statements
        WHERE mean_exec_time > 100 -- Queries taking more than 100ms on average
        AND calls > 5 -- Called more than 5 times
        AND last_call > NOW() - INTERVAL '24 hours'
        ORDER BY mean_exec_time DESC
        LIMIT 20
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'query', LEFT(query, 200) || CASE WHEN LENGTH(query) > 200 THEN '...' ELSE '' END,
            'calls', calls,
            'avg_time_ms', ROUND(mean_exec_time, 2),
            'total_time_ms', ROUND(total_exec_time, 2),
            'cache_hit_percent', ROUND(cache_hit_percent, 2),
            'temp_usage', temp_blks_read + temp_blks_written,
            'performance_score', ROUND(mean_exec_time * calls / 1000, 2)
        )
    ) INTO slow_queries
    FROM slow_query_analysis;
    
    -- Generate recommendations for slow queries
    IF slow_queries IS NOT NULL THEN
        INSERT INTO db_optimization_recommendations (
            recommendation_type, priority, target_object,
            recommended_action, expected_benefit, estimated_impact_score
        )
        SELECT 
            'query',
            CASE 
                WHEN (sq->>'avg_time_ms')::NUMERIC > 1000 THEN 'high'
                WHEN (sq->>'avg_time_ms')::NUMERIC > 500 THEN 'medium'
                ELSE 'low'
            END,
            'Query optimization',
            'Optimize slow query: ' || LEFT(sq->>'query', 100) || '...',
            'Reduce query execution time and resource usage',
            CASE 
                WHEN (sq->>'performance_score')::NUMERIC > 100 THEN 4.0
                WHEN (sq->>'performance_score')::NUMERIC > 50 THEN 3.0
                ELSE 2.0
            END
        FROM jsonb_array_elements(slow_queries) AS sq
        WHERE NOT EXISTS (
            SELECT 1 FROM db_optimization_recommendations 
            WHERE recommended_action LIKE '%' || LEFT(sq->>'query', 50) || '%'
            AND recommendation_type = 'query'
            AND status = 'pending'
        );
        
        GET DIAGNOSTICS rec_count = ROW_COUNT;
    END IF;
    
    result := jsonb_build_object(
        'timestamp', NOW(),
        'slow_queries', COALESCE(slow_queries, jsonb_build_array()),
        'recommendations_created', rec_count
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. MAINTENANCE OPTIMIZATION
-- =====================================================================================

-- Analyze tables that need maintenance
CREATE OR REPLACE FUNCTION analyze_maintenance_needs()
RETURNS JSONB AS $$
DECLARE
    maintenance_needs JSONB;
    result JSONB;
    rec_count INTEGER := 0;
BEGIN
    -- Analyze table statistics for maintenance needs
    WITH table_maintenance AS (
        SELECT 
            schemaname,
            tablename,
            n_live_tup,
            n_dead_tup,
            n_tup_ins,
            n_tup_upd,
            n_tup_del,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze,
            vacuum_count,
            autovacuum_count,
            analyze_count,
            autoanalyze_count,
            CASE 
                WHEN n_live_tup > 0 THEN ROUND(100.0 * n_dead_tup / n_live_tup, 2)
                ELSE 0
            END as dead_tuple_percent,
            CASE
                WHEN last_analyze IS NULL AND last_autoanalyze IS NULL THEN 'never'
                WHEN GREATEST(last_analyze, last_autoanalyze) < NOW() - INTERVAL '7 days' THEN 'overdue'
                WHEN GREATEST(last_analyze, last_autoanalyze) < NOW() - INTERVAL '1 day' THEN 'due'
                ELSE 'recent'
            END as analyze_status,
            CASE
                WHEN last_vacuum IS NULL AND last_autovacuum IS NULL THEN 'never'
                WHEN GREATEST(last_vacuum, last_autovacuum) < NOW() - INTERVAL '7 days' THEN 'overdue'
                WHEN GREATEST(last_vacuum, last_autovacuum) < NOW() - INTERVAL '1 day' THEN 'due'
                ELSE 'recent'
            END as vacuum_status
        FROM pg_stat_user_tables
        WHERE schemaname = 'public'
        AND (n_live_tup > 1000 OR n_dead_tup > 100) -- Focus on tables with significant activity
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'schema', schemaname,
            'table', tablename,
            'live_tuples', n_live_tup,
            'dead_tuples', n_dead_tup,
            'dead_tuple_percent', dead_tuple_percent,
            'analyze_status', analyze_status,
            'vacuum_status', vacuum_status,
            'last_analyze', last_analyze,
            'last_vacuum', last_vacuum,
            'priority', CASE
                WHEN dead_tuple_percent > 20 THEN 'high'
                WHEN dead_tuple_percent > 10 THEN 'medium'
                ELSE 'low'
            END
        )
    ) INTO maintenance_needs
    FROM table_maintenance
    WHERE dead_tuple_percent > 5 
    OR analyze_status IN ('never', 'overdue')
    OR vacuum_status IN ('never', 'overdue');
    
    -- Generate maintenance recommendations
    IF maintenance_needs IS NOT NULL THEN
        INSERT INTO db_optimization_recommendations (
            recommendation_type, priority, target_object,
            recommended_action, recommended_sql, expected_benefit, estimated_impact_score
        )
        SELECT 
            'maintenance',
            (maint->>'priority')::VARCHAR,
            maint->>'table',
            CASE 
                WHEN (maint->>'dead_tuple_percent')::NUMERIC > 20 THEN 'VACUUM ANALYZE ' || (maint->>'table')
                WHEN maint->>'analyze_status' IN ('never', 'overdue') THEN 'ANALYZE ' || (maint->>'table')
                ELSE 'VACUUM ' || (maint->>'table')
            END,
            CASE 
                WHEN (maint->>'dead_tuple_percent')::NUMERIC > 20 THEN 'VACUUM ANALYZE ' || (maint->>'table') || ';'
                WHEN maint->>'analyze_status' IN ('never', 'overdue') THEN 'ANALYZE ' || (maint->>'table') || ';'
                ELSE 'VACUUM ' || (maint->>'table') || ';'
            END,
            'Improve query performance and reclaim space',
            CASE 
                WHEN (maint->>'dead_tuple_percent')::NUMERIC > 20 THEN 3.5
                WHEN (maint->>'dead_tuple_percent')::NUMERIC > 10 THEN 2.5
                ELSE 1.5
            END
        FROM jsonb_array_elements(maintenance_needs) AS maint
        WHERE NOT EXISTS (
            SELECT 1 FROM db_optimization_recommendations 
            WHERE target_object = maint->>'table' 
            AND recommendation_type = 'maintenance'
            AND status = 'pending'
        );
        
        GET DIAGNOSTICS rec_count = ROW_COUNT;
    END IF;
    
    result := jsonb_build_object(
        'timestamp', NOW(),
        'maintenance_needs', COALESCE(maintenance_needs, jsonb_build_array()),
        'recommendations_created', rec_count
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. AUTOMATED OPTIMIZATION ORCHESTRATOR
-- =====================================================================================

-- Run all optimization analyses
CREATE OR REPLACE FUNCTION run_optimization_analysis()
RETURNS JSONB AS $$
DECLARE
    index_analysis JSONB;
    query_analysis JSONB;
    maintenance_analysis JSONB;
    result JSONB;
    start_time TIMESTAMPTZ;
    total_time_ms NUMERIC;
BEGIN
    start_time := clock_timestamp();
    
    -- Run all analyses
    SELECT analyze_index_usage() INTO index_analysis;
    SELECT analyze_slow_queries() INTO query_analysis;
    SELECT analyze_maintenance_needs() INTO maintenance_analysis;
    
    total_time_ms := EXTRACT(EPOCH FROM (clock_timestamp() - start_time)) * 1000;
    
    result := jsonb_build_object(
        'timestamp', NOW(),
        'execution_time_ms', total_time_ms,
        'index_analysis', index_analysis,
        'query_analysis', query_analysis,
        'maintenance_analysis', maintenance_analysis,
        'summary', jsonb_build_object(
            'total_recommendations', (
                SELECT COUNT(*) FROM db_optimization_recommendations 
                WHERE created_at > NOW() - INTERVAL '1 hour'
            ),
            'high_priority_recommendations', (
                SELECT COUNT(*) FROM db_optimization_recommendations 
                WHERE priority = 'high' AND status = 'pending'
            ),
            'ready_for_execution', (
                SELECT COUNT(*) FROM db_optimization_recommendations 
                WHERE status = 'approved'
            )
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. SAFE OPTIMIZATION EXECUTION
-- =====================================================================================

-- Execute approved optimization recommendations
CREATE OR REPLACE FUNCTION execute_optimization_recommendation(rec_id UUID)
RETURNS JSONB AS $$
DECLARE
    rec_record db_optimization_recommendations%ROWTYPE;
    start_time TIMESTAMPTZ;
    execution_time_ms NUMERIC;
    before_metrics JSONB;
    after_metrics JSONB;
    success BOOLEAN := false;
    error_msg TEXT;
    result JSONB;
BEGIN
    -- Get recommendation
    SELECT * INTO rec_record FROM db_optimization_recommendations WHERE id = rec_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Recommendation not found');
    END IF;
    
    IF rec_record.status != 'approved' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Recommendation not approved for execution');
    END IF;
    
    -- Collect before metrics
    before_metrics := collect_performance_metrics();
    
    -- Execute the recommendation
    start_time := clock_timestamp();
    
    BEGIN
        IF rec_record.recommended_sql IS NOT NULL THEN
            EXECUTE rec_record.recommended_sql;
            success := true;
        ELSE
            error_msg := 'No SQL provided for execution';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        success := false;
    END;
    
    execution_time_ms := EXTRACT(EPOCH FROM (clock_timestamp() - start_time)) * 1000;
    
    -- Collect after metrics if successful
    IF success THEN
        after_metrics := collect_performance_metrics();
    END IF;
    
    -- Update recommendation status
    UPDATE db_optimization_recommendations 
    SET status = CASE WHEN success THEN 'applied' ELSE 'rejected' END,
        applied_at = NOW(),
        applied_by = current_user,
        results = jsonb_build_object(
            'success', success,
            'execution_time_ms', execution_time_ms,
            'error_message', error_msg
        )
    WHERE id = rec_id;
    
    -- Record in history
    INSERT INTO db_optimization_history (
        recommendation_id, action_type, action_sql, execution_time_ms,
        before_metrics, after_metrics, success, error_message
    ) VALUES (
        rec_id, rec_record.recommendation_type, rec_record.recommended_sql,
        execution_time_ms, before_metrics, after_metrics, success, error_msg
    );
    
    result := jsonb_build_object(
        'success', success,
        'recommendation_id', rec_id,
        'execution_time_ms', execution_time_ms,
        'error_message', error_msg,
        'before_metrics', before_metrics,
        'after_metrics', after_metrics
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 7. MAINTENANCE SCHEDULER
-- =====================================================================================

-- Schedule routine maintenance tasks
INSERT INTO db_maintenance_schedule (maintenance_type, target_schema, schedule_cron, configuration) VALUES
('analyze', 'public', '0 2 * * *', '{"tables": ["contact_statistics", "agent_activity", "demo_scenario1_calls"]}'),
('vacuum', 'public', '0 3 * * 0', '{"tables": ["contact_statistics", "agent_activity"], "analyze": true}'),
('reindex', 'public', '0 1 * * 0', '{"tables": ["contact_statistics"], "concurrently": true}'),
('cleanup', 'public', '0 4 * * *', '{"retention_days": 90, "tables": ["db_health_results", "db_performance_metrics"]}')
ON CONFLICT DO NOTHING;

-- Create indexes for optimization tables
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_status ON db_optimization_recommendations(status, priority);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_created ON db_optimization_recommendations(created_at);
CREATE INDEX IF NOT EXISTS idx_optimization_history_timestamp ON db_optimization_history(action_timestamp);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedule_next_run ON db_maintenance_schedule(next_run) WHERE is_active = true;

-- Grant permissions
GRANT SELECT ON db_optimization_recommendations TO demo_user;
GRANT SELECT ON db_optimization_history TO demo_user;
GRANT SELECT ON db_maintenance_schedule TO demo_user;
GRANT EXECUTE ON FUNCTION analyze_index_usage() TO demo_user;
GRANT EXECUTE ON FUNCTION analyze_slow_queries() TO demo_user;
GRANT EXECUTE ON FUNCTION analyze_maintenance_needs() TO demo_user;
GRANT EXECUTE ON FUNCTION run_optimization_analysis() TO demo_user;