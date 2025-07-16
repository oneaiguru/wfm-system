"""
Real-time Alert System - PostgreSQL Schema 001 Integration
Converted from mock algorithms to real database integration

Algorithms:
1. ThresholdBreachAlerterReal - SLA violation detection (<200ms)
2. AnomalyDetectionEngineReal - Statistical pattern analysis (<200ms)
3. EscalationManagerReal - Priority routing & escalation (<200ms)
4. NotificationDispatcherReal - Multi-channel delivery (<200ms)

All algorithms:
- Zero mock dependencies
- Real PostgreSQL queries only
- Fail gracefully without database
- Meet BDD performance requirements
"""

from .threshold_breach_alerter_real import ThresholdBreachAlerterReal, RealAlert, AlertSeverity, AlertType
from .anomaly_detection_engine_real import AnomalyDetectionEngineReal, RealAnomalyPattern, AnomalyType, AnomalySeverity
from .escalation_manager_real import EscalationManagerReal, RealEscalationEvent, EscalationLevel, NotificationChannel
from .notification_dispatcher_real import NotificationDispatcherReal, RealNotificationEvent, DeliveryStatus, ChannelType

__all__ = [
    'ThresholdBreachAlerterReal',
    'RealAlert',
    'AlertSeverity',
    'AlertType',
    'AnomalyDetectionEngineReal',
    'RealAnomalyPattern',
    'AnomalyType',
    'AnomalySeverity',
    'EscalationManagerReal',
    'RealEscalationEvent',
    'EscalationLevel',
    'NotificationChannel',
    'NotificationDispatcherReal',
    'RealNotificationEvent',
    'DeliveryStatus',
    'ChannelType'
]