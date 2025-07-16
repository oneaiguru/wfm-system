-- Schema 071: Advanced Indexing Strategy
-- Performance optimization for complex queries across 650+ tables
-- Target: 50% query performance improvement

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 1. Covering Indexes for Complex Joins
-- Employee schedule queries with all needed columns
CREATE INDEX idx_employee_schedules_covering ON employee_schedules 
    (employee_id, schedule_date, shift_start_time, shift_end_time)
    INCLUDE (break_duration, status, created_at);

-- Forecast accuracy with included metrics
CREATE INDEX idx_forecast_accuracy_covering ON forecast_accuracy
    (forecast_date, queue_id, interval_start)
    INCLUDE (forecasted_volume, actual_volume, mape, wape);

-- Real-time agent status with performance data
CREATE INDEX idx_agent_realtime_covering ON realtime_agent_status
    (agent_id, status_timestamp)
    INCLUDE (current_status, current_queue, handling_time);

-- 2. Partial Indexes for Filtered Queries
-- Active employees only (90% of queries)
CREATE INDEX idx_employees_active_partial ON employees (id, department_id)
    WHERE is_active = true AND deleted_at IS NULL;

-- Pending requests requiring approval
CREATE INDEX idx_requests_pending_partial ON employee_requests (employee_id, request_type)
    WHERE status = 'pending' AND deleted_at IS NULL;

-- Current shift assignments (today + next 7 days)
CREATE INDEX idx_shifts_current_partial ON shift_assignments (employee_id, shift_date)
    WHERE shift_date >= CURRENT_DATE AND shift_date <= CURRENT_DATE + INTERVAL '7 days';

-- 3. GIN Indexes for JSONB and Array Operations
-- Configuration data fast lookups
CREATE INDEX idx_system_config_gin ON system_configuration 
    USING gin (config_data jsonb_path_ops);

-- Employee skills array searches
CREATE INDEX idx_employee_skills_gin ON employee_skills 
    USING gin (skill_ids);

-- Notification preferences JSONB
CREATE INDEX idx_notification_prefs_gin ON notification_preferences
    USING gin (preferences jsonb_path_ops);

-- 4. BRIN Indexes for Time-Series Data
-- Contact center statistics (massive time-series)
CREATE INDEX idx_contact_stats_brin ON contact_center_statistics
    USING brin (interval_start) WITH (pages_per_range = 128);

-- Agent activity logs
CREATE INDEX idx_agent_activity_brin ON agent_activity_logs
    USING brin (activity_timestamp) WITH (pages_per_range = 64);

-- Forecast history
CREATE INDEX idx_forecast_history_brin ON forecast_history
    USING brin (created_at) WITH (pages_per_range = 128);

-- 5. Specialized Index Types
-- Full-text search on employee names (Russian support)
CREATE INDEX idx_employees_fulltext ON employees
    USING gin (to_tsvector('russian', 
        coalesce(first_name, '') || ' ' || 
        coalesce(last_name, '') || ' ' || 
        coalesce(patronymic, '')));

-- Trigram similarity for fuzzy search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_employees_trigram ON employees
    USING gin (last_name gin_trgm_ops, first_name gin_trgm_ops);

-- Geospatial index for multi-site locations
CREATE INDEX idx_sites_location ON operational_sites
    USING gist (location);

-- 6. Composite Indexes for Common Query Patterns
-- Schedule optimization queries
CREATE INDEX idx_schedule_optimization_composite ON shift_templates
    (site_id, department_id, shift_type, is_active);

-- Vacation planning lookups
CREATE INDEX idx_vacation_planning_composite ON vacation_requests
    (employee_id, start_date, end_date, status);

-- Queue performance analysis
CREATE INDEX idx_queue_performance_composite ON queue_statistics
    (queue_id, date_hour, service_level);

-- 7. Index Usage Monitoring Tables
CREATE TABLE index_usage_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    index_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    index_scans BIGINT DEFAULT 0,
    index_size BIGINT,
    last_used TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    effectiveness_score DECIMAL(5,2)
);

-- 8. Query Performance Tracking
CREATE TABLE query_performance_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_hash VARCHAR(64) NOT NULL,
    query_text TEXT,
    execution_time_ms DECIMAL(10,2),
    rows_returned INTEGER,
    index_used VARCHAR(255),
    optimization_suggestions TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Index Maintenance Procedures
CREATE TABLE index_maintenance_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    index_name VARCHAR(255) NOT NULL,
    maintenance_type VARCHAR(50), -- REINDEX, ANALYZE, VACUUM
    last_maintenance TIMESTAMP,
    next_scheduled TIMESTAMP,
    fragmentation_level DECIMAL(5,2),
    status VARCHAR(50)
);

-- Test data for verification
INSERT INTO index_usage_statistics (index_name, table_name, index_scans, index_size, effectiveness_score)
VALUES 
    ('idx_employee_schedules_covering', 'employee_schedules', 50000, 1048576, 95.5),
    ('idx_employees_active_partial', 'employees', 125000, 524288, 98.2),
    ('idx_contact_stats_brin', 'contact_center_statistics', 75000, 262144, 92.8);

INSERT INTO query_performance_log (query_hash, execution_time_ms, rows_returned, index_used)
VALUES 
    ('a1b2c3d4', 2.5, 150, 'idx_employee_schedules_covering'),
    ('e5f6g7h8', 0.8, 25, 'idx_employees_active_partial'),
    ('i9j0k1l2', 5.2, 1000, 'idx_contact_stats_brin');

-- Verify advanced indexing
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%'
ORDER BY pg_relation_size(indexname::regclass) DESC
LIMIT 10;