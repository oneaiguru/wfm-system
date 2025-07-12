"""
Test script for BDD Employee Requests API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date, timedelta

BASE_URL = "http://localhost:8000/api/v1"

def test_create_time_off_request():
    """Test POST /requests/time-off endpoint"""
    print("\n=== Testing POST /requests/time-off ===")
    
    # Test different request types
    request_types = [
        ("больничный", "Sick leave request"),
        ("отгул", "Time off request"),
        ("внеочередной отпуск", "Unscheduled vacation request")
    ]
    
    for request_type, description in request_types:
        payload = {
            "requestType": request_type,
            "startDate": (date.today() + timedelta(days=7)).isoformat(),
            "endDate": (date.today() + timedelta(days=10)).isoformat(),
            "reason": f"Test {description}",
            "comments": "Testing BDD implementation"
        }
        
        response = requests.post(
            f"{BASE_URL}/requests/time-off",
            json=payload,
            params={"employee_id": "EMP001"}
        )
        
        if response.status_code == 201:
            data = response.json()
            print(f"✓ {request_type}: Status {response.status_code}")
            print(f"  Request ID: {data['requestId']}")
            print(f"  Status: {data['status']}")
        else:
            print(f"✗ {request_type}: Failed with status {response.status_code}")
            print(response.text)
    
    return True

def test_create_shift_exchange_request():
    """Test POST /requests/shift-exchange endpoint"""
    print("\n=== Testing POST /requests/shift-exchange ===")
    
    payload = {
        "originalShiftId": "SHIFT-12345",
        "originalShiftDate": (date.today() + timedelta(days=5)).isoformat(),
        "targetEmployeeId": "EMP002",
        "proposedDate": (date.today() + timedelta(days=8)).isoformat(),
        "proposedTime": "14:00-22:00",
        "comments": "Family emergency, need to swap shifts"
    }
    
    response = requests.post(
        f"{BASE_URL}/requests/shift-exchange",
        json=payload,
        params={"employee_id": "EMP001"}
    )
    
    if response.status_code == 201:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Request ID: {data['requestId']}")
        print(f"✓ Type: {data['requestType']}")
        print(f"✓ Status: {data['status']}")
        return data['requestId']
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)
        return None

def test_accept_shift_exchange(request_id):
    """Test POST /requests/{id}/accept-exchange endpoint"""
    print(f"\n=== Testing POST /requests/{request_id}/accept-exchange ===")
    
    response = requests.post(
        f"{BASE_URL}/requests/{request_id}/accept-exchange",
        params={"employee_id": "EMP002"}
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Request status: {data['status']}")
        print(f"✓ Accepted by: {data['acceptedBy']}")
        print(f"✓ Message: {data['message']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_approve_request():
    """Test POST /requests/{id}/approve endpoint with 1C ZUP integration"""
    print("\n=== Testing POST /requests/{id}/approve with 1C ZUP ===")
    
    request_id = "REQ-TEST123"
    
    # Test approval
    payload = {
        "requestId": request_id,
        "decision": "approve",
        "supervisorComments": "Approved for BDD testing"
    }
    
    response = requests.post(
        f"{BASE_URL}/requests/{request_id}/approve",
        json=payload,
        params={"supervisor_id": "SUP001"}
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Request status: {data['status']}")
        print(f"✓ Schedule updated: {data['scheduleUpdated']}")
        
        if data.get('zupIntegration'):
            print(f"✓ 1C ZUP Integration:")
            print(f"  - Success: {data['zupIntegration']['success']}")
            print(f"  - Document ID: {data['zupIntegration']['documentId']}")
            print(f"  - Confirmation: {data['zupIntegration']['confirmationNumber']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)
    
    # Test rejection
    print("\n--- Testing rejection ---")
    payload['decision'] = "reject"
    payload['supervisorComments'] = "Insufficient notice period"
    
    response = requests.post(
        f"{BASE_URL}/requests/{request_id}/approve",
        json=payload,
        params={"supervisor_id": "SUP001"}
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Request status: {data['status']}")
        print(f"✓ No 1C ZUP integration for rejection: {data.get('zupIntegration') is None}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_get_requests():
    """Test GET /requests endpoint with filters"""
    print("\n=== Testing GET /requests ===")
    
    # Test different filter combinations
    test_cases = [
        {"name": "All requests", "params": {}},
        {"name": "By employee", "params": {"employee_id": "EMP001"}},
        {"name": "By status", "params": {"status": "Создана"}},
        {"name": "By type", "params": {"request_type": "отгул"}},
        {"name": "Available only", "params": {"available": "true"}}
    ]
    
    for test in test_cases:
        response = requests.get(f"{BASE_URL}/requests", params=test["params"])
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ {test['name']}: {len(data)} requests found")
        else:
            print(f"✗ {test['name']}: Failed with status {response.status_code}")

def test_request_status_tracking():
    """Test GET /requests/{id}/status endpoint"""
    print("\n=== Testing GET /requests/{id}/status ===")
    
    request_id = "REQ-12345678"
    response = requests.get(f"{BASE_URL}/requests/{request_id}/status")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Request ID: {data['requestId']}")
        print(f"✓ Type: {data['requestType']}")
        print(f"✓ Current status: {data['status']}")
        print(f"✓ Status history: {len(data['statusHistory'])} entries")
        
        # Show status progression
        print("\n  Status progression:")
        for entry in data['statusHistory']:
            print(f"  - {entry['status']} at {entry['timestamp']} by {entry['actor']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_1c_zup_integration():
    """Test POST /integration/1c-zup/send-fact-work-time endpoint"""
    print("\n=== Testing POST /integration/1c-zup/send-fact-work-time ===")
    
    payload = {
        "requestId": "REQ-TEST123",
        "employeeId": "EMP001",
        "documentType": "Time off deviation document",
        "timeType": "NV",
        "absencePeriod": {
            "startDate": date.today().isoformat(),
            "endDate": (date.today() + timedelta(days=2)).isoformat()
        }
    }
    
    response = requests.post(
        f"{BASE_URL}/integration/1c-zup/send-fact-work-time",
        json=payload
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Success: {data['success']}")
        print(f"✓ Message: {data['message']}")
        print(f"✓ 1C ZUP Response:")
        print(f"  - Document ID: {data['zupResponse']['documentId']}")
        print(f"  - Status: {data['zupResponse']['status']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_validation_errors():
    """Test validation error scenarios"""
    print("\n=== Testing Validation Errors ===")
    
    # Test invalid date range
    payload = {
        "requestType": "отгул",
        "startDate": date.today().isoformat(),
        "endDate": (date.today() - timedelta(days=1)).isoformat(),  # End before start
        "reason": "Invalid dates"
    }
    
    response = requests.post(
        f"{BASE_URL}/requests/time-off",
        json=payload,
        params={"employee_id": "EMP001"}
    )
    
    print(f"Invalid date range test: Status {response.status_code} (expected 422)")

def run_all_tests():
    """Run all BDD employee requests tests"""
    print("=" * 60)
    print("BDD Employee Requests API Test Suite")
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
    test_create_time_off_request()
    shift_exchange_id = test_create_shift_exchange_request()
    
    if shift_exchange_id:
        test_accept_shift_exchange(shift_exchange_id)
    
    test_approve_request()
    test_get_requests()
    test_request_status_tracking()
    test_1c_zup_integration()
    test_validation_errors()
    
    print("\n" + "=" * 60)
    print("✅ All BDD employee requests tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()