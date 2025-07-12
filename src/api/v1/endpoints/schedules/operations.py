"""
Schedule Operations API Endpoints
8 endpoints for schedule generation, optimization, and advanced operations
"""

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleConflict, ScheduleOptimization
from ....models.user import User
from ....services.schedule_service import ScheduleService
from ....services.optimization_service import OptimizationService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    ScheduleGenerate, ScheduleOptimize, ScheduleValidate, ScheduleBulkUpdate,
    ScheduleCopy, ScheduleMerge, ScheduleTemplate, ScheduleResponse,
    ScheduleConflictResponse, ValidationResult, BulkOperationResult,
    OptimizationResult
)

router = APIRouter()


@router.post("/generate", response_model=ScheduleResponse)
async def generate_schedule(
    generate_data: ScheduleGenerate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Auto-generate schedule using AI/ML algorithms"""
    try:
        # Create schedule record
        schedule = Schedule(
            name=generate_data.name,
            start_date=generate_data.start_date,
            end_date=generate_data.end_date,
            department_id=generate_data.department_id,
            template_id=generate_data.template_id,
            schedule_type="generated",
            status="draft",
            configuration={
                "optimization_level": generate_data.optimization_level,
                "constraints": generate_data.constraints,
                "preferences": generate_data.preferences,
                "coverage_requirements": generate_data.coverage_requirements
            },
            created_by=current_user.id,
            organization_id=current_user.organization_id
        )
        
        db.add(schedule)
        db.commit()
        db.refresh(schedule)
        
        # Start background generation
        background_tasks.add_task(
            ScheduleService.generate_schedule,
            schedule.id,
            generate_data.dict(),
            current_user.id
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.generation_started",
            {
                "schedule_id": str(schedule.id),
                "name": schedule.name,
                "optimization_level": generate_data.optimization_level,
                "started_by": str(current_user.id)
            }
        )
        
        return ScheduleResponse.from_orm(schedule)
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to start schedule generation: {str(e)}")


@router.post("/{schedule_id}/optimize", response_model=OptimizationResult)
async def optimize_schedule(
    schedule_id: uuid.UUID,
    optimize_data: ScheduleOptimize,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["schedules.optimize"])),
    db: Session = Depends(get_db)
):
    """Optimize existing schedule"""
    try:
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Create optimization record
        optimization = ScheduleOptimization(
            schedule_id=schedule_id,
            optimization_type="multi_objective",
            algorithm_used="genetic_algorithm_v2",
            parameters=optimize_data.dict(),
            input_data={"schedule_id": str(schedule_id)},
            output_data={},
            objective_scores={},
            status="running",
            created_by=current_user.id
        )
        
        db.add(optimization)
        db.commit()
        db.refresh(optimization)
        
        # Start optimization process
        background_tasks.add_task(
            OptimizationService.optimize_schedule,
            schedule_id,
            optimization.id,
            optimize_data.dict(),
            current_user.id
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.optimization_started",
            {
                "schedule_id": str(schedule_id),
                "optimization_id": str(optimization.id),
                "goals": optimize_data.optimization_goals,
                "started_by": str(current_user.id)
            }
        )
        
        return OptimizationResult.from_orm(optimization)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to start optimization: {str(e)}")


@router.post("/validate", response_model=ValidationResult)
async def validate_schedule(
    validate_data: ScheduleValidate,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Validate schedule against rules and constraints"""
    try:
        # Perform validation
        validation_result = await ScheduleService.validate_schedule_data(
            validate_data.schedule_data,
            validate_data.validation_rules,
            validate_data.strict_validation,
            current_user.organization_id,
            db
        )
        
        return validation_result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to validate schedule: {str(e)}")


@router.get("/conflicts", response_model=List[ScheduleConflictResponse])
async def get_schedule_conflicts(
    schedule_id: Optional[uuid.UUID] = Query(None),
    severity: Optional[str] = Query(None),
    status: Optional[str] = Query("open"),
    conflict_type: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get schedule conflicts"""
    try:
        query = db.query(ScheduleConflict)
        
        if schedule_id:
            query = query.filter(ScheduleConflict.schedule_id == schedule_id)
        
        if severity:
            query = query.filter(ScheduleConflict.severity == severity)
        
        if status:
            query = query.filter(ScheduleConflict.status == status)
        
        if conflict_type:
            query = query.filter(ScheduleConflict.conflict_type == conflict_type)
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.join(Schedule).filter(Schedule.organization_id == current_user.organization_id)
        
        conflicts = query.offset(skip).limit(limit).all()
        
        return [ScheduleConflictResponse.from_orm(conflict) for conflict in conflicts]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get conflicts: {str(e)}")


@router.post("/bulk-update", response_model=BulkOperationResult)
async def bulk_update_schedules(
    bulk_data: ScheduleBulkUpdate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Perform bulk updates on schedules"""
    try:
        start_time = datetime.utcnow()
        
        result = await ScheduleService.bulk_update_schedules(
            bulk_data.operations,
            bulk_data.validate_before_apply,
            bulk_data.rollback_on_error,
            current_user.id,
            current_user.organization_id,
            db
        )
        
        # Calculate execution time
        execution_time = int((datetime.utcnow() - start_time).total_seconds() * 1000)
        result.execution_time_ms = execution_time
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.bulk_update_completed",
            {
                "total_operations": result.total_operations,
                "successful_operations": result.successful_operations,
                "failed_operations": result.failed_operations,
                "execution_time_ms": execution_time,
                "updated_by": str(current_user.id)
            }
        )
        
        return result
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to perform bulk update: {str(e)}")


@router.post("/copy", response_model=ScheduleResponse)
async def copy_schedule(
    copy_data: ScheduleCopy,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Copy schedule to new time period"""
    try:
        source_schedule = db.query(Schedule).filter(Schedule.id == copy_data.source_schedule_id).first()
        
        if not source_schedule:
            raise HTTPException(status_code=404, detail="Source schedule not found")
        
        # Organization check
        if not current_user.is_superuser and source_schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Create new schedule
        new_schedule = Schedule(
            name=copy_data.name,
            description=f"Copy of {source_schedule.name}",
            start_date=copy_data.start_date,
            end_date=copy_data.end_date,
            schedule_type=source_schedule.schedule_type,
            department_id=copy_data.target_department_id or source_schedule.department_id,
            organization_id=current_user.organization_id,
            template_id=source_schedule.template_id,
            configuration=source_schedule.configuration,
            created_by=current_user.id,
            status="draft"
        )
        
        db.add(new_schedule)
        db.commit()
        db.refresh(new_schedule)
        
        # Copy assignments and constraints if requested
        if copy_data.copy_assignments:
            await ScheduleService.copy_schedule_assignments(
                copy_data.source_schedule_id,
                new_schedule.id,
                copy_data.start_date,
                copy_data.end_date,
                db
            )
        
        if copy_data.copy_constraints:
            await ScheduleService.copy_schedule_constraints(
                copy_data.source_schedule_id,
                new_schedule.id,
                copy_data.start_date,
                copy_data.end_date,
                db
            )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.copied",
            {
                "source_schedule_id": str(copy_data.source_schedule_id),
                "new_schedule_id": str(new_schedule.id),
                "name": new_schedule.name,
                "copied_by": str(current_user.id)
            }
        )
        
        return ScheduleResponse.from_orm(new_schedule)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to copy schedule: {str(e)}")


@router.post("/merge", response_model=ScheduleResponse)
async def merge_schedules(
    merge_data: ScheduleMerge,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Merge multiple schedules into one"""
    try:
        # Validate source schedules
        source_schedules = db.query(Schedule).filter(
            Schedule.id.in_(merge_data.source_schedule_ids)
        ).all()
        
        if len(source_schedules) != len(merge_data.source_schedule_ids):
            raise HTTPException(status_code=404, detail="One or more source schedules not found")
        
        # Organization check
        for schedule in source_schedules:
            if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Perform merge
        merged_schedule = await ScheduleService.merge_schedules(
            merge_data.source_schedule_ids,
            merge_data.name,
            merge_data.merge_strategy,
            merge_data.conflict_resolution,
            merge_data.priority_order,
            current_user.id,
            current_user.organization_id,
            db
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.merged",
            {
                "source_schedule_ids": [str(id) for id in merge_data.source_schedule_ids],
                "merged_schedule_id": str(merged_schedule.id),
                "name": merged_schedule.name,
                "merge_strategy": merge_data.merge_strategy,
                "merged_by": str(current_user.id)
            }
        )
        
        return ScheduleResponse.from_orm(merged_schedule)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to merge schedules: {str(e)}")


@router.post("/template", response_model=Dict[str, Any])
async def create_schedule_template(
    template_data: ScheduleTemplate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Create schedule template from configuration"""
    try:
        from ....models.schedule import ScheduleTemplate as ScheduleTemplateModel
        
        # Create template
        template = ScheduleTemplateModel(
            name=template_data.name,
            description=template_data.description,
            template_type=template_data.template_type,
            pattern_config=template_data.pattern_config,
            shift_patterns=template_data.shift_patterns,
            skills_required=template_data.skills_required,
            coverage_requirements=template_data.coverage_requirements,
            is_active=template_data.is_active,
            organization_id=current_user.organization_id,
            created_by=current_user.id
        )
        
        db.add(template)
        db.commit()
        db.refresh(template)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.template_created",
            {
                "template_id": str(template.id),
                "name": template.name,
                "template_type": template.template_type,
                "created_by": str(current_user.id)
            }
        )
        
        return {
            "id": str(template.id),
            "name": template.name,
            "template_type": template.template_type,
            "created_at": template.created_at.isoformat(),
            "message": "Template created successfully"
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create template: {str(e)}")