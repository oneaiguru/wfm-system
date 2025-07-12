"""
WebSocket Package
Event handling and real-time communication
"""

from .handlers import initialize_handlers, event_registry
from .models.event_models import *

# Initialize handlers on import
initialize_handlers()

__all__ = [
    'initialize_handlers',
    'event_registry'
]