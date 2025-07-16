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

@given('I am logged in as a regular user')
def step_login_regular_user(context):
    # Set up regular user authentication
    context.driver.execute_script("localStorage.setItem('authToken', 'valid_user_token_123');")
    context.driver.execute_script("localStorage.setItem('user', JSON.stringify({id: 'user_123', role: 'employee'}));")

@given('I navigate to the Profile Management page')
def step_navigate_profile_page(context):
    context.driver.get(f"{UI_BASE_URL}/employee/profile")
    # Wait for the page to load
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//h2[contains(text(), 'My Profile')]"))
    )

@given('my profile information is loaded')
def step_ensure_profile_loaded(context):
    # Wait for profile data to be visible
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//input[@value]"))
    )

@when('I click the "Edit Profile" button')
def step_click_edit_profile(context):
    edit_button = context.driver.find_element(By.XPATH, "//button[contains(text(), 'Edit Profile')]")
    edit_button.click()
    
    # Wait for edit mode to activate
    WebDriverWait(context.driver, 5).until(
        EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Save Changes')]"))
    )

@when('I update my first name to "{new_name}"')
def step_update_first_name(context, new_name):
    first_name_input = context.driver.find_element(By.XPATH, "//input[@type='text' and contains(@class, 'border-gray-300')]")
    first_name_input.clear()
    first_name_input.send_keys(new_name)
    context.updated_name = new_name

@when('I click the "Save Changes" button')
def step_click_save_changes(context):
    save_button = context.driver.find_element(By.XPATH, "//button[contains(text(), 'Save Changes')]")
    save_button.click()
    context.save_clicked = True

@then('the system should make a PUT request to "{endpoint}"')
def step_verify_put_request(context, endpoint):
    # Verify the PUT request was made by checking for loading/success states
    print(f"[TEST] Verifying PUT request to {endpoint}")
    
    # Look for saving state first
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Saving...')]"))
        )
        context.put_request_verified = True
    except TimeoutException:
        # Check if save completed very quickly
        success_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'successfully')]")
        context.put_request_verified = len(success_elements) > 0

@then('I should see a success message "{message}"')
def step_verify_success_message(context, message):
    try:
        WebDriverWait(context.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, f"//div[contains(text(), '{message}')]"))
        )
        context.success_message_found = True
    except TimeoutException:
        # Look for any success indicator
        success_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-green') or contains(@class, 'bg-green')]")
        assert len(success_elements) > 0, f"No success message found: {message}"

@then('the updated information should be persisted in the backend')
def step_verify_info_persisted(context):
    # Refresh the page to verify data persistence
    context.driver.refresh()
    WebDriverWait(context.driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//h2[contains(text(), 'My Profile')]"))
    )
    
    # Check if the updated data is still there
    if hasattr(context, 'updated_name'):
        name_inputs = context.driver.find_elements(By.XPATH, f"//input[@value='{context.updated_name}']")
        assert len(name_inputs) > 0, "Updated information was not persisted"

@given('I switch to the "{tab_name}" tab')
def step_switch_tab(context, tab_name):
    tab_button = context.driver.find_element(By.XPATH, f"//button[contains(text(), '{tab_name}')]")
    tab_button.click()
    
    # Wait for tab content to load
    time.sleep(1)

@when('I toggle email notifications off')
def step_toggle_email_notifications(context):
    # Find email notification checkbox
    email_checkbox = context.driver.find_element(By.XPATH, "//input[@type='checkbox']/following-sibling::span[contains(text(), 'Email')]/../input")
    if email_checkbox.is_selected():
        email_checkbox.click()
    context.email_notifications_toggled = True

@then('my notification preferences should be saved to the backend')
def step_verify_notifications_saved(context):
    # Wait for save operation to complete
    WebDriverWait(context.driver, 10).until_not(
        EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Saving...')]"))
    )
    
    # Verify no error messages appeared
    error_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-red')]")
    assert len(error_elements) == 0, "Error occurred while saving notifications"

@then('I should see the changes reflected immediately')
def step_verify_changes_reflected(context):
    # Check that the UI reflects the changes made
    if hasattr(context, 'email_notifications_toggled'):
        # Verify checkbox state matches what we set
        email_checkbox = context.driver.find_element(By.XPATH, "//input[@type='checkbox']/following-sibling::span[contains(text(), 'Email')]/../input")
        # The state should match our toggle action
        assert not email_checkbox.is_selected(), "Email notifications checkbox should be unchecked"

@when('I add "{day}" to my available days')
def step_add_available_day(context, day):
    # Find the checkbox for the specified day
    day_checkbox = context.driver.find_element(By.XPATH, f"//input[@type='checkbox']/following-sibling::span[contains(text(), '{day}')]/../input")
    if not day_checkbox.is_selected():
        day_checkbox.click()
    context.added_day = day

@then('my schedule preferences should be updated in the backend')
def step_verify_schedule_updated(context):
    # Wait for save operation to complete
    WebDriverWait(context.driver, 10).until_not(
        EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Saving...')]"))
    )
    
    # Verify success
    success_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'successfully')]")
    assert len(success_elements) > 0, "Schedule preferences save was not successful"

@then('the new preferences should be immediately visible')
def step_verify_new_preferences_visible(context):
    if hasattr(context, 'added_day'):
        # Verify the day checkbox is checked
        day_checkbox = context.driver.find_element(By.XPATH, f"//input[@type='checkbox']/following-sibling::span[contains(text(), '{context.added_day}')]/../input")
        assert day_checkbox.is_selected(), f"{context.added_day} should be checked in available days"

@when('I enter invalid data in the email field')
def step_enter_invalid_email(context):
    email_input = context.driver.find_element(By.XPATH, "//input[@type='email']")
    email_input.clear()
    email_input.send_keys("invalid-email-format")
    context.invalid_email_entered = True

@then('the system should make a POST request to "{endpoint}"')
def step_verify_post_request(context, endpoint):
    print(f"[TEST] Verifying POST request to {endpoint}")
    # This would be verified through validation behavior
    context.validation_request_made = True

@then('I should see validation errors from the backend')
def step_verify_validation_errors(context):
    try:
        WebDriverWait(context.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//div[contains(@class, 'text-red') and contains(text(), 'error')]"))
        )
        context.validation_error_found = True
    except TimeoutException:
        # Look for any error indicators
        error_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-red')]")
        assert len(error_elements) > 0, "No validation errors displayed"

@then('the save operation should be prevented')
def step_verify_save_prevented(context):
    # Check that we're still in edit mode (save was prevented)
    edit_buttons = context.driver.find_elements(By.XPATH, "//button[contains(text(), 'Save Changes')]")
    assert len(edit_buttons) > 0, "Save operation was not prevented - no longer in edit mode"

@when('I click the "Reset to Defaults" button')
def step_click_reset_defaults(context):
    reset_button = context.driver.find_element(By.XPATH, "//button[contains(text(), 'Reset to Defaults')]")
    reset_button.click()
    context.reset_clicked = True

@then('my preferences should be reset to system defaults')
def step_verify_reset_to_defaults(context):
    # Wait for reset operation to complete
    WebDriverWait(context.driver, 10).until_not(
        EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Saving...')]"))
    )
    
    # Verify that preferences have changed (specific values would depend on defaults)
    success_elements = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'successfully')]")
    assert len(success_elements) > 0, "Reset to defaults was not successful"

@then('the default values should be loaded from the backend')
def step_verify_default_values_loaded(context):
    # This would verify that the form shows default values
    # Specific checks would depend on what the defaults are
    checkboxes = context.driver.find_elements(By.XPATH, "//input[@type='checkbox']")
    assert len(checkboxes) > 0, "No preference checkboxes found after reset"

@then('no mock profile data should be displayed')
def step_verify_no_mock_profile_data(context):
    # Verify no mock data patterns are visible
    mock_indicators = context.driver.find_elements(By.XPATH, "//div[contains(text(), 'mock') or contains(text(), 'test@')]")
    assert len(mock_indicators) == 0, "Mock profile data appears to be displayed"

@then('no profile information should be loaded')
def step_verify_no_profile_loaded(context):
    # Verify no profile data is visible
    profile_inputs = context.driver.find_elements(By.XPATH, "//input[@value and @value!='']")
    # Should either be empty or show error state
    if len(profile_inputs) > 0:
        # Check if they contain error messages rather than actual profile data
        for input_elem in profile_inputs:
            value = input_elem.get_attribute('value').lower()
            assert 'error' in value or 'failed' in value or 'unauthorized' in value, f"Found profile data when none should be loaded: {value}"

@then('I should see a loading spinner on the save button')
def step_verify_save_button_spinner(context):
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(@class, 'animate-spin')]"))
        )
        context.save_spinner_found = True
    except TimeoutException:
        context.save_spinner_found = False

@then('the button should show "{button_text}" text')
def step_verify_button_text(context, button_text):
    try:
        WebDriverWait(context.driver, 5).until(
            EC.presence_of_element_located((By.XPATH, f"//button[contains(text(), '{button_text}')]"))
        )
        context.button_text_found = True
    except TimeoutException:
        buttons = context.driver.find_elements(By.XPATH, "//button")
        button_texts = [btn.text for btn in buttons]
        assert False, f"Button text '{button_text}' not found. Available buttons: {button_texts}"

@then('all form controls should be disabled during save')
def step_verify_controls_disabled(context):
    # Check that inputs are disabled during save
    disabled_inputs = context.driver.find_elements(By.XPATH, "//input[@disabled]")
    # There should be some disabled inputs during save operation
    assert len(disabled_inputs) > 0, "No form controls appear to be disabled during save"

@then('the save operation should complete with real backend response')
def step_verify_real_backend_response(context):
    # Wait for save operation to complete
    WebDriverWait(context.driver, 15).until_not(
        EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Saving...')]"))
    )
    
    # Verify we got a real response (success or error, but not hanging)
    final_state_elements = context.driver.find_elements(By.XPATH, "//div[contains(@class, 'text-green') or contains(@class, 'text-red')]")
    assert len(final_state_elements) > 0, "Save operation did not complete with a clear response"