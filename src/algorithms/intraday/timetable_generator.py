#!/usr/bin/env python3
"""
Timetable Generator for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Create Detailed Daily Timetables, Break Optimization, Multi-skill Planning
"""

import numpy as np
from datetime import datetime, timedelta, time, date
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import pandas as pd
from copy import deepcopy
import asyncio

# Import the database service
from .timetable_database_service import (
    TimetableDatabaseService, 
    ScheduleTemplate as DBScheduleTemplate,
    EmployeeAvailability,
    ScheduleShift
)

logger = logging.getLogger(__name__)

class ActivityType(Enum):
    """Types of activities in timetable"""
    WORK_ATTENDANCE = "work_attendance"
    LUNCH_BREAK = "lunch_break"
    SHORT_BREAK = "short_break"
    TRAINING = "training"
    MEETING = "meeting"
    PROJECT_WORK = "project_work"
    DOWNTIME = "downtime"
    NOT_AVAILABLE = "not_available"

class OptimizationCriteria(Enum):
    """Optimization criteria for timetable generation"""
    SERVICE_LEVEL_80_20 = "80_20_format"  # 80% calls in 20 seconds
    COVERAGE_MAXIMIZATION = "coverage_max"
    COST_MINIMIZATION = "cost_min"
    WORKLOAD_BALANCE = "workload_balance"

@dataclass
class WorkScheduleEntry:
    """Individual work schedule entry"""
    employee_id: str
    date: datetime
    shift_start: time
    shift_end: time
    skills: List[str]
    availability_percentage: float = 100.0
    employee_constraints: Optional[Dict[str, Any]] = None
    schedule_preferences: Optional[List[Dict[str, Any]]] = None

@dataclass
class ForecastData:
    """Forecast data for workload analysis"""
    datetime: datetime
    interval: int  # 15-minute interval number
    call_volume: float
    average_handle_time: float
    required_agents: float
    service_level_target: float = 80.0

@dataclass
class TimetableBlock:
    """Individual timetable block (15-minute interval)"""
    employee_id: str
    datetime: datetime
    interval_start: time
    interval_end: time
    activity_type: ActivityType
    skill_assigned: Optional[str] = None
    project_id: Optional[str] = None
    break_type: Optional[str] = None
    locked: bool = False  # Cannot be modified

@dataclass
class TimetableTemplate:
    """Template for timetable generation"""
    template_name: str
    break_rules: Dict[str, Any]
    lunch_rules: Dict[str, Any]
    activity_distribution: Dict[ActivityType, float]
    optimization_criteria: OptimizationCriteria

@dataclass
class BreakRule:
    """Break scheduling rules"""
    break_duration: int  # minutes
    frequency_hours: float  # every X hours
    spacing_minutes: int  # minimum time between breaks
    max_delay_minutes: int  # maximum delay from scheduled time

@dataclass
class LunchRule:
    """Lunch scheduling rules"""
    min_duration: int = 30  # minutes
    max_duration: int = 60
    earliest_start: time = time(11, 0)
    latest_start: time = time(14, 0)
    min_hours_before: float = 2.0  # minimum hours worked before lunch

class TimetableGenerator:
    """Generate optimal daily timetables from work schedules using Mobile Workforce Scheduler pattern"""
    
    def __init__(self):
        self.work_schedules: List[WorkScheduleEntry] = []
        self.forecast_data: List[ForecastData] = []
        self.timetable_blocks: List[TimetableBlock] = []
        self.templates: Dict[str, TimetableTemplate] = {}
        self.break_rules: Dict[str, BreakRule] = {}
        self.lunch_rules: Dict[str, LunchRule] = {}
        
        # Database service for real data
        self.db_service = TimetableDatabaseService()
        self.db_initialized = False
        
        # Cache for database objects
        self.db_templates: Dict[str, DBScheduleTemplate] = {}
        self.employee_availability: Dict[str, EmployeeAvailability] = {}
        self.constraint_rules: Dict[str, Dict[str, Any]] = {}
        
        self._initialize_default_rules()
        
    async def _ensure_db_initialized(self):
        """Ensure database service is initialized"""
        if not self.db_initialized:
            await self.db_service.initialize()
            await self._load_constraint_rules()
            self.db_initialized = True
    
    async def _load_constraint_rules(self):
        """Load constraint rules from database"""
        try:
            self.constraint_rules = await self.db_service.get_constraint_rules()
            self._initialize_rules_from_db()
        except Exception as e:
            logger.warning(f"Failed to load constraint rules from DB: {e}")
            self._initialize_default_rules()
    
    def _initialize_rules_from_db(self):
        """Initialize rules from database constraint rules"""
        break_rules = self.constraint_rules.get('break_rules', {})
        
        # Initialize break rule from database
        self.break_rules['default'] = BreakRule(
            break_duration=break_rules.get('short_break_duration', 15),
            frequency_hours=break_rules.get('short_break_frequency', 2.0),
            spacing_minutes=90,
            max_delay_minutes=30
        )
        
        # Initialize lunch rule from database
        self.lunch_rules['default'] = LunchRule(
            min_duration=break_rules.get('lunch_break_min_duration', 30),
            max_duration=break_rules.get('lunch_break_max_duration', 60),
            earliest_start=break_rules.get('lunch_earliest_start', time(11, 0)),
            latest_start=break_rules.get('lunch_latest_start', time(14, 0)),
            min_hours_before=break_rules.get('min_work_before_lunch', 2.0)
        )
    
    def _initialize_default_rules(self):
        """Initialize default break and lunch rules as fallback"""
        # Default break rule: 15 minutes every 2 hours
        self.break_rules['default'] = BreakRule(
            break_duration=15,
            frequency_hours=2.0,
            spacing_minutes=90,
            max_delay_minutes=30
        )
        
        # Default lunch rule
        self.lunch_rules['default'] = LunchRule()
        
        # Technical Support Teams template from BDD
        self.templates['Technical Support Teams'] = TimetableTemplate(
            template_name='Technical Support Teams',
            break_rules={'rule': 'default'},
            lunch_rules={'rule': 'default'},
            activity_distribution={
                ActivityType.WORK_ATTENDANCE: 0.85,
                ActivityType.LUNCH_BREAK: 0.05,
                ActivityType.SHORT_BREAK: 0.075,
                ActivityType.TRAINING: 0.025
            },
            optimization_criteria=OptimizationCriteria.SERVICE_LEVEL_80_20
        )
    
    async def create_timetable(self,
                              period_start: datetime,
                              period_end: datetime,
                              template_name: str,
                              work_schedules: Optional[List[WorkScheduleEntry]] = None,
                              forecast_data: Optional[List[ForecastData]] = None,
                              optimization_enabled: bool = True,
                              department_id: Optional[str] = None) -> List[TimetableBlock]:
        """Create detailed timetables for the period using real database data"""
        await self._ensure_db_initialized()
        
        # Load real data from database if not provided
        if work_schedules is None:
            work_schedules = await self._load_work_schedules_from_db(
                period_start.date(), period_end.date(), department_id
            )
        
        if forecast_data is None:
            forecast_data = await self._load_forecast_data_from_db(
                period_start.date(), period_end.date()
            )
        
        self.work_schedules = work_schedules
        self.forecast_data = forecast_data
        self.timetable_blocks = []
        
        # Try to get template from database first
        template = await self._get_template_from_db(template_name)
        if not template:
            # Fallback to in-memory templates
            template = self.templates.get(template_name)
            if not template:
                raise ValueError(f"Template {template_name} not found in database or memory")
        
        # Generate timetable for each day in period
        current_date = period_start.date()
        while current_date <= period_end.date():
            daily_schedules = [
                ws for ws in work_schedules 
                if ws.date.date() == current_date
            ]
            
            if daily_schedules:
                daily_blocks = self._generate_daily_timetable(
                    date=datetime.combine(current_date, time(0, 0)),
                    schedules=daily_schedules,
                    template=template,
                    optimization_enabled=optimization_enabled
                )
                self.timetable_blocks.extend(daily_blocks)
            
            current_date += timedelta(days=1)
        
        return self.timetable_blocks
    
    def _generate_daily_timetable(self,
                                date: datetime,
                                schedules: List[WorkScheduleEntry],
                                template: TimetableTemplate,
                                optimization_enabled: bool) -> List[TimetableBlock]:
        """Generate timetable for a single day"""
        daily_blocks = []
        
        for schedule in schedules:
            employee_blocks = self._generate_employee_timetable(
                schedule=schedule,
                template=template,
                date=date
            )
            
            if optimization_enabled:
                employee_blocks = self._optimize_employee_timetable(
                    blocks=employee_blocks,
                    schedule=schedule,
                    template=template
                )
            
            daily_blocks.extend(employee_blocks)
        
        # Apply global optimization if enabled
        if optimization_enabled and template.optimization_criteria == OptimizationCriteria.SERVICE_LEVEL_80_20:
            daily_blocks = self._optimize_for_service_level(daily_blocks, date)
        
        return daily_blocks
    
    async def _load_work_schedules_from_db(self, 
                                          start_date: date, 
                                          end_date: date,
                                          department_id: Optional[str] = None) -> List[WorkScheduleEntry]:
        """Load work schedules from database using employee availability and shifts"""
        try:
            # Get employee availability
            self.employee_availability = await self.db_service.get_employee_availability(
                start_date, end_date, department_id
            )
            
            # Get existing shifts
            employee_ids = list(self.employee_availability.keys())
            shifts_by_employee = await self.db_service.get_schedule_shifts(
                start_date, end_date, employee_ids
            )
            
            work_schedules = []
            
            # Convert database data to WorkScheduleEntry objects
            for employee_id, availability in self.employee_availability.items():
                shifts = shifts_by_employee.get(employee_id, [])
                
                # Extract skills list
                skills = [skill['name'] for skill in availability.skills]
                
                # Create schedule entries for each shift
                for shift in shifts:
                    if shift.status in ['scheduled', 'confirmed']:
                        schedule_entry = WorkScheduleEntry(
                            employee_id=employee_id,
                            date=datetime.combine(shift.shift_date, time(0, 0)),
                            shift_start=shift.start_time,
                            shift_end=shift.end_time,
                            skills=skills,
                            availability_percentage=availability.work_rate * 100,
                            employee_constraints={
                                'max_daily_hours': availability.max_daily_hours,
                                'max_weekly_hours': availability.max_weekly_hours,
                                'night_work_allowed': availability.night_work_allowed,
                                'weekend_work_allowed': availability.weekend_work_allowed,
                                'overtime_allowed': availability.overtime_allowed
                            },
                            schedule_preferences=availability.schedule_preferences
                        )
                        work_schedules.append(schedule_entry)
            
            logger.info(f"Loaded {len(work_schedules)} work schedules from database")
            return work_schedules
            
        except Exception as e:
            logger.error(f"Error loading work schedules from database: {str(e)}")
            return []
    
    async def _load_forecast_data_from_db(self, 
                                         start_date: date, 
                                         end_date: date) -> List[ForecastData]:
        """Load forecast data from database"""
        try:
            forecast_requirements = await self.db_service.get_forecast_requirements(
                start_date, end_date
            )
            
            forecast_data = []
            
            for date_str, intervals in forecast_requirements.items():
                forecast_date = datetime.fromisoformat(date_str).date()
                
                for interval_req in intervals:
                    # Convert interval_start to datetime and interval number
                    interval_time = interval_req['interval_start']
                    forecast_datetime = datetime.combine(forecast_date, interval_time)
                    
                    # Calculate 15-minute interval number (assuming day starts at 00:00)
                    interval_number = (interval_time.hour * 4) + (interval_time.minute // 15)
                    
                    forecast_entry = ForecastData(
                        datetime=forecast_datetime,
                        interval=interval_number,
                        call_volume=interval_req['call_volume'],
                        average_handle_time=interval_req['average_handle_time'],
                        required_agents=float(interval_req['required_agents']),
                        service_level_target=interval_req['service_level_target'] * 100  # Convert to percentage
                    )
                    
                    forecast_data.append(forecast_entry)
            
            logger.info(f"Loaded {len(forecast_data)} forecast data points from database")
            return forecast_data
            
        except Exception as e:
            logger.error(f"Error loading forecast data from database: {str(e)}")
            return []
    
    async def _get_template_from_db(self, template_name: str) -> Optional[TimetableTemplate]:
        """Get template from database and convert to internal format"""
        try:
            if not self.db_templates:
                self.db_templates = await self.db_service.get_schedule_templates()
            
            # Look for template by name or code
            db_template = None
            for template_code, template in self.db_templates.items():
                if template.template_name == template_name or template_code == template_name:
                    db_template = template
                    break
            
            if not db_template:
                return None
            
            # Convert database template to internal format
            return TimetableTemplate(
                template_name=db_template.template_name,
                break_rules={'rule': 'default'},
                lunch_rules={'rule': 'default'},
                activity_distribution={
                    ActivityType.WORK_ATTENDANCE: 0.85,
                    ActivityType.LUNCH_BREAK: db_template.break_minutes / (db_template.hours_per_day * 60),
                    ActivityType.SHORT_BREAK: 0.075,
                    ActivityType.TRAINING: 0.025
                },
                optimization_criteria=OptimizationCriteria.SERVICE_LEVEL_80_20
            )
            
        except Exception as e:
            logger.error(f"Error getting template from database: {str(e)}")
            return None
    
    async def save_timetable_to_db(self, template_code: str) -> List[str]:
        """Save generated timetable blocks to database"""
        try:
            # Convert timetable blocks to database format
            db_blocks = []
            
            for block in self.timetable_blocks:
                db_block = {
                    'employee_id': block.employee_id,
                    'block_date': block.datetime.date(),
                    'interval_start': block.interval_start,
                    'interval_end': block.interval_end,
                    'activity_type': block.activity_type.value,
                    'skill_assigned': block.skill_assigned,
                    'project_id': block.project_id,
                    'break_type': block.break_type,
                    'is_locked': block.locked
                }
                db_blocks.append(db_block)
            
            # Save to database
            created_ids = await self.db_service.save_timetable_blocks(db_blocks, template_code)
            
            logger.info(f"Saved {len(created_ids)} timetable blocks to database")
            return created_ids
            
        except Exception as e:
            logger.error(f"Error saving timetable to database: {str(e)}")
            return []
    
    async def close_db_connection(self):
        """Close database connection"""
        if self.db_service:
            await self.db_service.close()
    
    def _generate_employee_timetable(self,
                                   schedule: WorkScheduleEntry,
                                   template: TimetableTemplate,
                                   date: datetime) -> List[TimetableBlock]:
        """Generate initial timetable for an employee with real constraints"""
        blocks = []
        
        # Get employee constraints
        constraints = schedule.employee_constraints or {}
        preferences = schedule.schedule_preferences or []
        
        # Calculate shift duration and intervals
        shift_start_dt = datetime.combine(date.date(), schedule.shift_start)
        shift_end_dt = datetime.combine(date.date(), schedule.shift_end)
        
        # Handle overnight shifts
        if shift_end_dt <= shift_start_dt:
            shift_end_dt += timedelta(days=1)
        
        # Validate shift duration against constraints
        shift_hours = (shift_end_dt - shift_start_dt).total_seconds() / 3600
        max_daily_hours = constraints.get('max_daily_hours', 8)
        
        if shift_hours > max_daily_hours and not constraints.get('overtime_allowed', False):
            logger.warning(f"Shift duration {shift_hours:.1f}h exceeds max daily hours {max_daily_hours}h for employee {schedule.employee_id}")
            # Adjust shift end time
            shift_end_dt = shift_start_dt + timedelta(hours=max_daily_hours)
        
        # Check for schedule preferences for this date
        date_preferences = [
            pref for pref in preferences 
            if pref.get('date') == date.date()
        ]
        
        # Apply preferences if any
        if date_preferences:
            pref = date_preferences[0]  # Take first preference
            if pref.get('day_type') == 'Day off':
                # Employee requested day off - mark as not available
                return self._create_unavailable_blocks(shift_start_dt, shift_end_dt, schedule.employee_id)
            
            # Adjust shift times based on preferences
            if pref.get('preferred_start_time') and pref.get('preferred_end_time'):
                preferred_start = datetime.combine(date.date(), pref['preferred_start_time'])
                preferred_end = datetime.combine(date.date(), pref['preferred_end_time'])
                
                # Use preferred times if they're reasonable (within 2 hours of scheduled)
                if abs((preferred_start - shift_start_dt).total_seconds()) <= 7200:  # 2 hours
                    shift_start_dt = preferred_start
                if abs((preferred_end - shift_end_dt).total_seconds()) <= 7200:
                    shift_end_dt = preferred_end
        
        # Generate 15-minute blocks
        current_time = shift_start_dt
        interval_count = 0
        
        while current_time < shift_end_dt:
            interval_end = current_time + timedelta(minutes=15)
            
            # Determine primary skill based on availability and rotation
            primary_skill = self._get_optimal_skill_for_interval(
                schedule.skills, current_time, interval_count
            )
            
            # Default to work attendance
            block = TimetableBlock(
                employee_id=schedule.employee_id,
                datetime=current_time,
                interval_start=current_time.time(),
                interval_end=interval_end.time(),
                activity_type=ActivityType.WORK_ATTENDANCE,
                skill_assigned=primary_skill
            )
            
            blocks.append(block)
            current_time = interval_end
            interval_count += 1
        
        # Apply constraint-based scheduling
        blocks = self._apply_constraint_based_scheduling(blocks, constraints)
        
        # Schedule lunch break with constraints
        blocks = self._schedule_lunch_with_constraints(blocks, template.lunch_rules, constraints)
        
        # Schedule short breaks with constraints  
        blocks = self._schedule_breaks_with_constraints(blocks, template.break_rules, constraints)
        
        return blocks
    
    def _create_unavailable_blocks(self, 
                                  start_dt: datetime, 
                                  end_dt: datetime, 
                                  employee_id: str) -> List[TimetableBlock]:
        """Create unavailable blocks for requested day off"""
        blocks = []
        current_time = start_dt
        
        while current_time < end_dt:
            interval_end = current_time + timedelta(minutes=15)
            
            block = TimetableBlock(
                employee_id=employee_id,
                datetime=current_time,
                interval_start=current_time.time(),
                interval_end=interval_end.time(),
                activity_type=ActivityType.NOT_AVAILABLE,
                locked=True  # Lock unavailable blocks
            )
            
            blocks.append(block)
            current_time = interval_end
        
        return blocks
    
    def _get_optimal_skill_for_interval(self, 
                                       skills: List[str], 
                                       current_time: datetime, 
                                       interval_count: int) -> Optional[str]:
        """Determine optimal skill assignment for current interval"""
        if not skills:
            return None
        
        # For multi-skilled employees, rotate skills throughout the day
        if len(skills) > 1:
            # Primary skill gets 70% of time, others split remaining 30%
            if interval_count % 10 < 7:  # 70% primary skill
                return skills[0]
            else:
                # Rotate through secondary skills
                secondary_idx = (interval_count // 10) % (len(skills) - 1)
                return skills[1 + secondary_idx]
        
        return skills[0]
    
    def _apply_constraint_based_scheduling(self, 
                                         blocks: List[TimetableBlock], 
                                         constraints: Dict[str, Any]) -> List[TimetableBlock]:
        """Apply constraint-based adjustments to schedule"""
        # Check night work constraints
        if not constraints.get('night_work_allowed', True):
            for block in blocks:
                # Consider 22:00-06:00 as night hours
                hour = block.interval_start.hour
                if hour >= 22 or hour < 6:
                    block.activity_type = ActivityType.NOT_AVAILABLE
                    block.locked = True
        
        # Check weekend work constraints  
        if not constraints.get('weekend_work_allowed', True):
            weekday = blocks[0].datetime.weekday()
            if weekday >= 5:  # Saturday (5) or Sunday (6)
                for block in blocks:
                    block.activity_type = ActivityType.NOT_AVAILABLE
                    block.locked = True
        
        return blocks
    
    def _schedule_lunch_with_constraints(self, 
                                       blocks: List[TimetableBlock], 
                                       lunch_rules: Dict[str, Any],
                                       constraints: Dict[str, Any]) -> List[TimetableBlock]:
        """Schedule lunch break with employee constraints"""
        rule_name = lunch_rules.get('rule', 'default')
        rule = self.lunch_rules.get(rule_name, self.lunch_rules['default'])
        
        # Skip if shift is too short
        work_blocks = [b for b in blocks if b.activity_type == ActivityType.WORK_ATTENDANCE]
        if len(work_blocks) < 20:  # Less than 5 hours shift
            return blocks
        
        # Find eligible lunch window considering constraints
        eligible_start_idx = int(rule.min_hours_before * 4)  # 4 blocks per hour
        
        # Find blocks within lunch time window
        lunch_candidates = []
        for i, block in enumerate(blocks[eligible_start_idx:], eligible_start_idx):
            if (rule.earliest_start <= block.interval_start <= rule.latest_start and
                block.activity_type == ActivityType.WORK_ATTENDANCE):
                lunch_candidates.append(i)
        
        if not lunch_candidates:
            return blocks
        
        # Select optimal lunch start (prefer middle of window)
        lunch_start_idx = lunch_candidates[len(lunch_candidates) // 2]
        lunch_duration_blocks = rule.min_duration // 15
        
        # Ensure lunch doesn't exceed max daily hours constraint
        max_daily_hours = constraints.get('max_daily_hours', 8)
        total_shift_blocks = len([b for b in blocks if b.activity_type != ActivityType.NOT_AVAILABLE])
        max_work_blocks = int((max_daily_hours * 4) - lunch_duration_blocks)
        
        if total_shift_blocks > max_work_blocks:
            # Adjust lunch duration or skip
            available_lunch_blocks = total_shift_blocks - max_work_blocks
            lunch_duration_blocks = min(lunch_duration_blocks, available_lunch_blocks)
        
        # Mark lunch blocks
        for i in range(lunch_start_idx, min(lunch_start_idx + lunch_duration_blocks, len(blocks))):
            if blocks[i].activity_type == ActivityType.WORK_ATTENDANCE:
                blocks[i].activity_type = ActivityType.LUNCH_BREAK
                blocks[i].break_type = 'lunch'
        
        return blocks
    
    def _schedule_breaks_with_constraints(self, 
                                        blocks: List[TimetableBlock], 
                                        break_rules: Dict[str, Any],
                                        constraints: Dict[str, Any]) -> List[TimetableBlock]:
        """Schedule short breaks with employee constraints"""
        rule_name = break_rules.get('rule', 'default')
        rule = self.break_rules.get(rule_name, self.break_rules['default'])
        
        blocks_per_break = int(rule.frequency_hours * 4)  # 4 blocks per hour
        break_duration_blocks = rule.break_duration // 15
        
        # Consider max consecutive work constraint from database
        max_consecutive_work = self.constraint_rules.get('break_rules', {}).get('max_consecutive_work', 4.0)
        max_consecutive_blocks = int(max_consecutive_work * 4)
        
        # Track last break time
        last_break_idx = -1
        work_block_count = 0
        
        for i in range(len(blocks)):
            if blocks[i].activity_type == ActivityType.WORK_ATTENDANCE:
                work_block_count += 1
                
                # Force break if max consecutive work reached
                if work_block_count >= max_consecutive_blocks:
                    if self._schedule_break_at_index(blocks, i, break_duration_blocks):
                        last_break_idx = i
                        work_block_count = 0
                        continue
                
                # Regular break scheduling
                if (i >= blocks_per_break and 
                    (last_break_idx < 0 or i - last_break_idx >= (rule.spacing_minutes // 15))):
                    
                    if self._schedule_break_at_index(blocks, i, break_duration_blocks):
                        last_break_idx = i
                        work_block_count = 0
            else:
                work_block_count = 0  # Reset count for non-work blocks
        
        return blocks
    
    def _schedule_break_at_index(self, 
                               blocks: List[TimetableBlock], 
                               start_idx: int, 
                               duration_blocks: int) -> bool:
        """Schedule break at specific index if possible"""
        # Check if break can be scheduled
        if start_idx + duration_blocks > len(blocks):
            return False
        
        # Check if all blocks are available for break
        for i in range(start_idx, start_idx + duration_blocks):
            if blocks[i].activity_type != ActivityType.WORK_ATTENDANCE:
                return False
        
        # Schedule the break
        for i in range(start_idx, start_idx + duration_blocks):
            blocks[i].activity_type = ActivityType.SHORT_BREAK
            blocks[i].break_type = 'short'
        
        return True
    
    def _schedule_lunch(self,
                       blocks: List[TimetableBlock],
                       lunch_rules: Dict[str, Any]) -> List[TimetableBlock]:
        """Schedule lunch break according to rules"""
        rule_name = lunch_rules.get('rule', 'default')
        rule = self.lunch_rules.get(rule_name, self.lunch_rules['default'])
        
        if len(blocks) < 20:  # Less than 5 hours shift
            return blocks
        
        # Find eligible lunch window
        eligible_start_idx = int(rule.min_hours_before * 4)  # 4 blocks per hour
        
        # Find blocks within lunch time window
        lunch_candidates = []
        for i, block in enumerate(blocks[eligible_start_idx:], eligible_start_idx):
            if (rule.earliest_start <= block.interval_start <= rule.latest_start and
                block.activity_type == ActivityType.WORK_ATTENDANCE):
                lunch_candidates.append(i)
        
        if not lunch_candidates:
            return blocks
        
        # Select optimal lunch start (middle of window)
        lunch_start_idx = lunch_candidates[len(lunch_candidates) // 2]
        lunch_duration_blocks = rule.min_duration // 15
        
        # Mark lunch blocks
        for i in range(lunch_start_idx, min(lunch_start_idx + lunch_duration_blocks, len(blocks))):
            if blocks[i].activity_type == ActivityType.WORK_ATTENDANCE:
                blocks[i].activity_type = ActivityType.LUNCH_BREAK
                blocks[i].break_type = 'lunch'
        
        return blocks
    
    def _schedule_breaks(self,
                        blocks: List[TimetableBlock],
                        break_rules: Dict[str, Any]) -> List[TimetableBlock]:
        """Schedule short breaks according to rules"""
        rule_name = break_rules.get('rule', 'default')
        rule = self.break_rules.get(rule_name, self.break_rules['default'])
        
        blocks_per_break = int(rule.frequency_hours * 4)  # 4 blocks per hour
        break_duration_blocks = rule.break_duration // 15
        
        # Track last break time
        last_break_idx = -1
        
        for i in range(0, len(blocks), blocks_per_break):
            # Skip if too close to last break
            if last_break_idx >= 0 and i - last_break_idx < (rule.spacing_minutes // 15):
                continue
            
            # Find next available slot for break
            break_scheduled = False
            for j in range(i, min(i + rule.max_delay_minutes // 15, len(blocks))):
                if (blocks[j].activity_type == ActivityType.WORK_ATTENDANCE and
                    j + break_duration_blocks <= len(blocks)):
                    
                    # Check if all blocks are available
                    can_schedule = all(
                        blocks[k].activity_type == ActivityType.WORK_ATTENDANCE
                        for k in range(j, j + break_duration_blocks)
                    )
                    
                    if can_schedule:
                        # Schedule break
                        for k in range(j, j + break_duration_blocks):
                            blocks[k].activity_type = ActivityType.SHORT_BREAK
                            blocks[k].break_type = 'short'
                        last_break_idx = j
                        break_scheduled = True
                        break
            
            if not break_scheduled:
                logger.warning(f"Could not schedule break around interval {i}")
        
        return blocks
    
    def _optimize_employee_timetable(self,
                                   blocks: List[TimetableBlock],
                                   schedule: WorkScheduleEntry,
                                   template: TimetableTemplate) -> List[TimetableBlock]:
        """Optimize individual employee timetable"""
        # Balance workload across day
        if template.optimization_criteria == OptimizationCriteria.WORKLOAD_BALANCE:
            blocks = self._balance_workload(blocks, schedule)
        
        # Multi-skill optimization if employee has multiple skills
        if len(schedule.skills) > 1:
            blocks = self._optimize_skill_assignments(blocks, schedule)
        
        return blocks
    
    def _optimize_for_service_level(self,
                                  blocks: List[TimetableBlock],
                                  date: datetime) -> List[TimetableBlock]:
        """Optimize timetable for 80/20 service level target"""
        # Get forecast data for the day
        daily_forecast = [
            f for f in self.forecast_data
            if f.datetime.date() == date.date()
        ]
        
        if not daily_forecast:
            return blocks
        
        # Group blocks by interval
        interval_blocks = defaultdict(list)
        for block in blocks:
            interval_key = block.interval_start
            interval_blocks[interval_key].append(block)
        
        # Analyze coverage gaps
        for forecast in daily_forecast:
            interval_key = forecast.datetime.time()
            available_agents = len([
                b for b in interval_blocks.get(interval_key, [])
                if b.activity_type == ActivityType.WORK_ATTENDANCE
            ])
            
            required_agents = int(np.ceil(forecast.required_agents))
            
            if available_agents < required_agents:
                # Try to move breaks to cover gap
                self._adjust_breaks_for_coverage(
                    blocks=blocks,
                    interval_time=interval_key,
                    agents_needed=required_agents - available_agents
                )
        
        return blocks
    
    def _adjust_breaks_for_coverage(self,
                                   blocks: List[TimetableBlock],
                                   interval_time: time,
                                   agents_needed: int) -> bool:
        """Adjust breaks to improve coverage at specific interval"""
        adjusted_count = 0
        
        # Find breaks that can be moved
        for block in blocks:
            if (block.interval_start == interval_time and
                block.activity_type in [ActivityType.SHORT_BREAK, ActivityType.LUNCH_BREAK] and
                not block.locked):
                
                # Try to find alternative time for this break
                employee_blocks = [b for b in blocks if b.employee_id == block.employee_id]
                alternative_found = self._find_alternative_break_time(
                    employee_blocks=employee_blocks,
                    current_break_idx=employee_blocks.index(block),
                    avoid_time=interval_time
                )
                
                if alternative_found:
                    block.activity_type = ActivityType.WORK_ATTENDANCE
                    adjusted_count += 1
                    
                    if adjusted_count >= agents_needed:
                        break
        
        return adjusted_count > 0
    
    def _find_alternative_break_time(self,
                                   employee_blocks: List[TimetableBlock],
                                   current_break_idx: int,
                                   avoid_time: time) -> bool:
        """Find alternative time slot for break"""
        break_duration = 1
        current_block = employee_blocks[current_break_idx]
        
        # Count consecutive break blocks
        for i in range(current_break_idx + 1, len(employee_blocks)):
            if (employee_blocks[i].activity_type == current_block.activity_type and
                employee_blocks[i].break_type == current_block.break_type):
                break_duration += 1
            else:
                break
        
        # Search for alternative slot within +/- 30 minutes
        search_range = 8  # 8 * 15 minutes = 2 hours
        
        for offset in range(1, search_range):
            for direction in [1, -1]:
                new_idx = current_break_idx + (offset * direction)
                
                if 0 <= new_idx <= len(employee_blocks) - break_duration:
                    # Check if new slot is available
                    can_move = all(
                        employee_blocks[i].activity_type == ActivityType.WORK_ATTENDANCE and
                        employee_blocks[i].interval_start != avoid_time
                        for i in range(new_idx, new_idx + break_duration)
                    )
                    
                    if can_move:
                        # Move break to new slot
                        for i in range(break_duration):
                            old_idx = current_break_idx + i
                            new_idx_i = new_idx + i
                            
                            # Swap activities
                            employee_blocks[new_idx_i].activity_type = employee_blocks[old_idx].activity_type
                            employee_blocks[new_idx_i].break_type = employee_blocks[old_idx].break_type
                            employee_blocks[old_idx].activity_type = ActivityType.WORK_ATTENDANCE
                            employee_blocks[old_idx].break_type = None
                        
                        return True
        
        return False
    
    def _balance_workload(self,
                         blocks: List[TimetableBlock],
                         schedule: WorkScheduleEntry) -> List[TimetableBlock]:
        """Balance workload distribution throughout the day"""
        # Simple implementation: ensure even distribution of intensive work
        work_blocks = [b for b in blocks if b.activity_type == ActivityType.WORK_ATTENDANCE]
        
        if len(work_blocks) > 16:  # More than 4 hours of work
            # Mark some blocks for less intensive activities
            project_blocks = len(work_blocks) // 10  # 10% for project work
            
            # Distribute project work evenly
            interval = len(work_blocks) // (project_blocks + 1)
            
            for i in range(project_blocks):
                idx = (i + 1) * interval
                if idx < len(work_blocks):
                    work_blocks[idx].activity_type = ActivityType.PROJECT_WORK
        
        return blocks
    
    def _optimize_skill_assignments(self,
                                  blocks: List[TimetableBlock],
                                  schedule: WorkScheduleEntry) -> List[TimetableBlock]:
        """Optimize skill assignments for multi-skilled operators"""
        if len(schedule.skills) <= 1:
            return blocks
        
        # Assign primary skill to majority of work blocks
        primary_skill = schedule.skills[0]
        secondary_skills = schedule.skills[1:]
        
        work_blocks = [b for b in blocks if b.activity_type == ActivityType.WORK_ATTENDANCE]
        
        # Distribute skills based on typical allocation
        primary_blocks = int(len(work_blocks) * 0.7)  # 70% primary skill
        
        for i, block in enumerate(work_blocks):
            if i < primary_blocks:
                block.skill_assigned = primary_skill
            else:
                # Assign secondary skills
                skill_idx = (i - primary_blocks) % len(secondary_skills)
                block.skill_assigned = secondary_skills[skill_idx]
        
        return blocks
    
    async def make_manual_adjustment(self,
                                   employee_id: str,
                                   start_time: datetime,
                                   end_time: datetime,
                                   adjustment_type: str,
                                   **kwargs) -> bool:
        """Make manual adjustment to timetable"""
        affected_blocks = [
            b for b in self.timetable_blocks
            if (b.employee_id == employee_id and
                start_time <= b.datetime < end_time)
        ]
        
        if not affected_blocks:
            return False
        
        success = False
        
        if adjustment_type == "Add work attendance":
            success = self._adjust_to_work(affected_blocks)
        elif adjustment_type == "Does not accept calls":
            success = self._adjust_to_downtime(affected_blocks)
        elif adjustment_type == "Assign to project":
            project_id = kwargs.get('project_id')
            success = self._adjust_to_project(affected_blocks, project_id)
        elif adjustment_type == "Add Lunch":
            success = self._adjust_to_lunch(affected_blocks)
        elif adjustment_type == "Add Break":
            success = self._adjust_to_break(affected_blocks)
        elif adjustment_type == "Cancel Breaks":
            success = self._cancel_breaks(affected_blocks)
        elif adjustment_type == "Event":
            event_type = kwargs.get('event_type', 'meeting')
            success = self._adjust_to_event(affected_blocks, event_type)
        
        if success:
            # Validate impact on service level
            self._validate_adjustment_impact(affected_blocks)
            
            # Update database with real-time changes
            await self._update_realtime_adjustments(affected_blocks, adjustment_type)
        
        return success
    
    async def _update_realtime_adjustments(self, 
                                          affected_blocks: List[TimetableBlock],
                                          adjustment_type: str):
        """Update database with real-time timetable adjustments"""
        try:
            if not self.db_initialized:
                await self._ensure_db_initialized()
            
            for block in affected_blocks:
                # Prepare changes for database update
                changes = {
                    'activity_type': block.activity_type.value,
                    'skill_assigned': block.skill_assigned,
                    'project_id': block.project_id,
                    'break_type': block.break_type,
                    'is_locked': block.locked
                }
                
                # For now, we'll use a simple ID mapping
                # In production, you'd track the database IDs
                block_id = f"{block.employee_id}_{block.datetime.isoformat()}"
                
                await self.db_service.update_realtime_timetable(block_id, changes)
                
        except Exception as e:
            logger.error(f"Error updating real-time adjustments: {str(e)}")
    
    def _adjust_to_work(self, blocks: List[TimetableBlock]) -> bool:
        """Adjust blocks to work attendance"""
        for block in blocks:
            if not block.locked:
                block.activity_type = ActivityType.WORK_ATTENDANCE
                block.break_type = None
                block.project_id = None
        return True
    
    def _adjust_to_downtime(self, blocks: List[TimetableBlock]) -> bool:
        """Adjust blocks to downtime"""
        for block in blocks:
            if not block.locked:
                block.activity_type = ActivityType.DOWNTIME
        return True
    
    def _adjust_to_project(self, blocks: List[TimetableBlock], project_id: str) -> bool:
        """Assign blocks to project work"""
        if not project_id:
            return False
        
        for block in blocks:
            if not block.locked:
                block.activity_type = ActivityType.PROJECT_WORK
                block.project_id = project_id
        return True
    
    def _adjust_to_lunch(self, blocks: List[TimetableBlock]) -> bool:
        """Adjust blocks to lunch break"""
        # Validate lunch rules
        if len(blocks) < 2:  # Minimum 30 minutes
            return False
        
        for block in blocks:
            if not block.locked:
                block.activity_type = ActivityType.LUNCH_BREAK
                block.break_type = 'lunch'
        return True
    
    def _adjust_to_break(self, blocks: List[TimetableBlock]) -> bool:
        """Adjust blocks to short break"""
        for block in blocks:
            if not block.locked:
                block.activity_type = ActivityType.SHORT_BREAK
                block.break_type = 'short'
        return True
    
    def _cancel_breaks(self, blocks: List[TimetableBlock]) -> bool:
        """Cancel breaks in selected blocks"""
        cancelled = False
        for block in blocks:
            if (not block.locked and
                block.activity_type in [ActivityType.SHORT_BREAK, ActivityType.LUNCH_BREAK]):
                block.activity_type = ActivityType.WORK_ATTENDANCE
                block.break_type = None
                cancelled = True
        return cancelled
    
    def _adjust_to_event(self, blocks: List[TimetableBlock], event_type: str) -> bool:
        """Adjust blocks for event (training, meeting)"""
        activity_type = ActivityType.MEETING
        if event_type == 'training':
            activity_type = ActivityType.TRAINING
        
        for block in blocks:
            if not block.locked:
                block.activity_type = activity_type
        return True
    
    def _validate_adjustment_impact(self, blocks: List[TimetableBlock]):
        """Validate and calculate service level impact of adjustments"""
        # This would calculate the expected impact on 80/20 service level
        # For now, just log the change
        work_blocks = sum(1 for b in blocks if b.activity_type == ActivityType.WORK_ATTENDANCE)
        total_blocks = len(blocks)
        
        logger.info(f"Adjustment impact: {work_blocks}/{total_blocks} blocks available for work")
    
    def get_timetable_statistics(self,
                               start_date: datetime,
                               end_date: datetime) -> Dict[str, Any]:
        """Get timetable statistics for analysis"""
        relevant_blocks = [
            b for b in self.timetable_blocks
            if start_date <= b.datetime <= end_date
        ]
        
        if not relevant_blocks:
            return {}
        
        # Calculate statistics
        stats = {
            'total_blocks': len(relevant_blocks),
            'coverage_analysis': self._analyze_coverage(relevant_blocks),
            'activity_distribution': self._analyze_activities(relevant_blocks),
            'break_distribution': self._analyze_breaks(relevant_blocks),
            'utilization_by_employee': self._analyze_utilization(relevant_blocks)
        }
        
        return stats
    
    def _analyze_coverage(self, blocks: List[TimetableBlock]) -> Dict[str, Any]:
        """Analyze coverage statistics"""
        interval_coverage = defaultdict(int)
        interval_capacity = defaultdict(int)
        
        for block in blocks:
            interval_key = block.interval_start
            interval_capacity[interval_key] += 1
            
            if block.activity_type == ActivityType.WORK_ATTENDANCE:
                interval_coverage[interval_key] += 1
        
        coverage_percentages = {}
        for interval, capacity in interval_capacity.items():
            if capacity > 0:
                coverage_percentages[str(interval)] = (interval_coverage[interval] / capacity) * 100
        
        return {
            'average_coverage': np.mean(list(coverage_percentages.values())),
            'min_coverage': min(coverage_percentages.values()) if coverage_percentages else 0,
            'max_coverage': max(coverage_percentages.values()) if coverage_percentages else 0,
            'coverage_by_interval': coverage_percentages
        }
    
    def _analyze_activities(self, blocks: List[TimetableBlock]) -> Dict[str, float]:
        """Analyze activity distribution"""
        activity_counts = defaultdict(int)
        
        for block in blocks:
            activity_counts[block.activity_type.value] += 1
        
        total_blocks = len(blocks)
        distribution = {}
        
        for activity, count in activity_counts.items():
            distribution[activity] = (count / total_blocks) * 100
        
        return distribution
    
    def _analyze_breaks(self, blocks: List[TimetableBlock]) -> Dict[str, Any]:
        """Analyze break distribution"""
        break_blocks = [
            b for b in blocks
            if b.activity_type in [ActivityType.SHORT_BREAK, ActivityType.LUNCH_BREAK]
        ]
        
        employees = set(b.employee_id for b in blocks)
        break_distribution = {}
        
        for employee in employees:
            emp_breaks = [b for b in break_blocks if b.employee_id == employee]
            emp_total = len([b for b in blocks if b.employee_id == employee])
            
            if emp_total > 0:
                break_distribution[employee] = (len(emp_breaks) / emp_total) * 100
        
        return {
            'average_break_percentage': np.mean(list(break_distribution.values())) if break_distribution else 0,
            'break_distribution_by_employee': break_distribution
        }
    
    def _analyze_utilization(self, blocks: List[TimetableBlock]) -> Dict[str, float]:
        """Analyze utilization by employee"""
        utilization = {}
        employees = set(b.employee_id for b in blocks)
        
        for employee in employees:
            emp_blocks = [b for b in blocks if b.employee_id == employee]
            productive_blocks = [
                b for b in emp_blocks
                if b.activity_type in [
                    ActivityType.WORK_ATTENDANCE,
                    ActivityType.PROJECT_WORK,
                    ActivityType.TRAINING
                ]
            ]
            
            if emp_blocks:
                utilization[employee] = (len(productive_blocks) / len(emp_blocks)) * 100
        
        return utilization