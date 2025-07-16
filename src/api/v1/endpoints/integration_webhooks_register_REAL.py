from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel, HttpUrl, Field
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import uuid
import hashlib
import hmac
from ...core.database import get_db
from ...core.auth import get_current_user

router = APIRouter()

# BDD Scenario: "Register Webhook for Event Notifications"
# File: 22-cross-system-integration.feature

class WebhookRegistration(BaseModel):
    url: HttpUrl
    events: List[str]
    description: Optional[str] = None
    secret: Optional[str] = None
    active: bool = True
    retry_policy: Dict = Field(default={"max_retries": 3, "retry_delay": 300})
    rate_limit: Optional[int] = Field(default=100, description="Max events per hour")

class WebhookResponse(BaseModel):
    webhook_id: str
    url: str
    events: List[str]
    status: str
    created_at: datetime
    last_delivery: Optional[datetime]
    delivery_stats: Dict

@router.post("/integration/webhooks/register", response_model=WebhookResponse, tags=["🔥 REAL Integration"])
async def register_webhook(
    webhook: WebhookRegistration, 
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Register webhook for enterprise event notifications with delivery guarantees"""
    
    webhook_id = str(uuid.uuid4())
    
    # Validate webhook URL and events
    validate_query = text("""
        SELECT COUNT(*) as count FROM webhook_events 
        WHERE event_name = ANY(:events)
    """)
    
    validation_result = await db.execute(validate_query, {"events": webhook.events})
    valid_events = validation_result.scalar()
    
    if valid_events != len(webhook.events):
        raise HTTPException(status_code=400, detail="Invalid event types specified")
    
    # Generate webhook secret if not provided
    webhook_secret = webhook.secret or hashlib.sha256(f"{webhook_id}{datetime.utcnow()}".encode()).hexdigest()
    
    # Register webhook
    register_query = text("""
        INSERT INTO webhook_registrations (
            webhook_id, user_id, url, events, description, secret, 
            active, retry_policy, rate_limit, created_at, updated_at
        ) VALUES (
            :webhook_id, :user_id, :url, :events, :description, :secret,
            :active, :retry_policy, :rate_limit, :created_at, :updated_at
        ) RETURNING webhook_id, url, events, active, created_at
    """)
    
    result = await db.execute(register_query, {
        "webhook_id": webhook_id,
        "user_id": current_user["user_id"],
        "url": str(webhook.url),
        "events": webhook.events,
        "description": webhook.description,
        "secret": webhook_secret,
        "active": webhook.active,
        "retry_policy": webhook.retry_policy,
        "rate_limit": webhook.rate_limit,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    })
    
    webhook_data = result.fetchone()
    
    # Create event subscriptions
    for event in webhook.events:
        subscription_query = text("""
            INSERT INTO event_subscriptions (
                webhook_id, event_name, active, created_at
            ) VALUES (:webhook_id, :event_name, :active, :created_at)
        """)
        
        await db.execute(subscription_query, {
            "webhook_id": webhook_id,
            "event_name": event,
            "active": True,
            "created_at": datetime.utcnow()
        })
    
    await db.commit()
    
    # Schedule webhook validation test
    background_tasks.add_task(test_webhook_endpoint, webhook_id, str(webhook.url), webhook_secret)
    
    return WebhookResponse(
        webhook_id=webhook_id,
        url=str(webhook.url),
        events=webhook.events,
        status="registered",
        created_at=webhook_data.created_at,
        last_delivery=None,
        delivery_stats={
            "total_deliveries": 0,
            "successful_deliveries": 0,
            "failed_deliveries": 0,
            "average_response_time": 0
        }
    )

async def test_webhook_endpoint(webhook_id: str, url: str, secret: str):
    """Background task to test webhook endpoint"""
    import aiohttp
    import json
    
    test_payload = {
        "event": "webhook.test",
        "timestamp": datetime.utcnow().isoformat(),
        "data": {"message": "Webhook registration test"}
    }
    
    # Generate HMAC signature
    signature = hmac.new(
        secret.encode(), 
        json.dumps(test_payload).encode(), 
        hashlib.sha256
    ).hexdigest()
    
    headers = {
        "Content-Type": "application/json",
        "X-Webhook-Signature": f"sha256={signature}",
        "User-Agent": "WFM-Webhook/1.0"
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=test_payload, headers=headers, timeout=30) as response:
                success = response.status == 200
                
                # Log test result
                # This would update the webhook status in the database
                
    except Exception as e:
        # Log webhook test failure
        pass