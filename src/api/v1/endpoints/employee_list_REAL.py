from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from typing import List, Dict, Any
from ...core.database import get_db

router = APIRouter()

@router.get("/employees/list", tags=["🔥 REAL Employees"])
async def get_employees_list(db: AsyncSession = Depends(get_db)):
    """
    Get all employees with UUID IDs for vacation requests compatibility
    """
    try:
        query = text("""
            SELECT 
                id,
                employee_number,
                first_name,
                last_name,
                CONCAT(first_name, ' ', last_name) as full_name
            FROM employees
            WHERE first_name IS NOT NULL
            ORDER BY last_name, first_name
        """)
        
        result = await db.execute(query)
        employees = []
        
        for row in result.fetchall():
            employees.append({
                "id": str(row.id),  # UUID as string
                "employee_number": row.employee_number,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "full_name": row.full_name,
                "department": "Call Center",  # Default for compatibility
                "position": f"Agent ({row.employee_number})",
                "status": "active"
            })
        
        return employees
        
    except Exception as e:
        raise HTTPException(500, f"Failed to get employees: {str(e)}")