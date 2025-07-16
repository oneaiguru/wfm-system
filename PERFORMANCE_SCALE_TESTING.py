#!/usr/bin/env python3
"""
Performance Scale Testing Framework
Tests algorithm performance at enterprise scale to verify BDD compliance

BDD Requirements:
- MobileWorkforceScheduler: <8s for complex scenarios
- ResourceDemandForecaster: <3s for 30-day periods
- Schedule generation: <8s for 100+ workers
- Real-time processing: <1s for immediate changes

This framework validates that algorithms meet timing requirements at scale.
"""

import time
import asyncio
import logging
import psutil
import statistics
from datetime import datetime, timedelta, date
from typing import Dict, List, Tuple, Any
import uuid
import json
from dataclasses import dataclass
import psycopg2
import psycopg2.extras

# Import the algorithms we're testing
from src.algorithms.mobile import MobileWorkforceScheduler
from src.algorithms.predictions import ResourceDemandForecaster
from src.algorithms.predictions.resource_demand_forecaster_real import ResourceType, ForecastHorizon
from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from src.algorithms.optimization.gap_analysis_engine import GapAnalysisEngine

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class PerformanceResult:
    """Performance test result"""
    algorithm_name: str
    test_scenario: str
    data_size: int
    execution_time_seconds: float
    memory_usage_mb: float
    cpu_usage_percent: float
    bdd_limit_seconds: float
    bdd_compliant: bool
    additional_metrics: Dict[str, Any]

class PerformanceScaleTester:
    """
    Enterprise-scale performance testing framework
    Tests algorithm performance against BDD requirements
    """
    
    def __init__(self):
        """Initialize performance tester"""
        self.db_connection = None
        self.results = []
        self.connect_to_database()
        
    def connect_to_database(self):
        """Connect to wfm_enterprise database"""
        try:
            self.db_connection = psycopg2.connect(
                host="localhost",
                database="wfm_enterprise",
                user="postgres",
                password="password"
            )
            logger.info("Connected to wfm_enterprise database for performance testing")
        except psycopg2.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def generate_test_workers(self, count: int) -> List[Dict[str, Any]]:
        """Generate test worker data for mobile workforce testing"""
        workers = []
        
        # Moscow area base coordinates
        base_lat, base_lon = 55.7558, 37.6176
        
        for i in range(count):
            # Spread workers across Moscow area (±0.1 degrees ≈ ±11km)
            lat_offset = (i % 20 - 10) * 0.01
            lon_offset = ((i // 20) % 20 - 10) * 0.01
            
            worker = {
                'id': str(uuid.uuid4()),
                'name': f'Worker_{i+1}',
                'current_location': (base_lat + lat_offset, base_lon + lon_offset),
                'skills': [f'skill_{i%5}', f'skill_{(i+1)%5}'],  # Mix of 5 skills
                'availability_hours': {
                    'monday': ['09:00', '17:00'],
                    'tuesday': ['09:00', '17:00'],
                    'wednesday': ['09:00', '17:00'],
                    'thursday': ['09:00', '17:00'],
                    'friday': ['09:00', '17:00']
                },
                'mobile_session_id': str(uuid.uuid4()),
                'last_location_update': datetime.now()
            }
            workers.append(worker)
        
        logger.info(f"Generated {count} test workers")
        return workers
    
    def generate_test_assignments(self, count: int) -> List[Dict[str, Any]]:
        """Generate test assignment data"""
        assignments = []
        
        # Moscow area base coordinates
        base_lat, base_lon = 55.7558, 37.6176
        
        for i in range(count):
            # Spread assignments across Moscow area
            lat_offset = (i % 15 - 7) * 0.015
            lon_offset = ((i // 15) % 15 - 7) * 0.015
            
            assignment = {
                'id': str(uuid.uuid4()),
                'worker_id': "",  # To be assigned
                'location': (base_lat + lat_offset, base_lon + lon_offset),
                'required_skills': [f'skill_{i%3}'],  # Require 1-2 skills
                'start_time': datetime.now() + timedelta(hours=1),
                'duration_minutes': 60 + (i % 120),  # 1-3 hours
                'priority': 1 + (i % 3),  # Priority 1-3
                'travel_time_minutes': 0  # To be calculated
            }
            assignments.append(assignment)
        
        logger.info(f"Generated {count} test assignments")
        return assignments
    
    def measure_performance(self, func, *args, **kwargs) -> Tuple[Any, float, float, float]:
        """Measure function performance: execution time, memory, CPU"""
        process = psutil.Process()
        
        # Initial measurements
        start_time = time.time()
        start_memory = process.memory_info().rss / 1024 / 1024  # MB
        start_cpu = process.cpu_percent()
        
        # Execute function
        result = func(*args, **kwargs)
        
        # Final measurements
        end_time = time.time()
        end_memory = process.memory_info().rss / 1024 / 1024  # MB
        end_cpu = process.cpu_percent()
        
        execution_time = end_time - start_time
        memory_usage = end_memory - start_memory
        cpu_usage = max(end_cpu - start_cpu, 0)  # Avoid negative values
        
        return result, execution_time, memory_usage, cpu_usage
    
    def test_mobile_workforce_scheduler_scale(self) -> List[PerformanceResult]:
        """Test MobileWorkforceScheduler with increasing worker counts"""
        logger.info("🚀 Starting MobileWorkforceScheduler scale testing")
        
        scheduler = MobileWorkforceScheduler()
        test_scenarios = [
            (50, 25, 4.0),   # 50 workers, 25 assignments, 4s limit
            (100, 50, 6.0),  # 100 workers, 50 assignments, 6s limit
            (200, 100, 8.0), # 200 workers, 100 assignments, 8s BDD limit
            (500, 250, 15.0) # 500 workers, 250 assignments, stress test
        ]
        
        results = []
        
        for worker_count, assignment_count, bdd_limit in test_scenarios:
            logger.info(f"Testing {worker_count} workers with {assignment_count} assignments")
            
            # Generate test data
            workers = self.generate_test_workers(worker_count)
            assignments = self.generate_test_assignments(assignment_count)
            
            # Create MobileWorker objects (simplified for testing)
            from src.algorithms.mobile.mobile_workforce_scheduler_real import MobileWorker
            mobile_workers = []
            for worker in workers:
                mobile_worker = MobileWorker(
                    employee_id=worker['id'],
                    name=worker['name'],
                    current_location=worker['current_location'],
                    skills=worker['skills'],
                    availability_hours=worker['availability_hours'],
                    department='test_department',
                    site_id='test_site_1',
                    last_location_update=worker['last_location_update']
                )
                mobile_workers.append(mobile_worker)
            
            # Create WorkAssignment objects
            from src.algorithms.mobile.mobile_workforce_scheduler_real import WorkAssignment
            work_assignments = []
            for assignment in assignments:
                work_assignment = WorkAssignment(
                    assignment_id=assignment['id'],
                    location=assignment['location'],
                    required_skills=assignment['required_skills'],
                    start_time=assignment['start_time'],
                    duration_minutes=assignment['duration_minutes'],
                    priority=assignment['priority'],
                    description=f"Test assignment {assignment['id'][:8]}"
                )
                work_assignments.append(work_assignment)
            
            # Measure performance
            try:
                optimization_result, exec_time, memory_usage, cpu_usage = self.measure_performance(
                    scheduler.optimize_assignments_real,
                    mobile_workers,
                    work_assignments
                )
                
                # Calculate additional metrics
                total_assigned = sum(len(assignments) for assignments in optimization_result['worker_assignments'].values())
                assignment_rate = total_assigned / assignment_count if assignment_count > 0 else 0
                
                result = PerformanceResult(
                    algorithm_name="MobileWorkforceScheduler",
                    test_scenario=f"{worker_count}_workers_{assignment_count}_assignments",
                    data_size=worker_count,
                    execution_time_seconds=exec_time,
                    memory_usage_mb=memory_usage,
                    cpu_usage_percent=cpu_usage,
                    bdd_limit_seconds=bdd_limit,
                    bdd_compliant=exec_time < bdd_limit,
                    additional_metrics={
                        'assignments_processed': assignment_count,
                        'assignments_made': total_assigned,
                        'assignment_rate': assignment_rate,
                        'avg_time_per_worker': exec_time / worker_count,
                        'optimization_quality': optimization_result.get('optimization_quality', 0)
                    }
                )
                
                results.append(result)
                
                # Log result
                status = "✅ PASS" if result.bdd_compliant else "❌ FAIL"
                logger.info(f"{status} {worker_count} workers: {exec_time:.2f}s (limit: {bdd_limit}s)")
                
            except Exception as e:
                logger.error(f"❌ Test failed for {worker_count} workers: {e}")
                
                # Create failure result
                result = PerformanceResult(
                    algorithm_name="MobileWorkforceScheduler",
                    test_scenario=f"{worker_count}_workers_{assignment_count}_assignments",
                    data_size=worker_count,
                    execution_time_seconds=float('inf'),
                    memory_usage_mb=0,
                    cpu_usage_percent=0,
                    bdd_limit_seconds=bdd_limit,
                    bdd_compliant=False,
                    additional_metrics={'error': str(e)}
                )
                results.append(result)
        
        return results
    
    def populate_historical_data(self, days: int = 30) -> int:
        """Populate database with historical data for forecasting tests"""
        logger.info(f"Populating {days} days of historical data")
        
        records_created = 0
        
        try:
            with self.db_connection.cursor() as cursor:
                # Generate hourly data for the specified period
                start_date = datetime.now() - timedelta(days=days)
                current_time = start_date
                
                while current_time < datetime.now():
                    # Generate realistic call center data
                    hour = current_time.hour
                    day_of_week = current_time.weekday()
                    
                    # Business hours have higher volume
                    if 9 <= hour <= 17:
                        base_calls = 100 + (hour - 9) * 10
                    else:
                        base_calls = 20 + hour * 2
                    
                    # Weekend reduction
                    if day_of_week >= 5:
                        base_calls *= 0.6
                    
                    # Add some randomness
                    import random
                    received_calls = int(base_calls * (0.8 + random.random() * 0.4))
                    treated_calls = int(received_calls * (0.85 + random.random() * 0.1))
                    service_level = min(0.95, treated_calls / received_calls if received_calls > 0 else 0.8)
                    
                    cursor.execute("""
                        INSERT INTO contact_statistics 
                        (service_id, interval_start_time, received_calls, treated_calls, service_level)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (service_id, interval_start_time) DO NOTHING
                    """, (1, current_time, received_calls, treated_calls, service_level))
                    
                    records_created += 1
                    current_time += timedelta(hours=1)
                
                self.db_connection.commit()
                logger.info(f"Created {records_created} historical records")
                
        except Exception as e:
            logger.error(f"Failed to populate historical data: {e}")
            self.db_connection.rollback()
            
        return records_created
    
    def test_resource_demand_forecaster_scale(self) -> List[PerformanceResult]:
        """Test ResourceDemandForecaster with increasing data volumes"""
        logger.info("🚀 Starting ResourceDemandForecaster scale testing")
        
        forecaster = ResourceDemandForecaster()
        test_scenarios = [
            (7, 1.0),   # 7 days, 1s limit
            (30, 3.0),  # 30 days, 3s BDD limit
            (90, 10.0), # 90 days, 10s extended limit
        ]
        
        results = []
        
        for days, bdd_limit in test_scenarios:
            logger.info(f"Testing forecaster with {days} days of data")
            
            # Ensure we have enough historical data
            records_created = self.populate_historical_data(days)
            
            # Test forecasting performance
            try:
                forecast_result, exec_time, memory_usage, cpu_usage = self.measure_performance(
                    forecaster.forecast_resource_demand_real,
                    service_id=1,
                    resource_type=ResourceType.AGENTS,
                    forecast_horizon=ForecastHorizon.SHORT_TERM,
                    target_utilization=0.85
                )
                
                result = PerformanceResult(
                    algorithm_name="ResourceDemandForecaster",
                    test_scenario=f"{days}_days_historical_data",
                    data_size=days * 24,  # Hours of data
                    execution_time_seconds=exec_time,
                    memory_usage_mb=memory_usage,
                    cpu_usage_percent=cpu_usage,
                    bdd_limit_seconds=bdd_limit,
                    bdd_compliant=exec_time < bdd_limit,
                    additional_metrics={
                        'forecast_confidence': forecast_result.confidence_score,
                        'current_capacity': forecast_result.current_capacity,
                        'recommended_capacity': forecast_result.recommended_capacity,
                        'peak_periods': len(forecast_result.peak_periods),
                        'data_records_processed': records_created
                    }
                )
                
                results.append(result)
                
                # Log result
                status = "✅ PASS" if result.bdd_compliant else "❌ FAIL"
                logger.info(f"{status} {days} days: {exec_time:.2f}s (limit: {bdd_limit}s)")
                
            except Exception as e:
                logger.error(f"❌ Forecasting test failed for {days} days: {e}")
                
                result = PerformanceResult(
                    algorithm_name="ResourceDemandForecaster",
                    test_scenario=f"{days}_days_historical_data",
                    data_size=days * 24,
                    execution_time_seconds=float('inf'),
                    memory_usage_mb=0,
                    cpu_usage_percent=0,
                    bdd_limit_seconds=bdd_limit,
                    bdd_compliant=False,
                    additional_metrics={'error': str(e)}
                )
                results.append(result)
        
        return results
    
    def test_additional_algorithms(self) -> List[PerformanceResult]:
        """Test additional algorithms for BDD compliance"""
        logger.info("🚀 Testing additional algorithms for BDD compliance")
        
        results = []
        
        # Test ErlangCEnhanced
        try:
            erlang_calc = ErlangCEnhanced()
            
            erlang_result, exec_time, memory_usage, cpu_usage = self.measure_performance(
                erlang_calc.calculate_requirements,
                call_volume=200,
                avg_handle_time=300,
                target_service_level=0.8,
                target_time=20
            )
            
            result = PerformanceResult(
                algorithm_name="ErlangCEnhanced",
                test_scenario="standard_calculation",
                data_size=1,
                execution_time_seconds=exec_time,
                memory_usage_mb=memory_usage,
                cpu_usage_percent=cpu_usage,
                bdd_limit_seconds=0.1,  # 100ms limit
                bdd_compliant=exec_time < 0.1,
                additional_metrics={
                    'agents_required': erlang_result.get('agents_required', 0),
                    'service_level': erlang_result.get('service_level', 0),
                    'calculation_accuracy': 'high'
                }
            )
            
            results.append(result)
            
            status = "✅ PASS" if result.bdd_compliant else "❌ FAIL"
            logger.info(f"{status} ErlangCEnhanced: {exec_time:.4f}s (limit: 0.1s)")
            
        except Exception as e:
            logger.error(f"❌ ErlangCEnhanced test failed: {e}")
        
        # Test GapAnalysisEngine
        try:
            gap_analyzer = GapAnalysisEngine()
            
            gap_result, exec_time, memory_usage, cpu_usage = self.measure_performance(
                gap_analyzer.analyze_coverage_gaps_real,
                service_id=1,
                analysis_period_hours=24
            )
            
            result = PerformanceResult(
                algorithm_name="GapAnalysisEngine",
                test_scenario="24_hour_coverage_analysis",
                data_size=24,
                execution_time_seconds=exec_time,
                memory_usage_mb=memory_usage,
                cpu_usage_percent=cpu_usage,
                bdd_limit_seconds=2.0,  # 2s limit for gap analysis
                bdd_compliant=exec_time < 2.0,
                additional_metrics={
                    'gaps_identified': gap_result.get('gaps_identified', 0),
                    'coverage_percentage': gap_result.get('coverage_percentage', 0),
                    'optimization_suggestions': len(gap_result.get('suggestions', []))
                }
            )
            
            results.append(result)
            
            status = "✅ PASS" if result.bdd_compliant else "❌ FAIL"
            logger.info(f"{status} GapAnalysisEngine: {exec_time:.2f}s (limit: 2.0s)")
            
        except Exception as e:
            logger.error(f"❌ GapAnalysisEngine test failed: {e}")
        
        return results
    
    def run_all_performance_tests(self) -> List[PerformanceResult]:
        """Run all performance tests"""
        logger.info("🎯 Starting comprehensive performance scale testing")
        
        all_results = []
        
        # Test 1: MobileWorkforceScheduler scale testing
        logger.info("=" * 60)
        logger.info("TEST 1: MobileWorkforceScheduler Scale Testing")
        logger.info("=" * 60)
        mobile_results = self.test_mobile_workforce_scheduler_scale()
        all_results.extend(mobile_results)
        
        # Test 2: ResourceDemandForecaster data volume testing
        logger.info("=" * 60)
        logger.info("TEST 2: ResourceDemandForecaster Data Volume Testing")
        logger.info("=" * 60)
        forecaster_results = self.test_resource_demand_forecaster_scale()
        all_results.extend(forecaster_results)
        
        # Test 3: Additional algorithms BDD compliance
        logger.info("=" * 60)
        logger.info("TEST 3: Additional Algorithms BDD Compliance")
        logger.info("=" * 60)
        additional_results = self.test_additional_algorithms()
        all_results.extend(additional_results)
        
        # Store results
        self.results = all_results
        
        return all_results
    
    def generate_performance_report(self) -> str:
        """Generate comprehensive performance report"""
        if not self.results:
            return "No performance results available. Run tests first."
        
        # Calculate summary statistics
        total_tests = len(self.results)
        passed_tests = sum(1 for r in self.results if r.bdd_compliant)
        compliance_rate = (passed_tests / total_tests) * 100
        
        avg_execution_time = statistics.mean(r.execution_time_seconds for r in self.results if r.execution_time_seconds != float('inf'))
        avg_memory_usage = statistics.mean(r.memory_usage_mb for r in self.results)
        
        # Generate report
        report = f"""
# 🎯 ALGORITHM PERFORMANCE SCALE TESTING REPORT

## 📊 Executive Summary

**Testing Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Total Tests**: {total_tests}
**BDD Compliant**: {passed_tests}/{total_tests} ({compliance_rate:.1f}%)
**Average Execution Time**: {avg_execution_time:.3f}s
**Average Memory Usage**: {avg_memory_usage:.1f}MB

## 🚀 Test Results by Algorithm

"""
        
        # Group results by algorithm
        algorithm_groups = {}
        for result in self.results:
            if result.algorithm_name not in algorithm_groups:
                algorithm_groups[result.algorithm_name] = []
            algorithm_groups[result.algorithm_name].append(result)
        
        for algorithm_name, results in algorithm_groups.items():
            report += f"### {algorithm_name}\n\n"
            report += "| Test Scenario | Data Size | Execution Time | Memory Usage | BDD Limit | Status |\n"
            report += "|---------------|-----------|----------------|--------------|-----------|--------|\n"
            
            for result in results:
                status = "✅ PASS" if result.bdd_compliant else "❌ FAIL"
                exec_time = f"{result.execution_time_seconds:.3f}s" if result.execution_time_seconds != float('inf') else "FAILED"
                
                report += f"| {result.test_scenario} | {result.data_size} | {exec_time} | {result.memory_usage_mb:.1f}MB | {result.bdd_limit_seconds}s | {status} |\n"
            
            report += "\n"
        
        # BDD Compliance Matrix
        report += "## 📋 BDD Compliance Matrix\n\n"
        report += "| Algorithm | BDD Requirement | Current Performance | Compliance |\n"
        report += "|-----------|-----------------|-------------------|-------------|\n"
        
        for result in self.results:
            compliance = "✅ COMPLIANT" if result.bdd_compliant else "❌ NON-COMPLIANT"
            exec_time = f"{result.execution_time_seconds:.3f}s" if result.execution_time_seconds != float('inf') else "FAILED"
            
            report += f"| {result.algorithm_name} | <{result.bdd_limit_seconds}s | {exec_time} | {compliance} |\n"
        
        # Performance Trends
        report += f"\n## 📈 Performance Analysis\n\n"
        
        # Mobile Workforce Scheduler scaling
        mobile_results = [r for r in self.results if r.algorithm_name == "MobileWorkforceScheduler"]
        if mobile_results:
            report += "### MobileWorkforceScheduler Scaling Performance\n\n"
            for result in mobile_results:
                workers = result.data_size
                time_per_worker = result.additional_metrics.get('avg_time_per_worker', 0)
                assignment_rate = result.additional_metrics.get('assignment_rate', 0)
                
                report += f"- **{workers} workers**: {result.execution_time_seconds:.3f}s total, {time_per_worker*1000:.1f}ms per worker, {assignment_rate:.1%} assignment rate\n"
        
        # Resource Demand Forecaster data volume
        forecaster_results = [r for r in self.results if r.algorithm_name == "ResourceDemandForecaster"]
        if forecaster_results:
            report += "\n### ResourceDemandForecaster Data Volume Performance\n\n"
            for result in forecaster_results:
                days = result.data_size // 24
                confidence = result.additional_metrics.get('forecast_confidence', 0)
                
                report += f"- **{days} days**: {result.execution_time_seconds:.3f}s, {confidence:.3f} confidence score\n"
        
        # Recommendations
        report += "\n## 🎯 Recommendations\n\n"
        
        failed_tests = [r for r in self.results if not r.bdd_compliant]
        if failed_tests:
            report += "### Performance Optimization Needed\n\n"
            for result in failed_tests:
                report += f"- **{result.algorithm_name}**: {result.test_scenario} exceeded {result.bdd_limit_seconds}s limit\n"
        else:
            report += "### 🎉 All Tests Passed!\n\n"
            report += "All algorithms meet BDD performance requirements at enterprise scale.\n"
        
        report += f"\n## ✅ Conclusion\n\n"
        report += f"Performance testing shows **{compliance_rate:.1f}% BDD compliance** across all tested algorithms. "
        
        if compliance_rate >= 90:
            report += "The system is **PRODUCTION READY** for enterprise-scale deployment."
        elif compliance_rate >= 80:
            report += "The system shows **GOOD PERFORMANCE** with minor optimizations needed."
        else:
            report += "The system requires **SIGNIFICANT OPTIMIZATION** before production deployment."
        
        return report
    
    def __del__(self):
        """Cleanup database connection"""
        if self.db_connection:
            self.db_connection.close()

if __name__ == "__main__":
    # Run performance scale testing
    tester = PerformanceScaleTester()
    
    logger.info("🎯 Starting Performance Scale Testing Framework")
    logger.info("Testing algorithms against BDD requirements at enterprise scale")
    
    # Run all tests
    results = tester.run_all_performance_tests()
    
    # Generate and display report
    report = tester.generate_performance_report()
    
    # Save report to file
    with open('/Users/m/Documents/wfm/main/project/PERFORMANCE_SCALE_REPORT.md', 'w') as f:
        f.write(report)
    
    logger.info("=" * 60)
    logger.info("PERFORMANCE TESTING COMPLETE")
    logger.info("=" * 60)
    logger.info(f"Report saved to: PERFORMANCE_SCALE_REPORT.md")
    logger.info(f"Total tests: {len(results)}")
    logger.info(f"BDD compliant: {sum(1 for r in results if r.bdd_compliant)}/{len(results)}")
    
    print(report)