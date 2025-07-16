Feature: Real Reports Integration
  As a WFM user
  I want all report components to work with real backend APIs
  So that I can generate actual business reports and analytics

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token
    And the Reports API endpoints are available

  @real-integration @reports-portal
  Scenario: ReportsPortal loads real report data
    Given I navigate to the reports portal page
    When the component loads
    Then it should call GET "/api/v1/reports/list" to fetch available reports
    And it should call GET "/api/v1/reports/real-time" for live metrics
    And I should see a list of real reports with their status
    And I should see real-time metrics updating every 30 seconds
    And the API connection status should show as "Live Data"

  @real-integration @reports-portal @error-handling
  Scenario: ReportsPortal handles API failures gracefully
    Given the Reports API server is not responding
    When I navigate to the reports portal page
    Then I should see an error message "Reports API server is not available"
    And the API status should show as "API Offline"
    And I should see a "Retry" button to reconnect
    When I click the "Retry" button
    Then it should attempt to reconnect to the API

  @real-integration @report-builder
  Scenario: ReportBuilder generates real schedule adherence reports
    Given I navigate to the report builder page
    And the Reports API is available
    When I select "Schedule Adherence Report" as the report type
    And I set the period start to "2024-01-01"
    And I set the period end to "2024-01-31"
    And I select "Technical Support" as the department
    And I click "Generate Report"
    Then it should call POST "/api/v1/reports/schedule-adherence" with the parameters
    And I should receive a real response with adherence data
    And I should see a preview with actual employee metrics
    And I should see average adherence percentage
    And I should see total scheduled and actual hours

  @real-integration @report-builder @forecast-accuracy
  Scenario: ReportBuilder generates real forecast accuracy reports
    Given I navigate to the report builder page
    And the Reports API is available
    When I select "Forecast Accuracy Analysis" as the report type
    And I set the period start to "2024-01-01"
    And I set the period end to "2024-01-31"
    And I click "Generate Report"
    Then it should call GET "/api/v1/reports/forecast-accuracy" with query parameters
    And I should receive real MAPE, WAPE, and bias metrics
    And I should see interval analysis data
    And I should see daily analysis breakdown

  @real-integration @analytics-dashboard
  Scenario: AnalyticsDashboard displays real KPI metrics
    Given I navigate to the analytics dashboard page
    When the component loads
    Then it should call GET "/api/v1/reports/kpi-dashboard" for KPI data
    And it should call GET "/api/v1/reports/real-time" for current metrics
    And I should see real KPI metrics with current and target values
    And I should see color-coded status indicators (green/yellow/red)
    And I should see trend arrows (up/down/stable)
    And metrics should auto-refresh every 30 seconds

  @real-integration @analytics-dashboard @realtime
  Scenario: AnalyticsDashboard shows real-time operational data
    Given I navigate to the analytics dashboard page
    And the component has loaded KPI data
    Then I should see current staffing percentage from real data
    And I should see service level metrics from real data
    And I should see queue time and active agents count
    And I should see system health status (integration, database, API response time)
    When there are active alerts in the system
    Then I should see them displayed with appropriate severity colors

  @real-integration @export-manager
  Scenario: ExportManager creates real export jobs
    Given I navigate to the export manager page
    And the Export API is available
    When I click "New Export"
    And I select "Schedule Adherence Report" as the report type
    And I select "Excel" as the format
    And I set the date range to "Last 30 days"
    And I enter "user@company.com" as email recipient
    And I click "Create Export"
    Then it should call POST "/api/v1/exports/create" with the export request
    And I should receive a real export job ID
    And the job should appear in the export jobs list
    And the job status should show as "pending" or "processing"

  @real-integration @export-manager @download
  Scenario: ExportManager downloads completed export files
    Given I have a completed export job in the system
    And I navigate to the export manager page
    When I click "Download" on the completed job
    Then it should call GET "/api/v1/exports/download/{job_id}"
    And I should receive the actual file for download
    And the browser should initiate file download

  @real-integration @export-manager @job-management
  Scenario: ExportManager manages export job lifecycle
    Given I have export jobs in various states
    And I navigate to the export manager page
    Then I should see jobs with real status updates (pending, processing, completed, failed)
    When I have a job in "processing" state
    And I click "Cancel" on that job
    Then it should call POST "/api/v1/exports/cancel/{job_id}"
    And the job status should update to "failed" with "Cancelled by user" message

  @real-integration @report-scheduler
  Scenario: ReportScheduler creates real scheduled reports
    Given I navigate to the report scheduler page
    And the Scheduler API is available
    When I click "New Schedule"
    And I fill in the schedule form:
      | Field            | Value                     |
      | Name             | Weekly Adherence Report   |
      | Report Type      | Schedule Adherence Report |
      | Format           | Excel                     |
      | Schedule Pattern | Weekly                    |
      | Day of Week      | Monday                    |
      | Time             | 09:00                     |
      | Email Recipients | manager@company.com       |
    And I click "Create Schedule"
    Then it should call POST "/api/v1/reports/scheduled" with the schedule data
    And I should receive a real schedule ID
    And the schedule should appear in the scheduled reports list
    And it should show the correct schedule description "Weekly on Monday at 09:00"

  @real-integration @report-scheduler @crud-operations
  Scenario: ReportScheduler performs CRUD operations on schedules
    Given I have scheduled reports in the system
    And I navigate to the report scheduler page
    When the component loads
    Then it should call GET "/api/v1/reports/scheduled" to load schedules
    And I should see the list of real scheduled reports
    When I click "Edit" on a schedule
    And I modify the schedule name to "Updated Report Name"
    And I click "Update Schedule"
    Then it should call PUT "/api/v1/reports/scheduled/{schedule_id}" with updates
    When I click "Pause" on an active schedule
    Then it should call POST "/api/v1/reports/scheduled/{schedule_id}/toggle"
    And the schedule status should change to inactive
    When I click "Run Now" on a schedule
    Then it should call POST "/api/v1/reports/scheduled/{schedule_id}/run"
    And I should see a confirmation that the report was queued
    When I click "Delete" on a schedule
    And I confirm the deletion
    Then it should call DELETE "/api/v1/reports/scheduled/{schedule_id}"
    And the schedule should be removed from the list

  @real-integration @authentication
  Scenario: All report components handle authentication properly
    Given I am not authenticated
    When I try to access any report component
    Then all API calls should include the JWT token from realAuthService
    When the token is invalid or expired
    Then I should receive appropriate authentication errors
    And the components should handle token refresh gracefully

  @real-integration @error-handling
  Scenario: All report components handle API errors properly
    Given I am on any report component page
    When the backend API returns an error response
    Then I should see a user-friendly error message
    And I should see a "Retry" button to attempt the operation again
    And the error should be logged to the console for debugging
    When I click "Retry"
    Then the component should re-attempt the failed operation

  @real-integration @performance
  Scenario: Report components load and respond quickly
    Given I navigate to any report component
    When the component loads
    Then the initial API calls should complete within 5 seconds
    And real-time updates should occur within 30 seconds
    And the UI should remain responsive during data loading
    And loading indicators should be shown during API operations

  @real-integration @data-integrity
  Scenario: Report components display accurate real data
    Given I generate reports using the real API
    When I compare the data with the backend database
    Then the numbers should match exactly
    And date ranges should be applied correctly
    And department filters should work properly
    And all calculations should be accurate

  @real-integration @network-monitoring
  Scenario: Monitor actual API network requests
    Given I have browser developer tools open
    When I use any report component
    Then I should see real HTTP requests in the Network tab
    And requests should use the correct HTTP methods (GET, POST, PUT, DELETE)
    And request headers should include proper authentication
    And request bodies should contain the expected data
    And response status codes should be appropriate (200, 201, 400, 500, etc.)
    And no mock data should be used as fallback

  @real-integration @integration-test
  Scenario: End-to-end report workflow with real backend
    Given the complete WFM system is running
    When I create a scheduled report in ReportScheduler
    And the schedule triggers automatically
    Then a real export job should be created in ExportManager
    And the job should process using real data
    And the completed report should be available for download
    And email recipients should receive the actual report
    And the analytics dashboard should reflect the updated metrics
    And all operations should be logged in the backend system