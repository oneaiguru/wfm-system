"""
REAL PENDING REQUESTS ENDPOINT - DATABASE QUERY
Gets all pending vacation requests from employee_requests table
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List
from datetime import datetime, date
from uuid import UUID

from ...core.database import get_db

router = APIRouter()

class PendingRequest(BaseModel):
    request_id: str
    employee_id: str  # UUID as string
    employee_name: str
    request_type: str
    start_date: date
    end_date: date
    duration_days: int
    submitted_at: datetime
    status: str
    reason: str

@router.get("/requests/pending", response_model=List[PendingRequest], tags=["🔥 REAL Requests"])
async def get_pending_requests(
    db: AsyncSession = Depends(get_db)
):
    """
    REAL PENDING REQUESTS - QUERIES DATABASE!
    
    Gets all vacation_requests WHERE status = 'pending'
    Returns real vacation requests from PostgreSQL using UUID relationships
    """
    try:
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
        
        result = await db.execute(query)
        pending_requests = []
        
        for row in result.fetchall():
            pending_requests.append(PendingRequest(
                request_id=str(row.request_id),
                employee_id=str(row.employee_id),  # UUID to string
                employee_name=row.employee_name or f"Employee {row.employee_id}",
                request_type=row.request_type,
                start_date=row.start_date,
                end_date=row.end_date,
                duration_days=row.duration_days,
                submitted_at=row.submitted_at,
                status=row.status,
                reason=row.reason or ""
            ))
        
        return pending_requests
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get pending requests: {str(e)}"
        )

"""
ENDPOINT 11 COMPLETE!
Test: curl http://localhost:8000/api/v1/requests/pending
"""