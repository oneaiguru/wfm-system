"""
GET /api/v1/mobile/calendar/schedule - View Personal Schedule in Calendar Interface
BDD Implementation: 14-mobile-personal-cabinet.feature
Scenario: "View Personal Schedule in Calendar Interface" (Lines 42-58)

This endpoint implements the personal calendar view from work_schedules_core,
following the exact BDD scenario requirements:
- Multiple view options (Monthly, Weekly, 4-day, Daily)
- Schedule elements visualization (shifts, breaks, lunches, events)
- Channel type color coding
- Navigation capabilities
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import logging
from datetime import datetime, date, timedelta
from enum import Enum

from api.core.database import get_db
from api.auth.dependencies import get_current_user
import asyncpg

# BDD TRACEABILITY: Lines 42-58 "View Personal Schedule in Calendar Interface"
logger = logging.getLogger(__name__)

router = APIRouter()

class CalendarViewMode(str, Enum):
    """BDD Scenario: Lines 45-50 - View options from BDD"""
    MONTHLY = "Monthly"
    WEEKLY = "Weekly"
    FOUR_DAY = "4-day"
    DAILY = "Daily"

class ScheduleElement(BaseModel):
    """BDD Scenario: Lines 51-57 - Schedule element structure"""
    element_type: str = Field(..., description="Work shifts, Breaks, Lunches, Events")
    start_time: datetime = Field(..., description="Element start time")
    end_time: datetime = Field(..., description="Element end time")
    duration_minutes: int = Field(..., description="Duration in minutes")
    color_code: str = Field(..., description="Color coding by channel type")
    information: str = Field(..., description="Detailed information")
    special_notes: Optional[str] = Field(None, description="Any special notes")

class CalendarScheduleResponse(BaseModel):
    """
    BDD Scenario Output: Lines 44-57
    - Calendar with multiple view options
    - Schedule elements with proper visualization
    - Channel type color coding
    - Navigation information
    """
    view_mode: CalendarViewMode = Field(..., description="Current view mode")
    schedule_period_start: date = Field(..., description="Period start date")
    schedule_period_end: date = Field(..., description="Period end date")
    
    # BDD: "calendar should display" (Lines 51-57)
    work_shifts: List[ScheduleElement] = Field(..., description="Colored blocks with start/end times")
    breaks: List[ScheduleElement] = Field(..., description="Smaller blocks with break duration")
    lunches: List[ScheduleElement] = Field(..., description="Designated blocks for lunch periods")
    events: List[ScheduleElement] = Field(..., description="Special indicators for training/meetings")
    
    # BDD: Navigation capabilities
    navigation: Dict[str, Any] = Field(..., description="Navigation options for view mode")
    
    # Calendar customization from preferences
    preferences: Dict[str, Any] = Field(..., description="User calendar preferences")
    
    employee_tab_n: str = Field(..., description="Employee identifier")

@router.get("/api/v1/mobile/calendar/schedule", 
           response_model=CalendarScheduleResponse,
           summary="View Personal Schedule in Calendar Interface",
           description="""
           BDD Scenario: View Personal Schedule in Calendar Interface
           
           Implements the complete calendar viewing functionality:
           1. Retrieves personal schedule from work_schedules_core
           2. Supports multiple view modes (Monthly, Weekly, 4-day, Daily)
           3. Displays all schedule elements with proper visualization
           4. Applies channel type color coding
           5. Provides navigation capabilities
           
           Real database implementation using personal_calendars and work_schedules_core.
           """)
async def get_mobile_calendar_schedule(
    view_mode: CalendarViewMode = Query(CalendarViewMode.WEEKLY, description="Calendar view mode"),
    start_date: Optional[date] = Query(None, description="Schedule start date"),
    end_date: Optional[date] = Query(None, description="Schedule end date"),
    current_user = Depends(get_current_user),
    db: asyncpg.Connection = Depends(get_db)
) -> CalendarScheduleResponse:
    """
    BDD Implementation: "View Personal Schedule in Calendar Interface"
    
    This endpoint follows the exact BDD scenario steps:
    1. User accesses calendar page (Line 44)
    2. Sees multiple view options (Lines 45-50)
    3. Calendar displays schedule elements (Lines 51-57)
    4. Elements show proper visualization and information
    """
    try:
        # Extract employee tab_n from current_user (either User object or dict)
        if hasattr(current_user, 'id'):
            employee_tab_n = str(current_user.id)
        else:
            employee_tab_n = current_user.get("sub")
        logger.info(f"Calendar schedule request for employee: {employee_tab_n}, view: {view_mode}")
        
        # Set default date range based on view mode if not provided
        if not start_date:
            start_date = date.today()
            
        if not end_date:
            if view_mode == CalendarViewMode.MONTHLY:
                # Full month view
                start_date = start_date.replace(day=1)
                next_month = start_date.replace(month=start_date.month + 1) if start_date.month < 12 else start_date.replace(year=start_date.year + 1, month=1)
                end_date = next_month - timedelta(days=1)
            elif view_mode == CalendarViewMode.WEEKLY:
                # 7-day view
                start_date = start_date - timedelta(days=start_date.weekday())
                end_date = start_date + timedelta(days=6)
            elif view_mode == CalendarViewMode.FOUR_DAY:
                # 4-day compact view
                end_date = start_date + timedelta(days=3)
            else:  # DAILY
                # Single day view
                end_date = start_date
        
        # BDD Step: "When I access the calendar page" (Line 44)
        # Get user calendar preferences
        preferences_query = """
            SELECT default_view, time_format, date_format, show_breaks, 
                   show_lunches, show_events, color_by_channel
            FROM calendar_preferences 
            WHERE employee_tab_n = $1
        """
        preferences_result = await db.fetchrow(preferences_query, employee_tab_n)
        
        if not preferences_result:
            # Create default preferences
            default_prefs_query = """
                INSERT INTO calendar_preferences (employee_tab_n, default_view, time_format)
                VALUES ($1, $2, '24-hour')
                RETURNING default_view, time_format, date_format, show_breaks, 
                         show_lunches, show_events, color_by_channel
            """
            preferences_result = await db.fetchrow(default_prefs_query, employee_tab_n, view_mode.value)
        
        # BDD Step: "Then I should see my work schedule" (Line 45)
        # BDD Step: "And calendar should display:" (Lines 51-57)
        
        # Get work shifts - "Colored blocks with Start/end times" (Line 52)
        shifts_query = """
            SELECT 
                ws.work_date,
                ws.shift_start_time,
                ws.shift_end_time,
                ws.shift_duration_minutes,
                ws.channel_type,
                ws.special_notes,
                cc.color_code,
                cc.description as channel_description
            FROM work_schedules_core ws
            LEFT JOIN channel_configurations cc ON cc.channel_type = ws.channel_type
            WHERE ws.employee_tab_n = $1 
            AND ws.work_date BETWEEN $2 AND $3
            AND ws.shift_start_time IS NOT NULL
            ORDER BY ws.work_date, ws.shift_start_time
        """
        
        shifts_results = await db.fetch(shifts_query, employee_tab_n, start_date, end_date)
        
        work_shifts = []
        for shift in shifts_results:
            # Combine date and time for proper datetime
            shift_start = datetime.combine(shift['work_date'], shift['shift_start_time'])
            shift_end = datetime.combine(shift['work_date'], shift['shift_end_time'])
            
            work_shifts.append(ScheduleElement(
                element_type="Work shifts",
                start_time=shift_start,
                end_time=shift_end,
                duration_minutes=shift['shift_duration_minutes'] or 0,
                color_code=shift['color_code'] or "#3498db",
                information=f"{shift['channel_description'] or 'Work'} - {shift_start.strftime('%H:%M')}-{shift_end.strftime('%H:%M')}",
                special_notes=shift['special_notes']
            ))
        
        # Get breaks - "Smaller blocks with Break duration" (Line 53)
        breaks_query = """
            SELECT 
                ws.work_date,
                ws.break_times,
                ws.break_duration_minutes
            FROM work_schedules_core ws
            WHERE ws.employee_tab_n = $1 
            AND ws.work_date BETWEEN $2 AND $3
            AND ws.break_times IS NOT NULL
            ORDER BY ws.work_date
        """
        
        breaks_results = await db.fetch(breaks_query, employee_tab_n, start_date, end_date)
        
        breaks = []
        if preferences_result['show_breaks']:
            for break_record in breaks_results:
                # Parse break times from JSONB
                break_times = break_record['break_times']
                if break_times and isinstance(break_times, list):
                    for break_time in break_times:
                        break_start = datetime.combine(
                            break_record['work_date'], 
                            datetime.strptime(break_time['start'], '%H:%M').time()
                        )
                        break_duration = break_record['break_duration_minutes'] or 15
                        break_end = break_start + timedelta(minutes=break_duration)
                        
                        breaks.append(ScheduleElement(
                            element_type="Breaks",
                            start_time=break_start,
                            end_time=break_end,
                            duration_minutes=break_duration,
                            color_code="#f39c12",
                            information=f"Break - {break_duration} minutes"
                        ))
        
        # Get lunches - "Designated blocks for Lunch periods" (Line 54)
        lunches_query = """
            SELECT 
                ws.work_date,
                ws.lunch_start_time,
                ws.lunch_duration_minutes
            FROM work_schedules_core ws
            WHERE ws.employee_tab_n = $1 
            AND ws.work_date BETWEEN $2 AND $3
            AND ws.lunch_start_time IS NOT NULL
            ORDER BY ws.work_date
        """
        
        lunches_results = await db.fetch(lunches_query, employee_tab_n, start_date, end_date)
        
        lunches = []
        if preferences_result['show_lunches']:
            for lunch_record in lunches_results:
                lunch_start = datetime.combine(lunch_record['work_date'], lunch_record['lunch_start_time'])
                lunch_duration = lunch_record['lunch_duration_minutes'] or 60
                lunch_end = lunch_start + timedelta(minutes=lunch_duration)
                
                lunches.append(ScheduleElement(
                    element_type="Lunches",
                    start_time=lunch_start,
                    end_time=lunch_end,
                    duration_minutes=lunch_duration,
                    color_code="#e74c3c",
                    information=f"Lunch - {lunch_duration} minutes"
                ))
        
        # Get events - "Special indicators for Training/meetings" (Line 55)
        events_query = """
            SELECT 
                te.event_date,
                te.event_start_time,
                te.event_end_time,
                te.event_type,
                te.event_title,
                te.description
            FROM training_events te
            WHERE te.employee_tab_n = $1 
            AND te.event_date BETWEEN $2 AND $3
            ORDER BY te.event_date, te.event_start_time
        """
        
        events_results = await db.fetch(events_query, employee_tab_n, start_date, end_date)
        
        events = []
        if preferences_result['show_events']:
            for event in events_results:
                event_start = datetime.combine(event['event_date'], event['event_start_time'])
                event_end = datetime.combine(event['event_date'], event['event_end_time'])
                duration = int((event_end - event_start).total_seconds() / 60)
                
                events.append(ScheduleElement(
                    element_type="Events",
                    start_time=event_start,
                    end_time=event_end,
                    duration_minutes=duration,
                    color_code="#9b59b6",
                    information=f"{event['event_type']}: {event['event_title']}",
                    special_notes=event['description']
                ))
        
        # BDD: Navigation capabilities based on view mode (Lines 46-50)
        navigation = {}
        if view_mode == CalendarViewMode.MONTHLY:
            navigation = {
                "display": "Full month grid",
                "navigation_type": "Previous/Next month",
                "prev_period": start_date.replace(day=1) - timedelta(days=1),
                "next_period": end_date + timedelta(days=1)
            }
        elif view_mode == CalendarViewMode.WEEKLY:
            navigation = {
                "display": "7-day detailed view",
                "navigation_type": "Week navigation",
                "prev_period": start_date - timedelta(days=7),
                "next_period": end_date + timedelta(days=1)
            }
        elif view_mode == CalendarViewMode.FOUR_DAY:
            navigation = {
                "display": "4-day compact view",
                "navigation_type": "Daily navigation",
                "prev_period": start_date - timedelta(days=4),
                "next_period": end_date + timedelta(days=1)
            }
        else:  # DAILY
            navigation = {
                "display": "Single day detail",
                "navigation_type": "Day-by-day",
                "prev_period": start_date - timedelta(days=1),
                "next_period": start_date + timedelta(days=1)
            }
        
        # Prepare preferences dict
        preferences = {
            "default_view": preferences_result['default_view'],
            "time_format": preferences_result['time_format'],
            "date_format": preferences_result['date_format'],
            "show_breaks": preferences_result['show_breaks'],
            "show_lunches": preferences_result['show_lunches'],
            "show_events": preferences_result['show_events'],
            "color_by_channel": preferences_result['color_by_channel']
        }
        
        logger.info(f"Calendar schedule retrieved for {employee_tab_n}: {len(work_shifts)} shifts, {len(breaks)} breaks, {len(lunches)} lunches, {len(events)} events")
        
        return CalendarScheduleResponse(
            view_mode=view_mode,
            schedule_period_start=start_date,
            schedule_period_end=end_date,
            work_shifts=work_shifts,
            breaks=breaks,
            lunches=lunches,
            events=events,
            navigation=navigation,
            preferences=preferences,
            employee_tab_n=employee_tab_n
        )
        
    except asyncpg.PostgresError as e:
        logger.error(f"Database error in calendar schedule: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in calendar schedule: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Calendar retrieval failed: {str(e)}"
        )

# Additional endpoint for detailed shift information (BDD Lines 60-77)
@router.get("/api/v1/mobile/calendar/shift/{shift_id}",
           summary="View Detailed Shift Information",
           description="BDD Scenario: View Detailed Shift Information (Lines 60-77)")
async def get_detailed_shift_info(
    shift_id: str,
    current_user = Depends(get_current_user),
    db: asyncpg.Connection = Depends(get_db)
):
    """Get detailed information for a specific shift"""
    try:
        # Extract employee tab_n from current_user (either User object or dict)
        if hasattr(current_user, 'id'):
            employee_tab_n = str(current_user.id)
        else:
            employee_tab_n = current_user.get("sub")
        
        # Get detailed shift information
        shift_query = """
            SELECT 
                ws.*,
                cc.description as channel_description,
                cc.color_code
            FROM work_schedules_core ws
            LEFT JOIN channel_configurations cc ON cc.channel_type = ws.channel_type
            WHERE ws.id = $1 AND ws.employee_tab_n = $2
        """
        
        shift_result = await db.fetchrow(shift_query, shift_id, employee_tab_n)
        
        if not shift_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shift not found"
            )
        
        # BDD: Detailed shift information (Lines 63-71)
        return {
            "shift_date": shift_result['work_date'],
            "start_time": shift_result['shift_start_time'],
            "end_time": shift_result['shift_end_time'],
            "duration": f"{shift_result['shift_duration_minutes']} minutes",
            "break_schedule": shift_result['break_times'],
            "lunch_period": {
                "start": shift_result['lunch_start_time'],
                "duration": shift_result['lunch_duration_minutes']
            },
            "special_notes": shift_result['special_notes'],
            "channel_assignments": shift_result['channel_type'],
            "coverage_requirements": shift_result.get('coverage_requirements')
        }
        
    except Exception as e:
        logger.error(f"Error getting detailed shift info: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )