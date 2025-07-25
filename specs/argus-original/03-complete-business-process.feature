# 🎉 COMPLETE BUSINESS PROCESS BDD SPECIFICATIONS
# Based on Successful Argus WFM Employee Portal Access

Feature: Argus WFM Employee Portal - Complete Business Process
  As an employee and supervisor in the WFM system
  I want to create and manage work requests and shift exchanges
  So that work schedules can be properly coordinated

  Background:
    Given the enhanced Playwright MCP server is active
    And the employee portal is accessible at "https://lkcc1010wfmcc.argustelecom.ru"
    And I can authenticate using direct API calls to "/gw/signin"

  # ============================================================================
  # AUTHENTICATION & ACCESS - VERIFIED WORKING
  # ============================================================================
  
  @authentication @verified
  Scenario: Successful Employee Portal Authentication
    Given I navigate to "https://lkcc1010wfmcc.argustelecom.ru/login"
    When I execute JavaScript to call the signin API with:
      | username | test |
      | password | test |
    Then a JWT token should be stored in localStorage
    And I should see user data with ID "111538"
    And I should be redirected to the calendar page "/calendar"

  @navigation @verified  
  Scenario: Employee Portal Navigation Access
    Given I am authenticated in the employee portal
    When I examine the main navigation
    Then I should see the following menu options:
      | Menu Item     | URL       | Purpose                    |
      | Календарь     | /calendar | Calendar and schedule view |
      | Профиль       | /user-info| User profile information   |
      | Оповещения    | /notifications | System notifications  |
      | Заявки        | /requests | Request management        |
      | Биржа         | /exchange | Shift exchange system     |
      | Ознакомления  | /introduce| Introductions/Training    |
      | Пожелания     | /desires  | Work preferences          |

  # ============================================================================
  # STEP 1: CREATE TIME OFF/SICK LEAVE/VACATION REQUESTS
  # ============================================================================
  
  @employee @step1 @requests
  @employee @step1 @calendar_integration
  Scenario: Create Request via Calendar Interface
    Given I am logged into the employee portal as "test"
    And I navigate to the "Календарь" (Calendar) section
    When I click the "Создать" (Create) button
    And I select a request type
    And I specify the dates and reason
    And I submit the calendar request
    Then the request should appear in both calendar and requests sections

  # ============================================================================
  # STEP 2: CREATE SHIFT EXCHANGE REQUESTS  
  # ============================================================================
  
  @employee @step2 @exchange
  @employee @step2 @exchange_verification
  Scenario: Verify Exchange Request in Exchange System
    Given I have created a shift exchange request
    When I navigate to the "Биржа" (Exchange) section
    And I select the "Мои" (My) tab
    Then I should see my exchange request with columns:
      | Column      | Russian Term | Content                    |
      | Period      | Период       | Date range of exchange     |
      | Name        | Название     | Exchange description       |
      | Status      | Статус       | Current request status     |
      | Start       | Начало       | Start time                 |
      | End         | Окончание    | End time                   |

  # ============================================================================
  # STEP 3: ACCEPT SHIFT EXCHANGE REQUESTS
  # ============================================================================
  
  @employee @step3 @exchange_accept
  Scenario: Accept Available Shift Exchange Request
    Given I am logged into the employee portal as "test"
    And there are available shift exchange requests from other operators
    When I navigate to the "Биржа" (Exchange) section
    And I select the "Доступные" (Available) tab
    And I see exchange offers in the list
    And I select an exchange request from another operator
    And I click "Принять" (Accept) or equivalent action
    Then the request status should be updated
    And I should see the updated status in "Мои" (My) section
    And the system should show "Предложения, на которые вы откликнулись" (Offers you responded to)

  # ============================================================================
  # STEP 4 & 5: SUPERVISOR APPROVAL WORKFLOWS
  # ============================================================================
  
  @supervisor @step4 @approval
  Scenario: Supervisor Approve Time Off/Sick Leave/Vacation Request
    Given I am logged in as a supervisor role
    And there are pending requests for approval
    When I navigate to the "Заявки" (Requests) section
    And I select "Доступные" (Available) requests
    And I review requests for:
      | Request Type         | Russian Term        |
      | Day Off             | отгул               |
      | Sick Leave          | больничный          |
      | Unscheduled Vacation| внеочередной отпуск |
    And I choose to approve or reject the request
    Then the request status should be updated to "Подтвержден" (Confirmed) or "Отказано" (Rejected)
    And I should verify the employee's work schedule changes
    And the employee should see the updated status

  @supervisor @step5 @exchange_approval
  Scenario: Supervisor Approve Shift Exchange Request  
    Given I am logged in as a supervisor role
    And there are pending shift exchange requests
    When I navigate to the exchange approval section
    And I review the shift exchange details
    And I approve the shift exchange
    Then both employees' schedules should be updated
    And the request status should show as "Выполнено" (Completed)
    And both participants should see the confirmed exchange

  # ============================================================================
  # VALIDATION & STATUS TRACKING
  # ============================================================================
  
  @validation @status_tracking
  Scenario Outline: Request Status Progression Tracking
    Given a request of type "<request_type>" has been created
    When the request goes through the approval process
    Then the status should progress through the workflow:
      | Status               | Russian Term    | Description                  |
      | Created              | Новый           | Initial creation             |
      | Under Review         | На рассмотрении | Pending supervisor review    |
      | Approved/Rejected    | Подтвержден/Отказано | Final decision        |
    And all parties should see the current status in the system
    And notifications should be sent for status changes

    Examples:
      | request_type         |
      | больничный           |
      | отгул                |
      | внеочередной отпуск  |
      | обмен сменами        |

  # ============================================================================
  # TECHNICAL VALIDATION - AUTHENTICATION & API
  # ============================================================================
  
  @technical @authentication_api
  Scenario: Direct API Authentication Validation
    Given the Argus WFM system API endpoint "/gw/signin"
    When I make a POST request with valid credentials:
      ```json
      {
        "username": "test",
        "password": "test"
      }
      ```
    Then I should receive a JWT token response
    And the token should contain user data:
      | Field    | Value                    |
      | user_id  | 111538                   |
      | username | test                     |
      | TZ       | Asia/Yekaterinburg       |
    And the token should be stored in localStorage as "user"

  @technical @spa_framework
  Scenario: Vue.js SPA Framework Validation
    Given the employee portal is a Vue.js single-page application
    When I navigate to any section of the portal
    Then the client-side routing should work properly
    And Vue.js components should be properly initialized
    And localStorage should maintain authentication state
    And the SPA should handle navigation without page refreshes