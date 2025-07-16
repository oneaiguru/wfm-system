# 📋 SUBAGENT TASK: Fix Geofencing Routing

## 🎯 Task Information
- **Task ID**: FIX_GEOFENCING_ROUTING
- **File**: src/algorithms/mobile/geofencing_routing.py
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- Simulated GPS and geofence data
- Returns mock/simulated data
- No real database connection

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\dt" | grep -E "(location|geofence|zone|territory)"
   ```
2. **Check Current Queries**: Analyze algorithm's database access
3. **Map to Real Schema**: Update to use actual tables/columns
4. **Test with Real Data**: Verify processes real business data
5. **Performance Check**: Meet BDD timing requirements

## 📊 Expected Real Tables to Use
- geofence_definitions
- location_zones
- territory_assignments
- sites (with lat/lon)

## ✅ Success Criteria
- [ ] Uses real database data only
- [ ] No mock data or random values
- [ ] Realistic business results
- [ ] Meets BDD performance requirements
- [ ] All tests pass

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.mobile/geofencing_routing.py import GeofencingRouter
algorithm = GeofencingRouter()
result = algorithm.route_by_location()
assert len(result) > 0  # Should process real data
print(f"Processed {len(result)} real records")
```

## 🔍 Common Issues to Fix
1. Replace mock data generators with real queries
2. Fix table/column names to match actual schema
3. Remove all random.uniform() calls
4. Connect to real business data
5. Verify performance meets BDD specs
