# features/shared/navigation.feature
Feature: Main Navigation
  As a workforce management user
  I want to navigate between different sections of the application
  So that I can access all available functionality

  Background:
    Given I am logged into the system
    And I am on the main dashboard

  Scenario: Navigate to Forecasts section
    When I click on "Прогнозы" in the main menu
    Then I should be taken to the forecasts page
    And the "Прогнозы" menu item should be highlighted as active

  Scenario: Navigate to Schedule section
    When I click on "Расписание" in the main menu
    Then I should be taken to the schedule page
    And the "Расписание" menu item should be highlighted as active
    And I should see the schedule sub-navigation

  Scenario: Navigate to Employees section
    When I click on "Сотрудники" in the main menu
    Then I should be taken to the employees page
    And the "Сотрудники" menu item should be highlighted as active

  Scenario: Navigate to Reports section
    When I click on "Отчеты" in the main menu
    Then I should be taken to the reports page
    And the "Отчеты" menu item should be highlighted as active

  Scenario: Schedule sub-navigation
    Given I am in the Schedule section
    When I click on "Смены" in the schedule sub-menu
    Then I should be taken to the shifts management page
    And the "Смены" sub-menu item should be highlighted as active

  Scenario: Navigate to Schema management
    Given I am in the Schedule section
    When I click on "Схемы" in the schedule sub-menu
    Then I should be taken to the schema management page
    And the "Схемы" sub-menu item should be highlighted as active

  Scenario: Navigate to Schedule Graph
    Given I am in the Schedule section
    When I click on "График" in the schedule sub-menu
    Then I should be taken to the schedule graph page
    And the "График" sub-menu item should be highlighted as active

  Scenario: Navigate to Schedule Requests
    Given I am in the Schedule section
    When I click on "Заявки" in the schedule sub-menu
    Then I should be taken to the schedule requests page
    And the "Заявки" sub-menu item should be highlighted as active