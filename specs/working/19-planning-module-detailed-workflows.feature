# /Users/m/Desktop/labor-standards-bdd/bdd-specs/19-planning-module-detailed-workflows.feature

Feature: Planning Module Detailed Workflows and UI Interactions
  As a planning specialist
  I want to follow specific planning workflows with exact UI interactions
  So that I can efficiently create and manage work schedules and timetables

  Background:
    Given I am logged in as a planning specialist
    And I have access to the Planning module
    And multi-skill planning templates are available

  @planning_templates @ui_workflow
  Scenario: Create Multi-skill Planning Template - Complete UI Workflow
    Given I navigate to "Planning" → "Multi-skill Planning" page
    When I see all created multi-skill planning templates displayed
    And I click on a template with the left mouse button
    Then I should see template information displayed to the right:
      | Information | Content |
      | Template Name | Name of the selected template |
      | Groups | List of groups included in template |
    When I click the "Create Template" button in the left part of the page
    Then a form for filling template data should appear
    And I enter the template name
    And I click "Save" to save it
    Then the new multi-skill planning template should appear in the general list
    When I click the "Add" button in the "Groups" window
    Then a dialog box should open with dropdown lists
    And I select "Service" and "Groups" using the dropdowns
    And I click "Save" in the dialog box
    Then the groups should be added to the multi-skill planning template

  @planning_templates @conflict_handling
  Scenario: Handle Group Conflicts in Multi-skill Templates
    Given I am adding groups to a multi-skill planning template
    When I try to add a group of operators who are already in another multi-skill template
    Then the system should issue a warning message
    And explain that an operator can only be in one multi-skill planning template
    And prevent the conflicting assignment
    And suggest alternative groups or templates

  @planning_templates @template_renaming
  Scenario: Rename Multi-skill Planning Template
    Given I have an existing multi-skill planning template
    When I right-click on the template name in the template list
    Then I should see a context menu with "Rename Template" option
    When I click "Rename Template"
    Then a dialog box should open with current template name pre-filled
    And I should be able to edit the template name
    When I enter a new template name "Updated Support Teams"
    And I click "Save" button
    Then the template name should be updated in the template list
    And the template information panel should reflect the new name
    And all associated work schedules should maintain their connection to the renamed template

  @planning_templates @group_removal
  Scenario: Remove Groups from Multi-skill Planning Template
    Given I have a multi-skill planning template with multiple groups
    When I select a template from the template list
    And I see the groups displayed in the "Groups" window
    And I right-click on a specific group in the groups list
    Then I should see a context menu with "Remove Group" option
    When I click "Remove Group"
    Then a confirmation dialog should appear asking:
      | Question | "Are you sure you want to remove this group from the template?" |
      | Warning | "This action will affect all schedules using this template" |
      | Options | "Yes" and "No" buttons |
    When I click "Yes" to confirm
    Then the group should be removed from the template
    And the template information should update to reflect the change
    And existing work schedules should be validated for coverage impacts

  @planning_templates @template_deletion
  Scenario: Delete Multi-skill Planning Template with Confirmation
    Given I have existing multi-skill planning templates
    When I right-click on a template in the template list
    Then I should see a context menu with "Delete Template" option
    When I click "Delete Template"
    Then a warning dialog should appear with:
      | Message | "Are you sure you want to delete this template?" |
      | Warning | "This action cannot be undone" |
      | Impact | "All associated work schedules will be automatically deleted" |
      | Options | "Yes" and "No" buttons |
    When I click "Yes" to confirm deletion
    Then the template should be removed from the template list
    And all associated work schedules should be automatically deleted
    And operators previously assigned to deleted schedules should be unassigned
    And the system should log the deletion action for audit purposes

  @planning_templates @template_selection_for_deletion
  Scenario: Select Template for Deletion from List
    Given I have multiple multi-skill planning templates
    When I need to delete a specific template
    Then I should be able to select the template by:
      | Method | Action | Visual Feedback |
      | Single Click | Click template name | Template highlights |
      | Right Click | Right-click template | Context menu appears |
      | Keyboard | Arrow keys + Enter | Template selection moves |
    And the selected template should be clearly highlighted
    And template information should display in the right panel
    And deletion option should be available via context menu or keyboard shortcut

  @planning_templates @deletion_confirmation_dialog
  Scenario: Template Deletion Confirmation Dialog with Yes/No Options
    Given I have selected a template for deletion
    When I initiate the deletion process
    Then a confirmation dialog should appear with exact elements:
      | Element | Content | Purpose |
      | Title | "Delete Template" | Dialog identification |
      | Message | "Are you sure you want to delete '[Template Name]'?" | Specific template confirmation |
      | Warning | "This action cannot be undone" | Irreversibility notice |
      | Impact | "All associated work schedules will be deleted" | Cascade impact warning |
      | Yes Button | "Yes, Delete" | Confirm deletion |
      | No Button | "Cancel" | Cancel deletion |
    And the "Yes" button should be styled as a destructive action
    And the "No" button should be the default focus
    And the dialog should be modal and block other actions

  @planning_templates @non_recovery_warning
  Scenario: Template Deletion Warning About Non-Recovery
    Given I am about to delete a multi-skill planning template
    When the deletion confirmation dialog appears
    Then I should see a prominent warning message:
      | Warning Text | "This action cannot be undone" |
      | Icon | Warning/Alert icon |
      | Style | Red text or warning color |
      | Position | Above the Yes/No buttons |
    And the warning should be clearly visible and readable
    And the warning should emphasize the permanent nature of the action
    And additional context should explain that:
      | Impact | "Deleted templates cannot be recovered" |
      | Scope | "All work schedules using this template will be lost" |
      | Recommendation | "Consider backing up data before deletion" |

  @planning_templates @automatic_schedule_deletion
  Scenario: Automatic Deletion of Associated Work Schedules
    Given I have a multi-skill planning template with associated work schedules
    When I delete the template
    Then the system should automatically handle cascading deletions:
      | Deletion Step | Action | Validation |
      | 1. Template deletion | Remove template from database | Confirm template removal |
      | 2. Schedule identification | Find all schedules using template | List affected schedules |
      | 3. Schedule deletion | Delete each associated schedule | Confirm schedule removal |
      | 4. Operator unassignment | Remove operators from deleted schedules | Update operator assignments |
      | 5. Audit logging | Log all deletion actions | Create audit trail |
    And the system should ensure data integrity throughout the process
    And any dependent processes should be notified of the changes
    And the deletion should be atomic (all or nothing)
    And rollback should be available if any step fails

  @work_schedule @schedule_creation_workflow
  Scenario: Create New Work Schedule Variant - Complete Workflow
    Given I navigate to "Work Schedule Planning" page through side menu or main page
    When I see the list of multi-skill planning templates
    And I select one template
    Then I should see a list of work schedule variants
    And the current applied work schedule should be highlighted in bold with checkmark
    When I click the "Create" button
    Then a window should open with specific fields:
      | Field | Purpose | Requirement |
      | Schedule name | Identify the schedule | Required |
      | Comment | Optional description | Optional |
      | Productivity | System type indicator | Shows annual/quarterly/monthly |
      | Work Schedule Planning Year | Planning year selection | Required |
      | Consider preferences | Operator preference checkbox | Optional |
    When I click "Start Planning" button
    Then the schedule name should appear in "Work Schedule Variants" window
    And planning task should appear in "Work Schedule Tasks" window
    And I can continue working in other modules while planning occurs

  @work_schedule @schedule_pinning
  Scenario: Applied Schedule Pinning to Top of List
    Given I have multiple work schedule variants in the list
    And one schedule is currently applied and active
    When I view the work schedule variants list
    Then the currently applied schedule should be:
      | Display Feature | Specification |
      | Position | Pinned to the top of the list |
      | Visual Indicator | Bold text with checkmark icon |
      | Background Color | Highlighted background (light blue/green) |
      | Sort Order | Always first regardless of creation date |
      | Label | "Current" or "Active" label |
    And other schedule variants should be sorted below the pinned schedule
    And the pinned schedule should remain at the top even when new variants are added
    And the pinning should persist across page refreshes and user sessions

  @ui_enhancements @alternative_timezone_display
  Scenario: Alternative Time Zone Display Options
    Given I am working with schedules across different time zones
    When I access time zone selection options
    Then I should see alternative display options:
      | Display Option | Format | Example | Use Case |
      | Local Time | User's system time zone | 09:00 EST | Default display |
      | UTC/GMT | Universal time | 14:00 UTC | International coordination |
      | Dual Time | Local + UTC | 09:00 EST (14:00 UTC) | Multi-timezone operations |
      | Relative Time | Offset from user | +5 hours | Quick reference |
      | Multiple Zones | Side-by-side display | EST\|PST\|UTC | Multi-location teams |
    And I should be able to switch between display modes
    And the selected display mode should be saved as user preference
    And all time-related fields should respect the selected display mode
    And time zone abbreviations should be clearly shown

  @ui_enhancements @vacation_violation_tooltips
  Scenario: Vacation Violation Tooltip on Hover
    Given I have vacation schedules with potential violations
    When I hover over a vacation period marked with violation indicator
    Then a tooltip should appear showing:
      | Tooltip Content | Description |
      | Violation Type | "Vacation Rule Violation" |
      | Specific Rule | "Minimum 7 days notice required" |
      | Current Value | "Only 3 days notice given" |
      | Impact | "May affect approval process" |
      | Suggestion | "Contact supervisor for exception" |
      | Severity | High/Medium/Low with color coding |
    And the tooltip should appear within 500ms of hover
    And the tooltip should disappear when mouse moves away
    And the tooltip should be positioned to avoid screen edges
    And multiple violations should be listed in priority order

  @ui_enhancements @enhanced_statistics_display
  Scenario: Enhanced Monthly and Yearly Statistics Display
    Given I am viewing schedule statistics and analytics
    When I access the statistics display options
    Then I should see enhanced statistics with:
      | Statistic Type | Monthly Display | Yearly Display | Calculation Method |
      | Operator Hours | Sum of all monthly hours | Sum of all yearly hours | Aggregated from daily data |
      | Productivity | Average monthly productivity | Average yearly productivity | Weighted by hours worked |
      | Overtime | Monthly overtime hours | Yearly overtime hours | Hours exceeding standard |
      | Vacation Usage | Monthly vacation days used | Yearly vacation days used | Calendar days consumed |
      | Absence Rate | Monthly absence percentage | Yearly absence percentage | Absent days / scheduled days |
      | Coverage Level | Monthly coverage percentage | Yearly coverage percentage | Staffed hours / required hours |
    And statistics should be displayed with:
      | Visual Element | Specification |
      | Charts | Bar charts, line graphs, pie charts |
      | Trend Indicators | Up/down arrows with percentage change |
      | Color Coding | Green (good), Yellow (caution), Red (problem) |
      | Drill-down | Click to see detailed breakdown |
      | Export | Download as Excel, PDF, or CSV |

  @ui_enhancements @working_hours_shift_display
  Scenario: Enhanced Working Hours per Shift Cell Display
    Given I am viewing the schedule grid with shift information
    When I look at individual shift cells
    Then each cell should display:
      | Cell Element | Format | Example | Purpose |
      | Shift Time | HH:MM-HH:MM | 09:00-17:00 | Shift duration |
      | Break Time | (HH:MM break) | (01:00 break) | Total break time |
      | Net Hours | Net: H.HH | Net: 7.00 | Actual work hours |
      | Project Code | [CODE] | [TECH] | Project assignment |
      | Skill Level | Skill icon | 🔧 | Required skill indicator |
    And cells should use consistent formatting and colors
    And overtime hours should be highlighted in different color
    And part-time shifts should be visually distinguished
    And cell information should be clear and readable at standard zoom levels

  @ui_enhancements @shift_information_tooltips
  Scenario: Enhanced Shift Information Tooltip on Hover
    Given I am viewing the schedule grid
    When I hover over a shift cell
    Then a detailed tooltip should appear showing:
      | Tooltip Section | Information | Format |
      | Shift Details | Start time, End time, Duration | "09:00-17:00 (8 hours)" |
      | Break Schedule | Lunch and break times | "Lunch: 12:00-13:00, Breaks: 10:30, 15:30" |
      | Employee Info | Name, Position, Skills | "John Doe, Senior Agent, Level 2" |
      | Workload | Expected calls, Productivity target | "50 calls, 85% target" |
      | Project Assignment | Current project, Percentage allocation | "Technical Support, 80%" |
      | Compliance | Labor law compliance status | "Compliant" or specific violations |
    And the tooltip should be well-formatted and easy to read
    And the tooltip should update dynamically if shift data changes
    And the tooltip should include color coding for different information types

  @work_schedule @planning_status_tracking
  Scenario: Track Work Schedule Planning Status with Exact Status Values
    Given a planning task is running
    When I check the task status by clicking refresh button
    Then I should see these exact schedule statuses:
      | Schedule Status | Exact Description |
      | Planning | There are open tasks for initial planning |
      | Planned | No open tasks, planning service sends result to WFMCC |
      | Planning Error | Planning was done incorrectly, can restart |
      | Updating | There are open tasks for updating work schedule |
      | Update Error | All update tasks completed with errors |
    And these exact task statuses:
      | Task Status | Exact Description |
      | Executing | Task executing or waiting for execution in planning service |
      | Awaiting Save | Task completed, result passed to WFMCC, awaits user action |
      | Result Saved | User saved the planning result |
      | Result Canceled | User canceled saving the planning result |
      | Execution Error | Planning error or error passing result to WFMCC |

  @work_schedule @schedule_review_detailed
  Scenario: Review Planned Work Schedule - Exact Interface Elements
    Given I click on a task with "Awaiting Save" status
    When the planned work schedule appears
    Then I see two tab options with exact content:
      | Tab Name | Russian | Content |
      | Org. Structure | Орг. Структура | Department-based view |
      | Func. Structure | Функц. Структура | Group-based view |
    In "Org. Structure" tab I see these exact checkboxes:
      | Checkbox | Russian | Purpose |
      | Operators without planned vacations | Операторы без запланированных отпусков | Positive vacation days, no vacation assigned |
      | Employees with non-plannable position | Сотрудники с непланируемой должностью | Position changed to not plan |
      | Vacation violations | Нарушения отпусков | Vacation assigned in violation of rules |
      | Desired vacations | Желаемые отпуска | Highlight with frame |
    In "Func. Structure" tab I see these exact checkboxes:
      | Checkbox | Russian | Purpose |
      | Op. Forecast | Прогноз Оп. | Forecasted operators per day/month |
      | Op. Plan | План Оп. | Planned operators per day/month |
      | Op. Plan %Abs | План Оп. %Отс | Planned operators × absence percentage |
      | %ACD forecast | Прогноз %ACD | Average forecasted %ACD for 15-min intervals |

  @vacation_planning @vacation_interface_exact
  Scenario: Vacation Schedule Interface - Exact UI Elements
    Given I am on the "Vacation Schedule" tab
    Then I see these exact top panel elements:
      | Element | Russian | Function |
      | Group Filter | Фильтр групп | View specific group |
      | Department Filter | Фильтр подразделений | View specific department |
      | Generate vacations button | Сгенерировать отпуска | Auto-generate vacations |
    And these exact checkboxes:
      | Checkbox | Russian | Purpose |
      | Operators with unassigned vacation | Операторы с неназначенным отпуском | Show unassigned vacation |
      | Operators with accumulated vacation days | Операторы с накопленными днями отпуска | Show accumulated days |
      | Subordinate employees | Подчиненные сотрудники | Department subordinates |
      | Vacation violations | Нарушения отпусков | Show rule violations |
      | Desired vacations | Желаемые отпуска | Show all desired, hide extraordinary |
    And exact table columns:
      | Column | Russian | Content |
      | Full Name | ФИО | Employee full name |
      | Planned Vacation Scheme | Планируемая схема отпусков | Assigned vacation scheme |
      | Remaining Vacation Days | Остаток дней отпуска | Days after vacation assignment |

  @vacation_planning @vacation_addition_exact_workflow
  Scenario: Add Vacation - Exact Right-click Workflow
    Given I am in vacation schedule view
    When I select a cell with left mouse button
    And I right-click to open context menu
    And I select "Add Vacation" (Добавить отпуск)
    Then dialog opens asking for vacation type:
      | Type | Russian | Configuration Required |
      | Extraordinary Vacation | Внеочередной отпуск | Start date + End date |
      | Desired Vacation | Желаемый отпуск | Vacation scheme + Method |
    When I select "Desired Vacation"
    Then I must choose creation method:
      | Method | Russian | Date Handling | Day Deduction |
      | Period | Период | Fixed period, holidays included | Exclude holidays from deduction |
      | Calendar Days | Календарные дни | Shifts around holidays | Full duration deducted |

  @vacation_planning @vacation_priorities_exact
  Scenario: Set Vacation Priorities - Exact Right-click Options
    Given I have vacation periods in the schedule
    When I right-click on vacation interval cell
    Then I see these exact priority options:
      | Option | Russian | Planning Effect |
      | Vacation Priority | Приоритетный отпуск | Move non-priority first, then priority |
      | Non-priority Vacation | Неприоритетный отпуск | Can move within shift range |
      | Fixed Vacation | Фиксированный отпуск | Never moves regardless of workload |
    And vacation should be visually marked according to priority
    And planning should respect these priorities during generation

  @schedule_planning @timetable_creation_exact
  Scenario: Create Timetable - Exact Interface Workflow
    Given I navigate to "Planning" → "Schedule Creation"
    When I select template and click "Create" in "Schedule" block
    Then "Schedule Planning" dialog opens with:
      | Field | Russian | Purpose |
      | Period | Период | Schedule action period |
      | Planning criteria | Критерии планирования | From Planning → Planning Criteria |
    When planning completes I see these exact view modes:
      | View | Russian | Content |
      | By employees | По сотрудникам | List of all employees |
      | By direction | По направлению | Specific group operators only |
    And exact statistics:
      | Statistic | Russian | Content |
      | Project | Проект | Project name |
      | Start Date | Дата начала | Project start |
      | End Date | Дата окончания | Project end |
      | Segment Requirement | Потребность сегментов | Intervals needed |
      | Total Segments Assigned | Всего назначено сегментов | All schedules |
      | Segments Assigned in Schedule | Назначено сегментов в расписании | Current schedule |

  @schedule_planning @manual_corrections_exact_ui
  Scenario: Manual Schedule Changes - Exact UI Interactions
    Given I have created schedule to modify
    When I select time intervals (5-minute divisions)
    And I right-click on selected interval
    Then I see these exact context menu options:
      | Option | Russian | Condition |
      | Add Lunch | Добавить обед | If lunch rules allow |
      | Add Break | Добавить перерыв | If break rules allow |
      | Cancel Breaks | Отменить перерывы | Remove existing breaks |
      | Does not accept calls | Не принимает звонки | Register downtime |
      | Non-working time | Нерабочее время | Register non-working |
      | Add work attendance | Добавить явку | Project view only |
      | Assign to project | Назначить на проект | 100% project engagement |
      | Event | Событие | Training/meeting/calls/survey |
      | Cancel Event | Отменить событие | Remove scheduled event |

  @schedule_planning @schedule_application_exact
  Scenario: Apply Schedule - Exact Workflow and Dialogs
    Given schedule is compiled and meets criteria
    When I select schedule variant and click "Apply"
    Then schedule becomes active and available in "Current Schedule"
    And appears highlighted in bold in variants list
    When schedule overlap occurs
    Then exact warning dialog appears asking:
      | Option | Russian | Action |
      | Confirm | Подтвердить | Overwrite overlapping dates |
      | Cancel | Отменить | Cancel new schedule application |
    And applied schedule becomes the active working schedule

  @business_process @exact_bp_workflow
  Scenario: Business Process Upload - Exact Interface
    Given I need automated workflow handling
    When I navigate to BP upload page from main screen
    Then I see exact interface elements:
      | Element | Function |
      | Browse button | Open file selection |
      | Upload button | Start upload (activated after file selection) |
      | Cancel button | Cancel operation (activated after file selection) |
    And I select .zip or .rar archive with BP definition
    Then Upload and Cancel buttons become active
    When upload completes BP stores:
      | Information | Content |
      | Stage sequence | Workflow step order |
      | User permissions | Stage authorization |
      | Available actions | Stage-specific actions |
      | Transition rules | Between-stage conditions |

  @vacation_planning @vacation_deletion_context_menu
  Scenario: Vacation Deletion via Context Menu
    Given I have vacation periods assigned to employees
    When I right-click on a vacation period cell in the vacation schedule
    Then I should see a context menu with "Delete Vacation" option
    When I click "Delete Vacation"
    Then a confirmation dialog should appear asking:
      | Question | "Are you sure you want to delete this vacation period?" |
      | Impact | "This will restore the vacation days to the employee's available balance" |
      | Warning | "This action cannot be undone" |
      | Options | "Yes, Delete" and "Cancel" buttons |
    When I click "Yes, Delete" to confirm
    Then the vacation period should be removed from the schedule
    And the employee's remaining vacation days should be updated
    And the vacation schedule should be recalculated
    And any conflicts should be resolved automatically

  @vacation_planning @automatic_vacation_arrangement
  Scenario: Automatic Vacation Arrangement During Planning
    Given I have employees with unassigned vacation days
    And I have business rules configured for vacation planning
    When I click "Generate vacations" button for automatic arrangement
    Then the system should apply automatic vacation arrangement using:
      | Arrangement Rule | Logic | Priority |
      | Vacation preferences | Use desired vacation periods first | 1 |
      | Workload distribution | Avoid high-demand periods | 2 |
      | Team coverage | Ensure minimum staffing levels | 3 |
      | Blackout periods | Respect vacation blackout rules | 4 |
      | Seniority rules | Senior employees get first choice | 5 |
      | Fairness algorithm | Distribute vacation periods evenly | 6 |
    And the system should generate vacation assignments that:
      | Criterion | Specification |
      | Coverage | Maintain minimum operator coverage |
      | Distribution | Spread vacations throughout the year |
      | Preferences | Honor as many preferences as possible |
      | Compliance | Follow all business rules |
      | Optimization | Minimize conflicts and overlaps |
    And provide a summary of:
      | Summary Item | Content |
      | Assignments Made | Number of vacation periods assigned |
      | Preferences Honored | Percentage of preferences satisfied |
      | Conflicts Resolved | Number of conflicts automatically resolved |
      | Manual Review Needed | Items requiring supervisor attention |

  @vacation_planning @business_vacation_rules_integration
  Scenario: Enhanced Business Vacation Rules Integration for Generation
    Given I have configured comprehensive business vacation rules
    When the system generates vacation assignments
    Then it should integrate with business rules including:
      | Rule Category | Specific Rules | Implementation |
      | Timing Rules | Minimum notice period, Maximum advance booking | Validate assignment dates |
      | Duration Rules | Minimum/maximum vacation length, Consecutive day limits | Check vacation period length |
      | Coverage Rules | Minimum staffing levels, Critical skill coverage | Ensure adequate coverage |
      | Seniority Rules | Senior employee priority, Conflict resolution | Apply hierarchy logic |
      | Seasonal Rules | Peak period restrictions, Holiday blackouts | Respect seasonal constraints |
      | Department Rules | Department-specific policies, Manager approval | Apply departmental rules |
    And the system should validate each assignment against:
      | Validation Check | Criteria | Action if Failed |
      | Coverage Impact | Minimum operators maintained | Suggest alternative dates |
      | Rule Compliance | All business rules satisfied | Flag for manual review |
      | Preference Alignment | Employee preferences respected | Optimize within constraints |
      | Conflict Resolution | No overlapping critical absences | Automatic conflict resolution |
    And provide detailed reporting on:
      | Report Element | Content |
      | Rule Violations | Any rules that couldn't be satisfied |
      | Optimization Score | How well assignments meet all criteria |
      | Manual Actions | Items requiring supervisor intervention |
      | Improvement Suggestions | Recommendations for better results |

  @vacation_planning @vacation_shifting_workload_integration
  Scenario: Enhanced Vacation Shifting Based on Workload and Rules
    Given I have vacation periods that may need adjustment
    And I have workload forecasts and business rules configured
    When the system evaluates vacation shifting needs
    Then it should apply workload-based shifting logic:
      | Shifting Factor | Evaluation Criteria | Action |
      | Workload Peaks | High-demand periods identified | Shift vacations away from peaks |
      | Coverage Gaps | Insufficient operator coverage | Redistribute vacation timing |
      | Skill Requirements | Critical skill shortages | Prioritize skilled operator coverage |
      | Business Rules | Vacation policy compliance | Ensure all rules remain satisfied |
      | Employee Preferences | Desired vacation periods | Minimize preference disruption |
      | Operational Impact | Service level maintenance | Optimize for service continuity |
    And shifting should consider:
      | Consideration | Logic | Priority |
      | Priority Vacations | Fixed and priority vacations immutable | 1 |
      | Preference Impact | Minimize disruption to desired dates | 2 |
      | Workload Balance | Distribute load evenly | 3 |
      | Coverage Optimization | Maintain adequate staffing | 4 |
      | Rule Compliance | All business rules satisfied | 5 |
    And provide shifting recommendations:
      | Recommendation Type | Content |
      | Optimal Shifts | Best alternative dates for each vacation |
      | Impact Analysis | How shifts affect coverage and preferences |
      | Conflict Resolution | Solutions for competing vacation requests |
      | Manual Review | Situations requiring supervisor decision |

  @vacation_planning @extraordinary_vacation_deduction_logic
  Scenario: Enhanced Extraordinary Vacation Without Accumulated Days Deduction
    Given I am creating extraordinary vacation periods
    When I assign extraordinary vacation to an employee
    Then the system should apply enhanced deduction logic:
      | Vacation Type | Deduction Logic | Accumulated Days Impact |
      | Extraordinary | No deduction from accumulated days | Balance unchanged |
      | Desired | Deduct from accumulated days | Balance reduced |
      | Carry-over | Special handling for previous year | Separate tracking |
    And the system should track:
      | Tracking Element | Purpose | Display |
      | Accumulated Balance | Standard vacation days earned | Main vacation counter |
      | Extraordinary Days | Days granted outside normal allocation | Separate counter |
      | Used Days | Days actually taken | Deduction tracking |
      | Pending Days | Days assigned but not yet taken | Future obligations |
    And provide clear distinction in:
      | Display Area | Extraordinary Vacation | Desired Vacation |
      | Color Coding | Different color (orange/purple) | Standard color (blue/green) |
      | Icon | Special icon (star/exclamation) | Standard icon |
      | Tooltip | "Extraordinary - no deduction" | "Desired - days deducted" |
      | Calculations | Excluded from balance calculations | Included in balance calculations |
    And ensure proper reporting:
      | Report Type | Extraordinary Vacation Handling |
      | Vacation Balance | Shown separately from accumulated days |
      | Usage Reports | Categorized by vacation type |
      | Audit Trail | Clear record of extraordinary grants |
      | Compliance | Proper tracking for labor law compliance |

  @vacancy_planning @workforce_capacity @priority_high
  Scenario: Create vacancy planning template
    Given I am a system administrator
    When I access the vacancy planning module
    Then I should see the vacancy planning interface with:
      | Field | Type | Content | Purpose |
      | Department | Dropdown | All departments | Select planning scope |
      | Position | Dropdown | All positions | Select vacancy type |
      | Required Skills | Multi-select | Skill categories | Define requirements |
      | Urgency Level | Dropdown | High/Medium/Low | Prioritize filling |
      | Expected Duration | Date range | Start/End dates | Planning timeline |
    And I should be able to create vacancy requests
    And the system should track staffing gaps
    And vacancy status should be: Open/In Progress/Filled/Cancelled

  @vacancy_planning @staffing_gaps @priority_high
  Scenario: Monitor staffing gaps and vacancies
    Given I have created vacancy planning templates
    When I access the vacancy monitoring dashboard
    Then I should see current staffing gaps:
      | Department | Position | Gap Count | Urgency | Days Open |
      | Sales | Senior Agent | 3 | High | 15 |
      | Support | Team Lead | 1 | Medium | 8 |
      | Technical | Specialist | 2 | Low | 22 |
    And I should see forecasted staffing needs
    And gap impact on service levels should be calculated
    And recruitment recommendations should be provided

  @vacancy_planning @capacity_planning @priority_high
  Scenario: Integrate vacancy planning with workforce forecasting
    Given I have vacancy planning active
    When I generate workforce forecasts
    Then vacancy impact should be included in calculations
    And service level impact should affect capacity planning
    And recruitment timeline should affect capacity planning
    And budget impact should be calculated for unfilled positions

  @planning_dashboard @centralized_interface @priority_medium
  Scenario: Access centralized planning operations dashboard
    Given I am a planning manager
    When I access the planning dashboard
    Then I should see overview of:
      | Planning Area | Status | Completion | Next Action |
      | Work Schedules | 85% | In Progress | Review drafts |
      | Vacation Plans | 92% | Nearly Complete | Final approval |
      | Shift Patterns | 78% | In Progress | Add templates |
      | Multi-skill Plans | 88% | In Progress | Assign resources |
    And I should have quick access to:
      | Function | Purpose | Priority |
      | Create Schedule | New planning | High |
      | Approve Plans | Authorization | High |
      | View Reports | Analysis | Medium |
      | Template Management | Configuration | Low |
    And dashboard should highlight urgent tasks
    And progress tracking should be visual

  @planning_dashboard @resource_utilization @priority_medium
  Scenario: Monitor resource utilization through planning dashboard
    Given I am using the planning dashboard
    When I review resource utilization
    Then I should see:
      | Resource Type | Utilization | Trend | Recommendation |
      | Full-time Staff | 95% | ↑ | Consider overtime |
      | Part-time Staff | 75% | → | Increase hours |
      | Contractors | 60% | ↓ | Reduce contracts |
      | Vacation Pool | 45% | ↑ | Encourage usage |
    And utilization trends should be forecasted
    And optimization recommendations should be provided
    And cost impact should be calculated
   @bulk_operations @schedule_management @medium
   Scenario: Enhanced bulk schedule operations interface
     Given I am logged in as schedule manager
     And I have multiple schedules to modify
     When I navigate to bulk schedule operations
     Then I should see enhanced bulk interface:
       | Operation | Description | Availability |
       | Bulk Copy | Copy schedules across periods | Available |
       | Mass Update | Update multiple schedule properties | Available |
       | Batch Delete | Delete multiple schedule entries | Available |
       | Pattern Apply | Apply patterns to multiple schedules | Available |
     When I select "Mass Update" operation
     And I choose schedules for modification:
       | Schedule | Period | Operators | Selected |
       | Morning Shift | Week 1 | 15 | Yes |
       | Evening Shift | Week 1 | 12 | Yes |
       | Night Shift | Week 1 | 8 | No |
     And I specify update parameters:
       | Parameter | Current | New | Apply |
       | Break Duration | 15 min | 20 min | Yes |
       | Lunch Duration | 30 min | 45 min | Yes |
     Then I should see update preview with impact analysis
     When I confirm bulk update
     Then I should see progress indicator with real-time status
     And all selected schedules should be updated consistently
     And bulk operation log should be created

