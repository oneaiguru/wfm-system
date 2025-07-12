"""
1C ZUP Integration Endpoints

This module implements 10 endpoints for 1C ZUP (Зарплата и Управление Персоналом) integration:
1. GET /agents/{start_date}/{end_date} - Get agents for date range
2. POST /sync-personnel - Sync personnel data
3. POST /sendSchedule - Send schedule to 1C
4. POST /getNormHours - Get norm hours
5. POST /getTimetypeInfo - Get time type info
6. POST /sendFactWorkTime - Send actual work time
7. GET /deviations - Get deviations
8. GET /status - Get integration status
9. PUT /config - Update configuration
10. POST /test-connection - Test connection

All endpoints include proper authentication, validation, and error handling.
"""

import logging
from datetime import datetime, date
from typing import Dict, Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....db.models import IntegrationConnection, IntegrationSyncLog, OneCIntegrationData
from ....services.onec_service import OneCService
from ....v1.schemas.integrations import (
    OneCPersonnelSync, OneCScheduleData, OneCTimeData,
    OneCNormHoursRequest, OneCTimetypeInfoRequest, OneCAgentData,
    OneCDeviationData, IntegrationConnectionResponse, IntegrationSyncLogResponse,
    IntegrationResponse, SyncOperationResponse, ConnectionTestResponse,
    IntegrationStatus, HealthCheckResponse
)
from ....models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/1c", tags=["1c-integration"])


@router.get("/agents/{start_date}/{end_date}")
async def get_onec_agents(
    start_date: date,
    end_date: date,
    departments: Optional[List[str]] = Query(None),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Get agents from 1C ZUP for specified date range
    
    Args:
        start_date: Start date for agent query
        end_date: End date for agent query
        departments: Optional list of departments to filter
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict containing agents list and metadata
        
    Raises:
        HTTPException: If 1C integration not configured or connection fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Validate date range
        if end_date < start_date:
            raise HTTPException(
                status_code=400,
                detail="end_date must be after start_date"
            )
        
        # Fetch data from 1C
        async with OneCService(connection) as onec_service:
            agents = await onec_service.get_agents(
                start_date=start_date,
                end_date=end_date,
                departments=departments
            )
        
        return {
            "agents": [agent.dict() for agent in agents],
            "total_count": len(agents),
            "date_range": {
                "start": start_date.isoformat(),
                "end": end_date.isoformat()
            },
            "departments": departments,
            "connection_id": str(connection.id),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting 1C agents: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get agents from 1C: {str(e)}"
        )


@router.post("/sync-personnel")
async def sync_personnel_from_onec(
    sync_data: OneCPersonnelSync,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["integrations.sync"])),
    db: AsyncSession = Depends(get_db)
) -> SyncOperationResponse:
    """
    Sync personnel data from 1C ZUP
    
    Args:
        sync_data: Personnel sync parameters
        background_tasks: FastAPI background tasks
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        SyncOperationResponse with sync details
        
    Raises:
        HTTPException: If 1C integration not configured or sync fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Start background sync
        background_tasks.add_task(
            OneCService.sync_personnel_data_background,
            connection.id,
            sync_data.dict(),
            current_user.id
        )
        
        # Create initial sync log
        sync_log = IntegrationSyncLog(
            connection_id=connection.id,
            sync_type="personnel" if not sync_data.full_sync else "full",
            direction="inbound",
            status="started",
            start_time=datetime.utcnow(),
            sync_data=sync_data.dict(),
            initiated_by=current_user.id
        )
        db.add(sync_log)
        await db.commit()
        
        return SyncOperationResponse(
            sync_id=sync_log.id,
            status="started",
            started_at=sync_log.start_time,
            progress_percentage=0.0,
            records_to_process=None,
            records_processed=0
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting personnel sync: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to start personnel sync: {str(e)}"
        )


@router.post("/sendSchedule")
async def send_schedule_to_onec(
    schedule_data: OneCScheduleData,
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Send schedule data to 1C ZUP
    
    Args:
        schedule_data: Schedule data to send
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with operation result
        
    Raises:
        HTTPException: If 1C integration not configured or send fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Send to 1C
        async with OneCService(connection) as onec_service:
            result = await onec_service.send_schedule(schedule_data.dict())
        
        # Log the operation
        sync_log = IntegrationSyncLog(
            connection_id=connection.id,
            sync_type="schedule",
            direction="outbound",
            status="completed" if result.success else "failed",
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow(),
            sync_data=schedule_data.dict(),
            initiated_by=current_user.id,
            records_processed=len(schedule_data.employees)
        )
        db.add(sync_log)
        await db.commit()
        
        return IntegrationResponse(
            success=result.success,
            message=result.message,
            data={
                "schedule_id": str(schedule_data.schedule_id),
                "employees_count": len(schedule_data.employees),
                "shifts_count": len(schedule_data.shifts),
                "sync_log_id": str(sync_log.id)
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending schedule to 1C: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send schedule to 1C: {str(e)}"
        )


@router.post("/getNormHours")
async def get_norm_hours_from_onec(
    request: OneCNormHoursRequest,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get norm hours from 1C ZUP
    
    Args:
        request: Norm hours request parameters
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with norm hours data
        
    Raises:
        HTTPException: If 1C integration not configured or request fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Get norm hours from 1C
        async with OneCService(connection) as onec_service:
            norm_hours = await onec_service.get_norm_hours(
                employee_id=request.employee_id,
                start_date=request.start_date,
                end_date=request.end_date
            )
        
        return {
            "employee_id": request.employee_id,
            "period": {
                "start_date": request.start_date.isoformat(),
                "end_date": request.end_date.isoformat()
            },
            "norm_hours": norm_hours,
            "calculation_type": request.calculation_type,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting norm hours: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get norm hours from 1C: {str(e)}"
        )


@router.post("/getTimetypeInfo")
async def get_timetype_info_from_onec(
    request: OneCTimetypeInfoRequest,
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get time type info from 1C ZUP
    
    Args:
        request: Time type info request parameters
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with time type info data
        
    Raises:
        HTTPException: If 1C integration not configured or request fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Get time type info from 1C
        async with OneCService(connection) as onec_service:
            timetype_info = await onec_service.get_timetype_info(
                employee_id=request.employee_id,
                query_date=request.date
            )
        
        return {
            "employee_id": request.employee_id,
            "date": request.date.isoformat(),
            "time_type_codes": request.time_type_codes,
            "timetype_info": timetype_info,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting time type info: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get time type info from 1C: {str(e)}"
        )


@router.post("/sendFactWorkTime")
async def send_work_time_to_onec(
    time_data: List[OneCTimeData],
    current_user: User = Depends(require_permissions(["integrations.write"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Send actual work time data to 1C ZUP
    
    Args:
        time_data: List of time data records
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with operation result
        
    Raises:
        HTTPException: If 1C integration not configured or send fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Send to 1C
        async with OneCService(connection) as onec_service:
            results = []
            successful_sends = 0
            failed_sends = 0
            
            for time_entry in time_data:
                try:
                    result = await onec_service.send_work_time(time_entry.dict())
                    results.append(result.dict())
                    if result.success:
                        successful_sends += 1
                    else:
                        failed_sends += 1
                except Exception as e:
                    results.append({
                        "success": False,
                        "message": f"Failed to send time data: {str(e)}",
                        "employee_id": time_entry.employee_id
                    })
                    failed_sends += 1
        
        # Log the operation
        sync_log = IntegrationSyncLog(
            connection_id=connection.id,
            sync_type="timesheet",
            direction="outbound",
            status="completed" if failed_sends == 0 else "failed",
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow(),
            sync_data={"time_entries": len(time_data)},
            initiated_by=current_user.id,
            records_processed=len(time_data),
            records_successful=successful_sends,
            records_failed=failed_sends
        )
        db.add(sync_log)
        await db.commit()
        
        return IntegrationResponse(
            success=failed_sends == 0,
            message=f"Sent {successful_sends} time records, {failed_sends} failed",
            data={
                "total_records": len(time_data),
                "successful_records": successful_sends,
                "failed_records": failed_sends,
                "results": results,
                "sync_log_id": str(sync_log.id)
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending work time to 1C: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send work time to 1C: {str(e)}"
        )


@router.get("/deviations")
async def get_onec_deviations(
    start_date: date = Query(..., description="Start date for deviations"),
    end_date: date = Query(..., description="End date for deviations"),
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get deviations from 1C ZUP
    
    Args:
        start_date: Start date for deviations query
        end_date: End date for deviations query
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Dict with deviations data
        
    Raises:
        HTTPException: If 1C integration not configured or request fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id,
                IntegrationConnection.status == "active"
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured or inactive"
            )
        
        # Validate date range
        if end_date < start_date:
            raise HTTPException(
                status_code=400,
                detail="end_date must be after start_date"
            )
        
        # Get deviations from 1C
        async with OneCService(connection) as onec_service:
            deviations = await onec_service.get_deviations(
                start_date=start_date,
                end_date=end_date
            )
        
        return {
            "deviations": [deviation.dict() for deviation in deviations],
            "total_count": len(deviations),
            "date_range": {
                "start": start_date.isoformat(),
                "end": end_date.isoformat()
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting 1C deviations: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get deviations from 1C: {str(e)}"
        )


@router.get("/status")
async def get_onec_status(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationStatus:
    """
    Get 1C integration status
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationStatus with current status
        
    Raises:
        HTTPException: If status check fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured"
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
            async with OneCService(connection) as onec_service:
                health_check = await onec_service.test_connection()
        
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
        logger.error(f"Error getting 1C status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get 1C status: {str(e)}"
        )


@router.put("/config")
async def update_onec_config(
    config: Dict[str, Any],
    current_user: User = Depends(require_permissions(["integrations.admin"])),
    db: AsyncSession = Depends(get_db)
) -> IntegrationResponse:
    """
    Update 1C integration configuration
    
    Args:
        config: New configuration data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        IntegrationResponse with operation result
        
    Raises:
        HTTPException: If 1C integration not configured or update fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured"
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
            message="1C configuration updated successfully",
            data={
                "connection_id": str(connection.id),
                "config": config,
                "updated_at": connection.updated_at.isoformat()
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating 1C config: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update 1C configuration: {str(e)}"
        )


@router.post("/test-connection")
async def test_onec_connection(
    current_user: User = Depends(require_permissions(["integrations.read"])),
    db: AsyncSession = Depends(get_db)
) -> ConnectionTestResponse:
    """
    Test 1C connection
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        ConnectionTestResponse with test results
        
    Raises:
        HTTPException: If 1C integration not configured or test fails
    """
    try:
        # Get 1C connection
        stmt = select(IntegrationConnection).where(
            and_(
                IntegrationConnection.integration_type == "1c",
                IntegrationConnection.organization_id == current_user.organization_id
            )
        )
        result = await db.execute(stmt)
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise HTTPException(
                status_code=404,
                detail="1C integration not configured"
            )
        
        # Test connection
        async with OneCService(connection) as onec_service:
            test_result = await onec_service.test_connection()
        
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
                "Check 1C service availability",
                "Verify authentication credentials",
                "Ensure network connectivity"
            ] if not test_result["success"] else [
                "Connection is healthy",
                "Consider enabling monitoring"
            ]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error testing 1C connection: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to test 1C connection: {str(e)}"
        )