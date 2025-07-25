Feature: Monthly Intraday Activity Planning and Timetable Management
  As a planning specialist
  I want to create detailed daily timetables with optimal break placement and activity scheduling
  So that operational efficiency is maximized while maintaining 80/20 format service levels

  Background:
    Given I am logged in as a planning specialist
    And work schedules are applied and active
    And forecast data is available for the planning period
    And multi-skill templates are configured

  @notifications @event_schedule_notifications
  Scenario: Configure Event and Schedule Notifications
    Given I am setting up notifications for events and schedules
    When I configure notification settings:
      | Event Type | Recipients | Notification Method | Timing |
      | Break Reminder | Individual Employee | System + Mobile | 5 minutes before |
      | Lunch Reminder | Individual Employee | System + Mobile | 10 minutes before |
      | Meeting Reminder | Participants | Email + System | 15 minutes before |
      | Training Start | Trainees + Instructor | System notification | 30 minutes before |
      | Schedule Change | Affected Employees | Email + System | Immediate |
      | Shift Start | Individual Employee | Mobile push | 30 minutes before |
    Then notification preferences should be saved per event type
    And employees should receive timely reminders
    And notification history should be tracked for compliance

  @notifications @system_notifications
  Scenario: Configure System-Wide Notification Settings
    Given I am logged in as an administrator
    And I navigate to system notification configuration
    When I configure global notification parameters:
      | Setting | Value | Purpose |
      | Email Server | smtp.company.com | Email delivery |
      | SMS Gateway | provider.sms.com | SMS notifications |
      | Mobile Push | Firebase FCM | Mobile alerts |
      | Notification Retention | 30 days | History keeping |
      | Escalation Rules | 3 attempts | Delivery assurance |
      | Quiet Hours | 22:00-08:00 | Respect personal time |
    Then notification infrastructure should be properly configured
    And delivery methods should be tested and verified
    And escalation procedures should activate for failed deliveries

  @absence_reasons @absence_configuration
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

  @timetable_creation @detailed_scheduling
  Scenario: Create Detailed Daily Timetables from Work Schedule
    Given an applied work schedule exists for the planning period
    And forecast data is available for workload analysis
    When I create a timetable for the period:
      | Parameter | Value |
      | Period | 01.01.2025-07.01.2025 |
      | Template | Technical Support Teams |
      | Planning Criteria | 80/20 format (80% calls in 20 seconds) |
      | Break Optimization | Enabled |
      | Lunch Scheduling | Automated |
    Then the system should generate detailed timetables with:
      | Component | Optimization Rule |
      | Work shares | Distribute based on load forecast |
      | Break placement | Optimize for coverage gaps |
      | Lunch scheduling | Maintain 80/20 format targets |
      | Activity assignments | Balance workload across team |
    And timetables should respect all configured break rules

  @timetable_creation @multiskill_optimization
  Scenario: Handle Multi-skill Operator Timetable Planning
    Given operators have multiple skill certifications
    When the system creates timetables for multi-skill operators:
      | Operator | Primary Skill | Secondary Skills | Load Distribution |
      | Иванов И.И. | Level 1 Support | Email, Sales | 70%, 20%, 10% |
      | Петров П.П. | Level 2 Support | Level 1, Training | 60%, 30%, 10% |
      | Сидорова А.А. | Email Support | Level 1, Quality | 50%, 40%, 10% |
    Then the system should assign operators based on priority:
      | Priority | Assignment Rule |
      | 1 | Mono-skill operators to primary channels |
      | 2 | Multi-skill operators to primary skills |
      | 3 | Multi-skill operators to secondary skills |
      | 4 | Overflow assignments as needed |
    And maintain skill proficiency requirements across assignments

  @timetable_manual_edits @real_time_adjustments
  Scenario: Make Manual Timetable Adjustments
    Given a timetable is generated and active
    When I need to make manual adjustments:
      | Adjustment Type | Action | Validation Required |
      | Add work attendance | Select interval + "Add work attendance" | Check minimum coverage |
      | Mark downtime | Select interval + "Does not accept calls" | Verify service impact |
      | Assign to project | Select interval + "Assign to project" | Confirm project allocation |
      | Add lunch break | Select interval + "Add Lunch" | Check lunch rules compliance |
      | Add short break | Select interval + "Add Break" | Verify break spacing |
      | Cancel breaks | Select interval + "Cancel Breaks" | Ensure adequate rest |
      | Schedule event | Select interval + "Event" | Check availability conflict |
    Then changes should be applied immediately to the active timetable
    And affected operators should receive notifications of changes
    And 80/20 format service level impact should be calculated and displayed

  @event_management @training_events
  Scenario: Schedule Training and Development Events
    Given I need to schedule regular training sessions
    When I create training events:
      | Event Type | Details | Scheduling Rules |
      | Weekly English Training | Duration: 120 min, Participants: 5-10 | Monday, Wednesday 14:00-16:00 |
      | Daily Team Sync | Duration: 30 min, Participants: All team | Every day 09:00-09:30 |
      | Monthly Quality Review | Duration: 60 min, Participants: 15-20 | First Monday of month |
      | Skills Assessment | Duration: 90 min, Participants: Individual | By appointment |
    And I configure event parameters:
      | Parameter | Value | Purpose |
      | Regularity | Weekly/Daily/Monthly | Recurring pattern |
      | Group/Individual | Group assignment | Participation type |
      | Combine with others | No for meetings | Prevent conflicts |
      | Find common time | Yes for training | Optimize attendance |
    Then events should be automatically scheduled in available time slots
    And participants should receive calendar invitations
    And timetables should reserve time for mandatory events

  @project_assignments @outbound_projects
  Scenario: Configure and Assign Outbound Projects
    Given I need to allocate operators to special projects
    When I create outbound projects:
      | Project Name | Type | Priority | Duration | Work Plan |
      | Customer Survey Q1 | Outbound calls | 80% | 5 min/call | 5000 calls |
      | Sales Follow-up | Warm leads | 90% | 8 min/call | 2000 calls |
      | Win-back Campaign | Retention | 70% | 10 min/call | 1500 calls |
    And I configure project parameters:
      | Parameter | Value | Impact |
      | Project period | 01.01.2025-31.03.2025 | Duration limit |
      | Operator allocation | 20% of team capacity | Resource dedication |
      | Performance target | Calls per hour | Productivity measure |
      | Quality requirements | 80% accuracy | Service standard |
    Then projects should affect load distribution planning
    And operators should be assignable based on skills and availability

  @timetable_statistics @coverage_analysis
  Scenario: Analyze Timetable Coverage and Statistics
    Given timetables are generated for the planning period
    When I review timetable statistics and coverage:
      | Metric | Visualization | Analysis |
      | Forecast vs Planned | Color-coded intervals | Green: optimal, Red: shortage, Grey: surplus |
      | Coverage gaps | Red highlighting | Times with insufficient staffing |
      | Service level projection | Percentage display | Expected SL achievement |
      | Break distribution | Timeline view | Even distribution verification |
      | Utilization rate | Percentage by operator | Individual productivity tracking |
    Then statistics should provide insights for optimization
    And highlight periods requiring attention or adjustment
    And support decision-making for resource allocation

  @timetable_integration @schedule_coordination
  Scenario: Integrate Timetables with Work Schedule Changes
    Given active timetables exist for current operations
    When work schedule changes are made:
      | Change Type | Timetable Impact | Required Action |
      | Shift extension | Extend timetable blocks | Recalculate breaks |
      | Shift reduction | Truncate timetable | Reassign activities |
      | Operator absence | Remove from timetable | Find replacement |
      | New operator added | Create timetable blocks | Assign activities |
      | Skill change | Modify assignments | Redistribute work |
    Then timetables should automatically adjust to schedule changes
    And maintain optimal coverage throughout the adjustment period
    And preserve 80/20 format service level targets during transitions

  @real_time_updates @dynamic_adjustments
  Scenario: Handle Real-time Timetable Updates
    Given timetables are active for current operations
    When real-time adjustments are needed:
      | Trigger | Required Response | System Action |
      | Higher than expected volume | Add overtime/call operators | Extend timetables |
      | Lower than expected volume | Send operators home early | Reduce timetables |
      | System outage | Redirect to backup channels | Modify assignments |
      | Skill shortage | Reassign multi-skill operators | Update work allocation |
      | Emergency situation | Prioritize critical functions | Reallocate resources |
    Then timetable updates should be implemented immediately
    And affected operators should be notified of changes
    And service continuity should be maintained throughout adjustments

  @cost_calculation @resource_optimization
  Scenario: Calculate Timetable Costs and Resource Optimization
    Given detailed timetables with all activities assigned
    When I analyze timetable costs and resource utilization:
      | Cost Component | Calculation Method | Optimization Opportunity |
      | Regular hours | Standard rate × scheduled hours | Minimize overstaffing |
      | Overtime hours | Overtime rate × excess hours | Reduce premium costs |
      | Break time | Paid break minutes | Optimize break placement |
      | Training time | Training rate × development hours | Maximize training ROI |
      | Project time | Project rate × allocated hours | Ensure project profitability |
    Then cost analysis should identify optimization opportunities
    And provide recommendations for more efficient resource allocation
    And support budget planning and cost control initiatives

  @compliance_monitoring @timetable_validation
  Scenario: Monitor Timetable Compliance with Labor Standards
    Given timetables are created with labor standard requirements
    When I validate timetable compliance:
      | Compliance Check | Standard | Validation |
      | Rest periods | 11 hours between shifts | Automated checking |
      | Daily work limits | 8 hours standard, 12 max | Real-time validation |
      | Weekly work limits | 40 hours standard, 48 max | Weekly aggregation |
      | Break requirements | 15 min per 2 hours worked | Break rule enforcement |
      | Lunch requirements | 30-60 min for 6+ hour shifts | Lunch scheduling validation |
    Then compliance violations should be flagged immediately
    And supervisors should be notified of potential issues
    And corrective actions should be suggested automatically

  @statistics @enhanced_working_days_calculation
  Scenario: Enhanced Working Days Count Display and Calculation
    Given I am viewing employee schedules and statistics
    When I calculate working days for different periods
    Then the system should provide detailed working days calculations:
      | Period | Calculation Method | Display Format | Business Logic |
      | Daily | Single day status | 1 or 0 | Work day vs non-work day |
      | Weekly | Sum of work days in week | 5 days | Monday-Friday standard |
      | Monthly | Sum of work days in month | 22 days | Exclude weekends and holidays |
      | Yearly | Sum of work days in year | 250 days | Annual working days |
      | Custom Period | Sum for date range | Variable | User-defined period |
    And working days calculation should consider:
      | Factor | Impact | Calculation |
      | Weekends | Exclude Saturday/Sunday | Not counted |
      | Holidays | Exclude public holidays | Production calendar |
      | Vacation | Exclude vacation days | Personal time off |
      | Sick Leave | Exclude sick days | Unplanned absences |
      | Training | Count as working days | Productive time |
    And provide working days statistics:
      | Statistic | Formula | Purpose |
      | Scheduled Days | Total planned work days | Baseline calculation |
      | Actual Days | Days actually worked | Performance tracking |
      | Absence Days | Scheduled - Actual | Absence analysis |
      | Utilization Rate | Actual / Scheduled * 100 | Efficiency measure |

  @statistics @enhanced_planned_hours_calculation
  Scenario: Enhanced Planned Hours Calculation Excluding Breaks
    Given I am calculating planned work hours for employees
    When I compute planned hours excluding breaks
    Then the system should apply detailed hour calculations:
      | Hour Type | Calculation Method | Break Handling | Example |
      | Gross Hours | End time - Start time | Includes all time | 8.0 hours |
      | Break Hours | Sum of all breaks | Lunch + short breaks | 1.0 hours |
      | Net Hours | Gross - Break hours | Excludes breaks | 7.0 hours |
      | Paid Hours | Net + paid break time | Includes paid breaks | 7.25 hours |
      | Productive Hours | Net - downtime | Actual work time | 6.5 hours |
    And break calculation should consider:
      | Break Type | Duration | Paid Status | Impact |
      | Lunch Break | 30-60 minutes | Unpaid | Reduce net hours |
      | Short Break | 15 minutes | Paid | Maintain net hours |
      | Rest Break | 10 minutes | Paid | Maintain net hours |
      | Technical Break | Variable | Unpaid | Reduce net hours |
    And provide hour breakdowns:
      | Breakdown | Content | Display |
      | Scheduled Hours | Planned work time | 8.00 hours |
      | Break Deduction | Total break time | -1.00 hours |
      | Net Work Hours | Actual work time | 7.00 hours |
      | Overtime Hours | Hours over standard | +1.50 hours |
      | Total Paid Hours | Complete compensation | 8.50 hours |

  @statistics @enhanced_overtime_detection
  Scenario: Enhanced Overtime Hours Detection and Display
    Given I am monitoring employee work hours
    When I detect and calculate overtime hours
    Then the system should provide comprehensive overtime analysis:
      | Overtime Type | Trigger | Calculation | Rate |
      | Daily Overtime | >8 hours per day | Hours over 8 | 1.5x |
      | Weekly Overtime | >40 hours per week | Hours over 40 | 1.5x |
      | Holiday Overtime | Work on holidays | All holiday hours | 2.0x |
      | Weekend Overtime | Work on weekends | Weekend hours | 1.5x |
      | Emergency Overtime | Unscheduled work | Emergency hours | 2.0x |
    And overtime detection should consider:
      | Factor | Logic | Impact |
      | Meal Breaks | Unpaid break time | Exclude from overtime |
      | Shift Differential | Night/weekend shifts | Additional calculation |
      | Comp Time | Time off in lieu | Alternative to overtime pay |
      | Overtime Authorization | Manager approval | Compliance validation |
    And provide overtime analytics:
      | Analytic | Content | Purpose |
      | Overtime Trend | Historical overtime patterns | Forecasting |
      | Cost Analysis | Overtime cost vs regular | Budget planning |
      | Distribution | Overtime across employees | Fairness analysis |
      | Compliance | Labor law adherence | Legal compliance |

  @statistics @enhanced_coverage_analysis
  Scenario: Enhanced Coverage Analysis and Statistics
    Given I have timetables and coverage requirements
    When I analyze coverage statistics
    Then the system should provide detailed coverage metrics:
      | Coverage Metric | Calculation | Target | Status |
      | Operator Coverage | Scheduled / Required | 100% | Green/Yellow/Red |
      | Skill Coverage | Skilled operators / Skill requirement | 100% | Coverage by skill |
      | Time Coverage | Covered intervals / Total intervals | 100% | Temporal coverage |
      | Service Level | Calls answered within SLA / Total calls | 80% | Performance metric |
      | Utilization | Productive time / Scheduled time | 85% | Efficiency measure |
    And coverage analysis should show:
      | Analysis Type | Content | Visualization |
      | Hourly Coverage | Coverage by hour of day | Bar chart |
      | Daily Coverage | Coverage by day of week | Line graph |
      | Skill Coverage | Coverage by skill type | Pie chart |
      | Department Coverage | Coverage by department | Heat map |
    And provide coverage recommendations:
      | Recommendation | Trigger | Action |
      | Increase Staffing | Coverage < 90% | Add operators |
      | Redistribute Hours | Uneven coverage | Rebalance schedules |
      | Skill Training | Skill gap identified | Cross-train operators |
      | Schedule Adjustment | Poor time coverage | Modify shift times |

  @statistics @enhanced_utilization_tracking
  Scenario: Enhanced Individual Utilization Rate Tracking
    Given I am tracking individual operator performance
    When I calculate utilization rates
    Then the system should provide comprehensive utilization metrics:
      | Utilization Type | Calculation | Target | Interpretation |
      | Time Utilization | Productive time / Scheduled time | 85% | How well time is used |
      | Task Utilization | Completed tasks / Assigned tasks | 100% | Task completion rate |
      | Skill Utilization | Skilled work / Total work | 80% | Skill application rate |
      | Capacity Utilization | Actual output / Maximum capacity | 90% | Productivity measure |
    And utilization tracking should consider:
      | Factor | Impact | Adjustment |
      | Training Time | Productive but different | Count as utilized |
      | System Downtime | Not operator fault | Exclude from calculation |
      | Break Time | Necessary rest | Exclude from productive time |
      | Overtime | Extra capacity | Include in calculations |
    And provide utilization analytics:
      | Analytic | Content | Use Case |
      | Trend Analysis | Utilization over time | Performance tracking |
      | Comparison | Individual vs team average | Benchmarking |
      | Correlation | Utilization vs other metrics | Root cause analysis |
      | Improvement | Utilization optimization suggestions | Performance enhancement |

  @statistics @enhanced_absence_tracking
  Scenario: Enhanced Absence Rate Calculation and Analysis
    Given I am tracking employee absences
    When I calculate absence rates and patterns
    Then the system should provide detailed absence analytics:
      | Absence Metric | Calculation | Period | Benchmark |
      | Absence Rate | Absent days / Scheduled days * 100 | Monthly | <5% |
      | Unplanned Absence | Unplanned absences / Total absences * 100 | Monthly | <30% |
      | Sick Leave Rate | Sick days / Scheduled days * 100 | Yearly | <3% |
      | Vacation Usage | Vacation days used / Allocated * 100 | Yearly | 90-100% |
      | FMLA Usage | FMLA days / Eligible days * 100 | Yearly | Variable |
    And absence tracking should categorize:
      | Absence Type | Impact | Tracking |
      | Planned Vacation | Scheduled coverage | Advance planning |
      | Sick Leave | Immediate replacement | Real-time adjustment |
      | Personal Time | Short notice | Coverage verification |
      | FMLA | Extended absence | Long-term planning |
      | Emergency Leave | Unplanned absence | Crisis management |
    And provide absence insights:
      | Insight | Content | Action |
      | Absence Patterns | Trends and seasonality | Predictive planning |
      | High Absence Employees | Individuals with high rates | Intervention planning |
      | Department Trends | Absence by department | Targeted solutions |
      | Cost Analysis | Financial impact | Budget planning |

  @statistics @enhanced_productivity_metrics
  Scenario: Enhanced Productivity Standard Tracking and Analysis
    Given I have productivity standards and actual performance data
    When I analyze productivity metrics
    Then the system should provide comprehensive productivity analysis:
      | Productivity Metric | Calculation | Target | Performance Indicator |
      | Calls per Hour | Total calls / Total hours | 15 | Efficiency measure |
      | Average Handle Time | Total talk time / Total calls | 5 minutes | Service quality |
      | First Call Resolution | Resolved calls / Total calls * 100 | 80% | Quality metric |
      | Occupancy Rate | Talk time / Available time * 100 | 85% | Utilization measure |
      | Quality Score | Quality points / Total evaluations | 90% | Service standard |
    And productivity tracking should consider:
      | Factor | Impact | Adjustment |
      | New Employee Ramp-up | Lower initial productivity | Graduated standards |
      | Skill Level | Different productivity by skill | Skill-based targets |
      | Channel Type | Email vs phone productivity | Channel-specific metrics |
      | Complexity | Complex cases take longer | Complexity weighting |
    And provide productivity insights:
      | Insight | Content | Use Case |
      | Performance Trends | Productivity over time | Improvement tracking |
      | Benchmark Comparison | Individual vs team standards | Performance review |
      | Correlation Analysis | Productivity vs other factors | Root cause analysis |
      | Improvement Recommendations | Specific enhancement suggestions | Performance coaching |