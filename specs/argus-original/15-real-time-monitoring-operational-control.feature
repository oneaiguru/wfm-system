Feature: Real-time Monitoring and Operational Control
  As a supervisor and operations manager
  I want real-time visibility into operational performance
  So that I can make immediate adjustments to maintain service levels

  Background:
    Given I have supervisor or manager permissions
    And real-time data integration is configured
    And monitoring dashboards are accessible
    And alert thresholds are properly configured

  @monitoring @operational_dashboards
  Scenario: View Real-time Operational Control Dashboards
    Given I navigate to "Monitoring" → "Operational Control"
    When I access the operational dashboards
    Then I should see six key real-time metrics:
      | Dashboard Metric | Calculation | Thresholds | Update Frequency |
      | Operators Online % | (Actual Online / Planned) × 100 | Green >80%, Yellow 70-80%, Red <70% | Every 30 seconds |
      | Load Deviation | (Actual Load - Forecast) / Forecast | ±10% Green, ±20% Yellow, >20% Red | Every minute |
      | Operator Requirement | Erlang C based on current load | Dynamic based on service level | Real-time |
      | SLA Performance | 80/20 format (80% calls in 20 seconds) | Target ±5% variations | Every minute |
      | ACD Rate | (Answered / Offered) × 100 | Against forecast expectations | Real-time |
      | AHT Trend | Weighted average handle time | Vs planned AHT | Every 5 minutes |
    And each metric should display:
      | Display Element | Purpose | Visual Indicator |
      | Current value | Real-time status | Large number display |
      | Trend arrow | Direction of change | Up/down/stable arrows |
      | Color coding | At-a-glance status | Traffic light system |
      | Historical context | Recent performance | Trend line or sparkline |

  @monitoring @drill_down_analysis
  Scenario: Drill Down into Metric Details
    Given I am viewing operational dashboards
    When I click on "Operators Online" metric
    Then I should see detailed breakdown:
      | Detail Category | Information | Purpose |
      | Schedule adherence 24h | Real-time compliance | Track punctuality |
      | By timetable status | Current vs planned activity | Verify task execution |
      | Actually online agents | Live feed from integration | Real staffing levels |
      | Individual agent status | Per-agent current state | Identify issues |
      | Deviation timeline | 24-hour historical chart | Pattern analysis |
    And the detailed view should update:
      | Update Element | Frequency | Source |
      | Agent status | Every 30 seconds | Real-time integration |
      | Schedule compliance | Real-time | Timetable comparison |
      | Historical trends | Every minute | Accumulated data |

  @monitoring @individual_agent_tracking
  Scenario: Monitor Individual Agent Status and Performance
    Given I have access to agent monitoring
    When I view subordinate operator statuses
    Then I should see real-time agent information:
      | Agent Status | Visual Indicator | Available Actions |
      | On schedule | Green indicator | None required |
      | Late login | Yellow + timer showing delay | "Call to workplace" |
      | Absent | Red + duration of absence | "Call to workplace" + escalation |
      | Wrong status | Orange + status mismatch | Investigate + correct |
      | In break | Blue + remaining time | Monitor break duration |
      | Lunch | Purple + expected return | Track lunch compliance |
    And for each agent, I should see:
      | Agent Information | Details | Purpose |
      | Current activity | What they're doing now | Real-time status |
      | Schedule adherence | On-time vs late | Performance tracking |
      | Today's statistics | Calls, talk time, breaks | Daily performance |
      | Contact availability | Ready for next contact | Queue management |

  @monitoring @threshold_alerts
  Scenario: Configure and Respond to Threshold-Based Alerts
    Given monitoring thresholds are configured
    When operational metrics exceed critical thresholds
    Then automated alerts should trigger:
      | Alert Trigger | Threshold | Response Actions |
      | Critical understaffing | Online % <70% | SMS + email to management |
      | Service level breach | 80/20 format <70% for 5 minutes | Immediate escalation |
      | System overload | Queue >20 contacts | Emergency staffing protocol |
      | Extended outages | No data for 10 minutes | Technical team alert |
    And alert responses should include:
      | Response Element | Content | Purpose |
      | Alert description | What threshold was breached | Clear problem identification |
      | Current values | Actual vs target metrics | Quantify severity |
      | Suggested actions | Recommended responses | Guidance for resolution |
      | Escalation timeline | When to escalate further | Progressive response |

  @monitoring @predictive_alerts
  Scenario: Generate Predictive Alerts for Potential Issues
    Given historical patterns are analyzed
    When trends indicate potential problems
    Then predictive alerts should warn of:
      | Predictive Alert | Analysis | Lead Time |
      | Approaching SLA breach | Trend analysis of current performance | 15-30 minutes |
      | Staffing shortfall | Scheduled vs required operators | 1-2 hours |
      | Break/lunch coverage gaps | Scheduled break overlaps | 30-60 minutes |
      | Peak load preparation | Forecasted volume increases | 2-4 hours |
    And predictions should be based on:
      | Prediction Factor | Data Source | Accuracy Target |
      | Historical patterns | Same day/time previous weeks | 80% accuracy |
      | Current trends | Real-time trajectory analysis | 75% accuracy |
      | Scheduled events | Known staffing changes | 95% accuracy |
      | External factors | Special events, holidays | 70% accuracy |

  @monitoring @real_time_adjustments
  Scenario: Make Real-time Operational Adjustments
    Given I identify operational issues through monitoring
    When immediate action is required
    Then I should be able to:
      | Adjustment Type | Action | System Response |
      | Call operator to work | "Call to workplace" button | Send notification + track response |
      | Extend shift | Adjust end time | Check overtime compliance |
      | Add break coverage | Reassign operators | Maintain service levels |
      | Emergency scheduling | Add unscheduled operators | Override normal constraints |
      | Skill reallocation | Move operators between channels | Update timetable assignments |
    And adjustments should:
      | Validation | Check | Error Handling |
      | Labor standards compliance | Overtime, rest periods | Block non-compliant changes |
      | Service level impact | Coverage requirements | Warn of potential SLA risk |
      | Employee availability | Current status | Prevent conflicts |
      | Cost implications | Budget impact | Show cost warnings |

  @monitoring @multi_group_monitoring
  Scenario: Monitor Multiple Groups Simultaneously
    Given I manage multiple service groups
    When I need comprehensive operational oversight
    Then the system should provide:
      | Multi-Group View | Display | Functionality |
      | Group comparison | Side-by-side metrics | Compare performance |
      | Aggregate dashboard | Combined statistics | Overall operation status |
      | Priority alerts | Most critical issues first | Focus attention |
      | Resource reallocation | Cross-group movements | Optimize coverage |
    And support group management:
      | Management Feature | Capability | Benefit |
      | Group prioritization | Set importance levels | Focus resources |
      | Escalation routing | Group-specific procedures | Appropriate response |
      | Performance benchmarking | Inter-group comparison | Identify best practices |
      | Resource sharing | Temporary reallocation | Crisis response |

  @monitoring @historical_analysis
  Scenario: Analyze Historical Monitoring Data for Patterns
    Given monitoring data is collected continuously
    When I analyze historical performance patterns
    Then I should be able to review:
      | Analysis Period | Data Granularity | Insights |
      | Intraday patterns | 15-minute intervals | Peak/low periods |
      | Daily trends | Hourly aggregations | Day-of-week patterns |
      | Weekly patterns | Daily summaries | Weekly cycles |
      | Monthly analysis | Weekly/daily trends | Seasonal variations |
    And identify improvement opportunities:
      | Pattern Analysis | Insight | Action |
      | Recurring SLA breaches | Systematic understaffing | Adjust base schedules |
      | Agent adherence patterns | Individual performance issues | Targeted coaching |
      | Break timing optimization | Coverage gap patterns | Optimize break schedules |
      | Forecast accuracy | Prediction vs actual | Improve forecasting models |

  @monitoring @integration_health
  Scenario: Monitor Integration Health and Data Quality
    Given multiple systems provide real-time data
    When monitoring system integration status
    Then I should track:
      | Integration Component | Health Metric | Alert Condition |
      | Contact center feed | Data freshness | >5 minutes delay |
      | Agent status updates | Update frequency | <50% expected updates |
      | Queue statistics | Data completeness | Missing key metrics |
      | Historical data sync | Sync success rate | <95% success |
    And data quality checks should validate:
      | Data Quality Check | Validation | Error Response |
      | Data completeness | All expected fields present | Flag incomplete records |
      | Value reasonableness | Metrics within expected ranges | Alert on anomalies |
      | Temporal consistency | Timestamps in correct sequence | Reject out-of-order data |
      | Cross-system consistency | Matching data across sources | Investigate discrepancies |

  @monitoring @mobile_monitoring
  Scenario: Access Monitoring Capabilities on Mobile Devices
    Given I need monitoring access while mobile
    When I access monitoring via mobile device
    Then mobile monitoring should provide:
      | Mobile Feature | Capability | User Experience |
      | Key metric dashboard | Essential metrics only | Quick overview |
      | Alert notifications | Push notifications | Immediate awareness |
      | Quick actions | Call operators, acknowledge alerts | Rapid response |
      | Simplified navigation | Touch-optimized interface | Easy operation |
    And maintain functionality:
      | Function | Mobile Implementation | Performance |
      | Real-time updates | Efficient data refresh | Minimal battery drain |
      | Alert management | Notification handling | Clear action options |
      | Trend visualization | Mobile-optimized charts | Fast rendering |
      | Emergency procedures | One-touch emergency actions | Critical response capability |

  @monitoring @performance_optimization
  Scenario: Optimize Monitoring System Performance
    Given high-volume real-time data processing
    When system performance needs optimization
    Then performance measures should include:
      | Optimization Area | Technique | Benefit |
      | Data aggregation | Pre-calculate common metrics | Faster dashboard loading |
      | Caching strategy | Cache frequently accessed data | Reduced database load |
      | Update frequency | Optimize refresh rates | Balance accuracy vs performance |
      | Data compression | Compress data transmission | Reduced network overhead |
    And monitor system resource usage:
      | Resource Metric | Target | Alert Threshold |
      | CPU utilization | <70% average | >85% sustained |
      | Memory usage | <80% of available | >90% peak |
      | Network bandwidth | <50% capacity | >75% sustained |
      | Database response time | <2 seconds | >5 seconds |

  @monitoring @escalation_procedures
  Scenario: Handle Monitoring Alert Escalations
    Given alert escalation procedures are defined
    When critical alerts are not resolved within timeframes
    Then escalation should progress through levels:
      | Escalation Level | Timeframe | Recipients | Actions |
      | Level 1 | Immediate | Direct supervisor | Initial response |
      | Level 2 | 15 minutes | Department manager | Management intervention |
      | Level 3 | 30 minutes | Operations director | Executive involvement |
      | Level 4 | 60 minutes | Crisis management team | Emergency procedures |
    And escalation should include:
      | Escalation Element | Content | Purpose |
      | Problem summary | Clear issue description | Quick understanding |
      | Impact assessment | Business impact quantification | Priority determination |
      | Actions taken | Previous response attempts | Avoid duplication |
      | Recommended actions | Next steps | Guidance for resolution |

  @monitoring @compliance_monitoring
  Scenario: Monitor Labor Standards and Compliance
    Given labor standards are configured
    When monitoring real-time compliance
    Then the system should track:
      | Compliance Area | Real-time Check | Alert Condition |
      | Rest period violations | Time since last break | >4 hours without break |
      | Overtime accumulation | Daily/weekly hours tracking | Approaching limits |
      | Shift duration compliance | Current shift length | >12 hours continuous |
      | Break duration monitoring | Current break length | Exceeding allocated time |
    And compliance violations should:
      | Violation Response | Action | Notification |
      | Immediate alert | Notify supervisor | Real-time warning |
      | Documentation | Log compliance breach | Audit trail |
      | Corrective action | Suggest remediation | Guidance |
      | Trend analysis | Identify patterns | Prevent recurrence |

  @monitoring @quality_monitoring
  Scenario: Monitor Service Quality Metrics in Real-time
    Given quality metrics are defined
    When monitoring service quality
    Then I should track:
      | Quality Metric | Measurement | Target |
      | First call resolution | Resolution rate | >85% |
      | Customer satisfaction | Post-call surveys | >4.0/5.0 |
      | Call quality scores | QA evaluations | >90% |
      | Complaint rate | Customer complaints | <2% |
    And quality monitoring should:
      | Monitoring Feature | Implementation | Benefit |
      | Real-time scoring | Immediate quality assessment | Quick intervention |
      | Trend analysis | Quality trends over time | Proactive improvement |
      | Individual tracking | Per-agent quality metrics | Targeted development |
      | Correlation analysis | Quality vs other metrics | Identify drivers |  # ============================================================================
  # ADMINISTRATIVE OPERATIONS - STATUS MANAGEMENT AND CUSTOMIZATION
  # ============================================================================

  @admin_operations @status_management @system_reset @emergency_procedures
  Scenario: Execute System-Wide Status Reset with Administrative Controls
    Given I have administrative privileges for status management
    And the system requires status reset due to operational issues
    When I initiate comprehensive status reset procedures
    Then I should execute multi-level status reset with authorization:
      | Reset Scope | Authorization Level | Confirmation | Audit Trail |
      | Individual operator | Supervisor approval | Single confirmation | Basic logging |
      | Department scope | Manager approval | Double confirmation | Enhanced logging |
      | System-wide reset | Executive approval | Triple confirmation | Complete audit |
      | Emergency reset | Emergency authorization | Emergency protocol | Immediate audit |
    And implement status reset workflow with validation:
      | Reset Phase | Implementation | Validation | Recovery |
      | Pre-reset validation | System state check | Data integrity | Backup creation |
      | Authorization check | Multi-level approval | Permission validation | Access verification |
      | Reset execution | Controlled reset | Status verification | State confirmation |
      | Post-reset validation | System health check | Functionality test | Performance validation |
    And configure reset audit and compliance:
      | Audit Requirement | Implementation | Retention | Access Control |
      | Reset authorization | Approval workflow | 7 years | Security team |
      | System state before | Full system snapshot | 3 years | Operations team |
      | Reset execution log | Detailed operation log | 5 years | Audit team |
      | Impact assessment | Performance analysis | 1 year | Management team |

  @admin_operations @status_reset @department_management @selective_reset
  Scenario: Execute Selective Status Reset by Department and Time Period
    Given I need to reset statuses for specific operational scenarios
    When I configure selective status reset parameters
    Then I should implement targeted reset capabilities:
      | Reset Target | Scope | Validation | Impact Assessment |
      | Department-specific | Selected departments | Department validation | Service impact analysis |
      | Time period-based | Date/time range | Historical validation | Data consistency check |
      | Status type-specific | Selected status types | Type validation | Workflow impact analysis |
      | Individual operator | Single operator | Identity validation | Personal impact review |
    And configure selective reset authorization:
      | Authorization Type | Required Approval | Documentation | Oversight |
      | Department reset | Department manager | Business justification | HR notification |
      | Time period reset | Operations manager | Impact assessment | Service continuity |
      | Status type reset | Technical manager | Technical justification | System validation |
      | Emergency selective | Duty manager | Emergency documentation | Executive notification |
    And implement reset rollback capabilities:
      | Rollback Scenario | Detection Method | Recovery Time | Data Protection |
      | Partial failure | Automated monitoring | 5 minutes | Transaction isolation |
      | Data corruption | Integrity checking | 15 minutes | Backup restoration |
      | Authorization error | Access validation | 2 minutes | Permission correction |
      | System conflict | Dependency analysis | 10 minutes | Conflict resolution |

  @user_customization @dashboard_personalization @preferences_management @ui_configuration
  Scenario: Configure Personal Dashboard Display Settings and Preferences
    Given I access personal account dashboard customization
    When I configure dashboard display settings
    Then I should implement comprehensive customization options:
      | Customization Category | Options | Persistence | Sync Capability |
      | Layout configuration | Grid/List/Compact views | User profile | Cross-device sync |
      | Widget arrangement | Drag-and-drop positioning | Local storage | Cloud backup |
      | Color scheme | Light/Dark/High-contrast | Browser storage | Account preference |
      | Metric preferences | Selected KPIs display | Database storage | Team sharing |
    And configure dashboard widget management:
      | Widget Type | Customization | Data Source | Update Frequency |
      | Performance metrics | Size, position, format | Real-time data | 30 seconds |
      | Schedule overview | Date range, detail level | Planning system | 5 minutes |
      | Alert notifications | Priority, display style | Monitoring system | Real-time |
      | Team status | Team selection, layout | HR system | 1 minute |
    And implement accessibility and mobile optimization:
      | Accessibility Feature | Implementation | Compliance | Mobile Support |
      | Screen reader support | ARIA labels | WCAG 2.1 AA | Full compatibility |
      | Keyboard navigation | Tab ordering | Accessibility standards | Touch optimization |
      | High contrast mode | Color adjustment | Visual accessibility | Responsive design |
      | Font size scaling | Dynamic scaling | User preference | Mobile-friendly |
    And configure preference synchronization:
      | Sync Aspect | Technology | Frequency | Conflict Resolution |
      | Layout settings | Cloud storage | Real-time | Last-write-wins |
      | Widget configuration | JSON serialization | On change | User preference |
      | Theme preferences | Profile storage | Immediate | Device-specific override |
      | Accessibility settings | Account level | Login sync | Merge strategy |

  @user_preferences @notification_customization @alert_management @communication_control
  Scenario: Configure Personal Notification and Alert Preferences
    Given I need to customize notification settings for optimal workflow
    When I configure personal notification preferences
    Then I should implement intelligent notification management:
      | Notification Type | Delivery Method | Timing Control | Priority Management |
      | Operational alerts | In-app, email, SMS | Immediate/Batched | High/Medium/Low |
      | Schedule changes | Dashboard, email | Real-time/Daily digest | Critical/Standard |
      | Performance updates | Dashboard only | Hourly summary | Informational |
      | System maintenance | Email, dashboard | Advance notice | Administrative |
    And configure smart notification filtering:
      | Filter Type | Logic | Customization | Learning |
      | Relevance filtering | Role-based rules | User preferences | Usage patterns |
      | Frequency limiting | Rate limiting | Personal thresholds | Behavioral analysis |
      | Priority escalation | Urgency detection | Escalation rules | Response patterns |
      | Context awareness | Situational logic | Work schedule | Activity correlation |
    And implement notification delivery optimization:
      | Optimization Feature | Implementation | Effectiveness | User Control |
      | Do not disturb mode | Schedule-based | Respect work hours | Manual override |
      | Delivery consolidation | Batch processing | Reduce interruption | Frequency control |
      | Mobile optimization | Push notifications | Instant delivery | Platform-specific |
      | Cross-device sync | Multi-device delivery | Prevent duplication | Device priority |

  @status_management @advanced_reset @medium
  Scenario: Advanced system status reset with selective components
    Given I am logged in as system administrator
    And system has various component statuses to reset
    When I navigate to advanced status management
    Then I should see component status overview:
      | Component | Status | Last Reset | Reset Available |
      | Load Forecasting | Active | 2024-01-15 10:30 | Yes |
      | Schedule Engine | Warning | 2024-01-15 09:15 | Yes |
      | Sync Services | Error | 2024-01-15 08:45 | Yes |
      | Report Generator | Active | 2024-01-14 16:20 | Yes |
    When I select components for reset:
      | Component | Reason | Reset Type |
      | Schedule Engine | Clear warnings | Soft Reset |
      | Sync Services | Resolve errors | Hard Reset |
    And I confirm selective reset
    Then I should see reset progress:
      | Component | Status | Progress | ETA |
      | Schedule Engine | Resetting | 60% | 30 seconds |
      | Sync Services | Resetting | 40% | 45 seconds |
    And components should return to healthy status
    And reset log should be created with audit trail

  @dashboard_customization @user_preferences @low
  Scenario: Dashboard display settings customization
    Given I am logged in as operator
    And I have access to personal dashboard
    When I navigate to dashboard settings
    Then I should see customization options:
      | Setting | Current Value | Options |
      | Default View | Calendar | Calendar, List, Grid |
      | Time Format | 24-hour | 12-hour, 24-hour |
      | Date Format | DD.MM.YYYY | DD.MM.YYYY, MM/DD/YYYY |
      | Language | Русский | Русский, English |
    And I should be able to save preferences
    And settings should persist across sessions
    And preferences should apply immediately
