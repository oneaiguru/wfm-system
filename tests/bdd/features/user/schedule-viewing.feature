# features/user/schedule-viewing.feature
Feature: Employee Schedule Viewing
  As an employee
  I want to view my work schedule
  So that I can know when I'm supposed to work

  Background:
    Given I am logged in as an employee
    And I have navigated to the schedule section

  Scenario: View current week schedule
    When I access my schedule
    Then I should see my schedule for the current week
    And I should see my assigned shifts with start and end times
    And I should see any break periods within my shifts

  Scenario: Navigate between weeks
    Given I am viewing my current week schedule
    When I click the "Next Week" button
    Then I should see my schedule for the next week
    When I click the "Previous Week" button
    Then I should see my schedule for the previous week

  Scenario: View schedule details
    Given I have shifts scheduled this week
    When I click on a specific shift
    Then I should see detailed information about that shift
    Including the exact start and end time
    And any special notes or requirements
    And the location or department assignment

  Scenario: Export personal schedule
    Given I am viewing my schedule
    When I click the "Export" button
    Then I should be able to download my schedule
    And I can choose between PDF or Excel format

  Scenario: View schedule changes
    Given my schedule has been modified
    When I view my schedule
    Then I should see highlighted changes
    And I should see when the change was made
    And I should see who approved the change