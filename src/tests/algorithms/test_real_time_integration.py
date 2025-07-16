#!/usr/bin/env python3
"""
Test script for real-time Erlang C integration with WFM Enterprise database
Validates Mobile Workforce Scheduler pattern implementation
"""

import asyncio
import logging
import json
import sys
import os
from datetime import datetime

# Add the current directory to Python path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from real_time_erlang_c import RealTimeErlangC, QueueState
from db_connector import WFMDatabaseConnector, DatabaseConfig

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_database_connection():
    """Test basic database connectivity"""
    print("=" * 60)
    print("Testing Database Connection")
    print("=" * 60)
    
    try:
        connector = WFMDatabaseConnector()
        await connector.connect()
        
        health = await connector.health_check()
        print(f"Database Status: {health['status']}")
        print(f"Database: {health.get('database', 'Unknown')}")
        print(f"Queue Services: {health.get('queue_services', 0)}")
        print(f"Total Agents: {health.get('total_agents', 0)}")
        print(f"Queue Last Update: {health.get('queue_last_update', 'Unknown')}")
        print(f"Agent Last Update: {health.get('agent_last_update', 'Unknown')}")
        
        await connector.disconnect()
        return True
        
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False

async def test_queue_metrics():
    """Test real-time queue metrics retrieval"""
    print("\n" + "=" * 60)
    print("Testing Queue Metrics Retrieval")
    print("=" * 60)
    
    try:
        connector = WFMDatabaseConnector()
        await connector.connect()
        
        # Get all queue metrics
        metrics = await connector.get_real_time_queue_metrics()
        print(f"Found {len(metrics)} active queues:")
        
        for metric in metrics[:5]:  # Show first 5
            print(f"\nService ID: {metric['service_id']}")
            print(f"  Calls Waiting: {metric['calls_waiting']}")
            print(f"  Agents Available: {metric['agents_available']}")
            print(f"  Agents Busy: {metric['agents_busy']}")
            print(f"  Current SL: {metric['current_service_level']}%")
            print(f"  Longest Wait: {metric['longest_wait_time']}s")
            print(f"  Last Updated: {metric['last_updated']}")
        
        await connector.disconnect()
        return len(metrics) > 0
        
    except Exception as e:
        print(f"Queue metrics test failed: {e}")
        return False

async def test_agent_availability():
    """Test agent availability data"""
    print("\n" + "=" * 60)
    print("Testing Agent Availability")
    print("=" * 60)
    
    try:
        connector = WFMDatabaseConnector()
        await connector.connect()
        
        availability = await connector.get_agent_availability()
        print(f"Agent Status Summary:")
        print(f"  Total Agents: {availability['total_agents']}")
        print(f"  Available: {availability['available']}")
        print(f"  Busy: {availability['busy']}")
        print(f"  On Break: {availability['break']}")
        print(f"  Unavailable: {availability['unavailable']}")
        
        print(f"\nDetailed Status Breakdown:")
        for status, data in availability['by_status'].items():
            print(f"  {status}: {data['count']} agents ({data['available_for_contact']} available for contact)")
        
        await connector.disconnect()
        return True
        
    except Exception as e:
        print(f"Agent availability test failed: {e}")
        return False

async def test_real_time_erlang_c():
    """Test real-time Erlang C calculations with database data"""
    print("\n" + "=" * 60)
    print("Testing Real-Time Erlang C Calculations")
    print("=" * 60)
    
    try:
        # Initialize real-time calculator
        calculator = RealTimeErlangC()
        
        # Get real queue states
        queue_states = await calculator.get_all_active_queues()
        print(f"Retrieved {len(queue_states)} queue states from database")
        
        if not queue_states:
            print("No queue states available for testing")
            return False
        
        # Test calculations for first few queues
        for i, state in enumerate(queue_states[:3]):
            print(f"\n--- Queue {i+1}: {state.service_name} (ID: {state.service_id}) ---")
            print(f"Current State:")
            print(f"  Calls Waiting: {state.calls_waiting}")
            print(f"  Agents Available: {state.agents_available}")
            print(f"  Agents Busy: {state.agents_busy}")
            print(f"  Service Level: {state.service_level:.1f}%")
            print(f"  Target SL: {state.target_service_level:.1f}%")
            print(f"  Avg Wait Time: {state.avg_wait_time:.1f}s")
            print(f"  Abandonment Rate: {state.abandonment_rate:.3f}")
            print(f"  Avg Handle Time: {state.avg_handle_time:.1f}s")
            
            # Calculate recommendations
            params = {
                'call_volume': max(state.calls_waiting * 4, state.calls_handled_last_15min),
                'target_service_level': state.target_service_level / 100.0,
                'target_time': 20
            }
            
            recommendation = calculator.calculate_with_queue_state(params, state)
            
            print(f"\nRecommendation:")
            print(f"  Required Agents: {recommendation.required_agents}")
            print(f"  Current Agents: {recommendation.current_agents}")
            print(f"  Gap: {recommendation.gap}")
            print(f"  Urgency: {recommendation.urgency}")
            print(f"  Confidence: {recommendation.confidence:.3f}")
            print(f"  Actions:")
            for action in recommendation.actions[:3]:
                print(f"    • {action}")
            
            print(f"  Predicted Impact:")
            for metric, value in recommendation.predicted_impact.items():
                print(f"    {metric}: {value}")
        
        return True
        
    except Exception as e:
        print(f"Real-time Erlang C test failed: {e}")
        return False

async def test_comprehensive_status():
    """Test comprehensive workforce status"""
    print("\n" + "=" * 60)
    print("Testing Comprehensive Workforce Status")
    print("=" * 60)
    
    try:
        calculator = RealTimeErlangC()
        status = await calculator.get_comprehensive_workforce_status()
        
        if 'error' in status:
            print(f"Error getting status: {status['error']}")
            return False
        
        print(f"Overall Status: {status['overall_status']}")
        print(f"Timestamp: {status['timestamp']}")
        
        summary = status['summary']
        print(f"\nSummary:")
        print(f"  Total Queues: {summary['total_queues']}")
        print(f"  Available Agents: {summary['total_agents_available']}")
        print(f"  Busy Agents: {summary['total_agents_busy']}")
        print(f"  Break Agents: {summary['total_agents_break']}")
        print(f"  Total Gap: {summary['total_gap']}")
        print(f"  Critical Queues: {summary['critical_queues']}")
        print(f"  Avg Service Level: {summary['avg_service_level']:.1f}%")
        
        print(f"\nImmediate Actions:")
        for action in status['recommendations']['immediate_actions'][:5]:
            print(f"  • {action}")
        
        print(f"\nStrategic Actions:")
        for action in status['recommendations']['strategic_actions'][:3]:
            print(f"  • {action}")
        
        return True
        
    except Exception as e:
        print(f"Comprehensive status test failed: {e}")
        return False

async def test_monitoring_callback(service_id, recommendation, state):
    """Callback function for monitoring test"""
    print(f"\n[MONITORING] Service {service_id} ({state.service_name})")
    print(f"  Gap: {recommendation.gap}, Urgency: {recommendation.urgency}")
    print(f"  SL: {state.service_level:.1f}%, Waiting: {state.calls_waiting}")

async def test_real_time_monitoring():
    """Test real-time monitoring with database"""
    print("\n" + "=" * 60)
    print("Testing Real-Time Monitoring (30 seconds)")
    print("=" * 60)
    
    try:
        calculator = RealTimeErlangC()
        
        # Get first active service for testing
        queue_states = await calculator.get_all_active_queues()
        if not queue_states:
            print("No active queues for monitoring test")
            return False
        
        service_id = queue_states[0].service_id
        print(f"Monitoring service {service_id} for 30 seconds...")
        
        # Start monitoring task
        monitoring_task = asyncio.create_task(
            calculator.monitor_queue_real_time(
                service_id, 
                test_monitoring_callback,
                monitoring_interval=10  # 10 second intervals
            )
        )
        
        # Run for 30 seconds
        await asyncio.sleep(30)
        
        # Cancel monitoring
        monitoring_task.cancel()
        
        try:
            await monitoring_task
        except asyncio.CancelledError:
            pass
        
        print("Monitoring test completed successfully")
        return True
        
    except Exception as e:
        print(f"Real-time monitoring test failed: {e}")
        return False

async def run_all_tests():
    """Run comprehensive test suite"""
    print("WFM Enterprise Real-Time Erlang C Integration Test")
    print("Mobile Workforce Scheduler Pattern Validation")
    print("=" * 60)
    
    tests = [
        ("Database Connection", test_database_connection),
        ("Queue Metrics", test_queue_metrics),
        ("Agent Availability", test_agent_availability),
        ("Real-Time Erlang C", test_real_time_erlang_c),
        ("Comprehensive Status", test_comprehensive_status),
        ("Real-Time Monitoring", test_real_time_monitoring)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        try:
            print(f"\n{'='*60}")
            print(f"Running: {test_name}")
            print(f"{'='*60}")
            
            result = await test_func()
            results[test_name] = "PASS" if result else "FAIL"
            
        except Exception as e:
            print(f"Test {test_name} failed with exception: {e}")
            results[test_name] = "ERROR"
    
    # Print summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"{'='*60}")
    
    for test_name, result in results.items():
        status_symbol = "✓" if result == "PASS" else "✗"
        print(f"{status_symbol} {test_name}: {result}")
    
    passed = sum(1 for r in results.values() if r == "PASS")
    total = len(results)
    
    print(f"\nOverall Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Real-time integration is working correctly.")
    else:
        print("⚠️  Some tests failed. Check database connection and data availability.")

if __name__ == "__main__":
    asyncio.run(run_all_tests())