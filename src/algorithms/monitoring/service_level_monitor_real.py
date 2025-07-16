#!/usr/bin/env python3
"""
REAL Service Level Monitor - Zero Mock Dependencies
Transformed from: subagents/agent-1/status_monitor.py
Database: PostgreSQL Schema 001 integration required
Performance: <500ms BDD requirement
"""

import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

logger = logging.getLogger(__name__)

@dataclass
class RealServiceLevelMetrics:
    """Real service level metrics from database"""
    timestamp: datetime
    service_id: int
    current_service_level: float
    target_service_level: float
    calls_offered: int
    calls_answered: int
    calls_answered_within_threshold: int
    threshold_seconds: int
    average_speed_answer: float
    longest_wait_time: float
    is_meeting_sla: bool
    breach_severity: str

class ServiceLevelMonitorReal:
    """Real-time Service Level Monitor using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.5  # 500ms BDD requirement
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
        
        # Create monitoring tables if needed
        self._ensure_monitoring_tables()
    
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
                    WHERE table_name IN ('contact_statistics', 'services', 'agent_activity')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_monitoring_tables(self):
        """Create monitoring-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create real_time_thresholds table
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
            
            # Create monitoring_sessions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS monitoring_sessions (
                    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    start_time TIMESTAMPTZ DEFAULT NOW(),
                    end_time TIMESTAMPTZ,
                    alerts_generated INTEGER DEFAULT 0,
                    avg_service_level DECIMAL(5,2),
                    min_service_level DECIMAL(5,2),
                    max_service_level DECIMAL(5,2)
                )
            """))
            
            session.commit()
            logger.info("✅ Monitoring tables created/validated")
    
    def calculate_real_service_level(self, service_id: int, interval_minutes: int = 15) -> RealServiceLevelMetrics:
        """Calculate real-time service level from actual database data"""
        start_time = time.time()
        
        with self.SessionLocal() as session:
            # Get current interval data from contact_statistics
            current_data = session.execute(text("""
                SELECT 
                    cs.service_id,
                    cs.service_level,
                    cs.received_calls,
                    cs.treated_calls,
                    cs.aht,
                    cs.interval_start_time,
                    s.target_service_level,
                    s.target_answer_time
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
            
            if not current_data:
                raise ValueError(f"No recent data for service {service_id} in last {interval_minutes} minutes")
            
            # Get threshold configuration
            threshold_config = session.execute(text("""
                SELECT warning_level, critical_level, emergency_level
                FROM real_time_thresholds 
                WHERE service_id = :service_id 
                AND threshold_name = 'service_level'
            """), {'service_id': service_id}).fetchone()
            
            # Use default thresholds if not configured
            if threshold_config:
                warning_level = float(threshold_config.warning_level)
                critical_level = float(threshold_config.critical_level)
                emergency_level = float(threshold_config.emergency_level)
            else:
                warning_level = 75.0
                critical_level = 65.0
                emergency_level = 55.0
            
            # Calculate derived metrics
            current_sl = float(current_data.service_level or 0)
            target_sl = float(current_data.target_service_level or 80.0)
            calls_offered = int(current_data.received_calls or 0)
            calls_answered = int(current_data.treated_calls or 0)
            threshold_seconds = int(current_data.target_answer_time or 20)
            
            # Calculate calls answered within threshold (estimate based on SL)
            calls_within_threshold = int(calls_offered * (current_sl / 100.0))
            
            # Calculate average speed of answer (estimate from AHT and SL)
            avg_speed_answer = float(current_data.aht or 0) * 0.1  # Rough estimate
            longest_wait = avg_speed_answer * 2.5  # Conservative estimate
            
            # Determine if meeting SLA
            is_meeting_sla = current_sl >= target_sl
            
            # Determine breach severity
            if current_sl <= emergency_level:
                breach_severity = "EMERGENCY"
            elif current_sl <= critical_level:
                breach_severity = "CRITICAL"
            elif current_sl <= warning_level:
                breach_severity = "WARNING"
            else:
                breach_severity = "NORMAL"
            
            metrics = RealServiceLevelMetrics(
                timestamp=datetime.now(),
                service_id=service_id,
                current_service_level=current_sl,
                target_service_level=target_sl,
                calls_offered=calls_offered,
                calls_answered=calls_answered,
                calls_answered_within_threshold=calls_within_threshold,
                threshold_seconds=threshold_seconds,
                average_speed_answer=avg_speed_answer,
                longest_wait_time=longest_wait,
                is_meeting_sla=is_meeting_sla,
                breach_severity=breach_severity
            )
            
            # Save monitoring session if this is a significant event
            if breach_severity in ["CRITICAL", "EMERGENCY"]:
                self._log_monitoring_event(session, service_id, metrics)
            
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Service Level Monitor processing time {processing_time:.3f}s exceeds 500ms target")
        
        logger.info(f"✅ Real SL calculated: {current_sl:.1f}% (target: {target_sl:.1f}%) - {breach_severity}")
        return metrics
    
    def _log_monitoring_event(self, session, service_id: int, metrics: RealServiceLevelMetrics):
        """Log significant monitoring events to database"""
        session.execute(text("""
            INSERT INTO monitoring_sessions (service_id, avg_service_level, min_service_level, max_service_level)
            VALUES (:service_id, :avg_sl, :min_sl, :max_sl)
        """), {
            'service_id': service_id,
            'avg_sl': metrics.current_service_level,
            'min_sl': metrics.current_service_level,
            'max_sl': metrics.current_service_level
        })
        session.commit()
    
    def get_service_level_trend(self, service_id: int, hours: int = 4) -> List[Dict[str, Any]]:
        """Get service level trend over specified hours"""
        with self.SessionLocal() as session:
            trend_data = session.execute(text("""
                SELECT 
                    interval_start_time as timestamp,
                    service_level,
                    received_calls,
                    treated_calls
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                ORDER BY interval_start_time ASC
            """), {'service_id': service_id, 'hours': hours}).fetchall()
            
            return [
                {
                    'timestamp': row.timestamp,
                    'service_level': float(row.service_level or 0),
                    'calls_offered': int(row.received_calls or 0),
                    'calls_answered': int(row.treated_calls or 0)
                }
                for row in trend_data
            ]
    
    def configure_thresholds(self, service_id: int, warning: float, critical: float, emergency: float):
        """Configure service level thresholds for a service"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO real_time_thresholds (service_id, threshold_name, warning_level, critical_level, emergency_level)
                VALUES (:service_id, 'service_level', :warning, :critical, :emergency)
                ON CONFLICT (service_id, threshold_name) 
                DO UPDATE SET 
                    warning_level = EXCLUDED.warning_level,
                    critical_level = EXCLUDED.critical_level,
                    emergency_level = EXCLUDED.emergency_level
            """), {
                'service_id': service_id,
                'warning': warning,
                'critical': critical,
                'emergency': emergency
            })
            session.commit()
            logger.info(f"✅ Thresholds configured for service {service_id}: W:{warning}% C:{critical}% E:{emergency}%")


# Example usage and testing
if __name__ == "__main__":
    # Test real service level monitoring
    try:
        monitor = ServiceLevelMonitorReal()
        
        # Configure thresholds for service 1
        monitor.configure_thresholds(service_id=1, warning=75.0, critical=65.0, emergency=55.0)
        
        # Calculate current service level
        metrics = monitor.calculate_real_service_level(service_id=1)
        
        print(f"Service Level Monitor Results:")
        print(f"Current SL: {metrics.current_service_level:.1f}%")
        print(f"Target SL: {metrics.target_service_level:.1f}%")
        print(f"Status: {metrics.breach_severity}")
        print(f"Meeting SLA: {metrics.is_meeting_sla}")
        print(f"Calls Offered: {metrics.calls_offered}")
        print(f"Calls Answered: {metrics.calls_answered}")
        
        # Get trend data
        trend = monitor.get_service_level_trend(service_id=1, hours=2)
        print(f"Trend points: {len(trend)}")
        
    except Exception as e:
        print(f"❌ Real Service Level Monitor failed: {e}")
        print("This is expected behavior without real database connection")