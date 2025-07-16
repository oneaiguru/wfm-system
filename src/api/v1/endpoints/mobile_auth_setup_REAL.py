"""
POST /api/v1/mobile/auth/setup - Mobile Application Authentication and Setup
BDD Implementation: 14-mobile-personal-cabinet.feature
Scenario: "Mobile Application Authentication and Setup" (Lines 12-23)

This endpoint implements the mobile JWT authentication with device registration,
following the exact BDD scenario requirements:
- Mobile app authentication via JWT tokens
- Device registration and push notification setup
- Biometric authentication options
- Session management for mobile devices
"""

from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import Optional
import logging
from datetime import datetime, timedelta

from api.core.database import get_db
import asyncpg

# BDD TRACEABILITY: Lines 12-23 "Mobile Application Authentication and Setup"
logger = logging.getLogger(__name__)

router = APIRouter()

class MobileAuthRequest(BaseModel):
    """
    BDD Scenario Input: Lines 15-18
    - Username (employee_login)
    - Password (employee_password)
    - Device information for registration
    """
    username: str = Field(..., description="Employee login credential")
    password: str = Field(..., description="Employee password")
    device_id: str = Field(..., description="Unique device identifier")
    device_type: str = Field(..., description="iOS, Android, or Web")
    push_token: Optional[str] = Field(None, description="Push notification token")
    enable_biometric: Optional[bool] = Field(False, description="Enable biometric auth")
    biometric_type: Optional[str] = Field(None, description="TouchID, FaceID, Fingerprint")

class MobileAuthResponse(BaseModel):
    """
    BDD Scenario Output: Lines 19-23
    - JWT token for session management
    - Mobile-optimized interface confirmation
    - Biometric authentication setup
    - Push notification registration confirmation
    """
    jwt_token: str = Field(..., description="JWT token for authentication")
    refresh_token: str = Field(..., description="Token for session refresh")
    expires_at: datetime = Field(..., description="Token expiration time")
    mobile_interface_enabled: bool = Field(..., description="Mobile UI confirmed")
    biometric_setup_available: bool = Field(..., description="Biometric auth available")
    push_notifications_registered: bool = Field(..., description="Push notifications ready")
    employee_tab_n: str = Field(..., description="Employee identifier")

@router.post("/api/v1/mobile/auth/setup", 
            response_model=MobileAuthResponse,
            summary="Mobile Application Authentication and Setup",
            description="""
            BDD Scenario: Mobile Application Authentication and Setup
            
            Implements the complete mobile authentication flow:
            1. Validates employee credentials
            2. Creates mobile session with JWT token
            3. Registers device for push notifications
            4. Sets up biometric authentication options
            5. Enables mobile-optimized interface access
            
            Real database implementation using mobile_sessions table.
            """)
async def setup_mobile_auth(
    request: MobileAuthRequest,
    db: asyncpg.Connection = Depends(get_db)
) -> MobileAuthResponse:
    """
    BDD Implementation: "Mobile Application Authentication and Setup"
    
    This endpoint follows the exact BDD scenario steps:
    1. User launches mobile app for first time (Lines 14)
    2. Enters credentials (Lines 15-18)
    3. Authenticates via mobile API (Line 19)
    4. Receives JWT token (Line 20)
    5. Gets mobile-optimized interface (Line 21)
    6. Sets up biometric authentication (Line 22)
    7. Registers for push notifications (Line 23)
    """
    try:
        logger.info(f"Mobile auth setup request for username: {request.username}")
        
        # BDD Step: "I enter my credentials" (Lines 15-18)
        # Verify employee credentials against zup_agent_data
        employee_query = """
            SELECT tab_n, fio_full, status_tabel
            FROM zup_agent_data 
            WHERE login_name = $1 AND password_hash = crypt($2, password_hash)
            AND status_tabel = 'ACTIVE'
        """
        
        employee_result = await db.fetchrow(employee_query, request.username, request.password)
        
        if not employee_result:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials or inactive employee"
            )
        
        employee_tab_n = employee_result['tab_n']
        employee_name = employee_result['fio_full']
        
        # BDD Step: "Then I should authenticate via the mobile API" (Line 19)
        # BDD Step: "And receive a JWT token for session management" (Line 20)
        # Create mobile session using database function
        session_query = """
            SELECT jwt_token, refresh_token, expires_at
            FROM create_mobile_session($1, $2, $3, $4)
        """
        
        session_result = await db.fetchrow(
            session_query,
            employee_tab_n,
            request.device_id,
            request.device_type,
            request.push_token
        )
        
        if not session_result:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create mobile session"
            )
        
        # BDD Step: "And have the option to enable biometric authentication" (Line 22)
        # Update biometric settings if requested
        if request.enable_biometric and request.biometric_type:
            biometric_query = """
                UPDATE mobile_sessions 
                SET biometric_enabled = $1, biometric_type = $2
                WHERE employee_tab_n = $3 AND device_id = $4
            """
            await db.execute(
                biometric_query,
                request.enable_biometric,
                request.biometric_type,
                employee_tab_n,
                request.device_id
            )
        
        # BDD Step: "And receive a registration confirmation for push notifications" (Line 23)
        # Initialize push notification settings if not exists
        notification_settings_query = """
            INSERT INTO push_notification_settings (employee_tab_n)
            VALUES ($1)
            ON CONFLICT (employee_tab_n) DO NOTHING
        """
        await db.execute(notification_settings_query, employee_tab_n)
        
        # Check if mobile interface customization exists
        interface_query = """
            INSERT INTO interface_customization (employee_tab_n, theme_mode, interface_language)
            VALUES ($1, 'Light', 'Russian')
            ON CONFLICT (employee_tab_n) DO NOTHING
        """
        await db.execute(interface_query, employee_tab_n)
        
        # Create calendar preferences for mobile viewing
        calendar_query = """
            INSERT INTO calendar_preferences (employee_tab_n, default_view, time_format)
            VALUES ($1, 'Weekly', '24-hour')
            ON CONFLICT ON CONSTRAINT calendar_preferences_pkey DO NOTHING
        """
        await db.execute(calendar_query, employee_tab_n)
        
        # BDD Verification: All authentication setup completed
        logger.info(f"Mobile authentication successful for {employee_name} (tab_n: {employee_tab_n})")
        
        return MobileAuthResponse(
            jwt_token=session_result['jwt_token'],
            refresh_token=session_result['refresh_token'],
            expires_at=session_result['expires_at'],
            mobile_interface_enabled=True,  # BDD: "see the mobile-optimized interface"
            biometric_setup_available=bool(request.biometric_type),  # BDD: biometric auth option
            push_notifications_registered=bool(request.push_token),  # BDD: push notification confirmation
            employee_tab_n=employee_tab_n
        )
        
    except asyncpg.PostgresError as e:
        logger.error(f"Database error in mobile auth setup: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in mobile auth setup: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Authentication setup failed: {str(e)}"
        )

# Health check endpoint for mobile authentication system
@router.get("/api/v1/mobile/auth/health",
           summary="Mobile Authentication System Health Check")
async def mobile_auth_health(db: asyncpg.Connection = Depends(get_db)):
    """Check mobile authentication system status"""
    try:
        # Verify mobile_sessions table exists and is accessible
        health_query = """
            SELECT COUNT(*) as active_sessions
            FROM mobile_sessions 
            WHERE is_active = true AND expires_at > CURRENT_TIMESTAMP
        """
        result = await db.fetchrow(health_query)
        
        return {
            "status": "healthy",
            "active_mobile_sessions": result['active_sessions'],
            "timestamp": datetime.utcnow()
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Mobile auth system unhealthy: {str(e)}"
        )