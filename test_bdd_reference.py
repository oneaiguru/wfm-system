"""
Test script for BDD Reference Data Management API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date, timedelta
import time

BASE_URL = "http://localhost:8000/api/v1"

def test_work_rules():
    """Test work rules configuration endpoints"""
    print("\n=== Testing Work Rules Configuration ===")
    
    # Create work rule with rotation
    work_rule = {
        "rule_name": "Standard 5/2 Rotation",
        "mode": "with_rotation",
        "consider_holidays": True,
        "time_zone": "Europe/Moscow",
        "mandatory_shifts_by_day": False,
        "shift_patterns": [
            {
                "shift_type": "morning",
                "start_time": "09:00",
                "duration_hours": 8,
                "break_integration": True
            },
            {
                "shift_type": "afternoon",
                "start_time": "13:00",
                "duration_hours": 8,
                "break_integration": True
            }
        ],
        "rotation_patterns": [
            {
                "pattern_type": "simple",
                "pattern_code": "WWWWWRR",
                "description": "5 work days, 2 rest days",
                "demand_driven": False
            }
        ],
        "constraints": {
            "min_hours_between_shifts": 11,
            "max_consecutive_hours": 40,
            "max_consecutive_days": 6
        }
    }
    
    response = requests.post(f"{BASE_URL}/references/work-rules", json=work_rule)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created work rule: {data['rule_name']}")
        print(f"✓ ID: {data['id']}")
        print(f"✓ Mode: {data['mode']}")
        print(f"✓ Shift patterns: {len(data['shift_patterns'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)
    
    # Get all work rules
    response = requests.get(f"{BASE_URL}/references/work-rules")
    if response.status_code == 200:
        rules = response.json()
        print(f"✓ Retrieved {len(rules)} work rules")

def test_events():
    """Test events and activities configuration"""
    print("\n=== Testing Events Configuration ===")
    
    # Create training event
    training_event = {
        "training_config": {
            "event_name": "Weekly English Training",
            "regularity": "weekly",
            "weekdays": ["Monday", "Wednesday"],
            "time_interval": "14:00-16:00",
            "duration_minutes": 120,
            "participation_type": "Group",
            "participant_range": "5-10",
            "skill_requirement": "English Level B1+"
        }
    }
    
    response = requests.post(f"{BASE_URL}/references/events", json=training_event)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created event: {data['training_config']['event_name']}")
        print(f"✓ Type: {data['event_type']}")
        print(f"✓ Regularity: {data['training_config']['regularity']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Get all events
    response = requests.get(f"{BASE_URL}/references/events")
    if response.status_code == 200:
        events = response.json()
        print(f"✓ Retrieved {len(events)} events")

def test_vacation_schemes():
    """Test vacation schemes configuration"""
    print("\n=== Testing Vacation Schemes ===")
    
    # Create vacation scheme
    scheme = {
        "scheme_name": "Standard Annual Leave",
        "scheme_type": "standard_annual",
        "total_days": 28,
        "periods": 2,
        "minimum_block_days": 7,
        "maximum_block_days": 28,
        "notice_period_days": 14,
        "approval_chain": ["supervisor", "hr", "director"],
        "blackout_periods": [
            {"start": "12-15", "end": "12-31"},
            {"start": "06-01", "end": "06-15"}
        ],
        "carryover_allowed": False,
        "calculation_method": "calendar_days"
    }
    
    response = requests.post(f"{BASE_URL}/references/vacation-schemes", json=scheme)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created vacation scheme: {data['scheme_name']}")
        print(f"✓ Total days: {data['total_days']}")
        print(f"✓ Minimum block: {data['minimum_block_days']} days")
        scheme_id = data['id']
        
        # Update the scheme
        updated_scheme = scheme.copy()
        updated_scheme['scheme_name'] = "Enhanced Annual Leave"
        updated_scheme['total_days'] = 30
        
        response = requests.put(
            f"{BASE_URL}/references/vacation-schemes/{scheme_id}",
            json=updated_scheme
        )
        
        if response.status_code == 200:
            print("✓ Successfully updated vacation scheme")
        
        # Test deletion with validation
        response = requests.delete(
            f"{BASE_URL}/references/vacation-schemes/{scheme_id}",
            params={"action": "archive"}
        )
        
        if response.status_code == 200:
            print("✓ Successfully archived vacation scheme")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_absence_reasons():
    """Test absence reason configuration"""
    print("\n=== Testing Absence Reasons ===")
    
    # Create absence reason
    absence_reason = {
        "category": "SICK",
        "code": "SICK",
        "description": "Sick leave",
        "impact_on_schedule": "Unplanned replacement",
        "payroll_integration": "Paid/Unpaid based on policy",
        "advance_notice_required": "None",
        "documentation_required": "Yes",
        "approval_level": "Supervisor",
        "maximum_duration_days": 30,
        "frequency_limits": {
            "per_month": 2,
            "per_year": 10
        }
    }
    
    response = requests.post(f"{BASE_URL}/references/absence-reasons", json=absence_reason)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created absence reason: {data['code']} - {data['description']}")
        print(f"✓ Documentation required: {data['documentation_required']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Get all absence reasons
    response = requests.get(f"{BASE_URL}/references/absence-reasons")
    if response.status_code == 200:
        reasons = response.json()
        print(f"✓ Retrieved {len(reasons)} absence reasons")

def test_service_groups():
    """Test service groups configuration"""
    print("\n=== Testing Service Groups ===")
    
    # Create top-level service
    service = {
        "service_level": "top_level",
        "name": "Technical Support",
        "channel_type": "voice_inbound",
        "skill_requirements": ["technical_knowledge", "problem_solving"],
        "service_level_target": {"percentage": 80, "seconds": 20},
        "operating_hours": {
            "monday": "08:00-20:00",
            "tuesday": "08:00-20:00",
            "wednesday": "08:00-20:00",
            "thursday": "08:00-20:00",
            "friday": "08:00-18:00"
        }
    }
    
    response = requests.post(f"{BASE_URL}/references/service-groups", json=service)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created service: {data['name']}")
        print(f"✓ Channel: {data['channel_type']}")
        print(f"✓ SLA target: {data['service_level_target']['percentage']}% in {data['service_level_target']['seconds']} seconds")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_service_level_config():
    """Test 80/20 format service level configuration"""
    print("\n=== Testing Service Level Configuration ===")
    
    config = {
        "service_level_target": 80,
        "answer_time_target": 20,
        "threshold_warning": 75,
        "threshold_critical": 65,
        "measurement_period": "30min",
        "alert_frequency": "1min"
    }
    
    response = requests.post(f"{BASE_URL}/configuration/service-level-settings", json=config)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Configured service level: {data['service_level_target']}% in {data['answer_time_target']} seconds")
        print(f"✓ Warning threshold: {data['threshold_warning']}%")
        print(f"✓ Critical threshold: {data['threshold_critical']}%")
        print(f"✓ Achievability score: {data.get('achievability_score', 'N/A')}%")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_roles_permissions():
    """Test roles and permissions configuration"""
    print("\n=== Testing Roles and Permissions ===")
    
    # Create business role
    role = {
        "role_category": "business",
        "role_name": "Regional Manager",
        "scope": "geographic",
        "permissions": [
            "System_AccessForecastList",
            "System_AccessWorkerList",
            "System_ViewReports"
        ],
        "inherit_permissions": True
    }
    
    response = requests.post(f"{BASE_URL}/references/roles", json=role)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created role: {data['role_name']}")
        print(f"✓ Category: {data['role_category']}")
        print(f"✓ Permissions: {len(data['permissions'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Get all roles
    response = requests.get(f"{BASE_URL}/references/roles")
    if response.status_code == 200:
        roles = response.json()
        print(f"✓ Retrieved {len(roles)} roles")

def test_communication_channels():
    """Test communication channels configuration"""
    print("\n=== Testing Communication Channels ===")
    
    channel = {
        "channel_category": "Digital Channels",
        "channel_type": "email",
        "characteristics": "Asynchronous communication",
        "concurrent_handling": "multiple",
        "response_time_sla": {"hours": 4},
        "skill_requirements": ["written_communication", "email_etiquette"],
        "priority_level": 3
    }
    
    response = requests.post(f"{BASE_URL}/references/channels", json=channel)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created channel: {data['channel_type']}")
        print(f"✓ Concurrent handling: {data['concurrent_handling']}")
        print(f"✓ Response SLA: {data['response_time_sla']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_production_calendar():
    """Test production calendar and holidays"""
    print("\n=== Testing Production Calendar ===")
    
    calendar = {
        "calendar_year": 2025,
        "holidays": [
            {
                "holiday_name": "New Year's Day",
                "holiday_date": "2025-01-01",
                "holiday_type": "national",
                "is_working_day": False,
                "pay_rate_multiplier": 2.0,
                "regions": ["Moscow", "St. Petersburg"]
            },
            {
                "holiday_name": "Victory Day",
                "holiday_date": "2025-05-09",
                "holiday_type": "national",
                "is_working_day": False,
                "pay_rate_multiplier": 2.0,
                "regions": ["All"]
            }
        ],
        "pre_holiday_schedule_adjustment": True,
        "post_holiday_schedule_adjustment": True
    }
    
    response = requests.post(f"{BASE_URL}/references/calendars", json=calendar)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created calendar for year: {data['calendar_year']}")
        print(f"✓ Holidays configured: {len(data['holidays'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Get calendar for specific year
    response = requests.get(f"{BASE_URL}/references/calendars/2025")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved calendar with {len(data['holidays'])} holidays")

def test_agent_status_types():
    """Test agent status types configuration"""
    print("\n=== Testing Agent Status Types ===")
    
    status_type = {
        "status_name": "On Call",
        "status_category": "productive",
        "productivity_impact": "positive",
        "reporting_classification": "Revenue-generating",
        "maximum_duration_minutes": None,
        "approval_required": False,
        "auto_transition_enabled": True,
        "auto_transition_to": "After Call Work"
    }
    
    response = requests.post(f"{BASE_URL}/references/agent-status-types", json=status_type)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Created status type: {data['status_name']}")
        print(f"✓ Category: {data['status_category']}")
        print(f"✓ Productivity impact: {data['productivity_impact']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_absenteeism_calculation():
    """Test absenteeism percentage calculation"""
    print("\n=== Testing Absenteeism Calculation ===")
    
    response = requests.get(
        f"{BASE_URL}/references/absenteeism/calculate",
        params={
            "period_type": "monthly",
            "department_id": "DEPT001"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Period: {data['period_type']}")
        print(f"✓ Absenteeism rate: {data['absenteeism_rate']}%")
        print(f"✓ Trend: {data['trend_analysis']['direction']}")
        print(f"✓ Alert level: {data['threshold_status']['alert_level']}")
        print(f"✓ Action required: {data['threshold_status']['action_required']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_employment_rates():
    """Test monthly employment rates"""
    print("\n=== Testing Employment Rates ===")
    
    response = requests.get(
        f"{BASE_URL}/references/employment-rates/monthly",
        params={
            "year": 2025,
            "month": 1,
            "department_id": "DEPT001"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Period: {data['period']['month_name']} {data['period']['year']}")
        print(f"✓ Average rate: {data['summary']['average_rate']}%")
        print(f"✓ Total employees: {data['summary']['total_employees']}")
        print(f"✓ Compliance status: {data['summary']['compliance_status']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def run_all_tests():
    """Run all BDD reference data tests"""
    print("=" * 60)
    print("BDD Reference Data Management API Test Suite")
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
    test_work_rules()
    test_events()
    test_vacation_schemes()
    test_absence_reasons()
    test_service_groups()
    test_service_level_config()
    test_roles_permissions()
    test_communication_channels()
    test_production_calendar()
    test_agent_status_types()
    test_absenteeism_calculation()
    test_employment_rates()
    
    print("\n" + "=" * 60)
    print("✅ All BDD reference data tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()