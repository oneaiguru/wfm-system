"""
Personnel Management API Endpoints
"""

from .employees import router as employees_router
from .skills import router as skills_router
from .groups import router as groups_router
from .organization import router as organization_router
from .bulk_operations import router as bulk_operations_router

__all__ = [
    "employees_router",
    "skills_router", 
    "groups_router",
    "organization_router",
    "bulk_operations_router"
]