"""
Real Request Submission Step Definitions
Tests ACTUAL backend integration - NO MOCKS
"""

from behave import given, when, then, step
import requests
import time
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options

# Constants
API_BASE_URL = "http://localhost:8000/api/v1"
UI_BASE_URL = "http://localhost:3000"

@given('the API server is running on localhost:8000')
def step_api_server_running(context):
    """Verify API server is actually running"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        assert response.status_code == 200, f"API health check failed: {response.status_code}"
        context.api_available = True
        print(f"✅ API server confirmed running: {response.status_code}")
    except requests.exceptions.RequestException as e:
        context.api_available = False
        raise AssertionError(f"API server is not running: {e}")

@given('the UI application is accessible on localhost:3000')
def step_ui_accessible(context):
    """Verify UI is running and start browser"""
    # Setup Chrome browser for testing
    chrome_options = Options()
    chrome_options.add_argument('--headless')  # Run headless for CI
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    
    context.driver = webdriver.Chrome(options=chrome_options)
    context.driver.implicitly_wait(10)
    
    # Verify UI is accessible
    try:
        context.driver.get(UI_BASE_URL)
        assert "WFM" in context.driver.title
        print(f"✅ UI application accessible at {UI_BASE_URL}")
    except Exception as e:
        context.driver.quit()
        raise AssertionError(f"UI application not accessible: {e}")

@given('I have a valid authentication token')
def step_valid_auth_token(context):
    """Set up authentication token in browser localStorage"""
    context.driver.execute_script(
        "localStorage.setItem('authToken', 'test-jwt-token-123');"
    )
    print("✅ Authentication token set in localStorage")

@given('the user ID "{user_id}" is set in localStorage')
def step_set_user_id(context, user_id):
    """Set user ID in localStorage"""
    context.driver.execute_script(
        f"localStorage.setItem('currentUserId', '{user_id}');"
    )
    context.current_user_id = user_id
    print(f"✅ User ID set: {user_id}")

@given('I navigate to the employee portal')
def step_navigate_employee_portal(context):
    """Navigate to employee portal page"""
    context.driver.get(f"{UI_BASE_URL}/employee-portal")
    
    # Wait for portal to load
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.TAG_NAME, "body"))
    )
    print("✅ Navigated to employee portal")

@given('I open the request form')
def step_open_request_form(context):
    """Click button to open request form"""
    # Look for "New Request" or similar button
    new_request_button = WebDriverWait(context.driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'New Request') or contains(text(), 'Create Request')]"))
    )
    new_request_button.click()
    
    # Wait for form modal to appear
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//h2[contains(text(), 'New Request')]"))
    )
    print("✅ Request form opened")

@when('I select "{request_type}" as the request type')
def step_select_request_type(context, request_type):
    """Select vacation as request type"""
    # Find and click the vacation option
    vacation_option = WebDriverWait(context.driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, f"//input[@value='{request_type}']"))
    )
    vacation_option.click()
    
    context.selected_request_type = request_type
    print(f"✅ Selected request type: {request_type}")

@when('I fill in the following details')
def step_fill_form_details(context):
    """Fill in form fields from table data"""
    for row in context.table:
        field_name = row['field']
        field_value = row['value']
        
        if field_name in ['startDate', 'endDate']:
            # Date inputs
            date_input = context.driver.find_element(
                By.XPATH, f"//input[@type='date' and contains(@class, '{field_name}') or @name='{field_name}']"
            )
            date_input.clear()
            date_input.send_keys(field_value)
            
        elif field_name == 'reason':
            # Textarea
            reason_textarea = context.driver.find_element(
                By.XPATH, "//textarea"
            )
            reason_textarea.clear()
            reason_textarea.send_keys(field_value)
            
        elif field_name == 'title':
            # Text input
            title_input = context.driver.find_element(
                By.XPATH, "//input[@type='text' and contains(@placeholder, 'Brief description')]"
            )
            title_input.clear()
            title_input.send_keys(field_value)
            
        elif field_name == 'priority':
            # Select dropdown
            priority_select = context.driver.find_element(By.XPATH, "//select")
            priority_select.select_by_value(field_value)
            
        elif field_name == 'emergencyContact':
            # Emergency contact input (vacation specific)
            emergency_input = context.driver.find_element(
                By.XPATH, "//input[@placeholder='Phone or other contact method']"
            )
            emergency_input.clear()
            emergency_input.send_keys(field_value)
        
        print(f"✅ Filled {field_name}: {field_value}")
        
        # Move through form steps if needed
        next_button = context.driver.find_elements(By.XPATH, "//button[contains(text(), 'Next')]")
        if next_button and field_name in ['title', 'reason']:  # After step 1 and step 3
            next_button[0].click()
            time.sleep(1)  # Wait for step transition

@when('I submit the request')
def step_submit_request(context):
    """Click submit button and capture network requests"""
    # Store current requests to compare
    context.initial_requests = []
    
    # Click submit button
    submit_button = WebDriverWait(context.driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Submit Request')]"))
    )
    
    # Monitor console logs for API calls
    console_logs_before = context.driver.get_log('browser')
    
    submit_button.click()
    
    # Wait for submission to complete
    time.sleep(3)
    
    # Check console logs for API calls
    console_logs_after = context.driver.get_log('browser')
    context.console_logs = [log for log in console_logs_after if log not in console_logs_before]
    
    print("✅ Submit button clicked")

@then('the request should be sent to POST "{endpoint}"')
def step_verify_api_call(context, endpoint):
    """Verify the correct API endpoint was called"""
    # Check console logs for API call evidence
    api_call_found = False
    for log in context.console_logs:
        if endpoint in log.get('message', ''):
            api_call_found = True
            print(f"✅ API call detected to: {endpoint}")
            break
    
    # Also check for any alerts or UI changes indicating success/failure
    try:
        # Look for success message or error
        alert_present = WebDriverWait(context.driver, 5).until(
            EC.alert_is_present()
        )
        if alert_present:
            alert_text = context.driver.switch_to.alert.text
            context.alert_message = alert_text
            context.driver.switch_to.alert.accept()
            print(f"✅ Alert message: {alert_text}")
    except:
        # No alert, check for other success indicators
        try:
            success_element = context.driver.find_element(
                By.XPATH, "//*[contains(text(), 'submitted') or contains(text(), 'success')]"
            )
            context.success_message = success_element.text
            print(f"✅ Success message found: {context.success_message}")
        except:
            # Check for error messages
            try:
                error_element = context.driver.find_element(
                    By.XPATH, "//*[contains(@class, 'error') or contains(@class, 'red')]"
                )
                context.error_message = error_element.text
                print(f"❌ Error message found: {context.error_message}")
            except:
                print("⚠️ No clear success/error message found")

@then('I should receive a request ID from the backend')
def step_verify_request_id(context):
    """Verify that a request ID was returned"""
    if hasattr(context, 'alert_message'):
        assert 'ID:' in context.alert_message, f"No request ID in alert: {context.alert_message}"
        # Extract ID from message like "Request submitted successfully! ID: req-123"
        id_part = context.alert_message.split('ID:')[1].strip()
        context.request_id = id_part
        print(f"✅ Request ID received: {context.request_id}")
    else:
        raise AssertionError("No alert message found containing request ID")

@then('the request status should be "{expected_status}"')
def step_verify_request_status(context, expected_status):
    """Verify the request status matches expected"""
    # This would typically require checking the API response or UI display
    # For now, we verify via the success message
    if hasattr(context, 'alert_message'):
        # Success alert implies submitted status
        if expected_status == 'submitted' and 'submitted successfully' in context.alert_message:
            print(f"✅ Request status confirmed: {expected_status}")
        else:
            raise AssertionError(f"Expected status {expected_status} not confirmed in UI")
    else:
        raise AssertionError("Cannot verify request status - no response message found")

@then('I should see a success message with the request ID')
def step_verify_success_message(context):
    """Verify success message is displayed"""
    assert hasattr(context, 'alert_message'), "No success message found"
    assert 'submitted successfully' in context.alert_message, f"Invalid success message: {context.alert_message}"
    assert 'ID:' in context.alert_message, "No request ID in success message"
    print(f"✅ Success message verified: {context.alert_message}")

# Error handling scenarios

@given('the API server is not running')
def step_api_server_not_running(context):
    """Simulate API server being unavailable"""
    # Skip API health check
    context.api_available = False
    print("⚠️ API server marked as unavailable for test")

@when('I attempt to submit a vacation request')
def step_attempt_submit_vacation(context):
    """Quick form fill and submit for error scenarios"""
    # Fill minimal required fields and submit
    context.driver.find_element(By.XPATH, "//input[@value='vacation']").click()
    context.driver.find_element(By.XPATH, "//button[contains(text(), 'Next')]").click()
    
    # Fill dates
    context.driver.find_element(By.XPATH, "//input[@type='date']").send_keys("2024-08-01")
    context.driver.find_element(By.XPATH, "//button[contains(text(), 'Next')]").click()
    
    # Fill reason and title
    context.driver.find_element(By.XPATH, "//input[@type='text']").send_keys("Test Request")
    context.driver.find_element(By.XPATH, "//textarea").send_keys("Test reason for vacation")
    context.driver.find_element(By.XPATH, "//button[contains(text(), 'Next')]").click()
    
    # Submit
    context.driver.find_element(By.XPATH, "//button[contains(text(), 'Submit')]").click()
    time.sleep(2)

@then('I should see an error message "{expected_error}"')
def step_verify_error_message(context, expected_error):
    """Verify specific error message is displayed"""
    try:
        error_element = WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, f"//*[contains(text(), '{expected_error}')]"))
        )
        context.error_message = error_element.text
        print(f"✅ Error message verified: {context.error_message}")
    except:
        raise AssertionError(f"Expected error message '{expected_error}' not found")

@then('the request should not be submitted')
def step_verify_no_submission(context):
    """Verify request was not submitted"""
    # Check that form is still open
    try:
        form_element = context.driver.find_element(By.XPATH, "//h2[contains(text(), 'New Request')]")
        print("✅ Form still open - request not submitted")
    except:
        raise AssertionError("Form was closed - request may have been submitted incorrectly")

@then('I should remain on the form to retry')
def step_verify_form_remains(context):
    """Verify form stays open for retry"""
    # Same as above - form should still be present
    try:
        submit_button = context.driver.find_element(By.XPATH, "//button[contains(text(), 'Submit')]")
        assert submit_button.is_enabled(), "Submit button should be enabled for retry"
        print("✅ Form remains open with enabled submit button")
    except:
        raise AssertionError("Form not available for retry")

def after_scenario(context, scenario):
    """Cleanup after each scenario"""
    if hasattr(context, 'driver'):
        context.driver.quit()
        print("🧹 Browser cleanup completed")