#!/usr/bin/env python3
"""
Create all algorithm fix task files for mass subagent execution
Based on Mobile Workforce Scheduler success pattern
"""

import os
from pathlib import Path

# Base directory for tasks
TASK_DIR = Path("/Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes")
TASK_DIR.mkdir(parents=True, exist_ok=True)

# Template for task files
TASK_TEMPLATE = """# 📋 SUBAGENT TASK: Fix {algorithm_name}

## 🎯 Task Information
- **Task ID**: FIX_{task_id}
- **File**: src/algorithms/{file_path}
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- {problem_description}
- Returns mock/simulated data
- No real database connection

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\\dt" | grep -E "{table_hints}"
   ```
2. **Check Current Queries**: Analyze algorithm's database access
3. **Map to Real Schema**: Update to use actual tables/columns
4. **Test with Real Data**: Verify processes real business data
5. **Performance Check**: Meet BDD timing requirements

## 📊 Expected Real Tables to Use
{expected_tables}

## ✅ Success Criteria
- [ ] Uses real database data only
- [ ] No mock data or random values
- [ ] Realistic business results
- [ ] Meets BDD performance requirements
- [ ] All tests pass

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.{file_path} import {class_name}
algorithm = {class_name}()
result = algorithm.{main_method}()
assert len(result) > 0  # Should process real data
print(f"Processed {{len(result)}} real records")
```

## 🔍 Common Issues to Fix
1. Replace mock data generators with real queries
2. Fix table/column names to match actual schema
3. Remove all random.uniform() calls
4. Connect to real business data
5. Verify performance meets BDD specs
"""

# Define all algorithms that need fixing
ALGORITHMS_TO_FIX = [
    # Workflow Algorithms
    {
        "name": "Automation Orchestrator",
        "file": "workflows/automation_orchestrator.py",
        "task_id": "AUTOMATION_ORCHESTRATOR",
        "class_name": "AutomationOrchestrator",
        "main_method": "orchestrate_workflows",
        "problem": "Uses mock workflow definitions",
        "table_hints": "(workflow|automation|process|task)",
        "expected_tables": "- workflow_definitions\n- automation_rules\n- process_instances\n- task_queue"
    },
    {
        "name": "Dynamic Routing",
        "file": "workflows/dynamic_routing.py",
        "task_id": "DYNAMIC_ROUTING",
        "class_name": "DynamicRouter",
        "main_method": "route_tasks",
        "problem": "Mock routing rules and assignments",
        "table_hints": "(routing|assignment|queue|skill)",
        "expected_tables": "- routing_rules\n- skill_based_routing\n- queue_assignments\n- agent_skills"
    },
    {
        "name": "Process Optimizer",
        "file": "workflows/process_optimizer.py",
        "task_id": "PROCESS_OPTIMIZER",
        "class_name": "ProcessOptimizer",
        "main_method": "optimize_processes",
        "problem": "Simulated process metrics",
        "table_hints": "(process|metric|performance|optimization)",
        "expected_tables": "- process_metrics\n- performance_history\n- optimization_rules\n- process_definitions"
    },
    
    # Core Algorithms
    {
        "name": "Multi Skill Allocation",
        "file": "core/multi_skill_allocation.py",
        "task_id": "MULTI_SKILL_ALLOCATION",
        "class_name": "MultiSkillAllocator",
        "main_method": "allocate_resources",
        "problem": "Mock skill matrices and agent data",
        "table_hints": "(skill|employee|allocation|competency)",
        "expected_tables": "- employee_skills\n- skill_requirements\n- skill_groups\n- allocation_rules"
    },
    {
        "name": "Real Time Erlang C",
        "file": "core/real_time_erlang_c.py",
        "task_id": "REAL_TIME_ERLANG_C",
        "class_name": "RealTimeErlangC",
        "main_method": "calculate_real_time",
        "problem": "Uses simulated real-time data",
        "table_hints": "(realtime|current|live|queue)",
        "expected_tables": "- realtime_metrics\n- queue_statistics\n- current_staffing\n- live_service_levels"
    },
    {
        "name": "Shift Optimization",
        "file": "core/shift_optimization.py",
        "task_id": "SHIFT_OPTIMIZATION",
        "class_name": "ShiftOptimizer",
        "main_method": "optimize_shifts",
        "problem": "Mock shift patterns and constraints",
        "table_hints": "(shift|schedule|pattern|template)",
        "expected_tables": "- shift_templates\n- shift_patterns\n- schedule_constraints\n- employee_preferences"
    },
    
    # Mobile Algorithms
    {
        "name": "Geofencing Routing",
        "file": "mobile/geofencing_routing.py",
        "task_id": "GEOFENCING_ROUTING",
        "class_name": "GeofencingRouter",
        "main_method": "route_by_location",
        "problem": "Simulated GPS and geofence data",
        "table_hints": "(location|geofence|zone|territory)",
        "expected_tables": "- geofence_definitions\n- location_zones\n- territory_assignments\n- sites (with lat/lon)"
    },
    {
        "name": "Location Optimization Engine",
        "file": "mobile/location_optimization_engine.py",
        "task_id": "LOCATION_OPTIMIZATION",
        "class_name": "LocationOptimizer",
        "main_method": "optimize_locations",
        "problem": "Mock location and distance data",
        "table_hints": "(location|distance|travel|route)",
        "expected_tables": "- locations\n- inter_location_travel_times\n- route_optimization\n- location_constraints"
    },
    
    # Intraday Algorithms
    {
        "name": "Compliance Validator",
        "file": "intraday/compliance_validator.py",
        "task_id": "COMPLIANCE_VALIDATOR",
        "class_name": "ComplianceValidator",
        "main_method": "validate_compliance",
        "problem": "Mock compliance rules and violations",
        "table_hints": "(compliance|rule|violation|regulation)",
        "expected_tables": "- compliance_rules\n- labor_regulations\n- violation_tracking\n- compliance_audit"
    },
    {
        "name": "Coverage Analyzer",
        "file": "intraday/coverage_analyzer.py",
        "task_id": "COVERAGE_ANALYZER",
        "class_name": "CoverageAnalyzer",
        "main_method": "analyze_coverage",
        "problem": "Simulated coverage gaps",
        "table_hints": "(coverage|gap|staffing|requirement)",
        "expected_tables": "- coverage_requirements\n- staffing_actuals\n- coverage_gaps\n- intraday_forecasts"
    },
    
    # ML/Analytics Algorithms
    {
        "name": "Auto Learning Coefficients",
        "file": "ml/auto_learning_coefficients.py",
        "task_id": "AUTO_LEARNING_COEFFICIENTS",
        "class_name": "AutoLearningCoefficients",
        "main_method": "learn_coefficients",
        "problem": "Uses random coefficients",
        "table_hints": "(coefficient|parameter|learning|model)",
        "expected_tables": "- model_coefficients\n- learning_history\n- parameter_tracking\n- forecast_accuracy"
    },
    {
        "name": "Forecast Accuracy Metrics",
        "file": "ml/forecast_accuracy_metrics.py",
        "task_id": "FORECAST_ACCURACY_METRICS",
        "class_name": "ForecastAccuracyMetrics",
        "main_method": "calculate_accuracy",
        "problem": "Mock forecast vs actual data",
        "table_hints": "(forecast|actual|accuracy|metric)",
        "expected_tables": "- forecast_results\n- actual_volumes\n- accuracy_metrics\n- forecast_historical_data"
    },
    
    # Multisite Algorithms
    {
        "name": "Global Optimizer",
        "file": "multisite/global_optimizer.py",
        "task_id": "GLOBAL_OPTIMIZER",
        "class_name": "GlobalOptimizer",
        "main_method": "optimize_globally",
        "problem": "Mock multi-site data",
        "table_hints": "(site|global|cross_site|multi)",
        "expected_tables": "- sites\n- cross_site_rules\n- global_constraints\n- site_relationships"
    },
    {
        "name": "Resource Sharing Engine",
        "file": "multisite/resource_sharing_engine.py",
        "task_id": "RESOURCE_SHARING",
        "class_name": "ResourceSharingEngine",
        "main_method": "share_resources",
        "problem": "Simulated resource availability",
        "table_hints": "(resource|sharing|pool|allocation)",
        "expected_tables": "- resource_pools\n- sharing_agreements\n- resource_availability\n- cross_site_assignments"
    }
]

def create_task_files():
    """Create all task files for algorithm fixes"""
    created_count = 0
    
    for algo in ALGORITHMS_TO_FIX:
        task_content = TASK_TEMPLATE.format(
            algorithm_name=algo["name"],
            task_id=algo["task_id"],
            file_path=algo["file"],
            problem_description=algo["problem"],
            table_hints=algo["table_hints"],
            expected_tables=algo["expected_tables"],
            class_name=algo["class_name"],
            main_method=algo["main_method"]
        )
        
        filename = f"SUBAGENT_{algo['task_id']}.md"
        filepath = TASK_DIR / filename
        
        with open(filepath, 'w') as f:
            f.write(task_content)
        
        created_count += 1
        print(f"Created: {filename}")
    
    print(f"\n✅ Created {created_count} task files in {TASK_DIR}")
    print("\n📋 Next steps:")
    print("1. Review the generated task files")
    print("2. Launch subagents using the Task tool")
    print("3. Monitor algorithm fixes for real data usage")

if __name__ == "__main__":
    create_task_files()