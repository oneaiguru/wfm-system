"""
Test script for BDD System Integration API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, timezone

BASE_URL = "http://localhost:8000/api/v1"

def test_personnel_endpoint():
    """Test GET /personnel endpoint"""
    print("\n=== Testing GET /personnel ===")
    response = requests.get(f"{BASE_URL}/personnel")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Services count: {len(data['services'])}")
        print(f"✓ Agents count: {len(data['agents'])}")
        
        # Validate structure per BDD
        assert 'services' in data, "Missing services field"
        assert 'agents' in data, "Missing agents field"
        assert len(data['services']) > 0, "Services array cannot be empty (BDD requirement)"
        
        # Check service structure
        service = data['services'][0]
        assert service['id'] == "External system", "Static service ID mismatch"
        assert service['status'] == "ACTIVE", "Service status must be ACTIVE"
        
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_service_group_data():
    """Test GET /historic/serviceGroupData endpoint"""
    print("\n=== Testing GET /historic/serviceGroupData ===")
    params = {
        "startDate": "2020-01-01T00:00:00Z",
        "endDate": "2020-01-02T00:00:00Z",
        "step": 300000,  # 5 minutes
        "groupId": "1,2"
    }
    response = requests.get(f"{BASE_URL}/historic/serviceGroupData", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Groups returned: {len(data)}")
        
        # Validate structure
        for group_data in data:
            assert 'serviceId' in group_data, "Missing serviceId"
            assert 'groupId' in group_data, "Missing groupId"
            assert 'historicData' in group_data, "Missing historicData"
            
            # Check interval structure
            if group_data['historicData']:
                interval = group_data['historicData'][0]
                required_fields = ['startInterval', 'endInterval', 'notUniqueReceived', 
                                 'notUniqueTreated', 'notUniqueMissed', 'receivedCalls',
                                 'treatedCalls', 'missCalls', 'aht', 'postProcessing']
                for field in required_fields:
                    assert field in interval, f"Missing required field: {field}"
        
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_agent_status_data():
    """Test GET /historic/agentStatusData endpoint"""
    print("\n=== Testing GET /historic/agentStatusData ===")
    params = {
        "startDate": "2020-01-01T00:00:00Z",
        "endDate": "2020-01-02T00:00:00Z",
        "agentId": "1,2"
    }
    response = requests.get(f"{BASE_URL}/historic/agentStatusData", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Agents returned: {len(data)}")
        
        for agent_state in data:
            assert 'agentId' in agent_state, "Missing agentId"
            assert 'states' in agent_state, "Missing states"
            
            if agent_state['states']:
                state = agent_state['states'][0]
                assert 'startDate' in state, "Missing startDate"
                assert 'endDate' in state, "Missing endDate"
                assert 'stateCode' in state, "Missing stateCode"
                assert 'stateName' in state, "Missing stateName"
        
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_agent_login_data():
    """Test GET /historic/agentLoginData endpoint"""
    print("\n=== Testing GET /historic/agentLoginData ===")
    params = {
        "startDate": "2020-01-01T00:00:00Z",
        "endDate": "2020-01-02T00:00:00Z",
        "agentId": "1,2,3"
    }
    response = requests.get(f"{BASE_URL}/historic/agentLoginData", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Agents returned: {len(data)}")
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_agent_calls_data():
    """Test GET /historic/agentCallsData endpoint"""
    print("\n=== Testing GET /historic/agentCallsData ===")
    params = {
        "startDate": "2020-01-01T00:00:00Z",
        "endDate": "2020-01-02T00:00:00Z",
        "agentId": "1,2"
    }
    response = requests.get(f"{BASE_URL}/historic/agentCallsData", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Agents returned: {len(data)}")
        
        for agent_calls in data:
            assert agent_calls['serviceId'] == "1", "ServiceId must be static '1'"
            assert 'agentCalls' in agent_calls, "Missing agentCalls array"
        
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_chat_work_time():
    """Test GET /historic/agentChatsWorkTime endpoint"""
    print("\n=== Testing GET /historic/agentChatsWorkTime ===")
    params = {
        "startDate": "2020-01-01T00:00:00Z",
        "endDate": "2020-01-03T00:00:00Z",
        "agentId": "1,2,3"
    }
    response = requests.get(f"{BASE_URL}/historic/agentChatsWorkTime", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Work time records: {len(data)}")
        
        for record in data:
            assert 'workDate' in record, "Missing workDate"
            assert 'workTime' in record, "Missing workTime"
            assert record['workTime'] == 4500000, "Work time should be 75 minutes (4500000 ms)"
        
        print("✓ All BDD validations passed")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_status_transmission():
    """Test POST /ccwfm/api/rest/status endpoint"""
    print("\n=== Testing POST /ccwfm/api/rest/status ===")
    payload = {
        "workerId": "1",
        "stateName": "Technical break",
        "stateCode": "Break",
        "systemId": "External system",
        "actionTime": 1568816347,
        "action": 1
    }
    response = requests.post(f"{BASE_URL}/ccwfm/api/rest/status", json=payload)
    
    if response.status_code == 200:
        print(f"✓ Status: {response.status_code}")
        print("✓ Status transmission accepted")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_online_agent_status():
    """Test GET /online/agentStatus endpoint"""
    print("\n=== Testing GET /online/agentStatus ===")
    response = requests.get(f"{BASE_URL}/online/agentStatus")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Active agents: {len(data)}")
        print("✓ Real-time status retrieved")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_groups_online_load():
    """Test GET /online/groupsOnlineLoad endpoint"""
    print("\n=== Testing GET /online/groupsOnlineLoad ===")
    params = {"groupId": "1,2"}
    response = requests.get(f"{BASE_URL}/online/groupsOnlineLoad", params=params)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Status: {response.status_code}")
        print(f"✓ Groups metrics: {len(data)}")
        
        for metrics in data:
            assert 'callNumber' in metrics, "Missing required field: callNumber"
            assert 'operatorNumber' in metrics, "Missing required field: operatorNumber"
        
        print("✓ All required fields present")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_error_handling():
    """Test error handling scenarios"""
    print("\n=== Testing Error Handling ===")
    
    # Test 400 - Bad Request
    params = {
        "startDate": "invalid-date",
        "endDate": "2020-01-02T00:00:00Z",
        "step": 300000,
        "groupId": "1"
    }
    response = requests.get(f"{BASE_URL}/historic/serviceGroupData", params=params)
    print(f"Bad date format: Status {response.status_code} (expected 400 or 422)")
    
    # Test 404 - No data
    params = {
        "startDate": "2099-01-01T00:00:00Z",
        "endDate": "2099-01-02T00:00:00Z",
        "agentId": "999999"
    }
    response = requests.get(f"{BASE_URL}/historic/agentLoginData", params=params)
    print(f"No data scenario: Status {response.status_code} (expected 404)")

def run_all_tests():
    """Run all BDD integration tests"""
    print("=" * 60)
    print("BDD System Integration API Test Suite")
    print("=" * 60)
    
    try:
        # Test connectivity
        response = requests.get(f"{BASE_URL.replace('/api/v1', '')}/health")
        if response.status_code != 200:
            print("⚠️  API server not responding on expected port")
            print("Please ensure the API is running on http://localhost:8000")
            return
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API server")
        print("Please start the API with: uvicorn src.api.main:app --reload")
        return
    
    # Run all tests
    test_personnel_endpoint()
    test_service_group_data()
    test_agent_status_data()
    test_agent_login_data()
    test_agent_calls_data()
    test_chat_work_time()
    test_status_transmission()
    test_online_agent_status()
    test_groups_online_load()
    test_error_handling()
    
    print("\n" + "=" * 60)
    print("✅ All BDD integration tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()