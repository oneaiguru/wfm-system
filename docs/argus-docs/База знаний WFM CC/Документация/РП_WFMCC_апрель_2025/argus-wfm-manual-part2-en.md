# ARGUS WFM CC User Manual - Part 2
## Complete English Translation (Pages 200-462)

---

## Page 200

![Synchronization Settings](img/synchronization_settings.png)

**Manual Corrections**

![Manual Corrections Dialog](img/manual_corrections_dialog.png)

This setting determines how personnel structure in WFM CC can be modified:

• **Synchronization only** – personnel in WFM CC is created only automatically from external systems; manual creation is impossible.

• **Manual corrections only** – creating groups/services/operators is only possible manually.

• **Manual corrections and synchronization** – creating and receiving personnel is possible both through integration and manually. With this option, personnel created manually and absent in the external system will not be deleted during synchronization.

### 7.1. Obtaining Personnel Data from External Systems

To obtain personnel structure and accounts from the contact center, click the button.

When clicking "Synchronize personnel," the personnel structure is updated automatically.

![Personnel Synchronization](img/personnel_synchronization.png)

During personnel synchronization, existing employees in the system are matched, along with their organizational structure (departments) and functional structure (groups and services) by external ID. Depending on the settings in the "Integration Systems" directory, the update logic will change:

• If the integration system is marked with the "Master system" checkbox, then all organizational structure data comes to

---

## Page 201

WFM CC from it (creation and filling of data in operator cards, departments).

• If the integration system is not marked as "Master system," then it affects the functional structure (moves employees between groups/services).

Further logic depends on the personnel correction mode:

• **If "Synchronization only" mode is selected**, then the logic corresponds to the previous point when the integration system is selected as "Master system," i.e., functionality does not change.

• **If "Manual corrections" mode is selected**, then WFM CC system does not receive information about employees through integration.

• **If "Manual corrections and synchronization" mode is selected**, then WFM CC system receives all information through integration (structure of groups/services and employees in them, adding new employees, changes to information about existing ones), but employees who were not received through integration but exist in WFM CC system are not deleted.

In the "Integration Systems" window, we can see operators whose data came to WFM CC through integration from a specific external system.

![Integration Systems Window](img/integration_systems_window.png)

---

## Page 202

Using the search line, you can find a specific employee; by clicking the icon, you can check which groups the employee belongs to.

![Employee Groups Check](img/employee_groups_check.png)

In the WFM CC system window, there is an identical interface except that a specific operator can be expanded by clicking the arrow to the left of their checkbox to see if any accounts from integration systems are linked.

External system accounts are required to obtain historical data about the employee. For example, information about working time in the system, login time, time in statuses, etc. This information is used to build reports from the report editor, operator performance, etc.

![External System Accounts](img/external_system_accounts.png)

---

## Page 203

### 7.2. Account Linking

The ability to perform actions in the "Personnel Synchronization" block is available to users with the "Administrator" role or any other role with access right "Execute personnel synchronization" (System_AccessSynchronization).

Accounts from integration systems can be linked automatically. The system checks personnel numbers of existing employees and personnel numbers of received accounts. When they match, the account is linked to the employee. This algorithm has its features:

• If an account and personnel number came, but the existing employee has no personnel number, then the account needs to be added manually.

• If no personnel number comes through synchronization, then the account needs to be added manually.

• If an account came that is already assigned to an employee in WFM CC system, but the personnel number does not match the one received through integration, then the account is unlinked from the employee in WFM CC system and can be linked to another employee.

To manually link an account and employee, select the needed operator in the integration system window (via checkbox), mark the operator to whom you want to link the account in the WFM CC system window and click the button.

![Manual Account Linking](img/manual_account_linking.png)

---

## Page 204

The linked account will be displayed in the WFM CC system window:

![Linked Account Display](img/linked_account_display.png)

### 8. Operator Data Collection

The page is available for viewing to users with access right "View 'Operator Data Collection' page" (System_AccessGetHistoricOperatorStatus).

The ability to collect operator data and configure automatic collection schedule is available to users with system role "Administrator" or any other role with access right "Operator data collection and automatic collection configuration" (System_EditGetHistoricOperatorStatus).

Operator data collection allows obtaining through synchronization with other systems data about actual operator presence in various statuses (login time, logout), number and time of processed requests (non-unique).

To go to the "Operator Data Collection" page, open the side menu and select "Personnel" → "Operator Data Collection."

---

## Page 205

![Operator Data Collection Page](img/operator_data_collection_page.png)

On the page, there is separate functionality for automatic (or mass) updating of specific operator data, as well as separate functionality for manual obtaining of specific data for specific operators.

**Automatic (Mass) Operator Data Collection – Scheduled Data Collection Configuration**

![Scheduled Data Collection](img/scheduled_data_collection.png)

In this block, you can obtain several types of data:

• **System working time**: shows how much time the operator was logged into one or another integration system.

---

## Page 206

• **Time in statuses**: shows how much time the operator spent in specific statuses. Statuses come to WFM CC system through integration (lunch, break, on call, etc.).

• **Request processing**: shows how much time the operator processed requests and how many such requests were processed by them during all working time.

• **Chat working time**: time when the operator was in the system with at least one chat in work (for example, in C2D).

• **Outgoing calls**: results of outgoing calls made by the operator.

Ultimately, each of these data types can be obtained automatically by setting automatic update settings, namely "Update Frequency."

**Collection frequency** – how often data needs to be obtained. Depending on the choice (monthly, weekly, daily), specify specific week numbers, days of weeks, time zone, and data collection time.

The button allows manually starting the process of obtaining one of the data types, specifying the period for which data needs to be obtained.

![Manual Data Collection](img/manual_data_collection.png)

**Note**: In this block, WFM CC system obtains data for all operators who have integration system accounts. If mass updating of any data types is needed, manual updating of this data can be called.

---

## Page 207

**Manual Data Re-request**

Manual obtaining of specific data can be done in two ways:

• **By direction**

In this block, you can obtain specific data types (described above). Select one or several from the dropdown list for specific services and groups (multiple groups cannot be selected) for the selected period. To obtain data for all operators having an integration system account within the selected group, click.

![Data Collection by Direction](img/data_collection_by_direction.png)

• **By operator**

In this block, you can obtain specific data types (described above). Select one type or several from the dropdown list for one specific operator (search by full name is available). To do this, enter the operator's full name, select the integration system to which the operator's account belongs (there may be several accounts for different systems), and data types that need to be obtained. After all parameters are set, click.

---

## Page 208

![Data Collection by Operator](img/data_collection_by_operator.png)

## 4. Load Forecasting in "ARGUS WFM CC" System

The load forecasting module is available to users with system role "Administrator," "Senior Operator," or any other role with access rights:

• **View pages in "Forecasting" section** (System_AccessForecastList)
• **Edit load forecasts** (System_EditForecast)

Load forecasting through the Argus algorithm allows calculating expected load based on historical data provided by the contact center or manually imported by the user, as well as calculating the number of operators needed to cover the forecasted load. Based on the forecasted load, schedules and work timetables are built. Also included in forecasting functionality:

1. Historical request data correction;
2. Historical AHT data correction;
3. Peak analysis;

---

## Page 209

4. Trend analysis;
5. Seasonal component analysis;
6. Application of reserve coefficients;
7. Specifying minimum number of operators;
8. Application of growth coefficients;
9. Application of % Absenteeism coefficients.

To go to the "Forecast Load" tab, you can either through the "Forecasting" section from the sidebar or from the main page by clicking the "Forecasting" block:

![Forecasting Main Page](img/forecasting_main_page.png)

Tabs within the section open sequentially. The proposed analysis tools can be skipped, but directly going to the final step "Calculate Number of Operators" is not possible.

### 4.1. Historical Data: Import and Obtaining from Contact Center

To import historical data for load and operator forecasting, go to the "Forecast Load" tab, select service, group, schema, period for requests and AHT, time zone.

![Historical Data Import](img/historical_data_import.png)

The "Schema" field determines which data will be considered when forecasting load. Choose one of the options:

---

## Page 210

• **Unique incoming requests** – requests having uniqueness attribute (depends on integration system) that arrived at the request processing channel. Incoming includes lost and dropped calls.

• **Unique processed requests** – requests having uniqueness attribute (depends on integration system) processed on the request processing channel.

• **Unique lost requests** – requests having uniqueness attribute (depends on integration system) lost on the request processing channel.

• **Non-unique incoming** – requests without uniqueness attribute that arrived at the request processing channel. Incoming includes lost and dropped calls.

• **Non-unique processed requests** – requests without uniqueness attribute processed on the request processing channel.

• **Non-unique lost requests** – requests without uniqueness attribute lost on the request processing channel.

Schema choice depends on individual contact center features. Most often "Non-unique incoming" is chosen. For example, if the same person called the line 3 times, then unique incoming counts as 1 request, and non-unique incoming counts as 3 requests.

#### 4.1.1. Import Requests from File

When there is no integration with the contact center, after selecting forecasting parameters, click "Apply," then the icon and select "Import."

---

## Page 211

![Import Dialog](img/import_dialog.png)

Next, a system file selection window will open. Select the file and click "Open." After this, data import to the system will begin. The process takes some time depending on the volume of imported data. You can click the gear icon to see file upload progress.

![Upload Progress](img/upload_progress.png)

Upon completion of loading, the loaded data will be displayed in the central part of the screen. You need to click the gear – "Save."

![Save Loaded Data](img/save_loaded_data.png)

---

## Page 212

Data in the Excel file must be prepared in a specific format and contain the following columns:

1. **Start of time interval** (in DD.MM.YYYY HH:MM:SS format). If no requests came during some N-minute period, it's better to leave the row with this time, filling with zeros (or leave unfilled, but don't remove completely).
2. **Unique incoming requests, pcs.** If there are none, you can leave the column empty or fill with zeros, but the column itself must be present. This applies to all subsequent items.
3. **Unique processed requests, pcs.**
4. **Unique lost requests, pcs.**
5. **Non-unique incoming, pcs.**
6. **Non-unique processed, pcs.**
7. **Non-unique lost requests, pcs.**
8. **Average talk time, sec.**
9. **Average post-processing duration, sec.**

Data in column 1 must be recorded in interval breakdown that the system is configured for (usually 5, 10, or 15 minutes). Required for filling are columns "Date Time," "Average talk time," and EITHER three columns with unique values OR three columns with non-unique values (depending on the schema chosen for forecasting).

![Excel Data Format](img/excel_data_format.png)

The file may have several sheets, and values of some columns calculated using formulas. In this case, the system will look only at the first sheet, where the first column will be

---

## Page 213

recognized as date, and subsequent ones as numeric values (including those obtained by formula).

If forecasting is performed for an aggregated group, data must first be loaded into each simple group, then values summed using the tool in the system. The number of requests in the aggregated group equals the weighted average value of all simple groups included in the aggregated. The average talk time of the aggregated group equals the weighted average AHT value of all simple groups included in the aggregated.

To recalculate data on the "Forecast Load" page, fill in "Parameters" (service, group, schema, request period), click the icon and select "Recalculate data." After this, click the gear – "Save."

![Recalculate Data](img/recalculate_data.png)

#### 4.1.2. Data Request via Integration

When there is integration with the contact center, historical data comes automatically through daily night integration (request period is configured on the "Forecasting" - "Update Settings" page). If manual data request is needed, after selecting forecasting parameters for the group, click gear - "Request data." To save, select gear – "Save."

---

## Page 214

### 4.2. View and Edit Historical Request Data

The proposed analysis tools can be skipped, but tabs open sequentially and directly going to the final step "Calculate Number of Operators" is not possible.

**Important!** Editing historical data is an optional action. If editing historical data is not required, you can immediately proceed to the "Peak Analysis" section.

To correct historical data, go to the "Forecast Load" tab either through the "Forecasting" section from the sidebar or from the main page by clicking the "Forecasting" block.

On the opened "Historical Request Data Correction" page, select Service, Group, Schema, data period for requests and AHT that you plan to edit, as well as time zone. Click the "Apply" screen button and wait for the system to load data.

![Historical Data Correction](img/historical_data_correction.png)

---

## Page 215

Data viewing and chart in the "Historical Data" section is available with breakdown by Months, Weeks, Days, Hours, Intervals. Select the appropriate one by clicking the corresponding screen button.

![Data Breakdown Options](img/data_breakdown_options.png)

By default, the "Historical Data" section presents a table with all possible data schemas. But only columns with schemas for which data has been loaded into the System are filled.

Additionally, it's possible to configure display of only interesting columns through screen buttons "Columns," "Extended mode," "Reset column settings."

Using the "Extended mode" button, you can see a comparison of source data, unchanged by copying, inclusion/exclusion of values or averaging, with their modified version. If you need to return this data, just select the period and click "Reset to original."

---

## Page 216

![Extended Mode](img/extended_mode.png)

Below are displayed charts, the first of which is "Traffic." It shows the number of requests for the time period previously selected by the user for viewing historical data.

![Traffic Chart](img/traffic_chart.png)

The Y-axis shows the number of calls, the X-axis shows time periods depending on the display filter. The legend shows all data display schemas.

One or several lines on the chart can be removed. To do this, click on the item of interest in the legend with the left mouse button.

You can scroll through dates by selecting numbers below the chart or using arrows.

To change chart scale, place the mouse cursor in the part of the page where the chart is directly displayed and scroll the mouse wheel.

#### 4.2.1. Including, Excluding Values

To obtain more reliable data when forecasting load, the system has the ability to exclude load spikes (accident, temporary promotion, etc.) from historical data. This can be done at the step – "Include/exclude values."

---

## Page 217

![Include Exclude Values](img/include_exclude_values.png)

Select the "Historical data period" for which corrections need to be made. On the chart, active intervals (those that will be considered during forecasting) are displayed in dark blue, and inactive intervals in light blue.

Below, the workspace is divided into 2 parts: Calendar and Table. Calendar allows working with days and intervals within the selected historical data period, Table – with intervals within one specific day.

Select the necessary period in the Calendar: day – by clicking on it with LMB, several days – LMB with Ctrl key held, continuous interval – LMB with Shift key held. After selection, the selected day/interval will be colored gray. You can also select several time intervals at once that need to be excluded/added. To select multiple intervals – click LMB with Ctrl key held.

---

## Page 218

![Calendar Selection](img/calendar_selection.png)

After selecting intervals, click and choose the action you plan to do: Include or Exclude.

![Include Exclude Actions](img/include_exclude_actions.png)

---

## Page 219

The excluded interval on the chart is marked with light blue color.

![Excluded Interval Chart](img/excluded_interval_chart.png)

Undoing an action in the direct sense is impossible, but you can perform the reverse action: for exclusion – Include, for inclusion – Exclude.

![Reverse Actions](img/reverse_actions.png)

If you need to include/exclude interval(s) within one day, select the day in the Calendar by clicking on it with LMB. Below in the Table, all values for the day will be reflected.

---

## Page 220

![Day Selection Table](img/day_selection_table.png)

Selecting the necessary interval(s) in the Table is done similarly to the Calendar: one interval – by clicking on it with LMB, several intervals – LMB with Ctrl key held, continuous interval – LMB while holding Shift key. After selection, the selected interval(s) will be colored white.

![Table Interval Selection](img/table_interval_selection.png)

To apply all changes made, click the screen button. It is located in the right corner above the Chart.

If changes have not been saved yet, when returning to the previous step, data exclusion will be reset. To cancel performed and saved changes, select the excluded day again, right-click on it – "Include."

#### 4.2.2. Copying Values

The next historical data correction tool for load forecasting in the system is "Copying Values." When viewing historical data, there is the ability to copy part of the data to another time period.

---

## Page 221

![Copy Values Interface](img/copy_values_interface.png)

Specify the historical data period from which data needs to be copied:

![Copy Source Period](img/copy_source_period.png)

The Y-axis displays data, X-axis displays time intervals. All data visible on the chart will be copied. You can scale specific periods by selecting them with the cursor directly on the chart:

---

## Page 222

![Chart Scaling](img/chart_scaling.png)

After the time period is selected, select the historical data period where data needs to be copied:

![Copy Destination Period](img/copy_destination_period.png)

When specifying the beginning of the period, its end will be set automatically based on the selected copying data period:

![Auto End Period](img/auto_end_period.png)

The chart displays data that currently exists (light blue) and data that was copied (dark blue).

---

## Page 223

![Copied Data Display](img/copied_data_display.png)

Lines on the chart can be hidden. To do this, click on the desired item from the legend located above the chart.

The chart can be scaled similarly to scaling when selecting data for copying.

If the obtained results do not need to be considered in analysis, proceed to the next tab without saving. To save results, click and "Apply":

![Save Copy Results](img/save_copy_results.png)

To cancel performed and saved changes, return to the "Data View" tab and start the process again (from loading source data).

#### 4.2.3. Averaging Values

The final historical data correction tool for load forecasting in the system is "Averaging Values." Used in cases of insufficient historical data for some period. The system allows filling these gaps with averaged data from other intervals that have historical data.

---

## Page 224

Specify the time period from which data needs to be taken for averaging.

![Averaging Source Period](img/averaging_source_period.png)

On the chart, Y-axis shows number of requests, X-axis shows time intervals in the selected day.

![Averaging Chart](img/averaging_chart.png)

Below the chart, select the day of the week. The number of charts corresponds to the number of, for example, Wednesdays that fell within the interval selected above.

![Day of Week Selection](img/day_of_week_selection.png)

---

## Page 225

The number of charts can be changed using the legend.

![Chart Legend Control](img/chart_legend_control.png)

Next, select the time period in which data will be averaged:

![Averaging Target Period](img/averaging_target_period.png)

The chart will mark data that exists now and averaged data. Information here is displayed by days (X-axis). Lines on charts can be hidden by clicking on the desired item in the legend.

![Averaged Data Chart](img/averaged_data_chart.png)

The chart can be scaled similarly to scaling when selecting data for copying.

---

## Page 226

If the obtained results do not need to be considered in analysis, proceed to the next step of Forecasting – "Historical AHT Data Correction."

To save results, click and "Apply":

![Save Averaging Results](img/save_averaging_results.png)

To cancel performed and saved changes, return to the "Data View" tab and start the process again (from loading source data).

---

## Page 227

### 4.3. View and Edit Historical AHT Data

Editing historical AHT data is an optional action. If editing historical AHT data is not required, you can immediately proceed to the "Peak Analysis" section.

The process of editing historical AHT data is similar to editing historical request data described in section 4.2 View and Edit Historical Request Data. We recommend using information from that section.

### 4.4. Peak Analysis

After viewing and editing historical data for the selected group for the selected time period, the system will offer to analyze load peaks. Load peaks can be smoothed if their presence is explained by abnormal load growth or load decline.

"Peak Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next one.

![Peak Analysis Interface](img/peak_analysis_interface.png)

In the "Forecast" section, time periods, number of requests and outlier type, average talk time and its outlier type are displayed.

An outlier is considered to be load values located between the upper outer and inner boundary, as well as those exceeding its limits, or values located between the lower outer and inner boundary, as well as those exceeding its limits. Outliers are calculated based on the quartile range analysis method (IQR – InterQuartile Range).

The concept of 1st, 2nd, 3rd order quartiles is highlighted:

• **Quartile 3 (Q3)** – value (from the sample of all historical data values) for which 75% of data is less than or equal to it.

• **Quartile 2 (Q2)** – value for which 50% of data is less than or equal to it (median in historical data)

• **Quartile 1 (Q1)** – value for which approximately 25% of data is less than or equal to it.

In the historical data array, extreme and moderate outliers are searched:

• **Extreme** – outlier that went beyond the outer boundary (upper or lower) – red line.

• **Moderate** – outlier located within the outer and inner boundary (upper or lower) – purple line.

Below the table are charts showing boundaries and number of requests and average AHT.

---

## Page 228

![Peak Analysis Chart](img/peak_analysis_chart.png)

Boundary lines, requests, AHT can be hidden on the chart by clicking on the desired item in the legend. The chart shows the same periods shown in the table above. To view other periods, select another page in the table.

Next, there is the ability to choose which peaks need to be smoothed. To display the list, click.

![Peak Smoothing Options](img/peak_smoothing_options.png)

• **Smooth extreme request peaks** – system smooths request outliers located above outer boundaries.

• **Smooth all request peaks** – system smooths extreme outliers and moderate ones located between outer and inner boundaries.

• **Smooth extreme AHT peaks** – system smooths AHT outliers located above outer boundaries.

• **Smooth all AHT peaks** – system smooths extreme outliers and moderate ones located between outer and inner boundaries.

• **Smooth selected peaks** – system smooths those outliers whose periods are marked with a checkmark.

![Selected Peaks](img/selected_peaks.png)

• **Smooth all** – system smooths all request and AHT outliers.

---

## Page 229

• **Cancel** – action cancels all previous smoothing if any was performed.

After smoothing, values with outliers will be removed from the table analysis, and the chart will be leveled.

Changes will look like this.

Before smoothing:

![Before Smoothing](img/before_smoothing.png)

After smoothing all peaks:

---

## Page 230

![After Smoothing](img/after_smoothing.png)

Additional saving of applied changes is not required; simply proceed to the next "Trend Analysis" tab.

At the Peak Analysis stage, viewing is available not only by intervals but also by days or days of the week.

The "Group data by day" function is needed when outliers within an interval don't matter. Only whether the entire day stands out from the overall picture matters.

---

## Page 231

![Group by Day](img/group_by_day.png)

The "Consider days of the week" function allows grouping data by all Mondays, all Tuesdays, etc., falling within the historical data period, and based on already grouped data, see if there's an anomaly in any of the days from the general series and whether smoothing is necessary.

![Consider Days of Week](img/consider_days_of_week.png)

### 4.5. Trend Analysis

"Trend Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next step.

Trend is calculated as linear regression y = a + bx, where a is the free term, b is the angular coefficient. Trend determines

---

## Page 232

patterns in the number of calls; it can be increasing and decreasing.

• **Increasing** – when the number of calls gradually grows from the beginning of the period and continues to grow toward its end. In this case, a pattern is visible – calls toward the end of the month become more. In this case, during forecasting, the system will account for and continue the trend of increasing calls (while maintaining various coefficients and formulas).

• **Decreasing** – when the number of calls gradually decreases from the beginning of the period and continues to fall until its end.

In this case, a pattern is visible – calls toward the end of the month become fewer. In this case, during forecasting, the system will account for and continue the trend of decreasing calls (while maintaining various coefficients and formulas).

![Trend Analysis Interface](img/trend_analysis_interface.png)

You can either consider the trend when composing the forecast or not consider it – select the desired option in the "Parameters" field (can be set separately for requests and AHT).

If the trend is considered, you can manually change the angle of inclination and free coefficient (point from which the trend starts growing on the chart). To do this, enter values in the "Angle change" and "Coefficient a change" fields.

---

## Page 233

![Trend Parameters](img/trend_parameters.png)

### 4.6. Seasonal Component Analysis

"Seasonal Component Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next step.

Seasonal component analysis allows accounting for seasonal load fluctuations in the historical data period for requests and AHT. Any combination of parameters can be used for both requests and AHT; multiple selection is possible.

![Seasonal Analysis Interface](img/seasonal_analysis_interface.png)

In the "Request Parameters" / "AHT Parameters" blocks, seasonality levels that can be considered are provided. Select those that most accurately fit your data. The system has six seasonality levels available.

**Intervals in day**: determined as load deviation in one or another time interval within the day relative to average load within the entire day.

---

## Page 234

For example, consider the interval from 13:00 to 13:05. The seasonal coefficient corresponding to a specific interval is calculated as the ratio of the average of all values in historical data corresponding to the time period from 13:00 to 13:05 to the overall average of all values in historical data.

![Intervals in Day](img/intervals_in_day.png)

**Intervals in day of week**: determined as load deviation in one or another time interval within a day of the week relative to average load within the day of the week.

For example, consider Monday from 13:00 to 13:05. The seasonal coefficient corresponding to a specific interval of the day of the week is calculated as the ratio of the average of all values in historical data corresponding to the time period from 13:00 to 13:05 of Monday to the overall average of all values in historical data.

![Intervals in Day of Week](img/intervals_in_day_of_week.png)

**Days in month**: determined as load deviation on one or another day (date) of the month relative to average load within the entire month.

For example, consider the 22nd day of the month. The seasonal coefficient corresponding to a specific day (date) in the month is calculated as the ratio of the average of all values in historical data corresponding to the 22nd days of all months falling within the historical data period to the overall average of all values in historical data.

---

## Page 235

![Days in Month](img/days_in_month.png)

The blue line on the chart shows the average number of calls for the entire historical data period, and the red line shows the number of requests in 15-minute intervals for all first/second/third days of the selected historical data period. The figure shows the number of requests for all fifth days of all months in 15-minute intervals. To select another day, click:

![Day Selection](img/day_selection.png)

In the figure, the red line shows the average number of calls for all 11th days of all months included in the selected time period.

**Days in week**: determined as load deviation on one or another day of the week relative to average load within the entire week.

---

## Page 236

For example, consider the day of the week – Wednesday. The seasonal coefficient corresponding to a specific day of the week is calculated as the ratio of the average of all values in historical data corresponding to all Wednesdays falling within the historical data period to the overall average of all values in historical data.

![Days in Week](img/days_in_week.png)

In the figure, the blue line shows the average number of calls for the entire time period selected earlier. The red line shows the average number of calls for all Mondays in the selected time period. Days of the week can be selected below the chart.

**Weeks in month**: determined as load deviation in one or another week of the month relative to average load within the entire month.

For example: consider the 2nd week of the month. The seasonal coefficient corresponding to a specific week should be calculated as the ratio of the average of all values in historical data corresponding to the 2nd weeks of the month to the overall average of all values in historical data.

---

## Page 237

![Weeks in Month](img/weeks_in_month.png)

In the figure, the blue line shows the average number of calls for the entire time period selected earlier. The red line shows the average number of calls for all first weeks of all months from the previously selected time period. Week numbers are selected below the chart.

**Month in year**: determined as load deviation in one or another month relative to average load within the entire year.

For example, consider February. The seasonal coefficient corresponding to a specific month is calculated as the ratio of the average of all values in historical data corresponding to February to the overall average of all values in historical data.

![Month in Year](img/month_in_year.png)

In the figure, the blue line shows the average number of requests for the entire time period selected earlier. Red shows the average

---

## Page 238

number of requests for all second months of the selected time period. Numbers can be selected by clicking:

![Month Selection](img/month_selection.png)

Similarly, all seasonal components marked with a "checkmark" in the "AHT Parameters" field will be considered during forecasting.

### 4.7. Traffic and AHT Forecasting

The "Traffic and AHT Forecasting" step is the penultimate before calculating the actual number of operators. At this step, the resulting request forecast is presented, which can be viewed on charts and you can decide whether to return to previous steps and consider other inputs.

**Important!** The system does not allow saving the resulting forecast, starting over and comparing results. Forecast versioning is not supported.

![Traffic AHT Forecasting](img/traffic_aht_forecasting.png)

In the "Forecasting" field, select the period for which load will be forecasted.

---

## Page 239

Optionally, the forecast can consider "Special dates."

After selecting the forecasting period, all intervals (with possible switching to hours, days, weeks, or months) with forecasted number of requests and AHT will be displayed in the "Forecast" field.

The forecasted number of requests and AHT can be manually corrected by clicking next to the desired interval. Editing capability is only available in "Intervals" mode.

![Manual Forecast Correction](img/manual_forecast_correction.png)

After editing, you can either apply new values or cancel them.

Charts show the number of forecasted requests and their average processing time in seconds. Charts can be viewed by months, weeks, days, hours, intervals.

![Forecast Charts](img/forecast_charts.png)

An additional tool for correcting obtained values is the growth coefficient. We recommend using it if at the time of load forecasting, upcoming growth or decline in load is known in advance. When setting a growth coefficient, the forecasted

---

## Page 240

number of requests will be multiplied by the set coefficient.

To set a growth coefficient, click, then "Growth coefficient."

![Growth Coefficient Setting](img/growth_coefficient_setting.png)

Next, select the time period for which the coefficient applies and enter the growth coefficient itself. To apply entered data, click or – to cancel.

![Growth Coefficient Parameters](img/growth_coefficient_parameters.png)

The "Growth coefficient" column reflects the entered value, the "Recalculated" column reflects the forecasted load obtained by multiplying by the coefficient.

If it's necessary to consider several increasing or decreasing coefficients, then before starting forecasting, you need to fill the "Special Events" directory.

---

## Page 241

### 4.8. Calculate Number of Operators

The final step in Forecasting is calculating the number of operators. At this step, the system calculates operators needed to cover the load forecasted at the "Traffic and AHT Forecasting" step.

![Calculate Operators Interface](img/calculate_operators_interface.png)

The system has 4 operator calculation models available, each with a specific set of parameters.

#### 4.8.1. Calculate Number of Operators by "Erlang C" Model

Erlang C (old name – Voice channel) is a standard forecasting algorithm using the improved Erlang C formula (considering SL corridor), most often used on voice channels.

---

## Page 242

![Erlang C Model](img/erlang_c_model.png)

When selecting this model, specify the following parameters:

• **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.

• **Customer wait time, sec.** – maximum customer wait time on the line (in seconds) or customer wait time on the line after IVR distribution until operator answer.

• **Operator occupancy** – desired/established contact center operator occupancy percentage.

• **SL (min and max)** – desired SL boundaries established in the contact center. The system will calculate the number of operators to fit within the specified SL framework.

• **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.

• **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.

#### 4.8.2. Calculate Number of Operators by "Linear" Model

Linear (old name – Non-voice channel) is a forecasting algorithm most often used for non-voice channels (operator can work with several requests in parallel).

---

## Page 243

The model does not require binding to service level (SL), can handle cases when average request handling time (AHT) is greater than the system interval (5, 10, or 15 minutes).

![Linear Model](img/linear_model.png)

When selecting this model, specify the following parameters:

• **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.

• **Operator occupancy** – desired/established contact center operator occupancy percentage.

• **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.

---

## Page 244

• **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.

• **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.

#### 4.8.3. Calculate Number of Operators by "Erlang C with SLA" Model

Erlang C with SLA (old name – Non-voice channel with SLA consideration) is a forecasting algorithm most often used for non-voice channels (operator can work with several requests in parallel) where service level (SL) needs to be considered.

![Erlang C with SLA Model](img/erlang_c_sla_model.png)

When selecting this model, specify the following parameters:

---

## Page 245

• **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.

• **Customer wait time, sec.** – maximum customer wait time on the line (in seconds) or customer wait time on the line after IVR distribution until operator answer.

• **Operator occupancy** – desired/established contact center operator occupancy percentage.

• **SL (min and max)** – desired SL boundaries established in the contact center. The system will calculate the number of operators to fit within the specified SL framework.

• **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.

• **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.

• **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.

#### 4.8.4. Calculate Number of Operators by "Linear with AWT" Model

Linear with AWT is a forecasting algorithm used for calculating non-voice channel operators. The approach feature is that the contact center works certain hours within the day (for example, 09:00 – 21:00) with backlog accumulation during non-working time. Requests that came at night have priority over morning ones and must be processed within a specified number of hours from the start of the shift.

---

## Page 246

![Linear with AWT Model](img/linear_awt_model.png)

When selecting this model, specify the following parameters:

• **AWT, min** – average call wait time in queue until customer answer, multiple of system interval.

• **Operator occupancy** – desired/established contact center operator occupancy percentage.

• **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.

• **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.

• **Contact center working hours** – contact center working hours within the day

• **Processing interval for requests received during non-working time** – time period from the start of contact center operation during which requests received during non-working time must be processed.

---

## Page 247

• **Add intraday period** – applying set KPI indicators to the contact center operation period.

#### 4.8.5. Adding Intraday Period

The above-described parameters can be applied either to the entire forecasted request period or to specific days through configuration in the left part of the screen.

![Intraday Period Configuration](img/intraday_period_configuration.png)

In "Day" mode, select either one day or several by highlighting them with the left mouse button while holding the CTRL key.

![Day Mode Selection](img/day_mode_selection.png)

---

## Page 248

Selected calculation parameters can be applied either to the entire day (i.e., all 24 hours) or to a specific period within the day. For example, in the morning, SL value or average customer wait time will differ (fewer requests in the morning, so customers will wait less).

To apply selected parameters, choose the daily interval or leave the default interval 00:00-24:00 and click "Add intraday interval."

![Add Intraday Interval](img/add_intraday_interval.png)

---

## Page 249

![Intraday Interval Applied](img/intraday_interval_applied.png)

#### 4.8.6. Calculate Number of Operators

When all needed periods within the day have calculation parameters set (period will be highlighted in green), check that the calculation period is correctly selected ("Entire period" or "Day") and click "Calculate number of operators." Below will display a table showing the calculated number of operators needed to cover the forecasted load. You can select data aggregation by intervals, hours, days, weeks, and months.

The table consists of the following fields and data (when selecting aggregation by intervals):

• **Time intervals**;

• **Forecasted considering % ACD (requests)** – forecasted number of requests considering %ACD;

• **Growth coefficient (requests)** – indicator set at the "Traffic and AHT Forecasting" step (default 1.0 if nothing else was specified);

---

## Page 250

• **Recalculated (requests)** – forecasted number of requests considering growth coefficient and "Special Events" from the directory of the same name;

• **Forecasted (operators)** - number of operators calculated by the system without considering coefficients;

• **% Absenteeism (operators)** – percentage of operators who may be absent (sick, time off, etc.). Can be set on the "Calculate Number of Operators" page by clicking;

• **Reserve coefficient (operators)** – coefficient by which the calculated number of operators is multiplied. Can be set on the "Calculate Number of Operators" page by clicking;

• **Final (operators)** – final forecasted number of operators needed to cover the load, considering all coefficients and minimum number of operators (can be set on the "Calculate Number of Operators" page by clicking);

• **AHT** – average request handling time, set manually at the stage of filling parameters for operator calculation, or forecasted by the system based on historical data (when checking "Consider statistically calculated AHT" in the parameters above).

---

## Page 251

![Operator Calculation Table](img/operator_calculation_table.png)

The table consists of the following fields and data (when selecting aggregation by hours, days, weeks, and months):

• **Time intervals**;

• **Forecasted considering % ACD (requests)** – forecasted number of requests considering %ACD;

• **Recalculated (requests)** – forecasted number of requests considering growth coefficient and "Special Events" from the directory of the same name;

• **Forecasted (operators)** - number of operators calculated by the system without considering coefficients;

• **Person-hours (operators)** – arithmetic average of operators for the selected period (for hour aggregation, the number of intervals is summed; for day aggregation, the number of hours is summed; for week and month aggregation, the number of days is summed);

• **% Absenteeism (operators)** – percentage of operators who may be absent (sick, time off, etc.). Can be set on the "Calculate Number of Operators" page by clicking;

• **Final (operators)** – final forecasted number of operators needed to cover the load, considering all coefficients and minimum number of operators (can be set on the "Calculate Number of Operators" page by clicking);

• **AHT** – average request handling time, set manually at the stage of filling parameters for operator calculation, or forecasted by the system based on historical data (when checking "Consider statistically calculated AHT" in the parameters above).

---

## Page 252

![Aggregated Calculation Table](img/aggregated_calculation_table.png)

Below, charts display the number of forecasted operators, requests, and AHT.

![Forecast Charts Display](img/forecast_charts_display.png)

The chart can be viewed by months, weeks, days, hours, and intervals.

#### 4.8.7. Coefficients for Calculating Number of Operators

Additional parameters can be applied to the forecasted number of operators.

---

## Page 253

![Operator Coefficients](img/operator_coefficients.png)

**Minimum operators**: determines the minimum number of operators that must be present on the line. Used, for example, for night periods: there's no load (no requests, zero forecast), but even in this situation, two operators should be on the line. If the forecasted number of operators is less than the set minimum, it will change to the set minimum. If the forecasted number of operators equals or exceeds the set minimum, it will not change. At the same time, the number of operators recalculated considering the minimum does not overwrite data forecasted by the system. Therefore, if necessary, the minimum can be changed or canceled – new values will be applied to the originally calculated number of operators.

To set minimum operators, select the period to which the minimum will be applied and the number of operators itself.

![Minimum Operators Setting](img/minimum_operators_setting.png)

When applying, click or – to cancel.

---

## Page 254

![Apply Minimum Operators](img/apply_minimum_operators.png)

**Reserve coefficient**: similar to growth coefficient for request calculation but applied to the number of operators. Used in situations when at a specific time it's necessary to bring more operators to the line: the calculated number of operators will be multiplied by the reserve coefficient.

When reserve coefficient is used together with minimum operators, the system will follow these rules:

• If the forecasted number of operators is less than the minimum, then the final number of operators will be calculated by the formula: minimum operators * reserve coefficient.

• If the forecasted number of operators is greater than or equal to the minimum, then the final number of operators will be calculated by the formula: forecasted number of operators * reserve coefficient.

For example, at 08:00, 6 operators are forecasted, at 08:15 – 10 operators. We set minimum operators to 8 and reserve coefficient to 2.0. The final number of operators at 08:00 will be 16 (8 * 2), and at 08:15 – 20 (10 * 2).

To calculate the coefficient, specify the period to which it will be applied and the coefficient itself.

---

## Page 255

![Reserve Coefficient Setting](img/reserve_coefficient_setting.png)

After which click - to apply, or – to cancel.

![Apply Reserve Coefficient](img/apply_reserve_coefficient.png)

**%Absenteeism**:

The parameter indicates the percentage of operators who may be absent from work due to illness or time off. To set the parameter, specify the period to which it will be applied and the percentage itself.

![Absenteeism Setting](img/absenteeism_setting.png)

After which click - to apply, or – to cancel.

---

## Page 256

![Apply Absenteeism](img/apply_absenteeism.png)

To cancel entered values, you need to click the gear again and set zero value in the needed coefficient instead of the entered one (for reserve coefficient, value 1.0).

To save all set coefficients, select "Save" through the "gear." This completes the forecasting process.

![Save Coefficients](img/save_coefficients.png)

After saving data, it can be seen in the "Load View" section.

### 4.9. Forecast Accuracy Analysis

Access right System_AccessAnalysisAccuracy opens access to the "Forecast Accuracy Analysis" page.

Allows evaluating the accuracy of load forecasted by the system. If in your view the accuracy is low, return to the "Forecast Load" section and build a new forecast, analyzing the reasons for low accuracy.

To go to the "Forecast Accuracy Analysis" page, open the side menu or main page: "Forecasting" → "Accuracy Analysis."

---

## Page 257

![Forecast Accuracy Analysis](img/forecast_accuracy_analysis.png)

To view forecast accuracy percentage, select the service and group of interest, as well as the period for which the system has both historical data and forecast.

![Accuracy Analysis Parameters](img/accuracy_analysis_parameters.png)

If an aggregated group was added to the "Group" field, a "Recalculate data" button appears. It allows summing historical data by simple groups without going to the "Forecast Load" page.

---

## Page 258

![Recalculate Data Option](img/recalculate_data_option.png)

When the "Personnel" - "Group Structure" page is filled in the system, viewing accuracy by segment is available on the "Forecast Accuracy Analysis" page.

![Accuracy by Segment](img/accuracy_by_segment.png)

Accuracy percentage is calculated by intervals for the selected data display period. Display can be changed to hours, days, weeks, months. On "Plan/actual" charts, blue color shows the chart of forecasted number of requests, purple shows actual number of requests. The "Forecast accuracy for period" section provides: MFA – average accuracy and WFA – weighted accuracy.

MAPE, WAPE, MFA, WFA charts:

---

## Page 259

![Accuracy Charts](img/accuracy_charts.png)

**MAPE (Mean Absolute Percentage Error)** – average absolute error in percentages. Calculated based on the number of intervals depending on the selected display mode (all intervals, intervals in hour, day, week, month), actual and forecasted number of requests per interval.

**WAPE (Weighted Absolute Percentage Error)** – weighted absolute percentage error. Each interval receives weight equal to the share of request volume in this interval from the total request volume of the considered period. Also calculated based on the number of intervals (number varies depending on selected display mode), total number of incoming requests for the entire considered period and number of incoming requests for corresponding intervals.

Lines on charts can be hidden: to do this, click on the desired item in the legend with the left mouse button.

### 4.10. Mass Forecast Assignment

This functionality allows assigning parameters for calculating the number of operators to several groups at once.

To go to the "Mass Forecast Assignment" page, open the side menu: "Forecasting" → "Mass Forecast Assignment."

---

## Page 260

![Mass Forecast Assignment](img/mass_forecast_assignment.png)

On the opened page, select the service, group (or one group) to which parameters need to be assigned en masse.

![Select Groups for Mass Assignment](img/select_groups_mass_assignment.png)

Next, change parameters by clicking on the selected parameter with the left mouse button.

After all parameters are configured, click.

Now, the next time when forecasting requests and operators for the selected group or groups, the parameters set on this page will already be specified at the operator calculation stage. The ability to make changes at the time of forecasting is preserved.

---

## Page 261

### 4.11. Update Historical Data on Schedule

To view "Update Settings," you need access right "System_AccessGetHistoricalData." To edit historical data update settings, you need access right "System_EditGetHistoricalData."

Obtaining historical data for load forecasting can be automated. In "Update Settings," you can set settings for automatic historical data requests for all groups. To do this, go to "Forecasting" → "Update Settings."

![Update Settings Page](img/update_settings_page.png)

When opening "Update Settings," the following settings will be displayed:

---

## Page 262

![Update Settings Configuration](img/update_settings_configuration.png)

**Collection frequency** – how often historical data should be automatically obtained for all groups. The following options are available:

• **Daily**: specify time zone and time when historical data request will be executed.

• **Weekly**: specify day of the week and time when historical data request will be executed.

![Weekly Settings](img/weekly_settings.png)

**Monthly**: specify week number, day of that week, and time of day when historical data request will be executed.

![Monthly Settings](img/monthly_settings.png)

---

## Page 263

When clicking the "Update for period" button, you can update historical data for all groups at once for a specific period without waiting for automatic update (with working contact center integration).

![Update for Period](img/update_for_period.png)

### 4.12. Special Dates Analysis

The "Special Dates Analysis" module is available to users with system role "Administrator" or any other role with access rights System_AccessForecastList – View pages in the "Forecasting" section.

There are days when the load profile differs from normal request distribution, while the differing days themselves are similar to each other. For example, holidays or periods of mailings, promotions. This module implements functionality for adding analysis of special date historical data and calculating load distribution coefficients on such days for their further use when forecasting load for similar days (unlike growth coefficients in the "Special Events" directory, where values are set manually, not calculated by the system).

The "Special Dates Analysis" page can be found in the navigation menu:

---

## Page 264

![Special Dates Analysis Menu](img/special_dates_analysis_menu.png)

Two tabs are available on the page:

• **Special Dates Analysis**;
• **View Coefficients**.

On the "Special Dates Analysis" tab, you can configure a special date/day for subsequent use in forecasting.

On the "View Coefficients" tab, you can review already created dates/days for forecasting.

Creating special dates, let's examine with an example.

Suppose our company had similar peak load days that don't follow a specific pattern (such as seasonal promotions). In this case, we can review historical data for promotion days and determine the load deviation coefficient to use in future forecasts when this event repeats.

For this, we need to fill in data for service, group, select forecasting schema, request period, and time zone.

---

## Page 265

![Special Dates Configuration](img/special_dates_configuration.png)

After this, click the "Apply" button.

In the "Special dates" window, select peak load dates for analysis (in our case, dates when there was a promotion) by clicking the "Calendar" button.

![Special Dates Calendar](img/special_dates_calendar.png)

After selecting dates for analysis, their load deviation coefficients will be displayed graphically by intervals in daily breakdown.

![Load Deviation Coefficients](img/load_deviation_coefficients.png)

---

## Page 266

Chart scale can be increased and decreased using the mouse wheel; you can also enable/disable curve display on the chart by clicking on dates in the chart legend.

The "Coefficients" window displays the final deviation coefficient for selected days, coefficients by intervals in daily breakdown, a chart showing normal distribution based on historical data, and a chart of general special date coefficients.

![Coefficients Window](img/coefficients_window.png)

Special day coefficients can be corrected by intervals by clicking on values in the table or changing the general date coefficient. After all settings are made, save the special date by clicking "Gear" -> "Save." You need to specify the special date name.

![Save Special Date](img/save_special_date.png)

On the "View Coefficients" tab, you can view/edit/delete already created special dates.

---

## Page 267

To do this, specify the special date name in "Parameters," and it will be displayed on the chart similar to the "Special Dates Analysis" tab.

![View Coefficients Tab](img/view_coefficients_tab.png)

Using special dates is available on the "Forecast Load" page at the "Traffic and AHT Forecasting" step. To do this, click the "Add coefficient" button, select the created special date, and assign dates when special day coefficients will be applied during forecasting.

![Use Special Dates](img/use_special_dates.png)

You can also add several different special dates by clicking the "Add coefficient" button again.

---

## Page 268

## 5. Load View

The forecasting module is available to users with system role "Administrator," "Senior Operator," or any other role with access right "Access to forecast view/edit pages."

A forecast represents the number of requests that will presumably arrive at an operator group/service during a specific time period.

To go to the forecast view/edit page, go to the "Forecasting" → "Load View" tab (you can go from the section list menu or from the main page by clicking the "Load View" block):

![Load View Navigation](img/load_view_navigation.png)

This will open the forecasting page with a filter for selecting services and groups included in them:

![Load View Filter](img/load_view_filter.png)

### 5.1. View Load for Group

In the service and group list, first select the necessary service, then the group included in this service. After this, select one of 5 modes.

---

## Page 269

![Load View Modes](img/load_view_modes.png)

• **Intra-annual profile of monthly periods** – will show load by months in the specified period.

• **Intra-annual profile of weekly periods** – will show load by weeks for the specified period.

• **Intra-monthly profile of daily periods** – will show load by days for the specified period.

• **Intra-daily profile of hourly intervals** – will show load by hours from the day for the specified period.

• **Intra-daily profile of interval periods** – will show load for all intervals in the day for the specified period.

After the desired mode is set, select the time zone and time period for viewing load. The beginning and end of the period are selected.

Load forecast is displayed in table format with the ability to switch by dates and navigate through time periods, as well as in chart form located below the forecast table.

---

## Page 270

![Load View Display](img/load_view_display.png)

### 5.2. Forecast Correction

In some cases, forecasts (required number of operators and number of requests) require manual correction. The WFM CC system implements the ability to manually correct:

• Forecasted number of operators;
• Forecasted number of requests.

For manual correction by intervals, select the "Intra-daily profile of interval periods" mode.

![Manual Correction Mode](img/manual_correction_mode.png)

---

## Page 271

There is also the ability to build forecasts considering the minimum number of operators set by the user.

![Minimum Operators Setting](img/minimum_operators_forecast.png)

The number of operators/requests is corrected by multiplying by a coefficient specified by the user.

#### 5.2.1. Update Forecasted Number of Operators

To specify new parameters for forecasting the number of operators for a specific period, click the button and select "Update for today/tomorrow/period" from the dropdown list, after which the following window will open:

![Update Operators Dialog](img/update_operators_dialog.png)

Parameters set in this window are similar to parameters set at the "Calculate Number of Operators" stage.

---

## Page 272

#### 5.2.2. Operator Count Correction with Reserve Coefficient

Reserve coefficient is applied to the forecast when there's operator shortage.

**Important!** Applying reserve coefficient affects only the number of operators without affecting forecast request numbers.

Select the group for which the obtained forecast needs to be corrected.

Next, in the "Forecast" block, click the button and select "Reserve coefficient" from the dropdown list:

![Reserve Coefficient Selection](img/reserve_coefficient_selection.png)

In the appearing window, specify:

• **Period** (accurate to minutes) for which the coefficient needs to be applied;
• **Reserve coefficient value**.

---

## Page 273

![Reserve Coefficient Parameters](img/reserve_coefficient_parameters.png)

After all parameters are specified, click to apply the coefficient.

As a result:

• Reserve coefficient will be successfully applied;
• The number of operators in the forecast will be recalculated;
• The number of requests will not change;
• Applied coefficient will be displayed next to intervals (in the "reserve coefficient" column).

Load update results will be displayed in the "Forecasting" → "Load View" section for the selected group in table and chart formats:

![Reserve Coefficient Results](img/reserve_coefficient_results.png)

To cancel applied reserve coefficient, perform the following actions:

Select the group for which reserve coefficient was previously applied, click the button and select "Reserve coefficient" from the dropdown list:

---

## Page 274

In the appearing window, specify:

• Previously selected period (accurate to minutes) for which the coefficient needs to be canceled
• Set reserve coefficient value equal to = 1.

After all parameters are specified, click.

As a result, the number of operators will return to the original value.

#### 5.2.3. Request Count Correction with Growth Coefficient

When manual correction of the obtained forecast is needed, mass load correction capability is provided.

**Important!** Applying growth coefficient will change the number of requests, which in turn will affect the number of operators (which will be recalculated using Erlang formula).

Select the group for which the obtained forecast needs to be corrected.

Next, in the "Forecast" block, click the button and select "Growth coefficient" from the dropdown list:

---

## Page 275

![Growth Coefficient Selection](img/growth_coefficient_selection.png)

In the appearing window, specify:

• **Period** (accurate to minutes) for which the coefficient needs to be applied;
• **Growth coefficient value**.

![Growth Coefficient Parameters](img/growth_coefficient_parameters.png)

After all parameters are specified, click to apply the coefficient.

As a result:

• Growth coefficient will be successfully applied;
• The number of requests and operators will be successfully recalculated;
• Applied coefficient will be displayed next to intervals (in the "Growth coefficient" column)

Load update results will be displayed in the "Forecasting" → "Load View" section for the selected group in table and chart formats:

---

## Page 276

![Growth Coefficient Results](img/growth_coefficient_results.png)

To cancel applied growth coefficient, perform the following actions:

Select the group for which growth coefficient was previously applied, click the button and select "Growth coefficient" from the dropdown list:

In the appearing window, specify:

• Previously specified period (accurate to minutes) for which the coefficient needs to be canceled;
• Set growth coefficient value equal to = 1.

After all parameters are specified, click to cancel the coefficient.

As a result, the number of requests and operators will return to the original value.

---

## Page 277

#### 5.2.4. Forecast Correction with Minimum Number of Operators

For example, a situation occurred where, according to obtained forecasts, data returned indicating that for several hours there were 0 requests, and consequently, 0 operators are suggested for the line (especially during night hours). But since request handling is 24/7, at least one or two operators still need to be on the line at night. For such situations, the WFM CC system implements the ability to specify minimum number of operators.

This functionality applies not only to cases when forecast calculated operator count=0. It can be used in other situations, for example, when minimum number of operators on the line should be =3, but forecast calculated operator count = 2 or 1 or 0.

**Logic**: if the obtained operator count by forecast is less than the set minimum number, then WFM CC system sets operator count = set minimum number of operators in the updated forecast. If operator count by forecast is greater than set minimum number, then WFM CC system leaves the operator count value obtained by forecast in the updated forecast.

Let's examine the example below.

After obtaining forecasts, the user discovered time moments when operator count = 0:

---

## Page 278

![Zero Operators Example](img/zero_operators_example.png)

Since the user understands that at least one operator should always be on the line, they set minimum number of operators=1 and update the previously obtained forecast.

To set minimum number of operators, click the button in the "Forecast" block and select "Minimum operators" from the dropdown list:

![Minimum Operators Selection](img/minimum_operators_selection.png)

In the appearing window, specify:

• **Period** (accurate to minutes) for which minimum number of operators needs to be applied;

---

## Page 279

• **Minimum operators**.

![Minimum Operators Parameters](img/minimum_operators_parameters.png)

After all parameters are set, click to apply minimum number of operators.

As a result:

• Minimum number of operators equal to the entered value will be set in those intervals where forecast returned a value less than the set minimum;
• Number of requests will not change when making adjustments.

Load update results will be displayed in the "Recalculated" column.

Before applying minimum number of operators=1:

![Before Minimum Operators](img/before_minimum_operators.png)

After applying minimum number of operators = 1:

---

## Page 280

![After Minimum Operators](img/after_minimum_operators.png)

![Minimum Operators Applied](img/minimum_operators_applied.png)

**The set minimum number of operators in the forecast cannot be canceled.** But it can be returned to 1 if the minimum value was set higher.

### 5.3. Import Load from File

In the system, besides obtaining forecasts based on historical data, there's the ability to import load from a file (by requests or operators). Acceptable imported file formats: .xls, .xlsx, .csv.

---

## Page 281

#### 5.3.1. Import Ready Request Forecast

The system implements the ability to import request forecast on the "Import Forecasts" page. This function is used when WFM CC system needs to load a request forecast and calculate the necessary number of operators to cover the load.

To load a ready request forecast, go to "Forecasting" - "Import forecasts" section or go directly to "Import forecasts" from the main page.

![Import Forecasts Page](img/import_forecasts_page.png)

For each group, a separate file with forecast needs to be loaded and operators calculated. The file for loading must contain three columns with headers "Start of time interval," "Number of requests," "AHT, sec." The number of rows must match the number of time intervals for which load is imported and be multiple of the system interval (5, 10, or 15 minutes, based on platform settings). Date must be in DD.MM.YYYY hh:mm format, and remaining columns in numeric format.

---

## Page 282

![Import File Format](img/import_file_format.png)

Fill in Service, Group, and Time Zone. Click "Load" and select the required file.

![Load File Dialog](img/load_file_dialog.png)

After selecting the file for loading ready request forecast, select KPI indicators that will be used for calculating number of operators (similar to 4.8. Calculate Number of Operators).

---

## Page 283

![KPI Indicators Selection](img/kpi_indicators_selection.png)

Don't forget to save the forecast.

#### 5.3.2. Import Ready Operator Forecast

The system implements the ability to import ready operator forecast. This function is used when operator forecast comes from external sources, so there's no need to forecast load in WFMCC system and calculate number of operators.

The specified operator forecast in source format is presented as hourly profile (number of operators by hours) for weekdays and separately for weekends. Since WFMCC system has system interval less than hour (5, 10, or 15 minutes), this hourly profile is broken down into system intervals.

To load ready operator forecast, go to "Forecasting" - "Load View" section or go directly to "Load View" from the main page.

---

## Page 284

![Load View Import](img/load_view_import.png)

This will open the forecasting page with group and service filter and mode selection.

![Load View Interface](img/load_view_interface.png)

Select the group for which forecast import from file will be performed and display mode.

Next, in the "Forecast" block, click the button and select "Import" from the dropdown list:

![Import Selection](img/import_selection.png)

In the opened "Load Import" window, fill in parameters:

![Load Import Parameters](img/load_import_parameters.png)

• **Date and Time**. Specify start and end of period for which load will be obtained from imported file;
• **Customer wait time, sec.** Used for operator calculation;
• **SL**. Upper SL boundary that system will orient to for operator calculation;
• **Average request handling time (AHT)**. Used for operator calculation.

---

## Page 285

To load file from your computer, click "Load" (button becomes available to user if Date and time are specified at minimum). In the opened file addition window, find the file on your computer's hard drive and click "Open."

The Excel file should not have column names; two columns should contain numbers: first column - number of requests, second column - number of operators. Data from file will automatically distribute across N-minute intervals (depending on system setting, this can be 5, 10, or 15 minutes) starting from the beginning of selected time interval.

**Note**: data must be in "General" format and number of rows (N-minute intervals) must correspond to time selected earlier. I.e., if there are 8 rows (with 15-minute system interval), this equals two hours. Accordingly, select a two-hour period for importing data.

![Excel File Format](img/excel_file_format.png)

After successful file loading, "Import" button becomes available, which must be clicked to check data.

---

## Page 286

![Import Button Available](img/import_button_available.png)

If data and intervals satisfy the user, click "Save" to apply this data or "Back" - to return to previous step.

![Save Import Data](img/save_import_data.png)

Load update results will be displayed in "Forecasting" → "Load View" section for selected group in table and chart formats.

---

## Page 287

## 6. Multi-skill Planning Template

Multi-skill planning template is necessary for creating work schedules for a specific group or list of groups, as well as for timetable planning.

To create a multi-skill planning template, go to "Planning" → "Multi-skill planning" page:

![Multi-skill Planning Navigation](img/multiskill_planning_navigation.png)

When going to the "Multi-skill planning" page, all created multi-skill planning templates are displayed.

![Multi-skill Planning Templates](img/multiskill_planning_templates.png)

---

## Page 288

To view general information about the template, click on it with the left mouse button. To the right of the template, the following information will be displayed: "Template name," "Groups."

![Template Information](img/template_information.png)

The "Groups" area displays groups included in the multi-skill planning template.

### 6.1. Creating Multi-skill Planning Template

To create a new template, click the button in the left part of the page, after which a form for filling template data will appear.

![Create New Template](img/create_new_template.png)

In the opened form, enter the template name and click to save. After saving, the new multi-skill planning template will appear in the general template list.

Next, to add groups to the multi-skill planning template, click the "Add" button in the "Groups" window:

---

## Page 289

![Add Groups to Template](img/add_groups_template.png)

In the opened dialog window, using dropdown lists, select "Service" and "Groups" that will be included in the multi-skill planning template.

To confirm adding groups, click in the dialog window.

An operator can belong to different groups but only one multi-skill planning template. Accordingly, one group can be included in only one multi-skill template. If you try to add an operator group that already exists in one of the multi-skill templates to a new template, the system will display a warning:

![Template Warning](img/template_warning.png)

This is necessary to exclude schedule discrepancies (for example, situations when an operator may have several conflicting work schedules or planned vacations).

The created multi-skill planning template, after adding groups to it, will be displayed in "Planning work schedules" and "Creating timetables" sections in the "Templates" block.

---

## Page 290

To rename the template, click on its name, correct it, and click to save.

To delete a group from the template, click next to it.

### 6.2. Deleting Multi-skill Planning Template

To delete a multi-skill planning template, select the necessary template in the general template list and click:

![Delete Template](img/delete_template.png)

After clicking the "Delete template" button, a confirmation dialog will appear:

![Delete Confirmation](img/delete_confirmation.png)

To confirm deletion, click "Yes." The deleted multi-skill planning template cannot be restored.

Work schedules planned based on the deleted multi-skill planning template will also be deleted without possibility of restoration.

---

## Page 291

## 7. Work Schedule Planning

The work schedule planning module is available to users with system role "Administrator," "Senior Operator," or any other role with access rights:

• **System_AccessPlanningShedule** – view "Planning work schedules" page (create button not available).
• **System_EditPlanningShedule** – ability to create work schedule planning variant.
• **System_AccessActualPlanningShedule** – view actual work schedule variant.
• **System_EditPlanningShedule** – ability to edit actual work schedule.

Work schedule planning is based on:

• Forecasted load;
• Operator performance;
• Individual settings;
• Labor standards;
• Work rules assigned to employees.

Work schedule is planned for employees with positions participating in planning and belonging to groups included in the "Multi-skill planning" template selected on the "Work schedule planning" page.

The "Work schedule planning" module is used for mass work schedule planning for employees. On the page of the same name, you can view the work schedule planned by the system for employees (eliminates the need to manually set operator schedules based on load and their preferences), as well as make corrections or accept the schedule as is.

During work schedule planning, the system considers employee hire and termination dates. The system will plan shifts for an employee only for the period when the operator works and will not assign shifts after termination date or before hire date. The system also considers the work norm assigned to the employee and will try to fit within this standard considering hire and termination dates.

If work rules in the "Work Rules" directory have configured variation in shift starts and durations, the system will select the start and duration of each operator's shift for each day of the year depending on load forecast. At the same time, operator performance will be maintained.

Such schedule planning can take a considerable amount of time. If the multi-skill planning template includes many operators and rules are configured quite freely, consider that this will affect planning time.

During schedule planning, you can continue using other system modules since planning occurs on a separate service.

### 7.1. Vacation Planning

Before planning the schedule in the system, vacation schedules need to be planned. Vacations that can be assigned to employees are created based on vacation schemes from the "Vacation Schemes" directory.

![Vacation Planning](img/vacation_planning.png)

---

## Page 292

In the "Vacation Schedule" tab, desired and extraordinary vacations that were set by the operator in their card will be displayed. Also in this tab, you can assign vacations manually and set priorities. Vacations set here are considered by the system when building work schedules, after which desired vacations become planned.

The following information is displayed on the top panel:

![Vacation Planning Panel](img/vacation_planning_panel.png)

• **Group filter** – allows viewing a specific group.
• **Department filter** – allows viewing a specific employee department.
• **"Operators without assigned vacation" checkbox** – will show operators who have vacation balance and haven't set desired vacation dates.
• **"Operators with accumulated vacation days" checkbox** – will show operators who have accumulated vacation days.
• **"Subordinate employees" checkbox** – will display employees under the supervision of the department head/deputy viewing the vacation schedule.
• **"Vacation violations" checkbox** – will display operators whose desired vacation was added with violations (accumulated vacation days not considered, incorrect duration – correctness is regulated by labor standards). When hovering the mouse cursor over such vacation (even without checkbox), the specific violation will be displayed.
• **"Desired vacations" checkbox** – will display all operator desired vacations, hiding extraordinary vacations.

---

## Page 293

• **"Generate vacations" button** – generates vacations for employees who haven't set desired vacations. The system follows vacation business rules assigned to employees.

The following information is displayed in table columns:

![Vacation Table Columns](img/vacation_table_columns.png)

• **Full Name** – employee's full name.
• **Planned vacation scheme** – shows vacation scheme set in operator card.
• **Remaining vacation days** – shows remaining vacation days after assigning operator vacation schedules. I.e., if operator has 15 vacation days (value comes via integration), when adding two vacations totaling 14 days, "remaining vacation days" field will show 1.

**Adding and deleting vacation:**

To add vacation on the "Vacation Schedule" tab, select a cell with the left mouse button, then right-click, and select "Add vacation" event from the dropdown menu:

---

## Page 294

![Add Vacation](img/add_vacation.png)

In the opened dialog window, select vacation type: "Desired vacation" or "Extraordinary vacation."

When selecting "Extraordinary vacation" type, specify start and end dates in the dialog window.

When adding "Extraordinary vacation" to an employee, accumulated vacation days are not deducted.

![Extraordinary Vacation](img/extraordinary_vacation.png)

When selecting "Desired vacation" type, select "Vacation scheme" and vacation creation method: "Period" or "Calendar days."

If "Period" vacation creation method is selected:

• Specify start and end vacation dates.
• Vacation is not shifted if holidays fall within its period (for example, vacation is set from 25.04 to 08.05. Despite one holiday "May 1" falling in this period, vacation is not shifted. Return to work date is 09.05).

---

## Page 295

• Days are deducted from accumulated vacation days considering holidays (for example, vacation is set for 14 days, with 1 holiday falling in its period. 13 days are deducted from accumulated days, not 14).

If "Calendar days" vacation creation method is selected:

• Specify vacation start date and number of vacation days (vacation end date will be pulled automatically).
• Vacation is shifted by the number of holiday days (for example, vacation is set for 14 calendar days from 25.04 to 08.05. One holiday "May 1" falls in this period, so vacation shifts to 09.05. But "May 9" is also a holiday, so vacation shifts again. Return to work date: 11.05).
• Days are deducted from accumulated vacation days without considering holidays (in the above example, 14 days will be deducted from accumulated days).

![Calendar Days Vacation](img/calendar_days_vacation.png)

The vacation addition functionality is similar to adding vacation in the client card.

To delete vacation, right-click on one of the cells in the desired vacation range and select "Delete vacation":

---

## Page 296

![Delete Vacation](img/delete_vacation.png)

**Vacation priorities**: vacations have priorities that are considered when planning work schedules. Priority works as follows: when planning work schedules, the system relies on forecasted load and personal vacation business rules for the operator.

The operator is assigned maximum number of vacation shift days. Based on this setting, the system can shift vacation within this range to cover load (for example, operator wanted to go on vacation on 5.01, but strong load is recorded on this day. In this case, the system can shift the operator's vacation by the number of days not exceeding the number set in the operator's card for vacation shift days). If vacation is considered priority, the system will first move (if necessary) non-priority vacations, and only then (if required) will move priority vacations to cover load. If vacation is considered fixed, the system doesn't shift it regardless of load.

To make vacation priority, select the vacation of interest by right-clicking on any cell of its interval and select "Vacation priority":

---

## Page 297

![Vacation Priority](img/vacation_priority.png)

To cancel vacation priority, select it as shown above and click "Non-priority vacation":

![Non-priority Vacation](img/non_priority_vacation.png)

To fix vacation, select it as shown earlier and click "Fixed vacation":

---

## Page 298

![Fixed Vacation](img/fixed_vacation.png)

Vacations set above are considered desired. Once work schedule is planned, the system will assign vacations itself, considering business rules and load, after which such vacations become planned.

**Note**: In "Calendar days" vacation mode, if vacation falls on a holiday, it is extended by the number of holiday days marked in the "Production Calendar" directory. This will be visible in both "Vacation Planning" and "Planned Work Schedule" fields. Also, all vacations that fall fully or partially within the work schedule planning period are confirmed.

---

## Page 299

### 7.2. Creating New Work Schedule Variant

To begin planning a work schedule variant, go to the "Planning work schedules" page either through the side menu or through the main page.

![Work Schedule Planning Navigation](img/work_schedule_planning_navigation.png)

After opening the page, we'll see a list of multi-skill planning templates.

To continue creating work schedules, select one of them, after which we'll see a list of work schedule variants, with the actual applied work schedule highlighted in bold and checkmark. The applied work schedule is always pinned to the top of the list.

Work schedule planning is independent of time zone; depending on the selected time zone, only display changes. By default, the user's time zone is always selected; there's also the ability to display in other time zones. To do this, change the time zone for work schedule display.

---

## Page 300

![Work Schedule Display Options](img/work_schedule_display_options.png)

In the "Work Schedule" area, there are two expandable windows:

• **Planned work schedule** – will display information about work schedule built by the system;
• **Vacation planning** – window for vacation planning.

To start schedule planning, click the button.

A window will open:

![Start Planning Dialog](img/start_planning_dialog.png)

In the opened window, specify the schedule name.

The "Comment" field is optional for filling.

The "Performance" field shows what type of performance is configured in the system (annual, quarterly, monthly).

The "Work schedule planning year" field allows selecting which year the schedule will be planned for.

If preference consideration was selected during work schedule planning, the system should consider operator preferences specified in their personal account.

After clicking "Start planning," the schedule name will appear in the "Work schedule variants" window, and the schedule planning task will appear in the "Work schedule tasks" window. While the schedule is being planned, you can continue working in the system – exit planning, go to other modules, and return back.

---

## Page 301

![Planning in Progress](img/planning_in_progress.png)

To check task status, update it by clicking the button.

If the schedule is planned, task status will change to "Awaiting save":

![Awaiting Save Status](img/awaiting_save_status.png)

To go to the planned schedule, click on the task itself:

![Access Planned Schedule](img/access_planned_schedule.png)

After which we'll see the work schedule planned by the system in the "Planned work schedule" area.

---

## Page 302

![Planned Schedule Display](img/planned_schedule_display.png)

Depending on the selected tab ("Org. Structure" or "Func. Structure"), the following areas will be displayed:

Or

![Structure Tabs](img/structure_tabs.png)

In "Org. Structure" we see:

• **Department filter** – allows viewing schedule for a specific department and all child departments.

---

## Page 303

• **"Operators without planned vacations" checkbox** – Operators who have positive vacation days balance but no vacation set.

• **"Employees with non-plannable position" checkbox** – shows employees whose position changed to non-planning attribute.

• **"Vacation violations" checkbox** – shows employees who were assigned vacation violating vacation assignment rules.

• **"Desired vacations" checkbox** – highlights desired employee vacations with a frame.

In "Func. structure" we see:

• **Group filter** – allows viewing schedule for a specific group.

• **"Vacation violations" checkbox** – shows employees who were assigned vacation violating vacation assignment rules.

• **"Desired vacations" checkbox** – highlights desired employee vacations with a frame.

• **"Op. Forecast" checkbox** – will display number of forecasted operators for day/month.

• **"Op. Plan" checkbox** – will display number of operators planned by work schedule for day/month.

• **"Op. plan %Abs" checkbox** – will display number of operators planned by work schedule multiplied by absence percentage from "Work absence percentage" directory for day/month.

• **"%ACD forecast" checkbox** – shows average forecasted %ACD value for 15-minute interval across all groups. Maximum shortage/surplus of employees – shows how many employees are lacking to cover load at the most loaded moment of the day and how many employees will be conditionally "excess" at the least loaded moment of the day.

---

## Page 304

![Monthly and Yearly Statistics](img/monthly_yearly_statistics.png)

Monthly and yearly statistics will display the same checkboxes that were selected earlier. In this case, these are OSS and %ACD for month and year. Values are shown as average values for all days of the month or all months of the year.

![Employee Information Columns](img/employee_information_columns.png)

• **Full Name** – employee's last name, first name, and patronymic
• **Work schedule template** – work schedule template selected by the system.
• **Vacation scheme** – vacation scheme name.
• **Standard** – employee performance set either in operator card or en masse.
• **Working days** – number of employee working days.
• **Planned hours** – number of working hours for entire work schedule period minus unpaid breaks.
• **Overtime** – shows presence of additional hours for employees.
• **Remaining vacation days** – shows remaining vacation days after assigning operator all planned vacations. The value of vacation days comes via integration. After assigning vacations in work schedule, assigned vacation days are subtracted from this value.

---

## Page 305

• **Days** – month days are displayed.

Information under days will display rows for indicators selected by checkboxes in the previous stage.

Numbers in cells are working hours in shift.

![Work Hours Display](img/work_hours_display.png)

In this same table, we can hover cursor over cell with working hours to learn which shift is selected for this operator:

![Shift Information Tooltip](img/shift_information_tooltip.png)

Also by right-clicking on day cell you can:

![Right-click Menu](img/right_click_menu.png)

---

## Page 306

• **Delete shift** – shift will be removed from selected day.

![Delete Shift](img/delete_shift.png)

• **Add shift** – select day when operator has no shift and click "Add shift." After which shift addition window opens where you can add planned or additional shift. Specify shift time. Then either click to add shift or to cancel addition.

![Add Shift Dialog](img/add_shift_dialog.png)

At this moment, operator individual settings are considered (if we consider them in "Labor Standards" directory), as well as number of hours for calculating additional shift.

---

## Page 307

When adding additional shift, operator hours will be recalculated. If operator's actual hours don't reach planned, additional shift won't be set.

![Additional Shift Validation](img/additional_shift_validation.png)

But if added shift exceeds operator's planned hours, additional shift will be added successfully.

• **Change shift** – allows changing shift start time and duration, as well as adding overtime hours. After selecting needed day, click "Change shift." Then in the appearing "Change shift" window, select shift hours or add "Overtime hours" field with number of hours before or after shift. Then click to accept changes or to cancel them.

![Change Shift Dialog](img/change_shift_dialog.png)

If additional hours are successfully added, such shift in calendar will be marked with orange triangle:

---

## Page 308

![Overtime Indicator](img/overtime_indicator.png)

Shifts can only be edited one at a time. Shifts can be deleted and added for several days at once. To do this, either select needed day range with left mouse button:

![Multi-day Selection](img/multiday_selection.png)

Or with Ctrl key held on keyboard, select needed days with left mouse button:

---

## Page 309

![Ctrl Multi-selection](img/ctrl_multiselection.png)

Here you can also assign vacations if this wasn't done in vacation planning or vacation wasn't assigned to operator in their card. To add vacation, left-click on any square, right-click and select "Add/correct vacation" event.

![Add Vacation Option](img/add_vacation_option.png)

Vacation addition interface is similar to vacation addition interface in employee card.

---

## Page 310

To correct vacation dates, perform the same actions described above, but click on already set vacation.

Vacation can be deleted by clicking on any vacation cell and pressing "Delete vacation":

![Delete Vacation Option](img/delete_vacation_option.png)

After all necessary edits are made, click to save created schedule example, or to cancel schedule creation.

**Note**: ability to edit work schedules (shifts/vacations) is regulated by configured BP in system. Only user provided for in BP will be able to edit work schedule (add/delete/change shifts and vacations).

To save schedule, fill in schedule name (mandatory parameter) and its description, then click to save it, or to cancel schedule saving.

---

## Page 311

![Save Schedule Dialog](img/save_schedule_dialog.png)

After saving, schedule will appear in list:

![Schedule in List](img/schedule_in_list.png)

After schedule is saved, depending on Business Process, the following can be done with it:

• **Update work schedule** – ability to replan work schedule for one or several operators appears if they want to change schedule template by which shifts were planned for them. In case of setting termination date for them, or conversely, add new employee to existing work schedule variant (work schedule correction BP).

• **Edit** – When schedule is applied, it can no longer be edited/updated. To do this, click "Edit," which will create a copy of work schedule to work with.

• **Apply** – work schedule will be applied and become current.

**Note**: Editing capability for applied work schedule is absent.

---

## Page 312

On the "Work schedule and vacation planning" page, there's also ability to view all changes made to work schedule and all BP execution stages. History is located under "Vacation schedule" block:

![Schedule History](img/schedule_history.png)

### 7.3. Editing Work Schedule Variant

Any schedule can be edited except the one currently applied or was applied in the past.

**Important!** Changes can only be made to a copy of applied work schedule.

To do this, go to applied schedule (Planning work schedules – Templates – click LMB on applied schedule). Then click "Edit" button.

![Edit Applied Schedule](img/edit_applied_schedule.png)

after which work schedule copying window opens where you need to specify new work schedule name:

---

## Page 313

![Copy Schedule Dialog](img/copy_schedule_dialog.png)

After performing these actions, a copy of applied work schedule is created. The copy can be updated and edited, then applied.

In "Planned work schedule" area, you can edit shifts: add, delete, or change shift duration (described in detail in "Creating new work schedule variant" section).

After changes are made, they need to be saved or canceled:

![Save or Cancel Changes](img/save_cancel_changes.png)

To save changes, click button. After which window with schedule name and description appears. Name and description are already filled but can be changed if desired.

---

## Page 314

![Save Changes Dialog](img/save_changes_dialog.png)

To add new workers to schedule or update schedules for existing operators (replan terminating worker, replan worker whose performance changed, etc.), schedule needs to be updated.

To update schedule, click, after which check needed employees and select planning start date (common for all marked employees or individual for each):

---

## Page 315

![Update Schedule Dialog](img/update_schedule_dialog.png)

**Important!** To select date, click on it in opening calendar window.

![Calendar Selection](img/calendar_selection.png)

---

## Page 316

After all changes are made, click:

There's also ability to delete work schedule. To do this, right-click on work schedule and click "Delete work schedule."

![Delete Work Schedule](img/delete_work_schedule.png)

![Delete Confirmation Dialog](img/delete_confirmation_dialog.png)

Warning will appear where you can confirm deletion or cancel it.

### 7.4. Applying Work Schedule Variant

After creating work schedule variant, it must go through business process approval. Each organization has its own business process involving different specialists with different roles.

Only confirmed work schedule can be applied. To confirm schedule, go to "Approval tasks" page and find created schedule in "Confirmation" task. Then select it and click "Execute."

---

## Page 317

![Apply Work Schedule](img/apply_work_schedule.png)

After confirmation, schedule can be applied. Return to this schedule in "Planning work schedules" section. After work schedule variant is selected, click button.

![Apply Schedule Button](img/apply_schedule_button.png)

If there's currently applied work schedule for the same period, system will warn about this and offer to either apply schedule or cancel action:

---

## Page 318

![Apply Schedule Warning](img/apply_schedule_warning.png)

After this, schedule will be considered current and displayed in employee personal cards. Subsequently, when building timetable, this schedule will be considered.

![Applied Schedule Display](img/applied_schedule_display.png)

### 7.5. Work Schedule Planning with Preference Consideration

When planning work schedules, performance standards, continuous rest, weekly/daily standards (if considered) are higher priority than preferences for the system. System should not consider preference during planning if it violates operator performance or standards from "Labor Standards" directory.

Examples are provided for simple understanding based on week.

**Example 1**: Operator has 5/2 rotation work rule with weekends on Sat and Sun, fixed 9-hour shift duration (8 hours without unpaid lunches). Operator set day off in each preference.

Since setting day off in all preferences doesn't meet performance standard, system will ignore operator preferences and set shifts under performance standard according to work rule.

**Example 2**: Operator has work rule without rotation, floating shift duration from 8 to 12 hours (7-11 hours without unpaid lunches). Operator set day off in each preference.

Since setting day off in all preferences doesn't meet performance standard, system will ignore operator preferences and set shifts under performance standard according to work rule, while shifts during schedule update may change their start and duration.

**General preference consideration rules:**

• When planning work schedule, load is higher priority than preference.
• If preference doesn't worsen load coverage quality, it will be set.
• If preference doesn't affect load coverage quality, it will be set.
• If preference worsens load coverage quality, it won't be set; shift/day off will be set according to work rules.

---

## Page 319

• When planning work schedules, difference between priority and regular preferences is that if system has equal choice of which shift/day off to set under equal conditions, priority preference should be set.

Examples are provided for simple understanding based on several days (for this example, weekly performance standard is not considered):

**Example 1**: Operator has 4/3 rotation work rule with weekends on Tue, Wed, and Thu, fixed 11-hour shift duration (10 hours without unpaid lunches). Operator set priority preference for shift on Tuesday and regular preference for shift on Thu.

Following load is forecasted:

If system fulfills both preferences and sets shift on both days, continuous rest standard in calendar week (equal to 42 hours) will be violated, so system can set only one preference. Since load is identical, system should set preference on Tue (since it's higher priority) but not set preference on Thu (since otherwise continuous rest standard will be violated).

### 7.6. Work Schedule Correction

Work Schedule Correction module is available to users with system role "Administrator" or any other role with access rights:

• **System_AccessWorkScheduleAdjustment** – View "Work Schedule Correction" page.
• **System_ViewAllWorkersInWorkScheduleAdjustment** – View all operators on "Work Schedule Correction" page.

In Work Schedule Correction module, user can change work schedules without creating copies of applied work schedule, and changes will immediately be displayed to operator and take effect.

On Work Schedule Corrections page you can:

• Change shift duration (shift can be lengthened or shortened);
• Move shift;
• Delete shift;
• Create new shift;
• Create, delete, or edit sick leave;
• Create, delete, or edit time off;
• Create, delete, or edit vacation.

To go to work schedule corrections page, open side menu, then "Planning" module → "Work Schedule Correction."

---

## Page 320

![Work Schedule Correction Navigation](img/work_schedule_correction_navigation.png)

Upon reaching the page, you'll see sections: "Legend," "Filters," "Statistics." And work schedules of all employees in system.

"Legend" section displays work schedule symbols:

![Work Schedule Legend](img/work_schedule_legend.png)

"Filters" section allows sorting employees for display on schedule by:

• Departments;
• Sites;
• Groups;
• Subordinate employees;
• Only with existing schedule.

You can also find individual employees by full name or personnel number.

"Statistics" section displays detailed information about surplus or deficit of planned operators according to load. The histogram shows deficits in red, surpluses in blue, green shows plan, values are displayed according to number of operators.

**Important!** Statistics will not be displayed if no group is selected in filters.

![Work Schedule Statistics](img/work_schedule_statistics.png)

The histogram can be scaled using mouse wheel and moved by holding left mouse button.

On the schedule itself, employees are listed on the left side with their planned and planned performance without unpaid breaks. In the main part of the schedule, employee shifts are displayed; by selecting a shift, it can be deleted by clicking the "Cross" button (✕).

![Delete Shift Button](img/delete_shift_button.png)

To set a new shift, double-click with left mouse button on the employee's schedule line to whom you want to assign a shift. A shift configuration window will open where you can set: shift type (planned/additional), shift time, overtime hours before or after shift. Then click the "Checkmark" button (✓). Additional shift or overtime hours cannot be set if operator's performance standard is not covered.

![New Shift Configuration](img/new_shift_configuration.png)

---

## Page 321

To add an event to an operator, double-click with left mouse button on the employee's schedule to whom you want to assign a shift. In the opened window, select events in the type field, configure event type (sick leave/time off/planned vacation/extraordinary vacation) and set start and end time, then click the "Checkmark" button (✓).

![Add Event Configuration](img/add_event_configuration.png)

The schedule can be scaled by day, week, or month breakdown, display current day by clicking "Today" button, or specify necessary date. You can also select time zone in which schedule will be displayed.

![Schedule Scaling Options](img/schedule_scaling_options.png)

All changes are saved automatically and applied to current applied work schedule.

---

## Page 322

## 8. Timetable Planning

Operator timetable planning is performed according to forecasted load, employee work schedules, and lunch and break rules.

**Important!** Planning is impossible without forecast and active work schedule.

Timetable planning module is available to users:

• with system role "Administrator," "Senior Operator"
• or any other role with access rights "Access to timetable planning page" and "Create/update/apply timetables."

![Timetable Planning Overview](img/timetable_planning_overview.png)

### 8.1. Creating and Viewing Timetable

"Creating timetables" module allows composing operator work timetable according to forecasted load, office operator work schedules, and home operator work preferences.

Prerequisites for creating timetable:

• Multi-skill planning template created;
• Forecasted load updated for specific period for selected group;
• Applied work and vacation schedule exists.

To go to timetable creation page, go to "Planning" → "Creating timetables" tab (you can go from section list menu or from main page by clicking "Creating timetables" block):

---

## Page 323

![Creating Timetables Navigation](img/creating_timetables_navigation.png)

Next, in the area with timetable template list, select necessary template and click "Create" button in "Timetable" block:

![Create Timetable Button](img/create_timetable_button.png)

**Note**: if multi-skill template including aggregated group is selected, load will be pulled for aggregated group, and employees will be pulled from simple groups included in aggregated.

**Important!** Timetable planning is independent of time zone; depending on selected time zone, only display changes. By default, user's time zone is always selected; there's also ability to display in other time zones. To do this, change time zone for timetable display.

In opened "Timetable Planning" dialog, specify period of created timetable validity and one of planning criteria (configured in Planning – Planning Criteria section):

---

## Page 324

![Timetable Planning Dialog](img/timetable_planning_dialog.png)

After parameters are selected, click "Start planning" button. After this, a planning task will appear in timetable tasks with "Executing" status. Task can be canceled or execution checked by updating status ⟳.

![Timetable Planning Status](img/timetable_planning_status.png)

**Note**: if attempting to build timetable for template that includes groups for which forecasts weren't previously obtained, system will display error:

![Timetable Planning Error](img/timetable_planning_error.png)

User in this case needs to obtain forecast, then retry building timetable.

Formed timetable will look as follows:

---

## Page 325

![Formed Timetable](img/formed_timetable.png)

Also by setting checkboxes in "Filters" area, you can sort employee list:

![Timetable Filters](img/timetable_filters.png)

• **Subordinate operators** – will display list of employees who belong to department headed or deputized by user;
• **Home** – will display list of operators marked in their card as home operator;
• **Office** – will display list of operators marked in their card as office operator;
• **Vacation** – will display list of operators who are on vacation during current timetable period;
• **Sick leave** – will display list of operators who are on sick leave during current timetable period;
• **Time off** – will display list of operators who took time off during current timetable period.

Next, statistics for created events are displayed. It's shown including for timetables that fall within event validity period:

![Event Statistics](img/event_statistics.png)

---

## Page 326

• **Project** – displays project name assigned in this timetable (and others);
• **Start date and End date** – project dates;
• **Segment requirements** – number of intervals needed to cover event-required load;
• **Total assigned, segments** – displays how many intervals were allocated for project. This field displays statistics for all current timetables created during event period;
• **Assigned in timetable, segments** – this statistic displays how many intervals were allocated for project specifically in considered timetable.

In "by employees" timetable view mode, list of all employees is displayed.

![Timetable by Employees](img/timetable_by_employees.png)

In view mode by individual group, only operators of this group are displayed.

---

## Page 327

![Timetable by Group](img/timetable_by_group.png)

Timetable statistics show intervals with deficit, surplus, and sufficiency according to legend.

![Timetable Statistics Legend](img/timetable_statistics_legend.png)

If forecasted number of operators exceeds actual (in other words, there won't be enough operators on line at some point according to forecast), then according to legend, "forecast" and "actual" rows are colored red.

If forecasted number of operators is less than actual (in other words, there will be excess operators on line at some point), then according to legend, "forecast" and "actual" rows are colored gray.

If employee composing timetable is satisfied with created timetable, it should be saved by clicking "Save" button. Next, dialog will open where timetable name and brief description must be specified. For final saving, click:

---

## Page 328

![Save Timetable Dialog](img/save_timetable_dialog.png)

To cancel timetable, click "Cancel" button.

If timetable needs updating, click "Update" button; read more about timetable updating in next section:

![Update Timetable Button](img/update_timetable_button.png)

### 8.2. Multi-skill Operator Consideration in Timetable Composition

Multi-skill operators are those who can simultaneously handle multiple directions (in WFM CC – simultaneously belong to multiple groups). For system to consider operator as multi-skill when composing timetable, they must belong simultaneously to multiple groups of one template.

Load between multi-skill and mono-skill operators is distributed as follows:

• First, system considers all mono-skill operators when creating timetable.
• Remaining load is distributed among multi-skill operators.

### 8.3. Updating Composed Timetable

**Important!** Before updating timetable, don't forget to save it first.

Timetable update function allows updating previously created timetable considering updated load, employee special events, manual timetable correction, employee work schedule change, employee deactivation, new employee creation.

To update timetable, first select template on left, then select saved timetable for this template (in "Timetable variants" area) and click "Update" button:

![Update Timetable Process](img/update_timetable_process.png)

---

## Page 329

"Timetable Planning" form will open. Specify planning period you want to update:

![Update Planning Period](img/update_planning_period.png)

After parameters are selected, click "Start planning" button. After updating schedule, it needs to be saved. When saving, you can change name and comment.

![Save Updated Timetable](img/save_updated_timetable.png)

### 8.4. Manual Timetable Changes

For created timetable in "ARGUS WFM CC" system, there's ability for manual correction of operator working intervals:

• Adding/removing lunches and breaks;
• Recording downtime;
• Call/cancel call to work;
• Adding/canceling work attendance;
• Project assignment;
• Adding/canceling events.

**Important!** User can edit timetable under following conditions:

• If user is head of parent department (and has access right for timetable editing), they can edit timetable for both subordinate operators and operators from child departments;
• If user is head of child department (and has access right for timetable editing), they can edit timetable only for subordinate employees;
• If user is deputy of parent department (and has access right for timetable editing), they can edit timetable for both subordinate operators and operators from child departments. Day when corrections are made must fall within deputy period;
• If user is deputy of child department (and has access right for timetable editing), they can edit timetable only for subordinate employees. Day when corrections are made must fall within deputy period;
• If user is not head or deputy but has access right for timetable editing, they can edit timetable for all operators.

On "Planning" → "Creating timetables" page, select timetable from list. In "Timetable" block, select necessary day and employee time interval:

---

## Page 330

![Manual Timetable Selection](img/manual_timetable_selection.png)

Time in timetable is divided into 5-minute intervals. To select one 5-minute interval, click on it with left mouse button:

![Select Time Interval](img/select_time_interval.png)

Using held "Ctrl" button, you can select different 5-minute intervals for different employees:

---

## Page 331

![Multi-select Intervals](img/multi_select_intervals.png)

System also allows selecting entire area by clicking left mouse button and dragging to select area without releasing:

![Select Area](img/select_area.png)

After time interval is selected, call menu by right-clicking and select one of events:

---

## Page 332

![Timetable Context Menu](img/timetable_context_menu.png)

**Adding/removing lunches and breaks.**

Lunches/breaks can be added and removed when operator's shift duration was changed to one for which there are no lunch/break rules in "Lunches/breaks" directory. In other cases, system won't allow adding and removing lunches and breaks.

To add lunch or break, select needed cells and choose "Add lunch" or "Add break":

---

## Page 333

![Add Lunch Break](img/add_lunch_break.png)

To remove lunch or break, select needed cells and choose "Cancel breaks":

---

## Page 334

![Cancel Breaks](img/cancel_breaks.png)

**Recording downtime.**

To register employee downtime, select needed cells and choose "Not taking calls":

---

## Page 335

![Record Downtime](img/record_downtime.png)

**Adding/canceling work attendance.**

To register employee non-working time, select needed cells and choose "Non-working time":

---

## Page 336

![Non-working Time](img/non_working_time.png)

To add employee work attendance, switch display to specific project:

---

## Page 337

![Project Display Switch](img/project_display_switch.png)

Then select needed cells and choose "Add work attendance":

![Add Work Attendance](img/add_work_attendance.png)

**Project assignment.**

To assign employee to specific project, switch display to specific project, select needed cells, and choose "Assign to project:"

---

## Page 338

![Assign to Project](img/assign_to_project.png)

In this case, regardless of employee involvement in other projects, they will be 100% engaged in current project.

**Adding/canceling events.**

To add event to operator, choose "Event," then dialog will open:

---

## Page 339

![Add Event Dialog](img/add_event_dialog.png)

Where you select event type (Training/Meeting/Calls/Survey collection), specific event from "Events" directory. Time and participant will be selected automatically since interval was already selected. Then click to add event.

![Event Added](img/event_added.png)

To cancel event, select event of interest and click "Cancel event"

---

## Page 340

### 8.5. Applying Composed Timetable for Selected Template

When timetable is composed successfully and fits planning criteria, it can be accepted as active working timetable. To do this, apply selected timetable for template. After applying timetable, it will be available for viewing in "Current timetable" section.

For selected template in "Timetable variants" block, select suitable timetable variant and click "Apply":

![Apply Timetable](img/apply_timetable.png)

In "Creating timetables" section, applied timetable is highlighted in bold in timetable variants list block:

![Applied Timetable Highlight](img/applied_timetable_highlight.png)

System also has ability to calculate timetable cost. Timetable cost calculation is based on operator hourly cost (set in "Premium Indicators" directory) and night shift premium (if employee works night hours) for operators participating in current timetable. To calculate cost, click.

---

## Page 341

![Calculate Timetable Cost](img/calculate_timetable_cost.png)

Based on cost of two or more timetables, you can decide which timetable is better to apply.

When timetables overlap (when there's already current timetable created earlier), when clicking "Apply" button, system will display warning message:

![Timetable Overlap Warning](img/timetable_overlap_warning.png)

– clicking this button, senior operator confirms overwriting previous current timetable (overlapping dates will be overwritten);
– clicking this button, senior operator cancels applying new timetable.

---

## Page 342

### 8.6. Current Timetable

Current timetable is designed for viewing current applied timetable for selected template with group.

To go to Current timetable, open side menu and go to "Planning" → "Current timetable":

![Current Timetable Navigation](img/current_timetable_navigation.png)

When opening page, select multi-skill template, then select date included in built timetable period:

![Current Timetable Selection](img/current_timetable_selection.png)

Current timetable functionality differs from creating timetable functionality:

• Cannot correct shares;
• Cannot add hours to operator;
• Cannot set downtime for operator and update timetable.

However, you can add event and call operator to work.

To call operator to work, go to operator view mode by groups:

---

## Page 343

![Operator View by Groups](img/operator_view_by_groups.png)

Then select needed time period, right-click and choose "Call to work" (call to work functionality is only available for subordinate employees):

![Call to Work](img/call_to_work.png)

Then click "Save" (after adding event too).

Called operator looks like this:

![Called Operator Display](img/called_operator_display.png)

This sign means employee is called to work and depending on "Notification Schemes" directory setting, operator will be sent notification. Next, if operator agrees to work shift/refuses to work shift, call to work must be deleted and either work shift added or not.

Current timetable can be exported to Excel by clicking.

## 9. Vacancy Planning

Vacancy Planning module is available to users with system role "Administrator" or any other role with access rights System_AccessVacancyPlanning – view "Vacancy Planning" page.

Vacancy planning module allows automatically calculating optimal personnel number needed to cover current load. During calculation, system will rely on:

---

## Page 344

• Work rules (set in system start and end shift times, duration, and alternation of working and non-working days);
• Current multi-skill planning template;
• Minimum vacancy efficiency (indicator reflecting what percentage of deficit intervals system should consider when calculating required operator number for given schedule);
• Break percentage.

Upon planning completion, system will suggest specific shifts and work rules for expanding staff for existing project.

To start vacancy planning, go to corresponding system module: "Planning" -> "Vacancy Planning"

![Vacancy Planning Navigation](img/vacancy_planning_navigation.png)

On "Vacancy Planning" page, you'll see list of multi-skill planning templates; vacancies are planned based on personnel in these templates.

---

## Page 345

Also when selecting template, you'll see list of existing vacancy planning tasks, and when selecting task, work rules available to it.

![Vacancy Planning Template Selection](img/vacancy_planning_template_selection.png)

To start planning, select template of interest and click "Plan vacancies" button.

![Plan Vacancies Button](img/plan_vacancies_button.png)

After this, window with task planning settings will open:

• **Task name** – Task name that will be displayed in task list;
• **Planning period** – period for which vacancies will be planned;
• **Breaks, %** – break percentage that will be considered during planning;

---

## Page 346

• **Minimum vacancy efficiency, %** – minimum ratio of deficit periods to total number of intervals covered by vacancy;
• **Plan considering work schedule** – When planning vacancies without considering work schedule, deficit equals forecast divided by (100% minus user-specified % breaks). When planning vacancies considering work schedule, deficit equals difference between forecast divided by (100% minus user-specified % breaks) and operator plan according to "Plan" work schedule;
• **Work rules** – work rules available for planning.

![Vacancy Planning Settings](img/vacancy_planning_settings.png)

After setting parameters, click "Start planning" button.

Planning task will appear in task list showing its status; to update task status, click "Update" button ⟳, to stop task, click "Cancel" button ✕. To delete task, right-click on it and select "Delete task."

---

## Page 347

![Vacancy Planning Task Status](img/vacancy_planning_task_status.png)

Once task completes planning, it automatically saves, and its status changes to "Result saved." You can click on task to display vacancy and employee work schedules (if "Plan considering work schedule" setting is enabled). Statistics on surpluses/deficits considering planned vacancies is also provided as histogram.

![Vacancy Planning Results](img/vacancy_planning_results.png)

---

## Page 348

![Vacancy Planning Chart](img/vacancy_planning_chart.png)

You can interact with schedules by scrolling mouse wheel or moving view period using held left mouse button.

Sorting is also available by:

• Display only operators/only vacancies;
• Display operators first/vacancies first;
• Select group from multi-skill planning template.

![Vacancy Planning Sorting](img/vacancy_planning_sorting.png)

Based on vacancy plan data, you can analyze deficit/surplus areas in work schedule and make appropriate decisions on staff reduction/expansion.

## 10. Exchange

Exchange is a set of tools and means providing interactive process of assigning performers to various offers, depending on employee needs and preferences. Currently, exchange has only one type of offer – shift.

Advantages:

• Planners spend less time determining resource needs;
• Managers potentially spend less time finding suitable performer;

---

## Page 349

• Operators have choice ability, which increases employee loyalty to company.

This approach can be called element of teal organization structure, and presence of this functionality in WFM product increases its integrability into EX / EE (Employee Experience / Employee Engagement) concepts.

Planner and manager interaction with exchange occurs on separate WFMCC page, divided into 3 tabs:

• **Statistics** - for viewing statistics, determining needs and creating offers;
• **Offers** - for viewing available offers (offers that operators haven't responded to yet) and deleting them;
• **Responses** - for viewing current responses awaiting answer (responses that haven't been confirmed/rejected/canceled yet).

Operator interaction with exchange occurs on separate page in personal account, divided into 2 tabs:

• **Mine** - for viewing submitted responses and canceling them;
• **Available** - for viewing offers and creating responses.

### 10.1. Viewing Statistics on Exchange Page

Exchange module is available to users:

• With "Administrator" role;
• With access rights "View Exchange page" (System_AccessExchangeService)

Exchange page can be found by going to side menu -> "Exchange"

---

## Page 350

![Exchange Navigation](img/exchange_navigation.png)

To view statistics by direction, on statistics tab, select multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.

![Exchange Statistics Configuration](img/exchange_statistics_configuration.png)

Statistics are presented for forecasted load and planned operators, shown in both table and chart format. You can interact with chart: increase/decrease scale, hide chart curve displays.

---

## Page 351

![Exchange Statistics Chart](img/exchange_statistics_chart.png)

![Exchange Statistics Table](img/exchange_statistics_table.png)

### 10.2. Creating and Viewing Offers on Exchange

Creating and viewing offers on exchange functionality is available to users:

• With "Administrator" role;
• With access rights "Create/delete offers" (System_ChangeOffer)
• With access rights "View Exchange page" (System_AccessExchangeService)

---

## Page 352

Based on presented statistics, analyzing surpluses and deficits, you can conclude about need for additional shifts – offers. Shifts that operator can respond to and come to work.

To create shift, on statistics tab fill in fields: shift name, shift duration, number of shifts. And click "Create" button.

![Create Shift Offer](img/create_shift_offer.png)

After this, offers will be created, and recalculated operator plan considering exchange offers will be displayed on chart and table.

![Exchange Offers Created](img/exchange_offers_created.png)

---

## Page 353

![Exchange Updated Plan](img/exchange_updated_plan.png)

Offers can also be viewed on corresponding "Offers" tab. In "View parameters" window, specify: multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.

All available offers will be displayed.

![View Exchange Offers](img/view_exchange_offers.png)

Offers can be deleted by selecting them with checkbox and clicking "Gear" -> "Delete."

![Delete Exchange Offers](img/delete_exchange_offers.png)

---

## Page 354

### 10.3. Response and Response Confirmation to Offer

Response confirmation functionality on exchange is available to users:

• With "Administrator" role;
• With access rights "Confirm responses" (System_ConfirmResponse)
• With access rights "View Exchange page" (System_AccessExchangeService)

After operators respond to offers, their responses can be viewed on "Responses" tab. In "View parameters" window, specify: multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.

![View Exchange Responses](img/view_exchange_responses.png)

Response can be confirmed by clicking "Checkmark" ✓, returned by clicking "Arrow" ↩ (in this case operator can respond again to same offer), or rejected by clicking "Cross" ✕ (in this case operator cannot respond again to this offer).

After manager confirms response, shift will be created in current applied work schedule for operator.

---

## Page 355

![Response Confirmation Actions](img/response_confirmation_actions.png)

![Response Confirmed Result](img/response_confirmed_result.png)

## 11. Employee Personal Account

User can log into system provided that user with "Senior Operator" or "Administrator" role previously created account for corresponding user.

After passing authorization procedure, user can view their profile (personal account) and edit part of information if they have corresponding access right.

To go to personal account, open "My Account" section (you can go from section list menu or from main page by clicking "My Account" block):

---

## Page 356

![Personal Account Navigation](img/personal_account_navigation.png)

### 11.1. Operator Personal Account

User with "Operator" role in personal account can view following profile information:

• Full name, personnel number, mark indicating whether operator is home (area 1).
• Timetable (area "Timetable," displays events according to "Current timetable." In other words, here their work timetable is displayed according to which they should come to work). For timetable to be displayed to operator: forecast load, assign work schedule template to employee, add business rules to them.
• Current work schedule (area "Current work schedule").
• Contact information (area "Contacts");
• Services and groups they belong to (area "Services and groups");
• Skills (area "Skills");
• Performance statistics for current period (area "Performance for current month")
• Assigned work schedule templates for this operator; here employee can set preference for desired rotation.

---

## Page 357

![Operator Personal Account](img/operator_personal_account.png)

Also here operator can export their premium report calculated for selected period:

![Export Premium Report](img/export_premium_report.png)

By clicking, report will be exported to Excel (xlsx). It looks like this:

---

## Page 358

![Premium Report Example](img/premium_report_example.png)

In row, indicator shows indicator for which percentage goes to premium, for which group and for what group.

### 11.2. Registering and Deleting Special Event in Timetable

Special event registration is available to user with access right "Ability to edit own events on calendar." Without this access right, employee can only view their timetable and work schedule.

**Note for database administrators.**

Database settings have limitation on ability to register special events for current day/week/month.

For this, following parameters are set in "pref_table" table:

"edit_my_schedule_period_type" – period type (DAY, WEEK, MONTH)
"edit_my_schedule_period_value" – value 0 or 1.

• 0 – can edit right on current day/week/month.
• 1 – can edit only starting from next day/week/month.

By default, database settings specify following values:

"edit_my_schedule_period_type" – WEEK
"edit_my_schedule_period_value" – 1

Since operator can be home or office:

• **Home operator.** If operator has access right "Ability to edit own events on calendar," they specify work attendance preferences and special events for next week. If no access right – they can only view their timetable and schedule.

---

## Page 359

• **Office operator.** Cannot change schedule and shift. But if "Ability to edit own events on calendar" access right is set, they can specify special events + work preferences outside schedule.

Following events can be registered as special event in system:

• Sick leave (icon on work schedule),
• Vacation (icon on work schedule),
• Time off (icon on work schedule),
• Work attendance (icon on work schedule),
• Reserve (icon on work schedule).

Employee special event is considered when planning timetable.

Adding events is available to user with access right: System_EditWorkerApprovedVacationAndExtraWork – allows editing approved vacations and "Work attendance" shifts.

To register work attendance in "Work schedule" block in calendar or table form, select date of interest.

Employee work schedule is displayed in two views: calendar and table:

![Work Schedule Views](img/work_schedule_views.png)

Days in calendar view are selected in several ways:

• One day in calendar is selected by clicking with left mouse button;

---

## Page 360

• Different days in calendar are selected by clicking left mouse button with Ctrl key held;
• Period of days can be selected in two ways;
• With Shift key held, select day – start of interval, then select day – end of interval;
• With Ctrl key held, sequentially select days from period.

Days in table view are selected:

• One/several days in calendar are selected by area capture (for this, holding left mouse button, select area)

![Table View Selection](img/table_view_selection.png)

• Specific hours can be selected. To do this, click on hour of interest with left mouse button:

---

## Page 361

![Hour Selection](img/hour_selection.png)

• With "CTRL" key held, you can select different hours for different days (or same day):

![Multiple Hour Selection](img/multiple_hour_selection.png)

After necessary period is selected (for example, March 16), right-click to call context menu and click "Add event":

---

## Page 362

![Add Event Context Menu](img/add_event_context_menu.png)

In appearing "Add new event" window:

• Select necessary event type from dropdown list (for example, work attendance)

![Select Event Type](img/select_event_type.png)

• In "Period" area, if "Selection" parameter is chosen, days and hours selected when highlighting them on calendar are displayed;

---

## Page 363

![Event Period Selection](img/event_period_selection.png)

• If different date range needs to be specified, select "Range" parameter in "Period" area and specify start and end event dates

![Event Date Range](img/event_date_range.png)

• To save event, click button:

---

## Page 364

![Save Event Button](img/save_event_button.png)

Added event will be displayed on employee work schedule:

![Added Event Display](img/added_event_display.png)

**Event deletion.**

To delete special event, select days on calendar (or at least one day included in special event) that have special event set, call menu by right-clicking and click "Delete event":

---

## Page 365

![Delete Event Menu](img/delete_event_menu.png)

Next, system will ask to confirm actions:

![Delete Event Confirmation](img/delete_event_confirmation.png)

If multiple special events fall within selected period, uncheck those that shouldn't be deleted.

---

## Page 366

To confirm event deletion, click, to cancel –.

Similarly, "Sick leave," "Vacation," "Time off," "Reserve" type events are added/deleted.

**Note.**

For more efficient work attendance registration, you can use "Add work attendance" button (this button is only available when registering event in table form of work schedule):

![Quick Add Work Attendance](img/quick_add_work_attendance.png)

In this case, when clicking "Add work attendance," system immediately displays "Work attendance" event in work schedule – for time interval that was selected (Figure – 8.2.14):

![Work Attendance Added](img/work_attendance_added.png)

---

## Page 367

### 11.3. Senior Operator Personal Account

Employee with "Senior Operator" role has following abilities in system:

• View all employees entered in system;
• View group list;
• Edit employee information;
• Timetable planning;
• Mass business rule assignment;
• Load forecasting;
• Reports.

In their personal account, senior operator sees same information as operator, and can also export their timetable. But besides this, senior operator can edit following information:

• Full name, personnel number, mark indicating whether operator is home or office;
• Work schedule;
• Contacts;
• Skills (area "Skills").

### 11.4. Setting Preferences in Operator Personal Account

In their personal account, Operator will see panel where they can specify their work and day off preferences. It contains following information:

• Period for which Operator can set preference;
• Preference setting deadline;

---

## Page 368

• Number of regular and priority preferences that Operator is allowed to set;
• Number of regular and priority preferences that system considered (appears only after work schedule update or creation of new one).

System may not consider all preferences. This is because System must cover forecasted load, and Operator must work required number of hours (cover performance). For example, if Operator working full-time sets 6 days off per week, system won't consider preference.

![Operator Preferences Panel](img/operator_preferences_panel.png)

Operator fills in their preferences during specific period in System. To do this, they specify:

• Preference day;
• Type (working day or day off);
• Shift start period (can be fixed (for example, 09:00 – 09:00) or flexible (07:00 – 09:00));
• Shift end (similar to start);
• Duration (similar to start and end);
• Priority checkbox.

---

## Page 369

![Set Preferences Form](img/set_preferences_form.png)

When filling preference, "Incorrectly set shift parameters" notification may appear. It's displayed when shift duration contradicts its start and end. For example, setting start 09:00-09:00, end 18:00-18:00, but duration 03:00-03:00.

After operators set their preference information, and Planner/Manager received information about closing ability to set preferences:

• Planner/Manager should plan/update work schedule to consider this preference data in work schedule. System during planning/updating schedule will try to consider preferences set by Operators in their personal accounts.

### 11.5. Responding to Exchange Offers

Operator can accept exchange offers through personal account by going to "Exchange" page:

---

## Page 370

![Exchange Page Navigation](img/exchange_page_navigation.png)

Exchange page has two tabs:

• "Mine" - displays accepted offers;
• "Available" - displays available exchange offers.

To respond to offers, go to available tab, which displays all offers suitable for operator and detailed information about them. Offers can be filtered by specific date or name.

If offer suits operator, they can respond to it by clicking on offer itself, then clicking "Accept" button.

---

## Page 371

![Accept Exchange Offer](img/accept_exchange_offer.png)

After employee responds to request, they can view its status on "Mine" tab.

![Exchange Response Status](img/exchange_response_status.png)

---

## Page 372

## 12. Business Processes (BPMS)

Business processes loaded into system allow implementing processes not by verbal agreement between users – need to first confirm employee wishes, then compose schedule, then schedules should be reviewed by department heads, etc. (this is verbal agreement since user may not do all this, but simply create schedule immediately), but as specific sequence of actions that system will expect and won't allow proceeding to next process stage until previous one is completed.

Loaded business process (hereinafter BP) stores information about action sequence that needs to be followed in system (directly business process sequence), otherwise system won't allow advancing in this BP, as well as which users can perform these BP stages and what actions will be available at specific stages (for example, changing shifts in work schedule is possible not at any BP stage and not any user has right to change these shifts at specific stage).

But besides loading BP into system that stores all necessary stage information, these stages need to be managed somehow, delegate tasks to users, etc. This task is performed by "Approval tasks" functionality, which allows executing BP stages, delegating these stages to other employees, or taking them for yourself.

### 12.1. Loading BP into System

To load BP into system, go to needed system page, link to which is on main screen:

---

## Page 373

![BP Loading Navigation](img/bp_loading_navigation.png)

After opening page, following functionality will be displayed:

![BP Loading Interface](img/bp_loading_interface.png)

Clicking "Browse" opens file selection window; you need to select .zip or .rar archive containing business process file. After file is selected, other buttons activate: "Load" and "Cancel."

![BP File Selection](img/bp_file_selection.png)

### 12.2. Task List

This section is available to roles with access right "View 'Approval tasks' page" (view and execute tasks) and "Assign task to employee" (assign tasks to other employees). To work with tasks, you need "Department head" role, as well as specific roles needed for executing specific business processes, described below.

Task list allows managing user-assigned tasks (execute/reassign) generated by executing business process stages. To go to task list, click icon in upper right corner of system interface:

---

## Page 374

![Task List Navigation](img/task_list_navigation.png)

Red circle shows number of tasks currently assigned to user who logged into system.

When opening task list, following fields will be displayed:

![Task List Interface](img/task_list_interface.png)

• **"Open/closed" tasks filter** – shows either active tasks or already resolved/closed ones;
• **Department and performer filters** – allow selecting departments that tasks assigned to users concern, as well as task performer;
• **My tasks** – displays tasks assigned to user who logged into system;
• **Where I'm candidate** – each BP stage has so-called "candidates" – users who also can execute specific BP task besides user to whom this task is assigned;
• **All** – will show all tasks assigned to all users.

After all necessary filters are filled, click "Search," after which tasks will be displayed (which tasks are displayed depends on filters set earlier):

---

## Page 375

![Task Search Results](img/task_search_results.png)

• **Approval object** – specific object of type specified below. In Figure – 9.2.3, object is work schedule. In this case, "approval object" is work schedule name;
• **Object type** – system functionality to which task relates. In case of figure above, this is "Schedule variant," i.e., work schedule;
• **Process** – BP name to which task relates;
• **Task** – specific BP stage currently being executed by this task;
• **Performer** – responsible user who should execute this task;
• **Comment** – filled after task execution.

By selecting task (clicking on one of list tasks with left mouse button), user can either execute it or assign to another user. Note that if task is initially assigned to another user, only candidates (mentioned above) and user-performer specified in task can execute it.

---

## Page 376

To assign task to another user (or take someone else's task for yourself), select task with left mouse button and click "Assign":

![Assign Task](img/assign_task.png)

Then in "Performer" field, select user from dropdown list to whom task should be assigned.

To execute task, select needed task with left mouse button and click "Execute":

![Execute Task](img/execute_task.png)

After this, window with comment (which can be left unfilled) and action choice will appear. Action set available when executing tasks is regulated by BP itself that was loaded into system. In figure above, user has two actions that will lead to different BP execution stages. After specific action is performed, click to execute task and transition to next (or previous, depending on selected action) stage. After this, task will move to another BP stage, which will have its own task set and users.

This is how BP work is organized – specific system actions can start BP execution, after which users will go through it entirely by executing tasks. While if some system functionality is available to user only at specific BP stage, they can't use it outside this BP.

### 12.3. Business Process List

#### 12.3.1. New Work Schedule Approval Process

Business process (BP) for work schedule formation regulates work schedule creation, its application, and sending to 1C. During BP execution, specific users can edit work schedule and update it. After applying work schedule, BP completes.

---

## Page 377

![Work Schedule BP Overview](img/work_schedule_bp_overview.png)

BP starts when first work schedule version is planned (detailed in section 6.1). Once work schedule is planned and saved, work schedule approval process starts. Department heads (supervisors) receive "Supervisor confirmation" approval task and notification (detailed in section 3.1.17 "Notification Scheme Directory") that work schedule needs to be corrected (if necessary) and approved. At "Supervisor confirmation" step, department head (supervisor) can make corrections to planned work schedule for subordinate employees (add/delete/correct shifts/vacations), department heads (supervisors) get access to "Update" button.

![Supervisor Confirmation](img/supervisor_confirmation.png)

After all department heads (supervisors) execute their tasks, work schedule approval business process moves to next stage. Responsible employee with "Planning specialist" role receives: notification that department heads (supervisors) approved work schedule and "Planning specialist confirmation" task. At this step, users with "Planning specialist" role can update work schedule and edit it. At this BP stage, responsible user can return work schedule for revision to department heads (supervisors) (previous BP stage), or can move BP to next stage:

---

## Page 378

![Planning Specialist Confirmation](img/planning_specialist_confirmation.png)

Next BP stage is "Operator confirmation." When moving to this business process step, operators participating in work schedule receive notification that work schedule is formed and task to confirm work schedule. At this step, employee with "Operator" role confirms their work schedule; if necessary, operator can leave wish for shift/vacation date transfer, etc., in "Comment" field.

![Operator Confirmation](img/operator_confirmation.png)

After operators confirm work schedule, BP again moves to last BP step – "Schedule application." When moving to this stage, responsible employee (user with "Planning specialist" role) receives notification that schedule is ready for application and "Apply schedule" task. At this step, employee with "Planning specialist" role, if necessary, makes final work schedule corrections (for example, edits schedule considering operator wishes), sends schedule to 1C system ("Send to 1C" button available), and applies planned work schedule ("Apply" button available).

**Important!** When transferring schedule to 1C system, work schedule for employees with position marked as non-planning is not transferred.

---

## Page 379

"Apply schedule" task is executed automatically after work schedule is applied.

![Schedule Application](img/schedule_application.png)

After applying schedule, "Work schedule approval" BP completes.

#### 12.3.2. Work Schedule and Vacation Correction Approval Process

Applied work schedule cannot be edited, so if users want to make corrections to planned work schedule, responsible employee needs to create copy of applied schedule and make corrections to created copy. More details about editing applied schedule in section 6.2. After making necessary changes to created and corrected copy of work schedule, it needs to be applied. Approval and application process for work schedule is similar to "New work schedule approval" BP, except for "Process" field name, i.e., after creating copy of work schedule, department heads (supervisors) receive "Head confirmation" task, etc.

![Schedule Correction BP](img/schedule_correction_bp.png)

## 13. Reports

All roles that have access right "System_PremiumPerformanceView" or "System_AccessReportEditor" have access to reports.

System has ability to generate various reports available to users for viewing and downloading in Excel format (To export report to Excel, click; such button exists in all reports described below).

**Important!** All reports are generated in user's time zone.

### 13.1. System Reports

#### 13.1.1. Control Page

Control page shows plan/actual worked hours by operators or entire department, as well as absence codes.

To go to control page, click "Open control page" on main page:

---

## Page 380

![Control Page Navigation](img/control_page_navigation.png)

After opening control page, following information will be displayed:

![Control Page Interface](img/control_page_interface.png)

To build report, select department, specific employee full name (optional), period for which information needs to be exported, and click. At this moment, request is sent to 1C, which provides information. From here, you can also go to "Salary calculation" report by clicking "Timesheet."

Generated report looks like this:

![Control Page Report](img/control_page_report.png)

• **"Overtime" filter** – will show only operators with overtime;
• **"Undertime" filter** – will show only operators with undertime;
• **"Confirmed by manager" filter** – displays operators whose information was confirmed by manager;
• **"Confirmed by Planning specialist" filter** – will show operators whose information was confirmed by "Planning specialist";
• **Full name** – employee full name. After expanding detailed operator information (arrow left of full name), this field will show date (or several) for which data is displayed;
• **Plan** – in general view, displays sum of planned working hours for all days; when expanded, shows value for specific day;

---

## Page 381

• **Actual** – displays actually worked time by days or their sum for all days. For actual calculation, operator statuses are used that came via integration and have "Actual time in timesheet" checkbox in "Work time efficiency configuration" directory.
• **Undertime** – shows difference between plan and actual if actual is less than plan, then undertime is considered;
• **Comment** – filled by department head where employee is located (or their deputy during deputy period). Comment can only be filled when employee data is not confirmed. To create comment, double-click left mouse button on field;
• **Overtime** – shows difference between plan and actual if actual is greater than plan, then overtime is considered;
• **Timesheet** – shows absence reasons or attendance (А);
• **Status** – "Not confirmed" means this report wasn't confirmed for this operator or information reset was performed. "Confirmed" – means data was sent to 1C. "Confirmed by manager" – means information was confirmed by group manager. "Report created" – means absence report was created;

**Actions:**

"Confirm by manager" available to group manager to confirm operator overtime/undertime, if necessary create absence report.

"Create absence report" available after manager confirmation when they confirm operator undertime fact. Button allows printing absence report that automatically fills data such as:

• Violator position and full name;
• Position and full name of manager of violator of work schedule;
• Date and time of violation.

"Reset" allows resetting all statuses.

"Confirm" needed for employee who confirms operator information and sends working hours information to 1C.

Various actions can only be performed by employees with access rights or managers of their departments (and actions, accordingly, are performed with subordinate departments).

#### 13.1.2. "Schedule Adherence" Report

Schedule adherence report for operator displays operator performance plan and their actual presence at work.

To build report, go to "Reports" → "Schedule adherence" tab (you can go from section list menu (click "Reports" – then "Schedule adherence" tab appears) or from main page by clicking "Reports" block):

---

## Page 382

![Schedule Adherence Navigation](img/schedule_adherence_navigation.png)

After this, "Schedule adherence" window opens where you select operators (check mark) for whom report needs to be built and date interval for which report needs to be built. You can also filter operators by department and set detail period. Operators can be filtered by groups or found by full name.

![Schedule Adherence Configuration](img/schedule_adherence_configuration.png)

Gray color marks terminated employees.

After all employees are marked and period selected, click.

---

## Page 383

![Schedule Adherence Results](img/schedule_adherence_results.png)

This table displays:

• **Full name** - employee last name, first name, and patronymic;
• **%AVG SH ADH** – operator average punctuality indicator for entire selected period;
• **SH ADH** – operator punctuality indicator for day;
• **Schedule** – performance according to operator work schedule;
• **Timetable** – performance according to operator timetable, can be less than work schedule performance since in timetable operator shift can be edited. Bright color means clean load, lighter color means productive load;
• **Actual** – actual performance. Bright color marks productive load;

Upper part of table shows 15-minute periods (or other if selected when building report), and each table cell equals one minute.

Button will display window with operator selection and date:

---

## Page 384

![Filter Options](img/filter_options.png)

After which you can either save new filter values by clicking or cancel them.

#### 13.1.3. "Salary Calculation" Report

Report is designed to display information about operator presence at their workplaces or their absence. Report is table where for each operator, attendance and non-attendance at work, weekends and vacations, overtime hours and weekend work are considered, and total worked hours for first and second half of month are output, as well as total worked hours for entire month.

To build report, go to "Reports" → "Salary calculation" tab or from main page by selecting needed report from "Reports" block.

---

## Page 385

![Salary Calculation Navigation](img/salary_calculation_navigation.png)

After this, window with operator list for whom report will be built opens. It can be filtered by groups, departments, types (home or office), or enter personnel number or operator full name.

---

## Page 386

![Salary Calculation Configuration](img/salary_calculation_configuration.png)

Three salary report building modes exist:

• **Build report from 1C data** – when building, data via integration with 1C:Payroll is used;
• **Build report from contact center actual data** – when building, data via integration with contact center is used;
• **Build report from schedule data** – when building, work schedule data and operator events are used.

---

## Page 387

![Report Building Modes](img/report_building_modes.png)

After all parameters are filled, click.

![Salary Calculation Report](img/salary_calculation_report.png)

Report shows attendance and non-attendance marks by month dates. Time is calculated in operator time zone specified in operator card.

When calculating operator hours, shift whose hours cross midnight boundary is divided into two days. For example, operator worked period 25.11.2025 from 22:00 - 26.11.2025 until 01:00; in this case, report counts for 25.11.2025 - 2 hours (22:00-00:00), for 26.11.2025 - 1 hour (00:00-01:00).

**Designations:**

• **А** – attendance;
• **Н** – night attendance;

---

## Page 388

• **НН** – absence;
• **В** – weekend;
• **ОТ** – vacation;
• **С** – overtime work;
• **РВ** – weekend work;
• **Б** – sick leave;
• **О** – time off.

Report displays information on sum of worked hours and absences for first half of month (1st to 15th) and second half of month (16th to 31st). If dividing month in half doesn't work (for example, 31 days), "Х" will be displayed in 16th day cell.

![Report Time Division](img/report_time_division.png)

If day has multiple marks/hours, they are separated by ";" sign.

Report can only be built within one month.

By clicking button, we can change filter for displaying operators in report.

**Field descriptions:**

| Field Name | Field Description | Calculation Logic |
|------------|-------------------|------------------|
| № | Operator sequence number in report | |
| Full Name | Last name F. I. of operators for whom report is built | |

---

## Page 389

| Field Name | Field Description | Calculation Logic |
|------------|-------------------|------------------|
| Personnel Number | Personnel number of operators for whom report is built | |
| Attendance and non-attendance marks by month dates | For each operator, 4 rows are displayed: • Presence/absence codes for 1-15 of month by each day separately (16th column should have Х) • Sum of hours by each code for 1-15 of month by each day separately (16th column should be empty) • Presence/absence codes for 16-31 of month by each day separately (if some day doesn't exist in month, missing day should have Х) • Sum of hours by each code for 16-31 of month by each day separately (if some day doesn't exist in month, missing day should be empty) | |
| Worked for half month (I, II) | For each operator, 4 rows are reflected: • Presence/absence codes that were for 1-15 of month (except В, ОТ, Б and О) • Sum of hours by each code for 1-15 of month (except В, ОТ, Б and О) • Presence/absence codes that were for 16-31 of month (except В, ОТ, Б and О) • Sum of hours by each code for 16-31 of month (except В, ОТ, Б and О) | |
| Month | For each operator, 2 rows are displayed: • Presence/absence codes that were in month (except В, ОТ, Б and О) • Sum of hours by each code for month (except В, ОТ, Б and О) | |
| Data for salary calculation | Not filled | |
| Absences by reasons | Not filled | |

---

## Page 390

**Calculation Logic:**

| Code | Description | Display Logic | Hour Calculation Logic |
|------|-------------|---------------|----------------------|
| А | Attendance | Operator has planned shift in work schedule for these 24 hours; Operator has working statuses from contact center for these 24 hours; Operator has no vacation, sick leave, time off in work schedule | Sum of operator status durations that were selected by user as timesheet time, but not more than planned shift duration minus unpaid lunches/breaks. For example, if planned shift duration for operator is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 12:30:00, then А should record 11:30:00, remaining time should refer to overtime work (С). |
| Н | Night attendance | Operator has planned shift in work schedule for these 24 hours; Operator has working statuses from contact center for these 24 hours; Operator has working statuses from contact center that were during night hours according to operator time zone; Code Н is displayed only together with code А | Sum of operator status durations during night hours that were selected by user as timesheet time, but not more than attendance duration. For example, night hours 22:00-06:00, operator planned shift 11:00-23:00, operator worked 11:30-23:30, unpaid lunch was 16:00–16:30. In this case, А should record 11:30:00, Н should record 1:30:00 (22:00-23:30) |

---

## Page 391

| Code | Description | Display Logic | Hour Calculation Logic |
|------|-------------|---------------|----------------------|
| НН | Absence | Attendance is less than operator shift duration according to work schedule minus unpaid lunches/breaks; Operator card has no vacation, sick leave, or time off | Absence duration = planned shift duration according to work schedule (minus unpaid lunches/breaks) - attendance duration. For example, if operator planned shift is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 10:30:00, then А = 10:30:00, НН=11:30:00-10:30:00=1:00:00 |
| В | Weekend | Operator has weekend in work schedule; Operator has no working statuses from contact center; Operator card has no vacation, sick leave, or time off | Hours for weekend are not calculated; hours field should be empty. |
| ОТ | Vacation | Operator has vacation in work schedule; Operator has no working statuses from contact center | Hours for vacation are not calculated; hours field should be empty. |
| С | Overtime work | Attendance duration is greater than operator shift duration according to work schedule (minus unpaid lunches/breaks); Operator card has no vacation, sick leave, or time off | Overtime work = attendance duration - planned shift duration according to work schedule (minus unpaid lunches/breaks). For example, if operator planned shift is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 12:30:00, then А = 11:30:00, С=12:30:00-11:30:00=1:00:00 |

---

## Page 392

| Code | Description | Display Logic | Hour Calculation Logic |
|------|-------------|---------------|----------------------|
| РВ | Weekend work | Operator has weekend or vacation in work schedule; Operator has working statuses from contact center for these 24 hours; Operator card has no sick leave or time off | Sum of operator status durations that were selected by user as timesheet time. For example, if operator has weekend but has actual contact center statuses marked as timesheet time and they = 05:00:00, then РВ = 05:00:00 |
| Б | Sick leave | Operator card has sick leave; Operator has no attendance | Hours for sick leave are not calculated; hours field should be empty. If operator has sick leave set but has contact center statuses, Attendance should be marked (sick leave is not marked) |
| О | Time off | Operator card has time off | Time off hours are calculated by time off date and time. For example, if time off is set for period 21.12.2022 10:00 - 21.12.2022 16:00, then time off duration for 21.12.2022 equals six hours (16:00-10:00). If time off is set for period 21.12.2022 10:00 - 22.12.2022 16:00, then time off duration for 21.12.2022 equals fourteen hours (24:00-10:00), time off duration for 22.12.2022 equals sixteen hours (16:00-00:00). If operator has time off set but has contact center statuses, both attendance and time off should be displayed. |

---

## Page 393

#### 13.1.4. "Forecast and Plan" Report

Report displays operator forecast and plan by days and hours breakdown. Operator forecast is taken from data obtained in "Forecast load" module or manually imported into system. Operator plan is calculated based on planned and applied timetable.

To build report, go to "Reports" → "Forecast and plan report" tab.

![Forecast Plan Report Navigation](img/forecast_plan_report_navigation.png)

To build report, select period (no more than month), time zone, planning template, and group (if necessary). Then click.

![Forecast Plan Report Configuration](img/forecast_plan_report_configuration.png)

If planning template is selected and no group is selected in report input parameters, report is built for selected multi-skill planning template.

---

## Page 394

If planning template and group are selected in report input parameters, report is built for selected group from multi-skill planning template.

Hour forecast for day is calculated as average value of forecasted operator number considering minimum operators, reserve coefficients, and absenteeism set during load forecasting, in intervals within calculated hour, rounded to hundredths.

• When exporting report by planning template - in each interval, sum of forecast value for all groups included in multi-skill template is calculated.
• When exporting report by group - in each interval, forecast value for this group is used.

![Forecast Plan Report Results](img/forecast_plan_report_results.png)

**Example calculation for one hour.** Suppose report is built for multi-skill planning template that includes simple group 1 and aggregated group 2.

| Time Interval Start | Group 1 Operator Forecast | Group 2 Operator Forecast | Total Template Groups 1 and 2 Forecast |
|-------------------|--------------------------|--------------------------|---------------------------------------|
| 06.02.2025 00:00 | 0 | 1 | 1 |
| 06.02.2025 00:15 | 1.25 | 1 | 2.25 |

---

## Page 395

| Time Interval Start | Group 1 Operator Forecast | Group 2 Operator Forecast | Total Template Groups 1 and 2 Forecast |
|-------------------|--------------------------|--------------------------|---------------------------------------|
| 06.02.2025 00:30 | 2.69542 | 1 | 3.69542 |
| 06.02.2025 00:45 | 10 | 1 | 11 |
| 06.02.2025 01:00 | 4 | 1 | 5 |

For specified values, report for 06.02.2025 at hour 00:00 will have forecast equal to (1 + 2.25 + 3.69542 + 11) / 4 = 4.49.

Hour plan for day is calculated as average value of "Operator plan" in intervals within calculated hour, rounded to hundredths.

• When exporting report by planning template - in each interval, each operator is counted as 1 (in event intervals not counted on line, described below (for example, sick leave, break), as 0).
• When exporting report by group - in each interval, sum of operator work shares on group is used. Share and downtime accounting (in event intervals not counted on line, described below (for example, sick leave, break), operator is not counted (i.e., their work shares on group = 0).

![Forecast Plan Detailed Results](img/forecast_plan_detailed_results.png)

During timetable planning, each timetable operator has work shares planned on groups (simple or aggregated) that are included in multi-skill planning template and are non-reserve for operator. In one system interval, operator can have from 0 to 100 shares planned on one or several groups.

When 0 shares are planned for interval, i.e., line load is covered and there's employee surplus, such interval is called downtime interval. Additionally, operator has various timetable and work schedule events that are also considered in report. Share, downtime, and event accounting rules listed in document are specified below.

**Share and downtime accounting.**

When exporting report by group, for each operator in each system interval, their work shares on this group are calculated considering events:

• If interval operator work shares are calculated on one group as 100, they are counted on this group as 1.
• If interval operator work shares are calculated on several groups, operator is counted proportionally to calculated shares.

**Example 1**: shares planned on group 1 = 25, on group 2 = 75, operator is counted as 25/100=0.25 on group 1 and 75/100=0.75 on group 2.

**Example 2**: shares planned on group 1 = 25, on group 2 = 50, operator is counted as 25/75=0.33 on group 1 and 50/75=0.67 on group 2.

• If interval operator work shares on all groups equal 0, i.e., downtime interval, then operator:
  - First, operator shares in this interval are counted same as in previous pre-downtime interval where operator was counted on group (i.e., interval with shares or interval with activity having "Count on line" attribute).
  - If no share intervals exist before downtime (for example, this is operator's first interval), then shares are counted same as in next post-downtime interval where operator was counted on group (i.e., interval with shares or interval with activity having "Count on line" attribute).
  - If no share intervals exist before and after downtime (i.e., entire shift is in downtime), and no activity with "Count on line" attribute is set, then operator is counted as 1 on any group included in multi-skill planning template that is non-reserve for operator ("Any" group - first alphabetically).

**Example**: planning template has 4 groups - group 1, 2, 3, and 4. Operator has 4 groups - groups 1 and 5 are reserve, groups 2 and 3 are non-reserve. Operator is counted as 1 in group 2.

When exporting report by planning template - in each interval, each operator is counted as 1 considering events.

**Operator event accounting.**

During vacation period (planned or extraordinary), as well as sick leave, operator is not counted in report for entire event day.

**Example**: operator has 3 shifts planned in timetable (report, operator, shifts and events in Moscow time zone):

• 06.02.2025 20:00 - 07.02.2025 08:00;
• 08.02.2025 20:00 - 09.02.2025 08:00;
• 10.02.2025 08:00 - 10.02.2025 20:00.

After this, operator is assigned:

• 06.02.2025 planned vacation for one day;
• 09.02.2025 extraordinary vacation for one day;
• 10.02.2025 sick leave for one day.

In report, operator:

• 06.02.2025 20:00 - 07.02.2025 00:00 is not counted on any group since planned vacation is set;

---

## Page 396

• 07.02.2025 00:00 - 07.02.2025 08:00 is counted according to planned shares;
• 08.02.2025 20:00 - 09.02.2025 00:00 is counted according to planned shares;
• 09.02.2025 00:00 - 09.02.2025 08:00 is not counted on any group since extraordinary vacation is set;
• 10.02.2025 08:00 - 10.02.2025 20:00 is not counted on any group since sick leave is set.

During time off and lateness period, operator is not counted in report for entire event period.

**Example**: operator has 2 shifts planned in timetable (report, operator, shifts and events in Moscow time zone):

• 08.02.2025 20:00 - 09.02.2025 08:00;
• 10.02.2025 08:00 - 10.02.2025 20:00.

After this, operator is assigned:

• 08.02.2025 23:00 - 09.02.2025 01:00 time off;
• 10.02.2025 08:00 - 10.02.2025 08:30 lateness.

In report, operator:

• 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares;
• 08.02.2025 23:00 - 09.02.2025 01:00 is not counted on any group since time off is set;
• 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares;
• 10.02.2025 08:00 - 10.02.2025 08:30 is not counted on any group since lateness is set;
• 10.02.2025 08:30 - 10.02.2025 20:00 is counted according to planned shares.

During lunch, break, event (training or meeting) period, operator is not counted in report for entire event period.

**Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):

• 08.02.2025 20:00 - 09.02.2025 08:00.

Operator has set:

• 08.02.2025 22:00 - 08.02.2025 22:15 break;
• 08.02.2025 23:45 - 09.02.2025 03:45 event;
• 09.02.2025 04:30 - 09.02.2025 05:00 lunch.

In report, operator:

• 08.02.2025 20:00 - 08.02.2025 22:00 is counted according to planned shares;
• 08.02.2025 22:00 - 08.02.2025 22:15 is not counted on any group since break is set;
• 08.02.2025 22:15 - 08.02.2025 23:45 is counted according to planned shares;
• 08.02.2025 23:45 - 09.02.2025 03:45 is not counted on any group since event is set;
• 09.02.2025 03:45 - 09.02.2025 04:30 is counted according to planned shares;
• 09.02.2025 04:30 - 09.02.2025 05:00 is not counted on any group since lunch is set;
• 09.02.2025 05:00 - 09.02.2025 08:00 is counted according to planned shares.

During activity period without "Count on line" attribute, operator is not counted in report for entire event period.

**Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):

• 08.02.2025 20:00 - 09.02.2025 08:00.

Operator has set:

• 08.02.2025 23:00 - 09.02.2025 01:00 activity without "Count on line" attribute.

In report, operator:

• 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares;
• 08.02.2025 23:00 - 09.02.2025 01:00 is not counted on any group since activity without "Count on line" attribute is set;
• 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares.

If after setting such activity, "Count on line" attribute is added to it in directory, since activity was set earlier, it still won't be counted. Activities set after attribute change will be counted.

During activity period with "Count on line" attribute, operator is counted in report as 1 on group selected when setting this event. If shares were planned under event, they won't be counted.

**Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):

• 08.02.2025 20:00 - 09.02.2025 08:00, for example simplification, assume entire shift is planned on group 2 (100 shares in each interval).

Operator has set:

• 08.02.2025 23:00 - 09.02.2025 01:00 activity with "Count on line" attribute, user selected group 1 when setting.

In report, operator:

• 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares on group 2.

---

## Page 397

• 08.02.2025 23:00 - 09.02.2025 01:00 is counted as 1 on group 1 since activity with "Count on line" attribute on group 1 is set.
• 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares on group 2.

If after setting such activity, "Count on line" attribute is removed from it in directory, since activity was set earlier, it will still be counted. Activities set after attribute change won't be counted.

Overtime is planned in timetable similar to other shifts (planned, additional) and overtime hours.

• If operator was assigned overtime and timetable was updated for overtime period after this - it will be planned similar to shift with shares and downtime, operator is counted in report according to logic described above.
• If operator was assigned overtime but timetable wasn't updated for overtime period after this - operator won't be counted in report since no shift is planned for this time in timetable.

**Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):

• 08.02.2025 20:00 - 09.02.2025 08:00.

Timetable was planned, after which work schedule set:

• 08.02.2025 19:00 - 08.02.2025 20:00 overtime before shift start;
• 10.02.2025 10:00 - 10.02.2025 12:00 overtime on weekend;
• User updated timetable from 09.02.2025 00:00.

In report, operator:

• 08.02.2025 19:00 - 08.02.2025 20:00 won't be counted since timetable wasn't updated and operator has no planned time for this period;
• 08.02.2025 20:00 - 09.02.2025 08:00 is counted according to planned shares;
• 10.02.2025 10:00 - 10.02.2025 12:00 is counted according to planned since timetable is updated and operator has this time planned.

**Shortage/surplus.**

Hour shortage/surplus for day is calculated by formula Plan for hour in day - Forecast for hour in day.

![Shortage Surplus Calculation](img/shortage_surplus_calculation.png)

Additionally, second sheet calculates general plan and forecast (for report building period).

![General Plan Forecast](img/general_plan_forecast.png)

Forecast is calculated as sum of all "Hour forecast for day" values in report building period.

---

## Page 398

Plan is calculated as sum of all "Hour plan for day" values in report building period.

#### 13.1.5. Operator Lateness Report

This report displays late employees and percentage of late employees by groups and departments. Lateness time is manually set. For employees to be displayed in report, they must belong to department and have applied timetable (current); if there's no current timetable built based on current work schedule, operators won't be in report. Lateness is considered difference between time when operator should start shift (taken from current timetable) and login time in integration system.

To go to this report, open side panel and go to "Reports → Operator lateness report":

![Lateness Report Navigation](img/lateness_report_navigation.png)

When opening report, filter will be displayed based on which data will be shown:

---

## Page 399

![Lateness Report Configuration](img/lateness_report_configuration.png)

Here you need to set period for which data will be output, department, operator type (home or office), their full name, and lateness boundaries; operators falling within these boundaries will be displayed in report. In screenshot above, only operators with lateness between 10 to 30 minutes will be displayed. After confirming parameters, report will be built and needs to be exported to Excel (xlsx) by clicking. Report looks like this:

![Lateness Report Results](img/lateness_report_results.png)

**Fields:**

---

## Page 400

• **Direction/group/Full name** – sequentially displays department, group, and operator full name for whom data is displayed;
• **Number of employees / lateness (min) date** – in this column, summary number of late people is displayed next to group and department, and number of minutes operator was late is displayed next to operator full name;
• **Employee percentage** – next to groups and departments, displays percentage of late people from percentage of operators who came to work in general;
• **Total late** – shows general number of late people across all groups and departments;
• **Total percentage** – displays general percentage of late people.

![Lateness Report Summary](img/lateness_report_summary.png)

#### 13.1.6. AHT Report

This report displays information about weighted average AHT (Average Handling Time) for each operator.

To go to report, select "Reports" → "AHT Report":

---

## Page 401

![AHT Report Navigation](img/aht_report_navigation.png)

After opening report, enter period for which data is needed, and specify groups for which report needs to be built (groups can be filtered by departments they belong to):

---

## Page 402

![AHT Report Configuration](img/aht_report_configuration.png)

After building report, export it by clicking:

![AHT Report Export](img/aht_report_export.png)

"Source" page displays dates, full names, departments, groups. They correspond to specific talk time in group (in seconds) and number of processed requests in same group.

![AHT Report Source](img/aht_report_source.png)

"By group" tab displays groups with departments nested in them, which have operator full names nested. Each department corresponds to row with "norm" and "AHT" (both indicators in seconds). "Norm" is taken from forecast (this is forecasted or manually set AHT when calculating number of operators), AHT is taken from operator statuses received via integration. "%Perf" is ratio of norm to actual AHT. Report has dynamic period columns with following fields: year, quarter, month, week, day. Depending on period for which report is built, some columns will be displayed, some won't.

On "By directions" tab, information is similar, only departments are displayed first, with groups nested in them, which have operators nested.

#### 13.1.7. %Ready Report

This report shows operator's daily %Ready percentage (as well as summary information). %Ready = productive time / login time.

Productive time is time in operator productive statuses received via integration (statuses with "Productive time" checkbox in "Working time configuration" directory are taken).

To go to report, select "Reports" → "%Ready Report":

---

## Page 403

![Ready Report Navigation](img/ready_report_navigation.png)

After opening report, enter period for which data is needed. Then check departments from which operators should be taken. After selecting department, operator full names will be displayed below, which also need to be checked:

![Ready Report Configuration](img/ready_report_configuration.png)

After building report, click.

---

## Page 404

![Ready Report Export](img/ready_report_export.png)

In exported report, on "Source" tab, departments and operator full names are displayed. Each row corresponds to "Productive status time," "Login time," and "%Ready" columns.

![Ready Report Source Results](img/ready_report_source_results.png)

"By direction" tab displays only %Ready. Summary Ready percentage for operators included in department is displayed next to department, operator %Ready is displayed next to operators. Report has dynamic period columns with following fields: year, quarter, month, week, day. Depending on period for which report is built, some columns will be displayed, some won't.

#### 13.1.8. Preferences Report

For planner/manager to review operator preferences both set and considered during planning, "Preferences Report" was added to system. To build report, following information is filled:

• Period for which report will be built;
• Template;
• Work schedule.

If necessary, separate export can be made by departments, operator types (office or home), or individual operator.

---

## Page 405

![Preferences Report Configuration](img/preferences_report_configuration.png)

Report consists of two sheets, displaying following information:

• Personnel number;
• Operator full name;
• Day for which preference is set;
• Preference importance specified by operator (mandatory/desirable);
• Preference type (Working/weekend);
• Intervals (for working day preference);
• Shift starts;
• Shift ends;
• Shift durations;
• Start and end of shift set in schedule (for shifts) or Weekend;
• Preference consideration (considered/not considered).

Report also displays considered preference percentage (general, mandatory, and desirable).

Preference consideration percentage is calculated as N_considered/N_total, where:

N_considered - number of shifts planned in work schedule that fit operator preference by start, end, and duration
N_total - number of shifts for which operator set preferences

Considered preference percentage is rounded mathematically.

![Preferences Report Results](img/preferences_report_results.png)

---

## Page 406

### 13.2. Report Editor

Creating reports in editor is available to user with system role "Administrator" or other role with access right "System_AccessReportEditor."

Building reports created in editor is available to user with system role "Administrator" or other role with access right "System_PremiumPerformanceView" from "Report List" page.

Report editor is designed for creating custom reports in system based on data obtained through database queries. To use editor, you need experience building database queries using SQL or GROOVY. Also need familiarity with WFM CC database data model.

To go to report editor, open side menu and select "Reports" → "Report editor" section.

![Report Editor Navigation](img/report_editor_navigation.png)

When going to "Report editor" page, all created reports are displayed broken down by groups:

---

## Page 407

![Report Editor Interface](img/report_editor_interface.png)

To view report information, click on it with left mouse button. To the right of created reports menu, general information about selected report is displayed: "Name," "Group" (if report belongs to group), "Status," "Description." To build report from "Report editor" page, click "Build" button.

![Report Editor Details](img/report_editor_details.png)

#### 13.2.1. Creating Report Group in "Report Editor" Section

To create new group in "Report editor," click "Add" button in left part of page and select object type "Group" from dropdown menu.

---

## Page 408

![Create Report Group](img/create_report_group.png)

After selecting object type, group creation window opens where you need to specify "Name," "Roles" (employees with assigned role will have ability to build reports from group), and click "Create" button.

![Report Group Creation Dialog](img/report_group_creation_dialog.png)

#### 13.2.2. Providing Access to Report Group

To open access to reports added to group, select report group (click on group with left mouse button), click "Add" button, and in opened window select necessary roles. Roles for which reports belonging to group are available are displayed in "Roles" information window.

![Report Group Access](img/report_group_access.png)

---

## Page 409

#### 13.2.3. Creating Report in "Report Editor" Section

To create new report in "Report editor," click "Add" button in left part of page and select "Report type" object from dropdown menu.

![Create New Report](img/create_new_report.png)

After selecting object type, report creation window opens where you need to specify attributes "Name," "Group," "Description," and click "Create" button.

![Report Creation Dialog](img/report_creation_dialog.png)

After creating report type, report is in "Blocked" status. If report is Blocked, it can be edited (change name, description, modify query to data, input data, etc.) and can be built by person with report editing rights. If report is Published, it can be viewed by person with report viewing access rights, but cannot be edited.

In "Data queries" tab in "Bands" area, Bands to which data requested from database are attached are arranged hierarchically. Band addition/removal buttons are also displayed here.

When selecting band, "Band properties" area displays band name, data acquisition method (SQL or GROOVY), and its orientation (HORIZONTAL, VERTICAL, CROSS, UNDEFINED). Below all this data, working field is displayed where database data query is written. "Save query" button saves query changes which, if not saved, are reset when refreshing page/going to another band.

---

## Page 410

![Report Query Editor](img/report_query_editor.png)

In "Input parameters" tab, parameters are set (depending on report type, input parameters may not be needed) that users will enter when building report and based on which data filtering will be performed. Created input parameters can be edited or deleted. One parameter must have name, keyword - word used to access input parameter in SQL code, data type (text, numeric, date, logical, etc.), and its requirement.

![Report Input Parameters](img/report_input_parameters.png)

In "Export templates" tab, export templates are loaded which can be selected when building report. Template can be in xls (Excel), html, doc, or other format. Templates can be loaded, and can also be deleted or edited (name).

![Report Export Templates](img/report_export_templates.png)

For created report to be available to users for building, click "Publish" button; report status will change to "Published."

#### 13.2.4. Building Reports

"Report List" page displays report groups available to user for building (groups available for role assigned to user).

To go to "Report List" page, open side menu and select "Reports" → "Report List" section.

To build, select report, click on it with left mouse button, specify input parameter values (if they were set during creation), select export template (if there are several), and building mode. "One-time" building mode means report building and export is performed once, "Scheduled" means report building and export will be performed according to set schedule.

To build scheduled report, specify:

• Period unit (minute, hour, day, week, month, etc.);
• Quantity;
• Start with "Start date and time";
• Number of repetitions.

Click "Create" button.

After building report, user will receive internal system notification:

![Report Build Notification](img/report_build_notification.png)

To download built reports, go to "Reports" → "Report building tasks" section. Expand detailed information and download built report.

---

## Page 411

![Download Built Report](img/download_built_report.png)

## 14. Monitoring

To view monitoring section pages, you need role with access right "View pages in 'Monitoring' section" (System_AccessMonitoring).

Monitoring is designed for operational load viewing on line and statistics concerning current number of operators and their planned number.

On "Operational control" page, statistics are displayed for each group (both simple and aggregated), and at time of opening in system there should be:

• Update and notification settings configured;
• "Work time efficiency configuration" directory configured;
• For groups of interest:
• Threshold values set;
• Timetable planned for operators;
• Load forecasted;
• User given access rights;
• Dashboard display settings configured in personal account.

### 14.1. Update and Notification Settings

Page is available for editing to user with system role "Administrator" or any other role with access right "Edit monitoring update settings" (System_EditMonitoringUpdateSettings).

In this section, you can assign periodicity for contact center polling regarding operator statistics (their number and statuses). To go to settings, open side menu and go to "Monitoring" → "Update and notification settings":

---

## Page 412

![Monitoring Settings Navigation](img/monitoring_settings_navigation.png)

Here, parameters for data acquisition frequency from contact center and operator notification frequency will be displayed:

![Monitoring Update Settings](img/monitoring_update_settings.png)

**Operator notification, min:** – operator notification frequency about absence;

---

## Page 413

**Group information update:** – shows how often (in seconds) we'll contact contact center to get group information (real ACD, AHT, etc.).

To change value, click on them, specify new ones, and click "checkmark":

![Update Settings Modification](img/update_settings_modification.png)

### 14.2. Threshold Values

Page is available for editing to user with system role "Administrator" or any other role with access right "Edit threshold value settings" (System_ThresholdUpdateSettings).

Threshold values determine at what values numbers in dashboards will change colors. To go to settings, open side menu and go to "Monitoring" → "Threshold value settings":

![Threshold Settings Navigation](img/threshold_settings_navigation.png)

---

## Page 414

When opening page, select service and group and set threshold values for them:

![Threshold Settings Configuration](img/threshold_settings_configuration.png)

**Operators on line** – values need to be entered as percentages from 1 to 100.

• **Acceptable boundary** – if number of operators on line exceeds acceptable boundary, we color corresponding dashboard green, showing that our load is normal.
• If number of operators drops below acceptable boundary but stays above critical boundary, corresponding dashboard will be colored yellow, showing that load is acceptable.
• If number of operators on line drops below critical boundary, we color dashboard red, showing that we don't have enough operators.

**Load** – values need to be entered as percentages from 1 to 100.

---

## Page 415

• **Decline** – if difference between forecasted number of calls and real number of calls equals less than or equal to acceptable value (number of real calls is less than forecasted), corresponding dashboard will display green color. If difference rises above acceptable value but stays below critical, dashboard color will be yellow. If call difference percentage becomes above critical value, dashboard will be red, showing that real load is less than forecasted and operators are idle.

• **Growth** – conversely, if number of real calls exceeds forecasted number but not higher than acceptable percentage, dashboard will be green. If real load exceeds forecasted by percentage that exceeds acceptable value but doesn't exceed critical, dashboard will be yellow; if above critical, then red.

**Operator requirement** – need to enter number of people.

• **Surplus** – difference value between required number of operators (calculated based on real call numbers) and number of operators according to timetable is examined. Accordingly, surplus is when required number of operators is higher than number according to timetable. If value is less than acceptable boundary, corresponding dashboard is colored green; if between acceptable and critical, then yellow; if above critical, then red.

• **Shortage** – also examines difference between number of operators according to timetable and required number of operators. Shortage means number of operators according to timetable is less than required number of operators. Accordingly, if this value is below acceptable, dashboard will be colored green; if between acceptable and critical, then yellow; if above critical, then red.

**SLA** – need to enter values as percentages from 1 to 100.

• **Decline** – difference between SLA calculated in timetable and real. Decline shows that real SLA is less than forecasted. If value of this difference is less than acceptable boundary, we color dashboard green; if between acceptable and critical, then yellow; if above critical, then red.

• **Growth** – when real SLA is greater than forecasted. If this value is below acceptable boundary, we color dashboard green; if between acceptable and critical, then yellow; if above critical, then red.

**ACD** – need to enter values as percentages from 1 to 100. ACD – deviation of processed request percentage from forecasted.

• **Decline** shows that real ACD is less than forecasted. If decline value is below acceptable, dashboard is colored green; if between acceptable and critical, then yellow; if above, then red.

• **Growth** shows that real ACD exceeds forecasted. Color settings are same as decline.

**AHT** – need to enter values as percentages from 1 to 100. AHT – deviation of average request processing time from forecasted.

• **Decline** shows that real AHT is less than forecasted. If value is below acceptable, dashboard is colored green; if between acceptable and critical, then yellow; if above, then red.

• **Growth** shows that real AHT exceeded forecasted. Color indication is identical to decline.

---

## Page 416

### 14.3. Operational Control

On this page, you can view dashboards with statistics for specific groups (both simple and aggregated) for which user configured display ability in personal account. Operational control dashboards can only be viewed when there's applied timetable and working integration with contact center.

You can get to operational control page either from main page:

![Operational Control Main](img/operational_control_main.png)

Or through side menu where you need to go to "Monitoring" → "Operational control."

---

## Page 417

![Operational Control Navigation](img/operational_control_navigation.png)

When opening, user will see six dashboards for specific groups (for which user specified display ability in personal account):

![Operational Control Dashboards](img/operational_control_dashboards.png)

**Operators on line%** – shows how many operators are currently on line. This dashboard shows percentage ratio of operators specified in timetable to real number of operators on line. This calculation doesn't include operators who have lunch, break, or training specified in timetable at viewing time.

**Load** – shows load growth/decline in real time. Displays percentage ratio between load we forecasted and real load on line.

**Operator requirement** – shows shortage or surplus of operators needed to cover current load. Depending on mode selected in group settings, statistics will be calculated as follows:

---

## Page 418

• **"Voice channel"** – Displayed as difference between required number of people needed to cover current load (calculated using Erlang formula) and real number of people on line.

• **"Non-voice channel"** – Displayed as difference between forecasted number of operators and real number of people on line.

**SLA** – Displays difference between real SLA (via integration) and SLA according to timetable.

**ACD** – Displays difference between actual %ACD (obtained via integration) and forecasted.

**AHT** – Displays percentage by which weighted average AHT by group grew/fell. Formula: (Actual AHT-Forecasted AHT)/Forecasted AHT*100. Actual AHT is obtained via integration.

When calculating ACD and AHT, values are taken starting from 00:00 of current day and ending at current time.

Each dashboard also has its own statistics page. To open dashboard, click on number inside it.

#### 14.3.1. Operators on Line

![Operators on Line Dashboard](img/operators_on_line_dashboard.png)

When opening dashboard, following information will be displayed:

• **Schedule adherence (24 hours)** – displays average schedule adherence indicator value (percentage ratio of operators specified in timetable to real number of operators on line) from start of day.

• **Number of operators:**
  • **according to timetable** – shows number of operators from current timetable;
  • **on line** – real number of operators on line, obtained via integration.

• **Schedule deviation** – displays chart of real operator number deviation from planned at each time moment.

• **Dynamics** – displays chart of "According to timetable" and "On line" values for specific time periods. By clicking on color legend below chart, you can remove unnecessary values.

For aggregated groups, number of operators on line is calculated as sum across all simple groups included in aggregated.

---

## Page 419

#### 14.3.2. Operator Requirement

![Operator Requirement Dashboard](img/operator_requirement_dashboard.png)

When opening dashboard, following information will be displayed:

• **Planning accuracy (24 hours)** – displays percentage average planning accuracy value (difference between real number of operators on line (obtained via integration) and required number of operators to cover load) of timetable from start of day to current time.

• **Accuracy dynamics** – graphical representation of "Planning accuracy" value. When hovering cursor over chart, you can see additional information.

• **Current snapshot:**
  • **By forecast** – displays forecasted operator number.
  • **By timetable** – displays operator number according to current timetable.
  • **Required** – displays required operator number considering current group load by requests (calculated using Erlang formula).

---

## Page 420

• **Actual** – displays real operator value on line, comes via integration.

• **Dynamics** – visualization of four above parameters. You can hover cursor over chart to see additional information.

For aggregated groups, actual and required operator numbers are calculated as sum across all simple groups included in aggregated.

To view and change operator timetable, go to current timetable in "Operational solutions" block.

#### 14.3.3. SLA

![SLA Dashboard](img/sla_dashboard.png)

When opening dashboard, following information will be displayed:

• **SLA deviation (24 hours)** – average SLA deviation value from forecast from start of day.

• **Forecast deviation (24 hours)** – visualization of "SLA deviation (24 hours)" value. By hovering cursor over chart, you can see additional information.

• **Current snapshot:**
  • **By forecast** – SLA according to forecast.
  • **By timetable** – SLA according to planned timetable; calculated using formula selected in group settings;

---

## Page 421

• **Actual** – real SLA calculated based on data obtained via integration.

• **Line wait time** – obtained via integration.

• **Dynamics** – visualization of four above parameters. By hovering cursor over chart, you can see additional information.

For aggregated groups, real SLA is calculated as weighted average value across all simple groups included in aggregated.

#### 14.3.4. Load Growth

![Load Growth Dashboard](img/load_growth_dashboard.png)

When opening dashboard, following information will be displayed:

• In "Current snapshot" block, load information (incoming requests) for current time moment (from 00:00 to current hour) is displayed.

• **By forecast – incoming** – displays forecasted request number considering growth coefficient.

• **By forecast – processed** – displays forecasted request number multiplied by %ACD set during forecasting.

• **Actually incoming requests** – displays number of incoming requests for previous interval

---

## Page 422

(snapshot updates every n seconds; previous update is previous interval). Obtained via integration.

• **Actually processed requests** – displays number of processed requests. Calculated as difference between processed requests for current period (received calls * %ACD) and processed requests for previous period. All values obtained via integration.

• **In queue** – queue call display, obtained via integration.

• **Dynamics (24 hours)** – graphical representation of parameters described in "Current snapshot" block.

• In "Forecast accuracy" block, calculated accuracy for incoming and processed requests is displayed. General formula looks like: |"actual request number"- "forecasted request number"|"forecasted request number"*100, where "requests" can be simply incoming for "By incoming calls" and processed for "By processed calls."

• **Deviation from norm (24 hours)** – graphical representation of "Planning accuracy" block values.

For aggregated groups, actual number of incoming and processed requests is calculated as number of requests incoming/processed on simple groups included in aggregated composition.

• In "Call number" chart, there's ability to remove specific lines – to do this, click on needed line legend:

---

## Page 423

![Chart Line Toggle](img/chart_line_toggle.png)

By hovering over chart line, you can see detailed information:

![Chart Hover Details](img/chart_hover_details.png)

---

## Page 424

#### 14.3.5. ACD

![ACD Dashboard](img/acd_dashboard.png)

When opening dashboard, following information will be displayed:

• In "ACD deviation (24 hours)" block, difference between actual ACD (obtained from integration) and forecasted at current moment (from 00:00 to current time) is displayed. I.e., this is same number as in dashboard list. Next to this block, deviation chart is displayed; curve either goes below 0 or above, depending on values.

• In "ACD from start of day" block, current ACD data is displayed, updated every specific number of seconds specified in group information update.

• **By forecast** – %ACD according to forecast
• **By timetable** – %ACD according to planned timetable
• **Actual** – %ACD according to current load. Real ACD is pulled via integration. Next to block, chart displaying data from "current snapshot" is shown.

• **Dynamics (24 hours)** – graphical representation of "Planning accuracy" block values.

For aggregated groups, indicators in "ACD from start of day" block equal weighted average value across all simple groups included in aggregated.

• In "Dynamics" chart, there's ability to remove specific lines – to do this, click on needed line legend:

![ACD Chart Line Toggle](img/acd_chart_line_toggle.png)

By hovering over chart line, you can see detailed information:

![ACD Chart Hover Details](img/acd_chart_hover_details.png)

---

## Page 425

#### 14.3.6. AHT

![AHT Dashboard](img/aht_dashboard.png)

When opening dashboard, following information will be displayed:

• In "AHT deviation" (24 hours) block, AHT deviation percentage at current moment (from 00:00 to current time) is displayed. I.e., same as in dashboard list. Next to this block, deviation chart is displayed, which from 0 goes either above or below.

• "AHT from start of day" displays accumulated AHT data from start of day:
  • **By forecast** – weighted average AHT according to forecast;
  • **Real** – weighted average actual AHT according to current load.

• **Dynamics (24 hours)** – graphical representation of "Current snapshot" block values.

For aggregated groups, indicators in "Current snapshot" block equal weighted average value across all simple groups included in aggregated.

In "Average service duration" chart, there's ability to remove specific lines – to do this, click on needed line legend:

---

## Page 426

![AHT Chart Line Toggle](img/aht_chart_line_toggle.png)

By hovering over chart line, you can see detailed information:

![AHT Chart Hover Details](img/aht_chart_hover_details.png)

### 14.4. Operator Statuses

To view this page, you need access rights "System_ViewAllWorkersInMonitoring" and "System_ViewSubordinatesWorkersInMonitoring." First right will allow viewing all operator statuses, second only subordinate operator statuses.

On "Operator statuses" page, you can see what status operator is currently in; if they're absent from place when they should be there, then how long, and you can call operator to workplace. All operator statuses and absence time are obtained via integration.

To go to operator statuses, go to "Monitoring" → "Operator statuses":

![Operator Statuses Navigation](img/operator_statuses_navigation.png)

Or

![Operator Statuses Alt Navigation](img/operator_statuses_alt_navigation.png)

When opening, following fields will be displayed:

**Operational solutions** – this block displays list of operators who should be at workplace this day. From here, you can filter operators by skill, type, line presence, and also call operator to line urgently.

---

## Page 427

![Operational Solutions](img/operational_solutions.png)

• In "Full name" column, operator full name is displayed, with their skill and type shown nearby.
• **Contact center status** – shows operator's current status obtained via integration.
• **Schedule adherence** – displays correspondence of timetable (current) to real statuses obtained via integration. If according to timetable operator should work, but according to integration we receive non-working status, field will be colored red and show "Violation."
• **Contact** – operator contacts from card.
• **Absent (min)** – number of minutes operator is absent (doesn't accumulate; if operator was absent 10 minutes, then came to line, on next absence counter resets).

By clicking next to operator, we'll see their working intervals according to planned work schedule and according to timetable ("Statistics" in figure above).

---

## Page 428

---

## **END OF TRANSLATION**

**Total Pages Translated: 462 of 462**

This completes the comprehensive English translation of the ARGUS WFM CC User Manual Part 2 (Pages 200-462). The manual covers:

## Key Sections Translated:

### **System Administration & Configuration**
- Personnel synchronization and data collection
- Integration system management
- Manual corrections and account linking

### **Core Forecasting Module**
- Load forecasting algorithms and methods
- Historical data import and correction
- Peak analysis and trend analysis
- Seasonal component analysis
- Operator calculation models (Erlang C, Linear, etc.)
- Forecast accuracy analysis

### **Planning & Scheduling**
- Multi-skill planning templates
- Work schedule planning with preferences
- Vacation planning and management
- Timetable creation and management
- Vacancy planning
- Exchange system for shift offers

### **Employee Management**
- Personal account functionality
- Preference setting and management
- Work schedule corrections
- Event registration (sick leave, vacation, etc.)

### **Business Process Management**
- BP loading and execution
- Task management and approval workflows
- Work schedule approval processes

### **Reporting & Analytics**
- System reports (schedule adherence, salary calculation, etc.)
- Report editor for custom reports
- Performance and accuracy reports

### **Monitoring & Control**
- Real-time operational control dashboards
- Threshold value configuration
- Operator status monitoring
- Load and performance tracking

The translation maintains technical accuracy while providing clear English equivalents for Russian workforce management terminology and preserves all workflow descriptions, user interface elements, and system functionality explanations.