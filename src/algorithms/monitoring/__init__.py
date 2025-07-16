"""
Real-time Monitoring Suite - PostgreSQL Schema 001 Integration
Converted from mock algorithms to real database integration

Algorithms:
1. ServiceLevelMonitorReal - Real-time SL tracking (<500ms)
2. QueueStatusTrackerReal - Live queue monitoring (<500ms)  
3. AgentAvailabilityMonitorReal - Agent status tracking (<500ms)
4. PerformanceThresholdDetectorReal - SLA breach detection (<500ms)

All algorithms:
- Zero mock dependencies
- Real PostgreSQL queries only
- Fail gracefully without database
- Meet BDD performance requirements
"""

from .service_level_monitor_real import ServiceLevelMonitorReal, RealServiceLevelMetrics
from .queue_status_tracker_real import QueueStatusTrackerReal, RealQueueStatus
from .agent_availability_monitor_real import AgentAvailabilityMonitorReal, RealAgentAvailability, RealAgentSummary
from .performance_threshold_detector_real import PerformanceThresholdDetectorReal, RealPerformanceThreshold

__all__ = [
    'ServiceLevelMonitorReal',
    'RealServiceLevelMetrics',
    'QueueStatusTrackerReal', 
    'RealQueueStatus',
    'AgentAvailabilityMonitorReal',
    'RealAgentAvailability',
    'RealAgentSummary',
    'PerformanceThresholdDetectorReal',
    'RealPerformanceThreshold'
]