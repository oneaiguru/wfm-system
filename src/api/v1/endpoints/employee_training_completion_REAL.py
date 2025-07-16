"""
REAL EMPLOYEE TRAINING COMPLETION ENDPOINT - Task 19
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

class TrainingCompletionRequest(BaseModel):
    training_id: UUID
    completion_date: date
    score: Optional[float] = None
    certificate_number: Optional[str] = None
    completion_notes: Optional[str] = None
    passed: bool = True

@router.post("/employees/{employee_id}/training/complete", tags=["🔥 REAL Employee Training"])
async def complete_employee_training(
    employee_id: UUID,
    completion: TrainingCompletionRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TRAINING COMPLETION - NO MOCKS!"""
    try:
        # Validate and update training record
        update_query = text("""
            UPDATE employee_training_records 
            SET status = :status, completion_date = :completion_date, score = :score,
                certificate_number = :certificate_number, completion_notes = :completion_notes
            WHERE id = :training_id AND employee_id = :employee_id
            RETURNING id, training_name
        """)
        
        status = 'completed' if completion.passed else 'failed'
        
        result = await db.execute(update_query, {
            'training_id': completion.training_id,
            'employee_id': employee_id,
            'status': status,
            'completion_date': completion.completion_date,
            'score': completion.score,
            'certificate_number': completion.certificate_number,
            'completion_notes': completion.completion_notes
        })
        
        updated_record = result.fetchone()
        if not updated_record:
            raise HTTPException(status_code=404, detail="Training record not found")
        
        await db.commit()
        
        return {
            "training_id": str(completion.training_id),
            "employee_id": str(employee_id),
            "training_name": updated_record.training_name,
            "status": status,
            "completion_date": completion.completion_date.isoformat(),
            "score": completion.score,
            "certificate_number": completion.certificate_number,
            "message": f"Training {'completed successfully' if completion.passed else 'marked as failed'}"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to complete training: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TRAINING COMPLETION ENDPOINT
"""