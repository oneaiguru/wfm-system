Feature: Real Integration Settings Management
  As a system administrator
  I want to manage API integration settings with real backend
  So that I can configure external system connections

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token
    And I am logged in as an admin user

  @real-integration @integration-settings
  Scenario: Load integration configurations from real backend
    Given I navigate to the API Settings page
    When the page loads
    Then the system should make a GET request to "/api/v1/integrations/config"
    And I should see real integration configurations loaded from the backend
    And the loading indicator should disappear

  @real-integration @endpoint-testing
  Scenario: Test API endpoint with real backend
    Given I navigate to the API Settings page
    And the integration configurations are loaded
    When I click the "Test Endpoint" button for an active endpoint
    Then the system should make a POST request to "/api/v1/integrations/config/test/{endpointId}"
    And I should see the endpoint status change to "testing"
    And the real test results should be displayed
    And the endpoint statistics should be updated

  @real-integration @configuration-export
  Scenario: Export configuration with real backend
    Given I navigate to the API Settings page
    And the integration configurations are loaded
    When I click the "Export Configuration" button
    Then the system should make a GET request to "/api/v1/integrations/config/export"
    And I should receive a real configuration file download
    And the file should contain actual integration settings

  @real-integration @error-handling
  Scenario: Handle API server unavailable
    Given the API server is not running
    When I navigate to the API Settings page
    Then I should see an error message "API server is not available"
    And I should see a "Retry" button
    And no mock data should be displayed

  @real-integration @authentication-failure
  Scenario: Handle authentication token expired
    Given I have an expired authentication token
    When I navigate to the API Settings page
    Then I should see an error message "No authentication token found"
    And I should be redirected to the login page
    And no integration settings should be loaded

  @real-integration @endpoint-statistics
  Scenario: Refresh endpoint statistics with real data
    Given I navigate to the API Settings page
    And an endpoint test has been completed
    When I view the endpoint details
    Then I should see real statistics from the backend
    And the success rate should reflect actual test results
    And the response time should show actual measured values