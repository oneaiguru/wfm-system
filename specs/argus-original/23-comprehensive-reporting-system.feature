Feature: Comprehensive Reporting System - Complete Enterprise Reporting Coverage
  As a system administrator, manager, and business analyst
  I want to access comprehensive reporting capabilities with a flexible report editor
  So that I can generate insights from workforce data and monitor organizational performance

  Background:
    Given the ARGUS WFM reporting system is fully operational
    And I have appropriate permissions for report access
    And the report editor infrastructure is configured
    And data sources are integrated from personnel, call center, and planning systems
    And PostgreSQL 10.x database contains current and historical data

  # ============================================================================
  # REPORT EDITOR INFRASTRUCTURE - CORE FUNCTIONALITY
  # ============================================================================

  @report_editor @infrastructure
  Scenario: Configure Report Editor with Required Components
    Given I am logged in as a system administrator
    And I navigate to the report editor configuration
    When I set up the report editor infrastructure
    Then the system should provide the following editor blocks:
      | Block | Description |
      | List of reports | Searchable report catalog |
      | General information | Name, description, status (published/blocked) |
      | Query data | SQL or GROOVY query builder |
      | Input parameters | Parameter configuration |
      | Export templates | Output format templates |
    And I should be able to specify data source methods:
      | Method | Purpose |
      | SQL | Direct database queries |
      | GROOVY | Programmatic data processing |

  @report_editor @parameters
  Scenario: Configure Report Input Parameters with All Supported Types
    Given I am creating a new report in the editor
    When I configure input parameters
    Then I should be able to create parameters with these types:
      | Parameter Type | Example | Validation |
      | date | Start date, End date | Valid date format |
      | numeric (fractional) | Percentage threshold | Decimal numbers |
      | numeric (integer) | Employee count | Whole numbers |
      | logical | Include inactive employees | Boolean true/false |
      | text | Employee name filter | String values |
      | query result | Department dropdown | SQL result set |
    And I should be able to specify parameter requirements:
      | Requirement | Options |
      | mandatory | Required field |
      | optional | Can be left blank |

  @report_editor @export_templates
  Scenario: Configure Export Templates for Multiple Output Formats
    Given I have a report with configured data and parameters
    When I set up export templates
    Then I should be able to upload templates in these formats:
      | Format | Use Case | Features |
      | xlsx | Excel spreadsheets | Formulas and formatting |
      | docx | Word documents | Rich text formatting |
      | html | Web display | Interactive elements |
      | xslm | Excel with macros | Advanced automation |
      | pdf | Print-ready documents | Fixed layout |
    And I should be able to load multiple output templates for one report

  # ============================================================================
  # OPERATIONAL REPORTS - LOGIN, SCHEDULE, PERFORMANCE
  # ============================================================================

  @operational_reports @login_logout
  Scenario: Generate Actual Operator Login/Logout Report
    Given I navigate to the reports section
    And I select "Actual Operator Login/Logout Report"
    When I configure the report parameters:
      | Parameter | Value | Required |
      | Date from | 01.01.2025 | Yes |
      | Date to | 31.01.2025 | Yes |
      | Direction/Group | All employees | Yes |
      | Operator name | Any | Yes |
      | House/Office | All types | Yes |
    And I generate the report
    Then the report should display login and logout information:
      | Field | Description |
      | Date | Date for which information is displayed |
      | Direction | Name of direction employee belongs to |
      | Leader's group | Manager's group name |
      | Full name | Complete employee name |
      | System | Name of logged in/out system |
      | Login time | Employee login timestamp |
      | Time of exit | Employee logout timestamp |
    And the report should show all employee entries and exits for the selected period

  @operational_reports @schedule_adherence
  Scenario: Generate Keeping to the Schedule Report
    Given I need to view planned and actual employee break times
    When I configure the schedule adherence report with parameters:
      | Parameter | Value | Required |
      | Period | 06.09.2025 to 07.09.2025 | Yes |
      | Detailing | 5 minutes | Yes |
      | Groups | Call center groups | No |
      | Full name | Selected employees | Yes |
      | Type | Office and home | No |
    And I generate the keeping to schedule report
    Then the report should show for each employee:
      | Field | Description |
      | Full name | Employee identification |
      | AVG-SH-ADH | Average punctuality rate for period |
      | %SH-ADH | Employee punctuality percentage |
      | Schedule | Planned employee schedule |
      | Fact | Actual employee time by statuses |
    And the report generation period should respect detailing constraints:
      | Detailing | Maximum Period |
      | 1 minute | 1 day |
      | 5 minutes | 1 day |
      | 15 minutes | 1 month |
      | 30 minutes | 1 month |

  @operational_reports @lateness
  Scenario: Generate Employee Lateness Report
    Given I want to view employee lateness patterns
    When I configure the lateness report:
      | Parameter | Value | Required |
      | Period | 01.09.2025 to 30.09.2025 | Yes |
      | Subdivision | Department filtering | No |
      | Full name | All employees | Yes |
      | Type | Office and home | No |
      | Late from | 10 minutes | Yes |
      | Late to | 60 minutes | Yes |
    And I generate the lateness report
    Then the system should calculate lateness as excess of actual login time over planned shift start
    And the report should handle these scenarios:
      | Scenario | Calculation Method |
      | Day off registered | Count from shift beginning |
      | Sick leave registered | Count from end of sick leave |
      | No login during shift | Not displayed in report |
      | Event without login | Not displayed in report |
    And the report should contain summary information by areas and manager groups

  @operational_reports @absenteeism
  Scenario: Generate %Absenteeism Report (NEW)
    Given I need to view planned and unscheduled employee absenteeism
    When I configure the absenteeism report:
      | Parameter | Value | Required |
      | Period | Q1 2025 | Yes |
      | Subdivision | All directions and manager groups | Yes |
    And I generate the absenteeism report
    Then the system should calculate absenteeism using exact formulas:
      | Calculation Type | Formula | Purpose |
      | Unscheduled absenteeism | (sick leave + time off + unscheduled vacation) / scheduled shift × 100 | Track unexpected absences |
      | Planned absenteeism | planned leave duration / scheduled shift × 100 | Track scheduled absences |
    And absenteeism should be displayed with two decimal places
    And the report should include summary information for month/quarter/year
    And zero values should be displayed in the report

  # ============================================================================
  # PERSONNEL REPORTS - EMPLOYEE DATA, VACATIONS, CHANGES
  # ============================================================================

  @personnel_reports @employee_data
  Scenario: Generate Report on Existing Employees
    Given I need comprehensive employee information
    When I generate the existing employees report with parameters:
      | Parameter | Value | Required |
      | Fired from | 01.01.2024 | Yes |
      | Direction/Group | All employees | Yes |
      | Operator details | All employees | Yes |
      | House/Office | All types | Yes |
    And I generate the report for current date
    Then the report should display both currently employed and dismissed employees
    And the first tab should show detailed employee information:
      | Field | Description |
      | Direction | Employee's direction |
      | Leader's group | Manager's group |
      | Operator ID | Unique employee identifier |
      | Personnel number | Employee ID number |
      | Full name | Complete employee name |
      | Job title | Current position |
      | Date of employment | Hiring date if completed |
      | Status | Working/not working/vacation/sick leave/time off |
      | Date status | Last event timestamp |
    And the second tab should show summary by direction/manager group:
      | Summary Field | Description |
      | Number of operators on leave | Time off event count |
      | Number of operators on vacation | Vacation event count |
      | Number of operators on sick leave | Sick leave event count |
      | Number of working operators | Active without special status |

  @personnel_reports @vacation_management
  Scenario: Generate Vacation Report with Summary
    Given I need to view employee vacation percentages
    When I configure the vacation report:
      | Parameter | Value | Required |
      | Date from | 01.01.2025 | Yes |
      | Date to | 31.12.2025 | Yes |
      | Direction/Group | All employees | Yes |
      | House/Office | All types | Yes |
    And I generate the vacation summary report
    Then the report should contain summary information for day/week/month/quarter/year
    And the report should show vacation data by CC/direction/manager group
    And vacation calculations should follow these rules:
      | Field | Calculation |
      | Working shifts | Employees with scheduled shifts (including vacation) |
      | Of which on vacation | Employees with planned/unscheduled vacation on selected date |
      | Percent | (Number in work / Number of work shifts) × 100 |
      | Operators on vacation | Full names of employees with planned vacation |

  @personnel_reports @vacation_upload
  Scenario: Generate Uploading Vacations Report
    Given I need to download planned vacation data
    When I configure the vacation upload report:
      | Parameter | Value | Required |
      | Direction | All employees | No |
      | Date from | 01.06.2025 | Yes |
      | Date to | 31.08.2025 | Yes |
    And I generate the vacation upload report
    Then the report should contain only planned vacation information
    And the report should display vacations with start or end dates in specified period
    And each vacation entry should show:
      | Field | Description |
      | Employee | Full employee name |
      | Type of leave | Basic vacation type |
      | start date | Vacation start date |
      | End date | Vacation end date |

  @personnel_reports @job_changes
  Scenario: Generate Job Change Report
    Given I need to track employee position transfers
    When I configure the job change report:
      | Parameter | Value | Required |
      | Surname(s) | All employees | Yes |
      | Beginning of period | 01.01.2025 | Yes |
      | End of period | 31.12.2025 | Yes |
    And I generate the job change report
    Then the report should display history of job changes from 1C system
    And each change should include:
      | Field | Description |
      | Employee | Full employee name |
      | New position | Position transferred to |
      | Date of translation | Date of position transfer |

  @personnel_reports @skill_changes
  Scenario: Generate Skill Change Report
    Given I need to track employee group membership changes
    When I configure the skill change report:
      | Parameter | Value | Required |
      | Surname(s) | All employees | Yes |
      | Beginning of period | 01.01.2025 | Yes |
      | End of period | 31.12.2025 | Yes |
    And I generate the skill change report
    Then the report should show history of group composition changes from:
      | Source | Change Type |
      | Central control center synchronization | Automatic updates |
      | Manual addition/exclusion | Manual changes |
    And each change should include:
      | Field | Description |
      | Employee | Full employee name |
      | Date changes | Change timestamp |
      | Type of change | Removed from group or Added to group |
      | Group name | Group added/removed |
      | Initiator of change | Employee or web service name |

  # ============================================================================
  # PERFORMANCE REPORTS - AHT, READY, LOAD ANALYSIS
  # ============================================================================

  @performance_reports @aht_analysis
  Scenario: Generate AHT Report with Multiple Views
    Given I need to analyze average handling time performance
    When I configure the AHT report:
      | Parameter | Value | Required |
      | Period | 01.09.2025 to 30.09.2025 | Yes |
      | Divisions | All organizational structure | Yes |
      | Groups | All functional structure | Yes |
    And I generate the AHT report with three tabs
    Then the Output tab should show individual employee conversation metrics:
      | Field | Description |
      | Date | Information display date |
      | Full name | Employee name |
      | Direction | Employee department |
      | Group | Functional group |
      | Talk time | Total processing time for non-unique requests |
      | Number of calls | Total processed non-unique calls |
    And the "By group" tab should show functional group data divided by areas/manager groups
    And the "By direction" tab should show directions/manager groups divided by functional groups
    And AHT should be displayed in seconds rounded to thousandths
    And AHT calculations should use exact formulas:
      | Calculation Level | Formula |
      | AHT by employee | Time to process non-unique requests / Number processed |
      | AHT by group | Sum processing time all employees / Sum processed requests all employees |

  @performance_reports @ready_percentage
  Scenario: Generate %Ready Report with Comprehensive Analysis
    Given I need to analyze employee productivity percentages
    When I configure the %Ready report:
      | Parameter | Value | Required |
      | Period | 01.09.2025 to 30.09.2025 | Yes |
      | Divisions | All departments | No |
      | Full name | Selected employees | Yes |
      | Type | Home/Office/All | No |
    And I generate the %Ready report with two tabs
    Then the Output tab should show individual employee productive time:
      | Field | Description |
      | Date | Information display date |
      | Direction | Employee direction |
      | Full name | Employee name |
      | Time for productive statuses | Time in "Productive time" statuses |
      | Login time | Total time in all statuses |
      | %Ready | (Productive time / Total time in system) × 100 |
    And the "By directions" tab should show summary by direction/manager group
    And the system should handle overlapping status periods correctly:
      | Overlap Scenario | Calculation Method |
      | Multiple productive statuses | Merge overlapping periods, count unique time |
      | System 1: 10:00-10:20 productive | Combined productive time should be 30 minutes |
      | System 2: 10:10-10:30 productive | Not 40 minutes (20+20) |
    And %Ready calculation should respect Working Time Efficiency Configuration from CVC integration

  @performance_reports @load_comparison
  Scenario: Generate Planned and Actual Load Report
    Given I need to compare planned versus actual request volumes
    When I configure the load comparison report:
      | Parameter | Value | Required |
      | Date from | 01.09.2025 | Yes |
      | Date to | 30.09.2025 | Yes |
      | Groups | Simple and aggregated groups | Yes |
      | Data type | Unique arrivals | Yes |
    And I select data type from available options:
      | Data Type | Description |
      | Unique arrivals | Unique contacts received |
      | Non-unique received | All contacts received |
      | Unique processed | Unique contacts processed |
      | Non-unique processed | All contacts processed |
      | Non-unique lost | All contacts missed |
      | Unique missed calls | Unique contacts lost |
    And I generate the planned vs actual load report
    Then the report should display information on hourly basis for selected groups
    And the report should contain summary information for day by group:
      | Summary Field | Description |
      | Total | Total requests per day (Actual, Planned, Discrepancy) |
      | Fact | Actual received requests from call center integration |
      | Plan | Predicted Number of Requests × Growth Rate |
      | Discrepancy | Fact - Plan (positive or negative values) |

  # ============================================================================
  # PLANNING REPORTS - FORECASTS, BUDGET, SCHEDULES
  # ============================================================================

  @planning_reports @forecast_export
  Scenario: Generate Export Forecasts Report
    Given I need to download and view forecasts for selected groups
    When I configure the forecast export report:
      | Parameter | Value | Required |
      | Date from | 01.10.2025 | Yes |
      | Date to | 31.10.2025 | Yes |
      | Group | All simple groups | Yes |
    And I generate the export forecasts report
    Then the information should be displayed in N-minute intervals based on system settings
    And each forecast entry should include:
      | Field | Description |
      | Service | Service name for information display |
      | Group | Group name for information display |
      | Beginning of interval | Interval start date and time |
      | End of interval | Interval end date and time |
      | Calls | Predicted number of calls |
      | Growth rate | Growth rate specified in forecast |
      | AHT | Average talk time in forecast |
      | Number of simultaneously processed | Concurrent chats (1 for calls) |
      | ACD forecast | Predicted call acceptance percentage |
      | OSS forecast | Employee workload in forecast |

  @planning_reports @budget_assessment
  Scenario: Generate Report for Budget Assessment
    Given I need to assess budget based on planned work schedule and timetable
    When I configure the budget report:
      | Parameter | Value | Required |
      | Date from | 01.11.2025 | Yes |
      | Date to | 30.11.2025 | Yes |
      | Group | Functional structure | Yes |
    And I generate the budget assessment report
    Then the report should display information in N-minute intervals
    And the report should include forecast data under predicted load:
      | Forecast Field | Calculation |
      | Calls received forecast | Predicted calls × growth rate |
      | Calls accepted forecast | Predicted calls × growth rate × %ACD/100 |
      | ACD forecast | %ACD specified in forecasting |
      | Operators forecast | Predicted operators with lunch rate consideration |
    And the report should include plan data according to work schedule:
      | Plan Field | Calculation |
      | Calls accepted schedule | Requests handled by planned operators |
      | ACD schedule | Schedule capacity vs forecast |
      | Operators schedule | Planned operators with absenteeism consideration |
    And budget calculations should use exact formulas from system configuration

  @planning_reports @graph_analysis
  Scenario: Generate Graph Report for Schedule Analysis
    Given I need to determine which schedule option is more accurately planned
    When I configure the graph report:
      | Parameter | Value | Required |
      | Period | 01.06.2025 to 02.06.2025 | Yes |
      | Templates | Multi-skill planning template | Yes |
      | Name | Work schedule option name | Yes |
    And I generate the graph analysis report
    Then the report should display information by day broken down into hours
    And the report should contain summary information for week and month
    And I should be able to select any schedule option (applied or not applied)
    And the report should show comparative data:
      | Comparison Field | Description |
      | Operators forecast | Predicted employees per hour with % occupancy |
      | Operators plan under load | Sum of scheduled employees per hourly interval |
      | Operators plan minus %absenteeism | Planned employees minus absence percentage |

  @planning_reports @employee_schedule
  Scenario: Generate Employee Work Schedule Report
    Given I need to download operators' work schedules
    When I configure the employee work schedule report:
      | Parameter | Value | Required |
      | Date from | 01.12.2025 | Yes |
      | Date to | 31.12.2025 | Yes |
      | Templates | Multi-skill planning template | Yes |
      | Working hours | Saved work schedule name | Yes |
      | Divisions | Parent and subsidiary divisions | Yes |
    And I generate the employee work schedule report
    Then the report should have three tabs with specific functionality:
      | Tab | Content |
      | Work rules | Summary of work rules by divisions |
      | By employees | Work schedule with shift durations |
      | By employees 2 | Work schedule with start/end times |
    And extra shifts and overtime should be displayed in orange
    And shift durations should be displayed with hundredths (e.g., 7.42)
    And vacation display should follow color coding:
      | Vacation Type | Color |
      | Unscheduled vacations | Blue |
      | Scheduled vacations | Green |
    And familiarization status should be determined by these rules:
      | Familiarization Status | Condition |
      | "Acquainted" | Has familiarization record up to period start |
      | Not filled | No familiarization record before period start |

  @planning_reports @preferences_analysis
  Scenario: Generate Preferences Report for Schedule Planning
    Given I need to download preferences entered by operators
    When I configure the preferences report:
      | Parameter | Value | Required |
      | Report period | 01.12.2025 to 31.12.2025 | Yes |
      | Sample | Multi-skill planning template | Yes |
      | Work schedule | Applied or copy schedule | Yes |
      | Subdivision | Department filtering | No |
      | Groups | Functional structure | No |
      | Type | Home or office | No |
      | Full names | Selected operators | Yes |
    And I generate the preferences report with two sheets
    Then Sheet 1 should show daily preference details:
      | Field | Description |
      | Personnel number | Employee ID |
      | Full name | Operator name |
      | Day | Preference date |
      | Priority | Mandatory or optional |
      | Preference | Work or weekend |
      | Start/End/Duration | Time intervals (min/max) |
      | Taken into account | System consideration status |
      | Shift | Planned shift details |
    And Sheet 2 should show preference summary for period:
      | Summary Category | Metrics |
      | All preferences | Quantity, system consideration %, final consideration % |
      | Priority preferences | Quantity, system consideration %, final consideration % |
      | Common preferences | Quantity, system consideration %, final consideration % |
    And preference consideration percentage should be calculated as: Number of matched shifts / Number of shifts with preferences
    And percentage should be rounded according to mathematical rules

  # ============================================================================
  # ADMINISTRATIVE REPORTS - LOGGING, NOTIFICATIONS, ACKNOWLEDGMENTS
  # ============================================================================

  @administrative_reports @system_logging
  Scenario: Generate Logging Report for System Actions
    Given I need to view user actions in the WFM CC system
    When I configure the logging report:
      | Parameter | Value | Required |
      | Date from | 01.01.2025 00:00:00 | Yes |
      | Date to | 31.01.2025 23:59:59 | Yes |
    And I generate the logging report
    Then the report should display history of user actions stored for three years
    And data should be grouped by date
    And each log entry should include:
      | Field | Description |
      | Date | Information display date |
      | Event start time | Action execution time (hh:mm:ss) |
      | Event end time | Action completion time |
      | Event Description | Description of action performed |
      | Event initiator | Employee who made changes or "System" |

  @administrative_reports @acknowledgment_tracking
  Scenario: Generate Report on Familiarization with Work Schedule
    Given I need to track operators' work schedule acknowledgments
    When I configure the familiarization report:
      | Parameter | Value | Required |
      | Period | 01.12.2025 to 31.12.2025 | Yes |
      | Subdivision | Department filtering | No |
      | Family name | Specific operator filter | No |
    And I generate the familiarization report
    Then the report should display acknowledgment status information:
      | Field | Description |
      | Full name | Employee last name and initials |
      | Personnel number | Employee ID |
      | Introduction | Familiarization status |
      | Date of familiarization | Acknowledgment date within period |
      | Confirmation | Employee who clicked read button |

  @administrative_reports @notification_status
  Scenario: Generate Report on Notifications of Familiarization
    Given I need to track notification status for work schedule familiarization
    When I configure the notification status report:
      | Parameter | Value | Required |
      | Period | 01.12.2025 to 31.12.2025 | Yes |
      | Subdivision | Department filtering | No |
      | Full name | Specific operator filter | No |
    And I generate the notification status report
    Then the report should display comprehensive notification information:
      | Field | Description |
      | Date of sending notification | Notification timestamp within period |
      | Notification recipient | Full recipient name |
      | Recipient's personnel number | Employee ID |
      | Full name of manager | Manager who sent notification |
      | Notification text | Complete message content |
      | Notification sending channel | PUSH notification method |
      | Status | Read or unread status |

  @administrative_reports @forecast_plan_analysis
  Scenario: Generate Operators Forecast and Plan Report
    Given I need to analyze operator forecast versus plan according to schedule
    When I configure the operators forecast and plan report:
      | Parameter | Value | Required |
      | Report start date | 01.02.2025 | Yes |
      | Report end date | 05.02.2025 | Yes |
      | Time zone | Europe/Moscow | Yes |
      | Planning Template | Active multi-skill template | Yes |
      | Group | Simple and aggregated groups | No |
    And I generate the forecast and plan report with two sheets
    Then Sheet 1 should show detailed hourly analysis:
      | Category | Calculation Method |
      | Forecast | Average predicted operators with occupancy, reserve factors, absenteeism |
      | Plan | Average "Operator Plan" in intervals per hour |
      | Deficiency/excess | [Plan per hour] - [Forecast per hour] |
    And Sheet 2 should show monthly summaries:
      | Summary | Description |
      | Forecast | Sum of all hourly forecast values for period |
      | Plan | Sum of all hourly plan values for period |
    And report should exclude terminated operators after termination date
    And values should be rounded to hundredths (2 decimal places)
    And data should be brought to single time zone for generation

  # ============================================================================
  # REPORT ACCESS CONTROL AND SECURITY
  # ============================================================================

  @security @access_control
  Scenario: Implement Report Access Control and Security
    Given the reporting system contains sensitive workforce data
    When I configure report access control
    Then the system should enforce role-based access:
      | Role | Report Access | Scope | Restrictions |
      | System Administrator | All reports | System-wide | Full access |
      | HR Manager | Personnel and vacation reports | All employees | HR-related only |
      | Department Manager | Performance and schedule reports | Department employees | Own department |
      | Team Leader | Operational reports | Team members | Team scope only |
      | Operator | Personal reports | Own data | Self-service |
    And the system should implement security measures:
      | Security Control | Implementation |
      | Data encryption | TLS 1.2+ for transmission |
      | Audit logging | All report access logged |
      | Parameter validation | Input sanitization |
      | Export control | Controlled download permissions |

  @security @data_privacy
  Scenario: Implement Data Privacy Controls in Reporting
    Given reports may contain personal employee information
    When the system generates reports containing personal data
    Then data privacy controls should be applied:
      | Privacy Control | Implementation |
      | Data minimization | Only necessary fields in reports |
      | Access logging | Complete audit trail |
      | Retention limits | Automated data archival |
      | Anonymization | Option for anonymized reports |
    And GDPR compliance should be maintained:
      | GDPR Requirement | Implementation |
      | Right to access | Personal data reports |
      | Right to rectification | Data correction capability |
      | Right to erasure | Data deletion on request |
      | Data portability | Structured export formats |

  # ============================================================================
  # PERFORMANCE AND SCALABILITY
  # ============================================================================

  @performance @scalability
  Scenario: Ensure Report Performance for Enterprise Scale
    Given the system must handle large datasets and concurrent users
    When reports are generated for enterprise-scale data
    Then performance requirements should be met:
      | Performance Metric | Target | Measurement |
      | Report generation time | <30 seconds for standard reports | Average response time |
      | Concurrent users | 100+ simultaneous report users | Load testing |
      | Large dataset handling | 1M+ records | Query optimization |
      | Export performance | <60 seconds for complex exports | File generation time |
    And scalability should be ensured through:
      | Scalability Feature | Implementation |
      | Database optimization | Indexed queries, partitioning |
      | Caching | Report result caching |
      | Pagination | Large result set pagination |
      | Background processing | Async report generation |

  @performance @optimization
  Scenario: Optimize Report Editor Performance
    Given the report editor must handle complex queries efficiently
    When users create and execute custom reports
    Then optimization should include:
      | Optimization Area | Implementation |
      | Query execution | Query plan optimization |
      | Parameter validation | Client-side validation |
      | Result caching | Redis-based caching |
      | Resource management | Connection pooling |
    And monitoring should track:
      | Monitoring Metric | Threshold | Action |
      | Query execution time | >10 seconds | Query optimization alert |
      | Memory usage | >80% | Resource scaling |
      | Database connections | >90% pool | Connection limit increase |
      | Error rates | >5% | System health check |

  # ============================================================================
  # INTEGRATION AND DATA SOURCES
  # ============================================================================

  @integration @data_sources
  Scenario: Integrate Reporting with All System Data Sources
    Given reports require data from multiple system components
    When the reporting system accesses data sources
    Then integration should cover all required sources:
      | Data Source | Report Usage | Integration Method |
      | Personnel Database | Employee information reports | Direct database queries |
      | Call Center Integration | Performance and load reports | Real-time API calls |
      | Planning System | Schedule and forecast reports | Planning database access |
      | Time Tracking | Attendance and lateness reports | Status data integration |
      | 1C System | Job and skill change reports | External system sync |
    And data consistency should be maintained:
      | Consistency Requirement | Implementation |
      | Real-time data | Live database connections |
      | Historical accuracy | Point-in-time snapshots |
      | Cross-system sync | Data validation checks |
      | Audit trail | Change tracking |

  @integration @real_time_reporting
  Scenario: Implement Real-Time Reporting Capabilities
    Given some reports require real-time or near real-time data
    When real-time reports are requested
    Then the system should provide current information:
      | Report Type | Update Frequency | Data Source |
      | Current agent status | Real-time | Live status API |
      | Group metrics | 5-minute intervals | Operational database |
      | Login/logout activity | Real-time | Authentication system |
      | Performance dashboards | 15-minute intervals | Aggregated metrics |
    And real-time performance should meet requirements:
      | Performance Requirement | Target |
      | Data latency | <30 seconds |
      | Update frequency | Configurable intervals |
      | System responsiveness | <2 seconds |
      | Concurrent real-time users | 50+ users |

  # ============================================================================
  # ERROR HANDLING AND RELIABILITY
  # ============================================================================

  @reliability @error_handling
  Scenario: Implement Comprehensive Error Handling for Reporting System
    Given the reporting system must be reliable and handle errors gracefully
    When errors occur during report generation or access
    Then the system should handle all error scenarios:
      | Error Type | Handling | User Experience |
      | Database connection failure | Retry with fallback | Clear error message |
      | Query timeout | Background processing | Progress indicator |
      | Invalid parameters | Validation feedback | Inline error display |
      | Insufficient permissions | Access denied message | Redirect to login |
      | Data export failure | Retry mechanism | Download alternative |
    And error logging should capture:
      | Log Information | Purpose |
      | Full error details | Technical debugging |
      | User context | Support assistance |
      | System state | Issue reproduction |
      | Performance metrics | Optimization |

  @reliability @backup_recovery
  Scenario: Implement Report System Backup and Recovery
    Given report configurations and historical data must be protected
    When backup and recovery procedures are implemented
    Then comprehensive protection should include:
      | Backup Component | Frequency | Retention |
      | Report definitions | Daily | 30 days |
      | Generated reports | Weekly | 90 days |
      | User configurations | Daily | 30 days |
      | System settings | After changes | 10 versions |
    And recovery procedures should ensure:
      | Recovery Scenario | RTO | RPO |
      | Report system failure | 2 hours | 1 hour |
      | Database corruption | 4 hours | 1 hour |
      | Configuration loss | 30 minutes | 0 minutes |
      | Export system failure | 1 hour | 0 minutes |