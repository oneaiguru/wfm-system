"""
Test script for BDD Reporting and Analytics API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date, timedelta
import time

BASE_URL = "http://localhost:8000/api/v1"

def test_schedule_adherence_report():
    """Test schedule adherence report generation"""
    print("\n=== Testing Schedule Adherence Reports ===")
    
    # Generate report for last month
    period_start = (date.today() - timedelta(days=30)).isoformat()
    period_end = date.today().isoformat()
    
    payload = {
        "period_start": period_start,
        "period_end": period_end,
        "department": "Technical Support",
        "detail_level": "15-minute",
        "include_weekends": True,
        "show_exceptions": True
    }
    
    response = requests.post(f"{BASE_URL}/reports/schedule-adherence", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated adherence report: {data['report_id']}")
        print(f"✓ Department: {data['department']}")
        print(f"✓ Average adherence: {data['average_adherence']:.1f}%")
        print(f"✓ Total employees: {len(data['employees'])}")
        print(f"✓ Scheduled hours: {data['total_scheduled_hours']:.1f}")
        print(f"✓ Actual hours: {data['total_actual_hours']:.1f}")
        print(f"✓ Deviation: {data['total_deviation_hours']:.1f} hours")
        
        # Show breakdown
        print(f"✓ Productive hours: {data['productive_hours']:.1f}")
        print(f"✓ Auxiliary hours: {data['auxiliary_hours']:.1f}")
        print(f"✓ Break hours: {data['break_hours']:.1f}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_payroll_report():
    """Test payroll calculation with 1C ZUP integration"""
    print("\n=== Testing Payroll Reports with 1C ZUP ===")
    
    period_start = (date.today() - timedelta(days=30)).isoformat()
    period_end = date.today().isoformat()
    
    payload = {
        "mode": "1C_data",
        "period_start": period_start,
        "period_end": period_end,
        "period_type": "monthly",
        "department": "Technical Support"
    }
    
    response = requests.post(f"{BASE_URL}/reports/payroll", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated payroll report: {data['report_id']}")
        print(f"✓ Mode: {data['mode']}")
        print(f"✓ Period: {data['period_start']} to {data['period_end']}")
        print(f"✓ Integration status: {data['integration_status']}")
        print(f"✓ Total employees: {len(data['employees'])}")
        
        # Show 1C ZUP time codes summary
        print("\n  1C ZUP Time Codes Summary:")
        for code, details in data['time_code_summary'].items():
            print(f"  - {code}: {details['total_hours']:.1f} hours, {details['employee_count']} employees")
        
        # Show period totals
        print(f"\n  Period Totals:")
        print(f"  - Regular hours: {data['period_totals']['total_regular_hours']:.1f}")
        print(f"  - Overtime hours: {data['period_totals']['total_overtime_hours']:.1f}")
        print(f"  - Total cost: {data['period_totals']['total_cost']:.2f}")
        
        # Show sample employee
        if data['employees']:
            emp = data['employees'][0]
            print(f"\n  Sample employee ({emp['employee_id']}):")
            print(f"  - Total hours: {emp['total_hours']:.1f}")
            print(f"  - Time codes: {len(emp['time_codes'])}")
            for tc in emp['time_codes'][:3]:  # Show first 3
                print(f"    • {tc['code']} ({tc['russian_name']}): {tc['hours']:.1f}h")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_forecast_accuracy():
    """Test forecast accuracy analysis"""
    print("\n=== Testing Forecast Accuracy Analysis ===")
    
    response = requests.get(
        f"{BASE_URL}/reports/forecast-accuracy",
        params={
            "period_start": (date.today() - timedelta(days=30)).isoformat(),
            "period_end": date.today().isoformat(),
            "service_group": "Technical Support"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated forecast accuracy report: {data['report_id']}")
        
        # Show BDD-specified metrics
        metrics = data['overall_metrics']
        print(f"\n  Accuracy Metrics (BDD targets):")
        print(f"  - MAPE: {metrics['mape']:.1f}% (target < 15%)")
        print(f"  - WAPE: {metrics['wape']:.1f}% (target < 12%)")
        print(f"  - MFA: {metrics['mfa']:.1f}% (target > 85%)")
        print(f"  - WFA: {metrics['wfa']:.1f}% (target > 88%)")
        print(f"  - Bias: {metrics['bias']:.1f}% (target ±5%)")
        print(f"  - Tracking Signal: {metrics['tracking_signal']:.1f} (target ±4)")
        
        # Show drill-down data
        print(f"\n  Drill-down Analysis:")
        print(f"  - Interval data points: {len(data['interval_analysis'])}")
        print(f"  - Daily analysis: {len(data['daily_analysis'])} days")
        print(f"  - Weekly analysis: {len(data['weekly_analysis'])} weeks")
        print(f"  - Channel analysis: {len(data['channel_analysis'])} channels")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_kpi_dashboard():
    """Test KPI performance dashboard"""
    print("\n=== Testing KPI Dashboard ===")
    
    response = requests.get(f"{BASE_URL}/reports/kpi-dashboard")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated KPI dashboard: {data['dashboard_id']}")
        
        # Show all KPI categories from BDD
        kpi_categories = [
            ("Service Level", data['service_level']),
            ("Answer Time", data['answer_time']),
            ("Occupancy", data['occupancy']),
            ("Utilization", data['utilization']),
            ("Customer Satisfaction", data['customer_satisfaction']),
            ("First Call Resolution", data['first_call_resolution']),
            ("Schedule Adherence", data['adherence']),
            ("Shrinkage", data['shrinkage']),
            ("Forecast Accuracy", data['forecast_accuracy']),
            ("Forecast Bias", data['forecast_bias']),
            ("Cost per Contact", data['cost_per_contact']),
            ("Overtime %", data['overtime_percentage'])
        ]
        
        print("\n  KPI Performance (Current vs Target):")
        for name, kpi in kpi_categories:
            status_icon = "✓" if kpi['status'] == "on_target" else "⚠" if kpi['status'] == "warning" else "✗"
            trend_icon = "↗" if kpi['trend'] == "up" else "↘" if kpi['trend'] == "down" else "→"
            print(f"  {status_icon} {name}: {kpi['current_value']:.1f} vs {kpi['target_value']:.1f} {kpi['unit']} {trend_icon}")
        
        print(f"\n  Last refresh: {data['last_refresh']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_absence_analysis():
    """Test absence pattern analysis"""
    print("\n=== Testing Absence Analysis ===")
    
    response = requests.get(
        f"{BASE_URL}/reports/absence-analysis",
        params={
            "period_start": (date.today() - timedelta(days=90)).isoformat(),
            "period_end": date.today().isoformat(),
            "department": "Technical Support"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated absence analysis: {data['report_id']}")
        
        # Show planned vs unplanned absences
        print(f"\n  Planned Absences:")
        planned = data['planned_absences']
        print(f"  - Vacation hours: {planned['vacation_hours']:.1f}")
        print(f"  - Training hours: {planned['training_hours']:.1f}")
        print(f"  - Total cost: ${planned['total_cost']:.2f}")
        
        print(f"\n  Unplanned Absences:")
        unplanned = data['unplanned_absences']
        print(f"  - Sick leave frequency: {unplanned['sick_leave_frequency']:.1f}")
        print(f"  - Emergency hours: {unplanned['emergency_leave_hours']:.1f}")
        print(f"  - Total cost: ${unplanned['total_cost']:.2f}")
        
        # Show patterns
        print(f"\n  Absence Patterns:")
        for pattern in data['patterns']:
            print(f"  - {pattern['pattern_type']}: Impact {pattern['impact_score']:.0f}%")
            print(f"    Recommendation: {pattern['recommendation']}")
        
        # Show insights
        print(f"\n  Key Insights:")
        for insight in data['insights']:
            print(f"  - {insight['category']}: {insight['analysis']}")
            print(f"    Action: {insight['action']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_real_time_reporting():
    """Test real-time operational reporting"""
    print("\n=== Testing Real-time Reporting ===")
    
    response = requests.get(f"{BASE_URL}/reports/real-time")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Real-time metrics at: {data['timestamp']}")
        
        # Show current metrics
        metrics = data['current_metrics']
        print(f"\n  Current Operational Metrics:")
        print(f"  - Staffing: {metrics['staffing_percentage']:.1f}%")
        print(f"  - Service Level (80/20): {metrics['service_level_80_20']:.1f}%")
        print(f"  - Queue time: {metrics['average_queue_time']:.1f} minutes")
        print(f"  - Active agents: {metrics['active_agents']}")
        print(f"  - Calls in queue: {metrics['calls_in_queue']}")
        
        # Show system health
        health = data['system_health']
        print(f"\n  System Health:")
        print(f"  - Integration: {health['integration_status']}")
        print(f"  - Database: {health['database_status']}")
        print(f"  - API response: {health['api_response_time']:.0f}ms")
        
        # Show active alerts
        alerts = data['active_alerts']
        if alerts:
            print(f"\n  Active Alerts ({len(alerts)}):")
            for alert in alerts:
                print(f"  - {alert['type']}: {alert['condition']}")
                print(f"    Notification: {alert['notification']}")
        else:
            print(f"\n  ✓ No active alerts")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_overtime_analysis():
    """Test overtime usage analysis"""
    print("\n=== Testing Overtime Analysis ===")
    
    response = requests.get(
        f"{BASE_URL}/reports/overtime-analysis",
        params={
            "period_start": (date.today() - timedelta(days=30)).isoformat(),
            "period_end": date.today().isoformat(),
            "department": "Technical Support"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Generated overtime analysis")
        
        # Show overtime metrics
        metrics = data['overtime_metrics']
        print(f"\n  Overtime Metrics:")
        print(f"  - Total overtime: {metrics['total_overtime_hours']:.1f} hours")
        print(f"  - Department %: {metrics['department_overtime_percentage']:.1f}%")
        print(f"  - Average individual: {metrics['average_individual_overtime']:.1f} hours")
        print(f"  - Over threshold: {metrics['employees_over_threshold']} employees")
        
        # Show alert thresholds
        thresholds = data['alert_thresholds']
        print(f"\n  Alert Thresholds:")
        for threshold, value in thresholds.items():
            print(f"  - {threshold}: {value}")
        
        # Show optimization opportunities
        print(f"\n  Optimization Opportunities:")
        for opp in data['optimization_opportunities']:
            print(f"  - {opp['area']}: {opp['analysis']}")
            print(f"    Recommendation: {opp['recommendation']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_mobile_reporting():
    """Test mobile-optimized reports"""
    print("\n=== Testing Mobile Reports ===")
    
    response = requests.get(f"{BASE_URL}/reports/mobile")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Mobile dashboard loaded")
        
        # Show key metrics
        metrics = data['mobile_dashboard']['key_metrics']
        print(f"\n  Mobile Key Metrics:")
        for metric, details in metrics.items():
            print(f"  - {metric}: {details['value']} (status: {details['status']})")
        
        # Show quick actions
        actions = data['mobile_dashboard']['quick_actions']
        print(f"\n  Quick Actions:")
        for action in actions:
            print(f"  - {action['action']} ({action['icon']})")
        
        # Show mobile features
        features = data['mobile_features']
        enabled_features = [feature for feature, enabled in features.items() if enabled]
        print(f"\n  Mobile Features Enabled: {len(enabled_features)}")
        for feature in enabled_features:
            print(f"  ✓ {feature}")
        
        # Show performance
        performance = data['performance']
        print(f"\n  Mobile Performance:")
        for metric, value in performance.items():
            print(f"  - {metric}: {value}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def run_all_tests():
    """Run all BDD reporting and analytics tests"""
    print("=" * 60)
    print("BDD Reporting and Analytics API Test Suite")
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
    test_schedule_adherence_report()
    test_payroll_report()
    test_forecast_accuracy()
    test_kpi_dashboard()
    test_absence_analysis()
    test_real_time_reporting()
    test_overtime_analysis()
    test_mobile_reporting()
    
    print("\n" + "=" * 60)
    print("✅ All BDD reporting and analytics tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()