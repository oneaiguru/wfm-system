-- Schema 072: Time-Series Partitioning
-- Partition large tables by date ranges for optimal performance
-- Target: Sub-millisecond queries on time-series data

-- 1. Create partitioned table for agent activity (replacing existing if needed)
CREATE TABLE IF NOT EXISTS agent_activity_partitioned (
    id UUID DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    activity_timestamp TIMESTAMP NOT NULL,
    activity_type VARCHAR(50),
    queue_id UUID,
    interaction_id VARCHAR(100),
    duration_seconds INTEGER,
    status VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, activity_timestamp)
) PARTITION BY RANGE (activity_timestamp);

-- Create monthly partitions for 2024-2025
CREATE TABLE agent_activity_y2024m01 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE agent_activity_y2024m02 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE agent_activity_y2024m03 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE agent_activity_y2024m04 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE agent_activity_y2024m05 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE agent_activity_y2024m06 PARTITION OF agent_activity_partitioned
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

-- 2. Forecast data partitioning
CREATE TABLE IF NOT EXISTS forecast_data_partitioned (
    id UUID DEFAULT uuid_generate_v4(),
    forecast_date DATE NOT NULL,
    interval_start TIMESTAMP NOT NULL,
    interval_end TIMESTAMP NOT NULL,
    queue_id UUID,
    predicted_volume INTEGER,
    predicted_aht DECIMAL(10,2),
    confidence_level DECIMAL(5,2),
    model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, interval_start)
) PARTITION BY RANGE (interval_start);

-- Weekly partitions for forecasts
CREATE TABLE forecast_data_week1 PARTITION OF forecast_data_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-01-08');
CREATE TABLE forecast_data_week2 PARTITION OF forecast_data_partitioned
    FOR VALUES FROM ('2024-01-08') TO ('2024-01-15');

-- 3. Automatic partition management
CREATE TABLE partition_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(255) NOT NULL,
    partition_name VARCHAR(255) NOT NULL,
    start_range TIMESTAMP NOT NULL,
    end_range TIMESTAMP NOT NULL,
    row_count BIGINT DEFAULT 0,
    size_bytes BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active'
);

-- 4. Partition maintenance procedures
CREATE TABLE partition_maintenance_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation VARCHAR(50), -- CREATE, DROP, VACUUM, ANALYZE
    table_name VARCHAR(255),
    partition_name VARCHAR(255),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    rows_affected BIGINT,
    status VARCHAR(50),
    error_message TEXT
);

-- 5. Archive configuration for old partitions
CREATE TABLE partition_archive_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(255) NOT NULL UNIQUE,
    retention_days INTEGER NOT NULL,
    archive_location VARCHAR(500),
    compression_enabled BOOLEAN DEFAULT true,
    last_archive_date TIMESTAMP,
    next_scheduled_archive TIMESTAMP
);

-- 6. Query routing optimization
CREATE TABLE partition_query_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_hash VARCHAR(64),
    partitions_scanned INTEGER,
    partitions_pruned INTEGER,
    execution_time_ms DECIMAL(10,2),
    optimization_used BOOLEAN,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO partition_management (table_name, partition_name, start_range, end_range, row_count, size_bytes)
VALUES 
    ('agent_activity_partitioned', 'agent_activity_y2024m01', '2024-01-01', '2024-02-01', 500000, 104857600),
    ('agent_activity_partitioned', 'agent_activity_y2024m02', '2024-02-01', '2024-03-01', 480000, 100663296),
    ('forecast_data_partitioned', 'forecast_data_week1', '2024-01-01', '2024-01-08', 50000, 10485760);

INSERT INTO partition_archive_config (table_name, retention_days, archive_location, compression_enabled)
VALUES 
    ('agent_activity_partitioned', 365, '/archive/agent_activity/', true),
    ('forecast_data_partitioned', 90, '/archive/forecasts/', true);

-- Create indexes on partitioned tables
CREATE INDEX idx_agent_activity_agent_time ON agent_activity_partitioned (agent_id, activity_timestamp);
CREATE INDEX idx_forecast_data_queue_time ON forecast_data_partitioned (queue_id, interval_start);

-- Verify partitioning
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE '%partition%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;