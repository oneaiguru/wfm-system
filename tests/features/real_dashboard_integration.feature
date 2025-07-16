Feature: Real Dashboard Components Integration
  As a workforce management user
  I want all dashboard components to work with real backend data
  So that I can monitor actual operations and metrics

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token

  @real-integration @dashboard
  Scenario: Main Dashboard loads real metrics
    Given I navigate to the main dashboard page
    When the dashboard loads
    Then it should fetch data from GET "/api/v1/metrics/dashboard"
    And I should see real active agents count
    And I should see real service level percentage
    And I should see real calls handled count
    And I should see real average wait time
    And the data should refresh every 30 seconds

  @real-integration @operational
  Scenario: Operational Control Dashboard displays real monitoring data
    Given I navigate to the operational control dashboard
    When the dashboard loads
    Then it should fetch data from GET "/api/v1/monitoring/operational"
    And I should see real operational metrics with traffic light indicators
    And I should see real agent status information
    And I should see agent performance data by queue
    And the metrics should update every 30 seconds

  @real-integration @realtime
  Scenario: Realtime Metrics shows live performance data
    Given I navigate to the realtime metrics page
    When the page loads
    Then it should fetch data from GET "/api/v1/metrics/realtime"
    And I should see real-time performance metrics
    And I should see queue performance tables
    And I should see system load and health indicators
    And the data should auto-refresh every 30 seconds

  @real-integration @performance
  Scenario: Performance Metrics displays comprehensive KPIs
    Given I navigate to the performance metrics page
    When I select a time period "today"
    Then it should fetch data from GET "/api/v1/metrics/performance?period=today"
    And I should see overall performance metrics by category
    And I should see top agent performers ranking
    And I should see team performance overview
    And I should be able to export performance reports

  @real-integration @alerts
  Scenario: Alerts Panel manages real alert notifications
    Given I navigate to the alerts panel
    When the panel loads
    Then it should fetch data from GET "/api/v1/alerts/active"
    And I should see active alerts with real severity levels
    And I should see alert details with timestamps and sources
    And I should be able to acknowledge alerts via API
    And I should be able to resolve alerts via API
    And the alerts should refresh every 30 seconds

  @real-integration @error-handling
  Scenario: Dashboard components handle API errors gracefully
    Given the API server is not available
    When I try to load any dashboard component
    Then I should see an error message "API server is not available"
    And I should see a retry button
    And when I click retry after the API is back online
    Then the dashboard should load successfully

  @real-integration @authentication
  Scenario: Dashboard components require valid authentication
    Given I have an invalid or expired authentication token
    When I try to access any dashboard component
    Then I should receive a 401 authentication error
    And I should be redirected to the login page

  @real-integration @real-time-updates
  Scenario: All dashboards support real-time data refresh
    Given any dashboard component is loaded
    When real-time refresh is enabled
    Then the component should automatically refresh data every 30 seconds
    And I should see a live indicator showing the last update time
    And I should be able to toggle auto-refresh on/off
    And I should be able to manually refresh the data

  @real-integration @performance-benchmarks
  Scenario: Performance metrics compare against real benchmarks
    Given I am viewing performance metrics
    When the data loads
    Then I should see industry benchmark comparisons
    And I should see internal benchmark data
    And I should see target achievement percentages
    And performance ratings should be calculated from real data

  @real-integration @alert-actions
  Scenario: Alert management performs real backend operations
    Given I have active alerts displayed
    When I acknowledge an alert
    Then it should call POST "/api/v1/alerts/{id}/acknowledge"
    And the alert should be marked as acknowledged in real-time
    When I resolve an alert
    Then it should call POST "/api/v1/alerts/{id}/resolve"
    And the alert should be removed from active alerts
    When I escalate an alert
    Then it should call POST "/api/v1/alerts/{id}/escalate"
    And the alert should be assigned to the escalated party

  @real-integration @data-consistency
  Scenario: All dashboard components show consistent real data
    Given multiple dashboard components are loaded
    When they all fetch data from the backend
    Then agent counts should be consistent across components
    And service level metrics should match between dashboards
    And alert counts should be synchronized
    And timestamp data should reflect real system time