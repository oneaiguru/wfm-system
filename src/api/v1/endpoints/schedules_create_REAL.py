from fastapi import APIRouter, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy import text
from typing import List, Dict, Any, Optional
from datetime import date, datetime
import uuid
import json
from pydantic import BaseModel

router = APIRouter()

# Database connection - create engine once
engine = create_async_engine(
    "postgresql+asyncpg://wfm_user:wfm_password@localhost/wfm_enterprise",
    echo=False
)

class ScheduleCreateRequest(BaseModel):
    agent_id: int
    schedule_name: str
    schedule_data: Dict[str, Any]
    shift_assignments: List[Dict[str, Any]]
    total_hours: float
    overtime_hours: Optional[float] = 0.0
    status: str = "draft"
    effective_date: date
    expiry_date: Optional[date] = None
    organization_ref: Optional[str] = None

class ScheduleCreateResponse(BaseModel):
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

@router.post("/api/v1/schedules/create", response_model=ScheduleCreateResponse)
async def create_schedule(request: ScheduleCreateRequest):
    """
    Create a new schedule record in the work_schedules_core table.
    Validates data and inserts into the database with proper versioning.
    """
    try:
        # Generate unique ID
        schedule_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        # Create new session for this request
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # Check if agent exists and is active
            agent_check_query = text("""
                SELECT id, is_active, first_name, last_name 
                FROM agents 
                WHERE id = :agent_id
            """)
            
            agent_result = await session.execute(agent_check_query, {"agent_id": request.agent_id})
            agent = agent_result.fetchone()
            
            if not agent:
                raise HTTPException(status_code=404, detail=f"Agent {request.agent_id} not found")
            
            if not agent.is_active:
                raise HTTPException(status_code=400, detail=f"Agent {request.agent_id} is not active")
            
            # Check for overlapping schedules (same agent, overlapping dates)
            overlap_check_query = text("""
                SELECT id, effective_date, expiry_date 
                FROM work_schedules_core 
                WHERE agent_id = :agent_id 
                AND status IN ('active', 'draft')
                AND effective_date <= :end_date
                AND (expiry_date IS NULL OR expiry_date >= :start_date)
            """)
            
            end_date = request.expiry_date if request.expiry_date else date(2030, 12, 31)
            overlap_result = await session.execute(overlap_check_query, {
                "agent_id": request.agent_id,
                "start_date": request.effective_date,
                "end_date": end_date
            })
            
            overlapping = overlap_result.fetchone()
            if overlapping:
                raise HTTPException(
                    status_code=409, 
                    detail=f"Schedule conflicts with existing schedule for agent {request.agent_id}"
                )
            
            # Validate schedule data structure
            if not isinstance(request.schedule_data, dict):
                raise HTTPException(status_code=400, detail="schedule_data must be a valid JSON object")
            
            if not isinstance(request.shift_assignments, list):
                raise HTTPException(status_code=400, detail="shift_assignments must be a valid JSON array")
            
            # Validate total hours
            if request.total_hours < 0 or request.total_hours > 168:  # Max 168 hours per week
                raise HTTPException(status_code=400, detail="total_hours must be between 0 and 168")
            
            # Insert new schedule
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
                "id": schedule_id,
                "agent_id": request.agent_id,
                "schedule_name": request.schedule_name,
                "schedule_data": json.dumps(request.schedule_data),
                "shift_assignments": json.dumps(request.shift_assignments),
                "total_hours": request.total_hours,
                "overtime_hours": request.overtime_hours or 0.0,
                "status": request.status,
                "version": 1,  # New schedule starts at version 1
                "effective_date": request.effective_date,
                "expiry_date": request.expiry_date,
                "created_by_user_id": "system",  # TODO: Get from auth context
                "organization_ref": request.organization_ref,
                "created_at": current_time,
                "updated_at": current_time
            })
            
            await session.commit()
            row = result.fetchone()
            
            # Return the created schedule
            return ScheduleCreateResponse(
                id=str(row.id),
                agent_id=row.agent_id,
                schedule_name=row.schedule_name,
                schedule_data=json.loads(row.schedule_data) if row.schedule_data else {},
                shift_assignments=json.loads(row.shift_assignments) if row.shift_assignments else [],
                total_hours=float(row.total_hours),
                overtime_hours=float(row.overtime_hours),
                status=row.status,
                version=row.version,
                effective_date=row.effective_date.isoformat(),
                expiry_date=row.expiry_date.isoformat() if row.expiry_date else None,
                created_by_user_id=str(row.created_by_user_id) if row.created_by_user_id else None,
                organization_ref=str(row.organization_ref) if row.organization_ref else None,
                created_at=row.created_at.isoformat(),
                updated_at=row.updated_at.isoformat()
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/health/schedules/create")
async def health_check():
    """Health check for schedule creation endpoint"""
    try:
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # Test connection and table access
            query = text("SELECT COUNT(*) FROM work_schedules_core")
            result = await session.execute(query)
            count = result.scalar()
            
            # Test agents table access
            agents_query = text("SELECT COUNT(*) FROM agents WHERE is_active = true")
            agents_result = await session.execute(agents_query)
            active_agents = agents_result.scalar()
            
            return {
                "status": "healthy", 
                "total_schedules": count,
                "active_agents": active_agents,
                "endpoint": "POST /api/v1/schedules/create"
            }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}