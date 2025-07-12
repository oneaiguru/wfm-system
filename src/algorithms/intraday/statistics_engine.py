#!/usr/bin/env python3
"""
Statistics Engine for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Enhanced Working Days, Planned Hours, Overtime, Absence, Productivity
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta, time, date
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import calendar

logger = logging.getLogger(__name__)

class CalculationMethod(Enum):
    """Methods for statistical calculations"""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    CUSTOM_PERIOD = "custom_period"

class AbsenceType(Enum):
    """Types of absences"""
    VACATION = "vacation"
    SICK_LEAVE = "sick_leave"
    PERSONAL_TIME = "personal_time"
    FMLA = "fmla"
    EMERGENCY_LEAVE = "emergency_leave"
    TRAINING = "training"  # Counts as working

@dataclass
class WorkingDaysCalculation:
    """Working days calculation result"""
    period: CalculationMethod
    start_date: date
    end_date: date
    total_calendar_days: int
    weekends: int
    holidays: int
    vacation_days: int
    sick_days: int
    other_absences: int
    scheduled_working_days: int
    actual_working_days: int
    utilization_rate: float

@dataclass
class PlannedHoursCalculation:
    """Planned hours calculation excluding breaks"""
    employee_id: str
    date: date
    gross_hours: float  # End time - Start time
    break_hours: float  # All breaks
    net_hours: float    # Gross - breaks
    paid_hours: float   # Net + paid breaks
    productive_hours: float  # Net - downtime
    overtime_hours: float
    details: Dict[str, float]

@dataclass
class OvertimeAnalysis:
    """Overtime detection and analysis"""
    employee_id: str
    period: Tuple[date, date]
    daily_overtime: Dict[date, float]
    weekly_overtime: Dict[int, float]  # week number -> hours
    holiday_overtime: float
    weekend_overtime: float
    emergency_overtime: float
    total_overtime: float
    overtime_cost: float
    compliance_status: str

@dataclass
class AbsenceAnalysis:
    """Absence rate calculation and analysis"""
    period: Tuple[date, date]
    employee_count: int
    absence_rate: float
    unplanned_absence_rate: float
    sick_leave_rate: float
    vacation_usage_rate: float
    absence_patterns: Dict[str, Any]
    high_absence_employees: List[str]
    department_trends: Dict[str, float]

@dataclass
class ProductivityMetrics:
    """Productivity standard tracking"""
    employee_id: str
    period: Tuple[date, date]
    calls_per_hour: float
    average_handle_time: float
    first_call_resolution: float
    occupancy_rate: float
    quality_score: float
    productivity_index: float  # Composite score
    performance_vs_standard: Dict[str, float]

class StatisticsEngine:
    """Calculate comprehensive statistics for timetable and employee data"""
    
    def __init__(self):
        self.production_calendar: Set[date] = set()
        self.employee_schedules: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        self.absence_records: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        self.performance_data: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        self._initialize_production_calendar()
        
    def _initialize_production_calendar(self):
        """Initialize production calendar with holidays"""
        # Sample holidays for 2025
        self.production_calendar = {
            date(2025, 1, 1),   # New Year
            date(2025, 1, 7),   # Orthodox Christmas
            date(2025, 2, 23),  # Defender's Day
            date(2025, 3, 8),   # Women's Day
            date(2025, 5, 1),   # Labor Day
            date(2025, 5, 9),   # Victory Day
            date(2025, 6, 12),  # Russia Day
            date(2025, 11, 4),  # Unity Day
        }
    
    def calculate_working_days(self,
                             start_date: date,
                             end_date: date,
                             calculation_method: CalculationMethod,
                             employee_id: Optional[str] = None) -> WorkingDaysCalculation:
        """Calculate working days with detailed breakdown"""
        # Adjust dates based on calculation method
        period_start, period_end = self._adjust_period_dates(start_date, end_date, calculation_method)
        
        # Count different day types
        total_days = (period_end - period_start).days + 1
        weekends = self._count_weekends(period_start, period_end)
        holidays = self._count_holidays(period_start, period_end)
        
        # Get absence data for employee if specified
        vacation_days = 0
        sick_days = 0
        other_absences = 0
        
        if employee_id:
            absences = self._get_employee_absences(employee_id, period_start, period_end)
            vacation_days = absences.get('vacation', 0)
            sick_days = absences.get('sick_leave', 0)
            other_absences = absences.get('other', 0)
        
        # Calculate working days
        scheduled_working_days = total_days - weekends - holidays
        actual_working_days = scheduled_working_days - vacation_days - sick_days - other_absences
        
        # Calculate utilization rate
        utilization_rate = (actual_working_days / scheduled_working_days * 100) if scheduled_working_days > 0 else 0
        
        return WorkingDaysCalculation(
            period=calculation_method,
            start_date=period_start,
            end_date=period_end,
            total_calendar_days=total_days,
            weekends=weekends,
            holidays=holidays,
            vacation_days=vacation_days,
            sick_days=sick_days,
            other_absences=other_absences,
            scheduled_working_days=scheduled_working_days,
            actual_working_days=actual_working_days,
            utilization_rate=utilization_rate
        )
    
    def _adjust_period_dates(self,
                           start_date: date,
                           end_date: date,
                           method: CalculationMethod) -> Tuple[date, date]:
        """Adjust dates based on calculation method"""
        if method == CalculationMethod.WEEKLY:
            # Adjust to full week (Monday to Sunday)
            start_date = start_date - timedelta(days=start_date.weekday())
            end_date = start_date + timedelta(days=6)
        elif method == CalculationMethod.MONTHLY:
            # Adjust to full month
            start_date = start_date.replace(day=1)
            last_day = calendar.monthrange(start_date.year, start_date.month)[1]
            end_date = start_date.replace(day=last_day)
        elif method == CalculationMethod.YEARLY:
            # Adjust to full year
            start_date = date(start_date.year, 1, 1)
            end_date = date(start_date.year, 12, 31)
        
        return start_date, end_date
    
    def _count_weekends(self, start_date: date, end_date: date) -> int:
        """Count weekend days in period"""
        weekends = 0
        current = start_date
        
        while current <= end_date:
            if current.weekday() in [5, 6]:  # Saturday, Sunday
                weekends += 1
            current += timedelta(days=1)
        
        return weekends
    
    def _count_holidays(self, start_date: date, end_date: date) -> int:
        """Count holidays in period"""
        holidays = 0
        
        for holiday in self.production_calendar:
            if start_date <= holiday <= end_date and holiday.weekday() not in [5, 6]:
                holidays += 1
        
        return holidays
    
    def _get_employee_absences(self,
                             employee_id: str,
                             start_date: date,
                             end_date: date) -> Dict[str, int]:
        """Get employee absence counts by type"""
        absences = defaultdict(int)
        
        for record in self.absence_records.get(employee_id, []):
            absence_date = record.get('date')
            absence_type = record.get('type')
            
            if absence_date and start_date <= absence_date <= end_date:
                if absence_type == AbsenceType.VACATION.value:
                    absences['vacation'] += 1
                elif absence_type == AbsenceType.SICK_LEAVE.value:
                    absences['sick_leave'] += 1
                else:
                    absences['other'] += 1
        
        return dict(absences)
    
    def calculate_planned_hours(self,
                              employee_id: str,
                              schedule_data: List[Dict[str, Any]]) -> List[PlannedHoursCalculation]:
        """Calculate planned hours excluding breaks"""
        calculations = []
        
        for schedule in schedule_data:
            date_val = schedule.get('date')
            blocks = schedule.get('blocks', [])
            
            if not blocks:
                continue
            
            # Calculate different hour types
            gross_blocks = len(blocks)
            work_blocks = sum(1 for b in blocks if b.get('activity_type') == 'work_attendance')
            lunch_blocks = sum(1 for b in blocks if b.get('activity_type') == 'lunch_break')
            break_blocks = sum(1 for b in blocks if b.get('activity_type') == 'short_break')
            downtime_blocks = sum(1 for b in blocks if b.get('activity_type') == 'downtime')
            
            # Convert blocks to hours (15 minutes per block)
            gross_hours = gross_blocks * 0.25
            lunch_hours = lunch_blocks * 0.25
            break_hours = break_blocks * 0.25
            total_break_hours = lunch_hours + break_hours
            
            # Calculate net and productive hours
            net_hours = gross_hours - total_break_hours
            productive_hours = net_hours - (downtime_blocks * 0.25)
            
            # Paid hours include paid breaks (short breaks but not lunch)
            paid_hours = net_hours + break_hours
            
            # Calculate overtime
            standard_hours = 8.0
            overtime_hours = max(0, net_hours - standard_hours)
            
            calculation = PlannedHoursCalculation(
                employee_id=employee_id,
                date=date_val,
                gross_hours=gross_hours,
                break_hours=total_break_hours,
                net_hours=net_hours,
                paid_hours=paid_hours,
                productive_hours=productive_hours,
                overtime_hours=overtime_hours,
                details={
                    'scheduled_hours': gross_hours,
                    'break_deduction': -total_break_hours,
                    'net_work_hours': net_hours,
                    'overtime_hours': overtime_hours,
                    'total_paid_hours': paid_hours
                }
            )
            
            calculations.append(calculation)
        
        return calculations
    
    def detect_overtime(self,
                       employee_id: str,
                       period: Tuple[date, date]) -> OvertimeAnalysis:
        """Detect and analyze overtime hours"""
        daily_overtime = {}
        weekly_overtime = defaultdict(float)
        holiday_overtime = 0.0
        weekend_overtime = 0.0
        emergency_overtime = 0.0
        
        # Process each day in period
        employee_schedules = self.employee_schedules.get(employee_id, [])
        
        for schedule in employee_schedules:
            schedule_date = schedule.get('date')
            if not (period[0] <= schedule_date <= period[1]):
                continue
            
            # Calculate hours for the day
            hours_calc = self.calculate_planned_hours(employee_id, [schedule])
            if hours_calc:
                daily_hours = hours_calc[0].net_hours
                
                # Daily overtime (over 8 hours)
                if daily_hours > 8:
                    daily_ot = daily_hours - 8
                    daily_overtime[schedule_date] = daily_ot
                    
                    # Check if holiday or weekend
                    if schedule_date in self.production_calendar:
                        holiday_overtime += daily_hours  # All hours on holiday are overtime
                    elif schedule_date.weekday() in [5, 6]:
                        weekend_overtime += daily_hours  # All hours on weekend are overtime
                    
                    # Add to weekly total
                    week_num = schedule_date.isocalendar()[1]
                    weekly_overtime[week_num] += daily_hours
        
        # Check weekly overtime (over 40 hours)
        for week_num, weekly_hours in weekly_overtime.items():
            if weekly_hours > 40:
                weekly_overtime[week_num] = weekly_hours - 40
            else:
                weekly_overtime[week_num] = 0
        
        # Calculate total overtime
        total_overtime = (
            sum(daily_overtime.values()) +
            holiday_overtime +
            weekend_overtime +
            emergency_overtime
        )
        
        # Calculate cost (simplified)
        base_rate = 1000  # per hour
        overtime_rates = {
            'daily': 1.5,
            'weekly': 1.5,
            'holiday': 2.0,
            'weekend': 1.5,
            'emergency': 2.0
        }
        
        overtime_cost = (
            sum(daily_overtime.values()) * base_rate * overtime_rates['daily'] +
            holiday_overtime * base_rate * overtime_rates['holiday'] +
            weekend_overtime * base_rate * overtime_rates['weekend'] +
            emergency_overtime * base_rate * overtime_rates['emergency']
        )
        
        # Determine compliance status
        if total_overtime > 120:  # Monthly limit example
            compliance_status = "Non-compliant: Excessive overtime"
        elif any(daily_ot > 4 for daily_ot in daily_overtime.values()):
            compliance_status = "Warning: High daily overtime"
        else:
            compliance_status = "Compliant"
        
        return OvertimeAnalysis(
            employee_id=employee_id,
            period=period,
            daily_overtime=daily_overtime,
            weekly_overtime=dict(weekly_overtime),
            holiday_overtime=holiday_overtime,
            weekend_overtime=weekend_overtime,
            emergency_overtime=emergency_overtime,
            total_overtime=total_overtime,
            overtime_cost=overtime_cost,
            compliance_status=compliance_status
        )
    
    def calculate_absence_rates(self,
                              period: Tuple[date, date],
                              department: Optional[str] = None) -> AbsenceAnalysis:
        """Calculate comprehensive absence analytics"""
        # Get all employees (or filter by department)
        employees = self._get_employees(department)
        employee_count = len(employees)
        
        if employee_count == 0:
            return AbsenceAnalysis(
                period=period,
                employee_count=0,
                absence_rate=0,
                unplanned_absence_rate=0,
                sick_leave_rate=0,
                vacation_usage_rate=0,
                absence_patterns={},
                high_absence_employees=[],
                department_trends={}
            )
        
        # Calculate absence metrics
        total_scheduled_days = 0
        total_absent_days = 0
        unplanned_absences = 0
        sick_days = 0
        vacation_days_used = 0
        vacation_days_allocated = 0
        
        absence_by_employee = defaultdict(int)
        absence_patterns = defaultdict(lambda: defaultdict(int))
        
        for employee_id in employees:
            # Get working days calculation
            work_calc = self.calculate_working_days(
                period[0], period[1], 
                CalculationMethod.CUSTOM_PERIOD,
                employee_id
            )
            
            total_scheduled_days += work_calc.scheduled_working_days
            employee_absences = work_calc.vacation_days + work_calc.sick_days + work_calc.other_absences
            total_absent_days += employee_absences
            
            # Track individual metrics
            absence_by_employee[employee_id] = employee_absences
            sick_days += work_calc.sick_days
            vacation_days_used += work_calc.vacation_days
            
            # Analyze patterns
            for record in self.absence_records.get(employee_id, []):
                if period[0] <= record.get('date') <= period[1]:
                    day_of_week = record.get('date').strftime('%A')
                    absence_patterns['day_of_week'][day_of_week] += 1
                    
                    if record.get('type') in ['sick_leave', 'emergency_leave']:
                        unplanned_absences += 1
        
        # Calculate rates
        absence_rate = (total_absent_days / total_scheduled_days * 100) if total_scheduled_days > 0 else 0
        unplanned_absence_rate = (unplanned_absences / total_absent_days * 100) if total_absent_days > 0 else 0
        sick_leave_rate = (sick_days / total_scheduled_days * 100) if total_scheduled_days > 0 else 0
        
        # Assume standard vacation allocation
        vacation_days_allocated = employee_count * 20  # 20 days per employee per year
        vacation_usage_rate = (vacation_days_used / vacation_days_allocated * 100) if vacation_days_allocated > 0 else 0
        
        # Identify high absence employees (>5% absence rate)
        high_absence_threshold = total_scheduled_days * 0.05 / employee_count
        high_absence_employees = [
            emp_id for emp_id, absences in absence_by_employee.items()
            if absences > high_absence_threshold
        ]
        
        # Department trends (simplified)
        department_trends = {
            'overall_trend': 'stable' if absence_rate < 5 else 'increasing',
            'seasonal_impact': 'high' if max(absence_patterns['day_of_week'].values(), default=0) > 10 else 'low'
        }
        
        return AbsenceAnalysis(
            period=period,
            employee_count=employee_count,
            absence_rate=absence_rate,
            unplanned_absence_rate=unplanned_absence_rate,
            sick_leave_rate=sick_leave_rate,
            vacation_usage_rate=vacation_usage_rate,
            absence_patterns=dict(absence_patterns),
            high_absence_employees=high_absence_employees,
            department_trends=department_trends
        )
    
    def analyze_productivity(self,
                           employee_id: str,
                           period: Tuple[date, date]) -> ProductivityMetrics:
        """Analyze productivity metrics against standards"""
        # Get performance data for employee
        performance_records = [
            r for r in self.performance_data.get(employee_id, [])
            if period[0] <= r.get('date') <= period[1]
        ]
        
        if not performance_records:
            # Return default metrics
            return ProductivityMetrics(
                employee_id=employee_id,
                period=period,
                calls_per_hour=0,
                average_handle_time=0,
                first_call_resolution=0,
                occupancy_rate=0,
                quality_score=0,
                productivity_index=0,
                performance_vs_standard={}
            )
        
        # Calculate average metrics
        calls_per_hour = np.mean([r.get('calls_per_hour', 0) for r in performance_records])
        avg_handle_time = np.mean([r.get('handle_time', 0) for r in performance_records])
        first_call_resolution = np.mean([r.get('fcr_rate', 0) for r in performance_records])
        occupancy_rate = np.mean([r.get('occupancy', 0) for r in performance_records])
        quality_score = np.mean([r.get('quality', 0) for r in performance_records])
        
        # Define productivity standards
        standards = {
            'calls_per_hour': 15,
            'average_handle_time': 5,  # minutes
            'first_call_resolution': 80,  # percentage
            'occupancy_rate': 85,  # percentage
            'quality_score': 90  # percentage
        }
        
        # Calculate performance vs standard
        performance_vs_standard = {
            'calls_per_hour': (calls_per_hour / standards['calls_per_hour']) * 100,
            'average_handle_time': (standards['average_handle_time'] / avg_handle_time) * 100 if avg_handle_time > 0 else 0,
            'first_call_resolution': (first_call_resolution / standards['first_call_resolution']) * 100,
            'occupancy_rate': (occupancy_rate / standards['occupancy_rate']) * 100,
            'quality_score': (quality_score / standards['quality_score']) * 100
        }
        
        # Calculate composite productivity index
        weights = {
            'calls_per_hour': 0.25,
            'average_handle_time': 0.20,
            'first_call_resolution': 0.25,
            'occupancy_rate': 0.15,
            'quality_score': 0.15
        }
        
        productivity_index = sum(
            performance_vs_standard[metric] * weight
            for metric, weight in weights.items()
        )
        
        return ProductivityMetrics(
            employee_id=employee_id,
            period=period,
            calls_per_hour=calls_per_hour,
            average_handle_time=avg_handle_time,
            first_call_resolution=first_call_resolution,
            occupancy_rate=occupancy_rate,
            quality_score=quality_score,
            productivity_index=productivity_index,
            performance_vs_standard=performance_vs_standard
        )
    
    def get_comprehensive_statistics(self,
                                   period: Tuple[date, date],
                                   metrics: List[str] = None) -> Dict[str, Any]:
        """Get comprehensive statistics for specified metrics"""
        if metrics is None:
            metrics = ['working_days', 'overtime', 'absence', 'productivity']
        
        statistics = {}
        
        if 'working_days' in metrics:
            # Calculate working days for the period
            work_calc = self.calculate_working_days(
                period[0], period[1],
                CalculationMethod.CUSTOM_PERIOD
            )
            statistics['working_days'] = {
                'scheduled': work_calc.scheduled_working_days,
                'actual': work_calc.actual_working_days,
                'utilization': work_calc.utilization_rate
            }
        
        if 'overtime' in metrics:
            # Aggregate overtime for all employees
            total_overtime = 0
            total_cost = 0
            employees = self._get_employees()
            
            for employee_id in employees:
                ot_analysis = self.detect_overtime(employee_id, period)
                total_overtime += ot_analysis.total_overtime
                total_cost += ot_analysis.overtime_cost
            
            statistics['overtime'] = {
                'total_hours': total_overtime,
                'total_cost': total_cost,
                'average_per_employee': total_overtime / len(employees) if employees else 0
            }
        
        if 'absence' in metrics:
            absence_analysis = self.calculate_absence_rates(period)
            statistics['absence'] = {
                'overall_rate': absence_analysis.absence_rate,
                'unplanned_rate': absence_analysis.unplanned_absence_rate,
                'sick_leave_rate': absence_analysis.sick_leave_rate,
                'high_absence_count': len(absence_analysis.high_absence_employees)
            }
        
        if 'productivity' in metrics:
            # Average productivity across all employees
            employees = self._get_employees()
            productivity_scores = []
            
            for employee_id in employees[:10]:  # Sample for performance
                prod_metrics = self.analyze_productivity(employee_id, period)
                productivity_scores.append(prod_metrics.productivity_index)
            
            statistics['productivity'] = {
                'average_index': np.mean(productivity_scores) if productivity_scores else 0,
                'min_index': min(productivity_scores) if productivity_scores else 0,
                'max_index': max(productivity_scores) if productivity_scores else 0
            }
        
        return statistics
    
    def _get_employees(self, department: Optional[str] = None) -> List[str]:
        """Get list of employees (optionally filtered by department)"""
        # In production, this would query the employee database
        # For now, return employees from schedule data
        employees = list(self.employee_schedules.keys())
        
        if not employees:
            # Return sample employees
            employees = ['EMP001', 'EMP002', 'EMP003', 'EMP004', 'EMP005']
        
        return employees
    
    def add_schedule_data(self, employee_id: str, schedule_data: List[Dict[str, Any]]):
        """Add schedule data for statistics calculation"""
        self.employee_schedules[employee_id].extend(schedule_data)
    
    def add_absence_record(self, employee_id: str, absence_date: date, absence_type: str):
        """Add absence record for employee"""
        self.absence_records[employee_id].append({
            'date': absence_date,
            'type': absence_type
        })
    
    def add_performance_data(self, employee_id: str, performance_data: Dict[str, Any]):
        """Add performance data for productivity analysis"""
        self.performance_data[employee_id].append(performance_data)
    
    def generate_statistics_report(self, period: Tuple[date, date]) -> pd.DataFrame:
        """Generate comprehensive statistics report as DataFrame"""
        report_data = []
        employees = self._get_employees()
        
        for employee_id in employees:
            # Working days
            work_calc = self.calculate_working_days(
                period[0], period[1],
                CalculationMethod.CUSTOM_PERIOD,
                employee_id
            )
            
            # Overtime
            ot_analysis = self.detect_overtime(employee_id, period)
            
            # Productivity
            prod_metrics = self.analyze_productivity(employee_id, period)
            
            report_data.append({
                'employee_id': employee_id,
                'scheduled_days': work_calc.scheduled_working_days,
                'actual_days': work_calc.actual_working_days,
                'absence_days': work_calc.vacation_days + work_calc.sick_days,
                'overtime_hours': ot_analysis.total_overtime,
                'productivity_index': prod_metrics.productivity_index,
                'calls_per_hour': prod_metrics.calls_per_hour,
                'quality_score': prod_metrics.quality_score
            })
        
        return pd.DataFrame(report_data)