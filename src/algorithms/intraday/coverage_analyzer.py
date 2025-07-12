#!/usr/bin/env python3
"""
Coverage Analyzer for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Analyze Timetable Coverage and Statistics, Coverage Analysis
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from scipy import stats

logger = logging.getLogger(__name__)

class CoverageStatus(Enum):
    """Coverage status levels"""
    OPTIMAL = "optimal"      # Green: 95-105% of required
    ADEQUATE = "adequate"    # Yellow: 85-95% of required
    SHORTAGE = "shortage"    # Red: < 85% of required
    SURPLUS = "surplus"      # Grey: > 105% of required

class MetricType(Enum):
    """Types of metrics to analyze"""
    COVERAGE_PERCENTAGE = "coverage_percentage"
    SERVICE_LEVEL = "service_level"
    UTILIZATION_RATE = "utilization_rate"
    ABSENCE_RATE = "absence_rate"
    PRODUCTIVITY = "productivity"

@dataclass
class IntervalCoverage:
    """Coverage data for a specific time interval"""
    datetime: datetime
    interval_start: time
    interval_end: time
    forecast_agents: float
    planned_agents: int
    available_agents: int
    coverage_percentage: float
    coverage_status: CoverageStatus
    service_level_projection: float
    gap_size: float

@dataclass
class CoverageGap:
    """Identified coverage gap requiring attention"""
    start_time: datetime
    end_time: datetime
    severity: str  # critical, high, medium, low
    agents_short: float
    impact_on_service_level: float
    recommended_actions: List[str]

@dataclass
class UtilizationMetrics:
    """Utilization metrics for analysis"""
    employee_id: str
    scheduled_hours: float
    productive_hours: float
    break_hours: float
    utilization_rate: float
    productivity_score: float

@dataclass
class CoverageStatistics:
    """Comprehensive coverage statistics"""
    period_start: datetime
    period_end: datetime
    average_coverage: float
    min_coverage: float
    max_coverage: float
    coverage_gaps: List[CoverageGap]
    service_level_forecast: float
    utilization_summary: Dict[str, float]
    recommendations: List[str]

class CoverageAnalyzer:
    """Analyze timetable coverage and provide insights"""
    
    def __init__(self):
        self.forecast_data: Dict[datetime, float] = {}
        self.planned_coverage: Dict[datetime, int] = {}
        self.interval_coverage: List[IntervalCoverage] = []
        self.coverage_gaps: List[CoverageGap] = []
        self.utilization_metrics: Dict[str, UtilizationMetrics] = {}
        
    def analyze_coverage(self,
                        forecast_data: List[Dict[str, Any]],
                        timetable_blocks: List[Dict[str, Any]],
                        analysis_period: Tuple[datetime, datetime]) -> CoverageStatistics:
        """Analyze coverage for the specified period"""
        # Process forecast data
        self._process_forecast_data(forecast_data)
        
        # Process timetable data
        self._process_timetable_data(timetable_blocks, analysis_period)
        
        # Calculate interval coverage
        self._calculate_interval_coverage(analysis_period)
        
        # Identify coverage gaps
        self._identify_coverage_gaps()
        
        # Calculate utilization metrics
        self._calculate_utilization_metrics(timetable_blocks, analysis_period)
        
        # Generate statistics
        statistics = self._generate_coverage_statistics(analysis_period)
        
        return statistics
    
    def _process_forecast_data(self, forecast_data: List[Dict[str, Any]]):
        """Process forecast data into internal format"""
        self.forecast_data = {}
        
        for forecast in forecast_data:
            dt = forecast.get('datetime')
            required_agents = forecast.get('required_agents', 0)
            
            if dt:
                self.forecast_data[dt] = required_agents
    
    def _process_timetable_data(self, 
                               timetable_blocks: List[Dict[str, Any]],
                               analysis_period: Tuple[datetime, datetime]):
        """Process timetable data to calculate planned coverage"""
        self.planned_coverage = defaultdict(int)
        
        for block in timetable_blocks:
            block_time = block.get('datetime')
            activity_type = block.get('activity_type')
            
            if (block_time and 
                analysis_period[0] <= block_time <= analysis_period[1] and
                activity_type == 'work_attendance'):
                
                # Round to 15-minute interval
                interval_time = self._round_to_interval(block_time)
                self.planned_coverage[interval_time] += 1
    
    def _round_to_interval(self, dt: datetime, interval_minutes: int = 15) -> datetime:
        """Round datetime to nearest interval"""
        minutes = (dt.minute // interval_minutes) * interval_minutes
        return dt.replace(minute=minutes, second=0, microsecond=0)
    
    def _calculate_interval_coverage(self, analysis_period: Tuple[datetime, datetime]):
        """Calculate coverage for each interval"""
        self.interval_coverage = []
        
        current_time = self._round_to_interval(analysis_period[0])
        end_time = analysis_period[1]
        
        while current_time <= end_time:
            forecast_agents = self.forecast_data.get(current_time, 0)
            planned_agents = self.planned_coverage.get(current_time, 0)
            
            # Calculate coverage percentage
            if forecast_agents > 0:
                coverage_percentage = (planned_agents / forecast_agents) * 100
            else:
                coverage_percentage = 100 if planned_agents == 0 else float('inf')
            
            # Determine coverage status
            coverage_status = self._determine_coverage_status(coverage_percentage)
            
            # Project service level based on coverage
            service_level_projection = self._project_service_level(coverage_percentage)
            
            # Calculate gap size
            gap_size = max(0, forecast_agents - planned_agents)
            
            interval = IntervalCoverage(
                datetime=current_time,
                interval_start=current_time.time(),
                interval_end=(current_time + timedelta(minutes=15)).time(),
                forecast_agents=forecast_agents,
                planned_agents=planned_agents,
                available_agents=planned_agents,  # Simplified - would consider real-time availability
                coverage_percentage=coverage_percentage,
                coverage_status=coverage_status,
                service_level_projection=service_level_projection,
                gap_size=gap_size
            )
            
            self.interval_coverage.append(interval)
            current_time += timedelta(minutes=15)
    
    def _determine_coverage_status(self, coverage_percentage: float) -> CoverageStatus:
        """Determine coverage status based on percentage"""
        if 95 <= coverage_percentage <= 105:
            return CoverageStatus.OPTIMAL
        elif 85 <= coverage_percentage < 95:
            return CoverageStatus.ADEQUATE
        elif coverage_percentage < 85:
            return CoverageStatus.SHORTAGE
        else:
            return CoverageStatus.SURPLUS
    
    def _project_service_level(self, coverage_percentage: float) -> float:
        """Project service level based on coverage percentage"""
        # Simplified model: SL drops rapidly below 85% coverage
        if coverage_percentage >= 100:
            return 85.0  # Target 80/20 service level with buffer
        elif coverage_percentage >= 95:
            return 80.0 + (coverage_percentage - 95) * 1.0
        elif coverage_percentage >= 85:
            return 70.0 + (coverage_percentage - 85) * 1.0
        elif coverage_percentage >= 70:
            return 50.0 + (coverage_percentage - 70) * 1.33
        else:
            return max(20.0, coverage_percentage * 0.7)
    
    def _identify_coverage_gaps(self):
        """Identify periods with coverage gaps"""
        self.coverage_gaps = []
        
        current_gap = None
        
        for interval in self.interval_coverage:
            if interval.coverage_status == CoverageStatus.SHORTAGE:
                if current_gap is None:
                    # Start new gap
                    current_gap = {
                        'start': interval.datetime,
                        'end': interval.datetime + timedelta(minutes=15),
                        'intervals': [interval],
                        'total_shortage': interval.gap_size
                    }
                else:
                    # Extend current gap
                    current_gap['end'] = interval.datetime + timedelta(minutes=15)
                    current_gap['intervals'].append(interval)
                    current_gap['total_shortage'] += interval.gap_size
            else:
                if current_gap is not None:
                    # Close current gap
                    gap = self._create_coverage_gap(current_gap)
                    self.coverage_gaps.append(gap)
                    current_gap = None
        
        # Close any remaining gap
        if current_gap is not None:
            gap = self._create_coverage_gap(current_gap)
            self.coverage_gaps.append(gap)
    
    def _create_coverage_gap(self, gap_data: Dict[str, Any]) -> CoverageGap:
        """Create coverage gap object with analysis"""
        intervals = gap_data['intervals']
        avg_shortage = gap_data['total_shortage'] / len(intervals)
        avg_sl_impact = np.mean([i.service_level_projection for i in intervals])
        
        # Determine severity
        if avg_sl_impact < 50:
            severity = "critical"
        elif avg_sl_impact < 70:
            severity = "high"
        elif avg_sl_impact < 80:
            severity = "medium"
        else:
            severity = "low"
        
        # Generate recommendations
        recommendations = []
        if severity in ["critical", "high"]:
            recommendations.append("Immediate staffing adjustment required")
            recommendations.append("Consider overtime or calling in additional staff")
        if gap_data['end'] - gap_data['start'] > timedelta(hours=2):
            recommendations.append("Extended gap - consider schedule redistribution")
        if avg_shortage > 5:
            recommendations.append(f"Need {int(avg_shortage)} additional agents")
        
        return CoverageGap(
            start_time=gap_data['start'],
            end_time=gap_data['end'],
            severity=severity,
            agents_short=avg_shortage,
            impact_on_service_level=80.0 - avg_sl_impact,  # Impact vs target
            recommended_actions=recommendations
        )
    
    def _calculate_utilization_metrics(self,
                                     timetable_blocks: List[Dict[str, Any]],
                                     analysis_period: Tuple[datetime, datetime]):
        """Calculate utilization metrics by employee"""
        employee_metrics = defaultdict(lambda: {
            'scheduled_hours': 0,
            'productive_hours': 0,
            'break_hours': 0,
            'blocks': []
        })
        
        # Aggregate data by employee
        for block in timetable_blocks:
            employee_id = block.get('employee_id')
            block_time = block.get('datetime')
            activity_type = block.get('activity_type')
            
            if (employee_id and block_time and
                analysis_period[0] <= block_time <= analysis_period[1]):
                
                # Count 15-minute blocks as 0.25 hours
                employee_metrics[employee_id]['scheduled_hours'] += 0.25
                employee_metrics[employee_id]['blocks'].append(block)
                
                if activity_type in ['work_attendance', 'project_work', 'training']:
                    employee_metrics[employee_id]['productive_hours'] += 0.25
                elif activity_type in ['lunch_break', 'short_break']:
                    employee_metrics[employee_id]['break_hours'] += 0.25
        
        # Calculate utilization rates
        self.utilization_metrics = {}
        
        for employee_id, metrics in employee_metrics.items():
            if metrics['scheduled_hours'] > 0:
                utilization_rate = (metrics['productive_hours'] / metrics['scheduled_hours']) * 100
                
                # Simple productivity score (would use actual performance data)
                productivity_score = min(100, utilization_rate * 1.1)
                
                self.utilization_metrics[employee_id] = UtilizationMetrics(
                    employee_id=employee_id,
                    scheduled_hours=metrics['scheduled_hours'],
                    productive_hours=metrics['productive_hours'],
                    break_hours=metrics['break_hours'],
                    utilization_rate=utilization_rate,
                    productivity_score=productivity_score
                )
    
    def _generate_coverage_statistics(self, analysis_period: Tuple[datetime, datetime]) -> CoverageStatistics:
        """Generate comprehensive coverage statistics"""
        coverage_percentages = [i.coverage_percentage for i in self.interval_coverage]
        
        # Calculate average utilization
        utilization_rates = [u.utilization_rate for u in self.utilization_metrics.values()]
        avg_utilization = np.mean(utilization_rates) if utilization_rates else 0
        
        # Generate recommendations
        recommendations = []
        
        avg_coverage = np.mean(coverage_percentages) if coverage_percentages else 0
        if avg_coverage < 90:
            recommendations.append("Overall coverage below target - increase staffing")
        
        if len(self.coverage_gaps) > 5:
            recommendations.append("Multiple coverage gaps detected - review scheduling approach")
        
        critical_gaps = [g for g in self.coverage_gaps if g.severity == "critical"]
        if critical_gaps:
            recommendations.append(f"{len(critical_gaps)} critical gaps require immediate attention")
        
        if avg_utilization < 80:
            recommendations.append("Low utilization detected - optimize schedule efficiency")
        
        # Project overall service level
        sl_projections = [i.service_level_projection for i in self.interval_coverage]
        avg_sl_projection = np.mean(sl_projections) if sl_projections else 80.0
        
        return CoverageStatistics(
            period_start=analysis_period[0],
            period_end=analysis_period[1],
            average_coverage=avg_coverage,
            min_coverage=min(coverage_percentages) if coverage_percentages else 0,
            max_coverage=max(coverage_percentages) if coverage_percentages else 0,
            coverage_gaps=self.coverage_gaps,
            service_level_forecast=avg_sl_projection,
            utilization_summary={
                'average_utilization': avg_utilization,
                'employees_analyzed': len(self.utilization_metrics),
                'total_productive_hours': sum(u.productive_hours for u in self.utilization_metrics.values())
            },
            recommendations=recommendations
        )
    
    def visualize_coverage(self, output_path: Optional[str] = None) -> Dict[str, Any]:
        """Create visualization of coverage analysis"""
        if not self.interval_coverage:
            return {"error": "No coverage data to visualize"}
        
        # Prepare data for visualization
        times = [i.datetime for i in self.interval_coverage]
        forecast = [i.forecast_agents for i in self.interval_coverage]
        planned = [i.planned_agents for i in self.interval_coverage]
        coverage_pct = [i.coverage_percentage for i in self.interval_coverage]
        
        # Create color map for coverage status
        colors = []
        for interval in self.interval_coverage:
            if interval.coverage_status == CoverageStatus.OPTIMAL:
                colors.append('green')
            elif interval.coverage_status == CoverageStatus.ADEQUATE:
                colors.append('yellow')
            elif interval.coverage_status == CoverageStatus.SHORTAGE:
                colors.append('red')
            else:
                colors.append('grey')
        
        visualization_data = {
            'times': times,
            'forecast': forecast,
            'planned': planned,
            'coverage_percentage': coverage_pct,
            'status_colors': colors,
            'gaps': [
                {
                    'start': gap.start_time,
                    'end': gap.end_time,
                    'severity': gap.severity
                }
                for gap in self.coverage_gaps
            ]
        }
        
        # If matplotlib is available, create actual plot
        try:
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)
            
            # Plot 1: Agent count comparison
            ax1.plot(times, forecast, 'b-', label='Forecast', linewidth=2)
            ax1.plot(times, planned, 'g-', label='Planned', linewidth=2)
            ax1.fill_between(times, forecast, planned, 
                           where=[p < f for p, f in zip(planned, forecast)],
                           color='red', alpha=0.3, label='Shortage')
            ax1.set_ylabel('Number of Agents')
            ax1.set_title('Coverage Analysis: Forecast vs Planned')
            ax1.legend()
            ax1.grid(True, alpha=0.3)
            
            # Plot 2: Coverage percentage with color coding
            for i in range(len(times) - 1):
                ax2.fill_between(times[i:i+2], 0, coverage_pct[i:i+2],
                               color=colors[i], alpha=0.6)
            ax2.axhline(y=100, color='black', linestyle='--', alpha=0.5)
            ax2.axhline(y=85, color='orange', linestyle='--', alpha=0.5)
            ax2.set_ylabel('Coverage %')
            ax2.set_xlabel('Time')
            ax2.set_title('Coverage Percentage by Interval')
            ax2.grid(True, alpha=0.3)
            
            plt.tight_layout()
            
            if output_path:
                plt.savefig(output_path)
                visualization_data['plot_saved'] = output_path
            
            plt.close()
            
        except Exception as e:
            logger.warning(f"Could not create matplotlib visualization: {str(e)}")
        
        return visualization_data
    
    def get_real_time_coverage_status(self, current_time: datetime) -> Dict[str, Any]:
        """Get real-time coverage status for current interval"""
        interval_time = self._round_to_interval(current_time)
        
        # Find matching interval
        for interval in self.interval_coverage:
            if interval.datetime == interval_time:
                return {
                    'current_time': current_time,
                    'interval': interval_time,
                    'coverage_status': interval.coverage_status.value,
                    'coverage_percentage': interval.coverage_percentage,
                    'agents_required': interval.forecast_agents,
                    'agents_available': interval.available_agents,
                    'gap': interval.gap_size,
                    'service_level_projection': interval.service_level_projection,
                    'action_required': interval.coverage_status == CoverageStatus.SHORTAGE
                }
        
        return {
            'current_time': current_time,
            'interval': interval_time,
            'status': 'No data available'
        }
    
    def export_coverage_report(self) -> pd.DataFrame:
        """Export coverage analysis as DataFrame"""
        if not self.interval_coverage:
            return pd.DataFrame()
        
        data = []
        for interval in self.interval_coverage:
            data.append({
                'datetime': interval.datetime,
                'interval_start': interval.interval_start,
                'interval_end': interval.interval_end,
                'forecast_agents': interval.forecast_agents,
                'planned_agents': interval.planned_agents,
                'coverage_percentage': interval.coverage_percentage,
                'coverage_status': interval.coverage_status.value,
                'service_level_projection': interval.service_level_projection,
                'gap_size': interval.gap_size
            })
        
        return pd.DataFrame(data)