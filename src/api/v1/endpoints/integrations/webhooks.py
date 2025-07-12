"""
Webhook Management Endpoints

This module provides webhook management functionality for integration events:
- Webhook endpoint registration
- Event subscription management
- Delivery tracking and retry logic
- Webhook security and authentication

Webhook events are used for real-time notifications of integration activities.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....db.models import WebhookEndpoint, WebhookDelivery
from ....v1.schemas.integrations import (
    WebhookEndpointCreate, WebhookEndpointUpdate, WebhookEndpointResponse,
    WebhookDeliveryResponse, IntegrationResponse
)
from ....models.user import User
from ....services.webhook_service import WebhookService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/webhooks", tags=["webhook-management"])


@router.post("/", response_model=WebhookEndpointResponse)
async def create_webhook_endpoint(
    webhook_data: WebhookEndpointCreate,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> WebhookEndpointResponse:
    """
    Create a new webhook endpoint
    
    Args:
        webhook_data: Webhook endpoint data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        WebhookEndpointResponse with created webhook
        
    Raises:
        HTTPException: If webhook creation fails
    """
    try:
        # Create webhook endpoint
        webhook = WebhookEndpoint(
            name=webhook_data.name,
            url=webhook_data.url,
            method=webhook_data.method,
            headers=webhook_data.headers,
            event_types=webhook_data.event_types,
            secret=webhook_data.secret,
            auth_type=webhook_data.auth_type,
            auth_credentials=webhook_data.auth_credentials,
            timeout_seconds=webhook_data.timeout_seconds,
            retry_attempts=webhook_data.retry_attempts,
            retry_delay_seconds=webhook_data.retry_delay_seconds,
            organization_id=current_user.organization_id,
            created_by=current_user.id
        )
        
        db.add(webhook)
        await db.commit()
        await db.refresh(webhook)
        
        return WebhookEndpointResponse.from_orm(webhook)
        
    except Exception as e:
        logger.error(f"Error creating webhook endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create webhook endpoint: {str(e)}"
        )


@router.get("/", response_model=List[WebhookEndpointResponse])
async def list_webhook_endpoints(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    is_active: Optional[bool] = Query(None),
    event_type: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> List[WebhookEndpointResponse]:
    """
    List webhook endpoints
    
    Args:
        skip: Number of records to skip
        limit: Maximum number of records to return
        is_active: Filter by active status
        event_type: Filter by event type
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        List of WebhookEndpointResponse
        
    Raises:
        HTTPException: If listing fails
    """
    try:
        # Build query
        query = select(WebhookEndpoint).where(
            WebhookEndpoint.organization_id == current_user.organization_id
        )
        
        if is_active is not None:
            query = query.where(WebhookEndpoint.is_active == is_active)
        
        if event_type:
            query = query.where(WebhookEndpoint.event_types.contains([event_type]))
        
        query = query.order_by(desc(WebhookEndpoint.created_at)).offset(skip).limit(limit)
        
        result = await db.execute(query)
        webhooks = result.scalars().all()
        
        return [WebhookEndpointResponse.from_orm(webhook) for webhook in webhooks]
        
    except Exception as e:
        logger.error(f"Error listing webhook endpoints: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list webhook endpoints: {str(e)}"
        )


@router.get("/{webhook_id}", response_model=WebhookEndpointResponse)
async def get_webhook_endpoint(
    webhook_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> WebhookEndpointResponse:
    """
    Get a specific webhook endpoint
    
    Args:
        webhook_id: Webhook endpoint ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        WebhookEndpointResponse
        
    Raises:
        HTTPException: If webhook not found
    """
    try:
        stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        webhook = result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        return WebhookEndpointResponse.from_orm(webhook)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting webhook endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get webhook endpoint: {str(e)}"
        )


@router.put("/{webhook_id}", response_model=WebhookEndpointResponse)
async def update_webhook_endpoint(
    webhook_id: UUID,
    webhook_data: WebhookEndpointUpdate,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> WebhookEndpointResponse:
    """
    Update a webhook endpoint
    
    Args:
        webhook_id: Webhook endpoint ID
        webhook_data: Updated webhook data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        WebhookEndpointResponse with updated webhook
        
    Raises:
        HTTPException: If webhook not found or update fails
    """
    try:
        stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        webhook = result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        # Update fields
        update_data = webhook_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(webhook, field, value)
        
        webhook.updated_at = datetime.utcnow()
        await db.commit()
        await db.refresh(webhook)
        
        return WebhookEndpointResponse.from_orm(webhook)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating webhook endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update webhook endpoint: {str(e)}"
        )


@router.delete("/{webhook_id}")
async def delete_webhook_endpoint(
    webhook_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Delete a webhook endpoint
    
    Args:
        webhook_id: Webhook endpoint ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with deletion result
        
    Raises:
        HTTPException: If webhook not found or deletion fails
    """
    try:
        stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        webhook = result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        await db.delete(webhook)
        await db.commit()
        
        return IntegrationResponse(
            success=True,
            message="Webhook endpoint deleted successfully",
            data={"webhook_id": str(webhook_id)}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting webhook endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete webhook endpoint: {str(e)}"
        )


@router.post("/{webhook_id}/test")
async def test_webhook_endpoint(
    webhook_id: UUID,
    test_payload: Optional[Dict[str, Any]] = None,
    background_tasks: BackgroundTasks = BackgroundTasks(),
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Test a webhook endpoint
    
    Args:
        webhook_id: Webhook endpoint ID
        test_payload: Optional test payload
        background_tasks: FastAPI background tasks
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with test result
        
    Raises:
        HTTPException: If webhook not found or test fails
    """
    try:
        stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        webhook = result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        # Create test payload if not provided
        if test_payload is None:
            test_payload = {
                "event_type": "integration.test",
                "data": {
                    "message": "Test webhook delivery",
                    "timestamp": datetime.utcnow().isoformat(),
                    "webhook_id": str(webhook_id)
                }
            }
        
        # Schedule webhook delivery
        webhook_service = WebhookService()
        background_tasks.add_task(
            webhook_service.deliver_webhook,
            webhook,
            "integration.test",
            test_payload
        )
        
        return IntegrationResponse(
            success=True,
            message="Test webhook delivery scheduled",
            data={
                "webhook_id": str(webhook_id),
                "test_payload": test_payload
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error testing webhook endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to test webhook endpoint: {str(e)}"
        )


@router.get("/{webhook_id}/deliveries", response_model=List[WebhookDeliveryResponse])
async def get_webhook_deliveries(
    webhook_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    status: Optional[str] = Query(None),
    event_type: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> List[WebhookDeliveryResponse]:
    """
    Get webhook deliveries for a specific webhook
    
    Args:
        webhook_id: Webhook endpoint ID
        skip: Number of records to skip
        limit: Maximum number of records to return
        status: Filter by delivery status
        event_type: Filter by event type
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        List of WebhookDeliveryResponse
        
    Raises:
        HTTPException: If webhook not found or query fails
    """
    try:
        # Verify webhook exists and belongs to user's organization
        webhook_stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        webhook_result = await db.execute(webhook_stmt)
        webhook = webhook_result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        # Build delivery query
        query = select(WebhookDelivery).where(
            WebhookDelivery.webhook_id == webhook_id
        )
        
        if status:
            query = query.where(WebhookDelivery.delivery_status == status)
        
        if event_type:
            query = query.where(WebhookDelivery.event_type == event_type)
        
        query = query.order_by(desc(WebhookDelivery.created_at)).offset(skip).limit(limit)
        
        result = await db.execute(query)
        deliveries = result.scalars().all()
        
        return [WebhookDeliveryResponse.from_orm(delivery) for delivery in deliveries]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting webhook deliveries: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get webhook deliveries: {str(e)}"
        )


@router.post("/{webhook_id}/deliveries/{delivery_id}/retry")
async def retry_webhook_delivery(
    webhook_id: UUID,
    delivery_id: UUID,
    background_tasks: BackgroundTasks = BackgroundTasks(),
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Retry a failed webhook delivery
    
    Args:
        webhook_id: Webhook endpoint ID
        delivery_id: Webhook delivery ID
        background_tasks: FastAPI background tasks
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with retry result
        
    Raises:
        HTTPException: If webhook or delivery not found
    """
    try:
        # Verify webhook exists and belongs to user's organization
        webhook_stmt = select(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.id == webhook_id,
                WebhookEndpoint.organization_id == current_user.organization_id
            )
        )
        webhook_result = await db.execute(webhook_stmt)
        webhook = webhook_result.scalar_one_or_none()
        
        if not webhook:
            raise HTTPException(
                status_code=404,
                detail="Webhook endpoint not found"
            )
        
        # Get delivery
        delivery_stmt = select(WebhookDelivery).where(
            and_(
                WebhookDelivery.id == delivery_id,
                WebhookDelivery.webhook_id == webhook_id
            )
        )
        delivery_result = await db.execute(delivery_stmt)
        delivery = delivery_result.scalar_one_or_none()
        
        if not delivery:
            raise HTTPException(
                status_code=404,
                detail="Webhook delivery not found"
            )
        
        # Check if delivery can be retried
        if delivery.delivery_status == "delivered":
            raise HTTPException(
                status_code=400,
                detail="Cannot retry successfully delivered webhook"
            )
        
        # Schedule retry
        webhook_service = WebhookService()
        background_tasks.add_task(
            webhook_service.retry_webhook_delivery,
            delivery
        )
        
        return IntegrationResponse(
            success=True,
            message="Webhook delivery retry scheduled",
            data={
                "webhook_id": str(webhook_id),
                "delivery_id": str(delivery_id)
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrying webhook delivery: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retry webhook delivery: {str(e)}"
        )


@router.get("/events/types")
async def get_webhook_event_types(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get available webhook event types
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with available event types and descriptions
    """
    try:
        event_types = {
            "integration.connection.created": "New integration connection created",
            "integration.connection.updated": "Integration connection updated",
            "integration.connection.deleted": "Integration connection deleted",
            "integration.connection.status_changed": "Integration connection status changed",
            "integration.sync.started": "Integration sync started",
            "integration.sync.completed": "Integration sync completed",
            "integration.sync.failed": "Integration sync failed",
            "integration.personnel.sync.completed": "Personnel sync completed",
            "integration.schedule.sent": "Schedule sent to external system",
            "integration.timesheet.sent": "Timesheet sent to external system",
            "contact_center.agent.status.updated": "Agent status updated",
            "contact_center.queue.metrics.updated": "Queue metrics updated",
            "contact_center.data.imported": "Data imported from contact center",
            "contact_center.data.exported": "Data exported to contact center",
            "1c.personnel.synced": "Personnel synced with 1C",
            "1c.schedule.sent": "Schedule sent to 1C",
            "1c.timesheet.sent": "Timesheet sent to 1C",
            "1c.deviations.received": "Deviations received from 1C",
            "webhook.delivery.failed": "Webhook delivery failed",
            "webhook.delivery.successful": "Webhook delivery successful",
            "system.maintenance.started": "System maintenance started",
            "system.maintenance.completed": "System maintenance completed"
        }
        
        return {
            "event_types": event_types,
            "total_types": len(event_types),
            "categories": {
                "integration": [k for k in event_types.keys() if k.startswith("integration.")],
                "contact_center": [k for k in event_types.keys() if k.startswith("contact_center.")],
                "1c": [k for k in event_types.keys() if k.startswith("1c.")],
                "webhook": [k for k in event_types.keys() if k.startswith("webhook.")],
                "system": [k for k in event_types.keys() if k.startswith("system.")]
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting webhook event types: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get webhook event types: {str(e)}"
        )


@router.get("/stats")
async def get_webhook_stats(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get webhook statistics
    
    Args:
        days: Number of days to include in statistics
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with webhook statistics
    """
    try:
        # Get date range
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Get webhook endpoints count
        webhook_count_stmt = select(func.count(WebhookEndpoint.id)).where(
            WebhookEndpoint.organization_id == current_user.organization_id
        )
        webhook_count_result = await db.execute(webhook_count_stmt)
        total_webhooks = webhook_count_result.scalar()
        
        # Get active webhooks count
        active_webhooks_stmt = select(func.count(WebhookEndpoint.id)).where(
            and_(
                WebhookEndpoint.organization_id == current_user.organization_id,
                WebhookEndpoint.is_active == True
            )
        )
        active_webhooks_result = await db.execute(active_webhooks_stmt)
        active_webhooks = active_webhooks_result.scalar()
        
        # Get deliveries in date range
        deliveries_stmt = select(WebhookDelivery).join(WebhookEndpoint).where(
            and_(
                WebhookEndpoint.organization_id == current_user.organization_id,
                WebhookDelivery.created_at >= start_date,
                WebhookDelivery.created_at <= end_date
            )
        )
        deliveries_result = await db.execute(deliveries_stmt)
        deliveries = deliveries_result.scalars().all()
        
        # Calculate statistics
        total_deliveries = len(deliveries)
        successful_deliveries = sum(1 for d in deliveries if d.delivery_status == "delivered")
        failed_deliveries = sum(1 for d in deliveries if d.delivery_status == "failed")
        pending_deliveries = sum(1 for d in deliveries if d.delivery_status == "pending")
        
        success_rate = (successful_deliveries / total_deliveries) * 100 if total_deliveries > 0 else 0
        
        # Group by event type
        event_type_stats = {}
        for delivery in deliveries:
            event_type = delivery.event_type
            if event_type not in event_type_stats:
                event_type_stats[event_type] = {
                    "total": 0,
                    "successful": 0,
                    "failed": 0,
                    "pending": 0
                }
            
            event_type_stats[event_type]["total"] += 1
            event_type_stats[event_type][delivery.delivery_status] += 1
        
        return {
            "period": {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "days": days
            },
            "webhooks": {
                "total": total_webhooks,
                "active": active_webhooks,
                "inactive": total_webhooks - active_webhooks
            },
            "deliveries": {
                "total": total_deliveries,
                "successful": successful_deliveries,
                "failed": failed_deliveries,
                "pending": pending_deliveries,
                "success_rate": round(success_rate, 2)
            },
            "event_types": event_type_stats,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error getting webhook stats: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get webhook stats: {str(e)}"
        )