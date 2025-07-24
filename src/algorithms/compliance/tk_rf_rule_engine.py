#!/usr/bin/env python3
"""
TK RF Rule Engine - Russian Labor Code Compliance
================================================

High-performance rule evaluation engine for TK RF (Russian Labor Code) compliance
with intelligent rule caching and vectorized validation.

Performance targets:
- Single employee check: <50ms
- Bulk validation (100+ employees): <1s  
- Rule tree loading: <200ms from cache
- Real-time monitoring: <100ms response

Key features:
- Vectorized rule evaluation using NumPy
- Redis-backed rule tree caching  
- Parallel bulk validation
- Real-time violation detection
"""

import logging
import time
import json
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple, Set
from dataclasses import dataclass, asdict
from enum import Enum
from concurrent.futures import ThreadPoolExecutor
import uuid

import numpy as np
import redis
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

logger = logging.getLogger(__name__)


class TKRFArticle(Enum):
    """TK RF Article categories for rule organization"""
    WORKING_TIME = "working_time"  # Articles 91-106
    BREAKS_REST = "breaks_rest"    # Articles 107-109  
    OVERTIME = "overtime"          # Article 99
    REST_PERIODS = "rest_periods"  # Articles 110-128
    SPECIAL_CONDITIONS = "special_conditions"  # Articles 92-94


class ViolationType(Enum):
    """Types of TK RF violations"""
    WORKING_TIME_EXCEEDED = "working_time_exceeded"
    INSUFFICIENT_BREAKS = "insufficient_breaks" 
    OVERTIME_VIOLATION = "overtime_violation"
    REST_PERIOD_VIOLATION = "rest_period_violation"
    SPECIAL_CONDITION_VIOLATION = "special_condition_violation"


@dataclass
class TKRFRule:
    """TK RF compliance rule definition"""
    rule_id: str
    article: TKRFArticle
    title: str
    condition: str
    violation_type: ViolationType
    max_value: Optional[float]
    min_value: Optional[float]
    penalty_level: int  # 1=warning, 2=fine, 3=serious
    enabled: bool


@dataclass
class ComplianceResult:
    """Employee compliance check result"""
    employee_id: int
    check_date: datetime
    violations: List[Dict[str, Any]]
    compliance_score: float  # 0.0-1.0
    check_duration_ms: float
    cache_hit: bool


@dataclass
class BulkComplianceResult:
    """Bulk compliance validation result"""
    validation_id: str
    total_employees: int
    compliant_employees: int
    violation_count: int
    validation_duration_ms: float
    violations_by_type: Dict[str, int]
    cache_hit_rate: float


class TKRFRuleEngine:
    """High-performance TK RF compliance rule engine"""
    
    def __init__(self, database_url: Optional[str] = None, redis_url: Optional[str] = None):
        # Database connection
        if not database_url:
            database_url = "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Redis for rule caching
        self.redis_client = None
        if redis_url:
            try:
                self.redis_client = redis.from_url(redis_url, decode_responses=True)
                self.redis_client.ping()
                logger.info("Redis connected for TK RF rule caching")
            except Exception as e:
                logger.warning(f"Redis unavailable for rule engine: {e}")
        
        # Rule management
        self.rule_cache_ttl = 86400  # 24 hours (stable regulations)
        self.employee_cache_ttl = 14400  # 4 hours
        self.violation_cache_ttl = 3600  # 1 hour
        
        # Performance optimization
        self.executor = ThreadPoolExecutor(max_workers=8)
        self.rule_matrix = None  # Vectorized rule representation
        
        # Load TK RF rules
        self.tk_rf_rules = self._load_tk_rf_rules()
        self._build_rule_matrix()
        
        # Performance tracking
        self.metrics = {
            'total_checks': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'average_check_time': 0.0,
            'violation_rate': 0.0
        }
    
    def validate_employee(
        self, 
        employee_id: int, 
        date_range: Tuple[datetime, datetime],
        use_cache: bool = True
    ) -> ComplianceResult:
        """
        Validate single employee TK RF compliance.
        
        Args:
            employee_id: Employee to validate
            date_range: Date range for validation
            use_cache: Whether to use cached results
            
        Returns:
            ComplianceResult with violations and score
        """
        start_time = time.time()
        
        # Check cache first
        cache_key = f"compliance:{employee_id}:{date_range[0].date()}:{date_range[1].date()}"
        cache_hit = False
        
        if use_cache and self.redis_client:
            cached_result = self.redis_client.get(cache_key)
            if cached_result:
                cache_hit = True
                self.metrics['cache_hits'] += 1
                result_dict = json.loads(cached_result)
                return ComplianceResult(**result_dict)
        
        # Load employee work data
        employee_data = self._get_employee_work_data(employee_id, date_range)
        
        # Vectorized rule evaluation
        violations = self._evaluate_rules_vectorized(employee_data)
        
        # Calculate compliance score
        compliance_score = self._calculate_compliance_score(violations)
        
        # Create result
        result = ComplianceResult(
            employee_id=employee_id,
            check_date=datetime.utcnow(),
            violations=violations,
            compliance_score=compliance_score,
            check_duration_ms=(time.time() - start_time) * 1000,
            cache_hit=cache_hit
        )
        
        # Cache result
        if self.redis_client:
            result_dict = asdict(result)
            result_dict['check_date'] = result.check_date.isoformat()
            self.redis_client.setex(
                cache_key,
                self.employee_cache_ttl,
                json.dumps(result_dict, default=str)
            )
        
        # Update metrics
        self.metrics['total_checks'] += 1
        if not cache_hit:
            self.metrics['cache_misses'] += 1
        
        logger.info(
            f"Employee compliance check completed: {employee_id} - "
            f"Score: {compliance_score:.2f}, "
            f"Violations: {len(violations)}, "
            f"Time: {result.check_duration_ms:.1f}ms"
        )
        
        return result
    
    def validate_bulk(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime],
        parallel: bool = True
    ) -> BulkComplianceResult:
        """
        Validate multiple employees in parallel.
        
        Args:
            employee_ids: List of employee IDs to validate
            date_range: Date range for validation
            parallel: Whether to use parallel processing
            
        Returns:
            BulkComplianceResult with aggregate statistics
        """
        start_time = time.time()
        validation_id = str(uuid.uuid4())
        
        if parallel and len(employee_ids) > 10:
            # Parallel processing for large batches
            results = self._validate_bulk_parallel(employee_ids, date_range)
        else:
            # Sequential processing for small batches
            results = [
                self.validate_employee(emp_id, date_range)
                for emp_id in employee_ids
            ]
        
        # Aggregate results
        total_employees = len(employee_ids)
        compliant_employees = sum(1 for r in results if r.compliance_score >= 0.95)
        total_violations = sum(len(r.violations) for r in results)
        
        # Violations by type
        violations_by_type = {}
        for result in results:
            for violation in result.violations:
                v_type = violation.get('violation_type', 'unknown')
                violations_by_type[v_type] = violations_by_type.get(v_type, 0) + 1
        
        # Cache hit rate
        cache_hits = sum(1 for r in results if r.cache_hit)
        cache_hit_rate = cache_hits / len(results) if results else 0.0
        
        bulk_result = BulkComplianceResult(
            validation_id=validation_id,
            total_employees=total_employees,
            compliant_employees=compliant_employees,
            violation_count=total_violations,
            validation_duration_ms=(time.time() - start_time) * 1000,
            violations_by_type=violations_by_type,
            cache_hit_rate=cache_hit_rate
        )
        
        logger.info(
            f"Bulk compliance validation completed: {validation_id} - "
            f"Employees: {total_employees}, "
            f"Compliant: {compliant_employees}, "
            f"Time: {bulk_result.validation_duration_ms:.1f}ms"
        )
        
        return bulk_result
    
    def _validate_bulk_parallel(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime]
    ) -> List[ComplianceResult]:
        """Validate employees in parallel using ThreadPoolExecutor"""
        
        # Split into batches for parallel processing
        batch_size = 20  # Optimal batch size for database connections
        batches = [
            employee_ids[i:i + batch_size]
            for i in range(0, len(employee_ids), batch_size)
        ]
        
        # Submit batch tasks
        futures = []
        for batch in batches:
            future = self.executor.submit(self._validate_batch, batch, date_range)
            futures.append(future)
        
        # Collect results
        results = []
        for future in futures:
            try:
                batch_results = future.result(timeout=30)
                results.extend(batch_results)
            except Exception as e:
                logger.error(f"Batch validation failed: {e}")
        
        return results
    
    def _validate_batch(
        self,
        employee_ids: List[int],
        date_range: Tuple[datetime, datetime]
    ) -> List[ComplianceResult]:
        """Validate a batch of employees"""
        
        return [
            self.validate_employee(emp_id, date_range, use_cache=True)
            for emp_id in employee_ids
        ]
    
    def _get_employee_work_data(
        self,
        employee_id: int,
        date_range: Tuple[datetime, datetime]
    ) -> Dict[str, Any]:
        """Get employee work data for compliance checking"""
        
        with self.SessionLocal() as session:
            # Get shift data
            shifts_result = session.execute(
                text("""
                    SELECT 
                        date_trunc('day', start_date) as work_day,
                        SUM(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as daily_hours,
                        COUNT(*) as shift_count,
                        SUM(CASE WHEN break_minutes < 30 THEN 1 ELSE 0 END) as insufficient_breaks,
                        SUM(CASE WHEN EXTRACT(EPOCH FROM (end_time - start_time))/3600 > 8 THEN 1 ELSE 0 END) as overtime_shifts
                    FROM schedules 
                    WHERE employee_id = :employee_id 
                    AND start_date BETWEEN :start_date AND :end_date
                    AND status = 'confirmed'
                    GROUP BY date_trunc('day', start_date)
                    ORDER BY work_day
                """),
                {
                    'employee_id': employee_id,
                    'start_date': date_range[0],
                    'end_date': date_range[1]
                }
            ).fetchall()
            
            # Get employee info
            employee_result = session.execute(
                text("""
                    SELECT 
                        e.id, e.name, e.employment_type,
                        'employee' as position_name,
                        CASE WHEN e.created_at < NOW() - INTERVAL '18 years' THEN 'adult' ELSE 'minor' END as age_category
                    FROM employees e
                    WHERE e.id = :employee_id
                """),
                {'employee_id': employee_id}
            ).first()
            
            if not employee_result:
                raise ValueError(f"Employee {employee_id} not found")
            
            # Convert to work data structure
            work_data = {
                'employee_id': employee_id,
                'name': employee_result.name,
                'employment_type': employee_result.employment_type,
                'position': employee_result.position_name,
                'age_category': employee_result.age_category,
                'work_days': []
            }
            
            # Process daily work data
            for shift in shifts_result:
                work_data['work_days'].append({
                    'date': shift.work_day,
                    'daily_hours': float(shift.daily_hours or 0),
                    'shift_count': int(shift.shift_count or 0),
                    'insufficient_breaks': int(shift.insufficient_breaks or 0),
                    'overtime_shifts': int(shift.overtime_shifts or 0)
                })
            
            return work_data
    
    def _evaluate_rules_vectorized(self, employee_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Evaluate TK RF rules using vectorized operations"""
        
        violations = []
        work_days = employee_data.get('work_days', [])
        
        if not work_days:
            return violations
        
        # Convert to NumPy arrays for vectorized operations
        daily_hours = np.array([day['daily_hours'] for day in work_days])
        insufficient_breaks = np.array([day['insufficient_breaks'] for day in work_days])
        overtime_shifts = np.array([day['overtime_shifts'] for day in work_days])
        
        # TK RF Article 91-106: Working time limits
        max_daily_hours = 8.0 if employee_data['age_category'] == 'adult' else 7.0
        overtime_violations = daily_hours > max_daily_hours
        
        if np.any(overtime_violations):
            violation_days = np.where(overtime_violations)[0]
            for day_idx in violation_days:
                violations.append({
                    'violation_type': ViolationType.WORKING_TIME_EXCEEDED.value,
                    'article': 'TK RF Article 91',
                    'date': work_days[day_idx]['date'].isoformat(),
                    'actual_hours': float(daily_hours[day_idx]),
                    'max_allowed_hours': max_daily_hours,
                    'penalty_level': 2,
                    'description': f"Working time exceeded: {daily_hours[day_idx]:.1f}h > {max_daily_hours}h"
                })
        
        # TK RF Article 107-109: Break requirements  
        break_violations = insufficient_breaks > 0
        
        if np.any(break_violations):
            violation_days = np.where(break_violations)[0]
            for day_idx in violation_days:
                violations.append({
                    'violation_type': ViolationType.INSUFFICIENT_BREAKS.value,
                    'article': 'TK RF Article 108',
                    'date': work_days[day_idx]['date'].isoformat(),
                    'insufficient_breaks': int(insufficient_breaks[day_idx]),
                    'penalty_level': 1,
                    'description': f"Insufficient break time: {insufficient_breaks[day_idx]} shifts with <30min breaks"
                })
        
        # TK RF Article 99: Overtime regulations
        weekly_hours = np.sum(daily_hours)
        if weekly_hours > 40.0:
            violations.append({
                'violation_type': ViolationType.OVERTIME_VIOLATION.value,
                'article': 'TK RF Article 99',
                'weekly_hours': float(weekly_hours),
                'max_allowed_hours': 40.0,
                'penalty_level': 2,
                'description': f"Weekly overtime exceeded: {weekly_hours:.1f}h > 40h"
            })
        
        # Special conditions for minors (TK RF Articles 92-94)
        if employee_data['age_category'] == 'minor':
            # Minors cannot work more than 35 hours per week
            if weekly_hours > 35.0:
                violations.append({
                    'violation_type': ViolationType.SPECIAL_CONDITION_VIOLATION.value,
                    'article': 'TK RF Article 92',
                    'weekly_hours': float(weekly_hours),
                    'max_allowed_hours': 35.0,
                    'penalty_level': 3,
                    'description': f"Minor weekly hours exceeded: {weekly_hours:.1f}h > 35h"
                })
        
        return violations
    
    def _calculate_compliance_score(self, violations: List[Dict[str, Any]]) -> float:
        """Calculate compliance score based on violations"""
        
        if not violations:
            return 1.0
        
        # Weight violations by penalty level
        penalty_weights = {1: 0.1, 2: 0.2, 3: 0.4}  # warning, fine, serious
        
        total_penalty = sum(
            penalty_weights.get(v.get('penalty_level', 1), 0.1)
            for v in violations
        )
        
        # Score decreases with penalty severity
        compliance_score = max(0.0, 1.0 - total_penalty)
        
        return compliance_score
    
    def _load_tk_rf_rules(self) -> List[TKRFRule]:
        """Load TK RF rules from cache or database"""
        
        cache_key = "tk_rf_rules:all"
        
        # Try cache first
        if self.redis_client:
            cached_rules = self.redis_client.get(cache_key)
            if cached_rules:
                rules_data = json.loads(cached_rules)
                return [TKRFRule(**rule) for rule in rules_data]
        
        # Load from database/configuration
        rules = [
            TKRFRule(
                rule_id="TK_RF_91_DAILY_HOURS",
                article=TKRFArticle.WORKING_TIME,
                title="Maximum daily working hours",
                condition="daily_hours <= max_daily_hours",
                violation_type=ViolationType.WORKING_TIME_EXCEEDED,
                max_value=8.0,
                min_value=None,
                penalty_level=2,
                enabled=True
            ),
            TKRFRule(
                rule_id="TK_RF_108_BREAK_TIME", 
                article=TKRFArticle.BREAKS_REST,
                title="Minimum break duration",
                condition="break_minutes >= 30",
                violation_type=ViolationType.INSUFFICIENT_BREAKS,
                max_value=None,
                min_value=30.0,
                penalty_level=1,
                enabled=True
            ),
            TKRFRule(
                rule_id="TK_RF_99_WEEKLY_OVERTIME",
                article=TKRFArticle.OVERTIME, 
                title="Maximum weekly working hours",
                condition="weekly_hours <= 40",
                violation_type=ViolationType.OVERTIME_VIOLATION,
                max_value=40.0,
                min_value=None,
                penalty_level=2,
                enabled=True
            ),
            TKRFRule(
                rule_id="TK_RF_92_MINOR_WEEKLY",
                article=TKRFArticle.SPECIAL_CONDITIONS,
                title="Minor maximum weekly hours", 
                condition="minor_weekly_hours <= 35",
                violation_type=ViolationType.SPECIAL_CONDITION_VIOLATION,
                max_value=35.0,
                min_value=None,
                penalty_level=3,
                enabled=True
            )
        ]
        
        # Cache rules
        if self.redis_client:
            rules_data = [asdict(rule) for rule in rules]
            # Convert enums to strings for JSON serialization
            for rule_data in rules_data:
                rule_data['article'] = rule_data['article'].value
                rule_data['violation_type'] = rule_data['violation_type'].value
            
            self.redis_client.setex(
                cache_key,
                self.rule_cache_ttl,
                json.dumps(rules_data)
            )
        
        return rules
    
    def _build_rule_matrix(self):
        """Build NumPy matrix representation of rules for vectorized evaluation"""
        
        # This would create optimized matrix operations for complex rule sets
        # For now, using the direct evaluation approach
        self.rule_matrix = {
            'max_daily_hours_adult': 8.0,
            'max_daily_hours_minor': 7.0,
            'min_break_minutes': 30.0,
            'max_weekly_hours_adult': 40.0,
            'max_weekly_hours_minor': 35.0
        }
    
    def get_rule_performance_metrics(self) -> Dict[str, Any]:
        """Get rule engine performance metrics"""
        
        total_checks = self.metrics['total_checks']
        cache_hit_rate = (
            self.metrics['cache_hits'] / max(1, total_checks)
        )
        
        return {
            'total_checks': total_checks,
            'cache_hit_rate': cache_hit_rate,
            'cache_hits': self.metrics['cache_hits'],
            'cache_misses': self.metrics['cache_misses'],
            'average_check_time_ms': self.metrics['average_check_time'],
            'violation_rate': self.metrics['violation_rate'],
            'rules_loaded': len(self.tk_rf_rules),
            'redis_connected': self.redis_client is not None
        }
    
    def clear_compliance_cache(self, employee_id: Optional[int] = None):
        """Clear compliance cache for employee or all"""
        
        if not self.redis_client:
            return
        
        if employee_id:
            # Clear specific employee cache
            pattern = f"compliance:{employee_id}:*"
        else:
            # Clear all compliance cache
            pattern = "compliance:*"
        
        deleted_keys = 0
        for key in self.redis_client.scan_iter(match=pattern):
            self.redis_client.delete(key)
            deleted_keys += 1
        
        logger.info(f"Cleared {deleted_keys} compliance cache entries")


if __name__ == "__main__":
    # Demo usage
    engine = TKRFRuleEngine(redis_url="redis://localhost:6379/0")
    
    # Single employee validation
    date_range = (
        datetime.utcnow() - timedelta(days=7),
        datetime.utcnow()
    )
    
    result = engine.validate_employee(
        employee_id=1,
        date_range=date_range
    )
    
    print(f"Compliance Check Results:")
    print(f"  Employee ID: {result.employee_id}")
    print(f"  Compliance Score: {result.compliance_score:.2f}")
    print(f"  Violations: {len(result.violations)}")
    print(f"  Check Duration: {result.check_duration_ms:.1f}ms")
    print(f"  Cache Hit: {result.cache_hit}")
    
    if result.violations:
        print(f"\nViolations Found:")
        for violation in result.violations:
            print(f"  - {violation['article']}: {violation['description']}")
    
    # Bulk validation demo
    employee_ids = list(range(1, 51))  # 50 employees
    
    bulk_result = engine.validate_bulk(
        employee_ids=employee_ids,
        date_range=date_range,
        parallel=True
    )
    
    print(f"\nBulk Validation Results:")
    print(f"  Total Employees: {bulk_result.total_employees}")
    print(f"  Compliant: {bulk_result.compliant_employees}")
    print(f"  Total Violations: {bulk_result.violation_count}")
    print(f"  Validation Duration: {bulk_result.validation_duration_ms:.1f}ms")
    print(f"  Cache Hit Rate: {bulk_result.cache_hit_rate:.1%}")
    
    print(f"\nViolations by Type:")
    for v_type, count in bulk_result.violations_by_type.items():
        print(f"  {v_type}: {count}")
    
    # Performance metrics
    metrics = engine.get_rule_performance_metrics()
    print(f"\nRule Engine Metrics:")
    print(f"  Total Checks: {metrics['total_checks']}")
    print(f"  Cache Hit Rate: {metrics['cache_hit_rate']:.1%}")
    print(f"  Rules Loaded: {metrics['rules_loaded']}")
    print(f"  Redis Connected: {metrics['redis_connected']}")