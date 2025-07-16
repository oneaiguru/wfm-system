#!/usr/bin/env python3
"""
Performance Trend Predictor Real - Zero Mock Dependencies
Transformed from: subagents/agent-8/prediction_engine.py (lines 929-1177)
Database: PostgreSQL Schema 001 + auto-created trend tables
Performance: <3s trend analysis, real statistical tests (Mann-Kendall)
"""

import time
import logging
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Statistical libraries for trend analysis
try:
    from scipy import stats
    from scipy.stats import kendalltau, theilslopes, pearsonr
    from sklearn.linear_model import LinearRegression, TheilSenRegressor
    from sklearn.preprocessing import StandardScaler
    from sklearn.metrics import r2_score, mean_absolute_error
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class TrendDirection(Enum):
    """Trend direction classifications"""
    STRONGLY_INCREASING = "strongly_increasing"
    MODERATELY_INCREASING = "moderately_increasing"
    STABLE = "stable"
    MODERATELY_DECREASING = "moderately_decreasing"
    STRONGLY_DECREASING = "strongly_decreasing"

class TrendSignificance(Enum):
    """Statistical significance levels"""
    HIGHLY_SIGNIFICANT = "highly_significant"  # p < 0.01
    SIGNIFICANT = "significant"                # p < 0.05
    MARGINALLY_SIGNIFICANT = "marginally_significant"  # p < 0.10
    NOT_SIGNIFICANT = "not_significant"        # p >= 0.10

class TrendImpact(Enum):
    """Trend impact on operations"""
    CRITICAL = "critical"     # Immediate intervention required
    HIGH = "high"            # Action needed soon
    MEDIUM = "medium"        # Monitor and plan
    LOW = "low"             # Informational

@dataclass
class RealPerformanceTrend:
    """Real performance trend prediction from statistical analysis"""
    trend_id: str
    prediction_timestamp: datetime
    service_id: int
    metric_name: str
    
    # Trend analysis results
    trend_direction: TrendDirection
    trend_strength: float  # 0-1 scale
    statistical_significance: TrendSignificance
    p_value: float
    confidence_interval: Tuple[float, float]
    
    # Regression analysis
    slope: float
    intercept: float
    r_squared: float
    mean_absolute_error: float
    
    # Future predictions
    predicted_values: List[Tuple[datetime, float, float, float]]  # (time, value, lower_ci, upper_ci)
    prediction_horizon_hours: int
    
    # Impact assessment
    impact_level: TrendImpact
    business_impact: Dict[str, float]
    intervention_threshold: float
    time_to_threshold: Optional[float]  # hours until critical threshold
    
    # Recommendations
    recommended_interventions: List[str]
    monitoring_frequency: str
    escalation_triggers: List[str]
    
    # Model quality
    model_accuracy: float
    data_points_used: int
    analysis_method: str
    data_source: str = "REAL_DATABASE"

class PerformanceTrendPredictorReal:
    """Real-time Performance Trend Predictor using PostgreSQL Schema 001 + Statistical Analysis"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for trend analysis
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # ML models for trend prediction
        self.linear_model = LinearRegression()
        self.robust_model = TheilSenRegressor(random_state=42)
        self.scaler = StandardScaler()
        
        # Trend analysis cache
        self.trend_history = {}  # service_id -> historical trends
        self.performance_thresholds = {}  # service_id -> metric -> thresholds
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_trend_tables()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate Schema 001 tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) FROM information_schema.tables 
                    WHERE table_name IN ('contact_statistics', 'services')
                """)).scalar()
                
                if tables_check < 2:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_trend_tables(self):
        """Create trend-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create performance_trends table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS performance_trends (
                    trend_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(50) NOT NULL,
                    analysis_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    trend_direction VARCHAR(50) NOT NULL,
                    trend_strength DECIMAL(3,2),
                    statistical_significance VARCHAR(50),
                    p_value DECIMAL(10,8),
                    slope DECIMAL(15,8),
                    r_squared DECIMAL(5,4),
                    prediction_horizon_hours INTEGER,
                    impact_level VARCHAR(20),
                    time_to_threshold DECIMAL(10,2),
                    model_accuracy DECIMAL(3,2),
                    data_points_used INTEGER,
                    analysis_method VARCHAR(50)
                )
            """))
            
            # Create trend_predictions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS trend_predictions (
                    prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    trend_id UUID REFERENCES performance_trends(trend_id),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(50) NOT NULL,
                    prediction_timestamp TIMESTAMPTZ NOT NULL,
                    predicted_value DECIMAL(10,4),
                    confidence_lower DECIMAL(10,4),
                    confidence_upper DECIMAL(10,4),
                    actual_value DECIMAL(10,4), -- filled later for validation
                    prediction_error DECIMAL(10,4) -- calculated when actual known
                )
            """))
            
            # Create performance_thresholds table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS performance_thresholds (
                    threshold_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(50) NOT NULL,
                    warning_threshold DECIMAL(10,4),
                    critical_threshold DECIMAL(10,4),
                    target_value DECIMAL(10,4),
                    threshold_type VARCHAR(20) DEFAULT 'lower_is_better', -- lower_is_better, higher_is_better
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true,
                    UNIQUE(service_id, metric_name)
                )
            """))
            
            # Create trend_interventions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS trend_interventions (
                    intervention_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    trend_id UUID REFERENCES performance_trends(trend_id),
                    service_id INTEGER NOT NULL,
                    intervention_type VARCHAR(100) NOT NULL,
                    intervention_description TEXT,
                    priority_level VARCHAR(20),
                    estimated_effort_hours DECIMAL(5,2),
                    estimated_impact DECIMAL(3,2),
                    implementation_timeline VARCHAR(50),
                    success_metrics JSONB
                )
            """))
            
            session.commit()
            logger.info("✅ Performance trend tables created/validated")
    
    def predict_performance_trends_real(self, 
                                       service_id: int,
                                       metrics: List[str],
                                       prediction_horizon_hours: int = 24,
                                       analysis_period_days: int = 14) -> List[RealPerformanceTrend]:
        """Predict performance trends using real statistical analysis on actual data"""
        start_time = time.time()
        
        try:
            # Update performance thresholds if needed
            self._update_performance_thresholds(service_id)
            
            # Get historical performance data
            historical_data = self._get_historical_performance_data(service_id, analysis_period_days)
            
            if len(historical_data) < 20:
                raise ValueError(f"Insufficient data for trend analysis: {len(historical_data)} points")
            
            trends = []
            
            # Analyze trends for each requested metric
            for metric_name in metrics:
                if metric_name in historical_data.columns:
                    trend = self._analyze_metric_trend_real(service_id, metric_name, historical_data, prediction_horizon_hours)
                    if trend:
                        trends.append(trend)
                        
                        # Save trend to database
                        self._save_performance_trend(trend)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            logger.info(f"✅ Analyzed performance trends for {len(metrics)} metrics, service {service_id}")
            return trends
            
        except Exception as e:
            logger.error(f"❌ Real performance trend prediction failed: {e}")
            raise ValueError(f"Performance trend prediction failed for service {service_id}: {e}")
    
    def _update_performance_thresholds(self, service_id: int):
        """Update performance thresholds from service configuration"""
        with self.SessionLocal() as session:
            # Get service configuration and historical performance
            service_config = session.execute(text("""
                SELECT target_service_level, target_answer_time
                FROM services
                WHERE id = :service_id
            """), {'service_id': service_id}).fetchone()
            
            # Calculate thresholds based on historical performance
            historical_stats = session.execute(text("""
                SELECT 
                    AVG(service_level) as avg_service_level,
                    STDDEV(service_level) as std_service_level,
                    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY service_level) as q25_service_level,
                    AVG(abandonment_rate) as avg_abandonment_rate,
                    STDDEV(abandonment_rate) as std_abandonment_rate,
                    AVG(aht) as avg_aht,
                    STDDEV(aht) as std_aht
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '30 days'
                AND service_level IS NOT NULL
            """), {'service_id': service_id}).fetchone()
            
            if not historical_stats:
                return
            
            # Define thresholds for key metrics
            thresholds = {
                'service_level': {
                    'target': service_config.target_service_level if service_config else 80.0,
                    'warning': max(60.0, (historical_stats.avg_service_level or 80) - (historical_stats.std_service_level or 10)),
                    'critical': 50.0,
                    'type': 'higher_is_better'
                },
                'abandonment_rate': {
                    'target': 5.0,
                    'warning': min(15.0, (historical_stats.avg_abandonment_rate or 5) + (historical_stats.std_abandonment_rate or 3)),
                    'critical': 20.0,
                    'type': 'lower_is_better'
                },
                'aht': {
                    'target': historical_stats.avg_aht or 300,
                    'warning': (historical_stats.avg_aht or 300) + (historical_stats.std_aht or 60),
                    'critical': (historical_stats.avg_aht or 300) + 2 * (historical_stats.std_aht or 60),
                    'type': 'lower_is_better'
                }
            }
            
            # Store thresholds
            if service_id not in self.performance_thresholds:
                self.performance_thresholds[service_id] = {}
            self.performance_thresholds[service_id] = thresholds
            
            # Save to database
            for metric_name, threshold_data in thresholds.items():
                session.execute(text("""
                    INSERT INTO performance_thresholds (
                        service_id, metric_name, warning_threshold, critical_threshold,
                        target_value, threshold_type
                    ) VALUES (
                        :service_id, :metric, :warning, :critical, :target, :type
                    )
                    ON CONFLICT (service_id, metric_name)
                    DO UPDATE SET
                        warning_threshold = EXCLUDED.warning_threshold,
                        critical_threshold = EXCLUDED.critical_threshold,
                        target_value = EXCLUDED.target_value,
                        threshold_type = EXCLUDED.threshold_type
                """), {
                    'service_id': service_id,
                    'metric': metric_name,
                    'warning': threshold_data['warning'],
                    'critical': threshold_data['critical'],
                    'target': threshold_data['target'],
                    'type': threshold_data['type']
                })
            
            session.commit()
            logger.info(f"✅ Updated performance thresholds for service {service_id}")
    
    def _get_historical_performance_data(self, service_id: int, days: int) -> pd.DataFrame:
        """Get historical performance data for trend analysis"""
        with self.SessionLocal() as session:
            historical_data = session.execute(text("""
                SELECT 
                    interval_start_time,
                    service_level,
                    abandonment_rate,
                    aht,
                    received_calls,
                    treated_calls,
                    (treated_calls::float / NULLIF(received_calls, 0) * 100) as answer_rate
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':days days'
                AND service_level IS NOT NULL
                ORDER BY interval_start_time ASC
            """), {'service_id': service_id, 'days': days}).fetchall()
            
            if not historical_data:
                return pd.DataFrame()
            
            # Convert to DataFrame
            df = pd.DataFrame([
                {
                    'timestamp': row.interval_start_time,
                    'service_level': float(row.service_level) if row.service_level else None,
                    'abandonment_rate': float(row.abandonment_rate) if row.abandonment_rate else None,
                    'aht': float(row.aht) if row.aht else None,
                    'received_calls': int(row.received_calls) if row.received_calls else 0,
                    'treated_calls': int(row.treated_calls) if row.treated_calls else 0,
                    'answer_rate': float(row.answer_rate) if row.answer_rate else None
                }
                for row in historical_data
            ])
            
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df = df.sort_values('timestamp')
            
            # Create time-based features
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            df['days_from_start'] = (df['timestamp'] - df['timestamp'].min()).dt.total_seconds() / (24 * 3600)
            
            return df
    
    def _analyze_metric_trend_real(self, 
                                  service_id: int,
                                  metric_name: str,
                                  historical_data: pd.DataFrame,
                                  prediction_horizon_hours: int) -> Optional[RealPerformanceTrend]:
        """Analyze trend for single metric using real statistical methods"""
        
        try:
            # Extract metric values (remove NaN)
            metric_data = historical_data[['timestamp', 'days_from_start', metric_name]].dropna()
            
            if len(metric_data) < 10:
                logger.warning(f"Insufficient data for {metric_name}: {len(metric_data)} points")
                return None
            
            y_values = metric_data[metric_name].values
            x_values = metric_data['days_from_start'].values
            timestamps = metric_data['timestamp'].values
            
            # 1. Mann-Kendall trend test for statistical significance
            tau, p_value = kendalltau(x_values, y_values)
            
            # 2. Theil-Sen slope estimation (robust trend)
            theil_slope, theil_intercept, _, _ = theilslopes(y_values, x_values)
            
            # 3. Linear regression for comparison
            X = x_values.reshape(-1, 1)
            self.linear_model.fit(X, y_values)
            linear_slope = self.linear_model.coef_[0]
            linear_intercept = self.linear_model.intercept_
            
            # 4. Model quality metrics
            y_pred_linear = self.linear_model.predict(X)
            r_squared = r2_score(y_values, y_pred_linear)
            mae = mean_absolute_error(y_values, y_pred_linear)
            
            # 5. Robust regression for better trend estimation
            self.robust_model.fit(X, y_values)
            robust_slope = self.robust_model.coef_[0]
            
            # Determine trend direction and strength
            trend_direction = self._classify_trend_direction(tau, theil_slope, p_value)
            trend_strength = min(abs(tau), 1.0)  # Kendall's tau as strength measure
            statistical_significance = self._classify_significance(p_value)
            
            # Calculate confidence intervals for slope
            n = len(y_values)
            slope_se = np.sqrt(np.sum((y_values - y_pred_linear)**2) / (n - 2)) / np.sqrt(np.sum((x_values - x_values.mean())**2))
            t_critical = stats.t.ppf(0.975, n - 2)  # 95% confidence
            ci_lower = linear_slope - t_critical * slope_se
            ci_upper = linear_slope + t_critical * slope_se
            
            # Generate future predictions
            predicted_values = self._generate_trend_predictions(
                timestamps[-1], linear_slope, linear_intercept, 
                slope_se, prediction_horizon_hours, y_values
            )
            
            # Assess business impact
            impact_assessment = self._assess_business_impact(
                service_id, metric_name, trend_direction, theil_slope, y_values[-1]
            )
            
            # Generate interventions
            interventions = self._generate_trend_interventions(
                metric_name, trend_direction, trend_strength, impact_assessment
            )
            
            # Calculate time to critical threshold
            time_to_threshold = self._calculate_time_to_threshold(
                service_id, metric_name, y_values[-1], theil_slope
            )
            
            trend = RealPerformanceTrend(
                trend_id=f"PT_{service_id}_{metric_name}_{int(time.time())}",
                prediction_timestamp=datetime.now(),
                service_id=service_id,
                metric_name=metric_name,
                
                trend_direction=trend_direction,
                trend_strength=trend_strength,
                statistical_significance=statistical_significance,
                p_value=p_value,
                confidence_interval=(ci_lower, ci_upper),
                
                slope=float(theil_slope),
                intercept=float(theil_intercept),
                r_squared=float(r_squared),
                mean_absolute_error=float(mae),
                
                predicted_values=predicted_values,
                prediction_horizon_hours=prediction_horizon_hours,
                
                impact_level=impact_assessment['impact_level'],
                business_impact=impact_assessment['business_impact'],
                intervention_threshold=impact_assessment['intervention_threshold'],
                time_to_threshold=time_to_threshold,
                
                recommended_interventions=interventions['interventions'],
                monitoring_frequency=interventions['monitoring_frequency'],
                escalation_triggers=interventions['escalation_triggers'],
                
                model_accuracy=max(0, float(r_squared)),
                data_points_used=len(metric_data),
                analysis_method="mann_kendall_theil_sen"
            )
            
            return trend
            
        except Exception as e:
            logger.error(f"Trend analysis failed for {metric_name}: {e}")
            return None
    
    def _classify_trend_direction(self, tau: float, slope: float, p_value: float) -> TrendDirection:
        """Classify trend direction based on statistical tests"""
        
        if p_value >= 0.05:  # Not statistically significant
            return TrendDirection.STABLE
        
        # Use Kendall's tau for classification
        if tau >= 0.4:
            return TrendDirection.STRONGLY_INCREASING
        elif tau >= 0.2:
            return TrendDirection.MODERATELY_INCREASING
        elif tau <= -0.4:
            return TrendDirection.STRONGLY_DECREASING
        elif tau <= -0.2:
            return TrendDirection.MODERATELY_DECREASING
        else:
            return TrendDirection.STABLE
    
    def _classify_significance(self, p_value: float) -> TrendSignificance:
        """Classify statistical significance level"""
        
        if p_value < 0.01:
            return TrendSignificance.HIGHLY_SIGNIFICANT
        elif p_value < 0.05:
            return TrendSignificance.SIGNIFICANT
        elif p_value < 0.10:
            return TrendSignificance.MARGINALLY_SIGNIFICANT
        else:
            return TrendSignificance.NOT_SIGNIFICANT
    
    def _generate_trend_predictions(self, 
                                   last_timestamp: np.datetime64,
                                   slope: float,
                                   intercept: float,
                                   slope_se: float,
                                   hours: int,
                                   historical_values: np.ndarray) -> List[Tuple[datetime, float, float, float]]:
        """Generate future trend predictions with confidence intervals"""
        
        predictions = []
        last_time = pd.to_datetime(last_timestamp)
        last_x = 0  # Relative to last data point
        
        # Calculate historical variance for uncertainty estimation
        historical_std = np.std(historical_values)
        
        for hour in range(1, hours + 1):
            future_time = last_time + timedelta(hours=hour)
            future_x = hour / 24  # Convert hours to days
            
            # Linear prediction
            predicted_value = slope * future_x + historical_values[-1]  # Relative to last value
            
            # Confidence interval considering slope uncertainty and prediction uncertainty
            slope_uncertainty = slope_se * future_x
            prediction_uncertainty = historical_std * np.sqrt(1 + future_x**2 / len(historical_values))
            
            total_uncertainty = np.sqrt(slope_uncertainty**2 + prediction_uncertainty**2)
            
            # 95% confidence interval
            ci_margin = 1.96 * total_uncertainty
            lower_ci = predicted_value - ci_margin
            upper_ci = predicted_value + ci_margin
            
            predictions.append((future_time, float(predicted_value), float(lower_ci), float(upper_ci)))
        
        return predictions
    
    def _assess_business_impact(self, 
                               service_id: int,
                               metric_name: str,
                               trend_direction: TrendDirection,
                               slope: float,
                               current_value: float) -> Dict[str, Any]:
        """Assess business impact of trend"""
        
        thresholds = self.performance_thresholds.get(service_id, {}).get(metric_name, {})
        
        # Calculate impact based on metric type and trend
        impact_level = TrendImpact.LOW
        business_impact = {}
        intervention_threshold = thresholds.get('warning', current_value * 0.9)
        
        # Assess impact based on metric and trend direction
        if metric_name == 'service_level':
            if trend_direction in [TrendDirection.STRONGLY_DECREASING, TrendDirection.MODERATELY_DECREASING]:
                # Declining service level is concerning
                daily_decline = abs(slope)  # Daily change
                if daily_decline > 2.0:  # >2% per day decline
                    impact_level = TrendImpact.CRITICAL
                elif daily_decline > 1.0:  # >1% per day decline
                    impact_level = TrendImpact.HIGH
                else:
                    impact_level = TrendImpact.MEDIUM
                
                business_impact = {
                    'sla_risk': min(daily_decline / 5.0, 1.0),
                    'customer_satisfaction_impact': daily_decline / 10.0,
                    'potential_penalty_risk': 0.8 if current_value < 70 else 0.3
                }
        
        elif metric_name == 'abandonment_rate':
            if trend_direction in [TrendDirection.STRONGLY_INCREASING, TrendDirection.MODERATELY_INCREASING]:
                # Increasing abandonment is concerning
                daily_increase = abs(slope)
                if daily_increase > 1.0:  # >1% per day increase
                    impact_level = TrendImpact.CRITICAL
                elif daily_increase > 0.5:  # >0.5% per day increase
                    impact_level = TrendImpact.HIGH
                else:
                    impact_level = TrendImpact.MEDIUM
                
                business_impact = {
                    'customer_loss_risk': min(daily_increase / 2.0, 1.0),
                    'revenue_impact': daily_increase / 5.0,
                    'reputation_risk': 0.7 if current_value > 15 else 0.3
                }
        
        elif metric_name == 'aht':
            if trend_direction in [TrendDirection.STRONGLY_INCREASING, TrendDirection.MODERATELY_INCREASING]:
                # Increasing handle time reduces efficiency
                daily_increase = abs(slope)
                if daily_increase > 30:  # >30 seconds per day increase
                    impact_level = TrendImpact.HIGH
                elif daily_increase > 15:  # >15 seconds per day increase
                    impact_level = TrendImpact.MEDIUM
                
                business_impact = {
                    'efficiency_impact': min(daily_increase / 60.0, 1.0),
                    'capacity_impact': daily_increase / 120.0,
                    'cost_impact': daily_increase / 300.0
                }
        
        return {
            'impact_level': impact_level,
            'business_impact': business_impact,
            'intervention_threshold': intervention_threshold
        }
    
    def _generate_trend_interventions(self, 
                                    metric_name: str,
                                    trend_direction: TrendDirection,
                                    trend_strength: float,
                                    impact_assessment: Dict[str, Any]) -> Dict[str, Any]:
        """Generate intervention recommendations based on trend analysis"""
        
        interventions = []
        monitoring_frequency = "daily"
        escalation_triggers = []
        
        impact_level = impact_assessment['impact_level']
        
        # Common interventions based on trend strength
        if trend_strength > 0.6:  # Strong trend
            monitoring_frequency = "hourly"
            escalation_triggers.append("trend_acceleration")
        elif trend_strength > 0.3:  # Moderate trend
            monitoring_frequency = "every_4_hours"
        
        # Metric-specific interventions
        if metric_name == 'service_level':
            if trend_direction in [TrendDirection.STRONGLY_DECREASING, TrendDirection.MODERATELY_DECREASING]:
                interventions.extend([
                    "Increase staffing levels during peak periods",
                    "Review call routing optimization",
                    "Analyze call complexity trends",
                    "Implement overflow protocols"
                ])
                
                if impact_level == TrendImpact.CRITICAL:
                    interventions.extend([
                        "Activate emergency staffing protocols",
                        "Implement immediate callback options",
                        "Review system performance for bottlenecks"
                    ])
                    escalation_triggers.extend(["sla_breach_imminent", "service_level_below_50"])
        
        elif metric_name == 'abandonment_rate':
            if trend_direction in [TrendDirection.STRONGLY_INCREASING, TrendDirection.MODERATELY_INCREASING]:
                interventions.extend([
                    "Reduce average wait time through staffing",
                    "Implement queue callback options",
                    "Optimize IVR to reduce call volume",
                    "Review agent efficiency and training"
                ])
                
                if impact_level == TrendImpact.CRITICAL:
                    interventions.extend([
                        "Emergency capacity activation",
                        "Implement immediate overflow routing",
                        "Deploy additional self-service options"
                    ])
                    escalation_triggers.extend(["abandonment_above_20", "trend_acceleration"])
        
        elif metric_name == 'aht':
            if trend_direction in [TrendDirection.STRONGLY_INCREASING, TrendDirection.MODERATELY_INCREASING]:
                interventions.extend([
                    "Review call complexity and provide additional training",
                    "Optimize knowledge base and tools",
                    "Analyze common call types for process improvement",
                    "Consider skill-based routing optimization"
                ])
                
                if impact_level == TrendImpact.HIGH:
                    interventions.extend([
                        "Immediate agent coaching on efficient call handling",
                        "Review and streamline call procedures",
                        "Deploy additional self-service for simple inquiries"
                    ])
                    escalation_triggers.extend(["aht_above_600_seconds", "efficiency_degradation"])
        
        return {
            'interventions': interventions,
            'monitoring_frequency': monitoring_frequency,
            'escalation_triggers': escalation_triggers
        }
    
    def _calculate_time_to_threshold(self, 
                                   service_id: int,
                                   metric_name: str,
                                   current_value: float,
                                   slope: float) -> Optional[float]:
        """Calculate time until critical threshold is reached"""
        
        thresholds = self.performance_thresholds.get(service_id, {}).get(metric_name, {})
        critical_threshold = thresholds.get('critical')
        threshold_type = thresholds.get('type', 'lower_is_better')
        
        if not critical_threshold or abs(slope) < 1e-6:
            return None
        
        # Calculate time to reach critical threshold
        if threshold_type == 'lower_is_better':
            # For metrics where lower is better (abandonment_rate, aht)
            if slope > 0:  # Increasing trend (bad)
                days_to_threshold = (critical_threshold - current_value) / slope
                return days_to_threshold * 24  # Convert to hours
        else:
            # For metrics where higher is better (service_level)
            if slope < 0:  # Decreasing trend (bad)
                days_to_threshold = (current_value - critical_threshold) / abs(slope)
                return days_to_threshold * 24  # Convert to hours
        
        return None
    
    def _save_performance_trend(self, trend: RealPerformanceTrend):
        """Save performance trend analysis to database"""
        with self.SessionLocal() as session:
            # Save main trend record
            session.execute(text("""
                INSERT INTO performance_trends (
                    service_id, metric_name, trend_direction, trend_strength,
                    statistical_significance, p_value, slope, r_squared,
                    prediction_horizon_hours, impact_level, time_to_threshold,
                    model_accuracy, data_points_used, analysis_method
                ) VALUES (
                    :service_id, :metric_name, :trend_direction, :trend_strength,
                    :significance, :p_value, :slope, :r_squared,
                    :horizon_hours, :impact_level, :time_to_threshold,
                    :model_accuracy, :data_points, :analysis_method
                )
            """), {
                'service_id': trend.service_id,
                'metric_name': trend.metric_name,
                'trend_direction': trend.trend_direction.value,
                'trend_strength': trend.trend_strength,
                'significance': trend.statistical_significance.value,
                'p_value': trend.p_value,
                'slope': trend.slope,
                'r_squared': trend.r_squared,
                'horizon_hours': trend.prediction_horizon_hours,
                'impact_level': trend.impact_level.value,
                'time_to_threshold': trend.time_to_threshold,
                'model_accuracy': trend.model_accuracy,
                'data_points': trend.data_points_used,
                'analysis_method': trend.analysis_method
            })
            
            # Save trend predictions
            for pred_time, pred_value, lower_ci, upper_ci in trend.predicted_values:
                session.execute(text("""
                    INSERT INTO trend_predictions (
                        service_id, metric_name, prediction_timestamp,
                        predicted_value, confidence_lower, confidence_upper
                    ) VALUES (
                        :service_id, :metric_name, :pred_time,
                        :pred_value, :lower_ci, :upper_ci
                    )
                """), {
                    'service_id': trend.service_id,
                    'metric_name': trend.metric_name,
                    'pred_time': pred_time,
                    'pred_value': pred_value,
                    'lower_ci': lower_ci,
                    'upper_ci': upper_ci
                })
            
            session.commit()

if __name__ == "__main__":
    # Test the real performance trend predictor
    predictor = PerformanceTrendPredictorReal()
    
    # Test performance trend analysis
    service_id = 1
    metrics = ['service_level', 'abandonment_rate', 'aht']
    
    try:
        trends = predictor.predict_performance_trends_real(
            service_id=service_id,
            metrics=metrics,
            prediction_horizon_hours=24,
            analysis_period_days=14
        )
        
        print(f"Performance trend analysis for service {service_id}:")
        
        for trend in trends:
            print(f"\n  Metric: {trend.metric_name}")
            print(f"  Trend: {trend.trend_direction.value} (strength: {trend.trend_strength:.2f})")
            print(f"  Significance: {trend.statistical_significance.value} (p-value: {trend.p_value:.4f})")
            print(f"  Impact: {trend.impact_level.value}")
            print(f"  R²: {trend.r_squared:.3f}, MAE: {trend.mean_absolute_error:.2f}")
            print(f"  Predictions: {len(trend.predicted_values)} hours ahead")
            print(f"  Interventions: {len(trend.recommended_interventions)}")
            
            if trend.time_to_threshold:
                print(f"  Time to critical threshold: {trend.time_to_threshold:.1f} hours")
        
    except Exception as e:
        print(f"Performance trend analysis failed: {e}")
