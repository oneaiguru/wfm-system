"""
WebSocket Event Dispatcher
High-performance event routing and handling system
"""

import asyncio
import logging
from typing import Dict, List, Callable, Any, Optional, Set
from datetime import datetime
from collections import defaultdict
from dataclasses import dataclass, field

from ..core.messages import WebSocketMessage, WebSocketEventType

logger = logging.getLogger(__name__)


@dataclass
class EventHandler:
    """Event handler metadata"""
    handler: Callable
    priority: int = 0
    filters: Dict[str, Any] = field(default_factory=dict)
    async_handler: bool = True
    
    def matches_filter(self, payload: Dict[str, Any]) -> bool:
        """Check if event matches handler filters"""
        if not self.filters:
            return True
        
        for key, value in self.filters.items():
            if key not in payload or payload[key] != value:
                return False
        
        return True


class EventDispatcher:
    """
    High-performance event dispatcher for WebSocket events
    Supports priority-based handlers, filtering, and async processing
    """
    
    def __init__(self, max_queue_size: int = 10000):
        self.max_queue_size = max_queue_size
        
        # Event handlers by event type
        self.handlers: Dict[str, List[EventHandler]] = defaultdict(list)
        
        # Global handlers (receive all events)
        self.global_handlers: List[EventHandler] = []
        
        # Event queue for async processing
        self.event_queue: asyncio.Queue = asyncio.Queue(maxsize=max_queue_size)
        
        # Processing task
        self.processing_task: Optional[asyncio.Task] = None
        self.is_running = False
        
        # Performance metrics
        self.events_processed = 0
        self.events_queued = 0
        self.handlers_executed = 0
        self.avg_processing_time = 0
        
        # Error handling
        self.error_handler: Optional[Callable] = None
        self.failed_events: List[Dict[str, Any]] = []
    
    async def start(self):
        """Start the event dispatcher"""
        if self.is_running:
            return
        
        self.is_running = True
        self.processing_task = asyncio.create_task(self._process_events())
        logger.info("Event dispatcher started")
    
    async def stop(self):
        """Stop the event dispatcher"""
        if not self.is_running:
            return
        
        self.is_running = False
        
        if self.processing_task:
            self.processing_task.cancel()
            try:
                await self.processing_task
            except asyncio.CancelledError:
                pass
        
        logger.info("Event dispatcher stopped")
    
    def register_handler(
        self,
        event_type: str,
        handler: Callable,
        priority: int = 0,
        filters: Optional[Dict[str, Any]] = None,
        async_handler: bool = True
    ):
        """Register event handler"""
        event_handler = EventHandler(
            handler=handler,
            priority=priority,
            filters=filters or {},
            async_handler=async_handler
        )
        
        self.handlers[event_type].append(event_handler)
        
        # Sort handlers by priority (higher priority first)
        self.handlers[event_type].sort(key=lambda h: h.priority, reverse=True)
        
        logger.debug(f"Registered handler for {event_type} with priority {priority}")
    
    def register_global_handler(
        self,
        handler: Callable,
        priority: int = 0,
        filters: Optional[Dict[str, Any]] = None,
        async_handler: bool = True
    ):
        """Register global event handler (receives all events)"""
        event_handler = EventHandler(
            handler=handler,
            priority=priority,
            filters=filters or {},
            async_handler=async_handler
        )
        
        self.global_handlers.append(event_handler)
        
        # Sort handlers by priority
        self.global_handlers.sort(key=lambda h: h.priority, reverse=True)
        
        logger.debug(f"Registered global handler with priority {priority}")
    
    def unregister_handler(self, event_type: str, handler: Callable):
        """Unregister event handler"""
        self.handlers[event_type] = [
            h for h in self.handlers[event_type] 
            if h.handler != handler
        ]
        
        if not self.handlers[event_type]:
            del self.handlers[event_type]
        
        logger.debug(f"Unregistered handler for {event_type}")
    
    def unregister_global_handler(self, handler: Callable):
        """Unregister global event handler"""
        self.global_handlers = [
            h for h in self.global_handlers 
            if h.handler != handler
        ]
        
        logger.debug("Unregistered global handler")
    
    async def dispatch_event(
        self,
        event_type: str,
        payload: Dict[str, Any],
        sync: bool = False
    ) -> bool:
        """Dispatch event to handlers"""
        if sync:
            # Synchronous dispatch
            return await self._execute_handlers(event_type, payload)
        else:
            # Asynchronous dispatch via queue
            try:
                event_data = {
                    "type": event_type,
                    "payload": payload,
                    "timestamp": datetime.utcnow().isoformat()
                }
                
                self.event_queue.put_nowait(event_data)
                self.events_queued += 1
                return True
                
            except asyncio.QueueFull:
                logger.error(f"Event queue full, dropping event: {event_type}")
                return False
    
    async def dispatch_message(self, message: WebSocketMessage, sync: bool = False) -> bool:
        """Dispatch WebSocket message as event"""
        return await self.dispatch_event(
            event_type=message.type,
            payload=message.payload,
            sync=sync
        )
    
    async def _process_events(self):
        """Background event processing task"""
        while self.is_running:
            try:
                # Get event from queue with timeout
                event_data = await asyncio.wait_for(
                    self.event_queue.get(),
                    timeout=1.0
                )
                
                # Process event
                await self._execute_handlers(
                    event_data["type"],
                    event_data["payload"]
                )
                
                self.events_processed += 1
                
            except asyncio.TimeoutError:
                # No events to process
                continue
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Event processing error: {e}")
                if self.error_handler:
                    try:
                        await self.error_handler(e)
                    except Exception as handler_error:
                        logger.error(f"Error handler failed: {handler_error}")
    
    async def _execute_handlers(self, event_type: str, payload: Dict[str, Any]) -> bool:
        """Execute handlers for an event"""
        start_time = asyncio.get_event_loop().time()
        
        # Get specific handlers
        specific_handlers = self.handlers.get(event_type, [])
        
        # Combine with global handlers
        all_handlers = specific_handlers + self.global_handlers
        
        if not all_handlers:
            return True
        
        # Execute handlers
        handler_tasks = []
        
        for handler in all_handlers:
            if handler.matches_filter(payload):
                if handler.async_handler:
                    task = asyncio.create_task(self._execute_async_handler(handler, event_type, payload))
                    handler_tasks.append(task)
                else:
                    # Execute sync handler in thread pool
                    task = asyncio.create_task(self._execute_sync_handler(handler, event_type, payload))
                    handler_tasks.append(task)
        
        # Wait for all handlers to complete
        if handler_tasks:
            results = await asyncio.gather(*handler_tasks, return_exceptions=True)
            
            # Check for errors
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    logger.error(f"Handler {i} failed for event {event_type}: {result}")
                    self.failed_events.append({
                        "event_type": event_type,
                        "payload": payload,
                        "error": str(result),
                        "timestamp": datetime.utcnow().isoformat()
                    })
        
        # Update metrics
        processing_time = (asyncio.get_event_loop().time() - start_time) * 1000
        self.handlers_executed += len(handler_tasks)
        
        # Update average processing time
        self.avg_processing_time = (
            (self.avg_processing_time * (self.events_processed - 1) + processing_time)
            / self.events_processed
        ) if self.events_processed > 0 else processing_time
        
        return True
    
    async def _execute_async_handler(self, handler: EventHandler, event_type: str, payload: Dict[str, Any]):
        """Execute async handler"""
        try:
            await handler.handler(event_type, payload)
        except Exception as e:
            logger.error(f"Async handler error for {event_type}: {e}")
            raise
    
    async def _execute_sync_handler(self, handler: EventHandler, event_type: str, payload: Dict[str, Any]):
        """Execute sync handler in thread pool"""
        try:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, handler.handler, event_type, payload)
        except Exception as e:
            logger.error(f"Sync handler error for {event_type}: {e}")
            raise
    
    def set_error_handler(self, handler: Callable):
        """Set global error handler"""
        self.error_handler = handler
    
    def get_stats(self) -> Dict[str, Any]:
        """Get dispatcher statistics"""
        return {
            "events_processed": self.events_processed,
            "events_queued": self.events_queued,
            "handlers_executed": self.handlers_executed,
            "avg_processing_time_ms": self.avg_processing_time,
            "queue_size": self.event_queue.qsize(),
            "max_queue_size": self.max_queue_size,
            "registered_handlers": len(self.handlers),
            "global_handlers": len(self.global_handlers),
            "failed_events": len(self.failed_events),
            "is_running": self.is_running
        }
    
    def get_handlers_info(self) -> Dict[str, Any]:
        """Get information about registered handlers"""
        handlers_info = {}
        
        for event_type, handlers in self.handlers.items():
            handlers_info[event_type] = [
                {
                    "handler": handler.handler.__name__,
                    "priority": handler.priority,
                    "filters": handler.filters,
                    "async": handler.async_handler
                }
                for handler in handlers
            ]
        
        return {
            "specific_handlers": handlers_info,
            "global_handlers": [
                {
                    "handler": handler.handler.__name__,
                    "priority": handler.priority,
                    "filters": handler.filters,
                    "async": handler.async_handler
                }
                for handler in self.global_handlers
            ]
        }
    
    def clear_failed_events(self):
        """Clear failed events list"""
        self.failed_events.clear()
    
    def get_failed_events(self) -> List[Dict[str, Any]]:
        """Get list of failed events"""
        return self.failed_events.copy()


# Decorator for easy handler registration
def event_handler(
    event_type: str,
    dispatcher: EventDispatcher,
    priority: int = 0,
    filters: Optional[Dict[str, Any]] = None
):
    """Decorator for registering event handlers"""
    def decorator(func):
        dispatcher.register_handler(
            event_type=event_type,
            handler=func,
            priority=priority,
            filters=filters
        )
        return func
    return decorator


def global_event_handler(
    dispatcher: EventDispatcher,
    priority: int = 0,
    filters: Optional[Dict[str, Any]] = None
):
    """Decorator for registering global event handlers"""
    def decorator(func):
        dispatcher.register_global_handler(
            handler=func,
            priority=priority,
            filters=filters
        )
        return func
    return decorator