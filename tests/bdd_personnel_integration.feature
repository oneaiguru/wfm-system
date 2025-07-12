# BDD Feature: Personnel Management UI-API Integration

Feature: Personnel Management Complete Integration
  As an HR administrator
  I want seamless integration between UI and personnel APIs
  So that employee management workflows operate correctly

  Background:
    Given the personnel API endpoints are available
    And the Enhanced Employee Profiles UI is accessible
    And I have valid authentication credentials

  @employee @crud @basic
  Scenario: Employee Profile Management
    Given I navigate to "/employees/enhanced-profiles"
    When I click "Add New Employee" 
    And I fill in the employee form with:
      | lastName   | Иванов      |
      | firstName  | Иван        |
      | middleName | Иванович    |
      | position   | Operator    |
      | department | Call Center |
    And I submit the form
    Then a new employee should be created via POST "/api/v1/personnel/employees"
    And the employee should appear in the list
    And Cyrillic validation should be applied correctly

  @skills @assignment @tracking
  Scenario: Skills Assignment Workflow
    Given an employee "Иван Иванов" exists in the system
    When I navigate to their profile
    And I click "Manage Skills"
    And I assign the following skills:
      | skillName        | proficiency | certification |
      | Customer Service | Expert      | Required      |
      | Technical Support| Advanced    | Optional      |
    Then skills should be saved via POST "/api/v1/personnel/employees/{id}/skills"
    And proficiency levels should be tracked
    And certification requirements should be managed

  @work-settings @compliance @labor-law
  Scenario: Work Settings Configuration
    Given an employee requires schedule constraints
    When I access their work settings
    And I configure:
      | maxOvertimeHours | 40          |
      | restPeriodHours  | 11          |
      | weekendWork      | Restricted  |
      | shiftRotation    | Enabled     |
    Then settings should be saved via PUT "/api/v1/personnel/employees/{id}/work-settings"
    And labor law compliance should be validated
    And scheduling constraints should be updated

  @performance @reviews @tracking
  Scenario: Performance Review Management
    Given performance review period is active
    When I navigate to employee performance section
    And I create a new review with:
      | reviewPeriod | Q1 2024    |
      | goals        | 3 objectives |
      | metrics      | KPI tracking |
    Then review should be saved to the personnel system
    And performance history should be updated
    And review reminders should be scheduled

  @training @certification @lifecycle
  Scenario: Training and Certification Tracking
    Given certification requirements exist
    When I register employee for training:
      | trainingName | Customer Service Excellence |
      | provider     | Internal Training Center   |
      | deadline     | 2024-12-31                 |
    Then training record should be created
    And certification tracking should begin
    And progress notifications should be enabled

  @hr-documents @lifecycle @audit
  Scenario: HR Document Management
    Given employee lifecycle events occur
    When I upload HR documents:
      | documentType | Contract        |
      | status       | Active          |
      | expiryDate   | 2025-06-30     |
    Then documents should be stored securely
    And audit trail should be maintained
    And expiry notifications should be scheduled

  @bulk-operations @import @export
  Scenario: Bulk Employee Operations
    Given I have employee data to import
    When I use bulk import functionality
    And I upload CSV file with employee data
    Then all valid records should be processed
    And error reports should highlight issues
    And import summary should be generated

  @search @filtering @pagination
  Scenario: Employee Search and Filtering
    Given multiple employees exist in the system
    When I use the search functionality with:
      | department | Call Center |
      | skills     | Customer Service |
      | status     | Active      |
    Then filtered results should be displayed
    And pagination should work correctly
    And search performance should be acceptable

  @mobile @responsive @access
  Scenario: Mobile Employee Access
    Given I access the system from mobile device
    When I navigate to employee profiles
    Then the interface should be mobile-responsive
    And core functionality should be available
    And performance should be optimized

  @offline @sync @continuity
  Scenario: Offline Data Synchronization
    Given I have offline capabilities enabled
    When internet connection is lost
    And I make changes to employee data
    Then changes should be cached locally
    And sync should occur when connection is restored
    And conflicts should be resolved appropriately