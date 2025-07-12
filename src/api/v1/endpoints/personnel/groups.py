"""
Groups & Teams Management API Endpoints
Complete group management with member assignment and hierarchy support
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
    Group, Employee, Department, Organization, GroupMembership, employee_groups
)
from ....models.user import User
from ...schemas.personnel import (
    GroupCreate, GroupUpdate, GroupResponse, GroupFilter, GroupStatistics,
    GroupMembershipCreate, GroupMembershipUpdate, GroupMembershipResponse,
    BulkGroupAssignment, BulkOperationResult, GroupType
)

router = APIRouter(prefix="/groups", tags=["groups"])


@router.get("/", response_model=List[GroupResponse])
async def list_groups(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    filters: GroupFilter = Depends(),
    current_user: User = Depends(require_permissions(["groups.read"])),
    db: Session = Depends(get_db)
):
    """
    List all groups with advanced filtering
    
    **Permissions Required:** `groups.read`
    
    **Features:**
    - Advanced filtering by type, department, leader
    - Hierarchical group support
    - Text search capabilities
    - Member count information
    """
    try:
        # Build base query
        query = db.query(Group)
        
        # Apply filters
        if filters.group_type:
            query = query.filter(Group.group_type == filters.group_type.value)
        
        if filters.department_id:
            query = query.filter(Group.department_id == filters.department_id)
        
        if filters.organization_id:
            query = query.filter(Group.organization_id == filters.organization_id)
        
        if filters.leader_id:
            query = query.filter(Group.leader_id == filters.leader_id)
        
        if filters.is_active is not None:
            query = query.filter(Group.is_active == filters.is_active)
        
        if filters.parent_id:
            query = query.filter(Group.parent_id == filters.parent_id)
        
        # Text search
        if filters.search_text:
            search_term = f"%{filters.search_text}%"
            query = query.filter(
                or_(
                    Group.name.ilike(search_term),
                    Group.description.ilike(search_term)
                )
            )
        
        # Order by name
        query = query.order_by(Group.name)
        
        # Apply pagination
        groups = query.offset(skip).limit(limit).all()
        
        # Add member count to each group
        result = []
        for group in groups:
            group_dict = GroupResponse.from_orm(group).dict()
            member_count = db.query(func.count(GroupMembership.id)).filter(
                GroupMembership.group_id == group.id,
                GroupMembership.is_active == True
            ).scalar()
            group_dict["member_count"] = member_count or 0
            result.append(GroupResponse(**group_dict))
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving groups: {str(e)}"
        )


@router.post("/", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    group_data: GroupCreate,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Create a new group
    
    **Permissions Required:** `groups.write`
    
    **Features:**
    - Validates unique group names within organization
    - Supports hierarchical group structure
    - Validates organizational relationships
    """
    try:
        # Check if group name already exists within organization
        existing_group = db.query(Group).filter(
            Group.name == group_data.name,
            Group.organization_id == group_data.organization_id
        ).first()
        
        if existing_group:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Group '{group_data.name}' already exists in this organization"
            )
        
        # Validate parent group if provided
        if group_data.parent_id:
            parent_group = db.query(Group).filter(
                Group.id == group_data.parent_id
            ).first()
            if not parent_group:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent group not found"
                )
        
        # Validate department if provided
        if group_data.department_id:
            department = db.query(Department).filter(
                Department.id == group_data.department_id
            ).first()
            if not department:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Department not found"
                )
        
        # Validate organization if provided
        if group_data.organization_id:
            organization = db.query(Organization).filter(
                Organization.id == group_data.organization_id
            ).first()
            if not organization:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Organization not found"
                )
        
        # Validate leader if provided
        if group_data.leader_id:
            leader = db.query(Employee).filter(
                Employee.id == group_data.leader_id,
                Employee.status == "active"
            ).first()
            if not leader:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Leader not found or inactive"
                )
        
        # Create group
        group = Group(**group_data.dict())
        group.is_active = True
        
        db.add(group)
        db.commit()
        db.refresh(group)
        
        # Add member count
        group_dict = GroupResponse.from_orm(group).dict()
        group_dict["member_count"] = 0
        
        return GroupResponse(**group_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating group: {str(e)}"
        )


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(
    group_id: UUID,
    current_user: User = Depends(require_permissions(["groups.read"])),
    db: Session = Depends(get_db)
):
    """
    Get group details by ID
    
    **Permissions Required:** `groups.read`
    """
    try:
        group = db.query(Group).filter(Group.id == group_id).first()
        
        if not group:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found"
            )
        
        # Add member count
        group_dict = GroupResponse.from_orm(group).dict()
        member_count = db.query(func.count(GroupMembership.id)).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.is_active == True
        ).scalar()
        group_dict["member_count"] = member_count or 0
        
        return GroupResponse(**group_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving group: {str(e)}"
        )


@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: UUID,
    group_data: GroupUpdate,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Update group information
    
    **Permissions Required:** `groups.write`
    """
    try:
        group = db.query(Group).filter(Group.id == group_id).first()
        
        if not group:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found"
            )
        
        # Build update data
        update_data = group_data.dict(exclude_unset=True)
        
        # Validate name uniqueness if being updated
        if "name" in update_data:
            existing_group = db.query(Group).filter(
                Group.name == update_data["name"],
                Group.organization_id == group.organization_id,
                Group.id != group_id
            ).first()
            if existing_group:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Group name already exists in this organization"
                )
        
        # Validate parent group if being updated
        if "parent_id" in update_data and update_data["parent_id"]:
            if update_data["parent_id"] == group_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Group cannot be its own parent"
                )
            
            parent_group = db.query(Group).filter(
                Group.id == update_data["parent_id"]
            ).first()
            if not parent_group:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Parent group not found"
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
        
        # Validate leader if being updated
        if "leader_id" in update_data and update_data["leader_id"]:
            leader = db.query(Employee).filter(
                Employee.id == update_data["leader_id"],
                Employee.status == "active"
            ).first()
            if not leader:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Leader not found or inactive"
                )
        
        # Apply updates
        for field, value in update_data.items():
            setattr(group, field, value)
        
        db.commit()
        db.refresh(group)
        
        # Add member count
        group_dict = GroupResponse.from_orm(group).dict()
        member_count = db.query(func.count(GroupMembership.id)).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.is_active == True
        ).scalar()
        group_dict["member_count"] = member_count or 0
        
        return GroupResponse(**group_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating group: {str(e)}"
        )


@router.delete("/{group_id}")
async def delete_group(
    group_id: UUID,
    current_user: User = Depends(require_permissions(["groups.delete"])),
    db: Session = Depends(get_db)
):
    """
    Delete a group (soft delete if has members)
    
    **Permissions Required:** `groups.delete`
    """
    try:
        group = db.query(Group).filter(Group.id == group_id).first()
        
        if not group:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found"
            )
        
        # Check if group has active members
        active_members = db.query(GroupMembership).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.is_active == True
        ).count()
        
        # Check if group has child groups
        child_groups = db.query(Group).filter(
            Group.parent_id == group_id
        ).count()
        
        if active_members > 0 or child_groups > 0:
            # Soft delete
            group.is_active = False
            db.commit()
            
            return {
                "message": f"Group deactivated successfully. {active_members} active members and {child_groups} child groups preserved.",
                "group_id": str(group_id),
                "group_name": group.name
            }
        else:
            # Hard delete if no members or children
            db.delete(group)
            db.commit()
            
            return {
                "message": "Group deleted successfully",
                "group_id": str(group_id),
                "group_name": group.name
            }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting group: {str(e)}"
        )


@router.get("/{group_id}/members", response_model=List[GroupMembershipResponse])
async def get_group_members(
    group_id: UUID,
    include_inactive: bool = Query(False, description="Include inactive members"),
    current_user: User = Depends(require_permissions(["groups.read"])),
    db: Session = Depends(get_db)
):
    """
    Get all members of a group
    
    **Permissions Required:** `groups.read`
    """
    try:
        # Verify group exists
        group = db.query(Group).filter(Group.id == group_id).first()
        if not group:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found"
            )
        
        # Get group members
        query = db.query(GroupMembership).filter(
            GroupMembership.group_id == group_id
        )
        
        if not include_inactive:
            query = query.filter(GroupMembership.is_active == True)
        
        members = query.all()
        
        return [GroupMembershipResponse.from_orm(member) for member in members]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving group members: {str(e)}"
        )


@router.post("/{group_id}/members", response_model=GroupMembershipResponse, status_code=status.HTTP_201_CREATED)
async def add_group_member(
    group_id: UUID,
    membership_data: GroupMembershipCreate,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Add a member to a group
    
    **Permissions Required:** `groups.write`
    """
    try:
        # Verify group exists
        group = db.query(Group).filter(Group.id == group_id).first()
        if not group:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found"
            )
        
        # Verify employee exists
        employee = db.query(Employee).filter(
            Employee.id == membership_data.employee_id
        ).first()
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        # Check if membership already exists
        existing_membership = db.query(GroupMembership).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.employee_id == membership_data.employee_id,
            GroupMembership.is_active == True
        ).first()
        
        if existing_membership:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Employee is already a member of this group"
            )
        
        # Check group capacity
        if group.max_members:
            current_members = db.query(GroupMembership).filter(
                GroupMembership.group_id == group_id,
                GroupMembership.is_active == True
            ).count()
            
            if current_members >= group.max_members:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Group is at maximum capacity ({group.max_members} members)"
                )
        
        # Create membership
        membership = GroupMembership(
            group_id=group_id,
            assigned_by=current_user.id,
            is_active=True,
            **membership_data.dict()
        )
        
        db.add(membership)
        db.commit()
        db.refresh(membership)
        
        return GroupMembershipResponse.from_orm(membership)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error adding group member: {str(e)}"
        )


@router.put("/{group_id}/members/{employee_id}", response_model=GroupMembershipResponse)
async def update_group_member(
    group_id: UUID,
    employee_id: UUID,
    membership_data: GroupMembershipUpdate,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Update a group member's role and details
    
    **Permissions Required:** `groups.write`
    """
    try:
        # Find the membership
        membership = db.query(GroupMembership).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.employee_id == employee_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group membership not found"
            )
        
        # Apply updates
        update_data = membership_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(membership, field, value)
        
        db.commit()
        db.refresh(membership)
        
        return GroupMembershipResponse.from_orm(membership)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating group member: {str(e)}"
        )


@router.delete("/{group_id}/members/{employee_id}")
async def remove_group_member(
    group_id: UUID,
    employee_id: UUID,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Remove a member from a group
    
    **Permissions Required:** `groups.write`
    """
    try:
        # Find the membership
        membership = db.query(GroupMembership).filter(
            GroupMembership.group_id == group_id,
            GroupMembership.employee_id == employee_id,
            GroupMembership.is_active == True
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Active group membership not found"
            )
        
        # Soft delete by setting inactive
        membership.is_active = False
        membership.end_date = date.today()
        
        db.commit()
        
        return {
            "message": "Group member removed successfully",
            "group_id": str(group_id),
            "employee_id": str(employee_id)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error removing group member: {str(e)}"
        )


@router.post("/bulk-assign-members", response_model=BulkOperationResult)
async def bulk_assign_group_members(
    bulk_data: BulkGroupAssignment,
    current_user: User = Depends(require_permissions(["groups.write"])),
    db: Session = Depends(get_db)
):
    """
    Bulk assign employees to a group
    
    **Permissions Required:** `groups.write`
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
            missing_ids = set(bulk_data.employee_ids) - {e.id for e in employees}
            result.errors.append({
                "type": "validation_error",
                "message": f"Employees not found: {missing_ids}"
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
        
        db.commit()
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in bulk group assignment: {str(e)}"
        )


@router.get("/statistics/overview", response_model=GroupStatistics)
async def get_group_statistics(
    current_user: User = Depends(require_permissions(["groups.read"])),
    db: Session = Depends(get_db)
):
    """
    Get comprehensive group statistics
    
    **Permissions Required:** `groups.read`
    """
    try:
        # Basic counts
        total_groups = db.query(Group).count()
        active_groups = db.query(Group).filter(Group.is_active == True).count()
        
        # Type breakdown
        type_stats = db.query(
            Group.group_type,
            func.count(Group.id).label("count")
        ).group_by(Group.group_type).all()
        
        by_type = {group_type: count for group_type, count in type_stats}
        
        # Average group size
        avg_size = db.query(
            func.avg(
                func.coalesce(
                    func.count(GroupMembership.id).filter(GroupMembership.is_active == True),
                    0
                )
            )
        ).join(GroupMembership, Group.id == GroupMembership.group_id, isouter=True)\
         .scalar() or 0
        
        # Largest groups
        largest = db.query(
            Group.name,
            func.count(GroupMembership.id).filter(GroupMembership.is_active == True).label("member_count")
        ).join(GroupMembership, Group.id == GroupMembership.group_id, isouter=True)\
         .group_by(Group.name)\
         .order_by(func.count(GroupMembership.id).desc()).limit(10).all()
        
        largest_groups = [
            {"group_name": name, "member_count": count}
            for name, count in largest
        ]
        
        return GroupStatistics(
            total_groups=total_groups,
            active_groups=active_groups,
            by_type=by_type,
            average_group_size=round(avg_size, 1),
            largest_groups=largest_groups
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating group statistics: {str(e)}"
        )