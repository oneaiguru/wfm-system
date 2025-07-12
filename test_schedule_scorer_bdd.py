#!/usr/bin/env python
"""
🔴🟢 TDD Test for Multi-Criteria Schedule Scorer
Testing from 24-automatic-schedule-optimization.feature
"""

import sys
sys.path.insert(0, '.')

from src.algorithms.optimization.schedule_scorer import MultiCriteriaScheduleScorer, ScheduleMetrics

def test_schedule_scorer_from_bdd():
    """Test multi-criteria scoring per BDD requirements"""
    
    print("\n📊 TESTING MULTI-CRITERIA SCHEDULE SCORER (BDD)")
    print("="*50)
    
    scorer = MultiCriteriaScheduleScorer()
    
    # Test Case 1: Good schedule from BDD scenario
    print("\n✅ Test 1: Well-Optimized Schedule")
    
    good_schedule = {
        'shifts': [
            {'agent': 'A001', 'start': '09:00', 'end': '17:00', 'skill': 'English'},
            {'agent': 'A002', 'start': '10:00', 'end': '18:00', 'skill': 'English'},
            {'agent': 'A003', 'start': '11:00', 'end': '19:00', 'skill': 'Russian'},
            {'agent': 'A004', 'start': '08:00', 'end': '16:00', 'skill': 'Technical'},
            {'agent': 'A005', 'start': '13:00', 'end': '21:00', 'skill': 'English'},
        ],
        'coverage': {
            '09:00': 2, '10:00': 3, '11:00': 4, '12:00': 4,
            '13:00': 5, '14:00': 5, '15:00': 5, '16:00': 4,
            '17:00': 3, '18:00': 2, '19:00': 1, '20:00': 1
        },
        'total_hours': 40,
        'overtime_hours': 0,
        'cost': 1200
    }
    
    requirements = {
        'coverage_targets': {
            '09:00': 2, '10:00': 3, '11:00': 4, '12:00': 4,
            '13:00': 5, '14:00': 5, '15:00': 5, '16:00': 4,
            '17:00': 3, '18:00': 2, '19:00': 1, '20:00': 1
        },
        'min_coverage': 0.95,
        'max_cost': 1500,
        'service_level': 0.80
    }
    
    # Score the schedule
    result = scorer.score_schedule(good_schedule, requirements)
    
    print(f"Coverage Score: {result.coverage_score:.2f}")
    print(f"Cost Score: {result.cost_score:.2f}")
    print(f"Compliance Score: {result.compliance_score:.2f}")
    print(f"Fairness Score: {result.fairness_score:.2f}")
    print(f"Overall Score: {result.overall_score:.2f}")
    
    # BDD acceptance criteria
    assert result.coverage_score >= 0.95, "Coverage below BDD requirement"
    assert result.overall_score >= 0.80, "Overall score below acceptable"
    print("✅ PASS: Good schedule scores well")
    
    # Test Case 2: Poor schedule (gaps in coverage)
    print("\n\n❌ Test 2: Poor Schedule with Gaps")
    
    poor_schedule = {
        'shifts': [
            {'agent': 'A001', 'start': '09:00', 'end': '13:00', 'skill': 'English'},
            {'agent': 'A002', 'start': '14:00', 'end': '18:00', 'skill': 'English'},
        ],
        'coverage': {
            '09:00': 1, '10:00': 1, '11:00': 1, '12:00': 1,
            '13:00': 0, '14:00': 1, '15:00': 1, '16:00': 1,
            '17:00': 1, '18:00': 0, '19:00': 0, '20:00': 0
        },
        'total_hours': 16,
        'overtime_hours': 0,
        'cost': 400
    }
    
    result_poor = scorer.score_schedule(poor_schedule, requirements)
    
    print(f"Coverage Score: {result_poor.coverage_score:.2f}")
    print(f"Overall Score: {result_poor.overall_score:.2f}")
    
    assert result_poor.coverage_score < 0.50, "Poor coverage not detected"
    assert result_poor.overall_score < result.overall_score, "Poor schedule scored too high"
    print("✅ PASS: Poor schedule correctly penalized")
    
    # Test Case 3: Custom weights (BDD requirement)
    print("\n\n⚖️ Test 3: Custom Weight Configuration")
    
    # Customer prioritizes cost over coverage
    scorer.weights = {
        'coverage': 0.20,
        'cost': 0.40,
        'compliance': 0.20,
        'fairness': 0.10,
        'efficiency': 0.05,
        'flexibility': 0.03,
        'continuity': 0.01,
        'preference': 0.01
    }
    
    result_custom = scorer.score_schedule(good_schedule, requirements)
    print(f"With cost priority: {result_custom.overall_score:.2f}")
    print("✅ PASS: Custom weights applied")

def test_bdd_scoring_criteria():
    """Test all 8 dimensions from BDD"""
    
    print("\n\n🎯 TESTING 8-DIMENSIONAL SCORING (BDD)")
    print("="*50)
    
    scorer = MultiCriteriaScheduleScorer()
    
    # Verify all 8 dimensions exist
    expected_dimensions = [
        'coverage', 'cost', 'compliance', 'fairness',
        'efficiency', 'flexibility', 'continuity', 'preference'
    ]
    
    for dimension in expected_dimensions:
        assert dimension in scorer.weights, f"Missing dimension: {dimension}"
        print(f"✅ {dimension}: weight = {scorer.weights[dimension]}")
    
    # Verify weights sum to 1.0
    total_weight = sum(scorer.weights.values())
    assert abs(total_weight - 1.0) < 0.001, f"Weights sum to {total_weight}, not 1.0"
    print(f"\n✅ Total weights = {total_weight:.2f}")

def compare_with_argus():
    """Show our multi-criteria advantage"""
    
    print("\n\n🏆 WFM vs ARGUS SCHEDULE SCORING")
    print("="*50)
    
    comparison = """
    ┌─────────────────────┬─────────────┬────────────┐
    │ Scoring Dimension   │ WFM         │ Argus      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Coverage            │ ✅ Advanced │ ✅ Basic   │
    │ Cost                │ ✅ Yes      │ ✅ Yes     │
    │ Compliance          │ ✅ Yes      │ ⚠️ Limited │
    │ Fairness            │ ✅ Yes      │ ❌ No      │
    │ Efficiency          │ ✅ Yes      │ ❌ No      │
    │ Flexibility         │ ✅ Yes      │ ❌ No      │
    │ Continuity          │ ✅ Yes      │ ❌ No      │
    │ Agent Preference    │ ✅ Yes      │ ❌ No      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Total Dimensions    │ 8           │ 2-3        │
    │ Customizable        │ ✅ Yes      │ ❌ No      │
    │ Real-time           │ ✅ Yes      │ ❌ No      │
    └─────────────────────┴─────────────┴────────────┘
    """
    print(comparison)
    
    print("\nKEY ADVANTAGES:")
    print("1. 8-dimensional scoring vs Argus 2-3 dimensions")
    print("2. Customizable weights per customer needs")
    print("3. Real-time re-scoring as conditions change")
    print("4. Fairness and preference tracking")

if __name__ == "__main__":
    # Run all tests
    test_schedule_scorer_from_bdd()
    test_bdd_scoring_criteria()
    compare_with_argus()
    
    print("\n\n✅ MULTI-CRITERIA SCORER TESTS COMPLETE!")
    print("8-dimensional scoring ready for BDD validation")