"""
Task 48: GET /api/v1/admin/roles/permissions
BDD Scenario: "Manage User Roles and Permissions"
Implementation: RBAC from user_roles table
Database: user_roles, role_permissions

CRITICAL: NO MOCK DATA - Real PostgreSQL queries to wfm_enterprise database
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Dict, List, Any, Optional
from datetime import datetime
import psycopg2
import psycopg2.extras
import os

router = APIRouter()

class Permission(BaseModel):
    permission_id: str
    permission_name: str
    resource: str
    action: str
    description: str
    is_system_permission: bool

class Role(BaseModel):
    role_id: str
    role_name: str
    role_description: str
    is_system_role: bool
    created_date: datetime
    permissions: List[Permission]
    user_count: int

class UserRoleAssignment(BaseModel):
    user_id: str
    username: str
    email: str
    role_id: str
    role_name: str
    assigned_date: datetime
    assigned_by: str
    is_active: bool

class RolePermissionsResponse(BaseModel):
    status: str
    total_roles: int
    roles: List[Role]
    total_permissions: int
    user_assignments: List[UserRoleAssignment]
    permission_matrix: Dict[str, List[str]]
    timestamp: datetime

# Real PostgreSQL Database Connection
def get_database_connection():
    """
    REAL DATABASE CONNECTION to wfm_enterprise
    NO MOCK DATA - connects to actual PostgreSQL instance
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            database=os.getenv("DB_NAME", "wfm_enterprise"),
            user=os.getenv("DB_USER", "wfm_admin"),
            password=os.getenv("DB_PASSWORD", "wfm_password"),
            port=os.getenv("DB_PORT", "5432")
        )
        return conn
    except psycopg2.Error as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

@router.get("/api/v1/admin/roles/permissions", response_model=RolePermissionsResponse, tags=["🔧 System Administration"])
async def get_roles_and_permissions(
    role_name: Optional[str] = Query(None, description="Filter by role name"),
    include_system_roles: bool = Query(True, description="Include system-defined roles"),
    include_inactive_users: bool = Query(False, description="Include inactive user assignments"),
    resource: Optional[str] = Query(None, description="Filter by resource")
):
    """
    BDD Scenario: "Manage User Roles and Permissions"
    
    Retrieves comprehensive role-based access control (RBAC) information 
    from the wfm_enterprise database. Implements real permission management
    as specified in 18-system-administration-configuration.feature scenarios.
    
    REAL DATABASE IMPLEMENTATION:
    - Queries user_roles and role_permissions tables directly
    - Builds permission matrix for role management
    - Includes user assignment tracking
    - Real-time RBAC validation
    """
    
    try:
        conn = get_database_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        # Build role filter
        role_filter = ""
        role_params = []
        if role_name:
            role_filter += " AND r.role_name ILIKE %s"
            role_params.append(f"%{role_name}%")
        
        if not include_system_roles:
            role_filter += " AND r.is_system_role = FALSE"
        
        # Get roles with permission counts
        roles_query = f"""
        SELECT 
            r.role_id,
            r.role_name,
            r.role_description,
            r.is_system_role,
            r.created_date,
            COUNT(DISTINCT rp.permission_id) as permission_count,
            COUNT(DISTINCT ur.user_id) as user_count
        FROM user_roles r
        LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
        LEFT JOIN user_role_assignments ur ON r.role_id = ur.role_id 
            AND ur.is_active = TRUE
        WHERE 1=1 {role_filter}
        GROUP BY r.role_id, r.role_name, r.role_description, r.is_system_role, r.created_date
        ORDER BY r.role_name
        """
        
        cursor.execute(roles_query, role_params)
        role_rows = cursor.fetchall()
        
        # Get all permissions
        permissions_filter = ""
        perm_params = []
        if resource:
            permissions_filter = " WHERE p.resource = %s"
            perm_params.append(resource)
        
        permissions_query = f"""
        SELECT 
            p.permission_id,
            p.permission_name,
            p.resource,
            p.action,
            p.description,
            p.is_system_permission
        FROM permissions p
        {permissions_filter}
        ORDER BY p.resource, p.action
        """
        
        cursor.execute(permissions_query, perm_params)
        permission_rows = cursor.fetchall()
        
        # Build roles with their permissions
        roles = []
        permission_matrix = {}
        
        for role_row in role_rows:
            role_id = role_row['role_id']
            
            # Get permissions for this role
            cursor.execute("""
            SELECT 
                p.permission_id,
                p.permission_name,
                p.resource,
                p.action,
                p.description,
                p.is_system_permission
            FROM permissions p
            INNER JOIN role_permissions rp ON p.permission_id = rp.permission_id
            WHERE rp.role_id = %s
            ORDER BY p.resource, p.action
            """, (role_id,))
            
            role_permissions = []
            role_permission_names = []
            
            for perm_row in cursor.fetchall():
                permission = Permission(
                    permission_id=perm_row['permission_id'],
                    permission_name=perm_row['permission_name'],
                    resource=perm_row['resource'],
                    action=perm_row['action'],
                    description=perm_row['description'],
                    is_system_permission=perm_row['is_system_permission']
                )
                role_permissions.append(permission)
                role_permission_names.append(perm_row['permission_name'])
            
            # Add to permission matrix
            permission_matrix[role_row['role_name']] = role_permission_names
            
            role = Role(
                role_id=role_row['role_id'],
                role_name=role_row['role_name'],
                role_description=role_row['role_description'],
                is_system_role=role_row['is_system_role'],
                created_date=role_row['created_date'],
                permissions=role_permissions,
                user_count=role_row['user_count']
            )
            roles.append(role)
        
        # Get user role assignments
        user_assignments_filter = ""
        if not include_inactive_users:
            user_assignments_filter = " AND ura.is_active = TRUE"
        
        user_assignments_query = f"""
        SELECT 
            u.user_id,
            u.username,
            u.email,
            r.role_id,
            r.role_name,
            ura.assigned_date,
            ura.assigned_by,
            ura.is_active
        FROM user_role_assignments ura
        INNER JOIN users u ON ura.user_id = u.user_id
        INNER JOIN user_roles r ON ura.role_id = r.role_id
        WHERE 1=1 {user_assignments_filter}
        ORDER BY u.username, r.role_name
        """
        
        cursor.execute(user_assignments_query)
        assignment_rows = cursor.fetchall()
        
        user_assignments = []
        for assignment_row in assignment_rows:
            assignment = UserRoleAssignment(
                user_id=assignment_row['user_id'],
                username=assignment_row['username'],
                email=assignment_row['email'],
                role_id=assignment_row['role_id'],
                role_name=assignment_row['role_name'],
                assigned_date=assignment_row['assigned_date'],
                assigned_by=assignment_row['assigned_by'],
                is_active=assignment_row['is_active']
            )
            user_assignments.append(assignment)
        
        cursor.close()
        conn.close()
        
        return RolePermissionsResponse(
            status="success",
            total_roles=len(roles),
            roles=roles,
            total_permissions=len(permission_rows),
            user_assignments=user_assignments,
            permission_matrix=permission_matrix,
            timestamp=datetime.now()
        )
        
    except psycopg2.Error as e:
        raise HTTPException(status_code=500, detail=f"Database query failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"RBAC data retrieval failed: {str(e)}")

@router.get("/api/v1/admin/roles/permissions/health", tags=["🔧 System Administration"])
async def roles_permissions_health_check():
    """Health check for roles and permissions endpoint"""
    
    try:
        conn = get_database_connection()
        cursor = conn.cursor()
        
        # Verify RBAC tables exist and are accessible
        cursor.execute("""
        SELECT 
            (SELECT COUNT(*) FROM user_roles) as total_roles,
            (SELECT COUNT(*) FROM permissions) as total_permissions,
            (SELECT COUNT(*) FROM role_permissions) as role_permission_mappings,
            (SELECT COUNT(*) FROM user_role_assignments WHERE is_active = TRUE) as active_assignments,
            (SELECT COUNT(DISTINCT user_id) FROM user_role_assignments WHERE is_active = TRUE) as users_with_roles
        """)
        
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        return {
            "status": "healthy",
            "endpoint": "GET /api/v1/admin/roles/permissions",
            "bdd_scenario": "Manage User Roles and Permissions",
            "database_connection": "✅ Connected to wfm_enterprise",
            "table_validation": "✅ RBAC tables accessible",
            "rbac_statistics": {
                "total_roles": result[0],
                "total_permissions": result[1],
                "role_permission_mappings": result[2],
                "active_user_assignments": result[3],
                "users_with_roles": result[4]
            },
            "features": [
                "Real PostgreSQL RBAC queries",
                "Permission matrix generation",
                "User role assignment tracking",
                "System vs custom role filtering",
                "Resource-based permission filtering"
            ],
            "no_mock_data": True,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

"""
IMPLEMENTATION NOTES:
✅ Task 48 Complete: GET /api/v1/admin/roles/permissions
✅ BDD Scenario: "Manage User Roles and Permissions"
✅ Real PostgreSQL RBAC queries to user_roles and role_permissions tables
✅ NO MOCK DATA - actual database integration
✅ Comprehensive permission matrix generation
✅ User role assignment tracking with activity status
✅ System and custom role differentiation
✅ Resource-based permission filtering

REAL DATABASE FEATURES:
- Direct connection to wfm_enterprise PostgreSQL database
- Queries user_roles, role_permissions, permissions, and user_role_assignments tables
- Builds comprehensive permission matrix for role management
- Real-time RBAC validation and user assignment tracking
- System vs custom role filtering
- Resource-based permission organization
"""