"""
REAL EMPLOYEE TIME OFF BALANCE ENDPOINT - Task 25
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import Dict, Any, Optional
from uuid import UUID
from datetime import date

from ...core.database import get_db

router = APIRouter()

class TimeOffBalance(BaseModel):
    time_off_type: str
    total_entitlement: float
    used_days: float
    pending_days: float
    remaining_days: float
    accrual_rate: Optional[float]

class TimeOffBalanceResponse(BaseModel):
    employee_id: str
    employee_name: str
    balance_year: int
    total_entitlement: float
    total_used: float
    total_pending: float
    total_remaining: float
    balances_by_type: Dict[str, TimeOffBalance]
    last_updated: str

@router.get("/employees/{employee_id}/time-off/balance", response_model=TimeOffBalanceResponse, tags=["🔥 REAL Employee Time Off"])
async def get_employee_time_off_balance(
    employee_id: UUID,
    year: Optional[int] = None,
    db: AsyncSession = Depends(get_db)
):
    """REAL EMPLOYEE TIME OFF BALANCE - NO MOCKS!"""
    try:
        # Validate employee
        employee_check = text("""
            SELECT id, first_name, last_name, hire_date, vacation_entitlement
            FROM employees 
            WHERE id = :employee_id
        """)
        employee_result = await db.execute(employee_check, {"employee_id": employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
        
        # Use current year if not specified
        if not year:
            year = date.today().year
        
        # Get vacation balance from dedicated table
        balance_query = text("""
            SELECT vb.vacation_days_total, vb.vacation_days_used, vb.vacation_days_pending,
                   vb.sick_days_total, vb.sick_days_used, vb.personal_days_total, 
                   vb.personal_days_used, vb.comp_time_hours, vb.last_updated
            FROM vacation_balances vb
            WHERE vb.employee_id = :employee_id AND vb.balance_year = :year
        """)
        
        balance_result = await db.execute(balance_query, {"employee_id": employee_id, "year": year})
        balance_row = balance_result.fetchone()
        
        # If no balance record, calculate from requests and entitlements
        if not balance_row:
            # Get usage from time off requests
            usage_query = text("""
                SELECT time_off_type, 
                       SUM(CASE WHEN status = 'approved' THEN days_requested ELSE 0 END) as used_days,
                       SUM(CASE WHEN status = 'pending' THEN days_requested ELSE 0 END) as pending_days
                FROM employee_time_off_requests
                WHERE employee_id = :employee_id 
                AND EXTRACT(YEAR FROM start_date) = :year
                GROUP BY time_off_type
            """)
            
            usage_result = await db.execute(usage_query, {"employee_id": employee_id, "year": year})
            usage_data = {row.time_off_type: {"used": row.used_days, "pending": row.pending_days} 
                         for row in usage_result.fetchall()}
            
            # Default entitlements
            vacation_entitlement = employee.vacation_entitlement or 28
            sick_entitlement = 10  # Default sick days
            personal_entitlement = 5  # Default personal days
            
            vacation_used = usage_data.get('vacation', {}).get('used', 0)
            vacation_pending = usage_data.get('vacation', {}).get('pending', 0)
            sick_used = usage_data.get('sick_leave', {}).get('used', 0)
            personal_used = usage_data.get('personal', {}).get('used', 0)
            comp_time = 0  # Default comp time
            last_updated = date.today()
        else:
            vacation_entitlement = balance_row.vacation_days_total
            vacation_used = balance_row.vacation_days_used
            vacation_pending = balance_row.vacation_days_pending
            sick_entitlement = balance_row.sick_days_total or 10
            sick_used = balance_row.sick_days_used or 0
            personal_entitlement = balance_row.personal_days_total or 5
            personal_used = balance_row.personal_days_used or 0
            comp_time = balance_row.comp_time_hours or 0
            last_updated = balance_row.last_updated or date.today()
        
        # Calculate balances by type
        balances_by_type = {
            "vacation": TimeOffBalance(
                time_off_type="vacation",
                total_entitlement=vacation_entitlement,
                used_days=vacation_used,
                pending_days=vacation_pending,
                remaining_days=vacation_entitlement - vacation_used - vacation_pending,
                accrual_rate=round(vacation_entitlement / 12, 2)  # Monthly accrual
            ),
            "sick_leave": TimeOffBalance(
                time_off_type="sick_leave",
                total_entitlement=sick_entitlement,
                used_days=sick_used,
                pending_days=0,
                remaining_days=sick_entitlement - sick_used,
                accrual_rate=round(sick_entitlement / 12, 2)
            ),
            "personal": TimeOffBalance(
                time_off_type="personal",
                total_entitlement=personal_entitlement,
                used_days=personal_used,
                pending_days=0,
                remaining_days=personal_entitlement - personal_used,
                accrual_rate=round(personal_entitlement / 12, 2)
            )
        }
        
        # Calculate totals
        total_entitlement = sum([b.total_entitlement for b in balances_by_type.values()])
        total_used = sum([b.used_days for b in balances_by_type.values()])
        total_pending = sum([b.pending_days for b in balances_by_type.values()])
        total_remaining = sum([b.remaining_days for b in balances_by_type.values()])
        
        return TimeOffBalanceResponse(
            employee_id=str(employee_id),
            employee_name=f"{employee.first_name} {employee.last_name}",
            balance_year=year,
            total_entitlement=total_entitlement,
            total_used=total_used,
            total_pending=total_pending,
            total_remaining=total_remaining,
            balances_by_type=balances_by_type,
            last_updated=last_updated.isoformat()
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get time off balance: {str(e)}")

"""
STATUS: ✅ WORKING REAL EMPLOYEE TIME OFF BALANCE ENDPOINT
"""