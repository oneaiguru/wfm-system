Feature: Work Schedule and Vacation Planning
  As a planning specialist and supervisor
  I want to plan comprehensive work schedules and vacation allocations
  So that workforce coverage meets business needs while respecting employee preferences

  Background:
    Given the system has role-based access for schedule planning
    And multi-skill planning templates are configured
    And work rules and vacation schemes are defined

  @schedule_planning @performance_assignment
  Scenario: Assign Employee Performance Standards
    Given I am logged in as a supervisor
    And I navigate to employee management
    When I assign performance standards to employees:
      | Employee | Performance Type | Standard Value | Period |
      | Иванов И.И. | Monthly | 168 hours | 2025 |
      | Петров П.П. | Annual | 2080 hours | 2025 |
      | Сидорова А.А. | Weekly | 40 hours | Ongoing |
    Then the performance standards should be saved to employee cards
    And schedule planning should respect these standards
    And overtime calculations should use these baselines
    And reporting should track actual vs standard performance

  @schedule_planning @work_rules
  Scenario: Create Work Rules with Rotation
    Given I am logged in as a planning specialist
    And I navigate to "References" → "Work Rules"
    When I create a work rule with the following configuration:
      | Field | Value |
      | Name | 5/2 Standard Week |
      | Mode | With rotation |
      | Consider holidays | Yes |
      | Time zone | Europe/Moscow |
      | Mandatory shifts by day | No |
    And I configure shifts:
      | Shift Name | Start Time | Duration | Type |
      | Work Day 1 | 09:00 | 08:00 | Standard |
      | Work Day 2 | 14:00 | 08:00 | Standard |
    And I set rotation pattern "WWWWWRR" (5 work days, 2 rest)
    And I configure shift constraints:
      | Parameter | Value |
      | Min hours between shifts | 11 |
      | Max consecutive work hours | 40 |
      | Max consecutive work days | 5 |
    Then the work rule should be created successfully
    And be available for assignment to employees

  @schedule_planning @flexible_rules
  Scenario: Create Flexible Work Rules
    Given I am creating a flexible work rule
    When I configure flexible parameters:
      | Parameter | Value |
      | Name | Flexible Schedule |
      | Start time range | 08:00-10:00 |
      | Duration range | 07:00-09:00 |
      | Core hours | 10:00-15:00 |
      | Mode | Without rotation |
    Then the system should allow flexible planning within ranges
    And actual times should be determined by load coverage needs
    And employees should have scheduling flexibility within bounds

  @schedule_planning @split_shifts
  Scenario: Configure Split Shift Work Rules
    Given I need to create split shift coverage
    When I create a split shift work rule:
      | Field | Value |
      | Name | Split Coverage |
      | Type | Split shift |
    And I add shift parts:
      | Part | Start Time | Duration | Break Type |
      | Morning | 08:00 | 04:00 | Paid |
      | Evening | 16:00 | 04:00 | Paid |
      | Between parts | 12:00-16:00 | Unpaid break | Unpaid |
    Then total work time should equal standard full shift
    And break between parts should be unpaid time
    And schedule should show both work periods

  @schedule_planning @lunch_break_rules
  Scenario: Create Business Rules for Lunches and Breaks
    Given I am configuring break and lunch policies
    When I create lunch/break rules:
      | Rule Type | Duration | Timing | Constraints |
      | Lunch | 60 minutes | 11:00-15:00 | 1 per shift |
      | Short Break | 15 minutes | Every 2 hours | Max 3 per shift |
      | Technical Break | 10 minutes | As needed | Supervisor approval |
    And I set break scheduling rules:
      | Parameter | Value |
      | Min time before lunch | 2 hours |
      | Max time after lunch | 6 hours |
      | Break spacing | Min 90 minutes |
      | Overlap restrictions | Max 20% of team |
    Then break rules should apply automatically during scheduling
    And prevent conflicts with coverage requirements

  @schedule_planning @template_assignment
  Scenario: Assign Work Rule Templates to Employees
    Given work rules are created and validated
    When I assign work rule templates:
      | Employee Group | Work Rule | Effective Period |
      | Call Center Level 1 | 5/2 Standard Week | 01.01.2025-31.12.2025 |
      | Call Center Level 2 | Flexible Schedule | 01.01.2025-30.06.2025 |
      | Email Support | Split Coverage | 01.02.2025-31.12.2025 |
    And I perform mass assignment for 50 operators
    Then all selected employees should have rules assigned
    And conflicting existing rules should generate warnings
    And assignment should be effective from specified dates

  @vacation_planning @vacation_schemes
  Scenario: Configure Vacation Schemes
    Given I am logged in as an administrator
    And I navigate to "References" → "Vacation Schemes"
    When I create vacation schemes:
      | Scheme Name | Duration | Type | Rules |
      | Standard Annual | 28 days | Calendar year | Must use by Dec 31 |
      | Senior Employee | 35 days | Calendar year | 7 days carryover allowed |
      | Part-time | 14 days | Prorated | Based on work percentage |
    And I configure vacation rules:
      | Parameter | Value |
      | Min vacation block | 7 days |
      | Max vacation block | 21 days |
      | Notice period | 14 days |
      | Blackout periods | Dec 15-31, Jun 1-15 |
    Then vacation schemes should be available for assignment
    And business rules should enforce vacation constraints

  @vacation_planning @scheme_assignment
  Scenario: Assign Vacation Schemes to Employees
    Given vacation schemes are configured
    When I assign schemes to employees:
      | Employee | Scheme | Effective Date | Accumulated Days |
      | Иванов И.И. | Standard Annual | 01.01.2025 | 28 |
      | Петров П.П. | Senior Employee | 01.01.2025 | 35 |
      | Сидорова А.А. | Part-time | 01.01.2025 | 14 |
    Then vacation entitlements should be updated in employee cards
    And accumulated vacation days should reflect assignments
    And vacation planning should respect individual allocations

  @vacation_planning @desired_vacations
  Scenario: Assign Desired Vacations to Employees
    Given employees have vacation schemes assigned
    When supervisors assign desired vacation periods:
      | Employee | Vacation Period | Type | Priority |
      | Иванов И.И. | 15.07.2025-29.07.2025 | Desired | Normal |
      | Петров П.П. | 01.08.2025-21.08.2025 | Desired | Priority |
      | Сидорова А.А. | 15.06.2025-21.06.2025 | Extraordinary | Fixed |
    And vacation preferences are saved
    Then desired vacations should appear in vacation schedule
    And be considered during work schedule planning
    And priority levels should affect vacation assignment order

  @multiskill_planning @template_creation
  Scenario: Create Multi-skill Planning Template
    Given I am logged in as a planning specialist
    And I navigate to "Planning" → "Multi-skill Planning"
    When I create a planning template:
      | Field | Value |
      | Template Name | Technical Support Teams |
      | Description | Combined Level 1, Level 2, and Email Support |
    And I add groups to the template:
      | Service | Groups | Priority |
      | Technical Support | Level 1 Support | Primary |
      | Technical Support | Level 2 Support | Secondary |
      | Technical Support | Email Support | Backup |
    Then the template should enforce exclusive operator assignment
    And prevent operators from being in multiple templates
    And be available for schedule planning

  @vacation_schedule @vacation_management
  Scenario: Manage Vacations in Work Schedule
    Given I have a multi-skill planning template
    And I navigate to vacation schedule management
    When I work with vacation assignments:
      | Action | Method | Impact |
      | View operators without vacation | Filter checkbox | Show unassigned employees |
      | Generate automatic vacations | "Generate vacations" button | Use business rules |
      | Add manual vacation | Right-click → "Add Vacation" | Create specific assignment |
      | Set vacation priority | Right-click → "Vacation Priority" | Influence planning order |
      | Fix vacation dates | Right-click → "Fixed Vacation" | Prevent system adjustment |
    Then vacation changes should integrate with work schedule planning
    And vacation violations should be highlighted
    And accumulated vacation days should be properly tracked

  @schedule_creation @planning_process
  Scenario: Plan Work Schedule with Integrated Vacation Management
    Given multi-skill template and vacation schedule are configured
    When I create a new work schedule variant:
      | Field | Value |
      | Schedule Name | Q1 2025 Complete Schedule |
      | Year | 2025 |
      | Performance Type | Monthly |
      | Consider Preferences | Yes |
      | Include Vacation Planning | Yes |
    And I start the planning process
    Then the system should:
      | Planning Step | Consideration |
      | Forecast Analysis | Workload requirements |
      | Work Rule Application | Employee-specific rules |
      | Vacation Integration | Desired and fixed vacations |
      | Labor Standards Check | Compliance validation |
      | Preference Consideration | Employee preferences |
    And generate a comprehensive schedule with integrated vacation plan

  @notifications @planning_notifications
  Scenario: Configure Planning Notifications
    Given I am logged in as an administrator
    And I navigate to notification configuration
    When I set up planning-related notifications:
      | Event | Recipients | Method | Timing |
      | Schedule Created | Planning specialists | Email + System | Immediate |
      | Vacation Conflicts | Supervisors | Email | Daily digest |
      | Planning Errors | Administrators | SMS + Email | Immediate |
      | Schedule Ready for Review | Department heads | System notification | When complete |
    Then notifications should be sent according to configuration
    And recipients should receive timely updates about planning status

  @schedule_application @schedule_deployment
  Scenario: Apply Planned Work Schedule
    Given a work schedule variant is successfully planned
    And vacation allocations are integrated
    When I apply the schedule for the selected template:
      | Action | Validation |
      | Review schedule accuracy | Check against requirements |
      | Validate vacation assignments | Confirm vacation day usage |
      | Check labor compliance | Verify standards adherence |
      | Apply schedule | Make active for operations |
    Then the schedule should become the current active schedule
    And be available in "Current Schedule" section
    And employees should see their assigned schedules in personal cabinets

  @schedule_corrections @operational_adjustments
  Scenario: Make Operational Schedule Corrections
    Given an active work schedule is applied
    When I need to make real-time corrections:
      | Correction Type | Method | Validation |
      | Extend shift | Drag shift end time | Check overtime limits |
      | Shorten shift | Drag shift start time | Verify minimum coverage |
      | Move shift | Drag entire shift | Check rest period compliance |
      | Delete shift | Click delete button | Confirm coverage impact |
      | Add emergency shift | Double-click empty slot | Validate labor standards |
    Then changes should be applied immediately
    And affected employees should be notified
    And labor standards compliance should be maintained

  @vacation_types @vacation_management_detail
  Scenario: Handle Different Vacation Types and Calculation Methods
    Given I am managing employee vacation schedules
    When I create different types of vacation:
      | Vacation Type | Calculation Method | Impact |
      | Desired Vacation (Period) | Start date + End date | Fixed period, holidays don't shift |
      | Desired Vacation (Calendar Days) | Start date + Duration | Shifts around holidays |
      | Extraordinary Vacation | Manual assignment | Doesn't deduct accumulated days |
    And I specify vacation parameters:
      | Parameter | Desired (Period) | Desired (Calendar) | Extraordinary |
      | Holiday Handling | Include in period | Shift vacation | No impact |
      | Day Deduction | Exclude holidays | Full duration | No deduction |
      | Flexibility | Fixed dates | Date shifting | Manager discretion |
    Then vacation calculations should follow the specified method
    And accumulated vacation day tracking should be accurate

  @employment_periods @enhanced_hire_termination_integration
  Scenario: Enhanced Hire and Termination Date Integration in Schedule Planning
    Given I am planning schedules for employees with varying employment periods
    When I integrate hire and termination dates into schedule planning
    Then the system should handle employment period logic comprehensively:
      | Employment Status | Date Range | Planning Impact | Validation |
      | New Hire | Hire date to future | Start scheduling from hire date | Verify hire date validity |
      | Active Employee | Hire date to termination/ongoing | Full scheduling capability | Standard validation |
      | Terminating Employee | Hire date to termination date | End scheduling before termination | Ensure proper transition |
      | Rehire | Multiple employment periods | Handle gaps and overlaps | Validate rehire logic |
      | Contractor | Contract start to end | Temporary assignment handling | Contract validation |
    And employment period integration should consider:
      | Factor | Logic | Implementation |
      | Probation Period | Reduced scheduling flexibility | Limit complex assignments |
      | Ramp-up Period | Gradual productivity increase | Adjusted work standards |
      | Notice Period | Transition planning | Knowledge transfer scheduling |
      | Training Period | Skill development scheduling | Training block allocation |
      | Certification Requirements | Skill-based availability | Certification tracking |
    And provide employment period analytics:
      | Analytic | Content | Purpose |
      | Tenure Analysis | Employment duration statistics | Retention planning |
      | Turnover Impact | Scheduling disruption assessment | Stability analysis |
      | Ramp-up Tracking | New employee productivity progression | Training effectiveness |
      | Transition Planning | Termination impact on schedules | Succession planning |

  @productivity_standards @enhanced_employment_period_compliance
  Scenario: Enhanced Productivity Standard Compliance with Employment Periods
    Given I have productivity standards and employment period requirements
    When I ensure compliance between productivity and employment periods
    Then the system should apply period-aware productivity standards:
      | Employment Phase | Productivity Standard | Adjustment Factor | Rationale |
      | First 30 days | 60% of standard | 0.6 | Initial learning curve |
      | Days 31-90 | 80% of standard | 0.8 | Skill development |
      | Days 91-180 | 95% of standard | 0.95 | Near full capability |
      | 180+ days | 100% of standard | 1.0 | Full productivity |
      | Final 30 days | 90% of standard | 0.9 | Transition period |
    And productivity compliance should track:
      | Tracking Element | Measurement | Adjustment |
      | Learning Curve | Productivity progression | Graduated expectations |
      | Skill Acquisition | Competency development | Skill-based standards |
      | Experience Factor | Tenure-based productivity | Experience weighting |
      | Termination Impact | Departure productivity | Transition accommodation |
    And provide compliance reporting:
      | Report | Content | Use Case |
      | Productivity Progression | Employee development tracking | Performance management |
      | Standard Compliance | Adherence to period-based standards | Quality assurance |
      | Adjustment Analysis | Impact of period adjustments | Standard validation |
      | Comparative Analysis | Period-based vs standard productivity | Fairness assessment |

  @schedule_updates @enhanced_post_save_capabilities
  Scenario: Enhanced Post-Save Schedule Update Capabilities
    Given I have saved work schedules that need modifications
    When I update schedules after initial save
    Then the system should provide comprehensive update capabilities:
      | Update Type | Scope | Impact Assessment | Validation |
      | Individual Changes | Single employee | Minimal disruption | Personal validation |
      | Bulk Updates | Multiple employees | Cascade analysis | Batch validation |
      | Template Changes | All template users | Widespread impact | Template validation |
      | Rule Changes | Rule-affected employees | Compliance check | Rule validation |
      | Time Period Changes | Specific date ranges | Temporal impact | Period validation |
    And update capabilities should include:
      | Capability | Function | Benefit |
      | Impact Preview | Show changes before applying | Risk mitigation |
      | Rollback Option | Revert to previous version | Error recovery |
      | Incremental Updates | Partial schedule modifications | Efficiency |
      | Audit Trail | Track all changes | Accountability |
      | Approval Workflow | Manager review for major changes | Governance |
    And provide update analytics:
      | Analytic | Content | Purpose |
      | Change Frequency | Update rate analysis | Process optimization |
      | Impact Assessment | Change consequence evaluation | Risk management |
      | User Behavior | Update pattern analysis | System improvement |
      | Compliance Tracking | Regulatory adherence | Compliance assurance |

  @schedule_replanning @enhanced_operator_specific_replanning
  Scenario: Enhanced Schedule Replanning for Specific Operators
    Given I need to replan schedules for specific operators
    When I initiate operator-specific replanning
    Then the system should provide targeted replanning capabilities:
      | Replanning Scope | Criteria | Process | Validation |
      | Single Operator | Individual need | Focused replanning | Personal validation |
      | Skill Group | Skill-based replanning | Group optimization | Skill validation |
      | Department | Department-wide changes | Departmental replanning | Department validation |
      | Project Team | Project-specific needs | Team optimization | Project validation |
      | Emergency Group | Crisis response | Rapid replanning | Emergency validation |
    And replanning should consider:
      | Factor | Impact | Handling |
      | Operator Preferences | Personal scheduling preferences | Preference integration |
      | Skill Requirements | Skill-based assignments | Skill matching |
      | Workload Balance | Fair distribution | Load balancing |
      | Coverage Needs | Service level maintenance | Coverage optimization |
      | Regulatory Compliance | Labor law adherence | Compliance checking |
    And provide replanning analytics:
      | Analytic | Content | Purpose |
      | Replanning Frequency | How often replanning occurs | Process efficiency |
      | Success Rate | Replanning effectiveness | Quality measurement |
      | Impact Analysis | Replanning consequences | Decision support |
      | Optimization Metrics | Improvement measurements | Performance tracking |

  @schedule_change_history @enhanced_change_tracking
  Scenario: Enhanced Schedule Change History Tracking
    Given I need comprehensive change tracking for schedules
    When I track schedule changes and modifications
    Then the system should provide detailed change history:
      | Change Element | Tracked Information | Storage | Access |
      | Change Type | What was changed | Database | Admin/Manager |
      | Change User | Who made the change | Audit log | Admin only |
      | Change Time | When change occurred | Timestamp | All users |
      | Change Reason | Why change was made | Comments | All users |
      | Change Impact | What was affected | Analysis | Manager |
    And change tracking should capture:
      | Tracking Item | Content | Purpose |
      | Before/After | Complete state comparison | Change visualization |
      | Cascade Effects | Downstream impacts | Impact assessment |
      | Approval Chain | Authorization trail | Governance tracking |
      | Notification Log | Who was notified | Communication audit |
      | Rollback Points | Restoration capabilities | Error recovery |
    And provide change analytics:
      | Analytic | Content | Use Case |
      | Change Patterns | Frequency and types | Process improvement |
      | User Activity | Who makes what changes | User behavior analysis |
      | Impact Assessment | Change consequences | Risk management |
      | Compliance Audit | Regulatory adherence | Compliance reporting |

  @business_process_stages @enhanced_execution_viewing
  Scenario: Enhanced Business Process Execution Stage Viewing
    Given I have business processes managing schedule workflows
    When I view process execution stages
    Then the system should provide comprehensive stage visualization:
      | Stage Element | Information | Display | Access |
      | Stage Name | Current process stage | Visual indicator | All users |
      | Stage Status | Active/Completed/Pending | Color coding | All users |
      | Stage Progress | Percentage complete | Progress bar | All users |
      | Stage Owner | Responsible person | Name/Role | Manager |
      | Stage Actions | Available actions | Button/Menu | Role-based |
    And stage viewing should include:
      | View Feature | Content | Purpose |
      | Timeline View | Process progression | Temporal understanding |
      | Dependency Map | Stage relationships | Workflow comprehension |
      | Action History | Completed actions | Audit trail |
      | Pending Items | Outstanding tasks | Action planning |
      | Performance Metrics | Stage efficiency | Process optimization |
    And provide stage analytics:
      | Analytic | Content | Use Case |
      | Stage Duration | Time spent per stage | Efficiency analysis |
      | Bottleneck Analysis | Process constraints | Optimization planning |
      | Approval Patterns | Decision-making trends | Process improvement |
      | Success Rates | Stage completion rates | Quality measurement |

  @personal_account_preferences @enhanced_preference_integration
  Scenario: Enhanced Personal Account Preference Integration
    Given I have employee personal account preferences
    When I integrate preferences into schedule planning
    Then the system should provide comprehensive preference handling:
      | Preference Type | Content | Impact | Priority |
      | Shift Preferences | Preferred shift times | Schedule assignment | High |
      | Day Preferences | Preferred work days | Weekly planning | Medium |
      | Skill Preferences | Preferred skill usage | Task assignment | Medium |
      | Vacation Preferences | Preferred vacation periods | Vacation planning | High |
      | Training Preferences | Preferred training times | Development scheduling | Low |
    And preference integration should consider:
      | Factor | Logic | Implementation |
      | Business Needs | Operational requirements | Preference vs need balance |
      | Team Fairness | Equitable preference handling | Fair distribution |
      | Seniority Rules | Preference priority by tenure | Hierarchy respect |
      | Skill Requirements | Skill-based constraints | Competency alignment |
      | Service Levels | Coverage maintenance | Quality assurance |
    And provide preference analytics:
      | Analytic | Content | Purpose |
      | Preference Satisfaction | How well preferences are met | Employee satisfaction |
      | Conflict Resolution | Preference conflicts and solutions | Process improvement |
      | Preference Trends | Changing preference patterns | Trend analysis |
      | Impact Assessment | Preference impact on operations | Business alignment |