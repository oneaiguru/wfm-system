Feature: Load Forecasting and Demand Planning - Complete Technical Implementation
  As a planning specialist
  I want to forecast contact center workload and calculate operator requirements
  So that staffing levels meet service level targets efficiently

  Background:
    Given I am logged in as a planning specialist
    And I have access to "Forecasting" → "Forecast Load"
    And historical data is available for analysis
    And the system supports multiple forecasting algorithms

  # ============================================================================
  # EXACT UI WORKFLOWS FROM DEMAND FORECASTING DOCUMENT
  # ============================================================================

  @forecasting @ui_navigation
  Scenario: Navigate to Forecast Load Page with Exact UI Steps
    Given I am logged into the WFM CC system
    When I navigate to forecasting functionality using exact UI path
    Then I should see the "Forecast Load" page
    And I should see service and group selection dropdowns
    And I should see schema options (unique/non-unique incoming)
    And I should see period and timezone settings
    And the page should match Figure 2 layout from documentation

  @forecasting @historical_data_acquisition_methods
  Scenario: Use Both Methods for Historical Data Acquisition
    Given I am on the "Forecast Load" page
    And I have selected service "Technical Support" and group "Level 1"
    When I need historical data for forecasting
    Then I should have two acquisition methods available:
      | Method | UI Action | Data Source | Requirements |
      | Integration | Click "gear" → "Request data" | Customer's source system | Integration configured |
      | Manual Upload | Click "gear" → "Import" | Excel document | Proper file format |
    And each method should have specific requirements and validation
    And data must be saved before proceeding to next tab

  @forecasting @manual_import_exact_format
  Scenario: Manual Historical Data Import with Exact Excel Template
    Given I need to manually upload historical data
    When I click "gear" → "Import" on Forecast Load page
    And I upload Excel file with exact format from Table 1:
      | Column | Header | Format | Example | Validation |
      | A | Start time | DD.MM.YYYY HH:MM:SS | 01.01.2024 09:00:00 | DateTime parsing |
      | B | Unique incoming | Integer | 10 | Positive numbers |
      | C | Non-unique incoming | Integer | 15 | >= Column B |
      | D | Average talk time | Seconds | 300 | Positive seconds |
      | E | Post-processing | Seconds | 30 | Positive seconds |
    Then the system should validate exact template format
    And reject files that don't match template structure
    And display clear error messages for format issues
    And show data preview before final import
    And save historical data for use in forecasting process
    And before moving to "Peak Analysis" tab I must click "gear" → "Save"

  @forecasting @aggregated_groups_workflow
  Scenario: Work with Aggregated Groups - Complete Workflow
    Given I have an aggregated group containing multiple simple groups
    And each simple group has historical data from integration
    When I select the aggregated group for forecasting
    And I need to work with combined historical data
    Then the system should automatically sum call data:
      | Data Type | Aggregation Method | Calculation |
      | Call volumes | Sum across groups | Group1_calls + Group2_calls + ... |
      | Average talk time | Weighted average | Sum(calls×AHT) / Sum(calls) |
      | Post-processing | Weighted average | Sum(calls×PostProc) / Sum(calls) |
    And I can click "gear" → "Recalculate data" to refresh aggregation
    And forecasting methodology should be identical to simple groups
    And operator calculations should apply to the aggregated group
    And results should reflect combined group performance

  @forecasting @growth_factor_use_case
  Scenario: Apply Growth Factor for Volume Scaling - Exact Use Case
    Given I have historical data/plan for 1,000 calls per day
    And I need a forecast for 5,000 calls with same distribution
    When I complete the standard forecasting process:
      | Step | Tab | Action |
      | 1 | Parameters | Set Service, Group, Schema, Period, Time Zone → Apply |
      | 2 | Historical Data Correction | Review and correct anomalies |
      | 3 | Peak Analysis | Smooth outliers as needed |
      | 4 | Trend Analysis | Configure trend parameters |
      | 5 | Seasonal Components | Set seasonal patterns |
      | 6 | Traffic and AHT Forecasting | Set forecasting period |
    And on "Traffic and AHT Forecasting" tab
    And I click "gear" in "Forecast" block → "Growth Factor"
    And I configure growth factor parameters:
      | Parameter | Value | Purpose |
      | Period | 01.11.2023 – 31.12.2023 | Base period for scaling |
      | Growth Factor | 5.0 | Scale from 1,000 to 5,000 calls |
      | Apply to | Call volume only | Maintain AHT values |
      | Maintain AHT | Yes | Keep same handling times |
    Then call volumes should be multiplied by 5.0
    And load distribution pattern should remain identical
    And AHT values should be preserved unchanged
    And scaled forecast should be ready for operator calculation

  # ============================================================================
  # IMPORT FORECASTS PAGE - CALL VOLUME PLANS
  # ============================================================================

  @import_forecasts @exact_ui_navigation
  Scenario: Navigate to Import Forecasts Page - Exact UI Path
    Given I need to import call volume plans for operator calculation
    When I navigate using exact UI path from Figure 8
    Then I should reach "Import Forecasts" page
    And I should see upload form for call volume plans
    And I should see separate file upload for each group/skill/split/queue
    And the interface should match Figure 9 layout

  @import_forecasts @call_volume_file_format_table2
  Scenario: Import Call Volume with Exact Format from Table 2
    Given I am on "Import Forecasts" page
    When I upload call volume plan file
    Then the file must match exact format from Table 2:
      | Column | Format | Example | Validation Rule |
      | A | DD.MM.YYYY hh:mm or YYYY.MM.DD hh:mm | 01.01.2025 09:00 | DateTime validation |
      | B | Numeric (calls) | 10 | Positive integer |
      | C | Numeric (AHT seconds) | 100 | Positive integer |
    And columns A and B are mandatory
    And column C is optional but recommended
    And data must be in numeric format for columns B and C
    And the system should provide the upload template from Table 3
    And validation should reject malformed files immediately

  @import_forecasts @operator_calculation_coefficients
  Scenario: Apply Operator Calculation Adjustments - Table 4 Logic
    Given I have imported forecast values successfully
    When I need to adjust calculated operator requirements
    And I apply various coefficient types:
      | Coefficient Type | Application Period | Calculation Method | Business Purpose |
      | Increasing coefficients | Specific intervals | Multiply operators | Handle volatility/peaks |
      | Decreasing coefficients | Low-load periods | Divide operators | Reduce overstaffing |
      | Absenteeism percentage | All periods | Add % to total | Account for sick leave |
      | Minimum operators | Low-load intervals | Set floor value | Ensure minimum coverage |
    Then adjustments should apply to each interval individually
    And different periods can have different coefficient values
    And minimum operators should override calculated values when higher
    And final values should be realistic and validated
    And coefficients can be set for periods down to intervals
    And different coefficient magnitudes can be set for different periods

  @import_forecasts @data_aggregation_table4
  Scenario: Apply Exact Data Aggregation Logic from Table 4
    Given I have calculated operator requirements by intervals
    When I view aggregated data by different time periods
    Then the system must apply exact logic from Table 4:
      | Aggregation Period | Calculation Method | Display Purpose | Formula Example |
      | Hour | Average across intervals in hour | Person-hours needed in this hour | (5+6+4+7)/4 intervals = 5.5 |
      | Day | Sum of hourly person-hours | Person-hours needed per day | 8+9+10+7+6+5+4+3 = 52 |
      | Week | Sum hourly ÷ number of days | Avg person-hours per day in week | 350 total ÷ 7 days = 50 |
      | Month | Sum hourly ÷ number of days | Avg person-hours per day in month | 1500 total ÷ 30 days = 50 |
    And aggregated data should preserve mathematical relationships
    And drill-down should be available to source intervals
    And calculations should be transparent and auditable
    And when saving, if forecast exists in DB system overwrites values

  @import_forecasts @minimum_operators_logic
  Scenario: Apply Minimum Operators Logic with Exact Calculation
    Given I have calculated operator requirements by intervals
    When I apply minimum operators setting of 1 operator for period 10:00-10:30
    And calculated operators show:
      | Interval | Calculated Operators |
      | 10:00-10:15 | 0 |
      | 10:15-10:30 | 1 |
    Then the system should compare calculated vs minimum:
      | Interval | Calculated | Minimum | Final Value | Logic |
      | 10:00-10:15 | 0 | 1 | 1 | Use minimum (higher than calculated) |
      | 10:15-10:30 | 1 | 1 | 1 | Keep calculated (equals minimum) |
    And minimum operators should override when calculated value is lower
    And intervals meeting or exceeding minimum should remain unchanged

  # ============================================================================
  # VIEW LOAD PAGE - OPERATOR FORECASTS IMPORT
  # ============================================================================

  @view_load @exact_ui_navigation_figure11
  Scenario: Navigate to View Load Page - Exact UI Steps
    Given I need to import ready operator forecasts
    When I navigate using path shown in Figure 11
    Then I should reach "View Load" page
    And I should see Service, Group, Mode, Period, Time Zone parameters
    And I should see "gear" → "Import" option
    And the interface should allow operator forecast import

  @view_load @import_sequence_figures12_14
  Scenario: Complete Import Sequence Following Figures 12-14
    Given I am on "View Load" page
    When I follow the exact sequence from documentation:
      | Step | Action | Reference | Result |
      | 1 | Fill Service, Group, Mode, Period, Time Zone | - | Parameters set |
      | 2 | Click "gear" → "Import" | Figure 12 | Import dialog opens |
      | 3 | Select import type (intervals/hours) | - | Type selected |
      | 4 | Set days for load import | Data Input tab | Days configured |
      | 5 | Fill wait time, SL, AHT parameters | Figure 13 | Parameters entered |
      | 6 | Upload file with load data | - | File uploaded |
      | 7 | Verify uploaded data | Verification tab | Data validated |
      | 8 | Click "Save" | Figure 14 | Data saved |
    Then each step should complete successfully
    And data should be validated at each stage
    And final verification should show correct data transformation

  @view_load @hourly_file_format_table5_6
  Scenario: Import Operator Plan with Exact Format from Tables 5-6
    Given I am importing operator forecasts by hours
    When I upload Excel file for operator plan
    Then the file must match exact format from Table 5:
      | Column | Content | Format | Validation |
      | A | Call count | Numeric (can be 0) | Integer or decimal |
      | B | Operator count | Numeric | Integer or decimal |
    And file must have exactly 24 rows
    And each row represents one hour in ascending order:
      | Row | Time Period | Data Requirement |
      | 1 | 00:00-01:00 | Hour 0 data |
      | 2 | 01:00-02:00 | Hour 1 data |
      | ... | ... | ... |
      | 24 | 23:00-24:00 | Hour 23 data |
    And the system should provide template from Table 6
    And validation should enforce exact 24-row requirement
    And when importing only operators, column A should be 0

  @view_load @interval_division_logic
  Scenario: Apply Exact Interval Division Logic for Hourly Import
    Given I upload hourly data to system configured for 5-minute intervals
    When the system processes hourly data for division
    Then exact division logic should apply:
      | Data Type | Division Method | Example Calculation | Result |
      | Call count | Divide equally | 120 calls/hour ÷ 12 intervals | 10 calls per 5-min interval |
      | Operator count | Maintain level | 6 operators/hour | 6 operators in each 5-min interval |
    And division should account for system interval configuration:
      | System Interval | Divisions per Hour | Calculation |
      | 5 minutes | 12 intervals | Hourly_value ÷ 12 |
      | 10 minutes | 6 intervals | Hourly_value ÷ 6 |
      | 15 minutes | 4 intervals | Hourly_value ÷ 4 |
    And decimal results should be handled appropriately
    And totals should reconcile with original hourly values

  @view_load @day_selection_production_calendar
  Scenario: Select Days for Forecast Upload Using Production Calendar
    Given I am importing forecasts by day type
    When I configure day selection for forecast upload
    Then I should have production calendar options:
      | Day Type | Selection | Calendar Source | Application |
      | Weekdays | Monday-Friday | Production calendar | Business days only |
      | Weekends and holidays | Saturday-Sunday + holidays | Production calendar | Non-business days |
      | All days | Every day in period | Full calendar | Complete coverage |
      | Custom selection | Specific date ranges | Manual selection | Targeted periods |
    And production calendar should be integrated
    And holiday definitions should be respected
    And day type selection should affect forecast application
    And different patterns can be applied to different day types

  @view_load @aggregation_operators_detailed
  Scenario: Apply Exact Operator Aggregation Logic for View Load
    Given I have operator data by intervals
    When I view aggregated operator data by different periods
    Then the system should apply specific aggregation for operators:
      | Period | Aggregation Method | Display Purpose | Example |
      | Hour | Average across intervals | Operators needed in this hour | (5+6+4+7)/4 = 5.5 operators |
      | Day | Sum hourly ÷ shift length | Operators needed per day | 52 person-hours ÷ 8 hours = 6.5 operators |
      | Week | Sum hourly ÷ shift length per week | Operators needed per week | 350 person-hours ÷ 40 hours = 8.75 operators |
      | Month | Sum hourly ÷ shift length per month | Operators needed per month | 1500 person-hours ÷ 168 hours = 8.93 operators |
    And calls during aggregation should be summed across all intervals
    And operator calculations should account for shift length
    And when saving, existing forecasts in DB should be overwritten

  @view_load @limitations_corrections
  Scenario: Handle View Load Limitations and Error Cases
    Given I am working with View Load import functionality
    When I encounter system limitations
    Then I should be aware of constraints:
      | Limitation | Impact | Workaround |
      | No correction of imported data | Cannot edit after import | Re-import correct file |
      | Separate file per group | Each group needs individual file | Prepare multiple files |
      | No validation during import | Errors discovered after processing | Validate files before upload |
      | Format restrictions | Strict adherence to template | Use provided templates |
    And error handling should include:
      | Error Type | System Response | User Action |
      | Wrong file format | Reject with error message | Use correct template |
      | Missing rows | Validation failure | Ensure 24 rows for hourly |
      | Invalid data types | Import failure | Check numeric formats |
      | File corruption | Processing error | Re-export and import |

  # ============================================================================
  # ADVANCED FORECASTING ALGORITHMS AND STATISTICAL METHODS
  # ============================================================================

  @forecasting @algorithm_stages
  Scenario: Complete Forecasting Algorithm with All Stages
    Given I have historical data loaded and corrected
    When I execute the forecasting algorithm
    Then the system should process data through exact stages:
      | Stage | Process | Input | Output |
      | 1 | Peak smoothing | Raw historical data | Outlier-free data |
      | 2 | Trend determination | Smoothed data | Trend coefficients |
      | 3 | Seasonal coefficients | Trend-adjusted data | Seasonal patterns |
      | 4 | Forecast calculation | All components | Interval forecasts |
    And each stage should use appropriate statistical methods
    And results should be available for review and adjustment
    And forecast accuracy should be measurable

  @forecasting @erlang_models_detailed
  Scenario: Apply Advanced Erlang Models for Different Channel Types
    Given I have forecast data for different communication channels
    When I calculate operator requirements by channel type:
      | Channel Type | Model | Parameters | Special Considerations |
      | Voice calls | Erlang C | Poisson arrival, exponential service | Queue tolerance |
      | Email | Linear | Multiple simultaneous handling | Response time SLA |
      | Chat | Modified Erlang | Concurrent conversations | Context switching |
      | Video calls | Erlang C | Higher resource usage | Technical requirements |
    Then each model should apply appropriate formulas
    And consider channel-specific constraints
    And calculate realistic operator requirements
    And account for skill requirements and cross-training

  @forecasting @error_handling_comprehensive
  Scenario: Handle Forecasting Errors and Data Quality Issues
    Given forecasting process is running
    When various error conditions occur:
      | Error Type | Cause | System Response | Recovery Action |
      | Missing data | Integration failure | Use last known values | Retry with backoff |
      | Invalid data | Out-of-range values | Flag for review | Manual correction |
      | Calculation error | Division by zero | Skip interval | Use adjacent data |
      | Model failure | Insufficient data | Fallback model | Simplified method |
      | Performance issue | Large dataset | Process in batches | Progress indication |
    Then the system should handle errors gracefully
    And provide clear error messages
    And suggest corrective actions
    And maintain audit trail of errors and resolutions

  @competitive_intelligence @documented_accuracy_metrics
  Scenario: Argus MFA/WFA Accuracy Metrics vs WFM Advanced Analytics
    Given Argus documentation confirms MFA and WFA accuracy metrics exist
    And "MFA – average accuracy and WFA – weighted accuracy" per official manual
    When compared to WFM statistical accuracy capabilities
    Then WFM should provide enhanced accuracy analysis:
      | Metric | Argus Capability | WFM Enhancement | Documentation Reference |
      | MFA | Mean forecast accuracy | MAPE with statistical validation | Official manual line 1052 |
      | WFA | Weighted forecast accuracy | WAPE with volume weighting | Official manual line 1052 |
      | Accuracy monitoring | Basic reporting | Real-time degradation alerts | Beyond Argus documented capability |
      | Error analysis | General accuracy metrics | Detailed statistical breakdowns | Industry standard enhancement |
    And WFM provides continuous accuracy monitoring vs periodic reporting

  @competitive_intelligence @documented_multi_skill_limitations
  Scenario: Argus Multi-Skill Allocation Limitations vs WFM Optimization
    Given Argus documentation states multi-skill load distribution method
    And "Remaining load is distributed among multi-skill operators" per manual
    And "one group can be included in only one multi-skill template" limitation
    When multiple projects compete for same multi-skilled operators
    Then Argus provides basic distribution without advanced optimization
    But WFM should provide:
      | Feature | Argus Documented Capability | WFM Enhancement |
      | Load distribution | Sequential (mono-skill first, then multi-skill) | Simultaneous optimization |
      | Template restrictions | One group per template limitation | Flexible cross-project allocation |
      | Conflict resolution | Manual allocation of remaining load | Automated multi-criteria optimization |
      | Optimization algorithm | Basic distribution logic | Advanced mathematical optimization |
    And WFM eliminates template restrictions for optimal allocation

  @forecasting @validation_quality_assurance
  Scenario: Implement Comprehensive Data Validation and Quality Assurance
    Given I am working with forecast data
    When the system validates data quality
    Then comprehensive checks should be performed:
      | Validation Type | Check | Threshold | Action |
      | Data completeness | Missing intervals | >5% | Require correction |
      | Value reasonableness | Call volumes | 10x average | Flag for review |
      | Trend consistency | Growth rates | >50% change | Validate manually |
      | Seasonal patterns | Coefficient range | ±100% | Check calculation |
      | Model accuracy | Prediction error | >20% MAPE | Suggest retraining |
    And quality scores should be calculated
    And recommendations should be provided
    And data lineage should be maintained
    And validation history should be preserved
