"""
GET /api/v1/mobile/profile/personal - Access Personal Information via Mobile
BDD Implementation: 14-mobile-personal-cabinet.feature
Scenario: "View and Manage Personal Profile" (Lines 165-181)

This endpoint implements mobile-optimized profile from agents table,
following the exact BDD scenario requirements:
- Display complete personal information
- Enable profile management capabilities
- Show work rules and organizational details
- Provide subscription and preference management
"""

from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import logging
from datetime import datetime

from api.core.database import get_db
from api.auth.dependencies import get_current_user
import asyncpg

# BDD TRACEABILITY: Lines 165-181 "View and Manage Personal Profile"
logger = logging.getLogger(__name__)

router = APIRouter()

class PersonalProfileInfo(BaseModel):
    """
    BDD Scenario Output: Lines 168-175
    Complete personal information display
    """
    full_name: str = Field(..., description="My complete name")
    department: str = Field(..., description="Organizational unit")
    position: str = Field(..., description="Job title")
    employee_id: str = Field(..., description="Personnel number (tab_n)")
    supervisor_contact: Optional[str] = Field(None, description="Manager's phone")
    time_zone: str = Field(..., description="My working timezone")
    
    # Additional profile information
    email: Optional[str] = Field(None, description="Work email address")
    phone: Optional[str] = Field(None, description="Contact phone number")
    hire_date: Optional[datetime] = Field(None, description="Employment start date")
    status: str = Field(..., description="Employment status")

class ProfileCapabilities(BaseModel):
    """
    BDD Scenario Output: Lines 176-181
    Profile management capabilities
    """
    subscribe_to_updates: bool = Field(..., description="Enable/disable notifications")
    update_contact_info: bool = Field(..., description="Modify personal details")
    change_preferences: bool = Field(..., description="Adjust personal settings")
    view_work_rules: bool = Field(..., description="See assigned work patterns")

class WorkRulesInfo(BaseModel):
    """Work rules and patterns assigned to employee"""
    work_pattern_id: Optional[str] = Field(None, description="Work pattern identifier")
    work_pattern_name: Optional[str] = Field(None, description="Work pattern description")
    weekly_hours: Optional[int] = Field(None, description="Standard weekly hours")
    shift_rules: Optional[Dict[str, Any]] = Field(None, description="Shift assignment rules")

class PersonalProfileResponse(BaseModel):
    """
    BDD Scenario Complete Response: Lines 165-181
    Mobile-optimized personal profile with all capabilities
    """
    profile_info: PersonalProfileInfo = Field(..., description="Complete personal information")
    capabilities: ProfileCapabilities = Field(..., description="Available profile actions")
    work_rules: WorkRulesInfo = Field(..., description="Assigned work patterns")
    
    # Mobile-specific enhancements
    mobile_preferences: Dict[str, Any] = Field(..., description="Mobile app preferences")
    notification_subscriptions: Dict[str, bool] = Field(..., description="Current subscriptions")
    last_updated: datetime = Field(..., description="Profile last update time")
    
    employee_tab_n: str = Field(..., description="Employee identifier")

@router.get("/api/v1/mobile/profile/personal", 
           response_model=PersonalProfileResponse,
           summary="Access Personal Information via Mobile",
           description="""
           BDD Scenario: View and Manage Personal Profile
           
           Implements the complete mobile profile access:
           1. Retrieves personal information from agents table
           2. Shows organizational details and supervisor contact
           3. Provides profile management capabilities
           4. Displays assigned work rules and patterns
           5. Shows current notification subscriptions
           
           Real database implementation using zup_agent_data and related tables.
           """)
async def get_mobile_personal_profile(
    current_user = Depends(get_current_user),
    db: asyncpg.Connection = Depends(get_db)
) -> PersonalProfileResponse:
    """
    BDD Implementation: "View and Manage Personal Profile"
    
    This endpoint follows the exact BDD scenario steps:
    1. User accesses profile page (Line 166)
    2. Views personal information (Line 167)
    3. Sees complete profile info (Lines 168-175)
    4. Has access to profile actions (Lines 176-181)
    """
    try:
        # Extract employee tab_n from current_user (either User object or dict)
        if hasattr(current_user, 'id'):
            employee_tab_n = str(current_user.id)
        else:
            employee_tab_n = current_user.get("sub")
        logger.info(f"Getting mobile personal profile for employee: {employee_tab_n}")
        
        # BDD Step: "When I view my personal information" (Line 167)
        # BDD Step: "Then I should see:" (Lines 168-175)
        
        # Get complete personal information from zup_agent_data
        profile_query = """
            SELECT 
                zad.tab_n,
                zad.fio_full,
                zad.department,
                zad.position,
                zad.email,
                zad.phone,
                zad.hire_date,
                zad.status_tabel,
                zad.timezone,
                zad.supervisor_tab_n,
                sup.fio_full as supervisor_name,
                sup.phone as supervisor_phone,
                dep.department_name,
                dep.department_head
            FROM zup_agent_data zad
            LEFT JOIN zup_agent_data sup ON sup.tab_n = zad.supervisor_tab_n
            LEFT JOIN departments dep ON dep.department_code = zad.department
            WHERE zad.tab_n = $1
        """
        
        profile_result = await db.fetchrow(profile_query, employee_tab_n)
        
        if not profile_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee profile not found"
            )
        
        # BDD: Complete personal information (Lines 168-175)
        profile_info = PersonalProfileInfo(
            full_name=profile_result['fio_full'],  # "My complete name"
            department=profile_result['department_name'] or profile_result['department'],  # "Organizational unit"
            position=profile_result['position'],  # "Job title"
            employee_id=profile_result['tab_n'],  # "Personnel number"
            supervisor_contact=profile_result['supervisor_phone'],  # "Manager's phone"
            time_zone=profile_result['timezone'] or 'Europe/Moscow',  # "My working timezone"
            email=profile_result['email'],
            phone=profile_result['phone'],
            hire_date=profile_result['hire_date'],
            status=profile_result['status_tabel']
        )
        
        # BDD Step: "And I should be able to:" (Lines 176-181)
        # Get current notification subscription status
        subscription_query = """
            SELECT schedule_reminders, break_reminders, lunch_reminders,
                   request_updates, exchange_notifications, emergency_alerts
            FROM push_notification_settings 
            WHERE employee_tab_n = $1
        """
        subscription_result = await db.fetchrow(subscription_query, employee_tab_n)
        
        # BDD: Profile management capabilities (Lines 176-181)
        capabilities = ProfileCapabilities(
            subscribe_to_updates=True,  # "Enable/disable notifications"
            update_contact_info=True,   # "Modify personal details"
            change_preferences=True,    # "Adjust personal settings"
            view_work_rules=True       # "See assigned work patterns"
        )
        
        # BDD: "View work rules" - Get assigned work patterns (Line 181)
        work_rules_query = """
            SELECT 
                wp.pattern_id,
                wp.pattern_name,
                wp.weekly_hours,
                wp.shift_rules,
                ewr.assigned_date,
                ewr.effective_from,
                ewr.effective_to
            FROM employee_work_rules ewr
            JOIN work_patterns wp ON wp.pattern_id = ewr.work_pattern_id
            WHERE ewr.employee_tab_n = $1 
            AND (ewr.effective_to IS NULL OR ewr.effective_to >= CURRENT_DATE)
            ORDER BY ewr.effective_from DESC
            LIMIT 1
        """
        
        work_rules_result = await db.fetchrow(work_rules_query, employee_tab_n)
        
        work_rules = WorkRulesInfo(
            work_pattern_id=work_rules_result['pattern_id'] if work_rules_result else None,
            work_pattern_name=work_rules_result['pattern_name'] if work_rules_result else "Standard Work Pattern",
            weekly_hours=work_rules_result['weekly_hours'] if work_rules_result else 40,
            shift_rules=work_rules_result['shift_rules'] if work_rules_result else {}
        )
        
        # Get mobile app preferences
        mobile_prefs_query = """
            SELECT theme_mode, interface_language, font_size, high_contrast_mode,
                   auto_sync_enabled, sync_on_wifi_only
            FROM interface_customization 
            WHERE employee_tab_n = $1
        """
        mobile_prefs_result = await db.fetchrow(mobile_prefs_query, employee_tab_n)
        
        mobile_preferences = {}
        if mobile_prefs_result:
            mobile_preferences = {
                "theme_mode": mobile_prefs_result['theme_mode'],
                "interface_language": mobile_prefs_result['interface_language'],
                "font_size": mobile_prefs_result['font_size'],
                "high_contrast_mode": mobile_prefs_result['high_contrast_mode'],
                "auto_sync_enabled": mobile_prefs_result['auto_sync_enabled'],
                "sync_on_wifi_only": mobile_prefs_result['sync_on_wifi_only']
            }
        else:
            # Default mobile preferences
            mobile_preferences = {
                "theme_mode": "Light",
                "interface_language": "Russian",
                "font_size": "Medium",
                "high_contrast_mode": False,
                "auto_sync_enabled": True,
                "sync_on_wifi_only": False
            }
        
        # BDD: Current notification subscriptions
        notification_subscriptions = {}
        if subscription_result:
            notification_subscriptions = {
                "schedule_reminders": subscription_result['schedule_reminders'],
                "break_reminders": subscription_result['break_reminders'],
                "lunch_reminders": subscription_result['lunch_reminders'],
                "request_updates": subscription_result['request_updates'],
                "exchange_notifications": subscription_result['exchange_notifications'],
                "emergency_alerts": subscription_result['emergency_alerts']
            }
        else:
            # Default subscriptions
            notification_subscriptions = {
                "schedule_reminders": True,
                "break_reminders": True,
                "lunch_reminders": True,
                "request_updates": True,
                "exchange_notifications": True,
                "emergency_alerts": True
            }
        
        # Get last profile update time
        last_update_query = """
            SELECT GREATEST(
                COALESCE((SELECT updated_at FROM interface_customization WHERE employee_tab_n = $1), '1970-01-01'),
                COALESCE((SELECT updated_at FROM push_notification_settings WHERE employee_tab_n = $1), '1970-01-01'),
                COALESCE((SELECT updated_at FROM calendar_preferences WHERE employee_tab_n = $1), '1970-01-01')
            ) as last_updated
        """
        last_update_result = await db.fetchrow(last_update_query, employee_tab_n)
        last_updated = last_update_result['last_updated'] if last_update_result else datetime.utcnow()
        
        logger.info(f"Mobile personal profile retrieved successfully for {profile_info.full_name} ({employee_tab_n})")
        
        return PersonalProfileResponse(
            profile_info=profile_info,
            capabilities=capabilities,
            work_rules=work_rules,
            mobile_preferences=mobile_preferences,
            notification_subscriptions=notification_subscriptions,
            last_updated=last_updated,
            employee_tab_n=employee_tab_n
        )
        
    except asyncpg.PostgresError as e:
        logger.error(f"Database error in mobile personal profile: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in mobile personal profile: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Profile retrieval failed: {str(e)}"
        )

# Additional endpoint for updating contact information (BDD Line 179)
@router.put("/api/v1/mobile/profile/contact",
           summary="Update Personal Contact Information",
           description="BDD Capability: Modify personal details (Line 179)")
async def update_contact_info(
    email: Optional[str] = None,
    phone: Optional[str] = None,
    current_user = Depends(get_current_user),
    db: asyncpg.Connection = Depends(get_db)
):
    """
    Update personal contact information
    BDD: "Update contact info - Modify personal details" (Line 179)
    """
    try:
        # Extract employee tab_n from current_user (either User object or dict)
        if hasattr(current_user, 'id'):
            employee_tab_n = str(current_user.id)
        else:
            employee_tab_n = current_user.get("sub")
        
        # Build dynamic update query
        update_fields = []
        params = [employee_tab_n]
        param_count = 1
        
        if email is not None:
            param_count += 1
            update_fields.append(f"email = ${param_count}")
            params.append(email)
            
        if phone is not None:
            param_count += 1
            update_fields.append(f"phone = ${param_count}")
            params.append(phone)
        
        if not update_fields:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        update_query = f"""
            UPDATE zup_agent_data 
            SET {', '.join(update_fields)}, updated_at = CURRENT_TIMESTAMP
            WHERE tab_n = $1
            RETURNING email, phone
        """
        
        result = await db.fetchrow(update_query, *params)
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Employee not found"
            )
        
        return {
            "contact_updated": True,
            "email": result['email'],
            "phone": result['phone'],
            "updated_at": datetime.utcnow()
        }
        
    except Exception as e:
        logger.error(f"Error updating contact info: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# Additional endpoint for managing notification subscriptions (BDD Line 178)
@router.put("/api/v1/mobile/profile/subscriptions",
           summary="Manage Notification Subscriptions",
           description="BDD Capability: Subscribe to updates (Line 178)")
async def update_notification_subscriptions(
    subscriptions: Dict[str, bool],
    current_user = Depends(get_current_user),
    db: asyncpg.Connection = Depends(get_db)
):
    """
    Update notification subscription preferences
    BDD: "Subscribe to updates - Enable/disable notifications" (Line 178)
    """
    try:
        # Extract employee tab_n from current_user (either User object or dict)
        if hasattr(current_user, 'id'):
            employee_tab_n = str(current_user.id)
        else:
            employee_tab_n = current_user.get("sub")
        
        # Update notification settings
        update_query = """
            UPDATE push_notification_settings SET
                schedule_reminders = COALESCE($2, schedule_reminders),
                break_reminders = COALESCE($3, break_reminders),
                lunch_reminders = COALESCE($4, lunch_reminders),
                request_updates = COALESCE($5, request_updates),
                exchange_notifications = COALESCE($6, exchange_notifications),
                emergency_alerts = COALESCE($7, emergency_alerts),
                updated_at = CURRENT_TIMESTAMP
            WHERE employee_tab_n = $1
            RETURNING *
        """
        
        result = await db.fetchrow(
            update_query,
            employee_tab_n,
            subscriptions.get('schedule_reminders'),
            subscriptions.get('break_reminders'),
            subscriptions.get('lunch_reminders'),
            subscriptions.get('request_updates'),
            subscriptions.get('exchange_notifications'),
            subscriptions.get('emergency_alerts')
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification settings not found"
            )
        
        return {
            "subscriptions_updated": True,
            "current_subscriptions": {
                "schedule_reminders": result['schedule_reminders'],
                "break_reminders": result['break_reminders'],
                "lunch_reminders": result['lunch_reminders'],
                "request_updates": result['request_updates'],
                "exchange_notifications": result['exchange_notifications'],
                "emergency_alerts": result['emergency_alerts']
            },
            "updated_at": result['updated_at']
        }
        
    except Exception as e:
        logger.error(f"Error updating subscriptions: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )