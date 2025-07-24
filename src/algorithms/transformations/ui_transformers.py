"""
UI Data Transformation Layer

Transforms complex algorithm outputs to simple UI-consumable formats.
Addresses the problem: Algorithms return complex objects, UI needs simple formats.

Key transformations:
- Forecast objects → Chart data
- Schedule results → Grid format  
- Metrics aggregations → Dashboard KPIs
- Complex nested data → Flat JSON structures

Performance: Sub-second transformations for real-time UI updates
"""

from typing import Dict, List, Any, Union, Optional
from datetime import datetime, date
from dataclasses import dataclass
import json

# Type definitions for algorithm outputs
@dataclass
class IntervalForecast:
    """Single interval forecast data"""
    start_time: datetime
    end_time: datetime
    predicted_calls: float
    confidence_lower: float
    confidence_upper: float
    skill_requirements: Optional[Dict[str, float]] = None

@dataclass
class ForecastMetadata:
    """Forecast metadata"""
    confidence_score: float
    model_version: str
    generated_at: datetime

@dataclass
class ForecastOutput:
    """Complex forecast output from algorithms"""
    forecast_date: date
    intervals: List[IntervalForecast]
    metadata: ForecastMetadata

@dataclass
class ScheduleAssignment:
    """Individual schedule assignment"""
    employee_id: int
    shift_date: date
    start_time: datetime
    end_time: datetime
    shift_type: str
    skill_assignments: List[str]

@dataclass
class ScheduleOptimizationResult:
    """Complex schedule optimization result"""
    assignments: List[ScheduleAssignment]
    optimization_score: float
    constraints_satisfied: List[str]
    violations: List[str]
    
@dataclass
class MetricsAggregation:
    """Complex metrics aggregation"""
    service_level: float
    avg_wait_time_seconds: float
    abandonment_rate: float
    agent_occupancy: float
    trend_direction: float  # -1 to +1


class UITransformer:
    """
    Transform complex algorithm outputs to simple UI formats
    
    Handles the gap between algorithmic complexity and UI simplicity.
    All transformations are optimized for front-end consumption.
    """
    
    @staticmethod
    def transform_forecast(forecast_output: ForecastOutput) -> Dict[str, Any]:
        """
        Transform complex forecast to simple chart data
        
        From: ForecastOutput with complex interval objects
        To: Simple chart-ready JSON
        
        Args:
            forecast_output: Complex forecast result from algorithm
            
        Returns:
            Dict with labels, values, confidence for chart display
        """
        if not forecast_output or not forecast_output.intervals:
            return {
                "labels": [], 
                "values": [], 
                "confidence": 0, 
                "date": "",
                "total_calls": 0,
                "peak_hour": "",
                "trend": "stable"
            }
            
        # Extract chart data
        labels = [
            interval.start_time.strftime("%H:%M") 
            for interval in forecast_output.intervals
        ]
        
        values = [
            round(interval.predicted_calls) 
            for interval in forecast_output.intervals
        ]
        
        total_calls = sum(interval.predicted_calls for interval in forecast_output.intervals)
        
        # Find peak hour
        peak_interval = max(forecast_output.intervals, key=lambda x: x.predicted_calls)
        peak_hour = peak_interval.start_time.strftime("%H:%M")
        
        # Simple trend calculation
        if len(values) >= 2:
            trend = "up" if values[-1] > values[0] else "down" if values[-1] < values[0] else "stable"
        else:
            trend = "stable"
            
        return {
            "labels": labels,
            "values": values,
            "confidence": round(forecast_output.metadata.confidence_score * 100, 1),
            "date": forecast_output.forecast_date.isoformat(),
            "total_calls": round(total_calls),
            "peak_hour": peak_hour,
            "trend": trend,
            "generated_at": forecast_output.metadata.generated_at.isoformat()
        }
    
    @staticmethod
    def transform_schedule(schedule_result: ScheduleOptimizationResult) -> Dict[str, Any]:
        """
        Transform optimized schedule to grid format for UI
        
        From: Complex optimization result with constraints
        To: Simple grid for calendar/table display
        
        Args:
            schedule_result: Complex schedule optimization result
            
        Returns:
            Dict with employees, dates, grid data for UI display
        """
        if not schedule_result or not schedule_result.assignments:
            return {
                "employees": [], 
                "dates": [], 
                "shifts": [],
                "coverage_score": 0,
                "total_assignments": 0,
                "violations": []
            }
            
        # Extract unique employees and dates
        employees = sorted(set(a.employee_id for a in schedule_result.assignments))
        dates = sorted(set(a.shift_date.isoformat() for a in schedule_result.assignments))
        
        # Build grid data
        grid = []
        for emp_id in employees:
            employee_shifts = []
            for date_str in dates:
                # Find assignment for this employee on this date
                assignment = next(
                    (a for a in schedule_result.assignments 
                     if a.employee_id == emp_id and a.shift_date.isoformat() == date_str),
                    None
                )
                
                if assignment:
                    employee_shifts.append({
                        "shift": assignment.shift_type,
                        "start": assignment.start_time.strftime("%H:%M"),
                        "end": assignment.end_time.strftime("%H:%M"),
                        "skills": assignment.skill_assignments,
                        "duration_hours": (assignment.end_time - assignment.start_time).total_seconds() / 3600
                    })
                else:
                    employee_shifts.append(None)  # No assignment
            
            grid.append({
                "employee_id": emp_id,
                "shifts": employee_shifts
            })
        
        return {
            "employees": employees,
            "dates": dates,
            "grid": grid,
            "coverage_score": round(schedule_result.optimization_score * 100, 1),
            "total_assignments": len(schedule_result.assignments),
            "violations": schedule_result.violations[:5],  # Limit violations for UI
            "constraints_satisfied": len(schedule_result.constraints_satisfied),
            "efficiency_rating": "high" if schedule_result.optimization_score > 0.8 else "medium" if schedule_result.optimization_score > 0.6 else "low"
        }
    
    @staticmethod
    def transform_metrics(metrics: MetricsAggregation) -> Dict[str, Any]:
        """
        Transform complex metrics to dashboard format
        
        From: Complex metrics aggregation with raw values
        To: Dashboard-ready KPI format with percentages and indicators
        
        Args:
            metrics: Complex metrics aggregation
            
        Returns:
            Dict with KPI values, trends, and status indicators
        """
        if not metrics:
            return {
                "kpi": {},
                "trend": "stable",
                "timestamp": datetime.now().isoformat(),
                "status": "unknown"
            }
        
        # Convert to percentage and round for display
        service_level_pct = round(metrics.service_level * 100, 1)
        abandonment_rate_pct = round(metrics.abandonment_rate * 100, 1)
        occupancy_pct = round(metrics.agent_occupancy * 100, 1)
        
        # Determine overall status
        status = "good"
        if service_level_pct < 80 or abandonment_rate_pct > 5:
            status = "warning"
        if service_level_pct < 70 or abandonment_rate_pct > 10:
            status = "critical"
        
        return {
            "kpi": {
                "service_level": service_level_pct,
                "average_wait": round(metrics.avg_wait_time_seconds),
                "abandonment_rate": abandonment_rate_pct,
                "occupancy": occupancy_pct
            },
            "trend": "up" if metrics.trend_direction > 0.1 else "down" if metrics.trend_direction < -0.1 else "stable",
            "status": status,
            "timestamp": datetime.now().isoformat(),
            "alerts": [
                f"Service level below target: {service_level_pct}%" if service_level_pct < 80 else None,
                f"High abandonment rate: {abandonment_rate_pct}%" if abandonment_rate_pct > 5 else None,
                f"Low occupancy: {occupancy_pct}%" if occupancy_pct < 60 else None,
                f"High occupancy: {occupancy_pct}%" if occupancy_pct > 90 else None
            ]
        }
    
    @staticmethod
    def transform_employee_request(request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Transform employee request validation result to UI format
        
        From: Complex validation result with technical details
        To: Simple status and user-friendly messages
        """
        if not request_data:
            return {"status": "unknown", "message": "No data available"}
        
        # Extract key information
        is_valid = request_data.get('is_valid', False)
        errors = request_data.get('errors', [])
        warnings = request_data.get('warnings', [])
        
        # Determine status
        if is_valid and not errors:
            status = "approved" if not warnings else "approved_with_warnings"
        elif errors:
            status = "rejected"
        else:
            status = "pending"
        
        # Create user-friendly messages
        messages = []
        if errors:
            messages.extend([f"❌ {error}" for error in errors])
        if warnings:
            messages.extend([f"⚠️ {warning}" for warning in warnings])
        if is_valid and not errors and not warnings:
            messages.append("✅ Request approved")
        
        return {
            "status": status,
            "messages": messages,
            "can_submit": is_valid and not errors,
            "requires_approval": request_data.get('requires_approval', True),
            "estimated_processing_time": "2-4 business days" if status == "pending" else "immediate",
            "next_steps": [
                "Wait for supervisor approval" if status == "pending" else None,
                "Check calendar for updates" if status == "approved" else None,
                "Revise request and resubmit" if status == "rejected" else None
            ]
        }
    
    @staticmethod
    def batch_transform(data_batch: List[Dict[str, Any]], transform_type: str) -> List[Dict[str, Any]]:
        """
        Transform multiple items efficiently
        
        Args:
            data_batch: List of items to transform
            transform_type: Type of transformation ('forecast', 'schedule', 'metrics', 'request')
            
        Returns:
            List of transformed items
        """
        transformers = {
            'forecast': UITransformer.transform_forecast,
            'schedule': UITransformer.transform_schedule,
            'metrics': UITransformer.transform_metrics,
            'request': UITransformer.transform_employee_request
        }
        
        transformer = transformers.get(transform_type)
        if not transformer:
            raise ValueError(f"Unknown transform type: {transform_type}")
        
        return [transformer(item) for item in data_batch if item]
    
    @staticmethod
    def create_summary_dashboard(forecasts: List[Dict], schedules: List[Dict], metrics: List[Dict]) -> Dict[str, Any]:
        """
        Create executive summary dashboard from multiple data sources
        
        Combines forecast, schedule, and metrics data into a single dashboard view
        """
        try:
            # Aggregate forecast data
            total_predicted_calls = sum(f.get('total_calls', 0) for f in forecasts)
            
            # Aggregate schedule data
            total_employees_scheduled = len(set(
                emp_id for schedule in schedules 
                for emp_id in schedule.get('employees', [])
            ))
            
            # Get latest metrics
            latest_metrics = metrics[-1] if metrics else {}
            
            return {
                "overview": {
                    "total_predicted_calls": total_predicted_calls,
                    "employees_scheduled": total_employees_scheduled,
                    "current_service_level": latest_metrics.get('kpi', {}).get('service_level', 0),
                    "status": latest_metrics.get('status', 'unknown')
                },
                "trends": {
                    "call_volume": "up" if any(f.get('trend') == 'up' for f in forecasts) else "stable",
                    "performance": latest_metrics.get('trend', 'stable')
                },
                "alerts": [
                    alert for metric in metrics 
                    for alert in metric.get('alerts', []) 
                    if alert is not None
                ],
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "error": f"Failed to create dashboard: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }