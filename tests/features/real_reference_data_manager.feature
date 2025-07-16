Feature: Real Reference Data Management
  As a system administrator
  I want to manage system connections and reference data with real backend
  So that external integrations work properly with actual data

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token
    And I am logged in as an admin user

  @real-integration @reference-data
  Scenario: Load system connections from real backend
    Given I navigate to the System Connectors page
    When the page loads
    Then the system should make a GET request to "/api/v1/reference-data/connections"
    And I should see real system connections loaded from the backend
    And the loading indicator should disappear

  @real-integration @connection-testing
  Scenario: Test system connection with real backend
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I click the "Test Connection" button for an active connection
    Then the system should make a POST request to "/api/v1/reference-data/connections/{id}/test"
    And I should see the connection status change to "testing"
    And the real test results should be displayed
    And the connection statistics should be updated

  @real-integration @connection-sync
  Scenario: Trigger sync for system connection with real backend
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I click the "Trigger Sync" button for an active connection
    Then the system should make a POST request to "/api/v1/reference-data/connections/{id}/sync"
    And I should see a sync spinner on the connection
    And the sync should complete with real backend response
    And the last sync time should be updated

  @real-integration @connection-deletion
  Scenario: Delete system connection with real backend
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I click the "Delete" button for a connection
    And I confirm the deletion
    Then the system should make a DELETE request to "/api/v1/reference-data/connections/{id}"
    And the connection should be removed from the list
    And the total connection count should be updated

  @real-integration @connection-statistics
  Scenario: View real connection statistics
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I view a connection's details
    Then I should see real statistics from the backend
    And the sync count should reflect actual values
    And the error count should show real error data
    And the success rate should be calculated from actual data

  @real-integration @bulk-testing
  Scenario: Test all connections with real backend
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I click the "Test All Connections" button
    Then the system should test each connection individually
    And I should see testing indicators for each connection
    And all tests should complete with real results
    And the overall system status should be updated

  @real-integration @error-handling
  Scenario: Handle API server unavailable
    Given the API server is not running
    When I navigate to the System Connectors page
    Then I should see an error message "API server is not available"
    And I should see a "Retry" button
    And no mock connection data should be displayed

  @real-integration @authentication-failure
  Scenario: Handle authentication token expired
    Given I have an expired authentication token
    When I navigate to the System Connectors page
    Then I should see an error message "No authentication token found"
    And I should be redirected to the login page
    And no system connections should be loaded

  @real-integration @connection-creation
  Scenario: Create new system connection with real backend
    Given I navigate to the System Connectors page
    When I click the "Add Connection" button
    And I fill in the connection details
    And I save the new connection
    Then the system should make a POST request to "/api/v1/reference-data/connections"
    And the new connection should appear in the list
    And it should have a real ID from the backend

  @real-integration @data-validation
  Scenario: Validate reference data integrity with real backend
    Given I navigate to the System Connectors page
    And the system connections are loaded
    When I request data integrity validation
    Then the system should make a request to "/api/v1/reference-data/validate"
    And I should see real validation results from the backend
    And any data integrity issues should be displayed
    And recommendations for fixes should be provided