"""
Integration Endpoints Package

This package contains all integration API endpoints:
- 1C ZUP Integration (10 endpoints)
- Contact Center Integration (15 endpoints)
- Webhook management
- Connection management

Total: 25+ integration endpoints
"""

from .onec import router as onec_router
from .contact_center import router as contact_center_router
from .webhooks import router as webhooks_router
from .connections import router as connections_router

__all__ = [
    "onec_router",
    "contact_center_router", 
    "webhooks_router",
    "connections_router"
]