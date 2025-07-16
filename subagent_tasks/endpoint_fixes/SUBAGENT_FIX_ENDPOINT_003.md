# 📋 SUBAGENT TASK: Fix Endpoint UUID Compliance 003

## 🎯 Task Information
- **Task ID**: FIX_ENDPOINT_003
- **Priority**: High
- **Estimated Time**: 15 minutes
- **Dependencies**: Database schema, agents/employees tables
- **Pattern**: Apply vacation request UUID fix success

## 📊 Assigned Endpoints
1. GET /api/v1/employees/list - `employee_list_REAL.py`
2. GET /api/v1/employees/search/query - `employee_search_REAL.py`
3. POST /api/v1/employees/bulk - `employee_bulk_REAL.py`

## 🔧 Fix Pattern (From Vacation Request Success)

### Current Problem:
```python
# ❌ BROKEN: Returns agents table (int IDs) 
# But vacation requests need employees table (UUID IDs)
query = text("SELECT id, first_name, last_name FROM agents")
# Returns: [{"id": 1, "first_name": "Анна"}]
# Needed: [{"id": "uuid-string", "first_name": "Анна"}]
```

### Required Fix:
```python
# ✅ FIXED: Return employees table (UUID IDs) for consistency
query = text("""
    SELECT 
        id,
        employee_number,
        first_name,
        last_name,
        CONCAT(first_name, ' ', last_name) as full_name
    FROM employees
    ORDER BY last_name, first_name
""")

# Process results to ensure UUID strings
employees = []
for row in result.fetchall():
    employees.append({
        "id": str(row.id),  # Convert UUID to string
        "employee_number": row.employee_number,
        "first_name": row.first_name,
        "last_name": row.last_name,
        "full_name": row.full_name
    })
```

## 📝 Step-by-Step Instructions

### Step 1: Check Data Consistency
```bash
# Compare agents vs employees tables
psql -U postgres -d wfm_enterprise -c "
SELECT 'agents' as table_name, COUNT(*) as count FROM agents
UNION ALL
SELECT 'employees' as table_name, COUNT(*) as count FROM employees;"

# Check if data overlaps or is separate
psql -U postgres -d wfm_enterprise -c "
SELECT a.first_name, a.last_name, 'agents' as source FROM agents a
UNION ALL  
SELECT e.first_name, e.last_name, 'employees' as source FROM employees e
ORDER BY first_name, last_name;"
```

### Step 2: Update Employee List Endpoint
```python
# File: employee_list_REAL.py
# Change from agents to employees table

@router.get("/employees/list", tags=["🔥 REAL Employees"])
async def get_employees_list(db: AsyncSession = Depends(get_db)):
    """
    Get all employees with UUID IDs for vacation requests compatibility
    """
    try:
        query = text("""
            SELECT 
                id,
                employee_number,
                first_name,
                last_name,
                CONCAT(first_name, ' ', last_name) as full_name
            FROM employees
            WHERE first_name IS NOT NULL
            ORDER BY last_name, first_name
        """)
        
        result = await db.execute(query)
        employees = []
        
        for row in result.fetchall():
            employees.append({
                "id": str(row.id),  # UUID as string
                "employee_number": row.employee_number,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "full_name": row.full_name,
                "department": "Call Center",  # Default for compatibility
                "position": f"Agent ({row.employee_number})",
                "status": "active"
            })
        
        return employees
        
    except Exception as e:
        raise HTTPException(500, f"Failed to get employees: {str(e)}")
```

### Step 3: Update Employee Search Endpoint
```python
# File: employee_search_REAL.py
# Ensure search works with employees table

@router.get("/employees/search/query", tags=["🔥 REAL Employees"])
async def search_employees(
    q: str,
    db: AsyncSession = Depends(get_db)
):
    """Search employees by name or employee_number (UUID compatible)"""
    try:
        query = text("""
            SELECT 
                id,
                employee_number,
                first_name,
                last_name,
                CONCAT(first_name, ' ', last_name) as full_name
            FROM employees
            WHERE 
                first_name ILIKE :search_term
                OR last_name ILIKE :search_term
                OR employee_number ILIKE :search_term
                OR CONCAT(first_name, ' ', last_name) ILIKE :search_term
            ORDER BY 
                CASE WHEN employee_number ILIKE :search_term THEN 1 ELSE 2 END,
                last_name, first_name
            LIMIT 50
        """)
        
        search_pattern = f"%{q}%"
        result = await db.execute(query, {"search_term": search_pattern})
        
        employees = []
        for row in result.fetchall():
            employees.append({
                "id": str(row.id),  # UUID as string
                "employee_number": row.employee_number,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "full_name": row.full_name
            })
        
        return {"query": q, "results": employees, "count": len(employees)}
        
    except Exception as e:
        raise HTTPException(500, f"Search failed: {str(e)}")
```

### Step 4: Update Bulk Operations Endpoint
```python
# File: employee_bulk_REAL.py
from uuid import UUID
from typing import List

class BulkEmployeeOperation(BaseModel):
    action: str  # "update", "activate", "deactivate" 
    employee_ids: List[UUID]  # Changed from List[int] to List[UUID]
    
@router.post("/employees/bulk", tags=["🔥 REAL Employees"])
async def bulk_employee_operations(
    operation: BulkEmployeeOperation,
    db: AsyncSession = Depends(get_db)
):
    """Bulk operations on employees using UUID IDs"""
    try:
        # Convert UUIDs to strings for SQL
        uuid_strings = [str(uuid_id) for uuid_id in operation.employee_ids]
        
        if operation.action == "activate":
            query = text("""
                UPDATE employees 
                SET updated_at = NOW()
                WHERE id = ANY(:employee_ids)
                RETURNING id, first_name, last_name
            """)
        elif operation.action == "deactivate":
            query = text("""
                UPDATE employees 
                SET updated_at = NOW()
                WHERE id = ANY(:employee_ids)
                RETURNING id, first_name, last_name  
            """)
        else:
            raise HTTPException(400, f"Unknown action: {operation.action}")
        
        result = await db.execute(query, {"employee_ids": uuid_strings})
        updated_employees = result.fetchall()
        await db.commit()
        
        return {
            "action": operation.action,
            "processed_count": len(updated_employees),
            "employee_ids": [str(emp.id) for emp in updated_employees]
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Bulk operation failed: {str(e)}")
```

### Step 5: Test All Endpoints
```bash
# Test 1: Employee list returns UUIDs
curl -s "http://localhost:8000/api/v1/employees/list" | jq '.[0].id'
# Expected: UUID string like "0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212"

# Test 2: Search works with Russian names
curl -s "http://localhost:8000/api/v1/employees/search/query?q=Иван" | jq '.results[].full_name'
# Expected: Returns matching Russian names

# Test 3: Bulk operations with UUIDs
UUID1=$(curl -s "http://localhost:8000/api/v1/employees/list" | jq -r '.[0].id')
UUID2=$(curl -s "http://localhost:8000/api/v1/employees/list" | jq -r '.[1].id')

curl -X POST "http://localhost:8000/api/v1/employees/bulk" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"activate\", \"employee_ids\": [\"$UUID1\", \"$UUID2\"]}"
# Expected: Success with processed_count = 2
```

## ✅ Success Criteria

- [ ] Employee list returns employees table data (not agents)
- [ ] All employee IDs are UUID strings (not integers)
- [ ] Search works with Russian names and employee numbers
- [ ] Bulk operations accept and process UUID arrays
- [ ] All endpoints maintain compatibility with vacation request workflow
- [ ] Russian text displays correctly throughout

## 🧪 Verification Commands

```bash
# Test 1: Verify UUID format consistency
curl -s "http://localhost:8000/api/v1/employees/list" | jq '.[0].id' | grep -E '^"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"$'
# Expected: Exit code 0 (UUID format match)

# Test 2: Check compatibility with vacation requests
EMPLOYEE_ID=$(curl -s "http://localhost:8000/api/v1/employees/list" | jq -r '.[0].id')
curl -X POST "http://localhost:8000/api/v1/requests/vacation" \
  -H "Content-Type: application/json" \
  -d "{\"employee_id\": \"$EMPLOYEE_ID\", \"start_date\": \"2025-09-01\", \"end_date\": \"2025-09-05\"}"
# Expected: Vacation request created successfully

# Test 3: Search performance with large dataset
time curl -s "http://localhost:8000/api/v1/employees/search/query?q=a" > /dev/null
# Expected: Response time < 1 second

# Test 4: Database consistency check
psql -U postgres -d wfm_enterprise -c "
SELECT COUNT(*) as employee_count FROM employees 
WHERE id IN (
    SELECT DISTINCT employee_id FROM vacation_requests
);"
# Expected: Matches number of employees with vacation requests
```

## 📊 Files to Modify

1. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_list_REAL.py`
2. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_search_REAL.py`
3. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_bulk_REAL.py`

## 📊 Progress Update
```bash
echo "ENDPOINT_FIX_003: Complete - Employee list/search/bulk endpoints fixed for UUID" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

- **No Employees Returned**: Check employees table has data, may need to populate from agents
- **UUID Format Errors**: Ensure converting UUID objects to strings with `str(row.id)`
- **Search Not Working**: Verify ILIKE operator works with UTF-8 Russian text
- **Bulk Operation Fails**: Check UUID array formatting in SQL query

## 🎯 Expected Output

After completion:
- All employee-related endpoints use consistent UUID employee IDs
- Search functionality works with Russian names
- Bulk operations support UUID-based employee management  
- Full compatibility with vacation request workflow
- Consistent data model across all employee endpoints

**CRITICAL**: This ensures UI components can use the same employee data for dropdowns, search, and vacation requests!