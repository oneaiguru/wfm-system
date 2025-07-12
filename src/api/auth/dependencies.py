"""
Authentication Dependencies for FastAPI
Provides dependency injection for authentication and authorization
"""

from typing import List, Optional, Dict, Any
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import time

from .jwt_handler import jwt_handler
from .oauth2 import oauth2_password_scheme
from ..core.database import get_db
from ..models.user import User
from ..models.permissions import Permission, Role


# Security schemes
security = HTTPBearer()


class AuthenticationError(HTTPException):
    """Custom authentication error"""
    def __init__(self, detail: str = "Authentication required"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class AuthorizationError(HTTPException):
    """Custom authorization error"""
    def __init__(self, detail: str = "Insufficient permissions"):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    token = credentials.credentials
    
    # Decode and validate token
    payload = await jwt_handler.decode_token(token)
    user_id = payload.get("sub")
    
    if not user_id:
        raise AuthenticationError("Invalid token payload")
    
    # Get user from database
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AuthenticationError("User not found")
    
    if not user.is_active:
        raise AuthenticationError("User account is disabled")
    
    # Cache user permissions
    await cache_user_permissions(user)
    
    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current active user (alias for backward compatibility)"""
    return current_user


async def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current user with admin privileges"""
    if not current_user.is_admin:
        raise AuthorizationError("Admin privileges required")
    return current_user


async def get_current_superuser(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current superuser"""
    if not current_user.is_superuser:
        raise AuthorizationError("Superuser privileges required")
    return current_user


def require_permissions(required_permissions: List[str]):
    """Dependency factory for permission-based authorization"""
    
    async def check_permissions(
        current_user: User = Depends(get_current_user)
    ) -> User:
        user_permissions = await get_user_permissions(current_user)
        
        for permission in required_permissions:
            if permission not in user_permissions:
                raise AuthorizationError(
                    f"Missing required permission: {permission}"
                )
        
        return current_user
    
    return check_permissions


def require_roles(required_roles: List[str]):
    """Dependency factory for role-based authorization"""
    
    async def check_roles(
        current_user: User = Depends(get_current_user)
    ) -> User:
        user_roles = await get_user_roles(current_user)
        
        for role in required_roles:
            if role not in user_roles:
                raise AuthorizationError(
                    f"Missing required role: {role}"
                )
        
        return current_user
    
    return check_roles


def require_scope(required_scopes: List[str]):
    """Dependency factory for OAuth2 scope-based authorization"""
    
    async def check_scopes(
        credentials: HTTPAuthorizationCredentials = Depends(security)
    ) -> Dict[str, Any]:
        token = credentials.credentials
        payload = await jwt_handler.decode_token(token)
        
        token_scopes = payload.get("scopes", [])
        
        for scope in required_scopes:
            if scope not in token_scopes:
                raise AuthorizationError(
                    f"Missing required scope: {scope}"
                )
        
        return payload
    
    return check_scopes


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """Get current user if authenticated, None otherwise"""
    if not credentials:
        return None
    
    try:
        token = credentials.credentials
        payload = await jwt_handler.decode_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            return None
        
        user = db.query(User).filter(User.id == user_id).first()
        return user if user and user.is_active else None
        
    except HTTPException:
        return None


async def get_user_permissions(user: User) -> List[str]:
    """Get user permissions from cache or database"""
    # Try cache first
    cached_permissions = await jwt_handler.get_cached_permissions(str(user.id))
    if cached_permissions:
        return cached_permissions.get("permissions", [])
    
    # Get from database
    permissions = []
    
    # Direct permissions
    for permission in user.permissions:
        permissions.append(permission.name)
    
    # Role-based permissions
    for role in user.roles:
        for permission in role.permissions:
            permissions.append(permission.name)
    
    # Remove duplicates
    permissions = list(set(permissions))
    
    # Cache permissions
    await jwt_handler.cache_user_permissions(
        str(user.id),
        {"permissions": permissions, "roles": [r.name for r in user.roles]}
    )
    
    return permissions


async def get_user_roles(user: User) -> List[str]:
    """Get user roles"""
    return [role.name for role in user.roles]


async def cache_user_permissions(user: User):
    """Cache user permissions for performance"""
    permissions = await get_user_permissions(user)
    roles = await get_user_roles(user)
    
    await jwt_handler.cache_user_permissions(
        str(user.id),
        {
            "permissions": permissions,
            "roles": roles,
            "organization_id": user.organization_id,
            "department_id": user.department_id
        }
    )


def organization_access_required(
    allow_admin: bool = True,
    allow_cross_org: bool = False
):
    """Dependency factory for organization-level access control"""
    
    async def check_organization_access(
        organization_id: str,
        current_user: User = Depends(get_current_user)
    ) -> User:
        # Superusers can access everything
        if current_user.is_superuser:
            return current_user
        
        # Admins can access if allowed
        if allow_admin and current_user.is_admin:
            return current_user
        
        # Cross-organization access check
        if not allow_cross_org:
            if str(current_user.organization_id) != organization_id:
                raise AuthorizationError(
                    "Access denied: organization mismatch"
                )
        
        return current_user
    
    return check_organization_access


def department_access_required(
    allow_admin: bool = True,
    allow_cross_dept: bool = False
):
    """Dependency factory for department-level access control"""
    
    async def check_department_access(
        department_id: str,
        current_user: User = Depends(get_current_user)
    ) -> User:
        # Superusers can access everything
        if current_user.is_superuser:
            return current_user
        
        # Admins can access if allowed
        if allow_admin and current_user.is_admin:
            return current_user
        
        # Cross-department access check
        if not allow_cross_dept:
            if str(current_user.department_id) != department_id:
                raise AuthorizationError(
                    "Access denied: department mismatch"
                )
        
        return current_user
    
    return check_department_access


class RateLimitChecker:
    """Rate limiting dependency"""
    
    def __init__(self, max_requests: int = 100, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: Dict[str, List[float]] = {}
    
    async def __call__(self, request: Request):
        # Get client identifier
        client_id = request.client.host
        
        # Get user ID if authenticated
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = await jwt_handler.decode_token(token)
                client_id = payload.get("sub", client_id)
            except:
                pass  # Use IP if token invalid
        
        # Check rate limit
        now = time.time()
        
        # Initialize or clean old requests
        if client_id not in self.requests:
            self.requests[client_id] = []
        
        # Remove old requests outside the window
        self.requests[client_id] = [
            req_time for req_time in self.requests[client_id]
            if now - req_time < self.window_seconds
        ]
        
        # Check if limit exceeded
        if len(self.requests[client_id]) >= self.max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded",
                headers={"Retry-After": str(self.window_seconds)}
            )
        
        # Add current request
        self.requests[client_id].append(now)


# Rate limit instances
rate_limit_standard = RateLimitChecker(max_requests=100, window_seconds=60)
rate_limit_strict = RateLimitChecker(max_requests=10, window_seconds=60)
rate_limit_lenient = RateLimitChecker(max_requests=1000, window_seconds=60)


# Service account authentication
async def get_service_account(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """Authenticate service account using API key or client credentials"""
    token = credentials.credentials
    payload = await jwt_handler.decode_token(token)
    
    # Check if it's a service account token
    if payload.get("type") not in ["service", "api_key"]:
        raise AuthenticationError("Service account token required")
    
    return payload


# Multi-tenant support
def tenant_required(tenant_param: str = "tenant_id"):
    """Dependency factory for multi-tenant applications"""
    
    async def check_tenant(
        request: Request,
        current_user: User = Depends(get_current_user)
    ) -> str:
        # Get tenant ID from path, query, or header
        tenant_id = (
            request.path_params.get(tenant_param) or
            request.query_params.get(tenant_param) or
            request.headers.get("X-Tenant-ID")
        )
        
        if not tenant_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tenant ID required"
            )
        
        # Validate user has access to tenant
        user_tenants = getattr(current_user, "tenant_ids", [])
        if tenant_id not in user_tenants and not current_user.is_superuser:
            raise AuthorizationError(
                "Access denied: insufficient tenant permissions"
            )
        
        return tenant_id
    
    return check_tenant