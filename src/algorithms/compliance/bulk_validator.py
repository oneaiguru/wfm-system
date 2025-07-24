#!/usr/bin/env python3
"""
Bulk Compliance Validator
========================

High-performance batch compliance checking for large employee groups
with intelligent load balancing and concurrent processing.

Performance targets:
- 100+ employees: <1s validation time
- 1000+ employees: <10s validation time
- Memory efficient processing
- Progressive result streaming

Key features:
- Adaptive batch sizing based on system load
- Memory-efficient chunked processing  
- Real-time progress reporting
- Intelligent error recovery
"""

import logging
import time
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple, Iterator
from dataclasses import dataclass, asdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict
import uuid
import psutil

import numpy as np
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from .tk_rf_rule_engine import TKRFRuleEngine, ComplianceResult, BulkComplianceResult

logger = logging.getLogger(__name__)


@dataclass
class BatchConfig:
    """Configuration for batch processing"""
    batch_size: int
    max_concurrent: int
    memory_limit_mb: int
    timeout_seconds: int
    retry_attempts: int


@dataclass
class ProgressUpdate:
    """Progress update for long-running validations"""
    validation_id: str
    total_employees: int
    processed_employees: int
    compliant_count: int
    violation_count: int
    elapsed_seconds: float
    estimated_remaining_seconds: float
    current_batch: int
    total_batches: int


class BulkValidator:
    """High-performance bulk compliance validator"""
    
    def __init__(self, database_url: Optional[str] = None, redis_url: Optional[str] = None):
        # Initialize rule engine
        self.rule_engine = TKRFRuleEngine(database_url, redis_url)
        
        # Database connection for bulk queries
        if not database_url:
            database_url = "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        
        self.engine = create_engine(database_url, pool_size=20, max_overflow=30)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Performance optimization settings
        self.default_batch_size = 50  # Employees per batch
        self.max_concurrent_batches = 8  # Concurrent batch processors
        self.memory_limit_mb = 2048  # 2GB memory limit
        
        # Progress tracking
        self.active_validations = {}  # validation_id -> progress
        
        # System monitoring
        self.system_monitor = SystemResourceMonitor()
    
    async def validate_department_async(
        self,
        department_id: int,
        date_range: Tuple[datetime, datetime],
        progress_callback: Optional[callable] = None
    ) -> BulkComplianceResult:
        """
        Validate all employees in a department asynchronously.
        
        Args:
            department_id: Department to validate
            date_range: Date range for validation
            progress_callback: Optional callback for progress updates
            
        Returns:
            BulkComplianceResult with department compliance
        """
        # Get department employees
        employee_ids = self._get_department_employees(department_id)
        
        if not employee_ids:
            return BulkComplianceResult(
                validation_id=str(uuid.uuid4()),
                total_employees=0,
                compliant_employees=0,
                violation_count=0,
                validation_duration_ms=0,
                violations_by_type={},
                cache_hit_rate=0.0
            )
        
        return await self.validate_employee_list_async(
            employee_ids=employee_ids,
            date_range=date_range,
            validation_name=f"Department_{department_id}",
            progress_callback=progress_callback
        )
    
    async def validate_employee_list_async(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime],
        validation_name: str = "BulkValidation",
        progress_callback: Optional[callable] = None
    ) -> BulkComplianceResult:
        """
        Validate a list of employees with optimized batch processing.
        
        Args:
            employee_ids: List of employee IDs
            date_range: Date range for validation
            validation_name: Name for this validation run
            progress_callback: Optional progress callback
            
        Returns:
            BulkComplianceResult with aggregated results
        """
        start_time = time.time()
        validation_id = str(uuid.uuid4())
        
        # Adaptive batch configuration
        batch_config = self._calculate_optimal_batch_config(len(employee_ids))
        
        # Split into batches
        batches = self._create_batches(employee_ids, batch_config.batch_size)
        
        # Initialize progress tracking
        progress = ProgressUpdate(
            validation_id=validation_id,
            total_employees=len(employee_ids),
            processed_employees=0,
            compliant_count=0,
            violation_count=0,
            elapsed_seconds=0,
            estimated_remaining_seconds=0,
            current_batch=0,
            total_batches=len(batches)
        )
        
        self.active_validations[validation_id] = progress
        
        try:
            # Process batches concurrently
            all_results = []
            semaphore = asyncio.Semaphore(batch_config.max_concurrent)
            
            # Create batch tasks
            batch_tasks = []
            for batch_idx, batch in enumerate(batches):
                task = self._process_batch_async(
                    batch, 
                    date_range, 
                    batch_idx,
                    validation_id,
                    semaphore,
                    progress_callback
                )
                batch_tasks.append(task)
            
            # Execute batches with progress tracking
            for completed_task in asyncio.as_completed(batch_tasks):
                batch_results = await completed_task
                all_results.extend(batch_results)
                
                # Update progress
                progress.processed_employees = len(all_results)
                progress.compliant_count = sum(
                    1 for r in all_results if r.compliance_score >= 0.95
                )
                progress.violation_count = sum(
                    len(r.violations) for r in all_results
                )
                progress.elapsed_seconds = time.time() - start_time
                
                # Estimate remaining time
                if progress.processed_employees > 0:
                    avg_time_per_employee = progress.elapsed_seconds / progress.processed_employees
                    remaining_employees = progress.total_employees - progress.processed_employees
                    progress.estimated_remaining_seconds = avg_time_per_employee * remaining_employees
                
                # Call progress callback
                if progress_callback:
                    await progress_callback(progress)
            
            # Aggregate final results
            return self._aggregate_results(
                validation_id=validation_id,
                individual_results=all_results,
                total_duration_ms=(time.time() - start_time) * 1000
            )
            
        finally:
            # Clean up progress tracking
            if validation_id in self.active_validations:
                del self.active_validations[validation_id]
    
    async def _process_batch_async(
        self,
        employee_batch: List[int],
        date_range: Tuple[datetime, datetime],
        batch_idx: int,
        validation_id: str,
        semaphore: asyncio.Semaphore,
        progress_callback: Optional[callable]
    ) -> List[ComplianceResult]:
        """Process a single batch of employees asynchronously"""
        
        async with semaphore:
            # Pre-load batch data for efficiency
            batch_data = await self._preload_batch_data_async(employee_batch, date_range)
            
            # Process employees in batch
            batch_results = []
            
            loop = asyncio.get_event_loop()
            
            # Use ThreadPoolExecutor for CPU-intensive rule evaluation
            with ThreadPoolExecutor(max_workers=4) as executor:
                # Create validation tasks
                validation_futures = []
                
                for employee_id in employee_batch:
                    if employee_id in batch_data:
                        future = loop.run_in_executor(
                            executor,
                            self._validate_single_employee_sync,
                            employee_id,
                            date_range,
                            batch_data[employee_id]
                        )
                        validation_futures.append((employee_id, future))
                
                # Collect results
                for employee_id, future in validation_futures:
                    try:
                        result = await asyncio.wait_for(future, timeout=30)
                        batch_results.append(result)
                    except asyncio.TimeoutError:
                        logger.error(f"Validation timeout for employee {employee_id}")
                    except Exception as e:
                        logger.error(f"Validation error for employee {employee_id}: {e}")
        
        logger.info(
            f"Batch {batch_idx} completed: {len(batch_results)}/{len(employee_batch)} employees"
        )
        
        return batch_results
    
    async def _preload_batch_data_async(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime]
    ) -> Dict[int, Dict[str, Any]]:
        """Preload work data for a batch of employees"""
        
        loop = asyncio.get_event_loop()
        
        # Run database query in thread pool
        batch_data = await loop.run_in_executor(
            None,
            self._load_batch_work_data,
            employee_ids,
            date_range
        )
        
        return batch_data
    
    def _load_batch_work_data(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime]
    ) -> Dict[int, Dict[str, Any]]:
        """Load work data for multiple employees in single query"""
        
        with self.SessionLocal() as session:
            # Single query for all employee data
            results = session.execute(
                text("""
                    SELECT 
                        s.employee_id,
                        e.name,
                        e.employment_type,
                        p.name as position_name,
                        CASE WHEN e.birth_date < NOW() - INTERVAL '18 years' THEN 'adult' ELSE 'minor' END as age_category,
                        date_trunc('day', s.shift_date) as work_day,
                        SUM(EXTRACT(EPOCH FROM (s.end_time - s.start_time))/3600) as daily_hours,
                        COUNT(*) as shift_count,
                        SUM(CASE WHEN s.break_minutes < 30 THEN 1 ELSE 0 END) as insufficient_breaks,
                        SUM(CASE WHEN EXTRACT(EPOCH FROM (s.end_time - s.start_time))/3600 > 8 THEN 1 ELSE 0 END) as overtime_shifts
                    FROM schedules s
                    JOIN employees e ON s.employee_id = e.id
                    LEFT JOIN positions p ON e.position_id = p.id
                    WHERE s.employee_id = ANY(:employee_ids)
                    AND s.shift_date BETWEEN :start_date AND :end_date
                    AND s.status = 'confirmed'
                    GROUP BY s.employee_id, e.name, e.employment_type, p.name, 
                             e.birth_date, date_trunc('day', s.shift_date)
                    ORDER BY s.employee_id, work_day
                """),
                {
                    'employee_ids': employee_ids,
                    'start_date': date_range[0],
                    'end_date': date_range[1]
                }
            ).fetchall()
            
            # Organize data by employee
            batch_data = {}
            
            for row in results:
                employee_id = row.employee_id
                
                if employee_id not in batch_data:
                    batch_data[employee_id] = {
                        'employee_id': employee_id,
                        'name': row.name,
                        'employment_type': row.employment_type,
                        'position': row.position_name,
                        'age_category': row.age_category,
                        'work_days': []
                    }
                
                batch_data[employee_id]['work_days'].append({
                    'date': row.work_day,
                    'daily_hours': float(row.daily_hours or 0),
                    'shift_count': int(row.shift_count or 0),
                    'insufficient_breaks': int(row.insufficient_breaks or 0),
                    'overtime_shifts': int(row.overtime_shifts or 0)
                })
            
            return batch_data
    
    def _validate_single_employee_sync(
        self,
        employee_id: int,
        date_range: Tuple[datetime, datetime],
        employee_data: Dict[str, Any]
    ) -> ComplianceResult:
        """Validate single employee using preloaded data"""
        
        start_time = time.time()
        
        # Use rule engine's vectorized evaluation with preloaded data
        violations = self.rule_engine._evaluate_rules_vectorized(employee_data)
        compliance_score = self.rule_engine._calculate_compliance_score(violations)
        
        return ComplianceResult(
            employee_id=employee_id,
            check_date=datetime.utcnow(),
            violations=violations,
            compliance_score=compliance_score,
            check_duration_ms=(time.time() - start_time) * 1000,
            cache_hit=False  # Using preloaded data, not cache
        )
    
    def _calculate_optimal_batch_config(self, total_employees: int) -> BatchConfig:
        """Calculate optimal batch configuration based on system resources"""
        
        # Get system resources
        memory_gb = psutil.virtual_memory().total / (1024**3)
        cpu_count = psutil.cpu_count()
        
        # Adaptive batch sizing
        if total_employees <= 100:
            batch_size = 25
            max_concurrent = min(4, cpu_count)
        elif total_employees <= 1000:
            batch_size = 50
            max_concurrent = min(8, cpu_count)
        else:
            batch_size = 100  
            max_concurrent = min(12, cpu_count)
        
        # Memory limit based on available RAM
        memory_limit_mb = min(2048, int(memory_gb * 1024 * 0.25))  # 25% of RAM
        
        return BatchConfig(
            batch_size=batch_size,
            max_concurrent=max_concurrent,
            memory_limit_mb=memory_limit_mb,
            timeout_seconds=300,  # 5 minutes
            retry_attempts=2
        )
    
    def _create_batches(self, employee_ids: List[int], batch_size: int) -> List[List[int]]:
        """Split employee list into optimally sized batches"""
        
        batches = []
        for i in range(0, len(employee_ids), batch_size):
            batch = employee_ids[i:i + batch_size]
            batches.append(batch)
        
        return batches
    
    def _get_department_employees(self, department_id: int) -> List[int]:
        """Get all employee IDs in a department"""
        
        with self.SessionLocal() as session:
            results = session.execute(
                text("""
                    SELECT e.id 
                    FROM employees e 
                    JOIN departments d ON e.department_id = d.id 
                    WHERE d.id = :department_id 
                    AND e.is_active = true
                    ORDER BY e.id
                """),
                {'department_id': department_id}
            ).fetchall()
            
            return [row.id for row in results]
    
    def _aggregate_results(
        self,
        validation_id: str,
        individual_results: List[ComplianceResult],
        total_duration_ms: float
    ) -> BulkComplianceResult:
        """Aggregate individual compliance results into bulk result"""
        
        total_employees = len(individual_results)
        compliant_employees = sum(
            1 for r in individual_results if r.compliance_score >= 0.95
        )
        total_violations = sum(len(r.violations) for r in individual_results)
        
        # Violations by type
        violations_by_type = defaultdict(int)
        for result in individual_results:
            for violation in result.violations:
                v_type = violation.get('violation_type', 'unknown')
                violations_by_type[v_type] += 1
        
        # Cache hit rate (for preloaded data, this is always 0)
        cache_hit_rate = 0.0
        
        return BulkComplianceResult(
            validation_id=validation_id,
            total_employees=total_employees,
            compliant_employees=compliant_employees,
            violation_count=total_violations,
            validation_duration_ms=total_duration_ms,
            violations_by_type=dict(violations_by_type),
            cache_hit_rate=cache_hit_rate
        )
    
    def get_validation_progress(self, validation_id: str) -> Optional[ProgressUpdate]:
        """Get current progress for an active validation"""
        return self.active_validations.get(validation_id)
    
    def cancel_validation(self, validation_id: str) -> bool:
        """Cancel an active validation"""
        if validation_id in self.active_validations:
            # In a full implementation, this would signal cancellation
            # to the running tasks
            del self.active_validations[validation_id]
            return True
        return False


class SystemResourceMonitor:
    """Monitor system resources during bulk processing"""
    
    def __init__(self):
        self.memory_threshold = 80  # Percentage
        self.cpu_threshold = 90     # Percentage
    
    def should_throttle(self) -> bool:
        """Check if processing should be throttled due to resource usage"""
        
        memory_percent = psutil.virtual_memory().percent
        cpu_percent = psutil.cpu_percent(interval=1)
        
        return (
            memory_percent > self.memory_threshold or
            cpu_percent > self.cpu_threshold
        )
    
    def get_resource_stats(self) -> Dict[str, Any]:
        """Get current resource statistics"""
        
        memory = psutil.virtual_memory()
        cpu_percent = psutil.cpu_percent(interval=1)
        
        return {
            'memory_percent': memory.percent,
            'memory_available_gb': memory.available / (1024**3),
            'cpu_percent': cpu_percent,
            'cpu_count': psutil.cpu_count(),
            'load_average': psutil.getloadavg() if hasattr(psutil, 'getloadavg') else None
        }


if __name__ == "__main__":
    # Demo usage
    async def progress_callback(progress: ProgressUpdate):
        print(f"Progress: {progress.processed_employees}/{progress.total_employees} "
              f"({progress.processed_employees/progress.total_employees*100:.1f}%) - "
              f"Compliant: {progress.compliant_count}, "
              f"Violations: {progress.violation_count}")
    
    async def main():
        validator = BulkValidator(redis_url="redis://localhost:6379/0")
        
        # Validate department
        date_range = (
            datetime.utcnow() - timedelta(days=7),
            datetime.utcnow()
        )
        
        result = await validator.validate_department_async(
            department_id=1,
            date_range=date_range,
            progress_callback=progress_callback
        )
        
        print(f"\nDepartment Compliance Results:")
        print(f"  Total Employees: {result.total_employees}")
        print(f"  Compliant: {result.compliant_employees}")
        print(f"  Compliance Rate: {result.compliant_employees/max(1, result.total_employees)*100:.1f}%")
        print(f"  Total Violations: {result.violation_count}")
        print(f"  Validation Duration: {result.validation_duration_ms:.1f}ms")
        
        print(f"\nViolations by Type:")
        for v_type, count in result.violations_by_type.items():
            print(f"  {v_type}: {count}")
    
    # Run demo
    asyncio.run(main())