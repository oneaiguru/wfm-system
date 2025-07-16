#!/usr/bin/env python3
"""
Test script to verify Erlang C cache integration with pre-computed scenarios
"""

import time
import logging
from erlang_c_cache import ErlangCCache
from erlang_c_enhanced import ErlangCEnhanced, CachedErlangCEnhanced

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def test_cache_performance():
    """Test cache performance with pre-computed scenarios"""
    print("\n" + "="*80)
    print("Erlang C Cache Performance Test with Pre-computed Scenarios")
    print("="*80)
    
    # Create cache instance
    cache = ErlangCCache(max_size=10000, ttl=3600)
    
    # Ensure pre-computed scenarios exist
    print("\n1. Checking for pre-computed scenarios...")
    if not cache.lookup_tables:
        print("   No pre-computed scenarios found. Generating...")
        cache.ensure_precomputed_scenarios_exist()
    else:
        print(f"   Found {len(cache.lookup_tables)} pre-computed scenarios")
    
    # Wait a moment for background loading if needed
    time.sleep(2)
    
    print(f"\n2. Loaded {len(cache.lookup_tables)} pre-computed scenarios")
    
    # Test scenarios from the standard 3,780 scenarios
    test_scenarios = [
        # (call_volume, aht_seconds, service_level, expected_response_time_ms)
        (100, 180, 0.80, 100),    # 100 calls/hour, 3min AHT, 80% SL
        (500, 240, 0.85, 100),    # 500 calls/hour, 4min AHT, 85% SL
        (1000, 300, 0.90, 100),   # 1000 calls/hour, 5min AHT, 90% SL
        (2000, 180, 0.85, 100),   # 2000 calls/hour, 3min AHT, 85% SL
        (5000, 120, 0.90, 100),   # 5000 calls/hour, 2min AHT, 90% SL
        # Repeat some scenarios to test exact cache
        (100, 180, 0.80, 10),     # Should hit exact cache
        (500, 240, 0.85, 10),     # Should hit exact cache
    ]
    
    print("\n3. Testing cache performance:")
    print("-" * 80)
    print(f"{'Scenario':<40} {'Result':<25} {'Time (ms)':<10} {'Status'}")
    print("-" * 80)
    
    total_time = 0
    hits = 0
    
    for call_volume, aht_seconds, service_level, max_time_ms in test_scenarios:
        # Convert to lambda and mu rates
        lambda_rate = call_volume  # calls per hour
        mu_rate = 3600 / aht_seconds  # service rate per hour
        
        # Time the cache lookup
        start_time = time.perf_counter()
        result = cache.get(lambda_rate, mu_rate, service_level)
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        total_time += elapsed_ms
        
        # Format scenario description
        scenario_desc = f"λ={call_volume}, AHT={aht_seconds}s, SL={service_level:.0%}"
        
        if result:
            hits += 1
            agents, achieved_sl = result
            result_str = f"Agents={agents}, SL={achieved_sl:.1%}"
            status = "✓ PASS" if elapsed_ms < max_time_ms else "✗ SLOW"
            print(f"{scenario_desc:<40} {result_str:<25} {elapsed_ms:>7.2f}ms  {status}")
        else:
            print(f"{scenario_desc:<40} {'CACHE MISS':<25} {elapsed_ms:>7.2f}ms  ✗ MISS")
    
    # Print summary statistics
    print("-" * 80)
    print("\n4. Performance Summary:")
    print(f"   - Total scenarios tested: {len(test_scenarios)}")
    print(f"   - Cache hits: {hits} ({hits/len(test_scenarios)*100:.1f}%)")
    print(f"   - Average response time: {total_time/len(test_scenarios):.2f}ms")
    print(f"   - Total test time: {total_time:.2f}ms")
    
    # Get and display cache statistics
    stats = cache.get_stats()
    print("\n5. Cache Statistics:")
    for key, value in stats.items():
        if isinstance(value, float):
            print(f"   - {key}: {value:.2f}")
        else:
            print(f"   - {key}: {value}")
    
    # Test with CachedErlangCEnhanced wrapper
    print("\n6. Testing CachedErlangCEnhanced wrapper:")
    base_calculator = ErlangCEnhanced()
    cached_calculator = CachedErlangCEnhanced(base_calculator, cache)
    
    # Test a scenario that might not be pre-computed
    print("   Testing edge case scenario...")
    start_time = time.perf_counter()
    agents, sl = cached_calculator.calculate_service_level_staffing(
        lambda_rate=123,  # Unusual call volume
        mu_rate=18.5,     # Unusual service rate
        target_sl=0.83    # Unusual service level
    )
    elapsed_ms = (time.perf_counter() - start_time) * 1000
    print(f"   Result: {agents} agents, {sl:.1%} SL (Time: {elapsed_ms:.2f}ms)")
    
    # Test the same scenario again (should be cached)
    start_time = time.perf_counter()
    agents2, sl2 = cached_calculator.calculate_service_level_staffing(
        lambda_rate=123,
        mu_rate=18.5,
        target_sl=0.83
    )
    elapsed_ms2 = (time.perf_counter() - start_time) * 1000
    print(f"   Cached: {agents2} agents, {sl2:.1%} SL (Time: {elapsed_ms2:.2f}ms)")
    print(f"   Speedup: {elapsed_ms/elapsed_ms2:.1f}x")
    
    print("\n" + "="*80)
    print("Test completed successfully!")
    print("="*80 + "\n")


if __name__ == "__main__":
    test_cache_performance()