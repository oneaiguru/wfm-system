Feature: Real Settings Components Integration
  As a system administrator
  I want to manage all system settings through real backend APIs
  So that configuration changes are properly persisted and validated

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid administrator authentication token
    And I am logged into the system with admin privileges

  @real-integration @system-settings
  Scenario: System Settings management with real backend
    Given I navigate to the System Settings page
    When I select the "general" settings category
    Then the settings should be loaded from GET "/api/v1/settings/system?category=general"
    And I should see system configuration options
    When I modify a setting value and save changes
    Then the changes should be sent to PUT "/api/v1/settings/system"
    And I should receive a confirmation of successful update
    And the new values should be persisted in the backend

  @real-integration @system-settings @health-monitoring
  Scenario: System health monitoring with real metrics
    Given I navigate to the System Settings page
    When the page loads
    Then system health data should be fetched from GET "/api/v1/settings/system/health"
    And I should see real CPU, memory, and uptime metrics
    And the health status should reflect actual system state

  @real-integration @user-preferences
  Scenario: User Preferences management with real backend
    Given I navigate to the User Preferences page
    When the preferences are loaded
    Then they should be fetched from GET "/api/v1/settings/user"
    And I should see my personal notification and shift preferences
    When I update my notification preferences
    Then the changes should be sent to PUT "/api/v1/settings/user"
    And I should receive real-time updates if preferences change elsewhere

  @real-integration @user-preferences @real-time
  Scenario: Real-time user preferences synchronization
    Given I have the User Preferences page open
    And WebSocket connection is established for real-time updates
    When another session updates my preferences
    Then I should receive a real-time update via WebSocket
    And my preferences display should automatically refresh
    And no page reload should be required

  @real-integration @reference-data
  Scenario: Reference Data management with real backend
    Given I navigate to the Reference Data Manager page
    When I select a data category
    Then reference data should be loaded from GET "/api/v1/reference-data/category/{category}"
    And I should see editable reference data items
    When I create a new reference data item
    Then it should be validated via POST "/api/v1/reference-data/validate"
    And if valid, created via POST "/api/v1/reference-data"
    And the new item should appear in the data grid

  @real-integration @reference-data @bulk-operations
  Scenario: Reference Data bulk operations with real backend
    Given I have reference data items loaded
    When I select multiple items for bulk deletion
    And I confirm the bulk delete operation
    Then the request should be sent to DELETE "/api/v1/reference-data/bulk-delete"
    And all selected items should be removed from the display
    And I should see a success confirmation

  @real-integration @reference-data @import-export
  Scenario: Reference Data import/export with real backend
    Given I navigate to the Reference Data Manager page
    When I click the export button
    Then a request should be made to GET "/api/v1/reference-data/export"
    And I should receive a downloadable CSV file
    When I import a CSV file
    Then it should be uploaded via POST "/api/v1/reference-data/import"
    And I should see import results with success/error counts

  @real-integration @integration-settings @admin-permissions
  Scenario: Integration Settings with admin permission checking
    Given I navigate to the Integration Settings page
    When the page loads
    Then it should check permissions via GET "/api/v1/integrations/config/permissions"
    And if I lack admin privileges, I should see an access denied message
    And if I have admin privileges, integrations should load from GET "/api/v1/integrations/config"

  @real-integration @integration-settings @connection-testing
  Scenario: Integration connection testing with real backend
    Given I have admin privileges and integration configurations loaded
    When I click test connection for an integration
    Then a test request should be sent to POST "/api/v1/integrations/config/{id}/test"
    And I should see real connection test results
    And the test should include connection, authentication, and data access status

  @real-integration @integration-settings @configuration-management
  Scenario: Integration configuration management with real backend
    Given I have admin privileges
    When I create a new integration configuration
    Then it should be validated via POST "/api/v1/integrations/config/validate"
    And if valid, created via POST "/api/v1/integrations/config"
    When I enable/disable an integration
    Then the status should be updated via POST "/api/v1/integrations/config/{id}/toggle"
    And the integration status should reflect the change

  @real-integration @notification-settings @templates
  Scenario: Notification Templates management with real backend
    Given I navigate to the Notification Settings page
    And I select the Templates tab
    Then templates should be loaded from GET "/api/v1/notifications/config/templates"
    When I create a new notification template
    Then it should be created via POST "/api/v1/notifications/config/templates"
    And the template should appear in the templates list

  @real-integration @notification-settings @rules
  Scenario: Notification Rules management with real backend
    Given I navigate to the Notification Settings page
    And I select the Rules tab
    Then rules should be loaded from GET "/api/v1/notifications/config/rules"
    When I create a notification rule
    Then it should be created via POST "/api/v1/notifications/config/rules"
    When I enable/disable a rule
    Then the status should be updated via POST "/api/v1/notifications/config/rules/{id}/toggle"

  @real-integration @notification-settings @channels
  Scenario: Notification Channels management with real backend
    Given I navigate to the Notification Settings page
    And I select the Channels tab
    Then channels should be loaded from GET "/api/v1/notifications/config/channels"
    When I test a notification channel
    Then a test should be sent via POST "/api/v1/notifications/config/channels/{id}/test"
    And I should see real delivery test results

  @real-integration @notification-settings @real-time-logs
  Scenario: Real-time notification logs with WebSocket updates
    Given I navigate to the Notification Settings page
    And I select the Logs tab
    And WebSocket connection is established for real-time updates
    When a notification is sent in the system
    Then I should receive a real-time log update via WebSocket
    And the new log entry should appear without page refresh

  @real-integration @notification-settings @statistics
  Scenario: Notification statistics with real backend metrics
    Given I navigate to the Notification Settings page
    And I select the Statistics tab
    Then statistics should be loaded from GET "/api/v1/notifications/config/stats"
    And I should see real metrics for delivery rates, channel performance, and failure reasons
    And the data should reflect actual notification activity

  @real-integration @error-handling
  Scenario: Real error handling across all settings components
    Given the API server is temporarily unavailable
    When I try to load any settings page
    Then I should see "API server is not available" error message
    And I should have a retry button that attempts to reconnect
    When the API server becomes available again
    And I click retry
    Then the settings should load successfully

  @real-integration @authentication
  Scenario: JWT authentication across all settings endpoints
    Given I have an expired authentication token
    When I try to access any settings functionality
    Then I should receive a 401 authentication error
    And I should see "Authentication failed. Please log in again." message
    And I should be redirected to the login page

  @real-integration @validation
  Scenario: Real validation across all settings components
    Given I navigate to any settings page with create/edit functionality
    When I submit invalid data
    Then validation should be performed by the backend API
    And I should see specific validation error messages
    And the form should highlight the invalid fields
    And no data should be saved until validation passes

  @real-integration @no-mock-fallbacks
  Scenario: Verify no mock fallbacks exist in settings components
    Given I inspect the network traffic for settings components
    When I interact with System Settings, User Preferences, Reference Data, Integration Settings, and Notification Settings
    Then all requests should go to real API endpoints
    And no mock data should be returned
    And no local fallback data should be used
    And all responses should come from the backend server

  @real-integration @jwt-token-usage
  Scenario: JWT token usage across all settings endpoints
    Given I have a valid JWT token from realAuthService.getAuthToken()
    When I make any request from settings components
    Then the Authorization header should contain "Bearer {token}"
    And all requests should be authenticated with real JWT tokens
    And no hardcoded or mock authentication should be used