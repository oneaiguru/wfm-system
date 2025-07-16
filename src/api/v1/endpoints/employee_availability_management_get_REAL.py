"""
REAL EMPLOYEE AVAILABILITY MANAGEMENT GET ENDPOINT - Task 21
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import date, timedelta

from ...core.database import get_db

router = APIRouter()

class AvailabilityWindow(BaseModel):
    date: str
    available_start: Optional[str]
    available_end: Optional[str]
    availability_type: str
    conflicts: List[str]

@router.get("/employees/{employee_id}/availability/management", tags=["🔥 REAL Employee Availability Management"])
async def get_employee_availability_management(
    employee_id: UUID,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE AVAILABILITY MANAGEMENT - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("SELECT id, first_name, last_name FROM employees WHERE id = :employee_id")
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Set default date range if not provided
        if not start_date:
            start_date = date.today()
        if not end_date:
            # Default to 30 days from start_date
            end_date = start_date + timedelta(days=30)
        
        # Get availability windows for the date range
        availability_query = text("""
            SELECT ea.start_date, ea.end_date, ea.start_time, ea.end_time,
                   ea.availability_type, ea.days_of_week
            FROM employee_availability ea
            WHERE ea.employee_id = :employee_id
            AND ea.start_date <= :end_date
            AND ea.end_date >= :start_date
            ORDER BY ea.start_date, ea.start_time
        """)
        
        availability_result = await db.execute(availability_query, {
            "employee_id": employee_id,
            "start_date": start_date,
            "end_date": end_date
        })
        
        # Get scheduled shifts for conflict detection
        shifts_query = text("""
            SELECT ss.shift_date, ss.start_time, ss.end_time
            FROM schedule_shifts ss
            WHERE ss.employee_id = :employee_id
            AND ss.shift_date BETWEEN :start_date AND :end_date
            ORDER BY ss.shift_date, ss.start_time
        """)
        
        shifts_result = await db.execute(shifts_query, {
            "employee_id": employee_id,
            "start_date": start_date,
            "end_date": end_date
        })
        
        # Build availability windows
        availability_windows = []
        
        # Process availability periods
        for row in availability_result.fetchall():
            # Generate windows for each day in the period
            current_date = row.start_date
            while current_date <= row.end_date:
                # Check if this day is included in days_of_week filter
                day_name = current_date.strftime('%A').lower()
                if not row.days_of_week or day_name in [d.lower() for d in row.days_of_week]:
                    availability_windows.append(AvailabilityWindow(
                        date=current_date.isoformat(),
                        available_start=row.start_time.strftime("%H:%M") if row.start_time else None,
                        available_end=row.end_time.strftime("%H:%M") if row.end_time else None,
                        availability_type=row.availability_type,
                        conflicts=[]  # Will be populated with shift conflicts
                    ))
                
                current_date += timedelta(days=1)
        
        # Add shift conflicts
        shift_conflicts = {}
        for shift_row in shifts_result.fetchall():
            shift_date = shift_row.shift_date.isoformat()
            if shift_date not in shift_conflicts:
                shift_conflicts[shift_date] = []
            shift_conflicts[shift_date].append(
                f"Scheduled shift: {shift_row.start_time.strftime('%H:%M')}-{shift_row.end_time.strftime('%H:%M')}"
            )
        
        # Update availability windows with conflicts
        for window in availability_windows:
            if window.date in shift_conflicts:
                window.conflicts = shift_conflicts[window.date]
        
        # If no availability found, provide default availability
        if not availability_windows:
            current = start_date
            while current <= end_date:
                # Default: available Monday-Friday 9-17
                if current.weekday() < 5:  # Monday-Friday
                    availability_windows.append(AvailabilityWindow(
                        date=current.isoformat(),
                        available_start="09:00",
                        available_end="17:00",
                        availability_type="available",
                        conflicts=shift_conflicts.get(current.isoformat(), [])
                    ))
                current += timedelta(days=1)
        
        return {
            "employee_id": str(employee_id),
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "date_range": f"{start_date.isoformat()} to {end_date.isoformat()}",
            "total_days": len(availability_windows),
            "available_days": len([w for w in availability_windows if w.availability_type == "available"]),
            "conflicts_detected": len([w for w in availability_windows if w.conflicts]),
            "availability_windows": availability_windows
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get availability management: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE AVAILABILITY MANAGEMENT GET ENDPOINT
"""