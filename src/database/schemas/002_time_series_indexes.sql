-- =====================================================================================
-- Time-Series Indexing for WFM PostgreSQL Database
-- Task ID: DB-003
-- Created for: DATABASE-OPUS Agent
-- Purpose: Optimize time-series queries for 100,000+ daily calls with sub-second response
-- Performance Target: <10ms point queries, <100ms range queries, <500ms aggregations
-- =====================================================================================

-- =====================================================================================
-- 1. CONTACT STATISTICS TIME-SERIES INDEXES
-- =====================================================================================

-- Primary BRIN index for time-series data (most efficient for chronological data)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_time_brin 
    ON contact_statistics USING BRIN (interval_start_time)
    WITH (pages_per_range = 128);

-- Composite B-tree indexes for common query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_time_service_group 
    ON contact_statistics (interval_start_time, service_id, group_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_service_time_desc 
    ON contact_statistics (service_id, interval_start_time DESC);

-- Partial indexes for active/recent data (last 24 hours)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_recent_24h 
    ON contact_statistics (service_id, interval_start_time, group_id)
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '1 day';

-- Partial index for current day's data
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_today 
    ON contact_statistics (interval_start_time, service_id)
    WHERE interval_start_time >= CURRENT_DATE;

-- Index for aggregation queries (service level calculations)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_service_level 
    ON contact_statistics (service_id, interval_start_time) 
    INCLUDE (service_level, aht, not_unique_received, not_unique_treated);

-- Index for high-volume services (optimize for services with >1000 calls/day)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contact_stats_high_volume 
    ON contact_statistics (interval_start_time, service_id, group_id)
    WHERE not_unique_received > 100;

-- =====================================================================================
-- 2. AGENT ACTIVITY TIME-SERIES INDEXES
-- =====================================================================================

-- Primary BRIN index for agent activity time-series
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_time_brin 
    ON agent_activity USING BRIN (interval_start_time)
    WITH (pages_per_range = 128);

-- Composite indexes for agent performance queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_agent_time_desc 
    ON agent_activity (agent_id, interval_start_time DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_time_agent_group 
    ON agent_activity (interval_start_time, agent_id, group_id);

-- Partial index for active agents (recent activity)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_recent_agents 
    ON agent_activity (agent_id, interval_start_time)
    WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days';

-- Index for agent occupancy calculations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_occupancy 
    ON agent_activity (agent_id, interval_start_time) 
    INCLUDE (login_time, ready_time, talk_time, calls_handled);

-- Group-based performance index
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_activity_group_time 
    ON agent_activity (group_id, interval_start_time, agent_id)
    WHERE group_id IS NOT NULL;

-- =====================================================================================
-- 3. REAL-TIME DATA INDEXES
-- =====================================================================================

-- Agent current status indexes for real-time monitoring
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_current_status_compound 
    ON agent_current_status (current_status, current_group_id, last_state_change DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_current_heartbeat 
    ON agent_current_status (last_heartbeat DESC)
    WHERE current_status != 'logged_out';

-- Queue metrics indexes for dashboard queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_queue_metrics_waiting 
    ON queue_current_metrics (calls_waiting DESC, service_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_queue_metrics_service_level 
    ON queue_current_metrics (service_id) 
    INCLUDE (current_service_level, agents_available, calls_waiting);

-- Call events indexes for real-time monitoring
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_call_events_time_service 
    ON call_events (event_time DESC, service_id, event_type);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_call_events_agent_recent 
    ON call_events (agent_id, event_time DESC)
    WHERE event_time >= NOW() - INTERVAL '1 hour';

-- =====================================================================================
-- 4. PARTITION-SPECIFIC INDEXES
-- =====================================================================================

-- Function to create indexes on all existing partitions
CREATE OR REPLACE FUNCTION create_partition_indexes()
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    base_table TEXT;
BEGIN
    -- Create indexes on contact_statistics partitions
    FOR partition_name IN 
        SELECT tablename FROM pg_tables 
        WHERE tablename LIKE 'contact_statistics_%'
          AND schemaname = 'public'
    LOOP
        -- Time-based index for each partition
        EXECUTE format('CREATE INDEX CONCURRENTLY IF NOT EXISTS %I 
                       ON %I (interval_start_time, service_id)',
                       partition_name || '_time_service_idx', partition_name);
        
        -- Service-based index for each partition
        EXECUTE format('CREATE INDEX CONCURRENTLY IF NOT EXISTS %I 
                       ON %I (service_id, interval_start_time DESC)',
                       partition_name || '_service_time_idx', partition_name);
        
        RAISE NOTICE 'Created indexes for partition: %', partition_name;
    END LOOP;
    
    -- Create indexes on agent_activity partitions
    FOR partition_name IN 
        SELECT tablename FROM pg_tables 
        WHERE tablename LIKE 'agent_activity_%'
          AND schemaname = 'public'
    LOOP
        -- Agent-time index for each partition
        EXECUTE format('CREATE INDEX CONCURRENTLY IF NOT EXISTS %I 
                       ON %I (agent_id, interval_start_time DESC)',
                       partition_name || '_agent_time_idx', partition_name);
        
        RAISE NOTICE 'Created indexes for partition: %', partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 5. INDEX MAINTENANCE PROCEDURES
-- =====================================================================================

-- Function to rebuild bloated indexes concurrently
CREATE OR REPLACE FUNCTION rebuild_bloated_indexes(bloat_threshold_percent INTEGER DEFAULT 20)
RETURNS VOID AS $$
DECLARE
    index_info RECORD;
    bloat_query TEXT := $QUERY$
        SELECT schemaname, tablename, indexname,
               round((100 * pg_relation_size(indexrelid) / 
                     GREATEST(pg_relation_size(indrelid), 1))::numeric, 1) as bloat_percent
        FROM pg_stat_user_indexes 
        WHERE schemaname = 'public'
          AND indexrelname LIKE 'idx_%'
    $QUERY$;
BEGIN
    -- Find and rebuild bloated indexes
    FOR index_info IN 
        EXECUTE bloat_query
    LOOP
        IF index_info.bloat_percent > bloat_threshold_percent THEN
            BEGIN
                EXECUTE format('REINDEX INDEX CONCURRENTLY %I.%I', 
                              index_info.schemaname, index_info.indexname);
                RAISE NOTICE 'Rebuilt bloated index: % (%.1%% bloat)', 
                           index_info.indexname, index_info.bloat_percent;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Failed to rebuild index %: %', 
                            index_info.indexname, SQLERRM;
            END;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to update table statistics for better query planning
CREATE OR REPLACE FUNCTION update_time_series_statistics()
RETURNS VOID AS $$
DECLARE
    table_name TEXT;
    partition_name TEXT;
BEGIN
    -- Update statistics for main tables
    FOR table_name IN VALUES ('contact_statistics'), ('agent_activity'), 
                             ('agent_current_status'), ('queue_current_metrics'), 
                             ('call_events')
    LOOP
        EXECUTE format('ANALYZE %I', table_name);
        RAISE NOTICE 'Updated statistics for table: %', table_name;
    END LOOP;
    
    -- Update statistics for all partitions
    FOR partition_name IN 
        SELECT tablename FROM pg_tables 
        WHERE (tablename LIKE 'contact_statistics_%' OR tablename LIKE 'agent_activity_%')
          AND schemaname = 'public'
    LOOP
        EXECUTE format('ANALYZE %I', partition_name);
    END LOOP;
    
    RAISE NOTICE 'Statistics update completed for all time-series tables and partitions';
END;
$$ LANGUAGE plpgsql;

-- Function to monitor index usage and identify unused indexes
CREATE OR REPLACE FUNCTION report_index_usage()
RETURNS TABLE (
    schemaname TEXT,
    tablename TEXT,
    indexname TEXT,
    index_scans BIGINT,
    index_size TEXT,
    usage_ratio NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.schemaname::TEXT,
        s.tablename::TEXT,
        s.indexrelname::TEXT,
        s.idx_scan,
        pg_size_pretty(pg_relation_size(s.indexrelid))::TEXT,
        CASE 
            WHEN s.idx_scan = 0 THEN 0
            ELSE round((s.idx_scan::NUMERIC / GREATEST(s.idx_scan + s.seq_scan, 1)) * 100, 2)
        END as usage_ratio
    FROM pg_stat_user_indexes s
    WHERE s.schemaname = 'public'
      AND s.indexrelname LIKE 'idx_%'
    ORDER BY s.idx_scan DESC, pg_relation_size(s.indexrelid) DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 6. AUTOMATIC INDEX CREATION FOR NEW PARTITIONS
-- =====================================================================================

-- Function to automatically create indexes on new partitions
CREATE OR REPLACE FUNCTION auto_create_partition_indexes()
RETURNS event_trigger AS $$
DECLARE
    obj RECORD;
    partition_name TEXT;
    parent_table TEXT;
BEGIN
    -- Check if this is a partition creation event
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        IF obj.command_tag = 'CREATE TABLE' AND obj.object_type = 'table' THEN
            -- Get the table name
            SELECT c.relname INTO partition_name
            FROM pg_class c
            WHERE c.oid = obj.objid;
            
            -- Check if it's a contact_statistics partition
            IF partition_name LIKE 'contact_statistics_%' THEN
                -- Create standard indexes for contact_statistics partition
                EXECUTE format('CREATE INDEX CONCURRENTLY %I ON %I (interval_start_time, service_id)',
                              partition_name || '_time_service_idx', partition_name);
                EXECUTE format('CREATE INDEX CONCURRENTLY %I ON %I (service_id, interval_start_time DESC)',
                              partition_name || '_service_time_idx', partition_name);
                RAISE NOTICE 'Auto-created indexes for contact_statistics partition: %', partition_name;
            END IF;
            
            -- Check if it's an agent_activity partition
            IF partition_name LIKE 'agent_activity_%' THEN
                -- Create standard indexes for agent_activity partition
                EXECUTE format('CREATE INDEX CONCURRENTLY %I ON %I (agent_id, interval_start_time DESC)',
                              partition_name || '_agent_time_idx', partition_name);
                RAISE NOTICE 'Auto-created indexes for agent_activity partition: %', partition_name;
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create the event trigger for automatic index creation
DROP EVENT TRIGGER IF EXISTS auto_partition_indexes_trigger;
CREATE EVENT TRIGGER auto_partition_indexes_trigger
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE')
    EXECUTE FUNCTION auto_create_partition_indexes();

-- =====================================================================================
-- 7. PERFORMANCE MONITORING VIEWS
-- =====================================================================================

-- View for monitoring time-series query performance
CREATE OR REPLACE VIEW time_series_performance_metrics AS
SELECT 
    'contact_statistics' as table_name,
    pg_size_pretty(pg_total_relation_size('contact_statistics')) as total_size,
    (SELECT COUNT(*) FROM contact_statistics WHERE interval_start_time >= CURRENT_DATE) as today_records,
    (SELECT COUNT(*) FROM contact_statistics WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days') as week_records,
    (SELECT AVG(query_time) FROM pg_stat_statements WHERE query LIKE '%contact_statistics%') as avg_query_time_ms
UNION ALL
SELECT 
    'agent_activity' as table_name,
    pg_size_pretty(pg_total_relation_size('agent_activity')) as total_size,
    (SELECT COUNT(*) FROM agent_activity WHERE interval_start_time >= CURRENT_DATE) as today_records,
    (SELECT COUNT(*) FROM agent_activity WHERE interval_start_time >= CURRENT_DATE - INTERVAL '7 days') as week_records,
    (SELECT AVG(query_time) FROM pg_stat_statements WHERE query LIKE '%agent_activity%') as avg_query_time_ms;

-- View for index effectiveness monitoring
CREATE OR REPLACE VIEW index_effectiveness_report AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as scans,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'LOW_USAGE'
        WHEN idx_scan < 1000 THEN 'MODERATE_USAGE'
        ELSE 'HIGH_USAGE'
    END as usage_level,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND indexrelname LIKE 'idx_%'
ORDER BY idx_scan DESC;

-- =====================================================================================
-- 8. INITIAL SETUP AND MAINTENANCE SCHEDULE
-- =====================================================================================

-- Create indexes on existing partitions
SELECT create_partition_indexes();

-- Update initial statistics
SELECT update_time_series_statistics();

-- =====================================================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================================================

COMMENT ON FUNCTION create_partition_indexes() IS 
    'Creates standard time-series indexes on all existing partitions for optimal query performance';

COMMENT ON FUNCTION rebuild_bloated_indexes(INTEGER) IS 
    'Rebuilds indexes that exceed the bloat threshold percentage to maintain performance';

COMMENT ON FUNCTION update_time_series_statistics() IS 
    'Updates table statistics for all time-series tables and partitions to optimize query planning';

COMMENT ON FUNCTION report_index_usage() IS 
    'Reports index usage statistics to identify unused or underutilized indexes';

COMMENT ON VIEW time_series_performance_metrics IS 
    'Provides key performance metrics for time-series tables including size and query performance';

COMMENT ON VIEW index_effectiveness_report IS 
    'Reports on index effectiveness and usage patterns for optimization decisions';

-- Index strategy comments
COMMENT ON INDEX idx_contact_stats_time_brin IS 
    'BRIN index for time-series data - highly efficient for chronological queries with minimal storage overhead';

COMMENT ON INDEX idx_contact_stats_recent_24h IS 
    'Partial index for recent data - optimizes real-time dashboard queries for last 24 hours';

COMMENT ON INDEX idx_agent_activity_occupancy IS 
    'Covering index for agent occupancy calculations - includes all required columns to avoid table lookups';

-- =====================================================================================
-- SAMPLE MAINTENANCE QUERIES
-- =====================================================================================

/*
-- Weekly maintenance routine (to be scheduled):

-- 1. Update statistics
SELECT update_time_series_statistics();

-- 2. Check for bloated indexes
SELECT * FROM report_index_usage() WHERE usage_ratio < 10 AND index_size != '0 bytes';

-- 3. Rebuild bloated indexes if needed
SELECT rebuild_bloated_indexes(25);

-- 4. Monitor performance
SELECT * FROM time_series_performance_metrics;

-- 5. Check index effectiveness
SELECT * FROM index_effectiveness_report WHERE usage_level = 'UNUSED';

-- Example queries for performance testing:

-- Point query (should be <10ms)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM contact_statistics 
WHERE service_id = 1 AND interval_start_time = '2024-01-15 14:30:00';

-- Range query (should be <100ms)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT service_id, SUM(not_unique_received), AVG(service_level)
FROM contact_statistics 
WHERE interval_start_time >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY service_id;

-- Aggregation query (should be <500ms)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT DATE_TRUNC('day', interval_start_time) as day,
       AVG(service_level), SUM(not_unique_received)
FROM contact_statistics 
WHERE interval_start_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', interval_start_time)
ORDER BY day;
*/

-- =====================================================================================
-- FINAL SETUP MESSAGE
-- =====================================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Time-Series Indexing Setup Complete';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Created indexes:';
    RAISE NOTICE '- BRIN indexes for chronological data (minimal overhead)';
    RAISE NOTICE '- Composite B-tree indexes for complex queries';
    RAISE NOTICE '- Partial indexes for recent/active data';
    RAISE NOTICE '- Covering indexes to avoid table lookups';
    RAISE NOTICE '- Automatic partition index creation';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Performance targets:';
    RAISE NOTICE '- Point queries: <10ms';
    RAISE NOTICE '- Range queries (24h): <100ms';
    RAISE NOTICE '- Aggregations (monthly): <500ms';
    RAISE NOTICE '- Index maintenance: Non-blocking concurrent operations';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Maintenance procedures available:';
    RAISE NOTICE '- create_partition_indexes(): Setup indexes on new partitions';
    RAISE NOTICE '- rebuild_bloated_indexes(): Maintain index performance';
    RAISE NOTICE '- update_time_series_statistics(): Optimize query planning';
    RAISE NOTICE '- report_index_usage(): Monitor index effectiveness';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Automatic features enabled:';
    RAISE NOTICE '- Event trigger for new partition index creation';
    RAISE NOTICE '- Performance monitoring views';
    RAISE NOTICE '- Index effectiveness reporting';
    RAISE NOTICE '=================================================================';
END $$;