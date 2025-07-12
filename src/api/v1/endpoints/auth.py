"""
Authentication Endpoints for WFM Enterprise API
Handles login, logout, token refresh, and OAuth2 flows
"""

from datetime import timedelta
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field, EmailStr
import secrets
import uuid

from ..schemas.auth import (
    Token, TokenResponse, UserLogin, UserRegister, UserResponse,
    PasswordReset, PasswordResetConfirm, OAuth2AuthRequest,
    OAuth2CallbackResponse, APIKeyCreate, APIKeyResponse
)
from ...auth.dependencies import (
    get_current_user, get_current_admin_user, get_optional_user,
    rate_limit_standard, rate_limit_strict
)
from ...auth.jwt_handler import jwt_handler
from ...auth.oauth2 import oauth2_handler
from ...core.database import get_db
from ...models.user import User
from ...models.api_key import APIKey
from ...utils.email import send_email
from ...utils.security import verify_password, get_password_hash


router = APIRouter(prefix="/auth", tags=["authentication"])


class LoginRequest(BaseModel):
    """Login request model"""
    username: str = Field(..., description="Username or email")
    password: str = Field(..., description="Password")
    remember_me: bool = Field(False, description="Extended session")


class RefreshRequest(BaseModel):
    """Token refresh request"""
    refresh_token: str = Field(..., description="Refresh token")


@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limit_standard)
):
    """Authenticate user and return JWT tokens"""
    # Find user by username or email
    user = db.query(User).filter(
        (User.username == request.username) | (User.email == request.username)
    ).first()
    
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account is disabled"
        )
    
    # Create token data
    token_data = {
        "sub": str(user.id),
        "email": user.email,
        "scopes": await get_user_scopes(user),
        "organization_id": str(user.organization_id) if user.organization_id else None,
        "department_id": str(user.department_id) if user.department_id else None
    }
    
    # Set token expiration
    access_expires = timedelta(hours=8 if request.remember_me else 1)
    refresh_expires = timedelta(days=30 if request.remember_me else 7)
    
    # Create tokens
    access_token = jwt_handler.create_access_token(token_data, access_expires)
    refresh_token = jwt_handler.create_refresh_token(token_data, refresh_expires)
    
    # Update user login info
    user.last_login = datetime.utcnow()
    db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=int(access_expires.total_seconds()),
        scope=" ".join(token_data.get("scopes", []))
    )


@router.post("/token", response_model=TokenResponse)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
    _: None = Depends(rate_limit_standard)
):
    """OAuth2 password flow - compatible with OpenAPI UI"""
    # Find user
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account is disabled"
        )
    
    # Create token data
    token_data = {
        "sub": str(user.id),
        "email": user.email,
        "scopes": form_data.scopes if form_data.scopes else await get_user_scopes(user),
        "organization_id": str(user.organization_id) if user.organization_id else None,
        "department_id": str(user.department_id) if user.department_id else None
    }
    
    # Create tokens
    access_token = jwt_handler.create_access_token(token_data)
    refresh_token = jwt_handler.create_refresh_token(token_data)
    
    # Update user login info
    user.last_login = datetime.utcnow()
    db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=1800,  # 30 minutes
        scope=" ".join(token_data.get("scopes", []))
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_access_token(
    request: RefreshRequest,
    _: None = Depends(rate_limit_standard)
):
    """Refresh access token using refresh token"""
    return await jwt_handler.refresh_access_token(request.refresh_token)


@router.post("/logout")
async def logout(
    response: Response,
    current_user: User = Depends(get_current_user)
):
    """Logout user and invalidate tokens"""
    # In a real implementation, you'd revoke the token
    # For now, we'll just clear any cookies
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token")
    
    return {"message": "Successfully logged out"}


@router.post("/revoke")
async def revoke_token(
    token: str,
    current_user: User = Depends(get_current_user)
):
    """Revoke a specific token"""
    success = await jwt_handler.revoke_token(token)
    if success:
        return {"message": "Token revoked successfully"}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid token"
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """Get current user information"""
    return UserResponse.from_orm(current_user)


@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserRegister,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limit_standard)
):
    """Register new user (if registration is enabled)"""
    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.username == user_data.username) | (User.email == user_data.email)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists"
        )
    
    # Create new user
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        is_active=True,
        is_verified=False  # Require email verification
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Send verification email
    # await send_verification_email(user)
    
    return UserResponse.from_orm(user)


@router.post("/password-reset")
async def request_password_reset(
    request: PasswordReset,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limit_strict)
):
    """Request password reset"""
    user = db.query(User).filter(User.email == request.email).first()
    
    if user:
        # Generate reset token
        reset_token = jwt_handler.create_password_reset_token(user.email)
        
        # Send reset email
        await send_email(
            to=user.email,
            subject="Password Reset Request",
            template="password_reset",
            context={"reset_token": reset_token, "user": user}
        )
    
    # Always return success to prevent email enumeration
    return {"message": "Password reset instructions sent to email"}


@router.post("/password-reset/confirm")
async def confirm_password_reset(
    request: PasswordResetConfirm,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limit_strict)
):
    """Confirm password reset with token"""
    try:
        payload = await jwt_handler.decode_token(request.token)
        
        if payload.get("type") != "password_reset":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid reset token"
            )
        
        email = payload.get("sub")
        user = db.query(User).filter(User.email == email).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User not found"
            )
        
        # Update password
        user.hashed_password = get_password_hash(request.new_password)
        db.commit()
        
        # Revoke reset token
        await jwt_handler.revoke_token(request.token)
        
        return {"message": "Password reset successful"}
        
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid reset token"
        )


# OAuth2 Authorization Code Flow
@router.get("/authorize")
async def authorize(
    client_id: str,
    redirect_uri: str,
    response_type: str = "code",
    scope: str = "",
    state: Optional[str] = None,
    code_challenge: Optional[str] = None,
    code_challenge_method: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """OAuth2 authorization endpoint"""
    # Validate client
    client = oauth2_handler.validate_client(client_id)
    
    # Validate redirect URI
    if not oauth2_handler.validate_redirect_uri(client, redirect_uri):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid redirect URI"
        )
    
    # Generate authorization code
    scopes = scope.split() if scope else []
    auth_code = oauth2_handler.generate_authorization_code(
        client_id=client_id,
        user_id=str(current_user.id),
        redirect_uri=redirect_uri,
        scopes=scopes,
        code_challenge=code_challenge,
        code_challenge_method=code_challenge_method
    )
    
    # Redirect with authorization code
    params = {"code": auth_code}
    if state:
        params["state"] = state
    
    query_string = "&".join([f"{k}={v}" for k, v in params.items()])
    return {"redirect_url": f"{redirect_uri}?{query_string}"}


@router.post("/token/oauth2", response_model=TokenResponse)
async def oauth2_token(
    grant_type: str,
    client_id: str,
    client_secret: str,
    code: Optional[str] = None,
    redirect_uri: Optional[str] = None,
    refresh_token: Optional[str] = None,
    username: Optional[str] = None,
    password: Optional[str] = None,
    scope: Optional[str] = None,
    code_verifier: Optional[str] = None,
    _: None = Depends(rate_limit_standard)
):
    """OAuth2 token endpoint"""
    if grant_type == "authorization_code":
        return await oauth2_handler.exchange_code_for_token(
            code=code,
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri=redirect_uri,
            code_verifier=code_verifier
        )
    
    elif grant_type == "password":
        return await oauth2_handler.password_grant(
            username=username,
            password=password,
            scopes=scope.split() if scope else None
        )
    
    elif grant_type == "refresh_token":
        return await oauth2_handler.refresh_token_grant(
            refresh_token=refresh_token,
            client_id=client_id,
            client_secret=client_secret
        )
    
    elif grant_type == "client_credentials":
        return await oauth2_handler.client_credentials_grant(
            client_id=client_id,
            client_secret=client_secret,
            scopes=scope.split() if scope else None
        )
    
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported grant type"
        )


# API Key Management
@router.post("/api-keys", response_model=APIKeyResponse)
async def create_api_key(
    key_data: APIKeyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new API key"""
    # Generate API key
    key_value = jwt_handler.create_api_key(str(current_user.id), key_data.name)
    
    # Store in database
    api_key = APIKey(
        id=str(uuid.uuid4()),
        name=key_data.name,
        key_hash=get_password_hash(key_value),
        user_id=current_user.id,
        scopes=key_data.scopes,
        expires_at=key_data.expires_at
    )
    
    db.add(api_key)
    db.commit()
    
    return APIKeyResponse(
        id=api_key.id,
        name=api_key.name,
        key=key_value,  # Only returned once
        scopes=api_key.scopes,
        created_at=api_key.created_at,
        expires_at=api_key.expires_at
    )


@router.get("/api-keys")
async def list_api_keys(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List user's API keys"""
    keys = db.query(APIKey).filter(
        APIKey.user_id == current_user.id,
        APIKey.is_active == True
    ).all()
    
    return [
        {
            "id": key.id,
            "name": key.name,
            "scopes": key.scopes,
            "created_at": key.created_at,
            "expires_at": key.expires_at,
            "last_used": key.last_used
        }
        for key in keys
    ]


@router.delete("/api-keys/{key_id}")
async def revoke_api_key(
    key_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Revoke API key"""
    api_key = db.query(APIKey).filter(
        APIKey.id == key_id,
        APIKey.user_id == current_user.id
    ).first()
    
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="API key not found"
        )
    
    api_key.is_active = False
    db.commit()
    
    return {"message": "API key revoked"}


# External OAuth2 Providers
@router.get("/oauth2/{provider}/authorize")
async def oauth2_provider_authorize(
    provider: str,
    redirect_uri: str,
    state: Optional[str] = None
):
    """Redirect to external OAuth2 provider"""
    try:
        auth_url = oauth2_handler.get_provider_auth_url(
            provider=provider,
            client_id="your-client-id",  # TODO: Get from config
            redirect_uri=redirect_uri,
            state=state or str(uuid.uuid4())
        )
        
        return {"authorize_url": auth_url}
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/oauth2/{provider}/callback")
async def oauth2_provider_callback(
    provider: str,
    code: str,
    state: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Handle OAuth2 provider callback"""
    try:
        # Exchange code for tokens
        tokens = await oauth2_handler.exchange_provider_code(
            provider=provider,
            code=code,
            client_id="your-client-id",  # TODO: Get from config
            client_secret="your-client-secret",  # TODO: Get from config
            redirect_uri="your-redirect-uri"  # TODO: Get from config
        )
        
        # Get user info from provider
        user_info = await oauth2_handler.get_provider_userinfo(
            provider=provider,
            access_token=tokens["access_token"]
        )
        
        # Find or create user
        user = db.query(User).filter(User.email == user_info["email"]).first()
        
        if not user:
            # Create new user from provider info
            user = User(
                username=user_info.get("email"),
                email=user_info["email"],
                first_name=user_info.get("given_name", ""),
                last_name=user_info.get("family_name", ""),
                is_active=True,
                is_verified=True,  # Provider-verified
                provider=provider,
                provider_id=user_info.get("id")
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        
        # Create our tokens
        token_data = {
            "sub": str(user.id),
            "email": user.email,
            "scopes": await get_user_scopes(user)
        }
        
        access_token = jwt_handler.create_access_token(token_data)
        refresh_token = jwt_handler.create_refresh_token(token_data)
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=1800
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"OAuth2 callback failed: {str(e)}"
        )


async def get_user_scopes(user: User) -> List[str]:
    """Get user scopes based on roles and permissions"""
    scopes = ["read"]  # Default scope
    
    if user.is_admin:
        scopes.extend(["write", "admin"])
    
    if user.is_superuser:
        scopes.append("superuser")
    
    # Add role-based scopes
    for role in user.roles:
        scopes.append(f"role:{role.name}")
    
    return list(set(scopes))  # Remove duplicates