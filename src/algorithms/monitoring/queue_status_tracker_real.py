#!/usr/bin/env python3
"""
REAL Queue Status Tracker - Zero Mock Dependencies
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
class RealQueueStatus:
    """Real queue status from database"""
    service_id: int
    queue_name: str
    timestamp: datetime
    calls_waiting: int
    longest_wait_seconds: float
    average_wait_seconds: float
    total_calls_received: int
    total_calls_treated: int
    current_queue_length: int
    estimated_wait_time: float
    queue_health_status: str

class QueueStatusTrackerReal:
    """Real-time Queue Status Tracker using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.5  # 500ms BDD requirement
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
    
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
                    WHERE interval_start_time >= NOW() - INTERVAL '1 hour'
                """)).scalar()
                
                if recent_data == 0:
                    raise ConnectionError("No recent contact_statistics data for queue monitoring")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Queue data validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def track_real_queue_status(self, service_id: int, interval_minutes: int = 15) -> RealQueueStatus:
        """Track real-time queue metrics from actual database data"""
        start_time = time.time()
        
        with self.SessionLocal() as session:
            # Get current queue data from contact_statistics
            queue_data = session.execute(text("""
                SELECT 
                    cs.service_id,
                    s.name as service_name,
                    cs.received_calls,
                    cs.treated_calls,
                    cs.received_calls - cs.treated_calls as current_queue_length,
                    cs.abandonment_rate,
                    cs.service_level,
                    cs.aht,
                    cs.interval_start_time
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
            
            if not queue_data:
                raise ValueError(f"No recent queue data for service {service_id} in last {interval_minutes} minutes")
            
            # Calculate queue metrics
            calls_received = int(queue_data.received_calls or 0)
            calls_treated = int(queue_data.treated_calls or 0)
            current_queue_length = int(queue_data.current_queue_length or 0)
            service_level = float(queue_data.service_level or 0)
            aht = float(queue_data.aht or 0)
            abandonment_rate = float(queue_data.abandonment_rate or 0)
            
            # Estimate wait times based on queue length and service level
            if service_level > 0 and aht > 0:
                # Rough estimate: if SL is low, wait times are higher
                avg_wait_seconds = (100 - service_level) / 100 * aht * 2
                longest_wait_seconds = avg_wait_seconds * 2.5
            else:
                avg_wait_seconds = current_queue_length * 30  # Conservative estimate
                longest_wait_seconds = avg_wait_seconds * 2
            
            # Estimate future wait time for new callers
            if current_queue_length > 0 and aht > 0:
                estimated_wait_time = current_queue_length * aht
            else:
                estimated_wait_time = avg_wait_seconds
            
            # Determine queue health status
            queue_health_status = self._assess_queue_health(
                current_queue_length, service_level, abandonment_rate
            )
            
            status = RealQueueStatus(
                service_id=service_id,
                queue_name=queue_data.service_name or f"Service_{service_id}",
                timestamp=datetime.now(),
                calls_waiting=current_queue_length,
                longest_wait_seconds=longest_wait_seconds,
                average_wait_seconds=avg_wait_seconds,
                total_calls_received=calls_received,
                total_calls_treated=calls_treated,
                current_queue_length=current_queue_length,
                estimated_wait_time=estimated_wait_time,
                queue_health_status=queue_health_status
            )
        
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Queue Status Tracker processing time {processing_time:.3f}s exceeds 500ms target")
        
        logger.info(f"✅ Real queue status: {current_queue_length} waiting, {queue_health_status} health")
        return status
    
    def _assess_queue_health(self, queue_length: int, service_level: float, abandonment_rate: float) -> str:
        """Assess overall queue health based on multiple metrics"""
        if abandonment_rate > 15 or service_level < 50:
            return "CRITICAL"
        elif abandonment_rate > 10 or service_level < 65 or queue_length > 50:
            return "WARNING"
        elif abandonment_rate > 5 or service_level < 75 or queue_length > 20:
            return "CAUTION"
        else:
            return "HEALTHY"
    
    def get_all_queue_statuses(self, interval_minutes: int = 15) -> List[RealQueueStatus]:
        """Get queue status for all active services"""
        with self.SessionLocal() as session:
            # Get all services with recent activity
            active_services = session.execute(text("""
                SELECT DISTINCT service_id 
                FROM contact_statistics 
                WHERE interval_start_time >= NOW() - INTERVAL ':interval_minutes minutes'
                ORDER BY service_id
            """), {'interval_minutes': interval_minutes}).fetchall()
            
            statuses = []
            for service_row in active_services:
                try:
                    status = self.track_real_queue_status(service_row.service_id, interval_minutes)
                    statuses.append(status)
                except Exception as e:
                    logger.warning(f"Failed to get status for service {service_row.service_id}: {e}")
            
            return statuses
    
    def get_queue_trend(self, service_id: int, hours: int = 4) -> List[Dict[str, Any]]:
        """Get queue length trend over specified hours"""
        with self.SessionLocal() as session:
            trend_data = session.execute(text("""
                SELECT 
                    interval_start_time as timestamp,
                    received_calls,
                    treated_calls,
                    received_calls - treated_calls as queue_length,
                    service_level,
                    abandonment_rate
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                ORDER BY interval_start_time ASC
            """), {'service_id': service_id, 'hours': hours}).fetchall()
            
            return [
                {
                    'timestamp': row.timestamp,
                    'queue_length': max(0, int(row.queue_length or 0)),
                    'calls_received': int(row.received_calls or 0),
                    'calls_treated': int(row.treated_calls or 0),
                    'service_level': float(row.service_level or 0),
                    'abandonment_rate': float(row.abandonment_rate or 0)
                }
                for row in trend_data
            ]
    
    def get_peak_queue_analysis(self, service_id: int, days: int = 7) -> Dict[str, Any]:
        """Analyze peak queue patterns over specified days"""
        with self.SessionLocal() as session:
            peak_analysis = session.execute(text("""
                SELECT 
                    EXTRACT(hour FROM interval_start_time) as hour_of_day,
                    AVG(received_calls - treated_calls) as avg_queue_length,
                    MAX(received_calls - treated_calls) as max_queue_length,
                    COUNT(*) as intervals_count
                FROM contact_statistics
                WHERE service_id = :service_id
                AND interval_start_time >= NOW() - INTERVAL ':days days'
                AND received_calls > 0
                GROUP BY EXTRACT(hour FROM interval_start_time)
                ORDER BY hour_of_day
            """), {'service_id': service_id, 'days': days}).fetchall()
            
            hourly_patterns = {}
            for row in peak_analysis:
                hour = int(row.hour_of_day)
                hourly_patterns[hour] = {
                    'avg_queue_length': float(row.avg_queue_length or 0),
                    'max_queue_length': int(row.max_queue_length or 0),
                    'sample_size': int(row.intervals_count)
                }
            
            # Find peak hours
            if hourly_patterns:
                peak_hour = max(hourly_patterns.keys(), 
                              key=lambda h: hourly_patterns[h]['avg_queue_length'])
                lowest_hour = min(hourly_patterns.keys(), 
                                key=lambda h: hourly_patterns[h]['avg_queue_length'])
            else:
                peak_hour = None
                lowest_hour = None
            
            return {
                'hourly_patterns': hourly_patterns,
                'peak_hour': peak_hour,
                'lowest_hour': lowest_hour,
                'analysis_period_days': days
            }


# Example usage and testing
if __name__ == "__main__":
    # Test real queue status tracking
    try:
        tracker = QueueStatusTrackerReal()
        
        # Track queue status for service 1
        status = tracker.track_real_queue_status(service_id=1)
        
        print(f"Queue Status Tracker Results:")
        print(f"Queue: {status.queue_name}")
        print(f"Calls Waiting: {status.calls_waiting}")
        print(f"Current Queue Length: {status.current_queue_length}")
        print(f"Average Wait: {status.average_wait_seconds:.1f}s")
        print(f"Estimated Wait: {status.estimated_wait_time:.1f}s")
        print(f"Health Status: {status.queue_health_status}")
        
        # Get all active queues
        all_statuses = tracker.get_all_queue_statuses()
        print(f"Active Queues: {len(all_statuses)}")
        
        # Get queue trend
        trend = tracker.get_queue_trend(service_id=1, hours=2)
        print(f"Queue Trend Points: {len(trend)}")
        
        # Get peak analysis
        peak_analysis = tracker.get_peak_queue_analysis(service_id=1, days=7)
        print(f"Peak Hour: {peak_analysis['peak_hour']}")
        
    except Exception as e:
        print(f"❌ Real Queue Status Tracker failed: {e}")
        print("This is expected behavior without real database connection")