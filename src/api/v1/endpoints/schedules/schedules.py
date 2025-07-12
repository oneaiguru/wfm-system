"""
Schedule CRUD Operations API Endpoints
7 endpoints for basic schedule management operations
"""

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
from datetime import datetime

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleShift, ScheduleVariant
from ....models.user import User
from ....services.schedule_service import ScheduleService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    ScheduleCreate, ScheduleUpdate, ScheduleResponse, ScheduleVariantCreate,
    ScheduleVariantResponse, SchedulePublishRequest, SchedulePublishResponse,
    ScheduleStatus, ScheduleType
)

router = APIRouter()


@router.post("/", response_model=ScheduleResponse)
async def create_schedule(
    schedule_data: ScheduleCreate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Create a new schedule"""
    try:
        # Create schedule
        schedule = Schedule(
            **schedule_data.dict(),
            created_by=current_user.id,
            organization_id=current_user.organization_id
        )
        
        db.add(schedule)
        db.commit()
        db.refresh(schedule)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.created",
            {
                "schedule_id": str(schedule.id),
                "name": schedule.name,
                "created_by": str(current_user.id),
                "organization_id": str(current_user.organization_id)
            }
        )
        
        return ScheduleResponse.from_orm(schedule)
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create schedule: {str(e)}")


@router.get("/", response_model=List[ScheduleResponse])
async def list_schedules(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    department_id: Optional[uuid.UUID] = Query(None),
    status: Optional[ScheduleStatus] = Query(None),
    schedule_type: Optional[ScheduleType] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """List schedules with filtering and pagination"""
    try:
        query = db.query(Schedule)
        
        # Apply filters
        if department_id:
            query = query.filter(Schedule.department_id == department_id)
        
        if status:
            query = query.filter(Schedule.status == status.value)
        
        if schedule_type:
            query = query.filter(Schedule.schedule_type == schedule_type.value)
        
        if start_date:
            query = query.filter(Schedule.start_date >= start_date)
        
        if end_date:
            query = query.filter(Schedule.end_date <= end_date)
        
        if search:
            query = query.filter(
                Schedule.name.ilike(f"%{search}%") |
                Schedule.description.ilike(f"%{search}%")
            )
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.filter(Schedule.organization_id == current_user.organization_id)
        
        # Apply pagination
        schedules = query.offset(skip).limit(limit).all()
        
        # Add computed fields
        for schedule in schedules:
            schedule.shift_count = len(schedule.shifts)
            schedule.employee_count = len(set(shift.employee_id for shift in schedule.shifts))
        
        return [ScheduleResponse.from_orm(schedule) for schedule in schedules]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list schedules: {str(e)}")


@router.get("/{schedule_id}", response_model=ScheduleResponse)
async def get_schedule(
    schedule_id: uuid.UUID,
    include_shifts: bool = Query(False),
    include_variants: bool = Query(False),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get schedule details by ID"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Add computed fields
        schedule.shift_count = len(schedule.shifts)
        schedule.employee_count = len(set(shift.employee_id for shift in schedule.shifts))
        
        response = ScheduleResponse.from_orm(schedule)
        
        # Add additional data if requested
        if include_shifts:
            response.shifts = [shift for shift in schedule.shifts]
        
        if include_variants:
            response.variants = [variant for variant in schedule.variants]
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get schedule: {str(e)}")


@router.put("/{schedule_id}", response_model=ScheduleResponse)
async def update_schedule(
    schedule_id: uuid.UUID,
    schedule_data: ScheduleUpdate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Update schedule"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Don't allow updating published schedules without proper permissions
        if schedule.status == ScheduleStatus.PUBLISHED and not current_user.has_permission("schedules.publish"):
            raise HTTPException(status_code=403, detail="Cannot modify published schedule")
        
        # Update fields
        update_data = schedule_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(schedule, field, value)
        
        schedule.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(schedule)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.updated",
            {
                "schedule_id": str(schedule.id),
                "name": schedule.name,
                "updated_by": str(current_user.id),
                "changes": update_data
            }
        )
        
        # Add computed fields
        schedule.shift_count = len(schedule.shifts)
        schedule.employee_count = len(set(shift.employee_id for shift in schedule.shifts))
        
        return ScheduleResponse.from_orm(schedule)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update schedule: {str(e)}")


@router.delete("/{schedule_id}")
async def delete_schedule(
    schedule_id: uuid.UUID,
    force: bool = Query(False, description="Force delete even if published"),
    current_user: User = Depends(require_permissions(["schedules.delete"])),
    db: Session = Depends(get_db)
):
    """Delete schedule"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check if schedule can be deleted
        if schedule.status == ScheduleStatus.PUBLISHED and not force:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete published schedule. Use force=true to override."
            )
        
        if schedule.status == ScheduleStatus.ACTIVE and not force:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete active schedule. Use force=true to override."
            )
        
        # Store schedule info for notification
        schedule_info = {
            "schedule_id": str(schedule.id),
            "name": schedule.name,
            "deleted_by": str(current_user.id),
            "organization_id": str(schedule.organization_id)
        }
        
        # Delete schedule (cascading will handle related records)
        db.delete(schedule)
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.deleted",
            schedule_info
        )
        
        return {"message": "Schedule deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete schedule: {str(e)}")


@router.post("/{schedule_id}/publish", response_model=SchedulePublishResponse)
async def publish_schedule(
    schedule_id: uuid.UUID,
    publish_request: SchedulePublishRequest,
    current_user: User = Depends(require_permissions(["schedules.publish"])),
    db: Session = Depends(get_db),
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """Publish schedule to employees"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Validate schedule before publishing
        validation_result = await ScheduleService.validate_schedule(schedule_id, db)
        if not validation_result.is_valid:
            critical_errors = [error for error in validation_result.errors if error.get("severity") == "critical"]
            if critical_errors:
                raise HTTPException(
                    status_code=400,
                    detail=f"Cannot publish schedule with {len(critical_errors)} critical errors"
                )
        
        # Update schedule status
        schedule.status = ScheduleStatus.PUBLISHED
        schedule.published_at = datetime.utcnow()
        schedule.published_by = current_user.id
        
        # Create publication record
        from ....models.schedule import SchedulePublication
        publication = SchedulePublication(
            schedule_id=schedule_id,
            publication_type=publish_request.publication_type,
            target_audience=publish_request.target_audience,
            channels=publish_request.channels,
            publication_data={"schedule_id": str(schedule_id), "name": schedule.name},
            template_used=publish_request.template_name,
            status="published" if not publish_request.scheduled_at else "scheduled",
            scheduled_at=publish_request.scheduled_at,
            published_at=datetime.utcnow() if not publish_request.scheduled_at else None,
            created_by=current_user.id
        )
        
        db.add(publication)
        db.commit()
        db.refresh(publication)
        
        # Send notifications via background task
        background_tasks.add_task(
            ScheduleService.send_schedule_notifications,
            schedule_id,
            publication.id,
            current_user.id
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.published",
            {
                "schedule_id": str(schedule.id),
                "name": schedule.name,
                "published_by": str(current_user.id),
                "publication_type": publish_request.publication_type,
                "channels": publish_request.channels
            }
        )
        
        return SchedulePublishResponse.from_orm(publication)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to publish schedule: {str(e)}")


@router.post("/{schedule_id}/variants", response_model=ScheduleVariantResponse)
async def create_schedule_variant(
    schedule_id: uuid.UUID,
    variant_data: ScheduleVariantCreate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Create a schedule variant"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Create variant
        variant = ScheduleVariant(
            schedule_id=schedule_id,
            **variant_data.dict(),
            created_by=current_user.id
        )
        
        db.add(variant)
        db.commit()
        db.refresh(variant)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.variant_created",
            {
                "schedule_id": str(schedule_id),
                "variant_id": str(variant.id),
                "variant_name": variant.name,
                "created_by": str(current_user.id)
            }
        )
        
        return ScheduleVariantResponse.from_orm(variant)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create schedule variant: {str(e)}")