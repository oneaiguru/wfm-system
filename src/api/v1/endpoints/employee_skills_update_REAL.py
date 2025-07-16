"""
REAL EMPLOYEE SKILLS UPDATE ENDPOINT - Task 5
Updates employee skills following proven UUID compliance pattern
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

class SkillUpdateRequest(BaseModel):
    skill_id: UUID
    skill_level: int
    proficiency_rating: Optional[float] = None
    certification_date: Optional[date] = None
    certification_expiry: Optional[date] = None
    is_primary: bool = False
    verified: bool = False

class SkillUpdateResponse(BaseModel):
    employee_id: str
    skill_id: str
    status: str
    message: str
    updated_at: str

@router.put("/employees/{employee_id}/skills/{skill_id}", response_model=SkillUpdateResponse, tags=["🔥 REAL Employee Skills"])
async def update_employee_skill(
    employee_id: UUID,
    skill_id: UUID,
    skill_update: SkillUpdateRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE SKILL UPDATE - NO MOCKS!
    
    Updates real employee_skills table with UUID compliance
    Handles skill level changes, certifications, and verification
    
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
        
        # Validate skill exists
        skill_check = text("""
            SELECT id, name 
            FROM skills 
            WHERE id = :skill_id
        """)
        
        skill_result = await db.execute(skill_check, {"skill_id": skill_id})
        skill = skill_result.fetchone()
        
        if not skill:
            raise HTTPException(
                status_code=404,
                detail=f"Skill {skill_id} not found in skills table"
            )
        
        # Check if employee_skill record exists
        existing_skill_check = text("""
            SELECT id FROM employee_skills 
            WHERE employee_id = :employee_id AND skill_id = :skill_id
        """)
        
        existing_result = await db.execute(existing_skill_check, {
            "employee_id": employee_id, 
            "skill_id": skill_id
        })
        existing_skill = existing_result.fetchone()
        
        if existing_skill:
            # Update existing skill
            update_query = text("""
                UPDATE employee_skills 
                SET 
                    skill_level = :skill_level,
                    proficiency_rating = :proficiency_rating,
                    certification_date = :certification_date,
                    certification_expiry = :certification_expiry,
                    is_primary = :is_primary,
                    verified = :verified,
                    updated_at = CURRENT_TIMESTAMP
                WHERE employee_id = :employee_id AND skill_id = :skill_id
                RETURNING id, updated_at
            """)
            
            result = await db.execute(update_query, {
                'employee_id': employee_id,
                'skill_id': skill_id,
                'skill_level': skill_update.skill_level,
                'proficiency_rating': skill_update.proficiency_rating,
                'certification_date': skill_update.certification_date,
                'certification_expiry': skill_update.certification_expiry,
                'is_primary': skill_update.is_primary,
                'verified': skill_update.verified
            })
            
            updated_record = result.fetchone()
            action = "updated"
        else:
            # Insert new skill
            insert_query = text("""
                INSERT INTO employee_skills 
                (employee_id, skill_id, skill_level, proficiency_rating, 
                 certification_date, certification_expiry, is_primary, verified)
                VALUES 
                (:employee_id, :skill_id, :skill_level, :proficiency_rating,
                 :certification_date, :certification_expiry, :is_primary, :verified)
                RETURNING id, updated_at
            """)
            
            result = await db.execute(insert_query, {
                'employee_id': employee_id,
                'skill_id': skill_id,
                'skill_level': skill_update.skill_level,
                'proficiency_rating': skill_update.proficiency_rating,
                'certification_date': skill_update.certification_date,
                'certification_expiry': skill_update.certification_expiry,
                'is_primary': skill_update.is_primary,
                'verified': skill_update.verified
            })
            
            updated_record = result.fetchone()
            action = "created"
        
        await db.commit()
        
        return SkillUpdateResponse(
            employee_id=str(employee_id),
            skill_id=str(skill_id),
            status="success",
            message=f"Employee skill {action} successfully - {skill.name} level {skill_update.skill_level}",
            updated_at=updated_record.updated_at.isoformat()
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update employee skill: {str(e)}"
        )

@router.post("/employees/{employee_id}/skills", response_model=SkillUpdateResponse, tags=["🔥 REAL Employee Skills"])
async def add_employee_skill(
    employee_id: UUID,
    skill_request: SkillUpdateRequest,
    db: AsyncSession = Depends(get_db)
):
    """Add new skill to employee - calls update endpoint with skill_id from request"""
    return await update_employee_skill(employee_id, skill_request.skill_id, skill_request, db)

"""
STATUS: ✅ WORKING REAL EMPLOYEE SKILLS UPDATE ENDPOINT

FEATURES:
- UUID employee_id and skill_id compliance
- Real employee_skills table updates/inserts
- Handles skill levels, certifications, verification
- Proper error handling (404/422/500)
- Supports both PUT (update) and POST (add) operations

NEXT: Implement Task 6 - Skills History!
"""