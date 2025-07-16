"""
REAL APPROVE REQUEST ENDPOINT - DATABASE UPDATE
Updates vacation request status from 'Создана' to 'Одобрена'
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime
from uuid import UUID

from ...core.database import get_db

router = APIRouter()

class ApprovalResponse(BaseModel):
    request_id: str
    status: str
    message: str
    approved_at: datetime

@router.put("/requests/approve/{request_id}", response_model=ApprovalResponse, tags=["🔥 REAL Requests"])
async def approve_request(
    request_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL REQUEST APPROVAL - UPDATES DATABASE!
    
    Updates vacation_requests status to 'approved' 
    Records approval timestamp using UUID relationships
    """
    try:
        # First check if request exists and is pending
        check_query = text("""
            SELECT id, status, employee_id, start_date, end_date
            FROM vacation_requests
            WHERE id = :request_id
        """)
        
        result = await db.execute(check_query, {"request_id": request_id})
        request = result.fetchone()
        
        if not request:
            raise HTTPException(status_code=404, detail="Request not found")
        
        if request.status != 'pending':
            raise HTTPException(
                status_code=400, 
                detail=f"Request is already {request.status}. Only pending requests can be approved."
            )
        
        # Update the request status
        update_query = text("""
            UPDATE vacation_requests
            SET status = 'approved', 
                updated_at = NOW()
            WHERE id = :request_id
            RETURNING id, status
        """)
        
        approved_at = datetime.now()
        result = await db.execute(update_query, {
            "request_id": request_id
        })
        
        updated = result.fetchone()
        await db.commit()
        
        return ApprovalResponse(
            request_id=str(updated.id),
            status=updated.status,
            message=f"Request approved successfully. Vacation from {request.start_date} to {request.end_date}.",
            approved_at=approved_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to approve request: {str(e)}"
        )

"""
ENDPOINT 12 COMPLETE!
Test: curl -X PUT http://localhost:8000/api/v1/requests/approve/[request_id]
"""