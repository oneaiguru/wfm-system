"""
BDD-Based Reporting Endpoints
Implements 10 essential reporting scenarios based on BDD specifications
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, extract
import pandas as pd
import io
from pydantic import BaseModel, Field

from ....core.database import get_db
from ....models.schedule import Schedule, ScheduleShift, Shift
from ....models.personnel import Employee, Department, Organization
from ....models.database import (
    Agent, AgentStatusHistory, AgentLoginHistory, 
    ServiceGroupMetrics, AgentCallsData
)
from ....core.security import get_current_user
from ....v1.schemas.auth import User


router = APIRouter(prefix="/reporting", tags=["reporting"])


# Pydantic Models for Request/Response
class DateRangeFilter(BaseModel):
    """Common date range filter"""
    start_date: date = Field(..., description="Start date for the report")
    end_date: date = Field(..., description="End date for the report")
    
    def validate_dates(self):
        if self.start_date > self.end_date:
            raise ValueError("Start date must be before end date")
        if (self.end_date - self.start_date).days > 365:
            raise ValueError("Date range cannot exceed 365 days")


class EmployeeFilter(BaseModel):
    """Employee filtering options"""
    department_id: Optional[str] = None
    group_id: Optional[str] = None
    employee_ids: Optional[List[str]] = None
    include_inactive: bool = False


class ExportFormat(BaseModel):
    """Export format options"""
    format: str = Field("json", regex="^(json|csv|excel)$")
    include_summary: bool = True


class AttendanceReportRequest(BaseModel):
    """Request model for attendance report"""
    date_range: DateRangeFilter
    employee_filter: Optional[EmployeeFilter] = None
    detail_level: str = Field("daily", regex="^(daily|weekly|monthly)$")
    include_weekends: bool = True


class ScheduleAdherenceRequest(BaseModel):
    """Request model for schedule adherence report"""
    date_range: DateRangeFilter
    employee_filter: Optional[EmployeeFilter] = None
    interval_minutes: int = Field(15, ge=5, le=60)
    threshold_percentage: float = Field(80.0, ge=0, le=100)


class ProductivityReportRequest(BaseModel):
    """Request model for productivity report"""
    date_range: DateRangeFilter
    employee_filter: Optional[EmployeeFilter] = None
    metrics: List[str] = Field(
        default=["aht", "calls_handled", "ready_time"],
        description="Metrics to include in report"
    )


class DepartmentSummaryRequest(BaseModel):
    """Request model for department summary report"""
    date_range: DateRangeFilter
    department_ids: Optional[List[str]] = None
    include_subdepartments: bool = True
    comparison_period: Optional[str] = None  # previous_period, previous_year


# Helper Functions
def apply_employee_filters(query, filters: Optional[EmployeeFilter], employee_alias=None):
    """Apply employee filters to a query"""
    if not filters:
        return query
    
    if employee_alias:
        if filters.department_id:
            query = query.filter(employee_alias.department_id == filters.department_id)
        if not filters.include_inactive:
            query = query.filter(employee_alias.status == "active")
        if filters.employee_ids:
            query = query.filter(employee_alias.id.in_(filters.employee_ids))
    else:
        if filters.department_id:
            query = query.filter(Employee.department_id == filters.department_id)
        if not filters.include_inactive:
            query = query.filter(Employee.status == "active")
        if filters.employee_ids:
            query = query.filter(Employee.id.in_(filters.employee_ids))
    
    return query


def calculate_adherence_percentage(scheduled_minutes: int, actual_minutes: int) -> float:
    """Calculate schedule adherence percentage"""
    if scheduled_minutes == 0:
        return 100.0 if actual_minutes == 0 else 0.0
    
    deviation = abs(scheduled_minutes - actual_minutes)
    adherence = ((scheduled_minutes - deviation) / scheduled_minutes) * 100
    return max(0.0, min(100.0, adherence))


def generate_excel_response(data: pd.DataFrame, filename: str):
    """Generate Excel file response"""
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
        data.to_excel(writer, sheet_name='Report', index=False)
        
        # Get the xlsxwriter workbook and worksheet objects
        workbook = writer.book
        worksheet = writer.sheets['Report']
        
        # Add formatting
        header_format = workbook.add_format({
            'bold': True,
            'bg_color': '#4472C4',
            'font_color': 'white',
            'border': 1
        })
        
        # Write headers with formatting
        for col_num, value in enumerate(data.columns.values):
            worksheet.write(0, col_num, value, header_format)
    
    output.seek(0)
    return StreamingResponse(
        output,
        media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# 1. Employee Attendance Report
@router.post("/attendance", response_model=Dict[str, Any])
async def generate_attendance_report(
    request: AttendanceReportRequest,
    export_format: Optional[str] = Query("json", regex="^(json|csv|excel)$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate employee attendance report showing login/logout times, 
    work hours, and attendance patterns
    """
    request.date_range.validate_dates()
    
    # Query login history with employee information
    query = db.query(
        AgentLoginHistory,
        Agent,
        Employee
    ).join(
        Agent, AgentLoginHistory.agent_id == Agent.id
    ).join(
        Employee, Agent.id == Employee.id
    ).filter(
        and_(
            AgentLoginHistory.login_date >= request.date_range.start_date,
            AgentLoginHistory.login_date <= request.date_range.end_date
        )
    )
    
    # Apply employee filters
    query = apply_employee_filters(query, request.employee_filter, Employee)
    
    # Execute query
    attendance_data = query.all()
    
    # Process data
    report_data = []
    for login_history, agent, employee in attendance_data:
        report_data.append({
            "date": login_history.login_date.date(),
            "employee_id": employee.id,
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "employee_number": employee.employee_number,
            "department": employee.department.name if employee.department else "N/A",
            "login_time": login_history.login_date,
            "logout_time": login_history.logout_date,
            "duration_hours": login_history.duration / 3600000,  # Convert ms to hours
            "work_location": employee.work_location or "Office"
        })
    
    # Generate summary statistics
    df = pd.DataFrame(report_data)
    if not df.empty:
        summary = {
            "total_employees": df['employee_id'].nunique(),
            "average_hours_per_day": df.groupby('date')['duration_hours'].mean().mean(),
            "total_work_hours": df['duration_hours'].sum(),
            "attendance_by_department": df.groupby('department')['employee_id'].nunique().to_dict()
        }
    else:
        summary = {
            "total_employees": 0,
            "average_hours_per_day": 0,
            "total_work_hours": 0,
            "attendance_by_department": {}
        }
    
    # Handle export formats
    if export_format == "excel":
        return generate_excel_response(df, f"attendance_report_{datetime.now().strftime('%Y%m%d')}.xlsx")
    elif export_format == "csv":
        output = io.StringIO()
        df.to_csv(output, index=False)
        return StreamingResponse(
            io.BytesIO(output.getvalue().encode()),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=attendance_report_{datetime.now().strftime('%Y%m%d')}.csv"}
        )
    
    return {
        "report_type": "attendance",
        "period": {
            "start": request.date_range.start_date.isoformat(),
            "end": request.date_range.end_date.isoformat()
        },
        "summary": summary,
        "data": report_data[:1000]  # Limit JSON response
    }


# 2. Schedule Adherence Report
@router.post("/schedule-adherence", response_model=Dict[str, Any])
async def generate_schedule_adherence_report(
    request: ScheduleAdherenceRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate schedule adherence report comparing planned vs actual schedules
    """
    request.date_range.validate_dates()
    
    # Query scheduled shifts
    scheduled_query = db.query(
        ScheduleShift,
        Employee,
        Shift
    ).join(
        Employee, ScheduleShift.employee_id == Employee.id
    ).join(
        Shift, ScheduleShift.shift_id == Shift.id
    ).filter(
        and_(
            ScheduleShift.date >= request.date_range.start_date,
            ScheduleShift.date <= request.date_range.end_date,
            ScheduleShift.status.in_(["assigned", "confirmed"])
        )
    )
    
    scheduled_query = apply_employee_filters(scheduled_query, request.employee_filter, Employee)
    scheduled_shifts = scheduled_query.all()
    
    # Query actual work time
    actual_query = db.query(
        AgentStatusHistory,
        Agent,
        Employee
    ).join(
        Agent, AgentStatusHistory.agent_id == Agent.id
    ).join(
        Employee, Agent.id == Employee.id
    ).filter(
        and_(
            AgentStatusHistory.start_date >= request.date_range.start_date,
            AgentStatusHistory.start_date <= request.date_range.end_date,
            AgentStatusHistory.state_code.in_(["READY", "IN_CALL", "AFTER_CALL"])
        )
    )
    
    actual_query = apply_employee_filters(actual_query, request.employee_filter, Employee)
    actual_statuses = actual_query.all()
    
    # Process adherence data
    adherence_data = []
    employee_adherence = {}
    
    for shift, employee, shift_type in scheduled_shifts:
        scheduled_start = datetime.combine(shift.date, shift.start_time)
        scheduled_end = datetime.combine(shift.date, shift.end_time)
        scheduled_minutes = (scheduled_end - scheduled_start).total_seconds() / 60
        
        # Find actual work time for this employee on this date
        actual_minutes = 0
        for status, agent, emp in actual_statuses:
            if emp.id == employee.id and status.start_date.date() == shift.date:
                duration = (status.end_date - status.start_date).total_seconds() / 60
                actual_minutes += duration
        
        adherence_pct = calculate_adherence_percentage(scheduled_minutes, actual_minutes)
        
        adherence_data.append({
            "date": shift.date,
            "employee_id": employee.id,
            "employee_name": f"{employee.first_name} {employee.last_name}",
            "shift_name": shift_type.name,
            "scheduled_start": scheduled_start,
            "scheduled_end": scheduled_end,
            "scheduled_minutes": scheduled_minutes,
            "actual_minutes": actual_minutes,
            "adherence_percentage": adherence_pct,
            "deviation_minutes": actual_minutes - scheduled_minutes
        })
        
        # Track employee-level adherence
        if employee.id not in employee_adherence:
            employee_adherence[employee.id] = []
        employee_adherence[employee.id].append(adherence_pct)
    
    # Calculate summary
    df = pd.DataFrame(adherence_data)
    if not df.empty:
        summary = {
            "average_adherence": df['adherence_percentage'].mean(),
            "employees_above_threshold": len([e for e, vals in employee_adherence.items() 
                                            if sum(vals)/len(vals) >= request.threshold_percentage]),
            "total_employees": len(employee_adherence),
            "adherence_by_shift": df.groupby('shift_name')['adherence_percentage'].mean().to_dict()
        }
    else:
        summary = {
            "average_adherence": 0,
            "employees_above_threshold": 0,
            "total_employees": 0,
            "adherence_by_shift": {}
        }
    
    return {
        "report_type": "schedule_adherence",
        "period": {
            "start": request.date_range.start_date.isoformat(),
            "end": request.date_range.end_date.isoformat()
        },
        "threshold": request.threshold_percentage,
        "summary": summary,
        "data": adherence_data[:1000]
    }


# 3. Productivity Report
@router.post("/productivity", response_model=Dict[str, Any])
async def generate_productivity_report(
    request: ProductivityReportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate productivity report with AHT, calls handled, and efficiency metrics
    """
    request.date_range.validate_dates()
    
    # Query call data
    calls_query = db.query(
        AgentCallsData,
        Agent,
        Employee
    ).join(
        Agent, AgentCallsData.agent_id == Agent.id
    ).join(
        Employee, Agent.id == Employee.id
    ).filter(
        and_(
            AgentCallsData.start_call >= request.date_range.start_date,
            AgentCallsData.start_call <= request.date_range.end_date
        )
    )
    
    calls_query = apply_employee_filters(calls_query, request.employee_filter, Employee)
    call_data = calls_query.all()
    
    # Query status history for ready time
    status_query = db.query(
        AgentStatusHistory,
        Agent,
        Employee
    ).join(
        Agent, AgentStatusHistory.agent_id == Agent.id
    ).join(
        Employee, Agent.id == Employee.id
    ).filter(
        and_(
            AgentStatusHistory.start_date >= request.date_range.start_date,
            AgentStatusHistory.start_date <= request.date_range.end_date
        )
    )
    
    status_query = apply_employee_filters(status_query, request.employee_filter, Employee)
    status_data = status_query.all()
    
    # Process productivity metrics by employee
    employee_metrics = {}
    
    # Process calls
    for call, agent, employee in call_data:
        emp_id = employee.id
        if emp_id not in employee_metrics:
            employee_metrics[emp_id] = {
                "employee_id": emp_id,
                "employee_name": f"{employee.first_name} {employee.last_name}",
                "employee_number": employee.employee_number,
                "department": employee.department.name if employee.department else "N/A",
                "calls_handled": 0,
                "total_call_time": 0,
                "ready_time": 0,
                "logged_in_time": 0
            }
        
        employee_metrics[emp_id]["calls_handled"] += 1
        employee_metrics[emp_id]["total_call_time"] += call.duration
    
    # Process status time
    for status, agent, employee in status_data:
        emp_id = employee.id
        if emp_id not in employee_metrics:
            employee_metrics[emp_id] = {
                "employee_id": emp_id,
                "employee_name": f"{employee.first_name} {employee.last_name}",
                "employee_number": employee.employee_number,
                "department": employee.department.name if employee.department else "N/A",
                "calls_handled": 0,
                "total_call_time": 0,
                "ready_time": 0,
                "logged_in_time": 0
            }
        
        duration = (status.end_date - status.start_date).total_seconds() * 1000  # to ms
        employee_metrics[emp_id]["logged_in_time"] += duration
        
        if status.state_code in ["READY", "IN_CALL", "AFTER_CALL"]:
            employee_metrics[emp_id]["ready_time"] += duration
    
    # Calculate final metrics
    productivity_data = []
    for emp_id, metrics in employee_metrics.items():
        if metrics["calls_handled"] > 0:
            aht_seconds = (metrics["total_call_time"] / metrics["calls_handled"]) / 1000
        else:
            aht_seconds = 0
        
        if metrics["logged_in_time"] > 0:
            utilization = (metrics["ready_time"] / metrics["logged_in_time"]) * 100
        else:
            utilization = 0
        
        productivity_data.append({
            **metrics,
            "aht_seconds": aht_seconds,
            "utilization_percentage": utilization,
            "ready_hours": metrics["ready_time"] / 3600000,
            "logged_hours": metrics["logged_in_time"] / 3600000
        })
    
    # Generate summary
    df = pd.DataFrame(productivity_data)
    if not df.empty:
        summary = {
            "total_calls": df['calls_handled'].sum(),
            "average_aht": df['aht_seconds'].mean(),
            "average_utilization": df['utilization_percentage'].mean(),
            "top_performers": df.nlargest(5, 'calls_handled')[['employee_name', 'calls_handled']].to_dict('records')
        }
    else:
        summary = {
            "total_calls": 0,
            "average_aht": 0,
            "average_utilization": 0,
            "top_performers": []
        }
    
    return {
        "report_type": "productivity",
        "period": {
            "start": request.date_range.start_date.isoformat(),
            "end": request.date_range.end_date.isoformat()
        },
        "metrics_included": request.metrics,
        "summary": summary,
        "data": productivity_data[:1000]
    }


# 4. Department Summary Report
@router.post("/department-summary", response_model=Dict[str, Any])
async def generate_department_summary_report(
    request: DepartmentSummaryRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate department-level summary with headcount, productivity, and performance metrics
    """
    request.date_range.validate_dates()
    
    # Query departments
    dept_query = db.query(Department)
    if request.department_ids:
        dept_query = dept_query.filter(Department.id.in_(request.department_ids))
    departments = dept_query.all()
    
    department_summaries = []
    
    for dept in departments:
        # Get employee count
        employee_count = db.query(Employee).filter(
            and_(
                Employee.department_id == dept.id,
                Employee.status == "active"
            )
        ).count()
        
        # Get attendance data
        attendance = db.query(
            func.count(func.distinct(AgentLoginHistory.agent_id)).label('unique_logins'),
            func.avg(AgentLoginHistory.duration).label('avg_duration')
        ).join(
            Agent, AgentLoginHistory.agent_id == Agent.id
        ).join(
            Employee, Agent.id == Employee.id
        ).filter(
            and_(
                Employee.department_id == dept.id,
                AgentLoginHistory.login_date >= request.date_range.start_date,
                AgentLoginHistory.login_date <= request.date_range.end_date
            )
        ).first()
        
        # Get productivity metrics
        productivity = db.query(
            func.count(AgentCallsData.id).label('total_calls'),
            func.avg(AgentCallsData.duration).label('avg_call_duration')
        ).join(
            Agent, AgentCallsData.agent_id == Agent.id
        ).join(
            Employee, Agent.id == Employee.id
        ).filter(
            and_(
                Employee.department_id == dept.id,
                AgentCallsData.start_call >= request.date_range.start_date,
                AgentCallsData.start_call <= request.date_range.end_date
            )
        ).first()
        
        # Calculate schedule adherence
        scheduled_count = db.query(func.count(ScheduleShift.id)).join(
            Employee, ScheduleShift.employee_id == Employee.id
        ).filter(
            and_(
                Employee.department_id == dept.id,
                ScheduleShift.date >= request.date_range.start_date,
                ScheduleShift.date <= request.date_range.end_date
            )
        ).scalar()
        
        department_summaries.append({
            "department_id": dept.id,
            "department_name": dept.name,
            "active_employees": employee_count,
            "unique_logins": attendance.unique_logins or 0,
            "avg_work_hours": (attendance.avg_duration or 0) / 3600000,
            "total_calls_handled": productivity.total_calls or 0,
            "avg_call_duration_seconds": (productivity.avg_call_duration or 0) / 1000,
            "scheduled_shifts": scheduled_count,
            "cost_center": dept.cost_center if hasattr(dept, 'cost_center') else None
        })
    
    # Overall summary
    df = pd.DataFrame(department_summaries)
    if not df.empty:
        overall_summary = {
            "total_departments": len(department_summaries),
            "total_employees": df['active_employees'].sum(),
            "total_calls": df['total_calls_handled'].sum(),
            "avg_department_size": df['active_employees'].mean()
        }
    else:
        overall_summary = {
            "total_departments": 0,
            "total_employees": 0,
            "total_calls": 0,
            "avg_department_size": 0
        }
    
    return {
        "report_type": "department_summary",
        "period": {
            "start": request.date_range.start_date.isoformat(),
            "end": request.date_range.end_date.isoformat()
        },
        "include_subdepartments": request.include_subdepartments,
        "overall_summary": overall_summary,
        "departments": department_summaries
    }


# 5. Forecast Accuracy Report
@router.post("/forecast-accuracy", response_model=Dict[str, Any])
async def generate_forecast_accuracy_report(
    request: DateRangeFilter,
    group_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate forecast accuracy report comparing predicted vs actual metrics
    """
    request.validate_dates()
    
    # Query service group metrics (actual data)
    metrics_query = db.query(ServiceGroupMetrics).filter(
        and_(
            ServiceGroupMetrics.start_interval >= request.start_date,
            ServiceGroupMetrics.end_interval <= request.end_date
        )
    )
    
    if group_id:
        metrics_query = metrics_query.filter(ServiceGroupMetrics.group_id == group_id)
    
    actual_metrics = metrics_query.all()
    
    # For this example, we'll simulate forecast data
    # In production, this would query from forecast tables
    accuracy_data = []
    
    for metric in actual_metrics:
        # Simulate forecast (in production, join with forecast table)
        forecast_calls = metric.received_calls * 0.95  # 95% accuracy simulation
        
        if metric.received_calls > 0:
            accuracy_pct = (1 - abs(forecast_calls - metric.received_calls) / metric.received_calls) * 100
            mape = abs(forecast_calls - metric.received_calls) / metric.received_calls * 100
        else:
            accuracy_pct = 100 if forecast_calls == 0 else 0
            mape = 0
        
        accuracy_data.append({
            "interval_start": metric.start_interval,
            "interval_end": metric.end_interval,
            "group_id": metric.group_id,
            "forecast_calls": int(forecast_calls),
            "actual_calls": metric.received_calls,
            "accuracy_percentage": accuracy_pct,
            "mape": mape,
            "bias": forecast_calls - metric.received_calls
        })
    
    # Calculate summary metrics
    df = pd.DataFrame(accuracy_data)
    if not df.empty:
        summary = {
            "average_accuracy": df['accuracy_percentage'].mean(),
            "mape": df['mape'].mean(),
            "mean_bias": df['bias'].mean(),
            "intervals_analyzed": len(accuracy_data),
            "accuracy_by_hour": df.groupby(df['interval_start'].dt.hour)['accuracy_percentage'].mean().to_dict()
        }
    else:
        summary = {
            "average_accuracy": 0,
            "mape": 0,
            "mean_bias": 0,
            "intervals_analyzed": 0,
            "accuracy_by_hour": {}
        }
    
    return {
        "report_type": "forecast_accuracy",
        "period": {
            "start": request.start_date.isoformat(),
            "end": request.end_date.isoformat()
        },
        "summary": summary,
        "data": accuracy_data[:1000]
    }


# 6. Absence Analysis Report
@router.post("/absence-analysis", response_model=Dict[str, Any])
async def generate_absence_analysis_report(
    request: DateRangeFilter,
    department_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate absence analysis report showing patterns and trends
    """
    request.validate_dates()
    
    # Query scheduled shifts
    scheduled_query = db.query(
        ScheduleShift,
        Employee
    ).join(
        Employee, ScheduleShift.employee_id == Employee.id
    ).filter(
        and_(
            ScheduleShift.date >= request.start_date,
            ScheduleShift.date <= request.end_date
        )
    )
    
    if department_id:
        scheduled_query = scheduled_query.filter(Employee.department_id == department_id)
    
    scheduled = scheduled_query.all()
    
    # Query actual attendance
    actual_query = db.query(
        func.date(AgentLoginHistory.login_date).label('work_date'),
        Agent.id
    ).join(
        Agent, AgentLoginHistory.agent_id == Agent.id
    ).filter(
        and_(
            AgentLoginHistory.login_date >= request.start_date,
            AgentLoginHistory.login_date <= request.end_date
        )
    ).group_by(func.date(AgentLoginHistory.login_date), Agent.id)
    
    actual_attendance = {(row.work_date, row.id) for row in actual_query}
    
    # Analyze absences
    absence_data = []
    employee_absences = {}
    
    for shift, employee in scheduled:
        if (shift.date, employee.id) not in actual_attendance:
            # Employee was scheduled but didn't log in
            day_of_week = shift.date.strftime('%A')
            
            absence_data.append({
                "date": shift.date,
                "employee_id": employee.id,
                "employee_name": f"{employee.first_name} {employee.last_name}",
                "department": employee.department.name if employee.department else "N/A",
                "day_of_week": day_of_week,
                "shift_type": shift.shift.name if shift.shift else "Regular"
            })
            
            if employee.id not in employee_absences:
                employee_absences[employee.id] = 0
            employee_absences[employee.id] += 1
    
    # Calculate patterns
    df = pd.DataFrame(absence_data)
    if not df.empty:
        summary = {
            "total_absences": len(absence_data),
            "unique_employees": len(employee_absences),
            "absence_rate": (len(absence_data) / len(scheduled)) * 100 if scheduled else 0,
            "by_day_of_week": df['day_of_week'].value_counts().to_dict(),
            "by_department": df['department'].value_counts().to_dict(),
            "chronic_absentees": [
                {"employee_id": emp_id, "absence_count": count}
                for emp_id, count in employee_absences.items()
                if count >= 3
            ][:10]
        }
    else:
        summary = {
            "total_absences": 0,
            "unique_employees": 0,
            "absence_rate": 0,
            "by_day_of_week": {},
            "by_department": {},
            "chronic_absentees": []
        }
    
    return {
        "report_type": "absence_analysis",
        "period": {
            "start": request.start_date.isoformat(),
            "end": request.end_date.isoformat()
        },
        "summary": summary,
        "data": absence_data[:1000]
    }


# 7. Overtime Report
@router.get("/overtime", response_model=Dict[str, Any])
async def generate_overtime_report(
    start_date: date = Query(...),
    end_date: date = Query(...),
    overtime_threshold_hours: float = Query(8.0, description="Daily hours threshold for overtime"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate overtime report showing employees working beyond standard hours
    """
    # Query login history
    overtime_query = db.query(
        AgentLoginHistory,
        Agent,
        Employee
    ).join(
        Agent, AgentLoginHistory.agent_id == Agent.id
    ).join(
        Employee, Agent.id == Employee.id
    ).filter(
        and_(
            AgentLoginHistory.login_date >= start_date,
            AgentLoginHistory.logout_date <= end_date
        )
    )
    
    overtime_data = []
    employee_overtime = {}
    
    for login, agent, employee in overtime_query:
        work_hours = login.duration / 3600000  # Convert ms to hours
        
        if work_hours > overtime_threshold_hours:
            overtime_hours = work_hours - overtime_threshold_hours
            
            overtime_data.append({
                "date": login.login_date.date(),
                "employee_id": employee.id,
                "employee_name": f"{employee.first_name} {employee.last_name}",
                "employee_number": employee.employee_number,
                "department": employee.department.name if employee.department else "N/A",
                "regular_hours": overtime_threshold_hours,
                "overtime_hours": overtime_hours,
                "total_hours": work_hours,
                "overtime_cost": overtime_hours * (employee.hourly_rate * 1.5 if employee.hourly_rate else 0)
            })
            
            if employee.id not in employee_overtime:
                employee_overtime[employee.id] = {
                    "total_overtime": 0,
                    "occurrences": 0
                }
            employee_overtime[employee.id]["total_overtime"] += overtime_hours
            employee_overtime[employee.id]["occurrences"] += 1
    
    # Summary
    df = pd.DataFrame(overtime_data)
    if not df.empty:
        summary = {
            "total_overtime_hours": df['overtime_hours'].sum(),
            "total_overtime_cost": df['overtime_cost'].sum(),
            "employees_with_overtime": len(employee_overtime),
            "average_overtime_per_occurrence": df['overtime_hours'].mean(),
            "top_overtime_employees": sorted(
                [{"employee_id": k, **v} for k, v in employee_overtime.items()],
                key=lambda x: x["total_overtime"],
                reverse=True
            )[:5]
        }
    else:
        summary = {
            "total_overtime_hours": 0,
            "total_overtime_cost": 0,
            "employees_with_overtime": 0,
            "average_overtime_per_occurrence": 0,
            "top_overtime_employees": []
        }
    
    return {
        "report_type": "overtime",
        "period": {
            "start": start_date.isoformat(),
            "end": end_date.isoformat()
        },
        "overtime_threshold": overtime_threshold_hours,
        "summary": summary,
        "data": overtime_data[:1000]
    }


# 8. Cost Analysis Report
@router.post("/cost-analysis", response_model=Dict[str, Any])
async def generate_cost_analysis_report(
    request: DateRangeFilter,
    include_benefits: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate comprehensive cost analysis report
    """
    request.validate_dates()
    
    # Query work hours and calculate costs
    cost_query = db.query(
        Employee,
        func.sum(AgentLoginHistory.duration).label('total_duration')
    ).join(
        Agent, Employee.id == Agent.id
    ).join(
        AgentLoginHistory, Agent.id == AgentLoginHistory.agent_id
    ).filter(
        and_(
            AgentLoginHistory.login_date >= request.start_date,
            AgentLoginHistory.login_date <= request.end_date
        )
    ).group_by(Employee.id)
    
    cost_data = []
    department_costs = {}
    
    for employee, total_duration in cost_query:
        if total_duration:
            work_hours = total_duration / 3600000  # ms to hours
            
            # Calculate costs
            if employee.hourly_rate:
                base_cost = work_hours * employee.hourly_rate
            elif employee.salary:
                # Assume monthly salary, calculate hourly
                base_cost = (employee.salary / 160) * work_hours  # 160 hours/month
            else:
                base_cost = 0
            
            # Add benefits (estimated 30% of base)
            if include_benefits:
                benefits_cost = base_cost * 0.3
                total_cost = base_cost + benefits_cost
            else:
                benefits_cost = 0
                total_cost = base_cost
            
            cost_data.append({
                "employee_id": employee.id,
                "employee_name": f"{employee.first_name} {employee.last_name}",
                "department": employee.department.name if employee.department else "N/A",
                "work_hours": work_hours,
                "base_cost": base_cost,
                "benefits_cost": benefits_cost,
                "total_cost": total_cost,
                "cost_per_hour": total_cost / work_hours if work_hours > 0 else 0
            })
            
            # Aggregate by department
            dept_name = employee.department.name if employee.department else "N/A"
            if dept_name not in department_costs:
                department_costs[dept_name] = {
                    "total_cost": 0,
                    "total_hours": 0,
                    "employee_count": 0
                }
            department_costs[dept_name]["total_cost"] += total_cost
            department_costs[dept_name]["total_hours"] += work_hours
            department_costs[dept_name]["employee_count"] += 1
    
    # Calculate summary
    df = pd.DataFrame(cost_data)
    if not df.empty:
        summary = {
            "total_labor_cost": df['total_cost'].sum(),
            "total_work_hours": df['work_hours'].sum(),
            "average_cost_per_hour": df['cost_per_hour'].mean(),
            "cost_by_department": {
                dept: {
                    **data,
                    "average_cost_per_hour": data["total_cost"] / data["total_hours"] if data["total_hours"] > 0 else 0
                }
                for dept, data in department_costs.items()
            }
        }
    else:
        summary = {
            "total_labor_cost": 0,
            "total_work_hours": 0,
            "average_cost_per_hour": 0,
            "cost_by_department": {}
        }
    
    return {
        "report_type": "cost_analysis",
        "period": {
            "start": request.start_date.isoformat(),
            "end": request.end_date.isoformat()
        },
        "include_benefits": include_benefits,
        "summary": summary,
        "data": cost_data[:1000]
    }


# 9. Real-time Dashboard Metrics
@router.get("/realtime-metrics", response_model=Dict[str, Any])
async def get_realtime_metrics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get real-time metrics for operational dashboard
    """
    current_time = datetime.utcnow()
    fifteen_minutes_ago = current_time - timedelta(minutes=15)
    
    # Current agent statuses
    current_agents = db.query(
        AgentStatusHistory.state_code,
        func.count(func.distinct(AgentStatusHistory.agent_id)).label('count')
    ).filter(
        and_(
            AgentStatusHistory.start_date <= current_time,
            AgentStatusHistory.end_date >= current_time
        )
    ).group_by(AgentStatusHistory.state_code).all()
    
    status_breakdown = {status: count for status, count in current_agents}
    
    # Recent metrics
    recent_calls = db.query(
        func.count(AgentCallsData.id).label('call_count'),
        func.avg(AgentCallsData.duration).label('avg_duration')
    ).filter(
        AgentCallsData.start_call >= fifteen_minutes_ago
    ).first()
    
    # Service level (calls answered within 20 seconds)
    total_calls = db.query(func.count(AgentCallsData.id)).filter(
        AgentCallsData.start_call >= fifteen_minutes_ago
    ).scalar() or 0
    
    answered_in_20 = db.query(func.count(AgentCallsData.id)).filter(
        and_(
            AgentCallsData.start_call >= fifteen_minutes_ago,
            AgentCallsData.duration <= 20000  # 20 seconds in ms
        )
    ).scalar() or 0
    
    service_level = (answered_in_20 / total_calls * 100) if total_calls > 0 else 100
    
    return {
        "timestamp": current_time.isoformat(),
        "agent_status_breakdown": status_breakdown,
        "total_agents_logged_in": sum(status_breakdown.values()),
        "agents_available": status_breakdown.get("READY", 0),
        "agents_on_calls": status_breakdown.get("IN_CALL", 0),
        "recent_metrics": {
            "calls_last_15_min": recent_calls.call_count if recent_calls else 0,
            "avg_call_duration": (recent_calls.avg_duration / 1000) if recent_calls and recent_calls.avg_duration else 0,
            "service_level_pct": service_level
        },
        "alerts": []  # Would include any threshold breaches
    }


# 10. Custom Report Builder
@router.post("/custom", response_model=Dict[str, Any])
async def generate_custom_report(
    report_name: str,
    sql_query: str,
    parameters: Optional[Dict[str, Any]] = None,
    export_format: str = Query("json", regex="^(json|csv|excel)$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate custom report using SQL query (admin only)
    """
    # Check if user has admin role
    if "admin" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Admin access required for custom reports")
    
    # Basic SQL injection prevention
    forbidden_keywords = ["DROP", "DELETE", "UPDATE", "INSERT", "ALTER", "CREATE"]
    query_upper = sql_query.upper()
    for keyword in forbidden_keywords:
        if keyword in query_upper:
            raise HTTPException(status_code=400, detail=f"Forbidden SQL keyword: {keyword}")
    
    try:
        # Execute query with parameters
        if parameters:
            result = db.execute(sql_query, parameters)
        else:
            result = db.execute(sql_query)
        
        # Fetch results
        columns = result.keys()
        data = [dict(zip(columns, row)) for row in result.fetchall()]
        
        # Handle export formats
        if export_format != "json" and data:
            df = pd.DataFrame(data)
            
            if export_format == "excel":
                return generate_excel_response(
                    df, 
                    f"{report_name.replace(' ', '_')}_{datetime.now().strftime('%Y%m%d')}.xlsx"
                )
            elif export_format == "csv":
                output = io.StringIO()
                df.to_csv(output, index=False)
                return StreamingResponse(
                    io.BytesIO(output.getvalue().encode()),
                    media_type="text/csv",
                    headers={
                        "Content-Disposition": f"attachment; filename={report_name.replace(' ', '_')}_{datetime.now().strftime('%Y%m%d')}.csv"
                    }
                )
        
        return {
            "report_type": "custom",
            "report_name": report_name,
            "generated_at": datetime.utcnow().isoformat(),
            "row_count": len(data),
            "columns": list(columns),
            "data": data[:1000]  # Limit for JSON response
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Query execution failed: {str(e)}")


# Export all reports list endpoint
@router.get("/available-reports", response_model=List[Dict[str, str]])
async def list_available_reports(
    current_user: User = Depends(get_current_user)
):
    """
    List all available report types and their descriptions
    """
    return [
        {
            "endpoint": "/reporting/attendance",
            "name": "Employee Attendance Report",
            "description": "Shows login/logout times, work hours, and attendance patterns"
        },
        {
            "endpoint": "/reporting/schedule-adherence",
            "name": "Schedule Adherence Report",
            "description": "Compares planned vs actual schedules with adherence percentages"
        },
        {
            "endpoint": "/reporting/productivity",
            "name": "Productivity Report",
            "description": "Employee productivity metrics including AHT, calls handled, and utilization"
        },
        {
            "endpoint": "/reporting/department-summary",
            "name": "Department Summary Report",
            "description": "Department-level summaries with headcount and performance metrics"
        },
        {
            "endpoint": "/reporting/forecast-accuracy",
            "name": "Forecast Accuracy Report",
            "description": "Analyzes forecast accuracy with MAPE and bias calculations"
        },
        {
            "endpoint": "/reporting/absence-analysis",
            "name": "Absence Analysis Report",
            "description": "Identifies absence patterns and chronic absenteeism"
        },
        {
            "endpoint": "/reporting/overtime",
            "name": "Overtime Report",
            "description": "Tracks overtime hours and associated costs"
        },
        {
            "endpoint": "/reporting/cost-analysis",
            "name": "Cost Analysis Report",
            "description": "Comprehensive labor cost analysis by employee and department"
        },
        {
            "endpoint": "/reporting/realtime-metrics",
            "name": "Real-time Dashboard Metrics",
            "description": "Current operational metrics for live monitoring"
        },
        {
            "endpoint": "/reporting/custom",
            "name": "Custom Report Builder",
            "description": "Build custom reports with SQL queries (admin only)"
        }
    ]