"""
Conflict Resolution API Endpoints
5 endpoints for managing schedule conflicts and resolutions
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleConflict, ScheduleRule
from ....models.user import User
from ....services.schedule_service import ScheduleService
from ....services.conflict_resolution_service import ConflictResolutionService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    ScheduleConflictResponse, ConflictResolution, ScheduleRuleCreate,
    ScheduleRuleUpdate, ScheduleRuleResponse, ConflictSeverity, ConflictStatus
)

router = APIRouter()


@router.get("/", response_model=List[ScheduleConflictResponse])
async def list_conflicts(
    schedule_id: Optional[uuid.UUID] = Query(None),
    severity: Optional[ConflictSeverity] = Query(None),
    status: Optional[ConflictStatus] = Query(None),
    conflict_type: Optional[str] = Query(None),
    employee_id: Optional[uuid.UUID] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """List schedule conflicts with filtering"""
    try:
        query = db.query(ScheduleConflict)
        
        # Apply filters
        if schedule_id:
            query = query.filter(ScheduleConflict.schedule_id == schedule_id)
        
        if severity:
            query = query.filter(ScheduleConflict.severity == severity.value)
        
        if status:
            query = query.filter(ScheduleConflict.status == status.value)
        
        if conflict_type:
            query = query.filter(ScheduleConflict.conflict_type == conflict_type)
        
        if employee_id:
            query = query.filter(ScheduleConflict.affected_employees.contains([str(employee_id)]))
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.join(Schedule).filter(Schedule.organization_id == current_user.organization_id)
        
        conflicts = query.order_by(
            ScheduleConflict.severity.desc(),
            ScheduleConflict.detected_at.desc()
        ).offset(skip).limit(limit).all()
        
        return [ScheduleConflictResponse.from_orm(conflict) for conflict in conflicts]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list conflicts: {str(e)}")


@router.get("/{conflict_id}", response_model=ScheduleConflictResponse)
async def get_conflict(
    conflict_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get conflict details by ID"""
    try:
        conflict = db.query(ScheduleConflict).filter(ScheduleConflict.id == conflict_id).first()
        
        if not conflict:
            raise HTTPException(status_code=404, detail="Conflict not found")
        
        # Organization check
        schedule = db.query(Schedule).filter(Schedule.id == conflict.schedule_id).first()
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        return ScheduleConflictResponse.from_orm(conflict)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get conflict: {str(e)}")


@router.post("/{conflict_id}/resolve")
async def resolve_conflict(
    conflict_id: uuid.UUID,
    resolution: ConflictResolution,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Resolve a schedule conflict"""
    try:
        conflict = db.query(ScheduleConflict).filter(ScheduleConflict.id == conflict_id).first()
        
        if not conflict:
            raise HTTPException(status_code=404, detail="Conflict not found")
        
        # Organization check
        schedule = db.query(Schedule).filter(Schedule.id == conflict.schedule_id).first()
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        if conflict.status == "resolved":
            raise HTTPException(status_code=400, detail="Conflict is already resolved")
        
        # Apply resolution
        resolution_result = await ConflictResolutionService.resolve_conflict(
            conflict_id,
            resolution.resolution_type,
            resolution.resolution_data,
            resolution.apply_immediately,
            current_user.id,
            db
        )
        
        if resolution_result.success:
            # Update conflict status
            conflict.status = "resolved"
            conflict.resolution_notes = resolution.resolution_notes
            conflict.resolved_at = datetime.utcnow()
            conflict.resolved_by = current_user.id
            
            db.commit()
            
            # Send WebSocket notification
            await websocket_manager.broadcast_schedule_event(
                "schedule.conflict_resolved",
                {
                    "conflict_id": str(conflict_id),
                    "schedule_id": str(conflict.schedule_id),
                    "conflict_type": conflict.conflict_type,
                    "resolution_type": resolution.resolution_type,
                    "resolved_by": str(current_user.id),
                    "resolved_at": conflict.resolved_at.isoformat()
                }
            )
            
            return {
                "message": "Conflict resolved successfully",
                "conflict_id": str(conflict_id),
                "resolution_type": resolution.resolution_type,
                "resolved_at": conflict.resolved_at.isoformat(),
                "details": resolution_result.details
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Failed to resolve conflict: {resolution_result.error_message}"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to resolve conflict: {str(e)}")


@router.post("/{conflict_id}/acknowledge")
async def acknowledge_conflict(
    conflict_id: uuid.UUID,
    notes: Optional[str] = None,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Acknowledge a conflict without resolving it"""
    try:
        conflict = db.query(ScheduleConflict).filter(ScheduleConflict.id == conflict_id).first()
        
        if not conflict:
            raise HTTPException(status_code=404, detail="Conflict not found")
        
        # Organization check
        schedule = db.query(Schedule).filter(Schedule.id == conflict.schedule_id).first()
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        if conflict.status in ["resolved", "acknowledged"]:
            raise HTTPException(status_code=400, detail="Conflict is already acknowledged or resolved")
        
        # Update conflict status
        conflict.status = "acknowledged"
        conflict.resolution_notes = notes
        conflict.resolved_by = current_user.id
        conflict.resolved_at = datetime.utcnow()
        
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.conflict_acknowledged",
            {
                "conflict_id": str(conflict_id),
                "schedule_id": str(conflict.schedule_id),
                "conflict_type": conflict.conflict_type,
                "acknowledged_by": str(current_user.id),
                "acknowledged_at": conflict.resolved_at.isoformat()
            }
        )
        
        return {
            "message": "Conflict acknowledged successfully",
            "conflict_id": str(conflict_id),
            "acknowledged_at": conflict.resolved_at.isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to acknowledge conflict: {str(e)}")


@router.post("/batch-resolve")
async def batch_resolve_conflicts(
    conflict_ids: List[uuid.UUID],
    resolution: ConflictResolution,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Resolve multiple conflicts with the same resolution"""
    try:
        if not conflict_ids:
            raise HTTPException(status_code=400, detail="No conflicts provided")
        
        if len(conflict_ids) > 50:
            raise HTTPException(status_code=400, detail="Cannot resolve more than 50 conflicts at once")
        
        # Get all conflicts
        conflicts = db.query(ScheduleConflict).filter(
            ScheduleConflict.id.in_(conflict_ids)
        ).all()
        
        if len(conflicts) != len(conflict_ids):
            raise HTTPException(status_code=404, detail="Some conflicts not found")
        
        # Check organization access for all conflicts
        if not current_user.is_superuser:
            schedule_ids = [conflict.schedule_id for conflict in conflicts]
            schedules = db.query(Schedule).filter(Schedule.id.in_(schedule_ids)).all()
            
            for schedule in schedules:
                if schedule.organization_id != current_user.organization_id:
                    raise HTTPException(status_code=403, detail="Access denied")
        
        # Resolve conflicts
        results = []
        resolved_count = 0
        failed_count = 0
        
        for conflict in conflicts:
            if conflict.status == "resolved":
                results.append({
                    "conflict_id": str(conflict.id),
                    "status": "already_resolved",
                    "message": "Conflict was already resolved"
                })
                continue
            
            try:
                resolution_result = await ConflictResolutionService.resolve_conflict(
                    conflict.id,
                    resolution.resolution_type,
                    resolution.resolution_data,
                    resolution.apply_immediately,
                    current_user.id,
                    db
                )
                
                if resolution_result.success:
                    conflict.status = "resolved"
                    conflict.resolution_notes = resolution.resolution_notes
                    conflict.resolved_at = datetime.utcnow()
                    conflict.resolved_by = current_user.id
                    
                    results.append({
                        "conflict_id": str(conflict.id),
                        "status": "resolved",
                        "message": "Conflict resolved successfully"
                    })
                    resolved_count += 1
                else:
                    results.append({
                        "conflict_id": str(conflict.id),
                        "status": "failed",
                        "message": resolution_result.error_message
                    })
                    failed_count += 1
                    
            except Exception as e:
                results.append({
                    "conflict_id": str(conflict.id),
                    "status": "failed",
                    "message": str(e)
                })
                failed_count += 1
        
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.conflicts_batch_resolved",
            {
                "total_conflicts": len(conflicts),
                "resolved_count": resolved_count,
                "failed_count": failed_count,
                "resolution_type": resolution.resolution_type,
                "resolved_by": str(current_user.id)
            }
        )
        
        return {
            "message": f"Batch resolution completed: {resolved_count} resolved, {failed_count} failed",
            "total_conflicts": len(conflicts),
            "resolved_count": resolved_count,
            "failed_count": failed_count,
            "results": results
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to batch resolve conflicts: {str(e)}")


@router.post("/detect")
async def detect_conflicts(
    schedule_id: uuid.UUID,
    redetect: bool = Query(False, description="Clear existing conflicts and redetect"),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Detect conflicts in a schedule"""
    try:
        # Check if schedule exists and user has access
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Organization check
        if not current_user.is_superuser and schedule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Clear existing conflicts if redetecting
        if redetect:
            db.query(ScheduleConflict).filter(
                ScheduleConflict.schedule_id == schedule_id
            ).delete()
        
        # Detect conflicts
        detection_result = await ScheduleService.detect_schedule_conflicts(
            schedule_id, current_user.organization_id, db
        )
        
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.conflicts_detected",
            {
                "schedule_id": str(schedule_id),
                "conflicts_found": detection_result.conflicts_found,
                "critical_conflicts": detection_result.critical_conflicts,
                "major_conflicts": detection_result.major_conflicts,
                "minor_conflicts": detection_result.minor_conflicts,
                "detected_by": str(current_user.id)
            }
        )
        
        return {
            "message": "Conflict detection completed",
            "schedule_id": str(schedule_id),
            "conflicts_found": detection_result.conflicts_found,
            "breakdown": {
                "critical": detection_result.critical_conflicts,
                "major": detection_result.major_conflicts,
                "minor": detection_result.minor_conflicts,
                "warnings": detection_result.warnings
            },
            "detection_time_ms": detection_result.detection_time_ms
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to detect conflicts: {str(e)}")


@router.get("/rules", response_model=List[ScheduleRuleResponse])
async def list_schedule_rules(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    rule_type: Optional[str] = Query(None),
    is_active: Optional[bool] = Query(None),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """List schedule rules"""
    try:
        query = db.query(ScheduleRule)
        
        # Apply filters
        if rule_type:
            query = query.filter(ScheduleRule.rule_type == rule_type)
        
        if is_active is not None:
            query = query.filter(ScheduleRule.is_active == is_active)
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.filter(ScheduleRule.organization_id == current_user.organization_id)
        
        rules = query.order_by(ScheduleRule.priority, ScheduleRule.name).offset(skip).limit(limit).all()
        
        return [ScheduleRuleResponse.from_orm(rule) for rule in rules]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list rules: {str(e)}")


@router.post("/rules", response_model=ScheduleRuleResponse)
async def create_schedule_rule(
    rule_data: ScheduleRuleCreate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Create a new schedule rule"""
    try:
        # Check if rule name already exists in organization
        existing_rule = db.query(ScheduleRule).filter(
            ScheduleRule.name == rule_data.name,
            ScheduleRule.organization_id == current_user.organization_id
        ).first()
        
        if existing_rule:
            raise HTTPException(
                status_code=400,
                detail=f"Rule with name '{rule_data.name}' already exists"
            )
        
        # Create rule
        rule = ScheduleRule(
            **rule_data.dict(),
            organization_id=current_user.organization_id,
            created_by=current_user.id
        )
        
        db.add(rule)
        db.commit()
        db.refresh(rule)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.rule_created",
            {
                "rule_id": str(rule.id),
                "name": rule.name,
                "rule_type": rule.rule_type,
                "rule_category": rule.rule_category,
                "created_by": str(current_user.id),
                "organization_id": str(current_user.organization_id)
            }
        )
        
        return ScheduleRuleResponse.from_orm(rule)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create rule: {str(e)}")


@router.get("/rules/{rule_id}", response_model=ScheduleRuleResponse)
async def get_schedule_rule(
    rule_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get schedule rule details"""
    try:
        rule = db.query(ScheduleRule).filter(ScheduleRule.id == rule_id).first()
        
        if not rule:
            raise HTTPException(status_code=404, detail="Rule not found")
        
        # Organization check
        if not current_user.is_superuser and rule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        return ScheduleRuleResponse.from_orm(rule)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get rule: {str(e)}")


@router.put("/rules/{rule_id}", response_model=ScheduleRuleResponse)
async def update_schedule_rule(
    rule_id: uuid.UUID,
    rule_data: ScheduleRuleUpdate,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Update schedule rule"""
    try:
        rule = db.query(ScheduleRule).filter(ScheduleRule.id == rule_id).first()
        
        if not rule:
            raise HTTPException(status_code=404, detail="Rule not found")
        
        # Organization check
        if not current_user.is_superuser and rule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check if name is being changed and conflicts
        if rule_data.name and rule_data.name != rule.name:
            existing_rule = db.query(ScheduleRule).filter(
                ScheduleRule.name == rule_data.name,
                ScheduleRule.organization_id == current_user.organization_id,
                ScheduleRule.id != rule_id
            ).first()
            
            if existing_rule:
                raise HTTPException(
                    status_code=400,
                    detail=f"Rule with name '{rule_data.name}' already exists"
                )
        
        # Update fields
        update_data = rule_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(rule, field, value)
        
        rule.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(rule)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.rule_updated",
            {
                "rule_id": str(rule.id),
                "name": rule.name,
                "updated_by": str(current_user.id),
                "changes": update_data
            }
        )
        
        return ScheduleRuleResponse.from_orm(rule)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update rule: {str(e)}")


@router.delete("/rules/{rule_id}")
async def delete_schedule_rule(
    rule_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["schedules.write"])),
    db: Session = Depends(get_db)
):
    """Delete schedule rule"""
    try:
        rule = db.query(ScheduleRule).filter(ScheduleRule.id == rule_id).first()
        
        if not rule:
            raise HTTPException(status_code=404, detail="Rule not found")
        
        # Organization check
        if not current_user.is_superuser and rule.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Store rule info for notification
        rule_info = {
            "rule_id": str(rule.id),
            "name": rule.name,
            "rule_type": rule.rule_type,
            "deleted_by": str(current_user.id),
            "organization_id": str(rule.organization_id)
        }
        
        # Delete rule
        db.delete(rule)
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.rule_deleted",
            rule_info
        )
        
        return {"message": "Rule deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete rule: {str(e)}")