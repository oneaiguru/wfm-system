"""
Advanced Mobile Push Notification API - Task 61
Enterprise-grade push notification system with targeting and campaigns
Features: User segmentation, A/B testing, delivery tracking, analytics
Database: push_notifications, device_tokens, notification_campaigns
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, and_, or_, func, case
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from uuid import UUID, uuid4
import json
import asyncio
from enum import Enum

from ...core.database import get_db
from ...auth.dependencies import get_current_user
from ...middleware.monitoring import track_performance
from ...utils.validators import validate_push_content

router = APIRouter()

# =============================================================================
# MODELS AND SCHEMAS
# =============================================================================

class NotificationPriority(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"

class NotificationCategory(str, Enum):
    SCHEDULE = "schedule_reminder"
    BREAK = "break_reminder" 
    LUNCH = "lunch_reminder"
    REQUEST = "request_update"
    EXCHANGE = "exchange_notification"
    EMERGENCY = "emergency_alert"
    MARKETING = "marketing"
    ANNOUNCEMENT = "announcement"

class TargetingCriteria(BaseModel):
    department_codes: Optional[List[str]] = None
    skill_groups: Optional[List[str]] = None
    employment_status: Optional[List[str]] = None
    shift_types: Optional[List[str]] = None
    location_codes: Optional[List[str]] = None
    seniority_months_min: Optional[int] = None
    seniority_months_max: Optional[int] = None
    last_login_days: Optional[int] = None

class ABTestVariant(BaseModel):
    variant_id: str = Field(..., max_length=50)
    title: str = Field(..., max_length=200)
    body: str = Field(..., max_length=500)
    action_text: Optional[str] = Field(None, max_length=50)
    deep_link: Optional[str] = Field(None, max_length=200)
    weight: float = Field(default=50.0, ge=0, le=100)

class PushNotificationRequest(BaseModel):
    title: str = Field(..., max_length=200)
    body: str = Field(..., max_length=500)
    category: NotificationCategory
    priority: NotificationPriority = NotificationPriority.NORMAL
    
    # Targeting
    target_employees: Optional[List[str]] = None  # Specific tab_n values
    targeting_criteria: Optional[TargetingCriteria] = None
    
    # Scheduling
    send_immediately: bool = True
    scheduled_send_time: Optional[datetime] = None
    timezone: str = "Europe/Moscow"
    
    # Content and interaction
    action_text: Optional[str] = Field(None, max_length=50)
    deep_link: Optional[str] = Field(None, max_length=200)
    custom_data: Optional[Dict[str, Any]] = None
    
    # Campaign settings
    campaign_name: Optional[str] = Field(None, max_length=100)
    ab_test_variants: Optional[List[ABTestVariant]] = None
    
    # Delivery options
    respect_quiet_hours: bool = True
    require_delivery_confirmation: bool = False
    max_retry_attempts: int = 3

class CampaignRequest(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    category: NotificationCategory
    
    # Campaign timeline
    start_date: datetime
    end_date: Optional[datetime] = None
    
    # Targeting and variants
    targeting_criteria: TargetingCriteria
    ab_test_variants: List[ABTestVariant]
    
    # Campaign settings
    frequency_cap: Optional[int] = None  # Max notifications per employee
    respect_quiet_hours: bool = True
    priority: NotificationPriority = NotificationPriority.NORMAL

# =============================================================================
# TASK 61: POST /api/v1/mobile/push/send
# =============================================================================

@router.post("/send", status_code=200)
@track_performance("mobile_push_send")
async def send_push_notification(
    request: PushNotificationRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Send advanced push notification with targeting and tracking
    
    Enterprise features:
    - User segmentation and targeting
    - A/B testing with multiple variants
    - Delivery tracking and analytics
    - Campaign management
    - Quiet hours and user preferences
    """
    try:
        # Validate content
        if not validate_push_content(request.title, request.body):
            raise HTTPException(status_code=400, detail="Invalid notification content")
        
        # Create notification campaign record
        campaign_id = str(uuid4())
        
        notification_query = text("""
            INSERT INTO push_notification_campaigns (
                id, name, category, priority, created_by_tab_n,
                title, body, action_text, deep_link, custom_data,
                targeting_criteria, send_immediately, scheduled_send_time,
                respect_quiet_hours, require_delivery_confirmation,
                max_retry_attempts, status, created_at
            ) VALUES (
                :campaign_id, :campaign_name, :category, :priority, :created_by,
                :title, :body, :action_text, :deep_link, :custom_data,
                :targeting_criteria, :send_immediately, :scheduled_send_time,
                :respect_quiet_hours, :require_delivery_confirmation,
                :max_retry_attempts, 'CREATED', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(notification_query, {
            "campaign_id": campaign_id,
            "campaign_name": request.campaign_name or f"Notification_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "category": request.category.value,
            "priority": request.priority.value,
            "created_by": current_user.get("tab_n"),
            "title": request.title,
            "body": request.body,
            "action_text": request.action_text,
            "deep_link": request.deep_link,
            "custom_data": json.dumps(request.custom_data) if request.custom_data else None,
            "targeting_criteria": json.dumps(request.targeting_criteria.dict()) if request.targeting_criteria else None,
            "send_immediately": request.send_immediately,
            "scheduled_send_time": request.scheduled_send_time,
            "respect_quiet_hours": request.respect_quiet_hours,
            "require_delivery_confirmation": request.require_delivery_confirmation,
            "max_retry_attempts": request.max_retry_attempts
        })
        
        # Determine target audience
        target_employees = []
        
        if request.target_employees:
            # Specific employees
            target_employees = request.target_employees
        elif request.targeting_criteria:
            # Dynamic targeting based on criteria
            targeting_query = text("""
                SELECT DISTINCT zad.tab_n
                FROM zup_agent_data zad
                LEFT JOIN employee_skills es ON es.employee_tab_n = zad.tab_n
                LEFT JOIN mobile_sessions ms ON ms.employee_tab_n = zad.tab_n
                WHERE zad.is_active = true
                AND (
                    :department_codes IS NULL 
                    OR zad.department_code = ANY(string_to_array(:department_codes, ','))
                )
                AND (
                    :skill_groups IS NULL
                    OR es.skill_group = ANY(string_to_array(:skill_groups, ','))
                )
                AND (
                    :employment_status IS NULL
                    OR zad.employment_status = ANY(string_to_array(:employment_status, ','))
                )
                AND (
                    :last_login_days IS NULL
                    OR ms.last_activity >= CURRENT_TIMESTAMP - INTERVAL ':last_login_days days'
                )
            """)
            
            criteria = request.targeting_criteria
            result = await db.execute(targeting_query, {
                "department_codes": ",".join(criteria.department_codes) if criteria.department_codes else None,
                "skill_groups": ",".join(criteria.skill_groups) if criteria.skill_groups else None,
                "employment_status": ",".join(criteria.employment_status) if criteria.employment_status else None,
                "last_login_days": criteria.last_login_days
            })
            
            target_employees = [row[0] for row in result.fetchall()]
        
        if not target_employees:
            raise HTTPException(status_code=400, detail="No target employees found")
        
        # Handle A/B testing variants
        variants_to_send = []
        if request.ab_test_variants and len(request.ab_test_variants) > 1:
            # Distribute employees across variants based on weights
            total_weight = sum(v.weight for v in request.ab_test_variants)
            current_index = 0
            
            for variant in request.ab_test_variants:
                variant_size = int(len(target_employees) * (variant.weight / total_weight))
                variant_employees = target_employees[current_index:current_index + variant_size]
                
                variants_to_send.append({
                    "variant": variant,
                    "employees": variant_employees
                })
                current_index += variant_size
            
            # Add remaining employees to last variant
            if current_index < len(target_employees):
                variants_to_send[-1]["employees"].extend(target_employees[current_index:])
        else:
            # Single variant (original notification)
            variants_to_send.append({
                "variant": ABTestVariant(
                    variant_id="original",
                    title=request.title,
                    body=request.body,
                    action_text=request.action_text,
                    deep_link=request.deep_link,
                    weight=100.0
                ),
                "employees": target_employees
            })
        
        # Create device tokens and notification queue entries
        total_queued = 0
        for variant_data in variants_to_send:
            variant = variant_data["variant"]
            employees = variant_data["employees"]
            
            for employee_tab_n in employees:
                # Get active device tokens for employee
                device_query = text("""
                    SELECT device_id, push_token, device_type
                    FROM mobile_sessions
                    WHERE employee_tab_n = :tab_n
                    AND is_active = true
                    AND expires_at > CURRENT_TIMESTAMP
                    AND push_token IS NOT NULL
                """)
                
                devices = await db.execute(device_query, {"tab_n": employee_tab_n})
                device_rows = devices.fetchall()
                
                for device_row in device_rows:
                    # Check user notification preferences
                    prefs_query = text("""
                        SELECT * FROM push_notification_settings
                        WHERE employee_tab_n = :tab_n
                    """)
                    
                    prefs_result = await db.execute(prefs_query, {"tab_n": employee_tab_n})
                    prefs = prefs_result.fetchone()
                    
                    # Check if notification should be sent based on preferences
                    should_send = True
                    if prefs:
                        category_enabled = getattr(prefs, f"{request.category.value.replace('_', '_')}", True)
                        if not category_enabled:
                            should_send = False
                        
                        # Check quiet hours
                        if request.respect_quiet_hours and prefs.quiet_hours_enabled:
                            current_time = datetime.now().time()
                            if prefs.quiet_hours_start <= current_time <= prefs.quiet_hours_end:
                                should_send = False
                    
                    if should_send:
                        # Queue notification for delivery
                        queue_query = text("""
                            INSERT INTO notification_delivery_queue (
                                id, campaign_id, employee_tab_n, device_id, device_type,
                                variant_id, title, body, action_text, deep_link,
                                push_token, priority, category, custom_data,
                                scheduled_delivery_time, max_retry_attempts,
                                require_confirmation, status, created_at
                            ) VALUES (
                                :id, :campaign_id, :employee_tab_n, :device_id, :device_type,
                                :variant_id, :title, :body, :action_text, :deep_link,
                                :push_token, :priority, :category, :custom_data,
                                :scheduled_time, :max_retries, :require_confirmation,
                                'QUEUED', CURRENT_TIMESTAMP
                            )
                        """)
                        
                        await db.execute(queue_query, {
                            "id": str(uuid4()),
                            "campaign_id": campaign_id,
                            "employee_tab_n": employee_tab_n,
                            "device_id": device_row[0],
                            "device_type": device_row[2],
                            "variant_id": variant.variant_id,
                            "title": variant.title,
                            "body": variant.body,
                            "action_text": variant.action_text,
                            "deep_link": variant.deep_link,
                            "push_token": device_row[1],
                            "priority": request.priority.value,
                            "category": request.category.value,
                            "custom_data": json.dumps(request.custom_data) if request.custom_data else None,
                            "scheduled_time": request.scheduled_send_time if not request.send_immediately else datetime.now(),
                            "max_retries": request.max_retry_attempts,
                            "require_confirmation": request.require_delivery_confirmation
                        })
                        
                        total_queued += 1
        
        # Update campaign status
        update_campaign_query = text("""
            UPDATE push_notification_campaigns
            SET status = 'QUEUED', target_count = :target_count, queued_at = CURRENT_TIMESTAMP
            WHERE id = :campaign_id
        """)
        
        await db.execute(update_campaign_query, {
            "campaign_id": campaign_id,
            "target_count": total_queued
        })
        
        await db.commit()
        
        # If sending immediately, trigger delivery process
        if request.send_immediately:
            await _trigger_immediate_delivery(campaign_id, db)
        
        return {
            "status": "success",
            "campaign_id": campaign_id,
            "target_audience_size": len(target_employees),
            "notifications_queued": total_queued,
            "variants_count": len(variants_to_send),
            "delivery_status": "immediate" if request.send_immediately else "scheduled"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to send push notification: {str(e)}")

# =============================================================================
# CAMPAIGN MANAGEMENT
# =============================================================================

@router.post("/campaigns", status_code=201)
@track_performance("mobile_push_campaign_create")
async def create_notification_campaign(
    request: CampaignRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a notification campaign with A/B testing"""
    try:
        campaign_id = str(uuid4())
        
        # Validate A/B test variants
        if len(request.ab_test_variants) < 2:
            raise HTTPException(status_code=400, detail="A/B test requires at least 2 variants")
        
        total_weight = sum(v.weight for v in request.ab_test_variants)
        if abs(total_weight - 100.0) > 0.1:
            raise HTTPException(status_code=400, detail="Variant weights must sum to 100%")
        
        # Create campaign
        campaign_query = text("""
            INSERT INTO push_notification_campaigns (
                id, name, description, category, priority, 
                start_date, end_date, targeting_criteria,
                ab_test_variants, frequency_cap, respect_quiet_hours,
                created_by_tab_n, status, created_at
            ) VALUES (
                :id, :name, :description, :category, :priority,
                :start_date, :end_date, :targeting_criteria,
                :ab_test_variants, :frequency_cap, :respect_quiet_hours,
                :created_by, 'DRAFT', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(campaign_query, {
            "id": campaign_id,
            "name": request.name,
            "description": request.description,
            "category": request.category.value,
            "priority": request.priority.value,
            "start_date": request.start_date,
            "end_date": request.end_date,
            "targeting_criteria": json.dumps(request.targeting_criteria.dict()),
            "ab_test_variants": json.dumps([v.dict() for v in request.ab_test_variants]),
            "frequency_cap": request.frequency_cap,
            "respect_quiet_hours": request.respect_quiet_hours,
            "created_by": current_user.get("tab_n")
        })
        
        await db.commit()
        
        return {
            "status": "success",
            "campaign_id": campaign_id,
            "message": "Campaign created successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create campaign: {str(e)}")

@router.get("/campaigns/{campaign_id}/analytics")
@track_performance("mobile_push_campaign_analytics")
async def get_campaign_analytics(
    campaign_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed campaign performance analytics"""
    try:
        # Get campaign overview
        campaign_query = text("""
            SELECT c.*, 
                COUNT(DISTINCT ndq.employee_tab_n) as target_audience,
                COUNT(ndq.id) as total_sent,
                COUNT(CASE WHEN ndq.delivery_status = 'DELIVERED' THEN 1 END) as delivered,
                COUNT(CASE WHEN ndq.delivery_status = 'FAILED' THEN 1 END) as failed,
                COUNT(CASE WHEN ndq.opened_at IS NOT NULL THEN 1 END) as opened,
                COUNT(CASE WHEN ndq.clicked_at IS NOT NULL THEN 1 END) as clicked
            FROM push_notification_campaigns c
            LEFT JOIN notification_delivery_queue ndq ON ndq.campaign_id = c.id
            WHERE c.id = :campaign_id
            GROUP BY c.id
        """)
        
        result = await db.execute(campaign_query, {"campaign_id": campaign_id})
        campaign = result.fetchone()
        
        if not campaign:
            raise HTTPException(status_code=404, detail="Campaign not found")
        
        # Get variant performance
        variant_query = text("""
            SELECT 
                variant_id,
                COUNT(*) as sent_count,
                COUNT(CASE WHEN delivery_status = 'DELIVERED' THEN 1 END) as delivered_count,
                COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END) as opened_count,
                COUNT(CASE WHEN clicked_at IS NOT NULL THEN 1 END) as clicked_count,
                AVG(CASE WHEN opened_at IS NOT NULL THEN 
                    EXTRACT(EPOCH FROM (opened_at - sent_at))/60 END) as avg_time_to_open_minutes
            FROM notification_delivery_queue
            WHERE campaign_id = :campaign_id
            GROUP BY variant_id
        """)
        
        variant_results = await db.execute(variant_query, {"campaign_id": campaign_id})
        variants = [dict(row._mapping) for row in variant_results.fetchall()]
        
        # Calculate performance metrics
        total_sent = campaign.total_sent or 0
        delivered = campaign.delivered or 0
        opened = campaign.opened or 0
        clicked = campaign.clicked or 0
        
        delivery_rate = (delivered / total_sent * 100) if total_sent > 0 else 0
        open_rate = (opened / delivered * 100) if delivered > 0 else 0
        click_rate = (clicked / opened * 100) if opened > 0 else 0
        
        return {
            "campaign_id": campaign_id,
            "campaign_name": campaign.name,
            "status": campaign.status,
            "created_at": campaign.created_at,
            "metrics": {
                "target_audience": campaign.target_audience,
                "total_sent": total_sent,
                "delivered": delivered,
                "failed": campaign.failed,
                "opened": opened,
                "clicked": clicked,
                "delivery_rate": round(delivery_rate, 2),
                "open_rate": round(open_rate, 2),
                "click_rate": round(click_rate, 2)
            },
            "variant_performance": variants
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get campaign analytics: {str(e)}")

# =============================================================================
# DELIVERY TRACKING
# =============================================================================

@router.get("/delivery/status")
@track_performance("mobile_push_delivery_status")
async def get_delivery_status(
    campaign_id: Optional[str] = Query(None),
    employee_tab_n: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    limit: int = Query(100, le=1000),
    offset: int = Query(0),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get delivery status for notifications with filtering options"""
    try:
        where_conditions = ["1=1"]
        params = {"limit": limit, "offset": offset}
        
        if campaign_id:
            where_conditions.append("ndq.campaign_id = :campaign_id")
            params["campaign_id"] = campaign_id
            
        if employee_tab_n:
            where_conditions.append("ndq.employee_tab_n = :employee_tab_n")
            params["employee_tab_n"] = employee_tab_n
            
        if status:
            where_conditions.append("ndq.delivery_status = :status")
            params["status"] = status
        
        query = text(f"""
            SELECT 
                ndq.id,
                ndq.campaign_id,
                c.name as campaign_name,
                ndq.employee_tab_n,
                zad.fio_full as employee_name,
                ndq.variant_id,
                ndq.title,
                ndq.device_type,
                ndq.delivery_status,
                ndq.sent_at,
                ndq.delivered_at,
                ndq.opened_at,
                ndq.clicked_at,
                ndq.failure_reason,
                ndq.retry_count
            FROM notification_delivery_queue ndq
            LEFT JOIN push_notification_campaigns c ON c.id = ndq.campaign_id
            LEFT JOIN zup_agent_data zad ON zad.tab_n = ndq.employee_tab_n
            WHERE {' AND '.join(where_conditions)}
            ORDER BY ndq.created_at DESC
            LIMIT :limit OFFSET :offset
        """)
        
        result = await db.execute(query, params)
        notifications = [dict(row._mapping) for row in result.fetchall()]
        
        # Get total count
        count_query = text(f"""
            SELECT COUNT(*) 
            FROM notification_delivery_queue ndq
            WHERE {' AND '.join(where_conditions)}
        """)
        
        count_result = await db.execute(count_query, {k: v for k, v in params.items() if k not in ['limit', 'offset']})
        total_count = count_result.scalar()
        
        return {
            "notifications": notifications,
            "total_count": total_count,
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get delivery status: {str(e)}")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

async def _trigger_immediate_delivery(campaign_id: str, db: AsyncSession):
    """Trigger immediate delivery of queued notifications"""
    try:
        # Update queued notifications to processing
        update_query = text("""
            UPDATE notification_delivery_queue
            SET status = 'PROCESSING', processing_started_at = CURRENT_TIMESTAMP
            WHERE campaign_id = :campaign_id AND status = 'QUEUED'
        """)
        
        await db.execute(update_query, {"campaign_id": campaign_id})
        await db.commit()
        
        # In a real implementation, this would trigger the actual push notification service
        # For now, we'll simulate successful delivery
        await asyncio.sleep(0.1)  # Simulate processing time
        
        # Mark as sent (in production, this would be done by the delivery service)
        delivery_query = text("""
            UPDATE notification_delivery_queue
            SET delivery_status = 'DELIVERED', 
                sent_at = CURRENT_TIMESTAMP,
                delivered_at = CURRENT_TIMESTAMP
            WHERE campaign_id = :campaign_id AND status = 'PROCESSING'
        """)
        
        await db.execute(delivery_query, {"campaign_id": campaign_id})
        await db.commit()
        
    except Exception as e:
        # Mark as failed
        failure_query = text("""
            UPDATE notification_delivery_queue
            SET delivery_status = 'FAILED', 
                failure_reason = :error,
                sent_at = CURRENT_TIMESTAMP
            WHERE campaign_id = :campaign_id AND status = 'PROCESSING'
        """)
        
        await db.execute(failure_query, {
            "campaign_id": campaign_id,
            "error": str(e)
        })
        await db.commit()
        
        raise e