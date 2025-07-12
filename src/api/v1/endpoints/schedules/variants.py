"""
Schedule Variants & Publishing API Endpoints
5 endpoints for managing schedule variants and publishing
"""

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleVariant, SchedulePublication
from ....models.user import User
from ....services.schedule_service import ScheduleService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    ScheduleVariantCreate, ScheduleVariantUpdate, ScheduleVariantResponse,
    SchedulePublishRequest, SchedulePublishResponse
)

router = APIRouter()


@router.get("/{schedule_id}/variants", response_model=List[ScheduleVariantResponse])
async def list_schedule_variants(
    schedule_id: uuid.UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    is_active: Optional[bool] = Query(None),
    is_approved: Optional[bool] = Query(None),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """List schedule variants"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Query variants
        query = db.query(ScheduleVariant).filter(ScheduleVariant.schedule_id == schedule_id)
        
        if is_active is not None:
            query = query.filter(ScheduleVariant.is_active == is_active)
        
        if is_approved is not None:
            query = query.filter(ScheduleVariant.is_approved == is_approved)
        
        variants = query.order_by(ScheduleVariant.created_at.desc()).offset(skip).limit(limit).all()
        
        return [ScheduleVariantResponse.from_orm(variant) for variant in variants]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list variants: {str(e)}")


@router.post("/{schedule_id}/variants", response_model=ScheduleVariantResponse)
async def create_schedule_variant(
    schedule_id: uuid.UUID,
    variant_data: ScheduleVariantCreate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Create a new schedule variant"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Analyze variant data and calculate impact metrics
        impact_analysis = await ScheduleService.analyze_variant_impact(
            schedule_id, variant_data.variant_data, db
        )
        
        # Create variant
        variant = ScheduleVariant(
            schedule_id=schedule_id,
            name=variant_data.name,
            description=variant_data.description,
            variant_data=variant_data.variant_data,
            changes_summary=variant_data.changes_summary,
            cost_impact=impact_analysis.get("cost_impact"),
            coverage_impact=impact_analysis.get("coverage_impact"),
            employee_satisfaction=impact_analysis.get("employee_satisfaction"),
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
                "cost_impact": float(variant.cost_impact) if variant.cost_impact else None,
                "coverage_impact": float(variant.coverage_impact) if variant.coverage_impact else None,
                "created_by": str(current_user.id)
            }
        )
        
        return ScheduleVariantResponse.from_orm(variant)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create variant: {str(e)}")


@router.get("/{schedule_id}/variants/{variant_id}", response_model=ScheduleVariantResponse)
async def get_schedule_variant(
    schedule_id: uuid.UUID,
    variant_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get schedule variant details"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get variant
        variant = db.query(ScheduleVariant).filter(
            ScheduleVariant.id == variant_id,
            ScheduleVariant.schedule_id == schedule_id
        ).first()
        
        if not variant:
            raise HTTPException(status_code=404, detail="Variant not found")
        
        return ScheduleVariantResponse.from_orm(variant)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get variant: {str(e)}")


@router.put("/{schedule_id}/variants/{variant_id}", response_model=ScheduleVariantResponse)
async def update_schedule_variant(
    schedule_id: uuid.UUID,
    variant_id: uuid.UUID,
    variant_data: ScheduleVariantUpdate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Update schedule variant"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get variant
        variant = db.query(ScheduleVariant).filter(
            ScheduleVariant.id == variant_id,
            ScheduleVariant.schedule_id == schedule_id
        ).first()
        
        if not variant:
            raise HTTPException(status_code=404, detail="Variant not found")
        
        # Don't allow updating approved variants without proper permissions
        if variant.is_approved and not current_user.has_permission("schedules.publish"):
            raise HTTPException(status_code=403, detail="Cannot modify approved variant")
        
        # Update fields
        update_data = variant_data.dict(exclude_unset=True)
        
        # Recalculate impact if variant data changed
        if "variant_data" in update_data:
            impact_analysis = await ScheduleService.analyze_variant_impact(
                schedule_id, update_data["variant_data"], db
            )
            update_data.update({
                "cost_impact": impact_analysis.get("cost_impact"),
                "coverage_impact": impact_analysis.get("coverage_impact"),
                "employee_satisfaction": impact_analysis.get("employee_satisfaction")
            })
        
        for field, value in update_data.items():
            setattr(variant, field, value)
        
        db.commit()
        db.refresh(variant)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.variant_updated",
            {
                "schedule_id": str(schedule_id),
                "variant_id": str(variant.id),
                "variant_name": variant.name,
                "updated_by": str(current_user.id),
                "changes": update_data
            }
        )
        
        return ScheduleVariantResponse.from_orm(variant)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update variant: {str(e)}")


@router.delete("/{schedule_id}/variants/{variant_id}")
async def delete_schedule_variant(
    schedule_id: uuid.UUID,
    variant_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Delete schedule variant"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get variant
        variant = db.query(ScheduleVariant).filter(
            ScheduleVariant.id == variant_id,
            ScheduleVariant.schedule_id == schedule_id
        ).first()
        
        if not variant:
            raise HTTPException(status_code=404, detail="Variant not found")
        
        # Don't allow deleting approved variants without proper permissions
        if variant.is_approved and not current_user.has_permission("schedules.publish"):
            raise HTTPException(status_code=403, detail="Cannot delete approved variant")
        
        # Store variant info for notification
        variant_info = {
            "schedule_id": str(schedule_id),
            "variant_id": str(variant.id),
            "variant_name": variant.name,
            "deleted_by": str(current_user.id)
        }
        
        # Delete variant
        db.delete(variant)
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.variant_deleted",
            variant_info
        )
        
        return {"message": "Variant deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete variant: {str(e)}")


@router.post("/{schedule_id}/publish", response_model=SchedulePublishResponse)
async def publish_schedule(
    schedule_id: uuid.UUID,
    publish_request: SchedulePublishRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["schedules.publish"])),
    db: Session = Depends(get_db)
):
    """Publish schedule to employees"""
    try:
        # Check if schedule exists and user has access
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
        
        # Create publication record
        publication = SchedulePublication(
            schedule_id=schedule_id,
            publication_type=publish_request.publication_type,
            target_audience=publish_request.target_audience,
            channels=publish_request.channels,
            publication_data={
                "schedule_id": str(schedule_id),
                "name": schedule.name,
                "custom_message": publish_request.custom_message,
                "include_changes": publish_request.include_changes
            },
            template_used=publish_request.template_name,
            status="scheduled" if publish_request.scheduled_at else "published",
            scheduled_at=publish_request.scheduled_at,
            published_at=datetime.utcnow() if not publish_request.scheduled_at else None,
            created_by=current_user.id
        )
        
        db.add(publication)
        
        # Update schedule status if publishing immediately
        if not publish_request.scheduled_at:
            schedule.status = "published"
            schedule.published_at = datetime.utcnow()
            schedule.published_by = current_user.id
        
        db.commit()
        db.refresh(publication)
        
        # Send notifications via background task
        if not publish_request.scheduled_at:
            background_tasks.add_task(
                ScheduleService.send_schedule_notifications,
                schedule_id,
                publication.id,
                current_user.id
            )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.publication_created",
            {
                "schedule_id": str(schedule_id),
                "publication_id": str(publication.id),
                "publication_type": publish_request.publication_type,
                "status": publication.status,
                "scheduled_at": publish_request.scheduled_at.isoformat() if publish_request.scheduled_at else None,
                "channels": publish_request.channels,
                "created_by": str(current_user.id)
            }
        )
        
        return SchedulePublishResponse.from_orm(publication)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to publish schedule: {str(e)}")


@router.get("/{schedule_id}/publications", response_model=List[SchedulePublishResponse])
async def list_schedule_publications(
    schedule_id: uuid.UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """List schedule publications"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Query publications
        query = db.query(SchedulePublication).filter(SchedulePublication.schedule_id == schedule_id)
        
        if status:
            query = query.filter(SchedulePublication.status == status)
        
        publications = query.order_by(SchedulePublication.created_at.desc()).offset(skip).limit(limit).all()
        
        return [SchedulePublishResponse.from_orm(pub) for pub in publications]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list publications: {str(e)}")


@router.post("/{schedule_id}/variants/{variant_id}/approve")
async def approve_schedule_variant(
    schedule_id: uuid.UUID,
    variant_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.publish"])),
    db: Session = Depends(get_db)
):
    """Approve schedule variant"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get variant
        variant = db.query(ScheduleVariant).filter(
            ScheduleVariant.id == variant_id,
            ScheduleVariant.schedule_id == schedule_id
        ).first()
        
        if not variant:
            raise HTTPException(status_code=404, detail="Variant not found")
        
        if variant.is_approved:
            raise HTTPException(status_code=400, detail="Variant is already approved")
        
        # Approve variant
        variant.is_approved = True
        variant.approved_by = current_user.id
        variant.approved_at = datetime.utcnow()
        
        db.commit()
        db.refresh(variant)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.variant_approved",
            {
                "schedule_id": str(schedule_id),
                "variant_id": str(variant.id),
                "variant_name": variant.name,
                "approved_by": str(current_user.id),
                "approved_at": variant.approved_at.isoformat()
            }
        )
        
        return {
            "message": "Variant approved successfully",
            "variant_id": str(variant.id),
            "approved_at": variant.approved_at.isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to approve variant: {str(e)}")


@router.post("/{schedule_id}/variants/{variant_id}/apply")
async def apply_schedule_variant(
    schedule_id: uuid.UUID,
    variant_id: uuid.UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Apply approved variant to schedule"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get variant
        variant = db.query(ScheduleVariant).filter(
            ScheduleVariant.id == variant_id,
            ScheduleVariant.schedule_id == schedule_id
        ).first()
        
        if not variant:
            raise HTTPException(status_code=404, detail="Variant not found")
        
        if not variant.is_approved:
            raise HTTPException(status_code=400, detail="Variant must be approved before applying")
        
        # Apply variant in background task
        background_tasks.add_task(
            ScheduleService.apply_schedule_variant,
            schedule_id,
            variant_id,
            current_user.id
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.variant_apply_started",
            {
                "schedule_id": str(schedule_id),
                "variant_id": str(variant.id),
                "variant_name": variant.name,
                "applied_by": str(current_user.id)
            }
        )
        
        return {
            "message": "Variant application started",
            "variant_id": str(variant.id),
            "status": "applying"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to apply variant: {str(e)}")