#!/usr/bin/env python3
"""
REAL Performance Threshold Detector - Zero Mock Dependencies
Transformed from: subagents/agent-1/status_monitor.py  
Database: PostgreSQL Schema 001 integration required
Performance: <500ms BDD requirement
"""

import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from enum import Enum
import os

logger = logging.getLogger(__name__)

class BreachSeverity(Enum):
    """Severity levels for threshold breaches"""
    NORMAL = "NORMAL"
    INFO = "INFO"
    WARNING = "WARNING"
    CRITICAL = "CRITICAL"
    EMERGENCY = "EMERGENCY"

@dataclass
class RealPerformanceThreshold:
    """Real performance threshold breach detection"""
    service_id: int
    metric_name: str
    current_value: float
    threshold_value: float
    threshold_type: str  # warning, critical, emergency
    is_breached: bool
    breach_severity: BreachSeverity
    breach_duration_seconds: float
    time_until_breach: Optional[float]
    recommended_action: str
    historical_context: Dict[str, Any]

@dataclass
class RealThresholdConfig:
    """Real threshold configuration from database"""
    service_id: int
    threshold_name: str
    warning_level: float
    critical_level: float
    emergency_level: float
    auto_alert_enabled: bool

class PerformanceThresholdDetectorReal:
    """Real-time Performance Threshold Detection using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.5  # 500ms BDD requirement
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
        
        # Initialize default thresholds
        self._initialize_default_thresholds()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate contact_statistics has recent data
                recent_data = session.execute(text("""
                    SELECT COUNT(*) FROM contact_statistics 
                    WHERE interval_start_time >= NOW() - INTERVAL '2 hours'
                """)).scalar()
                
                if recent_data == 0:
                    logger.warning("No recent contact_statistics data - threshold detection may be limited")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Threshold detection ready")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _initialize_default_thresholds(self):
        """Initialize default threshold configurations if not present"""
        with self.SessionLocal() as session:
            # Create thresholds table if it doesn't exist
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS real_time_thresholds (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    threshold_name VARCHAR(100) NOT NULL,
                    warning_level DECIMAL(5,2) DEFAULT 75.0,
                    critical_level DECIMAL(5,2) DEFAULT 65.0,
                    emergency_level DECIMAL(5,2) DEFAULT 55.0,
                    auto_alert_enabled BOOLEAN DEFAULT true,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    UNIQUE(service_id, threshold_name)
                )
            """))
            
            # Insert default thresholds for service_level if not exists
            session.execute(text("""
                INSERT INTO real_time_thresholds (service_id, threshold_name, warning_level, critical_level, emergency_level)
                SELECT 1, 'service_level', 75.0, 65.0, 55.0
                WHERE NOT EXISTS (
                    SELECT 1 FROM real_time_thresholds 
                    WHERE service_id = 1 AND threshold_name = 'service_level'
                )
            """))
            
            # Default abandonment rate thresholds
            session.execute(text("""
                INSERT INTO real_time_thresholds (service_id, threshold_name, warning_level, critical_level, emergency_level)
                SELECT 1, 'abandonment_rate', 5.0, 10.0, 15.0
                WHERE NOT EXISTS (
                    SELECT 1 FROM real_time_thresholds 
                    WHERE service_id = 1 AND threshold_name = 'abandonment_rate'
                )
            """))
            
            session.commit()
            logger.info("✅ Default thresholds initialized")
    
    def detect_real_threshold_breaches(self, service_id: int, interval_minutes: int = 15) -> List[RealPerformanceThreshold]:
        """Detect real threshold breaches from actual database data"""
        start_time = time.time()
        
        breaches = []
        
        with self.SessionLocal() as session:
            # Get current performance metrics
            current_metrics = session.execute(text("""
                SELECT 
                    service_level,
                    abandonment_rate,
                    aht,
                    received_calls,
                    treated_calls,
                    interval_start_time
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':interval_minutes minutes'
                ORDER BY interval_start_time DESC
                LIMIT 1
            """), {
                'service_id': service_id,
                'interval_minutes': interval_minutes
            }).fetchone()
            
            if not current_metrics:
                logger.warning(f"No recent metrics for service {service_id}")
                return breaches
            
            # Get threshold configurations
            threshold_configs = session.execute(text("""
                SELECT 
                    threshold_name,
                    warning_level,
                    critical_level,
                    emergency_level,
                    auto_alert_enabled
                FROM real_time_thresholds
                WHERE service_id = :service_id
            """), {'service_id': service_id}).fetchall()
            
            # Check each metric against its thresholds
            for config in threshold_configs:
                metric_name = config.threshold_name
                
                # Get current value for this metric
                if metric_name == 'service_level':
                    current_value = float(current_metrics.service_level or 0)
                    metric_direction = 'below'  # Breach when below threshold
                elif metric_name == 'abandonment_rate':
                    current_value = float(current_metrics.abandonment_rate or 0)
                    metric_direction = 'above'  # Breach when above threshold
                else:
                    continue  # Skip unknown metrics
                
                # Detect breaches
                breach = self._check_metric_breach(
                    service_id, metric_name, current_value, config, metric_direction
                )
                
                if breach and breach.is_breached:
                    breaches.append(breach)
        
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Threshold Detector processing time {processing_time:.3f}s exceeds 500ms target")
        
        logger.info(f"✅ Threshold detection complete: {len(breaches)} breaches detected")
        return breaches
    
    def _check_metric_breach(self, service_id: int, metric_name: str, current_value: float, 
                           config: Any, direction: str) -> Optional[RealPerformanceThreshold]:
        """Check if a specific metric breaches its thresholds"""
        
        warning_level = float(config.warning_level)
        critical_level = float(config.critical_level)
        emergency_level = float(config.emergency_level)
        
        # Determine breach status and severity
        is_breached = False
        breach_severity = BreachSeverity.NORMAL
        threshold_value = warning_level
        threshold_type = "warning"
        
        if direction == 'below':
            # Service level type metrics (breach when below)
            if current_value <= emergency_level:
                is_breached = True
                breach_severity = BreachSeverity.EMERGENCY
                threshold_value = emergency_level
                threshold_type = "emergency"
            elif current_value <= critical_level:
                is_breached = True
                breach_severity = BreachSeverity.CRITICAL
                threshold_value = critical_level
                threshold_type = "critical"
            elif current_value <= warning_level:
                is_breached = True
                breach_severity = BreachSeverity.WARNING
                threshold_value = warning_level
                threshold_type = "warning"
        else:
            # Abandonment rate type metrics (breach when above)
            if current_value >= emergency_level:
                is_breached = True
                breach_severity = BreachSeverity.EMERGENCY
                threshold_value = emergency_level
                threshold_type = "emergency"
            elif current_value >= critical_level:
                is_breached = True
                breach_severity = BreachSeverity.CRITICAL
                threshold_value = critical_level
                threshold_type = "critical"
            elif current_value >= warning_level:
                is_breached = True
                breach_severity = BreachSeverity.WARNING
                threshold_value = warning_level
                threshold_type = "warning"
        
        # Get historical context
        historical_context = self._get_historical_context(service_id, metric_name)
        
        # Calculate breach duration (simplified)
        breach_duration = 0.0  # Would need breach history table for accurate calculation
        
        # Predict time until breach
        time_until_breach = self._predict_time_to_breach(
            service_id, metric_name, current_value, threshold_value, direction
        )
        
        # Generate recommendation
        recommendation = self._generate_recommendation(
            metric_name, current_value, breach_severity, historical_context
        )
        
        return RealPerformanceThreshold(
            service_id=service_id,
            metric_name=metric_name,
            current_value=current_value,
            threshold_value=threshold_value,
            threshold_type=threshold_type,
            is_breached=is_breached,
            breach_severity=breach_severity,
            breach_duration_seconds=breach_duration,
            time_until_breach=time_until_breach,
            recommended_action=recommendation,
            historical_context=historical_context
        )
    
    def _get_historical_context(self, service_id: int, metric_name: str) -> Dict[str, Any]:
        """Get historical context for the metric"""
        with self.SessionLocal() as session:
            if metric_name == 'service_level':
                column = 'service_level'
            elif metric_name == 'abandonment_rate':
                column = 'abandonment_rate'
            else:
                return {}
            
            historical_data = session.execute(text(f"""
                SELECT 
                    AVG({column}) as avg_value,
                    MIN({column}) as min_value,
                    MAX({column}) as max_value,
                    STDDEV({column}) as std_dev,
                    COUNT(*) as data_points
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '7 days'
                AND {column} IS NOT NULL
            """), {'service_id': service_id}).fetchone()
            
            if historical_data:
                return {
                    'avg_7_days': float(historical_data.avg_value or 0),
                    'min_7_days': float(historical_data.min_value or 0),
                    'max_7_days': float(historical_data.max_value or 0),
                    'std_dev_7_days': float(historical_data.std_dev or 0),
                    'data_points': int(historical_data.data_points or 0)
                }
            
            return {}
    
    def _predict_time_to_breach(self, service_id: int, metric_name: str, 
                              current_value: float, threshold: float, direction: str) -> Optional[float]:
        """Predict time until threshold breach based on recent trend"""
        with self.SessionLocal() as session:
            if metric_name == 'service_level':
                column = 'service_level'
            elif metric_name == 'abandonment_rate':
                column = 'abandonment_rate'
            else:
                return None
            
            # Get recent trend data (last 2 hours)
            trend_data = session.execute(text(f"""
                SELECT 
                    {column} as value,
                    EXTRACT(EPOCH FROM interval_start_time) as timestamp_epoch
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL '2 hours'
                AND {column} IS NOT NULL
                ORDER BY interval_start_time ASC
            """), {'service_id': service_id}).fetchall()
            
            if len(trend_data) < 3:
                return None
            
            # Simple linear trend calculation
            values = [float(row.value) for row in trend_data]
            timestamps = [float(row.timestamp_epoch) for row in trend_data]
            
            # Calculate slope (change per second)
            if len(values) >= 2:
                time_diff = timestamps[-1] - timestamps[0]
                value_diff = values[-1] - values[0]
                
                if time_diff > 0:
                    slope = value_diff / time_diff  # units per second
                    
                    # Predict time to breach
                    if direction == 'below' and slope < 0:
                        # Decreasing toward lower threshold
                        time_to_breach = (current_value - threshold) / abs(slope)
                        return max(0, time_to_breach)
                    elif direction == 'above' and slope > 0:
                        # Increasing toward upper threshold  
                        time_to_breach = (threshold - current_value) / slope
                        return max(0, time_to_breach)
            
            return None
    
    def _generate_recommendation(self, metric_name: str, current_value: float, 
                               severity: BreachSeverity, context: Dict[str, Any]) -> str:
        """Generate recommended action based on breach"""
        
        recommendations = {
            'service_level': {
                BreachSeverity.EMERGENCY: "IMMEDIATE ACTION: Deploy all available agents, activate overflow protocols",
                BreachSeverity.CRITICAL: "Deploy additional agents immediately, consider call routing changes",
                BreachSeverity.WARNING: "Prepare additional agents, monitor closely for next 15 minutes",
                BreachSeverity.NORMAL: "Service level within acceptable range"
            },
            'abandonment_rate': {
                BreachSeverity.EMERGENCY: "EMERGENCY: Review IVR messages, add agents, implement callback system",
                BreachSeverity.CRITICAL: "High abandonment detected - immediate staffing increase required",
                BreachSeverity.WARNING: "Monitor abandonment patterns, consider proactive messaging",
                BreachSeverity.NORMAL: "Abandonment rate acceptable"
            }
        }
        
        base_recommendation = recommendations.get(metric_name, {}).get(
            severity, "Monitor metric closely"
        )
        
        # Add context-based enhancement
        if context.get('avg_7_days'):
            avg_7_days = context['avg_7_days']
            if metric_name == 'service_level':
                if current_value < avg_7_days * 0.9:
                    base_recommendation += f" (Current {current_value:.1f}% vs 7-day avg {avg_7_days:.1f}%)"
            elif metric_name == 'abandonment_rate':
                if current_value > avg_7_days * 1.5:
                    base_recommendation += f" (Current {current_value:.1f}% vs 7-day avg {avg_7_days:.1f}%)"
        
        return base_recommendation
    
    def configure_thresholds(self, service_id: int, metric_name: str, 
                           warning: float, critical: float, emergency: float):
        """Configure thresholds for a specific metric"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO real_time_thresholds (service_id, threshold_name, warning_level, critical_level, emergency_level)
                VALUES (:service_id, :metric_name, :warning, :critical, :emergency)
                ON CONFLICT (service_id, threshold_name) 
                DO UPDATE SET 
                    warning_level = EXCLUDED.warning_level,
                    critical_level = EXCLUDED.critical_level,
                    emergency_level = EXCLUDED.emergency_level
            """), {
                'service_id': service_id,
                'metric_name': metric_name,
                'warning': warning,
                'critical': critical,
                'emergency': emergency
            })
            session.commit()
            logger.info(f"✅ Thresholds configured for {metric_name}: W:{warning} C:{critical} E:{emergency}")


# Example usage and testing
if __name__ == "__main__":
    # Test real threshold detection
    try:
        detector = PerformanceThresholdDetectorReal()
        
        # Configure thresholds
        detector.configure_thresholds(
            service_id=1, 
            metric_name='service_level',
            warning=75.0, 
            critical=65.0, 
            emergency=55.0
        )
        
        # Detect breaches
        breaches = detector.detect_real_threshold_breaches(service_id=1)
        
        print(f"Performance Threshold Detector Results:")
        print(f"Breaches Detected: {len(breaches)}")
        
        for breach in breaches:
            print(f"\nBreach: {breach.metric_name}")
            print(f"Current Value: {breach.current_value}")
            print(f"Threshold: {breach.threshold_value}")
            print(f"Severity: {breach.breach_severity.value}")
            print(f"Recommendation: {breach.recommended_action}")
            if breach.time_until_breach:
                print(f"Time to Next Level: {breach.time_until_breach:.0f}s")
        
    except Exception as e:
        print(f"❌ Real Performance Threshold Detector failed: {e}")
        print("This is expected behavior without real database connection")