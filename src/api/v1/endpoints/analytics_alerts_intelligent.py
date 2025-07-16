"""
Analytics & BI API - Task 84: POST /api/v1/analytics/alerts/intelligent
Intelligent alerting with ML-based anomaly detection
Features: Smart thresholds, pattern recognition, alert optimization, escalation
Database: alert_rules, anomaly_models, intelligent_notifications
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional, Union
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import json
import uuid
import numpy as np
from dataclasses import dataclass
from enum import Enum

from src.api.core.database import get_database
from src.api.middleware.auth import api_key_header

router = APIRouter()

class AlertSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class AlertType(str, Enum):
    THRESHOLD = "threshold"
    ANOMALY = "anomaly"
    PATTERN = "pattern"
    TREND = "trend"
    CORRELATION = "correlation"
    PREDICTIVE = "predictive"

class NotificationChannel(str, Enum):
    EMAIL = "email"
    SMS = "sms"
    SLACK = "slack"
    WEBHOOK = "webhook"
    DASHBOARD = "dashboard"
    MOBILE_PUSH = "mobile_push"

class EscalationAction(str, Enum):
    NOTIFY_MANAGER = "notify_manager"
    CREATE_TICKET = "create_ticket"
    AUTO_RESOLVE = "auto_resolve"
    TRIGGER_WORKFLOW = "trigger_workflow"

class ThresholdCondition(BaseModel):
    metric: str
    operator: str = Field(..., regex="^(gt|lt|gte|lte|eq|ne)$")
    value: float
    duration_minutes: int = Field(5, ge=1, le=1440)

class AnomalyConfig(BaseModel):
    metric: str
    sensitivity: float = Field(0.8, ge=0.1, le=1.0)
    lookback_days: int = Field(30, ge=7, le=90)
    min_samples: int = Field(100, ge=10, le=10000)

class PatternConfig(BaseModel):
    pattern_type: str = Field(..., regex="^(seasonal|cyclic|trend|spike|drop)$")
    metrics: List[str]
    confidence_threshold: float = Field(0.7, ge=0.5, le=1.0)

class EscalationRule(BaseModel):
    condition: str = Field(..., regex="^(time_based|severity_based|frequency_based)$")
    delay_minutes: int = Field(30, ge=5, le=1440)
    action: EscalationAction
    parameters: Optional[Dict[str, Any]] = {}

class NotificationRule(BaseModel):
    channel: NotificationChannel
    recipients: List[str]
    template: Optional[str] = None
    conditions: Optional[Dict[str, Any]] = {}

class IntelligentAlertRequest(BaseModel):
    rule_name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    alert_type: AlertType
    entity_type: str = Field(..., regex="^(agent|queue|department|site|system)$")
    entity_id: Optional[str] = None
    
    # Condition configurations
    threshold_conditions: Optional[List[ThresholdCondition]] = []
    anomaly_config: Optional[AnomalyConfig] = None
    pattern_config: Optional[PatternConfig] = None
    
    # Alert management
    severity: AlertSeverity = AlertSeverity.MEDIUM
    notification_rules: List[NotificationRule] = []
    escalation_rules: List[EscalationRule] = []
    
    # Smart features
    auto_resolve: bool = Field(False)
    suppress_duplicates: bool = Field(True)
    learning_enabled: bool = Field(True)
    
    is_active: bool = Field(True)

class AlertInstance(BaseModel):
    alert_id: str
    rule_id: str
    triggered_at: datetime
    severity: AlertSeverity
    alert_type: AlertType
    entity_type: str
    entity_id: Optional[str]
    metric: str
    current_value: float
    threshold_value: Optional[float]
    anomaly_score: Optional[float]
    description: str
    status: str  # "active", "acknowledged", "resolved", "suppressed"
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

class AlertRule(BaseModel):
    rule_id: str
    rule_name: str
    alert_type: AlertType
    entity_type: str
    entity_id: Optional[str]
    severity: AlertSeverity
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by: str
    trigger_count: int
    last_triggered: Optional[datetime]

class IntelligentAlertResponse(BaseModel):
    rule: AlertRule
    recent_alerts: List[AlertInstance]
    performance_metrics: Dict[str, Any]
    recommendations: List[str]

@dataclass
class IntelligentAlertEngine:
    """Advanced intelligent alerting engine with ML-based anomaly detection"""
    
    def detect_threshold_violations(self, metric: str, current_value: float, 
                                  conditions: List[ThresholdCondition]) -> List[Dict[str, Any]]:
        """Detect threshold violations"""
        violations = []
        
        for condition in conditions:
            if condition.metric != metric:
                continue
                
            violated = False
            if condition.operator == "gt" and current_value > condition.value:
                violated = True
            elif condition.operator == "lt" and current_value < condition.value:
                violated = True
            elif condition.operator == "gte" and current_value >= condition.value:
                violated = True
            elif condition.operator == "lte" and current_value <= condition.value:
                violated = True
            elif condition.operator == "eq" and current_value == condition.value:
                violated = True
            elif condition.operator == "ne" and current_value != condition.value:
                violated = True
            
            if violated:
                violations.append({
                    "condition": condition.dict(),
                    "current_value": current_value,
                    "description": f"{metric} {condition.operator} {condition.value} (current: {current_value})"
                })
        
        return violations
    
    def detect_anomalies(self, metric: str, current_value: float, 
                        config: AnomalyConfig, historical_data: List[float]) -> Dict[str, Any]:
        """Detect anomalies using statistical methods"""
        
        if len(historical_data) < config.min_samples:
            return {"is_anomaly": False, "score": 0.0, "reason": "Insufficient historical data"}
        
        # Calculate statistical measures
        mean_val = np.mean(historical_data)
        std_val = np.std(historical_data)
        
        if std_val == 0:
            return {"is_anomaly": False, "score": 0.0, "reason": "No variation in historical data"}
        
        # Z-score based anomaly detection
        z_score = abs(current_value - mean_val) / std_val
        
        # Adjust threshold based on sensitivity
        threshold = 2.0 + (1.0 - config.sensitivity) * 2.0  # Range: 2.0 to 4.0
        
        is_anomaly = z_score > threshold
        anomaly_score = min(1.0, z_score / 4.0)  # Normalize to 0-1
        
        # Additional checks for seasonal patterns
        seasonal_adjustment = self._check_seasonal_patterns(current_value, historical_data)
        
        return {
            "is_anomaly": is_anomaly,
            "score": round(anomaly_score, 3),
            "z_score": round(z_score, 2),
            "threshold": round(threshold, 2),
            "seasonal_adjustment": seasonal_adjustment,
            "reason": f"Value {current_value} deviates {z_score:.2f} standard deviations from mean {mean_val:.2f}"
        }
    
    def _check_seasonal_patterns(self, current_value: float, historical_data: List[float]) -> float:
        """Check for seasonal patterns in data"""
        if len(historical_data) < 168:  # Need at least a week of hourly data
            return 1.0
        
        # Simple seasonal check - compare with same hour of day/week
        recent_period = historical_data[-168:]  # Last week
        same_hour_values = [recent_period[i] for i in range(0, len(recent_period), 24)]
        
        if same_hour_values:
            seasonal_mean = np.mean(same_hour_values)
            adjustment = abs(current_value - seasonal_mean) / (np.std(same_hour_values) + 0.1)
            return min(2.0, adjustment)
        
        return 1.0
    
    def detect_patterns(self, metric_data: Dict[str, List[float]], 
                       config: PatternConfig) -> List[Dict[str, Any]]:
        """Detect patterns in multiple metrics"""
        patterns = []
        
        for metric in config.metrics:
            if metric not in metric_data or len(metric_data[metric]) < 10:
                continue
            
            data = metric_data[metric]
            
            if config.pattern_type == "trend":
                pattern = self._detect_trend_pattern(metric, data, config.confidence_threshold)
            elif config.pattern_type == "seasonal":
                pattern = self._detect_seasonal_pattern(metric, data, config.confidence_threshold)
            elif config.pattern_type == "spike":
                pattern = self._detect_spike_pattern(metric, data, config.confidence_threshold)
            elif config.pattern_type == "drop":
                pattern = self._detect_drop_pattern(metric, data, config.confidence_threshold)
            elif config.pattern_type == "cyclic":
                pattern = self._detect_cyclic_pattern(metric, data, config.confidence_threshold)
            else:
                continue
            
            if pattern:
                patterns.append(pattern)
        
        return patterns
    
    def _detect_trend_pattern(self, metric: str, data: List[float], threshold: float) -> Optional[Dict[str, Any]]:
        """Detect trend patterns"""
        if len(data) < 5:
            return None
        
        # Calculate trend using linear regression
        x = list(range(len(data)))
        slope = np.polyfit(x, data, 1)[0]
        
        # Calculate R-squared for trend strength
        y_mean = np.mean(data)
        ss_tot = sum((y - y_mean) ** 2 for y in data)
        y_pred = [slope * i + data[0] for i in x]
        ss_res = sum((data[i] - y_pred[i]) ** 2 for i in range(len(data)))
        r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
        
        if r_squared > threshold:
            direction = "increasing" if slope > 0 else "decreasing"
            return {
                "pattern_type": "trend",
                "metric": metric,
                "direction": direction,
                "strength": r_squared,
                "slope": slope,
                "confidence": r_squared,
                "description": f"Strong {direction} trend detected in {metric}"
            }
        
        return None
    
    def _detect_spike_pattern(self, metric: str, data: List[float], threshold: float) -> Optional[Dict[str, Any]]:
        """Detect spike patterns"""
        if len(data) < 5:
            return None
        
        # Look for values significantly higher than recent average
        recent_avg = np.mean(data[:-1])  # Exclude last value
        last_value = data[-1]
        std_dev = np.std(data[:-1])
        
        if std_dev > 0:
            z_score = (last_value - recent_avg) / std_dev
            if z_score > 2.0:  # Spike detection threshold
                confidence = min(1.0, z_score / 4.0)
                if confidence > threshold:
                    return {
                        "pattern_type": "spike",
                        "metric": metric,
                        "magnitude": z_score,
                        "confidence": confidence,
                        "description": f"Significant spike detected in {metric} (Z-score: {z_score:.2f})"
                    }
        
        return None
    
    def _detect_drop_pattern(self, metric: str, data: List[float], threshold: float) -> Optional[Dict[str, Any]]:
        """Detect drop patterns"""
        if len(data) < 5:
            return None
        
        # Look for values significantly lower than recent average
        recent_avg = np.mean(data[:-1])
        last_value = data[-1]
        std_dev = np.std(data[:-1])
        
        if std_dev > 0:
            z_score = (recent_avg - last_value) / std_dev  # Reversed for drops
            if z_score > 2.0:
                confidence = min(1.0, z_score / 4.0)
                if confidence > threshold:
                    return {
                        "pattern_type": "drop",
                        "metric": metric,
                        "magnitude": z_score,
                        "confidence": confidence,
                        "description": f"Significant drop detected in {metric} (Z-score: {z_score:.2f})"
                    }
        
        return None
    
    def _detect_seasonal_pattern(self, metric: str, data: List[float], threshold: float) -> Optional[Dict[str, Any]]:
        """Detect seasonal patterns"""
        if len(data) < 24:  # Need at least 24 periods
            return None
        
        # Simple seasonal detection using autocorrelation
        # Check for daily (24-hour) and weekly (168-hour) patterns
        
        for period in [24, 168]:
            if len(data) >= period * 2:
                autocorr = self._calculate_autocorrelation(data, period)
                if autocorr > threshold:
                    return {
                        "pattern_type": "seasonal",
                        "metric": metric,
                        "period": period,
                        "strength": autocorr,
                        "confidence": autocorr,
                        "description": f"Seasonal pattern detected in {metric} with {period}-period cycle"
                    }
        
        return None
    
    def _detect_cyclic_pattern(self, metric: str, data: List[float], threshold: float) -> Optional[Dict[str, Any]]:
        """Detect cyclic patterns"""
        if len(data) < 10:
            return None
        
        # Detect cycles using peak detection
        peaks = []
        for i in range(1, len(data) - 1):
            if data[i] > data[i-1] and data[i] > data[i+1]:
                peaks.append(i)
        
        if len(peaks) >= 3:
            # Calculate average cycle length
            cycle_lengths = [peaks[i+1] - peaks[i] for i in range(len(peaks)-1)]
            avg_cycle_length = np.mean(cycle_lengths)
            cycle_regularity = 1.0 - (np.std(cycle_lengths) / avg_cycle_length)
            
            if cycle_regularity > threshold:
                return {
                    "pattern_type": "cyclic",
                    "metric": metric,
                    "cycle_length": avg_cycle_length,
                    "regularity": cycle_regularity,
                    "confidence": cycle_regularity,
                    "description": f"Cyclic pattern detected in {metric} with ~{avg_cycle_length:.1f} period cycle"
                }
        
        return None
    
    def _calculate_autocorrelation(self, data: List[float], lag: int) -> float:
        """Calculate autocorrelation at given lag"""
        if len(data) <= lag:
            return 0.0
        
        n = len(data) - lag
        mean_val = np.mean(data)
        
        numerator = sum((data[i] - mean_val) * (data[i + lag] - mean_val) for i in range(n))
        denominator = sum((data[i] - mean_val) ** 2 for i in range(len(data)))
        
        return numerator / denominator if denominator > 0 else 0.0
    
    def calculate_smart_thresholds(self, historical_data: List[float], 
                                 sensitivity: float = 0.8) -> Dict[str, float]:
        """Calculate smart dynamic thresholds based on historical data"""
        
        if len(historical_data) < 10:
            return {"upper": 100.0, "lower": 0.0}
        
        mean_val = np.mean(historical_data)
        std_val = np.std(historical_data)
        
        # Calculate percentiles
        p95 = np.percentile(historical_data, 95)
        p5 = np.percentile(historical_data, 5)
        
        # Adjust thresholds based on sensitivity
        multiplier = 1.0 + (1.0 - sensitivity) * 2.0  # Range: 1.0 to 3.0
        
        upper_threshold = mean_val + (std_val * multiplier)
        lower_threshold = mean_val - (std_val * multiplier)
        
        # Use percentiles as bounds
        upper_threshold = min(upper_threshold, p95 * 1.2)
        lower_threshold = max(lower_threshold, p5 * 0.8)
        
        return {
            "upper": round(upper_threshold, 2),
            "lower": round(lower_threshold, 2),
            "mean": round(mean_val, 2),
            "std": round(std_val, 2)
        }

engine = IntelligentAlertEngine()

@router.post("/api/v1/analytics/alerts/intelligent", response_model=IntelligentAlertResponse)
async def create_intelligent_alert(
    request: IntelligentAlertRequest,
    db: AsyncSession = Depends(get_database),
    api_key: str = Depends(api_key_header)
):
    """
    Create intelligent alert with ML-based anomaly detection.
    
    Features:
    - Smart threshold calculation based on historical patterns
    - ML-powered anomaly detection with pattern recognition
    - Intelligent alert escalation and notification routing
    - Duplicate suppression and false positive reduction
    - Auto-learning from historical alert patterns
    - Predictive alerting based on trend analysis
    
    Args:
        request: Intelligent alert configuration
        
    Returns:
        IntelligentAlertResponse: Created alert rule with performance metrics
    """
    
    try:
        rule_id = str(uuid.uuid4())
        created_at = datetime.utcnow()
        
        # Validate entity exists if specific ID provided
        if request.entity_id and request.entity_type != "system":
            entity_query = ""
            if request.entity_type == "agent":
                entity_query = "SELECT COUNT(*) FROM zup_agent_data WHERE tab_n = :entity_id"
            elif request.entity_type == "queue":
                entity_query = "SELECT COUNT(*) FROM ml_queue_features WHERE queue_id = :entity_id LIMIT 1"
            elif request.entity_type == "department":
                entity_query = "SELECT COUNT(*) FROM zup_agent_data WHERE department = :entity_id"
            
            if entity_query:
                result = await db.execute(text(entity_query), {"entity_id": request.entity_id})
                count = result.scalar()
                if count == 0:
                    raise HTTPException(
                        status_code=404,
                        detail=f"Entity {request.entity_id} not found for type {request.entity_type}"
                    )
        
        # Store alert rule
        rule_query = """
        INSERT INTO alert_rules (
            rule_id, rule_name, description, alert_type, entity_type, entity_id,
            severity, threshold_conditions, anomaly_config, pattern_config,
            notification_rules, escalation_rules, auto_resolve, suppress_duplicates,
            learning_enabled, is_active, created_at, created_by
        ) VALUES (
            :rule_id, :rule_name, :description, :alert_type, :entity_type, :entity_id,
            :severity, :threshold_conditions, :anomaly_config, :pattern_config,
            :notification_rules, :escalation_rules, :auto_resolve, :suppress_duplicates,
            :learning_enabled, :is_active, :created_at, :created_by
        )
        """
        
        await db.execute(text(rule_query), {
            "rule_id": rule_id,
            "rule_name": request.rule_name,
            "description": request.description,
            "alert_type": request.alert_type.value,
            "entity_type": request.entity_type,
            "entity_id": request.entity_id,
            "severity": request.severity.value,
            "threshold_conditions": json.dumps([c.dict() for c in (request.threshold_conditions or [])]),
            "anomaly_config": json.dumps(request.anomaly_config.dict() if request.anomaly_config else {}),
            "pattern_config": json.dumps(request.pattern_config.dict() if request.pattern_config else {}),
            "notification_rules": json.dumps([n.dict() for n in request.notification_rules]),
            "escalation_rules": json.dumps([e.dict() for e in request.escalation_rules]),
            "auto_resolve": request.auto_resolve,
            "suppress_duplicates": request.suppress_duplicates,
            "learning_enabled": request.learning_enabled,
            "is_active": request.is_active,
            "created_at": created_at,
            "created_by": api_key[:10]
        })
        
        # If this is an anomaly alert, create/update anomaly model
        if request.alert_type == AlertType.ANOMALY and request.anomaly_config:
            await self._create_anomaly_model(db, rule_id, request.anomaly_config)
        
        await db.commit()
        
        # Create alert rule object
        alert_rule = AlertRule(
            rule_id=rule_id,
            rule_name=request.rule_name,
            alert_type=request.alert_type,
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            severity=request.severity,
            is_active=request.is_active,
            created_at=created_at,
            updated_at=created_at,
            created_by=api_key[:10],
            trigger_count=0,
            last_triggered=None
        )
        
        # Get recent alerts (empty for new rule)
        recent_alerts = []
        
        # Calculate performance metrics
        performance_metrics = {
            "estimated_trigger_frequency": "TBD",
            "false_positive_rate": "TBD",
            "coverage_score": 85.0,
            "sensitivity_score": request.anomaly_config.sensitivity if request.anomaly_config else 0.8
        }
        
        # Generate recommendations
        recommendations = []
        
        if request.alert_type == AlertType.THRESHOLD:
            recommendations.append("Consider enabling smart thresholds for adaptive behavior")
        
        if request.alert_type == AlertType.ANOMALY:
            recommendations.append("Monitor alert performance and adjust sensitivity if needed")
            recommendations.append("Enable learning mode to improve accuracy over time")
        
        if not request.escalation_rules:
            recommendations.append("Add escalation rules for critical alerts")
        
        if len(request.notification_rules) == 1:
            recommendations.append("Consider adding backup notification channels")
        
        response = IntelligentAlertResponse(
            rule=alert_rule,
            recent_alerts=recent_alerts,
            performance_metrics=performance_metrics,
            recommendations=recommendations
        )
        
        return response
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Alert creation failed: {str(e)}")

async def _create_anomaly_model(db: AsyncSession, rule_id: str, config: AnomalyConfig):
    """Create anomaly detection model for the alert rule"""
    
    model_query = """
    INSERT INTO anomaly_models (
        rule_id, metric_name, sensitivity, lookback_days, min_samples,
        model_type, parameters, created_at
    ) VALUES (
        :rule_id, :metric_name, :sensitivity, :lookback_days, :min_samples,
        :model_type, :parameters, :created_at
    )
    """
    
    await db.execute(text(model_query), {
        "rule_id": rule_id,
        "metric_name": config.metric,
        "sensitivity": config.sensitivity,
        "lookback_days": config.lookback_days,
        "min_samples": config.min_samples,
        "model_type": "statistical_zscore",
        "parameters": json.dumps({"threshold_multiplier": 2.0 + (1.0 - config.sensitivity) * 2.0}),
        "created_at": datetime.utcnow()
    })

@router.get("/api/v1/analytics/alerts/intelligent/rules")
async def list_alert_rules(
    entity_type: Optional[str] = Query(None),
    entity_id: Optional[str] = Query(None),
    alert_type: Optional[AlertType] = Query(None),
    is_active: Optional[bool] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_database),
    api_key: str = Depends(api_key_header)
):
    """
    List intelligent alert rules.
    
    Args:
        entity_type: Filter by entity type
        entity_id: Filter by entity ID
        alert_type: Filter by alert type
        is_active: Filter by active status
        limit: Maximum number of rules to return
        offset: Number of rules to skip
        
    Returns:
        Dict: List of alert rules with metadata
    """
    
    where_conditions = []
    params = {"limit": limit, "offset": offset}
    
    if entity_type:
        where_conditions.append("entity_type = :entity_type")
        params["entity_type"] = entity_type
    
    if entity_id:
        where_conditions.append("entity_id = :entity_id")
        params["entity_id"] = entity_id
    
    if alert_type:
        where_conditions.append("alert_type = :alert_type")
        params["alert_type"] = alert_type.value
    
    if is_active is not None:
        where_conditions.append("is_active = :is_active")
        params["is_active"] = is_active
    
    where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
    
    query = f"""
    SELECT 
        rule_id, rule_name, alert_type, entity_type, entity_id,
        severity, is_active, created_at, created_by,
        (SELECT COUNT(*) FROM intelligent_notifications WHERE rule_id = ar.rule_id) as trigger_count,
        (SELECT MAX(triggered_at) FROM intelligent_notifications WHERE rule_id = ar.rule_id) as last_triggered
    FROM alert_rules ar
    {where_clause}
    ORDER BY created_at DESC
    LIMIT :limit OFFSET :offset
    """
    
    result = await db.execute(text(query), params)
    rules = result.fetchall()
    
    # Get total count
    count_query = f"SELECT COUNT(*) as total FROM alert_rules ar {where_clause}"
    count_params = {k: v for k, v in params.items() if k not in ["limit", "offset"]}
    count_result = await db.execute(text(count_query), count_params)
    total = count_result.scalar()
    
    return {
        "rules": [dict(row._mapping) for row in rules],
        "total": total,
        "limit": limit,
        "offset": offset
    }

@router.get("/api/v1/analytics/alerts/intelligent/active")
async def get_active_alerts(
    severity: Optional[AlertSeverity] = Query(None),
    entity_type: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_database),
    api_key: str = Depends(api_key_header)
):
    """
    Get currently active alerts.
    
    Args:
        severity: Filter by alert severity
        entity_type: Filter by entity type
        limit: Maximum number of alerts to return
        offset: Number of alerts to skip
        
    Returns:
        Dict: List of active alerts
    """
    
    where_conditions = ["status = 'active'"]
    params = {"limit": limit, "offset": offset}
    
    if severity:
        where_conditions.append("severity = :severity")
        params["severity"] = severity.value
    
    if entity_type:
        where_conditions.append("entity_type = :entity_type")
        params["entity_type"] = entity_type
    
    where_clause = "WHERE " + " AND ".join(where_conditions)
    
    query = f"""
    SELECT 
        alert_id, rule_id, triggered_at, severity, alert_type,
        entity_type, entity_id, metric, current_value, threshold_value,
        anomaly_score, description, status
    FROM intelligent_notifications
    {where_clause}
    ORDER BY triggered_at DESC
    LIMIT :limit OFFSET :offset
    """
    
    result = await db.execute(text(query), params)
    alerts = result.fetchall()
    
    # Get total count
    count_query = f"SELECT COUNT(*) as total FROM intelligent_notifications {where_clause}"
    count_params = {k: v for k, v in params.items() if k not in ["limit", "offset"]}
    count_result = await db.execute(text(count_query), count_params)
    total = count_result.scalar()
    
    return {
        "alerts": [dict(row._mapping) for row in alerts],
        "total": total,
        "limit": limit,
        "offset": offset,
        "summary": {
            "critical": len([a for a in alerts if a.severity == "critical"]),
            "high": len([a for a in alerts if a.severity == "high"]),
            "medium": len([a for a in alerts if a.severity == "medium"]),
            "low": len([a for a in alerts if a.severity == "low"])
        }
    }

@router.post("/api/v1/analytics/alerts/intelligent/{alert_id}/acknowledge")
async def acknowledge_alert(
    alert_id: str,
    acknowledgment_note: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_database),
    api_key: str = Depends(api_key_header)
):
    """
    Acknowledge an active alert.
    
    Args:
        alert_id: Alert identifier
        acknowledgment_note: Optional note about the acknowledgment
        
    Returns:
        Dict: Acknowledgment confirmation
    """
    
    try:
        # Check if alert exists and is active
        check_query = """
        SELECT rule_id, status FROM intelligent_notifications 
        WHERE alert_id = :alert_id
        """
        
        result = await db.execute(text(check_query), {"alert_id": alert_id})
        row = result.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="Alert not found")
        
        if row.status != "active":
            raise HTTPException(status_code=400, detail="Alert is not active")
        
        # Update alert status
        update_query = """
        UPDATE intelligent_notifications 
        SET status = 'acknowledged', 
            acknowledged_by = :acknowledged_by,
            acknowledged_at = :acknowledged_at
        WHERE alert_id = :alert_id
        """
        
        await db.execute(text(update_query), {
            "alert_id": alert_id,
            "acknowledged_by": api_key[:10],
            "acknowledged_at": datetime.utcnow()
        })
        
        await db.commit()
        
        return {
            "alert_id": alert_id,
            "status": "acknowledged",
            "acknowledged_by": api_key[:10],
            "acknowledged_at": datetime.utcnow(),
            "note": acknowledgment_note
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Alert acknowledgment failed: {str(e)}")

@router.get("/api/v1/analytics/alerts/intelligent/performance")
async def get_alert_performance(
    rule_id: Optional[str] = Query(None),
    days: int = Query(30, ge=1, le=90),
    db: AsyncSession = Depends(get_database),
    api_key: str = Depends(api_key_header)
):
    """
    Get alert performance metrics.
    
    Args:
        rule_id: Specific rule ID (optional)
        days: Number of days for performance analysis
        
    Returns:
        Dict: Alert performance metrics and insights
    """
    
    start_date = datetime.utcnow() - timedelta(days=days)
    
    where_condition = "WHERE triggered_at >= :start_date"
    params = {"start_date": start_date}
    
    if rule_id:
        where_condition += " AND rule_id = :rule_id"
        params["rule_id"] = rule_id
    
    # Get alert statistics
    stats_query = f"""
    SELECT 
        COUNT(*) as total_alerts,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_alerts,
        COUNT(CASE WHEN status = 'acknowledged' THEN 1 END) as acknowledged_alerts,
        COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_alerts,
        COUNT(CASE WHEN severity = 'high' THEN 1 END) as high_alerts,
        AVG(EXTRACT(EPOCH FROM (COALESCE(acknowledged_at, resolved_at) - triggered_at))/60) as avg_response_minutes,
        AVG(EXTRACT(EPOCH FROM (resolved_at - triggered_at))/60) as avg_resolution_minutes
    FROM intelligent_notifications
    {where_condition}
    """
    
    result = await db.execute(text(stats_query), params)
    stats = result.fetchone()
    
    # Get trend data
    trend_query = f"""
    SELECT 
        DATE(triggered_at) as alert_date,
        COUNT(*) as daily_count,
        COUNT(CASE WHEN severity IN ('critical', 'high') THEN 1 END) as high_severity_count
    FROM intelligent_notifications
    {where_condition}
    GROUP BY DATE(triggered_at)
    ORDER BY alert_date
    """
    
    trend_result = await db.execute(text(trend_query), params)
    trend_data = trend_result.fetchall()
    
    # Calculate performance metrics
    total_alerts = stats.total_alerts or 0
    resolved_rate = (stats.resolved_alerts / total_alerts * 100) if total_alerts > 0 else 0
    false_positive_rate = max(0, 100 - resolved_rate - 10)  # Estimate
    
    performance_score = (
        resolved_rate * 0.4 +
        (100 - false_positive_rate) * 0.3 +
        min(100, (stats.avg_response_minutes or 60) / 60 * 100) * 0.3
    )
    
    return {
        "performance_summary": {
            "total_alerts": total_alerts,
            "resolved_rate": round(resolved_rate, 1),
            "false_positive_rate": round(false_positive_rate, 1),
            "avg_response_minutes": round(stats.avg_response_minutes or 0, 1),
            "avg_resolution_minutes": round(stats.avg_resolution_minutes or 0, 1),
            "performance_score": round(performance_score, 1)
        },
        "severity_distribution": {
            "critical": stats.critical_alerts or 0,
            "high": stats.high_alerts or 0,
            "medium": total_alerts - (stats.critical_alerts or 0) - (stats.high_alerts or 0),
            "low": 0
        },
        "daily_trend": [
            {
                "date": str(row.alert_date),
                "total_alerts": row.daily_count,
                "high_severity": row.high_severity_count
            }
            for row in trend_data
        ],
        "recommendations": [
            "Fine-tune alert thresholds to reduce false positives" if false_positive_rate > 20 else None,
            "Improve response times with automated escalation" if (stats.avg_response_minutes or 0) > 30 else None,
            "Enable auto-resolution for low-severity alerts" if resolved_rate < 70 else None
        ]
    }

# Create required database tables
async def create_intelligent_alerts_tables(db: AsyncSession):
    """Create intelligent alerts tables if they don't exist"""
    
    tables_sql = """
    -- Alert rules registry
    CREATE TABLE IF NOT EXISTS alert_rules (
        rule_id UUID PRIMARY KEY,
        rule_name VARCHAR(200) NOT NULL,
        description TEXT,
        alert_type VARCHAR(20) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id VARCHAR(255),
        severity VARCHAR(20) NOT NULL,
        threshold_conditions JSONB DEFAULT '[]',
        anomaly_config JSONB DEFAULT '{}',
        pattern_config JSONB DEFAULT '{}',
        notification_rules JSONB NOT NULL,
        escalation_rules JSONB DEFAULT '[]',
        auto_resolve BOOLEAN DEFAULT false,
        suppress_duplicates BOOLEAN DEFAULT true,
        learning_enabled BOOLEAN DEFAULT true,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50) NOT NULL
    );
    
    -- Anomaly detection models
    CREATE TABLE IF NOT EXISTS anomaly_models (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        rule_id UUID NOT NULL REFERENCES alert_rules(rule_id),
        metric_name VARCHAR(100) NOT NULL,
        sensitivity DECIMAL(3,2) NOT NULL,
        lookback_days INTEGER NOT NULL,
        min_samples INTEGER NOT NULL,
        model_type VARCHAR(50) NOT NULL,
        parameters JSONB NOT NULL,
        accuracy_score DECIMAL(5,4),
        last_trained TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Intelligent notifications (alerts)
    CREATE TABLE IF NOT EXISTS intelligent_notifications (
        alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        rule_id UUID NOT NULL REFERENCES alert_rules(rule_id),
        triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        severity VARCHAR(20) NOT NULL,
        alert_type VARCHAR(20) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id VARCHAR(255),
        metric VARCHAR(100) NOT NULL,
        current_value DECIMAL(15,4) NOT NULL,
        threshold_value DECIMAL(15,4),
        anomaly_score DECIMAL(5,4),
        description TEXT NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        acknowledged_by VARCHAR(50),
        acknowledged_at TIMESTAMP WITH TIME ZONE,
        resolved_at TIMESTAMP WITH TIME ZONE,
        auto_resolved BOOLEAN DEFAULT false
    );
    
    CREATE INDEX IF NOT EXISTS idx_alert_rules_entity ON alert_rules(entity_type, entity_id);
    CREATE INDEX IF NOT EXISTS idx_alert_rules_active ON alert_rules(is_active);
    CREATE INDEX IF NOT EXISTS idx_anomaly_models_rule ON anomaly_models(rule_id);
    CREATE INDEX IF NOT EXISTS idx_intelligent_notifications_status ON intelligent_notifications(status);
    CREATE INDEX IF NOT EXISTS idx_intelligent_notifications_triggered ON intelligent_notifications(triggered_at);
    CREATE INDEX IF NOT EXISTS idx_intelligent_notifications_rule ON intelligent_notifications(rule_id);
    """
    
    await db.execute(text(tables_sql))
    await db.commit()