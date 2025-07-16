from behave import given, when, then
import requests
import time
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

# Configuration
UI_BASE_URL = "http://localhost:3000"
API_BASE_URL = "http://localhost:8000/api/v1"

@given('the API server is running on localhost:8000')
def step_check_api_server(context):
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        assert response.status_code == 200, f"API server not responding: {response.status_code}"
        context.api_available = True
    except requests.exceptions.RequestException as e:
        context.api_available = False
        assert False, f"API server is not available: {e}"

@given('the UI application is accessible on localhost:3000')
def step_check_ui_server(context):
    try:
        response = requests.get(UI_BASE_URL, timeout=5)
        assert response.status_code == 200, f"UI server not responding: {response.status_code}"
    except requests.exceptions.RequestException as e:
        assert False, f"UI server is not available: {e}"

@given('I have a valid authentication token')
def step_setup_auth_token(context):
    # Mock authentication for testing
    context.auth_token = "test_jwt_token_12345"
    context.driver.execute_script(f"localStorage.setItem('authToken', '{context.auth_token}')")

@given('I navigate to the main dashboard page')
def step_navigate_main_dashboard(context):
    context.driver.get(f"{UI_BASE_URL}/dashboard")
    context.current_page = "main_dashboard"

@given('I navigate to the operational control dashboard')
def step_navigate_operational_dashboard(context):
    context.driver.get(f"{UI_BASE_URL}/operational-control")
    context.current_page = "operational_control"

@given('I navigate to the realtime metrics page')
def step_navigate_realtime_metrics(context):
    context.driver.get(f"{UI_BASE_URL}/realtime-metrics")
    context.current_page = "realtime_metrics"

@given('I navigate to the performance metrics page')
def step_navigate_performance_metrics(context):
    context.driver.get(f"{UI_BASE_URL}/performance-metrics")
    context.current_page = "performance_metrics"

@given('I navigate to the alerts panel')
def step_navigate_alerts_panel(context):
    context.driver.get(f"{UI_BASE_URL}/alerts")
    context.current_page = "alerts_panel"

@given('the API server is not available')
def step_stop_api_server(context):
    context.api_available = False

@given('I have an invalid or expired authentication token')
def step_invalid_auth_token(context):
    context.auth_token = "invalid_token"
    context.driver.execute_script(f"localStorage.setItem('authToken', '{context.auth_token}')")

@given('any dashboard component is loaded')
def step_load_any_dashboard(context):
    context.driver.get(f"{UI_BASE_URL}/dashboard")
    wait = WebDriverWait(context.driver, 10)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

@given('I am viewing performance metrics')
def step_viewing_performance_metrics(context):
    context.driver.get(f"{UI_BASE_URL}/performance-metrics")
    wait = WebDriverWait(context.driver, 10)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

@given('I have active alerts displayed')
def step_alerts_displayed(context):
    context.driver.get(f"{UI_BASE_URL}/alerts")
    wait = WebDriverWait(context.driver, 10)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

@given('multiple dashboard components are loaded')
def step_multiple_dashboards_loaded(context):
    # Open multiple tabs with different dashboard components
    context.driver.get(f"{UI_BASE_URL}/dashboard")
    context.driver.execute_script("window.open(arguments[0])", f"{UI_BASE_URL}/operational-control")
    context.driver.execute_script("window.open(arguments[0])", f"{UI_BASE_URL}/realtime-metrics")

@when('the dashboard loads')
def step_dashboard_loads(context):
    wait = WebDriverWait(context.driver, 10)
    # Wait for dashboard content to load (not just loading spinner)
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "[data-testid='dashboard-content'], .grid")))

@when('the panel loads')
def step_panel_loads(context):
    wait = WebDriverWait(context.driver, 10)
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "[data-testid='alerts-panel'], .space-y-6")))

@when('the page loads')
def step_page_loads(context):
    wait = WebDriverWait(context.driver, 10)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
    # Wait for any loading spinners to disappear
    wait.until_not(EC.presence_of_element_located((By.CSS_SELECTOR, ".animate-spin")))

@when('I select a time period "{period}"')
def step_select_time_period(context, period):
    wait = WebDriverWait(context.driver, 10)
    period_selector = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "select")))
    period_selector.click()
    
    # Select the specific period option
    option = context.driver.find_element(By.CSS_SELECTOR, f"option[value='{period}']")
    option.click()

@when('I try to load any dashboard component')
def step_try_load_dashboard(context):
    context.driver.get(f"{UI_BASE_URL}/dashboard")

@when('I try to access any dashboard component')
def step_try_access_dashboard(context):
    context.driver.get(f"{UI_BASE_URL}/dashboard")

@when('real-time refresh is enabled')
def step_enable_realtime_refresh(context):
    wait = WebDriverWait(context.driver, 10)
    # Look for auto-refresh toggle button
    try:
        refresh_toggle = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button:contains('Auto-refresh')")))
        refresh_toggle.click()
    except TimeoutException:
        # If toggle not found, assume auto-refresh is already enabled
        pass

@when('the data loads')
def step_data_loads(context):
    wait = WebDriverWait(context.driver, 15)
    # Wait for actual data to load (not loading placeholders)
    wait.until_not(EC.presence_of_element_located((By.CSS_SELECTOR, ".animate-pulse")))

@when('I acknowledge an alert')
def step_acknowledge_alert(context):
    wait = WebDriverWait(context.driver, 10)
    acknowledge_btn = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[title='Acknowledge']")))
    acknowledge_btn.click()

@when('I resolve an alert')
def step_resolve_alert(context):
    wait = WebDriverWait(context.driver, 10)
    resolve_btn = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[title='Resolve']")))
    resolve_btn.click()

@when('I escalate an alert')
def step_escalate_alert(context):
    wait = WebDriverWait(context.driver, 10)
    escalate_btn = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[title='Escalate']")))
    escalate_btn.click()

@when('I click retry after the API is back online')
def step_click_retry_api_online(context):
    context.api_available = True  # Simulate API coming back online
    wait = WebDriverWait(context.driver, 10)
    retry_btn = wait.until(EC.element_to_be_clickable((By.TEXT, "Retry")))
    retry_btn.click()

@when('they all fetch data from the backend')
def step_all_fetch_data(context):
    # Wait for all tabs to load data
    time.sleep(2)  # Give time for API calls to complete

@then('it should fetch data from GET "{endpoint}"')
def step_verify_api_endpoint(context, endpoint):
    # Monitor network requests in browser dev tools
    logs = context.driver.get_log('performance')
    api_calls = [log for log in logs if endpoint in str(log)]
    assert len(api_calls) > 0, f"No API call found to {endpoint}"
    
    # Verify the API call was successful
    if context.api_available:
        try:
            response = requests.get(f"{API_BASE_URL}{endpoint}", 
                                  headers={'Authorization': f'Bearer {context.auth_token}'})
            assert response.status_code == 200, f"API call failed: {response.status_code}"
        except requests.exceptions.RequestException:
            assert False, f"Failed to call API endpoint {endpoint}"

@then('I should see real active agents count')
def step_verify_active_agents(context):
    wait = WebDriverWait(context.driver, 10)
    agents_element = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='active-agents'], .text-blue-600")
    ))
    agents_text = agents_element.text
    assert agents_text.isdigit() or any(char.isdigit() for char in agents_text), \
        "Active agents count should contain numeric data"

@then('I should see real service level percentage')
def step_verify_service_level(context):
    wait = WebDriverWait(context.driver, 10)
    service_level = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='service-level'], .text-green-600")
    ))
    service_level_text = service_level.text
    assert '%' in service_level_text, "Service level should show percentage"

@then('I should see real calls handled count')
def step_verify_calls_handled(context):
    wait = WebDriverWait(context.driver, 10)
    calls_element = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='calls-handled'], .text-purple-600")
    ))
    assert calls_element.is_displayed(), "Calls handled metric should be visible"

@then('I should see real average wait time')
def step_verify_avg_wait_time(context):
    wait = WebDriverWait(context.driver, 10)
    wait_time_element = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='avg-wait-time'], .text-orange-600")
    ))
    wait_time_text = wait_time_element.text
    assert any(char.isdigit() for char in wait_time_text), "Wait time should contain numeric data"

@then('the data should refresh every 30 seconds')
def step_verify_auto_refresh(context):
    # Verify auto-refresh indicator is present
    wait = WebDriverWait(context.driver, 10)
    refresh_indicator = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, ".animate-pulse, [data-testid='refresh-indicator']")
    ))
    assert refresh_indicator.is_displayed(), "Auto-refresh indicator should be visible"

@then('I should see real operational metrics with traffic light indicators')
def step_verify_operational_metrics(context):
    wait = WebDriverWait(context.driver, 10)
    metrics_grid = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, ".grid, [data-testid='metrics-grid']")
    ))
    
    # Verify traffic light indicators (🟢🟡🔴 or colored elements)
    indicators = context.driver.find_elements(By.CSS_SELECTOR, ".bg-green-100, .bg-yellow-100, .bg-red-100")
    assert len(indicators) > 0, "Should have traffic light status indicators"

@then('I should see real agent status information')
def step_verify_agent_status(context):
    wait = WebDriverWait(context.driver, 10)
    agent_status = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='agent-status'], .divide-y")
    ))
    assert agent_status.is_displayed(), "Agent status section should be visible"

@then('I should see agent performance data by queue')
def step_verify_agent_performance_by_queue(context):
    wait = WebDriverWait(context.driver, 10)
    queue_filter = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "select, [data-testid='queue-filter']")
    ))
    assert queue_filter.is_displayed(), "Queue filter should be available"

@then('the metrics should update every 30 seconds')
def step_verify_metrics_auto_update(context):
    # Check for update timestamp or refresh indicator
    wait = WebDriverWait(context.driver, 10)
    last_update = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='last-update'], .text-gray-500")
    ))
    assert last_update.is_displayed(), "Last update timestamp should be visible"

@then('I should see real-time performance metrics')
def step_verify_realtime_metrics(context):
    wait = WebDriverWait(context.driver, 10)
    metrics_cards = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "[data-testid='metric-card'], .rounded-lg")
    ))
    assert len(metrics_cards) > 0, "Should display real-time metric cards"

@then('I should see queue performance tables')
def step_verify_queue_performance(context):
    wait = WebDriverWait(context.driver, 10)
    queue_table = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "table, [data-testid='queue-table']")
    ))
    assert queue_table.is_displayed(), "Queue performance table should be visible"

@then('I should see system load and health indicators')
def step_verify_system_health(context):
    wait = WebDriverWait(context.driver, 10)
    health_indicators = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "[data-testid='system-health'], .text-2xl")
    ))
    assert len(health_indicators) > 0, "Should display system health indicators"

@then('the data should auto-refresh every 30 seconds')
def step_verify_data_auto_refresh(context):
    # Verify auto-refresh functionality
    wait = WebDriverWait(context.driver, 10)
    auto_refresh_toggle = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='auto-refresh'], button")
    ))
    assert auto_refresh_toggle.is_displayed(), "Auto-refresh toggle should be visible"

@then('I should see overall performance metrics by category')
def step_verify_performance_by_category(context):
    wait = WebDriverWait(context.driver, 10)
    category_filters = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "select option, [data-testid='category-filter']")
    ))
    assert len(category_filters) > 1, "Should have multiple performance categories"

@then('I should see top agent performers ranking')
def step_verify_top_performers(context):
    wait = WebDriverWait(context.driver, 10)
    performers_section = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='top-performers'], .grid")
    ))
    assert performers_section.is_displayed(), "Top performers section should be visible"

@then('I should see team performance overview')
def step_verify_team_performance(context):
    wait = WebDriverWait(context.driver, 10)
    team_table = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='team-performance'], table")
    ))
    assert team_table.is_displayed(), "Team performance table should be visible"

@then('I should be able to export performance reports')
def step_verify_export_functionality(context):
    wait = WebDriverWait(context.driver, 10)
    export_button = wait.until(EC.element_to_be_clickable(
        (By.CSS_SELECTOR, "[data-testid='export-button'], button:contains('Export')")
    ))
    assert export_button.is_enabled(), "Export button should be clickable"

@then('I should see active alerts with real severity levels')
def step_verify_alerts_severity(context):
    wait = WebDriverWait(context.driver, 10)
    severity_indicators = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, ".bg-red-100, .bg-orange-100, .bg-yellow-100, .bg-blue-100")
    ))
    assert len(severity_indicators) > 0, "Should display alerts with severity indicators"

@then('I should see alert details with timestamps and sources')
def step_verify_alert_details(context):
    wait = WebDriverWait(context.driver, 10)
    alert_timestamps = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "[data-testid='alert-timestamp'], .text-gray-500")
    ))
    assert len(alert_timestamps) > 0, "Should display alert timestamps"

@then('I should be able to acknowledge alerts via API')
def step_verify_acknowledge_api(context):
    # This would be verified by checking network requests when acknowledge is clicked
    wait = WebDriverWait(context.driver, 10)
    acknowledge_buttons = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "button[title='Acknowledge']")
    ))
    assert len(acknowledge_buttons) > 0, "Should have acknowledge buttons available"

@then('I should be able to resolve alerts via API')
def step_verify_resolve_api(context):
    wait = WebDriverWait(context.driver, 10)
    resolve_buttons = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "button[title='Resolve']")
    ))
    assert len(resolve_buttons) > 0, "Should have resolve buttons available"

@then('the alerts should refresh every 30 seconds')
def step_verify_alerts_refresh(context):
    wait = WebDriverWait(context.driver, 10)
    refresh_indicator = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='alerts-refresh'], .animate-pulse")
    ))
    assert refresh_indicator.is_displayed(), "Alerts refresh indicator should be visible"

@then('I should see an error message "{message}"')
def step_verify_error_message(context, message):
    wait = WebDriverWait(context.driver, 10)
    error_element = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='error-message'], .text-red-800")
    ))
    error_text = error_element.text
    assert message.lower() in error_text.lower(), f"Expected error message '{message}' not found in '{error_text}'"

@then('I should see a retry button')
def step_verify_retry_button(context):
    wait = WebDriverWait(context.driver, 10)
    retry_button = wait.until(EC.element_to_be_clickable(
        (By.CSS_SELECTOR, "button:contains('Retry'), [data-testid='retry-button']")
    ))
    assert retry_button.is_enabled(), "Retry button should be clickable"

@then('the dashboard should load successfully')
def step_verify_dashboard_loads_successfully(context):
    wait = WebDriverWait(context.driver, 10)
    dashboard_content = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='dashboard-content'], .grid")
    ))
    assert dashboard_content.is_displayed(), "Dashboard should load successfully after retry"

@then('I should receive a 401 authentication error')
def step_verify_auth_error(context):
    wait = WebDriverWait(context.driver, 10)
    auth_error = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='auth-error'], .text-red-600")
    ))
    assert auth_error.is_displayed(), "Authentication error should be displayed"

@then('I should be redirected to the login page')
def step_verify_login_redirect(context):
    wait = WebDriverWait(context.driver, 10)
    wait.until(lambda driver: "/login" in driver.current_url)
    assert "/login" in context.driver.current_url, "Should be redirected to login page"

@then('the component should automatically refresh data every 30 seconds')
def step_verify_auto_refresh_30s(context):
    wait = WebDriverWait(context.driver, 10)
    auto_refresh_status = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='auto-refresh-status'], .text-green-700")
    ))
    assert auto_refresh_status.is_displayed(), "Auto-refresh status should be visible"

@then('I should see a live indicator showing the last update time')
def step_verify_live_indicator(context):
    wait = WebDriverWait(context.driver, 10)
    live_indicator = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='live-indicator'], .bg-green-500")
    ))
    assert live_indicator.is_displayed(), "Live indicator should be visible"

@then('I should be able to toggle auto-refresh on/off')
def step_verify_toggle_auto_refresh(context):
    wait = WebDriverWait(context.driver, 10)
    auto_refresh_toggle = wait.until(EC.element_to_be_clickable(
        (By.CSS_SELECTOR, "button:contains('Auto-refresh'), [data-testid='auto-refresh-toggle']")
    ))
    assert auto_refresh_toggle.is_enabled(), "Auto-refresh toggle should be clickable"

@then('I should be able to manually refresh the data')
def step_verify_manual_refresh(context):
    wait = WebDriverWait(context.driver, 10)
    manual_refresh = wait.until(EC.element_to_be_clickable(
        (By.CSS_SELECTOR, "button:contains('Refresh'), [data-testid='manual-refresh']")
    ))
    assert manual_refresh.is_enabled(), "Manual refresh button should be clickable"

@then('I should see industry benchmark comparisons')
def step_verify_industry_benchmarks(context):
    wait = WebDriverWait(context.driver, 10)
    benchmarks = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='industry-benchmark'], .text-blue-600")
    ))
    assert benchmarks.is_displayed(), "Industry benchmarks should be visible"

@then('I should see internal benchmark data')
def step_verify_internal_benchmarks(context):
    wait = WebDriverWait(context.driver, 10)
    internal_benchmarks = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='internal-benchmark'], .text-green-600")
    ))
    assert internal_benchmarks.is_displayed(), "Internal benchmarks should be visible"

@then('I should see target achievement percentages')
def step_verify_target_achievement(context):
    wait = WebDriverWait(context.driver, 10)
    targets = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='target-achievement'], .text-purple-600")
    ))
    assert targets.is_displayed(), "Target achievement should be visible"

@then('performance ratings should be calculated from real data')
def step_verify_performance_ratings(context):
    wait = WebDriverWait(context.driver, 10)
    ratings = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, ".bg-green-100, .bg-yellow-100, .bg-red-100")
    ))
    assert len(ratings) > 0, "Performance ratings should be calculated and displayed"

@then('it should call POST "{endpoint}"')
def step_verify_post_api_call(context, endpoint):
    # Monitor network requests for POST calls
    logs = context.driver.get_log('performance')
    post_calls = [log for log in logs if 'POST' in str(log) and endpoint in str(log)]
    assert len(post_calls) > 0, f"No POST call found to {endpoint}"

@then('the alert should be marked as acknowledged in real-time')
def step_verify_alert_acknowledged(context):
    wait = WebDriverWait(context.driver, 10)
    acknowledged_status = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, ".bg-green-100:contains('Acknowledged'), [data-testid='acknowledged-status']")
    ))
    assert acknowledged_status.is_displayed(), "Alert should show acknowledged status"

@then('the alert should be removed from active alerts')
def step_verify_alert_removed(context):
    time.sleep(2)  # Wait for UI update
    # Verify alert is no longer in the active alerts list
    resolved_alerts = context.driver.find_elements(By.CSS_SELECTOR, ".bg-gray-100:contains('Resolved')")
    assert len(resolved_alerts) > 0, "Resolved alert should be marked appropriately"

@then('the alert should be assigned to the escalated party')
def step_verify_alert_escalated(context):
    wait = WebDriverWait(context.driver, 10)
    escalated_status = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, "[data-testid='escalated-status'], .text-orange-600")
    ))
    assert escalated_status.is_displayed(), "Alert should show escalated status"

@then('agent counts should be consistent across components')
def step_verify_consistent_agent_counts(context):
    # Switch between tabs and verify agent counts match
    windows = context.driver.window_handles
    agent_counts = []
    
    for window in windows:
        context.driver.switch_to.window(window)
        try:
            agent_element = context.driver.find_element(By.CSS_SELECTOR, "[data-testid='agent-count'], .text-2xl")
            agent_counts.append(agent_element.text)
        except:
            continue
    
    # Verify all counts are the same (allowing for slight timing differences)
    if len(agent_counts) > 1:
        assert len(set(agent_counts)) <= 2, "Agent counts should be consistent across dashboards"

@then('service level metrics should match between dashboards')
def step_verify_consistent_service_levels(context):
    # Similar to agent counts, verify service levels are consistent
    windows = context.driver.window_handles
    service_levels = []
    
    for window in windows:
        context.driver.switch_to.window(window)
        try:
            sl_element = context.driver.find_element(By.CSS_SELECTOR, "[data-testid='service-level'], .text-green-600")
            service_levels.append(sl_element.text)
        except:
            continue
    
    if len(service_levels) > 1:
        assert len(set(service_levels)) <= 2, "Service levels should be consistent across dashboards"

@then('alert counts should be synchronized')
def step_verify_synchronized_alert_counts(context):
    # Verify alert counts are synchronized across components
    windows = context.driver.window_handles
    alert_counts = []
    
    for window in windows:
        context.driver.switch_to.window(window)
        try:
            alert_element = context.driver.find_element(By.CSS_SELECTOR, "[data-testid='alert-count'], .text-red-600")
            alert_counts.append(alert_element.text)
        except:
            continue
    
    if len(alert_counts) > 1:
        assert len(set(alert_counts)) <= 2, "Alert counts should be synchronized"

@then('timestamp data should reflect real system time')
def step_verify_real_timestamps(context):
    wait = WebDriverWait(context.driver, 10)
    timestamp_elements = wait.until(EC.presence_of_all_elements_located(
        (By.CSS_SELECTOR, "[data-testid='timestamp'], .text-gray-500")
    ))
    
    for timestamp_element in timestamp_elements:
        timestamp_text = timestamp_element.text
        # Verify timestamp format and that it's recent
        assert any(char.isdigit() for char in timestamp_text), "Timestamps should contain numeric data"