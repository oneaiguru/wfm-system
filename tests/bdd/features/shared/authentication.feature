# features/shared/authentication.feature
Feature: User Authentication
  As a workforce management user
  I want to securely log into the system
  So that I can access my assigned functions

  Background:
    Given the system is available
    And the login page is displayed

  Scenario: Successful login with valid credentials
    Given I have valid user credentials
    When I enter my username and password
    And I click the login button
    Then I should be redirected to the main dashboard
    And I should see my user avatar in the header
    And I should see the logout option

  Scenario: Failed login with invalid credentials
    Given I have invalid user credentials
    When I enter incorrect username or password
    And I click the login button
    Then I should see an error message
    And I should remain on the login page

  Scenario: User logout
    Given I am logged into the system
    When I click the logout button
    Then I should be logged out
    And I should be redirected to the login page