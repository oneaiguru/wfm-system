#!/usr/bin/env python3
"""
Compliance Validator for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Monitor Timetable Compliance with Labor Standards

Mobile Workforce Scheduler Pattern Implementation:
- Real-time compliance monitoring with database integration
- Labor law compliance validation from compliance_tracking table
- Mobile worker location-based compliance checks
- Violation tracking and automated corrective actions
"""

import numpy as np
import asyncio
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import json

# Import database connector
try:
    from ..core.db_connector import WFMDatabaseConnector, get_connector
except ImportError:
    # Fallback for testing
    WFMDatabaseConnector = None
    get_connector = None

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
    """Labor standard requirement from database"""
    standard_type: ComplianceType
    requirement_value: Any
    validation_rule: str
    severity_if_violated: ViolationSeverity
    description: str
    compliance_id: Optional[str] = None
    regulatory_body: Optional[str] = None
    applicable_roles: Optional[List[str]] = None
    assessment_frequency: Optional[str] = None

@dataclass
class ComplianceViolation:
    """Identified compliance violation with database integration"""
    violation_id: str
    employee_id: str
    violation_type: ComplianceType
    violation_date: datetime
    severity: ViolationSeverity
    description: str
    actual_value: Any
    required_value: Any
    corrective_actions: List[str]
    location_data: Optional[Dict] = None
    mobile_worker: bool = False
    auto_resolved: bool = False
    escalation_level: int = 0
    alert_sent: bool = False

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
    """Validate timetables against labor standards with real-time database integration"""
    
    def __init__(self, db_connector: WFMDatabaseConnector = None):
        self.db_connector = db_connector
        self.labor_standards: Dict[ComplianceType, LaborStandard] = {}
        self.violations: List[ComplianceViolation] = []
        self.employee_patterns: Dict[str, List[EmployeeWorkPattern]] = defaultdict(list)
        self.mobile_workers: Set[str] = set()
        self.real_time_monitoring = False
        
        # Initialize with database if available
        if self.db_connector and hasattr(self.db_connector, 'connected'):
            asyncio.create_task(self._initialize_from_database())
        else:
            self.labor_standards = self._initialize_fallback_standards()
        
    async def _initialize_from_database(self):
        """Initialize labor standards from compliance_tracking table"""
        try:
            if not self.db_connector.connected:
                await self.db_connector.connect()
            
            # Load compliance standards from database
            query = """
            SELECT 
                compliance_id,
                compliance_name,
                compliance_type,
                description,
                compliance_requirements,
                current_status,
                applicable_to_roles,
                assessment_frequency,
                regulatory_body
            FROM compliance_tracking
            WHERE is_active = TRUE
            AND compliance_type IN ('regulatory', 'internal_policy')
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query)
                
                for row in rows:
                    compliance_data = dict(row)
                    self._parse_compliance_standard(compliance_data)
                    
            # Load mobile worker identifications
            await self._load_mobile_workers()
            
            logger.info(f"Loaded {len(self.labor_standards)} compliance standards from database")
            
        except Exception as e:
            logger.error(f"Failed to load compliance standards from database: {e}")
            # Fallback to default standards
            self.labor_standards = self._initialize_fallback_standards()
    
    def _parse_compliance_standard(self, compliance_data: Dict):
        """Parse compliance data from database into LaborStandard"""
        try:
            requirements = compliance_data.get('compliance_requirements', {})
            if isinstance(requirements, str):
                requirements = json.loads(requirements)
            
            # Map compliance types
            compliance_name = compliance_data['compliance_name'].lower()
            
            if 'rest' in compliance_name or 'break' in compliance_name:
                standard_type = ComplianceType.REST_PERIOD
                requirement_value = requirements.get('min_rest_hours', 11)
            elif 'daily' in compliance_name and 'work' in compliance_name:
                standard_type = ComplianceType.DAILY_WORK_LIMIT
                requirement_value = (requirements.get('standard_hours', 8), 
                                   requirements.get('max_hours', 12))
            elif 'weekly' in compliance_name and 'work' in compliance_name:
                standard_type = ComplianceType.WEEKLY_WORK_LIMIT
                requirement_value = (requirements.get('standard_hours', 40), 
                                   requirements.get('max_hours', 48))
            elif 'break' in compliance_name and 'requirement' in compliance_name:
                standard_type = ComplianceType.BREAK_REQUIREMENT
                requirement_value = requirements.get('break_minutes', 15)
            elif 'lunch' in compliance_name:
                standard_type = ComplianceType.LUNCH_REQUIREMENT
                requirement_value = (requirements.get('min_minutes', 30),
                                   requirements.get('max_minutes', 60))
            elif 'consecutive' in compliance_name:
                standard_type = ComplianceType.CONSECUTIVE_DAYS
                requirement_value = requirements.get('max_consecutive_days', 6)
            else:
                # Skip unrecognized compliance types
                return
            
            # Determine severity based on compliance type
            severity = ViolationSeverity.MEDIUM
            if compliance_data['compliance_type'] == 'regulatory':
                severity = ViolationSeverity.CRITICAL
            elif 'critical' in compliance_data.get('description', '').lower():
                severity = ViolationSeverity.HIGH
            
            standard = LaborStandard(
                standard_type=standard_type,
                requirement_value=requirement_value,
                validation_rule=requirements.get('validation_rule', ''),
                severity_if_violated=severity,
                description=compliance_data['description'],
                compliance_id=compliance_data['compliance_id'],
                regulatory_body=compliance_data.get('regulatory_body'),
                applicable_roles=compliance_data.get('applicable_to_roles', []),
                assessment_frequency=compliance_data.get('assessment_frequency')
            )
            
            self.labor_standards[standard_type] = standard
            
        except Exception as e:
            logger.error(f"Error parsing compliance standard: {e}")
    
    async def _load_mobile_workers(self):
        """Load mobile worker identifications from database"""
        try:
            # Query for mobile workers based on work patterns
            query = """
            SELECT DISTINCT e.employee_id
            FROM employees e
            JOIN time_entries te ON e.employee_id = te.employee_id
            WHERE te.location_data IS NOT NULL
            AND te.entry_timestamp >= NOW() - INTERVAL '30 days'
            AND jsonb_typeof(te.location_data->'coordinates') = 'array'
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query)
                self.mobile_workers = {str(row['employee_id']) for row in rows}
                
            logger.info(f"Identified {len(self.mobile_workers)} mobile workers")
            
        except Exception as e:
            logger.error(f"Error loading mobile workers: {e}")
    
    def _initialize_fallback_standards(self) -> Dict[ComplianceType, LaborStandard]:
        """Fallback initialization when database is not available"""
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
    
    async def validate_timetable(self,
                                timetable_blocks: List[Dict[str, Any]] = None,
                                validation_period: Tuple[datetime, datetime] = None,
                                use_real_time_data: bool = True) -> ComplianceReport:
        """Validate timetable compliance with real-time database integration"""
        self.violations = []
        self.employee_patterns = defaultdict(list)
        
        # Set default validation period if not provided
        if validation_period is None:
            end_time = datetime.now()
            start_time = end_time - timedelta(days=7)  # Last 7 days
            validation_period = (start_time, end_time)
        
        # Load data from database if available and requested
        if use_real_time_data and self.db_connector:
            await self._load_real_time_work_patterns(validation_period)
        elif timetable_blocks:
            # Fallback to provided timetable blocks
            self._process_timetable_blocks(timetable_blocks, validation_period)
        else:
            raise ValueError("Either use_real_time_data must be True with db_connector or timetable_blocks must be provided")
        
        # Run compliance checks
        await self._check_rest_periods()
        await self._check_daily_work_limits()
        await self._check_weekly_work_limits()
        await self._check_break_requirements()
        await self._check_lunch_requirements()
        await self._check_consecutive_days()
        
        # Mobile workforce specific checks
        await self._check_mobile_worker_compliance()
        
        # Store violations in database
        if self.db_connector:
            await self._store_violations_in_database()
        
        # Generate compliance report
        report = await self._generate_compliance_report(validation_period)
        
        return report
    
    async def _load_real_time_work_patterns(self, validation_period: Tuple[datetime, datetime]):
        """Load work patterns from real database tables"""
        try:
            # Load attendance sessions from database
            query = """
            SELECT 
                ats.employee_id,
                ats.session_date,
                ats.clock_in_time,
                ats.clock_out_time,
                ats.scheduled_start,
                ats.scheduled_end,
                ats.total_hours,
                ats.productive_hours,
                ats.break_hours,
                ats.overtime_hours,
                ats.late_minutes,
                ats.early_departure_minutes,
                ats.attendance_status,
                ats.adherence_percentage,
                e.first_name,
                e.last_name
            FROM attendance_sessions ats
            JOIN employees e ON ats.employee_id = e.employee_id
            WHERE ats.session_date BETWEEN $1 AND $2
            AND ats.is_complete = TRUE
            ORDER BY ats.employee_id, ats.session_date
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query, validation_period[0].date(), validation_period[1].date())
                
                for row in rows:
                    employee_id = str(row['employee_id'])
                    
                    # Create work pattern from attendance session
                    pattern = EmployeeWorkPattern(
                        employee_id=employee_id,
                        date=row['session_date'],
                        shift_start=row['clock_in_time'] or row['scheduled_start'],
                        shift_end=row['clock_out_time'] or row['scheduled_end'],
                        total_hours=float(row['total_hours'] or 0),
                        break_minutes=int((row['break_hours'] or 0) * 60),
                        lunch_minutes=0,  # Will be calculated from break data
                        overtime_hours=float(row['overtime_hours'] or 0),
                        consecutive_days_worked=1  # Will be calculated later
                    )
                    
                    self.employee_patterns[employee_id].append(pattern)
            
            # Load detailed break information
            await self._load_break_details(validation_period)
            
            # Sort patterns by date for each employee
            for employee_id in self.employee_patterns:
                self.employee_patterns[employee_id].sort(key=lambda p: p.date)
                
            # Calculate consecutive days worked
            self._calculate_consecutive_days()
            
            logger.info(f"Loaded work patterns for {len(self.employee_patterns)} employees")
            
        except Exception as e:
            logger.error(f"Error loading real-time work patterns: {e}")
            raise
    
    async def _load_break_details(self, validation_period: Tuple[datetime, datetime]):
        """Load detailed break information from time_entries"""
        try:
            query = """
            SELECT 
                te.employee_id,
                DATE(te.entry_timestamp) as work_date,
                te.entry_type,
                te.entry_timestamp,
                te.work_state_id,
                ws.state_name,
                ws.counts_as_break_time,
                te.location_data
            FROM time_entries te
            LEFT JOIN work_states ws ON te.work_state_id = ws.id
            WHERE te.entry_timestamp BETWEEN $1 AND $2
            AND te.entry_type IN ('break_start', 'break_end', 'status_change')
            ORDER BY te.employee_id, te.entry_timestamp
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query, validation_period[0], validation_period[1])
                
                # Process break entries to calculate lunch/break times
                employee_breaks = defaultdict(lambda: defaultdict(list))
                
                for row in rows:
                    employee_id = str(row['employee_id'])
                    work_date = row['work_date']
                    
                    employee_breaks[employee_id][work_date].append({
                        'timestamp': row['entry_timestamp'],
                        'type': row['entry_type'],
                        'state_name': row['state_name'],
                        'is_break': row['counts_as_break_time'],
                        'location_data': row['location_data']
                    })
                
                # Update work patterns with break information
                for employee_id, date_breaks in employee_breaks.items():
                    if employee_id in self.employee_patterns:
                        for pattern in self.employee_patterns[employee_id]:
                            date_key = pattern.date
                            if date_key in date_breaks:
                                break_info = self._calculate_break_times(date_breaks[date_key])
                                pattern.break_minutes = break_info['total_break_minutes']
                                pattern.lunch_minutes = break_info['lunch_minutes']
                                
                                # Check if this is a mobile worker based on location data
                                if any(entry.get('location_data') for entry in date_breaks[date_key]):
                                    self.mobile_workers.add(employee_id)
        
        except Exception as e:
            logger.error(f"Error loading break details: {e}")
    
    def _calculate_break_times(self, break_entries: List[Dict]) -> Dict[str, int]:
        """Calculate total break and lunch times from time entries"""
        total_break_minutes = 0
        lunch_minutes = 0
        
        # Sort by timestamp
        break_entries.sort(key=lambda x: x['timestamp'])
        
        # Track break periods
        break_start = None
        
        for entry in break_entries:
            if entry['type'] == 'break_start':
                break_start = entry['timestamp']
            elif entry['type'] == 'break_end' and break_start:
                duration = (entry['timestamp'] - break_start).total_seconds() / 60
                
                # Categorize break type
                if entry['state_name'] and 'lunch' in entry['state_name'].lower():
                    lunch_minutes += duration
                else:
                    total_break_minutes += duration
                
                break_start = None
        
        return {
            'total_break_minutes': int(total_break_minutes),
            'lunch_minutes': int(lunch_minutes)
        }
    
    def _process_timetable_blocks(self,
                                 timetable_blocks: List[Dict[str, Any]],
                                 validation_period: Tuple[datetime, datetime]):
        """Process timetable blocks into employee work patterns (fallback method)"""
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
    
    async def _check_rest_periods(self):
        """Check minimum rest period between shifts with real-time alerts"""
        if ComplianceType.REST_PERIOD not in self.labor_standards:
            return
            
        standard = self.labor_standards[ComplianceType.REST_PERIOD]
        
        for employee_id, patterns in self.employee_patterns.items():
            for i in range(1, len(patterns)):
                prev_shift_end = patterns[i-1].shift_end
                curr_shift_start = patterns[i].shift_start
                
                if prev_shift_end and curr_shift_start:
                    rest_hours = (curr_shift_start - prev_shift_end).total_seconds() / 3600
                    
                    if rest_hours < standard.requirement_value:
                        # Enhanced corrective actions for mobile workers
                        corrective_actions = [
                            "Adjust shift start time",
                            "Reduce previous shift end time",
                            "Provide compensatory rest"
                        ]
                        
                        if employee_id in self.mobile_workers:
                            corrective_actions.extend([
                                "Consider travel time between locations",
                                "Adjust route planning for next day",
                                "Enable remote check-in flexibility"
                            ])
                        
                        violation = ComplianceViolation(
                            violation_id=f"REST_{employee_id}_{patterns[i].date}",
                            employee_id=employee_id,
                            violation_type=ComplianceType.REST_PERIOD,
                            violation_date=patterns[i].date,
                            severity=standard.severity_if_violated,
                            description=f"Insufficient rest period between shifts",
                            actual_value=f"{rest_hours:.1f} hours",
                            required_value=f"{standard.requirement_value} hours",
                            corrective_actions=corrective_actions,
                            mobile_worker=employee_id in self.mobile_workers
                        )
                        self.violations.append(violation)
                        
                        # Send real-time alert for critical violations
                        if standard.severity_if_violated == ViolationSeverity.CRITICAL:
                            await self._send_compliance_alert(violation)
    
    async def _check_daily_work_limits(self):
        """Check daily work hour limits with mobile worker considerations"""
        if ComplianceType.DAILY_WORK_LIMIT not in self.labor_standards:
            return
            
        standard = self.labor_standards[ComplianceType.DAILY_WORK_LIMIT]
        standard_hours, max_hours = standard.requirement_value
        
        for employee_id, patterns in self.employee_patterns.items():
            for pattern in patterns:
                # Adjust limits for mobile workers (consider travel time)
                effective_max_hours = max_hours
                if employee_id in self.mobile_workers:
                    effective_max_hours = max_hours - 1  # Account for travel time
                
                if pattern.total_hours > effective_max_hours:
                    severity = ViolationSeverity.CRITICAL
                    description = "Exceeded maximum daily work hours"
                elif pattern.total_hours > standard_hours:
                    severity = ViolationSeverity.LOW
                    description = "Exceeded standard daily work hours"
                else:
                    continue
                
                corrective_actions = [
                    "Reduce shift duration",
                    "Distribute work to other days",
                    "Ensure proper overtime authorization"
                ]
                
                if employee_id in self.mobile_workers:
                    corrective_actions.extend([
                        "Optimize route efficiency",
                        "Consider overnight accommodations",
                        "Adjust service area boundaries"
                    ])
                
                violation = ComplianceViolation(
                    violation_id=f"DAILY_{employee_id}_{pattern.date}",
                    employee_id=employee_id,
                    violation_type=ComplianceType.DAILY_WORK_LIMIT,
                    violation_date=pattern.date,
                    severity=severity,
                    description=description,
                    actual_value=f"{pattern.total_hours:.1f} hours",
                    required_value=f"{standard_hours} standard, {effective_max_hours} max",
                    corrective_actions=corrective_actions,
                    mobile_worker=employee_id in self.mobile_workers
                )
                self.violations.append(violation)
                
                # Send alert for critical violations
                if severity == ViolationSeverity.CRITICAL:
                    await self._send_compliance_alert(violation)
    
    async def _check_weekly_work_limits(self):
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
    
    async def _check_break_requirements(self):
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
    
    async def _check_lunch_requirements(self):
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
    
    async def _check_consecutive_days(self):
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
    
    async def _check_mobile_worker_compliance(self):
        """Check compliance specific to mobile workers"""
        for employee_id in self.mobile_workers:
            if employee_id not in self.employee_patterns:
                continue
            
            patterns = self.employee_patterns[employee_id]
            
            # Check for location-based compliance issues
            for pattern in patterns:
                # Check for excessive travel between locations
                await self._check_travel_time_compliance(employee_id, pattern)
                
                # Check for proper check-in/check-out at locations
                await self._check_location_compliance(employee_id, pattern)
    
    async def _check_travel_time_compliance(self, employee_id: str, pattern: EmployeeWorkPattern):
        """Check if travel time is properly accounted for in work hours"""
        try:
            if not self.db_connector:
                return
            
            # Get location changes for the day
            query = """
            SELECT 
                entry_timestamp,
                location_data,
                entry_type
            FROM time_entries
            WHERE employee_id = $1
            AND DATE(entry_timestamp) = $2
            AND location_data IS NOT NULL
            ORDER BY entry_timestamp
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query, employee_id, pattern.date)
                
                if len(rows) > 1:
                    # Calculate total travel time based on location changes
                    travel_violations = self._analyze_travel_patterns(rows, pattern)
                    self.violations.extend(travel_violations)
                    
        except Exception as e:
            logger.error(f"Error checking travel time compliance: {e}")
    
    def _analyze_travel_patterns(self, location_entries: List, pattern: EmployeeWorkPattern) -> List[ComplianceViolation]:
        """Analyze travel patterns for compliance violations"""
        violations = []
        
        for i in range(1, len(location_entries)):
            prev_entry = location_entries[i-1]
            curr_entry = location_entries[i]
            
            # Calculate time between location changes
            time_diff = (curr_entry['entry_timestamp'] - prev_entry['entry_timestamp']).total_seconds() / 60
            
            # If location changes are too frequent (less than 30 minutes)
            if time_diff < 30:
                violation = ComplianceViolation(
                    violation_id=f"TRAVEL_{pattern.employee_id}_{pattern.date}_{i}",
                    employee_id=pattern.employee_id,
                    violation_type=ComplianceType.BREAK_REQUIREMENT,  # Using break requirement as closest match
                    violation_date=pattern.date,
                    severity=ViolationSeverity.MEDIUM,
                    description="Insufficient time between location changes",
                    actual_value=f"{time_diff:.0f} minutes",
                    required_value="30 minutes minimum",
                    corrective_actions=[
                        "Allow more time between locations",
                        "Optimize route planning",
                        "Consider grouping nearby appointments"
                    ],
                    mobile_worker=True,
                    location_data={
                        'prev_location': prev_entry['location_data'],
                        'curr_location': curr_entry['location_data']
                    }
                )
                violations.append(violation)
        
        return violations
    
    async def _check_location_compliance(self, employee_id: str, pattern: EmployeeWorkPattern):
        """Check proper check-in/check-out at work locations"""
        try:
            if not self.db_connector:
                return
            
            # Check for missing location data during work hours
            query = """
            SELECT COUNT(*) as missing_locations
            FROM time_entries
            WHERE employee_id = $1
            AND DATE(entry_timestamp) = $2
            AND entry_type IN ('clock_in', 'clock_out')
            AND location_data IS NULL
            """
            
            async with self.db_connector.pool.acquire() as conn:
                result = await conn.fetchval(query, employee_id, pattern.date)
                
                if result > 0:
                    violation = ComplianceViolation(
                        violation_id=f"LOCATION_{employee_id}_{pattern.date}",
                        employee_id=employee_id,
                        violation_type=ComplianceType.BREAK_REQUIREMENT,
                        violation_date=pattern.date,
                        severity=ViolationSeverity.MEDIUM,
                        description="Missing location data for mobile worker check-in/out",
                        actual_value=f"{result} missing location records",
                        required_value="All check-ins/outs must have location data",
                        corrective_actions=[
                            "Enable GPS tracking on mobile device",
                            "Verify location services are enabled",
                            "Provide training on proper check-in procedures"
                        ],
                        mobile_worker=True
                    )
                    self.violations.append(violation)
                    
        except Exception as e:
            logger.error(f"Error checking location compliance: {e}")
    
    async def _send_compliance_alert(self, violation: ComplianceViolation):
        """Send real-time compliance alert to database"""
        try:
            if not self.db_connector:
                return
            
            # Insert alert into quality_alerts table
            query = """
            INSERT INTO quality_alerts (
                alert_type,
                severity,
                alert_title,
                alert_description,
                affected_entity_type,
                affected_entity_id,
                trigger_metric,
                trigger_value,
                threshold_value,
                alert_data,
                alert_status
            ) VALUES (
                'compliance_violation',
                $1,
                $2,
                $3,
                'agent',
                $4,
                $5,
                $6,
                $7,
                $8,
                'active'
            )
            """
            
            severity_map = {
                ViolationSeverity.CRITICAL: 'critical',
                ViolationSeverity.HIGH: 'high',
                ViolationSeverity.MEDIUM: 'medium',
                ViolationSeverity.LOW: 'low'
            }
            
            alert_data = {
                'violation_id': violation.violation_id,
                'violation_type': violation.violation_type.value,
                'mobile_worker': violation.mobile_worker,
                'corrective_actions': violation.corrective_actions,
                'location_data': violation.location_data
            }
            
            async with self.db_connector.pool.acquire() as conn:
                await conn.execute(
                    query,
                    severity_map[violation.severity],
                    f"Compliance Violation: {violation.violation_type.value}",
                    violation.description,
                    violation.employee_id,
                    violation.violation_type.value,
                    str(violation.actual_value),
                    str(violation.required_value),
                    json.dumps(alert_data)
                )
            
            violation.alert_sent = True
            logger.info(f"Sent compliance alert for violation {violation.violation_id}")
            
        except Exception as e:
            logger.error(f"Error sending compliance alert: {e}")
    
    async def _store_violations_in_database(self):
        """Store compliance violations in database for tracking"""
        try:
            if not self.db_connector or not self.violations:
                return
            
            # Update compliance tracking with violations
            for violation in self.violations:
                await self._update_compliance_tracking(violation)
            
            logger.info(f"Stored {len(self.violations)} violations in database")
            
        except Exception as e:
            logger.error(f"Error storing violations in database: {e}")
    
    async def _update_compliance_tracking(self, violation: ComplianceViolation):
        """Update compliance tracking record with violation"""
        try:
            # Find relevant compliance tracking record
            query = """
            UPDATE compliance_tracking
            SET 
                violations_count = violations_count + 1,
                recent_violations = COALESCE(recent_violations, '[]'::jsonb) || $1::jsonb,
                current_status = CASE 
                    WHEN $2 = 'critical' THEN 'non_compliant'
                    WHEN $2 = 'high' AND current_status = 'compliant' THEN 'remediation_required'
                    ELSE current_status
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE compliance_type IN ('regulatory', 'internal_policy')
            AND compliance_name ILIKE $3
            """
            
            violation_data = {
                'violation_id': violation.violation_id,
                'employee_id': violation.employee_id,
                'date': violation.violation_date.isoformat(),
                'description': violation.description,
                'severity': violation.severity.value
            }
            
            severity_map = {
                ViolationSeverity.CRITICAL: 'critical',
                ViolationSeverity.HIGH: 'high',
                ViolationSeverity.MEDIUM: 'medium',
                ViolationSeverity.LOW: 'low'
            }
            
            search_term = f"%{violation.violation_type.value.replace('_', ' ')}%"
            
            async with self.db_connector.pool.acquire() as conn:
                await conn.execute(
                    query,
                    json.dumps(violation_data),
                    severity_map[violation.severity],
                    search_term
                )
                
        except Exception as e:
            logger.error(f"Error updating compliance tracking: {e}")
    
    async def _generate_compliance_report(self, validation_period: Tuple[datetime, datetime]) -> ComplianceReport:
        """Generate comprehensive compliance report with mobile workforce insights"""
        # Count violations by type and severity
        violations_by_type = defaultdict(int)
        violations_by_severity = defaultdict(int)
        mobile_violations = 0
        
        for violation in self.violations:
            violations_by_type[violation.violation_type] += 1
            violations_by_severity[violation.severity] += 1
            if violation.mobile_worker:
                mobile_violations += 1
        
        # Calculate compliance score
        total_checks = len(self.employee_patterns) * len(self.labor_standards)
        compliance_score = ((total_checks - len(self.violations)) / total_checks * 100) if total_checks > 0 else 100
        
        # Generate recommendations
        recommendations = await self._generate_recommendations(violations_by_type, violations_by_severity)
        
        # Add mobile workforce specific recommendations
        if mobile_violations > 0:
            recommendations.extend([
                f"Review mobile workforce policies ({mobile_violations} mobile worker violations)",
                "Consider implementing GPS-based compliance monitoring",
                "Provide mobile-specific compliance training"
            ])
        
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
    
    async def _generate_recommendations(self,
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
    
    async def enable_real_time_monitoring(self, callback_func=None, interval_seconds: int = 300):
        """Enable real-time compliance monitoring with periodic checks"""
        if not self.db_connector:
            logger.warning("Real-time monitoring requires database connection")
            return
        
        self.real_time_monitoring = True
        logger.info(f"Enabled real-time compliance monitoring (checking every {interval_seconds} seconds)")
        
        async def monitoring_loop():
            while self.real_time_monitoring:
                try:
                    # Validate compliance for the last hour
                    end_time = datetime.now()
                    start_time = end_time - timedelta(hours=1)
                    
                    report = await self.validate_timetable(
                        validation_period=(start_time, end_time),
                        use_real_time_data=True
                    )
                    
                    # Call callback if provided
                    if callback_func and report.total_violations > 0:
                        await callback_func(report)
                    
                    # Log monitoring results
                    if report.total_violations > 0:
                        logger.warning(f"Real-time monitoring found {report.total_violations} compliance violations")
                    
                except Exception as e:
                    logger.error(f"Error in real-time monitoring: {e}")
                
                await asyncio.sleep(interval_seconds)
        
        # Start monitoring in background
        asyncio.create_task(monitoring_loop())
    
    def disable_real_time_monitoring(self):
        """Disable real-time compliance monitoring"""
        self.real_time_monitoring = False
        logger.info("Disabled real-time compliance monitoring")
    
    async def get_compliance_dashboard_data(self) -> Dict[str, Any]:
        """Get comprehensive compliance dashboard data"""
        try:
            if not self.db_connector:
                return {"error": "Database connection required"}
            
            dashboard_data = {
                "total_employees": len(self.employee_patterns),
                "mobile_workers": len(self.mobile_workers),
                "active_violations": len([v for v in self.violations if not v.auto_resolved]),
                "critical_violations": len([v for v in self.violations if v.severity == ViolationSeverity.CRITICAL]),
                "compliance_standards": len(self.labor_standards),
                "last_updated": datetime.now().isoformat()
            }
            
            # Get compliance trends from database
            trends = await self._get_compliance_trends()
            dashboard_data["trends"] = trends
            
            return dashboard_data
            
        except Exception as e:
            logger.error(f"Error getting dashboard data: {e}")
            return {"error": str(e)}
    
    async def _get_compliance_trends(self) -> Dict[str, Any]:
        """Get compliance trends from database"""
        try:
            query = """
            SELECT 
                DATE(created_at) as violation_date,
                COUNT(*) as violation_count,
                severity
            FROM quality_alerts
            WHERE alert_type = 'compliance_violation'
            AND created_at >= NOW() - INTERVAL '30 days'
            GROUP BY DATE(created_at), severity
            ORDER BY violation_date DESC
            """
            
            async with self.db_connector.pool.acquire() as conn:
                rows = await conn.fetch(query)
                
                trends = {
                    "daily_violations": [],
                    "severity_distribution": defaultdict(int)
                }
                
                for row in rows:
                    trends["daily_violations"].append({
                        "date": row["violation_date"].isoformat(),
                        "count": row["violation_count"],
                        "severity": row["severity"]
                    })
                    trends["severity_distribution"][row["severity"]] += row["violation_count"]
                
                return dict(trends)
                
        except Exception as e:
            logger.error(f"Error getting compliance trends: {e}")
            return {}


# Factory function for creating enhanced compliance validator
async def create_compliance_validator(use_database: bool = True) -> ComplianceValidator:
    """Create a compliance validator with optional database integration"""
    try:
        if use_database and get_connector:
            db_connector = await get_connector()
            validator = ComplianceValidator(db_connector)
            
            # Initialize from database
            if hasattr(validator, '_initialize_from_database'):
                await validator._initialize_from_database()
            
            logger.info("Created compliance validator with database integration")
            return validator
        else:
            # Fallback to basic validator
            validator = ComplianceValidator()
            logger.info("Created basic compliance validator (no database)")
            return validator
            
    except Exception as e:
        logger.error(f"Error creating compliance validator: {e}")
        # Return basic validator as fallback
        return ComplianceValidator()


# Utility function for mobile workforce compliance checking
async def check_mobile_worker_compliance(employee_id: str, 
                                       validation_period: Tuple[datetime, datetime] = None) -> Dict[str, Any]:
    """Quick compliance check for a specific mobile worker"""
    try:
        validator = await create_compliance_validator(use_database=True)
        
        if validation_period is None:
            end_time = datetime.now()
            start_time = end_time - timedelta(days=1)
            validation_period = (start_time, end_time)
        
        # Validate compliance
        report = await validator.validate_timetable(
            validation_period=validation_period,
            use_real_time_data=True
        )
        
        # Filter for specific employee
        employee_violations = [v for v in report.violations if v.employee_id == employee_id]
        mobile_violations = [v for v in employee_violations if v.mobile_worker]
        
        return {
            "employee_id": employee_id,
            "total_violations": len(employee_violations),
            "mobile_violations": len(mobile_violations),
            "compliance_score": 100 - (len(employee_violations) * 10),  # Simplified scoring
            "violations": [
                {
                    "type": v.violation_type.value,
                    "severity": v.severity.value,
                    "description": v.description,
                    "corrective_actions": v.corrective_actions
                }
                for v in employee_violations
            ]
        }
        
    except Exception as e:
        logger.error(f"Error checking mobile worker compliance: {e}")
        return {"error": str(e)}