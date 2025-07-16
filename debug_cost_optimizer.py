#!/usr/bin/env python3
"""
Debug Cost Optimizer - Find the root cause of infeasibility
"""

import pulp
import logging

logging.basicConfig(level=logging.INFO)

def debug_simple_assignment():
    """Create the simplest possible LP problem to test"""
    print("🔍 DEBUGGING COST OPTIMIZER")
    print("="*50)
    
    # Create problem
    prob = pulp.LpProblem("Debug_Test", pulp.LpMinimize)
    
    # Variables: assign agent1 to interval1, agent2 to interval1
    x1 = pulp.LpVariable("assign_agent1_interval1", cat='Binary')
    x2 = pulp.LpVariable("assign_agent2_interval1", cat='Binary')
    
    # Objective: minimize cost (arbitrary costs)
    prob += 10 * x1 + 12 * x2
    
    # Constraint: exactly 1 agent needed for interval1
    prob += x1 + x2 >= 1, "coverage_constraint"
    
    print(f"📋 Problem setup:")
    print(f"  Variables: x1 (agent1→interval1), x2 (agent2→interval1)")
    print(f"  Objective: minimize 10*x1 + 12*x2")
    print(f"  Constraint: x1 + x2 >= 1")
    
    # Solve
    status = prob.solve(pulp.PULP_CBC_CMD(msg=0))
    
    print(f"\n📊 Results:")
    print(f"  Status: {pulp.LpStatus[status]}")
    
    if status == pulp.LpStatusOptimal:
        print(f"  Solution: x1={x1.varValue}, x2={x2.varValue}")
        print(f"  Cost: {pulp.value(prob.objective)}")
        print("✅ SUCCESS: Basic LP problem works!")
        return True
    else:
        print("❌ FAILED: Even simple LP problem is infeasible")
        return False

def debug_mobile_workforce_structure():
    """Debug the mobile workforce variable structure"""
    print(f"\n🔍 DEBUGGING MOBILE WORKFORCE STRUCTURE")
    print("="*50)
    
    # Simulate the mobile workforce variable creation
    agents = [{'id': 'agent1'}, {'id': 'agent2'}]
    requirements = [
        {'interval': 'int1', 'site_id': 'site_a'},
        {'interval': 'int2', 'site_id': 'site_a'}
    ]
    
    # Create variables like in the real code
    agent_vars = {}
    travel_vars = {}
    
    for agent in agents:
        agent_id = agent['id']
        for req_idx, req in enumerate(requirements):
            interval = req['interval']
            site_id = req.get('site_id', 'default')
            
            # Main assignment variable
            var_name = f"assign_{agent_id}_{interval}_{req_idx}"
            agent_vars[(agent_id, interval, req_idx)] = pulp.LpVariable(
                var_name, cat='Binary'
            )
            
            # Travel variable
            travel_var_name = f"travel_{agent_id}_{site_id}_{req_idx}"
            travel_vars[(agent_id, site_id, req_idx)] = pulp.LpVariable(
                travel_var_name, cat='Binary'
            )
    
    print(f"📋 Variable structure:")
    print(f"  Assignment variables: {len(agent_vars)}")
    for key in agent_vars.keys():
        print(f"    {key}")
    print(f"  Travel variables: {len(travel_vars)}")
    for key in travel_vars.keys():
        print(f"    {key}")
    
    # Create problem and test basic constraints
    prob = pulp.LpProblem("Debug_Mobile", pulp.LpMinimize)
    
    # Simple objective
    objective = 0
    for var in agent_vars.values():
        objective += 10 * var
    prob += objective
    
    # Simple coverage constraint: each requirement needs exactly 1 agent
    for req_idx, req in enumerate(requirements):
        interval = req['interval']
        constraint_vars = [agent_vars[(agent['id'], interval, req_idx)] for agent in agents]
        prob += pulp.lpSum(constraint_vars) >= 1, f"coverage_{interval}_{req_idx}"
    
    print(f"\n📊 Constraint test:")
    print(f"  Added {len(requirements)} coverage constraints")
    
    # Solve
    status = prob.solve(pulp.PULP_CBC_CMD(msg=0))
    
    print(f"  Status: {pulp.LpStatus[status]}")
    
    if status == pulp.LpStatusOptimal:
        print(f"  Objective value: {pulp.value(prob.objective)}")
        print("✅ SUCCESS: Mobile workforce structure works!")
        
        # Show solution
        print(f"\n📋 Solution:")
        for key, var in agent_vars.items():
            if var.varValue == 1:
                agent_id, interval, req_idx = key
                print(f"  Assign {agent_id} to {interval} (req {req_idx})")
        
        return True
    else:
        print("❌ FAILED: Mobile workforce structure has issues")
        return False

if __name__ == "__main__":
    success1 = debug_simple_assignment()
    success2 = debug_mobile_workforce_structure()
    
    if success1 and success2:
        print(f"\n🎉 DEBUGGING COMPLETE: Core LP functionality works!")
        print(f"   Issue must be in the complex constraint setup")
    else:
        print(f"\n⚠️  DEBUGGING FOUND ISSUES: Need to fix basic LP setup")