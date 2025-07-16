"""
REAL EMPLOYEE PERFORMANCE HISTORY ENDPOINT - Task 16
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

class PerformanceHistoryEntry(BaseModel):
    period_start: str
    period_end: str
    overall_score: float
    evaluation_type: str
    key_achievements: List[str]
    improvement_areas: List[str]

@router.get("/employees/{employee_id}/performance/history", tags=["🔥 REAL Employee Performance"])
async def get_employee_performance_history(
    employee_id: UUID,
    years: int = 2,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE PERFORMANCE HISTORY - NO MOCKS!
    """
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Get performance history
        query = text("""
            SELECT evaluation_period_start, evaluation_period_end, overall_score, 
                   evaluation_type, strengths, improvement_areas
            FROM employee_performance_evaluations
            WHERE employee_id = :employee_id 
            AND evaluation_period_start >= CURRENT_DATE - INTERVAL '%s years'
            ORDER BY evaluation_period_end DESC
        """ % years)
        
        result = await db.execute(query, {"employee_id": employee_id})
        history = []
        
        for row in result.fetchall():
            history.append(PerformanceHistoryEntry(
                period_start=row.evaluation_period_start.isoformat(),
                period_end=row.evaluation_period_end.isoformat(),
                overall_score=row.overall_score,
                evaluation_type=row.evaluation_type,
                key_achievements=row.strengths or ["Нет данных"],
                improvement_areas=row.improvement_areas or ["Нет данных"]
            ))
        
        return {
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "history": history
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE PERFORMANCE HISTORY ENDPOINT
"""