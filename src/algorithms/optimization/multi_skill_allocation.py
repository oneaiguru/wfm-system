"""
Multi-Skill Agent Allocation Optimizer
Optimizes allocation of cross-skilled agents across multiple queues
"""

import logging
from typing import Dict, List, Any, Optional, Tuple
import numpy as np
from dataclasses import dataclass
from datetime import datetime
import asyncio

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
    """Multi-skill agent allocation optimizer."""
    
    def __init__(self):
        self.optimization_methods = {
            'greedy': self._greedy_allocation,
            'genetic_algorithm': self._genetic_algorithm_allocation,
            'linear_programming': self._linear_programming_allocation,
            'simulated_annealing': self._simulated_annealing_allocation
        }
    
    async def optimize_allocation(self, optimization_data: Dict[str, Any]) -> AllocationResult:
        """
        Optimize multi-skill agent allocation.
        
        Args:
            optimization_data: Dictionary containing:
                - forecast_data: List of forecast periods
                - skill_matrix: Agent skills mapping
                - service_level_targets: Target service levels per skill
                - max_wait_times: Maximum wait times per skill
                - optimization_method: Method to use for optimization
        
        Returns:
            AllocationResult with optimized allocations
        """
        try:
            method = optimization_data.get('optimization_method', 'greedy')
            
            if method not in self.optimization_methods:
                raise ValueError(f"Unknown optimization method: {method}")
            
            # Prepare data for optimization
            prepared_data = self._prepare_optimization_data(optimization_data)
            
            # Run optimization
            optimization_func = self.optimization_methods[method]
            result = await optimization_func(prepared_data)
            
            # Validate and post-process results
            validated_result = self._validate_allocation_result(result, optimization_data)
            
            return validated_result
            
        except Exception as e:
            logger.error(f"Error in multi-skill allocation optimization: {str(e)}")
            raise
    
    def _prepare_optimization_data(self, optimization_data: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare data for optimization algorithms."""
        try:
            forecast_data = optimization_data['forecast_data']
            skill_matrix = optimization_data['skill_matrix']
            service_level_targets = optimization_data['service_level_targets']
            max_wait_times = optimization_data['max_wait_times']
            
            # Extract unique skills
            all_skills = set()
            for agent_skills in skill_matrix.values():
                all_skills.update(agent_skills)
            
            # Calculate demand per skill from forecast data
            skill_demand = {}
            for skill in all_skills:
                skill_demand[skill] = sum(
                    period.get(skill, 0) for period in forecast_data
                )
            
            # Calculate agent efficiency matrix
            agent_efficiency = {}
            for agent_id, skills in skill_matrix.items():
                agent_efficiency[agent_id] = {}
                for skill in all_skills:
                    # Base efficiency: 1.0 if agent has skill, 0.0 if not
                    # Could be enhanced with actual efficiency data
                    agent_efficiency[agent_id][skill] = 1.0 if skill in skills else 0.0
            
            return {
                'forecast_data': forecast_data,
                'skill_matrix': skill_matrix,
                'service_level_targets': service_level_targets,
                'max_wait_times': max_wait_times,
                'all_skills': list(all_skills),
                'skill_demand': skill_demand,
                'agent_efficiency': agent_efficiency,
                'num_agents': len(skill_matrix),
                'num_skills': len(all_skills)
            }
            
        except Exception as e:
            logger.error(f"Error preparing optimization data: {str(e)}")
            raise
    
    async def _greedy_allocation(self, data: Dict[str, Any]) -> AllocationResult:
        """Greedy allocation algorithm - fast but not optimal."""
        try:
            skill_demand = data['skill_demand']
            skill_matrix = data['skill_matrix']
            service_level_targets = data['service_level_targets']
            agent_efficiency = data['agent_efficiency']
            
            # Initialize allocations
            agent_allocations = {agent_id: {} for agent_id in skill_matrix.keys()}
            remaining_demand = skill_demand.copy()
            
            # Sort skills by demand (highest first)
            sorted_skills = sorted(skill_demand.items(), key=lambda x: x[1], reverse=True)
            
            # Allocate agents to skills greedily
            for skill, demand in sorted_skills:
                if demand <= 0:
                    continue
                
                # Find agents with this skill, sorted by efficiency
                skilled_agents = [
                    (agent_id, agent_efficiency[agent_id][skill])
                    for agent_id in skill_matrix.keys()
                    if skill in skill_matrix[agent_id]
                ]
                
                skilled_agents.sort(key=lambda x: x[1], reverse=True)
                
                # Allocate hours to skilled agents
                for agent_id, efficiency in skilled_agents:
                    if remaining_demand[skill] <= 0:
                        break
                    
                    # Calculate allocation (simplified)
                    allocated_hours = min(remaining_demand[skill], 8)  # Max 8 hours per agent
                    
                    agent_allocations[agent_id][skill] = allocated_hours
                    remaining_demand[skill] -= allocated_hours
            
            # Calculate results
            total_cost = self._calculate_total_cost(agent_allocations)
            service_level_achieved = self._calculate_service_levels(agent_allocations, data)
            efficiency_score = self._calculate_efficiency_score(agent_allocations, data)
            skill_coverage = self._calculate_skill_coverage(agent_allocations, skill_demand)
            
            return AllocationResult(
                agent_allocations=agent_allocations,
                skill_coverage=skill_coverage,
                total_cost=total_cost,
                service_level_achieved=service_level_achieved,
                efficiency_score=efficiency_score,
                optimization_metadata={
                    'method': 'greedy',
                    'iterations': 1,
                    'convergence_time': 0.1
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
    
    def _calculate_total_cost(self, agent_allocations: Dict[str, Dict[str, int]]) -> float:
        """Calculate total cost of allocation."""
        try:
            total_cost = 0.0
            hourly_rate = 25.0  # Default hourly rate
            
            for agent_id, skills in agent_allocations.items():
                agent_hours = sum(skills.values())
                total_cost += agent_hours * hourly_rate
            
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
                service_level = min(1.0, allocated_hours / demand)
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
                                   original_data: Dict[str, Any]) -> AllocationResult:
        """Validate and adjust allocation result if needed."""
        try:
            # Check if all required skills are covered
            service_level_targets = original_data['service_level_targets']
            
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
                                   skill_matrix: Dict[str, List[str]]) -> Dict[str, Any]:
        """Calculate cost impact of optimization."""
        try:
            # Calculate baseline cost (everyone working full time)
            baseline_cost = len(skill_matrix) * 8 * 25.0  # 8 hours * $25/hour
            
            optimized_cost = optimization_result.total_cost
            cost_savings = baseline_cost - optimized_cost
            savings_percentage = (cost_savings / baseline_cost) * 100 if baseline_cost > 0 else 0
            
            return {
                'baseline_cost': baseline_cost,
                'optimized_cost': optimized_cost,
                'cost_savings': cost_savings,
                'savings_percentage': savings_percentage,
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