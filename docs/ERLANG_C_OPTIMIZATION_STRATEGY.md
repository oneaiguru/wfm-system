# Erlang C Optimization Strategy

## Current Performance Issue
- **Current**: 415ms average response time
- **Target**: <100ms
- **Gap**: 315ms reduction needed

## Root Cause Analysis

### 1. Current Bottlenecks
From the API service implementation:
```python
# Current flow in algorithm_service.py
1. Database query for service channels (~50ms)
2. Calculate for each channel separately (~100ms each)
3. Multi-channel optimization (~50ms)
4. Result aggregation (~15ms)
```

### 2. Algorithm Complexity
The Enhanced Erlang C implementation includes:
- Factorial calculations (cached but still computed)
- Iterative staffing search (up to 100 iterations)
- Service level corridor calculations
- Conservative safety margins

## Optimization Strategies

### Strategy 1: Result Caching (Quick Win)
**Estimated Impact**: 200-300ms reduction

```python
# Add to erlang_c_enhanced.py
class ErlangCEnhanced:
    def __init__(self, cache_size: int = 1000):
        self.cache_size = cache_size
        self._result_cache = TTLCache(max_size=10000, ttl=3600)
    
    def calculate_service_level_staffing(self, lambda_rate, mu_rate, target_sl):
        # Create cache key
        cache_key = f"{lambda_rate}_{mu_rate}_{target_sl}"
        
        # Check cache first
        cached = self._result_cache.get(cache_key)
        if cached:
            return cached
        
        # Existing calculation...
        result = self._calculate_actual(lambda_rate, mu_rate, target_sl)
        
        # Cache result
        self._result_cache.put(cache_key, result)
        return result
```

### Strategy 2: Pre-computation Tables
**Estimated Impact**: 300-350ms reduction

```python
# Pre-compute common scenarios
ERLANG_C_LOOKUP_TABLE = {}

def build_lookup_tables():
    """Pre-compute common contact center scenarios"""
    # Common arrival rates (calls/hour)
    lambda_rates = [50, 100, 200, 300, 400, 500, 750, 1000, 1500, 2000]
    
    # Common service rates (calls/hour/agent)
    mu_rates = [10, 12, 15, 20, 25, 30]
    
    # Standard service levels
    service_levels = [0.70, 0.75, 0.80, 0.85, 0.90, 0.95]
    
    for lambda_r in lambda_rates:
        for mu_r in mu_rates:
            for sl in service_levels:
                key = (lambda_r, mu_r, sl)
                agents, achieved_sl = calculate_exact(lambda_r, mu_r, sl)
                ERLANG_C_LOOKUP_TABLE[key] = (agents, achieved_sl)

def get_staffing_fast(lambda_rate, mu_rate, target_sl):
    """Get staffing with interpolation from lookup table"""
    # Find nearest values
    key = find_nearest_key(lambda_rate, mu_rate, target_sl)
    
    if key in ERLANG_C_LOOKUP_TABLE:
        return ERLANG_C_LOOKUP_TABLE[key]
    
    # Interpolate between nearest values
    return interpolate_staffing(lambda_rate, mu_rate, target_sl)
```

### Strategy 3: Algorithmic Optimization
**Estimated Impact**: 100-150ms reduction

```python
# Optimize the staffing search
def calculate_service_level_staffing_optimized(self, lambda_rate, mu_rate, target_sl):
    offered_load = lambda_rate / mu_rate
    
    # Better starting point using square root staffing rule
    sqrt_staffing = offered_load + 3 * math.sqrt(offered_load)
    start_agents = max(int(offered_load * 1.05), int(sqrt_staffing))
    
    # Binary search instead of linear
    low = start_agents
    high = start_agents * 2
    
    while low < high:
        mid = (low + high) // 2
        utilization = offered_load / mid
        
        if utilization >= 0.99:
            low = mid + 1
            continue
            
        achieved_sl = self._calculate_service_level_fast(mid, lambda_rate, mu_rate)
        
        if achieved_sl >= target_sl:
            high = mid
        else:
            low = mid + 1
    
    return low, self._calculate_service_level_fast(low, lambda_rate, mu_rate)
```

### Strategy 4: Parallel Processing
**Estimated Impact**: 50-100ms reduction for multi-channel

```python
# Parallelize multi-channel calculations
async def calculate_multi_channel_parallel(self, channels, calls, aht, target_sl):
    tasks = []
    
    for channel in channels:
        task = asyncio.create_task(
            self._calculate_single_channel_async(
                channel, calls, aht, target_sl
            )
        )
        tasks.append(task)
    
    results = await asyncio.gather(*tasks)
    return self._aggregate_results(results)
```

### Strategy 5: Numba JIT Compilation
**Estimated Impact**: 50-100ms reduction

```python
from numba import jit

@jit(nopython=True)
def erlang_c_probability_jit(s: int, lambda_rate: float, mu_rate: float) -> float:
    """JIT-compiled Erlang C probability calculation"""
    # Optimized calculation without Python overhead
    # Implementation details...
```

## Implementation Plan

### Phase 1: Quick Wins (1-2 days)
1. Implement result caching (Strategy 1)
2. Add request-level caching in API
3. Expected improvement: 200-300ms

### Phase 2: Lookup Tables (2-3 days)
1. Build pre-computation tables
2. Implement interpolation logic
3. Expected improvement: 300-350ms (cumulative: <100ms target achieved)

### Phase 3: Advanced Optimization (Optional, 3-5 days)
1. Binary search algorithm
2. Parallel processing for multi-channel
3. Numba JIT compilation
4. Expected improvement: Additional 100-200ms

## Testing Strategy

### Performance Benchmarks
```python
# Create performance test suite
def benchmark_erlang_c():
    test_cases = [
        # (lambda, mu, target_sl, expected_time_ms)
        (100, 20, 0.80, 100),
        (500, 30, 0.85, 100),
        (1000, 40, 0.90, 100),
        (2000, 50, 0.80, 100),
    ]
    
    for lambda_r, mu_r, sl, expected in test_cases:
        start = time.perf_counter()
        result = calculator.calculate_service_level_staffing(lambda_r, mu_r, sl)
        elapsed = (time.perf_counter() - start) * 1000
        
        assert elapsed < expected, f"Too slow: {elapsed}ms > {expected}ms"
```

### Accuracy Validation
- Ensure optimizations don't change results
- Compare with current implementation
- Maintain conservative staffing approach

## Caching Architecture

### Level 1: Result Cache (Application)
```python
# In-memory cache for algorithm results
result_cache = TTLCache(max_size=10000, ttl=3600)  # 1 hour TTL
```

### Level 2: API Response Cache
```python
# FastAPI response caching
@cache_decorator(expire=300)  # 5 minutes
async def calculate_erlang_c(request: ErlangCRequest):
    # Implementation
```

### Level 3: Database Query Cache
```python
# Cache service configuration queries
service_config_cache = TTLCache(max_size=1000, ttl=600)  # 10 minutes
```

### Cache Invalidation Strategy
1. Time-based expiration (TTL)
2. Event-based invalidation (config changes)
3. Memory pressure eviction (LRU)

## Expected Outcomes

### Performance Targets
- **Phase 1**: 415ms → 150ms (64% improvement)
- **Phase 2**: 150ms → 50ms (88% improvement)
- **Phase 3**: 50ms → 25ms (94% improvement)

### Business Impact
1. Better user experience
2. Higher throughput capability
3. Reduced server costs
4. Competitive advantage

## Next Steps
1. Implement result caching immediately
2. Build lookup tables for common scenarios
3. Test with production-like workloads
4. Monitor cache hit rates
5. Fine-tune cache parameters