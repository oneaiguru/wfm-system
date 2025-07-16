#!/usr/bin/env python3
"""
Database Service for Timetable Generator
Provides real data connections for Mobile Workforce Scheduler pattern
"""

import logging
import asyncio
import asyncpg
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, date, time, timedelta
import os
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class ScheduleTemplate:
    """Schedule template data from database"""
    template_id: int
    template_code: str
    template_name: str
    shift_pattern: str
    work_days_per_week: int
    hours_per_day: float
    start_time: time
    end_time: time
    break_minutes: int
    is_rotational: bool
    rotation_weeks: Optional[int] = None


@dataclass
class EmployeeAvailability:
    """Employee availability and constraints"""
    employee_id: str
    employee_number: str
    first_name: str
    last_name: str
    skills: List[Dict[str, Any]]
    work_rate: float
    max_weekly_hours: int
    max_daily_hours: int
    night_work_allowed: bool
    weekend_work_allowed: bool
    overtime_allowed: bool
    schedule_preferences: List[Dict[str, Any]]


@dataclass
class ScheduleShift:
    """Actual scheduled shift data"""
    shift_id: str
    employee_id: str
    shift_date: date
    start_time: time
    end_time: time
    break_duration: int
    shift_type: str
    status: str


class TimetableDatabaseService:
    """Database service for timetable generator with real WFM data connections."""
    
    def __init__(self):
        self.pool = None
        self.connection_params = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': os.getenv('DB_PORT', 5432),
            'database': os.getenv('DB_NAME', 'wfm_enterprise'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', '')
        }
    
    async def initialize(self):
        """Initialize database connection pool."""
        try:
            self.pool = await asyncpg.create_pool(
                **self.connection_params,
                min_size=2,
                max_size=10,
                command_timeout=30
            )
            logger.info("Timetable database service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize database connection pool: {str(e)}")
            raise
    
    async def close(self):
        """Close database connection pool."""
        if self.pool:
            await self.pool.close()
            logger.info("Timetable database connection pool closed")
    
    async def get_schedule_templates(self) -> Dict[str, ScheduleTemplate]:
        """
        Get all available schedule templates from database.
        
        Returns:
            Dict[template_code, ScheduleTemplate]
        """
        try:
            async with self.pool.acquire() as connection:
                query = """
                    SELECT 
                        template_id,
                        template_code,
                        template_name,
                        shift_pattern,
                        work_days_per_week,
                        hours_per_day,
                        start_time,
                        end_time,
                        break_minutes,
                        is_rotational,
                        rotation_weeks
                    FROM schedule_templates
                    ORDER BY template_name
                """
                
                rows = await connection.fetch(query)
                
                templates = {}
                for row in rows:
                    template = ScheduleTemplate(
                        template_id=row['template_id'],
                        template_code=row['template_code'],
                        template_name=row['template_name'],
                        shift_pattern=row['shift_pattern'],
                        work_days_per_week=row['work_days_per_week'],
                        hours_per_day=float(row['hours_per_day']),
                        start_time=row['start_time'],
                        end_time=row['end_time'],
                        break_minutes=row['break_minutes'],
                        is_rotational=row['is_rotational'],
                        rotation_weeks=row['rotation_weeks']
                    )
                    templates[template.template_code] = template
                
                logger.info(f"Retrieved {len(templates)} schedule templates")
                return templates
                
        except Exception as e:
            logger.error(f"Error retrieving schedule templates: {str(e)}")
            raise
    
    async def get_employee_availability(self, 
                                      start_date: date, 
                                      end_date: date,
                                      department_id: Optional[str] = None) -> Dict[str, EmployeeAvailability]:
        """
        Get employee availability data including skills, constraints, and preferences.
        
        Returns:
            Dict[employee_id, EmployeeAvailability]
        """
        try:
            async with self.pool.acquire() as connection:
                # Get employee base data with constraints
                employee_query = """
                    SELECT 
                        e.id as employee_id,
                        e.employee_number,
                        e.first_name,
                        e.last_name,
                        e.work_rate,
                        e.weekly_hours_norm,
                        e.daily_hours_limit,
                        e.night_work_permission,
                        e.weekend_work_permission,
                        e.overtime_authorization
                    FROM employees e
                    WHERE e.is_active = true
                    AND e.status = 'active'
                """
                
                params = []
                if department_id:
                    employee_query += " AND e.department_id = $1"
                    params.append(department_id)
                
                employee_query += " ORDER BY e.employee_number"
                
                employee_rows = await connection.fetch(employee_query, *params)
                
                employees = {}
                for row in employee_rows:
                    employee_id = str(row['employee_id'])
                    employees[employee_id] = EmployeeAvailability(
                        employee_id=employee_id,
                        employee_number=row['employee_number'],
                        first_name=row['first_name'],
                        last_name=row['last_name'],
                        skills=[],  # Will be populated below
                        work_rate=float(row['work_rate'] or 1.0),
                        max_weekly_hours=row['weekly_hours_norm'] or 40,
                        max_daily_hours=row['daily_hours_limit'] or 8,
                        night_work_allowed=row['night_work_permission'] or False,
                        weekend_work_allowed=row['weekend_work_permission'] or False,
                        overtime_allowed=row['overtime_authorization'] or False,
                        schedule_preferences=[]  # Will be populated below
                    )
                
                if not employees:
                    return {}
                
                # Get employee skills
                employee_ids = list(employees.keys())
                skills_query = """
                    SELECT 
                        es.employee_id,
                        s.name as skill_name,
                        s.category as skill_category,
                        es.proficiency_level,
                        es.certified
                    FROM employee_skills es
                    JOIN skills s ON es.skill_id = s.id
                    WHERE es.employee_id = ANY($1::uuid[])
                    ORDER BY es.employee_id, s.name
                """
                
                skills_rows = await connection.fetch(
                    skills_query, 
                    [employee_id for employee_id in employee_ids]
                )
                
                for row in skills_rows:
                    employee_id = str(row['employee_id'])
                    if employee_id in employees:
                        skill_data = {
                            'name': row['skill_name'],
                            'category': row['skill_category'],
                            'proficiency_level': row['proficiency_level'],
                            'certified': row['certified']
                        }
                        employees[employee_id].skills.append(skill_data)
                
                # Get schedule preferences for the period
                preferences_query = """
                    SELECT 
                        esp.employee_tab_n,
                        esp.preference_date,
                        esp.preference_type,
                        esp.day_type,
                        esp.preferred_start_time,
                        esp.preferred_end_time,
                        esp.preferred_duration
                    FROM employee_schedule_preferences esp
                    JOIN employees e ON esp.employee_tab_n = e.employee_number
                    WHERE esp.preference_date BETWEEN $1 AND $2
                    AND e.id = ANY($3::uuid[])
                    ORDER BY esp.employee_tab_n, esp.preference_date
                """
                
                pref_rows = await connection.fetch(
                    preferences_query,
                    start_date,
                    end_date,
                    [employee_id for employee_id in employee_ids]
                )
                
                # Map preferences to employees
                for row in pref_rows:
                    employee_number = row['employee_tab_n']
                    # Find employee by number
                    for emp in employees.values():
                        if emp.employee_number == employee_number:
                            preference_data = {
                                'date': row['preference_date'],
                                'type': row['preference_type'],
                                'day_type': row['day_type'],
                                'preferred_start_time': row['preferred_start_time'],
                                'preferred_end_time': row['preferred_end_time'],
                                'preferred_duration': row['preferred_duration']
                            }
                            emp.schedule_preferences.append(preference_data)
                            break
                
                logger.info(f"Retrieved availability for {len(employees)} employees")
                return employees
                
        except Exception as e:
            logger.error(f"Error retrieving employee availability: {str(e)}")
            raise
    
    async def get_schedule_shifts(self, 
                                 start_date: date, 
                                 end_date: date,
                                 employee_ids: Optional[List[str]] = None) -> Dict[str, List[ScheduleShift]]:
        """
        Get existing schedule shifts for the period.
        
        Returns:
            Dict[employee_id, List[ScheduleShift]]
        """
        try:
            async with self.pool.acquire() as connection:
                query = """
                    SELECT 
                        ss.id as shift_id,
                        ss.employee_id,
                        ss.shift_date,
                        ss.start_time,
                        ss.end_time,
                        ss.break_duration,
                        ss.shift_type,
                        ss.status
                    FROM schedule_shifts ss
                    WHERE ss.shift_date BETWEEN $1 AND $2
                """
                
                params = [start_date, end_date]
                
                if employee_ids:
                    placeholders = ','.join(f'${i+3}' for i in range(len(employee_ids)))
                    query += f" AND ss.employee_id::text IN ({placeholders})"
                    params.extend(employee_ids)
                
                query += " ORDER BY ss.employee_id, ss.shift_date, ss.start_time"
                
                rows = await connection.fetch(query, *params)
                
                shifts_by_employee = {}
                for row in rows:
                    employee_id = str(row['employee_id'])
                    
                    shift = ScheduleShift(
                        shift_id=str(row['shift_id']),
                        employee_id=employee_id,
                        shift_date=row['shift_date'],
                        start_time=row['start_time'],
                        end_time=row['end_time'],
                        break_duration=row['break_duration'],
                        shift_type=row['shift_type'],
                        status=row['status']
                    )
                    
                    if employee_id not in shifts_by_employee:
                        shifts_by_employee[employee_id] = []
                    
                    shifts_by_employee[employee_id].append(shift)
                
                logger.info(f"Retrieved shifts for {len(shifts_by_employee)} employees")
                return shifts_by_employee
                
        except Exception as e:
            logger.error(f"Error retrieving schedule shifts: {str(e)}")
            raise
    
    async def get_forecast_requirements(self, 
                                      start_date: date, 
                                      end_date: date,
                                      service_ids: Optional[List[int]] = None) -> Dict[str, List[Dict[str, Any]]]:
        """
        Get forecast requirements that drive timetable needs.
        
        Returns:
            Dict[date_str, List[interval_requirements]]
        """
        try:
            async with self.pool.acquire() as connection:
                query = """
                    SELECT 
                        fd.forecast_date,
                        fd.interval_start,
                        fd.service_id,
                        fd.call_volume,
                        fd.average_handle_time,
                        fd.service_level_target
                    FROM forecast_data fd
                    WHERE fd.forecast_date BETWEEN $1 AND $2
                """
                
                params = [start_date, end_date]
                
                if service_ids:
                    placeholders = ','.join(f'${i+3}' for i in range(len(service_ids)))
                    query += f" AND fd.service_id IN ({placeholders})"
                    params.extend(service_ids)
                
                query += " ORDER BY fd.forecast_date, fd.interval_start"
                
                rows = await connection.fetch(query, *params)
                
                forecast_by_date = {}
                for row in rows:
                    date_str = row['forecast_date'].isoformat()
                    
                    if date_str not in forecast_by_date:
                        forecast_by_date[date_str] = []
                    
                    # Calculate required agents using Erlang C formula (simplified)
                    call_volume = float(row['call_volume'] or 0)
                    aht_seconds = float(row['average_handle_time'] or 300)
                    service_level_target = float(row['service_level_target'] or 0.8)
                    
                    # Simple calculation: agents needed = (call_volume * AHT) / (interval_seconds * utilization)
                    interval_seconds = 15 * 60  # 15 minutes
                    utilization = 0.85  # 85% utilization
                    required_agents = max(1, int((call_volume * aht_seconds) / (interval_seconds * utilization)))
                    
                    requirement = {
                        'interval_start': row['interval_start'],
                        'service_id': row['service_id'],
                        'call_volume': call_volume,
                        'average_handle_time': aht_seconds,
                        'service_level_target': service_level_target,
                        'required_agents': required_agents
                    }
                    
                    forecast_by_date[date_str].append(requirement)
                
                logger.info(f"Retrieved forecast requirements for {len(forecast_by_date)} dates")
                return forecast_by_date
                
        except Exception as e:
            logger.error(f"Error retrieving forecast requirements: {str(e)}")
            raise
    
    async def save_timetable_blocks(self, 
                                   timetable_blocks: List[Dict[str, Any]],
                                   template_code: str) -> List[str]:
        """
        Save generated timetable blocks to database.
        
        Returns:
            List of created block IDs
        """
        try:
            async with self.pool.acquire() as connection:
                # Create timetable_blocks table if it doesn't exist
                create_table_query = """
                    CREATE TABLE IF NOT EXISTS timetable_blocks (
                        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                        employee_id uuid NOT NULL,
                        block_date date NOT NULL,
                        interval_start time NOT NULL,
                        interval_end time NOT NULL,
                        activity_type varchar(50) NOT NULL,
                        skill_assigned varchar(100),
                        project_id varchar(100),
                        break_type varchar(20),
                        is_locked boolean DEFAULT false,
                        template_code varchar(50),
                        created_at timestamp DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (employee_id) REFERENCES employees(id)
                    )
                """
                
                await connection.execute(create_table_query)
                
                # Create index if not exists
                index_query = """
                    CREATE INDEX IF NOT EXISTS idx_timetable_blocks_employee_date 
                    ON timetable_blocks(employee_id, block_date)
                """
                
                await connection.execute(index_query)
                
                # Insert timetable blocks
                insert_query = """
                    INSERT INTO timetable_blocks (
                        employee_id, block_date, interval_start, interval_end,
                        activity_type, skill_assigned, project_id, break_type,
                        is_locked, template_code
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                    RETURNING id
                """
                
                created_ids = []
                for block in timetable_blocks:
                    result = await connection.fetchrow(
                        insert_query,
                        block['employee_id'],
                        block['block_date'],
                        block['interval_start'],
                        block['interval_end'],
                        block['activity_type'],
                        block.get('skill_assigned'),
                        block.get('project_id'),
                        block.get('break_type'),
                        block.get('is_locked', False),
                        template_code
                    )
                    created_ids.append(str(result['id']))
                
                logger.info(f"Saved {len(created_ids)} timetable blocks")
                return created_ids
                
        except Exception as e:
            logger.error(f"Error saving timetable blocks: {str(e)}")
            raise
    
    async def get_constraint_rules(self) -> Dict[str, Dict[str, Any]]:
        """
        Get scheduling constraint rules from database.
        
        Returns:
            Dict[rule_type, rule_data]
        """
        try:
            async with self.pool.acquire() as connection:
                # For now, return standard WFM rules
                # These could be stored in a scheduling_rules table
                rules = {
                    'break_rules': {
                        'short_break_duration': 15,  # minutes
                        'short_break_frequency': 2.0,  # hours
                        'lunch_break_min_duration': 30,
                        'lunch_break_max_duration': 60,
                        'lunch_earliest_start': time(11, 0),
                        'lunch_latest_start': time(14, 0),
                        'min_work_before_lunch': 2.0,  # hours
                        'max_consecutive_work': 4.0  # hours
                    },
                    'shift_rules': {
                        'min_shift_duration': 4.0,  # hours
                        'max_shift_duration': 12.0,
                        'min_rest_between_shifts': 8.0,
                        'max_weekly_hours': 40,
                        'max_consecutive_days': 5
                    },
                    'coverage_rules': {
                        'service_level_target': 0.8,  # 80%
                        'response_time_target': 20,   # seconds
                        'min_coverage_percentage': 0.85,
                        'peak_hour_buffer': 1.2  # 20% extra coverage
                    }
                }
                
                logger.info("Retrieved constraint rules")
                return rules
                
        except Exception as e:
            logger.error(f"Error retrieving constraint rules: {str(e)}")
            # Return default rules on error
            return {
                'break_rules': {
                    'short_break_duration': 15,
                    'short_break_frequency': 2.0,
                    'lunch_break_min_duration': 30,
                    'lunch_break_max_duration': 60
                },
                'shift_rules': {
                    'min_shift_duration': 4.0,
                    'max_shift_duration': 8.0
                },
                'coverage_rules': {
                    'service_level_target': 0.8
                }
            }
    
    async def update_realtime_timetable(self, 
                                       block_id: str, 
                                       changes: Dict[str, Any]) -> bool:
        """
        Update timetable block for real-time adjustments.
        
        Returns:
            Success status
        """
        try:
            async with self.pool.acquire() as connection:
                # Update timetable block
                update_fields = []
                params = []
                param_count = 1
                
                for field, value in changes.items():
                    if field in ['activity_type', 'skill_assigned', 'project_id', 'break_type', 'is_locked']:
                        update_fields.append(f"{field} = ${param_count}")
                        params.append(value)
                        param_count += 1
                
                if not update_fields:
                    return False
                
                update_query = f"""
                    UPDATE timetable_blocks 
                    SET {', '.join(update_fields)}
                    WHERE id = ${param_count}
                """
                params.append(block_id)
                
                result = await connection.execute(update_query, *params)
                
                # Log to realtime updates table
                log_query = """
                    INSERT INTO realtime_timetable_updates (
                        block_id, change_type, old_value, new_value, updated_at
                    ) VALUES ($1, $2, $3, $4, $5)
                """
                
                for field, new_value in changes.items():
                    await connection.execute(
                        log_query,
                        block_id,
                        field,
                        None,  # Would need to track old value
                        str(new_value),
                        datetime.now()
                    )
                
                logger.info(f"Updated timetable block {block_id}")
                return True
                
        except Exception as e:
            logger.error(f"Error updating realtime timetable: {str(e)}")
            return False