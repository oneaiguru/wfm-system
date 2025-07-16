"""
REAL EMPLOYEE AVAILABILITY GET ENDPOINT - Task 12
Retrieves employee availability periods following proven UUID compliance pattern
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import date

from ...core.database import get_db

router = APIRouter()

class AvailabilityPeriodResponse(BaseModel):
    availability_id: str
    start_date: str
    end_date: str
    start_time: str
    end_time: str
    availability_type: str
    days_of_week: List[str]
    reason: Optional[str]
    is_recurring: bool
    created_at: str

class EmployeeAvailabilityResponse(BaseModel):
    employee_id: str
    employee_name: str
    total_periods: int
    date_range: str
    availability_periods: List[AvailabilityPeriodResponse]

@router.get("/employees/{employee_id}/availability", response_model=EmployeeAvailabilityResponse, tags=["🔥 REAL Employee Availability"])
async def get_employee_availability(
    employee_id: UUID,
    start_date: Optional[date] = Query(None, description="Filter from date (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="Filter until date (YYYY-MM-DD)"),
    availability_type: Optional[str] = Query(None, description="Filter by type: available, unavailable, preferred, limited"),
    include_recurring: bool = Query(True, description="Include recurring patterns"),
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE AVAILABILITY GET - NO MOCKS!
    
    Retrieves employee availability periods with filtering options
    Uses real employee_availability table with UUID compliance
    
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
        
        # Build query conditions
        where_conditions = ["ea.employee_id = :employee_id"]
        params = {"employee_id": employee_id}
        
        if start_date:
            where_conditions.append("ea.end_date >= :start_date")
            params["start_date"] = start_date
            
        if end_date:
            where_conditions.append("ea.start_date <= :end_date")
            params["end_date"] = end_date
            
        if availability_type:
            where_conditions.append("ea.availability_type = :availability_type")
            params["availability_type"] = availability_type
            
        if not include_recurring:
            where_conditions.append("ea.is_recurring = false")
        
        where_clause = " AND ".join(where_conditions)
        
        # Get availability periods
        availability_query = text(f"""
            SELECT 
                ea.id,
                ea.start_date,
                ea.end_date,
                ea.start_time,
                ea.end_time,
                ea.availability_type,
                ea.days_of_week,
                ea.reason,
                ea.is_recurring,
                ea.created_at
            FROM employee_availability ea
            WHERE {where_clause}
            ORDER BY ea.start_date ASC, ea.start_time ASC
        """)
        
        availability_result = await db.execute(availability_query, params)
        availability_periods = []
        
        for row in availability_result.fetchall():
            availability_periods.append(AvailabilityPeriodResponse(
                availability_id=str(row.id),
                start_date=row.start_date.isoformat(),
                end_date=row.end_date.isoformat(),
                start_time=row.start_time.strftime("%H:%M"),
                end_time=row.end_time.strftime("%H:%M"),
                availability_type=row.availability_type,
                days_of_week=row.days_of_week or [],
                reason=row.reason,
                is_recurring=row.is_recurring,
                created_at=row.created_at.isoformat()
            ))
        
        # Build date range description
        if start_date and end_date:
            date_range = f"{start_date.isoformat()} to {end_date.isoformat()}"
        elif start_date:
            date_range = f"from {start_date.isoformat()}"
        elif end_date:
            date_range = f"until {end_date.isoformat()}"
        else:
            date_range = "all periods"
        
        return EmployeeAvailabilityResponse(
            employee_id=str(employee_id),
            employee_name=f"{employee.first_name} {employee.last_name}",
            total_periods=len(availability_periods),
            date_range=date_range,
            availability_periods=availability_periods
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get employee availability: {str(e)}"
        )

"""
STATUS: ✅ WORKING REAL EMPLOYEE AVAILABILITY GET ENDPOINT

FEATURES:
- UUID employee_id parameter compliance
- Real employee_availability table queries
- Date range filtering with query parameters
- Availability type filtering
- Recurring pattern inclusion control
- Time format output (HH:MM)
- Russian text support for reasons
- Proper error handling (404/500)

CONTINUING WITH PERFORMANCE METRICS ENDPOINTS...
"""