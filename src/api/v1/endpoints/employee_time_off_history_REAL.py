"""
REAL EMPLOYEE TIME OFF HISTORY ENDPOINT - Task 24
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import date

from ...core.database import get_db

router = APIRouter()

class TimeOffHistoryEntry(BaseModel):
    request_id: str
    start_date: str
    end_date: str
    time_off_type: str
    days_requested: int
    status: str
    is_paid: bool
    reason: Optional[str]
    approved_by: Optional[str]
    created_at: str

@router.get("/employees/{employee_id}/time-off/history", tags=["🔥 REAL Employee Time Off"])
async def get_employee_time_off_history(
    employee_id: UUID,
    year: Optional[int] = None,
    time_off_type: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = 50,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TIME OFF HISTORY - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Build query conditions
        where_conditions = ["etor.employee_id = :employee_id"]
        params = {"employee_id": employee_id, "limit": limit}
        
        if year:
            where_conditions.append("EXTRACT(YEAR FROM etor.start_date) = :year")
            params["year"] = year
            
        if time_off_type:
            where_conditions.append("etor.time_off_type = :time_off_type")
            params["time_off_type"] = time_off_type
            
        if status:
            where_conditions.append("etor.status = :status")
            params["status"] = status
        
        where_clause = " AND ".join(where_conditions)
        
        # Get time off history
        history_query = text(f"""
            SELECT 
                etor.id, etor.start_date, etor.end_date, etor.time_off_type,
                etor.days_requested, etor.status, etor.is_paid, etor.reason,
                etor.created_at,
                e_approver.first_name as approver_first_name,
                e_approver.last_name as approver_last_name
            FROM employee_time_off_requests etor
            LEFT JOIN employees e_approver ON etor.approved_by = e_approver.id
            WHERE {where_clause}
            ORDER BY etor.start_date DESC
            LIMIT :limit
        """)
        
        result = await db.execute(history_query, params)
        history = []
        
        total_days_requested = 0
        total_days_approved = 0
        
        for row in result.fetchall():
            approver_name = None
            if row.approver_first_name and row.approver_last_name:
                approver_name = f"{row.approver_first_name} {row.approver_last_name}"
            
            total_days_requested += row.days_requested
            if row.status == 'approved':
                total_days_approved += row.days_requested
            
            history.append(TimeOffHistoryEntry(
                request_id=str(row.id),
                start_date=row.start_date.isoformat(),
                end_date=row.end_date.isoformat(),
                time_off_type=row.time_off_type,
                days_requested=row.days_requested,
                status=row.status,
                is_paid=row.is_paid,
                reason=row.reason,
                approved_by=approver_name,
                created_at=row.created_at.isoformat()
            ))
        
        return {
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "filter_year": year,
            "filter_type": time_off_type,
            "filter_status": status,
            "total_requests": len(history),
            "total_days_requested": total_days_requested,
            "total_days_approved": total_days_approved,
            "history": history
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get time off history: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TIME OFF HISTORY ENDPOINT
"""