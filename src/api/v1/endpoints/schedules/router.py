"""
Schedule Management Router
Combines all schedule-related endpoints
"""

from fastapi import APIRouter

from . import schedules, operations, employee_access, shifts, variants, conflicts

# Create main schedule router
router = APIRouter()

# Include all schedule sub-routers
router.include_router(schedules.router, tags=["schedules"])
router.include_router(operations.router, tags=["schedule-operations"])
router.include_router(employee_access.router, prefix="/employees", tags=["employee-schedules"])
router.include_router(shifts.router, prefix="/shifts", tags=["shifts"])
router.include_router(variants.router, tags=["schedule-variants"])
router.include_router(conflicts.router, prefix="/conflicts", tags=["schedule-conflicts"])