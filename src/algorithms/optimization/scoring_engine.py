#!/usr/bin/env python3
"""
Scoring Engine - BDD Implementation
From: 24-automatic-schedule-optimization.feature:55
"Scoring Engine | Multi-criteria decision | All metrics | Ranked suggestions | 1-2 seconds"
"""

from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum
import logging
import numpy as np

logger = logging.getLogger(__name__)

class ScoringCriteria(Enum):
    """Multi-criteria scoring components"""
    COVERAGE_OPTIMIZATION = "coverage_optimization"
    COST_EFFICIENCY = "cost_efficiency"
    COMPLIANCE_PREFERENCES = "compliance_preferences"
    IMPLEMENTATION_SIMPLICITY = "implementation_simplicity"

@dataclass
class ScoreBreakdown:
    """Detailed scoring breakdown per BDD specification"""
    coverage_score: float
    cost_score: float
    compliance_score: float
    simplicity_score: float
    total_score: float
    weighted_scores: Dict[ScoringCriteria, float]
    sub_component_scores: Dict[str, float]

@dataclass
class OptimizationScore:
    """Complete optimization score for schedule variant"""
    variant_id: str
    overall_score: float
    score_breakdown: ScoreBreakdown
    ranking_position: int
    recommendation_level: str
    risk_assessment: str
    implementation_timeline: str
    expected_outcomes: Dict[str, float]

@dataclass
class RankedSuggestion:
    """Ranked schedule suggestion with comprehensive scoring"""
    suggestions: List[OptimizationScore]
    scoring_methodology: Dict[str, Any]
    comparison_matrix: Dict[str, Dict[str, float]]
    recommendation_summary: Dict[str, Any]
    processing_time_ms: float

class ScoringEngine:
    """
    Multi-criteria decision analysis scoring system
    BDD Requirement: All metrics → Ranked suggestions
    """
    
    def __init__(self):
        # BDD Requirements: Optimization weights (lines 64-68)
        self.scoring_weights = {
            ScoringCriteria.COVERAGE_OPTIMIZATION: 0.40,      # 40% weight
            ScoringCriteria.COST_EFFICIENCY: 0.30,           # 30% weight
            ScoringCriteria.COMPLIANCE_PREFERENCES: 0.20,     # 20% weight
            ScoringCriteria.IMPLEMENTATION_SIMPLICITY: 0.10   # 10% weight
        }
        
        # Sub-component weights (BDD lines 122-133)
        self.sub_weights = {
            'gap_reduction': 0.375,          # 15/40 of coverage weight
            'peak_coverage': 0.320,          # 12.8/40 of coverage weight
            'skill_match': 0.238,            # 9.5/40 of coverage weight
            'overtime_reduction': 0.373,     # 11.2/30 of cost weight
            'labor_compliance': 0.500,       # 10/20 of compliance weight
            'employee_preferences': 0.340,   # 6.8/20 of compliance weight
            'pattern_regularity': 0.860      # 8.6/10 of simplicity weight
        }
        
        # BDD target processing time: 1-2 seconds
        self.processing_target = 2.0
        
    def score_schedule_suggestions(self,
                                 schedule_variants: List[Dict[str, Any]],
                                 gap_analysis: Dict[str, Any],
                                 cost_analysis: Dict[str, Any],
                                 compliance_matrix: Dict[str, Any],
                                 target_improvements: Dict[str, float]) -> RankedSuggestion:
        """
        Main scoring engine per BDD specification
        Input: All metrics from optimization components
        Output: Ranked suggestions
        Processing: 1-2 seconds (BDD requirement)
        """
        start_time = datetime.now()
        
        # Step 1: Score each variant
        optimization_scores = []
        for variant in schedule_variants:
            score = self._score_individual_variant(
                variant, gap_analysis, cost_analysis, compliance_matrix, target_improvements
            )
            optimization_scores.append(score)
        
        # Step 2: Rank suggestions by score
        optimization_scores.sort(key=lambda x: x.overall_score, reverse=True)
        
        # Step 3: Assign ranking positions
        for i, score in enumerate(optimization_scores):
            score.ranking_position = i + 1
        
        # Step 4: Create comparison matrix
        comparison_matrix = self._create_comparison_matrix(optimization_scores)
        
        # Step 5: Generate methodology explanation
        scoring_methodology = self._generate_scoring_methodology()
        
        # Step 6: Create recommendation summary
        recommendation_summary = self._generate_recommendation_summary(optimization_scores)
        
        # Processing time validation
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return RankedSuggestion(
            suggestions=optimization_scores,
            scoring_methodology=scoring_methodology,
            comparison_matrix=comparison_matrix,
            recommendation_summary=recommendation_summary,
            processing_time_ms=processing_time
        )
    
    def _score_individual_variant(self,
                                variant: Dict[str, Any],
                                gap_analysis: Dict[str, Any],
                                cost_analysis: Dict[str, Any],
                                compliance_matrix: Dict[str, Any],
                                target_improvements: Dict[str, float]) -> OptimizationScore:
        """Score individual schedule variant using multi-criteria analysis"""
        
        # Calculate component scores
        coverage_score = self._score_coverage_optimization(variant, gap_analysis, target_improvements)
        cost_score = self._score_cost_efficiency(variant, cost_analysis, target_improvements)
        compliance_score = self._score_compliance_preferences(variant, compliance_matrix)
        simplicity_score = self._score_implementation_simplicity(variant)
        
        # Calculate weighted scores
        weighted_scores = {
            ScoringCriteria.COVERAGE_OPTIMIZATION: coverage_score * self.scoring_weights[ScoringCriteria.COVERAGE_OPTIMIZATION],
            ScoringCriteria.COST_EFFICIENCY: cost_score * self.scoring_weights[ScoringCriteria.COST_EFFICIENCY],
            ScoringCriteria.COMPLIANCE_PREFERENCES: compliance_score * self.scoring_weights[ScoringCriteria.COMPLIANCE_PREFERENCES],
            ScoringCriteria.IMPLEMENTATION_SIMPLICITY: simplicity_score * self.scoring_weights[ScoringCriteria.IMPLEMENTATION_SIMPLICITY]
        }
        
        # Calculate total score
        total_score = sum(weighted_scores.values())
        
        # Calculate sub-component scores
        sub_component_scores = self._calculate_sub_component_scores(
            variant, gap_analysis, cost_analysis, compliance_matrix
        )
        
        # Create score breakdown
        score_breakdown = ScoreBreakdown(
            coverage_score=coverage_score,
            cost_score=cost_score,
            compliance_score=compliance_score,
            simplicity_score=simplicity_score,
            total_score=total_score,
            weighted_scores=weighted_scores,
            sub_component_scores=sub_component_scores
        )
        
        # Assess risk and implementation
        risk_assessment = self._assess_implementation_risk(total_score, compliance_score)
        implementation_timeline = self._estimate_implementation_timeline(simplicity_score, compliance_score)
        recommendation_level = self._determine_recommendation_level(total_score, risk_assessment)
        
        # Calculate expected outcomes
        expected_outcomes = self._calculate_expected_outcomes(variant, target_improvements)
        
        return OptimizationScore(
            variant_id=variant.get('variant_id', 'UNKNOWN'),
            overall_score=total_score,
            score_breakdown=score_breakdown,
            ranking_position=0,  # Will be set during ranking
            recommendation_level=recommendation_level,
            risk_assessment=risk_assessment,
            implementation_timeline=implementation_timeline,
            expected_outcomes=expected_outcomes
        )
    
    def _score_coverage_optimization(self,
                                   variant: Dict[str, Any],
                                   gap_analysis: Dict[str, Any],
                                   target_improvements: Dict[str, float]) -> float:
        """Score coverage optimization (40% weight per BDD line 65)"""
        
        # Gap reduction score (BDD line 128)
        current_gaps = gap_analysis.get('total_gaps', 0)
        projected_gaps = variant.get('projected_gaps', current_gaps)
        gap_reduction = max(0, (current_gaps - projected_gaps) / current_gaps) if current_gaps > 0 else 0
        gap_reduction_score = min(100, gap_reduction * 100 * 5)  # Scale to 15 points max
        
        # Peak coverage score (BDD line 129)
        peak_periods = gap_analysis.get('peak_periods', [])
        covered_peaks = 0
        for period in peak_periods:
            if self._is_period_covered(variant, period):
                covered_peaks += 1
        
        peak_coverage_ratio = covered_peaks / len(peak_periods) if peak_periods else 1.0
        peak_coverage_score = peak_coverage_ratio * 15  # Scale to 15 points max
        
        # Skill match score (BDD line 130)
        skill_requirements = variant.get('required_skills', [])
        available_skills = variant.get('available_skills', [])
        skill_match_ratio = len(set(skill_requirements) & set(available_skills)) / len(skill_requirements) if skill_requirements else 1.0
        skill_match_score = skill_match_ratio * 10  # Scale to 10 points max
        
        # Total coverage score (out of 40 points)
        total_coverage = gap_reduction_score + peak_coverage_score + skill_match_score
        
        return min(40.0, total_coverage)
    
    def _score_cost_efficiency(self,
                             variant: Dict[str, Any],
                             cost_analysis: Dict[str, Any],
                             target_improvements: Dict[str, float]) -> float:
        """Score cost efficiency (30% weight per BDD line 66)"""
        
        # Overtime reduction score (BDD line 131)
        current_overtime = cost_analysis.get('current_overtime_cost', 1000)
        projected_overtime = variant.get('projected_overtime_cost', current_overtime)
        overtime_reduction = max(0, (current_overtime - projected_overtime) / current_overtime) if current_overtime > 0 else 0
        overtime_reduction_score = overtime_reduction * 12  # Scale to 12 points max
        
        # Cost efficiency score
        current_cost = cost_analysis.get('current_weekly_cost', 10000)
        projected_cost = variant.get('projected_weekly_cost', current_cost)
        cost_reduction = max(0, (current_cost - projected_cost) / current_cost) if current_cost > 0 else 0
        cost_efficiency_score = cost_reduction * 18  # Scale to 18 points max
        
        # Total cost score (out of 30 points)
        total_cost = overtime_reduction_score + cost_efficiency_score
        
        return min(30.0, total_cost)
    
    def _score_compliance_preferences(self,
                                    variant: Dict[str, Any],
                                    compliance_matrix: Dict[str, Any]) -> float:
        """Score compliance and preferences (20% weight per BDD line 67)"""
        
        # Labor law compliance score (BDD line 132)
        compliance_score_raw = compliance_matrix.get('compliance_score', 100)
        labor_compliance_score = compliance_score_raw / 100 * 10  # Scale to 10 points max
        
        # Employee preferences score (BDD line 133)
        total_employees = len(variant.get('schedule_blocks', []))
        preferences_met = 0
        
        for block in variant.get('schedule_blocks', []):
            preferred_shifts = block.get('preferred_shifts', [])
            assigned_shift = f"{block.get('start_time', '08:00')}-{block.get('end_time', '16:00')}"
            if not preferred_shifts or assigned_shift in preferred_shifts:
                preferences_met += 1
        
        preference_ratio = preferences_met / total_employees if total_employees > 0 else 1.0
        preference_score = preference_ratio * 10  # Scale to 10 points max
        
        # Total compliance score (out of 20 points)
        total_compliance = labor_compliance_score + preference_score
        
        return min(20.0, total_compliance)
    
    def _score_implementation_simplicity(self, variant: Dict[str, Any]) -> float:
        """Score implementation simplicity (10% weight per BDD line 68)"""
        
        # Pattern regularity score
        pattern_type = variant.get('pattern_type', 'traditional')
        
        # Complexity factors
        complexity_factors = {
            'traditional': 10.0,      # Simplest
            'flexible': 8.0,
            'staggered': 7.0,
            'compressed': 6.0,
            'part_time': 7.5,
            'split_shift': 4.0,       # Most complex
            'peak_focus': 6.5,
            'weekend_focus': 5.5
        }
        
        base_simplicity = complexity_factors.get(pattern_type, 5.0)
        
        # Adjust for special features
        schedule_blocks = variant.get('schedule_blocks', [])
        complexity_penalty = 0
        
        for block in schedule_blocks:
            if block.get('overlap_shift'):
                complexity_penalty += 0.5
            if block.get('split_shift'):
                complexity_penalty += 1.0
            if block.get('compressed_schedule'):
                complexity_penalty += 0.5
        
        final_simplicity = max(0, base_simplicity - complexity_penalty)
        
        return min(10.0, final_simplicity)
    
    def _calculate_sub_component_scores(self,
                                      variant: Dict[str, Any],
                                      gap_analysis: Dict[str, Any],
                                      cost_analysis: Dict[str, Any],
                                      compliance_matrix: Dict[str, Any]) -> Dict[str, float]:
        """Calculate detailed sub-component scores per BDD lines 127-133"""
        
        # Extract basic metrics
        current_gaps = gap_analysis.get('total_gaps', 0)
        projected_gaps = variant.get('projected_gaps', current_gaps)
        
        current_overtime = cost_analysis.get('current_overtime_cost', 1000)
        projected_overtime = variant.get('projected_overtime_cost', current_overtime)
        
        return {
            'gap_reduction': ((current_gaps - projected_gaps) / current_gaps * 100) if current_gaps > 0 else 0,
            'peak_coverage': variant.get('peak_coverage_percentage', 85.0),
            'skill_match': variant.get('skill_match_percentage', 95.0),
            'overtime_reduction': ((current_overtime - projected_overtime) / current_overtime * 100) if current_overtime > 0 else 0,
            'labor_compliance': compliance_matrix.get('compliance_score', 100),
            'employee_preferences': variant.get('preference_satisfaction', 68.0),
            'pattern_regularity': variant.get('pattern_simplicity_score', 86.0)
        }
    
    def _is_period_covered(self, variant: Dict[str, Any], period: str) -> bool:
        """Check if a specific time period is covered by the variant"""
        # Simplified coverage check
        schedule_blocks = variant.get('schedule_blocks', [])
        
        # Parse period (assuming format like "10:00")
        period_hour = int(period.split(':')[0])
        
        for block in schedule_blocks:
            start_hour = int(block.get('start_time', '08:00').split(':')[0])
            end_hour = int(block.get('end_time', '16:00').split(':')[0])
            
            if start_hour <= period_hour < end_hour:
                return True
        
        return False
    
    def _assess_implementation_risk(self, total_score: float, compliance_score: float) -> str:
        """Assess implementation risk level"""
        if compliance_score < 15:  # Critical compliance issues
            return "High"
        elif total_score >= 90:
            return "Low"
        elif total_score >= 75:
            return "Medium"
        else:
            return "High"
    
    def _estimate_implementation_timeline(self, simplicity_score: float, compliance_score: float) -> str:
        """Estimate implementation timeline"""
        if compliance_score < 15:
            return "4-6 weeks"  # Need compliance fixes
        elif simplicity_score >= 8:
            return "1-2 weeks"  # Simple implementation
        elif simplicity_score >= 6:
            return "2-3 weeks"  # Medium complexity
        else:
            return "3-4 weeks"  # Complex implementation
    
    def _determine_recommendation_level(self, total_score: float, risk_assessment: str) -> str:
        """Determine recommendation level per BDD lines 136-138"""
        if total_score >= 90 and risk_assessment == "Low":
            return "Implement"      # High acceptance likelihood
        elif total_score >= 75:
            return "Monitor"        # Medium risk factors
        else:
            return "Plan accordingly"  # Implementation timeline needed
    
    def _calculate_expected_outcomes(self,
                                   variant: Dict[str, Any],
                                   target_improvements: Dict[str, float]) -> Dict[str, float]:
        """Calculate expected outcomes from implementation"""
        return {
            'coverage_improvement': variant.get('coverage_improvement', 15.0),
            'cost_savings': variant.get('cost_savings', 10.0),
            'service_level_improvement': variant.get('service_level_improvement', 5.0),
            'employee_satisfaction': variant.get('employee_satisfaction', 68.0),
            'implementation_confidence': variant.get('implementation_confidence', 85.0)
        }
    
    def _create_comparison_matrix(self, 
                                optimization_scores: List[OptimizationScore]) -> Dict[str, Dict[str, float]]:
        """Create comparison matrix between top suggestions"""
        if len(optimization_scores) < 2:
            return {}
        
        # Take top 3 suggestions for comparison
        top_suggestions = optimization_scores[:3]
        comparison_matrix = {}
        
        for i, suggestion in enumerate(top_suggestions):
            comparison_matrix[f"Suggestion_{i+1}"] = {
                'overall_score': suggestion.overall_score,
                'coverage_score': suggestion.score_breakdown.coverage_score,
                'cost_score': suggestion.score_breakdown.cost_score,
                'compliance_score': suggestion.score_breakdown.compliance_score,
                'simplicity_score': suggestion.score_breakdown.simplicity_score,
                'risk_level': suggestion.risk_assessment,
                'implementation_weeks': self._parse_timeline_weeks(suggestion.implementation_timeline)
            }
        
        return comparison_matrix
    
    def _parse_timeline_weeks(self, timeline: str) -> float:
        """Parse timeline string to weeks"""
        # Extract first number from timeline string
        import re
        match = re.search(r'(\d+)', timeline)
        return float(match.group(1)) if match else 3.0
    
    def _generate_scoring_methodology(self) -> Dict[str, Any]:
        """Generate explanation of scoring methodology per BDD lines 122-125"""
        return {
            'component_weights': {
                'coverage_optimization': f"{self.scoring_weights[ScoringCriteria.COVERAGE_OPTIMIZATION]:.0%}",
                'cost_efficiency': f"{self.scoring_weights[ScoringCriteria.COST_EFFICIENCY]:.0%}",
                'compliance_preferences': f"{self.scoring_weights[ScoringCriteria.COMPLIANCE_PREFERENCES]:.0%}",
                'implementation_simplicity': f"{self.scoring_weights[ScoringCriteria.IMPLEMENTATION_SIMPLICITY]:.0%}"
            },
            'scoring_scale': '0-100 points',
            'calculation_method': 'Weighted multi-criteria decision analysis',
            'sub_components': {
                'gap_reduction': 'Coverage gap reduction percentage',
                'peak_coverage': 'Peak period coverage improvement',
                'skill_match': 'Required vs available skill alignment',
                'overtime_reduction': 'Overtime cost reduction percentage',
                'labor_compliance': 'Labor law compliance score',
                'employee_preferences': 'Employee preference satisfaction rate'
            }
        }
    
    def _generate_recommendation_summary(self, 
                                       optimization_scores: List[OptimizationScore]) -> Dict[str, Any]:
        """Generate recommendation summary for decision makers"""
        if not optimization_scores:
            return {}
        
        top_suggestion = optimization_scores[0]
        
        return {
            'top_recommendation': {
                'variant_id': top_suggestion.variant_id,
                'score': top_suggestion.overall_score,
                'recommendation': top_suggestion.recommendation_level,
                'risk': top_suggestion.risk_assessment,
                'timeline': top_suggestion.implementation_timeline
            },
            'score_distribution': {
                'excellent': len([s for s in optimization_scores if s.overall_score >= 90]),
                'good': len([s for s in optimization_scores if 75 <= s.overall_score < 90]),
                'acceptable': len([s for s in optimization_scores if 60 <= s.overall_score < 75]),
                'poor': len([s for s in optimization_scores if s.overall_score < 60])
            },
            'implementation_readiness': {
                'low_risk': len([s for s in optimization_scores if s.risk_assessment == "Low"]),
                'medium_risk': len([s for s in optimization_scores if s.risk_assessment == "Medium"]),
                'high_risk': len([s for s in optimization_scores if s.risk_assessment == "High"])
            },
            'average_metrics': {
                'coverage_score': np.mean([s.score_breakdown.coverage_score for s in optimization_scores]),
                'cost_score': np.mean([s.score_breakdown.cost_score for s in optimization_scores]),
                'compliance_score': np.mean([s.score_breakdown.compliance_score for s in optimization_scores]),
                'simplicity_score': np.mean([s.score_breakdown.simplicity_score for s in optimization_scores])
            }
        }
    
    def validate_bdd_requirements(self, result: RankedSuggestion) -> Dict[str, bool]:
        """Validate against BDD requirements"""
        validation = {}
        
        # Processing time: 1-2 seconds
        validation['processing_time'] = result.processing_time_ms <= 2000
        
        # Ranked suggestions generated
        validation['ranked_suggestions'] = len(result.suggestions) > 0
        
        # Multi-criteria scoring applied
        validation['multi_criteria_scoring'] = len(result.scoring_methodology) > 0
        
        # Score breakdown available
        if result.suggestions:
            first_suggestion = result.suggestions[0]
            validation['score_breakdown'] = hasattr(first_suggestion, 'score_breakdown')
            validation['component_scores'] = len(first_suggestion.score_breakdown.weighted_scores) == 4
        
        # Comparison matrix generated
        validation['comparison_matrix'] = len(result.comparison_matrix) > 0
        
        # Recommendation summary provided
        validation['recommendation_summary'] = len(result.recommendation_summary) > 0
        
        return validation