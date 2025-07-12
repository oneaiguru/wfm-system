# features/admin/schedule-management.feature

Feature: Schedule Grid Management
  As a WFM supervisor
  I want to manage employee schedules in a grid view
  So that I can efficiently assign shifts to 500+ employees

  Background:
    Given I am logged in as a supervisor
    And the "Контакт-центр 1010" contact center is selected
    And I navigate to the schedule management section

  Scenario: View monthly schedule grid
    Given I have 500+ employees in the system
    When I select date range "01.07.2024" to "31.07.2024"
    Then I see the virtualized grid with all employees listed vertically
    And I see dates displayed horizontally for July 2024
    And each cell shows current shift assignment or is empty
    And weekend days (Saturday/Sunday) are highlighted in bold
    And the current day "17.07" is highlighted with context color

  Scenario: Filter employees by skills
    Given I am viewing the schedule grid
    When I click on the skills filter dropdown
    And I select skill "Входящая линия_1"
    Then only employees with the selected skill are displayed
    And the skill filter shows colored indicator for "Входящая линия_1"
    And the total employee count updates accordingly

  Scenario: Search employees by name
    Given I am viewing the schedule grid
    When I enter "Абдуллаева" in the employee search field
    Then only employees matching "Абдуллаева" are shown
    And the search results are highlighted
    And I can click on the dropdown to see suggestions

  Scenario: Select all employees
    Given I am viewing the schedule grid
    When I click the "Все" (All) checkbox in the header
    Then all visible employees are selected
    And individual employee checkboxes are checked
    And bulk actions become available

  Scenario: Navigate between time periods
    Given I am viewing July 2024 schedule
    When I change the start date to "01.08.2024"
    And I change the end date to "31.08.2024"
    And I click the refresh button
    Then the grid updates to show August 2024
    And week numbers are updated accordingly (week 31, 32, etc.)

  Scenario: View forecast and plan charts
    Given I am viewing the schedule grid
    When I look at the chart panel above the grid
    Then I see "Прогноз + план" (Forecast + Plan) mode is active
    And the chart displays forecast data for the selected period
    And chart controls show options for "Отклонения" and "Уровень сервиса (SL)"

  Scenario: Calculate FTE values
    Given I have schedule data loaded
    When I click the "FTE" recalculation button
    Then the system recalculates Full Time Equivalent values
    And FTE data is updated in the grid
    And I can optionally view FTE sum information

  Scenario: Build schedule automatically
    Given I am viewing the schedule grid
    When I click the "Построить" (Build) button
    Then the system generates automatic schedule assignments
    And the grid updates with new shift assignments
    And I see success feedback for the operation

  Scenario: Publish schedule changes
    Given I have made changes to the schedule
    When the publish button shows "Есть неопубликованные изменения"
    And I click the publish button
    Then the schedule changes are published to employees
    And the publish status updates to current state
    And employees can see the new schedule

  Scenario: Import activities from Excel
    Given I am viewing the schedule grid
    When I click the import button
    And I select an Excel file with activity data
    Then the activities are imported into the system
    And the schedule grid updates with imported data

  @performance
  Scenario: Handle large employee datasets
    Given I have 500+ employees in the contact center
    When I open the schedule grid
    Then the virtualized table loads efficiently
    And scrolling through employees is smooth
    And the interface remains responsive during operations