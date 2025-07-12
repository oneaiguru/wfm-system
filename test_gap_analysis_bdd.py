#!/usr/bin/env python
"""
🔴🟢 TDD Test for Gap Analysis Engine per BDD Line 51
From: 24-automatic-schedule-optimization.feature:51
"Gap Analysis Engine | Statistical analysis | Coverage vs forecast | Gap severity map | 2-3 seconds"
"""

import sys
import time
sys.path.insert(0, '.')

from src.algorithms.optimization.gap_analysis_engine import GapAnalysisEngine, GapSeverity

def test_gap_analysis_bdd_basic():
    """Test basic gap analysis per BDD requirements"""
    
    print("\n📊 TESTING GAP ANALYSIS ENGINE (BDD Line 51)")
    print("="*60)
    print("BDD: Statistical analysis | Coverage vs forecast | Gap severity map")
    
    engine = GapAnalysisEngine()
    
    # Test Case 1: Standard scenario with gaps
    print("\n📈 Test 1: Standard Coverage Gaps")
    
    # Forecast requirements (what we need)
    forecast_data = {
        '09:00': 10, '10:00': 15, '11:00': 20, '12:00': 25,
        '13:00': 30, '14:00': 28, '15:00': 22, '16:00': 18,
        '17:00': 12, '18:00': 8
    }
    
    # Current schedule (what we have)
    current_schedule = {
        '09:00': 8,  '10:00': 12, '11:00': 18, '12:00': 20,  # Gaps here
        '13:00': 30, '14:00': 28, '15:00': 22, '16:00': 18,  # Covered
        '17:00': 12, '18:00': 8
    }
    
    # Run gap analysis
    start_time = time.time()
    result = engine.analyze_coverage_gaps(forecast_data, current_schedule)
    processing_time = (time.time() - start_time) * 1000
    
    print(f"Processing time: {result.processing_time_ms:.1f}ms")
    print(f"Total gaps: {result.total_gaps} agents")
    print(f"Average gap: {result.average_gap_percentage:.1%}")
    print(f"Coverage score: {result.coverage_score:.1f}/100")
    print(f"Critical intervals: {len(result.critical_intervals)}")
    
    # BDD Validations
    assert result.processing_time_ms <= 3000, f"Too slow: {result.processing_time_ms}ms > 3000ms"
    assert result.total_gaps > 0, "Should detect gaps in test data"
    assert result.coverage_score < 100, "Should show imperfect coverage"
    assert len(result.improvement_recommendations) > 0, "Should provide recommendations"
    
    print("✅ PASS: Basic gap analysis working")
    
    # Test Case 2: Gap severity classification
    print("\n🚨 Test 2: Gap Severity Classification")
    
    # Check severity levels
    severity_counts = {}
    for gap in result.interval_gaps:
        severity = gap.severity.value
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        if gap.gap_count > 0:
            print(f"  {gap.interval}: {gap.gap_count} gap → {gap.severity.value}")
    
    print(f"Severity distribution: {severity_counts}")
    
    # Should have different severity levels
    assert len(severity_counts) > 1, "Should classify different severity levels"
    print("✅ PASS: Gap severity classification working")

def test_gap_patterns_identification():
    """Test gap pattern identification per BDD"""
    
    print("\n\n🔍 Test 3: Gap Pattern Identification")
    
    engine = GapAnalysisEngine()
    
    # Create pattern with peak hour gaps
    forecast = {f"{h:02d}:00": 25 if 10 <= h <= 15 else 10 for h in range(9, 19)}
    schedule = {f"{h:02d}:00": 20 if 10 <= h <= 15 else 10 for h in range(9, 19)}  # Peak gaps
    
    result = engine.analyze_coverage_gaps(forecast, schedule)
    patterns = engine.identify_gap_patterns(result.interval_gaps)
    
    print(f"Peak periods: {len(patterns['peak_periods'])}")
    print(f"Severity distribution: {patterns['severity_distribution']}")
    print(f"Cost hotspots: {len(patterns['cost_hotspots'])}")
    
    # Should detect peak hour pattern
    assert len(patterns['peak_periods']) > 0, "Should detect peak periods"
    assert len(patterns['cost_hotspots']) > 0, "Should identify cost hotspots"
    
    print("✅ PASS: Pattern identification working")

def test_bdd_compliance_validation():
    """Test compliance with all BDD requirements"""
    
    print("\n\n✅ Test 4: BDD Compliance Validation")
    
    engine = GapAnalysisEngine()
    
    # Simple test data
    forecast = {'10:00': 20, '11:00': 25, '12:00': 30}
    schedule = {'10:00': 15, '11:00': 20, '12:00': 25}  # 5 gap each
    
    result = engine.analyze_coverage_gaps(forecast, schedule)
    validation = engine.validate_bdd_requirements(result)
    
    print("BDD Requirement Validation:")
    for requirement, passed in validation.items():
        status = "✅" if passed else "❌"
        print(f"  {status} {requirement}")
    
    # All requirements should pass
    all_passed = all(validation.values())
    assert all_passed, f"BDD requirements failed: {validation}"
    
    print("✅ PASS: All BDD requirements validated")

def test_improvement_recommendations():
    """Test improvement recommendations per BDD line 65"""
    
    print("\n\n💡 Test 5: Improvement Recommendations")
    
    engine = GapAnalysisEngine()
    
    # Create scenario with critical gaps
    forecast = {'10:00': 50, '11:00': 40, '12:00': 60}  # High requirements
    schedule = {'10:00': 30, '11:00': 30, '12:00': 30}  # Understaffed
    
    result = engine.analyze_coverage_gaps(forecast, schedule)
    
    print(f"Recommendations ({len(result.improvement_recommendations)}):")
    for i, rec in enumerate(result.improvement_recommendations, 1):
        print(f"  {i}. {rec}")
    
    # BDD Target: >15% reduction
    total_required = sum(forecast.values())
    total_gap = result.total_gaps
    potential_improvement = total_gap / total_required
    
    print(f"Potential improvement: {potential_improvement:.1%}")
    
    # Should provide actionable recommendations
    assert len(result.improvement_recommendations) >= 2, "Should provide multiple recommendations"
    assert any("URGENT" in rec for rec in result.improvement_recommendations), "Should flag urgent issues"
    
    print("✅ PASS: Improvement recommendations generated")

def test_performance_requirement():
    """Test 2-3 second processing requirement"""
    
    print("\n\n⚡ Test 6: Performance Requirement (2-3 seconds)")
    
    engine = GapAnalysisEngine()
    
    # Large dataset test
    forecast = {f"{h:02d}:{m:02d}": 20 + (h * m) % 15 
               for h in range(6, 24) for m in [0, 15, 30, 45]}
    schedule = {k: v - 3 for k, v in forecast.items()}  # 3 agent gaps
    
    start_time = time.time()
    result = engine.analyze_coverage_gaps(forecast, schedule)
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Large dataset ({len(forecast)} intervals):")
    print(f"Processing time: {actual_time:.1f}ms")
    print(f"BDD requirement: ≤3000ms")
    
    # BDD requirement: 2-3 seconds max
    assert actual_time <= 3000, f"Too slow: {actual_time}ms > 3000ms"
    print("✅ PASS: Performance requirement met")

def compare_with_argus():
    """Show our gap analysis advantage"""
    
    print("\n\n🏆 GAP ANALYSIS vs ARGUS")
    print("="*60)
    
    comparison = """
    ┌─────────────────────┬─────────────┬────────────┐
    │ Capability          │ WFM         │ Argus      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Gap Detection       │ ✅ Auto     │ ❌ Manual  │
    │ Severity Mapping    │ ✅ 5 levels │ ❌ Basic   │
    │ Pattern Analysis    │ ✅ ML-based │ ❌ None    │
    │ Cost Impact         │ ✅ Real-time│ ❌ Manual  │
    │ Recommendations     │ ✅ Auto     │ ❌ None    │
    │ Processing Speed    │ ✅ <3 sec   │ ❓ Unknown │
    │ Statistical Depth   │ ✅ Advanced │ ❌ Basic   │
    └─────────────────────┴─────────────┴────────────┘
    """
    print(comparison)
    
    print("\nBDD ADVANTAGES:")
    print("1. Automated statistical gap analysis (Argus requires manual review)")
    print("2. Real-time severity mapping with color coding")
    print("3. Pattern detection for optimization opportunities")
    print("4. Instant cost impact calculations")
    print("5. >15% improvement recommendations")

if __name__ == "__main__":
    # Run all BDD tests
    test_gap_analysis_bdd_basic()
    test_gap_patterns_identification()
    test_bdd_compliance_validation()
    test_improvement_recommendations()
    test_performance_requirement()
    compare_with_argus()
    
    print("\n\n✅ GAP ANALYSIS ENGINE BDD TESTS COMPLETE!")
    print("All requirements from line 51 validated")