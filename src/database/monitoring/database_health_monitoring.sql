-- =====================================================================================
-- Database Health Monitoring System
-- Purpose: Enterprise-grade database monitoring and health assessment
-- Features: Real-time health metrics, automated alerts, performance tracking
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- 1. HEALTH MONITORING TABLES
-- =====================================================================================

-- Health check definitions and configurations
CREATE TABLE IF NOT EXISTS db_health_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_name VARCHAR(100) NOT NULL UNIQUE,
    check_type VARCHAR(50) NOT NULL, -- 'performance', 'capacity', 'integrity', 'availability'
    check_category VARCHAR(50) NOT NULL, -- 'critical', 'warning', 'info'
    check_description TEXT,
    check_query TEXT NOT NULL,
    expected_result_type VARCHAR(20) NOT NULL, -- 'numeric', 'boolean', 'text'
    threshold_critical NUMERIC,
    threshold_warning NUMERIC,
    threshold_operator VARCHAR(10) DEFAULT '>', -- '>', '<', '>=', '<=', '=', '!='
    is_active BOOLEAN DEFAULT true,
    check_interval_minutes INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Health check results history
CREATE TABLE IF NOT EXISTS db_health_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_id UUID NOT NULL REFERENCES db_health_checks(id),
    check_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    result_value NUMERIC,
    result_text TEXT,
    status VARCHAR(20) NOT NULL, -- 'ok', 'warning', 'critical', 'error'
    execution_time_ms NUMERIC,
    error_message TEXT,
    additional_info JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create partitioned table for health results (monthly partitions)
CREATE TABLE IF NOT EXISTS db_health_results_partitioned (
    LIKE db_health_results INCLUDING ALL
) PARTITION BY RANGE (check_timestamp);

-- Database performance metrics
CREATE TABLE IF NOT EXISTS db_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Connection metrics
    active_connections INTEGER,
    idle_connections INTEGER,
    max_connections INTEGER,
    connection_utilization NUMERIC(5,2),
    
    -- Query performance
    avg_query_time_ms NUMERIC(10,2),
    slow_query_count INTEGER,
    queries_per_second NUMERIC(10,2),
    
    -- Database size and growth
    database_size_mb NUMERIC(12,2),
    largest_table_size_mb NUMERIC(12,2),
    total_indexes_size_mb NUMERIC(12,2),
    
    -- Cache and I/O
    cache_hit_ratio NUMERIC(5,2),
    shared_buffers_utilization NUMERIC(5,2),
    disk_reads_per_second NUMERIC(10,2),
    disk_writes_per_second NUMERIC(10,2),
    
    -- Lock and conflict metrics
    lock_waits INTEGER,
    deadlocks INTEGER,
    conflicts INTEGER,
    
    -- Additional metrics
    additional_metrics JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Database capacity planning data
CREATE TABLE IF NOT EXISTS db_capacity_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_date DATE NOT NULL,
    
    -- Storage metrics
    total_storage_gb NUMERIC(12,2),
    used_storage_gb NUMERIC(12,2),
    available_storage_gb NUMERIC(12,2),
    storage_growth_rate_gb_per_day NUMERIC(10,4),
    
    -- Performance metrics
    peak_connections INTEGER,
    avg_cpu_usage NUMERIC(5,2),
    avg_memory_usage NUMERIC(5,2),
    peak_query_time_ms NUMERIC(10,2),
    
    -- Projected metrics
    projected_storage_30_days_gb NUMERIC(12,2),
    projected_storage_90_days_gb NUMERIC(12,2),
    projected_connections_30_days INTEGER,
    
    -- Table-specific growth
    table_growth_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(metric_date)
);

-- =====================================================================================
-- 2. HEALTH CHECK FUNCTIONS
-- =====================================================================================

-- Execute a single health check
CREATE OR REPLACE FUNCTION execute_health_check(check_id UUID)
RETURNS JSONB AS $$
DECLARE
    check_record db_health_checks%ROWTYPE;
    start_time TIMESTAMPTZ;
    execution_time_ms NUMERIC;
    result_value NUMERIC;
    result_text TEXT;
    status VARCHAR(20) := 'ok';
    error_msg TEXT;
    result_record JSONB;
BEGIN
    -- Get check definition
    SELECT * INTO check_record FROM db_health_checks WHERE id = check_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Health check not found or inactive'
        );
    END IF;
    
    -- Execute the check
    start_time := clock_timestamp();
    
    BEGIN
        EXECUTE check_record.check_query INTO result_value, result_text;
        
        -- Determine status based on thresholds
        IF check_record.expected_result_type = 'numeric' AND result_value IS NOT NULL THEN
            IF check_record.threshold_critical IS NOT NULL THEN
                CASE check_record.threshold_operator
                    WHEN '>' THEN
                        IF result_value > check_record.threshold_critical THEN status := 'critical';
                        ELSIF result_value > check_record.threshold_warning THEN status := 'warning';
                        END IF;
                    WHEN '<' THEN
                        IF result_value < check_record.threshold_critical THEN status := 'critical';
                        ELSIF result_value < check_record.threshold_warning THEN status := 'warning';
                        END IF;
                    WHEN '>=' THEN
                        IF result_value >= check_record.threshold_critical THEN status := 'critical';
                        ELSIF result_value >= check_record.threshold_warning THEN status := 'warning';
                        END IF;
                    WHEN '<=' THEN
                        IF result_value <= check_record.threshold_critical THEN status := 'critical';
                        ELSIF result_value <= check_record.threshold_warning THEN status := 'warning';
                        END IF;
                END CASE;
            END IF;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        status := 'error';
    END;
    
    execution_time_ms := EXTRACT(EPOCH FROM (clock_timestamp() - start_time)) * 1000;
    
    -- Insert result
    INSERT INTO db_health_results (
        check_id, result_value, result_text, status, 
        execution_time_ms, error_message
    ) VALUES (
        check_id, result_value, result_text, status,
        execution_time_ms, error_msg
    );
    
    -- Build result object
    result_record := jsonb_build_object(
        'success', true,
        'check_name', check_record.check_name,
        'status', status,
        'result_value', result_value,
        'result_text', result_text,
        'execution_time_ms', execution_time_ms,
        'error_message', error_msg,
        'timestamp', NOW()
    );
    
    RETURN result_record;
END;
$$ LANGUAGE plpgsql;

-- Execute all active health checks
CREATE OR REPLACE FUNCTION execute_all_health_checks()
RETURNS JSONB AS $$
DECLARE
    check_record RECORD;
    all_results JSONB := jsonb_build_array();
    check_result JSONB;
    summary_stats JSONB;
    total_checks INTEGER := 0;
    ok_checks INTEGER := 0;
    warning_checks INTEGER := 0;
    critical_checks INTEGER := 0;
    error_checks INTEGER := 0;
BEGIN
    -- Execute all active checks
    FOR check_record IN 
        SELECT id, check_name FROM db_health_checks WHERE is_active = true
    LOOP
        check_result := execute_health_check(check_record.id);
        all_results := all_results || check_result;
        
        total_checks := total_checks + 1;
        
        CASE check_result->>'status'
            WHEN 'ok' THEN ok_checks := ok_checks + 1;
            WHEN 'warning' THEN warning_checks := warning_checks + 1;
            WHEN 'critical' THEN critical_checks := critical_checks + 1;
            WHEN 'error' THEN error_checks := error_checks + 1;
        END CASE;
    END LOOP;
    
    -- Build summary
    summary_stats := jsonb_build_object(
        'total_checks', total_checks,
        'ok_checks', ok_checks,
        'warning_checks', warning_checks,
        'critical_checks', critical_checks,
        'error_checks', error_checks,
        'overall_health', CASE
            WHEN critical_checks > 0 THEN 'critical'
            WHEN error_checks > 0 THEN 'error'
            WHEN warning_checks > 0 THEN 'warning'
            ELSE 'healthy'
        END,
        'health_score', ROUND((ok_checks::NUMERIC / NULLIF(total_checks, 0)) * 100, 1)
    );
    
    RETURN jsonb_build_object(
        'timestamp', NOW(),
        'summary', summary_stats,
        'results', all_results
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. PERFORMANCE MONITORING FUNCTIONS
-- =====================================================================================

-- Collect current performance metrics
CREATE OR REPLACE FUNCTION collect_performance_metrics()
RETURNS JSONB AS $$
DECLARE
    metrics RECORD;
    result JSONB;
BEGIN
    -- Collect comprehensive performance metrics
    WITH connection_stats AS (
        SELECT 
            COUNT(*) as total_connections,
            COUNT(*) FILTER (WHERE state = 'active') as active_connections,
            COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
        FROM pg_stat_activity
        WHERE pid != pg_backend_pid()
    ),
    query_stats AS (
        SELECT 
            COALESCE(AVG(mean_exec_time), 0) as avg_query_time_ms,
            COUNT(*) FILTER (WHERE mean_exec_time > 1000) as slow_query_count,
            COALESCE(SUM(calls), 0) as total_queries
        FROM pg_stat_statements
        WHERE last_call > NOW() - INTERVAL '5 minutes'
    ),
    size_stats AS (
        SELECT 
            ROUND(pg_database_size(current_database()) / 1024.0 / 1024.0, 2) as database_size_mb,
            ROUND(pg_total_relation_size(
                (SELECT oid FROM pg_class WHERE relname = 'contact_statistics' LIMIT 1)
            ) / 1024.0 / 1024.0, 2) as largest_table_size_mb,
            ROUND(SUM(pg_indexes_size(schemaname||'.'||tablename)) / 1024.0 / 1024.0, 2) as total_indexes_size_mb
        FROM pg_tables
        WHERE schemaname = 'public'
    ),
    cache_stats AS (
        SELECT 
            ROUND(
                100.0 * sum(heap_blks_hit) / 
                NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
            ) as cache_hit_ratio
        FROM pg_statio_user_tables
    ),
    lock_stats AS (
        SELECT 
            COUNT(*) as current_locks,
            COUNT(*) FILTER (WHERE NOT granted) as lock_waits
        FROM pg_locks
    )
    SELECT 
        cs.total_connections,
        cs.active_connections,
        cs.idle_connections,
        qs.avg_query_time_ms,
        qs.slow_query_count,
        qs.total_queries,
        ss.database_size_mb,
        ss.largest_table_size_mb,
        ss.total_indexes_size_mb,
        COALESCE(cache_s.cache_hit_ratio, 0) as cache_hit_ratio,
        ls.current_locks,
        ls.lock_waits
    INTO metrics
    FROM connection_stats cs, query_stats qs, size_stats ss, cache_stats cache_s, lock_stats ls;
    
    -- Insert into performance metrics table
    INSERT INTO db_performance_metrics (
        active_connections, idle_connections, avg_query_time_ms,
        slow_query_count, queries_per_second, database_size_mb,
        largest_table_size_mb, total_indexes_size_mb, cache_hit_ratio,
        lock_waits, additional_metrics
    ) VALUES (
        metrics.active_connections, metrics.idle_connections, metrics.avg_query_time_ms,
        metrics.slow_query_count, metrics.total_queries / 300.0, -- 5 minutes = 300 seconds
        metrics.database_size_mb, metrics.largest_table_size_mb, metrics.total_indexes_size_mb,
        metrics.cache_hit_ratio, metrics.lock_waits,
        jsonb_build_object(
            'total_connections', metrics.total_connections,
            'current_locks', metrics.current_locks,
            'collection_timestamp', NOW()
        )
    );
    
    -- Return metrics as JSON
    result := jsonb_build_object(
        'timestamp', NOW(),
        'connections', jsonb_build_object(
            'active', metrics.active_connections,
            'idle', metrics.idle_connections,
            'total', metrics.total_connections
        ),
        'performance', jsonb_build_object(
            'avg_query_time_ms', metrics.avg_query_time_ms,
            'slow_queries', metrics.slow_query_count,
            'queries_per_second', ROUND(metrics.total_queries / 300.0, 2)
        ),
        'storage', jsonb_build_object(
            'database_size_mb', metrics.database_size_mb,
            'largest_table_mb', metrics.largest_table_size_mb,
            'indexes_size_mb', metrics.total_indexes_size_mb
        ),
        'cache', jsonb_build_object(
            'hit_ratio', metrics.cache_hit_ratio
        ),
        'locks', jsonb_build_object(
            'current_locks', metrics.current_locks,
            'lock_waits', metrics.lock_waits
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. PREDEFINED HEALTH CHECKS
-- =====================================================================================

-- Insert standard health checks
INSERT INTO db_health_checks (check_name, check_type, check_category, check_description, check_query, expected_result_type, threshold_critical, threshold_warning, threshold_operator, check_interval_minutes) VALUES
('Database Size Growth', 'capacity', 'warning', 'Monitor database size growth rate', 'SELECT pg_database_size(current_database()) / 1024.0 / 1024.0 / 1024.0', 'numeric', 50, 30, '>', 60),
('Connection Count', 'performance', 'critical', 'Monitor active database connections', 'SELECT COUNT(*) FROM pg_stat_activity WHERE state = ''active''', 'numeric', 80, 60, '>', 5),
('Cache Hit Ratio', 'performance', 'warning', 'Monitor buffer cache hit ratio', 'SELECT ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) FROM pg_statio_user_tables', 'numeric', 85, 90, '<', 10),
('Average Query Time', 'performance', 'critical', 'Monitor average query execution time', 'SELECT COALESCE(AVG(mean_exec_time), 0) FROM pg_stat_statements WHERE last_call > NOW() - INTERVAL ''5 minutes''', 'numeric', 100, 50, '>', 5),
('Slow Query Count', 'performance', 'warning', 'Monitor number of slow queries', 'SELECT COUNT(*) FROM pg_stat_statements WHERE mean_exec_time > 1000 AND last_call > NOW() - INTERVAL ''5 minutes''', 'numeric', 10, 5, '>', 5),
('Lock Waits', 'performance', 'critical', 'Monitor lock contention', 'SELECT COUNT(*) FROM pg_locks WHERE NOT granted', 'numeric', 5, 2, '>', 2),
('Disk Space Usage', 'capacity', 'critical', 'Monitor disk space usage percentage', 'SELECT ROUND((pg_database_size(current_database())::NUMERIC / (1024^3)) * 100 / 100, 2)', 'numeric', 90, 80, '>', 30),
('Replication Lag', 'availability', 'critical', 'Monitor replication lag if applicable', 'SELECT COALESCE(EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp())), 0)', 'numeric', 300, 60, '>', 5),
('Table Bloat Check', 'maintenance', 'warning', 'Monitor table bloat in critical tables', 'SELECT COUNT(*) FROM pg_stat_user_tables WHERE n_dead_tup > n_live_tup', 'numeric', 5, 2, '>', 60),
('Index Usage', 'performance', 'info', 'Monitor unused indexes', 'SELECT COUNT(*) FROM pg_stat_user_indexes WHERE idx_scan = 0', 'numeric', null, 10, '>', 240)
ON CONFLICT (check_name) DO UPDATE SET
    check_description = EXCLUDED.check_description,
    check_query = EXCLUDED.check_query,
    threshold_critical = EXCLUDED.threshold_critical,
    threshold_warning = EXCLUDED.threshold_warning,
    updated_at = NOW();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_results_check_timestamp ON db_health_results(check_id, check_timestamp);
CREATE INDEX IF NOT EXISTS idx_health_results_status ON db_health_results(status, check_timestamp);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_timestamp ON db_performance_metrics(metric_timestamp);
CREATE INDEX IF NOT EXISTS idx_capacity_metrics_date ON db_capacity_metrics(metric_date);

-- Grant permissions
GRANT SELECT ON db_health_checks TO demo_user;
GRANT SELECT ON db_health_results TO demo_user;
GRANT SELECT ON db_performance_metrics TO demo_user;
GRANT SELECT ON db_capacity_metrics TO demo_user;
GRANT EXECUTE ON FUNCTION execute_health_check(UUID) TO demo_user;
GRANT EXECUTE ON FUNCTION execute_all_health_checks() TO demo_user;
GRANT EXECUTE ON FUNCTION collect_performance_metrics() TO demo_user;