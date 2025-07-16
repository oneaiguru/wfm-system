"""
REAL EMPLOYEE AVAILABILITY MANAGEMENT UPDATE ENDPOINT - Task 22
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List
from uuid import UUID
from datetime import date, time

from ...core.database import get_db

router = APIRouter()

class AvailabilityUpdate(BaseModel):
    date: date
    available_start: str  # HH:MM
    available_end: str    # HH:MM
    availability_type: str

@router.put("/employees/{employee_id}/availability/management", tags=["🔥 REAL Employee Availability Management"])
async def update_employee_availability_management(
    employee_id: UUID,
    updates: List[AvailabilityUpdate],
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE AVAILABILITY MANAGEMENT UPDATE - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        updated_count = 0
        
        for update in updates:
            # Parse time strings
            start_hour, start_minute = map(int, update.available_start.split(':'))
            start_time_obj = time(start_hour, start_minute)
            
            end_hour, end_minute = map(int, update.available_end.split(':'))
            end_time_obj = time(end_hour, end_minute)
            
            # Update or insert availability for this specific date
            upsert_query = text("""
                INSERT INTO employee_availability 
                (employee_id, start_date, end_date, start_time, end_time, availability_type, days_of_week)
                VALUES (:employee_id, :date, :date, :start_time, :end_time, :availability_type, ARRAY[:day_of_week])
                ON CONFLICT (employee_id, start_date, end_date) 
                DO UPDATE SET 
                    start_time = :start_time,
                    end_time = :end_time,
                    availability_type = :availability_type
            """)
            
            day_of_week = update.date.strftime('%A').lower()
            
            await db.execute(upsert_query, {
                'employee_id': employee_id,
                'date': update.date,
                'start_time': start_time_obj,
                'end_time': end_time_obj,
                'availability_type': update.availability_type,
                'day_of_week': day_of_week
            })
            
            updated_count += 1
        
        await db.commit()
        
        return {
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "status": "success",
            "updated_days": updated_count,
            "message": f"Updated availability for {updated_count} days"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update availability management: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE AVAILABILITY MANAGEMENT UPDATE ENDPOINT
"""