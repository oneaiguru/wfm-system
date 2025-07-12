"""
Organizational Structure API Endpoints
Complete organizational hierarchy management and structure operations
"""

from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, func, and_
from uuid import UUID

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.personnel import (
    Organization, Department, Group, Employee
)
from ....models.user import User
from ...schemas.personnel import (
    OrganizationCreate, OrganizationUpdate, OrganizationResponse,
    DepartmentCreate, DepartmentUpdate, DepartmentResponse,
    OrganizationalStructureResponse, OrganizationalStructureNode
)

router = APIRouter(prefix="/organization", tags=["organization"])


@router.get("/structure", response_model=OrganizationalStructureResponse)
async def get_organizational_structure(
    organization_id: Optional[UUID] = Query(None, description="Specific organization ID"),
    include_employees: bool = Query(False, description="Include employee details"),
    current_user: User = Depends(require_permissions(["organization.read"])),
    db: Session = Depends(get_db)
):
    """
    Get complete organizational structure tree
    
    **Permissions Required:** `organization.read`
    
    **Features:**
    - Hierarchical organization structure
    - Department and group nesting
    - Optional employee inclusion
    - Recursive tree building
    """
    try:
        # Get root organization
        org_query = db.query(Organization).filter(Organization.is_active == True)
        if organization_id:
            org_query = org_query.filter(Organization.id == organization_id)
        else:
            org_query = org_query.filter(Organization.parent_id.is_(None))
        
        root_org = org_query.first()
        if not root_org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )
        
        def build_structure_node(org: Organization, depth: int = 0) -> OrganizationalStructureNode:
            """Recursively build organizational structure"""
            node = OrganizationalStructureNode(
                id=org.id,
                name=org.name,
                type="organization",
                parent_id=org.parent_id,
                children=[],
                metadata={
                    "description": org.description,
                    "organization_type": org.organization_type,
                    "is_active": org.is_active,
                    "depth": depth
                }
            )
            
            # Add child organizations
            child_orgs = db.query(Organization).filter(
                Organization.parent_id == org.id,
                Organization.is_active == True
            ).all()
            
            for child_org in child_orgs:
                node.children.append(build_structure_node(child_org, depth + 1))
            
            # Add departments
            departments = db.query(Department).filter(
                Department.organization_id == org.id,
                Department.is_active == True
            ).all()
            
            for dept in departments:
                dept_node = build_department_node(dept, depth + 1)
                node.children.append(dept_node)
            
            return node
        
        def build_department_node(dept: Department, depth: int = 0) -> OrganizationalStructureNode:
            """Build department node with groups and employees"""
            node = OrganizationalStructureNode(
                id=dept.id,
                name=dept.name,
                type="department",
                parent_id=dept.parent_id,
                children=[],
                metadata={
                    "description": dept.description,
                    "code": dept.code,
                    "location": dept.location,
                    "cost_center": dept.cost_center,
                    "is_active": dept.is_active,
                    "depth": depth
                }
            )
            
            # Add child departments
            child_depts = db.query(Department).filter(
                Department.parent_id == dept.id,
                Department.is_active == True
            ).all()
            
            for child_dept in child_depts:
                node.children.append(build_department_node(child_dept, depth + 1))
            
            # Add groups
            groups = db.query(Group).filter(
                Group.department_id == dept.id,
                Group.is_active == True
            ).all()
            
            for group in groups:
                group_node = build_group_node(group, depth + 1)
                node.children.append(group_node)
            
            # Add employees if requested
            if include_employees:
                employees = db.query(Employee).filter(
                    Employee.department_id == dept.id,
                    Employee.status == "active"
                ).all()
                
                for employee in employees:
                    emp_node = OrganizationalStructureNode(
                        id=employee.id,
                        name=f"{employee.first_name} {employee.last_name}",
                        type="employee",
                        parent_id=None,
                        children=[],
                        metadata={
                            "employee_number": employee.employee_number,
                            "email": employee.email,
                            "position": employee.position,
                            "employment_type": employee.employment_type,
                            "depth": depth + 1
                        }
                    )
                    node.children.append(emp_node)
            
            return node
        
        def build_group_node(group: Group, depth: int = 0) -> OrganizationalStructureNode:
            """Build group node with members"""
            node = OrganizationalStructureNode(
                id=group.id,
                name=group.name,
                type="group",
                parent_id=group.parent_id,
                children=[],
                metadata={
                    "description": group.description,
                    "group_type": group.group_type,
                    "location": group.location,
                    "max_members": group.max_members,
                    "is_active": group.is_active,
                    "depth": depth
                }
            )
            
            # Add child groups
            child_groups = db.query(Group).filter(
                Group.parent_id == group.id,
                Group.is_active == True
            ).all()
            
            for child_group in child_groups:
                node.children.append(build_group_node(child_group, depth + 1))
            
            return node
        
        # Build the complete structure
        structure = build_structure_node(root_org)
        
        # Calculate total nodes and depth
        def count_nodes_and_depth(node: OrganizationalStructureNode) -> tuple[int, int]:
            """Count total nodes and calculate maximum depth"""
            total_nodes = 1
            max_depth = node.metadata.get("depth", 0)
            
            for child in node.children:
                child_nodes, child_depth = count_nodes_and_depth(child)
                total_nodes += child_nodes
                max_depth = max(max_depth, child_depth)
            
            return total_nodes, max_depth
        
        total_nodes, max_depth = count_nodes_and_depth(structure)
        
        return OrganizationalStructureResponse(
            organization=structure,
            total_nodes=total_nodes,
            depth=max_depth + 1
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving organizational structure: {str(e)}"
        )


@router.get("/departments", response_model=List[DepartmentResponse])
async def list_departments(
    organization_id: Optional[UUID] = Query(None, description="Filter by organization"),
    parent_id: Optional[UUID] = Query(None, description="Filter by parent department"),
    include_inactive: bool = Query(False, description="Include inactive departments"),
    current_user: User = Depends(require_permissions(["organization.read"])),
    db: Session = Depends(get_db)
):
    """
    List all departments with filtering options
    
    **Permissions Required:** `organization.read`
    """
    try:
        # Build query
        query = db.query(Department)
        
        if organization_id:
            query = query.filter(Department.organization_id == organization_id)
        
        if parent_id:
            query = query.filter(Department.parent_id == parent_id)
        
        if not include_inactive:
            query = query.filter(Department.is_active == True)
        
        # Order by name
        departments = query.order_by(Department.name).all()
        
        # Add counts for each department
        result = []
        for dept in departments:
            dept_dict = DepartmentResponse.from_orm(dept).dict()
            
            # Count employees
            employee_count = db.query(func.count(Employee.id)).filter(
                Employee.department_id == dept.id,
                Employee.status == "active"
            ).scalar() or 0
            
            # Count groups
            group_count = db.query(func.count(Group.id)).filter(
                Group.department_id == dept.id,
                Group.is_active == True
            ).scalar() or 0
            
            dept_dict["employee_count"] = employee_count
            dept_dict["group_count"] = group_count
            
            result.append(DepartmentResponse(**dept_dict))
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving departments: {str(e)}"
        )


@router.post("/departments", response_model=DepartmentResponse, status_code=status.HTTP_201_CREATED)
async def create_department(
    department_data: DepartmentCreate,
    current_user: User = Depends(require_permissions(["organization.admin"])),
    db: Session = Depends(get_db)
):
    """
    Create a new department
    
    **Permissions Required:** `organization.admin`
    """
    try:
        # Check if department code already exists
        existing_dept = db.query(Department).filter(
            Department.code == department_data.code
        ).first()
        
        if existing_dept:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Department code '{department_data.code}' already exists"
            )
        
        # Validate organization exists
        organization = db.query(Organization).filter(
            Organization.id == department_data.organization_id
        ).first()
        if not organization:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Organization not found"
            )
        
        # Validate parent department if provided
        if department_data.parent_id:
            parent_dept = db.query(Department).filter(
                Department.id == department_data.parent_id
            ).first()
            if not parent_dept:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent department not found"
                )
        
        # Validate department head if provided
        if department_data.head_id:
            head = db.query(Employee).filter(
                Employee.id == department_data.head_id,
                Employee.status == "active"
            ).first()
            if not head:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department head not found or inactive"
                )
        
        # Create department
        department = Department(**department_data.dict())
        department.is_active = True
        
        db.add(department)
        db.commit()
        db.refresh(department)
        
        # Add counts
        dept_dict = DepartmentResponse.from_orm(department).dict()
        dept_dict["employee_count"] = 0
        dept_dict["group_count"] = 0
        
        return DepartmentResponse(**dept_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating department: {str(e)}"
        )


@router.put("/departments/{department_id}", response_model=DepartmentResponse)
async def update_department(
    department_id: UUID,
    department_data: DepartmentUpdate,
    current_user: User = Depends(require_permissions(["organization.admin"])),
    db: Session = Depends(get_db)
):
    """
    Update department information
    
    **Permissions Required:** `organization.admin`
    """
    try:
        department = db.query(Department).filter(Department.id == department_id).first()
        
        if not department:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Department not found"
            )
        
        # Build update data
        update_data = department_data.dict(exclude_unset=True)
        
        # Validate code uniqueness if being updated
        if "code" in update_data:
            existing_dept = db.query(Department).filter(
                Department.code == update_data["code"],
                Department.id != department_id
            ).first()
            if existing_dept:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department code already exists"
                )
        
        # Validate parent department if being updated
        if "parent_id" in update_data and update_data["parent_id"]:
            if update_data["parent_id"] == department_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department cannot be its own parent"
                )
            
            parent_dept = db.query(Department).filter(
                Department.id == update_data["parent_id"]
            ).first()
            if not parent_dept:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent department not found"
                )
        
        # Validate department head if being updated
        if "head_id" in update_data and update_data["head_id"]:
            head = db.query(Employee).filter(
                Employee.id == update_data["head_id"],
                Employee.status == "active"
            ).first()
            if not head:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department head not found or inactive"
                )
        
        # Apply updates
        for field, value in update_data.items():
            setattr(department, field, value)
        
        db.commit()
        db.refresh(department)
        
        # Add counts
        dept_dict = DepartmentResponse.from_orm(department).dict()
        
        # Count employees
        employee_count = db.query(func.count(Employee.id)).filter(
            Employee.department_id == department_id,
            Employee.status == "active"
        ).scalar() or 0
        
        # Count groups
        group_count = db.query(func.count(Group.id)).filter(
            Group.department_id == department_id,
            Group.is_active == True
        ).scalar() or 0
        
        dept_dict["employee_count"] = employee_count
        dept_dict["group_count"] = group_count
        
        return DepartmentResponse(**dept_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating department: {str(e)}"
        )


@router.post("/restructure")
async def restructure_organization(
    restructure_data: Dict[str, Any],
    current_user: User = Depends(require_permissions(["organization.admin"])),
    db: Session = Depends(get_db)
):
    """
    Perform bulk organizational restructuring
    
    **Permissions Required:** `organization.admin`
    
    **Features:**
    - Bulk department moves
    - Employee reassignments
    - Group reorganization
    - Validation and rollback support
    """
    try:
        result = {
            "department_moves": 0,
            "employee_reassignments": 0,
            "group_moves": 0,
            "errors": [],
            "warnings": []
        }
        
        # Department moves
        if "department_moves" in restructure_data:
            for move in restructure_data["department_moves"]:
                try:
                    dept = db.query(Department).filter(
                        Department.id == move["department_id"]
                    ).first()
                    
                    if not dept:
                        result["errors"].append(f"Department {move['department_id']} not found")
                        continue
                    
                    # Validate new parent
                    if move.get("new_parent_id"):
                        new_parent = db.query(Department).filter(
                            Department.id == move["new_parent_id"]
                        ).first()
                        if not new_parent:
                            result["errors"].append(f"New parent department {move['new_parent_id']} not found")
                            continue
                    
                    dept.parent_id = move.get("new_parent_id")
                    result["department_moves"] += 1
                    
                except Exception as e:
                    result["errors"].append(f"Error moving department: {str(e)}")
        
        # Employee reassignments
        if "employee_reassignments" in restructure_data:
            for reassignment in restructure_data["employee_reassignments"]:
                try:
                    employee = db.query(Employee).filter(
                        Employee.id == reassignment["employee_id"]
                    ).first()
                    
                    if not employee:
                        result["errors"].append(f"Employee {reassignment['employee_id']} not found")
                        continue
                    
                    # Validate new department
                    if reassignment.get("new_department_id"):
                        new_dept = db.query(Department).filter(
                            Department.id == reassignment["new_department_id"]
                        ).first()
                        if not new_dept:
                            result["errors"].append(f"New department {reassignment['new_department_id']} not found")
                            continue
                    
                    employee.department_id = reassignment.get("new_department_id")
                    
                    # Update manager if provided
                    if reassignment.get("new_manager_id"):
                        new_manager = db.query(Employee).filter(
                            Employee.id == reassignment["new_manager_id"],
                            Employee.status == "active"
                        ).first()
                        if not new_manager:
                            result["warnings"].append(f"New manager {reassignment['new_manager_id']} not found, skipping manager update")
                        else:
                            employee.manager_id = reassignment["new_manager_id"]
                    
                    result["employee_reassignments"] += 1
                    
                except Exception as e:
                    result["errors"].append(f"Error reassigning employee: {str(e)}")
        
        # Group moves
        if "group_moves" in restructure_data:
            for move in restructure_data["group_moves"]:
                try:
                    group = db.query(Group).filter(
                        Group.id == move["group_id"]
                    ).first()
                    
                    if not group:
                        result["errors"].append(f"Group {move['group_id']} not found")
                        continue
                    
                    # Validate new department
                    if move.get("new_department_id"):
                        new_dept = db.query(Department).filter(
                            Department.id == move["new_department_id"]
                        ).first()
                        if not new_dept:
                            result["errors"].append(f"New department {move['new_department_id']} not found")
                            continue
                    
                    group.department_id = move.get("new_department_id")
                    result["group_moves"] += 1
                    
                except Exception as e:
                    result["errors"].append(f"Error moving group: {str(e)}")
        
        if result["errors"]:
            db.rollback()
            return {
                "success": False,
                "message": "Restructuring failed due to errors",
                "result": result
            }
        
        db.commit()
        
        return {
            "success": True,
            "message": "Organizational restructuring completed successfully",
            "result": result
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error during organizational restructuring: {str(e)}"
        )


@router.get("/services", response_model=List[Dict[str, Any]])
async def list_services(
    organization_id: Optional[UUID] = Query(None, description="Filter by organization"),
    current_user: User = Depends(require_permissions(["organization.read"])),
    db: Session = Depends(get_db)
):
    """
    List organizational services/business units
    
    **Permissions Required:** `organization.read`
    
    **Note:** This endpoint provides a conceptual view of services.
    In a real implementation, you would have a separate Service model.
    """
    try:
        # For now, return departments as services
        query = db.query(Department).filter(Department.is_active == True)
        
        if organization_id:
            query = query.filter(Department.organization_id == organization_id)
        
        departments = query.all()
        
        services = []
        for dept in departments:
            employee_count = db.query(func.count(Employee.id)).filter(
                Employee.department_id == dept.id,
                Employee.status == "active"
            ).scalar() or 0
            
            group_count = db.query(func.count(Group.id)).filter(
                Group.department_id == dept.id,
                Group.is_active == True
            ).scalar() or 0
            
            services.append({
                "id": str(dept.id),
                "name": dept.name,
                "description": dept.description,
                "type": "department",
                "location": dept.location,
                "cost_center": dept.cost_center,
                "employee_count": employee_count,
                "group_count": group_count,
                "head_id": str(dept.head_id) if dept.head_id else None,
                "organization_id": str(dept.organization_id),
                "is_active": dept.is_active
            })
        
        return services
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving services: {str(e)}"
        )