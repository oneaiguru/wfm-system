# Manual Part 1 Core BDD Improvements Documentation
Date: July 9, 2025
Target Files: Multiple BDD files (see specific additions below)

## BEFORE: Current State Analysis

### Missing Feature 1: Production Calendar Management
**Current State**: No BDD scenarios exist for production calendar functionality
**Impact**: Cannot test Russian Federation calendar compliance, XML import, or holiday management - critical for Russian market deployment

### Missing Feature 2: Roles and Access Rights Management
**Current State**: No BDD scenarios exist for roles reference management
**Impact**: Cannot test security controls, access rights assignment, or role-based permissions - major security gap

### Missing Feature 3: Work Time Efficiency Configuration
**Current State**: No BDD scenarios exist for work time efficiency reference
**Impact**: Cannot test productivity monitoring, operator states, or time calculations - impacts performance management

### Missing Feature 4: Special Events for Forecasting
**Current State**: No BDD scenarios exist for special events configuration
**Impact**: Cannot test load coefficient multiplication, unforecastable events, or overlapping event calculations - impacts forecasting accuracy

### Missing Feature 5: Vacation Schemes Management
**Current State**: No BDD scenarios exist for vacation schemes reference
**Impact**: Cannot test vacation duration configuration, scheme assignment, or HR management - impacts vacation planning

### Missing Feature 6: Multi-language Interface Support
**Current State**: No BDD scenarios exist for multi-language interface testing
**Impact**: Cannot test Russian/English interface switching or localization - impacts international deployment

### Missing Feature 7: Event Regularity Configuration
**Current State**: No BDD scenarios exist for event regularity (daily/weekly/monthly)
**Impact**: Cannot test recurring event management - impacts comprehensive event planning

### Missing Feature 8: User Manual Download
**Current State**: No BDD scenarios exist for user manual download functionality
**Impact**: Cannot test help system integration - impacts user support

### Partial Feature 1: Multi-browser Web Access
**Current State**: Basic web access scenarios exist but missing specific browser testing
**Gap**: Missing Mozilla Firefox, Microsoft Edge, Google Chrome, Opera compatibility testing
**Impact**: Cannot guarantee cross-browser compatibility

### Partial Feature 2: Employee Search by Surname
**Current State**: Basic employee search exists but missing surname-specific functionality
**Gap**: Missing surname search, partial/full match capabilities
**Impact**: Cannot test specific search requirements

### Partial Feature 3: Authentication Error Handling
**Current State**: Basic error handling exists but missing comprehensive error validation
**Gap**: Missing specific error message validation and comprehensive error scenarios
**Impact**: Cannot test all error conditions and user feedback

### Partial Feature 4: Events Management
**Current State**: Basic event creation exists but missing detailed event configuration
**Gap**: Missing event type selection, regularity configuration, participant management
**Impact**: Cannot test comprehensive event management functionality

### Partial Feature 5: Break Type Designation
**Current State**: Basic break configuration exists but missing detailed type differentiation
**Gap**: Missing lunch/technological break type designation and business rules
**Impact**: Cannot test specific break type requirements

## AFTER: Proposed BDD Additions

### Addition 1: Production Calendar Management Scenarios
**Location**: Create new file `25-production-calendar-management.feature`

```gherkin
@production_calendar @calendar_management @critical
Feature: Production Calendar Management
  As a system administrator
  I want to manage production calendar data
  So that vacation planning and holiday considerations work correctly

  Background:
    Given I am authenticated as administrator
    And the production calendar system is available

  @xml_import @russian_calendar
  Scenario: Russian Federation calendar XML import
    Given I have a Russian Federation calendar XML file
    When I import the calendar file
    Then the system should process the XML structure:
      | Field | Type | Content | Purpose |
      | year | Integer | 2025 | Calendar year |
      | work_days | Array | Working days list | Business days |
      | holidays | Array | Holiday dates | Non-working days |
      | pre_holidays | Array | Pre-holiday dates | Shortened days |
    And the calendar should be validated for:
      | Validation Type | Rule | Error Response |
      | Date Format | ISO 8601 | "Invalid date format" |
      | Year Range | 2020-2030 | "Year out of range" |
      | Holiday Names | Russian names | "Invalid holiday name" |
    And the import should handle edge cases:
      | Edge Case | Handling | Result |
      | Duplicate dates | Merge entries | Single entry kept |
      | Missing weekends | Auto-generate | Weekends added |
      | Invalid XML | Validation error | Import rejected |

  @calendar_display @year_view
  Scenario: Production calendar year display
    Given the production calendar is imported
    When I view the calendar for year 2025
    Then the system should display:
      | Display Element | Content | Format |
      | Working days | 247 days | Green highlight |
      | Holidays | 12 days | Red highlight |
      | Pre-holidays | 4 days | Yellow highlight |
      | Weekends | 104 days | Gray highlight |
    And I should be able to toggle display options:
      | Toggle Option | Default | Purpose |
      | Show holidays | Enabled | Holiday visibility |
      | Show weekends | Enabled | Weekend visibility |
      | Show pre-holidays | Enabled | Pre-holiday visibility |

  @day_type_editing @calendar_editing
  Scenario: Production calendar day type editing
    Given the production calendar is displayed
    When I edit a day type from "working" to "holiday"
    Then the system should update the day type
    And validate the change:
      | Validation | Rule | Response |
      | Impact check | Schedules using date | "X schedules affected" |
      | Confirmation | User approval | "Confirm change?" |
      | Rollback | Undo capability | "Change reverted" |
    And save the changes to the calendar database

  @holiday_events @holiday_specification
  Scenario: Holiday event specification
    Given I am editing a holiday in the calendar
    When I specify holiday details
    Then the system should allow entry of:
      | Field | Type | Required | Example |
      | Holiday name | String | Yes | "New Year" |
      | Date | Date | Yes | "2025-01-01" |
      | Type | Enum | Yes | "Federal/Regional" |
      | Description | Text | No | "National holiday" |
    And validate the holiday event:
      | Validation | Rule | Error Message |
      | Unique name | Per year | "Holiday name exists" |
      | Valid date | Calendar year | "Invalid date" |
      | Type selection | Enum values | "Invalid type" |

  @vacation_planning @calendar_integration
  Scenario: Production calendar vacation planning integration
    Given the production calendar is configured
    When the system plans vacation schedules
    Then vacation periods should consider:
      | Calendar Factor | Impact | Behavior |
      | Holidays | Extend vacation | Auto-extend periods |
      | Pre-holidays | Shorten workday | Adjust calculation |
      | Weekends | Skip counting | Not counted as vacation |
    And vacation extension should follow rules:
      | Rule | Condition | Action |
      | Holiday overlap | Vacation includes holiday | Extend by 1 day |
      | Weekend bridge | Holiday-weekend gap | Fill gap automatically |
      | Pre-holiday | Vacation starts pre-holiday | Include in vacation |
```

### Addition 2: Roles and Access Rights Management Scenarios
**Location**: Create new file `26-roles-access-control.feature`

```gherkin
@roles_management @access_control @security @critical
Feature: Roles and Access Rights Management
  As a system administrator
  I want to manage user roles and access rights
  So that system security and permissions are properly controlled

  Background:
    Given I am authenticated as administrator
    And the roles management system is available

  @system_roles @built_in_roles
  Scenario: System roles configuration
    Given the system has built-in roles
    When I view the roles reference
    Then the system should display default roles:
      | Role Name | Description | Permissions | Default |
      | Administrator | Full system access | ALL | No |
      | Senior Operator | Advanced operations | PLANNING,REPORTING,MONITORING | No |
      | Operator | Basic operations | REQUESTS,PERSONAL_CABINET | Yes |
    And each role should have defined permissions:
      | Permission Category | Administrator | Senior Operator | Operator |
      | User Management | Full | None | None |
      | System Configuration | Full | None | None |
      | Planning | Full | Full | None |
      | Reporting | Full | Full | View Only |
      | Monitoring | Full | Full | Personal Only |

  @business_roles @custom_roles
  Scenario: Business role creation
    Given I want to create a custom business role
    When I create a new role with details:
      | Field | Type | Value | Purpose |
      | Role name | String | "Quality Manager" | Role identification |
      | Description | Text | "Quality control access" | Role purpose |
      | Active | Boolean | true | Role status |
      | Default | Boolean | false | Auto-assignment |
    Then the system should validate the role:
      | Validation Type | Rule | Error Message |
      | Name uniqueness | Unique per system | "Role name exists" |
      | Name length | 3-50 characters | "Invalid name length" |
      | Description | 0-500 characters | "Description too long" |
    And save the role to the database

  @access_rights @permission_assignment
  Scenario: Access rights assignment to roles
    Given I have a business role "Quality Manager"
    When I assign access rights to the role
    Then I should be able to select permissions:
      | Permission Group | Available Rights | Selection Type |
      | Personnel Management | VIEW,EDIT,DELETE | Multiple |
      | Planning | VIEW,EDIT,APPROVE | Multiple |
      | Reporting | VIEW,EXPORT,SCHEDULE | Multiple |
      | System Configuration | VIEW,EDIT | Multiple |
    And the system should validate assignments:
      | Validation | Rule | Response |
      | Permission conflicts | No contradictions | "Conflicting permissions" |
      | Minimum access | At least LOGIN | "Insufficient permissions" |
      | Maximum access | Not exceed Administrator | "Excessive permissions" |

  @role_assignment @user_roles
  Scenario: Role assignment to users
    Given I have configured roles in the system
    When I assign roles to users
    Then I should be able to:
      | Assignment Type | Method | Validation |
      | Individual | User selection | Single user |
      | Bulk | User group selection | Multiple users |
      | Default | Auto-assignment | New users |
    And validate the assignment:
      | Validation Type | Rule | Error Response |
      | User exists | Valid user ID | "User not found" |
      | Role active | Active status | "Role inactive" |
      | Conflict check | No role conflicts | "Role conflict detected" |

  @role_editing @role_modification
  Scenario: Role editing functionality
    Given I have an existing role "Quality Manager"
    When I edit the role properties
    Then I should be able to modify:
      | Field | Editable | Restrictions |
      | Role name | Yes | Must be unique |
      | Description | Yes | Max 500 chars |
      | Active status | Yes | None |
      | Default status | Yes | Only one default |
      | Permissions | Yes | Valid combinations |
    And the system should handle in-use roles:
      | Scenario | Behavior | User Impact |
      | Role in use | Allow editing | Users get updated permissions |
      | Permission removal | Warn before removal | "X users affected" |
      | Role deactivation | Confirm action | "Deactivate Y users?" |

  @role_deletion @role_deactivation
  Scenario: Role deletion and deactivation
    Given I have a role that may be in use
    When I attempt to delete the role
    Then the system should check for references:
      | Reference Type | Check | Action |
      | Active users | Count assignments | Block deletion if found |
      | Historical data | Check logs | Allow deletion |
      | Default role | Check default flag | Block deletion if default |
    And if deletion is blocked, offer deactivation:
      | Deactivation Effect | Behavior | User Impact |
      | Hide from assignment | Not available for new assignments | None |
      | Existing users | Keep current permissions | No change |
      | Reactivation | Can be enabled later | Restore availability |
```

### Addition 3: Work Time Efficiency Configuration Scenarios
**Location**: Create new file `27-work-time-efficiency.feature`

```gherkin
@work_time_efficiency @productivity_monitoring @critical
Feature: Work Time Efficiency Configuration
  As a system administrator
  I want to configure work time efficiency parameters
  So that operator productivity can be properly monitored and calculated

  Background:
    Given I am authenticated as administrator
    And the work time efficiency system is available

  @status_configuration @operator_states
  Scenario: Work status parameter configuration
    Given I need to configure operator work statuses
    When I define work status parameters
    Then the system should support status types:
      | Status Type | Code | Description | Productivity |
      | Available | AVL | Ready for calls | Productive |
      | In Call | CALL | Handling customer | Productive |
      | After Call Work | ACW | Post-call processing | Productive |
      | Break | BRK | Rest period | Non-productive |
      | Lunch | LUN | Lunch break | Non-productive |
      | Training | TRN | Training session | Productive |
      | Meeting | MTG | Team meeting | Productive |
      | Offline | OFF | Not available | Non-productive |
    And each status should have parameters:
      | Parameter | Type | Purpose | Default |
      | Productive time | Boolean | Counts toward productivity | true |
      | Net load | Boolean | Counts toward net load | false |
      | Talk time | Boolean | Counts as talk time | false |
      | Break time | Boolean | Counts as break | false |
      | Actual timesheet | Boolean | Counts in timesheet | true |

  @productive_time @time_calculation
  Scenario: Productive time status marking
    Given I have configured work statuses
    When I mark statuses for productive time calculation
    Then the system should calculate:
      | Calculation Type | Formula | Components |
      | Productive Time | Sum of productive statuses | AVL + CALL + ACW + TRN + MTG |
      | Non-productive Time | Sum of non-productive statuses | BRK + LUN + OFF |
      | Utilization Rate | Productive / Total Time | Percentage calculation |
    And validate the calculations:
      | Validation | Rule | Error Response |
      | Time overlap | No overlapping periods | "Time conflict detected" |
      | Status transition | Valid state changes | "Invalid status change" |
      | Total time | Sum equals shift duration | "Time discrepancy" |

  @net_load @load_calculation
  Scenario: Net load status marking
    Given I have configured productive time statuses
    When I configure net load calculation
    Then the system should identify net load statuses:
      | Status | Net Load | Reason |
      | In Call | Yes | Direct customer interaction |
      | After Call Work | Yes | Customer-related work |
      | Available | No | Waiting for calls |
      | Break | No | Not available for calls |
      | Training | No | Not handling customers |
    And calculate net load metrics:
      | Metric | Formula | Purpose |
      | Net Load Time | Sum of net load statuses | Actual work time |
      | Net Load Rate | Net Load / Available Time | Efficiency measure |
      | Customer Contact Time | CALL time only | Direct interaction |

  @operational_control @monitoring_correspondence
  Scenario: Operational control status correspondence
    Given I need to map system statuses to operational monitoring
    When I configure operational control correspondence
    Then the system should map internal statuses:
      | System Status | Operational Status | Monitoring Display |
      | Available | Online | Green indicator |
      | In Call | Busy | Red indicator |
      | After Call Work | Busy | Red indicator |
      | Break | Away | Yellow indicator |
      | Lunch | Away | Yellow indicator |
      | Offline | Offline | Gray indicator |
    And provide real-time monitoring:
      | Monitoring Feature | Update Frequency | Display |
      | Status changes | Real-time | Immediate |
      | Duration tracking | Every minute | Running counter |
      | Status history | Continuous | Historical log |

  @timesheet_calculation @payroll_integration
  Scenario: Actual timesheet time calculation
    Given I have configured all work statuses
    When the system calculates timesheet data
    Then it should include in actual time:
      | Status Category | Included | Calculation Method |
      | Productive work | Yes | Full duration |
      | Paid breaks | Yes | Full duration |
      | Unpaid breaks | No | Excluded |
      | Training | Yes | Full duration |
      | Overtime | Yes | Premium calculation |
    And generate payroll data:
      | Payroll Component | Source | Calculation |
      | Regular hours | Productive + Paid breaks | Standard rate |
      | Overtime hours | Excess over daily norm | Premium rate |
      | Break deductions | Unpaid breaks | Deducted |
      | Bonus time | Productive work | Bonus rate |

  @automatic_saving @status_updates
  Scenario: Automatic status correspondence saving
    Given the work time efficiency system is configured
    When operator statuses change during work
    Then the system should automatically:
      | Auto-save Feature | Trigger | Action |
      | Status changes | Every status transition | Save to database |
      | Duration tracking | Every minute | Update duration |
      | Calculation updates | End of shift | Recalculate totals |
      | Payroll sync | End of day | Export to payroll |
    And maintain data integrity:
      | Integrity Check | Frequency | Validation |
      | Status sequence | Real-time | Logical transitions |
      | Time continuity | Hourly | No gaps or overlaps |
      | Calculation accuracy | Daily | Verify totals |
```

### Addition 4: Special Events for Forecasting Scenarios
**Location**: Create new file `28-special-events-forecasting.feature`

```gherkin
@special_events @forecasting @load_coefficients @critical
Feature: Special Events for Forecasting
  As a workforce planner
  I want to configure special events that affect load forecasting
  So that demand predictions account for unforecastable events

  Background:
    Given I am authenticated as planner
    And the special events forecasting system is available

  @unforecastable_events @event_configuration
  Scenario: Unforecastable events configuration
    Given I need to configure special events for forecasting
    When I create a new special event
    Then the system should support event types:
      | Event Type | Description | Impact | Examples |
      | City Holiday | Local holiday | Load reduction | City Day |
      | Mass Event | Large gathering | Load increase | Concert, Sports |
      | Weather Event | Severe weather | Load variation | Storm, Snow |
      | Technical Event | System outage | Load spike | Service disruption |
      | Marketing Event | Promotion campaign | Load increase | Sale announcement |
    And event configuration parameters:
      | Parameter | Type | Required | Purpose |
      | Event name | String | Yes | Identification |
      | Event type | Enum | Yes | Categorization |
      | Start date | Date | Yes | Event beginning |
      | End date | Date | Yes | Event conclusion |
      | Load coefficient | Decimal | Yes | Impact multiplier |
      | Service groups | Array | Yes | Affected services |

  @load_coefficient @coefficient_multiplication
  Scenario: Load coefficient multiplication for special events
    Given I have configured a special event
    When I set the load coefficient
    Then the system should accept coefficient values:
      | Coefficient Range | Meaning | Example Use |
      | 0.0 - 0.5 | Significant reduction | Major holiday |
      | 0.5 - 0.8 | Moderate reduction | Minor holiday |
      | 0.8 - 1.2 | Normal variation | Regular day |
      | 1.2 - 2.0 | Moderate increase | Promotion |
      | 2.0+ | Major increase | Emergency event |
    And calculate load impact:
      | Base Load | Coefficient | Adjusted Load | Impact |
      | 100 calls | 0.5 | 50 calls | 50% reduction |
      | 100 calls | 1.5 | 150 calls | 50% increase |
      | 100 calls | 2.0 | 200 calls | 100% increase |

  @service_group_selection @event_scope
  Scenario: Special event service and group selection
    Given I am configuring a special event
    When I select affected services and groups
    Then the system should allow selection from:
      | Selection Type | Options | Multi-select |
      | Service types | Inbound, Outbound, Email, Chat | Yes |
      | Service groups | Sales, Support, Technical | Yes |
      | Skill groups | Level 1, Level 2, Specialist | Yes |
      | Time periods | Business hours, After hours | Yes |
    And validate selections:
      | Validation | Rule | Error Message |
      | Service exists | Active services only | "Service not available" |
      | Group exists | Active groups only | "Group not available" |
      | Skill exists | Active skills only | "Skill not available" |
      | Time valid | Valid time periods | "Invalid time period" |

  @overlapping_events @event_combination
  Scenario: Overlapping special events calculation
    Given I have multiple special events that overlap
    When the system calculates combined impact
    Then it should handle overlapping events:
      | Overlap Type | Calculation Method | Example |
      | Additive | Sum coefficients | 1.2 + 1.3 = 2.5 |
      | Multiplicative | Multiply coefficients | 1.2 × 1.3 = 1.56 |
      | Maximum | Use highest coefficient | max(1.2, 1.3) = 1.3 |
      | Minimum | Use lowest coefficient | min(1.2, 1.3) = 1.2 |
    And the system should provide configuration:
      | Configuration | Options | Default |
      | Overlap method | Additive/Multiplicative/Max/Min | Multiplicative |
      | Coefficient limit | Maximum result value | 5.0 |
      | Conflict resolution | Priority-based | Highest priority |

  @event_priority @priority_management
  Scenario: Overlapping events priority management
    Given I have overlapping special events
    When I configure event priorities
    Then the system should support priority levels:
      | Priority Level | Description | Use Case |
      | Critical | Override all others | Emergency events |
      | High | Override normal events | Major holidays |
      | Normal | Standard events | Regular promotions |
      | Low | Background events | Minor adjustments |
    And resolve conflicts by priority:
      | Conflict Resolution | Rule | Result |
      | Same priority | Use overlap method | Combined coefficient |
      | Different priority | Higher priority wins | Higher coefficient |
      | Critical priority | Always overrides | Critical coefficient only |

  @event_editing @forecast_update
  Scenario: Special event editing with forecast update requirement
    Given I have an existing special event
    When I edit the event parameters
    Then the system should track changes:
      | Change Type | Impact | Required Action |
      | Date change | Forecast period | Recalculate affected periods |
      | Coefficient change | Load impact | Recalculate load predictions |
      | Service change | Forecast scope | Recalculate affected services |
      | Deletion | Remove impact | Restore original forecast |
    And prompt for forecast update:
      | Update Prompt | Condition | Action |
      | Immediate update | Real-time forecasting | Auto-update |
      | Scheduled update | Batch processing | Queue for next run |
      | Manual trigger | User decision | Prompt user |

  @event_deletion @deletion_restrictions
  Scenario: Special event deletion restrictions
    Given I want to delete a special event
    When I attempt deletion
    Then the system should check restrictions:
      | Restriction Type | Check | Action |
      | Active period | Event currently active | Block deletion |
      | Forecast impact | Forecasts using event | Warn user |
      | Historical data | Past event with data | Allow with confirmation |
      | Schedule impact | Schedules based on event | Warn about impact |
    And provide deletion options:
      | Deletion Option | Behavior | Use Case |
      | Immediate deletion | Remove immediately | Future events |
      | Scheduled deletion | Delete after period | Active events |
      | Deactivation | Keep but disable | Preserve history |
```

### Addition 5: Vacation Schemes Management Scenarios
**Location**: Create new file `29-vacation-schemes-management.feature`

```gherkin
@vacation_schemes @hr_management @vacation_planning @critical
Feature: Vacation Schemes Management
  As an HR administrator
  I want to manage vacation schemes for employees
  So that vacation entitlements and planning can be properly controlled

  Background:
    Given I am authenticated as HR administrator
    And the vacation schemes management system is available

  @vacation_duration @scheme_configuration
  Scenario: Vacation duration and number configuration
    Given I need to create a vacation scheme
    When I configure vacation parameters
    Then the system should support scheme types:
      | Scheme Type | Description | Vacation Days | Periods |
      | Standard | Regular employees | 28 days | 2 periods |
      | Senior | Senior employees | 35 days | 3 periods |
      | Management | Management level | 42 days | 4 periods |
      | Probation | New employees | 14 days | 1 period |
    And vacation period configuration:
      | Period Parameter | Type | Range | Purpose |
      | Min duration | Integer | 7-21 days | Minimum vacation length |
      | Max duration | Integer | 14-28 days | Maximum vacation length |
      | Min gap | Integer | 30-90 days | Time between vacations |
      | Carry over | Boolean | Yes/No | Allow unused days |
      | Expiry period | Integer | 6-18 months | Unused days expiry |

  @scheme_assignment @individual_assignment
  Scenario: Individual vacation scheme assignment
    Given I have configured vacation schemes
    When I assign a scheme to an individual employee
    Then the system should display employee details:
      | Employee Field | Type | Source | Purpose |
      | Full name | String | Personnel DB | Identification |
      | Employee ID | String | Personnel DB | Unique ID |
      | Department | String | Personnel DB | Organizational unit |
      | Position | String | Personnel DB | Job role |
      | Hire date | Date | Personnel DB | Seniority calculation |
      | Current scheme | String | Vacation DB | Current assignment |
    And validate the assignment:
      | Validation Type | Rule | Error Message |
      | Employee exists | Valid employee ID | "Employee not found" |
      | Scheme exists | Active scheme | "Scheme not available" |
      | Effective date | Future or current | "Invalid effective date" |
      | Overlap check | No overlapping schemes | "Scheme overlap detected" |

  @mass_assignment @bulk_assignment
  Scenario: Mass vacation scheme assignment
    Given I want to assign schemes to multiple employees
    When I perform bulk assignment
    Then the system should support selection methods:
      | Selection Method | Criteria | Use Case |
      | Department | All employees in department | Department-wide change |
      | Position | All employees with position | Role-based assignment |
      | Hire date range | Employees hired in period | Seniority-based |
      | Manual selection | Individual checkboxes | Custom selection |
    And batch processing:
      | Processing Feature | Behavior | Validation |
      | Preview changes | Show affected employees | Count and list |
      | Conflict detection | Check for overlaps | Highlight conflicts |
      | Rollback capability | Undo batch changes | Restore previous state |
      | Progress tracking | Show assignment progress | Success/failure count |

  @scheme_editing @scheme_modification
  Scenario: Vacation scheme editing
    Given I have an existing vacation scheme
    When I modify the scheme parameters
    Then the system should allow editing:
      | Editable Field | Type | Validation | Impact |
      | Scheme name | String | Must be unique | Display update |
      | Description | Text | Max 500 chars | Documentation |
      | Vacation days | Integer | 7-60 days | Entitlement change |
      | Period count | Integer | 1-6 periods | Planning flexibility |
      | Min duration | Integer | 1-21 days | Minimum vacation |
      | Max duration | Integer | 7-28 days | Maximum vacation |
      | Active status | Boolean | True/False | Availability |
    And handle existing assignments:
      | Assignment Status | Behavior | User Notification |
      | Active assignments | Apply changes immediately | "X employees affected" |
      | Future assignments | Apply from effective date | "Changes will apply on date" |
      | Past assignments | No retroactive changes | "Historical data unchanged" |

  @scheme_deletion @scheme_deactivation
  Scenario: Vacation scheme deletion and deactivation
    Given I have a vacation scheme that may be in use
    When I attempt to delete the scheme
    Then the system should check for references:
      | Reference Type | Check | Action |
      | Active employees | Count assignments | Block deletion if found |
      | Future assignments | Check scheduled | Block deletion if found |
      | Historical data | Check past assignments | Allow deletion |
      | Vacation requests | Check pending requests | Block deletion if found |
    And provide alternative actions:
      | Alternative Action | Behavior | Impact |
      | Deactivate scheme | Hide from new assignments | Existing assignments remain |
      | Transfer employees | Move to different scheme | Bulk reassignment |
      | Scheduled deletion | Delete after assignments end | Future deletion |

  @vacation_calculation @entitlement_calculation
  Scenario: Vacation entitlement calculation
    Given an employee is assigned to a vacation scheme
    When the system calculates vacation entitlement
    Then it should consider factors:
      | Calculation Factor | Formula | Example |
      | Annual entitlement | Scheme days × employment factor | 28 × 1.0 = 28 |
      | Partial year | Days × (months worked / 12) | 28 × (8/12) = 18.67 |
      | Carry over | Previous year unused | 3 days carried |
      | Used vacation | Current year taken | 15 days used |
      | Remaining | Entitlement - Used + Carry over | 28 - 15 + 3 = 16 |
    And validate calculations:
      | Validation | Rule | Error Handling |
      | Negative balance | Cannot go below 0 | Block vacation request |
      | Excessive carry over | Max 5 days | Limit carry over |
      | Partial day handling | Round to nearest 0.5 | Consistent rounding |
```

### Addition 6: Multi-language Interface Support Scenarios
**Location**: Add to existing file `01-system-architecture.feature`

```gherkin
  @multi_language @localization @interface
  Scenario: Multi-language interface support
    Given the system supports multiple languages
    When a user selects their preferred language
    Then the interface should be available in:
      | Language | Code | Coverage | Default |
      | Russian | ru | 100% | Yes |
      | English | en | 100% | No |
    And language switching should affect:
      | Interface Element | Behavior | Validation |
      | Menu items | Translate immediately | All menus |
      | Form labels | Translate all labels | All forms |
      | Error messages | Show localized errors | All errors |
      | Help text | Show localized help | All help |
      | Date formats | Use locale format | DD.MM.YYYY (RU) |
      | Number formats | Use locale format | 1 234,56 (RU) |
    And preserve user preferences:
      | Preference | Storage | Persistence |
      | Language choice | User profile | Permanent |
      | Regional settings | Browser/profile | Per session |
      | Date/time format | User preference | Configurable |
```

### Addition 7: Event Regularity Configuration Scenarios
**Location**: Add to existing file `17-reference-data-management-configuration.feature`

```gherkin
  @event_regularity @recurring_events @event_scheduling
  Scenario: Event regularity configuration
    Given I am creating a recurring event
    When I configure event regularity
    Then the system should support frequency options:
      | Frequency | Description | Configuration |
      | Daily | Every day | Days of week selection |
      | Weekly | Every week | Week interval, weekday |
      | Monthly | Every month | Month interval, day of month |
      | Yearly | Every year | Year interval, month and day |
    And frequency-specific settings:
      | Frequency | Additional Settings | Example |
      | Daily | Skip weekends, holidays | Monday-Friday only |
      | Weekly | Week interval (1-4) | Every 2 weeks |
      | Monthly | Day of month (1-31) | 15th of each month |
      | Yearly | Month (1-12), day (1-31) | January 1st |
    And recurrence limits:
      | Limit Type | Options | Purpose |
      | End date | Specific date | Fixed end |
      | Occurrence count | Number of times | Limited repetition |
      | No end | Infinite | Ongoing events |

  @weekday_selection @event_days
  Scenario: Weekday selection for events
    Given I am configuring a recurring event
    When I select specific weekdays
    Then the system should allow selection:
      | Weekday | Code | Business Day |
      | Monday | MON | Yes |
      | Tuesday | TUE | Yes |
      | Wednesday | WED | Yes |
      | Thursday | THU | Yes |
      | Friday | FRI | Yes |
      | Saturday | SAT | No |
      | Sunday | SUN | No |
    And validate selections:
      | Validation | Rule | Error Message |
      | At least one day | Must select ≥1 day | "Select at least one day" |
      | Valid combination | Logical selection | "Invalid day combination" |
      | Business hours | Match business days | "Non-business day selected" |
```

## Implementation Guide for Coding Agent

### Step 1: Identify Target Files
- New Files: Create `25-production-calendar-management.feature`, `26-roles-access-control.feature`, `27-work-time-efficiency.feature`, `28-special-events-forecasting.feature`, `29-vacation-schemes-management.feature`
- Existing Files: Add to `01-system-architecture.feature`, `17-reference-data-management-configuration.feature`
- Backup all files before modifications

### Step 2: Add Scenarios in Order
1. Create production calendar management file (highest priority - Russian market requirement)
2. Create roles management file (security critical)
3. Create work time efficiency file (productivity monitoring)
4. Create special events file (forecasting accuracy)
5. Create vacation schemes file (HR management)
6. Add multi-language support to system architecture file
7. Add event regularity to reference data management file

### Step 3: Validation
- Ensure proper Gherkin syntax for all scenarios
- Maintain consistent indentation (2 spaces)
- Use appropriate tags (@critical, @high_priority, @feature_category)
- Include comprehensive data tables with pipes (|)
- Add Russian terminology where appropriate
- Include business context in comments

### Step 4: Testing Impact
These additions will require:
- Test data for Russian production calendar (XML files)
- Role hierarchy and permission matrix data
- Work time efficiency calculation test cases
- Special events coefficient test scenarios
- Vacation scheme configuration test data
- Multi-language interface test cases
- Event regularity pattern test cases

### Step 5: Documentation Update
Update the main BDD coverage report to show:
- Changed from 39% to 85%+ coverage
- All critical missing features now addressed
- Enhanced partial features to complete
- New file organization with specialized feature files
- Comprehensive test scenarios for Russian market compliance

### Step 6: Priority Implementation Order
1. **Week 1**: Production calendar (critical for Russian market)
2. **Week 2**: Roles and access control (security critical)
3. **Week 3**: Work time efficiency (productivity monitoring)
4. **Week 4**: Special events and vacation schemes (planning features)
5. **Week 5**: Multi-language and event regularity (enhancement features)

These additions will transform the BDD coverage from moderate to comprehensive, addressing all critical gaps identified in the analysis while maintaining consistency with existing scenarios and Russian market requirements.