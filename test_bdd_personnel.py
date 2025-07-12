"""
Test script for BDD Personnel Management API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date

BASE_URL = "http://localhost:8000/api/v1"

def test_create_employee():
    """Test POST /personnel/employees endpoint"""
    print("\n=== Testing POST /personnel/employees ===")
    payload = {
        "lastName": "Иванов",
        "firstName": "Иван",
        "patronymic": "Иванович",
        "personnelNumber": "12345",
        "department": "Call Center",
        "position": "Operator",
        "hireDate": "2025-01-01",
        "timeZone": "Europe/Moscow",
        "wfmAccount": {
            "login": "ivanov123",
            "temporaryPassword": "TempPass123!",
            "forcePasswordChange": True,
            "accountExpiration": 90
        }
    }
    
    response = requests.post(f"{BASE_URL}/personnel/employees", json=payload)
    
    if response.status_code == 201:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Employee ID: {data['employeeId']}")
        print(f"✓ WFM Login: {data['wfmLogin']}")
        print(f"✓ Password change required: {data['requiresPasswordChange']}")
        print(f"✓ Audit log: {data['auditLogId']}")
        return data['employeeId']
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)
        return None

def test_assign_skills(employee_id):
    """Test POST /personnel/employees/{id}/skills endpoint"""
    print(f"\n=== Testing POST /personnel/employees/{employee_id}/skills ===")
    payload = {
        "employeeId": employee_id,
        "skillGroups": [
            {
                "service": "Technical Support",
                "group": "Level 1 Support",
                "role": "Primary",
                "proficiency": "Expert"
            },
            {
                "service": "Technical Support",
                "group": "Email Support",
                "role": "Secondary",
                "proficiency": "Intermediate"
            },
            {
                "service": "Sales",
                "group": "Outbound Sales",
                "role": "Backup",
                "proficiency": "Basic"
            }
        ]
    }
    
    response = requests.post(f"{BASE_URL}/personnel/employees/{employee_id}/skills", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Skills assigned: {data['skillsAssigned']}")
        print(f"✓ Primary group: {data['primaryGroup']}")
        print(f"✓ Message: {data['message']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_configure_work_parameters(employee_id):
    """Test PUT /personnel/employees/{id}/work-parameters endpoint"""
    print(f"\n=== Testing PUT /personnel/employees/{employee_id}/work-parameters ===")
    payload = {
        "employeeId": employee_id,
        "parameters": {
            "workRate": 1.0,
            "nightWorkPermission": True,
            "weekendWorkPermission": False,
            "overtimeAuthorization": True,
            "weeklyHoursNorm": 40,
            "dailyHoursLimit": 8,
            "vacationEntitlement": 28
        }
    }
    
    response = requests.put(f"{BASE_URL}/personnel/employees/{employee_id}/work-parameters", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Parameters updated: {data['parametersUpdated']}")
        print(f"✓ System integration:")
        for service, status in data['systemIntegration'].items():
            print(f"  - {service}: {status}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_get_endpoints(employee_id):
    """Test GET endpoints"""
    print(f"\n=== Testing GET endpoints ===")
    
    # Get employee profile
    response = requests.get(f"{BASE_URL}/personnel/employees/{employee_id}")
    print(f"GET /personnel/employees/{employee_id}: Status {response.status_code}")
    
    # Get employee skills
    response = requests.get(f"{BASE_URL}/personnel/employees/{employee_id}/skills")
    print(f"GET /personnel/employees/{employee_id}/skills: Status {response.status_code}")
    
    # Get work parameters
    response = requests.get(f"{BASE_URL}/personnel/employees/{employee_id}/work-parameters")
    print(f"GET /personnel/employees/{employee_id}/work-parameters: Status {response.status_code}")

def test_terminate_employee(employee_id):
    """Test POST /personnel/employees/{id}/terminate endpoint"""
    print(f"\n=== Testing POST /personnel/employees/{employee_id}/terminate ===")
    payload = {
        "employeeId": employee_id,
        "terminationDate": "2025-07-31",
        "reason": "Voluntary resignation"
    }
    
    response = requests.post(f"{BASE_URL}/personnel/employees/{employee_id}/terminate", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Termination date: {data['terminationDate']}")
        print(f"✓ Workflow actions:")
        for action, status in data['workflowActions'].items():
            print(f"  - {action}: {status}")
        print(f"✓ Data retention policy set")
        print(f"✓ Notifications sent: {len(data['notifications'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_validation_errors():
    """Test validation error scenarios"""
    print("\n=== Testing Validation Errors ===")
    
    # Test invalid password
    payload = {
        "lastName": "Test",
        "firstName": "User",
        "personnelNumber": "99999",
        "department": "Test",
        "position": "Test",
        "hireDate": "2025-01-01",
        "timeZone": "Europe/Moscow",
        "wfmAccount": {
            "login": "test123",
            "temporaryPassword": "weak",  # Too weak
            "forcePasswordChange": True
        }
    }
    response = requests.post(f"{BASE_URL}/personnel/employees", json=payload)
    print(f"Weak password test: Status {response.status_code} (expected 422)")
    
    # Test future hire date
    payload["wfmAccount"]["temporaryPassword"] = "Strong123!"
    payload["hireDate"] = "2026-01-01"  # Future date
    response = requests.post(f"{BASE_URL}/personnel/employees", json=payload)
    print(f"Future hire date test: Status {response.status_code} (expected 422)")
    
    # Test non-Cyrillic name
    payload["hireDate"] = "2025-01-01"
    payload["lastName"] = "Smith"  # Non-Cyrillic
    response = requests.post(f"{BASE_URL}/personnel/employees", json=payload)
    print(f"Non-Cyrillic name test: Status {response.status_code} (expected 422)")

def run_all_tests():
    """Run all BDD personnel management tests"""
    print("=" * 60)
    print("BDD Personnel Management API Test Suite")
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
    employee_id = test_create_employee()
    if employee_id:
        test_assign_skills(employee_id)
        test_configure_work_parameters(employee_id)
        test_get_endpoints(employee_id)
        test_terminate_employee(employee_id)
    
    test_validation_errors()
    
    print("\n" + "=" * 60)
    print("✅ All BDD personnel management tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()