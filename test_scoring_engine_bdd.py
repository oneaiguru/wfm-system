#!/usr/bin/env python
"""
🔴🟢 TDD Test for Scoring Engine per BDD Line 55
From: 24-automatic-schedule-optimization.feature:55
"Scoring Engine | Multi-criteria decision | All metrics | Ranked suggestions | 1-2 seconds"
"""

import sys
import time
sys.path.insert(0, '.')

from src.algorithms.optimization.scoring_engine import ScoringEngine, RankedSuggestions, ScoringResult

def test_scoring_engine_bdd():
    """Test scoring engine per BDD requirements"""
    
    print("\n🏆 TESTING SCORING ENGINE (BDD Line 55)")
    print("="*70)
    print("BDD: Multi-criteria decision | All metrics | Ranked suggestions | 1-2 seconds")
    
    engine = ScoringEngine()
    
    # Test Case 1: Standard multi-criteria scoring
    print("\n📊 Test 1: Multi-Criteria Decision Scoring")
    
    # Multiple suggestions to score and rank (BDD input)
    suggestions = [
        {
            'id': 'SUGGESTION_001',
            'projected_metrics': {
                'coverage_gaps': 12,
                'peak_coverage': 87.8,
                'overtime_hours': 48
            },
            'skill_coverage': ['english', 'technical', 'spanish'],
            'compliance_violations': 0,
            'preference_match_rate': 85.0,
            'pattern_complexity': 'simple',
            'implementation_weeks': 2
        },
        {
            'id': 'SUGGESTION_002',
            'projected_metrics': {
                'coverage_gaps': 18,
                'peak_coverage': 84.2,
                'overtime_hours': 56
            },
            'skill_coverage': ['english', 'technical'],
            'compliance_violations': 1,
            'preference_match_rate': 78.0,
            'pattern_complexity': 'medium',
            'implementation_weeks': 1
        },
        {
            'id': 'SUGGESTION_003',
            'projected_metrics': {
                'coverage_gaps': 25,
                'peak_coverage': 82.1,
                'overtime_hours': 65
            },
            'skill_coverage': ['english'],
            'compliance_violations': 0,
            'preference_match_rate': 92.0,
            'pattern_complexity': 'complex',
            'implementation_weeks': 4
        }
    ]
    
    # All metrics (BDD input)
    all_metrics = {
        'current_state': {
            'coverage_gaps': 47,
            'peak_coverage': 72.4,
            'overtime_hours': 124
        },
        'required_skills': ['english', 'technical', 'spanish'],
        'business_constraints': {
            'max_overtime': 50,
            'min_coverage': 85
        }
    }
    
    # Run multi-criteria scoring
    start_time = time.time()
    result = engine.score_and_rank_suggestions(
        suggestions=suggestions,
        all_metrics=all_metrics
    )
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Processing time: {result.processing_time_ms:.1f}ms")
    print(f"Suggestions evaluated: {result.total_evaluated}")
    print(f"Confidence level: {result.confidence_level:.1f}%")
    print(f"Recommendation: {result.recommendation_summary}")
    
    print(f"\nRanked Suggestions:")
    for suggestion in result.suggestions:
        print(f"  {suggestion.ranking_position}. {suggestion.suggestion_id}: {suggestion.total_score:.1f}/100 ({suggestion.recommendation_level})")
    
    # BDD Validations
    assert result.processing_time_ms <= 2000, f"Processing time {result.processing_time_ms}ms exceeds 2s limit"
    bdd_compliant = result.processing_time_ms <= 2000
    print(f"BDD 1-2 second requirement: {'✅' if bdd_compliant else '❌'} {'Met' if bdd_compliant else 'Failed'}")
    
    # Multi-criteria decision validation
    assert result.total_evaluated == 3, "Should evaluate all suggestions"
    assert len(result.suggestions) == 3, "Should return all suggestions ranked"
    assert result.suggestions[0].ranking_position == 1, "Top suggestion should be ranked #1"
    assert result.suggestions[0].total_score >= result.suggestions[1].total_score, "Should be ranked by score"
    
    # Scoring transparency
    for suggestion in result.suggestions:
        assert len(suggestion.score_breakdown) > 0, "Should provide score breakdown"
        assert suggestion.coverage_score >= 0, "Should have coverage score"
        assert suggestion.cost_score >= 0, "Should have cost score"
        assert suggestion.compliance_score >= 0, "Should have compliance score"
        assert suggestion.implementation_score >= 0, "Should have implementation score"
    
    print("✅ PASS: Multi-criteria scoring generates ranked suggestions in required time")

def test_scoring_criteria_weights():
    """Test scoring criteria weights per BDD specifications"""
    
    print("\n\n⚖️ Test 2: Scoring Criteria Weights (40-30-20-10)")
    
    engine = ScoringEngine()
    
    # Test weight distribution
    weights = engine.scoring_weights
    print(f"Coverage Optimization: {weights[engine.scoring_weights.__class__.__dict__['COVERAGE_OPTIMIZATION']]}%" if hasattr(engine.scoring_weights.__class__, 'COVERAGE_OPTIMIZATION') else f"Coverage: {weights[list(weights.keys())[0]]}%")
    
    # Get actual keys from the weights dictionary
    weight_keys = list(weights.keys())
    weight_values = list(weights.values())
    
    print(f"Weights found: {weight_keys}")
    print(f"Values: {weight_values}")
    
    # Validate BDD weight requirements using enum values
    from src.algorithms.optimization.scoring_engine import ScoringCriteria
    assert weights[ScoringCriteria.COVERAGE_OPTIMIZATION] == 40.0, "Coverage should be 40% weight"
    assert weights[ScoringCriteria.COST_EFFICIENCY] == 30.0, "Cost should be 30% weight"
    assert weights[ScoringCriteria.COMPLIANCE_PREFERENCES] == 20.0, "Compliance should be 20% weight"
    assert weights[ScoringCriteria.IMPLEMENTATION_SIMPLICITY] == 10.0, "Implementation should be 10% weight"
    
    total_weight = sum(weights.values())
    assert abs(total_weight - 100.0) < 0.01, f"Total weight should be 100%, got {total_weight}%"
    
    print("✅ PASS: Scoring criteria weights match BDD specifications")

def test_score_breakdown_transparency():
    """Test detailed score breakdown for algorithm transparency"""
    
    print("\n\n🔍 Test 3: Score Breakdown Transparency")
    
    engine = ScoringEngine()
    
    # Single suggestion with clear metrics
    suggestions = [
        {
            'projected_metrics': {
                'coverage_gaps': 5,    # 89% reduction from 47
                'peak_coverage': 90.0, # Excellent peak coverage
                'overtime_hours': 20   # 84% reduction from 124
            },
            'skill_coverage': ['english', 'technical', 'spanish'],
            'compliance_violations': 0,
            'preference_match_rate': 95.0,
            'pattern_complexity': 'simple',
            'implementation_weeks': 1
        }
    ]
    
    all_metrics = {
        'current_state': {
            'coverage_gaps': 47,
            'peak_coverage': 72.4,
            'overtime_hours': 124
        },
        'required_skills': ['english', 'technical', 'spanish']
    }
    
    result = engine.score_and_rank_suggestions(suggestions, all_metrics)
    suggestion = result.suggestions[0]
    
    print(f"Total Score: {suggestion.total_score:.1f}/100")
    print(f"Score Breakdown:")
    
    for breakdown in suggestion.score_breakdown:
        print(f"  {breakdown.component.value}: {breakdown.points_earned:.1f}/{breakdown.max_points:.1f}")
        print(f"    Method: {breakdown.calculation_method}")
        print(f"    Result: {breakdown.explanation}")
    
    # Validate score components
    assert len(suggestion.score_breakdown) >= 6, "Should have multiple score components"
    
    # Check specific components exist
    components = [b.component.value for b in suggestion.score_breakdown]
    assert 'gap_reduction' in components, "Should score gap reduction"
    assert 'peak_coverage' in components, "Should score peak coverage"
    assert 'overtime_reduction' in components, "Should score overtime reduction"
    assert 'labor_law_compliance' in components, "Should score compliance"
    
    # High-performing suggestion should score well
    assert suggestion.total_score >= 75, f"High-performing suggestion should score ≥75, got {suggestion.total_score}"
    
    print("✅ PASS: Score breakdown provides transparency")

def test_ranking_accuracy():
    """Test ranking accuracy with different suggestion profiles"""
    
    print("\n\n📈 Test 4: Ranking Accuracy")
    
    engine = ScoringEngine()
    
    # Suggestions with clear performance differences
    suggestions = [
        {
            'name': 'Poor Performance',
            'projected_metrics': {
                'coverage_gaps': 45,   # Minimal improvement
                'peak_coverage': 75.0, # Below target
                'overtime_hours': 120  # High overtime
            },
            'skill_coverage': ['english'],
            'compliance_violations': 3,
            'preference_match_rate': 45.0,
            'pattern_complexity': 'complex',
            'implementation_weeks': 6
        },
        {
            'name': 'Excellent Performance',
            'projected_metrics': {
                'coverage_gaps': 8,    # 83% improvement
                'peak_coverage': 92.0, # Excellent
                'overtime_hours': 25   # 80% reduction
            },
            'skill_coverage': ['english', 'technical', 'spanish'],
            'compliance_violations': 0,
            'preference_match_rate': 88.0,
            'pattern_complexity': 'simple',
            'implementation_weeks': 2
        },
        {
            'name': 'Good Performance',
            'projected_metrics': {
                'coverage_gaps': 15,   # 68% improvement
                'peak_coverage': 86.0, # Good
                'overtime_hours': 40   # 68% reduction
            },
            'skill_coverage': ['english', 'technical'],
            'compliance_violations': 1,
            'preference_match_rate': 75.0,
            'pattern_complexity': 'medium',
            'implementation_weeks': 3
        }
    ]
    
    all_metrics = {
        'current_state': {
            'coverage_gaps': 47,
            'peak_coverage': 72.4,
            'overtime_hours': 124
        },
        'required_skills': ['english', 'technical', 'spanish']
    }
    
    result = engine.score_and_rank_suggestions(suggestions, all_metrics)
    
    print(f"Ranking Results:")
    for suggestion in result.suggestions:
        print(f"  {suggestion.ranking_position}. Score: {suggestion.total_score:.1f} - {suggestion.recommendation_level}")
    
    # Validate ranking logic
    scores = [s.total_score for s in result.suggestions]
    assert scores == sorted(scores, reverse=True), "Suggestions should be ranked by score (highest first)"
    
    # Excellent performance should rank #1
    top_suggestion = result.suggestions[0]
    assert top_suggestion.total_score >= 75, f"Excellent suggestion should score ≥75, got {top_suggestion.total_score}"
    assert top_suggestion.recommendation_level in ["Highly Recommended", "Recommended", "Consider"], f"Top suggestion should be recommended, got {top_suggestion.recommendation_level}"
    
    # Poor performance should rank last
    bottom_suggestion = result.suggestions[-1]
    assert bottom_suggestion.total_score <= 40, f"Poor suggestion should score ≤40, got {bottom_suggestion.total_score}"
    
    print("✅ PASS: Ranking accurately reflects suggestion quality")

def test_performance_requirement():
    """Test 1-2 second processing requirement"""
    
    print("\n\n⚡ Test 5: Performance Requirement (1-2 seconds)")
    
    engine = ScoringEngine()
    
    # Large number of suggestions to test performance
    suggestions = []
    for i in range(20):  # 20 suggestions
        suggestions.append({
            'projected_metrics': {
                'coverage_gaps': 10 + (i % 15),
                'peak_coverage': 80 + (i % 15),
                'overtime_hours': 30 + (i % 50)
            },
            'skill_coverage': ['english', 'technical'][:(i % 2) + 1],
            'compliance_violations': i % 3,
            'preference_match_rate': 60 + (i % 35),
            'pattern_complexity': ['simple', 'medium', 'complex'][i % 3],
            'implementation_weeks': (i % 4) + 1
        })
    
    all_metrics = {
        'current_state': {
            'coverage_gaps': 47,
            'peak_coverage': 72.4,
            'overtime_hours': 124
        },
        'required_skills': ['english', 'technical', 'spanish']
    }
    
    start_time = time.time()
    result = engine.score_and_rank_suggestions(suggestions, all_metrics)
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Large scenario processing: {actual_time:.1f}ms")
    print(f"BDD requirement: ≤2000ms")
    print(f"Within range: {actual_time <= 2000}")
    print(f"Suggestions processed: {result.total_evaluated}")
    print(f"Top score: {result.suggestions[0].total_score:.1f}")
    
    # Performance validation
    assert actual_time <= 2000, f"Too slow: {actual_time}ms > 2000ms"
    assert result.total_evaluated == 20, "Should process all suggestions"
    assert len(result.suggestions) == 20, "Should return all suggestions ranked"
    
    print("✅ PASS: Performance meets BDD requirement")

def test_confidence_assessment():
    """Test confidence level calculation"""
    
    print("\n\n🎯 Test 6: Confidence Assessment")
    
    engine = ScoringEngine()
    
    # High confidence scenario (clear winner)
    high_confidence_suggestions = [
        {
            'projected_metrics': {'coverage_gaps': 5, 'peak_coverage': 95, 'overtime_hours': 15},
            'skill_coverage': ['english', 'technical', 'spanish'],
            'compliance_violations': 0,
            'preference_match_rate': 95,
            'pattern_complexity': 'simple',
            'implementation_weeks': 1
        },
        {
            'projected_metrics': {'coverage_gaps': 30, 'peak_coverage': 78, 'overtime_hours': 80},
            'skill_coverage': ['english'],
            'compliance_violations': 2,
            'preference_match_rate': 60,
            'pattern_complexity': 'complex',
            'implementation_weeks': 5
        }
    ]
    
    all_metrics = {
        'current_state': {'coverage_gaps': 47, 'peak_coverage': 72.4, 'overtime_hours': 124},
        'required_skills': ['english', 'technical', 'spanish']
    }
    
    result = engine.score_and_rank_suggestions(high_confidence_suggestions, all_metrics)
    
    print(f"Confidence level: {result.confidence_level:.1f}%")
    print(f"Score gap: {result.suggestions[0].total_score - result.suggestions[1].total_score:.1f} points")
    print(f"Recommendation: {result.recommendation_summary}")
    
    # High confidence expected due to large score gap
    assert result.confidence_level >= 80, f"Should have high confidence, got {result.confidence_level}%"
    
    # Clear recommendation expected
    assert "recommendation" in result.recommendation_summary.lower(), "Should provide clear recommendation"
    
    print("✅ PASS: Confidence assessment working")

def test_bdd_compliance_validation():
    """Test full BDD compliance"""
    
    print("\n\n✅ Test 7: Full BDD Compliance")
    
    engine = ScoringEngine()
    
    suggestions = [
        {
            'projected_metrics': {'coverage_gaps': 10, 'peak_coverage': 88, 'overtime_hours': 35},
            'skill_coverage': ['english', 'technical'],
            'compliance_violations': 0,
            'preference_match_rate': 82,
            'pattern_complexity': 'medium',
            'implementation_weeks': 2
        }
    ]
    
    all_metrics = {
        'current_state': {'coverage_gaps': 47, 'peak_coverage': 72.4, 'overtime_hours': 124},
        'required_skills': ['english', 'technical']
    }
    
    result = engine.score_and_rank_suggestions(suggestions, all_metrics)
    validation = engine.validate_bdd_requirements(result)
    
    print("BDD Requirement Validation:")
    for requirement, passed in validation.items():
        status = "✅" if passed else "❌"
        print(f"  {status} {requirement}")
    
    # All requirements should pass
    all_passed = all(validation.values())
    assert all_passed, f"BDD requirements failed: {validation}"
    
    print("✅ PASS: All BDD requirements validated")

def compare_with_argus():
    """Show scoring engine advantage"""
    
    print("\n\n🏆 SCORING ENGINE vs ARGUS")
    print("="*70)
    
    comparison = """
    ┌─────────────────────┬─────────────┬────────────┐
    │ Capability          │ WFM         │ Argus      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Multi-Criteria      │ ✅ 8 factors│ ❌ Manual  │
    │ Automated Ranking   │ ✅ Smart    │ ❌ None    │
    │ Score Transparency  │ ✅ Detailed │ ❌ Opaque  │
    │ Confidence Assessment│ ✅ Auto     │ ❌ None    │
    │ Processing Speed    │ ✅ 1-2 sec  │ ❓ Unknown │
    │ Recommendation Level│ ✅ Graded   │ ❌ Binary  │
    │ Weight Customization│ ✅ Flexible │ ❌ Fixed   │
    └─────────────────────┴─────────────┴────────────┘
    """
    print(comparison)
    
    print("\nBDD ADVANTAGES:")
    print("1. Multi-criteria decision system (8 scoring factors)")
    print("2. Automated ranking with confidence assessment")
    print("3. Transparent score breakdown and methodology")
    print("4. Customizable criteria weights per business needs")
    print("5. Real-time processing with sub-2-second response")

if __name__ == "__main__":
    # Run all BDD tests
    test_scoring_engine_bdd()
    test_scoring_criteria_weights()
    test_score_breakdown_transparency()
    test_ranking_accuracy()
    test_performance_requirement()
    test_confidence_assessment()
    test_bdd_compliance_validation()
    compare_with_argus()
    
    print("\n\n✅ SCORING ENGINE BDD TESTS COMPLETE!")
    print("All requirements from line 55 validated")