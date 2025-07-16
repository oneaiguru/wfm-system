# 📋 SUBAGENT TASK: Fix Coverage Analyzer

## 🎯 Task Information
- **Task ID**: FIX_COVERAGE_ANALYZER
- **File**: src/algorithms/intraday/coverage_analyzer.py
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- Simulated coverage gaps
- Returns mock/simulated data
- No real database connection

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\dt" | grep -E "(coverage|gap|staffing|requirement)"
   ```
2. **Check Current Queries**: Analyze algorithm's database access
3. **Map to Real Schema**: Update to use actual tables/columns
4. **Test with Real Data**: Verify processes real business data
5. **Performance Check**: Meet BDD timing requirements

## 📊 Expected Real Tables to Use
- coverage_requirements
- staffing_actuals
- coverage_gaps
- intraday_forecasts

## ✅ Success Criteria
- [ ] Uses real database data only
- [ ] No mock data or random values
- [ ] Realistic business results
- [ ] Meets BDD performance requirements
- [ ] All tests pass

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.intraday/coverage_analyzer.py import CoverageAnalyzer
algorithm = CoverageAnalyzer()
result = algorithm.analyze_coverage()
assert len(result) > 0  # Should process real data
print(f"Processed {len(result)} real records")
```

## 🔍 Common Issues to Fix
1. Replace mock data generators with real queries
2. Fix table/column names to match actual schema
3. Remove all random.uniform() calls
4. Connect to real business data
5. Verify performance meets BDD specs
