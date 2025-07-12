import time
from fastapi import Request
from prometheus_client import Counter, Histogram, Gauge
from starlette.middleware.base import BaseHTTPMiddleware

request_count = Counter(
    "http_requests_total", 
    "Total HTTP requests", 
    ["method", "endpoint", "status"]
)

request_duration = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration",
    ["method", "endpoint"]
)

active_requests = Gauge(
    "http_requests_active",
    "Active HTTP requests"
)


class MonitoringMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        active_requests.inc()
        start_time = time.time()
        
        try:
            response = await call_next(request)
            duration = time.time() - start_time
            
            request_count.labels(
                method=request.method,
                endpoint=request.url.path,
                status=response.status_code
            ).inc()
            
            request_duration.labels(
                method=request.method,
                endpoint=request.url.path
            ).observe(duration)
            
            response.headers["X-Process-Time"] = str(duration)
            return response
        finally:
            active_requests.dec()