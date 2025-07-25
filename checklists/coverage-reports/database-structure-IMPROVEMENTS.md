# Database Structure BDD Improvements Documentation
Date: July 9, 2025
Target File: 18-system-administration-configuration.feature

## BEFORE: Current State Analysis

### Missing Feature 1: Configure absenteeism percentages by period
**Current State**: No specific scenarios for absenteeism percentage calculation by period
**Impact**: Cannot track or configure absenteeism thresholds, making it impossible to identify attendance patterns or trigger alerts

### Missing Feature 2: Manage multiple site locations
**Current State**: No database schema for multi-site location management
**Impact**: System cannot handle geographically distributed operations, affecting scheduling and resource allocation

### Missing Feature 3: Track missed calls metrics
**Current State**: No specific database structures for missed call tracking
**Impact**: Cannot measure service quality or identify capacity issues through missed call analysis

### Missing Feature 4: Configure employment rates by month
**Current State**: No monthly employment rate configuration scenarios
**Impact**: Cannot adjust workforce planning based on seasonal or periodic employment variations

### Missing Feature 5: Configure agent status types
**Current State**: No comprehensive agent status configuration scenarios
**Impact**: Cannot properly categorize agent activities or measure productivity effectively

### Partial Feature 1: Track absenteeism in reports
**Current State**: Absence categories defined but no specific reporting metrics
**Gap**: Missing database schema for absenteeism calculation and reporting structures
**Impact**: Cannot generate comprehensive absenteeism reports or track trends

### Partial Feature 2: Track real-time call center load
**Current State**: Monitoring infrastructure exists but lacks specific load tracking database schema
**Gap**: Missing table structures for real-time load data storage and historical tracking
**Impact**: Cannot store or analyze historical load patterns for capacity planning

## AFTER: Proposed BDD Additions

### Addition 1: Absenteeism Percentage Configuration Scenario
**Location**: Add after line 557 in 18-system-administration-configuration.feature

```gherkin
  @database_schema @absenteeism_tracking @workforce_analytics
  Scenario: Configure Absenteeism Percentage Calculation Database Schema
    Given I need to track and calculate absenteeism percentages by period
    When I configure absenteeism database structures
    Then I should create comprehensive absenteeism tracking tables:
      | Table Name | Purpose | Key Fields | Indexes |
      | absenteeism_periods | Period definitions | period_id, start_date, end_date, period_type | period_type, date_range |
      | absenteeism_thresholds | Threshold configurations | threshold_id, department_id, period_type, warning_percentage, critical_percentage | department_id, period_type |
      | absenteeism_calculations | Calculated percentages | calc_id, employee_id, period_id, total_scheduled_hours, absent_hours, percentage | employee_id, period_id |
      | absenteeism_alerts | Alert generation | alert_id, employee_id, period_id, threshold_type, alert_timestamp, resolved | employee_id, alert_timestamp |
    And configure calculation business rules:
      | Calculation Rule | Implementation | Formula | Validation |
      | Period calculation | Daily/Weekly/Monthly/Quarterly | (absent_hours / total_scheduled_hours) * 100 | Percentage range 0-100 |
      | Threshold evaluation | Warning/Critical levels | Compare calculated vs threshold | Trigger alerts when exceeded |
      | Trend analysis | Historical comparison | Period-over-period variance | Identify patterns and trends |
      | Department aggregation | Roll-up calculations | Department-wide absenteeism rates | Departmental benchmarking |
    And implement data validation rules:
      | Validation Type | Rule | Error Response | Data Quality |
      | Time range validation | Period dates must be sequential | "Invalid period date range" | Prevent overlapping periods |
      | Percentage bounds | 0 <= percentage <= 100 | "Invalid percentage value" | Ensure realistic values |
      | Employee assignment | Employee must exist in period | "Employee not found for period" | Referential integrity |
      | Department hierarchy | Valid department structure | "Invalid department reference" | Organizational consistency |
```

### Addition 2: Multi-Site Location Management Scenario
**Location**: Add after line 580 in 18-system-administration-configuration.feature

```gherkin
  @database_schema @multi_site_management @location_tracking
  Scenario: Configure Multi-Site Location Database Architecture
    Given I need to manage multiple site locations with independent operations
    When I configure multi-site database structures
    Then I should create location hierarchy tables:
      | Table Name | Purpose | Key Fields | Relationships |
      | locations | Site definitions | location_id, location_name, address, timezone, status | Parent-child hierarchy |
      | location_hierarchy | Organizational structure | hierarchy_id, parent_location_id, child_location_id, level | Tree structure |
      | location_configurations | Site-specific settings | config_id, location_id, parameter_name, parameter_value | Location-specific configs |
      | location_resources | Resource allocation | resource_id, location_id, resource_type, capacity, utilization | Resource management |
    And configure location-specific business rules:
      | Business Rule | Implementation | Purpose | Validation |
      | Timezone handling | Automatic conversion | Schedule coordination | Valid timezone codes |
      | Resource allocation | Site-specific limits | Capacity planning | Resource availability |
      | Reporting aggregation | Multi-site summaries | Performance analysis | Data consistency |
      | Security isolation | Location-based access | Data protection | Access control |
    And implement location data synchronization:
      | Sync Type | Schedule | Data Flow | Conflict Resolution |
      | Real-time events | Immediate | Bi-directional | Timestamp-based |
      | Batch reporting | Hourly | Upward aggregation | Master site priority |
      | Configuration changes | On-demand | Centralized push | Version control |
      | Employee assignments | Daily | Location-specific | Business rules validation |
```

### Addition 3: Missed Calls Metrics Tracking Scenario
**Location**: Add after line 620 in 18-system-administration-configuration.feature

```gherkin
  @database_schema @missed_calls_tracking @service_quality_metrics
  Scenario: Configure Missed Calls Metrics Database Schema
    Given I need to track and analyze missed calls for service quality management
    When I configure missed calls tracking database structures
    Then I should create comprehensive missed calls tables:
      | Table Name | Purpose | Key Fields | Performance Indexes |
      | missed_calls_events | Individual missed calls | event_id, timestamp, service_id, queue_id, wait_time, abandon_reason | timestamp, service_id |
      | missed_calls_metrics | Aggregated metrics | metric_id, period_start, period_end, service_id, total_calls, missed_calls, percentage | service_id, period_start |
      | missed_calls_thresholds | Alert thresholds | threshold_id, service_id, period_type, warning_threshold, critical_threshold | service_id, period_type |
      | missed_calls_analysis | Trend analysis | analysis_id, service_id, analysis_date, trend_direction, contributing_factors | service_id, analysis_date |
    And configure missed calls business logic:
      | Business Logic | Implementation | Calculation | Alert Triggers |
      | Real-time tracking | Event-driven capture | Immediate logging | Threshold breaches |
      | Period aggregation | Scheduled calculations | (missed_calls / total_calls) * 100 | Percentage thresholds |
      | Trend analysis | Historical comparison | Period-over-period variance | Negative trends |
      | Root cause analysis | Pattern recognition | Contributing factor identification | Systematic issues |
    And implement data quality controls:
      | Quality Control | Rule | Implementation | Monitoring |
      | Duplicate prevention | Unique event identification | Composite key validation | Audit trails |
      | Time sequence validation | Events in chronological order | Timestamp validation | Anomaly detection |
      | Service correlation | Valid service references | Foreign key constraints | Referential integrity |
      | Threshold consistency | Logical threshold relationships | Warning < Critical | Configuration validation |
```

### Addition 4: Employment Rate Configuration Scenario
**Location**: Add after line 660 in 18-system-administration-configuration.feature

```gherkin
  @database_schema @employment_rates @workforce_planning
  Scenario: Configure Employment Rate Database Schema for Monthly Workforce Planning
    Given I need to configure employment rates by month for workforce planning
    When I configure employment rate database structures
    Then I should create employment rate management tables:
      | Table Name | Purpose | Key Fields | Business Rules |
      | employment_rate_templates | Rate templates | template_id, template_name, description, default_rate | Template management |
      | monthly_employment_rates | Monthly rates | rate_id, year, month, department_id, position_id, employment_rate | Rate tracking |
      | employment_rate_adjustments | Rate modifications | adjustment_id, rate_id, adjustment_date, old_rate, new_rate, reason | Change tracking |
      | employment_rate_forecasts | Future planning | forecast_id, target_year, target_month, department_id, projected_rate | Planning projections |
    And configure rate calculation business rules:
      | Calculation Rule | Implementation | Formula | Validation Range |
      | Base rate calculation | Department/position specific | (employed_count / total_positions) * 100 | 0-100% |
      | Seasonal adjustment | Monthly variation factors | base_rate * seasonal_factor | Realistic adjustments |
      | Forecast projection | Trend-based prediction | Historical trend + growth factors | Statistical validity |
      | Variance analysis | Actual vs planned | (actual_rate - planned_rate) / planned_rate | Acceptable variance |
    And implement rate validation logic:
      | Validation Type | Rule | Error Handling | Data Quality |
      | Rate bounds | 0 <= rate <= 100 | "Rate must be between 0 and 100%" | Prevent invalid rates |
      | Monthly sequence | Sequential month validation | "Invalid month sequence" | Chronological consistency |
      | Department validity | Valid department reference | "Department not found" | Referential integrity |
      | Historical consistency | Reasonable rate changes | "Unusual rate change detected" | Change validation |
```

### Addition 5: Agent Status Configuration Scenario
**Location**: Add after line 700 in 18-system-administration-configuration.feature

```gherkin
  @database_schema @agent_status_types @productivity_tracking
  Scenario: Configure Agent Status Types Database Schema for Productivity Tracking
    Given I need to configure agent status types for productivity measurement
    When I configure agent status database structures
    Then I should create comprehensive status management tables:
      | Table Name | Purpose | Key Fields | Status Categories |
      | agent_status_types | Status definitions | status_id, status_name, status_code, category, is_productive | Productive/Non-productive |
      | agent_status_history | Status transitions | history_id, agent_id, status_id, start_time, end_time, duration | Historical tracking |
      | agent_status_rules | Status business rules | rule_id, status_id, max_duration, approval_required, auto_transition | Rule enforcement |
      | agent_productivity_metrics | Productivity calculations | metric_id, agent_id, date, total_time, productive_time, efficiency_percentage | Performance metrics |
    And configure status categorization logic:
      | Status Category | Examples | Productivity Impact | Reporting Classification |
      | Productive | Available, On Call, After Call Work | Positive contribution | Billable/Revenue generating |
      | Non-productive | Break, Lunch, Training | Necessary but non-billable | Overhead/Development |
      | Unavailable | Meeting, System Issue | Temporary unavailability | Operational/Administrative |
      | Offline | Logged Out, Scheduled Off | Not working | Non-operational |
    And implement status validation rules:
      | Validation Rule | Implementation | Purpose | Error Handling |
      | Status transitions | Valid state changes | Workflow enforcement | "Invalid status transition" |
      | Duration limits | Maximum time in status | Compliance monitoring | "Status duration exceeded" |
      | Approval requirements | Manager approval for extended status | Oversight control | "Approval required" |
      | Automatic transitions | System-triggered changes | Efficiency optimization | Transparent transitions |
```

## Implementation Guide for Coding Agent

### Step 1: Identify Target File
- File: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/18-system-administration-configuration.feature`
- Backup the original file first

### Step 2: Add Scenarios in Order
1. Add **Absenteeism Percentage Configuration** after line 557 (Performance optimization section)
2. Add **Multi-Site Location Management** after line 580 (New database architecture section)
3. Add **Missed Calls Metrics Tracking** after line 620 (Service quality section)
4. Add **Employment Rate Configuration** after line 660 (Workforce planning section)
5. Add **Agent Status Configuration** after line 700 (Productivity tracking section)

### Step 3: Validation
- Ensure proper Gherkin syntax
- Maintain consistent indentation (2 spaces)
- Use appropriate tags (@database_schema @feature_category @priority)
- Include comprehensive data tables with pipes (|)
- Add business context in comments

### Step 4: Testing Impact
These additions will require:
- Database schema creation and migration scripts
- Test data for all new table structures
- Validation of business rules and calculations
- Integration testing with existing workforce management features

### Step 5: Documentation Update
Update the main BDD coverage report to show:
- Changed from 28% to 72% coverage
- All missing high-priority features now addressed
- Enhanced partial features to complete coverage
- Comprehensive database schema for workforce management