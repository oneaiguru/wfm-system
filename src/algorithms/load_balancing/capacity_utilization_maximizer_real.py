#!/usr/bin/env python3
"""
Capacity Utilization Maximizer Real - Zero Mock Dependencies
Transformed from: subagents/agent-7/load_balancer.py (CapacityUtilizationMaximizer class)
Database: PostgreSQL Schema 001 + auto-created capacity optimization tables
Performance: <2s capacity optimization decisions, real utilization maximization
"""

import time
import logging
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Optimization libraries for capacity maximization
try:
    from scipy.optimize import minimize, differential_evolution
    from sklearn.preprocessing import StandardScaler
    from sklearn.linear_model import LinearRegression
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class OptimizationStrategy(Enum):
    """Capacity optimization strategies"""
    MAXIMUM_THROUGHPUT = "maximum_throughput"
    BALANCED_UTILIZATION = "balanced_utilization"
    COST_EFFICIENCY = "cost_efficiency"
    RESOURCE_SMOOTHING = "resource_smoothing"
    DEMAND_MATCHING = "demand_matching"

class CapacityResult(Enum):
    """Capacity optimization result status"""
    SUCCESS = "success"
    PARTIAL_SUCCESS = "partial_success"
    NO_IMPROVEMENT = "no_improvement"
    FAILED = "failed"

@dataclass
class RealCapacityOptimizationDecision:
    """Real capacity optimization decision from utilization analysis"""
    decision_id: str
    decision_timestamp: datetime
    resource_type: str
    resource_id: int
    optimization_action: str  # 'increase_capacity', 'redistribute_load', 'optimize_schedule'
    current_utilization: float
    target_utilization: float
    utilization_improvement: float
    capacity_change_required: float
    throughput_improvement: float
    cost_impact: float
    implementation_priority: int
    implementation_effort: str  # 'low', 'medium', 'high'
    confidence_score: float
    roi_estimate: float
    supporting_metrics: Dict[str, float]
    data_source: str = "REAL_DATABASE"

@dataclass
class RealResourceCapacityState:
    """Real resource capacity state from utilization analysis"""
    resource_id: int
    resource_type: str
    resource_name: str
    current_utilization: float
    optimal_utilization: float
    utilization_gap: float
    max_capacity: float
    current_throughput: float
    potential_throughput: float
    efficiency_score: float
    bottleneck_risk: float
    optimization_potential: float
    peak_utilization: float
    off_peak_utilization: float
    utilization_variance: float
    data_source: str = "REAL_DATABASE"

@dataclass
class RealCapacityOptimizationResult:
    """Complete capacity optimization result"""
    optimization_id: str
    optimization_timestamp: datetime
    strategy_used: OptimizationStrategy
    resources_analyzed: int
    decisions_made: List[RealCapacityOptimizationDecision]
    overall_utilization_improvement: float
    throughput_improvement: float
    efficiency_improvement: float
    cost_savings_estimate: float
    resources_affected: int
    capacity_optimization_result: CapacityResult
    processing_time_ms: float
    utilization_before: Dict[int, float]
    utilization_after: Dict[int, float]
    data_quality_score: float
    data_source: str = "REAL_DATABASE"

class CapacityUtilizationMaximizerReal:
    """Real-time Capacity Utilization Maximizer using PostgreSQL Schema 001 + Resource Analytics"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 2.0  # 2 seconds for real-time optimization
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Optimization models
        self.scaler = StandardScaler()
        self.regression_model = LinearRegression()
        
        # Caching for performance
        self.resource_state_cache = {}  # resource_id -> capacity state
        self.optimization_history = []  # Historical optimization results
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_capacity_optimization_tables()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate Schema 001 tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) FROM information_schema.tables 
                    WHERE table_name IN ('agent_activity', 'contact_statistics', 'services')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_capacity_optimization_tables(self):
        """Create capacity optimization-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create resource_capacity_metrics table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS resource_capacity_metrics (
                    id SERIAL PRIMARY KEY,
                    resource_id INTEGER NOT NULL,
                    resource_type VARCHAR(50) NOT NULL, -- 'agent', 'queue', 'service_group'
                    measurement_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    current_utilization DECIMAL(5,2),
                    optimal_utilization DECIMAL(5,2) DEFAULT 85.0,
                    max_capacity DECIMAL(10,2),
                    current_throughput DECIMAL(10,2),
                    potential_throughput DECIMAL(10,2),
                    efficiency_score DECIMAL(3,2),
                    bottleneck_risk DECIMAL(3,2),
                    peak_utilization DECIMAL(5,2),
                    off_peak_utilization DECIMAL(5,2),
                    utilization_variance DECIMAL(8,4),
                    optimization_potential DECIMAL(3,2)
                )
            """))
            
            # Create capacity_optimization_decisions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS capacity_optimization_decisions (
                    id SERIAL PRIMARY KEY,
                    decision_id UUID NOT NULL DEFAULT gen_random_uuid(),
                    optimization_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    resource_type VARCHAR(50) NOT NULL,
                    resource_id INTEGER NOT NULL,
                    optimization_action VARCHAR(100) NOT NULL,
                    current_utilization DECIMAL(5,2),
                    target_utilization DECIMAL(5,2),
                    utilization_improvement DECIMAL(5,2),
                    capacity_change_required DECIMAL(5,2),
                    throughput_improvement DECIMAL(5,2),
                    cost_impact DECIMAL(10,2),
                    implementation_priority INTEGER DEFAULT 3,
                    implementation_effort VARCHAR(20),
                    confidence_score DECIMAL(3,2),
                    roi_estimate DECIMAL(5,2),
                    actual_improvement DECIMAL(5,2), -- measured later
                    supporting_metrics JSONB
                )
            """))
            
            # Create capacity_optimization_targets table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS capacity_optimization_targets (
                    id SERIAL PRIMARY KEY,
                    resource_type VARCHAR(50) NOT NULL,
                    target_utilization DECIMAL(5,2) DEFAULT 85.0,
                    min_utilization DECIMAL(5,2) DEFAULT 70.0,
                    max_utilization DECIMAL(5,2) DEFAULT 95.0,
                    efficiency_target DECIMAL(3,2) DEFAULT 0.9,
                    throughput_target_growth DECIMAL(5,2) DEFAULT 10.0,
                    optimization_interval_hours INTEGER DEFAULT 6,
                    max_capacity_increase DECIMAL(5,2) DEFAULT 20.0,
                    cost_per_capacity_unit DECIMAL(8,2) DEFAULT 100.0,
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create resource_performance_history table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS resource_performance_history (
                    id SERIAL PRIMARY KEY,
                    resource_id INTEGER NOT NULL,
                    resource_type VARCHAR(50) NOT NULL,
                    performance_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    utilization_rate DECIMAL(5,2),
                    throughput_rate DECIMAL(10,2),
                    efficiency_score DECIMAL(3,2),
                    queue_length INTEGER DEFAULT 0,
                    processing_time_avg DECIMAL(8,2),
                    error_rate DECIMAL(5,4) DEFAULT 0.0,
                    capacity_constraint_hit BOOLEAN DEFAULT false
                )
            """))
            
            session.commit()
            logger.info("✅ Capacity optimization tables created/validated")
    
    def maximize_capacity_utilization_real(self, 
                                         resource_ids: List[int],
                                         resource_type: str = "service",
                                         strategy: OptimizationStrategy = OptimizationStrategy.BALANCED_UTILIZATION,
                                         max_optimizations: int = 15) -> RealCapacityOptimizationResult:
        """Maximize capacity utilization using real resource utilization and performance data"""
        start_time = time.time()
        
        try:
            # Get current resource capacity state from real data
            resource_states = self._get_current_resource_capacity_states(resource_ids, resource_type)
            
            if not resource_states:
                raise ValueError(f"No resource capacity data found for {resource_type} resources: {resource_ids}")
            
            # Calculate utilization distribution before optimization
            utilization_before = {
                state.resource_id: state.current_utilization 
                for state in resource_states
            }
            
            # Generate capacity optimization decisions
            optimization_decisions = self._generate_capacity_optimization_decisions(
                resource_states, strategy, max_optimizations
            )
            
            # Simulate optimization effects
            utilization_after = self._simulate_capacity_optimization_effects(
                resource_states, optimization_decisions
            )
            
            # Calculate improvement metrics
            utilization_improvement = self._calculate_utilization_improvement(
                utilization_before, utilization_after
            )
            
            throughput_improvement = self._calculate_throughput_improvement(
                resource_states, optimization_decisions
            )
            
            efficiency_improvement = self._calculate_efficiency_improvement(
                resource_states, optimization_decisions
            )
            
            cost_savings = self._calculate_cost_savings(optimization_decisions)
            
            # Determine optimization result
            optimization_result = self._determine_capacity_result(
                utilization_improvement, throughput_improvement, len(optimization_decisions)
            )
            
            # Save decisions to database
            for decision in optimization_decisions:
                self._save_capacity_decision(decision)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            result = RealCapacityOptimizationResult(
                optimization_id=f"CUM_{int(time.time())}",
                optimization_timestamp=datetime.now(),
                strategy_used=strategy,
                resources_analyzed=len(resource_states),
                decisions_made=optimization_decisions,
                overall_utilization_improvement=utilization_improvement,
                throughput_improvement=throughput_improvement,
                efficiency_improvement=efficiency_improvement,
                cost_savings_estimate=cost_savings,
                resources_affected=len([d for d in optimization_decisions if d.utilization_improvement > 5]),
                capacity_optimization_result=optimization_result,
                processing_time_ms=processing_time * 1000,
                utilization_before=utilization_before,
                utilization_after=utilization_after,
                data_quality_score=self._calculate_data_quality_score(resource_states)
            )
            
            # Store in history
            self.optimization_history.append(result)
            
            logger.info(f"✅ Capacity optimization completed: {len(optimization_decisions)} decisions, {utilization_improvement:.1f}% utilization improvement")
            return result
            
        except Exception as e:
            logger.error(f"❌ Real capacity utilization optimization failed: {e}")
            raise ValueError(f"Capacity utilization optimization failed: {e}")
    
    def _get_current_resource_capacity_states(self, resource_ids: List[int], 
                                            resource_type: str) -> List[RealResourceCapacityState]:
        """Get current resource capacity states from real data"""
        with self.SessionLocal() as session:
            # Get resource utilization and capacity data based on type
            if resource_type == "service":
                resource_data = session.execute(text("""
                    SELECT 
                        cs.service_id as resource_id,
                        s.name as resource_name,
                        AVG(CASE 
                            WHEN cs.received_calls > 0 THEN 
                                (cs.treated_calls::float / cs.received_calls) * 100
                            ELSE 0 
                        END) as current_utilization,
                        SUM(cs.received_calls) as total_demand,
                        SUM(cs.treated_calls) as current_throughput,
                        AVG(cs.service_level) as efficiency_score,
                        MAX(cs.received_calls) as peak_demand,
                        MIN(cs.received_calls) as off_peak_demand,
                        STDDEV(cs.received_calls) as demand_variance,
                        COUNT(DISTINCT cs.interval_start_time) as measurement_periods
                    FROM contact_statistics cs
                    JOIN services s ON s.id = cs.service_id
                    WHERE cs.service_id = ANY(:resource_ids)
                    AND cs.interval_start_time >= NOW() - INTERVAL '24 hours'
                    GROUP BY cs.service_id, s.name
                    HAVING COUNT(DISTINCT cs.interval_start_time) >= 8
                    ORDER BY cs.service_id
                """), {'resource_ids': resource_ids}).fetchall()
            else:  # agent type
                resource_data = session.execute(text("""
                    SELECT 
                        aa.agent_id as resource_id,
                        a.name as resource_name,
                        AVG(CASE 
                            WHEN aa.login_time > 0 THEN 
                                ((aa.login_time - COALESCE(aa.ready_time, 0)) / aa.login_time) * 100
                            ELSE 0 
                        END) as current_utilization,
                        SUM(aa.login_time) as total_capacity,
                        SUM(aa.login_time - COALESCE(aa.ready_time, 0)) as current_throughput,
                        AVG(CASE 
                            WHEN aa.login_time > 0 THEN 
                                (aa.login_time / (aa.login_time + COALESCE(aa.not_ready_time, 0)))
                            ELSE 0 
                        END) as efficiency_score,
                        MAX(aa.login_time - COALESCE(aa.ready_time, 0)) as peak_utilization,
                        MIN(aa.login_time - COALESCE(aa.ready_time, 0)) as off_peak_utilization,
                        STDDEV(aa.login_time) as utilization_variance,
                        COUNT(DISTINCT aa.interval_start_time) as measurement_periods
                    FROM agent_activity aa
                    JOIN agents a ON a.id = aa.agent_id
                    WHERE aa.agent_id = ANY(:resource_ids)
                    AND aa.interval_start_time >= NOW() - INTERVAL '24 hours'
                    AND aa.login_time > 0
                    GROUP BY aa.agent_id, a.name
                    HAVING COUNT(DISTINCT aa.interval_start_time) >= 8
                    ORDER BY aa.agent_id
                """), {'resource_ids': resource_ids}).fetchall()
            
            # Convert to capacity state objects
            resource_states = []
            
            for row in resource_data:
                current_util = float(row.current_utilization or 0)
                optimal_util = 85.0  # Default target
                
                # Calculate capacity metrics
                max_capacity = float(row.total_capacity or row.total_demand or 100)
                current_throughput = float(row.current_throughput or 0)
                
                # Calculate potential throughput based on optimal utilization
                potential_throughput = current_throughput * (optimal_util / max(current_util, 1))
                
                # Calculate utilization gap and optimization potential
                utilization_gap = optimal_util - current_util
                optimization_potential = min(abs(utilization_gap) / 100.0, 1.0)
                
                # Calculate bottleneck risk
                peak_util = float(row.peak_demand or row.peak_utilization or current_util)
                bottleneck_risk = min(peak_util / 100.0, 1.0)
                
                # Calculate variance for stability assessment
                utilization_variance = float(row.demand_variance or row.utilization_variance or 0)
                
                resource_states.append(RealResourceCapacityState(
                    resource_id=row.resource_id,
                    resource_type=resource_type,
                    resource_name=row.resource_name or f"{resource_type}_{row.resource_id}",
                    current_utilization=current_util,
                    optimal_utilization=optimal_util,
                    utilization_gap=utilization_gap,
                    max_capacity=max_capacity,
                    current_throughput=current_throughput,
                    potential_throughput=potential_throughput,
                    efficiency_score=float(row.efficiency_score or 0) / 100,
                    bottleneck_risk=bottleneck_risk,
                    optimization_potential=optimization_potential,
                    peak_utilization=peak_util,
                    off_peak_utilization=float(row.off_peak_demand or row.off_peak_utilization or current_util * 0.7),
                    utilization_variance=utilization_variance
                ))
            
            return resource_states
    
    def _generate_capacity_optimization_decisions(self, 
                                                resource_states: List[RealResourceCapacityState],
                                                strategy: OptimizationStrategy,
                                                max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Generate capacity optimization decisions based on strategy"""
        decisions = []
        
        if strategy == OptimizationStrategy.MAXIMUM_THROUGHPUT:
            decisions = self._optimize_for_maximum_throughput(resource_states, max_decisions)
        elif strategy == OptimizationStrategy.COST_EFFICIENCY:
            decisions = self._optimize_for_cost_efficiency(resource_states, max_decisions)
        elif strategy == OptimizationStrategy.RESOURCE_SMOOTHING:
            decisions = self._optimize_for_resource_smoothing(resource_states, max_decisions)
        elif strategy == OptimizationStrategy.DEMAND_MATCHING:
            decisions = self._optimize_for_demand_matching(resource_states, max_decisions)
        else:  # BALANCED_UTILIZATION
            decisions = self._optimize_for_balanced_utilization(resource_states, max_decisions)
        
        return decisions
    
    def _optimize_for_balanced_utilization(self, resource_states: List[RealResourceCapacityState], 
                                         max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Optimize for balanced utilization across resources"""
        decisions = []
        
        # Calculate target utilization (mean of optimal targets)
        target_utilization = np.mean([state.optimal_utilization for state in resource_states])
        
        # Find resources with significant utilization gaps
        for state in resource_states:
            if len(decisions) >= max_decisions:
                break
            
            utilization_gap = abs(state.current_utilization - target_utilization)
            
            if utilization_gap > 10.0:  # Significant gap threshold
                if state.current_utilization < target_utilization:
                    # Under-utilized - increase load or reduce capacity
                    optimization_action = "redistribute_load"
                    capacity_change = 0  # No capacity change, redistribute load
                    utilization_improvement = min(utilization_gap * 0.7, 20.0)
                else:
                    # Over-utilized - increase capacity or redistribute load
                    optimization_action = "increase_capacity" if state.optimization_potential > 0.3 else "redistribute_load"
                    capacity_change = utilization_gap * 0.5 if optimization_action == "increase_capacity" else 0
                    utilization_improvement = min(utilization_gap * 0.6, 25.0)
                
                # Calculate throughput improvement
                throughput_improvement = utilization_improvement * state.current_throughput / 100
                
                # Calculate cost impact
                cost_impact = capacity_change * 100  # $100 per unit capacity change
                
                # Calculate ROI
                roi_estimate = (throughput_improvement * 10) / max(cost_impact, 1)  # $10 value per throughput unit
                
                decision = RealCapacityOptimizationDecision(
                    decision_id=f"BAL_{state.resource_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    resource_type=state.resource_type,
                    resource_id=state.resource_id,
                    optimization_action=optimization_action,
                    current_utilization=state.current_utilization,
                    target_utilization=target_utilization,
                    utilization_improvement=utilization_improvement,
                    capacity_change_required=capacity_change,
                    throughput_improvement=throughput_improvement,
                    cost_impact=cost_impact,
                    implementation_priority=self._calculate_implementation_priority(state, utilization_gap),
                    implementation_effort=self._determine_implementation_effort(optimization_action, capacity_change),
                    confidence_score=min(0.9, state.optimization_potential + 0.5),
                    roi_estimate=roi_estimate,
                    supporting_metrics={
                        'utilization_gap': utilization_gap,
                        'optimization_potential': state.optimization_potential,
                        'efficiency_score': state.efficiency_score,
                        'bottleneck_risk': state.bottleneck_risk
                    }
                )
                
                decisions.append(decision)
        
        return decisions
    
    def _optimize_for_maximum_throughput(self, resource_states: List[RealResourceCapacityState], 
                                       max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Optimize for maximum throughput"""
        decisions = []
        
        # Sort by throughput potential (highest first)
        sorted_states = sorted(resource_states, 
                             key=lambda x: x.potential_throughput - x.current_throughput, 
                             reverse=True)
        
        for state in sorted_states:
            if len(decisions) >= max_decisions:
                break
            
            throughput_gap = state.potential_throughput - state.current_throughput
            
            if throughput_gap > state.current_throughput * 0.1:  # 10% improvement threshold
                optimization_action = "increase_capacity"
                capacity_increase = min(throughput_gap / state.current_throughput * 100, 30.0)
                utilization_improvement = min(capacity_increase * 0.8, 25.0)
                
                cost_impact = capacity_increase * 150  # Higher cost for capacity increase
                roi_estimate = (throughput_gap * 15) / max(cost_impact, 1)
                
                decision = RealCapacityOptimizationDecision(
                    decision_id=f"THR_{state.resource_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    resource_type=state.resource_type,
                    resource_id=state.resource_id,
                    optimization_action=optimization_action,
                    current_utilization=state.current_utilization,
                    target_utilization=min(state.current_utilization + utilization_improvement, 95.0),
                    utilization_improvement=utilization_improvement,
                    capacity_change_required=capacity_increase,
                    throughput_improvement=throughput_gap,
                    cost_impact=cost_impact,
                    implementation_priority=4,  # High priority for throughput
                    implementation_effort="high",
                    confidence_score=min(0.8, state.optimization_potential + 0.3),
                    roi_estimate=roi_estimate,
                    supporting_metrics={
                        'throughput_gap': throughput_gap,
                        'potential_throughput': state.potential_throughput,
                        'current_throughput': state.current_throughput
                    }
                )
                
                decisions.append(decision)
        
        return decisions
    
    def _optimize_for_cost_efficiency(self, resource_states: List[RealResourceCapacityState], 
                                    max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Optimize for cost efficiency"""
        decisions = []
        
        # Focus on high-utilization resources that can be optimized without additional cost
        for state in resource_states:
            if len(decisions) >= max_decisions:
                break
            
            # Look for efficiency improvements without capacity increases
            if state.efficiency_score < 0.8 and state.current_utilization > 70:
                optimization_action = "optimize_schedule"
                utilization_improvement = (0.8 - state.efficiency_score) * 100
                throughput_improvement = utilization_improvement * state.current_throughput / 100
                
                cost_impact = 50  # Low cost for process optimization
                roi_estimate = (throughput_improvement * 12) / max(cost_impact, 1)
                
                decision = RealCapacityOptimizationDecision(
                    decision_id=f"COST_{state.resource_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    resource_type=state.resource_type,
                    resource_id=state.resource_id,
                    optimization_action=optimization_action,
                    current_utilization=state.current_utilization,
                    target_utilization=state.current_utilization + utilization_improvement,
                    utilization_improvement=utilization_improvement,
                    capacity_change_required=0,  # No capacity change
                    throughput_improvement=throughput_improvement,
                    cost_impact=cost_impact,
                    implementation_priority=3,
                    implementation_effort="medium",
                    confidence_score=0.75,
                    roi_estimate=roi_estimate,
                    supporting_metrics={
                        'efficiency_gap': 0.8 - state.efficiency_score,
                        'current_efficiency': state.efficiency_score
                    }
                )
                
                decisions.append(decision)
        
        return decisions
    
    def _optimize_for_resource_smoothing(self, resource_states: List[RealResourceCapacityState], 
                                       max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Optimize for resource smoothing (reduce variance)"""
        decisions = []
        
        # Find resources with high variance
        high_variance_resources = [s for s in resource_states if s.utilization_variance > 50]
        
        for state in high_variance_resources:
            if len(decisions) >= max_decisions:
                break
            
            # Smoothing through better scheduling
            optimization_action = "optimize_schedule"
            variance_reduction = min(state.utilization_variance * 0.4, 30.0)
            utilization_improvement = variance_reduction * 0.3
            
            decision = RealCapacityOptimizationDecision(
                decision_id=f"SMOOTH_{state.resource_id}_{int(time.time())}",
                decision_timestamp=datetime.now(),
                resource_type=state.resource_type,
                resource_id=state.resource_id,
                optimization_action=optimization_action,
                current_utilization=state.current_utilization,
                target_utilization=state.current_utilization + utilization_improvement,
                utilization_improvement=utilization_improvement,
                capacity_change_required=0,
                throughput_improvement=utilization_improvement * state.current_throughput / 100,
                cost_impact=75,  # Medium cost for scheduling optimization
                implementation_priority=2,
                implementation_effort="medium",
                confidence_score=0.7,
                roi_estimate=5.0,  # Moderate ROI for smoothing
                supporting_metrics={
                    'utilization_variance': state.utilization_variance,
                    'peak_utilization': state.peak_utilization,
                    'off_peak_utilization': state.off_peak_utilization
                }
            )
            
            decisions.append(decision)
        
        return decisions
    
    def _optimize_for_demand_matching(self, resource_states: List[RealResourceCapacityState], 
                                    max_decisions: int) -> List[RealCapacityOptimizationDecision]:
        """Optimize to better match demand patterns"""
        # For now, use balanced utilization with demand-focused metrics
        return self._optimize_for_balanced_utilization(resource_states, max_decisions)
    
    def _calculate_implementation_priority(self, state: RealResourceCapacityState, impact: float) -> int:
        """Calculate implementation priority (1-5)"""
        priority = 3  # Default medium priority
        
        # Increase priority for high impact
        if impact > 20:
            priority = 5
        elif impact > 15:
            priority = 4
        elif impact < 5:
            priority = 1
        
        # Adjust for bottleneck risk
        if state.bottleneck_risk > 0.8:
            priority = min(5, priority + 1)
        
        return priority
    
    def _determine_implementation_effort(self, action: str, capacity_change: float) -> str:
        """Determine implementation effort level"""
        if action == "optimize_schedule":
            return "medium"
        elif action == "redistribute_load":
            return "low"
        elif action == "increase_capacity":
            return "high" if capacity_change > 20 else "medium"
        else:
            return "medium"
    
    def _simulate_capacity_optimization_effects(self, 
                                              resource_states: List[RealResourceCapacityState],
                                              decisions: List[RealCapacityOptimizationDecision]) -> Dict[int, float]:
        """Simulate the effects of capacity optimization decisions"""
        simulated_utilization = {state.resource_id: state.current_utilization for state in resource_states}
        
        for decision in decisions:
            resource_id = decision.resource_id
            if resource_id in simulated_utilization:
                # Apply utilization improvement
                current = simulated_utilization[resource_id]
                improved = min(95.0, current + decision.utilization_improvement * 0.8)  # 80% effectiveness
                simulated_utilization[resource_id] = improved
        
        return simulated_utilization
    
    def _calculate_utilization_improvement(self, before: Dict[int, float], after: Dict[int, float]) -> float:
        """Calculate overall utilization improvement"""
        if not before or not after:
            return 0.0
        
        before_avg = np.mean(list(before.values()))
        after_avg = np.mean(list(after.values()))
        
        if before_avg == 0:
            return 0.0
        
        improvement = (after_avg - before_avg) / before_avg * 100
        return max(0, improvement)
    
    def _calculate_throughput_improvement(self, 
                                        resource_states: List[RealResourceCapacityState],
                                        decisions: List[RealCapacityOptimizationDecision]) -> float:
        """Calculate overall throughput improvement"""
        total_improvement = sum(decision.throughput_improvement for decision in decisions)
        total_current_throughput = sum(state.current_throughput for state in resource_states)
        
        if total_current_throughput == 0:
            return 0.0
        
        return (total_improvement / total_current_throughput) * 100
    
    def _calculate_efficiency_improvement(self, 
                                        resource_states: List[RealResourceCapacityState],
                                        decisions: List[RealCapacityOptimizationDecision]) -> float:
        """Calculate overall efficiency improvement"""
        # Approximate efficiency improvement based on utilization and optimization actions
        efficiency_decisions = [d for d in decisions if d.optimization_action in ["optimize_schedule", "redistribute_load"]]
        
        if not efficiency_decisions:
            return 0.0
        
        total_efficiency_gain = sum(d.utilization_improvement * 0.5 for d in efficiency_decisions)
        return min(total_efficiency_gain, 25.0)  # Cap at 25%
    
    def _calculate_cost_savings(self, decisions: List[RealCapacityOptimizationDecision]) -> float:
        """Calculate estimated cost savings from optimization"""
        # Cost savings from efficiency improvements minus implementation costs
        efficiency_savings = sum(d.throughput_improvement * 8 for d in decisions)  # $8 per throughput unit
        implementation_costs = sum(d.cost_impact for d in decisions)
        
        return max(0, efficiency_savings - implementation_costs)
    
    def _determine_capacity_result(self, utilization_improvement: float, 
                                 throughput_improvement: float, num_decisions: int) -> CapacityResult:
        """Determine the capacity optimization result status"""
        if (utilization_improvement > 10 or throughput_improvement > 15) and num_decisions > 0:
            return CapacityResult.SUCCESS
        elif (utilization_improvement > 5 or throughput_improvement > 8) or num_decisions > 0:
            return CapacityResult.PARTIAL_SUCCESS
        elif utilization_improvement > 0 or throughput_improvement > 0:
            return CapacityResult.NO_IMPROVEMENT
        else:
            return CapacityResult.FAILED
    
    def _calculate_data_quality_score(self, resource_states: List[RealResourceCapacityState]) -> float:
        """Calculate data quality score based on available capacity data"""
        if not resource_states:
            return 0.0
        
        total_score = 0
        for state in resource_states:
            score = 0
            # Check data completeness
            if state.current_utilization > 0:
                score += 0.3
            if state.current_throughput > 0:
                score += 0.3
            if state.efficiency_score > 0:
                score += 0.2
            if state.utilization_variance >= 0:
                score += 0.2
            total_score += score
        
        return total_score / len(resource_states)
    
    def _save_capacity_decision(self, decision: RealCapacityOptimizationDecision):
        """Save capacity optimization decision to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO capacity_optimization_decisions (
                    resource_type, resource_id, optimization_action, current_utilization,
                    target_utilization, utilization_improvement, capacity_change_required,
                    throughput_improvement, cost_impact, implementation_priority,
                    implementation_effort, confidence_score, roi_estimate, supporting_metrics
                ) VALUES (
                    :resource_type, :resource_id, :action, :current_util,
                    :target_util, :util_improvement, :capacity_change,
                    :throughput_improvement, :cost_impact, :priority,
                    :effort, :confidence, :roi, :metrics
                )
            """), {
                'resource_type': decision.resource_type,
                'resource_id': decision.resource_id,
                'action': decision.optimization_action,
                'current_util': decision.current_utilization,
                'target_util': decision.target_utilization,
                'util_improvement': decision.utilization_improvement,
                'capacity_change': decision.capacity_change_required,
                'throughput_improvement': decision.throughput_improvement,
                'cost_impact': decision.cost_impact,
                'priority': decision.implementation_priority,
                'effort': decision.implementation_effort,
                'confidence': decision.confidence_score,
                'roi': decision.roi_estimate,
                'metrics': decision.supporting_metrics
            })
            
            session.commit()

if __name__ == "__main__":
    # Test the real capacity utilization maximizer
    maximizer = CapacityUtilizationMaximizerReal()
    
    # Test capacity optimization
    resource_ids = [1, 2, 3]
    try:
        result = maximizer.maximize_capacity_utilization_real(
            resource_ids=resource_ids,
            resource_type="service",
            strategy=OptimizationStrategy.BALANCED_UTILIZATION,
            max_optimizations=8
        )
        
        print(f"Capacity optimization for {result.strategy_used.value} strategy:")
        print(f"  Resources analyzed: {result.resources_analyzed}")
        print(f"  Decisions made: {len(result.decisions_made)}")
        print(f"  Utilization improvement: {result.overall_utilization_improvement:.1f}%")
        print(f"  Throughput improvement: {result.throughput_improvement:.1f}%")
        print(f"  Efficiency improvement: {result.efficiency_improvement:.1f}%")
        print(f"  Cost savings estimate: ${result.cost_savings_estimate:.0f}")
        print(f"  Resources affected: {result.resources_affected}")
        print(f"  Optimization result: {result.capacity_optimization_result.value}")
        print(f"  Processing time: {result.processing_time_ms:.0f}ms")
        print(f"  Data quality: {result.data_quality_score:.2f}")
        
        for i, decision in enumerate(result.decisions_made[:3]):  # Show first 3 decisions
            print(f"  Decision {i+1}: {decision.optimization_action} for {decision.resource_type} {decision.resource_id}")
            print(f"    Utilization: {decision.current_utilization:.1f}% → {decision.target_utilization:.1f}%")
            print(f"    Improvement: {decision.utilization_improvement:.1f}%, ROI: {decision.roi_estimate:.1f}")
            print(f"    Priority: {decision.implementation_priority}/5, Effort: {decision.implementation_effort}")
        
    except Exception as e:
        print(f"Capacity optimization failed: {e}")