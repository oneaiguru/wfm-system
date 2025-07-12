#!/usr/bin/env python3
"""
Compliance Validator for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Monitor Timetable Compliance with Labor Standards
"""

import numpy as np
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict

logger = logging.getLogger(__name__)

class ComplianceType(Enum):
    """Types of compliance checks"""
    REST_PERIOD = "rest_period"
    DAILY_WORK_LIMIT = "daily_work_limit"
    WEEKLY_WORK_LIMIT = "weekly_work_limit"
    BREAK_REQUIREMENT = "break_requirement"
    LUNCH_REQUIREMENT = "lunch_requirement"
    OVERTIME_LIMIT = "overtime_limit"
    CONSECUTIVE_DAYS = "consecutive_days"

class ViolationSeverity(Enum):
    """Severity levels for compliance violations"""
    CRITICAL = "critical"  # Legal violation
    HIGH = "high"         # Policy violation
    MEDIUM = "medium"     # Best practice violation
    LOW = "low"           # Minor deviation

@dataclass
class LaborStandard:
    """Labor standard requirement"""
    standard_type: ComplianceType
    requirement_value: Any
    validation_rule: str
    severity_if_violated: ViolationSeverity
    description: str

@dataclass
class ComplianceViolation:
    """Identified compliance violation"""
    violation_id: str
    employee_id: str
    violation_type: ComplianceType
    violation_date: datetime
    severity: ViolationSeverity
    description: str
    actual_value: Any
    required_value: Any
    corrective_actions: List[str]

@dataclass
class ComplianceReport:
    """Compliance validation report"""
    report_date: datetime
    period_start: datetime
    period_end: datetime
    total_employees: int
    total_violations: int
    violations_by_type: Dict[ComplianceType, int]
    violations_by_severity: Dict[ViolationSeverity, int]
    violations: List[ComplianceViolation]
    compliance_score: float  # 0-100%
    recommendations: List[str]

@dataclass
class EmployeeWorkPattern:
    """Employee work pattern for compliance checking"""
    employee_id: str
    date: datetime
    shift_start: datetime
    shift_end: datetime
    total_hours: float
    break_minutes: int
    lunch_minutes: int
    overtime_hours: float
    consecutive_days_worked: int

class ComplianceValidator:
    """Validate timetables against labor standards"""
    
    def __init__(self):
        self.labor_standards = self._initialize_labor_standards()
        self.violations: List[ComplianceViolation] = []
        self.employee_patterns: Dict[str, List[EmployeeWorkPattern]] = defaultdict(list)
        
    def _initialize_labor_standards(self) -> Dict[ComplianceType, LaborStandard]:
        """Initialize labor standards from BDD specifications"""
        return {
            ComplianceType.REST_PERIOD: LaborStandard(
                standard_type=ComplianceType.REST_PERIOD,
                requirement_value=11,  # hours
                validation_rule="11 hours between shifts",
                severity_if_violated=ViolationSeverity.CRITICAL,
                description="Minimum 11 hours rest between consecutive shifts"
            ),
            ComplianceType.DAILY_WORK_LIMIT: LaborStandard(
                standard_type=ComplianceType.DAILY_WORK_LIMIT,
                requirement_value=(8, 12),  # (standard, maximum)
                validation_rule="8 hours standard, 12 max",
                severity_if_violated=ViolationSeverity.HIGH,
                description="Daily work limit: 8 hours standard, 12 hours maximum"
            ),
            ComplianceType.WEEKLY_WORK_LIMIT: LaborStandard(
                standard_type=ComplianceType.WEEKLY_WORK_LIMIT,
                requirement_value=(40, 48),  # (standard, maximum)
                validation_rule="40 hours standard, 48 max",
                severity_if_violated=ViolationSeverity.HIGH,
                description="Weekly work limit: 40 hours standard, 48 hours maximum"
            ),
            ComplianceType.BREAK_REQUIREMENT: LaborStandard(
                standard_type=ComplianceType.BREAK_REQUIREMENT,
                requirement_value=15,  # minutes per 2 hours
                validation_rule="15 min per 2 hours worked",
                severity_if_violated=ViolationSeverity.MEDIUM,
                description="15-minute break required every 2 hours of work"
            ),
            ComplianceType.LUNCH_REQUIREMENT: LaborStandard(
                standard_type=ComplianceType.LUNCH_REQUIREMENT,
                requirement_value=(30, 60),  # (minimum, maximum) minutes
                validation_rule="30-60 min for 6+ hour shifts",
                severity_if_violated=ViolationSeverity.MEDIUM,
                description="Lunch break 30-60 minutes for shifts over 6 hours"
            ),
            ComplianceType.CONSECUTIVE_DAYS: LaborStandard(
                standard_type=ComplianceType.CONSECUTIVE_DAYS,
                requirement_value=6,  # maximum consecutive days
                validation_rule="Maximum 6 consecutive work days",
                severity_if_violated=ViolationSeverity.HIGH,
                description="Maximum 6 consecutive days without rest day"
            )
        }
    
    def validate_timetable(self,
                          timetable_blocks: List[Dict[str, Any]],
                          validation_period: Tuple[datetime, datetime]) -> ComplianceReport:
        """Validate timetable compliance for the period"""
        self.violations = []
        self.employee_patterns = defaultdict(list)
        
        # Process timetable into work patterns
        self._process_timetable_blocks(timetable_blocks, validation_period)
        
        # Run compliance checks
        self._check_rest_periods()
        self._check_daily_work_limits()
        self._check_weekly_work_limits()
        self._check_break_requirements()
        self._check_lunch_requirements()
        self._check_consecutive_days()
        
        # Generate compliance report
        report = self._generate_compliance_report(validation_period)
        
        return report
    
    def _process_timetable_blocks(self,
                                 timetable_blocks: List[Dict[str, Any]],
                                 validation_period: Tuple[datetime, datetime]):
        """Process timetable blocks into employee work patterns"""
        # Group blocks by employee and date
        employee_daily_blocks = defaultdict(lambda: defaultdict(list))
        
        for block in timetable_blocks:
            employee_id = block.get('employee_id')
            block_time = block.get('datetime')
            
            if (employee_id and block_time and
                validation_period[0] <= block_time <= validation_period[1]):
                
                date_key = block_time.date()
                employee_daily_blocks[employee_id][date_key].append(block)
        
        # Create work patterns
        for employee_id, daily_blocks in employee_daily_blocks.items():
            for date, blocks in daily_blocks.items():
                if blocks:
                    pattern = self._create_work_pattern(employee_id, date, blocks)
                    self.employee_patterns[employee_id].append(pattern)
        
        # Sort patterns by date for each employee
        for employee_id in self.employee_patterns:
            self.employee_patterns[employee_id].sort(key=lambda p: p.date)
            
        # Calculate consecutive days worked
        self._calculate_consecutive_days()
    
    def _create_work_pattern(self,
                           employee_id: str,
                           date: datetime,
                           blocks: List[Dict[str, Any]]) -> EmployeeWorkPattern:
        """Create work pattern from daily blocks"""
        # Sort blocks by time
        blocks.sort(key=lambda b: b['datetime'])
        
        # Find shift boundaries
        shift_start = blocks[0]['datetime']
        shift_end = blocks[-1]['datetime'] + timedelta(minutes=15)  # Each block is 15 minutes
        
        # Calculate hours and breaks
        total_blocks = len(blocks)
        work_blocks = sum(1 for b in blocks if b.get('activity_type') == 'work_attendance')
        break_blocks = sum(1 for b in blocks if b.get('activity_type') == 'short_break')
        lunch_blocks = sum(1 for b in blocks if b.get('activity_type') == 'lunch_break')
        
        total_hours = total_blocks * 0.25  # 15 minutes per block
        break_minutes = break_blocks * 15
        lunch_minutes = lunch_blocks * 15
        
        # Calculate overtime
        standard_hours = 8.0
        overtime_hours = max(0, total_hours - standard_hours)
        
        return EmployeeWorkPattern(
            employee_id=employee_id,
            date=date,
            shift_start=shift_start,
            shift_end=shift_end,
            total_hours=total_hours,
            break_minutes=break_minutes,
            lunch_minutes=lunch_minutes,
            overtime_hours=overtime_hours,
            consecutive_days_worked=1  # Will be updated later
        )
    
    def _calculate_consecutive_days(self):
        """Calculate consecutive days worked for each employee"""
        for employee_id, patterns in self.employee_patterns.items():
            consecutive_count = 1
            
            for i in range(1, len(patterns)):
                prev_date = patterns[i-1].date
                curr_date = patterns[i].date
                
                if (curr_date - prev_date).days == 1:
                    consecutive_count += 1
                else:
                    consecutive_count = 1
                
                patterns[i].consecutive_days_worked = consecutive_count
    
    def _check_rest_periods(self):
        """Check minimum rest period between shifts"""
        standard = self.labor_standards[ComplianceType.REST_PERIOD]
        
        for employee_id, patterns in self.employee_patterns.items():
            for i in range(1, len(patterns)):
                prev_shift_end = patterns[i-1].shift_end
                curr_shift_start = patterns[i].shift_start
                
                rest_hours = (curr_shift_start - prev_shift_end).total_seconds() / 3600
                
                if rest_hours < standard.requirement_value:
                    violation = ComplianceViolation(
                        violation_id=f"REST_{employee_id}_{patterns[i].date}",
                        employee_id=employee_id,
                        violation_type=ComplianceType.REST_PERIOD,
                        violation_date=patterns[i].date,
                        severity=standard.severity_if_violated,
                        description=f"Insufficient rest period between shifts",
                        actual_value=f"{rest_hours:.1f} hours",
                        required_value=f"{standard.requirement_value} hours",
                        corrective_actions=[
                            "Adjust shift start time",
                            "Reduce previous shift end time",
                            "Provide compensatory rest"
                        ]
                    )
                    self.violations.append(violation)
    
    def _check_daily_work_limits(self):
        """Check daily work hour limits"""
        standard = self.labor_standards[ComplianceType.DAILY_WORK_LIMIT]
        standard_hours, max_hours = standard.requirement_value
        
        for employee_id, patterns in self.employee_patterns.items():
            for pattern in patterns:
                if pattern.total_hours > max_hours:
                    severity = ViolationSeverity.CRITICAL
                    description = "Exceeded maximum daily work hours"
                elif pattern.total_hours > standard_hours:
                    severity = ViolationSeverity.LOW
                    description = "Exceeded standard daily work hours"
                else:
                    continue
                
                violation = ComplianceViolation(
                    violation_id=f"DAILY_{employee_id}_{pattern.date}",
                    employee_id=employee_id,
                    violation_type=ComplianceType.DAILY_WORK_LIMIT,
                    violation_date=pattern.date,
                    severity=severity,
                    description=description,
                    actual_value=f"{pattern.total_hours:.1f} hours",
                    required_value=f"{standard_hours} standard, {max_hours} max",
                    corrective_actions=[
                        "Reduce shift duration",
                        "Distribute work to other days",
                        "Ensure proper overtime authorization"
                    ]
                )
                self.violations.append(violation)
    
    def _check_weekly_work_limits(self):
        """Check weekly work hour limits"""
        standard = self.labor_standards[ComplianceType.WEEKLY_WORK_LIMIT]
        standard_hours, max_hours = standard.requirement_value
        
        # Group patterns by week
        for employee_id, patterns in self.employee_patterns.items():
            weekly_hours = defaultdict(float)
            weekly_dates = defaultdict(list)
            
            for pattern in patterns:
                week_key = pattern.date.isocalendar()[1]  # Week number
                weekly_hours[week_key] += pattern.total_hours
                weekly_dates[week_key].append(pattern.date)
            
            for week, hours in weekly_hours.items():
                if hours > max_hours:
                    severity = ViolationSeverity.CRITICAL
                    description = "Exceeded maximum weekly work hours"
                elif hours > standard_hours:
                    severity = ViolationSeverity.LOW
                    description = "Exceeded standard weekly work hours"
                else:
                    continue
                
                violation = ComplianceViolation(
                    violation_id=f"WEEKLY_{employee_id}_W{week}",
                    employee_id=employee_id,
                    violation_type=ComplianceType.WEEKLY_WORK_LIMIT,
                    violation_date=min(weekly_dates[week]),
                    severity=severity,
                    description=description,
                    actual_value=f"{hours:.1f} hours",
                    required_value=f"{standard_hours} standard, {max_hours} max",
                    corrective_actions=[
                        "Reduce weekly hours",
                        "Redistribute workload",
                        "Review scheduling patterns"
                    ]
                )
                self.violations.append(violation)
    
    def _check_break_requirements(self):
        """Check break requirements are met"""
        standard = self.labor_standards[ComplianceType.BREAK_REQUIREMENT]
        
        for employee_id, patterns in self.employee_patterns.items():
            for pattern in patterns:
                # Calculate required breaks
                work_hours = pattern.total_hours - (pattern.lunch_minutes / 60)
                required_breaks = int(work_hours / 2) * standard.requirement_value
                
                if pattern.break_minutes < required_breaks and work_hours >= 2:
                    violation = ComplianceViolation(
                        violation_id=f"BREAK_{employee_id}_{pattern.date}",
                        employee_id=employee_id,
                        violation_type=ComplianceType.BREAK_REQUIREMENT,
                        violation_date=pattern.date,
                        severity=standard.severity_if_violated,
                        description="Insufficient break time",
                        actual_value=f"{pattern.break_minutes} minutes",
                        required_value=f"{required_breaks} minutes",
                        corrective_actions=[
                            "Schedule additional breaks",
                            "Adjust break timing",
                            "Review workload distribution"
                        ]
                    )
                    self.violations.append(violation)
    
    def _check_lunch_requirements(self):
        """Check lunch break requirements"""
        standard = self.labor_standards[ComplianceType.LUNCH_REQUIREMENT]
        min_lunch, max_lunch = standard.requirement_value
        
        for employee_id, patterns in self.employee_patterns.items():
            for pattern in patterns:
                if pattern.total_hours >= 6:  # Lunch required for 6+ hour shifts
                    if pattern.lunch_minutes < min_lunch:
                        violation = ComplianceViolation(
                            violation_id=f"LUNCH_{employee_id}_{pattern.date}",
                            employee_id=employee_id,
                            violation_type=ComplianceType.LUNCH_REQUIREMENT,
                            violation_date=pattern.date,
                            severity=standard.severity_if_violated,
                            description="Insufficient lunch break",
                            actual_value=f"{pattern.lunch_minutes} minutes",
                            required_value=f"{min_lunch}-{max_lunch} minutes",
                            corrective_actions=[
                                "Extend lunch break",
                                "Reschedule lunch timing",
                                "Ensure lunch is not interrupted"
                            ]
                        )
                        self.violations.append(violation)
                    elif pattern.lunch_minutes > max_lunch:
                        violation = ComplianceViolation(
                            violation_id=f"LUNCH_LONG_{employee_id}_{pattern.date}",
                            employee_id=employee_id,
                            violation_type=ComplianceType.LUNCH_REQUIREMENT,
                            violation_date=pattern.date,
                            severity=ViolationSeverity.LOW,
                            description="Excessive lunch break",
                            actual_value=f"{pattern.lunch_minutes} minutes",
                            required_value=f"{min_lunch}-{max_lunch} minutes",
                            corrective_actions=[
                                "Reduce lunch duration",
                                "Review schedule efficiency"
                            ]
                        )
                        self.violations.append(violation)
    
    def _check_consecutive_days(self):
        """Check consecutive days worked limit"""
        standard = self.labor_standards[ComplianceType.CONSECUTIVE_DAYS]
        max_consecutive = standard.requirement_value
        
        for employee_id, patterns in self.employee_patterns.items():
            for pattern in patterns:
                if pattern.consecutive_days_worked > max_consecutive:
                    violation = ComplianceViolation(
                        violation_id=f"CONSEC_{employee_id}_{pattern.date}",
                        employee_id=employee_id,
                        violation_type=ComplianceType.CONSECUTIVE_DAYS,
                        violation_date=pattern.date,
                        severity=standard.severity_if_violated,
                        description="Exceeded consecutive days limit",
                        actual_value=f"{pattern.consecutive_days_worked} days",
                        required_value=f"{max_consecutive} days maximum",
                        corrective_actions=[
                            "Schedule mandatory rest day",
                            "Rotate staff assignments",
                            "Review long-term scheduling"
                        ]
                    )
                    self.violations.append(violation)
    
    def _generate_compliance_report(self, validation_period: Tuple[datetime, datetime]) -> ComplianceReport:
        """Generate comprehensive compliance report"""
        # Count violations by type and severity
        violations_by_type = defaultdict(int)
        violations_by_severity = defaultdict(int)
        
        for violation in self.violations:
            violations_by_type[violation.violation_type] += 1
            violations_by_severity[violation.severity] += 1
        
        # Calculate compliance score
        total_checks = len(self.employee_patterns) * len(self.labor_standards)
        compliance_score = ((total_checks - len(self.violations)) / total_checks * 100) if total_checks > 0 else 100
        
        # Generate recommendations
        recommendations = self._generate_recommendations(violations_by_type, violations_by_severity)
        
        return ComplianceReport(
            report_date=datetime.now(),
            period_start=validation_period[0],
            period_end=validation_period[1],
            total_employees=len(self.employee_patterns),
            total_violations=len(self.violations),
            violations_by_type=dict(violations_by_type),
            violations_by_severity=dict(violations_by_severity),
            violations=self.violations,
            compliance_score=compliance_score,
            recommendations=recommendations
        )
    
    def _generate_recommendations(self,
                                violations_by_type: Dict[ComplianceType, int],
                                violations_by_severity: Dict[ViolationSeverity, int]) -> List[str]:
        """Generate recommendations based on violations"""
        recommendations = []
        
        # Critical violations require immediate action
        if violations_by_severity.get(ViolationSeverity.CRITICAL, 0) > 0:
            recommendations.append("URGENT: Address critical compliance violations immediately")
            recommendations.append("Review and revise scheduling policies to prevent legal violations")
        
        # High severity violations
        if violations_by_severity.get(ViolationSeverity.HIGH, 0) > 5:
            recommendations.append("Implement automated compliance checking in scheduling system")
            recommendations.append("Provide compliance training to scheduling managers")
        
        # Specific violation types
        if violations_by_type.get(ComplianceType.REST_PERIOD, 0) > 0:
            recommendations.append("Enforce minimum rest periods between shifts")
            recommendations.append("Consider implementing shift pattern templates")
        
        if violations_by_type.get(ComplianceType.WEEKLY_WORK_LIMIT, 0) > 0:
            recommendations.append("Monitor weekly hours more closely")
            recommendations.append("Implement weekly hour alerts at 90% threshold")
        
        if violations_by_type.get(ComplianceType.BREAK_REQUIREMENT, 0) > 10:
            recommendations.append("Review break scheduling practices")
            recommendations.append("Ensure breaks are protected time")
        
        # General recommendations
        if len(self.violations) > 20:
            recommendations.append("Consider investing in workforce management software")
            recommendations.append("Establish regular compliance audits")
        
        return recommendations
    
    def get_employee_compliance_summary(self, employee_id: str) -> Dict[str, Any]:
        """Get compliance summary for specific employee"""
        employee_violations = [v for v in self.violations if v.employee_id == employee_id]
        employee_patterns = self.employee_patterns.get(employee_id, [])
        
        if not employee_patterns:
            return {"status": "No data for employee"}
        
        # Calculate metrics
        total_hours = sum(p.total_hours for p in employee_patterns)
        avg_daily_hours = total_hours / len(employee_patterns) if employee_patterns else 0
        overtime_hours = sum(p.overtime_hours for p in employee_patterns)
        max_consecutive_days = max(p.consecutive_days_worked for p in employee_patterns) if employee_patterns else 0
        
        return {
            "employee_id": employee_id,
            "total_violations": len(employee_violations),
            "violations_by_type": defaultdict(int, {v.violation_type.value: 1 for v in employee_violations}),
            "total_hours_worked": total_hours,
            "average_daily_hours": avg_daily_hours,
            "total_overtime_hours": overtime_hours,
            "max_consecutive_days": max_consecutive_days,
            "compliance_status": "Compliant" if len(employee_violations) == 0 else "Non-compliant",
            "risk_level": self._assess_risk_level(employee_violations)
        }
    
    def _assess_risk_level(self, violations: List[ComplianceViolation]) -> str:
        """Assess risk level based on violations"""
        if any(v.severity == ViolationSeverity.CRITICAL for v in violations):
            return "Critical Risk"
        elif any(v.severity == ViolationSeverity.HIGH for v in violations):
            return "High Risk"
        elif len(violations) > 5:
            return "Medium Risk"
        elif len(violations) > 0:
            return "Low Risk"
        else:
            return "No Risk"
    
    def suggest_corrective_schedule(self,
                                   employee_id: str,
                                   violation_type: ComplianceType) -> Dict[str, Any]:
        """Suggest corrective schedule adjustments"""
        suggestions = {
            "employee_id": employee_id,
            "violation_type": violation_type.value,
            "adjustments": []
        }
        
        if violation_type == ComplianceType.REST_PERIOD:
            suggestions["adjustments"] = [
                {"action": "Delay next shift start by 2 hours"},
                {"action": "End current shift 2 hours early"},
                {"action": "Swap shifts with another employee"}
            ]
        elif violation_type == ComplianceType.DAILY_WORK_LIMIT:
            suggestions["adjustments"] = [
                {"action": "Split shift into two parts"},
                {"action": "Reassign overtime hours to another employee"},
                {"action": "Schedule compensatory time off"}
            ]
        elif violation_type == ComplianceType.CONSECUTIVE_DAYS:
            suggestions["adjustments"] = [
                {"action": "Schedule immediate rest day"},
                {"action": "Implement rotating rest day pattern"},
                {"action": "Review monthly schedule for better distribution"}
            ]
        
        return suggestions