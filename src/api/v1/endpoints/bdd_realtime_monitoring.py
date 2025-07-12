"""
BDD Real-time Monitoring and Operational Control API
Based on: 15-real-time-monitoring-operational-control.feature
"""

from fastapi import APIRouter, HTTPException, Query, Depends, Path
from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
from pydantic import BaseModel, Field, constr
from enum import Enum
import random

router = APIRouter()

# Enums
class MetricStatus(str, Enum):
    GREEN = "green"
    YELLOW = "yellow"
    RED = "red"

class TrendDirection(str, Enum):
    UP = "up"
    DOWN = "down"
    STABLE = "stable"

class AgentStatus(str, Enum):
    ON_SCHEDULE = "on_schedule"
    LATE_LOGIN = "late_login"
    ABSENT = "absent"
    WRONG_STATUS = "wrong_status"
    IN_BREAK = "in_break"
    LUNCH = "lunch"

class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"
    EMERGENCY = "emergency"

# Models
class MetricThresholds(BaseModel):
    green_min: float
    green_max: float
    yellow_min: float
    yellow_max: float
    red_threshold: float

class DashboardMetric(BaseModel):
    metric_name: str
    current_value: float
    trend_direction: TrendDirection
    color_status: MetricStatus
    historical_context: List[float] = Field(description="Recent values for sparkline")
    last_updated: datetime
    update_frequency: str
    thresholds: MetricThresholds

class OperationalDashboard(BaseModel):
    operators_online_percent: DashboardMetric
    load_deviation: DashboardMetric
    operator_requirement: DashboardMetric
    sla_performance: DashboardMetric
    acd_rate: DashboardMetric
    aht_trend: DashboardMetric
    last_refresh: datetime

class DrillDownDetails(BaseModel):
    metric_name: str
    schedule_adherence_24h: Dict[str, float]
    timetable_status: Dict[str, Any]
    actually_online_agents: List[Dict[str, Any]]
    individual_agent_status: List[Dict[str, Any]]
    deviation_timeline: List[Dict[str, Any]]
    last_updated: datetime

class AgentStatusInfo(BaseModel):
    agent_id: str
    agent_name: str
    current_status: AgentStatus
    visual_indicator: str
    status_duration: str
    current_activity: str
    schedule_adherence: bool
    today_statistics: Dict[str, Any]
    contact_availability: bool
    available_actions: List[str]

class ThresholdAlert(BaseModel):
    alert_id: str
    alert_trigger: str
    threshold_breached: str
    severity: AlertSeverity
    alert_description: str
    current_values: Dict[str, Any]
    suggested_actions: List[str]
    escalation_timeline: Dict[str, str]
    created_at: datetime
    acknowledged: bool

class PredictiveAlert(BaseModel):
    alert_id: str
    prediction_type: str
    analysis_basis: str
    lead_time_minutes: int
    confidence_score: float
    predicted_issue: str
    prevention_actions: List[str]
    data_sources: List[str]

class OperationalAdjustment(BaseModel):
    adjustment_type: str
    target_id: str = Field(description="Employee or resource ID")
    action: str
    parameters: Dict[str, Any]
    validation_result: Optional[Dict[str, Any]] = None
    estimated_impact: Optional[str] = None

# Endpoints

@router.get("/monitoring/operational-control", response_model=OperationalDashboard, tags=["monitoring"])
async def get_operational_dashboards():
    """
    View Real-time Operational Control Dashboards
    BDD: Scenario: View Real-time Operational Control Dashboards (lines 13-30)
    
    Returns six key real-time metrics with visual indicators and thresholds
    """
    current_time = datetime.now()
    
    # Generate realistic metric values
    operators_online = random.uniform(65, 95)
    load_deviation = random.uniform(-25, 25)
    
    return OperationalDashboard(
        operators_online_percent=DashboardMetric(
            metric_name="Operators Online %",
            current_value=operators_online,
            trend_direction=TrendDirection.UP if operators_online > 80 else TrendDirection.DOWN,
            color_status=MetricStatus.GREEN if operators_online > 80 else (MetricStatus.YELLOW if operators_online > 70 else MetricStatus.RED),
            historical_context=[operators_online + random.uniform(-5, 5) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Every 30 seconds",
            thresholds=MetricThresholds(
                green_min=80, green_max=100,
                yellow_min=70, yellow_max=80,
                red_threshold=70
            )
        ),
        load_deviation=DashboardMetric(
            metric_name="Load Deviation",
            current_value=load_deviation,
            trend_direction=TrendDirection.STABLE if abs(load_deviation) < 5 else (TrendDirection.UP if load_deviation > 0 else TrendDirection.DOWN),
            color_status=MetricStatus.GREEN if abs(load_deviation) <= 10 else (MetricStatus.YELLOW if abs(load_deviation) <= 20 else MetricStatus.RED),
            historical_context=[load_deviation + random.uniform(-5, 5) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Every minute",
            thresholds=MetricThresholds(
                green_min=-10, green_max=10,
                yellow_min=-20, yellow_max=20,
                red_threshold=20
            )
        ),
        operator_requirement=DashboardMetric(
            metric_name="Operator Requirement",
            current_value=random.uniform(45, 60),
            trend_direction=TrendDirection.STABLE,
            color_status=MetricStatus.GREEN,
            historical_context=[random.uniform(45, 60) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Real-time",
            thresholds=MetricThresholds(
                green_min=0, green_max=100,
                yellow_min=100, yellow_max=120,
                red_threshold=120
            )
        ),
        sla_performance=DashboardMetric(
            metric_name="SLA Performance",
            current_value=random.uniform(75, 85),
            trend_direction=TrendDirection.STABLE,
            color_status=MetricStatus.GREEN,
            historical_context=[random.uniform(75, 85) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Every minute",
            thresholds=MetricThresholds(
                green_min=75, green_max=100,
                yellow_min=70, yellow_max=75,
                red_threshold=70
            )
        ),
        acd_rate=DashboardMetric(
            metric_name="ACD Rate",
            current_value=random.uniform(90, 98),
            trend_direction=TrendDirection.UP,
            color_status=MetricStatus.GREEN,
            historical_context=[random.uniform(90, 98) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Real-time",
            thresholds=MetricThresholds(
                green_min=90, green_max=100,
                yellow_min=85, yellow_max=90,
                red_threshold=85
            )
        ),
        aht_trend=DashboardMetric(
            metric_name="AHT Trend",
            current_value=random.uniform(280, 320),
            trend_direction=TrendDirection.STABLE,
            color_status=MetricStatus.GREEN,
            historical_context=[random.uniform(280, 320) for _ in range(10)],
            last_updated=current_time,
            update_frequency="Every 5 minutes",
            thresholds=MetricThresholds(
                green_min=0, green_max=300,
                yellow_min=300, yellow_max=330,
                red_threshold=330
            )
        ),
        last_refresh=current_time
    )

@router.get("/monitoring/metrics/{metric_name}/drill-down", response_model=DrillDownDetails, tags=["monitoring"])
async def drill_down_metric_details(
    metric_name: str = Path(description="Name of the metric to drill down into")
):
    """
    Drill Down into Metric Details
    BDD: Scenario: Drill Down into Metric Details (lines 32-47)
    
    Provides detailed breakdown of selected metrics with real-time updates
    """
    if metric_name not in ["operators_online", "load_deviation", "operator_requirement", "sla_performance", "acd_rate", "aht_trend"]:
        raise HTTPException(status_code=404, detail="Metric not found")
    
    current_time = datetime.now()
    
    # Generate 24-hour schedule adherence data
    schedule_adherence = {}
    for hour in range(24):
        hour_time = (current_time - timedelta(hours=23-hour)).strftime("%H:00")
        schedule_adherence[hour_time] = random.uniform(75, 95)
    
    # Generate agent status breakdown
    agent_statuses = []
    for i in range(20):
        agent_statuses.append({
            "agent_id": f"AGENT{i+1:03d}",
            "name": f"Agent {i+1}",
            "status": random.choice(["online", "break", "offline"]),
            "adherence": random.uniform(85, 100)
        })
    
    # Generate deviation timeline
    deviation_timeline = []
    for hour in range(24):
        timeline_point = current_time - timedelta(hours=23-hour)
        deviation_timeline.append({
            "timestamp": timeline_point.isoformat(),
            "planned": random.randint(45, 55),
            "actual": random.randint(40, 60),
            "deviation": random.uniform(-10, 10)
        })
    
    return DrillDownDetails(
        metric_name=metric_name,
        schedule_adherence_24h=schedule_adherence,
        timetable_status={
            "scheduled": 50,
            "online": 45,
            "on_break": 3,
            "absent": 2
        },
        actually_online_agents=agent_statuses,
        individual_agent_status=[
            {
                "agent_id": agent["agent_id"],
                "current_state": agent["status"],
                "schedule_compliance": agent["adherence"]
            } for agent in agent_statuses[:10]
        ],
        deviation_timeline=deviation_timeline,
        last_updated=current_time
    )

@router.get("/monitoring/agents/status", response_model=List[AgentStatusInfo], tags=["monitoring"])
async def monitor_agent_status(
    supervisor_id: str = Query(description="Supervisor ID to filter subordinate agents"),
    status_filter: Optional[AgentStatus] = Query(None, description="Filter by agent status")
):
    """
    Monitor Individual Agent Status and Performance
    BDD: Scenario: Monitor Individual Agent Status and Performance (lines 49-66)
    
    Shows real-time agent information with visual indicators and available actions
    """
    agents = []
    statuses = [
        (AgentStatus.ON_SCHEDULE, "green", ["Monitor"]),
        (AgentStatus.LATE_LOGIN, "yellow", ["Call to workplace"]),
        (AgentStatus.ABSENT, "red", ["Call to workplace", "Escalate"]),
        (AgentStatus.WRONG_STATUS, "orange", ["Investigate", "Correct"]),
        (AgentStatus.IN_BREAK, "blue", ["Monitor duration"]),
        (AgentStatus.LUNCH, "purple", ["Track compliance"])
    ]
    
    for i in range(15):
        status_info = random.choice(statuses)
        status = status_info[0]
        
        if status_filter and status != status_filter:
            continue
            
        agents.append(AgentStatusInfo(
            agent_id=f"AGENT{i+1:03d}",
            agent_name=f"Оператор {i+1}",
            current_status=status,
            visual_indicator=status_info[1],
            status_duration="15 минут" if status != AgentStatus.ON_SCHEDULE else "На месте",
            current_activity="Обработка звонка" if status == AgentStatus.ON_SCHEDULE else status.value,
            schedule_adherence=status == AgentStatus.ON_SCHEDULE,
            today_statistics={
                "calls_handled": random.randint(20, 50),
                "average_talk_time": random.randint(180, 300),
                "breaks_taken": random.randint(2, 4),
                "ready_time_percent": random.uniform(70, 95)
            },
            contact_availability=status == AgentStatus.ON_SCHEDULE,
            available_actions=status_info[2]
        ))
    
    return agents

@router.get("/monitoring/alerts/threshold", response_model=List[ThresholdAlert], tags=["monitoring"])
async def get_threshold_alerts(
    severity: Optional[AlertSeverity] = Query(None, description="Filter by severity"),
    acknowledged: Optional[bool] = Query(None, description="Filter by acknowledgment status")
):
    """
    Configure and Respond to Threshold-Based Alerts
    BDD: Scenario: Configure and Respond to Threshold-Based Alerts (lines 68-83)
    
    Returns active threshold-based alerts with response actions
    """
    alerts = []
    
    alert_scenarios = [
        {
            "trigger": "Critical understaffing",
            "threshold": "Online % <70%",
            "severity": AlertSeverity.CRITICAL,
            "actions": ["SMS to management", "Email to management", "Emergency staffing protocol"]
        },
        {
            "trigger": "Service level breach",
            "threshold": "80/20 format <70% for 5 minutes",
            "severity": AlertSeverity.CRITICAL,
            "actions": ["Immediate escalation", "Notify operations director", "Activate backup team"]
        },
        {
            "trigger": "System overload",
            "threshold": "Queue >20 contacts",
            "severity": AlertSeverity.EMERGENCY,
            "actions": ["Emergency staffing protocol", "Overflow activation", "Technical team alert"]
        },
        {
            "trigger": "Extended outages",
            "threshold": "No data for 10 minutes",
            "severity": AlertSeverity.EMERGENCY,
            "actions": ["Technical team alert", "Failover activation", "Manual operations mode"]
        }
    ]
    
    for i, scenario in enumerate(alert_scenarios):
        if severity and scenario["severity"] != severity:
            continue
            
        alert_acknowledged = random.choice([True, False])
        if acknowledged is not None and alert_acknowledged != acknowledged:
            continue
            
        alerts.append(ThresholdAlert(
            alert_id=f"ALERT{i+1:04d}",
            alert_trigger=scenario["trigger"],
            threshold_breached=scenario["threshold"],
            severity=scenario["severity"],
            alert_description=f"{scenario['trigger']} detected - {scenario['threshold']}",
            current_values={
                "metric_value": random.uniform(60, 70),
                "threshold_value": 70,
                "duration_minutes": random.randint(1, 15)
            },
            suggested_actions=scenario["actions"],
            escalation_timeline={
                "Level 1": "Immediate",
                "Level 2": "15 minutes",
                "Level 3": "30 minutes",
                "Level 4": "60 minutes"
            },
            created_at=datetime.now() - timedelta(minutes=random.randint(1, 30)),
            acknowledged=alert_acknowledged
        ))
    
    return alerts

@router.get("/monitoring/alerts/predictive", response_model=List[PredictiveAlert], tags=["monitoring"])
async def get_predictive_alerts():
    """
    Generate Predictive Alerts for Potential Issues
    BDD: Scenario: Generate Predictive Alerts for Potential Issues (lines 85-100)
    
    Returns predictive alerts based on trend analysis and patterns
    """
    alerts = []
    
    predictive_scenarios = [
        {
            "type": "Approaching SLA breach",
            "analysis": "Trend analysis of current performance",
            "lead_time": random.randint(15, 30),
            "confidence": random.uniform(75, 85),
            "issue": "SLA likely to drop below 70% within 20 minutes",
            "prevention": ["Add backup agents", "Reduce break allocations", "Alert supervisors"]
        },
        {
            "type": "Staffing shortfall",
            "analysis": "Scheduled vs required operators",
            "lead_time": random.randint(60, 120),
            "confidence": random.uniform(80, 90),
            "issue": "Understaffing expected at 14:00-16:00",
            "prevention": ["Call additional operators", "Reschedule breaks", "Prepare overtime"]
        },
        {
            "type": "Break/lunch coverage gaps",
            "analysis": "Scheduled break overlaps",
            "lead_time": random.randint(30, 60),
            "confidence": random.uniform(85, 95),
            "issue": "Insufficient coverage during lunch period",
            "prevention": ["Stagger lunch times", "Assign floaters", "Delay non-critical breaks"]
        },
        {
            "type": "Peak load preparation",
            "analysis": "Forecasted volume increases",
            "lead_time": random.randint(120, 240),
            "confidence": random.uniform(70, 80),
            "issue": "30% volume spike expected at 17:00",
            "prevention": ["Pre-position agents", "Clear queue backlog", "Prepare overflow"]
        }
    ]
    
    for i, scenario in enumerate(predictive_scenarios):
        alerts.append(PredictiveAlert(
            alert_id=f"PRED{i+1:04d}",
            prediction_type=scenario["type"],
            analysis_basis=scenario["analysis"],
            lead_time_minutes=scenario["lead_time"],
            confidence_score=scenario["confidence"],
            predicted_issue=scenario["issue"],
            prevention_actions=scenario["prevention"],
            data_sources=[
                "Historical patterns",
                "Current trends",
                "Scheduled events",
                "External factors"
            ]
        ))
    
    return alerts

@router.post("/monitoring/adjustments", response_model=OperationalAdjustment, tags=["monitoring"])
async def make_operational_adjustment(adjustment: OperationalAdjustment):
    """
    Make Real-time Operational Adjustments
    BDD: Scenario: Make Real-time Operational Adjustments (lines 102-118)
    
    Execute immediate operational adjustments with validation
    """
    # Validate adjustment type
    valid_types = [
        "call_to_workplace",
        "extend_shift",
        "add_break_coverage",
        "emergency_scheduling",
        "skill_reallocation"
    ]
    
    if adjustment.adjustment_type not in valid_types:
        raise HTTPException(status_code=400, detail="Invalid adjustment type")
    
    # Simulate validation checks
    validation_results = {
        "labor_standards_compliance": {
            "overtime_check": "Pass",
            "rest_period_check": "Pass",
            "weekly_hours_check": "Pass"
        },
        "service_level_impact": {
            "coverage_maintained": True,
            "sla_risk": "Low",
            "queue_impact": "Minimal"
        },
        "employee_availability": {
            "current_status": "Available",
            "conflicts": "None",
            "skills_match": True
        },
        "cost_implications": {
            "overtime_cost": 0 if adjustment.adjustment_type != "extend_shift" else 1500,
            "budget_impact": "Within limits",
            "approval_required": False
        }
    }
    
    # Return adjustment result
    adjustment.validation_result = validation_results
    adjustment.estimated_impact = "Positive - Coverage improved by 5%"
    
    return adjustment

@router.get("/monitoring/groups", response_model=Dict[str, Any], tags=["monitoring"])
async def monitor_multiple_groups():
    """
    Monitor Multiple Groups Simultaneously
    BDD: Scenario: Monitor Multiple Groups Simultaneously (lines 120-135)
    
    Provides multi-group monitoring view with comparison and management features
    """
    groups = []
    
    for i in range(4):
        groups.append({
            "group_id": f"GROUP{i+1:02d}",
            "group_name": f"Service Group {i+1}",
            "priority_level": random.choice(["high", "medium", "low"]),
            "metrics": {
                "operators_online_percent": random.uniform(70, 95),
                "sla_performance": random.uniform(75, 90),
                "acd_rate": random.uniform(85, 98),
                "current_queue": random.randint(0, 15)
            },
            "alerts": random.randint(0, 3),
            "available_for_reallocation": random.randint(0, 5)
        })
    
    return {
        "groups": groups,
        "aggregate_metrics": {
            "total_operators_online": sum(g["metrics"]["operators_online_percent"] for g in groups) / len(groups),
            "overall_sla": sum(g["metrics"]["sla_performance"] for g in groups) / len(groups),
            "critical_alerts": sum(1 for g in groups if g["alerts"] > 2),
            "reallocation_capacity": sum(g["available_for_reallocation"] for g in groups)
        },
        "priority_alerts": [
            {
                "group_id": "GROUP02",
                "alert": "SLA breach risk",
                "severity": "high",
                "action_required": "Immediate attention"
            }
        ],
        "resource_recommendations": [
            {
                "from_group": "GROUP01",
                "to_group": "GROUP02",
                "agents": 2,
                "impact": "Improve GROUP02 SLA by 5%"
            }
        ]
    }

@router.get("/monitoring/historical/{period}", response_model=Dict[str, Any], tags=["monitoring"])
async def analyze_historical_patterns(
    period: str = Path(description="Analysis period: intraday, daily, weekly, monthly")
):
    """
    Analyze Historical Monitoring Data for Patterns
    BDD: Scenario: Analyze Historical Monitoring Data for Patterns (lines 137-152)
    
    Reviews historical performance patterns to identify improvement opportunities
    """
    if period not in ["intraday", "daily", "weekly", "monthly"]:
        raise HTTPException(status_code=400, detail="Invalid period specified")
    
    # Generate sample pattern data based on period
    patterns = {
        "intraday": {
            "granularity": "15-minute intervals",
            "patterns_found": [
                {
                    "pattern": "Morning peak",
                    "time_range": "09:00-11:00",
                    "impact": "20% higher volume",
                    "recommendation": "Schedule 5 additional agents"
                },
                {
                    "pattern": "Lunch coverage gap",
                    "time_range": "12:00-14:00",
                    "impact": "SLA drops 10%",
                    "recommendation": "Stagger lunch breaks"
                }
            ]
        },
        "daily": {
            "granularity": "Hourly aggregations",
            "patterns_found": [
                {
                    "pattern": "Monday surge",
                    "day": "Monday",
                    "impact": "30% higher volume",
                    "recommendation": "Increase Monday staffing by 25%"
                }
            ]
        },
        "weekly": {
            "granularity": "Daily summaries",
            "patterns_found": [
                {
                    "pattern": "Mid-week efficiency",
                    "days": "Tuesday-Thursday",
                    "impact": "Best SLA performance",
                    "recommendation": "Use as baseline for optimization"
                }
            ]
        },
        "monthly": {
            "granularity": "Weekly trends",
            "patterns_found": [
                {
                    "pattern": "Month-end spike",
                    "period": "Last week",
                    "impact": "15% volume increase",
                    "recommendation": "Plan additional coverage"
                }
            ]
        }
    }
    
    improvement_opportunities = [
        {
            "area": "Recurring SLA breaches",
            "insight": "Systematic understaffing 14:00-16:00",
            "action": "Adjust base schedules"
        },
        {
            "area": "Agent adherence patterns",
            "insight": "Late returns from lunch on Fridays",
            "action": "Targeted coaching"
        },
        {
            "area": "Break timing optimization",
            "insight": "Coverage gaps during break clusters",
            "action": "Optimize break schedules"
        },
        {
            "area": "Forecast accuracy",
            "insight": "Underestimating Tuesday volumes by 15%",
            "action": "Improve forecasting models"
        }
    ]
    
    return {
        "analysis_period": period,
        "data_analyzed": patterns[period],
        "improvement_opportunities": improvement_opportunities,
        "estimated_impact": {
            "sla_improvement": "5-8%",
            "cost_savings": "10-15%",
            "agent_satisfaction": "Improved work-life balance"
        }
    }

@router.get("/monitoring/integration/health", response_model=Dict[str, Any], tags=["monitoring"])
async def monitor_integration_health():
    """
    Monitor Integration Health and Data Quality
    BDD: Scenario: Monitor Integration Health and Data Quality (lines 154-169)
    
    Tracks integration status and data quality metrics
    """
    integrations = [
        {
            "component": "Contact center feed",
            "status": "healthy",
            "data_freshness_seconds": random.randint(1, 10),
            "last_update": (datetime.now() - timedelta(seconds=random.randint(5, 30))).isoformat(),
            "alert_threshold": 300,  # 5 minutes
            "data_quality": {
                "completeness": random.uniform(95, 100),
                "accuracy": random.uniform(98, 100),
                "consistency": random.uniform(97, 100)
            }
        },
        {
            "component": "Agent status updates",
            "status": "warning" if random.random() > 0.8 else "healthy",
            "update_frequency_percent": random.uniform(45, 100),
            "expected_updates_per_minute": 100,
            "actual_updates_per_minute": random.randint(45, 100),
            "data_quality": {
                "completeness": random.uniform(90, 100),
                "temporal_consistency": random.uniform(95, 100),
                "value_reasonableness": random.uniform(98, 100)
            }
        },
        {
            "component": "Queue statistics",
            "status": "healthy",
            "data_completeness_percent": random.uniform(92, 100),
            "missing_metrics": [] if random.random() > 0.2 else ["abandon_rate"],
            "data_quality": {
                "field_presence": random.uniform(95, 100),
                "cross_system_consistency": random.uniform(94, 100)
            }
        },
        {
            "component": "Historical data sync",
            "status": "healthy",
            "sync_success_rate": random.uniform(93, 100),
            "last_successful_sync": (datetime.now() - timedelta(minutes=random.randint(5, 60))).isoformat(),
            "pending_records": random.randint(0, 100)
        }
    ]
    
    # Calculate overall health
    healthy_count = sum(1 for i in integrations if i["status"] == "healthy")
    overall_health = "healthy" if healthy_count == len(integrations) else ("warning" if healthy_count >= 2 else "critical")
    
    return {
        "overall_health": overall_health,
        "integrations": integrations,
        "data_quality_summary": {
            "overall_completeness": random.uniform(94, 99),
            "overall_accuracy": random.uniform(97, 100),
            "anomalies_detected": random.randint(0, 5),
            "validation_errors": random.randint(0, 3)
        },
        "recommendations": [
            "Investigate agent status update frequency drop" if any(i["component"] == "Agent status updates" and i["status"] == "warning" for i in integrations) else None,
            "Review missing queue metrics" if any(i["component"] == "Queue statistics" and i.get("missing_metrics") for i in integrations) else None
        ]
    }

@router.get("/monitoring/mobile", response_model=Dict[str, Any], tags=["monitoring"])
async def get_mobile_monitoring():
    """
    Access Monitoring Capabilities on Mobile Devices
    BDD: Scenario: Access Monitoring Capabilities on Mobile Devices (lines 171-186)
    
    Provides mobile-optimized monitoring interface
    """
    return {
        "mobile_dashboard": {
            "key_metrics": {
                "operators_online": {
                    "value": random.uniform(75, 95),
                    "status": "green",
                    "trend": "stable"
                },
                "sla_performance": {
                    "value": random.uniform(78, 88),
                    "status": "green",
                    "trend": "up"
                },
                "queue_size": {
                    "value": random.randint(5, 25),
                    "status": "yellow" if random.random() > 0.5 else "green",
                    "trend": "down"
                },
                "critical_alerts": {
                    "count": random.randint(0, 3),
                    "unacknowledged": random.randint(0, 2)
                }
            },
            "quick_actions": [
                {
                    "action": "Call operators",
                    "type": "one_touch",
                    "icon": "phone"
                },
                {
                    "action": "Acknowledge alerts",
                    "type": "one_touch",
                    "icon": "check"
                },
                {
                    "action": "Emergency staffing",
                    "type": "emergency",
                    "icon": "warning"
                }
            ],
            "recent_notifications": [
                {
                    "type": "alert",
                    "message": "SLA approaching threshold",
                    "time": "2 min ago",
                    "priority": "high"
                },
                {
                    "type": "info",
                    "message": "Break coverage optimized",
                    "time": "15 min ago",
                    "priority": "low"
                }
            ]
        },
        "mobile_features": {
            "push_notifications_enabled": True,
            "offline_mode_available": True,
            "data_usage_optimization": "enabled",
            "battery_optimization": "enabled",
            "simplified_navigation": True,
            "touch_optimized": True
        },
        "performance_metrics": {
            "data_refresh_interval_seconds": 30,
            "average_load_time_ms": 500,
            "battery_impact": "minimal",
            "network_usage_kb_per_minute": 50
        }
    }

# Additional endpoints for remaining scenarios would follow the same pattern...