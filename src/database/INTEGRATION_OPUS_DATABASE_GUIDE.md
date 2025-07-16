# 📚 DATABASE GUIDE FOR INTEGRATION-OPUS

## 🚨 CRITICAL: UUID vs Integer Issue

**THE PROBLEM:**
```python
# ❌ WRONG - This is why vacation requests fail
class VacationRequest(BaseModel):
    employee_id: int  # DATABASE HAS UUID, NOT INT!
```

**THE FIX:**
```python
# ✅ CORRECT - Matches database schema
from uuid import UUID

class VacationRequest(BaseModel):
    employee_id: UUID  # Now matches database
    start_date: date
    end_date: date
```

## 📊 Database Reality Check

### Current Data Available:
- **20 employees** with Russian names (Иван, Петр, Мария)
- **Employee IDs are UUIDs** like `ead4aaaf-5fcf-4661-aa08-cef7d9132b86`
- **Vacation requests table** ready with proper foreign keys
- **Test data** available in `integration_test_data` table

### Run This First:
```bash
# See actual employee data structure
psql -U postgres -d wfm_enterprise -c "SELECT id, first_name, last_name, email FROM employees LIMIT 3"

# See API contracts
psql -U postgres -d wfm_enterprise -f /Users/m/Documents/wfm/main/project/src/database/scripts/show_api_contracts.sql
```

## 🔧 Correct API Implementation

### 1. Employee List Endpoint
```python
from fastapi import APIRouter, Depends
from sqlalchemy import text
from uuid import UUID
from typing import List

router = APIRouter()

@router.get("/api/v1/employees")
async def get_employees(db: Session = Depends(get_db)) -> List[dict]:
    """Get all employees for dropdown selection"""
    
    # Query matches what's actually in database
    result = db.execute(text("""
        SELECT 
            id::text as id,  -- Convert UUID to string for JSON
            first_name || ' ' || last_name as name,
            email
        FROM employees
        ORDER BY last_name, first_name
    """))
    
    employees = []
    for row in result:
        employees.append({
            "id": row.id,  # UUID as string
            "name": row.name,  # Combined name
            "email": row.email
        })
    
    return employees
```

### 2. Vacation Request Endpoint (Fixed)
```python
from pydantic import BaseModel
from uuid import UUID
from datetime import date

class VacationRequestCreate(BaseModel):
    employee_id: UUID  # FIXED: Was int, now UUID
    start_date: date
    end_date: date

    class Config:
        # This allows UUID serialization
        json_encoders = {
            UUID: str
        }

@router.post("/api/v1/requests/vacation")
async def create_vacation_request(
    request: VacationRequestCreate,
    db: Session = Depends(get_db)
):
    # Validate employee exists
    employee_check = db.execute(
        text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id"),
        {"employee_id": request.employee_id}
    ).first()
    
    if not employee_check:
        raise HTTPException(404, f"Employee {request.employee_id} not found")
    
    # Insert vacation request
    result = db.execute(
        text("""
            INSERT INTO vacation_requests 
            (employee_id, start_date, end_date, status, request_type, created_at)
            VALUES 
            (:employee_id, :start_date, :end_date, 'pending', 'отпуск', NOW())
            RETURNING id, status
        """),
        {
            "employee_id": request.employee_id,
            "start_date": request.start_date,
            "end_date": request.end_date
        }
    )
    
    vacation_request = result.first()
    db.commit()
    
    return {
        "id": vacation_request.id,
        "employee_id": str(request.employee_id),
        "employee_name": f"{employee_check.first_name} {employee_check.last_name}",
        "start_date": request.start_date.isoformat(),
        "end_date": request.end_date.isoformat(),
        "status": vacation_request.status,
        "message": "Заявка на отпуск создана успешно"
    }
```

## 📋 Database Schema Reference

### employees table:
```sql
Column          Type        Description
---------       ------      -----------
id              UUID        Primary key (NOT integer!)
first_name      VARCHAR     Russian names supported
last_name       VARCHAR     Russian names supported
patronymic      VARCHAR     Отчество (optional)
email           VARCHAR     Employee email
```

### vacation_requests table:
```sql
Column          Type        Description
---------       ------      -----------
id              INTEGER     Auto-increment primary key
employee_id     UUID        Foreign key to employees(id)
start_date      DATE        YYYY-MM-DD format
end_date        DATE        YYYY-MM-DD format
status          VARCHAR     pending|approved|rejected|cancelled
request_type    VARCHAR     отпуск|больничный|отгул|etc
```

## 🧪 Testing Your API

### Test with Real Employee ID:
```bash
# Get real employee ID first
EMPLOYEE_ID=$(psql -U postgres -d wfm_enterprise -t -c "SELECT id FROM employees WHERE first_name='Иван' LIMIT 1" | tr -d ' ')

# Test vacation request with real UUID
curl -X POST http://localhost:8000/api/v1/requests/vacation \
  -H "Content-Type: application/json" \
  -d "{
    \"employee_id\": \"$EMPLOYEE_ID\",
    \"start_date\": \"2025-02-01\",
    \"end_date\": \"2025-02-07\"
  }"
```

### Expected Success Response:
```json
{
  "id": 123,
  "employee_id": "ead4aaaf-5fcf-4661-aa08-cef7d9132b86",
  "employee_name": "Иван Иванов",
  "start_date": "2025-02-01",
  "end_date": "2025-02-07",
  "status": "pending",
  "message": "Заявка на отпуск создана успешно"
}
```

## ❌ Common Mistakes to Avoid

1. **Using integer for employee_id** - Database uses UUID
2. **Hardcoding test data** - Use real employees from database
3. **Ignoring Russian text** - Set UTF-8 encoding
4. **Wrong date format** - Use YYYY-MM-DD
5. **Invalid status values** - Use: pending, approved, rejected, cancelled

## 📊 Integration Test Data

We have test data ready in `integration_test_data` table:
- Test employee: `550e8400-e29b-41d4-a716-446655440000` (Иван Петров)
- Test vacation request scenarios
- Expected API responses

## 🔄 Continuous Validation

Run this to check your API matches database:
```bash
psql -U postgres -d wfm_enterprise -f /Users/m/Documents/wfm/main/project/src/database/scripts/validate_bdd_integration.sql
```

## 💡 Key Takeaways

1. **Always check database schema first** before defining API models
2. **Use UUID type for employee_id**, not integer
3. **Test with real data** from the database
4. **Support Russian text** throughout
5. **Follow the vacation request example** for other endpoints

The database is ready with 706 tables and real data. Your API just needs to connect properly!