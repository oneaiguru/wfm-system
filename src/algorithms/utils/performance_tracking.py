"""Track algorithm performance without optimizing"""

import time
import functools
from datetime import datetime
import psycopg2
import psycopg2.extras
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)


class PerformanceTracker:
    """Track algorithm performance without optimizing"""
    
    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.warning_threshold = 2.0  # seconds
        self.critical_threshold = 10.0  # seconds
        self._ensure_table_exists()
        
    def _ensure_table_exists(self):
        """Ensure the performance tracking table exists"""
        # Table already exists in the database with a specific structure
        # No need to create it
        pass
        
    def track_performance(self, algorithm_name: str):
        """Decorator to track execution time"""
        def decorator(func):
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                start_time = time.time()
                input_params = {
                    'args_count': len(args),
                    'kwargs_keys': list(kwargs.keys())
                }
                
                try:
                    result = func(*args, **kwargs)
                    execution_time = time.time() - start_time
                    
                    # Determine result size
                    result_size = 0
                    if isinstance(result, (list, dict)):
                        result_size = len(result)
                    elif isinstance(result, str):
                        result_size = len(result)
                    elif hasattr(result, '__len__'):
                        result_size = len(result)
                    
                    # Log to database
                    self._log_performance(
                        algorithm_name=algorithm_name,
                        function_name=func.__name__,
                        execution_time_ms=int(execution_time * 1000),
                        status='success',
                        input_params=input_params,
                        result_size=result_size
                    )
                    
                    # Warning if slow (but don't optimize yet)
                    if execution_time > self.critical_threshold:
                        logger.critical(
                            f"🚨 CRITICAL PERFORMANCE: {algorithm_name}.{func.__name__} "
                            f"took {execution_time:.2f}s (critical threshold: {self.critical_threshold}s)\n"
                            f"  Input params: {input_params}\n"
                            f"  Result size: {result_size}\n"
                            f"  Note: DO NOT OPTIMIZE YET - just tracking for now"
                        )
                    elif execution_time > self.warning_threshold:
                        logger.warning(
                            f"⚠️ PERFORMANCE WARNING: {algorithm_name}.{func.__name__} "
                            f"took {execution_time:.2f}s (warning threshold: {self.warning_threshold}s)\n"
                            f"  Note: DO NOT OPTIMIZE YET - just tracking for now"
                        )
                    
                    return result
                    
                except Exception as e:
                    execution_time = time.time() - start_time
                    self._log_performance(
                        algorithm_name=algorithm_name,
                        function_name=func.__name__,
                        execution_time_ms=int(execution_time * 1000),
                        status='error',
                        error_message=str(e),
                        input_params=input_params
                    )
                    raise
                    
            return wrapper
        return decorator
    
    def _log_performance(self, **kwargs):
        """Log to query_performance_log table"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor()
            
            # Generate a simple hash for the query
            import hashlib
            query_text = f"{kwargs.get('algorithm_name')}.{kwargs.get('function_name')}"
            query_hash = hashlib.md5(query_text.encode()).hexdigest()
            
            # Insert into existing table structure
            cur.execute("""
                INSERT INTO query_performance_log 
                (query_hash, query_text, execution_time_ms, rows_returned, optimization_suggestions)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                query_hash,
                query_text,
                kwargs.get('execution_time_ms'),
                kwargs.get('result_size', 0),
                f"Status: {kwargs.get('status')}; " + 
                (f"Error: {kwargs.get('error_message')}" if kwargs.get('error_message') else 
                 f"Params: {kwargs.get('input_params', {})}")
            ))
            
            conn.commit()
            cur.close()
            conn.close()
            
        except Exception as e:
            logger.error(f"Failed to log performance: {e}")
    
    def get_slow_queries(self, days: int = 7, threshold_ms: int = 2000) -> list:
        """Get queries that exceed the threshold"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            cur.execute("""
                SELECT 
                    table_name as algorithm,
                    query_text as function,
                    AVG(execution_time_ms) as avg_ms,
                    MAX(execution_time_ms) as max_ms,
                    MIN(execution_time_ms) as min_ms,
                    COUNT(*) as executions,
                    COUNT(CASE WHEN operation_type = 'error' THEN 1 END) as errors
                FROM query_performance_log
                WHERE timestamp > NOW() - INTERVAL '%s days'
                GROUP BY table_name, query_text
                HAVING AVG(execution_time_ms) > %s
                ORDER BY avg_ms DESC
            """, (days, threshold_ms))
            
            results = cur.fetchall()
            cur.close()
            conn.close()
            
            return results
            
        except Exception as e:
            logger.error(f"Failed to get slow queries: {e}")
            return []
    
    def get_performance_summary(self, algorithm_name: str, days: int = 7) -> Dict[str, Any]:
        """Get performance summary for a specific algorithm"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Overall stats
            cur.execute("""
                SELECT 
                    COUNT(*) as total_executions,
                    AVG(execution_time_ms) as avg_time_ms,
                    MIN(execution_time_ms) as min_time_ms,
                    MAX(execution_time_ms) as max_time_ms,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) as median_time_ms,
                    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_time_ms,
                    COUNT(CASE WHEN operation_type = 'error' THEN 1 END) as error_count
                FROM query_performance_log
                WHERE table_name = %s
                AND timestamp > NOW() - INTERVAL '%s days'
            """, (algorithm_name, days))
            
            overall_stats = cur.fetchone()
            
            # Function-level breakdown
            cur.execute("""
                SELECT 
                    query_text as function,
                    COUNT(*) as executions,
                    AVG(execution_time_ms) as avg_ms,
                    MAX(execution_time_ms) as max_ms
                FROM query_performance_log
                WHERE table_name = %s
                AND timestamp > NOW() - INTERVAL '%s days'
                GROUP BY query_text
                ORDER BY avg_ms DESC
            """, (algorithm_name, days))
            
            function_stats = cur.fetchall()
            
            cur.close()
            conn.close()
            
            return {
                'algorithm': algorithm_name,
                'period_days': days,
                'overall': overall_stats,
                'by_function': function_stats
            }
            
        except Exception as e:
            logger.error(f"Failed to get performance summary: {e}")
            return {}


# Initialize global tracker
tracker = PerformanceTracker({
    'host': 'localhost',
    'database': 'wfm_enterprise',
    'user': 'postgres',
    'password': 'password'
})