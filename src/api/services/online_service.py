from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import logging

from ..db.models import AgentCurrentStatus, GroupOnlineMetrics, Agent, Service, Group
from ..utils.cache import cache_with_timeout
from ..utils.validators import validate_service_id

logger = logging.getLogger(__name__)


class OnlineService:
    """
    PHASE 1: Core Argus-Compatible Online Service
    
    Provides real-time status tracking with 10-second cache.
    Handles queue metrics and SLA monitoring.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    @cache_with_timeout(timeout=10)  # 10 seconds cache for real-time data
    async def get_agent_status(self, agent_id: str) -> Dict[str, Any]:
        """
        Get real-time agent status with 10-second cache.
        
        Args:
            agent_id: Agent identifier
            
        Returns:
            Current agent status in Argus format
        """
        try:
            # Get current status
            current_status = self.db.query(AgentCurrentStatus).filter(
                AgentCurrentStatus.agent_id == agent_id
            ).first()
            
            if not current_status:
                return {
                    "status": "error",
                    "message": f"Agent {agent_id} not found or offline",
                    "data": None,
                    "timestamp": datetime.utcnow().isoformat()
                }
            
            # Calculate duration in current state
            duration = (datetime.utcnow() - current_status.start_date).total_seconds() * 1000  # milliseconds
            
            return {
                "status": "success",
                "data": {
                    "agent_id": current_status.agent_id,
                    "state_code": current_status.state_code,
                    "state_name": current_status.state_name,
                    "start_date": current_status.start_date.isoformat(),
                    "duration": int(duration),
                    "duration_minutes": duration / (1000 * 60),
                    "last_updated": current_status.updated_at.isoformat()
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting agent status for {agent_id}: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": None,
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=10)  # 10 seconds cache for real-time data
    async def get_groups_online_load(self, service_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Get real-time queue metrics and SLA data.
        
        Args:
            service_id: Optional service filter
            
        Returns:
            Group online metrics in Argus format
        """
        try:
            # Build query
            query = self.db.query(GroupOnlineMetrics)
            
            # Apply service filter if provided
            if service_id:
                if not validate_service_id(service_id):
                    raise ValueError(f"Invalid service_id: {service_id}")
                query = query.filter(GroupOnlineMetrics.service_id == service_id)
            
            # Get metrics
            metrics = query.all()
            
            # Format response
            groups_data = []
            for metric in metrics:
                # Calculate SLA metrics
                sla_percentage = (metric.call_answered_tst / metric.call_received * 100) if metric.call_received > 0 else 0
                
                group_data = {
                    "service_id": metric.service_id,
                    "group_id": metric.group_id,
                    "real_time_metrics": {
                        "call_number": metric.call_number,  # Contacts in queue now
                        "operator_number": metric.operator_number,  # Available operators
                        "awt": metric.awt,  # Average wait time (ms)
                        "call_processing": metric.call_processing,  # Calls being processed now
                        "queue_load": "HIGH" if metric.call_number > metric.operator_number * 2 else "NORMAL"
                    },
                    "daily_metrics": {
                        "call_received": metric.call_received,
                        "call_answered": metric.call_answered,
                        "call_answered_tst": metric.call_answered_tst,  # Within SLA
                        "aht": metric.aht,  # Average handle time (ms)
                        "acd": metric.acd,  # Percentage answered
                        "sla_percentage": sla_percentage,
                        "abandonment_rate": ((metric.call_received - metric.call_answered) / metric.call_received * 100) if metric.call_received > 0 else 0
                    },
                    "performance_indicators": {
                        "awt_status": "GOOD" if metric.awt < 20000 else "WARNING" if metric.awt < 60000 else "CRITICAL",  # 20s, 60s thresholds
                        "sla_status": "GOOD" if sla_percentage >= 80 else "WARNING" if sla_percentage >= 60 else "CRITICAL",
                        "capacity_utilization": (metric.call_processing / metric.operator_number * 100) if metric.operator_number > 0 else 0
                    },
                    "last_updated": metric.updated_at.isoformat()
                }
                groups_data.append(group_data)
            
            # Calculate service-level summary
            total_queue = sum(m.call_number for m in metrics)
            total_operators = sum(m.operator_number for m in metrics)
            total_received = sum(m.call_received for m in metrics)
            total_answered = sum(m.call_answered for m in metrics)
            total_answered_tst = sum(m.call_answered_tst for m in metrics)
            avg_awt = sum(m.awt for m in metrics) / len(metrics) if metrics else 0
            
            service_summary = {
                "total_groups": len(metrics),
                "total_queue": total_queue,
                "total_operators": total_operators,
                "total_received": total_received,
                "total_answered": total_answered,
                "total_answered_tst": total_answered_tst,
                "overall_sla": (total_answered_tst / total_received * 100) if total_received > 0 else 0,
                "average_awt": avg_awt,
                "overall_status": "GOOD" if total_queue < total_operators else "WARNING" if total_queue < total_operators * 2 else "CRITICAL"
            }
            
            return {
                "status": "success",
                "data": groups_data,
                "summary": service_summary,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting groups online load: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=30)  # 30 seconds cache for status overview
    async def get_service_status_overview(self, service_id: str) -> Dict[str, Any]:
        """
        Get comprehensive service status overview.
        
        Args:
            service_id: Service identifier
            
        Returns:
            Service status overview in Argus format
        """
        try:
            if not validate_service_id(service_id):
                raise ValueError(f"Invalid service_id: {service_id}")
            
            # Get agent status counts
            agent_status_counts = self.db.query(
                AgentCurrentStatus.state_code,
                AgentCurrentStatus.state_name,
                func.count(AgentCurrentStatus.agent_id).label('count')
            ).join(
                Agent, AgentCurrentStatus.agent_id == Agent.id
            ).join(
                Group, Agent.groups.contains(Group.id)
            ).filter(
                Group.service_id == service_id
            ).group_by(
                AgentCurrentStatus.state_code,
                AgentCurrentStatus.state_name
            ).all()
            
            # Get group metrics
            group_metrics = self.db.query(GroupOnlineMetrics).filter(
                GroupOnlineMetrics.service_id == service_id
            ).all()
            
            # Format agent status breakdown
            agent_status_breakdown = {}
            total_agents = 0
            for status in agent_status_counts:
                agent_status_breakdown[status.state_code] = {
                    "state_name": status.state_name,
                    "count": status.count
                }
                total_agents += status.count
            
            # Calculate service metrics
            total_queue = sum(m.call_number for m in group_metrics)
            total_operators = sum(m.operator_number for m in group_metrics)
            total_processing = sum(m.call_processing for m in group_metrics)
            
            return {
                "status": "success",
                "data": {
                    "service_id": service_id,
                    "agent_status": agent_status_breakdown,
                    "total_agents": total_agents,
                    "queue_metrics": {
                        "total_queue": total_queue,
                        "total_operators": total_operators,
                        "total_processing": total_processing,
                        "capacity_utilization": (total_processing / total_operators * 100) if total_operators > 0 else 0
                    },
                    "service_health": {
                        "status": "HEALTHY" if total_queue < total_operators else "DEGRADED" if total_queue < total_operators * 2 else "CRITICAL",
                        "queue_pressure": total_queue / total_operators if total_operators > 0 else 0,
                        "operator_availability": total_operators - total_processing
                    }
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting service status overview for {service_id}: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": None,
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=5)  # 5 seconds cache for monitoring
    async def get_system_health_check(self) -> Dict[str, Any]:
        """
        Get system-wide health check for monitoring.
        
        Returns:
            System health status
        """
        try:
            # Get counts
            total_agents = self.db.query(Agent).count()
            online_agents = self.db.query(AgentCurrentStatus).count()
            total_groups = self.db.query(Group).count()
            active_groups = self.db.query(GroupOnlineMetrics).count()
            
            # Get queue totals
            queue_totals = self.db.query(
                func.sum(GroupOnlineMetrics.call_number).label('total_queue'),
                func.sum(GroupOnlineMetrics.operator_number).label('total_operators')
            ).first()
            
            total_queue = queue_totals.total_queue or 0
            total_operators = queue_totals.total_operators or 0
            
            # Determine system health
            agent_health = "GOOD" if (online_agents / total_agents * 100) >= 80 else "WARNING" if (online_agents / total_agents * 100) >= 60 else "CRITICAL"
            queue_health = "GOOD" if total_queue < total_operators else "WARNING" if total_queue < total_operators * 2 else "CRITICAL"
            
            overall_health = "GOOD" if agent_health == "GOOD" and queue_health == "GOOD" else "WARNING" if "CRITICAL" not in [agent_health, queue_health] else "CRITICAL"
            
            return {
                "status": "success",
                "data": {
                    "overall_health": overall_health,
                    "agents": {
                        "total": total_agents,
                        "online": online_agents,
                        "online_percentage": (online_agents / total_agents * 100) if total_agents > 0 else 0,
                        "health": agent_health
                    },
                    "groups": {
                        "total": total_groups,
                        "active": active_groups,
                        "active_percentage": (active_groups / total_groups * 100) if total_groups > 0 else 0
                    },
                    "queues": {
                        "total_queue": total_queue,
                        "total_operators": total_operators,
                        "queue_ratio": total_queue / total_operators if total_operators > 0 else 0,
                        "health": queue_health
                    }
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting system health check: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": None,
                "timestamp": datetime.utcnow().isoformat()
            }