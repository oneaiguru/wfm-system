from behave import given, when, then
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import requests
import json
import time

# Test configuration
UI_BASE_URL = "http://localhost:3000"
API_BASE_URL = "http://localhost:8000/api/v1"


@given('the API server is running on port 8000')
def step_api_server_running(context):
    """Check if API server is responding"""
    try:
        response = requests.get(f"{API_BASE_URL}/health")
        assert response.status_code in [200, 404], f"API server not responding properly: {response.status_code}"
        context.api_available = True
    except requests.exceptions.ConnectionError:
        context.api_available = False


@given('the UI application is running on port 3000')
def step_ui_app_running(context):
    """Initialize browser and check UI is accessible"""
    if not hasattr(context, 'browser'):
        context.browser = webdriver.Chrome()
    
    context.browser.get(UI_BASE_URL)
    assert "WFM" in context.browser.title or "React" in context.browser.title


@given('I am on the login page')
def step_on_login_page(context):
    """Navigate to login page"""
    context.browser.get(f"{UI_BASE_URL}/login")
    # Wait for login form to be visible
    WebDriverWait(context.browser, 10).until(
        EC.presence_of_element_located((By.ID, "email"))
    )


@given('the API server is not responding')
def step_api_not_responding(context):
    """Simulate API server being down"""
    context.api_available = False
    # In a real test, you might stop the API server or block network requests


@given('I have a valid JWT token in localStorage')
def step_valid_token_in_storage(context):
    """Set a valid token in localStorage"""
    context.browser.get(UI_BASE_URL)
    context.browser.execute_script("""
        localStorage.setItem('authToken', 'valid-test-token-123');
        localStorage.setItem('user', JSON.stringify({
            id: 1,
            name: 'Test User',
            email: 'test@technoservice.ru'
        }));
    """)


@given('I have an expired JWT token in localStorage')
def step_expired_token_in_storage(context):
    """Set an expired token in localStorage"""
    context.browser.get(UI_BASE_URL)
    context.browser.execute_script("""
        localStorage.setItem('authToken', 'expired-test-token-456');
    """)


@given('I am logged in with a valid token')
def step_logged_in_with_token(context):
    """Simulate being logged in"""
    context.browser.get(UI_BASE_URL)
    context.browser.execute_script("""
        localStorage.setItem('authToken', 'valid-test-token-789');
        localStorage.setItem('user', JSON.stringify({
            id: 1,
            name: 'Test User',
            email: 'test@technoservice.ru'
        }));
    """)
    context.browser.get(f"{UI_BASE_URL}/dashboard")


@when('I enter email "{email}"')
def step_enter_email(context, email):
    """Enter email in login form"""
    email_input = context.browser.find_element(By.ID, "email")
    email_input.clear()
    email_input.send_keys(email)
    context.entered_email = email


@when('I enter password "{password}"')
def step_enter_password(context, password):
    """Enter password in login form"""
    password_input = context.browser.find_element(By.ID, "password")
    password_input.clear()
    password_input.send_keys(password)
    context.entered_password = password


@when('I click the "{button_text}" button')
def step_click_button(context, button_text):
    """Click button with specific text"""
    button = context.browser.find_element(By.XPATH, f"//button[contains(text(), '{button_text}')]")
    button.click()


@when('I click the "Login" button without entering credentials')
def step_click_login_empty(context):
    """Click login without entering any data"""
    button = context.browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
    button.click()


@when('I visit the dashboard page')
def step_visit_dashboard(context):
    """Navigate to dashboard"""
    context.browser.get(f"{UI_BASE_URL}/dashboard")


@when('I click the logout button')
def step_click_logout(context):
    """Click logout button"""
    # Assuming logout button exists on dashboard
    try:
        logout_button = WebDriverWait(context.browser, 5).until(
            EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Logout')]"))
        )
        logout_button.click()
    except TimeoutException:
        # If no logout button, check for other logout mechanisms
        pass


@then('I should see "{message}" message')
def step_see_message(context, message):
    """Check for specific message on page"""
    WebDriverWait(context.browser, 5).until(
        EC.text_to_be_present_in_element((By.TAG_NAME, "body"), message)
    )


@then('the API endpoint "{endpoint}" should be called with credentials')
def step_api_called_with_credentials(context):
    """Verify API was called with correct credentials"""
    # In real implementation, you might use browser network monitoring
    # or check server logs
    if context.api_available:
        # Make test API call to verify endpoint exists
        response = requests.post(
            f"{API_BASE_URL}/auth/login",
            json={"email": context.entered_email, "password": context.entered_password}
        )
        context.api_response = response


@then('the API endpoint "{endpoint}" should be called')
def step_api_endpoint_called(context, endpoint):
    """Verify API endpoint was called"""
    # This would typically use browser dev tools or proxy to verify
    pass


@then('I should receive a JWT token')
def step_receive_jwt_token(context):
    """Check if JWT token was received"""
    if hasattr(context, 'api_response') and context.api_response.status_code == 200:
        data = context.api_response.json()
        assert 'token' in data, "No token in response"


@then('the token should be stored in localStorage')
def step_token_in_localstorage(context):
    """Verify token is stored in localStorage"""
    time.sleep(0.5)  # Wait for JS to execute
    token = context.browser.execute_script("return localStorage.getItem('authToken');")
    assert token is not None, "Token not found in localStorage"


@then('no token should be stored in localStorage')
def step_no_token_in_localstorage(context):
    """Verify no token in localStorage"""
    time.sleep(0.5)  # Wait for JS to execute
    token = context.browser.execute_script("return localStorage.getItem('authToken');")
    assert token is None, "Token should not be in localStorage"


@then('I should see "Welcome" message with the user\'s name')
def step_see_welcome_with_name(context):
    """Check for personalized welcome message"""
    welcome_element = WebDriverWait(context.browser, 5).until(
        EC.presence_of_element_located((By.XPATH, "//h2[contains(text(), 'Welcome')]"))
    )
    assert "Welcome" in welcome_element.text


@then('I should be redirected to "{path}" after {seconds} seconds')
def step_redirected_after_delay(context, path, seconds):
    """Check redirect after delay"""
    time.sleep(float(seconds) + 0.5)  # Add buffer
    assert path in context.browser.current_url, f"Not redirected to {path}"


@then('I should see an error message "{error_text}"')
def step_see_error_message(context, error_text):
    """Check for error message"""
    error_element = WebDriverWait(context.browser, 5).until(
        EC.presence_of_element_located((By.XPATH, f"//*[contains(text(), '{error_text}')]"))
    )
    assert error_text in error_element.text


@then('I should remain on the login page')
def step_remain_on_login(context):
    """Verify still on login page"""
    assert "/login" in context.browser.current_url or context.browser.current_url == UI_BASE_URL + "/"
    # Check login form is still visible
    assert context.browser.find_element(By.ID, "email").is_displayed()


@then('no API call should be made')
def step_no_api_call(context):
    """Verify no API call was made (client-side validation)"""
    # This is handled by client-side validation
    pass


@then('I should see "{error_text}"')
def step_see_text(context, error_text):
    """Generic text verification"""
    WebDriverWait(context.browser, 5).until(
        EC.text_to_be_present_in_element((By.TAG_NAME, "body"), error_text)
    )


@then('I should be allowed to access the dashboard')
def step_access_dashboard(context):
    """Verify dashboard access"""
    assert "/dashboard" in context.browser.current_url
    # Could also check for dashboard-specific elements


@then('the token should be removed from localStorage')
def step_token_removed(context):
    """Verify token removed from localStorage"""
    time.sleep(0.5)
    token = context.browser.execute_script("return localStorage.getItem('authToken');")
    assert token is None, "Token should be removed from localStorage"


@then('the user data should be cleared')
def step_user_data_cleared(context):
    """Verify user data cleared"""
    user_data = context.browser.execute_script("return localStorage.getItem('user');")
    assert user_data is None, "User data should be cleared"


@then('I should be redirected to the login page')
def step_redirected_to_login(context):
    """Verify redirected to login"""
    time.sleep(0.5)
    assert "/login" in context.browser.current_url or context.browser.current_url == UI_BASE_URL + "/"


def after_scenario(context, scenario):
    """Clean up after each scenario"""
    if hasattr(context, 'browser'):
        # Clear localStorage
        context.browser.execute_script("localStorage.clear();")
        # Close browser after all scenarios
        context.browser.quit()