from fastapi import APIRouter, HTTPException, Path
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy import text
from typing import List, Dict, Any, Optional
from datetime import date, datetime
import json
from pydantic import BaseModel

router = APIRouter()

# Database connection - create engine once
engine = create_async_engine(
    "postgresql+asyncpg://wfm_user:wfm_password@localhost/wfm_enterprise",
    echo=False
)

class ScheduleUpdateRequest(BaseModel):
    schedule_name: Optional[str] = None
    schedule_data: Optional[Dict[str, Any]] = None
    shift_assignments: Optional[List[Dict[str, Any]]] = None
    total_hours: Optional[float] = None
    overtime_hours: Optional[float] = None
    status: Optional[str] = None
    effective_date: Optional[date] = None
    expiry_date: Optional[date] = None
    organization_ref: Optional[str] = None

class ScheduleUpdateResponse(BaseModel):
    id: str
    agent_id: int
    schedule_name: str
    schedule_data: Dict[str, Any]
    shift_assignments: List[Dict[str, Any]]
    total_hours: float
    overtime_hours: float
    status: str
    version: int
    effective_date: str
    expiry_date: Optional[str] = None
    created_by_user_id: Optional[str] = None
    organization_ref: Optional[str] = None
    created_at: str
    updated_at: str

@router.put("/api/v1/schedules/{schedule_id}", response_model=ScheduleUpdateResponse)
async def update_schedule(
    schedule_id: str = Path(..., description="Schedule ID to update"),
    request: ScheduleUpdateRequest = ...
):
    """
    Update an existing schedule record in the work_schedules_core table.
    Increments version number and validates business rules.
    """
    try:
        current_time = datetime.utcnow()
        
        # Create new session for this request
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # First check if schedule exists
            check_query = text("""
                SELECT 
                    id, agent_id, schedule_name, schedule_data, shift_assignments,
                    total_hours, overtime_hours, status, version, effective_date,
                    expiry_date, created_by_user_id, organization_ref,
                    created_at, updated_at
                FROM work_schedules_core
                WHERE id = :schedule_id
            """)
            
            result = await session.execute(check_query, {"schedule_id": schedule_id})
            existing = result.fetchone()
            
            if not existing:
                raise HTTPException(status_code=404, detail=f"Schedule {schedule_id} not found")
            
            # Check if schedule is editable (can't update locked/finalized schedules)
            if existing.status in ('locked', 'archived', 'finalized'):
                raise HTTPException(
                    status_code=409, 
                    detail=f"Cannot update schedule with status '{existing.status}'"
                )
            
            # Prepare update fields - only update provided fields
            update_fields = {}
            update_params = {"schedule_id": schedule_id, "updated_at": current_time}
            
            if request.schedule_name is not None:
                update_fields["schedule_name"] = ":schedule_name"
                update_params["schedule_name"] = request.schedule_name
            
            if request.schedule_data is not None:
                if not isinstance(request.schedule_data, dict):
                    raise HTTPException(status_code=400, detail="schedule_data must be a valid JSON object")
                update_fields["schedule_data"] = ":schedule_data"
                update_params["schedule_data"] = json.dumps(request.schedule_data)
            
            if request.shift_assignments is not None:
                if not isinstance(request.shift_assignments, list):
                    raise HTTPException(status_code=400, detail="shift_assignments must be a valid JSON array")
                update_fields["shift_assignments"] = ":shift_assignments"
                update_params["shift_assignments"] = json.dumps(request.shift_assignments)
            
            if request.total_hours is not None:
                if request.total_hours < 0 or request.total_hours > 168:
                    raise HTTPException(status_code=400, detail="total_hours must be between 0 and 168")
                update_fields["total_hours"] = ":total_hours"
                update_params["total_hours"] = request.total_hours
            
            if request.overtime_hours is not None:
                update_fields["overtime_hours"] = ":overtime_hours"
                update_params["overtime_hours"] = request.overtime_hours
            
            if request.status is not None:
                # Validate status transitions
                valid_statuses = ['draft', 'active', 'pending', 'suspended', 'locked', 'archived']
                if request.status not in valid_statuses:
                    raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")
                
                # Check valid transitions
                current_status = existing.status
                invalid_transitions = {
                    'locked': ['draft', 'pending'],
                    'archived': ['draft', 'active', 'pending', 'suspended']
                }
                
                if current_status in invalid_transitions and request.status in invalid_transitions[current_status]:
                    raise HTTPException(
                        status_code=409,
                        detail=f"Cannot change status from '{current_status}' to '{request.status}'"
                    )
                
                update_fields["status"] = ":status"
                update_params["status"] = request.status
            
            if request.effective_date is not None:
                update_fields["effective_date"] = ":effective_date"
                update_params["effective_date"] = request.effective_date
            
            if request.expiry_date is not None:
                update_fields["expiry_date"] = ":expiry_date"
                update_params["expiry_date"] = request.expiry_date
            
            if request.organization_ref is not None:
                update_fields["organization_ref"] = ":organization_ref"
                update_params["organization_ref"] = request.organization_ref
            
            # Check for date conflicts if dates are being updated
            if request.effective_date is not None or request.expiry_date is not None:
                new_start = request.effective_date if request.effective_date else existing.effective_date
                new_end = request.expiry_date if request.expiry_date else existing.expiry_date
                
                if new_end and new_start >= new_end:
                    raise HTTPException(status_code=400, detail="effective_date must be before expiry_date")
                
                # Check for overlaps with other schedules for same agent
                overlap_check_query = text("""
                    SELECT id 
                    FROM work_schedules_core 
                    WHERE agent_id = :agent_id 
                    AND id != :schedule_id
                    AND status IN ('active', 'draft')
                    AND effective_date <= :end_date
                    AND (expiry_date IS NULL OR expiry_date >= :start_date)
                """)
                
                overlap_result = await session.execute(overlap_check_query, {
                    "agent_id": existing.agent_id,
                    "schedule_id": schedule_id,
                    "start_date": new_start,
                    "end_date": new_end if new_end else date(2030, 12, 31)
                })
                
                if overlap_result.fetchone():
                    raise HTTPException(
                        status_code=409, 
                        detail=f"Updated schedule would conflict with existing schedule for agent {existing.agent_id}"
                    )
            
            if not update_fields:
                raise HTTPException(status_code=400, detail="No fields provided for update")
            
            # Increment version
            update_fields["version"] = ":version"
            update_params["version"] = existing.version + 1
            update_fields["updated_at"] = ":updated_at"
            
            # Build dynamic update query
            set_clause = ", ".join([f"{field} = {placeholder}" for field, placeholder in update_fields.items()])
            update_query = text(f"""
                UPDATE work_schedules_core 
                SET {set_clause}
                WHERE id = :schedule_id
                RETURNING *
            """)
            
            update_result = await session.execute(update_query, update_params)
            await session.commit()
            
            updated_row = update_result.fetchone()
            
            # Return the updated schedule
            return ScheduleUpdateResponse(
                id=str(updated_row.id),
                agent_id=updated_row.agent_id,
                schedule_name=updated_row.schedule_name,
                schedule_data=json.loads(updated_row.schedule_data) if updated_row.schedule_data else {},
                shift_assignments=json.loads(updated_row.shift_assignments) if updated_row.shift_assignments else [],
                total_hours=float(updated_row.total_hours),
                overtime_hours=float(updated_row.overtime_hours),
                status=updated_row.status,
                version=updated_row.version,
                effective_date=updated_row.effective_date.isoformat(),
                expiry_date=updated_row.expiry_date.isoformat() if updated_row.expiry_date else None,
                created_by_user_id=str(updated_row.created_by_user_id) if updated_row.created_by_user_id else None,
                organization_ref=str(updated_row.organization_ref) if updated_row.organization_ref else None,
                created_at=updated_row.created_at.isoformat(),
                updated_at=updated_row.updated_at.isoformat()
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/health/schedules/update")
async def health_check():
    """Health check for schedule update endpoint"""
    try:
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # Test connection and get sample schedule for update testing
            query = text("""
                SELECT id, status, version 
                FROM work_schedules_core 
                WHERE status NOT IN ('locked', 'archived') 
                LIMIT 1
            """)
            result = await session.execute(query)
            schedule = result.fetchone()
            
            return {
                "status": "healthy", 
                "endpoint": "PUT /api/v1/schedules/{id}",
                "updatable_schedules": 1 if schedule else 0,
                "sample_schedule_id": str(schedule.id) if schedule else None,
                "sample_version": schedule.version if schedule else None
            }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}