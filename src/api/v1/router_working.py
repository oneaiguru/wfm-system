"""
Working Router for WFM Enterprise Demo
Minimal router with only working endpoints for testing
"""

from fastapi import APIRouter
from .endpoints.auth_simple import router as auth_router
from .endpoints.bdd_step_by_step_requests import router as requests_router

api_router = APIRouter()

# Health check endpoint
@api_router.get("/health")
async def health_check():
    """Simple health check"""
    return {
        "status": "healthy",
        "api_endpoints": 5,
        "demo_mode": True,
        "vacation_request_system": "active"
    }

# Include auth router
api_router.include_router(auth_router, prefix="/auth", tags=["authentication"])

# Include vacation requests router
api_router.include_router(requests_router, tags=["Vacation Requests"])

# Simple employee endpoint for demo
@api_router.get("/employees")
async def list_employees():
    """Demo employee list"""
    return {
        "employees": [
            {"id": "1", "name": "John Doe", "department": "Support", "employee_id": "111538"},
            {"id": "2", "name": "Jane Smith", "department": "Sales", "employee_id": "111539"},
            {"id": "3", "name": "Bob Johnson", "department": "Support", "employee_id": "111540"}
        ],
        "total": 3
    }

# Vacation request submission endpoint
@api_router.post("/requests/vacation")
async def submit_vacation_request(request_data: dict):
    """Submit a vacation request - CORE BDD SCENARIO"""
    
    employee_id = request_data.get("employee_id", "1")
    request_type = request_data.get("request_type", "sick_leave")
    start_date = request_data.get("start_date")
    end_date = request_data.get("end_date") 
    reason = request_data.get("reason", "")
    
    # Validate required fields
    if not start_date or not end_date:
        return {
            "status": "error",
            "message": "Start date and end date are required"
        }
    
    # Create request ID
    import uuid
    request_id = str(uuid.uuid4())
    
    return {
        "status": "success",
        "message": "Vacation request submitted successfully",
        "request_id": request_id,
        "employee_id": employee_id,
        "request_type": request_type,
        "start_date": start_date,
        "end_date": end_date,
        "reason": reason,
        "created_at": "2025-07-15T12:00:00Z",
        "approval_status": "pending"
    }