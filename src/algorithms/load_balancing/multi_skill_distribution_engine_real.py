#!/usr/bin/env python3
"""
Multi-Skill Distribution Engine Real - Zero Mock Dependencies
Transformed from: subagents/agent-7/load_balancer.py
Database: PostgreSQL Schema 001 + auto-created load balancing tables
Performance: <2s skill-based routing decisions, real agent capabilities
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

# Optimization libraries for real load balancing
try:
    from scipy.optimize import linear_sum_assignment, minimize
    from sklearn.preprocessing import StandardScaler
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class SkillProficiency(Enum):
    """Skill proficiency levels"""
    NOVICE = 1
    BASIC = 2
    INTERMEDIATE = 3
    ADVANCED = 4
    EXPERT = 5

class DistributionStrategy(Enum):
    """Distribution optimization strategies"""
    SKILL_MATCH_OPTIMAL = "skill_match_optimal"
    WORKLOAD_BALANCED = "workload_balanced"
    HYBRID_OPTIMIZED = "hybrid_optimized"
    PRIORITY_BASED = "priority_based"

class OptimizationResult(Enum):
    """Optimization result status"""
    SUCCESS = "success"
    PARTIAL_SUCCESS = "partial_success"
    NO_IMPROVEMENT = "no_improvement"
    FAILED = "failed"

@dataclass
class RealSkillDistributionDecision:
    """Real skill-based distribution decision from agent capability analysis"""
    decision_id: str
    decision_timestamp: datetime
    agent_id: int
    from_queue_id: Optional[int]
    to_queue_id: int
    skill_match_score: float
    workload_improvement: float
    utilization_before: float
    utilization_after: float
    expected_efficiency_gain: float
    implementation_priority: int
    decision_confidence: float
    supporting_skills: List[str]
    data_source: str = "REAL_DATABASE"

@dataclass
class RealSkillDistributionResult:
    """Complete skill distribution optimization result"""
    optimization_id: str
    optimization_timestamp: datetime
    strategy_used: DistributionStrategy
    total_agents_analyzed: int
    decisions_made: List[RealSkillDistributionDecision]
    overall_improvement: float
    skill_utilization_before: Dict[str, float]
    skill_utilization_after: Dict[str, float]
    optimization_result: OptimizationResult
    processing_time_ms: float
    data_quality_score: float
    data_source: str = "REAL_DATABASE"

class MultiSkillDistributionEngineReal:
    """Real-time Multi-Skill Distribution Engine using PostgreSQL Schema 001 + Agent Capabilities"""
    
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
        self.agent_skills_cache = {}  # agent_id -> skills
        self.skill_demands_cache = {}  # skill -> current demand
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_load_balancing_tables()
    
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
                    WHERE table_name IN ('agent_activity', 'contact_statistics', 'agent_current_status')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_load_balancing_tables(self):
        """Create load balancing-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create agent_skills table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS agent_skills (
                    id SERIAL PRIMARY KEY,
                    agent_id INTEGER NOT NULL,
                    skill_id INTEGER NOT NULL,
                    skill_name VARCHAR(100) NOT NULL,
                    proficiency_level INTEGER DEFAULT 1, -- 1-5 scale
                    certification_date DATE,
                    last_used_date DATE,
                    performance_rating DECIMAL(3,2) DEFAULT 3.0, -- 1.0-5.0 scale
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    UNIQUE(agent_id, skill_id)
                )
            """))
            
            # Create queue_priorities table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS queue_priorities (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    queue_name VARCHAR(100) NOT NULL,
                    business_priority INTEGER DEFAULT 3, -- 1-5 scale, 5=highest
                    sla_target_seconds INTEGER DEFAULT 300,
                    escalation_threshold_seconds INTEGER DEFAULT 600,
                    peak_hours_start TIME DEFAULT '09:00',
                    peak_hours_end TIME DEFAULT '17:00',
                    peak_priority_multiplier DECIMAL(3,2) DEFAULT 1.5,
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            # Create load_balancing_decisions table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS load_balancing_decisions (
                    id SERIAL PRIMARY KEY,
                    decision_id UUID NOT NULL DEFAULT gen_random_uuid(),
                    algorithm_type VARCHAR(50) NOT NULL,
                    decision_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    agent_id INTEGER NOT NULL,
                    from_queue_id INTEGER,
                    to_queue_id INTEGER,
                    workload_before JSONB,
                    workload_after JSONB,
                    expected_improvement DECIMAL(5,2),
                    actual_improvement DECIMAL(5,2), -- measured later
                    decision_reason TEXT,
                    implementation_time_ms INTEGER
                )
            """))
            
            # Create utilization_targets table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS utilization_targets (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    target_name VARCHAR(100) NOT NULL,
                    target_utilization_pct DECIMAL(5,2) DEFAULT 85.0,
                    min_utilization_pct DECIMAL(5,2) DEFAULT 70.0,
                    max_utilization_pct DECIMAL(5,2) DEFAULT 95.0,
                    rebalance_threshold_pct DECIMAL(5,2) DEFAULT 15.0,
                    measurement_window_minutes INTEGER DEFAULT 30,
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            session.commit()
            logger.info("✅ Load balancing tables created/validated")
    
    def optimize_skill_distribution_real(self, 
                                        service_ids: List[int],
                                        strategy: DistributionStrategy = DistributionStrategy.HYBRID_OPTIMIZED,
                                        max_moves: int = 10) -> RealSkillDistributionResult:
        """Optimize skill-based agent distribution using real agent capabilities and workload data"""
        start_time = time.time()
        
        try:
            # Get current state from real data
            current_state = self._get_current_distribution_state(service_ids)
            
            if not current_state['agents'] or not current_state['demands']:
                raise ValueError(f"Insufficient data for optimization: {len(current_state['agents'])} agents, {len(current_state['demands'])} demands")
            
            # Calculate current skill utilization
            skill_utilization_before = self._calculate_skill_utilization(current_state)
            
            # Generate optimization decisions based on strategy
            decisions = self._generate_skill_optimization_decisions(
                current_state, strategy, max_moves
            )
            
            # Calculate expected improvements
            expected_state = self._simulate_decisions(current_state, decisions)
            skill_utilization_after = self._calculate_skill_utilization(expected_state)
            
            # Calculate overall improvement
            overall_improvement = self._calculate_overall_improvement(
                skill_utilization_before, skill_utilization_after
            )
            
            # Determine optimization result
            optimization_result = self._determine_optimization_result(
                overall_improvement, len(decisions)
            )
            
            # Save decisions to database
            for decision in decisions:
                self._save_distribution_decision(decision)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            result = RealSkillDistributionResult(
                optimization_id=f"MSD_{int(time.time())}",
                optimization_timestamp=datetime.now(),
                strategy_used=strategy,
                total_agents_analyzed=len(current_state['agents']),
                decisions_made=decisions,
                overall_improvement=overall_improvement,
                skill_utilization_before=skill_utilization_before,
                skill_utilization_after=skill_utilization_after,
                optimization_result=optimization_result,
                processing_time_ms=processing_time * 1000,
                data_quality_score=current_state['data_quality']
            )
            
            logger.info(f"✅ Multi-skill distribution optimization completed: {len(decisions)} decisions, {overall_improvement:.1f}% improvement")
            return result
            
        except Exception as e:
            logger.error(f"❌ Real multi-skill distribution optimization failed: {e}")
            raise ValueError(f"Multi-skill distribution optimization failed: {e}")
    
    def _get_current_distribution_state(self, service_ids: List[int]) -> Dict[str, Any]:
        """Get current agent distribution and skill demand state from real data"""
        with self.SessionLocal() as session:
            # Get current agent status and skills
            agent_data = session.execute(text("""
                SELECT 
                    acs.agent_id,
                    acs.state_code,
                    acs.start_date,
                    aa.login_time,
                    aa.ready_time,
                    aa.not_ready_time,
                    STRING_AGG(ask.skill_name, ',') as skills,
                    AVG(ask.proficiency_level) as avg_proficiency,
                    AVG(ask.performance_rating) as avg_performance
                FROM agent_current_status acs
                LEFT JOIN agent_activity aa ON acs.agent_id = aa.agent_id
                    AND aa.interval_start_time >= NOW() - INTERVAL '2 hours'
                LEFT JOIN agent_skills ask ON acs.agent_id = ask.agent_id
                    AND ask.is_active = true
                WHERE acs.state_code IN ('ready', 'busy', 'wrap_up')
                GROUP BY acs.agent_id, acs.state_code, acs.start_date, aa.login_time, aa.ready_time, aa.not_ready_time
            """)).fetchall()
            
            # Get current demand by skill/service
            demand_data = session.execute(text("""
                SELECT 
                    cs.service_id,
                    cs.received_calls - cs.treated_calls as current_queue_depth,
                    cs.service_level,
                    qp.business_priority,
                    qp.sla_target_seconds,
                    qp.queue_name,
                    COUNT(DISTINCT aa.agent_id) as agents_working
                FROM contact_statistics cs
                JOIN queue_priorities qp ON cs.service_id = qp.service_id
                LEFT JOIN agent_activity aa ON 
                    aa.interval_start_time = cs.interval_start_time
                WHERE cs.service_id = ANY(:service_ids)
                AND cs.interval_start_time >= NOW() - INTERVAL '15 minutes'
                GROUP BY cs.service_id, cs.received_calls, cs.treated_calls, cs.service_level,
                         qp.business_priority, qp.sla_target_seconds, qp.queue_name
                ORDER BY cs.service_id
            """), {'service_ids': service_ids}).fetchall()
            
            # Convert to structured data
            agents = []
            for row in agent_data:
                skills = row.skills.split(',') if row.skills else []
                utilization = 0.0
                if row.login_time and row.login_time > 0:
                    total_time = row.login_time
                    ready_time = row.ready_time or 0
                    utilization = (total_time - ready_time) / total_time if total_time > 0 else 0
                
                agents.append({
                    'agent_id': row.agent_id,
                    'current_status': row.state_code,
                    'skills': skills,
                    'avg_proficiency': float(row.avg_proficiency) if row.avg_proficiency else 3.0,
                    'avg_performance': float(row.avg_performance) if row.avg_performance else 3.0,
                    'current_utilization': utilization,
                    'available_for_rebalance': row.state_code in ['ready', 'wrap_up']
                })
            
            demands = []
            for row in demand_data:
                demands.append({
                    'service_id': row.service_id,
                    'queue_name': row.queue_name,
                    'current_queue_depth': int(row.current_queue_depth) if row.current_queue_depth else 0,
                    'service_level': float(row.service_level) if row.service_level else 0,
                    'business_priority': int(row.business_priority) if row.business_priority else 3,
                    'sla_target_seconds': int(row.sla_target_seconds) if row.sla_target_seconds else 300,
                    'agents_working': int(row.agents_working) if row.agents_working else 0
                })
            
            # Calculate data quality score
            data_quality = min(
                len(agent_data) / max(10, len(service_ids) * 5),  # Expected agents per service
                len(demand_data) / len(service_ids),  # Expected queues per service
                1.0
            )
            
            return {
                'agents': agents,
                'demands': demands,
                'data_quality': data_quality,
                'timestamp': datetime.now()
            }
    
    def _calculate_skill_utilization(self, state: Dict[str, Any]) -> Dict[str, float]:
        """Calculate current skill utilization rates"""
        skill_utilization = {}
        
        # Count available agents by skill
        skill_capacity = {}
        skill_workload = {}
        
        for agent in state['agents']:
            for skill in agent['skills']:
                if skill not in skill_capacity:
                    skill_capacity[skill] = 0
                    skill_workload[skill] = 0
                
                skill_capacity[skill] += 1
                skill_workload[skill] += agent['current_utilization']
        
        # Calculate utilization rates
        for skill in skill_capacity:
            if skill_capacity[skill] > 0:
                skill_utilization[skill] = skill_workload[skill] / skill_capacity[skill]
            else:
                skill_utilization[skill] = 0.0
        
        return skill_utilization
    
    def _generate_skill_optimization_decisions(self, 
                                             current_state: Dict[str, Any],
                                             strategy: DistributionStrategy,
                                             max_moves: int) -> List[RealSkillDistributionDecision]:
        """Generate optimization decisions based on strategy"""
        decisions = []
        
        if strategy == DistributionStrategy.SKILL_MATCH_OPTIMAL:
            decisions = self._optimize_skill_matching(current_state, max_moves)
        elif strategy == DistributionStrategy.WORKLOAD_BALANCED:
            decisions = self._optimize_workload_balance(current_state, max_moves)
        elif strategy == DistributionStrategy.HYBRID_OPTIMIZED:
            decisions = self._optimize_hybrid(current_state, max_moves)
        elif strategy == DistributionStrategy.PRIORITY_BASED:
            decisions = self._optimize_priority_based(current_state, max_moves)
        
        return decisions
    
    def _optimize_skill_matching(self, state: Dict[str, Any], max_moves: int) -> List[RealSkillDistributionDecision]:
        """Optimize based on skill matching quality"""
        decisions = []
        
        # Find skill mismatches and improvement opportunities
        for demand in state['demands']:
            if demand['current_queue_depth'] > 5:  # Only optimize queues with significant demand
                
                # Find best skill matches for this queue
                queue_skills = self._identify_required_skills(demand)
                
                # Find agents who could better serve this queue
                for agent in state['agents']:
                    if not agent['available_for_rebalance']:
                        continue
                    
                    skill_match_score = self._calculate_skill_match_score(agent['skills'], queue_skills)
                    
                    if skill_match_score > 0.7:  # High skill match threshold
                        decision = RealSkillDistributionDecision(
                            decision_id=f"SM_{agent['agent_id']}_{demand['service_id']}_{int(time.time())}",
                            decision_timestamp=datetime.now(),
                            agent_id=agent['agent_id'],
                            from_queue_id=None,  # Current assignment unknown
                            to_queue_id=demand['service_id'],
                            skill_match_score=skill_match_score,
                            workload_improvement=demand['current_queue_depth'] * 0.1,
                            utilization_before=agent['current_utilization'],
                            utilization_after=min(0.95, agent['current_utilization'] + 0.1),
                            expected_efficiency_gain=skill_match_score * 20,  # 20% max gain
                            implementation_priority=int(skill_match_score * 5),
                            decision_confidence=skill_match_score,
                            supporting_skills=agent['skills']
                        )
                        
                        decisions.append(decision)
                        
                        if len(decisions) >= max_moves:
                            break
                
                if len(decisions) >= max_moves:
                    break
        
        return decisions
    
    def _optimize_workload_balance(self, state: Dict[str, Any], max_moves: int) -> List[RealSkillDistributionDecision]:
        """Optimize based on workload balance"""
        decisions = []
        
        # Calculate current workload distribution
        agent_workloads = [(agent['agent_id'], agent['current_utilization']) for agent in state['agents']]
        agent_workloads.sort(key=lambda x: x[1])  # Sort by utilization
        
        if len(agent_workloads) < 2:
            return decisions
        
        # Find imbalanced workloads
        underutilized = [agent for agent in agent_workloads if agent[1] < 0.7]
        overutilized = [agent for agent in agent_workloads if agent[1] > 0.9]
        
        # Generate rebalancing decisions
        for i, (under_agent_id, under_util) in enumerate(underutilized):
            if i >= len(overutilized) or len(decisions) >= max_moves:
                break
                
            over_agent_id, over_util = overutilized[i]
            
            # Find agents in state
            under_agent = next((a for a in state['agents'] if a['agent_id'] == under_agent_id), None)
            over_agent = next((a for a in state['agents'] if a['agent_id'] == over_agent_id), None)
            
            if under_agent and over_agent and under_agent['available_for_rebalance']:
                workload_transfer = (over_util - under_util) / 2
                
                decision = RealSkillDistributionDecision(
                    decision_id=f"WB_{under_agent_id}_{int(time.time())}",
                    decision_timestamp=datetime.now(),
                    agent_id=under_agent_id,
                    from_queue_id=None,
                    to_queue_id=None,  # Workload rebalance across queues
                    skill_match_score=0.8,  # Assume good skill match for simplicity
                    workload_improvement=workload_transfer,
                    utilization_before=under_util,
                    utilization_after=under_util + workload_transfer,
                    expected_efficiency_gain=workload_transfer * 10,  # 10% efficiency per workload unit
                    implementation_priority=3,
                    decision_confidence=0.8,
                    supporting_skills=under_agent['skills']
                )
                
                decisions.append(decision)
        
        return decisions
    
    def _optimize_hybrid(self, state: Dict[str, Any], max_moves: int) -> List[RealSkillDistributionDecision]:
        """Optimize using hybrid approach (skill + workload)"""
        # Combine skill matching and workload balancing
        skill_decisions = self._optimize_skill_matching(state, max_moves // 2)
        workload_decisions = self._optimize_workload_balance(state, max_moves // 2)
        
        # Merge and prioritize decisions
        all_decisions = skill_decisions + workload_decisions
        
        # Sort by combined score (efficiency gain + confidence)
        all_decisions.sort(key=lambda d: d.expected_efficiency_gain * d.decision_confidence, reverse=True)
        
        return all_decisions[:max_moves]
    
    def _optimize_priority_based(self, state: Dict[str, Any], max_moves: int) -> List[RealSkillDistributionDecision]:
        """Optimize based on business priority"""
        decisions = []
        
        # Sort demands by priority and queue depth
        sorted_demands = sorted(
            state['demands'], 
            key=lambda d: (d['business_priority'], d['current_queue_depth']), 
            reverse=True
        )
        
        for demand in sorted_demands:
            if len(decisions) >= max_moves:
                break
                
            if demand['current_queue_depth'] > 2:  # Focus on queues with backlogs
                # Find best available agents for high priority queue
                available_agents = [a for a in state['agents'] if a['available_for_rebalance']]
                
                for agent in available_agents:
                    if len(decisions) >= max_moves:
                        break
                    
                    # Calculate priority-weighted score
                    priority_score = demand['business_priority'] / 5.0  # Normalize to 0-1
                    urgency_score = min(demand['current_queue_depth'] / 20.0, 1.0)  # Normalize queue depth
                    
                    combined_score = (priority_score + urgency_score) / 2
                    
                    if combined_score > 0.6:
                        decision = RealSkillDistributionDecision(
                            decision_id=f"PB_{agent['agent_id']}_{demand['service_id']}_{int(time.time())}",
                            decision_timestamp=datetime.now(),
                            agent_id=agent['agent_id'],
                            from_queue_id=None,
                            to_queue_id=demand['service_id'],
                            skill_match_score=0.7,  # Assume adequate skill match
                            workload_improvement=demand['current_queue_depth'] * 0.15,
                            utilization_before=agent['current_utilization'],
                            utilization_after=min(0.95, agent['current_utilization'] + 0.15),
                            expected_efficiency_gain=combined_score * 25,  # 25% max gain for priority
                            implementation_priority=demand['business_priority'],
                            decision_confidence=combined_score,
                            supporting_skills=agent['skills']
                        )
                        
                        decisions.append(decision)
        
        return decisions
    
    def _identify_required_skills(self, demand: Dict[str, Any]) -> List[str]:
        """Identify skills required for a queue/service"""
        # Simplified skill identification - in production, this would be more sophisticated
        queue_name = demand['queue_name'].lower()
        
        if 'technical' in queue_name or 'support' in queue_name:
            return ['technical_support', 'troubleshooting']
        elif 'sales' in queue_name:
            return ['sales', 'customer_relations']
        elif 'billing' in queue_name or 'payment' in queue_name:
            return ['billing', 'financial_services']
        else:
            return ['general_customer_service']
    
    def _calculate_skill_match_score(self, agent_skills: List[str], required_skills: List[str]) -> float:
        """Calculate how well agent skills match required skills"""
        if not required_skills:
            return 0.5  # Neutral match
        
        matches = len(set(agent_skills) & set(required_skills))
        return matches / len(required_skills)
    
    def _simulate_decisions(self, current_state: Dict[str, Any], decisions: List[RealSkillDistributionDecision]) -> Dict[str, Any]:
        """Simulate the effect of applying decisions"""
        # Create a copy of current state
        simulated_state = {
            'agents': [agent.copy() for agent in current_state['agents']],
            'demands': [demand.copy() for demand in current_state['demands']],
            'data_quality': current_state['data_quality'],
            'timestamp': current_state['timestamp']
        }
        
        # Apply decisions to simulated state
        for decision in decisions:
            # Find the agent and update their utilization
            for agent in simulated_state['agents']:
                if agent['agent_id'] == decision.agent_id:
                    agent['current_utilization'] = decision.utilization_after
                    break
        
        return simulated_state
    
    def _calculate_overall_improvement(self, before: Dict[str, float], after: Dict[str, float]) -> float:
        """Calculate overall improvement percentage"""
        if not before or not after:
            return 0.0
        
        # Calculate variance reduction (better balance = lower variance)
        before_variance = np.var(list(before.values()))
        after_variance = np.var(list(after.values()))
        
        variance_improvement = (before_variance - after_variance) / before_variance if before_variance > 0 else 0
        
        # Calculate average utilization improvement
        before_avg = np.mean(list(before.values()))
        after_avg = np.mean(list(after.values()))
        
        avg_improvement = (after_avg - before_avg) / before_avg if before_avg > 0 else 0
        
        # Combined improvement score
        overall_improvement = (variance_improvement * 0.6 + avg_improvement * 0.4) * 100
        
        return max(0, overall_improvement)
    
    def _determine_optimization_result(self, improvement: float, num_decisions: int) -> OptimizationResult:
        """Determine the optimization result status"""
        if improvement > 10 and num_decisions > 0:
            return OptimizationResult.SUCCESS
        elif improvement > 5 or num_decisions > 0:
            return OptimizationResult.PARTIAL_SUCCESS
        elif improvement > 0:
            return OptimizationResult.NO_IMPROVEMENT
        else:
            return OptimizationResult.FAILED
    
    def _save_distribution_decision(self, decision: RealSkillDistributionDecision):
        """Save distribution decision to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO load_balancing_decisions (
                    algorithm_type, agent_id, from_queue_id, to_queue_id,
                    workload_before, workload_after, expected_improvement,
                    decision_reason, implementation_time_ms
                ) VALUES (
                    'multi_skill_distribution', :agent_id, :from_queue, :to_queue,
                    :workload_before, :workload_after, :expected_improvement,
                    :reason, :impl_time
                )
            """), {
                'agent_id': decision.agent_id,
                'from_queue': decision.from_queue_id,
                'to_queue': decision.to_queue_id,
                'workload_before': {'utilization': decision.utilization_before},
                'workload_after': {'utilization': decision.utilization_after},
                'expected_improvement': decision.expected_efficiency_gain,
                'reason': f"Skill match: {decision.skill_match_score:.2f}, Skills: {', '.join(decision.supporting_skills)}",
                'impl_time': 50  # Estimated implementation time in ms
            })
            
            session.commit()

if __name__ == "__main__":
    # Test the real multi-skill distribution engine
    engine = MultiSkillDistributionEngineReal()
    
    # Test skill distribution optimization
    service_ids = [1, 2, 3]
    try:
        result = engine.optimize_skill_distribution_real(
            service_ids=service_ids,
            strategy=DistributionStrategy.HYBRID_OPTIMIZED,
            max_moves=5
        )
        
        print(f"Multi-skill distribution optimization for services {service_ids}:")
        print(f"  Strategy: {result.strategy_used.value}")
        print(f"  Agents analyzed: {result.total_agents_analyzed}")
        print(f"  Decisions made: {len(result.decisions_made)}")
        print(f"  Overall improvement: {result.overall_improvement:.1f}%")
        print(f"  Optimization result: {result.optimization_result.value}")
        print(f"  Processing time: {result.processing_time_ms:.0f}ms")
        print(f"  Data quality: {result.data_quality_score:.2f}")
        
        for i, decision in enumerate(result.decisions_made[:3]):  # Show first 3 decisions
            print(f"  Decision {i+1}: Agent {decision.agent_id} → Queue {decision.to_queue_id}")
            print(f"    Skill match: {decision.skill_match_score:.2f}, Improvement: {decision.expected_efficiency_gain:.1f}%")
        
    except Exception as e:
        print(f"Multi-skill distribution optimization failed: {e}")
