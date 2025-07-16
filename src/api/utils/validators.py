from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import re
import json
import base64
import hashlib


def validate_date_range(start_date: datetime, end_date: datetime, max_days: int = 365):
    """
    Validate date range parameters.
    
    Args:
        start_date: Start date
        end_date: End date
        max_days: Maximum allowed days in range
    
    Raises:
        ValueError: If validation fails
    """
    if start_date >= end_date:
        raise ValueError("Start date must be before end date")
    
    if (end_date - start_date).days > max_days:
        raise ValueError(f"Date range cannot exceed {max_days} days")
    
    if end_date > datetime.utcnow():
        raise ValueError("End date cannot be in the future")


def validate_timestamp(timestamp: int, max_age_seconds: int = 300):
    """
    Validate Unix timestamp.
    
    Args:
        timestamp: Unix timestamp in seconds
        max_age_seconds: Maximum age of timestamp
    
    Raises:
        ValueError: If validation fails
    """
    try:
        dt = datetime.fromtimestamp(timestamp)
    except (ValueError, OSError):
        raise ValueError("Invalid timestamp format")
    
    now = datetime.utcnow()
    if dt > now + timedelta(seconds=60):
        raise ValueError("Timestamp cannot be in the future")
    
    if dt < now - timedelta(seconds=max_age_seconds):
        raise ValueError(f"Timestamp is too old (max age: {max_age_seconds} seconds)")


def validate_step_interval(step: int, min_ms: int = 60000, max_ms: int = 86400000):
    """
    Validate time interval step.
    
    Args:
        step: Step interval in milliseconds
        min_ms: Minimum allowed milliseconds
        max_ms: Maximum allowed milliseconds
    
    Raises:
        ValueError: If validation fails
    """
    if step < min_ms:
        raise ValueError(f"Step interval must be at least {min_ms}ms")
    
    if step > max_ms:
        raise ValueError(f"Step interval cannot exceed {max_ms}ms")
    
    # Validate common intervals (1min, 5min, 15min, 30min, 1hour, etc.)
    valid_minutes = [1, 5, 15, 30, 60, 120, 240, 480, 1440]
    step_minutes = step / 60000
    
    if step_minutes not in valid_minutes:
        raise ValueError(f"Step interval must be one of: {valid_minutes} minutes")


# =============================================================================
# ADDITIONAL VALIDATORS FOR MOBILE APIS
# =============================================================================

def validate_push_content(title: str, body: str) -> bool:
    """Validate push notification content"""
    try:
        # Check length limits
        if len(title) > 200 or len(body) > 500:
            return False
        
        # Check for empty content
        if not title.strip() or not body.strip():
            return False
        
        # Check for malicious content (basic check)
        forbidden_patterns = [
            r'<script',
            r'javascript:',
            r'onclick=',
            r'onerror=',
            r'eval\(',
            r'alert\('
        ]
        
        content = title + " " + body
        for pattern in forbidden_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                return False
        
        return True
        
    except Exception:
        return False

def validate_coordinates(value: float) -> bool:
    """Validate GPS coordinates"""
    try:
        # Check if it's a valid number
        if not isinstance(value, (int, float)):
            return False
        
        # Basic range check (more specific checks done in the model validators)
        if abs(value) > 180:
            return False
        
        return True
        
    except Exception:
        return False

def validate_entity_data(entity_type: str, entity_data: Dict[str, Any]) -> bool:
    """Validate entity data for sync operations"""
    try:
        # Check if data is valid JSON-serializable
        json.dumps(entity_data)
        
        # Entity-specific validation
        if entity_type == "employee_request":
            required_fields = ["request_type", "date_from", "date_to"]
            return all(field in entity_data for field in required_fields)
        
        elif entity_type == "schedule_preference":
            required_fields = ["preference_date", "preference_type"]
            return all(field in entity_data for field in required_fields)
        
        elif entity_type == "vacation_request":
            required_fields = ["start_date", "end_date", "days_requested"]
            return all(field in entity_data for field in required_fields)
        
        elif entity_type == "notification_settings":
            # Notification settings can be flexible
            return isinstance(entity_data, dict)
        
        # Default validation - check for basic structure
        return isinstance(entity_data, dict) and len(entity_data) > 0
        
    except Exception:
        return False

def validate_device_info(device_info: Dict[str, Any]) -> bool:
    """Validate device information for registration"""
    try:
        required_fields = [
            "device_name", "device_type", "os_version", 
            "app_version", "hardware_model", "unique_identifier", "manufacturer"
        ]
        
        # Check required fields exist
        if not all(field in device_info for field in required_fields):
            return False
        
        # Validate device type
        valid_device_types = ["iPhone", "Android", "Tablet", "Desktop", "Web Browser"]
        if device_info.get("device_type") not in valid_device_types:
            return False
        
        # Validate unique identifier format
        unique_id = device_info.get("unique_identifier", "")
        if len(unique_id) < 10 or len(unique_id) > 200:
            return False
        
        # Validate version strings
        version_fields = ["os_version", "app_version"]
        for field in version_fields:
            value = device_info.get(field, "")
            if not re.match(r'^[\d\.\w\-]+$', value):
                return False
        
        return True
        
    except Exception:
        return False

def validate_biometric_template(template_data: str, biometric_type: str) -> bool:
    """Validate biometric template data"""
    try:
        # Check if it's valid base64
        try:
            decoded = base64.b64decode(template_data)
        except Exception:
            return False
        
        # Check minimum size (biometric templates should be substantial)
        if len(decoded) < 100:  # Minimum 100 bytes
            return False
        
        # Check maximum size (prevent DoS attacks)
        if len(decoded) > 10 * 1024 * 1024:  # Max 10MB
            return False
        
        # Type-specific validation
        valid_biometric_types = [
            "fingerprint", "face_id", "touch_id", "voice_print", "iris_scan", "palm_print"
        ]
        
        if biometric_type not in valid_biometric_types:
            return False
        
        return True
        
    except Exception:
        return False

def validate_employee_tab_n(tab_n: str) -> bool:
    """Validate employee tab number format"""
    try:
        if not tab_n or len(tab_n) > 50:
            return False
        
        # Basic pattern check (alphanumeric with some special characters)
        if not re.match(r'^[A-Za-z0-9_\-\.]+$', tab_n):
            return False
        
        return True
        
    except Exception:
        return False

def validate_phone_number(phone: str) -> bool:
    """Validate phone number format"""
    try:
        if not phone:
            return True  # Phone number is optional
        
        # Remove common formatting characters
        clean_phone = re.sub(r'[\s\-\(\)\+]', '', phone)
        
        # Check if it's all digits and reasonable length
        if not re.match(r'^\d{7,15}$', clean_phone):
            return False
        
        return True
        
    except Exception:
        return False

def validate_email_address(email: str) -> bool:
    """Validate email address format"""
    try:
        if not email:
            return True  # Email might be optional
        
        # Basic email pattern
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        
        if not re.match(pattern, email):
            return False
        
        # Check reasonable length
        if len(email) > 254:
            return False
        
        return True
        
    except Exception:
        return False