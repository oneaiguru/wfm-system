#!/usr/bin/env python3
"""
Scoring Engine - BDD Implementation
From: 24-automatic-schedule-optimization.feature:55
"Scoring Engine | Multi-criteria decision | All metrics | Ranked suggestions | 1-2 seconds"
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Any
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import time
import logging

logger = logging.getLogger(__name__)

class ScoringCriteria(Enum):
    """Scoring criteria types"""
    COVERAGE_OPTIMIZATION = "coverage_optimization"
    COST_EFFICIENCY = "cost_efficiency"
    COMPLIANCE_PREFERENCES = "compliance_preferences"
    IMPLEMENTATION_SIMPLICITY = "implementation_simplicity"

class ScoreComponent(Enum):
    """Individual score components"""
    GAP_REDUCTION = "gap_reduction"
    PEAK_COVERAGE = "peak_coverage"
    SKILL_MATCH = "skill_match"
    OVERTIME_REDUCTION = "overtime_reduction"
    LABOR_LAW_COMPLIANCE = "labor_law_compliance"
    EMPLOYEE_PREFERENCES = "employee_preferences"
    PATTERN_REGULARITY = "pattern_regularity"
    IMPLEMENTATION_EASE = "implementation_ease"

@dataclass
class ScoreBreakdown:
    """Detailed score breakdown for transparency"""
    component: ScoreComponent
    weight: float
    points_earned: float
    max_points: float
    calculation_method: str
    explanation: str

@dataclass
class ScoringResult:
    """Individual suggestion scoring result"""
    suggestion_id: str
    total_score: float
    coverage_score: float
    cost_score: float
    compliance_score: float
    implementation_score: float
    score_breakdown: List[ScoreBreakdown]
    ranking_position: int
    recommendation_level: str

@dataclass
class RankedSuggestions:
    """Complete ranked suggestions output"""
    suggestions: List[ScoringResult]
    total_evaluated: int
    scoring_methodology: Dict[str, Any]
    processing_time_ms: float
    confidence_level: float
    recommendation_summary: str

class ScoringEngine:
    """
    Multi-Criteria Decision Scoring Engine
    BDD Requirement: All metrics → Ranked suggestions (1-2 seconds)
    """
    
    def __init__(self):
        # Scoring weights per BDD specifications
        self.scoring_weights = {
            ScoringCriteria.COVERAGE_OPTIMIZATION: 40.0,  # 40% weight
            ScoringCriteria.COST_EFFICIENCY: 30.0,        # 30% weight
            ScoringCriteria.COMPLIANCE_PREFERENCES: 20.0,  # 20% weight
            ScoringCriteria.IMPLEMENTATION_SIMPLICITY: 10.0 # 10% weight
        }
        
        # Component weights within each criteria
        self.component_weights = {
            # Coverage Optimization (40%)
            ScoreComponent.GAP_REDUCTION: 15.0,
            ScoreComponent.PEAK_COVERAGE: 15.0,
            ScoreComponent.SKILL_MATCH: 10.0,
            
            # Cost Efficiency (30%)
            ScoreComponent.OVERTIME_REDUCTION: 12.0,
            
            # Compliance & Preferences (20%)
            ScoreComponent.LABOR_LAW_COMPLIANCE: 10.0,
            ScoreComponent.EMPLOYEE_PREFERENCES: 10.0,
            
            # Implementation Simplicity (10%)
            ScoreComponent.PATTERN_REGULARITY: 5.0,
            ScoreComponent.IMPLEMENTATION_EASE: 5.0
        }
        
        # BDD processing time target: 1-2 seconds
        self.max_processing_time = 2.0
    
    def score_and_rank_suggestions(self,
                                 suggestions: List[Dict[str, Any]],
                                 all_metrics: Dict[str, Any],
                                 scoring_criteria: Optional[Dict] = None) -> RankedSuggestions:
        """
        Main scoring engine per BDD specification
        Input: All metrics
        Output: Ranked suggestions
        Processing: 1-2 seconds (BDD requirement)
        """
        start_time = time.time()
        
        # Step 1: Initialize scoring methodology
        methodology = self._initialize_scoring_methodology(scoring_criteria)
        
        # Step 2: Score each suggestion
        scored_suggestions = []
        for i, suggestion in enumerate(suggestions):
            score_result = self._score_individual_suggestion(
                suggestion_id=f"SUGGESTION_{i+1:03d}",
                suggestion_data=suggestion,
                all_metrics=all_metrics,
                methodology=methodology
            )
            scored_suggestions.append(score_result)
        
        # Step 3: Rank suggestions by total score
        ranked_suggestions = sorted(
            scored_suggestions, 
            key=lambda x: x.total_score, 
            reverse=True
        )
        
        # Step 4: Assign ranking positions and recommendation levels
        for rank, suggestion in enumerate(ranked_suggestions, 1):
            suggestion.ranking_position = rank
            suggestion.recommendation_level = self._determine_recommendation_level(
                suggestion.total_score, rank
            )
        
        # Step 5: Calculate confidence and generate summary
        confidence_level = self._calculate_confidence_level(ranked_suggestions)
        recommendation_summary = self._generate_recommendation_summary(ranked_suggestions)
        
        processing_time = (time.time() - start_time) * 1000
        
        return RankedSuggestions(
            suggestions=ranked_suggestions,
            total_evaluated=len(suggestions),
            scoring_methodology=methodology,
            processing_time_ms=processing_time,
            confidence_level=confidence_level,
            recommendation_summary=recommendation_summary
        )
    
    def _initialize_scoring_methodology(self, custom_criteria: Optional[Dict]) -> Dict[str, Any]:
        """Initialize scoring methodology with custom overrides"""
        methodology = {
            'weights': self.scoring_weights.copy(),
            'component_weights': self.component_weights.copy(),
            'max_score': 100.0,
            'scoring_version': 'BDD_v1.0'
        }
        
        # Apply custom criteria if provided
        if custom_criteria:
            if 'coverage_weight' in custom_criteria:
                methodology['weights'][ScoringCriteria.COVERAGE_OPTIMIZATION] = custom_criteria['coverage_weight']
            if 'cost_weight' in custom_criteria:
                methodology['weights'][ScoringCriteria.COST_EFFICIENCY] = custom_criteria['cost_weight']
            # Normalize weights to 100%
            total_weight = sum(methodology['weights'].values())
            if total_weight != 100.0:
                for criteria in methodology['weights']:
                    methodology['weights'][criteria] = (methodology['weights'][criteria] / total_weight) * 100.0
        
        return methodology
    
    def _score_individual_suggestion(self,
                                   suggestion_id: str,
                                   suggestion_data: Dict[str, Any],
                                   all_metrics: Dict[str, Any],
                                   methodology: Dict[str, Any]) -> ScoringResult:
        """Score an individual suggestion using multi-criteria analysis"""
        
        # Extract metrics for scoring
        current_metrics = all_metrics.get('current_state', {})
        projected_metrics = suggestion_data.get('projected_metrics', {})
        
        # Score each component
        score_breakdown = []
        
        # Coverage Optimization Components
        gap_reduction_score = self._score_gap_reduction(
            current_metrics, projected_metrics, methodology
        )
        score_breakdown.append(gap_reduction_score)
        
        peak_coverage_score = self._score_peak_coverage(
            current_metrics, projected_metrics, methodology
        )
        score_breakdown.append(peak_coverage_score)
        
        skill_match_score = self._score_skill_match(
            suggestion_data, all_metrics, methodology
        )
        score_breakdown.append(skill_match_score)
        
        # Cost Efficiency Components
        overtime_reduction_score = self._score_overtime_reduction(
            current_metrics, projected_metrics, methodology
        )
        score_breakdown.append(overtime_reduction_score)
        
        # Compliance & Preferences Components
        compliance_score = self._score_labor_law_compliance(
            suggestion_data, all_metrics, methodology
        )
        score_breakdown.append(compliance_score)
        
        preferences_score = self._score_employee_preferences(
            suggestion_data, all_metrics, methodology
        )
        score_breakdown.append(preferences_score)
        
        # Implementation Simplicity Components
        pattern_score = self._score_pattern_regularity(
            suggestion_data, methodology
        )
        score_breakdown.append(pattern_score)
        
        ease_score = self._score_implementation_ease(
            suggestion_data, methodology
        )
        score_breakdown.append(ease_score)
        
        # Calculate category scores
        coverage_score = sum(s.points_earned for s in score_breakdown 
                           if s.component in [ScoreComponent.GAP_REDUCTION, 
                                            ScoreComponent.PEAK_COVERAGE, 
                                            ScoreComponent.SKILL_MATCH])
        
        cost_score = sum(s.points_earned for s in score_breakdown 
                        if s.component == ScoreComponent.OVERTIME_REDUCTION) * 2.5  # Scale to 30%
        
        compliance_score_total = sum(s.points_earned for s in score_breakdown 
                                   if s.component in [ScoreComponent.LABOR_LAW_COMPLIANCE,
                                                    ScoreComponent.EMPLOYEE_PREFERENCES])
        
        implementation_score = sum(s.points_earned for s in score_breakdown 
                                 if s.component in [ScoreComponent.PATTERN_REGULARITY,
                                                  ScoreComponent.IMPLEMENTATION_EASE])
        
        # Calculate total score
        total_score = sum(s.points_earned for s in score_breakdown)
        
        return ScoringResult(
            suggestion_id=suggestion_id,
            total_score=total_score,
            coverage_score=coverage_score,
            cost_score=cost_score,
            compliance_score=compliance_score_total,
            implementation_score=implementation_score,
            score_breakdown=score_breakdown,
            ranking_position=0,  # Will be set during ranking
            recommendation_level=""  # Will be set during ranking
        )
    
    def _score_gap_reduction(self, current: Dict, projected: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score gap reduction improvement"""
        current_gaps = current.get('coverage_gaps', 50)
        projected_gaps = projected.get('coverage_gaps', 40)
        
        if current_gaps > 0:
            reduction_percent = ((current_gaps - projected_gaps) / current_gaps) * 100
        else:
            reduction_percent = 0
        
        # Score: 15 points max, proportional to reduction
        max_points = 15.0
        points_earned = min(max_points, (reduction_percent / 75.0) * max_points)  # 75% reduction = full points
        
        return ScoreBreakdown(
            component=ScoreComponent.GAP_REDUCTION,
            weight=15.0,
            points_earned=max(0, points_earned),
            max_points=max_points,
            calculation_method="(Current gaps - Projected gaps) / Current gaps",
            explanation=f"{reduction_percent:.1f}% reduction in coverage gaps"
        )
    
    def _score_peak_coverage(self, current: Dict, projected: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score peak period coverage improvement"""
        current_peak = current.get('peak_coverage', 70)
        projected_peak = projected.get('peak_coverage', 85)
        
        improvement = projected_peak - current_peak
        
        # Score: 15 points max, target 85% coverage
        max_points = 15.0
        if projected_peak >= 85:
            points_earned = max_points
        else:
            points_earned = (projected_peak / 85.0) * max_points
        
        return ScoreBreakdown(
            component=ScoreComponent.PEAK_COVERAGE,
            weight=15.0,
            points_earned=max(0, points_earned),
            max_points=max_points,
            calculation_method="Peak period coverage improvement",
            explanation=f"{projected_peak:.1f}% of peak periods covered (+{improvement:.1f}%)"
        )
    
    def _score_skill_match(self, suggestion: Dict, all_metrics: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score skill requirements alignment"""
        required_skills = all_metrics.get('required_skills', [])
        available_skills = suggestion.get('skill_coverage', [])
        
        if not required_skills:
            match_percent = 100
        else:
            matched_skills = len(set(required_skills) & set(available_skills))
            match_percent = (matched_skills / len(required_skills)) * 100
        
        # Score: 10 points max
        max_points = 10.0
        points_earned = (match_percent / 100.0) * max_points
        
        return ScoreBreakdown(
            component=ScoreComponent.SKILL_MATCH,
            weight=10.0,
            points_earned=points_earned,
            max_points=max_points,
            calculation_method="Required vs available skill alignment",
            explanation=f"{match_percent:.1f}% skill requirements met"
        )
    
    def _score_overtime_reduction(self, current: Dict, projected: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score overtime cost reduction"""
        current_overtime = current.get('overtime_hours', 100)
        projected_overtime = projected.get('overtime_hours', 60)
        
        if current_overtime > 0:
            reduction_percent = ((current_overtime - projected_overtime) / current_overtime) * 100
        else:
            reduction_percent = 0
        
        # Score: 12 points max (30% of total via 2.5x multiplier)
        max_points = 12.0
        points_earned = min(max_points, (reduction_percent / 66.0) * max_points)  # 66% reduction = full points
        
        return ScoreBreakdown(
            component=ScoreComponent.OVERTIME_REDUCTION,
            weight=12.0,
            points_earned=max(0, points_earned),
            max_points=max_points,
            calculation_method="(Current OT - Projected OT) / Current OT",
            explanation=f"{reduction_percent:.1f}% overtime reduction"
        )
    
    def _score_labor_law_compliance(self, suggestion: Dict, all_metrics: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score labor law compliance"""
        compliance_violations = suggestion.get('compliance_violations', 0)
        
        # Score: 10 points max, lose points for violations
        max_points = 10.0
        if compliance_violations == 0:
            points_earned = max_points
        else:
            # Lose 2 points per violation, minimum 0
            points_earned = max(0, max_points - (compliance_violations * 2))
        
        return ScoreBreakdown(
            component=ScoreComponent.LABOR_LAW_COMPLIANCE,
            weight=10.0,
            points_earned=points_earned,
            max_points=max_points,
            calculation_method="Compliance check results",
            explanation=f"{'100% compliant' if compliance_violations == 0 else f'{compliance_violations} violations found'}"
        )
    
    def _score_employee_preferences(self, suggestion: Dict, all_metrics: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score employee preference matching"""
        preference_match = suggestion.get('preference_match_rate', 70)
        
        # Score: 10 points max
        max_points = 10.0
        points_earned = (preference_match / 100.0) * max_points
        
        return ScoreBreakdown(
            component=ScoreComponent.EMPLOYEE_PREFERENCES,
            weight=10.0,
            points_earned=points_earned,
            max_points=max_points,
            calculation_method="Preference matching rate",
            explanation=f"{preference_match:.1f}% preferences accommodated"
        )
    
    def _score_pattern_regularity(self, suggestion: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score pattern regularity for implementation ease"""
        pattern_complexity = suggestion.get('pattern_complexity', 'medium')
        
        # Score: 5 points max
        max_points = 5.0
        complexity_scores = {
            'simple': 5.0,
            'medium': 3.0,
            'complex': 1.0
        }
        points_earned = complexity_scores.get(pattern_complexity, 3.0)
        
        return ScoreBreakdown(
            component=ScoreComponent.PATTERN_REGULARITY,
            weight=5.0,
            points_earned=points_earned,
            max_points=max_points,
            calculation_method="Pattern regularity assessment",
            explanation=f"{pattern_complexity.title()} pattern complexity"
        )
    
    def _score_implementation_ease(self, suggestion: Dict, methodology: Dict) -> ScoreBreakdown:
        """Score implementation ease"""
        implementation_timeline = suggestion.get('implementation_weeks', 3)
        
        # Score: 5 points max, fewer weeks = higher score
        max_points = 5.0
        if implementation_timeline <= 1:
            points_earned = 5.0
        elif implementation_timeline <= 2:
            points_earned = 4.0
        elif implementation_timeline <= 3:
            points_earned = 3.0
        else:
            points_earned = max(0, 5 - implementation_timeline)
        
        return ScoreBreakdown(
            component=ScoreComponent.IMPLEMENTATION_EASE,
            weight=5.0,
            points_earned=points_earned,
            max_points=max_points,
            calculation_method="Implementation timeline assessment",
            explanation=f"{implementation_timeline} week implementation timeline"
        )
    
    def _determine_recommendation_level(self, total_score: float, rank: int) -> str:
        """Determine recommendation level based on score and rank"""
        if rank == 1 and total_score >= 90:
            return "Highly Recommended"
        elif rank <= 3 and total_score >= 80:
            return "Recommended"
        elif total_score >= 70:
            return "Consider"
        else:
            return "Not Recommended"
    
    def _calculate_confidence_level(self, ranked_suggestions: List[ScoringResult]) -> float:
        """Calculate confidence level in scoring results"""
        if not ranked_suggestions:
            return 0.0
        
        # High confidence if top suggestion significantly outperforms others
        if len(ranked_suggestions) >= 2:
            top_score = ranked_suggestions[0].total_score
            second_score = ranked_suggestions[1].total_score
            score_gap = top_score - second_score
            
            if score_gap >= 10:
                return 95.0
            elif score_gap >= 5:
                return 85.0
            else:
                return 75.0
        else:
            return 90.0  # Single suggestion
    
    def _generate_recommendation_summary(self, ranked_suggestions: List[ScoringResult]) -> str:
        """Generate executive recommendation summary"""
        if not ranked_suggestions:
            return "No suggestions to evaluate"
        
        top_suggestion = ranked_suggestions[0]
        
        if top_suggestion.total_score >= 90:
            return f"Strong recommendation: Suggestion {top_suggestion.ranking_position} scores {top_suggestion.total_score:.1f}/100 with excellent coverage and cost optimization"
        elif top_suggestion.total_score >= 80:
            return f"Good recommendation: Suggestion {top_suggestion.ranking_position} scores {top_suggestion.total_score:.1f}/100 with solid performance across criteria"
        elif top_suggestion.total_score >= 70:
            return f"Moderate recommendation: Suggestion {top_suggestion.ranking_position} scores {top_suggestion.total_score:.1f}/100 with acceptable trade-offs"
        else:
            return f"Weak recommendation: Top suggestion scores only {top_suggestion.total_score:.1f}/100, consider generating new options"
    
    def validate_bdd_requirements(self, result: RankedSuggestions) -> Dict[str, bool]:
        """Validate against BDD requirements"""
        validation = {}
        
        # Processing time: 1-2 seconds
        validation['processing_time'] = result.processing_time_ms <= 2000
        
        # Multi-criteria decision system
        validation['multi_criteria'] = len(result.scoring_methodology['weights']) >= 4
        
        # All metrics processed
        validation['all_metrics'] = result.total_evaluated > 0
        
        # Ranked suggestions generated
        validation['ranked_suggestions'] = len(result.suggestions) > 0
        
        # Scoring methodology transparency
        validation['scoring_transparency'] = all(
            len(s.score_breakdown) > 0 for s in result.suggestions
        )
        
        # Confidence assessment
        validation['confidence_assessment'] = result.confidence_level > 0
        
        return validation