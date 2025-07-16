"""Transform complex algorithm outputs to simple UI formats"""

from typing import Dict, List, Any, Union, Optional
from datetime import datetime, date
from dataclasses import dataclass
import json


# Define the data models that algorithms use
@dataclass
class IntervalForecast:
    start_time: datetime
    end_time: datetime
    predicted_calls: float
    confidence_lower: float
    confidence_upper: float


@dataclass
class ForecastMetadata:
    confidence_score: float
    algorithm_version: str
    parameters: Dict[str, Any]


@dataclass
class ForecastOutput:
    forecast_date: date
    intervals: List[IntervalForecast]
    metadata: ForecastMetadata


@dataclass
class ShiftAssignment:
    employee_id: str
    shift_date: date
    shift_type: str
    start_time: datetime
    end_time: datetime
    skills: List[str]


@dataclass
class ScheduleOptimizationResult:
    assignments: List[ShiftAssignment]
    optimization_score: float
    coverage_analysis: Dict[str, Any]
    constraint_violations: List[str]


@dataclass
class MetricsAggregation:
    service_level: float
    avg_wait_time_seconds: float
    abandonment_rate: float
    agent_occupancy: float
    trend_direction: float
    interval_start: datetime
    interval_end: datetime


@dataclass
class GapAnalysisResult:
    gaps: List[Dict[str, Any]]
    total_gap_minutes: float
    severity_score: float
    recommendations: List[str]


class UITransformer:
    """Transform complex algorithm outputs to simple UI formats"""
    
    @staticmethod
    def transform_forecast(forecast_output: Union[ForecastOutput, Dict[str, Any]]) -> Dict[str, Any]:
        """
        Transform complex forecast to simple chart data
        
        From:
        ForecastOutput(
            forecast_date=date(2025, 7, 20),
            intervals=[
                IntervalForecast(
                    start_time=datetime(...),
                    end_time=datetime(...),
                    predicted_calls=142.5,
                    confidence_lower=130.2,
                    confidence_upper=154.8
                ), ...
            ],
            metadata=ForecastMetadata(...)
        )
        
        To:
        {
            "labels": ["00:00", "00:30", "01:00", ...],
            "values": [120, 135, 142, ...],
            "confidence": 0.90,
            "date": "2025-07-20"
        }
        """
        # Handle both dataclass and dict inputs
        if isinstance(forecast_output, dict):
            if not forecast_output or 'intervals' not in forecast_output:
                return {"labels": [], "values": [], "confidence": 0, "date": ""}
                
            intervals = forecast_output['intervals']
            forecast_date = forecast_output.get('forecast_date', '')
            confidence = forecast_output.get('metadata', {}).get('confidence_score', 0)
        else:
            if not forecast_output or not forecast_output.intervals:
                return {"labels": [], "values": [], "confidence": 0, "date": ""}
                
            intervals = forecast_output.intervals
            forecast_date = forecast_output.forecast_date
            confidence = forecast_output.metadata.confidence_score
        
        # Transform intervals to UI format
        labels = []
        values = []
        confidence_bands = {"lower": [], "upper": []}
        
        for interval in intervals:
            if isinstance(interval, dict):
                start_time = interval.get('start_time')
                if isinstance(start_time, str):
                    start_time = datetime.fromisoformat(start_time)
                labels.append(start_time.strftime("%H:%M"))
                values.append(round(interval.get('predicted_calls', 0)))
                confidence_bands["lower"].append(round(interval.get('confidence_lower', 0)))
                confidence_bands["upper"].append(round(interval.get('confidence_upper', 0)))
            else:
                labels.append(interval.start_time.strftime("%H:%M"))
                values.append(round(interval.predicted_calls))
                confidence_bands["lower"].append(round(interval.confidence_lower))
                confidence_bands["upper"].append(round(interval.confidence_upper))
        
        # Format date
        if isinstance(forecast_date, date):
            date_str = forecast_date.isoformat()
        else:
            date_str = str(forecast_date)
        
        return {
            "labels": labels,
            "values": values,
            "confidence": round(confidence, 2) if confidence else 0,
            "confidence_bands": confidence_bands,
            "date": date_str,
            "total_calls": sum(values)
        }
    
    @staticmethod
    def transform_schedule(schedule_result: Union[ScheduleOptimizationResult, Dict[str, Any]]) -> Dict[str, Any]:
        """
        Transform optimized schedule to grid format for UI
        
        From: Complex optimization result with constraints
        To: Simple grid for display
        """
        # Handle both dataclass and dict inputs
        if isinstance(schedule_result, dict):
            if not schedule_result or 'assignments' not in schedule_result:
                return {"employees": [], "dates": [], "shifts": [], "coverage_score": 0}
                
            assignments = schedule_result['assignments']
            optimization_score = schedule_result.get('optimization_score', 0)
        else:
            if not schedule_result or not schedule_result.assignments:
                return {"employees": [], "dates": [], "shifts": [], "coverage_score": 0}
                
            assignments = schedule_result.assignments
            optimization_score = schedule_result.optimization_score
        
        # Extract unique employees and dates
        employees = set()
        dates = set()
        
        for assignment in assignments:
            if isinstance(assignment, dict):
                employees.add(assignment['employee_id'])
                shift_date = assignment.get('shift_date')
                if isinstance(shift_date, str):
                    dates.add(shift_date)
                else:
                    dates.add(shift_date.isoformat())
            else:
                employees.add(assignment.employee_id)
                dates.add(assignment.shift_date.isoformat())
        
        employees = sorted(employees)
        dates = sorted(dates)
        
        # Build grid data
        grid = []
        for emp_id in employees:
            employee_shifts = []
            for date in dates:
                # Find assignment for this employee and date
                assignment = None
                for a in assignments:
                    if isinstance(a, dict):
                        a_date = a.get('shift_date')
                        if isinstance(a_date, date):
                            a_date = a_date.isoformat()
                        if a['employee_id'] == emp_id and a_date == date:
                            assignment = a
                            break
                    else:
                        if a.employee_id == emp_id and a.shift_date.isoformat() == date:
                            assignment = a
                            break
                
                if assignment:
                    if isinstance(assignment, dict):
                        start_time = assignment.get('start_time')
                        end_time = assignment.get('end_time')
                        if isinstance(start_time, datetime):
                            start_str = start_time.strftime("%H:%M")
                        else:
                            start_str = start_time
                        if isinstance(end_time, datetime):
                            end_str = end_time.strftime("%H:%M")
                        else:
                            end_str = end_time
                            
                        employee_shifts.append({
                            "shift": assignment.get('shift_type', 'standard'),
                            "start": start_str,
                            "end": end_str,
                            "skills": assignment.get('skills', [])
                        })
                    else:
                        employee_shifts.append({
                            "shift": assignment.shift_type,
                            "start": assignment.start_time.strftime("%H:%M"),
                            "end": assignment.end_time.strftime("%H:%M"),
                            "skills": assignment.skills
                        })
                else:
                    employee_shifts.append(None)
            
            grid.append({
                "employee_id": emp_id,
                "shifts": employee_shifts
            })
        
        return {
            "employees": employees,
            "dates": dates,
            "grid": grid,
            "coverage_score": round(optimization_score * 100, 1) if optimization_score else 0
        }
    
    @staticmethod
    def transform_metrics(metrics: Union[MetricsAggregation, Dict[str, Any]]) -> Dict[str, Any]:
        """Transform complex metrics to dashboard format"""
        # Handle both dataclass and dict inputs
        if isinstance(metrics, dict):
            service_level = metrics.get('service_level', 0)
            avg_wait = metrics.get('avg_wait_time_seconds', 0)
            abandonment = metrics.get('abandonment_rate', 0)
            occupancy = metrics.get('agent_occupancy', 0)
            trend = metrics.get('trend_direction', 0)
        else:
            service_level = metrics.service_level
            avg_wait = metrics.avg_wait_time_seconds
            abandonment = metrics.abandonment_rate
            occupancy = metrics.agent_occupancy
            trend = metrics.trend_direction
        
        return {
            "kpi": {
                "service_level": round(service_level * 100, 1),
                "average_wait": round(avg_wait),
                "abandonment_rate": round(abandonment * 100, 1),
                "occupancy": round(occupancy * 100, 1)
            },
            "trend": "up" if trend > 0 else "down" if trend < 0 else "stable",
            "timestamp": datetime.now().isoformat()
        }
    
    @staticmethod
    def transform_gap_analysis(gap_result: Union[GapAnalysisResult, Dict[str, Any]]) -> Dict[str, Any]:
        """Transform gap analysis results to UI format"""
        # Handle both dataclass and dict inputs
        if isinstance(gap_result, dict):
            gaps = gap_result.get('gaps', [])
            total_gap = gap_result.get('total_gap_minutes', 0)
            severity = gap_result.get('severity_score', 0)
            recommendations = gap_result.get('recommendations', [])
        else:
            gaps = gap_result.gaps
            total_gap = gap_result.total_gap_minutes
            severity = gap_result.severity_score
            recommendations = gap_result.recommendations
        
        # Transform gaps to timeline format
        timeline_gaps = []
        for gap in gaps:
            timeline_gaps.append({
                "start": gap.get('start_time', ''),
                "end": gap.get('end_time', ''),
                "shortage": gap.get('shortage_count', 0),
                "severity": gap.get('severity', 'low')
            })
        
        return {
            "summary": {
                "total_gap_hours": round(total_gap / 60, 1),
                "severity_percentage": round(severity * 100, 1),
                "gap_count": len(gaps)
            },
            "timeline": timeline_gaps,
            "recommendations": recommendations[:5],  # Top 5 recommendations
            "chart_data": {
                "labels": [gap.get('start_time', '') for gap in gaps],
                "values": [gap.get('shortage_count', 0) for gap in gaps]
            }
        }
    
    @staticmethod
    def transform_batch_results(results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Transform batch algorithm results for UI summary view"""
        if not results:
            return {"total": 0, "successful": 0, "failed": 0, "results": []}
        
        successful = [r for r in results if r.get('status') == 'success']
        failed = [r for r in results if r.get('status') == 'error']
        
        return {
            "total": len(results),
            "successful": len(successful),
            "failed": len(failed),
            "results": [
                {
                    "id": r.get('id', ''),
                    "status": r.get('status', 'unknown'),
                    "execution_time": r.get('execution_time_ms', 0),
                    "summary": r.get('summary', '')
                }
                for r in results
            ],
            "avg_execution_time": sum(r.get('execution_time_ms', 0) for r in results) / len(results) if results else 0
        }
    
    @staticmethod
    def transform_cost_data(cost_data: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Transform cost calculation data for UI display"""
        if isinstance(cost_data, dict):
            total_cost = cost_data.get('total_cost', 0)
            cost_per_agent = cost_data.get('cost_per_agent', 0)
            overtime_cost = cost_data.get('overtime_cost', 0)
            breakdown = cost_data.get('cost_breakdown', {})
        else:
            # Handle object with attributes
            total_cost = getattr(cost_data, 'total_cost', 0)
            cost_per_agent = getattr(cost_data, 'cost_per_agent', 0)
            overtime_cost = getattr(cost_data, 'overtime_cost', 0)
            breakdown = getattr(cost_data, 'cost_breakdown', {})
        
        return {
            "total_cost_display": f"${total_cost:,.2f}",
            "cost_per_agent_display": f"${cost_per_agent:,.2f}",
            "overtime_cost_display": f"${overtime_cost:,.2f}",
            "overtime_percentage": round((overtime_cost / total_cost * 100) if total_cost > 0 else 0, 1),
            "breakdown": {
                key: f"${value:,.2f}" for key, value in breakdown.items()
            },
            "raw_values": {
                "total_cost": total_cost,
                "cost_per_agent": cost_per_agent,
                "overtime_cost": overtime_cost
            }
        }
    
    @staticmethod
    def transform_forecast_for_chart(forecast_data: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Transform forecast data specifically for Chart.js components"""
        # First use the standard transformer
        ui_data = UITransformer.transform_forecast(forecast_data)
        
        # Then format for Chart.js
        return {
            "datasets": [
                {
                    "label": "Forecast",
                    "data": ui_data.get('values', []),
                    "borderColor": "rgb(59, 130, 246)",
                    "backgroundColor": "rgba(59, 130, 246, 0.1)",
                    "tension": 0.4
                },
                {
                    "label": "Confidence Upper",
                    "data": ui_data.get('confidence_bands', {}).get('upper', []),
                    "borderColor": "rgb(251, 146, 60)",
                    "borderDash": [5, 5],
                    "fill": False
                },
                {
                    "label": "Confidence Lower", 
                    "data": ui_data.get('confidence_bands', {}).get('lower', []),
                    "borderColor": "rgb(251, 146, 60)",
                    "borderDash": [5, 5],
                    "fill": False
                }
            ],
            "labels": ui_data.get('labels', []),
            "options": {
                "responsive": True,
                "scales": {
                    "y": {
                        "beginAtZero": True,
                        "title": {
                            "display": True,
                            "text": "Call Volume"
                        }
                    }
                }
            },
            "metadata": {
                "confidence": ui_data.get('confidence', 0),
                "total_calls": ui_data.get('total_calls', 0),
                "date": ui_data.get('date', '')
            }
        }
    
    @staticmethod
    def transform_schedule_for_grid(schedule_data: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Transform schedule data specifically for ScheduleGridBDD component"""
        # First use the standard transformer
        ui_data = UITransformer.transform_schedule(schedule_data)
        
        # Then format for ScheduleGrid
        schedule_cells = []
        for employee in ui_data.get('grid', []):
            employee_id = employee.get('employee_id', '')
            shifts = employee.get('shifts', [])
            
            for i, shift in enumerate(shifts):
                date = ui_data.get('dates', [])[i] if i < len(ui_data.get('dates', [])) else ''
                
                if shift:  # Not None
                    schedule_cells.append({
                        "employeeId": employee_id,
                        "date": date,
                        "type": "work",
                        "startTime": shift.get('start', ''),
                        "endTime": shift.get('end', ''),
                        "shiftType": shift.get('shift', 'standard'),
                        "skills": shift.get('skills', []),
                        "overtime": False,  # Could be calculated
                        "violations": []  # Could be populated from constraint violations
                    })
                else:
                    schedule_cells.append({
                        "employeeId": employee_id,
                        "date": date,
                        "type": "rest",
                        "startTime": None,
                        "endTime": None,
                        "shiftType": None,
                        "skills": [],
                        "overtime": False,
                        "violations": []
                    })
        
        return {
            "employees": [
                {
                    "id": emp_id,
                    "name": f"Employee {emp_id}",  # Would need real name lookup
                    "position": "Operator",
                    "skills": []
                }
                for emp_id in ui_data.get('employees', [])
            ],
            "dates": ui_data.get('dates', []),
            "cells": schedule_cells,
            "coverage_score": ui_data.get('coverage_score', 0),
            "metadata": {
                "total_employees": len(ui_data.get('employees', [])),
                "total_shifts": len([cell for cell in schedule_cells if cell['type'] == 'work']),
                "optimization_score": ui_data.get('coverage_score', 0)
            }
        }
    
    @staticmethod
    def transform_optimization_result(optimization_data: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Transform optimization results for OptimizationPanel component"""
        if isinstance(optimization_data, dict):
            total_gaps = optimization_data.get('total_gaps', 0)
            coverage_score = optimization_data.get('coverage_score', 0)
            recommendations = optimization_data.get('recommendations', [])
        else:
            total_gaps = getattr(optimization_data, 'total_gaps', 0)
            coverage_score = getattr(optimization_data, 'coverage_score', 0)
            recommendations = getattr(optimization_data, 'recommendations', [])
        
        return {
            "total_gaps": total_gaps,
            "coverage_score": round(coverage_score, 1),
            "average_gap_percentage": round((total_gaps / 480) * 100, 1) if total_gaps > 0 else 0,  # 480 = 8 hours * 60 minutes
            "critical_intervals": [],  # Would need to be calculated from gap data
            "recommendations": recommendations[:5],  # Top 5 recommendations
            "status": "good" if coverage_score > 80 else "warning" if coverage_score > 60 else "critical",
            "trend": "stable"  # Would need historical comparison
        }