#!/usr/bin/env python3
"""
Test script for Multi-Skill Allocation with real database data
"""

import sys
import os
import logging
from datetime import datetime

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from algorithms.core.multi_skill_allocation import MultiSkillAllocator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def test_multi_skill_allocation():
    """Test the multi-skill allocation algorithm with real data"""
    print("Testing Multi-Skill Allocation with Real Database Data")
    print("=" * 60)
    
    try:
        # Create allocator instance
        allocator = MultiSkillAllocator()
        
        # Test loading agents from database
        print("\n1. Loading agents from database...")
        agents = allocator.load_agents_from_db()
        print(f"   Loaded {len(agents)} agents")
        
        if agents:
            # Show sample agent data
            agent = agents[0]
            print(f"   Sample agent: ID={agent.id}")
            print(f"   Skills: {agent.skills}")
            print(f"   Max concurrent tasks: {agent.max_concurrent_tasks}")
        
        # Test loading queues from database
        print("\n2. Loading queues/services from database...")
        queues = allocator.load_queues_from_db()
        print(f"   Loaded {len(queues)} queues")
        
        if queues:
            # Show sample queue data
            queue = queues[0]
            print(f"   Sample queue: ID={queue.id}")
            print(f"   Required skills: {queue.required_skills}")
            print(f"   Priority: {queue.priority.name}")
            print(f"   Target wait time: {queue.target_wait_time}s")
        
        # Test the allocation algorithm
        print("\n3. Running allocation algorithm...")
        start_time = datetime.now()
        allocations = allocator.allocate_resources()
        end_time = datetime.now()
        
        print(f"   Allocation completed in {(end_time - start_time).total_seconds():.2f} seconds")
        print(f"   Generated {len(allocations)} allocations")
        
        if allocations:
            # Show sample allocations
            print("\n4. Sample allocations:")
            for i, allocation in enumerate(allocations[:5]):
                print(f"   Allocation {i+1}:")
                print(f"     Agent ID: {allocation.agent_id}")
                print(f"     Queue ID: {allocation.queue_id}")
                print(f"     Skill Score: {allocation.skill_score:.2f}")
                print(f"     Urgency Score: {allocation.urgency_score:.2f}")
        
        # Test performance metrics
        print("\n5. Performance metrics:")
        metrics = allocator.get_performance_metrics()
        for metric_name, values in metrics.items():
            print(f"   {metric_name}:")
            print(f"     Average: {values['avg']:.4f}")
            print(f"     Min: {values['min']:.4f}")
            print(f"     Max: {values['max']:.4f}")
            print(f"     Count: {values['count']}")
        
        # Test Linear Programming optimization
        print("\n6. Testing Linear Programming optimization...")
        if agents and queues:
            # Define constraints and targets
            constraints = {
                'max_utilization': 0.85,
                'min_service_level': 0.80
            }
            targets = {str(q.id): 0.80 for q in queues[:10]}  # Target 80% service level
            
            lp_solution = allocator.solve_optimal_staffing(
                agents[:20],  # Use subset for testing
                queues[:10],
                constraints,
                targets
            )
            
            if lp_solution:
                print("   LP optimization successful")
                print(f"   Solution covers {len(lp_solution)} queues")
            else:
                print("   LP optimization did not find a solution")
        
        print("\n✅ All tests completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Error during testing: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    success = test_multi_skill_allocation()
    sys.exit(0 if success else 1)