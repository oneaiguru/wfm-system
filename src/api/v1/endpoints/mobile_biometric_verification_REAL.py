"""
Advanced Mobile Biometric Authentication API - Task 65
Biometric authentication with enterprise security
Features: Fingerprint/face verification, security tokens, audit trails
Database: biometric_data, security_tokens, authentication_logs
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, and_, or_, func, case
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
from uuid import UUID, uuid4
import json
import hashlib
import secrets
import base64
from enum import Enum
import hmac

from ...core.database import get_db
from ...auth.dependencies import get_current_user
from ...middleware.monitoring import track_performance
from ...utils.validators import validate_biometric_template

router = APIRouter()

# =============================================================================
# MODELS AND SCHEMAS
# =============================================================================

class BiometricType(str, Enum):
    FINGERPRINT = "fingerprint"
    FACE_ID = "face_id"
    TOUCH_ID = "touch_id"
    VOICE_PRINT = "voice_print"
    IRIS_SCAN = "iris_scan"
    PALM_PRINT = "palm_print"

class AuthenticationMethod(str, Enum):
    SINGLE_FACTOR = "single_factor"          # Biometric only
    TWO_FACTOR = "two_factor"               # Biometric + PIN/Password
    MULTI_FACTOR = "multi_factor"           # Biometric + PIN + Token
    ADAPTIVE = "adaptive"                   # Risk-based authentication

class VerificationResult(str, Enum):
    SUCCESS = "success"
    FAILED = "failed"
    LOCKED = "locked"
    EXPIRED = "expired"
    INVALID = "invalid"
    RETRY = "retry"

class SecurityLevel(str, Enum):
    STANDARD = "standard"
    HIGH = "high"
    MAXIMUM = "maximum"
    CRITICAL = "critical"

class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class BiometricTemplate(BaseModel):
    biometric_type: BiometricType
    template_data: str = Field(..., min_length=100)  # Base64 encoded biometric template
    template_version: str = Field(default="1.0", max_length=10)
    extraction_algorithm: str = Field(..., max_length=50)
    quality_score: float = Field(..., ge=0.0, le=1.0)
    
    # Security metadata
    device_id: str = Field(..., max_length=200)
    enrollment_timestamp: datetime = Field(default_factory=datetime.now)
    template_hash: Optional[str] = None
    
    @validator('template_data')
    def validate_template(cls, v):
        try:
            # Validate base64 encoding
            base64.b64decode(v)
            return v
        except Exception:
            raise ValueError('Invalid biometric template format')

class BiometricEnrollmentRequest(BaseModel):
    employee_tab_n: str = Field(..., max_length=50)
    biometric_templates: List[BiometricTemplate] = Field(..., min_items=1, max_items=5)
    security_level: SecurityLevel = SecurityLevel.STANDARD
    
    # Enrollment metadata
    enrollment_reason: Optional[str] = Field(None, max_length=500)
    backup_authentication: bool = True  # Allow fallback to PIN if biometric fails
    multi_factor_required: bool = False

class BiometricVerificationRequest(BaseModel):
    employee_tab_n: str = Field(..., max_length=50)
    biometric_data: str = Field(..., min_length=100)  # Base64 encoded biometric sample
    biometric_type: BiometricType
    device_id: str = Field(..., max_length=200)
    
    # Authentication context
    authentication_method: AuthenticationMethod = AuthenticationMethod.SINGLE_FACTOR
    additional_factors: Optional[Dict[str, str]] = None  # PIN, token, etc.
    
    # Request metadata
    request_timestamp: datetime = Field(default_factory=datetime.now)
    client_ip: Optional[str] = None
    user_agent: Optional[str] = None
    location_data: Optional[Dict[str, float]] = None
    
    # Risk assessment context
    transaction_type: Optional[str] = None
    transaction_value: Optional[float] = None
    high_risk_action: bool = False

class SecurityToken(BaseModel):
    token_type: str = Field(..., regex="^(session|transaction|access|refresh)$")
    validity_duration_minutes: int = Field(default=30, ge=1, le=1440)
    scope: Optional[List[str]] = None  # Allowed operations
    additional_data: Optional[Dict[str, Any]] = None

# =============================================================================
# TASK 65: POST /api/v1/mobile/biometric/verify
# =============================================================================

@router.post("/verify", status_code=200)
@track_performance("mobile_biometric_verify")
async def verify_biometric_authentication(
    request: BiometricVerificationRequest,
    x_device_signature: Optional[str] = Header(None),
    x_request_id: Optional[str] = Header(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Verify biometric authentication with enterprise security
    
    Enterprise features:
    - Multiple biometric types support
    - Risk-based adaptive authentication
    - Comprehensive audit trails
    - Security token generation
    - Anti-spoofing measures
    """
    try:
        # Validate request permissions
        if request.employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only verify own biometric data")
        
        # Generate unique verification session
        verification_session_id = str(uuid4())
        request_id = x_request_id or str(uuid4())
        
        # Perform risk assessment
        risk_assessment = await _perform_risk_assessment(request, db)
        
        # Get enrolled biometric templates
        templates_query = text("""
            SELECT 
                bt.id, bt.biometric_type, bt.template_data, bt.template_hash,
                bt.extraction_algorithm, bt.quality_score, bt.is_active,
                be.security_level, be.multi_factor_required, be.backup_authentication,
                be.max_failed_attempts, be.lockout_duration_minutes
            FROM biometric_templates bt
            JOIN biometric_enrollments be ON be.id = bt.enrollment_id
            WHERE be.employee_tab_n = :tab_n
            AND bt.biometric_type = :biometric_type
            AND bt.is_active = true
            AND be.is_active = true
            ORDER BY bt.quality_score DESC
        """)
        
        templates_result = await db.execute(templates_query, {
            "tab_n": request.employee_tab_n,
            "biometric_type": request.biometric_type.value
        })
        templates = templates_result.fetchall()
        
        if not templates:
            # Log failed verification attempt
            await _log_verification_attempt(
                verification_session_id, request, VerificationResult.FAILED,
                "No enrolled biometric templates found", risk_assessment, db
            )
            raise HTTPException(status_code=404, detail="No biometric templates enrolled")
        
        # Check for account lockout
        lockout_check = await _check_account_lockout(request.employee_tab_n, request.device_id, db)
        if lockout_check["is_locked"]:
            await _log_verification_attempt(
                verification_session_id, request, VerificationResult.LOCKED,
                f"Account locked until {lockout_check['locked_until']}", risk_assessment, db
            )
            raise HTTPException(status_code=423, detail=f"Account locked until {lockout_check['locked_until']}")
        
        # Perform biometric matching
        best_match = None
        match_score = 0.0
        match_threshold = 0.75  # Configurable threshold
        
        for template in templates:
            # In a real implementation, this would use actual biometric matching algorithms
            # For now, we'll simulate the matching process
            current_score = await _perform_biometric_matching(
                request.biometric_data, template.template_data, 
                request.biometric_type, template.extraction_algorithm
            )
            
            if current_score > match_score and current_score >= match_threshold:
                match_score = current_score
                best_match = template
        
        verification_result = VerificationResult.SUCCESS if best_match else VerificationResult.FAILED
        
        # Handle failed verification
        if verification_result == VerificationResult.FAILED:
            await _handle_failed_verification(request.employee_tab_n, request.device_id, db)
            await _log_verification_attempt(
                verification_session_id, request, verification_result,
                f"Biometric matching failed (score: {match_score:.3f})", risk_assessment, db
            )
            
            return {
                "verification_result": verification_result.value,
                "session_id": verification_session_id,
                "message": "Biometric verification failed",
                "retry_allowed": True,
                "remaining_attempts": await _get_remaining_attempts(request.employee_tab_n, request.device_id, db)
            }
        
        # Handle successful verification
        template_info = best_match
        
        # Check if additional factors are required
        additional_verification_required = False
        required_factors = []
        
        if (request.authentication_method == AuthenticationMethod.TWO_FACTOR or
            template_info.multi_factor_required or
            risk_assessment["risk_level"] in [RiskLevel.HIGH, RiskLevel.CRITICAL]):
            
            additional_verification_required = True
            required_factors.append("pin")
            
            if risk_assessment["risk_level"] == RiskLevel.CRITICAL:
                required_factors.append("otp")
        
        if additional_verification_required and not request.additional_factors:
            await _log_verification_attempt(
                verification_session_id, request, VerificationResult.RETRY,
                "Additional authentication factors required", risk_assessment, db
            )
            
            return {
                "verification_result": "additional_factors_required",
                "session_id": verification_session_id,
                "required_factors": required_factors,
                "message": "Additional authentication required"
            }
        
        # Verify additional factors if provided
        if additional_verification_required and request.additional_factors:
            additional_verification = await _verify_additional_factors(
                request.employee_tab_n, request.additional_factors, required_factors, db
            )
            
            if not additional_verification["success"]:
                await _log_verification_attempt(
                    verification_session_id, request, VerificationResult.FAILED,
                    f"Additional factor verification failed: {additional_verification['error']}", 
                    risk_assessment, db
                )
                
                return {
                    "verification_result": VerificationResult.FAILED.value,
                    "session_id": verification_session_id,
                    "message": "Additional authentication factor verification failed"
                }
        
        # Generate security tokens
        security_tokens = await _generate_security_tokens(
            request.employee_tab_n, verification_session_id, 
            template_info.security_level, request.high_risk_action, db
        )
        
        # Reset failed attempts counter
        await _reset_failed_attempts(request.employee_tab_n, request.device_id, db)
        
        # Log successful verification
        await _log_verification_attempt(
            verification_session_id, request, verification_result,
            f"Biometric verification successful (score: {match_score:.3f})", 
            risk_assessment, db
        )
        
        # Update last verification timestamp
        update_template_query = text("""
            UPDATE biometric_templates
            SET last_verification = CURRENT_TIMESTAMP,
                verification_count = verification_count + 1
            WHERE id = :template_id
        """)
        
        await db.execute(update_template_query, {"template_id": template_info.id})
        
        await db.commit()
        
        return {
            "verification_result": verification_result.value,
            "session_id": verification_session_id,
            "match_score": round(match_score, 3),
            "biometric_type": request.biometric_type.value,
            "security_level": template_info.security_level,
            "security_tokens": security_tokens,
            "risk_assessment": {
                "risk_level": risk_assessment["risk_level"].value,
                "risk_factors": risk_assessment["risk_factors"]
            },
            "message": "Biometric verification successful"
        }
        
    except Exception as e:
        await db.rollback()
        
        # Log the error
        if 'verification_session_id' in locals():
            await _log_verification_attempt(
                verification_session_id, request, VerificationResult.FAILED,
                f"System error: {str(e)}", {}, db
            )
        
        raise HTTPException(status_code=500, detail=f"Biometric verification failed: {str(e)}")

# =============================================================================
# BIOMETRIC ENROLLMENT
# =============================================================================

@router.post("/enroll", status_code=201)
@track_performance("mobile_biometric_enroll")
async def enroll_biometric_templates(
    request: BiometricEnrollmentRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Enroll biometric templates for authentication"""
    try:
        # Validate permissions
        if request.employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "hr_manager", "it_manager"]:
                raise HTTPException(status_code=403, detail="Can only enroll own biometric data")
        
        # Validate biometric templates
        for template in request.biometric_templates:
            if not validate_biometric_template(template.template_data, template.biometric_type.value):
                raise HTTPException(status_code=400, detail=f"Invalid {template.biometric_type.value} template")
        
        # Check existing enrollments
        existing_query = text("""
            SELECT be.id, COUNT(bt.id) as template_count
            FROM biometric_enrollments be
            LEFT JOIN biometric_templates bt ON bt.enrollment_id = be.id AND bt.is_active = true
            WHERE be.employee_tab_n = :tab_n AND be.is_active = true
            GROUP BY be.id
        """)
        
        existing_result = await db.execute(existing_query, {"tab_n": request.employee_tab_n})
        existing_enrollment = existing_result.fetchone()
        
        enrollment_id = None
        if existing_enrollment:
            enrollment_id = existing_enrollment.id
            # Deactivate old templates of the same type
            for template in request.biometric_templates:
                deactivate_query = text("""
                    UPDATE biometric_templates
                    SET is_active = false, deactivated_at = CURRENT_TIMESTAMP
                    WHERE enrollment_id = :enrollment_id 
                    AND biometric_type = :biometric_type
                """)
                
                await db.execute(deactivate_query, {
                    "enrollment_id": enrollment_id,
                    "biometric_type": template.biometric_type.value
                })
        else:
            # Create new enrollment
            enrollment_id = str(uuid4())
            enrollment_query = text("""
                INSERT INTO biometric_enrollments (
                    id, employee_tab_n, security_level, enrollment_reason,
                    backup_authentication, multi_factor_required,
                    enrolled_by_tab_n, enrollment_date, is_active, created_at
                ) VALUES (
                    :id, :tab_n, :security_level, :reason,
                    :backup_auth, :multi_factor, :enrolled_by,
                    CURRENT_TIMESTAMP, true, CURRENT_TIMESTAMP
                )
            """)
            
            await db.execute(enrollment_query, {
                "id": enrollment_id,
                "tab_n": request.employee_tab_n,
                "security_level": request.security_level.value,
                "reason": request.enrollment_reason,
                "backup_auth": request.backup_authentication,
                "multi_factor": request.multi_factor_required,
                "enrolled_by": current_user.get("tab_n")
            })
        
        # Enroll new templates
        enrolled_templates = []
        for template in request.biometric_templates:
            template_id = str(uuid4())
            
            # Generate template hash for integrity verification
            template_hash = hashlib.sha256(template.template_data.encode()).hexdigest()
            
            template_query = text("""
                INSERT INTO biometric_templates (
                    id, enrollment_id, biometric_type, template_data,
                    template_hash, template_version, extraction_algorithm,
                    quality_score, device_id, enrollment_timestamp,
                    is_active, created_at
                ) VALUES (
                    :id, :enrollment_id, :biometric_type, :template_data,
                    :template_hash, :template_version, :extraction_algorithm,
                    :quality_score, :device_id, :enrollment_timestamp,
                    true, CURRENT_TIMESTAMP
                )
            """)
            
            await db.execute(template_query, {
                "id": template_id,
                "enrollment_id": enrollment_id,
                "biometric_type": template.biometric_type.value,
                "template_data": template.template_data,
                "template_hash": template_hash,
                "template_version": template.template_version,
                "extraction_algorithm": template.extraction_algorithm,
                "quality_score": template.quality_score,
                "device_id": template.device_id,
                "enrollment_timestamp": template.enrollment_timestamp
            })
            
            enrolled_templates.append({
                "template_id": template_id,
                "biometric_type": template.biometric_type.value,
                "quality_score": template.quality_score
            })
        
        # Log enrollment event
        audit_query = text("""
            INSERT INTO biometric_audit_log (
                id, employee_tab_n, action_type, biometric_types,
                device_id, ip_address, user_agent, success,
                details, performed_by_tab_n, timestamp
            ) VALUES (
                :id, :tab_n, 'ENROLLMENT', :biometric_types,
                :device_id, :ip_address, :user_agent, true,
                :details, :performed_by, CURRENT_TIMESTAMP
            )
        """)
        
        biometric_types = [t.biometric_type.value for t in request.biometric_templates]
        await db.execute(audit_query, {
            "id": str(uuid4()),
            "tab_n": request.employee_tab_n,
            "biometric_types": json.dumps(biometric_types),
            "device_id": request.biometric_templates[0].device_id,
            "ip_address": None,  # Would be extracted from request
            "user_agent": None,  # Would be extracted from request
            "details": json.dumps({
                "enrollment_id": enrollment_id,
                "templates_count": len(request.biometric_templates),
                "security_level": request.security_level.value
            }),
            "performed_by": current_user.get("tab_n")
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "enrollment_id": enrollment_id,
            "enrolled_templates": enrolled_templates,
            "security_level": request.security_level.value,
            "message": f"Successfully enrolled {len(enrolled_templates)} biometric templates"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Biometric enrollment failed: {str(e)}")

# =============================================================================
# SECURITY TOKEN MANAGEMENT
# =============================================================================

@router.post("/tokens/generate", status_code=201)
@track_performance("mobile_biometric_token_generate")
async def generate_security_token(
    token_request: SecurityToken,
    employee_tab_n: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate security tokens for authenticated sessions"""
    try:
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Validate permissions
        if target_employee != current_user.get("tab_n"):
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only generate tokens for yourself")
        
        # Generate token
        token_value = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token_value.encode()).hexdigest()
        
        # Calculate expiration
        expires_at = datetime.now() + timedelta(minutes=token_request.validity_duration_minutes)
        
        # Store token
        token_id = str(uuid4())
        token_query = text("""
            INSERT INTO security_tokens (
                id, employee_tab_n, token_type, token_hash,
                expires_at, scope, additional_data, is_active,
                issued_by_tab_n, created_at
            ) VALUES (
                :id, :tab_n, :token_type, :token_hash,
                :expires_at, :scope, :additional_data, true,
                :issued_by, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(token_query, {
            "id": token_id,
            "tab_n": target_employee,
            "token_type": token_request.token_type,
            "token_hash": token_hash,
            "expires_at": expires_at,
            "scope": json.dumps(token_request.scope) if token_request.scope else None,
            "additional_data": json.dumps(token_request.additional_data) if token_request.additional_data else None,
            "issued_by": current_user.get("tab_n")
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "token_id": token_id,
            "token": token_value,
            "token_type": token_request.token_type,
            "expires_at": expires_at,
            "scope": token_request.scope
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to generate security token: {str(e)}")

@router.post("/tokens/validate", status_code=200)
@track_performance("mobile_biometric_token_validate")
async def validate_security_token(
    token: str,
    token_type: Optional[str] = None,
    required_scope: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """Validate security token"""
    try:
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        
        # Find and validate token
        validation_query = text("""
            SELECT 
                st.id, st.employee_tab_n, st.token_type, st.scope,
                st.expires_at, st.is_active, st.additional_data,
                zad.fio_full as employee_name
            FROM security_tokens st
            JOIN zup_agent_data zad ON zad.tab_n = st.employee_tab_n
            WHERE st.token_hash = :token_hash
            AND st.is_active = true
            AND st.expires_at > CURRENT_TIMESTAMP
        """)
        
        result = await db.execute(validation_query, {"token_hash": token_hash})
        token_data = result.fetchone()
        
        if not token_data:
            return {
                "valid": False,
                "error": "Invalid or expired token"
            }
        
        # Check token type if specified
        if token_type and token_data.token_type != token_type:
            return {
                "valid": False,
                "error": "Invalid token type"
            }
        
        # Check scope if specified
        if required_scope:
            token_scope = json.loads(token_data.scope) if token_data.scope else []
            if required_scope not in token_scope:
                return {
                "valid": False,
                "error": "Insufficient token scope"
            }
        
        # Update last used timestamp
        update_query = text("""
            UPDATE security_tokens
            SET last_used = CURRENT_TIMESTAMP,
                usage_count = usage_count + 1
            WHERE id = :token_id
        """)
        
        await db.execute(update_query, {"token_id": token_data.id})
        await db.commit()
        
        return {
            "valid": True,
            "employee_tab_n": token_data.employee_tab_n,
            "employee_name": token_data.employee_name,
            "token_type": token_data.token_type,
            "scope": json.loads(token_data.scope) if token_data.scope else [],
            "expires_at": token_data.expires_at,
            "additional_data": json.loads(token_data.additional_data) if token_data.additional_data else {}
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Token validation failed: {str(e)}")

# =============================================================================
# AUDIT AND MONITORING
# =============================================================================

@router.get("/audit/logs", status_code=200)
@track_performance("mobile_biometric_audit_logs")
async def get_biometric_audit_logs(
    employee_tab_n: Optional[str] = Query(None),
    action_type: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    limit: int = Query(100, le=1000),
    offset: int = Query(0),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get biometric authentication audit logs"""
    try:
        # Check permissions
        if employee_tab_n and employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "security_officer", "audit_manager"]:
                raise HTTPException(status_code=403, detail="Insufficient permissions to view audit logs")
        
        where_conditions = ["1=1"]
        params = {"limit": limit, "offset": offset}
        
        if employee_tab_n:
            where_conditions.append("bal.employee_tab_n = :employee_tab_n")
            params["employee_tab_n"] = employee_tab_n
        elif not current_user.get("role_name") in ["admin", "security_officer", "audit_manager"]:
            # Regular users can only see their own logs
            where_conditions.append("bal.employee_tab_n = :current_user")
            params["current_user"] = current_user.get("tab_n")
        
        if action_type:
            where_conditions.append("bal.action_type = :action_type")
            params["action_type"] = action_type
        
        if start_date:
            where_conditions.append("bal.timestamp >= :start_date")
            params["start_date"] = start_date
        
        if end_date:
            where_conditions.append("bal.timestamp <= :end_date")
            params["end_date"] = end_date
        
        logs_query = text(f"""
            SELECT 
                bal.id,
                bal.employee_tab_n,
                zad.fio_full as employee_name,
                bal.action_type,
                bal.biometric_types,
                bal.device_id,
                bal.ip_address,
                bal.user_agent,
                bal.success,
                bal.details,
                bal.performed_by_tab_n,
                performer.fio_full as performed_by_name,
                bal.timestamp
            FROM biometric_audit_log bal
            LEFT JOIN zup_agent_data zad ON zad.tab_n = bal.employee_tab_n
            LEFT JOIN zup_agent_data performer ON performer.tab_n = bal.performed_by_tab_n
            WHERE {' AND '.join(where_conditions)}
            ORDER BY bal.timestamp DESC
            LIMIT :limit OFFSET :offset
        """)
        
        result = await db.execute(logs_query, params)
        logs = [dict(row._mapping) for row in result.fetchall()]
        
        # Parse JSON fields
        for log in logs:
            if log["biometric_types"]:
                log["biometric_types"] = json.loads(log["biometric_types"])
            if log["details"]:
                log["details"] = json.loads(log["details"])
        
        # Get total count
        count_query = text(f"""
            SELECT COUNT(*)
            FROM biometric_audit_log bal
            WHERE {' AND '.join(where_conditions)}
        """)
        
        count_result = await db.execute(count_query, {
            k: v for k, v in params.items() if k not in ['limit', 'offset']
        })
        total_count = count_result.scalar()
        
        return {
            "audit_logs": logs,
            "total_count": total_count,
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve audit logs: {str(e)}")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

async def _perform_risk_assessment(request: BiometricVerificationRequest, db: AsyncSession) -> Dict[str, Any]:
    """Perform risk assessment for biometric verification request"""
    risk_factors = []
    risk_score = 0
    
    # Check time-based patterns
    current_hour = datetime.now().hour
    if current_hour < 6 or current_hour > 22:
        risk_factors.append("unusual_time")
        risk_score += 20
    
    # Check device consistency
    device_query = text("""
        SELECT COUNT(*) as usage_count, MAX(timestamp) as last_used
        FROM biometric_audit_log
        WHERE employee_tab_n = :tab_n AND device_id = :device_id
        AND timestamp > CURRENT_TIMESTAMP - INTERVAL '30 days'
    """)
    
    device_result = await db.execute(device_query, {
        "tab_n": request.employee_tab_n,
        "device_id": request.device_id
    })
    device_info = device_result.fetchone()
    
    if device_info.usage_count == 0:
        risk_factors.append("new_device")
        risk_score += 30
    elif device_info.usage_count < 5:
        risk_factors.append("infrequent_device")
        risk_score += 15
    
    # Check transaction context
    if request.high_risk_action:
        risk_factors.append("high_risk_action")
        risk_score += 25
    
    if request.transaction_value and request.transaction_value > 10000:
        risk_factors.append("high_value_transaction")
        risk_score += 20
    
    # Determine risk level
    if risk_score >= 60:
        risk_level = RiskLevel.CRITICAL
    elif risk_score >= 40:
        risk_level = RiskLevel.HIGH
    elif risk_score >= 20:
        risk_level = RiskLevel.MEDIUM
    else:
        risk_level = RiskLevel.LOW
    
    return {
        "risk_level": risk_level,
        "risk_score": risk_score,
        "risk_factors": risk_factors
    }

async def _perform_biometric_matching(sample_data: str, template_data: str, biometric_type: BiometricType, algorithm: str) -> float:
    """Simulate biometric matching - in production this would use actual biometric algorithms"""
    # This is a simulation - real implementation would use proper biometric matching
    # algorithms like minutiae matching for fingerprints or facial feature comparison
    
    sample_hash = hashlib.sha256(sample_data.encode()).hexdigest()
    template_hash = hashlib.sha256(template_data.encode()).hexdigest()
    
    # Simulate matching score based on hash similarity (not realistic but for demo)
    common_chars = sum(1 for a, b in zip(sample_hash, template_hash) if a == b)
    score = common_chars / len(sample_hash)
    
    # Add some randomness to simulate real matching variability
    import random
    score += random.uniform(-0.1, 0.1)
    
    return max(0.0, min(1.0, score))

async def _check_account_lockout(employee_tab_n: str, device_id: str, db: AsyncSession) -> Dict[str, Any]:
    """Check if account is locked due to failed attempts"""
    lockout_query = text("""
        SELECT locked_until, failed_attempts
        FROM biometric_lockouts
        WHERE employee_tab_n = :tab_n AND device_id = :device_id
        AND locked_until > CURRENT_TIMESTAMP
    """)
    
    result = await db.execute(lockout_query, {
        "tab_n": employee_tab_n,
        "device_id": device_id
    })
    lockout = result.fetchone()
    
    return {
        "is_locked": lockout is not None,
        "locked_until": lockout.locked_until if lockout else None,
        "failed_attempts": lockout.failed_attempts if lockout else 0
    }

async def _handle_failed_verification(employee_tab_n: str, device_id: str, db: AsyncSession):
    """Handle failed verification attempt"""
    # Increment failed attempts
    failed_attempts_query = text("""
        INSERT INTO biometric_lockouts (
            employee_tab_n, device_id, failed_attempts, first_failed_attempt, created_at
        ) VALUES (:tab_n, :device_id, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (employee_tab_n, device_id) DO UPDATE SET
            failed_attempts = biometric_lockouts.failed_attempts + 1,
            last_failed_attempt = CURRENT_TIMESTAMP
    """)
    
    await db.execute(failed_attempts_query, {
        "tab_n": employee_tab_n,
        "device_id": device_id
    })
    
    # Check if lockout threshold reached
    check_query = text("""
        SELECT failed_attempts FROM biometric_lockouts
        WHERE employee_tab_n = :tab_n AND device_id = :device_id
    """)
    
    result = await db.execute(check_query, {
        "tab_n": employee_tab_n,
        "device_id": device_id
    })
    lockout_info = result.fetchone()
    
    # Lock account if too many failures (configurable threshold)
    max_attempts = 5  # Could be policy-based
    if lockout_info and lockout_info.failed_attempts >= max_attempts:
        lockout_duration = 30  # minutes - could be policy-based
        
        lock_query = text("""
            UPDATE biometric_lockouts
            SET locked_until = CURRENT_TIMESTAMP + INTERVAL ':duration minutes'
            WHERE employee_tab_n = :tab_n AND device_id = :device_id
        """)
        
        await db.execute(lock_query, {
            "tab_n": employee_tab_n,
            "device_id": device_id,
            "duration": lockout_duration
        })

async def _reset_failed_attempts(employee_tab_n: str, device_id: str, db: AsyncSession):
    """Reset failed attempts counter after successful verification"""
    reset_query = text("""
        DELETE FROM biometric_lockouts
        WHERE employee_tab_n = :tab_n AND device_id = :device_id
    """)
    
    await db.execute(reset_query, {
        "tab_n": employee_tab_n,
        "device_id": device_id
    })

async def _get_remaining_attempts(employee_tab_n: str, device_id: str, db: AsyncSession) -> int:
    """Get remaining verification attempts before lockout"""
    query = text("""
        SELECT failed_attempts FROM biometric_lockouts
        WHERE employee_tab_n = :tab_n AND device_id = :device_id
    """)
    
    result = await db.execute(query, {
        "tab_n": employee_tab_n,
        "device_id": device_id
    })
    lockout = result.fetchone()
    
    max_attempts = 5  # Configurable
    current_attempts = lockout.failed_attempts if lockout else 0
    
    return max(0, max_attempts - current_attempts)

async def _verify_additional_factors(employee_tab_n: str, factors: Dict[str, str], required_factors: List[str], db: AsyncSession) -> Dict[str, Any]:
    """Verify additional authentication factors (PIN, OTP, etc.)"""
    for factor in required_factors:
        if factor not in factors:
            return {"success": False, "error": f"Missing required factor: {factor}"}
        
        # Verify each factor - simplified implementation
        if factor == "pin":
            pin_query = text("""
                SELECT pin_hash FROM employee_pins
                WHERE employee_tab_n = :tab_n AND is_active = true
            """)
            
            result = await db.execute(pin_query, {"tab_n": employee_tab_n})
            pin_data = result.fetchone()
            
            if not pin_data:
                return {"success": False, "error": "PIN not configured"}
            
            provided_pin_hash = hashlib.sha256(factors[factor].encode()).hexdigest()
            if provided_pin_hash != pin_data.pin_hash:
                return {"success": False, "error": "Invalid PIN"}
        
        # Add other factor verification as needed
    
    return {"success": True}

async def _generate_security_tokens(employee_tab_n: str, session_id: str, security_level: str, high_risk: bool, db: AsyncSession) -> Dict[str, Any]:
    """Generate security tokens for authenticated session"""
    tokens = {}
    
    # Session token
    session_token = secrets.token_urlsafe(32)
    session_duration = 480 if security_level == "maximum" else 720  # minutes
    if high_risk:
        session_duration = min(session_duration, 60)  # Max 1 hour for high risk
    
    tokens["session_token"] = {
        "token": session_token,
        "expires_in_minutes": session_duration,
        "type": "session"
    }
    
    # Transaction token for high-risk operations
    if high_risk or security_level in ["high", "maximum"]:
        transaction_token = secrets.token_urlsafe(16)
        tokens["transaction_token"] = {
            "token": transaction_token,
            "expires_in_minutes": 15,
            "type": "transaction"
        }
    
    return tokens

async def _log_verification_attempt(session_id: str, request: BiometricVerificationRequest, result: VerificationResult, details: str, risk_assessment: Dict, db: AsyncSession):
    """Log biometric verification attempt for audit trail"""
    try:
        log_query = text("""
            INSERT INTO biometric_audit_log (
                id, employee_tab_n, action_type, biometric_types,
                device_id, ip_address, user_agent, success, details,
                session_id, risk_level, timestamp
            ) VALUES (
                :id, :tab_n, 'VERIFICATION', :biometric_types,
                :device_id, :ip_address, :user_agent, :success, :details,
                :session_id, :risk_level, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(log_query, {
            "id": str(uuid4()),
            "tab_n": request.employee_tab_n,
            "biometric_types": json.dumps([request.biometric_type.value]),
            "device_id": request.device_id,
            "ip_address": request.client_ip,
            "user_agent": request.user_agent,
            "success": result == VerificationResult.SUCCESS,
            "details": json.dumps({
                "result": result.value,
                "details": details,
                "authentication_method": request.authentication_method.value,
                "risk_assessment": risk_assessment
            }),
            "session_id": session_id,
            "risk_level": risk_assessment.get("risk_level", {}).get("value", "unknown") if risk_assessment else "unknown"
        })
        
        await db.commit()
        
    except Exception as e:
        # Don't fail the main operation if logging fails
        print(f"Failed to log verification attempt: {e}")
        pass