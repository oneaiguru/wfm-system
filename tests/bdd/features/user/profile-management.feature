# features/user/profile-management.feature
Feature: User Profile Management
  As an employee
  I want to manage my profile information
  So that my personal data is up to date

  Background:
    Given I am logged in as an employee
    And I have navigated to my profile section

  Scenario: View profile information
    When I access my profile
    Then I should see my personal information
    Including my name, employee ID, and department
    And I should see my contact information
    And I should see my current role and permissions

  Scenario: Update contact information
    Given I am viewing my profile
    When I click "Edit Contact Information"
    And I update my phone number
    And I update my email address
    And I click "Save"
    Then my contact information should be updated
    And I should see a confirmation message

  Scenario: Change password
    Given I am viewing my profile
    When I click "Change Password"
    And I enter my current password
    And I enter a new password twice
    And I click "Update Password"
    Then my password should be changed
    And I should see a confirmation message

  Scenario: View employment details
    Given I am viewing my profile
    When I click on "Employment Details" tab
    Then I should see my hire date
    And I should see my current position
    And I should see my assigned skills
    And I should see my work schedule type