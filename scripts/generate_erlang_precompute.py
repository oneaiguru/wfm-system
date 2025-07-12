#!/usr/bin/env python3
"""
Script to generate pre-computed Erlang C scenarios for performance optimization.

This script generates the 3,780 industry-standard scenarios needed to achieve
<100ms response times for common contact center configurations.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from src.algorithms.optimization.erlang_c_precompute_enhanced import ErlangCPrecomputeEnhanced


def main():
    """Generate all pre-computed Erlang C scenarios."""
    print("Erlang C Pre-computation Generator")
    print("=" * 50)
    
    # Initialize the pre-computer
    cache_dir = project_root / "data" / "erlang_cache"
    precomputer = ErlangCPrecomputeEnhanced(cache_dir=str(cache_dir))
    
    print(f"Cache directory: {cache_dir}")
    print(f"Standard scenarios to generate: 3,780")
    print(f"Using parallel processing for faster computation\n")
    
    # Check if scenarios already exist
    existing_standard = precomputer.results_file.exists()
    existing_extended = precomputer.extended_results_file.exists()
    
    if existing_standard and existing_extended:
        print("Pre-computed scenarios already exist!")
        response = input("Do you want to regenerate them? (y/N): ").lower()
        if response != 'y':
            print("Exiting without regeneration.")
            return
    
    # Generate scenarios
    print("\nGenerating scenarios...")
    standard_results, extended_results = precomputer.generate_all_scenarios(
        force_regenerate=True if existing_standard else False
    )
    
    # Display statistics
    print("\n" + "=" * 50)
    print("Generation Complete!")
    print("=" * 50)
    
    print("\nStandard Scenarios:")
    stats = precomputer.get_statistics(standard_results)
    print(f"  - Total scenarios: {stats['total_scenarios']:.0f}")
    print(f"  - Avg computation time: {stats['avg_computation_time_ms']:.2f}ms")
    print(f"  - Total generation time: {stats['total_computation_time_seconds']:.1f}s")
    
    print("\nExtended Scenarios:")
    stats = precomputer.get_statistics(extended_results)
    print(f"  - Total scenarios: {stats['total_scenarios']:.0f}")
    print(f"  - Avg computation time: {stats['avg_computation_time_ms']:.2f}ms")
    print(f"  - Total generation time: {stats['total_computation_time_seconds']:.1f}s")
    
    print(f"\nCache files saved to: {cache_dir}")
    print("\nThese pre-computed scenarios will enable <100ms response times!")


if __name__ == "__main__":
    main()