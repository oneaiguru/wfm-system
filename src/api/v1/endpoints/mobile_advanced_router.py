"""
Advanced Mobile APIs Router - Aggregates Tasks 61-65
Enterprise-grade mobile endpoints with security and compliance features
"""

from fastapi import APIRouter

# Import all advanced mobile endpoint modules
from . import (
    mobile_push_notifications_REAL,
    mobile_location_tracking_REAL,
    mobile_offline_sync_REAL,
    mobile_device_management_REAL,
    mobile_biometric_verification_REAL
)

# Create advanced mobile router
advanced_mobile_router = APIRouter(prefix="/mobile", tags=["advanced-mobile-apis"])

# Task 61: Push Notification System
advanced_mobile_router.include_router(
    mobile_push_notifications_REAL.router,
    prefix="/push",
    tags=["push-notifications"]
)

# Task 62: Location Tracking System  
advanced_mobile_router.include_router(
    mobile_location_tracking_REAL.router,
    prefix="/location",
    tags=["location-tracking"]
)

# Task 63: Offline Synchronization System
advanced_mobile_router.include_router(
    mobile_offline_sync_REAL.router,
    prefix="/sync",
    tags=["offline-sync"]
)

# Task 64: Device Management System
advanced_mobile_router.include_router(
    mobile_device_management_REAL.router,
    prefix="/devices",
    tags=["device-management"]
)

# Task 65: Biometric Authentication System
advanced_mobile_router.include_router(
    mobile_biometric_verification_REAL.router,
    prefix="/biometric",
    tags=["biometric-auth"]
)

# Export the router
__all__ = ["advanced_mobile_router"]