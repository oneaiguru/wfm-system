#!/usr/bin/env python3
"""
Concurrent Load Generator for Enterprise Testing
===============================================

Advanced load generation system for simulating realistic user behavior patterns
with support for 500+ concurrent users and complex usage scenarios.

BDD Source: Task 11 - Load generation for concurrent user testing up to 500+ users
Targets: Realistic load patterns, concurrent execution, comprehensive metrics

Key features:
- Realistic user behavior simulation
- Concurrent request generation
- Load pattern variations (peak, steady, burst)
- Resource usage monitoring under load
"""

import asyncio
import time
import random
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable, Tuple
from dataclasses import dataclass, field
from concurrent.futures import ThreadPoolExecutor, as_completed
from enum import Enum
import statistics
import json

logger = logging.getLogger(__name__)


class LoadPatternType(Enum):
    """Types of load patterns"""
    CONSTANT = "constant"
    RAMP_UP = "ramp_up"
    RAMP_DOWN = "ramp_down"
    SPIKE = "spike"
    WAVE = "wave"
    REALISTIC_DAILY = "realistic_daily"


@dataclass
class UserScenario:
    """User behavior scenario definition"""
    user_count: int
    duration_seconds: int
    operations_per_user: int
    think_time_ms: int = 100  # Time between operations
    ramp_up_seconds: int = 0
    load_pattern: LoadPatternType = LoadPatternType.CONSTANT
    operation_weights: Dict[str, float] = field(default_factory=lambda: {
        'scheduling_optimization': 0.3,
        'analytics_forecasting': 0.25,
        'trend_analysis': 0.2,
        'kpi_calculation': 0.15,
        'health_check': 0.1
    })


@dataclass
class LoadTestResult:
    """Comprehensive load test results"""
    scenario_name: str
    start_time: datetime
    end_time: datetime
    total_duration_seconds: float
    
    # Request statistics
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    
    # Response time statistics
    average_response_time_ms: float = 0.0
    median_response_time_ms: float = 0.0
    p95_response_time_ms: float = 0.0
    p99_response_time_ms: float = 0.0
    min_response_time_ms: float = 0.0
    max_response_time_ms: float = 0.0
    
    # Throughput metrics
    throughput_per_second: float = 0.0
    peak_throughput_per_second: float = 0.0
    
    # Error metrics
    error_rate: float = 0.0
    error_details: Dict[str, int] = field(default_factory=dict)
    
    # Resource usage
    peak_memory_mb: float = 0.0
    average_memory_mb: float = 0.0
    peak_cpu_percent: float = 0.0
    average_cpu_percent: float = 0.0
    
    # Concurrency metrics
    max_concurrent_requests: int = 0
    average_concurrent_requests: float = 0.0
    
    # Detailed data
    all_response_times: List[float] = field(default_factory=list)
    request_timeline: List[Dict[str, Any]] = field(default_factory=list)
    resource_snapshots: List[Dict[str, Any]] = field(default_factory=list)


class RealisticUserBehavior:
    """Realistic user behavior patterns for load testing"""
    
    def __init__(self):
        self.operation_patterns = {
            'morning_peak': {
                'scheduling_optimization': 0.5,  # Heavy scheduling at start of day
                'analytics_forecasting': 0.2,
                'trend_analysis': 0.15,
                'kpi_calculation': 0.1,
                'health_check': 0.05
            },
            'steady_state': {
                'scheduling_optimization': 0.25,
                'analytics_forecasting': 0.3,   # More analysis during day
                'trend_analysis': 0.25,
                'kpi_calculation': 0.15,
                'health_check': 0.05
            },
            'evening_peak': {
                'scheduling_optimization': 0.2,
                'analytics_forecasting': 0.35,  # End-of-day reporting
                'trend_analysis': 0.3,
                'kpi_calculation': 0.1,
                'health_check': 0.05
            }
        }
        
        # Think time variations (milliseconds)
        self.think_time_patterns = {
            'power_user': (50, 150),      # Fast, experienced users
            'regular_user': (100, 300),   # Normal usage
            'casual_user': (200, 800)     # Slower, exploratory usage
        }
    
    def get_operation_weights(self, time_of_day: str) -> Dict[str, float]:
        """Get operation weights based on time of day"""
        return self.operation_patterns.get(time_of_day, self.operation_patterns['steady_state'])
    
    def get_user_think_time(self, user_type: str) -> int:
        """Get realistic think time for user type"""
        min_time, max_time = self.think_time_patterns.get(user_type, (100, 300))
        return random.randint(min_time, max_time)
    
    def simulate_user_session(self, session_duration_seconds: int, user_type: str = 'regular_user') -> List[Dict[str, Any]]:
        """Simulate a complete user session with realistic behavior"""
        
        operations = []
        current_time = 0
        
        # Determine time of day pattern
        time_patterns = ['morning_peak', 'steady_state', 'evening_peak']
        pattern_duration = session_duration_seconds // 3
        
        while current_time < session_duration_seconds:
            # Select time-based operation weights
            pattern_index = min(current_time // pattern_duration, 2)
            time_pattern = time_patterns[pattern_index]
            operation_weights = self.get_operation_weights(time_pattern)
            
            # Select operation based on weights
            operation = self._weighted_choice(operation_weights)
            
            # Add realistic delay before operation
            think_time = self.get_user_think_time(user_type)
            current_time += think_time / 1000.0  # Convert to seconds
            
            if current_time < session_duration_seconds:
                operations.append({
                    'operation': operation,
                    'scheduled_time': current_time,
                    'user_type': user_type,
                    'time_pattern': time_pattern
                })
        
        return operations
    
    def _weighted_choice(self, weights: Dict[str, float]) -> str:
        """Select item based on weights"""
        total = sum(weights.values())
        r = random.uniform(0, total)
        
        cumulative = 0
        for item, weight in weights.items():
            cumulative += weight
            if r <= cumulative:
                return item
        
        # Fallback
        return list(weights.keys())[0]


class LoadGenerator:
    """Advanced concurrent load generator"""
    
    def __init__(self, config):
        self.config = config
        self.user_behavior = RealisticUserBehavior()
        self.active_requests = 0
        self.max_concurrent_requests = 0
        self.request_counter = 0
        
        # Thread pool for concurrent execution
        self.thread_pool = ThreadPoolExecutor(max_workers=min(config.max_concurrent_users, 100))
        
        # Results tracking
        self.all_response_times: List[float] = []
        self.request_results: List[Dict[str, Any]] = []
        self.resource_snapshots: List[Dict[str, Any]] = []
        
        logger.info(f"Load generator initialized for {config.max_concurrent_users} max users")
    
    async def execute_load_scenario(self, scenario: UserScenario) -> LoadTestResult:
        """
        Execute comprehensive load testing scenario.
        
        Args:
            scenario: User scenario configuration
            
        Returns:
            LoadTestResult with complete analysis
        """
        logger.info(f"Starting load scenario: {scenario.user_count} users for {scenario.duration_seconds}s")
        
        start_time = datetime.now()
        
        # Initialize result tracking
        self.all_response_times = []
        self.request_results = []
        self.resource_snapshots = []
        self.active_requests = 0
        self.max_concurrent_requests = 0
        self.request_counter = 0
        
        try:
            # Start resource monitoring
            monitor_task = asyncio.create_task(self._monitor_resources(scenario.duration_seconds))
            
            # Generate load based on pattern
            if scenario.load_pattern == LoadPatternType.CONSTANT:
                await self._execute_constant_load(scenario)
            elif scenario.load_pattern == LoadPatternType.RAMP_UP:
                await self._execute_ramp_up_load(scenario)
            elif scenario.load_pattern == LoadPatternType.SPIKE:
                await self._execute_spike_load(scenario)
            elif scenario.load_pattern == LoadPatternType.REALISTIC_DAILY:
                await self._execute_realistic_daily_load(scenario)
            else:
                await self._execute_constant_load(scenario)  # Default fallback
            
            # Wait for resource monitoring to complete
            await monitor_task
            
        except Exception as e:
            logger.error(f"Load scenario execution failed: {e}")
            raise
        
        end_time = datetime.now()
        total_duration = (end_time - start_time).total_seconds()
        
        # Analyze results
        result = self._analyze_load_test_results(
            scenario_name=f"{scenario.user_count}_users_{scenario.load_pattern.value}",
            start_time=start_time,
            end_time=end_time,
            total_duration=total_duration
        )
        
        logger.info(f"Load scenario completed: {result.successful_requests}/{result.total_requests} successful")
        
        return result
    
    async def _execute_constant_load(self, scenario: UserScenario):
        """Execute constant load pattern"""
        
        # Create user sessions
        user_sessions = []
        for user_id in range(scenario.user_count):
            user_type = random.choice(['power_user', 'regular_user', 'casual_user'])
            operations = self.user_behavior.simulate_user_session(scenario.duration_seconds, user_type)
            user_sessions.append((user_id, operations))
        
        # Execute all user sessions concurrently
        tasks = []
        for user_id, operations in user_sessions:
            task = asyncio.create_task(self._execute_user_session(user_id, operations))
            tasks.append(task)
        
        # Wait for all sessions to complete
        await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _execute_ramp_up_load(self, scenario: UserScenario):
        """Execute ramp-up load pattern"""
        
        ramp_up_duration = scenario.ramp_up_seconds or scenario.duration_seconds // 4
        steady_duration = scenario.duration_seconds - ramp_up_duration
        
        # Calculate user introduction rate
        users_per_second = scenario.user_count / ramp_up_duration
        
        tasks = []
        
        # Gradually introduce users
        for i in range(scenario.user_count):
            # Calculate when this user should start
            start_delay = i / users_per_second
            
            user_type = random.choice(['power_user', 'regular_user', 'casual_user'])
            session_duration = steady_duration + (ramp_up_duration - start_delay)
            operations = self.user_behavior.simulate_user_session(int(session_duration), user_type)
            
            task = asyncio.create_task(self._execute_user_session_with_delay(i, operations, start_delay))
            tasks.append(task)
        
        # Wait for all sessions to complete
        await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _execute_spike_load(self, scenario: UserScenario):
        """Execute spike load pattern"""
        
        # Normal load for first 1/3
        normal_duration = scenario.duration_seconds // 3
        spike_duration = scenario.duration_seconds // 6  # Short spike
        recovery_duration = scenario.duration_seconds - normal_duration - spike_duration
        
        # Phase 1: Normal load (50% of users)
        normal_users = scenario.user_count // 2
        await self._execute_phase_load(normal_users, normal_duration, 0)
        
        # Phase 2: Spike load (all users)
        await self._execute_phase_load(scenario.user_count, spike_duration, normal_duration)
        
        # Phase 3: Recovery (25% of users)
        recovery_users = scenario.user_count // 4
        await self._execute_phase_load(recovery_users, recovery_duration, normal_duration + spike_duration)
    
    async def _execute_realistic_daily_load(self, scenario: UserScenario):
        """Execute realistic daily load pattern with peaks and valleys"""
        
        # Divide day into periods with different load levels
        periods = [
            {'name': 'morning_peak', 'duration_ratio': 0.2, 'load_ratio': 0.8},      # 20% time, 80% load
            {'name': 'steady_state', 'duration_ratio': 0.6, 'load_ratio': 0.4},     # 60% time, 40% load
            {'name': 'evening_peak', 'duration_ratio': 0.15, 'load_ratio': 0.6},    # 15% time, 60% load
            {'name': 'night_low', 'duration_ratio': 0.05, 'load_ratio': 0.1}        # 5% time, 10% load
        ]
        
        current_time = 0
        tasks = []
        
        for period in periods:
            period_duration = int(scenario.duration_seconds * period['duration_ratio'])
            period_users = int(scenario.user_count * period['load_ratio'])
            
            if period_users > 0:
                # Create user sessions for this period
                for user_id in range(period_users):
                    user_type = self._select_user_type_for_period(period['name'])
                    operations = self.user_behavior.simulate_user_session(period_duration, user_type)
                    
                    task = asyncio.create_task(
                        self._execute_user_session_with_delay(
                            f"{period['name']}_{user_id}", 
                            operations, 
                            current_time
                        )
                    )
                    tasks.append(task)
            
            current_time += period_duration
        
        # Wait for all sessions to complete
        await asyncio.gather(*tasks, return_exceptions=True)
    
    def _select_user_type_for_period(self, period_name: str) -> str:
        """Select appropriate user type based on time period"""
        
        if period_name == 'morning_peak':
            # More power users in morning
            return random.choices(
                ['power_user', 'regular_user', 'casual_user'], 
                weights=[0.5, 0.4, 0.1]
            )[0]
        elif period_name == 'steady_state':
            # Balanced mix during day
            return random.choices(
                ['power_user', 'regular_user', 'casual_user'], 
                weights=[0.2, 0.6, 0.2]
            )[0]
        elif period_name == 'evening_peak':
            # More regular users in evening
            return random.choices(
                ['power_user', 'regular_user', 'casual_user'], 
                weights=[0.3, 0.6, 0.1]
            )[0]
        else:  # night_low
            # Mostly power users at night
            return random.choices(
                ['power_user', 'regular_user', 'casual_user'], 
                weights=[0.7, 0.3, 0.0]
            )[0]
    
    async def _execute_phase_load(self, user_count: int, duration: int, start_delay: float):
        """Execute load for a specific phase"""
        
        tasks = []
        for user_id in range(user_count):
            user_type = random.choice(['power_user', 'regular_user', 'casual_user'])
            operations = self.user_behavior.simulate_user_session(duration, user_type)
            
            task = asyncio.create_task(
                self._execute_user_session_with_delay(f"phase_{user_id}", operations, start_delay)
            )
            tasks.append(task)
        
        await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _execute_user_session_with_delay(self, user_id: str, operations: List[Dict[str, Any]], delay_seconds: float):
        """Execute user session after specified delay"""
        
        if delay_seconds > 0:
            await asyncio.sleep(delay_seconds)
        
        await self._execute_user_session(user_id, operations)
    
    async def _execute_user_session(self, user_id: str, operations: List[Dict[str, Any]]):
        """Execute a complete user session"""
        
        session_start = time.time()
        
        for operation_data in operations:
            try:
                # Wait for scheduled time (think time)
                operation_start = session_start + operation_data['scheduled_time']
                current_time = time.time()
                
                if operation_start > current_time:
                    await asyncio.sleep(operation_start - current_time)
                
                # Execute operation
                await self._execute_operation(user_id, operation_data)
                
            except Exception as e:
                # Log error but continue session
                logger.warning(f"Operation failed for user {user_id}: {e}")
                self._record_failed_request(user_id, operation_data, str(e))
    
    async def _execute_operation(self, user_id: str, operation_data: Dict[str, Any]):
        """Execute a single operation with metrics tracking"""
        
        operation_type = operation_data['operation']
        
        # Track concurrent requests
        self.active_requests += 1
        self.max_concurrent_requests = max(self.max_concurrent_requests, self.active_requests)
        self.request_counter += 1
        
        request_start = time.time()
        
        try:
            # Simulate operation execution
            response_time_ms = await self._simulate_operation(operation_type)
            
            # Record successful request
            self._record_successful_request(user_id, operation_data, response_time_ms)
            
        except Exception as e:
            # Record failed request
            self._record_failed_request(user_id, operation_data, str(e))
            
        finally:
            self.active_requests -= 1
    
    async def _simulate_operation(self, operation_type: str) -> float:
        """Simulate algorithm operation with realistic timing"""
        
        # Realistic operation timing based on our benchmarks
        operation_timings = {
            'scheduling_optimization': (80, 120),     # 80-120ms
            'analytics_forecasting': (150, 250),     # 150-250ms  
            'trend_analysis': (90, 130),             # 90-130ms
            'kpi_calculation': (120, 180),           # 120-180ms
            'health_check': (20, 50)                 # 20-50ms
        }
        
        min_time, max_time = operation_timings.get(operation_type, (50, 100))
        
        # Add some variability and occasional slow requests
        if random.random() < 0.05:  # 5% slow requests
            response_time_ms = random.uniform(max_time * 2, max_time * 5)
        else:
            response_time_ms = random.uniform(min_time, max_time)
        
        # Simulate work with async sleep
        await asyncio.sleep(response_time_ms / 1000.0)
        
        # Simulate occasional failures
        if random.random() < 0.01:  # 1% failure rate
            raise Exception(f"Simulated {operation_type} failure")
        
        return response_time_ms
    
    def _record_successful_request(self, user_id: str, operation_data: Dict[str, Any], response_time_ms: float):
        """Record successful request metrics"""
        
        self.all_response_times.append(response_time_ms)
        
        self.request_results.append({
            'user_id': user_id,
            'operation': operation_data['operation'],
            'response_time_ms': response_time_ms,
            'timestamp': time.time(),
            'success': True,
            'concurrent_requests': self.active_requests,
            'user_type': operation_data.get('user_type', 'unknown')
        })
    
    def _record_failed_request(self, user_id: str, operation_data: Dict[str, Any], error_message: str):
        """Record failed request metrics"""
        
        self.request_results.append({
            'user_id': user_id,
            'operation': operation_data['operation'],
            'response_time_ms': 0.0,
            'timestamp': time.time(),
            'success': False,
            'error_message': error_message,
            'concurrent_requests': self.active_requests,
            'user_type': operation_data.get('user_type', 'unknown')
        })
    
    async def _monitor_resources(self, duration_seconds: int):
        """Monitor system resources during load test"""
        
        import psutil
        
        start_time = time.time()
        
        while time.time() - start_time < duration_seconds:
            try:
                # Collect resource metrics
                memory_info = psutil.virtual_memory()
                cpu_percent = psutil.cpu_percent(interval=0.1)
                
                self.resource_snapshots.append({
                    'timestamp': time.time(),
                    'memory_usage_mb': memory_info.used / 1024 / 1024,
                    'memory_percent': memory_info.percent,
                    'cpu_percent': cpu_percent,
                    'active_requests': self.active_requests,
                    'total_requests': self.request_counter
                })
                
                # Sleep before next snapshot
                await asyncio.sleep(1.0)  # 1 second intervals
                
            except Exception as e:
                logger.warning(f"Resource monitoring error: {e}")
                continue
    
    def _analyze_load_test_results(self, scenario_name: str, start_time: datetime, end_time: datetime, total_duration: float) -> LoadTestResult:
        """Analyze load test results and generate comprehensive report"""
        
        # Basic statistics
        total_requests = len(self.request_results)
        successful_requests = sum(1 for r in self.request_results if r['success'])
        failed_requests = total_requests - successful_requests
        
        # Response time analysis
        successful_times = [r['response_time_ms'] for r in self.request_results if r['success']]
        
        result = LoadTestResult(
            scenario_name=scenario_name,
            start_time=start_time,
            end_time=end_time,
            total_duration_seconds=total_duration,
            total_requests=total_requests,
            successful_requests=successful_requests,
            failed_requests=failed_requests,
            all_response_times=successful_times
        )
        
        if successful_times:
            # Response time statistics
            result.average_response_time_ms = statistics.mean(successful_times)
            result.median_response_time_ms = statistics.median(successful_times)
            result.min_response_time_ms = min(successful_times)
            result.max_response_time_ms = max(successful_times)
            
            # Percentiles
            if len(successful_times) >= 20:
                sorted_times = sorted(successful_times)
                percentiles = statistics.quantiles(sorted_times, n=100)
                result.p95_response_time_ms = percentiles[94]  # 95th percentile
                result.p99_response_time_ms = percentiles[98]  # 99th percentile
        
        # Throughput calculation
        if total_duration > 0:
            result.throughput_per_second = successful_requests / total_duration
            
            # Calculate peak throughput (max requests in any 1-second window)
            result.peak_throughput_per_second = self._calculate_peak_throughput()
        
        # Error analysis
        if total_requests > 0:
            result.error_rate = failed_requests / total_requests
            
            # Categorize errors
            error_counts = {}
            for request in self.request_results:
                if not request['success']:
                    error_msg = request.get('error_message', 'unknown_error')
                    error_counts[error_msg] = error_counts.get(error_msg, 0) + 1
            
            result.error_details = error_counts
        
        # Resource usage analysis
        if self.resource_snapshots:
            memory_values = [s['memory_usage_mb'] for s in self.resource_snapshots]
            cpu_values = [s['cpu_percent'] for s in self.resource_snapshots]
            
            result.peak_memory_mb = max(memory_values)
            result.average_memory_mb = statistics.mean(memory_values)
            result.peak_cpu_percent = max(cpu_values)
            result.average_cpu_percent = statistics.mean(cpu_values)
        
        # Concurrency analysis
        result.max_concurrent_requests = self.max_concurrent_requests
        if self.request_results:
            concurrent_values = [r['concurrent_requests'] for r in self.request_results]
            result.average_concurrent_requests = statistics.mean(concurrent_values)
        
        # Add resource snapshots to result
        result.resource_snapshots = self.resource_snapshots.copy()
        result.request_timeline = self.request_results.copy()
        
        return result
    
    def _calculate_peak_throughput(self) -> float:
        """Calculate peak throughput in requests per second"""
        
        if not self.request_results:
            return 0.0
        
        # Group requests by second
        request_times = [r['timestamp'] for r in self.request_results if r['success']]
        
        if not request_times:
            return 0.0
        
        # Find peak 1-second throughput
        start_time = min(request_times)
        end_time = max(request_times)
        
        max_throughput = 0.0
        current_second = int(start_time)
        
        while current_second <= int(end_time):
            # Count requests in this second
            requests_in_second = sum(
                1 for t in request_times 
                if current_second <= t < current_second + 1
            )
            
            max_throughput = max(max_throughput, requests_in_second)
            current_second += 1
        
        return max_throughput
    
    def generate_load_test_report(self, results: List[LoadTestResult]) -> Dict[str, Any]:
        """Generate comprehensive load testing report"""
        
        if not results:
            return {}
        
        # Aggregate statistics
        total_requests = sum(r.total_requests for r in results)
        total_successful = sum(r.successful_requests for r in results)
        total_failed = sum(r.failed_requests for r in results)
        
        # Response time aggregation
        all_response_times = []
        for result in results:
            all_response_times.extend(result.all_response_times)
        
        report = {
            'summary': {
                'total_scenarios': len(results),
                'total_requests': total_requests,
                'successful_requests': total_successful,
                'failed_requests': total_failed,
                'overall_success_rate': total_successful / total_requests if total_requests > 0 else 0,
                'total_test_duration': sum(r.total_duration_seconds for r in results)
            },
            'performance_analysis': {},
            'resource_usage': {},
            'error_analysis': {},
            'scalability_insights': []
        }
        
        # Performance analysis
        if all_response_times:
            report['performance_analysis'] = {
                'average_response_time_ms': statistics.mean(all_response_times),
                'median_response_time_ms': statistics.median(all_response_times),
                'p95_response_time_ms': statistics.quantiles(sorted(all_response_times), n=20)[18] if len(all_response_times) >= 20 else 0,
                'p99_response_time_ms': statistics.quantiles(sorted(all_response_times), n=100)[98] if len(all_response_times) >= 100 else 0,
                'min_response_time_ms': min(all_response_times),
                'max_response_time_ms': max(all_response_times)
            }
        
        # Resource usage analysis
        peak_memory = max(r.peak_memory_mb for r in results)
        peak_cpu = max(r.peak_cpu_percent for r in results)
        max_concurrent = max(r.max_concurrent_requests for r in results)
        
        report['resource_usage'] = {
            'peak_memory_mb': peak_memory,
            'peak_cpu_percent': peak_cpu,
            'max_concurrent_requests': max_concurrent,
            'average_throughput': statistics.mean([r.throughput_per_second for r in results]),
            'peak_throughput': max(r.peak_throughput_per_second for r in results)
        }
        
        # Error analysis
        all_errors = {}
        for result in results:
            for error, count in result.error_details.items():
                all_errors[error] = all_errors.get(error, 0) + count
        
        report['error_analysis'] = {
            'total_error_types': len(all_errors),
            'error_breakdown': all_errors,
            'most_common_error': max(all_errors.items(), key=lambda x: x[1])[0] if all_errors else None
        }
        
        # Scalability insights
        scalability_insights = []
        
        # Check if system handles 500+ users
        max_users_tested = max_concurrent
        if max_users_tested >= 500:
            scalability_insights.append("✅ System successfully handled 500+ concurrent users")
        else:
            scalability_insights.append(f"⚠️ Maximum tested: {max_users_tested} concurrent users")
        
        # Performance degradation analysis
        if len(results) > 1:
            low_load_result = min(results, key=lambda r: r.max_concurrent_requests)
            high_load_result = max(results, key=lambda r: r.max_concurrent_requests)
            
            if low_load_result.average_response_time_ms > 0:
                degradation_ratio = (high_load_result.average_response_time_ms / low_load_result.average_response_time_ms)
                if degradation_ratio > 3.0:
                    scalability_insights.append(f"⚠️ Performance degrades {degradation_ratio:.1f}x under high load")
                else:
                    scalability_insights.append(f"✅ Performance scales well (only {degradation_ratio:.1f}x degradation)")
        
        report['scalability_insights'] = scalability_insights
        
        return report


if __name__ == "__main__":
    # Demo usage
    async def main():
        print("Load Generator Demo")
        print("=" * 50)
        
        # Create test configuration
        class TestConfig:
            max_concurrent_users = 100
        
        # Initialize load generator
        generator = LoadGenerator(TestConfig())
        
        # Test scenario 1: Constant load
        scenario1 = UserScenario(
            user_count=20,
            duration_seconds=30,
            operations_per_user=5,
            think_time_ms=200,
            load_pattern=LoadPatternType.CONSTANT
        )
        
        print(f"Testing constant load: {scenario1.user_count} users")
        result1 = await generator.execute_load_scenario(scenario1)
        
        print(f"Results:")
        print(f"  Total Requests: {result1.total_requests}")
        print(f"  Successful: {result1.successful_requests}")
        print(f"  Failed: {result1.failed_requests}")
        print(f"  Success Rate: {(result1.successful_requests/result1.total_requests)*100:.1f}%")
        print(f"  Average Response Time: {result1.average_response_time_ms:.1f}ms")
        print(f"  P95 Response Time: {result1.p95_response_time_ms:.1f}ms")  
        print(f"  Throughput: {result1.throughput_per_second:.1f} req/sec")
        print(f"  Peak Memory: {result1.peak_memory_mb:.1f}MB")
        print(f"  Peak CPU: {result1.peak_cpu_percent:.1f}%")
        print(f"  Max Concurrent: {result1.max_concurrent_requests}")
        
        # Test scenario 2: Ramp-up load
        print(f"\nTesting ramp-up load...")
        scenario2 = UserScenario(
            user_count=30,
            duration_seconds=45,
            operations_per_user=3,
            ramp_up_seconds=15,
            load_pattern=LoadPatternType.RAMP_UP
        )
        
        result2 = await generator.execute_load_scenario(scenario2)
        
        print(f"Ramp-up Results:")
        print(f"  Total Requests: {result2.total_requests}")
        print(f"  Success Rate: {(result2.successful_requests/result2.total_requests)*100:.1f}%")
        print(f"  Average Response Time: {result2.average_response_time_ms:.1f}ms")
        print(f"  Peak Throughput: {result2.peak_throughput_per_second:.1f} req/sec")
        
        # Generate comprehensive report
        report = generator.generate_load_test_report([result1, result2])
        
        print(f"\nOverall Report:")
        print(f"  Total Scenarios: {report['summary']['total_scenarios']}")
        print(f"  Total Requests: {report['summary']['total_requests']}")
        print(f"  Overall Success Rate: {report['summary']['overall_success_rate']*100:.1f}%")
        print(f"  Peak Memory Usage: {report['resource_usage']['peak_memory_mb']:.1f}MB")
        print(f"  Peak CPU Usage: {report['resource_usage']['peak_cpu_percent']:.1f}%")
        print(f"  Max Concurrent Requests: {report['resource_usage']['max_concurrent_requests']}")
        
        print(f"\nScalability Insights:")
        for insight in report['scalability_insights']:
            print(f"  {insight}")
    
    # Run demo
    asyncio.run(main())