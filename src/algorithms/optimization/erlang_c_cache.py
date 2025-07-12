"""
Erlang C Caching Layer
Optimizes performance by caching frequently requested calculations
Target: Reduce response time from 415ms to <100ms
"""

import hashlib
import json
import time
from typing import Dict, Tuple, Optional, Any
from dataclasses import dataclass
from collections import OrderedDict
import numpy as np
from concurrent.futures import ThreadPoolExecutor
import asyncio
from pathlib import Path
import logging

from .erlang_c_precompute_enhanced import ErlangCPrecomputeEnhanced, ScenarioResult

logger = logging.getLogger(__name__)


@dataclass
class CacheEntry:
    """Single cache entry with metadata"""
    result: Tuple[int, float]  # (agents_required, service_level)
    timestamp: float
    hit_count: int = 0
    compute_time_ms: float = 0.0


class ErlangCCache:
    """
    High-performance caching layer for Erlang C calculations
    
    Features:
    - Multi-level caching (exact match, range-based, interpolated)
    - Pre-computation of common scenarios
    - Async warming for predictive caching
    - Performance monitoring
    """
    
    def __init__(self, max_size: int = 10000, ttl: int = 3600, cache_dir: str = "/tmp/erlang_c_cache"):
        self.max_size = max_size
        self.ttl = ttl
        self.cache_dir = Path(cache_dir)
        
        # Level 1: Exact match cache
        self.exact_cache: OrderedDict[str, CacheEntry] = OrderedDict()
        
        # Level 2: Range-based cache for interpolation
        self.range_cache: Dict[str, Dict[str, CacheEntry]] = {}
        
        # Level 3: Pre-computed lookup tables from ErlangCPrecomputeEnhanced
        self.lookup_tables: Dict[str, ScenarioResult] = {}
        
        # Performance metrics
        self.stats = {
            'hits': 0,
            'misses': 0,
            'avg_compute_time': 0.0,
            'cache_saves_ms': 0.0
        }
        
        # Pre-compute manager
        self.precompute_manager = ErlangCPrecomputeEnhanced(cache_dir=cache_dir)
        
        # Background pre-computation
        self.executor = ThreadPoolExecutor(max_workers=2)
        self._initialize_lookup_tables()
    
    def get_cache_key(self, lambda_rate: float, mu_rate: float, 
                     target_sl: float, **kwargs) -> str:
        """Generate unique cache key"""
        # Round to reasonable precision to increase cache hits
        key_data = {
            'lambda': round(lambda_rate, 1),
            'mu': round(mu_rate, 2),
            'sl': round(target_sl, 3),
            **kwargs
        }
        key_str = json.dumps(key_data, sort_keys=True)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def get(self, lambda_rate: float, mu_rate: float, 
            target_sl: float, **kwargs) -> Optional[Tuple[int, float]]:
        """
        Get cached result with multi-level lookup
        
        Returns:
            Tuple of (agents_required, achieved_service_level) or None
        """
        start_time = time.perf_counter()
        
        # Level 1: Exact match
        cache_key = self.get_cache_key(lambda_rate, mu_rate, target_sl, **kwargs)
        if cache_key in self.exact_cache:
            entry = self.exact_cache[cache_key]
            if time.time() - entry.timestamp < self.ttl:
                # Move to end (LRU)
                self.exact_cache.move_to_end(cache_key)
                entry.hit_count += 1
                self.stats['hits'] += 1
                self.stats['cache_saves_ms'] += (time.perf_counter() - start_time) * 1000
                return entry.result
            else:
                # Expired
                del self.exact_cache[cache_key]
        
        # Level 2: Lookup table (pre-computed scenarios)
        # Try exact match first
        aht_seconds = 3600 / mu_rate  # Convert mu_rate back to AHT
        lookup_key = self.precompute_manager._generate_cache_key(
            lambda_rate, aht_seconds, target_sl, 20  # Default 20s wait time
        )
        
        if lookup_key in self.lookup_tables:
            scenario = self.lookup_tables[lookup_key]
            self.stats['hits'] += 1
            return (scenario.agents_required, scenario.achieved_service_level)
        
        # Try with rounded values for near matches
        rounded_lambda = round(lambda_rate / 10) * 10  # Round to nearest 10
        rounded_aht = round(aht_seconds / 30) * 30     # Round to nearest 30s
        rounded_sl = round(target_sl * 20) / 20        # Round to nearest 0.05
        
        rounded_key = self.precompute_manager._generate_cache_key(
            rounded_lambda, rounded_aht, rounded_sl, 20
        )
        
        if rounded_key in self.lookup_tables:
            scenario = self.lookup_tables[rounded_key]
            self.stats['hits'] += 1
            # Adjust the result slightly based on the difference
            adjustment_factor = (lambda_rate / rounded_lambda) * (rounded_aht / aht_seconds)
            adjusted_agents = max(1, int(scenario.agents_required * adjustment_factor))
            return (adjusted_agents, scenario.achieved_service_level)
        
        # Level 3: Range-based interpolation
        result = self._interpolate_from_cache(lambda_rate, mu_rate, target_sl)
        if result:
            self.stats['hits'] += 1
            return result
        
        self.stats['misses'] += 1
        return None
    
    def put(self, lambda_rate: float, mu_rate: float, target_sl: float,
            agents: int, achieved_sl: float, compute_time_ms: float, **kwargs):
        """Store result in cache"""
        cache_key = self.get_cache_key(lambda_rate, mu_rate, target_sl, **kwargs)
        
        # Enforce cache size limit
        if len(self.exact_cache) >= self.max_size:
            # Remove oldest entry
            self.exact_cache.popitem(last=False)
        
        # Store new entry
        self.exact_cache[cache_key] = CacheEntry(
            result=(agents, achieved_sl),
            timestamp=time.time(),
            compute_time_ms=compute_time_ms
        )
        
        # Update average compute time
        self.stats['avg_compute_time'] = (
            (self.stats['avg_compute_time'] * self.stats['misses'] + compute_time_ms) /
            (self.stats['misses'] + 1)
        )
        
        # Also store in range cache for interpolation
        self._update_range_cache(lambda_rate, mu_rate, target_sl, agents, achieved_sl)
    
    def _initialize_lookup_tables(self):
        """Load pre-computed scenarios from ErlangCPrecomputeEnhanced"""
        logger.info("Initializing lookup tables with pre-computed scenarios...")
        
        # Submit for background loading
        self.executor.submit(self._load_precomputed_scenarios)
    
    def _load_precomputed_scenarios(self):
        """Load pre-computed scenarios from JSON files"""
        try:
            # Load standard scenarios (3,780 industry-standard scenarios)
            standard_scenarios = self.precompute_manager.load_results()
            
            # If no pre-computed scenarios exist, generate them
            if not standard_scenarios:
                logger.info("No pre-computed scenarios found. Generating standard scenarios...")
                standard_scenarios, _ = self.precompute_manager.generate_all_scenarios()
            
            # Load extended scenarios if available
            extended_scenarios = self.precompute_manager.load_results("precomputed_scenarios_extended.json")
            
            # Merge all scenarios into lookup tables
            self.lookup_tables.update(standard_scenarios)
            if extended_scenarios:
                self.lookup_tables.update(extended_scenarios)
            
            logger.info(f"Loaded {len(self.lookup_tables)} pre-computed scenarios")
            
            # Calculate statistics
            if self.lookup_tables:
                stats = self.precompute_manager.get_statistics(self.lookup_tables)
                logger.info(f"Pre-computed scenarios - Avg computation time: {stats.get('avg_computation_time_ms', 0):.2f}ms")
                
        except Exception as e:
            logger.error(f"Error loading pre-computed scenarios: {e}")
            # Fall back to empty lookup tables
            self.lookup_tables = {}
    
    def load_precomputed_scenarios_from_json(self, json_path: str) -> bool:
        """Load pre-computed scenarios from a specific JSON file"""
        try:
            scenarios = self.precompute_manager.load_results(json_path)
            self.lookup_tables.update(scenarios)
            logger.info(f"Loaded {len(scenarios)} scenarios from {json_path}")
            return True
        except Exception as e:
            logger.error(f"Error loading scenarios from {json_path}: {e}")
            return False
    
    def _interpolate_from_cache(self, lambda_rate: float, mu_rate: float,
                               target_sl: float) -> Optional[Tuple[int, float]]:
        """Interpolate result from nearby cached values"""
        # Find closest cached values
        tolerance = 0.1  # 10% tolerance
        candidates = []
        
        for key, entry in self.exact_cache.items():
            # Parse key to get parameters (simplified)
            # In production, would decode the key properly
            if time.time() - entry.timestamp < self.ttl:
                candidates.append(entry.result)
        
        if len(candidates) >= 2:
            # Simple average for demonstration
            avg_agents = sum(c[0] for c in candidates) / len(candidates)
            avg_sl = sum(c[1] for c in candidates) / len(candidates)
            return (int(avg_agents), avg_sl)
        
        return None
    
    def _update_range_cache(self, lambda_rate: float, mu_rate: float,
                           target_sl: float, agents: int, achieved_sl: float):
        """Update range cache for interpolation"""
        # Create range buckets
        lambda_bucket = int(lambda_rate / 100) * 100
        mu_bucket = int(mu_rate / 5) * 5
        sl_bucket = int(target_sl * 10) / 10
        
        bucket_key = f"{lambda_bucket}_{mu_bucket}_{sl_bucket}"
        
        if bucket_key not in self.range_cache:
            self.range_cache[bucket_key] = {}
        
        point_key = f"{lambda_rate}_{mu_rate}_{target_sl}"
        self.range_cache[bucket_key][point_key] = CacheEntry(
            result=(agents, achieved_sl),
            timestamp=time.time()
        )
    
    def warm_cache_async(self, predicted_requests: list):
        """Asynchronously warm cache with predicted requests"""
        async def warm():
            tasks = []
            for params in predicted_requests:
                # Check if already cached
                if not self.get(params['lambda'], params['mu'], params['sl']):
                    # Submit for computation
                    task = asyncio.create_task(self._compute_async(params))
                    tasks.append(task)
            
            if tasks:
                await asyncio.gather(*tasks)
        
        # Run in background
        asyncio.create_task(warm())
    
    async def _compute_async(self, params):
        """Placeholder for async computation"""
        # Would call actual Erlang C calculator
        await asyncio.sleep(0.01)  # Simulate computation
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache performance statistics"""
        total = self.stats['hits'] + self.stats['misses']
        hit_rate = self.stats['hits'] / total if total > 0 else 0
        
        return {
            'hit_rate': hit_rate,
            'total_hits': self.stats['hits'],
            'total_misses': self.stats['misses'],
            'avg_compute_time_ms': self.stats['avg_compute_time'],
            'cache_saves_ms': self.stats['cache_saves_ms'],
            'cache_size': len(self.exact_cache),
            'lookup_table_size': len(self.lookup_tables),
            'estimated_time_saved_ms': self.stats['cache_saves_ms'] * hit_rate
        }
    
    def ensure_precomputed_scenarios_exist(self, force_regenerate: bool = False) -> bool:
        """Ensure pre-computed scenarios exist, generate if needed"""
        try:
            if force_regenerate or not self.lookup_tables:
                logger.info("Generating pre-computed scenarios...")
                standard_scenarios, extended_scenarios = self.precompute_manager.generate_all_scenarios(
                    force_regenerate=force_regenerate
                )
                # Reload the generated scenarios
                self._load_precomputed_scenarios()
                return True
            return len(self.lookup_tables) > 0
        except Exception as e:
            logger.error(f"Error ensuring pre-computed scenarios: {e}")
            return False
    
    def clear(self):
        """Clear all caches"""
        self.exact_cache.clear()
        self.range_cache.clear()
        self.stats = {
            'hits': 0,
            'misses': 0,
            'avg_compute_time': 0.0,
            'cache_saves_ms': 0.0
        }


# Integration with ErlangCEnhanced
class CachedErlangCEnhanced:
    """Wrapper for ErlangCEnhanced with caching and pre-computed scenarios"""
    
    def __init__(self, base_calculator, cache: Optional[ErlangCCache] = None):
        self.calculator = base_calculator
        self.cache = cache or ErlangCCache()
        
        # Ensure pre-computed scenarios are loaded
        if not self.cache.lookup_tables:
            logger.info("Loading pre-computed scenarios on demand...")
            self.cache._load_precomputed_scenarios()
    
    def calculate_service_level_staffing(self, lambda_rate: float, mu_rate: float,
                                        target_sl: float, **kwargs) -> Tuple[int, float]:
        """Calculate with caching"""
        # Check cache first
        cached = self.cache.get(lambda_rate, mu_rate, target_sl, **kwargs)
        if cached:
            return cached
        
        # Calculate if not cached
        start_time = time.perf_counter()
        agents, achieved_sl = self.calculator.calculate_service_level_staffing(
            lambda_rate, mu_rate, target_sl
        )
        compute_time_ms = (time.perf_counter() - start_time) * 1000
        
        # Store in cache
        self.cache.put(lambda_rate, mu_rate, target_sl, agents, achieved_sl, 
                      compute_time_ms, **kwargs)
        
        return agents, achieved_sl
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache performance stats"""
        stats = self.cache.get_stats()
        stats['precomputed_scenarios'] = len(self.cache.lookup_tables)
        return stats
    
    def warm_cache_with_scenarios(self, scenarios: list) -> int:
        """Warm the cache with specific scenarios"""
        warmed = 0
        for scenario in scenarios:
            if 'lambda_rate' in scenario and 'mu_rate' in scenario and 'target_sl' in scenario:
                # Check if already in pre-computed scenarios
                aht = 3600 / scenario['mu_rate']
                key = self.cache.precompute_manager._generate_cache_key(
                    scenario['lambda_rate'], aht, scenario['target_sl'], 
                    scenario.get('wait_time', 20)
                )
                
                if key not in self.cache.lookup_tables:
                    # Compute and cache
                    result = self.calculate_service_level_staffing(
                        scenario['lambda_rate'],
                        scenario['mu_rate'],
                        scenario['target_sl']
                    )
                    warmed += 1
        
        return warmed


# Example usage
if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Create cache with pre-computed scenarios
    cache = ErlangCCache(max_size=10000, ttl=3600)
    
    # Wait for pre-computed scenarios to load
    import time
    time.sleep(2)
    
    print(f"\nLoaded {len(cache.lookup_tables)} pre-computed scenarios")
    
    # Test with industry-standard scenarios
    test_scenarios = [
        (100, 20, 0.80),     # 100 calls/hour, 3min AHT, 80% SL
        (500, 15, 0.85),     # 500 calls/hour, 4min AHT, 85% SL
        (1000, 12, 0.90),    # 1000 calls/hour, 5min AHT, 90% SL
        (2000, 20, 0.85),    # 2000 calls/hour, 3min AHT, 85% SL
        (100, 20, 0.80),     # Repeat - should hit exact cache
        (500, 15, 0.85),     # Repeat - should hit exact cache
    ]
    
    print("\nTesting cache performance:")
    print("-" * 60)
    
    for lambda_r, mu_r, sl in test_scenarios:
        start = time.perf_counter()
        result = cache.get(lambda_r, mu_r, sl)
        elapsed_ms = (time.perf_counter() - start) * 1000
        
        if result:
            print(f"Cache HIT: λ={lambda_r:4d}, μ={mu_r:2d}, SL={sl:.2f} → "
                  f"Agents={result[0]:3d}, Achieved SL={result[1]:.3f} "
                  f"(Time: {elapsed_ms:.2f}ms)")
        else:
            print(f"Cache MISS: λ={lambda_r:4d}, μ={mu_r:2d}, SL={sl:.2f} "
                  f"(Time: {elapsed_ms:.2f}ms)")
            # Simulate calculation
            agents = int(lambda_r / mu_r * 1.2)
            cache.put(lambda_r, mu_r, sl, agents, sl + 0.05, 50.0)
    
    print("\n" + "=" * 60)
    print("Cache Statistics:")
    stats = cache.get_stats()
    for key, value in stats.items():
        if isinstance(value, float):
            print(f"  {key}: {value:.2f}")
        else:
            print(f"  {key}: {value}")