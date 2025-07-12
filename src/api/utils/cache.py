import json
import hashlib
from functools import wraps
from typing import Any, Callable
import redis.asyncio as redis
from src.api.core.config import settings

redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def generate_cache_key(prefix: str, *args, **kwargs) -> str:
    """Generate a unique cache key based on function arguments."""
    key_data = {
        "args": args,
        "kwargs": kwargs
    }
    key_hash = hashlib.md5(json.dumps(key_data, sort_keys=True).encode()).hexdigest()
    return f"{settings.CACHE_KEY_PREFIX}{prefix}:{key_hash}"


def cache_decorator(expire: int = 300):
    """
    Decorator for caching function results in Redis.
    
    Args:
        expire: Cache expiration time in seconds
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            # Generate cache key
            cache_key = generate_cache_key(func.__name__, *args, **kwargs)
            
            # Try to get from cache
            try:
                cached_result = await redis_client.get(cache_key)
                if cached_result:
                    return json.loads(cached_result)
            except Exception as e:
                # Log error but continue without cache
                pass
            
            # Execute function
            result = await func(*args, **kwargs)
            
            # Store in cache
            try:
                await redis_client.setex(
                    cache_key,
                    expire,
                    json.dumps(result, default=str)
                )
            except Exception as e:
                # Log error but return result anyway
                pass
            
            return result
        
        return wrapper
    return decorator


async def invalidate_cache_pattern(pattern: str):
    """Invalidate all cache keys matching a pattern."""
    async for key in redis_client.scan_iter(match=f"{settings.CACHE_KEY_PREFIX}{pattern}*"):
        await redis_client.delete(key)