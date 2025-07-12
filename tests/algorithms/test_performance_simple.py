"""
Simplified Algorithm Performance Test Suite
Tests core algorithms without complex dependencies
"""
import asyncio
import time
import statistics
from typing import List, Dict, Any
from datetime import datetime, timedelta
import sys
import os
import json

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

# Import our algorithms
from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from src.algorithms.optimization.performance_optimization import TTLCache
from src.algorithms.validation.validation_framework import ValidationFramework


class SimplePerformanceTestSuite:
    """Simplified test suite for algorithm performance validation"""
    
    def __init__(self):
        self.results = {}
        self.targets = {
            'erlang_c': 100,  # ms
            'cache_hit_rate': 80  # %
        }
    
    async def run_tests(self):
        """Run performance tests"""
        print("🚀 Starting Algorithm Performance Test Suite (Simplified)")
        print("=" * 60)
        
        # Test 1: Erlang C Performance
        await self.test_erlang_c_performance()
        
        # Test 2: Cache Performance
        await self.test_cache_performance()
        
        # Test 3: Validation Framework Performance
        await self.test_validation_performance()
        
        # Report results
        self.generate_report()
    
    async def test_erlang_c_performance(self):
        """Test Erlang C calculator performance"""
        print("\n📊 Testing Erlang C Performance...")
        
        calculator = ErlangCEnhanced()
        test_cases = [
            {'lambda_rate': 100, 'mu_rate': 20, 'num_agents': 10},
            {'lambda_rate': 500, 'mu_rate': 30, 'num_agents': 25},
            {'lambda_rate': 1000, 'mu_rate': 40, 'num_agents': 50},
            {'lambda_rate': 2000, 'mu_rate': 50, 'num_agents': 100}
        ]
        
        times = []
        for case in test_cases:
            # Warm up
            calculator.calculate_metrics(**case)
            
            # Actual test
            start = time.perf_counter()
            result = calculator.calculate_metrics(**case)
            end = time.perf_counter()
            elapsed_ms = (end - start) * 1000
            times.append(elapsed_ms)
            print(f"  - Test case {case['num_agents']} agents: {elapsed_ms:.2f}ms")
            print(f"    Service Level: {result.get('service_level', 0):.2%}")
        
        avg_time = statistics.mean(times)
        max_time = max(times)
        self.results['erlang_c'] = {
            'average_ms': avg_time,
            'max_ms': max_time,
            'target_ms': self.targets['erlang_c'],
            'passed': max_time < self.targets['erlang_c'],
            'times': times
        }
        
        print(f"  ✅ Average: {avg_time:.2f}ms, Max: {max_time:.2f}ms")
    
    async def test_cache_performance(self):
        """Test cache hit rate and performance"""
        print("\n💾 Testing Cache Performance...")
        
        cache = TTLCache(ttl_seconds=300, max_size=1000)
        
        # Simulate realistic cache usage
        keys = [f"calc_{i}" for i in range(100)]
        values = [{'result': i * 100} for i in range(100)]
        
        # First pass - all misses
        miss_times = []
        for key, value in zip(keys, values):
            start = time.perf_counter()
            cache.get(key)  # Miss
            cache.set(key, value)
            end = time.perf_counter()
            miss_times.append((end - start) * 1000)
        
        # Second pass - all hits
        hit_times = []
        hits = 0
        total_accesses = 0
        
        for _ in range(5):  # Multiple access rounds
            for key in keys:
                start = time.perf_counter()
                result = cache.get(key)
                end = time.perf_counter()
                hit_times.append((end - start) * 1000)
                total_accesses += 1
                if result is not None:
                    hits += 1
        
        hit_rate = (hits / total_accesses) * 100
        avg_hit_time = statistics.mean(hit_times)
        avg_miss_time = statistics.mean(miss_times)
        
        self.results['cache'] = {
            'hit_rate': hit_rate,
            'target_hit_rate': self.targets['cache_hit_rate'],
            'avg_hit_time_ms': avg_hit_time,
            'avg_miss_time_ms': avg_miss_time,
            'passed': hit_rate > self.targets['cache_hit_rate']
        }
        
        print(f"  ✅ Hit rate: {hit_rate:.1f}%, Hit time: {avg_hit_time:.3f}ms")
    
    async def test_validation_performance(self):
        """Test validation framework performance"""
        print("\n✔️  Testing Validation Framework Performance...")
        
        validator = ValidationFramework()
        
        # Generate test predictions
        actual = [100 + i % 50 for i in range(1000)]
        predicted = [actual[i] + (i % 10 - 5) for i in range(1000)]
        
        times = []
        metrics_list = []
        
        for i in range(10):
            start = time.perf_counter()
            metrics = validator.calculate_metrics(actual, predicted)
            end = time.perf_counter()
            elapsed_ms = (end - start) * 1000
            times.append(elapsed_ms)
            metrics_list.append(metrics)
        
        avg_time = statistics.mean(times)
        avg_mfa = statistics.mean([m['mean_forecast_accuracy'] for m in metrics_list])
        
        self.results['validation'] = {
            'average_ms': avg_time,
            'avg_mfa': avg_mfa,
            'times': times
        }
        
        print(f"  ✅ Average: {avg_time:.2f}ms, MFA: {avg_mfa:.2f}%")
    
    def generate_report(self):
        """Generate performance test report"""
        print("\n" + "=" * 60)
        print("📈 PERFORMANCE TEST REPORT")
        print("=" * 60)
        
        all_passed = True
        
        # Erlang C Results
        erlang_result = self.results.get('erlang_c', {})
        status = "✅ PASS" if erlang_result.get('passed', False) else "❌ FAIL"
        print(f"\n1. Erlang C Performance: {status}")
        print(f"   Target: <{self.targets['erlang_c']}ms")
        print(f"   Average: {erlang_result.get('average_ms', 0):.2f}ms")
        print(f"   Maximum: {erlang_result.get('max_ms', 0):.2f}ms")
        all_passed &= erlang_result.get('passed', False)
        
        # Cache Results
        cache_result = self.results.get('cache', {})
        status = "✅ PASS" if cache_result.get('passed', False) else "❌ FAIL"
        print(f"\n2. Cache Performance: {status}")
        print(f"   Target Hit Rate: >{self.targets['cache_hit_rate']}%")
        print(f"   Actual Hit Rate: {cache_result.get('hit_rate', 0):.1f}%")
        print(f"   Hit Time: {cache_result.get('avg_hit_time_ms', 0):.3f}ms")
        all_passed &= cache_result.get('passed', False)
        
        # Validation Results
        val_result = self.results.get('validation', {})
        print(f"\n3. Validation Framework:")
        print(f"   Average Time: {val_result.get('average_ms', 0):.2f}ms")
        print(f"   MFA: {val_result.get('avg_mfa', 0):.2f}%")
        
        # Summary
        print("\n" + "=" * 60)
        overall_status = "✅ ALL TESTS PASSED" if all_passed else "❌ SOME TESTS FAILED"
        print(f"OVERALL RESULT: {overall_status}")
        print("=" * 60)
        
        # Save detailed results
        self.save_results()
    
    def save_results(self):
        """Save detailed results to file"""
        with open('/Users/m/Documents/wfm/WFM_Enterprise/main/project/tests/algorithms/performance_results.json', 'w') as f:
            json.dump(self.results, f, indent=2)
        
        print(f"\n📄 Detailed results saved to performance_results.json")


async def main():
    """Run performance test suite"""
    suite = SimplePerformanceTestSuite()
    await suite.run_tests()


if __name__ == "__main__":
    asyncio.run(main())