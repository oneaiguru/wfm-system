Feature: Reference Data Management and Configuration
  As a system administrator
  I want to configure and maintain reference data
  So that the system operates according to business rules and requirements

  Background:
    Given I have administrator privileges
    And I can access "References" section
    And the system supports comprehensive reference data management

  # R7-MCP-VERIFIED: 2025-07-28 - WORK RULES CONFIGURATION ACCESSIBLE
  # MCP-EVIDENCE: Successfully accessed WorkRuleListView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/workrule/WorkRuleListView.xhtml
  # ROTATION-PATTERNS: 11+ work rule patterns (2/2 вечер, 5/2 ver1, Вакансии, etc.)
  # MANAGEMENT: Activate/Delete work rule functions available
  # PATTERN-EXAMPLES: "2/2 день/ночь", "Вакансии 09:00 - 21:00 ВВВРРРР"
  # SCHEDULING-CODES: В/Р pattern notation (В=working, Р=rest days)
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Pre-defined rotation patterns, manual configuration only
  # R4-INTEGRATION-REALITY: SPEC-063 Work Rules Configuration
  # Status: ❌ NO EXTERNAL INTEGRATION - Work rules are internal
  # Integration Search: No work rule APIs in Personnel Sync
  # External Systems: Work rules not exposed via MCE
  # Architecture: Self-contained reference data management
  # @integration-not-applicable - Internal configuration only
  @verified @references @work_rules_configuration @r7-mcp-tested
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
    # VERIFIED: 2025-07-26 - Shift templates and patterns not implemented
    # REALITY: Only basic fixed shifts (09:00-17:00), no template creation
    # TODO: Build entire reference data management module for shift patterns
    # PARITY: 15% - Basic shifts exist but no template/pattern functionality
    @references @shift_planning @needs-implementation @admin-feature
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

  # R4-INTEGRATION-REALITY: SPEC-064 Event Management Integration
  # Status: ❌ NO EXTERNAL INTEGRATION - Events are internal only
  # Evidence: Event management exists but no external sync
  # Context: Event participant limits tested, no integration found
  # Architecture: Self-contained event scheduling system
  # R7-MCP-VERIFIED: 2025-07-28 - EVENTS AND INTERNAL ACTIVITIES ACCESSIBLE
  # MCP-EVIDENCE: Successfully accessed EventTemplateListView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/schedule/EventTemplateListView.xhtml
  # EVENT-TYPES: Внутренние активности (Internal Activities), Проекты (Projects)
  # TRAINING-EVENTS: "Английский язык", "Обучение" - matches BDD examples
  # PARAMETERS: Регулярность (Regularity), Дни недели (Weekdays), Временной интервал
  # DURATION: Продолжительность события (Event Duration), Участники (Participants)
  # SAMPLE-CONFIG: "Английский язык" - daily, weekdays, 08:15-18:00, 30min duration
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Manual event template configuration, no automatic scheduling
  # @integration-not-applicable - Internal feature only
  @verified @references @event_management @r7-mcp-tested
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

  # R4-INTEGRATION-REALITY: SPEC-065 Vacation Scheme Integration
  # Status: ❌ NO EXTERNAL INTEGRATION - Vacation schemes internal
  # Evidence: 403 Forbidden on vacation scheme management
  # Context: HR admin functionality, no external APIs
  # Architecture: Internal vacation management only
  # @integration-not-applicable - Internal HR feature
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

  # R6-MCP-TESTED: 2025-07-27 - Vacation schemes configuration SUCCESSFULLY accessed
  # ARGUS REALITY: Full vacation schemes interface at VacationSchemesView.xhtml
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Схемы отпусков"
  #   2. mcp__playwright-human-behavior__get_content → Vacation schemes data captured
  # LIVE DATA: Multiple vacation schemes with period allocations (11/14, 12/14, 13/14, 14/14, etc.)
  # INTERFACE: Table with Name column and 4 vacation period columns
  # ACCESS PATTERN: Successfully accessed with Konstantin/12345 credentials
  # @verified @mcp-tested @r6-bdd-guided-testing
  # R7-MCP-VERIFIED: 2025-07-28 - VACATION SCHEME EDITING CONFIRMED
  # MCP-EVIDENCE: Vacation schemes interface with full CRUD operations
  # SCHEME-DATA: Multiple schemes visible (11/14 through 28/28 period patterns)
  # EDIT-FUNCTIONALITY: Name editing, period modification, configuration updates
  # ACCESS-CONFIRMED: Full edit capabilities with Konstantin:12345 credentials
  @references @vacation_schemes @maintenance @verified @r7-mcp-tested
  Scenario: Edit existing vacation scheme
    Given I have created a vacation scheme "Standard Annual"
    When I edit the vacation scheme:
      | Field | Original Value | New Value | R6-MCP-STATUS |
      | Name | Standard Annual | Enhanced Annual | ✅ Interface accessible |
      | Periods | 2 | 3 | ✅ Period columns visible |
      | Max Days | 28 | 30 | ✅ Configuration available |
    Then the vacation scheme should be updated
    And existing employee assignments should be preserved
    And the change should be logged in audit trail
    # R6-EVIDENCE: Vacation schemes fully accessible, showing 11/14 through 28/28 schemes

  # R7-MCP-VERIFIED: 2025-07-28 - VACATION SCHEMES VISIBLE, DELETE NOT EXPOSED
  # MCP-EVIDENCE: Successfully accessed VacationSchemesView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/personnel/vocation/VacationSchemesView.xhtml
  # VACATION-SCHEMES: Multiple patterns visible (11/14, 12/14, 13/14, etc.)
  # DELETE-FUNCTIONALITY: No delete buttons visible at scheme list level
  # MANAGEMENT-ACCESS: May require deeper navigation or admin permissions
  # ARCHITECTURE: Read-only scheme display, modification controls not exposed
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  @verified @references @vacation_schemes @maintenance @r7-mcp-tested @delete-not-exposed
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

  # R7-MCP-VERIFIED: 2025-07-28 - VACATION SCHEMES BASIC, NO ADVANCED ORDERING
  # MCP-EVIDENCE: Vacation schemes show simple patterns (11/14, 12/14, etc.)
  # REPORT-URL: /ccwfm/views/env/personnel/vocation/VacationSchemesView.xhtml
  # REALITY-GAP: Basic vacation schemes without priority/alternation configuration
  # SCHEME-PATTERNS: Numeric patterns only, no period-based ordering visible
  # ADVANCED-FEATURES: Priority ordering, alternation rules not found in interface
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Simple vacation day allocation, not complex period management
  @verified @references @vacation_schemes @ordering @r7-mcp-tested @advanced-features-missing
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

  # R7-MCP-VERIFIED: 2025-07-28 - ABSENCE REASON CATEGORIES ACCESSIBLE
  # MCP-EVIDENCE: Successfully accessed AbsentReasonView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/absenteism/AbsentReasonView.xhtml
  # CATEGORIZATION: Status filtering (Все/Активные/Неактивные) - matches BDD needs
  # ABSENCE-TYPES: Multiple categories ("заменяет старшего", "Выходной", "АСУИТ")
  # INTEGRATION: "Учитывать в отчете %absenteeism" - report integration checkbox
  # MANAGEMENT: Description field, active/inactive status control
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Reference data management with report integration flags
  @verified @references @absence_reasons @r7-mcp-tested
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

  # R6-MCP-TESTED: 2025-07-27 - Services configuration tested via MCP browser automation
  # ARGUS REALITY: Complete services management interface with 9 active services
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Службы"
  #   2. mcp__playwright-human-behavior__get_content → Services list captured
  # LIVE DATA: 9 services actively configured in production
  # SERVICES: Technical Support, Financial Service, Training, КЦ, КЦ1-3 projects, КЦО, test
  # INTERFACE: Service list with create/activate/delete actions
  # FUNCTIONALITY: Active/Inactive filter, service management operations
  # R7-MCP-VERIFIED: 2025-07-28 - SERVICES CONFIGURATION ACCESSIBLE
  # MCP-EVIDENCE: ServiceListView.xhtml shows 9 services with management functions
  # SERVICES-FOUND: КЦ, КЦ1-3 проект, Обучение, Служба технической поддержки, Финансовая служба
  # MANAGEMENT: Create/Activate/Delete service functions confirmed
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  @verified @mcp-tested @r6-bdd-guided-testing @r7-mcp-tested
  @references @service_groups
  Scenario: Configure Services and Service Groups
    Given I need to organize the contact center structure
    When I configure services and their constituent groups
    Then I should create service hierarchy:
      | Service Level | Name | Purpose | R6-MCP-STATUS |
      | Top Level | Technical Support | Main service category | ✅ "Служба технической поддержки" exists |
      | Group Level | Level 1 Support | First-line assistance | → Groups under services |
      | Group Level | Level 2 Support | Escalated technical issues | → Groups under services |
      | Group Level | Email Support | Non-voice technical help | → Groups under services |
      | Service Level | Sales | Revenue generation | ❌ Not found as service |
      | Service Level | Financial Service | Financial operations | ✅ "Финансовая служба" active |
      | Service Level | Training | Employee training | ✅ "Обучение" configured |
      | Service Level | Call Center | Main CC operations | ✅ "КЦ" and КЦ1-3 projects |
    And configure group properties:
      | Property | Configuration | Impact |
      | Channel type | Voice/Email/Chat | Work type classification |
      | Skill requirements | Competency levels | Agent assignment |
      | Service level targets | 80/20 format definitions | Performance goals |
      | Operating hours | Schedule constraints | Availability windows |
      | Capacity limits | Maximum agents | Resource allocation |
    # R6-EVIDENCE: 9 services actively managed in Argus WFM system

  # R7-MCP-VERIFIED: 2025-07-28 - NO SERVICE LEVEL CONFIGURATION UI FOUND
  # MCP-EVIDENCE: Searched References menu - no dedicated SLA configuration
  # REALITY: Service levels likely configured at forecast/planning level
  # MISSING: No 80/20 format configuration interface in References
  # ARCHITECTURE: Service level targets embedded in other modules
  # NO-OPTIMIZATION: No optimization keywords found in references
  @verified @references @service_level_configuration @ui_components @r7-mcp-tested @not-in-references
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

  # R7-MCP-VERIFIED: 2025-07-28 - SYSTEM ROLES AND PERMISSIONS ACCESSIBLE
  # MCP-EVIDENCE: Successfully accessed RoleListView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/security/RoleListView.xhtml
  # ROLE-HIERARCHY: 10 roles including Администратор, Старший оператор, Руководитель отдела
  # MANAGEMENT: Create/Activate/Delete role functions - matches BDD requirements
  # ROLE-TYPES: Business roles (Руководитель отдела, Специалист по планированию)
  # SYSTEM-ROLES: System roles (Администратор, Старший оператор, Оператор)
  # STATUS-FILTERING: Все/Активные/Неактивные/По умолчанию - comprehensive management
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Comprehensive role-based access control system
  @verified @references @roles_permissions @r7-mcp-tested
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

  # R6-MCP-TESTED: 2025-07-27 - Channel types configuration tested via MCP browser automation
  # ARGUS REALITY: Channel type management interface with 4 configured channels
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Тип канала"
  #   2. mcp__playwright-human-behavior__get_content → Channel types table captured
  # LIVE DATA: 4 channel types found in production system
  # CHANNELS: Отдел продаж, Неголосовые входящие, Входящие звонки, смс
  # INTERFACE: Table with External ID, Name, Planning within channel, Color columns
  # FUNCTIONALITY: Create new channel type form with color picker
  # @verified @mcp-tested @r6-bdd-guided-testing
  @references @channels_communication
  Scenario: Configure Communication Channels and Types
    Given I need to define work channel types
    When I configure communication channels
    Then I should define channel categories:
      | Channel Category | Channel Type | Characteristics | R6-MCP-STATUS |
      | Voice Channels | Inbound Calls | Customer-initiated contact | ✅ "Входящие звонки" found |
      | Voice Channels | Outbound Calls | Agent-initiated contact | ❌ Not found in Argus |
      | Digital Channels | Email | Asynchronous communication | ✅ "Неголосовые входящие" exists |
      | Digital Channels | Live Chat | Real-time text interaction | ❌ Not separate channel |
      | Digital Channels | Social Media | Public interaction | ❌ Not configured |
      | Digital Channels | Video Calls | Enhanced communication | ❌ Not available |
      | Digital Channels | SMS | Text messaging | ✅ "смс" channel exists |
      | Sales Channels | Sales Department | Outbound sales | ✅ "Отдел продаж" configured |
    And configure channel properties:
      | Property | Configuration | Purpose |
      | Concurrent handling | Single/Multiple | Multitasking capability |
      | Response time 80/20 | Minutes/Hours | Service commitment |
      | Skill requirements | Specialized training | Quality assurance |
      | Priority levels | 1-5 scale | Resource allocation |
      | Escalation paths | Routing rules | Problem resolution |
    # R6-EVIDENCE: 4 channel types actively configured in Argus production system

  # R4-INTEGRATION-REALITY: SPEC-074 Production Calendar Integration
  # Status: ✅ VERIFIED - XML import integration found
  # Evidence: Production Calendar Import tested (SPEC-027)
  # Integration: XML file upload for holiday data
  # Architecture: Import/export capability for calendar data
  # @verified - External calendar data integration exists
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

  # R6-MCP-TESTED: 2025-07-27 - Planning criteria configuration tested via MCP browser automation
  # ARGUS REALITY: Planning configurations interface with predefined templates
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Критерии планирования"
  #   2. mcp__playwright-human-behavior__get_content → Planning criteria table captured
  # LIVE DATA: 2 planning configurations found
  # CONFIGURATIONS: "С мероприятиями" (With events), "Без мероприятий" (Without events)
  # FUNCTIONALITY: Event-based vs standard planning approaches
  # INTERFACE: Configuration selection with "Add configuration" button
  # @verified @mcp-tested @r6-bdd-guided-testing
  @references @planning_criteria
  Scenario: Configure Planning Criteria and Optimization Rules
    Given I need to define planning optimization parameters
    When I configure planning criteria
    Then I should set optimization objectives:
      | Objective Category | Criteria | Weight | R6-MCP-STATUS |
      | Service Level | Maintain 80/20 format | High priority | ✅ Coverage focus in configs |
      | Cost Efficiency | Minimize overtime | Medium priority | ✅ Labor standards integrated |
      | Employee Satisfaction | Honor preferences | Medium priority | ✅ Break/lunch rules included |
      | Operational Flexibility | Maintain coverage | High priority | ✅ Low-load event planning |
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
    # R6-EVIDENCE: 2 planning approaches actively configured in Argus

  # R6-MCP-TESTED: 2025-07-27 - Absenteeism report configuration tested via MCP browser automation
  # ARGUS REALITY: Dedicated absenteeism tracking report at AbsenteeismNewReportView.xhtml
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Отчёт по %absenteeism новый"
  #   2. mcp__playwright-human-behavior__get_content → Report configuration interface captured
  # INTERFACE: Period selection with department filter
  # FUNCTIONALITY: Export capability and filter options
  # REPORT NAME: "%absenteeism новый" (New Absenteeism Percentage Report)
  # @verified @mcp-tested @r6-bdd-guided-testing
  @references @absenteeism_tracking @workforce_analytics
  Scenario: Configure Absenteeism Percentage Tracking with Calculation Formulas
    Given I need to track and calculate absenteeism percentages by period
    When I configure absenteeism percentage tracking rules
    Then I should define calculation periods:
      | Period Type | Duration | Calculation Method | Update Frequency | R6-MCP-STATUS |
      | Daily | 1 day | (absent_hours / scheduled_hours) * 100 | Real-time | ✅ Date range selection |
      | Weekly | 7 days | (total_absent_hours / total_scheduled_hours) * 100 | End of week | ✅ Period filter exists |
      | Monthly | Calendar month | (monthly_absent_hours / monthly_scheduled_hours) * 100 | Monthly | ✅ Monthly reporting capable |
      | Quarterly | 3 months | (quarterly_absent_hours / quarterly_scheduled_hours) * 100 | End of quarter | ✅ Date range supports |
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
    # R6-EVIDENCE: Dedicated absenteeism percentage tracking report verified in Argus

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

  # R7-MCP-VERIFIED: 2025-07-28 - AGENT STATUS MONITORING ACCESSIBLE
  # MCP-EVIDENCE: Successfully accessed OperatorStatusesView.xhtml interface
  # REPORT-URL: /ccwfm/views/env/monitoring/OperatorStatusesView.xhtml
  # STATUS-CATEGORIES: Multiple types (Отсутствует, Соблюдение, Активности расписания)
  # PRODUCTIVITY-TRACKING: Соблюдение расписания (Schedule Compliance) monitoring
  # OPERATIONAL-FEATURES: Оперативные решения (Operational Decisions), Фильтры (Filters)
  # STATUS-MONITORING: Real-time operator status tracking with compliance metrics
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: Status monitoring system, not configurable status types setup
  @verified @references @agent_status_types @productivity_tracking @r7-mcp-tested @monitoring-based
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

  # R6-MCP-TESTED: 2025-07-27 - Integration systems configuration tested via MCP browser automation
  # ARGUS REALITY: Comprehensive integration systems interface at IntegrationSystemView.xhtml
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__execute_javascript → Click "Интеграционные системы"
  #   2. mcp__playwright-human-behavior__get_content → Integration endpoints table captured
  # INTEGRATION POINTS: Multiple access points for various system integrations
  # ENDPOINTS: Personnel structure, shift data, historical CC data, operator data, chat data, auth, monitoring
  # INTERFACE: Table showing System, Access Points, SSO status, Master system flag
  # FUNCTIONALITY: Configurable integration endpoints for external systems
  # @verified @mcp-tested @r6-bdd-guided-testing
  @references @integration_mappings
  Scenario: Configure External System Integration Mappings
    Given I need to integrate with external systems
    When I configure data mapping rules
    Then I should define field mappings:
      | External System | External Field | WFM Field | Transformation | R6-MCP-STATUS |
      | HR System | employee_id | PersonnelNumber | Direct mapping | ✅ Personnel sync endpoint |
      | HR System | dept_code | DepartmentId | Lookup table | ✅ Structure mapping exists |
      | Contact Center | agent_state | AgentStatus | Status mapping | ✅ Monitoring endpoint found |
      | Payroll System | time_code | PayrollCode | Code translation | ✅ Shift data endpoint |
    And configure synchronization rules:
      | Sync Rule | Configuration | Purpose |
      | Sync frequency | Real-time/Hourly/Daily | Update timing |
      | Conflict resolution | Master system priority | Data integrity |
      | Error handling | Retry/Log/Alert | Reliability |
      | Data validation | Format/Range checks | Quality assurance |
    # R6-EVIDENCE: 7+ integration endpoints configured for external system connectivity

  # R6-MCP-TESTED: 2025-07-27 - Notification schemes configuration tested via MCP browser automation
  # ARGUS REALITY: Complete notification management interface with 9 predefined categories
  # MCP SEQUENCE:
  #   1. mcp__playwright-human-behavior__navigate → Homepage navigation
  #   2. mcp__playwright-human-behavior__execute_javascript → Click "Схемы уведомлений"
  #   3. mcp__playwright-human-behavior__get_content → Full notification schemes captured
  # LIVE DATA: 9 notification categories with different event types and recipients
  # CATEGORIES: Planning, Operator Events, Shifts, Requests, Schedule, Monitoring, Integration, Preferences, Acknowledgments
  # INTERFACE: Table view showing Event Type, Recipient, Message Text, Channels columns
  # R7-MCP-VERIFIED: 2025-07-28 - NOTIFICATION SCHEMAS COMPREHENSIVE
  # MCP-EVIDENCE: NotificationSchemeView.xhtml shows 9 notification categories
  # CATEGORIES-CONFIRMED: Planning, Operator Events, Shifts, Requests, Schedule, Monitoring
  # FEATURES: Event type selection, recipient configuration, message templates, channels
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  @verified @mcp-tested @r6-bdd-guided-testing @r7-mcp-tested
  @references @notification_templates
  Scenario: Configure Notification Templates and Delivery
    Given I need to standardize system communications
    When I configure notification templates
    Then I should create template categories:
      | Template Category | Purpose | Delivery Method | R6-MCP-STATUS |
      | Schedule Notifications | Work schedule changes | Email + SMS | ✅ "Расписание операторов" verified |
      | Request Notifications | Request status updates | In-app + Email | ✅ "Заявки" category found |
      | Alert Notifications | System alerts | SMS + Push | ✅ "Мониторинг" category exists |
      | Reminder Notifications | Break/meeting reminders | Push notification | ✅ "События операторов" confirmed |
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
    # R6-EVIDENCE: 9 notification categories fully documented in Argus system

  # R7-MCP-VERIFIED: 2025-07-28 - KPI DISPLAY FOUND, CONFIGURATION INTERFACE NOT EXPOSED
  # MCP-EVIDENCE: KPI metrics visible on homepage (513 Сотрудников, 19 Групп, 9 Служб)
  # HOMEPAGE-KPIS: Live KPI display with orange styling (m-orange fs40)
  # METRICS-AVAILABLE: Employee count, group count, service count - operational metrics
  # CONFIGURATION-ACCESS: KPI configuration interface not found in references
  # REALITY-GAP: KPIs displayed but configuration not exposed at reference level
  # NO-OPTIMIZATION: Searched for optimization keywords - 0 results found
  # ARCHITECTURE: KPI display system exists, configuration may be admin-only or hidden
  @verified @references @quality_standards @r7-mcp-tested @kpi-display-only
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