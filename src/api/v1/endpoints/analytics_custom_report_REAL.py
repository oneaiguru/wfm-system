from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
import uuid
import json
from ...core.database import get_db
from ...core.auth import get_current_user

router = APIRouter()

# BDD Scenario: "Create Custom Report with Dynamic Parameters"
# File: Analytics & BI feature scenarios

class ReportParameter(BaseModel):
    name: str
    type: str = Field(..., regex="^(string|number|date|boolean|select)$")
    required: bool = True
    default_value: Optional[Any] = None
    options: Optional[List[str]] = None

class CustomReportRequest(BaseModel):
    name: str
    description: Optional[str] = None
    sql_query: Optional[str] = None
    report_type: str = Field(..., regex="^(table|chart|dashboard|export)$")
    parameters: List[ReportParameter] = []
    schedule: Optional[Dict] = None
    output_format: str = Field(default="json", regex="^(json|csv|excel|pdf)$")
    filters: Optional[Dict] = {}
    grouping: Optional[List[str]] = []
    sorting: Optional[List[Dict]] = []

class CustomReportResponse(BaseModel):
    report_id: str
    name: str
    status: str
    created_at: datetime
    data: Optional[List[Dict]] = None
    metadata: Dict
    execution_time_ms: int
    row_count: int

@router.post("/analytics/custom/report", response_model=CustomReportResponse, tags=["🔥 REAL Analytics"])
async def create_custom_report(
    report_request: CustomReportRequest,
    execute_immediately: bool = Query(False, description="Execute report immediately"),
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create custom report with dynamic SQL generation and enterprise features"""
    
    start_time = datetime.utcnow()
    report_id = str(uuid.uuid4())
    
    # Validate and secure SQL query
    if report_request.sql_query:
        if not validate_sql_query(report_request.sql_query):
            raise HTTPException(status_code=400, detail="Invalid or unsafe SQL query")
    else:
        # Generate SQL from report specification
        report_request.sql_query = generate_sql_from_spec(report_request)
    
    # Save report definition
    save_query = text("""
        INSERT INTO custom_reports (
            report_id, user_id, name, description, sql_query, report_type,
            parameters, schedule, output_format, filters, grouping, sorting,
            status, created_at, updated_at
        ) VALUES (
            :report_id, :user_id, :name, :description, :sql_query, :report_type,
            :parameters, :schedule, :output_format, :filters, :grouping, :sorting,
            :status, :created_at, :updated_at
        )
    """)
    
    await db.execute(save_query, {
        "report_id": report_id,
        "user_id": current_user["user_id"],
        "name": report_request.name,
        "description": report_request.description,
        "sql_query": report_request.sql_query,
        "report_type": report_request.report_type,
        "parameters": json.dumps([p.dict() for p in report_request.parameters]),
        "schedule": json.dumps(report_request.schedule) if report_request.schedule else None,
        "output_format": report_request.output_format,
        "filters": json.dumps(report_request.filters),
        "grouping": json.dumps(report_request.grouping),
        "sorting": json.dumps(report_request.sorting),
        "status": "created",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    })
    
    report_data = None
    execution_time_ms = 0
    row_count = 0
    
    if execute_immediately:
        # Execute report query
        try:
            execution_start = datetime.utcnow()
            
            # Apply parameters and filters to query
            final_query = apply_parameters_to_query(
                report_request.sql_query, 
                report_request.filters,
                report_request.grouping,
                report_request.sorting
            )
            
            result = await db.execute(text(final_query))
            rows = result.fetchall()
            
            execution_end = datetime.utcnow()
            execution_time_ms = int((execution_end - execution_start).total_seconds() * 1000)
            
            # Convert to dict format
            report_data = [dict(row._mapping) for row in rows]
            row_count = len(report_data)
            
            # Update report status
            update_query = text("""
                UPDATE custom_reports 
                SET status = 'completed', last_executed_at = :executed_at,
                    execution_time_ms = :execution_time, row_count = :row_count
                WHERE report_id = :report_id
            """)
            
            await db.execute(update_query, {
                "report_id": report_id,
                "executed_at": datetime.utcnow(),
                "execution_time": execution_time_ms,
                "row_count": row_count
            })
            
        except Exception as e:
            # Log error and update status
            error_query = text("""
                UPDATE custom_reports 
                SET status = 'error', error_message = :error_message
                WHERE report_id = :report_id
            """)
            
            await db.execute(error_query, {
                "report_id": report_id,
                "error_message": str(e)
            })
            
            raise HTTPException(status_code=500, detail=f"Report execution failed: {str(e)}")
    
    await db.commit()
    
    # Generate metadata
    metadata = {
        "parameters_count": len(report_request.parameters),
        "has_schedule": report_request.schedule is not None,
        "filters_applied": len(report_request.filters) if report_request.filters else 0,
        "grouping_fields": len(report_request.grouping),
        "sorting_fields": len(report_request.sorting),
        "query_complexity": analyze_query_complexity(report_request.sql_query),
        "estimated_memory_usage": estimate_memory_usage(row_count),
        "cache_eligible": is_cache_eligible(report_request.sql_query)
    }
    
    return CustomReportResponse(
        report_id=report_id,
        name=report_request.name,
        status="completed" if execute_immediately and report_data is not None else "created",
        created_at=start_time,
        data=report_data,
        metadata=metadata,
        execution_time_ms=execution_time_ms,
        row_count=row_count
    )

def validate_sql_query(sql: str) -> bool:
    """Validate SQL query for security and syntax"""
    # Remove comments and normalize
    sql_clean = sql.strip().lower()
    
    # Check for dangerous operations
    dangerous_keywords = [
        'drop', 'delete', 'update', 'insert', 'create', 'alter',
        'truncate', 'exec', 'execute', 'sp_', 'xp_'
    ]
    
    for keyword in dangerous_keywords:
        if keyword in sql_clean:
            return False
    
    # Must start with SELECT
    if not sql_clean.startswith('select'):
        return False
    
    return True

def generate_sql_from_spec(spec: CustomReportRequest) -> str:
    """Generate SQL query from report specification"""
    base_tables = {
        "table": "SELECT * FROM agents",
        "chart": "SELECT department_id, COUNT(*) as count FROM agents GROUP BY department_id",
        "dashboard": "SELECT 'employees' as metric, COUNT(*) as value FROM agents UNION SELECT 'requests' as metric, COUNT(*) as value FROM employee_requests",
        "export": "SELECT * FROM agents"
    }
    
    return base_tables.get(spec.report_type, base_tables["table"])

def apply_parameters_to_query(sql: str, filters: Dict, grouping: List[str], sorting: List[Dict]) -> str:
    """Apply filters, grouping, and sorting to SQL query"""
    query = sql
    
    # Apply filters
    if filters:
        where_conditions = []
        for field, value in filters.items():
            if isinstance(value, str):
                where_conditions.append(f"{field} ILIKE '%{value}%'")
            else:
                where_conditions.append(f"{field} = {value}")
        
        if where_conditions:
            if "WHERE" in query.upper():
                query += f" AND {' AND '.join(where_conditions)}"
            else:
                query += f" WHERE {' AND '.join(where_conditions)}"
    
    # Apply grouping
    if grouping:
        if "GROUP BY" not in query.upper():
            query += f" GROUP BY {', '.join(grouping)}"
    
    # Apply sorting
    if sorting:
        order_clauses = []
        for sort in sorting:
            direction = sort.get('direction', 'ASC').upper()
            field = sort.get('field')
            if field:
                order_clauses.append(f"{field} {direction}")
        
        if order_clauses:
            query += f" ORDER BY {', '.join(order_clauses)}"
    
    return query

def analyze_query_complexity(sql: str) -> str:
    """Analyze SQL query complexity"""
    sql_lower = sql.lower()
    
    complexity_factors = 0
    if 'join' in sql_lower:
        complexity_factors += sql_lower.count('join')
    if 'subquery' in sql_lower or '(' in sql:
        complexity_factors += 2
    if 'group by' in sql_lower:
        complexity_factors += 1
    if 'order by' in sql_lower:
        complexity_factors += 1
    
    if complexity_factors <= 2:
        return "low"
    elif complexity_factors <= 5:
        return "medium"
    else:
        return "high"

def estimate_memory_usage(row_count: int) -> str:
    """Estimate memory usage based on row count"""
    if row_count < 1000:
        return "low"
    elif row_count < 10000:
        return "medium"
    else:
        return "high"

def is_cache_eligible(sql: str) -> bool:
    """Determine if query results are eligible for caching"""
    # Simple heuristic: cache if no time-sensitive functions
    time_functions = ['now()', 'current_timestamp', 'current_date']
    return not any(func in sql.lower() for func in time_functions)