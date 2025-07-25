Feature: 1C ZUP Integrated Payroll and Analytics Reporting System
  As a payroll manager and HR analyst
  I want 1C ZUP integrated reporting capabilities for payroll and time tracking
  So that I can generate official payroll reports with proper 1C time codes and labor compliance

  Background:
    Given I have appropriate permissions for payroll and 1C ZUP integrated reports
    And the reporting service is configured with 1C ZUP integration
    And 1C ZUP time type data is synchronized and available
    And payroll calculation periods are properly configured

  @reports @schedule_adherence
  Scenario: Generate Schedule Adherence Reports
    Given I navigate to Reports → Schedule Adherence
    When I configure report parameters:
      | Parameter | Value |
      | Period | 01.01.2025-31.01.2025 |
      | Department | Technical Support |
      | Detail Level | 15-minute intervals |
      | Include Weekends | Yes |
      | Show Exceptions | Yes |
    Then the report should display:
      | Metric | Visualization | Calculation |
      | Individual adherence % | Color-coded cells | (Scheduled time - Deviation) / Scheduled time |
      | Planned schedule time | Blue blocks | From work schedule |
      | Actual worked time | Green blocks | From integration data |
      | Timetable details | Productive vs auxiliary | Break down activity types |
      | Average adherence | Summary percentage | Team average calculation |
    And cells should be color-coded:
      | Color | Meaning | Threshold |
      | Green | Good adherence | >80% |
      | Yellow | Moderate adherence | 70-80% |
      | Red | Poor adherence | <85% |

  @reports @payroll_calculation
  Scenario: Create Payroll Calculation Reports
    Given I need payroll data for accounting
    When I generate payroll reports with parameters:
      | Mode | Data Source | Period |
      | 1C Data | Integration system | Half-month |
      | Actual CC | Contact center actual | Bi-weekly |
      | WFM Schedule | Planned schedules | Monthly |
    Then the report should contain 1C ZUP time codes:
      | Code | Russian | English | 1C ZUP Document Type | Calculation |
      | I (Я) | Явка | Day work | Individual schedule | Standard worked hours 06:00-21:59 |
      | H (Н) | Ночные | Night work | Individual schedule | Hours worked 22:00-05:59 |
      | B (В) | Выходной | Day off | Individual schedule | No shift scheduled |
      | C (С) | Сверхурочные | Overtime | Overtime work | Hours above norm |
      | RV (РВ) | Работа в выходной | Weekend work | Work on holidays/weekends | Rest day work |
      | RVN (РВН) | Ночная работа в выходной | Night weekend work | Work on holidays/weekends | Night work on rest days |
      | NV (НВ) | Неявка | Absence | Absence (unexplained) | From absence events |
      | OT (ОТ) | Отпуск | Annual vacation | Vacation | From vacation schedule |
    And provide summaries by:
      | Period | Aggregation | Purpose |
      | Half-month | 1st-15th, 16th-end | Payroll processing |
      | Monthly | Full month totals | Management reporting |
      | Quarterly | 3-month summaries | Performance analysis |

  @reports @forecast_accuracy
  Scenario: Analyze Forecast Accuracy Performance
    Given historical forecasts and actual data exist
    When I run forecast accuracy analysis for the period
    Then the system should calculate accuracy metrics:
      | Metric | Formula | Target | Purpose |
      | MAPE | Mean Absolute Percentage Error | <15% | Overall accuracy |
      | WAPE | Weighted Absolute Percentage Error | <12% | Volume-weighted accuracy |
      | MFA | Mean Forecast Accuracy | >85% | Average precision |
      | WFA | Weighted Forecast Accuracy | >88% | Volume-weighted precision |
      | Bias | (Forecast - Actual) / Actual | ±5% | Systematic error |
      | Tracking Signal | Cumulative bias / MAD | ±4 | Trend detection |
    And provide drill-down analysis by:
      | Level | Granularity | Insight |
      | Interval | 15-minute | Intraday patterns |
      | Daily | Day-by-day | Daily variations |
      | Weekly | Week-by-week | Weekly seasonality |
      | Monthly | Month-by-month | Monthly trends |
      | Channel | By service group | Channel-specific accuracy |

  @reports @kpi_dashboards
  Scenario: Generate KPI Performance Dashboards
    Given I need executive-level performance visibility
    When I access KPI dashboards
    Then I should see key performance indicators:
      | KPI Category | Metrics | Frequency | Target |
      | Service Level | 80/20 format (80% calls in 20 seconds) | Real-time | 80/20 |
      | Efficiency | Occupancy, Utilization | Hourly | 85% |
      | Quality | Customer satisfaction, FCR | Daily | >90% |
      | Schedule | Adherence, Shrinkage | Daily | >80% |
      | Forecast | Accuracy, Bias | Weekly | ±10% |
      | Cost | Cost per contact, Overtime % | Monthly | Budget targets |
    And dashboards should include:
      | Visualization | Purpose | Update Frequency |
      | Traffic light indicators | Quick status overview | Real-time |
      | Trend charts | Performance over time | Hourly |
      | Heat maps | Performance by time/agent | Daily |
      | Waterfall charts | Variance analysis | Weekly |

  @reports @absence_analysis
  Scenario: Analyze Employee Absence Patterns
    Given I need to understand absence trends
    When I generate absence analysis reports
    Then the analysis should include:
      | Absence Type | Metrics | Analysis Period |
      | Planned absences | Vacation usage, Training hours | Monthly |
      | Unplanned absences | Sick leave frequency, Emergency leave | Weekly |
      | Pattern analysis | Day-of-week trends, Seasonal patterns | Quarterly |
      | Impact analysis | Coverage effects, Cost implications | Ongoing |
    And provide insights on:
      | Insight Category | Analysis | Actionable Information |
      | Absence rates | By department/individual | Identify high-absence areas |
      | Trends | Increasing/decreasing patterns | Predict future absences |
      | Costs | Direct and indirect costs | Budget impact assessment |
      | Coverage | Service level impact | Staffing adjustments needed |

  @reports @overtime_tracking
  Scenario: Track and Analyze Overtime Usage
    Given overtime policies are in place
    When I analyze overtime utilization
    Then the report should track:
      | Overtime Metric | Calculation | Alert Threshold |
      | Individual overtime | Hours per employee per period | >10 hours/week |
      | Department overtime | Total hours by department | >5% of regular hours |
      | Overtime costs | Premium rate calculations | >Budget allocation |
      | Approval compliance | Approved vs actual overtime | >80% pre-approval |
    And identify optimization opportunities:
      | Optimization Area | Analysis | Recommendation |
      | Staffing levels | Chronic overtime patterns | Hire additional staff |
      | Schedule efficiency | Predictable overtime needs | Adjust base schedules |
      | Skill development | Single-skill bottlenecks | Cross-train employees |
      | Workload distribution | Uneven work allocation | Balance assignments |

  @reports @cost_analysis
  Scenario: Comprehensive Cost Analysis Reporting
    Given cost centers are configured
    When I generate cost analysis reports
    Then the analysis should break down costs by:
      | Cost Category | Components | Allocation Method |
      | Direct labor | Regular hours, Overtime, Benefits | Time-based |
      | Indirect labor | Management, Support staff | Activity-based |
      | Technology | Systems, Telecommunications | Usage-based |
      | Facilities | Office space, Utilities | Square footage |
      | Training | Development programs, Certifications | Per employee |
    And provide cost metrics:
      | Metric | Calculation | Benchmark |
      | Cost per contact | Total costs / Total contacts | Industry average |
      | Cost per FTE | Total costs / Full-time equivalent | Previous periods |
      | Variable cost ratio | Variable costs / Total costs | Budget targets |
      | Unit cost trends | Period-over-period changes | Efficiency goals |

  @reports @audit_trails
  Scenario: Generate Audit Trail Reports
    Given system changes need to be tracked
    When I generate audit trail reports
    Then the report should capture:
      | Audit Category | Tracked Events | Retention Period |
      | User actions | Login, logout, access attempts | 1 year |
      | Data changes | Schedule modifications, Approvals | 7 years |
      | System changes | Configuration updates, Integrations | 5 years |
      | Security events | Failed logins, Permission changes | 2 years |
    And include audit details:
      | Audit Field | Information | Purpose |
      | Timestamp | When event occurred | Temporal tracking |
      | User ID | Who performed action | Accountability |
      | Action type | What was done | Event categorization |
      | Before/After | Data state changes | Change verification |
      | IP address | Source of action | Security analysis |
      | Session ID | User session tracking | Activity correlation |

  @reports @custom_reports
  Scenario: Build Custom Reports Using Report Editor
    Given I have report building permissions
    When I access the Report Editor
    And I create a custom report with:
      | Component | Configuration | Purpose |
      | Data sources | Multiple database connections | Comprehensive data access |
      | SQL queries | Custom queries with parameters | Flexible data selection |
      | Input parameters | Date ranges, departments, filters | User customization |
      | Output format | Excel, PDF, CSV | Multiple delivery formats |
      | Scheduling | Daily, weekly, monthly automation | Automated delivery |
      | Distribution | Email lists, shared folders | Stakeholder access |
    Then the custom report should be:
      | Feature | Capability |
      | Parameterized | Accept user inputs |
      | Scheduled | Run automatically |
      | Secured | Role-based access |
      | Versioned | Track report changes |
      | Documented | Clear descriptions |

  @reports @performance_benchmarking
  Scenario: Performance Benchmarking Analysis
    Given historical performance data is available
    When I conduct benchmarking analysis
    Then the system should compare:
      | Benchmark Type | Comparison | Analysis Period |
      | Internal trends | Current vs historical performance | Year-over-year |
      | Peer comparison | Similar departments/teams | Quarterly |
      | Industry standards | External benchmarks | Annually |
      | Best practices | Top-performing periods | Ongoing |
    And identify improvement opportunities:
      | Opportunity Area | Metric | Improvement Target |
      | Service level | Current vs best period | +5% improvement |
      | Efficiency | Productivity comparisons | Match top quartile |
      | Quality | Customer satisfaction | Industry benchmark |
      | Cost effectiveness | Cost per unit metrics | 10% reduction target |

  @reports @predictive_analytics
  Scenario: Predictive Analytics and Forecasting Reports
    Given machine learning models are configured
    When I generate predictive analytics reports
    Then the system should provide:
      | Prediction Type | Forecast | Confidence Level |
      | Attrition risk | Employee turnover likelihood | 80%+ accuracy |
      | Absence prediction | Unplanned absence probability | 75%+ accuracy |
      | Performance trends | Individual/team trajectory | Statistical significance |
      | Capacity needs | Future staffing requirements | Scenario-based |
    And support decision-making with:
      | Decision Support | Analysis | Recommendation |
      | Hiring plans | Predicted attrition + growth | Recruitment timing |
      | Training needs | Skill gap analysis | Development priorities |
      | Schedule optimization | Predicted absence patterns | Proactive scheduling |
      | Budget planning | Cost trend projections | Budget allocations |

  @reports @real_time_reporting
  Scenario: Real-time Operational Reporting
    Given real-time data feeds are configured
    When I access real-time reports
    Then I should see live operational metrics:
      | Metric Category | Update Frequency | Alert Threshold |
      | Current staffing | Every 30 seconds | <85% of plan |
      | Service levels | Every minute | <Target 80/20 format |
      | Queue status | Real-time | >5 minute wait |
      | System health | Every 30 seconds | Any failures |
    And real-time alerts should trigger:
      | Alert Type | Condition | Notification Method |
      | Critical understaffing | <75% of required staff | Immediate SMS/Email |
      | Service level breach | <70% 80/20 format achievement | Dashboard alert |
      | System outage | Integration failures | Emergency notification |
      | Queue overflow | >20 contacts waiting | Escalation protocol |

  @reports @mobile_reporting
  Scenario: Mobile-Optimized Reports and Dashboards
    Given managers need mobile access to reports
    When I access reports via mobile device
    Then mobile reports should provide:
      | Mobile Feature | Capability | User Experience |
      | Responsive design | Adapt to screen size | Optimal viewing |
      | Touch navigation | Finger-friendly controls | Easy interaction |
      | Offline access | Cached data availability | Work without connection |
      | Push notifications | Critical alert delivery | Timely awareness |
      | Quick actions | One-tap responses | Efficient operation |
    And maintain functionality:
      | Function | Mobile Capability | Performance |
      | Report viewing | Full report access | Fast loading |
      | Data drilling | Tap to drill down | Smooth navigation |
      | Filtering | Touch-based filters | Intuitive operation |
      | Sharing | Email/message sharing | Simple distribution |