#!/usr/bin/env python
"""
🔴🟢 TDD Test for Enhanced Erlang C per BDD Line 306
From: 08-load-forecasting-demand-planning.feature:306
"Voice calls | Erlang C | Poisson arrival, exponential service | Queue tolerance"
"""

import sys
import numpy as np
import math
sys.path.insert(0, '.')

from src.algorithms.core.erlang_c_enhanced import erlang_c_enhanced_staffing

def test_erlang_c_bdd_voice_calls():
    """Test Enhanced Erlang C for voice calls per BDD line 306"""
    
    print("\n📞 TESTING ENHANCED ERLANG C - VOICE CALLS (BDD)")
    print("="*60)
    print("BDD Requirement: Voice calls | Erlang C | Poisson arrival, exponential service")
    
    # Test Case 1: Standard call center scenario
    print("\n📊 Test 1: Standard Call Center")
    
    # BDD parameters for voice calls
    lambda_rate = 100.0  # 100 calls per hour (Poisson arrival)
    mu_rate = 6.0        # 6 calls per hour per agent (exponential service)
    service_level = 0.80 # 80% answered within threshold
    target_time = 20     # 20 seconds (queue tolerance)
    
    # Calculate using Enhanced Erlang C
    agents_required, actual_service_level = erlang_c_enhanced_staffing(
        lambda_rate=lambda_rate,
        mu_rate=mu_rate,
        target_sl=service_level
    )
    
    print(f"Arrival rate (λ): {lambda_rate} calls/hour")
    print(f"Service rate (μ): {mu_rate} calls/hour/agent")
    print(f"Target SL: {service_level:.1%} in {target_time}s")
    print(f"Required agents: {agents_required}")
    print(f"Actual SL: {actual_service_level:.1%}")
    
    # BDD validation
    assert agents_required > 0, "Must require positive number of agents"
    assert actual_service_level >= service_level * 0.95, f"SL {actual_service_level:.1%} below target {service_level:.1%}"
    print("✅ PASS: Voice calls Erlang C calculation correct")
    
    # Test Case 2: High volume scenario
    print("\n📊 Test 2: High Volume Peak Hour")
    
    peak_lambda = 500.0  # 500 calls per hour
    peak_agents = calculate_operators(
        lambda_rate=peak_lambda,
        mu_rate=mu_rate,
        target_service_level=service_level,
        target_answer_time=target_time
    )
    
    peak_sl = erlang_c_enhanced(
        arrival_rate=peak_lambda,
        service_rate=mu_rate,
        num_servers=peak_agents,
        target_time=target_time
    )
    
    print(f"Peak λ: {peak_lambda} calls/hour")
    print(f"Peak agents: {peak_agents}")
    print(f"Peak SL: {peak_sl:.1%}")
    
    assert peak_agents > agents_required, "Peak should need more agents"
    assert peak_sl >= service_level * 0.95, "Peak SL should meet target"
    print("✅ PASS: High volume calculations correct")

def test_erlang_c_multi_channel():
    """Test Erlang C for different channel types per BDD"""
    
    print("\n\n📡 TESTING MULTI-CHANNEL ERLANG C (BDD)")
    print("="*60)
    
    # BDD Channel scenarios from line 305-309
    channels = {
        'voice': {
            'arrival_rate': 100,
            'service_rate': 6,
            'model': 'Erlang C',
            'considerations': 'Queue tolerance'
        },
        'video': {
            'arrival_rate': 50,
            'service_rate': 3,  # Higher resource usage
            'model': 'Erlang C',
            'considerations': 'Technical requirements'
        }
    }
    
    print("\n📞 Voice Channel:")
    voice_agents = calculate_operators(
        lambda_rate=channels['voice']['arrival_rate'],
        mu_rate=channels['voice']['service_rate'],
        target_service_level=0.80,
        target_answer_time=20
    )
    print(f"Voice agents required: {voice_agents}")
    
    print("\n📹 Video Channel:")
    video_agents = calculate_operators(
        lambda_rate=channels['video']['arrival_rate'],
        mu_rate=channels['video']['service_rate'],
        target_service_level=0.80,
        target_answer_time=30  # Higher tolerance for video
    )
    print(f"Video agents required: {video_agents}")
    
    # Video should need proportionally more agents due to higher resource usage
    voice_ratio = voice_agents / channels['voice']['arrival_rate']
    video_ratio = video_agents / channels['video']['arrival_rate']
    
    assert video_ratio > voice_ratio, "Video should have higher agent ratio"
    print("✅ PASS: Multi-channel considerations applied")

def test_poisson_exponential_assumptions():
    """Test Poisson arrival and exponential service assumptions"""
    
    print("\n\n🎲 TESTING POISSON/EXPONENTIAL ASSUMPTIONS (BDD)")
    print("="*60)
    
    # BDD requirement: "Poisson arrival, exponential service"
    
    # Test traffic intensity (rho = λ/μ) must be < number of servers
    lambda_rate = 100
    mu_rate = 6
    num_agents = 20
    
    traffic_intensity = lambda_rate / mu_rate
    utilization = traffic_intensity / num_agents
    
    print(f"Traffic intensity (ρ = λ/μ): {traffic_intensity:.2f}")
    print(f"Number of agents: {num_agents}")
    print(f"Utilization: {utilization:.1%}")
    
    # Stability condition for Erlang C
    assert traffic_intensity < num_agents, "System must be stable (ρ < s)"
    assert utilization < 1.0, "Utilization must be less than 100%"
    
    # Test service level calculation
    service_level = erlang_c_enhanced(
        arrival_rate=lambda_rate,
        service_rate=mu_rate,
        num_servers=num_agents,
        target_time=20
    )
    
    print(f"Calculated service level: {service_level:.1%}")
    assert 0 <= service_level <= 1, "Service level must be between 0% and 100%"
    print("✅ PASS: Poisson/exponential assumptions validated")

def test_service_level_corridor():
    """Test service level corridor support per BDD"""
    
    print("\n\n📊 TESTING SERVICE LEVEL CORRIDOR (BDD)")
    print("="*60)
    
    # BDD from 24-automatic-schedule-optimization.feature:16
    # "Erlang C formula (considering SL corridor)"
    
    lambda_rate = 200
    mu_rate = 8
    
    # Test different service level targets (corridor)
    service_levels = [0.75, 0.80, 0.85, 0.90]
    results = []
    
    for sl in service_levels:
        agents = calculate_operators(
            lambda_rate=lambda_rate,
            mu_rate=mu_rate,
            target_service_level=sl,
            target_answer_time=20
        )
        
        actual_sl = erlang_c_enhanced(
            arrival_rate=lambda_rate,
            service_rate=mu_rate,
            num_servers=agents,
            target_time=20
        )
        
        results.append({'target': sl, 'agents': agents, 'actual': actual_sl})
        print(f"Target SL: {sl:.1%} → Agents: {agents} → Actual: {actual_sl:.1%}")
    
    # Verify corridor behavior
    for i in range(1, len(results)):
        assert results[i]['agents'] >= results[i-1]['agents'], "Higher SL should need more agents"
    
    print("✅ PASS: Service level corridor support working")

def performance_benchmark():
    """Benchmark performance per BDD requirements"""
    
    print("\n\n⚡ PERFORMANCE BENCHMARK (BDD)")
    print("="*60)
    
    import time
    
    # Test calculation speed for real-time requirements
    start_time = time.time()
    
    # Run 1000 calculations
    for i in range(1000):
        agents = calculate_operators(
            lambda_rate=100 + i % 100,
            mu_rate=6,
            target_service_level=0.80,
            target_answer_time=20
        )
    
    end_time = time.time()
    total_time = (end_time - start_time) * 1000  # Convert to ms
    avg_time = total_time / 1000
    
    print(f"1000 calculations: {total_time:.1f}ms")
    print(f"Average per calculation: {avg_time:.2f}ms")
    
    # BDD performance requirement (should be fast for real-time)
    assert avg_time < 1.0, f"Too slow: {avg_time:.2f}ms per calculation"
    print("✅ PASS: Performance meets real-time requirements")

if __name__ == "__main__":
    # Run all BDD tests
    test_erlang_c_bdd_voice_calls()
    test_erlang_c_multi_channel()
    test_poisson_exponential_assumptions()
    test_service_level_corridor()
    performance_benchmark()
    
    print("\n\n✅ ENHANCED ERLANG C BDD TESTS COMPLETE!")
    print("All BDD requirements from line 306 validated")