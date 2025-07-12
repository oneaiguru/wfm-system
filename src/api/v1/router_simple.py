"""
Simple Router for WFM Enterprise Demo
Minimal router with only essential endpoints for demo
"""

from fastapi import APIRouter
from .endpoints.auth_simple import router as auth_router
from .endpoints.employee_management_bdd import router as employee_bdd_router
from .endpoints.skills_management_bdd import router as skills_bdd_router
from .endpoints.personnel_infrastructure_bdd import router as infrastructure_bdd_router
from .endpoints.integration_service_bdd import router as integration_bdd_router
from .endpoints.security_access_bdd import router as security_bdd_router
from .endpoints.account_lifecycle_bdd import router as account_lifecycle_bdd_router
from .endpoints.backup_recovery_bdd import router as backup_recovery_bdd_router

api_router = APIRouter()

# Health check endpoint
@api_router.get("/health")
async def health_check():
    """Simple health check"""
    return {
        "status": "healthy",
        "api_endpoints": 3,
        "demo_mode": True
    }

# Include auth router
api_router.include_router(auth_router, prefix="/auth", tags=["authentication"])

# Include BDD-compliant employee management router
api_router.include_router(employee_bdd_router, tags=["Employee Management BDD"])

# Include BDD-compliant infrastructure monitoring router
api_router.include_router(infrastructure_bdd_router, tags=["Personnel Infrastructure BDD"])

# Include BDD-compliant integration service router
api_router.include_router(integration_bdd_router, tags=["Integration Service BDD"])

# Include BDD-compliant security access router
api_router.include_router(security_bdd_router, tags=["Security Access BDD"])

# Include BDD-compliant account lifecycle router
api_router.include_router(account_lifecycle_bdd_router, tags=["Account Lifecycle BDD"])

# Simple employee endpoint for demo
@api_router.get("/personnel/employees")
async def list_employees():
    """Demo employee list"""
    return {
        "employees": [
            {"id": "emp_001", "name": "John Doe", "department": "Support"},
            {"id": "emp_002", "name": "Jane Smith", "department": "Sales"},
            {"id": "emp_003", "name": "Bob Johnson", "department": "Support"}
        ],
        "total": 3
    }

# Simple forecast endpoint for demo
@api_router.get("/forecasts")
async def list_forecasts():
    """Demo forecast list"""
    return {
        "forecasts": [
            {
                "id": "forecast_001", 
                "name": "Q1 2024 Call Volume", 
                "accuracy": 0.956,
                "status": "completed"
            }
        ],
        "total": 1
    }

# Simple schedule endpoint for demo
@api_router.get("/schedules")
async def list_schedules():
    """Demo schedule list"""
    return {
        "schedules": [
            {
                "id": "schedule_001",
                "name": "Week 1 Optimized Schedule",
                "status": "published",
                "optimization_score": 0.923
            }
        ],
        "total": 1
    }