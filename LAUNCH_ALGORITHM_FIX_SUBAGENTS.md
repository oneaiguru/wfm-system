# 🚀 Algorithm Fix Mass Subagent Launch Plan

## ✅ Preparation Complete
- **Task Files Created**: 16 initial tasks + framework for remaining
- **Success Pattern**: Mobile Workforce Scheduler fix proven
- **Target**: Fix 57 algorithms to use real data

## 📋 Launch Commands for Subagents

### Batch 1: Workflow Algorithms (9 subagents)
```python
# Launch workflow algorithm fixes
Task(description="Fix Approval Engine", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_FIX_APPROVAL_ENGINE.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Vacation Processor", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_FIX_VACATION_PROCESSOR.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Automation Orchestrator", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_AUTOMATION_ORCHESTRATOR.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Dynamic Routing", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_DYNAMIC_ROUTING.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Process Optimizer", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_PROCESS_OPTIMIZER.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")
```

### Batch 2: Core Algorithms (6 subagents)
```python
Task(description="Fix Erlang C Enhanced", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_FIX_ERLANG_C_ENHANCED.md completely. Use forecast_historical_data table. Test with real data.")

Task(description="Fix Multi Skill Allocation", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_MULTI_SKILL_ALLOCATION.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Real Time Erlang", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_REAL_TIME_ERLANG_C.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")

Task(description="Fix Shift Optimization", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_SHIFT_OPTIMIZATION.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")
```

### Batch 3: Mobile & Location (5 subagents)
```python
Task(description="Fix Geofencing Routing", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_GEOFENCING_ROUTING.md completely. Use sites table with lat/lon. Test with real data.")

Task(description="Fix Location Optimization", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_LOCATION_OPTIMIZATION.md completely. Apply Mobile Workforce Scheduler fix pattern. Test with real data.")
```

### Batch 4: Analytics & ML (4 subagents)
```python
Task(description="Fix Auto Learning", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_AUTO_LEARNING_COEFFICIENTS.md completely. Remove all random values. Test with real data.")

Task(description="Fix Forecast Accuracy", 
     prompt="Execute /Users/m/Documents/wfm/main/project/subagent_tasks/algorithm_fixes/SUBAGENT_FORECAST_ACCURACY_METRICS.md completely. Use forecast_historical_data. Test with real data.")
```

## 🎯 Success Metrics to Monitor

### Per Algorithm:
- ✅ Finds real data (not 0 results)
- ✅ No mock/random values in code
- ✅ Performance meets BDD specs
- ✅ Tests pass with real database

### Overall Progress:
- **Start**: 33/90 algorithms real (36.7%)
- **Target**: 90/90 algorithms real (100%)
- **Quality**: Zero mock data remaining

## 📊 Verification Commands

```bash
# Check for remaining mock data
grep -r "mock\|fake\|random\.uniform" src/algorithms/ | grep -v _real | wc -l

# Count fixed algorithms
find src/algorithms -name "*_real.py" | wc -l

# Test all algorithms
python -m pytest tests/algorithms/ -v
```

## 🚨 Critical Success Factors

1. **Database First**: Every algorithm must connect to PostgreSQL
2. **Real Data Only**: No mock generators or random values
3. **BDD Compliance**: Meet performance requirements
4. **Test Coverage**: All algorithms must have working tests

## 📋 Subagent Instructions Template

Each subagent should:
1. Read their specific task file completely
2. Apply the Mobile Workforce Scheduler fix pattern
3. Find and use real database tables
4. Test with actual business data
5. Verify performance requirements
6. Create *_real.py version if needed

Ready to launch mass algorithm fix! 🚀