from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from typing import Dict, Any, List
from ...core.database import get_db

router = APIRouter()

@router.get("/employees/search/query", tags=["🔥 REAL Employees"])
async def search_employees(
    q: str = Query(..., min_length=2, description="Search query (name, email, employee_number)"),
    db: AsyncSession = Depends(get_db)
):
    """Search employees by name or employee_number (UUID compatible)"""
    try:
        query = text("""
            SELECT 
                id,
                employee_number,
                first_name,
                last_name,
                CONCAT(first_name, ' ', last_name) as full_name
            FROM employees
            WHERE 
                first_name ILIKE :search_term
                OR last_name ILIKE :search_term
                OR employee_number ILIKE :search_term
                OR CONCAT(first_name, ' ', last_name) ILIKE :search_term
            ORDER BY 
                CASE WHEN employee_number ILIKE :search_term THEN 1 ELSE 2 END,
                last_name, first_name
            LIMIT 50
        """)
        
        search_pattern = f"%{q}%"
        result = await db.execute(query, {"search_term": search_pattern})
        
        employees = []
        for row in result.fetchall():
            employees.append({
                "id": str(row.id),  # UUID as string
                "employee_number": row.employee_number,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "full_name": row.full_name
            })
        
        return {"query": q, "results": employees, "count": len(employees)}
        
    except Exception as e:
        raise HTTPException(500, f"Search failed: {str(e)}")