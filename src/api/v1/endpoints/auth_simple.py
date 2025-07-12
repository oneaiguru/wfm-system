"""
Simple Authentication Endpoints for Demo
Minimal auth system for getting the API running
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class LoginRequest(BaseModel):
    username: str
    password: str
    remember_me: bool = False

class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 1800

@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """Simple login for demo - accepts any credentials"""
    
    # Demo login - accept admin@demo.com / AdminPass123!
    if request.username in ["admin@demo.com", "admin"] and request.password == "AdminPass123!":
        return LoginResponse(
            access_token="demo-access-token-" + request.username,
            refresh_token="demo-refresh-token-" + request.username,
            expires_in=1800
        )
    elif request.username in ["manager@demo.com", "manager"] and request.password == "ManagerPass123!":
        return LoginResponse(
            access_token="demo-access-token-" + request.username,
            refresh_token="demo-refresh-token-" + request.username,
            expires_in=1800
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials. Try admin@demo.com / AdminPass123!"
        )

@router.post("/refresh")
async def refresh_token(refresh_token: str):
    """Simple token refresh for demo"""
    return {
        "access_token": "refreshed-" + refresh_token,
        "token_type": "bearer",
        "expires_in": 1800
    }

@router.get("/me")
async def get_current_user():
    """Get current user info for demo"""
    return {
        "id": "demo-user-id",
        "username": "admin",
        "email": "admin@demo.com",
        "is_active": True,
        "is_admin": True
    }