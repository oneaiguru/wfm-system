Feature: Real Employee Integration
  As a WFM system user
  I want employee operations to work with real backend APIs
  So that I can manage employees with actual data persistence

  Background:
    Given the API server is running on localhost:8000
    And the UI application is accessible on localhost:3000
    And I have a valid authentication token

  @real-integration @employee-list
  Scenario: Employee List loads from real API
    Given I navigate to the employee list page
    When the page loads
    Then the system should call GET "/api/v1/personnel/employees"
    And I should see employee data loaded from the real database
    And employee statistics should be displayed correctly
    And pagination should work with real data

  @real-integration @employee-list @filtering
  Scenario: Employee List filtering with real API
    Given I am on the employee list page with real data loaded
    When I enter "anna" in the search field
    Then the system should call GET "/api/v1/personnel/employees" with search parameter
    And I should see filtered results from the real API
    And the results should update in real-time

  @real-integration @employee-list @export
  Scenario: Export employees with real API
    Given I am on the employee list page
    And I have selected some employees
    When I click the "Export" button
    Then the system should call POST "/api/v1/personnel/employees/export"
    And I should receive a real download link
    And the file should contain actual employee data

  @real-integration @profile-view
  Scenario: Profile View loads user's real profile
    Given I navigate to the profile page
    When the page loads
    Then the system should call GET "/api/v1/profile/me"
    And I should see my real profile data from the backend
    And all fields should display current information
    And performance metrics should show real data

  @real-integration @profile-view @editing
  Scenario: Profile editing saves to real backend
    Given I am on the profile page with real data loaded
    When I click "Edit Profile"
    And I change my phone number to "+7 495 999 8888"
    And I click "Save"
    Then the system should call PUT "/api/v1/profile/me"
    And my profile should be updated in the real database
    And I should see a success confirmation
    And the data should persist on page refresh

  @real-integration @employee-create
  Scenario: Create new employee with real API
    Given I navigate to the employee creation page
    When I fill in the employee form with valid data:
      | firstName    | John           |
      | lastName     | Smith          |
      | email        | john@test.com  |
      | position     | Senior Operator|
      | team         | Support Team   |
      | department   | Support        |
      | contractType | full-time      |
      | workLocation | Moscow Office  |
      | hireDate     | 2024-01-01     |
    And I click "Add Employee"
    Then the system should call POST "/api/v1/personnel/employees"
    And the employee should be created in the real database
    And I should see a success message with the new employee ID
    And the form should be reset for next entry

  @real-integration @employee-create @validation
  Scenario: Employee creation with duplicate email fails
    Given I navigate to the employee creation page
    When I fill in the form with an email that already exists
    And I click "Add Employee"
    Then the system should call POST "/api/v1/personnel/employees"
    And I should receive a 409 conflict error from the API
    And I should see an error message "Employee with this email already exists"
    And the form should remain filled for correction

  @real-integration @employee-edit
  Scenario: Edit existing employee with real API
    Given I navigate to edit employee with ID "emp_001"
    When the page loads
    Then the system should call GET "/api/v1/personnel/employees/emp_001"
    And I should see the employee's current data loaded from the database
    When I change the position to "Team Lead"
    And I click "Save Changes"
    Then the system should call PUT "/api/v1/personnel/employees/emp_001"
    And the employee should be updated in the real database
    And I should see a success confirmation

  @real-integration @employee-edit @permissions
  Scenario: Edit employee without permission fails
    Given I have limited permissions
    And I navigate to edit employee with ID "emp_001"
    When I try to save changes
    Then the system should call PUT "/api/v1/personnel/employees/emp_001"
    And I should receive a 403 forbidden error from the API
    And I should see an error message about insufficient permissions

  @real-integration @employee-search
  Scenario: Search employees with real API
    Given I navigate to the employee search page
    When I enter "manager" in the search field
    And I click "Search"
    Then the system should call POST "/api/v1/personnel/search"
    And I should see search results from the real database
    And the results should match the search criteria
    And I should see pagination for large result sets

  @real-integration @employee-search @advanced-filters
  Scenario: Advanced search with filters uses real API
    Given I am on the employee search page
    When I expand advanced filters
    And I select "Support Team" filter
    And I select "Senior Operator" position filter
    And I click "Search"
    Then the system should call POST "/api/v1/personnel/search" with filters
    And I should see employees that match all selected criteria
    And the results should come from the real backend

  @real-integration @employee-search @selection
  Scenario: Select employee from search results
    Given I have performed a search with results displayed
    When I click on an employee in the search results
    Then the employee selection callback should be triggered
    And the selected employee data should be real backend data
    And I should be able to perform actions on the selected employee

  @real-integration @error-handling
  Scenario: Handle API server unavailable gracefully
    Given the API server is not running
    When I navigate to any employee page
    Then I should see an error message "API server is not available"
    And I should see a "Try Again" button
    And no mock data should be displayed
    And the user should understand this is a real system error

  @real-integration @authentication
  Scenario: Handle authentication token expiry
    Given my authentication token has expired
    When I perform any employee operation
    Then the system should receive a 401 unauthorized error
    And I should be prompted to login again
    And the token should be cleared from storage
    And I should be redirected to the login page

  @real-integration @data-persistence
  Scenario: Verify data persistence across sessions
    Given I create a new employee via the real API
    When I logout and login again
    And I navigate to the employee list
    Then the newly created employee should still be visible
    And all employee data should be preserved
    And the data should match what was originally entered

  @real-integration @concurrent-updates
  Scenario: Handle concurrent employee updates
    Given employee "emp_001" is being edited by another user
    When I try to save changes to the same employee
    Then the system should handle the conflict appropriately
    And I should see an appropriate error or warning message
    And the data integrity should be maintained

  @real-integration @performance
  Scenario: Employee list loads with acceptable performance
    Given the database contains 1000+ employees
    When I load the employee list page
    Then the initial load should complete within 3 seconds
    And pagination should respond within 1 second
    And search operations should complete within 2 seconds
    And the UI should remain responsive during operations