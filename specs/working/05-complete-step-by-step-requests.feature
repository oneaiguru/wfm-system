Feature: Complete Requests Section - Step-by-Step BDD Specifications
  As a system developer
  I want detailed step-by-step BDD specs for request management
  So that I can build an identical system

  Background:
    Given I am authenticated in the Argus WFM employee portal with test/test
    And the enhanced Playwright MCP is working with direct API authentication
    And JWT token is stored in localStorage with user ID 111538

  # ============================================================================
  # STEP 1: JWT AUTHENTICATION PATTERNS (DISCOVERED)
  # ============================================================================
  
  # VERIFIED: 2025-07-30 - Hidden feature discovered during R2 systematic exploration
  # REALITY: Employee portal uses JWT authentication with long-lived tokens
  # IMPLEMENTATION: JWT stored in localStorage, expires 2025-08-01 (long-lived)
  # UI_FLOW: Login → JWT token generation → localStorage storage → Session persistence
  # API: POST /gw/signin generates JWT, token structure includes user_id, timezone
  # SECURITY: Long JWT expiry for convenience vs admin portal short sessions
  # RUSSIAN_TERMS: 
  #   - Личный кабинет = Personal Cabinet/Portal
  #   - Войти в систему = Log into system
  @hidden-feature @discovered-2025-07-30 @jwt-authentication
  Scenario: JWT Token Management in Employee Portal
    Given I access the employee portal login page
    When I enter credentials "test/test"
    And I click "Войти в систему" (Log into system)
    Then the system should generate a JWT token
    And the token should be stored in localStorage with key "user"
    And the token should contain:
      | Field | Value | Purpose |
      | sub | test | Username |
      | user_id | 111538 | Internal user ID |
      | TZ | Asia/Yekaterinburg | User timezone |
      | exp | Future timestamp | Token expiry |
    And the token should remain valid for extended period (not 22-minute timeout)
    And the session should persist across browser restarts

  # VERIFIED: 2025-07-30 - Hidden feature discovered
  # REALITY: Directory APIs provide configuration data not documented in specs
  # IMPLEMENTATION: Multiple directory endpoints loaded at login
  # API_CALLS: /gw/api/v1/directories/prefValues/, /eventTypes/, /calendarColorLegends/, /channelColorLegends/
  # PURPOSE: UI configuration, color schemes, event types, preferences
  @hidden-feature @discovered-2025-07-30 @directory-apis
  Scenario: Directory Configuration APIs
    Given I am logged into the employee portal
    Then the system should load directory configuration via APIs:
      | API Endpoint | Purpose | Usage |
      | /gw/api/v1/directories/prefValues/ | User preferences | UI customization |
      | /gw/api/v1/directories/eventTypes/ | Calendar event types | Event categorization |
      | /gw/api/v1/directories/calendarColorLegends/ | Calendar colors | Visual organization |
      | /gw/api/v1/directories/channelColorLegends/ | Channel colors | Communication channels |
    And these should be cached in the application state
    And should provide configuration for the entire portal

  # VERIFIED: 2025-07-30 - Hidden feature discovered
  # REALITY: Vuex state management with localStorage persistence
  # IMPLEMENTATION: Application state stored in localStorage key "vuex"
  # TECHNICAL: Vue.js + Vuex architecture with state persistence
  # MISSING: State synchronization across browser tabs
  @hidden-feature @discovered-2025-07-30 @state-management
  Scenario: Application State Management
    Given I am using the employee portal
    Then the application should use Vuex for state management
    And the application state should be persisted in localStorage
    And the state should include:
      | State Category | Purpose | Persistence |
      | User session | Authentication state | localStorage |
      | UI preferences | Theme, layout settings | localStorage |
      | Application data | Cached API responses | Memory |
    But the state should not sync across browser tabs (limitation)

  # ============================================================================
  # STEP 2: REQUESTS LANDING PAGE
  # ============================================================================
  
  # VERIFIED: 2025-07-30 - Hidden feature discovered
  # REALITY: Error recovery patterns not in original specs
  # IMPLEMENTATION: Custom 404 page, form validation, limited retry mechanisms
  # UI_FLOW: Error occurs → Custom error page → "Вернуться назад" option
  # MISSING: Automatic retry for failed API calls, connection recovery
  # RUSSIAN_TERMS:
  #   - Упс.. = Oops..
  #   - Вернуться назад = Return back
  #   - Поле должно быть заполнено = Field must be filled
  @hidden-feature @discovered-2025-07-30 @error-recovery
  Scenario: Error Recovery Patterns
    Given I am using the employee portal
    When I encounter various error conditions:
      | Error Type | Error Message | Recovery Option |
      | 404 Page | Упс.. | Вернуться назад |
      | Form validation | Поле должно быть заполнено | Field highlighting |
      | Network error | Connection failed | Manual retry required |
    Then the system should show appropriate error messages
    And provide recovery options where available
    But automatic retry mechanisms should not be available (limitation)
    And connection recovery should require manual refresh (missing feature)

  # VERIFIED: 2025-07-30 - Hidden feature discovered
  # REALITY: Request form has Vue.js specific bug not documented
  # IMPLEMENTATION: "Причина" field self-clears, known Vue.js issue
  # WORKAROUND: Users must re-enter reason text multiple times
  # BUG_REPORT: Vue.js reactive form bug affecting request creation
  @hidden-feature @discovered-2025-07-30 @vue-form-bug @known-issue
  Scenario: Request Form Vue.js Bug
    Given I am creating a new request in the employee portal
    When I fill in the "Причина" (Reason) field
    And I interact with other form fields
    Then the "Причина" field should inappropriately clear itself
    And I should need to re-enter the reason text
    And this should be a known Vue.js reactive form issue
    And users should be aware this requires multiple attempts

