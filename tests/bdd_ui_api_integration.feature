# BDD Feature: UI-API Integration Test Suite
# Comprehensive integration testing between UI-OPUS and INTEGRATION-OPUS

Feature: Complete UI-API Integration Validation
  As a WFM system integrator
  I want to validate all UI-API connections
  So that the system operates reliably end-to-end

  Background:
    Given the WFM API server is running on port 8000
    And the UI application is accessible on port 3000
    And integration tester is available at "/integration-tester"

  @core-api @health
  Scenario: Core API Health and Connectivity
    Given I navigate to the integration tester
    When I execute the "Core API Connections" test suite
    Then all health check endpoints should respond successfully
    And authentication endpoints should validate tokens
    And database connectivity should be confirmed
    And algorithm service integration should be operational

  @personnel @crud
  Scenario: Personnel Management Integration
    Given employee data exists in the system
    When I test personnel management endpoints
    Then I should retrieve employee lists successfully
    And employee creation with Cyrillic names should work
    And skill assignment workflows should complete
    And work settings should include labor law compliance

  @vacancy-planning @analysis
  Scenario: Vacancy Planning Module Integration
    Given I have System_AccessVacancyPlanning role
    When I test vacancy planning endpoints
    Then settings configuration should be accessible
    And gap analysis should execute with progress tracking
    And exchange system integration should be functional
    And comprehensive reports should be generated

  @real-time @websocket
  Scenario: Real-time Features Integration
    Given real-time monitoring is enabled
    When I test real-time endpoints
    Then WebSocket connections should establish successfully
    And operational metrics should update every 30 seconds
    And agent status monitoring should be current
    And schedule change notifications should be delivered

  @performance @load
  Scenario: Performance and Load Testing
    Given all endpoints are operational
    When I execute concurrent requests
    Then response times should be under 2000ms
    And the system should handle 100+ concurrent users
    And error rates should be below defined thresholds
    And WebSocket connections should remain stable

  @error-handling @fallback
  Scenario: Error Handling and Fallback Mechanisms
    Given the API server is temporarily unavailable
    When I interact with UI components
    Then mock data should be served as fallback
    And error messages should be user-friendly
    And retry mechanisms should activate automatically
    And system should recover when API is restored

  @russian @localization
  Scenario: Russian Localization Integration
    Given I configure the system for Russian locale
    When I test employee management with Cyrillic data
    Then Cyrillic names should be validated correctly
    And error messages should display in Russian
    And time codes should follow 1C ZUP format
    And calendar should show Russian month names

  @reporting @export
  Scenario: Reporting and Export Integration
    Given analysis and data are available
    When I request various report formats
    Then Excel exports should be generated correctly
    And PDF reports should include all required data
    And CSV exports should maintain data integrity
    And report delivery should be schedulable