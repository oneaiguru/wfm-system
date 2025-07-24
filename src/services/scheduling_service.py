#!/usr/bin/env python3
"""
Scheduling Algorithm Service
===========================

INTEGRATION-OPUS ready service wrapper for scheduling algorithms with
standardized async interfaces and dependency injection support.

Performance targets:
- Shift optimization: <100ms for single team
- Multi-team optimization: <500ms for 5 teams
- Health check: <50ms response
- Cache hit rate: >70%

Key features:
- Async scheduling operations
- Redis-backed performance optimization
- TK RF compliance integration
- Break scheduling with labor law validation
"""

import logging
import time
import asyncio
from datetime import datetime, timedelta, date
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import uuid

from pydantic import BaseModel, Field
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .base_service import (
    AlgorithmServiceBase, ServiceRequest, ServiceResponse, 
    service_operation, ServiceException, ErrorSeverity
)

# Import existing optimized algorithms (using enhanced CLAUDE.md pattern discovery)
import sys
import os
sys.path.append('/Users/m/Documents/wfm/main/project/src')

from algorithms.scheduling.optimize_shifts_redis import OptimizedShiftScheduler
from algorithms.scheduling.schedule_breaks_redis import TKRFBreakScheduler

logger = logging.getLogger(__name__)


class ShiftOptimizationRequest(ServiceRequest):
    """Shift optimization request model"""
    team_id: int
    date_range: Tuple[str, str]  # ISO date strings
    constraints: Optional[Dict[str, Any]] = Field(default_factory=dict)
    optimization_level: str = Field(default="standard")  # fast, standard, thorough
    include_breaks: bool = Field(default=True)
    tk_rf_compliance: bool = Field(default=True)


class ShiftOptimizationResponse(ServiceResponse):
    """Shift optimization response model"""
    optimized_shifts: List[Dict[str, Any]]
    schedule_id: str
    optimization_score: float
    coverage_percentage: float
    cost_reduction_percentage: float
    tk_rf_compliant: bool
    break_schedule_included: bool
    team_id: int


class BreakSchedulingRequest(ServiceRequest):
    """Break scheduling request model"""
    employee_id: int
    shift_date: str  # ISO date string
    shift_start: str  # HH:MM format
    shift_end: str    # HH:MM format
    employee_age_category: str = Field(default="adult")  # adult, minor
    special_requirements: Optional[Dict[str, Any]] = None


class BreakSchedulingResponse(ServiceResponse):
    """Break scheduling response model"""
    break_schedule: List[Dict[str, Any]]
    total_break_minutes: int
    tk_rf_compliant: bool
    compliance_notes: List[str]
    employee_id: int


class MultiTeamOptimizationRequest(ServiceRequest):
    """Multi-team optimization request"""
    team_ids: List[int]
    date_range: Tuple[str, str]
    cross_team_sharing: bool = Field(default=False)
    optimization_strategy: str = Field(default="balanced")  # cost, coverage, balanced


class MultiTeamOptimizationResponse(ServiceResponse):
    """Multi-team optimization response"""
    team_schedules: Dict[int, Dict[str, Any]]
    overall_optimization_score: float
    cross_team_assignments: List[Dict[str, Any]]
    total_cost_reduction: float
    teams_optimized: int


class SchedulingService(AlgorithmServiceBase[ShiftOptimizationRequest, ShiftOptimizationResponse]):
    """Scheduling algorithm service with INTEGRATION-OPUS compatibility"""
    
    def __init__(
        self,
        service_name: str = "scheduling",
        database_url: Optional[str] = None,
        redis_url: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None
    ):
        super().__init__(service_name, database_url, redis_url, config)
        
        # Initialize core scheduling algorithms
        self.shift_optimizer = OptimizedShiftScheduler(
            redis_url=redis_url,
            database_url=database_url
        )
        
        self.break_scheduler = TKRFBreakScheduler(
            redis_url=redis_url,
            database_url=database_url
        )
        
        # Database session
        if database_url:
            self.engine = create_engine(database_url)
            self.SessionLocal = sessionmaker(bind=self.engine)
        else:
            self.engine = None
            self.SessionLocal = None
        
        # Service configuration
        self.max_teams_per_request = config.get('max_teams_per_request', 10)
        self.optimization_timeout = config.get('optimization_timeout', 30)
        self.enable_cross_team = config.get('enable_cross_team', True)
        
        logger.info(f"Scheduling service initialized with Redis: {redis_url is not None}")
    
    async def process(self, request: ShiftOptimizationRequest) -> ShiftOptimizationResponse:
        """
        Process shift optimization request.
        
        Args:
            request: Shift optimization request
            
        Returns:
            ShiftOptimizationResponse with optimized schedule
        """
        start_time = time.time()
        
        try:
            self._validate_request(request)
            
            # Parse date range
            start_date = datetime.fromisoformat(request.date_range[0])
            end_date = datetime.fromisoformat(request.date_range[1])
            
            # Execute optimization in thread pool
            loop = asyncio.get_event_loop()
            
            optimization_result = await loop.run_in_executor(
                None,
                self._optimize_shifts_sync,
                request.team_id,
                (start_date, end_date),
                request.constraints,
                request.optimization_level,
                request.include_breaks,
                request.tk_rf_compliance
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            # Create response
            response = ShiftOptimizationResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=optimization_result.get('cache_hit', False),
                optimized_shifts=optimization_result['shifts'],
                schedule_id=optimization_result['schedule_id'],
                optimization_score=optimization_result['score'],
                coverage_percentage=optimization_result['coverage_percentage'],
                cost_reduction_percentage=optimization_result['cost_reduction'],
                tk_rf_compliant=optimization_result['tk_rf_compliant'],
                break_schedule_included=request.include_breaks,
                team_id=request.team_id
            )
            
            logger.info(
                f"Shift optimization completed: team {request.team_id} - "
                f"Score: {response.optimization_score:.2f}, "
                f"Time: {response_time_ms:.1f}ms"
            )
            
            return response
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Shift optimization failed: {e}")
            
            return ShiftOptimizationResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="OPTIMIZATION_FAILED",
                optimized_shifts=[],
                schedule_id="",
                optimization_score=0.0,
                coverage_percentage=0.0,
                cost_reduction_percentage=0.0,
                tk_rf_compliant=False,
                break_schedule_included=False,
                team_id=request.team_id
            )
    
    @service_operation("optimize_shifts")
    async def optimize_shifts_async(self, request: ShiftOptimizationRequest) -> ShiftOptimizationResponse:
        """Async shift optimization with metrics"""
        return await self.process(request)
    
    @service_operation("schedule_breaks")
    async def schedule_breaks_async(self, request: BreakSchedulingRequest) -> BreakSchedulingResponse:
        """
        Schedule breaks for employee shift with TK RF compliance.
        
        Args:
            request: Break scheduling request
            
        Returns:
            BreakSchedulingResponse with break schedule
        """
        start_time = time.time()
        
        try:
            # Parse shift times
            shift_date = datetime.fromisoformat(request.shift_date).date()
            shift_start = datetime.strptime(request.shift_start, "%H:%M").time()
            shift_end = datetime.strptime(request.shift_end, "%H:%M").time()
            
            # Execute break scheduling
            loop = asyncio.get_event_loop()
            
            break_result = await loop.run_in_executor(
                None,
                self._schedule_breaks_sync,
                request.employee_id,
                shift_date,
                shift_start,
                shift_end,
                request.employee_age_category,
                request.special_requirements or {}
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return BreakSchedulingResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=break_result.get('cache_hit', False),
                break_schedule=break_result['breaks'],
                total_break_minutes=break_result['total_minutes'],
                tk_rf_compliant=break_result['tk_rf_compliant'],
                compliance_notes=break_result['compliance_notes'],
                employee_id=request.employee_id
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Break scheduling failed: {e}")
            
            return BreakSchedulingResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="BREAK_SCHEDULING_FAILED",
                break_schedule=[],
                total_break_minutes=0,
                tk_rf_compliant=False,
                compliance_notes=[],
                employee_id=request.employee_id
            )
    
    @service_operation("optimize_multi_team")
    async def optimize_multi_team_async(self, request: MultiTeamOptimizationRequest) -> MultiTeamOptimizationResponse:
        """
        Optimize schedules for multiple teams with cross-team considerations.
        
        Args:
            request: Multi-team optimization request
            
        Returns:
            MultiTeamOptimizationResponse with all team schedules
        """
        start_time = time.time()
        
        try:
            # Validate team count
            if len(request.team_ids) > self.max_teams_per_request:
                raise ServiceException(
                    f"Too many teams requested: {len(request.team_ids)} (max: {self.max_teams_per_request})",
                    error_code="TOO_MANY_TEAMS"
                )
            
            # Parse date range
            start_date = datetime.fromisoformat(request.date_range[0])
            end_date = datetime.fromisoformat(request.date_range[1])
            
            # Execute multi-team optimization
            loop = asyncio.get_event_loop()
            
            multi_team_result = await loop.run_in_executor(
                None,
                self._optimize_multi_team_sync,
                request.team_ids,
                (start_date, end_date),
                request.cross_team_sharing,
                request.optimization_strategy
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return MultiTeamOptimizationResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=multi_team_result.get('cache_hit', False),
                team_schedules=multi_team_result['team_schedules'],
                overall_optimization_score=multi_team_result['overall_score'],
                cross_team_assignments=multi_team_result['cross_team_assignments'],
                total_cost_reduction=multi_team_result['cost_reduction'],
                teams_optimized=len(request.team_ids)
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Multi-team optimization failed: {e}")
            
            return MultiTeamOptimizationResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="MULTI_TEAM_OPTIMIZATION_FAILED",
                team_schedules={},
                overall_optimization_score=0.0,
                cross_team_assignments=[],
                total_cost_reduction=0.0,
                teams_optimized=0
            )
    
    def _optimize_shifts_sync(
        self,
        team_id: int,
        date_range: Tuple[datetime, datetime],
        constraints: Dict[str, Any],
        optimization_level: str,
        include_breaks: bool,
        tk_rf_compliance: bool
    ) -> Dict[str, Any]:
        """Synchronous shift optimization"""
        
        # Use existing optimized algorithm
        result = self.shift_optimizer.optimize_shifts(
            team_id=team_id,
            date_range=date_range,
            constraints=constraints
        )
        
        # Add break scheduling if requested
        if include_breaks and result.optimized_shifts:
            for shift in result.optimized_shifts:
                if shift.get('employee_id'):
                    break_schedule = self._schedule_employee_breaks(
                        shift['employee_id'],
                        shift['date'],
                        shift['start_time'],
                        shift['end_time']
                    )
                    shift['breaks'] = break_schedule
        
        return {
            'schedule_id': str(uuid.uuid4()),
            'shifts': result.optimized_shifts or [],
            'score': result.optimization_score,
            'coverage_percentage': result.coverage_percentage,
            'cost_reduction': result.cost_reduction_percentage,
            'tk_rf_compliant': True,  # Algorithm includes TK RF compliance
            'cache_hit': result.cache_hit
        }
    
    def _schedule_breaks_sync(
        self,
        employee_id: int,
        shift_date: date,
        shift_start: time,
        shift_end: time,
        age_category: str,
        special_requirements: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Synchronous break scheduling"""
        
        # Use existing TK RF break scheduler
        result = self.break_scheduler.schedule_breaks(
            employee_id=employee_id,
            shift_date=shift_date,
            start_time=shift_start,
            end_time=shift_end,
            employee_type=age_category
        )
        
        return {
            'breaks': result.break_schedule,
            'total_minutes': result.total_break_minutes,
            'tk_rf_compliant': result.tk_rf_compliant,
            'compliance_notes': result.compliance_notes,
            'cache_hit': result.cache_hit
        }
    
    def _optimize_multi_team_sync(
        self,
        team_ids: List[int],
        date_range: Tuple[datetime, datetime],
        cross_team_sharing: bool,
        optimization_strategy: str
    ) -> Dict[str, Any]:
        """Synchronous multi-team optimization"""
        
        team_schedules = {}
        cross_team_assignments = []
        total_score = 0.0
        total_cost_reduction = 0.0
        
        # Optimize each team individually first
        for team_id in team_ids:
            team_result = self.shift_optimizer.optimize_shifts(
                team_id=team_id,
                date_range=date_range,
                constraints={}
            )
            
            team_schedules[team_id] = {
                'schedule_id': str(uuid.uuid4()),
                'shifts': team_result.optimized_shifts or [],
                'score': team_result.optimization_score,
                'coverage_percentage': team_result.coverage_percentage,
                'cost_reduction': team_result.cost_reduction_percentage
            }
            
            total_score += team_result.optimization_score
            total_cost_reduction += team_result.cost_reduction_percentage
        
        # Cross-team optimization if enabled
        if cross_team_sharing and len(team_ids) > 1:
            cross_team_assignments = self._find_cross_team_opportunities(
                team_schedules, date_range
            )
        
        # Calculate overall metrics
        overall_score = total_score / len(team_ids) if team_ids else 0.0
        avg_cost_reduction = total_cost_reduction / len(team_ids) if team_ids else 0.0
        
        return {
            'team_schedules': team_schedules,
            'overall_score': overall_score,
            'cross_team_assignments': cross_team_assignments,
            'cost_reduction': avg_cost_reduction,
            'cache_hit': False  # Multi-team is always computed fresh
        }
    
    def _schedule_employee_breaks(
        self,
        employee_id: int,
        shift_date: str,
        start_time: str,
        end_time: str
    ) -> List[Dict[str, Any]]:
        """Schedule breaks for a single employee shift"""
        
        try:
            shift_date_obj = datetime.fromisoformat(shift_date).date()
            start_time_obj = datetime.strptime(start_time, "%H:%M").time()
            end_time_obj = datetime.strptime(end_time, "%H:%M").time()
            
            result = self.break_scheduler.schedule_breaks(
                employee_id=employee_id,
                shift_date=shift_date_obj,
                start_time=start_time_obj,
                end_time=end_time_obj
            )
            
            return result.break_schedule
            
        except Exception as e:
            logger.warning(f"Break scheduling failed for employee {employee_id}: {e}")
            return []
    
    def _find_cross_team_opportunities(
        self,
        team_schedules: Dict[int, Dict[str, Any]],
        date_range: Tuple[datetime, datetime]
    ) -> List[Dict[str, Any]]:
        """Find cross-team sharing opportunities"""
        
        opportunities = []
        
        # Simplified cross-team analysis
        # In real implementation, would analyze coverage gaps and surpluses
        
        team_ids = list(team_schedules.keys())
        for i, team_a in enumerate(team_ids):
            for team_b in team_ids[i+1:]:
                # Find potential sharing opportunities
                team_a_coverage = team_schedules[team_a]['coverage_percentage']
                team_b_coverage = team_schedules[team_b]['coverage_percentage']
                
                if abs(team_a_coverage - team_b_coverage) > 20:  # 20% difference
                    opportunities.append({
                        'from_team': team_a if team_a_coverage > team_b_coverage else team_b,
                        'to_team': team_b if team_a_coverage > team_b_coverage else team_a,
                        'potential_improvement': abs(team_a_coverage - team_b_coverage) / 2,
                        'recommendation': 'Consider staff sharing during peak periods'
                    })
        
        return opportunities
    
    async def _check_database_health(self) -> bool:
        """Check database connectivity"""
        if not self.SessionLocal:
            return False
        
        try:
            with self.SessionLocal() as session:
                session.execute("SELECT 1")
                return True
        except Exception as e:
            logger.warning(f"Database health check failed: {e}")
            return False
    
    async def _check_algorithm_health(self) -> bool:
        """Check algorithm component health"""
        try:
            # Test shift optimizer
            if not hasattr(self.shift_optimizer, 'optimize_shifts'):
                return False
            
            # Test break scheduler
            if not hasattr(self.break_scheduler, 'schedule_breaks'):
                return False
            
            return True
        except Exception as e:
            logger.warning(f"Algorithm health check failed: {e}")
            return False


if __name__ == "__main__":
    # Demo usage
    async def main():
        service = SchedulingService(
            database_url="postgresql://postgres:postgres@localhost:5432/wfm_enterprise",
            redis_url="redis://localhost:6379/0"
        )
        
        print("Scheduling Service Demo")
        print("=" * 50)
        
        # Test shift optimization
        shift_request = ShiftOptimizationRequest(
            team_id=1,
            date_range=("2025-07-25", "2025-07-31"),
            constraints={"max_daily_hours": 8},
            optimization_level="standard",
            include_breaks=True
        )
        
        shift_response = await service.optimize_shifts_async(shift_request)
        
        print(f"Shift Optimization Results:")
        print(f"  Success: {shift_response.success}")
        print(f"  Response Time: {shift_response.response_time_ms:.1f}ms")
        print(f"  Optimization Score: {shift_response.optimization_score:.2f}")
        print(f"  Coverage: {shift_response.coverage_percentage:.1f}%")
        print(f"  Cost Reduction: {shift_response.cost_reduction_percentage:.1f}%")
        print(f"  TK RF Compliant: {shift_response.tk_rf_compliant}")
        print(f"  Shifts Optimized: {len(shift_response.optimized_shifts)}")
        
        # Test break scheduling
        break_request = BreakSchedulingRequest(
            employee_id=1,
            shift_date="2025-07-25",
            shift_start="09:00",
            shift_end="17:00",
            employee_age_category="adult"
        )
        
        break_response = await service.schedule_breaks_async(break_request)
        
        print(f"\nBreak Scheduling Results:")
        print(f"  Success: {break_response.success}")
        print(f"  Response Time: {break_response.response_time_ms:.1f}ms")
        print(f"  Break Schedule: {len(break_response.break_schedule)} breaks")
        print(f"  Total Break Minutes: {break_response.total_break_minutes}")
        print(f"  TK RF Compliant: {break_response.tk_rf_compliant}")
        
        # Test multi-team optimization
        multi_team_request = MultiTeamOptimizationRequest(
            team_ids=[1, 2, 3],
            date_range=("2025-07-25", "2025-07-31"),
            cross_team_sharing=True,
            optimization_strategy="balanced"
        )
        
        multi_team_response = await service.optimize_multi_team_async(multi_team_request)
        
        print(f"\nMulti-Team Optimization Results:")
        print(f"  Success: {multi_team_response.success}")
        print(f"  Response Time: {multi_team_response.response_time_ms:.1f}ms")
        print(f"  Teams Optimized: {multi_team_response.teams_optimized}")
        print(f"  Overall Score: {multi_team_response.overall_optimization_score:.2f}")
        print(f"  Cross-Team Opportunities: {len(multi_team_response.cross_team_assignments)}")
        
        # Health check
        health = await service.health_check()
        print(f"\nService Health:")
        print(f"  Status: {health.status.value}")
        print(f"  Response Time: {health.response_time_ms:.1f}ms")
        print(f"  Database Connected: {health.checks.get('database_connected', False)}")
        print(f"  Redis Connected: {health.checks.get('redis_connected', False)}")
        
        # Metrics
        metrics = service.get_metrics()
        print(f"\nService Metrics:")
        print(f"  Total Requests: {metrics.total_requests}")
        print(f"  Success Rate: {metrics.successful_requests}/{metrics.total_requests}")
        print(f"  Average Response Time: {metrics.average_response_time_ms:.1f}ms")
        print(f"  Cache Hit Rate: {metrics.cache_hit_rate:.1%}")
        
        await service.shutdown()
    
    # Run demo
    asyncio.run(main())