-- Schema 075: Query Performance Views and Caching
-- Materialized views and caching for heavy queries
-- Target: Dashboard queries < 10ms response time

-- 1. Materialized View Registry
CREATE TABLE performance_materialized_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    view_name VARCHAR(255) NOT NULL UNIQUE,
    source_query TEXT NOT NULL,
    refresh_method VARCHAR(50), -- incremental, complete, fast
    refresh_interval INTERVAL,
    last_refresh TIMESTAMP,
    next_refresh TIMESTAMP,
    avg_query_time_ms DECIMAL(10,2),
    space_used_bytes BIGINT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Query Result Cache
CREATE TABLE performance_query_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_hash VARCHAR(64) NOT NULL,
    query_text TEXT,
    result_data JSONB,
    result_row_count INTEGER,
    cache_hit_count INTEGER DEFAULT 0,
    execution_time_ms DECIMAL(10,2),
    cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    cache_key VARCHAR(255),
    UNIQUE(query_hash, cache_key)
);

-- 3. Dashboard Performance Metrics
CREATE TABLE performance_dashboard_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id VARCHAR(255),
    widget_id VARCHAR(255),
    metric_name VARCHAR(255),
    calculation_query TEXT,
    avg_response_time_ms DECIMAL(10,2),
    p95_response_time_ms DECIMAL(10,2),
    p99_response_time_ms DECIMAL(10,2),
    cache_strategy VARCHAR(50),
    last_optimized TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Real-time Aggregation Tables
CREATE TABLE performance_realtime_aggregates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aggregate_name VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(50), -- sum, avg, count, min, max
    source_table VARCHAR(255),
    group_by_columns TEXT[],
    filter_conditions TEXT,
    time_window INTERVAL,
    last_value JSONB,
    last_updated TIMESTAMP,
    update_frequency INTERVAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Query Optimization Suggestions
CREATE TABLE performance_optimization_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_pattern VARCHAR(500),
    current_execution_time_ms DECIMAL(10,2),
    suggested_optimization TEXT,
    expected_improvement_percent DECIMAL(5,2),
    implementation_status VARCHAR(50),
    tested_at TIMESTAMP,
    implemented_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Connection Pool Monitoring
CREATE TABLE performance_connection_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_name VARCHAR(100),
    timestamp TIMESTAMP NOT NULL,
    active_connections INTEGER,
    idle_connections INTEGER,
    waiting_connections INTEGER,
    total_connections INTEGER,
    avg_connection_age_seconds INTEGER,
    connection_errors INTEGER,
    pool_efficiency_percent DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Slow Query Log
CREATE TABLE performance_slow_queries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_hash VARCHAR(64),
    query_text TEXT,
    execution_time_ms DECIMAL(10,2),
    rows_examined BIGINT,
    rows_returned BIGINT,
    temp_tables_used INTEGER,
    filesort_used BOOLEAN,
    full_scan BOOLEAN,
    user_name VARCHAR(255),
    database_name VARCHAR(255),
    occurred_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Index Effectiveness Tracking
CREATE TABLE performance_index_effectiveness (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    index_name VARCHAR(255),
    table_name VARCHAR(255),
    columns_indexed TEXT[],
    index_scans BIGINT,
    tuple_reads BIGINT,
    effectiveness_score DECIMAL(5,2),
    size_bytes BIGINT,
    last_used TIMESTAMP,
    recommendation VARCHAR(50), -- keep, drop, rebuild
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sample materialized view definitions
INSERT INTO performance_materialized_views (view_name, source_query, refresh_method, refresh_interval, avg_query_time_ms)
VALUES 
    ('mv_agent_daily_stats', 
     'SELECT agent_id, date, SUM(calls), AVG(handle_time) FROM agent_activity GROUP BY agent_id, date',
     'incremental', '1 hour', 5.2),
    ('mv_queue_hourly_metrics',
     'SELECT queue_id, hour, AVG(wait_time), COUNT(*) FROM queue_statistics GROUP BY queue_id, hour',
     'complete', '15 minutes', 8.7),
    ('mv_forecast_accuracy',
     'SELECT forecast_date, AVG(mape), AVG(wape) FROM forecast_results GROUP BY forecast_date',
     'fast', '1 day', 3.1);

-- Insert sample cache entries
INSERT INTO performance_query_cache (query_hash, query_text, result_row_count, execution_time_ms, expires_at)
VALUES 
    ('a1b2c3d4e5f6', 'SELECT COUNT(*) FROM employees WHERE is_active = true', 1, 0.5, CURRENT_TIMESTAMP + INTERVAL '1 hour'),
    ('g7h8i9j0k1l2', 'SELECT * FROM current_agent_status LIMIT 10', 10, 1.2, CURRENT_TIMESTAMP + INTERVAL '5 minutes');

-- Insert optimization suggestions
INSERT INTO performance_optimization_suggestions (query_pattern, current_execution_time_ms, suggested_optimization, expected_improvement_percent)
VALUES 
    ('SELECT * FROM large_table WHERE unindexed_column = ?', 850.5, 'Create index on unindexed_column', 95.0),
    ('Multiple JOINs without proper indexes', 1200.0, 'Add covering indexes for JOIN columns', 80.0);

-- Verify performance tables
SELECT COUNT(*) as performance_tables_count
FROM information_schema.tables 
WHERE table_name LIKE 'performance_%';