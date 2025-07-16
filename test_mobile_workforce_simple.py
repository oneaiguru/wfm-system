#!/usr/bin/env python3
"""
Simple Test for Mobile Workforce Scheduler Cost Optimizer

This test uses minimal requirements to verify the system works.
"""

import asyncio
import logging
from datetime import datetime
from typing import Dict, List

from src.algorithms.optimization.cost_optimizer import (
    MobileWorkforceSchedulerCostOptimizer,
    MobileWorkforceCostParameters
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_simple_requirements() -> List[Dict]:
    """Create very simple requirements for testing"""
    requirements = []
    
    # Just 4 simple intervals
    for i in range(4):
        hour = 9 + i  # 9 AM to 12 PM
        requirements.append({
            'interval': f'site_a_{hour:02d}:00-{hour:02d}:30',
            'required_agents': 1,
            'skills': ['general'],
            'priority': 1,
            'site_id': 'site_a',
            'duration_hours': 0.5
        })
    
    return requirements

def create_simple_agents() -> List[Dict]:
    """Create simple test agents"""
    return [
        {
            'id': 'agent_001',
            'name': 'Test Agent 1',
            'skills': ['general'],
            'availability': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
            'base_site': 'site_a'
        },
        {
            'id': 'agent_002',
            'name': 'Test Agent 2',
            'skills': ['general'],
            'availability': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
            'base_site': 'site_a'
        }
    ]

async def test_simple_mobile_workforce():
    """Simple test to verify basic functionality"""
    print("\n" + "="*60)
    print("SIMPLE MOBILE WORKFORCE SCHEDULER TEST")
    print("="*60)
    
    # Create optimizer with simple parameters
    cost_params = MobileWorkforceCostParameters(
        regular_hourly=25.0,
        budget_constraint_weight=1.0  # No budget constraints
    )
    
    optimizer = MobileWorkforceSchedulerCostOptimizer(cost_params)
    
    try:
        requirements = create_simple_requirements()
        agents = create_simple_agents()
        constraints = {'max_hours_per_day': 8}  # Simple constraints
        
        print(f"📋 Requirements: {len(requirements)}")
        print(f"👥 Agents: {len(agents)}")
        
        # Run optimization
        result = await optimizer.optimize_staffing_cost(
            requirements=requirements,
            available_agents=agents,
            constraints=constraints
        )
        
        print(f"\n📊 RESULTS:")
        print(f"  Status: {result.optimization_quality}")
        print(f"  Cost: ${result.total_cost:,.2f}")
        print(f"  Assignments: {len(result.agent_assignments)}")
        print(f"  Constraints satisfied: {result.constraints_satisfied}")
        
        if result.optimization_quality != 'infeasible':
            print("✅ SUCCESS: Optimization completed successfully!")
        else:
            print("⚠️  INFEASIBLE: Need to adjust constraints")
            
        return result
        
    except Exception as e:
        logger.error(f"Test failed: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        await optimizer.close()

if __name__ == "__main__":
    result = asyncio.run(test_simple_mobile_workforce())
    print(f"\n🎉 Simple test completed!")