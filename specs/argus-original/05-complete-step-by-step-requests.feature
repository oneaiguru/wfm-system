Feature: Complete Requests Section - Step-by-Step BDD Specifications
  As a system developer
  I want detailed step-by-step BDD specs for request management
  So that I can build an identical system

  Background:
    Given I am authenticated in the Argus WFM employee portal with test/test
    And the enhanced Playwright MCP is working with direct API authentication
    And JWT token is stored in localStorage with user ID 111538

  # ============================================================================
  # STEP 1: REQUESTS LANDING PAGE
  # ============================================================================
  
  @step1 @requests_landing
  Scenario: Navigate to Requests Landing Page
    Given I am on any portal page
    When I click "Заявки" in the main navigation sidebar
    Then I should navigate to "https://lkcc1010wfmcc.argustelecom.ru/requests"
    And I should see the page title "Заявки" in the main content area
    And the "Заявки" navigation item should be highlighted as active
    And I should see the standard navigation sidebar with all menu items
    # URL TO SAVE: https://lkcc1010wfmcc.argustelecom.ru/requests

  @step1 @requests_landing_content
  Scenario: Verify Requests Landing Page Content
    Given I am on the requests landing page
    When I examine the page content
    Then I should see:
      | Element | Content |
      | Page Title | Заявки |
      | Navigation Status | Заявки marked as active |
      | Content State | Basic landing page (may be empty for users without requests) |
    And the page should be ready for navigation to request creation

  # ============================================================================
  # STEP 2: CALENDAR-BASED REQUEST CREATION
  # ============================================================================
  
  @step2 @calendar_navigation
  Scenario: Navigate to Calendar for Request Creation  
    Given I want to create a new request
    When I click "Календарь" in the main navigation
    Then I should navigate to "https://lkcc1010wfmcc.argustelecom.ru/calendar"
    And I should see the calendar interface with:
      | Element | Content |
      | Page Title | Календарь |
      | View Mode | Месяц (Month) |
      | Current Month | июнь 2025 (June 2025) |
      | Navigation | Сегодня (Today) button |
      | Primary Action | Создать (Create) button |
    # URL TO SAVE: https://lkcc1010wfmcc.argustelecom.ru/calendar

  @step2 @calendar_interface
  Scenario: Examine Calendar Interface Structure
    Given I am on the calendar page
    When I examine the calendar layout
    Then I should see:
      | Component | Description |
      | Monthly Grid | Days displayed as: пнвтсрчтптсбвс (Mon-Sun) |
      | Date Range | Showing current month with adjacent month dates |
      | Mode Selector | Режим предпочтений (Preferences Mode) |
      | Create Button | Создать (Create) - primary action for new requests |
    And the calendar should display June 2025 with full month view

  @step2 @request_creation_trigger
  Scenario: Trigger Request Creation Interface
    Given I am on the calendar page
    When I click the "Создать" (Create) button
    Then a request creation form should appear
    And I should see form elements:
      | Field | Type | Description |
      | Тип | Selection | Request type selector |
      | Calendar | Date Picker | Month/year selector showing "июнь 2025 г." |
      | Date Grid | Interactive | Clickable date selection grid |
      | Комментарий | Text Area | Comment field for request details |
      | Actions | Buttons | Отменить (Cancel) and Добавить (Add) |
    # URL TO SAVE: Same URL but with form opened

  @step2 @request_creation_form @live_tested
  Scenario: Request Creation Form - LIVE TESTED VALIDATION
    Given I click "Создать" button on calendar page
    When the request creation form opens with title "Создать"
    Then I should see these EXACT form elements:
      | Field Label | Russian | Type | Required | Validation Message |
      | Request Type | Тип | Dropdown | Yes | Поле должно быть заполнено |
      | Comment | Комментарий | Text Area | No | (no validation) |
      | Calendar | (calendar grid) | Date Picker | Yes | Заполните дату в календаре |
    And I should see these EXACT action buttons:
      | Button | Russian | Action |
      | Submit | Добавить | Save request |
      | Cancel | Отменить | Close without saving |
    And request type dropdown options are:
      | Option | Russian |
      | Sick Leave Request | Заявка на создание больничного |
      | Day Off Request | Заявка на создание отгула |
    
  @live_tested @validation_behavior
  Scenario: Form Validation Behavior - LIVE VERIFIED
    Given the request creation form is open
    When I click "Добавить" without filling any fields
    Then I should see validation errors:
      | Field | Error Message |
      | Type | Поле должно быть заполнено |
      | Date | Заполните дату в календаре |
    When I select "Заявка на создание больничного" from type dropdown
    And I add text "Test comment for validation" to comment field
    And I click "Добавить" again
    Then I should see only date validation: "Заполните дату в календаре"
    And type field validation should be cleared
    And comment field should show no validation errors

  @edge_cases @live_testable
  Scenario Outline: Comment Field Edge Cases - TESTABLE CASES
    Given the request creation form is open
    And I have selected "Заявка на создание больничного" as type
    When I enter "<comment_text>" in the comment field
    And I click "Добавить" (without selecting date)
    Then the comment should be accepted without validation errors
    And I should still see date validation: "Заполните дату в календаре"
    
    Examples:
      | comment_text |
      | Short text |
      | Very long comment with special characters: русский текст, numbers 123, symbols !@#$%^&*()_+-= |
      | Empty comment field should be accepted |
      | 123456789 |
      | Line 1\nLine 2\nLine 3 |

  # ============================================================================
  # STEP 3: EXCHANGE SYSTEM (SHIFT EXCHANGES)
  # ============================================================================
  
  @step3 @exchange_navigation
  Scenario: Navigate to Exchange System
    Given I want to manage shift exchanges
    When I click "Биржа" in the main navigation
    Then I should navigate to "https://lkcc1010wfmcc.argustelecom.ru/exchange"
    And I should see the exchange interface with:
      | Element | Content |
      | Page Title | Биржа |
      | Tab 1 | Мои (My exchanges) |
      | Tab 2 | Доступные (Available exchanges) |
      | Description | Предложения, на которые вы откликнулись |
    # URL TO SAVE: https://lkcc1010wfmcc.argustelecom.ru/exchange

  @step3 @exchange_table_structure
  Scenario: Examine Exchange Data Table Structure
    Given I am on the exchange page
    When I examine the exchange table
    Then I should see table columns:
      | Column | Russian | Purpose |
      | Period | Период | Date range of exchange |
      | Name | Название | Exchange description/title |
      | Status | Статус | Current exchange status |
      | Start | Начало | Start time/date |
      | End | Окончание | End time/date |
    And if no data exists, I should see "Отсутствуют данные" (No data available)

  @step3 @exchange_tabs_functionality
  Scenario: Verify Exchange Tabs Functionality
    Given I am on the exchange page
    When I interact with the exchange tabs
    Then I should be able to switch between:
      | Tab | Purpose |
      | Мои | View my own exchange requests |
      | Доступные | View available exchanges from others |
    And each tab should show relevant exchange data in the same table format
    And the description should update to match the selected tab context

  # ============================================================================
  # STEP 4: COMPLETE WORKFLOW INTEGRATION
  # ============================================================================
  
  @step4 @workflow_integration
  Scenario: Complete Request Workflow Integration
    Given I understand the three main request pathways
    When I map the complete workflow
    Then the system should support:
      | Pathway | Entry Point | Purpose |
      | Time Off Requests | Calendar → Создать | больничный/отгул/внеочередной отпуск |
      | Shift Exchanges | Calendar → Shift Selection | обмен сменами |
      | Exchange Management | Биржа → Tabs | View and respond to exchanges |
    And all pathways should integrate with the approval workflow
    And status tracking should be available in the Заявки section

  @step4 @business_process_mapping
  Scenario: Map to Original Business Process Requirements
    Given the original 5-step business process requirements
    When I map discovered functionality to requirements
    Then the system should fully support:
      | Step | Russian Process | Discovered Implementation |
      | 1 | Создание заявки на отгул/больничный/отпуск | Calendar → Создать → Type Selection |
      | 2 | Создание заявки на обмен сменами | Calendar → Shift → Создать заявку |
      | 3 | Принять заявку на обмен сменами | Биржа → Доступные → Accept |
      | 4 | Принять заявку (руководитель) | Заявки → Доступные → Approve |
      | 5 | Принять заявку на обмен (руководитель) | Заявки → Review Exchange |
    And all functionality is accessible through the documented navigation paths

  # ============================================================================
  # TECHNICAL IMPLEMENTATION DETAILS
  # ============================================================================
  
  @technical @vue_spa_architecture
  Scenario: Document Vue.js SPA Architecture Requirements
    Given the system is a Vue.js single-page application
    When implementing an identical system
    Then the technical requirements should include:
      | Component | Requirement |
      | Framework | Vue.js with Vuetify UI components |
      | Authentication | JWT tokens stored in localStorage |
      | Navigation | Client-side routing with active state management |
      | Calendar | Month view with date selection grid |
      | Forms | Modal/overlay forms with validation |
      | Tables | Data tables with empty state handling |
      | Tabs | Tab navigation for different data views |
    And the system should handle dynamic content loading and SPA state management

  @technical @authentication_api
  Scenario: Document Authentication Requirements
    Given successful authentication via enhanced MCP
    When implementing the authentication system
    Then the API should support:
      | Endpoint | Method | Purpose |
      | /gw/signin | POST | Username/password authentication |
      | Response | JSON | JWT token with user data |
      | Storage | localStorage | Token stored as "user" object |
      | User Data | JSON | ID, username, roles, timezone |
    And authentication should persist across SPA navigation