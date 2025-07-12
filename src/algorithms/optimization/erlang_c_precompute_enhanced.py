"""
Enhanced Erlang C Pre-computation Module

This module generates and manages pre-computed Erlang C results for 3,780 industry-standard
scenarios to achieve <100ms response times for common contact center configurations.
"""

import json
import time
import logging
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict
from pathlib import Path
import numpy as np
from concurrent.futures import ProcessPoolExecutor, as_completed
from tqdm import tqdm

from ..core.erlang_c_enhanced import ErlangCEnhanced, ServiceLevelTarget

logger = logging.getLogger(__name__)


@dataclass
class ScenarioResult:
    """Represents a pre-computed Erlang C scenario result."""
    call_volume: float
    aht_seconds: float
    service_level_target: float
    target_wait_seconds: float
    agents_required: int
    achieved_service_level: float
    average_wait_time: float
    utilization: float
    computation_time_ms: float


class ErlangCPrecomputeEnhanced:
    """
    Generates and manages pre-computed Erlang C results for industry-standard scenarios.
    
    Scenario Coverage (3,780 total):
    - Call volumes: 21 values (10, 25, 50, 75, 100, 150, 200, 300, 400, 500, 
                              750, 1000, 1500, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 10000)
    - AHT: 30 values (30s to 900s in 30s intervals)
    - Service levels: 6 values (70%, 75%, 80%, 85%, 90%, 95%)
    - Target wait times: Fixed at 20s for standard scenarios
    
    Total: 21 × 30 × 6 = 3,780 scenarios
    """
    
    # Industry-standard parameter ranges
    CALL_VOLUMES = [10, 25, 50, 75, 100, 150, 200, 300, 400, 500, 
                    750, 1000, 1500, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 10000]
    
    AHT_SECONDS = list(range(30, 901, 30))  # 30s to 15min in 30s intervals
    
    SERVICE_LEVELS = [0.70, 0.75, 0.80, 0.85, 0.90, 0.95]
    
    TARGET_WAIT_SECONDS = [20]  # Standard 20-second target for base scenarios
    
    # Extended scenarios for comprehensive coverage
    EXTENDED_WAIT_TIMES = [10, 15, 20, 30, 45, 60, 90, 120]
    EXTENDED_SERVICE_LEVELS = [0.50, 0.60, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95]
    
    def __init__(self, cache_dir: str = "/tmp/erlang_c_cache"):
        """Initialize the pre-computation manager."""
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.calculator = ErlangCEnhanced()
        self.results_file = self.cache_dir / "precomputed_scenarios.json"
        self.extended_results_file = self.cache_dir / "precomputed_scenarios_extended.json"
        
    def compute_scenario(self, call_volume: float, aht_seconds: float, 
                        service_level: float, wait_time: float) -> Optional[ScenarioResult]:
        """Compute a single Erlang C scenario."""
        try:
            start_time = time.time()
            
            # Convert parameters to calculator format
            lambda_rate = call_volume  # calls per hour
            mu_rate = 3600 / aht_seconds  # service rate per hour
            
            # Calculate required agents
            sl_target = ServiceLevelTarget(
                target_percentage=service_level,
                target_seconds=wait_time
            )
            
            agents_required, achieved_sl = self.calculator.calculate_service_level_staffing(
                lambda_rate=lambda_rate,
                mu_rate=mu_rate,
                target_sl=service_level
            )
            
            # Calculate additional metrics
            metrics = self.calculator.calculate_metrics(
                lambda_rate=lambda_rate,
                mu_rate=mu_rate,
                num_agents=agents_required
            )
            
            computation_time = (time.time() - start_time) * 1000  # Convert to ms
            
            return ScenarioResult(
                call_volume=call_volume,
                aht_seconds=aht_seconds,
                service_level_target=service_level,
                target_wait_seconds=wait_time,
                agents_required=agents_required,
                achieved_service_level=achieved_sl,
                average_wait_time=metrics.get('average_wait_time', 0.0),
                utilization=metrics.get('utilization', 0.0),
                computation_time_ms=computation_time
            )
            
        except Exception as e:
            logger.error(f"Error computing scenario: {e}")
            return None
    
    def generate_standard_scenarios(self, parallel: bool = True, max_workers: int = 4) -> Dict[str, ScenarioResult]:
        """Generate all 3,780 standard industry scenarios."""
        scenarios = []
        
        # Generate all scenario combinations
        for call_volume in self.CALL_VOLUMES:
            for aht in self.AHT_SECONDS:
                for sl in self.SERVICE_LEVELS:
                    for wait_time in self.TARGET_WAIT_SECONDS:
                        scenarios.append((call_volume, aht, sl, wait_time))
        
        logger.info(f"Generating {len(scenarios)} standard scenarios...")
        
        results = {}
        
        if parallel:
            # Use parallel processing for faster computation
            with ProcessPoolExecutor(max_workers=max_workers) as executor:
                # Submit all tasks
                future_to_scenario = {
                    executor.submit(self.compute_scenario, *scenario): scenario
                    for scenario in scenarios
                }
                
                # Process results with progress bar
                with tqdm(total=len(scenarios), desc="Computing scenarios") as pbar:
                    for future in as_completed(future_to_scenario):
                        scenario = future_to_scenario[future]
                        try:
                            result = future.result()
                            if result:
                                key = self._generate_cache_key(*scenario)
                                results[key] = result
                        except Exception as e:
                            logger.error(f"Error in scenario {scenario}: {e}")
                        pbar.update(1)
        else:
            # Sequential processing
            for scenario in tqdm(scenarios, desc="Computing scenarios"):
                result = self.compute_scenario(*scenario)
                if result:
                    key = self._generate_cache_key(*scenario)
                    results[key] = result
        
        logger.info(f"Successfully computed {len(results)} scenarios")
        return results
    
    def generate_extended_scenarios(self, parallel: bool = True, max_workers: int = 4) -> Dict[str, ScenarioResult]:
        """Generate extended scenarios with varied wait times and service levels."""
        scenarios = []
        
        # Focus on common call volumes and AHT ranges for extended scenarios
        common_volumes = [50, 100, 200, 500, 1000, 2000, 5000]
        common_ahts = [60, 120, 180, 240, 300, 360, 420, 480]  # 1-8 minutes
        
        for call_volume in common_volumes:
            for aht in common_ahts:
                for sl in self.EXTENDED_SERVICE_LEVELS:
                    for wait_time in self.EXTENDED_WAIT_TIMES:
                        # Skip if already in standard scenarios
                        if (wait_time == 20 and sl in self.SERVICE_LEVELS and 
                            call_volume in self.CALL_VOLUMES and aht in self.AHT_SECONDS):
                            continue
                        scenarios.append((call_volume, aht, sl, wait_time))
        
        logger.info(f"Generating {len(scenarios)} extended scenarios...")
        
        results = {}
        
        if parallel:
            with ProcessPoolExecutor(max_workers=max_workers) as executor:
                future_to_scenario = {
                    executor.submit(self.compute_scenario, *scenario): scenario
                    for scenario in scenarios
                }
                
                with tqdm(total=len(scenarios), desc="Computing extended scenarios") as pbar:
                    for future in as_completed(future_to_scenario):
                        scenario = future_to_scenario[future]
                        try:
                            result = future.result()
                            if result:
                                key = self._generate_cache_key(*scenario)
                                results[key] = result
                        except Exception as e:
                            logger.error(f"Error in scenario {scenario}: {e}")
                        pbar.update(1)
        else:
            for scenario in tqdm(scenarios, desc="Computing extended scenarios"):
                result = self.compute_scenario(*scenario)
                if result:
                    key = self._generate_cache_key(*scenario)
                    results[key] = result
        
        logger.info(f"Successfully computed {len(results)} extended scenarios")
        return results
    
    def save_results(self, results: Dict[str, ScenarioResult], filename: Optional[str] = None) -> None:
        """Save pre-computed results to JSON file."""
        if filename:
            output_file = self.cache_dir / filename
        else:
            output_file = self.results_file
            
        # Convert dataclass instances to dictionaries
        serializable_results = {
            key: asdict(result) for key, result in results.items()
        }
        
        with open(output_file, 'w') as f:
            json.dump(serializable_results, f, indent=2)
        
        logger.info(f"Saved {len(results)} results to {output_file}")
    
    def load_results(self, filename: Optional[str] = None) -> Dict[str, ScenarioResult]:
        """Load pre-computed results from JSON file."""
        if filename:
            input_file = self.cache_dir / filename
        else:
            input_file = self.results_file
            
        if not input_file.exists():
            logger.warning(f"Results file {input_file} not found")
            return {}
        
        with open(input_file, 'r') as f:
            data = json.load(f)
        
        # Convert dictionaries back to dataclass instances
        results = {
            key: ScenarioResult(**value) for key, value in data.items()
        }
        
        logger.info(f"Loaded {len(results)} results from {input_file}")
        return results
    
    def _generate_cache_key(self, call_volume: float, aht_seconds: float,
                           service_level: float, wait_time: float) -> str:
        """Generate a unique cache key for a scenario."""
        return f"{call_volume}_{aht_seconds}_{service_level:.2f}_{wait_time}"
    
    def generate_all_scenarios(self, force_regenerate: bool = False) -> Tuple[Dict, Dict]:
        """Generate both standard and extended scenarios."""
        standard_results = {}
        extended_results = {}
        
        # Check if results already exist
        if not force_regenerate:
            if self.results_file.exists():
                logger.info("Loading existing standard scenarios...")
                standard_results = self.load_results()
                
            if self.extended_results_file.exists():
                logger.info("Loading existing extended scenarios...")
                extended_results = self.load_results("precomputed_scenarios_extended.json")
        
        # Generate missing scenarios
        if not standard_results or force_regenerate:
            logger.info("Generating standard scenarios...")
            standard_results = self.generate_standard_scenarios()
            self.save_results(standard_results)
        
        if not extended_results or force_regenerate:
            logger.info("Generating extended scenarios...")
            extended_results = self.generate_extended_scenarios()
            self.save_results(extended_results, "precomputed_scenarios_extended.json")
        
        return standard_results, extended_results
    
    def get_statistics(self, results: Dict[str, ScenarioResult]) -> Dict[str, float]:
        """Calculate statistics for pre-computed results."""
        if not results:
            return {}
        
        computation_times = [r.computation_time_ms for r in results.values()]
        agent_counts = [r.agents_required for r in results.values()]
        utilizations = [r.utilization for r in results.values()]
        
        return {
            "total_scenarios": len(results),
            "avg_computation_time_ms": np.mean(computation_times),
            "max_computation_time_ms": np.max(computation_times),
            "min_computation_time_ms": np.min(computation_times),
            "avg_agents_required": np.mean(agent_counts),
            "max_agents_required": np.max(agent_counts),
            "avg_utilization": np.mean(utilizations),
            "total_computation_time_seconds": sum(computation_times) / 1000
        }


def main():
    """Main function to generate all pre-computed scenarios."""
    logging.basicConfig(level=logging.INFO)
    
    precomputer = ErlangCPrecomputeEnhanced()
    
    print("Erlang C Pre-computation Generator")
    print("==================================")
    print(f"Standard scenarios: {len(precomputer.CALL_VOLUMES)} × {len(precomputer.AHT_SECONDS)} × "
          f"{len(precomputer.SERVICE_LEVELS)} = {len(precomputer.CALL_VOLUMES) * len(precomputer.AHT_SECONDS) * len(precomputer.SERVICE_LEVELS)}")
    
    # Generate all scenarios
    standard_results, extended_results = precomputer.generate_all_scenarios()
    
    # Display statistics
    print("\nStandard Scenarios Statistics:")
    print("------------------------------")
    stats = precomputer.get_statistics(standard_results)
    for key, value in stats.items():
        print(f"{key}: {value:.2f}")
    
    print("\nExtended Scenarios Statistics:")
    print("------------------------------")
    stats = precomputer.get_statistics(extended_results)
    for key, value in stats.items():
        print(f"{key}: {value:.2f}")
    
    print(f"\nTotal scenarios generated: {len(standard_results) + len(extended_results)}")
    print(f"Cache files saved to: {precomputer.cache_dir}")


if __name__ == "__main__":
    main()