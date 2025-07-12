"""
Base Event Handler Architecture for WebSocket Events
Provides standardized interface for all event handlers
"""

import asyncio
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List, Callable
from datetime import datetime
from pydantic import BaseModel, Field
import uuid

logger = logging.getLogger(__name__)


class EventPayload(BaseModel):
    """Base event payload structure"""
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    correlation_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source: str = Field(default="system")
    data: Dict[str, Any] = Field(default_factory=dict)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class HandlerMetrics(BaseModel):
    """Event handler performance metrics"""
    total_events: int = 0
    successful_events: int = 0
    failed_events: int = 0
    average_processing_time: float = 0.0
    last_processed: Optional[datetime] = None
    
    def record_success(self, processing_time: float):
        """Record successful event processing"""
        self.total_events += 1
        self.successful_events += 1
        self.last_processed = datetime.utcnow()
        
        # Update rolling average
        total_time = self.average_processing_time * (self.total_events - 1) + processing_time
        self.average_processing_time = total_time / self.total_events
    
    def record_failure(self):
        """Record failed event processing"""
        self.total_events += 1
        self.failed_events += 1
        self.last_processed = datetime.utcnow()
    
    @property
    def success_rate(self) -> float:
        """Calculate success rate percentage"""
        if self.total_events == 0:
            return 0.0
        return (self.successful_events / self.total_events) * 100


class BaseEventHandler(ABC):
    """Abstract base class for all event handlers"""
    
    def __init__(self, event_type: str):
        self.event_type = event_type
        self.metrics = HandlerMetrics()
        self.middleware: List[Callable] = []
        self.enabled = True
    
    @abstractmethod
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Process the event and return optional response"""
        pass
    
    @abstractmethod
    async def validate(self, payload: EventPayload) -> bool:
        """Validate event payload"""
        pass
    
    async def pre_process(self, payload: EventPayload) -> EventPayload:
        """Pre-processing hook - can be overridden"""
        return payload
    
    async def post_process(self, result: Optional[Dict[str, Any]]) -> None:
        """Post-processing hook - can be overridden"""
        pass
    
    async def process_event(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Main event processing pipeline"""
        if not self.enabled:
            logger.debug(f"Handler {self.event_type} is disabled")
            return None
        
        start_time = datetime.utcnow()
        
        try:
            # Validate payload
            if not await self.validate(payload):
                logger.warning(f"Invalid payload for event {self.event_type}")
                self.metrics.record_failure()
                return None
            
            # Pre-process
            processed_payload = await self.pre_process(payload)
            
            # Handle event
            result = await self.handle(processed_payload)
            
            # Post-process
            await self.post_process(result)
            
            # Record success metrics
            processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000  # ms
            self.metrics.record_success(processing_time)
            
            logger.debug(f"Successfully processed {self.event_type} in {processing_time:.2f}ms")
            return result
            
        except Exception as e:
            logger.error(f"Error processing {self.event_type}: {str(e)}")
            self.metrics.record_failure()
            return None
    
    def add_middleware(self, middleware: Callable):
        """Add middleware to handler"""
        self.middleware.append(middleware)
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get handler metrics"""
        return {
            "event_type": self.event_type,
            "enabled": self.enabled,
            "metrics": self.metrics.dict()
        }


class EventMiddleware:
    """Base middleware for event processing"""
    
    async def before(self, payload: EventPayload) -> EventPayload:
        """Execute before event processing"""
        return payload
    
    async def after(self, result: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """Execute after event processing"""
        return result


class EventHandlerRegistry:
    """Central registry for all event handlers"""
    
    def __init__(self):
        self.handlers: Dict[str, BaseEventHandler] = {}
        self.middleware: List[EventMiddleware] = []
        self.global_enabled = True
    
    def register(self, event_type: str, handler: BaseEventHandler):
        """Register event handler"""
        self.handlers[event_type] = handler
        logger.info(f"Registered handler for {event_type}")
    
    def unregister(self, event_type: str):
        """Unregister event handler"""
        if event_type in self.handlers:
            del self.handlers[event_type]
            logger.info(f"Unregistered handler for {event_type}")
    
    def register_module(self, module):
        """Register all handlers from a module"""
        for attr_name in dir(module):
            attr = getattr(module, attr_name)
            if (isinstance(attr, type) and 
                issubclass(attr, BaseEventHandler) and 
                attr is not BaseEventHandler):
                try:
                    handler_instance = attr()
                    self.register(handler_instance.event_type, handler_instance)
                except Exception as e:
                    logger.error(f"Failed to register handler {attr_name}: {str(e)}")
    
    def add_middleware(self, middleware: EventMiddleware):
        """Add global middleware"""
        self.middleware.append(middleware)
    
    async def process(self, event_type: str, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Process event through registered handler"""
        if not self.global_enabled:
            logger.debug("Event processing is globally disabled")
            return None
        
        handler = self.handlers.get(event_type)
        if not handler:
            logger.warning(f"No handler registered for {event_type}")
            return None
        
        # Apply global middleware
        processed_payload = payload
        for middleware in self.middleware:
            processed_payload = await middleware.before(processed_payload)
        
        # Process event
        result = await handler.process_event(processed_payload)
        
        # Apply global middleware (after)
        for middleware in self.middleware:
            result = await middleware.after(result)
        
        return result
    
    def get_registered_events(self) -> List[str]:
        """Get list of all registered event types"""
        return list(self.handlers.keys())
    
    def get_handler_metrics(self) -> Dict[str, Any]:
        """Get metrics for all handlers"""
        return {
            "total_handlers": len(self.handlers),
            "global_enabled": self.global_enabled,
            "handlers": {
                event_type: handler.get_metrics()
                for event_type, handler in self.handlers.items()
            }
        }
    
    def enable_handler(self, event_type: str):
        """Enable specific handler"""
        if event_type in self.handlers:
            self.handlers[event_type].enabled = True
            logger.info(f"Enabled handler for {event_type}")
    
    def disable_handler(self, event_type: str):
        """Disable specific handler"""
        if event_type in self.handlers:
            self.handlers[event_type].enabled = False
            logger.info(f"Disabled handler for {event_type}")
    
    def enable_all(self):
        """Enable all handlers"""
        self.global_enabled = True
        for handler in self.handlers.values():
            handler.enabled = True
        logger.info("Enabled all event handlers")
    
    def disable_all(self):
        """Disable all handlers"""
        self.global_enabled = False
        for handler in self.handlers.values():
            handler.enabled = False
        logger.info("Disabled all event handlers")


# Global registry instance
event_registry = EventHandlerRegistry()