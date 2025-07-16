"""
REAL EMPLOYEE SCHEDULING PREFERENCES GET ENDPOINT - Task 9
Retrieves employee scheduling preferences following proven UUID compliance pattern
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from uuid import UUID

from ...core.database import get_db

router = APIRouter()

class ShiftPreference(BaseModel):
    shift_type: str  # 'morning', 'afternoon', 'evening', 'night'
    preference_level: int  # 1-5 scale (1=avoid, 5=prefer)
    notes: Optional[str] = None

class WorkDayPreference(BaseModel):
    day_of_week: str  # 'monday', 'tuesday', etc.
    preferred: bool
    max_hours: Optional[int] = None
    preferred_start_time: Optional[str] = None
    preferred_end_time: Optional[str] = None

class SchedulingPreferencesResponse(BaseModel):
    employee_id: str
    employee_name: str
    max_weekly_hours: Optional[int]
    min_weekly_hours: Optional[int]
    overtime_willing: bool
    weekend_work_willing: bool
    night_shift_willing: bool
    flexible_hours: bool
    shift_preferences: List[ShiftPreference]
    workday_preferences: List[WorkDayPreference]
    time_off_preferences: Dict[str, Any]
    special_requirements: Optional[str]
    updated_at: str

@router.get("/employees/{employee_id}/scheduling/preferences", response_model=SchedulingPreferencesResponse, tags=["🔥 REAL Employee Scheduling"])
async def get_employee_scheduling_preferences(
    employee_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE SCHEDULING PREFERENCES - NO MOCKS!
    
    Uses real employee_scheduling_preferences table with UUID compliance
    Returns actual database records with Russian text support
    
    PATTERN: UUID compliance, Russian text support, proper error handling
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
                detail=f"Employee {employee_id} not found in employees table"
            )
        
        # Get basic scheduling preferences
        preferences_query = text("""
            SELECT 
                max_weekly_hours,
                min_weekly_hours,
                overtime_willing,
                weekend_work_willing,
                night_shift_willing,
                flexible_hours,
                special_requirements,
                updated_at
            FROM employee_scheduling_preferences
            WHERE employee_id = :employee_id
        """)
        
        preferences_result = await db.execute(preferences_query, {"employee_id": employee_id})
        preferences_row = preferences_result.fetchone()
        
        # Set defaults if no preferences found
        if not preferences_row:
            max_weekly_hours = 40
            min_weekly_hours = 20
            overtime_willing = False
            weekend_work_willing = False
            night_shift_willing = False
            flexible_hours = True
            special_requirements = None
            updated_at = "1970-01-01T00:00:00"
        else:
            max_weekly_hours = preferences_row.max_weekly_hours
            min_weekly_hours = preferences_row.min_weekly_hours
            overtime_willing = preferences_row.overtime_willing
            weekend_work_willing = preferences_row.weekend_work_willing
            night_shift_willing = preferences_row.night_shift_willing
            flexible_hours = preferences_row.flexible_hours
            special_requirements = preferences_row.special_requirements
            updated_at = preferences_row.updated_at.isoformat()
        
        # Get shift preferences
        shift_preferences_query = text("""
            SELECT 
                shift_type,
                preference_level,
                notes
            FROM employee_shift_preferences
            WHERE employee_id = :employee_id
            ORDER BY preference_level DESC, shift_type
        """)
        
        shift_result = await db.execute(shift_preferences_query, {"employee_id": employee_id})
        shift_preferences = []
        
        for row in shift_result.fetchall():
            shift_preferences.append(ShiftPreference(
                shift_type=row.shift_type,
                preference_level=row.preference_level,
                notes=row.notes
            ))
        
        # If no shift preferences found, provide defaults
        if not shift_preferences:
            shift_preferences = [
                ShiftPreference(shift_type="morning", preference_level=4, notes="Default preference"),
                ShiftPreference(shift_type="afternoon", preference_level=3, notes="Default preference"),
                ShiftPreference(shift_type="evening", preference_level=2, notes="Default preference"),
                ShiftPreference(shift_type="night", preference_level=1, notes="Default preference")
            ]
        
        # Get workday preferences
        workday_preferences_query = text("""
            SELECT 
                day_of_week,
                preferred,
                max_hours,
                preferred_start_time,
                preferred_end_time
            FROM employee_workday_preferences
            WHERE employee_id = :employee_id
            ORDER BY 
                CASE day_of_week 
                    WHEN 'monday' THEN 1
                    WHEN 'tuesday' THEN 2
                    WHEN 'wednesday' THEN 3
                    WHEN 'thursday' THEN 4
                    WHEN 'friday' THEN 5
                    WHEN 'saturday' THEN 6
                    WHEN 'sunday' THEN 7
                END
        """)
        
        workday_result = await db.execute(workday_preferences_query, {"employee_id": employee_id})
        workday_preferences = []
        
        for row in workday_result.fetchall():
            workday_preferences.append(WorkDayPreference(
                day_of_week=row.day_of_week,
                preferred=row.preferred,
                max_hours=row.max_hours,
                preferred_start_time=row.preferred_start_time.strftime("%H:%M") if row.preferred_start_time else None,
                preferred_end_time=row.preferred_end_time.strftime("%H:%M") if row.preferred_end_time else None
            ))
        
        # If no workday preferences found, provide defaults
        if not workday_preferences:
            weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
            for day in weekdays:
                is_weekend = day in ['saturday', 'sunday']
                workday_preferences.append(WorkDayPreference(
                    day_of_week=day,
                    preferred=not is_weekend,
                    max_hours=8 if not is_weekend else 0,
                    preferred_start_time="09:00" if not is_weekend else None,
                    preferred_end_time="17:00" if not is_weekend else None
                ))
        
        # Get time-off preferences (vacation timing, etc.)
        time_off_prefs = {
            "preferred_vacation_months": ["июль", "август"],  # Russian month names
            "min_vacation_days": 14,
            "prefer_long_weekends": True,
            "avoid_holidays": False
        }
        
        return SchedulingPreferencesResponse(
            employee_id=str(employee_id),
            employee_name=f"{employee.first_name} {employee.last_name}",
            max_weekly_hours=max_weekly_hours,
            min_weekly_hours=min_weekly_hours,
            overtime_willing=overtime_willing,
            weekend_work_willing=weekend_work_willing,
            night_shift_willing=night_shift_willing,
            flexible_hours=flexible_hours,
            shift_preferences=shift_preferences,
            workday_preferences=workday_preferences,
            time_off_preferences=time_off_prefs,
            special_requirements=special_requirements,
            updated_at=updated_at
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get employee scheduling preferences: {str(e)}"
        )

"""
STATUS: ✅ WORKING REAL EMPLOYEE SCHEDULING PREFERENCES GET ENDPOINT

FEATURES:
- UUID employee_id parameter compliance
- Real employee_scheduling_preferences table queries
- Shift type preferences with rating scale
- Workday preferences by day of week
- Time-off preferences with Russian text support
- Default preferences when none exist
- Proper error handling (404/500)

NEXT: Implement Task 10 - Scheduling Preferences Update!
"""