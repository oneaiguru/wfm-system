"""
WebSocket Logging Utilities
High-performance logging for WebSocket operations
"""

import asyncio
import logging
import time
from typing import Optional, Dict, Any
from datetime import datetime
from contextlib import contextmanager

class WebSocketLogger:
    """Specialized logger for WebSocket operations"""
    
    def __init__(self, name: str = "websocket"):
        self.logger = logging.getLogger(name)
        self.performance_logger = logging.getLogger(f"{name}.performance")
        self.metrics = {
            "connections": 0,
            "messages_sent": 0,
            "messages_received": 0,
            "errors": 0,
            "slow_operations": 0
        }
    
    def connection_established(self, connection_id: str, user_id: Optional[str] = None):
        """Log connection establishment"""
        self.metrics["connections"] += 1
        self.logger.info(f"Connection established: {connection_id} (user: {user_id})")
    
    def connection_closed(self, connection_id: str, reason: str = ""):
        """Log connection closure"""
        self.metrics["connections"] -= 1
        self.logger.info(f"Connection closed: {connection_id} (reason: {reason})")
    
    def message_sent(self, connection_id: str, message_type: str, size: int, latency: float):
        """Log message sent"""
        self.metrics["messages_sent"] += 1
        
        if latency > 50:  # Log slow messages
            self.metrics["slow_operations"] += 1
            self.performance_logger.warning(
                f"Slow message send: {latency:.2f}ms to {connection_id} "
                f"(type: {message_type}, size: {size})"
            )
        else:
            self.logger.debug(
                f"Message sent to {connection_id}: {message_type} "
                f"({size} bytes, {latency:.2f}ms)"
            )
    
    def message_received(self, connection_id: str, message_type: str, size: int):
        """Log message received"""
        self.metrics["messages_received"] += 1
        self.logger.debug(
            f"Message received from {connection_id}: {message_type} ({size} bytes)"
        )
    
    def error(self, connection_id: str, error: Exception, context: Optional[Dict[str, Any]] = None):
        """Log error"""
        self.metrics["errors"] += 1
        context_str = f" (context: {context})" if context else ""
        self.logger.error(
            f"Error in connection {connection_id}: {error}{context_str}",
            exc_info=True
        )
    
    def performance_metrics(self, operation: str, duration: float, metadata: Optional[Dict[str, Any]] = None):
        """Log performance metrics"""
        if duration > 100:  # Log slow operations
            self.metrics["slow_operations"] += 1
            self.performance_logger.warning(
                f"Slow operation: {operation} took {duration:.2f}ms {metadata or ''}"
            )
        else:
            self.performance_logger.debug(
                f"Operation: {operation} took {duration:.2f}ms {metadata or ''}"
            )
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get logging metrics"""
        return self.metrics.copy()
    
    def reset_metrics(self):
        """Reset metrics counters"""
        self.metrics = {
            "connections": 0,
            "messages_sent": 0,
            "messages_received": 0,
            "errors": 0,
            "slow_operations": 0
        }
    
    @contextmanager
    def performance_context(self, operation: str, connection_id: Optional[str] = None):
        """Context manager for performance measurement"""
        start_time = time.time()
        try:
            yield
        finally:
            duration = (time.time() - start_time) * 1000  # Convert to ms
            self.performance_metrics(
                operation, 
                duration, 
                {"connection_id": connection_id} if connection_id else None
            )


def setup_websocket_logging(
    level: str = "INFO",
    format_string: Optional[str] = None,
    performance_logging: bool = True
):
    """Setup WebSocket logging configuration"""
    
    # Default format
    if format_string is None:
        format_string = (
            "%(asctime)s - %(name)s - %(levelname)s - "
            "%(message)s [%(filename)s:%(lineno)d]"
        )
    
    # Main WebSocket logger
    websocket_logger = logging.getLogger("websocket")
    websocket_logger.setLevel(getattr(logging, level.upper()))
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(getattr(logging, level.upper()))
    console_handler.setFormatter(logging.Formatter(format_string))
    websocket_logger.addHandler(console_handler)
    
    # Performance logger
    if performance_logging:
        performance_logger = logging.getLogger("websocket.performance")
        performance_logger.setLevel(logging.DEBUG)
        
        # Separate handler for performance logs
        performance_handler = logging.StreamHandler()
        performance_handler.setLevel(logging.DEBUG)
        performance_handler.setFormatter(
            logging.Formatter(
                "%(asctime)s - PERF - %(message)s"
            )
        )
        performance_logger.addHandler(performance_handler)
    
    # Prevent duplicate logs
    websocket_logger.propagate = False
    if performance_logging:
        performance_logger.propagate = False
    
    return websocket_logger


class PerformanceMonitor:
    """Performance monitoring utility"""
    
    def __init__(self, name: str):
        self.name = name
        self.start_time = time.time()
        self.measurements = []
    
    def mark(self, checkpoint: str):
        """Mark a checkpoint"""
        current_time = time.time()
        self.measurements.append({
            "checkpoint": checkpoint,
            "time": current_time,
            "elapsed": (current_time - self.start_time) * 1000
        })
    
    def get_summary(self) -> Dict[str, Any]:
        """Get performance summary"""
        if not self.measurements:
            return {"name": self.name, "measurements": []}
        
        total_time = self.measurements[-1]["elapsed"]
        
        return {
            "name": self.name,
            "total_time_ms": total_time,
            "measurements": self.measurements,
            "avg_checkpoint_time": total_time / len(self.measurements)
        }
    
    def log_summary(self, logger: WebSocketLogger):
        """Log performance summary"""
        summary = self.get_summary()
        
        if summary["total_time_ms"] > 100:  # Log slow operations
            logger.performance_logger.warning(
                f"Performance summary for {self.name}: "
                f"{summary['total_time_ms']:.2f}ms total, "
                f"{len(self.measurements)} checkpoints"
            )
        else:
            logger.performance_logger.debug(
                f"Performance summary for {self.name}: "
                f"{summary['total_time_ms']:.2f}ms total"
            )


# Global logger instance
ws_logger = WebSocketLogger()

# Decorator for performance monitoring
def monitor_performance(operation_name: str):
    """Decorator for monitoring function performance"""
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            with ws_logger.performance_context(operation_name):
                return await func(*args, **kwargs)
        
        def sync_wrapper(*args, **kwargs):
            with ws_logger.performance_context(operation_name):
                return func(*args, **kwargs)
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator