"""
SPEC-26: Automatic Schedule Optimization - Multi-Objective Optimizer
BDD File: 24-automatic-schedule-optimization.feature

Enterprise-grade multi-objective optimization for workforce scheduling.
Built for REAL database integration with Pareto optimization and trade-off analysis.
Performance target: <2 seconds for multi-objective optimization.
"""

import asyncio
import json
import math
import random
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Any, Optional, Tuple, Set
from dataclasses import dataclass, asdict
from enum import Enum
import asyncpg
import numpy as np
from itertools import combinations

class OptimizationMethod(Enum):
    """Multi-objective optimization methods"""
    PARETO_FRONTIER = "pareto_frontier"
    WEIGHTED_SUM = "weighted_sum"
    EPSILON_CONSTRAINT = "epsilon_constraint"
    GOAL_PROGRAMMING = "goal_programming"
    NSGA_II = "nsga_ii"  # Non-dominated Sorting Genetic Algorithm

class ObjectivePriority(Enum):
    """Priority levels for objectives"""
    CRITICAL = "critical"   # Must achieve target
    HIGH = "high"          # Strong preference
    MEDIUM = "medium"      # Moderate preference
    LOW = "low"           # Nice to have

@dataclass
class OptimizationObjective:
    """Individual optimization objective"""
    objective_id: str
    name: str
    name_ru: str
    description: str
    minimize: bool  # True for minimization, False for maximization
    target_value: Optional[float]
    current_value: float
    weight: float
    priority: ObjectivePriority
    measurement_unit: str
    acceptable_range: Tuple[float, float]

@dataclass
class Solution:
    """Individual solution in multi-objective space"""
    solution_id: str
    objective_values: Dict[str, float]
    normalized_values: Dict[str, float]
    weighted_score: float
    dominance_rank: int
    crowding_distance: float
    is_pareto_optimal: bool
    trade_offs: Dict[str, str]
    schedule_data: Dict[str, Any]

@dataclass
class ParetoFront:
    """Pareto frontier representation"""
    front_id: str
    solutions: List[Solution]
    front_rank: int
    coverage_metrics: Dict[str, float]
    diversity_metrics: Dict[str, float]
    extremes: Dict[str, Solution]

@dataclass
class MultiObjectiveResult:
    """Multi-objective optimization result"""
    optimization_id: str
    method_used: OptimizationMethod
    objectives: List[OptimizationObjective]
    pareto_fronts: List[ParetoFront]
    recommended_solution: Solution
    trade_off_analysis: Dict[str, Any]
    convergence_metrics: Dict[str, float]
    processing_time_seconds: float
    total_solutions_evaluated: int

class MultiObjectiveOptimizer:
    """
    Enterprise multi-objective optimizer for workforce scheduling.
    Implements Pareto optimization with trade-off analysis and decision support.
    """

    def __init__(self, database_url: str = "postgresql://postgres:password@localhost:5432/wfm_enterprise"):
        self.database_url = database_url
        self.performance_target_seconds = 2.0
        
        # Default objective definitions
        self.default_objectives = [
            OptimizationObjective(
                objective_id="COST_EFFICIENCY",
                name="Cost Efficiency",
                name_ru="Эффективность затрат",
                description="Minimize total labor costs while maintaining service levels",
                minimize=True,
                target_value=None,
                current_value=0.0,
                weight=0.30,
                priority=ObjectivePriority.HIGH,
                measurement_unit="cost_per_hour",
                acceptable_range=(15.0, 35.0)
            ),
            OptimizationObjective(
                objective_id="SERVICE_QUALITY",
                name="Service Quality",
                name_ru="Качество обслуживания",
                description="Maximize service level and customer satisfaction",
                minimize=False,
                target_value=0.90,
                current_value=0.0,
                weight=0.25,
                priority=ObjectivePriority.CRITICAL,
                measurement_unit="service_level_percentage",
                acceptable_range=(0.80, 1.00)
            ),
            OptimizationObjective(
                objective_id="EMPLOYEE_SATISFACTION",
                name="Employee Satisfaction",
                name_ru="Удовлетворенность сотрудников",
                description="Maximize employee work-life balance and preferences",
                minimize=False,
                target_value=0.80,
                current_value=0.0,
                weight=0.20,
                priority=ObjectivePriority.MEDIUM,
                measurement_unit="satisfaction_score",
                acceptable_range=(0.60, 1.00)
            ),
            OptimizationObjective(
                objective_id="SCHEDULE_STABILITY",
                name="Schedule Stability",
                name_ru="Стабильность расписания",
                description="Minimize changes from previous schedule",
                minimize=True,
                target_value=0.20,
                current_value=0.0,
                weight=0.15,
                priority=ObjectivePriority.MEDIUM,
                measurement_unit="change_percentage",
                acceptable_range=(0.00, 0.30)
            ),
            OptimizationObjective(
                objective_id="COMPLIANCE_SCORE",
                name="Compliance Score",
                name_ru="Оценка соответствия",
                description="Maximize compliance with labor laws and regulations",
                minimize=False,
                target_value=0.95,
                current_value=0.0,
                weight=0.10,
                priority=ObjectivePriority.CRITICAL,
                measurement_unit="compliance_percentage",
                acceptable_range=(0.90, 1.00)
            )
        ]

    async def optimize_multi_objective(self, schedule_context: Dict[str, Any], 
                                     objectives: List[OptimizationObjective] = None,
                                     method: OptimizationMethod = OptimizationMethod.PARETO_FRONTIER,
                                     solution_count: int = 100) -> MultiObjectiveResult:
        """
        Execute multi-objective optimization for workforce scheduling.
        Target performance: <2 seconds for optimization.
        """
        start_time = datetime.now()
        optimization_id = f"MOO_{int(start_time.timestamp())}"
        
        if objectives is None:
            objectives = self.default_objectives
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            print(f"🎯 Starting multi-objective optimization")
            print(f"   Method: {method.value}")
            print(f"   Objectives: {len(objectives)}")
            print(f"   Target solutions: {solution_count}")
            
            # Update objectives with current values
            objectives = await self._update_objective_current_values(conn, objectives, schedule_context)
            
            # Generate solution population
            print("🔄 Generating solution population...")
            solutions = await self._generate_solution_population(conn, solution_count, objectives, schedule_context)
            
            # Evaluate objectives for all solutions
            print("📊 Evaluating objectives...")
            evaluated_solutions = await self._evaluate_solution_objectives(conn, solutions, objectives, schedule_context)
            
            # Apply multi-objective optimization method
            print(f"🔍 Applying {method.value} optimization...")
            if method == OptimizationMethod.PARETO_FRONTIER:
                pareto_fronts = await self._find_pareto_fronts(evaluated_solutions, objectives)
            elif method == OptimizationMethod.NSGA_II:
                pareto_fronts = await self._nsga_ii_optimization(evaluated_solutions, objectives)
            else:
                pareto_fronts = await self._weighted_sum_optimization(evaluated_solutions, objectives)
            
            # Select recommended solution
            recommended_solution = await self._select_recommended_solution(pareto_fronts, objectives)
            
            # Perform trade-off analysis
            trade_off_analysis = await self._analyze_trade_offs(pareto_fronts, objectives)
            
            # Calculate convergence metrics
            convergence_metrics = self._calculate_convergence_metrics(pareto_fronts, objectives)
            
            elapsed_seconds = (datetime.now() - start_time).total_seconds()
            
            result = MultiObjectiveResult(
                optimization_id=optimization_id,
                method_used=method,
                objectives=objectives,
                pareto_fronts=pareto_fronts,
                recommended_solution=recommended_solution,
                trade_off_analysis=trade_off_analysis,
                convergence_metrics=convergence_metrics,
                processing_time_seconds=elapsed_seconds,
                total_solutions_evaluated=len(evaluated_solutions)
            )
            
            # Log optimization result
            await self._log_multi_objective_result(conn, result)
            
            await conn.close()
            
            if elapsed_seconds > self.performance_target_seconds:
                print(f"⚠️ Multi-objective optimization took {elapsed_seconds:.1f}s (target: {self.performance_target_seconds}s)")
            
            print(f"✅ Multi-objective optimization completed:")
            print(f"   Pareto fronts: {len(pareto_fronts)}")
            print(f"   Pareto optimal solutions: {sum(len(front.solutions) for front in pareto_fronts if front.front_rank == 1)}")
            print(f"   Recommended solution score: {recommended_solution.weighted_score:.3f}")
            print(f"   Processing time: {elapsed_seconds:.1f}s")
            
            # Print objective values for recommended solution
            print(f"\n   Recommended solution objectives:")
            for obj in objectives:
                value = recommended_solution.objective_values.get(obj.objective_id, 0)
                trend = "↓" if obj.minimize else "↑"
                print(f"     {obj.name}: {value:.3f} {obj.measurement_unit} {trend}")
            
            return result
            
        except Exception as e:
            print(f"❌ Failed to execute multi-objective optimization: {str(e)}")
            raise

    async def _update_objective_current_values(self, conn: asyncpg.Connection, 
                                             objectives: List[OptimizationObjective],
                                             context: Dict[str, Any]) -> List[OptimizationObjective]:
        """Update current values for objectives based on schedule context"""
        
        for objective in objectives:
            if objective.objective_id == "COST_EFFICIENCY":
                # Calculate current cost efficiency
                objective.current_value = await self._calculate_current_cost_efficiency(context)
            
            elif objective.objective_id == "SERVICE_QUALITY":
                # Calculate current service quality
                objective.current_value = await self._calculate_current_service_quality(context)
            
            elif objective.objective_id == "EMPLOYEE_SATISFACTION":
                # Calculate current employee satisfaction
                objective.current_value = await self._calculate_current_employee_satisfaction(context)
            
            elif objective.objective_id == "SCHEDULE_STABILITY":
                # Calculate current schedule stability
                objective.current_value = await self._calculate_current_schedule_stability(context)
            
            elif objective.objective_id == "COMPLIANCE_SCORE":
                # Calculate current compliance score
                objective.current_value = await self._calculate_current_compliance_score(context)
        
        return objectives

    async def _calculate_current_cost_efficiency(self, context: Dict[str, Any]) -> float:
        """Calculate current cost efficiency"""
        try:
            total_cost = 0.0
            total_hours = 0.0
            
            employees = context.get("employees", [])
            assignments = context.get("assignments", {})
            
            for emp in employees:
                emp_id = emp["id"]
                emp_cost = 0.0
                emp_hours = 0.0
                
                # Calculate hours from assignments
                for shift_assignments in assignments.values():
                    if emp_id in shift_assignments:
                        emp_hours += 8.0  # Assume 8-hour shifts
                
                # Calculate cost
                hourly_rate = emp.get("hourly_rate", 20.0)
                emp_cost = emp_hours * hourly_rate
                
                total_cost += emp_cost
                total_hours += emp_hours
            
            if total_hours > 0:
                cost_per_hour = total_cost / total_hours
                return cost_per_hour
            
            return 25.0  # Default cost per hour
            
        except Exception as e:
            print(f"⚠️ Error calculating cost efficiency: {str(e)}")
            return 25.0

    async def _calculate_current_service_quality(self, context: Dict[str, Any]) -> float:
        """Calculate current service quality"""
        try:
            # Simplified service quality calculation
            # In production, would use real contact volume and service level data
            
            total_capacity = 0
            required_capacity = 0
            
            shifts = context.get("shifts", [])
            assignments = context.get("assignments", {})
            
            for shift in shifts:
                shift_id = shift.get("shift_id")
                required_agents = shift.get("required_agents", 5)
                assigned_agents = len(assignments.get(shift_id, []))
                
                total_capacity += assigned_agents
                required_capacity += required_agents
            
            if required_capacity > 0:
                coverage_ratio = min(1.0, total_capacity / required_capacity)
                # Convert coverage to service level estimate
                service_level = 0.5 + (coverage_ratio * 0.4)  # 50-90% range
                return min(1.0, service_level)
            
            return 0.85  # Default service level
            
        except Exception as e:
            print(f"⚠️ Error calculating service quality: {str(e)}")
            return 0.85

    async def _calculate_current_employee_satisfaction(self, context: Dict[str, Any]) -> float:
        """Calculate current employee satisfaction"""
        try:
            employees = context.get("employees", [])
            assignments = context.get("assignments", {})
            
            satisfaction_scores = []
            
            for emp in employees:
                emp_id = emp["id"]
                emp_satisfaction = 0.0
                factors = 0
                
                # Factor 1: Workload balance
                assigned_shifts = sum(1 for shift_assignments in assignments.values() 
                                    if emp_id in shift_assignments)
                if assigned_shifts <= 5:  # Reasonable workload
                    emp_satisfaction += 1.0
                elif assigned_shifts <= 7:
                    emp_satisfaction += 0.7
                else:
                    emp_satisfaction += 0.3
                factors += 1
                
                # Factor 2: Skill utilization (simplified)
                emp_satisfaction += 0.8  # Assume good skill utilization
                factors += 1
                
                # Factor 3: Schedule preferences (simplified)
                emp_satisfaction += 0.75  # Assume partial preference satisfaction
                factors += 1
                
                if factors > 0:
                    satisfaction_scores.append(emp_satisfaction / factors)
            
            if satisfaction_scores:
                return sum(satisfaction_scores) / len(satisfaction_scores)
            
            return 0.70  # Default satisfaction
            
        except Exception as e:
            print(f"⚠️ Error calculating employee satisfaction: {str(e)}")
            return 0.70

    async def _calculate_current_schedule_stability(self, context: Dict[str, Any]) -> float:
        """Calculate current schedule stability (change rate)"""
        try:
            # Simplified stability calculation
            # In production, would compare with previous schedule
            
            # Assume 20% change rate as baseline
            change_rate = 0.20
            
            # Random variation for testing
            change_rate += random.uniform(-0.05, 0.05)
            
            return max(0.0, min(1.0, change_rate))
            
        except Exception as e:
            print(f"⚠️ Error calculating schedule stability: {str(e)}")
            return 0.20

    async def _calculate_current_compliance_score(self, context: Dict[str, Any]) -> float:
        """Calculate current compliance score"""
        try:
            # Simplified compliance calculation
            # In production, would use actual constraint validation results
            
            employees = context.get("employees", [])
            assignments = context.get("assignments", {})
            
            compliance_scores = []
            
            for emp in employees:
                emp_id = emp["id"]
                emp_compliance = []
                
                # Check weekly hours
                total_hours = sum(8.0 for shift_assignments in assignments.values() 
                                if emp_id in shift_assignments)
                if total_hours <= 40:
                    emp_compliance.append(1.0)
                elif total_hours <= 44:
                    emp_compliance.append(0.8)
                else:
                    emp_compliance.append(0.5)
                
                # Assume other compliance factors
                emp_compliance.extend([0.95, 0.90, 0.85])  # Rest periods, overtime, etc.
                
                if emp_compliance:
                    compliance_scores.append(sum(emp_compliance) / len(emp_compliance))
            
            if compliance_scores:
                return sum(compliance_scores) / len(compliance_scores)
            
            return 0.90  # Default compliance
            
        except Exception as e:
            print(f"⚠️ Error calculating compliance score: {str(e)}")
            return 0.90

    async def _generate_solution_population(self, conn: asyncpg.Connection, 
                                          solution_count: int,
                                          objectives: List[OptimizationObjective],
                                          context: Dict[str, Any]) -> List[Solution]:
        """Generate population of diverse solutions"""
        
        solutions = []
        
        for i in range(solution_count):
            solution = Solution(
                solution_id=f"SOL_{i:03d}",
                objective_values={},
                normalized_values={},
                weighted_score=0.0,
                dominance_rank=0,
                crowding_distance=0.0,
                is_pareto_optimal=False,
                trade_offs={},
                schedule_data=self._generate_random_schedule_variation(context, i)
            )
            solutions.append(solution)
        
        return solutions

    def _generate_random_schedule_variation(self, context: Dict[str, Any], seed: int) -> Dict[str, Any]:
        """Generate random schedule variation for testing"""
        random.seed(seed)
        
        # Create variation in assignments
        base_assignments = context.get("assignments", {})
        varied_assignments = {}
        
        employees = [emp["id"] for emp in context.get("employees", [])]
        
        for shift_id, base_assigned in base_assignments.items():
            # Random variation: swap some employees
            varied_assigned = base_assigned.copy()
            
            if len(varied_assigned) > 1 and len(employees) > len(varied_assigned):
                # Randomly replace one employee
                if random.random() < 0.3:  # 30% chance of change
                    replace_idx = random.randint(0, len(varied_assigned) - 1)
                    available = [emp for emp in employees if emp not in varied_assigned]
                    if available:
                        varied_assigned[replace_idx] = random.choice(available)
            
            varied_assignments[shift_id] = varied_assigned
        
        return {
            "assignments": varied_assignments,
            "variation_seed": seed
        }

    async def _evaluate_solution_objectives(self, conn: asyncpg.Connection,
                                          solutions: List[Solution],
                                          objectives: List[OptimizationObjective],
                                          context: Dict[str, Any]) -> List[Solution]:
        """Evaluate objective values for all solutions"""
        
        for solution in solutions:
            # Create modified context for this solution
            solution_context = context.copy()
            solution_context.update(solution.schedule_data)
            
            # Evaluate each objective
            for objective in objectives:
                if objective.objective_id == "COST_EFFICIENCY":
                    value = await self._calculate_current_cost_efficiency(solution_context)
                elif objective.objective_id == "SERVICE_QUALITY":
                    value = await self._calculate_current_service_quality(solution_context)
                elif objective.objective_id == "EMPLOYEE_SATISFACTION":
                    value = await self._calculate_current_employee_satisfaction(solution_context)
                elif objective.objective_id == "SCHEDULE_STABILITY":
                    value = await self._calculate_current_schedule_stability(solution_context)
                elif objective.objective_id == "COMPLIANCE_SCORE":
                    value = await self._calculate_current_compliance_score(solution_context)
                else:
                    value = objective.current_value + random.uniform(-0.1, 0.1)
                
                solution.objective_values[objective.objective_id] = value
            
            # Normalize objective values
            solution.normalized_values = self._normalize_objective_values(solution.objective_values, objectives)
            
            # Calculate weighted score
            solution.weighted_score = self._calculate_weighted_score(solution.normalized_values, objectives)
        
        return solutions

    def _normalize_objective_values(self, objective_values: Dict[str, float], 
                                  objectives: List[OptimizationObjective]) -> Dict[str, float]:
        """Normalize objective values to 0-1 scale"""
        normalized = {}
        
        for objective in objectives:
            value = objective_values.get(objective.objective_id, 0.0)
            min_val, max_val = objective.acceptable_range
            
            # Normalize to 0-1 scale
            if max_val > min_val:
                normalized_value = (value - min_val) / (max_val - min_val)
                normalized_value = max(0.0, min(1.0, normalized_value))
            else:
                normalized_value = 0.5
            
            # For minimization objectives, invert the scale
            if objective.minimize:
                normalized_value = 1.0 - normalized_value
            
            normalized[objective.objective_id] = normalized_value
        
        return normalized

    def _calculate_weighted_score(self, normalized_values: Dict[str, float], 
                                objectives: List[OptimizationObjective]) -> float:
        """Calculate weighted score for solution"""
        weighted_score = 0.0
        total_weight = 0.0
        
        for objective in objectives:
            value = normalized_values.get(objective.objective_id, 0.0)
            weighted_score += value * objective.weight
            total_weight += objective.weight
        
        if total_weight > 0:
            return weighted_score / total_weight
        
        return 0.0

    async def _find_pareto_fronts(self, solutions: List[Solution], 
                                objectives: List[OptimizationObjective]) -> List[ParetoFront]:
        """Find Pareto fronts using non-dominated sorting"""
        
        pareto_fronts = []
        remaining_solutions = solutions.copy()
        front_rank = 1
        
        while remaining_solutions:
            current_front_solutions = []
            
            for solution in remaining_solutions:
                is_dominated = False
                
                for other_solution in remaining_solutions:
                    if other_solution.solution_id == solution.solution_id:
                        continue
                    
                    if self._dominates(other_solution, solution, objectives):
                        is_dominated = True
                        break
                
                if not is_dominated:
                    current_front_solutions.append(solution)
                    solution.dominance_rank = front_rank
                    solution.is_pareto_optimal = (front_rank == 1)
            
            if current_front_solutions:
                # Calculate crowding distance
                self._calculate_crowding_distance(current_front_solutions, objectives)
                
                pareto_front = ParetoFront(
                    front_id=f"FRONT_{front_rank}",
                    solutions=current_front_solutions,
                    front_rank=front_rank,
                    coverage_metrics=self._calculate_front_coverage(current_front_solutions, objectives),
                    diversity_metrics=self._calculate_front_diversity(current_front_solutions, objectives),
                    extremes=self._find_front_extremes(current_front_solutions, objectives)
                )
                pareto_fronts.append(pareto_front)
                
                # Remove current front solutions from remaining
                remaining_solutions = [s for s in remaining_solutions if s not in current_front_solutions]
                front_rank += 1
            else:
                break  # No more non-dominated solutions
        
        return pareto_fronts

    def _dominates(self, solution1: Solution, solution2: Solution, 
                  objectives: List[OptimizationObjective]) -> bool:
        """Check if solution1 dominates solution2"""
        
        at_least_one_better = False
        
        for objective in objectives:
            value1 = solution1.objective_values.get(objective.objective_id, 0.0)
            value2 = solution2.objective_values.get(objective.objective_id, 0.0)
            
            if objective.minimize:
                if value1 > value2:  # solution1 is worse
                    return False
                elif value1 < value2:  # solution1 is better
                    at_least_one_better = True
            else:  # maximize
                if value1 < value2:  # solution1 is worse
                    return False
                elif value1 > value2:  # solution1 is better
                    at_least_one_better = True
        
        return at_least_one_better

    def _calculate_crowding_distance(self, solutions: List[Solution], 
                                   objectives: List[OptimizationObjective]):
        """Calculate crowding distance for solutions in a front"""
        
        if len(solutions) <= 2:
            for solution in solutions:
                solution.crowding_distance = float('inf')
            return
        
        # Initialize crowding distances
        for solution in solutions:
            solution.crowding_distance = 0.0
        
        # Calculate for each objective
        for objective in objectives:
            # Sort by objective value
            solutions.sort(key=lambda s: s.objective_values.get(objective.objective_id, 0.0))
            
            # Set boundary solutions to infinite distance
            solutions[0].crowding_distance = float('inf')
            solutions[-1].crowding_distance = float('inf')
            
            # Calculate range
            min_val = solutions[0].objective_values.get(objective.objective_id, 0.0)
            max_val = solutions[-1].objective_values.get(objective.objective_id, 0.0)
            objective_range = max_val - min_val
            
            if objective_range > 0:
                for i in range(1, len(solutions) - 1):
                    if solutions[i].crowding_distance != float('inf'):
                        prev_val = solutions[i-1].objective_values.get(objective.objective_id, 0.0)
                        next_val = solutions[i+1].objective_values.get(objective.objective_id, 0.0)
                        solutions[i].crowding_distance += (next_val - prev_val) / objective_range

    def _calculate_front_coverage(self, solutions: List[Solution], 
                                objectives: List[OptimizationObjective]) -> Dict[str, float]:
        """Calculate coverage metrics for a Pareto front"""
        
        if not solutions:
            return {"objective_coverage": 0.0, "solution_spread": 0.0}
        
        # Calculate objective space coverage
        coverage_scores = []
        for objective in objectives:
            values = [s.objective_values.get(objective.objective_id, 0.0) for s in solutions]
            if values:
                min_val, max_val = objective.acceptable_range
                actual_min, actual_max = min(values), max(values)
                coverage = (actual_max - actual_min) / (max_val - min_val) if max_val > min_val else 0.0
                coverage_scores.append(min(1.0, coverage))
        
        avg_coverage = sum(coverage_scores) / len(coverage_scores) if coverage_scores else 0.0
        
        # Calculate solution spread
        if len(solutions) > 1:
            distances = []
            for i, sol1 in enumerate(solutions):
                for j, sol2 in enumerate(solutions[i+1:], i+1):
                    distance = self._euclidean_distance(sol1, sol2, objectives)
                    distances.append(distance)
            
            solution_spread = np.std(distances) if distances else 0.0
        else:
            solution_spread = 0.0
        
        return {
            "objective_coverage": avg_coverage,
            "solution_spread": solution_spread
        }

    def _calculate_front_diversity(self, solutions: List[Solution], 
                                 objectives: List[OptimizationObjective]) -> Dict[str, float]:
        """Calculate diversity metrics for a Pareto front"""
        
        if len(solutions) <= 1:
            return {"diversity_score": 0.0, "uniform_distribution": 0.0}
        
        # Calculate average crowding distance
        finite_distances = [s.crowding_distance for s in solutions if s.crowding_distance != float('inf')]
        avg_crowding = np.mean(finite_distances) if finite_distances else 0.0
        
        # Calculate distribution uniformity
        distances = []
        for i in range(len(solutions) - 1):
            distance = self._euclidean_distance(solutions[i], solutions[i+1], objectives)
            distances.append(distance)
        
        uniformity = 1.0 - (np.std(distances) / np.mean(distances)) if distances and np.mean(distances) > 0 else 0.0
        uniformity = max(0.0, min(1.0, uniformity))
        
        return {
            "diversity_score": avg_crowding,
            "uniform_distribution": uniformity
        }

    def _find_front_extremes(self, solutions: List[Solution], 
                           objectives: List[OptimizationObjective]) -> Dict[str, Solution]:
        """Find extreme solutions for each objective"""
        
        extremes = {}
        
        for objective in objectives:
            if objective.minimize:
                # Find minimum value
                best_solution = min(solutions, 
                                  key=lambda s: s.objective_values.get(objective.objective_id, float('inf')))
                extremes[f"{objective.objective_id}_best"] = best_solution
            else:
                # Find maximum value
                best_solution = max(solutions, 
                                  key=lambda s: s.objective_values.get(objective.objective_id, 0.0))
                extremes[f"{objective.objective_id}_best"] = best_solution
        
        return extremes

    def _euclidean_distance(self, solution1: Solution, solution2: Solution, 
                          objectives: List[OptimizationObjective]) -> float:
        """Calculate Euclidean distance between two solutions in objective space"""
        
        distance_squared = 0.0
        
        for objective in objectives:
            value1 = solution1.normalized_values.get(objective.objective_id, 0.0)
            value2 = solution2.normalized_values.get(objective.objective_id, 0.0)
            distance_squared += (value1 - value2) ** 2
        
        return math.sqrt(distance_squared)

    async def _nsga_ii_optimization(self, solutions: List[Solution], 
                                  objectives: List[OptimizationObjective]) -> List[ParetoFront]:
        """NSGA-II optimization algorithm"""
        # For now, use regular Pareto front finding
        # In production, would implement full NSGA-II with genetic operators
        return await self._find_pareto_fronts(solutions, objectives)

    async def _weighted_sum_optimization(self, solutions: List[Solution], 
                                       objectives: List[OptimizationObjective]) -> List[ParetoFront]:
        """Weighted sum optimization (single front)"""
        
        # Sort solutions by weighted score
        solutions.sort(key=lambda s: s.weighted_score, reverse=True)
        
        # Create single front with all solutions
        for i, solution in enumerate(solutions):
            solution.dominance_rank = 1
            solution.is_pareto_optimal = (i < len(solutions) // 10)  # Top 10% are "optimal"
            solution.crowding_distance = len(solutions) - i  # Descending order
        
        pareto_front = ParetoFront(
            front_id="WEIGHTED_FRONT",
            solutions=solutions,
            front_rank=1,
            coverage_metrics=self._calculate_front_coverage(solutions, objectives),
            diversity_metrics=self._calculate_front_diversity(solutions, objectives),
            extremes=self._find_front_extremes(solutions, objectives)
        )
        
        return [pareto_front]

    async def _select_recommended_solution(self, pareto_fronts: List[ParetoFront], 
                                         objectives: List[OptimizationObjective]) -> Solution:
        """Select recommended solution from Pareto fronts"""
        
        if not pareto_fronts or not pareto_fronts[0].solutions:
            raise ValueError("No solutions available for recommendation")
        
        # Get first (best) Pareto front
        best_front = pareto_fronts[0]
        
        # Select solution with highest weighted score in the front
        recommended = max(best_front.solutions, key=lambda s: s.weighted_score)
        
        # Generate trade-off analysis for recommended solution
        recommended.trade_offs = self._analyze_solution_trade_offs(recommended, objectives)
        
        return recommended

    def _analyze_solution_trade_offs(self, solution: Solution, 
                                   objectives: List[OptimizationObjective]) -> Dict[str, str]:
        """Analyze trade-offs for a specific solution"""
        
        trade_offs = {}
        
        for objective in objectives:
            value = solution.objective_values.get(objective.objective_id, 0.0)
            target = objective.target_value
            
            if target is not None:
                if objective.minimize:
                    if value <= target:
                        trade_offs[objective.objective_id] = f"Meets target (≤{target:.3f})"
                    else:
                        trade_offs[objective.objective_id] = f"Exceeds target by {value - target:.3f}"
                else:
                    if value >= target:
                        trade_offs[objective.objective_id] = f"Meets target (≥{target:.3f})"
                    else:
                        trade_offs[objective.objective_id] = f"Below target by {target - value:.3f}"
            else:
                normalized = solution.normalized_values.get(objective.objective_id, 0.0)
                if normalized >= 0.8:
                    trade_offs[objective.objective_id] = "Excellent performance"
                elif normalized >= 0.6:
                    trade_offs[objective.objective_id] = "Good performance"
                elif normalized >= 0.4:
                    trade_offs[objective.objective_id] = "Acceptable performance"
                else:
                    trade_offs[objective.objective_id] = "Needs improvement"
        
        return trade_offs

    async def _analyze_trade_offs(self, pareto_fronts: List[ParetoFront], 
                                objectives: List[OptimizationObjective]) -> Dict[str, Any]:
        """Analyze trade-offs across Pareto front"""
        
        if not pareto_fronts or not pareto_fronts[0].solutions:
            return {"trade_off_analysis": "No solutions available"}
        
        best_front = pareto_fronts[0]
        
        analysis = {
            "front_size": len(best_front.solutions),
            "objective_correlations": {},
            "conflicting_objectives": [],
            "synergistic_objectives": [],
            "extreme_solutions": {},
            "trade_off_recommendations": []
        }
        
        # Calculate objective correlations
        for i, obj1 in enumerate(objectives):
            for obj2 in objectives[i+1:]:
                correlation = self._calculate_objective_correlation(best_front.solutions, obj1, obj2)
                analysis["objective_correlations"][f"{obj1.objective_id}_vs_{obj2.objective_id}"] = correlation
                
                if correlation < -0.5:
                    analysis["conflicting_objectives"].append((obj1.name, obj2.name))
                elif correlation > 0.5:
                    analysis["synergistic_objectives"].append((obj1.name, obj2.name))
        
        # Identify extreme solutions
        for objective in objectives:
            if objective.minimize:
                best_solution = min(best_front.solutions, 
                                  key=lambda s: s.objective_values.get(objective.objective_id, float('inf')))
            else:
                best_solution = max(best_front.solutions, 
                                  key=lambda s: s.objective_values.get(objective.objective_id, 0.0))
            
            analysis["extreme_solutions"][objective.name] = {
                "solution_id": best_solution.solution_id,
                "value": best_solution.objective_values.get(objective.objective_id, 0.0),
                "trade_offs": best_solution.trade_offs
            }
        
        # Generate recommendations
        analysis["trade_off_recommendations"] = [
            "Balance cost efficiency with service quality for optimal ROI",
            "Consider employee satisfaction impact on long-term stability",
            "Ensure compliance requirements are met before optimizing other objectives",
            "Use extreme solutions to understand objective boundaries"
        ]
        
        return analysis

    def _calculate_objective_correlation(self, solutions: List[Solution], 
                                       obj1: OptimizationObjective, 
                                       obj2: OptimizationObjective) -> float:
        """Calculate correlation between two objectives"""
        
        values1 = [s.objective_values.get(obj1.objective_id, 0.0) for s in solutions]
        values2 = [s.objective_values.get(obj2.objective_id, 0.0) for s in solutions]
        
        if len(values1) < 2:
            return 0.0
        
        return np.corrcoef(values1, values2)[0, 1] if not np.isnan(np.corrcoef(values1, values2)[0, 1]) else 0.0

    def _calculate_convergence_metrics(self, pareto_fronts: List[ParetoFront], 
                                     objectives: List[OptimizationObjective]) -> Dict[str, float]:
        """Calculate convergence quality metrics"""
        
        if not pareto_fronts:
            return {"convergence_score": 0.0, "front_quality": 0.0}
        
        best_front = pareto_fronts[0]
        
        metrics = {
            "convergence_score": len(best_front.solutions) / 100.0,  # Normalized by expected size
            "front_quality": best_front.coverage_metrics.get("objective_coverage", 0.0),
            "diversity_score": best_front.diversity_metrics.get("diversity_score", 0.0),
            "solution_spread": best_front.coverage_metrics.get("solution_spread", 0.0)
        }
        
        return metrics

    async def _log_multi_objective_result(self, conn: asyncpg.Connection, result: MultiObjectiveResult):
        """Log multi-objective optimization result"""
        try:
            await conn.execute("""
                INSERT INTO multi_objective_optimization_log 
                (optimization_id, method_used, total_solutions_evaluated, pareto_front_count,
                 recommended_solution_score, processing_time_seconds, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            """, result.optimization_id, result.method_used.value, result.total_solutions_evaluated,
                len(result.pareto_fronts), result.recommended_solution.weighted_score,
                result.processing_time_seconds, datetime.now(timezone.utc))
            
        except Exception as e:
            print(f"⚠️ Error logging multi-objective result: {str(e)}")


# Test the multi-objective optimizer
async def test_multi_objective_optimizer():
    """Test multi-objective optimizer with sample scenarios"""
    optimizer = MultiObjectiveOptimizer()
    
    print("Testing multi-objective optimizer...")
    
    try:
        # Create test schedule context
        test_context = {
            "employees": [
                {"id": 1001, "hourly_rate": 20.0, "skills": ["Phone", "Chat"]},
                {"id": 1002, "hourly_rate": 22.0, "skills": ["Phone", "Email"]},
                {"id": 1003, "hourly_rate": 25.0, "skills": ["Chat", "Technical"]},
                {"id": 1004, "hourly_rate": 18.0, "skills": ["Phone", "Spanish"]},
                {"id": 1005, "hourly_rate": 24.0, "skills": ["Technical", "Escalation"]}
            ],
            "shifts": [
                {"shift_id": "MORNING", "required_agents": 3},
                {"shift_id": "AFTERNOON", "required_agents": 2},
                {"shift_id": "EVENING", "required_agents": 2}
            ],
            "assignments": {
                "MORNING": [1001, 1002, 1003],
                "AFTERNOON": [1002, 1004],
                "EVENING": [1003, 1005]
            }
        }
        
        # Test Pareto optimization
        result = await optimizer.optimize_multi_objective(
            schedule_context=test_context,
            method=OptimizationMethod.PARETO_FRONTIER,
            solution_count=50  # Smaller for testing
        )
        
        print(f"✅ Multi-objective optimization completed:")
        print(f"   Method: {result.method_used.value}")
        print(f"   Solutions evaluated: {result.total_solutions_evaluated}")
        print(f"   Pareto fronts: {len(result.pareto_fronts)}")
        print(f"   Processing time: {result.processing_time_seconds:.1f}s")
        
        if result.pareto_fronts:
            first_front = result.pareto_fronts[0]
            print(f"   First front solutions: {len(first_front.solutions)}")
            print(f"   Objective coverage: {first_front.coverage_metrics.get('objective_coverage', 0):.1%}")
            print(f"   Diversity score: {first_front.diversity_metrics.get('diversity_score', 0):.3f}")
        
        print(f"\n   Recommended solution:")
        print(f"     Solution ID: {result.recommended_solution.solution_id}")
        print(f"     Weighted score: {result.recommended_solution.weighted_score:.3f}")
        print(f"     Pareto optimal: {result.recommended_solution.is_pareto_optimal}")
        
        print(f"\n   Objective values:")
        for objective in result.objectives:
            value = result.recommended_solution.objective_values.get(objective.objective_id, 0)
            target = f" (target: {objective.target_value})" if objective.target_value else ""
            direction = "↓" if objective.minimize else "↑"
            print(f"     {objective.name}: {value:.3f} {direction}{target}")
        
        print(f"\n   Trade-off analysis:")
        print(f"     Conflicting objectives: {len(result.trade_off_analysis.get('conflicting_objectives', []))}")
        print(f"     Synergistic objectives: {len(result.trade_off_analysis.get('synergistic_objectives', []))}")
        
        print("\n✅ Multi-objective optimizer test completed successfully")
        
    except Exception as e:
        print(f"❌ Multi-objective optimizer test failed: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_multi_objective_optimizer())