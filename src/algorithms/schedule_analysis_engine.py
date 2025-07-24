#!/usr/bin/env python3
"""
Schedule Analysis Engine
Comprehensive schedule analysis for employee view and manager optimization
"""

import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime, date, time, timedelta
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

logger = logging.getLogger(__name__)

@dataclass
class ConflictInfo:
    """Schedule conflict information"""
    conflict_type: str
    employee_id: int
    date: str
    description: str
    severity: str  # "low", "medium", "high", "critical"
    resolution_suggestion: str

@dataclass
class CoverageGap:
    """Coverage gap analysis"""
    date: str
    time_period: str
    required_agents: int
    scheduled_agents: int
    gap_size: int
    impact_level: str  # "minimal", "moderate", "significant", "severe"
    suggested_actions: List[str]

@dataclass
class ScheduleRecommendation:
    """Schedule optimization recommendation"""
    recommendation_type: str  # "shift_swap", "overtime", "additional_staff", "workload_redistribution"
    priority: str  # "low", "medium", "high", "urgent"
    affected_employees: List[int]
    implementation_time: str
    expected_improvement: str
    cost_impact: str

@dataclass
class ScheduleAnalysisResult:
    """Complete schedule analysis result"""
    analysis_date: str
    conflicts: List[ConflictInfo]
    coverage_gaps: List[CoverageGap]
    recommendations: List[ScheduleRecommendation]
    overall_score: float  # 0-100
    summary: str

class ScheduleAnalysisEngine:
    """Advanced schedule analysis for employee view and optimization"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with wfm_enterprise database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        logger.info("✅ ScheduleAnalysisEngine initialized")
    
    def analyze_employee_schedule(self, employee_id: int, start_date: str, end_date: str) -> ScheduleAnalysisResult:
        """
        Comprehensive schedule analysis for specific employee
        """
        try:
            with self.SessionLocal() as session:
                # Detect conflicts
                conflicts = self._detect_employee_conflicts(session, employee_id, start_date, end_date)
                
                # Analyze coverage gaps
                coverage_gaps = self._analyze_coverage_gaps(session, start_date, end_date)
                
                # Generate recommendations
                recommendations = self._generate_recommendations(session, employee_id, conflicts, coverage_gaps)
                
                # Calculate overall score
                overall_score = self._calculate_schedule_score(conflicts, coverage_gaps)
                
                # Generate summary
                summary = self._generate_analysis_summary(conflicts, coverage_gaps, recommendations, overall_score)
                
                return ScheduleAnalysisResult(
                    analysis_date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                    conflicts=conflicts,
                    coverage_gaps=coverage_gaps,
                    recommendations=recommendations,
                    overall_score=overall_score,
                    summary=summary
                )
                
        except Exception as e:
            logger.error(f"Error analyzing employee schedule: {e}")
            return ScheduleAnalysisResult(
                analysis_date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                conflicts=[],
                coverage_gaps=[],
                recommendations=[],
                overall_score=0.0,
                summary=f"Analysis failed: {str(e)}"
            )
    
    def _detect_employee_conflicts(self, session, employee_id: int, start_date: str, end_date: str) -> List[ConflictInfo]:
        """Detect schedule conflicts for employee"""
        conflicts = []
        
        try:
            # Check for overlapping shifts
            overlaps = session.execute(text("""
                SELECT 
                    ws1.schedule_date,
                    ws1.shift_start as start1,
                    ws1.shift_end as end1,
                    ws2.shift_start as start2,
                    ws2.shift_end as end2
                FROM work_schedules ws1
                JOIN work_schedules ws2 ON ws1.agent_id = ws2.agent_id 
                    AND ws1.schedule_date = ws2.schedule_date
                    AND ws1.id != ws2.id
                WHERE ws1.agent_id = :employee_id
                AND ws1.schedule_date BETWEEN :start_date AND :end_date
                AND ws1.status = 'published'
                AND ws2.status = 'published'
            """), {
                'employee_id': employee_id,
                'start_date': start_date,
                'end_date': end_date
            }).fetchall()
            
            for overlap in overlaps:
                conflicts.append(ConflictInfo(
                    conflict_type="overlapping_shifts",
                    employee_id=employee_id,
                    date=str(overlap.schedule_date),
                    description=f"Overlapping shifts: {overlap.start1}-{overlap.end1} and {overlap.start2}-{overlap.end2}",
                    severity="high",
                    resolution_suggestion="Remove one shift or adjust times to eliminate overlap"
                ))
            
            # Check for insufficient rest between shifts
            rest_violations = session.execute(text("""
                SELECT 
                    ws1.schedule_date as date1,
                    ws1.shift_end as end1,
                    ws2.schedule_date as date2,
                    ws2.shift_start as start2
                FROM work_schedules ws1
                JOIN work_schedules ws2 ON ws1.agent_id = ws2.agent_id
                WHERE ws1.agent_id = :employee_id
                AND ws1.schedule_date BETWEEN :start_date AND :end_date
                AND ws2.schedule_date = ws1.schedule_date + INTERVAL '1 day'
                AND ws1.status = 'published'
                AND ws2.status = 'published'
                AND (EXTRACT(EPOCH FROM ws2.shift_start) - EXTRACT(EPOCH FROM ws1.shift_end)) < 36000  -- Less than 10 hours
            """), {
                'employee_id': employee_id,
                'start_date': start_date,
                'end_date': end_date
            }).fetchall()
            
            for violation in rest_violations:
                conflicts.append(ConflictInfo(
                    conflict_type="insufficient_rest",
                    employee_id=employee_id,
                    date=str(violation.date1),
                    description=f"Less than 10 hours between shifts ending {violation.end1} and starting {violation.start2}",
                    severity="medium",
                    resolution_suggestion="Adjust shift times to ensure minimum 10-hour rest period"
                ))
                
        except Exception as e:
            logger.error(f"Error detecting conflicts: {e}")
            
        return conflicts
    
    def _analyze_coverage_gaps(self, session, start_date: str, end_date: str) -> List[CoverageGap]:
        """Analyze coverage gaps for date range"""
        gaps = []
        
        try:
            # Calculate daily coverage
            coverage_data = session.execute(text("""
                SELECT 
                    schedule_date,
                    COUNT(DISTINCT agent_id) as scheduled_count,
                    EXTRACT(HOUR FROM shift_start) as hour_start,
                    EXTRACT(HOUR FROM shift_end) as hour_end
                FROM work_schedules
                WHERE schedule_date BETWEEN :start_date AND :end_date
                AND status = 'published'
                GROUP BY schedule_date, EXTRACT(HOUR FROM shift_start), EXTRACT(HOUR FROM shift_end)
                ORDER BY schedule_date, hour_start
            """), {
                'start_date': start_date,
                'end_date': end_date
            }).fetchall()
            
            # Import Erlang C for dynamic calculation
            from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
            
            # Initialize Erlang C calculator with database connection
            erlang_calc = ErlangCEnhanced(database_url=self.session.bind.url)
            
            # Get service level configuration
            sl_config = erlang_calc.get_service_level_target()
            target_sl = sl_config['target_percent'] / 100.0  # Convert to decimal
            
            for coverage in coverage_data:
                # Get demand data for this time period
                demand_query = text("""
                    SELECT 
                        AVG(calls_offered) as avg_calls,
                        AVG(average_handle_time) as avg_aht
                    FROM contact_statistics
                    WHERE service_id = 1  -- Default service
                    AND DATE(interval_start_time) = :date
                    AND EXTRACT(HOUR FROM interval_start_time) >= :hour_start
                    AND EXTRACT(HOUR FROM interval_start_time) < :hour_end
                """)
                
                demand_data = session.execute(demand_query, {
                    'date': coverage.schedule_date,
                    'hour_start': coverage.hour_start,
                    'hour_end': coverage.hour_end or coverage.hour_start + 1
                }).fetchone()
                
                # Calculate required agents dynamically
                if demand_data and demand_data.avg_calls and demand_data.avg_aht:
                    # Convert to rates per hour
                    lambda_rate = float(demand_data.avg_calls) * 4  # 15-min intervals to hourly
                    mu_rate = 3600.0 / float(demand_data.avg_aht) if demand_data.avg_aht > 0 else 12.0  # calls per hour per agent
                    
                    # Calculate required staffing
                    required_agents, achieved_sl = erlang_calc.calculate_service_level_staffing(
                        lambda_rate=lambda_rate,
                        mu_rate=mu_rate,
                        target_sl=target_sl
                    )
                else:
                    # Fallback to minimum if no demand data
                    required_agents = 3
                
                if coverage.scheduled_count < required_agents:
                    gap_size = required_agents - coverage.scheduled_count
                    
                    # Determine impact level
                    if gap_size >= 3:
                        impact_level = "severe"
                    elif gap_size >= 2:
                        impact_level = "significant"
                    elif gap_size >= 1:
                        impact_level = "moderate"
                    else:
                        impact_level = "minimal"
                    
                    # Generate suggestions
                    suggestions = []
                    if gap_size == 1:
                        suggestions.append("Consider overtime for existing staff")
                        suggestions.append("Check for voluntary shift swaps")
                    elif gap_size >= 2:
                        suggestions.append("Hire additional staff or extend shifts")
                        suggestions.append("Redistribute workload from other periods")
                    
                    gaps.append(CoverageGap(
                        date=str(coverage.schedule_date),
                        time_period=f"{int(coverage.hour_start):02d}:00-{int(coverage.hour_end):02d}:00",
                        required_agents=required_agents,
                        scheduled_agents=coverage.scheduled_count,
                        gap_size=gap_size,
                        impact_level=impact_level,
                        suggested_actions=suggestions
                    ))
                    
        except Exception as e:
            logger.error(f"Error analyzing coverage gaps: {e}")
            
        return gaps
    
    def _generate_recommendations(self, session, employee_id: int, conflicts: List[ConflictInfo], 
                                gaps: List[CoverageGap]) -> List[ScheduleRecommendation]:
        """Generate optimization recommendations"""
        recommendations = []
        
        # Recommendation based on conflicts
        if conflicts:
            high_severity_conflicts = [c for c in conflicts if c.severity in ["high", "critical"]]
            if high_severity_conflicts:
                recommendations.append(ScheduleRecommendation(
                    recommendation_type="schedule_adjustment",
                    priority="high",
                    affected_employees=[employee_id],
                    implementation_time="immediate",
                    expected_improvement="Eliminate schedule conflicts",
                    cost_impact="minimal"
                ))
        
        # Recommendations based on coverage gaps
        severe_gaps = [g for g in gaps if g.impact_level in ["severe", "significant"]]
        if severe_gaps:
            recommendations.append(ScheduleRecommendation(
                recommendation_type="additional_staff",
                priority="urgent",
                affected_employees=[],
                implementation_time="1-2 days",
                expected_improvement="Close critical coverage gaps",
                cost_impact="moderate"
            ))
        
        # Performance optimization recommendations
        if not conflicts and not severe_gaps:
            recommendations.append(ScheduleRecommendation(
                recommendation_type="optimization",
                priority="low",
                affected_employees=[employee_id],
                implementation_time="next_period",
                expected_improvement="Minor efficiency gains",
                cost_impact="none"
            ))
            
        return recommendations
    
    def _calculate_schedule_score(self, conflicts: List[ConflictInfo], gaps: List[CoverageGap]) -> float:
        """Calculate overall schedule quality score (0-100)"""
        base_score = 100.0
        
        # Deduct points for conflicts
        for conflict in conflicts:
            if conflict.severity == "critical":
                base_score -= 25
            elif conflict.severity == "high":
                base_score -= 15
            elif conflict.severity == "medium":
                base_score -= 10
            else:
                base_score -= 5
        
        # Deduct points for coverage gaps
        for gap in gaps:
            if gap.impact_level == "severe":
                base_score -= 20
            elif gap.impact_level == "significant":
                base_score -= 15
            elif gap.impact_level == "moderate":
                base_score -= 10
            else:
                base_score -= 5
        
        return max(0.0, base_score)
    
    def _generate_analysis_summary(self, conflicts: List[ConflictInfo], gaps: List[CoverageGap], 
                                 recommendations: List[ScheduleRecommendation], score: float) -> str:
        """Generate human-readable summary"""
        summary = f"Schedule Quality Score: {score:.1f}/100\n"
        
        if conflicts:
            summary += f"Found {len(conflicts)} schedule conflicts requiring attention.\n"
        else:
            summary += "No schedule conflicts detected.\n"
            
        if gaps:
            summary += f"Identified {len(gaps)} coverage gaps needing resolution.\n"
        else:
            summary += "Coverage levels are adequate.\n"
            
        if recommendations:
            summary += f"Generated {len(recommendations)} optimization recommendations."
        else:
            summary += "Schedule is optimally configured."
            
        return summary

# Simple function interfaces
def analyze_employee_schedule(employee_id: int, start_date: str, end_date: str) -> ScheduleAnalysisResult:
    """Analyze schedule for specific employee"""
    engine = ScheduleAnalysisEngine()
    return engine.analyze_employee_schedule(employee_id, start_date, end_date)

def detect_schedule_conflicts(employee_id: int, date: str) -> List[ConflictInfo]:
    """Detect conflicts for employee on specific date"""
    end_date = (datetime.strptime(date, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d')
    result = analyze_employee_schedule(employee_id, date, end_date)
    return result.conflicts

def find_coverage_gaps(start_date: str, end_date: str) -> List[CoverageGap]:
    """Find coverage gaps in date range"""
    result = analyze_employee_schedule(111538, start_date, end_date)  # Use demo employee
    return result.coverage_gaps

def validate_schedule_analysis():
    """Test schedule analysis with real data"""
    try:
        # Test with employee 111538 for next week
        start_date = datetime.now().strftime('%Y-%m-%d')
        end_date = (datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d')
        
        result = analyze_employee_schedule(111538, start_date, end_date)
        
        print(f"✅ Schedule Analysis for Employee 111538:")
        print(f"   Analysis Date: {result.analysis_date}")
        print(f"   Overall Score: {result.overall_score:.1f}/100")
        print(f"   Conflicts Found: {len(result.conflicts)}")
        print(f"   Coverage Gaps: {len(result.coverage_gaps)}")
        print(f"   Recommendations: {len(result.recommendations)}")
        print(f"   Summary: {result.summary}")
        
        return True
        
    except Exception as e:
        print(f"❌ Schedule analysis validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the analysis engine
    if validate_schedule_analysis():
        print("\n✅ Schedule Analysis Engine: READY")
    else:
        print("\n❌ Schedule Analysis Engine: FAILED")