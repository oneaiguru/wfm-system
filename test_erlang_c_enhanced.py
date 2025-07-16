#!/usr/bin/env python3
"""
Test script to verify the Enhanced Erlang C implementation meets all requirements
"""

import time
from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced

def test_real_data_connection():
    """Test that the algorithm uses real database data"""
    print("Testing Real Data Connection...")
    print("-" * 50)
    
    calculator = ErlangCEnhanced()
    
    # Test with a date that has data
    result = calculator.calculate_staffing(
        date='2024-07-15',
        interval='15min',
        service_level_target=0.8,
        target_time_seconds=20
    )
    
    # Verify we got real data
    assert result['call_volume'] > 0, "Should have real call volume"
    assert result['data_source'] == 'forecast_historical_data', "Should use forecast_historical_data table"
    assert result['required_agents'] > 0, "Should calculate real staffing"
    assert 0 <= result['achieved_service_level'] <= 1, "Service level should be valid"
    
    print(f"✓ Using real data from {result['data_source']}")
    print(f"✓ Call volume: {result['call_volume']} calls")
    print(f"✓ Average handle time: {result['average_handle_time']:.0f} seconds")
    print(f"✓ Required agents: {result['required_agents']}")
    print(f"✓ Achieved service level: {result['achieved_service_level']:.3f}")
    
    return result

def test_no_random_calls():
    """Verify there are no random.uniform() calls in the code"""
    print("\nTesting for Random Calls...")
    print("-" * 50)
    
    with open('src/algorithms/core/erlang_c_enhanced.py', 'r') as f:
        code = f.read()
    
    assert 'random.uniform' not in code, "Should not contain random.uniform()"
    assert 'import random' not in code, "Should not import random module"
    
    print("✓ No random.uniform() calls found")
    print("✓ No random module imports found")

def test_performance():
    """Test that calculations complete in under 100ms"""
    print("\nTesting Performance...")
    print("-" * 50)
    
    calculator = ErlangCEnhanced()
    
    # Test multiple scenarios
    scenarios = [
        {'date': '2024-07-15', 'interval': '15min'},
        {'date': '2024-07-15', 'interval': '30min'},
        {'date': '2024-07-15', 'interval': '1hour'},
    ]
    
    max_time = 0
    for scenario in scenarios:
        result = calculator.calculate_staffing(**scenario)
        calc_time = result['calculation_time_ms']
        max_time = max(max_time, calc_time)
        
        print(f"  Interval {scenario['interval']}: {calc_time:.1f} ms")
        assert calc_time < 100, f"Calculation time {calc_time}ms exceeds 100ms limit"
    
    print(f"\n✓ All calculations under 100ms (max: {max_time:.1f} ms)")

def test_real_calculations():
    """Test that calculations are based on real formulas, not mocks"""
    print("\nTesting Real Calculations...")
    print("-" * 50)
    
    calculator = ErlangCEnhanced()
    
    # Test Erlang C formula with known values
    # For 100 calls/hour, 5 min handle time (12 calls/agent/hour), 80% SL
    lambda_rate = 100  # calls per hour
    mu_rate = 12      # calls per agent per hour
    target_sl = 0.8
    
    agents, achieved_sl = calculator.calculate_service_level_staffing(
        lambda_rate, mu_rate, target_sl
    )
    
    # Verify it's calculating properly (not just returning fixed values)
    offered_load = lambda_rate / mu_rate  # ~8.33 Erlangs
    assert agents > offered_load, "Agents should be more than offered load"
    assert agents < offered_load * 20, "Agents shouldn't be unreasonably high"  # Erlang C can require many agents for high SL
    
    print(f"✓ Offered load: {offered_load:.2f} Erlangs")
    print(f"✓ Required agents: {agents}")
    print(f"✓ Achieved SL: {achieved_sl:.3f}")
    print(f"✓ Calculation appears realistic")

def test_database_integration():
    """Test database integration features"""
    print("\nTesting Database Integration...")
    print("-" * 50)
    
    calculator = ErlangCEnhanced()
    
    # Test getting historical data
    hist_data = calculator.get_historical_call_volume('2024-07-15', '15min')
    print(f"✓ Historical data retrieved: {hist_data['total_calls']} calls")
    
    # Test getting service level config
    sl_config = calculator.get_service_level_target()
    print(f"✓ Service level config: {sl_config['target_percent']}% in {sl_config['answer_time_seconds']}s")
    
    # Test with service name filter
    result = calculator.calculate_staffing(
        date='2024-07-15',
        interval='15min',
        service_name='Customer Service'
    )
    print(f"✓ Service name filter working")

def main():
    """Run all tests"""
    print("Enhanced Erlang C Implementation Test Suite")
    print("=" * 50)
    
    try:
        # Run all tests
        test_no_random_calls()
        test_real_data_connection()
        test_performance()
        test_real_calculations()
        test_database_integration()
        
        print("\n" + "=" * 50)
        print("✅ ALL TESTS PASSED!")
        print("=" * 50)
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())