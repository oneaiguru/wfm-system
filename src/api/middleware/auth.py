"""
Simple Authentication Middleware for Demo
========================================
Provides basic API key authentication for professional appearance
"""

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from typing import Optional

# API Key configuration
API_KEY_NAME = "X-API-Key"
DEMO_API_KEYS = {
    "demo-api-key-2024": {
        "name": "Demo Access",
        "permissions": ["read", "write", "demo"]
    },
    "readonly-key-2024": {
        "name": "Read Only Access", 
        "permissions": ["read"]
    },
    "admin-key-2024": {
        "name": "Admin Access",
        "permissions": ["read", "write", "admin", "demo"]
    }
}

# Create API key header security scheme
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)


async def get_api_key(api_key: Optional[str] = Security(api_key_header)) -> dict:
    """
    Validate API key and return permissions
    
    For demo purposes, this is a simple key lookup.
    In production, use JWT tokens or OAuth2.
    """
    if api_key is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required",
            headers={"WWW-Authenticate": "ApiKey"}
        )
    
    if api_key not in DEMO_API_KEYS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key"
        )
    
    return {
        "api_key": api_key,
        **DEMO_API_KEYS[api_key]
    }


async def require_permission(
    permission: str,
    api_key_info: dict = Security(get_api_key)
) -> dict:
    """
    Require specific permission for endpoint access
    """
    if permission not in api_key_info.get("permissions", []):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Permission '{permission}' required"
        )
    
    return api_key_info


# Dependency shortcuts for common permissions
async def require_read(api_key_info: dict = Security(get_api_key)) -> dict:
    """Require read permission"""
    return await require_permission("read", api_key_info)


async def require_write(api_key_info: dict = Security(get_api_key)) -> dict:
    """Require write permission"""
    return await require_permission("write", api_key_info)


async def require_admin(api_key_info: dict = Security(get_api_key)) -> dict:
    """Require admin permission"""
    return await require_permission("admin", api_key_info)


async def require_demo(api_key_info: dict = Security(get_api_key)) -> dict:
    """Require demo permission"""
    return await require_permission("demo", api_key_info)


# Optional authentication (for public endpoints)
async def optional_api_key(
    api_key: Optional[str] = Security(api_key_header)
) -> Optional[dict]:
    """
    Optional API key validation
    Returns None if no key provided, validates if provided
    """
    if api_key is None:
        return None
    
    if api_key in DEMO_API_KEYS:
        return {
            "api_key": api_key,
            **DEMO_API_KEYS[api_key]
        }
    
    return None