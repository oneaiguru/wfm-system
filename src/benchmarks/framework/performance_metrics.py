#!/usr/bin/env python3
"""
Performance Metrics Collection System
====================================

Comprehensive metrics collection and analysis for enterprise-scale benchmarking
with focus on algorithm performance, Redis optimization, and system resource usage.

BDD Source: Task 11 - Performance metrics collection for 1,173 table scale testing
Targets: Sub-millisecond metric collection, comprehensive analysis, regression detection

Key features:
- Real-time metrics collection
- Statistical analysis with percentiles
- Performance regression detection
- Resource usage monitoring
"""

import time
import statistics
import psutil
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json
import asyncio

class MetricType(Enum):
    """Types of performance metrics"""
    EXECUTION_TIME = "execution_time"
    MEMORY_USAGE = "memory_usage"
    CPU_USAGE = "cpu_usage"
    CACHE_HIT_RATE = "cache_hit_rate"
    THROUGHPUT = "throughput"
    ERROR_RATE = "error_rate"
    RESPONSE_TIME = "response_time"
    DATABASE_QUERY_TIME = "database_query_time"
    REDIS_OPERATION_TIME = "redis_operation_time"


@dataclass
class PerformanceMetrics:
    """Core performance metrics data structure"""
    timestamp: datetime = field(default_factory=datetime.now)
    execution_time_ms: float = 0.0
    memory_usage_mb: float = 0.0
    memory_usage_gb: float = 0.0
    cpu_usage_percent: float = 0.0
    cache_hit_rate: float = 0.0
    throughput_ops_per_sec: float = 0.0
    error_rate_percent: float = 0.0
    response_time_ms: float = 0.0
    database_query_time_ms: float = 0.0
    redis_operation_time_ms: float = 0.0
    concurrent_connections: int = 0
    active_threads: int = 0
    heap_usage_mb: float = 0.0
    gc_collections: int = 0
    network_io_bytes: int = 0
    disk_io_bytes: int = 0
    
    def __post_init__(self):
        """Calculate derived metrics"""
        if self.memory_usage_mb > 0:
            self.memory_usage_gb = self.memory_usage_mb / 1024.0


@dataclass 
class BenchmarkResult:
    """Complete benchmark result with statistical analysis"""
    test_name: str
    start_time: datetime
    end_time: datetime
    total_duration_seconds: float
    
    # Execution metrics
    total_operations: int = 0
    successful_operations: int = 0
    failed_operations: int = 0
    
    # Timing statistics
    average_time_ms: float = 0.0
    median_time_ms: float = 0.0
    p95_time_ms: float = 0.0
    p99_time_ms: float = 0.0
    min_time_ms: float = 0.0
    max_time_ms: float = 0.0
    std_deviation_ms: float = 0.0
    
    # Resource usage
    peak_memory_mb: float = 0.0
    average_memory_mb: float = 0.0
    peak_cpu_percent: float = 0.0
    average_cpu_percent: float = 0.0
    
    # Efficiency metrics
    throughput_ops_per_sec: float = 0.0
    cache_hit_rate: float = 0.0
    error_rate_percent: float = 0.0
    
    # Detailed data
    all_execution_times: List[float] = field(default_factory=list)
    resource_snapshots: List[PerformanceMetrics] = field(default_factory=list)
    error_details: List[Dict[str, Any]] = field(default_factory=list)
    
    # Performance targets compliance
    meets_performance_targets: bool = False
    target_violations: List[str] = field(default_factory=list)


class PerformanceMetricsCollector:
    """Real-time performance metrics collection system"""
    
    def __init__(self, collection_interval_ms: float = 100.0):
        self.collection_interval_ms = collection_interval_ms
        self.collection_active = False
        self.metrics_history: List[PerformanceMetrics] = []
        self.current_session_start: Optional[datetime] = None
        
        # System baseline metrics
        self.baseline_metrics: Optional[PerformanceMetrics] = None
        self.process = psutil.Process()
        
    async def start_collection_session(self) -> datetime:
        """Start a new metrics collection session"""
        self.current_session_start = datetime.now()
        self.collection_active = True
        self.metrics_history = []
        
        # Collect baseline metrics
        self.baseline_metrics = await self.collect_current_metrics()
        
        # Start background collection task
        asyncio.create_task(self._background_collection())
        
        return self.current_session_start
    
    async def stop_collection_session(self) -> BenchmarkResult:
        """Stop metrics collection and return analysis"""
        self.collection_active = False
        end_time = datetime.now()
        
        if not self.current_session_start:
            raise ValueError("No active collection session")
        
        duration = (end_time - self.current_session_start).total_seconds()
        
        # Analyze collected metrics
        result = BenchmarkResult(
            test_name="metrics_collection_session",
            start_time=self.current_session_start,
            end_time=end_time,
            total_duration_seconds=duration,
            resource_snapshots=self.metrics_history.copy()
        )
        
        if self.metrics_history:
            result = self._analyze_metrics_history(result)
        
        return result
    
    async def collect_current_metrics(self) -> PerformanceMetrics:
        """Collect current system performance metrics"""
        
        # System metrics
        memory_info = self.process.memory_info()
        cpu_percent = self.process.cpu_percent()
        
        # System-wide metrics
        system_memory = psutil.virtual_memory()
        system_cpu = psutil.cpu_percent(interval=0.1)
        
        # Network and disk I/O
        net_io = psutil.net_io_counters()
        disk_io = psutil.disk_io_counters()
        
        metrics = PerformanceMetrics(
            timestamp=datetime.now(),
            memory_usage_mb=memory_info.rss / 1024 / 1024,  # Convert to MB
            cpu_usage_percent=cpu_percent,
            concurrent_connections=len(self.process.connections()),
            active_threads=self.process.num_threads(),
            network_io_bytes=net_io.bytes_sent + net_io.bytes_recv if net_io else 0,
            disk_io_bytes=disk_io.read_bytes + disk_io.write_bytes if disk_io else 0
        )
        
        return metrics
    
    async def _background_collection(self):
        """Background task for continuous metrics collection"""
        
        while self.collection_active:
            try:
                metrics = await self.collect_current_metrics()
                self.metrics_history.append(metrics)
                
                # Sleep for collection interval
                await asyncio.sleep(self.collection_interval_ms / 1000.0)
                
            except Exception as e:
                # Continue collection even if individual collection fails
                continue
    
    def _analyze_metrics_history(self, result: BenchmarkResult) -> BenchmarkResult:
        """Analyze collected metrics history"""
        
        if not self.metrics_history:
            return result
        
        # Memory usage analysis
        memory_values = [m.memory_usage_mb for m in self.metrics_history]
        result.peak_memory_mb = max(memory_values)
        result.average_memory_mb = statistics.mean(memory_values)
        
        # CPU usage analysis
        cpu_values = [m.cpu_usage_percent for m in self.metrics_history]
        result.peak_cpu_percent = max(cpu_values)
        result.average_cpu_percent = statistics.mean(cpu_values)
        
        # Calculate throughput (metrics collected per second)
        if result.total_duration_seconds > 0:
            result.throughput_ops_per_sec = len(self.metrics_history) / result.total_duration_seconds
        
        return result


class BenchmarkAnalyzer:
    """Advanced benchmark result analysis and reporting"""
    
    def __init__(self):
        self.performance_targets = {
            'max_response_time_ms': 1000.0,
            'max_p95_response_time_ms': 2000.0,
            'min_cache_hit_rate': 0.70,
            'max_error_rate': 0.01,  # 1%
            'max_memory_usage_gb': 2.0,
            'max_cpu_usage_percent': 80.0,
            'min_throughput_ops_per_sec': 100.0
        }
    
    def analyze_execution_times(self, execution_times: List[float]) -> Dict[str, float]:
        """Analyze execution time statistics"""
        
        if not execution_times:
            return {}
        
        # Sort for percentile calculations
        sorted_times = sorted(execution_times)
        n = len(sorted_times)
        
        analysis = {
            'count': n,
            'average_ms': statistics.mean(execution_times),
            'median_ms': statistics.median(execution_times),
            'min_ms': min(execution_times),
            'max_ms': max(execution_times),
            'std_deviation_ms': statistics.stdev(execution_times) if n > 1 else 0.0,
            'variance_ms': statistics.variance(execution_times) if n > 1 else 0.0
        }
        
        # Percentiles
        if n >= 20:  # Need sufficient data for reliable percentiles
            percentiles = statistics.quantiles(sorted_times, n=100)
            analysis.update({
                'p50_ms': percentiles[49],  # 50th percentile (median)
                'p90_ms': percentiles[89],  # 90th percentile
                'p95_ms': percentiles[94],  # 95th percentile
                'p99_ms': percentiles[98],  # 99th percentile
                'p999_ms': percentiles[99] if n >= 1000 else percentiles[98]  # 99.9th percentile
            })
        elif n >= 4:
            # Simple quartile calculation for smaller datasets
            q1_idx = n // 4
            q3_idx = 3 * n // 4
            analysis.update({
                'p25_ms': sorted_times[q1_idx],
                'p75_ms': sorted_times[q3_idx]
            })
        
        return analysis
    
    def analyze_resource_usage(self, metrics_history: List[PerformanceMetrics]) -> Dict[str, Any]:
        """Analyze resource usage patterns"""
        
        if not metrics_history:
            return {}
        
        # Memory usage analysis
        memory_values = [m.memory_usage_mb for m in metrics_history]
        cpu_values = [m.cpu_usage_percent for m in metrics_history]
        
        analysis = {
            'memory_analysis': {
                'peak_mb': max(memory_values),
                'average_mb': statistics.mean(memory_values),
                'min_mb': min(memory_values),
                'std_deviation_mb': statistics.stdev(memory_values) if len(memory_values) > 1 else 0.0,
                'growth_rate_mb_per_sec': self._calculate_growth_rate(memory_values, metrics_history)
            },
            'cpu_analysis': {
                'peak_percent': max(cpu_values),
                'average_percent': statistics.mean(cpu_values),
                'min_percent': min(cpu_values),
                'std_deviation_percent': statistics.stdev(cpu_values) if len(cpu_values) > 1 else 0.0,
                'utilization_efficiency': statistics.mean(cpu_values) / max(cpu_values) if max(cpu_values) > 0 else 0.0
            },
            'connection_analysis': {
                'peak_connections': max(m.concurrent_connections for m in metrics_history),
                'average_connections': statistics.mean([m.concurrent_connections for m in metrics_history]),
                'peak_threads': max(m.active_threads for m in metrics_history),
                'average_threads': statistics.mean([m.active_threads for m in metrics_history])
            }
        }
        
        return analysis
    
    def _calculate_growth_rate(self, values: List[float], metrics_history: List[PerformanceMetrics]) -> float:
        """Calculate growth rate per second"""
        
        if len(values) < 2 or len(metrics_history) < 2:
            return 0.0
        
        first_value = values[0]
        last_value = values[-1]
        
        time_diff = (metrics_history[-1].timestamp - metrics_history[0].timestamp).total_seconds()
        
        if time_diff <= 0:
            return 0.0
        
        return (last_value - first_value) / time_diff
    
    def evaluate_performance_targets(self, result: BenchmarkResult) -> Tuple[bool, List[str]]:
        """Evaluate benchmark result against performance targets"""
        
        violations = []
        
        # Response time targets
        if result.average_time_ms > self.performance_targets['max_response_time_ms']:
            violations.append(f"Average response time {result.average_time_ms:.1f}ms exceeds target {self.performance_targets['max_response_time_ms']:.1f}ms")
        
        if result.p95_time_ms > self.performance_targets['max_p95_response_time_ms']:
            violations.append(f"P95 response time {result.p95_time_ms:.1f}ms exceeds target {self.performance_targets['max_p95_response_time_ms']:.1f}ms")
        
        # Cache efficiency targets
        if result.cache_hit_rate < self.performance_targets['min_cache_hit_rate']:
            violations.append(f"Cache hit rate {result.cache_hit_rate:.1%} below target {self.performance_targets['min_cache_hit_rate']:.1%}")
        
        # Error rate targets
        if result.error_rate_percent > self.performance_targets['max_error_rate']:
            violations.append(f"Error rate {result.error_rate_percent:.1%} exceeds target {self.performance_targets['max_error_rate']:.1%}")
        
        # Resource usage targets
        if result.peak_memory_mb / 1024 > self.performance_targets['max_memory_usage_gb']:
            violations.append(f"Peak memory {result.peak_memory_mb/1024:.2f}GB exceeds target {self.performance_targets['max_memory_usage_gb']:.1f}GB")
        
        if result.peak_cpu_percent > self.performance_targets['max_cpu_usage_percent']:
            violations.append(f"Peak CPU {result.peak_cpu_percent:.1f}% exceeds target {self.performance_targets['max_cpu_usage_percent']:.1f}%")
        
        # Throughput targets
        if result.throughput_ops_per_sec < self.performance_targets['min_throughput_ops_per_sec']:
            violations.append(f"Throughput {result.throughput_ops_per_sec:.1f} ops/sec below target {self.performance_targets['min_throughput_ops_per_sec']:.1f}")
        
        meets_targets = len(violations) == 0
        
        return meets_targets, violations
    
    def generate_performance_report(self, results: List[BenchmarkResult]) -> Dict[str, Any]:
        """Generate comprehensive performance analysis report"""
        
        if not results:
            return {}
        
        # Overall statistics
        all_response_times = []
        all_memory_usage = []
        all_cpu_usage = []
        all_cache_hit_rates = []
        all_error_rates = []
        
        for result in results:
            all_response_times.extend(result.all_execution_times)
            all_memory_usage.append(result.peak_memory_mb)
            all_cpu_usage.append(result.peak_cpu_percent)
            if result.cache_hit_rate > 0:
                all_cache_hit_rates.append(result.cache_hit_rate)
            all_error_rates.append(result.error_rate_percent)
        
        # Performance summary
        report = {
            'summary': {
                'total_benchmarks': len(results),
                'total_duration_seconds': sum(r.total_duration_seconds for r in results),
                'total_operations': sum(r.total_operations for r in results),
                'overall_success_rate': sum(r.successful_operations for r in results) / sum(r.total_operations for r in results) if sum(r.total_operations for r in results) > 0 else 0
            },
            'response_time_analysis': self.analyze_execution_times(all_response_times),
            'resource_usage_summary': {
                'peak_memory_mb': max(all_memory_usage) if all_memory_usage else 0,
                'average_memory_mb': statistics.mean(all_memory_usage) if all_memory_usage else 0,
                'peak_cpu_percent': max(all_cpu_usage) if all_cpu_usage else 0,
                'average_cpu_percent': statistics.mean(all_cpu_usage) if all_cpu_usage else 0
            },
            'efficiency_metrics': {
                'average_cache_hit_rate': statistics.mean(all_cache_hit_rates) if all_cache_hit_rates else 0,
                'average_error_rate': statistics.mean(all_error_rates) if all_error_rates else 0,
                'overall_throughput': sum(r.throughput_ops_per_sec for r in results) / len(results) if results else 0
            }
        }
        
        # Performance targets evaluation
        passed_benchmarks = 0
        all_violations = []
        
        for result in results:
            meets_targets, violations = self.evaluate_performance_targets(result)
            if meets_targets:
                passed_benchmarks += 1
            all_violations.extend(violations)
        
        report['target_compliance'] = {
            'benchmarks_passed': passed_benchmarks,
            'success_rate': passed_benchmarks / len(results),
            'total_violations': len(all_violations),
            'common_violations': self._find_common_violations(all_violations),
            'meets_enterprise_standards': passed_benchmarks / len(results) >= 0.90  # 90% pass rate
        }
        
        # Recommendations
        report['recommendations'] = self._generate_performance_recommendations(report)
        
        return report
    
    def _find_common_violations(self, violations: List[str]) -> List[Tuple[str, int]]:
        """Find most common performance violations"""
        
        violation_counts = {}
        for violation in violations:
            # Extract violation type (first part before specific values)
            violation_type = violation.split(' ')[0:3]  # First 3 words
            violation_key = ' '.join(violation_type)
            
            violation_counts[violation_key] = violation_counts.get(violation_key, 0) + 1
        
        # Sort by frequency
        sorted_violations = sorted(violation_counts.items(), key=lambda x: x[1], reverse=True)
        
        return sorted_violations[:5]  # Top 5 most common
    
    def _generate_performance_recommendations(self, report: Dict[str, Any]) -> List[str]:
        """Generate performance improvement recommendations"""
        
        recommendations = []
        
        # Response time recommendations
        response_analysis = report.get('response_time_analysis', {})
        if response_analysis.get('p95_ms', 0) > 1000:
            recommendations.append("Consider algorithm optimization for P95 response times > 1s")
        
        # Memory usage recommendations
        resource_summary = report.get('resource_usage_summary', {})
        if resource_summary.get('peak_memory_mb', 0) > 1024:  # > 1GB
            recommendations.append("Investigate memory usage optimization for peak usage > 1GB")
        
        # Cache efficiency recommendations
        efficiency = report.get('efficiency_metrics', {})
        if efficiency.get('average_cache_hit_rate', 0) < 0.70:
            recommendations.append("Improve Redis cache strategies for hit rates < 70%")
        
        # Error rate recommendations
        if efficiency.get('average_error_rate', 0) > 0.005:  # > 0.5%
            recommendations.append("Address error handling to reduce error rate below 0.5%")
        
        # Target compliance recommendations
        compliance = report.get('target_compliance', {})
        if compliance.get('success_rate', 0) < 0.90:
            recommendations.append("Focus on failing benchmarks to achieve 90%+ success rate")
        
        if not recommendations:
            recommendations.append("All performance targets met - system ready for production")
        
        return recommendations


class PerformanceRegression:
    """Performance regression detection and analysis"""
    
    def __init__(self, baseline_file: Optional[str] = None):
        self.baseline_file = baseline_file
        self.baseline_data: Optional[Dict[str, Any]] = None
        
        if baseline_file:
            self.load_baseline(baseline_file)
    
    def load_baseline(self, baseline_file: str):
        """Load baseline performance data"""
        try:
            with open(baseline_file, 'r') as f:
                self.baseline_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            self.baseline_data = None
    
    def save_baseline(self, results: List[BenchmarkResult], baseline_file: str):
        """Save current results as new baseline"""
        
        analyzer = BenchmarkAnalyzer()
        report = analyzer.generate_performance_report(results)
        
        baseline_data = {
            'timestamp': datetime.now().isoformat(),
            'performance_report': report,
            'key_metrics': {
                'average_response_time_ms': report.get('response_time_analysis', {}).get('average_ms', 0),
                'p95_response_time_ms': report.get('response_time_analysis', {}).get('p95_ms', 0),
                'peak_memory_mb': report.get('resource_usage_summary', {}).get('peak_memory_mb', 0),
                'average_cache_hit_rate': report.get('efficiency_metrics', {}).get('average_cache_hit_rate', 0),
                'overall_success_rate': report.get('summary', {}).get('overall_success_rate', 0)
            }
        }
        
        with open(baseline_file, 'w') as f:
            json.dump(baseline_data, f, indent=2, default=str)
        
        self.baseline_data = baseline_data
    
    def detect_regressions(self, current_results: List[BenchmarkResult], threshold_percent: float = 10.0) -> Dict[str, Any]:
        """Detect performance regressions compared to baseline"""
        
        if not self.baseline_data:
            return {'regression_detected': False, 'message': 'No baseline data available'}
        
        analyzer = BenchmarkAnalyzer()
        current_report = analyzer.generate_performance_report(current_results)
        
        baseline_metrics = self.baseline_data.get('key_metrics', {})
        current_metrics = {
            'average_response_time_ms': current_report.get('response_time_analysis', {}).get('average_ms', 0),
            'p95_response_time_ms': current_report.get('response_time_analysis', {}).get('p95_ms', 0),
            'peak_memory_mb': current_report.get('resource_usage_summary', {}).get('peak_memory_mb', 0),
            'average_cache_hit_rate': current_report.get('efficiency_metrics', {}).get('average_cache_hit_rate', 0),
            'overall_success_rate': current_report.get('summary', {}).get('overall_success_rate', 0)
        }
        
        regressions = []
        improvements = []
        
        for metric_name, baseline_value in baseline_metrics.items():
            current_value = current_metrics.get(metric_name, 0)
            
            if baseline_value == 0:
                continue  # Skip if no baseline
            
            # Calculate percentage change
            percent_change = ((current_value - baseline_value) / baseline_value) * 100
            
            # Determine if this is a regression (worse performance)
            is_regression = False
            if metric_name in ['average_response_time_ms', 'p95_response_time_ms', 'peak_memory_mb']:
                # Lower is better for these metrics
                is_regression = percent_change > threshold_percent
            elif metric_name in ['average_cache_hit_rate', 'overall_success_rate']:
                # Higher is better for these metrics
                is_regression = percent_change < -threshold_percent
            
            if is_regression:
                regressions.append({
                    'metric': metric_name,
                    'baseline_value': baseline_value,
                    'current_value': current_value,
                    'percent_change': percent_change,
                    'threshold_percent': threshold_percent
                })
            elif abs(percent_change) > threshold_percent:
                improvements.append({
                    'metric': metric_name,
                    'baseline_value': baseline_value,
                    'current_value': current_value,
                    'percent_change': percent_change
                })
        
        return {
            'regression_detected': len(regressions) > 0,
            'regressions': regressions,
            'improvements': improvements,
            'baseline_timestamp': self.baseline_data.get('timestamp'),
            'comparison_threshold_percent': threshold_percent,
            'summary': f"{len(regressions)} regressions, {len(improvements)} improvements detected"
        }


if __name__ == "__main__":
    # Demo usage
    async def main():
        print("Performance Metrics Collection Demo")
        print("=" * 50)
        
        # Initialize metrics collector
        collector = PerformanceMetricsCollector(collection_interval_ms=50)
        
        # Start collection session
        session_start = await collector.start_collection_session()
        print(f"Metrics collection started at {session_start}")
        
        # Simulate some work
        import random
        for i in range(10):
            # Simulate algorithm execution
            start_time = time.time()
            await asyncio.sleep(random.uniform(0.01, 0.1))  # 10-100ms work
            end_time = time.time()
            
            execution_time_ms = (end_time - start_time) * 1000
            print(f"Operation {i+1}: {execution_time_ms:.1f}ms")
        
        # Stop collection and analyze
        result = await collector.stop_collection_session()
        
        print(f"\nCollection Results:")
        print(f"  Duration: {result.total_duration_seconds:.1f}s")
        print(f"  Metrics Collected: {len(result.resource_snapshots)}")
        print(f"  Peak Memory: {result.peak_memory_mb:.1f}MB")
        print(f"  Average CPU: {result.average_cpu_percent:.1f}%")
        print(f"  Throughput: {result.throughput_ops_per_sec:.1f} metrics/sec")
        
        # Demonstrate analysis
        analyzer = BenchmarkAnalyzer()
        
        # Create sample execution times
        sample_times = [random.uniform(10, 200) for _ in range(100)]
        timing_analysis = analyzer.analyze_execution_times(sample_times)
        
        print(f"\nTiming Analysis:")
        print(f"  Average: {timing_analysis.get('average_ms', 0):.1f}ms")
        print(f"  Median: {timing_analysis.get('median_ms', 0):.1f}ms")
        print(f"  P95: {timing_analysis.get('p95_ms', 0):.1f}ms")
        print(f"  P99: {timing_analysis.get('p99_ms', 0):.1f}ms")
        
        # Performance targets evaluation
        meets_targets, violations = analyzer.evaluate_performance_targets(result)
        print(f"\nPerformance Targets:")
        print(f"  Meets Targets: {'✅' if meets_targets else '❌'}")
        if violations:
            print(f"  Violations:")
            for violation in violations:
                print(f"    • {violation}")
    
    # Run demo
    asyncio.run(main())