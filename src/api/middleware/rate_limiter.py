"""
Advanced Rate Limiting Middleware for WFM Enterprise API
Redis-based rate limiting with multiple strategies and user-aware limiting
"""

import time
import json
from typing import Dict, Optional, Callable, Any
from datetime import datetime, timedelta
from enum import Enum

from fastapi import Request, Response, HTTPException, status
from fastapi.responses import JSONResponse
import redis.asyncio as redis
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
import asyncio
import hashlib

from ..auth.jwt_handler import jwt_handler


class RateLimitStrategy(str, Enum):
    """Rate limiting strategies"""
    FIXED_WINDOW = "fixed_window"
    SLIDING_WINDOW = "sliding_window"
    TOKEN_BUCKET = "token_bucket"
    LEAKY_BUCKET = "leaky_bucket"


class RateLimitConfig:
    """Rate limit configuration"""
    def __init__(
        self,
        max_requests: int = 100,
        window_seconds: int = 60,
        strategy: RateLimitStrategy = RateLimitStrategy.SLIDING_WINDOW,
        burst_capacity: Optional[int] = None,
        refill_rate: Optional[float] = None
    ):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.strategy = strategy
        self.burst_capacity = burst_capacity or max_requests
        self.refill_rate = refill_rate or (max_requests / window_seconds)


class RateLimiter:
    """Advanced rate limiter with multiple strategies"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        
        # Default rate limit configurations
        self.default_config = RateLimitConfig(
            max_requests=100,
            window_seconds=60,
            strategy=RateLimitStrategy.SLIDING_WINDOW
        )
        
        # Per-endpoint configurations
        self.endpoint_configs: Dict[str, RateLimitConfig] = {
            "/api/v1/auth/login": RateLimitConfig(
                max_requests=5,
                window_seconds=60,
                strategy=RateLimitStrategy.FIXED_WINDOW
            ),
            "/api/v1/auth/register": RateLimitConfig(
                max_requests=3,
                window_seconds=300,  # 5 minutes
                strategy=RateLimitStrategy.FIXED_WINDOW
            ),
            "/api/v1/auth/password-reset": RateLimitConfig(
                max_requests=3,
                window_seconds=3600,  # 1 hour
                strategy=RateLimitStrategy.FIXED_WINDOW
            ),
            "/api/v1/auth/token": RateLimitConfig(
                max_requests=10,
                window_seconds=60,
                strategy=RateLimitStrategy.SLIDING_WINDOW
            ),
            # Bulk operations
            "/api/v1/employees/bulk": RateLimitConfig(
                max_requests=5,
                window_seconds=300,
                strategy=RateLimitStrategy.TOKEN_BUCKET
            ),
            "/api/v1/schedules/bulk": RateLimitConfig(
                max_requests=3,
                window_seconds=600,
                strategy=RateLimitStrategy.TOKEN_BUCKET
            ),
            # Reporting endpoints
            "/api/v1/reports/generate": RateLimitConfig(
                max_requests=10,
                window_seconds=300,
                strategy=RateLimitStrategy.LEAKY_BUCKET
            ),
            # Integration endpoints
            "/api/v1/integrations/": RateLimitConfig(
                max_requests=50,
                window_seconds=60,
                strategy=RateLimitStrategy.SLIDING_WINDOW
            )
        }
        
        # Per-user type configurations
        self.user_type_configs: Dict[str, RateLimitConfig] = {
            "admin": RateLimitConfig(
                max_requests=1000,
                window_seconds=60,
                strategy=RateLimitStrategy.SLIDING_WINDOW
            ),
            "service": RateLimitConfig(
                max_requests=10000,
                window_seconds=60,
                strategy=RateLimitStrategy.TOKEN_BUCKET
            ),
            "guest": RateLimitConfig(
                max_requests=20,
                window_seconds=60,
                strategy=RateLimitStrategy.FIXED_WINDOW
            )
        }
    
    async def is_allowed(
        self,
        key: str,
        config: RateLimitConfig,
        request_cost: int = 1
    ) -> tuple[bool, Dict[str, Any]]:
        """Check if request is allowed based on rate limit configuration"""
        
        if config.strategy == RateLimitStrategy.FIXED_WINDOW:
            return await self._fixed_window_check(key, config, request_cost)
        elif config.strategy == RateLimitStrategy.SLIDING_WINDOW:
            return await self._sliding_window_check(key, config, request_cost)
        elif config.strategy == RateLimitStrategy.TOKEN_BUCKET:
            return await self._token_bucket_check(key, config, request_cost)
        elif config.strategy == RateLimitStrategy.LEAKY_BUCKET:
            return await self._leaky_bucket_check(key, config, request_cost)
        
        return False, {}
    
    async def _fixed_window_check(
        self,
        key: str,
        config: RateLimitConfig,
        request_cost: int
    ) -> tuple[bool, Dict[str, Any]]:
        """Fixed window rate limiting"""
        now = int(time.time())
        window_start = now - (now % config.window_seconds)
        redis_key = f"rate_limit:fixed:{key}:{window_start}"
        
        pipe = self.redis.pipeline()
        pipe.get(redis_key)
        pipe.incr(redis_key, request_cost)
        pipe.expire(redis_key, config.window_seconds)
        
        results = await pipe.execute()
        current_count = int(results[1])
        
        allowed = current_count <= config.max_requests
        
        reset_time = window_start + config.window_seconds
        
        return allowed, {
            "limit": config.max_requests,
            "remaining": max(0, config.max_requests - current_count),
            "reset": reset_time,
            "retry_after": reset_time - now if not allowed else None
        }
    
    async def _sliding_window_check(
        self,
        key: str,
        config: RateLimitConfig,
        request_cost: int
    ) -> tuple[bool, Dict[str, Any]]:
        """Sliding window rate limiting"""
        now = time.time()
        window_start = now - config.window_seconds
        redis_key = f"rate_limit:sliding:{key}"
        
        pipe = self.redis.pipeline()
        # Remove old entries
        pipe.zremrangebyscore(redis_key, 0, window_start)
        # Count current requests
        pipe.zcard(redis_key)
        # Add current request
        pipe.zadd(redis_key, {str(now): now})
        # Set expiration
        pipe.expire(redis_key, config.window_seconds)
        
        results = await pipe.execute()
        current_count = results[1]
        
        allowed = current_count + request_cost <= config.max_requests
        
        if not allowed:
            # Remove the request we just added
            await self.redis.zrem(redis_key, str(now))
        
        # Calculate reset time (when oldest request expires)
        oldest_requests = await self.redis.zrange(redis_key, 0, 0, withscores=True)
        reset_time = int(oldest_requests[0][1]) + config.window_seconds if oldest_requests else int(now) + config.window_seconds
        
        return allowed, {
            "limit": config.max_requests,
            "remaining": max(0, config.max_requests - current_count),
            "reset": reset_time,
            "retry_after": reset_time - int(now) if not allowed else None
        }
    
    async def _token_bucket_check(
        self,
        key: str,
        config: RateLimitConfig,
        request_cost: int
    ) -> tuple[bool, Dict[str, Any]]:
        """Token bucket rate limiting"""
        redis_key = f"rate_limit:bucket:{key}"
        now = time.time()
        
        # Get current bucket state
        bucket_data = await self.redis.hgetall(redis_key)
        
        if bucket_data:
            tokens = float(bucket_data.get("tokens", config.burst_capacity))
            last_refill = float(bucket_data.get("last_refill", now))
        else:
            tokens = config.burst_capacity
            last_refill = now
        
        # Calculate tokens to add
        time_passed = now - last_refill
        tokens_to_add = time_passed * config.refill_rate
        tokens = min(config.burst_capacity, tokens + tokens_to_add)
        
        allowed = tokens >= request_cost
        
        if allowed:
            tokens -= request_cost
        
        # Update bucket state
        await self.redis.hset(redis_key, mapping={
            "tokens": tokens,
            "last_refill": now
        })
        await self.redis.expire(redis_key, config.window_seconds)
        
        # Calculate retry after
        retry_after = None
        if not allowed:
            tokens_needed = request_cost - tokens
            retry_after = int(tokens_needed / config.refill_rate)
        
        return allowed, {
            "limit": config.max_requests,
            "remaining": int(tokens),
            "reset": int(now + (config.burst_capacity - tokens) / config.refill_rate),
            "retry_after": retry_after
        }
    
    async def _leaky_bucket_check(
        self,
        key: str,
        config: RateLimitConfig,
        request_cost: int
    ) -> tuple[bool, Dict[str, Any]]:
        """Leaky bucket rate limiting"""
        redis_key = f"rate_limit:leaky:{key}"
        now = time.time()
        
        # Get current bucket state
        bucket_data = await self.redis.hgetall(redis_key)
        
        if bucket_data:
            volume = float(bucket_data.get("volume", 0))
            last_leak = float(bucket_data.get("last_leak", now))
        else:
            volume = 0
            last_leak = now
        
        # Calculate volume to leak
        time_passed = now - last_leak
        volume_to_leak = time_passed * config.refill_rate
        volume = max(0, volume - volume_to_leak)
        
        allowed = volume + request_cost <= config.burst_capacity
        
        if allowed:
            volume += request_cost
        
        # Update bucket state
        await self.redis.hset(redis_key, mapping={
            "volume": volume,
            "last_leak": now
        })
        await self.redis.expire(redis_key, config.window_seconds)
        
        # Calculate retry after
        retry_after = None
        if not allowed:
            excess_volume = volume + request_cost - config.burst_capacity
            retry_after = int(excess_volume / config.refill_rate)
        
        return allowed, {
            "limit": config.max_requests,
            "remaining": int(config.burst_capacity - volume),
            "reset": int(now + volume / config.refill_rate),
            "retry_after": retry_after
        }
    
    def get_config_for_endpoint(self, path: str, user_type: str = "regular") -> RateLimitConfig:
        """Get rate limit configuration for endpoint"""
        # Check user type first
        if user_type in self.user_type_configs:
            return self.user_type_configs[user_type]
        
        # Check specific endpoint
        if path in self.endpoint_configs:
            return self.endpoint_configs[path]
        
        # Check pattern matching
        for pattern, config in self.endpoint_configs.items():
            if path.startswith(pattern):
                return config
        
        return self.default_config
    
    def get_client_identifier(self, request: Request) -> str:
        """Get client identifier for rate limiting"""
        # Try to get user ID from token
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = jwt_handler.decode_token(token)
                return f"user:{payload.get('sub')}"
            except:
                pass
        
        # Try API key
        api_key = request.headers.get("X-API-Key")
        if api_key:
            # Hash the API key for privacy
            key_hash = hashlib.sha256(api_key.encode()).hexdigest()[:16]
            return f"api_key:{key_hash}"
        
        # Fall back to IP address
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            client_ip = forwarded_for.split(",")[0].strip()
        else:
            client_ip = request.client.host
        
        return f"ip:{client_ip}"
    
    def get_user_type(self, request: Request) -> str:
        """Determine user type from request"""
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = jwt_handler.decode_token(token)
                
                # Check token type
                token_type = payload.get("type")
                if token_type in ["service", "api_key"]:
                    return "service"
                
                # Check user scopes
                scopes = payload.get("scopes", [])
                if "admin" in scopes or "superuser" in scopes:
                    return "admin"
                
                return "regular"
            except:
                pass
        
        return "guest"


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limiting middleware"""
    
    def __init__(self, app: ASGIApp, redis_url: str = "redis://localhost:6379"):
        super().__init__(app)
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None
        self.rate_limiter: Optional[RateLimiter] = None
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request with rate limiting"""
        # Initialize Redis connection if needed
        if not self.redis_client:
            self.redis_client = await redis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True
            )
            self.rate_limiter = RateLimiter(self.redis_client)
        
        # Skip rate limiting for health checks
        if request.url.path in ["/health", "/api/health", "/api/v1/health"]:
            return await call_next(request)
        
        # Get client identifier and user type
        client_id = self.rate_limiter.get_client_identifier(request)
        user_type = self.rate_limiter.get_user_type(request)
        
        # Get rate limit configuration
        config = self.rate_limiter.get_config_for_endpoint(request.url.path, user_type)
        
        # Check rate limit
        rate_limit_key = f"{client_id}:{request.url.path}"
        
        # Calculate request cost (some endpoints cost more)
        request_cost = self._calculate_request_cost(request)
        
        allowed, rate_info = await self.rate_limiter.is_allowed(
            rate_limit_key,
            config,
            request_cost
        )
        
        if not allowed:
            # Rate limit exceeded
            response = JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "error": "Rate limit exceeded",
                    "message": f"Too many requests. Try again in {rate_info.get('retry_after', 60)} seconds.",
                    "limit": rate_info.get("limit"),
                    "remaining": rate_info.get("remaining"),
                    "reset": rate_info.get("reset")
                }
            )
            
            # Add rate limit headers
            response.headers["X-RateLimit-Limit"] = str(rate_info.get("limit"))
            response.headers["X-RateLimit-Remaining"] = str(rate_info.get("remaining"))
            response.headers["X-RateLimit-Reset"] = str(rate_info.get("reset"))
            
            if rate_info.get("retry_after"):
                response.headers["Retry-After"] = str(rate_info.get("retry_after"))
            
            return response
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers to successful responses
        response.headers["X-RateLimit-Limit"] = str(rate_info.get("limit"))
        response.headers["X-RateLimit-Remaining"] = str(rate_info.get("remaining"))
        response.headers["X-RateLimit-Reset"] = str(rate_info.get("reset"))
        
        return response
    
    def _calculate_request_cost(self, request: Request) -> int:
        """Calculate cost of request (some operations cost more)"""
        # Bulk operations cost more
        if "bulk" in request.url.path:
            return 5
        
        # Report generation costs more
        if "reports" in request.url.path and request.method == "POST":
            return 3
        
        # Integration endpoints cost more
        if "integrations" in request.url.path:
            return 2
        
        # Default cost
        return 1
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.redis_client:
            await self.redis_client.close()


# Decorator for endpoint-specific rate limiting
def rate_limit(
    max_requests: int,
    window_seconds: int,
    strategy: RateLimitStrategy = RateLimitStrategy.SLIDING_WINDOW,
    per_user: bool = True
):
    """Decorator for endpoint-specific rate limiting"""
    def decorator(func):
        # Store rate limit config in function metadata
        func._rate_limit_config = RateLimitConfig(
            max_requests=max_requests,
            window_seconds=window_seconds,
            strategy=strategy
        )
        func._rate_limit_per_user = per_user
        return func
    return decorator