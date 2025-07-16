"""
REAL EMPLOYEE TRAINING RECORDS GET ENDPOINT - Task 17
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID

from ...core.database import get_db

router = APIRouter()

class TrainingRecord(BaseModel):
    training_id: str
    training_name: str
    training_type: str
    status: str
    completion_date: Optional[str]
    score: Optional[float]
    certificate_number: Optional[str]

@router.get("/employees/{employee_id}/training/records", tags=["🔥 REAL Employee Training"])
async def get_employee_training_records(
    employee_id: UUID,
    status: Optional[str] = None,
    training_type: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TRAINING RECORDS - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Build query
        where_conditions = ["etr.employee_id = :employee_id"]
        params = {"employee_id": employee_id}
        
        if status:
            where_conditions.append("etr.status = :status")
            params["status"] = status
            
        if training_type:
            where_conditions.append("etr.training_type = :training_type")
            params["training_type"] = training_type
        
        where_clause = " AND ".join(where_conditions)
        
        query = text(f"""
            SELECT etr.id, etr.training_name, etr.training_type, etr.status,
                   etr.completion_date, etr.score, etr.certificate_number
            FROM employee_training_records etr
            WHERE {where_clause}
            ORDER BY etr.completion_date DESC NULLS LAST
        """)
        
        result = await db.execute(query, params)
        records = []
        
        for row in result.fetchall():
            records.append(TrainingRecord(
                training_id=str(row.id),
                training_name=row.training_name,
                training_type=row.training_type,
                status=row.status,
                completion_date=row.completion_date.isoformat() if row.completion_date else None,
                score=row.score,
                certificate_number=row.certificate_number
            ))
        
        return {
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "total_records": len(records),
            "training_records": records
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get training records: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TRAINING RECORDS GET ENDPOINT
"""