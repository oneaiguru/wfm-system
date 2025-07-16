Feature: Real Login Authentication
  As a user of the WFM system
  I want to log in with my credentials
  So that I can access the system with proper authentication

  Background:
    Given the API server is running on port 8000
    And the UI application is running on port 3000

  Scenario: Successful login with valid credentials
    Given I am on the login page
    When I enter email "test@technoservice.ru"
    And I enter password "testpass123"
    And I click the "Login" button
    Then I should see "Logging in..." message
    And the API endpoint "/api/v1/auth/login" should be called with credentials
    And I should receive a JWT token
    And the token should be stored in localStorage
    And I should see "Welcome" message with the user's name
    And I should be redirected to "/dashboard" after 1.5 seconds

  Scenario: Failed login with invalid credentials
    Given I am on the login page
    When I enter email "invalid@example.com"
    And I enter password "wrongpass"
    And I click the "Login" button
    Then I should see "Logging in..." message
    And the API endpoint "/api/v1/auth/login" should be called
    And I should see an error message "Authentication failed"
    And no token should be stored in localStorage
    And I should remain on the login page

  Scenario: Login attempt with empty fields
    Given I am on the login page
    When I click the "Login" button without entering credentials
    Then I should see an error "Please enter both email and password"
    And no API call should be made
    And I should remain on the login page

  Scenario: API server not available
    Given I am on the login page
    And the API server is not responding
    When I enter email "test@technoservice.ru"
    And I enter password "testpass123"
    And I click the "Login" button
    Then I should see "API server is not available. Please try again later."
    And I should remain on the login page

  Scenario: Token verification on page load
    Given I have a valid JWT token in localStorage
    When I visit the dashboard page
    Then the API endpoint "/api/v1/auth/verify" should be called
    And I should be allowed to access the dashboard
    
  Scenario: Expired token handling
    Given I have an expired JWT token in localStorage
    When I visit the dashboard page
    Then the API endpoint "/api/v1/auth/verify" should be called
    And the token should be removed from localStorage
    And I should be redirected to the login page

  Scenario: Logout functionality
    Given I am logged in with a valid token
    When I click the logout button
    Then the API endpoint "/api/v1/auth/logout" should be called
    And the token should be removed from localStorage
    And the user data should be cleared
    And I should be redirected to the login page