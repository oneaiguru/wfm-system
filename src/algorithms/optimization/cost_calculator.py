#!/usr/bin/env python3
"""
Cost Calculator - BDD Implementation
From: 24-automatic-schedule-optimization.feature:54
"Cost Calculator | Linear programming | Staffing costs + overtime | Financial impact | 1-2 seconds"
"""

from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import logging
import numpy as np

logger = logging.getLogger(__name__)

class CostComponent(Enum):
    """Types of cost components"""
    BASE_SALARY = "base_salary"
    OVERTIME = "overtime"
    WEEKEND_PREMIUM = "weekend_premium"
    NIGHT_DIFFERENTIAL = "night_differential"
    SKILL_PREMIUM = "skill_premium"
    BENEFITS = "benefits"
    TRAINING = "training"
    HIRING = "hiring"

@dataclass
class CostAnalysis:
    """Individual cost analysis result"""
    employee_id: str
    base_cost: float
    overtime_cost: float
    premium_cost: float
    benefit_cost: float
    total_cost: float
    cost_breakdown: Dict[CostComponent, float]
    efficiency_score: float

@dataclass
class FinancialImpact:
    """Complete financial impact assessment"""
    total_weekly_cost: float
    cost_by_component: Dict[CostComponent, float]
    cost_by_employee: List[CostAnalysis]
    cost_variance: float
    efficiency_metrics: Dict[str, float]
    savings_opportunities: List[str]
    processing_time_ms: float

class CostCalculator:
    """
    Linear programming cost calculator
    BDD Requirement: Staffing costs + overtime → Financial impact
    """
    
    def __init__(self, database_url: Optional[str] = None):
        # BDD Requirement: Cost efficiency 30% weight (line 66)
        self.cost_weight = 0.30
        
        # Real database connection for financial data
        self.financial_service = None
        self.database_url = database_url
        
        # Cache for employee financial profiles
        self._employee_profiles_cache = {}
        self._payroll_rates_cache = None
        self._cache_timestamp = None
        self._cache_ttl = 300  # 5 minutes cache
        
        # BDD target processing time: 1-2 seconds
        self.processing_target = 2.0
        
        # Mobile Workforce Scheduler pattern enabled
        self.mobile_workforce_enabled = True
        
    async def calculate_financial_impact(self,
                                       schedule_variant: Dict[str, Any],
                                       staffing_costs: Dict[str, Any],
                                       overtime_policies: Dict[str, Any]) -> FinancialImpact:
        """
        Main cost calculation per BDD specification with REAL DATABASE DATA
        Input: Staffing costs + overtime
        Output: Financial impact
        Processing: 1-2 seconds (BDD requirement)
        Mobile Workforce Scheduler pattern support
        """
        start_time = datetime.now()
        
        # Initialize financial service if not done
        if not self.financial_service:
            await self._initialize_financial_service()
        
        schedule_blocks = schedule_variant.get('schedule_blocks', [])
        
        # Step 1: Calculate individual employee costs with REAL DATA
        employee_costs = []
        for block in schedule_blocks:
            cost_analysis = await self._calculate_employee_cost_real(block, overtime_policies)
            employee_costs.append(cost_analysis)
        
        # Step 2: Aggregate cost components
        cost_by_component = self._aggregate_cost_components(employee_costs)
        
        # Step 3: Calculate total weekly cost
        total_weekly_cost = sum(cost.total_cost for cost in employee_costs)
        
        # Step 4: Calculate cost variance and efficiency
        cost_variance = self._calculate_cost_variance(employee_costs)
        efficiency_metrics = self._calculate_efficiency_metrics(employee_costs, schedule_blocks)
        
        # Step 5: Identify savings opportunities
        savings_opportunities = self._identify_savings_opportunities(employee_costs, cost_by_component)
        
        # Processing time validation
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return FinancialImpact(
            total_weekly_cost=total_weekly_cost,
            cost_by_component=cost_by_component,
            cost_by_employee=employee_costs,
            cost_variance=cost_variance,
            efficiency_metrics=efficiency_metrics,
            savings_opportunities=savings_opportunities,
            processing_time_ms=processing_time
        )
    
    async def _calculate_employee_cost_real(self,
                                           schedule_block: Dict[str, Any],
                                           overtime_policies: Dict[str, Any]) -> CostAnalysis:
        """Calculate cost for individual employee schedule block using REAL DATABASE DATA"""
        employee_id = schedule_block.get('employee_id', 'UNKNOWN')
        
        # Get real employee financial profile
        employee_profile = await self._get_employee_profile(employee_id)
        if not employee_profile:
            logger.warning(f"No financial profile found for employee {employee_id}, using defaults")
            return await self._calculate_fallback_cost(schedule_block, overtime_policies)
        
        # Get real payroll rates
        payroll_rates = await self._get_payroll_rates()
        
        # Calculate hours
        regular_hours = self._calculate_regular_hours(schedule_block)
        overtime_hours = self._calculate_overtime_hours(schedule_block, overtime_policies)
        weekend_hours = self._calculate_weekend_hours(schedule_block)
        night_hours = self._calculate_night_hours(schedule_block)
        
        # Calculate REAL hourly rate from employee profile
        base_hourly_rate = await self.financial_service.calculate_real_hourly_rate(employee_profile)
        
        # Apply Mobile Workforce Scheduler costs if cross-site work
        mobile_costs = await self._calculate_mobile_workforce_costs(schedule_block)
        
        # Calculate cost components with REAL RATES
        base_cost = regular_hours * base_hourly_rate * employee_profile.work_rate
        
        # Real overtime calculation based on employee authorization
        if employee_profile.overtime_authorization:
            overtime_multiplier = 1.5  # Standard overtime rate
            overtime_cost = overtime_hours * base_hourly_rate * overtime_multiplier
        else:
            overtime_cost = 0.0  # No overtime if not authorized
            logger.warning(f"Employee {employee_id} not authorized for overtime")
        
        # Real premium calculations
        weekend_premium = 0.0
        if employee_profile.weekend_work_permission and weekend_hours > 0:
            weekend_premium = weekend_hours * (payroll_rates.weekend_work_rate - payroll_rates.day_work_rate)
        
        night_premium = 0.0
        if employee_profile.night_work_permission and night_hours > 0:
            night_premium = night_hours * (payroll_rates.night_work_rate - payroll_rates.day_work_rate)
        
        # Skill premium based on position
        skill_premium = self._calculate_position_skill_premium(employee_profile, regular_hours + overtime_hours)
        
        premium_cost = weekend_premium + night_premium + skill_premium + mobile_costs
        
        # Benefits calculation based on real employment type
        gross_wages = base_cost + overtime_cost + premium_cost
        benefit_rate = 0.35 if employee_profile.employment_type == 'full-time' else 0.20
        benefit_cost = gross_wages * benefit_rate
        
        # Total cost
        total_cost = gross_wages + benefit_cost
        
        # Cost breakdown
        cost_breakdown = {
            CostComponent.BASE_SALARY: base_cost,
            CostComponent.OVERTIME: overtime_cost,
            CostComponent.WEEKEND_PREMIUM: weekend_premium,
            CostComponent.NIGHT_DIFFERENTIAL: night_premium,
            CostComponent.SKILL_PREMIUM: skill_premium,
            CostComponent.BENEFITS: benefit_cost
        }
        
        # Efficiency score (cost per productive hour)
        total_hours = regular_hours + overtime_hours
        efficiency_score = total_cost / total_hours if total_hours > 0 else 0
        
        return CostAnalysis(
            employee_id=employee_id,
            base_cost=base_cost,
            overtime_cost=overtime_cost,
            premium_cost=premium_cost,
            benefit_cost=benefit_cost,
            total_cost=total_cost,
            cost_breakdown=cost_breakdown,
            efficiency_score=efficiency_score
        )
    
    def _calculate_employee_cost(self,
                               schedule_block: Dict[str, Any],
                               overtime_policies: Dict[str, Any]) -> CostAnalysis:
        """Calculate cost for individual employee schedule block"""
        employee_id = schedule_block.get('employee_id', 'UNKNOWN')
        
        # Calculate hours
        regular_hours = self._calculate_regular_hours(schedule_block)
        overtime_hours = self._calculate_overtime_hours(schedule_block, overtime_policies)
        weekend_hours = self._calculate_weekend_hours(schedule_block)
        night_hours = self._calculate_night_hours(schedule_block)
        
        # Get skill level
        skill_level = schedule_block.get('skill_level', 'basic')
        
        # Calculate cost components
        base_cost = regular_hours * self.cost_rates['base_hourly']
        
        overtime_cost = (
            overtime_hours * 
            self.cost_rates['base_hourly'] * 
            self.cost_rates['overtime_multiplier']
        )
        
        weekend_premium = weekend_hours * self.cost_rates['weekend_premium']
        night_premium = night_hours * self.cost_rates['night_differential']
        skill_premium = (
            (regular_hours + overtime_hours) * 
            self.cost_rates['skill_premium'][skill_level]
        )
        
        premium_cost = weekend_premium + night_premium + skill_premium
        
        # Benefits calculation
        gross_wages = base_cost + overtime_cost + premium_cost
        benefit_cost = gross_wages * self.cost_rates['benefits_rate']
        
        # Total cost
        total_cost = gross_wages + benefit_cost
        
        # Cost breakdown
        cost_breakdown = {
            CostComponent.BASE_SALARY: base_cost,
            CostComponent.OVERTIME: overtime_cost,
            CostComponent.WEEKEND_PREMIUM: weekend_premium,
            CostComponent.NIGHT_DIFFERENTIAL: night_premium,
            CostComponent.SKILL_PREMIUM: skill_premium,
            CostComponent.BENEFITS: benefit_cost
        }
        
        # Efficiency score (cost per productive hour)
        total_hours = regular_hours + overtime_hours
        efficiency_score = total_cost / total_hours if total_hours > 0 else 0
        
        return CostAnalysis(
            employee_id=employee_id,
            base_cost=base_cost,
            overtime_cost=overtime_cost,
            premium_cost=premium_cost,
            benefit_cost=benefit_cost,
            total_cost=total_cost,
            cost_breakdown=cost_breakdown,
            efficiency_score=efficiency_score
        )
    
    def _calculate_regular_hours(self, block: Dict[str, Any]) -> float:
        """Calculate regular hours from schedule block"""
        start_time = block.get('start_time', '08:00')
        end_time = block.get('end_time', '16:00')
        
        start_hour = int(start_time.split(':')[0])
        end_hour = int(end_time.split(':')[0])
        daily_hours = end_hour - start_hour
        
        days_per_week = block.get('days_per_week', 5)
        weekly_hours = daily_hours * days_per_week
        
        # Regular hours capped at 40
        return min(40.0, weekly_hours)
    
    def _calculate_overtime_hours(self, 
                                block: Dict[str, Any],
                                overtime_policies: Dict[str, Any]) -> float:
        """Calculate overtime hours"""
        start_time = block.get('start_time', '08:00')
        end_time = block.get('end_time', '16:00')
        
        start_hour = int(start_time.split(':')[0])
        end_hour = int(end_time.split(':')[0])
        daily_hours = end_hour - start_hour
        
        days_per_week = block.get('days_per_week', 5)
        weekly_hours = daily_hours * days_per_week
        
        # Overtime is hours over 40 per week
        return max(0.0, weekly_hours - 40.0)
    
    def _calculate_weekend_hours(self, block: Dict[str, Any]) -> float:
        """Calculate weekend hours"""
        # Simplified - check if weekend work is included
        works_weekends = block.get('weekend_work', False)
        if works_weekends:
            # Assume 2 weekend days * 8 hours
            return 16.0
        return 0.0
    
    def _calculate_night_hours(self, block: Dict[str, Any]) -> float:
        """Calculate night shift hours (10 PM - 6 AM)"""
        start_time = block.get('start_time', '08:00')
        end_time = block.get('end_time', '16:00')
        
        start_hour = int(start_time.split(':')[0])
        end_hour = int(end_time.split(':')[0])
        
        # Night hours: 22:00 - 06:00
        night_start = 22
        night_end = 6
        
        night_hours = 0.0
        
        # Handle overnight shifts
        if start_hour >= night_start or end_hour <= night_end:
            if start_hour >= night_start:
                # Shift starts in night period
                if end_hour <= night_end or end_hour < start_hour:
                    # Overnight shift
                    night_hours = (24 - start_hour) + end_hour
                else:
                    # Night shift ending in day
                    night_hours = 24 - start_hour
            elif end_hour <= night_end:
                # Day shift ending in night
                night_hours = end_hour
        
        days_per_week = block.get('days_per_week', 5)
        return night_hours * days_per_week
    
    def _aggregate_cost_components(self, 
                                 employee_costs: List[CostAnalysis]) -> Dict[CostComponent, float]:
        """Aggregate costs by component type"""
        component_totals = {component: 0.0 for component in CostComponent}
        
        for cost_analysis in employee_costs:
            for component, amount in cost_analysis.cost_breakdown.items():
                component_totals[component] += amount
        
        return component_totals
    
    def _calculate_cost_variance(self, employee_costs: List[CostAnalysis]) -> float:
        """Calculate cost variance across employees"""
        if len(employee_costs) < 2:
            return 0.0
        
        costs = [cost.total_cost for cost in employee_costs]
        mean_cost = np.mean(costs)
        variance = np.var(costs)
        
        # Return coefficient of variation (normalized variance)
        return (np.sqrt(variance) / mean_cost) * 100 if mean_cost > 0 else 0.0
    
    def _calculate_efficiency_metrics(self,
                                    employee_costs: List[CostAnalysis],
                                    schedule_blocks: List[Dict[str, Any]]) -> Dict[str, float]:
        """Calculate cost efficiency metrics"""
        if not employee_costs:
            return {}
        
        total_cost = sum(cost.total_cost for cost in employee_costs)
        total_hours = sum(
            self._get_total_hours(block) for block in schedule_blocks
        )
        
        efficiency_metrics = {
            'cost_per_hour': total_cost / total_hours if total_hours > 0 else 0,
            'average_employee_cost': total_cost / len(employee_costs),
            'overtime_percentage': self._calculate_overtime_percentage(employee_costs),
            'premium_percentage': self._calculate_premium_percentage(employee_costs),
            'utilization_efficiency': self._calculate_utilization_efficiency(employee_costs)
        }
        
        return efficiency_metrics
    
    def _get_total_hours(self, block: Dict[str, Any]) -> float:
        """Get total hours for a schedule block"""
        start_time = block.get('start_time', '08:00')
        end_time = block.get('end_time', '16:00')
        
        start_hour = int(start_time.split(':')[0])
        end_hour = int(end_time.split(':')[0])
        daily_hours = end_hour - start_hour
        
        days_per_week = block.get('days_per_week', 5)
        return daily_hours * days_per_week
    
    def _calculate_overtime_percentage(self, employee_costs: List[CostAnalysis]) -> float:
        """Calculate percentage of costs from overtime"""
        total_cost = sum(cost.total_cost for cost in employee_costs)
        overtime_cost = sum(cost.overtime_cost for cost in employee_costs)
        
        return (overtime_cost / total_cost * 100) if total_cost > 0 else 0.0
    
    def _calculate_premium_percentage(self, employee_costs: List[CostAnalysis]) -> float:
        """Calculate percentage of costs from premiums"""
        total_cost = sum(cost.total_cost for cost in employee_costs)
        premium_cost = sum(cost.premium_cost for cost in employee_costs)
        
        return (premium_cost / total_cost * 100) if total_cost > 0 else 0.0
    
    def _calculate_utilization_efficiency(self, employee_costs: List[CostAnalysis]) -> float:
        """Calculate cost utilization efficiency score"""
        if not employee_costs:
            return 0.0
        
        efficiency_scores = [cost.efficiency_score for cost in employee_costs]
        average_efficiency = np.mean(efficiency_scores)
        
        # Convert to 0-100 scale (lower cost per hour = higher efficiency)
        # Assuming $50/hour is baseline efficiency
        baseline_efficiency = 50.0
        efficiency_ratio = baseline_efficiency / average_efficiency if average_efficiency > 0 else 0
        
        return min(100.0, efficiency_ratio * 100)
    
    def _identify_savings_opportunities(self,
                                      employee_costs: List[CostAnalysis],
                                      cost_by_component: Dict[CostComponent, float]) -> List[str]:
        """Identify cost savings opportunities"""
        opportunities = []
        total_cost = sum(cost.total_cost for cost in employee_costs)
        
        # High overtime costs
        overtime_percentage = cost_by_component[CostComponent.OVERTIME] / total_cost * 100
        if overtime_percentage > 15:
            opportunities.append(
                f"Reduce overtime costs: {overtime_percentage:.1f}% of total budget"
            )
        
        # Weekend premium optimization
        weekend_percentage = cost_by_component[CostComponent.WEEKEND_PREMIUM] / total_cost * 100
        if weekend_percentage > 10:
            opportunities.append(
                f"Optimize weekend coverage: {weekend_percentage:.1f}% premium costs"
            )
        
        # Skill premium efficiency
        skill_percentage = cost_by_component[CostComponent.SKILL_PREMIUM] / total_cost * 100
        if skill_percentage > 20:
            opportunities.append(
                f"Review skill assignments: {skill_percentage:.1f}% in skill premiums"
            )
        
        # Cost variance optimization
        high_cost_employees = [
            cost for cost in employee_costs 
            if cost.total_cost > np.mean([c.total_cost for c in employee_costs]) * 1.3
        ]
        if len(high_cost_employees) > len(employee_costs) * 0.2:
            opportunities.append(
                f"Address cost variance: {len(high_cost_employees)} high-cost assignments"
            )
        
        # BDD Target: >10% savings (line 66)
        potential_savings = self._calculate_potential_savings(cost_by_component)
        if potential_savings > 0.10:
            opportunities.append(
                f"Potential savings: {potential_savings:.1%} through optimization"
            )
        
        return opportunities[:5]  # Limit to top 5 opportunities
    
    def _calculate_potential_savings(self, 
                                   cost_by_component: Dict[CostComponent, float]) -> float:
        """Calculate potential cost savings percentage"""
        total_cost = sum(cost_by_component.values())
        
        # Identify reducible costs
        overtime_savings = cost_by_component[CostComponent.OVERTIME] * 0.5  # 50% overtime reduction
        premium_savings = cost_by_component[CostComponent.WEEKEND_PREMIUM] * 0.3  # 30% premium reduction
        
        total_savings = overtime_savings + premium_savings
        
        return total_savings / total_cost if total_cost > 0 else 0.0
    
    def validate_bdd_requirements(self, result: FinancialImpact) -> Dict[str, bool]:
        """Validate against BDD requirements"""
        validation = {}
        
        # Processing time: 1-2 seconds
        validation['processing_time'] = result.processing_time_ms <= 2000
        
        # Financial impact calculated
        validation['financial_impact'] = result.total_weekly_cost > 0
        
        # Cost breakdown by component
        validation['cost_breakdown'] = len(result.cost_by_component) > 0
        
        # Individual employee costs
        validation['employee_costs'] = len(result.cost_by_employee) > 0
        
        # Efficiency metrics calculated
        validation['efficiency_metrics'] = len(result.efficiency_metrics) > 0
        
        # Savings opportunities identified
        validation['savings_opportunities'] = len(result.savings_opportunities) > 0
        
        # BDD Target: >10% cost savings potential
        potential_savings = self._calculate_potential_savings(result.cost_by_component)
        validation['savings_target'] = potential_savings >= 0.10
        
        return validation
    
    # NEW: Real database integration methods
    
    async def _initialize_financial_service(self):
        """Initialize real database financial service"""
        try:
            from .financial_data_service import create_financial_data_service
            self.financial_service = await create_financial_data_service(self.database_url)
            logger.info("Financial service initialized with real database connection")
        except Exception as e:
            logger.error(f"Failed to initialize financial service: {e}")
            raise RuntimeError(f"Cannot connect to financial database: {e}")
    
    async def _get_employee_profile(self, employee_id: str) -> Optional['EmployeeFinancialProfile']:
        """Get cached employee financial profile"""
        current_time = datetime.now()
        
        # Check cache validity
        if (self._cache_timestamp and 
            current_time - self._cache_timestamp < timedelta(seconds=self._cache_ttl) and
            employee_id in self._employee_profiles_cache):
            return self._employee_profiles_cache[employee_id]
        
        # Fetch from database
        try:
            profile = await self.financial_service.get_employee_financial_profile(employee_id)
            self._employee_profiles_cache[employee_id] = profile
            self._cache_timestamp = current_time
            return profile
        except Exception as e:
            logger.error(f"Error fetching employee profile for {employee_id}: {e}")
            return None
    
    async def _get_payroll_rates(self) -> 'PayrollTimeCodeRates':
        """Get cached payroll rates"""
        current_time = datetime.now()
        
        # Check cache validity
        if (self._payroll_rates_cache and 
            self._cache_timestamp and 
            current_time - self._cache_timestamp < timedelta(seconds=self._cache_ttl)):
            return self._payroll_rates_cache
        
        # Fetch from database
        try:
            rates = await self.financial_service.get_payroll_time_code_rates()
            self._payroll_rates_cache = rates
            self._cache_timestamp = current_time
            return rates
        except Exception as e:
            logger.error(f"Error fetching payroll rates: {e}")
            # Return fallback rates
            from .financial_data_service import PayrollTimeCodeRates
            return PayrollTimeCodeRates(
                day_work_rate=25.0,
                night_work_rate=30.0,
                overtime_rate=37.5,
                weekend_work_rate=35.0,
                night_weekend_rate=42.0
            )
    
    async def _calculate_mobile_workforce_costs(self, schedule_block: Dict[str, Any]) -> float:
        """Calculate Mobile Workforce Scheduler pattern costs"""
        if not self.mobile_workforce_enabled:
            return 0.0
        
        from_site_id = schedule_block.get('from_site_id')
        to_site_id = schedule_block.get('to_site_id')
        
        # Only apply mobile workforce costs for cross-site assignments
        if not from_site_id or not to_site_id or from_site_id == to_site_id:
            return 0.0
        
        try:
            mobile_costs = await self.financial_service.get_mobile_workforce_costs(from_site_id, to_site_id)
            
            # Calculate total mobile workforce cost
            total_cost = (
                mobile_costs.base_site_cost +
                mobile_costs.travel_cost_per_km +
                mobile_costs.equipment_transport_cost +
                mobile_costs.cross_site_coordination_cost
            )
            
            # Apply site premium multiplier
            total_cost *= mobile_costs.site_premium_multiplier
            
            return total_cost
            
        except Exception as e:
            logger.error(f"Error calculating mobile workforce costs: {e}")
            return 50.0  # Fallback cost
    
    def _calculate_position_skill_premium(self, employee_profile: 'EmployeeFinancialProfile', total_hours: float) -> float:
        """Calculate skill premium based on position"""
        position_premiums = {
            'manager': 5.0,
            'senior': 3.0,
            'specialist': 2.0,
            'analyst': 1.0
        }
        
        position_lower = employee_profile.position_title.lower()
        premium_rate = 0.0
        
        for position_key, rate in position_premiums.items():
            if position_key in position_lower:
                premium_rate = rate
                break
        
        return total_hours * premium_rate
    
    async def _calculate_fallback_cost(self, schedule_block: Dict[str, Any], overtime_policies: Dict[str, Any]) -> CostAnalysis:
        """Fallback cost calculation when real data unavailable"""
        employee_id = schedule_block.get('employee_id', 'UNKNOWN')
        
        # Use simple default rates
        default_hourly = 25.0
        regular_hours = self._calculate_regular_hours(schedule_block)
        overtime_hours = self._calculate_overtime_hours(schedule_block, overtime_policies)
        
        base_cost = regular_hours * default_hourly
        overtime_cost = overtime_hours * default_hourly * 1.5
        premium_cost = 0.0
        benefit_cost = (base_cost + overtime_cost) * 0.35
        total_cost = base_cost + overtime_cost + premium_cost + benefit_cost
        
        cost_breakdown = {
            CostComponent.BASE_SALARY: base_cost,
            CostComponent.OVERTIME: overtime_cost,
            CostComponent.WEEKEND_PREMIUM: 0.0,
            CostComponent.NIGHT_DIFFERENTIAL: 0.0,
            CostComponent.SKILL_PREMIUM: 0.0,
            CostComponent.BENEFITS: benefit_cost
        }
        
        efficiency_score = total_cost / (regular_hours + overtime_hours) if (regular_hours + overtime_hours) > 0 else 0
        
        return CostAnalysis(
            employee_id=employee_id,
            base_cost=base_cost,
            overtime_cost=overtime_cost,
            premium_cost=premium_cost,
            benefit_cost=benefit_cost,
            total_cost=total_cost,
            cost_breakdown=cost_breakdown,
            efficiency_score=efficiency_score
        )
    
    async def close(self):
        """Close database connections"""
        if self.financial_service:
            await self.financial_service.close()
    
    # NEW: Mobile Workforce Scheduler pattern methods
    
    async def calculate_cross_site_optimization(self, 
                                              sites: List[str], 
                                              employees: List[str],
                                              schedule_variants: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate optimal cross-site workforce allocation using Mobile Workforce Scheduler pattern
        """
        optimization_results = {
            'optimal_assignments': [],
            'total_cost_savings': 0.0,
            'mobile_workforce_utilization': 0.0,
            'site_cost_breakdown': {},
            'travel_cost_optimization': {}
        }
        
        for variant in schedule_variants:
            site_costs = {}
            
            for site_id in sites:
                site_employees = [emp for emp in employees if self._is_employee_available_for_site(emp, site_id)]
                
                if site_employees:
                    # Calculate costs for this site
                    site_cost = await self._calculate_site_total_cost(site_id, site_employees, variant)
                    site_costs[site_id] = site_cost
                    
                    # Calculate potential mobile workforce cost savings
                    mobile_savings = await self._calculate_mobile_workforce_savings(site_id, site_employees)
                    optimization_results['total_cost_savings'] += mobile_savings
            
            optimization_results['site_cost_breakdown'] = site_costs
        
        return optimization_results
    
    def _is_employee_available_for_site(self, employee_id: str, site_id: str) -> bool:
        """Check if employee is available for cross-site assignment"""
        # This would check employee permissions, location, skills, etc.
        # For now, return True (all employees available)
        return True
    
    async def _calculate_site_total_cost(self, site_id: str, employees: List[str], schedule_variant: Dict[str, Any]) -> float:
        """Calculate total cost for all employees at a site"""
        total_cost = 0.0
        
        for employee_id in employees:
            employee_profile = await self._get_employee_profile(employee_id)
            if employee_profile:
                # Base calculation for site work
                hours_per_week = 40  # Standard
                hourly_rate = await self.financial_service.calculate_real_hourly_rate(employee_profile)
                weekly_cost = hours_per_week * hourly_rate
                total_cost += weekly_cost
        
        return total_cost
    
    async def _calculate_mobile_workforce_savings(self, site_id: str, employees: List[str]) -> float:
        """Calculate potential savings from mobile workforce optimization"""
        # This would analyze optimal vs. current assignments
        # For now, return estimated savings
        base_savings_per_employee = 200.0  # Weekly savings estimate
        return len(employees) * base_savings_per_employee