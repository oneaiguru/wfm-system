#!/usr/bin/env python3
"""
Real-Time Erlang C Optimizer - Week 1 Phase 3 Priority
Dynamic staffing optimization that Argus literally cannot do
"""

import asyncio
import time
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import json
from dataclasses import dataclass
from enum import Enum

from .erlang_c_enhanced import ErlangCEnhanced
from ..optimization.erlang_c_cache import ErlangCCache

class AlertLevel(Enum):
    """Alert severity levels"""
    NORMAL = "normal"
    WARNING = "warning"
    CRITICAL = "critical"
    EMERGENCY = "emergency"

@dataclass
class QueueState:
    """Real-time queue state"""
    queue_id: str
    timestamp: datetime
    calls_waiting: int
    agents_available: int
    agents_total: int
    avg_wait_time: float
    service_level: float
    call_volume_last_hour: int
    aht_seconds: int
    
@dataclass
class StaffingRecommendation:
    """AI-generated staffing recommendation"""
    queue_id: str
    current_agents: int
    required_agents: int
    agent_deficit: int
    predicted_sl: float
    urgency: AlertLevel
    actions: List[str]
    response_time_seconds: int
    confidence: float

class RealTimeErlangOptimizer:
    """
    Real-time Erlang C optimization engine
    Capabilities Argus cannot match:
    - Sub-second response times
    - Predictive SL breach detection
    - Automatic reallocation suggestions
    - WebSocket-ready streaming
    """
    
    def __init__(self):
        self.erlang_c = ErlangCEnhanced()
        self.cache = ErlangCCache()
        self.queue_states: Dict[str, QueueState] = {}
        self.thresholds = {
            'sl_warning': 0.75,      # 75% SL warning
            'sl_critical': 0.65,     # 65% SL critical
            'sl_emergency': 0.50,    # 50% SL emergency
            'wait_time_max': 45,     # 45 seconds max wait
            'forecast_deviation': 0.20  # 20% forecast deviation
        }
        
    def calculate_real_time_requirements(self, queue_state: QueueState) -> StaffingRecommendation:
        """
        Calculate staffing requirements in real-time
        Target: <50ms response time (vs Argus's inability to do this)
        """
        start_time = time.time()
        
        # Extract parameters
        arrival_rate = queue_state.call_volume_last_hour / 3600  # calls per second
        service_rate = 1 / queue_state.aht_seconds  # calls per second per agent
        target_sl = 0.80  # 80% service level target
        target_time = 20  # 20 seconds
        
        # Calculate required agents using enhanced Erlang C
        required_agents = self.erlang_c.calculate_agents(
            arrival_rate * 3600,  # calls per hour
            queue_state.aht_seconds,
            target_sl,
            target_time
        )
        
        # Calculate predicted service level with current staffing
        predicted_sl = self.erlang_c.calculate_service_level(
            arrival_rate * 3600,
            queue_state.aht_seconds,
            queue_state.agents_available,
            target_time
        )
        
        # Determine urgency level
        urgency = self._assess_urgency(queue_state, predicted_sl)
        
        # Generate action recommendations
        actions = self._generate_actions(queue_state, required_agents, urgency)
        
        # Calculate response time
        response_time = int((time.time() - start_time) * 1000)  # milliseconds
        
        # Calculate confidence based on data quality
        confidence = self._calculate_confidence(queue_state)
        
        return StaffingRecommendation(
            queue_id=queue_state.queue_id,
            current_agents=queue_state.agents_available,
            required_agents=required_agents,
            agent_deficit=max(0, required_agents - queue_state.agents_available),
            predicted_sl=predicted_sl,
            urgency=urgency,
            actions=actions,
            response_time_seconds=response_time,
            confidence=confidence
        )
    
    def _assess_urgency(self, queue_state: QueueState, predicted_sl: float) -> AlertLevel:
        """Assess urgency level based on multiple factors"""
        
        # Service level based urgency
        if predicted_sl < self.thresholds['sl_emergency']:
            return AlertLevel.EMERGENCY
        elif predicted_sl < self.thresholds['sl_critical']:
            return AlertLevel.CRITICAL
        elif predicted_sl < self.thresholds['sl_warning']:
            return AlertLevel.WARNING
        
        # Wait time based urgency
        if queue_state.avg_wait_time > self.thresholds['wait_time_max']:
            return AlertLevel.CRITICAL
        
        # Queue length based urgency
        if queue_state.calls_waiting > queue_state.agents_available * 3:
            return AlertLevel.WARNING
        
        return AlertLevel.NORMAL
    
    def _generate_actions(self, queue_state: QueueState, required_agents: int, urgency: AlertLevel) -> List[str]:
        """Generate specific action recommendations"""
        actions = []
        deficit = required_agents - queue_state.agents_available
        
        if deficit <= 0:
            actions.append("✓ Staffing adequate - monitor trending")
            return actions
        
        # Immediate actions based on urgency
        if urgency == AlertLevel.EMERGENCY:
            actions.append(f"🚨 EMERGENCY: Need {deficit} agents immediately")
            actions.append("📞 Call all available agents to workplace")
            actions.append("⏰ Authorize emergency overtime")
            actions.append("🔄 Reassign agents from lower priority queues")
        
        elif urgency == AlertLevel.CRITICAL:
            actions.append(f"⚠️ CRITICAL: Need {deficit} agents within 15 minutes")
            actions.append("📋 Check agent availability in other skills")
            actions.append("💰 Offer overtime to current agents")
            actions.append("📱 Send notifications to on-call agents")
        
        elif urgency == AlertLevel.WARNING:
            actions.append(f"⚡ WARNING: Need {deficit} agents within 30 minutes")
            actions.append("🔍 Review upcoming break schedules")
            actions.append("📊 Monitor trend - may need reinforcement")
            actions.append("🎯 Consider skill-based reallocation")
        
        # Add predictive actions
        actions.append(f"📈 Predicted SL with current staff: {queue_state.service_level:.1%}")
        actions.append(f"🎯 Target SL with {required_agents} agents: 80%")
        
        return actions
    
    def _calculate_confidence(self, queue_state: QueueState) -> float:
        """Calculate confidence in the recommendation"""
        confidence_factors = []
        
        # Data recency (higher confidence for recent data)
        age_minutes = (datetime.now() - queue_state.timestamp).total_seconds() / 60
        recency_score = max(0, 1 - age_minutes / 60)  # Decreases over 1 hour
        confidence_factors.append(recency_score)
        
        # Data completeness
        completeness_score = 1.0 if all([
            queue_state.calls_waiting >= 0,
            queue_state.agents_available > 0,
            queue_state.aht_seconds > 0,
            queue_state.call_volume_last_hour > 0
        ]) else 0.5
        confidence_factors.append(completeness_score)
        
        # Statistical significance (more data = higher confidence)
        volume_score = min(1.0, queue_state.call_volume_last_hour / 50)  # Normalize to 50 calls/hour
        confidence_factors.append(volume_score)
        
        return np.mean(confidence_factors)
    
    async def monitor_queue_continuously(self, queue_id: str, callback_func=None):
        """
        Continuous monitoring with real-time updates
        Simulates WebSocket-style streaming that Argus cannot do
        """
        print(f"🎯 Starting real-time monitoring for queue {queue_id}")
        print("📡 Streaming optimization recommendations...")
        
        while True:
            try:
                # Simulate real-time data update
                queue_state = self._simulate_queue_state(queue_id)
                
                # Calculate recommendation
                recommendation = self.calculate_real_time_requirements(queue_state)
                
                # Display update
                self._display_real_time_update(queue_state, recommendation)
                
                # Call callback if provided (WebSocket emit)
                if callback_func:
                    await callback_func(queue_id, recommendation)
                
                # Wait for next update (15 seconds in production)
                await asyncio.sleep(2)  # 2 seconds for demo
                
            except KeyboardInterrupt:
                print("\n🛑 Monitoring stopped by user")
                break
            except Exception as e:
                print(f"❌ Error in monitoring: {e}")
                await asyncio.sleep(5)
    
    def _simulate_queue_state(self, queue_id: str) -> QueueState:
        """Simulate realistic queue state changes"""
        now = datetime.now()
        
        # Simulate varying conditions
        base_volume = 80 + np.random.normal(0, 20)  # Base 80 calls/hour ± 20
        
        # Add time-of-day variation
        hour = now.hour
        if 9 <= hour <= 11:  # Morning peak
            base_volume *= 1.3
        elif 14 <= hour <= 16:  # Afternoon peak
            base_volume *= 1.2
        elif hour >= 18 or hour <= 7:  # Night/early morning
            base_volume *= 0.6
        
        # Simulate service level deterioration under load
        agents_available = np.random.randint(8, 15)
        calls_waiting = max(0, int(np.random.normal(base_volume / 10, 3)))
        
        # Calculate realistic metrics
        if agents_available > 0:
            avg_wait_time = max(0, (calls_waiting / agents_available) * 25)
            service_level = max(0.3, 0.9 - (calls_waiting / agents_available) * 0.1)
        else:
            avg_wait_time = 300  # 5 minutes
            service_level = 0.0
        
        return QueueState(
            queue_id=queue_id,
            timestamp=now,
            calls_waiting=calls_waiting,
            agents_available=agents_available,
            agents_total=agents_available + np.random.randint(0, 3),
            avg_wait_time=avg_wait_time,
            service_level=service_level,
            call_volume_last_hour=int(base_volume),
            aht_seconds=np.random.randint(280, 320)  # 280-320 seconds AHT
        )
    
    def _display_real_time_update(self, queue_state: QueueState, recommendation: StaffingRecommendation):
        """Display real-time update in terminal"""
        
        # Clear screen and show header
        print("\n" + "="*80)
        print(f"🎯 REAL-TIME OPTIMIZATION - Queue {queue_state.queue_id}")
        print(f"⏰ {queue_state.timestamp.strftime('%H:%M:%S')} | Response: {recommendation.response_time_seconds}ms")
        print("="*80)
        
        # Current state
        print(f"📊 Current State:")
        print(f"   Calls waiting: {queue_state.calls_waiting}")
        print(f"   Agents available: {queue_state.agents_available}")
        print(f"   Avg wait time: {queue_state.avg_wait_time:.1f}s")
        print(f"   Service level: {queue_state.service_level:.1%}")
        print(f"   Call volume: {queue_state.call_volume_last_hour}/hour")
        
        # Recommendation
        urgency_colors = {
            AlertLevel.NORMAL: "✅",
            AlertLevel.WARNING: "⚠️",
            AlertLevel.CRITICAL: "🚨",
            AlertLevel.EMERGENCY: "🔥"
        }
        
        print(f"\n🤖 AI Recommendation:")
        print(f"   Status: {urgency_colors[recommendation.urgency]} {recommendation.urgency.value.upper()}")
        print(f"   Required agents: {recommendation.required_agents}")
        print(f"   Agent deficit: {recommendation.agent_deficit}")
        print(f"   Predicted SL: {recommendation.predicted_sl:.1%}")
        print(f"   Confidence: {recommendation.confidence:.1%}")
        
        # Actions
        print(f"\n🎯 Recommended Actions:")
        for action in recommendation.actions:
            print(f"   {action}")
        
        # Argus comparison
        print(f"\n💀 Argus Status: 'No real-time updates available' (manual intervention required)")

async def demo_real_time_optimization():
    """Demonstrate real-time optimization capabilities"""
    print("🚀 Real-Time Erlang C Optimization Demo")
    print("Showing capabilities that Argus literally cannot match!")
    
    optimizer = RealTimeErlangOptimizer()
    
    # Run monitoring for queue
    await optimizer.monitor_queue_continuously("Q001")

if __name__ == "__main__":
    asyncio.run(demo_real_time_optimization())