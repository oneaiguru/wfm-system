from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date
from uuid import UUID
from ...core.database import get_db

router = APIRouter()

class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    employee_number: Optional[str] = None
    is_active: Optional[bool] = None
    employment_type: Optional[str] = None
    time_zone: Optional[str] = None
    work_rate: Optional[float] = None
    patronymic: Optional[str] = None

class EmployeeUpdateResponse(BaseModel):
    id: str
    employee_number: str
    first_name: str
    last_name: str
    email: Optional[str]
    employment_type: Optional[str]
    is_active: bool
    updated_fields: list[str]

@router.put("/employees/{employee_id}", response_model=EmployeeUpdateResponse, tags=["🔥 REAL Employees"])
async def update_employee(employee_id: UUID, updates: EmployeeUpdate, db: AsyncSession = Depends(get_db)):
    """Update employee details"""
    
    # Build dynamic update query
    update_fields = []
    params = {"employee_id": employee_id}
    
    update_data = updates.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    for field, value in update_data.items():
        update_fields.append(f"{field} = :{field}")
        params[field] = value
    
    # Update query with RETURNING
    update_query = text(f"""
        UPDATE employees
        SET {', '.join(update_fields)}, updated_at = now()
        WHERE id = :employee_id
        RETURNING id, employee_number, first_name, last_name, email, employment_type, is_active
    """)
    
    result = await db.execute(update_query, params)
    updated_employee = result.fetchone()
    
    if not updated_employee:
        raise HTTPException(
            status_code=404,
            detail=f"Employee {employee_id} not found in employees table"
        )
    
    await db.commit()
    
    # Return response
    response_data = dict(updated_employee._mapping)
    response_data["id"] = str(response_data["id"])
    response_data["updated_fields"] = list(update_data.keys())
    
    return EmployeeUpdateResponse(**response_data)