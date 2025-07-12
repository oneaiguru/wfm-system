"""
Shift Management API Endpoints
5 endpoints for managing shift types and templates
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Shift, ScheduleTemplate
from ....models.user import User
from ....services.schedule_service import ScheduleService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    ShiftCreate, ShiftUpdate, ShiftResponse, ScheduleTemplate as ScheduleTemplateSchema,
    ShiftType
)

router = APIRouter()


@router.get("/", response_model=List[ShiftResponse])
async def list_shifts(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    shift_type: Optional[ShiftType] = Query(None),
    is_active: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    skills: Optional[List[str]] = Query(None),
    current_user: User = Depends(require_permissions(["shifts.read"])),
    db: Session = Depends(get_db)
):
    """List shift types with filtering and pagination"""
    try:
        query = db.query(Shift)
        
        # Apply filters
        if shift_type:
            query = query.filter(Shift.shift_type == shift_type.value)
        
        if is_active is not None:
            query = query.filter(Shift.is_active == is_active)
        
        if search:
            query = query.filter(
                Shift.name.ilike(f"%{search}%") |
                Shift.code.ilike(f"%{search}%") |
                Shift.description.ilike(f"%{search}%")
            )
        
        if skills:
            query = query.filter(Shift.required_skills.overlap(skills))
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.filter(Shift.organization_id == current_user.organization_id)
        
        # Apply pagination and ordering
        shifts = query.order_by(Shift.display_order, Shift.name).offset(skip).limit(limit).all()
        
        return [ShiftResponse.from_orm(shift) for shift in shifts]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list shifts: {str(e)}")


@router.post("/", response_model=ShiftResponse)
async def create_shift(
    shift_data: ShiftCreate,
    current_user: User = Depends(require_permissions(["shifts.write"])),
    db: Session = Depends(get_db)
):
    """Create a new shift type"""
    try:
        # Check if shift code already exists in organization
        existing_shift = db.query(Shift).filter(
            Shift.code == shift_data.code,
            Shift.organization_id == current_user.organization_id
        ).first()
        
        if existing_shift:
            raise HTTPException(
                status_code=400,
                detail=f"Shift with code '{shift_data.code}' already exists"
            )
        
        # Create shift
        shift = Shift(
            **shift_data.dict(),
            organization_id=current_user.organization_id
        )
        
        db.add(shift)
        db.commit()
        db.refresh(shift)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "shift.created",
            {
                "shift_id": str(shift.id),
                "name": shift.name,
                "code": shift.code,
                "shift_type": shift.shift_type,
                "created_by": str(current_user.id),
                "organization_id": str(current_user.organization_id)
            }
        )
        
        return ShiftResponse.from_orm(shift)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create shift: {str(e)}")


@router.get("/{shift_id}", response_model=ShiftResponse)
async def get_shift(
    shift_id: uuid.UUID,
    current_user: User = Depends(require_permissions(["shifts.read"])),
    db: Session = Depends(get_db)
):
    """Get shift details by ID"""
    try:
        shift = db.query(Shift).filter(Shift.id == shift_id).first()
        
        if not shift:
            raise HTTPException(status_code=404, detail="Shift not found")
        
        # Organization check
        if not current_user.is_superuser and shift.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        return ShiftResponse.from_orm(shift)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get shift: {str(e)}")


@router.put("/{shift_id}", response_model=ShiftResponse)
async def update_shift(
    shift_id: uuid.UUID,
    shift_data: ShiftUpdate,
    current_user: User = Depends(require_permissions(["shifts.write"])),
    db: Session = Depends(get_db)
):
    """Update shift type"""
    try:
        shift = db.query(Shift).filter(Shift.id == shift_id).first()
        
        if not shift:
            raise HTTPException(status_code=404, detail="Shift not found")
        
        # Organization check
        if not current_user.is_superuser and shift.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check if code is being changed and conflicts with existing
        if shift_data.code and shift_data.code != shift.code:
            existing_shift = db.query(Shift).filter(
                Shift.code == shift_data.code,
                Shift.organization_id == current_user.organization_id,
                Shift.id != shift_id
            ).first()
            
            if existing_shift:
                raise HTTPException(
                    status_code=400,
                    detail=f"Shift with code '{shift_data.code}' already exists"
                )
        
        # Update fields
        update_data = shift_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(shift, field, value)
        
        shift.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(shift)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "shift.updated",
            {
                "shift_id": str(shift.id),
                "name": shift.name,
                "code": shift.code,
                "updated_by": str(current_user.id),
                "changes": update_data
            }
        )
        
        return ShiftResponse.from_orm(shift)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update shift: {str(e)}")


@router.delete("/{shift_id}")
async def delete_shift(
    shift_id: uuid.UUID,
    force: bool = Query(False, description="Force delete even if used in schedules"),
    current_user: User = Depends(require_permissions(["shifts.delete"])),
    db: Session = Depends(get_db)
):
    """Delete shift type"""
    try:
        shift = db.query(Shift).filter(Shift.id == shift_id).first()
        
        if not shift:
            raise HTTPException(status_code=404, detail="Shift not found")
        
        # Organization check
        if not current_user.is_superuser and shift.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check if shift is used in schedules
        if not force:
            from ....models.schedule import ScheduleShift
            
            usage_count = db.query(ScheduleShift).filter(
                ScheduleShift.shift_id == shift_id
            ).count()
            
            if usage_count > 0:
                raise HTTPException(
                    status_code=400,
                    detail=f"Cannot delete shift used in {usage_count} schedule assignments. Use force=true to override."
                )
        
        # Store shift info for notification
        shift_info = {
            "shift_id": str(shift.id),
            "name": shift.name,
            "code": shift.code,
            "deleted_by": str(current_user.id),
            "organization_id": str(shift.organization_id)
        }
        
        # Delete shift
        db.delete(shift)
        db.commit()
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "shift.deleted",
            shift_info
        )
        
        return {"message": "Shift deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete shift: {str(e)}")


@router.post("/templates", response_model=Dict[str, Any])
async def create_shift_templates(
    template_data: ScheduleTemplateSchema,
    current_user: User = Depends(require_permissions(["shifts.write"])),
    db: Session = Depends(get_db)
):
    """Create shift templates from predefined patterns"""
    try:
        # Create common shift templates based on the template type
        created_shifts = []
        
        if template_data.template_type == "24x7":
            # Create 24/7 shift templates
            shift_templates = [
                {
                    "name": "Morning Shift",
                    "code": "AM",
                    "description": "Standard morning shift",
                    "start_time": "06:00",
                    "end_time": "14:00",
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 30,
                    "shift_type": "regular",
                    "color_code": "#4CAF50"
                },
                {
                    "name": "Afternoon Shift",
                    "code": "PM",
                    "description": "Standard afternoon shift", 
                    "start_time": "14:00",
                    "end_time": "22:00",
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 30,
                    "shift_type": "regular",
                    "color_code": "#FF9800"
                },
                {
                    "name": "Night Shift",
                    "code": "NT",
                    "description": "Overnight shift",
                    "start_time": "22:00",
                    "end_time": "06:00",
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 30,
                    "shift_type": "regular",
                    "color_code": "#9C27B0"
                }
            ]
        elif template_data.template_type == "standard":
            # Create standard business hours shifts
            shift_templates = [
                {
                    "name": "Standard Day",
                    "code": "STD",
                    "description": "Standard 9-5 shift",
                    "start_time": "09:00",
                    "end_time": "17:00",
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 60,
                    "shift_type": "regular",
                    "color_code": "#2196F3"
                },
                {
                    "name": "Early Start",
                    "code": "EARLY",
                    "description": "Early morning shift",
                    "start_time": "07:00",
                    "end_time": "15:00", 
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 60,
                    "shift_type": "regular",
                    "color_code": "#00BCD4"
                },
                {
                    "name": "Late Finish",
                    "code": "LATE",
                    "description": "Late afternoon shift",
                    "start_time": "11:00",
                    "end_time": "19:00",
                    "duration_minutes": 480,
                    "break_duration_minutes": 30,
                    "lunch_duration_minutes": 60,
                    "shift_type": "regular",
                    "color_code": "#FF5722"
                }
            ]
        else:
            # Custom template - use provided shift patterns
            shift_templates = template_data.shift_patterns
        
        # Create shifts from templates
        for template in shift_templates:
            # Check if shift with this code already exists
            existing_shift = db.query(Shift).filter(
                Shift.code == template["code"],
                Shift.organization_id == current_user.organization_id
            ).first()
            
            if existing_shift:
                continue  # Skip if already exists
            
            # Parse times
            from datetime import time
            
            start_time = time.fromisoformat(template["start_time"])
            end_time = time.fromisoformat(template["end_time"])
            
            # Create shift
            shift = Shift(
                name=template["name"],
                code=template["code"],
                description=template.get("description", ""),
                start_time=start_time,
                end_time=end_time,
                duration_minutes=template.get("duration_minutes", 480),
                break_duration_minutes=template.get("break_duration_minutes", 30),
                lunch_duration_minutes=template.get("lunch_duration_minutes", 30),
                shift_type=template.get("shift_type", "regular"),
                min_staff=template.get("min_staff", 1),
                max_staff=template.get("max_staff"),
                required_skills=template.get("required_skills", []),
                color_code=template.get("color_code", "#3498db"),
                organization_id=current_user.organization_id
            )
            
            db.add(shift)
            created_shifts.append(shift)
        
        if created_shifts:
            db.commit()
            
            # Refresh all created shifts
            for shift in created_shifts:
                db.refresh(shift)
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "shift.templates_created",
            {
                "template_type": template_data.template_type,
                "shifts_created": len(created_shifts),
                "shift_codes": [shift.code for shift in created_shifts],
                "created_by": str(current_user.id),
                "organization_id": str(current_user.organization_id)
            }
        )
        
        return {
            "message": f"Created {len(created_shifts)} shift templates",
            "template_type": template_data.template_type,
            "shifts_created": len(created_shifts),
            "shifts": [
                {
                    "id": str(shift.id),
                    "name": shift.name,
                    "code": shift.code,
                    "start_time": shift.start_time.isoformat(),
                    "end_time": shift.end_time.isoformat()
                }
                for shift in created_shifts
            ]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create shift templates: {str(e)}")


@router.get("/templates/preview")
async def preview_shift_templates(
    template_type: str = Query(..., regex=r'^(24x7|standard|custom)$'),
    current_user: User = Depends(require_permissions(["shifts.read"])),
    db: Session = Depends(get_db)
):
    """Preview shift templates without creating them"""
    try:
        if template_type == "24x7":
            templates = [
                {
                    "name": "Morning Shift",
                    "code": "AM",
                    "description": "Standard morning shift (6 AM - 2 PM)",
                    "start_time": "06:00",
                    "end_time": "14:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#4CAF50"
                },
                {
                    "name": "Afternoon Shift",
                    "code": "PM", 
                    "description": "Standard afternoon shift (2 PM - 10 PM)",
                    "start_time": "14:00",
                    "end_time": "22:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#FF9800"
                },
                {
                    "name": "Night Shift",
                    "code": "NT",
                    "description": "Overnight shift (10 PM - 6 AM)",
                    "start_time": "22:00",
                    "end_time": "06:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#9C27B0"
                }
            ]
        elif template_type == "standard":
            templates = [
                {
                    "name": "Standard Day",
                    "code": "STD",
                    "description": "Standard business hours (9 AM - 5 PM)",
                    "start_time": "09:00",
                    "end_time": "17:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#2196F3"
                },
                {
                    "name": "Early Start",
                    "code": "EARLY",
                    "description": "Early morning shift (7 AM - 3 PM)",
                    "start_time": "07:00",
                    "end_time": "15:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#00BCD4"
                },
                {
                    "name": "Late Finish",
                    "code": "LATE", 
                    "description": "Late afternoon shift (11 AM - 7 PM)",
                    "start_time": "11:00",
                    "end_time": "19:00",
                    "duration_hours": 8,
                    "shift_type": "regular",
                    "color_code": "#FF5722"
                }
            ]
        else:
            templates = []
        
        # Check which templates already exist
        existing_codes = set()
        if templates:
            codes = [t["code"] for t in templates]
            existing_shifts = db.query(Shift).filter(
                Shift.code.in_(codes),
                Shift.organization_id == current_user.organization_id
            ).all()
            existing_codes = set(shift.code for shift in existing_shifts)
        
        # Mark existing templates
        for template in templates:
            template["already_exists"] = template["code"] in existing_codes
        
        return {
            "template_type": template_type,
            "templates": templates,
            "total_templates": len(templates),
            "existing_templates": len(existing_codes),
            "new_templates": len(templates) - len(existing_codes)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to preview templates: {str(e)}")