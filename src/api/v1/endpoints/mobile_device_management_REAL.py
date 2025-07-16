"""
Advanced Mobile Device Management API - Task 64
Enterprise device management with security policies
Features: Device registration, policy enforcement, remote wipe, compliance
Database: registered_devices, device_policies, security_settings
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, and_, or_, func, case
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
from uuid import UUID, uuid4
import json
import hashlib
import secrets
from enum import Enum

from ...core.database import get_db
from ...auth.dependencies import get_current_user
from ...middleware.monitoring import track_performance
from ...utils.validators import validate_device_info

router = APIRouter()

# =============================================================================
# MODELS AND SCHEMAS
# =============================================================================

class DeviceStatus(str, Enum):
    PENDING_APPROVAL = "pending_approval"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    BLOCKED = "blocked"
    RETIRED = "retired"
    LOST_STOLEN = "lost_stolen"

class DeviceType(str, Enum):
    IPHONE = "iPhone"
    ANDROID = "Android"
    TABLET = "Tablet"
    DESKTOP = "Desktop"
    WEB_BROWSER = "Web Browser"

class PolicyStatus(str, Enum):
    COMPLIANT = "compliant"
    NON_COMPLIANT = "non_compliant"
    PENDING_CHECK = "pending_check"
    UNKNOWN = "unknown"

class SecurityLevel(str, Enum):
    BASIC = "basic"
    STANDARD = "standard"
    HIGH = "high"
    MAXIMUM = "maximum"

class ComplianceAction(str, Enum):
    WARN = "warn"
    RESTRICT = "restrict"
    BLOCK = "block"
    WIPE = "wipe"

class DeviceInfo(BaseModel):
    device_name: str = Field(..., max_length=100)
    device_type: DeviceType
    os_version: str = Field(..., max_length=50)
    app_version: str = Field(..., max_length=20)
    hardware_model: str = Field(..., max_length=100)
    unique_identifier: str = Field(..., max_length=200)  # IMEI, Serial, etc.
    
    # Security features
    passcode_enabled: bool = False
    biometric_enabled: bool = False
    encryption_enabled: bool = False
    vpn_enabled: bool = False
    
    # Device capabilities
    gps_enabled: bool = True
    camera_enabled: bool = True
    microphone_enabled: bool = True
    network_type: str = Field(default="WiFi+Cellular", max_length=20)
    
    # Additional metadata
    manufacturer: str = Field(..., max_length=50)
    carrier: Optional[str] = Field(None, max_length=50)
    phone_number: Optional[str] = Field(None, max_length=20)

class DeviceRegistrationRequest(BaseModel):
    employee_tab_n: str = Field(..., max_length=50)
    device_info: DeviceInfo
    registration_reason: Optional[str] = Field(None, max_length=500)
    emergency_contact: Optional[str] = Field(None, max_length=100)
    
    # Self-registration vs admin registration
    self_registration: bool = True
    manager_approval_required: bool = True

class SecurityPolicy(BaseModel):
    policy_name: str = Field(..., max_length=100)
    security_level: SecurityLevel
    description: Optional[str] = Field(None, max_length=500)
    
    # Password requirements
    require_passcode: bool = True
    min_passcode_length: int = Field(default=6, ge=4, le=20)
    require_alphanumeric: bool = False
    passcode_expiry_days: Optional[int] = Field(None, ge=1, le=365)
    
    # Biometric requirements
    allow_biometric: bool = True
    require_biometric: bool = False
    
    # Device security
    require_encryption: bool = True
    allow_jailbreak_root: bool = False
    require_remote_wipe: bool = True
    max_failed_attempts: int = Field(default=5, ge=1, le=20)
    
    # Application restrictions
    allowed_apps: Optional[List[str]] = None
    blocked_apps: Optional[List[str]] = None
    allow_personal_apps: bool = True
    
    # Network and data
    require_vpn: bool = False
    allow_personal_hotspot: bool = True
    data_usage_limit_mb: Optional[int] = None
    
    # Compliance checking
    compliance_check_interval_hours: int = Field(default=24, ge=1, le=168)
    auto_remediation: bool = True
    non_compliance_action: ComplianceAction = ComplianceAction.WARN
    
    # Location and tracking
    location_tracking_required: bool = False
    geofencing_enabled: bool = False
    
    # Audit and monitoring
    audit_app_usage: bool = True
    audit_location: bool = False
    audit_communication: bool = False

class RemoteAction(BaseModel):
    device_id: str
    action_type: str = Field(..., regex="^(lock|unlock|wipe|locate|alarm|restrict)$")
    reason: str = Field(..., max_length=500)
    emergency_action: bool = False
    scheduled_execution: Optional[datetime] = None
    
    # Action-specific parameters
    wipe_external_storage: bool = True
    lock_message: Optional[str] = Field(None, max_length=200)
    alarm_duration_seconds: Optional[int] = Field(None, ge=30, le=300)

# =============================================================================
# TASK 64: GET /api/v1/mobile/devices/management
# =============================================================================

@router.get("/management", status_code=200)
@track_performance("mobile_device_management_list")
async def get_device_management_overview(
    employee_tab_n: Optional[str] = Query(None),
    device_status: Optional[DeviceStatus] = Query(None),
    policy_compliance: Optional[PolicyStatus] = Query(None),
    include_policies: bool = Query(True),
    include_compliance: bool = Query(True),
    limit: int = Query(100, le=500),
    offset: int = Query(0),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get enterprise device management overview with security policies
    
    Enterprise features:
    - Device registration and approval workflow
    - Security policy enforcement
    - Compliance monitoring and reporting
    - Remote device management capabilities
    """
    try:
        # Check permissions
        if employee_tab_n and employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
                raise HTTPException(status_code=403, detail="Insufficient permissions to view device data")
        
        # Build query conditions
        where_conditions = ["1=1"]
        params = {"limit": limit, "offset": offset}
        
        if employee_tab_n:
            where_conditions.append("rd.employee_tab_n = :employee_tab_n")
            params["employee_tab_n"] = employee_tab_n
        else:
            # If no specific employee, check if user can see all devices
            if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
                where_conditions.append("rd.employee_tab_n = :current_user_tab_n")
                params["current_user_tab_n"] = current_user.get("tab_n")
        
        if device_status:
            where_conditions.append("rd.status = :device_status")
            params["device_status"] = device_status.value
        
        if policy_compliance:
            where_conditions.append("rd.policy_compliance_status = :compliance_status")
            params["compliance_status"] = policy_compliance.value
        
        # Main devices query
        devices_query = text(f"""
            SELECT 
                rd.id as device_id,
                rd.employee_tab_n,
                zad.fio_full as employee_name,
                rd.device_name,
                rd.device_type,
                rd.os_version,
                rd.app_version,
                rd.hardware_model,
                rd.manufacturer,
                rd.unique_identifier,
                rd.status,
                rd.policy_compliance_status,
                rd.last_compliance_check,
                rd.last_seen,
                rd.registration_date,
                rd.approved_date,
                rd.approved_by_tab_n,
                
                -- Security features
                rd.passcode_enabled,
                rd.biometric_enabled,
                rd.encryption_enabled,
                rd.vpn_enabled,
                rd.jailbroken_rooted,
                
                -- Policy information
                sp.policy_name,
                sp.security_level,
                sp.require_passcode,
                sp.require_encryption,
                sp.allow_jailbreak_root,
                
                -- Compliance details
                CASE 
                    WHEN rd.policy_compliance_status = 'compliant' THEN 'Compliant'
                    WHEN rd.policy_compliance_status = 'non_compliant' THEN 'Non-Compliant'
                    ELSE 'Unknown'
                END as compliance_display,
                
                -- Risk assessment
                CASE 
                    WHEN rd.jailbroken_rooted = true THEN 'HIGH'
                    WHEN rd.policy_compliance_status = 'non_compliant' THEN 'MEDIUM'
                    WHEN rd.last_compliance_check < CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 'MEDIUM'
                    ELSE 'LOW'
                END as risk_level
                
            FROM registered_devices rd
            LEFT JOIN zup_agent_data zad ON zad.tab_n = rd.employee_tab_n
            LEFT JOIN security_policies sp ON sp.id = rd.assigned_policy_id
            WHERE {' AND '.join(where_conditions)}
            ORDER BY rd.last_seen DESC, rd.registration_date DESC
            LIMIT :limit OFFSET :offset
        """)
        
        devices_result = await db.execute(devices_query, params)
        devices = [dict(row._mapping) for row in devices_result.fetchall()]
        
        # Get compliance violations if requested
        if include_compliance and devices:
            device_ids = [d["device_id"] for d in devices]
            violations_query = text("""
                SELECT 
                    cv.device_id,
                    cv.violation_type,
                    cv.violation_description,
                    cv.detected_at,
                    cv.resolved_at,
                    cv.severity
                FROM compliance_violations cv
                WHERE cv.device_id = ANY(:device_ids)
                AND cv.resolved_at IS NULL
                ORDER BY cv.severity DESC, cv.detected_at DESC
            """)
            
            violations_result = await db.execute(violations_query, {"device_ids": device_ids})
            violations = violations_result.fetchall()
            
            # Group violations by device
            violations_by_device = {}
            for violation in violations:
                device_id = violation.device_id
                if device_id not in violations_by_device:
                    violations_by_device[device_id] = []
                violations_by_device[device_id].append(dict(violation._mapping))
            
            # Add violations to device data
            for device in devices:
                device["compliance_violations"] = violations_by_device.get(device["device_id"], [])
        
        # Get security policies if requested
        policies = []
        if include_policies:
            policies_query = text("""
                SELECT 
                    id, policy_name, security_level, description,
                    require_passcode, min_passcode_length, require_biometric,
                    require_encryption, allow_jailbreak_root, require_remote_wipe,
                    compliance_check_interval_hours, non_compliance_action,
                    is_active, created_at
                FROM security_policies
                WHERE is_active = true
                ORDER BY security_level DESC, policy_name
            """)
            
            policies_result = await db.execute(policies_query)
            policies = [dict(row._mapping) for row in policies_result.fetchall()]
        
        # Get summary statistics
        stats_query = text(f"""
            SELECT 
                COUNT(*) as total_devices,
                COUNT(CASE WHEN status = 'active' THEN 1 END) as active_devices,
                COUNT(CASE WHEN status = 'suspended' THEN 1 END) as suspended_devices,
                COUNT(CASE WHEN status = 'blocked' THEN 1 END) as blocked_devices,
                COUNT(CASE WHEN policy_compliance_status = 'compliant' THEN 1 END) as compliant_devices,
                COUNT(CASE WHEN policy_compliance_status = 'non_compliant' THEN 1 END) as non_compliant_devices,
                COUNT(CASE WHEN jailbroken_rooted = true THEN 1 END) as jailbroken_devices,
                COUNT(CASE WHEN last_seen < CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 1 END) as inactive_devices
            FROM registered_devices rd
            WHERE {' AND '.join([c for c in where_conditions if 'LIMIT' not in c and 'OFFSET' not in c])}
        """)
        
        stats_result = await db.execute(stats_query, {k: v for k, v in params.items() if k not in ['limit', 'offset']})
        stats = dict(stats_result.fetchone()._mapping)
        
        return {
            "devices": devices,
            "security_policies": policies if include_policies else [],
            "device_statistics": stats,
            "total_count": len(devices),
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get device management data: {str(e)}")

# =============================================================================
# DEVICE REGISTRATION
# =============================================================================

@router.post("/register", status_code=201)
@track_performance("mobile_device_register")
async def register_device(
    request: DeviceRegistrationRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Register a new mobile device for enterprise management"""
    try:
        # Validate user can register device for this employee
        if request.employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "it_manager"]:
                raise HTTPException(status_code=403, detail="Can only register devices for yourself")
        
        # Validate device info
        if not validate_device_info(request.device_info.dict()):
            raise HTTPException(status_code=400, detail="Invalid device information")
        
        # Check if device already registered
        existing_query = text("""
            SELECT id FROM registered_devices
            WHERE unique_identifier = :unique_id
            OR (employee_tab_n = :tab_n AND device_name = :device_name)
        """)
        
        existing_result = await db.execute(existing_query, {
            "unique_id": request.device_info.unique_identifier,
            "tab_n": request.employee_tab_n,
            "device_name": request.device_info.device_name
        })
        
        if existing_result.fetchone():
            raise HTTPException(status_code=409, detail="Device already registered")
        
        # Get default security policy for device type
        policy_query = text("""
            SELECT id FROM security_policies
            WHERE device_types @> :device_type
            AND is_default = true
            AND is_active = true
            LIMIT 1
        """)
        
        policy_result = await db.execute(policy_query, {
            "device_type": json.dumps([request.device_info.device_type.value])
        })
        policy = policy_result.fetchone()
        default_policy_id = policy.id if policy else None
        
        # Determine approval status
        status = DeviceStatus.PENDING_APPROVAL
        if not request.manager_approval_required or current_user.get("role_name") in ["admin", "it_manager"]:
            status = DeviceStatus.ACTIVE
        
        # Register device
        device_id = str(uuid4())
        registration_query = text("""
            INSERT INTO registered_devices (
                id, employee_tab_n, device_name, device_type,
                os_version, app_version, hardware_model, manufacturer,
                unique_identifier, carrier, phone_number,
                passcode_enabled, biometric_enabled, encryption_enabled,
                vpn_enabled, gps_enabled, camera_enabled, microphone_enabled,
                network_type, registration_reason, emergency_contact,
                status, assigned_policy_id, registered_by_tab_n,
                registration_date, self_registered, created_at
            ) VALUES (
                :id, :tab_n, :device_name, :device_type,
                :os_version, :app_version, :hardware_model, :manufacturer,
                :unique_id, :carrier, :phone_number,
                :passcode_enabled, :biometric_enabled, :encryption_enabled,
                :vpn_enabled, :gps_enabled, :camera_enabled, :microphone_enabled,
                :network_type, :registration_reason, :emergency_contact,
                :status, :policy_id, :registered_by,
                CURRENT_TIMESTAMP, :self_registered, CURRENT_TIMESTAMP
            )
        """)
        
        device_info = request.device_info
        await db.execute(registration_query, {
            "id": device_id,
            "tab_n": request.employee_tab_n,
            "device_name": device_info.device_name,
            "device_type": device_info.device_type.value,
            "os_version": device_info.os_version,
            "app_version": device_info.app_version,
            "hardware_model": device_info.hardware_model,
            "manufacturer": device_info.manufacturer,
            "unique_id": device_info.unique_identifier,
            "carrier": device_info.carrier,
            "phone_number": device_info.phone_number,
            "passcode_enabled": device_info.passcode_enabled,
            "biometric_enabled": device_info.biometric_enabled,
            "encryption_enabled": device_info.encryption_enabled,
            "vpn_enabled": device_info.vpn_enabled,
            "gps_enabled": device_info.gps_enabled,
            "camera_enabled": device_info.camera_enabled,
            "microphone_enabled": device_info.microphone_enabled,
            "network_type": device_info.network_type,
            "registration_reason": request.registration_reason,
            "emergency_contact": request.emergency_contact,
            "status": status.value,
            "policy_id": default_policy_id,
            "registered_by": current_user.get("tab_n"),
            "self_registered": request.self_registration
        })
        
        # Create device access token
        access_token = secrets.token_urlsafe(32)
        token_query = text("""
            INSERT INTO device_access_tokens (
                device_id, access_token, token_hash,
                expires_at, created_at
            ) VALUES (
                :device_id, :token, :token_hash,
                CURRENT_TIMESTAMP + INTERVAL '90 days', CURRENT_TIMESTAMP
            )
        """)
        
        token_hash = hashlib.sha256(access_token.encode()).hexdigest()
        await db.execute(token_query, {
            "device_id": device_id,
            "token": access_token,
            "token_hash": token_hash
        })
        
        # Create approval workflow if needed
        if status == DeviceStatus.PENDING_APPROVAL:
            approval_query = text("""
                INSERT INTO device_approval_requests (
                    id, device_id, employee_tab_n, requested_by_tab_n,
                    manager_tab_n, status, created_at
                ) VALUES (
                    :id, :device_id, :employee_tab_n, :requested_by,
                    (SELECT manager_tab_n FROM zup_agent_data WHERE tab_n = :employee_tab_n),
                    'PENDING', CURRENT_TIMESTAMP
                )
            """)
            
            await db.execute(approval_query, {
                "id": str(uuid4()),
                "device_id": device_id,
                "employee_tab_n": request.employee_tab_n,
                "requested_by": current_user.get("tab_n")
            })
        
        await db.commit()
        
        return {
            "status": "success",
            "device_id": device_id,
            "access_token": access_token if status == DeviceStatus.ACTIVE else None,
            "registration_status": status.value,
            "message": "Device registered successfully" if status == DeviceStatus.ACTIVE else "Device registered, pending approval"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to register device: {str(e)}")

# =============================================================================
# SECURITY POLICY MANAGEMENT
# =============================================================================

@router.post("/policies", status_code=201)
@track_performance("mobile_device_policy_create")
async def create_security_policy(
    policy: SecurityPolicy,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new security policy for device management"""
    try:
        # Check permissions
        if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
            raise HTTPException(status_code=403, detail="Insufficient permissions to create security policies")
        
        policy_id = str(uuid4())
        
        policy_query = text("""
            INSERT INTO security_policies (
                id, policy_name, security_level, description,
                require_passcode, min_passcode_length, require_alphanumeric,
                passcode_expiry_days, allow_biometric, require_biometric,
                require_encryption, allow_jailbreak_root, require_remote_wipe,
                max_failed_attempts, allowed_apps, blocked_apps, allow_personal_apps,
                require_vpn, allow_personal_hotspot, data_usage_limit_mb,
                compliance_check_interval_hours, auto_remediation, non_compliance_action,
                location_tracking_required, geofencing_enabled,
                audit_app_usage, audit_location, audit_communication,
                created_by_tab_n, is_active, created_at
            ) VALUES (
                :id, :name, :security_level, :description,
                :require_passcode, :min_passcode_length, :require_alphanumeric,
                :passcode_expiry_days, :allow_biometric, :require_biometric,
                :require_encryption, :allow_jailbreak_root, :require_remote_wipe,
                :max_failed_attempts, :allowed_apps, :blocked_apps, :allow_personal_apps,
                :require_vpn, :allow_personal_hotspot, :data_usage_limit_mb,
                :compliance_check_interval_hours, :auto_remediation, :non_compliance_action,
                :location_tracking_required, :geofencing_enabled,
                :audit_app_usage, :audit_location, :audit_communication,
                :created_by, true, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(policy_query, {
            "id": policy_id,
            "name": policy.policy_name,
            "security_level": policy.security_level.value,
            "description": policy.description,
            "require_passcode": policy.require_passcode,
            "min_passcode_length": policy.min_passcode_length,
            "require_alphanumeric": policy.require_alphanumeric,
            "passcode_expiry_days": policy.passcode_expiry_days,
            "allow_biometric": policy.allow_biometric,
            "require_biometric": policy.require_biometric,
            "require_encryption": policy.require_encryption,
            "allow_jailbreak_root": policy.allow_jailbreak_root,
            "require_remote_wipe": policy.require_remote_wipe,
            "max_failed_attempts": policy.max_failed_attempts,
            "allowed_apps": json.dumps(policy.allowed_apps) if policy.allowed_apps else None,
            "blocked_apps": json.dumps(policy.blocked_apps) if policy.blocked_apps else None,
            "allow_personal_apps": policy.allow_personal_apps,
            "require_vpn": policy.require_vpn,
            "allow_personal_hotspot": policy.allow_personal_hotspot,
            "data_usage_limit_mb": policy.data_usage_limit_mb,
            "compliance_check_interval_hours": policy.compliance_check_interval_hours,
            "auto_remediation": policy.auto_remediation,
            "non_compliance_action": policy.non_compliance_action.value,
            "location_tracking_required": policy.location_tracking_required,
            "geofencing_enabled": policy.geofencing_enabled,
            "audit_app_usage": policy.audit_app_usage,
            "audit_location": policy.audit_location,
            "audit_communication": policy.audit_communication,
            "created_by": current_user.get("tab_n")
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "policy_id": policy_id,
            "message": "Security policy created successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create security policy: {str(e)}")

@router.put("/policies/{policy_id}/assign", status_code=200)
@track_performance("mobile_device_policy_assign")
async def assign_policy_to_devices(
    policy_id: str = Path(...),
    device_ids: List[str] = [],
    employee_tab_ns: List[str] = [],
    department_codes: List[str] = [],
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Assign security policy to devices, employees, or departments"""
    try:
        # Check permissions
        if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
            raise HTTPException(status_code=403, detail="Insufficient permissions to assign policies")
        
        # Verify policy exists
        policy_check_query = text("SELECT id FROM security_policies WHERE id = :policy_id AND is_active = true")
        policy_result = await db.execute(policy_check_query, {"policy_id": policy_id})
        if not policy_result.fetchone():
            raise HTTPException(status_code=404, detail="Security policy not found")
        
        updated_devices = 0
        
        # Assign to specific devices
        if device_ids:
            device_update_query = text("""
                UPDATE registered_devices
                SET assigned_policy_id = :policy_id,
                    policy_updated_at = CURRENT_TIMESTAMP,
                    policy_updated_by_tab_n = :updated_by
                WHERE id = ANY(:device_ids)
            """)
            
            result = await db.execute(device_update_query, {
                "policy_id": policy_id,
                "updated_by": current_user.get("tab_n"),
                "device_ids": device_ids
            })
            updated_devices += result.rowcount
        
        # Assign to employees (all their devices)
        if employee_tab_ns:
            employee_update_query = text("""
                UPDATE registered_devices
                SET assigned_policy_id = :policy_id,
                    policy_updated_at = CURRENT_TIMESTAMP,
                    policy_updated_by_tab_n = :updated_by
                WHERE employee_tab_n = ANY(:employee_tab_ns)
            """)
            
            result = await db.execute(employee_update_query, {
                "policy_id": policy_id,
                "updated_by": current_user.get("tab_n"),
                "employee_tab_ns": employee_tab_ns
            })
            updated_devices += result.rowcount
        
        # Assign to departments
        if department_codes:
            dept_update_query = text("""
                UPDATE registered_devices rd
                SET assigned_policy_id = :policy_id,
                    policy_updated_at = CURRENT_TIMESTAMP,
                    policy_updated_by_tab_n = :updated_by
                FROM zup_agent_data zad
                WHERE rd.employee_tab_n = zad.tab_n
                AND zad.department_code = ANY(:department_codes)
            """)
            
            result = await db.execute(dept_update_query, {
                "policy_id": policy_id,
                "updated_by": current_user.get("tab_n"),
                "department_codes": department_codes
            })
            updated_devices += result.rowcount
        
        # Trigger compliance check for affected devices
        compliance_update_query = text("""
            UPDATE registered_devices
            SET policy_compliance_status = 'pending_check',
                last_compliance_check = NULL
            WHERE assigned_policy_id = :policy_id
        """)
        
        await db.execute(compliance_update_query, {"policy_id": policy_id})
        
        await db.commit()
        
        return {
            "status": "success",
            "updated_devices": updated_devices,
            "message": f"Policy assigned to {updated_devices} devices successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to assign policy: {str(e)}")

# =============================================================================
# REMOTE DEVICE ACTIONS
# =============================================================================

@router.post("/remote-actions", status_code=202)
@track_performance("mobile_device_remote_action")
async def execute_remote_action(
    action: RemoteAction,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Execute remote action on device (lock, wipe, locate, etc.)"""
    try:
        # Check permissions
        if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
            # Check if it's user's own device or they're a manager
            device_check_query = text("""
                SELECT rd.employee_tab_n, zad.manager_tab_n
                FROM registered_devices rd
                JOIN zup_agent_data zad ON zad.tab_n = rd.employee_tab_n
                WHERE rd.id = :device_id
            """)
            
            device_result = await db.execute(device_check_query, {"device_id": action.device_id})
            device_info = device_result.fetchone()
            
            if not device_info:
                raise HTTPException(status_code=404, detail="Device not found")
            
            if (device_info.employee_tab_n != current_user.get("tab_n") and 
                device_info.manager_tab_n != current_user.get("tab_n")):
                raise HTTPException(status_code=403, detail="Insufficient permissions")
        
        # Validate action type
        dangerous_actions = ["wipe", "restrict"]
        if action.action_type in dangerous_actions and not action.emergency_action:
            if not current_user.get("role_name") in ["admin", "security_officer"]:
                raise HTTPException(status_code=403, detail=f"Action '{action.action_type}' requires higher privileges")
        
        # Create remote action record
        action_id = str(uuid4())
        action_query = text("""
            INSERT INTO device_remote_actions (
                id, device_id, action_type, action_reason,
                emergency_action, scheduled_execution,
                wipe_external_storage, lock_message, alarm_duration_seconds,
                requested_by_tab_n, status, created_at
            ) VALUES (
                :id, :device_id, :action_type, :reason,
                :emergency_action, :scheduled_execution,
                :wipe_external_storage, :lock_message, :alarm_duration,
                :requested_by, 'PENDING', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(action_query, {
            "id": action_id,
            "device_id": action.device_id,
            "action_type": action.action_type,
            "reason": action.reason,
            "emergency_action": action.emergency_action,
            "scheduled_execution": action.scheduled_execution,
            "wipe_external_storage": action.wipe_external_storage,
            "lock_message": action.lock_message,
            "alarm_duration": action.alarm_duration_seconds,
            "requested_by": current_user.get("tab_n")
        })
        
        # Update device status for certain actions
        if action.action_type in ["lock", "restrict"]:
            status_update_query = text("""
                UPDATE registered_devices
                SET status = 'suspended',
                    last_action = :action_type,
                    last_action_time = CURRENT_TIMESTAMP
                WHERE id = :device_id
            """)
            
            await db.execute(status_update_query, {
                "device_id": action.device_id,
                "action_type": action.action_type
            })
        elif action.action_type == "wipe":
            status_update_query = text("""
                UPDATE registered_devices
                SET status = 'retired',
                    last_action = :action_type,
                    last_action_time = CURRENT_TIMESTAMP
                WHERE id = :device_id
            """)
            
            await db.execute(status_update_query, {
                "device_id": action.device_id,
                "action_type": action.action_type
            })
        
        # In a real implementation, this would trigger the actual remote action
        # For now, we'll simulate immediate execution for non-scheduled actions
        if not action.scheduled_execution:
            execute_query = text("""
                UPDATE device_remote_actions
                SET status = 'EXECUTED',
                    executed_at = CURRENT_TIMESTAMP,
                    execution_result = 'Command sent to device successfully'
                WHERE id = :action_id
            """)
            
            await db.execute(execute_query, {"action_id": action_id})
        
        await db.commit()
        
        return {
            "status": "accepted",
            "action_id": action_id,
            "message": f"Remote action '{action.action_type}' queued for execution",
            "scheduled_execution": action.scheduled_execution
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to execute remote action: {str(e)}")

# =============================================================================
# COMPLIANCE MONITORING
# =============================================================================

@router.post("/compliance/check", status_code=200)
@track_performance("mobile_device_compliance_check")
async def trigger_compliance_check(
    device_ids: Optional[List[str]] = None,
    employee_tab_n: Optional[str] = None,
    force_check: bool = False,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Trigger compliance check for devices"""
    try:
        # Check permissions
        if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
            if employee_tab_n and employee_tab_n != current_user.get("tab_n"):
                raise HTTPException(status_code=403, detail="Can only check compliance for own devices")
        
        where_conditions = ["rd.status = 'active'"]
        params = {}
        
        if device_ids:
            where_conditions.append("rd.id = ANY(:device_ids)")
            params["device_ids"] = device_ids
        elif employee_tab_n:
            where_conditions.append("rd.employee_tab_n = :employee_tab_n")
            params["employee_tab_n"] = employee_tab_n
        else:
            # Check all devices if admin
            if not current_user.get("role_name") in ["admin", "it_manager", "security_officer"]:
                where_conditions.append("rd.employee_tab_n = :current_user")
                params["current_user"] = current_user.get("tab_n")
        
        if not force_check:
            where_conditions.append("""
                (rd.last_compliance_check IS NULL 
                 OR rd.last_compliance_check < CURRENT_TIMESTAMP - INTERVAL '1 hour')
            """)
        
        # Get devices for compliance check
        devices_query = text(f"""
            SELECT 
                rd.id, rd.employee_tab_n, rd.assigned_policy_id,
                rd.passcode_enabled, rd.biometric_enabled, rd.encryption_enabled,
                rd.vpn_enabled, rd.jailbroken_rooted,
                sp.require_passcode, sp.require_biometric, sp.require_encryption,
                sp.require_vpn, sp.allow_jailbreak_root, sp.non_compliance_action
            FROM registered_devices rd
            LEFT JOIN security_policies sp ON sp.id = rd.assigned_policy_id
            WHERE {' AND '.join(where_conditions)}
        """)
        
        devices_result = await db.execute(devices_query, params)
        devices = devices_result.fetchall()
        
        checked_devices = 0
        violations_found = 0
        
        for device in devices:
            compliance_status = PolicyStatus.COMPLIANT
            violations = []
            
            # Check policy compliance
            if device.assigned_policy_id:
                if device.require_passcode and not device.passcode_enabled:
                    violations.append("Passcode not enabled")
                
                if device.require_biometric and not device.biometric_enabled:
                    violations.append("Biometric authentication not enabled")
                
                if device.require_encryption and not device.encryption_enabled:
                    violations.append("Device encryption not enabled")
                
                if device.require_vpn and not device.vpn_enabled:
                    violations.append("VPN connection not enabled")
                
                if not device.allow_jailbreak_root and device.jailbroken_rooted:
                    violations.append("Device is jailbroken/rooted")
            
            if violations:
                compliance_status = PolicyStatus.NON_COMPLIANT
                violations_found += 1
                
                # Record violations
                for violation in violations:
                    violation_query = text("""
                        INSERT INTO compliance_violations (
                            id, device_id, violation_type, violation_description,
                            detected_at, severity, created_at
                        ) VALUES (
                            :id, :device_id, 'POLICY_VIOLATION', :description,
                            CURRENT_TIMESTAMP, 
                            CASE WHEN :description LIKE '%jailbroken%' THEN 'HIGH' ELSE 'MEDIUM' END,
                            CURRENT_TIMESTAMP
                        )
                        ON CONFLICT (device_id, violation_type, violation_description) 
                        DO UPDATE SET detected_at = CURRENT_TIMESTAMP
                    """)
                    
                    await db.execute(violation_query, {
                        "id": str(uuid4()),
                        "device_id": device.id,
                        "description": violation
                    })
            
            # Update device compliance status
            compliance_update_query = text("""
                UPDATE registered_devices
                SET 
                    policy_compliance_status = :status,
                    last_compliance_check = CURRENT_TIMESTAMP
                WHERE id = :device_id
            """)
            
            await db.execute(compliance_update_query, {
                "device_id": device.id,
                "status": compliance_status.value
            })
            
            checked_devices += 1
        
        await db.commit()
        
        return {
            "status": "success",
            "checked_devices": checked_devices,
            "violations_found": violations_found,
            "message": f"Compliance check completed for {checked_devices} devices"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to check compliance: {str(e)}")