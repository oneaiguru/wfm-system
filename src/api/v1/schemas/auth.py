"""
Authentication Schemas for WFM Enterprise API
Pydantic models for auth-related requests and responses
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, EmailStr, validator
import uuid


class Token(BaseModel):
    """Basic token model"""
    access_token: str
    token_type: str = "bearer"


class TokenResponse(BaseModel):
    """Complete token response"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    scope: str = ""


class TokenData(BaseModel):
    """Token payload data"""
    sub: Optional[str] = None
    email: Optional[str] = None
    scopes: List[str] = Field(default_factory=list)
    organization_id: Optional[str] = None
    department_id: Optional[str] = None


class UserBase(BaseModel):
    """Base user model"""
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    is_active: bool = True


class UserCreate(UserBase):
    """User creation model"""
    password: str = Field(..., min_length=8)
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one digit')
        return v


class UserRegister(UserCreate):
    """User registration model"""
    confirm_password: str
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'password' in values and v != values['password']:
            raise ValueError('Passwords do not match')
        return v


class UserUpdate(BaseModel):
    """User update model"""
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    """User response model"""
    id: str
    is_verified: bool = False
    is_admin: bool = False
    is_superuser: bool = False
    organization_id: Optional[str] = None
    department_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        orm_mode = True


class UserLogin(BaseModel):
    """User login model"""
    username: str = Field(..., description="Username or email")
    password: str = Field(..., description="Password")
    remember_me: bool = Field(False, description="Extended session")


class PasswordReset(BaseModel):
    """Password reset request"""
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation"""
    token: str
    new_password: str = Field(..., min_length=8)
    confirm_password: str
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('Passwords do not match')
        return v


class PasswordChange(BaseModel):
    """Password change for authenticated users"""
    current_password: str
    new_password: str = Field(..., min_length=8)
    confirm_password: str
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('Passwords do not match')
        return v


class OAuth2Client(BaseModel):
    """OAuth2 client model"""
    client_id: str
    client_name: str
    redirect_uris: List[str]
    grant_types: List[str] = ["authorization_code", "refresh_token"]
    response_types: List[str] = ["code"]
    scopes: List[str] = []
    client_uri: Optional[str] = None
    logo_uri: Optional[str] = None
    contacts: List[str] = []


class OAuth2ClientCreate(BaseModel):
    """OAuth2 client creation"""
    client_name: str = Field(..., min_length=3, max_length=100)
    redirect_uris: List[str] = Field(..., min_items=1)
    grant_types: List[str] = ["authorization_code", "refresh_token"]
    scopes: List[str] = []
    client_uri: Optional[str] = None
    logo_uri: Optional[str] = None
    contacts: List[str] = []


class OAuth2ClientResponse(OAuth2Client):
    """OAuth2 client response"""
    client_secret: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class OAuth2AuthRequest(BaseModel):
    """OAuth2 authorization request"""
    client_id: str
    redirect_uri: str
    response_type: str = "code"
    scope: str = ""
    state: Optional[str] = None
    code_challenge: Optional[str] = None
    code_challenge_method: Optional[str] = None


class OAuth2CallbackResponse(BaseModel):
    """OAuth2 callback response"""
    code: str
    state: Optional[str] = None


class OAuth2TokenRequest(BaseModel):
    """OAuth2 token request"""
    grant_type: str
    client_id: str
    client_secret: str
    code: Optional[str] = None
    redirect_uri: Optional[str] = None
    refresh_token: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    scope: Optional[str] = None
    code_verifier: Optional[str] = None


class APIKeyBase(BaseModel):
    """Base API key model"""
    name: str = Field(..., min_length=3, max_length=100)
    scopes: List[str] = Field(default_factory=list)
    expires_at: Optional[datetime] = None


class APIKeyCreate(APIKeyBase):
    """API key creation"""
    pass


class APIKeyResponse(APIKeyBase):
    """API key response"""
    id: str
    key: Optional[str] = None  # Only returned on creation
    created_at: datetime
    last_used: Optional[datetime] = None
    is_active: bool = True
    
    class Config:
        orm_mode = True


class APIKeyUpdate(BaseModel):
    """API key update"""
    name: Optional[str] = Field(None, min_length=3, max_length=100)
    scopes: Optional[List[str]] = None
    expires_at: Optional[datetime] = None
    is_active: Optional[bool] = None


class RoleBase(BaseModel):
    """Base role model"""
    name: str = Field(..., min_length=3, max_length=50)
    description: Optional[str] = Field(None, max_length=200)
    is_active: bool = True


class RoleCreate(RoleBase):
    """Role creation"""
    permissions: List[str] = Field(default_factory=list)


class RoleResponse(RoleBase):
    """Role response"""
    id: str
    permissions: List[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class PermissionBase(BaseModel):
    """Base permission model"""
    name: str = Field(..., min_length=3, max_length=100)
    description: Optional[str] = Field(None, max_length=200)
    resource: str = Field(..., max_length=50)
    action: str = Field(..., max_length=50)


class PermissionCreate(PermissionBase):
    """Permission creation"""
    pass


class PermissionResponse(PermissionBase):
    """Permission response"""
    id: str
    created_at: datetime
    
    class Config:
        orm_mode = True


class UserRoleAssignment(BaseModel):
    """User role assignment"""
    user_id: str
    role_ids: List[str]


class UserPermissionAssignment(BaseModel):
    """User permission assignment"""
    user_id: str
    permission_ids: List[str]


class SessionInfo(BaseModel):
    """User session information"""
    session_id: str
    user_id: str
    ip_address: str
    user_agent: str
    created_at: datetime
    last_activity: datetime
    expires_at: datetime
    is_active: bool = True


class LoginAttempt(BaseModel):
    """Login attempt tracking"""
    username: str
    ip_address: str
    success: bool
    timestamp: datetime
    failure_reason: Optional[str] = None


class SecurityEvent(BaseModel):
    """Security event logging"""
    event_type: str
    user_id: Optional[str] = None
    ip_address: str
    user_agent: Optional[str] = None
    details: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime
    severity: str = "info"  # info, warning, error, critical


class TwoFactorAuth(BaseModel):
    """Two-factor authentication"""
    enabled: bool = False
    method: str = "totp"  # totp, sms, email
    backup_codes: List[str] = Field(default_factory=list)
    created_at: datetime
    last_used: Optional[datetime] = None


class TwoFactorSetup(BaseModel):
    """Two-factor setup request"""
    method: str = "totp"
    phone_number: Optional[str] = None


class TwoFactorVerify(BaseModel):
    """Two-factor verification"""
    code: str = Field(..., min_length=6, max_length=6)


class DeviceInfo(BaseModel):
    """Device information"""
    device_id: str
    device_name: str
    device_type: str  # mobile, desktop, tablet
    os: str
    browser: str
    ip_address: str
    trusted: bool = False
    created_at: datetime
    last_used: datetime


class TrustedDevice(BaseModel):
    """Trusted device registration"""
    device_id: str
    device_name: str
    expires_at: Optional[datetime] = None


class AuditLog(BaseModel):
    """Audit log entry"""
    id: str
    user_id: Optional[str] = None
    action: str
    resource: str
    resource_id: Optional[str] = None
    ip_address: str
    user_agent: Optional[str] = None
    details: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime
    
    class Config:
        orm_mode = True


class LoginHistory(BaseModel):
    """User login history"""
    user_id: str
    ip_address: str
    location: Optional[str] = None
    device_info: Optional[DeviceInfo] = None
    success: bool
    timestamp: datetime
    session_duration: Optional[timedelta] = None