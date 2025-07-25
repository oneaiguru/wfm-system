Feature: Requests Section - Step-by-Step Navigation and BDD Specs
  As a system analyst 
  I want to document each step of the Requests functionality
  So that I can create identical system behavior

  Background:
    Given I am authenticated in the Argus WFM employee portal
    And I have navigated to the Requests section at "/requests"

  @step1 @requests_main_page
  Scenario: Access Requests Main Page
    Given I click on "Заявки" in the main navigation
    When the page loads
    Then I should be at URL "https://lkcc1010wfmcc.argustelecom.ru/requests"
    And I should see the page title "Заявки" (Requests)
    And I should see the navigation breadcrumb showing "Заявки" as active
    # Save URL: https://lkcc1010wfmcc.argustelecom.ru/requests

  @step2 @requests_sections
  Scenario: Examine Available Request Sections
    Given I am on the Requests main page
    When I examine the page structure
    Then I should see request management sections:
      | Section Name | Purpose |
      | Current requests view | Shows active requests |
      | Request creation interface | Allows new request creation |
      | Request status tracking | Shows request progression |
    # Next step: Explore request creation functionality

  @step3 @request_creation_navigation
  Scenario: Navigate to Request Creation
    Given I am on the Requests main page
    When I look for request creation options
    Then I should find a "Создать" (Create) button or link
    And clicking it should reveal request type options:
      | Request Type | Russian Term |
      | Sick Leave | больничный |
      | Day Off | отгул |
      | Unscheduled Vacation | внеочередной отпуск |
    # URL to capture: [Next navigation URL after clicking create]

  @step4 @request_types_interface
  Scenario: Document Request Type Selection Interface
    Given I am in the request creation interface
    When I examine the request type selection
    Then I should see form fields for:
      | Field | Type | Required |
      | Request Type | Dropdown/Radio | Yes |
      | Start Date | Date Picker | Yes |
      | End Date | Date Picker | Yes |
      | Reason/Comment | Text Area | Optional |
      | Duration | Calculated | Auto |
    # URL to capture: [Request creation form URL]

  @step5 @request_submission_flow
  Scenario: Document Request Submission Process
    Given I have filled out a request form
    When I submit the request
    Then the system should:
      | Action | Expected Result |
      | Validate required fields | Show validation errors if incomplete |
      | Create request record | Generate unique request ID |
      | Set initial status | Status = "Новый" (New) |
      | Show confirmation | Display success message |
      | Redirect to tracking | Show request in personal requests list |
    # URL to capture: [Post-submission confirmation/redirect URL]

  @step6 @request_tracking_interface
  Scenario: Document Request Status Tracking
    Given I have submitted a request
    When I view my requests list
    Then I should see a table with columns:
      | Column | Content |
      | Request ID | Unique identifier |
      | Type | больничный/отгул/внеочередной отпуск |
      | Start Date | Requested start date |
      | End Date | Requested end date |
      | Status | Новый/На рассмотрении/Подтвержден/Отказано |
      | Created Date | When request was submitted |
      | Actions | View/Edit/Cancel buttons |
    # URL to capture: [Request tracking/list URL]

  @step7 @request_status_progression
  Scenario: Document Request Status Workflow
    Given a request exists in the system
    When the request goes through approval workflow
    Then the status should progress as follows:
      | Status | Russian | Who Can Change | Next Possible Status |
      | New | Новый | Employee (cancel) | На рассмотрении |
      | Under Review | На рассмотрении | Supervisor | Подтвержден/Отказано |
      | Approved | Подтвержден | System | Final |
      | Rejected | Отказано | System | Final |
      | Cancelled | Отменен | Employee/Supervisor | Final |
    # Document: Status change notifications and user permissions

  @technical @api_endpoints
  Scenario: Identify API Endpoints for Request Management
    Given the requests functionality is operational
    When examining network traffic during request operations
    Then I should identify API endpoints:
      | Operation | Likely Endpoint | Method |
      | Get requests list | /api/v1/requests | GET |
      | Create new request | /api/v1/requests | POST |
      | Update request | /api/v1/requests/{id} | PUT |
      | Cancel request | /api/v1/requests/{id}/cancel | POST |
      | Get request types | /api/v1/directories/requestTypes | GET |
    # Technical documentation for API integration
