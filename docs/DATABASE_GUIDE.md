# WFM Database Guide

## Overview

The WFM database is a PostgreSQL-based time-series system optimized for handling 100,000+ call center interactions daily with sub-second query performance. It implements sophisticated partitioning, indexing, and caching strategies to meet demanding SLA requirements.

## Architecture

### Core Schema Design

#### 1. Time-Series Tables
- **contact_statistics** - Primary table for 15-minute interval call data
  - Partitioned by month for optimal query performance
  - Stores both unique and non-unique call metrics
  - Tracks service level, AHT, and occupancy metrics
  
- **agent_activity** - Tracks individual agent performance
  - Login/ready/talk time tracking
  - Activity state transitions
  - Performance aggregations

#### 2. Support Tables
- **import_batches** - Audit trail for all data imports
- **import_errors** - Detailed error tracking
- **services/groups** - Organizational hierarchy
- **forecasts** - Generated forecast data

### Partitioning Strategy
```sql
-- Automatic monthly partitions
-- Tables are partitioned by interval_start_time
-- Example: contact_statistics_2024_01, contact_statistics_2024_02
```

## Key Procedures

### Data Import

#### 1. Argus Format Import (`argus_format_validation.sql`)
```sql
-- Validate Excel data against BDD specification
SELECT * FROM validate_argus_format(jsonb_data);

-- Import with exact format compliance
SELECT * FROM import_argus_format_data(
    p_data := jsonb_data,
    p_service_id := 1,
    p_group_id := NULL,
    p_validate_only := FALSE
);
```

**Argus Format Requirements:**
- Column A: DD.MM.YYYY HH:MM:SS (Start time)
- Column B: Integer (Unique incoming calls)
- Column C: Integer (Non-unique incoming, must be ≥ B)
- Column D: Integer (Average talk time in seconds)
- Column E: Integer (Post-processing time in seconds)

#### 2. Generic Excel Import (`excel_import.sql`)
```sql
-- Batch import with validation
SELECT * FROM import_excel_batch(
    p_batch_data := jsonb_array,
    p_service_id := 1
);
```

### API Integration

#### 1. Query Operations (`api_integration.sql`)
```sql
-- Get calls by flexible intervals
SELECT * FROM api_get_calls_by_interval(
    p_start_time := '2024-01-01'::timestamptz,
    p_end_time := '2024-01-02'::timestamptz,
    p_interval_minutes := 15,
    p_service_ids := ARRAY[1,2,3]
);

-- Real-time statistics
SELECT * FROM api_get_realtime_stats(
    p_service_ids := ARRAY[1],
    p_lookback_minutes := 60
);

-- Daily summaries (cache-friendly)
SELECT * FROM api_get_service_summary(
    p_service_id := 1,
    p_date := CURRENT_DATE
);
```

#### 2. Write Operations
```sql
-- Batch insert via API
SELECT * FROM api_batch_insert_calls(
    p_calls := jsonb_array,
    p_source := 'ui_upload'
);
```

### Performance Validation

#### 1. Run Complete Validation Suite
```sql
-- Comprehensive system validation
SELECT * FROM run_all_validations();

-- Individual test suites
SELECT * FROM validate_query_performance();
SELECT * FROM validate_throughput_capacity();
SELECT * FROM monitor_resource_usage();
SELECT * FROM test_integration_performance();
```

#### 2. Health Monitoring
```sql
-- Quick health check
SELECT * FROM database_health_check();

-- Analyze query performance
SELECT * FROM analyze_query_performance();
```

## Performance Optimization

### Index Strategy

1. **BRIN Indexes** - For time-series data
   - Extremely efficient for chronological data
   - Minimal storage overhead
   - Used on interval_start_time columns

2. **B-tree Indexes** - For point lookups
   - Composite indexes on (time, service_id, group_id)
   - Descending indexes for recent data queries

3. **Partial Indexes** - For hot data
   - Last 24 hours index for real-time queries
   - Last 7 days index for recent analytics

### Query Optimization Tips

1. **Always filter by time first**
   ```sql
   -- Good: Time filter enables partition pruning
   WHERE interval_start_time >= '2024-01-01' 
     AND interval_start_time < '2024-01-02'
     AND service_id = 1
   ```

2. **Use materialized views for aggregations**
   ```sql
   -- Refresh hourly for performance
   REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hourly_stats;
   ```

3. **Leverage parallel queries**
   ```sql
   -- Functions marked as PARALLEL SAFE
   -- PostgreSQL can parallelize execution
   ```

### Connection Pooling

Recommended settings:
- Max connections: 100
- Pool size per API instance: 20
- Idle timeout: 300 seconds
- Statement timeout: 30 seconds (reads)

## Maintenance Tasks

### Daily
```sql
-- Refresh materialized views
SELECT api_refresh_all_views();

-- Check health status
SELECT * FROM database_health_check();
```

### Weekly
```sql
-- Analyze tables for query planner
ANALYZE contact_statistics;
ANALYZE agent_activity;

-- Check index usage
SELECT * FROM monitor_resource_usage();
```

### Monthly
```sql
-- Create next month's partition
-- (Handled automatically by trigger)

-- Archive old data if needed
-- Consider data retention policies
```

## Troubleshooting

### Common Issues

1. **Slow Queries**
   - Check partition pruning with EXPLAIN
   - Verify indexes are being used
   - Look for missing statistics (run ANALYZE)

2. **Import Failures**
   - Check import_errors table
   - Validate format with validate_argus_format()
   - Ensure service_id exists

3. **High Resource Usage**
   - Monitor with monitor_resource_usage()
   - Check for unused indexes
   - Review connection pool settings

### Debug Queries

```sql
-- Check recent imports
SELECT * FROM import_batches 
ORDER BY created_at DESC 
LIMIT 10;

-- View import errors
SELECT * FROM import_errors 
WHERE import_batch_id = 'uuid-here';

-- Analyze query performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM contact_statistics 
WHERE interval_start_time >= CURRENT_DATE;
```

## Integration Points

### With API Layer
- All procedures prefixed with `api_` are optimized for API use
- Support JSONB input/output for flexibility
- Include batch operations for efficiency

### With UI Layer
- Import procedures handle Excel uploads
- Validation provides clear error messages
- Preview functions for user confirmation

### With Algorithm Layer
- Efficient data retrieval for calculations
- Support for various aggregation levels
- Real-time data access for live calculations

## Security Considerations

1. **Use prepared statements** - All procedures use parameterized queries
2. **Grant minimal permissions** - API user needs only EXECUTE on procedures
3. **Validate all inputs** - Format validation before processing
4. **Audit all changes** - import_batches tracks all modifications

## Best Practices

1. **Always validate before import**
   ```sql
   -- First validate
   SELECT * FROM validate_argus_format(data);
   -- Then import if valid
   ```

2. **Use transactions for consistency**
   ```sql
   BEGIN;
   -- Multiple operations
   COMMIT;
   ```

3. **Monitor performance regularly**
   ```sql
   -- Schedule daily
   SELECT * FROM run_all_validations();
   ```

4. **Keep statistics updated**
   ```sql
   -- After large imports
   ANALYZE contact_statistics;
   ```

## Quick Reference

### Essential Procedures
- `validate_argus_format()` - Validate Excel format
- `import_argus_format_data()` - Import with validation
- `api_get_calls_by_interval()` - Query call data
- `api_batch_insert_calls()` - Bulk insert
- `run_all_validations()` - System health check
- `database_health_check()` - Quick status

### Performance SLAs
- Point queries: <10ms
- Range queries: <100ms
- Aggregations: <500ms
- Batch inserts: >100/second

### Capacity Targets
- Daily: 100,000+ calls
- Peak hour: 10,000+ calls
- Concurrent users: 50+
- Data retention: 13+ months