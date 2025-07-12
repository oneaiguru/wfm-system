#!/usr/bin/env python3
"""
Quick benchmark script to test Erlang C performance improvements.

This script provides a quick way to verify that our optimizations
achieve the <100ms target for Erlang C calculations.
"""

import sys
import time
import statistics
from pathlib import Path
from typing import List, Tuple

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from src.algorithms.optimization.erlang_c_cache import ErlangCCache, CachedErlangCEnhanced


def benchmark_scenario(calculator, lambda_rate: float, mu_rate: float, 
                      target_sl: float, iterations: int = 10) -> Tuple[float, float]:
    """Benchmark a single scenario."""
    times = []
    
    for _ in range(iterations):
        start = time.time()
        result = calculator.calculate_service_level_staffing(lambda_rate, mu_rate, target_sl)
        elapsed = (time.time() - start) * 1000  # Convert to ms
        times.append(elapsed)
    
    return statistics.mean(times), statistics.stdev(times) if len(times) > 1 else 0


def run_quick_benchmark():
    """Run a quick performance benchmark."""
    print("Erlang C Performance Benchmark")
    print("=" * 50)
    
    # Initialize calculators
    base_calc = ErlangCEnhanced()
    cache = ErlangCCache(max_size=10000, ttl=3600)
    cached_calc = CachedErlangCEnhanced(base_calc, cache)
    
    # Ensure pre-computed scenarios are loaded
    print("Loading pre-computed scenarios...")
    cache.ensure_precomputed_scenarios_exist()
    print(f"Loaded {len(cache.lookup_tables)} pre-computed scenarios\n")
    
    # Test scenarios
    scenarios = [
        # (calls/hour, aht_seconds, service_level, description)
        (100, 180, 0.80, "Small center, standard"),
        (500, 240, 0.85, "Medium center, standard"),
        (1000, 300, 0.90, "Large center, standard"),
        (2500, 360, 0.80, "Very large center"),
        (123, 234, 0.83, "Random values"),
    ]
    
    print("Testing scenarios:")
    print("-" * 80)
    print(f"{'Scenario':<30} {'Base (ms)':<15} {'Cached (ms)':<15} {'Speedup':<10} {'Status'}")
    print("-" * 80)
    
    for calls, aht, sl, desc in scenarios:
        mu_rate = 3600 / aht
        
        # Test base implementation
        base_mean, base_std = benchmark_scenario(base_calc, calls, mu_rate, sl)
        
        # Clear cache for first call
        cache.cache.clear()
        
        # First cached call (miss)
        cached_first, _ = benchmark_scenario(cached_calc, calls, mu_rate, sl, iterations=1)
        
        # Subsequent cached calls (hit)
        cached_mean, cached_std = benchmark_scenario(cached_calc, calls, mu_rate, sl)
        
        # Calculate speedup
        speedup = base_mean / cached_mean if cached_mean > 0 else 0
        
        # Status
        status = "✅ PASS" if cached_mean < 100 else "❌ FAIL"
        
        print(f"{desc:<30} {base_mean:>8.2f}±{base_std:<4.1f} "
              f"{cached_mean:>8.2f}±{cached_std:<4.1f} {speedup:>8.1f}x     {status}")
    
    # Cache statistics
    stats = cache.get_stats()
    print("\n" + "-" * 80)
    print("Cache Statistics:")
    print(f"  Hit Rate: {stats['hit_rate']:.1f}%")
    print(f"  Total Requests: {stats['total_requests']}")
    print(f"  Time Saved: {stats['time_saved']:.2f} seconds")
    
    # Overall performance
    print("\n" + "=" * 50)
    print("PERFORMANCE SUMMARY")
    print("=" * 50)
    
    # Test 100 random scenarios for overall statistics
    print("\nTesting 100 random scenarios...")
    import random
    random.seed(42)
    
    all_times = []
    for _ in range(100):
        calls = random.randint(50, 2000)
        aht = random.randint(120, 480)
        sl = random.uniform(0.70, 0.95)
        mu_rate = 3600 / aht
        
        start = time.time()
        cached_calc.calculate_service_level_staffing(calls, mu_rate, sl)
        elapsed = (time.time() - start) * 1000
        all_times.append(elapsed)
    
    # Calculate percentiles
    all_times.sort()
    p50 = all_times[49]
    p95 = all_times[94]
    p99 = all_times[98]
    
    print(f"\nResponse Time Percentiles:")
    print(f"  P50 (Median): {p50:.2f}ms")
    print(f"  P95: {p95:.2f}ms")
    print(f"  P99: {p99:.2f}ms")
    print(f"  Max: {max(all_times):.2f}ms")
    
    if p95 < 100:
        print("\n✅ SUCCESS: Erlang C achieves <100ms target (P95)!")
    else:
        print("\n❌ FAILURE: Erlang C does not meet <100ms target")
        print(f"   Current P95: {p95:.2f}ms (Target: <100ms)")


if __name__ == "__main__":
    run_quick_benchmark()