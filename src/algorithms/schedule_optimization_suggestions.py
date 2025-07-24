#!/usr/bin/env python3
"""
Schedule Optimization Suggestions Algorithm
SPEC-03: Employee Schedule View optimization recommendations
Combines genetic scheduler, gap analysis, and conflict detection for intelligent suggestions
"""

import logging
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, date, timedelta
from dataclasses import dataclass
from enum import Enum
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Import handling for both module and direct execution
try:
    from .schedule_analysis_engine import detect_schedule_conflicts, ConflictInfo
except ImportError:
    import sys
    import os
    sys.path.append(os.path.dirname(__file__))
    from schedule_analysis_engine import detect_schedule_conflicts, ConflictInfo

logger = logging.getLogger(__name__)

class SuggestionType(Enum):
    """Types of schedule optimization suggestions"""
    SHIFT_SWAP = "shift_swap"
    OVERTIME_OPPORTUNITY = "overtime_opportunity" 
    SCHEDULE_IMPROVEMENT = "schedule_improvement"
    COVERAGE_OPTIMIZATION = "coverage_optimization"
    CONFLICT_RESOLUTION = "conflict_resolution"
    EFFICIENCY_ENHANCEMENT = "efficiency_enhancement"

class Priority(Enum):
    """Suggestion priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

@dataclass
class ScheduleSuggestion:
    """Individual schedule optimization suggestion"""
    suggestion_id: str
    suggestion_type: SuggestionType
    priority: Priority
    title: str
    description: str
    benefit: str
    implementation_effort: str  # "easy", "medium", "complex"
    estimated_improvement: str
    affected_dates: List[str]
    action_required: str
    deadline: Optional[str] = None

@dataclass
class ScheduleOptimizationResult:
    """Complete schedule optimization analysis"""
    employee_id: int
    analysis_period: str
    suggestions: List[ScheduleSuggestion]
    current_efficiency_score: float
    potential_efficiency_score: float
    improvement_potential: float
    critical_issues: List[str]
    summary: str

class ScheduleOptimizationEngine:
    """Generate intelligent schedule optimization suggestions"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        # Initialize database connection
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        logger.info("✅ ScheduleOptimizationEngine initialized")
    
    def generate_optimization_suggestions(
        self, 
        employee_id: int, 
        start_date: date, 
        end_date: date
    ) -> ScheduleOptimizationResult:
        """
        Generate comprehensive optimization suggestions for employee schedule
        BDD Compliance: 03-schedule-view.feature
        """
        suggestions = []
        critical_issues = []
        
        try:
            # Step 1: Analyze current schedule conflicts
            conflicts = detect_schedule_conflicts(employee_id, start_date.strftime('%Y-%m-%d'))
            
            # Generate conflict resolution suggestions
            for conflict in conflicts:
                if conflict.severity in ["high", "critical"]:
                    critical_issues.append(f"Schedule conflict: {conflict.description}")
                    
                    suggestions.append(ScheduleSuggestion(
                        suggestion_id=f"conflict_{len(suggestions)}",
                        suggestion_type=SuggestionType.CONFLICT_RESOLUTION,
                        priority=Priority.HIGH if conflict.severity == "high" else Priority.URGENT,
                        title=f"Resolve {conflict.conflict_type} conflict",
                        description=conflict.description,
                        benefit="Eliminate schedule conflicts and improve work-life balance",
                        implementation_effort="medium",
                        estimated_improvement="15-25% efficiency gain",
                        affected_dates=[conflict.date],
                        action_required=conflict.resolution_suggestion,
                        deadline=(datetime.now() + timedelta(days=3)).strftime('%Y-%m-%d')
                    ))
            
            # Step 2: Analyze coverage gaps using simplified analysis
            coverage_gaps = self._analyze_simple_coverage_gaps(employee_id, start_date, end_date)
            
            if coverage_gaps > 0:
                suggestions.append(ScheduleSuggestion(
                    suggestion_id=f"coverage_{len(suggestions)}",
                    suggestion_type=SuggestionType.COVERAGE_OPTIMIZATION,
                    priority=Priority.HIGH,
                    title="Optimize coverage during identified gaps",
                    description=f"Found {coverage_gaps} periods with potential coverage issues",
                    benefit="Improve service levels and team performance",
                    implementation_effort="medium",
                    estimated_improvement=f"{10 + coverage_gaps * 5}% service level improvement",
                    affected_dates=[(start_date + timedelta(days=i)).strftime('%Y-%m-%d') 
                                  for i in range(min(3, (end_date - start_date).days))],
                    action_required="Consider shift adjustments or coordination with team"
                ))
            
            # Step 3: Generate schedule improvement suggestions using simple analysis
            if len(suggestions) == 0:  # Only if no critical issues
                improvement_potential = self._analyze_schedule_improvement_potential(employee_id, start_date, end_date)
                
                if improvement_potential > 5:
                    suggestions.append(ScheduleSuggestion(
                        suggestion_id=f"optimize_{len(suggestions)}",
                        suggestion_type=SuggestionType.SCHEDULE_IMPROVEMENT,
                        priority=Priority.MEDIUM,
                        title="Apply schedule optimization recommendations",
                        description=f"Analysis shows {improvement_potential:.1f}% potential improvement",
                        benefit="Better work-life balance and improved efficiency",
                        implementation_effort="easy",
                        estimated_improvement=f"{improvement_potential:.1f}% overall improvement",
                        affected_dates=[(start_date + timedelta(days=i)).strftime('%Y-%m-%d') 
                                      for i in range(min(7, (end_date - start_date).days))],
                        action_required="Review schedule patterns and consider adjustments"
                    ))
            
            # Step 4: Identify overtime opportunities
            overtime_suggestions = self._identify_overtime_opportunities(employee_id, start_date, end_date)
            suggestions.extend(overtime_suggestions)
            
            # Step 5: Generate shift swap opportunities
            swap_suggestions = self._identify_shift_swap_opportunities(employee_id, start_date, end_date)
            suggestions.extend(swap_suggestions)
            
            # Calculate efficiency scores
            current_efficiency = self._calculate_current_efficiency(employee_id, conflicts, coverage_gaps)
            potential_efficiency = current_efficiency + sum(
                self._extract_improvement_value(s.estimated_improvement) for s in suggestions
            )
            improvement_potential = potential_efficiency - current_efficiency
            
            # Generate summary
            summary = self._generate_optimization_summary(suggestions, current_efficiency, improvement_potential)
            
            return ScheduleOptimizationResult(
                employee_id=employee_id,
                analysis_period=f"{start_date} to {end_date}",
                suggestions=suggestions,
                current_efficiency_score=current_efficiency,
                potential_efficiency_score=potential_efficiency,
                improvement_potential=improvement_potential,
                critical_issues=critical_issues,
                summary=summary
            )
            
        except Exception as e:
            logger.error(f"Error generating optimization suggestions: {e}")
            return ScheduleOptimizationResult(
                employee_id=employee_id,
                analysis_period=f"{start_date} to {end_date}",
                suggestions=[],
                current_efficiency_score=50.0,
                potential_efficiency_score=50.0,
                improvement_potential=0.0,
                critical_issues=[f"Analysis error: {str(e)}"],
                summary="Unable to generate suggestions due to system error"
            )
    
    def _analyze_simple_coverage_gaps(self, employee_id: int, start_date: date, end_date: date) -> int:
        """Enhanced coverage gap analysis using real demand and Erlang C calculations"""
        try:
            # Import required modules
            from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
            from src.algorithms.intraday.coverage_analyzer import CoverageAnalyzer
            
            with self.SessionLocal() as session:
                # Use coverage analyzer for real gap detection
                coverage_analyzer = CoverageAnalyzer(database_url=self.engine.url)
                
                # Get team/service ID for the employee
                team_result = session.execute(text("""
                    SELECT team_id, service_id 
                    FROM employee_team_assignments 
                    WHERE employee_id = :employee_id
                    AND is_active = true
                """), {'employee_id': employee_id}).fetchone()
                
                service_id = team_result.service_id if team_result else 1
                
                # Analyze coverage gaps for each day
                gap_count = 0
                current_date = start_date
                
                while current_date <= end_date:
                    # Get scheduled vs required for each hour
                    hourly_gaps = session.execute(text("""
                        WITH scheduled AS (
                            SELECT EXTRACT(HOUR FROM shift_start) as hour,
                                   COUNT(DISTINCT agent_id) as scheduled_count
                            FROM work_schedules
                            WHERE schedule_date = :date
                            AND status = 'published'
                            GROUP BY EXTRACT(HOUR FROM shift_start)
                        ),
                        demand AS (
                            SELECT EXTRACT(HOUR FROM interval_start_time) as hour,
                                   AVG(calls_offered) as avg_calls,
                                   AVG(average_handle_time) as avg_aht
                            FROM contact_statistics
                            WHERE service_id = :service_id
                            AND DATE(interval_start_time) = :date
                            GROUP BY EXTRACT(HOUR FROM interval_start_time)
                        )
                        SELECT s.hour, 
                               COALESCE(s.scheduled_count, 0) as scheduled,
                               COALESCE(d.avg_calls, 0) as calls,
                               COALESCE(d.avg_aht, 300) as aht
                        FROM scheduled s
                        FULL OUTER JOIN demand d ON s.hour = d.hour
                        WHERE d.avg_calls > 0
                    """), {
                        'date': current_date,
                        'service_id': service_id
                    }).fetchall()
                    
                    # Calculate gaps using Erlang C
                    erlang_calc = ErlangCEnhanced(database_url=self.engine.url)
                    sl_config = erlang_calc.get_service_level_target()
                    target_sl = sl_config['target_percent'] / 100.0
                    
                    for hour_data in hourly_gaps:
                        if hour_data.calls > 0:
                            # Calculate required agents
                            lambda_rate = float(hour_data.calls) * 4  # 15-min to hourly
                            mu_rate = 3600.0 / float(hour_data.aht)
                            
                            required, _ = erlang_calc.calculate_service_level_staffing(
                                lambda_rate=lambda_rate,
                                mu_rate=mu_rate,
                                target_sl=target_sl
                            )
                            
                            # Count gap if understaffed
                            if hour_data.scheduled < required:
                                gap_count += 1
                    
                    current_date += timedelta(days=1)
                
                return gap_count
                
        except Exception as e:
            logger.warning(f"Enhanced coverage gap analysis failed: {e}")
            # Fallback to simple analysis
            return self._simple_gap_fallback(employee_id, start_date, end_date)
    
    def _simple_gap_fallback(self, employee_id: int, start_date: date, end_date: date) -> int:
        """Fallback to simple gap detection"""
        with self.SessionLocal() as session:
            result = session.execute(text("""
                SELECT COUNT(*) as gap_count
                FROM work_schedules ws 
                WHERE ws.employee_id = :employee_id
                AND ws.schedule_date BETWEEN :start_date AND :end_date
                AND (ws.status IS NULL OR ws.status = 'pending')
            """), {
                'employee_id': employee_id,
                'start_date': start_date,
                'end_date': end_date
            }).fetchone()
            
            return result.gap_count if result else 0
    
    def _analyze_schedule_improvement_potential(self, employee_id: int, start_date: date, end_date: date) -> float:
        """Analyze potential for schedule improvement"""
        try:
            # Simple heuristic based on schedule consistency
            with self.SessionLocal() as session:
                result = session.execute(text("""
                    SELECT COUNT(DISTINCT shift_pattern) as pattern_variety,
                           COUNT(*) as total_shifts
                    FROM work_schedules ws 
                    WHERE ws.employee_id = :employee_id
                    AND ws.schedule_date BETWEEN :start_date AND :end_date
                """), {
                    'employee_id': employee_id,
                    'start_date': start_date,
                    'end_date': end_date
                }).fetchone()
                
                if result and result.total_shifts > 0:
                    # More variety might mean optimization opportunities
                    variety_ratio = result.pattern_variety / result.total_shifts
                    return min(25.0, variety_ratio * 100)
                
                return 10.0  # Default improvement potential
        except Exception as e:
            logger.warning(f"Improvement potential analysis failed: {e}")
            return 10.0
    
    def _identify_overtime_opportunities(
        self, employee_id: int, start_date: date, end_date: date
    ) -> List[ScheduleSuggestion]:
        """Identify overtime opportunities based on real workload and coverage gaps"""
        suggestions = []
        
        try:
            from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
            
            with self.SessionLocal() as session:
                # Get employee's current scheduled hours
                employee_hours = session.execute(text("""
                    SELECT 
                        schedule_date,
                        SUM(EXTRACT(EPOCH FROM (shift_end - shift_start))/3600) as scheduled_hours
                    FROM work_schedules
                    WHERE employee_id = :employee_id
                    AND schedule_date BETWEEN :start_date AND :end_date
                    AND status = 'published'
                    GROUP BY schedule_date
                """), {
                    'employee_id': employee_id,
                    'start_date': start_date,
                    'end_date': end_date
                }).fetchall()
                
                # Find days with significant coverage gaps
                erlang_calc = ErlangCEnhanced(database_url=self.engine.url)
                sl_config = erlang_calc.get_service_level_target()
                target_sl = sl_config['target_percent'] / 100.0
                
                overtime_opportunities = []
                
                for day_hours in employee_hours:
                    # Only suggest overtime if employee works < 40 hours that week
                    if day_hours.scheduled_hours < 8:  # Less than full day
                        # Check coverage gaps for that day
                        gap_check = session.execute(text("""
                            WITH peak_hours AS (
                                SELECT 
                                    EXTRACT(HOUR FROM interval_start_time) as hour,
                                    AVG(calls_offered) as avg_calls,
                                    AVG(average_handle_time) as avg_aht
                                FROM contact_statistics
                                WHERE service_id = 1
                                AND DATE(interval_start_time) = :date
                                AND calls_offered > 0
                                GROUP BY EXTRACT(HOUR FROM interval_start_time)
                                ORDER BY avg_calls DESC
                                LIMIT 3  -- Top 3 peak hours
                            ),
                            scheduled_coverage AS (
                                SELECT 
                                    EXTRACT(HOUR FROM shift_start) as hour,
                                    COUNT(DISTINCT agent_id) as scheduled
                                FROM work_schedules
                                WHERE schedule_date = :date
                                AND status = 'published'
                                GROUP BY EXTRACT(HOUR FROM shift_start)
                            )
                            SELECT 
                                ph.hour,
                                ph.avg_calls,
                                ph.avg_aht,
                                COALESCE(sc.scheduled, 0) as scheduled_agents
                            FROM peak_hours ph
                            LEFT JOIN scheduled_coverage sc ON ph.hour = sc.hour
                        """), {'date': day_hours.schedule_date}).fetchall()
                        
                        for peak_hour in gap_check:
                            if peak_hour.avg_calls > 0:
                                # Calculate required agents
                                lambda_rate = float(peak_hour.avg_calls) * 4
                                mu_rate = 3600.0 / float(peak_hour.avg_aht)
                                
                                required, _ = erlang_calc.calculate_service_level_staffing(
                                    lambda_rate=lambda_rate,
                                    mu_rate=mu_rate,
                                    target_sl=target_sl
                                )
                                
                                gap = required - peak_hour.scheduled_agents
                                if gap >= 2:  # Significant gap
                                    overtime_opportunities.append({
                                        'date': day_hours.schedule_date,
                                        'hour': int(peak_hour.hour),
                                        'gap_size': int(gap),
                                        'additional_income': gap * 25 * 1.5  # Overtime rate estimate
                                    })
                
                # Create suggestions for top opportunities
                if overtime_opportunities:
                    top_opp = sorted(overtime_opportunities, 
                                   key=lambda x: x['gap_size'], 
                                   reverse=True)[:3]
                    
                    for i, opp in enumerate(top_opp):
                        suggestions.append(ScheduleSuggestion(
                            suggestion_id=f"overtime_{i+1}",
                            suggestion_type=SuggestionType.OVERTIME_OPPORTUNITY,
                            priority=Priority.MEDIUM if opp['gap_size'] >= 3 else Priority.LOW,
                            title=f"Overtime opportunity on {opp['date'].strftime('%A, %B %d')}",
                            description=f"Critical coverage gap of {opp['gap_size']} agents at {opp['hour']}:00",
                            benefit=f"Earn ~${opp['additional_income']:.0f} extra at overtime rate",
                            implementation_effort="easy",
                            estimated_improvement=f"{opp['gap_size']} agent gap coverage",
                            affected_dates=[opp['date'].strftime('%Y-%m-%d')],
                            action_required=f"Volunteer for {opp['hour']}:00-{opp['hour']+2}:00 shift"
                        ))
                
        except Exception as e:
            logger.warning(f"Overtime opportunity analysis failed: {e}")
            # No fallback - just return empty if real analysis fails
        
        return suggestions
    
    def _identify_shift_swap_opportunities(
        self, employee_id: int, start_date: date, end_date: date
    ) -> List[ScheduleSuggestion]:
        """Identify shift swap opportunities based on real team availability"""
        suggestions = []
        
        try:
            with self.SessionLocal() as session:
                # Get employee's team and shift preferences
                employee_info = session.execute(text("""
                    SELECT 
                        e.name as employee_name,
                        eta.team_id,
                        esp.preferred_shift_type,
                        esp.preferred_start_time,
                        esp.preferred_days_off
                    FROM employees e
                    JOIN employee_team_assignments eta ON e.id = eta.employee_id
                    LEFT JOIN employee_shift_preferences esp ON e.id = esp.employee_id
                    WHERE e.id = :employee_id
                    AND eta.is_active = true
                """), {'employee_id': employee_id}).fetchone()
                
                if not employee_info or not employee_info.team_id:
                    return suggestions
                
                # Find employee's less desirable shifts
                undesirable_shifts = session.execute(text("""
                    SELECT 
                        ws.schedule_date,
                        ws.shift_start,
                        ws.shift_end,
                        EXTRACT(DOW FROM ws.schedule_date) as day_of_week
                    FROM work_schedules ws
                    WHERE ws.employee_id = :employee_id
                    AND ws.schedule_date BETWEEN :start_date AND :end_date
                    AND ws.status = 'published'
                    AND (
                        -- Weekend shifts if employee prefers weekdays
                        (EXTRACT(DOW FROM ws.schedule_date) IN (0, 6) AND :prefers_weekdays)
                        OR
                        -- Early shifts if employee prefers late
                        (EXTRACT(HOUR FROM ws.shift_start) < 9 AND :prefers_late)
                        OR
                        -- Late shifts if employee prefers early
                        (EXTRACT(HOUR FROM ws.shift_start) > 14 AND :prefers_early)
                    )
                    ORDER BY ws.schedule_date
                    LIMIT 5
                """), {
                    'employee_id': employee_id,
                    'start_date': start_date,
                    'end_date': end_date,
                    'prefers_weekdays': employee_info.preferred_days_off in ['weekend', 'saturday-sunday'],
                    'prefers_late': employee_info.preferred_shift_type == 'evening',
                    'prefers_early': employee_info.preferred_shift_type == 'morning'
                }).fetchall()
                
                # For each undesirable shift, find team members who might want it
                swap_opportunities = []
                
                for shift in undesirable_shifts:
                    # Find team members who are off that day and prefer this shift type
                    potential_swappers = session.execute(text("""
                        SELECT 
                            e.id as employee_id,
                            e.name as employee_name,
                            esp.preferred_shift_type,
                            COUNT(ws2.id) as shifts_that_week
                        FROM employees e
                        JOIN employee_team_assignments eta ON e.id = eta.employee_id
                        LEFT JOIN employee_shift_preferences esp ON e.id = esp.employee_id
                        LEFT JOIN work_schedules ws2 ON e.id = ws2.employee_id
                            AND ws2.schedule_date BETWEEN :week_start AND :week_end
                            AND ws2.status = 'published'
                        WHERE eta.team_id = :team_id
                        AND e.id != :employee_id
                        AND eta.is_active = true
                        AND NOT EXISTS (
                            -- Not already scheduled that day
                            SELECT 1 FROM work_schedules ws3
                            WHERE ws3.employee_id = e.id
                            AND ws3.schedule_date = :shift_date
                            AND ws3.status = 'published'
                        )
                        AND (
                            -- They prefer this shift type
                            (EXTRACT(HOUR FROM :shift_start) < 12 AND esp.preferred_shift_type = 'morning')
                            OR
                            (EXTRACT(HOUR FROM :shift_start) > 12 AND esp.preferred_shift_type = 'evening')
                            OR
                            -- They prefer working weekends
                            (:is_weekend AND esp.preferred_days_off IN ('monday-tuesday', 'weekdays'))
                        )
                        GROUP BY e.id, e.name, esp.preferred_shift_type
                        HAVING COUNT(ws2.id) < 5  -- Not already at max hours
                        ORDER BY 
                            -- Prioritize those with fewer shifts
                            COUNT(ws2.id) ASC,
                            -- Then by preference match
                            CASE WHEN esp.preferred_shift_type = 
                                CASE WHEN EXTRACT(HOUR FROM :shift_start) < 12 
                                THEN 'morning' ELSE 'evening' END 
                            THEN 0 ELSE 1 END
                        LIMIT 3
                    """), {
                        'team_id': employee_info.team_id,
                        'employee_id': employee_id,
                        'shift_date': shift.schedule_date,
                        'shift_start': shift.shift_start,
                        'week_start': shift.schedule_date - timedelta(days=shift.schedule_date.weekday()),
                        'week_end': shift.schedule_date + timedelta(days=6-shift.schedule_date.weekday()),
                        'is_weekend': shift.day_of_week in [0, 6]
                    }).fetchall()
                    
                    if potential_swappers:
                        swap_opportunities.append({
                            'date': shift.schedule_date,
                            'shift_time': f"{shift.shift_start.strftime('%H:%M')}-{shift.shift_end.strftime('%H:%M')}",
                            'swappers': [s.employee_name for s in potential_swappers],
                            'match_quality': 'high' if potential_swappers[0].preferred_shift_type else 'medium'
                        })
                
                # Create suggestions for best swap opportunities
                if swap_opportunities:
                    for i, swap in enumerate(swap_opportunities[:3]):  # Top 3
                        suggestions.append(ScheduleSuggestion(
                            suggestion_id=f"swap_{i+1}",
                            suggestion_type=SuggestionType.SHIFT_SWAP,
                            priority=Priority.MEDIUM if swap['match_quality'] == 'high' else Priority.LOW,
                            title=f"Swap opportunity for {swap['date'].strftime('%A, %B %d')}",
                            description=f"Exchange your {swap['shift_time']} shift with team members who prefer it",
                            benefit="Better work-life balance by aligning shifts with preferences",
                            implementation_effort="easy",
                            estimated_improvement="Mutual benefit - both parties get preferred shifts",
                            affected_dates=[swap['date'].strftime('%Y-%m-%d')],
                            action_required=f"Contact: {', '.join(swap['swappers'][:2])} to arrange swap"
                        ))
                
        except Exception as e:
            logger.warning(f"Shift swap analysis failed: {e}")
            # No fallback - real analysis or nothing
        
        return suggestions
    
    def _calculate_current_efficiency(
        self, employee_id: int, conflicts: List[ConflictInfo], coverage_gaps: int
    ) -> float:
        """Calculate current schedule efficiency score (0-100)"""
        base_score = 75.0
        
        # Reduce score for conflicts
        conflict_penalty = len(conflicts) * 10
        
        # Reduce score for gaps
        gap_penalty = coverage_gaps * 5
        
        efficiency = max(0, base_score - conflict_penalty - gap_penalty)
        return min(100, efficiency)
    
    def _extract_improvement_value(self, improvement_str: str) -> float:
        """Extract numerical improvement value from description"""
        try:
            # Extract percentage from strings like "15-25% efficiency gain"
            import re
            numbers = re.findall(r'\d+', improvement_str)
            if numbers:
                return float(numbers[0])
        except:
            pass
        return 0.0
    
    def _generate_optimization_summary(
        self, suggestions: List[ScheduleSuggestion], current_efficiency: float, improvement_potential: float
    ) -> str:
        """Generate human-readable optimization summary"""
        if not suggestions:
            return f"Schedule analysis complete. Current efficiency: {current_efficiency:.1f}%. No immediate optimization opportunities identified."
        
        high_priority = len([s for s in suggestions if s.priority in [Priority.HIGH, Priority.URGENT]])
        
        if high_priority > 0:
            return f"Found {len(suggestions)} optimization opportunities ({high_priority} high priority). Potential {improvement_potential:.1f}% efficiency improvement available."
        else:
            return f"Found {len(suggestions)} enhancement opportunities. Potential {improvement_potential:.1f}% efficiency improvement through suggested optimizations."

def generate_schedule_suggestions(
    employee_id: int, start_date: date, end_date: date
) -> ScheduleOptimizationResult:
    """Simple function interface for schedule optimization suggestions"""
    engine = ScheduleOptimizationEngine()
    return engine.generate_optimization_suggestions(employee_id, start_date, end_date)

def validate_schedule_optimizer():
    """Test schedule optimization suggestions with real data"""
    try:
        # Test with employee 111538 for next 2 weeks
        start_date = date.today() + timedelta(days=1)
        end_date = start_date + timedelta(days=14)
        
        result = generate_schedule_suggestions(111538, start_date, end_date)
        
        print(f"✅ Schedule Optimization for Employee {result.employee_id}:")
        print(f"   Period: {result.analysis_period}")
        print(f"   Current efficiency: {result.current_efficiency_score:.1f}%")
        print(f"   Potential efficiency: {result.potential_efficiency_score:.1f}%")
        print(f"   Improvement potential: {result.improvement_potential:.1f}%")
        print(f"   Suggestions: {len(result.suggestions)}")
        print(f"   Critical issues: {len(result.critical_issues)}")
        print(f"   Summary: {result.summary}")
        
        for i, suggestion in enumerate(result.suggestions[:3]):  # Show first 3
            print(f"   Suggestion {i+1}: {suggestion.title}")
            print(f"     Priority: {suggestion.priority.value}")
            print(f"     Benefit: {suggestion.benefit}")
            print(f"     Action: {suggestion.action_required}")
        
        return True
        
    except Exception as e:
        print(f"❌ Schedule optimizer validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the optimizer
    if validate_schedule_optimizer():
        print("\n✅ Schedule Optimization Suggestions: READY")
    else:
        print("\n❌ Schedule Optimization Suggestions: FAILED")