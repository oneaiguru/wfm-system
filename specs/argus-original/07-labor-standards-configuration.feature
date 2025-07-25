Feature: Labor Standards Configuration - Complete Administrative Setup
  As a system administrator
  I want to configure comprehensive labor standards and normatives
  So that the system enforces compliance with labor laws and regulations

  Background:
    Given I am logged in as an administrator
    And I have access to "References" → "Labor Standards" 
    And the system supports multiple compliance frameworks
    And I can navigate to "Справочники" → "Трудовые нормативы"

  # ============================================================================
  # BUSINESS PROCESS #1: ПЕРВИЧНАЯ НАСТРОЙКА СИСТЕМЫ - ТРУДОВЫЕ НОРМАТИВЫ
  # Based on paste.txt detailed steps
  # ============================================================================

  @bp1 @labor_standards @rest_norm_detailed
  Scenario: Configure Rest Norm with Exact UI Steps
    Given I navigate to "Справочники" → "Трудовые нормативы"
    When I configure rest norm in block "Норма отдыха":
      | Step | Action | Parameter |
      | 1 | Set continuous rest norm | 42 hours per week |
      | 2 | Choose usage type | Учитывать (Consider) |
    And I select usage type from options:
      | Option | Russian | Behavior |
      | Ignore | Игнорировать | No enforcement |
      | Consider | Учитывать | Track violations |
      | Warn | Предупреждать | Show warnings |
      | Planning only | Использовать только при планировании | Apply during planning |
    Then the system should enforce 42-hour rest periods
    And prevent manual violations during schedule planning
    And show warnings for scheduling attempts that violate rest norms
    And automatically adjust schedules to maintain compliance

  @bp1 @labor_standards @night_work_detailed
  Scenario: Configure Night Work with Complete Parameters
    Given I am in block "Ночное время" (Night Time)
    When I configure night work parameters following exact steps:
      | Step | Parameter | Value | UI Element |
      | 1 | Set night hours | 22:00-06:00 | Time range selector |
      | 2 | Choose usage type | Предупреждать | Dropdown selection |
      | 3 | Set night supplement | 20% | Percentage input |
    And I select night work usage type:
      | Option | Russian | Effect |
      | Ignore | Игнорировать | No night work restrictions |
      | Consider | Учитывать | Track night work |
      | Warn | Предупреждать | Warning for unauthorized |
      | Planning only | Использовать только при планировании | Planning constraints only |
    Then employees without night work permission should receive warnings
    And night work supplement should calculate automatically at 20%
    And the system should track night work limits per employee
    And night work should be highlighted in schedules

  @bp1 @labor_standards @accumulated_vacation_detailed
  Scenario: Configure Accumulated Vacation Days with Exact Steps
    Given I am in block "Накопленные дни отпуска" (Accumulated Vacation Days)
    When I configure accumulated vacation handling:
      | Step | Action | Options |
      | 1 | Choose usage type | Игнорировать/Учитывать/Предупреждать |
    And I select "Учитывать" (Consider) option
    Then the system should:
      | Action | Result |
      | Track accumulated days | Monitor employee vacation balances |
      | Warn on excess | Alert when carryover limits exceeded |
      | Enforce policies | Apply vacation day expiration rules |
      | Prevent conflicts | Check vacation entitlements |

  @bp1 @labor_standards @daily_norm_detailed
  Scenario: Configure Daily Work Norm with Complete Settings
    Given I am in block "Норматив в день" (Daily Norm)
    When I configure daily work limits following steps:
      | Step | Parameter | Configuration |
      | 1 | Choose usage type | Использовать только при планировании |
    And I select from daily norm options:
      | Option | Russian | Application |
      | Ignore | Игнорировать | No daily limits |
      | Consider | Учитывать | Track daily hours |
      | Warn | Предупреждать | Warning on excess |
      | Planning only | Использовать только при планировании | Planning stage only |
    Then the system should apply daily norms during planning
    And calculate overtime for hours beyond standard daily norm
    And track compliance across all planned schedules

  @bp1 @labor_standards @weekly_norm_detailed  
  Scenario: Configure Weekly Work Norm with Usage Types
    Given I am in block "Норматив в неделю" (Weekly Norm)
    When I configure weekly work limits:
      | Step | Parameter | Options |
      | 1 | Choose usage type | Игнорировать/Учитывать/Предупреждать/Использовать только при планировании |
    And I select "Предупреждать" (Warn) option
    Then the system should warn when weekly hours exceed standard
    And prevent scheduling beyond maximum weekly hours
    And automatically distribute hours across work days
    And consider part-time and full-time employee differences

  @bp1 @labor_standards @period_norm_detailed
  Scenario: Configure Period Performance Norm with Exact Steps
    Given I am in block "Норматив выработки за период" (Performance Norm for Period)
    When I configure period norms following steps:
      | Step | Action | Options |
      | 1 | Choose usage type | Игнорировать/Учитывать/Предупреждать |
    And I select usage type from available options
    Then the system should use period norms for schedule planning
    And track actual vs planned performance
    And generate compliance reports for the period
    And adjust future planning based on performance data

  @bp1 @labor_standards @annual_norm_detailed
  Scenario: Configure Annual Performance Norm Calculation
    Given I am in block "Получение норматива выработки в год" (Annual Performance Norm)
    When I configure annual norm calculation:
      | Step | Parameter | Value |
      | 1 | Choose calculation method | Задавать вручную (Manual entry) |
    Then the system should allow manual entry of annual performance norms
    And calculate annual performance based on:
      | Factor | Consideration |
      | Production calendar | Exclude holidays |
      | Vacation allocation | Deduct vacation days |
      | Sick leave | Track separately |
      | Overtime | Add to base hours |

  # ============================================================================
  # IMPORT PRODUCTION CALENDAR - BUSINESS PROCESS #1 STEP 2
  # ============================================================================

  @bp1 @production_calendar @import
  Scenario: Import Production Calendar Following Admin Process
    Given I need to import production calendar data
    And this is Step 2 of primary system setup
    When I import the production calendar for the year
    Then the system should:
      | Action | Result | Impact |
      | Import holidays | Mark non-working days | Schedule adjustments |
      | Import work days | Set standard work schedule | Normal operations |
      | Import short days | Adjust work hour calculations | Hour calculations |
      | Validate data | Check for conflicts | Data integrity |
    And all labor standard calculations should respect calendar data
    And schedules should automatically adjust for holidays
    And the import should complete successfully for planning

  # ============================================================================
  # ROLES CONFIGURATION - BUSINESS PROCESS #1 STEP 3
  # ============================================================================

  @bp1 @roles_configuration @setup
  Scenario: Configure System Roles as Part of Initial Setup
    Given I need to configure system roles
    And this is Step 3 of primary system setup
    When I navigate to roles configuration
    And I set up role-based labor standards:
      | Role Type | Configuration | Labor Standards Application |
      | System roles | Administrator/Senior Operator/Operator | Full/Limited/Personal |
      | Business roles | Regional Manager/Department Head | Department/Team scope |
    Then each role should have appropriate labor standard enforcement
    And the system should validate role assignments against standards
    And schedule planning should respect role-specific limitations

  # ============================================================================
  # ENHANCED VALIDATION AND COMPLIANCE SCENARIOS
  # ============================================================================

  @labor_standards @validation_enhanced
  Scenario Outline: Enhanced Labor Standards Validation During Planning
    Given labor standards are configured with "<behavior>" setting
    And the norm type is "<norm_type>"
    When the system attempts to create a schedule that violates "<standard_type>"
    Then the system should respond with "<expected_action>"
    And appropriate notifications should be sent to relevant stakeholders
    And the violation should be logged for compliance reporting

    Examples:
      | behavior | norm_type | standard_type | expected_action |
      | Игнорировать | rest_norm | weekly_rest | Allow violation without warning |
      | Учитывать | rest_norm | weekly_rest | Allow but track for reporting |
      | Предупреждать | night_work | unauthorized_night | Show warning but allow override |
      | Использовать только при планировании | daily_norm | daily_hours | Block during planning phase |

  @labor_standards @compliance_detailed
  Scenario: Generate Comprehensive Labor Standards Compliance Reports
    Given all labor standards are configured and active
    And historical scheduling data exists
    When I request a comprehensive compliance report for the period
    Then the report should include detailed analysis:
      | Compliance Area | Metrics | Violation Tracking |
      | Rest norm compliance | 42-hour rest periods | Violations by employee |
      | Night work tracking | Hours and compensation | Unauthorized assignments |
      | Daily limit adherence | 8/12 hour limits | Exceeded shifts |
      | Weekly limit status | 40/48 hour compliance | Weekly violations |
      | Vacation day usage | Accumulated vs used | Policy violations |
      | Annual performance | Norm vs actual | Performance gaps |
    And the report should highlight non-compliant schedules
    And provide specific recommendations for corrective actions
    And support regulatory audit requirements

  @labor_standards @role_based_detailed
  Scenario: Configure Role-Based Labor Standards with Detailed Permissions
    Given I am configuring labor standards for different employee roles
    When I set comprehensive role-specific parameters:
      | Role | Daily Hours | Weekly Hours | Night Work | Overtime | Rest Periods | Vacation |
      | Call Center Agent | 8 std/12 max | 40 std/48 max | Allowed | Limited | 42h/week | Standard |
      | Supervisor | 8 std/12 max | 40 std/48 max | Restricted | Flexible | 42h/week | Enhanced |
      | Senior Operator | 8 std/12 max | 40 std/48 max | Allowed | Extended | 42h/week | Standard |
      | Department Manager | Flexible | 40 std/exempt | Not Applicable | Exempt | Flexible | Executive |
      | Part-time Employee | 4 std/8 max | 20 std/30 max | Restricted | None | Prorated | Prorated |
    Then each role should have appropriate labor standard enforcement
    And the system should validate role assignments against standards
    And schedule planning should respect role-specific limitations
    And role changes should trigger standard recalculation

  @labor_standards @integration_enhanced
  Scenario: Comprehensive Production Calendar Integration
    Given I need to integrate production calendar with labor standards
    When I import complete production calendar data
    Then the system should handle:
      | Calendar Element | Integration | Labor Standards Impact |
      | National holidays | Auto-import | No work scheduling |
      | Regional holidays | Location-based | Geographic compliance |
      | Company holidays | Custom dates | Organization-specific |
      | Short work days | Hour adjustments | Reduced daily norms |
      | Weekend shifts | Special rates | Premium calculations |
      | Holiday work | Exception handling | Compensation rules |
    And all labor standard calculations should respect calendar data
    And schedules should automatically adjust for holidays
    And compliance reporting should include calendar impacts
    And multi-year planning should be supported

  # ============================================================================
  # ERROR HANDLING AND EDGE CASES
  # ============================================================================

  @labor_standards @error_handling
  Scenario: Handle Labor Standards Configuration Errors
    Given I am configuring labor standards
    When configuration errors occur:
      | Error Type | Cause | System Response |
      | Invalid time range | Overlapping night hours | Show validation error |
      | Conflicting norms | Weekly > Daily × 7 | Prevent save with warning |
      | Missing calendar | No production calendar | Require calendar import |
      | Role conflicts | Multiple primary roles | Force resolution |
    Then the system should provide clear error messages
    And prevent invalid configurations from being saved
    And suggest corrective actions for each error type
    And maintain data integrity throughout configuration

  @labor_standards @edge_cases
  Scenario: Handle Edge Cases in Labor Standards Application
    Given labor standards are configured and active
    When edge cases occur during scheduling:
      | Edge Case | Scenario | Expected Handling |
      | Cross-midnight shifts | 22:00-06:00 shift | Split night/day calculation |
      | Holiday boundary | Shift spanning holiday | Proportional calculation |
      | DST transition | Time change during shift | Adjust for actual hours |
      | Leap year | February 29 scheduling | Calendar-aware planning |
      | Role transition | Employee promotion | Apply new standards |
    Then the system should handle each edge case appropriately
    And maintain accurate hour calculations
    And preserve compliance with labor standards
    And provide audit trails for edge case handling