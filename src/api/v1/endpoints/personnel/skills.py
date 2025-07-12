"""
Skills Management API Endpoints
Complete skill management and employee skill assignment operations
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, func, and_
from uuid import UUID
from datetime import date

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.personnel import (
    Employee, Skill, EmployeeSkillAssignment, employee_skills
)
from ....models.user import User
from ...schemas.personnel import (
    SkillCreate, SkillUpdate, SkillResponse, SkillFilter, SkillStatistics,
    EmployeeSkillCreate, EmployeeSkillUpdate, EmployeeSkillResponse,
    BulkSkillAssignment, BulkOperationResult, SkillCategory
)

router = APIRouter(prefix="/skills", tags=["skills"])


@router.get("/", response_model=List[SkillResponse])
async def list_skills(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    filters: SkillFilter = Depends(),
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    List all available skills with filtering options
    
    **Permissions Required:** `employees.read`
    
    **Features:**
    - Comprehensive skill filtering
    - Text search across name and description
    - Category-based filtering
    - Hierarchical skill support
    """
    try:
        # Build base query
        query = db.query(Skill)
        
        # Apply filters
        if filters.category:
            query = query.filter(Skill.category == filters.category.value)
        
        if filters.is_active is not None:
            query = query.filter(Skill.is_active == filters.is_active)
        
        if filters.is_certifiable is not None:
            query = query.filter(Skill.is_certifiable == filters.is_certifiable)
        
        if filters.parent_skill_id:
            query = query.filter(Skill.parent_skill_id == filters.parent_skill_id)
        
        # Text search
        if filters.search_text:
            search_term = f"%{filters.search_text}%"
            query = query.filter(
                or_(
                    Skill.name.ilike(search_term),
                    Skill.description.ilike(search_term)
                )
            )
        
        # Order by name
        query = query.order_by(Skill.name)
        
        # Apply pagination
        skills = query.offset(skip).limit(limit).all()
        
        return [SkillResponse.from_orm(skill) for skill in skills]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving skills: {str(e)}"
        )


@router.post("/", response_model=SkillResponse, status_code=status.HTTP_201_CREATED)
async def create_skill(
    skill_data: SkillCreate,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Create a new skill
    
    **Permissions Required:** `employees.skills`
    
    **Features:**
    - Validates unique skill names
    - Supports hierarchical skill structure
    - Comprehensive validation
    """
    try:
        # Check if skill name already exists
        existing_skill = db.query(Skill).filter(
            Skill.name.ilike(skill_data.name)
        ).first()
        
        if existing_skill:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Skill '{skill_data.name}' already exists"
            )
        
        # Validate parent skill if provided
        if skill_data.parent_skill_id:
            parent_skill = db.query(Skill).filter(
                Skill.id == skill_data.parent_skill_id
            ).first()
            if not parent_skill:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent skill not found"
                )
        
        # Create skill
        skill = Skill(**skill_data.dict())
        skill.is_active = True
        
        db.add(skill)
        db.commit()
        db.refresh(skill)
        
        return SkillResponse.from_orm(skill)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating skill: {str(e)}"
        )


@router.get("/{skill_id}", response_model=SkillResponse)
async def get_skill(
    skill_id: UUID,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get skill details by ID
    
    **Permissions Required:** `employees.read`
    """
    try:
        skill = db.query(Skill).filter(Skill.id == skill_id).first()
        
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Skill not found"
            )
        
        return SkillResponse.from_orm(skill)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving skill: {str(e)}"
        )


@router.put("/{skill_id}", response_model=SkillResponse)
async def update_skill(
    skill_id: UUID,
    skill_data: SkillUpdate,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Update skill information
    
    **Permissions Required:** `employees.skills`
    """
    try:
        skill = db.query(Skill).filter(Skill.id == skill_id).first()
        
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Skill not found"
            )
        
        # Build update data
        update_data = skill_data.dict(exclude_unset=True)
        
        # Validate name uniqueness if being updated
        if "name" in update_data:
            existing_skill = db.query(Skill).filter(
                Skill.name.ilike(update_data["name"]),
                Skill.id != skill_id
            ).first()
            if existing_skill:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Skill name already exists"
                )
        
        # Validate parent skill if being updated
        if "parent_skill_id" in update_data and update_data["parent_skill_id"]:
            if update_data["parent_skill_id"] == skill_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Skill cannot be its own parent"
                )
            
            parent_skill = db.query(Skill).filter(
                Skill.id == update_data["parent_skill_id"]
            ).first()
            if not parent_skill:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent skill not found"
                )
        
        # Apply updates
        for field, value in update_data.items():
            setattr(skill, field, value)
        
        db.commit()
        db.refresh(skill)
        
        return SkillResponse.from_orm(skill)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating skill: {str(e)}"
        )


@router.delete("/{skill_id}")
async def delete_skill(
    skill_id: UUID,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Deactivate a skill (soft delete)
    
    **Permissions Required:** `employees.skills`
    """
    try:
        skill = db.query(Skill).filter(Skill.id == skill_id).first()
        
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Skill not found"
            )
        
        # Check if skill is assigned to any employees
        assigned_count = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.skill_id == skill_id
        ).count()
        
        if assigned_count > 0:
            # Soft delete
            skill.is_active = False
            db.commit()
            
            return {
                "message": f"Skill deactivated successfully. {assigned_count} employee assignments preserved.",
                "skill_id": str(skill_id),
                "skill_name": skill.name
            }
        else:
            # Hard delete if no assignments
            db.delete(skill)
            db.commit()
            
            return {
                "message": "Skill deleted successfully",
                "skill_id": str(skill_id),
                "skill_name": skill.name
            }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting skill: {str(e)}"
        )


@router.get("/{skill_id}/employees", response_model=List[EmployeeSkillResponse])
async def get_skill_employees(
    skill_id: UUID,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get all employees with a specific skill
    
    **Permissions Required:** `employees.read`
    """
    try:
        # Verify skill exists
        skill = db.query(Skill).filter(Skill.id == skill_id).first()
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Skill not found"
            )
        
        # Get employee skill assignments
        assignments = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.skill_id == skill_id
        ).all()
        
        return [EmployeeSkillResponse.from_orm(assignment) for assignment in assignments]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving skill employees: {str(e)}"
        )


# Employee skill management endpoints
@router.get("/employees/{employee_id}/skills", response_model=List[EmployeeSkillResponse])
async def get_employee_skills(
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get all skills for a specific employee
    
    **Permissions Required:** `employees.read`
    """
    try:
        # Verify employee exists
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Get employee skills
        skills = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.employee_id == employee_id
        ).all()
        
        return [EmployeeSkillResponse.from_orm(skill) for skill in skills]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving employee skills: {str(e)}"
        )


@router.post("/employees/{employee_id}/skills", response_model=EmployeeSkillResponse, status_code=status.HTTP_201_CREATED)
async def add_employee_skill(
    employee_id: UUID,
    skill_data: EmployeeSkillCreate,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Add a skill to an employee
    
    **Permissions Required:** `employees.skills`
    """
    try:
        # Verify employee exists
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Verify skill exists
        skill = db.query(Skill).filter(Skill.id == skill_data.skill_id).first()
        if not skill:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Skill not found"
            )
        
        # Check if assignment already exists
        existing_assignment = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.employee_id == employee_id,
            EmployeeSkillAssignment.skill_id == skill_data.skill_id
        ).first()
        
        if existing_assignment:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Employee already has this skill assigned"
            )
        
        # Create assignment
        assignment = EmployeeSkillAssignment(
            employee_id=employee_id,
            assigned_by=current_user.id,
            **skill_data.dict()
        )
        
        db.add(assignment)
        db.commit()
        db.refresh(assignment)
        
        return EmployeeSkillResponse.from_orm(assignment)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error adding employee skill: {str(e)}"
        )


@router.put("/employees/{employee_id}/skills/{skill_id}", response_model=EmployeeSkillResponse)
async def update_employee_skill(
    employee_id: UUID,
    skill_id: UUID,
    skill_data: EmployeeSkillUpdate,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Update an employee's skill proficiency and details
    
    **Permissions Required:** `employees.skills`
    """
    try:
        # Find the skill assignment
        assignment = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.employee_id == employee_id,
            EmployeeSkillAssignment.skill_id == skill_id
        ).first()
        
        if not assignment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee skill assignment not found"
            )
        
        # Apply updates
        update_data = skill_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(assignment, field, value)
        
        db.commit()
        db.refresh(assignment)
        
        return EmployeeSkillResponse.from_orm(assignment)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating employee skill: {str(e)}"
        )


@router.delete("/employees/{employee_id}/skills/{skill_id}")
async def remove_employee_skill(
    employee_id: UUID,
    skill_id: UUID,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Remove a skill from an employee
    
    **Permissions Required:** `employees.skills`
    """
    try:
        # Find the skill assignment
        assignment = db.query(EmployeeSkillAssignment).filter(
            EmployeeSkillAssignment.employee_id == employee_id,
            EmployeeSkillAssignment.skill_id == skill_id
        ).first()
        
        if not assignment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee skill assignment not found"
            )
        
        # Remove assignment
        db.delete(assignment)
        db.commit()
        
        return {
            "message": "Employee skill removed successfully",
            "employee_id": str(employee_id),
            "skill_id": str(skill_id)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error removing employee skill: {str(e)}"
        )


@router.post("/bulk-assign", response_model=BulkOperationResult)
async def bulk_assign_skills(
    bulk_data: BulkSkillAssignment,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Bulk assign skills to multiple employees
    
    **Permissions Required:** `employees.skills`
    """
    try:
        result = BulkOperationResult()
        
        # Validate employees exist
        employees = db.query(Employee).filter(
            Employee.id.in_(bulk_data.employee_ids)
        ).all()
        
        if len(employees) != len(bulk_data.employee_ids):
            missing_ids = set(bulk_data.employee_ids) - {e.id for e in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
            })
            return result
        
        # Validate skills exist
        skill_ids = [skill.skill_id for skill in bulk_data.skills]
        skills = db.query(Skill).filter(Skill.id.in_(skill_ids)).all()
        
        if len(skills) != len(skill_ids):
            missing_ids = set(skill_ids) - {s.id for s in skills}
            result.errors.append({
                "type": "validation_error",
                "message": f"Skills not found: {missing_ids}"
            })
            return result
        
        # Process assignments
        for employee_id in bulk_data.employee_ids:
            for skill_data in bulk_data.skills:
                try:
                    # Check if assignment already exists
                    existing = db.query(EmployeeSkillAssignment).filter(
                        EmployeeSkillAssignment.employee_id == employee_id,
                        EmployeeSkillAssignment.skill_id == skill_data.skill_id
                    ).first()
                    
                    if existing:
                        if bulk_data.replace_existing:
                            # Update existing assignment
                            for field, value in skill_data.dict().items():
                                setattr(existing, field, value)
                            result.success_count += 1
                        else:
                            result.warnings.append(
                                f"Employee {employee_id} already has skill {skill_data.skill_id}"
                            )
                    else:
                        # Create new assignment
                        assignment = EmployeeSkillAssignment(
                            employee_id=employee_id,
                            assigned_by=current_user.id,
                            **skill_data.dict()
                        )
                        db.add(assignment)
                        result.success_count += 1
                        
                except Exception as e:
                    result.error_count += 1
                    result.errors.append({
                        "employee_id": str(employee_id),
                        "skill_id": str(skill_data.skill_id),
                        "error": str(e)
                    })
        
        result.total_processed = len(bulk_data.employee_ids) * len(bulk_data.skills)
        
        db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk skill assignment: {str(e)}"
        )


@router.get("/statistics/overview", response_model=SkillStatistics)
async def get_skill_statistics(
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get comprehensive skill statistics
    
    **Permissions Required:** `employees.read`
    """
    try:
        # Basic counts
        total_skills = db.query(Skill).count()
        active_skills = db.query(Skill).filter(Skill.is_active == True).count()
        
        # Category breakdown
        category_stats = db.query(
            Skill.category,
            func.count(Skill.id).label("count")
        ).group_by(Skill.category).all()
        
        by_category = {category: count for category, count in category_stats}
        
        # Certifiable skills
        certifiable_skills = db.query(Skill).filter(
            Skill.is_certifiable == True
        ).count()
        
        # Most common skills
        most_common = db.query(
            Skill.name,
            func.count(EmployeeSkillAssignment.id).label("assignment_count")
        ).join(EmployeeSkillAssignment).group_by(Skill.name)\
         .order_by(func.count(EmployeeSkillAssignment.id).desc()).limit(10).all()
        
        most_common_skills = [
            {"skill_name": name, "assignment_count": count}
            for name, count in most_common
        ]
        
        return SkillStatistics(
            total_skills=total_skills,
            active_skills=active_skills,
            by_category=by_category,
            certifiable_skills=certifiable_skills,
            most_common_skills=most_common_skills
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating skill statistics: {str(e)}"
        )