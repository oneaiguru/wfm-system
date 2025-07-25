    1: # Methods for Obtaining Demand in the ARGUS WFM CC System
    2: 
    3: ## Table of Contents
    4: 
    5: [Introduction](#introduction)
    6: 
    7: [1. Load Forecasting Through the "Forecast Load" Page](#1-load-forecasting-through-the-forecast-load-page)
    8: 
    9: [2. Adding Call Volume Plans for Operator Calculation Through the "Import Forecasts" Page](#2-adding-call-volume-plans-for-operator-calculation-through-the-import-forecasts-page)
   10: 
   11: [3. Adding Operator Plans Through the "View Load" Page](#3-adding-operator-plans-through-the-view-load-page)
   12: 
   13: ---
   14: 
   15: ## Introduction
   16: 
   17: Figure 1 presents the scheme for obtaining/loading operator requirements in the ARGUS WFM CC system.
   18: 
   19: ![Operator Requirements Schema](img/operator_requirements_workflow_schema.png)
   20: 
   21: **Figure 1 - Schema for obtaining operator requirements in the ARGUS WFM CC system**
   22: 
   23: ---
   24: 
   25: ## 1. Load Forecasting Through the "Forecast Load" Page
   26: 
   27: This system module performs load forecasting based on historical data that is preliminarily analyzed and corrected.
   28: 
   29: ### General Requirements:
   30: 
   31: - Forecasting and calculation of operator requirements in the system is performed at the group level (both simple and aggregated groups).
   32: 
   33: - Group selection must be performed at the stage of working with historical data that will participate in forecast formation.
   34: 
   35: - To form a forecast, the user must specify the forecasting period. The forecasting period is unlimited.
   36: 
   37: - Forecasting and calculation of operator requirements is performed at the interval level (interval is set during system implementation, typically equal to 5, 10, or 15 minutes).
   38: 
   39: - Calculation of operator requirements is performed based on forecasted data.
   40: 
   41: ![Navigate to Forecast Load Page](img/navigate_to_forecast_load_page.png)
   42: 
   43: **Figure 2 - Navigation to "Forecast Load" page**
   44: 
   45: ### Forecasting Algorithm
   46: 
   47: The forecasting algorithm is divided into several stages:
   48: 
   49: - Smoothing peaks (outliers) in historical data
   50: - Trend determination
   51: - Seasonal coefficient determination (yearly, monthly, weekly, daily)
   52: - Calculation of forecasted values in intervals considering trend and seasonal components
   53: 
   54: ![Load Forecasting Algorithm](img/load_forecasting_algorithm_flowchart.png)
   55: 
   56: **Figure 3 - Load forecasting algorithm**
   57: 
   58: ### Historical Data Acquisition
   59: 
   60: The system can obtain historical data for groups in two ways:
   61: 
   62: **1. Data from the Customer's source system (with integration):**
   63: To request data via integration, click the "gear" → "Request data". Historical data will be received for the period specified in the "Parameters" block.
   64: 
   65: **2. Manual data upload via Excel document:**
   66: To manually upload historical data, click the "gear" → "Import".
   67: 
   68: **Table 1 - Historical data upload template**
   69: 
   70: | № | Description | Document |
   71: |---|-------------|----------|
   72: | 1 | Template for manually uploading historical data to the system | ![Historical Data Template](img/historical_data_upload_template.png) |
   73: 
   74: Before moving from the "Historical Data Correction" tab to the next "Peak Analysis" tab, you must save the received historical data by clicking "gear" → "Save".
   75: 
   76: ![Import Historical Data](img/import_load_historical_data_interface.png)
   77: 
   78: **Figure 4 - Import/loading historical data**
   79: 
   80: ### Requirements for Aggregated Forecast Formation
   81: 
   82: - The WFM CC system has the ability to create an aggregated group that includes simple groups.
   83: - For each simple group, historical data enters the WFM CC system from the corresponding Customer source system (with integration).
   84: - When working with historical data for an aggregated group, the system sums historical data for all calls from all simple groups included in the aggregated group. Average talk time and post-processing time are calculated as weighted averages across all simple groups, using the number of calls in the interval as weight.
   85: - To recalculate data for an aggregated group, click "gear" → "Recalculate data".
   86: 
   87: ![Recalculate Aggregated Group Data](img/recalculate_aggregated_group_data.png)
   88: 
   89: **Figure 5 - Recalculating data for aggregated group**
   90: 
   91: - When forecasting load, generated forecasts relate to the aggregated group. The forecasting methodology is the same as for simple groups - using a trend-seasonal model.
   92: - When calculating operator requirements, generated data relates to the aggregated group.
   93: - Results of calculations for aggregated forecasts and calculated operator requirements are displayed in tabular and graphical form, same as forecasts for simple groups.
   94: 
   95: ### Use Case: Forecasting Load for Higher Call Volume with Same Load Distribution
   96: 
   97: **Given:**
   98: - We have historical data/plan by intervals for 1,000 calls
   99: 
  100: **Required:**
  101: - Obtain a plan/forecast for a future period for 5,000 calls with the same load distribution
  102: 
  103: **Steps:**
  104: 1. Go to "Forecast Load" page
  105: 2. Fill parameters: "Service", "Group", "Schema", "Period", "Time Zone" and click "Apply"
  106: 3. Step by step, set necessary settings on tabs: "Historical Data Correction", "Peak Analysis", "Trend Analysis", "Seasonal Components Analysis"
  107: 4. On the "Traffic and AHT Forecasting" tab in the "Forecasting" block, set the period for which load needs to be forecasted
  108: 
  109: ![Select Forecasting Period](img/select_forecasting_period_interface.png)
  110: 
  111: **Figure 6 - Selecting forecasting period**
  112: 
  113: 5. To obtain a plan/forecast with the same load distribution but higher call volume (5,000), on the "Traffic and AHT Forecasting" tab, click "gear" in the "Forecast" block → "Growth Factor"
  114: 6. In the "Period" parameter, specify the period for which the growth factor will be calculated (01.11.2023 – 31.12.2023)
  115: 7. In the "Growth Factor" parameter, specify the load increase factor (5)
  116: 
  117: ![Apply Growth Factor](img/apply_growth_factor_interface.png)
  118: 
  119: **Figure 7 - Applying growth factor**
  120: 
  121: ---
  122: 
  123: ## 2. Adding Call Volume Plans for Operator Calculation Through the "Import Forecasts" Page
  124: 
  125: The system implements the ability to import call volume plans on the "Import Forecasts" page. This function is used when the WFM CC system needs to load call plans and calculate the required number of operators to cover the load, as well as plan work schedules.
  126: 
  127: ![Navigate to Import Forecasts](img/navigate_to_import_forecasts_page.png)
  128: 
  129: **Figure 8 - Navigation to "Import Forecasts" page**
  130: 
  131: For each group (skill, split, queue), a separate file with forecast and operator calculations will need to be uploaded.
  132: 
  133: ![Call Volume Plan Upload Form](img/call_volume_plan_upload_form.png)
  134: 
  135: **Figure 9 - Form for uploading call volume plan (by intervals)**
  136: 
  137: ### File Format Requirements for Call Import
  138: 
  139: **Table 2 - Call import file format**
  140: 
  141: | A | B | C |
  142: |---|---|---|
  143: | Time interval start | Number of calls | AHT, sec |
  144: | DD.MM.YYYY hh:mm | 10 | 100 |
  145: 
  146: **File Column Descriptions:**
  147: - Columns A and B data must be mandatory
  148: - Column A data must be in date and time format:
  149:   - DD.MM.YYYY hh:mm
  150:   - YYYY.MM.DD hh:mm
  151: - Columns B and C data must be in numeric format
  152: 
  153: **Table 3 - Call volume plan upload template by intervals**
  154: 
  155: | № | Description | Document |
  156: |---|-------------|----------|
  157: | 1 | Template for uploading calls to system (xls, xlsx) by intervals | ![Call Volume Template](img/call_volume_upload_template_intervals.png) |
  158: 
  159: ![Calculate Operators Based on Call Plan](img/calculate_operators_from_call_plan.png)
  160: 
  161: **Figure 10 - Calculating number of operators based on call volume plan**
  162: 
  163: ### Operator Calculation Requirements
  164: 
  165: 1. After importing forecast values, the system can calculate the required number of operators to cover the load.
  166: 
  167: 2. Calculation formulas are analogous to formulas used on the "Forecast Load" page.
  168: 
  169: 3. When working with calculated data, users can adjust the calculated operator requirements using increasing or decreasing coefficients or % absenteeism (% of absent operators, e.g., due to illness). Users can specify correction periods down to intervals, as well as coefficient magnitude or % absenteeism - different coefficient magnitudes or % absenteeism can be set for different periods. When applying coefficients or % absenteeism, values for each interval will be multiplied by specified coefficients.
  170: 
  171: 4. Users can specify minimum operators (relevant for low-load lines that must have a certain minimum number of operators regardless of low utilization). When applying minimum operators, the system compares calculated operator count with minimum and, if calculated value is less than specified minimum, changes calculated value to specified minimum. For example, in interval 10:00-10:15 calculated operators = 0, in interval 10:15-10:30 calculated operators = 1, if user specified minimum 1 operator during this period, system should account for one operator in interval 10:00-10:15, leave interval 10:15-10:30 unchanged since value >= minimum.
  172: 
  173: 5. When aggregating calculated data by hours, days, weeks, months, the following calculation logic is used:
  174: 
  175: **Table 4 - Data aggregation logic**
  176: 
  177: | Period | Aggregation Method | Display |
  178: |--------|-------------------|---------|
  179: | Hour | Average value across all intervals in hour | Person-hours needed to cover load in this hour |
  180: | Days | Sum of values across all hourly intervals in day | Person-hours needed to cover load in this day |
  181: | Weeks | Sum of values across all hourly intervals in week / number of days in week | Average person-hours needed to cover load each day of week |
  182: | Month | Sum of values across all hourly intervals in month / number of days in month | Average person-hours needed to cover load each day of month |
  183: 
  184: **Important:**
  185: - After calculating operator count data, user must save information
  186: - When saving, if forecast already exists in DB for any forecasted intervals and group, system overwrites forecast values with current ones
  187: 
  188: ---
  189: 
  190: ## 3. Adding Operator Plans Through the "View Load" Page
  191: 
  192: The system implements the ability to import ready forecasts/plans for operators. This function is used when operator forecasts come from external sources, so there's no need to forecast load in the WFMCC system and calculate operator count.
  193: 
  194: The specified operator forecast in source format is presented as an hourly profile (operator count by hours) for weekdays and, separately, for weekends. Since the WFMCC system has system intervals less than an hour (5, 10, or 15 minutes), this hourly profile is divided into system intervals.
  195: 
  196: ![Navigate to View Load Page](img/navigate_to_view_load_page.png)
  197: 
  198: **Figure 11 - Navigation to "View Load" page**
  199: 
  200: ### Limitations:
  201: 
  202: - Correction of imported data is not implemented. In case of importing an erroneous file, a correct file will need to be imported again.
  203: - For each group - simple (skill, split, queue) or aggregated (set of several simple groups) - a separate file with forecast will need to be uploaded.
  204: 
  205: ### Action Sequence for Importing Call Volume Plan:
  206: 
  207: 1. Go to "View Load" page
  208: 2. Fill parameters "Service", "Group", "Mode", "Period", and "Time Zone"
  209: 3. Click "gear" → "Import"
  210: 
  211: ![Import Operator Plan](img/import_operator_plan_interface.png)
  212: 
  213: **Figure 12 - Importing operator plan**
  214: 
  215: 4. Select import type (by intervals/by hours)
  216: 5. On "Data Input" tab:
  217:    - Set days for load import
  218:    - Fill parameters "Customer wait time, sec", "SL", "Average call processing time (AHT)"
  219:    - Upload file with load data
  220: 
  221: ![Upload Operator Data](img/upload_operator_data_interface.png)
  222: 
  223: **Figure 13 - Uploading operator data**
  224: 
  225: 6. On "Verification" tab, check correctness of uploaded data and click "Save"
  226: 
  227: ![Verify Upload Data](img/verify_uploaded_data_interface.png)
  228: 
  229: **Figure 14 - Verifying uploaded data**
  230: 
  231: ### File Format Requirements for Import:
  232: 
  233: **Table 5 - Operator plan import file format**
  234: 
  235: | A | B |
  236: |---|---|
  237: | 100 | 10 |
  238: 
  239: **File Column Descriptions:**
  240: - Columns A and B data must be mandatory (when importing only operators, column A should be 0)
  241: - Columns A and B data must be in numeric format, values can be 0, whole or decimal (through period or comma)
  242: - File must have 24 rows. Each row represents an hour in ascending order. Row 1 should have data for interval 00:00-01:00, row 2 should have data for interval 01:00-02:00, etc.
  243: 
  244: **Table 6 - Operator plan upload template by hours**
  245: 
  246: | № | Description | Document |
  247: |---|-------------|----------|
  248: | 1 | Template for uploading operators to system (xls, xlsx) by hours | ![Operator Plan Template](img/operator_plan_upload_template_hours.png) |
  249: 
  250: ### Import Logic Description:
  251: 
  252: - Excel file with call count and operators is uploaded for a specific group - simple or aggregated
  253: - During import, there's an option to select days for forecast upload. Selection includes settings allowing choice of all days in month that are according to production calendar:
  254:   - Weekdays
  255:   - Weekends and holidays
  256: - When importing hourly intervals, system divides them into smaller system intervals (5, 10, or 15 minutes depending on system settings)
  257: - System implements the following data division logic:
  258:   - **Call count** - specified number must be divided by number of system intervals in one hour
  259:     
  260:     *Example: first row, interval 00:00-01:00 shows 123 calls. If system is configured for 5-minute intervals, then each 5-minute interval in this hour (00:00-00:05, 00:05-00:10, etc.) should have 123/12=10.25 calls*
  261:   
  262:   - **Operator count** - specified number should be in each system interval in hour
  263:     
  264:     *Example: first row, interval 00:00-01:00 shows 123 operators. If system is configured for 5-minute intervals, then each 5-minute interval in this hour (00:00-00:05, 00:05-00:10, etc.) should have 123 operators*
  265: 
  266: - After import, data is displayed as:
  267:   - Table with time intervals in rows and call count, operator count in columns
  268:   - Graphs for call count, operator count (each point on graphs represents interval value)
  269: - System provides aggregation modes for calculated data by hours, days, weeks, months. Aggregated data is displayed in tabular and graphical form similar to source data.
  270: - For calls during aggregation, call count is summed across all intervals included in aggregated interval.
  271: - When aggregating operators by hours, days, weeks, months, the following calculation logic is used:
  272: 
  273: | Period | Aggregation Method | Display |
  274: |--------|-------------------|---------|
  275: | Hour | Average value across all intervals in hour | Number of operators needed to cover load in this hour |
  276: | Days | Sum of values across all hourly intervals in day / shift length per day (e.g., 8 hours) | Number of operators needed to cover load in this day |
  277: | Weeks | Sum of values across all hourly intervals in week / shift length per week (e.g., 40 hours) | Number of operators needed to cover load in this week |
  278: | Month | Sum of values across all hourly intervals in month / shift length per month (e.g., 168 hours) | Number of operators needed to cover load in this month |
  279: 
  280: **Important:**
  281: - When saving, if forecast already exists in DB for any forecasted intervals and group, system overwrites forecast values with current ones.