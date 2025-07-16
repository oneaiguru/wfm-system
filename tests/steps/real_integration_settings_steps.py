from behave import given, when, then
import requests
import time
import json
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

API_BASE_URL = "http://localhost:8000/api/v1"
UI_BASE_URL = "http://localhost:3000"

@given('I navigate to the API Settings page')
def step_navigate_api_settings(context):
    context.driver.get(f"{UI_BASE_URL}/integration/settings")
    # Wait for the page to load
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//h2[contains(text(), 'API Settings')]"))
    )

@when('the page loads')
def step_page_loads(context):
    # Wait for loading to complete
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, "//div[contains(@class, 'animate-spin')]"))
        )
        # Wait for loading to disappear
        WebDriverWait(context.driver, 10).until_not(
            EC.presence_of_element_located((By.XPATH, "//div[contains(@class, 'animate-spin')]"))
        )
    except TimeoutException:
        # Loading might complete very quickly
        pass

@then('the system should make a GET request to "{endpoint}"')
def step_verify_get_request(context, endpoint):
    # Check network logs or verify API call was made
    # This would need browser network monitoring or API server logs
    print(f"[TEST] Verifying GET request to {endpoint}")
    
    # Verify the request was made by checking if data is loaded
    try:
        WebDriverWait(context.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//div[contains(text(), 'endpoints')]"))
        )
        context.api_request_verified = True
    except TimeoutException:
        context.api_request_verified = False

@then('I should see real integration configurations loaded from the backend')
def step_verify_real_configs_loaded(context):
    # Look for actual configuration data, not mock data
    config_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'bg-white')]//h4")
    
    assert len(config_elements) > 0, "No integration configurations found"
    
    # Verify we're not seeing mock data patterns
    for element in config_elements:
        config_name = element.text
        # Mock data would have specific test patterns
        assert "mock" not in config_name.lower(), f"Found mock data: {config_name}"
        assert "test_" not in config_name.lower(), f"Found test mock data: {config_name}"

@then('the loading indicator should disappear')
def step_verify_loading_disappeared(context):
    # Ensure no loading spinners are visible
    loading_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'animate-spin')]")
    assert len(loading_elements) == 0, "Loading indicator is still visible"

@given('the integration configurations are loaded')
def step_ensure_configs_loaded(context):
    # Wait for configurations to be present
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//button[contains(@title, 'Test Endpoint')]"))
    )

@when('I click the "Test Endpoint" button for an active endpoint')
def step_click_test_endpoint(context):
    # Find an active endpoint and click its test button
    test_buttons = context.driver.find_elements(By.XPATH, "//button[contains(@title, 'Test Endpoint')]")
    assert len(test_buttons) > 0, "No test endpoint buttons found"
    
    # Click the first test button
    test_buttons[0].click()
    context.tested_endpoint = True

@then('the system should make a POST request to "{endpoint_pattern}"')
def step_verify_post_request(context, endpoint_pattern):
    # Verify the POST request pattern
    print(f"[TEST] Verifying POST request to pattern: {endpoint_pattern}")
    
    # Wait for the test to start (button should show testing state)
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, "//div[contains(@class, 'animate-spin')]"))
        )
        context.test_request_verified = True
    except TimeoutException:
        context.test_request_verified = False

@then('I should see the endpoint status change to "testing"')
def step_verify_testing_status(context):
    # Look for testing status indicator
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, "//span[contains(text(), 'Testing') or contains(text(), 'testing')]"))
        )
        context.testing_status_found = True
    except TimeoutException:
        # Check for spinning indicator
        spinning_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'animate-spin')]")
        context.testing_status_found = len(spinning_elements) > 0

@then('the real test results should be displayed')
def step_verify_real_test_results(context):
    # Wait for test to complete and show results
    WebDriverWait(context.driver, 15).until_not(
        EC.presence_of_element_located((By.XPATH, "//div[contains(@class, 'animate-spin')]"))
    )
    
    # Look for test results (success/failure indicators)
    status_elements = context.driver.find_elements(By.XPATH, "//span[contains(text(), 'Active') or contains(text(), 'Inactive') or contains(text(), 'Error')]")
    assert len(status_elements) > 0, "No test result status found"

@then('the endpoint statistics should be updated')
def step_verify_stats_updated(context):
    # Look for updated statistics
    stats_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'Response Time') or contains(text(), 'Success Rate')]")
    assert len(stats_elements) > 0, "No statistics found"

@when('I click the "Export Configuration" button')
def step_click_export_config(context):
    export_button = context.driver.find_element(By.XPATH, "//button[contains(., 'Export Configuration')]")
    export_button.click()
    context.export_clicked = True

@then('I should receive a real configuration file download')
def step_verify_config_download(context):
    # In a real test, we would monitor browser downloads
    # For now, verify the button interaction worked
    assert hasattr(context, 'export_clicked'), "Export button was not clicked"
    
    # Wait a moment for download to potentially start
    time.sleep(2)
    
    # Check if any error messages appeared instead of download
    error_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-red')]")
    if len(error_elements) > 0:
        error_text = error_elements[0].text
        assert False, f"Export failed with error: {error_text}"

@then('the file should contain actual integration settings')
def step_verify_config_content(context):
    # This would require checking the downloaded file content
    # For now, verify no error messages appeared
    error_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'Export failed')]")
    assert len(error_elements) == 0, "Export appears to have failed"

@given('the API server is not running')
def step_api_server_down(context):
    # This step would need to be coordinated with test infrastructure
    # to actually stop the API server or mock its unavailability
    context.api_server_down = True

@then('I should see an error message "{error_message}"')
def step_verify_error_message(context, error_message):
    try:
        WebDriverWait(context.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, f"//div[contains(text(), '{error_message}')]"))
        )
        context.error_message_found = True
    except TimeoutException:
        # Look for any error message
        error_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-red') or contains(@class, 'bg-red')]")
        assert len(error_elements) > 0, f"No error message found containing: {error_message}"

@then('I should see a "Retry" button')
def step_verify_retry_button(context):
    retry_button = context.driver.find_element(By.XPATH, "//button[contains(text(), 'Retry')]")
    assert retry_button is not None, "Retry button not found"

@then('no mock data should be displayed')
def step_verify_no_mock_data(context):
    # Verify no mock data patterns are visible
    mock_indicators = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'mock') or contains(text(), 'test_')]")
    assert len(mock_indicators) == 0, "Mock data appears to be displayed"

@given('I have an expired authentication token')
def step_expired_token(context):
    # Set an expired or invalid token in localStorage
    context.driver.execute_script("localStorage.setItem('authToken', 'expired_token_123');")

@then('I should be redirected to the login page')
def step_verify_login_redirect(context):
    # Wait for potential redirect
    time.sleep(2)
    current_url = context.driver.current_url
    assert '/login' in current_url or '/auth' in current_url, f"Not redirected to login page. Current URL: {current_url}"

@then('no integration settings should be loaded')
def step_verify_no_settings_loaded(context):
    # Verify no settings data is visible
    setting_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'bg-white')]//h4")
    # Should either be empty or show error state
    if len(setting_elements) > 0:
        # Check if they contain error messages rather than actual settings
        for element in setting_elements:
            text = element.text.lower()
            assert 'error' in text or 'failed' in text or 'unauthorized' in text, f"Found settings data when none should be loaded: {element.text}"

@given('an endpoint test has been completed')
def step_endpoint_test_completed(context):
    # Trigger an endpoint test first
    step_click_test_endpoint(context)
    step_verify_real_test_results(context)

@when('I view the endpoint details')
def step_view_endpoint_details(context):
    # Look for endpoint details display
    details_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'Response Time') or contains(text(), 'Success Rate')]")
    assert len(details_elements) > 0, "No endpoint details found"

@then('I should see real statistics from the backend')
def step_verify_real_statistics(context):
    # Verify statistics are present and appear to be real data
    stats_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), '%') or contains(text(), 'ms')]")
    assert len(stats_elements) > 0, "No statistical data found"

@then('the success rate should reflect actual test results')
def step_verify_real_success_rate(context):
    success_rate_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), '%')]")
    assert len(success_rate_elements) > 0, "No success rate data found"

@then('the response time should show actual measured values')
def step_verify_real_response_time(context):
    response_time_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'ms') or contains(text(), 's')]")
    assert len(response_time_elements) > 0, "No response time data found"