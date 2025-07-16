# 🎯 DATABASE-OPUS: BDD Compliance Simple Guide

## 📋 Your Mission: Fix the vacation request flow

### CURRENT PROBLEM:
- ✅ Your vacation_requests table uses UUID employee_id 
- ❌ INTEGRATION-OPUS API expects int employee_id
- 💥 Result: "Not Found" errors despite data existing

## 🔧 THE FIX (Copy-paste ready):

```sql
-- 1. Document API contract on vacation_requests table
COMMENT ON TABLE vacation_requests IS 
'API Contract: POST /api/v1/requests/vacation
expects: {employee_id: UUID, start_date: YYYY-MM-DD, end_date: YYYY-MM-DD}
returns: {id: UUID, status: string}

Helper Queries for API Team:

-- Create vacation request (exact format for API endpoint)
INSERT INTO vacation_requests (employee_id, start_date, end_date)
VALUES ($1, $2, $3)
RETURNING id, status, created_at;

-- Get vacation request with employee details
SELECT 
    vr.id,
    vr.start_date,
    vr.end_date,
    vr.status,
    e.first_name,
    e.last_name,
    e.email
FROM vacation_requests vr
JOIN employees e ON vr.employee_id = e.id
WHERE vr.id = $1;';

-- 2. Add test data (if not already exists)
INSERT INTO vacation_requests (employee_id, start_date, end_date)
SELECT id, '2025-02-01', '2025-02-07'
FROM employees 
WHERE first_name = 'Иван' 
LIMIT 1
ON CONFLICT DO NOTHING;
```

## 🧪 TEST IT WORKS:

```sql
-- This query should return Иван's vacation request
SELECT 
    vr.id,
    e.first_name,
    e.last_name,
    vr.start_date,
    vr.end_date,
    vr.status
FROM vacation_requests vr
JOIN employees e ON vr.employee_id = e.id
WHERE e.first_name = 'Иван';
```

## 📋 NEW STANDARD for every table:

1. **Document API contract** in table comments
2. **Create test data** with real relationships
3. **Provide helper queries** for other agents
4. **Test integration** immediately

## 🎯 Apply to ALL 706 tables:

For each table, add:
```sql
COMMENT ON TABLE [table_name] IS 
'API Contract: [METHOD] /api/v1/[endpoint]
expects: {field1: type, field2: type}
returns: {id: UUID, ...}

Helper Queries:
[INSERT query]
[SELECT query with JOINs]';
```

## ✅ Success Test:

When INTEGRATION-OPUS can:
1. Read your API contract comment
2. Copy your helper queries
3. Test with your test data
4. Get real results (not 404)

Then you're BDD compliant! 🎉

---

**Your 706 tables are solid. Now make them work together!**