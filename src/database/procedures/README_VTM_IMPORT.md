# Project ВТМ Import Procedures

## Overview

This module provides comprehensive SQL procedures and Python scripts for importing and processing Project ВТМ data from Argus Excel files. Project ВТМ is characterized by:

- **32 queues** with complex routing structure
- **60 projects** in the data
- **50,000+ calls per day** volume
- **Multi-skill requirements** across queues
- Support for **15m, 30m, and 1h** interval data

## Files

### SQL Procedures: `import_project_vtm.sql`

#### Tables Created

1. **`stg_vtm_metrics`** - Staging table for raw Excel data
   - Supports all 26 columns from Argus format
   - Handles both standard and extended formats
   - Includes validation and error tracking

2. **`stg_vtm_queue_mapping`** - Queue configuration (32 queues)
   - Queue codes and names
   - Service types and priorities
   - Skill requirements per queue

3. **`stg_vtm_skill_requirements`** - Skill mapping
   - Links queues to required skills
   - Minimum proficiency levels
   - Mandatory vs optional skills

4. **`vtm_routing_rules`** - Complex routing configuration
   - Time-based routing
   - Skill-based routing
   - Priority and overflow handling

5. **`vtm_metrics_partitioned`** - High-performance partitioned storage
   - Monthly partitions for scalability
   - Optimized for 50K+ calls/day

#### Key Functions

1. **`import_vtm_excel_data()`** - Main import function
   ```sql
   SELECT * FROM import_vtm_excel_data(
       p_file_path := 'path/to/excel',
       p_interval_type := '15m',
       p_has_project_column := FALSE
   );
   ```

2. **`process_vtm_metrics_batch()`** - High-volume processing
   ```sql
   SELECT * FROM process_vtm_metrics_batch(
       p_batch_id := 'uuid',
       p_target_date := CURRENT_DATE
   );
   ```

3. **`analyze_vtm_performance()`** - Complex analysis queries
   ```sql
   SELECT * FROM analyze_vtm_performance(
       p_start_date := '2025-01-01',
       p_end_date := '2025-01-31',
       p_queue_codes := ARRAY['VTM_SALES_01', 'VTM_SUPPORT_01']
   );
   ```

4. **`process_vtm_skill_requirements()`** - Multi-skill integration
   ```sql
   SELECT * FROM process_vtm_skill_requirements(p_batch_id := 'uuid');
   ```

### Python Script: `import_vtm_excel.py`

Python script for reading Excel files and loading data into staging tables.

#### Features

- Automatic Excel format detection
- Handles both 26 and 27 column formats
- Batch processing with UUID tracking
- Comprehensive error handling
- Support for all interval types (15m, 30m, 1h)

#### Usage

```bash
# Set environment variables
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=wfm_system
export DB_USER=postgres
export DB_PASSWORD=your_password
export EXCEL_DIR=/path/to/excel/files

# Run import
python import_vtm_excel.py
```

## Data Flow

1. **Excel Import** → `stg_vtm_metrics` (staging)
2. **Validation** → Error detection and logging
3. **Processing** → Parse timestamps, validate metrics
4. **Integration** → Move to production tables
5. **Aggregation** → Create hourly/daily summaries
6. **Analysis** → Generate performance reports

## Queue Structure

### Sample Queue Mapping

| Queue Code | Queue Name | Service Type | Priority | Required Skills |
|------------|------------|--------------|----------|-----------------|
| VTM_SALES_01 | ВТМ Продажи 1 | sales | 4 | russian_native, sales_experience |
| VTM_SUPPORT_01 | ВТМ Поддержка 1 | support | 3 | russian_native, technical_knowledge |
| VTM_TECH_01 | ВТМ Техническая 1 | technical | 5 | russian_native, it_expertise |
| VTM_VIP_01 | ВТМ VIP | vip_support | 5 | russian_native, english_b2, vip_handling |

### Routing Rules

- **Time-based**: Different queues active at different times
- **Skill-based**: Route to agents with matching skills
- **Overflow**: Automatic overflow to backup queues
- **Priority**: VIP and technical queues have higher priority

## Performance Optimization

### Partitioning Strategy

- Monthly partitions for metrics data
- Automatic partition creation
- Optimized indexes per partition
- Support for 50K+ calls/day

### Query Optimization

- Temporary tables for batch processing
- Specialized indexes for common queries
- Materialized views for reporting
- Connection pooling support

## Multi-Skill Integration

### Skill Categories

1. **Language Skills**
   - russian_native
   - english_b2
   - Other languages as needed

2. **Technical Skills**
   - sales_experience
   - technical_knowledge
   - it_expertise

3. **Soft Skills**
   - vip_handling
   - complaint_resolution
   - Team leadership

### Assignment Logic

```sql
-- Agents assigned based on:
-- 1. Required skills for queue
-- 2. Proficiency level (1-5)
-- 3. Availability in time slot
-- 4. Utilization targets
```

## Error Handling

### Common Errors and Solutions

1. **Period parsing errors**
   - Check date format: DD.MM.YYYY HH:MM
   - Ensure consistent formatting

2. **Validation failures**
   - HC > CDO: Data integrity issue
   - SL > 100: Percentage out of bounds
   - Negative values: Check source data

3. **Queue mapping issues**
   - Unknown queue codes
   - Missing skill requirements
   - Routing conflicts

## Monitoring

### Key Metrics to Monitor

1. **Import Performance**
   - Files processed per batch
   - Rows imported per minute
   - Error rate

2. **Data Quality**
   - Service level averages
   - Abandon rates
   - Handle time distributions

3. **Queue Performance**
   - Calls per queue
   - Agent utilization
   - Skill coverage gaps

## Maintenance

### Regular Tasks

1. **Daily**
   - Import new Excel files
   - Process staging data
   - Update aggregates

2. **Weekly**
   - Analyze performance trends
   - Review error logs
   - Update skill mappings

3. **Monthly**
   - Create new partitions
   - Archive old staging data
   - Performance tuning

### Cleanup Procedures

```sql
-- Clean up processed staging data older than 30 days
SELECT cleanup_vtm_staging(30);

-- Vacuum and analyze tables
VACUUM ANALYZE stg_vtm_metrics;
VACUUM ANALYZE vtm_metrics_partitioned;
```

## Integration Points

### With Multi-Skill Module

- Skills defined in `skills` table
- Requirements in `skill_requirements`
- Assignments in `multi_skill_assignments`

### With Reporting Module

- Views: `v_vtm_queue_performance`, `v_vtm_skill_coverage`
- Functions: `analyze_vtm_performance()`
- Real-time dashboards supported

### With Agent Management

- Agent skills tracked
- Proficiency levels maintained
- Assignment optimization

## Best Practices

1. **Import Scheduling**
   - Run imports during off-peak hours
   - Process in batches of 10,000 rows
   - Monitor memory usage

2. **Data Validation**
   - Always validate before processing
   - Log all errors for review
   - Maintain data quality metrics

3. **Performance**
   - Use partitioned tables for large datasets
   - Create appropriate indexes
   - Regular VACUUM and ANALYZE

4. **Security**
   - Limit access to staging tables
   - Audit all data modifications
   - Encrypt sensitive data

## Troubleshooting

### Common Issues

1. **Slow imports**
   - Check indexes on staging tables
   - Increase work_mem for session
   - Use COPY instead of INSERT for bulk loads

2. **Memory errors**
   - Process smaller batches
   - Increase shared_buffers
   - Use streaming for large files

3. **Lock conflicts**
   - Schedule imports appropriately
   - Use advisory locks
   - Monitor pg_stat_activity

## Future Enhancements

1. **Real-time streaming** from Argus
2. **Machine learning** for routing optimization
3. **Predictive analytics** for staffing
4. **API integration** for direct data access
5. **Advanced visualization** dashboards