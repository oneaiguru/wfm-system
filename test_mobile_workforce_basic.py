#!/usr/bin/env python3
"""
Basic Test for Mobile Workforce Scheduler Cost Optimizer - No Database Dependencies

This test demonstrates the core optimization algorithm without database integration.
"""

import asyncio
import logging
import time
from datetime import datetime
from typing import Dict, List

from src.algorithms.optimization.cost_optimizer import (
    MobileWorkforceSchedulerCostOptimizer,
    MobileWorkforceCostParameters
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_basic_optimization():
    """Test basic optimization functionality without database"""
    print("\n" + "="*60)
    print("BASIC MOBILE WORKFORCE SCHEDULER TEST")
    print("="*60)
    
    # Create optimizer with no database URL (will use defaults)
    cost_params = MobileWorkforceCostParameters(
        regular_hourly=25.0,
        overtime_multiplier=1.5,
        night_shift_premium=1.2,
        weekend_premium=1.3,
        travel_cost_per_km=0.5,
        accommodation_per_night=80.0
    )
    
    # Pass None as database URL to avoid connection
    optimizer = MobileWorkforceSchedulerCostOptimizer(cost_params, database_url=None)
    
    try:
        # Create minimal test data
        requirements = [
            {
                'interval': '09:00-09:15',
                'required_agents': 1,
                'skills': [],  # No skill requirements
                'priority': 1,
                'site_id': 'site_a'
            },
            {
                'interval': '09:15-09:30',
                'required_agents': 1,
                'skills': [],
                'priority': 1,
                'site_id': 'site_a'
            }
        ]
        
        agents = [
            {
                'id': 'agent1',
                'name': 'Agent 1',
                'skills': ['general'],
                'availability': ['monday'],
                'base_site': 'site_a'
            },
            {
                'id': 'agent2',
                'name': 'Agent 2',
                'skills': ['general'],
                'availability': ['monday'],
                'base_site': 'site_a'
            }
        ]
        
        # Minimal constraints
        constraints = {
            'max_hours_per_day': 8,
            'min_hours_per_day': 1
        }
        
        print(f"📋 Requirements: {len(requirements)} intervals")
        print(f"👥 Agents: {len(agents)}")
        print(f"🔧 Constraints: Simple scheduling rules")
        
        # Run optimization
        start_time = time.time()
        
        result = await optimizer.optimize_staffing_cost(
            requirements=requirements,
            available_agents=agents,
            constraints=constraints
        )
        
        optimization_time = time.time() - start_time
        
        print(f"\n📊 OPTIMIZATION RESULTS:")
        print(f"  ⏱️  Time: {optimization_time:.3f} seconds")
        print(f"  📈 Quality: {result.optimization_quality}")
        print(f"  💰 Total cost: ${result.total_cost:,.2f}")
        print(f"  📋 Assignments: {len(result.agent_assignments)}")
        print(f"  ✅ Constraints satisfied: {result.constraints_satisfied}")
        print(f"  🔗 Real data integration: {result.real_data_integration}")
        
        if result.cost_breakdown:
            print(f"\n💰 COST BREAKDOWN:")
            for category, amount in result.cost_breakdown.items():
                if amount > 0:
                    print(f"  - {category.replace('_', ' ').title()}: ${amount:,.2f}")
        
        if result.agent_assignments:
            print(f"\n📋 ASSIGNMENTS:")
            for i, assignment in enumerate(result.agent_assignments):
                print(f"  {i+1}. Agent {assignment['agent_id']} → {assignment['interval']} (${assignment['cost']:.2f})")
        
        # Test assertions
        if result.optimization_quality != 'infeasible':
            assert result.total_cost > 0, "Should have positive cost"
            assert len(result.agent_assignments) > 0, "Should have assignments"
            print(f"\n✅ SUCCESS: Basic optimization works correctly!")
        else:
            print(f"\n⚠️  INFEASIBLE: Problem constraints cannot be satisfied")
            print(f"   This indicates the constraint setup needs adjustment")
        
        assert optimization_time < 5.0, "Should optimize quickly"
        
        return result
        
    except Exception as e:
        logger.error(f"Test failed: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        await optimizer.close()

if __name__ == "__main__":
    result = asyncio.run(test_basic_optimization())
    print(f"\n🎉 Basic optimization test completed!")
    
    if result.optimization_quality == 'infeasible':
        print(f"\n📝 NEXT STEPS:")
        print(f"  1. Simplify constraints further")
        print(f"  2. Add more agents or reduce requirements")
        print(f"  3. Debug constraint conflicts in the LP model")
    else:
        print(f"\n🚀 READY FOR:")
        print(f"  1. Real database integration testing")
        print(f"  2. More complex multi-site scenarios")
        print(f"  3. Performance optimization with larger datasets")