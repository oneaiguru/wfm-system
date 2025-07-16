"""
REAL EMPLOYEE TRAINING ENROLLMENT ENDPOINT - Task 18
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

class TrainingEnrollmentRequest(BaseModel):
    training_name: str
    training_type: str  # 'mandatory', 'optional', 'skill_development'
    start_date: date
    end_date: Optional[date] = None
    trainer_id: Optional[UUID] = None
    enrollment_notes: Optional[str] = None

class TrainingEnrollmentResponse(BaseModel):
    enrollment_id: str
    employee_id: str
    training_name: str
    status: str
    start_date: str
    message: str

@router.post("/employees/{employee_id}/training/enroll", response_model=TrainingEnrollmentResponse, tags=["🔥 REAL Employee Training"])
async def enroll_employee_training(
    employee_id: UUID,
    enrollment: TrainingEnrollmentRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TRAINING ENROLLMENT - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Insert training enrollment
        insert_query = text("""
            INSERT INTO employee_training_records 
            (employee_id, training_name, training_type, status, start_date, end_date, 
             trainer_id, enrollment_notes)
            VALUES 
            (:employee_id, :training_name, :training_type, 'enrolled', :start_date, :end_date,
             :trainer_id, :enrollment_notes)
            RETURNING id
        """)
        
        result = await db.execute(insert_query, {
            'employee_id': employee_id,
            'training_name': enrollment.training_name,
            'training_type': enrollment.training_type,
            'start_date': enrollment.start_date,
            'end_date': enrollment.end_date,
            'trainer_id': enrollment.trainer_id,
            'enrollment_notes': enrollment.enrollment_notes
        })
        
        enrollment_record = result.fetchone()
        await db.commit()
        
        return TrainingEnrollmentResponse(
            enrollment_id=str(enrollment_record.id),
            employee_id=str(employee_id),
            training_name=enrollment.training_name,
            status="enrolled",
            start_date=enrollment.start_date.isoformat(),
            message=f"Successfully enrolled {employee.first_name} {employee.last_name} in {enrollment.training_name}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to enroll in training: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TRAINING ENROLLMENT ENDPOINT
"""