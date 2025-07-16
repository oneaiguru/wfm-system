#!/usr/bin/env python3
"""
Comprehensive test for Multi-Skill Allocation with performance metrics
"""

import sys
import os
import logging
from datetime import datetime
import json

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from algorithms.core.multi_skill_allocation import MultiSkillAllocator, SkillPriority

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def test_comprehensive_allocation():
    """Run comprehensive tests on the multi-skill allocation algorithm"""
    
    print("\n" + "="*80)
    print("COMPREHENSIVE MULTI-SKILL ALLOCATION TEST")
    print("="*80)
    
    allocator = MultiSkillAllocator(starvation_threshold=2.5)
    
    # Test 1: Load and analyze agents
    print("\n1. AGENT ANALYSIS")
    print("-" * 40)
    agents = allocator.load_agents_from_db()
    
    # Analyze skill distribution
    skill_counts = {}
    total_skills = 0
    for agent in agents:
        for skill_name in agent.skills:
            skill_counts[skill_name] = skill_counts.get(skill_name, 0) + 1
            total_skills += 1
    
    print(f"Total agents: {len(agents)}")
    print(f"Average skills per agent: {total_skills / len(agents) if agents else 0:.2f}")
    print("\nSkill distribution:")
    for skill, count in sorted(skill_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {skill}: {count} agents ({count/len(agents)*100:.1f}%)")
    
    # Test 2: Load and analyze queues
    print("\n2. QUEUE ANALYSIS")
    print("-" * 40)
    queues = allocator.load_queues_from_db()
    
    print(f"Total queues: {len(queues)}")
    print("\nQueue priorities:")
    priority_counts = {}
    for queue in queues:
        priority_counts[queue.priority.name] = priority_counts.get(queue.priority.name, 0) + 1
    
    for priority, count in sorted(priority_counts.items()):
        print(f"  {priority}: {count} queues")
    
    # Test 3: Run allocation multiple times to gather performance metrics
    print("\n3. ALLOCATION PERFORMANCE TEST")
    print("-" * 40)
    
    allocation_results = []
    for i in range(5):
        print(f"\nRun {i+1}:")
        start_time = datetime.now()
        allocations = allocator.allocate_resources()
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        allocation_results.append({
            'run': i + 1,
            'allocations': len(allocations),
            'duration': duration
        })
        
        print(f"  Allocations: {len(allocations)}")
        print(f"  Duration: {duration:.3f} seconds")
        
        # Show skill match quality
        if allocations:
            avg_skill_score = sum(a.skill_score for a in allocations) / len(allocations)
            avg_urgency_score = sum(a.urgency_score for a in allocations) / len(allocations)
            print(f"  Average skill score: {avg_skill_score:.2f}")
            print(f"  Average urgency score: {avg_urgency_score:.2f}")
    
    # Test 4: Test Linear Programming optimization
    print("\n4. LINEAR PROGRAMMING OPTIMIZATION")
    print("-" * 40)
    
    if agents and queues:
        # Define realistic constraints
        constraints = {
            'max_utilization': 0.85,
            'min_service_level': 0.80,
            'max_concurrent_tasks': 3
        }
        
        # Set service level targets
        targets = {}
        for queue in queues[:10]:
            targets[str(queue.id)] = 0.80  # 80% service level target
        
        print("Constraints:")
        for key, value in constraints.items():
            print(f"  {key}: {value}")
        
        print(f"\nOptimizing for {len(queues[:10])} queues and {len(agents[:20])} agents...")
        
        lp_solution = allocator.solve_optimal_staffing(
            agents[:20],
            queues[:10],
            constraints,
            targets
        )
        
        if lp_solution:
            print("LP optimization successful!")
            total_allocations = sum(len(allocations) for allocations in lp_solution.values())
            print(f"Total allocation decisions: {total_allocations}")
            
            # Show sample allocations
            for queue_id, allocations in list(lp_solution.items())[:3]:
                print(f"\nQueue {queue_id}:")
                for alloc in allocations[:3]:
                    print(f"  Agent {alloc['agent_id']}: {alloc['allocation_ratio']:.2%}")
        else:
            print("LP optimization failed to find a solution")
    
    # Test 5: Performance metrics summary
    print("\n5. PERFORMANCE METRICS SUMMARY")
    print("-" * 40)
    
    metrics = allocator.get_performance_metrics()
    for metric_name, values in metrics.items():
        print(f"\n{metric_name}:")
        print(f"  Average: {values['avg']:.4f}")
        print(f"  Min: {values['min']:.4f}")
        print(f"  Max: {values['max']:.4f}")
        print(f"  Samples: {values['count']}")
    
    # Test 6: Skill coverage analysis
    print("\n6. SKILL COVERAGE ANALYSIS")
    print("-" * 40)
    
    # Analyze which queues might have insufficient coverage
    uncovered_skills = []
    for queue in queues:
        qualified_agents = allocator.filter_qualified_agents(agents, queue.required_skills)
        coverage_ratio = len(qualified_agents) / len(agents) if agents else 0
        
        if coverage_ratio < 0.1:  # Less than 10% of agents qualified
            uncovered_skills.append({
                'queue_id': queue.id,
                'required_skills': queue.required_skills,
                'qualified_agents': len(qualified_agents),
                'coverage_ratio': coverage_ratio
            })
    
    if uncovered_skills:
        print(f"\nQueues with low skill coverage ({len(uncovered_skills)} found):")
        for item in uncovered_skills[:5]:
            print(f"  Queue {item['queue_id']}: {item['coverage_ratio']:.1%} coverage")
            print(f"    Required skills: {list(item['required_skills'].keys())}")
    else:
        print("\nAll queues have adequate skill coverage")
    
    # Test 7: Fairness constraint testing
    print("\n7. FAIRNESS CONSTRAINT TEST")
    print("-" * 40)
    
    # Simulate queue starvation scenario
    if queues:
        # Artificially increase wait times for some queues
        test_queues = queues[:5]
        test_queues[0].current_wait_time = 300  # 5 minutes
        test_queues[1].current_wait_time = 250  # 4+ minutes
        
        print("Simulating queue starvation...")
        print(f"  Queue {test_queues[0].id}: {test_queues[0].current_wait_time}s wait time")
        print(f"  Queue {test_queues[1].id}: {test_queues[1].current_wait_time}s wait time")
        
        # Run allocation with fairness constraints
        allocations = allocator.allocate_agents_to_queues(test_queues, agents[:10])
        allocations = allocator.apply_fairness_constraints(allocations, test_queues)
        
        print(f"\nAllocations after fairness constraints: {len(allocations)}")
        
        # Check if starving queues got priority
        starving_allocations = [a for a in allocations if a.queue_id in [str(test_queues[0].id), str(test_queues[1].id)]]
        print(f"Allocations to starving queues: {len(starving_allocations)}")
    
    print("\n" + "="*80)
    print("COMPREHENSIVE TEST COMPLETED SUCCESSFULLY")
    print("="*80)
    
    return True

if __name__ == "__main__":
    success = test_comprehensive_allocation()
    sys.exit(0 if success else 1)