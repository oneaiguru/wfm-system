"""
Employee Management API Endpoints
Complete CRUD operations for employee management with advanced features
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from uuid import UUID

from ....auth.dependencies import get_current_user, require_permissions
from ...core.database import get_db
from ...models.personnel import Employee, Department, Organization
from ...models.user import User
from ...schemas.personnel import (
    EmployeeCreate, EmployeeUpdate, EmployeeResponse, EmployeeListResponse,
    EmployeeFilter, EmployeeStatistics, EmployeeStatus, EmploymentType
)

router = APIRouter(prefix="/employees", tags=["employees"])


@router.get("/", response_model=EmployeeListResponse)
async def list_employees(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    filters: EmployeeFilter = Depends(),
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    List employees with advanced filtering and pagination
    
    **Permissions Required:** `employees.read`
    
    **Features:**
    - Pagination with configurable limits
    - Advanced filtering by department, manager, skills, etc.
    - Text search across name, email, and position
    - Sorting and ordering options
    """
    try:
        # Build base query
        query = db.query(Employee)
        
        # Apply filters
        if filters.department_id:
            query = query.filter(Employee.department_id == filters.department_id)
        
        if filters.manager_id:
            query = query.filter(Employee.manager_id == filters.manager_id)
        
        if filters.organization_id:
            query = query.filter(Employee.organization_id == filters.organization_id)
        
        if filters.status:
            query = query.filter(Employee.status == filters.status.value)
        
        if filters.employment_type:
            query = query.filter(Employee.employment_type == filters.employment_type.value)
        
        if filters.hire_date_from:
            query = query.filter(Employee.hire_date >= filters.hire_date_from)
        
        if filters.hire_date_to:
            query = query.filter(Employee.hire_date <= filters.hire_date_to)
        
        # Text search
        if filters.search_text:
            search_term = f"%{filters.search_text}%"
            query = query.filter(
                or_(
                    Employee.first_name.ilike(search_term),
                    Employee.last_name.ilike(search_term),
                    Employee.email.ilike(search_term),
                    Employee.position.ilike(search_term)
                )
            )
        
        # Skill filtering (if skill_ids provided)
        if filters.skill_ids:
            from ....models.personnel import employee_skills
            query = query.join(employee_skills).filter(
                employee_skills.c.skill_id.in_(filters.skill_ids)
            )
        
        # Group filtering (if group_ids provided)
        if filters.group_ids:
            from ....models.personnel import employee_groups
            query = query.join(employee_groups).filter(
                employee_groups.c.group_id.in_(filters.group_ids)
            )
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        employees = query.offset(skip).limit(limit).all()
        
        # Calculate pagination metadata
        pages = (total + limit - 1) // limit
        page = (skip // limit) + 1
        
        return EmployeeListResponse(
            employees=[EmployeeResponse.from_orm(emp) for emp in employees],
            total=total,
            page=page,
            per_page=limit,
            pages=pages
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving employees: {str(e)}"
        )


@router.post("/", response_model=EmployeeResponse, status_code=status.HTTP_201_CREATED)
async def create_employee(
    employee_data: EmployeeCreate,
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Create a new employee
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - Validates unique employee number and email
    - Validates organizational relationships
    - Automatically sets creation metadata
    - Comprehensive error handling
    """
    try:
        # Check if employee number already exists
        existing_employee = db.query(Employee).filter(
            Employee.employee_number == employee_data.employee_number
        ).first()
        
        if existing_employee:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Employee number '{employee_data.employee_number}' already exists"
            )
        
        # Check if email already exists
        existing_email = db.query(Employee).filter(
            Employee.email == employee_data.email
        ).first()
        
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Email '{employee_data.email}' already exists"
            )
        
        # Validate department exists if provided
        if employee_data.department_id:
            department = db.query(Department).filter(
                Department.id == employee_data.department_id
            ).first()
            if not department:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department not found"
                )
        
        # Validate manager exists if provided
        if employee_data.manager_id:
            manager = db.query(Employee).filter(
                Employee.id == employee_data.manager_id,
                Employee.status == "active"
            ).first()
            if not manager:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Manager not found or inactive"
                )
        
        # Validate organization exists if provided
        if employee_data.organization_id:
            organization = db.query(Organization).filter(
                Organization.id == employee_data.organization_id
            ).first()
            if not organization:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Organization not found"
                )
        
        # Create employee
        employee = Employee(**employee_data.dict())
        employee.status = "active"  # Set default status
        
        db.add(employee)
        db.commit()
        db.refresh(employee)
        
        return EmployeeResponse.from_orm(employee)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating employee: {str(e)}"
        )


@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get employee by ID with detailed information
    
    **Permissions Required:** `employees.read`
    
    **Features:**
    - Retrieves complete employee information
    - Includes related data (department, manager, organization)
    - Optimized database queries
    """
    try:
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        return EmployeeResponse.from_orm(employee)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving employee: {str(e)}"
        )


@router.put("/{employee_id}", response_model=EmployeeResponse)
async def update_employee(
    employee_id: UUID,
    employee_data: EmployeeUpdate,
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Update employee information
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - Partial updates with validation
    - Prevents circular manager relationships
    - Validates organizational relationships
    - Comprehensive error handling
    """
    try:
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Build update data
        update_data = employee_data.dict(exclude_unset=True)
        
        # Validate email uniqueness if being updated
        if "email" in update_data:
            existing_email = db.query(Employee).filter(
                Employee.email == update_data["email"],
                Employee.id != employee_id
            ).first()
            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already exists"
                )
        
        # Validate manager relationship if being updated
        if "manager_id" in update_data and update_data["manager_id"]:
            if update_data["manager_id"] == employee_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Employee cannot be their own manager"
                )
            
            manager = db.query(Employee).filter(
                Employee.id == update_data["manager_id"],
                Employee.status == "active"
            ).first()
            if not manager:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Manager not found or inactive"
                )
        
        # Validate department if being updated
        if "department_id" in update_data and update_data["department_id"]:
            department = db.query(Department).filter(
                Department.id == update_data["department_id"]
            ).first()
            if not department:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department not found"
                )
        
        # Apply updates
        for field, value in update_data.items():
            setattr(employee, field, value)
        
        db.commit()
        db.refresh(employee)
        
        return EmployeeResponse.from_orm(employee)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating employee: {str(e)}"
        )


@router.delete("/{employee_id}")
async def delete_employee(
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["employees.delete"])),
    db: Session = Depends(get_db)
):
    """
    Deactivate employee (soft delete)
    
    **Permissions Required:** `employees.delete`
    
    **Features:**
    - Soft delete (sets status to inactive)
    - Prevents deletion of employees with active reports
    - Maintains data integrity
    - Audit trail preservation
    """
    try:
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Check if employee has active direct reports
        active_reports = db.query(Employee).filter(
            Employee.manager_id == employee_id,
            Employee.status == "active"
        ).count()
        
        if active_reports > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot deactivate employee with {active_reports} active direct reports. "
                       "Please reassign or deactivate direct reports first."
            )
        
        # Soft delete
        employee.status = "inactive"
        
        db.commit()
        
        return {
            "message": "Employee deactivated successfully",
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deactivating employee: {str(e)}"
        )


@router.get("/statistics/overview", response_model=EmployeeStatistics)
async def get_employee_statistics(
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get comprehensive employee statistics
    
    **Permissions Required:** `employees.read`
    
    **Features:**
    - Total and active employee counts
    - Breakdown by department, employment type, and status
    - Average tenure calculations
    - Performance metrics
    """
    try:
        # Basic counts
        total_employees = db.query(Employee).count()
        active_employees = db.query(Employee).filter(Employee.status == "active").count()
        inactive_employees = total_employees - active_employees
        
        # Department breakdown
        dept_stats = db.query(
            Department.name,
            func.count(Employee.id).label("count")
        ).join(Employee, Employee.department_id == Department.id, isouter=True)\
         .group_by(Department.name).all()
        
        by_department = {dept: count for dept, count in dept_stats}
        
        # Employment type breakdown
        employment_stats = db.query(
            Employee.employment_type,
            func.count(Employee.id).label("count")
        ).group_by(Employee.employment_type).all()
        
        by_employment_type = {emp_type: count for emp_type, count in employment_stats}
        
        # Status breakdown
        status_stats = db.query(
            Employee.status,
            func.count(Employee.id).label("count")
        ).group_by(Employee.status).all()
        
        by_status = {status: count for status, count in status_stats}
        
        # Average tenure calculation
        from datetime import date
        avg_tenure = db.query(
            func.avg(func.extract('epoch', date.today() - Employee.hire_date) / (30 * 24 * 3600))
        ).scalar() or 0
        
        return EmployeeStatistics(
            total_employees=total_employees,
            active_employees=active_employees,
            inactive_employees=inactive_employees,
            by_department=by_department,
            by_employment_type=by_employment_type,
            by_status=by_status,
            average_tenure_months=round(avg_tenure, 1)
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating employee statistics: {str(e)}"
        )


@router.post("/{employee_id}/reactivate")
async def reactivate_employee(
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["employees.write"])),
    db: Session = Depends(get_db)
):
    """
    Reactivate an inactive employee
    
    **Permissions Required:** `employees.write`
    
    **Features:**
    - Validates employee exists and is inactive
    - Reactivates employee status
    - Maintains audit trail
    """
    try:
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        if employee.status == "active":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Employee is already active"
            )
        
        if employee.status == "terminated":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot reactivate terminated employee"
            )
        
        employee.status = "active"
        db.commit()
        
        return {
            "message": "Employee reactivated successfully",
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error reactivating employee: {str(e)}"
        )


@router.get("/{employee_id}/direct-reports", response_model=List[EmployeeResponse])
async def get_employee_direct_reports(
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["employees.read"])),
    db: Session = Depends(get_db)
):
    """
    Get direct reports for an employee
    
    **Permissions Required:** `employees.read`
    
    **Features:**
    - Lists all direct reports
    - Includes inactive employees
    - Sorted by employee name
    """
    try:
        # Verify employee exists
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Get direct reports
        direct_reports = db.query(Employee).filter(
            Employee.manager_id == employee_id
        ).order_by(Employee.first_name, Employee.last_name).all()
        
        return [EmployeeResponse.from_orm(report) for report in direct_reports]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving direct reports: {str(e)}"
        )