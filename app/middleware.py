"""
HTTP Request/Response Logging Middleware
"""
from fastapi import Request
from fastapi.responses import JSONResponse
from .routers.business_metrics import metrics
import time


async def log_requests_middleware(request: Request, call_next):
    """Middleware to log all HTTP requests and responses"""
    start_time = time.time()
    
    # Extract request details
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")
    
    # Log incoming request
    metrics.log_http_request(
        method=request.method,
        path=request.url.path,
        client_ip=client_ip,
        user_agent=user_agent,
        headers={
            "host": request.headers.get("host"),
            "content-type": request.headers.get("content-type"),
            "referer": request.headers.get("referer"),
        },
        query_params=str(request.query_params) if request.query_params else None
    )
    
    # Process request
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        
        # Log response
        metrics.log_http_response(
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_seconds=duration,
            client_ip=client_ip
        )
        
        return response
        
    except Exception as e:
        duration = time.time() - start_time
        
        # Log error
        metrics.log_http_error(
            method=request.method,
            path=request.url.path,
            error=str(e),
            error_type=type(e).__name__,
            duration_seconds=duration,
            client_ip=client_ip
        )
        
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )
