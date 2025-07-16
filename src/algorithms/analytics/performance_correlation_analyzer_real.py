#!/usr/bin/env python3
"""
Performance Correlation Analyzer - REAL Implementation
====================================================

Analyzes correlations between multiple performance metrics using real PostgreSQL data.
Zero mock dependencies - fails without database connection.

BDD Requirements:
- Multi-variable correlation analysis
- Statistical significance testing
- Business interpretation of correlations
- <3s processing time for correlation matrix
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import uuid

import numpy as np
from scipy import stats
from scipy.stats import pearsonr, spearmanr
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

logger = logging.getLogger(__name__)


class CorrelationStrength(Enum):
    """Correlation strength categories"""
    VERY_STRONG = "very_strong"  # |r| >= 0.8
    STRONG = "strong"            # 0.6 <= |r| < 0.8
    MODERATE = "moderate"        # 0.4 <= |r| < 0.6
    WEAK = "weak"                # 0.2 <= |r| < 0.4
    NEGLIGIBLE = "negligible"    # |r| < 0.2


@dataclass
class CorrelationInsight:
    """Real correlation analysis result"""
    analysis_id: str
    service_id: int
    metric_x: str
    metric_y: str
    correlation_coefficient: float
    p_value: float
    sample_size: int
    correlation_strength: CorrelationStrength
    is_significant: bool
    confidence_interval: Tuple[float, float]
    business_interpretation: str
    recommended_actions: List[str]
    analysis_timestamp: datetime
    data_quality_score: float


class PerformanceCorrelationAnalyzerReal:
    """Real-time Performance Correlation Analysis using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for correlation analysis
        self.min_sample_size = 30     # Minimum for reliable correlation
        
        # Database connection - REQUIRED
        if not database_url:
            database_url = "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        
        try:
            self.engine = create_engine(database_url)
            self.SessionLocal = sessionmaker(bind=self.engine)
            self._validate_database_connection()
            self._ensure_analytics_tables()
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
    
    def _ensure_analytics_tables(self):
        """Create analytics tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create correlation insights table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS correlation_insights (
                    id SERIAL PRIMARY KEY,
                    analysis_id UUID NOT NULL,
                    service_id INTEGER NOT NULL,
                    metric_x VARCHAR(100) NOT NULL,
                    metric_y VARCHAR(100) NOT NULL,
                    correlation_coefficient DECIMAL(6,4) NOT NULL,
                    p_value DECIMAL(10,8),
                    sample_size INTEGER NOT NULL,
                    correlation_strength VARCHAR(20),
                    statistical_significance BOOLEAN,
                    confidence_lower DECIMAL(6,4),
                    confidence_upper DECIMAL(6,4),
                    business_interpretation TEXT,
                    recommended_actions JSONB,
                    data_quality_score DECIMAL(3,2),
                    analysis_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    INDEX idx_correlation_service_metrics (service_id, metric_x, metric_y),
                    INDEX idx_correlation_timestamp (analysis_timestamp)
                )
            """))
            
            # Create correlation matrix cache table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS correlation_matrix_cache (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    matrix_data JSONB NOT NULL,
                    metrics_included TEXT[],
                    sample_size INTEGER,
                    calculated_at TIMESTAMPTZ DEFAULT NOW(),
                    expires_at TIMESTAMPTZ,
                    INDEX idx_matrix_service (service_id),
                    INDEX idx_matrix_expiry (expires_at)
                )
            """))
            
            session.commit()
            logger.info("Analytics tables ready")
    
    def analyze_metric_correlation(
        self,
        service_id: int,
        metric_x: str,
        metric_y: str,
        time_window_hours: int = 24*7,  # 1 week default
        min_data_points: int = 30
    ) -> CorrelationInsight:
        """
        Analyze correlation between two metrics using real data.
        
        Args:
            service_id: Service to analyze
            metric_x: First metric name
            metric_y: Second metric name
            time_window_hours: Hours of historical data to analyze
            min_data_points: Minimum data points required
            
        Returns:
            CorrelationInsight with real statistical analysis
        """
        start_time = time.time()
        
        try:
            # Get real data for both metrics
            data = self._get_correlation_data(
                service_id, metric_x, metric_y, time_window_hours
            )
            
            if len(data) < min_data_points:
                raise ValueError(
                    f"Insufficient data for correlation: {len(data)} points "
                    f"(minimum: {min_data_points})"
                )
            
            # Calculate real correlation
            x_values = data[metric_x].values
            y_values = data[metric_y].values
            
            # Pearson correlation for linear relationships
            corr_coef, p_value = pearsonr(x_values, y_values)
            
            # Calculate confidence interval
            ci_lower, ci_upper = self._calculate_confidence_interval(
                corr_coef, len(data)
            )
            
            # Determine correlation strength
            strength = self._classify_correlation_strength(corr_coef)
            
            # Statistical significance (p < 0.05)
            is_significant = p_value < 0.05
            
            # Generate business interpretation
            interpretation = self._interpret_correlation(
                metric_x, metric_y, corr_coef, is_significant, strength
            )
            
            # Generate actionable recommendations
            recommendations = self._generate_correlation_recommendations(
                metric_x, metric_y, corr_coef, strength, is_significant
            )
            
            # Calculate data quality score
            quality_score = self._assess_data_quality(data, x_values, y_values)
            
            # Create insight
            insight = CorrelationInsight(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                metric_x=metric_x,
                metric_y=metric_y,
                correlation_coefficient=round(corr_coef, 4),
                p_value=p_value,
                sample_size=len(data),
                correlation_strength=strength,
                is_significant=is_significant,
                confidence_interval=(round(ci_lower, 4), round(ci_upper, 4)),
                business_interpretation=interpretation,
                recommended_actions=recommendations,
                analysis_timestamp=datetime.utcnow(),
                data_quality_score=quality_score
            )
            
            # Save to database
            self._save_correlation_insight(insight)
            
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
        """Get real metric data from PostgreSQL"""
        with self.SessionLocal() as session:
            # Map metric names to database columns
            metric_mapping = {
                'service_level': 'service_level',
                'average_wait_time': 'average_wait_time',
                'abandonment_rate': 'abandonment_rate',
                'occupancy': 'occupancy',
                'calls_offered': 'calls_offered',
                'calls_handled': 'calls_handled',
                'average_handle_time': 'average_handle_time',
                'agent_utilization': 'occupancy',  # Alias
                'call_volume': 'calls_offered'     # Alias
            }
            
            x_column = metric_mapping.get(metric_x, metric_x)
            y_column = metric_mapping.get(metric_y, metric_y)
            
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
    
    def _calculate_confidence_interval(
        self,
        r: float,
        n: int,
        confidence: float = 0.95
    ) -> Tuple[float, float]:
        """Calculate confidence interval for correlation coefficient"""
        # Fisher Z transformation
        z = 0.5 * np.log((1 + r) / (1 - r))
        se = 1 / np.sqrt(n - 3)
        
        # Critical value for 95% confidence
        z_crit = stats.norm.ppf((1 + confidence) / 2)
        
        # Confidence interval in Z space
        z_lower = z - z_crit * se
        z_upper = z + z_crit * se
        
        # Transform back to r
        r_lower = (np.exp(2 * z_lower) - 1) / (np.exp(2 * z_lower) + 1)
        r_upper = (np.exp(2 * z_upper) - 1) / (np.exp(2 * z_upper) + 1)
        
        return r_lower, r_upper
    
    def _classify_correlation_strength(self, r: float) -> CorrelationStrength:
        """Classify correlation coefficient strength"""
        abs_r = abs(r)
        
        if abs_r >= 0.8:
            return CorrelationStrength.VERY_STRONG
        elif abs_r >= 0.6:
            return CorrelationStrength.STRONG
        elif abs_r >= 0.4:
            return CorrelationStrength.MODERATE
        elif abs_r >= 0.2:
            return CorrelationStrength.WEAK
        else:
            return CorrelationStrength.NEGLIGIBLE
    
    def _interpret_correlation(
        self,
        metric_x: str,
        metric_y: str,
        corr: float,
        is_significant: bool,
        strength: CorrelationStrength
    ) -> str:
        """Generate business interpretation of correlation"""
        direction = "positive" if corr > 0 else "negative"
        
        # Common interpretations
        interpretations = {
            ('agent_utilization', 'service_level'): {
                'negative': "Higher agent utilization is associated with lower service levels, "
                           "suggesting agents are overloaded",
                'positive': "Unexpected positive correlation - may indicate data quality issues"
            },
            ('call_volume', 'average_wait_time'): {
                'positive': "Higher call volumes lead to longer wait times, "
                           "indicating capacity constraints",
                'negative': "Unexpected negative correlation - verify staffing adjustments"
            },
            ('average_handle_time', 'abandonment_rate'): {
                'positive': "Longer handle times correlate with higher abandonment, "
                           "suggesting customer patience limits",
                'negative': "Shorter handle times reduce abandonment rates"
            }
        }
        
        # Check for specific interpretation
        key = (metric_x, metric_y)
        reverse_key = (metric_y, metric_x)
        
        if key in interpretations:
            base_interp = interpretations[key].get(
                direction,
                f"{strength.value.replace('_', ' ').title()} {direction} correlation"
            )
        elif reverse_key in interpretations:
            base_interp = interpretations[reverse_key].get(
                direction,
                f"{strength.value.replace('_', ' ').title()} {direction} correlation"
            )
        else:
            base_interp = (
                f"{strength.value.replace('_', ' ').title()} {direction} "
                f"correlation between {metric_x} and {metric_y}"
            )
        
        # Add significance note
        if not is_significant:
            base_interp += " (not statistically significant)"
        
        return base_interp
    
    def _generate_correlation_recommendations(
        self,
        metric_x: str,
        metric_y: str,
        corr: float,
        strength: CorrelationStrength,
        is_significant: bool
    ) -> List[str]:
        """Generate actionable recommendations based on correlation"""
        if not is_significant:
            return ["Monitor for changes as correlation is not statistically significant"]
        
        recommendations = []
        
        # Strong correlations warrant action
        if strength in [CorrelationStrength.STRONG, CorrelationStrength.VERY_STRONG]:
            if (metric_x == 'agent_utilization' and metric_y == 'service_level' and corr < 0):
                recommendations.extend([
                    "Consider increasing staffing when utilization exceeds 85%",
                    "Implement real-time monitoring alerts for high utilization",
                    "Review scheduling to better match demand patterns"
                ])
            
            elif (metric_x == 'call_volume' and metric_y == 'average_wait_time' and corr > 0):
                recommendations.extend([
                    "Implement dynamic staffing based on volume forecasts",
                    "Consider skill-based routing to improve efficiency",
                    "Add overflow capacity during peak periods"
                ])
            
            else:
                recommendations.append(
                    f"Investigate the strong {('positive' if corr > 0 else 'negative')} "
                    f"relationship between {metric_x} and {metric_y}"
                )
        
        # Moderate correlations
        elif strength == CorrelationStrength.MODERATE:
            recommendations.append(
                f"Monitor {metric_x} as a leading indicator for {metric_y} changes"
            )
        
        # Weak correlations
        else:
            recommendations.append(
                f"Continue monitoring but no immediate action required"
            )
        
        return recommendations
    
    def _assess_data_quality(self, df: pd.DataFrame, x: np.ndarray, y: np.ndarray) -> float:
        """Assess quality of data used for correlation"""
        quality_score = 1.0
        
        # Check for outliers (reduce quality score)
        x_outliers = np.abs(stats.zscore(x)) > 3
        y_outliers = np.abs(stats.zscore(y)) > 3
        outlier_ratio = (x_outliers.sum() + y_outliers.sum()) / (2 * len(x))
        quality_score -= outlier_ratio * 0.3
        
        # Check for data completeness
        completeness = len(df) / (len(df) + df.isnull().sum().sum())
        quality_score *= completeness
        
        # Check for variance (too little variance = poor correlation)
        x_cv = np.std(x) / np.mean(x) if np.mean(x) != 0 else 0
        y_cv = np.std(y) / np.mean(y) if np.mean(y) != 0 else 0
        
        if x_cv < 0.05 or y_cv < 0.05:  # Less than 5% coefficient of variation
            quality_score *= 0.8
        
        return round(max(0.0, min(1.0, quality_score)), 2)
    
    def _save_correlation_insight(self, insight: CorrelationInsight):
        """Save correlation insight to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO correlation_insights (
                    analysis_id, service_id, metric_x, metric_y,
                    correlation_coefficient, p_value, sample_size,
                    correlation_strength, statistical_significance,
                    confidence_lower, confidence_upper,
                    business_interpretation, recommended_actions,
                    data_quality_score, analysis_timestamp
                ) VALUES (
                    :analysis_id, :service_id, :metric_x, :metric_y,
                    :correlation_coefficient, :p_value, :sample_size,
                    :correlation_strength, :statistical_significance,
                    :confidence_lower, :confidence_upper,
                    :interpretation, :recommendations::jsonb,
                    :data_quality_score, :timestamp
                )
            """), {
                'analysis_id': insight.analysis_id,
                'service_id': insight.service_id,
                'metric_x': insight.metric_x,
                'metric_y': insight.metric_y,
                'correlation_coefficient': insight.correlation_coefficient,
                'p_value': insight.p_value,
                'sample_size': insight.sample_size,
                'correlation_strength': insight.correlation_strength.value,
                'statistical_significance': insight.is_significant,
                'confidence_lower': insight.confidence_interval[0],
                'confidence_upper': insight.confidence_interval[1],
                'interpretation': insight.business_interpretation,
                'recommendations': {'actions': insight.recommended_actions},
                'data_quality_score': insight.data_quality_score,
                'timestamp': insight.analysis_timestamp
            })
            session.commit()
    
    def build_correlation_matrix(
        self,
        service_id: int,
        metrics: List[str],
        time_window_hours: int = 24*7
    ) -> Dict[str, Any]:
        """Build complete correlation matrix for multiple metrics"""
        start_time = time.time()
        
        try:
            # Get all data at once for efficiency
            with self.SessionLocal() as session:
                metric_columns = []
                for metric in metrics:
                    if metric in ['service_level', 'average_wait_time', 'abandonment_rate',
                                  'occupancy', 'calls_offered', 'calls_handled', 
                                  'average_handle_time']:
                        metric_columns.append(metric)
                
                if not metric_columns:
                    raise ValueError("No valid metrics specified")
                
                columns_str = ', '.join(metric_columns)
                
                query = text(f"""
                    SELECT {columns_str}
                    FROM contact_statistics
                    WHERE service_id = :service_id
                        AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                    ORDER BY interval_start_time
                """)
                
                result = session.execute(
                    query,
                    {'service_id': service_id, 'hours': time_window_hours}
                )
                
                df = pd.DataFrame(result.fetchall(), columns=metric_columns)
                
                if df.empty or len(df) < self.min_sample_size:
                    raise ValueError(f"Insufficient data: {len(df)} rows")
                
                # Calculate correlation matrix
                corr_matrix = df.corr(method='pearson')
                
                # Calculate p-values for each correlation
                p_values = np.zeros_like(corr_matrix)
                for i in range(len(metrics)):
                    for j in range(len(metrics)):
                        if i != j:
                            _, p_values[i, j] = pearsonr(
                                df.iloc[:, i], df.iloc[:, j]
                            )
                
                # Build response
                matrix_data = {
                    'correlation_matrix': corr_matrix.to_dict(),
                    'p_values': p_values.tolist(),
                    'metrics': metric_columns,
                    'sample_size': len(df),
                    'significant_correlations': self._find_significant_correlations(
                        corr_matrix, p_values, metric_columns
                    )
                }
                
                # Cache result
                self._cache_correlation_matrix(service_id, matrix_data)
                
                processing_time = time.time() - start_time
                matrix_data['processing_time_seconds'] = processing_time
                
                return matrix_data
                
        except Exception as e:
            logger.error(f"Failed to build correlation matrix: {str(e)}")
            raise
    
    def _find_significant_correlations(
        self,
        corr_matrix: pd.DataFrame,
        p_values: np.ndarray,
        metrics: List[str]
    ) -> List[Dict[str, Any]]:
        """Find statistically significant correlations"""
        significant = []
        
        for i in range(len(metrics)):
            for j in range(i + 1, len(metrics)):
                if p_values[i, j] < 0.05:  # Significant
                    corr = corr_matrix.iloc[i, j]
                    strength = self._classify_correlation_strength(corr)
                    
                    if strength not in [CorrelationStrength.NEGLIGIBLE, 
                                       CorrelationStrength.WEAK]:
                        significant.append({
                            'metric_x': metrics[i],
                            'metric_y': metrics[j],
                            'correlation': round(corr, 4),
                            'p_value': p_values[i, j],
                            'strength': strength.value
                        })
        
        # Sort by absolute correlation strength
        significant.sort(key=lambda x: abs(x['correlation']), reverse=True)
        return significant
    
    def _cache_correlation_matrix(self, service_id: int, matrix_data: Dict[str, Any]):
        """Cache correlation matrix for performance"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO correlation_matrix_cache (
                    service_id, matrix_data, metrics_included, 
                    sample_size, expires_at
                ) VALUES (
                    :service_id, :matrix_data::jsonb, :metrics,
                    :sample_size, NOW() + INTERVAL '1 hour'
                )
            """), {
                'service_id': service_id,
                'matrix_data': matrix_data,
                'metrics': matrix_data['metrics'],
                'sample_size': matrix_data['sample_size']
            })
            session.commit()


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        analyzer = PerformanceCorrelationAnalyzerReal()
        
        # Example: Analyze correlation between utilization and service level
        insight = analyzer.analyze_metric_correlation(
            service_id=1,
            metric_x='agent_utilization',
            metric_y='service_level'
        )
        
        print(f"Correlation: {insight.correlation_coefficient}")
        print(f"Significant: {insight.is_significant}")
        print(f"Interpretation: {insight.business_interpretation}")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")