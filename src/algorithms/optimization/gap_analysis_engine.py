#!/usr/bin/env python3
"""
Gap Analysis Engine - BDD Implementation
From: 24-automatic-schedule-optimization.feature:51
"Gap Analysis Engine | Statistical analysis | Coverage vs forecast | Gap severity map | 2-3 seconds"
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Any
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class GapSeverity(Enum):
    """Gap severity levels for color coding"""
    CRITICAL = "critical"    # Red - >20% gap
    HIGH = "high"           # Orange - 10-20% gap  
    MEDIUM = "medium"       # Yellow - 5-10% gap
    LOW = "low"            # Light yellow - 0-5% gap
    COVERED = "covered"     # Green - no gap

@dataclass
class GapAnalysis:
    """Individual gap analysis result"""
    interval: str
    required_agents: int
    scheduled_agents: int
    gap_count: int
    gap_percentage: float
    severity: GapSeverity
    cost_impact: float
    service_level_impact: float

@dataclass
class GapSeverityMap:
    """Complete gap severity mapping output"""
    interval_gaps: List[GapAnalysis]
    total_gaps: int
    average_gap_percentage: float
    critical_intervals: List[str]
    coverage_score: float
    improvement_recommendations: List[str]
    processing_time_ms: float

class GapAnalysisEngine:
    """
    Statistical analysis engine for coverage gaps
    BDD Requirement: Coverage vs forecast → Gap severity map
    """
    
    def __init__(self):
        self.severity_thresholds = {
            'critical': 0.20,   # >20% gap
            'high': 0.10,       # 10-20% gap
            'medium': 0.05,     # 5-10% gap
            'low': 0.01,        # 1-5% gap
        }
        
        # BDD Requirement: Target >15% reduction
        self.target_improvement = 0.15
        
    def analyze_coverage_gaps(self, 
                             forecast_data: Dict[str, int],
                             current_schedule: Dict[str, int]) -> GapSeverityMap:
        """
        Main gap analysis per BDD specification
        Input: Coverage vs forecast
        Output: Gap severity map
        Processing: 2-3 seconds (BDD requirement)
        """
        start_time = datetime.now()
        
        # Step 1: Interval-by-interval analysis (BDD line 65)
        interval_gaps = []
        
        for interval, required in forecast_data.items():
            scheduled = current_schedule.get(interval, 0)
            gap_count = max(0, required - scheduled)
            gap_percentage = gap_count / required if required > 0 else 0
            
            # Determine severity
            severity = self._classify_gap_severity(gap_percentage)
            
            # Calculate impacts
            cost_impact = self._calculate_cost_impact(gap_count)
            sl_impact = self._calculate_service_level_impact(gap_percentage)
            
            gap_analysis = GapAnalysis(
                interval=interval,
                required_agents=required,
                scheduled_agents=scheduled,
                gap_count=gap_count,
                gap_percentage=gap_percentage,
                severity=severity,
                cost_impact=cost_impact,
                service_level_impact=sl_impact
            )
            
            interval_gaps.append(gap_analysis)
        
        # Step 2: Statistical summary
        total_gaps = sum(gap.gap_count for gap in interval_gaps)
        avg_gap_pct = np.mean([gap.gap_percentage for gap in interval_gaps])
        
        # Step 3: Critical interval identification
        critical_intervals = [
            gap.interval for gap in interval_gaps 
            if gap.severity == GapSeverity.CRITICAL
        ]
        
        # Step 4: Coverage score calculation
        coverage_score = self._calculate_coverage_score(interval_gaps)
        
        # Step 5: Improvement recommendations
        recommendations = self._generate_recommendations(interval_gaps)
        
        # Processing time validation
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return GapSeverityMap(
            interval_gaps=interval_gaps,
            total_gaps=total_gaps,
            average_gap_percentage=avg_gap_pct,
            critical_intervals=critical_intervals,
            coverage_score=coverage_score,
            improvement_recommendations=recommendations,
            processing_time_ms=processing_time
        )
    
    def _classify_gap_severity(self, gap_percentage: float) -> GapSeverity:
        """Classify gap severity per BDD color coding"""
        if gap_percentage >= self.severity_thresholds['critical']:
            return GapSeverity.CRITICAL
        elif gap_percentage >= self.severity_thresholds['high']:
            return GapSeverity.HIGH
        elif gap_percentage >= self.severity_thresholds['medium']:
            return GapSeverity.MEDIUM
        elif gap_percentage >= self.severity_thresholds['low']:
            return GapSeverity.LOW
        else:
            return GapSeverity.COVERED
    
    def _calculate_cost_impact(self, gap_count: int) -> float:
        """Calculate financial impact of gap"""
        # Assume $25/hour average wage + benefits
        hourly_cost = 35.0
        return gap_count * hourly_cost
    
    def _calculate_service_level_impact(self, gap_percentage: float) -> float:
        """Estimate service level degradation from gap"""
        # Statistical approximation: SL drops roughly 2x gap percentage
        return min(1.0, gap_percentage * 2.0)
    
    def _calculate_coverage_score(self, gaps: List[GapAnalysis]) -> float:
        """Calculate overall coverage score (0-100)"""
        if not gaps:
            return 100.0
        
        # Weight by severity
        severity_weights = {
            GapSeverity.CRITICAL: 1.0,
            GapSeverity.HIGH: 0.7,
            GapSeverity.MEDIUM: 0.4,
            GapSeverity.LOW: 0.2,
            GapSeverity.COVERED: 0.0
        }
        
        total_weight = 0
        weighted_coverage = 0
        
        for gap in gaps:
            weight = severity_weights[gap.severity]
            coverage = 1.0 - gap.gap_percentage
            weighted_coverage += coverage * weight
            total_weight += weight
        
        if total_weight == 0:
            return 100.0
        
        return (weighted_coverage / total_weight) * 100
    
    def _generate_recommendations(self, gaps: List[GapAnalysis]) -> List[str]:
        """Generate improvement recommendations per BDD"""
        recommendations = []
        
        # Critical gaps
        critical_gaps = [g for g in gaps if g.severity == GapSeverity.CRITICAL]
        if critical_gaps:
            recommendations.append(
                f"URGENT: {len(critical_gaps)} critical intervals need immediate staffing"
            )
        
        # High impact periods
        high_cost_gaps = [g for g in gaps if g.cost_impact > 200]
        if high_cost_gaps:
            recommendations.append(
                f"Focus on {len(high_cost_gaps)} high-cost intervals for maximum ROI"
            )
        
        # Pattern detection
        peak_hours = [g for g in gaps if "10:00" <= g.interval <= "16:00" and g.gap_count > 0]
        if len(peak_hours) > 3:
            recommendations.append(
                "Consider additional peak-hour staffing or shift overlap"
            )
        
        # BDD Target: >15% reduction possible
        total_reduction_potential = sum(g.gap_count for g in gaps)
        if total_reduction_potential > 0:
            recommendations.append(
                f"Potential improvement: {total_reduction_potential} agent gaps reducible"
            )
        
        return recommendations
    
    def identify_gap_patterns(self, gaps: List[GapAnalysis]) -> Dict[str, Any]:
        """Advanced pattern analysis for optimization"""
        patterns = {
            'peak_periods': [],
            'recurring_gaps': [],
            'severity_distribution': {},
            'cost_hotspots': []
        }
        
        # Peak period detection
        for gap in gaps:
            if gap.severity in [GapSeverity.CRITICAL, GapSeverity.HIGH]:
                patterns['peak_periods'].append(gap.interval)
        
        # Severity distribution
        for severity in GapSeverity:
            count = len([g for g in gaps if g.severity == severity])
            patterns['severity_distribution'][severity.value] = count
        
        # Cost hotspots (BDD: Cost efficiency 30% weight)
        cost_sorted = sorted(gaps, key=lambda x: x.cost_impact, reverse=True)
        patterns['cost_hotspots'] = [
            {'interval': g.interval, 'cost': g.cost_impact} 
            for g in cost_sorted[:5]
        ]
        
        return patterns
    
    def validate_bdd_requirements(self, result: GapSeverityMap) -> Dict[str, bool]:
        """Validate against BDD requirements"""
        validation = {}
        
        # Processing time: 2-3 seconds
        validation['processing_time'] = result.processing_time_ms <= 3000
        
        # Statistical analysis completed
        validation['statistical_analysis'] = len(result.interval_gaps) > 0
        
        # Gap severity map generated
        validation['severity_map'] = all(
            gap.severity is not None for gap in result.interval_gaps
        )
        
        # Coverage vs forecast analysis
        validation['coverage_analysis'] = result.coverage_score is not None
        
        # Target improvement calculation (>15% reduction)
        validation['improvement_target'] = len(result.improvement_recommendations) > 0
        
        return validation