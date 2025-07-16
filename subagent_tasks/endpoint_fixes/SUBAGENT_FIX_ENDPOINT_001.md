# 📋 SUBAGENT TASK: Fix Endpoint UUID Compliance 001

## 🎯 Task Information
- **Task ID**: FIX_ENDPOINT_001
- **Priority**: Critical
- **Estimated Time**: 15 minutes
- **Dependencies**: Database schema, employees table
- **Pattern**: Apply vacation request UUID fix success

## 📊 Assigned Endpoints
1. GET /api/v1/employees/{employee_id} - `employee_get_REAL.py`
2. PUT /api/v1/employees/{employee_id} - `employee_update_REAL.py`
3. DELETE /api/v1/employees/{employee_id} - `employee_delete_REAL.py`

## 🔧 Fix Pattern (From Vacation Request Success)

### Current Problem:
```python
# ❌ BROKEN: Endpoints expect int employee_id
@router.get("/employees/{emp_id}")
async def get_employee(emp_id: int, db: AsyncSession = Depends(get_db)):
    # Queries agents table (int IDs) but should query employees table (UUID IDs)
```

### Required Fix:
```python
# ✅ FIXED: Use UUID type and employees table
from uuid import UUID

@router.get("/employees/{employee_id}")
async def get_employee(employee_id: UUID, db: AsyncSession = Depends(get_db)):
    # Validate employee exists in UUID employees table
    query = text("""
        SELECT 
            id,
            first_name,
            last_name,
            employee_number,
            CONCAT(first_name, ' ', last_name) as full_name
        FROM employees
        WHERE id = :employee_id
    """)
    
    result = await db.execute(query, {"employee_id": employee_id})
    employee = result.fetchone()
    
    if not employee:
        raise HTTPException(
            status_code=404,
            detail=f"Employee {employee_id} not found"
        )
    
    return {
        "id": str(employee.id),
        "employee_number": employee.employee_number,
        "first_name": employee.first_name,
        "last_name": employee.last_name,
        "full_name": employee.full_name
    }
```

## 📝 Step-by-Step Instructions

### Step 1: Check Database Schema
```bash
psql -U postgres -d wfm_enterprise -c "\d employees"
# Verify: employee_id column is UUID type
```

### Step 2: Update Pydantic Models
```python
# In each endpoint file, update imports:
from uuid import UUID

# Update path parameters:
employee_id: UUID  # Change from int to UUID

# Update request models:
class EmployeeUpdate(BaseModel):
    employee_id: UUID  # If used in request body
```

### Step 3: Update Database Queries
```python
# Change from agents table to employees table:
# OLD: SELECT * FROM agents WHERE id = :emp_id
# NEW: SELECT * FROM employees WHERE id = :employee_id

# Ensure all queries use UUID employee_id parameter
```

### Step 4: Update Error Handling
```python
# Add proper UUID validation and error messages
if not employee:
    raise HTTPException(
        status_code=404,
        detail=f"Employee {employee_id} not found in employees table"
    )
```

### Step 5: Test with Real Employee UUID
```bash
# Get real employee UUID
EMPLOYEE_UUID=$(curl -s http://localhost:8000/api/v1/employees/uuid | jq -r '.[0].id')

# Test GET endpoint
curl "http://localhost:8000/api/v1/employees/$EMPLOYEE_UUID"

# Test PUT endpoint  
curl -X PUT "http://localhost:8000/api/v1/employees/$EMPLOYEE_UUID" \
  -H "Content-Type: application/json" \
  -d '{"first_name": "Updated", "last_name": "Name"}'

# Test DELETE endpoint
curl -X DELETE "http://localhost:8000/api/v1/employees/$EMPLOYEE_UUID"
```

## ✅ Success Criteria

- [ ] All 3 endpoints accept UUID employee_id (not int)
- [ ] Pydantic models use UUID type correctly  
- [ ] Database queries use employees table (not agents)
- [ ] Error handling returns 404 for invalid UUIDs
- [ ] Russian employee names display correctly
- [ ] Integration tests pass with real UUIDs

## 🧪 Verification Commands

```bash
# Test 1: Valid UUID should work
curl "http://localhost:8000/api/v1/employees/0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212"
# Expected: Returns employee data

# Test 2: Invalid UUID should return 404  
curl "http://localhost:8000/api/v1/employees/00000000-0000-0000-0000-000000000000"
# Expected: 404 Not Found

# Test 3: Invalid format should return 422
curl "http://localhost:8000/api/v1/employees/123"
# Expected: 422 Validation Error

# Test 4: Russian names should display
curl "http://localhost:8000/api/v1/employees/uuid" | grep "Иван"
# Expected: Russian names properly encoded
```

## 📊 Files to Modify

1. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_get_REAL.py`
2. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_update_REAL.py`  
3. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/employee_delete_REAL.py`

## 📊 Progress Update
```bash
echo "ENDPOINT_FIX_001: Complete - Employee CRUD endpoints fixed for UUID" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

- **Import Error**: Add `from uuid import UUID` at top of file
- **Validation Error**: Ensure path parameter uses `employee_id: UUID`
- **Database Error**: Verify using `employees` table not `agents` table
- **404 Errors**: Check employee exists in employees table with UUID

## 🎯 Expected Output

After completion:
- 3 endpoint files updated with UUID support
- All endpoints tested and working with real employee UUIDs
- Error handling properly implemented
- Russian text support confirmed
- Progress logged to tracking system

**SUCCESS PATTERN**: Apply this same UUID fix pattern to all remaining 70 endpoints!