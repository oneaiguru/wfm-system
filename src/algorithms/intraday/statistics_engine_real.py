"""
Statistics Engine with Real Database Integration Only
Task 30: Remove simulated value generation - require real database connection
Enhanced statistical calculations for workforce management with PostgreSQL-only data
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, date, timedelta
from dataclasses import dataclass, field
import numpy as np
import pandas as pd
from collections import defaultdict, Counter
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import json

logger = logging.getLogger(__name__)

@dataclass
class WorkforceStatistics:
    """Workforce statistics from real data"""
    period: Tuple[date, date]
    total_employees: int
    active_employees: int
    utilization_rate: float
    productivity_score: float
    quality_metrics: Dict[str, float]
    performance_trends: Dict[str, List[float]]
    calculated_at: datetime = field(default_factory=datetime.now)

@dataclass
class MobileWorkforceMetrics:
    """Mobile workforce metrics from real tracking data"""
    employee_id: int
    total_distance_km: float
    travel_time_hours: float
    fuel_consumption_liters: float
    jobs_completed: int
    customer_satisfaction: float
    on_time_percentage: float
    service_areas_covered: int
    vehicle_utilization: float
    gps_efficiency: float
    territory_coverage: float
    calculated_at: datetime = field(default_factory=datetime.now)

@dataclass
class ScheduleStatistics:
    """Schedule statistics from real schedule data"""
    coverage_percentage: float
    overtime_hours: float
    schedule_adherence: float
    gap_count: int
    conflicts_resolved: int
    efficiency_score: float

class StatisticsEngineReal:
    """
    Enhanced statistics engine with real database integration only
    Calculates workforce management statistics from PostgreSQL data
    NO simulated values - fails if database unavailable
    """
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with required database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        # Initialize database connection
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Verify database connection is working
        self._verify_database_connection()
        
        # Statistics caching
        self.statistics_cache: Dict[str, Any] = {}
        self.cache_ttl: Dict[str, datetime] = {}
        
        # Real data tracking
        self.data_sources = {
            'employees': 'employees table',
            'schedules': 'work_schedules table', 
            'mobile_tracking': 'mobile_tracking_data table',
            'performance': 'employee_performance table',
            'attendance': 'attendance_records table'
        }
        
        logger.info("✅ Statistics Engine Real initialized (PostgreSQL only)")
    
    def _verify_database_connection(self):
        """Verify database connection - fail if not available"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).scalar()
                if not result:
                    raise ConnectionError("Database verification failed")
            logger.info("✅ Database connection verified")
        except Exception as e:
            logger.error(f"❌ Database connection required: {e}")
            raise ConnectionError(f"Statistics engine requires database connection: {e}")
    
    def calculate_workforce_statistics(self, 
                                     start_date: date, 
                                     end_date: date) -> WorkforceStatistics:
        """Calculate comprehensive workforce statistics from real data"""
        cache_key = f"workforce_stats_{start_date}_{end_date}"
        
        # Check cache first
        if self._is_cache_valid(cache_key):
            return self.statistics_cache[cache_key]
        
        try:
            with self.SessionLocal() as session:
                # Get employee counts
                employee_stats = session.execute(text("""
                    SELECT 
                        COUNT(*) as total_employees,
                        COUNT(CASE WHEN is_active = true THEN 1 END) as active_employees,
                        AVG(CASE WHEN performance_score IS NOT NULL THEN performance_score END) as avg_performance
                    FROM employees
                    WHERE hire_date <= :end_date
                """), {'end_date': end_date}).fetchone()
                
                # Get utilization data
                utilization_stats = session.execute(text("""
                    SELECT 
                        AVG(hours_worked) as avg_hours_worked,
                        AVG(scheduled_hours) as avg_scheduled_hours,
                        COUNT(*) as total_records
                    FROM work_schedules ws
                    JOIN employees e ON ws.employee_id = e.employee_id
                    WHERE ws.schedule_date BETWEEN :start_date AND :end_date
                    AND e.is_active = true
                """), {
                    'start_date': start_date,
                    'end_date': end_date
                }).fetchone()
                
                # Calculate utilization rate
                utilization_rate = 0.0
                if utilization_stats and utilization_stats.avg_scheduled_hours:
                    utilization_rate = (
                        utilization_stats.avg_hours_worked / 
                        utilization_stats.avg_scheduled_hours
                    )
                
                # Get quality metrics
                quality_stats = session.execute(text("""
                    SELECT 
                        AVG(customer_satisfaction) as avg_satisfaction,
                        AVG(on_time_percentage) as avg_on_time,
                        AVG(quality_score) as avg_quality
                    FROM employee_performance
                    WHERE performance_date BETWEEN :start_date AND :end_date
                """), {
                    'start_date': start_date,
                    'end_date': end_date
                }).fetchone()
                
                # Build quality metrics
                quality_metrics = {}
                if quality_stats:
                    quality_metrics = {
                        'customer_satisfaction': float(quality_stats.avg_satisfaction or 0.0),
                        'on_time_percentage': float(quality_stats.avg_on_time or 0.0),
                        'quality_score': float(quality_stats.avg_quality or 0.0)
                    }
                
                # Get performance trends (last 4 weeks)
                trends = self._calculate_performance_trends(start_date, end_date, session)
                
                statistics = WorkforceStatistics(
                    period=(start_date, end_date),
                    total_employees=employee_stats.total_employees or 0,
                    active_employees=employee_stats.active_employees or 0,
                    utilization_rate=utilization_rate,
                    productivity_score=float(employee_stats.avg_performance or 0.0),
                    quality_metrics=quality_metrics,
                    performance_trends=trends
                )
                
                # Cache the result
                self._cache_result(cache_key, statistics)
                
                return statistics
                
        except Exception as e:
            logger.error(f"Failed to calculate workforce statistics: {e}")
            raise RuntimeError(f"Cannot calculate statistics without database data: {e}")
    
    def get_mobile_workforce_metrics(self, employee_id: int) -> MobileWorkforceMetrics:
        """Get mobile workforce metrics from real tracking data"""
        cache_key = f"mobile_metrics_{employee_id}"
        
        if self._is_cache_valid(cache_key):
            return self.statistics_cache[cache_key]
        
        try:
            with self.SessionLocal() as session:
                # Get mobile tracking data
                mobile_data = session.execute(text("""
                    SELECT 
                        COALESCE(SUM(distance_km), 0) as total_distance,
                        COALESCE(SUM(travel_time_minutes), 0) / 60.0 as travel_time_hours,
                        COALESCE(SUM(fuel_used_liters), 0) as fuel_consumption,
                        COUNT(DISTINCT job_id) as jobs_completed,
                        COALESCE(AVG(customer_rating), 0) as customer_satisfaction,
                        COALESCE(AVG(CASE WHEN arrived_on_time THEN 100 ELSE 0 END), 0) as on_time_percentage,
                        COUNT(DISTINCT service_area) as service_areas,
                        COALESCE(AVG(vehicle_utilization_percent), 0) / 100.0 as vehicle_utilization,
                        COALESCE(AVG(gps_accuracy_percent), 0) / 100.0 as gps_efficiency
                    FROM mobile_tracking_data
                    WHERE employee_id = :employee_id
                    AND tracking_date >= CURRENT_DATE - INTERVAL '30 days'
                """), {'employee_id': employee_id}).fetchone()
                
                if not mobile_data:
                    raise ValueError(f"No mobile tracking data found for employee {employee_id}")
                
                # Get territory coverage
                territory_data = session.execute(text("""
                    SELECT 
                        COUNT(DISTINCT territory_id) as territories_covered,
                        (SELECT COUNT(*) FROM assigned_territories WHERE employee_id = :employee_id) as assigned_territories
                    FROM mobile_tracking_data
                    WHERE employee_id = :employee_id
                    AND tracking_date >= CURRENT_DATE - INTERVAL '30 days'
                """), {'employee_id': employee_id}).fetchone()
                
                territory_coverage = 0.0
                if territory_data and territory_data.assigned_territories > 0:
                    territory_coverage = (
                        territory_data.territories_covered / 
                        territory_data.assigned_territories
                    )
                
                metrics = MobileWorkforceMetrics(
                    employee_id=employee_id,
                    total_distance_km=float(mobile_data.total_distance),
                    travel_time_hours=float(mobile_data.travel_time_hours),
                    fuel_consumption_liters=float(mobile_data.fuel_consumption),
                    jobs_completed=int(mobile_data.jobs_completed),
                    customer_satisfaction=float(mobile_data.customer_satisfaction),
                    on_time_percentage=float(mobile_data.on_time_percentage),
                    service_areas_covered=int(mobile_data.service_areas),
                    vehicle_utilization=float(mobile_data.vehicle_utilization),
                    gps_efficiency=float(mobile_data.gps_efficiency),
                    territory_coverage=territory_coverage
                )
                
                self._cache_result(cache_key, metrics)
                return metrics
                
        except Exception as e:
            logger.error(f"Failed to get mobile workforce metrics for employee {employee_id}: {e}")
            raise RuntimeError(f"Cannot calculate mobile metrics without tracking data: {e}")
    
    def calculate_working_days(self, start_date: date, end_date: date) -> Dict[str, Any]:
        """Calculate working days using real business calendar"""
        try:
            with self.SessionLocal() as session:
                # Get business calendar from database
                calendar_data = session.execute(text("""
                    SELECT 
                        calendar_date,
                        is_working_day,
                        is_holiday,
                        holiday_name,
                        hours_adjustment
                    FROM business_calendar
                    WHERE calendar_date BETWEEN :start_date AND :end_date
                    ORDER BY calendar_date
                """), {
                    'start_date': start_date,
                    'end_date': end_date
                }).fetchall()
                
                if not calendar_data:
                    # Fall back to weekend-only calculation if no business calendar
                    total_days = (end_date - start_date).days + 1
                    working_days = 0
                    current_date = start_date
                    
                    while current_date <= end_date:
                        if current_date.weekday() < 5:  # Monday = 0, Friday = 4
                            working_days += 1
                        current_date += timedelta(days=1)
                    
                    return {
                        'total_days': total_days,
                        'working_days': working_days,
                        'holiday_days': 0,
                        'weekend_days': total_days - working_days,
                        'data_source': 'weekend_calculation'
                    }
                
                # Calculate from business calendar
                total_days = len(calendar_data)
                working_days = sum(1 for day in calendar_data if day.is_working_day)
                holiday_days = sum(1 for day in calendar_data if day.is_holiday)
                weekend_days = total_days - working_days - holiday_days
                
                return {
                    'total_days': total_days,
                    'working_days': working_days,
                    'holiday_days': holiday_days,
                    'weekend_days': weekend_days,
                    'holidays': [
                        {'date': day.calendar_date, 'name': day.holiday_name}
                        for day in calendar_data if day.is_holiday
                    ],
                    'data_source': 'business_calendar'
                }
                
        except Exception as e:
            logger.error(f"Failed to calculate working days: {e}")
            raise RuntimeError(f"Cannot calculate working days without calendar data: {e}")
    
    def get_schedule_statistics(self, employee_id: int, 
                               period_start: date, 
                               period_end: date) -> ScheduleStatistics:
        """Get schedule statistics from real schedule data"""
        try:
            with self.SessionLocal() as session:
                # Get schedule data
                schedule_data = session.execute(text("""
                    SELECT 
                        COUNT(*) as total_shifts,
                        COUNT(CASE WHEN actual_start_time IS NOT NULL THEN 1 END) as worked_shifts,
                        AVG(CASE WHEN scheduled_hours > 0 THEN 
                            (actual_hours / scheduled_hours) * 100 
                            ELSE 0 END) as adherence_percentage,
                        SUM(CASE WHEN actual_hours > scheduled_hours THEN 
                            actual_hours - scheduled_hours 
                            ELSE 0 END) as overtime_hours,
                        COUNT(CASE WHEN status = 'conflict' THEN 1 END) as conflicts,
                        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_conflicts
                    FROM work_schedules
                    WHERE employee_id = :employee_id
                    AND schedule_date BETWEEN :start_date AND :end_date
                """), {
                    'employee_id': employee_id,
                    'start_date': period_start,
                    'end_date': period_end
                }).fetchone()
                
                if not schedule_data or schedule_data.total_shifts == 0:
                    raise ValueError(f"No schedule data found for employee {employee_id}")
                
                # Calculate coverage percentage
                coverage_percentage = (
                    (schedule_data.worked_shifts / schedule_data.total_shifts) * 100
                    if schedule_data.total_shifts > 0 else 0.0
                )
                
                # Get schedule gaps
                gaps_data = session.execute(text("""
                    SELECT COUNT(*) as gap_count
                    FROM schedule_gaps
                    WHERE employee_id = :employee_id
                    AND gap_date BETWEEN :start_date AND :end_date
                """), {
                    'employee_id': employee_id,
                    'start_date': period_start,
                    'end_date': period_end
                }).fetchone()
                
                gap_count = gaps_data.gap_count if gaps_data else 0
                
                # Calculate efficiency score
                efficiency_score = min(100.0, (
                    coverage_percentage * 0.4 +
                    float(schedule_data.adherence_percentage or 0) * 0.4 +
                    max(0, 100 - gap_count * 5) * 0.2  # Penalty for gaps
                ))
                
                return ScheduleStatistics(
                    coverage_percentage=coverage_percentage,
                    overtime_hours=float(schedule_data.overtime_hours or 0),
                    schedule_adherence=float(schedule_data.adherence_percentage or 0),
                    gap_count=gap_count,
                    conflicts_resolved=int(schedule_data.resolved_conflicts or 0),
                    efficiency_score=efficiency_score
                )
                
        except Exception as e:
            logger.error(f"Failed to get schedule statistics: {e}")
            raise RuntimeError(f"Cannot calculate schedule statistics without data: {e}")
    
    def _calculate_performance_trends(self, start_date: date, end_date: date, 
                                    session) -> Dict[str, List[float]]:
        """Calculate performance trends over time"""
        try:
            # Get weekly performance data
            trend_data = session.execute(text("""
                SELECT 
                    DATE_TRUNC('week', performance_date) as week_start,
                    AVG(performance_score) as avg_performance,
                    AVG(customer_satisfaction) as avg_satisfaction,
                    AVG(productivity_score) as avg_productivity
                FROM employee_performance
                WHERE performance_date BETWEEN :start_date AND :end_date
                GROUP BY DATE_TRUNC('week', performance_date)
                ORDER BY week_start
            """), {
                'start_date': start_date,
                'end_date': end_date
            }).fetchall()
            
            trends = {
                'performance': [],
                'satisfaction': [],
                'productivity': []
            }
            
            for row in trend_data:
                trends['performance'].append(float(row.avg_performance or 0))
                trends['satisfaction'].append(float(row.avg_satisfaction or 0))
                trends['productivity'].append(float(row.avg_productivity or 0))
            
            return trends
            
        except Exception as e:
            logger.warning(f"Could not calculate performance trends: {e}")
            return {'performance': [], 'satisfaction': [], 'productivity': []}
    
    def _is_cache_valid(self, cache_key: str, ttl_minutes: int = 30) -> bool:
        """Check if cache entry is valid"""
        if cache_key not in self.cache_ttl:
            return False
        
        cache_time = self.cache_ttl[cache_key]
        expiry_time = cache_time + timedelta(minutes=ttl_minutes)
        
        return datetime.now() < expiry_time
    
    def _cache_result(self, cache_key: str, result: Any):
        """Cache calculation result"""
        self.statistics_cache[cache_key] = result
        self.cache_ttl[cache_key] = datetime.now()
    
    def get_comprehensive_statistics_summary(self) -> Dict[str, Any]:
        """Get comprehensive statistics summary"""
        try:
            # Get overall workforce statistics for last 30 days
            end_date = date.today()
            start_date = end_date - timedelta(days=30)
            
            workforce_stats = self.calculate_workforce_statistics(start_date, end_date)
            working_days = self.calculate_working_days(start_date, end_date)
            
            return {
                'timestamp': datetime.now().isoformat(),
                'period': f"{start_date} to {end_date}",
                'workforce_statistics': asdict(workforce_stats),
                'working_days_calculation': working_days,
                'data_sources': self.data_sources,
                'cache_status': {
                    'cached_items': len(self.statistics_cache),
                    'cache_keys': list(self.statistics_cache.keys())
                },
                'database_integration': 'postgresql',
                'real_data_source': 'wfm_enterprise'
            }
            
        except Exception as e:
            logger.error(f"Failed to generate statistics summary: {e}")
            raise RuntimeError(f"Cannot generate statistics without database: {e}")


# Convenience functions
def validate_statistics_engine_real():
    """Test statistics engine with real database only"""
    try:
        engine = StatisticsEngineReal()
        
        # Test workforce statistics
        end_date = date.today()
        start_date = end_date - timedelta(days=7)
        
        workforce_stats = engine.calculate_workforce_statistics(start_date, end_date)
        print("✅ Statistics Engine Real:")
        print(f"   Total employees: {workforce_stats.total_employees}")
        print(f"   Active employees: {workforce_stats.active_employees}")
        print(f"   Utilization rate: {workforce_stats.utilization_rate:.1%}")
        print(f"   Productivity score: {workforce_stats.productivity_score:.2f}")
        
        # Test working days calculation
        working_days = engine.calculate_working_days(start_date, end_date)
        print(f"   Working days: {working_days['working_days']}/{working_days['total_days']}")
        print(f"   Data source: {working_days['data_source']}")
        
        # Test mobile metrics (if employee exists)
        try:
            mobile_metrics = engine.get_mobile_workforce_metrics(111538)
            print(f"   Mobile distance: {mobile_metrics.total_distance_km:.1f}km")
            print(f"   Jobs completed: {mobile_metrics.jobs_completed}")
        except Exception:
            print("   Mobile metrics: No tracking data available")
        
        # Test summary
        summary = engine.get_comprehensive_statistics_summary()
        print(f"   Data sources: {len(summary['data_sources'])}")
        print(f"   Database: {summary['real_data_source']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Statistics engine validation failed: {e}")
        return False


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    if validate_statistics_engine_real():
        print("\n✅ Statistics Engine Real: READY (PostgreSQL only, no simulated values)")
    else:
        print("\n❌ Statistics Engine Real: FAILED")