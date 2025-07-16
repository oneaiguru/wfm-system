"""
REAL EMPLOYEE PERFORMANCE GOALS ENDPOINT - Task 15
Manages performance goals following proven UUID compliance pattern
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import datetime, date

from ...core.database import get_db

router = APIRouter()

class PerformanceGoal(BaseModel):
    goal_title: str
    goal_description: str
    target_date: date
    goal_category: str  # 'productivity', 'quality', 'skill_development', 'leadership'
    target_value: Optional[float] = None
    target_unit: Optional[str] = None
    priority: str = 'medium'  # 'low', 'medium', 'high', 'critical'

class GoalProgress(BaseModel):
    current_value: Optional[float] = None
    progress_percentage: Optional[float] = None
    status_notes: Optional[str] = None

class PerformanceGoalResponse(BaseModel):
    goal_id: str
    employee_id: str
    goal_title: str
    goal_description: str
    target_date: str
    goal_category: str
    target_value: Optional[float]
    target_unit: Optional[str]
    priority: str
    status: str
    current_progress: Optional[float]
    created_at: str

@router.post("/employees/{employee_id}/performance/goals", response_model=PerformanceGoalResponse, tags=["🔥 REAL Employee Performance"])
async def create_performance_goal(
    employee_id: UUID,
    goal: PerformanceGoal,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE PERFORMANCE GOALS - NO MOCKS!
    
    Creates performance goals with UUID compliance
    Uses real employee_performance_goals table
    """
    try:
        # Validate employee exists
        employee_check = text("""
            SELECT id, first_name, last_name 
            FROM employees 
            WHERE id = :employee_id
        """)
        
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(
                status_code=404,
                detail=f"Employee {employee_id} not found"
            )
        
        # Insert performance goal
        insert_query = text("""
            INSERT INTO employee_performance_goals 
            (employee_id, goal_title, goal_description, target_date, goal_category,
             target_value, target_unit, priority, status)
            VALUES 
            (:employee_id, :goal_title, :goal_description, :target_date, :goal_category,
             :target_value, :target_unit, :priority, 'active')
            RETURNING id, created_at
        """)
        
        result = await db.execute(insert_query, {
            'employee_id': employee_id,
            'goal_title': goal.goal_title,
            'goal_description': goal.goal_description,
            'target_date': goal.target_date,
            'goal_category': goal.goal_category,
            'target_value': goal.target_value,
            'target_unit': goal.target_unit,
            'priority': goal.priority
        })
        
        goal_record = result.fetchone()
        await db.commit()
        
        return PerformanceGoalResponse(
            goal_id=str(goal_record.id),
            employee_id=str(employee_id),
            goal_title=goal.goal_title,
            goal_description=goal.goal_description,
            target_date=goal.target_date.isoformat(),
            goal_category=goal.goal_category,
            target_value=goal.target_value,
            target_unit=goal.target_unit,
            priority=goal.priority,
            status="active",
            current_progress=0.0,
            created_at=goal_record.created_at.isoformat()
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create goal: {str(e)}")

@router.get("/employees/{employee_id}/performance/goals", tags=["🔥 REAL Employee Performance"])
async def get_employee_goals(
    employee_id: UUID,
    status: Optional[str] = None,
    category: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """Get performance goals for employee"""
    try:
        where_conditions = ["epg.employee_id = :employee_id"]
        params = {"employee_id": employee_id}
        
        if status:
            where_conditions.append("epg.status = :status")
            params["status"] = status
            
        if category:
            where_conditions.append("epg.goal_category = :category")
            params["category"] = category
        
        where_clause = " AND ".join(where_conditions)
        
        query = text(f"""
            SELECT 
                epg.id, epg.goal_title, epg.goal_description, epg.target_date,
                epg.goal_category, epg.target_value, epg.target_unit, epg.priority,
                epg.status, epg.current_progress, epg.created_at
            FROM employee_performance_goals epg
            WHERE {where_clause}
            ORDER BY epg.priority DESC, epg.target_date ASC
        """)
        
        result = await db.execute(query, params)
        goals = []
        
        for row in result.fetchall():
            goals.append({
                "goal_id": str(row.id),
                "goal_title": row.goal_title,
                "goal_description": row.goal_description,
                "target_date": row.target_date.isoformat(),
                "goal_category": row.goal_category,
                "target_value": row.target_value,
                "target_unit": row.target_unit,
                "priority": row.priority,
                "status": row.status,
                "current_progress": row.current_progress,
                "created_at": row.created_at.isoformat()
            })
        
        return {"employee_id": employee_id, "goals": goals}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get goals: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE PERFORMANCE GOALS ENDPOINT
"""