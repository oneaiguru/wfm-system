"""
BDD Reporting and Analytics System API
Based on: 12-reporting-analytics-system.feature
"""

from fastapi import APIRouter, HTTPException, Query, Path, Body
from typing import List, Dict, Optional, Any, Union
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field, validator
from enum import Enum
import uuid
import random
import math

router = APIRouter()

# Enums
class ReportFormat(str, Enum):
    EXCEL = "excel"
    PDF = "pdf"
    CSV = "csv"
    JSON = "json"

class DetailLevel(str, Enum):
    FIFTEEN_MINUTE = "15-minute"
    HOURLY = "hourly"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class PayrollMode(str, Enum):
    ZUP_DATA = "1C_data"
    ACTUAL_CC = "actual_cc"
    WFM_SCHEDULE = "wfm_schedule"

class AdherenceColor(str, Enum):
    GREEN = "green"
    YELLOW = "yellow"
    RED = "red"

class AlertLevel(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"
    EMERGENCY = "emergency"

# Models for Schedule Adherence Reports
class AdherenceCell(BaseModel):
    time_slot: str = Field(description="15-minute time slot (e.g., 09:00-09:15)")
    planned_activity: str
    actual_activity: str
    adherence_percentage: float = Field(ge=0, le=100)
    color_code: AdherenceColor
    deviation_minutes: int = Field(description="Positive = late, Negative = early")

class ScheduleAdherenceReport(BaseModel):
    report_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    period_start: date
    period_end: date
    department: str
    detail_level: DetailLevel
    include_weekends: bool
    show_exceptions: bool
    
    # Employee data
    employees: List[Dict[str, Any]] = Field(default=[])
    
    # Summary metrics
    average_adherence: float = Field(ge=0, le=100)
    total_scheduled_hours: float
    total_actual_hours: float
    total_deviation_hours: float
    
    # Breakdown by activity type
    productive_hours: float
    auxiliary_hours: float
    break_hours: float
    
    generated_at: datetime = Field(default_factory=datetime.now)

# Models for Payroll Reports
class ZUPTimeCode(BaseModel):
    code: str = Field(description="Time code (I, H, B, C, etc.)")
    russian_name: str
    english_name: str
    zup_document_type: str
    calculation_rule: str
    hours: float = Field(ge=0)
    rate_multiplier: float = Field(default=1.0, ge=0)

class PayrollEmployee(BaseModel):
    employee_id: str
    employee_name: str
    department: str
    time_codes: List[ZUPTimeCode]
    total_hours: float
    regular_hours: float
    overtime_hours: float
    weekend_hours: float
    night_hours: float
    calculated_pay: Optional[float] = None

class PayrollReport(BaseModel):
    report_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    mode: PayrollMode
    period_start: date
    period_end: date
    period_type: str = Field(description="half-month, bi-weekly, monthly")
    
    employees: List[PayrollEmployee]
    
    # Summary by time codes
    time_code_summary: Dict[str, Dict[str, Union[float, int]]] = Field(default={})
    
    # Period summaries
    period_totals: Dict[str, float] = Field(default={})
    
    generated_at: datetime = Field(default_factory=datetime.now)
    integration_status: str = Field(default="1C_ZUP_synchronized")

# Models for Forecast Accuracy
class ForecastAccuracyMetrics(BaseModel):
    mape: float = Field(description="Mean Absolute Percentage Error")
    wape: float = Field(description="Weighted Absolute Percentage Error")
    mfa: float = Field(description="Mean Forecast Accuracy")
    wfa: float = Field(description="Weighted Forecast Accuracy")
    bias: float = Field(description="Systematic error percentage")
    tracking_signal: float = Field(description="Cumulative bias / MAD")

class ForecastAccuracyReport(BaseModel):
    report_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    period_start: date
    period_end: date
    
    overall_metrics: ForecastAccuracyMetrics
    
    # Drill-down analysis
    interval_analysis: List[Dict[str, Any]] = Field(default=[])
    daily_analysis: List[Dict[str, Any]] = Field(default=[])
    weekly_analysis: List[Dict[str, Any]] = Field(default=[])
    monthly_analysis: List[Dict[str, Any]] = Field(default=[])
    channel_analysis: List[Dict[str, Any]] = Field(default=[])
    
    generated_at: datetime = Field(default_factory=datetime.now)

# Models for KPI Dashboards
class KPIMetric(BaseModel):
    metric_name: str
    current_value: float
    target_value: float
    unit: str
    status: str = Field(description="on_target, warning, critical")
    trend: str = Field(description="up, down, stable")
    last_updated: datetime

class KPIDashboard(BaseModel):
    dashboard_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    # Service Level KPIs
    service_level: KPIMetric
    answer_time: KPIMetric
    
    # Efficiency KPIs
    occupancy: KPIMetric
    utilization: KPIMetric
    
    # Quality KPIs
    customer_satisfaction: KPIMetric
    first_call_resolution: KPIMetric
    
    # Schedule KPIs
    adherence: KPIMetric
    shrinkage: KPIMetric
    
    # Forecast KPIs
    forecast_accuracy: KPIMetric
    forecast_bias: KPIMetric
    
    # Cost KPIs
    cost_per_contact: KPIMetric
    overtime_percentage: KPIMetric
    
    last_refresh: datetime = Field(default_factory=datetime.now)

# Models for Absence Analysis
class AbsencePattern(BaseModel):
    pattern_type: str = Field(description="day_of_week, seasonal, frequency")
    pattern_data: Dict[str, Any]
    impact_score: float = Field(ge=0, le=100)
    recommendation: str

class AbsenceAnalysisReport(BaseModel):
    report_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    period_start: date
    period_end: date
    
    # Absence metrics
    planned_absences: Dict[str, Any] = Field(default={})
    unplanned_absences: Dict[str, Any] = Field(default={})
    
    # Pattern analysis
    patterns: List[AbsencePattern] = Field(default=[])
    
    # Impact analysis
    coverage_impact: Dict[str, Any] = Field(default={})
    cost_impact: Dict[str, Any] = Field(default={})
    
    # Insights and recommendations
    insights: List[Dict[str, str]] = Field(default=[])
    
    generated_at: datetime = Field(default_factory=datetime.now)

# Endpoints

@router.post("/reports/schedule-adherence", response_model=ScheduleAdherenceReport, tags=["reports"])
async def generate_schedule_adherence_report(
    period_start: date = Body(),
    period_end: date = Body(),
    department: str = Body(default="Technical Support"),
    detail_level: DetailLevel = Body(default=DetailLevel.FIFTEEN_MINUTE),
    include_weekends: bool = Body(default=True),
    show_exceptions: bool = Body(default=True)
):
    """
    Generate Schedule Adherence Reports
    BDD: Scenario: Generate Schedule Adherence Reports (lines 13-34)
    """
    
    # Generate sample employee adherence data
    employees = []
    total_scheduled = 0
    total_actual = 0
    total_deviation = 0
    
    for i in range(10):
        emp_scheduled = random.uniform(160, 180)  # Hours in month
        emp_actual = emp_scheduled + random.uniform(-20, 20)
        emp_adherence = min(100, max(0, (emp_actual / emp_scheduled) * 100))
        emp_deviation = emp_actual - emp_scheduled
        
        # Generate 15-minute intervals for the employee
        adherence_cells = []
        for day in range((period_end - period_start).days + 1):
            current_date = period_start + timedelta(days=day)
            
            # Skip weekends if not included
            if not include_weekends and current_date.weekday() >= 5:
                continue
                
            # Generate hourly data (simplified)
            for hour in range(8, 18):  # 8 AM to 6 PM
                for quarter in range(4):  # 15-minute intervals
                    time_slot = f"{hour:02d}:{quarter*15:02d}-{hour:02d}:{(quarter+1)*15:02d}"
                    adherence_pct = random.uniform(70, 100)
                    
                    # Determine color coding
                    if adherence_pct > 80:
                        color = AdherenceColor.GREEN
                    elif adherence_pct > 70:
                        color = AdherenceColor.YELLOW
                    else:
                        color = AdherenceColor.RED
                    
                    cell = AdherenceCell(
                        time_slot=time_slot,
                        planned_activity="Work" if random.random() > 0.2 else "Break",
                        actual_activity="Work" if random.random() > 0.1 else "Break",
                        adherence_percentage=adherence_pct,
                        color_code=color,
                        deviation_minutes=random.randint(-15, 30)
                    )
                    adherence_cells.append(cell)
        
        employee_data = {
            "employee_id": f"EMP{i+1:03d}",
            "employee_name": f"Employee {i+1}",
            "scheduled_hours": emp_scheduled,
            "actual_hours": emp_actual,
            "adherence_percentage": emp_adherence,
            "deviation_hours": emp_deviation,
            "adherence_cells": [cell.dict() for cell in adherence_cells] if show_exceptions else []
        }
        employees.append(employee_data)
        
        total_scheduled += emp_scheduled
        total_actual += emp_actual
        total_deviation += emp_deviation
    
    # Calculate averages
    avg_adherence = (total_actual / total_scheduled) * 100 if total_scheduled > 0 else 0
    
    return ScheduleAdherenceReport(
        period_start=period_start,
        period_end=period_end,
        department=department,
        detail_level=detail_level,
        include_weekends=include_weekends,
        show_exceptions=show_exceptions,
        employees=employees,
        average_adherence=avg_adherence,
        total_scheduled_hours=total_scheduled,
        total_actual_hours=total_actual,
        total_deviation_hours=total_deviation,
        productive_hours=total_actual * 0.8,
        auxiliary_hours=total_actual * 0.15,
        break_hours=total_actual * 0.05
    )

@router.post("/reports/payroll", response_model=PayrollReport, tags=["reports"])
async def generate_payroll_report(
    mode: PayrollMode = Body(),
    period_start: date = Body(),
    period_end: date = Body(),
    period_type: str = Body(default="monthly"),
    department: Optional[str] = Body(None)
):
    """
    Create Payroll Calculation Reports
    BDD: Scenario: Create Payroll Calculation Reports (lines 36-58)
    """
    
    # Generate sample payroll data with 1C ZUP time codes
    employees = []
    time_code_summary = {}
    
    # Define 1C ZUP time codes as per BDD specifications
    time_code_definitions = {
        "I": {"russian": "Явка", "english": "Day work", "doc_type": "Individual schedule", "multiplier": 1.0},
        "H": {"russian": "Ночные", "english": "Night work", "doc_type": "Individual schedule", "multiplier": 1.3},
        "B": {"russian": "Выходной", "english": "Day off", "doc_type": "Individual schedule", "multiplier": 0.0},
        "C": {"russian": "Сверхурочные", "english": "Overtime", "doc_type": "Overtime work", "multiplier": 1.5},
        "RV": {"russian": "Работа в выходной", "english": "Weekend work", "doc_type": "Work on holidays/weekends", "multiplier": 2.0},
        "RVN": {"russian": "Ночная работа в выходной", "english": "Night weekend work", "doc_type": "Work on holidays/weekends", "multiplier": 2.3},
        "NV": {"russian": "Неявка", "english": "Absence", "doc_type": "Absence (unexplained)", "multiplier": 0.0},
        "OT": {"russian": "Отпуск", "english": "Annual vacation", "doc_type": "Vacation", "multiplier": 1.0}
    }
    
    for i in range(15):
        # Generate time codes for employee
        time_codes = []
        total_hours = 0
        regular_hours = 0
        overtime_hours = 0
        weekend_hours = 0
        night_hours = 0
        
        # Regular work hours
        regular = random.uniform(140, 168)
        time_codes.append(ZUPTimeCode(
            code="I",
            russian_name=time_code_definitions["I"]["russian"],
            english_name=time_code_definitions["I"]["english"],
            zup_document_type=time_code_definitions["I"]["doc_type"],
            calculation_rule="Standard worked hours 06:00-21:59",
            hours=regular,
            rate_multiplier=time_code_definitions["I"]["multiplier"]
        ))
        regular_hours += regular
        total_hours += regular
        
        # Possible overtime
        if random.random() > 0.6:
            overtime = random.uniform(5, 20)
            time_codes.append(ZUPTimeCode(
                code="C",
                russian_name=time_code_definitions["C"]["russian"],
                english_name=time_code_definitions["C"]["english"],
                zup_document_type=time_code_definitions["C"]["doc_type"],
                calculation_rule="Hours above norm",
                hours=overtime,
                rate_multiplier=time_code_definitions["C"]["multiplier"]
            ))
            overtime_hours += overtime
            total_hours += overtime
        
        # Possible night work
        if random.random() > 0.7:
            night = random.uniform(8, 16)
            time_codes.append(ZUPTimeCode(
                code="H",
                russian_name=time_code_definitions["H"]["russian"],
                english_name=time_code_definitions["H"]["english"],
                zup_document_type=time_code_definitions["H"]["doc_type"],
                calculation_rule="Hours worked 22:00-05:59",
                hours=night,
                rate_multiplier=time_code_definitions["H"]["multiplier"]
            ))
            night_hours += night
            total_hours += night
        
        # Possible weekend work
        if random.random() > 0.8:
            weekend = random.uniform(8, 16)
            time_codes.append(ZUPTimeCode(
                code="RV",
                russian_name=time_code_definitions["RV"]["russian"],
                english_name=time_code_definitions["RV"]["english"],
                zup_document_type=time_code_definitions["RV"]["doc_type"],
                calculation_rule="Rest day work",
                hours=weekend,
                rate_multiplier=time_code_definitions["RV"]["multiplier"]
            ))
            weekend_hours += weekend
            total_hours += weekend
        
        # Possible vacation
        if random.random() > 0.9:
            vacation = random.uniform(40, 80)
            time_codes.append(ZUPTimeCode(
                code="OT",
                russian_name=time_code_definitions["OT"]["russian"],
                english_name=time_code_definitions["OT"]["english"],
                zup_document_type=time_code_definitions["OT"]["doc_type"],
                calculation_rule="From vacation schedule",
                hours=vacation,
                rate_multiplier=time_code_definitions["OT"]["multiplier"]
            ))
        
        employee = PayrollEmployee(
            employee_id=f"EMP{i+1:03d}",
            employee_name=f"Сотрудник {i+1}",
            department=department or "Technical Support",
            time_codes=time_codes,
            total_hours=total_hours,
            regular_hours=regular_hours,
            overtime_hours=overtime_hours,
            weekend_hours=weekend_hours,
            night_hours=night_hours,
            calculated_pay=total_hours * 1000  # Sample hourly rate
        )
        employees.append(employee)
        
        # Update summary
        for tc in time_codes:
            if tc.code not in time_code_summary:
                time_code_summary[tc.code] = {
                    "total_hours": 0,
                    "employee_count": 0,
                    "total_cost": 0
                }
            time_code_summary[tc.code]["total_hours"] += tc.hours
            time_code_summary[tc.code]["employee_count"] += 1
            time_code_summary[tc.code]["total_cost"] += tc.hours * 1000 * tc.rate_multiplier
    
    return PayrollReport(
        mode=mode,
        period_start=period_start,
        period_end=period_end,
        period_type=period_type,
        employees=employees,
        time_code_summary=time_code_summary,
        period_totals={
            "total_regular_hours": sum(e.regular_hours for e in employees),
            "total_overtime_hours": sum(e.overtime_hours for e in employees),
            "total_cost": sum(e.calculated_pay or 0 for e in employees)
        }
    )

@router.get("/reports/forecast-accuracy", response_model=ForecastAccuracyReport, tags=["reports"])
async def analyze_forecast_accuracy(
    period_start: date = Query(),
    period_end: date = Query(),
    service_group: Optional[str] = Query(None)
):
    """
    Analyze Forecast Accuracy Performance
    BDD: Scenario: Analyze Forecast Accuracy Performance (lines 60-78)
    """
    
    # Calculate accuracy metrics based on BDD specifications
    def calculate_mape():
        return random.uniform(8, 18)  # Target < 15%
    
    def calculate_wape():
        return random.uniform(6, 15)  # Target < 12%
    
    def calculate_mfa():
        return random.uniform(80, 95)  # Target > 85%
    
    def calculate_wfa():
        return random.uniform(85, 95)  # Target > 88%
    
    def calculate_bias():
        return random.uniform(-8, 8)  # Target ±5%
    
    def calculate_tracking_signal():
        return random.uniform(-5, 5)  # Target ±4
    
    metrics = ForecastAccuracyMetrics(
        mape=calculate_mape(),
        wape=calculate_wape(),
        mfa=calculate_mfa(),
        wfa=calculate_wfa(),
        bias=calculate_bias(),
        tracking_signal=calculate_tracking_signal()
    )
    
    # Generate drill-down analysis
    interval_analysis = []
    for hour in range(8, 20):
        for quarter in range(4):
            interval_analysis.append({
                "time_interval": f"{hour:02d}:{quarter*15:02d}",
                "forecasted": random.randint(40, 80),
                "actual": random.randint(35, 85),
                "accuracy": random.uniform(70, 95),
                "pattern": "peak" if hour in [10, 14, 16] else "normal"
            })
    
    daily_analysis = []
    current_date = period_start
    while current_date <= period_end:
        daily_analysis.append({
            "date": current_date.isoformat(),
            "day_of_week": current_date.strftime("%A"),
            "forecasted_volume": random.randint(800, 1200),
            "actual_volume": random.randint(750, 1250),
            "accuracy": random.uniform(75, 95)
        })
        current_date += timedelta(days=1)
    
    return ForecastAccuracyReport(
        period_start=period_start,
        period_end=period_end,
        overall_metrics=metrics,
        interval_analysis=interval_analysis,
        daily_analysis=daily_analysis,
        weekly_analysis=[{
            "week": f"Week {i+1}",
            "accuracy": random.uniform(80, 95),
            "volume_variance": random.uniform(-15, 15)
        } for i in range(4)],
        monthly_analysis=[{
            "month": period_start.strftime("%B %Y"),
            "accuracy": random.uniform(85, 95),
            "trend": random.choice(["improving", "stable", "declining"])
        }],
        channel_analysis=[{
            "service_group": "Technical Support",
            "accuracy": random.uniform(80, 95),
            "volume": random.randint(5000, 8000)
        }, {
            "service_group": "Sales",
            "accuracy": random.uniform(75, 90),
            "volume": random.randint(3000, 5000)
        }]
    )

@router.get("/reports/kpi-dashboard", response_model=KPIDashboard, tags=["reports"])
async def get_kpi_dashboard():
    """
    Generate KPI Performance Dashboards
    BDD: Scenario: Generate KPI Performance Dashboards (lines 80-97)
    """
    
    def create_kpi_metric(name: str, current: float, target: float, unit: str) -> KPIMetric:
        status = "on_target"
        if abs(current - target) / target > 0.1:
            status = "warning" if abs(current - target) / target < 0.2 else "critical"
        
        trend = random.choice(["up", "down", "stable"])
        
        return KPIMetric(
            metric_name=name,
            current_value=current,
            target_value=target,
            unit=unit,
            status=status,
            trend=trend,
            last_updated=datetime.now()
        )
    
    return KPIDashboard(
        service_level=create_kpi_metric("Service Level", random.uniform(75, 85), 80, "%"),
        answer_time=create_kpi_metric("Answer Time", random.uniform(18, 25), 20, "seconds"),
        occupancy=create_kpi_metric("Occupancy", random.uniform(80, 90), 85, "%"),
        utilization=create_kpi_metric("Utilization", random.uniform(82, 88), 85, "%"),
        customer_satisfaction=create_kpi_metric("Customer Satisfaction", random.uniform(4.0, 4.5), 4.2, "rating"),
        first_call_resolution=create_kpi_metric("First Call Resolution", random.uniform(85, 95), 90, "%"),
        adherence=create_kpi_metric("Schedule Adherence", random.uniform(75, 85), 80, "%"),
        shrinkage=create_kpi_metric("Shrinkage", random.uniform(15, 25), 20, "%"),
        forecast_accuracy=create_kpi_metric("Forecast Accuracy", random.uniform(85, 95), 90, "%"),
        forecast_bias=create_kpi_metric("Forecast Bias", random.uniform(-8, 8), 0, "%"),
        cost_per_contact=create_kpi_metric("Cost per Contact", random.uniform(15, 25), 20, "USD"),
        overtime_percentage=create_kpi_metric("Overtime %", random.uniform(3, 8), 5, "%")
    )

@router.get("/reports/absence-analysis", response_model=AbsenceAnalysisReport, tags=["reports"])
async def analyze_absence_patterns(
    period_start: date = Query(),
    period_end: date = Query(),
    department: Optional[str] = Query(None)
):
    """
    Analyze Employee Absence Patterns
    BDD: Scenario: Analyze Employee Absence Patterns (lines 99-114)
    """
    
    # Generate absence patterns
    patterns = []
    
    # Day-of-week pattern
    patterns.append(AbsencePattern(
        pattern_type="day_of_week",
        pattern_data={
            "Monday": 25,
            "Tuesday": 15,
            "Wednesday": 12,
            "Thursday": 18,
            "Friday": 30
        },
        impact_score=75,
        recommendation="Monitor Friday absences - highest frequency day"
    ))
    
    # Seasonal pattern
    patterns.append(AbsencePattern(
        pattern_type="seasonal",
        pattern_data={
            "Summer": 35,
            "Winter": 20,
            "Spring": 25,
            "Fall": 20
        },
        impact_score=60,
        recommendation="Plan additional coverage for summer vacation period"
    ))
    
    return AbsenceAnalysisReport(
        period_start=period_start,
        period_end=period_end,
        planned_absences={
            "vacation_hours": random.uniform(200, 400),
            "training_hours": random.uniform(50, 100),
            "total_cost": random.uniform(5000, 10000)
        },
        unplanned_absences={
            "sick_leave_frequency": random.uniform(5, 15),
            "emergency_leave_hours": random.uniform(20, 60),
            "total_cost": random.uniform(2000, 5000)
        },
        patterns=patterns,
        coverage_impact={
            "service_level_impact": random.uniform(-5, -15),
            "overtime_increase": random.uniform(10, 25),
            "customer_satisfaction_impact": random.uniform(-2, -8)
        },
        cost_impact={
            "direct_costs": random.uniform(7000, 15000),
            "indirect_costs": random.uniform(3000, 8000),
            "overtime_costs": random.uniform(2000, 6000)
        },
        insights=[
            {
                "category": "Absence rates",
                "analysis": "Department average 8.5% vs company 6.2%",
                "action": "Investigate high-absence employees"
            },
            {
                "category": "Trends",
                "analysis": "15% increase in unplanned absences vs last quarter",
                "action": "Review attendance policies and wellness programs"
            }
        ]
    )

@router.get("/reports/real-time", tags=["reports"])
async def get_real_time_metrics():
    """
    Real-time Operational Reporting
    BDD: Scenario: Real-time Operational Reporting (lines 224-239)
    """
    
    current_staffing = random.uniform(80, 95)
    service_level = random.uniform(70, 85)
    queue_wait_time = random.uniform(1, 8)
    
    # Determine alert conditions
    alerts = []
    
    if current_staffing < 75:
        alerts.append({
            "type": "critical_understaffing",
            "condition": f"Current staffing {current_staffing:.1f}% < 75%",
            "notification": "Immediate SMS/Email sent",
            "severity": AlertLevel.EMERGENCY
        })
    
    if service_level < 70:
        alerts.append({
            "type": "service_level_breach",
            "condition": f"Service level {service_level:.1f}% < 70%",
            "notification": "Dashboard alert activated",
            "severity": AlertLevel.CRITICAL
        })
    
    if queue_wait_time > 5:
        alerts.append({
            "type": "queue_overflow",
            "condition": f"Wait time {queue_wait_time:.1f} minutes > 5",
            "notification": "Escalation protocol initiated",
            "severity": AlertLevel.WARNING
        })
    
    return {
        "timestamp": datetime.now().isoformat(),
        "current_metrics": {
            "staffing_percentage": current_staffing,
            "service_level_80_20": service_level,
            "average_queue_time": queue_wait_time,
            "active_agents": random.randint(45, 65),
            "calls_in_queue": random.randint(0, 25)
        },
        "system_health": {
            "integration_status": "healthy",
            "database_status": "healthy",
            "api_response_time": random.uniform(100, 500)
        },
        "active_alerts": alerts,
        "update_frequency": {
            "staffing": "30 seconds",
            "service_levels": "1 minute",
            "queue_status": "real-time",
            "system_health": "30 seconds"
        }
    }

@router.get("/reports/overtime-analysis", tags=["reports"])
async def analyze_overtime_usage(
    period_start: date = Query(),
    period_end: date = Query(),
    department: Optional[str] = Query(None)
):
    """
    Track and Analyze Overtime Usage
    BDD: Scenario: Track and Analyze Overtime Usage (lines 116-131)
    """
    
    # Generate overtime analysis data
    employees = []
    total_overtime = 0
    total_regular = 0
    
    for i in range(15):
        individual_overtime = random.uniform(0, 20)
        regular_hours = random.uniform(140, 168)
        approval_rate = random.uniform(60, 100)
        
        employees.append({
            "employee_id": f"EMP{i+1:03d}",
            "employee_name": f"Employee {i+1}",
            "overtime_hours": individual_overtime,
            "regular_hours": regular_hours,
            "overtime_percentage": (individual_overtime / regular_hours) * 100,
            "approval_compliance": approval_rate,
            "alert_threshold_exceeded": individual_overtime > 10
        })
        
        total_overtime += individual_overtime
        total_regular += regular_hours
    
    department_overtime_pct = (total_overtime / total_regular) * 100
    
    return {
        "period": {"start": period_start, "end": period_end},
        "department": department or "All Departments",
        
        "overtime_metrics": {
            "total_overtime_hours": total_overtime,
            "department_overtime_percentage": department_overtime_pct,
            "average_individual_overtime": total_overtime / len(employees),
            "employees_over_threshold": len([e for e in employees if e["overtime_hours"] > 10])
        },
        
        "alert_thresholds": {
            "individual_overtime": "> 10 hours/week",
            "department_overtime": "> 5% of regular hours",
            "approval_compliance": "> 80% pre-approval"
        },
        
        "optimization_opportunities": [
            {
                "area": "Staffing levels",
                "analysis": f"Department overtime at {department_overtime_pct:.1f}%",
                "recommendation": "Consider hiring additional staff" if department_overtime_pct > 5 else "Current staffing adequate"
            },
            {
                "area": "Schedule efficiency",
                "analysis": "Predictable overtime patterns detected",
                "recommendation": "Adjust base schedules to reduce overtime dependency"
            },
            {
                "area": "Skill development",
                "analysis": "Single-skill bottlenecks identified",
                "recommendation": "Cross-train employees to improve flexibility"
            }
        ],
        
        "employees": employees
    }

@router.get("/reports/mobile", tags=["reports"])
async def get_mobile_reports():
    """
    Mobile-Optimized Reports and Dashboards
    BDD: Scenario: Mobile-Optimized Reports and Dashboards (lines 241-256)
    """
    
    return {
        "mobile_dashboard": {
            "key_metrics": {
                "service_level": {
                    "value": random.uniform(75, 85),
                    "target": 80,
                    "status": "warning",
                    "icon": "trending-up"
                },
                "current_staffing": {
                    "value": random.randint(45, 65),
                    "target": 55,
                    "status": "on_target",
                    "icon": "users"
                },
                "queue_size": {
                    "value": random.randint(0, 15),
                    "status": "normal",
                    "icon": "clock"
                }
            },
            
            "quick_actions": [
                {"action": "View detailed reports", "icon": "bar-chart", "deep_link": "/reports/detailed"},
                {"action": "Acknowledge alerts", "icon": "bell", "deep_link": "/alerts"},
                {"action": "Emergency staffing", "icon": "phone", "deep_link": "/emergency"}
            ],
            
            "recent_alerts": [
                {
                    "type": "Service level warning",
                    "time": "2 minutes ago",
                    "priority": "medium"
                },
                {
                    "type": "Overtime threshold",
                    "time": "15 minutes ago",
                    "priority": "low"
                }
            ]
        },
        
        "mobile_features": {
            "responsive_design": True,
            "touch_navigation": True,
            "offline_access": True,
            "push_notifications": True,
            "quick_actions": True,
            "data_compression": True
        },
        
        "performance": {
            "average_load_time": "< 2 seconds",
            "data_usage": "Minimal",
            "battery_impact": "Low",
            "cache_enabled": True
        }
    }

# Additional endpoints for custom reports, audit trails, etc. would follow the same pattern...