"""
WebSocket endpoints for real-time WFM communication
Replaces the TypeScript stub with production FastAPI implementation
"""

import asyncio
import json
import logging
from typing import Dict, Any, Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, Query
from fastapi.responses import JSONResponse

from ...services.websocket import ws_manager, WebSocketEventType, WebSocketMessage
from ..schemas.websocket import (
    WebSocketConnectionRequest,
    WebSocketSubscriptionRequest,
    WebSocketRoomRequest,
    WebSocketStatsResponse,
    WebSocketResponse,
    WebSocketEventMessage
)
from ...core.deps import get_current_user_optional

logger = logging.getLogger(__name__)
router = APIRouter()

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    client_id: Optional[str] = Query(None),
    user_id: Optional[str] = Query(None),
    token: Optional[str] = Query(None)
):
    """
    Main WebSocket endpoint for real-time communication
    Supports authentication, subscriptions, and room management
    """
    try:
        # TODO: Implement proper authentication with token
        # For now, accept all connections
        
        client_id = await ws_manager.connect(websocket, client_id, user_id)
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_text()
                
                try:
                    message = json.loads(data)
                    await handle_websocket_message(client_id, message)
                except json.JSONDecodeError:
                    logger.error(f"Invalid JSON from client {client_id}: {data}")
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": "Invalid JSON format",
                        "timestamp": asyncio.get_event_loop().time()
                    }))
                except Exception as e:
                    logger.error(f"Error handling message from {client_id}: {e}")
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": "Internal server error",
                        "timestamp": asyncio.get_event_loop().time()
                    }))
                    
        except WebSocketDisconnect:
            logger.info(f"Client {client_id} disconnected")
        finally:
            await ws_manager.disconnect(client_id)
            
    except Exception as e:
        logger.error(f"WebSocket connection error: {e}")
        try:
            await websocket.close()
        except:
            pass

async def handle_websocket_message(client_id: str, message: Dict[str, Any]):
    """Handle incoming WebSocket messages from clients"""
    message_type = message.get("type")
    payload = message.get("payload", {})
    
    if message_type == "subscribe":
        # Subscribe to event types
        event_types = payload.get("event_types", [])
        for event_type in event_types:
            await ws_manager.subscribe(client_id, event_type)
        
        response = WebSocketMessage(
            type="subscription_confirmed",
            payload={"subscribed_events": event_types},
            timestamp=asyncio.get_event_loop().time()
        )
        await ws_manager.send_to_client(client_id, response)
        
    elif message_type == "unsubscribe":
        # Unsubscribe from event types
        event_types = payload.get("event_types", [])
        for event_type in event_types:
            await ws_manager.unsubscribe(client_id, event_type)
        
        response = WebSocketMessage(
            type="unsubscription_confirmed",
            payload={"unsubscribed_events": event_types},
            timestamp=asyncio.get_event_loop().time()
        )
        await ws_manager.send_to_client(client_id, response)
        
    elif message_type == "join_room":
        # Join rooms
        rooms = payload.get("rooms", [])
        for room in rooms:
            await ws_manager.join_room(client_id, room)
        
        response = WebSocketMessage(
            type="room_joined",
            payload={"joined_rooms": rooms},
            timestamp=asyncio.get_event_loop().time()
        )
        await ws_manager.send_to_client(client_id, response)
        
    elif message_type == "leave_room":
        # Leave rooms
        rooms = payload.get("rooms", [])
        for room in rooms:
            await ws_manager.leave_room(client_id, room)
        
        response = WebSocketMessage(
            type="room_left",
            payload={"left_rooms": rooms},
            timestamp=asyncio.get_event_loop().time()
        )
        await ws_manager.send_to_client(client_id, response)
        
    elif message_type == "emit":
        # Emit custom event (for testing/development)
        event_type = payload.get("event_type")
        event_payload = payload.get("payload", {})
        room = payload.get("room")
        
        if event_type:
            await ws_manager.emit_event(event_type, event_payload, room)
        
    elif message_type == "pong":
        # Handle pong response to ping
        logger.debug(f"Received pong from {client_id}")
        
    else:
        logger.warning(f"Unknown message type from {client_id}: {message_type}")

# REST API endpoints for WebSocket management
@router.post("/ws/broadcast")
async def broadcast_event(
    event: WebSocketEventMessage,
    room: Optional[str] = None,
    current_user = Depends(get_current_user_optional)
):
    """
    Broadcast event to all connected clients or specific room
    Used by other services to emit events
    """
    try:
        message = WebSocketMessage(
            type=event.type,
            payload=event.payload,
            timestamp=event.timestamp,
            client_id=event.client_id,
            room=room
        )
        
        sent_count = await ws_manager.broadcast(message, room)
        
        return WebSocketResponse(
            success=True,
            message=f"Event broadcast to {sent_count} clients",
            data={"sent_count": sent_count},
            timestamp=asyncio.get_event_loop().time()
        )
        
    except Exception as e:
        logger.error(f"Broadcast error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/ws/emit/{event_type}")
async def emit_event(
    event_type: str,
    payload: Dict[str, Any],
    room: Optional[str] = None,
    current_user = Depends(get_current_user_optional)
):
    """
    Emit specific event type with payload
    Convenience endpoint for common event types
    """
    try:
        # Validate event type
        try:
            ws_event_type = WebSocketEventType(event_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid event type: {event_type}")
        
        sent_count = await ws_manager.emit_event(ws_event_type, payload, room)
        
        return WebSocketResponse(
            success=True,
            message=f"Event {event_type} emitted to {sent_count} clients",
            data={"sent_count": sent_count, "event_type": event_type},
            timestamp=asyncio.get_event_loop().time()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Emit error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/ws/stats")
async def get_websocket_stats(
    current_user = Depends(get_current_user_optional)
) -> WebSocketStatsResponse:
    """Get WebSocket connection statistics"""
    stats = ws_manager.get_stats()
    
    return WebSocketStatsResponse(
        total_connections=stats["total_connections"],
        active_rooms=stats["active_rooms"],
        room_details=stats["room_details"],
        event_handlers=stats["event_handlers"],
        heartbeat_active=stats["heartbeat_active"],
        uptime_seconds=asyncio.get_event_loop().time()
    )

@router.get("/ws/events")
async def get_available_events():
    """Get list of available WebSocket event types"""
    events = {
        "forecast_events": [
            WebSocketEventType.FORECAST_UPDATED.value,
            WebSocketEventType.FORECAST_CALCULATED.value,
            WebSocketEventType.FORECAST_ERROR.value
        ],
        "schedule_events": [
            WebSocketEventType.SCHEDULE_CHANGED.value,
            WebSocketEventType.SCHEDULE_OPTIMIZED.value,
            WebSocketEventType.SHIFT_ASSIGNED.value,
            WebSocketEventType.SHIFT_SWAPPED.value
        ],
        "monitoring_events": [
            WebSocketEventType.AGENT_STATUS_CHANGED.value,
            WebSocketEventType.QUEUE_METRICS_UPDATE.value,
            WebSocketEventType.SLA_ALERT.value
        ],
        "skill_events": [
            WebSocketEventType.SKILL_ASSIGNED.value,
            WebSocketEventType.SKILL_REMOVED.value,
            WebSocketEventType.SKILL_LEVEL_CHANGED.value
        ],
        "vacancy_events": [
            WebSocketEventType.VACANCY_CREATED.value,
            WebSocketEventType.VACANCY_FILLED.value,
            WebSocketEventType.STAFFING_GAP_DETECTED.value
        ],
        "algorithm_events": [
            WebSocketEventType.ERLANG_CALCULATION_COMPLETE.value,
            WebSocketEventType.OPTIMIZATION_COMPLETE.value,
            WebSocketEventType.ACCURACY_METRICS_READY.value
        ]
    }
    
    return {"events": events, "total_count": sum(len(category) for category in events.values())}

# Legacy compatibility endpoints (matching existing argus_realtime_enhanced.py)
@router.websocket("/ws/agent-status/{agent_id}")
async def agent_status_websocket(websocket: WebSocket, agent_id: str):
    """
    Legacy WebSocket endpoint for agent status updates
    Maintains compatibility with existing clients
    """
    client_id = await ws_manager.connect(websocket, f"agent-{agent_id}")
    
    # Auto-subscribe to agent status events
    await ws_manager.subscribe(client_id, WebSocketEventType.AGENT_STATUS_CHANGED.value)
    await ws_manager.join_room(client_id, f"agent-{agent_id}")
    
    try:
        while True:
            # Keep connection alive and handle any client messages
            data = await websocket.receive_text()
            # Echo back for compatibility
            await websocket.send_text(data)
            
    except WebSocketDisconnect:
        await ws_manager.disconnect(client_id)

@router.websocket("/ws/queue-metrics/{group_id}")
async def queue_metrics_websocket(websocket: WebSocket, group_id: str):
    """
    Legacy WebSocket endpoint for queue metrics
    Maintains compatibility with existing clients
    """
    client_id = await ws_manager.connect(websocket, f"queue-{group_id}")
    
    # Auto-subscribe to queue metrics events
    await ws_manager.subscribe(client_id, WebSocketEventType.QUEUE_METRICS_UPDATE.value)
    await ws_manager.join_room(client_id, f"queue-{group_id}")
    
    try:
        while True:
            # Keep connection alive and handle any client messages
            data = await websocket.receive_text()
            # Echo back for compatibility
            await websocket.send_text(data)
            
    except WebSocketDisconnect:
        await ws_manager.disconnect(client_id)