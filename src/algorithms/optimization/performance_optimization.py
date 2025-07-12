"""
Performance optimization module for WFM algorithms.
Implements caching, vectorization, and parallel processing for enterprise-scale performance.
"""

import functools
import threading
import time
import numpy as np
from typing import Any, Callable, Dict, List, Optional, Tuple, Union
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from collections import OrderedDict
import weakref
import gc
import sys
import os


@dataclass
class CacheStats:
    """Cache performance statistics."""
    hits: int = 0
    misses: int = 0
    evictions: int = 0
    
    @property
    def hit_rate(self) -> float:
        """Calculate cache hit rate."""
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0


class TTLCache:
    """Thread-safe LRU cache with TTL support."""
    
    def __init__(self, max_size: int = 1000, ttl: int = 3600):
        self.max_size = max_size
        self.ttl = ttl
        self.cache = OrderedDict()
        self.timestamps = {}
        self.lock = threading.RLock()
        self.stats = CacheStats()
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        with self.lock:
            if key not in self.cache:
                self.stats.misses += 1
                return None
            
            # Check TTL
            if time.time() - self.timestamps[key] > self.ttl:
                del self.cache[key]
                del self.timestamps[key]
                self.stats.misses += 1
                return None
            
            # Move to end (most recently used)
            value = self.cache.pop(key)
            self.cache[key] = value
            self.stats.hits += 1
            return value
    
    def put(self, key: str, value: Any) -> None:
        """Put value in cache."""
        with self.lock:
            current_time = time.time()
            
            if key in self.cache:
                # Update existing
                self.cache.pop(key)
                self.cache[key] = value
                self.timestamps[key] = current_time
            else:
                # Add new
                if len(self.cache) >= self.max_size:
                    # Remove oldest
                    oldest_key = next(iter(self.cache))
                    del self.cache[oldest_key]
                    del self.timestamps[oldest_key]
                    self.stats.evictions += 1
                
                self.cache[key] = value
                self.timestamps[key] = current_time
    
    def clear(self) -> None:
        """Clear all cache entries."""
        with self.lock:
            self.cache.clear()
            self.timestamps.clear()
            self.stats = CacheStats()


class MemoryPool:
    """Memory pool for object reuse."""
    
    def __init__(self, factory: Callable, max_size: int = 100):
        self.factory = factory
        self.max_size = max_size
        self.pool = []
        self.lock = threading.Lock()
    
    def acquire(self):
        """Acquire object from pool."""
        with self.lock:
            if self.pool:
                return self.pool.pop()
            return self.factory()
    
    def release(self, obj):
        """Release object back to pool."""
        with self.lock:
            if len(self.pool) < self.max_size:
                # Reset object state if needed
                if hasattr(obj, 'reset'):
                    obj.reset()
                self.pool.append(obj)


class PerformanceProfiler:
    """Performance profiling decorator."""
    
    def __init__(self, name: str):
        self.name = name
        self.call_count = 0
        self.total_time = 0.0
        self.min_time = float('inf')
        self.max_time = 0.0
        self.lock = threading.Lock()
    
    def __call__(self, func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.perf_counter()
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                end_time = time.perf_counter()
                execution_time = end_time - start_time
                
                with self.lock:
                    self.call_count += 1
                    self.total_time += execution_time
                    self.min_time = min(self.min_time, execution_time)
                    self.max_time = max(self.max_time, execution_time)
        
        return wrapper
    
    def stats(self) -> Dict[str, float]:
        """Get performance statistics."""
        with self.lock:
            if self.call_count == 0:
                return {"calls": 0, "avg_time": 0.0, "min_time": 0.0, "max_time": 0.0}
            
            return {
                "calls": self.call_count,
                "avg_time": self.total_time / self.call_count,
                "min_time": self.min_time,
                "max_time": self.max_time,
                "total_time": self.total_time
            }


class CachedErlangC:
    """Cached Erlang C implementation."""
    
    def __init__(self):
        self.cache = TTLCache(max_size=10000, ttl=3600)
        self.profiler = PerformanceProfiler("erlang_c")
    
    def _cache_key(self, lambda_val: float, mu: float, s: int, service_level: float) -> str:
        """Generate cache key for Erlang C parameters."""
        return f"ec_{lambda_val:.3f}_{mu:.3f}_{s}_{service_level:.2f}"
    
    @PerformanceProfiler("erlang_c_single")
    def calculate(self, lambda_val: float, mu: float, s: int, service_level: float = 0.8) -> Dict[str, float]:
        """Calculate Erlang C with caching."""
        cache_key = self._cache_key(lambda_val, mu, service_level, s)
        
        # Check cache
        cached_result = self.cache.get(cache_key)
        if cached_result is not None:
            return cached_result
        
        # Calculate
        result = self._calculate_erlang_c(lambda_val, mu, s, service_level)
        
        # Cache result
        self.cache.put(cache_key, result)
        
        return result
    
    def _calculate_erlang_c(self, lambda_val: float, mu: float, s: int, service_level: float) -> Dict[str, float]:
        """Core Erlang C calculation."""
        rho = lambda_val / mu
        utilization = rho / s
        
        if utilization >= 1.0:
            return {
                "agents_required": s + 1,
                "utilization": utilization,
                "service_level": 0.0,
                "abandon_rate": 1.0
            }
        
        # Erlang C formula implementation
        erlang_c_num = (rho ** s) / np.math.factorial(s)
        erlang_c_den = sum((rho ** i) / np.math.factorial(i) for i in range(s))
        erlang_c_den += erlang_c_num / (1 - utilization)
        
        erlang_c = erlang_c_num / erlang_c_den
        
        # Service level calculation
        actual_service_level = 1 - erlang_c * np.exp(-s * (1 - utilization) * service_level)
        
        return {
            "agents_required": s,
            "utilization": utilization,
            "service_level": actual_service_level,
            "abandon_rate": 1 - actual_service_level
        }


class VectorizedOperations:
    """Vectorized algorithm operations using numpy."""
    
    @staticmethod
    @PerformanceProfiler("vectorized_erlang_c_batch")
    def erlang_c_batch(lambda_array: np.ndarray, mu_array: np.ndarray, s_array: np.ndarray) -> np.ndarray:
        """Vectorized Erlang C calculation for batch operations."""
        rho_array = lambda_array / mu_array
        utilization_array = rho_array / s_array
        
        # Vectorized calculation
        results = np.zeros((len(lambda_array), 4))  # agents, utilization, service_level, abandon_rate
        
        # Handle valid cases (utilization < 1.0)
        valid_mask = utilization_array < 1.0
        valid_rho = rho_array[valid_mask]
        valid_s = s_array[valid_mask]
        valid_util = utilization_array[valid_mask]
        
        # Simplified vectorized Erlang C approximation
        erlang_c_approx = valid_util ** valid_s / (1 - valid_util + valid_util ** valid_s)
        service_level_approx = 1 - erlang_c_approx * 0.5  # Simplified approximation
        
        results[valid_mask, 0] = valid_s
        results[valid_mask, 1] = valid_util
        results[valid_mask, 2] = service_level_approx
        results[valid_mask, 3] = 1 - service_level_approx
        
        # Handle invalid cases
        invalid_mask = ~valid_mask
        results[invalid_mask, 0] = s_array[invalid_mask] + 1
        results[invalid_mask, 1] = utilization_array[invalid_mask]
        results[invalid_mask, 2] = 0.0
        results[invalid_mask, 3] = 1.0
        
        return results
    
    @staticmethod
    @PerformanceProfiler("vectorized_skill_scoring")
    def skill_scoring_batch(agent_matrix: np.ndarray, skill_matrix: np.ndarray) -> np.ndarray:
        """Vectorized skill scoring for agent-queue matching."""
        # Matrix multiplication for skill scoring
        scores = np.dot(agent_matrix, skill_matrix.T)
        
        # Apply sigmoid normalization
        normalized_scores = 1 / (1 + np.exp(-scores))
        
        return normalized_scores


class ParallelProcessor:
    """Parallel processing manager."""
    
    def __init__(self, max_workers: Optional[int] = None):
        self.max_workers = max_workers or min(8, (os.cpu_count() or 1) + 4)
        self.executor = ThreadPoolExecutor(max_workers=self.max_workers)
    
    @PerformanceProfiler("parallel_forecast_generation")
    def parallel_forecast(self, data_chunks: List[np.ndarray], forecast_func: Callable) -> List[np.ndarray]:
        """Generate forecasts in parallel."""
        futures = []
        
        for chunk in data_chunks:
            future = self.executor.submit(forecast_func, chunk)
            futures.append(future)
        
        results = []
        for future in as_completed(futures):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                print(f"Forecast error: {e}")
                results.append(np.array([]))
        
        return results
    
    @PerformanceProfiler("parallel_skill_optimization")
    def parallel_skill_optimization(self, queue_segments: List[Dict], optimization_func: Callable) -> List[Dict]:
        """Optimize skill allocation in parallel."""
        futures = []
        
        for segment in queue_segments:
            future = self.executor.submit(optimization_func, segment)
            futures.append(future)
        
        results = []
        for future in as_completed(futures):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                print(f"Optimization error: {e}")
                results.append({})
        
        return results
    
    def shutdown(self):
        """Shutdown thread pool."""
        self.executor.shutdown(wait=True)


class PerformanceOptimizer:
    """Main performance optimization coordinator."""
    
    def __init__(self):
        self.cached_erlang_c = CachedErlangC()
        self.vectorized_ops = VectorizedOperations()
        self.parallel_processor = ParallelProcessor()
        self.memory_pools = {}
        self.profilers = {}
    
    def get_memory_pool(self, name: str, factory: Callable, max_size: int = 100) -> MemoryPool:
        """Get or create memory pool."""
        if name not in self.memory_pools:
            self.memory_pools[name] = MemoryPool(factory, max_size)
        return self.memory_pools[name]
    
    def get_profiler(self, name: str) -> PerformanceProfiler:
        """Get or create profiler."""
        if name not in self.profilers:
            self.profilers[name] = PerformanceProfiler(name)
        return self.profilers[name]
    
    def performance_report(self) -> Dict[str, Any]:
        """Generate comprehensive performance report."""
        report = {
            "cache_stats": {
                "erlang_c_hit_rate": self.cached_erlang_c.cache.stats.hit_rate,
                "erlang_c_entries": len(self.cached_erlang_c.cache.cache)
            },
            "profiler_stats": {
                name: profiler.stats() for name, profiler in self.profilers.items()
            },
            "memory_usage": {
                "resident_set_size": self._get_memory_usage(),
                "pool_sizes": {name: len(pool.pool) for name, pool in self.memory_pools.items()}
            }
        }
        return report
    
    def _get_memory_usage(self) -> int:
        """Get current memory usage in bytes."""
        try:
            import psutil
            process = psutil.Process()
            return process.memory_info().rss
        except ImportError:
            return sys.getsizeof(gc.get_objects())
    
    def optimize_for_enterprise(self) -> Dict[str, Any]:
        """Apply enterprise-scale optimizations."""
        # Increase cache sizes
        self.cached_erlang_c.cache.max_size = 50000
        
        # Pre-allocate memory pools
        self.get_memory_pool("numpy_arrays", lambda: np.zeros(1000), 50)
        self.get_memory_pool("result_dicts", lambda: {}, 100)
        
        # Trigger garbage collection
        gc.collect()
        
        return {
            "status": "optimized",
            "cache_size": self.cached_erlang_c.cache.max_size,
            "memory_pools": len(self.memory_pools),
            "thread_pool_size": self.parallel_processor.max_workers
        }
    
    def benchmark_suite(self) -> Dict[str, float]:
        """Run performance benchmark suite."""
        results = {}
        
        # Benchmark 1: High Volume Erlang C
        start_time = time.perf_counter()
        lambda_vals = np.random.uniform(10, 100, 1000)
        mu_vals = np.random.uniform(5, 20, 1000)
        s_vals = np.random.randint(5, 50, 1000)
        
        batch_results = self.vectorized_ops.erlang_c_batch(lambda_vals, mu_vals, s_vals)
        results["high_volume_erlang_c"] = time.perf_counter() - start_time
        
        # Benchmark 2: Skill Allocation
        start_time = time.perf_counter()
        agent_matrix = np.random.rand(1000, 10)
        skill_matrix = np.random.rand(20, 10)
        
        skill_scores = self.vectorized_ops.skill_scoring_batch(agent_matrix, skill_matrix)
        results["skill_allocation"] = time.perf_counter() - start_time
        
        # Benchmark 3: Cached Operations
        start_time = time.perf_counter()
        for i in range(1000):
            self.cached_erlang_c.calculate(
                lambda_val=np.random.uniform(10, 100),
                mu=np.random.uniform(5, 20),
                s=np.random.randint(5, 50),
                service_level=0.8
            )
        results["cached_operations"] = time.perf_counter() - start_time
        
        return results
    
    def cleanup(self):
        """Cleanup resources."""
        self.parallel_processor.shutdown()
        for pool in self.memory_pools.values():
            pool.pool.clear()
        gc.collect()


# Global optimizer instance
optimizer = PerformanceOptimizer()


def profile_function(name: str):
    """Decorator for profiling functions."""
    return optimizer.get_profiler(name)


def cached_erlang_c(lambda_val: float, mu: float, s: int, service_level: float = 0.8) -> Dict[str, float]:
    """Cached Erlang C calculation."""
    return optimizer.cached_erlang_c.calculate(lambda_val, mu, s, service_level)


def vectorized_erlang_c_batch(lambda_array: np.ndarray, mu_array: np.ndarray, s_array: np.ndarray) -> np.ndarray:
    """Vectorized Erlang C batch calculation."""
    return optimizer.vectorized_ops.erlang_c_batch(lambda_array, mu_array, s_array)


def get_performance_report() -> Dict[str, Any]:
    """Get comprehensive performance report."""
    return optimizer.performance_report()


def run_benchmark() -> Dict[str, float]:
    """Run performance benchmark suite."""
    return optimizer.benchmark_suite()


if __name__ == "__main__":
    # Run benchmarks
    print("Running performance benchmarks...")
    benchmark_results = run_benchmark()
    
    for test_name, duration in benchmark_results.items():
        print(f"{test_name}: {duration:.4f}s")
    
    # Print performance report
    print("\nPerformance Report:")
    report = get_performance_report()
    print(f"Erlang C Cache Hit Rate: {report['cache_stats']['erlang_c_hit_rate']:.2%}")
    print(f"Memory Usage: {report['memory_usage']['resident_set_size'] / 1024 / 1024:.1f} MB")
    
    # Cleanup
    optimizer.cleanup()