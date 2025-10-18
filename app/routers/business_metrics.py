"""
Business Metrics and Structured Logging Module
Tracks application events, user actions, and business KPIs
"""
import logging
import json
import time
from typing import Dict, Any, Optional
from datetime import datetime

# Configure logger
logger = logging.getLogger("workout-api")


class BusinessMetrics:
    """Centralized business metrics and event logging"""
    
    @staticmethod
    def log_event(event_type: str, data: Dict[str, Any]):
        """
        Log a structured event as JSON
        
        Args:
            event_type: Type of event (e.g., 'http_request', 'business_metric')
            data: Dictionary with event details
        """
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "event_type": event_type,
            "app": "workout-api",
            **data
        }
        logger.info(json.dumps(log_entry))
    
    # ==========================================
    # HTTP Request/Response Logging
    # ==========================================
    
    @staticmethod
    def log_http_request(
        method: str,
        path: str,
        client_ip: str,
        user_agent: str,
        headers: Dict[str, Any],
        query_params: Optional[str] = None,
        user_id: Optional[str] = None
    ):
        """Log incoming HTTP request"""
        BusinessMetrics.log_event("http_request", {
            "method": method,
            "path": path,
            "query_params": query_params,
            "client_ip": client_ip,
            "user_agent": user_agent,
            "user_id": user_id,
            "headers": headers
        })
    
    @staticmethod
    def log_http_response(
        method: str,
        path: str,
        status_code: int,
        duration_seconds: float,
        client_ip: str,
        user_id: Optional[str] = None
    ):
        """Log HTTP response with timing"""
        BusinessMetrics.log_event("http_response", {
            "method": method,
            "path": path,
            "status_code": status_code,
            "duration_seconds": round(duration_seconds, 3),
            "client_ip": client_ip,
            "user_id": user_id,
            "success": status_code < 400
        })
    
    @staticmethod
    def log_http_error(
        method: str,
        path: str,
        error: str,
        error_type: str,
        duration_seconds: float,
        client_ip: str,
        user_id: Optional[str] = None
    ):
        """Log HTTP error"""
        BusinessMetrics.log_event("http_error", {
            "method": method,
            "path": path,
            "error": error,
            "error_type": error_type,
            "duration_seconds": round(duration_seconds, 3),
            "client_ip": client_ip,
            "user_id": user_id
        })
    
    # ==========================================
    # User Authentication Events
    # ==========================================
    
    @staticmethod
    def log_user_login(user_id: str, email: str, client_ip: str, success: bool = True):
        """Log user login attempt"""
        BusinessMetrics.log_event("user_login", {
            "user_id": user_id,
            "email": email,
            "client_ip": client_ip,
            "success": success
        })
    
    @staticmethod
    def log_user_registration(user_id: str, email: str, client_ip: str):
        """Log new user registration"""
        BusinessMetrics.log_event("user_registration", {
            "user_id": user_id,
            "email": email,
            "client_ip": client_ip
        })
    
    @staticmethod
    def log_user_logout(user_id: str, client_ip: str):
        """Log user logout"""
        BusinessMetrics.log_event("user_logout", {
            "user_id": user_id,
            "client_ip": client_ip
        })
    
    # ==========================================
    # Workout Events
    # ==========================================
    
    @staticmethod
    def log_workout_created(
        user_id: str,
        workout_id: str,
        workout_type: Optional[str] = None,
        exercises_count: int = 0,
        duration_minutes: Optional[int] = None,
        difficulty: Optional[str] = None
    ):
        """Log workout creation"""
        BusinessMetrics.log_event("workout_created", {
            "metric_name": "workout_created",
            "user_id": user_id,
            "workout_id": workout_id,
            "workout_type": workout_type,
            "exercises_count": exercises_count,
            "duration_minutes": duration_minutes,
            "difficulty": difficulty
        })
    
    @staticmethod
    def log_workout_completed(
        user_id: str,
        workout_id: str,
        total_sets: int,
        total_reps: int,
        total_volume: float,
        duration_minutes: int,
        difficulty: Optional[str] = None
    ):
        """Log workout completion"""
        BusinessMetrics.log_event("workout_completed", {
            "metric_name": "workout_completed",
            "user_id": user_id,
            "workout_id": workout_id,
            "total_sets": total_sets,
            "total_reps": total_reps,
            "total_volume": total_volume,
            "duration_minutes": duration_minutes,
            "difficulty": difficulty
        })
    
    @staticmethod
    def log_workout_viewed(user_id: str, workout_id: str, workout_type: Optional[str] = None):
        """Log workout view"""
        BusinessMetrics.log_event("workout_viewed", {
            "metric_name": "workout_viewed",
            "user_id": user_id,
            "workout_id": workout_id,
            "workout_type": workout_type
        })
    
    @staticmethod
    def log_workout_deleted(user_id: str, workout_id: str):
        """Log workout deletion"""
        BusinessMetrics.log_event("workout_deleted", {
            "metric_name": "workout_deleted",
            "user_id": user_id,
            "workout_id": workout_id
        })
    
    @staticmethod
    def log_workout_generation_failed(user_id: str, error: str):
        """Log failed workout generation"""
        BusinessMetrics.log_event("workout_generation_failed", {
            "metric_name": "workout_generation_failed",
            "user_id": user_id,
            "error": error
        })
    
    # ==========================================
    # Plan Events
    # ==========================================
    
    @staticmethod
    def log_plan_created(
        user_id: str,
        plan_id: str,
        plan_type: Optional[str] = None,
        weeks: Optional[int] = None
    ):
        """Log training plan creation"""
        BusinessMetrics.log_event("plan_created", {
            "metric_name": "plan_created",
            "user_id": user_id,
            "plan_id": plan_id,
            "plan_type": plan_type,
            "weeks": weeks
        })
    
    @staticmethod
    def log_plan_viewed(user_id: str, plan_id: str):
        """Log plan view"""
        BusinessMetrics.log_event("plan_viewed", {
            "metric_name": "plan_viewed",
            "user_id": user_id,
            "plan_id": plan_id
        })
    
    # ==========================================
    # Database Events
    # ==========================================
    
    @staticmethod
    def log_db_query(collection: str, operation: str, duration_ms: float, success: bool = True):
        """Log database operation"""
        BusinessMetrics.log_event("db_query", {
            "collection": collection,
            "operation": operation,
            "duration_ms": round(duration_ms, 2),
            "success": success
        })
    
    @staticmethod
    def log_db_error(collection: str, operation: str, error: str):
        """Log database error"""
        BusinessMetrics.log_event("db_error", {
            "collection": collection,
            "operation": operation,
            "error": error
        })
    
    # ==========================================
    # System Events
    # ==========================================
    
    @staticmethod
    def log_health_check(status: str = "ok"):
        """Log health check"""
        BusinessMetrics.log_event("health_check", {"status": status})
    
    @staticmethod
    def log_startup():
        """Log application startup"""
        BusinessMetrics.log_event("app_startup", {
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })
    
    @staticmethod
    def log_shutdown():
        """Log application shutdown"""
        BusinessMetrics.log_event("app_shutdown", {
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })


# Export singleton instance
metrics = BusinessMetrics()