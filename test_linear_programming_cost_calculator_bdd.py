#!/usr/bin/env python
"""
🔴🟢 TDD Test for Linear Programming Cost Calculator per BDD Line 54
From: 24-automatic-schedule-optimization.feature:54
"Cost Calculator | Linear programming | Staffing costs + overtime | Financial impact | 1-2 seconds"
"""

import sys
import time
sys.path.insert(0, '.')

from src.algorithms.optimization.linear_programming_cost_calculator import LinearProgrammingCostCalculator, FinancialImpact

def test_linear_programming_cost_calculator_bdd():
    """Test linear programming cost calculator per BDD requirements"""
    
    print("\n💰 TESTING LINEAR PROGRAMMING COST CALCULATOR (BDD Line 54)")
    print("="*70)
    print("BDD: Linear programming | Staffing costs + overtime | Financial impact | 1-2 seconds")
    
    calculator = LinearProgrammingCostCalculator()
    
    # Test Case 1: Standard scenario with overtime
    print("\n📊 Test 1: Staffing Costs + Overtime Calculation")
    
    # Staffing plan with regular and overtime hours (BDD input)
    staffing_plan = {
        'agents': [
            {
                'id': 'AGENT_001',
                'skill_level': 'senior',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '19:00',  # 10 hours = 2 overtime
                        'hours': 10.0
                    }
                ]
            },
            {
                'id': 'AGENT_002', 
                'skill_level': 'junior',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '10:00',
                        'end_time': '18:00',  # 8 hours = no overtime
                        'hours': 8.0
                    }
                ]
            },
            {
                'id': 'AGENT_003',
                'skill_level': 'specialist',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '08:00',
                        'end_time': '20:00',  # 12 hours = 4 overtime
                        'hours': 12.0
                    }
                ]
            }
        ]
    }
    
    # Schedule requirements for optimization
    schedule_requirements = {
        '09:00': 15,
        '10:00': 20,
        '14:00': 25,
        '16:00': 18,
        '18:00': 12
    }
    
    # Optimization constraints
    constraints = {
        'max_overtime_percentage': 15,
        'budget_limit': 5000,
        'min_coverage': 10
    }
    
    # Run linear programming cost calculation
    start_time = time.time()
    result = calculator.calculate_financial_impact(
        staffing_plan=staffing_plan,
        schedule_requirements=schedule_requirements,
        optimization_constraints=constraints
    )
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Processing time: {result.processing_time_ms:.1f}ms")
    print(f"Total labor cost: ${result.total_labor_cost:.2f}")
    print(f"Regular time cost: ${result.regular_time_cost:.2f}")
    print(f"Overtime cost: ${result.overtime_cost:.2f}")
    print(f"Premium cost: ${result.premium_cost:.2f}")
    print(f"ROI projection: {result.roi_projection:.1f}%")
    print(f"Cost breakdown items: {len(result.cost_breakdown)}")
    print(f"Savings opportunities: {len(result.savings_opportunities)}")
    
    # BDD Validations
    assert result.processing_time_ms <= 2000, f"Processing time {result.processing_time_ms}ms exceeds 2s limit"
    bdd_compliant = result.processing_time_ms <= 2000
    print(f"BDD 1-2 second requirement: {'✅' if bdd_compliant else '❌'} {'Met' if bdd_compliant else 'Failed'}")
    
    # Financial impact validation
    assert result.total_labor_cost > 0, "Should calculate total labor cost"
    assert result.regular_time_cost > 0, "Should calculate regular time cost"
    assert result.overtime_cost > 0, "Should calculate overtime cost (has 10+12 hour shifts)"
    assert len(result.cost_breakdown) > 0, "Should provide cost breakdown"
    assert isinstance(result.cost_per_interval, dict), "Should provide cost per interval"
    assert len(result.savings_opportunities) > 0, "Should identify savings opportunities"
    assert len(result.optimization_recommendations) > 0, "Should provide optimization recommendations"
    
    print("✅ PASS: Linear programming calculates financial impact in required time")

def test_overtime_cost_calculation():
    """Test overtime cost calculation specifically"""
    
    print("\n\n⏰ Test 2: Overtime Cost Analysis")
    
    calculator = LinearProgrammingCostCalculator()
    
    # High overtime scenario
    staffing_plan = {
        'agents': [
            {
                'id': 'OVERTIME_001',
                'skill_level': 'senior',  # $30/hour
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '06:00',
                        'end_time': '20:00',  # 14 hours = 6 overtime
                        'hours': 14.0
                    }
                ]
            }
        ]
    }
    
    requirements = {'12:00': 5}
    
    result = calculator.calculate_financial_impact(staffing_plan, requirements)
    
    # Expected: 8 regular hours * $30 + 6 overtime hours * $30 * 1.5 = $240 + $270 = $510
    expected_regular = 8 * 30  # $240
    expected_overtime = 6 * 30 * 1.5  # $270
    expected_total = expected_regular + expected_overtime  # $510
    
    print(f"Expected regular: ${expected_regular:.2f}")
    print(f"Actual regular: ${result.regular_time_cost:.2f}")
    print(f"Expected overtime: ${expected_overtime:.2f}")
    print(f"Actual overtime: ${result.overtime_cost:.2f}")
    print(f"Expected total: ${expected_total:.2f}")
    print(f"Actual total: ${result.total_labor_cost:.2f}")
    
    # Validate overtime calculations (allow small variance)
    assert abs(result.regular_time_cost - expected_regular) < 1, f"Regular cost mismatch: {result.regular_time_cost} vs {expected_regular}"
    assert abs(result.overtime_cost - expected_overtime) < 1, f"Overtime cost mismatch: {result.overtime_cost} vs {expected_overtime}"
    assert abs(result.total_labor_cost - expected_total) < 1, f"Total cost mismatch: {result.total_labor_cost} vs {expected_total}"
    
    print("✅ PASS: Overtime calculations accurate")

def test_linear_programming_optimization():
    """Test linear programming optimization functionality"""
    
    print("\n\n🔧 Test 3: Linear Programming Optimization")
    
    calculator = LinearProgrammingCostCalculator()
    
    # Multiple agents scenario for optimization
    staffing_plan = {
        'agents': [
            {
                'id': f'LP_AGENT_{i:03d}',
                'skill_level': 'junior' if i % 2 == 0 else 'senior',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '17:00',
                        'hours': 8.0
                    }
                ]
            }
            for i in range(20)
        ]
    }
    
    requirements = {
        '09:00': 8, '10:00': 10, '11:00': 12, '12:00': 12,
        '13:00': 10, '14:00': 15, '15:00': 12, '16:00': 8
    }
    
    constraints = {
        'max_overtime_percentage': 10,
        'budget_limit': 4000,
        'optimization_goal': 'cost_minimization'
    }
    
    result = calculator.calculate_financial_impact(staffing_plan, requirements, constraints)
    
    print(f"ROI projection: {result.roi_projection:.1f}%")
    print(f"Cost intervals: {len(result.cost_per_interval)}")
    print(f"Optimization recommendations: {len(result.optimization_recommendations)}")
    
    # Linear programming should provide optimization benefits
    assert result.roi_projection >= 0, "Should show non-negative ROI projection"
    assert len(result.cost_per_interval) > 0, "Should provide interval cost breakdown"
    assert len(result.optimization_recommendations) > 0, "Should provide optimization recommendations"
    
    print("✅ PASS: Linear programming optimization working")

def test_savings_opportunities():
    """Test savings opportunity identification"""
    
    print("\n\n💡 Test 4: Savings Opportunity Identification")
    
    calculator = LinearProgrammingCostCalculator()
    
    # Scenario with clear savings opportunities
    staffing_plan = {
        'agents': [
            {
                'id': 'EXPENSIVE_001',
                'skill_level': 'supervisor',  # $40/hour
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '08:00',
                        'end_time': '22:00',  # 14 hours = lots of overtime
                        'hours': 14.0
                    }
                ]
            },
            {
                'id': 'EXPENSIVE_002',
                'skill_level': 'supervisor',  # $40/hour
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '07:00',
                        'end_time': '19:00',  # 12 hours = overtime
                        'hours': 12.0
                    }
                ]
            }
        ]
    }
    
    requirements = {'12:00': 2}
    
    result = calculator.calculate_financial_impact(staffing_plan, requirements)
    
    print(f"Savings opportunities found: {len(result.savings_opportunities)}")
    for opportunity in result.savings_opportunities:
        print(f"  • {opportunity}")
    
    print(f"Optimization recommendations: {len(result.optimization_recommendations)}")
    for rec in result.optimization_recommendations:
        print(f"  • {rec}")
    
    # Should identify overtime and cost savings
    assert len(result.savings_opportunities) > 0, "Should identify savings opportunities"
    assert any('overtime' in opp.lower() for opp in result.savings_opportunities), "Should identify overtime savings"
    assert any('cost' in opp.lower() or 'savings' in opp.lower() for opp in result.savings_opportunities), "Should identify cost savings"
    
    print("✅ PASS: Savings opportunities properly identified")

def test_performance_requirement():
    """Test 1-2 second processing requirement"""
    
    print("\n\n⚡ Test 5: Performance Requirement (1-2 seconds)")
    
    calculator = LinearProgrammingCostCalculator()
    
    # Large scenario to test performance
    staffing_plan = {
        'agents': [
            {
                'id': f'PERF_{i:03d}',
                'skill_level': ['junior', 'senior', 'specialist', 'supervisor'][i % 4],
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': f"{8 + (i % 8):02d}:00",
                        'end_time': f"{16 + (i % 8):02d}:00",
                        'hours': 8.0 + (i % 4)  # Some overtime
                    }
                ]
            }
            for i in range(100)  # Large dataset
        ]
    }
    
    requirements = {f"{h:02d}:00": 10 + (h % 8) for h in range(6, 22)}
    
    constraints = {
        'max_overtime_percentage': 15,
        'budget_limit': 50000,
        'optimization_aggressiveness': 8
    }
    
    start_time = time.time()
    result = calculator.calculate_financial_impact(staffing_plan, requirements, constraints)
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Large scenario processing: {actual_time:.1f}ms")
    print(f"BDD requirement: ≤2000ms")
    print(f"Within range: {actual_time <= 2000}")
    print(f"Total agents processed: {len(staffing_plan['agents'])}")
    print(f"Cost breakdown items: {len(result.cost_breakdown)}")
    
    # Performance validation
    assert actual_time <= 2000, f"Too slow: {actual_time}ms > 2000ms"
    assert result.total_labor_cost > 0, "Should calculate costs for large scenario"
    
    print("✅ PASS: Performance meets BDD requirement")

def test_bdd_compliance_validation():
    """Test full BDD compliance"""
    
    print("\n\n✅ Test 6: Full BDD Compliance")
    
    calculator = LinearProgrammingCostCalculator()
    
    staffing_plan = {
        'agents': [
            {
                'id': 'COMPLY_001',
                'skill_level': 'junior',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '18:00',
                        'hours': 9.0  # 1 hour overtime
                    }
                ]
            }
        ]
    }
    
    requirements = {'14:00': 1}
    
    result = calculator.calculate_financial_impact(staffing_plan, requirements)
    validation = calculator.validate_bdd_requirements(result)
    
    print("BDD Requirement Validation:")
    for requirement, passed in validation.items():
        status = "✅" if passed else "❌"
        print(f"  {status} {requirement}")
    
    # All requirements should pass
    all_passed = all(validation.values())
    assert all_passed, f"BDD requirements failed: {validation}"
    
    print("✅ PASS: All BDD requirements validated")

def compare_with_argus():
    """Show linear programming advantage"""
    
    print("\n\n🏆 LINEAR PROGRAMMING vs ARGUS")
    print("="*70)
    
    comparison = """
    ┌─────────────────────┬─────────────┬────────────┐
    │ Capability          │ WFM         │ Argus      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Cost Optimization   │ ✅ LP Model │ ❌ Manual  │
    │ Overtime Analysis   │ ✅ Auto     │ ❌ Basic   │
    │ Financial Impact    │ ✅ Complete │ ❌ Limited │
    │ Savings Opportunities│ ✅ AI-based │ ❌ None    │
    │ ROI Projections     │ ✅ Advanced │ ❌ Basic   │
    │ Processing Speed    │ ✅ 1-2 sec  │ ❓ Unknown │
    │ Multi-criteria Cost │ ✅ Complex  │ ❌ Simple  │
    └─────────────────────┴─────────────┴────────────┘
    """
    print(comparison)
    
    print("\nBDD ADVANTAGES:")
    print("1. Linear programming for cost optimization")
    print("2. Automated overtime and premium calculations")  
    print("3. Comprehensive financial impact analysis")
    print("4. AI-powered savings opportunity identification")
    print("5. Real-time ROI projections and recommendations")

if __name__ == "__main__":
    # Run all BDD tests
    test_linear_programming_cost_calculator_bdd()
    test_overtime_cost_calculation()
    test_linear_programming_optimization()
    test_savings_opportunities()
    test_performance_requirement()
    test_bdd_compliance_validation()
    compare_with_argus()
    
    print("\n\n✅ LINEAR PROGRAMMING COST CALCULATOR BDD TESTS COMPLETE!")
    print("All requirements from line 54 validated")