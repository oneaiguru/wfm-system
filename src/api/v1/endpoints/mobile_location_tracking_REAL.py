"""
Advanced Mobile Location Tracking API - Task 62
GPS location tracking with geofencing and privacy controls
Features: Real-time tracking, geofence alerts, location history, privacy settings
Database: location_history, geofences, tracking_sessions
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, and_, or_, func, case
from typing import List, Optional, Dict, Any, Tuple
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
from uuid import UUID, uuid4
import json
import math
from enum import Enum
# from geopy.distance import geodesic  # Would need: pip install geopy

from ...core.database import get_db
from ...auth.dependencies import get_current_user
from ...middleware.monitoring import track_performance
from ...utils.validators import validate_coordinates

router = APIRouter()

# =============================================================================
# MODELS AND SCHEMAS
# =============================================================================

class TrackingMode(str, Enum):
    DISABLED = "disabled"
    WORK_HOURS_ONLY = "work_hours_only"
    ALWAYS = "always"
    ON_DEMAND = "on_demand"

class GeofenceType(str, Enum):
    WORKPLACE = "workplace"
    BREAK_AREA = "break_area"
    CUSTOMER_SITE = "customer_site"
    RESTRICTED_AREA = "restricted_area"
    EMERGENCY_ZONE = "emergency_zone"

class LocationPrecision(str, Enum):
    HIGH = "high"        # GPS + Network
    MEDIUM = "medium"    # Network only
    LOW = "low"         # Cell tower only

class PrivacyLevel(str, Enum):
    PUBLIC = "public"           # Visible to all authorized users
    MANAGER_ONLY = "manager_only"  # Only direct manager
    ADMIN_ONLY = "admin_only"      # Only system admins
    PRIVATE = "private"         # Employee only

class LocationPoint(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    altitude: Optional[float] = None
    accuracy: Optional[float] = None  # meters
    timestamp: datetime = Field(default_factory=datetime.now)
    
    @validator('latitude', 'longitude')
    def validate_coordinates(cls, v):
        if not validate_coordinates(v):
            raise ValueError('Invalid coordinates')
        return v

class GeofenceDefinition(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    geofence_type: GeofenceType
    center_lat: float = Field(..., ge=-90, le=90)
    center_lng: float = Field(..., ge=-180, le=180)
    radius_meters: float = Field(..., gt=0, le=50000)  # Max 50km radius
    is_active: bool = True
    
    # Alert settings
    entry_alert: bool = True
    exit_alert: bool = True
    dwell_time_alert_minutes: Optional[int] = None
    
    # Schedule constraints
    active_days: List[int] = Field(default=[0,1,2,3,4,5,6])  # 0=Monday
    active_time_start: Optional[str] = None  # HH:MM format
    active_time_end: Optional[str] = None
    
    # Assignment
    assigned_employees: Optional[List[str]] = None
    assigned_departments: Optional[List[str]] = None

class TrackingPreferences(BaseModel):
    tracking_mode: TrackingMode = TrackingMode.WORK_HOURS_ONLY
    location_precision: LocationPrecision = LocationPrecision.MEDIUM
    privacy_level: PrivacyLevel = PrivacyLevel.MANAGER_ONLY
    
    # Update frequency (minutes)
    update_frequency_working: int = Field(default=5, ge=1, le=60)
    update_frequency_break: int = Field(default=15, ge=1, le=60)
    update_frequency_idle: int = Field(default=30, ge=1, le=120)
    
    # Battery optimization
    low_battery_mode: bool = True
    background_tracking: bool = True
    wifi_only_sync: bool = False
    
    # Privacy controls
    location_history_retention_days: int = Field(default=90, ge=1, le=365)
    share_location_with_colleagues: bool = False
    emergency_override_enabled: bool = True

class LocationUpdateRequest(BaseModel):
    employee_tab_n: str = Field(..., max_length=50)
    location: LocationPoint
    session_id: Optional[str] = None
    is_working: bool = True
    current_activity: Optional[str] = None
    device_info: Optional[Dict[str, Any]] = None

# =============================================================================
# TASK 62: GET /api/v1/mobile/location/tracking
# =============================================================================

@router.get("/tracking", status_code=200)
@track_performance("mobile_location_tracking_status")
async def get_location_tracking_status(
    employee_tab_n: Optional[str] = Query(None),
    include_history: bool = Query(False),
    history_hours: int = Query(24, le=168),  # Max 1 week
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get GPS location tracking status and history with privacy controls
    
    Enterprise features:
    - Real-time location tracking
    - Geofence monitoring and alerts
    - Location history with retention policies
    - Privacy settings and access controls
    """
    try:
        # Determine which employee data to retrieve
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Check authorization for accessing other employees' data
        if employee_tab_n and employee_tab_n != current_user.get("tab_n"):
            # Check if user has permission to view other employees' locations
            auth_query = text("""
                SELECT 
                    zad.tab_n,
                    zad.manager_tab_n,
                    ur.role_name,
                    lp.privacy_level,
                    CASE 
                        WHEN ur.role_name IN ('admin', 'hr_manager') THEN true
                        WHEN zad.manager_tab_n = :current_user_tab_n THEN true
                        WHEN lp.privacy_level = 'public' THEN true
                        ELSE false
                    END as can_view_location
                FROM zup_agent_data zad
                LEFT JOIN user_roles ur ON ur.tab_n = :current_user_tab_n
                LEFT JOIN location_tracking_preferences lp ON lp.employee_tab_n = zad.tab_n
                WHERE zad.tab_n = :target_employee
            """)
            
            auth_result = await db.execute(auth_query, {
                "current_user_tab_n": current_user.get("tab_n"),
                "target_employee": target_employee
            })
            auth_data = auth_result.fetchone()
            
            if not auth_data or not auth_data.can_view_location:
                raise HTTPException(status_code=403, detail="Insufficient permissions to view location data")
        
        # Get tracking preferences
        prefs_query = text("""
            SELECT * FROM location_tracking_preferences
            WHERE employee_tab_n = :tab_n
        """)
        
        prefs_result = await db.execute(prefs_query, {"tab_n": target_employee})
        preferences = prefs_result.fetchone()
        
        if not preferences:
            # Create default preferences
            default_prefs_query = text("""
                INSERT INTO location_tracking_preferences (
                    employee_tab_n, tracking_mode, location_precision,
                    privacy_level, update_frequency_working, 
                    update_frequency_break, update_frequency_idle,
                    low_battery_mode, background_tracking,
                    location_history_retention_days, created_at
                ) VALUES (
                    :tab_n, 'work_hours_only', 'medium', 'manager_only',
                    5, 15, 30, true, true, 90, CURRENT_TIMESTAMP
                ) RETURNING *
            """)
            
            prefs_result = await db.execute(default_prefs_query, {"tab_n": target_employee})
            preferences = prefs_result.fetchone()
            await db.commit()
        
        # Get current tracking session
        session_query = text("""
            SELECT 
                id, session_start, session_end, is_active,
                total_locations_recorded, last_update,
                average_accuracy, battery_optimization_active
            FROM location_tracking_sessions
            WHERE employee_tab_n = :tab_n
            AND (session_end IS NULL OR session_end > CURRENT_TIMESTAMP - INTERVAL '1 hour')
            ORDER BY session_start DESC
            LIMIT 1
        """)
        
        session_result = await db.execute(session_query, {"tab_n": target_employee})
        current_session = session_result.fetchone()
        
        # Get latest location
        latest_location_query = text("""
            SELECT 
                latitude, longitude, altitude, accuracy,
                recorded_at, is_working, current_activity,
                geofence_status, inside_geofences
            FROM location_history
            WHERE employee_tab_n = :tab_n
            ORDER BY recorded_at DESC
            LIMIT 1
        """)
        
        location_result = await db.execute(latest_location_query, {"tab_n": target_employee})
        latest_location = location_result.fetchone()
        
        # Get active geofences for employee
        geofences_query = text("""
            SELECT 
                g.id, g.name, g.geofence_type, g.center_lat, g.center_lng,
                g.radius_meters, g.entry_alert, g.exit_alert,
                g.dwell_time_alert_minutes, g.is_active,
                CASE 
                    WHEN :latest_lat IS NOT NULL AND :latest_lng IS NOT NULL THEN
                        (6371000 * acos(cos(radians(:latest_lat)) * cos(radians(g.center_lat)) * 
                         cos(radians(g.center_lng) - radians(:latest_lng)) + 
                         sin(radians(:latest_lat)) * sin(radians(g.center_lat))))
                    ELSE NULL
                END as distance_meters,
                CASE 
                    WHEN :latest_lat IS NOT NULL AND :latest_lng IS NOT NULL THEN
                        (6371000 * acos(cos(radians(:latest_lat)) * cos(radians(g.center_lat)) * 
                         cos(radians(g.center_lng) - radians(:latest_lng)) + 
                         sin(radians(:latest_lat)) * sin(radians(g.center_lat)))) <= g.radius_meters
                    ELSE false
                END as currently_inside
            FROM geofences g
            LEFT JOIN geofence_assignments ga ON ga.geofence_id = g.id
            WHERE g.is_active = true
            AND (
                ga.employee_tab_n = :tab_n
                OR ga.department_code IN (
                    SELECT department_code FROM zup_agent_data WHERE tab_n = :tab_n
                )
                OR NOT EXISTS (SELECT 1 FROM geofence_assignments WHERE geofence_id = g.id)
            )
        """)
        
        geofences_result = await db.execute(geofences_query, {
            "tab_n": target_employee,
            "latest_lat": latest_location.latitude if latest_location else None,
            "latest_lng": latest_location.longitude if latest_location else None
        })
        geofences = [dict(row._mapping) for row in geofences_result.fetchall()]
        
        # Get location history if requested
        location_history = []
        if include_history and history_hours > 0:
            history_query = text("""
                SELECT 
                    latitude, longitude, altitude, accuracy,
                    recorded_at, is_working, current_activity,
                    geofence_status, speed_kmh, heading
                FROM location_history
                WHERE employee_tab_n = :tab_n
                AND recorded_at >= CURRENT_TIMESTAMP - INTERVAL ':hours hours'
                ORDER BY recorded_at DESC
                LIMIT 1000
            """)
            
            history_result = await db.execute(history_query, {
                "tab_n": target_employee,
                "hours": history_hours
            })
            location_history = [dict(row._mapping) for row in history_result.fetchall()]
        
        # Get recent geofence events
        geofence_events_query = text("""
            SELECT 
                ge.event_type, ge.geofence_name, ge.event_time,
                ge.latitude, ge.longitude, ge.dwell_duration_minutes
            FROM geofence_events ge
            WHERE ge.employee_tab_n = :tab_n
            AND ge.event_time >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
            ORDER BY ge.event_time DESC
            LIMIT 50
        """)
        
        events_result = await db.execute(geofence_events_query, {"tab_n": target_employee})
        geofence_events = [dict(row._mapping) for row in events_result.fetchall()]
        
        return {
            "employee_tab_n": target_employee,
            "tracking_preferences": {
                "tracking_mode": preferences.tracking_mode,
                "location_precision": preferences.location_precision,
                "privacy_level": preferences.privacy_level,
                "update_frequency_working": preferences.update_frequency_working,
                "update_frequency_break": preferences.update_frequency_break,
                "update_frequency_idle": preferences.update_frequency_idle,
                "low_battery_mode": preferences.low_battery_mode,
                "background_tracking": preferences.background_tracking,
                "location_history_retention_days": preferences.location_history_retention_days
            },
            "current_session": {
                "id": current_session.id if current_session else None,
                "is_active": current_session.is_active if current_session else False,
                "session_start": current_session.session_start if current_session else None,
                "last_update": current_session.last_update if current_session else None,
                "total_locations": current_session.total_locations_recorded if current_session else 0,
                "average_accuracy": current_session.average_accuracy if current_session else None
            },
            "latest_location": {
                "latitude": latest_location.latitude if latest_location else None,
                "longitude": latest_location.longitude if latest_location else None,
                "accuracy": latest_location.accuracy if latest_location else None,
                "recorded_at": latest_location.recorded_at if latest_location else None,
                "is_working": latest_location.is_working if latest_location else None,
                "current_activity": latest_location.current_activity if latest_location else None
            } if latest_location else None,
            "geofences": geofences,
            "recent_geofence_events": geofence_events,
            "location_history": location_history if include_history else []
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get location tracking status: {str(e)}")

@router.post("/tracking/start", status_code=201)
@track_performance("mobile_location_tracking_start")
async def start_location_tracking(
    employee_tab_n: Optional[str] = None,
    precision: LocationPrecision = LocationPrecision.MEDIUM,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start a new location tracking session"""
    try:
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Check if user can start tracking for this employee
        if employee_tab_n and employee_tab_n != current_user.get("tab_n"):
            # Only managers and admins can start tracking for others
            auth_query = text("""
                SELECT ur.role_name, zad.manager_tab_n
                FROM user_roles ur, zup_agent_data zad
                WHERE ur.tab_n = :current_user
                AND zad.tab_n = :target_employee
                AND (ur.role_name IN ('admin', 'hr_manager') OR zad.manager_tab_n = :current_user)
            """)
            
            auth_result = await db.execute(auth_query, {
                "current_user": current_user.get("tab_n"),
                "target_employee": target_employee
            })
            
            if not auth_result.fetchone():
                raise HTTPException(status_code=403, detail="Insufficient permissions")
        
        # End any active sessions
        end_session_query = text("""
            UPDATE location_tracking_sessions
            SET session_end = CURRENT_TIMESTAMP, is_active = false
            WHERE employee_tab_n = :tab_n AND is_active = true
        """)
        
        await db.execute(end_session_query, {"tab_n": target_employee})
        
        # Create new tracking session
        session_id = str(uuid4())
        create_session_query = text("""
            INSERT INTO location_tracking_sessions (
                id, employee_tab_n, session_start, is_active,
                precision_level, started_by_tab_n, created_at
            ) VALUES (
                :session_id, :tab_n, CURRENT_TIMESTAMP, true,
                :precision, :started_by, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(create_session_query, {
            "session_id": session_id,
            "tab_n": target_employee,
            "precision": precision.value,
            "started_by": current_user.get("tab_n")
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "session_id": session_id,
            "message": f"Location tracking started for {target_employee}",
            "precision": precision.value
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to start location tracking: {str(e)}")

@router.post("/tracking/update", status_code=200)
@track_performance("mobile_location_tracking_update")
async def update_location(
    request: LocationUpdateRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update employee location with geofence checking"""
    try:
        # Validate that user can update location for this employee
        if request.employee_tab_n != current_user.get("tab_n"):
            # Check if it's a system service or authorized manager
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only update own location")
        
        # Get active tracking session
        session_query = text("""
            SELECT id, precision_level FROM location_tracking_sessions
            WHERE employee_tab_n = :tab_n AND is_active = true
            ORDER BY session_start DESC LIMIT 1
        """)
        
        session_result = await db.execute(session_query, {"tab_n": request.employee_tab_n})
        session = session_result.fetchone()
        
        if not session:
            raise HTTPException(status_code=400, detail="No active tracking session found")
        
        # Insert location record
        location_id = str(uuid4())
        location_query = text("""
            INSERT INTO location_history (
                id, employee_tab_n, session_id, latitude, longitude,
                altitude, accuracy, recorded_at, is_working,
                current_activity, device_info, created_at
            ) VALUES (
                :id, :tab_n, :session_id, :lat, :lng,
                :alt, :accuracy, :timestamp, :is_working,
                :activity, :device_info, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(location_query, {
            "id": location_id,
            "tab_n": request.employee_tab_n,
            "session_id": session.id,
            "lat": request.location.latitude,
            "lng": request.location.longitude,
            "alt": request.location.altitude,
            "accuracy": request.location.accuracy,
            "timestamp": request.location.timestamp,
            "is_working": request.is_working,
            "activity": request.current_activity,
            "device_info": json.dumps(request.device_info) if request.device_info else None
        })
        
        # Check geofences
        geofence_alerts = await _check_geofences(
            request.employee_tab_n,
            request.location.latitude,
            request.location.longitude,
            db
        )
        
        # Update session statistics
        update_session_query = text("""
            UPDATE location_tracking_sessions
            SET 
                last_update = CURRENT_TIMESTAMP,
                total_locations_recorded = total_locations_recorded + 1,
                latest_latitude = :lat,
                latest_longitude = :lng,
                latest_accuracy = :accuracy
            WHERE id = :session_id
        """)
        
        await db.execute(update_session_query, {
            "session_id": session.id,
            "lat": request.location.latitude,
            "lng": request.location.longitude,
            "accuracy": request.location.accuracy
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "location_id": location_id,
            "geofence_alerts": geofence_alerts,
            "message": "Location updated successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update location: {str(e)}")

# =============================================================================
# GEOFENCE MANAGEMENT
# =============================================================================

@router.post("/geofences", status_code=201)
@track_performance("mobile_geofence_create")
async def create_geofence(
    request: GeofenceDefinition,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new geofence with alert settings"""
    try:
        geofence_id = str(uuid4())
        
        # Create geofence
        geofence_query = text("""
            INSERT INTO geofences (
                id, name, description, geofence_type,
                center_lat, center_lng, radius_meters,
                entry_alert, exit_alert, dwell_time_alert_minutes,
                active_days, active_time_start, active_time_end,
                is_active, created_by_tab_n, created_at
            ) VALUES (
                :id, :name, :description, :type,
                :lat, :lng, :radius,
                :entry_alert, :exit_alert, :dwell_alert,
                :active_days, :time_start, :time_end,
                :is_active, :created_by, CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(geofence_query, {
            "id": geofence_id,
            "name": request.name,
            "description": request.description,
            "type": request.geofence_type.value,
            "lat": request.center_lat,
            "lng": request.center_lng,
            "radius": request.radius_meters,
            "entry_alert": request.entry_alert,
            "exit_alert": request.exit_alert,
            "dwell_alert": request.dwell_time_alert_minutes,
            "active_days": json.dumps(request.active_days),
            "time_start": request.active_time_start,
            "time_end": request.active_time_end,
            "is_active": request.is_active,
            "created_by": current_user.get("tab_n")
        })
        
        # Assign to employees if specified
        if request.assigned_employees:
            for employee_tab_n in request.assigned_employees:
                assignment_query = text("""
                    INSERT INTO geofence_assignments (
                        geofence_id, employee_tab_n, assigned_by_tab_n, created_at
                    ) VALUES (:geofence_id, :tab_n, :assigned_by, CURRENT_TIMESTAMP)
                """)
                
                await db.execute(assignment_query, {
                    "geofence_id": geofence_id,
                    "tab_n": employee_tab_n,
                    "assigned_by": current_user.get("tab_n")
                })
        
        # Assign to departments if specified
        if request.assigned_departments:
            for dept_code in request.assigned_departments:
                dept_assignment_query = text("""
                    INSERT INTO geofence_assignments (
                        geofence_id, department_code, assigned_by_tab_n, created_at
                    ) VALUES (:geofence_id, :dept_code, :assigned_by, CURRENT_TIMESTAMP)
                """)
                
                await db.execute(dept_assignment_query, {
                    "geofence_id": geofence_id,
                    "dept_code": dept_code,
                    "assigned_by": current_user.get("tab_n")
                })
        
        await db.commit()
        
        return {
            "status": "success",
            "geofence_id": geofence_id,
            "message": "Geofence created successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create geofence: {str(e)}")

@router.get("/geofences")
@track_performance("mobile_geofence_list")
async def list_geofences(
    employee_tab_n: Optional[str] = Query(None),
    geofence_type: Optional[GeofenceType] = Query(None),
    active_only: bool = Query(True),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List geofences with filtering options"""
    try:
        where_conditions = ["1=1"]
        params = {}
        
        if active_only:
            where_conditions.append("g.is_active = true")
        
        if geofence_type:
            where_conditions.append("g.geofence_type = :geofence_type")
            params["geofence_type"] = geofence_type.value
        
        if employee_tab_n:
            where_conditions.append("""
                (ga.employee_tab_n = :employee_tab_n
                 OR ga.department_code IN (
                     SELECT department_code FROM zup_agent_data WHERE tab_n = :employee_tab_n
                 )
                 OR NOT EXISTS (SELECT 1 FROM geofence_assignments WHERE geofence_id = g.id))
            """)
            params["employee_tab_n"] = employee_tab_n
        
        query = text(f"""
            SELECT DISTINCT
                g.id, g.name, g.description, g.geofence_type,
                g.center_lat, g.center_lng, g.radius_meters,
                g.entry_alert, g.exit_alert, g.dwell_time_alert_minutes,
                g.active_days, g.active_time_start, g.active_time_end,
                g.is_active, g.created_at
            FROM geofences g
            LEFT JOIN geofence_assignments ga ON ga.geofence_id = g.id
            WHERE {' AND '.join(where_conditions)}
            ORDER BY g.name
        """)
        
        result = await db.execute(query, params)
        geofences = [dict(row._mapping) for row in result.fetchall()]
        
        return {
            "geofences": geofences,
            "total_count": len(geofences)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list geofences: {str(e)}")

# =============================================================================
# PRIVACY CONTROLS
# =============================================================================

@router.put("/preferences", status_code=200)
@track_performance("mobile_location_preferences_update")
async def update_tracking_preferences(
    preferences: TrackingPreferences,
    employee_tab_n: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update location tracking preferences and privacy settings"""
    try:
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Only allow users to update their own preferences (unless admin)
        if target_employee != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "hr_manager"]:
                raise HTTPException(status_code=403, detail="Can only update own preferences")
        
        update_query = text("""
            INSERT INTO location_tracking_preferences (
                employee_tab_n, tracking_mode, location_precision, privacy_level,
                update_frequency_working, update_frequency_break, update_frequency_idle,
                low_battery_mode, background_tracking, wifi_only_sync,
                location_history_retention_days, share_location_with_colleagues,
                emergency_override_enabled, updated_at
            ) VALUES (
                :tab_n, :tracking_mode, :precision, :privacy_level,
                :freq_working, :freq_break, :freq_idle,
                :low_battery, :background, :wifi_only,
                :retention_days, :share_location, :emergency_override,
                CURRENT_TIMESTAMP
            )
            ON CONFLICT (employee_tab_n) DO UPDATE SET
                tracking_mode = EXCLUDED.tracking_mode,
                location_precision = EXCLUDED.location_precision,
                privacy_level = EXCLUDED.privacy_level,
                update_frequency_working = EXCLUDED.update_frequency_working,
                update_frequency_break = EXCLUDED.update_frequency_break,
                update_frequency_idle = EXCLUDED.update_frequency_idle,
                low_battery_mode = EXCLUDED.low_battery_mode,
                background_tracking = EXCLUDED.background_tracking,
                wifi_only_sync = EXCLUDED.wifi_only_sync,
                location_history_retention_days = EXCLUDED.location_history_retention_days,
                share_location_with_colleagues = EXCLUDED.share_location_with_colleagues,
                emergency_override_enabled = EXCLUDED.emergency_override_enabled,
                updated_at = CURRENT_TIMESTAMP
        """)
        
        await db.execute(update_query, {
            "tab_n": target_employee,
            "tracking_mode": preferences.tracking_mode.value,
            "precision": preferences.location_precision.value,
            "privacy_level": preferences.privacy_level.value,
            "freq_working": preferences.update_frequency_working,
            "freq_break": preferences.update_frequency_break,
            "freq_idle": preferences.update_frequency_idle,
            "low_battery": preferences.low_battery_mode,
            "background": preferences.background_tracking,
            "wifi_only": preferences.wifi_only_sync,
            "retention_days": preferences.location_history_retention_days,
            "share_location": preferences.share_location_with_colleagues,
            "emergency_override": preferences.emergency_override_enabled
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "message": "Location tracking preferences updated successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update preferences: {str(e)}")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

async def _check_geofences(employee_tab_n: str, latitude: float, longitude: float, db: AsyncSession) -> List[Dict]:
    """Check if location triggers any geofence alerts"""
    alerts = []
    
    try:
        # Get all active geofences for employee
        geofences_query = text("""
            SELECT 
                g.id, g.name, g.geofence_type, g.center_lat, g.center_lng,
                g.radius_meters, g.entry_alert, g.exit_alert,
                g.dwell_time_alert_minutes
            FROM geofences g
            LEFT JOIN geofence_assignments ga ON ga.geofence_id = g.id
            WHERE g.is_active = true
            AND (
                ga.employee_tab_n = :tab_n
                OR ga.department_code IN (
                    SELECT department_code FROM zup_agent_data WHERE tab_n = :tab_n
                )
                OR NOT EXISTS (SELECT 1 FROM geofence_assignments WHERE geofence_id = g.id)
            )
        """)
        
        geofences_result = await db.execute(geofences_query, {"tab_n": employee_tab_n})
        geofences = geofences_result.fetchall()
        
        # Check each geofence
        for geofence in geofences:
            # Calculate distance using Haversine formula
            distance = _calculate_distance(
                latitude, longitude,
                geofence.center_lat, geofence.center_lng
            )
            
            is_inside = distance <= geofence.radius_meters
            
            # Check previous location to determine entry/exit
            prev_location_query = text("""
                SELECT latitude, longitude, geofence_status
                FROM location_history
                WHERE employee_tab_n = :tab_n
                ORDER BY recorded_at DESC
                OFFSET 1 LIMIT 1
            """)
            
            prev_result = await db.execute(prev_location_query, {"tab_n": employee_tab_n})
            prev_location = prev_result.fetchone()
            
            was_inside = False
            if prev_location:
                prev_distance = _calculate_distance(
                    prev_location.latitude, prev_location.longitude,
                    geofence.center_lat, geofence.center_lng
                )
                was_inside = prev_distance <= geofence.radius_meters
            
            # Determine event type
            event_type = None
            if is_inside and not was_inside:
                event_type = "ENTRY"
                should_alert = geofence.entry_alert
            elif not is_inside and was_inside:
                event_type = "EXIT"
                should_alert = geofence.exit_alert
            else:
                should_alert = False
            
            # Record geofence event if there's a change
            if event_type:
                event_query = text("""
                    INSERT INTO geofence_events (
                        id, employee_tab_n, geofence_id, geofence_name,
                        event_type, event_time, latitude, longitude,
                        distance_meters, created_at
                    ) VALUES (
                        :id, :tab_n, :geofence_id, :name,
                        :event_type, CURRENT_TIMESTAMP, :lat, :lng,
                        :distance, CURRENT_TIMESTAMP
                    )
                """)
                
                await db.execute(event_query, {
                    "id": str(uuid4()),
                    "tab_n": employee_tab_n,
                    "geofence_id": geofence.id,
                    "name": geofence.name,
                    "event_type": event_type,
                    "lat": latitude,
                    "lng": longitude,
                    "distance": distance
                })
                
                if should_alert:
                    alerts.append({
                        "geofence_id": geofence.id,
                        "geofence_name": geofence.name,
                        "geofence_type": geofence.geofence_type,
                        "event_type": event_type,
                        "distance_meters": distance,
                        "alert_sent": True
                    })
        
        return alerts
        
    except Exception as e:
        print(f"Error checking geofences: {e}")
        return []

def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points using Haversine formula"""
    # Haversine formula implementation
    R = 6371000  # Earth's radius in meters
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c