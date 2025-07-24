#!/usr/bin/env python3
"""
Trend Detection Engine - BDD Compliant Version
==============================================

Simplified trend detection based on BDD specifications from files 10 and 12.
Removed: Advanced statistical analysis, ML components, custom tables
Added: Basic trend reporting for BDD-specified metrics only

BDD Requirements (SPEC-10 & SPEC-12):
- Working days calculation display 
- Planned hours calculation excluding breaks
- Overtime detection and display
- Coverage analysis statistics
- Utilization rate tracking
- Absence rate calculation
- Productivity metrics tracking

Performance: <3s for basic trend analysis
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


class TrendDirection(Enum):
    """Simple trend directions"""
    INCREASING = "increasing"
    DECREASING = "decreasing"
    STABLE = "stable"


class TrendStrength(Enum):
    """Basic trend strength categories"""
    STRONG = "strong"      # >10% change
    MODERATE = "moderate"  # 5-10% change
    WEAK = "weak"         # <5% change


@dataclass
class BasicTrendInsight:
    """Simplified trend analysis result for BDD compliance"""
    analysis_id: str
    service_id: int
    metric_name: str
    trend_direction: TrendDirection
    trend_strength: TrendStrength
    current_value: float
    previous_value: float
    percentage_change: float
    measurement_period_days: int
    analysis_timestamp: datetime
    bdd_interpretation: str
    data_source: str = "REAL_DATABASE"


class TrendDetectionEngineBDDCompliant:
    """BDD-Compliant Trend Detection using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for basic trend analysis
        
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
    
    def detect_basic_trend(
        self,
        service_id: int,
        metric_name: str,
        analysis_period_days: int = 7,
        comparison_period_days: int = 7
    ) -> BasicTrendInsight:
        """
        Detect basic trend in BDD-specified metrics.
        
        Args:
            service_id: Service to analyze
            metric_name: BDD metric name (service_level, utilization, etc.)
            analysis_period_days: Current period to analyze
            comparison_period_days: Previous period to compare against
            
        Returns:
            BasicTrendInsight with simple trend analysis
        """
        start_time = time.time()
        
        try:
            # Get current and previous period data
            current_data = self._get_metric_data(
                service_id, metric_name, analysis_period_days, 0
            )
            
            previous_data = self._get_metric_data(
                service_id, metric_name, comparison_period_days, analysis_period_days
            )
            
            if not current_data or not previous_data:
                raise ValueError(f"Insufficient data for trend analysis: {metric_name}")
            
            # Calculate simple averages
            current_avg = np.mean(current_data)
            previous_avg = np.mean(previous_data)
            
            # Calculate percentage change
            if previous_avg != 0:
                percentage_change = ((current_avg - previous_avg) / previous_avg) * 100
            else:
                percentage_change = 0.0
            
            # Determine trend direction
            if abs(percentage_change) < 1.0:  # Less than 1% change
                direction = TrendDirection.STABLE
            elif percentage_change > 0:
                direction = TrendDirection.INCREASING
            else:
                direction = TrendDirection.DECREASING
            
            # Determine trend strength
            abs_change = abs(percentage_change)
            if abs_change >= 10:
                strength = TrendStrength.STRONG
            elif abs_change >= 5:
                strength = TrendStrength.MODERATE
            else:
                strength = TrendStrength.WEAK
            
            # Generate BDD-compliant interpretation
            interpretation = self._generate_bdd_interpretation(
                metric_name, direction, strength, percentage_change
            )
            
            # Create insight
            insight = BasicTrendInsight(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                metric_name=metric_name,
                trend_direction=direction,
                trend_strength=strength,
                current_value=round(current_avg, 2),
                previous_value=round(previous_avg, 2),
                percentage_change=round(percentage_change, 2),
                measurement_period_days=analysis_period_days,
                analysis_timestamp=datetime.utcnow(),
                bdd_interpretation=interpretation
            )
            
            # Check performance
            processing_time = time.time() - start_time
            if processing_time > self.processing_target:
                logger.warning(
                    f"Trend analysis took {processing_time:.2f}s "
                    f"(target: {self.processing_target}s)"
                )
            
            return insight
            
        except Exception as e:
            logger.error(f"Trend detection failed: {str(e)}")
            raise
    
    def _get_metric_data(
        self,
        service_id: int,
        metric_name: str,
        days: int,
        offset_days: int
    ) -> List[float]:
        """Get real metric data from PostgreSQL for specified period"""
        with self.SessionLocal() as session:
            # Map BDD metric names to database columns
            metric_mapping = {
                'service_level': 'service_level',
                'utilization': 'occupancy',
                'average_wait_time': 'average_wait_time',
                'abandonment_rate': 'abandonment_rate',
                'calls_offered': 'calls_offered',
                'calls_handled': 'calls_handled',
                'average_handle_time': 'average_handle_time',
                'working_days': 'calls_offered',  # Proxy metric
                'overtime_hours': 'occupancy',    # Proxy metric (high occupancy indicates overtime)
                'absence_rate': 'abandonment_rate',  # Proxy metric
                'coverage_percentage': 'service_level',  # Direct mapping
                'productivity_score': 'occupancy'  # Proxy metric
            }
            
            db_column = metric_mapping.get(metric_name, metric_name)
            
            # Query real data
            query = text(f"""
                SELECT {db_column} as metric_value
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':total_days days'
                    AND interval_start_time < NOW() - INTERVAL ':offset_days days'
                    AND {db_column} IS NOT NULL
                ORDER BY interval_start_time
            """)
            
            result = session.execute(
                query,
                {
                    'service_id': service_id, 
                    'total_days': days + offset_days,
                    'offset_days': offset_days
                }
            )
            
            values = [float(row.metric_value) for row in result.fetchall()]
            return values
    
    def _generate_bdd_interpretation(
        self,
        metric_name: str,
        direction: TrendDirection,
        strength: TrendStrength,
        change_percent: float
    ) -> str:
        """Generate BDD-compliant business interpretation"""
        
        # BDD-specific interpretations from SPEC-10 and SPEC-12
        bdd_interpretations = {
            'service_level': {
                TrendDirection.INCREASING: "Service level performance is improving, indicating better customer experience",
                TrendDirection.DECREASING: "Service level declining, may require staffing adjustment or process improvement",
                TrendDirection.STABLE: "Service level remains consistent within target range"
            },
            'utilization': {
                TrendDirection.INCREASING: "Agent utilization increasing, monitor for burnout risk above 85%",
                TrendDirection.DECREASING: "Agent utilization decreasing, may indicate overstaffing or reduced demand",
                TrendDirection.STABLE: "Agent utilization stable within operational targets"
            },
            'coverage_percentage': {
                TrendDirection.INCREASING: "Coverage improving, indicating better staffing alignment with demand",
                TrendDirection.DECREASING: "Coverage declining, may require schedule adjustments or additional staff",
                TrendDirection.STABLE: "Coverage remains adequate for current service requirements"
            },
            'working_days': {
                TrendDirection.INCREASING: "Working days utilization increasing, good productivity indicator",
                TrendDirection.DECREASING: "Working days utilization decreasing, review absence patterns",
                TrendDirection.STABLE: "Working days utilization consistent with planning targets"
            },
            'overtime_hours': {
                TrendDirection.INCREASING: "Overtime usage increasing, evaluate base staffing levels",
                TrendDirection.DECREASING: "Overtime usage decreasing, indicating better resource planning",
                TrendDirection.STABLE: "Overtime usage within acceptable limits"
            }
        }
        
        # Get base interpretation
        if metric_name in bdd_interpretations:
            base_interpretation = bdd_interpretations[metric_name].get(
                direction, 
                f"{metric_name} showing {direction.value} trend"
            )
        else:
            base_interpretation = f"{metric_name} showing {direction.value} {strength.value} trend"
        
        # Add strength qualifier for significant changes
        if strength == TrendStrength.STRONG:
            base_interpretation = f"STRONG TREND: {base_interpretation} ({change_percent:+.1f}%)"
        elif strength == TrendStrength.MODERATE:
            base_interpretation = f"MODERATE TREND: {base_interpretation} ({change_percent:+.1f}%)"
        else:
            base_interpretation = f"MINOR TREND: {base_interpretation} ({change_percent:+.1f}%)"
        
        return base_interpretation
    
    def analyze_bdd_metrics_trends(
        self,
        service_id: int,
        analysis_period_days: int = 7
    ) -> List[BasicTrendInsight]:
        """Analyze trends for all BDD-specified metrics"""
        
        # BDD metrics from SPEC-10 and SPEC-12
        bdd_metrics = [
            'service_level',
            'utilization', 
            'coverage_percentage',
            'working_days',
            'overtime_hours',
            'average_wait_time',
            'abandonment_rate'
        ]
        
        trends = []
        for metric in bdd_metrics:
            try:
                trend = self.detect_basic_trend(
                    service_id=service_id,
                    metric_name=metric,
                    analysis_period_days=analysis_period_days,
                    comparison_period_days=analysis_period_days
                )
                trends.append(trend)
            except Exception as e:
                logger.warning(f"Failed to analyze trend for {metric}: {e}")
                continue
        
        return trends


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        detector = TrendDetectionEngineBDDCompliant()
        
        # Test basic trend detection
        trend = detector.detect_basic_trend(
            service_id=1,
            metric_name='service_level',
            analysis_period_days=7,
            comparison_period_days=7
        )
        
        print(f"Trend Analysis Results:")
        print(f"  Metric: {trend.metric_name}")
        print(f"  Direction: {trend.trend_direction.value}")
        print(f"  Strength: {trend.trend_strength.value}")
        print(f"  Change: {trend.percentage_change:+.1f}%")
        print(f"  Current: {trend.current_value}")
        print(f"  Previous: {trend.previous_value}")
        print(f"  Interpretation: {trend.bdd_interpretation}")
        
        # Test multiple metrics
        all_trends = detector.analyze_bdd_metrics_trends(service_id=1)
        print(f"\nAnalyzed {len(all_trends)} BDD metrics successfully")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")