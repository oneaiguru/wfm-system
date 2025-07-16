# 📋 SUBAGENT TASK: Fix Endpoint UUID Compliance 002

## 🎯 Task Information
- **Task ID**: FIX_ENDPOINT_002
- **Priority**: Critical
- **Estimated Time**: 15 minutes
- **Dependencies**: Database schema, vacation_requests table
- **Pattern**: Apply vacation request UUID fix success

## 📊 Assigned Endpoints
1. GET /api/v1/requests/pending - `requests_pending_REAL.py`
2. PUT /api/v1/requests/approve/{id} - `requests_approve_REAL.py`
3. GET /api/v1/requests/vacation/employee/{employee_id} - `vacation_requests_REAL.py`

## 🔧 Fix Pattern (From Vacation Request Success)

### Current Problem:
```python
# ❌ BROKEN: Mixed int/UUID handling
@router.get("/requests/pending")
async def get_pending_requests():
    # Joins employee_requests with agents (int IDs)
    # Should join vacation_requests with employees (UUID IDs)
```

### Required Fix:
```python
# ✅ FIXED: Use proper UUID relationships
@router.get("/requests/pending")
async def get_pending_requests(db: AsyncSession = Depends(get_db)):
    query = text("""
        SELECT 
            vr.id as request_id,
            vr.employee_id,
            CONCAT(e.first_name, ' ', e.last_name) as employee_name,
            vr.request_type,
            vr.start_date,
            vr.end_date,
            (vr.end_date - vr.start_date + 1) as duration_days,
            vr.created_at,
            vr.status,
            vr.reason
        FROM vacation_requests vr
        JOIN employees e ON vr.employee_id = e.id
        WHERE vr.status = 'pending'
        ORDER BY vr.created_at DESC
    """)
    
    result = await db.execute(query)
    return [dict(row._mapping) for row in result.fetchall()]
```

## 📝 Step-by-Step Instructions

### Step 1: Check Current Table Usage
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('vacation_requests', 'employee_requests', 'employees', 'agents')
AND column_name LIKE '%employee%';"
```

### Step 2: Update Pending Requests Endpoint
```python
# File: requests_pending_REAL.py
# Change query to use vacation_requests + employees (UUID relationship)

query = text("""
    SELECT 
        vr.id as request_id,
        vr.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        vr.request_type,
        vr.start_date,
        vr.end_date,
        (vr.end_date - vr.start_date + 1) as duration_days,
        vr.created_at as submitted_at,
        vr.status,
        vr.reason
    FROM vacation_requests vr
    JOIN employees e ON vr.employee_id = e.id
    WHERE vr.status = 'pending'
    ORDER BY vr.created_at DESC
""")
```

### Step 3: Update Approval Endpoint
```python
# File: requests_approve_REAL.py
from uuid import UUID

@router.put("/requests/approve/{request_id}")
async def approve_request(
    request_id: int,  # vacation_requests.id is int
    approval_data: dict,
    db: AsyncSession = Depends(get_db)
):
    # Update vacation_requests table (not employee_requests)
    query = text("""
        UPDATE vacation_requests 
        SET status = :status, 
            updated_at = NOW()
        WHERE id = :request_id
        RETURNING id, employee_id, status
    """)
    
    result = await db.execute(query, {
        "request_id": request_id,
        "status": "approved" if approval_data.get("action") == "approve" else "rejected"
    })
    
    updated_request = result.fetchone()
    if not updated_request:
        raise HTTPException(404, "Vacation request not found")
    
    await db.commit()
    return {"request_id": updated_request.id, "status": updated_request.status}
```

### Step 4: Fix Employee Vacation History
```python
# File: vacation_requests_REAL.py (already mostly fixed)
# Ensure employee_id parameter is UUID type

@router.get("/requests/vacation/employee/{employee_id}")
async def get_employee_vacation_requests(
    employee_id: UUID,  # ✅ Already fixed to UUID
    db: AsyncSession = Depends(get_db)
):
    # Query is already correct - uses vacation_requests + employees
```

### Step 5: Test All Endpoints
```bash
# Test 1: Pending requests should show vacation requests
curl "http://localhost:8000/api/v1/requests/pending"
# Expected: Shows pending vacation requests with employee names

# Test 2: Approve request should work
REQUEST_ID=$(curl -s "http://localhost:8000/api/v1/requests/pending" | jq -r '.[0].request_id')
curl -X PUT "http://localhost:8000/api/v1/requests/approve/$REQUEST_ID" \
  -H "Content-Type: application/json" \
  -d '{"action": "approve", "comments": "Одобрено"}'
# Expected: Request status updated to approved

# Test 3: Employee vacation history with UUID
EMPLOYEE_UUID="0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212"
curl "http://localhost:8000/api/v1/requests/vacation/employee/$EMPLOYEE_UUID"
# Expected: Shows employee's vacation request history
```

## ✅ Success Criteria

- [ ] Pending requests endpoint shows vacation_requests (not employee_requests)
- [ ] Employee names display correctly with Russian text
- [ ] Approval endpoint updates vacation_requests table
- [ ] Employee vacation history uses UUID employee_id
- [ ] All joins use employees table (not agents table)
- [ ] Date calculations work correctly (duration_days)

## 🧪 Verification Commands

```bash
# Test 1: Check pending requests data source
curl -s "http://localhost:8000/api/v1/requests/pending" | jq '.[0]'
# Expected: Contains vacation request fields (start_date, end_date, reason)

# Test 2: Verify employee names are Russian
curl -s "http://localhost:8000/api/v1/requests/pending" | jq '.[].employee_name'
# Expected: Shows names like "Иван Иванов"

# Test 3: Test approval workflow
curl -s "http://localhost:8000/api/v1/requests/pending" | jq '.[0].request_id' | \
xargs -I {} curl -X PUT "http://localhost:8000/api/v1/requests/approve/{}" \
  -H "Content-Type: application/json" -d '{"action": "approve"}'
# Expected: Returns success with updated status

# Test 4: Verify database consistency
psql -U postgres -d wfm_enterprise -c "
SELECT vr.id, vr.status, e.first_name, e.last_name 
FROM vacation_requests vr 
JOIN employees e ON vr.employee_id = e.id 
WHERE vr.status = 'approved' 
ORDER BY vr.updated_at DESC LIMIT 5;"
# Expected: Shows approved requests with employee names
```

## 📊 Files to Modify

1. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/requests_pending_REAL.py`
2. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/requests_approve_REAL.py`
3. `/Users/m/Documents/wfm/main/project/src/api/v1/endpoints/vacation_requests_REAL.py` (verify existing fix)

## 📊 Progress Update
```bash
echo "ENDPOINT_FIX_002: Complete - Request management endpoints fixed for UUID" >> /Users/m/Documents/wfm/main/project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

- **Empty Results**: Check vacation_requests table has data, not just employee_requests
- **Join Errors**: Verify using employees table (UUID) not agents table (int)
- **Russian Text Issues**: Ensure proper UTF-8 encoding in database queries
- **Approval Fails**: Check request_id exists in vacation_requests table

## 🎯 Expected Output

After completion:
- Pending requests show real vacation requests with employee names
- Approval workflow updates correct table (vacation_requests)
- All employee relationships use UUID-based employees table
- Russian names display correctly throughout
- Complete vacation request workflow functional

**KEY INSIGHT**: This fixes the core request management flow to use the correct UUID-based tables!