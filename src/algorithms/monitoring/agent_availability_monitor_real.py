#!/usr/bin/env python3
"""
REAL Agent Availability Monitor - Zero Mock Dependencies  
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
from enum import Enum
import os

logger = logging.getLogger(__name__)

class RealAgentStatus(Enum):
    """Real agent status from database"""
    READY = "ready"
    TALKING = "talking"
    AFTER_CALL_WORK = "after_call_work"
    BREAK = "break"
    OFFLINE = "offline"
    TRAINING = "training"
    MEETING = "meeting"

@dataclass
class RealAgentAvailability:
    """Real agent availability from database"""
    agent_id: int
    agent_name: str
    timestamp: datetime
    current_status: RealAgentStatus
    time_in_status_seconds: float
    login_time_today: float
    calls_handled_today: int
    service_ids: List[int]
    utilization_percent: float
    is_available_for_calls: bool

@dataclass
class RealAgentSummary:
    """Summary of agent availability across all agents"""
    timestamp: datetime
    total_agents: int
    ready_agents: int
    talking_agents: int
    acw_agents: int
    break_agents: int
    offline_agents: int
    training_agents: int
    meeting_agents: int
    overall_utilization: float
    available_capacity: float

class AgentAvailabilityMonitorReal:
    """Real-time Agent Availability Monitor using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 0.5  # 500ms BDD requirement
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Validate database connection on startup
        self._validate_database_connection()
        
        # Create agent monitoring tables if needed
        self._ensure_agent_tables()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate agent tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) FROM information_schema.tables 
                    WHERE table_name IN ('agent_current_status', 'agent_activity', 'agents')
                """)).scalar()
                
                if tables_check < 2:  # agent_current_status might not exist yet
                    logger.warning("Some agent tables missing - will auto-create")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Agent monitoring ready")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_agent_tables(self):
        """Create agent-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create agent_current_status table if it doesn't exist
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS agent_current_status (
                    agent_id INTEGER PRIMARY KEY,
                    current_status VARCHAR(50) NOT NULL DEFAULT 'offline',
                    status_changed_at TIMESTAMPTZ DEFAULT NOW(),
                    last_updated TIMESTAMPTZ DEFAULT NOW()
                )
            """))
            
            # Create agents table if it doesn't exist (basic structure)
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS agents (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(200) NOT NULL,
                    employee_id VARCHAR(50),
                    is_active BOOLEAN DEFAULT true,
                    primary_group_id INTEGER,
                    created_at TIMESTAMPTZ DEFAULT NOW()
                )
            """))
            
            session.commit()
            logger.info("✅ Agent monitoring tables created/validated")
    
    def monitor_agent_availability(self, agent_id: int) -> RealAgentAvailability:
        """Monitor real agent availability from database"""
        start_time = time.time()
        
        with self.SessionLocal() as session:
            # Get current agent status
            agent_data = session.execute(text("""
                SELECT 
                    a.id,
                    a.name,
                    COALESCE(acs.current_status, 'offline') as current_status,
                    COALESCE(acs.status_changed_at, NOW()) as status_changed_at,
                    COALESCE(acs.last_updated, NOW()) as last_updated
                FROM agents a
                LEFT JOIN agent_current_status acs ON acs.agent_id = a.id
                WHERE a.id = :agent_id
                AND a.is_active = true
            """), {'agent_id': agent_id}).fetchone()
            
            if not agent_data:
                raise ValueError(f"Agent {agent_id} not found or inactive")
            
            # Get today's activity data
            today_activity = session.execute(text("""
                SELECT 
                    SUM(login_time) as total_login_time,
                    COUNT(DISTINCT interval_start_time) as active_intervals
                FROM agent_activity aa
                WHERE aa.agent_id = :agent_id
                AND DATE(aa.interval_start_time) = CURRENT_DATE
                AND aa.login_time > 0
            """), {'agent_id': agent_id}).fetchone()
            
            # Get service assignments (from activity data)
            service_assignments = session.execute(text("""
                SELECT DISTINCT sg.service_id
                FROM agent_activity aa
                JOIN service_groups sg ON sg.group_id = aa.group_id
                WHERE aa.agent_id = :agent_id
                AND aa.interval_start_time >= CURRENT_DATE
                AND aa.login_time > 0
            """), {'agent_id': agent_id}).fetchall()
            
            # Calculate metrics
            current_status = RealAgentStatus(agent_data.current_status)
            time_in_status = (datetime.now() - agent_data.status_changed_at).total_seconds()
            login_time_today = float(today_activity.total_login_time or 0)
            calls_handled = int(today_activity.active_intervals or 0)  # Rough estimate
            service_ids = [row.service_id for row in service_assignments]
            
            # Calculate utilization (rough estimate based on login time)
            total_possible_seconds = 8 * 3600  # 8-hour workday
            utilization_percent = min(100.0, (login_time_today / total_possible_seconds) * 100)
            
            # Determine if available for calls
            is_available = current_status in [RealAgentStatus.READY, RealAgentStatus.TALKING]
            
            availability = RealAgentAvailability(
                agent_id=agent_id,
                agent_name=agent_data.name,
                timestamp=datetime.now(),
                current_status=current_status,
                time_in_status_seconds=time_in_status,
                login_time_today=login_time_today,
                calls_handled_today=calls_handled,
                service_ids=service_ids,
                utilization_percent=utilization_percent,
                is_available_for_calls=is_available
            )
        
        # Validate processing time meets BDD requirement
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"Agent Availability Monitor processing time {processing_time:.3f}s exceeds 500ms target")
        
        logger.info(f"✅ Real agent {agent_id} status: {current_status.value}, util: {utilization_percent:.1f}%")
        return availability
    
    def get_all_agent_availability(self) -> RealAgentSummary:
        """Get availability summary for all active agents"""
        start_time = time.time()
        
        with self.SessionLocal() as session:
            # Get all active agents with their current status
            agents_data = session.execute(text("""
                SELECT 
                    a.id,
                    a.name,
                    COALESCE(acs.current_status, 'offline') as current_status,
                    COALESCE(today_activity.login_time, 0) as login_time_today
                FROM agents a
                LEFT JOIN agent_current_status acs ON acs.agent_id = a.id
                LEFT JOIN (
                    SELECT 
                        agent_id,
                        SUM(login_time) as login_time
                    FROM agent_activity 
                    WHERE DATE(interval_start_time) = CURRENT_DATE
                    GROUP BY agent_id
                ) today_activity ON today_activity.agent_id = a.id
                WHERE a.is_active = true
            """)).fetchall()
            
            # Count agents by status
            status_counts = {status.value: 0 for status in RealAgentStatus}
            total_utilization = 0.0
            total_agents = len(agents_data)
            
            for agent in agents_data:
                status = agent.current_status
                status_counts[status] = status_counts.get(status, 0) + 1
                
                # Calculate individual utilization
                login_time = float(agent.login_time_today or 0)
                agent_util = min(100.0, (login_time / (8 * 3600)) * 100)
                total_utilization += agent_util
            
            # Calculate overall metrics
            overall_utilization = total_utilization / max(1, total_agents)
            ready_agents = status_counts.get('ready', 0)
            available_capacity = (ready_agents / max(1, total_agents)) * 100
            
            summary = RealAgentSummary(
                timestamp=datetime.now(),
                total_agents=total_agents,
                ready_agents=ready_agents,
                talking_agents=status_counts.get('talking', 0),
                acw_agents=status_counts.get('after_call_work', 0),
                break_agents=status_counts.get('break', 0),
                offline_agents=status_counts.get('offline', 0),
                training_agents=status_counts.get('training', 0),
                meeting_agents=status_counts.get('meeting', 0),
                overall_utilization=overall_utilization,
                available_capacity=available_capacity
            )
        
        # Validate processing time
        processing_time = time.time() - start_time
        if processing_time >= self.processing_target:
            logger.warning(f"All Agent Availability processing time {processing_time:.3f}s exceeds 500ms target")
        
        logger.info(f"✅ Agent summary: {total_agents} total, {ready_agents} ready, {overall_utilization:.1f}% util")
        return summary
    
    def update_agent_status(self, agent_id: int, new_status: str) -> bool:
        """Update agent status in real-time"""
        try:
            status = RealAgentStatus(new_status)
        except ValueError:
            logger.error(f"Invalid status: {new_status}")
            return False
        
        with self.SessionLocal() as session:
            # Update or insert agent status
            session.execute(text("""
                INSERT INTO agent_current_status (agent_id, current_status, status_changed_at, last_updated)
                VALUES (:agent_id, :status, NOW(), NOW())
                ON CONFLICT (agent_id) 
                DO UPDATE SET 
                    current_status = EXCLUDED.current_status,
                    status_changed_at = NOW(),
                    last_updated = NOW()
            """), {'agent_id': agent_id, 'status': status.value})
            
            session.commit()
            logger.info(f"✅ Agent {agent_id} status updated to {status.value}")
            return True
    
    def get_agent_utilization_trend(self, agent_id: int, days: int = 7) -> List[Dict[str, Any]]:
        """Get agent utilization trend over specified days"""
        with self.SessionLocal() as session:
            trend_data = session.execute(text("""
                SELECT 
                    DATE(interval_start_time) as work_date,
                    SUM(login_time) as total_login_time,
                    COUNT(DISTINCT interval_start_time) as active_intervals
                FROM agent_activity
                WHERE agent_id = :agent_id
                AND interval_start_time >= CURRENT_DATE - INTERVAL ':days days'
                AND login_time > 0
                GROUP BY DATE(interval_start_time)
                ORDER BY work_date
            """), {'agent_id': agent_id, 'days': days}).fetchall()
            
            return [
                {
                    'date': row.work_date,
                    'login_time_seconds': float(row.total_login_time or 0),
                    'utilization_percent': min(100.0, (float(row.total_login_time or 0) / (8 * 3600)) * 100),
                    'active_intervals': int(row.active_intervals)
                }
                for row in trend_data
            ]


# Example usage and testing
if __name__ == "__main__":
    # Test real agent availability monitoring
    try:
        monitor = AgentAvailabilityMonitorReal()
        
        # Monitor specific agent
        agent_availability = monitor.monitor_agent_availability(agent_id=1)
        
        print(f"Agent Availability Monitor Results:")
        print(f"Agent: {agent_availability.agent_name}")
        print(f"Status: {agent_availability.current_status.value}")
        print(f"Time in Status: {agent_availability.time_in_status_seconds:.0f}s")
        print(f"Utilization: {agent_availability.utilization_percent:.1f}%")
        print(f"Available for Calls: {agent_availability.is_available_for_calls}")
        print(f"Services: {agent_availability.service_ids}")
        
        # Get all agents summary
        summary = monitor.get_all_agent_availability()
        print(f"\nAgent Summary:")
        print(f"Total Agents: {summary.total_agents}")
        print(f"Ready: {summary.ready_agents}")
        print(f"Talking: {summary.talking_agents}")
        print(f"Overall Utilization: {summary.overall_utilization:.1f}%")
        print(f"Available Capacity: {summary.available_capacity:.1f}%")
        
        # Test status update
        success = monitor.update_agent_status(agent_id=1, new_status="ready")
        print(f"Status Update Success: {success}")
        
    except Exception as e:
        print(f"❌ Real Agent Availability Monitor failed: {e}")
        print("This is expected behavior without real database connection")