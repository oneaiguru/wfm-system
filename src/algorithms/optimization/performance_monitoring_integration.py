"""
Performance Validation Integration Module
========================================

Integrates algorithm performance metrics with DATABASE-OPUS monitoring 
and UI-OPUS dashboards for system-wide performance validation.

Supports load testing up to 100K calls/day with <100ms response times
and 80%+ cache efficiency across all algorithm operations.
"""

import time
import psutil
import threading
import asyncio
import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable, Any
from datetime import datetime, timedelta
from collections import deque, defaultdict
import numpy as np
import json

logger = logging.getLogger(__name__)


@dataclass
class PerformanceMetrics:
    """Algorithm-level performance metrics container."""
    
    # Core metrics
    calculation_time_ms: float = 0.0
    memory_usage_mb: float = 0.0
    cache_hit_rate: float = 0.0
    batch_processing_throughput: float = 0.0
    
    # System-level metrics
    end_to_end_latency: float = 0.0
    concurrent_user_capacity: int = 0
    daily_calculation_volume: int = 0
    accuracy_vs_performance_tradeoff: float = 0.0
    
    # Metadata
    timestamp: datetime = field(default_factory=datetime.utcnow)
    algorithm_type: str = ""
    operation_type: str = ""
    input_size: int = 0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert metrics to dictionary for serialization."""
        return {
            "calculation_time_ms": self.calculation_time_ms,
            "memory_usage_mb": self.memory_usage_mb,
            "cache_hit_rate": self.cache_hit_rate,
            "batch_processing_throughput": self.batch_processing_throughput,
            "end_to_end_latency": self.end_to_end_latency,
            "concurrent_user_capacity": self.concurrent_user_capacity,
            "daily_calculation_volume": self.daily_calculation_volume,
            "accuracy_vs_performance_tradeoff": self.accuracy_vs_performance_tradeoff,
            "timestamp": self.timestamp.isoformat(),
            "algorithm_type": self.algorithm_type,
            "operation_type": self.operation_type,
            "input_size": self.input_size
        }


class PerformanceMonitor:
    """
    Real-time performance monitoring for algorithm operations.
    
    Tracks execution times, memory usage, cache efficiency, and
    provides integration points for database and UI systems.
    """
    
    def __init__(self, 
                 max_history: int = 10000,
                 alert_thresholds: Optional[Dict[str, float]] = None):
        self.max_history = max_history
        self.metrics_history = deque(maxlen=max_history)
        self.current_metrics = {}
        self.alert_thresholds = alert_thresholds or self._default_thresholds()
        
        # Performance tracking
        self.operation_counts = defaultdict(int)
        self.operation_times = defaultdict(list)
        self.cache_stats = {"hits": 0, "misses": 0}
        
        # Real-time streaming
        self.subscribers = []
        self.streaming_active = False
        self.stream_thread = None
        
        # Alert callbacks
        self.alert_callbacks = []
        
    def _default_thresholds(self) -> Dict[str, float]:
        """Default performance alert thresholds."""
        return {
            "calculation_time_ms": 100.0,  # 95th percentile target
            "memory_usage_mb": 512.0,      # Memory usage limit
            "cache_hit_rate": 0.8,         # 80%+ cache efficiency
            "end_to_end_latency": 2000.0,  # 2 second max latency
            "cpu_usage_percent": 80.0,     # CPU usage threshold
            "concurrent_users": 1000       # Concurrent user limit
        }
    
    def start_monitoring(self):
        """Start real-time performance monitoring."""
        if not self.streaming_active:
            self.streaming_active = True
            self.stream_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
            self.stream_thread.start()
            logger.info("Performance monitoring started")
    
    def stop_monitoring(self):
        """Stop real-time performance monitoring."""
        self.streaming_active = False
        if self.stream_thread:
            self.stream_thread.join(timeout=5)
        logger.info("Performance monitoring stopped")
    
    def _monitoring_loop(self):
        """Background monitoring loop."""
        while self.streaming_active:
            try:
                # Collect system metrics
                system_metrics = self._collect_system_metrics()
                
                # Check thresholds
                self._check_alert_thresholds(system_metrics)
                
                # Notify subscribers
                self._notify_subscribers(system_metrics)
                
                time.sleep(1)  # 1-second monitoring interval
                
            except Exception as e:
                logger.error(f"Error in monitoring loop: {str(e)}")
                time.sleep(5)
    
    def _collect_system_metrics(self) -> Dict[str, Any]:
        """Collect current system performance metrics."""
        try:
            process = psutil.Process()
            
            return {
                "timestamp": datetime.utcnow(),
                "cpu_percent": process.cpu_percent(),
                "memory_mb": process.memory_info().rss / 1024 / 1024,
                "threads": process.num_threads(),
                "open_files": len(process.open_files()),
                "cache_hit_rate": self._calculate_cache_hit_rate(),
                "operations_per_second": self._calculate_ops_per_second(),
                "average_response_time": self._calculate_avg_response_time()
            }
        except Exception as e:
            logger.error(f"Error collecting system metrics: {str(e)}")
            return {}
    
    def _calculate_cache_hit_rate(self) -> float:
        """Calculate current cache hit rate."""
        total = self.cache_stats["hits"] + self.cache_stats["misses"]
        if total == 0:
            return 0.0
        return self.cache_stats["hits"] / total
    
    def _calculate_ops_per_second(self) -> float:
        """Calculate operations per second over last minute."""
        one_minute_ago = datetime.utcnow() - timedelta(minutes=1)
        recent_ops = sum(
            1 for metrics in self.metrics_history 
            if metrics.timestamp >= one_minute_ago
        )
        return recent_ops / 60.0
    
    def _calculate_avg_response_time(self) -> float:
        """Calculate average response time over last minute."""
        one_minute_ago = datetime.utcnow() - timedelta(minutes=1)
        recent_times = [
            metrics.calculation_time_ms for metrics in self.metrics_history 
            if metrics.timestamp >= one_minute_ago
        ]
        return np.mean(recent_times) if recent_times else 0.0


class PerformanceProfiler:
    """
    Context manager for profiling algorithm performance.
    
    Usage:
        with PerformanceProfiler(monitor, "erlang_c", "calculation") as profiler:
            result = calculate_erlang_c(params)
            profiler.set_result_size(len(result))
    """
    
    def __init__(self, 
                 monitor: PerformanceMonitor,
                 algorithm_type: str,
                 operation_type: str,
                 input_size: int = 0):
        self.monitor = monitor
        self.algorithm_type = algorithm_type
        self.operation_type = operation_type
        self.input_size = input_size
        self.start_time = None
        self.start_memory = None
        self.result_size = 0
        
    def __enter__(self):
        """Start profiling."""
        self.start_time = time.perf_counter()
        process = psutil.Process()
        self.start_memory = process.memory_info().rss / 1024 / 1024
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """End profiling and record metrics."""
        if self.start_time is None:
            return
        
        # Calculate metrics
        calculation_time = (time.perf_counter() - self.start_time) * 1000  # ms
        
        process = psutil.Process()
        current_memory = process.memory_info().rss / 1024 / 1024
        memory_delta = current_memory - self.start_memory
        
        # Create metrics object
        metrics = PerformanceMetrics(
            calculation_time_ms=calculation_time,
            memory_usage_mb=memory_delta,
            algorithm_type=self.algorithm_type,
            operation_type=self.operation_type,
            input_size=self.input_size
        )
        
        # Record metrics
        self.monitor.record_metrics(metrics)
        
        # Check for performance issues
        if calculation_time > 100:  # >100ms
            logger.warning(f"Slow operation: {self.algorithm_type}.{self.operation_type} "
                          f"took {calculation_time:.2f}ms")
    
    def set_result_size(self, size: int):
        """Set the size of operation result for throughput calculation."""
        self.result_size = size
    
    def record_cache_hit(self):
        """Record a cache hit."""
        self.monitor.cache_stats["hits"] += 1
    
    def record_cache_miss(self):
        """Record a cache miss."""
        self.monitor.cache_stats["misses"] += 1


class MetricsAggregator:
    """
    Aggregates performance metrics for reporting and analysis.
    
    Provides functions for DATABASE-OPUS integration and
    UI-OPUS dashboard data preparation.
    """
    
    def __init__(self, monitor: PerformanceMonitor):
        self.monitor = monitor
    
    async def aggregate_performance_trends(self, 
                                         time_range: timedelta) -> Dict[str, Any]:
        """
        Aggregate performance trends over specified time range.
        
        Args:
            time_range: Time period to analyze
            
        Returns:
            Aggregated performance data
        """
        cutoff_time = datetime.utcnow() - time_range
        
        # Filter metrics within time range
        relevant_metrics = [
            metrics for metrics in self.monitor.metrics_history
            if metrics.timestamp >= cutoff_time
        ]
        
        if not relevant_metrics:
            return {"error": "No metrics found in time range"}
        
        # Calculate aggregations
        calculation_times = [m.calculation_time_ms for m in relevant_metrics]
        memory_usage = [m.memory_usage_mb for m in relevant_metrics]
        cache_hits = [m.cache_hit_rate for m in relevant_metrics if m.cache_hit_rate > 0]
        
        return {
            "time_range_hours": time_range.total_seconds() / 3600,
            "total_operations": len(relevant_metrics),
            "performance_summary": {
                "avg_calculation_time_ms": np.mean(calculation_times),
                "p95_calculation_time_ms": np.percentile(calculation_times, 95),
                "p99_calculation_time_ms": np.percentile(calculation_times, 99),
                "max_calculation_time_ms": np.max(calculation_times),
                "avg_memory_usage_mb": np.mean(memory_usage),
                "peak_memory_usage_mb": np.max(memory_usage),
                "avg_cache_hit_rate": np.mean(cache_hits) if cache_hits else 0.0
            },
            "operation_breakdown": self._analyze_operations_by_type(relevant_metrics),
            "performance_trends": self._calculate_performance_trends(relevant_metrics),
            "threshold_violations": self._count_threshold_violations(relevant_metrics)
        }
    
    def _analyze_operations_by_type(self, metrics: List[PerformanceMetrics]) -> Dict[str, Any]:
        """Analyze performance by operation type."""
        by_algorithm = defaultdict(list)
        
        for metric in metrics:
            key = f"{metric.algorithm_type}.{metric.operation_type}"
            by_algorithm[key].append(metric)
        
        analysis = {}
        for op_type, op_metrics in by_algorithm.items():
            times = [m.calculation_time_ms for m in op_metrics]
            analysis[op_type] = {
                "count": len(op_metrics),
                "avg_time_ms": np.mean(times),
                "p95_time_ms": np.percentile(times, 95),
                "total_time_ms": np.sum(times)
            }
        
        return analysis
    
    def _calculate_performance_trends(self, metrics: List[PerformanceMetrics]) -> Dict[str, Any]:
        """Calculate performance trends over time."""
        if len(metrics) < 10:
            return {"trend": "insufficient_data"}
        
        # Sort by timestamp
        sorted_metrics = sorted(metrics, key=lambda m: m.timestamp)
        
        # Calculate trends
        times = [m.calculation_time_ms for m in sorted_metrics]
        memory = [m.memory_usage_mb for m in sorted_metrics]
        
        # Simple linear trend
        x = np.arange(len(times))
        time_trend = np.polyfit(x, times, 1)[0]  # slope
        memory_trend = np.polyfit(x, memory, 1)[0]  # slope
        
        return {
            "time_trend_ms_per_operation": time_trend,
            "memory_trend_mb_per_operation": memory_trend,
            "trend_direction": {
                "performance": "degrading" if time_trend > 0 else "improving",
                "memory": "increasing" if memory_trend > 0 else "stable"
            }
        }
    
    def _count_threshold_violations(self, metrics: List[PerformanceMetrics]) -> Dict[str, int]:
        """Count threshold violations."""
        violations = defaultdict(int)
        
        for metric in metrics:
            if metric.calculation_time_ms > self.monitor.alert_thresholds["calculation_time_ms"]:
                violations["slow_calculations"] += 1
            if metric.memory_usage_mb > self.monitor.alert_thresholds["memory_usage_mb"]:
                violations["high_memory"] += 1
            if metric.cache_hit_rate > 0 and metric.cache_hit_rate < self.monitor.alert_thresholds["cache_hit_rate"]:
                violations["low_cache_efficiency"] += 1
        
        return dict(violations)


class LoadTestHelper:
    """
    Helper functions for load testing algorithm performance.
    
    Supports testing scenarios up to 100K calls/day with
    concurrent user simulation and performance validation.
    """
    
    def __init__(self, monitor: PerformanceMonitor):
        self.monitor = monitor
        self.test_results = {}
    
    async def simulate_daily_load(self, 
                                calls_per_day: int = 100000,
                                peak_hours: List[int] = None) -> Dict[str, Any]:
        """
        Simulate daily call load with realistic distribution.
        
        Args:
            calls_per_day: Total calls to simulate
            peak_hours: Hours with peak load (defaults to 9-17)
            
        Returns:
            Load test results
        """
        peak_hours = peak_hours or list(range(9, 18))  # 9 AM to 5 PM
        
        # Distribute calls across 24 hours with peak concentration
        hourly_distribution = self._calculate_hourly_distribution(calls_per_day, peak_hours)
        
        test_start = datetime.utcnow()
        results = {
            "test_start": test_start,
            "calls_per_day": calls_per_day,
            "peak_hours": peak_hours,
            "hourly_results": {},
            "performance_summary": {}
        }
        
        total_processed = 0
        total_errors = 0
        all_response_times = []
        
        for hour, calls_in_hour in enumerate(hourly_distribution):
            logger.info(f"Simulating hour {hour}: {calls_in_hour} calls")
            
            hour_results = await self._simulate_hour_load(calls_in_hour, hour)
            results["hourly_results"][hour] = hour_results
            
            total_processed += hour_results["calls_processed"]
            total_errors += hour_results["errors"]
            all_response_times.extend(hour_results["response_times"])
        
        # Calculate overall performance
        results["performance_summary"] = {
            "total_calls_processed": total_processed,
            "total_errors": total_errors,
            "error_rate": total_errors / total_processed if total_processed > 0 else 0,
            "avg_response_time_ms": np.mean(all_response_times),
            "p95_response_time_ms": np.percentile(all_response_times, 95),
            "p99_response_time_ms": np.percentile(all_response_times, 99),
            "max_response_time_ms": np.max(all_response_times),
            "target_compliance": {
                "p95_under_100ms": np.percentile(all_response_times, 95) < 100,
                "error_rate_under_1pct": (total_errors / total_processed) < 0.01 if total_processed > 0 else False
            }
        }
        
        return results
    
    def _calculate_hourly_distribution(self, 
                                     total_calls: int, 
                                     peak_hours: List[int]) -> List[int]:
        """Calculate realistic hourly call distribution."""
        # Base distribution (all hours get minimum load)
        base_calls_per_hour = total_calls * 0.1 / 24  # 10% distributed evenly
        
        # Peak distribution (90% concentrated in peak hours)
        peak_calls_total = total_calls * 0.9
        peak_calls_per_hour = peak_calls_total / len(peak_hours)
        
        distribution = []
        for hour in range(24):
            if hour in peak_hours:
                calls = int(base_calls_per_hour + peak_calls_per_hour)
            else:
                calls = int(base_calls_per_hour)
            distribution.append(calls)
        
        return distribution
    
    async def _simulate_hour_load(self, calls_in_hour: int, hour: int) -> Dict[str, Any]:
        """Simulate load for a specific hour."""
        calls_per_minute = calls_in_hour / 60
        
        hour_start = time.time()
        calls_processed = 0
        errors = 0
        response_times = []
        
        # Simulate calls for this hour (compressed time)
        for minute in range(60):
            minute_calls = int(calls_per_minute)
            
            # Simulate concurrent calls within the minute
            tasks = []
            for call in range(minute_calls):
                task = self._simulate_single_call(f"hour_{hour}_min_{minute}_call_{call}")
                tasks.append(task)
            
            # Process calls concurrently
            if tasks:
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                for result in results:
                    if isinstance(result, Exception):
                        errors += 1
                    else:
                        calls_processed += 1
                        response_times.append(result["response_time_ms"])
        
        return {
            "hour": hour,
            "calls_processed": calls_processed,
            "errors": errors,
            "response_times": response_times,
            "duration_seconds": time.time() - hour_start
        }
    
    async def _simulate_single_call(self, call_id: str) -> Dict[str, Any]:
        """Execute a real algorithm call for load testing."""
        start_time = time.perf_counter()
        
        try:
            # Execute real Erlang C calculation with realistic parameters
            from ..core.erlang_c_enhanced import enhanced_erlang_c
            
            # Use realistic call center parameters
            agents = 10
            arrival_rate = 50  # calls per hour
            service_time = 6   # minutes average
            
            # Real calculation instead of sleep
            result = enhanced_erlang_c(agents, arrival_rate, service_time)
            
            response_time = (time.perf_counter() - start_time) * 1000
            
            return {
                "call_id": call_id,
                "response_time_ms": response_time,
                "success": True,
                "calculation_result": result
            }
        
        except Exception as e:
            return {
                "call_id": call_id,
                "error": str(e),
                "success": False
            }


class AlertManager:
    """
    Manages performance alerts and threshold monitoring.
    
    Integrates with UI-OPUS for real-time alerts and
    DATABASE-OPUS for alert persistence.
    """
    
    def __init__(self, monitor: PerformanceMonitor):
        self.monitor = monitor
        self.alert_history = deque(maxlen=1000)
        self.active_alerts = {}
        
    def check_thresholds(self, metrics: PerformanceMetrics) -> List[Dict[str, Any]]:
        """Check metrics against defined thresholds."""
        alerts = []
        thresholds = self.monitor.alert_thresholds
        
        # Check calculation time
        if metrics.calculation_time_ms > thresholds["calculation_time_ms"]:
            alerts.append({
                "type": "performance_degradation",
                "severity": "warning",
                "metric": "calculation_time_ms",
                "value": metrics.calculation_time_ms,
                "threshold": thresholds["calculation_time_ms"],
                "message": f"Calculation time {metrics.calculation_time_ms:.2f}ms exceeds threshold {thresholds['calculation_time_ms']}ms"
            })
        
        # Check memory usage
        if metrics.memory_usage_mb > thresholds["memory_usage_mb"]:
            alerts.append({
                "type": "resource_usage",
                "severity": "warning",
                "metric": "memory_usage_mb",
                "value": metrics.memory_usage_mb,
                "threshold": thresholds["memory_usage_mb"],
                "message": f"Memory usage {metrics.memory_usage_mb:.2f}MB exceeds threshold {thresholds['memory_usage_mb']}MB"
            })
        
        # Check cache efficiency
        if metrics.cache_hit_rate > 0 and metrics.cache_hit_rate < thresholds["cache_hit_rate"]:
            alerts.append({
                "type": "cache_efficiency",
                "severity": "warning",
                "metric": "cache_hit_rate",
                "value": metrics.cache_hit_rate,
                "threshold": thresholds["cache_hit_rate"],
                "message": f"Cache hit rate {metrics.cache_hit_rate:.2%} below threshold {thresholds['cache_hit_rate']:.2%}"
            })
        
        # Record alerts
        for alert in alerts:
            alert["timestamp"] = datetime.utcnow()
            alert["algorithm_type"] = metrics.algorithm_type
            alert["operation_type"] = metrics.operation_type
            self.alert_history.append(alert)
        
        return alerts


# Integration Points

def store_performance_metrics(metrics_batch: List[PerformanceMetrics]) -> bool:
    """
    DATABASE-OPUS Integration: Store performance metrics batch.
    
    Args:
        metrics_batch: Batch of performance metrics to store
        
    Returns:
        Success status
    """
    try:
        # This would integrate with DATABASE-OPUS storage
        # Placeholder for actual database integration
        logger.info(f"Storing {len(metrics_batch)} performance metrics to database")
        return True
    except Exception as e:
        logger.error(f"Error storing performance metrics: {str(e)}")
        return False


def query_historical_performance(time_range: timedelta) -> List[Dict[str, Any]]:
    """
    DATABASE-OPUS Integration: Query historical performance data.
    
    Args:
        time_range: Time period to query
        
    Returns:
        Historical performance data
    """
    try:
        # This would integrate with DATABASE-OPUS queries
        # Placeholder for actual database query
        logger.info(f"Querying historical performance for {time_range}")
        return []
    except Exception as e:
        logger.error(f"Error querying historical performance: {str(e)}")
        return []


def format_metrics_for_display(metrics: List[PerformanceMetrics]) -> Dict[str, Any]:
    """
    UI-OPUS Integration: Format metrics for dashboard display.
    
    Args:
        metrics: Performance metrics to format
        
    Returns:
        Formatted data for UI display
    """
    try:
        if not metrics:
            return {"error": "No metrics available"}
        
        # Format for UI consumption
        return {
            "summary": {
                "total_operations": len(metrics),
                "avg_response_time": np.mean([m.calculation_time_ms for m in metrics]),
                "cache_efficiency": np.mean([m.cache_hit_rate for m in metrics if m.cache_hit_rate > 0])
            },
            "time_series": [
                {
                    "timestamp": m.timestamp.isoformat(),
                    "response_time": m.calculation_time_ms,
                    "memory_usage": m.memory_usage_mb,
                    "operation": f"{m.algorithm_type}.{m.operation_type}"
                }
                for m in metrics[-100:]  # Last 100 operations
            ],
            "alerts": []  # Would include active alerts
        }
    except Exception as e:
        logger.error(f"Error formatting metrics for display: {str(e)}")
        return {"error": str(e)}


def real_time_performance_stream() -> Dict[str, Any]:
    """
    UI-OPUS Integration: Provide real-time performance data stream.
    
    Returns:
        Real-time performance data
    """
    try:
        # This would provide real-time streaming data for UI
        process = psutil.Process()
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "cpu_percent": process.cpu_percent(),
            "memory_mb": process.memory_info().rss / 1024 / 1024,
            "threads": process.num_threads(),
            "status": "healthy"
        }
    except Exception as e:
        logger.error(f"Error getting real-time performance: {str(e)}")
        return {"error": str(e)}


# Performance optimization recommendations
def generate_optimization_recommendations(metrics_history: List[PerformanceMetrics]) -> List[Dict[str, Any]]:
    """
    Generate performance optimization recommendations based on metrics analysis.
    
    Args:
        metrics_history: Historical performance metrics
        
    Returns:
        List of optimization recommendations
    """
    recommendations = []
    
    if not metrics_history:
        return recommendations
    
    # Analyze calculation times
    calc_times = [m.calculation_time_ms for m in metrics_history]
    avg_calc_time = np.mean(calc_times)
    p95_calc_time = np.percentile(calc_times, 95)
    
    if p95_calc_time > 100:
        recommendations.append({
            "type": "performance",
            "priority": "high",
            "issue": "Slow calculations",
            "recommendation": "Implement algorithm caching for repeated calculations",
            "impact": "Could reduce response times by 60-80%",
            "effort": "medium"
        })
    
    # Analyze memory usage
    memory_usage = [m.memory_usage_mb for m in metrics_history]
    if memory_usage and np.max(memory_usage) > 500:
        recommendations.append({
            "type": "resource",
            "priority": "medium",
            "issue": "High memory usage",
            "recommendation": "Implement object pooling for large data structures",
            "impact": "Could reduce memory usage by 30-50%",
            "effort": "medium"
        })
    
    # Analyze cache efficiency
    cache_rates = [m.cache_hit_rate for m in metrics_history if m.cache_hit_rate > 0]
    if cache_rates and np.mean(cache_rates) < 0.8:
        recommendations.append({
            "type": "caching",
            "priority": "high",
            "issue": "Low cache hit rate",
            "recommendation": "Optimize cache key strategy and increase cache size",
            "impact": "Could improve response times by 40-60%",
            "effort": "low"
        })
    
    return recommendations