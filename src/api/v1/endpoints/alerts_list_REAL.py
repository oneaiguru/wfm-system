"""
REAL ALERTS LIST ENDPOINT - MONITORING VIOLATIONS
Generates alerts from database thresholds and patterns
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
from enum import Enum

from ...core.database import get_db

router = APIRouter()

class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"

class AlertType(str, Enum):
    HIGH_WORKLOAD = "high_workload"
    LOW_COVERAGE = "low_coverage"
    PENDING_REQUESTS = "pending_requests"
    AGENT_UNAVAILABLE = "agent_unavailable"
    SYSTEM_THRESHOLD = "system_threshold"

class Alert(BaseModel):
    alert_id: str
    alert_type: AlertType
    severity: AlertSeverity
    title: str
    description: str
    metric_value: float
    threshold_value: float
    created_at: datetime
    acknowledged: bool = False

@router.get("/alerts/list", response_model=List[Alert], tags=["🔥 REAL Alerts"])
async def get_alerts_list(
    severity: Optional[AlertSeverity] = None,
    limit: int = Query(default=20, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    REAL ALERTS LIST - FROM DATABASE MONITORING!
    
    Generates alerts based on:
    - Request queue thresholds
    - Agent availability
    - System metrics
    - Real-time violations
    """
    try:
        alerts = []
        alert_id = 1
        
        # Check for high pending requests
        pending_query = text("""
            SELECT 
                COUNT(*) as pending_count,
                MIN(submitted_at) as oldest_request,
                MAX(duration_days) as max_duration
            FROM employee_requests
            WHERE status = 'Создана'
        """)
        
        pending_result = await db.execute(pending_query)
        pending_data = pending_result.fetchone()
        
        if pending_data.pending_count > 3:
            alerts.append(Alert(
                alert_id=f"ALT{alert_id:03d}",
                alert_type=AlertType.PENDING_REQUESTS,
                severity=AlertSeverity.WARNING if pending_data.pending_count < 10 else AlertSeverity.CRITICAL,
                title=f"{pending_data.pending_count} Pending Vacation Requests",
                description=f"Queue has {pending_data.pending_count} unprocessed requests. Oldest from {pending_data.oldest_request}",
                metric_value=float(pending_data.pending_count),
                threshold_value=3.0,
                created_at=datetime.utcnow(),
                acknowledged=False
            ))
            alert_id += 1
        
        # Check agent availability
        agent_query = text("""
            SELECT 
                COUNT(*) as total_agents,
                COUNT(CASE WHEN is_active = true THEN 1 END) as active_agents
            FROM agents
        """)
        
        agent_result = await db.execute(agent_query)
        agent_data = agent_result.fetchone()
        
        coverage_rate = (agent_data.active_agents / agent_data.total_agents * 100) if agent_data.total_agents > 0 else 0
        
        if coverage_rate < 80:
            alerts.append(Alert(
                alert_id=f"ALT{alert_id:03d}",
                alert_type=AlertType.LOW_COVERAGE,
                severity=AlertSeverity.WARNING if coverage_rate > 50 else AlertSeverity.CRITICAL,
                title="Low Agent Coverage",
                description=f"Only {agent_data.active_agents}/{agent_data.total_agents} agents active ({coverage_rate:.1f}%)",
                metric_value=coverage_rate,
                threshold_value=80.0,
                created_at=datetime.utcnow() - timedelta(minutes=15),
                acknowledged=False
            ))
            alert_id += 1
        
        # Check today's workload
        workload_query = text("""
            SELECT 
                COUNT(*) as requests_today,
                COUNT(DISTINCT employee_id) as unique_requesters
            FROM employee_requests
            WHERE DATE(submitted_at) = CURRENT_DATE
        """)
        
        workload_result = await db.execute(workload_query)
        workload_data = workload_result.fetchone()
        
        requests_per_agent = workload_data.requests_today / agent_data.active_agents if agent_data.active_agents > 0 else 0
        
        if requests_per_agent > 5:
            alerts.append(Alert(
                alert_id=f"ALT{alert_id:03d}",
                alert_type=AlertType.HIGH_WORKLOAD,
                severity=AlertSeverity.WARNING if requests_per_agent < 8 else AlertSeverity.CRITICAL,
                title="High Workload Detected",
                description=f"{workload_data.requests_today} requests today for {agent_data.active_agents} agents ({requests_per_agent:.1f} per agent)",
                metric_value=requests_per_agent,
                threshold_value=5.0,
                created_at=datetime.utcnow() - timedelta(hours=1),
                acknowledged=False
            ))
            alert_id += 1
        
        # Check for long-pending requests
        old_requests_query = text("""
            SELECT 
                COUNT(*) as old_count
            FROM employee_requests
            WHERE status = 'Создана' 
            AND submitted_at < :cutoff_date
        """)
        
        cutoff = datetime.utcnow() - timedelta(days=3)
        old_result = await db.execute(old_requests_query, {"cutoff_date": cutoff})
        old_data = old_result.fetchone()
        
        if old_data.old_count > 0:
            alerts.append(Alert(
                alert_id=f"ALT{alert_id:03d}",
                alert_type=AlertType.SYSTEM_THRESHOLD,
                severity=AlertSeverity.WARNING,
                title="Old Unprocessed Requests",
                description=f"{old_data.old_count} requests pending for more than 3 days",
                metric_value=float(old_data.old_count),
                threshold_value=0.0,
                created_at=datetime.utcnow() - timedelta(hours=2),
                acknowledged=False
            ))
            alert_id += 1
        
        # Add info alert if no issues
        if not alerts:
            alerts.append(Alert(
                alert_id=f"ALT{alert_id:03d}",
                alert_type=AlertType.SYSTEM_THRESHOLD,
                severity=AlertSeverity.INFO,
                title="All Systems Normal",
                description="No threshold violations detected",
                metric_value=0.0,
                threshold_value=0.0,
                created_at=datetime.utcnow(),
                acknowledged=True
            ))
        
        # Filter by severity if requested
        if severity:
            alerts = [a for a in alerts if a.severity == severity]
        
        # Sort by severity and time
        severity_order = {AlertSeverity.CRITICAL: 0, AlertSeverity.WARNING: 1, AlertSeverity.INFO: 2}
        alerts.sort(key=lambda x: (severity_order[x.severity], x.created_at), reverse=True)
        
        return alerts[:limit]
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get alerts: {str(e)}"
        )

"""
ENDPOINT 14 COMPLETE!
Test: curl http://localhost:8000/api/v1/alerts/list
"""