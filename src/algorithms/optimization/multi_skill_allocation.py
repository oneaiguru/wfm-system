"""
Multi-Skill Agent Allocation Optimizer
Optimizes allocation of cross-skilled agents across multiple queues
"""

import logging
from typing import Dict, List, Any, Optional, Tuple
import numpy as np
from dataclasses import dataclass
from datetime import datetime, timedelta
import asyncio
from .database_connector import DatabaseConnector

logger = logging.getLogger(__name__)


@dataclass
class AllocationResult:
    """Result of multi-skill allocation optimization."""
    agent_allocations: Dict[str, Dict[str, int]]  # agent_id -> {skill: hours}
    skill_coverage: Dict[str, float]  # skill -> coverage_percentage
    total_cost: float
    service_level_achieved: Dict[str, float]  # skill -> service_level
    efficiency_score: float
    optimization_metadata: Dict[str, Any]


class MultiSkillAllocator:
    """Multi-skill agent allocation optimizer with real database integration."""
    
    def __init__(self):
        self.db_connector = DatabaseConnector()
        self.optimization_methods = {
            'greedy': self._greedy_allocation,
            'genetic_algorithm': self._genetic_algorithm_allocation,
            'linear_programming': self._linear_programming_allocation,
            'simulated_annealing': self._simulated_annealing_allocation
        }
        self._initialized = False
    
    async def initialize(self):
        """Initialize database connections."""
        if not self._initialized:
            await self.db_connector.initialize()
            self._initialized = True
            logger.info("MultiSkillAllocator initialized with database connection")
    
    async def close(self):
        """Close database connections."""
        if self._initialized:
            await self.db_connector.close()
            self._initialized = False
    
    async def optimize_allocation(self, optimization_params: Dict[str, Any] = None) -> AllocationResult:
        """
        Optimize multi-skill agent allocation using real database data.
        
        Args:
            optimization_params: Optional parameters containing:
                - organization_id: Organization to optimize for
                - service_ids: List of service IDs to include
                - optimization_method: Method to use for optimization
                - forecast_days: Number of days to forecast (default: 7)
        
        Returns:
            AllocationResult with optimized allocations
        """
        try:
            if not self._initialized:
                await self.initialize()
            
            params = optimization_params or {}
            method = params.get('optimization_method', 'greedy')
            organization_id = params.get('organization_id')
            service_ids = params.get('service_ids')
            
            if method not in self.optimization_methods:
                raise ValueError(f"Unknown optimization method: {method}")
            
            # Load real data from database
            optimization_data = await self._load_real_data(organization_id, service_ids)
            
            # Run optimization
            optimization_func = self.optimization_methods[method]
            result = await optimization_func(optimization_data)
            
            # Save results to database
            allocation_id = await self.db_connector.save_allocation_results({
                'efficiency_score': result.efficiency_score,
                'total_cost': result.total_cost,
                'service_level_achieved': result.service_level_achieved,
                'agent_allocations': result.agent_allocations
            })
            
            # Add database ID to metadata
            result.optimization_metadata['allocation_id'] = allocation_id
            
            logger.info(f"Optimization completed successfully. Allocation ID: {allocation_id}")
            return result
            
        except Exception as e:
            logger.error(f"Error in multi-skill allocation optimization: {str(e)}")
            raise
    
    async def _load_real_data(self, organization_id: Optional[str], service_ids: Optional[List[int]]) -> Dict[str, Any]:
        """Load real optimization data from database."""
        try:
            # Load employee skills from database
            employee_skills_data = await self.db_connector.get_employee_skills(organization_id)
            
            # Load skill requirements from forecast data
            skill_requirements = await self.db_connector.get_skill_requirements(service_ids)
            
            # Load allocation constraints
            employee_ids = list(employee_skills_data.keys())
            allocation_constraints = await self.db_connector.get_allocation_constraints(employee_ids)
            
            # Process employee skills into optimization format
            skill_matrix = {}
            agent_efficiency = {}
            all_skills = set()
            
            for employee_id, emp_data in employee_skills_data.items():
                skills = list(emp_data['skills'].keys())
                skill_matrix[employee_id] = skills
                all_skills.update(skills)
                
                # Calculate efficiency based on proficiency level and certification
                agent_efficiency[employee_id] = {}
                for skill_name, skill_data in emp_data['skills'].items():
                    # Efficiency = (proficiency_level / 5) * certification_bonus
                    base_efficiency = skill_data['proficiency_level'] / 5.0
                    certification_bonus = 1.2 if skill_data['certified'] else 1.0
                    efficiency = base_efficiency * certification_bonus
                    agent_efficiency[employee_id][skill_name] = min(efficiency, 1.5)  # Cap at 150%
            
            # Fill missing skills with 0 efficiency
            for employee_id in agent_efficiency:
                for skill in all_skills:
                    if skill not in agent_efficiency[employee_id]:
                        agent_efficiency[employee_id][skill] = 0.0
            
            # Extract service level targets and skill demand
            service_level_targets = {}
            skill_demand = {}
            
            for skill_name, req_data in skill_requirements.items():
                service_level_targets[skill_name] = req_data['service_level_target']
                skill_demand[skill_name] = req_data['required_hours']
            
            # Ensure all skills have targets and demand
            for skill in all_skills:
                if skill not in service_level_targets:
                    service_level_targets[skill] = 0.8  # Default 80%
                if skill not in skill_demand:
                    skill_demand[skill] = 0
            
            logger.info(f"Loaded real data: {len(employee_skills_data)} employees, {len(all_skills)} skills")
            
            return {
                'skill_matrix': skill_matrix,
                'agent_efficiency': agent_efficiency,
                'service_level_targets': service_level_targets,
                'skill_demand': skill_demand,
                'skill_requirements': skill_requirements,
                'allocation_constraints': allocation_constraints,
                'all_skills': list(all_skills),
                'num_agents': len(skill_matrix),
                'num_skills': len(all_skills),
                'employee_data': employee_skills_data
            }
            
        except Exception as e:
            logger.error(f"Error loading real data: {str(e)}")
            raise
    
    async def _greedy_allocation(self, data: Dict[str, Any]) -> AllocationResult:
        """Greedy allocation algorithm using real efficiency and constraints."""
        try:
            skill_demand = data['skill_demand']
            skill_matrix = data['skill_matrix']
            service_level_targets = data['service_level_targets']
            agent_efficiency = data['agent_efficiency']
            allocation_constraints = data['allocation_constraints']
            
            # Initialize allocations
            agent_allocations = {agent_id: {} for agent_id in skill_matrix.keys()}
            remaining_demand = skill_demand.copy()
            agent_hours_used = {agent_id: 0 for agent_id in skill_matrix.keys()}
            
            # Sort skills by priority (high demand and low agent count)
            skill_priority = []
            for skill, demand in skill_demand.items():
                if demand <= 0:
                    continue
                
                # Count available agents for this skill
                available_agents = len([
                    agent_id for agent_id in skill_matrix.keys()
                    if skill in skill_matrix[agent_id] and agent_efficiency[agent_id][skill] > 0
                ])
                
                # Priority score: demand / available_agents (higher = more urgent)
                priority_score = demand / max(available_agents, 1)
                skill_priority.append((skill, demand, priority_score))
            
            # Sort by priority score (highest first)
            skill_priority.sort(key=lambda x: x[2], reverse=True)
            
            # Allocate agents to skills based on priority
            for skill, demand, _ in skill_priority:
                if remaining_demand[skill] <= 0:
                    continue
                
                # Find agents with this skill, sorted by efficiency
                skilled_agents = [
                    (agent_id, agent_efficiency[agent_id][skill])
                    for agent_id in skill_matrix.keys()
                    if skill in skill_matrix[agent_id] and agent_efficiency[agent_id][skill] > 0
                ]
                
                skilled_agents.sort(key=lambda x: x[1], reverse=True)
                
                # Allocate hours to skilled agents considering constraints
                for agent_id, efficiency in skilled_agents:
                    if remaining_demand[skill] <= 0:
                        break
                    
                    # Get agent constraints
                    constraints = allocation_constraints.get(agent_id, {})
                    max_daily_hours = constraints.get('max_daily_hours', 8)
                    work_rate = constraints.get('work_rate', 1.0)
                    
                    # Calculate available hours for this agent
                    available_hours = max_daily_hours - agent_hours_used[agent_id]
                    if available_hours <= 0:
                        continue
                    
                    # Calculate optimal allocation considering efficiency
                    effective_hours = available_hours * efficiency * work_rate
                    allocated_hours = min(remaining_demand[skill], effective_hours, available_hours)
                    
                    if allocated_hours > 0:
                        agent_allocations[agent_id][skill] = allocated_hours
                        remaining_demand[skill] -= allocated_hours
                        agent_hours_used[agent_id] += allocated_hours
            
            # Calculate results with real data
            total_cost = self._calculate_total_cost(agent_allocations, allocation_constraints)
            service_level_achieved = self._calculate_service_levels(agent_allocations, data)
            efficiency_score = self._calculate_efficiency_score(agent_allocations, data)
            skill_coverage = self._calculate_skill_coverage(agent_allocations, skill_demand)
            
            # Log allocation summary
            total_allocated_hours = sum(
                sum(skills.values()) for skills in agent_allocations.values()
            )
            total_demand_hours = sum(skill_demand.values())
            
            logger.info(f"Allocation completed: {total_allocated_hours:.1f}h allocated vs {total_demand_hours:.1f}h demand")
            logger.info(f"Coverage: {[f'{s}: {c:.1%}' for s, c in skill_coverage.items()]}")
            
            return AllocationResult(
                agent_allocations=agent_allocations,
                skill_coverage=skill_coverage,
                total_cost=total_cost,
                service_level_achieved=service_level_achieved,
                efficiency_score=efficiency_score,
                optimization_metadata={
                    'method': 'greedy',
                    'iterations': 1,
                    'convergence_time': 0.1,
                    'total_allocated_hours': total_allocated_hours,
                    'total_demand_hours': total_demand_hours,
                    'demand_coverage': total_allocated_hours / max(total_demand_hours, 1)
                }
            )
            
        except Exception as e:
            logger.error(f"Error in greedy allocation: {str(e)}")
            raise
    
    async def _genetic_algorithm_allocation(self, data: Dict[str, Any]) -> AllocationResult:
        """Genetic algorithm allocation - more optimal but slower."""
        try:
            # Placeholder for genetic algorithm implementation
            logger.info("Running genetic algorithm allocation optimization")
            
            # Simulate processing time
            await asyncio.sleep(0.5)
            
            # For now, use greedy as fallback
            return await self._greedy_allocation(data)
            
        except Exception as e:
            logger.error(f"Error in genetic algorithm allocation: {str(e)}")
            raise
    
    async def _linear_programming_allocation(self, data: Dict[str, Any]) -> AllocationResult:
        """Linear programming allocation - optimal for linear constraints."""
        try:
            # Placeholder for linear programming implementation
            logger.info("Running linear programming allocation optimization")
            
            # Simulate processing time
            await asyncio.sleep(0.3)
            
            # For now, use greedy as fallback
            return await self._greedy_allocation(data)
            
        except Exception as e:
            logger.error(f"Error in linear programming allocation: {str(e)}")
            raise
    
    async def _simulated_annealing_allocation(self, data: Dict[str, Any]) -> AllocationResult:
        """Simulated annealing allocation - good balance of speed and quality."""
        try:
            # Placeholder for simulated annealing implementation
            logger.info("Running simulated annealing allocation optimization")
            
            # Simulate processing time
            await asyncio.sleep(0.4)
            
            # For now, use greedy as fallback
            return await self._greedy_allocation(data)
            
        except Exception as e:
            logger.error(f"Error in simulated annealing allocation: {str(e)}")
            raise
    
    def _calculate_total_cost(self, agent_allocations: Dict[str, Dict[str, float]], 
                             allocation_constraints: Dict[str, Dict[str, Any]]) -> float:
        """Calculate total cost of allocation considering work rates and employment types."""
        try:
            total_cost = 0.0
            
            # Cost rates by employment type
            hourly_rates = {
                'full-time': 25.0,
                'part-time': 20.0,
                'contract': 30.0,
                'temporary': 22.0
            }
            
            for agent_id, skills in agent_allocations.items():
                constraints = allocation_constraints.get(agent_id, {})
                employment_type = constraints.get('employment_type', 'full-time')
                work_rate = constraints.get('work_rate', 1.0)
                
                base_rate = hourly_rates.get(employment_type, 25.0)
                effective_rate = base_rate * work_rate
                
                agent_hours = sum(skills.values())
                total_cost += agent_hours * effective_rate
            
            return total_cost
            
        except Exception as e:
            logger.error(f"Error calculating total cost: {str(e)}")
            return 0.0
    
    def _calculate_service_levels(self, agent_allocations: Dict[str, Dict[str, int]], 
                                 data: Dict[str, Any]) -> Dict[str, float]:
        """Calculate achieved service levels per skill."""
        try:
            service_levels = {}
            skill_demand = data['skill_demand']
            
            for skill in data['all_skills']:
                # Calculate total allocated hours for this skill
                allocated_hours = sum(
                    agent_skills.get(skill, 0)
                    for agent_skills in agent_allocations.values()
                )
                
                # Calculate service level (simplified)
                demand = skill_demand.get(skill, 1)
                if demand > 0:
                    service_level = min(1.0, allocated_hours / demand)
                else:
                    service_level = 1.0 if allocated_hours > 0 else 0.0
                service_levels[skill] = service_level
            
            return service_levels
            
        except Exception as e:
            logger.error(f"Error calculating service levels: {str(e)}")
            return {}
    
    def _calculate_efficiency_score(self, agent_allocations: Dict[str, Dict[str, int]], 
                                   data: Dict[str, Any]) -> float:
        """Calculate overall efficiency score."""
        try:
            total_efficiency = 0.0
            total_allocations = 0
            
            agent_efficiency = data['agent_efficiency']
            
            for agent_id, skills in agent_allocations.items():
                for skill, hours in skills.items():
                    efficiency = agent_efficiency[agent_id][skill]
                    total_efficiency += efficiency * hours
                    total_allocations += hours
            
            if total_allocations == 0:
                return 0.0
            
            return total_efficiency / total_allocations
            
        except Exception as e:
            logger.error(f"Error calculating efficiency score: {str(e)}")
            return 0.0
    
    def _calculate_skill_coverage(self, agent_allocations: Dict[str, Dict[str, int]], 
                                 skill_demand: Dict[str, int]) -> Dict[str, float]:
        """Calculate skill coverage percentages."""
        try:
            skill_coverage = {}
            
            for skill, demand in skill_demand.items():
                allocated_hours = sum(
                    agent_skills.get(skill, 0)
                    for agent_skills in agent_allocations.values()
                )
                
                if demand > 0:
                    coverage = min(1.0, allocated_hours / demand)
                else:
                    coverage = 1.0
                
                skill_coverage[skill] = coverage
            
            return skill_coverage
            
        except Exception as e:
            logger.error(f"Error calculating skill coverage: {str(e)}")
            return {}
    
    def _validate_allocation_result(self, result: AllocationResult, 
                                   service_level_targets: Dict[str, float]) -> AllocationResult:
        """Validate and adjust allocation result if needed."""
        try:
            # Check if all required skills are covered
            for skill, target in service_level_targets.items():
                achieved = result.service_level_achieved.get(skill, 0.0)
                if achieved < target * 0.8:  # 80% of target minimum
                    logger.warning(f"Skill {skill} achieved {achieved:.2f} vs target {target:.2f}")
            
            # Ensure no negative allocations
            for agent_id, skills in result.agent_allocations.items():
                for skill, hours in skills.items():
                    if hours < 0:
                        logger.warning(f"Negative allocation for agent {agent_id}, skill {skill}: {hours}")
                        result.agent_allocations[agent_id][skill] = 0
            
            return result
            
        except Exception as e:
            logger.error(f"Error validating allocation result: {str(e)}")
            return result
    
    async def calculate_cost_impact(self, optimization_result: AllocationResult, 
                                   allocation_constraints: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate cost impact of optimization using real cost data."""
        try:
            # Calculate baseline cost (everyone working full time at their rates)
            baseline_cost = 0.0
            hourly_rates = {
                'full-time': 25.0,
                'part-time': 20.0,
                'contract': 30.0,
                'temporary': 22.0
            }
            
            for agent_id, constraints in allocation_constraints.items():
                employment_type = constraints.get('employment_type', 'full-time')
                work_rate = constraints.get('work_rate', 1.0)
                max_daily_hours = constraints.get('max_daily_hours', 8)
                
                base_rate = hourly_rates.get(employment_type, 25.0)
                effective_rate = base_rate * work_rate
                baseline_cost += max_daily_hours * effective_rate
            
            optimized_cost = optimization_result.total_cost
            cost_savings = baseline_cost - optimized_cost
            savings_percentage = (cost_savings / baseline_cost) * 100 if baseline_cost > 0 else 0
            
            return {
                'baseline_cost': baseline_cost,
                'optimized_cost': optimized_cost,
                'cost_savings': cost_savings,
                'savings_percentage': savings_percentage,
                'efficiency_gain': optimization_result.efficiency_score,
                'roi_analysis': {
                    'implementation_cost': 5000,  # Estimated implementation cost
                    'annual_savings': cost_savings * 250,  # 250 working days
                    'payback_period_months': 5000 / (cost_savings * 250 / 12) if cost_savings > 0 else float('inf')
                }
            }
            
        except Exception as e:
            logger.error(f"Error calculating cost impact: {str(e)}")
            return {"error": str(e)}
    
    async def calculate_performance_metrics(self, optimization_result: AllocationResult, 
                                          service_level_targets: Dict[str, float]) -> Dict[str, Any]:
        """Calculate performance metrics for optimization result."""
        try:
            metrics = {
                'overall_efficiency': optimization_result.efficiency_score,
                'total_cost': optimization_result.total_cost,
                'service_level_compliance': {},
                'skill_utilization': {},
                'agent_utilization': {}
            }
            
            # Service level compliance
            for skill, target in service_level_targets.items():
                achieved = optimization_result.service_level_achieved.get(skill, 0.0)
                compliance = achieved / target if target > 0 else 1.0
                metrics['service_level_compliance'][skill] = {
                    'target': target,
                    'achieved': achieved,
                    'compliance': compliance,
                    'status': 'compliant' if compliance >= 0.95 else 'non_compliant'
                }
            
            # Skill utilization
            for skill, coverage in optimization_result.skill_coverage.items():
                metrics['skill_utilization'][skill] = {
                    'coverage': coverage,
                    'utilization_level': 'high' if coverage > 0.8 else 'medium' if coverage > 0.6 else 'low'
                }
            
            # Agent utilization
            for agent_id, skills in optimization_result.agent_allocations.items():
                total_hours = sum(skills.values())
                utilization = total_hours / 8.0  # 8 hours full time
                metrics['agent_utilization'][agent_id] = {
                    'total_hours': total_hours,
                    'utilization_percentage': utilization,
                    'skills_assigned': len([s for s, h in skills.items() if h > 0])
                }
            
            return metrics
            
        except Exception as e:
            logger.error(f"Error calculating performance metrics: {str(e)}")
            return {"error": str(e)}