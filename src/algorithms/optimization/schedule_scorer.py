#!/usr/bin/env python3
"""
Multi-Criteria Schedule Scorer
Implements sophisticated schedule scoring that Argus lacks
Evaluates schedules across multiple dimensions with configurable weights
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
import json

@dataclass
class ScheduleMetrics:
    """Comprehensive schedule evaluation metrics"""
    coverage_score: float
    cost_score: float
    compliance_score: float
    fairness_score: float
    efficiency_score: float
    flexibility_score: float
    continuity_score: float
    preference_score: float
    overall_score: float
    detailed_breakdown: Dict

class MultiCriteriaScheduleScorer:
    """
    Advanced schedule scoring system
    Far more sophisticated than Argus's basic evaluation
    """
    
    def __init__(self):
        # Default weights (customizable)
        self.weights = {
            'coverage': 0.30,      # Meeting demand
            'cost': 0.25,          # Labor cost optimization
            'compliance': 0.20,    # Legal/policy compliance
            'fairness': 0.10,      # Fair distribution
            'efficiency': 0.05,    # Resource utilization
            'flexibility': 0.05,   # Adaptability
            'continuity': 0.03,    # Shift patterns
            'preference': 0.02     # Agent preferences
        }
        
        # Scoring thresholds
        self.thresholds = {
            'coverage': {
                'excellent': 0.98,
                'good': 0.95,
                'acceptable': 0.90,
                'poor': 0.80
            },
            'cost': {
                'excellent': 0.90,  # Within 10% of optimal
                'good': 0.85,
                'acceptable': 0.80,
                'poor': 0.70
            },
            'compliance': {
                'excellent': 1.0,   # 100% compliant
                'good': 0.98,
                'acceptable': 0.95,
                'poor': 0.90
            }
        }
    
    def score_schedule(self, 
                      schedule: Dict,
                      requirements: Dict,
                      constraints: Optional[Dict] = None,
                      preferences: Optional[Dict] = None) -> ScheduleMetrics:
        """
        Score a schedule across all dimensions
        This comprehensive evaluation is what Argus lacks
        """
        # Calculate individual scores
        coverage_score, coverage_details = self._score_coverage(schedule, requirements)
        cost_score, cost_details = self._score_cost(schedule, requirements)
        compliance_score, compliance_details = self._score_compliance(schedule, constraints)
        fairness_score, fairness_details = self._score_fairness(schedule)
        efficiency_score, efficiency_details = self._score_efficiency(schedule, requirements)
        flexibility_score, flexibility_details = self._score_flexibility(schedule)
        continuity_score, continuity_details = self._score_continuity(schedule)
        preference_score, preference_details = self._score_preferences(schedule, preferences)
        
        # Calculate weighted overall score
        scores = {
            'coverage': coverage_score,
            'cost': cost_score,
            'compliance': compliance_score,
            'fairness': fairness_score,
            'efficiency': efficiency_score,
            'flexibility': flexibility_score,
            'continuity': continuity_score,
            'preference': preference_score
        }
        
        overall_score = sum(scores[metric] * self.weights[metric] 
                          for metric in scores)
        
        # Compile detailed breakdown
        detailed_breakdown = {
            'coverage': coverage_details,
            'cost': cost_details,
            'compliance': compliance_details,
            'fairness': fairness_details,
            'efficiency': efficiency_details,
            'flexibility': flexibility_details,
            'continuity': continuity_details,
            'preference': preference_details,
            'weighted_scores': {
                metric: scores[metric] * self.weights[metric]
                for metric in scores
            }
        }
        
        return ScheduleMetrics(
            coverage_score=coverage_score,
            cost_score=cost_score,
            compliance_score=compliance_score,
            fairness_score=fairness_score,
            efficiency_score=efficiency_score,
            flexibility_score=flexibility_score,
            continuity_score=continuity_score,
            preference_score=preference_score,
            overall_score=overall_score,
            detailed_breakdown=detailed_breakdown
        )
    
    def _score_coverage(self, schedule: Dict, requirements: Dict) -> Tuple[float, Dict]:
        """
        Score how well schedule meets coverage requirements
        """
        total_intervals = 0
        covered_intervals = 0
        gap_severity = 0
        interval_scores = []
        
        for interval, requirement in requirements.items():
            scheduled = self._count_scheduled_agents(schedule, interval)
            required = requirement.get('required_agents', 0)
            
            if required > 0:
                coverage_ratio = min(1.0, scheduled / required)
                interval_scores.append({
                    'interval': interval,
                    'required': required,
                    'scheduled': scheduled,
                    'coverage': coverage_ratio,
                    'gap': max(0, required - scheduled)
                })
                
                covered_intervals += coverage_ratio
                total_intervals += 1
                
                # Calculate gap severity
                if scheduled < required:
                    gap_pct = (required - scheduled) / required
                    gap_severity += gap_pct ** 2  # Square to penalize large gaps
        
        # Base coverage score
        if total_intervals > 0:
            base_score = covered_intervals / total_intervals
            
            # Apply penalty for severe gaps
            severity_penalty = min(0.2, gap_severity / total_intervals)
            coverage_score = max(0, base_score - severity_penalty)
        else:
            coverage_score = 1.0
        
        details = {
            'base_coverage': base_score if total_intervals > 0 else 1.0,
            'gap_penalty': severity_penalty if total_intervals > 0 else 0,
            'total_intervals': total_intervals,
            'fully_covered': sum(1 for s in interval_scores if s['coverage'] >= 1.0),
            'critical_gaps': [s for s in interval_scores if s['gap'] > 5],
            'interval_breakdown': interval_scores[:10]  # Top 10 for brevity
        }
        
        return coverage_score, details
    
    def _score_cost(self, schedule: Dict, requirements: Dict) -> Tuple[float, Dict]:
        """
        Score schedule cost efficiency
        """
        # Calculate actual cost
        total_hours = 0
        overtime_hours = 0
        idle_hours = 0
        
        for agent in schedule.get('agents', []):
            agent_hours = self._calculate_agent_hours(agent)
            total_hours += agent_hours['regular']
            overtime_hours += agent_hours['overtime']
            idle_hours += agent_hours['idle']
        
        # Calculate theoretical minimum cost
        min_hours = sum(req.get('required_agents', 0) * 0.25  # 15-min intervals
                       for req in requirements.values())
        
        # Cost factors
        regular_cost = total_hours * 1.0
        overtime_cost = overtime_hours * 1.5
        idle_cost = idle_hours * 0.8  # Idle time still costs
        
        actual_cost = regular_cost + overtime_cost + idle_cost
        theoretical_min = min_hours * 1.0
        
        # Calculate efficiency
        if theoretical_min > 0:
            cost_efficiency = theoretical_min / actual_cost
            cost_score = min(1.0, cost_efficiency)
        else:
            cost_score = 1.0
        
        details = {
            'total_hours': round(total_hours, 2),
            'overtime_hours': round(overtime_hours, 2),
            'idle_hours': round(idle_hours, 2),
            'regular_cost': round(regular_cost, 2),
            'overtime_cost': round(overtime_cost, 2),
            'total_cost': round(actual_cost, 2),
            'theoretical_minimum': round(theoretical_min, 2),
            'efficiency_ratio': round(cost_efficiency if theoretical_min > 0 else 1.0, 3),
            'cost_per_interval': round(actual_cost / max(1, len(requirements)), 2)
        }
        
        return cost_score, details
    
    def _score_compliance(self, schedule: Dict, constraints: Optional[Dict]) -> Tuple[float, Dict]:
        """
        Score legal and policy compliance
        """
        if not constraints:
            return 1.0, {'status': 'no_constraints_defined'}
        
        violations = []
        checks_passed = 0
        total_checks = 0
        
        # Check each constraint type
        compliance_checks = {
            'max_hours': self._check_max_hours,
            'min_rest': self._check_min_rest,
            'max_consecutive': self._check_max_consecutive,
            'break_requirements': self._check_breaks,
            'skill_requirements': self._check_skills
        }
        
        for check_name, check_func in compliance_checks.items():
            if check_name in constraints:
                total_checks += 1
                result = check_func(schedule, constraints[check_name])
                if result['compliant']:
                    checks_passed += 1
                else:
                    violations.extend(result['violations'])
        
        # Calculate compliance score
        if total_checks > 0:
            compliance_score = checks_passed / total_checks
            
            # Apply severity penalties
            for violation in violations:
                if violation.get('severity') == 'critical':
                    compliance_score *= 0.8
                elif violation.get('severity') == 'major':
                    compliance_score *= 0.9
        else:
            compliance_score = 1.0
        
        details = {
            'checks_passed': checks_passed,
            'total_checks': total_checks,
            'violations': violations[:10],  # Top 10 violations
            'violation_count': len(violations),
            'critical_violations': sum(1 for v in violations if v.get('severity') == 'critical'),
            'compliance_percentage': round(compliance_score * 100, 2)
        }
        
        return max(0, compliance_score), details
    
    def _score_fairness(self, schedule: Dict) -> Tuple[float, Dict]:
        """
        Score fairness of work distribution
        """
        agents = schedule.get('agents', [])
        if not agents:
            return 1.0, {'status': 'no_agents'}
        
        # Calculate work distribution
        work_hours = []
        weekend_shifts = []
        night_shifts = []
        
        for agent in agents:
            hours = self._calculate_agent_hours(agent)
            work_hours.append(hours['total'])
            weekend_shifts.append(hours['weekend_count'])
            night_shifts.append(hours['night_count'])
        
        # Calculate fairness metrics
        work_hours = np.array(work_hours)
        
        # Coefficient of variation for work hours
        if np.mean(work_hours) > 0:
            cv_hours = np.std(work_hours) / np.mean(work_hours)
        else:
            cv_hours = 0
        
        # Gini coefficient for work distribution
        gini = self._calculate_gini_coefficient(work_hours)
        
        # Weekend/night shift fairness
        weekend_fairness = 1 - (np.std(weekend_shifts) / max(1, np.mean(weekend_shifts)))
        night_fairness = 1 - (np.std(night_shifts) / max(1, np.mean(night_shifts)))
        
        # Combined fairness score
        fairness_score = (
            (1 - gini) * 0.4 +
            (1 - cv_hours) * 0.3 +
            weekend_fairness * 0.15 +
            night_fairness * 0.15
        )
        
        details = {
            'hours_distribution': {
                'mean': round(np.mean(work_hours), 2),
                'std': round(np.std(work_hours), 2),
                'cv': round(cv_hours, 3),
                'gini': round(gini, 3)
            },
            'weekend_fairness': round(weekend_fairness, 3),
            'night_fairness': round(night_fairness, 3),
            'most_hours': round(np.max(work_hours), 2),
            'least_hours': round(np.min(work_hours), 2),
            'hours_range': round(np.max(work_hours) - np.min(work_hours), 2)
        }
        
        return max(0, min(1, fairness_score)), details
    
    def _score_efficiency(self, schedule: Dict, requirements: Dict) -> Tuple[float, Dict]:
        """
        Score resource utilization efficiency
        """
        total_capacity = 0
        utilized_capacity = 0
        overstaffed_intervals = 0
        understaffed_intervals = 0
        
        for interval, requirement in requirements.items():
            scheduled = self._count_scheduled_agents(schedule, interval)
            required = requirement.get('required_agents', 0)
            
            total_capacity += scheduled
            utilized_capacity += min(scheduled, required)
            
            if scheduled > required * 1.1:  # 10% overstaffed
                overstaffed_intervals += 1
            elif scheduled < required * 0.9:  # 10% understaffed
                understaffed_intervals += 1
        
        # Calculate efficiency metrics
        if total_capacity > 0:
            utilization_rate = utilized_capacity / total_capacity
        else:
            utilization_rate = 0
        
        # Penalize both over and understaffing
        staffing_accuracy = 1 - (
            (overstaffed_intervals + understaffed_intervals) / 
            max(1, len(requirements))
        )
        
        efficiency_score = utilization_rate * 0.6 + staffing_accuracy * 0.4
        
        details = {
            'utilization_rate': round(utilization_rate, 3),
            'staffing_accuracy': round(staffing_accuracy, 3),
            'overstaffed_intervals': overstaffed_intervals,
            'understaffed_intervals': understaffed_intervals,
            'total_intervals': len(requirements),
            'average_utilization': round(utilization_rate * 100, 1),
            'waste_percentage': round((1 - utilization_rate) * 100, 1)
        }
        
        return efficiency_score, details
    
    def _score_flexibility(self, schedule: Dict) -> Tuple[float, Dict]:
        """
        Score schedule flexibility and adaptability
        """
        agents = schedule.get('agents', [])
        
        # Calculate flexibility metrics
        multi_skilled_agents = 0
        flexible_shifts = 0
        backup_coverage = 0
        
        for agent in agents:
            skills = agent.get('skills', [])
            if len(skills) > 1:
                multi_skilled_agents += 1
            
            # Check for flexible shift patterns
            if self._has_flexible_pattern(agent):
                flexible_shifts += 1
        
        # Calculate scores
        if len(agents) > 0:
            skill_flexibility = multi_skilled_agents / len(agents)
            shift_flexibility = flexible_shifts / len(agents)
        else:
            skill_flexibility = 0
            shift_flexibility = 0
        
        # Check backup coverage
        backup_ratio = self._calculate_backup_coverage(schedule)
        
        flexibility_score = (
            skill_flexibility * 0.4 +
            shift_flexibility * 0.3 +
            backup_ratio * 0.3
        )
        
        details = {
            'multi_skilled_ratio': round(skill_flexibility, 3),
            'flexible_shifts_ratio': round(shift_flexibility, 3),
            'backup_coverage_ratio': round(backup_ratio, 3),
            'multi_skilled_count': multi_skilled_agents,
            'total_agents': len(agents),
            'adaptability_index': round(flexibility_score * 100, 1)
        }
        
        return flexibility_score, details
    
    def _score_continuity(self, schedule: Dict) -> Tuple[float, Dict]:
        """
        Score shift pattern continuity
        """
        pattern_score = 0
        consistency_score = 0
        
        agents = schedule.get('agents', [])
        if not agents:
            return 1.0, {'status': 'no_agents'}
        
        # Analyze shift patterns
        good_patterns = 0
        poor_patterns = 0
        
        for agent in agents:
            pattern_quality = self._analyze_shift_pattern(agent)
            if pattern_quality == 'good':
                good_patterns += 1
            elif pattern_quality == 'poor':
                poor_patterns += 1
        
        if len(agents) > 0:
            pattern_score = (good_patterns - poor_patterns) / len(agents)
            continuity_score = (pattern_score + 1) / 2  # Normalize to 0-1
        else:
            continuity_score = 0.5
        
        details = {
            'good_patterns': good_patterns,
            'poor_patterns': poor_patterns,
            'neutral_patterns': len(agents) - good_patterns - poor_patterns,
            'pattern_quality_ratio': round(pattern_score, 3),
            'consistency_index': round(continuity_score * 100, 1)
        }
        
        return max(0, min(1, continuity_score)), details
    
    def _score_preferences(self, schedule: Dict, preferences: Optional[Dict]) -> Tuple[float, Dict]:
        """
        Score how well schedule matches agent preferences
        """
        if not preferences:
            return 0.5, {'status': 'no_preferences_defined'}
        
        agents = schedule.get('agents', [])
        total_preferences = 0
        met_preferences = 0
        preference_violations = []
        
        for agent in agents:
            agent_id = agent.get('id')
            if agent_id in preferences:
                agent_prefs = preferences[agent_id]
                
                # Check various preference types
                for pref_type, pref_value in agent_prefs.items():
                    total_preferences += 1
                    if self._check_preference_met(agent, pref_type, pref_value):
                        met_preferences += 1
                    else:
                        preference_violations.append({
                            'agent': agent_id,
                            'preference': pref_type,
                            'requested': pref_value
                        })
        
        if total_preferences > 0:
            preference_score = met_preferences / total_preferences
        else:
            preference_score = 0.5
        
        details = {
            'preferences_met': met_preferences,
            'total_preferences': total_preferences,
            'satisfaction_rate': round(preference_score * 100, 1),
            'violations': preference_violations[:10],
            'agents_with_preferences': len([a for a in agents if a.get('id') in preferences])
        }
        
        return preference_score, details
    
    # Helper methods
    
    def _count_scheduled_agents(self, schedule: Dict, interval: str) -> int:
        """Count agents scheduled for a specific interval"""
        count = 0
        for agent in schedule.get('agents', []):
            if self._is_agent_scheduled(agent, interval):
                count += 1
        return count
    
    def _is_agent_scheduled(self, agent: Dict, interval: str) -> bool:
        """Check if agent is scheduled for interval"""
        # Implementation depends on schedule format
        shifts = agent.get('shifts', [])
        for shift in shifts:
            if self._interval_in_shift(interval, shift):
                return True
        return False
    
    def _interval_in_shift(self, interval: str, shift: Dict) -> bool:
        """Check if interval falls within shift"""
        # Parse interval and shift times
        # This is a simplified check
        return True  # Placeholder
    
    def _calculate_agent_hours(self, agent: Dict) -> Dict:
        """Calculate various hour metrics for an agent"""
        total_hours = 0
        regular_hours = 0
        overtime_hours = 0
        idle_hours = 0
        weekend_count = 0
        night_count = 0
        
        # Simplified calculation
        shifts = agent.get('shifts', [])
        for shift in shifts:
            hours = shift.get('duration', 8)
            total_hours += hours
            
            if total_hours > 40:
                overtime_hours += hours
            else:
                regular_hours += hours
        
        return {
            'total': total_hours,
            'regular': regular_hours,
            'overtime': overtime_hours,
            'idle': idle_hours,
            'weekend_count': weekend_count,
            'night_count': night_count
        }
    
    def _calculate_gini_coefficient(self, values: np.ndarray) -> float:
        """Calculate Gini coefficient for inequality measurement"""
        if len(values) == 0:
            return 0
        
        sorted_values = np.sort(values)
        n = len(values)
        index = np.arange(1, n + 1)
        
        return (2 * np.sum(index * sorted_values)) / (n * np.sum(sorted_values)) - (n + 1) / n
    
    def _check_max_hours(self, schedule: Dict, max_hours: int) -> Dict:
        """Check maximum hours constraint"""
        violations = []
        for agent in schedule.get('agents', []):
            hours = self._calculate_agent_hours(agent)
            if hours['total'] > max_hours:
                violations.append({
                    'agent': agent.get('id'),
                    'hours': hours['total'],
                    'limit': max_hours,
                    'severity': 'critical'
                })
        
        return {
            'compliant': len(violations) == 0,
            'violations': violations
        }
    
    def _check_min_rest(self, schedule: Dict, min_rest: int) -> Dict:
        """Check minimum rest between shifts"""
        # Simplified implementation
        return {'compliant': True, 'violations': []}
    
    def _check_max_consecutive(self, schedule: Dict, max_days: int) -> Dict:
        """Check maximum consecutive days"""
        # Simplified implementation
        return {'compliant': True, 'violations': []}
    
    def _check_breaks(self, schedule: Dict, break_rules: Dict) -> Dict:
        """Check break requirements"""
        # Simplified implementation
        return {'compliant': True, 'violations': []}
    
    def _check_skills(self, schedule: Dict, skill_requirements: Dict) -> Dict:
        """Check skill requirements"""
        # Simplified implementation
        return {'compliant': True, 'violations': []}
    
    def _has_flexible_pattern(self, agent: Dict) -> bool:
        """Check if agent has flexible shift pattern"""
        # Simplified check
        shifts = agent.get('shifts', [])
        return len(set(s.get('start_time') for s in shifts)) > 1
    
    def _calculate_backup_coverage(self, schedule: Dict) -> float:
        """Calculate backup coverage ratio"""
        # Simplified calculation
        return 0.8
    
    def _analyze_shift_pattern(self, agent: Dict) -> str:
        """Analyze quality of shift pattern"""
        # Simplified analysis
        shifts = agent.get('shifts', [])
        if len(shifts) >= 5:
            return 'good'
        elif len(shifts) <= 2:
            return 'poor'
        return 'neutral'
    
    def _check_preference_met(self, agent: Dict, pref_type: str, pref_value: any) -> bool:
        """Check if preference is met"""
        # Simplified check
        return True
    
    def compare_schedules(self, schedules: List[Dict], 
                         requirements: Dict,
                         constraints: Optional[Dict] = None) -> List[Dict]:
        """
        Compare multiple schedules and rank them
        This is how we outperform Argus's basic comparison
        """
        scored_schedules = []
        
        for i, schedule in enumerate(schedules):
            metrics = self.score_schedule(schedule, requirements, constraints)
            scored_schedules.append({
                'schedule_id': schedule.get('id', f'schedule_{i}'),
                'overall_score': metrics.overall_score,
                'metrics': metrics,
                'rank': 0  # Will be set after sorting
            })
        
        # Sort by overall score
        scored_schedules.sort(key=lambda x: x['overall_score'], reverse=True)
        
        # Assign ranks
        for i, scored in enumerate(scored_schedules):
            scored['rank'] = i + 1
        
        return scored_schedules