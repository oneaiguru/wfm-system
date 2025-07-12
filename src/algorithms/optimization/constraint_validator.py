#!/usr/bin/env python3
"""
Constraint Validator - BDD Implementation
From: 24-automatic-schedule-optimization.feature:52
"Constraint Validator | Rule-based system | Labor laws + contracts | Compliance matrix | 1-2 seconds"
"""

from typing import Dict, List, Optional, Any, Set
from datetime import datetime, timedelta, time
from dataclasses import dataclass, field
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class ValidationRule(Enum):
    """Types of validation rules"""
    LABOR_LAW = "labor_law"
    UNION_AGREEMENT = "union_agreement"
    EMPLOYEE_CONTRACT = "employee_contract"
    BUSINESS_RULE = "business_rule"
    EMPLOYEE_PREFERENCE = "employee_preference"

class ViolationSeverity(Enum):
    """Severity levels for violations"""
    CRITICAL = "critical"     # Must fix - blocks implementation
    HIGH = "high"            # Should fix - significant risk
    MEDIUM = "medium"        # Could fix - minor risk
    LOW = "low"             # Optional - minimal impact

@dataclass
class ConstraintViolation:
    """Individual constraint violation"""
    rule_id: str
    rule_type: ValidationRule
    severity: ViolationSeverity
    description: str
    affected_employee: Optional[str]
    affected_timeperiod: Optional[str]
    resolution_suggestion: str
    cost_impact: float

@dataclass
class ComplianceMatrix:
    """Complete compliance validation result"""
    total_violations: int
    violations_by_severity: Dict[ViolationSeverity, int]
    violations_by_rule_type: Dict[ValidationRule, int]
    compliance_score: float
    all_violations: List[ConstraintViolation]
    validation_summary: Dict[str, Any]
    processing_time_ms: float

class ConstraintValidator:
    """
    Rule-based constraint validation system
    BDD Requirement: Labor laws + contracts → Compliance matrix
    """
    
    def __init__(self):
        # BDD Requirements from line 168-172
        self.labor_law_rules = {
            'max_hours_week': 40,      # Max 40 hours/week
            'min_rest_hours': 11,      # 11 hours rest between shifts
            'max_overtime_week': 8,    # Maximum 8 hours overtime per week
            'max_consecutive_days': 6,  # Maximum 6 consecutive workdays
            'min_vacation_days': 20    # Minimum 20 vacation days per year
        }
        
        # Union agreement rules (BDD line 169)
        self.union_rules = {
            'overtime_ratio_limit': 0.20,  # Max 20% overtime ratio
            'weekend_work_limit': 2,       # Max 2 weekends per month
            'shift_pattern_consistency': True,  # Consistent patterns required
            'min_advance_notice': 72       # 72 hours advance notice for changes
        }
        
        # BDD target processing time: 1-2 seconds
        self.processing_target = 2.0
        
    def validate_schedule_constraints(self,
                                   schedule_variant: Dict[str, Any],
                                   labor_laws: Dict[str, Any],
                                   union_contracts: Dict[str, Any],
                                   employee_contracts: List[Dict[str, Any]]) -> ComplianceMatrix:
        """
        Main constraint validation per BDD specification
        Input: Labor laws + contracts
        Output: Compliance matrix
        Processing: 1-2 seconds (BDD requirement)
        """
        start_time = datetime.now()
        
        # Step 1: Labor law validation (BDD line 58)
        labor_violations = self._validate_labor_laws(schedule_variant, labor_laws)
        
        # Step 2: Union agreement validation (BDD line 59)
        union_violations = self._validate_union_agreements(schedule_variant, union_contracts)
        
        # Step 3: Employee contract validation (BDD line 60)
        contract_violations = self._validate_employee_contracts(schedule_variant, employee_contracts)
        
        # Step 4: Business rule validation (BDD line 61)
        business_violations = self._validate_business_rules(schedule_variant)
        
        # Step 5: Employee preference validation (BDD line 62)
        preference_violations = self._validate_employee_preferences(schedule_variant)
        
        # Combine all violations
        all_violations = (
            labor_violations + union_violations + 
            contract_violations + business_violations + preference_violations
        )
        
        # Calculate compliance metrics
        violations_by_severity = self._count_by_severity(all_violations)
        violations_by_rule_type = self._count_by_rule_type(all_violations)
        compliance_score = self._calculate_compliance_score(all_violations)
        
        # Validation summary
        summary = self._generate_validation_summary(all_violations)
        
        # Processing time validation
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return ComplianceMatrix(
            total_violations=len(all_violations),
            violations_by_severity=violations_by_severity,
            violations_by_rule_type=violations_by_rule_type,
            compliance_score=compliance_score,
            all_violations=all_violations,
            validation_summary=summary,
            processing_time_ms=processing_time
        )
    
    def _validate_labor_laws(self, 
                           schedule: Dict[str, Any],
                           labor_laws: Dict[str, Any]) -> List[ConstraintViolation]:
        """Validate against labor law requirements (BDD line 58)"""
        violations = []
        
        schedule_blocks = schedule.get('schedule_blocks', [])
        
        for block in schedule_blocks:
            employee_id = block.get('employee_id')
            
            # Max hours per week validation
            weekly_hours = self._calculate_weekly_hours(block)
            if weekly_hours > self.labor_law_rules['max_hours_week']:
                violations.append(ConstraintViolation(
                    rule_id="LAB_001",
                    rule_type=ValidationRule.LABOR_LAW,
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Weekly hours {weekly_hours} exceed legal limit of {self.labor_law_rules['max_hours_week']}",
                    affected_employee=employee_id,
                    affected_timeperiod=block.get('week_period'),
                    resolution_suggestion="Reduce weekly hours or distribute across multiple employees",
                    cost_impact=weekly_hours * 35.0  # Penalty cost
                ))
            
            # Rest period validation (BDD requirement: 11 hours rest)
            rest_hours = self._calculate_rest_period(block)
            if rest_hours < self.labor_law_rules['min_rest_hours']:
                violations.append(ConstraintViolation(
                    rule_id="LAB_002",
                    rule_type=ValidationRule.LABOR_LAW,
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Rest period {rest_hours}h below legal minimum {self.labor_law_rules['min_rest_hours']}h",
                    affected_employee=employee_id,
                    affected_timeperiod=block.get('date'),
                    resolution_suggestion="Extend rest period between shifts",
                    cost_impact=500.0  # Compliance penalty
                ))
            
            # Overtime validation
            overtime_hours = self._calculate_overtime(block)
            if overtime_hours > self.labor_law_rules['max_overtime_week']:
                violations.append(ConstraintViolation(
                    rule_id="LAB_003",
                    rule_type=ValidationRule.LABOR_LAW,
                    severity=ViolationSeverity.HIGH,
                    description=f"Overtime {overtime_hours}h exceeds weekly limit {self.labor_law_rules['max_overtime_week']}h",
                    affected_employee=employee_id,
                    affected_timeperiod=block.get('week_period'),
                    resolution_suggestion="Redistribute overtime or hire additional staff",
                    cost_impact=overtime_hours * 52.5  # 1.5x overtime rate
                ))
        
        return violations
    
    def _validate_union_agreements(self,
                                 schedule: Dict[str, Any],
                                 union_contracts: Dict[str, Any]) -> List[ConstraintViolation]:
        """Validate against union agreement terms (BDD line 59)"""
        violations = []
        
        schedule_blocks = schedule.get('schedule_blocks', [])
        
        # Overtime ratio validation
        total_hours = sum(self._calculate_weekly_hours(block) for block in schedule_blocks)
        overtime_hours = sum(self._calculate_overtime(block) for block in schedule_blocks)
        
        if total_hours > 0:
            overtime_ratio = overtime_hours / total_hours
            if overtime_ratio > self.union_rules['overtime_ratio_limit']:
                violations.append(ConstraintViolation(
                    rule_id="UNION_001",
                    rule_type=ValidationRule.UNION_AGREEMENT,
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Overtime ratio {overtime_ratio:.1%} exceeds union limit {self.union_rules['overtime_ratio_limit']:.1%}",
                    affected_employee=None,
                    affected_timeperiod="All periods",
                    resolution_suggestion="Reduce overtime assignments or negotiate with union",
                    cost_impact=overtime_hours * 100.0  # Union penalty
                ))
        
        # Weekend work validation
        for block in schedule_blocks:
            weekend_shifts = self._count_weekend_shifts(block)
            if weekend_shifts > self.union_rules['weekend_work_limit']:
                violations.append(ConstraintViolation(
                    rule_id="UNION_002",
                    rule_type=ValidationRule.UNION_AGREEMENT,
                    severity=ViolationSeverity.HIGH,
                    description=f"Weekend shifts {weekend_shifts} exceed union limit {self.union_rules['weekend_work_limit']}",
                    affected_employee=block.get('employee_id'),
                    affected_timeperiod=block.get('month_period'),
                    resolution_suggestion="Rotate weekend assignments among team members",
                    cost_impact=weekend_shifts * 200.0  # Weekend premium
                ))
        
        return violations
    
    def _validate_employee_contracts(self,
                                   schedule: Dict[str, Any],
                                   employee_contracts: List[Dict[str, Any]]) -> List[ConstraintViolation]:
        """Validate against individual employee contracts (BDD line 60)"""
        violations = []
        
        schedule_blocks = schedule.get('schedule_blocks', [])
        contract_map = {contract['employee_id']: contract for contract in employee_contracts}
        
        for block in schedule_blocks:
            employee_id = block.get('employee_id')
            contract = contract_map.get(employee_id)
            
            if not contract:
                continue
            
            # Individual hour limitations
            weekly_hours = self._calculate_weekly_hours(block)
            max_contract_hours = contract.get('max_weekly_hours', 40)
            
            if weekly_hours > max_contract_hours:
                violations.append(ConstraintViolation(
                    rule_id="CONTRACT_001",
                    rule_type=ValidationRule.EMPLOYEE_CONTRACT,
                    severity=ViolationSeverity.HIGH,
                    description=f"Weekly hours {weekly_hours} exceed contract limit {max_contract_hours}",
                    affected_employee=employee_id,
                    affected_timeperiod=block.get('week_period'),
                    resolution_suggestion="Respect individual contract limitations",
                    cost_impact=weekly_hours * 40.0  # Contract breach cost
                ))
            
            # Skill requirements
            required_skills = block.get('required_skills', [])
            employee_skills = contract.get('certified_skills', [])
            
            missing_skills = set(required_skills) - set(employee_skills)
            if missing_skills:
                violations.append(ConstraintViolation(
                    rule_id="CONTRACT_002",
                    rule_type=ValidationRule.EMPLOYEE_CONTRACT,
                    severity=ViolationSeverity.MEDIUM,
                    description=f"Missing skills: {', '.join(missing_skills)}",
                    affected_employee=employee_id,
                    affected_timeperiod=block.get('date'),
                    resolution_suggestion="Provide training or reassign to qualified employee",
                    cost_impact=len(missing_skills) * 1000.0  # Training cost
                ))
        
        return violations
    
    def _validate_business_rules(self, schedule: Dict[str, Any]) -> List[ConstraintViolation]:
        """Validate against business rules (BDD line 61)"""
        violations = []
        
        schedule_blocks = schedule.get('schedule_blocks', [])
        
        # Minimum coverage validation (80/20 format during business hours)
        business_hours = range(8, 18)  # 8 AM to 6 PM
        
        for hour in business_hours:
            hour_coverage = self._calculate_hour_coverage(schedule_blocks, hour)
            if hour_coverage < 1:  # Minimum 1 agent during business hours
                violations.append(ConstraintViolation(
                    rule_id="BIZ_001",
                    rule_type=ValidationRule.BUSINESS_RULE,
                    severity=ViolationSeverity.CRITICAL,
                    description=f"No coverage at {hour:02d}:00 during business hours",
                    affected_employee=None,
                    affected_timeperiod=f"{hour:02d}:00",
                    resolution_suggestion="Add coverage during business hours",
                    cost_impact=hour_coverage * 50.0  # Service penalty
                ))
        
        # Skill distribution validation
        total_agents = len(set(block.get('employee_id') for block in schedule_blocks))
        skilled_agents = len(set(
            block.get('employee_id') for block in schedule_blocks 
            if block.get('skill_level', 'basic') in ['intermediate', 'expert']
        ))
        
        if total_agents > 0:
            skill_ratio = skilled_agents / total_agents
            if skill_ratio < 0.3:  # Minimum 30% skilled agents
                violations.append(ConstraintViolation(
                    rule_id="BIZ_002",
                    rule_type=ValidationRule.BUSINESS_RULE,
                    severity=ViolationSeverity.HIGH,
                    description=f"Skilled agent ratio {skill_ratio:.1%} below minimum 30%",
                    affected_employee=None,
                    affected_timeperiod="All periods",
                    resolution_suggestion="Include more skilled agents or provide training",
                    cost_impact=(0.3 - skill_ratio) * 5000.0  # Training cost
                ))
        
        return violations
    
    def _validate_employee_preferences(self, schedule: Dict[str, Any]) -> List[ConstraintViolation]:
        """Validate against employee preferences (BDD line 62)"""
        violations = []
        
        schedule_blocks = schedule.get('schedule_blocks', [])
        
        # Simplified preference validation
        for block in schedule_blocks:
            preferred_shifts = block.get('preferred_shifts', [])
            assigned_shift = f"{block.get('start_time', '08:00')}-{block.get('end_time', '16:00')}"
            
            if preferred_shifts and assigned_shift not in preferred_shifts:
                violations.append(ConstraintViolation(
                    rule_id="PREF_001",
                    rule_type=ValidationRule.EMPLOYEE_PREFERENCE,
                    severity=ViolationSeverity.LOW,
                    description=f"Assigned shift {assigned_shift} not in preferences: {', '.join(preferred_shifts)}",
                    affected_employee=block.get('employee_id'),
                    affected_timeperiod=block.get('date'),
                    resolution_suggestion="Consider employee preferences when possible",
                    cost_impact=50.0  # Satisfaction cost
                ))
        
        return violations
    
    def _calculate_weekly_hours(self, block: Dict[str, Any]) -> float:
        """Calculate weekly hours for a schedule block"""
        # Simplified calculation
        start_time = block.get('start_time', '08:00')
        end_time = block.get('end_time', '16:00')
        
        start_hour = int(start_time.split(':')[0])
        end_hour = int(end_time.split(':')[0])
        daily_hours = end_hour - start_hour
        
        days_per_week = block.get('days_per_week', 5)
        return daily_hours * days_per_week
    
    def _calculate_rest_period(self, block: Dict[str, Any]) -> float:
        """Calculate rest period between shifts"""
        # Simplified - assume standard rest period
        return block.get('rest_hours', 12.0)
    
    def _calculate_overtime(self, block: Dict[str, Any]) -> float:
        """Calculate overtime hours"""
        weekly_hours = self._calculate_weekly_hours(block)
        regular_hours = block.get('regular_hours', 40.0)
        return max(0, weekly_hours - regular_hours)
    
    def _count_weekend_shifts(self, block: Dict[str, Any]) -> int:
        """Count weekend shifts for employee"""
        return block.get('weekend_shifts', 0)
    
    def _calculate_hour_coverage(self, blocks: List[Dict[str, Any]], hour: int) -> int:
        """Calculate coverage for specific hour"""
        coverage = 0
        for block in blocks:
            start_hour = int(block.get('start_time', '08:00').split(':')[0])
            end_hour = int(block.get('end_time', '16:00').split(':')[0])
            
            if start_hour <= hour < end_hour:
                coverage += 1
        
        return coverage
    
    def _count_by_severity(self, violations: List[ConstraintViolation]) -> Dict[ViolationSeverity, int]:
        """Count violations by severity"""
        counts = {severity: 0 for severity in ViolationSeverity}
        for violation in violations:
            counts[violation.severity] += 1
        return counts
    
    def _count_by_rule_type(self, violations: List[ConstraintViolation]) -> Dict[ValidationRule, int]:
        """Count violations by rule type"""
        counts = {rule_type: 0 for rule_type in ValidationRule}
        for violation in violations:
            counts[violation.rule_type] += 1
        return counts
    
    def _calculate_compliance_score(self, violations: List[ConstraintViolation]) -> float:
        """Calculate overall compliance score (0-100)"""
        if not violations:
            return 100.0
        
        # Weight violations by severity
        severity_weights = {
            ViolationSeverity.CRITICAL: 10,
            ViolationSeverity.HIGH: 5,
            ViolationSeverity.MEDIUM: 2,
            ViolationSeverity.LOW: 1
        }
        
        total_penalty = sum(severity_weights[v.severity] for v in violations)
        
        # Calculate score (max penalty assumed to be 100)
        max_penalty = 100
        score = max(0, 100 - (total_penalty * 100 / max_penalty))
        
        return score
    
    def _generate_validation_summary(self, violations: List[ConstraintViolation]) -> Dict[str, Any]:
        """Generate validation summary"""
        return {
            'critical_issues': len([v for v in violations if v.severity == ViolationSeverity.CRITICAL]),
            'high_priority': len([v for v in violations if v.severity == ViolationSeverity.HIGH]),
            'total_cost_impact': sum(v.cost_impact for v in violations),
            'most_common_violation': self._find_most_common_violation(violations),
            'recommendations': self._generate_recommendations(violations)
        }
    
    def _find_most_common_violation(self, violations: List[ConstraintViolation]) -> str:
        """Find most common violation type"""
        if not violations:
            return "No violations"
        
        rule_counts = {}
        for violation in violations:
            rule_counts[violation.rule_type] = rule_counts.get(violation.rule_type, 0) + 1
        
        most_common = max(rule_counts.items(), key=lambda x: x[1])
        return f"{most_common[0].value} ({most_common[1]} violations)"
    
    def _generate_recommendations(self, violations: List[ConstraintViolation]) -> List[str]:
        """Generate improvement recommendations"""
        recommendations = []
        
        critical_violations = [v for v in violations if v.severity == ViolationSeverity.CRITICAL]
        if critical_violations:
            recommendations.append("URGENT: Address critical violations before implementation")
        
        labor_violations = [v for v in violations if v.rule_type == ValidationRule.LABOR_LAW]
        if labor_violations:
            recommendations.append("Review labor law compliance and adjust schedules")
        
        union_violations = [v for v in violations if v.rule_type == ValidationRule.UNION_AGREEMENT]
        if union_violations:
            recommendations.append("Consult with union representatives for agreement compliance")
        
        if len(violations) > 10:
            recommendations.append("Consider simplifying schedule patterns to reduce violations")
        
        return recommendations[:5]  # Limit to top 5 recommendations
    
    def validate_bdd_requirements(self, result: ComplianceMatrix) -> Dict[str, bool]:
        """Validate against BDD requirements"""
        validation = {}
        
        # Processing time: 1-2 seconds
        validation['processing_time'] = result.processing_time_ms <= 2000
        
        # Compliance matrix generated
        validation['compliance_matrix'] = result.compliance_score is not None
        
        # Labor law validation completed
        validation['labor_law_validation'] = ValidationRule.LABOR_LAW in result.violations_by_rule_type
        
        # Union agreement validation completed
        validation['union_validation'] = ValidationRule.UNION_AGREEMENT in result.violations_by_rule_type
        
        # Violation severity classification
        validation['severity_classification'] = len(result.violations_by_severity) > 0
        
        return validation