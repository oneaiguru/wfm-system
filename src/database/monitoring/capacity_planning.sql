-- =====================================================================================
-- Database Capacity Planning System
-- Purpose: Predictive capacity analysis and growth planning
-- Features: Storage forecasting, performance projections, scalability analysis
-- =====================================================================================

-- =====================================================================================
-- 1. CAPACITY PLANNING TABLES
-- =====================================================================================

-- Storage capacity tracking
CREATE TABLE IF NOT EXISTS db_storage_capacity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measurement_date DATE NOT NULL,
    measurement_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Database-level storage
    total_database_size_gb NUMERIC(12,4) NOT NULL,
    data_size_gb NUMERIC(12,4) NOT NULL,
    index_size_gb NUMERIC(12,4) NOT NULL,
    toast_size_gb NUMERIC(12,4) NOT NULL,
    
    -- Table-level storage details
    table_storage_data JSONB NOT NULL,
    largest_tables JSONB NOT NULL,
    
    -- Growth calculations
    daily_growth_gb NUMERIC(10,6),
    weekly_growth_gb NUMERIC(10,4),
    monthly_growth_gb NUMERIC(10,2),
    
    -- Projections
    projected_30_days_gb NUMERIC(12,2),
    projected_90_days_gb NUMERIC(12,2),
    projected_365_days_gb NUMERIC(12,2),
    
    -- Additional metrics
    total_tables INTEGER,
    total_indexes INTEGER,
    fragmentation_score NUMERIC(5,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(measurement_date)
);

-- Performance capacity tracking
CREATE TABLE IF NOT EXISTS db_performance_capacity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measurement_date DATE NOT NULL,
    measurement_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Connection capacity
    peak_connections INTEGER NOT NULL,
    avg_connections NUMERIC(8,2) NOT NULL,
    max_connections INTEGER NOT NULL,
    connection_utilization_percent NUMERIC(5,2) NOT NULL,
    
    -- Query performance capacity
    queries_per_second_peak NUMERIC(10,2) NOT NULL,
    queries_per_second_avg NUMERIC(10,2) NOT NULL,
    avg_query_time_ms NUMERIC(10,2) NOT NULL,
    slowest_query_time_ms NUMERIC(10,2) NOT NULL,
    
    -- Resource utilization
    cpu_usage_percent NUMERIC(5,2),
    memory_usage_percent NUMERIC(5,2),
    disk_io_per_second NUMERIC(10,2),
    cache_hit_ratio NUMERIC(5,2),
    
    -- Capacity thresholds
    performance_degradation_threshold NUMERIC(5,2) DEFAULT 80.0,
    critical_threshold NUMERIC(5,2) DEFAULT 90.0,
    
    -- Projections
    projected_peak_connections_30_days INTEGER,
    projected_peak_connections_90_days INTEGER,
    projected_queries_per_second_30_days NUMERIC(10,2),
    projected_queries_per_second_90_days NUMERIC(10,2),
    
    -- Capacity scores
    overall_capacity_score NUMERIC(5,2),
    bottleneck_analysis JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(measurement_date)
);

-- Capacity planning recommendations
CREATE TABLE IF NOT EXISTS db_capacity_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_date DATE NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL, -- 'storage', 'performance', 'scaling', 'optimization'
    priority VARCHAR(20) NOT NULL, -- 'critical', 'high', 'medium', 'low'
    
    -- Recommendation details
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    technical_details TEXT,
    business_impact TEXT,
    
    -- Capacity metrics
    current_capacity NUMERIC(10,2),
    projected_capacity NUMERIC(10,2),
    capacity_unit VARCHAR(20), -- 'GB', 'connections', 'QPS', 'percent'
    time_to_capacity_limit INTEGER, -- Days until capacity limit reached
    
    -- Implementation
    recommended_action TEXT NOT NULL,
    implementation_effort VARCHAR(20), -- 'low', 'medium', 'high'
    estimated_cost NUMERIC(10,2),
    implementation_timeline VARCHAR(50),
    
    -- Tracking
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'in_progress', 'completed', 'deferred'
    assigned_to VARCHAR(100),
    due_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================================
-- 2. CAPACITY MEASUREMENT FUNCTIONS
-- =====================================================================================

-- Collect storage capacity metrics
CREATE OR REPLACE FUNCTION collect_storage_capacity_metrics()
RETURNS JSONB AS $$
DECLARE
    storage_data RECORD;
    table_data JSONB;
    largest_tables JSONB;
    previous_measurement RECORD;
    growth_data RECORD;
    result JSONB;
BEGIN
    -- Get overall database size information
    WITH db_size AS (
        SELECT 
            ROUND(pg_database_size(current_database()) / 1024.0 / 1024.0 / 1024.0, 4) as total_size_gb,
            ROUND(pg_database_size(current_database()) / 1024.0 / 1024.0 / 1024.0, 4) as data_size_gb,
            0 as index_size_gb,
            0 as toast_size_gb
    ),
    table_sizes AS (
        SELECT 
            schemaname,
            tablename,
            pg_total_relation_size(schemaname||'.'||tablename) as total_size,
            pg_relation_size(schemaname||'.'||tablename) as table_size,
            pg_indexes_size(schemaname||'.'||tablename) as index_size,
            pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename) as toast_size
        FROM pg_tables
        WHERE schemaname = 'public'
    ),
    aggregated_sizes AS (
        SELECT 
            SUM(total_size) / 1024.0 / 1024.0 / 1024.0 as total_gb,
            SUM(table_size) / 1024.0 / 1024.0 / 1024.0 as data_gb,
            SUM(index_size) / 1024.0 / 1024.0 / 1024.0 as index_gb,
            SUM(toast_size) / 1024.0 / 1024.0 / 1024.0 as toast_gb,
            COUNT(*) as table_count
        FROM table_sizes
    ),
    index_count AS (
        SELECT COUNT(*) as index_count FROM pg_indexes WHERE schemaname = 'public'
    )
    SELECT 
        ROUND(ag.total_gb, 4) as total_database_size_gb,
        ROUND(ag.data_gb, 4) as data_size_gb,
        ROUND(ag.index_gb, 4) as index_size_gb,
        ROUND(ag.toast_gb, 4) as toast_size_gb,
        ag.table_count as total_tables,
        ic.index_count as total_indexes
    INTO storage_data
    FROM aggregated_sizes ag, index_count ic;
    
    -- Get detailed table storage data
    WITH detailed_tables AS (
        SELECT 
            schemaname,
            tablename,
            ROUND(pg_total_relation_size(schemaname||'.'||tablename) / 1024.0 / 1024.0, 2) as total_size_mb,
            ROUND(pg_relation_size(schemaname||'.'||tablename) / 1024.0 / 1024.0, 2) as table_size_mb,
            ROUND(pg_indexes_size(schemaname||'.'||tablename) / 1024.0 / 1024.0, 2) as index_size_mb,
            ROUND(n_live_tup::NUMERIC, 0) as live_tuples,
            ROUND(n_dead_tup::NUMERIC, 0) as dead_tuples,
            CASE 
                WHEN n_live_tup > 0 THEN ROUND(100.0 * n_dead_tup / n_live_tup, 2)
                ELSE 0
            END as fragmentation_percent
        FROM pg_tables t
        JOIN pg_stat_user_tables s ON t.tablename = s.relname AND t.schemaname = s.schemaname
        WHERE t.schemaname = 'public'
        ORDER BY pg_total_relation_size(t.schemaname||'.'||t.tablename) DESC
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'schema', schemaname,
            'table', tablename,
            'total_size_mb', total_size_mb,
            'table_size_mb', table_size_mb,
            'index_size_mb', index_size_mb,
            'live_tuples', live_tuples,
            'dead_tuples', dead_tuples,
            'fragmentation_percent', fragmentation_percent
        )
    ) INTO table_data
    FROM detailed_tables;
    
    -- Get largest tables
    WITH largest_tables_data AS (
        SELECT 
            schemaname,
            tablename,
            ROUND(pg_total_relation_size(schemaname||'.'||tablename) / 1024.0 / 1024.0, 2) as size_mb
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
        LIMIT 10
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'table', tablename,
            'size_mb', size_mb
        )
    ) INTO largest_tables
    FROM largest_tables_data;
    
    -- Calculate growth rates from previous measurements
    SELECT 
        total_database_size_gb,
        measurement_date,
        measurement_timestamp
    INTO previous_measurement
    FROM db_storage_capacity
    WHERE measurement_date = CURRENT_DATE - INTERVAL '1 day'
    ORDER BY measurement_timestamp DESC
    LIMIT 1;
    
    -- Calculate growth metrics
    IF previous_measurement IS NOT NULL THEN
        SELECT 
            storage_data.total_database_size_gb - previous_measurement.total_database_size_gb as daily_growth,
            CASE 
                WHEN previous_measurement.total_database_size_gb > 0 THEN
                    ROUND((storage_data.total_database_size_gb - previous_measurement.total_database_size_gb) * 7, 4)
                ELSE 0
            END as weekly_growth,
            CASE 
                WHEN previous_measurement.total_database_size_gb > 0 THEN
                    ROUND((storage_data.total_database_size_gb - previous_measurement.total_database_size_gb) * 30, 4)
                ELSE 0
            END as monthly_growth
        INTO growth_data;
    ELSE
        SELECT 0 as daily_growth, 0 as weekly_growth, 0 as monthly_growth INTO growth_data;
    END IF;
    
    -- Calculate fragmentation score
    WITH fragmentation_calc AS (
        SELECT AVG(
            CASE 
                WHEN s.n_live_tup > 0 THEN 100.0 * s.n_dead_tup / s.n_live_tup
                ELSE 0
            END
        ) as avg_fragmentation
        FROM pg_stat_user_tables s
        WHERE s.schemaname = 'public'
    )
    SELECT ROUND(avg_fragmentation, 2) INTO storage_data.fragmentation_score
    FROM fragmentation_calc;
    
    -- Insert storage capacity record
    INSERT INTO db_storage_capacity (
        measurement_date,
        total_database_size_gb,
        data_size_gb,
        index_size_gb,
        toast_size_gb,
        table_storage_data,
        largest_tables,
        daily_growth_gb,
        weekly_growth_gb,
        monthly_growth_gb,
        projected_30_days_gb,
        projected_90_days_gb,
        projected_365_days_gb,
        total_tables,
        total_indexes,
        fragmentation_score
    ) VALUES (
        CURRENT_DATE,
        storage_data.total_database_size_gb,
        storage_data.data_size_gb,
        storage_data.index_size_gb,
        storage_data.toast_size_gb,
        table_data,
        largest_tables,
        growth_data.daily_growth,
        growth_data.weekly_growth,
        growth_data.monthly_growth,
        storage_data.total_database_size_gb + (growth_data.daily_growth * 30),
        storage_data.total_database_size_gb + (growth_data.daily_growth * 90),
        storage_data.total_database_size_gb + (growth_data.daily_growth * 365),
        storage_data.total_tables,
        storage_data.total_indexes,
        COALESCE(storage_data.fragmentation_score, 0)
    )
    ON CONFLICT (measurement_date) DO UPDATE SET
        measurement_timestamp = NOW(),
        total_database_size_gb = EXCLUDED.total_database_size_gb,
        data_size_gb = EXCLUDED.data_size_gb,
        index_size_gb = EXCLUDED.index_size_gb,
        toast_size_gb = EXCLUDED.toast_size_gb,
        table_storage_data = EXCLUDED.table_storage_data,
        largest_tables = EXCLUDED.largest_tables,
        daily_growth_gb = EXCLUDED.daily_growth_gb,
        weekly_growth_gb = EXCLUDED.weekly_growth_gb,
        monthly_growth_gb = EXCLUDED.monthly_growth_gb,
        projected_30_days_gb = EXCLUDED.projected_30_days_gb,
        projected_90_days_gb = EXCLUDED.projected_90_days_gb,
        projected_365_days_gb = EXCLUDED.projected_365_days_gb,
        total_tables = EXCLUDED.total_tables,
        total_indexes = EXCLUDED.total_indexes,
        fragmentation_score = EXCLUDED.fragmentation_score;
    
    -- Build result
    result := jsonb_build_object(
        'timestamp', NOW(),
        'storage_metrics', jsonb_build_object(
            'total_size_gb', storage_data.total_database_size_gb,
            'data_size_gb', storage_data.data_size_gb,
            'index_size_gb', storage_data.index_size_gb,
            'toast_size_gb', storage_data.toast_size_gb,
            'total_tables', storage_data.total_tables,
            'total_indexes', storage_data.total_indexes,
            'fragmentation_score', storage_data.fragmentation_score
        ),
        'growth_metrics', jsonb_build_object(
            'daily_growth_gb', growth_data.daily_growth,
            'weekly_growth_gb', growth_data.weekly_growth,
            'monthly_growth_gb', growth_data.monthly_growth
        ),
        'projections', jsonb_build_object(
            '30_days_gb', storage_data.total_database_size_gb + (growth_data.daily_growth * 30),
            '90_days_gb', storage_data.total_database_size_gb + (growth_data.daily_growth * 90),
            '365_days_gb', storage_data.total_database_size_gb + (growth_data.daily_growth * 365)
        ),
        'largest_tables', largest_tables
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 3. PERFORMANCE CAPACITY ANALYSIS
-- =====================================================================================

-- Collect performance capacity metrics
CREATE OR REPLACE FUNCTION collect_performance_capacity_metrics()
RETURNS JSONB AS $$
DECLARE
    perf_data RECORD;
    bottleneck_analysis JSONB;
    result JSONB;
BEGIN
    -- Collect comprehensive performance metrics
    WITH connection_metrics AS (
        SELECT 
            COUNT(*) as current_connections,
            COUNT(*) FILTER (WHERE state = 'active') as active_connections,
            MAX(CASE WHEN name = 'max_connections' THEN setting::INTEGER END) as max_connections
        FROM pg_stat_activity, pg_settings
        WHERE name = 'max_connections'
        GROUP BY max_connections
    ),
    query_metrics AS (
        SELECT 
            COALESCE(SUM(calls), 0) as total_queries_5min,
            COALESCE(AVG(mean_exec_time), 0) as avg_query_time_ms,
            COALESCE(MAX(mean_exec_time), 0) as max_query_time_ms,
            COUNT(*) FILTER (WHERE mean_exec_time > 1000) as slow_queries
        FROM pg_stat_statements
        WHERE last_call > NOW() - INTERVAL '5 minutes'
    ),
    cache_metrics AS (
        SELECT 
            ROUND(
                100.0 * sum(heap_blks_hit) / 
                NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
            ) as cache_hit_ratio
        FROM pg_statio_user_tables
    ),
    lock_metrics AS (
        SELECT 
            COUNT(*) as current_locks,
            COUNT(*) FILTER (WHERE NOT granted) as waiting_locks
        FROM pg_locks
    )
    SELECT 
        cm.current_connections,
        cm.active_connections,
        cm.max_connections,
        ROUND(100.0 * cm.current_connections / cm.max_connections, 2) as connection_utilization,
        qm.total_queries_5min,
        ROUND(qm.total_queries_5min / 300.0, 2) as queries_per_second,
        qm.avg_query_time_ms,
        qm.max_query_time_ms,
        qm.slow_queries,
        cache_m.cache_hit_ratio,
        lm.current_locks,
        lm.waiting_locks
    INTO perf_data
    FROM connection_metrics cm, query_metrics qm, cache_metrics cache_m, lock_metrics lm;
    
    -- Analyze bottlenecks
    bottleneck_analysis := jsonb_build_object(
        'connection_pressure', CASE 
            WHEN perf_data.connection_utilization > 90 THEN 'critical'
            WHEN perf_data.connection_utilization > 80 THEN 'high'
            WHEN perf_data.connection_utilization > 60 THEN 'medium'
            ELSE 'low'
        END,
        'query_performance', CASE 
            WHEN perf_data.avg_query_time_ms > 100 THEN 'critical'
            WHEN perf_data.avg_query_time_ms > 50 THEN 'high'
            WHEN perf_data.avg_query_time_ms > 20 THEN 'medium'
            ELSE 'low'
        END,
        'cache_efficiency', CASE 
            WHEN perf_data.cache_hit_ratio < 85 THEN 'critical'
            WHEN perf_data.cache_hit_ratio < 90 THEN 'high'
            WHEN perf_data.cache_hit_ratio < 95 THEN 'medium'
            ELSE 'low'
        END,
        'lock_contention', CASE 
            WHEN perf_data.waiting_locks > 10 THEN 'critical'
            WHEN perf_data.waiting_locks > 5 THEN 'high'
            WHEN perf_data.waiting_locks > 2 THEN 'medium'
            ELSE 'low'
        END
    );
    
    -- Calculate overall capacity score
    WITH capacity_scores AS (
        SELECT 
            CASE 
                WHEN perf_data.connection_utilization > 90 THEN 20
                WHEN perf_data.connection_utilization > 80 THEN 40
                WHEN perf_data.connection_utilization > 60 THEN 70
                ELSE 100
            END as connection_score,
            CASE 
                WHEN perf_data.avg_query_time_ms > 100 THEN 20
                WHEN perf_data.avg_query_time_ms > 50 THEN 40
                WHEN perf_data.avg_query_time_ms > 20 THEN 70
                ELSE 100
            END as query_score,
            CASE 
                WHEN perf_data.cache_hit_ratio < 85 THEN 20
                WHEN perf_data.cache_hit_ratio < 90 THEN 40
                WHEN perf_data.cache_hit_ratio < 95 THEN 70
                ELSE 100
            END as cache_score,
            CASE 
                WHEN perf_data.waiting_locks > 10 THEN 20
                WHEN perf_data.waiting_locks > 5 THEN 40
                WHEN perf_data.waiting_locks > 2 THEN 70
                ELSE 100
            END as lock_score
    )
    SELECT ROUND((connection_score + query_score + cache_score + lock_score) / 4.0, 2) as overall_score
    INTO perf_data.overall_capacity_score
    FROM capacity_scores;
    
    -- Insert performance capacity record
    INSERT INTO db_performance_capacity (
        measurement_date,
        peak_connections,
        avg_connections,
        max_connections,
        connection_utilization_percent,
        queries_per_second_peak,
        queries_per_second_avg,
        avg_query_time_ms,
        slowest_query_time_ms,
        cache_hit_ratio,
        overall_capacity_score,
        bottleneck_analysis,
        projected_peak_connections_30_days,
        projected_queries_per_second_30_days
    ) VALUES (
        CURRENT_DATE,
        perf_data.active_connections,
        perf_data.current_connections,
        perf_data.max_connections,
        perf_data.connection_utilization,
        perf_data.queries_per_second,
        perf_data.queries_per_second,
        perf_data.avg_query_time_ms,
        perf_data.max_query_time_ms,
        perf_data.cache_hit_ratio,
        perf_data.overall_capacity_score,
        bottleneck_analysis,
        ROUND(perf_data.active_connections * 1.1), -- 10% growth assumption
        ROUND(perf_data.queries_per_second * 1.1)
    )
    ON CONFLICT (measurement_date) DO UPDATE SET
        measurement_timestamp = NOW(),
        peak_connections = EXCLUDED.peak_connections,
        avg_connections = EXCLUDED.avg_connections,
        connection_utilization_percent = EXCLUDED.connection_utilization_percent,
        queries_per_second_peak = EXCLUDED.queries_per_second_peak,
        queries_per_second_avg = EXCLUDED.queries_per_second_avg,
        avg_query_time_ms = EXCLUDED.avg_query_time_ms,
        slowest_query_time_ms = EXCLUDED.slowest_query_time_ms,
        cache_hit_ratio = EXCLUDED.cache_hit_ratio,
        overall_capacity_score = EXCLUDED.overall_capacity_score,
        bottleneck_analysis = EXCLUDED.bottleneck_analysis;
    
    -- Build result
    result := jsonb_build_object(
        'timestamp', NOW(),
        'performance_metrics', jsonb_build_object(
            'connections', jsonb_build_object(
                'current', perf_data.current_connections,
                'active', perf_data.active_connections,
                'max', perf_data.max_connections,
                'utilization_percent', perf_data.connection_utilization
            ),
            'queries', jsonb_build_object(
                'per_second', perf_data.queries_per_second,
                'avg_time_ms', perf_data.avg_query_time_ms,
                'max_time_ms', perf_data.max_query_time_ms,
                'slow_queries', perf_data.slow_queries
            ),
            'cache', jsonb_build_object(
                'hit_ratio', perf_data.cache_hit_ratio
            ),
            'locks', jsonb_build_object(
                'current', perf_data.current_locks,
                'waiting', perf_data.waiting_locks
            )
        ),
        'capacity_score', perf_data.overall_capacity_score,
        'bottleneck_analysis', bottleneck_analysis
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 4. CAPACITY PLANNING DASHBOARD
-- =====================================================================================

-- Get comprehensive capacity planning dashboard
CREATE OR REPLACE FUNCTION get_capacity_planning_dashboard()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH latest_storage AS (
        SELECT *
        FROM db_storage_capacity
        ORDER BY measurement_date DESC
        LIMIT 1
    ),
    latest_performance AS (
        SELECT *
        FROM db_performance_capacity
        ORDER BY measurement_date DESC
        LIMIT 1
    ),
    growth_trend AS (
        SELECT 
            AVG(daily_growth_gb) as avg_daily_growth,
            AVG(weekly_growth_gb) as avg_weekly_growth,
            AVG(monthly_growth_gb) as avg_monthly_growth
        FROM db_storage_capacity
        WHERE measurement_date >= CURRENT_DATE - INTERVAL '30 days'
    ),
    capacity_recommendations AS (
        SELECT 
            COUNT(*) as total_recommendations,
            COUNT(*) FILTER (WHERE priority = 'critical') as critical_recommendations,
            COUNT(*) FILTER (WHERE priority = 'high') as high_recommendations,
            COUNT(*) FILTER (WHERE status = 'open') as open_recommendations
        FROM db_capacity_recommendations
        WHERE recommendation_date >= CURRENT_DATE - INTERVAL '30 days'
    )
    SELECT jsonb_build_object(
        'timestamp', NOW(),
        'storage_capacity', jsonb_build_object(
            'current_size_gb', ls.total_database_size_gb,
            'data_size_gb', ls.data_size_gb,
            'index_size_gb', ls.index_size_gb,
            'largest_tables', ls.largest_tables,
            'fragmentation_score', ls.fragmentation_score,
            'growth_trend', jsonb_build_object(
                'daily_gb', gt.avg_daily_growth,
                'weekly_gb', gt.avg_weekly_growth,
                'monthly_gb', gt.avg_monthly_growth
            ),
            'projections', jsonb_build_object(
                '30_days_gb', ls.projected_30_days_gb,
                '90_days_gb', ls.projected_90_days_gb,
                '365_days_gb', ls.projected_365_days_gb
            )
        ),
        'performance_capacity', jsonb_build_object(
            'connection_utilization', lp.connection_utilization_percent,
            'queries_per_second', lp.queries_per_second_avg,
            'avg_query_time_ms', lp.avg_query_time_ms,
            'cache_hit_ratio', lp.cache_hit_ratio,
            'capacity_score', lp.overall_capacity_score,
            'bottlenecks', lp.bottleneck_analysis,
            'projections', jsonb_build_object(
                'peak_connections_30_days', lp.projected_peak_connections_30_days,
                'queries_per_second_30_days', lp.projected_queries_per_second_30_days
            )
        ),
        'recommendations', jsonb_build_object(
            'total', cr.total_recommendations,
            'critical', cr.critical_recommendations,
            'high', cr.high_recommendations,
            'open', cr.open_recommendations
        )
    ) INTO result
    FROM latest_storage ls, latest_performance lp, growth_trend gt, capacity_recommendations cr;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_storage_capacity_date ON db_storage_capacity(measurement_date);
CREATE INDEX IF NOT EXISTS idx_performance_capacity_date ON db_performance_capacity(measurement_date);
CREATE INDEX IF NOT EXISTS idx_capacity_recommendations_status ON db_capacity_recommendations(status, priority);
CREATE INDEX IF NOT EXISTS idx_capacity_recommendations_date ON db_capacity_recommendations(recommendation_date);

-- Grant permissions
GRANT SELECT ON db_storage_capacity TO demo_user;
GRANT SELECT ON db_performance_capacity TO demo_user;
GRANT SELECT ON db_capacity_recommendations TO demo_user;
GRANT EXECUTE ON FUNCTION collect_storage_capacity_metrics() TO demo_user;
GRANT EXECUTE ON FUNCTION collect_performance_capacity_metrics() TO demo_user;
GRANT EXECUTE ON FUNCTION get_capacity_planning_dashboard() TO demo_user;