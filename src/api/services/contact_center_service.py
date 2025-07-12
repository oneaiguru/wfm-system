"""
Contact Center Integration Service

This service handles all communication with Contact Center systems (Argus-compatible).
Provides enhanced integration features building on existing Argus endpoints:
- Historical data retrieval with enhanced filtering
- Real-time data synchronization
- Bulk import/export operations
- Data validation and transformation

Integration points:
- Leverages existing Argus-compatible endpoints
- WebSocket system for real-time updates
- Personnel API for agent synchronization
"""

import asyncio
import json
import logging
from datetime import datetime, date, timedelta
from typing import Dict, Any, List, Optional, Union, Tuple
from uuid import UUID

import aiohttp
import pandas as pd
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, insert, delete, func, and_, or_
from sqlalchemy.orm import selectinload

from ..db.models import (
    IntegrationConnection, IntegrationSyncLog, ContactCenterData,
    ServiceGroupMetrics, AgentStatusHistory, AgentLoginHistory,
    AgentCallsData, AgentChatsWorkTime, AgentCurrentStatus,
    GroupOnlineMetrics, Agent, Service, Group
)
from ..v1.schemas.integrations import (
    ContactCenterHistoricRequest, ContactCenterRealtimeData,
    ContactCenterBulkImport, ContactCenterExportRequest,
    ContactCenterValidationRequest, ContactCenterServiceGroupData,
    ContactCenterAgentStatusData, ContactCenterAgentLoginData,
    ContactCenterAgentCallsData, ContactCenterAgentChatsWorkTime,
    IntegrationResponse, BulkOperationResponse, SyncOperationResponse
)
from ..core.config import get_settings
from ..utils.cache import cache_manager
from ..websocket.events import emit_integration_event

# Import existing Argus services for enhanced compatibility
from ..services.historic_service import HistoricService
from ..services.online_service import OnlineService


logger = logging.getLogger(__name__)
settings = get_settings()


class ContactCenterService:
    """Service for Contact Center integration operations"""
    
    def __init__(self, connection: IntegrationConnection):
        self.connection = connection
        self.base_url = connection.endpoint_url
        self.auth_config = connection.credentials
        self.config = connection.config or {}
        self.session = None
        
        # Initialize existing services for enhanced compatibility
        self.historic_service = HistoricService()
        self.online_service = OnlineService()
        
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    def _get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers for Contact Center requests"""
        headers = {"Content-Type": "application/json"}
        
        if self.connection.authentication_type == "basic":
            import base64
            username = self.auth_config.get("username", "")
            password = self.auth_config.get("password", "")
            credentials = base64.b64encode(f"{username}:{password}".encode()).decode()
            headers["Authorization"] = f"Basic {credentials}"
        elif self.connection.authentication_type == "api_key":
            api_key = self.auth_config.get("api_key", "")
            headers["X-API-Key"] = api_key
        elif self.connection.authentication_type == "bearer":
            token = self.auth_config.get("token", "")
            headers["Authorization"] = f"Bearer {token}"
            
        return headers
    
    async def test_connection(self) -> Dict[str, Any]:
        """Test connection to Contact Center system"""
        try:
            async with aiohttp.ClientSession() as session:
                headers = self._get_auth_headers()
                test_url = f"{self.base_url}/api/test"
                
                start_time = datetime.utcnow()
                async with session.get(test_url, headers=headers, timeout=30) as response:
                    end_time = datetime.utcnow()
                    response_time = (end_time - start_time).total_seconds() * 1000
                    
                    if response.status == 200:
                        return {
                            "success": True,
                            "status_code": response.status,
                            "response_time_ms": response_time,
                            "message": "Connection successful"
                        }
                    else:
                        return {
                            "success": False,
                            "status_code": response.status,
                            "response_time_ms": response_time,
                            "message": f"Connection failed with status {response.status}"
                        }
                        
        except Exception as e:
            logger.error(f"Contact Center connection test failed: {str(e)}")
            return {
                "success": False,
                "status_code": 0,
                "response_time_ms": 0,
                "message": f"Connection failed: {str(e)}"
            }
    
    # ========================================================================
    # HISTORICAL DATA METHODS (Enhanced Argus compatibility)
    # ========================================================================
    
    async def get_service_group_data(
        self, 
        request: ContactCenterHistoricRequest,
        db: AsyncSession
    ) -> List[ContactCenterServiceGroupData]:
        """Get service group data with enhanced filtering"""
        try:
            # Use existing historic service as base
            historic_data = await self.historic_service.get_service_group_data(
                start_date=request.start_date,
                end_date=request.end_date,
                interval_minutes=request.interval_minutes,
                service_groups=request.service_groups,
                db=db
            )
            
            # Transform to enhanced format
            enhanced_data = []
            for data in historic_data:
                enhanced_item = ContactCenterServiceGroupData(
                    service_id=data.service_id,
                    group_id=data.group_id,
                    interval_start=data.start_interval,
                    interval_end=data.end_interval,
                    metrics={
                        "not_unique_received": data.not_unique_received,
                        "not_unique_treated": data.not_unique_treated,
                        "not_unique_missed": data.not_unique_missed,
                        "received_calls": data.received_calls,
                        "treated_calls": data.treated_calls,
                        "miss_calls": data.miss_calls,
                        "aht": data.aht,
                        "post_processing": data.post_processing,
                        # Enhanced metrics
                        "service_level": self._calculate_service_level(data),
                        "abandonment_rate": self._calculate_abandonment_rate(data),
                        "occupancy_rate": self._calculate_occupancy_rate(data)
                    }
                )
                enhanced_data.append(enhanced_item)
            
            return enhanced_data
            
        except Exception as e:
            logger.error(f"Error getting service group data: {str(e)}")
            return []
    
    async def get_agent_status_data(
        self, 
        request: ContactCenterHistoricRequest,
        db: AsyncSession
    ) -> List[ContactCenterAgentStatusData]:
        """Get agent status data with enhanced filtering"""
        try:
            # Build query with filters
            query = select(AgentStatusHistory).where(
                and_(
                    AgentStatusHistory.start_date >= request.start_date,
                    AgentStatusHistory.end_date <= request.end_date
                )
            )
            
            # Apply agent filter if provided
            if request.agents:
                query = query.where(AgentStatusHistory.agent_id.in_(request.agents))
            
            # Apply service group filter if provided
            if request.service_groups:
                query = query.where(AgentStatusHistory.group_id.in_(request.service_groups))
            
            result = await db.execute(query)
            status_data = result.scalars().all()
            
            # Transform to response format
            response_data = []
            for status in status_data:
                response_item = ContactCenterAgentStatusData(
                    agent_id=status.agent_id,
                    start_date=status.start_date,
                    end_date=status.end_date,
                    state_code=status.state_code,
                    state_name=status.state_name,
                    service_id=status.service_id,
                    group_id=status.group_id
                )
                response_data.append(response_item)
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error getting agent status data: {str(e)}")
            return []
    
    async def get_agent_login_data(
        self, 
        request: ContactCenterHistoricRequest,
        db: AsyncSession
    ) -> List[ContactCenterAgentLoginData]:
        """Get agent login data with enhanced filtering"""
        try:
            # Build query with filters
            query = select(AgentLoginHistory).where(
                and_(
                    AgentLoginHistory.login_date >= request.start_date,
                    AgentLoginHistory.logout_date <= request.end_date
                )
            )
            
            # Apply agent filter if provided
            if request.agents:
                query = query.where(AgentLoginHistory.agent_id.in_(request.agents))
            
            result = await db.execute(query)
            login_data = result.scalars().all()
            
            # Transform to response format
            response_data = []
            for login in login_data:
                response_item = ContactCenterAgentLoginData(
                    agent_id=login.agent_id,
                    login_date=login.login_date,
                    logout_date=login.logout_date,
                    duration=login.duration
                )
                response_data.append(response_item)
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error getting agent login data: {str(e)}")
            return []
    
    async def get_agent_calls_data(
        self, 
        request: ContactCenterHistoricRequest,
        db: AsyncSession
    ) -> List[ContactCenterAgentCallsData]:
        """Get agent calls data with enhanced filtering"""
        try:
            # Build query with filters
            query = select(AgentCallsData).where(
                and_(
                    AgentCallsData.start_call >= request.start_date,
                    AgentCallsData.end_call <= request.end_date
                )
            )
            
            # Apply agent filter if provided
            if request.agents:
                query = query.where(AgentCallsData.agent_id.in_(request.agents))
            
            # Apply service group filter if provided
            if request.service_groups:
                query = query.where(AgentCallsData.group_id.in_(request.service_groups))
            
            result = await db.execute(query)
            calls_data = result.scalars().all()
            
            # Transform to response format
            response_data = []
            for call in calls_data:
                response_item = ContactCenterAgentCallsData(
                    agent_id=call.agent_id,
                    service_id=call.service_id,
                    group_id=call.group_id,
                    start_call=call.start_call,
                    end_call=call.end_call,
                    duration=call.duration
                )
                response_data.append(response_item)
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error getting agent calls data: {str(e)}")
            return []
    
    async def get_agent_chats_work_time(
        self, 
        request: ContactCenterHistoricRequest,
        db: AsyncSession
    ) -> List[ContactCenterAgentChatsWorkTime]:
        """Get agent chats work time with enhanced filtering"""
        try:
            # Build query with filters
            query = select(AgentChatsWorkTime).where(
                and_(
                    AgentChatsWorkTime.work_date >= request.start_date.date(),
                    AgentChatsWorkTime.work_date <= request.end_date.date()
                )
            )
            
            # Apply agent filter if provided
            if request.agents:
                query = query.where(AgentChatsWorkTime.agent_id.in_(request.agents))
            
            result = await db.execute(query)
            chats_data = result.scalars().all()
            
            # Transform to response format
            response_data = []
            for chat in chats_data:
                response_item = ContactCenterAgentChatsWorkTime(
                    agent_id=chat.agent_id,
                    work_date=chat.work_date,
                    work_time=chat.work_time
                )
                response_data.append(response_item)
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error getting agent chats work time: {str(e)}")
            return []
    
    # ========================================================================
    # REAL-TIME DATA METHODS
    # ========================================================================
    
    async def process_realtime_status(
        self,
        status_data: ContactCenterRealtimeData,
        db: AsyncSession
    ) -> IntegrationResponse:
        """Process real-time status data (fire-and-forget)"""
        try:
            # Update current status
            await self._update_current_status(status_data, db)
            
            # Store in contact center data table
            cc_data = ContactCenterData(
                data_type="agent_status",
                timestamp=datetime.utcnow(),
                date=datetime.utcnow().date(),
                interval_start=status_data.start_time,
                interval_end=status_data.start_time + timedelta(seconds=status_data.duration_seconds or 0),
                agent_id=status_data.agent_id,
                queue_id=status_data.queue_id,
                service_group=status_data.service_group,
                metrics={
                    "status": status_data.status,
                    "start_time": status_data.start_time.isoformat(),
                    "duration_seconds": status_data.duration_seconds,
                    "calls_handled": status_data.calls_handled
                },
                source_system="realtime_api",
                raw_data=status_data.dict()
            )
            db.add(cc_data)
            await db.commit()
            
            # Emit real-time event
            await emit_integration_event(
                event_type="contact_center.agent.status.updated",
                payload={
                    "agent_id": status_data.agent_id,
                    "status": status_data.status,
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            
            return IntegrationResponse(
                success=True,
                message="Real-time status processed successfully"
            )
            
        except Exception as e:
            logger.error(f"Error processing real-time status: {str(e)}")
            return IntegrationResponse(
                success=False,
                message=f"Error processing real-time status: {str(e)}"
            )
    
    async def get_online_agent_status(self, db: AsyncSession) -> List[Dict[str, Any]]:
        """Get current online agent status"""
        try:
            query = select(AgentCurrentStatus).options(
                selectinload(AgentCurrentStatus.agent)
            )
            result = await db.execute(query)
            current_statuses = result.scalars().all()
            
            status_data = []
            for status in current_statuses:
                status_item = {
                    "agent_id": status.agent_id,
                    "state_code": status.state_code,
                    "state_name": status.state_name,
                    "start_date": status.start_date.isoformat(),
                    "duration_seconds": (datetime.utcnow() - status.start_date).total_seconds(),
                    "updated_at": status.updated_at.isoformat()
                }
                status_data.append(status_item)
            
            return status_data
            
        except Exception as e:
            logger.error(f"Error getting online agent status: {str(e)}")
            return []
    
    async def get_online_groups_load(self, db: AsyncSession) -> List[Dict[str, Any]]:
        """Get current groups load metrics"""
        try:
            query = select(GroupOnlineMetrics)
            result = await db.execute(query)
            metrics = result.scalars().all()
            
            load_data = []
            for metric in metrics:
                load_item = {
                    "service_id": metric.service_id,
                    "group_id": metric.group_id,
                    "call_number": metric.call_number,
                    "operator_number": metric.operator_number,
                    "awt": metric.awt,
                    "call_processing": metric.call_processing,
                    "call_received": metric.call_received,
                    "call_answered": metric.call_answered,
                    "call_answered_tst": metric.call_answered_tst,
                    "aht": metric.aht,
                    "acd": metric.acd,
                    "updated_at": metric.updated_at.isoformat()
                }
                load_data.append(load_item)
            
            return load_data
            
        except Exception as e:
            logger.error(f"Error getting online groups load: {str(e)}")
            return []
    
    async def get_queue_metrics(self, db: AsyncSession) -> List[Dict[str, Any]]:
        """Get real-time queue metrics"""
        try:
            # Get recent metrics from the last 5 minutes
            five_minutes_ago = datetime.utcnow() - timedelta(minutes=5)
            
            query = select(ContactCenterData).where(
                and_(
                    ContactCenterData.data_type == "queue_metrics",
                    ContactCenterData.timestamp >= five_minutes_ago
                )
            )
            result = await db.execute(query)
            recent_metrics = result.scalars().all()
            
            metrics_data = []
            for metric in recent_metrics:
                metric_item = {
                    "queue_id": metric.queue_id,
                    "service_group": metric.service_group,
                    "timestamp": metric.timestamp.isoformat(),
                    "metrics": metric.metrics
                }
                metrics_data.append(metric_item)
            
            return metrics_data
            
        except Exception as e:
            logger.error(f"Error getting queue metrics: {str(e)}")
            return []
    
    # ========================================================================
    # BULK OPERATIONS
    # ========================================================================
    
    async def bulk_import_data(
        self,
        import_request: ContactCenterBulkImport,
        db: AsyncSession
    ) -> BulkOperationResponse:
        """Bulk import contact center data"""
        start_time = datetime.utcnow()
        
        try:
            total_records = len(import_request.data)
            successful_records = 0
            failed_records = 0
            errors = []
            
            # Validate data if requested
            if import_request.validate_before_import:
                validation_errors = await self._validate_bulk_data(
                    import_request.data_type,
                    import_request.data
                )
                if validation_errors:
                    return BulkOperationResponse(
                        total_records=total_records,
                        successful_records=0,
                        failed_records=total_records,
                        errors=validation_errors,
                        processing_time_ms=0
                    )
            
            # Process data in batches
            batch_size = import_request.batch_size
            for i in range(0, total_records, batch_size):
                batch = import_request.data[i:i + batch_size]
                
                batch_success, batch_errors = await self._process_batch(
                    import_request.data_type,
                    batch,
                    import_request.update_existing,
                    db
                )
                
                successful_records += batch_success
                failed_records += len(batch_errors)
                errors.extend(batch_errors)
            
            processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            return BulkOperationResponse(
                total_records=total_records,
                successful_records=successful_records,
                failed_records=failed_records,
                errors=errors if errors else None,
                processing_time_ms=int(processing_time)
            )
            
        except Exception as e:
            logger.error(f"Error in bulk import: {str(e)}")
            processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            return BulkOperationResponse(
                total_records=len(import_request.data),
                successful_records=0,
                failed_records=len(import_request.data),
                errors=[{"error": str(e)}],
                processing_time_ms=int(processing_time)
            )
    
    async def export_data(
        self,
        export_request: ContactCenterExportRequest,
        db: AsyncSession
    ) -> Dict[str, Any]:
        """Export contact center data"""
        try:
            # Build query based on data type
            query = select(ContactCenterData).where(
                and_(
                    ContactCenterData.data_type == export_request.data_type,
                    ContactCenterData.timestamp >= export_request.start_date,
                    ContactCenterData.timestamp <= export_request.end_date
                )
            )
            
            # Apply additional filters
            if export_request.filters:
                for key, value in export_request.filters.items():
                    if key == "agent_id":
                        query = query.where(ContactCenterData.agent_id == value)
                    elif key == "service_group":
                        query = query.where(ContactCenterData.service_group == value)
            
            result = await db.execute(query)
            data = result.scalars().all()
            
            # Transform to export format
            export_data = []
            for item in data:
                export_item = {
                    "id": str(item.id),
                    "data_type": item.data_type,
                    "timestamp": item.timestamp.isoformat(),
                    "agent_id": item.agent_id,
                    "queue_id": item.queue_id,
                    "service_group": item.service_group,
                    "metrics": item.metrics
                }
                
                if export_request.include_raw_data:
                    export_item["raw_data"] = item.raw_data
                
                export_data.append(export_item)
            
            return {
                "data": export_data,
                "total_records": len(export_data),
                "export_timestamp": datetime.utcnow().isoformat(),
                "parameters": export_request.dict()
            }
            
        except Exception as e:
            logger.error(f"Error exporting data: {str(e)}")
            return {
                "data": [],
                "total_records": 0,
                "error": str(e)
            }
    
    async def validate_data(
        self,
        validation_request: ContactCenterValidationRequest
    ) -> Dict[str, Any]:
        """Validate contact center data"""
        try:
            validation_errors = await self._validate_bulk_data(
                validation_request.data_type,
                validation_request.data,
                validation_request.validation_rules,
                validation_request.strict_mode
            )
            
            total_records = len(validation_request.data)
            valid_records = total_records - len(validation_errors)
            
            return {
                "total_records": total_records,
                "valid_records": valid_records,
                "invalid_records": len(validation_errors),
                "validation_errors": validation_errors,
                "success_rate": (valid_records / total_records) * 100 if total_records > 0 else 0
            }
            
        except Exception as e:
            logger.error(f"Error validating data: {str(e)}")
            return {
                "total_records": len(validation_request.data),
                "valid_records": 0,
                "invalid_records": len(validation_request.data),
                "validation_errors": [{"error": str(e)}],
                "success_rate": 0
            }
    
    # ========================================================================
    # HELPER METHODS
    # ========================================================================
    
    async def _update_current_status(
        self,
        status_data: ContactCenterRealtimeData,
        db: AsyncSession
    ) -> None:
        """Update current agent status"""
        try:
            # Update or create current status
            stmt = select(AgentCurrentStatus).where(
                AgentCurrentStatus.agent_id == status_data.agent_id
            )
            result = await db.execute(stmt)
            current_status = result.scalar_one_or_none()
            
            if current_status:
                current_status.state_code = status_data.status
                current_status.state_name = status_data.status.replace("_", " ").title()
                current_status.start_date = status_data.start_time
                current_status.updated_at = datetime.utcnow()
            else:
                new_status = AgentCurrentStatus(
                    agent_id=status_data.agent_id,
                    state_code=status_data.status,
                    state_name=status_data.status.replace("_", " ").title(),
                    start_date=status_data.start_time
                )
                db.add(new_status)
            
            await db.commit()
            
        except Exception as e:
            logger.error(f"Error updating current status: {str(e)}")
    
    def _calculate_service_level(self, data: ServiceGroupMetrics) -> float:
        """Calculate service level percentage"""
        if data.received_calls == 0:
            return 0.0
        return (data.treated_calls / data.received_calls) * 100
    
    def _calculate_abandonment_rate(self, data: ServiceGroupMetrics) -> float:
        """Calculate abandonment rate percentage"""
        if data.received_calls == 0:
            return 0.0
        return (data.miss_calls / data.received_calls) * 100
    
    def _calculate_occupancy_rate(self, data: ServiceGroupMetrics) -> float:
        """Calculate occupancy rate - simplified calculation"""
        # This would need more sophisticated logic in a real implementation
        if data.aht == 0:
            return 0.0
        return min(100.0, (data.treated_calls * data.aht) / (30 * 60 * 1000))  # 30 min intervals
    
    async def _validate_bulk_data(
        self,
        data_type: str,
        data: List[Dict[str, Any]],
        custom_rules: Optional[Dict[str, Any]] = None,
        strict_mode: bool = False
    ) -> List[Dict[str, Any]]:
        """Validate bulk data according to schema and custom rules"""
        errors = []
        
        for i, record in enumerate(data):
            record_errors = []
            
            # Basic validation based on data type
            if data_type == "agent_status":
                if not record.get("agent_id"):
                    record_errors.append("agent_id is required")
                if not record.get("status"):
                    record_errors.append("status is required")
                if not record.get("start_time"):
                    record_errors.append("start_time is required")
            
            elif data_type == "service_group_metrics":
                if not record.get("service_id"):
                    record_errors.append("service_id is required")
                if not record.get("group_id"):
                    record_errors.append("group_id is required")
                if not record.get("interval_start"):
                    record_errors.append("interval_start is required")
            
            # Apply custom validation rules
            if custom_rules:
                for field, rule in custom_rules.items():
                    if field in record:
                        if rule.get("required") and not record[field]:
                            record_errors.append(f"{field} is required")
                        if rule.get("min_value") and record[field] < rule["min_value"]:
                            record_errors.append(f"{field} must be >= {rule['min_value']}")
                        if rule.get("max_value") and record[field] > rule["max_value"]:
                            record_errors.append(f"{field} must be <= {rule['max_value']}")
            
            if record_errors:
                errors.append({
                    "record_index": i,
                    "record": record,
                    "errors": record_errors
                })
        
        return errors
    
    async def _process_batch(
        self,
        data_type: str,
        batch: List[Dict[str, Any]],
        update_existing: bool,
        db: AsyncSession
    ) -> Tuple[int, List[Dict[str, Any]]]:
        """Process a batch of data"""
        successful_records = 0
        errors = []
        
        for i, record in enumerate(batch):
            try:
                # Process based on data type
                if data_type == "agent_status":
                    await self._process_agent_status_record(record, update_existing, db)
                elif data_type == "service_group_metrics":
                    await self._process_service_group_record(record, update_existing, db)
                elif data_type == "queue_metrics":
                    await self._process_queue_metrics_record(record, update_existing, db)
                
                successful_records += 1
                
            except Exception as e:
                errors.append({
                    "record_index": i,
                    "record": record,
                    "error": str(e)
                })
        
        return successful_records, errors
    
    async def _process_agent_status_record(
        self,
        record: Dict[str, Any],
        update_existing: bool,
        db: AsyncSession
    ) -> None:
        """Process individual agent status record"""
        # Create ContactCenterData record
        cc_data = ContactCenterData(
            data_type="agent_status",
            timestamp=datetime.utcnow(),
            date=datetime.utcnow().date(),
            interval_start=datetime.fromisoformat(record["start_time"]),
            interval_end=datetime.fromisoformat(record.get("end_time", record["start_time"])),
            agent_id=record["agent_id"],
            metrics=record,
            source_system="bulk_import"
        )
        db.add(cc_data)
    
    async def _process_service_group_record(
        self,
        record: Dict[str, Any],
        update_existing: bool,
        db: AsyncSession
    ) -> None:
        """Process individual service group record"""
        # Create ContactCenterData record
        cc_data = ContactCenterData(
            data_type="service_group_metrics",
            timestamp=datetime.utcnow(),
            date=datetime.utcnow().date(),
            interval_start=datetime.fromisoformat(record["interval_start"]),
            interval_end=datetime.fromisoformat(record["interval_end"]),
            service_group=record["group_id"],
            metrics=record,
            source_system="bulk_import"
        )
        db.add(cc_data)
    
    async def _process_queue_metrics_record(
        self,
        record: Dict[str, Any],
        update_existing: bool,
        db: AsyncSession
    ) -> None:
        """Process individual queue metrics record"""
        # Create ContactCenterData record
        cc_data = ContactCenterData(
            data_type="queue_metrics",
            timestamp=datetime.utcnow(),
            date=datetime.utcnow().date(),
            interval_start=datetime.fromisoformat(record.get("timestamp", datetime.utcnow().isoformat())),
            interval_end=datetime.fromisoformat(record.get("timestamp", datetime.utcnow().isoformat())),
            queue_id=record.get("queue_id"),
            service_group=record.get("service_group"),
            metrics=record,
            source_system="bulk_import"
        )
        db.add(cc_data)