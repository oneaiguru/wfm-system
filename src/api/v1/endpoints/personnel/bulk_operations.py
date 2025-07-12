"""
Bulk Operations API Endpoints
High-performance bulk operations for personnel management
"""

from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from uuid import UUID
from datetime import date

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.personnel import (
    Employee, Skill, Group, Department, Organization,
    EmployeeSkillAssignment, GroupMembership
)
from ....models.user import User
from ...schemas.personnel import (
    BulkEmployeeCreate, BulkEmployeeUpdate, BulkSkillAssignment,
    BulkGroupAssignment, BulkOperationResult, EmployeeCreate, EmployeeUpdate,
    EmployeeSkillCreate, GroupMembershipCreate
)

router = APIRouter(prefix="/bulk", tags=["bulk-operations"])


@router.post("/employees/create", response_model=BulkOperationResult)
async def bulk_create_employees(
    bulk_data: BulkEmployeeCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Bulk create multiple employees
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - High-performance batch creation
    - Validation and conflict resolution
    - Background task processing for large batches
    - Detailed error reporting
    """
    try:
        result = BulkOperationResult()
        created_employees = []
        
        # Pre-validation phase
        if bulk_data.validate_unique:
            # Check for duplicate employee numbers
            employee_numbers = [emp.employee_number for emp in bulk_data.employees]
            if len(employee_numbers) != len(set(employee_numbers)):
                result.errors.append({
                    "type": "validation_error",
                    "message": "Duplicate employee numbers found in batch"
                })
                return result
            
            # Check for duplicate emails
            emails = [emp.email for emp in bulk_data.employees]
            if len(emails) != len(set(emails)):
                result.errors.append({
                    "type": "validation_error",
                    "message": "Duplicate email addresses found in batch"
                })
                return result
            
            # Check existing employee numbers
            existing_numbers = db.query(Employee.employee_number).filter(
                Employee.employee_number.in_(employee_numbers)
            ).all()
            
            if existing_numbers:
                existing_set = {num[0] for num in existing_numbers}
                result.errors.append({
                    "type": "validation_error",
                    "message": f"Employee numbers already exist: {existing_set}"
                })
                return result
            
            # Check existing emails
            existing_emails = db.query(Employee.email).filter(
                Employee.email.in_(emails)
            ).all()
            
            if existing_emails:
                existing_set = {email[0] for email in existing_emails}
                result.errors.append({
                    "type": "validation_error",
                    "message": f"Email addresses already exist: {existing_set}"
                })
                return result
        
        # Process each employee
        for i, employee_data in enumerate(bulk_data.employees):
            try:
                # Validate department if provided
                if employee_data.department_id:
                    dept = db.query(Department).filter(
                        Department.id == employee_data.department_id
                    ).first()
                    if not dept:
                        if bulk_data.continue_on_error:
                            result.errors.append({
                                "index": i,
                                "employee_number": employee_data.employee_number,
                                "error": "Department not found"
                            })
                            result.error_count += 1
                            continue
                        else:
                            raise HTTPException(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                detail=f"Department not found for employee {employee_data.employee_number}"
                            )
                
                # Validate manager if provided
                if employee_data.manager_id:
                    manager = db.query(Employee).filter(
                        Employee.id == employee_data.manager_id,
                        Employee.status == "active"
                    ).first()
                    if not manager:
                        if bulk_data.continue_on_error:
                            result.errors.append({
                                "index": i,
                                "employee_number": employee_data.employee_number,
                                "error": "Manager not found or inactive"
                            })
                            result.error_count += 1
                            continue
                        else:
                            raise HTTPException(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                detail=f"Manager not found for employee {employee_data.employee_number}"
                            )
                
                # Validate organization if provided
                if employee_data.organization_id:
                    org = db.query(Organization).filter(
                        Organization.id == employee_data.organization_id
                    ).first()
                    if not org:
                        if bulk_data.continue_on_error:
                            result.errors.append({
                                "index": i,
                                "employee_number": employee_data.employee_number,
                                "error": "Organization not found"
                            })
                            result.error_count += 1
                            continue
                        else:
                            raise HTTPException(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                detail=f"Organization not found for employee {employee_data.employee_number}"
                            )
                
                # Create employee
                employee = Employee(**employee_data.dict())
                employee.status = "active"
                
                db.add(employee)
                created_employees.append(employee)
                result.success_count += 1
                
            except Exception as e:
                if bulk_data.continue_on_error:
                    result.errors.append({
                        "index": i,
                        "employee_number": employee_data.employee_number,
                        "error": str(e)
                    })
                    result.error_count += 1
                else:
                    db.rollback()
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail=f"Error creating employee {employee_data.employee_number}: {str(e)}"
                    )
        
        result.total_processed = len(bulk_data.employees)
        
        # Commit all successful creations
        if result.success_count > 0:
            db.commit()
            
            # Add background task for post-processing if needed
            if len(created_employees) > 50:
                background_tasks.add_task(
                    post_process_bulk_employees,
                    [emp.id for emp in created_employees]
                )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk employee creation: {str(e)}"
        )


@router.put("/employees/update", response_model=BulkOperationResult)
async def bulk_update_employees(
    bulk_data: BulkEmployeeUpdate,
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Bulk update multiple employees
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - Apply same updates to multiple employees
    - Validation and conflict resolution
    - Partial update support
    """
    try:
        result = BulkOperationResult()
        
        # Validate employees exist
        employees = db.query(Employee).filter(
            Employee.id.in_(bulk_data.employee_ids)
        ).all()
        
        if len(employees) != len(bulk_data.employee_ids):
            missing_ids = set(bulk_data.employee_ids) - {emp.id for emp in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
            })
            return result
        
        # Build update data
        update_data = bulk_data.updates.dict(exclude_unset=True)
        
        # Validate department if being updated
        if "department_id" in update_data and update_data["department_id"]:
            dept = db.query(Department).filter(
                Department.id == update_data["department_id"]
            ).first()
            if not dept:
                result.errors.append({
                    "type": "validation_error",
                    "message": "Department not found"
                })
                return result
        
        # Validate manager if being updated
        if "manager_id" in update_data and update_data["manager_id"]:
            manager = db.query(Employee).filter(
                Employee.id == update_data["manager_id"],
                Employee.status == "active"
            ).first()
            if not manager:
                result.errors.append({
                    "type": "validation_error",
                    "message": "Manager not found or inactive"
                })
                return result
        
        # Apply updates to each employee
        for employee in employees:
            try:
                # Check for self-referential manager assignment
                if "manager_id" in update_data and update_data["manager_id"] == employee.id:
                    result.warnings.append(
                        f"Skipped manager assignment for employee {employee.id}: cannot be self-manager"
                    )
                    continue
                
                # Apply updates
                for field, value in update_data.items():
                    setattr(employee, field, value)
                
                result.success_count += 1
                
            except Exception as e:
                result.errors.append({
                    "employee_id": str(employee.id),
                    "error": str(e)
                })
                result.error_count += 1
        
        result.total_processed = len(bulk_data.employee_ids)
        
        if result.success_count > 0:
            db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk employee update: {str(e)}"
        )


@router.post("/employees/deactivate", response_model=BulkOperationResult)
async def bulk_deactivate_employees(
    employee_ids: List[UUID],
    current_user: User = Depends(require_permissions(["employees.delete"])),
    db: Session = Depends(get_db)
):
    """
    Bulk deactivate multiple employees
    
    **Permissions Required:** `employees.delete`
    
    **Features:**
    - Soft delete multiple employees
    - Validation for employees with direct reports
    - Cascade handling options
    """
    try:
        result = BulkOperationResult()
        
        # Validate employees exist
        employees = db.query(Employee).filter(
            Employee.id.in_(employee_ids)
        ).all()
        
        if len(employees) != len(employee_ids):
            missing_ids = set(employee_ids) - {emp.id for emp in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
            })
            return result
        
        # Check for employees with direct reports
        for employee in employees:
            try:
                # Check for active direct reports
                direct_reports = db.query(Employee).filter(
                    Employee.manager_id == employee.id,
                    Employee.status == "active"
                ).count()
                
                if direct_reports > 0:
                    result.warnings.append(
                        f"Employee {employee.id} has {direct_reports} direct reports. "
                        "Consider reassigning before deactivation."
                    )
                
                # Deactivate employee
                employee.status = "inactive"
                result.success_count += 1
                
            except Exception as e:
                result.errors.append({
                    "employee_id": str(employee.id),
                    "error": str(e)
                })
                result.error_count += 1
        
        result.total_processed = len(employee_ids)
        
        if result.success_count > 0:
            db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk employee deactivation: {str(e)}"
        )


@router.post("/skills/assign", response_model=BulkOperationResult)
async def bulk_assign_skills(
    bulk_data: BulkSkillAssignment,
    current_user: User = Depends(require_permissions(["employees.skills"])),
    db: Session = Depends(get_db)
):
    """
    Bulk assign skills to multiple employees
    
    **Permissions Required:** `employees.skills`
    
    **Features:**
    - Assign multiple skills to multiple employees
    - Replace existing assignments option
    - Batch processing optimization
    """
    try:
        result = BulkOperationResult()
        
        # Validate employees exist
        employees = db.query(Employee).filter(
            Employee.id.in_(bulk_data.employee_ids)
        ).all()
        
        if len(employees) != len(bulk_data.employee_ids):
            missing_ids = set(bulk_data.employee_ids) - {emp.id for emp in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
            })
            return result
        
        # Validate skills exist
        skill_ids = [skill.skill_id for skill in bulk_data.skills]
        skills = db.query(Skill).filter(Skill.id.in_(skill_ids)).all()
        
        if len(skills) != len(skill_ids):
            missing_ids = set(skill_ids) - {skill.id for skill in skills}
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
        
        if result.success_count > 0:
            db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk skill assignment: {str(e)}"
        )


@router.post("/groups/assign-members", response_model=BulkOperationResult)
async def bulk_assign_group_members(
    bulk_data: BulkGroupAssignment,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Bulk assign employees to a group
    
    **Permissions Required:** `groups.write`
    
    **Features:**
    - Assign multiple employees to a group
    - Role assignment and management
    - Capacity validation
    """
    try:
        result = BulkOperationResult()
        
        # Validate group exists
        group = db.query(Group).filter(Group.id == bulk_data.group_id).first()
        if not group:
            result.errors.append({
                "type": "validation_error",
                "message": "Group not found"
            })
            return result
        
        # Validate employees exist
        employees = db.query(Employee).filter(
            Employee.id.in_(bulk_data.employee_ids)
        ).all()
        
        if len(employees) != len(bulk_data.employee_ids):
            missing_ids = set(bulk_data.employee_ids) - {emp.id for emp in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
            })
            return result
        
        # Check group capacity
        if group.max_members:
            current_members = db.query(GroupMembership).filter(
                GroupMembership.group_id == bulk_data.group_id,
                GroupMembership.is_active == True
            ).count()
            
            new_members_count = len(bulk_data.employee_ids)
            if not bulk_data.replace_existing:
                # Count only new members
                existing_members = db.query(GroupMembership).filter(
                    GroupMembership.group_id == bulk_data.group_id,
                    GroupMembership.employee_id.in_(bulk_data.employee_ids),
                    GroupMembership.is_active == True
                ).count()
                new_members_count -= existing_members
            
            if current_members + new_members_count > group.max_members:
                result.errors.append({
                    "type": "capacity_error",
                    "message": f"Group capacity exceeded. Current: {current_members}, "
                              f"Adding: {new_members_count}, Max: {group.max_members}"
                })
                return result
        
        # Process assignments
        for employee_id in bulk_data.employee_ids:
            try:
                # Check if membership already exists
                existing = db.query(GroupMembership).filter(
                    GroupMembership.group_id == bulk_data.group_id,
                    GroupMembership.employee_id == employee_id,
                    GroupMembership.is_active == True
                ).first()
                
                if existing:
                    if bulk_data.replace_existing:
                        # Update existing membership
                        if bulk_data.role:
                            existing.role = bulk_data.role
                        result.success_count += 1
                    else:
                        result.warnings.append(
                            f"Employee {employee_id} is already a member of this group"
                        )
                else:
                    # Create new membership
                    membership = GroupMembership(
                        group_id=bulk_data.group_id,
                        employee_id=employee_id,
                        role=bulk_data.role,
                        assigned_by=current_user.id,
                        is_active=True,
                        start_date=date.today()
                    )
                    db.add(membership)
                    result.success_count += 1
                    
            except Exception as e:
                result.error_count += 1
                result.errors.append({
                    "employee_id": str(employee_id),
                    "error": str(e)
                })
        
        result.total_processed = len(bulk_data.employee_ids)
        
        if result.success_count > 0:
            db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk group assignment: {str(e)}"
        )


# Background task functions
async def post_process_bulk_employees(employee_ids: List[UUID]):
    """Background task for post-processing bulk employee creation"""
    # This could include:
    # - Sending welcome emails
    # - Creating default skill assignments
    # - Setting up default group memberships
    # - Triggering external system integrations
    pass


@router.get("/operations/status/{operation_id}")
async def get_bulk_operation_status(
    operation_id: str,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get status of a bulk operation
    
    **Permissions Required:** `employees.read`
    
    **Note:** This is a placeholder for background task status tracking.
    In a real implementation, you would use a task queue like Celery.
    """
    return {
        "operation_id": operation_id,
        "status": "completed",
        "message": "Bulk operation status tracking not implemented yet"
    }


@router.post("/import/csv")
async def import_employees_from_csv(
    # This would typically accept a file upload
    csv_data: Dict[str, Any],
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Import employees from CSV data
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - CSV parsing and validation
    - Field mapping configuration
    - Error reporting and data quality checks
    """
    try:
        # This is a placeholder implementation
        # In a real application, you would:
        # 1. Parse CSV file
        # 2. Map columns to employee fields
        # 3. Validate data
        # 4. Create BulkEmployeeCreate request
        # 5. Call bulk_create_employees
        
        return {
            "message": "CSV import functionality not implemented yet",
            "note": "This would parse CSV and call bulk_create_employees"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error importing CSV: {str(e)}"
        )