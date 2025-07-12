"""
Test script for BDD Step-by-Step Requests API endpoints
Tests all endpoints against BDD specifications
"""

import requests
import json
from datetime import datetime, date, timedelta

BASE_URL = "http://localhost:8000/api/v1"

def test_requests_landing():
    """Test requests landing page navigation"""
    print("\n=== Testing Requests Landing Page ===")
    
    response = requests.get(f"{BASE_URL}/requests/landing")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Navigation state: {data['current_page']}")
        print(f"✓ Page active: {data['is_active']}")
        print(f"✓ URL: {data['url']}")
        print(f"✓ Page title: {data['page_title']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Test landing content
    response = requests.get(f"{BASE_URL}/requests/landing/content")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Content verified: {data['page_title']}")
        print(f"✓ Navigation status: {data['navigation_status']}")
        print(f"✓ Ready for navigation: {data['ready_for_navigation']}")

def test_calendar_interface():
    """Test calendar interface and navigation"""
    print("\n=== Testing Calendar Interface ===")
    
    # Get calendar for June 2025
    response = requests.get(f"{BASE_URL}/calendar", params={"year": 2025, "month": 6})
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Calendar loaded: {data['month_name']} {data['year']}")
        print(f"✓ Days in calendar: {len(data['days'])}")
        print(f"✓ Interface title: {data['interface']['page_title']}")
        print(f"✓ View mode: {data['interface']['view_mode']}")
        print(f"✓ Current month: {data['interface']['current_month']}")
        print(f"✓ Primary action: {data['interface']['primary_action']}")
        
        # Show some calendar statistics
        current_month_days = [d for d in data['days'] if d['is_current_month']]
        days_with_shifts = [d for d in current_month_days if d['has_shift']]
        weekend_days = [d for d in current_month_days if d['is_weekend']]
        
        print(f"✓ Current month days: {len(current_month_days)}")
        print(f"✓ Days with shifts: {len(days_with_shifts)}")
        print(f"✓ Weekend days: {len(weekend_days)}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Test calendar interface structure
    response = requests.get(f"{BASE_URL}/calendar/interface")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Monthly grid: {data['monthly_grid']}")
        print(f"✓ Create button: {data['create_button']}")
        print(f"✓ Mode selector: {data['mode_selector']}")

def test_request_creation_flow():
    """Test request creation form and validation"""
    print("\n=== Testing Request Creation Flow ===")
    
    # Trigger request creation interface
    response = requests.post(f"{BASE_URL}/calendar/create-request")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Form opened: {data['form_opened']}")
        print(f"✓ Form title: {data['form_title']}")
        
        # Show form elements
        elements = data['form_elements']
        print(f"✓ Form elements:")
        for element, details in elements.items():
            print(f"  - {element}: {details['description']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Get request form structure
    response = requests.get(f"{BASE_URL}/calendar/request-form")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Form structure loaded")
        print(f"✓ Form elements: {len(data['form_elements'])}")
        print(f"✓ Action buttons: {len(data['action_buttons'])}")
        print(f"✓ Request types: {len(data['request_types'])}")
        
        # Show validation messages
        for element in data['form_elements']:
            if element.get('validation_message'):
                print(f"  - {element['label']}: {element['validation_message']}")

def test_form_validation():
    """Test form validation behavior"""
    print("\n=== Testing Form Validation ===")
    
    # Test empty form validation
    form_data = {
        "request_type": None,
        "selected_date": None,
        "comment": None
    }
    
    response = requests.post(f"{BASE_URL}/calendar/validate-form", json=form_data)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Validation passed: {data['validation_passed']}")
        print(f"✓ Validation errors: {len(data['errors'])}")
        
        for error in data['errors']:
            print(f"  - {error['field']}: {error['message']}")
        
        validation_behavior = data['validation_behavior']
        print(f"✓ Type field: {validation_behavior['type_field']}")
        print(f"✓ Date field: {validation_behavior['date_field']}")
        print(f"✓ Comment field: {validation_behavior['comment_field']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Test partial form validation
    form_data = {
        "request_type": "Заявка на создание больничного",
        "selected_date": None,
        "comment": "Test comment"
    }
    
    response = requests.post(f"{BASE_URL}/calendar/validate-form", json=form_data)
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Partial validation - errors: {len(data['errors'])}")
        print(f"✓ Should only show date error: {data['errors'][0]['field'] == 'date' if data['errors'] else 'No errors'}")

def test_comment_edge_cases():
    """Test comment field edge cases"""
    print("\n=== Testing Comment Edge Cases ===")
    
    test_comments = [
        "Short text",
        "Very long comment with special characters: русский текст, numbers 123, symbols !@#$%^&*()_+-=",
        "",  # Empty comment
        "123456789",
        "Line 1\nLine 2\nLine 3"
    ]
    
    for i, comment in enumerate(test_comments):
        response = requests.post(
            f"{BASE_URL}/calendar/test-comment-edge-cases",
            json={"comment_text": comment}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Test {i+1}: {data['test_result']}")
            print(f"  - Comment accepted: {data['comment_accepted']}")
            print(f"  - Date validation present: {data['date_validation_present']}")
            print(f"  - Summary: {data['validation_summary']['comment_field']}")
        else:
            print(f"✗ Test {i+1} failed with status: {response.status_code}")

def test_request_submission():
    """Test successful request submission"""
    print("\n=== Testing Request Submission ===")
    
    # Valid form data
    form_data = {
        "request_type": "Заявка на создание больничного",
        "selected_date": (date.today() + timedelta(days=5)).isoformat(),
        "comment": "Test sick leave request"
    }
    
    response = requests.post(
        f"{BASE_URL}/requests/submit",
        json=form_data,
        params={"employee_id": "111538"}
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Request submitted: {data['request_id']}")
        print(f"✓ Request type: {data['request_type']}")
        print(f"✓ Selected date: {data['selected_date']}")
        print(f"✓ Status: {data['status']}")
        print(f"✓ Employee ID: {data['employee_id']}")
        print(f"✓ Approval chain: {len(data['approval_chain'])} levels")
    else:
        print(f"✗ Failed with status: {response.status_code}")
        print(response.text)

def test_exchange_system():
    """Test exchange system interface"""
    print("\n=== Testing Exchange System ===")
    
    # Get exchange interface
    response = requests.get(f"{BASE_URL}/exchange")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Exchange interface loaded")
        print(f"✓ Page title: {data['interface']['page_title']}")
        print(f"✓ Tabs: {len(data['interface']['tabs'])}")
        
        for tab in data['interface']['tabs']:
            print(f"  - {tab['name']}: {tab['description']} (active: {tab['active']})")
        
        print(f"✓ Current description: {data['interface']['current_description']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Test table structure
    response = requests.get(f"{BASE_URL}/exchange/table-structure")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Table structure loaded")
        print(f"✓ Columns: {len(data['table_columns'])}")
        
        for col in data['table_columns']:
            print(f"  - {col['column']}: {col['purpose']}")
        
        print(f"✓ Empty state: {data['empty_state']['message']}")

def test_exchange_tabs():
    """Test exchange tab functionality"""
    print("\n=== Testing Exchange Tabs ===")
    
    # Test "my" tab
    response = requests.get(f"{BASE_URL}/exchange/my")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ My exchanges tab: {data['tab_name']}")
        print(f"✓ Has data: {data['has_data']}")
        print(f"✓ Exchanges: {len(data['exchanges'])}")
        print(f"✓ Description: {data['description']}")
        
        if data['exchanges']:
            sample = data['exchanges'][0]
            print(f"  Sample exchange: {sample['name']} ({sample['status']})")
    else:
        print(f"✗ My tab failed with status: {response.status_code}")
    
    # Test "available" tab
    response = requests.get(f"{BASE_URL}/exchange/available")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Available exchanges tab: {data['tab_name']}")
        print(f"✓ Has data: {data['has_data']}")
        print(f"✓ Exchanges: {len(data['exchanges'])}")
        
        if data['exchanges']:
            sample = data['exchanges'][0]
            print(f"  Sample exchange: {sample['name']} ({sample['status']})")
    else:
        print(f"✗ Available tab failed with status: {response.status_code}")

def test_workflow_integration():
    """Test complete workflow integration"""
    print("\n=== Testing Workflow Integration ===")
    
    response = requests.get(f"{BASE_URL}/workflow/integration")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Workflow pathways: {len(data['workflow_pathways'])}")
        
        for pathway in data['workflow_pathways']:
            print(f"  - {pathway['pathway']}: {pathway['entry_point']}")
            print(f"    Purpose: {pathway['purpose']}")
            print(f"    Steps: {len(pathway['process'])}")
        
        integration = data['integration_features']
        print(f"✓ Integration features:")
        print(f"  - Approval workflow: {integration['approval_workflow']}")
        print(f"  - Status tracking: {integration['status_tracking']}")
        print(f"  - Navigation: {integration['navigation']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_business_process_mapping():
    """Test business process mapping"""
    print("\n=== Testing Business Process Mapping ===")
    
    response = requests.get(f"{BASE_URL}/business-process/mapping")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Business process mapping loaded")
        print(f"✓ Implementation coverage: {data['implementation_coverage']}")
        print(f"✓ 5-step process mapping:")
        
        for step in data['original_5_step_process']:
            print(f"  Step {step['step']}: {step['status']}")
            print(f"    Process: {step['russian_process']}")
            print(f"    Implementation: {step['discovered_implementation']}")
        
        print(f"✓ Technical framework: {data['technical_notes']['framework']}")
        print(f"✓ Authentication: {data['technical_notes']['authentication']}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_technical_documentation():
    """Test technical documentation endpoints"""
    print("\n=== Testing Technical Documentation ===")
    
    # Vue SPA architecture
    response = requests.get(f"{BASE_URL}/technical/vue-spa-architecture")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Vue SPA architecture documented")
        print(f"✓ Framework: {data['framework_requirements']['framework']}")
        print(f"✓ Authentication: {data['framework_requirements']['authentication']}")
        print(f"✓ SPA features: {len(data['spa_features'])}")
        print(f"✓ UI components: {len(data['ui_components'])}")
    else:
        print(f"✗ Failed with status: {response.status_code}")
    
    # Authentication API
    response = requests.get(f"{BASE_URL}/technical/authentication-api")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Authentication API documented")
        print(f"✓ Signin endpoint: {data['authentication_endpoints']['signin']['endpoint']}")
        print(f"✓ Token storage: {data['token_storage']['location']}")
        print(f"✓ User data includes: {list(data['user_data_structure'].keys())}")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def test_my_requests():
    """Test user's requests retrieval"""
    print("\n=== Testing My Requests ===")
    
    response = requests.get(f"{BASE_URL}/requests/my-requests")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ My requests loaded")
        print(f"✓ Employee ID: {data['employee_id']}")
        print(f"✓ Total requests: {data['total_requests']}")
        
        summary = data['summary']
        print(f"✓ Summary:")
        print(f"  - Pending: {summary['pending']}")
        print(f"  - Approved: {summary['approved']}")
        print(f"  - Rejected: {summary['rejected']}")
        
        if data['requests']:
            sample = data['requests'][0]
            print(f"✓ Sample request: {sample['request_type']} ({sample['status']})")
    else:
        print(f"✗ Failed with status: {response.status_code}")

def run_all_tests():
    """Run all BDD step-by-step requests tests"""
    print("=" * 60)
    print("BDD Step-by-Step Requests API Test Suite")
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
    test_requests_landing()
    test_calendar_interface()
    test_request_creation_flow()
    test_form_validation()
    test_comment_edge_cases()
    test_request_submission()
    test_exchange_system()
    test_exchange_tabs()
    test_workflow_integration()
    test_business_process_mapping()
    test_technical_documentation()
    test_my_requests()
    
    print("\n" + "=" * 60)
    print("✅ All BDD step-by-step requests tests completed")
    print("=" * 60)

if __name__ == "__main__":
    run_all_tests()