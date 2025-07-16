#!/usr/bin/env python3
"""
REAL Threshold Breach Alerter - Zero Mock Dependencies
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
import os

logger = logging.getLogger(__name__)

class AlertSeverity(Enum):
    """Alert severity levels"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

class AlertType(Enum):
    """Types of alerts"""
    SLA_BREACH = "sla_breach"
    THRESHOLD_VIOLATION = "threshold_violation"
    ABANDONMENT_HIGH = "abandonment_high"
    UTILIZATION_HIGH = "utilization_high"

@dataclass
class RealAlert:
    """Real alert from database breach detection"""
    alert_id: str
    timestamp: datetime
    service_id: int
    alert_type: AlertType
    severity: AlertSeverity
    title: str
    description: str
    metric_name: str
    current_value: float
    threshold_value: float
    affected_entities: List[str]
    recommended_action: str
    auto_resolve_possible: bool
    ttl_seconds: int

class ThresholdBreachAlerterReal:
    """Real-time Threshold Breach Detection using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.2  # 200ms BDD requirement
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
        
        # Ensure alert tables exist
        self._ensure_alert_tables()
    
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
                    WHERE table_name IN ('contact_statistics', 'real_time_thresholds')
                """)).scalar()
                
                if tables_check < 1:
                    raise ConnectionError("Required Schema 001 tables missing for alert generation")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Alert system ready")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_alert_tables(self):
        """Create alert-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create alert_history table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS alert_history (
                    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    alert_type VARCHAR(50) NOT NULL,
                    severity VARCHAR(20) NOT NULL,
                    message TEXT NOT NULL,
                    metric_name VARCHAR(100),
                    current_value DECIMAL(10,4),
                    threshold_value DECIMAL(10,4),
                    data_snapshot JSONB,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    acknowledged_at TIMESTAMPTZ,
                    acknowledged_by INTEGER,
                    resolved_at TIMESTAMPTZ,
                    resolution_notes TEXT
                )
            """))
            
            # Create escalation_rules table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS escalation_rules (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    alert_type VARCHAR(50) NOT NULL,
                    severity VARCHAR(20) NOT NULL,
                    escalation_level INTEGER NOT NULL,
                    delay_minutes INTEGER DEFAULT 15,
                    target_role VARCHAR(50),
                    target_user_id INTEGER,
                    notification_channels TEXT[] DEFAULT ARRAY['email'],
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            session.commit()
            logger.info("✅ Alert tables created/validated")
    
    def detect_real_threshold_breaches(self, service_id: int, interval_minutes: int = 15) -> List[RealAlert]:
        """Detect real threshold breaches from actual database data"""
        start_time = time.time()
        
        alerts = []
        
        with self.SessionLocal() as session:
            # Get current performance metrics
            current_metrics = session.execute(text("""
                SELECT 
                    cs.service_id,
                    cs.service_level,
                    cs.abandonment_rate,
                    cs.aht,
                    cs.received_calls,
                    cs.treated_calls,
                    cs.interval_start_time,
                    s.name as service_name,
                    s.target_service_level
                FROM contact_statistics cs
                JOIN services s ON s.id = cs.service_id
                WHERE cs.service_id = :service_id
                AND cs.interval_start_time >= NOW() - INTERVAL ':interval_minutes minutes'
                ORDER BY cs.interval_start_time DESC
                LIMIT 1
            """), {
                'service_id': service_id,
                'interval_minutes': interval_minutes
            }).fetchone()
            
            if not current_metrics:
                logger.warning(f"No recent metrics for service {service_id}")
                return alerts
            
            # Get threshold configurations
            thresholds = session.execute(text("""
                SELECT 
                    threshold_name,
                    warning_level,
                    critical_level,
                    emergency_level
                FROM real_time_thresholds
                WHERE service_id = :service_id
            """), {'service_id': service_id}).fetchall()
            
            # Check service level breach
            if current_metrics.service_level is not None:
                sl_alert = self._check_service_level_breach(
                    service_id, float(current_metrics.service_level), 
                    float(current_metrics.target_service_level or 80.0),
                    thresholds, current_metrics
                )
                if sl_alert:
                    alerts.append(sl_alert)
            
            # Check abandonment rate breach
            if current_metrics.abandonment_rate is not None:
                abandon_alert = self._check_abandonment_breach(
                    service_id, float(current_metrics.abandonment_rate),
                    thresholds, current_metrics
                )
                if abandon_alert:
                    alerts.append(abandon_alert)
            
            # Save alerts to database
            for alert in alerts:
                self._save_alert_to_database(session, alert, current_metrics)
        
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Threshold Breach Alerter processing time {processing_time:.3f}s exceeds 200ms target")
        
        logger.info(f"✅ Real threshold breach detection: {len(alerts)} breaches found")
        return alerts
    
    def _check_service_level_breach(self, service_id: int, current_sl: float, target_sl: float,
                                  thresholds: List, metrics: Any) -> Optional[RealAlert]:
        """Check for service level threshold breaches"""
        
        # Find service level thresholds
        sl_thresholds = None
        for threshold in thresholds:
            if threshold.threshold_name == 'service_level':
                sl_thresholds = threshold
                break
        
        # Use default thresholds if not configured
        if sl_thresholds:
            warning_level = float(sl_thresholds.warning_level)
            critical_level = float(sl_thresholds.critical_level)
            emergency_level = float(sl_thresholds.emergency_level)
        else:
            warning_level = 75.0
            critical_level = 65.0
            emergency_level = 55.0
        
        # Determine breach severity
        severity = None
        threshold_value = None
        
        if current_sl <= emergency_level:
            severity = AlertSeverity.CRITICAL
            threshold_value = emergency_level
        elif current_sl <= critical_level:
            severity = AlertSeverity.HIGH
            threshold_value = critical_level
        elif current_sl <= warning_level:
            severity = AlertSeverity.MEDIUM
            threshold_value = warning_level
        elif current_sl < target_sl:
            severity = AlertSeverity.LOW
            threshold_value = target_sl
        
        if not severity:
            return None
        
        # Generate alert
        alert_id = str(uuid.uuid4())
        
        return RealAlert(
            alert_id=alert_id,
            timestamp=datetime.now(),
            service_id=service_id,
            alert_type=AlertType.SLA_BREACH,
            severity=severity,
            title=f"Service Level Breach - {metrics.service_name}",
            description=f"Service level {current_sl:.1f}% has fallen below {threshold_value:.1f}% threshold (target: {target_sl:.1f}%)",
            metric_name="service_level",
            current_value=current_sl,
            threshold_value=threshold_value,
            affected_entities=[f"service_{service_id}"],
            recommended_action=self._get_sl_recommendation(severity, current_sl, target_sl),
            auto_resolve_possible=severity in [AlertSeverity.LOW, AlertSeverity.MEDIUM],
            ttl_seconds=self._calculate_ttl(severity)
        )
    
    def _check_abandonment_breach(self, service_id: int, current_abandon: float,
                                thresholds: List, metrics: Any) -> Optional[RealAlert]:
        """Check for abandonment rate threshold breaches"""
        
        # Find abandonment thresholds
        abandon_thresholds = None
        for threshold in thresholds:
            if threshold.threshold_name == 'abandonment_rate':
                abandon_thresholds = threshold
                break
        
        # Use default thresholds if not configured
        if abandon_thresholds:
            warning_level = float(abandon_thresholds.warning_level)
            critical_level = float(abandon_thresholds.critical_level)
            emergency_level = float(abandon_thresholds.emergency_level)
        else:
            warning_level = 5.0
            critical_level = 10.0
            emergency_level = 15.0
        
        # Determine breach severity (abandonment breaches when ABOVE threshold)
        severity = None
        threshold_value = None
        
        if current_abandon >= emergency_level:
            severity = AlertSeverity.CRITICAL
            threshold_value = emergency_level
        elif current_abandon >= critical_level:
            severity = AlertSeverity.HIGH
            threshold_value = critical_level
        elif current_abandon >= warning_level:
            severity = AlertSeverity.MEDIUM
            threshold_value = warning_level
        
        if not severity:
            return None
        
        # Generate alert
        alert_id = str(uuid.uuid4())
        
        return RealAlert(
            alert_id=alert_id,
            timestamp=datetime.now(),
            service_id=service_id,
            alert_type=AlertType.ABANDONMENT_HIGH,
            severity=severity,
            title=f"High Abandonment Rate - {metrics.service_name}",
            description=f"Abandonment rate {current_abandon:.1f}% has exceeded {threshold_value:.1f}% threshold",
            metric_name="abandonment_rate",
            current_value=current_abandon,
            threshold_value=threshold_value,
            affected_entities=[f"service_{service_id}"],
            recommended_action=self._get_abandonment_recommendation(severity, current_abandon),
            auto_resolve_possible=False,
            ttl_seconds=self._calculate_ttl(severity)
        )
    
    def _get_sl_recommendation(self, severity: AlertSeverity, current_sl: float, target_sl: float) -> str:
        """Get recommendation for service level breach"""
        sl_gap = target_sl - current_sl
        
        if severity == AlertSeverity.CRITICAL:
            return f"EMERGENCY: Deploy all available agents immediately. SL gap: {sl_gap:.1f}%"
        elif severity == AlertSeverity.HIGH:
            return f"Activate backup staff and reduce breaks. SL gap: {sl_gap:.1f}%"
        elif severity == AlertSeverity.MEDIUM:
            return f"Adjust break schedules and monitor closely. SL gap: {sl_gap:.1f}%"
        else:
            return f"Review staffing for next interval. SL gap: {sl_gap:.1f}%"
    
    def _get_abandonment_recommendation(self, severity: AlertSeverity, current_abandon: float) -> str:
        """Get recommendation for abandonment rate breach"""
        if severity == AlertSeverity.CRITICAL:
            return f"CRISIS: Review IVR messaging, add crisis message, deploy emergency staff"
        elif severity == AlertSeverity.HIGH:
            return f"Offer callback option to waiting callers, add available agents"
        else:
            return f"Analyze call patterns and adjust routing, consider queue messaging"
    
    def _calculate_ttl(self, severity: AlertSeverity) -> int:
        """Calculate alert time-to-live based on severity"""
        ttl_map = {
            AlertSeverity.CRITICAL: 3600,    # 1 hour
            AlertSeverity.HIGH: 1800,        # 30 minutes
            AlertSeverity.MEDIUM: 900,       # 15 minutes
            AlertSeverity.LOW: 600,          # 10 minutes
            AlertSeverity.INFO: 300          # 5 minutes
        }
        return ttl_map.get(severity, 600)
    
    def _save_alert_to_database(self, session, alert: RealAlert, metrics_snapshot: Any):
        """Save alert to database for audit trail"""
        session.execute(text("""
            INSERT INTO alert_history (
                alert_id, service_id, alert_type, severity, message, 
                metric_name, current_value, threshold_value, data_snapshot
            ) VALUES (
                :alert_id, :service_id, :alert_type, :severity, :message,
                :metric_name, :current_value, :threshold_value, :data_snapshot
            )
        """), {
            'alert_id': alert.alert_id,
            'service_id': alert.service_id,
            'alert_type': alert.alert_type.value,
            'severity': alert.severity.value,
            'message': alert.description,
            'metric_name': alert.metric_name,
            'current_value': alert.current_value,
            'threshold_value': alert.threshold_value,
            'data_snapshot': {
                'service_level': float(metrics_snapshot.service_level or 0),
                'abandonment_rate': float(metrics_snapshot.abandonment_rate or 0),
                'received_calls': int(metrics_snapshot.received_calls or 0),
                'treated_calls': int(metrics_snapshot.treated_calls or 0)
            }
        })
        session.commit()
        logger.info(f"✅ Alert {alert.alert_id} saved to database")
    
    def get_active_alerts(self, service_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """Get currently active alerts"""
        with self.SessionLocal() as session:
            query = """
                SELECT 
                    alert_id,
                    service_id,
                    alert_type,
                    severity,
                    message,
                    metric_name,
                    current_value,
                    threshold_value,
                    created_at
                FROM alert_history
                WHERE resolved_at IS NULL
                AND created_at >= NOW() - INTERVAL '24 hours'
            """
            
            params = {}
            if service_id:
                query += " AND service_id = :service_id"
                params['service_id'] = service_id
            
            query += " ORDER BY created_at DESC"
            
            alerts = session.execute(text(query), params).fetchall()
            
            return [
                {
                    'alert_id': alert.alert_id,
                    'service_id': alert.service_id,
                    'alert_type': alert.alert_type,
                    'severity': alert.severity,
                    'message': alert.message,
                    'metric_name': alert.metric_name,
                    'current_value': float(alert.current_value or 0),
                    'threshold_value': float(alert.threshold_value or 0),
                    'created_at': alert.created_at
                }
                for alert in alerts
            ]
    
    def acknowledge_alert(self, alert_id: str, acknowledged_by: int, notes: str = "") -> bool:
        """Acknowledge an alert"""
        with self.SessionLocal() as session:
            result = session.execute(text("""
                UPDATE alert_history 
                SET acknowledged_at = NOW(), 
                    acknowledged_by = :acknowledged_by,
                    resolution_notes = :notes
                WHERE alert_id = :alert_id
                AND acknowledged_at IS NULL
            """), {
                'alert_id': alert_id,
                'acknowledged_by': acknowledged_by,
                'notes': notes
            })
            
            session.commit()
            success = result.rowcount > 0
            
            if success:
                logger.info(f"✅ Alert {alert_id} acknowledged by user {acknowledged_by}")
            
            return success


# Example usage and testing
if __name__ == "__main__":
    # Test real threshold breach detection
    try:
        alerter = ThresholdBreachAlerterReal()
        
        # Detect breaches for service 1
        alerts = alerter.detect_real_threshold_breaches(service_id=1)
        
        print(f"Threshold Breach Alerter Results:")
        print(f"Alerts Generated: {len(alerts)}")
        
        for alert in alerts:
            print(f"\nAlert: {alert.title}")
            print(f"Severity: {alert.severity.value}")
            print(f"Type: {alert.alert_type.value}")
            print(f"Current Value: {alert.current_value}")
            print(f"Threshold: {alert.threshold_value}")
            print(f"Recommendation: {alert.recommended_action}")
        
        # Get active alerts
        active_alerts = alerter.get_active_alerts(service_id=1)
        print(f"\nActive Alerts: {len(active_alerts)}")
        
    except Exception as e:
        print(f"❌ Real Threshold Breach Alerter failed: {e}")
        print("This is expected behavior without real database connection")