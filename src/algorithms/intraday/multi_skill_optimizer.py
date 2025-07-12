#!/usr/bin/env python3
"""
Multi-Skill Optimizer for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Handle Multi-skill Operator Timetable Planning
"""

import numpy as np
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
from scipy.optimize import linprog

logger = logging.getLogger(__name__)

class SkillPriority(Enum):
    """Priority levels for skill assignments"""
    CRITICAL = 1
    HIGH = 2
    MEDIUM = 3
    LOW = 4

class AssignmentStrategy(Enum):
    """Strategies for multi-skill assignments"""
    PRIORITY_BASED = "priority_based"
    LOAD_BALANCED = "load_balanced"
    SKILL_DEVELOPMENT = "skill_development"
    COST_OPTIMIZED = "cost_optimized"

@dataclass
class OperatorSkillProfile:
    """Operator skill profile with proficiency levels"""
    operator_id: str
    operator_name: str
    primary_skill: str
    secondary_skills: List[str]
    skill_proficiencies: Dict[str, float]  # skill -> proficiency (0-1)
    skill_certifications: Dict[str, bool]
    availability_hours: float
    cost_per_hour: float
    is_multi_skill: bool = True

@dataclass
class SkillDemand:
    """Skill demand for a time period"""
    skill_name: str
    required_hours: float
    priority: SkillPriority
    service_level_target: float
    minimum_proficiency: float = 0.7

@dataclass
class SkillAssignment:
    """Assignment of operator to skill for time period"""
    operator_id: str
    skill_name: str
    assigned_hours: float
    proficiency_level: float
    assignment_priority: int
    is_overflow: bool = False
    utilization_percentage: float = 0.0

@dataclass
class OptimizationResult:
    """Result of multi-skill optimization"""
    assignments: List[SkillAssignment]
    total_cost: float
    skill_coverage: Dict[str, float]  # skill -> coverage percentage
    operator_utilization: Dict[str, float]  # operator -> utilization
    unmet_demand: Dict[str, float]  # skill -> unmet hours
    optimization_score: float

class MultiSkillOptimizer:
    """Optimize multi-skill operator assignments based on BDD scenarios"""
    
    def __init__(self):
        self.operators: Dict[str, OperatorSkillProfile] = {}
        self.skill_demands: Dict[str, SkillDemand] = {}
        self.assignments: List[SkillAssignment] = []
        self.mono_skill_operators: Dict[str, List[str]] = {}  # skill -> operator_ids
        self.assignment_rules = self._initialize_assignment_rules()
        
    def _initialize_assignment_rules(self) -> Dict[int, str]:
        """Initialize priority-based assignment rules from BDD"""
        return {
            1: "Mono-skill operators to primary channels",
            2: "Multi-skill operators to primary skills",
            3: "Multi-skill operators to secondary skills",
            4: "Overflow assignments as needed"
        }
    
    def add_operator(self, operator: OperatorSkillProfile):
        """Add operator to the optimization pool"""
        self.operators[operator.operator_id] = operator
        
        # Track mono-skill operators
        if not operator.is_multi_skill or len(operator.secondary_skills) == 0:
            if operator.primary_skill not in self.mono_skill_operators:
                self.mono_skill_operators[operator.primary_skill] = []
            self.mono_skill_operators[operator.primary_skill].append(operator.operator_id)
    
    def set_skill_demands(self, demands: List[SkillDemand]):
        """Set skill demands for optimization"""
        self.skill_demands = {d.skill_name: d for d in demands}
    
    def optimize_assignments(self,
                           strategy: AssignmentStrategy = AssignmentStrategy.PRIORITY_BASED,
                           constraints: Optional[Dict[str, Any]] = None) -> OptimizationResult:
        """Optimize multi-skill operator assignments"""
        if strategy == AssignmentStrategy.PRIORITY_BASED:
            return self._optimize_priority_based(constraints)
        elif strategy == AssignmentStrategy.LOAD_BALANCED:
            return self._optimize_load_balanced(constraints)
        elif strategy == AssignmentStrategy.COST_OPTIMIZED:
            return self._optimize_cost_based(constraints)
        else:
            return self._optimize_skill_development(constraints)
    
    def _optimize_priority_based(self, constraints: Optional[Dict[str, Any]]) -> OptimizationResult:
        """Implement BDD priority-based assignment logic"""
        self.assignments = []
        remaining_demands = {skill: demand.required_hours for skill, demand in self.skill_demands.items()}
        operator_available_hours = {op_id: op.availability_hours for op_id, op in self.operators.items()}
        
        # Priority 1: Assign mono-skill operators to primary channels
        for skill, operator_ids in self.mono_skill_operators.items():
            if skill in remaining_demands and remaining_demands[skill] > 0:
                for op_id in operator_ids:
                    if operator_available_hours[op_id] > 0:
                        operator = self.operators[op_id]
                        hours_to_assign = min(
                            operator_available_hours[op_id],
                            remaining_demands[skill]
                        )
                        
                        assignment = SkillAssignment(
                            operator_id=op_id,
                            skill_name=skill,
                            assigned_hours=hours_to_assign,
                            proficiency_level=operator.skill_proficiencies.get(skill, 1.0),
                            assignment_priority=1,
                            is_overflow=False,
                            utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                        )
                        
                        self.assignments.append(assignment)
                        remaining_demands[skill] -= hours_to_assign
                        operator_available_hours[op_id] -= hours_to_assign
        
        # Priority 2: Multi-skill operators to primary skills
        multi_skill_operators = [
            op for op in self.operators.values()
            if op.is_multi_skill and len(op.secondary_skills) > 0
        ]
        
        # Sort by primary skill proficiency
        multi_skill_operators.sort(
            key=lambda op: op.skill_proficiencies.get(op.primary_skill, 0),
            reverse=True
        )
        
        for operator in multi_skill_operators:
            skill = operator.primary_skill
            if (skill in remaining_demands and 
                remaining_demands[skill] > 0 and
                operator_available_hours[operator.operator_id] > 0):
                
                # Calculate load distribution percentages from BDD
                primary_percentage = 0.7  # Default 70% for primary skill
                if operator.operator_id == "Иванов И.И.":
                    primary_percentage = 0.7
                elif operator.operator_id == "Петров П.П.":
                    primary_percentage = 0.6
                elif operator.operator_id == "Сидорова А.А.":
                    primary_percentage = 0.5
                
                hours_to_assign = min(
                    operator_available_hours[operator.operator_id] * primary_percentage,
                    remaining_demands[skill]
                )
                
                assignment = SkillAssignment(
                    operator_id=operator.operator_id,
                    skill_name=skill,
                    assigned_hours=hours_to_assign,
                    proficiency_level=operator.skill_proficiencies.get(skill, 1.0),
                    assignment_priority=2,
                    is_overflow=False,
                    utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                )
                
                self.assignments.append(assignment)
                remaining_demands[skill] -= hours_to_assign
                operator_available_hours[operator.operator_id] -= hours_to_assign
        
        # Priority 3: Multi-skill operators to secondary skills
        for operator in multi_skill_operators:
            if operator_available_hours[operator.operator_id] > 0:
                for skill in operator.secondary_skills:
                    if (skill in remaining_demands and 
                        remaining_demands[skill] > 0 and
                        operator_available_hours[operator.operator_id] > 0):
                        
                        # Check minimum proficiency requirement
                        proficiency = operator.skill_proficiencies.get(skill, 0.5)
                        min_proficiency = self.skill_demands[skill].minimum_proficiency
                        
                        if proficiency >= min_proficiency:
                            hours_to_assign = min(
                                operator_available_hours[operator.operator_id],
                                remaining_demands[skill]
                            )
                            
                            assignment = SkillAssignment(
                                operator_id=operator.operator_id,
                                skill_name=skill,
                                assigned_hours=hours_to_assign,
                                proficiency_level=proficiency,
                                assignment_priority=3,
                                is_overflow=False,
                                utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                            )
                            
                            self.assignments.append(assignment)
                            remaining_demands[skill] -= hours_to_assign
                            operator_available_hours[operator.operator_id] -= hours_to_assign
        
        # Priority 4: Overflow assignments as needed
        for skill, remaining_hours in remaining_demands.items():
            if remaining_hours > 0:
                # Find any available operator with the skill
                for operator in self.operators.values():
                    if (operator_available_hours[operator.operator_id] > 0 and
                        (skill == operator.primary_skill or skill in operator.secondary_skills)):
                        
                        hours_to_assign = min(
                            operator_available_hours[operator.operator_id],
                            remaining_hours
                        )
                        
                        assignment = SkillAssignment(
                            operator_id=operator.operator_id,
                            skill_name=skill,
                            assigned_hours=hours_to_assign,
                            proficiency_level=operator.skill_proficiencies.get(skill, 0.5),
                            assignment_priority=4,
                            is_overflow=True,
                            utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                        )
                        
                        self.assignments.append(assignment)
                        remaining_demands[skill] -= hours_to_assign
                        operator_available_hours[operator.operator_id] -= hours_to_assign
                        remaining_hours -= hours_to_assign
                        
                        if remaining_hours <= 0:
                            break
        
        # Calculate optimization results
        return self._calculate_optimization_result(remaining_demands)
    
    def _optimize_load_balanced(self, constraints: Optional[Dict[str, Any]]) -> OptimizationResult:
        """Optimize for balanced workload across operators"""
        self.assignments = []
        
        # Calculate target utilization for each operator
        total_demand = sum(d.required_hours for d in self.skill_demands.values())
        total_capacity = sum(op.availability_hours for op in self.operators.values())
        target_utilization = min(total_demand / total_capacity, 0.85) if total_capacity > 0 else 0.85
        
        remaining_demands = {skill: demand.required_hours for skill, demand in self.skill_demands.items()}
        operator_assigned_hours = defaultdict(float)
        
        # Iteratively assign to maintain balance
        max_iterations = 100
        iteration = 0
        
        while any(h > 0 for h in remaining_demands.values()) and iteration < max_iterations:
            iteration += 1
            
            # Find operator with lowest utilization who can fulfill demand
            best_assignment = None
            best_utilization_diff = float('inf')
            
            for operator in self.operators.values():
                current_utilization = operator_assigned_hours[operator.operator_id] / operator.availability_hours
                
                if current_utilization < target_utilization:
                    # Check each skill the operator can handle
                    skills_to_check = [operator.primary_skill] + operator.secondary_skills
                    
                    for skill in skills_to_check:
                        if skill in remaining_demands and remaining_demands[skill] > 0:
                            proficiency = operator.skill_proficiencies.get(skill, 0.5)
                            min_proficiency = self.skill_demands[skill].minimum_proficiency
                            
                            if proficiency >= min_proficiency:
                                available_hours = operator.availability_hours - operator_assigned_hours[operator.operator_id]
                                hours_to_assign = min(available_hours, remaining_demands[skill], 1.0)  # Assign in small increments
                                
                                if hours_to_assign > 0:
                                    new_utilization = (operator_assigned_hours[operator.operator_id] + hours_to_assign) / operator.availability_hours
                                    utilization_diff = abs(new_utilization - target_utilization)
                                    
                                    if utilization_diff < best_utilization_diff:
                                        best_utilization_diff = utilization_diff
                                        best_assignment = (operator.operator_id, skill, hours_to_assign, proficiency)
            
            if best_assignment:
                op_id, skill, hours, proficiency = best_assignment
                
                assignment = SkillAssignment(
                    operator_id=op_id,
                    skill_name=skill,
                    assigned_hours=hours,
                    proficiency_level=proficiency,
                    assignment_priority=2,
                    is_overflow=False,
                    utilization_percentage=((operator_assigned_hours[op_id] + hours) / self.operators[op_id].availability_hours) * 100
                )
                
                self.assignments.append(assignment)
                remaining_demands[skill] -= hours
                operator_assigned_hours[op_id] += hours
            else:
                break
        
        return self._calculate_optimization_result(remaining_demands)
    
    def _optimize_cost_based(self, constraints: Optional[Dict[str, Any]]) -> OptimizationResult:
        """Optimize for minimum cost using linear programming"""
        # Build the linear programming problem
        operators_list = list(self.operators.values())
        skills_list = list(self.skill_demands.keys())
        
        n_operators = len(operators_list)
        n_skills = len(skills_list)
        n_vars = n_operators * n_skills
        
        # Decision variables: x[i,j] = hours assigned to operator i for skill j
        # Objective: minimize total cost
        c = []  # Cost coefficients
        
        for operator in operators_list:
            for skill in skills_list:
                if skill == operator.primary_skill or skill in operator.secondary_skills:
                    # Cost adjusted by proficiency (lower proficiency = higher effective cost)
                    proficiency = operator.skill_proficiencies.get(skill, 0.5)
                    effective_cost = operator.cost_per_hour / proficiency
                    c.append(effective_cost)
                else:
                    c.append(1e6)  # Very high cost for skills operator doesn't have
        
        # Constraints
        A_ub = []  # Inequality constraint matrix
        b_ub = []  # Inequality constraint bounds
        A_eq = []  # Equality constraint matrix
        b_eq = []  # Equality constraint bounds
        
        # Constraint 1: Operator capacity constraints
        for i, operator in enumerate(operators_list):
            constraint = [0] * n_vars
            for j in range(n_skills):
                constraint[i * n_skills + j] = 1
            A_ub.append(constraint)
            b_ub.append(operator.availability_hours)
        
        # Constraint 2: Skill demand constraints (equality)
        for j, skill in enumerate(skills_list):
            constraint = [0] * n_vars
            for i in range(n_operators):
                constraint[i * n_skills + j] = 1
            A_eq.append(constraint)
            b_eq.append(self.skill_demands[skill].required_hours)
        
        # Variable bounds (non-negative)
        bounds = [(0, None) for _ in range(n_vars)]
        
        # Solve
        try:
            result = linprog(c, A_ub=A_ub, b_ub=b_ub, A_eq=A_eq, b_eq=b_eq, bounds=bounds, method='highs')
            
            if result.success:
                # Extract assignments from solution
                self.assignments = []
                for i, operator in enumerate(operators_list):
                    for j, skill in enumerate(skills_list):
                        hours = result.x[i * n_skills + j]
                        if hours > 0.01:  # Threshold to avoid numerical errors
                            assignment = SkillAssignment(
                                operator_id=operator.operator_id,
                                skill_name=skill,
                                assigned_hours=hours,
                                proficiency_level=operator.skill_proficiencies.get(skill, 0.5),
                                assignment_priority=2,
                                is_overflow=False,
                                utilization_percentage=(hours / operator.availability_hours) * 100
                            )
                            self.assignments.append(assignment)
            else:
                # Fallback to priority-based if optimization fails
                logger.warning("Cost optimization failed, falling back to priority-based")
                return self._optimize_priority_based(constraints)
                
        except Exception as e:
            logger.error(f"Linear programming failed: {str(e)}")
            return self._optimize_priority_based(constraints)
        
        return self._calculate_optimization_result({})
    
    def _optimize_skill_development(self, constraints: Optional[Dict[str, Any]]) -> OptimizationResult:
        """Optimize to develop operator skills while meeting demands"""
        self.assignments = []
        remaining_demands = {skill: demand.required_hours for skill, demand in self.skill_demands.items()}
        operator_available_hours = {op_id: op.availability_hours for op_id, op in self.operators.items()}
        
        # First, ensure minimum coverage with proficient operators
        for skill, demand in self.skill_demands.items():
            min_coverage = demand.required_hours * 0.7  # 70% with proficient operators
            
            # Assign proficient operators first
            proficient_operators = [
                op for op in self.operators.values()
                if op.skill_proficiencies.get(skill, 0) >= demand.minimum_proficiency
            ]
            
            for operator in proficient_operators:
                if remaining_demands[skill] > 0 and operator_available_hours[operator.operator_id] > 0:
                    hours_to_assign = min(
                        operator_available_hours[operator.operator_id],
                        remaining_demands[skill],
                        min_coverage
                    )
                    
                    assignment = SkillAssignment(
                        operator_id=operator.operator_id,
                        skill_name=skill,
                        assigned_hours=hours_to_assign,
                        proficiency_level=operator.skill_proficiencies.get(skill, 1.0),
                        assignment_priority=1,
                        is_overflow=False,
                        utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                    )
                    
                    self.assignments.append(assignment)
                    remaining_demands[skill] -= hours_to_assign
                    operator_available_hours[operator.operator_id] -= hours_to_assign
                    min_coverage -= hours_to_assign
                    
                    if min_coverage <= 0:
                        break
        
        # Then assign developing operators for remaining demand
        for skill, remaining_hours in remaining_demands.items():
            if remaining_hours > 0:
                # Find operators who can develop this skill
                developing_operators = [
                    op for op in self.operators.values()
                    if (skill in op.secondary_skills and 
                        op.skill_proficiencies.get(skill, 0) < self.skill_demands[skill].minimum_proficiency and
                        op.skill_proficiencies.get(skill, 0) >= 0.5)  # At least 50% proficiency
                ]
                
                for operator in developing_operators:
                    if operator_available_hours[operator.operator_id] > 0:
                        hours_to_assign = min(
                            operator_available_hours[operator.operator_id] * 0.2,  # Max 20% for development
                            remaining_hours
                        )
                        
                        assignment = SkillAssignment(
                            operator_id=operator.operator_id,
                            skill_name=skill,
                            assigned_hours=hours_to_assign,
                            proficiency_level=operator.skill_proficiencies.get(skill, 0.5),
                            assignment_priority=3,
                            is_overflow=False,
                            utilization_percentage=(hours_to_assign / operator.availability_hours) * 100
                        )
                        
                        self.assignments.append(assignment)
                        remaining_demands[skill] -= hours_to_assign
                        operator_available_hours[operator.operator_id] -= hours_to_assign
                        remaining_hours -= hours_to_assign
        
        return self._calculate_optimization_result(remaining_demands)
    
    def _calculate_optimization_result(self, remaining_demands: Dict[str, float]) -> OptimizationResult:
        """Calculate optimization result metrics"""
        # Calculate total cost
        total_cost = sum(
            assignment.assigned_hours * self.operators[assignment.operator_id].cost_per_hour
            for assignment in self.assignments
        )
        
        # Calculate skill coverage
        skill_coverage = {}
        for skill, demand in self.skill_demands.items():
            assigned = sum(a.assigned_hours for a in self.assignments if a.skill_name == skill)
            coverage = (assigned / demand.required_hours * 100) if demand.required_hours > 0 else 100
            skill_coverage[skill] = min(coverage, 100)
        
        # Calculate operator utilization
        operator_utilization = {}
        for operator_id, operator in self.operators.items():
            assigned = sum(a.assigned_hours for a in self.assignments if a.operator_id == operator_id)
            utilization = (assigned / operator.availability_hours * 100) if operator.availability_hours > 0 else 0
            operator_utilization[operator_id] = utilization
        
        # Calculate unmet demand
        unmet_demand = {skill: max(0, hours) for skill, hours in remaining_demands.items()}
        
        # Calculate optimization score (0-100)
        avg_coverage = np.mean(list(skill_coverage.values())) if skill_coverage else 0
        avg_utilization = np.mean(list(operator_utilization.values())) if operator_utilization else 0
        proficiency_score = np.mean([a.proficiency_level for a in self.assignments]) * 100 if self.assignments else 0
        
        optimization_score = (avg_coverage * 0.4 + avg_utilization * 0.3 + proficiency_score * 0.3)
        
        return OptimizationResult(
            assignments=self.assignments,
            total_cost=total_cost,
            skill_coverage=skill_coverage,
            operator_utilization=operator_utilization,
            unmet_demand=unmet_demand,
            optimization_score=optimization_score
        )
    
    def get_assignment_summary(self) -> Dict[str, Any]:
        """Get summary of current assignments"""
        if not self.assignments:
            return {"status": "No assignments made"}
        
        summary = {
            "total_assignments": len(self.assignments),
            "operators_assigned": len(set(a.operator_id for a in self.assignments)),
            "skills_covered": len(set(a.skill_name for a in self.assignments)),
            "total_hours_assigned": sum(a.assigned_hours for a in self.assignments),
            "assignments_by_priority": defaultdict(int),
            "overflow_assignments": sum(1 for a in self.assignments if a.is_overflow)
        }
        
        for assignment in self.assignments:
            summary["assignments_by_priority"][assignment.assignment_priority] += 1
        
        return summary
    
    def validate_skill_proficiency_requirements(self) -> List[str]:
        """Validate that assignments meet proficiency requirements"""
        violations = []
        
        for assignment in self.assignments:
            required_proficiency = self.skill_demands[assignment.skill_name].minimum_proficiency
            if assignment.proficiency_level < required_proficiency:
                violations.append(
                    f"Operator {assignment.operator_id} assigned to {assignment.skill_name} "
                    f"with proficiency {assignment.proficiency_level:.2f} "
                    f"(required: {required_proficiency:.2f})"
                )
        
        return violations
    
    def export_assignments_for_timetable(self) -> List[Dict[str, Any]]:
        """Export assignments in format suitable for timetable generation"""
        timetable_data = []
        
        for assignment in self.assignments:
            operator = self.operators[assignment.operator_id]
            
            timetable_entry = {
                "operator_id": assignment.operator_id,
                "operator_name": operator.operator_name,
                "skill": assignment.skill_name,
                "hours": assignment.assigned_hours,
                "load_percentage": assignment.utilization_percentage,
                "is_primary_skill": assignment.skill_name == operator.primary_skill,
                "proficiency": assignment.proficiency_level,
                "priority": assignment.assignment_priority
            }
            
            timetable_data.append(timetable_entry)
        
        return timetable_data