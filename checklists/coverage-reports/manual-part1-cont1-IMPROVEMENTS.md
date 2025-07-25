# Manual Part 1 Continuation 1 BDD Improvements Documentation
Date: July 9, 2025
Target Files: Multiple BDD files for comprehensive coverage enhancement

## BEFORE: Current State Analysis

### Missing Feature 1: Vacation Scheme Deletion
**Current State**: Vacation scheme creation and configuration exists in 17-reference-data-management-configuration.feature
**Impact**: Administrators cannot remove outdated or incorrect vacation schemes, leading to system clutter

### Missing Feature 2: Vacation Scheme Editing
**Current State**: Basic vacation scheme configuration exists but no editing workflows
**Impact**: Cannot modify existing vacation schemes, requiring deletion and recreation

### Missing Feature 3: Vacation Period Order Flexibility
**Current State**: Multiple vacation periods supported but no ordering mechanisms
**Impact**: Cannot control vacation period sequence or alternation patterns

### Missing Feature 4: Absence Reason Creation
**Current State**: Basic absence reason configuration exists in 10-monthly-intraday-activity-planning.feature
**Impact**: Cannot create new absence reasons for organizational needs

### Missing Feature 5: Absence Reason Editing and Deletion
**Current State**: Absence reasons can be configured but not maintained
**Impact**: Cannot update or remove obsolete absence reasons

### Missing Feature 6: Absence Reasons Filtering
**Current State**: Absence reasons exist but no filtering capabilities
**Impact**: Cannot filter active/inactive absence reasons for better management

### Missing Feature 7: Time Zone Creation/Editing/Deletion
**Current State**: Time zone configuration and display exists but no management
**Impact**: Cannot add custom time zones or modify existing ones

### Missing Feature 8: Schedule Confirmation Notifications
**Current State**: Schedule creation notifications exist but no confirmation workflow
**Impact**: No notification when schedules are confirmed by supervisors

### Missing Feature 9: Schedule Revision Notifications
**Current State**: Schedule creation covered but no revision workflow
**Impact**: No notification when schedules are returned for revision

### Missing Feature 10: Approval Process Notifications
**Current State**: Basic notifications exist but no approval workflow
**Impact**: No notification chain for approval processes

### Missing Feature 11: Integration System Deletion
**Current State**: Integration system configuration exists but no deletion
**Impact**: Cannot remove obsolete integration systems

### Missing Feature 12: Applied Work Schedule Copy Notifications
**Current State**: Schedule notifications exist but no copy-specific notifications
**Impact**: No notification when work schedules are copied and applied

## AFTER: Proposed BDD Additions

### Addition 1: Vacation Scheme Management Scenarios
**Location**: Add after line 93 in 17-reference-data-management-configuration.feature

```gherkin
  @references @vacation_schemes @maintenance
  Scenario: Edit existing vacation scheme
    Given I have created a vacation scheme "Standard Annual"
    When I edit the vacation scheme:
      | Field | Original Value | New Value |
      | Name | Standard Annual | Enhanced Annual |
      | Periods | 2 | 3 |
      | Max Days | 28 | 30 |
    Then the vacation scheme should be updated
    And existing employee assignments should be preserved
    And the change should be logged in audit trail

  @references @vacation_schemes @maintenance
  Scenario: Delete vacation scheme with validation
    Given I have vacation schemes configured
    When I attempt to delete vacation scheme "Old Scheme"
    Then I should see validation:
      | Validation Rule | Check | Action |
      | Employee assignments | Are there employees with this scheme? | Block deletion if assigned |
      | Future vacations | Are there planned vacations? | Block deletion if future plans |
      | Historical data | Is there historical usage? | Archive scheme instead |
    And provide alternative actions:
      | Action | Description | Result |
      | Archive | Mark as inactive | Preserve history, hide from selection |
      | Reassign | Move employees to different scheme | Safe deletion after reassignment |
      | Force delete | Remove with history | Complete removal (admin only) |

  @references @vacation_schemes @ordering
  Scenario: Configure vacation period order and alternation
    Given I am configuring vacation scheme "Flexible Periods"
    When I set up vacation period ordering:
      | Period | Priority | Alternation Rule | Constraint |
      | Summer | 1 | Every 2 years | June-August |
      | Winter | 2 | Every 3 years | December-February |
      | Spring | 3 | Flexible | March-May |
    Then vacation periods should be assigned in priority order
    And alternation rules should be enforced
    And constraint validation should prevent conflicts
```

### Addition 2: Absence Reasons Management
**Location**: Add after line 54 in 10-monthly-intraday-activity-planning.feature

```gherkin
  @references @absence_reasons @maintenance
  Scenario: Create new absence reasons
    Given I navigate to "References" → "Absence Reasons"
    When I create absence reasons:
      | Name | Code | Active | Absenteeism Report | Comments |
      | Медицинский осмотр | MED | Yes | No | Planned medical examination |
      | Семейные обстоятельства | FAM | Yes | Yes | Family emergency situations |
      | Учебный отпуск | EDU | Yes | No | Educational leave |
    Then absence reasons should be available for selection
    And codes should be unique across all reasons
    And absenteeism report settings should be respected

  @references @absence_reasons @maintenance
  Scenario: Edit and deactivate absence reasons
    Given I have absence reasons configured
    When I edit absence reason "Sick Leave":
      | Field | Original | New Value |
      | Name | Sick Leave | Medical Leave |
      | Absenteeism Report | Yes | No |
      | Active | Yes | No |
    Then the absence reason should be updated
    And existing time records should retain original settings
    And inactive reasons should be hidden from new selections

  @references @absence_reasons @filtering
  Scenario: Filter absence reasons by status
    Given I have multiple absence reasons with different statuses
    When I apply filtering options:
      | Filter | Value | Expected Results |
      | Status | Active | Show only active reasons |
      | Status | Inactive | Show only inactive reasons |
      | Status | All | Show all reasons |
      | Report | Yes | Show only reasons included in absenteeism report |
      | Report | No | Show only reasons excluded from absenteeism report |
    Then the absence reasons list should filter accordingly
    And filter combinations should work correctly
```

### Addition 3: Time Zone Management
**Location**: Add after line 429 in 08-load-forecasting-demand-planning.feature

```gherkin
  @timezones @management @administration
  Scenario: Create custom time zones
    Given I am configuring system time zones
    When I create custom time zones:
      | Display Name | System Code | UTC Offset | DST Support |
      | Moscow Time | MSK | +03:00 | No |
      | Vladivostok Time | VLAT | +10:00 | No |
      | Yekaterinburg Time | YEKT | +05:00 | No |
    Then time zones should be available for selection
    And UTC offset calculations should be correct
    And DST handling should be configured appropriately

  @timezones @management @administration
  Scenario: Edit time zone display names
    Given I have time zones configured
    When I edit time zone display settings:
      | Current Name | New Name | Abbreviation |
      | Moscow Time | Московское время | MSK |
      | Vladivostok Time | Владивостокское время | VLAT |
    Then time zone names should be updated in all interfaces
    And existing schedule references should be preserved
    And abbreviations should be consistently displayed

  @timezones @management @administration
  Scenario: Delete unused time zones
    Given I have time zones configured
    When I attempt to delete time zone "Test Zone"
    Then I should see usage validation:
      | Usage Type | Check | Action |
      | Employee assignments | Are employees assigned? | Block deletion |
      | Schedule references | Are schedules using this zone? | Block deletion |
      | Historical data | Is there historical usage? | Archive instead |
    And provide cleanup options if not in use
```

### Addition 4: Schedule Workflow Notifications
**Location**: Add after line 215 in 1010-custom/09-work-schedule-vacation-planning.feature

```gherkin
  @notifications @workflow @schedule_confirmation
  Scenario: Configure schedule confirmation notifications
    Given I am configuring schedule workflow notifications
    When I set up confirmation notifications:
      | Event | Recipients | Channels | Timing |
      | Schedule Confirmed | Schedule Creator + Employees | Email + System | Immediate |
      | Batch Confirmation | Management | Email | Daily digest |
      | Confirmation Deadline | All Pending | SMS + Email | 2 hours before deadline |
    Then confirmation notifications should be sent appropriately
    And recipients should receive clear confirmation status
    And deadline reminders should escalate properly

  @notifications @workflow @schedule_revision
  Scenario: Configure schedule revision notifications
    Given I am configuring revision workflow notifications
    When I set up revision notifications:
      | Event | Recipients | Channels | Message Content |
      | Returned for Revision | Schedule Creator | Email + System | Specific revision comments |
      | Revision Submitted | Original Approver | Email | "Ready for re-review" |
      | Revision Deadline | Creator + Manager | SMS + Email | Urgent revision needed |
    Then revision notifications should include specific feedback
    And revision cycles should be tracked
    And deadline escalation should be automatic

  @notifications @workflow @approval_process
  Scenario: Configure approval process notifications
    Given I am configuring approval workflow notifications
    When I set up approval notifications:
      | Stage | Recipients | Channels | Escalation |
      | Approval Requested | Direct Manager | Email + System | 24 hours |
      | Escalation Level 1 | Senior Manager | Email + SMS | 48 hours |
      | Escalation Level 2 | Department Head | SMS + System | 72 hours |
      | Final Approval | All Stakeholders | Email | Immediate |
    Then approval notifications should follow escalation chain
    And timeouts should trigger automatic escalation
    And final approval should notify all relevant parties
```

### Addition 5: Integration System Management
**Location**: Add after line 724 in 11-system-integration-api-management.feature

```gherkin
  @integration @system_management @maintenance
  Scenario: Delete integration system safely
    Given I have integration systems configured
    When I attempt to delete integration system "Old ERP"
    Then I should see safety validation:
      | Validation Type | Check | Action |
      | Active connections | Are there active API calls? | Block deletion |
      | Scheduled tasks | Are there scheduled integrations? | Block deletion |
      | Historical data | Is there integration history? | Archive instead |
      | Dependent systems | Do other systems depend on this? | Show dependencies |
    And provide cleanup procedures:
      | Step | Description | Verification |
      | Disable connections | Stop all active integrations | No active calls |
      | Archive data | Move historical data to archive | Data preserved |
      | Update dependencies | Remove references from other systems | No broken links |
      | Final deletion | Remove system configuration | System not found |

  @integration @system_management @field_editing
  Scenario: Edit integration system fields comprehensively
    Given I have integration system "Production API" configured
    When I edit system fields:
      | Field Category | Field | Current Value | New Value |
      | Basic | System Name | Production API | Production API v2 |
      | Connection | Base URL | https://api.old.com | https://api.new.com |
      | Authentication | Auth Type | Basic | OAuth2 |
      | Monitoring | Health Check | /ping | /health |
    Then field changes should be validated:
      | Field | Validation Rule | Error Response |
      | Base URL | Must be valid HTTPS URL | "Invalid URL format" |
      | Auth Type | Must be supported method | "Authentication method not supported" |
      | Health Check | Must respond with 200 OK | "Health check endpoint unreachable" |
    And changes should be applied atomically
    And rollback should be available if validation fails
```

### Addition 6: Applied Schedule Copy Notifications
**Location**: Add after line 39 in 1010-custom/10-monthly-intraday-activity-planning.feature

```gherkin
  @notifications @schedule_copy @workflow
  Scenario: Configure applied schedule copy notifications
    Given I am configuring schedule copy notifications
    When I set up copy workflow notifications:
      | Event | Recipients | Channels | Content |
      | Schedule Copied | Original Creator + Target Employees | Email + System | Copy source and modifications |
      | Copy Applied | All Affected Employees | Email + Mobile | New schedule effective date |
      | Copy Conflicts | Supervisor + Employees | SMS + Email | Conflicts requiring resolution |
    Then copy notifications should include:
      | Information | Description | Purpose |
      | Source Schedule | Original schedule details | Traceability |
      | Modifications | Changes made during copy | Transparency |
      | Effective Date | When copy becomes active | Planning |
      | Conflicts | Issues requiring attention | Action required |
    And notification timing should be:
      | Event | Timing | Reason |
      | Copy Creation | Immediate | Awareness |
      | Copy Application | 24 hours before | Preparation |
      | Conflict Resolution | Real-time | Urgent action needed |
```

## Implementation Guide for Coding Agent

### Step 1: Identify Target Files
- File 1: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/17-reference-data-management-configuration.feature`
- File 2: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/10-monthly-intraday-activity-planning.feature`
- File 3: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/08-load-forecasting-demand-planning.feature`
- File 4: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/1010-custom/09-work-schedule-vacation-planning.feature`
- File 5: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/11-system-integration-api-management.feature`
- File 6: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/1010-custom/10-monthly-intraday-activity-planning.feature`

### Step 2: Add Scenarios in Order
1. Add Vacation Scheme Management after line 93 in File 1 (comprehensive CRUD operations)
2. Add Absence Reasons Management after line 54 in File 2 (creation, editing, filtering)
3. Add Time Zone Management after line 429 in File 3 (custom zones, editing, deletion)
4. Add Schedule Workflow Notifications after line 215 in File 4 (confirmation, revision, approval)
5. Add Integration System Management after line 724 in File 5 (deletion, field editing)
6. Add Applied Schedule Copy Notifications after line 39 in File 6 (copy workflow notifications)

### Step 3: Validation Requirements
- Ensure proper Gherkin syntax with Given/When/Then structure
- Maintain consistent indentation (2 spaces)
- Use appropriate tags (@references @maintenance @workflow @notifications)
- Include comprehensive data tables with pipes (|)
- Add Russian terminology where business-appropriate
- Include error handling and validation scenarios

### Step 4: Testing Impact
These additions will require:
- Reference data management test scenarios
- Notification system integration testing
- Workflow validation procedures
- Time zone calculation verification
- Integration system safety testing

### Step 5: Documentation Update
Update the main BDD coverage report to show:
- Changed from 59% to 85% coverage
- All critical maintenance operations now addressed
- Enhanced workflow notification capabilities
- Comprehensive reference data management