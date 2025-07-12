"""
WebSocket Service for WFM Multi-Agent System
Centralized WebSocket connection management and event broadcasting
"""

import asyncio
import json
import logging
from typing import Dict, List, Set, Optional, Any, Callable
from datetime import datetime
from enum import Enum
from fastapi import WebSocket, WebSocketDisconnect
from pydantic import BaseModel
import uuid

logger = logging.getLogger(__name__)

# Import event handlers
from ..websocket.handlers import event_registry
from ..websocket.handlers.base import EventPayload

class WebSocketEventType(str, Enum):
    """WebSocket event types matching the TypeScript stub"""
    # Forecasting events
    FORECAST_UPDATED = "forecast.updated"
    FORECAST_CALCULATED = "forecast.calculated"
    FORECAST_ERROR = "forecast.error"
    
    # Schedule events
    SCHEDULE_CHANGED = "schedule.changed"
    SCHEDULE_OPTIMIZED = "schedule.optimized"
    SHIFT_ASSIGNED = "shift.assigned"
    SHIFT_SWAPPED = "shift.swapped"
    
    # Enhanced schedule events
    SCHEDULE_CREATED = "schedule.created"
    SCHEDULE_UPDATED = "schedule.updated"
    SCHEDULE_DELETED = "schedule.deleted"
    SCHEDULE_PUBLISHED = "schedule.published"
    SCHEDULE_GENERATION_STARTED = "schedule.generation_started"
    SCHEDULE_GENERATION_PROGRESS = "schedule.generation_progress"
    SCHEDULE_GENERATION_COMPLETED = "schedule.generation_completed"
    SCHEDULE_GENERATION_FAILED = "schedule.generation_failed"
    SCHEDULE_OPTIMIZATION_STARTED = "schedule.optimization_started"
    SCHEDULE_OPTIMIZATION_PROGRESS = "schedule.optimization_progress"
    SCHEDULE_OPTIMIZATION_COMPLETED = "schedule.optimization_completed"
    SCHEDULE_OPTIMIZATION_FAILED = "schedule.optimization_failed"
    SCHEDULE_CONFLICT_DETECTED = "schedule.conflict_detected"
    SCHEDULE_CONFLICT_RESOLVED = "schedule.conflict_resolved"
    SCHEDULE_CONFLICT_ACKNOWLEDGED = "schedule.conflict_acknowledged"
    SCHEDULE_CONFLICTS_DETECTED = "schedule.conflicts_detected"
    SCHEDULE_CONFLICTS_BATCH_RESOLVED = "schedule.conflicts_batch_resolved"
    SCHEDULE_VARIANT_CREATED = "schedule.variant_created"
    SCHEDULE_VARIANT_UPDATED = "schedule.variant_updated"
    SCHEDULE_VARIANT_DELETED = "schedule.variant_deleted"
    SCHEDULE_VARIANT_APPROVED = "schedule.variant_approved"
    SCHEDULE_VARIANT_APPLIED = "schedule.variant_applied"
    SCHEDULE_VARIANT_APPLY_STARTED = "schedule.variant_apply_started"
    SCHEDULE_PUBLICATION_CREATED = "schedule.publication_created"
    SCHEDULE_NOTIFICATIONS_SENT = "schedule.notifications_sent"
    SCHEDULE_ACKNOWLEDGED = "schedule.acknowledged"
    SCHEDULE_BULK_UPDATE_COMPLETED = "schedule.bulk_update_completed"
    SCHEDULE_COPIED = "schedule.copied"
    SCHEDULE_MERGED = "schedule.merged"
    SCHEDULE_TEMPLATE_CREATED = "schedule.template_created"
    SCHEDULE_RECOMMENDATIONS_APPLIED = "schedule.recommendations_applied"
    
    # Shift events
    SHIFT_CREATED = "shift.created"
    SHIFT_UPDATED = "shift.updated"
    SHIFT_DELETED = "shift.deleted"
    SHIFT_TEMPLATES_CREATED = "shift.templates_created"
    
    # Schedule rule events
    SCHEDULE_RULE_CREATED = "schedule.rule_created"
    SCHEDULE_RULE_UPDATED = "schedule.rule_updated"
    SCHEDULE_RULE_DELETED = "schedule.rule_deleted"
    
    # Real-time monitoring
    AGENT_STATUS_CHANGED = "agent.status.changed"
    QUEUE_METRICS_UPDATE = "queue.metrics.update"
    SLA_ALERT = "sla.alert"
    
    # Skill management
    SKILL_ASSIGNED = "skill.assigned"
    SKILL_REMOVED = "skill.removed"
    SKILL_LEVEL_CHANGED = "skill.level.changed"
    
    # Vacancy events
    VACANCY_CREATED = "vacancy.created"
    VACANCY_FILLED = "vacancy.filled"
    STAFFING_GAP_DETECTED = "staffing.gap.detected"
    
    # Algorithm calculation events
    ERLANG_CALCULATION_COMPLETE = "erlang.calculation.complete"
    OPTIMIZATION_COMPLETE = "optimization.complete"
    ACCURACY_METRICS_READY = "accuracy.metrics.ready"

class WebSocketMessage(BaseModel):
    """WebSocket message structure"""
    type: str
    payload: Any
    timestamp: float
    client_id: Optional[str] = None
    room: Optional[str] = None

class WebSocketConnection:
    """WebSocket connection wrapper with metadata"""
    def __init__(self, websocket: WebSocket, client_id: str, user_id: Optional[str] = None):
        self.websocket = websocket
        self.client_id = client_id
        self.user_id = user_id
        self.connected_at = datetime.now()
        self.last_ping = datetime.now()
        self.subscriptions: Set[str] = set()
        self.rooms: Set[str] = set()

    async def send_message(self, message: WebSocketMessage):
        """Send message to this connection"""
        try:
            await self.websocket.send_text(message.json())
            return True
        except Exception as e:
            logger.error(f"Failed to send message to {self.client_id}: {e}")
            return False

    async def ping(self):
        """Send ping to keep connection alive"""
        try:
            await self.websocket.send_text(json.dumps({
                "type": "ping",
                "timestamp": datetime.now().timestamp()
            }))
            self.last_ping = datetime.now()
            return True
        except Exception as e:
            logger.error(f"Failed to ping {self.client_id}: {e}")
            return False

class WebSocketManager:
    """Centralized WebSocket connection manager"""
    
    def __init__(self):
        self.connections: Dict[str, WebSocketConnection] = {}
        self.rooms: Dict[str, Set[str]] = {}
        self.event_handlers: Dict[str, List[Callable]] = {}
        self.heartbeat_task: Optional[asyncio.Task] = None
        self.heartbeat_interval = 30  # seconds
        
    async def connect(self, websocket: WebSocket, client_id: str = None, user_id: str = None) -> str:
        """Accept WebSocket connection and register client"""
        await websocket.accept()
        
        if not client_id:
            client_id = str(uuid.uuid4())
            
        connection = WebSocketConnection(websocket, client_id, user_id)
        self.connections[client_id] = connection
        
        logger.info(f"WebSocket connected: {client_id} (user: {user_id})")
        
        # Start heartbeat task if first connection
        if len(self.connections) == 1 and not self.heartbeat_task:
            self.heartbeat_task = asyncio.create_task(self._heartbeat_loop())
            
        return client_id
        
    async def disconnect(self, client_id: str):
        """Disconnect and cleanup client"""
        if client_id in self.connections:
            connection = self.connections[client_id]
            
            # Remove from all rooms
            for room in connection.rooms.copy():
                await self.leave_room(client_id, room)
                
            # Remove connection
            del self.connections[client_id]
            logger.info(f"WebSocket disconnected: {client_id}")
            
            # Stop heartbeat if no connections
            if not self.connections and self.heartbeat_task:
                self.heartbeat_task.cancel()
                self.heartbeat_task = None
                
    async def join_room(self, client_id: str, room: str):
        """Add client to a room for group messaging"""
        if client_id in self.connections:
            if room not in self.rooms:
                self.rooms[room] = set()
            self.rooms[room].add(client_id)
            self.connections[client_id].rooms.add(room)
            logger.debug(f"Client {client_id} joined room {room}")
            
    async def leave_room(self, client_id: str, room: str):
        """Remove client from a room"""
        if room in self.rooms:
            self.rooms[room].discard(client_id)
            if not self.rooms[room]:
                del self.rooms[room]
                
        if client_id in self.connections:
            self.connections[client_id].rooms.discard(room)
            logger.debug(f"Client {client_id} left room {room}")
            
    async def subscribe(self, client_id: str, event_type: str):
        """Subscribe client to event type"""
        if client_id in self.connections:
            self.connections[client_id].subscriptions.add(event_type)
            logger.debug(f"Client {client_id} subscribed to {event_type}")
            
    async def unsubscribe(self, client_id: str, event_type: str):
        """Unsubscribe client from event type"""
        if client_id in self.connections:
            self.connections[client_id].subscriptions.discard(event_type)
            logger.debug(f"Client {client_id} unsubscribed from {event_type}")
            
    async def broadcast(self, message: WebSocketMessage, room: str = None):
        """Broadcast message to all connections or specific room"""
        if room:
            # Broadcast to specific room
            if room in self.rooms:
                clients = self.rooms[room]
            else:
                clients = set()
        else:
            # Broadcast to all connections
            clients = set(self.connections.keys())
            
        # Send to clients subscribed to this event type
        sent_count = 0
        failed_clients = []
        
        for client_id in clients:
            if client_id in self.connections:
                connection = self.connections[client_id]
                # Check if client is subscribed to this event type
                if not connection.subscriptions or message.type in connection.subscriptions:
                    success = await connection.send_message(message)
                    if success:
                        sent_count += 1
                    else:
                        failed_clients.append(client_id)
                        
        # Clean up failed connections
        for client_id in failed_clients:
            await self.disconnect(client_id)
            
        logger.debug(f"Broadcast {message.type} to {sent_count} clients")
        return sent_count
        
    async def send_to_client(self, client_id: str, message: WebSocketMessage):
        """Send message to specific client"""
        if client_id in self.connections:
            connection = self.connections[client_id]
            success = await connection.send_message(message)
            if not success:
                await self.disconnect(client_id)
            return success
        return False
        
    async def emit_event(self, event_type: WebSocketEventType, payload: Any, room: str = None):
        """Emit event with payload to subscribers"""
        message = WebSocketMessage(
            type=event_type.value,
            payload=payload,
            timestamp=datetime.now().timestamp()
        )
        
        # Call registered event handlers
        if event_type.value in self.event_handlers:
            for handler in self.event_handlers[event_type.value]:
                try:
                    await handler(payload)
                except Exception as e:
                    logger.error(f"Event handler error for {event_type.value}: {e}")
        
        # Process through event registry
        try:
            event_payload = EventPayload(
                timestamp=datetime.now(),
                correlation_id=str(uuid.uuid4()),
                source="websocket",
                data=payload
            )
            
            # Process event through registered handlers
            result = await event_registry.process(event_type.value, event_payload)
            
            if result:
                logger.debug(f"Event {event_type.value} processed successfully: {result}")
                
        except Exception as e:
            logger.error(f"Error processing event {event_type.value} through registry: {e}")
                    
        return await self.broadcast(message, room)
        
    def register_event_handler(self, event_type: WebSocketEventType, handler: Callable):
        """Register handler for specific event type"""
        if event_type.value not in self.event_handlers:
            self.event_handlers[event_type.value] = []
        self.event_handlers[event_type.value].append(handler)
        
    async def _heartbeat_loop(self):
        """Background task to send heartbeat pings"""
        while True:
            try:
                await asyncio.sleep(self.heartbeat_interval)
                
                failed_clients = []
                for client_id, connection in self.connections.items():
                    success = await connection.ping()
                    if not success:
                        failed_clients.append(client_id)
                        
                # Clean up failed connections
                for client_id in failed_clients:
                    await self.disconnect(client_id)
                    
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Heartbeat error: {e}")
                
    async def broadcast_schedule_event(self, event_type: str, payload: Dict[str, Any], room: str = None):
        """Convenience method for broadcasting schedule events"""
        try:
            # Map string event types to enum values
            event_enum = None
            for event in WebSocketEventType:
                if event.value == event_type:
                    event_enum = event
                    break
            
            if event_enum:
                return await self.emit_event(event_enum, payload, room)
            else:
                # Fallback for custom event types
                message = WebSocketMessage(
                    type=event_type,
                    payload=payload,
                    timestamp=datetime.now().timestamp()
                )
                return await self.broadcast(message, room)
        except Exception as e:
            logger.error(f"Error broadcasting schedule event {event_type}: {e}")
            return 0
    
    def get_stats(self) -> Dict[str, Any]:
        """Get WebSocket connection statistics"""
        return {
            "total_connections": len(self.connections),
            "active_rooms": len(self.rooms),
            "room_details": {room: len(clients) for room, clients in self.rooms.items()},
            "event_handlers": len(self.event_handlers),
            "heartbeat_active": self.heartbeat_task is not None,
            "event_registry_stats": event_registry.get_handler_metrics()
        }

# Global WebSocket manager instance
ws_manager = WebSocketManager()

# Alias for backward compatibility
websocket_manager = ws_manager