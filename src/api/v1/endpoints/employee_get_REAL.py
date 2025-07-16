from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import Optional
from datetime import date
from uuid import UUID
from ...core.database import get_db

router = APIRouter()

class EmployeeDetail(BaseModel):
    id: str
    employee_number: str
    first_name: str
    last_name: str
    full_name: str
    email: Optional[str]
    employment_type: Optional[str]
    hire_date: Optional[date]
    is_active: bool
    time_zone: Optional[str]
    work_rate: Optional[float]
    patronymic: Optional[str]

@router.get("/employees/{employee_id}", response_model=EmployeeDetail, tags=["🔥 REAL Employees"])
async def get_employee(employee_id: UUID, db: AsyncSession = Depends(get_db)):
    """Get single employee details by ID"""
    
    # Query employees table with UUID
    query = text("""
        SELECT 
            id,
            employee_number,
            first_name,
            last_name,
            CONCAT(first_name, ' ', last_name) as full_name,
            email,
            employment_type,
            hire_date,
            is_active,
            time_zone,
            work_rate,
            patronymic
        FROM employees
        WHERE id = :employee_id
    """)
    
    result = await db.execute(query, {"employee_id": employee_id})
    employee = result.fetchone()
    
    if not employee:
        raise HTTPException(
            status_code=404,
            detail=f"Employee {employee_id} not found in employees table"
        )
    
    # Convert row to dict and return
    employee_dict = dict(employee._mapping)
    employee_dict["id"] = str(employee_dict["id"])
    return EmployeeDetail(**employee_dict)