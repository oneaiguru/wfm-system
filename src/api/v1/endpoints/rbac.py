"""
RBAC (Role-Based Access Control) Management Endpoints
Handles roles, permissions, and user assignments
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from ..schemas.auth import (
    RoleCreate, RoleResponse, RoleUpdate,
    PermissionCreate, PermissionResponse,
    UserRoleAssignment, UserPermissionAssignment
)
from ...auth.dependencies import (
    get_current_user, get_current_admin_user,
    require_permissions, require_roles
)
from ...core.database import get_db
from ...models.user import User
from ...models.permissions import Role, Permission, OrganizationRole, ResourcePermission


router = APIRouter(prefix="/rbac", tags=["rbac"])


# Permission Management
@router.get("/permissions", response_model=List[PermissionResponse])
async def list_permissions(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    resource: Optional[str] = Query(None, description="Filter by resource"),
    action: Optional[str] = Query(None, description="Filter by action"),
    current_user: User = Depends(require_permissions(["system.read"])),
    db: Session = Depends(get_db)
):
    """List all permissions with optional filtering"""
    query = db.query(Permission)
    
    if resource:
        query = query.filter(Permission.resource == resource)
    if action:
        query = query.filter(Permission.action == action)
    
    permissions = query.offset(skip).limit(limit).all()
    return [PermissionResponse.from_orm(p) for p in permissions]


@router.post("/permissions", response_model=PermissionResponse)
async def create_permission(
    permission_data: PermissionCreate,
    current_user: User = Depends(require_permissions(["system.config"])),
    db: Session = Depends(get_db)
):
    """Create a new permission"""
    # Check if permission already exists
    existing = db.query(Permission).filter(
        Permission.name == permission_data.name
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Permission already exists"
        )
    
    permission = Permission(**permission_data.dict())
    db.add(permission)
    db.commit()
    db.refresh(permission)
    
    return PermissionResponse.from_orm(permission)


@router.get("/permissions/{permission_id}", response_model=PermissionResponse)
async def get_permission(
    permission_id: str,
    current_user: User = Depends(require_permissions(["system.read"])),
    db: Session = Depends(get_db)
):
    """Get permission by ID"""
    permission = db.query(Permission).filter(Permission.id == permission_id).first()
    
    if not permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission not found"
        )
    
    return PermissionResponse.from_orm(permission)


@router.delete("/permissions/{permission_id}")
async def delete_permission(
    permission_id: str,
    current_user: User = Depends(require_permissions(["system.config"])),
    db: Session = Depends(get_db)
):
    """Delete a permission"""
    permission = db.query(Permission).filter(Permission.id == permission_id).first()
    
    if not permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission not found"
        )
    
    db.delete(permission)
    db.commit()
    
    return {"message": "Permission deleted successfully"}


# Role Management
@router.get("/roles", response_model=List[RoleResponse])
async def list_roles(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    active_only: bool = Query(True, description="Filter active roles only"),
    current_user: User = Depends(require_permissions(["system.read"])),
    db: Session = Depends(get_db)
):
    """List all roles with optional filtering"""
    query = db.query(Role)
    
    if active_only:
        query = query.filter(Role.is_active == True)
    
    roles = query.offset(skip).limit(limit).all()
    return [RoleResponse.from_orm(r) for r in roles]


@router.post("/roles", response_model=RoleResponse)
async def create_role(
    role_data: RoleCreate,
    current_user: User = Depends(require_permissions(["system.config"])),
    db: Session = Depends(get_db)
):
    """Create a new role"""
    # Check if role already exists
    existing = db.query(Role).filter(Role.name == role_data.name).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role already exists"
        )
    
    # Create role
    role_dict = role_data.dict()
    permission_names = role_dict.pop("permissions", [])
    
    role = Role(**role_dict)
    db.add(role)
    db.flush()  # Get the role ID
    
    # Add permissions to role
    if permission_names:
        permissions = db.query(Permission).filter(
            Permission.name.in_(permission_names)
        ).all()
        
        if len(permissions) != len(permission_names):
            found_names = [p.name for p in permissions]
            missing = set(permission_names) - set(found_names)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Permissions not found: {list(missing)}"
            )
        
        role.permissions = permissions
    
    db.commit()
    db.refresh(role)
    
    return RoleResponse.from_orm(role)


@router.get("/roles/{role_id}", response_model=RoleResponse)
async def get_role(
    role_id: str,
    current_user: User = Depends(require_permissions(["system.read"])),
    db: Session = Depends(get_db)
):
    """Get role by ID"""
    role = db.query(Role).filter(Role.id == role_id).first()
    
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )
    
    return RoleResponse.from_orm(role)


@router.put("/roles/{role_id}", response_model=RoleResponse)
async def update_role(
    role_id: str,
    role_data: RoleUpdate,
    current_user: User = Depends(require_permissions(["system.config"])),
    db: Session = Depends(get_db)
):
    """Update a role"""
    role = db.query(Role).filter(Role.id == role_id).first()
    
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )
    
    # Update role fields
    update_data = role_data.dict(exclude_unset=True)
    permission_names = update_data.pop("permissions", None)
    
    for field, value in update_data.items():
        setattr(role, field, value)
    
    # Update permissions if provided
    if permission_names is not None:
        permissions = db.query(Permission).filter(
            Permission.name.in_(permission_names)
        ).all()
        
        if len(permissions) != len(permission_names):
            found_names = [p.name for p in permissions]
            missing = set(permission_names) - set(found_names)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Permissions not found: {list(missing)}"
            )
        
        role.permissions = permissions
    
    db.commit()
    db.refresh(role)
    
    return RoleResponse.from_orm(role)


@router.delete("/roles/{role_id}")
async def delete_role(
    role_id: str,
    current_user: User = Depends(require_permissions(["system.config"])),
    db: Session = Depends(get_db)
):
    """Delete a role"""
    role = db.query(Role).filter(Role.id == role_id).first()
    
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )
    
    # Check if role is assigned to users
    users_with_role = db.query(User).filter(User.roles.contains(role)).count()
    if users_with_role > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete role: assigned to {users_with_role} users"
        )
    
    db.delete(role)
    db.commit()
    
    return {"message": "Role deleted successfully"}


# User Role Assignment
@router.post("/users/{user_id}/roles")
async def assign_user_roles(
    user_id: str,
    assignment: UserRoleAssignment,
    current_user: User = Depends(require_permissions(["users.admin"])),
    db: Session = Depends(get_db)
):
    """Assign roles to a user"""
    # Get user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get roles
    roles = db.query(Role).filter(Role.id.in_(assignment.role_ids)).all()
    if len(roles) != len(assignment.role_ids):
        found_ids = [str(r.id) for r in roles]
        missing = set(assignment.role_ids) - set(found_ids)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Roles not found: {list(missing)}"
        )
    
    # Assign roles
    user.roles = roles
    db.commit()
    
    return {"message": f"Assigned {len(roles)} roles to user"}


@router.get("/users/{user_id}/roles")
async def get_user_roles(
    user_id: str,
    current_user: User = Depends(require_permissions(["users.read"])),
    db: Session = Depends(get_db)
):
    """Get user's roles"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return [RoleResponse.from_orm(role) for role in user.roles]


@router.delete("/users/{user_id}/roles/{role_id}")
async def remove_user_role(
    user_id: str,
    role_id: str,
    current_user: User = Depends(require_permissions(["users.admin"])),
    db: Session = Depends(get_db)
):
    """Remove a role from user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    role = db.query(Role).filter(Role.id == role_id).first()
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )
    
    if role in user.roles:
        user.roles.remove(role)
        db.commit()
        return {"message": "Role removed from user"}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User does not have this role"
        )


# User Permission Assignment
@router.post("/users/{user_id}/permissions")
async def assign_user_permissions(
    user_id: str,
    assignment: UserPermissionAssignment,
    current_user: User = Depends(require_permissions(["users.admin"])),
    db: Session = Depends(get_db)
):
    """Assign direct permissions to a user"""
    # Get user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get permissions
    permissions = db.query(Permission).filter(
        Permission.id.in_(assignment.permission_ids)
    ).all()
    
    if len(permissions) != len(assignment.permission_ids):
        found_ids = [str(p.id) for p in permissions]
        missing = set(assignment.permission_ids) - set(found_ids)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Permissions not found: {list(missing)}"
        )
    
    # Assign permissions
    user.permissions = permissions
    db.commit()
    
    return {"message": f"Assigned {len(permissions)} permissions to user"}


@router.get("/users/{user_id}/permissions")
async def get_user_permissions(
    user_id: str,
    include_role_permissions: bool = Query(True, description="Include role-based permissions"),
    current_user: User = Depends(require_permissions(["users.read"])),
    db: Session = Depends(get_db)
):
    """Get user's permissions"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Direct permissions
    direct_permissions = [PermissionResponse.from_orm(p) for p in user.permissions]
    
    result = {
        "direct_permissions": direct_permissions,
        "role_permissions": [],
        "all_permissions": direct_permissions.copy()
    }
    
    if include_role_permissions:
        # Role-based permissions
        role_permissions = []
        for role in user.roles:
            for permission in role.permissions:
                perm_response = PermissionResponse.from_orm(permission)
                perm_response.source_role = role.name
                role_permissions.append(perm_response)
        
        result["role_permissions"] = role_permissions
        
        # All permissions (deduplicated)
        all_perms = {}
        for perm in direct_permissions + role_permissions:
            all_perms[perm.id] = perm
        
        result["all_permissions"] = list(all_perms.values())
    
    return result


# Resource-specific permissions
@router.post("/users/{user_id}/resources/{resource_type}/{resource_id}/permissions")
async def assign_resource_permission(
    user_id: str,
    resource_type: str,
    resource_id: str,
    permission_id: str,
    expires_at: Optional[str] = None,
    current_user: User = Depends(require_permissions(["users.admin"])),
    db: Session = Depends(get_db)
):
    """Assign permission for a specific resource"""
    # Validate user and permission
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    permission = db.query(Permission).filter(Permission.id == permission_id).first()
    if not permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permission not found"
        )
    
    # Check if already exists
    existing = db.query(ResourcePermission).filter(
        and_(
            ResourcePermission.user_id == user_id,
            ResourcePermission.resource_type == resource_type,
            ResourcePermission.resource_id == resource_id,
            ResourcePermission.permission_id == permission_id
        )
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resource permission already exists"
        )
    
    # Create resource permission
    resource_perm = ResourcePermission(
        user_id=user_id,
        resource_type=resource_type,
        resource_id=resource_id,
        permission_id=permission_id,
        granted_by=current_user.id,
        expires_at=expires_at
    )
    
    db.add(resource_perm)
    db.commit()
    
    return {"message": "Resource permission assigned"}


@router.get("/users/{user_id}/resources/{resource_type}/{resource_id}/permissions")
async def get_resource_permissions(
    user_id: str,
    resource_type: str,
    resource_id: str,
    current_user: User = Depends(require_permissions(["users.read"])),
    db: Session = Depends(get_db)
):
    """Get user's permissions for a specific resource"""
    resource_perms = db.query(ResourcePermission).filter(
        and_(
            ResourcePermission.user_id == user_id,
            ResourcePermission.resource_type == resource_type,
            ResourcePermission.resource_id == resource_id
        )
    ).all()
    
    return [
        {
            "id": rp.id,
            "permission": PermissionResponse.from_orm(rp.permission),
            "granted_by": rp.granted_by,
            "expires_at": rp.expires_at,
            "created_at": rp.created_at
        }
        for rp in resource_perms
    ]


# Utility endpoints
@router.get("/check-permission")
async def check_user_permission(
    permission_name: str,
    resource_type: Optional[str] = None,
    resource_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if current user has a specific permission"""
    # Get user permissions
    user_permissions = await get_user_permissions_list(current_user, db)
    
    has_permission = permission_name in user_permissions
    
    # Check resource-specific permissions if specified
    if resource_type and resource_id and not has_permission:
        resource_perm = db.query(ResourcePermission).join(Permission).filter(
            and_(
                ResourcePermission.user_id == current_user.id,
                ResourcePermission.resource_type == resource_type,
                ResourcePermission.resource_id == resource_id,
                Permission.name == permission_name
            )
        ).first()
        
        has_permission = resource_perm is not None
    
    return {
        "has_permission": has_permission,
        "permission": permission_name,
        "resource_type": resource_type,
        "resource_id": resource_id
    }


async def get_user_permissions_list(user: User, db: Session) -> List[str]:
    """Get list of all permission names for a user"""
    permissions = set()
    
    # Direct permissions
    for perm in user.permissions:
        permissions.add(perm.name)
    
    # Role-based permissions
    for role in user.roles:
        for perm in role.get_all_permissions():
            permissions.add(perm.name)
    
    return list(permissions)