"""
UUID-BASED EMPLOYEES ENDPOINT
Provides employees with UUID IDs for vacation requests and other UUID-based operations
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from uuid import UUID
from typing import List

from ...core.database import get_db

router = APIRouter()

@router.get("/employees/uuid", tags=["🔥 REAL Employees"])
async def get_employees_uuid(db: AsyncSession = Depends(get_db)):
    """
    Get employees with UUID IDs for vacation requests
    
    This endpoint returns employees from the UUID-based employees table
    (not the integer-based agents table) for use with vacation_requests
    and other UUID-based operations.
    """
    try:
        query = text("""
            SELECT 
                id,
                first_name,
                last_name,
                employee_number,
                CONCAT(first_name, ' ', last_name) as full_name
            FROM employees
            ORDER BY last_name, first_name
        """)
        
        result = await db.execute(query)
        employees = []
        
        for row in result.fetchall():
            employees.append({
                "id": str(row.id),  # Convert UUID to string for JSON
                "employee_number": row.employee_number,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "full_name": row.full_name
            })
        
        return employees
        
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get employees: {str(e)}"
        )

@router.get("/employees/uuid/{employee_id}", tags=["🔥 REAL Employees"])
async def get_employee_uuid(
    employee_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get single employee by UUID"""
    try:
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
            from fastapi import HTTPException
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
        
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get employee: {str(e)}"
        )

"""
STATUS: ✅ UUID EMPLOYEES ENDPOINT READY

PROVIDES:
- GET /api/v1/employees/uuid - All employees with UUID IDs
- GET /api/v1/employees/uuid/{id} - Single employee by UUID

FOR VACATION REQUESTS:
- UI can load dropdown with UUID employees
- Vacation request endpoint can validate UUIDs
- Real database integration with proper types
"""