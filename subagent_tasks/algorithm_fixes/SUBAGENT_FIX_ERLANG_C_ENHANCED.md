# 📋 SUBAGENT TASK: Fix Enhanced Erlang C

## 🎯 Task Information
- **Task ID**: FIX_ERLANG_C_ENHANCED
- **File**: src/algorithms/core/erlang_c_enhanced.py
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- Uses mock call volume data
- Generates random service levels
- No connection to real historical data

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\dt" | grep -E "(call|contact|forecast|historical)"
   ```
2. **Check Forecast Tables**: Look for forecast_historical_data (proven to exist)
3. **Map to Real Schema**: 
   - forecast_historical_data (call volumes)
   - service_level_targets (SLA requirements)
   - contact_statistics (actual performance)
4. **Test with Real Data**: Verify calculates from real call data
5. **Performance**: Must complete <100ms per calculation (BDD requirement)

## 📊 Expected Real Tables to Use
- forecast_historical_data (proven in Gap Analysis)
- forecast_results
- service_level_configurations
- contact_center_metrics
- channel_statistics

## ✅ Success Criteria
- [ ] Uses real historical call volume data
- [ ] No random.uniform() or mock generators
- [ ] Calculates real staffing requirements
- [ ] Performance <100ms per calculation
- [ ] Results align with business reality

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
erlang = ErlangCEnhanced()

# Test with real forecast data
result = erlang.calculate_staffing(
    date='2024-07-15',
    interval='15min',
    service_level_target=0.8,
    target_time_seconds=20
)
assert result['required_agents'] > 0  # Real calculation
assert result['call_volume'] > 0  # From real data
assert result['calculation_time_ms'] < 100  # Performance requirement
print(f"Calculated {result['required_agents']} agents for {result['call_volume']} calls")
```

## 🔍 Common Issues to Fix
1. Replace mock call volume generator with forecast_historical_data query
2. Remove all random.uniform() calls
3. Connect to real service level configurations
4. Use actual shrinkage/utilization from database
5. Apply real multi-skill considerations

## 📋 BDD Compliance
- File: 08-load-forecasting-demand-planning.feature
- Enhanced Erlang C with service level corridors
- Multi-channel support required
- Real-time adaptation capability