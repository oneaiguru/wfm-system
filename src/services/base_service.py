#!/usr/bin/env python3
"""
Algorithm Service Base Interface
==============================

Standardized base interface for all algorithm services with dependency injection,
health monitoring, and INTEGRATION-OPUS compatibility.

Performance targets:
- Service response time: <100ms standard operations
- Health check response: <50ms
- Metrics collection: <10ms
- Error handling: Structured exceptions with fallback

Key features:
- Async-first design for non-blocking operations
- Pydantic models for request/response validation
- Comprehensive health monitoring
- Prometheus-compatible metrics
"""

import logging
import time
import asyncio
from abc import ABC, abstractmethod
from datetime import datetime
from typing import Dict, List, Optional, Any, Type, Generic, TypeVar
from dataclasses import dataclass, asdict
from enum import Enum
import uuid

from pydantic import BaseModel, Field
import redis

logger = logging.getLogger(__name__)

# Generic types for request/response
RequestType = TypeVar('RequestType', bound=BaseModel)
ResponseType = TypeVar('ResponseType', bound=BaseModel)


class ServiceStatus(Enum):
    """Service health status levels"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


class ErrorSeverity(Enum):
    """Error severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


@dataclass
class ServiceMetrics:
    """Service performance metrics"""
    service_name: str
    total_requests: int
    successful_requests: int
    failed_requests: int
    average_response_time_ms: float
    cache_hit_rate: float
    uptime_seconds: float
    last_updated: datetime


class ServiceRequest(BaseModel):
    """Base service request model"""
    request_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    user_id: Optional[int] = None
    priority: str = Field(default="normal")  # low, normal, high, critical
    timeout_seconds: Optional[int] = Field(default=30)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ServiceResponse(BaseModel):
    """Base service response model"""
    request_id: str
    success: bool
    response_time_ms: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    cache_hit: bool = Field(default=False)
    error_message: Optional[str] = None
    error_code: Optional[str] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class HealthStatus(BaseModel):
    """Service health status"""
    service_name: str
    status: ServiceStatus
    checks: Dict[str, bool]  # component_name -> healthy
    response_time_ms: float
    last_check: datetime
    uptime_seconds: float
    details: Optional[Dict[str, Any]] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ServiceException(Exception):
    """Standardized service exception"""
    
    def __init__(
        self,
        message: str,
        error_code: str = "SERVICE_ERROR",
        severity: ErrorSeverity = ErrorSeverity.ERROR,
        details: Optional[Dict[str, Any]] = None,
        cause: Optional[Exception] = None
    ):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.severity = severity
        self.details = details or {}
        self.cause = cause
        self.timestamp = datetime.utcnow()


class AlgorithmServiceBase(ABC, Generic[RequestType, ResponseType]):
    """Base class for all algorithm services"""
    
    def __init__(
        self,
        service_name: str,
        database_url: Optional[str] = None,
        redis_url: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None
    ):
        self.service_name = service_name
        self.service_id = str(uuid.uuid4())
        self.start_time = datetime.utcnow()
        
        # Configuration
        self.config = config or {}
        self.database_url = database_url
        self.redis_url = redis_url
        
        # Redis client (optional)
        self.redis_client = None
        if redis_url:
            try:
                self.redis_client = redis.from_url(redis_url, decode_responses=True)
                self.redis_client.ping()
                logger.info(f"{service_name} Redis client connected")
            except Exception as e:
                logger.warning(f"{service_name} Redis unavailable: {e}")
        
        # Service metrics
        self.metrics = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'total_response_time': 0.0,
            'cache_hits': 0,
            'cache_misses': 0,
            'start_time': datetime.utcnow()
        }
        
        # Performance targets
        self.response_time_target_ms = 100
        self.cache_hit_target = 0.7  # 70%
        
        logger.info(f"Service {service_name} initialized with ID: {self.service_id}")
    
    @abstractmethod
    async def process(self, request: RequestType) -> ResponseType:
        """Process service request - must be implemented by subclasses"""
        pass
    
    async def health_check(self) -> HealthStatus:
        """
        Comprehensive health check for the service.
        
        Returns:
            HealthStatus with component status and metrics
        """
        start_time = time.time()
        
        checks = {
            'service_ready': True,
            'redis_connected': False,
            'database_connected': False,
            'algorithm_ready': True
        }
        
        # Check Redis connection
        if self.redis_client:
            try:
                self.redis_client.ping()
                checks['redis_connected'] = True
            except Exception as e:
                logger.warning(f"Redis health check failed: {e}")
        
        # Check database connection (to be implemented by subclasses)
        try:
            checks['database_connected'] = await self._check_database_health()
        except Exception as e:
            logger.warning(f"Database health check failed: {e}")
        
        # Check algorithm health (to be implemented by subclasses)
        try:
            checks['algorithm_ready'] = await self._check_algorithm_health()
        except Exception as e:
            logger.warning(f"Algorithm health check failed: {e}")
        
        # Determine overall status
        critical_checks = ['service_ready', 'algorithm_ready']
        optional_checks = ['redis_connected', 'database_connected']
        
        if all(checks[check] for check in critical_checks):
            if all(checks[check] for check in optional_checks):
                status = ServiceStatus.HEALTHY
            else:
                status = ServiceStatus.DEGRADED
        else:
            status = ServiceStatus.UNHEALTHY
        
        # Calculate uptime
        uptime_seconds = (datetime.utcnow() - self.start_time).total_seconds()
        response_time_ms = (time.time() - start_time) * 1000
        
        return HealthStatus(
            service_name=self.service_name,
            status=status,
            checks=checks,
            response_time_ms=response_time_ms,
            last_check=datetime.utcnow(),
            uptime_seconds=uptime_seconds,
            details={
                'service_id': self.service_id,
                'redis_url': self.redis_url,
                'database_url': self.database_url,
                'config': self.config
            }
        )
    
    async def _check_database_health(self) -> bool:
        """Check database health - to be implemented by subclasses"""
        return True
    
    async def _check_algorithm_health(self) -> bool:
        """Check algorithm health - to be implemented by subclasses"""
        return True
    
    def get_metrics(self) -> ServiceMetrics:
        """
        Get service performance metrics.
        
        Returns:
            ServiceMetrics with current performance data
        """
        total_requests = self.metrics['total_requests']
        uptime_seconds = (datetime.utcnow() - self.start_time).total_seconds()
        
        # Calculate averages
        average_response_time = (
            self.metrics['total_response_time'] / max(1, total_requests)
        )
        
        cache_hit_rate = (
            self.metrics['cache_hits'] / 
            max(1, self.metrics['cache_hits'] + self.metrics['cache_misses'])
        )
        
        return ServiceMetrics(
            service_name=self.service_name,
            total_requests=total_requests,
            successful_requests=self.metrics['successful_requests'],
            failed_requests=self.metrics['failed_requests'],
            average_response_time_ms=average_response_time,
            cache_hit_rate=cache_hit_rate,
            uptime_seconds=uptime_seconds,
            last_updated=datetime.utcnow()
        )
    
    def get_prometheus_metrics(self) -> str:
        """
        Get metrics in Prometheus format.
        
        Returns:
            Prometheus-formatted metrics string
        """
        metrics = self.get_metrics()
        
        prometheus_lines = [
            f"# HELP service_requests_total Total number of requests processed",
            f"# TYPE service_requests_total counter",
            f'service_requests_total{{service="{self.service_name}"}} {metrics.total_requests}',
            f"",
            f"# HELP service_requests_successful_total Successful requests",
            f"# TYPE service_requests_successful_total counter", 
            f'service_requests_successful_total{{service="{self.service_name}"}} {metrics.successful_requests}',
            f"",
            f"# HELP service_response_time_ms Average response time in milliseconds",
            f"# TYPE service_response_time_ms gauge",
            f'service_response_time_ms{{service="{self.service_name}"}} {metrics.average_response_time_ms:.2f}',
            f"",
            f"# HELP service_cache_hit_rate Cache hit rate (0.0 to 1.0)",
            f"# TYPE service_cache_hit_rate gauge",
            f'service_cache_hit_rate{{service="{self.service_name}"}} {metrics.cache_hit_rate:.3f}',
            f"",
            f"# HELP service_uptime_seconds Service uptime in seconds",
            f"# TYPE service_uptime_seconds gauge",
            f'service_uptime_seconds{{service="{self.service_name}"}} {metrics.uptime_seconds:.0f}'
        ]
        
        return "\n".join(prometheus_lines)
    
    async def _execute_with_metrics(
        self,
        operation: str,
        func,
        *args,
        **kwargs
    ) -> Any:
        """
        Execute function with automatic metrics collection.
        
        Args:
            operation: Operation name for logging
            func: Function to execute
            *args: Function arguments
            **kwargs: Function keyword arguments
            
        Returns:
            Function result
        """
        start_time = time.time()
        self.metrics['total_requests'] += 1
        
        try:
            # Execute operation
            if asyncio.iscoroutinefunction(func):
                result = await func(*args, **kwargs)
            else:
                result = func(*args, **kwargs)
            
            # Success metrics
            self.metrics['successful_requests'] += 1
            
            # Check for cache hit (if result has cache_hit attribute)
            if hasattr(result, 'cache_hit') and result.cache_hit:
                self.metrics['cache_hits'] += 1
            else:
                self.metrics['cache_misses'] += 1
            
            return result
            
        except Exception as e:
            self.metrics['failed_requests'] += 1
            logger.error(f"Operation {operation} failed: {e}")
            raise
            
        finally:
            # Track response time
            response_time = (time.time() - start_time) * 1000
            self.metrics['total_response_time'] += response_time
            
            # Log performance warning if over target
            if response_time > self.response_time_target_ms:
                logger.warning(
                    f"Operation {operation} took {response_time:.1f}ms "
                    f"(target: {self.response_time_target_ms}ms)"
                )
    
    def _validate_request(self, request: RequestType) -> None:
        """
        Validate service request.
        
        Args:
            request: Request to validate
            
        Raises:
            ServiceException: If request is invalid
        """
        if not isinstance(request, BaseModel):
            raise ServiceException(
                "Invalid request format",
                error_code="INVALID_REQUEST",
                severity=ErrorSeverity.ERROR
            )
        
        # Check timeout
        if hasattr(request, 'timeout_seconds') and request.timeout_seconds:
            if request.timeout_seconds < 1 or request.timeout_seconds > 300:
                raise ServiceException(
                    "Invalid timeout value (must be 1-300 seconds)",
                    error_code="INVALID_TIMEOUT",
                    severity=ErrorSeverity.WARNING
                )
    
    def _create_error_response(
        self,
        request_id: str,
        exception: Exception,
        response_time_ms: float
    ) -> ServiceResponse:
        """
        Create standardized error response.
        
        Args:
            request_id: Original request ID
            exception: Exception that occurred
            response_time_ms: Response time
            
        Returns:
            ServiceResponse with error details
        """
        if isinstance(exception, ServiceException):
            error_message = exception.message
            error_code = exception.error_code
        else:
            error_message = str(exception)
            error_code = "INTERNAL_ERROR"
        
        return ServiceResponse(
            request_id=request_id,
            success=False,
            response_time_ms=response_time_ms,
            cache_hit=False,
            error_message=error_message,
            error_code=error_code
        )
    
    async def shutdown(self):
        """Graceful service shutdown"""
        logger.info(f"Shutting down service: {self.service_name}")
        
        # Close Redis connection
        if self.redis_client:
            try:
                await self.redis_client.close()
            except Exception as e:
                logger.warning(f"Error closing Redis connection: {e}")
        
        logger.info(f"Service {self.service_name} shutdown complete")


class ServiceDecorator:
    """Decorator for service methods to add automatic metrics and error handling"""
    
    def __init__(self, operation_name: str):
        self.operation_name = operation_name
    
    def __call__(self, func):
        async def wrapper(service_instance, *args, **kwargs):
            return await service_instance._execute_with_metrics(
                self.operation_name,
                func,
                service_instance,
                *args,
                **kwargs
            )
        return wrapper


# Decorator for easy use
def service_operation(operation_name: str):
    """Decorator for service operations with automatic metrics"""
    return ServiceDecorator(operation_name)


if __name__ == "__main__":
    # Demo usage - example service implementation
    class ExampleRequest(ServiceRequest):
        data: str
        count: int = Field(default=1)
    
    class ExampleResponse(ServiceResponse):
        result: str
        processed_count: int
    
    class ExampleService(AlgorithmServiceBase[ExampleRequest, ExampleResponse]):
        
        async def process(self, request: ExampleRequest) -> ExampleResponse:
            start_time = time.time()
            
            # Simulate processing
            await asyncio.sleep(0.01)  # 10ms processing time
            
            result = f"Processed: {request.data} x{request.count}"
            
            return ExampleResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=(time.time() - start_time) * 1000,
                result=result,
                processed_count=request.count
            )
    
    # Demo
    async def main():
        service = ExampleService("example_service")
        
        # Test request
        request = ExampleRequest(data="test_data", count=3)
        response = await service.process(request)
        
        print(f"Service Response:")
        print(f"  Success: {response.success}")
        print(f"  Result: {response.result}")
        print(f"  Response Time: {response.response_time_ms:.1f}ms")
        
        # Health check
        health = await service.health_check()
        print(f"\nHealth Status:")
        print(f"  Status: {health.status.value}")
        print(f"  Response Time: {health.response_time_ms:.1f}ms")
        print(f"  Uptime: {health.uptime_seconds:.0f}s")
        
        # Metrics
        metrics = service.get_metrics()
        print(f"\nService Metrics:")
        print(f"  Total Requests: {metrics.total_requests}")
        print(f"  Success Rate: {metrics.successful_requests}/{metrics.total_requests}")
        print(f"  Average Response Time: {metrics.average_response_time_ms:.1f}ms")
        print(f"  Cache Hit Rate: {metrics.cache_hit_rate:.1%}")
        
        # Prometheus metrics
        prometheus = service.get_prometheus_metrics()
        print(f"\nPrometheus Metrics (sample):")
        print(prometheus.split('\n')[2])  # Show one metric line
        
        await service.shutdown()
    
    # Run demo
    asyncio.run(main())