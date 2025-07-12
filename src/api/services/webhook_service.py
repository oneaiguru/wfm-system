"""
Webhook Service

This service handles webhook deliveries and management:
- Webhook delivery with retry logic
- Signature verification
- Event dispatching
- Delivery tracking
"""

import asyncio
import hashlib
import hmac
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

import aiohttp
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db
from ..db.models import WebhookEndpoint, WebhookDelivery


logger = logging.getLogger(__name__)


class WebhookService:
    """Service for webhook operations"""
    
    def __init__(self):
        self.session = None
    
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    async def deliver_webhook(
        self,
        webhook: WebhookEndpoint,
        event_type: str,
        event_data: Dict[str, Any]
    ) -> None:
        """
        Deliver webhook with retry logic
        
        Args:
            webhook: Webhook endpoint configuration
            event_type: Type of event being delivered
            event_data: Event data payload
        """
        async with get_db() as db:
            # Create delivery record
            delivery = WebhookDelivery(
                webhook_id=webhook.id,
                event_type=event_type,
                event_data=event_data,
                delivery_status="pending"
            )
            db.add(delivery)
            await db.commit()
            await db.refresh(delivery)
            
            # Attempt delivery
            await self._attempt_delivery(webhook, delivery, db)
    
    async def retry_webhook_delivery(self, delivery: WebhookDelivery) -> None:
        """
        Retry a failed webhook delivery
        
        Args:
            delivery: Webhook delivery to retry
        """
        async with get_db() as db:
            # Get webhook endpoint
            webhook = await db.get(WebhookEndpoint, delivery.webhook_id)
            if not webhook:
                logger.error(f"Webhook {delivery.webhook_id} not found for retry")
                return
            
            # Reset delivery status
            delivery.delivery_status = "pending"
            delivery.retry_count += 1
            delivery.next_retry_at = None
            await db.commit()
            
            # Attempt delivery
            await self._attempt_delivery(webhook, delivery, db)
    
    async def _attempt_delivery(
        self,
        webhook: WebhookEndpoint,
        delivery: WebhookDelivery,
        db: AsyncSession
    ) -> None:
        """
        Attempt webhook delivery
        
        Args:
            webhook: Webhook endpoint configuration
            delivery: Webhook delivery record
            db: Database session
        """
        try:
            # Prepare payload
            payload = {
                "event_type": delivery.event_type,
                "event_data": delivery.event_data,
                "delivery_id": str(delivery.id),
                "webhook_id": str(webhook.id),
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Prepare headers
            headers = {
                "Content-Type": "application/json",
                "User-Agent": "WFM-Integration-Webhook/1.0"
            }
            
            # Add custom headers
            if webhook.headers:
                headers.update(webhook.headers)
            
            # Add authentication headers
            if webhook.auth_type == "bearer" and webhook.auth_credentials:
                token = webhook.auth_credentials.get("token")
                if token:
                    headers["Authorization"] = f"Bearer {token}"
            elif webhook.auth_type == "basic" and webhook.auth_credentials:
                import base64
                username = webhook.auth_credentials.get("username", "")
                password = webhook.auth_credentials.get("password", "")
                credentials = base64.b64encode(f"{username}:{password}".encode()).decode()
                headers["Authorization"] = f"Basic {credentials}"
            
            # Add signature if secret is provided
            if webhook.secret:
                signature = self._generate_signature(webhook.secret, payload)
                headers["X-Webhook-Signature"] = signature
                headers["X-Webhook-Signature-256"] = f"sha256={signature}"
            
            # Make request
            async with aiohttp.ClientSession() as session:
                async with session.request(
                    method=webhook.method,
                    url=webhook.url,
                    json=payload,
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=webhook.timeout_seconds)
                ) as response:
                    response_body = await response.text()
                    
                    # Update delivery record
                    delivery.delivered_at = datetime.utcnow()
                    delivery.http_status = response.status
                    delivery.response_body = response_body[:1000]  # Limit response size
                    
                    if 200 <= response.status < 300:
                        delivery.delivery_status = "delivered"
                        webhook.success_count += 1
                        webhook.last_triggered = datetime.utcnow()
                        logger.info(f"Webhook {webhook.id} delivered successfully")
                    else:
                        delivery.delivery_status = "failed"
                        delivery.error_message = f"HTTP {response.status}: {response_body[:500]}"
                        webhook.failure_count += 1
                        await self._schedule_retry(webhook, delivery)
                        logger.error(f"Webhook {webhook.id} delivery failed: {delivery.error_message}")
        
        except asyncio.TimeoutError:
            delivery.delivery_status = "failed"
            delivery.error_message = "Request timeout"
            webhook.failure_count += 1
            await self._schedule_retry(webhook, delivery)
            logger.error(f"Webhook {webhook.id} delivery timed out")
        
        except Exception as e:
            delivery.delivery_status = "failed"
            delivery.error_message = str(e)
            webhook.failure_count += 1
            await self._schedule_retry(webhook, delivery)
            logger.error(f"Webhook {webhook.id} delivery failed: {str(e)}")
        
        finally:
            await db.commit()
    
    async def _schedule_retry(self, webhook: WebhookEndpoint, delivery: WebhookDelivery) -> None:
        """
        Schedule retry for failed delivery
        
        Args:
            webhook: Webhook endpoint configuration
            delivery: Failed webhook delivery
        """
        if delivery.retry_count < webhook.retry_attempts:
            # Calculate next retry time with exponential backoff
            delay_seconds = webhook.retry_delay_seconds * (2 ** delivery.retry_count)
            delivery.next_retry_at = datetime.utcnow() + timedelta(seconds=delay_seconds)
            logger.info(f"Scheduled retry for webhook {webhook.id} in {delay_seconds} seconds")
        else:
            logger.info(f"Max retry attempts reached for webhook {webhook.id}")
    
    def _generate_signature(self, secret: str, payload: Dict[str, Any]) -> str:
        """
        Generate HMAC signature for webhook payload
        
        Args:
            secret: Webhook secret
            payload: Payload to sign
            
        Returns:
            HMAC signature
        """
        payload_bytes = json.dumps(payload, sort_keys=True).encode('utf-8')
        return hmac.new(
            secret.encode('utf-8'),
            payload_bytes,
            hashlib.sha256
        ).hexdigest()
    
    @staticmethod
    async def process_retry_queue() -> None:
        """
        Process webhook retry queue (background task)
        """
        async with get_db() as db:
            # Get pending retries
            from sqlalchemy import select, and_
            
            stmt = select(WebhookDelivery).where(
                and_(
                    WebhookDelivery.delivery_status == "failed",
                    WebhookDelivery.next_retry_at <= datetime.utcnow(),
                    WebhookDelivery.retry_count < WebhookDelivery.webhook.retry_attempts
                )
            ).limit(100)
            
            result = await db.execute(stmt)
            pending_retries = result.scalars().all()
            
            webhook_service = WebhookService()
            
            for delivery in pending_retries:
                try:
                    await webhook_service.retry_webhook_delivery(delivery)
                except Exception as e:
                    logger.error(f"Error retrying webhook delivery {delivery.id}: {str(e)}")
    
    @staticmethod
    async def emit_webhook_event(event_type: str, event_data: Dict[str, Any]) -> None:
        """
        Emit webhook event to all subscribed endpoints
        
        Args:
            event_type: Type of event to emit
            event_data: Event data payload
        """
        async with get_db() as db:
            # Get active webhooks subscribed to this event type
            from sqlalchemy import select, and_
            
            stmt = select(WebhookEndpoint).where(
                and_(
                    WebhookEndpoint.is_active == True,
                    WebhookEndpoint.event_types.contains([event_type])
                )
            )
            
            result = await db.execute(stmt)
            webhooks = result.scalars().all()
            
            webhook_service = WebhookService()
            
            # Deliver to all subscribed webhooks
            for webhook in webhooks:
                try:
                    await webhook_service.deliver_webhook(webhook, event_type, event_data)
                except Exception as e:
                    logger.error(f"Error delivering webhook {webhook.id}: {str(e)}")