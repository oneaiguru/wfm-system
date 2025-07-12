from datetime import datetime, timedelta
from typing import Optional


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