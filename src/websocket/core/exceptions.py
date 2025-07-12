"""
WebSocket Exception Classes
Custom exceptions for WebSocket operations
"""

from typing import Optional, Dict, Any


class WebSocketException(Exception):
    """Base exception for WebSocket operations"""
    
    def __init__(self, message: str, error_code: Optional[str] = None, details: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.error_code = error_code or "WEBSOCKET_ERROR"
        self.details = details or {}
        
    def to_dict(self) -> Dict[str, Any]:
        """Convert exception to dictionary for serialization"""
        return {
            "error_code": self.error_code,
            "error_message": str(self),
            "details": self.details
        }


class ConnectionClosedException(WebSocketException):
    """Raised when attempting to use a closed connection"""
    
    def __init__(self, connection_id: str, message: str = "Connection is closed"):
        super().__init__(
            message,
            error_code="CONNECTION_CLOSED",
            details={"connection_id": connection_id}
        )


class InvalidMessageException(WebSocketException):
    """Raised when message format is invalid"""
    
    def __init__(self, message: str, raw_message: Optional[str] = None):
        super().__init__(
            message,
            error_code="INVALID_MESSAGE",
            details={"raw_message": raw_message}
        )


class AuthenticationException(WebSocketException):
    """Raised when authentication fails"""
    
    def __init__(self, message: str = "Authentication failed"):
        super().__init__(
            message,
            error_code="AUTHENTICATION_FAILED"
        )


class AuthorizationException(WebSocketException):
    """Raised when authorization fails"""
    
    def __init__(self, message: str = "Authorization failed", required_permission: Optional[str] = None):
        super().__init__(
            message,
            error_code="AUTHORIZATION_FAILED",
            details={"required_permission": required_permission}
        )


class RateLimitException(WebSocketException):
    """Raised when rate limit is exceeded"""
    
    def __init__(self, message: str = "Rate limit exceeded", limit: Optional[int] = None, window: Optional[int] = None):
        super().__init__(
            message,
            error_code="RATE_LIMIT_EXCEEDED",
            details={"limit": limit, "window": window}
        )


class ConnectionLimitException(WebSocketException):
    """Raised when connection limit is exceeded"""
    
    def __init__(self, message: str = "Connection limit exceeded", limit: Optional[int] = None):
        super().__init__(
            message,
            error_code="CONNECTION_LIMIT_EXCEEDED",
            details={"limit": limit}
        )


class SubscriptionException(WebSocketException):
    """Raised when subscription operations fail"""
    
    def __init__(self, message: str, event_type: Optional[str] = None):
        super().__init__(
            message,
            error_code="SUBSCRIPTION_ERROR",
            details={"event_type": event_type}
        )


class BroadcastException(WebSocketException):
    """Raised when broadcast operations fail"""
    
    def __init__(self, message: str, failed_connections: Optional[list] = None):
        super().__init__(
            message,
            error_code="BROADCAST_ERROR",
            details={"failed_connections": failed_connections or []}
        )


class ServerOverloadException(WebSocketException):
    """Raised when server is overloaded"""
    
    def __init__(self, message: str = "Server overloaded", metrics: Optional[Dict[str, Any]] = None):
        super().__init__(
            message,
            error_code="SERVER_OVERLOAD",
            details=metrics or {}
        )


class ProtocolException(WebSocketException):
    """Raised when WebSocket protocol violations occur"""
    
    def __init__(self, message: str, protocol_version: Optional[str] = None):
        super().__init__(
            message,
            error_code="PROTOCOL_ERROR",
            details={"protocol_version": protocol_version}
        )