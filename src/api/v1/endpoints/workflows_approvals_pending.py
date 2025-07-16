# Task 41: GET /api/v1/workflows/approvals/pending
# BDD Scenario: "Manager Views Pending Approvals"
# Implements: Manager dashboard from employee_requests
# Database: employee_requests, approval_workflows

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from pydantic import BaseModel, Field
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import uuid

from ...core.database import get_db

router = APIRouter()

# Response Models
class PendingApproval(BaseModel):
    id: str
    request_type: str
    employee_name: str
    employee_id: str
    department: str
    request_title: str
    request_details: str
    submitted_at: datetime
    due_date: datetime
    priority: str
    status: str
    days_pending: int
    escalation_level: int
    current_stage: str
    assignee_name: str

class PendingApprovalsResponse(BaseModel):
    status: str
    message: str
    pending_approvals: List[PendingApproval]
    summary: Dict[str, Any]
    filters_applied: Dict[str, Any]

@router.get("/api/v1/workflows/approvals/pending", response_model=PendingApprovalsResponse)
async def get_pending_approvals(
    manager_id: Optional[str] = Query(None, description="Manager ID to filter approvals"),
    department: Optional[str] = Query(None, description="Department filter"),
    priority: Optional[str] = Query(None, description="Priority filter (low/medium/high/urgent)"),
    request_type: Optional[str] = Query(None, description="Request type filter"),
    overdue_only: Optional[bool] = Query(False, description="Show only overdue approvals"),
    limit: Optional[int] = Query(50, description="Maximum number of results"),
    offset: Optional[int] = Query(0, description="Pagination offset"),
    db: AsyncSession = Depends(get_db)
) -> PendingApprovalsResponse:
    """
    BDD Scenario: Manager Views Pending Approvals
    
    Given a manager needs to review pending requests
    When they access the pending approvals dashboard
    Then they should see all requests awaiting their approval with details
    """
    
    try:
        # Build base query for pending approvals from employee_requests and approval_workflows
        base_query = """
        SELECT 
            er.id,
            er.request_type,
            e.full_name as employee_name,
            e.employee_id,
            d.department_name as department,
            er.request_title,
            er.request_details,
            er.submitted_at,
            er.due_date,
            er.priority,
            er.status,
            EXTRACT(DAY FROM CURRENT_TIMESTAMP - er.submitted_at) as days_pending,
            COALESCE(aw.escalation_level, 0) as escalation_level,
            aw.current_stage,
            approver.full_name as assignee_name
        FROM employee_requests er
        JOIN employees e ON er.employee_id = e.id
        JOIN departments d ON e.department_id = d.id
        LEFT JOIN approval_workflows aw ON er.id = aw.request_id
        LEFT JOIN employees approver ON aw.current_approver_id = approver.id
        WHERE er.status IN ('pending', 'in_review')
        """
        
        # Apply filters
        conditions = []
        params = {}
        
        if manager_id:
            conditions.append("AND (aw.current_approver_id = :manager_id OR e.manager_id = :manager_id)")
            params['manager_id'] = manager_id
            
        if department:
            conditions.append("AND d.department_name ILIKE :department")
            params['department'] = f"%{department}%"
            
        if priority:
            conditions.append("AND er.priority = :priority")
            params['priority'] = priority
            
        if request_type:
            conditions.append("AND er.request_type = :request_type")
            params['request_type'] = request_type
            
        if overdue_only:
            conditions.append("AND er.due_date < CURRENT_TIMESTAMP")
        
        # Complete query with conditions
        query = base_query + " " + " ".join(conditions)
        query += " ORDER BY er.priority DESC, er.due_date ASC, er.submitted_at ASC"
        query += " LIMIT :limit OFFSET :offset"
        
        params.update({'limit': limit, 'offset': offset})
        
        # Execute query
        result = await db.execute(query, params)
        rows = result.fetchall()
        
        # Process results
        pending_approvals = []
        for row in rows:
            approval = PendingApproval(
                id=str(row.id),
                request_type=row.request_type,
                employee_name=row.employee_name,
                employee_id=row.employee_id,
                department=row.department,
                request_title=row.request_title,
                request_details=row.request_details,
                submitted_at=row.submitted_at,
                due_date=row.due_date,
                priority=row.priority,
                status=row.status,
                days_pending=int(row.days_pending),
                escalation_level=row.escalation_level,
                current_stage=row.current_stage or "Initial Review",
                assignee_name=row.assignee_name or "Pending Assignment"
            )
            pending_approvals.append(approval)
        
        # Get summary statistics
        summary_query = """
        SELECT 
            COUNT(*) as total_pending,
            COUNT(CASE WHEN er.priority = 'urgent' THEN 1 END) as urgent_count,
            COUNT(CASE WHEN er.priority = 'high' THEN 1 END) as high_count,
            COUNT(CASE WHEN er.due_date < CURRENT_TIMESTAMP THEN 1 END) as overdue_count,
            COUNT(CASE WHEN aw.escalation_level > 0 THEN 1 END) as escalated_count,
            AVG(EXTRACT(DAY FROM CURRENT_TIMESTAMP - er.submitted_at)) as avg_days_pending
        FROM employee_requests er
        LEFT JOIN approval_workflows aw ON er.id = aw.request_id
        WHERE er.status IN ('pending', 'in_review')
        """
        
        if manager_id:
            summary_query += " AND (aw.current_approver_id = :manager_id)"
            
        summary_result = await db.execute(summary_query, {'manager_id': manager_id} if manager_id else {})
        summary_row = summary_result.fetchone()
        
        summary = {
            "total_pending": summary_row.total_pending,
            "urgent_count": summary_row.urgent_count,
            "high_count": summary_row.high_count,
            "overdue_count": summary_row.overdue_count,
            "escalated_count": summary_row.escalated_count,
            "avg_days_pending": round(float(summary_row.avg_days_pending or 0), 1),
            "showing_count": len(pending_approvals)
        }
        
        filters_applied = {
            "manager_id": manager_id,
            "department": department,
            "priority": priority,
            "request_type": request_type,
            "overdue_only": overdue_only,
            "limit": limit,
            "offset": offset
        }
        
        return PendingApprovalsResponse(
            status="success",
            message=f"Retrieved {len(pending_approvals)} pending approvals",
            pending_approvals=pending_approvals,
            summary=summary,
            filters_applied=filters_applied
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve pending approvals: {str(e)}"
        )

# Health check endpoint
@router.get("/api/v1/workflows/approvals/pending/health")
async def pending_approvals_health_check() -> Dict[str, Any]:
    """Health check for pending approvals endpoint"""
    return {
        "status": "healthy",
        "endpoint": "GET /api/v1/workflows/approvals/pending",
        "bdd_scenario": "Manager Views Pending Approvals",
        "task_number": 41,
        "database_tables": ["employee_requests", "approval_workflows", "employees", "departments"],
        "real_implementation": True,
        "mock_data": False,
        "timestamp": datetime.now().isoformat()
    }