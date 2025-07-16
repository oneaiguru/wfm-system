#!/usr/bin/env python3
"""
REAL Anomaly Detection Engine - Zero Mock Dependencies
Transformed from: subagents/agent-2/alert_generator.py
Database: PostgreSQL Schema 001 integration required
Performance: <200ms BDD requirement
"""

import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from enum import Enum
import uuid
import numpy as np
from scipy import stats
import os

logger = logging.getLogger(__name__)

class AnomalyType(Enum):
    """Types of anomalies detected"""
    STATISTICAL_DEVIATION = "statistical_deviation"
    TREND_ANOMALY = "trend_anomaly"
    PATTERN_BREAK = "pattern_break"
    VOLUME_SPIKE = "volume_spike"
    PERFORMANCE_DROP = "performance_drop"

class AnomalySeverity(Enum):
    """Anomaly severity levels"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

@dataclass
class RealAnomalyPattern:
    """Real anomaly pattern detected from database"""
    anomaly_id: str
    service_id: int
    timestamp: datetime
    metric_name: str
    anomaly_type: AnomalyType
    severity: AnomalySeverity
    current_value: float
    expected_value: float
    deviation_magnitude: float
    confidence_score: float
    z_score: float
    historical_context: Dict[str, Any]
    predicted_impact: str
    recommended_action: str

class AnomalyDetectionEngineReal:
    """Real-time Anomaly Detection using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.2  # 200ms BDD requirement
        self.anomaly_threshold = 2.5  # Standard deviations for anomaly detection
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
        
        # Ensure anomaly tables exist
        self._ensure_anomaly_tables()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate sufficient historical data for anomaly detection
                data_check = session.execute(text("""
                    SELECT COUNT(*) FROM contact_statistics 
                    WHERE interval_start_time >= NOW() - INTERVAL '30 days'
                """)).scalar()
                
                if data_check < 100:
                    logger.warning("Limited historical data - anomaly detection may be less accurate")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Anomaly detection ready")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_anomaly_tables(self):
        """Create anomaly-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create anomaly_patterns table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS anomaly_patterns (
                    id SERIAL PRIMARY KEY,
                    anomaly_id UUID DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(100) NOT NULL,
                    pattern_type VARCHAR(50) NOT NULL,
                    statistical_baseline JSONB NOT NULL,
                    detection_threshold DECIMAL(5,2) DEFAULT 2.5,
                    false_positive_rate DECIMAL(5,4),
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    last_trained_at TIMESTAMPTZ DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create anomaly_detections table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS anomaly_detections (
                    detection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    metric_name VARCHAR(100) NOT NULL,
                    anomaly_type VARCHAR(50) NOT NULL,
                    severity VARCHAR(20) NOT NULL,
                    current_value DECIMAL(10,4) NOT NULL,
                    expected_value DECIMAL(10,4) NOT NULL,
                    z_score DECIMAL(6,3) NOT NULL,
                    confidence_score DECIMAL(5,4) NOT NULL,
                    detected_at TIMESTAMPTZ DEFAULT NOW(),
                    acknowledged_at TIMESTAMPTZ,
                    false_positive BOOLEAN DEFAULT NULL
                )
            """))
            
            session.commit()
            logger.info("✅ Anomaly detection tables created/validated")
    
    def detect_real_anomalies(self, service_id: int, metric_name: str, 
                            analysis_window_hours: int = 4) -> List[RealAnomalyPattern]:
        """Detect real anomalies using statistical analysis of historical data"""
        start_time = time.time()
        
        anomalies = []
        
        with self.SessionLocal() as session:
            # Get current value
            current_data = session.execute(text(f"""
                SELECT 
                    {metric_name},
                    interval_start_time
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':window_hours hours'
                AND {metric_name} IS NOT NULL
                ORDER BY interval_start_time DESC
                LIMIT 1
            """), {
                'service_id': service_id,
                'window_hours': analysis_window_hours
            }).fetchone()
            
            if not current_data:
                logger.warning(f"No recent data for {metric_name} on service {service_id}")
                return anomalies
            
            current_value = float(getattr(current_data, metric_name) or 0)
            
            # Get historical baseline (last 30 days, excluding recent window)
            historical_data = session.execute(text(f"""
                SELECT {metric_name} as value
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '30 days'
                AND interval_start_time <= NOW() - INTERVAL ':window_hours hours'
                AND {metric_name} IS NOT NULL
                ORDER BY interval_start_time
            """), {
                'service_id': service_id,
                'window_hours': analysis_window_hours
            }).fetchall()
            
            if len(historical_data) < 50:
                logger.warning(f"Insufficient historical data for {metric_name}: {len(historical_data)} points")
                return anomalies
            
            # Perform statistical anomaly detection
            anomaly = self._detect_statistical_anomaly(
                service_id, metric_name, current_value, 
                [float(row.value) for row in historical_data]
            )
            
            if anomaly:
                # Save anomaly to database
                self._save_anomaly_detection(session, anomaly)
                anomalies.append(anomaly)
        
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Anomaly Detection processing time {processing_time:.3f}s exceeds 200ms target")
        
        logger.info(f"✅ Real anomaly detection: {len(anomalies)} anomalies found for {metric_name}")
        return anomalies
    
    def _detect_statistical_anomaly(self, service_id: int, metric_name: str, 
                                  current_value: float, historical_values: List[float]) -> Optional[RealAnomalyPattern]:
        """Detect statistical anomaly using robust statistical methods"""
        
        # Convert to numpy array for statistical analysis
        data = np.array(historical_values)
        
        # Remove outliers using IQR method for robust baseline
        q1, q3 = np.percentile(data, [25, 75])
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr
        cleaned_data = data[(data >= lower_bound) & (data <= upper_bound)]
        
        if len(cleaned_data) < 20:
            logger.warning(f"Insufficient clean data for {metric_name} after outlier removal")
            return None
        
        # Calculate robust baseline statistics
        baseline_mean = np.mean(cleaned_data)
        baseline_std = np.std(cleaned_data)
        baseline_median = np.median(cleaned_data)
        
        if baseline_std == 0:
            logger.warning(f"Zero standard deviation for {metric_name} - cannot detect anomalies")
            return None
        
        # Calculate z-score
        z_score = abs((current_value - baseline_mean) / baseline_std)
        
        # Check if anomalous
        if z_score < self.anomaly_threshold:
            return None
        
        # Determine anomaly type and severity
        anomaly_type = self._classify_anomaly_type(current_value, baseline_mean, baseline_median, metric_name)
        severity = self._determine_anomaly_severity(z_score)
        
        # Calculate confidence score
        confidence_score = min(0.99, z_score / 5.0)  # Cap at 99%
        
        # Generate historical context
        historical_context = {
            'baseline_mean': baseline_mean,
            'baseline_std': baseline_std,
            'baseline_median': baseline_median,
            'data_points_used': len(cleaned_data),
            'total_data_points': len(historical_values),
            'data_quality': len(cleaned_data) / len(historical_values),
            'percentile_95': np.percentile(cleaned_data, 95),
            'percentile_5': np.percentile(cleaned_data, 5)
        }
        
        # Generate predictions and recommendations
        predicted_impact = self._predict_anomaly_impact(metric_name, current_value, baseline_mean, z_score)
        recommended_action = self._generate_anomaly_recommendation(anomaly_type, severity, metric_name)
        
        return RealAnomalyPattern(
            anomaly_id=str(uuid.uuid4()),
            service_id=service_id,
            timestamp=datetime.now(),
            metric_name=metric_name,
            anomaly_type=anomaly_type,
            severity=severity,
            current_value=current_value,
            expected_value=baseline_mean,
            deviation_magnitude=abs(current_value - baseline_mean),
            confidence_score=confidence_score,
            z_score=z_score,
            historical_context=historical_context,
            predicted_impact=predicted_impact,
            recommended_action=recommended_action
        )
    
    def _classify_anomaly_type(self, current_value: float, baseline_mean: float, 
                             baseline_median: float, metric_name: str) -> AnomalyType:
        """Classify the type of anomaly detected"""
        
        deviation_from_mean = current_value - baseline_mean
        deviation_magnitude = abs(deviation_from_mean) / baseline_mean if baseline_mean > 0 else 0
        
        # Volume spike detection
        if metric_name in ['received_calls', 'treated_calls'] and deviation_from_mean > 0:
            if deviation_magnitude > 0.5:  # 50% increase
                return AnomalyType.VOLUME_SPIKE
        
        # Performance drop detection
        if metric_name in ['service_level'] and deviation_from_mean < 0:
            if deviation_magnitude > 0.2:  # 20% decrease
                return AnomalyType.PERFORMANCE_DROP
        
        # High abandonment
        if metric_name in ['abandonment_rate'] and deviation_from_mean > 0:
            if deviation_magnitude > 0.5:  # 50% increase in abandonment
                return AnomalyType.PERFORMANCE_DROP
        
        # Default to statistical deviation
        return AnomalyType.STATISTICAL_DEVIATION
    
    def _determine_anomaly_severity(self, z_score: float) -> AnomalySeverity:
        """Determine anomaly severity based on z-score"""
        if z_score >= 4.0:
            return AnomalySeverity.CRITICAL
        elif z_score >= 3.5:
            return AnomalySeverity.HIGH
        elif z_score >= 2.5:
            return AnomalySeverity.MEDIUM
        else:
            return AnomalySeverity.LOW
    
    def _predict_anomaly_impact(self, metric_name: str, current_value: float, 
                               baseline_mean: float, z_score: float) -> str:
        """Predict potential impact of the anomaly"""
        
        deviation_pct = abs((current_value - baseline_mean) / baseline_mean * 100) if baseline_mean > 0 else 0
        
        impact_templates = {
            'service_level': {
                'high': f"Critical SLA impact: {deviation_pct:.1f}% below normal performance",
                'medium': f"Moderate SLA impact: {deviation_pct:.1f}% performance deviation",
                'low': f"Minor SLA impact: {deviation_pct:.1f}% performance variance"
            },
            'received_calls': {
                'high': f"Severe capacity impact: {deviation_pct:.1f}% volume anomaly may overwhelm system",
                'medium': f"Moderate capacity impact: {deviation_pct:.1f}% volume deviation from normal",
                'low': f"Minor capacity impact: {deviation_pct:.1f}% volume variance"
            },
            'abandonment_rate': {
                'high': f"Critical customer impact: {deviation_pct:.1f}% increase in abandonment",
                'medium': f"Moderate customer impact: {deviation_pct:.1f}% abandonment increase",
                'low': f"Minor customer impact: {deviation_pct:.1f}% abandonment variance"
            }
        }
        
        # Determine impact level
        if z_score >= 3.5:
            impact_level = 'high'
        elif z_score >= 2.8:
            impact_level = 'medium'
        else:
            impact_level = 'low'
        
        return impact_templates.get(metric_name, {}).get(
            impact_level, 
            f"Operational impact: {deviation_pct:.1f}% deviation from baseline"
        )
    
    def _generate_anomaly_recommendation(self, anomaly_type: AnomalyType, 
                                       severity: AnomalySeverity, metric_name: str) -> str:
        """Generate recommended action for the anomaly"""
        
        recommendations = {
            AnomalyType.VOLUME_SPIKE: {
                AnomalySeverity.CRITICAL: "EMERGENCY: Activate overflow protocols, deploy all available agents",
                AnomalySeverity.HIGH: "Urgent: Add emergency staffing, prepare escalation procedures",
                AnomalySeverity.MEDIUM: "Alert: Monitor capacity, prepare additional resources",
                AnomalySeverity.LOW: "Monitor: Track volume patterns, prepare contingency"
            },
            AnomalyType.PERFORMANCE_DROP: {
                AnomalySeverity.CRITICAL: "CRISIS: Immediate intervention required, investigate system issues",
                AnomalySeverity.HIGH: "Urgent: Review agent availability, check system performance",
                AnomalySeverity.MEDIUM: "Alert: Analyze performance factors, adjust operations",
                AnomalySeverity.LOW: "Monitor: Track performance trends, review metrics"
            },
            AnomalyType.STATISTICAL_DEVIATION: {
                AnomalySeverity.CRITICAL: "Investigate immediately: Severe deviation requires urgent analysis",
                AnomalySeverity.HIGH: "Review urgently: Significant pattern change detected",
                AnomalySeverity.MEDIUM: "Analyze: Notable deviation from normal patterns",
                AnomalySeverity.LOW: "Monitor: Minor variance from baseline patterns"
            }
        }
        
        return recommendations.get(anomaly_type, {}).get(
            severity, 
            f"Review {metric_name} patterns and investigate cause"
        )
    
    def _save_anomaly_detection(self, session, anomaly: RealAnomalyPattern):
        """Save anomaly detection to database"""
        session.execute(text("""
            INSERT INTO anomaly_detections (
                detection_id, service_id, metric_name, anomaly_type, severity,
                current_value, expected_value, z_score, confidence_score
            ) VALUES (
                :detection_id, :service_id, :metric_name, :anomaly_type, :severity,
                :current_value, :expected_value, :z_score, :confidence_score
            )
        """), {
            'detection_id': anomaly.anomaly_id,
            'service_id': anomaly.service_id,
            'metric_name': anomaly.metric_name,
            'anomaly_type': anomaly.anomaly_type.value,
            'severity': anomaly.severity.value,
            'current_value': anomaly.current_value,
            'expected_value': anomaly.expected_value,
            'z_score': anomaly.z_score,
            'confidence_score': anomaly.confidence_score
        })
        session.commit()
        logger.info(f"✅ Anomaly {anomaly.anomaly_id} saved to database")
    
    def get_recent_anomalies(self, service_id: Optional[int] = None, hours: int = 24) -> List[Dict[str, Any]]:
        """Get recent anomaly detections"""
        with self.SessionLocal() as session:
            query = """
                SELECT 
                    detection_id,
                    service_id,
                    metric_name,
                    anomaly_type,
                    severity,
                    current_value,
                    expected_value,
                    z_score,
                    confidence_score,
                    detected_at
                FROM anomaly_detections
                WHERE detected_at >= NOW() - INTERVAL ':hours hours'
            """
            
            params = {'hours': hours}
            if service_id:
                query += " AND service_id = :service_id"
                params['service_id'] = service_id
            
            query += " ORDER BY detected_at DESC"
            
            anomalies = session.execute(text(query), params).fetchall()
            
            return [
                {
                    'detection_id': anomaly.detection_id,
                    'service_id': anomaly.service_id,
                    'metric_name': anomaly.metric_name,
                    'anomaly_type': anomaly.anomaly_type,
                    'severity': anomaly.severity,
                    'current_value': float(anomaly.current_value),
                    'expected_value': float(anomaly.expected_value),
                    'z_score': float(anomaly.z_score),
                    'confidence_score': float(anomaly.confidence_score),
                    'detected_at': anomaly.detected_at
                }
                for anomaly in anomalies
            ]


# Example usage and testing
if __name__ == "__main__":
    # Test real anomaly detection
    try:
        detector = AnomalyDetectionEngineReal()
        
        # Detect anomalies for service level metric
        anomalies = detector.detect_real_anomalies(service_id=1, metric_name='service_level')
        
        print(f"Anomaly Detection Engine Results:")
        print(f"Anomalies Detected: {len(anomalies)}")
        
        for anomaly in anomalies:
            print(f"\nAnomaly: {anomaly.metric_name}")
            print(f"Type: {anomaly.anomaly_type.value}")
            print(f"Severity: {anomaly.severity.value}")
            print(f"Current Value: {anomaly.current_value:.2f}")
            print(f"Expected Value: {anomaly.expected_value:.2f}")
            print(f"Z-Score: {anomaly.z_score:.2f}")
            print(f"Confidence: {anomaly.confidence_score:.2%}")
            print(f"Impact: {anomaly.predicted_impact}")
            print(f"Recommendation: {anomaly.recommended_action}")
        
        # Get recent anomalies
        recent = detector.get_recent_anomalies(service_id=1, hours=24)
        print(f"\nRecent Anomalies (24h): {len(recent)}")
        
    except Exception as e:
        print(f"❌ Real Anomaly Detection Engine failed: {e}")
        print("This is expected behavior without real database connection")