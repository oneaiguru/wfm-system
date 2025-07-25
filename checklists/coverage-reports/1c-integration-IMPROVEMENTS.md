# 1C Integration BDD Improvements Documentation
Date: July 9, 2025
Target File: 21-1c-zup-integration.feature

## BEFORE: Current State Analysis

### Missing Feature 1: Time standards actualization on employee changes
**Current State**: No scenarios exist for automatic time standard updates when employee data changes
**Impact**: When an employee's working hours, position, or department changes in 1C, the time standards in WFM don't automatically update

### Missing Feature 2: Document execution in Personnel subsystem  
**Current State**: Document creation is covered, but document execution/posting in 1C subsystems is not specified
**Impact**: Created documents remain unprocessed, not affecting payroll or personnel records

### Missing Feature 3: Initial data upload process
**Current State**: Daily sync is covered, but initial system setup and bulk data migration is not documented
**Impact**: No clear process for system go-live and initial data population

### Missing Feature 4: 1C Salary and Personnel Management customization
**Current State**: API usage is documented, but 1C system configuration requirements are not specified
**Impact**: Unclear what settings are needed in 1C ZUP before integration can work

### Partial Feature 1: Vacation schedule upload from WFM
**Current State**: Vacation balance retrieval is covered, but specific vacation schedule upload format (Excel) is not detailed
**Impact**: Unclear how to format vacation schedules for upload to 1C

### Partial Feature 2: Vacation entitlement accrual algorithm  
**Current State**: Vacation balance retrieval exists, but the accrual calculation algorithm is not specified
**Impact**: Cannot verify if vacation calculations are correct

## AFTER: Proposed BDD Additions

### Addition 1: Time Standards Actualization Scenario
**Location**: Add after line 182 in 21-1c-zup-integration.feature

```gherkin
  @time_standards @actualization @employee_changes
  Scenario: Automatic Time Standards Update on Employee Changes
    Given employee data has changed in 1C ZUP:
      | Change Type | Example | Trigger |
      | Position change | Operator → Senior Operator | Different weekly norm |
      | Department transfer | Call Center → Back Office | Different work rules |
      | Work schedule type | 5-day → Shift work | Different calculation |
      | Employment type | Full-time → Part-time | Reduced hours norm |
    When the personnel synchronization runs
    Then time standards should be automatically recalculated:
      | Update Process | Action | Timing |
      | Detect change | Compare previous vs current data | During sync |
      | Identify affected periods | Current month forward | No retroactive |
      | Trigger getNormHours | Recalculate for affected employee | Immediate |
      | Update WFM database | Store new time standards | Before scheduling |
    And the system should maintain audit trail:
      | Audit Field | Content | Purpose |
      | Previous norm | Old weekly/monthly hours | Change tracking |
      | New norm | Updated hours | Current standard |
      | Change reason | Position/Department/Schedule | Justification |
      | Effective date | When change takes effect | Period boundary |
    And edge cases should be handled:
      | Edge Case | Handling | Result |
      | Mid-month change | Prorate time standards | Partial month norms |
      | Multiple changes | Process sequentially | Latest state wins |
      | Retroactive changes | Warning + manual review | Prevent overwrites |
```

### Addition 2: Document Execution Workflow
**Location**: Add after line 810 in 21-1c-zup-integration.feature

```gherkin
  @document_execution @1c_subsystems @workflow
  Scenario: Document Execution in Personnel and Salary Subsystems
    Given deviation documents have been created in 1C ZUP
    When documents need to be executed (posted)
    Then the execution workflow should follow 1C business logic:
      | Document Type | Execution Steps | Subsystem | Result |
      | Absence (NV) | 1. Validate employee status | Personnel | Update attendance |
      |              | 2. Check document period | Personnel | Period validation |
      |              | 3. Post to personnel records | Personnel | Official record |
      |              | 4. Transfer to salary | Salary | Affect payroll |
      | Overtime (C) | 1. Verify overtime approval | Personnel | Compliance check |
      |              | 2. Calculate overtime hours | Salary | Payment calculation |
      |              | 3. Post to payroll | Salary | Include in salary |
      | Holiday work | 1. Confirm holiday status | Personnel | Calendar validation |
      |              | 2. Apply premium rates | Salary | Higher pay rate |
      |              | 3. Post with special marker | Both | Legal compliance |
    And execution should handle errors:
      | Error Type | Handling | User Notification |
      | Period closed | Reject execution | "Payroll period closed" |
      | Missing approval | Hold document | "Requires approval" |
      | Employee terminated | Special handling | "Check termination date" |
    And execution status should be tracked:
      | Status | Meaning | Next Action |
      | Created | Document exists | Ready for execution |
      | Posted | Executed successfully | Affects calculations |
      | Rejected | Execution failed | Review and correct |
```

### Addition 3: Initial Data Upload Process
**Location**: Add new section after line 951 in 21-1c-zup-integration.feature

```gherkin
  # ============================================================================
  # INITIAL SYSTEM SETUP AND DATA MIGRATION
  # ============================================================================

  @initial_setup @data_migration @go_live
  Scenario: Initial Data Upload and System Setup Process
    Given a new WFM implementation requires initial data load
    When performing initial system setup
    Then the data migration should follow this sequence:
      | Step | Process | Validation | Rollback |
      | 1 | Production calendar upload | Verify all holidays | Clear calendar |
      | 2 | Organizational structure | Check hierarchy | Remove all departments |
      | 3 | Employee master data | Validate required fields | Delete employees |
      | 4 | Historical time norms | Calculate for all employees | Reset norms |
      | 5 | Current schedules | If mid-month go-live | Clear schedules |
      | 6 | Vacation balances | As of go-live date | Reset balances |
    And each step should be verified:
      | Data Type | Verification Method | Success Criteria |
      | Production calendar | Compare holiday count | Matches RF calendar |
      | Org structure | Department tree validation | No orphan departments |
      | Employees | Active employee count | Matches 1C count |
      | Time norms | Spot check calculations | Within 0.1 hour tolerance |
    And the initial load should support:
      | Feature | Implementation | Purpose |
      | Batch processing | 100 employees per batch | Performance |
      | Progress tracking | Status per data type | Monitoring |
      | Error recovery | Resume from last success | Reliability |
      | Validation report | Summary of all issues | Quality assurance |

  @initial_setup @prerequisites
  Scenario: System Prerequisites Verification Before Go-Live
    Given initial data upload is planned
    When verifying system readiness
    Then all prerequisites should be checked:
      | Component | Requirement | Verification | Critical |
      | 1C ZUP version | 3.1.7 or higher | Version check API | Yes |
      | HTTP service | wfm_Energosbyt_ExchangeWFM active | Test connection | Yes |
      | WFMSystem user | Created with full rights | Login test | Yes |
      | Production calendar | Current year loaded | Calendar query | Yes |
      | Time types | All types configured | Type list check | Yes |
      | API endpoints | All 4 methods responding | Connectivity test | Yes |
```

### Addition 4: 1C Configuration Requirements
**Location**: Add after Background section (line 15) in 21-1c-zup-integration.feature

```gherkin
  @1c_configuration @setup_requirements
  Scenario: 1C ZUP Configuration Requirements for Integration
    Given 1C ZUP needs to be configured for WFM integration
    When setting up the 1C system
    Then the following configurations are required:
      | Configuration Area | Setting | Value/Requirement | Validation |
      | HTTP Services | Publication | Web server enabled | URL accessible |
      | Exchange Plans | WFM Exchange | Created and active | Exchange node exists |
      | Users | WFMSystem | Full access rights | Can read/write all |
      | Time Types | Work types | I, H, B configured | Types return in API |
      | Time Types | Deviations | RV, RVN, NV, C active | Document creation enabled |
      | Catalogs | Subdivisions | CFR000260 exists | Customer Service dept |
      | Registers | Work time norms | Accumulation enabled | Norm calculation works |
      | Documents | Absence docs | Templates configured | Auto-creation ready |
      | Documents | Overtime docs | Approval workflow | Routing configured |
    And specific 1C settings should be:
      | Setting Path | Configuration | Purpose |
      | Administration > HTTP Services | Enable wfm_Energosbyt_ExchangeWFM | API access |
      | Salary > Settings > Time tracking | Summarized time tracking | Monthly periods |
      | Personnel > Settings > Schedules | Individual schedules allowed | Per-employee |
      | Salary > Calculation > Types | Night work premium: 20% | Compliance |
```

### Addition 5: Vacation Schedule Upload Enhancement
**Location**: Add after line 109 in 21-1c-zup-integration.feature

```gherkin
  @vacation_schedules @excel_format @enhancement
  Scenario: Vacation Schedule Upload from WFM to 1C in Excel Format
    Given approved vacation schedules need to be uploaded to 1C
    When generating vacation schedule for upload
    Then the Excel file should follow this exact format:
      | Column | Header (Russian) | Header (English) | Data Type | Example |
      | A | Табельный номер | Personnel Number | String | "001234" |
      | B | ФИО | Full Name | String | "Иванов И.И." |
      | C | Подразделение | Department | String | "Контакт-центр" |
      | D | Должность | Position | String | "Оператор" |
      | E | Дата начала | Start Date | Date | 01.07.2025 |
      | F | Дата окончания | End Date | Date | 14.07.2025 |
      | G | Количество дней | Days Count | Number | 14 |
      | H | Тип отпуска | Vacation Type | String | "Основной" |
    And Excel generation rules should be:
      | Rule | Implementation | Validation |
      | Date format | DD.MM.YYYY | Russian locale |
      | Encoding | UTF-8 with BOM | Cyrillic support |
      | Sheet name | "График отпусков YYYY" | Current year |
      | Sorting | By department, then name | Logical grouping |
    And vacation types should map correctly:
      | WFM Type | 1C Type | Excel Value |
      | Regular vacation | ОсновнойОтпуск | "Основной" |
      | Additional vacation | ДополнительныйОтпуск | "Дополнительный" |
      | Unpaid leave | ОтпускБезСохранения | "Без сохранения" |
```

### Addition 6: Vacation Accrual Algorithm Enhancement
**Location**: Add after line 144 in 21-1c-zup-integration.feature

```gherkin
  @vacation_accrual @calculation_algorithm @enhancement
  Scenario: Vacation Entitlement Accrual Algorithm Specification
    Given vacation balances need to be calculated
    When applying 1C ZUP vacation accrual rules
    Then the calculation should follow Russian labor law:
      | Component | Formula | Example | Notes |
      | Base entitlement | 28 calendar days/year | 28 days | Minimum by law |
      | Monthly accrual | 28 / 12 = 2.33 days | 2.33 | Proportional |
      | Additional days | Based on conditions | +7 days | Northern regions |
      | Working period | 11 months = full year | 11/12 | Rounding rules |
    And accrual conditions should be checked:
      | Condition | Rule | Impact |
      | Probation period | No accrual first 6 months | Delayed start |
      | Sick leave | >14 days affects accrual | Reduced entitlement |
      | Unpaid leave | >14 days affects accrual | Reduced entitlement |
      | Work experience | 6 months = first vacation | Eligibility threshold |
    And the system should calculate:
      | Calculation Type | Method | Precision |
      | Days accrued | Monthly accumulation | 2 decimal places |
      | Days used | Deduction from balance | Whole days |
      | Days remaining | Accrued - Used | Real-time balance |
      | Expiry tracking | 2 years carry-over limit | Automatic warnings |
```

## Implementation Guide for Coding Agent

### Step 1: Identify Target File
- File: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/21-1c-zup-integration.feature`
- Backup the original file first

### Step 2: Add Scenarios in Order
1. Add Configuration Requirements after line 15 (extends Background context)
2. Add Vacation Schedule Upload after line 109 (enhances personnel sync)
3. Add Vacation Accrual Algorithm after line 144 (enhances vacation balance)
4. Add Time Standards Actualization after line 182 (extends getNormHours)
5. Add Document Execution after line 810 (extends document creation)
6. Add Initial Setup section after line 951 (new major section)

### Step 3: Validation
- Ensure proper Gherkin syntax
- Maintain consistent indentation (2 spaces)
- Use appropriate tags (@tag1 @tag2)
- Include data tables with pipes (|)
- Add business context in comments

### Step 4: Testing Impact
These additions will require:
- New test data for employee changes
- Document execution test scenarios  
- Initial setup test environment
- Excel file generation tests
- Vacation calculation verification

### Step 5: Documentation Update
Update the main BDD coverage report to show:
- Changed from 89% to ~98% coverage
- All missing features now addressed
- Enhanced partial features to complete