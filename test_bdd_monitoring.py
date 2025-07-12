"""
Test script for BDD Real-time Monitoring API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date, timedelta
import time

BASE_URL = "http://localhost:8000/api/v1"

def test_operational_dashboards():
    """Test GET /monitoring/operational-control endpoint"""
    print("\n=== Testing GET /monitoring/operational-control ===")
    
    response = requests.get(f"{BASE_URL}/monitoring/operational-control")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        
        # Check all 6 key metrics
        metrics = [
            "operators_online_percent",
            "load_deviation", 
            "operator_requirement",
            "sla_performance",
            "acd_rate",
            "aht_trend"
        ]
        
        for metric in metrics:
            if metric in data:
                m = data[metric]
                print(f"✓ {m['metric_name']}: {m['current_value']:.1f} - Status: {m['color_status']}")
        
        print(f"✓ Last refresh: {data['last_refresh']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_drill_down_analysis():
    """Test GET /monitoring/metrics/{metric_name}/drill-down endpoint"""
    print("\n=== Testing GET /monitoring/metrics/{metric_name}/drill-down ===")
    
    metric = "operators_online"
    response = requests.get(f"{BASE_URL}/monitoring/metrics/{metric}/drill-down")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Metric: {data['metric_name']}")
        print(f"✓ Schedule adherence entries: {len(data['schedule_adherence_24h'])}")
        print(f"✓ Online agents: {len(data['actually_online_agents'])}")
        print(f"✓ Deviation timeline: {len(data['deviation_timeline'])} entries")
        
        # Show timetable status
        print("\n  Timetable status:")
        for status, count in data['timetable_status'].items():
            print(f"  - {status}: {count}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_agent_status_monitoring():
    """Test GET /monitoring/agents/status endpoint"""
    print("\n=== Testing GET /monitoring/agents/status ===")
    
    # Test without filter
    response = requests.get(
        f"{BASE_URL}/monitoring/agents/status",
        params={"supervisor_id": "SUP001"}
    )
    
    if response.status_code == 200:
        agents = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Total agents: {len(agents)}")
        
        # Count by status
        status_counts = {}
        for agent in agents:
            status = agent['current_status']
            status_counts[status] = status_counts.get(status, 0) + 1
        
        print("\n  Agent status breakdown:")
        for status, count in status_counts.items():
            print(f"  - {status}: {count} agents")
        
        # Show sample agent details
        if agents:
            sample = agents[0]
            print(f"\n  Sample agent ({sample['agent_id']}):")
            print(f"  - Status: {sample['current_status']} ({sample['visual_indicator']})")
            print(f"  - Activity: {sample['current_activity']}")
            print(f"  - Actions: {', '.join(sample['available_actions'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Test with status filter
    print("\n--- Testing with status filter ---")
    response = requests.get(
        f"{BASE_URL}/monitoring/agents/status",
        params={
            "supervisor_id": "SUP001",
            "status_filter": "late_login"
        }
    )
    
    if response.status_code == 200:
        agents = response.json()
        print(f"✓ Filtered agents: {len(agents)} with late_login status")

def test_threshold_alerts():
    """Test GET /monitoring/alerts/threshold endpoint"""
    print("\n=== Testing GET /monitoring/alerts/threshold ===")
    
    # Test without filters
    response = requests.get(f"{BASE_URL}/monitoring/alerts/threshold")
    
    if response.status_code == 200:
        alerts = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Active alerts: {len(alerts)}")
        
        # Group by severity
        severity_counts = {}
        for alert in alerts:
            severity = alert['severity']
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        print("\n  Alerts by severity:")
        for severity, count in severity_counts.items():
            print(f"  - {severity}: {count} alerts")
        
        # Show critical alerts
        critical_alerts = [a for a in alerts if a['severity'] == 'critical']
        if critical_alerts:
            print(f"\n  Critical alerts ({len(critical_alerts)}):")
            for alert in critical_alerts[:2]:  # Show first 2
                print(f"  - {alert['alert_trigger']}")
                print(f"    Actions: {', '.join(alert['suggested_actions'][:2])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_predictive_alerts():
    """Test GET /monitoring/alerts/predictive endpoint"""
    print("\n=== Testing GET /monitoring/alerts/predictive ===")
    
    response = requests.get(f"{BASE_URL}/monitoring/alerts/predictive")
    
    if response.status_code == 200:
        alerts = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Predictive alerts: {len(alerts)}")
        
        for alert in alerts:
            print(f"\n  {alert['prediction_type']}:")
            print(f"  - Issue: {alert['predicted_issue']}")
            print(f"  - Lead time: {alert['lead_time_minutes']} minutes")
            print(f"  - Confidence: {alert['confidence_score']:.0f}%")
            print(f"  - Prevention: {alert['prevention_actions'][0]}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_operational_adjustments():
    """Test POST /monitoring/adjustments endpoint"""
    print("\n=== Testing POST /monitoring/adjustments ===")
    
    # Test call to workplace adjustment
    adjustment = {
        "adjustment_type": "call_to_workplace",
        "target_id": "AGENT015",
        "action": "Call absent operator to workplace",
        "parameters": {
            "urgency": "high",
            "reason": "Critical understaffing",
            "contact_method": "phone"
        }
    }
    
    response = requests.post(
        f"{BASE_URL}/monitoring/adjustments",
        json=adjustment
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Adjustment type: {data['adjustment_type']}")
        print(f"✓ Target: {data['target_id']}")
        print(f"✓ Estimated impact: {data['estimated_impact']}")
        
        # Show validation results
        validation = data['validation_result']
        print("\n  Validation results:")
        print(f"  - Labor compliance: {validation['labor_standards_compliance']['overtime_check']}")
        print(f"  - SLA risk: {validation['service_level_impact']['sla_risk']}")
        print(f"  - Cost impact: {validation['cost_implications']['budget_impact']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_multi_group_monitoring():
    """Test GET /monitoring/groups endpoint"""
    print("\n=== Testing GET /monitoring/groups ===")
    
    response = requests.get(f"{BASE_URL}/monitoring/groups")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Groups monitored: {len(data['groups'])}")
        
        # Show aggregate metrics
        agg = data['aggregate_metrics']
        print(f"\n  Aggregate metrics:")
        print(f"  - Overall operators online: {agg['total_operators_online']:.1f}%")
        print(f"  - Overall SLA: {agg['overall_sla']:.1f}%")
        print(f"  - Critical alerts: {agg['critical_alerts']}")
        print(f"  - Reallocation capacity: {agg['reallocation_capacity']} agents")
        
        # Show priority alerts
        if data['priority_alerts']:
            print(f"\n  Priority alerts: {len(data['priority_alerts'])}")
            for alert in data['priority_alerts']:
                print(f"  - {alert['group_id']}: {alert['alert']} ({alert['severity']})")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_historical_analysis():
    """Test GET /monitoring/historical/{period} endpoint"""
    print("\n=== Testing GET /monitoring/historical/{period} ===")
    
    periods = ["intraday", "daily", "weekly", "monthly"]
    
    for period in periods:
        print(f"\n--- Analyzing {period} patterns ---")
        response = requests.get(f"{BASE_URL}/monitoring/historical/{period}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Period: {period}")
            print(f"✓ Granularity: {data['data_analyzed']['granularity']}")
            print(f"✓ Patterns found: {len(data['data_analyzed']['patterns_found'])}")
            
            # Show first pattern
            if data['data_analyzed']['patterns_found']:
                pattern = data['data_analyzed']['patterns_found'][0]
                print(f"  - Pattern: {pattern['pattern']}")
                print(f"  - Impact: {pattern['impact']}")
                print(f"  - Recommendation: {pattern['recommendation']}")
        else:
            print(f"✗ Failed for {period}: {response.status_code}")

def test_integration_health():
    """Test GET /monitoring/integration/health endpoint"""
    print("\n=== Testing GET /monitoring/integration/health ===")
    
    response = requests.get(f"{BASE_URL}/monitoring/integration/health")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Overall health: {data['overall_health']}")
        print(f"✓ Integrations monitored: {len(data['integrations'])}")
        
        print("\n  Integration status:")
        for integration in data['integrations']:
            print(f"  - {integration['component']}: {integration['status']}")
        
        # Show data quality summary
        quality = data['data_quality_summary']
        print(f"\n  Data quality:")
        print(f"  - Completeness: {quality['overall_completeness']:.1f}%")
        print(f"  - Accuracy: {quality['overall_accuracy']:.1f}%")
        print(f"  - Anomalies: {quality['anomalies_detected']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_mobile_monitoring():
    """Test GET /monitoring/mobile endpoint"""
    print("\n=== Testing GET /monitoring/mobile ===")
    
    response = requests.get(f"{BASE_URL}/monitoring/mobile")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        
        # Show key metrics
        metrics = data['mobile_dashboard']['key_metrics']
        print("\n  Mobile dashboard metrics:")
        print(f"  - Operators online: {metrics['operators_online']['value']:.1f}% ({metrics['operators_online']['status']})")
        print(f"  - SLA: {metrics['sla_performance']['value']:.1f}% ({metrics['sla_performance']['status']})")
        print(f"  - Queue: {metrics['queue_size']['value']} ({metrics['queue_size']['status']})")
        print(f"  - Critical alerts: {metrics['critical_alerts']['count']}")
        
        # Show mobile features
        features = data['mobile_features']
        print("\n  Mobile features:")
        for feature, enabled in features.items():
            if enabled:
                print(f"  ✓ {feature}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def run_all_tests():
    """Run all BDD real-time monitoring tests"""
    print("=" * 60)
    print("BDD Real-time Monitoring API Test Suite")
    print("=" * 60)
    
    try:
        # Test connectivity
        response = requests.get(f"{BASE_URL.replace('/api/v1', '')}/health")
        if response.status_code != 200:
            print("⚠️  API server not responding on expected port")
            return
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API server")
        print("Please ensure the BDD test API is running")
        return
    
    # Run tests in sequence
    test_operational_dashboards()
    test_drill_down_analysis()
    test_agent_status_monitoring()
    test_threshold_alerts()
    test_predictive_alerts()
    test_operational_adjustments()
    test_multi_group_monitoring()
    test_historical_analysis()
    test_integration_health()
    test_mobile_monitoring()
    
    print("\n" + "=" * 60)
    print("✅ All BDD real-time monitoring tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()