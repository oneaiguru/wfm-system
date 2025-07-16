"""
Mobile Personal Cabinet Endpoints Router
BDD Implementation: 14-mobile-personal-cabinet.feature

This router aggregates all mobile personal cabinet endpoints (Tasks 36-40):
- Mobile authentication and setup
- Personal calendar schedule viewing
- Push notification preferences
- Personal profile access
- Work preferences and availability settings

All endpoints implement real BDD scenarios with PostgreSQL integration.
"""

from fastapi import APIRouter

# Import all mobile endpoint modules
from . import (
    mobile_auth_setup_REAL,
    mobile_calendar_schedule_REAL,
    mobile_notifications_preferences_REAL,
    mobile_profile_personal_REAL,
    mobile_preferences_availability_REAL
)

# Create mobile endpoints router
mobile_router = APIRouter(prefix="/mobile", tags=["mobile-personal-cabinet"])

# BDD Task 36: Mobile Authentication and Setup
mobile_router.include_router(
    mobile_auth_setup_REAL.router,
    tags=["mobile-auth"]
)

# BDD Task 37: Personal Calendar Schedule
mobile_router.include_router(
    mobile_calendar_schedule_REAL.router,
    tags=["mobile-calendar"]
)

# BDD Task 38: Push Notification Preferences
mobile_router.include_router(
    mobile_notifications_preferences_REAL.router,
    tags=["mobile-notifications"]
)

# BDD Task 39: Personal Profile Access
mobile_router.include_router(
    mobile_profile_personal_REAL.router,
    tags=["mobile-profile"]
)

# BDD Task 40: Work Preferences and Availability
mobile_router.include_router(
    mobile_preferences_availability_REAL.router,
    tags=["mobile-preferences"]
)

# Export the router
__all__ = ["mobile_router"]