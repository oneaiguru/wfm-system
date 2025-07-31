# Database Integration Patterns

**Source**: MD-CURATOR extraction from production implementations  
**Date**: 2025-07-18  
**Database**: wfm_enterprise (777 tables)

## Core Patterns

### 1. UUID→INTEGER Mapping Pattern
**Problem**: PostgreSQL UUID performance vs INTEGER foreign key needs
**Solution**: Mapping table with predictable integer IDs

```sql
CREATE TABLE employee_id_mapping (
    uuid_id UUID NOT NULL REFERENCES employees(id),
    numeric_id INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (uuid_id)
);
```

### 2. Mixed Reference Pattern
**Template**: Handle both UUID and INTEGER references in single table
```sql
CREATE TABLE approval_history (
    request_id UUID NOT NULL,           -- UUID reference
    employee_id INTEGER NOT NULL,       -- INTEGER via mapping
    CONSTRAINT fk_approval_request 
        FOREIGN KEY (request_id) REFERENCES employee_requests(id),
    CONSTRAINT fk_approval_employee 
        FOREIGN KEY (employee_id) REFERENCES employee_id_mapping(numeric_id)
);
```

### 3. Performance Index Pattern
**Optimization**: Partial indexes for active records only
```sql
CREATE INDEX idx_team_assignments_manager_id 
ON team_assignments(manager_id) 
WHERE is_active = TRUE;
```

### 4. Integration View Pattern
**Purpose**: Simplify complex joins for API access
```sql
CREATE VIEW manager_teams AS
SELECT 
    m.numeric_id as manager_id,
    COUNT(DISTINCT ta.employee_id) as team_size,
    array_agg(DISTINCT ta.team_name) as teams
FROM employee_id_mapping m
JOIN team_assignments ta ON m.numeric_id = ta.manager_id
WHERE ta.is_active = TRUE
GROUP BY m.numeric_id;
```

## Common Gotchas

### Schema Alignment Issues
- **Column Names**: password_hash vs hashed_password
- **Missing Columns**: consider_holidays, department_id
- **Type Mismatches**: UUID vs INTEGER expectations

### Performance Pitfalls
- **Missing Indexes**: Slow queries on large tables
- **Full Table Scans**: Queries without WHERE clauses
- **Cascade Deletes**: Unintended data loss

## Success Metrics
- **Performance**: All queries <300ms
- **Integration**: 100% BDD compatibility
- **Reliability**: 0 foreign key violations
- **Scalability**: 777 tables, 79,893+ records

---
**Status**: Production-tested  
**Performance**: <300ms all operations  
**Next Evolution**: Universal schema patterns