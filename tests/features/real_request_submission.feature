# BDD Feature: REAL Request Submission Integration
# This tests the FIRST component with actual backend connectivity

Feature: Real Vacation Request Submission
  As an employee
  I want to submit vacation requests that actually reach the backend
  So that my requests are processed by the real system

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token
    And the user ID "user-123" is set in localStorage

  @real-integration @vacation-request
  Scenario: Submit vacation request to real API
    Given I navigate to the employee portal
    And I open the request form
    When I select "vacation" as the request type
    And I fill in the following details:
      | field           | value                    |
      | title          | Summer Vacation 2024     |
      | startDate      | 2024-08-01              |
      | endDate        | 2024-08-15              |
      | reason         | Family vacation planned for over a year |
      | priority       | normal                   |
      | emergencyContact | +7-999-123-4567       |
    And I submit the request
    Then the request should be sent to POST "/api/v1/requests/vacation"
    And I should receive a request ID from the backend
    And the request status should be "submitted"
    And I should see a success message with the request ID

  @real-integration @api-error-handling
  Scenario: Handle API server unavailable
    Given the API server is not running
    When I attempt to submit a vacation request
    Then I should see an error message "API server is not available"
    And the request should not be submitted
    And I should remain on the form to retry

  @real-integration @authentication
  Scenario: Handle missing authentication
    Given I have no authentication token
    When I attempt to submit a vacation request
    Then I should see an error message "No authentication token found"
    And the request should not be submitted

  @real-integration @validation
  Scenario: Handle backend validation errors
    Given the API server returns validation errors
    When I submit a vacation request with invalid data
    Then I should see the specific validation error from the backend
    And I should be able to correct the data and resubmit

  @real-integration @file-upload
  Scenario: Upload attachments with real request
    Given I have a medical certificate file "medical_cert.pdf"
    When I add the file as an attachment
    And I submit the vacation request
    Then the file should be uploaded to "/api/v1/files/upload"
    And the file URL should be included in the request payload
    And the backend should receive the attachment reference

  @real-integration @request-types
  Scenario: Verify only vacation requests work
    Given I open the request form
    When I select "sick_leave" as the request type
    And I attempt to submit the request
    Then I should see an error "Only vacation requests are currently supported"
    And no API call should be made