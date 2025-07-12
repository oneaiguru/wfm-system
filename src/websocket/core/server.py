"""
WebSocket Server Core Implementation
High-performance WebSocket server with <100ms latency optimization
"""

import asyncio
import logging
import time
import uuid
from typing import Dict, Set, Optional, Any, Callable, List
from datetime import datetime, timedelta
from collections import defaultdict
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends
from fastapi.routing import APIRouter
import uvloop

from .connection import WebSocketConnection, RateLimiter
from .messages import (
    WebSocketMessage, 
    WebSocketEventType,
    create_error_message,
    create_event_message,
    CONNECTION_ESTABLISHED_MESSAGE
)
from .exceptions import (
    WebSocketException,
    ConnectionLimitException,
    ServerOverloadException,
    AuthenticationException
)
from ..events.dispatcher import EventDispatcher

logger = logging.getLogger(__name__)


class ConnectionPool:
    """High-performance connection pool with automatic cleanup"""
    
    def __init__(self, max_connections: int = 10000):
        self.max_connections = max_connections
        self.connections: Dict[str, WebSocketConnection] = {}
        self.user_connections: Dict[str, Set[str]] = defaultdict(set)
        self.room_connections: Dict[str, Set[str]] = defaultdict(set)
        self.subscription_connections: Dict[str, Set[str]] = defaultdict(set)
        self._lock = asyncio.Lock()
        
        # Performance monitoring
        self.total_connections_created = 0
        self.total_connections_closed = 0
        self.peak_connections = 0
        
    @property
    def active_connections(self) -> int:
        """Get number of active connections"""
        return len(self.connections)
    
    async def add_connection(self, connection: WebSocketConnection) -> bool:
        """Add connection to pool"""
        async with self._lock:
            if len(self.connections) >= self.max_connections:
                raise ConnectionLimitException(
                    f"Maximum connections ({self.max_connections}) exceeded"
                )
            
            self.connections[connection.connection_id] = connection
            self.total_connections_created += 1
            
            # Track by user
            if connection.user_id:
                self.user_connections[connection.user_id].add(connection.connection_id)
            
            # Update peak connections
            self.peak_connections = max(self.peak_connections, len(self.connections))
            
            logger.info(f"Added connection {connection.connection_id} (total: {len(self.connections)})")
            return True
    
    async def remove_connection(self, connection_id: str) -> bool:
        """Remove connection from pool"""
        async with self._lock:
            if connection_id not in self.connections:
                return False
            
            connection = self.connections[connection_id]
            
            # Remove from user tracking
            if connection.user_id:
                self.user_connections[connection.user_id].discard(connection_id)
                if not self.user_connections[connection.user_id]:
                    del self.user_connections[connection.user_id]
            
            # Remove from room tracking
            for room in connection.rooms:
                self.room_connections[room].discard(connection_id)
                if not self.room_connections[room]:
                    del self.room_connections[room]
            
            # Remove from subscription tracking
            for event_type in connection.subscriptions:
                self.subscription_connections[event_type].discard(connection_id)
                if not self.subscription_connections[event_type]:
                    del self.subscription_connections[event_type]
            
            # Remove connection
            del self.connections[connection_id]
            self.total_connections_closed += 1
            
            logger.info(f"Removed connection {connection_id} (total: {len(self.connections)})")
            return True
    
    async def get_connection(self, connection_id: str) -> Optional[WebSocketConnection]:
        """Get connection by ID"""
        return self.connections.get(connection_id)
    
    async def get_user_connections(self, user_id: str) -> List[WebSocketConnection]:
        """Get all connections for a user"""
        connection_ids = self.user_connections.get(user_id, set())
        return [self.connections[cid] for cid in connection_ids if cid in self.connections]
    
    async def get_room_connections(self, room: str) -> List[WebSocketConnection]:
        """Get all connections in a room"""
        connection_ids = self.room_connections.get(room, set())
        return [self.connections[cid] for cid in connection_ids if cid in self.connections]
    
    async def get_subscription_connections(self, event_type: str) -> List[WebSocketConnection]:
        """Get all connections subscribed to event type"""
        connection_ids = self.subscription_connections.get(event_type, set())
        return [self.connections[cid] for cid in connection_ids if cid in self.connections]
    
    async def add_to_room(self, connection_id: str, room: str):
        """Add connection to room"""
        if connection_id in self.connections:
            self.room_connections[room].add(connection_id)
            await self.connections[connection_id].join_room(room)
    
    async def remove_from_room(self, connection_id: str, room: str):
        """Remove connection from room"""
        if connection_id in self.connections:
            self.room_connections[room].discard(connection_id)
            await self.connections[connection_id].leave_room(room)
            
            # Clean up empty rooms
            if not self.room_connections[room]:
                del self.room_connections[room]
    
    async def add_subscription(self, connection_id: str, event_type: str):
        """Add event subscription"""
        if connection_id in self.connections:
            self.subscription_connections[event_type].add(connection_id)
            await self.connections[connection_id].subscribe(event_type)
    
    async def remove_subscription(self, connection_id: str, event_type: str):
        """Remove event subscription"""
        if connection_id in self.connections:
            self.subscription_connections[event_type].discard(connection_id)
            await self.connections[connection_id].unsubscribe(event_type)
            
            # Clean up empty subscriptions
            if not self.subscription_connections[event_type]:
                del self.subscription_connections[event_type]
    
    async def cleanup_stale_connections(self, max_age: timedelta = timedelta(hours=24)):
        """Clean up stale connections"""
        now = datetime.utcnow()
        stale_connections = []
        
        for connection_id, connection in self.connections.items():
            if not connection.is_connected or now - connection.connected_at > max_age:
                stale_connections.append(connection_id)
        
        for connection_id in stale_connections:
            connection = self.connections.get(connection_id)
            if connection:
                await connection.close(code=1001, reason="Stale connection cleanup")
                await self.remove_connection(connection_id)
        
        if stale_connections:
            logger.info(f"Cleaned up {len(stale_connections)} stale connections")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get pool statistics"""
        return {
            "active_connections": len(self.connections),
            "peak_connections": self.peak_connections,
            "total_created": self.total_connections_created,
            "total_closed": self.total_connections_closed,
            "active_rooms": len(self.room_connections),
            "active_subscriptions": len(self.subscription_connections),
            "users_connected": len(self.user_connections)
        }


class WebSocketServer:
    """
    High-performance WebSocket server
    Optimized for <100ms latency and 10,000+ concurrent connections
    """
    
    def __init__(
        self,
        max_connections: int = 10000,
        heartbeat_interval: float = 30.0,
        cleanup_interval: float = 300.0,
        enable_performance_monitoring: bool = True
    ):
        self.max_connections = max_connections
        self.heartbeat_interval = heartbeat_interval
        self.cleanup_interval = cleanup_interval
        self.enable_performance_monitoring = enable_performance_monitoring
        
        # Core components
        self.connection_pool = ConnectionPool(max_connections)
        self.event_dispatcher = EventDispatcher()
        
        # Background tasks
        self.heartbeat_task: Optional[asyncio.Task] = None
        self.cleanup_task: Optional[asyncio.Task] = None
        self.monitoring_task: Optional[asyncio.Task] = None
        
        # Performance metrics
        self.start_time = time.time()
        self.total_messages_processed = 0
        self.total_events_dispatched = 0
        self.avg_message_latency = 0
        
        # Event handlers
        self.message_handlers: Dict[str, Callable] = {}
        self.connection_handlers: List[Callable] = []
        self.disconnection_handlers: List[Callable] = []
        
        # Router for FastAPI integration
        self.router = APIRouter()
        self._setup_routes()
        
        logger.info(f"WebSocket server initialized (max_connections: {max_connections})")
    
    def _setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.router.websocket("/ws")
        async def websocket_endpoint(
            websocket: WebSocket,
            client_id: Optional[str] = None,
            user_id: Optional[str] = None,
            token: Optional[str] = None
        ):
            await self.handle_websocket_connection(websocket, client_id, user_id, token)
        
        @self.router.get("/ws/health")
        async def health_check():
            return await self.get_health_status()
        
        @self.router.get("/ws/stats")
        async def get_stats():
            return await self.get_server_stats()
        
        @self.router.post("/ws/broadcast")
        async def broadcast_message(message: dict):
            return await self.broadcast_message(message)
    
    async def start(self):
        """Start server background tasks"""
        # Use uvloop for better performance
        if hasattr(asyncio, 'set_event_loop_policy'):
            asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
        
        # Start background tasks
        self.heartbeat_task = asyncio.create_task(self._heartbeat_loop())
        self.cleanup_task = asyncio.create_task(self._cleanup_loop())
        
        if self.enable_performance_monitoring:
            self.monitoring_task = asyncio.create_task(self._monitoring_loop())
        
        logger.info("WebSocket server started")
    
    async def stop(self):
        """Stop server and cleanup"""
        tasks = [self.heartbeat_task, self.cleanup_task, self.monitoring_task]
        
        for task in tasks:
            if task and not task.done():
                task.cancel()
        
        # Close all connections
        for connection in list(self.connection_pool.connections.values()):
            await connection.close(code=1001, reason="Server shutdown")
        
        # Wait for tasks to complete
        await asyncio.gather(*[task for task in tasks if task], return_exceptions=True)
        
        logger.info("WebSocket server stopped")
    
    async def handle_websocket_connection(
        self,
        websocket: WebSocket,
        client_id: Optional[str] = None,
        user_id: Optional[str] = None,
        token: Optional[str] = None
    ):
        """Handle incoming WebSocket connection"""
        connection_id = client_id or str(uuid.uuid4())
        
        try:
            # Accept connection
            await websocket.accept()
            
            # Create connection with rate limiting
            rate_limiter = RateLimiter(max_tokens=100, refill_rate=10.0)
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=connection_id,
                user_id=user_id,
                rate_limit=rate_limiter
            )
            
            # Add to pool
            await self.connection_pool.add_connection(connection)
            
            # TODO: Implement authentication
            if token:
                await self._authenticate_connection(connection, token)
            
            # Send connection established message
            await connection.send_message(CONNECTION_ESTABLISHED_MESSAGE)
            
            # Notify connection handlers
            for handler in self.connection_handlers:
                try:
                    await handler(connection)
                except Exception as e:
                    logger.error(f"Connection handler error: {e}")
            
            # Message handling loop
            await self._handle_connection_messages(connection)
            
        except WebSocketDisconnect:
            logger.info(f"Client {connection_id} disconnected")
        except Exception as e:
            logger.error(f"WebSocket connection error for {connection_id}: {e}")
        finally:
            # Cleanup
            await self.connection_pool.remove_connection(connection_id)
            
            # Notify disconnection handlers
            for handler in self.disconnection_handlers:
                try:
                    await handler(connection_id)
                except Exception as e:
                    logger.error(f"Disconnection handler error: {e}")
    
    async def _handle_connection_messages(self, connection: WebSocketConnection):
        """Handle messages from a connection"""
        try:
            while connection.is_connected:
                message = await connection.receive_message()
                
                if message:
                    await self._process_message(connection, message)
                    
        except WebSocketDisconnect:
            logger.info(f"Connection {connection.connection_id} disconnected")
        except Exception as e:
            logger.error(f"Message handling error for {connection.connection_id}: {e}")
            await connection.close(code=1011, reason="Internal server error")
    
    async def _process_message(self, connection: WebSocketConnection, message: WebSocketMessage):
        """Process incoming message"""
        start_time = time.time()
        
        try:
            message_type = message.type
            
            # Handle built-in message types
            if message_type == "subscribe":
                await self._handle_subscribe(connection, message)
            elif message_type == "unsubscribe":
                await self._handle_unsubscribe(connection, message)
            elif message_type == "join_room":
                await self._handle_join_room(connection, message)
            elif message_type == "leave_room":
                await self._handle_leave_room(connection, message)
            elif message_type in self.message_handlers:
                # Custom message handler
                await self.message_handlers[message_type](connection, message)
            else:
                logger.warning(f"Unknown message type: {message_type} from {connection.connection_id}")
            
            # Update metrics
            self.total_messages_processed += 1
            processing_time = (time.time() - start_time) * 1000  # Convert to ms
            
            # Update average latency
            self.avg_message_latency = (
                (self.avg_message_latency * (self.total_messages_processed - 1) + processing_time)
                / self.total_messages_processed
            )
            
            # Log slow message processing
            if processing_time > 50:  # 50ms threshold
                logger.warning(f"Slow message processing: {processing_time:.2f}ms for {message_type}")
                
        except Exception as e:
            logger.error(f"Message processing error: {e}")
            error_msg = create_error_message("MESSAGE_PROCESSING_ERROR", str(e))
            await connection.send_message(error_msg)
    
    async def _handle_subscribe(self, connection: WebSocketConnection, message: WebSocketMessage):
        """Handle subscription request"""
        event_types = message.payload.get("event_types", [])
        
        for event_type in event_types:
            await self.connection_pool.add_subscription(connection.connection_id, event_type)
        
        # Send confirmation
        response = WebSocketMessage(
            type=WebSocketEventType.SUBSCRIPTION_CONFIRMED.value,
            payload={"subscribed_events": event_types}
        )
        await connection.send_message(response)
    
    async def _handle_unsubscribe(self, connection: WebSocketConnection, message: WebSocketMessage):
        """Handle unsubscription request"""
        event_types = message.payload.get("event_types", [])
        
        for event_type in event_types:
            await self.connection_pool.remove_subscription(connection.connection_id, event_type)
        
        # Send confirmation
        response = WebSocketMessage(
            type=WebSocketEventType.UNSUBSCRIPTION_CONFIRMED.value,
            payload={"unsubscribed_events": event_types}
        )
        await connection.send_message(response)
    
    async def _handle_join_room(self, connection: WebSocketConnection, message: WebSocketMessage):
        """Handle room join request"""
        rooms = message.payload.get("rooms", [])
        
        for room in rooms:
            await self.connection_pool.add_to_room(connection.connection_id, room)
        
        # Send confirmation
        response = WebSocketMessage(
            type=WebSocketEventType.ROOM_JOINED.value,
            payload={"joined_rooms": rooms}
        )
        await connection.send_message(response)
    
    async def _handle_leave_room(self, connection: WebSocketConnection, message: WebSocketMessage):
        """Handle room leave request"""
        rooms = message.payload.get("rooms", [])
        
        for room in rooms:
            await self.connection_pool.remove_from_room(connection.connection_id, room)
        
        # Send confirmation
        response = WebSocketMessage(
            type=WebSocketEventType.ROOM_LEFT.value,
            payload={"left_rooms": rooms}
        )
        await connection.send_message(response)
    
    async def _authenticate_connection(self, connection: WebSocketConnection, token: str):
        """Authenticate connection with token"""
        # TODO: Implement JWT token validation
        # For now, accept all connections
        pass
    
    async def broadcast_message(self, message: WebSocketMessage, room: Optional[str] = None) -> int:
        """Broadcast message to connections"""
        if room:
            connections = await self.connection_pool.get_room_connections(room)
        else:
            connections = list(self.connection_pool.connections.values())
        
        sent_count = 0
        failed_connections = []
        
        # Use batched sending for better performance
        send_tasks = []
        for connection in connections:
            if connection.is_connected:
                task = asyncio.create_task(connection.send_message(message, batch=True))
                send_tasks.append((connection.connection_id, task))
        
        # Wait for all sends to complete
        results = await asyncio.gather(*[task for _, task in send_tasks], return_exceptions=True)
        
        for i, result in enumerate(results):
            connection_id, _ = send_tasks[i]
            if isinstance(result, Exception):
                logger.error(f"Broadcast failed to {connection_id}: {result}")
                failed_connections.append(connection_id)
            elif result:
                sent_count += 1
        
        # Clean up failed connections
        for connection_id in failed_connections:
            await self.connection_pool.remove_connection(connection_id)
        
        self.total_events_dispatched += 1
        return sent_count
    
    async def emit_event(self, event_type: WebSocketEventType, payload: Dict[str, Any], room: Optional[str] = None) -> int:
        """Emit event to subscribers"""
        message = create_event_message(event_type, payload)
        
        if room:
            connections = await self.connection_pool.get_room_connections(room)
        else:
            connections = await self.connection_pool.get_subscription_connections(event_type.value)
        
        sent_count = 0
        
        # Filter connections and send
        for connection in connections:
            if connection.is_connected and connection.matches_filter(event_type.value, payload):
                success = await connection.send_message(message, batch=True)
                if success:
                    sent_count += 1
        
        return sent_count
    
    async def _heartbeat_loop(self):
        """Background heartbeat task"""
        while True:
            try:
                await asyncio.sleep(self.heartbeat_interval)
                
                # Send ping to all connections
                failed_connections = []
                for connection in list(self.connection_pool.connections.values()):
                    if connection.is_connected:
                        success = await connection.send_ping()
                        if not success:
                            failed_connections.append(connection.connection_id)
                
                # Clean up failed connections
                for connection_id in failed_connections:
                    await self.connection_pool.remove_connection(connection_id)
                
                logger.debug(f"Heartbeat sent to {len(self.connection_pool.connections)} connections")
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Heartbeat error: {e}")
    
    async def _cleanup_loop(self):
        """Background cleanup task"""
        while True:
            try:
                await asyncio.sleep(self.cleanup_interval)
                await self.connection_pool.cleanup_stale_connections()
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Cleanup error: {e}")
    
    async def _monitoring_loop(self):
        """Background monitoring task"""
        while True:
            try:
                await asyncio.sleep(60)  # Monitor every minute
                
                stats = await self.get_server_stats()
                
                # Log performance metrics
                if self.avg_message_latency > 100:  # 100ms threshold
                    logger.warning(f"High message latency: {self.avg_message_latency:.2f}ms")
                
                if stats["active_connections"] > self.max_connections * 0.8:
                    logger.warning(f"High connection count: {stats['active_connections']}")
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Monitoring error: {e}")
    
    def register_message_handler(self, message_type: str, handler: Callable):
        """Register custom message handler"""
        self.message_handlers[message_type] = handler
    
    def register_connection_handler(self, handler: Callable):
        """Register connection handler"""
        self.connection_handlers.append(handler)
    
    def register_disconnection_handler(self, handler: Callable):
        """Register disconnection handler"""
        self.disconnection_handlers.append(handler)
    
    async def get_health_status(self) -> Dict[str, Any]:
        """Get server health status"""
        uptime = time.time() - self.start_time
        
        return {
            "status": "healthy",
            "uptime_seconds": uptime,
            "active_connections": self.connection_pool.active_connections,
            "avg_message_latency_ms": self.avg_message_latency,
            "total_messages_processed": self.total_messages_processed,
            "total_events_dispatched": self.total_events_dispatched
        }
    
    async def get_server_stats(self) -> Dict[str, Any]:
        """Get comprehensive server statistics"""
        pool_stats = self.connection_pool.get_stats()
        health_stats = await self.get_health_status()
        
        return {
            **health_stats,
            **pool_stats,
            "max_connections": self.max_connections,
            "heartbeat_interval": self.heartbeat_interval,
            "cleanup_interval": self.cleanup_interval
        }


# Global server instance
ws_server = WebSocketServer()

# FastAPI router for integration
websocket_router = ws_server.router