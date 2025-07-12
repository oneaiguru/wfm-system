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
    
    def __init__(self):
        # BDD Requirement: Cost efficiency 30% weight (line 66)
        self.cost_weight = 0.30
        
        # Standard cost rates (hourly)
        self.cost_rates = {
            'base_hourly': 25.00,        # Base hourly rate
            'overtime_multiplier': 1.5,   # Overtime multiplier
            'weekend_premium': 5.00,      # Weekend premium per hour
            'night_differential': 3.00,   # Night shift differential
            'skill_premium': {
                'basic': 0.00,
                'intermediate': 2.50,
                'expert': 5.00
            },
            'benefits_rate': 0.35,        # 35% benefits on base salary
            'training_cost': 1000.00,     # Training cost per skill
            'hiring_cost': 3000.00        # Hiring cost per new employee
        }
        
        # BDD target processing time: 1-2 seconds
        self.processing_target = 2.0
        
    def calculate_financial_impact(self,
                                 schedule_variant: Dict[str, Any],
                                 staffing_costs: Dict[str, Any],
                                 overtime_policies: Dict[str, Any]) -> FinancialImpact:
        """
        Main cost calculation per BDD specification
        Input: Staffing costs + overtime
        Output: Financial impact
        Processing: 1-2 seconds (BDD requirement)
        """
        start_time = datetime.now()
        
        schedule_blocks = schedule_variant.get('schedule_blocks', [])
        
        # Step 1: Calculate individual employee costs
        employee_costs = []
        for block in schedule_blocks:
            cost_analysis = self._calculate_employee_cost(block, overtime_policies)
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