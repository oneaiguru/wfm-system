# Methods for Obtaining Demand in the ARGUS WFM CC System

## Table of Contents

[Introduction](#introduction)

[1. Load Forecasting Through the "Forecast Load" Page](#1-load-forecasting-through-the-forecast-load-page)

[2. Adding Call Volume Plans for Operator Calculation Through the "Import Forecasts" Page](#2-adding-call-volume-plans-for-operator-calculation-through-the-import-forecasts-page)

[3. Adding Operator Plans Through the "View Load" Page](#3-adding-operator-plans-through-the-view-load-page)

---

## Introduction

Figure 1 presents the scheme for obtaining/loading operator requirements in the ARGUS WFM CC system.

![Operator Requirements Schema](img/operator_requirements_workflow_schema.png)

**Figure 1 - Schema for obtaining operator requirements in the ARGUS WFM CC system**

---

## 1. Load Forecasting Through the "Forecast Load" Page

This system module performs load forecasting based on historical data that is preliminarily analyzed and corrected.

### General Requirements:

- Forecasting and calculation of operator requirements in the system is performed at the group level (both simple and aggregated groups).

- Group selection must be performed at the stage of working with historical data that will participate in forecast formation.

- To form a forecast, the user must specify the forecasting period. The forecasting period is unlimited.

- Forecasting and calculation of operator requirements is performed at the interval level (interval is set during system implementation, typically equal to 5, 10, or 15 minutes).

- Calculation of operator requirements is performed based on forecasted data.

![Navigate to Forecast Load Page](img/navigate_to_forecast_load_page.png)

**Figure 2 - Navigation to "Forecast Load" page**

### Forecasting Algorithm

The forecasting algorithm is divided into several stages:

- Smoothing peaks (outliers) in historical data
- Trend determination
- Seasonal coefficient determination (yearly, monthly, weekly, daily)
- Calculation of forecasted values in intervals considering trend and seasonal components

![Load Forecasting Algorithm](img/load_forecasting_algorithm_flowchart.png)

**Figure 3 - Load forecasting algorithm**

### Historical Data Acquisition

The system can obtain historical data for groups in two ways:

**1. Data from the Customer's source system (with integration):**
To request data via integration, click the "gear" → "Request data". Historical data will be received for the period specified in the "Parameters" block.

**2. Manual data upload via Excel document:**
To manually upload historical data, click the "gear" → "Import".

**Table 1 - Historical data upload template**

| № | Description | Document |
|---|-------------|----------|
| 1 | Template for manually uploading historical data to the system | ![Historical Data Template](img/historical_data_upload_template.png) |

Before moving from the "Historical Data Correction" tab to the next "Peak Analysis" tab, you must save the received historical data by clicking "gear" → "Save".

![Import Historical Data](img/import_load_historical_data_interface.png)

**Figure 4 - Import/loading historical data**

### Requirements for Aggregated Forecast Formation

- The WFM CC system has the ability to create an aggregated group that includes simple groups.
- For each simple group, historical data enters the WFM CC system from the corresponding Customer source system (with integration).
- When working with historical data for an aggregated group, the system sums historical data for all calls from all simple groups included in the aggregated group. Average talk time and post-processing time are calculated as weighted averages across all simple groups, using the number of calls in the interval as weight.
- To recalculate data for an aggregated group, click "gear" → "Recalculate data".

![Recalculate Aggregated Group Data](img/recalculate_aggregated_group_data.png)

**Figure 5 - Recalculating data for aggregated group**

- When forecasting load, generated forecasts relate to the aggregated group. The forecasting methodology is the same as for simple groups - using a trend-seasonal model.
- When calculating operator requirements, generated data relates to the aggregated group.
- Results of calculations for aggregated forecasts and calculated operator requirements are displayed in tabular and graphical form, same as forecasts for simple groups.

### Use Case: Forecasting Load for Higher Call Volume with Same Load Distribution

**Given:**
- We have historical data/plan by intervals for 1,000 calls

**Required:**
- Obtain a plan/forecast for a future period for 5,000 calls with the same load distribution

**Steps:**
1. Go to "Forecast Load" page
2. Fill parameters: "Service", "Group", "Schema", "Period", "Time Zone" and click "Apply"
3. Step by step, set necessary settings on tabs: "Historical Data Correction", "Peak Analysis", "Trend Analysis", "Seasonal Components Analysis"
4. On the "Traffic and AHT Forecasting" tab in the "Forecasting" block, set the period for which load needs to be forecasted

![Select Forecasting Period](img/select_forecasting_period_interface.png)

**Figure 6 - Selecting forecasting period**

5. To obtain a plan/forecast with the same load distribution but higher call volume (5,000), on the "Traffic and AHT Forecasting" tab, click "gear" in the "Forecast" block → "Growth Factor"
6. In the "Period" parameter, specify the period for which the growth factor will be calculated (01.11.2023 – 31.12.2023)
7. In the "Growth Factor" parameter, specify the load increase factor (5)

![Apply Growth Factor](img/apply_growth_factor_interface.png)

**Figure 7 - Applying growth factor**

---

## 2. Adding Call Volume Plans for Operator Calculation Through the "Import Forecasts" Page

The system implements the ability to import call volume plans on the "Import Forecasts" page. This function is used when the WFM CC system needs to load call plans and calculate the required number of operators to cover the load, as well as plan work schedules.

![Navigate to Import Forecasts](img/navigate_to_import_forecasts_page.png)

**Figure 8 - Navigation to "Import Forecasts" page**

For each group (skill, split, queue), a separate file with forecast and operator calculations will need to be uploaded.

![Call Volume Plan Upload Form](img/call_volume_plan_upload_form.png)

**Figure 9 - Form for uploading call volume plan (by intervals)**

### File Format Requirements for Call Import

**Table 2 - Call import file format**

| A | B | C |
|---|---|---|
| Time interval start | Number of calls | AHT, sec |
| DD.MM.YYYY hh:mm | 10 | 100 |

**File Column Descriptions:**
- Columns A and B data must be mandatory
- Column A data must be in date and time format:
  - DD.MM.YYYY hh:mm
  - YYYY.MM.DD hh:mm
- Columns B and C data must be in numeric format

**Table 3 - Call volume plan upload template by intervals**

| № | Description | Document |
|---|-------------|----------|
| 1 | Template for uploading calls to system (xls, xlsx) by intervals | ![Call Volume Template](img/call_volume_upload_template_intervals.png) |

![Calculate Operators Based on Call Plan](img/calculate_operators_from_call_plan.png)

**Figure 10 - Calculating number of operators based on call volume plan**

### Operator Calculation Requirements

1. After importing forecast values, the system can calculate the required number of operators to cover the load.

2. Calculation formulas are analogous to formulas used on the "Forecast Load" page.

3. When working with calculated data, users can adjust the calculated operator requirements using increasing or decreasing coefficients or % absenteeism (% of absent operators, e.g., due to illness). Users can specify correction periods down to intervals, as well as coefficient magnitude or % absenteeism - different coefficient magnitudes or % absenteeism can be set for different periods. When applying coefficients or % absenteeism, values for each interval will be multiplied by specified coefficients.

4. Users can specify minimum operators (relevant for low-load lines that must have a certain minimum number of operators regardless of low utilization). When applying minimum operators, the system compares calculated operator count with minimum and, if calculated value is less than specified minimum, changes calculated value to specified minimum. For example, in interval 10:00-10:15 calculated operators = 0, in interval 10:15-10:30 calculated operators = 1, if user specified minimum 1 operator during this period, system should account for one operator in interval 10:00-10:15, leave interval 10:15-10:30 unchanged since value >= minimum.

5. When aggregating calculated data by hours, days, weeks, months, the following calculation logic is used:

**Table 4 - Data aggregation logic**

| Period | Aggregation Method | Display |
|--------|-------------------|---------|
| Hour | Average value across all intervals in hour | Person-hours needed to cover load in this hour |
| Days | Sum of values across all hourly intervals in day | Person-hours needed to cover load in this day |
| Weeks | Sum of values across all hourly intervals in week / number of days in week | Average person-hours needed to cover load each day of week |
| Month | Sum of values across all hourly intervals in month / number of days in month | Average person-hours needed to cover load each day of month |

**Important:**
- After calculating operator count data, user must save information
- When saving, if forecast already exists in DB for any forecasted intervals and group, system overwrites forecast values with current ones

---

## 3. Adding Operator Plans Through the "View Load" Page

The system implements the ability to import ready forecasts/plans for operators. This function is used when operator forecasts come from external sources, so there's no need to forecast load in the WFMCC system and calculate operator count.

The specified operator forecast in source format is presented as an hourly profile (operator count by hours) for weekdays and, separately, for weekends. Since the WFMCC system has system intervals less than an hour (5, 10, or 15 minutes), this hourly profile is divided into system intervals.

![Navigate to View Load Page](img/navigate_to_view_load_page.png)

**Figure 11 - Navigation to "View Load" page**

### Limitations:

- Correction of imported data is not implemented. In case of importing an erroneous file, a correct file will need to be imported again.
- For each group - simple (skill, split, queue) or aggregated (set of several simple groups) - a separate file with forecast will need to be uploaded.

### Action Sequence for Importing Call Volume Plan:

1. Go to "View Load" page
2. Fill parameters "Service", "Group", "Mode", "Period", and "Time Zone"
3. Click "gear" → "Import"

![Import Operator Plan](img/import_operator_plan_interface.png)

**Figure 12 - Importing operator plan**

4. Select import type (by intervals/by hours)
5. On "Data Input" tab:
   - Set days for load import
   - Fill parameters "Customer wait time, sec", "SL", "Average call processing time (AHT)"
   - Upload file with load data

![Upload Operator Data](img/upload_operator_data_interface.png)

**Figure 13 - Uploading operator data**

6. On "Verification" tab, check correctness of uploaded data and click "Save"

![Verify Upload Data](img/verify_uploaded_data_interface.png)

**Figure 14 - Verifying uploaded data**

### File Format Requirements for Import:

**Table 5 - Operator plan import file format**

| A | B |
|---|---|
| 100 | 10 |

**File Column Descriptions:**
- Columns A and B data must be mandatory (when importing only operators, column A should be 0)
- Columns A and B data must be in numeric format, values can be 0, whole or decimal (through period or comma)
- File must have 24 rows. Each row represents an hour in ascending order. Row 1 should have data for interval 00:00-01:00, row 2 should have data for interval 01:00-02:00, etc.

**Table 6 - Operator plan upload template by hours**

| № | Description | Document |
|---|-------------|----------|
| 1 | Template for uploading operators to system (xls, xlsx) by hours | ![Operator Plan Template](img/operator_plan_upload_template_hours.png) |

### Import Logic Description:

- Excel file with call count and operators is uploaded for a specific group - simple or aggregated
- During import, there's an option to select days for forecast upload. Selection includes settings allowing choice of all days in month that are according to production calendar:
  - Weekdays
  - Weekends and holidays
- When importing hourly intervals, system divides them into smaller system intervals (5, 10, or 15 minutes depending on system settings)
- System implements the following data division logic:
  - **Call count** - specified number must be divided by number of system intervals in one hour
    
    *Example: first row, interval 00:00-01:00 shows 123 calls. If system is configured for 5-minute intervals, then each 5-minute interval in this hour (00:00-00:05, 00:05-00:10, etc.) should have 123/12=10.25 calls*
  
  - **Operator count** - specified number should be in each system interval in hour
    
    *Example: first row, interval 00:00-01:00 shows 123 operators. If system is configured for 5-minute intervals, then each 5-minute interval in this hour (00:00-00:05, 00:05-00:10, etc.) should have 123 operators*

- After import, data is displayed as:
  - Table with time intervals in rows and call count, operator count in columns
  - Graphs for call count, operator count (each point on graphs represents interval value)
- System provides aggregation modes for calculated data by hours, days, weeks, months. Aggregated data is displayed in tabular and graphical form similar to source data.
- For calls during aggregation, call count is summed across all intervals included in aggregated interval.
- When aggregating operators by hours, days, weeks, months, the following calculation logic is used:

| Period | Aggregation Method | Display |
|--------|-------------------|---------|
| Hour | Average value across all intervals in hour | Number of operators needed to cover load in this hour |
| Days | Sum of values across all hourly intervals in day / shift length per day (e.g., 8 hours) | Number of operators needed to cover load in this day |
| Weeks | Sum of values across all hourly intervals in week / shift length per week (e.g., 40 hours) | Number of operators needed to cover load in this week |
| Month | Sum of values across all hourly intervals in month / shift length per month (e.g., 168 hours) | Number of operators needed to cover load in this month |

**Important:**
- When saving, if forecast already exists in DB for any forecasted intervals and group, system overwrites forecast values with current ones.