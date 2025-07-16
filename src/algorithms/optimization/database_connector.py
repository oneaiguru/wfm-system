"""
Database Connector for Multi-Skill Allocation Optimizer
Handles database operations for real employee skills and allocation data
"""

import logging
import asyncio
import asyncpg
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, date, time, timedelta
import os

logger = logging.getLogger(__name__)


class DatabaseConnector:
    """Database connector for WFM enterprise database operations."""
    
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
            logger.info("Database connection pool initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize database connection pool: {str(e)}")
            raise
    
    async def close(self):
        """Close database connection pool."""
        if self.pool:
            await self.pool.close()
            logger.info("Database connection pool closed")
    
    async def get_employee_skills(self, organization_id: Optional[str] = None) -> Dict[str, Dict[str, Any]]:
        """
        Get employee skills with proficiency levels and certification status.
        
        Returns:
            Dict[employee_id, Dict[skill_name, skill_data]]
        """
        try:
            async with self.pool.acquire() as connection:
                query = """
                    SELECT 
                        e.id as employee_id,
                        e.first_name,
                        e.last_name,
                        e.employee_number,
                        s.name as skill_name,
                        s.category as skill_category,
                        es.proficiency_level,
                        es.certified,
                        es.assigned_at
                    FROM employees e
                    JOIN employee_skills es ON e.id = es.employee_id
                    JOIN skills s ON es.skill_id = s.id
                    WHERE e.is_active = true
                    AND e.status = 'active'
                """
                
                params = []
                if organization_id:
                    query += " AND e.organization_id = $1"
                    params.append(organization_id)
                
                query += " ORDER BY e.employee_number, s.name"
                
                rows = await connection.fetch(query, *params)
                
                employee_skills = {}
                for row in rows:
                    employee_id = str(row['employee_id'])
                    skill_name = row['skill_name']
                    
                    if employee_id not in employee_skills:
                        employee_skills[employee_id] = {
                            'employee_info': {
                                'first_name': row['first_name'],
                                'last_name': row['last_name'],
                                'employee_number': row['employee_number']
                            },
                            'skills': {}
                        }
                    
                    employee_skills[employee_id]['skills'][skill_name] = {
                        'proficiency_level': row['proficiency_level'],
                        'certified': row['certified'],
                        'category': row['skill_category'],
                        'assigned_at': row['assigned_at']
                    }
                
                logger.info(f"Retrieved skills for {len(employee_skills)} employees")
                return employee_skills
                
        except Exception as e:
            logger.error(f"Error retrieving employee skills: {str(e)}")
            raise
    
    async def get_skill_requirements(self, service_ids: Optional[List[int]] = None) -> Dict[str, Dict[str, Any]]:
        """
        Get skill requirements from forecast data and service configurations.
        
        Returns:
            Dict[skill_name, requirement_data]
        """
        try:
            async with self.pool.acquire() as connection:
                # Get forecast data for skill demand calculation
                forecast_query = """
                    SELECT 
                        fd.service_id,
                        fd.forecast_date,
                        fd.interval_start,
                        fd.call_volume,
                        fd.average_handle_time,
                        fd.service_level_target
                    FROM forecast_data fd
                    WHERE fd.forecast_date >= CURRENT_DATE
                    AND fd.forecast_date <= CURRENT_DATE + INTERVAL '7 days'
                """
                
                forecast_params = []
                if service_ids:
                    placeholders = ','.join(f'${i+1}' for i in range(len(service_ids)))
                    forecast_query += f" AND fd.service_id IN ({placeholders})"
                    forecast_params.extend(service_ids)
                
                forecast_query += " ORDER BY fd.forecast_date, fd.interval_start"
                
                forecast_rows = await connection.fetch(forecast_query, *forecast_params)
                
                # Calculate skill requirements based on forecast data
                skill_requirements = {}
                
                # Map service types to skills (simplified mapping)
                service_skill_mapping = {
                    1: 'Customer Service',
                    2: 'Technical Support', 
                    3: 'Sales',
                    4: 'Billing Support',
                    5: 'Chat Support'
                }
                
                for row in forecast_rows:
                    service_id = row['service_id']
                    skill_name = service_skill_mapping.get(service_id, 'Customer Service')
                    
                    if skill_name not in skill_requirements:
                        skill_requirements[skill_name] = {
                            'total_volume': 0,
                            'peak_volume': 0,
                            'average_handle_time': 0,
                            'service_level_target': 0.8,
                            'required_hours': 0,
                            'priority': 'medium'
                        }
                    
                    # Calculate required hours (simplified)
                    volume = row['call_volume'] or 0
                    aht_seconds = row['average_handle_time'] or 300  # 5 minutes default
                    required_hours = (volume * aht_seconds) / 3600  # Convert to hours
                    
                    skill_requirements[skill_name]['total_volume'] += volume
                    skill_requirements[skill_name]['peak_volume'] = max(
                        skill_requirements[skill_name]['peak_volume'], volume
                    )
                    skill_requirements[skill_name]['required_hours'] += required_hours
                    skill_requirements[skill_name]['service_level_target'] = max(
                        skill_requirements[skill_name]['service_level_target'],
                        float(row['service_level_target'] or 0.8)
                    )
                
                # Set priorities based on volume
                for skill_name, req in skill_requirements.items():
                    if req['total_volume'] > 100:
                        req['priority'] = 'high'
                    elif req['total_volume'] > 50:
                        req['priority'] = 'medium'
                    else:
                        req['priority'] = 'low'
                
                logger.info(f"Calculated requirements for {len(skill_requirements)} skills")
                return skill_requirements
                
        except Exception as e:
            logger.error(f"Error retrieving skill requirements: {str(e)}")
            raise
    
    async def get_allocation_constraints(self, employee_ids: Optional[List[str]] = None) -> Dict[str, Dict[str, Any]]:
        """
        Get allocation constraints for employees (work hours, permissions, etc.).
        
        Returns:
            Dict[employee_id, constraint_data]
        """
        try:
            async with self.pool.acquire() as connection:
                query = """
                    SELECT 
                        e.id as employee_id,
                        e.employment_type,
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
                if employee_ids:
                    placeholders = ','.join(f'${i+1}' for i in range(len(employee_ids)))
                    query += f" AND e.id::text IN ({placeholders})"
                    params.extend(employee_ids)
                
                rows = await connection.fetch(query, *params)
                
                constraints = {}
                for row in rows:
                    employee_id = str(row['employee_id'])
                    constraints[employee_id] = {
                        'employment_type': row['employment_type'],
                        'work_rate': float(row['work_rate'] or 1.0),
                        'max_weekly_hours': row['weekly_hours_norm'] or 40,
                        'max_daily_hours': row['daily_hours_limit'] or 8,
                        'night_work_allowed': row['night_work_permission'] or False,
                        'weekend_work_allowed': row['weekend_work_permission'] or False,
                        'overtime_allowed': row['overtime_authorization'] or False
                    }
                
                logger.info(f"Retrieved constraints for {len(constraints)} employees")
                return constraints
                
        except Exception as e:
            logger.error(f"Error retrieving allocation constraints: {str(e)}")
            raise
    
    async def save_allocation_results(self, allocation_result: Dict[str, Any]) -> int:
        """
        Save allocation optimization results to database.
        
        Returns:
            ID of saved allocation record
        """
        try:
            async with self.pool.acquire() as connection:
                # Save to allocation_results table (extend schema if needed)
                insert_query = """
                    INSERT INTO allocation_results (
                        agent_id, 
                        skill_score, 
                        urgency_score, 
                        allocated_at
                    ) VALUES ($1, $2, $3, $4)
                    RETURNING id
                """
                
                # For now, save a summary record
                total_efficiency = allocation_result.get('efficiency_score', 0.0)
                total_cost = allocation_result.get('total_cost', 0.0)
                
                result = await connection.fetchrow(
                    insert_query,
                    None,  # agent_id (summary record)
                    total_efficiency,
                    total_cost,
                    datetime.now()
                )
                
                allocation_id = result['id']
                logger.info(f"Saved allocation results with ID: {allocation_id}")
                return allocation_id
                
        except Exception as e:
            logger.error(f"Error saving allocation results: {str(e)}")
            raise
    
    async def get_historical_performance(self, skill_name: str, days_back: int = 30) -> Dict[str, Any]:
        """
        Get historical performance data for a skill.
        
        Returns:
            Performance metrics for the skill
        """
        try:
            async with self.pool.acquire() as connection:
                # This would require more complex queries with actual performance tables
                # For now, return mock data structure with real calculation potential
                
                query = """
                    SELECT 
                        COUNT(*) as allocation_count,
                        AVG(skill_score) as avg_skill_score,
                        MAX(allocated_at) as last_allocation
                    FROM allocation_results
                    WHERE allocated_at >= CURRENT_DATE - INTERVAL '%s days'
                """
                
                row = await connection.fetchrow(query, days_back)
                
                return {
                    'allocation_count': row['allocation_count'] or 0,
                    'average_performance': float(row['avg_skill_score'] or 0.0),
                    'last_allocation': row['last_allocation'],
                    'skill_name': skill_name
                }
                
        except Exception as e:
            logger.error(f"Error retrieving historical performance: {str(e)}")
            return {
                'allocation_count': 0,
                'average_performance': 0.0,
                'last_allocation': None,
                'skill_name': skill_name
            }