#!/usr/bin/env python3
"""
Trend Detection Engine - REAL Implementation
==========================================

Detects trends in time series data using statistical methods on real PostgreSQL data.
Zero mock dependencies - fails without database connection.

BDD Requirements:
- Mann-Kendall trend test for non-parametric analysis
- Sen's slope estimator for trend magnitude
- Seasonal decomposition
- <3s processing time for trend analysis
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
import pandas as pd
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import adfuller
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

logger = logging.getLogger(__name__)


class TrendDirection(Enum):
    """Trend direction classification"""
    INCREASING = "increasing"
    DECREASING = "decreasing"
    STABLE = "stable"
    VOLATILE = "volatile"


class TrendStrength(Enum):
    """Trend strength classification"""
    VERY_STRONG = "very_strong"  # p < 0.001
    STRONG = "strong"            # p < 0.01
    MODERATE = "moderate"        # p < 0.05
    WEAK = "weak"                # p < 0.1
    NONE = "none"                # p >= 0.1


@dataclass
class TrendAnalysisResult:
    """Real trend analysis result"""
    analysis_id: str
    service_id: int
    metric_name: str
    trend_direction: TrendDirection
    trend_strength: TrendStrength
    trend_slope: float  # Sen's slope
    mann_kendall_statistic: float
    p_value: float
    confidence_interval: Tuple[float, float]
    seasonal_component: bool
    seasonal_period: Optional[int]
    seasonality_strength: Optional[float]
    forecast_30_days: List[float]
    forecast_confidence_bands: Dict[str, List[float]]
    change_points: List[datetime]
    analysis_start_date: datetime
    analysis_end_date: datetime
    data_points: int
    analysis_timestamp: datetime


class TrendDetectionEngineReal:
    """Real-time Trend Detection using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for trend analysis
        self.min_data_points = 10     # Minimum for trend detection
        
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
                    WHERE table_name = 'contact_statistics'
                """)).scalar()
                
                if tables_check < 1:
                    raise ConnectionError("Required Schema 001 tables missing")
                    
        except OperationalError as e:
            logger.error(f"Database connection failed: {str(e)}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_analytics_tables(self):
        """Create analytics tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create trend analysis results table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS trend_analysis_results (
                    id SERIAL PRIMARY KEY,
                    analysis_id UUID NOT NULL,
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(100) NOT NULL,
                    trend_direction VARCHAR(20) NOT NULL,
                    trend_strength VARCHAR(20) NOT NULL,
                    trend_slope DECIMAL(10,6),
                    mann_kendall_statistic DECIMAL(10,4),
                    p_value DECIMAL(10,8),
                    confidence_lower DECIMAL(10,6),
                    confidence_upper DECIMAL(10,6),
                    seasonal_component BOOLEAN DEFAULT false,
                    seasonal_period_days INTEGER,
                    seasonality_strength DECIMAL(5,4),
                    forecast_next_30_days JSONB,
                    forecast_confidence_bands JSONB,
                    change_points JSONB,
                    analysis_start_date DATE NOT NULL,
                    analysis_end_date DATE NOT NULL,
                    data_points_analyzed INTEGER,
                    analysis_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    INDEX idx_trend_service_metric (service_id, metric_name),
                    INDEX idx_trend_timestamp (analysis_timestamp)
                )
            """))
            
            # Create trend alerts table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS trend_alerts (
                    id SERIAL PRIMARY KEY,
                    analysis_id UUID NOT NULL,
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(100) NOT NULL,
                    alert_type VARCHAR(50) NOT NULL,
                    severity VARCHAR(20) NOT NULL,
                    description TEXT,
                    recommended_action TEXT,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    acknowledged_at TIMESTAMPTZ,
                    INDEX idx_alerts_service (service_id),
                    INDEX idx_alerts_unack (acknowledged_at) WHERE acknowledged_at IS NULL
                )
            """))
            
            session.commit()
            logger.info("Trend analysis tables ready")
    
    def detect_trend(
        self,
        service_id: int,
        metric_name: str,
        weeks: int = 12,
        confidence_level: float = 0.95
    ) -> TrendAnalysisResult:
        """
        Detect trends in metric using Mann-Kendall test.
        
        Args:
            service_id: Service to analyze
            metric_name: Metric to analyze for trends
            weeks: Number of weeks of historical data
            confidence_level: Confidence level for analysis
            
        Returns:
            TrendAnalysisResult with statistical trend analysis
        """
        start_time = time.time()
        
        try:
            # Get time series data
            ts_data = self._get_time_series_data(service_id, metric_name, weeks)
            
            if len(ts_data) < self.min_data_points:
                raise ValueError(
                    f"Insufficient data for trend analysis: {len(ts_data)} points "
                    f"(minimum: {self.min_data_points})"
                )
            
            # Prepare data
            timestamps = ts_data.index
            values = ts_data.values
            
            # Mann-Kendall trend test
            mk_result = self._mann_kendall_test(values)
            
            # Sen's slope estimator
            slope, intercept, lower_slope, upper_slope = self._sen_slope(values)
            
            # Determine trend direction and strength
            direction = self._classify_trend_direction(mk_result['z'], mk_result['p'], slope)
            strength = self._classify_trend_strength(mk_result['p'])
            
            # Seasonal analysis
            seasonal_info = self._analyze_seasonality(ts_data)
            
            # Detect change points
            change_points = self._detect_change_points(values, timestamps)
            
            # Generate forecast
            forecast, confidence_bands = self._generate_forecast(
                values, slope, intercept, seasonal_info, 30
            )
            
            # Check for trend alerts
            self._check_trend_alerts(service_id, metric_name, direction, strength, slope)
            
            # Create result
            result = TrendAnalysisResult(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                metric_name=metric_name,
                trend_direction=direction,
                trend_strength=strength,
                trend_slope=slope,
                mann_kendall_statistic=mk_result['z'],
                p_value=mk_result['p'],
                confidence_interval=(lower_slope, upper_slope),
                seasonal_component=seasonal_info['has_seasonality'],
                seasonal_period=seasonal_info.get('period_days'),
                seasonality_strength=seasonal_info.get('strength'),
                forecast_30_days=forecast,
                forecast_confidence_bands=confidence_bands,
                change_points=change_points,
                analysis_start_date=timestamps[0],
                analysis_end_date=timestamps[-1],
                data_points=len(values),
                analysis_timestamp=datetime.utcnow()
            )
            
            # Save to database
            self._save_trend_analysis(result)
            
            # Check performance
            processing_time = time.time() - start_time
            if processing_time > self.processing_target:
                logger.warning(
                    f"Trend analysis took {processing_time:.2f}s "
                    f"(target: {self.processing_target}s)"
                )
            
            return result
            
        except Exception as e:
            logger.error(f"Trend detection failed: {str(e)}")
            raise
    
    def _get_time_series_data(
        self,
        service_id: int,
        metric_name: str,
        weeks: int
    ) -> pd.Series:
        """Get real time series data from PostgreSQL"""
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
                'call_volume': 'calls_offered',
                'aht': 'average_handle_time'
            }
            
            column = metric_mapping.get(metric_name, metric_name)
            
            # Get hourly aggregated data for trend analysis
            query = text(f"""
                SELECT 
                    DATE_TRUNC('hour', interval_start_time) as hour,
                    AVG({column}) as value
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':weeks weeks'
                    AND {column} IS NOT NULL
                GROUP BY hour
                ORDER BY hour
            """)
            
            result = session.execute(
                query,
                {'service_id': service_id, 'weeks': weeks}
            )
            
            df = pd.DataFrame(result.fetchall(), columns=['timestamp', 'value'])
            if df.empty:
                raise ValueError(f"No data found for service {service_id}, metric {metric_name}")
            
            # Convert to time series
            ts = pd.Series(df['value'].values, index=pd.to_datetime(df['timestamp']))
            return ts
    
    def _mann_kendall_test(self, values: np.ndarray) -> Dict[str, float]:
        """Perform Mann-Kendall trend test"""
        n = len(values)
        s = 0
        
        # Calculate S statistic
        for i in range(n-1):
            for j in range(i+1, n):
                s += np.sign(values[j] - values[i])
        
        # Calculate variance
        var_s = n * (n - 1) * (2 * n + 5) / 18
        
        # Calculate Z statistic
        if s > 0:
            z = (s - 1) / np.sqrt(var_s)
        elif s < 0:
            z = (s + 1) / np.sqrt(var_s)
        else:
            z = 0
        
        # Calculate p-value (two-tailed)
        p_value = 2 * (1 - stats.norm.cdf(abs(z)))
        
        return {
            's': s,
            'z': z,
            'p': p_value,
            'var_s': var_s
        }
    
    def _sen_slope(self, values: np.ndarray) -> Tuple[float, float, float, float]:
        """Calculate Sen's slope estimator with confidence intervals"""
        n = len(values)
        slopes = []
        
        # Calculate all pairwise slopes
        for i in range(n-1):
            for j in range(i+1, n):
                if j - i > 0:
                    slopes.append((values[j] - values[i]) / (j - i))
        
        # Sen's slope is the median of all slopes
        slope = np.median(slopes)
        
        # Calculate intercept
        intercepts = [values[i] - slope * i for i in range(n)]
        intercept = np.median(intercepts)
        
        # Confidence intervals
        # Using normal approximation
        c_alpha = stats.norm.ppf(0.975)  # 95% confidence
        n_slopes = len(slopes)
        rank_lower = int((n_slopes - c_alpha * np.sqrt(n_slopes)) / 2)
        rank_upper = int((n_slopes + c_alpha * np.sqrt(n_slopes)) / 2)
        
        slopes_sorted = sorted(slopes)
        lower_slope = slopes_sorted[max(0, rank_lower)]
        upper_slope = slopes_sorted[min(n_slopes-1, rank_upper)]
        
        return slope, intercept, lower_slope, upper_slope
    
    def _classify_trend_direction(
        self,
        z_statistic: float,
        p_value: float,
        slope: float
    ) -> TrendDirection:
        """Classify trend direction based on test results"""
        if p_value > 0.05:  # Not statistically significant
            return TrendDirection.STABLE
        
        # Check for high variability
        if abs(z_statistic) < 2 and p_value > 0.01:
            return TrendDirection.VOLATILE
        
        # Significant trend
        if slope > 0:
            return TrendDirection.INCREASING
        elif slope < 0:
            return TrendDirection.DECREASING
        else:
            return TrendDirection.STABLE
    
    def _classify_trend_strength(self, p_value: float) -> TrendStrength:
        """Classify trend strength based on p-value"""
        if p_value < 0.001:
            return TrendStrength.VERY_STRONG
        elif p_value < 0.01:
            return TrendStrength.STRONG
        elif p_value < 0.05:
            return TrendStrength.MODERATE
        elif p_value < 0.1:
            return TrendStrength.WEAK
        else:
            return TrendStrength.NONE
    
    def _analyze_seasonality(self, ts_data: pd.Series) -> Dict[str, Any]:
        """Analyze seasonality in time series"""
        try:
            # Need at least 2 complete periods for seasonal decomposition
            if len(ts_data) < 48:  # Less than 2 days of hourly data
                return {'has_seasonality': False}
            
            # Try different seasonal periods
            periods_to_test = [
                24,    # Daily seasonality (24 hours)
                168,   # Weekly seasonality (7 days)
                720    # Monthly seasonality (30 days)
            ]
            
            best_period = None
            best_strength = 0
            
            for period in periods_to_test:
                if len(ts_data) >= 2 * period:
                    try:
                        # Perform seasonal decomposition
                        decomposition = seasonal_decompose(
                            ts_data, 
                            model='additive', 
                            period=period,
                            extrapolate_trend='freq'
                        )
                        
                        # Calculate seasonality strength
                        seasonal_var = np.var(decomposition.seasonal)
                        total_var = np.var(ts_data)
                        strength = seasonal_var / total_var if total_var > 0 else 0
                        
                        if strength > best_strength:
                            best_strength = strength
                            best_period = period
                            
                    except Exception:
                        continue
            
            if best_strength > 0.1:  # At least 10% of variance explained by seasonality
                return {
                    'has_seasonality': True,
                    'period_days': best_period / 24 if best_period else None,
                    'strength': round(best_strength, 4)
                }
            else:
                return {'has_seasonality': False}
                
        except Exception as e:
            logger.warning(f"Seasonality analysis failed: {str(e)}")
            return {'has_seasonality': False}
    
    def _detect_change_points(self, values: np.ndarray, timestamps: pd.DatetimeIndex) -> List[datetime]:
        """Detect significant change points in time series"""
        change_points = []
        
        if len(values) < 20:
            return change_points
        
        # Simple change point detection using rolling statistics
        window = min(10, len(values) // 4)
        
        for i in range(window, len(values) - window):
            before = values[i-window:i]
            after = values[i:i+window]
            
            # T-test for mean change
            t_stat, p_value = stats.ttest_ind(before, after)
            
            if p_value < 0.01:  # Significant change
                change_points.append(timestamps[i])
        
        # Filter out change points too close together
        if change_points:
            filtered = [change_points[0]]
            for cp in change_points[1:]:
                if (cp - filtered[-1]).days > 7:  # At least 7 days apart
                    filtered.append(cp)
            change_points = filtered
        
        return change_points[:5]  # Return at most 5 change points
    
    def _generate_forecast(
        self,
        values: np.ndarray,
        slope: float,
        intercept: float,
        seasonal_info: Dict[str, Any],
        days_ahead: int
    ) -> Tuple[List[float], Dict[str, List[float]]]:
        """Generate trend-based forecast with confidence bands"""
        n = len(values)
        last_value = values[-1]
        
        # Simple linear forecast based on Sen's slope
        forecast = []
        for i in range(1, days_ahead + 1):
            # Base trend
            trend_value = last_value + slope * i
            
            # Add seasonal component if present
            if seasonal_info.get('has_seasonality'):
                period = int(seasonal_info['period_days'] * 24)  # Convert to hours
                seasonal_index = (n + i) % period
                # Simple seasonal adjustment (would be more sophisticated in production)
                seasonal_factor = 1.0 + 0.1 * np.sin(2 * np.pi * seasonal_index / period)
                trend_value *= seasonal_factor
            
            forecast.append(max(0, trend_value))  # Ensure non-negative
        
        # Calculate prediction intervals
        # Using historical variance for uncertainty
        historical_std = np.std(values)
        
        confidence_bands = {
            'lower_95': [max(0, f - 1.96 * historical_std * np.sqrt(1 + i/n)) 
                         for i, f in enumerate(forecast)],
            'upper_95': [f + 1.96 * historical_std * np.sqrt(1 + i/n) 
                         for i, f in enumerate(forecast)],
            'lower_80': [max(0, f - 1.28 * historical_std * np.sqrt(1 + i/n)) 
                         for i, f in enumerate(forecast)],
            'upper_80': [f + 1.28 * historical_std * np.sqrt(1 + i/n) 
                         for i, f in enumerate(forecast)]
        }
        
        return forecast, confidence_bands
    
    def _check_trend_alerts(
        self,
        service_id: int,
        metric_name: str,
        direction: TrendDirection,
        strength: TrendStrength,
        slope: float
    ):
        """Check if trend warrants an alert"""
        alerts = []
        
        # Alert for strong negative trends in service level
        if (metric_name == 'service_level' and 
            direction == TrendDirection.DECREASING and 
            strength in [TrendStrength.STRONG, TrendStrength.VERY_STRONG]):
            alerts.append({
                'type': 'service_degradation',
                'severity': 'high',
                'description': f'Service level showing strong downward trend ({slope:.2%} per hour)',
                'action': 'Review staffing levels and recent operational changes'
            })
        
        # Alert for increasing wait times
        elif (metric_name == 'average_wait_time' and 
              direction == TrendDirection.INCREASING and 
              strength in [TrendStrength.STRONG, TrendStrength.VERY_STRONG]):
            alerts.append({
                'type': 'wait_time_increase',
                'severity': 'high',
                'description': f'Wait times increasing significantly ({slope:.1f}s per hour)',
                'action': 'Consider immediate staffing adjustments'
            })
        
        # Alert for abandonment rate trends
        elif (metric_name == 'abandonment_rate' and 
              direction == TrendDirection.INCREASING and 
              slope > 0.001):  # More than 0.1% per hour
            alerts.append({
                'type': 'abandonment_increase',
                'severity': 'medium',
                'description': f'Abandonment rate trending upward',
                'action': 'Monitor wait times and consider queue prioritization'
            })
        
        # Save alerts
        if alerts:
            with self.SessionLocal() as session:
                for alert in alerts:
                    session.execute(text("""
                        INSERT INTO trend_alerts (
                            analysis_id, service_id, metric_name,
                            alert_type, severity, description, recommended_action
                        ) VALUES (
                            gen_random_uuid(), :service_id, :metric_name,
                            :alert_type, :severity, :description, :action
                        )
                    """), {
                        'service_id': service_id,
                        'metric_name': metric_name,
                        'alert_type': alert['type'],
                        'severity': alert['severity'],
                        'description': alert['description'],
                        'action': alert['action']
                    })
                session.commit()
    
    def _save_trend_analysis(self, result: TrendAnalysisResult):
        """Save trend analysis results to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO trend_analysis_results (
                    analysis_id, service_id, metric_name,
                    trend_direction, trend_strength, trend_slope,
                    mann_kendall_statistic, p_value,
                    confidence_lower, confidence_upper,
                    seasonal_component, seasonal_period_days, seasonality_strength,
                    forecast_next_30_days, forecast_confidence_bands,
                    change_points, analysis_start_date, analysis_end_date,
                    data_points_analyzed, analysis_timestamp
                ) VALUES (
                    :analysis_id, :service_id, :metric_name,
                    :trend_direction, :trend_strength, :trend_slope,
                    :mann_kendall_statistic, :p_value,
                    :confidence_lower, :confidence_upper,
                    :seasonal_component, :seasonal_period_days, :seasonality_strength,
                    :forecast::jsonb, :confidence_bands::jsonb,
                    :change_points::jsonb, :start_date, :end_date,
                    :data_points, :timestamp
                )
            """), {
                'analysis_id': result.analysis_id,
                'service_id': result.service_id,
                'metric_name': result.metric_name,
                'trend_direction': result.trend_direction.value,
                'trend_strength': result.trend_strength.value,
                'trend_slope': result.trend_slope,
                'mann_kendall_statistic': result.mann_kendall_statistic,
                'p_value': result.p_value,
                'confidence_lower': result.confidence_interval[0],
                'confidence_upper': result.confidence_interval[1],
                'seasonal_component': result.seasonal_component,
                'seasonal_period_days': result.seasonal_period,
                'seasonality_strength': result.seasonality_strength,
                'forecast': {'values': result.forecast_30_days},
                'confidence_bands': result.forecast_confidence_bands,
                'change_points': {'dates': [cp.isoformat() for cp in result.change_points]},
                'start_date': result.analysis_start_date,
                'end_date': result.analysis_end_date,
                'data_points': result.data_points,
                'timestamp': result.analysis_timestamp
            })
            session.commit()
    
    def analyze_multiple_metrics(
        self,
        service_id: int,
        metrics: List[str],
        weeks: int = 12
    ) -> Dict[str, TrendAnalysisResult]:
        """Analyze trends for multiple metrics"""
        results = {}
        
        for metric in metrics:
            try:
                results[metric] = self.detect_trend(service_id, metric, weeks)
            except Exception as e:
                logger.error(f"Failed to analyze {metric}: {str(e)}")
                results[metric] = None
        
        return results


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        engine = TrendDetectionEngineReal()
        
        # Example: Detect trend in service level
        result = engine.detect_trend(
            service_id=1,
            metric_name='service_level',
            weeks=12
        )
        
        print(f"Trend: {result.trend_direction.value}")
        print(f"Strength: {result.trend_strength.value}")
        print(f"Slope: {result.trend_slope:.4f} per hour")
        print(f"Significant: {result.p_value < 0.05}")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")