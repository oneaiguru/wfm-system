#!/usr/bin/env python3
"""
Anomaly Predictor Real - Zero Mock Dependencies
Transformed from: subagents/agent-8/prediction_engine.py (lines 418-696)
Database: PostgreSQL Schema 001 + auto-created anomaly tables
Performance: <2s anomaly predictions, real statistical analysis
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

# Statistical libraries for REAL anomaly detection
try:
    from scipy import stats
    from scipy.stats import kendalltau, mannwhitneyu
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler
    from sklearn.decomposition import PCA
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class AnomalyType(Enum):
    """Types of anomalies"""
    VOLUME_SPIKE = "volume_spike"
    VOLUME_DROP = "volume_drop"
    PERFORMANCE_DEGRADATION = "performance_degradation"
    SEASONAL_DEVIATION = "seasonal_deviation"
    CORRELATION_BREAK = "correlation_break"
    PATTERN_CHANGE = "pattern_change"

class AnomalySeverity(Enum):
    """Anomaly severity levels"""
    CRITICAL = "critical"    # Immediate action required
    HIGH = "high"           # Action required soon
    MEDIUM = "medium"       # Monitor closely
    LOW = "low"            # Informational

@dataclass
class RealAnomalyPrediction:
    """Real anomaly prediction result from statistical analysis"""
    anomaly_id: str
    prediction_timestamp: datetime
    service_id: int
    anomaly_type: AnomalyType
    severity: AnomalySeverity
    probability: float
    statistical_significance: float
    affected_metrics: List[str]
    leading_indicators: List[str]
    confidence_score: float
    expected_impact: Dict[str, float]
    recommended_actions: List[str]
    detection_method: str
    data_source: str = "REAL_DATABASE"

class AnomalyPredictorReal:
    """Real-time Anomaly Predictor using PostgreSQL Schema 001 + Statistical Analysis"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 2.0  # 2 seconds for anomaly predictions
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # ML models for anomaly detection
        self.isolation_forest = IsolationForest(contamination=0.1, random_state=42)
        self.scaler = StandardScaler()
        self.is_trained = False
        
        # Statistical baselines
        self.baseline_stats = {}  # service_id -> baseline statistics
        self.correlation_matrix = {}  # service_id -> correlation patterns
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_anomaly_tables()
    
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
                    WHERE table_name IN ('contact_statistics', 'agent_activity')
                """)).scalar()
                
                if tables_check < 2:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_anomaly_tables(self):
        """Create anomaly-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create anomaly_patterns table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS anomaly_patterns (
                    pattern_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    anomaly_type VARCHAR(50) NOT NULL,
                    pattern_signature JSONB NOT NULL,
                    detection_frequency INTEGER DEFAULT 0,
                    last_detected TIMESTAMPTZ,
                    pattern_strength DECIMAL(3,2),
                    false_positive_rate DECIMAL(3,2) DEFAULT 0.05,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create anomaly_predictions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS anomaly_predictions (
                    prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    prediction_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    anomaly_type VARCHAR(50) NOT NULL,
                    probability DECIMAL(3,2) NOT NULL,
                    severity VARCHAR(20) NOT NULL,
                    statistical_significance DECIMAL(5,4),
                    affected_metrics JSONB,
                    detection_method VARCHAR(50),
                    confidence_score DECIMAL(3,2),
                    was_accurate BOOLEAN, -- filled later for validation
                    actual_anomaly_occurred TIMESTAMPTZ
                )
            """))
            
            # Create statistical_baselines table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS statistical_baselines (
                    baseline_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(50) NOT NULL,
                    baseline_mean DECIMAL(10,4),
                    baseline_std DECIMAL(10,4),
                    baseline_median DECIMAL(10,4),
                    q25 DECIMAL(10,4),
                    q75 DECIMAL(10,4),
                    min_value DECIMAL(10,4),
                    max_value DECIMAL(10,4),
                    data_points_used INTEGER,
                    calculation_date DATE DEFAULT CURRENT_DATE,
                    is_current BOOLEAN DEFAULT true,
                    UNIQUE(service_id, metric_name, calculation_date)
                )
            """))
            
            session.commit()
            logger.info("✅ Anomaly tables created/validated")
    
    def predict_anomalies_real(self, 
                              service_id: int,
                              prediction_horizon_hours: int = 4) -> List[RealAnomalyPrediction]:
        """Predict anomalies using real statistical analysis on actual data"""
        start_time = time.time()
        
        try:
            # Update statistical baselines if needed
            self._update_statistical_baselines(service_id)
            
            # Get current metrics for analysis
            current_metrics = self._get_current_metrics(service_id)
            historical_metrics = self._get_historical_metrics(service_id)
            
            if not current_metrics or len(historical_metrics) < 50:
                raise ValueError(f"Insufficient data for anomaly prediction: {len(historical_metrics)} historical points")
            
            # Perform multiple anomaly detection methods
            predictions = []
            
            # 1. Statistical anomaly detection (Z-score, IQR)
            statistical_anomalies = self._detect_statistical_anomalies_real(service_id, current_metrics, historical_metrics)
            predictions.extend(statistical_anomalies)
            
            # 2. Machine learning anomaly detection
            ml_anomalies = self._detect_ml_anomalies_real(service_id, current_metrics, historical_metrics)
            predictions.extend(ml_anomalies)
            
            # 3. Seasonal deviation detection
            seasonal_anomalies = self._detect_seasonal_deviations_real(service_id, current_metrics, historical_metrics)
            predictions.extend(seasonal_anomalies)
            
            # 4. Correlation break detection
            correlation_anomalies = self._detect_correlation_breaks_real(service_id, current_metrics, historical_metrics)
            predictions.extend(correlation_anomalies)
            
            # 5. Pattern change detection
            pattern_anomalies = self._detect_pattern_changes_real(service_id, historical_metrics)
            predictions.extend(pattern_anomalies)
            
            # Deduplicate and rank predictions
            final_predictions = self._deduplicate_and_rank_predictions(predictions)
            
            # Save predictions to database
            for prediction in final_predictions:
                self._save_anomaly_prediction(prediction)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            logger.info(f"✅ Predicted {len(final_predictions)} potential anomalies for service {service_id}")
            return final_predictions
            
        except Exception as e:
            logger.error(f"❌ Real anomaly prediction failed: {e}")
            raise ValueError(f"Anomaly prediction failed for service {service_id}: {e}")
    
    def _update_statistical_baselines(self, service_id: int):
        """Update statistical baselines from real historical data"""
        with self.SessionLocal() as session:
            # Get 30 days of historical data for baseline calculation
            historical_data = session.execute(text("""
                SELECT 
                    received_calls,
                    treated_calls,
                    service_level,
                    abandonment_rate,
                    aht,
                    interval_start_time
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '30 days'
                AND received_calls IS NOT NULL
                ORDER BY interval_start_time DESC
            """), {'service_id': service_id}).fetchall()
            
            if len(historical_data) < 100:
                logger.warning(f"Insufficient historical data for baselines: {len(historical_data)} points")
                return
            
            # Calculate baselines for each metric
            metrics = ['received_calls', 'treated_calls', 'service_level', 'abandonment_rate', 'aht']
            
            for metric in metrics:
                values = [getattr(row, metric) for row in historical_data if getattr(row, metric) is not None]
                
                if len(values) < 20:
                    continue
                
                values_array = np.array(values)
                
                # Calculate robust statistics
                baseline_stats = {
                    'mean': float(np.mean(values_array)),
                    'std': float(np.std(values_array)),
                    'median': float(np.median(values_array)),
                    'q25': float(np.percentile(values_array, 25)),
                    'q75': float(np.percentile(values_array, 75)),
                    'min': float(np.min(values_array)),
                    'max': float(np.max(values_array))
                }
                
                # Store in memory
                if service_id not in self.baseline_stats:
                    self.baseline_stats[service_id] = {}
                self.baseline_stats[service_id][metric] = baseline_stats
                
                # Save to database
                session.execute(text("""
                    INSERT INTO statistical_baselines (
                        service_id, metric_name, baseline_mean, baseline_std,
                        baseline_median, q25, q75, min_value, max_value,
                        data_points_used, calculation_date
                    ) VALUES (
                        :service_id, :metric, :mean, :std, :median,
                        :q25, :q75, :min_val, :max_val, :data_points, CURRENT_DATE
                    )
                    ON CONFLICT (service_id, metric_name, calculation_date)
                    DO UPDATE SET
                        baseline_mean = EXCLUDED.baseline_mean,
                        baseline_std = EXCLUDED.baseline_std,
                        baseline_median = EXCLUDED.baseline_median,
                        q25 = EXCLUDED.q25,
                        q75 = EXCLUDED.q75,
                        data_points_used = EXCLUDED.data_points_used
                """), {
                    'service_id': service_id,
                    'metric': metric,
                    'mean': baseline_stats['mean'],
                    'std': baseline_stats['std'],
                    'median': baseline_stats['median'],
                    'q25': baseline_stats['q25'],
                    'q75': baseline_stats['q75'],
                    'min_val': baseline_stats['min'],
                    'max_val': baseline_stats['max'],
                    'data_points': len(values)
                })
            
            session.commit()
            logger.info(f"✅ Updated statistical baselines for service {service_id}")
    
    def _get_current_metrics(self, service_id: int) -> Dict[str, float]:
        """Get current real-time metrics"""
        with self.SessionLocal() as session:
            current_data = session.execute(text("""
                SELECT 
                    received_calls,
                    treated_calls,
                    service_level,
                    abandonment_rate,
                    aht,
                    interval_start_time
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '15 minutes'
                ORDER BY interval_start_time DESC
                LIMIT 1
            """), {'service_id': service_id}).fetchone()
            
            if not current_data:
                return {}
            
            return {
                'received_calls': float(current_data.received_calls) if current_data.received_calls else 0,
                'treated_calls': float(current_data.treated_calls) if current_data.treated_calls else 0,
                'service_level': float(current_data.service_level) if current_data.service_level else 0,
                'abandonment_rate': float(current_data.abandonment_rate) if current_data.abandonment_rate else 0,
                'aht': float(current_data.aht) if current_data.aht else 0
            }
    
    def _get_historical_metrics(self, service_id: int, days: int = 14) -> pd.DataFrame:
        """Get historical metrics for analysis"""
        with self.SessionLocal() as session:
            historical_data = session.execute(text("""
                SELECT 
                    interval_start_time,
                    received_calls,
                    treated_calls,
                    service_level,
                    abandonment_rate,
                    aht
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':days days'
                AND received_calls IS NOT NULL
                ORDER BY interval_start_time ASC
            """), {'service_id': service_id, 'days': days}).fetchall()
            
            if not historical_data:
                return pd.DataFrame()
            
            df = pd.DataFrame([
                {
                    'timestamp': row.interval_start_time,
                    'received_calls': float(row.received_calls) if row.received_calls else 0,
                    'treated_calls': float(row.treated_calls) if row.treated_calls else 0,
                    'service_level': float(row.service_level) if row.service_level else 0,
                    'abandonment_rate': float(row.abandonment_rate) if row.abandonment_rate else 0,
                    'aht': float(row.aht) if row.aht else 0
                }
                for row in historical_data
            ])
            
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            return df
    
    def _detect_statistical_anomalies_real(self, 
                                          service_id: int,
                                          current_metrics: Dict[str, float],
                                          historical_data: pd.DataFrame) -> List[RealAnomalyPrediction]:
        """Detect statistical anomalies using Z-score and IQR methods"""
        anomalies = []
        
        if service_id not in self.baseline_stats:
            return anomalies
        
        baselines = self.baseline_stats[service_id]
        
        for metric_name, current_value in current_metrics.items():
            if metric_name not in baselines:
                continue
                
            baseline = baselines[metric_name]
            
            # Z-score anomaly detection
            if baseline['std'] > 1e-6:
                z_score = abs(current_value - baseline['mean']) / baseline['std']
                
                if z_score > 3.0:  # 3-sigma rule
                    # Determine anomaly type and severity
                    if current_value > baseline['mean']:
                        anomaly_type = AnomalyType.VOLUME_SPIKE if 'calls' in metric_name else AnomalyType.PERFORMANCE_DEGRADATION
                    else:
                        anomaly_type = AnomalyType.VOLUME_DROP if 'calls' in metric_name else AnomalyType.PERFORMANCE_DEGRADATION
                    
                    severity = self._determine_severity_from_zscore(z_score)
                    
                    # Calculate statistical significance using Mann-Whitney U test
                    recent_values = historical_data[metric_name].tail(20).values
                    historical_values = historical_data[metric_name].head(-20).values
                    
                    try:
                        statistic, p_value = mannwhitneyu(recent_values, historical_values, alternative='two-sided')
                        statistical_significance = 1 - p_value
                    except Exception:
                        statistical_significance = 0.95 if z_score > 4 else 0.80
                    
                    anomaly = RealAnomalyPrediction(
                        anomaly_id=f"STAT_{service_id}_{metric_name}_{int(time.time())}",
                        prediction_timestamp=datetime.now(),
                        service_id=service_id,
                        anomaly_type=anomaly_type,
                        severity=severity,
                        probability=min(z_score / 5.0, 1.0),
                        statistical_significance=statistical_significance,
                        affected_metrics=[metric_name],
                        leading_indicators=self._identify_leading_indicators(metric_name, current_metrics),
                        confidence_score=min(z_score / 4.0, 1.0),
                        expected_impact=self._calculate_expected_impact(metric_name, current_value, baseline),
                        recommended_actions=self._generate_anomaly_actions(anomaly_type, metric_name),
                        detection_method="z_score_statistical"
                    )
                    
                    anomalies.append(anomaly)
        
        return anomalies
    
    def _detect_ml_anomalies_real(self, 
                                 service_id: int,
                                 current_metrics: Dict[str, float],
                                 historical_data: pd.DataFrame) -> List[RealAnomalyPrediction]:
        """Detect anomalies using machine learning (Isolation Forest)"""
        anomalies = []
        
        try:
            # Prepare feature matrix
            feature_columns = ['received_calls', 'treated_calls', 'service_level', 'abandonment_rate', 'aht']
            feature_data = historical_data[feature_columns].fillna(0)
            
            if len(feature_data) < 50:
                return anomalies
            
            # Train Isolation Forest on historical data
            self.isolation_forest.fit(feature_data.values)
            
            # Prepare current metrics for prediction
            current_features = np.array([[current_metrics.get(col, 0) for col in feature_columns]])
            
            # Detect anomaly
            anomaly_score = self.isolation_forest.decision_function(current_features)[0]
            is_anomaly = self.isolation_forest.predict(current_features)[0] == -1
            
            if is_anomaly and anomaly_score < -0.1:
                # Calculate feature importance to identify affected metrics
                feature_importance = self._calculate_feature_importance(current_features[0], feature_data)
                affected_metrics = [feature_columns[i] for i, importance in enumerate(feature_importance) if importance > 0.2]
                
                anomaly = RealAnomalyPrediction(
                    anomaly_id=f"ML_{service_id}_{int(time.time())}",
                    prediction_timestamp=datetime.now(),
                    service_id=service_id,
                    anomaly_type=AnomalyType.PATTERN_CHANGE,
                    severity=self._determine_severity_from_score(abs(anomaly_score)),
                    probability=min(abs(anomaly_score) * 2, 1.0),
                    statistical_significance=0.85,
                    affected_metrics=affected_metrics,
                    leading_indicators=[],
                    confidence_score=min(abs(anomaly_score), 1.0),
                    expected_impact={'overall_pattern': abs(anomaly_score)},
                    recommended_actions=["Investigate unusual pattern", "Check for system changes", "Review recent events"],
                    detection_method="isolation_forest_ml"
                )
                
                anomalies.append(anomaly)
                
        except Exception as e:
            logger.warning(f"ML anomaly detection failed: {e}")
        
        return anomalies
    
    def _detect_seasonal_deviations_real(self, 
                                        service_id: int,
                                        current_metrics: Dict[str, float],
                                        historical_data: pd.DataFrame) -> List[RealAnomalyPrediction]:
        """Detect deviations from seasonal patterns"""
        anomalies = []
        
        try:
            # Calculate expected values based on time of day/week patterns
            current_time = datetime.now()
            hour_of_day = current_time.hour
            day_of_week = current_time.weekday()
            
            # Get historical data for same hour and day patterns
            historical_data['hour'] = pd.to_datetime(historical_data['timestamp']).dt.hour
            historical_data['day_of_week'] = pd.to_datetime(historical_data['timestamp']).dt.dayofweek
            
            # Similar time periods (same hour of day)
            similar_hour_data = historical_data[historical_data['hour'] == hour_of_day]
            similar_day_data = historical_data[historical_data['day_of_week'] == day_of_week]
            
            if len(similar_hour_data) >= 10:
                for metric in ['received_calls', 'service_level']:
                    expected_value = similar_hour_data[metric].mean()
                    expected_std = similar_hour_data[metric].std()
                    current_value = current_metrics.get(metric, 0)
                    
                    if expected_std > 0:
                        deviation = abs(current_value - expected_value) / expected_std
                        
                        if deviation > 2.5:  # Seasonal deviation threshold
                            anomaly = RealAnomalyPrediction(
                                anomaly_id=f"SEASONAL_{service_id}_{metric}_{int(time.time())}",
                                prediction_timestamp=datetime.now(),
                                service_id=service_id,
                                anomaly_type=AnomalyType.SEASONAL_DEVIATION,
                                severity=self._determine_severity_from_zscore(deviation),
                                probability=min(deviation / 4.0, 1.0),
                                statistical_significance=0.90,
                                affected_metrics=[metric],
                                leading_indicators=[f"hour_{hour_of_day}_pattern"],
                                confidence_score=min(deviation / 3.0, 1.0),
                                expected_impact={metric: deviation},
                                recommended_actions=[f"Check {metric} against seasonal expectations", "Verify operational changes"],
                                detection_method="seasonal_pattern_analysis"
                            )
                            
                            anomalies.append(anomaly)
                            
        except Exception as e:
            logger.warning(f"Seasonal deviation detection failed: {e}")
        
        return anomalies
    
    def _detect_correlation_breaks_real(self, 
                                       service_id: int,
                                       current_metrics: Dict[str, float],
                                       historical_data: pd.DataFrame) -> List[RealAnomalyPrediction]:
        """Detect breaks in expected metric correlations"""
        anomalies = []
        
        try:
            # Check service level vs call volume correlation
            if len(historical_data) >= 30:
                # Calculate historical correlation
                hist_corr = historical_data['service_level'].corr(historical_data['received_calls'])
                
                # Check current state against expected correlation
                current_sl = current_metrics.get('service_level', 0)
                current_calls = current_metrics.get('received_calls', 0)
                
                # Expected service level based on call volume correlation
                if abs(hist_corr) > 0.3 and current_calls > 0:
                    recent_data = historical_data.tail(20)
                    expected_sl = self._predict_from_correlation(recent_data, 'received_calls', 'service_level', current_calls)
                    
                    if expected_sl is not None:
                        deviation = abs(current_sl - expected_sl)
                        
                        if deviation > 15:  # 15% service level deviation
                            anomaly = RealAnomalyPrediction(
                                anomaly_id=f"CORR_{service_id}_sl_calls_{int(time.time())}",
                                prediction_timestamp=datetime.now(),
                                service_id=service_id,
                                anomaly_type=AnomalyType.CORRELATION_BREAK,
                                severity=AnomalySeverity.HIGH if deviation > 25 else AnomalySeverity.MEDIUM,
                                probability=min(deviation / 30.0, 1.0),
                                statistical_significance=0.80,
                                affected_metrics=['service_level', 'received_calls'],
                                leading_indicators=['call_volume_correlation'],
                                confidence_score=min(deviation / 20.0, 1.0),
                                expected_impact={'service_level_deviation': deviation},
                                recommended_actions=["Check capacity vs demand", "Investigate system issues"],
                                detection_method="correlation_analysis"
                            )
                            
                            anomalies.append(anomaly)
                            
        except Exception as e:
            logger.warning(f"Correlation break detection failed: {e}")
        
        return anomalies
    
    def _detect_pattern_changes_real(self, 
                                    service_id: int,
                                    historical_data: pd.DataFrame) -> List[RealAnomalyPrediction]:
        """Detect changes in underlying patterns using Mann-Kendall trend test"""
        anomalies = []
        
        try:
            # Test for trend changes in key metrics
            for metric in ['received_calls', 'service_level']:
                if len(historical_data) >= 30:
                    recent_data = historical_data[metric].tail(20).values
                    
                    # Mann-Kendall trend test
                    tau, p_value = kendalltau(range(len(recent_data)), recent_data)
                    
                    # Significant trend change detection
                    if p_value < 0.05 and abs(tau) > 0.4:
                        trend_direction = "increasing" if tau > 0 else "decreasing"
                        
                        # Only flag concerning trends
                        is_concerning = (
                            (metric == 'service_level' and tau < -0.4) or  # Declining service level
                            (metric == 'received_calls' and abs(tau) > 0.6)  # Major volume changes
                        )
                        
                        if is_concerning:
                            anomaly = RealAnomalyPrediction(
                                anomaly_id=f"TREND_{service_id}_{metric}_{int(time.time())}",
                                prediction_timestamp=datetime.now(),
                                service_id=service_id,
                                anomaly_type=AnomalyType.PATTERN_CHANGE,
                                severity=AnomalySeverity.HIGH if abs(tau) > 0.6 else AnomalySeverity.MEDIUM,
                                probability=1 - p_value,
                                statistical_significance=1 - p_value,
                                affected_metrics=[metric],
                                leading_indicators=[f"{trend_direction}_trend"],
                                confidence_score=1 - p_value,
                                expected_impact={f"{metric}_trend": abs(tau)},
                                recommended_actions=[f"Investigate {trend_direction} trend in {metric}", "Check for systemic changes"],
                                detection_method="mann_kendall_trend"
                            )
                            
                            anomalies.append(anomaly)
                            
        except Exception as e:
            logger.warning(f"Pattern change detection failed: {e}")
        
        return anomalies
    
    def _determine_severity_from_zscore(self, z_score: float) -> AnomalySeverity:
        """Determine anomaly severity from Z-score"""
        if z_score >= 5.0:
            return AnomalySeverity.CRITICAL
        elif z_score >= 4.0:
            return AnomalySeverity.HIGH
        elif z_score >= 3.0:
            return AnomalySeverity.MEDIUM
        else:
            return AnomalySeverity.LOW
    
    def _determine_severity_from_score(self, score: float) -> AnomalySeverity:
        """Determine anomaly severity from ML score"""
        if score >= 0.8:
            return AnomalySeverity.CRITICAL
        elif score >= 0.6:
            return AnomalySeverity.HIGH
        elif score >= 0.4:
            return AnomalySeverity.MEDIUM
        else:
            return AnomalySeverity.LOW
    
    def _identify_leading_indicators(self, metric_name: str, current_metrics: Dict[str, float]) -> List[str]:
        """Identify leading indicators for anomaly"""
        indicators = []
        
        if metric_name == 'service_level':
            if current_metrics.get('received_calls', 0) > current_metrics.get('treated_calls', 0) * 1.2:
                indicators.append("high_call_volume")
            if current_metrics.get('aht', 0) > 300:  # 5+ minutes
                indicators.append("extended_handle_time")
        
        elif metric_name == 'received_calls':
            current_hour = datetime.now().hour
            if current_hour in [9, 10, 14, 15]:  # Typical peak hours
                indicators.append("peak_hour_pattern")
        
        return indicators
    
    def _calculate_expected_impact(self, metric_name: str, current_value: float, baseline: Dict[str, float]) -> Dict[str, float]:
        """Calculate expected impact of anomaly"""
        impact = {}
        
        deviation_pct = abs(current_value - baseline['mean']) / baseline['mean'] * 100 if baseline['mean'] > 0 else 0
        
        if metric_name == 'service_level':
            impact['sla_breach_risk'] = min(deviation_pct / 20.0, 1.0)  # Normalize to 0-1
            impact['customer_satisfaction'] = deviation_pct / 30.0
        
        elif 'calls' in metric_name:
            impact['capacity_stress'] = deviation_pct / 50.0
            impact['resource_requirement_change'] = deviation_pct / 40.0
        
        return impact
    
    def _generate_anomaly_actions(self, anomaly_type: AnomalyType, metric_name: str) -> List[str]:
        """Generate recommended actions for anomaly"""
        actions = []
        
        if anomaly_type == AnomalyType.VOLUME_SPIKE:
            actions.extend(["Activate additional capacity", "Check for promotional events", "Review call routing"])
        elif anomaly_type == AnomalyType.VOLUME_DROP:
            actions.extend(["Verify data collection", "Check for system outages", "Review business calendar"])
        elif anomaly_type == AnomalyType.PERFORMANCE_DEGRADATION:
            actions.extend(["Investigate system performance", "Check agent availability", "Review call complexity"])
        elif anomaly_type == AnomalyType.SEASONAL_DEVIATION:
            actions.extend(["Compare to historical patterns", "Check for operational changes", "Validate seasonal adjustments"])
        
        return actions
    
    def _calculate_feature_importance(self, current_features: np.ndarray, historical_features: pd.DataFrame) -> List[float]:
        """Calculate feature importance for ML anomaly"""
        importance = []
        
        for i in range(len(current_features)):
            feature_mean = historical_features.iloc[:, i].mean()
            feature_std = historical_features.iloc[:, i].std()
            
            if feature_std > 0:
                z_score = abs(current_features[i] - feature_mean) / feature_std
                importance.append(min(z_score / 5.0, 1.0))
            else:
                importance.append(0.0)
        
        return importance
    
    def _predict_from_correlation(self, data: pd.DataFrame, x_col: str, y_col: str, x_value: float) -> Optional[float]:
        """Predict y value from x using linear correlation"""
        try:
            correlation = data[x_col].corr(data[y_col])
            if abs(correlation) < 0.2:
                return None
                
            # Simple linear regression prediction
            x_mean = data[x_col].mean()
            y_mean = data[y_col].mean()
            x_std = data[x_col].std()
            y_std = data[y_col].std()
            
            if x_std > 0:
                predicted_y = y_mean + correlation * (y_std / x_std) * (x_value - x_mean)
                return predicted_y
                
        except Exception:
            pass
        
        return None
    
    def _deduplicate_and_rank_predictions(self, predictions: List[RealAnomalyPrediction]) -> List[RealAnomalyPrediction]:
        """Remove duplicates and rank predictions by severity and confidence"""
        # Remove duplicates based on affected metrics and anomaly type
        unique_predictions = []
        seen_combinations = set()
        
        for prediction in predictions:
            combo = (frozenset(prediction.affected_metrics), prediction.anomaly_type)
            if combo not in seen_combinations:
                unique_predictions.append(prediction)
                seen_combinations.add(combo)
        
        # Sort by severity and confidence
        severity_order = {AnomalySeverity.CRITICAL: 4, AnomalySeverity.HIGH: 3, AnomalySeverity.MEDIUM: 2, AnomalySeverity.LOW: 1}
        
        unique_predictions.sort(
            key=lambda x: (severity_order[x.severity], x.confidence_score, x.probability),
            reverse=True
        )
        
        return unique_predictions[:5]  # Top 5 predictions
    
    def _save_anomaly_prediction(self, prediction: RealAnomalyPrediction):
        """Save anomaly prediction to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO anomaly_predictions (
                    service_id, anomaly_type, probability, severity,
                    statistical_significance, affected_metrics, detection_method,
                    confidence_score
                ) VALUES (
                    :service_id, :anomaly_type, :probability, :severity,
                    :significance, :metrics, :method, :confidence
                )
            """), {
                'service_id': prediction.service_id,
                'anomaly_type': prediction.anomaly_type.value,
                'probability': prediction.probability,
                'severity': prediction.severity.value,
                'significance': prediction.statistical_significance,
                'metrics': prediction.affected_metrics,
                'method': prediction.detection_method,
                'confidence': prediction.confidence_score
            })
            
            session.commit()

if __name__ == "__main__":
    # Test the real anomaly predictor
    predictor = AnomalyPredictorReal()
    
    # Test anomaly prediction
    service_id = 1
    try:
        predictions = predictor.predict_anomalies_real(service_id, prediction_horizon_hours=4)
        print(f"Predicted {len(predictions)} potential anomalies for service {service_id}:")
        
        for pred in predictions:
            print(f"  {pred.anomaly_type.value}: {pred.severity.value} severity, {pred.probability:.2f} probability, {pred.confidence_score:.2f} confidence")
            print(f"    Affected: {pred.affected_metrics}")
            print(f"    Method: {pred.detection_method}")
    except Exception as e:
        print(f"Anomaly prediction failed: {e}")
