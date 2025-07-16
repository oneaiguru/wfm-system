from fastapi import APIRouter, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy import text
from typing import List, Dict, Any, Optional
from datetime import date, datetime, timedelta
import uuid
import json
from pydantic import BaseModel

router = APIRouter()

# Database connection - create engine once
engine = create_async_engine(
    "postgresql+asyncpg://wfm_user:wfm_password@localhost/wfm_enterprise",
    echo=False
)

class ScheduleCopyRequest(BaseModel):
    source_schedule_id: str
    target_agent_id: Optional[int] = None  # If None, copy to same agent
    new_schedule_name: Optional[str] = None
    new_effective_date: date
    new_expiry_date: Optional[date] = None
    copy_shift_assignments: bool = True
    adjust_dates_in_assignments: bool = True
    new_status: str = "draft"
    organization_ref: Optional[str] = None

class ScheduleCopyResponse(BaseModel):
    original_schedule_id: str
    new_schedule_id: str
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
    copy_metadata: Dict[str, Any]

@router.post("/api/v1/schedules/copy", response_model=ScheduleCopyResponse)
async def copy_schedule(request: ScheduleCopyRequest):
    """
    Copy an existing schedule to create a new schedule.
    Supports copying to same or different agent with date adjustments.
    """
    try:
        new_schedule_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        # Create new session for this request
        async with AsyncSession(engine, expire_on_commit=False) as session:
            
            # Get the source schedule
            source_query = text("""
                SELECT 
                    id, agent_id, schedule_name, schedule_data, shift_assignments,
                    total_hours, overtime_hours, status, version, effective_date,
                    expiry_date, created_by_user_id, organization_ref,
                    created_at, updated_at
                FROM work_schedules_core
                WHERE id = :schedule_id
            """)
            
            source_result = await session.execute(source_query, {"schedule_id": request.source_schedule_id})
            source_schedule = source_result.fetchone()
            
            if not source_schedule:
                raise HTTPException(
                    status_code=404, 
                    detail=f"Source schedule {request.source_schedule_id} not found"
                )
            
            # Determine target agent
            target_agent_id = request.target_agent_id if request.target_agent_id else source_schedule.agent_id
            
            # Validate target agent exists and is active
            agent_check_query = text("""
                SELECT id, is_active, first_name, last_name 
                FROM agents 
                WHERE id = :agent_id
            """)
            
            agent_result = await session.execute(agent_check_query, {"agent_id": target_agent_id})
            agent = agent_result.fetchone()
            
            if not agent:
                raise HTTPException(status_code=404, detail=f"Target agent {target_agent_id} not found")
            
            if not agent.is_active:
                raise HTTPException(status_code=400, detail=f"Target agent {target_agent_id} is not active")
            
            # Check for overlapping schedules
            overlap_check_query = text("""
                SELECT id, effective_date, expiry_date 
                FROM work_schedules_core 
                WHERE agent_id = :agent_id 
                AND status IN ('active', 'draft')
                AND effective_date <= :end_date
                AND (expiry_date IS NULL OR expiry_date >= :start_date)
            """)
            
            end_date = request.new_expiry_date if request.new_expiry_date else date(2030, 12, 31)
            overlap_result = await session.execute(overlap_check_query, {
                "agent_id": target_agent_id,
                "start_date": request.new_effective_date,
                "end_date": end_date
            })
            
            overlapping = overlap_result.fetchone()
            if overlapping:
                raise HTTPException(
                    status_code=409, 
                    detail=f"New schedule would conflict with existing schedule for agent {target_agent_id}"
                )
            
            # Prepare copied data
            new_schedule_name = request.new_schedule_name or f"Copy of {source_schedule.schedule_name}"
            
            # Copy and process schedule data
            copied_schedule_data = json.loads(source_schedule.schedule_data) if source_schedule.schedule_data else {}
            
            # Add copy metadata to schedule data
            copied_schedule_data["copy_metadata"] = {
                "source_schedule_id": request.source_schedule_id,
                "copied_at": current_time.isoformat(),
                "copied_by": "system",  # TODO: Get from auth context
                "copy_type": "manual"
            }
            
            # Copy and adjust shift assignments
            copied_shift_assignments = []
            if request.copy_shift_assignments and source_schedule.shift_assignments:
                original_assignments = json.loads(source_schedule.shift_assignments)
                
                if request.adjust_dates_in_assignments:
                    # Calculate date difference for adjustment
                    original_effective = source_schedule.effective_date
                    date_diff = (request.new_effective_date - original_effective).days
                    
                    for assignment in original_assignments:
                        new_assignment = assignment.copy()
                        
                        # Adjust date fields if they exist
                        if "shift_date" in assignment:
                            try:
                                original_date = datetime.fromisoformat(assignment["shift_date"]).date()
                                new_date = original_date + timedelta(days=date_diff)
                                new_assignment["shift_date"] = new_date.isoformat()
                            except (ValueError, TypeError):
                                # Keep original if parsing fails
                                pass
                        
                        if "start_datetime" in assignment:
                            try:
                                original_datetime = datetime.fromisoformat(assignment["start_datetime"])
                                new_datetime = original_datetime + timedelta(days=date_diff)
                                new_assignment["start_datetime"] = new_datetime.isoformat()
                            except (ValueError, TypeError):
                                pass
                        
                        if "end_datetime" in assignment:
                            try:
                                original_datetime = datetime.fromisoformat(assignment["end_datetime"])
                                new_datetime = original_datetime + timedelta(days=date_diff)
                                new_assignment["end_datetime"] = new_datetime.isoformat()
                            except (ValueError, TypeError):
                                pass
                        
                        # Update agent reference if copying to different agent
                        if request.target_agent_id and "agent_id" in assignment:
                            new_assignment["agent_id"] = target_agent_id
                        
                        copied_shift_assignments.append(new_assignment)
                else:
                    # Copy assignments as-is
                    copied_shift_assignments = original_assignments.copy()
            
            # Validate new dates
            if request.new_expiry_date and request.new_effective_date >= request.new_expiry_date:
                raise HTTPException(status_code=400, detail="new_effective_date must be before new_expiry_date")
            
            # Validate status
            valid_statuses = ['draft', 'active', 'pending', 'suspended']
            if request.new_status not in valid_statuses:
                raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")
            
            # Insert the copied schedule
            insert_query = text("""
                INSERT INTO work_schedules_core (
                    id, agent_id, schedule_name, schedule_data, shift_assignments,
                    total_hours, overtime_hours, status, version, effective_date,
                    expiry_date, created_by_user_id, organization_ref, created_at, updated_at
                ) VALUES (
                    :id, :agent_id, :schedule_name, :schedule_data, :shift_assignments,
                    :total_hours, :overtime_hours, :status, :version, :effective_date,
                    :expiry_date, :created_by_user_id, :organization_ref, :created_at, :updated_at
                ) RETURNING *
            """)
            
            result = await session.execute(insert_query, {
                "id": new_schedule_id,
                "agent_id": target_agent_id,
                "schedule_name": new_schedule_name,
                "schedule_data": json.dumps(copied_schedule_data),
                "shift_assignments": json.dumps(copied_shift_assignments),
                "total_hours": source_schedule.total_hours,
                "overtime_hours": source_schedule.overtime_hours,
                "status": request.new_status,
                "version": 1,  # New copy starts at version 1
                "effective_date": request.new_effective_date,
                "expiry_date": request.new_expiry_date,
                "created_by_user_id": "system",  # TODO: Get from auth context
                "organization_ref": request.organization_ref or source_schedule.organization_ref,
                "created_at": current_time,
                "updated_at": current_time
            })
            
            await session.commit()
            new_row = result.fetchone()
            
            # Prepare copy metadata for response
            copy_metadata = {
                "source_schedule_id": request.source_schedule_id,
                "source_agent_id": source_schedule.agent_id,
                "target_agent_id": target_agent_id,
                "date_adjustment_days": (request.new_effective_date - source_schedule.effective_date).days,
                "assignments_copied": len(copied_shift_assignments),
                "assignments_adjusted": request.adjust_dates_in_assignments,
                "copied_at": current_time.isoformat()
            }
            
            # Return the copied schedule
            return ScheduleCopyResponse(
                original_schedule_id=request.source_schedule_id,
                new_schedule_id=str(new_row.id),
                agent_id=new_row.agent_id,
                schedule_name=new_row.schedule_name,
                schedule_data=json.loads(new_row.schedule_data) if new_row.schedule_data else {},
                shift_assignments=json.loads(new_row.shift_assignments) if new_row.shift_assignments else [],
                total_hours=float(new_row.total_hours),
                overtime_hours=float(new_row.overtime_hours),
                status=new_row.status,
                version=new_row.version,
                effective_date=new_row.effective_date.isoformat(),
                expiry_date=new_row.expiry_date.isoformat() if new_row.expiry_date else None,
                created_by_user_id=str(new_row.created_by_user_id) if new_row.created_by_user_id else None,
                organization_ref=str(new_row.organization_ref) if new_row.organization_ref else None,
                created_at=new_row.created_at.isoformat(),
                updated_at=new_row.updated_at.isoformat(),
                copy_metadata=copy_metadata
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/health/schedules/copy")
async def health_check():
    """Health check for schedule copy endpoint"""
    try:
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # Test connection and get available schedules for copying
            schedules_query = text("""
                SELECT COUNT(*) as copyable_schedules
                FROM work_schedules_core 
                WHERE status IN ('active', 'draft')
            """)
            schedules_result = await session.execute(schedules_query)
            copyable_count = schedules_result.scalar()
            
            # Test agents available as copy targets
            agents_query = text("SELECT COUNT(*) FROM agents WHERE is_active = true")
            agents_result = await session.execute(agents_query)
            active_agents = agents_result.scalar()
            
            return {
                "status": "healthy",
                "endpoint": "POST /api/v1/schedules/copy",
                "copyable_schedules": copyable_count,
                "active_agents": active_agents,
                "features": ["agent_transfer", "date_adjustment", "assignment_copying", "conflict_detection"]
            }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}