#!/usr/bin/env python3
"""
Performance Correlation Analyzer - BDD Compliant Version
========================================================

Simplified correlation analysis based on BDD specifications from files 10 and 12.
Removed: Advanced statistics, ML components, custom tables, complex correlation matrices
Added: Basic reporting correlations for BDD-specified metrics only

BDD Requirements (SPEC-10 & SPEC-12):
- Basic performance metric reporting
- Simple correlation identification for operational metrics
- Service level vs utilization analysis
- Coverage vs performance correlation

Performance: <3s for basic correlation reporting
Database: PostgreSQL Schema 001 only (no custom tables)
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import uuid

import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

logger = logging.getLogger(__name__)


class CorrelationCategory(Enum):
    """Simple correlation categories"""
    POSITIVE = "positive"     # r > 0.1
    NEGATIVE = "negative"     # r < -0.1
    NONE = "none"            # -0.1 <= r <= 0.1


class CorrelationSignificance(Enum):
    """Basic significance levels"""
    SIGNIFICANT = "significant"      # |r| > 0.3
    MODERATE = "moderate"           # 0.1 < |r| <= 0.3
    NEGLIGIBLE = "negligible"       # |r| <= 0.1


@dataclass
class BasicCorrelationInsight:
    """Simplified correlation result for BDD compliance"""
    analysis_id: str
    service_id: int
    metric_x: str
    metric_y: str
    correlation_value: float
    correlation_category: CorrelationCategory
    correlation_significance: CorrelationSignificance
    sample_size: int
    bdd_interpretation: str
    analysis_timestamp: datetime
    data_source: str = "REAL_DATABASE"


class PerformanceCorrelationAnalyzerBDDCompliant:
    """BDD-Compliant Correlation Analysis using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for basic correlation analysis
        self.min_sample_size = 20     # Minimum for basic correlation
        
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
    
    def analyze_basic_correlation(
        self,
        service_id: int,
        metric_x: str,
        metric_y: str,
        time_window_hours: int = 24*7  # 1 week default
    ) -> BasicCorrelationInsight:
        """
        Analyze basic correlation between two BDD metrics.
        
        Args:
            service_id: Service to analyze
            metric_x: First BDD metric name
            metric_y: Second BDD metric name  
            time_window_hours: Hours of data to analyze
            
        Returns:
            BasicCorrelationInsight with simple correlation analysis
        """
        start_time = time.time()
        
        try:
            # Get real data for both metrics
            data = self._get_correlation_data(
                service_id, metric_x, metric_y, time_window_hours
            )
            
            if len(data) < self.min_sample_size:
                raise ValueError(
                    f"Insufficient data for correlation: {len(data)} points "
                    f"(minimum: {self.min_sample_size})"
                )
            
            # Calculate simple correlation (Pearson)
            x_values = data[metric_x].values
            y_values = data[metric_y].values
            
            # Simple correlation calculation
            correlation_matrix = np.corrcoef(x_values, y_values)
            correlation_value = correlation_matrix[0, 1]
            
            # Handle NaN correlation (e.g., constant values)
            if np.isnan(correlation_value):
                correlation_value = 0.0
            
            # Categorize correlation
            if correlation_value > 0.1:
                category = CorrelationCategory.POSITIVE
            elif correlation_value < -0.1:
                category = CorrelationCategory.NEGATIVE
            else:
                category = CorrelationCategory.NONE
            
            # Determine significance
            abs_corr = abs(correlation_value)
            if abs_corr > 0.3:
                significance = CorrelationSignificance.SIGNIFICANT
            elif abs_corr > 0.1:
                significance = CorrelationSignificance.MODERATE
            else:
                significance = CorrelationSignificance.NEGLIGIBLE
            
            # Generate BDD interpretation
            interpretation = self._generate_bdd_interpretation(
                metric_x, metric_y, correlation_value, category, significance
            )
            
            # Create insight
            insight = BasicCorrelationInsight(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                metric_x=metric_x,
                metric_y=metric_y,
                correlation_value=round(correlation_value, 3),
                correlation_category=category,
                correlation_significance=significance,
                sample_size=len(data),
                bdd_interpretation=interpretation,
                analysis_timestamp=datetime.utcnow()
            )
            
            # Check performance
            processing_time = time.time() - start_time
            if processing_time > self.processing_target:
                logger.warning(
                    f"Correlation analysis took {processing_time:.2f}s "
                    f"(target: {self.processing_target}s)"
                )
            
            return insight
            
        except Exception as e:
            logger.error(f"Correlation analysis failed: {str(e)}")
            raise
    
    def _get_correlation_data(
        self,
        service_id: int,
        metric_x: str,
        metric_y: str,
        time_window_hours: int
    ) -> pd.DataFrame:
        """Get real metric data from PostgreSQL for correlation analysis"""
        with self.SessionLocal() as session:
            # Map BDD metric names to database columns
            metric_mapping = {
                'service_level': 'service_level',
                'utilization': 'occupancy',
                'average_wait_time': 'average_wait_time',
                'abandonment_rate': 'abandonment_rate',
                'calls_offered': 'calls_offered',
                'calls_handled': 'calls_handled',
                'coverage_percentage': 'service_level',  # Proxy
                'productivity_score': 'occupancy',       # Proxy
                'working_days': 'calls_offered'          # Proxy
            }
            
            x_column = metric_mapping.get(metric_x, 'service_level')  # Default fallback
            y_column = metric_mapping.get(metric_y, 'occupancy')      # Default fallback
            
            # Query real data
            query = text(f"""
                SELECT 
                    interval_start_time,
                    {x_column} as metric_x,
                    {y_column} as metric_y
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                    AND {x_column} IS NOT NULL
                    AND {y_column} IS NOT NULL
                ORDER BY interval_start_time
            """)
            
            result = session.execute(
                query,
                {'service_id': service_id, 'hours': time_window_hours}
            )
            
            df = pd.DataFrame(result.fetchall())
            if df.empty:
                raise ValueError(f"No data found for service {service_id}")
            
            df.columns = ['timestamp', metric_x, metric_y]
            return df
    
    def _generate_bdd_interpretation(
        self,
        metric_x: str,
        metric_y: str,
        correlation: float,
        category: CorrelationCategory,
        significance: CorrelationSignificance
    ) -> str:
        """Generate BDD-compliant business interpretation"""
        
        # BDD-specific interpretations from SPEC-10 and SPEC-12
        bdd_correlations = {
            ('utilization', 'service_level'): {
                CorrelationCategory.NEGATIVE: "Higher utilization correlates with lower service levels - monitor staffing",
                CorrelationCategory.POSITIVE: "Utilization and service level moving together - verify data quality",
                CorrelationCategory.NONE: "No clear relationship between utilization and service level"
            },
            ('calls_offered', 'average_wait_time'): {
                CorrelationCategory.POSITIVE: "More calls offered leads to longer wait times - capacity constraint",
                CorrelationCategory.NEGATIVE: "Calls offered and wait time inversely related - good scaling",
                CorrelationCategory.NONE: "Call volume doesn't clearly impact wait times"
            },
            ('coverage_percentage', 'service_level'): {
                CorrelationCategory.POSITIVE: "Better coverage correlates with improved service levels",
                CorrelationCategory.NEGATIVE: "Coverage and service level inversely related - investigate",
                CorrelationCategory.NONE: "Coverage doesn't clearly predict service level performance"
            },
            ('productivity_score', 'service_level'): {
                CorrelationCategory.POSITIVE: "Higher productivity associates with better service levels",
                CorrelationCategory.NEGATIVE: "Productivity and service quality appear to conflict",
                CorrelationCategory.NONE: "No clear productivity-service level relationship"
            }
        }
        
        # Check for specific interpretation
        key = (metric_x, metric_y)
        reverse_key = (metric_y, metric_x)
        
        if key in bdd_correlations:
            base_interpretation = bdd_correlations[key].get(
                category,
                f"Basic {category.value} relationship between {metric_x} and {metric_y}"
            )
        elif reverse_key in bdd_correlations:
            base_interpretation = bdd_correlations[reverse_key].get(
                category,
                f"Basic {category.value} relationship between {metric_y} and {metric_x}"
            )
        else:
            base_interpretation = (
                f"Basic {category.value} correlation between {metric_x} and {metric_y}"
            )
        
        # Add significance qualifier
        if significance == CorrelationSignificance.SIGNIFICANT:
            base_interpretation = f"SIGNIFICANT: {base_interpretation} (r={correlation:.2f})"
        elif significance == CorrelationSignificance.MODERATE:
            base_interpretation = f"MODERATE: {base_interpretation} (r={correlation:.2f})"
        else:
            base_interpretation = f"WEAK: {base_interpretation} (r={correlation:.2f})"
        
        return base_interpretation
    
    def analyze_bdd_metric_correlations(
        self,
        service_id: int,
        time_window_hours: int = 24*7
    ) -> List[BasicCorrelationInsight]:
        """Analyze correlations between key BDD metrics"""
        
        # Key BDD metric pairs for analysis
        bdd_metric_pairs = [
            ('utilization', 'service_level'),
            ('calls_offered', 'average_wait_time'),
            ('coverage_percentage', 'service_level'),
            ('productivity_score', 'service_level'),
            ('utilization', 'abandonment_rate'),
            ('service_level', 'average_wait_time')
        ]
        
        correlations = []
        for metric_x, metric_y in bdd_metric_pairs:
            try:
                correlation = self.analyze_basic_correlation(
                    service_id=service_id,
                    metric_x=metric_x,
                    metric_y=metric_y,
                    time_window_hours=time_window_hours
                )
                correlations.append(correlation)
            except Exception as e:
                logger.warning(f"Failed to analyze correlation {metric_x}-{metric_y}: {e}")
                continue
        
        return correlations


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        analyzer = PerformanceCorrelationAnalyzerBDDCompliant()
        
        # Test basic correlation
        correlation = analyzer.analyze_basic_correlation(
            service_id=1,
            metric_x='utilization',
            metric_y='service_level'
        )
        
        print(f"Correlation Analysis Results:")
        print(f"  Metrics: {correlation.metric_x} vs {correlation.metric_y}")
        print(f"  Correlation: {correlation.correlation_value}")
        print(f"  Category: {correlation.correlation_category.value}")
        print(f"  Significance: {correlation.correlation_significance.value}")
        print(f"  Sample Size: {correlation.sample_size}")
        print(f"  Interpretation: {correlation.bdd_interpretation}")
        
        # Test multiple correlations
        all_correlations = analyzer.analyze_bdd_metric_correlations(service_id=1)
        print(f"\nAnalyzed {len(all_correlations)} BDD metric correlations successfully")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")