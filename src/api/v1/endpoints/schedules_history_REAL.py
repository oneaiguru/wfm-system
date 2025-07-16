from fastapi import APIRouter, HTTPException, Query
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

class ScheduleHistoryItem(BaseModel):
    id: str
    agent_id: int
    agent_name: Optional[str] = None
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

class ScheduleHistoryResponse(BaseModel):
    schedules: List[ScheduleHistoryItem]
    total_count: int
    page: int
    page_size: int
    has_next: bool
    has_previous: bool
    filters_applied: Dict[str, Any]

@router.get("/api/v1/schedules/history", response_model=ScheduleHistoryResponse)
async def get_schedule_history(
    agent_id: Optional[int] = Query(None, description="Filter by agent ID"),
    status: Optional[str] = Query(None, description="Filter by status"),
    from_date: Optional[date] = Query(None, description="Filter from effective date"),
    to_date: Optional[date] = Query(None, description="Filter to effective date"),
    organization_ref: Optional[str] = Query(None, description="Filter by organization"),
    include_versions: bool = Query(False, description="Include all versions of schedules"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Number of items per page")
):
    """
    Get schedule history with filtering and pagination.
    Returns chronological list of schedule changes and versions.
    """
    try:
        # Create new session for this request
        async with AsyncSession(engine, expire_on_commit=False) as session:
            
            # Build WHERE conditions dynamically
            where_conditions = []
            query_params = {}
            
            if agent_id is not None:
                where_conditions.append("wsc.agent_id = :agent_id")
                query_params["agent_id"] = agent_id
            
            if status is not None:
                where_conditions.append("wsc.status = :status")
                query_params["status"] = status
            
            if from_date is not None:
                where_conditions.append("wsc.effective_date >= :from_date")
                query_params["from_date"] = from_date
            
            if to_date is not None:
                where_conditions.append("wsc.effective_date <= :to_date")
                query_params["to_date"] = to_date
            
            if organization_ref is not None:
                where_conditions.append("wsc.organization_ref = :organization_ref")
                query_params["organization_ref"] = organization_ref
            
            # Version filtering logic
            if not include_versions:
                # Only get latest version of each schedule
                where_conditions.append("""
                    wsc.version = (
                        SELECT MAX(version) 
                        FROM work_schedules_core wsc2 
                        WHERE wsc2.id = wsc.id
                    )
                """)
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Count total records
            count_query = text(f"""
                SELECT COUNT(*) as total
                FROM work_schedules_core wsc
                LEFT JOIN agents a ON wsc.agent_id = a.id
                {where_clause}
            """)
            
            count_result = await session.execute(count_query, query_params)
            total_count = count_result.scalar()
            
            # Calculate pagination
            offset = (page - 1) * page_size
            has_next = offset + page_size < total_count
            has_previous = page > 1
            
            # Get paginated results
            query_params["limit"] = page_size
            query_params["offset"] = offset
            
            data_query = text(f"""
                SELECT 
                    wsc.id,
                    wsc.agent_id,
                    COALESCE(a.first_name || ' ' || a.last_name, 'Unknown Agent') as agent_name,
                    wsc.schedule_name,
                    wsc.schedule_data,
                    wsc.shift_assignments,
                    wsc.total_hours,
                    wsc.overtime_hours,
                    wsc.status,
                    wsc.version,
                    wsc.effective_date,
                    wsc.expiry_date,
                    wsc.created_by_user_id,
                    wsc.organization_ref,
                    wsc.created_at,
                    wsc.updated_at
                FROM work_schedules_core wsc
                LEFT JOIN agents a ON wsc.agent_id = a.id
                {where_clause}
                ORDER BY wsc.created_at DESC, wsc.agent_id, wsc.version DESC
                LIMIT :limit OFFSET :offset
            """)
            
            data_result = await session.execute(data_query, query_params)
            rows = data_result.fetchall()
            
            # Convert to response objects
            schedules = []
            for row in rows:
                schedule = ScheduleHistoryItem(
                    id=str(row.id),
                    agent_id=row.agent_id,
                    agent_name=row.agent_name,
                    schedule_name=row.schedule_name or f"Schedule {row.agent_id}",
                    schedule_data=json.loads(row.schedule_data) if row.schedule_data else {},
                    shift_assignments=json.loads(row.shift_assignments) if row.shift_assignments else [],
                    total_hours=float(row.total_hours) if row.total_hours else 0.0,
                    overtime_hours=float(row.overtime_hours) if row.overtime_hours else 0.0,
                    status=row.status or "draft",
                    version=row.version or 1,
                    effective_date=row.effective_date.isoformat() if row.effective_date else None,
                    expiry_date=row.expiry_date.isoformat() if row.expiry_date else None,
                    created_by_user_id=str(row.created_by_user_id) if row.created_by_user_id else None,
                    organization_ref=str(row.organization_ref) if row.organization_ref else None,
                    created_at=row.created_at.isoformat() if row.created_at else None,
                    updated_at=row.updated_at.isoformat() if row.updated_at else None
                )
                schedules.append(schedule)
            
            # Build filters summary
            filters_applied = {}
            if agent_id is not None:
                filters_applied["agent_id"] = agent_id
            if status is not None:
                filters_applied["status"] = status
            if from_date is not None:
                filters_applied["from_date"] = from_date.isoformat()
            if to_date is not None:
                filters_applied["to_date"] = to_date.isoformat()
            if organization_ref is not None:
                filters_applied["organization_ref"] = organization_ref
            if include_versions:
                filters_applied["include_versions"] = True
            
            return ScheduleHistoryResponse(
                schedules=schedules,
                total_count=total_count,
                page=page,
                page_size=page_size,
                has_next=has_next,
                has_previous=has_previous,
                filters_applied=filters_applied
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/api/v1/schedules/history/stats")
async def get_schedule_history_stats():
    """
    Get statistics about schedule history for analytics.
    """
    try:
        async with AsyncSession(engine, expire_on_commit=False) as session:
            
            # Get comprehensive statistics
            stats_query = text("""
                SELECT 
                    COUNT(*) as total_schedules,
                    COUNT(DISTINCT agent_id) as unique_agents,
                    COUNT(DISTINCT DATE(created_at)) as active_days,
                    AVG(total_hours) as avg_total_hours,
                    AVG(overtime_hours) as avg_overtime_hours,
                    MAX(version) as max_version,
                    MIN(effective_date) as earliest_schedule,
                    MAX(effective_date) as latest_schedule
                FROM work_schedules_core
            """)
            
            stats_result = await session.execute(stats_query)
            stats = stats_result.fetchone()
            
            # Status distribution
            status_query = text("""
                SELECT status, COUNT(*) as count
                FROM work_schedules_core
                GROUP BY status
                ORDER BY count DESC
            """)
            
            status_result = await session.execute(status_query)
            status_distribution = {row.status: row.count for row in status_result.fetchall()}
            
            # Agent activity (schedules per agent)
            agent_activity_query = text("""
                SELECT 
                    agent_id,
                    COALESCE(a.first_name || ' ' || a.last_name, 'Unknown') as agent_name,
                    COUNT(*) as schedule_count,
                    MAX(version) as max_version,
                    MAX(updated_at) as last_activity
                FROM work_schedules_core wsc
                LEFT JOIN agents a ON wsc.agent_id = a.id
                GROUP BY agent_id, a.first_name, a.last_name
                ORDER BY schedule_count DESC
                LIMIT 10
            """)
            
            agent_result = await session.execute(agent_activity_query)
            top_agents = []
            for row in agent_result.fetchall():
                top_agents.append({
                    "agent_id": row.agent_id,
                    "agent_name": row.agent_name,
                    "schedule_count": row.schedule_count,
                    "max_version": row.max_version,
                    "last_activity": row.last_activity.isoformat() if row.last_activity else None
                })
            
            # Recent activity (last 30 days)
            recent_activity_query = text("""
                SELECT 
                    DATE(created_at) as activity_date,
                    COUNT(*) as schedules_created,
                    COUNT(CASE WHEN version > 1 THEN 1 END) as schedules_updated
                FROM work_schedules_core
                WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(created_at)
                ORDER BY activity_date DESC
            """)
            
            activity_result = await session.execute(recent_activity_query)
            recent_activity = []
            for row in activity_result.fetchall():
                recent_activity.append({
                    "date": row.activity_date.isoformat(),
                    "schedules_created": row.schedules_created,
                    "schedules_updated": row.schedules_updated
                })
            
            return {
                "summary": {
                    "total_schedules": stats.total_schedules,
                    "unique_agents": stats.unique_agents,
                    "active_days": stats.active_days,
                    "avg_total_hours": round(float(stats.avg_total_hours), 2) if stats.avg_total_hours else 0,
                    "avg_overtime_hours": round(float(stats.avg_overtime_hours), 2) if stats.avg_overtime_hours else 0,
                    "max_version": stats.max_version,
                    "earliest_schedule": stats.earliest_schedule.isoformat() if stats.earliest_schedule else None,
                    "latest_schedule": stats.latest_schedule.isoformat() if stats.latest_schedule else None
                },
                "status_distribution": status_distribution,
                "top_active_agents": top_agents,
                "recent_activity": recent_activity
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/health/schedules/history")
async def health_check():
    """Health check for schedule history endpoint"""
    try:
        async with AsyncSession(engine, expire_on_commit=False) as session:
            # Test basic query functionality
            query = text("""
                SELECT 
                    COUNT(*) as total_schedules,
                    COUNT(DISTINCT agent_id) as unique_agents,
                    MAX(version) as max_version
                FROM work_schedules_core
            """)
            result = await session.execute(query)
            stats = result.fetchone()
            
            return {
                "status": "healthy",
                "endpoint": "GET /api/v1/schedules/history",
                "total_schedules": stats.total_schedules,
                "unique_agents": stats.unique_agents,
                "max_version": stats.max_version,
                "features": ["filtering", "pagination", "versioning", "statistics"]
            }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}