Feature: Real User Preferences Management
  As an employee
  I want to manage my profile and preferences with real backend
  So that my settings are actually saved and used in the system

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token
    And I am logged in as a regular user

  @real-integration @user-preferences
  Scenario: Load user profile from real backend
    Given I navigate to the Profile Management page
    When the page loads
    Then the system should make a GET request to "/api/v1/settings/user/profile"
    And I should see my real profile information loaded from the backend
    And the loading indicator should disappear

  @real-integration @profile-update
  Scenario: Update personal information with real backend
    Given I navigate to the Profile Management page
    And my profile information is loaded
    When I click the "Edit Profile" button
    And I update my first name to "UpdatedName"
    And I click the "Save Changes" button
    Then the system should make a PUT request to "/api/v1/settings/user/profile"
    And I should see a success message "Profile updated successfully!"
    And the updated information should be persisted in the backend

  @real-integration @notification-preferences
  Scenario: Update notification preferences with real backend
    Given I navigate to the Profile Management page
    And I switch to the "Preferences" tab
    When I click the "Edit Profile" button
    And I toggle email notifications off
    And I click the "Save Changes" button
    Then the system should make a PUT request to "/api/v1/settings/user/preferences"
    And my notification preferences should be saved to the backend
    And I should see the changes reflected immediately

  @real-integration @schedule-preferences
  Scenario: Update schedule preferences with real backend
    Given I navigate to the Profile Management page
    And I switch to the "Preferences" tab
    When I click the "Edit Profile" button
    And I add "weekend" to my available days
    And I click the "Save Changes" button
    Then the system should make a PUT request to "/api/v1/settings/user/preferences"
    And my schedule preferences should be updated in the backend
    And the new preferences should be immediately visible

  @real-integration @validation-errors
  Scenario: Handle validation errors from backend
    Given I navigate to the Profile Management page
    When I click the "Edit Profile" button
    And I enter invalid data in the email field
    And I click the "Save Changes" button
    Then the system should make a POST request to "/api/v1/settings/user/validate"
    And I should see validation errors from the backend
    And the save operation should be prevented

  @real-integration @reset-defaults
  Scenario: Reset preferences to defaults with real backend
    Given I navigate to the Profile Management page
    And I switch to the "Preferences" tab
    When I click the "Reset to Defaults" button
    Then the system should make a POST request to "/api/v1/settings/user/reset"
    And my preferences should be reset to system defaults
    And I should see a success message
    And the default values should be loaded from the backend

  @real-integration @error-handling
  Scenario: Handle API server unavailable
    Given the API server is not running
    When I navigate to the Profile Management page
    Then I should see an error message "API server is not available"
    And I should see a "Retry" button
    And no mock profile data should be displayed

  @real-integration @authentication-failure
  Scenario: Handle authentication token expired
    Given I have an expired authentication token
    When I navigate to the Profile Management page
    Then I should see an error message "No authentication token found"
    And I should be redirected to the login page
    And no profile information should be loaded

  @real-integration @concurrent-updates
  Scenario: Handle save operations with loading states
    Given I navigate to the Profile Management page
    And my profile information is loaded
    When I click the "Edit Profile" button
    And I update my information
    And I click the "Save Changes" button
    Then I should see a loading spinner on the save button
    And the button should show "Saving..." text
    And all form controls should be disabled during save
    And the save operation should complete with real backend response