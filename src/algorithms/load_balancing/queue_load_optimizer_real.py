#!/usr/bin/env python3
"""
Queue Load Optimizer Real - Zero Mock Dependencies
Transformed from: subagents/agent-7/load_balancer.py (QueueLoadOptimizer class)
Database: PostgreSQL Schema 001 + auto-created queue optimization tables
Performance: <2s queue load optimization decisions, real-time balancing
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

# Optimization libraries for real queue balancing
try:
    from scipy.optimize import minimize, linprog
    from sklearn.preprocessing import StandardScaler
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class OptimizationMethod(Enum):
    """Queue optimization methods"""
    ROUND_ROBIN = "round_robin"
    LOAD_BASED = "load_based"
    PRIORITY_WEIGHTED = "priority_weighted"
    SLA_OPTIMIZED = "sla_optimized"
    HYBRID_BALANCED = "hybrid_balanced"

class LoadBalanceResult(Enum):
    """Load balancing result status"""
    SUCCESS = "success"
    PARTIAL_SUCCESS = "partial_success"
    NO_IMPROVEMENT = "no_improvement"
    FAILED = "failed"

@dataclass
class RealQueueOptimizationDecision:
    """Real queue optimization decision from load analysis"""
    decision_id: str
    decision_timestamp: datetime
    from_queue_id: int
    to_queue_id: int
    agent_count_to_move: int
    load_improvement_expected: float
    sla_impact_score: float
    business_priority_factor: float
    urgency_level: int
    implementation_time_estimate: int  # minutes
    confidence_score: float
    supporting_metrics: Dict[str, float]
    data_source: str = "REAL_DATABASE"

@dataclass
class RealQueueLoadMetrics:
    """Real queue load optimization metrics"""
    queue_id: int
    queue_name: str
    current_load_percentage: float
    target_load_percentage: float
    load_imbalance: float
    agents_assigned: int
    optimal_agents: int
    calls_waiting: int
    average_wait_time: float
    service_level: float
    sla_target: float
    business_priority: int
    rebalance_urgency: float
    optimization_potential: float
    data_source: str = "REAL_DATABASE"

@dataclass
class RealQueueOptimizationResult:
    """Complete queue load optimization result"""
    optimization_id: str
    optimization_timestamp: datetime
    method_used: OptimizationMethod
    queues_analyzed: int
    decisions_made: List[RealQueueOptimizationDecision]
    overall_load_improvement: float
    sla_improvement_expected: float
    agents_affected: int
    optimization_result: LoadBalanceResult
    processing_time_ms: float
    load_distribution_before: Dict[int, float]
    load_distribution_after: Dict[int, float]
    data_quality_score: float
    data_source: str = "REAL_DATABASE"

class QueueLoadOptimizerReal:
    """Real-time Queue Load Optimizer using PostgreSQL Schema 001 + Queue Analytics"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 2.0  # 2 seconds for real-time optimization
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Optimization models
        self.scaler = StandardScaler()
        
        # Caching for performance
        self.queue_metrics_cache = {}  # queue_id -> metrics
        self.agent_allocation_cache = {}  # queue_id -> agent allocation
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_queue_optimization_tables()
    
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
                    WHERE table_name IN ('contact_statistics', 'agent_current_status', 'services')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_queue_optimization_tables(self):
        """Create queue optimization-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create queue_load_metrics table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS queue_load_metrics (
                    id SERIAL PRIMARY KEY,
                    queue_id INTEGER NOT NULL,
                    service_id INTEGER NOT NULL,
                    measurement_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    current_load_percentage DECIMAL(5,2),
                    target_load_percentage DECIMAL(5,2) DEFAULT 85.0,
                    agents_assigned INTEGER DEFAULT 0,
                    calls_waiting INTEGER DEFAULT 0,
                    average_wait_time DECIMAL(10,2),
                    service_level DECIMAL(5,2),
                    sla_breach_risk DECIMAL(3,2) DEFAULT 0.0,
                    business_priority INTEGER DEFAULT 3,
                    optimization_score DECIMAL(5,2),
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create queue_optimization_decisions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS queue_optimization_decisions (
                    id SERIAL PRIMARY KEY,
                    decision_id UUID NOT NULL DEFAULT gen_random_uuid(),
                    optimization_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    from_queue_id INTEGER NOT NULL,
                    to_queue_id INTEGER NOT NULL,
                    agent_count_moved INTEGER,
                    load_improvement_expected DECIMAL(5,2),
                    sla_impact_score DECIMAL(3,2),
                    business_priority_factor DECIMAL(3,2),
                    urgency_level INTEGER DEFAULT 3,
                    implementation_time_minutes INTEGER,
                    confidence_score DECIMAL(3,2),
                    actual_improvement DECIMAL(5,2), -- measured later
                    decision_effectiveness DECIMAL(3,2), -- calculated later
                    supporting_metrics JSONB
                )
            """))
            
            # Create queue_balance_targets table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS queue_balance_targets (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    queue_name VARCHAR(100) NOT NULL,
                    target_load_percentage DECIMAL(5,2) DEFAULT 85.0,
                    min_load_percentage DECIMAL(5,2) DEFAULT 60.0,
                    max_load_percentage DECIMAL(5,2) DEFAULT 95.0,
                    rebalance_threshold DECIMAL(5,2) DEFAULT 20.0,
                    sla_target_seconds INTEGER DEFAULT 300,
                    max_wait_time_seconds INTEGER DEFAULT 600,
                    business_priority INTEGER DEFAULT 3,
                    optimization_weight DECIMAL(3,2) DEFAULT 1.0,
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create agent_queue_assignments table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS agent_queue_assignments (
                    id SERIAL PRIMARY KEY,
                    agent_id INTEGER NOT NULL,
                    queue_id INTEGER NOT NULL,
                    service_id INTEGER NOT NULL,
                    assignment_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    assignment_type VARCHAR(20) DEFAULT 'primary', -- primary, secondary, overflow
                    skill_match_score DECIMAL(3,2) DEFAULT 1.0,
                    current_workload DECIMAL(5,2) DEFAULT 0.0,
                    max_workload DECIMAL(5,2) DEFAULT 100.0,
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            session.commit()
            logger.info("✅ Queue optimization tables created/validated")
    
    def optimize_queue_loads_real(self, 
                                service_ids: List[int],
                                optimization_method: OptimizationMethod = OptimizationMethod.HYBRID_BALANCED,
                                max_agent_moves: int = 10) -> RealQueueOptimizationResult:
        """Optimize queue loads using real queue metrics and agent allocation data"""
        start_time = time.time()
        
        try:
            # Get current queue load state from real data
            queue_metrics = self._get_current_queue_metrics(service_ids)
            
            if not queue_metrics:
                raise ValueError(f"No queue metrics found for services: {service_ids}")
            
            # Calculate load distribution before optimization
            load_distribution_before = {
                queue.queue_id: queue.current_load_percentage 
                for queue in queue_metrics
            }
            
            # Identify optimization opportunities
            optimization_decisions = self._generate_optimization_decisions(
                queue_metrics, optimization_method, max_agent_moves
            )
            
            # Calculate expected improvements
            load_distribution_after = self._simulate_optimization_effects(
                queue_metrics, optimization_decisions
            )
            
            # Calculate overall improvement metrics
            overall_improvement = self._calculate_overall_load_improvement(
                load_distribution_before, load_distribution_after
            )
            
            sla_improvement = self._calculate_sla_improvement(
                queue_metrics, optimization_decisions
            )
            
            # Determine optimization result
            optimization_result = self._determine_optimization_result(
                overall_improvement, len(optimization_decisions)
            )
            
            # Save decisions to database
            for decision in optimization_decisions:
                self._save_optimization_decision(decision)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            result = RealQueueOptimizationResult(
                optimization_id=f"QLO_{int(time.time())}",
                optimization_timestamp=datetime.now(),
                method_used=optimization_method,
                queues_analyzed=len(queue_metrics),
                decisions_made=optimization_decisions,
                overall_load_improvement=overall_improvement,
                sla_improvement_expected=sla_improvement,
                agents_affected=sum(d.agent_count_to_move for d in optimization_decisions),
                optimization_result=optimization_result,
                processing_time_ms=processing_time * 1000,
                load_distribution_before=load_distribution_before,
                load_distribution_after=load_distribution_after,
                data_quality_score=self._calculate_data_quality_score(queue_metrics)
            )
            
            logger.info(f"✅ Queue load optimization completed: {len(optimization_decisions)} decisions, {overall_improvement:.1f}% improvement")
            return result
            
        except Exception as e:
            logger.error(f"❌ Real queue load optimization failed: {e}")
            raise ValueError(f"Queue load optimization failed: {e}")
    
    def _get_current_queue_metrics(self, service_ids: List[int]) -> List[RealQueueLoadMetrics]:
        """Get current queue metrics from real data"""
        with self.SessionLocal() as session:
            # Get current queue status and load metrics
            queue_data = session.execute(text("""
                SELECT 
                    cs.service_id as queue_id,
                    s.name as queue_name,
                    cs.received_calls,
                    cs.treated_calls,
                    (cs.received_calls - cs.treated_calls) as calls_waiting,
                    cs.service_level,
                    cs.aht as average_handle_time,
                    s.target_service_level as sla_target,
                    qbt.target_load_percentage,
                    qbt.business_priority,
                    COUNT(DISTINCT aqa.agent_id) as agents_assigned
                FROM contact_statistics cs
                JOIN services s ON s.id = cs.service_id
                LEFT JOIN queue_balance_targets qbt ON qbt.service_id = cs.service_id
                LEFT JOIN agent_queue_assignments aqa ON aqa.service_id = cs.service_id 
                    AND aqa.is_active = true
                WHERE cs.service_id = ANY(:service_ids)
                AND cs.interval_start_time >= NOW() - INTERVAL '15 minutes'
                GROUP BY cs.service_id, s.name, cs.received_calls, cs.treated_calls, 
                         cs.service_level, cs.aht, s.target_service_level,
                         qbt.target_load_percentage, qbt.business_priority
                ORDER BY cs.service_id
            """), {'service_ids': service_ids}).fetchall()
            
            # Get agent utilization for load calculation
            agent_utilization = session.execute(text("""
                SELECT 
                    aqa.service_id as queue_id,
                    AVG(CASE 
                        WHEN aa.login_time > 0 THEN 
                            ((aa.login_time - COALESCE(aa.ready_time, 0)) / aa.login_time) * 100
                        ELSE 0 
                    END) as avg_utilization
                FROM agent_queue_assignments aqa
                JOIN agent_activity aa ON aa.agent_id = aqa.agent_id
                WHERE aqa.service_id = ANY(:service_ids)
                AND aqa.is_active = true
                AND aa.interval_start_time >= NOW() - INTERVAL '2 hours'
                GROUP BY aqa.service_id
            """), {'service_ids': service_ids}).fetchall()
            
            # Convert to metrics objects
            utilization_map = {row.queue_id: row.avg_utilization for row in agent_utilization}
            
            queue_metrics = []
            for row in queue_data:
                current_load = float(utilization_map.get(row.queue_id, 0) or 0)
                target_load = float(row.target_load_percentage or 85.0)
                
                # Calculate average wait time from queue depth and service rate
                calls_waiting = max(0, int(row.calls_waiting or 0))
                service_rate = max(1, int(row.treated_calls or 1))
                avg_wait_time = (calls_waiting / service_rate) * (row.average_handle_time or 300)
                
                # Calculate optimization potential
                load_imbalance = abs(current_load - target_load)
                optimization_potential = min(load_imbalance / 100.0, 1.0)
                
                queue_metrics.append(RealQueueLoadMetrics(
                    queue_id=row.queue_id,
                    queue_name=row.queue_name or f"Queue_{row.queue_id}",
                    current_load_percentage=current_load,
                    target_load_percentage=target_load,
                    load_imbalance=load_imbalance,
                    agents_assigned=int(row.agents_assigned or 0),
                    optimal_agents=self._calculate_optimal_agents(current_load, target_load, int(row.agents_assigned or 0)),
                    calls_waiting=calls_waiting,
                    average_wait_time=avg_wait_time,
                    service_level=float(row.service_level or 0),
                    sla_target=float(row.sla_target or 80.0),
                    business_priority=int(row.business_priority or 3),
                    rebalance_urgency=self._calculate_rebalance_urgency(
                        current_load, target_load, float(row.service_level or 0), float(row.sla_target or 80.0)
                    ),
                    optimization_potential=optimization_potential
                ))
            
            return queue_metrics
    
    def _calculate_optimal_agents(self, current_load: float, target_load: float, current_agents: int) -> int:
        """Calculate optimal number of agents based on load"""
        if current_load <= 0 or current_agents <= 0:
            return current_agents
        
        # Simple proportional calculation
        optimal_agents = int((current_load / target_load) * current_agents)
        return max(1, optimal_agents)
    
    def _calculate_rebalance_urgency(self, current_load: float, target_load: float, 
                                   service_level: float, sla_target: float) -> float:
        """Calculate urgency score for rebalancing"""
        load_urgency = abs(current_load - target_load) / 100.0
        sla_urgency = max(0, (sla_target - service_level) / 100.0)
        
        # Weight SLA urgency higher
        urgency = (load_urgency * 0.4) + (sla_urgency * 0.6)
        return min(urgency, 1.0)
    
    def _generate_optimization_decisions(self, 
                                       queue_metrics: List[RealQueueLoadMetrics],
                                       method: OptimizationMethod,
                                       max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Generate optimization decisions based on method"""
        decisions = []
        
        if method == OptimizationMethod.LOAD_BASED:
            decisions = self._optimize_by_load_balance(queue_metrics, max_moves)
        elif method == OptimizationMethod.PRIORITY_WEIGHTED:
            decisions = self._optimize_by_priority(queue_metrics, max_moves)
        elif method == OptimizationMethod.SLA_OPTIMIZED:
            decisions = self._optimize_by_sla(queue_metrics, max_moves)
        elif method == OptimizationMethod.HYBRID_BALANCED:
            decisions = self._optimize_hybrid(queue_metrics, max_moves)
        else:  # ROUND_ROBIN fallback
            decisions = self._optimize_round_robin(queue_metrics, max_moves)
        
        return decisions
    
    def _optimize_by_load_balance(self, queue_metrics: List[RealQueueLoadMetrics], 
                                max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Optimize based on load balancing"""
        decisions = []
        
        # Sort queues by load imbalance
        overloaded = [q for q in queue_metrics if q.current_load_percentage > q.target_load_percentage + 10]
        underloaded = [q for q in queue_metrics if q.current_load_percentage < q.target_load_percentage - 10]
        
        overloaded.sort(key=lambda x: x.load_imbalance, reverse=True)
        underloaded.sort(key=lambda x: x.load_imbalance, reverse=True)
        
        # Generate rebalancing moves
        for i, over_queue in enumerate(overloaded):
            if i >= len(underloaded) or len(decisions) >= max_moves:
                break
            
            under_queue = underloaded[i]
            
            # Calculate agent movement
            over_excess = over_queue.agents_assigned - over_queue.optimal_agents
            under_deficit = under_queue.optimal_agents - under_queue.agents_assigned
            
            agents_to_move = min(abs(over_excess), abs(under_deficit), 3)  # Max 3 agents per move
            
            if agents_to_move > 0:
                decision = RealQueueOptimizationDecision(
                    decision_id=f"LB_{over_queue.queue_id}_{under_queue.queue_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    from_queue_id=over_queue.queue_id,
                    to_queue_id=under_queue.queue_id,
                    agent_count_to_move=agents_to_move,
                    load_improvement_expected=(over_queue.load_imbalance + under_queue.load_imbalance) / 2,
                    sla_impact_score=0.7,  # Moderate SLA impact
                    business_priority_factor=(over_queue.business_priority + under_queue.business_priority) / 10.0,
                    urgency_level=int((over_queue.rebalance_urgency + under_queue.rebalance_urgency) * 5),
                    implementation_time_estimate=15,  # 15 minutes
                    confidence_score=0.8,
                    supporting_metrics={
                        'from_load': over_queue.current_load_percentage,
                        'to_load': under_queue.current_load_percentage,
                        'load_difference': abs(over_queue.current_load_percentage - under_queue.current_load_percentage)
                    }
                )
                decisions.append(decision)
        
        return decisions
    
    def _optimize_by_priority(self, queue_metrics: List[RealQueueLoadMetrics], 
                            max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Optimize based on business priority"""
        decisions = []
        
        # Sort by priority and urgency
        priority_queues = sorted(queue_metrics, 
                               key=lambda x: (x.business_priority, x.rebalance_urgency), 
                               reverse=True)
        
        high_priority = [q for q in priority_queues if q.business_priority >= 4]
        available_sources = [q for q in queue_metrics if q.current_load_percentage < q.target_load_percentage]
        
        for priority_queue in high_priority:
            if len(decisions) >= max_moves:
                break
            
            if priority_queue.current_load_percentage > priority_queue.target_load_percentage + 15:
                # Find best source queue for agents
                best_source = None
                for source in available_sources:
                    if source.queue_id != priority_queue.queue_id and source.agents_assigned > 1:
                        if not best_source or source.current_load_percentage < best_source.current_load_percentage:
                            best_source = source
                
                if best_source:
                    agents_to_move = min(2, best_source.agents_assigned - 1)
                    
                    decision = RealQueueOptimizationDecision(
                        decision_id=f"PR_{best_source.queue_id}_{priority_queue.queue_id}_{int(time.time())}",
                        decision_timestamp=datetime.now(),
                        from_queue_id=best_source.queue_id,
                        to_queue_id=priority_queue.queue_id,
                        agent_count_to_move=agents_to_move,
                        load_improvement_expected=priority_queue.load_imbalance * 0.3,
                        sla_impact_score=0.9,  # High SLA impact for priority
                        business_priority_factor=priority_queue.business_priority / 5.0,
                        urgency_level=5,  # High urgency
                        implementation_time_estimate=10,  # 10 minutes
                        confidence_score=0.9,
                        supporting_metrics={
                            'priority_queue_load': priority_queue.current_load_percentage,
                            'source_queue_load': best_source.current_load_percentage,
                            'business_priority': priority_queue.business_priority
                        }
                    )
                    decisions.append(decision)
        
        return decisions
    
    def _optimize_by_sla(self, queue_metrics: List[RealQueueLoadMetrics], 
                       max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Optimize based on SLA targets"""
        decisions = []
        
        # Find queues with SLA breaches or risks
        sla_risk_queues = [q for q in queue_metrics if q.service_level < q.sla_target * 0.9]
        sla_risk_queues.sort(key=lambda x: x.sla_target - x.service_level, reverse=True)
        
        donor_queues = [q for q in queue_metrics if q.service_level > q.sla_target * 1.1]
        
        for risk_queue in sla_risk_queues:
            if len(decisions) >= max_moves:
                break
            
            # Find best donor queue
            best_donor = None
            for donor in donor_queues:
                if donor.queue_id != risk_queue.queue_id and donor.agents_assigned > 1:
                    sla_buffer = donor.service_level - donor.sla_target
                    if not best_donor or sla_buffer > (best_donor.service_level - best_donor.sla_target):
                        best_donor = donor
            
            if best_donor:
                agents_to_move = min(2, best_donor.agents_assigned - 1)
                sla_improvement = (risk_queue.sla_target - risk_queue.service_level) * 0.5
                
                decision = RealQueueOptimizationDecision(
                    decision_id=f"SLA_{best_donor.queue_id}_{risk_queue.queue_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    from_queue_id=best_donor.queue_id,
                    to_queue_id=risk_queue.queue_id,
                    agent_count_to_move=agents_to_move,
                    load_improvement_expected=sla_improvement,
                    sla_impact_score=1.0,  # Maximum SLA impact
                    business_priority_factor=risk_queue.business_priority / 5.0,
                    urgency_level=5,  # High urgency for SLA
                    implementation_time_estimate=5,  # 5 minutes - urgent
                    confidence_score=0.85,
                    supporting_metrics={
                        'risk_queue_sla': risk_queue.service_level,
                        'risk_queue_target': risk_queue.sla_target,
                        'donor_queue_sla': best_donor.service_level,
                        'donor_queue_target': best_donor.sla_target,
                        'sla_gap': risk_queue.sla_target - risk_queue.service_level
                    }
                )
                decisions.append(decision)
        
        return decisions
    
    def _optimize_hybrid(self, queue_metrics: List[RealQueueLoadMetrics], 
                       max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Optimize using hybrid approach combining multiple factors"""
        # Combine load balancing, priority, and SLA optimization
        load_decisions = self._optimize_by_load_balance(queue_metrics, max_moves // 3)
        priority_decisions = self._optimize_by_priority(queue_metrics, max_moves // 3)
        sla_decisions = self._optimize_by_sla(queue_metrics, max_moves // 3)
        
        # Merge and prioritize decisions
        all_decisions = load_decisions + priority_decisions + sla_decisions
        
        # Remove duplicates and conflicts
        unique_decisions = self._resolve_decision_conflicts(all_decisions)
        
        # Sort by combined score
        for decision in unique_decisions:
            score = (decision.sla_impact_score * 0.4 + 
                    decision.business_priority_factor * 0.3 + 
                    decision.confidence_score * 0.3)
            decision.supporting_metrics['hybrid_score'] = score
        
        unique_decisions.sort(key=lambda x: x.supporting_metrics.get('hybrid_score', 0), reverse=True)
        
        return unique_decisions[:max_moves]
    
    def _optimize_round_robin(self, queue_metrics: List[RealQueueLoadMetrics], 
                            max_moves: int) -> List[RealQueueOptimizationDecision]:
        """Simple round-robin optimization as fallback"""
        decisions = []
        
        # Simple approach: move agents from highest to lowest load
        sorted_by_load = sorted(queue_metrics, key=lambda x: x.current_load_percentage, reverse=True)
        
        if len(sorted_by_load) >= 2:
            highest_load = sorted_by_load[0]
            lowest_load = sorted_by_load[-1]
            
            if highest_load.current_load_percentage > lowest_load.current_load_percentage + 20:
                agents_to_move = min(1, highest_load.agents_assigned - 1)
                
                if agents_to_move > 0:
                    decision = RealQueueOptimizationDecision(
                        decision_id=f"RR_{highest_load.queue_id}_{lowest_load.queue_id}_{int(time.time())}",
                        decision_timestamp=datetime.now(),
                        from_queue_id=highest_load.queue_id,
                        to_queue_id=lowest_load.queue_id,
                        agent_count_to_move=agents_to_move,
                        load_improvement_expected=abs(highest_load.current_load_percentage - lowest_load.current_load_percentage) * 0.2,
                        sla_impact_score=0.5,
                        business_priority_factor=0.5,
                        urgency_level=3,
                        implementation_time_estimate=20,
                        confidence_score=0.6,
                        supporting_metrics={
                            'method': 'round_robin',
                            'load_difference': highest_load.current_load_percentage - lowest_load.current_load_percentage
                        }
                    )
                    decisions.append(decision)
        
        return decisions
    
    def _resolve_decision_conflicts(self, decisions: List[RealQueueOptimizationDecision]) -> List[RealQueueOptimizationDecision]:
        """Resolve conflicts between optimization decisions"""
        # Track queue movements to avoid double-booking
        queue_movements = {}  # queue_id -> net agent change
        resolved_decisions = []
        
        # Sort by confidence and impact
        sorted_decisions = sorted(decisions, 
                                key=lambda x: x.confidence_score * x.sla_impact_score, 
                                reverse=True)
        
        for decision in sorted_decisions:
            from_queue = decision.from_queue_id
            to_queue = decision.to_queue_id
            move_count = decision.agent_count_to_move
            
            # Check if movement is feasible
            from_outbound = queue_movements.get(from_queue, 0)
            to_inbound = queue_movements.get(to_queue, 0)
            
            # Ensure we don't over-allocate agents from source queue
            if from_outbound + move_count <= 3:  # Max 3 agents outbound per queue
                # Update tracking
                queue_movements[from_queue] = from_outbound + move_count
                queue_movements[to_queue] = to_inbound - move_count
                resolved_decisions.append(decision)
        
        return resolved_decisions
    
    def _simulate_optimization_effects(self, 
                                     queue_metrics: List[RealQueueLoadMetrics],
                                     decisions: List[RealQueueOptimizationDecision]) -> Dict[int, float]:
        """Simulate the effects of optimization decisions"""
        simulated_loads = {q.queue_id: q.current_load_percentage for q in queue_metrics}
        
        for decision in decisions:
            from_queue = decision.from_queue_id
            to_queue = decision.to_queue_id
            move_count = decision.agent_count_to_move
            
            # Simple simulation: assume load redistributes proportionally
            from_queue_metric = next((q for q in queue_metrics if q.queue_id == from_queue), None)
            to_queue_metric = next((q for q in queue_metrics if q.queue_id == to_queue), None)
            
            if from_queue_metric and to_queue_metric:
                # Calculate load transfer
                if from_queue_metric.agents_assigned > 0:
                    load_per_agent = from_queue_metric.current_load_percentage / from_queue_metric.agents_assigned
                    load_transfer = load_per_agent * move_count
                    
                    simulated_loads[from_queue] = max(0, simulated_loads[from_queue] - load_transfer)
                    simulated_loads[to_queue] = min(100, simulated_loads[to_queue] + load_transfer * 0.8)  # 80% efficiency
        
        return simulated_loads
    
    def _calculate_overall_load_improvement(self, before: Dict[int, float], after: Dict[int, float]) -> float:
        """Calculate overall load balance improvement"""
        if not before or not after:
            return 0.0
        
        # Calculate variance before and after
        before_variance = np.var(list(before.values()))
        after_variance = np.var(list(after.values()))
        
        if before_variance == 0:
            return 0.0
        
        variance_improvement = (before_variance - after_variance) / before_variance * 100
        return max(0, variance_improvement)
    
    def _calculate_sla_improvement(self, 
                                 queue_metrics: List[RealQueueLoadMetrics],
                                 decisions: List[RealQueueOptimizationDecision]) -> float:
        """Calculate expected SLA improvement"""
        total_sla_impact = sum(d.sla_impact_score * d.load_improvement_expected for d in decisions)
        return min(total_sla_impact / 10.0, 100.0) if decisions else 0.0
    
    def _determine_optimization_result(self, improvement: float, num_decisions: int) -> LoadBalanceResult:
        """Determine the optimization result status"""
        if improvement > 15 and num_decisions > 0:
            return LoadBalanceResult.SUCCESS
        elif improvement > 5 or num_decisions > 0:
            return LoadBalanceResult.PARTIAL_SUCCESS
        elif improvement > 0:
            return LoadBalanceResult.NO_IMPROVEMENT
        else:
            return LoadBalanceResult.FAILED
    
    def _calculate_data_quality_score(self, queue_metrics: List[RealQueueLoadMetrics]) -> float:
        """Calculate data quality score based on available metrics"""
        total_score = 0
        for metric in queue_metrics:
            score = 0
            # Check data completeness
            if metric.current_load_percentage > 0:
                score += 0.3
            if metric.agents_assigned > 0:
                score += 0.3
            if metric.service_level > 0:
                score += 0.2
            if metric.calls_waiting >= 0:
                score += 0.2
            total_score += score
        
        return total_score / len(queue_metrics) if queue_metrics else 0.0
    
    def _save_optimization_decision(self, decision: RealQueueOptimizationDecision):
        """Save optimization decision to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO queue_optimization_decisions (
                    from_queue_id, to_queue_id, agent_count_moved,
                    load_improvement_expected, sla_impact_score, business_priority_factor,
                    urgency_level, implementation_time_minutes, confidence_score,
                    supporting_metrics
                ) VALUES (
                    :from_queue, :to_queue, :agent_count,
                    :load_improvement, :sla_impact, :priority_factor,
                    :urgency, :impl_time, :confidence, :metrics
                )
            """), {
                'from_queue': decision.from_queue_id,
                'to_queue': decision.to_queue_id,
                'agent_count': decision.agent_count_to_move,
                'load_improvement': decision.load_improvement_expected,
                'sla_impact': decision.sla_impact_score,
                'priority_factor': decision.business_priority_factor,
                'urgency': decision.urgency_level,
                'impl_time': decision.implementation_time_estimate,
                'confidence': decision.confidence_score,
                'metrics': decision.supporting_metrics
            })
            
            session.commit()

if __name__ == "__main__":
    # Test the real queue load optimizer
    optimizer = QueueLoadOptimizerReal()
    
    # Test queue optimization
    service_ids = [1, 2, 3]
    try:
        result = optimizer.optimize_queue_loads_real(
            service_ids=service_ids,
            optimization_method=OptimizationMethod.HYBRID_BALANCED,
            max_agent_moves=5
        )
        
        print(f"Queue load optimization for services {service_ids}:")
        print(f"  Method: {result.method_used.value}")
        print(f"  Queues analyzed: {result.queues_analyzed}")
        print(f"  Decisions made: {len(result.decisions_made)}")
        print(f"  Overall improvement: {result.overall_load_improvement:.1f}%")
        print(f"  SLA improvement: {result.sla_improvement_expected:.1f}%")
        print(f"  Agents affected: {result.agents_affected}")
        print(f"  Optimization result: {result.optimization_result.value}")
        print(f"  Processing time: {result.processing_time_ms:.0f}ms")
        print(f"  Data quality: {result.data_quality_score:.2f}")
        
        for i, decision in enumerate(result.decisions_made[:3]):  # Show first 3 decisions
            print(f"  Decision {i+1}: Queue {decision.from_queue_id} → Queue {decision.to_queue_id}")
            print(f"    Agents: {decision.agent_count_to_move}, Improvement: {decision.load_improvement_expected:.1f}%")
            print(f"    Urgency: {decision.urgency_level}/5, Confidence: {decision.confidence_score:.2f}")
        
    except Exception as e:
        print(f"Queue load optimization failed: {e}")