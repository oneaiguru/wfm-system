from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List
from uuid import UUID
from ...core.database import get_db

router = APIRouter()

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