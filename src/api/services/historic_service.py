from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import logging

from ..db.models import (
    ServiceGroupMetrics, AgentStatusHistory, AgentLoginHistory, 
    AgentCallsData, AgentChatsWorkTime, Agent, Service, Group
)
from ..utils.cache import cache_with_timeout
from ..utils.validators import validate_date_range, validate_service_id

logger = logging.getLogger(__name__)


class HistoricService:
    """
    PHASE 1: Core Argus-Compatible Historic Service
    
    Provides 15-minute interval metrics with exact Argus endpoint behavior.
    Handles status change tracking, session management, and multi-chat overlap.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    @cache_with_timeout(timeout=900)  # 15 minutes cache
    async def get_service_group_data(
        self, 
        service_id: str, 
        start_date: datetime, 
        end_date: datetime,
        group_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get service group data with 15-minute interval metrics.
        
        Args:
            service_id: Service identifier
            start_date: Start of the time range
            end_date: End of the time range  
            group_id: Optional group filter
            
        Returns:
            Service group metrics in Argus format
        """
        try:
            # Validate inputs
            if not validate_service_id(service_id):
                raise ValueError(f"Invalid service_id: {service_id}")
            
            if not validate_date_range(start_date, end_date):
                raise ValueError("Invalid date range")
            
            # Build query
            query = self.db.query(ServiceGroupMetrics).filter(
                and_(
                    ServiceGroupMetrics.service_id == service_id,
                    ServiceGroupMetrics.start_interval >= start_date,
                    ServiceGroupMetrics.end_interval <= end_date
                )
            )
            
            # Apply group filter if provided
            if group_id:
                query = query.filter(ServiceGroupMetrics.group_id == group_id)
            
            # Execute query and order by time
            metrics = query.order_by(ServiceGroupMetrics.start_interval).all()
            
            # Format response in Argus format
            service_data = []
            for metric in metrics:
                interval_data = {
                    "service_id": metric.service_id,
                    "group_id": metric.group_id,
                    "start_interval": metric.start_interval.isoformat(),
                    "end_interval": metric.end_interval.isoformat(),
                    "contacts": {
                        "not_unique_received": metric.not_unique_received,
                        "not_unique_treated": metric.not_unique_treated,
                        "not_unique_missed": metric.not_unique_missed,
                        "received_calls": metric.received_calls,
                        "treated_calls": metric.treated_calls,
                        "miss_calls": metric.miss_calls
                    },
                    "performance": {
                        "aht": metric.aht,  # milliseconds
                        "post_processing": metric.post_processing,  # milliseconds
                        "service_level": (
                            (metric.treated_calls / metric.received_calls * 100) 
                            if metric.received_calls > 0 else 0
                        ),
                        "abandonment_rate": (
                            (metric.miss_calls / metric.received_calls * 100) 
                            if metric.received_calls > 0 else 0
                        )
                    }
                }
                service_data.append(interval_data)
            
            # Calculate summary statistics
            total_received = sum(m.received_calls for m in metrics)
            total_treated = sum(m.treated_calls for m in metrics)
            total_missed = sum(m.miss_calls for m in metrics)
            avg_aht = sum(m.aht for m in metrics) / len(metrics) if metrics else 0
            
            return {
                "status": "success",
                "data": service_data,
                "summary": {
                    "total_intervals": len(metrics),
                    "total_received": total_received,
                    "total_treated": total_treated,
                    "total_missed": total_missed,
                    "overall_service_level": (total_treated / total_received * 100) if total_received > 0 else 0,
                    "average_aht": avg_aht
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting service group data: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=300)  # 5 minutes cache
    async def get_agent_status_data(
        self, 
        agent_id: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> Dict[str, Any]:
        """
        Get agent status change tracking data.
        
        Args:
            agent_id: Agent identifier
            start_date: Start of the time range
            end_date: End of the time range
            
        Returns:
            Agent status history in Argus format
        """
        try:
            # Validate date range
            if not validate_date_range(start_date, end_date):
                raise ValueError("Invalid date range")
            
            # Get status history
            status_history = self.db.query(AgentStatusHistory).filter(
                and_(
                    AgentStatusHistory.agent_id == agent_id,
                    AgentStatusHistory.start_date >= start_date,
                    AgentStatusHistory.end_date <= end_date
                )
            ).order_by(AgentStatusHistory.start_date).all()
            
            # Format response
            status_data = []
            for status in status_history:
                duration = (status.end_date - status.start_date).total_seconds() * 1000  # milliseconds
                status_data.append({
                    "agent_id": status.agent_id,
                    "service_id": status.service_id,
                    "group_id": status.group_id,
                    "start_date": status.start_date.isoformat(),
                    "end_date": status.end_date.isoformat(),
                    "duration": int(duration),
                    "state_code": status.state_code,
                    "state_name": status.state_name
                })
            
            # Calculate status summary
            status_summary = {}
            for status in status_history:
                duration = (status.end_date - status.start_date).total_seconds() * 1000
                if status.state_code not in status_summary:
                    status_summary[status.state_code] = {
                        "state_name": status.state_name,
                        "total_duration": 0,
                        "occurrences": 0
                    }
                status_summary[status.state_code]["total_duration"] += duration
                status_summary[status.state_code]["occurrences"] += 1
            
            return {
                "status": "success",
                "data": status_data,
                "summary": status_summary,
                "total_records": len(status_data),
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting agent status data: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=300)  # 5 minutes cache
    async def get_agent_login_data(
        self, 
        agent_id: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> Dict[str, Any]:
        """
        Get agent login session management data.
        
        Args:
            agent_id: Agent identifier
            start_date: Start of the time range
            end_date: End of the time range
            
        Returns:
            Agent login history in Argus format
        """
        try:
            # Validate date range
            if not validate_date_range(start_date, end_date):
                raise ValueError("Invalid date range")
            
            # Get login history
            login_history = self.db.query(AgentLoginHistory).filter(
                and_(
                    AgentLoginHistory.agent_id == agent_id,
                    AgentLoginHistory.login_date >= start_date,
                    AgentLoginHistory.logout_date <= end_date
                )
            ).order_by(AgentLoginHistory.login_date).all()
            
            # Format response
            login_data = []
            for login in login_history:
                login_data.append({
                    "agent_id": login.agent_id,
                    "login_date": login.login_date.isoformat(),
                    "logout_date": login.logout_date.isoformat(),
                    "duration": login.duration,  # milliseconds
                    "duration_hours": login.duration / (1000 * 60 * 60)  # hours
                })
            
            # Calculate login summary
            total_duration = sum(login.duration for login in login_history)
            total_sessions = len(login_history)
            avg_session_duration = total_duration / total_sessions if total_sessions > 0 else 0
            
            return {
                "status": "success",
                "data": login_data,
                "summary": {
                    "total_sessions": total_sessions,
                    "total_duration": total_duration,
                    "total_hours": total_duration / (1000 * 60 * 60),
                    "average_session_duration": avg_session_duration,
                    "average_session_hours": avg_session_duration / (1000 * 60 * 60)
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting agent login data: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=300)  # 5 minutes cache
    async def get_agent_calls_data(
        self, 
        agent_id: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> Dict[str, Any]:
        """
        Get individual agent performance data.
        
        Args:
            agent_id: Agent identifier
            start_date: Start of the time range
            end_date: End of the time range
            
        Returns:
            Agent calls data in Argus format
        """
        try:
            # Validate date range
            if not validate_date_range(start_date, end_date):
                raise ValueError("Invalid date range")
            
            # Get calls data
            calls_data = self.db.query(AgentCallsData).filter(
                and_(
                    AgentCallsData.agent_id == agent_id,
                    AgentCallsData.start_call >= start_date,
                    AgentCallsData.end_call <= end_date
                )
            ).order_by(AgentCallsData.start_call).all()
            
            # Format response
            calls_list = []
            for call in calls_data:
                calls_list.append({
                    "agent_id": call.agent_id,
                    "service_id": call.service_id,
                    "group_id": call.group_id,
                    "start_call": call.start_call.isoformat(),
                    "end_call": call.end_call.isoformat(),
                    "duration": call.duration,  # milliseconds
                    "duration_minutes": call.duration / (1000 * 60)  # minutes
                })
            
            # Calculate performance summary
            total_calls = len(calls_data)
            total_duration = sum(call.duration for call in calls_data)
            avg_call_duration = total_duration / total_calls if total_calls > 0 else 0
            
            return {
                "status": "success",
                "data": calls_list,
                "summary": {
                    "total_calls": total_calls,
                    "total_duration": total_duration,
                    "total_minutes": total_duration / (1000 * 60),
                    "average_call_duration": avg_call_duration,
                    "average_call_minutes": avg_call_duration / (1000 * 60)
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting agent calls data: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    @cache_with_timeout(timeout=300)  # 5 minutes cache
    async def get_agent_chats_work_time(
        self, 
        agent_id: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> Dict[str, Any]:
        """
        Get agent chat work time with multi-chat overlap handling.
        
        Args:
            agent_id: Agent identifier
            start_date: Start of the time range
            end_date: End of the time range
            
        Returns:
            Agent chat work time in Argus format
        """
        try:
            # Validate date range
            if not validate_date_range(start_date, end_date):
                raise ValueError("Invalid date range")
            
            # Get chat work time data
            chat_work_data = self.db.query(AgentChatsWorkTime).filter(
                and_(
                    AgentChatsWorkTime.agent_id == agent_id,
                    AgentChatsWorkTime.work_date >= start_date.date(),
                    AgentChatsWorkTime.work_date <= end_date.date()
                )
            ).order_by(AgentChatsWorkTime.work_date).all()
            
            # Format response
            work_time_list = []
            for work_time in chat_work_data:
                work_time_list.append({
                    "agent_id": work_time.agent_id,
                    "work_date": work_time.work_date.isoformat(),
                    "work_time": work_time.work_time,  # milliseconds with at least 1 chat
                    "work_time_hours": work_time.work_time / (1000 * 60 * 60)  # hours
                })
            
            # Calculate work time summary
            total_work_time = sum(wt.work_time for wt in chat_work_data)
            total_days = len(chat_work_data)
            avg_daily_work_time = total_work_time / total_days if total_days > 0 else 0
            
            return {
                "status": "success",
                "data": work_time_list,
                "summary": {
                    "total_days": total_days,
                    "total_work_time": total_work_time,
                    "total_work_hours": total_work_time / (1000 * 60 * 60),
                    "average_daily_work_time": avg_daily_work_time,
                    "average_daily_work_hours": avg_daily_work_time / (1000 * 60 * 60)
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting agent chats work time: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }