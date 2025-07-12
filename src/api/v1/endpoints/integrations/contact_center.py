"""
Contact Center Integration Endpoints

This module implements 15 endpoints for Contact Center integration (Enhanced Argus compatibility):

Historical Data (5 endpoints):
1. GET /historic/serviceGroupData - Service group metrics
2. GET /historic/agentStatusData - Agent status history
3. GET /historic/agentLoginData - Agent login history
4. GET /historic/agentCallsData - Agent calls data
5. GET /historic/agentChatsWorkTime - Agent chats work time

Real-time Data (4 endpoints):
6. POST /status - Fire-and-forget status updates
7. GET /online/agentStatus - Current agent status
8. GET /online/groupsLoad - Groups load metrics
9. GET /online/queueMetrics - Queue metrics

Bulk Operations (3 endpoints):
10. POST /bulk-import - Bulk data import
11. POST /validate-data - Data validation
12. POST /export-data - Data export

Configuration (3 endpoints):
13. GET /status - Integration status
14. PUT /config - Update configuration
15. POST /test-connection - Test connection

All endpoints build on existing Argus-compatible infrastructure.
"""

import logging
from datetime import datetime, date, timedelta
from typing import Dict, Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....db.models import IntegrationConnection, IntegrationSyncLog, ContactCenterData
from ....services.contact_center_service import ContactCenterService
from ....v1.schemas.integrations import (
    ContactCenterHistoricRequest, ContactCenterRealtimeData,
    ContactCenterBulkImport, ContactCenterExportRequest, ContactCenterValidationRequest,
    ContactCenterServiceGroupData, ContactCenterAgentStatusData,
    ContactCenterAgentLoginData, ContactCenterAgentCallsData,
    ContactCenterAgentChatsWorkTime, IntegrationResponse,
    BulkOperationResponse, ConnectionTestResponse, IntegrationStatus
)
from ....models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/cc", tags=["contact-center-integration"])


# ============================================================================
# HISTORICAL DATA ENDPOINTS (5 endpoints)
# ============================================================================

@router.get("/historic/serviceGroupData")
async def get_service_group_data(
    start_date: datetime = Query(..., description="Start datetime for data"),
    end_date: datetime = Query(..., description="End datetime for data"),
    interval_minutes: int = Query(30, ge=1, le=1440, description="Interval in minutes"),
    service_groups: Optional[List[str]] = Query(None, description="Service groups filter"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get service group data with enhanced Argus compatibility
    
    Args:
        start_date: Start datetime for data retrieval
        end_date: End datetime for data retrieval
        interval_minutes: Interval in minutes
        service_groups: Optional service groups filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with service group data and metadata
        
    Raises:
        HTTPException: If request fails or data not available
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Create request object
        request = ContactCenterHistoricRequest(
            start_date=start_date,
            end_date=end_date,
            interval_minutes=interval_minutes,
            service_groups=service_groups
        )
        
        # Get data using service
        async with ContactCenterService(connection) as cc_service:
            data = await cc_service.get_service_group_data(request, db)
        
        return {
            "service_group_data": [item.dict() for item in data],
            "total_count": len(data),
            "parameters": request.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting service group data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get service group data: {str(e)}"
        )


@router.get("/historic/agentStatusData")
async def get_agent_status_data(
    start_date: datetime = Query(..., description="Start datetime for data"),
    end_date: datetime = Query(..., description="End datetime for data"),
    agents: Optional[List[str]] = Query(None, description="Agent IDs filter"),
    service_groups: Optional[List[str]] = Query(None, description="Service groups filter"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get agent status data with enhanced filtering
    
    Args:
        start_date: Start datetime for data retrieval
        end_date: End datetime for data retrieval
        agents: Optional agents filter
        service_groups: Optional service groups filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with agent status data and metadata
        
    Raises:
        HTTPException: If request fails or data not available
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Create request object
        request = ContactCenterHistoricRequest(
            start_date=start_date,
            end_date=end_date,
            agents=agents,
            service_groups=service_groups
        )
        
        # Get data using service
        async with ContactCenterService(connection) as cc_service:
            data = await cc_service.get_agent_status_data(request, db)
        
        return {
            "agent_status_data": [item.dict() for item in data],
            "total_count": len(data),
            "parameters": request.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting agent status data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get agent status data: {str(e)}"
        )


@router.get("/historic/agentLoginData")
async def get_agent_login_data(
    start_date: datetime = Query(..., description="Start datetime for data"),
    end_date: datetime = Query(..., description="End datetime for data"),
    agents: Optional[List[str]] = Query(None, description="Agent IDs filter"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get agent login data with enhanced filtering
    
    Args:
        start_date: Start datetime for data retrieval
        end_date: End datetime for data retrieval
        agents: Optional agents filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with agent login data and metadata
        
    Raises:
        HTTPException: If request fails or data not available
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Create request object
        request = ContactCenterHistoricRequest(
            start_date=start_date,
            end_date=end_date,
            agents=agents
        )
        
        # Get data using service
        async with ContactCenterService(connection) as cc_service:
            data = await cc_service.get_agent_login_data(request, db)
        
        return {
            "agent_login_data": [item.dict() for item in data],
            "total_count": len(data),
            "parameters": request.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting agent login data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get agent login data: {str(e)}"
        )


@router.get("/historic/agentCallsData")
async def get_agent_calls_data(
    start_date: datetime = Query(..., description="Start datetime for data"),
    end_date: datetime = Query(..., description="End datetime for data"),
    agents: Optional[List[str]] = Query(None, description="Agent IDs filter"),
    service_groups: Optional[List[str]] = Query(None, description="Service groups filter"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get agent calls data with enhanced filtering
    
    Args:
        start_date: Start datetime for data retrieval
        end_date: End datetime for data retrieval
        agents: Optional agents filter
        service_groups: Optional service groups filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with agent calls data and metadata
        
    Raises:
        HTTPException: If request fails or data not available
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Create request object
        request = ContactCenterHistoricRequest(
            start_date=start_date,
            end_date=end_date,
            agents=agents,
            service_groups=service_groups
        )
        
        # Get data using service
        async with ContactCenterService(connection) as cc_service:
            data = await cc_service.get_agent_calls_data(request, db)
        
        return {
            "agent_calls_data": [item.dict() for item in data],
            "total_count": len(data),
            "parameters": request.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting agent calls data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get agent calls data: {str(e)}"
        )


@router.get("/historic/agentChatsWorkTime")
async def get_agent_chats_work_time(
    start_date: datetime = Query(..., description="Start datetime for data"),
    end_date: datetime = Query(..., description="End datetime for data"),
    agents: Optional[List[str]] = Query(None, description="Agent IDs filter"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get agent chats work time data with enhanced filtering
    
    Args:
        start_date: Start datetime for data retrieval
        end_date: End datetime for data retrieval
        agents: Optional agents filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with agent chats work time data and metadata
        
    Raises:
        HTTPException: If request fails or data not available
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Create request object
        request = ContactCenterHistoricRequest(
            start_date=start_date,
            end_date=end_date,
            agents=agents
        )
        
        # Get data using service
        async with ContactCenterService(connection) as cc_service:
            data = await cc_service.get_agent_chats_work_time(request, db)
        
        return {
            "agent_chats_work_time": [item.dict() for item in data],
            "total_count": len(data),
            "parameters": request.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting agent chats work time: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get agent chats work time: {str(e)}"
        )


# ============================================================================
# REAL-TIME DATA ENDPOINTS (4 endpoints)
# ============================================================================

@router.post("/status")
async def process_realtime_status(
    status_data: ContactCenterRealtimeData,
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Process real-time status data (fire-and-forget)
    
    Args:
        status_data: Real-time status data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with processing result
        
    Raises:
        HTTPException: If processing fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Process real-time data
        async with ContactCenterService(connection) as cc_service:
            result = await cc_service.process_realtime_status(status_data, db)
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing real-time status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process real-time status: {str(e)}"
        )


@router.get("/online/agentStatus")
async def get_online_agent_status(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get current online agent status
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with current agent status data
        
    Raises:
        HTTPException: If request fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Get online agent status
        async with ContactCenterService(connection) as cc_service:
            status_data = await cc_service.get_online_agent_status(db)
        
        return {
            "agent_status": status_data,
            "total_agents": len(status_data),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting online agent status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get online agent status: {str(e)}"
        )


@router.get("/online/groupsLoad")
async def get_online_groups_load(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get current groups load metrics
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with current groups load data
        
    Raises:
        HTTPException: If request fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Get groups load data
        async with ContactCenterService(connection) as cc_service:
            load_data = await cc_service.get_online_groups_load(db)
        
        return {
            "groups_load": load_data,
            "total_groups": len(load_data),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting groups load: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get groups load: {str(e)}"
        )


@router.get("/online/queueMetrics")
async def get_queue_metrics(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get real-time queue metrics
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with queue metrics data
        
    Raises:
        HTTPException: If request fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Get queue metrics
        async with ContactCenterService(connection) as cc_service:
            metrics_data = await cc_service.get_queue_metrics(db)
        
        return {
            "queue_metrics": metrics_data,
            "total_queues": len(metrics_data),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting queue metrics: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get queue metrics: {str(e)}"
        )


# ============================================================================
# BULK OPERATIONS ENDPOINTS (3 endpoints)
# ============================================================================

@router.post("/bulk-import")
async def bulk_import_data(
    import_request: ContactCenterBulkImport,
    current_user: User = Depends(require_permissions(["integrations.sync"])),
    db: AsyncSession = Depends(get_db)
) -> BulkOperationResponse:
    """
    Bulk import contact center data
    
    Args:
        import_request: Bulk import request data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        BulkOperationResponse with import results
        
    Raises:
        HTTPException: If import fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Perform bulk import
        async with ContactCenterService(connection) as cc_service:
            result = await cc_service.bulk_import_data(import_request, db)
        
        # Log the operation
        sync_log = IntegrationSyncLog(
            connection_id=connection.id,
            sync_type="bulk_import",
            direction="inbound",
            status="completed" if result.failed_records == 0 else "failed",
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow(),
            sync_data={"data_type": import_request.data_type},
            initiated_by=current_user.id,
            records_processed=result.total_records,
            records_successful=result.successful_records,
            records_failed=result.failed_records
        )
        db.add(sync_log)
        await db.commit()
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in bulk import: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to perform bulk import: {str(e)}"
        )


@router.post("/validate-data")
async def validate_data(
    validation_request: ContactCenterValidationRequest,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Validate contact center data
    
    Args:
        validation_request: Data validation request
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with validation results
        
    Raises:
        HTTPException: If validation fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Validate data
        async with ContactCenterService(connection) as cc_service:
            validation_result = await cc_service.validate_data(validation_request)
        
        return validation_result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error validating data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to validate data: {str(e)}"
        )


@router.post("/export-data")
async def export_data(
    export_request: ContactCenterExportRequest,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Export contact center data
    
    Args:
        export_request: Data export request
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with exported data
        
    Raises:
        HTTPException: If export fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured or inactive"
            )
        
        # Export data
        async with ContactCenterService(connection) as cc_service:
            export_result = await cc_service.export_data(export_request, db)
        
        return export_result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to export data: {str(e)}"
        )


# ============================================================================
# CONFIGURATION ENDPOINTS (3 endpoints)
# ============================================================================

@router.get("/status")
async def get_contact_center_status(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationStatus:
    """
    Get Contact Center integration status
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationStatus with current status
        
    Raises:
        HTTPException: If status check fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured"
            )
        
        # Get recent sync logs
        recent_syncs_stmt = select(IntegrationSyncLog).where(
            IntegrationSyncLog.connection_id == connection.id
        ).order_by(IntegrationSyncLog.start_time.desc()).limit(10)
        
        recent_syncs_result = await db.execute(recent_syncs_stmt)
        recent_syncs = recent_syncs_result.scalars().all()
        
        # Calculate success rate
        total_syncs = len(recent_syncs)
        successful_syncs = sum(1 for sync in recent_syncs if sync.status == "completed")
        success_rate = (successful_syncs / total_syncs) * 100 if total_syncs > 0 else 0
        
        # Get error count
        error_count = sum(1 for sync in recent_syncs if sync.status == "failed")
        
        # Test connection if active
        health_check = {"status": "unknown"}
        if connection.status == "active":
            async with ContactCenterService(connection) as cc_service:
                health_check = await cc_service.test_connection()
        
        return IntegrationStatus(
            connection_id=connection.id,
            status=connection.status,
            last_sync=connection.last_sync,
            next_sync=None,
            health_check=health_check,
            error_count=error_count,
            success_rate=success_rate,
            performance_metrics={
                "total_syncs": total_syncs,
                "successful_syncs": successful_syncs,
                "recent_syncs": [
                    {
                        "id": str(sync.id),
                        "sync_type": sync.sync_type,
                        "status": sync.status,
                        "start_time": sync.start_time.isoformat(),
                        "records_processed": sync.records_processed
                    }
                    for sync in recent_syncs[:5]
                ]
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting Contact Center status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get Contact Center status: {str(e)}"
        )


@router.put("/config")
async def update_contact_center_config(
    config: Dict[str, Any],
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Update Contact Center integration configuration
    
    Args:
        config: New configuration data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with operation result
        
    Raises:
        HTTPException: If configuration update fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured"
            )
        
        # Update configuration
        connection.config = config
        connection.updated_at = datetime.utcnow()
        await db.commit()
        
        # Log the configuration change
        sync_log = IntegrationSyncLog(
            connection_id=connection.id,
            sync_type="config_update",
            direction="bidirectional",
            status="completed",
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow(),
            sync_data={"config": config},
            initiated_by=current_user.id
        )
        db.add(sync_log)
        await db.commit()
        
        return IntegrationResponse(
            success=True,
            message="Contact Center configuration updated successfully",
            data={
                "connection_id": str(connection.id),
                "config": config,
                "updated_at": connection.updated_at.isoformat()
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating Contact Center config: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update Contact Center configuration: {str(e)}"
        )


@router.post("/test-connection")
async def test_contact_center_connection(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> ConnectionTestResponse:
    """
    Test Contact Center connection
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        ConnectionTestResponse with test results
        
    Raises:
        HTTPException: If connection test fails
    """
    try:
        # Get Contact Center connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "contact_center",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Contact Center integration not configured"
            )
        
        # Test connection
        async with ContactCenterService(connection) as cc_service:
            test_result = await cc_service.test_connection()
        
        # Update connection status based on test result
        if test_result["success"]:
            connection.status = "active"
            connection.last_error = None
        else:
            connection.status = "error"
            connection.last_error = test_result["message"]
        
        await db.commit()
        
        return ConnectionTestResponse(
            connection_id=connection.id,
            test_type="basic",
            success=test_result["success"],
            response_time_ms=int(test_result["response_time_ms"]),
            test_results=test_result,
            recommendations=[
                "Check Contact Center service availability",
                "Verify authentication credentials",
                "Ensure network connectivity",
                "Review Argus compatibility settings"
            ] if not test_result["success"] else [
                "Connection is healthy",
                "Argus compatibility active",
                "Consider enabling monitoring"
            ]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error testing Contact Center connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to test Contact Center connection: {str(e)}"
        )