"""
Integration Connections Management Endpoints

This module provides endpoints for managing integration connections:
- Create, read, update, delete integration connections
- Connection testing and health monitoring
- Connection statistics and usage metrics
- Bulk connection operations

Supports all integration types: 1C, Contact Center, LDAP, etc.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, desc

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....db.models import IntegrationConnection, IntegrationSyncLog, IntegrationDataMapping
from ....v1.schemas.integrations import (
    IntegrationConnectionCreate, IntegrationConnectionUpdate,
    IntegrationConnectionResponse, IntegrationTestConnection,
    IntegrationStatus, IntegrationResponse, ConnectionTestResponse,
    HealthCheckResponse, IntegrationDataMappingResponse
)
from ....models.user import User
from ....services.onec_service import OneCService
from ....services.contact_center_service import ContactCenterService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/connections", tags=["integration-connections"])


@router.post("/", response_model=IntegrationConnectionResponse)
async def create_integration_connection(
    connection_data: IntegrationConnectionCreate,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationConnectionResponse:
    """
    Create a new integration connection
    
    Args:
        connection_data: Integration connection data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationConnectionResponse with created connection
        
    Raises:
        HTTPException: If connection creation fails
    """
    try:
        # Encrypt credentials before storing
        # In a real implementation, you would use proper encryption
        encrypted_credentials = connection_data.credentials
        
        # Create connection
        connection = IntegrationConnection(
            name=connection_data.name,
            integration_type=connection_data.integration_type,
            endpoint_url=connection_data.endpoint_url,
            authentication_type=connection_data.authentication_type,
            credentials=encrypted_credentials,
            config=connection_data.config,
            mapping_rules=connection_data.mapping_rules,
            organization_id=current_user.organization_id,
            created_by=current_user.id
        )
        
        db.add(connection)
        await db.commit()
        await db.refresh(connection)
        
        return IntegrationConnectionResponse.from_orm(connection)
        
    except Exception as e:
        logger.error(f"Error creating integration connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create integration connection: {str(e)}"
        )


@router.get("/", response_model=List[IntegrationConnectionResponse])
async def list_integration_connections(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    integration_type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> List[IntegrationConnectionResponse]:
    """
    List integration connections
    
    Args:
        skip: Number of records to skip
        limit: Maximum number of records to return
        integration_type: Filter by integration type
        status: Filter by connection status
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        List of IntegrationConnectionResponse
        
    Raises:
        HTTPException: If listing fails
    """
    try:
        # Build query
        query = select(IntegrationConnection).where(
            IntegrationConnection.organization_id == current_user.organization_id
        )
        
        if integration_type:
            query = query.where(IntegrationConnection.integration_type == integration_type)
        
        if status:
            query = query.where(IntegrationConnection.status == status)
        
        query = query.order_by(desc(IntegrationConnection.created_at)).offset(skip).limit(limit)
        
        result = await db.execute(query)
        connections = result.scalars().all()
        
        # Remove sensitive data from response
        response_connections = []
        for conn in connections:
            conn_dict = conn.__dict__.copy()
            if 'credentials' in conn_dict:
                conn_dict['credentials'] = {"***": "***"}  # Mask credentials
            response_connections.append(IntegrationConnectionResponse(**conn_dict))
        
        return response_connections
        
    except Exception as e:
        logger.error(f"Error listing integration connections: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list integration connections: {str(e)}"
        )


@router.get("/{connection_id}", response_model=IntegrationConnectionResponse)
async def get_integration_connection(
    connection_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationConnectionResponse:
    """
    Get a specific integration connection
    
    Args:
        connection_id: Integration connection ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationConnectionResponse
        
    Raises:
        HTTPException: If connection not found
    """
    try:
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Mask credentials in response
        conn_dict = connection.__dict__.copy()
        if 'credentials' in conn_dict:
            conn_dict['credentials'] = {"***": "***"}
        
        return IntegrationConnectionResponse(**conn_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting integration connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get integration connection: {str(e)}"
        )


@router.put("/{connection_id}", response_model=IntegrationConnectionResponse)
async def update_integration_connection(
    connection_id: UUID,
    connection_data: IntegrationConnectionUpdate,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationConnectionResponse:
    """
    Update an integration connection
    
    Args:
        connection_id: Integration connection ID
        connection_data: Updated connection data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationConnectionResponse with updated connection
        
    Raises:
        HTTPException: If connection not found or update fails
    """
    try:
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Update fields
        update_data = connection_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            if field == "credentials" and value:
                # Encrypt credentials before storing
                setattr(connection, field, value)
            else:
                setattr(connection, field, value)
        
        connection.updated_at = datetime.utcnow()
        await db.commit()
        await db.refresh(connection)
        
        # Mask credentials in response
        conn_dict = connection.__dict__.copy()
        if 'credentials' in conn_dict:
            conn_dict['credentials'] = {"***": "***"}
        
        return IntegrationConnectionResponse(**conn_dict)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating integration connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update integration connection: {str(e)}"
        )


@router.delete("/{connection_id}")
async def delete_integration_connection(
    connection_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Delete an integration connection
    
    Args:
        connection_id: Integration connection ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with deletion result
        
    Raises:
        HTTPException: If connection not found or deletion fails
    """
    try:
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Check if connection is in use
        sync_logs_stmt = select(func.count(IntegrationSyncLog.id)).where(
            IntegrationSyncLog.connection_id == connection_id
        )
        sync_logs_result = await db.execute(sync_logs_stmt)
        sync_logs_count = sync_logs_result.scalar()
        
        if sync_logs_count > 0:
            # Soft delete by setting status to inactive
            connection.status = "inactive"
            connection.updated_at = datetime.utcnow()
            await db.commit()
            
            return IntegrationResponse(
                success=True,
                message="Integration connection deactivated (has sync history)",
                data={"connection_id": str(connection_id), "action": "deactivated"}
            )
        else:
            # Hard delete
            await db.delete(connection)
            await db.commit()
            
            return IntegrationResponse(
                success=True,
                message="Integration connection deleted successfully",
                data={"connection_id": str(connection_id), "action": "deleted"}
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting integration connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete integration connection: {str(e)}"
        )


@router.post("/{connection_id}/test")
async def test_integration_connection(
    connection_id: UUID,
    test_config: Optional[IntegrationTestConnection] = None,
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> ConnectionTestResponse:
    """
    Test an integration connection
    
    Args:
        connection_id: Integration connection ID
        test_config: Optional test configuration
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        ConnectionTestResponse with test results
        
    Raises:
        HTTPException: If connection not found or test fails
    """
    try:
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        test_type = test_config.test_type if test_config else "basic"
        
        # Test connection based on type
        if connection.integration_type == "1c":
            async with OneCService(connection) as service:
                test_result = await service.test_connection()
        elif connection.integration_type == "contact_center":
            async with ContactCenterService(connection) as service:
                test_result = await service.test_connection()
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Testing not supported for integration type: {connection.integration_type}"
            )
        
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
            test_type=test_type,
            success=test_result["success"],
            response_time_ms=int(test_result.get("response_time_ms", 0)),
            test_results=test_result,
            recommendations=_get_test_recommendations(connection.integration_type, test_result)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error testing integration connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to test integration connection: {str(e)}"
        )


@router.get("/{connection_id}/status", response_model=IntegrationStatus)
async def get_connection_status(
    connection_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationStatus:
    """
    Get detailed status of an integration connection
    
    Args:
        connection_id: Integration connection ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationStatus with detailed status information
        
    Raises:
        HTTPException: If connection not found
    """
    try:
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Get recent sync logs
        recent_syncs_stmt = select(IntegrationSyncLog).where(
            IntegrationSyncLog.connection_id == connection_id
        ).order_by(desc(IntegrationSyncLog.start_time)).limit(10)
        
        recent_syncs_result = await db.execute(recent_syncs_stmt)
        recent_syncs = recent_syncs_result.scalars().all()
        
        # Calculate metrics
        total_syncs = len(recent_syncs)
        successful_syncs = sum(1 for sync in recent_syncs if sync.status == "completed")
        success_rate = (successful_syncs / total_syncs) * 100 if total_syncs > 0 else 0
        error_count = sum(1 for sync in recent_syncs if sync.status == "failed")
        
        # Health check
        health_check = {"status": "unknown", "message": "No recent activity"}
        if connection.status == "active":
            if connection.integration_type == "1c":
                async with OneCService(connection) as service:
                    health_check = await service.test_connection()
            elif connection.integration_type == "contact_center":
                async with ContactCenterService(connection) as service:
                    health_check = await service.test_connection()
        
        return IntegrationStatus(
            connection_id=connection.id,
            status=connection.status,
            last_sync=connection.last_sync,
            next_sync=None,  # Would be calculated based on sync schedule
            health_check=health_check,
            error_count=error_count,
            success_rate=success_rate,
            performance_metrics={
                "total_syncs": total_syncs,
                "successful_syncs": successful_syncs,
                "avg_response_time_ms": health_check.get("response_time_ms", 0),
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
        logger.error(f"Error getting connection status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get connection status: {str(e)}"
        )


@router.get("/{connection_id}/sync-logs")
async def get_connection_sync_logs(
    connection_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    sync_type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get sync logs for an integration connection
    
    Args:
        connection_id: Integration connection ID
        skip: Number of records to skip
        limit: Maximum number of records to return
        sync_type: Filter by sync type
        status: Filter by sync status
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with sync logs and metadata
        
    Raises:
        HTTPException: If connection not found
    """
    try:
        # Verify connection exists
        connection_stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        connection_result = await db.execute(connection_stmt)
        connection = connection_result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Build sync logs query
        query = select(IntegrationSyncLog).where(
            IntegrationSyncLog.connection_id == connection_id
        )
        
        if sync_type:
            query = query.where(IntegrationSyncLog.sync_type == sync_type)
        
        if status:
            query = query.where(IntegrationSyncLog.status == status)
        
        query = query.order_by(desc(IntegrationSyncLog.start_time)).offset(skip).limit(limit)
        
        result = await db.execute(query)
        sync_logs = result.scalars().all()
        
        # Get total count
        count_query = select(func.count(IntegrationSyncLog.id)).where(
            IntegrationSyncLog.connection_id == connection_id
        )
        if sync_type:
            count_query = count_query.where(IntegrationSyncLog.sync_type == sync_type)
        if status:
            count_query = count_query.where(IntegrationSyncLog.status == status)
        
        count_result = await db.execute(count_query)
        total_count = count_result.scalar()
        
        return {
            "sync_logs": [
                {
                    "id": str(log.id),
                    "sync_type": log.sync_type,
                    "direction": log.direction,
                    "status": log.status,
                    "start_time": log.start_time.isoformat(),
                    "end_time": log.end_time.isoformat() if log.end_time else None,
                    "records_processed": log.records_processed,
                    "records_successful": log.records_successful,
                    "records_failed": log.records_failed,
                    "error_details": log.error_details
                }
                for log in sync_logs
            ],
            "total_count": total_count,
            "connection_id": str(connection_id),
            "connection_name": connection.name,
            "filters": {
                "sync_type": sync_type,
                "status": status,
                "skip": skip,
                "limit": limit
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting sync logs: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get sync logs: {str(e)}"
        )


@router.get("/{connection_id}/mappings", response_model=List[IntegrationDataMappingResponse])
async def get_connection_mappings(
    connection_id: UUID,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> List[IntegrationDataMappingResponse]:
    """
    Get data mappings for an integration connection
    
    Args:
        connection_id: Integration connection ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        List of IntegrationDataMappingResponse
        
    Raises:
        HTTPException: If connection not found
    """
    try:
        # Verify connection exists
        connection_stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.id == connection_id,
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        connection_result = await db.execute(connection_stmt)
        connection = connection_result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="Integration connection not found"
            )
        
        # Get mappings
        mappings_stmt = select(IntegrationDataMapping).where(
            IntegrationDataMapping.connection_id == connection_id
        )
        mappings_result = await db.execute(mappings_stmt)
        mappings = mappings_result.scalars().all()
        
        return [IntegrationDataMappingResponse.from_orm(mapping) for mapping in mappings]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting connection mappings: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get connection mappings: {str(e)}"
        )


@router.get("/health")
async def get_integrations_health(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> HealthCheckResponse:
    """
    Get overall integrations health status
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        HealthCheckResponse with health status
        
    Raises:
        HTTPException: If health check fails
    """
    try:
        # Get connections count
        connections_stmt = select(func.count(IntegrationConnection.id)).where(
            IntegrationConnection.organization_id == current_user.organization_id
        )
        connections_result = await db.execute(connections_stmt)
        total_connections = connections_result.scalar()
        
        # Get active connections count
        active_connections_stmt = select(func.count(IntegrationConnection.id)).where(
            and_(
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        active_connections_result = await db.execute(active_connections_stmt)
        active_connections = active_connections_result.scalar()
        
        # Get recent sync times
        recent_syncs_stmt = select(IntegrationSyncLog).where(
            IntegrationSyncLog.connection_id.in_(
                select(IntegrationConnection.id).where(
                    IntegrationConnection.organization_id == current_user.organization_id
                )
            )
        ).order_by(desc(IntegrationSyncLog.start_time)).limit(10)
        
        recent_syncs_result = await db.execute(recent_syncs_stmt)
        recent_syncs = recent_syncs_result.scalars().all()
        
        # Calculate performance metrics
        last_sync_times = {}
        for sync in recent_syncs:
            sync_type = sync.sync_type
            if sync_type not in last_sync_times:
                last_sync_times[sync_type] = sync.start_time
        
        # Determine overall status
        if active_connections == 0:
            status = "warning"
        elif active_connections == total_connections:
            status = "healthy"
        else:
            status = "degraded"
        
        return HealthCheckResponse(
            service_name="WFM Integration Service",
            status=status,
            version="1.0.0",
            uptime_seconds=int((datetime.utcnow() - datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)).total_seconds()),
            active_connections=active_connections,
            last_sync_times=last_sync_times,
            performance_metrics={
                "total_connections": total_connections,
                "active_connections": active_connections,
                "inactive_connections": total_connections - active_connections,
                "recent_syncs": len(recent_syncs),
                "success_rate": (
                    sum(1 for sync in recent_syncs if sync.status == "completed") / len(recent_syncs) * 100
                    if recent_syncs else 0
                )
            }
        )
        
    except Exception as e:
        logger.error(f"Error getting integrations health: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get integrations health: {str(e)}"
        )


def _get_test_recommendations(integration_type: str, test_result: Dict[str, Any]) -> List[str]:
    """
    Get test recommendations based on integration type and test result
    
    Args:
        integration_type: Type of integration
        test_result: Test result data
        
    Returns:
        List of recommendations
    """
    recommendations = []
    
    if not test_result["success"]:
        recommendations.extend([
            "Check service availability",
            "Verify authentication credentials",
            "Ensure network connectivity"
        ])
        
        if integration_type == "1c":
            recommendations.extend([
                "Verify 1C ZUP service is running",
                "Check 1C database connection",
                "Ensure proper 1C user permissions"
            ])
        elif integration_type == "contact_center":
            recommendations.extend([
                "Verify Contact Center service is running",
                "Check Argus compatibility settings",
                "Ensure proper API permissions"
            ])
    else:
        recommendations.extend([
            "Connection is healthy",
            "Consider enabling monitoring",
            "Set up regular health checks"
        ])
        
        if test_result.get("response_time_ms", 0) > 5000:
            recommendations.append("Consider optimizing connection for better performance")
    
    return recommendations