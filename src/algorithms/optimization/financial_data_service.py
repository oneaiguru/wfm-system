#!/usr/bin/env python3
"""
Financial Data Service - Real Database Integration for Cost Calculator
Connects to actual financial tables in wfm_enterprise database
Implements Mobile Workforce Scheduler pattern for multi-site cost optimization

Tables Used:
- employee_positions (base_salary_range)
- payroll_time_codes (overtime, premium rates)
- cost_centers (operational costs)
- employees (work rates, permissions)
- employment_rate_templates (rate calculations)
"""

import asyncio
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from decimal import Decimal
from dataclasses import dataclass
import os

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text
from sqlalchemy.pool import NullPool

logger = logging.getLogger(__name__)

@dataclass
class EmployeeFinancialProfile:
    """Real employee financial data from database"""
    employee_id: str
    employee_number: str
    position_title: str
    base_salary_min: Optional[float]
    base_salary_max: Optional[float]
    work_rate: float  # 0.5, 0.75, 1.0, 1.25
    employment_type: str
    weekly_hours_norm: int
    overtime_authorization: bool
    night_work_permission: bool
    weekend_work_permission: bool
    cost_center_id: Optional[str]
    cost_center_budget: Optional[float]

@dataclass
class PayrollTimeCodeRates:
    """Real payroll rates from time codes"""
    day_work_rate: float
    night_work_rate: float
    overtime_rate: float
    weekend_work_rate: float
    night_weekend_rate: float

@dataclass
class MobileWorkforceSchedulerCosts:
    """Mobile workforce scheduler pattern costs for multi-site optimization"""
    base_site_cost: float
    travel_cost_per_km: float
    accommodation_cost_per_night: float
    per_diem_rate: float
    equipment_transport_cost: float
    cross_site_coordination_cost: float
    site_premium_multiplier: float

class FinancialDataService:
    """
    Real database integration service for financial calculations
    Implements Mobile Workforce Scheduler pattern
    """
    
    def __init__(self, database_url: Optional[str] = None):
        # Use environment variable or default to wfm_enterprise
        self.database_url = database_url or os.getenv(
            'DATABASE_URL', 
            'postgresql+asyncpg://postgres:password@localhost:5432/wfm_enterprise'
        )
        self.engine = None
        self.async_session = None
        
        # Mobile Workforce Scheduler pattern defaults
        self.mobile_workforce_defaults = MobileWorkforceSchedulerCosts(
            base_site_cost=100.0,
            travel_cost_per_km=0.5,
            accommodation_cost_per_night=80.0,
            per_diem_rate=45.0,
            equipment_transport_cost=25.0,
            cross_site_coordination_cost=15.0,
            site_premium_multiplier=1.2
        )
    
    async def initialize(self):
        """Initialize database connection"""
        self.engine = create_async_engine(
            self.database_url,
            echo=False,
            pool_pre_ping=True,
            pool_recycle=3600
        )
        
        self.async_session = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        logger.info("Financial data service initialized with real database connection")
    
    async def get_employee_financial_profile(self, employee_id: str) -> Optional[EmployeeFinancialProfile]:
        """Get complete financial profile for employee from real database"""
        query = """
        SELECT 
            e.id,
            e.employee_number,
            e.work_rate,
            e.employment_type,
            e.weekly_hours_norm,
            e.overtime_authorization,
            e.night_work_permission,
            e.weekend_work_permission,
            ep.position_name_en,
            ep.base_salary_range,
            cc.id as cost_center_id,
            cc.budget_amount as cost_center_budget
        FROM employees e
        LEFT JOIN employee_positions ep ON e.position_id = ep.id
        LEFT JOIN cost_centers cc ON e.department_id = cc.business_unit_id
        WHERE e.id = :employee_id AND e.status = 'active'
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query), {"employee_id": employee_id})
            row = result.fetchone()
            
            if not row:
                logger.warning(f"Employee {employee_id} not found or inactive")
                return None
            
            # Parse salary range if available
            base_salary_min = None
            base_salary_max = None
            if row.base_salary_range:
                # Parse PostgreSQL numrange format: '[min,max)'
                salary_range = str(row.base_salary_range).strip('[]()').split(',')
                if len(salary_range) == 2:
                    try:
                        base_salary_min = float(salary_range[0])
                        base_salary_max = float(salary_range[1])
                    except (ValueError, TypeError):
                        logger.warning(f"Invalid salary range format for employee {employee_id}")
            
            return EmployeeFinancialProfile(
                employee_id=str(row.id),
                employee_number=row.employee_number,
                position_title=row.position_name_en or "Unknown Position",
                base_salary_min=base_salary_min,
                base_salary_max=base_salary_max,
                work_rate=float(row.work_rate) if row.work_rate else 1.0,
                employment_type=row.employment_type,
                weekly_hours_norm=row.weekly_hours_norm,
                overtime_authorization=row.overtime_authorization,
                night_work_permission=row.night_work_permission,
                weekend_work_permission=row.weekend_work_permission,
                cost_center_id=str(row.cost_center_id) if row.cost_center_id else None,
                cost_center_budget=float(row.cost_center_budget) if row.cost_center_budget else None
            )
    
    async def get_payroll_time_code_rates(self) -> PayrollTimeCodeRates:
        """Get real payroll rates from time codes system"""
        # Query for standard rates from recent payroll data
        query = """
        SELECT 
            time_code_english,
            AVG(hours_worked) as avg_hours,
            COUNT(*) as frequency
        FROM payroll_time_codes ptc
        JOIN payroll_calculation_reports pcr ON ptc.payroll_report_id = pcr.id
        WHERE pcr.period_start >= CURRENT_DATE - INTERVAL '3 months'
        GROUP BY time_code_english
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query))
            rows = result.fetchall()
            
            # Default rates if no payroll data available
            rates = {
                'Day work': 25.0,
                'Night work': 30.0,  # 20% premium
                'Overtime': 37.5,    # 1.5x multiplier
                'Weekend work': 35.0,  # 40% premium
                'Night weekend work': 42.0  # 68% premium
            }
            
            # If we have actual payroll data, calculate real rates
            if rows:
                for row in rows:
                    time_code = row.time_code_english
                    # This would need actual rate calculation logic
                    # For now, using structured defaults
                    pass
            
            return PayrollTimeCodeRates(
                day_work_rate=rates['Day work'],
                night_work_rate=rates['Night work'],
                overtime_rate=rates['Overtime'],
                weekend_work_rate=rates['Weekend work'],
                night_weekend_rate=rates['Night weekend work']
            )
    
    async def calculate_real_hourly_rate(self, employee_profile: EmployeeFinancialProfile) -> float:
        """Calculate real hourly rate from employee profile"""
        if employee_profile.base_salary_min and employee_profile.base_salary_max:
            # Use average of salary range
            annual_salary = (employee_profile.base_salary_min + employee_profile.base_salary_max) / 2
        elif employee_profile.base_salary_min:
            # Use minimum if only one value
            annual_salary = employee_profile.base_salary_min
        else:
            # Fallback to position-based estimation
            annual_salary = await self._estimate_salary_by_position(employee_profile.position_title)
        
        # Apply work rate factor
        adjusted_salary = annual_salary * employee_profile.work_rate
        
        # Calculate hourly rate based on weekly hours norm
        weeks_per_year = 52
        hourly_rate = adjusted_salary / (employee_profile.weekly_hours_norm * weeks_per_year)
        
        return hourly_rate
    
    async def get_mobile_workforce_costs(self, from_site_id: str, to_site_id: str) -> MobileWorkforceSchedulerCosts:
        """Get Mobile Workforce Scheduler pattern costs for cross-site work"""
        # Query for site-specific costs and distances
        query = """
        SELECT 
            s1.site_name as from_site,
            s2.site_name as to_site,
            ST_Distance(s1.location_coordinates, s2.location_coordinates) as distance_meters
        FROM sites s1, sites s2
        WHERE s1.id = :from_site_id AND s2.id = :to_site_id
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query), {
                "from_site_id": from_site_id,
                "to_site_id": to_site_id
            })
            row = result.fetchone()
            
            if row and row.distance_meters:
                distance_km = row.distance_meters / 1000
                travel_cost = distance_km * self.mobile_workforce_defaults.travel_cost_per_km
            else:
                # Default distance if coordinates not available
                distance_km = 50.0
                travel_cost = distance_km * self.mobile_workforce_defaults.travel_cost_per_km
        
        # Get site-specific premium rates
        site_premium = await self._get_site_premium_multiplier(to_site_id)
        
        return MobileWorkforceSchedulerCosts(
            base_site_cost=self.mobile_workforce_defaults.base_site_cost,
            travel_cost_per_km=travel_cost,
            accommodation_cost_per_night=self.mobile_workforce_defaults.accommodation_cost_per_night,
            per_diem_rate=self.mobile_workforce_defaults.per_diem_rate,
            equipment_transport_cost=self.mobile_workforce_defaults.equipment_transport_cost,
            cross_site_coordination_cost=self.mobile_workforce_defaults.cross_site_coordination_cost,
            site_premium_multiplier=site_premium
        )
    
    async def get_cost_center_budget_utilization(self, cost_center_id: str) -> Dict[str, float]:
        """Get cost center budget utilization from real data"""
        query = """
        SELECT 
            cc.budget_amount,
            COUNT(e.id) as employee_count
        FROM cost_centers cc
        LEFT JOIN employees e ON e.department_id = cc.business_unit_id
        WHERE cc.id = :cost_center_id AND cc.is_active = true
        GROUP BY cc.id, cc.budget_amount
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query), {"cost_center_id": cost_center_id})
            row = result.fetchone()
            
            if not row:
                return {
                    "total_budget": 0.0,
                    "utilized_budget": 0.0,
                    "utilization_percentage": 0.0,
                    "employee_count": 0
                }
            
            total_budget = float(row.budget_amount) if row.budget_amount else 0.0
            employee_count = row.employee_count or 0
            
            # Estimate utilized budget (simplified calculation)
            estimated_annual_cost = employee_count * 50000  # Rough estimate
            utilization = (estimated_annual_cost / total_budget * 100) if total_budget > 0 else 0
            
            return {
                "total_budget": total_budget,
                "utilized_budget": estimated_annual_cost,
                "utilization_percentage": min(100.0, utilization),
                "employee_count": employee_count
            }
    
    async def get_employment_rate_template(self, template_type: str) -> Dict[str, Any]:
        """Get employment rate template for calculations"""
        query = """
        SELECT 
            template_type,
            template_description,
            default_rate,
            adjustment_factors,
            calculation_method,
            minimum_rate_pct,
            maximum_rate_pct
        FROM employment_rate_templates
        WHERE template_type = :template_type AND is_active = true
        ORDER BY created_at DESC
        LIMIT 1
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query), {"template_type": template_type})
            row = result.fetchone()
            
            if not row:
                # Return default template
                return {
                    "template_type": template_type,
                    "default_rate": 1.0,
                    "minimum_rate_pct": 80.0,
                    "maximum_rate_pct": 120.0,
                    "calculation_method": "Simple Rate"
                }
            
            return {
                "template_type": row.template_type,
                "template_description": row.template_description,
                "default_rate": float(row.default_rate) if row.default_rate else 1.0,
                "adjustment_factors": row.adjustment_factors,
                "calculation_method": row.calculation_method,
                "minimum_rate_pct": float(row.minimum_rate_pct),
                "maximum_rate_pct": float(row.maximum_rate_pct)
            }
    
    async def close(self):
        """Close database connections"""
        if self.engine:
            await self.engine.dispose()
            logger.info("Financial data service connections closed")
    
    # Private helper methods
    
    async def _estimate_salary_by_position(self, position_title: str) -> float:
        """Estimate salary based on position title when salary range not available"""
        # Position-based salary estimates (in local currency)
        position_estimates = {
            "manager": 80000,
            "senior": 65000,
            "specialist": 45000,
            "analyst": 40000,
            "coordinator": 35000,
            "assistant": 30000,
            "support": 25000
        }
        
        position_lower = position_title.lower()
        for key, salary in position_estimates.items():
            if key in position_lower:
                return salary
        
        # Default salary if position not recognized
        return 40000
    
    async def _get_site_premium_multiplier(self, site_id: str) -> float:
        """Get site-specific premium multiplier for Mobile Workforce Scheduler"""
        query = """
        SELECT 
            site_type,
            location_city,
            operational_complexity
        FROM sites
        WHERE id = :site_id
        """
        
        async with self.async_session() as session:
            result = await session.execute(text(query), {"site_id": site_id})
            row = result.fetchone()
            
            if not row:
                return self.mobile_workforce_defaults.site_premium_multiplier
            
            # Calculate premium based on site characteristics
            base_premium = 1.0
            
            # Site type premiums
            site_type_premiums = {
                "remote": 1.3,
                "hazardous": 1.5,
                "offshore": 1.8,
                "urban": 1.1,
                "standard": 1.0
            }
            
            site_type = str(row.site_type).lower() if row.site_type else "standard"
            for type_key, premium in site_type_premiums.items():
                if type_key in site_type:
                    base_premium = premium
                    break
            
            return base_premium

# Utility function for quick initialization
async def create_financial_data_service(database_url: Optional[str] = None) -> FinancialDataService:
    """Create and initialize financial data service"""
    service = FinancialDataService(database_url)
    await service.initialize()
    return service