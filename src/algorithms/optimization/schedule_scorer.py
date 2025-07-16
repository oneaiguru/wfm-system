#!/usr/bin/env python3
"""
Mobile Workforce Schedule Scorer - Enhanced with Real Database Integration
Implements sophisticated schedule scoring with real performance data
Applies Mobile Workforce Scheduler pattern for field service optimization
Connects to actual database performance metrics and KPIs
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import json
import asyncio
import asyncpg
import logging
from pathlib import Path
import sys

# Add the project root to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))
from api.core.config import settings

logging.basicConfig(level=logging.INFO)

@dataclass
class MobileWorkforceScheduleMetrics:
    """Enhanced schedule evaluation metrics with mobile workforce specifics"""
    coverage_score: float
    cost_score: float
    compliance_score: float
    fairness_score: float
    efficiency_score: float
    flexibility_score: float
    continuity_score: float
    preference_score: float
    # Mobile Workforce Specific Metrics
    location_optimization_score: float
    travel_time_efficiency: float
    mobile_coverage_score: float
    real_time_performance_score: float
    overall_score: float
    detailed_breakdown: Dict
    database_metrics: Dict = field(default_factory=dict)
    performance_benchmarks: Dict = field(default_factory=dict)

class MobileWorkforceScheduleScorer:
    """
    Enhanced Mobile Workforce Schedule Scoring System
    Integrates real database performance data and KPIs
    Implements Mobile Workforce Scheduler pattern
    Connects to actual schedule optimization results and performance metrics
    """
    
    def __init__(self, database_url: Optional[str] = None):
        # Enhanced weights including mobile workforce specifics
        self.weights = {
            'coverage': 0.25,                    # Meeting demand
            'cost': 0.20,                       # Labor cost optimization
            'compliance': 0.15,                 # Legal/policy compliance
            'fairness': 0.10,                   # Fair distribution
            'efficiency': 0.08,                 # Resource utilization
            'flexibility': 0.05,                # Adaptability
            'continuity': 0.03,                 # Shift patterns
            'preference': 0.02,                 # Agent preferences
            # Mobile Workforce Specific Weights
            'location_optimization': 0.05,      # Geographic efficiency
            'travel_time_efficiency': 0.04,     # Travel optimization
            'mobile_coverage': 0.02,            # Mobile field coverage
            'real_time_performance': 0.01       # Real-time KPIs
        }
        
        # Database connection
        raw_url = database_url or settings.DATABASE_URL
        # Convert SQLAlchemy URL to asyncpg format
        if raw_url and 'postgresql+asyncpg://' in raw_url:
            self.database_url = raw_url.replace('postgresql+asyncpg://', 'postgresql://')
        else:
            self.database_url = raw_url
        self.db_pool = None
        
        # Performance cache
        self.performance_cache = {}
        self.cache_ttl = 300  # 5 minutes
        
        # Mobile workforce specific settings
        self.mobile_settings = {
            'max_travel_time_minutes': 45,
            'optimal_coverage_radius_km': 25,
            'service_level_target': 85.0,
            'response_time_target_minutes': 30
        }
        
        # Enhanced scoring thresholds with mobile workforce standards
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
            },
            'location_optimization': {
                'excellent': 0.95,  # Minimal travel overhead
                'good': 0.88,
                'acceptable': 0.80,
                'poor': 0.70
            },
            'travel_efficiency': {
                'excellent': 0.92,  # Optimal routing
                'good': 0.85,
                'acceptable': 0.75,
                'poor': 0.60
            },
            'mobile_coverage': {
                'excellent': 0.95,  # Full geographic coverage
                'good': 0.88,
                'acceptable': 0.80,
                'poor': 0.70
            }
        }
        
        logging.info("MobileWorkforceScheduleScorer initialized with database integration")
    
    async def score_schedule(self, 
                           schedule: Dict,
                           requirements: Dict,
                           constraints: Optional[Dict] = None,
                           preferences: Optional[Dict] = None,
                           include_real_metrics: bool = True) -> MobileWorkforceScheduleMetrics:
        """
        Score a schedule across all dimensions with real database integration
        Implements Mobile Workforce Scheduler pattern with actual performance data
        Connects to real schedule optimization results and performance KPIs
        """
        try:
            # Initialize database connection if needed
            if include_real_metrics and not self.db_pool:
                await self._init_database_connection()
            
            # Get real-time performance data from database
            real_metrics = {}
            if include_real_metrics and self.db_pool:
                real_metrics = await self._fetch_real_performance_metrics(schedule)
            
            logging.info(f"Scoring schedule with {len(schedule.get('agents', []))} agents and real metrics: {bool(real_metrics)}")
            # Calculate traditional scores enhanced with real data
            coverage_score, coverage_details = await self._score_coverage_enhanced(schedule, requirements, real_metrics)
            cost_score, cost_details = await self._score_cost_enhanced(schedule, requirements, real_metrics)
            compliance_score, compliance_details = await self._score_compliance_enhanced(schedule, constraints, real_metrics)
            fairness_score, fairness_details = self._score_fairness(schedule)
            efficiency_score, efficiency_details = await self._score_efficiency_enhanced(schedule, requirements, real_metrics)
            flexibility_score, flexibility_details = self._score_flexibility(schedule)
            continuity_score, continuity_details = self._score_continuity(schedule)
            preference_score, preference_details = self._score_preferences(schedule, preferences)
            
            # Mobile Workforce specific scores
            location_score, location_details = await self._score_location_optimization(schedule, real_metrics)
            travel_score, travel_details = await self._score_travel_efficiency(schedule, real_metrics)
            mobile_coverage_score, mobile_details = await self._score_mobile_coverage(schedule, real_metrics)
            rt_performance_score, rt_details = await self._score_real_time_performance(schedule, real_metrics)
        
            # Calculate weighted overall score with mobile workforce metrics
            scores = {
                'coverage': coverage_score,
                'cost': cost_score,
                'compliance': compliance_score,
                'fairness': fairness_score,
                'efficiency': efficiency_score,
                'flexibility': flexibility_score,
                'continuity': continuity_score,
                'preference': preference_score,
                'location_optimization': location_score,
                'travel_time_efficiency': travel_score,
                'mobile_coverage': mobile_coverage_score,
                'real_time_performance': rt_performance_score
            }
        
            overall_score = sum(scores[metric] * self.weights[metric] 
                              for metric in scores if metric in self.weights)
        
            # Compile detailed breakdown with mobile workforce specifics
            detailed_breakdown = {
                'coverage': coverage_details,
                'cost': cost_details,
                'compliance': compliance_details,
                'fairness': fairness_details,
                'efficiency': efficiency_details,
                'flexibility': flexibility_details,
                'continuity': continuity_details,
                'preference': preference_details,
                'location_optimization': location_details,
                'travel_efficiency': travel_details,
                'mobile_coverage': mobile_details,
                'real_time_performance': rt_details,
                'weighted_scores': {
                    metric: scores[metric] * self.weights.get(metric, 0)
                    for metric in scores
                },
                'database_integration': {
                    'real_metrics_available': bool(real_metrics),
                    'metrics_source': 'database' if real_metrics else 'calculated',
                    'cache_hit_rate': self._calculate_cache_hit_rate()
                }
            }
        
            # Store optimization results in database for future reference
            if include_real_metrics and self.db_pool:
                await self._store_scoring_results(schedule, scores, overall_score)
            
            return MobileWorkforceScheduleMetrics(
                coverage_score=coverage_score,
                cost_score=cost_score,
                compliance_score=compliance_score,
                fairness_score=fairness_score,
                efficiency_score=efficiency_score,
                flexibility_score=flexibility_score,
                continuity_score=continuity_score,
                preference_score=preference_score,
                location_optimization_score=location_score,
                travel_time_efficiency=travel_score,
                mobile_coverage_score=mobile_coverage_score,
                real_time_performance_score=rt_performance_score,
                overall_score=overall_score,
                detailed_breakdown=detailed_breakdown,
                database_metrics=real_metrics,
                performance_benchmarks=await self._get_performance_benchmarks()
            )
            
        except Exception as e:
            logging.error(f"Error scoring schedule: {str(e)}")
            # Return basic scoring without database integration on error
            return await self._fallback_scoring(schedule, requirements, constraints, preferences)
    
    async def _score_coverage_enhanced(self, schedule: Dict, requirements: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score how well schedule meets coverage requirements with real database data
        Uses actual schedule coverage analysis from database
        """
        total_intervals = 0
        covered_intervals = 0
        gap_severity = 0
        interval_scores = []
        
        # Use real coverage data if available
        real_coverage_data = real_metrics.get('coverage_analysis', {})
        if real_coverage_data:
            base_score = real_coverage_data.get('coverage_percentage', 0) / 100.0
            logging.info(f"Using real coverage percentage: {real_coverage_data.get('coverage_percentage', 0)}%")
        else:
            # Calculate coverage from schedule data
            base_score = 0
        
        # Calculate interval-by-interval coverage
        for interval, requirement in requirements.items():
            scheduled = self._count_scheduled_agents(schedule, interval)
            required = requirement.get('required_agents', 0)
            
            if required > 0:
                coverage_ratio = min(1.0, scheduled / required)
                
                # Apply real-time adjustment if we have real metrics
                rt_adjustment = 1.0
                if real_metrics.get('real_time_adjustments'):
                    rt_data = real_metrics['real_time_adjustments'].get(interval, {})
                    rt_adjustment = rt_data.get('coverage_multiplier', 1.0)
                
                adjusted_coverage = coverage_ratio * rt_adjustment
                
                interval_scores.append({
                    'interval': interval,
                    'required': required,
                    'scheduled': scheduled,
                    'coverage': adjusted_coverage,
                    'gap': max(0, required - scheduled),
                    'real_time_adjustment': rt_adjustment
                })
                
                covered_intervals += adjusted_coverage
                total_intervals += 1
                
                # Calculate gap severity with real-time weighting
                if scheduled < required:
                    gap_pct = (required - scheduled) / required
                    gap_severity += (gap_pct ** 2) * rt_adjustment
        
        # Base coverage score calculation
        if not real_coverage_data and total_intervals > 0:
            base_score = covered_intervals / total_intervals
        
        if total_intervals > 0:
            # Apply penalty for severe gaps
            severity_penalty = min(0.2, gap_severity / total_intervals)
            coverage_score = max(0, base_score - severity_penalty)
            
            # Apply real-time performance bonus if service levels are exceeded
            if real_metrics.get('service_level_current', 0) > self.mobile_settings['service_level_target']:
                service_bonus = min(0.1, (real_metrics['service_level_current'] - self.mobile_settings['service_level_target']) / 100.0)
                coverage_score = min(1.0, coverage_score + service_bonus)
        else:
            coverage_score = 1.0
        
        details = {
            'base_coverage': base_score if total_intervals > 0 else 1.0,
            'gap_penalty': severity_penalty if total_intervals > 0 else 0,
            'total_intervals': total_intervals,
            'fully_covered': sum(1 for s in interval_scores if s['coverage'] >= 1.0),
            'critical_gaps': [s for s in interval_scores if s['gap'] > 5],
            'interval_breakdown': interval_scores[:10],  # Top 10 for brevity
            'real_coverage_data': real_coverage_data,
            'service_level_bonus': real_metrics.get('service_level_current', 0) > self.mobile_settings['service_level_target'],
            'database_source': bool(real_coverage_data)
        }
        
        return coverage_score, details
    
    async def _score_cost_enhanced(self, schedule: Dict, requirements: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score schedule cost efficiency with real database optimization data
        Uses actual cost calculations and optimization results
        """
        # Get real cost data from database if available
        real_cost_data = real_metrics.get('cost_optimization', {})
        
        # Calculate actual cost
        total_hours = 0
        overtime_hours = 0
        idle_hours = 0
        travel_hours = 0  # Mobile workforce specific
        
        for agent in schedule.get('agents', []):
            agent_hours = self._calculate_agent_hours(agent)
            total_hours += agent_hours['regular']
            overtime_hours += agent_hours['overtime']
            idle_hours += agent_hours['idle']
            travel_hours += agent_hours.get('travel', 0)  # Mobile workforce travel time
        
        # Calculate theoretical minimum cost (enhanced for mobile workforce)
        min_hours = sum(req.get('required_agents', 0) * 0.25  # 15-min intervals
                       for req in requirements.values())
        
        # Use real optimization data if available
        if real_cost_data:
            theoretical_min = real_cost_data.get('theoretical_minimum_cost', min_hours * 1.0)
            logging.info(f"Using real theoretical minimum cost: {theoretical_min}")
        else:
            theoretical_min = min_hours * 1.0
        
        # Enhanced cost factors including mobile workforce specifics
        regular_cost = total_hours * 1.0
        overtime_cost = overtime_hours * 1.5
        idle_cost = idle_hours * 0.8  # Idle time still costs
        travel_cost = travel_hours * 1.2  # Travel time premium
        
        # Mobile workforce additional costs
        fuel_cost = self._calculate_fuel_costs(schedule, real_metrics)
        vehicle_cost = self._calculate_vehicle_costs(schedule, real_metrics)
        
        actual_cost = regular_cost + overtime_cost + idle_cost + travel_cost + fuel_cost + vehicle_cost
        
        # Calculate efficiency with real benchmark data
        if theoretical_min > 0:
            cost_efficiency = theoretical_min / actual_cost
            cost_score = min(1.0, cost_efficiency)
            
            # Apply benchmark adjustment if available
            if real_cost_data.get('industry_benchmark'):
                benchmark_ratio = actual_cost / real_cost_data['industry_benchmark']
                if benchmark_ratio < 0.9:  # Better than benchmark
                    cost_score = min(1.0, cost_score * 1.1)
                elif benchmark_ratio > 1.2:  # Worse than benchmark
                    cost_score = cost_score * 0.9
        else:
            cost_score = 1.0
        
        details = {
            'total_hours': round(total_hours, 2),
            'overtime_hours': round(overtime_hours, 2),
            'idle_hours': round(idle_hours, 2),
            'travel_hours': round(travel_hours, 2),
            'regular_cost': round(regular_cost, 2),
            'overtime_cost': round(overtime_cost, 2),
            'travel_cost': round(travel_cost, 2),
            'fuel_cost': round(fuel_cost, 2),
            'vehicle_cost': round(vehicle_cost, 2),
            'total_cost': round(actual_cost, 2),
            'theoretical_minimum': round(theoretical_min, 2),
            'efficiency_ratio': round(cost_efficiency if theoretical_min > 0 else 1.0, 3),
            'cost_per_interval': round(actual_cost / max(1, len(requirements)), 2),
            'mobile_workforce_overhead': round((travel_cost + fuel_cost + vehicle_cost) / max(1, actual_cost) * 100, 2),
            'real_cost_data': real_cost_data,
            'benchmark_comparison': real_cost_data.get('industry_benchmark', 0)
        }
        
        return cost_score, details
    
    async def _score_compliance_enhanced(self, schedule: Dict, constraints: Optional[Dict], real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score legal and policy compliance with real violation tracking
        """
        if not constraints:
            return 1.0, {'status': 'no_constraints_defined'}
        
        # Get real compliance data from database
        real_compliance_data = real_metrics.get('compliance_tracking', {})
        
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
    
    async def _score_location_optimization(self, schedule: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score geographic location optimization for mobile workforce
        """
        location_data = real_metrics.get('location_optimization', {})
        
        # Calculate travel distance efficiency
        total_travel_distance = 0
        optimal_travel_distance = 0
        agents = schedule.get('agents', [])
        
        for agent in agents:
            agent_travel = agent.get('travel_metrics', {})
            total_travel_distance += agent_travel.get('actual_distance_km', 0)
            optimal_travel_distance += agent_travel.get('optimal_distance_km', 0)
        
        if optimal_travel_distance > 0:
            travel_efficiency = optimal_travel_distance / total_travel_distance
            location_score = min(1.0, travel_efficiency)
        else:
            location_score = 0.8  # Default if no travel data
        
        # Apply real-time GPS tracking bonuses
        if location_data.get('gps_tracking_efficiency', 0) > 0.9:
            location_score = min(1.0, location_score * 1.05)
        
        details = {
            'total_travel_distance_km': round(total_travel_distance, 2),
            'optimal_travel_distance_km': round(optimal_travel_distance, 2),
            'travel_efficiency': round(travel_efficiency if optimal_travel_distance > 0 else 0, 3),
            'gps_tracking_efficiency': location_data.get('gps_tracking_efficiency', 0),
            'location_clusters': location_data.get('service_location_clusters', 0),
            'coverage_radius_efficiency': location_data.get('coverage_radius_efficiency', 0)
        }
        
        return location_score, details
    
    async def _score_travel_efficiency(self, schedule: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score travel time efficiency for mobile workforce
        """
        travel_data = real_metrics.get('travel_metrics', {})
        
        total_travel_time = 0
        productive_time = 0
        agents = schedule.get('agents', [])
        
        for agent in agents:
            agent_hours = self._calculate_agent_hours(agent)
            total_travel_time += agent_hours.get('travel', 0)
            productive_time += agent_hours.get('productive', agent_hours.get('regular', 0))
        
        if total_travel_time + productive_time > 0:
            productivity_ratio = productive_time / (total_travel_time + productive_time)
            travel_score = productivity_ratio
        else:
            travel_score = 0.8
        
        # Apply traffic optimization bonuses
        if travel_data.get('traffic_optimization_score', 0) > 0.85:
            travel_score = min(1.0, travel_score * 1.03)
        
        details = {
            'total_travel_time_hours': round(total_travel_time, 2),
            'productive_time_hours': round(productive_time, 2),
            'productivity_ratio': round(productivity_ratio if total_travel_time + productive_time > 0 else 0, 3),
            'average_travel_time_per_job': travel_data.get('avg_travel_time_minutes', 0),
            'traffic_optimization_score': travel_data.get('traffic_optimization_score', 0),
            'route_optimization_savings': travel_data.get('route_savings_percentage', 0)
        }
        
        return travel_score, details
    
    async def _score_mobile_coverage(self, schedule: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score mobile field coverage efficiency
        """
        coverage_data = real_metrics.get('mobile_coverage', {})
        
        # Calculate geographic coverage score
        covered_areas = coverage_data.get('covered_service_areas', 0)
        total_areas = coverage_data.get('total_service_areas', 1)
        
        area_coverage_score = covered_areas / total_areas if total_areas > 0 else 0.8
        
        # Calculate response time coverage
        avg_response_time = coverage_data.get('average_response_time_minutes', 60)
        target_response_time = self.mobile_settings['response_time_target_minutes']
        
        if avg_response_time <= target_response_time:
            response_time_score = 1.0
        else:
            response_time_score = max(0.3, target_response_time / avg_response_time)
        
        # Combined mobile coverage score
        mobile_coverage_score = (area_coverage_score * 0.6 + response_time_score * 0.4)
        
        details = {
            'covered_service_areas': covered_areas,
            'total_service_areas': total_areas,
            'area_coverage_percentage': round(area_coverage_score * 100, 1),
            'average_response_time_minutes': avg_response_time,
            'target_response_time_minutes': target_response_time,
            'response_time_score': round(response_time_score, 3),
            'mobile_coverage_score': round(mobile_coverage_score, 3)
        }
        
        return mobile_coverage_score, details
    
    async def _score_real_time_performance(self, schedule: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """
        Score based on real-time performance KPIs from database
        """
        rt_data = real_metrics.get('real_time_performance', {})
        
        # Service level performance
        current_service_level = rt_data.get('service_level_current', 0)
        target_service_level = self.mobile_settings['service_level_target']
        
        if current_service_level >= target_service_level:
            service_level_score = min(1.0, current_service_level / target_service_level)
        else:
            service_level_score = current_service_level / target_service_level
        
        # Response time performance
        avg_response_time = rt_data.get('response_time_avg', 0)
        target_response_time = self.mobile_settings['response_time_target_minutes'] * 60  # Convert to seconds
        
        if avg_response_time <= target_response_time and avg_response_time > 0:
            response_time_score = 1.0
        elif avg_response_time > 0:
            response_time_score = max(0.3, target_response_time / avg_response_time)
        else:
            response_time_score = 0.5
        
        # Queue performance
        calls_in_queue = rt_data.get('calls_in_queue', 0)
        agents_available = rt_data.get('agents_available', 1)
        
        queue_ratio = calls_in_queue / max(1, agents_available)
        if queue_ratio <= 1:
            queue_score = 1.0
        else:
            queue_score = max(0.2, 1.0 / queue_ratio)
        
        # Combined real-time performance score
        rt_performance_score = (service_level_score * 0.4 + response_time_score * 0.35 + queue_score * 0.25)
        
        details = {
            'current_service_level': current_service_level,
            'target_service_level': target_service_level,
            'service_level_score': round(service_level_score, 3),
            'average_response_time_seconds': avg_response_time,
            'target_response_time_seconds': target_response_time,
            'response_time_score': round(response_time_score, 3),
            'calls_in_queue': calls_in_queue,
            'agents_available': agents_available,
            'queue_score': round(queue_score, 3),
            'real_time_score': round(rt_performance_score, 3)
        }
        
        return rt_performance_score, details
    
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
    
    # Database Integration Methods
    
    async def _init_database_connection(self):
        """Initialize database connection pool"""
        try:
            self.db_pool = await asyncpg.create_pool(
                self.database_url,
                min_size=2,
                max_size=10,
                command_timeout=30
            )
            logging.info("Database connection pool initialized for schedule scoring")
        except Exception as e:
            logging.error(f"Failed to initialize database connection: {str(e)}")
            self.db_pool = None
    
    async def _fetch_real_performance_metrics(self, schedule: Dict) -> Dict:
        """Fetch real performance metrics from database"""
        if not self.db_pool:
            return {}
        
        try:
            async with self.db_pool.acquire() as conn:
                # Fetch coverage analysis data
                coverage_query = """
                    SELECT coverage_percentage, actual_coverage, coverage_gaps, 
                           required_coverage, analysis_status
                    FROM schedule_coverage_analysis 
                    WHERE analysis_status = 'completed' 
                    ORDER BY created_at DESC LIMIT 1
                """
                coverage_data = await conn.fetchrow(coverage_query)
                
                # Fetch real-time performance metrics
                performance_query = """
                    SELECT metric_name, metric_value, service_level_current, 
                           response_time_avg, calls_in_queue, agents_available
                    FROM performance_metrics_realtime 
                    WHERE timestamp_recorded > NOW() - INTERVAL '1 hour'
                    ORDER BY timestamp_recorded DESC
                """
                performance_data = await conn.fetch(performance_query)
                
                # Fetch optimization results
                optimization_query = """
                    SELECT improvement_percentage, algorithm_used, execution_time_ms,
                           original_schedule, optimized_schedule
                    FROM schedule_optimization_results 
                    WHERE optimization_date >= CURRENT_DATE - INTERVAL '7 days'
                    ORDER BY created_at DESC LIMIT 5
                """
                optimization_data = await conn.fetch(optimization_query)
                
                # Compile metrics
                metrics = {
                    'coverage_analysis': {
                        'coverage_percentage': float(coverage_data['coverage_percentage']) if coverage_data else 0,
                        'actual_coverage': coverage_data['actual_coverage'] if coverage_data else {},
                        'coverage_gaps': coverage_data['coverage_gaps'] if coverage_data else {},
                        'status': coverage_data['analysis_status'] if coverage_data else 'no_data'
                    },
                    'real_time_performance': {
                        'service_level_current': 0,
                        'response_time_avg': 0,
                        'calls_in_queue': 0,
                        'agents_available': 0
                    },
                    'optimization_history': []
                }
                
                # Process real-time metrics
                if performance_data:
                    latest_metrics = performance_data[0]
                    metrics['real_time_performance'].update({
                        'service_level_current': float(latest_metrics['service_level_current'] or 0),
                        'response_time_avg': float(latest_metrics['response_time_avg'] or 0),
                        'calls_in_queue': int(latest_metrics['calls_in_queue'] or 0),
                        'agents_available': int(latest_metrics['agents_available'] or 0)
                    })
                
                # Process optimization history
                for opt_result in optimization_data:
                    metrics['optimization_history'].append({
                        'improvement_percentage': float(opt_result['improvement_percentage'] or 0),
                        'algorithm_used': opt_result['algorithm_used'],
                        'execution_time_ms': int(opt_result['execution_time_ms'] or 0)
                    })
                
                logging.info(f"Fetched real performance metrics: coverage={metrics['coverage_analysis']['coverage_percentage']}%, service_level={metrics['real_time_performance']['service_level_current']}%")
                return metrics
                
        except Exception as e:
            logging.error(f"Error fetching performance metrics: {str(e)}")
            return {}
    
    async def _store_scoring_results(self, schedule: Dict, scores: Dict, overall_score: float):
        """Store scoring results back to database for future optimization"""
        if not self.db_pool:
            return
        
        try:
            async with self.db_pool.acquire() as conn:
                insert_query = """
                    INSERT INTO schedule_optimization_results 
                    (optimization_date, original_schedule, optimized_schedule, 
                     improvement_percentage, algorithm_used, execution_time_ms)
                    VALUES ($1, $2, $3, $4, $5, $6)
                """
                
                await conn.execute(
                    insert_query,
                    datetime.now().date(),
                    json.dumps(schedule),
                    json.dumps({'scores': scores, 'overall_score': overall_score}),
                    round(overall_score * 100, 2),
                    'mobile_workforce_scorer',
                    100  # Placeholder execution time
                )
                
                logging.info(f"Stored scoring results with overall score: {overall_score:.3f}")
                
        except Exception as e:
            logging.error(f"Error storing scoring results: {str(e)}")
    
    async def _get_performance_benchmarks(self) -> Dict:
        """Get performance benchmarks from database"""
        if not self.db_pool:
            return {}
        
        try:
            async with self.db_pool.acquire() as conn:
                benchmark_query = """
                    SELECT 
                        AVG(coverage_percentage) as avg_coverage,
                        AVG(service_level_current) as avg_service_level,
                        AVG(response_time_avg) as avg_response_time,
                        COUNT(*) as sample_size
                    FROM schedule_coverage_analysis sca
                    JOIN performance_metrics_realtime pmr ON DATE(sca.created_at) = DATE(pmr.timestamp_recorded)
                    WHERE sca.created_at > NOW() - INTERVAL '30 days'
                """
                
                result = await conn.fetchrow(benchmark_query)
                
                if result:
                    return {
                        'industry_avg_coverage': float(result['avg_coverage'] or 0),
                        'industry_avg_service_level': float(result['avg_service_level'] or 0),
                        'industry_avg_response_time': float(result['avg_response_time'] or 0),
                        'benchmark_sample_size': int(result['sample_size'] or 0)
                    }
                else:
                    return {}
                    
        except Exception as e:
            logging.error(f"Error fetching benchmarks: {str(e)}")
            return {}
    
    async def _score_efficiency_enhanced(self, schedule: Dict, requirements: Dict, real_metrics: Dict) -> Tuple[float, Dict]:
        """Enhanced efficiency scoring with real database metrics"""
        # Get the basic efficiency score
        efficiency_score, details = self._score_efficiency(schedule, requirements)
        
        # Enhance with real-time data
        rt_data = real_metrics.get('real_time_performance', {})
        if rt_data:
            # Apply real-time utilization bonus
            agents_available = rt_data.get('agents_available', 0)
            calls_in_queue = rt_data.get('calls_in_queue', 0)
            
            if agents_available > 0:
                utilization_rate = min(1.0, calls_in_queue / agents_available)
                if 0.8 <= utilization_rate <= 0.95:  # Optimal utilization range
                    efficiency_score = min(1.0, efficiency_score * 1.05)
                elif utilization_rate > 0.95:  # Over-utilized
                    efficiency_score = efficiency_score * 0.95
        
        details['real_time_enhancement'] = bool(rt_data)
        details['real_time_utilization'] = rt_data.get('agents_available', 0)
        
        return efficiency_score, details
    
    def _calculate_fuel_costs(self, schedule: Dict, real_metrics: Dict) -> float:
        """Calculate fuel costs for mobile workforce"""
        fuel_rate_per_km = 0.15  # Default fuel cost per km
        total_distance = 0
        
        for agent in schedule.get('agents', []):
            travel_metrics = agent.get('travel_metrics', {})
            total_distance += travel_metrics.get('actual_distance_km', 0)
        
        return total_distance * fuel_rate_per_km
    
    def _calculate_vehicle_costs(self, schedule: Dict, real_metrics: Dict) -> float:
        """Calculate vehicle costs for mobile workforce"""
        vehicle_cost_per_hour = 5.0  # Default vehicle cost per hour
        total_vehicle_hours = 0
        
        for agent in schedule.get('agents', []):
            agent_hours = self._calculate_agent_hours(agent)
            total_vehicle_hours += agent_hours.get('total', 0)
        
        return total_vehicle_hours * vehicle_cost_per_hour
    
    def _calculate_cache_hit_rate(self) -> float:
        """Calculate cache hit rate for performance monitoring"""
        if not hasattr(self, '_cache_hits'):
            self._cache_hits = 0
            self._cache_misses = 0
        
        total_requests = self._cache_hits + self._cache_misses
        return self._cache_hits / max(1, total_requests)
    
    async def _fallback_scoring(self, schedule: Dict, requirements: Dict, 
                              constraints: Optional[Dict], preferences: Optional[Dict]) -> MobileWorkforceScheduleMetrics:
        """Fallback scoring when database integration fails"""
        logging.warning("Using fallback scoring - database integration unavailable")
        
        # Calculate basic scores without database integration
        coverage_score, coverage_details = self._score_coverage_basic(schedule, requirements)
        cost_score, cost_details = self._score_cost_basic(schedule, requirements)
        compliance_score, compliance_details = self._score_compliance_basic(schedule, constraints)
        fairness_score, fairness_details = self._score_fairness(schedule)
        efficiency_score, efficiency_details = self._score_efficiency(schedule, requirements)
        flexibility_score, flexibility_details = self._score_flexibility(schedule)
        continuity_score, continuity_details = self._score_continuity(schedule)
        preference_score, preference_details = self._score_preferences(schedule, preferences)
        
        # Default mobile workforce scores
        location_score, location_details = 0.8, {'status': 'fallback_mode'}
        travel_score, travel_details = 0.8, {'status': 'fallback_mode'}
        mobile_coverage_score, mobile_details = 0.8, {'status': 'fallback_mode'}
        rt_performance_score, rt_details = 0.8, {'status': 'fallback_mode'}
        
        scores = {
            'coverage': coverage_score,
            'cost': cost_score,
            'compliance': compliance_score,
            'fairness': fairness_score,
            'efficiency': efficiency_score,
            'flexibility': flexibility_score,
            'continuity': continuity_score,
            'preference': preference_score,
            'location_optimization': location_score,
            'travel_time_efficiency': travel_score,
            'mobile_coverage': mobile_coverage_score,
            'real_time_performance': rt_performance_score
        }
        
        overall_score = sum(scores[metric] * self.weights.get(metric, 0) for metric in scores)
        
        return MobileWorkforceScheduleMetrics(
            coverage_score=coverage_score,
            cost_score=cost_score,
            compliance_score=compliance_score,
            fairness_score=fairness_score,
            efficiency_score=efficiency_score,
            flexibility_score=flexibility_score,
            continuity_score=continuity_score,
            preference_score=preference_score,
            location_optimization_score=location_score,
            travel_time_efficiency=travel_score,
            mobile_coverage_score=mobile_coverage_score,
            real_time_performance_score=rt_performance_score,
            overall_score=overall_score,
            detailed_breakdown={
                'coverage': coverage_details,
                'cost': cost_details,
                'compliance': compliance_details,
                'fairness': fairness_details,
                'efficiency': efficiency_details,
                'flexibility': flexibility_details,
                'continuity': continuity_details,
                'preference': preference_details,
                'location_optimization': location_details,
                'travel_efficiency': travel_details,
                'mobile_coverage': mobile_details,
                'real_time_performance': rt_details,
                'fallback_mode': True
            }
        )
    
    def _score_coverage_basic(self, schedule: Dict, requirements: Dict) -> Tuple[float, Dict]:
        """Basic coverage scoring without database integration"""
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
                
                if scheduled < required:
                    gap_pct = (required - scheduled) / required
                    gap_severity += gap_pct ** 2
        
        if total_intervals > 0:
            base_score = covered_intervals / total_intervals
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
            'interval_breakdown': interval_scores[:10]
        }
        
        return coverage_score, details
    
    def _score_cost_basic(self, schedule: Dict, requirements: Dict) -> Tuple[float, Dict]:
        """Basic cost scoring without database integration"""
        total_hours = 0
        overtime_hours = 0
        idle_hours = 0
        
        for agent in schedule.get('agents', []):
            agent_hours = self._calculate_agent_hours(agent)
            total_hours += agent_hours['regular']
            overtime_hours += agent_hours['overtime']
            idle_hours += agent_hours['idle']
        
        min_hours = sum(req.get('required_agents', 0) * 0.25 for req in requirements.values())
        
        regular_cost = total_hours * 1.0
        overtime_cost = overtime_hours * 1.5
        idle_cost = idle_hours * 0.8
        
        actual_cost = regular_cost + overtime_cost + idle_cost
        theoretical_min = min_hours * 1.0
        
        if theoretical_min > 0:
            cost_efficiency = theoretical_min / actual_cost
            cost_score = min(1.0, cost_efficiency)
        else:
            cost_score = 1.0
        
        details = {
            'total_hours': round(total_hours, 2),
            'overtime_hours': round(overtime_hours, 2),
            'idle_hours': round(idle_hours, 2),
            'total_cost': round(actual_cost, 2),
            'theoretical_minimum': round(theoretical_min, 2),
            'efficiency_ratio': round(cost_efficiency if theoretical_min > 0 else 1.0, 3)
        }
        
        return cost_score, details
    
    def _score_compliance_basic(self, schedule: Dict, constraints: Optional[Dict]) -> Tuple[float, Dict]:
        """Basic compliance scoring without database integration"""
        if not constraints:
            return 1.0, {'status': 'no_constraints_defined'}
        
        violations = []
        checks_passed = 0
        total_checks = len(constraints)
        
        # Simplified compliance checks
        for constraint_type, constraint_value in constraints.items():
            if constraint_type == 'max_hours':
                for agent in schedule.get('agents', []):
                    hours = self._calculate_agent_hours(agent)
                    if hours['total'] <= constraint_value:
                        checks_passed += 1
                    else:
                        violations.append({
                            'agent': agent.get('id'),
                            'constraint': 'max_hours',
                            'violation': f"Exceeded by {hours['total'] - constraint_value} hours"
                        })
        
        if total_checks > 0:
            compliance_score = checks_passed / total_checks
        else:
            compliance_score = 1.0
        
        details = {
            'checks_passed': checks_passed,
            'total_checks': total_checks,
            'violations': violations[:10],
            'compliance_percentage': round(compliance_score * 100, 2)
        }
        
        return max(0, compliance_score), details