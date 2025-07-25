Feature: Reference Data Management and Configuration
  As a system administrator
  I want to configure and maintain reference data
  So that the system operates according to business rules and requirements

  Background:
    Given I have administrator privileges
    And I can access "References" section
    And the system supports comprehensive reference data management

  @references @work_rules_configuration
  Scenario: Configure Work Rules with Rotation Patterns
    Given I navigate to "References" → "Work Rules"
    When I create a comprehensive work rule
    Then I should configure basic parameters:
      | Parameter | Options | Purpose |
      | Rule Name | Text field | Identification |
      | Mode | With rotation / Without rotation | Planning approach |
      | Consider holidays | Yes/No | Holiday handling |
      | Time zone | Time zone list | Scheduling reference |
      | Mandatory shifts by day | Yes/No | Flexibility control |
    And define shift patterns:
      | Shift Configuration | Details | Constraints |
      | Shift types | Morning, Afternoon, Evening, Night | Up to 10 types |
      | Start times | Fixed or range (e.g., 09:00-10:00) | Flexibility options |
      | Duration | Fixed or range (e.g., 7:00-9:00) | Variable length |
      | Break integration | Automatic break scheduling | Compliance rules |
    And set rotation patterns:
      | Pattern Type | Example | Description |
      | Simple rotation | WWWWWRR | 5 work days, 2 rest |
      | Complex rotation | WWRWWRR | Custom pattern |
      | Flexible rotation | Variable based on demand | Demand-driven |
    And configure constraints:
      | Constraint | Rule | Enforcement |
      | Min hours between shifts | 11 hours | Labor law compliance |
      | Max consecutive hours | 40 hours | Fatigue prevention |
      | Max consecutive days | 6 days | Rest requirement |
      | Shift distance rules | Geographic considerations | Travel time |

  @references @event_management
  Scenario: Configure Events and Internal Activities
    Given I navigate to "References" → "Events"
    When I create different types of internal activities
    Then I should be able to configure training events:
      | Training Parameter | Configuration | Example |
      | Event Name | Descriptive title | Weekly English Training |
      | Regularity | Frequency pattern | Once a week |
      | Weekdays | Day selection | Monday, Wednesday |
      | Time interval | Duration window | 14:00-16:00 |
      | Duration | Exact time | 120 minutes |
      | Participation | Group or Individual | Group |
      | Participants | Number range | 5-10 people |
      | Skill requirement | Prerequisites | English Level B1+ |
    And configure meeting activities:
      | Meeting Parameter | Configuration | Purpose |
      | Meeting type | Daily, Weekly, Monthly | Frequency |
      | Mandatory attendance | Yes/No | Requirement level |
      | Combine with others | Yes/No | Conflict handling |
      | Find common time | Automatic scheduling | Optimization |
      | Resource requirements | Room, equipment | Logistics |
    And set up project activities:
      | Project Parameter | Configuration | Impact |
      | Project name | Identification | Customer Survey Q1 |
      | Project mode | Inbound/Outbound priority | Work type |
      | Priority level | 1-100 scale | Resource allocation |
      | Target duration | Per contact time | 5 minutes |
      | Work plan volume | Total scope | 5000 calls |
      | Project period | Start/end dates | Timeline |

  @references @vacation_schemes
  Scenario: Configure Vacation Schemes and Policies
    Given I navigate to "References" → "Vacation Schemes"
    When I create vacation management policies
    Then I should define scheme types:
      | Scheme Type | Configuration | Rules |
      | Standard Annual | 28 calendar days | Must use by December 31 |
      | Senior Employee | 35 calendar days | 7 days carryover allowed |
      | Part-time Employee | Prorated calculation | Based on work percentage |
      | Probationary Period | Reduced entitlement | 14 days maximum |
    And configure vacation rules:
      | Rule Category | Parameter | Value |
      | Minimum vacation block | Consecutive days | 7 days |
      | Maximum vacation block | Continuous period | 28 days |
      | Notice period | Advance request time | 14 days minimum |
      | Approval chain | Routing sequence | Supervisor → HR → Director |
      | Blackout periods | Restricted dates | Dec 15-31, Jun 1-15 |
      | Carryover policy | Year-end handling | Use or lose |
    And set calculation methods:
      | Calculation Type | Method | Application |
      | Calendar days | Fixed period calculation | Includes weekends/holidays |
      | Working days | Business days only | Excludes weekends/holidays |
      | Prorated allocation | Percentage-based | Part-time employees |
      | Accumulation rate | Monthly accrual | 2.33 days per month |

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

  @references @absence_reasons
  Scenario: Configure Absence Reason Categories
    Given I need to categorize different types of employee absences
    When I configure absence reason codes
    Then I should define comprehensive absence categories:
      | Category | Code | Impact on Schedule | Payroll Integration |
      | Sick Leave | SICK | Unplanned replacement | Paid/Unpaid based on policy |
      | Vacation | VAC | Planned coverage | Paid time off |
      | Personal Leave | PTO | Semi-planned coverage | Usually unpaid |
      | Training | TRN | Productive activity | Paid development time |
      | Jury Duty | JURY | Legal obligation | Paid civic duty |
      | Bereavement | BER | Emergency leave | Paid compassionate leave |
      | Medical Appointment | MED | Short absence | Flexible scheduling |
      | Emergency | EMG | Immediate absence | Case-by-case evaluation |
    And configure absence properties:
      | Property | Options | Purpose |
      | Advance notice required | Hours/Days | Planning requirement |
      | Documentation required | Yes/No/Sometimes | Verification needs |
      | Approval level | Supervisor/HR/Director | Authorization level |
      | Maximum duration | Days/Weeks | Policy limits |
      | Frequency limits | Per year/month | Abuse prevention |

  @references @service_groups
  Scenario: Configure Services and Service Groups
    Given I need to organize the contact center structure
    When I configure services and their constituent groups
    Then I should create service hierarchy:
      | Service Level | Name | Purpose |
      | Top Level | Technical Support | Main service category |
      | Group Level | Level 1 Support | First-line assistance |
      | Group Level | Level 2 Support | Escalated technical issues |
      | Group Level | Email Support | Non-voice technical help |
      | Service Level | Sales | Revenue generation |
      | Group Level | Inbound Sales | Inquiry conversion |
      | Group Level | Outbound Sales | Proactive sales |
      | Group Level | Retention Team | Customer retention |
    And configure group properties:
      | Property | Configuration | Impact |
      | Channel type | Voice/Email/Chat | Work type classification |
      | Skill requirements | Competency levels | Agent assignment |
      | Service level targets | 80/20 format definitions | Performance goals |
      | Operating hours | Schedule constraints | Availability windows |
      | Capacity limits | Maximum agents | Resource allocation |

  @references @service_level_configuration @ui_components
  Scenario: Configure 80/20 Format Service Level Settings with UI Components
    Given I need to configure service level targets for contact center operations
    When I navigate to "Configuration" → "Service Level Settings"
    Then I should see the 80/20 format configuration interface with:
      | UI Component | Element Type | Validation Rule | Default Value |
      | Service Level Target | Percentage Input | Range: 70-95% | 80% |
      | Answer Time Target | Seconds Input | Range: 10-60 seconds | 20 seconds |
      | Threshold Warning | Percentage Input | Range: 60-85% | 75% |
      | Threshold Critical | Percentage Input | Range: 50-75% | 65% |
      | Measurement Period | Dropdown | Options: 15min/30min/1hour | 30min |
      | Alert Frequency | Dropdown | Options: Real-time/1min/5min | 1min |
    And the form should include validation components:
      | Validation Component | Rule | Error Message | Field Dependencies |
      | Range Validator | Target ≥ Warning ≥ Critical | "Service level hierarchy must be maintained" | All percentage fields |
      | Minimum Threshold | Answer time ≥ 10 seconds | "Answer time must be at least 10 seconds" | Answer Time Target |
      | Maximum Threshold | Answer time ≤ 60 seconds | "Answer time cannot exceed 60 seconds" | Answer Time Target |
      | Consistency Check | Target + Answer time realistic | "Configuration may be unachievable" | Target + Answer fields |
    And configuration should support group-specific settings:
      | Group Setting | Override Option | Inheritance | Validation |
      | Department Level | Yes | From organization | Department-specific validation |
      | Team Level | Yes | From department | Team-specific validation |
      | Individual Level | No | From team | Read-only inheritance |
    And provide real-time preview:
      | Preview Component | Display | Update Frequency | Purpose |
      | Impact Calculator | Estimated operator requirements | On change | Resource planning |
      | Historical Comparison | Previous vs new settings | On change | Change impact assessment |
      | Achievability Score | Percentage likelihood | On change | Realistic target setting |

  @references @roles_permissions
  Scenario: Configure System Roles and Permissions
    Given I need to manage user access and permissions
    When I create custom business roles
    Then I should configure role hierarchy:
      | Role Category | Role Name | Scope | Permissions |
      | System Roles | Administrator | Global | Full system access |
      | System Roles | Senior Operator | Multi-department | Planning and coordination |
      | System Roles | Operator | Personal | Self-service functions |
      | Business Roles | Regional Manager | Geographic region | Regional operations |
      | Business Roles | Department Head | Department | Team management |
      | Business Roles | Team Lead | Team/Group | Immediate supervision |
    And assign specific permissions:
      | Permission Category | Permission Name | Role Assignment |
      | System Access | System_AccessForecastList | Regional Manager: Yes |
      | System Access | System_EditForecast | Regional Manager: No |
      | Employee Data | System_AccessWorkerList | Regional Manager: Yes |
      | Schedule Management | System_EditSchedule | Team Lead: Limited |
      | Report Access | System_ViewReports | Department Head: Yes |
    And manage role inheritance:
      | Inheritance Rule | Implementation | Benefit |
      | Parent role permissions | Automatic inheritance | Simplified management |
      | Override capabilities | Specific restrictions | Granular control |
      | Time-based permissions | Temporary access | Flexible authorization |

  @references @channels_communication
  Scenario: Configure Communication Channels and Types
    Given I need to define work channel types
    When I configure communication channels
    Then I should define channel categories:
      | Channel Category | Channel Type | Characteristics |
      | Voice Channels | Inbound Calls | Customer-initiated contact |
      | Voice Channels | Outbound Calls | Agent-initiated contact |
      | Digital Channels | Email | Asynchronous communication |
      | Digital Channels | Live Chat | Real-time text interaction |
      | Digital Channels | Social Media | Public interaction |
      | Digital Channels | Video Calls | Enhanced communication |
    And configure channel properties:
      | Property | Configuration | Purpose |
      | Concurrent handling | Single/Multiple | Multitasking capability |
      | Response time 80/20 | Minutes/Hours | Service commitment |
      | Skill requirements | Specialized training | Quality assurance |
      | Priority levels | 1-5 scale | Resource allocation |
      | Escalation paths | Routing rules | Problem resolution |

  @references @calendar_holidays
  Scenario: Configure Production Calendar and Holidays
    Given I need to manage working and non-working days
    When I configure the production calendar
    Then I should import/define holiday data:
      | Holiday Type | Configuration | Impact |
      | National holidays | Fixed dates | Standard non-working days |
      | Religious holidays | Variable dates | Cultural observance |
      | Company holidays | Custom dates | Organization-specific |
      | Regional holidays | Location-based | Geographic variations |
    And configure holiday rules:
      | Holiday Rule | Implementation | Effect |
      | Holiday pay rates | Premium calculation | Compensation adjustment |
      | Work on holidays | Optional/Prohibited | Scheduling constraint |
      | Holiday substitution | Alternate day off | Flexible observance |
      | Pre/post holiday | Adjusted schedules | Operational planning |
    And manage calendar variations:
      | Calendar Feature | Purpose | Application |
      | Multi-year planning | Long-term scheduling | Strategic planning |
      | Regional differences | Local compliance | Geographic operations |
      | Calendar updates | Annual refreshing | Current information |

  @references @planning_criteria
  Scenario: Configure Planning Criteria and Optimization Rules
    Given I need to define planning optimization parameters
    When I configure planning criteria
    Then I should set optimization objectives:
      | Objective Category | Criteria | Weight |
      | Service Level | Maintain 80/20 format | High priority |
      | Cost Efficiency | Minimize overtime | Medium priority |
      | Employee Satisfaction | Honor preferences | Medium priority |
      | Operational Flexibility | Maintain coverage | High priority |
    And configure planning constraints:
      | Constraint Type | Rule | Enforcement |
      | Labor standards | Legal compliance | Mandatory |
      | Budget limits | Cost boundaries | Flexible |
      | Skill requirements | Competency matching | Mandatory |
      | Employee preferences | Personal requests | Best effort |
    And set planning algorithms:
      | Algorithm | Purpose | Parameters |
      | Genetic algorithm | Schedule optimization | Population size, iterations |
      | Linear programming | Resource allocation | Constraints, objectives |
      | Heuristic rules | Fast approximation | Priority weighting |

  @references @absenteeism_tracking @workforce_analytics
  Scenario: Configure Absenteeism Percentage Tracking with Calculation Formulas
    Given I need to track and calculate absenteeism percentages by period
    When I configure absenteeism percentage tracking rules
    Then I should define calculation periods:
      | Period Type | Duration | Calculation Method | Update Frequency |
      | Daily | 1 day | (absent_hours / scheduled_hours) * 100 | Real-time |
      | Weekly | 7 days | (total_absent_hours / total_scheduled_hours) * 100 | End of week |
      | Monthly | Calendar month | (monthly_absent_hours / monthly_scheduled_hours) * 100 | Monthly |
      | Quarterly | 3 months | (quarterly_absent_hours / quarterly_scheduled_hours) * 100 | End of quarter |
    And configure threshold levels:
      | Threshold Type | Percentage Range | Alert Level | Action Required |
      | Normal | 0-5% | None | Monitor only |
      | Warning | 5-10% | Yellow alert | Supervisor notification |
      | Critical | 10-15% | Red alert | HR intervention |
      | Emergency | >15% | Critical alert | Management escalation |
    And set calculation formulas:
      | Formula Component | Calculation | Example | Validation |
      | Absenteeism Rate | (Total Absent Hours / Total Scheduled Hours) * 100 | (8 / 40) * 100 = 20% | Must be 0-100% |
      | Trend Analysis | Current Period - Previous Period | 15% - 12% = +3% increase | Track direction |
      | Department Average | Sum of all employee rates / Employee count | (5% + 10% + 15%) / 3 = 10% | Department benchmark |
      | Seasonal Adjustment | Rate * Seasonal Factor | 10% * 1.2 = 12% | Account for patterns |
    And configure alert automation:
      | Alert Type | Trigger Condition | Recipient | Message Format |
      | Threshold Breach | Rate exceeds threshold | Direct supervisor | "Employee X exceeded Y% absenteeism" |
      | Trend Alert | 3 consecutive increases | Department manager | "Rising absenteeism trend detected" |
      | Department Alert | Department average > 15% | HR director | "Department absenteeism critical" |
      | System Alert | Calculation errors | System administrator | "Absenteeism calculation failed" |

  @references @employment_rates @workforce_planning
  Scenario: Configure Employment Rate by Month for Workforce Planning
    Given I need to configure employment rates by month for workforce planning
    When I configure monthly employment rate settings
    Then I should define rate templates:
      | Template Type | Description | Default Rate | Adjustment Factors |
      | Full-time Standard | Regular full-time employees | 100% | None |
      | Part-time Standard | Regular part-time employees | Variable | Hours-based |
      | Seasonal Workers | Temporary seasonal staff | Variable | Season-based |
      | Contract Workers | External contractors | Variable | Contract-based |
    And configure monthly rate calculations:
      | Calculation Method | Formula | Application | Validation |
      | Simple Rate | (Actual Hours / Standard Hours) * 100 | Basic calculation | 0-200% range |
      | Weighted Average | Sum(Employee Rate * Weight) / Total Weight | Department level | Statistical validity |
      | Seasonal Adjustment | Base Rate * Seasonal Factor | Holiday periods | Realistic adjustments |
      | Forecast Projection | Historical Average + Trend | Future planning | Trend validation |
    And set rate planning rules:
      | Planning Rule | Implementation | Purpose | Constraints |
      | Minimum Rate | Department minimum 80% | Operational capacity | Business requirements |
      | Maximum Rate | Individual maximum 120% | Overtime control | Labor law compliance |
      | Rate Consistency | Month-to-month variance <20% | Stable planning | Reasonable changes |
      | Approval Workflow | Rates >110% require approval | Cost control | Management oversight |
    And configure rate reporting:
      | Report Type | Frequency | Recipients | Content |
      | Monthly Summary | Monthly | Department managers | Rate trends and variances |
      | Quarterly Analysis | Quarterly | HR leadership | Strategic planning data |
      | Annual Review | Yearly | Executive team | Workforce planning metrics |
      | Real-time Dashboard | Live | Operations managers | Current rate monitoring |

  @references @agent_status_types @productivity_tracking
  Scenario: Configure Agent Status Types for Productivity Measurement
    Given I need to configure agent status types for productivity tracking
    When I configure agent status type categories
    Then I should define status classifications:
      | Status Category | Status Examples | Productivity Impact | Reporting Classification |
      | Productive | Available, On Call, After Call Work | Positive | Revenue-generating |
      | Necessary Non-Productive | Break, Lunch, Training | Neutral | Required overhead |
      | Administrative | Meeting, System Issue, Coaching | Neutral | Operational support |
      | Unavailable | Personal, Medical, Emergency | Negative | Unplanned absence |
    And configure status business rules:
      | Business Rule | Implementation | Purpose | Validation |
      | Maximum Duration | Each status has max time limit | Prevent abuse | Time limits enforced |
      | Transition Rules | Valid status change paths | Workflow control | Logic validation |
      | Approval Required | Some statuses need manager approval | Oversight | Authorization check |
      | Auto-Transition | System changes status automatically | Efficiency | Rule-based automation |
    And set productivity calculations:
      | Calculation Type | Formula | Purpose | Reporting |
      | Individual Productivity | (Productive Time / Total Time) * 100 | Agent performance | Daily/weekly reports |
      | Team Productivity | Average of all team members | Team performance | Management dashboard |
      | Department Productivity | Weighted average by department | Department metrics | Monthly analysis |
      | Trend Analysis | Period-over-period comparison | Performance trends | Executive reporting |
    And configure status monitoring:
      | Monitoring Type | Implementation | Alert Conditions | Response Actions |
      | Real-time Status | Live status tracking | Extended non-productive | Supervisor notification |
      | Duration Alerts | Time-based warnings | Status time limits | Automatic reminders |
      | Pattern Detection | Behavior analysis | Unusual patterns | Investigation triggers |
      | Compliance Monitoring | Rule enforcement | Policy violations | Corrective actions |

  @references @integration_mappings
  Scenario: Configure External System Integration Mappings
    Given I need to integrate with external systems
    When I configure data mapping rules
    Then I should define field mappings:
      | External System | External Field | WFM Field | Transformation |
      | HR System | employee_id | PersonnelNumber | Direct mapping |
      | HR System | dept_code | DepartmentId | Lookup table |
      | Contact Center | agent_state | AgentStatus | Status mapping |
      | Payroll System | time_code | PayrollCode | Code translation |
    And configure synchronization rules:
      | Sync Rule | Configuration | Purpose |
      | Sync frequency | Real-time/Hourly/Daily | Update timing |
      | Conflict resolution | Master system priority | Data integrity |
      | Error handling | Retry/Log/Alert | Reliability |
      | Data validation | Format/Range checks | Quality assurance |

  @references @notification_templates
  Scenario: Configure Notification Templates and Delivery
    Given I need to standardize system communications
    When I configure notification templates
    Then I should create template categories:
      | Template Category | Purpose | Delivery Method |
      | Schedule Notifications | Work schedule changes | Email + SMS |
      | Request Notifications | Request status updates | In-app + Email |
      | Alert Notifications | System alerts | SMS + Push |
      | Reminder Notifications | Break/meeting reminders | Push notification |
    And configure template content:
      | Content Element | Configuration | Personalization |
      | Subject line | Dynamic with variables | Employee name, date |
      | Message body | HTML + plain text | Context-specific |
      | Call-to-action | Direct links | Deep linking |
      | Attachments | Optional files | Supporting documents |
    And set delivery rules:
      | Delivery Rule | Configuration | Purpose |
      | Delivery timing | Immediate/Scheduled | Optimal timing |
      | Retry logic | Failed delivery handling | Reliability |
      | Opt-out options | User preferences | Compliance |
      | Tracking | Read receipts | Effectiveness |

  @references @quality_standards
  Scenario: Configure Quality Standards and KPIs
    Given I need to define performance standards
    When I configure quality metrics
    Then I should set performance benchmarks:
      | KPI Category | Metric | Target | Measurement |
      | Productivity | Calls per hour | 15 | Real-time tracking |
      | Quality | Customer satisfaction | 4.2/5.0 | Post-interaction survey |
      | Efficiency | Schedule adherence | 80% | Continuous monitoring |
      | Development | Training completion | 100% | LMS integration |
    And configure measurement rules:
      | Measurement Rule | Implementation | Purpose |
      | Calculation periods | Daily/Weekly/Monthly | Performance cycles |
      | Weighting factors | Importance scaling | Balanced scorecards |
      | Trending analysis | Historical comparison | Improvement tracking |
      | Benchmark updates | Periodic recalibration | Continuous improvement |