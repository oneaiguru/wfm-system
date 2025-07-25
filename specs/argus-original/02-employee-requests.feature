Feature: Employee Request Management Business Process
  As an employee and supervisor
  I want to create and manage different types of requests
  So that work schedules and time off can be properly managed

  Background:
    Given the employee portal is accessible at "https://lkcc1010wfmcc.argustelecom.ru/login"
    And employees can login with their credentials
    And supervisors have access to approval functions

  @employee @step1
  Scenario: Create Request for Time Off/Sick Leave/Unscheduled Vacation
    Given I am logged into the employee portal as an operator
    When I navigate to the "Календарь" tab
    And I click the "Создать" button
    And I select request type from:
      | Request Type |
      | больничный |
      | отгул |
      | внеочередной отпуск |
    And I fill in the corresponding fields
    And I submit the request
    Then the request should be created
    And I should see the request status on the "Заявки" page

  @employee @step2  
  Scenario: Create Shift Exchange Request
    Given I am logged into the employee portal as an operator
    When I navigate to the "Календарь" tab
    And I select a shift for exchange
    And I click on the "трёх точек" icon in the shift window
    And I select "Создать заявку"
    And I choose the date and time to work another employee's shift
    And I submit the request
    Then the shift exchange request should be created
    And I should see the request status on the "Заявки" page

  @employee @step3
  Scenario: Accept Shift Exchange Request
    Given I am logged into the employee portal as an operator
    And there are available shift exchange requests from other operators
    When I navigate to the "Заявки" tab
    And I select "Доступные"
    And I accept a shift exchange request from another operator
    Then the request status should be updated
    And I should see the updated status

  @supervisor @step4 @1c_zup_integration
  Scenario: Approve Time Off/Sick Leave/Unscheduled Vacation Request with 1C ZUP Integration
    Given I am logged in as a supervisor
    And there are pending requests for approval
    When I navigate to the "Заявки" page
    And I select "Доступные"
    And I choose to approve or reject the request for:
      | Request Type | 1C ZUP Document Type | Time Type Created |
      | отгул | Time off deviation document | NV (НВ) - Absence |
      | больничный | Sick leave document | Sick leave time type |
      | внеочередной отпуск | Unscheduled vacation document | OT (ОТ) - Vacation |
    Then the request status should be updated
    And the system should trigger 1C ZUP integration:
      | Integration Step | API Call | Expected Result |
      | Calculate deviation time | sendFactWorkTime with actual absence period | 1C ZUP creates appropriate time type document |
      | Document creation | Automatic document generation in 1C ZUP | Time deviation properly recorded |
      | Confirmation | Receive 1C ZUP success response | Integration confirmed |
    And I should verify the employee's work schedule changes
    And 1C ZUP should show the created absence/vacation document

  @supervisor @step5
  Scenario: Approve Shift Exchange Request
    Given I am logged in as a supervisor
    And there are pending shift exchange requests
    When I navigate to the request approval section
    And I review the shift exchange details
    And I approve the shift exchange
    Then both employees' schedules should be updated
    And the request status should show as approved

  @validation
  Scenario Outline: Request Status Tracking
    Given a request of type "<request_type>" has been created
    When the request goes through the approval process
    Then the status should progress through:
      | Status |
      | Создана |
      | На рассмотрении |
      | Одобрена/Отклонена |
    And all parties should see the current status

    Examples:
      | request_type |
      | больничный |
      | отгул |
      | внеочередной отпуск |
      | обмен сменами |
