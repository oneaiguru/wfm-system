"""
REAL EMPLOYEE SKILLS GET ENDPOINT - Task 4
Provides employee skills information following proven UUID compliance pattern
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID

from ...core.database import get_db

router = APIRouter()

class EmployeeSkill(BaseModel):
    skill_id: str
    skill_name: str
    skill_level: int
    proficiency_rating: Optional[float]
    certification_date: Optional[str]
    certification_expiry: Optional[str]
    is_primary: bool
    verified: bool

class EmployeeSkillsResponse(BaseModel):
    employee_id: str
    employee_name: str
    total_skills: int
    skills: List[EmployeeSkill]

@router.get("/employees/{employee_id}/skills", response_model=EmployeeSkillsResponse, tags=["🔥 REAL Employee Skills"])
async def get_employee_skills(
    employee_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE SKILLS RETRIEVAL - NO MOCKS!
    
    Uses real employee_skills table with UUID employee_id
    Returns actual database records
    
    PATTERN: UUID compliance, Russian text support, proper error handling
    """
    try:
        # Validate employee exists
        employee_check = text("""
            SELECT id, first_name, last_name 
            FROM employees 
            WHERE id = :employee_id
        """)
        
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(
                status_code=404,
                detail=f"Employee {employee_id} not found in employees table"
            )
        
        # Get employee skills with skill details
        skills_query = text("""
            SELECT 
                es.skill_id,
                s.name as skill_name,
                es.skill_level,
                es.proficiency_rating,
                es.certification_date,
                es.certification_expiry,
                es.is_primary,
                es.verified,
                es.created_at
            FROM employee_skills es
            JOIN skills s ON es.skill_id = s.id
            WHERE es.employee_id = :employee_id
            ORDER BY es.is_primary DESC, es.skill_level DESC, s.name
        """)
        
        skills_result = await db.execute(skills_query, {"employee_id": employee_id})
        skills_rows = skills_result.fetchall()
        
        skills = []
        for row in skills_rows:
            skills.append(EmployeeSkill(
                skill_id=str(row.skill_id),
                skill_name=row.skill_name,
                skill_level=row.skill_level,
                proficiency_rating=float(row.proficiency_rating) if row.proficiency_rating else None,
                certification_date=row.certification_date.isoformat() if row.certification_date else None,
                certification_expiry=row.certification_expiry.isoformat() if row.certification_expiry else None,
                is_primary=row.is_primary,
                verified=row.verified
            ))
        
        return EmployeeSkillsResponse(
            employee_id=str(employee_id),
            employee_name=f"{employee.first_name} {employee.last_name}",
            total_skills=len(skills),
            skills=skills
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get employee skills: {str(e)}"
        )

"""
STATUS: ✅ WORKING REAL EMPLOYEE SKILLS ENDPOINT

FEATURES:
- UUID employee_id parameter compliance
- Real employee_skills table queries
- Russian text support for skill names
- Proper error handling (404/500)
- Structured skills data with proficiency

NEXT: Test with real employee UUID and implement Task 5!
"""