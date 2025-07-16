"""
Task 53: POST /api/v1/performance/alerts/configure
BDD Scenario: Configure Performance Alerts
Based on: 15-real-time-monitoring-operational-control.feature lines 67-100

Performance alerts configuration endpoint implementing exact BDD requirements:
- Threshold-based alert configuration 
- Predictive alert setup with lead times
- Real database operations on threshold_alerts and predictive_alerts tables
- Alert response actions and escalation timelines per BDD specifications
"""

from fastapi import APIRouter, HTTPException, Body
from sqlalchemy import text
from typing import Dict, List, Optional, Any, Union
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
import psycopg2
import psycopg2.extras
import logging
import uuid

# Database connection
def get_db_connection():
    """Get database connection for WFM Enterprise"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="wfm_enterprise", 
            user="postgres",
            password="password"
        )
        return conn
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# BDD Request Models - Based on feature lines 67-100
class ThresholdAlertConfig(BaseModel):
    """Threshold-based alert configuration from BDD lines 72-76"""
    alert_type: str = Field(..., description="Type of threshold alert")
    threshold: float = Field(..., description="Threshold value that triggers alert")
    condition: str = Field(..., description="Alert condition (e.g., '<70% for 5 minutes')")
    response_actions: List[str] = Field(..., description="Response actions to take")
    
    class Config:
        schema_extra = {
            "example": {
                "alert_type": "Critical understaffing",
                "threshold": 70.0,
                "condition": "Online % <70%",
                "response_actions": ["SMS + email to management"]
            }
        }

class PredictiveAlertConfig(BaseModel):
    """Predictive alert configuration from BDD lines 84-100"""
    prediction_type: str = Field(..., description="Type of predictive alert")
    lead_time_minutes: int = Field(..., description="Lead time for prediction")
    confidence_threshold: float = Field(..., description="Minimum confidence percentage")
    analysis_factors: Dict[str, float] = Field(..., description="Prediction factor weights")
    
    class Config:
        schema_extra = {
            "example": {
                "prediction_type": "Approaching SLA breach",
                "lead_time_minutes": 30,
                "confidence_threshold": 75.0,
                "analysis_factors": {
                    "historical_patterns": 0.80,
                    "current_trends": 0.75,
                    "scheduled_events": 0.95,
                    "external_factors": 0.70
                }
            }
        }

class AlertConfigurationRequest(BaseModel):
    """Complete alert configuration request"""
    threshold_alerts: List[ThresholdAlertConfig]
    predictive_alerts: List[PredictiveAlertConfig]
    notification_settings: Dict[str, Any] = Field(default_factory=dict)
    enabled: bool = Field(default=True, description="Enable/disable alert system")

class AlertConfigurationResponse(BaseModel):
    """Alert configuration response"""
    configuration_id: str
    threshold_alerts_configured: int
    predictive_alerts_configured: int
    validation_results: List[str]
    status: str
    configured_at: datetime
    bdd_scenario: str = "Configure Performance Alerts"

router = APIRouter()

@router.post("/performance/alerts/configure", response_model=AlertConfigurationResponse)
async def configure_performance_alerts(
    config_request: AlertConfigurationRequest = Body(...)
):
    """
    Configure Performance Alerts
    
    BDD Implementation from 15-real-time-monitoring-operational-control.feature:
    - Scenario: Configure and Respond to Threshold-Based Alerts (lines 67-83)
    - Scenario: Generate Predictive Alerts for Potential Issues (lines 84-100)
    - Real database configuration storage and validation
    """
    
    conn = get_db_connection()
    configuration_id = str(uuid.uuid4())
    validation_results = []
    
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # Begin transaction for atomic configuration
            cur.execute("BEGIN")
            
            # Configure threshold-based alerts from BDD lines 67-83
            threshold_count = 0
            for threshold_alert in config_request.threshold_alerts:
                
                # Validate alert type against BDD specifications
                valid_alert_types = [
                    'Critical understaffing',   # Online % <70%
                    'Service level breach',     # 80/20 format <70% for 5 minutes
                    'System overload',          # Queue >20 contacts  
                    'Extended outages'          # No data for 10 minutes
                ]
                
                if threshold_alert.alert_type not in valid_alert_types:
                    validation_results.append(f"Invalid alert type: {threshold_alert.alert_type}")
                    continue
                
                # Validate threshold values per BDD
                threshold_validation = True
                if threshold_alert.alert_type == 'Critical understaffing' and threshold_alert.threshold >= 70:
                    validation_results.append("Critical understaffing threshold must be <70%")
                    threshold_validation = False
                elif threshold_alert.alert_type == 'System overload' and threshold_alert.threshold <= 20:
                    validation_results.append("System overload threshold must be >20 contacts")
                    threshold_validation = False
                
                if not threshold_validation:
                    continue
                
                # Insert threshold alert configuration
                cur.execute("""
                    INSERT INTO threshold_alerts (
                        alert_trigger, alert_type, threshold_value, current_value,
                        response_actions, suggested_actions, severity, alert_status
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                """, (
                    f"{threshold_alert.alert_type} configuration",
                    threshold_alert.alert_type,
                    threshold_alert.threshold,
                    0.0,  # Will be updated in real-time
                    threshold_alert.response_actions,
                    ["Monitor situation", "Take corrective action", "Escalate if needed"],
                    'High' if 'Critical' in threshold_alert.alert_type else 'Medium',
                    'Configured'
                ))
                
                threshold_count += 1
                validation_results.append(f"Configured threshold alert: {threshold_alert.alert_type}")
            
            # Configure predictive alerts from BDD lines 84-100
            predictive_count = 0
            for predictive_alert in config_request.predictive_alerts:
                
                # Validate prediction type against BDD specifications
                valid_prediction_types = [
                    'Approaching SLA breach',      # 15-30 minutes lead time
                    'Staffing shortfall',          # 1-2 hours lead time
                    'Break/lunch coverage gaps',   # 30-60 minutes lead time
                    'Peak load preparation'        # 2-4 hours lead time
                ]
                
                if predictive_alert.prediction_type not in valid_prediction_types:
                    validation_results.append(f"Invalid prediction type: {predictive_alert.prediction_type}")
                    continue
                
                # Validate lead times per BDD specifications
                lead_time_ranges = {
                    'Approaching SLA breach': (15, 30),
                    'Staffing shortfall': (60, 120),
                    'Break/lunch coverage gaps': (30, 60),
                    'Peak load preparation': (120, 240)
                }
                
                min_lead, max_lead = lead_time_ranges[predictive_alert.prediction_type]
                if not (min_lead <= predictive_alert.lead_time_minutes <= max_lead):
                    validation_results.append(
                        f"Lead time for {predictive_alert.prediction_type} must be {min_lead}-{max_lead} minutes"
                    )
                    continue
                
                # Validate analysis factors against BDD accuracy targets
                factors = predictive_alert.analysis_factors
                expected_accuracies = {
                    'historical_patterns': 0.80,  # 80% accuracy target
                    'current_trends': 0.75,       # 75% accuracy target
                    'scheduled_events': 0.95,     # 95% accuracy target
                    'external_factors': 0.70      # 70% accuracy target
                }
                
                for factor, expected in expected_accuracies.items():
                    if factor in factors and factors[factor] > expected + 0.1:
                        validation_results.append(
                            f"Factor {factor} confidence {factors[factor]} exceeds realistic target {expected}"
                        )
                
                # Insert predictive alert configuration
                cur.execute("""
                    INSERT INTO predictive_alerts (
                        prediction_type, analysis_method, lead_time_minutes, confidence_percentage,
                        historical_patterns_weight, current_trends_weight, 
                        scheduled_events_weight, external_factors_weight,
                        event_time
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                """, (
                    predictive_alert.prediction_type,
                    f"Multi-factor analysis for {predictive_alert.prediction_type}",
                    predictive_alert.lead_time_minutes,
                    predictive_alert.confidence_threshold,
                    factors.get('historical_patterns', 0.80),
                    factors.get('current_trends', 0.75),
                    factors.get('scheduled_events', 0.95),
                    factors.get('external_factors', 0.70),
                    datetime.now() + timedelta(minutes=predictive_alert.lead_time_minutes)
                ))
                
                predictive_count += 1
                validation_results.append(f"Configured predictive alert: {predictive_alert.prediction_type}")
            
            # Update operational alert configuration
            cur.execute("""
                INSERT INTO operational_notification_preferences (
                    employee_tab_n, operational_alerts_delivery, 
                    relevance_filtering_enabled, frequency_limiting_enabled,
                    priority_escalation_enabled
                ) VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (employee_tab_n) DO UPDATE SET
                    operational_alerts_delivery = EXCLUDED.operational_alerts_delivery,
                    relevance_filtering_enabled = EXCLUDED.relevance_filtering_enabled,
                    updated_at = CURRENT_TIMESTAMP
            """, (
                'SYSTEM_ADMIN',  # System-wide configuration
                config_request.notification_settings.get('delivery_method', 'In-app, email, SMS'),
                config_request.notification_settings.get('relevance_filtering', True),
                config_request.notification_settings.get('frequency_limiting', True),
                config_request.notification_settings.get('priority_escalation', True)
            ))
            
            # Commit transaction
            cur.execute("COMMIT")
            
            # Determine overall status
            total_alerts = len(config_request.threshold_alerts) + len(config_request.predictive_alerts)
            configured_alerts = threshold_count + predictive_count
            
            if configured_alerts == total_alerts:
                status = "Configuration completed successfully"
            elif configured_alerts > 0:
                status = f"Partial configuration: {configured_alerts}/{total_alerts} alerts configured"
            else:
                status = "Configuration failed - no alerts configured"
                
            return AlertConfigurationResponse(
                configuration_id=configuration_id,
                threshold_alerts_configured=threshold_count,
                predictive_alerts_configured=predictive_count,
                validation_results=validation_results,
                status=status,
                configured_at=datetime.now()
            )
            
    except psycopg2.Error as e:
        # Rollback on database error
        try:
            cur.execute("ROLLBACK")
        except:
            pass
        logging.error(f"Database error in alert configuration: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        # Rollback on any error
        try:
            cur.execute("ROLLBACK")
        except:
            pass
        logging.error(f"Unexpected error in alert configuration: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

# Additional endpoint to get current alert configurations
@router.get("/performance/alerts/configure")
async def get_alert_configurations():
    """
    Get Current Alert Configurations
    
    Returns currently configured threshold and predictive alerts
    """
    
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # Get threshold alert configurations
            cur.execute("""
                SELECT 
                    alert_type,
                    threshold_value,
                    response_actions,
                    severity,
                    alert_status,
                    triggered_at
                FROM threshold_alerts
                WHERE alert_status IN ('Configured', 'Active')
                ORDER BY triggered_at DESC
            """)
            threshold_alerts = cur.fetchall()
            
            # Get predictive alert configurations  
            cur.execute("""
                SELECT 
                    prediction_type,
                    lead_time_minutes,
                    confidence_percentage,
                    historical_patterns_weight,
                    current_trends_weight,
                    scheduled_events_weight,
                    external_factors_weight,
                    predicted_at
                FROM predictive_alerts
                ORDER BY predicted_at DESC
            """)
            predictive_alerts = cur.fetchall()
            
            # Get notification preferences
            cur.execute("""
                SELECT 
                    operational_alerts_delivery,
                    relevance_filtering_enabled,
                    frequency_limiting_enabled,
                    priority_escalation_enabled,
                    updated_at
                FROM operational_notification_preferences
                WHERE employee_tab_n = 'SYSTEM_ADMIN'
                ORDER BY updated_at DESC
                LIMIT 1
            """)
            notification_prefs = cur.fetchone()
            
            return {
                "threshold_alerts": [
                    {
                        "alert_type": alert['alert_type'],
                        "threshold": alert['threshold_value'],
                        "response_actions": alert['response_actions'],
                        "severity": alert['severity'],
                        "status": alert['alert_status']
                    }
                    for alert in threshold_alerts
                ],
                "predictive_alerts": [
                    {
                        "prediction_type": alert['prediction_type'],
                        "lead_time_minutes": alert['lead_time_minutes'],
                        "confidence_percentage": alert['confidence_percentage'],
                        "analysis_factors": {
                            "historical_patterns": alert['historical_patterns_weight'],
                            "current_trends": alert['current_trends_weight'],
                            "scheduled_events": alert['scheduled_events_weight'],
                            "external_factors": alert['external_factors_weight']
                        }
                    }
                    for alert in predictive_alerts
                ],
                "notification_settings": notification_prefs or {},
                "last_updated": datetime.now(),
                "bdd_scenario": "View Alert Configurations"
            }
            
    except psycopg2.Error as e:
        logging.error(f"Database error getting alert configurations: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logging.error(f"Unexpected error getting alert configurations: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()