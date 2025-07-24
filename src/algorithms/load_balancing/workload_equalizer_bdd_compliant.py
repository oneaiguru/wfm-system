#!/usr/bin/env python3
"""
Workload Equalizer - BDD Compliant Version
==========================================

Simplified workload equalization based on BDD specifications from files 10 and 12.
Removed: Advanced statistics, ML clustering, complex equalization algorithms, custom tables
Added: Basic workload reporting for BDD-specified metrics only

BDD Requirements (SPEC-10 & SPEC-12):
- Utilization rate tracking and balancing
- Coverage analysis and workload distribution
- Working days efficiency monitoring
- Simple workload redistribution without ML

Performance: <2s for basic workload analysis
Database: PostgreSQL Schema 001 only (no custom tables)
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum
import uuid

import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

logger = logging.getLogger(__name__)


class WorkloadBalance(Enum):
    """Basic workload balance categories"""
    BALANCED = "balanced"          # Variance < 10%
    SLIGHTLY_UNBALANCED = "slightly_unbalanced"  # Variance 10-20%
    UNBALANCED = "unbalanced"      # Variance > 20%


class EqualizationNeed(Enum):
    """Simple equalization needs"""
    NONE = "none"                  # No action needed
    MINOR_ADJUSTMENT = "minor_adjustment"  # Small redistributions
    MAJOR_REBALANCING = "major_rebalancing"  # Significant changes needed


@dataclass
class BasicWorkloadInsight:
    """Simplified workload analysis result for BDD compliance"""
    analysis_id: str
    service_id: int
    total_agents_analyzed: int
    average_utilization: float
    utilization_variance: float
    min_utilization: float
    max_utilization: float
    workload_balance: WorkloadBalance
    equalization_need: EqualizationNeed
    agents_overloaded: int
    agents_underloaded: int
    recommended_redistributions: int
    analysis_timestamp: datetime
    bdd_interpretation: str
    data_source: str = "REAL_DATABASE"


@dataclass
class BasicAgentWorkload:
    """Simple agent workload state"""
    agent_id: int
    agent_name: str
    utilization_percentage: float
    calls_handled: int
    average_handle_time: float
    workload_status: str  # 'overloaded', 'balanced', 'underloaded'


class WorkloadEqualizerBDDCompliant:
    """BDD-Compliant Workload Analysis using PostgreSQL Schema 001"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 2.0  # 2 seconds for basic workload analysis
        self.target_utilization = 80.0  # Target utilization percentage
        self.balance_threshold = 10.0   # Variance threshold for balanced workload
        
        # Database connection - REQUIRED
        if not database_url:
            database_url = "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        
        try:
            self.engine = create_engine(database_url)
            self.SessionLocal = sessionmaker(bind=self.engine)
            self._validate_database_connection()
        except Exception as e:
            logger.error(f"Failed to initialize database: {str(e)}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Verify Schema 001 tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) 
                    FROM information_schema.tables 
                    WHERE table_name IN ('agent_activity', 'contact_statistics')
                """)).scalar()
                
                if tables_check < 2:
                    raise ConnectionError("Required Schema 001 tables missing")
                    
        except OperationalError as e:
            logger.error(f"Database connection failed: {str(e)}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def analyze_workload_balance(
        self,
        service_id: int,
        analysis_period_hours: int = 24*7  # 1 week default
    ) -> BasicWorkloadInsight:
        """
        Analyze basic workload balance for BDD metrics.
        
        Args:
            service_id: Service to analyze
            analysis_period_hours: Hours of data to analyze
            
        Returns:
            BasicWorkloadInsight with simple workload analysis
        """
        start_time = time.time()
        
        try:
            # Get agent workload data
            agent_workloads = self._get_agent_workloads(service_id, analysis_period_hours)
            
            if not agent_workloads:
                raise ValueError(f"No agent workload data found for service {service_id}")
            
            # Calculate basic metrics
            utilizations = [agent.utilization_percentage for agent in agent_workloads]
            average_utilization = np.mean(utilizations)
            utilization_variance = np.var(utilizations)
            min_utilization = min(utilizations)
            max_utilization = max(utilizations)
            
            # Classify workload balance
            if utilization_variance < 100:  # Std dev < 10%
                balance = WorkloadBalance.BALANCED
            elif utilization_variance < 400:  # Std dev < 20%
                balance = WorkloadBalance.SLIGHTLY_UNBALANCED
            else:
                balance = WorkloadBalance.UNBALANCED
            
            # Determine equalization need
            utilization_range = max_utilization - min_utilization
            if utilization_range < 15:
                need = EqualizationNeed.NONE
            elif utilization_range < 30:
                need = EqualizationNeed.MINOR_ADJUSTMENT
            else:
                need = EqualizationNeed.MAJOR_REBALANCING
            
            # Count agents by workload status
            agents_overloaded = len([a for a in agent_workloads if a.workload_status == 'overloaded'])
            agents_underloaded = len([a for a in agent_workloads if a.workload_status == 'underloaded'])
            
            # Simple redistribution recommendation
            recommended_redistributions = min(agents_overloaded, agents_underloaded)
            
            # Generate BDD interpretation
            interpretation = self._generate_bdd_interpretation(
                average_utilization, balance, need, agents_overloaded, 
                agents_underloaded, len(agent_workloads)
            )
            
            # Create insight
            insight = BasicWorkloadInsight(
                analysis_id=str(uuid.uuid4()),
                service_id=service_id,
                total_agents_analyzed=len(agent_workloads),
                average_utilization=round(average_utilization, 1),
                utilization_variance=round(utilization_variance, 1),
                min_utilization=round(min_utilization, 1),
                max_utilization=round(max_utilization, 1),
                workload_balance=balance,
                equalization_need=need,
                agents_overloaded=agents_overloaded,
                agents_underloaded=agents_underloaded,
                recommended_redistributions=recommended_redistributions,
                analysis_timestamp=datetime.utcnow(),
                bdd_interpretation=interpretation
            )
            
            # Check performance
            processing_time = time.time() - start_time
            if processing_time > self.processing_target:
                logger.warning(
                    f"Workload analysis took {processing_time:.2f}s "
                    f"(target: {self.processing_target}s)"
                )
            
            return insight
            
        except Exception as e:
            logger.error(f"Workload analysis failed: {str(e)}")
            raise
    
    def _get_agent_workloads(self, service_id: int, hours: int) -> List[BasicAgentWorkload]:
        """Get agent workload data from PostgreSQL"""
        with self.SessionLocal() as session:
            # Query agent activity data
            query = text("""
                SELECT 
                    aa.agent_id,
                    a.name as agent_name,
                    AVG(aa.login_time) as avg_login_time,
                    AVG(aa.ready_time) as avg_ready_time,
                    COUNT(DISTINCT aa.interval_start_time) as intervals_worked,
                    AVG(CASE 
                        WHEN aa.login_time > 0 THEN 
                            ((aa.login_time - COALESCE(aa.not_ready_time, 0)) / aa.login_time) * 100
                        ELSE 0 
                    END) as avg_utilization
                FROM agent_activity aa
                LEFT JOIN agents a ON a.id = aa.agent_id
                JOIN service_groups sg ON sg.group_id = aa.group_id
                JOIN services s ON s.id = sg.service_id
                WHERE s.id = :service_id
                    AND aa.interval_start_time >= NOW() - INTERVAL ':hours hours'
                    AND aa.login_time > 0
                GROUP BY aa.agent_id, a.name
                HAVING COUNT(DISTINCT aa.interval_start_time) >= 8
                ORDER BY aa.agent_id
            """)
            
            agent_result = session.execute(
                query,
                {'service_id': service_id, 'hours': hours}
            ).fetchall()
            
            if not agent_result:
                return []
            
            # Get call statistics for the same agents
            agent_ids = [row.agent_id for row in agent_result]
            if not agent_ids:
                return []
            
            # Get call handling stats (approximated from contact_statistics)
            call_query = text("""
                SELECT 
                    :service_id as service_id,
                    AVG(calls_handled) as avg_calls_per_interval,
                    AVG(average_handle_time) as avg_handle_time
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':hours hours'
                    AND calls_handled > 0
            """)
            
            call_result = session.execute(
                call_query,
                {'service_id': service_id, 'hours': hours}
            ).fetchone()
            
            # Default call metrics if no data
            avg_calls_per_agent = 10  # Default
            avg_handle_time = 300     # Default 5 minutes
            
            if call_result and call_result.avg_calls_per_interval:
                avg_calls_per_agent = int(call_result.avg_calls_per_interval / max(1, len(agent_result)))
                avg_handle_time = call_result.avg_handle_time or 300
            
            # Create agent workload objects
            agent_workloads = []
            for row in agent_result:
                utilization = float(row.avg_utilization or 0)
                
                # Determine workload status
                if utilization > self.target_utilization + 15:  # > 95%
                    status = 'overloaded'
                elif utilization < self.target_utilization - 15:  # < 65%
                    status = 'underloaded'
                else:
                    status = 'balanced'
                
                agent_workloads.append(BasicAgentWorkload(
                    agent_id=row.agent_id,
                    agent_name=row.agent_name or f"Agent_{row.agent_id}",
                    utilization_percentage=utilization,
                    calls_handled=avg_calls_per_agent,
                    average_handle_time=avg_handle_time,
                    workload_status=status
                ))
            
            return agent_workloads
    
    def _generate_bdd_interpretation(
        self,
        avg_utilization: float,
        balance: WorkloadBalance,
        need: EqualizationNeed,
        overloaded: int,
        underloaded: int,
        total_agents: int
    ) -> str:
        """Generate BDD-compliant business interpretation"""
        
        # Base balance interpretation
        balance_interpretations = {
            WorkloadBalance.BALANCED: f"Workload well balanced across {total_agents} agents (avg: {avg_utilization:.1f}%)",
            WorkloadBalance.SLIGHTLY_UNBALANCED: f"Minor workload imbalances detected across {total_agents} agents (avg: {avg_utilization:.1f}%)",
            WorkloadBalance.UNBALANCED: f"Significant workload imbalances across {total_agents} agents (avg: {avg_utilization:.1f}%)"
        }
        
        base_interpretation = balance_interpretations[balance]
        
        # Add agent status details
        agent_details = []
        if overloaded > 0:
            agent_details.append(f"{overloaded} agents overloaded (>95% utilization)")
        if underloaded > 0:
            agent_details.append(f"{underloaded} agents underutilized (<65% utilization)")
        
        # Add action recommendations per BDD requirements
        action_recommendations = {
            EqualizationNeed.NONE: "No workload redistribution needed - maintain current allocation",
            EqualizationNeed.MINOR_ADJUSTMENT: "Minor workload adjustments recommended to optimize utilization",
            EqualizationNeed.MAJOR_REBALANCING: "Major workload rebalancing required to improve fairness and efficiency"
        }
        
        action_text = action_recommendations[need]
        
        # BDD-specific insights (SPEC-10 & SPEC-12)
        bdd_insights = []
        
        # Working days efficiency insight
        if avg_utilization < 70:
            bdd_insights.append("Working days efficiency below target - review scheduling patterns")
        elif avg_utilization > 90:
            bdd_insights.append("High utilization may impact service quality - monitor closely")
        
        # Coverage analysis insight
        balanced_agents = total_agents - overloaded - underloaded
        if balanced_agents / total_agents < 0.6:  # Less than 60% balanced
            bdd_insights.append("Coverage at risk due to workload imbalances - prioritize equalization")
        
        # Utilization rate tracking insight
        if need == EqualizationNeed.MAJOR_REBALANCING:
            bdd_insights.append("Utilization variance exceeds acceptable limits per BDD requirements")
        
        # Combine all parts
        full_interpretation = base_interpretation
        if agent_details:
            full_interpretation += f". {'; '.join(agent_details)}"
        if bdd_insights:
            full_interpretation += f". {'; '.join(bdd_insights)}"
        full_interpretation += f". {action_text}."
        
        return full_interpretation
    
    def get_agent_workload_details(
        self,
        service_id: int,
        analysis_period_hours: int = 24*7
    ) -> List[BasicAgentWorkload]:
        """Get detailed agent workload information"""
        return self._get_agent_workloads(service_id, analysis_period_hours)
    
    def analyze_multi_service_workloads(
        self,
        service_ids: List[int],
        analysis_period_hours: int = 24*7
    ) -> List[BasicWorkloadInsight]:
        """Analyze workload balance for multiple services"""
        
        insights = []
        for service_id in service_ids:
            try:
                insight = self.analyze_workload_balance(
                    service_id=service_id,
                    analysis_period_hours=analysis_period_hours
                )
                insights.append(insight)
            except Exception as e:
                logger.warning(f"Failed to analyze workload for service {service_id}: {e}")
                continue
        
        return insights


if __name__ == "__main__":
    # This will fail without a real database - proving no mocks!
    try:
        equalizer = WorkloadEqualizerBDDCompliant()
        
        # Test workload analysis
        insight = equalizer.analyze_workload_balance(service_id=1)
        
        print(f"Workload Balance Analysis Results:")
        print(f"  Total Agents: {insight.total_agents_analyzed}")
        print(f"  Average Utilization: {insight.average_utilization}%")
        print(f"  Utilization Range: {insight.min_utilization}% - {insight.max_utilization}%")
        print(f"  Variance: {insight.utilization_variance:.1f}")
        print(f"  Balance Status: {insight.workload_balance.value}")
        print(f"  Equalization Need: {insight.equalization_need.value}")
        print(f"  Overloaded Agents: {insight.agents_overloaded}")
        print(f"  Underloaded Agents: {insight.agents_underloaded}")
        print(f"  Recommended Redistributions: {insight.recommended_redistributions}")
        print(f"  Interpretation: {insight.bdd_interpretation}")
        
        # Test agent details
        agent_details = equalizer.get_agent_workload_details(service_id=1)
        print(f"\nAgent Details: {len(agent_details)} agents found")
        for agent in agent_details[:3]:  # Show first 3
            print(f"  {agent.agent_name}: {agent.utilization_percentage:.1f}% ({agent.workload_status})")
        
    except ConnectionError as e:
        print(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
        print("This is expected behavior without real database connection")