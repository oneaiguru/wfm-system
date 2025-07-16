"""
REAL EMPLOYEE TIME OFF REQUEST ENDPOINT - Task 23
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import date

from ...core.database import get_db

router = APIRouter()

class TimeOffRequest(BaseModel):
    start_date: date
    end_date: date
    time_off_type: str  # 'vacation', 'sick_leave', 'personal', 'comp_time'
    reason: Optional[str] = None
    is_paid: bool = True

@router.post("/employees/{employee_id}/time-off/request", tags=["🔥 REAL Employee Time Off"])
async def create_time_off_request(
    employee_id: UUID,
    time_off: TimeOffRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TIME OFF REQUEST - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Calculate days
        days_requested = (time_off.end_date - time_off.start_date).days + 1
        
        # Insert time off request
        insert_query = text("""
            INSERT INTO employee_time_off_requests 
            (employee_id, start_date, end_date, time_off_type, reason, is_paid, 
             days_requested, status)
            VALUES 
            (:employee_id, :start_date, :end_date, :time_off_type, :reason, :is_paid,
             :days_requested, 'pending')
            RETURNING id, created_at
        """)
        
        result = await db.execute(insert_query, {
            'employee_id': employee_id,
            'start_date': time_off.start_date,
            'end_date': time_off.end_date,
            'time_off_type': time_off.time_off_type,
            'reason': time_off.reason,
            'is_paid': time_off.is_paid,
            'days_requested': days_requested
        })
        
        request_record = result.fetchone()
        await db.commit()
        
        return {
            "request_id": str(request_record.id),
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "time_off_type": time_off.time_off_type,
            "start_date": time_off.start_date.isoformat(),
            "end_date": time_off.end_date.isoformat(),
            "days_requested": days_requested,
            "is_paid": time_off.is_paid,
            "status": "pending",
            "created_at": request_record.created_at.isoformat(),
            "message": f"Time off request created for {days_requested} days"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create time off request: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TIME OFF REQUEST ENDPOINT
"""