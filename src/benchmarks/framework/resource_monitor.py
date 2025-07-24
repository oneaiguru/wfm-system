#!/usr/bin/env python3
"""
System Resource Monitor for Performance Benchmarking
===================================================

Advanced system resource monitoring for enterprise-scale performance testing
with focus on memory, CPU, I/O, and database connection tracking.

BDD Source: Task 11 - Resource monitoring for 1,173 table system performance validation
Targets: Real-time monitoring, resource limit detection, performance correlation

Key features:
- Real-time system resource tracking
- Database connection pool monitoring
- Redis memory usage tracking
- Performance bottleneck detection
"""

import asyncio
import time
import logging
import psutil
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
import statistics
import threading

logger = logging.getLogger(__name__)


class ResourceType(Enum):
    """Types of system resources to monitor"""
    MEMORY = "memory"
    CPU = "cpu"
    DISK_IO = "disk_io"
    NETWORK_IO = "network_io"
    DATABASE_CONNECTIONS = "database_connections"
    REDIS_MEMORY = "redis_memory"
    PROCESS_COUNT = "process_count"
    FILE_DESCRIPTORS = "file_descriptors"


@dataclass
class SystemMetrics:
    """System resource metrics snapshot"""
    timestamp: datetime = field(default_factory=datetime.now)
    
    # Memory metrics
    memory_usage_mb: float = 0.0
    memory_usage_gb: float = 0.0
    memory_usage_percent: float = 0.0
    available_memory_mb: float = 0.0
    swap_usage_mb: float = 0.0
    swap_usage_percent: float = 0.0
    
    # CPU metrics
    cpu_usage_percent: float = 0.0
    cpu_count: int = 0
    load_average_1m: float = 0.0
    load_average_5m: float = 0.0
    load_average_15m: float = 0.0
    
    # Disk I/O metrics
    disk_read_bytes: int = 0
    disk_write_bytes: int = 0
    disk_read_ops: int = 0
    disk_write_ops: int = 0
    disk_usage_percent: float = 0.0
    
    # Network I/O metrics
    network_bytes_sent: int = 0
    network_bytes_recv: int = 0
    network_packets_sent: int = 0
    network_packets_recv: int = 0
    
    # Process metrics
    process_count: int = 0
    thread_count: int = 0
    file_descriptor_count: int = 0
    
    # Database metrics
    database_connections: int = 0
    database_active_queries: int = 0
    database_idle_connections: int = 0
    
    # Redis metrics
    redis_memory_used_mb: float = 0.0
    redis_memory_peak_mb: float = 0.0
    redis_connected_clients: int = 0
    redis_keyspace_hits: int = 0
    redis_keyspace_misses: int = 0
    
    def __post_init__(self):
        """Calculate derived metrics"""
        if self.memory_usage_mb > 0:
            self.memory_usage_gb = self.memory_usage_mb / 1024.0


@dataclass
class ResourceAlert:
    """Resource usage alert"""
    alert_type: str
    resource_type: ResourceType
    current_value: float
    threshold_value: float
    severity: str  # 'warning', 'critical'
    message: str
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class MonitoringSession:
    """Complete monitoring session results"""
    session_id: str
    start_time: datetime
    end_time: datetime
    duration_seconds: float
    
    # Metrics history
    metrics_history: List[SystemMetrics] = field(default_factory=list)
    
    # Alerts generated
    alerts: List[ResourceAlert] = field(default_factory=list)
    
    # Peak values
    peak_memory_mb: float = 0.0
    peak_cpu_percent: float = 0.0
    peak_disk_io_mb_per_sec: float = 0.0
    peak_network_io_mb_per_sec: float = 0.0
    
    # Average values
    average_memory_mb: float = 0.0
    average_cpu_percent: float = 0.0
    average_disk_io_mb_per_sec: float = 0.0
    average_network_io_mb_per_sec: float = 0.0
    
    # Resource utilization trends
    memory_trend: str = "stable"  # increasing, decreasing, stable, volatile
    cpu_trend: str = "stable"
    
    # Performance bottlenecks detected
    bottlenecks: List[str] = field(default_factory=list)


class ResourceMonitor:
    """Advanced system resource monitoring"""
    
    def __init__(self, 
                 monitoring_interval_ms: float = 1000.0,
                 enable_database_monitoring: bool = True,
                 enable_redis_monitoring: bool = True):
        
        self.monitoring_interval_ms = monitoring_interval_ms
        self.enable_database_monitoring = enable_database_monitoring
        self.enable_redis_monitoring = enable_redis_monitoring
        
        # Monitoring state
        self.monitoring_active = False
        self.current_session: Optional[MonitoringSession] = None
        
        # Resource thresholds for alerts
        self.thresholds = {
            'memory_usage_percent': {'warning': 70.0, 'critical': 90.0},
            'cpu_usage_percent': {'warning': 80.0, 'critical': 95.0},
            'disk_usage_percent': {'warning': 80.0, 'critical': 95.0},
            'swap_usage_percent': {'warning': 10.0, 'critical': 50.0},
            'load_average_ratio': {'warning': 1.5, 'critical': 3.0},  # ratio to CPU count
            'file_descriptor_count': {'warning': 8000, 'critical': 16000}
        }
        
        # External connections
        self.redis_client = None
        self.database_connection = None
        
        # Baseline metrics for comparison
        self.baseline_metrics: Optional[SystemMetrics] = None
        
        logger.info(f"Resource monitor initialized with {monitoring_interval_ms}ms interval")
    
    async def start_monitoring(self) -> str:
        """
        Start resource monitoring session.
        
        Returns:
            Session ID for tracking
        """
        session_id = f"monitoring_{int(time.time())}"
        
        self.current_session = MonitoringSession(
            session_id=session_id,
            start_time=datetime.now(),
            end_time=datetime.now(),  # Will be updated when stopped
            duration_seconds=0.0,
            metrics_history=[],
            alerts=[]
        )
        
        # Collect baseline metrics
        self.baseline_metrics = await self.collect_system_metrics()
        
        # Start monitoring loop
        self.monitoring_active = True
        asyncio.create_task(self._monitoring_loop())
        
        logger.info(f"Resource monitoring started: {session_id}")
        return session_id
    
    async def stop_monitoring(self, session_id: str) -> MonitoringSession:
        """
        Stop resource monitoring and return analysis.
        
        Args:
            session_id: Session ID from start_monitoring
            
        Returns:
            Complete monitoring session with analysis
        """
        self.monitoring_active = False
        
        if not self.current_session or self.current_session.session_id != session_id:
            raise ValueError(f"No active session found for ID: {session_id}")
        
        # Finalize session
        self.current_session.end_time = datetime.now()
        self.current_session.duration_seconds = (
            self.current_session.end_time - self.current_session.start_time
        ).total_seconds()
        
        # Analyze collected metrics
        self._analyze_monitoring_session()
        
        session_result = self.current_session
        self.current_session = None
        
        logger.info(f"Resource monitoring stopped: {session_id} ({session_result.duration_seconds:.1f}s)")
        return session_result
    
    async def collect_system_metrics(self) -> SystemMetrics:
        """Collect comprehensive system metrics snapshot"""
        
        metrics = SystemMetrics()
        
        try:
            # Memory metrics
            memory = psutil.virtual_memory()
            metrics.memory_usage_mb = memory.used / 1024 / 1024
            metrics.memory_usage_percent = memory.percent
            metrics.available_memory_mb = memory.available / 1024 / 1024
            
            # Swap metrics
            swap = psutil.swap_memory()
            metrics.swap_usage_mb = swap.used / 1024 / 1024
            metrics.swap_usage_percent = swap.percent
            
            # CPU metrics
            metrics.cpu_usage_percent = psutil.cpu_percent(interval=0.1)
            metrics.cpu_count = psutil.cpu_count()
            
            # Load average (Unix/Linux only)
            try:
                load_avg = psutil.getloadavg()
                metrics.load_average_1m = load_avg[0]
                metrics.load_average_5m = load_avg[1]
                metrics.load_average_15m = load_avg[2]
            except (AttributeError, OSError):
                # Windows doesn't have load average
                pass
            
            # Disk I/O metrics
            disk_io = psutil.disk_io_counters()
            if disk_io:
                metrics.disk_read_bytes = disk_io.read_bytes
                metrics.disk_write_bytes = disk_io.write_bytes
                metrics.disk_read_ops = disk_io.read_count
                metrics.disk_write_ops = disk_io.write_count
            
            # Disk usage
            disk_usage = psutil.disk_usage('/')
            metrics.disk_usage_percent = (disk_usage.used / disk_usage.total) * 100
            
            # Network I/O metrics
            network_io = psutil.net_io_counters()
            if network_io:
                metrics.network_bytes_sent = network_io.bytes_sent
                metrics.network_bytes_recv = network_io.bytes_recv
                metrics.network_packets_sent = network_io.packets_sent
                metrics.network_packets_recv = network_io.packets_recv
            
            # Process metrics
            metrics.process_count = len(psutil.pids())
            
            # Current process metrics
            current_process = psutil.Process()
            metrics.thread_count = current_process.num_threads()
            
            try:
                metrics.file_descriptor_count = current_process.num_fds()
            except (AttributeError, psutil.AccessDenied):
                # Windows or permission issues
                pass
            
            # Database metrics (if enabled)
            if self.enable_database_monitoring:
                await self._collect_database_metrics(metrics)
            
            # Redis metrics (if enabled)
            if self.enable_redis_monitoring:
                await self._collect_redis_metrics(metrics)
            
        except Exception as e:
            logger.warning(f"Error collecting system metrics: {e}")
        
        return metrics
    
    async def _collect_database_metrics(self, metrics: SystemMetrics):
        """Collect database-specific metrics"""
        
        try:
            # This would be implemented with actual database connection
            # For now, simulate with psutil process monitoring
            
            # Look for PostgreSQL processes
            postgres_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'connections']):
                try:
                    if 'postgres' in proc.info['name'].lower():
                        postgres_processes.append(proc)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            # Count total database connections
            total_connections = 0
            for proc in postgres_processes:
                try:
                    connections = proc.connections()
                    total_connections += len([c for c in connections if c.status == 'ESTABLISHED'])
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            metrics.database_connections = total_connections
            
        except Exception as e:
            logger.debug(f"Database metrics collection failed: {e}")
    
    async def _collect_redis_metrics(self, metrics: SystemMetrics):
        """Collect Redis-specific metrics"""
        
        try:
            if not self.redis_client:
                # Try to connect to Redis
                import redis
                self.redis_client = redis.from_url("redis://localhost:6379/0", socket_timeout=1)
            
            # Get Redis info
            info = await asyncio.to_thread(self.redis_client.info)
            
            metrics.redis_memory_used_mb = info.get('used_memory', 0) / 1024 / 1024
            metrics.redis_memory_peak_mb = info.get('used_memory_peak', 0) / 1024 / 1024
            metrics.redis_connected_clients = info.get('connected_clients', 0)
            metrics.redis_keyspace_hits = info.get('keyspace_hits', 0)
            metrics.redis_keyspace_misses = info.get('keyspace_misses', 0)
            
        except Exception as e:
            logger.debug(f"Redis metrics collection failed: {e}")
            # Reset client on failure
            self.redis_client = None
    
    async def _monitoring_loop(self):
        """Main monitoring loop"""
        
        while self.monitoring_active:
            try:
                # Collect metrics
                metrics = await self.collect_system_metrics()
                
                if self.current_session:
                    self.current_session.metrics_history.append(metrics)
                    
                    # Check for alerts
                    alerts = self._check_resource_thresholds(metrics)
                    self.current_session.alerts.extend(alerts)
                
                # Sleep until next collection
                await asyncio.sleep(self.monitoring_interval_ms / 1000.0)
                
            except Exception as e:
                logger.warning(f"Monitoring loop error: {e}")
                continue
    
    def _check_resource_thresholds(self, metrics: SystemMetrics) -> List[ResourceAlert]:
        """Check metrics against thresholds and generate alerts"""
        
        alerts = []
        
        # Memory usage alerts
        if metrics.memory_usage_percent >= self.thresholds['memory_usage_percent']['critical']:
            alerts.append(ResourceAlert(
                alert_type="memory_critical",
                resource_type=ResourceType.MEMORY,
                current_value=metrics.memory_usage_percent,
                threshold_value=self.thresholds['memory_usage_percent']['critical'],
                severity="critical",
                message=f"Memory usage critical: {metrics.memory_usage_percent:.1f}%"
            ))
        elif metrics.memory_usage_percent >= self.thresholds['memory_usage_percent']['warning']:
            alerts.append(ResourceAlert(
                alert_type="memory_warning",
                resource_type=ResourceType.MEMORY,
                current_value=metrics.memory_usage_percent,
                threshold_value=self.thresholds['memory_usage_percent']['warning'],
                severity="warning",
                message=f"Memory usage high: {metrics.memory_usage_percent:.1f}%"
            ))
        
        # CPU usage alerts
        if metrics.cpu_usage_percent >= self.thresholds['cpu_usage_percent']['critical']:
            alerts.append(ResourceAlert(
                alert_type="cpu_critical",
                resource_type=ResourceType.CPU,
                current_value=metrics.cpu_usage_percent,
                threshold_value=self.thresholds['cpu_usage_percent']['critical'],
                severity="critical",
                message=f"CPU usage critical: {metrics.cpu_usage_percent:.1f}%"
            ))
        elif metrics.cpu_usage_percent >= self.thresholds['cpu_usage_percent']['warning']:
            alerts.append(ResourceAlert(
                alert_type="cpu_warning",
                resource_type=ResourceType.CPU,
                current_value=metrics.cpu_usage_percent,
                threshold_value=self.thresholds['cpu_usage_percent']['warning'],
                severity="warning",
                message=f"CPU usage high: {metrics.cpu_usage_percent:.1f}%"
            ))
        
        # Load average alerts (if available)
        if metrics.load_average_1m > 0 and metrics.cpu_count > 0:
            load_ratio = metrics.load_average_1m / metrics.cpu_count
            
            if load_ratio >= self.thresholds['load_average_ratio']['critical']:
                alerts.append(ResourceAlert(
                    alert_type="load_critical",
                    resource_type=ResourceType.CPU,
                    current_value=load_ratio,
                    threshold_value=self.thresholds['load_average_ratio']['critical'],
                    severity="critical",
                    message=f"Load average critical: {load_ratio:.2f} (1m avg)"
                ))
            elif load_ratio >= self.thresholds['load_average_ratio']['warning']:
                alerts.append(ResourceAlert(
                    alert_type="load_warning",
                    resource_type=ResourceType.CPU,
                    current_value=load_ratio,
                    threshold_value=self.thresholds['load_average_ratio']['warning'],
                    severity="warning",
                    message=f"Load average high: {load_ratio:.2f} (1m avg)"
                ))
        
        # Disk usage alerts
        if metrics.disk_usage_percent >= self.thresholds['disk_usage_percent']['critical']:
            alerts.append(ResourceAlert(
                alert_type="disk_critical",
                resource_type=ResourceType.DISK_IO,
                current_value=metrics.disk_usage_percent,
                threshold_value=self.thresholds['disk_usage_percent']['critical'],
                severity="critical",
                message=f"Disk usage critical: {metrics.disk_usage_percent:.1f}%"
            ))
        elif metrics.disk_usage_percent >= self.thresholds['disk_usage_percent']['warning']:
            alerts.append(ResourceAlert(
                alert_type="disk_warning",
                resource_type=ResourceType.DISK_IO,
                current_value=metrics.disk_usage_percent,
                threshold_value=self.thresholds['disk_usage_percent']['warning'],
                severity="warning",
                message=f"Disk usage high: {metrics.disk_usage_percent:.1f}%"
            ))
        
        # Swap usage alerts
        if metrics.swap_usage_percent >= self.thresholds['swap_usage_percent']['critical']:
            alerts.append(ResourceAlert(
                alert_type="swap_critical",
                resource_type=ResourceType.MEMORY,
                current_value=metrics.swap_usage_percent,
                threshold_value=self.thresholds['swap_usage_percent']['critical'],
                severity="critical",
                message=f"Swap usage critical: {metrics.swap_usage_percent:.1f}%"
            ))
        elif metrics.swap_usage_percent >= self.thresholds['swap_usage_percent']['warning']:
            alerts.append(ResourceAlert(
                alert_type="swap_warning",
                resource_type=ResourceType.MEMORY,
                current_value=metrics.swap_usage_percent,
                threshold_value=self.thresholds['swap_usage_percent']['warning'],
                severity="warning",
                message=f"Swap usage high: {metrics.swap_usage_percent:.1f}%"
            ))
        
        # File descriptor alerts
        if metrics.file_descriptor_count >= self.thresholds['file_descriptor_count']['critical']:
            alerts.append(ResourceAlert(
                alert_type="fd_critical",
                resource_type=ResourceType.FILE_DESCRIPTORS,
                current_value=metrics.file_descriptor_count,
                threshold_value=self.thresholds['file_descriptor_count']['critical'],
                severity="critical",
                message=f"File descriptors critical: {metrics.file_descriptor_count}"
            ))
        elif metrics.file_descriptor_count >= self.thresholds['file_descriptor_count']['warning']:
            alerts.append(ResourceAlert(
                alert_type="fd_warning",
                resource_type=ResourceType.FILE_DESCRIPTORS,
                current_value=metrics.file_descriptor_count,
                threshold_value=self.thresholds['file_descriptor_count']['warning'],
                severity="warning",
                message=f"File descriptors high: {metrics.file_descriptor_count}"
            ))
        
        return alerts
    
    def _analyze_monitoring_session(self):
        """Analyze complete monitoring session and extract insights"""
        
        if not self.current_session or not self.current_session.metrics_history:
            return
        
        metrics_list = self.current_session.metrics_history
        
        # Calculate peak values
        self.current_session.peak_memory_mb = max(m.memory_usage_mb for m in metrics_list)
        self.current_session.peak_cpu_percent = max(m.cpu_usage_percent for m in metrics_list)
        
        # Calculate peak I/O rates
        if len(metrics_list) > 1:
            disk_io_rates = []
            network_io_rates = []
            
            for i in range(1, len(metrics_list)):
                prev = metrics_list[i-1]
                curr = metrics_list[i]
                
                time_diff = (curr.timestamp - prev.timestamp).total_seconds()
                if time_diff > 0:
                    # Disk I/O rate (MB/sec)
                    disk_bytes_diff = (curr.disk_read_bytes + curr.disk_write_bytes) - (prev.disk_read_bytes + prev.disk_write_bytes)
                    disk_io_rate = (disk_bytes_diff / 1024 / 1024) / time_diff
                    disk_io_rates.append(disk_io_rate)
                    
                    # Network I/O rate (MB/sec)
                    network_bytes_diff = (curr.network_bytes_sent + curr.network_bytes_recv) - (prev.network_bytes_sent + prev.network_bytes_recv)
                    network_io_rate = (network_bytes_diff / 1024 / 1024) / time_diff
                    network_io_rates.append(network_io_rate)
            
            if disk_io_rates:
                self.current_session.peak_disk_io_mb_per_sec = max(disk_io_rates)
                self.current_session.average_disk_io_mb_per_sec = statistics.mean(disk_io_rates)
            
            if network_io_rates:
                self.current_session.peak_network_io_mb_per_sec = max(network_io_rates)
                self.current_session.average_network_io_mb_per_sec = statistics.mean(network_io_rates)
        
        # Calculate average values
        self.current_session.average_memory_mb = statistics.mean(m.memory_usage_mb for m in metrics_list)
        self.current_session.average_cpu_percent = statistics.mean(m.cpu_usage_percent for m in metrics_list)
        
        # Analyze trends
        self.current_session.memory_trend = self._analyze_trend([m.memory_usage_mb for m in metrics_list])
        self.current_session.cpu_trend = self._analyze_trend([m.cpu_usage_percent for m in metrics_list])
        
        # Detect performance bottlenecks
        self.current_session.bottlenecks = self._detect_bottlenecks(metrics_list)
    
    def _analyze_trend(self, values: List[float]) -> str:
        """Analyze trend in metric values"""
        
        if len(values) < 3:
            return "insufficient_data"
        
        # Calculate linear regression slope
        n = len(values)
        x_values = list(range(n))
        
        # Calculate slope using least squares
        sum_x = sum(x_values)
        sum_y = sum(values)
        sum_xy = sum(x * y for x, y in zip(x_values, values))
        sum_x2 = sum(x * x for x in x_values)
        
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
        
        # Calculate coefficient of variation for volatility
        mean_value = statistics.mean(values)
        std_dev = statistics.stdev(values) if len(values) > 1 else 0
        coefficient_of_variation = std_dev / mean_value if mean_value > 0 else 0
        
        # Classify trend
        if coefficient_of_variation > 0.3:  # High volatility
            return "volatile"
        elif abs(slope) < 0.01:  # Very small slope
            return "stable"
        elif slope > 0.05:  # Significant positive slope
            return "increasing"
        elif slope < -0.05:  # Significant negative slope
            return "decreasing"
        else:
            return "stable"
    
    def _detect_bottlenecks(self, metrics_list: List[SystemMetrics]) -> List[str]:
        """Detect performance bottlenecks from metrics"""
        
        bottlenecks = []
        
        # Memory bottleneck detection
        high_memory_periods = sum(1 for m in metrics_list if m.memory_usage_percent > 85)
        if high_memory_periods > len(metrics_list) * 0.3:  # > 30% of time
            bottlenecks.append("memory_pressure")
        
        # CPU bottleneck detection
        high_cpu_periods = sum(1 for m in metrics_list if m.cpu_usage_percent > 90)
        if high_cpu_periods > len(metrics_list) * 0.2:  # > 20% of time
            bottlenecks.append("cpu_saturation")
        
        # Swap usage detection (memory pressure indicator)
        swap_usage_periods = sum(1 for m in metrics_list if m.swap_usage_percent > 5)
        if swap_usage_periods > len(metrics_list) * 0.1:  # > 10% of time
            bottlenecks.append("memory_thrashing")
        
        # Load average bottleneck (if available)
        high_load_periods = sum(1 for m in metrics_list 
                               if m.load_average_1m > 0 and m.cpu_count > 0 
                               and m.load_average_1m / m.cpu_count > 2.0)
        if high_load_periods > len(metrics_list) * 0.2:
            bottlenecks.append("system_overload")
        
        # File descriptor exhaustion
        high_fd_periods = sum(1 for m in metrics_list if m.file_descriptor_count > 10000)
        if high_fd_periods > len(metrics_list) * 0.1:
            bottlenecks.append("fd_exhaustion")
        
        # Database connection bottleneck
        high_db_conn_periods = sum(1 for m in metrics_list if m.database_connections > 100)
        if high_db_conn_periods > len(metrics_list) * 0.2:
            bottlenecks.append("database_connection_pressure")
        
        return bottlenecks
    
    def generate_monitoring_report(self, sessions: List[MonitoringSession]) -> Dict[str, Any]:
        """Generate comprehensive monitoring report"""
        
        if not sessions:
            return {}
        
        # Aggregate statistics across sessions
        all_metrics = []
        all_alerts = []
        all_bottlenecks = []
        
        for session in sessions:
            all_metrics.extend(session.metrics_history)
            all_alerts.extend(session.alerts)
            all_bottlenecks.extend(session.bottlenecks)
        
        if not all_metrics:
            return {'error': 'No metrics data available'}
        
        report = {
            'summary': {
                'total_sessions': len(sessions),
                'total_monitoring_duration_seconds': sum(s.duration_seconds for s in sessions),
                'total_metrics_collected': len(all_metrics),
                'total_alerts_generated': len(all_alerts)
            },
            'resource_analysis': {},
            'performance_trends': {},
            'alert_analysis': {},
            'bottleneck_analysis': {},
            'recommendations': []
        }
        
        # Resource usage analysis
        memory_values = [m.memory_usage_mb for m in all_metrics]
        cpu_values = [m.cpu_usage_percent for m in all_metrics]
        
        report['resource_analysis'] = {
            'memory': {
                'peak_mb': max(memory_values),
                'average_mb': statistics.mean(memory_values),
                'median_mb': statistics.median(memory_values),
                'std_dev_mb': statistics.stdev(memory_values) if len(memory_values) > 1 else 0,
                'peak_gb': max(memory_values) / 1024
            },
            'cpu': {
                'peak_percent': max(cpu_values),
                'average_percent': statistics.mean(cpu_values),
                'median_percent': statistics.median(cpu_values),
                'std_dev_percent': statistics.stdev(cpu_values) if len(cpu_values) > 1 else 0
            }
        }
        
        # Performance trends analysis
        peak_memory_per_session = [s.peak_memory_mb for s in sessions]
        peak_cpu_per_session = [s.peak_cpu_percent for s in sessions]
        
        report['performance_trends'] = {
            'memory_trend_across_sessions': self._analyze_trend(peak_memory_per_session),
            'cpu_trend_across_sessions': self._analyze_trend(peak_cpu_per_session),
            'session_memory_peaks': peak_memory_per_session,
            'session_cpu_peaks': peak_cpu_per_session
        }
        
        # Alert analysis
        alert_counts = {}
        critical_alerts = 0
        warning_alerts = 0
        
        for alert in all_alerts:
            alert_counts[alert.alert_type] = alert_counts.get(alert.alert_type, 0) + 1
            if alert.severity == 'critical':
                critical_alerts += 1
            elif alert.severity == 'warning':
                warning_alerts += 1
        
        report['alert_analysis'] = {
            'total_alerts': len(all_alerts),
            'critical_alerts': critical_alerts,
            'warning_alerts': warning_alerts,
            'alert_types': alert_counts,
            'most_common_alert': max(alert_counts.items(), key=lambda x: x[1])[0] if alert_counts else None
        }
        
        # Bottleneck analysis
        bottleneck_counts = {}
        for bottleneck in all_bottlenecks:
            bottleneck_counts[bottleneck] = bottleneck_counts.get(bottleneck, 0) + 1
        
        report['bottleneck_analysis'] = {
            'unique_bottlenecks': len(set(all_bottlenecks)),
            'bottleneck_frequency': bottleneck_counts,
            'most_common_bottleneck': max(bottleneck_counts.items(), key=lambda x: x[1])[0] if bottleneck_counts else None
        }
        
        # Generate recommendations
        recommendations = []
        
        # Memory recommendations
        peak_memory_gb = max(memory_values) / 1024
        if peak_memory_gb > 2.0:
            recommendations.append(f"Peak memory usage {peak_memory_gb:.1f}GB exceeds 2GB target - investigate memory optimization")
        
        # CPU recommendations
        peak_cpu = max(cpu_values)
        if peak_cpu > 90:
            recommendations.append(f"Peak CPU usage {peak_cpu:.1f}% indicates CPU bottleneck - consider optimization")
        
        # Alert-based recommendations
        if critical_alerts > 0:
            recommendations.append(f"{critical_alerts} critical alerts require immediate attention")
        
        # Bottleneck-based recommendations
        if 'memory_pressure' in bottleneck_counts:
            recommendations.append("Memory pressure detected - consider increasing available memory or optimizing memory usage")
        
        if 'cpu_saturation' in bottleneck_counts:
            recommendations.append("CPU saturation detected - consider optimizing algorithms or increasing CPU resources")
        
        if not recommendations:
            recommendations.append("All resource usage within acceptable limits")
        
        report['recommendations'] = recommendations
        
        return report


if __name__ == "__main__":
    # Demo usage
    async def main():
        print("Resource Monitor Demo")
        print("=" * 50)
        
        # Initialize resource monitor
        monitor = ResourceMonitor(monitoring_interval_ms=500)  # 500ms intervals
        
        # Start monitoring
        session_id = await monitor.start_monitoring()
        print(f"Monitoring started: {session_id}")
        
        # Simulate some load
        print("Simulating workload...")
        
        # Create some CPU load
        import random
        tasks = []
        for i in range(5):
            async def cpu_work():
                # Simulate CPU-intensive work
                for _ in range(1000000):
                    _ = random.random() * random.random()
            
            tasks.append(asyncio.create_task(cpu_work()))
        
        # Let monitoring run for a bit
        await asyncio.sleep(10)
        
        # Wait for tasks to complete
        await asyncio.gather(*tasks)
        
        # Stop monitoring
        session = await monitor.stop_monitoring(session_id)
        
        print(f"\nMonitoring Results:")
        print(f"  Session Duration: {session.duration_seconds:.1f}s")
        print(f"  Metrics Collected: {len(session.metrics_history)}")
        print(f"  Peak Memory: {session.peak_memory_mb:.1f}MB ({session.peak_memory_mb/1024:.2f}GB)")
        print(f"  Average Memory: {session.average_memory_mb:.1f}MB")
        print(f"  Peak CPU: {session.peak_cpu_percent:.1f}%")
        print(f"  Average CPU: {session.average_cpu_percent:.1f}%")
        print(f"  Memory Trend: {session.memory_trend}")
        print(f"  CPU Trend: {session.cpu_trend}")
        print(f"  Alerts Generated: {len(session.alerts)}")
        print(f"  Bottlenecks: {', '.join(session.bottlenecks) if session.bottlenecks else 'None'}")
        
        if session.alerts:
            print(f"\nAlerts:")
            for alert in session.alerts[-5:]:  # Show last 5 alerts
                print(f"  [{alert.severity.upper()}] {alert.message}")
        
        # Test single metrics collection
        print(f"\nCurrent System Metrics:")
        current_metrics = await monitor.collect_system_metrics()
        print(f"  Memory Usage: {current_metrics.memory_usage_mb:.1f}MB ({current_metrics.memory_usage_percent:.1f}%)")
        print(f"  CPU Usage: {current_metrics.cpu_usage_percent:.1f}%")
        print(f"  Disk Usage: {current_metrics.disk_usage_percent:.1f}%")
        print(f"  Process Count: {current_metrics.process_count}")
        print(f"  Thread Count: {current_metrics.thread_count}")
        
        if current_metrics.redis_memory_used_mb > 0:
            print(f"  Redis Memory: {current_metrics.redis_memory_used_mb:.1f}MB")
            print(f"  Redis Clients: {current_metrics.redis_connected_clients}")
        
        # Generate report
        report = monitor.generate_monitoring_report([session])
        
        print(f"\nMonitoring Report:")
        print(f"  Peak Memory: {report['resource_analysis']['memory']['peak_gb']:.2f}GB")
        print(f"  Peak CPU: {report['resource_analysis']['cpu']['peak_percent']:.1f}%")
        print(f"  Total Alerts: {report['alert_analysis']['total_alerts']}")
        
        print(f"\nRecommendations:")
        for rec in report['recommendations']:
            print(f"  • {rec}")
    
    # Run demo
    asyncio.run(main())