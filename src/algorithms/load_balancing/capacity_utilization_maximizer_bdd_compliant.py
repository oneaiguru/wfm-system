#!/usr/bin/env python3
"""
Capacity Utilization Maximizer - BDD Compliant Version
======================================================

Simplified capacity optimization based on BDD specifications from files 10 and 12.
Removed: ML optimization, differential evolution, custom tables, complex algorithms
Added: Basic capacity reporting for BDD-specified metrics only

BDD Requirements (SPEC-10 & SPEC-12):
- Working days calculation and utilization
- Planned hours calculation excluding breaks
- Utilization rate tracking and optimization
- Coverage analysis and capacity planning
- Simple resource optimization without ML

Performance: <2s for basic capacity analysis
Database: PostgreSQL Schema 001 only (no custom tables)
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum
import uuid

import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

logger = logging.getLogger(__name__)


class CapacityStatus(Enum):
    """Basic capacity status categories"""
    UNDERUTILIZED = "underutilized"    # <70% utilization
    OPTIMAL = "optimal"                # 70-85% utilization  
    OVERUTILIZED = "overutilized"     # >85% utilization


class OptimizationAction(Enum):
    """Simple optimization actions"""
    INCREASE_CAPACITY = "increase_capacity"
    REDUCE_CAPACITY = "reduce_capacity"
    REDISTRIBUTE = "redistribute"
    MAINTAIN = "maintain"


@dataclass
class BasicCapacityInsight:
    """Simplified capacity analysis result for BDD compliance"""
    analysis_id: str
    service_id: int
    resource_name: str
    current_utilization: float
    optimal_utilization: float
    capacity_status: CapacityStatus
    recommended_action: OptimizationAction
    utilization_gap: float
    working_days_efficiency: float
    planned_hours_utilization: float
    coverage_percentage: float
    analysis_timestamp: datetime
    bdd_interpretation: str
    data_source: str = "REAL_DATABASE"


class CapacityUtilizationMaximizerBDDCompliant:
    """BDD-Compliant Capacity Analysis using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 2.0  # 2 seconds for basic capacity analysis
        self.optimal_utilization = 85.0  # Target utilization percentage
        
        # Database connection - REQUIRED
        if not database_url:
            database_url = "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        
        try:
            self.engine = create_engine(database_url)
            self.SessionLocal = sessionmaker(bind=self.engine)
            self._validate_database_connection()
        except Exception as e:
            logger.error(f"Failed to initialize database: {str(e)}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Verify Schema 001 tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) 
                    FROM information_schema.tables 
                    WHERE table_name IN ('contact_statistics', 'agent_activity')
                """)).scalar()
                
                if tables_check < 2:
                    raise ConnectionError("Required Schema 001 tables missing")
                    
        except OperationalError as e:
            logger.error(f"Database connection failed: {str(e)}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def analyze_capacity_utilization(
        self,
        service_id: int,
        analysis_period_hours: int = 24*7  # 1 week default
    ) -> BasicCapacityInsight:
        """
        Analyze basic capacity utilization for BDD metrics.
        
        Args:
            service_id: Service to analyze
            analysis_period_hours: Hours of data to analyze
            
        Returns:
            BasicCapacityInsight with simple capacity analysis
        """
        start_time = time.time()
        
        try:
            # Get real utilization data
            utilization_data = self._get_utilization_data(service_id, analysis_period_hours)
            
            if not utilization_data:
                raise ValueError(f"No utilization data found for service {service_id}")
            
            # Calculate basic metrics
            current_utilization = np.mean(utilization_data['occupancy'])
            service_level = np.mean(utilization_data['service_level'])
            
            # Calculate BDD-specific metrics
            working_days_efficiency = self._calculate_working_days_efficiency(utilization_data)
            planned_hours_utilization = self._calculate_planned_hours_utilization(utilization_data)
            coverage_percentage = max(0, min(100, service_level))  # Service level as coverage proxy
            
            # Determine capacity status
            if current_utilization < 70:
                status = CapacityStatus.UNDERUTILIZED
            elif current_utilization <= 85:
                status = CapacityStatus.OPTIMAL
            else:
                status = CapacityStatus.OVERUTILIZED
            
            # Determine recommended action
            utilization_gap = current_utilization - self.optimal_utilization
            
            if abs(utilization_gap) <= 5:  # Within 5% of optimal
                action = OptimizationAction.MAINTAIN
            elif utilization_gap > 10:  # Significantly over-utilized
                action = OptimizationAction.INCREASE_CAPACITY
            elif utilization_gap < -15:  # Significantly under-utilized
                action = OptimizationAction.REDUCE_CAPACITY
            else:
                action = OptimizationAction.REDISTRIBUTE
            
            # Generate BDD interpretation
            interpretation = self._generate_bdd_interpretation(
                current_utilization, status, action, working_days_efficiency,
                planned_hours_utilization, coverage_percentage
            )
            
            # Create insight
            insight = BasicCapacityInsight(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                resource_name=f"Service_{service_id}_Agents",
                current_utilization=round(current_utilization, 1),
                optimal_utilization=self.optimal_utilization,
                capacity_status=status,
                recommended_action=action,
                utilization_gap=round(utilization_gap, 1),
                working_days_efficiency=round(working_days_efficiency, 1),
                planned_hours_utilization=round(planned_hours_utilization, 1),
                coverage_percentage=round(coverage_percentage, 1),
                analysis_timestamp=datetime.utcnow(),
                bdd_interpretation=interpretation
            )
            
            # Check performance
            processing_time = time.time() - start_time
            if processing_time > self.processing_target:
                logger.warning(
                    f"Capacity analysis took {processing_time:.2f}s "
                    f"(target: {self.processing_target}s)"
                )
            
            return insight
            
        except Exception as e:
            logger.error(f"Capacity analysis failed: {str(e)}")
            raise
    
    def _get_utilization_data(self, service_id: int, hours: int) -> pd.DataFrame:
        """Get real utilization data from PostgreSQL"""
        with self.SessionLocal() as session:
            # Query real data from contact_statistics
            query = text("""
                SELECT 
                    interval_start_time,
                    occupancy,
                    service_level,
                    calls_offered,
                    calls_handled,
                    average_handle_time
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                    AND occupancy IS NOT NULL
                    AND service_level IS NOT NULL
                ORDER BY interval_start_time
            """)
            
            result = session.execute(
                query,
                {'service_id': service_id, 'hours': hours}
            )
            
            df = pd.DataFrame(result.fetchall())
            if df.empty:
                raise ValueError(f"No data found for service {service_id}")
            
            df.columns = ['timestamp', 'occupancy', 'service_level', 
                         'calls_offered', 'calls_handled', 'average_handle_time']
            return df
    
    def _calculate_working_days_efficiency(self, data: pd.DataFrame) -> float:
        """Calculate working days efficiency per BDD SPEC-10"""
        # Working days efficiency = productive intervals / total intervals
        total_intervals = len(data)
        productive_intervals = len(data[data['occupancy'] > 0])
        
        if total_intervals == 0:
            return 0.0
        
        efficiency = (productive_intervals / total_intervals) * 100
        return efficiency
    
    def _calculate_planned_hours_utilization(self, data: pd.DataFrame) -> float:
        """Calculate planned hours utilization excluding breaks per BDD SPEC-10"""
        # Planned hours utilization = (handle time / total time) * 100
        # Assumes 15-minute intervals, with breaks reducing available time
        
        interval_minutes = 15
        break_minutes_per_interval = 2.5  # Assume ~10% break time
        net_available_minutes = interval_minutes - break_minutes_per_interval
        
        # Calculate average handle time utilization
        avg_handle_time = data['average_handle_time'].mean()
        calls_per_interval = data['calls_handled'].mean()
        
        if calls_per_interval > 0 and avg_handle_time > 0:
            # Total handle time per interval (in minutes)
            handle_time_minutes = (avg_handle_time / 60) * calls_per_interval
            utilization = (handle_time_minutes / net_available_minutes) * 100
            return min(100, max(0, utilization))  # Cap at 0-100%
        
        return 0.0
    
    def _generate_bdd_interpretation(
        self,
        utilization: float,
        status: CapacityStatus,
        action: OptimizationAction,
        working_days_eff: float,
        planned_hours_util: float,
        coverage_pct: float
    ) -> str:
        """Generate BDD-compliant business interpretation"""
        
        # Base status interpretation
        status_interpretations = {
            CapacityStatus.UNDERUTILIZED: f"Capacity underutilized at {utilization:.1f}% - potential cost inefficiency",
            CapacityStatus.OPTIMAL: f"Capacity optimally utilized at {utilization:.1f}% - maintain current level",
            CapacityStatus.OVERUTILIZED: f"Capacity overutilized at {utilization:.1f}% - service quality risk"
        }
        
        base_interpretation = status_interpretations[status]
        
        # Add BDD-specific insights
        bdd_insights = []
        
        # Working days efficiency insight (BDD SPEC-10)
        if working_days_eff < 80:
            bdd_insights.append(f"Working days efficiency low ({working_days_eff:.1f}%) - review scheduling")
        elif working_days_eff > 95:
            bdd_insights.append(f"Excellent working days efficiency ({working_days_eff:.1f}%)")
        
        # Planned hours utilization insight (BDD SPEC-10)
        if planned_hours_util < 70:
            bdd_insights.append(f"Planned hours underutilized ({planned_hours_util:.1f}%) - optimize breaks")
        elif planned_hours_util > 90:
            bdd_insights.append(f"High planned hours utilization ({planned_hours_util:.1f}%) - monitor burnout")
        
        # Coverage percentage insight (BDD SPEC-10)
        if coverage_pct < 80:
            bdd_insights.append(f"Coverage below target ({coverage_pct:.1f}%) - increase staffing")
        elif coverage_pct > 95:
            bdd_insights.append(f"Excellent coverage ({coverage_pct:.1f}%) - consider optimization")
        
        # Action recommendation
        action_recommendations = {
            OptimizationAction.INCREASE_CAPACITY: "Recommend adding staff or extending hours",
            OptimizationAction.REDUCE_CAPACITY: "Consider reducing staff or hours for cost efficiency", 
            OptimizationAction.REDISTRIBUTE: "Recommend redistributing workload across shifts",
            OptimizationAction.MAINTAIN: "Current capacity allocation is appropriate"
        }
        
        action_text = action_recommendations[action]
        
        # Combine all insights
        full_interpretation = base_interpretation
        if bdd_insights:
            full_interpretation += ". " + "; ".join(bdd_insights)
        full_interpretation += f". {action_text}."
        
        return full_interpretation
    
    def analyze_multi_service_capacity(
        self,
        service_ids: List[int],
        analysis_period_hours: int = 24*7
    ) -> List[BasicCapacityInsight]:
        """Analyze capacity for multiple services"""
        
        insights = []
        for service_id in service_ids:
            try:
                insight = self.analyze_capacity_utilization(
                    service_id=service_id,
                    analysis_period_hours=analysis_period_hours
                )
                insights.append(insight)
            except Exception as e:
                logger.warning(f"Failed to analyze capacity for service {service_id}: {e}")
                continue
        
        return insights


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        maximizer = CapacityUtilizationMaximizerBDDCompliant()
        
        # Test capacity analysis
        insight = maximizer.analyze_capacity_utilization(service_id=1)
        
        print(f"Capacity Analysis Results:")
        print(f"  Service: {insight.resource_name}")
        print(f"  Current Utilization: {insight.current_utilization}%")
        print(f"  Optimal Utilization: {insight.optimal_utilization}%")
        print(f"  Status: {insight.capacity_status.value}")
        print(f"  Recommended Action: {insight.recommended_action.value}")
        print(f"  Utilization Gap: {insight.utilization_gap:+.1f}%")
        print(f"  Working Days Efficiency: {insight.working_days_efficiency:.1f}%")
        print(f"  Planned Hours Utilization: {insight.planned_hours_utilization:.1f}%")
        print(f"  Coverage: {insight.coverage_percentage:.1f}%")
        print(f"  Interpretation: {insight.bdd_interpretation}")
        
        # Test multiple services
        multi_insights = maximizer.analyze_multi_service_capacity([1, 2])
        print(f"\nAnalyzed {len(multi_insights)} services successfully")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")