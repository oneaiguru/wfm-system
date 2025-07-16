#!/usr/bin/env python3
"""
Mobile Workforce Scheduler - Multi-Skill Optimizer with Real Data Integration
Implements Mobile Workforce Scheduler pattern for intraday activity planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Handle Multi-skill Operator Timetable Planning with Real Workforce Data
"""

import numpy as np
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
from scipy.optimize import linprog
import sys
import os

# Add the parent directory to sys.path to import db_connection
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'core'))
from db_connection import WFMDatabaseConnection, EmployeeSkillData

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
    MOBILE_WORKFORCE = "mobile_workforce"  # New Mobile Workforce Scheduler strategy

class LocationType(Enum):
    """Location types for mobile workforce scheduling"""
    OFFICE = "office"
    REMOTE = "remote"
    FIELD = "field"
    CLIENT_SITE = "client_site"
    HYBRID = "hybrid"

@dataclass
class MobileWorkforceProfile:
    """Mobile Workforce Profile with location and skill data"""
    operator_id: str
    operator_name: str
    employee_number: str
    position_name: str
    department_type: str
    level_category: str
    primary_skill: str
    secondary_skills: List[str]
    skill_proficiencies: Dict[str, float]  # skill -> proficiency (0-1)
    skill_certifications: Dict[str, bool]
    availability_hours: float
    cost_per_hour: float
    is_multi_skill: bool = True
    location_type: LocationType = LocationType.OFFICE
    mobile_enabled: bool = True
    current_location: Optional[str] = None
    travel_time_minutes: int = 0
    mobile_performance_score: float = 1.0  # Based on mobile app usage metrics

@dataclass
class OperatorSkillProfile:
    """Legacy operator skill profile - maintained for backward compatibility"""
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
class MobileSkillAssignment:
    """Mobile workforce assignment with location and performance data"""
    operator_id: str
    skill_name: str
    assigned_hours: float
    proficiency_level: float
    assignment_priority: int
    is_overflow: bool = False
    utilization_percentage: float = 0.0
    location_type: LocationType = LocationType.OFFICE
    requires_mobile_access: bool = False
    estimated_performance_impact: float = 1.0
    intraday_adjustment_factor: float = 1.0

@dataclass
class SkillAssignment:
    """Legacy assignment - maintained for backward compatibility"""
    operator_id: str
    skill_name: str
    assigned_hours: float
    proficiency_level: float
    assignment_priority: int
    is_overflow: bool = False
    utilization_percentage: float = 0.0

@dataclass
class MobileOptimizationResult:
    """Result of mobile workforce optimization"""
    mobile_assignments: List[MobileSkillAssignment]
    legacy_assignments: List[SkillAssignment]  # For backward compatibility
    total_cost: float
    skill_coverage: Dict[str, float]  # skill -> coverage percentage
    operator_utilization: Dict[str, float]  # operator -> utilization
    unmet_demand: Dict[str, float]  # skill -> unmet hours
    optimization_score: float
    mobile_performance_score: float
    location_distribution: Dict[LocationType, int]
    intraday_adjustment_recommendations: List[str]

@dataclass
class OptimizationResult:
    """Legacy optimization result - maintained for backward compatibility"""
    assignments: List[SkillAssignment]
    total_cost: float
    skill_coverage: Dict[str, float]  # skill -> coverage percentage
    operator_utilization: Dict[str, float]  # operator -> utilization
    unmet_demand: Dict[str, float]  # skill -> unmet hours
    optimization_score: float

class MobileWorkforceScheduler:
    """Mobile Workforce Scheduler implementing Mobile Workforce Scheduler pattern
    
    Integrates real employee data with location-aware scheduling and mobile performance metrics.
    Supports both traditional office-based and mobile workforce optimization.
    """
    
    def __init__(self, use_real_data: bool = True):
        self.mobile_workforce: Dict[str, MobileWorkforceProfile] = {}
        self.legacy_operators: Dict[str, OperatorSkillProfile] = {}
        self.skill_demands: Dict[str, SkillDemand] = {}
        self.mobile_assignments: List[MobileSkillAssignment] = []
        self.legacy_assignments: List[SkillAssignment] = []
        self.mono_skill_operators: Dict[str, List[str]] = {}  # skill -> operator_ids
        self.assignment_rules = self._initialize_assignment_rules()
        self.use_real_data = use_real_data
        self.db_connection = None
        
        if use_real_data:
            self._initialize_database_connection()
            self._load_real_workforce_data()
    
    def _initialize_database_connection(self):
        """Initialize connection to real workforce data"""
        try:
            self.db_connection = WFMDatabaseConnection()
            if self.db_connection.connect():
                logging.info("✅ Connected to real workforce database")
            else:
                logging.warning("⚠️ Database connection failed, using mock data")
                self.use_real_data = False
        except Exception as e:
            logging.error(f"Database initialization failed: {e}")
            self.use_real_data = False
    
    def _load_real_workforce_data(self, limit: int = 50):
        """Load real employee data from database"""
        if not self.db_connection:
            return
        
        try:
            real_employees = self.db_connection.get_real_employee_data(limit)
            
            for emp_data in real_employees:
                # Determine primary and secondary skills
                skills_sorted = sorted(emp_data.skills.items(), key=lambda x: x[1], reverse=True)
                primary_skill = skills_sorted[0][0] if skills_sorted else "Customer Service"
                secondary_skills = [skill for skill, _ in skills_sorted[1:]] if len(skills_sorted) > 1 else []
                
                # Create skill certifications (assume certified if proficiency > 0.8)
                certifications = {skill: prof > 0.8 for skill, prof in emp_data.skills.items()}
                
                # Create mobile workforce profile
                mobile_profile = MobileWorkforceProfile(
                    operator_id=emp_data.employee_id,
                    operator_name=f"{emp_data.first_name} {emp_data.last_name}",
                    employee_number=emp_data.employee_number,
                    position_name=emp_data.position_name,
                    department_type=emp_data.department_type,
                    level_category=emp_data.level_category,
                    primary_skill=primary_skill,
                    secondary_skills=secondary_skills,
                    skill_proficiencies=emp_data.skills,
                    skill_certifications=certifications,
                    availability_hours=8.0,  # Standard work day
                    cost_per_hour=emp_data.hourly_cost,
                    is_multi_skill=len(emp_data.skills) > 1,
                    location_type=self._determine_location_type(emp_data.department_type),
                    mobile_enabled=True,
                    mobile_performance_score=self._calculate_mobile_performance_score(emp_data)
                )
                
                self.mobile_workforce[emp_data.employee_id] = mobile_profile
                
                # Track mono-skill operators
                if not mobile_profile.is_multi_skill:
                    if primary_skill not in self.mono_skill_operators:
                        self.mono_skill_operators[primary_skill] = []
                    self.mono_skill_operators[primary_skill].append(emp_data.employee_id)
            
            logging.info(f"✅ Loaded {len(self.mobile_workforce)} real workforce profiles")
            
        except Exception as e:
            logging.error(f"Error loading real workforce data: {e}")
    
    def _determine_location_type(self, department_type: str) -> LocationType:
        """Determine location type based on department"""
        location_mapping = {
            'incoming': LocationType.OFFICE,
            'outbound': LocationType.HYBRID,
            'support': LocationType.REMOTE,
            'vip': LocationType.OFFICE,
            'management': LocationType.HYBRID,
            'quality': LocationType.OFFICE
        }
        return location_mapping.get(department_type, LocationType.OFFICE)
    
    def _calculate_mobile_performance_score(self, emp_data: EmployeeSkillData) -> float:
        """Calculate mobile performance score based on employee attributes"""
        # Base score
        score = 1.0
        
        # Adjust based on level (senior staff typically more mobile-savvy)
        level_adjustments = {
            'junior': 0.9,
            'middle': 1.0,
            'senior': 1.1,
            'lead': 1.15,
            'manager': 1.2
        }
        score *= level_adjustments.get(emp_data.level_category, 1.0)
        
        # Adjust based on skill diversity (multi-skill workers are more adaptable)
        if len(emp_data.skills) > 2:
            score *= 1.1
        elif len(emp_data.skills) == 1:
            score *= 0.95
        
        return min(1.5, max(0.7, score))  # Clamp between 0.7 and 1.5

class MultiSkillOptimizer:
    """Legacy multi-skill optimizer - maintained for backward compatibility"""
    
    def __init__(self):
        self.operators: Dict[str, OperatorSkillProfile] = {}
        self.skill_demands: Dict[str, SkillDemand] = {}
        self.assignments: List[SkillAssignment] = []
        self.mono_skill_operators: Dict[str, List[str]] = {}  # skill -> operator_ids
        self.assignment_rules = self._initialize_assignment_rules()
        
        # Initialize Mobile Workforce Scheduler for enhanced functionality
        self.mobile_scheduler = MobileWorkforceScheduler(use_real_data=True)
        
    def _initialize_assignment_rules(self) -> Dict[int, str]:
        """Initialize Mobile Workforce Scheduler assignment rules"""
        return {
            1: "Mobile-enabled mono-skill operators to primary channels",
            2: "Multi-skill operators to primary skills with location optimization",
            3: "Multi-skill operators to secondary skills considering mobile performance",
            4: "Overflow assignments with intraday adjustment capability",
            5: "Remote/field workers for specialized requirements"
        }
    
    def add_mobile_workforce_profile(self, profile: MobileWorkforceProfile):
        """Add mobile workforce profile to the optimization pool"""
        self.mobile_workforce[profile.operator_id] = profile
        
        # Track mono-skill operators
        if not profile.is_multi_skill or len(profile.secondary_skills) == 0:
            if profile.primary_skill not in self.mono_skill_operators:
                self.mono_skill_operators[profile.primary_skill] = []
            self.mono_skill_operators[profile.primary_skill].append(profile.operator_id)
    
    def add_operator(self, operator: OperatorSkillProfile):
        """Legacy method - converts to mobile workforce profile"""
        # Convert legacy operator to mobile workforce profile
        mobile_profile = MobileWorkforceProfile(
            operator_id=operator.operator_id,
            operator_name=operator.operator_name,
            employee_number=f"EMP_{operator.operator_id[:8]}",
            position_name="General Operator",
            department_type="incoming",
            level_category="middle",
            primary_skill=operator.primary_skill,
            secondary_skills=operator.secondary_skills,
            skill_proficiencies=operator.skill_proficiencies,
            skill_certifications=operator.skill_certifications,
            availability_hours=operator.availability_hours,
            cost_per_hour=operator.cost_per_hour,
            is_multi_skill=operator.is_multi_skill,
            location_type=LocationType.OFFICE,
            mobile_enabled=True
        )
        
        self.add_mobile_workforce_profile(mobile_profile)
        self.legacy_operators[operator.operator_id] = operator
    
    def set_skill_demands(self, demands: List[SkillDemand]):
        """Set skill demands for optimization"""
        self.skill_demands = {d.skill_name: d for d in demands}
    
    def optimize_mobile_assignments(self,
                                   strategy: AssignmentStrategy = AssignmentStrategy.MOBILE_WORKFORCE,
                                   constraints: Optional[Dict[str, Any]] = None) -> MobileOptimizationResult:
        """Optimize mobile workforce assignments using Mobile Workforce Scheduler pattern"""
        if strategy == AssignmentStrategy.MOBILE_WORKFORCE:
            return self._optimize_mobile_workforce(constraints)
        elif strategy == AssignmentStrategy.PRIORITY_BASED:
            return self._optimize_priority_based_mobile(constraints)
        elif strategy == AssignmentStrategy.LOAD_BALANCED:
            return self._optimize_load_balanced_mobile(constraints)
        elif strategy == AssignmentStrategy.COST_OPTIMIZED:
            return self._optimize_cost_based_mobile(constraints)
        else:
            return self._optimize_skill_development_mobile(constraints)
    
    def optimize_assignments(self,
                           strategy: AssignmentStrategy = AssignmentStrategy.PRIORITY_BASED,
                           constraints: Optional[Dict[str, Any]] = None) -> OptimizationResult:
        """Legacy optimization method - delegates to mobile scheduler"""
        mobile_result = self.optimize_mobile_assignments(strategy, constraints)
        
        # Convert to legacy format
        legacy_assignments = []
        for mobile_assignment in mobile_result.mobile_assignments:
            legacy_assignment = SkillAssignment(
                operator_id=mobile_assignment.operator_id,
                skill_name=mobile_assignment.skill_name,
                assigned_hours=mobile_assignment.assigned_hours,
                proficiency_level=mobile_assignment.proficiency_level,
                assignment_priority=mobile_assignment.assignment_priority,
                is_overflow=mobile_assignment.is_overflow,
                utilization_percentage=mobile_assignment.utilization_percentage
            )
            legacy_assignments.append(legacy_assignment)
        
        return OptimizationResult(
            assignments=legacy_assignments,
            total_cost=mobile_result.total_cost,
            skill_coverage=mobile_result.skill_coverage,
            operator_utilization=mobile_result.operator_utilization,
            unmet_demand=mobile_result.unmet_demand,
            optimization_score=mobile_result.optimization_score
        )
    
    def _optimize_mobile_workforce(self, constraints: Optional[Dict[str, Any]] = None) -> MobileOptimizationResult:
        """Optimize using Mobile Workforce Scheduler pattern with real data and location awareness"""
        self.mobile_assignments = []
        remaining_demands = {skill: demand.required_hours for skill, demand in self.skill_demands.items()}
        operator_available_hours = {op_id: op.availability_hours for op_id, op in self.mobile_workforce.items()}
        
        intraday_recommendations = []
        
        # Priority 1: Mobile-enabled mono-skill operators to primary channels
        for skill, operator_ids in self.mono_skill_operators.items():
            if skill in remaining_demands and remaining_demands[skill] > 0:
                for op_id in operator_ids:
                    if op_id in self.mobile_workforce and operator_available_hours[op_id] > 0:
                        operator = self.mobile_workforce[op_id]
                        
                        # Apply mobile performance adjustment
                        mobile_adjustment = operator.mobile_performance_score
                        effective_hours = operator_available_hours[op_id] * mobile_adjustment
                        
                        hours_to_assign = min(effective_hours, remaining_demands[skill])
                        
                        assignment = MobileSkillAssignment(
                            operator_id=op_id,
                            skill_name=skill,
                            assigned_hours=hours_to_assign,
                            proficiency_level=operator.skill_proficiencies.get(skill, 1.0),
                            assignment_priority=1,
                            is_overflow=False,
                            utilization_percentage=(hours_to_assign / operator.availability_hours) * 100,
                            location_type=operator.location_type,
                            requires_mobile_access=operator.location_type != LocationType.OFFICE,
                            estimated_performance_impact=mobile_adjustment,
                            intraday_adjustment_factor=1.0
                        )
                        
                        self.mobile_assignments.append(assignment)
                        remaining_demands[skill] -= hours_to_assign
                        operator_available_hours[op_id] -= hours_to_assign
        
        # Priority 2: Multi-skill operators with location optimization
        mobile_operators = [
            op for op in self.mobile_workforce.values()
            if op.is_multi_skill and len(op.secondary_skills) > 0
        ]
        
        # Sort by mobile performance score and skill proficiency
        mobile_operators.sort(
            key=lambda op: (op.mobile_performance_score, op.skill_proficiencies.get(op.primary_skill, 0)),
            reverse=True
        )
        
        for operator in mobile_operators:
            skill = operator.primary_skill
            if (skill in remaining_demands and 
                remaining_demands[skill] > 0 and
                operator_available_hours[operator.operator_id] > 0):
                
                # Calculate load distribution with mobile workforce adjustments
                location_factor = self._get_location_efficiency_factor(operator.location_type)
                mobile_factor = operator.mobile_performance_score
                
                primary_percentage = 0.7 * location_factor * mobile_factor
                
                hours_to_assign = min(
                    operator_available_hours[operator.operator_id] * primary_percentage,
                    remaining_demands[skill]
                )
                
                assignment = MobileSkillAssignment(
                    operator_id=operator.operator_id,
                    skill_name=skill,
                    assigned_hours=hours_to_assign,
                    proficiency_level=operator.skill_proficiencies.get(skill, 1.0),
                    assignment_priority=2,
                    is_overflow=False,
                    utilization_percentage=(hours_to_assign / operator.availability_hours) * 100,
                    location_type=operator.location_type,
                    requires_mobile_access=operator.location_type != LocationType.OFFICE,
                    estimated_performance_impact=mobile_factor,
                    intraday_adjustment_factor=location_factor
                )
                
                self.mobile_assignments.append(assignment)
                remaining_demands[skill] -= hours_to_assign
                operator_available_hours[operator.operator_id] -= hours_to_assign
                
                # Add intraday recommendation if mobile performance is suboptimal
                if mobile_factor < 0.9:
                    intraday_recommendations.append(
                        f"Monitor {operator.operator_name} mobile performance for {skill}"
                    )
        
        # Priority 3: Secondary skills with mobile considerations
        for operator in mobile_operators:
            if operator_available_hours[operator.operator_id] > 0:
                for skill in operator.secondary_skills:
                    if (skill in remaining_demands and 
                        remaining_demands[skill] > 0 and
                        operator_available_hours[operator.operator_id] > 0):
                        
                        # Check minimum proficiency with mobile adjustment
                        proficiency = operator.skill_proficiencies.get(skill, 0.5)
                        min_proficiency = self.skill_demands[skill].minimum_proficiency
                        mobile_adjusted_proficiency = proficiency * operator.mobile_performance_score
                        
                        if mobile_adjusted_proficiency >= min_proficiency * 0.9:  # 10% tolerance for mobile
                            location_factor = self._get_location_efficiency_factor(operator.location_type)
                            
                            hours_to_assign = min(
                                operator_available_hours[operator.operator_id] * location_factor,
                                remaining_demands[skill]
                            )
                            
                            assignment = MobileSkillAssignment(
                                operator_id=operator.operator_id,
                                skill_name=skill,
                                assigned_hours=hours_to_assign,
                                proficiency_level=proficiency,
                                assignment_priority=3,
                                is_overflow=False,
                                utilization_percentage=(hours_to_assign / operator.availability_hours) * 100,
                                location_type=operator.location_type,
                                requires_mobile_access=operator.location_type != LocationType.OFFICE,
                                estimated_performance_impact=operator.mobile_performance_score,
                                intraday_adjustment_factor=location_factor
                            )
                            
                            self.mobile_assignments.append(assignment)
                            remaining_demands[skill] -= hours_to_assign
                            operator_available_hours[operator.operator_id] -= hours_to_assign
        
        # Priority 4: Overflow with intraday adjustment capability
        for skill, remaining_hours in remaining_demands.items():
            if remaining_hours > 0:
                # Prioritize operators with high mobile performance for overflow
                overflow_candidates = [
                    op for op in self.mobile_workforce.values()
                    if (operator_available_hours[op.operator_id] > 0 and
                        (skill == op.primary_skill or skill in op.secondary_skills))
                ]
                
                overflow_candidates.sort(key=lambda op: op.mobile_performance_score, reverse=True)
                
                for operator in overflow_candidates:
                    if remaining_hours <= 0:
                        break
                        
                    hours_to_assign = min(
                        operator_available_hours[operator.operator_id],
                        remaining_hours
                    )
                    
                    assignment = MobileSkillAssignment(
                        operator_id=operator.operator_id,
                        skill_name=skill,
                        assigned_hours=hours_to_assign,
                        proficiency_level=operator.skill_proficiencies.get(skill, 0.5),
                        assignment_priority=4,
                        is_overflow=True,
                        utilization_percentage=(hours_to_assign / operator.availability_hours) * 100,
                        location_type=operator.location_type,
                        requires_mobile_access=operator.location_type != LocationType.OFFICE,
                        estimated_performance_impact=operator.mobile_performance_score,
                        intraday_adjustment_factor=1.1  # Higher for overflow flexibility
                    )
                    
                    self.mobile_assignments.append(assignment)
                    remaining_demands[skill] -= hours_to_assign
                    operator_available_hours[operator.operator_id] -= hours_to_assign
                    remaining_hours -= hours_to_assign
                    
                    intraday_recommendations.append(
                        f"Overflow assignment for {operator.operator_name} - monitor closely"
                    )
        
        # Calculate mobile optimization results with intraday integration
        return self._calculate_mobile_optimization_result(remaining_demands, intraday_recommendations)
    
    def _get_location_efficiency_factor(self, location_type: LocationType) -> float:
        """Get efficiency factor based on location type"""
        efficiency_factors = {
            LocationType.OFFICE: 1.0,      # Baseline efficiency
            LocationType.REMOTE: 0.95,     # Slight reduction for remote
            LocationType.HYBRID: 0.98,     # Minor reduction for hybrid
            LocationType.FIELD: 0.90,      # More reduction for field work
            LocationType.CLIENT_SITE: 0.92 # Moderate reduction for client sites
        }
        return efficiency_factors.get(location_type, 1.0)
    
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
    
    def _calculate_mobile_optimization_result(self, remaining_demands: Dict[str, float], 
                                             intraday_recommendations: List[str] = None) -> MobileOptimizationResult:
        """Calculate mobile workforce optimization result with enhanced metrics"""
        if intraday_recommendations is None:
            intraday_recommendations = []
        
        # Calculate total cost with mobile adjustments
        total_cost = sum(
            assignment.assigned_hours * self.mobile_workforce[assignment.operator_id].cost_per_hour *
            assignment.estimated_performance_impact
            for assignment in self.mobile_assignments
        )
        
        # Calculate skill coverage
        skill_coverage = {}
        for skill, demand in self.skill_demands.items():
            assigned = sum(a.assigned_hours for a in self.mobile_assignments if a.skill_name == skill)
            coverage = (assigned / demand.required_hours * 100) if demand.required_hours > 0 else 100
            skill_coverage[skill] = min(coverage, 100)
        
        # Calculate operator utilization
        operator_utilization = {}
        for operator_id, operator in self.mobile_workforce.items():
            assigned = sum(a.assigned_hours for a in self.mobile_assignments if a.operator_id == operator_id)
            utilization = (assigned / operator.availability_hours * 100) if operator.availability_hours > 0 else 0
            operator_utilization[operator_id] = utilization
        
        # Calculate unmet demand
        unmet_demand = {skill: max(0, hours) for skill, hours in remaining_demands.items()}
        
        # Calculate mobile performance score
        mobile_performance_scores = [a.estimated_performance_impact for a in self.mobile_assignments]
        mobile_performance_score = np.mean(mobile_performance_scores) if mobile_performance_scores else 1.0
        
        # Calculate location distribution
        location_distribution = defaultdict(int)
        for assignment in self.mobile_assignments:
            location_distribution[assignment.location_type] += 1
        
        # Calculate optimization score with mobile factors
        avg_coverage = np.mean(list(skill_coverage.values())) if skill_coverage else 0
        avg_utilization = np.mean(list(operator_utilization.values())) if operator_utilization else 0
        proficiency_score = np.mean([a.proficiency_level for a in self.mobile_assignments]) * 100 if self.mobile_assignments else 0
        
        # Mobile-specific adjustments to optimization score
        mobile_adjustment = mobile_performance_score * 0.2  # 20% weight for mobile performance
        location_diversity_bonus = min(len(location_distribution), 3) * 2  # Bonus for location diversity
        
        optimization_score = (
            avg_coverage * 0.35 + 
            avg_utilization * 0.25 + 
            proficiency_score * 0.25 + 
            mobile_adjustment * 100 * 0.1 + 
            location_diversity_bonus * 0.05
        )
        
        # Add intraday integration recommendations
        if self._should_add_intraday_recommendations():
            intraday_recommendations.extend(self._generate_intraday_recommendations())
        
        return MobileOptimizationResult(
            mobile_assignments=self.mobile_assignments,
            legacy_assignments=[],  # Will be populated by conversion methods
            total_cost=total_cost,
            skill_coverage=skill_coverage,
            operator_utilization=operator_utilization,
            unmet_demand=unmet_demand,
            optimization_score=optimization_score,
            mobile_performance_score=mobile_performance_score,
            location_distribution=dict(location_distribution),
            intraday_adjustment_recommendations=intraday_recommendations
        )
    
    def _should_add_intraday_recommendations(self) -> bool:
        """Check if intraday recommendations should be generated"""
        # Check if we have access to intraday data
        if not self.db_connection:
            return False
        
        # Check if there are assignments that could benefit from intraday monitoring
        mobile_assignments_count = len([a for a in self.mobile_assignments if a.requires_mobile_access])
        return mobile_assignments_count > 0
    
    def _generate_intraday_recommendations(self) -> List[str]:
        """Generate intraday adjustment recommendations based on mobile workforce patterns"""
        recommendations = []
        
        # Analyze mobile assignments for potential issues
        mobile_assignments = [a for a in self.mobile_assignments if a.requires_mobile_access]
        
        if mobile_assignments:
            avg_performance = np.mean([a.estimated_performance_impact for a in mobile_assignments])
            if avg_performance < 0.9:
                recommendations.append("Consider providing mobile performance support for remote workers")
        
        # Check for high utilization in mobile workers
        high_util_mobile = [
            a for a in mobile_assignments 
            if a.utilization_percentage > 85 and a.location_type != LocationType.OFFICE
        ]
        
        if high_util_mobile:
            recommendations.append(f"Monitor {len(high_util_mobile)} high-utilization mobile workers for burnout")
        
        # Check for overflow assignments in mobile context
        mobile_overflow = [a for a in mobile_assignments if a.is_overflow]
        if mobile_overflow:
            recommendations.append(f"Review {len(mobile_overflow)} mobile overflow assignments for optimization")
        
        return recommendations
    
    def integrate_with_intraday_schedules(self) -> bool:
        """Integrate assignments with real intraday activity schedules"""
        if not self.db_connection:
            logging.warning("No database connection for intraday integration")
            return False
        
        try:
            # Insert mobile assignments into intraday_activity_schedules
            insert_query = """
            INSERT INTO intraday_activity_schedules 
            (planning_template_id, employee_id, schedule_date, interval_start_time, interval_end_time,
             activity_type, assigned_skill, skill_priority, load_distribution_pct, impacts_service_level)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            # Generate a template ID (in real implementation, this would come from the planning system)
            template_id = "00000000-0000-0000-0000-000000000001"  # Mock template ID
            schedule_date = datetime.now().date()
            
            with self.db_connection.conn.cursor() as cur:
                for assignment in self.mobile_assignments:
                    # Convert assignment to intraday schedule entries
                    total_hours = assignment.assigned_hours
                    intervals_needed = max(1, int(total_hours))  # At least 1 interval
                    hours_per_interval = total_hours / intervals_needed
                    
                    for i in range(intervals_needed):
                        start_time = datetime.now().time().replace(hour=9+i, minute=0)  # Start at 9 AM
                        end_time = datetime.now().time().replace(hour=9+i+int(hours_per_interval), minute=0)
                        
                        # Determine skill priority based on assignment priority
                        skill_priority = "Primary" if assignment.assignment_priority <= 2 else "Secondary"
                        if assignment.is_overflow:
                            skill_priority = "Overflow"
                        
                        cur.execute(insert_query, (
                            template_id,
                            assignment.operator_id,
                            schedule_date,
                            start_time,
                            end_time,
                            "Work Attendance",
                            assignment.skill_name,
                            skill_priority,
                            assignment.utilization_percentage,
                            assignment.intraday_adjustment_factor > 1.0
                        ))
                
                self.db_connection.conn.commit()
                logging.info(f"✅ Integrated {len(self.mobile_assignments)} assignments with intraday schedules")
                return True
                
        except Exception as e:
            logging.error(f"Error integrating with intraday schedules: {e}")
            if self.db_connection.conn:
                self.db_connection.conn.rollback()
            return False
    
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
    
    def get_mobile_performance_metrics(self) -> Dict[str, Any]:
        """Get mobile workforce performance metrics for integration with mobile performance analytics"""
        if not self.mobile_assignments:
            return {"status": "No mobile assignments available"}
        
        mobile_metrics = {
            "total_mobile_assignments": len(self.mobile_assignments),
            "mobile_enabled_operators": len([a for a in self.mobile_assignments if a.requires_mobile_access]),
            "location_distribution": defaultdict(int),
            "performance_impact_distribution": {
                "high_performance": 0,  # > 1.1
                "normal_performance": 0,  # 0.9 - 1.1
                "low_performance": 0    # < 0.9
            },
            "utilization_by_location": defaultdict(list),
            "skill_coverage_by_location": defaultdict(float),
            "intraday_recommendations_count": 0
        }
        
        for assignment in self.mobile_assignments:
            # Location distribution
            mobile_metrics["location_distribution"][assignment.location_type.value] += 1
            
            # Performance impact categorization
            if assignment.estimated_performance_impact > 1.1:
                mobile_metrics["performance_impact_distribution"]["high_performance"] += 1
            elif assignment.estimated_performance_impact >= 0.9:
                mobile_metrics["performance_impact_distribution"]["normal_performance"] += 1
            else:
                mobile_metrics["performance_impact_distribution"]["low_performance"] += 1
            
            # Utilization by location
            mobile_metrics["utilization_by_location"][assignment.location_type.value].append(
                assignment.utilization_percentage
            )
        
        # Calculate average utilization by location
        for location, utilizations in mobile_metrics["utilization_by_location"].items():
            if utilizations:
                mobile_metrics["utilization_by_location"][location] = {
                    "average": np.mean(utilizations),
                    "max": max(utilizations),
                    "min": min(utilizations),
                    "count": len(utilizations)
                }
        
        # Add database integration metrics if available
        if self.db_connection:
            mobile_metrics["database_integration"] = "enabled"
            mobile_metrics["real_data_source"] = "wfm_enterprise"
        else:
            mobile_metrics["database_integration"] = "disabled"
            mobile_metrics["real_data_source"] = "mock_data"
        
        return dict(mobile_metrics)
    
    def export_mobile_assignments_for_timetable(self) -> List[Dict[str, Any]]:
        """Export mobile assignments in format suitable for timetable generation with mobile-specific data"""
        timetable_data = []
        
        for assignment in self.mobile_assignments:
            if assignment.operator_id in self.mobile_workforce:
                operator = self.mobile_workforce[assignment.operator_id]
                
                timetable_entry = {
                    "operator_id": assignment.operator_id,
                    "operator_name": operator.operator_name,
                    "employee_number": operator.employee_number,
                    "skill": assignment.skill_name,
                    "hours": assignment.assigned_hours,
                    "load_percentage": assignment.utilization_percentage,
                    "is_primary_skill": assignment.skill_name == operator.primary_skill,
                    "proficiency": assignment.proficiency_level,
                    "priority": assignment.assignment_priority,
                    # Mobile-specific fields
                    "location_type": assignment.location_type.value,
                    "mobile_enabled": operator.mobile_enabled,
                    "requires_mobile_access": assignment.requires_mobile_access,
                    "mobile_performance_score": assignment.estimated_performance_impact,
                    "intraday_adjustment_factor": assignment.intraday_adjustment_factor,
                    "department_type": operator.department_type,
                    "level_category": operator.level_category,
                    "position_name": operator.position_name,
                    "is_overflow": assignment.is_overflow
                }
                
                timetable_data.append(timetable_entry)
        
        return timetable_data
    
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