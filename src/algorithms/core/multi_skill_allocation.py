"""
Multi-Skill Allocation Algorithms for WFM Enterprise
Implements Linear Programming optimization and priority-based routing
"""

import numpy as np
from scipy.optimize import linprog
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import time
import logging
import psycopg2
import psycopg2.extras
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import os

logger = logging.getLogger(__name__)

class SkillPriority(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

@dataclass
class Agent:
    id: str
    skills: Dict[str, float]  # skill_name -> proficiency_level (0-1)
    availability: bool
    idle_time: float
    max_concurrent_tasks: int
    current_tasks: int = 0

@dataclass
class Queue:
    id: str
    required_skills: Dict[str, float]  # skill_name -> minimum_required_level
    priority: SkillPriority
    current_wait_time: float
    target_wait_time: float
    call_volume: float
    arrival_rate: float

@dataclass
class AllocationResult:
    agent_id: str
    queue_id: str
    skill_score: float
    urgency_score: float
    timestamp: float

class MultiSkillAllocator:
    def __init__(self, starvation_threshold: float = 3.0):
        self.starvation_threshold = starvation_threshold
        self.performance_metrics = {
            'allocation_times': [],
            'skill_match_accuracy': [],
            'queue_wait_times': [],
            'solution_times': []
        }
        # Database connection parameters
        self.db_params = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': os.getenv('DB_PORT', '5432'),
            'dbname': 'wfm_enterprise',
            'user': 'postgres',
            'password': os.getenv('DB_PASSWORD', '')
        }
    
    def get_db_connection(self):
        """Create database connection"""
        return psycopg2.connect(**self.db_params)
    
    def load_agents_from_db(self) -> List[Agent]:
        """Load real agent data from database"""
        agents = []
        
        with self.get_db_connection() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                # Get employees with their skills
                cur.execute("""
                    SELECT 
                        e.id,
                        e.first_name,
                        e.last_name,
                        e.is_active,
                        COALESCE(e.work_rate, 1.0) as work_rate,
                        array_agg(
                            json_build_object(
                                'skill_id', es.skill_id,
                                'skill_name', s.name,
                                'proficiency', es.proficiency_level
                            )
                        ) FILTER (WHERE es.skill_id IS NOT NULL) as skills
                    FROM employees e
                    LEFT JOIN employee_skills es ON e.id = es.employee_id
                    LEFT JOIN skills s ON es.skill_id = s.id
                    WHERE e.is_active = true
                    GROUP BY e.id, e.first_name, e.last_name, e.is_active, e.work_rate
                    LIMIT 100
                """)
                
                for row in cur.fetchall():
                    # Convert skills to dictionary
                    skills_dict = {}
                    if row['skills']:
                        for skill in row['skills']:
                            # Normalize proficiency level from 1-5 to 0-1
                            skills_dict[skill['skill_name']] = skill['proficiency'] / 5.0
                    
                    agent = Agent(
                        id=str(row['id']),
                        skills=skills_dict,
                        availability=row['is_active'],
                        idle_time=0.0,  # Would need real-time data
                        max_concurrent_tasks=int(row['work_rate'] * 3),  # Assume 3 tasks at full rate
                        current_tasks=0
                    )
                    agents.append(agent)
        
        logger.info(f"Loaded {len(agents)} agents from database")
        return agents
    
    def load_queues_from_db(self) -> List[Queue]:
        """Load real queue/service data from database"""
        queues = []
        
        with self.get_db_connection() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                # Get services as queues
                cur.execute("""
                    SELECT 
                        s.id,
                        s.service_name,
                        s.service_code,
                        s.priority_level,
                        s.target_answer_time,
                        s.target_service_level,
                        s.max_wait_time,
                        COALESCE(qm.avg_wait_time_last_15min, 0) as current_wait_time,
                        COALESCE(qm.calls_handled_last_15min * 4, 40) as arrival_rate,
                        COALESCE(qm.calls_waiting, 0) as call_volume
                    FROM services s
                    LEFT JOIN queue_current_metrics qm ON s.id = qm.service_id
                    WHERE s.is_active = true
                    LIMIT 50
                """)
                
                service_rows = cur.fetchall()
                
                # Get skill requirements from multiskill distribution
                cur.execute("""
                    SELECT DISTINCT 
                        primary_skill,
                        secondary_skills
                    FROM multiskill_operator_distribution
                    WHERE primary_skill IS NOT NULL
                """)
                
                skill_data = cur.fetchall()
                all_skills = set()
                for row in skill_data:
                    all_skills.add(row['primary_skill'])
                    if row['secondary_skills']:
                        all_skills.update(row['secondary_skills'])
                
                # Create queues from services
                for idx, service in enumerate(service_rows):
                    # Assign skills based on service type (simplified logic)
                    required_skills = {}
                    
                    # Map skills to services based on patterns and available skills
                    if 'support' in service['service_name'].lower():
                        required_skills['Technical Support'] = 0.6
                        required_skills['Customer Service'] = 0.4
                    elif 'sales' in service['service_name'].lower():
                        required_skills['Sales'] = 0.8
                        required_skills['Customer Service'] = 0.4
                    elif 'billing' in service['service_name'].lower():
                        required_skills['Billing Support'] = 0.7  # Fixed skill name
                        required_skills['Customer Service'] = 0.5
                    elif 'chat' in service['service_name'].lower():
                        required_skills['Chat Support'] = 0.8
                        required_skills['Customer Service'] = 0.3
                    else:
                        # Default skills
                        required_skills['Customer Service'] = 0.5
                    
                    # Map priority levels
                    priority_map = {1: SkillPriority.LOW, 2: SkillPriority.MEDIUM, 
                                   3: SkillPriority.HIGH, 4: SkillPriority.CRITICAL}
                    
                    queue = Queue(
                        id=str(service['id']),
                        required_skills=required_skills,
                        priority=priority_map.get(service['priority_level'], SkillPriority.MEDIUM),
                        current_wait_time=float(service['current_wait_time']),
                        target_wait_time=float(service['target_answer_time']),
                        call_volume=float(service['call_volume']),
                        arrival_rate=float(service['arrival_rate'])
                    )
                    queues.append(queue)
        
        logger.info(f"Loaded {len(queues)} queues from database")
        return queues
    
    def save_allocation_results(self, allocations: List[AllocationResult]):
        """Save allocation results to database"""
        if not allocations:
            return
        
        with self.get_db_connection() as conn:
            with conn.cursor() as cur:
                # Create allocation results table if not exists
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS allocation_results (
                        id SERIAL PRIMARY KEY,
                        agent_id UUID,
                        queue_id INTEGER,
                        skill_score FLOAT,
                        urgency_score FLOAT,
                        allocated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Insert allocation results
                for allocation in allocations:
                    cur.execute("""
                        INSERT INTO allocation_results 
                        (agent_id, queue_id, skill_score, urgency_score)
                        VALUES (%s, %s, %s, %s)
                    """, (
                        allocation.agent_id,
                        int(allocation.queue_id),
                        allocation.skill_score,
                        allocation.urgency_score
                    ))
                
                conn.commit()
                logger.info(f"Saved {len(allocations)} allocation results to database")
    
    def allocate_resources(self) -> List[AllocationResult]:
        """Main allocation method using real database data"""
        # Load real data
        agents = self.load_agents_from_db()
        queues = self.load_queues_from_db()
        
        if not agents:
            logger.warning("No agents found in database")
            return []
        
        if not queues:
            logger.warning("No queues found in database")
            return []
        
        # Calculate urgency scores
        urgency_scores = self.calculate_urgency_scores(queues)
        
        # Sort queues by priority
        sorted_queues = self.sort_queues_by_priority(queues, urgency_scores)
        
        # Allocate agents to queues
        allocations = self.allocate_agents_to_queues(sorted_queues, agents.copy())
        
        # Apply fairness constraints
        allocations = self.apply_fairness_constraints(allocations, queues)
        
        # Save results to database
        self.save_allocation_results(allocations)
        
        return allocations
    
    def formulate_lp_problem(self, agents: List[Agent], queues: List[Queue], 
                           constraints: Dict, targets: Dict) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        Formulate Linear Programming problem for optimal staffing
        
        Returns:
            c: cost coefficients
            A_ub: inequality constraint matrix
            b_ub: inequality constraint bounds
        """
        n_agents = len(agents)
        n_queues = len(queues)
        
        # Objective: minimize total cost (agent utilization costs)
        c = np.ones(n_agents * n_queues)
        
        # Constraints matrix
        constraints_list = []
        bounds_list = []
        
        # Service level constraints
        for i, queue in enumerate(queues):
            constraint_row = np.zeros(n_agents * n_queues)
            for j, agent in enumerate(agents):
                # Agent j assigned to queue i
                idx = i * n_agents + j
                skill_coverage = self._calculate_skill_coverage(agent, queue)
                constraint_row[idx] = skill_coverage
            
            constraints_list.append(-constraint_row)  # Negative for >= constraint
            bounds_list.append(-targets.get(queue.id, 0.8))  # Target service level
        
        # Agent availability constraints
        for j, agent in enumerate(agents):
            constraint_row = np.zeros(n_agents * n_queues)
            for i in range(n_queues):
                idx = i * n_agents + j
                constraint_row[idx] = 1
            constraints_list.append(constraint_row)
            bounds_list.append(agent.max_concurrent_tasks)
        
        A_ub = np.array(constraints_list)
        b_ub = np.array(bounds_list)
        
        return c, A_ub, b_ub
    
    def solve_optimal_staffing(self, agents: List[Agent], queues: List[Queue],
                             constraints: Dict, targets: Dict) -> Optional[Dict]:
        """
        Solve Linear Programming problem for optimal staffing allocation
        """
        start_time = time.time()
        
        try:
            c, A_ub, b_ub = self.formulate_lp_problem(agents, queues, constraints, targets)
            
            # Bounds for variables (0 <= x <= 1 for allocation variables)
            bounds = [(0, 1) for _ in range(len(c))]
            
            result = linprog(c, A_ub=A_ub, b_ub=b_ub, bounds=bounds, method='highs')
            
            solution_time = time.time() - start_time
            self.performance_metrics['solution_times'].append(solution_time)
            
            if result.success:
                return self._parse_lp_solution(result.x, agents, queues)
            else:
                logger.warning(f"LP optimization failed: {result.message}")
                return None
                
        except Exception as e:
            logger.error(f"LP optimization error: {e}")
            return None
    
    def calculate_skill_scores(self, agent_skills: Dict[str, float], 
                             required_skills: Dict[str, float],
                             priorities: Dict[str, SkillPriority]) -> float:
        """
        Calculate skill matching score for an agent
        
        Formula: score = Σ(skill_level × priority_weight × urgency_weight)
        """
        total_score = 0.0
        
        for skill, required_level in required_skills.items():
            if skill in agent_skills:
                skill_level = agent_skills[skill]
                priority_weight = priorities.get(skill, SkillPriority.MEDIUM).value
                
                # Skill contribution (higher if agent exceeds requirement)
                skill_contribution = min(skill_level / required_level, 2.0)
                
                total_score += skill_contribution * priority_weight
        
        return total_score
    
    def filter_qualified_agents(self, agents: List[Agent], 
                              required_skills: Dict[str, float],
                              min_threshold: float = 0.7) -> List[Agent]:
        """
        Filter agents that meet minimum skill requirements
        """
        qualified = []
        
        for agent in agents:
            if not agent.availability or agent.current_tasks >= agent.max_concurrent_tasks:
                continue
                
            # Check if agent meets minimum skill requirements
            meets_requirements = True
            for skill, required_level in required_skills.items():
                if skill not in agent.skills or agent.skills[skill] < required_level * min_threshold:
                    meets_requirements = False
                    break
            
            if meets_requirements:
                qualified.append(agent)
        
        return qualified
    
    def select_best_agent(self, qualified_agents: List[Agent], 
                         required_skills: Dict[str, float],
                         priorities: Dict[str, SkillPriority],
                         tiebreaker: str = 'longest_idle') -> Optional[Agent]:
        """
        Select the best agent from qualified candidates
        """
        if not qualified_agents:
            return None
        
        # Calculate scores for all qualified agents
        agent_scores = []
        for agent in qualified_agents:
            skill_score = self.calculate_skill_scores(agent.skills, required_skills, priorities)
            agent_scores.append((agent, skill_score))
        
        # Sort by skill score (descending)
        agent_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Apply tiebreaker for agents with similar scores
        if len(agent_scores) > 1 and abs(agent_scores[0][1] - agent_scores[1][1]) < 0.01:
            if tiebreaker == 'longest_idle':
                return max(agent_scores[:3], key=lambda x: x[0].idle_time)[0]
            elif tiebreaker == 'lowest_utilization':
                return min(agent_scores[:3], key=lambda x: x[0].current_tasks)[0]
        
        return agent_scores[0][0]
    
    def calculate_urgency_scores(self, queues: List[Queue]) -> Dict[str, float]:
        """
        Calculate urgency scores for all queues
        
        Formula: urgency = λ × (current_wait - target_wait)
        """
        urgency_scores = {}
        
        for queue in queues:
            wait_time_diff = queue.current_wait_time - queue.target_wait_time
            urgency = queue.arrival_rate * max(wait_time_diff, 0)
            urgency_scores[queue.id] = urgency
        
        return urgency_scores
    
    def sort_queues_by_priority(self, queues: List[Queue], 
                              urgency_scores: Dict[str, float]) -> List[Queue]:
        """
        Sort queues by combined priority and urgency
        """
        def queue_priority_key(queue):
            base_priority = queue.priority.value * 1000  # Base priority weight
            urgency_component = urgency_scores.get(queue.id, 0)
            return base_priority + urgency_component
        
        return sorted(queues, key=queue_priority_key, reverse=True)
    
    def allocate_agents_to_queues(self, sorted_queues: List[Queue], 
                                available_agents: List[Agent]) -> List[AllocationResult]:
        """
        Allocate agents to queues based on priority and skills
        """
        start_time = time.time()
        allocations = []
        
        for queue in sorted_queues:
            # Find qualified agents for this queue
            qualified = self.filter_qualified_agents(available_agents, queue.required_skills)
            
            if not qualified:
                continue
            
            # Select best agent
            priorities = {skill: SkillPriority.HIGH for skill in queue.required_skills}
            best_agent = self.select_best_agent(qualified, queue.required_skills, priorities)
            
            if best_agent:
                # Calculate scores
                skill_score = self.calculate_skill_scores(
                    best_agent.skills, queue.required_skills, priorities
                )
                urgency_score = self.calculate_urgency_scores([queue])[queue.id]
                
                allocation = AllocationResult(
                    agent_id=best_agent.id,
                    queue_id=queue.id,
                    skill_score=skill_score,
                    urgency_score=urgency_score,
                    timestamp=time.time()
                )
                allocations.append(allocation)
                
                # Update agent availability
                best_agent.current_tasks += 1
                best_agent.idle_time = 0
                
                # Remove agent if at capacity
                if best_agent.current_tasks >= best_agent.max_concurrent_tasks:
                    available_agents.remove(best_agent)
        
        allocation_time = time.time() - start_time
        self.performance_metrics['allocation_times'].append(allocation_time)
        
        return allocations
    
    def apply_fairness_constraints(self, allocations: List[AllocationResult],
                                 queues: List[Queue]) -> List[AllocationResult]:
        """
        Apply fairness constraints to prevent queue starvation
        """
        queue_wait_times = {q.id: q.current_wait_time for q in queues}
        
        if not queue_wait_times:
            return allocations
        
        avg_wait_time = sum(queue_wait_times.values()) / len(queue_wait_times)
        max_allowed_wait = avg_wait_time * self.starvation_threshold
        
        # Check for starving queues
        starving_queues = [
            q_id for q_id, wait_time in queue_wait_times.items()
            if wait_time > max_allowed_wait
        ]
        
        if starving_queues:
            # Prioritize starving queues in next allocation cycle
            logger.warning(f"Queue starvation detected: {starving_queues}")
            
            # Redistribute some allocations
            for queue_id in starving_queues:
                # Find lowest priority allocation to potentially reassign
                reassignable = [a for a in allocations if a.urgency_score < avg_wait_time]
                if reassignable:
                    lowest_priority = min(reassignable, key=lambda x: x.urgency_score)
                    lowest_priority.queue_id = queue_id
                    logger.info(f"Reassigned agent {lowest_priority.agent_id} to starving queue {queue_id}")
        
        return allocations
    
    def create_state_representation(self, queues: List[Queue], 
                                  agents: List[Agent]) -> np.ndarray:
        """
        Create state representation for future DQN integration
        """
        state_vector = []
        
        # Queue states
        for queue in queues:
            state_vector.extend([
                queue.current_wait_time,
                queue.target_wait_time,
                queue.arrival_rate,
                queue.priority.value
            ])
        
        # Agent states
        for agent in agents:
            state_vector.extend([
                agent.idle_time,
                agent.current_tasks / agent.max_concurrent_tasks,
                len(agent.skills),
                float(agent.availability)
            ])
        
        return np.array(state_vector)
    
    def calculate_reward(self, state: np.ndarray, action: int, 
                        penalties: Dict[str, float]) -> float:
        """
        Calculate reward for DQN training
        
        Formula: R(s,a) = -α×waiting_penalty - β×abandonment_penalty - γ×occupancy_penalty
        """
        alpha = penalties.get('waiting', 1.0)
        beta = penalties.get('abandonment', 2.0)
        gamma = penalties.get('occupancy', 0.5)
        
        # Extract metrics from state
        avg_wait_time = np.mean(state[::4])  # Every 4th element is wait time
        occupancy_rate = np.mean(state[1::4])  # Occupancy metrics
        
        waiting_penalty = alpha * avg_wait_time
        abandonment_penalty = beta * max(0, avg_wait_time - 120)  # Penalty after 2 minutes
        occupancy_penalty = gamma * abs(occupancy_rate - 0.85)  # Target 85% occupancy
        
        return -(waiting_penalty + abandonment_penalty + occupancy_penalty)
    
    def get_performance_metrics(self) -> Dict:
        """
        Get current performance metrics
        """
        metrics = {}
        for key, values in self.performance_metrics.items():
            if values:
                metrics[key] = {
                    'avg': np.mean(values),
                    'max': np.max(values),
                    'min': np.min(values),
                    'count': len(values)
                }
        return metrics
    
    def _calculate_skill_coverage(self, agent: Agent, queue: Queue) -> float:
        """
        Calculate how well an agent covers queue skill requirements
        """
        if not queue.required_skills:
            return 1.0
        
        coverage_scores = []
        for skill, required_level in queue.required_skills.items():
            if skill in agent.skills:
                coverage = min(agent.skills[skill] / required_level, 1.0)
                coverage_scores.append(coverage)
            else:
                coverage_scores.append(0.0)
        
        return np.mean(coverage_scores)
    
    def _parse_lp_solution(self, solution: np.ndarray, agents: List[Agent], 
                          queues: List[Queue]) -> Dict:
        """
        Parse LP solution into allocation dictionary
        """
        allocations = {}
        n_agents = len(agents)
        
        for i, queue in enumerate(queues):
            queue_allocations = []
            for j, agent in enumerate(agents):
                idx = i * n_agents + j
                if solution[idx] > 0.01:  # Threshold for meaningful allocation
                    queue_allocations.append({
                        'agent_id': agent.id,
                        'allocation_ratio': solution[idx]
                    })
            allocations[queue.id] = queue_allocations
        
        return allocations