from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from uuid import UUID
from ...core.database import get_db

router = APIRouter()

class DeleteResponse(BaseModel):
    id: str
    employee_number: str
    first_name: str
    last_name: str
    is_active: bool
    message: str

@router.delete("/employees/{employee_id}", response_model=DeleteResponse, tags=["🔥 REAL Employees"])
async def delete_employee(employee_id: UUID, db: AsyncSession = Depends(get_db)):
    """Soft delete employee (set is_active = false)"""
    
    # Soft delete query with RETURNING
    delete_query = text("""
        UPDATE employees
        SET is_active = false, updated_at = now()
        WHERE id = :employee_id AND is_active = true
        RETURNING id, employee_number, first_name, last_name, is_active
    """)
    
    result = await db.execute(delete_query, {"employee_id": employee_id})
    deleted_employee = result.fetchone()
    
    if not deleted_employee:
        raise HTTPException(
            status_code=404,
            detail=f"Employee {employee_id} not found or already deleted in employees table"
        )
    
    await db.commit()
    
    # Return response
    response_data = dict(deleted_employee._mapping)
    response_data["id"] = str(response_data["id"])
    response_data["message"] = f"Employee {employee_id} successfully deactivated"
    
    return DeleteResponse(**response_data)