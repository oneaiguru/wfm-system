"""
Employee Schedule Access API Endpoints
5 endpoints for employee schedule viewing and acknowledgment
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import calendar

from ...auth.dependencies import get_current_user, require_permissions
from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleShift
from ....models.user import User, Employee
from ....services.schedule_service import ScheduleService
from ....services.websocket import websocket_manager
from ...schemas.schedules import (
    EmployeeScheduleResponse, EmployeeScheduleMonthly, EmployeeScheduleWeekly,
    ScheduleAcknowledgment
)

router = APIRouter()


@router.get("/{employee_id}/schedule", response_model=EmployeeScheduleResponse)
async def get_employee_schedule(
    employee_id: uuid.UUID,
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    include_conflicts: bool = Query(True),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get employee's current schedule"""
    try:
        # Check if user can access this employee's schedule
        if not current_user.is_superuser and not current_user.has_permission("employees.read"):
            # Check if user is requesting their own schedule
            if not current_user.employee_profile or current_user.employee_profile.id != employee_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Get employee
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        # Organization check
        if not current_user.is_superuser and employee.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Set default date range if not provided
        if not start_date:
            start_date = date.today()
        if not end_date:
            end_date = start_date + relativedelta(months=1)
        
        # Get schedule shifts
        query = db.query(ScheduleShift).filter(
            ScheduleShift.employee_id == employee_id,
            ScheduleShift.date >= start_date,
            ScheduleShift.date <= end_date
        ).join(Schedule).filter(
            Schedule.status.in_(["published", "active"])
        )
        
        shifts = query.all()
        
        # Format schedule data
        schedule_data = []
        total_hours = 0
        overtime_hours = 0
        
        for shift in shifts:
            # Calculate shift duration
            shift_start = datetime.combine(shift.date, shift.override_start_time or shift.start_time)
            shift_end = datetime.combine(shift.date, shift.override_end_time or shift.end_time)
            
            # Handle overnight shifts
            if shift_end < shift_start:
                shift_end += relativedelta(days=1)
            
            duration_hours = (shift_end - shift_start).total_seconds() / 3600
            total_hours += duration_hours
            
            # Check if overtime (assuming 8 hours is standard)
            if duration_hours > 8:
                overtime_hours += duration_hours - 8
            
            shift_data = {
                "id": str(shift.id),
                "date": shift.date.isoformat(),
                "start_time": (shift.override_start_time or shift.start_time).isoformat(),
                "end_time": (shift.override_end_time or shift.end_time).isoformat(),
                "shift_name": shift.shift.name if shift.shift else "Unknown",
                "shift_type": shift.shift.shift_type if shift.shift else "regular",
                "status": shift.status,
                "notes": shift.notes,
                "break_times": shift.break_times or [],
                "duration_hours": round(duration_hours, 2),
                "color_code": shift.shift.color_code if shift.shift else "#3498db"
            }
            
            schedule_data.append(shift_data)
        
        # Get conflicts if requested
        conflicts = []
        if include_conflicts:
            conflicts = await ScheduleService.get_employee_schedule_conflicts(
                employee_id, start_date, end_date, db
            )
        
        return EmployeeScheduleResponse(
            employee_id=employee_id,
            employee_name=employee.full_name,
            schedule_data=schedule_data,
            total_hours=round(total_hours, 2),
            overtime_hours=round(overtime_hours, 2),
            conflicts=conflicts,
            last_updated=datetime.utcnow()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get employee schedule: {str(e)}")


@router.get("/{employee_id}/schedule/month", response_model=EmployeeScheduleMonthly)
async def get_employee_monthly_schedule(
    employee_id: uuid.UUID,
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=2020, le=2030),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get employee's monthly schedule view"""
    try:
        # Check access permissions
        if not current_user.is_superuser and not current_user.has_permission("employees.read"):
            if not current_user.employee_profile or current_user.employee_profile.id != employee_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Get employee
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        # Organization check
        if not current_user.is_superuser and employee.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get month boundaries
        start_date = date(year, month, 1)
        end_date = date(year, month, calendar.monthrange(year, month)[1])
        
        # Get schedule shifts for the month
        query = db.query(ScheduleShift).filter(
            ScheduleShift.employee_id == employee_id,
            ScheduleShift.date >= start_date,
            ScheduleShift.date <= end_date
        ).join(Schedule).filter(
            Schedule.status.in_(["published", "active"])
        )
        
        shifts = query.all()
        
        # Format schedule data by days
        schedule_data = []
        monthly_totals = {
            "total_hours": 0,
            "overtime_hours": 0,
            "days_worked": 0,
            "shifts_count": len(shifts)
        }
        
        # Create a dictionary for quick lookup
        shifts_by_date = {}
        for shift in shifts:
            if shift.date not in shifts_by_date:
                shifts_by_date[shift.date] = []
            shifts_by_date[shift.date].append(shift)
        
        # Process each day of the month
        current_date = start_date
        while current_date <= end_date:
            day_shifts = shifts_by_date.get(current_date, [])
            day_total_hours = 0
            
            day_data = {
                "date": current_date.isoformat(),
                "day_of_week": current_date.strftime("%A"),
                "shifts": []
            }
            
            for shift in day_shifts:
                # Calculate shift duration
                shift_start = datetime.combine(shift.date, shift.override_start_time or shift.start_time)
                shift_end = datetime.combine(shift.date, shift.override_end_time or shift.end_time)
                
                if shift_end < shift_start:
                    shift_end += relativedelta(days=1)
                
                duration_hours = (shift_end - shift_start).total_seconds() / 3600
                day_total_hours += duration_hours
                
                shift_data = {
                    "id": str(shift.id),
                    "start_time": (shift.override_start_time or shift.start_time).isoformat(),
                    "end_time": (shift.override_end_time or shift.end_time).isoformat(),
                    "shift_name": shift.shift.name if shift.shift else "Unknown",
                    "shift_type": shift.shift.shift_type if shift.shift else "regular",
                    "status": shift.status,
                    "duration_hours": round(duration_hours, 2),
                    "color_code": shift.shift.color_code if shift.shift else "#3498db"
                }
                
                day_data["shifts"].append(shift_data)
            
            day_data["total_hours"] = round(day_total_hours, 2)
            
            if day_shifts:
                monthly_totals["days_worked"] += 1
                monthly_totals["total_hours"] += day_total_hours
                
                # Check for overtime (more than 8 hours per day)
                if day_total_hours > 8:
                    monthly_totals["overtime_hours"] += day_total_hours - 8
            
            schedule_data.append(day_data)
            current_date += relativedelta(days=1)
        
        # Round totals
        for key in ["total_hours", "overtime_hours"]:
            monthly_totals[key] = round(monthly_totals[key], 2)
        
        return EmployeeScheduleMonthly(
            employee_id=employee_id,
            month=month,
            year=year,
            schedule_data=schedule_data,
            monthly_summary=monthly_totals
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get monthly schedule: {str(e)}")


@router.get("/{employee_id}/schedule/week", response_model=EmployeeScheduleWeekly)
async def get_employee_weekly_schedule(
    employee_id: uuid.UUID,
    week_start: date = Query(...),
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Get employee's weekly schedule view"""
    try:
        # Check access permissions
        if not current_user.is_superuser and not current_user.has_permission("employees.read"):
            if not current_user.employee_profile or current_user.employee_profile.id != employee_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Get employee
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        # Organization check
        if not current_user.is_superuser and employee.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Calculate week boundaries
        week_end = week_start + relativedelta(days=6)
        
        # Get schedule shifts for the week
        query = db.query(ScheduleShift).filter(
            ScheduleShift.employee_id == employee_id,
            ScheduleShift.date >= week_start,
            ScheduleShift.date <= week_end
        ).join(Schedule).filter(
            Schedule.status.in_(["published", "active"])
        )
        
        shifts = query.all()
        
        # Format schedule data by days
        schedule_data = []
        weekly_totals = {
            "total_hours": 0,
            "overtime_hours": 0,
            "days_worked": 0,
            "shifts_count": len(shifts)
        }
        
        # Create a dictionary for quick lookup
        shifts_by_date = {}
        for shift in shifts:
            if shift.date not in shifts_by_date:
                shifts_by_date[shift.date] = []
            shifts_by_date[shift.date].append(shift)
        
        # Process each day of the week
        current_date = week_start
        for day_num in range(7):
            day_shifts = shifts_by_date.get(current_date, [])
            day_total_hours = 0
            
            day_data = {
                "date": current_date.isoformat(),
                "day_of_week": current_date.strftime("%A"),
                "day_number": day_num + 1,
                "shifts": []
            }
            
            for shift in day_shifts:
                # Calculate shift duration
                shift_start = datetime.combine(shift.date, shift.override_start_time or shift.start_time)
                shift_end = datetime.combine(shift.date, shift.override_end_time or shift.end_time)
                
                if shift_end < shift_start:
                    shift_end += relativedelta(days=1)
                
                duration_hours = (shift_end - shift_start).total_seconds() / 3600
                day_total_hours += duration_hours
                
                shift_data = {
                    "id": str(shift.id),
                    "start_time": (shift.override_start_time or shift.start_time).isoformat(),
                    "end_time": (shift.override_end_time or shift.end_time).isoformat(),
                    "shift_name": shift.shift.name if shift.shift else "Unknown",
                    "shift_type": shift.shift.shift_type if shift.shift else "regular",
                    "status": shift.status,
                    "duration_hours": round(duration_hours, 2),
                    "color_code": shift.shift.color_code if shift.shift else "#3498db"
                }
                
                day_data["shifts"].append(shift_data)
            
            day_data["total_hours"] = round(day_total_hours, 2)
            
            if day_shifts:
                weekly_totals["days_worked"] += 1
                weekly_totals["total_hours"] += day_total_hours
                
                # Check for overtime (more than 8 hours per day)
                if day_total_hours > 8:
                    weekly_totals["overtime_hours"] += day_total_hours - 8
            
            schedule_data.append(day_data)
            current_date += relativedelta(days=1)
        
        # Round totals
        for key in ["total_hours", "overtime_hours"]:
            weekly_totals[key] = round(weekly_totals[key], 2)
        
        return EmployeeScheduleWeekly(
            employee_id=employee_id,
            week_start=week_start,
            week_end=week_end,
            schedule_data=schedule_data,
            weekly_summary=weekly_totals
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get weekly schedule: {str(e)}")


@router.post("/{employee_id}/schedule/acknowledge")
async def acknowledge_schedule(
    employee_id: uuid.UUID,
    acknowledgment: ScheduleAcknowledgment,
    current_user: User = Depends(require_permissions(["schedules.read"])),
    db: Session = Depends(get_db)
):
    """Acknowledge schedule viewing"""
    try:
        # Check if user can acknowledge this employee's schedule
        if not current_user.is_superuser and not current_user.has_permission("employees.read"):
            if not current_user.employee_profile or current_user.employee_profile.id != employee_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Get employee
        employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        # Organization check
        if not current_user.is_superuser and employee.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Validate schedule exists
        schedule = db.query(Schedule).filter(Schedule.id == acknowledgment.schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # Record acknowledgment
        await ScheduleService.record_schedule_acknowledgment(
            employee_id,
            acknowledgment.schedule_id,
            acknowledgment.acknowledged_at,
            acknowledgment.comments,
            current_user.id,
            db
        )
        
        # Send WebSocket notification
        await websocket_manager.broadcast_schedule_event(
            "schedule.acknowledged",
            {
                "employee_id": str(employee_id),
                "schedule_id": str(acknowledgment.schedule_id),
                "acknowledged_at": acknowledgment.acknowledged_at.isoformat(),
                "acknowledged_by": str(current_user.id)
            }
        )
        
        return {
            "message": "Schedule acknowledgment recorded successfully",
            "employee_id": str(employee_id),
            "schedule_id": str(acknowledgment.schedule_id),
            "acknowledged_at": acknowledgment.acknowledged_at.isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to acknowledge schedule: {str(e)}")


@router.get("/me/schedule", response_model=EmployeeScheduleResponse)
async def get_my_schedule(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    include_conflicts: bool = Query(True),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's own schedule"""
    try:
        # Check if user has an employee profile
        if not current_user.employee_profile:
            raise HTTPException(status_code=404, detail="Employee profile not found")
        
        # Delegate to the main employee schedule endpoint
        return await get_employee_schedule(
            current_user.employee_profile.id,
            start_date,
            end_date,
            include_conflicts,
            current_user,
            db
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get personal schedule: {str(e)}")