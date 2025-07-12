"""
WebSocket Event Handlers Package
Central registration and management of all event handlers
"""

from .base import BaseEventHandler, EventHandlerRegistry, event_registry
from .forecast_handlers import ForecastUpdatedHandler, ForecastCalculatedHandler, ForecastErrorHandler
from .schedule_handlers import ScheduleChangedHandler, ScheduleOptimizedHandler, ShiftAssignedHandler

# Register all handlers
def initialize_handlers():
    """Initialize and register all event handlers"""
    
    # Forecast handlers
    event_registry.register('forecast.updated', ForecastUpdatedHandler())
    event_registry.register('forecast.calculated', ForecastCalculatedHandler())
    event_registry.register('forecast.error', ForecastErrorHandler())
    
    # Schedule handlers
    event_registry.register('schedule.changed', ScheduleChangedHandler())
    event_registry.register('schedule.optimized', ScheduleOptimizedHandler())
    event_registry.register('shift.assigned', ShiftAssignedHandler())
    
    return event_registry

# Export main components
__all__ = [
    'BaseEventHandler',
    'EventHandlerRegistry',
    'event_registry',
    'initialize_handlers',
    'ForecastUpdatedHandler',
    'ForecastCalculatedHandler',
    'ForecastErrorHandler',
    'ScheduleChangedHandler',
    'ScheduleOptimizedHandler',
    'ShiftAssignedHandler'
]