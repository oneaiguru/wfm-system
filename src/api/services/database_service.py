"""
Database Service - Direct API Access to Core Database Features
Created: 2025-07-11

This service provides comprehensive API access to all database features including:
- Contact statistics and agent activity
- Real-time monitoring and alerts
- Schedule management and optimization
- Performance metrics and analytics
- Import/export operations
- Data validation and quality checks
"""

from typing import List, Dict, Any, Optional, Union
from datetime import datetime, date, time
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc, asc, text
from sqlalchemy.orm import joinedload
import json
import uuid
from decimal import Decimal

from src.api.db.models import (
    Service, Group, Agent, AgentCurrentStatus, ServiceGroupMetrics,
    AgentStatusHistory, AgentLoginHistory, AgentCallsData, AgentChatsWorkTime,
    GroupOnlineMetrics, Forecast, ForecastDataPoint, ForecastModel,
    StaffingPlan, StaffingRequirement, ForecastScenario, Organization,
    Department, User, IntegrationConnection, IntegrationSyncLog,
    ContactCenterData, OneCIntegrationData, WebhookEndpoint, WebhookDelivery
)


class DatabaseService:
    """Comprehensive database service for all database operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ========================================================================================
    # CONTACT STATISTICS & PERFORMANCE METRICS
    # ========================================================================================
    
    async def get_contact_statistics(
        self,
        service_ids: Optional[List[int]] = None,
        group_ids: Optional[List[int]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        interval_type: str = "15min",
        include_calculated_metrics: bool = True
    ) -> Dict[str, Any]:
        """
        Retrieve contact statistics with comprehensive filtering and aggregation.
        Supports real-time and historical data with advanced analytics.
        """
        try:
            # Base query for contact statistics
            query = """
            SELECT 
                cs.service_id,
                cs.group_id,
                cs.interval_start_time,
                cs.interval_end_time,
                cs.not_unique_received,
                cs.not_unique_treated,
                cs.not_unique_missed,
                cs.received_calls,
                cs.treated_calls,
                cs.miss_calls,
                cs.aht,
                cs.talk_time,
                cs.post_processing,
                cs.service_level,
                cs.abandonment_rate,
                cs.occupancy_rate,
                s.service_name,
                s.service_code,
                g.group_name,
                g.group_code
            FROM contact_statistics cs
            JOIN services s ON cs.service_id = s.id
            LEFT JOIN groups g ON cs.group_id = g.id
            WHERE 1=1
            """
            
            params = {}
            
            # Apply filters
            if service_ids:
                query += " AND cs.service_id = ANY(:service_ids)"
                params['service_ids'] = service_ids
            
            if group_ids:
                query += " AND cs.group_id = ANY(:group_ids)"
                params['group_ids'] = group_ids
            
            if start_date:
                query += " AND cs.interval_start_time >= :start_date"
                params['start_date'] = start_date
            
            if end_date:
                query += " AND cs.interval_end_time <= :end_date"
                params['end_date'] = end_date
            
            query += " ORDER BY cs.interval_start_time DESC"
            
            # Execute query
            result = await self.db.execute(text(query), params)
            raw_data = result.fetchall()
            
            # Process results
            statistics = []
            for row in raw_data:
                stat = {
                    'service_id': row.service_id,
                    'service_name': row.service_name,
                    'service_code': row.service_code,
                    'group_id': row.group_id,
                    'group_name': row.group_name,
                    'group_code': row.group_code,
                    'interval_start': row.interval_start_time.isoformat(),
                    'interval_end': row.interval_end_time.isoformat(),
                    'metrics': {
                        'contacts': {
                            'not_unique_received': row.not_unique_received,
                            'not_unique_treated': row.not_unique_treated,
                            'not_unique_missed': row.not_unique_missed,
                            'received_calls': row.received_calls,
                            'treated_calls': row.treated_calls,
                            'miss_calls': row.miss_calls
                        },
                        'performance': {
                            'aht': float(row.aht) if row.aht else 0,
                            'talk_time': float(row.talk_time) if row.talk_time else 0,
                            'post_processing': float(row.post_processing) if row.post_processing else 0,
                            'service_level': float(row.service_level) if row.service_level else 0,
                            'abandonment_rate': float(row.abandonment_rate) if row.abandonment_rate else 0,
                            'occupancy_rate': float(row.occupancy_rate) if row.occupancy_rate else 0
                        }
                    }
                }
                
                # Add calculated metrics if requested
                if include_calculated_metrics:
                    stat['calculated_metrics'] = {
                        'total_contacts': row.not_unique_received or 0,
                        'handled_rate': (row.not_unique_treated / row.not_unique_received * 100) if row.not_unique_received else 0,
                        'efficiency_score': self._calculate_efficiency_score(row),
                        'quality_score': self._calculate_quality_score(row)
                    }
                
                statistics.append(stat)
            
            # Calculate summary statistics
            summary = await self._calculate_summary_statistics(statistics)
            
            return {
                'statistics': statistics,
                'summary': summary,
                'total_records': len(statistics),
                'query_params': {
                    'service_ids': service_ids,
                    'group_ids': group_ids,
                    'start_date': start_date.isoformat() if start_date else None,
                    'end_date': end_date.isoformat() if end_date else None,
                    'interval_type': interval_type
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving contact statistics: {str(e)}")
    
    async def get_agent_activity(
        self,
        agent_ids: Optional[List[int]] = None,
        group_ids: Optional[List[int]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        include_performance_metrics: bool = True
    ) -> Dict[str, Any]:
        """
        Retrieve comprehensive agent activity data with performance calculations.
        """
        try:
            query = """
            SELECT 
                aa.agent_id,
                aa.group_id,
                aa.interval_start_time,
                aa.interval_end_time,
                aa.login_time,
                aa.ready_time,
                aa.not_ready_time,
                aa.talk_time,
                aa.hold_time,
                aa.wrap_time,
                aa.calls_handled,
                aa.calls_transferred,
                a.agent_code,
                a.first_name,
                a.last_name,
                a.email,
                g.group_name,
                g.group_code
            FROM agent_activity aa
            JOIN agents a ON aa.agent_id = a.id
            LEFT JOIN groups g ON aa.group_id = g.id
            WHERE 1=1
            """
            
            params = {}
            
            if agent_ids:
                query += " AND aa.agent_id = ANY(:agent_ids)"
                params['agent_ids'] = agent_ids
            
            if group_ids:
                query += " AND aa.group_id = ANY(:group_ids)"
                params['group_ids'] = group_ids
            
            if start_date:
                query += " AND aa.interval_start_time >= :start_date"
                params['start_date'] = start_date
            
            if end_date:
                query += " AND aa.interval_end_time <= :end_date"
                params['end_date'] = end_date
            
            query += " ORDER BY aa.interval_start_time DESC"
            
            result = await self.db.execute(text(query), params)
            raw_data = result.fetchall()
            
            # Process agent activity data
            activities = []
            for row in raw_data:
                activity = {
                    'agent_id': row.agent_id,
                    'agent_code': row.agent_code,
                    'agent_name': f"{row.first_name} {row.last_name}",
                    'email': row.email,
                    'group_id': row.group_id,
                    'group_name': row.group_name,
                    'group_code': row.group_code,
                    'interval_start': row.interval_start_time.isoformat(),
                    'interval_end': row.interval_end_time.isoformat(),
                    'time_allocation': {
                        'login_time': row.login_time,
                        'ready_time': row.ready_time,
                        'not_ready_time': row.not_ready_time,
                        'talk_time': row.talk_time,
                        'hold_time': row.hold_time,
                        'wrap_time': row.wrap_time
                    },
                    'call_activity': {
                        'calls_handled': row.calls_handled,
                        'calls_transferred': row.calls_transferred
                    }
                }
                
                # Add performance metrics if requested
                if include_performance_metrics:
                    activity['performance_metrics'] = {
                        'utilization_rate': (row.talk_time / row.login_time * 100) if row.login_time > 0 else 0,
                        'occupancy_rate': ((row.talk_time + row.hold_time + row.wrap_time) / row.login_time * 100) if row.login_time > 0 else 0,
                        'calls_per_hour': (row.calls_handled / (row.login_time / 3600)) if row.login_time > 0 else 0,
                        'avg_call_time': (row.talk_time / row.calls_handled) if row.calls_handled > 0 else 0
                    }
                
                activities.append(activity)
            
            return {
                'activities': activities,
                'total_records': len(activities),
                'query_params': {
                    'agent_ids': agent_ids,
                    'group_ids': group_ids,
                    'start_date': start_date.isoformat() if start_date else None,
                    'end_date': end_date.isoformat() if end_date else None
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving agent activity: {str(e)}")
    
    # ========================================================================================
    # REAL-TIME MONITORING AND ALERTS
    # ========================================================================================
    
    async def get_real_time_status(
        self,
        entity_type: str = "all",  # queue, agent, system, all
        entity_ids: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Get comprehensive real-time status across all entities.
        """
        try:
            status_data = {}
            
            if entity_type in ["queue", "all"]:
                # Get queue status
                queue_query = """
                SELECT 
                    rq.queue_id,
                    rq.queue_name,
                    rq.queue_type,
                    rq.status,
                    rq.current_calls,
                    rq.waiting_calls,
                    rq.agents_available,
                    rq.agents_busy,
                    rq.agents_total,
                    rq.avg_wait_time,
                    rq.avg_handle_time,
                    rq.service_level,
                    rq.abandon_rate,
                    rq.last_updated
                FROM realtime_queues rq
                WHERE rq.status = 'active'
                """
                
                if entity_ids:
                    queue_query += " AND rq.queue_id = ANY(:entity_ids)"
                    result = await self.db.execute(text(queue_query), {'entity_ids': entity_ids})
                else:
                    result = await self.db.execute(text(queue_query))
                
                queue_data = result.fetchall()
                status_data['queues'] = [
                    {
                        'queue_id': row.queue_id,
                        'queue_name': row.queue_name,
                        'queue_type': row.queue_type,
                        'status': row.status,
                        'current_calls': row.current_calls,
                        'waiting_calls': row.waiting_calls,
                        'agents_available': row.agents_available,
                        'agents_busy': row.agents_busy,
                        'agents_total': row.agents_total,
                        'avg_wait_time': float(row.avg_wait_time) if row.avg_wait_time else 0,
                        'avg_handle_time': float(row.avg_handle_time) if row.avg_handle_time else 0,
                        'service_level': float(row.service_level) if row.service_level else 0,
                        'abandon_rate': float(row.abandon_rate) if row.abandon_rate else 0,
                        'last_updated': row.last_updated.isoformat()
                    } for row in queue_data
                ]
            
            if entity_type in ["agent", "all"]:
                # Get agent status
                agent_query = """
                SELECT 
                    ra.agent_id,
                    ra.agent_name,
                    ra.status,
                    ra.state,
                    ra.queue_id,
                    ra.current_call_id,
                    ra.call_start_time,
                    ra.session_start_time,
                    ra.calls_handled,
                    ra.avg_handle_time,
                    ra.occupancy_rate,
                    ra.location,
                    ra.device_type,
                    ra.last_activity,
                    ra.status_changed_at
                FROM realtime_agents ra
                WHERE ra.status IN ('online', 'break', 'training')
                """
                
                if entity_ids:
                    agent_query += " AND ra.agent_id = ANY(:entity_ids)"
                    result = await self.db.execute(text(agent_query), {'entity_ids': entity_ids})
                else:
                    result = await self.db.execute(text(agent_query))
                
                agent_data = result.fetchall()
                status_data['agents'] = [
                    {
                        'agent_id': row.agent_id,
                        'agent_name': row.agent_name,
                        'status': row.status,
                        'state': row.state,
                        'queue_id': row.queue_id,
                        'current_call_id': str(row.current_call_id) if row.current_call_id else None,
                        'call_start_time': row.call_start_time.isoformat() if row.call_start_time else None,
                        'session_start_time': row.session_start_time.isoformat() if row.session_start_time else None,
                        'calls_handled': row.calls_handled,
                        'avg_handle_time': float(row.avg_handle_time) if row.avg_handle_time else 0,
                        'occupancy_rate': float(row.occupancy_rate) if row.occupancy_rate else 0,
                        'location': row.location,
                        'device_type': row.device_type,
                        'last_activity': row.last_activity.isoformat(),
                        'status_changed_at': row.status_changed_at.isoformat()
                    } for row in agent_data
                ]
            
            if entity_type in ["system", "all"]:
                # Get system metrics
                system_query = """
                SELECT 
                    COUNT(*) as total_active_sessions,
                    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_sessions,
                    SUM(CASE WHEN status = 'idle' THEN 1 ELSE 0 END) as idle_sessions,
                    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - last_activity))) as avg_session_age
                FROM realtime_sessions
                WHERE status IN ('active', 'idle')
                """
                
                result = await self.db.execute(text(system_query))
                system_data = result.fetchone()
                
                status_data['system'] = {
                    'total_active_sessions': system_data.total_active_sessions,
                    'active_sessions': system_data.active_sessions,
                    'idle_sessions': system_data.idle_sessions,
                    'avg_session_age_seconds': float(system_data.avg_session_age) if system_data.avg_session_age else 0,
                    'timestamp': datetime.now().isoformat()
                }
            
            return {
                'status_data': status_data,
                'timestamp': datetime.now().isoformat(),
                'entity_type': entity_type,
                'entity_ids': entity_ids
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving real-time status: {str(e)}")
    
    async def get_performance_alerts(
        self,
        severity: Optional[str] = None,
        entity_type: Optional[str] = None,
        active_only: bool = True
    ) -> Dict[str, Any]:
        """
        Retrieve performance alerts with filtering options.
        """
        try:
            query = """
            SELECT 
                ra.id,
                ra.alert_name,
                ra.alert_type,
                ra.entity_type,
                ra.entity_id,
                ra.metric_name,
                ra.threshold_value,
                ra.comparison_operator,
                ra.severity,
                ra.status,
                ra.is_triggered,
                ra.trigger_count,
                ra.last_triggered,
                ra.last_checked,
                ra.notification_channels,
                ra.escalation_rules
            FROM realtime_alerts ra
            WHERE 1=1
            """
            
            params = {}
            
            if severity:
                query += " AND ra.severity = :severity"
                params['severity'] = severity
            
            if entity_type:
                query += " AND ra.entity_type = :entity_type"
                params['entity_type'] = entity_type
            
            if active_only:
                query += " AND ra.status = 'active'"
            
            query += " ORDER BY ra.severity DESC, ra.last_triggered DESC"
            
            result = await self.db.execute(text(query), params)
            alert_data = result.fetchall()
            
            alerts = []
            for row in alert_data:
                alert = {
                    'id': str(row.id),
                    'alert_name': row.alert_name,
                    'alert_type': row.alert_type,
                    'entity_type': row.entity_type,
                    'entity_id': row.entity_id,
                    'metric_name': row.metric_name,
                    'threshold_value': float(row.threshold_value),
                    'comparison_operator': row.comparison_operator,
                    'severity': row.severity,
                    'status': row.status,
                    'is_triggered': row.is_triggered,
                    'trigger_count': row.trigger_count,
                    'last_triggered': row.last_triggered.isoformat() if row.last_triggered else None,
                    'last_checked': row.last_checked.isoformat() if row.last_checked else None,
                    'notification_channels': row.notification_channels,
                    'escalation_rules': row.escalation_rules
                }
                alerts.append(alert)
            
            return {
                'alerts': alerts,
                'total_count': len(alerts),
                'filters': {
                    'severity': severity,
                    'entity_type': entity_type,
                    'active_only': active_only
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving performance alerts: {str(e)}")
    
    # ========================================================================================
    # SCHEDULE MANAGEMENT
    # ========================================================================================
    
    async def get_schedule_data(
        self,
        agent_ids: Optional[List[str]] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        status: Optional[str] = None,
        include_conflicts: bool = True
    ) -> Dict[str, Any]:
        """
        Retrieve comprehensive schedule data with conflict detection.
        """
        try:
            query = """
            SELECT 
                ws.id,
                ws.agent_id,
                ws.schedule_name,
                ws.schedule_data,
                ws.shift_assignments,
                ws.total_hours,
                ws.overtime_hours,
                ws.status,
                ws.effective_date,
                ws.expiry_date,
                a.name as agent_name,
                sp.period_name,
                sp.period_type
            FROM work_schedules ws
            JOIN agents a ON ws.agent_id = a.id
            JOIN schedule_periods sp ON ws.schedule_period_id = sp.id
            WHERE 1=1
            """
            
            params = {}
            
            if agent_ids:
                query += " AND ws.agent_id = ANY(:agent_ids)"
                params['agent_ids'] = agent_ids
            
            if start_date:
                query += " AND ws.effective_date >= :start_date"
                params['start_date'] = start_date
            
            if end_date:
                query += " AND ws.effective_date <= :end_date"
                params['end_date'] = end_date
            
            if status:
                query += " AND ws.status = :status"
                params['status'] = status
            
            query += " ORDER BY ws.effective_date DESC"
            
            result = await self.db.execute(text(query), params)
            schedule_data = result.fetchall()
            
            schedules = []
            for row in schedule_data:
                schedule = {
                    'id': str(row.id),
                    'agent_id': str(row.agent_id),
                    'agent_name': row.agent_name,
                    'schedule_name': row.schedule_name,
                    'schedule_data': row.schedule_data,
                    'shift_assignments': row.shift_assignments,
                    'total_hours': float(row.total_hours) if row.total_hours else 0,
                    'overtime_hours': float(row.overtime_hours) if row.overtime_hours else 0,
                    'status': row.status,
                    'effective_date': row.effective_date.isoformat(),
                    'expiry_date': row.expiry_date.isoformat() if row.expiry_date else None,
                    'period_name': row.period_name,
                    'period_type': row.period_type
                }
                
                # Add conflict data if requested
                if include_conflicts:
                    conflicts = await self._get_schedule_conflicts(row.id)
                    schedule['conflicts'] = conflicts
                
                schedules.append(schedule)
            
            return {
                'schedules': schedules,
                'total_count': len(schedules),
                'filters': {
                    'agent_ids': agent_ids,
                    'start_date': start_date.isoformat() if start_date else None,
                    'end_date': end_date.isoformat() if end_date else None,
                    'status': status
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving schedule data: {str(e)}")
    
    # ========================================================================================
    # FORECASTING AND ANALYTICS
    # ========================================================================================
    
    async def get_forecast_data(
        self,
        forecast_type: Optional[str] = None,
        organization_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        include_data_points: bool = True
    ) -> Dict[str, Any]:
        """
        Retrieve comprehensive forecast data with data points and accuracy metrics.
        """
        try:
            query = """
            SELECT 
                f.id,
                f.name,
                f.description,
                f.forecast_type,
                f.method,
                f.granularity,
                f.start_date,
                f.end_date,
                f.department_id,
                f.service_id,
                f.organization_id,
                f.data,
                f.metadata,
                f.status,
                f.version,
                f.accuracy_metrics,
                f.last_validation,
                f.created_at,
                f.updated_at
            FROM forecasts f
            WHERE 1=1
            """
            
            params = {}
            
            if forecast_type:
                query += " AND f.forecast_type = :forecast_type"
                params['forecast_type'] = forecast_type
            
            if organization_id:
                query += " AND f.organization_id = :organization_id"
                params['organization_id'] = uuid.UUID(organization_id)
            
            if start_date:
                query += " AND f.start_date >= :start_date"
                params['start_date'] = start_date
            
            if end_date:
                query += " AND f.end_date <= :end_date"
                params['end_date'] = end_date
            
            query += " ORDER BY f.created_at DESC"
            
            result = await self.db.execute(text(query), params)
            forecast_data = result.fetchall()
            
            forecasts = []
            for row in forecast_data:
                forecast = {
                    'id': str(row.id),
                    'name': row.name,
                    'description': row.description,
                    'forecast_type': row.forecast_type,
                    'method': row.method,
                    'granularity': row.granularity,
                    'start_date': row.start_date.isoformat(),
                    'end_date': row.end_date.isoformat(),
                    'department_id': str(row.department_id) if row.department_id else None,
                    'service_id': row.service_id,
                    'organization_id': str(row.organization_id) if row.organization_id else None,
                    'data': row.data,
                    'metadata': row.metadata,
                    'status': row.status,
                    'version': row.version,
                    'accuracy_metrics': row.accuracy_metrics,
                    'last_validation': row.last_validation.isoformat() if row.last_validation else None,
                    'created_at': row.created_at.isoformat(),
                    'updated_at': row.updated_at.isoformat()
                }
                
                # Add data points if requested
                if include_data_points:
                    data_points = await self._get_forecast_data_points(row.id)
                    forecast['data_points'] = data_points
                
                forecasts.append(forecast)
            
            return {
                'forecasts': forecasts,
                'total_count': len(forecasts),
                'filters': {
                    'forecast_type': forecast_type,
                    'organization_id': organization_id,
                    'start_date': start_date.isoformat() if start_date else None,
                    'end_date': end_date.isoformat() if end_date else None
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving forecast data: {str(e)}")
    
    # ========================================================================================
    # INTEGRATION MANAGEMENT
    # ========================================================================================
    
    async def get_integration_status(
        self,
        integration_type: Optional[str] = None,
        organization_id: Optional[str] = None,
        include_sync_logs: bool = True
    ) -> Dict[str, Any]:
        """
        Get comprehensive integration status and sync information.
        """
        try:
            query = """
            SELECT 
                ic.id,
                ic.name,
                ic.integration_type,
                ic.endpoint_url,
                ic.authentication_type,
                ic.config,
                ic.mapping_rules,
                ic.status,
                ic.last_sync,
                ic.last_error,
                ic.organization_id,
                ic.created_at,
                ic.updated_at
            FROM integration_connections ic
            WHERE 1=1
            """
            
            params = {}
            
            if integration_type:
                query += " AND ic.integration_type = :integration_type"
                params['integration_type'] = integration_type
            
            if organization_id:
                query += " AND ic.organization_id = :organization_id"
                params['organization_id'] = uuid.UUID(organization_id)
            
            query += " ORDER BY ic.created_at DESC"
            
            result = await self.db.execute(text(query), params)
            integration_data = result.fetchall()
            
            integrations = []
            for row in integration_data:
                integration = {
                    'id': str(row.id),
                    'name': row.name,
                    'integration_type': row.integration_type,
                    'endpoint_url': row.endpoint_url,
                    'authentication_type': row.authentication_type,
                    'config': row.config,
                    'mapping_rules': row.mapping_rules,
                    'status': row.status,
                    'last_sync': row.last_sync.isoformat() if row.last_sync else None,
                    'last_error': row.last_error,
                    'organization_id': str(row.organization_id) if row.organization_id else None,
                    'created_at': row.created_at.isoformat(),
                    'updated_at': row.updated_at.isoformat()
                }
                
                # Add sync logs if requested
                if include_sync_logs:
                    sync_logs = await self._get_integration_sync_logs(row.id)
                    integration['sync_logs'] = sync_logs
                
                integrations.append(integration)
            
            return {
                'integrations': integrations,
                'total_count': len(integrations),
                'filters': {
                    'integration_type': integration_type,
                    'organization_id': organization_id
                }
            }
            
        except Exception as e:
            raise Exception(f"Error retrieving integration status: {str(e)}")
    
    # ========================================================================================
    # DATA VALIDATION AND QUALITY
    # ========================================================================================
    
    async def validate_data_quality(
        self,
        table_name: str,
        validation_rules: Optional[List[str]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Comprehensive data quality validation with detailed reporting.
        """
        try:
            validation_results = {
                'table_name': table_name,
                'validation_timestamp': datetime.now().isoformat(),
                'quality_score': 0.0,
                'issues_found': [],
                'recommendations': [],
                'statistics': {}
            }
            
            # Table-specific validation
            if table_name == 'contact_statistics':
                validation_results = await self._validate_contact_statistics(
                    validation_results, start_date, end_date
                )
            elif table_name == 'agent_activity':
                validation_results = await self._validate_agent_activity(
                    validation_results, start_date, end_date
                )
            elif table_name == 'work_schedules':
                validation_results = await self._validate_work_schedules(
                    validation_results, start_date, end_date
                )
            else:
                # Generic validation
                validation_results = await self._validate_generic_table(
                    validation_results, table_name, start_date, end_date
                )
            
            # Calculate overall quality score
            validation_results['quality_score'] = self._calculate_quality_score_from_issues(
                validation_results['issues_found']
            )
            
            return validation_results
            
        except Exception as e:
            raise Exception(f"Error validating data quality: {str(e)}")
    
    # ========================================================================================
    # HELPER METHODS
    # ========================================================================================
    
    def _calculate_efficiency_score(self, row) -> float:
        """Calculate efficiency score based on performance metrics."""
        if not row.not_unique_received:
            return 0.0
        
        handle_rate = row.not_unique_treated / row.not_unique_received
        service_level = (row.service_level or 0) / 100
        
        # Weight factors
        efficiency = (handle_rate * 0.6) + (service_level * 0.4)
        return round(efficiency * 100, 2)
    
    def _calculate_quality_score(self, row) -> float:
        """Calculate quality score based on service metrics."""
        abandonment_penalty = (row.abandonment_rate or 0) / 100
        service_level_score = (row.service_level or 0) / 100
        
        quality = service_level_score - abandonment_penalty
        return round(max(0, quality) * 100, 2)
    
    async def _calculate_summary_statistics(self, statistics: List[Dict]) -> Dict[str, Any]:
        """Calculate summary statistics for contact data."""
        if not statistics:
            return {}
        
        total_received = sum(stat['metrics']['contacts']['not_unique_received'] for stat in statistics)
        total_treated = sum(stat['metrics']['contacts']['not_unique_treated'] for stat in statistics)
        
        return {
            'total_contacts_received': total_received,
            'total_contacts_treated': total_treated,
            'overall_handle_rate': (total_treated / total_received * 100) if total_received > 0 else 0,
            'average_service_level': sum(stat['metrics']['performance']['service_level'] for stat in statistics) / len(statistics),
            'intervals_analyzed': len(statistics)
        }
    
    async def _get_schedule_conflicts(self, schedule_id: str) -> List[Dict[str, Any]]:
        """Get conflicts for a specific schedule."""
        try:
            query = """
            SELECT 
                sc.id,
                sc.conflict_type,
                sc.severity,
                sc.conflict_description,
                sc.affected_agents,
                sc.affected_shifts,
                sc.resolution_status,
                sc.resolution_notes,
                sc.auto_resolvable,
                sc.suggested_resolution,
                sc.detection_date
            FROM schedule_conflicts sc
            WHERE sc.schedule_id = :schedule_id
            ORDER BY sc.detection_date DESC
            """
            
            result = await self.db.execute(text(query), {'schedule_id': uuid.UUID(schedule_id)})
            conflict_data = result.fetchall()
            
            conflicts = []
            for row in conflict_data:
                conflict = {
                    'id': str(row.id),
                    'conflict_type': row.conflict_type,
                    'severity': row.severity,
                    'description': row.conflict_description,
                    'affected_agents': row.affected_agents,
                    'affected_shifts': row.affected_shifts,
                    'resolution_status': row.resolution_status,
                    'resolution_notes': row.resolution_notes,
                    'auto_resolvable': row.auto_resolvable,
                    'suggested_resolution': row.suggested_resolution,
                    'detection_date': row.detection_date.isoformat()
                }
                conflicts.append(conflict)
            
            return conflicts
            
        except Exception as e:
            return []
    
    async def _get_forecast_data_points(self, forecast_id: str) -> List[Dict[str, Any]]:
        """Get data points for a specific forecast."""
        try:
            query = """
            SELECT 
                fdp.id,
                fdp.timestamp,
                fdp.date,
                fdp.predicted_value,
                fdp.actual_value,
                fdp.confidence_interval_lower,
                fdp.confidence_interval_upper,
                fdp.seasonal_factor,
                fdp.trend_factor,
                fdp.holiday_factor
            FROM forecast_data_points fdp
            WHERE fdp.forecast_id = :forecast_id
            ORDER BY fdp.timestamp
            """
            
            result = await self.db.execute(text(query), {'forecast_id': uuid.UUID(forecast_id)})
            data_points = result.fetchall()
            
            points = []
            for row in data_points:
                point = {
                    'id': str(row.id),
                    'timestamp': row.timestamp.isoformat(),
                    'date': row.date.isoformat(),
                    'predicted_value': float(row.predicted_value),
                    'actual_value': float(row.actual_value) if row.actual_value else None,
                    'confidence_interval_lower': float(row.confidence_interval_lower) if row.confidence_interval_lower else None,
                    'confidence_interval_upper': float(row.confidence_interval_upper) if row.confidence_interval_upper else None,
                    'seasonal_factor': float(row.seasonal_factor) if row.seasonal_factor else 1.0,
                    'trend_factor': float(row.trend_factor) if row.trend_factor else 1.0,
                    'holiday_factor': float(row.holiday_factor) if row.holiday_factor else 1.0
                }
                points.append(point)
            
            return points
            
        except Exception as e:
            return []
    
    async def _get_integration_sync_logs(self, connection_id: str) -> List[Dict[str, Any]]:
        """Get sync logs for a specific integration connection."""
        try:
            query = """
            SELECT 
                isl.id,
                isl.sync_type,
                isl.direction,
                isl.status,
                isl.start_time,
                isl.end_time,
                isl.records_processed,
                isl.records_successful,
                isl.records_failed,
                isl.error_details
            FROM integration_sync_logs isl
            WHERE isl.connection_id = :connection_id
            ORDER BY isl.start_time DESC
            LIMIT 10
            """
            
            result = await self.db.execute(text(query), {'connection_id': uuid.UUID(connection_id)})
            sync_logs = result.fetchall()
            
            logs = []
            for row in sync_logs:
                log = {
                    'id': str(row.id),
                    'sync_type': row.sync_type,
                    'direction': row.direction,
                    'status': row.status,
                    'start_time': row.start_time.isoformat(),
                    'end_time': row.end_time.isoformat() if row.end_time else None,
                    'records_processed': row.records_processed,
                    'records_successful': row.records_successful,
                    'records_failed': row.records_failed,
                    'error_details': row.error_details
                }
                logs.append(log)
            
            return logs
            
        except Exception as e:
            return []
    
    async def _validate_contact_statistics(self, validation_results: Dict, start_date: Optional[datetime], end_date: Optional[datetime]) -> Dict[str, Any]:
        """Validate contact statistics data quality."""
        issues = []
        
        # Check for missing data
        query = """
        SELECT COUNT(*) as total_records,
               COUNT(CASE WHEN not_unique_received IS NULL THEN 1 END) as null_received,
               COUNT(CASE WHEN not_unique_treated IS NULL THEN 1 END) as null_treated,
               COUNT(CASE WHEN service_level IS NULL THEN 1 END) as null_service_level,
               COUNT(CASE WHEN not_unique_received < 0 THEN 1 END) as negative_received,
               COUNT(CASE WHEN not_unique_treated > not_unique_received THEN 1 END) as invalid_treated
        FROM contact_statistics
        WHERE 1=1
        """
        
        params = {}
        if start_date:
            query += " AND interval_start_time >= :start_date"
            params['start_date'] = start_date
        if end_date:
            query += " AND interval_end_time <= :end_date"
            params['end_date'] = end_date
        
        result = await self.db.execute(text(query), params)
        stats = result.fetchone()
        
        if stats.null_received > 0:
            issues.append({
                'type': 'missing_data',
                'field': 'not_unique_received',
                'count': stats.null_received,
                'severity': 'high'
            })
        
        if stats.negative_received > 0:
            issues.append({
                'type': 'invalid_data',
                'field': 'not_unique_received',
                'count': stats.negative_received,
                'severity': 'critical'
            })
        
        if stats.invalid_treated > 0:
            issues.append({
                'type': 'logical_error',
                'field': 'not_unique_treated',
                'count': stats.invalid_treated,
                'severity': 'high'
            })
        
        validation_results['issues_found'] = issues
        validation_results['statistics'] = {
            'total_records': stats.total_records,
            'null_received': stats.null_received,
            'null_treated': stats.null_treated,
            'null_service_level': stats.null_service_level,
            'negative_received': stats.negative_received,
            'invalid_treated': stats.invalid_treated
        }
        
        return validation_results
    
    async def _validate_agent_activity(self, validation_results: Dict, start_date: Optional[datetime], end_date: Optional[datetime]) -> Dict[str, Any]:
        """Validate agent activity data quality."""
        issues = []
        
        # Check for logical inconsistencies
        query = """
        SELECT COUNT(*) as total_records,
               COUNT(CASE WHEN login_time < ready_time + not_ready_time + talk_time + hold_time + wrap_time THEN 1 END) as time_inconsistency,
               COUNT(CASE WHEN login_time IS NULL THEN 1 END) as null_login_time,
               COUNT(CASE WHEN calls_handled < 0 THEN 1 END) as negative_calls
        FROM agent_activity
        WHERE 1=1
        """
        
        params = {}
        if start_date:
            query += " AND interval_start_time >= :start_date"
            params['start_date'] = start_date
        if end_date:
            query += " AND interval_end_time <= :end_date"
            params['end_date'] = end_date
        
        result = await self.db.execute(text(query), params)
        stats = result.fetchone()
        
        if stats.time_inconsistency > 0:
            issues.append({
                'type': 'logical_error',
                'field': 'time_allocation',
                'count': stats.time_inconsistency,
                'severity': 'high'
            })
        
        if stats.null_login_time > 0:
            issues.append({
                'type': 'missing_data',
                'field': 'login_time',
                'count': stats.null_login_time,
                'severity': 'medium'
            })
        
        if stats.negative_calls > 0:
            issues.append({
                'type': 'invalid_data',
                'field': 'calls_handled',
                'count': stats.negative_calls,
                'severity': 'high'
            })
        
        validation_results['issues_found'] = issues
        validation_results['statistics'] = {
            'total_records': stats.total_records,
            'time_inconsistency': stats.time_inconsistency,
            'null_login_time': stats.null_login_time,
            'negative_calls': stats.negative_calls
        }
        
        return validation_results
    
    async def _validate_work_schedules(self, validation_results: Dict, start_date: Optional[datetime], end_date: Optional[datetime]) -> Dict[str, Any]:
        """Validate work schedules data quality."""
        issues = []
        
        # Check for schedule conflicts and inconsistencies
        query = """
        SELECT COUNT(*) as total_records,
               COUNT(CASE WHEN total_hours < 0 THEN 1 END) as negative_hours,
               COUNT(CASE WHEN total_hours > 168 THEN 1 END) as excessive_hours,
               COUNT(CASE WHEN schedule_data IS NULL THEN 1 END) as null_schedule_data
        FROM work_schedules
        WHERE 1=1
        """
        
        params = {}
        if start_date:
            query += " AND effective_date >= :start_date"
            params['start_date'] = start_date.date() if hasattr(start_date, 'date') else start_date
        if end_date:
            query += " AND effective_date <= :end_date"
            params['end_date'] = end_date.date() if hasattr(end_date, 'date') else end_date
        
        result = await self.db.execute(text(query), params)
        stats = result.fetchone()
        
        if stats.negative_hours > 0:
            issues.append({
                'type': 'invalid_data',
                'field': 'total_hours',
                'count': stats.negative_hours,
                'severity': 'high'
            })
        
        if stats.excessive_hours > 0:
            issues.append({
                'type': 'logical_error',
                'field': 'total_hours',
                'count': stats.excessive_hours,
                'severity': 'medium'
            })
        
        if stats.null_schedule_data > 0:
            issues.append({
                'type': 'missing_data',
                'field': 'schedule_data',
                'count': stats.null_schedule_data,
                'severity': 'high'
            })
        
        validation_results['issues_found'] = issues
        validation_results['statistics'] = {
            'total_records': stats.total_records,
            'negative_hours': stats.negative_hours,
            'excessive_hours': stats.excessive_hours,
            'null_schedule_data': stats.null_schedule_data
        }
        
        return validation_results
    
    async def _validate_generic_table(self, validation_results: Dict, table_name: str, start_date: Optional[datetime], end_date: Optional[datetime]) -> Dict[str, Any]:
        """Generic table validation."""
        issues = []
        
        # Basic record count
        query = f"SELECT COUNT(*) as total_records FROM {table_name}"
        result = await self.db.execute(text(query))
        stats = result.fetchone()
        
        validation_results['issues_found'] = issues
        validation_results['statistics'] = {
            'total_records': stats.total_records
        }
        
        return validation_results
    
    def _calculate_quality_score_from_issues(self, issues: List[Dict]) -> float:
        """Calculate quality score based on issues found."""
        if not issues:
            return 100.0
        
        penalty = 0.0
        for issue in issues:
            if issue['severity'] == 'critical':
                penalty += 30
            elif issue['severity'] == 'high':
                penalty += 20
            elif issue['severity'] == 'medium':
                penalty += 10
            else:
                penalty += 5
        
        return max(0.0, 100.0 - penalty)