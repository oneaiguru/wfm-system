"""
Algorithm Performance Test Suite - Using Actual API
Tests algorithms through their actual interfaces
"""
import time
import statistics
from typing import List, Dict, Any
import sys
import os
import json

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

# Import our algorithms
from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from src.algorithms.optimization.performance_optimization import TTLCache
from src.algorithms.validation.validation_framework import ValidationMetrics


class ActualPerformanceTestSuite:
    """Test suite using actual algorithm APIs"""
    
    def __init__(self):
        self.results = {}
        self.targets = {
            'erlang_c': 100,  # ms
            'cache_hit_rate': 80  # %
        }
    
    def run_tests(self):
        """Run performance tests"""
        print("🚀 Starting Algorithm Performance Test Suite")
        print("=" * 60)
        
        # Test 1: Erlang C Performance
        self.test_erlang_c_performance()
        
        # Test 2: Cache Performance
        self.test_cache_performance()
        
        # Test 3: Validation Framework Performance
        self.test_validation_performance()
        
        # Report results
        self.generate_report()
    
    def test_erlang_c_performance(self):
        """Test Erlang C calculator performance"""
        print("\n📊 Testing Erlang C Performance...")
        
        calculator = ErlangCEnhanced()
        test_cases = [
            {'lambda_rate': 100, 'mu_rate': 20, 'target_sl': 0.8},
            {'lambda_rate': 500, 'mu_rate': 30, 'target_sl': 0.85},
            {'lambda_rate': 1000, 'mu_rate': 40, 'target_sl': 0.9},
            {'lambda_rate': 2000, 'mu_rate': 50, 'target_sl': 0.8}
        ]
        
        times = []
        for case in test_cases:
            # Warm up
            calculator.calculate_service_level_staffing(
                case['lambda_rate'], 
                case['mu_rate'], 
                case['target_sl']
            )
            
            # Actual test
            start = time.perf_counter()
            agents, achieved_sl = calculator.calculate_service_level_staffing(
                case['lambda_rate'], 
                case['mu_rate'], 
                case['target_sl']
            )
            end = time.perf_counter()
            elapsed_ms = (end - start) * 1000
            times.append(elapsed_ms)
            
            utilization = calculator.calculate_utilization(
                case['lambda_rate'], 
                agents, 
                case['mu_rate']
            )
            
            print(f"  - λ={case['lambda_rate']}, μ={case['mu_rate']}: {elapsed_ms:.2f}ms")
            print(f"    Agents: {agents}, SL: {achieved_sl:.2%}, Util: {utilization:.2%}")
        
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
    
    def test_cache_performance(self):
        """Test cache hit rate and performance"""
        print("\n💾 Testing Cache Performance...")
        
        cache = TTLCache(max_size=1000, ttl=300)
        
        # Simulate realistic cache usage
        keys = [f"calc_{i}" for i in range(100)]
        values = [{'result': i * 100} for i in range(100)]
        
        # First pass - all misses
        miss_times = []
        for key, value in zip(keys, values):
            start = time.perf_counter()
            cache.get(key)  # Miss
            cache.put(key, value)
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
        
        # Get cache stats
        stats = cache.stats
        
        self.results['cache'] = {
            'hit_rate': hit_rate,
            'target_hit_rate': self.targets['cache_hit_rate'],
            'avg_hit_time_ms': avg_hit_time,
            'avg_miss_time_ms': avg_miss_time,
            'passed': hit_rate > self.targets['cache_hit_rate'],
            'total_hits': stats.hits,
            'total_misses': stats.misses,
            'items_in_cache': len(cache.cache)
        }
        
        print(f"  ✅ Hit rate: {hit_rate:.1f}%, Hit time: {avg_hit_time:.3f}ms")
        print(f"     Cache stats: {stats.hits} hits, {stats.misses} misses, {len(cache.cache)} items")
    
    def test_validation_performance(self):
        """Test validation framework performance"""
        print("\n✔️  Testing Validation Framework Performance...")
        
        # Generate test predictions
        import numpy as np
        actual = np.array([100 + i % 50 for i in range(1000)])
        predicted = np.array([actual[i] + (i % 10 - 5) for i in range(1000)])
        
        times = []
        mfa_list = []
        mape_list = []
        
        for i in range(10):
            start = time.perf_counter()
            mape = ValidationMetrics.mean_absolute_percentage_error(actual, predicted)
            mfa = 100 - mape  # Mean Forecast Accuracy = 100 - MAPE
            end = time.perf_counter()
            elapsed_ms = (end - start) * 1000
            times.append(elapsed_ms)
            mfa_list.append(mfa)
            mape_list.append(mape)
        
        avg_time = statistics.mean(times)
        avg_mfa = statistics.mean(mfa_list)
        avg_mape = statistics.mean(mape_list)
        
        self.results['validation'] = {
            'average_ms': avg_time,
            'avg_mfa': avg_mfa,
            'avg_mape': avg_mape,
            'times': times
        }
        
        print(f"  ✅ Average: {avg_time:.2f}ms, MFA: {avg_mfa:.2f}%, MAPE: {avg_mape:.2f}%")
    
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
        print(f"   Total Hits: {cache_result.get('total_hits', 0)}")
        print(f"   Total Misses: {cache_result.get('total_misses', 0)}")
        all_passed &= cache_result.get('passed', False)
        
        # Validation Results
        val_result = self.results.get('validation', {})
        print(f"\n3. Validation Framework:")
        print(f"   Average Time: {val_result.get('average_ms', 0):.2f}ms")
        print(f"   MFA: {val_result.get('avg_mfa', 0):.2f}%")
        print(f"   MAPE: {val_result.get('avg_mape', 0):.2f}%")
        
        # Summary
        print("\n" + "=" * 60)
        overall_status = "✅ ALL TESTS PASSED" if all_passed else "❌ SOME TESTS FAILED"
        print(f"OVERALL RESULT: {overall_status}")
        print("=" * 60)
        
        # Save detailed results
        self.save_results()
    
    def save_results(self):
        """Save detailed results to file"""
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        filename = f'/Users/m/Documents/wfm/WFM_Enterprise/main/project/tests/algorithms/performance_results_{timestamp}.json'
        
        with open(filename, 'w') as f:
            json.dump({
                'timestamp': timestamp,
                'targets': self.targets,
                'results': self.results
            }, f, indent=2)
        
        print(f"\n📄 Detailed results saved to performance_results_{timestamp}.json")


def main():
    """Run performance test suite"""
    suite = ActualPerformanceTestSuite()
    suite.run_tests()


if __name__ == "__main__":
    main()