"""
WebSocket Connection Management
High-performance connection handling with <100ms latency optimization
"""

import asyncio
import time
import logging
from typing import Dict, Set, Optional, Any, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass
from fastapi import WebSocket, WebSocketDisconnect
from collections import defaultdict

from .messages import WebSocketMessage, WebSocketEventType, PING_MESSAGE, PONG_MESSAGE
from .exceptions import (
    ConnectionClosedException, 
    InvalidMessageException, 
    RateLimitException
)

logger = logging.getLogger(__name__)


@dataclass
class ConnectionMetrics:
    """Connection performance metrics"""
    messages_sent: int = 0
    messages_received: int = 0
    bytes_sent: int = 0
    bytes_received: int = 0
    last_message_time: float = 0
    avg_message_latency: float = 0
    connection_duration: float = 0
    
    def update_send_metrics(self, bytes_count: int, latency: float):
        """Update send metrics"""
        self.messages_sent += 1
        self.bytes_sent += bytes_count
        self.last_message_time = time.time()
        # Rolling average for latency
        self.avg_message_latency = (
            (self.avg_message_latency * (self.messages_sent - 1) + latency) / self.messages_sent
        )
    
    def update_receive_metrics(self, bytes_count: int):
        """Update receive metrics"""
        self.messages_received += 1
        self.bytes_received += bytes_count
        self.last_message_time = time.time()


class RateLimiter:
    """Token bucket rate limiter for WebSocket connections"""
    
    def __init__(self, max_tokens: int = 100, refill_rate: float = 10.0):
        self.max_tokens = max_tokens
        self.refill_rate = refill_rate
        self.tokens = max_tokens
        self.last_refill = time.time()
        self._lock = asyncio.Lock()
    
    async def acquire(self, tokens: int = 1) -> bool:
        """Acquire tokens from bucket"""
        async with self._lock:
            now = time.time()
            elapsed = now - self.last_refill
            
            # Refill tokens
            self.tokens = min(
                self.max_tokens,
                self.tokens + elapsed * self.refill_rate
            )
            self.last_refill = now
            
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            return False


class WebSocketConnection:
    """
    High-performance WebSocket connection wrapper
    Optimized for <100ms message handling
    """
    
    def __init__(
        self,
        websocket: WebSocket,
        connection_id: str,
        user_id: Optional[str] = None,
        rate_limit: Optional[RateLimiter] = None
    ):
        self.websocket = websocket
        self.connection_id = connection_id
        self.user_id = user_id
        self.connected_at = datetime.utcnow()
        self.last_ping = datetime.utcnow()
        self.last_pong = datetime.utcnow()
        
        # Subscriptions and rooms
        self.subscriptions: Set[str] = set()
        self.rooms: Set[str] = set()
        self.event_filters: Dict[str, Any] = {}
        
        # Performance optimization
        self.metrics = ConnectionMetrics()
        self.rate_limiter = rate_limit or RateLimiter()
        self._send_lock = asyncio.Lock()
        self._is_closed = False
        
        # Message queues for batching
        self._message_queue: asyncio.Queue = asyncio.Queue(maxsize=1000)
        self._batch_send_task: Optional[asyncio.Task] = None
        self._batch_size = 10
        self._batch_timeout = 0.01  # 10ms batch timeout for <100ms total latency
        
        # Connection state
        self._authenticated = False
        self._permissions: Set[str] = set()
        
        logger.info(f"WebSocket connection created: {connection_id}")
    
    @property
    def is_connected(self) -> bool:
        """Check if connection is active"""
        return not self._is_closed and self.websocket.client_state.name == "CONNECTED"
    
    @property
    def is_authenticated(self) -> bool:
        """Check if connection is authenticated"""
        return self._authenticated
    
    @property
    def connection_age(self) -> timedelta:
        """Get connection age"""
        return datetime.utcnow() - self.connected_at
    
    async def send_message(self, message: WebSocketMessage, batch: bool = False) -> bool:
        """
        Send message with performance optimization
        Uses batching for high-frequency messages
        """
        if self._is_closed:
            raise ConnectionClosedException(self.connection_id)
        
        # Rate limiting
        if not await self.rate_limiter.acquire():
            raise RateLimitException("Message rate limit exceeded")
        
        try:
            if batch:
                # Queue message for batch sending
                await self._message_queue.put(message)
                if not self._batch_send_task:
                    self._batch_send_task = asyncio.create_task(self._batch_send_loop())
                return True
            else:
                # Send immediately
                return await self._send_single_message(message)
                
        except Exception as e:
            logger.error(f"Failed to send message to {self.connection_id}: {e}")
            await self._handle_send_error(e)
            return False
    
    async def _send_single_message(self, message: WebSocketMessage) -> bool:
        """Send single message with latency tracking"""
        start_time = time.time()
        
        try:
            # Use binary websocket for better performance
            message_bytes = message.to_bytes()
            
            async with self._send_lock:
                await self.websocket.send_bytes(message_bytes)
            
            # Update metrics
            latency = (time.time() - start_time) * 1000  # Convert to ms
            self.metrics.update_send_metrics(len(message_bytes), latency)
            
            # Log slow messages
            if latency > 50:  # 50ms warning threshold
                logger.warning(f"Slow message send: {latency:.2f}ms to {self.connection_id}")
            
            return True
            
        except WebSocketDisconnect:
            await self._close_connection()
            return False
        except Exception as e:
            logger.error(f"Send error to {self.connection_id}: {e}")
            await self._handle_send_error(e)
            return False
    
    async def _batch_send_loop(self):
        """Batch message sending loop for high-frequency updates"""
        try:
            while self.is_connected:
                messages = []
                
                # Wait for first message with timeout
                try:
                    first_message = await asyncio.wait_for(
                        self._message_queue.get(), 
                        timeout=self._batch_timeout
                    )
                    messages.append(first_message)
                except asyncio.TimeoutError:
                    continue
                
                # Collect additional messages up to batch size
                while len(messages) < self._batch_size and not self._message_queue.empty():
                    try:
                        message = self._message_queue.get_nowait()
                        messages.append(message)
                    except asyncio.QueueEmpty:
                        break
                
                # Send batch
                if messages:
                    await self._send_message_batch(messages)
                    
        except Exception as e:
            logger.error(f"Batch send loop error for {self.connection_id}: {e}")
        finally:
            self._batch_send_task = None
    
    async def _send_message_batch(self, messages: list[WebSocketMessage]):
        """Send batch of messages efficiently"""
        start_time = time.time()
        
        try:
            # Create batch message
            batch_payload = {
                "messages": [msg.dict() for msg in messages],
                "batch_size": len(messages),
                "timestamp": datetime.utcnow().isoformat()
            }
            
            batch_message = WebSocketMessage(
                type="batch",
                payload=batch_payload
            )
            
            # Send batch
            await self._send_single_message(batch_message)
            
            # Update metrics for all messages in batch
            batch_latency = (time.time() - start_time) * 1000
            for _ in messages:
                self.metrics.update_send_metrics(0, batch_latency / len(messages))
                
        except Exception as e:
            logger.error(f"Batch send error to {self.connection_id}: {e}")
            # Fall back to individual sends
            for message in messages:
                await self._send_single_message(message)
    
    async def receive_message(self) -> Optional[WebSocketMessage]:
        """Receive and parse WebSocket message"""
        try:
            # Use binary receive for better performance
            data = await self.websocket.receive_bytes()
            
            # Update metrics
            self.metrics.update_receive_metrics(len(data))
            
            # Parse message
            message = WebSocketMessage.from_bytes(data)
            
            # Handle system messages
            if message.type == WebSocketEventType.PING.value:
                await self.send_pong()
                return None
            elif message.type == WebSocketEventType.PONG.value:
                self.last_pong = datetime.utcnow()
                return None
            
            return message
            
        except WebSocketDisconnect:
            await self._close_connection()
            return None
        except Exception as e:
            logger.error(f"Receive error from {self.connection_id}: {e}")
            raise InvalidMessageException(str(e))
    
    async def send_ping(self) -> bool:
        """Send ping message"""
        self.last_ping = datetime.utcnow()
        return await self.send_message(PING_MESSAGE)
    
    async def send_pong(self) -> bool:
        """Send pong message"""
        return await self.send_message(PONG_MESSAGE)
    
    async def subscribe(self, event_type: str, filters: Optional[Dict[str, Any]] = None):
        """Subscribe to event type"""
        self.subscriptions.add(event_type)
        if filters:
            self.event_filters[event_type] = filters
        logger.debug(f"Client {self.connection_id} subscribed to {event_type}")
    
    async def unsubscribe(self, event_type: str):
        """Unsubscribe from event type"""
        self.subscriptions.discard(event_type)
        self.event_filters.pop(event_type, None)
        logger.debug(f"Client {self.connection_id} unsubscribed from {event_type}")
    
    async def join_room(self, room: str):
        """Join room"""
        self.rooms.add(room)
        logger.debug(f"Client {self.connection_id} joined room {room}")
    
    async def leave_room(self, room: str):
        """Leave room"""
        self.rooms.discard(room)
        logger.debug(f"Client {self.connection_id} left room {room}")
    
    def authenticate(self, user_id: str, permissions: Set[str]):
        """Authenticate connection"""
        self.user_id = user_id
        self._authenticated = True
        self._permissions = permissions
        logger.info(f"Connection {self.connection_id} authenticated for user {user_id}")
    
    def has_permission(self, permission: str) -> bool:
        """Check if connection has permission"""
        return permission in self._permissions
    
    def matches_filter(self, event_type: str, payload: Dict[str, Any]) -> bool:
        """Check if message matches event filters"""
        if event_type not in self.event_filters:
            return True
        
        filters = self.event_filters[event_type]
        
        # Simple filter matching - can be extended
        for key, value in filters.items():
            if key in payload and payload[key] != value:
                return False
        
        return True
    
    async def close(self, code: int = 1000, reason: str = ""):
        """Close connection gracefully"""
        if not self._is_closed:
            try:
                await self.websocket.close(code=code, reason=reason)
            except Exception as e:
                logger.error(f"Error closing connection {self.connection_id}: {e}")
            finally:
                await self._close_connection()
    
    async def _close_connection(self):
        """Internal connection cleanup"""
        if self._is_closed:
            return
        
        self._is_closed = True
        
        # Cancel batch send task
        if self._batch_send_task:
            self._batch_send_task.cancel()
            self._batch_send_task = None
        
        # Clear queues
        while not self._message_queue.empty():
            try:
                self._message_queue.get_nowait()
            except asyncio.QueueEmpty:
                break
        
        # Update metrics
        self.metrics.connection_duration = (
            datetime.utcnow() - self.connected_at
        ).total_seconds()
        
        logger.info(f"Connection {self.connection_id} closed after {self.metrics.connection_duration:.2f}s")
    
    async def _handle_send_error(self, error: Exception):
        """Handle send errors"""
        if isinstance(error, (ConnectionResetError, BrokenPipeError)):
            await self._close_connection()
        else:
            logger.error(f"Send error to {self.connection_id}: {error}")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get connection statistics"""
        return {
            "connection_id": self.connection_id,
            "user_id": self.user_id,
            "connected_at": self.connected_at.isoformat(),
            "connection_age_seconds": self.connection_age.total_seconds(),
            "is_connected": self.is_connected,
            "is_authenticated": self.is_authenticated,
            "subscriptions": list(self.subscriptions),
            "rooms": list(self.rooms),
            "metrics": {
                "messages_sent": self.metrics.messages_sent,
                "messages_received": self.metrics.messages_received,
                "bytes_sent": self.metrics.bytes_sent,
                "bytes_received": self.metrics.bytes_received,
                "avg_message_latency_ms": self.metrics.avg_message_latency,
                "connection_duration_seconds": self.metrics.connection_duration
            }
        }