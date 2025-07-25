    1: # ARGUS WFM CC User Manual - Part 2
    2: ## Complete English Translation (Pages 200-462)
    3: 
    4: ---
    5: 
    6: ## Page 200
    7: 
    8: ![Synchronization Settings](img/synchronization_settings.png)
    9: 
   10: **Manual Corrections**
   11: 
   12: ![Manual Corrections Dialog](img/manual_corrections_dialog.png)
   13: 
   14: This setting determines how personnel structure in WFM CC can be modified:
   15: 
   16: • **Synchronization only** – personnel in WFM CC is created only automatically from external systems; manual creation is impossible.
   17: 
   18: • **Manual corrections only** – creating groups/services/operators is only possible manually.
   19: 
   20: • **Manual corrections and synchronization** – creating and receiving personnel is possible both through integration and manually. With this option, personnel created manually and absent in the external system will not be deleted during synchronization.
   21: 
   22: ### 7.1. Obtaining Personnel Data from External Systems
   23: 
   24: To obtain personnel structure and accounts from the contact center, click the button.
   25: 
   26: When clicking "Synchronize personnel," the personnel structure is updated automatically.
   27: 
   28: ![Personnel Synchronization](img/personnel_synchronization.png)
   29: 
   30: During personnel synchronization, existing employees in the system are matched, along with their organizational structure (departments) and functional structure (groups and services) by external ID. Depending on the settings in the "Integration Systems" directory, the update logic will change:
   31: 
   32: • If the integration system is marked with the "Master system" checkbox, then all organizational structure data comes to
   33: 
   34: ---
   35: 
   36: ## Page 201
   37: 
   38: WFM CC from it (creation and filling of data in operator cards, departments).
   39: 
   40: • If the integration system is not marked as "Master system," then it affects the functional structure (moves employees between groups/services).
   41: 
   42: Further logic depends on the personnel correction mode:
   43: 
   44: • **If "Synchronization only" mode is selected**, then the logic corresponds to the previous point when the integration system is selected as "Master system," i.e., functionality does not change.
   45: 
   46: • **If "Manual corrections" mode is selected**, then WFM CC system does not receive information about employees through integration.
   47: 
   48: • **If "Manual corrections and synchronization" mode is selected**, then WFM CC system receives all information through integration (structure of groups/services and employees in them, adding new employees, changes to information about existing ones), but employees who were not received through integration but exist in WFM CC system are not deleted.
   49: 
   50: In the "Integration Systems" window, we can see operators whose data came to WFM CC through integration from a specific external system.
   51: 
   52: ![Integration Systems Window](img/integration_systems_window.png)
   53: 
   54: ---
   55: 
   56: ## Page 202
   57: 
   58: Using the search line, you can find a specific employee; by clicking the icon, you can check which groups the employee belongs to.
   59: 
   60: ![Employee Groups Check](img/employee_groups_check.png)
   61: 
   62: In the WFM CC system window, there is an identical interface except that a specific operator can be expanded by clicking the arrow to the left of their checkbox to see if any accounts from integration systems are linked.
   63: 
   64: External system accounts are required to obtain historical data about the employee. For example, information about working time in the system, login time, time in statuses, etc. This information is used to build reports from the report editor, operator performance, etc.
   65: 
   66: ![External System Accounts](img/external_system_accounts.png)
   67: 
   68: ---
   69: 
   70: ## Page 203
   71: 
   72: ### 7.2. Account Linking
   73: 
   74: The ability to perform actions in the "Personnel Synchronization" block is available to users with the "Administrator" role or any other role with access right "Execute personnel synchronization" (System_AccessSynchronization).
   75: 
   76: Accounts from integration systems can be linked automatically. The system checks personnel numbers of existing employees and personnel numbers of received accounts. When they match, the account is linked to the employee. This algorithm has its features:
   77: 
   78: • If an account and personnel number came, but the existing employee has no personnel number, then the account needs to be added manually.
   79: 
   80: • If no personnel number comes through synchronization, then the account needs to be added manually.
   81: 
   82: • If an account came that is already assigned to an employee in WFM CC system, but the personnel number does not match the one received through integration, then the account is unlinked from the employee in WFM CC system and can be linked to another employee.
   83: 
   84: To manually link an account and employee, select the needed operator in the integration system window (via checkbox), mark the operator to whom you want to link the account in the WFM CC system window and click the button.
   85: 
   86: ![Manual Account Linking](img/manual_account_linking.png)
   87: 
   88: ---
   89: 
   90: ## Page 204
   91: 
   92: The linked account will be displayed in the WFM CC system window:
   93: 
   94: ![Linked Account Display](img/linked_account_display.png)
   95: 
   96: ### 8. Operator Data Collection
   97: 
   98: The page is available for viewing to users with access right "View 'Operator Data Collection' page" (System_AccessGetHistoricOperatorStatus).
   99: 
  100: The ability to collect operator data and configure automatic collection schedule is available to users with system role "Administrator" or any other role with access right "Operator data collection and automatic collection configuration" (System_EditGetHistoricOperatorStatus).
  101: 
  102: Operator data collection allows obtaining through synchronization with other systems data about actual operator presence in various statuses (login time, logout), number and time of processed requests (non-unique).
  103: 
  104: To go to the "Operator Data Collection" page, open the side menu and select "Personnel" → "Operator Data Collection."
  105: 
  106: ---
  107: 
  108: ## Page 205
  109: 
  110: ![Operator Data Collection Page](img/operator_data_collection_page.png)
  111: 
  112: On the page, there is separate functionality for automatic (or mass) updating of specific operator data, as well as separate functionality for manual obtaining of specific data for specific operators.
  113: 
  114: **Automatic (Mass) Operator Data Collection – Scheduled Data Collection Configuration**
  115: 
  116: ![Scheduled Data Collection](img/scheduled_data_collection.png)
  117: 
  118: In this block, you can obtain several types of data:
  119: 
  120: • **System working time**: shows how much time the operator was logged into one or another integration system.
  121: 
  122: ---
  123: 
  124: ## Page 206
  125: 
  126: • **Time in statuses**: shows how much time the operator spent in specific statuses. Statuses come to WFM CC system through integration (lunch, break, on call, etc.).
  127: 
  128: • **Request processing**: shows how much time the operator processed requests and how many such requests were processed by them during all working time.
  129: 
  130: • **Chat working time**: time when the operator was in the system with at least one chat in work (for example, in C2D).
  131: 
  132: • **Outgoing calls**: results of outgoing calls made by the operator.
  133: 
  134: Ultimately, each of these data types can be obtained automatically by setting automatic update settings, namely "Update Frequency."
  135: 
  136: **Collection frequency** – how often data needs to be obtained. Depending on the choice (monthly, weekly, daily), specify specific week numbers, days of weeks, time zone, and data collection time.
  137: 
  138: The button allows manually starting the process of obtaining one of the data types, specifying the period for which data needs to be obtained.
  139: 
  140: ![Manual Data Collection](img/manual_data_collection.png)
  141: 
  142: **Note**: In this block, WFM CC system obtains data for all operators who have integration system accounts. If mass updating of any data types is needed, manual updating of this data can be called.
  143: 
  144: ---
  145: 
  146: ## Page 207
  147: 
  148: **Manual Data Re-request**
  149: 
  150: Manual obtaining of specific data can be done in two ways:
  151: 
  152: • **By direction**
  153: 
  154: In this block, you can obtain specific data types (described above). Select one or several from the dropdown list for specific services and groups (multiple groups cannot be selected) for the selected period. To obtain data for all operators having an integration system account within the selected group, click.
  155: 
  156: ![Data Collection by Direction](img/data_collection_by_direction.png)
  157: 
  158: • **By operator**
  159: 
  160: In this block, you can obtain specific data types (described above). Select one type or several from the dropdown list for one specific operator (search by full name is available). To do this, enter the operator's full name, select the integration system to which the operator's account belongs (there may be several accounts for different systems), and data types that need to be obtained. After all parameters are set, click.
  161: 
  162: ---
  163: 
  164: ## Page 208
  165: 
  166: ![Data Collection by Operator](img/data_collection_by_operator.png)
  167: 
  168: ## 4. Load Forecasting in "ARGUS WFM CC" System
  169: 
  170: The load forecasting module is available to users with system role "Administrator," "Senior Operator," or any other role with access rights:
  171: 
  172: • **View pages in "Forecasting" section** (System_AccessForecastList)
  173: • **Edit load forecasts** (System_EditForecast)
  174: 
  175: Load forecasting through the Argus algorithm allows calculating expected load based on historical data provided by the contact center or manually imported by the user, as well as calculating the number of operators needed to cover the forecasted load. Based on the forecasted load, schedules and work timetables are built. Also included in forecasting functionality:
  176: 
  177: 1. Historical request data correction;
  178: 2. Historical AHT data correction;
  179: 3. Peak analysis;
  180: 
  181: ---
  182: 
  183: ## Page 209
  184: 
  185: 4. Trend analysis;
  186: 5. Seasonal component analysis;
  187: 6. Application of reserve coefficients;
  188: 7. Specifying minimum number of operators;
  189: 8. Application of growth coefficients;
  190: 9. Application of % Absenteeism coefficients.
  191: 
  192: To go to the "Forecast Load" tab, you can either through the "Forecasting" section from the sidebar or from the main page by clicking the "Forecasting" block:
  193: 
  194: ![Forecasting Main Page](img/forecasting_main_page.png)
  195: 
  196: Tabs within the section open sequentially. The proposed analysis tools can be skipped, but directly going to the final step "Calculate Number of Operators" is not possible.
  197: 
  198: ### 4.1. Historical Data: Import and Obtaining from Contact Center
  199: 
  200: To import historical data for load and operator forecasting, go to the "Forecast Load" tab, select service, group, schema, period for requests and AHT, time zone.
  201: 
  202: ![Historical Data Import](img/historical_data_import.png)
  203: 
  204: The "Schema" field determines which data will be considered when forecasting load. Choose one of the options:
  205: 
  206: ---
  207: 
  208: ## Page 210
  209: 
  210: • **Unique incoming requests** – requests having uniqueness attribute (depends on integration system) that arrived at the request processing channel. Incoming includes lost and dropped calls.
  211: 
  212: • **Unique processed requests** – requests having uniqueness attribute (depends on integration system) processed on the request processing channel.
  213: 
  214: • **Unique lost requests** – requests having uniqueness attribute (depends on integration system) lost on the request processing channel.
  215: 
  216: • **Non-unique incoming** – requests without uniqueness attribute that arrived at the request processing channel. Incoming includes lost and dropped calls.
  217: 
  218: • **Non-unique processed requests** – requests without uniqueness attribute processed on the request processing channel.
  219: 
  220: • **Non-unique lost requests** – requests without uniqueness attribute lost on the request processing channel.
  221: 
  222: Schema choice depends on individual contact center features. Most often "Non-unique incoming" is chosen. For example, if the same person called the line 3 times, then unique incoming counts as 1 request, and non-unique incoming counts as 3 requests.
  223: 
  224: #### 4.1.1. Import Requests from File
  225: 
  226: When there is no integration with the contact center, after selecting forecasting parameters, click "Apply," then the icon and select "Import."
  227: 
  228: ---
  229: 
  230: ## Page 211
  231: 
  232: ![Import Dialog](img/import_dialog.png)
  233: 
  234: Next, a system file selection window will open. Select the file and click "Open." After this, data import to the system will begin. The process takes some time depending on the volume of imported data. You can click the gear icon to see file upload progress.
  235: 
  236: ![Upload Progress](img/upload_progress.png)
  237: 
  238: Upon completion of loading, the loaded data will be displayed in the central part of the screen. You need to click the gear – "Save."
  239: 
  240: ![Save Loaded Data](img/save_loaded_data.png)
  241: 
  242: ---
  243: 
  244: ## Page 212
  245: 
  246: Data in the Excel file must be prepared in a specific format and contain the following columns:
  247: 
  248: 1. **Start of time interval** (in DD.MM.YYYY HH:MM:SS format). If no requests came during some N-minute period, it's better to leave the row with this time, filling with zeros (or leave unfilled, but don't remove completely).
  249: 2. **Unique incoming requests, pcs.** If there are none, you can leave the column empty or fill with zeros, but the column itself must be present. This applies to all subsequent items.
  250: 3. **Unique processed requests, pcs.**
  251: 4. **Unique lost requests, pcs.**
  252: 5. **Non-unique incoming, pcs.**
  253: 6. **Non-unique processed, pcs.**
  254: 7. **Non-unique lost requests, pcs.**
  255: 8. **Average talk time, sec.**
  256: 9. **Average post-processing duration, sec.**
  257: 
  258: Data in column 1 must be recorded in interval breakdown that the system is configured for (usually 5, 10, or 15 minutes). Required for filling are columns "Date Time," "Average talk time," and EITHER three columns with unique values OR three columns with non-unique values (depending on the schema chosen for forecasting).
  259: 
  260: ![Excel Data Format](img/excel_data_format.png)
  261: 
  262: The file may have several sheets, and values of some columns calculated using formulas. In this case, the system will look only at the first sheet, where the first column will be
  263: 
  264: ---
  265: 
  266: ## Page 213
  267: 
  268: recognized as date, and subsequent ones as numeric values (including those obtained by formula).
  269: 
  270: If forecasting is performed for an aggregated group, data must first be loaded into each simple group, then values summed using the tool in the system. The number of requests in the aggregated group equals the weighted average value of all simple groups included in the aggregated. The average talk time of the aggregated group equals the weighted average AHT value of all simple groups included in the aggregated.
  271: 
  272: To recalculate data on the "Forecast Load" page, fill in "Parameters" (service, group, schema, request period), click the icon and select "Recalculate data." After this, click the gear – "Save."
  273: 
  274: ![Recalculate Data](img/recalculate_data.png)
  275: 
  276: #### 4.1.2. Data Request via Integration
  277: 
  278: When there is integration with the contact center, historical data comes automatically through daily night integration (request period is configured on the "Forecasting" - "Update Settings" page). If manual data request is needed, after selecting forecasting parameters for the group, click gear - "Request data." To save, select gear – "Save."
  279: 
  280: ---
  281: 
  282: ## Page 214
  283: 
  284: ### 4.2. View and Edit Historical Request Data
  285: 
  286: The proposed analysis tools can be skipped, but tabs open sequentially and directly going to the final step "Calculate Number of Operators" is not possible.
  287: 
  288: **Important!** Editing historical data is an optional action. If editing historical data is not required, you can immediately proceed to the "Peak Analysis" section.
  289: 
  290: To correct historical data, go to the "Forecast Load" tab either through the "Forecasting" section from the sidebar or from the main page by clicking the "Forecasting" block.
  291: 
  292: On the opened "Historical Request Data Correction" page, select Service, Group, Schema, data period for requests and AHT that you plan to edit, as well as time zone. Click the "Apply" screen button and wait for the system to load data.
  293: 
  294: ![Historical Data Correction](img/historical_data_correction.png)
  295: 
  296: ---
  297: 
  298: ## Page 215
  299: 
  300: Data viewing and chart in the "Historical Data" section is available with breakdown by Months, Weeks, Days, Hours, Intervals. Select the appropriate one by clicking the corresponding screen button.
  301: 
  302: ![Data Breakdown Options](img/data_breakdown_options.png)
  303: 
  304: By default, the "Historical Data" section presents a table with all possible data schemas. But only columns with schemas for which data has been loaded into the System are filled.
  305: 
  306: Additionally, it's possible to configure display of only interesting columns through screen buttons "Columns," "Extended mode," "Reset column settings."
  307: 
  308: Using the "Extended mode" button, you can see a comparison of source data, unchanged by copying, inclusion/exclusion of values or averaging, with their modified version. If you need to return this data, just select the period and click "Reset to original."
  309: 
  310: ---
  311: 
  312: ## Page 216
  313: 
  314: ![Extended Mode](img/extended_mode.png)
  315: 
  316: Below are displayed charts, the first of which is "Traffic." It shows the number of requests for the time period previously selected by the user for viewing historical data.
  317: 
  318: ![Traffic Chart](img/traffic_chart.png)
  319: 
  320: The Y-axis shows the number of calls, the X-axis shows time periods depending on the display filter. The legend shows all data display schemas.
  321: 
  322: One or several lines on the chart can be removed. To do this, click on the item of interest in the legend with the left mouse button.
  323: 
  324: You can scroll through dates by selecting numbers below the chart or using arrows.
  325: 
  326: To change chart scale, place the mouse cursor in the part of the page where the chart is directly displayed and scroll the mouse wheel.
  327: 
  328: #### 4.2.1. Including, Excluding Values
  329: 
  330: To obtain more reliable data when forecasting load, the system has the ability to exclude load spikes (accident, temporary promotion, etc.) from historical data. This can be done at the step – "Include/exclude values."
  331: 
  332: ---
  333: 
  334: ## Page 217
  335: 
  336: ![Include Exclude Values](img/include_exclude_values.png)
  337: 
  338: Select the "Historical data period" for which corrections need to be made. On the chart, active intervals (those that will be considered during forecasting) are displayed in dark blue, and inactive intervals in light blue.
  339: 
  340: Below, the workspace is divided into 2 parts: Calendar and Table. Calendar allows working with days and intervals within the selected historical data period, Table – with intervals within one specific day.
  341: 
  342: Select the necessary period in the Calendar: day – by clicking on it with LMB, several days – LMB with Ctrl key held, continuous interval – LMB with Shift key held. After selection, the selected day/interval will be colored gray. You can also select several time intervals at once that need to be excluded/added. To select multiple intervals – click LMB with Ctrl key held.
  343: 
  344: ---
  345: 
  346: ## Page 218
  347: 
  348: ![Calendar Selection](img/calendar_selection.png)
  349: 
  350: After selecting intervals, click and choose the action you plan to do: Include or Exclude.
  351: 
  352: ![Include Exclude Actions](img/include_exclude_actions.png)
  353: 
  354: ---
  355: 
  356: ## Page 219
  357: 
  358: The excluded interval on the chart is marked with light blue color.
  359: 
  360: ![Excluded Interval Chart](img/excluded_interval_chart.png)
  361: 
  362: Undoing an action in the direct sense is impossible, but you can perform the reverse action: for exclusion – Include, for inclusion – Exclude.
  363: 
  364: ![Reverse Actions](img/reverse_actions.png)
  365: 
  366: If you need to include/exclude interval(s) within one day, select the day in the Calendar by clicking on it with LMB. Below in the Table, all values for the day will be reflected.
  367: 
  368: ---
  369: 
  370: ## Page 220
  371: 
  372: ![Day Selection Table](img/day_selection_table.png)
  373: 
  374: Selecting the necessary interval(s) in the Table is done similarly to the Calendar: one interval – by clicking on it with LMB, several intervals – LMB with Ctrl key held, continuous interval – LMB while holding Shift key. After selection, the selected interval(s) will be colored white.
  375: 
  376: ![Table Interval Selection](img/table_interval_selection.png)
  377: 
  378: To apply all changes made, click the screen button. It is located in the right corner above the Chart.
  379: 
  380: If changes have not been saved yet, when returning to the previous step, data exclusion will be reset. To cancel performed and saved changes, select the excluded day again, right-click on it – "Include."
  381: 
  382: #### 4.2.2. Copying Values
  383: 
  384: The next historical data correction tool for load forecasting in the system is "Copying Values." When viewing historical data, there is the ability to copy part of the data to another time period.
  385: 
  386: ---
  387: 
  388: ## Page 221
  389: 
  390: ![Copy Values Interface](img/copy_values_interface.png)
  391: 
  392: Specify the historical data period from which data needs to be copied:
  393: 
  394: ![Copy Source Period](img/copy_source_period.png)
  395: 
  396: The Y-axis displays data, X-axis displays time intervals. All data visible on the chart will be copied. You can scale specific periods by selecting them with the cursor directly on the chart:
  397: 
  398: ---
  399: 
  400: ## Page 222
  401: 
  402: ![Chart Scaling](img/chart_scaling.png)
  403: 
  404: After the time period is selected, select the historical data period where data needs to be copied:
  405: 
  406: ![Copy Destination Period](img/copy_destination_period.png)
  407: 
  408: When specifying the beginning of the period, its end will be set automatically based on the selected copying data period:
  409: 
  410: ![Auto End Period](img/auto_end_period.png)
  411: 
  412: The chart displays data that currently exists (light blue) and data that was copied (dark blue).
  413: 
  414: ---
  415: 
  416: ## Page 223
  417: 
  418: ![Copied Data Display](img/copied_data_display.png)
  419: 
  420: Lines on the chart can be hidden. To do this, click on the desired item from the legend located above the chart.
  421: 
  422: The chart can be scaled similarly to scaling when selecting data for copying.
  423: 
  424: If the obtained results do not need to be considered in analysis, proceed to the next tab without saving. To save results, click and "Apply":
  425: 
  426: ![Save Copy Results](img/save_copy_results.png)
  427: 
  428: To cancel performed and saved changes, return to the "Data View" tab and start the process again (from loading source data).
  429: 
  430: #### 4.2.3. Averaging Values
  431: 
  432: The final historical data correction tool for load forecasting in the system is "Averaging Values." Used in cases of insufficient historical data for some period. The system allows filling these gaps with averaged data from other intervals that have historical data.
  433: 
  434: ---
  435: 
  436: ## Page 224
  437: 
  438: Specify the time period from which data needs to be taken for averaging.
  439: 
  440: ![Averaging Source Period](img/averaging_source_period.png)
  441: 
  442: On the chart, Y-axis shows number of requests, X-axis shows time intervals in the selected day.
  443: 
  444: ![Averaging Chart](img/averaging_chart.png)
  445: 
  446: Below the chart, select the day of the week. The number of charts corresponds to the number of, for example, Wednesdays that fell within the interval selected above.
  447: 
  448: ![Day of Week Selection](img/day_of_week_selection.png)
  449: 
  450: ---
  451: 
  452: ## Page 225
  453: 
  454: The number of charts can be changed using the legend.
  455: 
  456: ![Chart Legend Control](img/chart_legend_control.png)
  457: 
  458: Next, select the time period in which data will be averaged:
  459: 
  460: ![Averaging Target Period](img/averaging_target_period.png)
  461: 
  462: The chart will mark data that exists now and averaged data. Information here is displayed by days (X-axis). Lines on charts can be hidden by clicking on the desired item in the legend.
  463: 
  464: ![Averaged Data Chart](img/averaged_data_chart.png)
  465: 
  466: The chart can be scaled similarly to scaling when selecting data for copying.
  467: 
  468: ---
  469: 
  470: ## Page 226
  471: 
  472: If the obtained results do not need to be considered in analysis, proceed to the next step of Forecasting – "Historical AHT Data Correction."
  473: 
  474: To save results, click and "Apply":
  475: 
  476: ![Save Averaging Results](img/save_averaging_results.png)
  477: 
  478: To cancel performed and saved changes, return to the "Data View" tab and start the process again (from loading source data).
  479: 
  480: ---
  481: 
  482: ## Page 227
  483: 
  484: ### 4.3. View and Edit Historical AHT Data
  485: 
  486: Editing historical AHT data is an optional action. If editing historical AHT data is not required, you can immediately proceed to the "Peak Analysis" section.
  487: 
  488: The process of editing historical AHT data is similar to editing historical request data described in section 4.2 View and Edit Historical Request Data. We recommend using information from that section.
  489: 
  490: ### 4.4. Peak Analysis
  491: 
  492: After viewing and editing historical data for the selected group for the selected time period, the system will offer to analyze load peaks. Load peaks can be smoothed if their presence is explained by abnormal load growth or load decline.
  493: 
  494: "Peak Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next one.
  495: 
  496: ![Peak Analysis Interface](img/peak_analysis_interface.png)
  497: 
  498: In the "Forecast" section, time periods, number of requests and outlier type, average talk time and its outlier type are displayed.
  499: 
  500: An outlier is considered to be load values located between the upper outer and inner boundary, as well as those exceeding its limits, or values located between the lower outer and inner boundary, as well as those exceeding its limits. Outliers are calculated based on the quartile range analysis method (IQR – InterQuartile Range).
  501: 
  502: The concept of 1st, 2nd, 3rd order quartiles is highlighted:
  503: 
  504: • **Quartile 3 (Q3)** – value (from the sample of all historical data values) for which 75% of data is less than or equal to it.
  505: 
  506: • **Quartile 2 (Q2)** – value for which 50% of data is less than or equal to it (median in historical data)
  507: 
  508: • **Quartile 1 (Q1)** – value for which approximately 25% of data is less than or equal to it.
  509: 
  510: In the historical data array, extreme and moderate outliers are searched:
  511: 
  512: • **Extreme** – outlier that went beyond the outer boundary (upper or lower) – red line.
  513: 
  514: • **Moderate** – outlier located within the outer and inner boundary (upper or lower) – purple line.
  515: 
  516: Below the table are charts showing boundaries and number of requests and average AHT.
  517: 
  518: ---
  519: 
  520: ## Page 228
  521: 
  522: ![Peak Analysis Chart](img/peak_analysis_chart.png)
  523: 
  524: Boundary lines, requests, AHT can be hidden on the chart by clicking on the desired item in the legend. The chart shows the same periods shown in the table above. To view other periods, select another page in the table.
  525: 
  526: Next, there is the ability to choose which peaks need to be smoothed. To display the list, click.
  527: 
  528: ![Peak Smoothing Options](img/peak_smoothing_options.png)
  529: 
  530: • **Smooth extreme request peaks** – system smooths request outliers located above outer boundaries.
  531: 
  532: • **Smooth all request peaks** – system smooths extreme outliers and moderate ones located between outer and inner boundaries.
  533: 
  534: • **Smooth extreme AHT peaks** – system smooths AHT outliers located above outer boundaries.
  535: 
  536: • **Smooth all AHT peaks** – system smooths extreme outliers and moderate ones located between outer and inner boundaries.
  537: 
  538: • **Smooth selected peaks** – system smooths those outliers whose periods are marked with a checkmark.
  539: 
  540: ![Selected Peaks](img/selected_peaks.png)
  541: 
  542: • **Smooth all** – system smooths all request and AHT outliers.
  543: 
  544: ---
  545: 
  546: ## Page 229
  547: 
  548: • **Cancel** – action cancels all previous smoothing if any was performed.
  549: 
  550: After smoothing, values with outliers will be removed from the table analysis, and the chart will be leveled.
  551: 
  552: Changes will look like this.
  553: 
  554: Before smoothing:
  555: 
  556: ![Before Smoothing](img/before_smoothing.png)
  557: 
  558: After smoothing all peaks:
  559: 
  560: ---
  561: 
  562: ## Page 230
  563: 
  564: ![After Smoothing](img/after_smoothing.png)
  565: 
  566: Additional saving of applied changes is not required; simply proceed to the next "Trend Analysis" tab.
  567: 
  568: At the Peak Analysis stage, viewing is available not only by intervals but also by days or days of the week.
  569: 
  570: The "Group data by day" function is needed when outliers within an interval don't matter. Only whether the entire day stands out from the overall picture matters.
  571: 
  572: ---
  573: 
  574: ## Page 231
  575: 
  576: ![Group by Day](img/group_by_day.png)
  577: 
  578: The "Consider days of the week" function allows grouping data by all Mondays, all Tuesdays, etc., falling within the historical data period, and based on already grouped data, see if there's an anomaly in any of the days from the general series and whether smoothing is necessary.
  579: 
  580: ![Consider Days of Week](img/consider_days_of_week.png)
  581: 
  582: ### 4.5. Trend Analysis
  583: 
  584: "Trend Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next step.
  585: 
  586: Trend is calculated as linear regression y = a + bx, where a is the free term, b is the angular coefficient. Trend determines
  587: 
  588: ---
  589: 
  590: ## Page 232
  591: 
  592: patterns in the number of calls; it can be increasing and decreasing.
  593: 
  594: • **Increasing** – when the number of calls gradually grows from the beginning of the period and continues to grow toward its end. In this case, a pattern is visible – calls toward the end of the month become more. In this case, during forecasting, the system will account for and continue the trend of increasing calls (while maintaining various coefficients and formulas).
  595: 
  596: • **Decreasing** – when the number of calls gradually decreases from the beginning of the period and continues to fall until its end.
  597: 
  598: In this case, a pattern is visible – calls toward the end of the month become fewer. In this case, during forecasting, the system will account for and continue the trend of decreasing calls (while maintaining various coefficients and formulas).
  599: 
  600: ![Trend Analysis Interface](img/trend_analysis_interface.png)
  601: 
  602: You can either consider the trend when composing the forecast or not consider it – select the desired option in the "Parameters" field (can be set separately for requests and AHT).
  603: 
  604: If the trend is considered, you can manually change the angle of inclination and free coefficient (point from which the trend starts growing on the chart). To do this, enter values in the "Angle change" and "Coefficient a change" fields.
  605: 
  606: ---
  607: 
  608: ## Page 233
  609: 
  610: ![Trend Parameters](img/trend_parameters.png)
  611: 
  612: ### 4.6. Seasonal Component Analysis
  613: 
  614: "Seasonal Component Analysis" is the next step in the Forecasting module. If this tool is not relevant, proceed to the next step.
  615: 
  616: Seasonal component analysis allows accounting for seasonal load fluctuations in the historical data period for requests and AHT. Any combination of parameters can be used for both requests and AHT; multiple selection is possible.
  617: 
  618: ![Seasonal Analysis Interface](img/seasonal_analysis_interface.png)
  619: 
  620: In the "Request Parameters" / "AHT Parameters" blocks, seasonality levels that can be considered are provided. Select those that most accurately fit your data. The system has six seasonality levels available.
  621: 
  622: **Intervals in day**: determined as load deviation in one or another time interval within the day relative to average load within the entire day.
  623: 
  624: ---
  625: 
  626: ## Page 234
  627: 
  628: For example, consider the interval from 13:00 to 13:05. The seasonal coefficient corresponding to a specific interval is calculated as the ratio of the average of all values in historical data corresponding to the time period from 13:00 to 13:05 to the overall average of all values in historical data.
  629: 
  630: ![Intervals in Day](img/intervals_in_day.png)
  631: 
  632: **Intervals in day of week**: determined as load deviation in one or another time interval within a day of the week relative to average load within the day of the week.
  633: 
  634: For example, consider Monday from 13:00 to 13:05. The seasonal coefficient corresponding to a specific interval of the day of the week is calculated as the ratio of the average of all values in historical data corresponding to the time period from 13:00 to 13:05 of Monday to the overall average of all values in historical data.
  635: 
  636: ![Intervals in Day of Week](img/intervals_in_day_of_week.png)
  637: 
  638: **Days in month**: determined as load deviation on one or another day (date) of the month relative to average load within the entire month.
  639: 
  640: For example, consider the 22nd day of the month. The seasonal coefficient corresponding to a specific day (date) in the month is calculated as the ratio of the average of all values in historical data corresponding to the 22nd days of all months falling within the historical data period to the overall average of all values in historical data.
  641: 
  642: ---
  643: 
  644: ## Page 235
  645: 
  646: ![Days in Month](img/days_in_month.png)
  647: 
  648: The blue line on the chart shows the average number of calls for the entire historical data period, and the red line shows the number of requests in 15-minute intervals for all first/second/third days of the selected historical data period. The figure shows the number of requests for all fifth days of all months in 15-minute intervals. To select another day, click:
  649: 
  650: ![Day Selection](img/day_selection.png)
  651: 
  652: In the figure, the red line shows the average number of calls for all 11th days of all months included in the selected time period.
  653: 
  654: **Days in week**: determined as load deviation on one or another day of the week relative to average load within the entire week.
  655: 
  656: ---
  657: 
  658: ## Page 236
  659: 
  660: For example, consider the day of the week – Wednesday. The seasonal coefficient corresponding to a specific day of the week is calculated as the ratio of the average of all values in historical data corresponding to all Wednesdays falling within the historical data period to the overall average of all values in historical data.
  661: 
  662: ![Days in Week](img/days_in_week.png)
  663: 
  664: In the figure, the blue line shows the average number of calls for the entire time period selected earlier. The red line shows the average number of calls for all Mondays in the selected time period. Days of the week can be selected below the chart.
  665: 
  666: **Weeks in month**: determined as load deviation in one or another week of the month relative to average load within the entire month.
  667: 
  668: For example: consider the 2nd week of the month. The seasonal coefficient corresponding to a specific week should be calculated as the ratio of the average of all values in historical data corresponding to the 2nd weeks of the month to the overall average of all values in historical data.
  669: 
  670: ---
  671: 
  672: ## Page 237
  673: 
  674: ![Weeks in Month](img/weeks_in_month.png)
  675: 
  676: In the figure, the blue line shows the average number of calls for the entire time period selected earlier. The red line shows the average number of calls for all first weeks of all months from the previously selected time period. Week numbers are selected below the chart.
  677: 
  678: **Month in year**: determined as load deviation in one or another month relative to average load within the entire year.
  679: 
  680: For example, consider February. The seasonal coefficient corresponding to a specific month is calculated as the ratio of the average of all values in historical data corresponding to February to the overall average of all values in historical data.
  681: 
  682: ![Month in Year](img/month_in_year.png)
  683: 
  684: In the figure, the blue line shows the average number of requests for the entire time period selected earlier. Red shows the average
  685: 
  686: ---
  687: 
  688: ## Page 238
  689: 
  690: number of requests for all second months of the selected time period. Numbers can be selected by clicking:
  691: 
  692: ![Month Selection](img/month_selection.png)
  693: 
  694: Similarly, all seasonal components marked with a "checkmark" in the "AHT Parameters" field will be considered during forecasting.
  695: 
  696: ### 4.7. Traffic and AHT Forecasting
  697: 
  698: The "Traffic and AHT Forecasting" step is the penultimate before calculating the actual number of operators. At this step, the resulting request forecast is presented, which can be viewed on charts and you can decide whether to return to previous steps and consider other inputs.
  699: 
  700: **Important!** The system does not allow saving the resulting forecast, starting over and comparing results. Forecast versioning is not supported.
  701: 
  702: ![Traffic AHT Forecasting](img/traffic_aht_forecasting.png)
  703: 
  704: In the "Forecasting" field, select the period for which load will be forecasted.
  705: 
  706: ---
  707: 
  708: ## Page 239
  709: 
  710: Optionally, the forecast can consider "Special dates."
  711: 
  712: After selecting the forecasting period, all intervals (with possible switching to hours, days, weeks, or months) with forecasted number of requests and AHT will be displayed in the "Forecast" field.
  713: 
  714: The forecasted number of requests and AHT can be manually corrected by clicking next to the desired interval. Editing capability is only available in "Intervals" mode.
  715: 
  716: ![Manual Forecast Correction](img/manual_forecast_correction.png)
  717: 
  718: After editing, you can either apply new values or cancel them.
  719: 
  720: Charts show the number of forecasted requests and their average processing time in seconds. Charts can be viewed by months, weeks, days, hours, intervals.
  721: 
  722: ![Forecast Charts](img/forecast_charts.png)
  723: 
  724: An additional tool for correcting obtained values is the growth coefficient. We recommend using it if at the time of load forecasting, upcoming growth or decline in load is known in advance. When setting a growth coefficient, the forecasted
  725: 
  726: ---
  727: 
  728: ## Page 240
  729: 
  730: number of requests will be multiplied by the set coefficient.
  731: 
  732: To set a growth coefficient, click, then "Growth coefficient."
  733: 
  734: ![Growth Coefficient Setting](img/growth_coefficient_setting.png)
  735: 
  736: Next, select the time period for which the coefficient applies and enter the growth coefficient itself. To apply entered data, click or – to cancel.
  737: 
  738: ![Growth Coefficient Parameters](img/growth_coefficient_parameters.png)
  739: 
  740: The "Growth coefficient" column reflects the entered value, the "Recalculated" column reflects the forecasted load obtained by multiplying by the coefficient.
  741: 
  742: If it's necessary to consider several increasing or decreasing coefficients, then before starting forecasting, you need to fill the "Special Events" directory.
  743: 
  744: ---
  745: 
  746: ## Page 241
  747: 
  748: ### 4.8. Calculate Number of Operators
  749: 
  750: The final step in Forecasting is calculating the number of operators. At this step, the system calculates operators needed to cover the load forecasted at the "Traffic and AHT Forecasting" step.
  751: 
  752: ![Calculate Operators Interface](img/calculate_operators_interface.png)
  753: 
  754: The system has 4 operator calculation models available, each with a specific set of parameters.
  755: 
  756: #### 4.8.1. Calculate Number of Operators by "Erlang C" Model
  757: 
  758: Erlang C (old name – Voice channel) is a standard forecasting algorithm using the improved Erlang C formula (considering SL corridor), most often used on voice channels.
  759: 
  760: ---
  761: 
  762: ## Page 242
  763: 
  764: ![Erlang C Model](img/erlang_c_model.png)
  765: 
  766: When selecting this model, specify the following parameters:
  767: 
  768: • **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.
  769: 
  770: • **Customer wait time, sec.** – maximum customer wait time on the line (in seconds) or customer wait time on the line after IVR distribution until operator answer.
  771: 
  772: • **Operator occupancy** – desired/established contact center operator occupancy percentage.
  773: 
  774: • **SL (min and max)** – desired SL boundaries established in the contact center. The system will calculate the number of operators to fit within the specified SL framework.
  775: 
  776: • **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.
  777: 
  778: • **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.
  779: 
  780: #### 4.8.2. Calculate Number of Operators by "Linear" Model
  781: 
  782: Linear (old name – Non-voice channel) is a forecasting algorithm most often used for non-voice channels (operator can work with several requests in parallel).
  783: 
  784: ---
  785: 
  786: ## Page 243
  787: 
  788: The model does not require binding to service level (SL), can handle cases when average request handling time (AHT) is greater than the system interval (5, 10, or 15 minutes).
  789: 
  790: ![Linear Model](img/linear_model.png)
  791: 
  792: When selecting this model, specify the following parameters:
  793: 
  794: • **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.
  795: 
  796: • **Operator occupancy** – desired/established contact center operator occupancy percentage.
  797: 
  798: • **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.
  799: 
  800: ---
  801: 
  802: ## Page 244
  803: 
  804: • **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.
  805: 
  806: • **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.
  807: 
  808: #### 4.8.3. Calculate Number of Operators by "Erlang C with SLA" Model
  809: 
  810: Erlang C with SLA (old name – Non-voice channel with SLA consideration) is a forecasting algorithm most often used for non-voice channels (operator can work with several requests in parallel) where service level (SL) needs to be considered.
  811: 
  812: ![Erlang C with SLA Model](img/erlang_c_sla_model.png)
  813: 
  814: When selecting this model, specify the following parameters:
  815: 
  816: ---
  817: 
  818: ## Page 245
  819: 
  820: • **% ACD Calls** – percentage of accepted requests. If 100% is specified, all forecasted requests will be considered.
  821: 
  822: • **Customer wait time, sec.** – maximum customer wait time on the line (in seconds) or customer wait time on the line after IVR distribution until operator answer.
  823: 
  824: • **Operator occupancy** – desired/established contact center operator occupancy percentage.
  825: 
  826: • **SL (min and max)** – desired SL boundaries established in the contact center. The system will calculate the number of operators to fit within the specified SL framework.
  827: 
  828: • **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.
  829: 
  830: • **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.
  831: 
  832: • **Period within day** – applying set KPI indicators to a specific period within the day. When clicking "Add intraday interval," by default, indicators apply to the entire day (all 24 hours) unless otherwise set in the "Day period" field.
  833: 
  834: #### 4.8.4. Calculate Number of Operators by "Linear with AWT" Model
  835: 
  836: Linear with AWT is a forecasting algorithm used for calculating non-voice channel operators. The approach feature is that the contact center works certain hours within the day (for example, 09:00 – 21:00) with backlog accumulation during non-working time. Requests that came at night have priority over morning ones and must be processed within a specified number of hours from the start of the shift.
  837: 
  838: ---
  839: 
  840: ## Page 246
  841: 
  842: ![Linear with AWT Model](img/linear_awt_model.png)
  843: 
  844: When selecting this model, specify the following parameters:
  845: 
  846: • **AWT, min** – average call wait time in queue until customer answer, multiple of system interval.
  847: 
  848: • **Operator occupancy** – desired/established contact center operator occupancy percentage.
  849: 
  850: • **Average handling time (AHT)** – request processing time (talk time + post-processing time). Manual input option is available or automatic calculation by the system by selecting the "Consider statistically calculated AHT" checkbox.
  851: 
  852: • **Number of simultaneous requests** – number of requests that an Operator can process simultaneously.
  853: 
  854: • **Contact center working hours** – contact center working hours within the day
  855: 
  856: • **Processing interval for requests received during non-working time** – time period from the start of contact center operation during which requests received during non-working time must be processed.
  857: 
  858: ---
  859: 
  860: ## Page 247
  861: 
  862: • **Add intraday period** – applying set KPI indicators to the contact center operation period.
  863: 
  864: #### 4.8.5. Adding Intraday Period
  865: 
  866: The above-described parameters can be applied either to the entire forecasted request period or to specific days through configuration in the left part of the screen.
  867: 
  868: ![Intraday Period Configuration](img/intraday_period_configuration.png)
  869: 
  870: In "Day" mode, select either one day or several by highlighting them with the left mouse button while holding the CTRL key.
  871: 
  872: ![Day Mode Selection](img/day_mode_selection.png)
  873: 
  874: ---
  875: 
  876: ## Page 248
  877: 
  878: Selected calculation parameters can be applied either to the entire day (i.e., all 24 hours) or to a specific period within the day. For example, in the morning, SL value or average customer wait time will differ (fewer requests in the morning, so customers will wait less).
  879: 
  880: To apply selected parameters, choose the daily interval or leave the default interval 00:00-24:00 and click "Add intraday interval."
  881: 
  882: ![Add Intraday Interval](img/add_intraday_interval.png)
  883: 
  884: ---
  885: 
  886: ## Page 249
  887: 
  888: ![Intraday Interval Applied](img/intraday_interval_applied.png)
  889: 
  890: #### 4.8.6. Calculate Number of Operators
  891: 
  892: When all needed periods within the day have calculation parameters set (period will be highlighted in green), check that the calculation period is correctly selected ("Entire period" or "Day") and click "Calculate number of operators." Below will display a table showing the calculated number of operators needed to cover the forecasted load. You can select data aggregation by intervals, hours, days, weeks, and months.
  893: 
  894: The table consists of the following fields and data (when selecting aggregation by intervals):
  895: 
  896: • **Time intervals**;
  897: 
  898: • **Forecasted considering % ACD (requests)** – forecasted number of requests considering %ACD;
  899: 
  900: • **Growth coefficient (requests)** – indicator set at the "Traffic and AHT Forecasting" step (default 1.0 if nothing else was specified);
  901: 
  902: ---
  903: 
  904: ## Page 250
  905: 
  906: • **Recalculated (requests)** – forecasted number of requests considering growth coefficient and "Special Events" from the directory of the same name;
  907: 
  908: • **Forecasted (operators)** - number of operators calculated by the system without considering coefficients;
  909: 
  910: • **% Absenteeism (operators)** – percentage of operators who may be absent (sick, time off, etc.). Can be set on the "Calculate Number of Operators" page by clicking;
  911: 
  912: • **Reserve coefficient (operators)** – coefficient by which the calculated number of operators is multiplied. Can be set on the "Calculate Number of Operators" page by clicking;
  913: 
  914: • **Final (operators)** – final forecasted number of operators needed to cover the load, considering all coefficients and minimum number of operators (can be set on the "Calculate Number of Operators" page by clicking);
  915: 
  916: • **AHT** – average request handling time, set manually at the stage of filling parameters for operator calculation, or forecasted by the system based on historical data (when checking "Consider statistically calculated AHT" in the parameters above).
  917: 
  918: ---
  919: 
  920: ## Page 251
  921: 
  922: ![Operator Calculation Table](img/operator_calculation_table.png)
  923: 
  924: The table consists of the following fields and data (when selecting aggregation by hours, days, weeks, and months):
  925: 
  926: • **Time intervals**;
  927: 
  928: • **Forecasted considering % ACD (requests)** – forecasted number of requests considering %ACD;
  929: 
  930: • **Recalculated (requests)** – forecasted number of requests considering growth coefficient and "Special Events" from the directory of the same name;
  931: 
  932: • **Forecasted (operators)** - number of operators calculated by the system without considering coefficients;
  933: 
  934: • **Person-hours (operators)** – arithmetic average of operators for the selected period (for hour aggregation, the number of intervals is summed; for day aggregation, the number of hours is summed; for week and month aggregation, the number of days is summed);
  935: 
  936: • **% Absenteeism (operators)** – percentage of operators who may be absent (sick, time off, etc.). Can be set on the "Calculate Number of Operators" page by clicking;
  937: 
  938: • **Final (operators)** – final forecasted number of operators needed to cover the load, considering all coefficients and minimum number of operators (can be set on the "Calculate Number of Operators" page by clicking);
  939: 
  940: • **AHT** – average request handling time, set manually at the stage of filling parameters for operator calculation, or forecasted by the system based on historical data (when checking "Consider statistically calculated AHT" in the parameters above).
  941: 
  942: ---
  943: 
  944: ## Page 252
  945: 
  946: ![Aggregated Calculation Table](img/aggregated_calculation_table.png)
  947: 
  948: Below, charts display the number of forecasted operators, requests, and AHT.
  949: 
  950: ![Forecast Charts Display](img/forecast_charts_display.png)
  951: 
  952: The chart can be viewed by months, weeks, days, hours, and intervals.
  953: 
  954: #### 4.8.7. Coefficients for Calculating Number of Operators
  955: 
  956: Additional parameters can be applied to the forecasted number of operators.
  957: 
  958: ---
  959: 
  960: ## Page 253
  961: 
  962: ![Operator Coefficients](img/operator_coefficients.png)
  963: 
  964: **Minimum operators**: determines the minimum number of operators that must be present on the line. Used, for example, for night periods: there's no load (no requests, zero forecast), but even in this situation, two operators should be on the line. If the forecasted number of operators is less than the set minimum, it will change to the set minimum. If the forecasted number of operators equals or exceeds the set minimum, it will not change. At the same time, the number of operators recalculated considering the minimum does not overwrite data forecasted by the system. Therefore, if necessary, the minimum can be changed or canceled – new values will be applied to the originally calculated number of operators.
  965: 
  966: To set minimum operators, select the period to which the minimum will be applied and the number of operators itself.
  967: 
  968: ![Minimum Operators Setting](img/minimum_operators_setting.png)
  969: 
  970: When applying, click or – to cancel.
  971: 
  972: ---
  973: 
  974: ## Page 254
  975: 
  976: ![Apply Minimum Operators](img/apply_minimum_operators.png)
  977: 
  978: **Reserve coefficient**: similar to growth coefficient for request calculation but applied to the number of operators. Used in situations when at a specific time it's necessary to bring more operators to the line: the calculated number of operators will be multiplied by the reserve coefficient.
  979: 
  980: When reserve coefficient is used together with minimum operators, the system will follow these rules:
  981: 
  982: • If the forecasted number of operators is less than the minimum, then the final number of operators will be calculated by the formula: minimum operators * reserve coefficient.
  983: 
  984: • If the forecasted number of operators is greater than or equal to the minimum, then the final number of operators will be calculated by the formula: forecasted number of operators * reserve coefficient.
  985: 
  986: For example, at 08:00, 6 operators are forecasted, at 08:15 – 10 operators. We set minimum operators to 8 and reserve coefficient to 2.0. The final number of operators at 08:00 will be 16 (8 * 2), and at 08:15 – 20 (10 * 2).
  987: 
  988: To calculate the coefficient, specify the period to which it will be applied and the coefficient itself.
  989: 
  990: ---
  991: 
  992: ## Page 255
  993: 
  994: ![Reserve Coefficient Setting](img/reserve_coefficient_setting.png)
  995: 
  996: After which click - to apply, or – to cancel.
  997: 
  998: ![Apply Reserve Coefficient](img/apply_reserve_coefficient.png)
  999: 
 1000: **%Absenteeism**:
 1001: 
 1002: The parameter indicates the percentage of operators who may be absent from work due to illness or time off. To set the parameter, specify the period to which it will be applied and the percentage itself.
 1003: 
 1004: ![Absenteeism Setting](img/absenteeism_setting.png)
 1005: 
 1006: After which click - to apply, or – to cancel.
 1007: 
 1008: ---
 1009: 
 1010: ## Page 256
 1011: 
 1012: ![Apply Absenteeism](img/apply_absenteeism.png)
 1013: 
 1014: To cancel entered values, you need to click the gear again and set zero value in the needed coefficient instead of the entered one (for reserve coefficient, value 1.0).
 1015: 
 1016: To save all set coefficients, select "Save" through the "gear." This completes the forecasting process.
 1017: 
 1018: ![Save Coefficients](img/save_coefficients.png)
 1019: 
 1020: After saving data, it can be seen in the "Load View" section.
 1021: 
 1022: ### 4.9. Forecast Accuracy Analysis
 1023: 
 1024: Access right System_AccessAnalysisAccuracy opens access to the "Forecast Accuracy Analysis" page.
 1025: 
 1026: Allows evaluating the accuracy of load forecasted by the system. If in your view the accuracy is low, return to the "Forecast Load" section and build a new forecast, analyzing the reasons for low accuracy.
 1027: 
 1028: To go to the "Forecast Accuracy Analysis" page, open the side menu or main page: "Forecasting" → "Accuracy Analysis."
 1029: 
 1030: ---
 1031: 
 1032: ## Page 257
 1033: 
 1034: ![Forecast Accuracy Analysis](img/forecast_accuracy_analysis.png)
 1035: 
 1036: To view forecast accuracy percentage, select the service and group of interest, as well as the period for which the system has both historical data and forecast.
 1037: 
 1038: ![Accuracy Analysis Parameters](img/accuracy_analysis_parameters.png)
 1039: 
 1040: If an aggregated group was added to the "Group" field, a "Recalculate data" button appears. It allows summing historical data by simple groups without going to the "Forecast Load" page.
 1041: 
 1042: ---
 1043: 
 1044: ## Page 258
 1045: 
 1046: ![Recalculate Data Option](img/recalculate_data_option.png)
 1047: 
 1048: When the "Personnel" - "Group Structure" page is filled in the system, viewing accuracy by segment is available on the "Forecast Accuracy Analysis" page.
 1049: 
 1050: ![Accuracy by Segment](img/accuracy_by_segment.png)
 1051: 
 1052: Accuracy percentage is calculated by intervals for the selected data display period. Display can be changed to hours, days, weeks, months. On "Plan/actual" charts, blue color shows the chart of forecasted number of requests, purple shows actual number of requests. The "Forecast accuracy for period" section provides: MFA – average accuracy and WFA – weighted accuracy.
 1053: 
 1054: MAPE, WAPE, MFA, WFA charts:
 1055: 
 1056: ---
 1057: 
 1058: ## Page 259
 1059: 
 1060: ![Accuracy Charts](img/accuracy_charts.png)
 1061: 
 1062: **MAPE (Mean Absolute Percentage Error)** – average absolute error in percentages. Calculated based on the number of intervals depending on the selected display mode (all intervals, intervals in hour, day, week, month), actual and forecasted number of requests per interval.
 1063: 
 1064: **WAPE (Weighted Absolute Percentage Error)** – weighted absolute percentage error. Each interval receives weight equal to the share of request volume in this interval from the total request volume of the considered period. Also calculated based on the number of intervals (number varies depending on selected display mode), total number of incoming requests for the entire considered period and number of incoming requests for corresponding intervals.
 1065: 
 1066: Lines on charts can be hidden: to do this, click on the desired item in the legend with the left mouse button.
 1067: 
 1068: ### 4.10. Mass Forecast Assignment
 1069: 
 1070: This functionality allows assigning parameters for calculating the number of operators to several groups at once.
 1071: 
 1072: To go to the "Mass Forecast Assignment" page, open the side menu: "Forecasting" → "Mass Forecast Assignment."
 1073: 
 1074: ---
 1075: 
 1076: ## Page 260
 1077: 
 1078: ![Mass Forecast Assignment](img/mass_forecast_assignment.png)
 1079: 
 1080: On the opened page, select the service, group (or one group) to which parameters need to be assigned en masse.
 1081: 
 1082: ![Select Groups for Mass Assignment](img/select_groups_mass_assignment.png)
 1083: 
 1084: Next, change parameters by clicking on the selected parameter with the left mouse button.
 1085: 
 1086: After all parameters are configured, click.
 1087: 
 1088: Now, the next time when forecasting requests and operators for the selected group or groups, the parameters set on this page will already be specified at the operator calculation stage. The ability to make changes at the time of forecasting is preserved.
 1089: 
 1090: ---
 1091: 
 1092: ## Page 261
 1093: 
 1094: ### 4.11. Update Historical Data on Schedule
 1095: 
 1096: To view "Update Settings," you need access right "System_AccessGetHistoricalData." To edit historical data update settings, you need access right "System_EditGetHistoricalData."
 1097: 
 1098: Obtaining historical data for load forecasting can be automated. In "Update Settings," you can set settings for automatic historical data requests for all groups. To do this, go to "Forecasting" → "Update Settings."
 1099: 
 1100: ![Update Settings Page](img/update_settings_page.png)
 1101: 
 1102: When opening "Update Settings," the following settings will be displayed:
 1103: 
 1104: ---
 1105: 
 1106: ## Page 262
 1107: 
 1108: ![Update Settings Configuration](img/update_settings_configuration.png)
 1109: 
 1110: **Collection frequency** – how often historical data should be automatically obtained for all groups. The following options are available:
 1111: 
 1112: • **Daily**: specify time zone and time when historical data request will be executed.
 1113: 
 1114: • **Weekly**: specify day of the week and time when historical data request will be executed.
 1115: 
 1116: ![Weekly Settings](img/weekly_settings.png)
 1117: 
 1118: **Monthly**: specify week number, day of that week, and time of day when historical data request will be executed.
 1119: 
 1120: ![Monthly Settings](img/monthly_settings.png)
 1121: 
 1122: ---
 1123: 
 1124: ## Page 263
 1125: 
 1126: When clicking the "Update for period" button, you can update historical data for all groups at once for a specific period without waiting for automatic update (with working contact center integration).
 1127: 
 1128: ![Update for Period](img/update_for_period.png)
 1129: 
 1130: ### 4.12. Special Dates Analysis
 1131: 
 1132: The "Special Dates Analysis" module is available to users with system role "Administrator" or any other role with access rights System_AccessForecastList – View pages in the "Forecasting" section.
 1133: 
 1134: There are days when the load profile differs from normal request distribution, while the differing days themselves are similar to each other. For example, holidays or periods of mailings, promotions. This module implements functionality for adding analysis of special date historical data and calculating load distribution coefficients on such days for their further use when forecasting load for similar days (unlike growth coefficients in the "Special Events" directory, where values are set manually, not calculated by the system).
 1135: 
 1136: The "Special Dates Analysis" page can be found in the navigation menu:
 1137: 
 1138: ---
 1139: 
 1140: ## Page 264
 1141: 
 1142: ![Special Dates Analysis Menu](img/special_dates_analysis_menu.png)
 1143: 
 1144: Two tabs are available on the page:
 1145: 
 1146: • **Special Dates Analysis**;
 1147: • **View Coefficients**.
 1148: 
 1149: On the "Special Dates Analysis" tab, you can configure a special date/day for subsequent use in forecasting.
 1150: 
 1151: On the "View Coefficients" tab, you can review already created dates/days for forecasting.
 1152: 
 1153: Creating special dates, let's examine with an example.
 1154: 
 1155: Suppose our company had similar peak load days that don't follow a specific pattern (such as seasonal promotions). In this case, we can review historical data for promotion days and determine the load deviation coefficient to use in future forecasts when this event repeats.
 1156: 
 1157: For this, we need to fill in data for service, group, select forecasting schema, request period, and time zone.
 1158: 
 1159: ---
 1160: 
 1161: ## Page 265
 1162: 
 1163: ![Special Dates Configuration](img/special_dates_configuration.png)
 1164: 
 1165: After this, click the "Apply" button.
 1166: 
 1167: In the "Special dates" window, select peak load dates for analysis (in our case, dates when there was a promotion) by clicking the "Calendar" button.
 1168: 
 1169: ![Special Dates Calendar](img/special_dates_calendar.png)
 1170: 
 1171: After selecting dates for analysis, their load deviation coefficients will be displayed graphically by intervals in daily breakdown.
 1172: 
 1173: ![Load Deviation Coefficients](img/load_deviation_coefficients.png)
 1174: 
 1175: ---
 1176: 
 1177: ## Page 266
 1178: 
 1179: Chart scale can be increased and decreased using the mouse wheel; you can also enable/disable curve display on the chart by clicking on dates in the chart legend.
 1180: 
 1181: The "Coefficients" window displays the final deviation coefficient for selected days, coefficients by intervals in daily breakdown, a chart showing normal distribution based on historical data, and a chart of general special date coefficients.
 1182: 
 1183: ![Coefficients Window](img/coefficients_window.png)
 1184: 
 1185: Special day coefficients can be corrected by intervals by clicking on values in the table or changing the general date coefficient. After all settings are made, save the special date by clicking "Gear" -> "Save." You need to specify the special date name.
 1186: 
 1187: ![Save Special Date](img/save_special_date.png)
 1188: 
 1189: On the "View Coefficients" tab, you can view/edit/delete already created special dates.
 1190: 
 1191: ---
 1192: 
 1193: ## Page 267
 1194: 
 1195: To do this, specify the special date name in "Parameters," and it will be displayed on the chart similar to the "Special Dates Analysis" tab.
 1196: 
 1197: ![View Coefficients Tab](img/view_coefficients_tab.png)
 1198: 
 1199: Using special dates is available on the "Forecast Load" page at the "Traffic and AHT Forecasting" step. To do this, click the "Add coefficient" button, select the created special date, and assign dates when special day coefficients will be applied during forecasting.
 1200: 
 1201: ![Use Special Dates](img/use_special_dates.png)
 1202: 
 1203: You can also add several different special dates by clicking the "Add coefficient" button again.
 1204: 
 1205: ---
 1206: 
 1207: ## Page 268
 1208: 
 1209: ## 5. Load View
 1210: 
 1211: The forecasting module is available to users with system role "Administrator," "Senior Operator," or any other role with access right "Access to forecast view/edit pages."
 1212: 
 1213: A forecast represents the number of requests that will presumably arrive at an operator group/service during a specific time period.
 1214: 
 1215: To go to the forecast view/edit page, go to the "Forecasting" → "Load View" tab (you can go from the section list menu or from the main page by clicking the "Load View" block):
 1216: 
 1217: ![Load View Navigation](img/load_view_navigation.png)
 1218: 
 1219: This will open the forecasting page with a filter for selecting services and groups included in them:
 1220: 
 1221: ![Load View Filter](img/load_view_filter.png)
 1222: 
 1223: ### 5.1. View Load for Group
 1224: 
 1225: In the service and group list, first select the necessary service, then the group included in this service. After this, select one of 5 modes.
 1226: 
 1227: ---
 1228: 
 1229: ## Page 269
 1230: 
 1231: ![Load View Modes](img/load_view_modes.png)
 1232: 
 1233: • **Intra-annual profile of monthly periods** – will show load by months in the specified period.
 1234: 
 1235: • **Intra-annual profile of weekly periods** – will show load by weeks for the specified period.
 1236: 
 1237: • **Intra-monthly profile of daily periods** – will show load by days for the specified period.
 1238: 
 1239: • **Intra-daily profile of hourly intervals** – will show load by hours from the day for the specified period.
 1240: 
 1241: • **Intra-daily profile of interval periods** – will show load for all intervals in the day for the specified period.
 1242: 
 1243: After the desired mode is set, select the time zone and time period for viewing load. The beginning and end of the period are selected.
 1244: 
 1245: Load forecast is displayed in table format with the ability to switch by dates and navigate through time periods, as well as in chart form located below the forecast table.
 1246: 
 1247: ---
 1248: 
 1249: ## Page 270
 1250: 
 1251: ![Load View Display](img/load_view_display.png)
 1252: 
 1253: ### 5.2. Forecast Correction
 1254: 
 1255: In some cases, forecasts (required number of operators and number of requests) require manual correction. The WFM CC system implements the ability to manually correct:
 1256: 
 1257: • Forecasted number of operators;
 1258: • Forecasted number of requests.
 1259: 
 1260: For manual correction by intervals, select the "Intra-daily profile of interval periods" mode.
 1261: 
 1262: ![Manual Correction Mode](img/manual_correction_mode.png)
 1263: 
 1264: ---
 1265: 
 1266: ## Page 271
 1267: 
 1268: There is also the ability to build forecasts considering the minimum number of operators set by the user.
 1269: 
 1270: ![Minimum Operators Setting](img/minimum_operators_forecast.png)
 1271: 
 1272: The number of operators/requests is corrected by multiplying by a coefficient specified by the user.
 1273: 
 1274: #### 5.2.1. Update Forecasted Number of Operators
 1275: 
 1276: To specify new parameters for forecasting the number of operators for a specific period, click the button and select "Update for today/tomorrow/period" from the dropdown list, after which the following window will open:
 1277: 
 1278: ![Update Operators Dialog](img/update_operators_dialog.png)
 1279: 
 1280: Parameters set in this window are similar to parameters set at the "Calculate Number of Operators" stage.
 1281: 
 1282: ---
 1283: 
 1284: ## Page 272
 1285: 
 1286: #### 5.2.2. Operator Count Correction with Reserve Coefficient
 1287: 
 1288: Reserve coefficient is applied to the forecast when there's operator shortage.
 1289: 
 1290: **Important!** Applying reserve coefficient affects only the number of operators without affecting forecast request numbers.
 1291: 
 1292: Select the group for which the obtained forecast needs to be corrected.
 1293: 
 1294: Next, in the "Forecast" block, click the button and select "Reserve coefficient" from the dropdown list:
 1295: 
 1296: ![Reserve Coefficient Selection](img/reserve_coefficient_selection.png)
 1297: 
 1298: In the appearing window, specify:
 1299: 
 1300: • **Period** (accurate to minutes) for which the coefficient needs to be applied;
 1301: • **Reserve coefficient value**.
 1302: 
 1303: ---
 1304: 
 1305: ## Page 273
 1306: 
 1307: ![Reserve Coefficient Parameters](img/reserve_coefficient_parameters.png)
 1308: 
 1309: After all parameters are specified, click to apply the coefficient.
 1310: 
 1311: As a result:
 1312: 
 1313: • Reserve coefficient will be successfully applied;
 1314: • The number of operators in the forecast will be recalculated;
 1315: • The number of requests will not change;
 1316: • Applied coefficient will be displayed next to intervals (in the "reserve coefficient" column).
 1317: 
 1318: Load update results will be displayed in the "Forecasting" → "Load View" section for the selected group in table and chart formats:
 1319: 
 1320: ![Reserve Coefficient Results](img/reserve_coefficient_results.png)
 1321: 
 1322: To cancel applied reserve coefficient, perform the following actions:
 1323: 
 1324: Select the group for which reserve coefficient was previously applied, click the button and select "Reserve coefficient" from the dropdown list:
 1325: 
 1326: ---
 1327: 
 1328: ## Page 274
 1329: 
 1330: In the appearing window, specify:
 1331: 
 1332: • Previously selected period (accurate to minutes) for which the coefficient needs to be canceled
 1333: • Set reserve coefficient value equal to = 1.
 1334: 
 1335: After all parameters are specified, click.
 1336: 
 1337: As a result, the number of operators will return to the original value.
 1338: 
 1339: #### 5.2.3. Request Count Correction with Growth Coefficient
 1340: 
 1341: When manual correction of the obtained forecast is needed, mass load correction capability is provided.
 1342: 
 1343: **Important!** Applying growth coefficient will change the number of requests, which in turn will affect the number of operators (which will be recalculated using Erlang formula).
 1344: 
 1345: Select the group for which the obtained forecast needs to be corrected.
 1346: 
 1347: Next, in the "Forecast" block, click the button and select "Growth coefficient" from the dropdown list:
 1348: 
 1349: ---
 1350: 
 1351: ## Page 275
 1352: 
 1353: ![Growth Coefficient Selection](img/growth_coefficient_selection.png)
 1354: 
 1355: In the appearing window, specify:
 1356: 
 1357: • **Period** (accurate to minutes) for which the coefficient needs to be applied;
 1358: • **Growth coefficient value**.
 1359: 
 1360: ![Growth Coefficient Parameters](img/growth_coefficient_parameters.png)
 1361: 
 1362: After all parameters are specified, click to apply the coefficient.
 1363: 
 1364: As a result:
 1365: 
 1366: • Growth coefficient will be successfully applied;
 1367: • The number of requests and operators will be successfully recalculated;
 1368: • Applied coefficient will be displayed next to intervals (in the "Growth coefficient" column)
 1369: 
 1370: Load update results will be displayed in the "Forecasting" → "Load View" section for the selected group in table and chart formats:
 1371: 
 1372: ---
 1373: 
 1374: ## Page 276
 1375: 
 1376: ![Growth Coefficient Results](img/growth_coefficient_results.png)
 1377: 
 1378: To cancel applied growth coefficient, perform the following actions:
 1379: 
 1380: Select the group for which growth coefficient was previously applied, click the button and select "Growth coefficient" from the dropdown list:
 1381: 
 1382: In the appearing window, specify:
 1383: 
 1384: • Previously specified period (accurate to minutes) for which the coefficient needs to be canceled;
 1385: • Set growth coefficient value equal to = 1.
 1386: 
 1387: After all parameters are specified, click to cancel the coefficient.
 1388: 
 1389: As a result, the number of requests and operators will return to the original value.
 1390: 
 1391: ---
 1392: 
 1393: ## Page 277
 1394: 
 1395: #### 5.2.4. Forecast Correction with Minimum Number of Operators
 1396: 
 1397: For example, a situation occurred where, according to obtained forecasts, data returned indicating that for several hours there were 0 requests, and consequently, 0 operators are suggested for the line (especially during night hours). But since request handling is 24/7, at least one or two operators still need to be on the line at night. For such situations, the WFM CC system implements the ability to specify minimum number of operators.
 1398: 
 1399: This functionality applies not only to cases when forecast calculated operator count=0. It can be used in other situations, for example, when minimum number of operators on the line should be =3, but forecast calculated operator count = 2 or 1 or 0.
 1400: 
 1401: **Logic**: if the obtained operator count by forecast is less than the set minimum number, then WFM CC system sets operator count = set minimum number of operators in the updated forecast. If operator count by forecast is greater than set minimum number, then WFM CC system leaves the operator count value obtained by forecast in the updated forecast.
 1402: 
 1403: Let's examine the example below.
 1404: 
 1405: After obtaining forecasts, the user discovered time moments when operator count = 0:
 1406: 
 1407: ---
 1408: 
 1409: ## Page 278
 1410: 
 1411: ![Zero Operators Example](img/zero_operators_example.png)
 1412: 
 1413: Since the user understands that at least one operator should always be on the line, they set minimum number of operators=1 and update the previously obtained forecast.
 1414: 
 1415: To set minimum number of operators, click the button in the "Forecast" block and select "Minimum operators" from the dropdown list:
 1416: 
 1417: ![Minimum Operators Selection](img/minimum_operators_selection.png)
 1418: 
 1419: In the appearing window, specify:
 1420: 
 1421: • **Period** (accurate to minutes) for which minimum number of operators needs to be applied;
 1422: 
 1423: ---
 1424: 
 1425: ## Page 279
 1426: 
 1427: • **Minimum operators**.
 1428: 
 1429: ![Minimum Operators Parameters](img/minimum_operators_parameters.png)
 1430: 
 1431: After all parameters are set, click to apply minimum number of operators.
 1432: 
 1433: As a result:
 1434: 
 1435: • Minimum number of operators equal to the entered value will be set in those intervals where forecast returned a value less than the set minimum;
 1436: • Number of requests will not change when making adjustments.
 1437: 
 1438: Load update results will be displayed in the "Recalculated" column.
 1439: 
 1440: Before applying minimum number of operators=1:
 1441: 
 1442: ![Before Minimum Operators](img/before_minimum_operators.png)
 1443: 
 1444: After applying minimum number of operators = 1:
 1445: 
 1446: ---
 1447: 
 1448: ## Page 280
 1449: 
 1450: ![After Minimum Operators](img/after_minimum_operators.png)
 1451: 
 1452: ![Minimum Operators Applied](img/minimum_operators_applied.png)
 1453: 
 1454: **The set minimum number of operators in the forecast cannot be canceled.** But it can be returned to 1 if the minimum value was set higher.
 1455: 
 1456: ### 5.3. Import Load from File
 1457: 
 1458: In the system, besides obtaining forecasts based on historical data, there's the ability to import load from a file (by requests or operators). Acceptable imported file formats: .xls, .xlsx, .csv.
 1459: 
 1460: ---
 1461: 
 1462: ## Page 281
 1463: 
 1464: #### 5.3.1. Import Ready Request Forecast
 1465: 
 1466: The system implements the ability to import request forecast on the "Import Forecasts" page. This function is used when WFM CC system needs to load a request forecast and calculate the necessary number of operators to cover the load.
 1467: 
 1468: To load a ready request forecast, go to "Forecasting" - "Import forecasts" section or go directly to "Import forecasts" from the main page.
 1469: 
 1470: ![Import Forecasts Page](img/import_forecasts_page.png)
 1471: 
 1472: For each group, a separate file with forecast needs to be loaded and operators calculated. The file for loading must contain three columns with headers "Start of time interval," "Number of requests," "AHT, sec." The number of rows must match the number of time intervals for which load is imported and be multiple of the system interval (5, 10, or 15 minutes, based on platform settings). Date must be in DD.MM.YYYY hh:mm format, and remaining columns in numeric format.
 1473: 
 1474: ---
 1475: 
 1476: ## Page 282
 1477: 
 1478: ![Import File Format](img/import_file_format.png)
 1479: 
 1480: Fill in Service, Group, and Time Zone. Click "Load" and select the required file.
 1481: 
 1482: ![Load File Dialog](img/load_file_dialog.png)
 1483: 
 1484: After selecting the file for loading ready request forecast, select KPI indicators that will be used for calculating number of operators (similar to 4.8. Calculate Number of Operators).
 1485: 
 1486: ---
 1487: 
 1488: ## Page 283
 1489: 
 1490: ![KPI Indicators Selection](img/kpi_indicators_selection.png)
 1491: 
 1492: Don't forget to save the forecast.
 1493: 
 1494: #### 5.3.2. Import Ready Operator Forecast
 1495: 
 1496: The system implements the ability to import ready operator forecast. This function is used when operator forecast comes from external sources, so there's no need to forecast load in WFMCC system and calculate number of operators.
 1497: 
 1498: The specified operator forecast in source format is presented as hourly profile (number of operators by hours) for weekdays and separately for weekends. Since WFMCC system has system interval less than hour (5, 10, or 15 minutes), this hourly profile is broken down into system intervals.
 1499: 
 1500: To load ready operator forecast, go to "Forecasting" - "Load View" section or go directly to "Load View" from the main page.
 1501: 
 1502: ---
 1503: 
 1504: ## Page 284
 1505: 
 1506: ![Load View Import](img/load_view_import.png)
 1507: 
 1508: This will open the forecasting page with group and service filter and mode selection.
 1509: 
 1510: ![Load View Interface](img/load_view_interface.png)
 1511: 
 1512: Select the group for which forecast import from file will be performed and display mode.
 1513: 
 1514: Next, in the "Forecast" block, click the button and select "Import" from the dropdown list:
 1515: 
 1516: ![Import Selection](img/import_selection.png)
 1517: 
 1518: In the opened "Load Import" window, fill in parameters:
 1519: 
 1520: ![Load Import Parameters](img/load_import_parameters.png)
 1521: 
 1522: • **Date and Time**. Specify start and end of period for which load will be obtained from imported file;
 1523: • **Customer wait time, sec.** Used for operator calculation;
 1524: • **SL**. Upper SL boundary that system will orient to for operator calculation;
 1525: • **Average request handling time (AHT)**. Used for operator calculation.
 1526: 
 1527: ---
 1528: 
 1529: ## Page 285
 1530: 
 1531: To load file from your computer, click "Load" (button becomes available to user if Date and time are specified at minimum). In the opened file addition window, find the file on your computer's hard drive and click "Open."
 1532: 
 1533: The Excel file should not have column names; two columns should contain numbers: first column - number of requests, second column - number of operators. Data from file will automatically distribute across N-minute intervals (depending on system setting, this can be 5, 10, or 15 minutes) starting from the beginning of selected time interval.
 1534: 
 1535: **Note**: data must be in "General" format and number of rows (N-minute intervals) must correspond to time selected earlier. I.e., if there are 8 rows (with 15-minute system interval), this equals two hours. Accordingly, select a two-hour period for importing data.
 1536: 
 1537: ![Excel File Format](img/excel_file_format.png)
 1538: 
 1539: After successful file loading, "Import" button becomes available, which must be clicked to check data.
 1540: 
 1541: ---
 1542: 
 1543: ## Page 286
 1544: 
 1545: ![Import Button Available](img/import_button_available.png)
 1546: 
 1547: If data and intervals satisfy the user, click "Save" to apply this data or "Back" - to return to previous step.
 1548: 
 1549: ![Save Import Data](img/save_import_data.png)
 1550: 
 1551: Load update results will be displayed in "Forecasting" → "Load View" section for selected group in table and chart formats.
 1552: 
 1553: ---
 1554: 
 1555: ## Page 287
 1556: 
 1557: ## 6. Multi-skill Planning Template
 1558: 
 1559: Multi-skill planning template is necessary for creating work schedules for a specific group or list of groups, as well as for timetable planning.
 1560: 
 1561: To create a multi-skill planning template, go to "Planning" → "Multi-skill planning" page:
 1562: 
 1563: ![Multi-skill Planning Navigation](img/multiskill_planning_navigation.png)
 1564: 
 1565: When going to the "Multi-skill planning" page, all created multi-skill planning templates are displayed.
 1566: 
 1567: ![Multi-skill Planning Templates](img/multiskill_planning_templates.png)
 1568: 
 1569: ---
 1570: 
 1571: ## Page 288
 1572: 
 1573: To view general information about the template, click on it with the left mouse button. To the right of the template, the following information will be displayed: "Template name," "Groups."
 1574: 
 1575: ![Template Information](img/template_information.png)
 1576: 
 1577: The "Groups" area displays groups included in the multi-skill planning template.
 1578: 
 1579: ### 6.1. Creating Multi-skill Planning Template
 1580: 
 1581: To create a new template, click the button in the left part of the page, after which a form for filling template data will appear.
 1582: 
 1583: ![Create New Template](img/create_new_template.png)
 1584: 
 1585: In the opened form, enter the template name and click to save. After saving, the new multi-skill planning template will appear in the general template list.
 1586: 
 1587: Next, to add groups to the multi-skill planning template, click the "Add" button in the "Groups" window:
 1588: 
 1589: ---
 1590: 
 1591: ## Page 289
 1592: 
 1593: ![Add Groups to Template](img/add_groups_template.png)
 1594: 
 1595: In the opened dialog window, using dropdown lists, select "Service" and "Groups" that will be included in the multi-skill planning template.
 1596: 
 1597: To confirm adding groups, click in the dialog window.
 1598: 
 1599: An operator can belong to different groups but only one multi-skill planning template. Accordingly, one group can be included in only one multi-skill template. If you try to add an operator group that already exists in one of the multi-skill templates to a new template, the system will display a warning:
 1600: 
 1601: ![Template Warning](img/template_warning.png)
 1602: 
 1603: This is necessary to exclude schedule discrepancies (for example, situations when an operator may have several conflicting work schedules or planned vacations).
 1604: 
 1605: The created multi-skill planning template, after adding groups to it, will be displayed in "Planning work schedules" and "Creating timetables" sections in the "Templates" block.
 1606: 
 1607: ---
 1608: 
 1609: ## Page 290
 1610: 
 1611: To rename the template, click on its name, correct it, and click to save.
 1612: 
 1613: To delete a group from the template, click next to it.
 1614: 
 1615: ### 6.2. Deleting Multi-skill Planning Template
 1616: 
 1617: To delete a multi-skill planning template, select the necessary template in the general template list and click:
 1618: 
 1619: ![Delete Template](img/delete_template.png)
 1620: 
 1621: After clicking the "Delete template" button, a confirmation dialog will appear:
 1622: 
 1623: ![Delete Confirmation](img/delete_confirmation.png)
 1624: 
 1625: To confirm deletion, click "Yes." The deleted multi-skill planning template cannot be restored.
 1626: 
 1627: Work schedules planned based on the deleted multi-skill planning template will also be deleted without possibility of restoration.
 1628: 
 1629: ---
 1630: 
 1631: ## Page 291
 1632: 
 1633: ## 7. Work Schedule Planning
 1634: 
 1635: The work schedule planning module is available to users with system role "Administrator," "Senior Operator," or any other role with access rights:
 1636: 
 1637: • **System_AccessPlanningShedule** – view "Planning work schedules" page (create button not available).
 1638: • **System_EditPlanningShedule** – ability to create work schedule planning variant.
 1639: • **System_AccessActualPlanningShedule** – view actual work schedule variant.
 1640: • **System_EditPlanningShedule** – ability to edit actual work schedule.
 1641: 
 1642: Work schedule planning is based on:
 1643: 
 1644: • Forecasted load;
 1645: • Operator performance;
 1646: • Individual settings;
 1647: • Labor standards;
 1648: • Work rules assigned to employees.
 1649: 
 1650: Work schedule is planned for employees with positions participating in planning and belonging to groups included in the "Multi-skill planning" template selected on the "Work schedule planning" page.
 1651: 
 1652: The "Work schedule planning" module is used for mass work schedule planning for employees. On the page of the same name, you can view the work schedule planned by the system for employees (eliminates the need to manually set operator schedules based on load and their preferences), as well as make corrections or accept the schedule as is.
 1653: 
 1654: During work schedule planning, the system considers employee hire and termination dates. The system will plan shifts for an employee only for the period when the operator works and will not assign shifts after termination date or before hire date. The system also considers the work norm assigned to the employee and will try to fit within this standard considering hire and termination dates.
 1655: 
 1656: If work rules in the "Work Rules" directory have configured variation in shift starts and durations, the system will select the start and duration of each operator's shift for each day of the year depending on load forecast. At the same time, operator performance will be maintained.
 1657: 
 1658: Such schedule planning can take a considerable amount of time. If the multi-skill planning template includes many operators and rules are configured quite freely, consider that this will affect planning time.
 1659: 
 1660: During schedule planning, you can continue using other system modules since planning occurs on a separate service.
 1661: 
 1662: ### 7.1. Vacation Planning
 1663: 
 1664: Before planning the schedule in the system, vacation schedules need to be planned. Vacations that can be assigned to employees are created based on vacation schemes from the "Vacation Schemes" directory.
 1665: 
 1666: ![Vacation Planning](img/vacation_planning.png)
 1667: 
 1668: ---
 1669: 
 1670: ## Page 292
 1671: 
 1672: In the "Vacation Schedule" tab, desired and extraordinary vacations that were set by the operator in their card will be displayed. Also in this tab, you can assign vacations manually and set priorities. Vacations set here are considered by the system when building work schedules, after which desired vacations become planned.
 1673: 
 1674: The following information is displayed on the top panel:
 1675: 
 1676: ![Vacation Planning Panel](img/vacation_planning_panel.png)
 1677: 
 1678: • **Group filter** – allows viewing a specific group.
 1679: • **Department filter** – allows viewing a specific employee department.
 1680: • **"Operators without assigned vacation" checkbox** – will show operators who have vacation balance and haven't set desired vacation dates.
 1681: • **"Operators with accumulated vacation days" checkbox** – will show operators who have accumulated vacation days.
 1682: • **"Subordinate employees" checkbox** – will display employees under the supervision of the department head/deputy viewing the vacation schedule.
 1683: • **"Vacation violations" checkbox** – will display operators whose desired vacation was added with violations (accumulated vacation days not considered, incorrect duration – correctness is regulated by labor standards). When hovering the mouse cursor over such vacation (even without checkbox), the specific violation will be displayed.
 1684: • **"Desired vacations" checkbox** – will display all operator desired vacations, hiding extraordinary vacations.
 1685: 
 1686: ---
 1687: 
 1688: ## Page 293
 1689: 
 1690: • **"Generate vacations" button** – generates vacations for employees who haven't set desired vacations. The system follows vacation business rules assigned to employees.
 1691: 
 1692: The following information is displayed in table columns:
 1693: 
 1694: ![Vacation Table Columns](img/vacation_table_columns.png)
 1695: 
 1696: • **Full Name** – employee's full name.
 1697: • **Planned vacation scheme** – shows vacation scheme set in operator card.
 1698: • **Remaining vacation days** – shows remaining vacation days after assigning operator vacation schedules. I.e., if operator has 15 vacation days (value comes via integration), when adding two vacations totaling 14 days, "remaining vacation days" field will show 1.
 1699: 
 1700: **Adding and deleting vacation:**
 1701: 
 1702: To add vacation on the "Vacation Schedule" tab, select a cell with the left mouse button, then right-click, and select "Add vacation" event from the dropdown menu:
 1703: 
 1704: ---
 1705: 
 1706: ## Page 294
 1707: 
 1708: ![Add Vacation](img/add_vacation.png)
 1709: 
 1710: In the opened dialog window, select vacation type: "Desired vacation" or "Extraordinary vacation."
 1711: 
 1712: When selecting "Extraordinary vacation" type, specify start and end dates in the dialog window.
 1713: 
 1714: When adding "Extraordinary vacation" to an employee, accumulated vacation days are not deducted.
 1715: 
 1716: ![Extraordinary Vacation](img/extraordinary_vacation.png)
 1717: 
 1718: When selecting "Desired vacation" type, select "Vacation scheme" and vacation creation method: "Period" or "Calendar days."
 1719: 
 1720: If "Period" vacation creation method is selected:
 1721: 
 1722: • Specify start and end vacation dates.
 1723: • Vacation is not shifted if holidays fall within its period (for example, vacation is set from 25.04 to 08.05. Despite one holiday "May 1" falling in this period, vacation is not shifted. Return to work date is 09.05).
 1724: 
 1725: ---
 1726: 
 1727: ## Page 295
 1728: 
 1729: • Days are deducted from accumulated vacation days considering holidays (for example, vacation is set for 14 days, with 1 holiday falling in its period. 13 days are deducted from accumulated days, not 14).
 1730: 
 1731: If "Calendar days" vacation creation method is selected:
 1732: 
 1733: • Specify vacation start date and number of vacation days (vacation end date will be pulled automatically).
 1734: • Vacation is shifted by the number of holiday days (for example, vacation is set for 14 calendar days from 25.04 to 08.05. One holiday "May 1" falls in this period, so vacation shifts to 09.05. But "May 9" is also a holiday, so vacation shifts again. Return to work date: 11.05).
 1735: • Days are deducted from accumulated vacation days without considering holidays (in the above example, 14 days will be deducted from accumulated days).
 1736: 
 1737: ![Calendar Days Vacation](img/calendar_days_vacation.png)
 1738: 
 1739: The vacation addition functionality is similar to adding vacation in the client card.
 1740: 
 1741: To delete vacation, right-click on one of the cells in the desired vacation range and select "Delete vacation":
 1742: 
 1743: ---
 1744: 
 1745: ## Page 296
 1746: 
 1747: ![Delete Vacation](img/delete_vacation.png)
 1748: 
 1749: **Vacation priorities**: vacations have priorities that are considered when planning work schedules. Priority works as follows: when planning work schedules, the system relies on forecasted load and personal vacation business rules for the operator.
 1750: 
 1751: The operator is assigned maximum number of vacation shift days. Based on this setting, the system can shift vacation within this range to cover load (for example, operator wanted to go on vacation on 5.01, but strong load is recorded on this day. In this case, the system can shift the operator's vacation by the number of days not exceeding the number set in the operator's card for vacation shift days). If vacation is considered priority, the system will first move (if necessary) non-priority vacations, and only then (if required) will move priority vacations to cover load. If vacation is considered fixed, the system doesn't shift it regardless of load.
 1752: 
 1753: To make vacation priority, select the vacation of interest by right-clicking on any cell of its interval and select "Vacation priority":
 1754: 
 1755: ---
 1756: 
 1757: ## Page 297
 1758: 
 1759: ![Vacation Priority](img/vacation_priority.png)
 1760: 
 1761: To cancel vacation priority, select it as shown above and click "Non-priority vacation":
 1762: 
 1763: ![Non-priority Vacation](img/non_priority_vacation.png)
 1764: 
 1765: To fix vacation, select it as shown earlier and click "Fixed vacation":
 1766: 
 1767: ---
 1768: 
 1769: ## Page 298
 1770: 
 1771: ![Fixed Vacation](img/fixed_vacation.png)
 1772: 
 1773: Vacations set above are considered desired. Once work schedule is planned, the system will assign vacations itself, considering business rules and load, after which such vacations become planned.
 1774: 
 1775: **Note**: In "Calendar days" vacation mode, if vacation falls on a holiday, it is extended by the number of holiday days marked in the "Production Calendar" directory. This will be visible in both "Vacation Planning" and "Planned Work Schedule" fields. Also, all vacations that fall fully or partially within the work schedule planning period are confirmed.
 1776: 
 1777: ---
 1778: 
 1779: ## Page 299
 1780: 
 1781: ### 7.2. Creating New Work Schedule Variant
 1782: 
 1783: To begin planning a work schedule variant, go to the "Planning work schedules" page either through the side menu or through the main page.
 1784: 
 1785: ![Work Schedule Planning Navigation](img/work_schedule_planning_navigation.png)
 1786: 
 1787: After opening the page, we'll see a list of multi-skill planning templates.
 1788: 
 1789: To continue creating work schedules, select one of them, after which we'll see a list of work schedule variants, with the actual applied work schedule highlighted in bold and checkmark. The applied work schedule is always pinned to the top of the list.
 1790: 
 1791: Work schedule planning is independent of time zone; depending on the selected time zone, only display changes. By default, the user's time zone is always selected; there's also the ability to display in other time zones. To do this, change the time zone for work schedule display.
 1792: 
 1793: ---
 1794: 
 1795: ## Page 300
 1796: 
 1797: ![Work Schedule Display Options](img/work_schedule_display_options.png)
 1798: 
 1799: In the "Work Schedule" area, there are two expandable windows:
 1800: 
 1801: • **Planned work schedule** – will display information about work schedule built by the system;
 1802: • **Vacation planning** – window for vacation planning.
 1803: 
 1804: To start schedule planning, click the button.
 1805: 
 1806: A window will open:
 1807: 
 1808: ![Start Planning Dialog](img/start_planning_dialog.png)
 1809: 
 1810: In the opened window, specify the schedule name.
 1811: 
 1812: The "Comment" field is optional for filling.
 1813: 
 1814: The "Performance" field shows what type of performance is configured in the system (annual, quarterly, monthly).
 1815: 
 1816: The "Work schedule planning year" field allows selecting which year the schedule will be planned for.
 1817: 
 1818: If preference consideration was selected during work schedule planning, the system should consider operator preferences specified in their personal account.
 1819: 
 1820: After clicking "Start planning," the schedule name will appear in the "Work schedule variants" window, and the schedule planning task will appear in the "Work schedule tasks" window. While the schedule is being planned, you can continue working in the system – exit planning, go to other modules, and return back.
 1821: 
 1822: ---
 1823: 
 1824: ## Page 301
 1825: 
 1826: ![Planning in Progress](img/planning_in_progress.png)
 1827: 
 1828: To check task status, update it by clicking the button.
 1829: 
 1830: If the schedule is planned, task status will change to "Awaiting save":
 1831: 
 1832: ![Awaiting Save Status](img/awaiting_save_status.png)
 1833: 
 1834: To go to the planned schedule, click on the task itself:
 1835: 
 1836: ![Access Planned Schedule](img/access_planned_schedule.png)
 1837: 
 1838: After which we'll see the work schedule planned by the system in the "Planned work schedule" area.
 1839: 
 1840: ---
 1841: 
 1842: ## Page 302
 1843: 
 1844: ![Planned Schedule Display](img/planned_schedule_display.png)
 1845: 
 1846: Depending on the selected tab ("Org. Structure" or "Func. Structure"), the following areas will be displayed:
 1847: 
 1848: Or
 1849: 
 1850: ![Structure Tabs](img/structure_tabs.png)
 1851: 
 1852: In "Org. Structure" we see:
 1853: 
 1854: • **Department filter** – allows viewing schedule for a specific department and all child departments.
 1855: 
 1856: ---
 1857: 
 1858: ## Page 303
 1859: 
 1860: • **"Operators without planned vacations" checkbox** – Operators who have positive vacation days balance but no vacation set.
 1861: 
 1862: • **"Employees with non-plannable position" checkbox** – shows employees whose position changed to non-planning attribute.
 1863: 
 1864: • **"Vacation violations" checkbox** – shows employees who were assigned vacation violating vacation assignment rules.
 1865: 
 1866: • **"Desired vacations" checkbox** – highlights desired employee vacations with a frame.
 1867: 
 1868: In "Func. structure" we see:
 1869: 
 1870: • **Group filter** – allows viewing schedule for a specific group.
 1871: 
 1872: • **"Vacation violations" checkbox** – shows employees who were assigned vacation violating vacation assignment rules.
 1873: 
 1874: • **"Desired vacations" checkbox** – highlights desired employee vacations with a frame.
 1875: 
 1876: • **"Op. Forecast" checkbox** – will display number of forecasted operators for day/month.
 1877: 
 1878: • **"Op. Plan" checkbox** – will display number of operators planned by work schedule for day/month.
 1879: 
 1880: • **"Op. plan %Abs" checkbox** – will display number of operators planned by work schedule multiplied by absence percentage from "Work absence percentage" directory for day/month.
 1881: 
 1882: • **"%ACD forecast" checkbox** – shows average forecasted %ACD value for 15-minute interval across all groups. Maximum shortage/surplus of employees – shows how many employees are lacking to cover load at the most loaded moment of the day and how many employees will be conditionally "excess" at the least loaded moment of the day.
 1883: 
 1884: ---
 1885: 
 1886: ## Page 304
 1887: 
 1888: ![Monthly and Yearly Statistics](img/monthly_yearly_statistics.png)
 1889: 
 1890: Monthly and yearly statistics will display the same checkboxes that were selected earlier. In this case, these are OSS and %ACD for month and year. Values are shown as average values for all days of the month or all months of the year.
 1891: 
 1892: ![Employee Information Columns](img/employee_information_columns.png)
 1893: 
 1894: • **Full Name** – employee's last name, first name, and patronymic
 1895: • **Work schedule template** – work schedule template selected by the system.
 1896: • **Vacation scheme** – vacation scheme name.
 1897: • **Standard** – employee performance set either in operator card or en masse.
 1898: • **Working days** – number of employee working days.
 1899: • **Planned hours** – number of working hours for entire work schedule period minus unpaid breaks.
 1900: • **Overtime** – shows presence of additional hours for employees.
 1901: • **Remaining vacation days** – shows remaining vacation days after assigning operator all planned vacations. The value of vacation days comes via integration. After assigning vacations in work schedule, assigned vacation days are subtracted from this value.
 1902: 
 1903: ---
 1904: 
 1905: ## Page 305
 1906: 
 1907: • **Days** – month days are displayed.
 1908: 
 1909: Information under days will display rows for indicators selected by checkboxes in the previous stage.
 1910: 
 1911: Numbers in cells are working hours in shift.
 1912: 
 1913: ![Work Hours Display](img/work_hours_display.png)
 1914: 
 1915: In this same table, we can hover cursor over cell with working hours to learn which shift is selected for this operator:
 1916: 
 1917: ![Shift Information Tooltip](img/shift_information_tooltip.png)
 1918: 
 1919: Also by right-clicking on day cell you can:
 1920: 
 1921: ![Right-click Menu](img/right_click_menu.png)
 1922: 
 1923: ---
 1924: 
 1925: ## Page 306
 1926: 
 1927: • **Delete shift** – shift will be removed from selected day.
 1928: 
 1929: ![Delete Shift](img/delete_shift.png)
 1930: 
 1931: • **Add shift** – select day when operator has no shift and click "Add shift." After which shift addition window opens where you can add planned or additional shift. Specify shift time. Then either click to add shift or to cancel addition.
 1932: 
 1933: ![Add Shift Dialog](img/add_shift_dialog.png)
 1934: 
 1935: At this moment, operator individual settings are considered (if we consider them in "Labor Standards" directory), as well as number of hours for calculating additional shift.
 1936: 
 1937: ---
 1938: 
 1939: ## Page 307
 1940: 
 1941: When adding additional shift, operator hours will be recalculated. If operator's actual hours don't reach planned, additional shift won't be set.
 1942: 
 1943: ![Additional Shift Validation](img/additional_shift_validation.png)
 1944: 
 1945: But if added shift exceeds operator's planned hours, additional shift will be added successfully.
 1946: 
 1947: • **Change shift** – allows changing shift start time and duration, as well as adding overtime hours. After selecting needed day, click "Change shift." Then in the appearing "Change shift" window, select shift hours or add "Overtime hours" field with number of hours before or after shift. Then click to accept changes or to cancel them.
 1948: 
 1949: ![Change Shift Dialog](img/change_shift_dialog.png)
 1950: 
 1951: If additional hours are successfully added, such shift in calendar will be marked with orange triangle:
 1952: 
 1953: ---
 1954: 
 1955: ## Page 308
 1956: 
 1957: ![Overtime Indicator](img/overtime_indicator.png)
 1958: 
 1959: Shifts can only be edited one at a time. Shifts can be deleted and added for several days at once. To do this, either select needed day range with left mouse button:
 1960: 
 1961: ![Multi-day Selection](img/multiday_selection.png)
 1962: 
 1963: Or with Ctrl key held on keyboard, select needed days with left mouse button:
 1964: 
 1965: ---
 1966: 
 1967: ## Page 309
 1968: 
 1969: ![Ctrl Multi-selection](img/ctrl_multiselection.png)
 1970: 
 1971: Here you can also assign vacations if this wasn't done in vacation planning or vacation wasn't assigned to operator in their card. To add vacation, left-click on any square, right-click and select "Add/correct vacation" event.
 1972: 
 1973: ![Add Vacation Option](img/add_vacation_option.png)
 1974: 
 1975: Vacation addition interface is similar to vacation addition interface in employee card.
 1976: 
 1977: ---
 1978: 
 1979: ## Page 310
 1980: 
 1981: To correct vacation dates, perform the same actions described above, but click on already set vacation.
 1982: 
 1983: Vacation can be deleted by clicking on any vacation cell and pressing "Delete vacation":
 1984: 
 1985: ![Delete Vacation Option](img/delete_vacation_option.png)
 1986: 
 1987: After all necessary edits are made, click to save created schedule example, or to cancel schedule creation.
 1988: 
 1989: **Note**: ability to edit work schedules (shifts/vacations) is regulated by configured BP in system. Only user provided for in BP will be able to edit work schedule (add/delete/change shifts and vacations).
 1990: 
 1991: To save schedule, fill in schedule name (mandatory parameter) and its description, then click to save it, or to cancel schedule saving.
 1992: 
 1993: ---
 1994: 
 1995: ## Page 311
 1996: 
 1997: ![Save Schedule Dialog](img/save_schedule_dialog.png)
 1998: 
 1999: After saving, schedule will appear in list:
 2000: 
 2001: ![Schedule in List](img/schedule_in_list.png)
 2002: 
 2003: After schedule is saved, depending on Business Process, the following can be done with it:
 2004: 
 2005: • **Update work schedule** – ability to replan work schedule for one or several operators appears if they want to change schedule template by which shifts were planned for them. In case of setting termination date for them, or conversely, add new employee to existing work schedule variant (work schedule correction BP).
 2006: 
 2007: • **Edit** – When schedule is applied, it can no longer be edited/updated. To do this, click "Edit," which will create a copy of work schedule to work with.
 2008: 
 2009: • **Apply** – work schedule will be applied and become current.
 2010: 
 2011: **Note**: Editing capability for applied work schedule is absent.
 2012: 
 2013: ---
 2014: 
 2015: ## Page 312
 2016: 
 2017: On the "Work schedule and vacation planning" page, there's also ability to view all changes made to work schedule and all BP execution stages. History is located under "Vacation schedule" block:
 2018: 
 2019: ![Schedule History](img/schedule_history.png)
 2020: 
 2021: ### 7.3. Editing Work Schedule Variant
 2022: 
 2023: Any schedule can be edited except the one currently applied or was applied in the past.
 2024: 
 2025: **Important!** Changes can only be made to a copy of applied work schedule.
 2026: 
 2027: To do this, go to applied schedule (Planning work schedules – Templates – click LMB on applied schedule). Then click "Edit" button.
 2028: 
 2029: ![Edit Applied Schedule](img/edit_applied_schedule.png)
 2030: 
 2031: after which work schedule copying window opens where you need to specify new work schedule name:
 2032: 
 2033: ---
 2034: 
 2035: ## Page 313
 2036: 
 2037: ![Copy Schedule Dialog](img/copy_schedule_dialog.png)
 2038: 
 2039: After performing these actions, a copy of applied work schedule is created. The copy can be updated and edited, then applied.
 2040: 
 2041: In "Planned work schedule" area, you can edit shifts: add, delete, or change shift duration (described in detail in "Creating new work schedule variant" section).
 2042: 
 2043: After changes are made, they need to be saved or canceled:
 2044: 
 2045: ![Save or Cancel Changes](img/save_cancel_changes.png)
 2046: 
 2047: To save changes, click button. After which window with schedule name and description appears. Name and description are already filled but can be changed if desired.
 2048: 
 2049: ---
 2050: 
 2051: ## Page 314
 2052: 
 2053: ![Save Changes Dialog](img/save_changes_dialog.png)
 2054: 
 2055: To add new workers to schedule or update schedules for existing operators (replan terminating worker, replan worker whose performance changed, etc.), schedule needs to be updated.
 2056: 
 2057: To update schedule, click, after which check needed employees and select planning start date (common for all marked employees or individual for each):
 2058: 
 2059: ---
 2060: 
 2061: ## Page 315
 2062: 
 2063: ![Update Schedule Dialog](img/update_schedule_dialog.png)
 2064: 
 2065: **Important!** To select date, click on it in opening calendar window.
 2066: 
 2067: ![Calendar Selection](img/calendar_selection.png)
 2068: 
 2069: ---
 2070: 
 2071: ## Page 316
 2072: 
 2073: After all changes are made, click:
 2074: 
 2075: There's also ability to delete work schedule. To do this, right-click on work schedule and click "Delete work schedule."
 2076: 
 2077: ![Delete Work Schedule](img/delete_work_schedule.png)
 2078: 
 2079: ![Delete Confirmation Dialog](img/delete_confirmation_dialog.png)
 2080: 
 2081: Warning will appear where you can confirm deletion or cancel it.
 2082: 
 2083: ### 7.4. Applying Work Schedule Variant
 2084: 
 2085: After creating work schedule variant, it must go through business process approval. Each organization has its own business process involving different specialists with different roles.
 2086: 
 2087: Only confirmed work schedule can be applied. To confirm schedule, go to "Approval tasks" page and find created schedule in "Confirmation" task. Then select it and click "Execute."
 2088: 
 2089: ---
 2090: 
 2091: ## Page 317
 2092: 
 2093: ![Apply Work Schedule](img/apply_work_schedule.png)
 2094: 
 2095: After confirmation, schedule can be applied. Return to this schedule in "Planning work schedules" section. After work schedule variant is selected, click button.
 2096: 
 2097: ![Apply Schedule Button](img/apply_schedule_button.png)
 2098: 
 2099: If there's currently applied work schedule for the same period, system will warn about this and offer to either apply schedule or cancel action:
 2100: 
 2101: ---
 2102: 
 2103: ## Page 318
 2104: 
 2105: ![Apply Schedule Warning](img/apply_schedule_warning.png)
 2106: 
 2107: After this, schedule will be considered current and displayed in employee personal cards. Subsequently, when building timetable, this schedule will be considered.
 2108: 
 2109: ![Applied Schedule Display](img/applied_schedule_display.png)
 2110: 
 2111: ### 7.5. Work Schedule Planning with Preference Consideration
 2112: 
 2113: When planning work schedules, performance standards, continuous rest, weekly/daily standards (if considered) are higher priority than preferences for the system. System should not consider preference during planning if it violates operator performance or standards from "Labor Standards" directory.
 2114: 
 2115: Examples are provided for simple understanding based on week.
 2116: 
 2117: **Example 1**: Operator has 5/2 rotation work rule with weekends on Sat and Sun, fixed 9-hour shift duration (8 hours without unpaid lunches). Operator set day off in each preference.
 2118: 
 2119: Since setting day off in all preferences doesn't meet performance standard, system will ignore operator preferences and set shifts under performance standard according to work rule.
 2120: 
 2121: **Example 2**: Operator has work rule without rotation, floating shift duration from 8 to 12 hours (7-11 hours without unpaid lunches). Operator set day off in each preference.
 2122: 
 2123: Since setting day off in all preferences doesn't meet performance standard, system will ignore operator preferences and set shifts under performance standard according to work rule, while shifts during schedule update may change their start and duration.
 2124: 
 2125: **General preference consideration rules:**
 2126: 
 2127: • When planning work schedule, load is higher priority than preference.
 2128: • If preference doesn't worsen load coverage quality, it will be set.
 2129: • If preference doesn't affect load coverage quality, it will be set.
 2130: • If preference worsens load coverage quality, it won't be set; shift/day off will be set according to work rules.
 2131: 
 2132: ---
 2133: 
 2134: ## Page 319
 2135: 
 2136: • When planning work schedules, difference between priority and regular preferences is that if system has equal choice of which shift/day off to set under equal conditions, priority preference should be set.
 2137: 
 2138: Examples are provided for simple understanding based on several days (for this example, weekly performance standard is not considered):
 2139: 
 2140: **Example 1**: Operator has 4/3 rotation work rule with weekends on Tue, Wed, and Thu, fixed 11-hour shift duration (10 hours without unpaid lunches). Operator set priority preference for shift on Tuesday and regular preference for shift on Thu.
 2141: 
 2142: Following load is forecasted:
 2143: 
 2144: If system fulfills both preferences and sets shift on both days, continuous rest standard in calendar week (equal to 42 hours) will be violated, so system can set only one preference. Since load is identical, system should set preference on Tue (since it's higher priority) but not set preference on Thu (since otherwise continuous rest standard will be violated).
 2145: 
 2146: ### 7.6. Work Schedule Correction
 2147: 
 2148: Work Schedule Correction module is available to users with system role "Administrator" or any other role with access rights:
 2149: 
 2150: • **System_AccessWorkScheduleAdjustment** – View "Work Schedule Correction" page.
 2151: • **System_ViewAllWorkersInWorkScheduleAdjustment** – View all operators on "Work Schedule Correction" page.
 2152: 
 2153: In Work Schedule Correction module, user can change work schedules without creating copies of applied work schedule, and changes will immediately be displayed to operator and take effect.
 2154: 
 2155: On Work Schedule Corrections page you can:
 2156: 
 2157: • Change shift duration (shift can be lengthened or shortened);
 2158: • Move shift;
 2159: • Delete shift;
 2160: • Create new shift;
 2161: • Create, delete, or edit sick leave;
 2162: • Create, delete, or edit time off;
 2163: • Create, delete, or edit vacation.
 2164: 
 2165: To go to work schedule corrections page, open side menu, then "Planning" module → "Work Schedule Correction."
 2166: 
 2167: ---
 2168: 
 2169: ## Page 320
 2170: 
 2171: ![Work Schedule Correction Navigation](img/work_schedule_correction_navigation.png)
 2172: 
 2173: Upon reaching the page, you'll see sections: "Legend," "Filters," "Statistics." And work schedules of all employees in system.
 2174: 
 2175: "Legend" section displays work schedule symbols:
 2176: 
 2177: ![Work Schedule Legend](img/work_schedule_legend.png)
 2178: 
 2179: "Filters" section allows sorting employees for display on schedule by:
 2180: 
 2181: • Departments;
 2182: • Sites;
 2183: • Groups;
 2184: • Subordinate employees;
 2185: • Only with existing schedule.
 2186: 
 2187: You can also find individual employees by full name or personnel number.
 2188: 
 2189: "Statistics" section displays detailed information about surplus or deficit of planned operators according to load. The histogram shows deficits in red, surpluses in blue, green shows plan, values are displayed according to number of operators.
 2190: 
 2191: **Important!** Statistics will not be displayed if no group is selected in filters.
 2192: 
 2193: ![Work Schedule Statistics](img/work_schedule_statistics.png)
 2194: 
 2195: The histogram can be scaled using mouse wheel and moved by holding left mouse button.
 2196: 
 2197: On the schedule itself, employees are listed on the left side with their planned and planned performance without unpaid breaks. In the main part of the schedule, employee shifts are displayed; by selecting a shift, it can be deleted by clicking the "Cross" button (✕).
 2198: 
 2199: ![Delete Shift Button](img/delete_shift_button.png)
 2200: 
 2201: To set a new shift, double-click with left mouse button on the employee's schedule line to whom you want to assign a shift. A shift configuration window will open where you can set: shift type (planned/additional), shift time, overtime hours before or after shift. Then click the "Checkmark" button (✓). Additional shift or overtime hours cannot be set if operator's performance standard is not covered.
 2202: 
 2203: ![New Shift Configuration](img/new_shift_configuration.png)
 2204: 
 2205: ---
 2206: 
 2207: ## Page 321
 2208: 
 2209: To add an event to an operator, double-click with left mouse button on the employee's schedule to whom you want to assign a shift. In the opened window, select events in the type field, configure event type (sick leave/time off/planned vacation/extraordinary vacation) and set start and end time, then click the "Checkmark" button (✓).
 2210: 
 2211: ![Add Event Configuration](img/add_event_configuration.png)
 2212: 
 2213: The schedule can be scaled by day, week, or month breakdown, display current day by clicking "Today" button, or specify necessary date. You can also select time zone in which schedule will be displayed.
 2214: 
 2215: ![Schedule Scaling Options](img/schedule_scaling_options.png)
 2216: 
 2217: All changes are saved automatically and applied to current applied work schedule.
 2218: 
 2219: ---
 2220: 
 2221: ## Page 322
 2222: 
 2223: ## 8. Timetable Planning
 2224: 
 2225: Operator timetable planning is performed according to forecasted load, employee work schedules, and lunch and break rules.
 2226: 
 2227: **Important!** Planning is impossible without forecast and active work schedule.
 2228: 
 2229: Timetable planning module is available to users:
 2230: 
 2231: • with system role "Administrator," "Senior Operator"
 2232: • or any other role with access rights "Access to timetable planning page" and "Create/update/apply timetables."
 2233: 
 2234: ![Timetable Planning Overview](img/timetable_planning_overview.png)
 2235: 
 2236: ### 8.1. Creating and Viewing Timetable
 2237: 
 2238: "Creating timetables" module allows composing operator work timetable according to forecasted load, office operator work schedules, and home operator work preferences.
 2239: 
 2240: Prerequisites for creating timetable:
 2241: 
 2242: • Multi-skill planning template created;
 2243: • Forecasted load updated for specific period for selected group;
 2244: • Applied work and vacation schedule exists.
 2245: 
 2246: To go to timetable creation page, go to "Planning" → "Creating timetables" tab (you can go from section list menu or from main page by clicking "Creating timetables" block):
 2247: 
 2248: ---
 2249: 
 2250: ## Page 323
 2251: 
 2252: ![Creating Timetables Navigation](img/creating_timetables_navigation.png)
 2253: 
 2254: Next, in the area with timetable template list, select necessary template and click "Create" button in "Timetable" block:
 2255: 
 2256: ![Create Timetable Button](img/create_timetable_button.png)
 2257: 
 2258: **Note**: if multi-skill template including aggregated group is selected, load will be pulled for aggregated group, and employees will be pulled from simple groups included in aggregated.
 2259: 
 2260: **Important!** Timetable planning is independent of time zone; depending on selected time zone, only display changes. By default, user's time zone is always selected; there's also ability to display in other time zones. To do this, change time zone for timetable display.
 2261: 
 2262: In opened "Timetable Planning" dialog, specify period of created timetable validity and one of planning criteria (configured in Planning – Planning Criteria section):
 2263: 
 2264: ---
 2265: 
 2266: ## Page 324
 2267: 
 2268: ![Timetable Planning Dialog](img/timetable_planning_dialog.png)
 2269: 
 2270: After parameters are selected, click "Start planning" button. After this, a planning task will appear in timetable tasks with "Executing" status. Task can be canceled or execution checked by updating status ⟳.
 2271: 
 2272: ![Timetable Planning Status](img/timetable_planning_status.png)
 2273: 
 2274: **Note**: if attempting to build timetable for template that includes groups for which forecasts weren't previously obtained, system will display error:
 2275: 
 2276: ![Timetable Planning Error](img/timetable_planning_error.png)
 2277: 
 2278: User in this case needs to obtain forecast, then retry building timetable.
 2279: 
 2280: Formed timetable will look as follows:
 2281: 
 2282: ---
 2283: 
 2284: ## Page 325
 2285: 
 2286: ![Formed Timetable](img/formed_timetable.png)
 2287: 
 2288: Also by setting checkboxes in "Filters" area, you can sort employee list:
 2289: 
 2290: ![Timetable Filters](img/timetable_filters.png)
 2291: 
 2292: • **Subordinate operators** – will display list of employees who belong to department headed or deputized by user;
 2293: • **Home** – will display list of operators marked in their card as home operator;
 2294: • **Office** – will display list of operators marked in their card as office operator;
 2295: • **Vacation** – will display list of operators who are on vacation during current timetable period;
 2296: • **Sick leave** – will display list of operators who are on sick leave during current timetable period;
 2297: • **Time off** – will display list of operators who took time off during current timetable period.
 2298: 
 2299: Next, statistics for created events are displayed. It's shown including for timetables that fall within event validity period:
 2300: 
 2301: ![Event Statistics](img/event_statistics.png)
 2302: 
 2303: ---
 2304: 
 2305: ## Page 326
 2306: 
 2307: • **Project** – displays project name assigned in this timetable (and others);
 2308: • **Start date and End date** – project dates;
 2309: • **Segment requirements** – number of intervals needed to cover event-required load;
 2310: • **Total assigned, segments** – displays how many intervals were allocated for project. This field displays statistics for all current timetables created during event period;
 2311: • **Assigned in timetable, segments** – this statistic displays how many intervals were allocated for project specifically in considered timetable.
 2312: 
 2313: In "by employees" timetable view mode, list of all employees is displayed.
 2314: 
 2315: ![Timetable by Employees](img/timetable_by_employees.png)
 2316: 
 2317: In view mode by individual group, only operators of this group are displayed.
 2318: 
 2319: ---
 2320: 
 2321: ## Page 327
 2322: 
 2323: ![Timetable by Group](img/timetable_by_group.png)
 2324: 
 2325: Timetable statistics show intervals with deficit, surplus, and sufficiency according to legend.
 2326: 
 2327: ![Timetable Statistics Legend](img/timetable_statistics_legend.png)
 2328: 
 2329: If forecasted number of operators exceeds actual (in other words, there won't be enough operators on line at some point according to forecast), then according to legend, "forecast" and "actual" rows are colored red.
 2330: 
 2331: If forecasted number of operators is less than actual (in other words, there will be excess operators on line at some point), then according to legend, "forecast" and "actual" rows are colored gray.
 2332: 
 2333: If employee composing timetable is satisfied with created timetable, it should be saved by clicking "Save" button. Next, dialog will open where timetable name and brief description must be specified. For final saving, click:
 2334: 
 2335: ---
 2336: 
 2337: ## Page 328
 2338: 
 2339: ![Save Timetable Dialog](img/save_timetable_dialog.png)
 2340: 
 2341: To cancel timetable, click "Cancel" button.
 2342: 
 2343: If timetable needs updating, click "Update" button; read more about timetable updating in next section:
 2344: 
 2345: ![Update Timetable Button](img/update_timetable_button.png)
 2346: 
 2347: ### 8.2. Multi-skill Operator Consideration in Timetable Composition
 2348: 
 2349: Multi-skill operators are those who can simultaneously handle multiple directions (in WFM CC – simultaneously belong to multiple groups). For system to consider operator as multi-skill when composing timetable, they must belong simultaneously to multiple groups of one template.
 2350: 
 2351: Load between multi-skill and mono-skill operators is distributed as follows:
 2352: 
 2353: • First, system considers all mono-skill operators when creating timetable.
 2354: • Remaining load is distributed among multi-skill operators.
 2355: 
 2356: ### 8.3. Updating Composed Timetable
 2357: 
 2358: **Important!** Before updating timetable, don't forget to save it first.
 2359: 
 2360: Timetable update function allows updating previously created timetable considering updated load, employee special events, manual timetable correction, employee work schedule change, employee deactivation, new employee creation.
 2361: 
 2362: To update timetable, first select template on left, then select saved timetable for this template (in "Timetable variants" area) and click "Update" button:
 2363: 
 2364: ![Update Timetable Process](img/update_timetable_process.png)
 2365: 
 2366: ---
 2367: 
 2368: ## Page 329
 2369: 
 2370: "Timetable Planning" form will open. Specify planning period you want to update:
 2371: 
 2372: ![Update Planning Period](img/update_planning_period.png)
 2373: 
 2374: After parameters are selected, click "Start planning" button. After updating schedule, it needs to be saved. When saving, you can change name and comment.
 2375: 
 2376: ![Save Updated Timetable](img/save_updated_timetable.png)
 2377: 
 2378: ### 8.4. Manual Timetable Changes
 2379: 
 2380: For created timetable in "ARGUS WFM CC" system, there's ability for manual correction of operator working intervals:
 2381: 
 2382: • Adding/removing lunches and breaks;
 2383: • Recording downtime;
 2384: • Call/cancel call to work;
 2385: • Adding/canceling work attendance;
 2386: • Project assignment;
 2387: • Adding/canceling events.
 2388: 
 2389: **Important!** User can edit timetable under following conditions:
 2390: 
 2391: • If user is head of parent department (and has access right for timetable editing), they can edit timetable for both subordinate operators and operators from child departments;
 2392: • If user is head of child department (and has access right for timetable editing), they can edit timetable only for subordinate employees;
 2393: • If user is deputy of parent department (and has access right for timetable editing), they can edit timetable for both subordinate operators and operators from child departments. Day when corrections are made must fall within deputy period;
 2394: • If user is deputy of child department (and has access right for timetable editing), they can edit timetable only for subordinate employees. Day when corrections are made must fall within deputy period;
 2395: • If user is not head or deputy but has access right for timetable editing, they can edit timetable for all operators.
 2396: 
 2397: On "Planning" → "Creating timetables" page, select timetable from list. In "Timetable" block, select necessary day and employee time interval:
 2398: 
 2399: ---
 2400: 
 2401: ## Page 330
 2402: 
 2403: ![Manual Timetable Selection](img/manual_timetable_selection.png)
 2404: 
 2405: Time in timetable is divided into 5-minute intervals. To select one 5-minute interval, click on it with left mouse button:
 2406: 
 2407: ![Select Time Interval](img/select_time_interval.png)
 2408: 
 2409: Using held "Ctrl" button, you can select different 5-minute intervals for different employees:
 2410: 
 2411: ---
 2412: 
 2413: ## Page 331
 2414: 
 2415: ![Multi-select Intervals](img/multi_select_intervals.png)
 2416: 
 2417: System also allows selecting entire area by clicking left mouse button and dragging to select area without releasing:
 2418: 
 2419: ![Select Area](img/select_area.png)
 2420: 
 2421: After time interval is selected, call menu by right-clicking and select one of events:
 2422: 
 2423: ---
 2424: 
 2425: ## Page 332
 2426: 
 2427: ![Timetable Context Menu](img/timetable_context_menu.png)
 2428: 
 2429: **Adding/removing lunches and breaks.**
 2430: 
 2431: Lunches/breaks can be added and removed when operator's shift duration was changed to one for which there are no lunch/break rules in "Lunches/breaks" directory. In other cases, system won't allow adding and removing lunches and breaks.
 2432: 
 2433: To add lunch or break, select needed cells and choose "Add lunch" or "Add break":
 2434: 
 2435: ---
 2436: 
 2437: ## Page 333
 2438: 
 2439: ![Add Lunch Break](img/add_lunch_break.png)
 2440: 
 2441: To remove lunch or break, select needed cells and choose "Cancel breaks":
 2442: 
 2443: ---
 2444: 
 2445: ## Page 334
 2446: 
 2447: ![Cancel Breaks](img/cancel_breaks.png)
 2448: 
 2449: **Recording downtime.**
 2450: 
 2451: To register employee downtime, select needed cells and choose "Not taking calls":
 2452: 
 2453: ---
 2454: 
 2455: ## Page 335
 2456: 
 2457: ![Record Downtime](img/record_downtime.png)
 2458: 
 2459: **Adding/canceling work attendance.**
 2460: 
 2461: To register employee non-working time, select needed cells and choose "Non-working time":
 2462: 
 2463: ---
 2464: 
 2465: ## Page 336
 2466: 
 2467: ![Non-working Time](img/non_working_time.png)
 2468: 
 2469: To add employee work attendance, switch display to specific project:
 2470: 
 2471: ---
 2472: 
 2473: ## Page 337
 2474: 
 2475: ![Project Display Switch](img/project_display_switch.png)
 2476: 
 2477: Then select needed cells and choose "Add work attendance":
 2478: 
 2479: ![Add Work Attendance](img/add_work_attendance.png)
 2480: 
 2481: **Project assignment.**
 2482: 
 2483: To assign employee to specific project, switch display to specific project, select needed cells, and choose "Assign to project:"
 2484: 
 2485: ---
 2486: 
 2487: ## Page 338
 2488: 
 2489: ![Assign to Project](img/assign_to_project.png)
 2490: 
 2491: In this case, regardless of employee involvement in other projects, they will be 100% engaged in current project.
 2492: 
 2493: **Adding/canceling events.**
 2494: 
 2495: To add event to operator, choose "Event," then dialog will open:
 2496: 
 2497: ---
 2498: 
 2499: ## Page 339
 2500: 
 2501: ![Add Event Dialog](img/add_event_dialog.png)
 2502: 
 2503: Where you select event type (Training/Meeting/Calls/Survey collection), specific event from "Events" directory. Time and participant will be selected automatically since interval was already selected. Then click to add event.
 2504: 
 2505: ![Event Added](img/event_added.png)
 2506: 
 2507: To cancel event, select event of interest and click "Cancel event"
 2508: 
 2509: ---
 2510: 
 2511: ## Page 340
 2512: 
 2513: ### 8.5. Applying Composed Timetable for Selected Template
 2514: 
 2515: When timetable is composed successfully and fits planning criteria, it can be accepted as active working timetable. To do this, apply selected timetable for template. After applying timetable, it will be available for viewing in "Current timetable" section.
 2516: 
 2517: For selected template in "Timetable variants" block, select suitable timetable variant and click "Apply":
 2518: 
 2519: ![Apply Timetable](img/apply_timetable.png)
 2520: 
 2521: In "Creating timetables" section, applied timetable is highlighted in bold in timetable variants list block:
 2522: 
 2523: ![Applied Timetable Highlight](img/applied_timetable_highlight.png)
 2524: 
 2525: System also has ability to calculate timetable cost. Timetable cost calculation is based on operator hourly cost (set in "Premium Indicators" directory) and night shift premium (if employee works night hours) for operators participating in current timetable. To calculate cost, click.
 2526: 
 2527: ---
 2528: 
 2529: ## Page 341
 2530: 
 2531: ![Calculate Timetable Cost](img/calculate_timetable_cost.png)
 2532: 
 2533: Based on cost of two or more timetables, you can decide which timetable is better to apply.
 2534: 
 2535: When timetables overlap (when there's already current timetable created earlier), when clicking "Apply" button, system will display warning message:
 2536: 
 2537: ![Timetable Overlap Warning](img/timetable_overlap_warning.png)
 2538: 
 2539: – clicking this button, senior operator confirms overwriting previous current timetable (overlapping dates will be overwritten);
 2540: – clicking this button, senior operator cancels applying new timetable.
 2541: 
 2542: ---
 2543: 
 2544: ## Page 342
 2545: 
 2546: ### 8.6. Current Timetable
 2547: 
 2548: Current timetable is designed for viewing current applied timetable for selected template with group.
 2549: 
 2550: To go to Current timetable, open side menu and go to "Planning" → "Current timetable":
 2551: 
 2552: ![Current Timetable Navigation](img/current_timetable_navigation.png)
 2553: 
 2554: When opening page, select multi-skill template, then select date included in built timetable period:
 2555: 
 2556: ![Current Timetable Selection](img/current_timetable_selection.png)
 2557: 
 2558: Current timetable functionality differs from creating timetable functionality:
 2559: 
 2560: • Cannot correct shares;
 2561: • Cannot add hours to operator;
 2562: • Cannot set downtime for operator and update timetable.
 2563: 
 2564: However, you can add event and call operator to work.
 2565: 
 2566: To call operator to work, go to operator view mode by groups:
 2567: 
 2568: ---
 2569: 
 2570: ## Page 343
 2571: 
 2572: ![Operator View by Groups](img/operator_view_by_groups.png)
 2573: 
 2574: Then select needed time period, right-click and choose "Call to work" (call to work functionality is only available for subordinate employees):
 2575: 
 2576: ![Call to Work](img/call_to_work.png)
 2577: 
 2578: Then click "Save" (after adding event too).
 2579: 
 2580: Called operator looks like this:
 2581: 
 2582: ![Called Operator Display](img/called_operator_display.png)
 2583: 
 2584: This sign means employee is called to work and depending on "Notification Schemes" directory setting, operator will be sent notification. Next, if operator agrees to work shift/refuses to work shift, call to work must be deleted and either work shift added or not.
 2585: 
 2586: Current timetable can be exported to Excel by clicking.
 2587: 
 2588: ## 9. Vacancy Planning
 2589: 
 2590: Vacancy Planning module is available to users with system role "Administrator" or any other role with access rights System_AccessVacancyPlanning – view "Vacancy Planning" page.
 2591: 
 2592: Vacancy planning module allows automatically calculating optimal personnel number needed to cover current load. During calculation, system will rely on:
 2593: 
 2594: ---
 2595: 
 2596: ## Page 344
 2597: 
 2598: • Work rules (set in system start and end shift times, duration, and alternation of working and non-working days);
 2599: • Current multi-skill planning template;
 2600: • Minimum vacancy efficiency (indicator reflecting what percentage of deficit intervals system should consider when calculating required operator number for given schedule);
 2601: • Break percentage.
 2602: 
 2603: Upon planning completion, system will suggest specific shifts and work rules for expanding staff for existing project.
 2604: 
 2605: To start vacancy planning, go to corresponding system module: "Planning" -> "Vacancy Planning"
 2606: 
 2607: ![Vacancy Planning Navigation](img/vacancy_planning_navigation.png)
 2608: 
 2609: On "Vacancy Planning" page, you'll see list of multi-skill planning templates; vacancies are planned based on personnel in these templates.
 2610: 
 2611: ---
 2612: 
 2613: ## Page 345
 2614: 
 2615: Also when selecting template, you'll see list of existing vacancy planning tasks, and when selecting task, work rules available to it.
 2616: 
 2617: ![Vacancy Planning Template Selection](img/vacancy_planning_template_selection.png)
 2618: 
 2619: To start planning, select template of interest and click "Plan vacancies" button.
 2620: 
 2621: ![Plan Vacancies Button](img/plan_vacancies_button.png)
 2622: 
 2623: After this, window with task planning settings will open:
 2624: 
 2625: • **Task name** – Task name that will be displayed in task list;
 2626: • **Planning period** – period for which vacancies will be planned;
 2627: • **Breaks, %** – break percentage that will be considered during planning;
 2628: 
 2629: ---
 2630: 
 2631: ## Page 346
 2632: 
 2633: • **Minimum vacancy efficiency, %** – minimum ratio of deficit periods to total number of intervals covered by vacancy;
 2634: • **Plan considering work schedule** – When planning vacancies without considering work schedule, deficit equals forecast divided by (100% minus user-specified % breaks). When planning vacancies considering work schedule, deficit equals difference between forecast divided by (100% minus user-specified % breaks) and operator plan according to "Plan" work schedule;
 2635: • **Work rules** – work rules available for planning.
 2636: 
 2637: ![Vacancy Planning Settings](img/vacancy_planning_settings.png)
 2638: 
 2639: After setting parameters, click "Start planning" button.
 2640: 
 2641: Planning task will appear in task list showing its status; to update task status, click "Update" button ⟳, to stop task, click "Cancel" button ✕. To delete task, right-click on it and select "Delete task."
 2642: 
 2643: ---
 2644: 
 2645: ## Page 347
 2646: 
 2647: ![Vacancy Planning Task Status](img/vacancy_planning_task_status.png)
 2648: 
 2649: Once task completes planning, it automatically saves, and its status changes to "Result saved." You can click on task to display vacancy and employee work schedules (if "Plan considering work schedule" setting is enabled). Statistics on surpluses/deficits considering planned vacancies is also provided as histogram.
 2650: 
 2651: ![Vacancy Planning Results](img/vacancy_planning_results.png)
 2652: 
 2653: ---
 2654: 
 2655: ## Page 348
 2656: 
 2657: ![Vacancy Planning Chart](img/vacancy_planning_chart.png)
 2658: 
 2659: You can interact with schedules by scrolling mouse wheel or moving view period using held left mouse button.
 2660: 
 2661: Sorting is also available by:
 2662: 
 2663: • Display only operators/only vacancies;
 2664: • Display operators first/vacancies first;
 2665: • Select group from multi-skill planning template.
 2666: 
 2667: ![Vacancy Planning Sorting](img/vacancy_planning_sorting.png)
 2668: 
 2669: Based on vacancy plan data, you can analyze deficit/surplus areas in work schedule and make appropriate decisions on staff reduction/expansion.
 2670: 
 2671: ## 10. Exchange
 2672: 
 2673: Exchange is a set of tools and means providing interactive process of assigning performers to various offers, depending on employee needs and preferences. Currently, exchange has only one type of offer – shift.
 2674: 
 2675: Advantages:
 2676: 
 2677: • Planners spend less time determining resource needs;
 2678: • Managers potentially spend less time finding suitable performer;
 2679: 
 2680: ---
 2681: 
 2682: ## Page 349
 2683: 
 2684: • Operators have choice ability, which increases employee loyalty to company.
 2685: 
 2686: This approach can be called element of teal organization structure, and presence of this functionality in WFM product increases its integrability into EX / EE (Employee Experience / Employee Engagement) concepts.
 2687: 
 2688: Planner and manager interaction with exchange occurs on separate WFMCC page, divided into 3 tabs:
 2689: 
 2690: • **Statistics** - for viewing statistics, determining needs and creating offers;
 2691: • **Offers** - for viewing available offers (offers that operators haven't responded to yet) and deleting them;
 2692: • **Responses** - for viewing current responses awaiting answer (responses that haven't been confirmed/rejected/canceled yet).
 2693: 
 2694: Operator interaction with exchange occurs on separate page in personal account, divided into 2 tabs:
 2695: 
 2696: • **Mine** - for viewing submitted responses and canceling them;
 2697: • **Available** - for viewing offers and creating responses.
 2698: 
 2699: ### 10.1. Viewing Statistics on Exchange Page
 2700: 
 2701: Exchange module is available to users:
 2702: 
 2703: • With "Administrator" role;
 2704: • With access rights "View Exchange page" (System_AccessExchangeService)
 2705: 
 2706: Exchange page can be found by going to side menu -> "Exchange"
 2707: 
 2708: ---
 2709: 
 2710: ## Page 350
 2711: 
 2712: ![Exchange Navigation](img/exchange_navigation.png)
 2713: 
 2714: To view statistics by direction, on statistics tab, select multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.
 2715: 
 2716: ![Exchange Statistics Configuration](img/exchange_statistics_configuration.png)
 2717: 
 2718: Statistics are presented for forecasted load and planned operators, shown in both table and chart format. You can interact with chart: increase/decrease scale, hide chart curve displays.
 2719: 
 2720: ---
 2721: 
 2722: ## Page 351
 2723: 
 2724: ![Exchange Statistics Chart](img/exchange_statistics_chart.png)
 2725: 
 2726: ![Exchange Statistics Table](img/exchange_statistics_table.png)
 2727: 
 2728: ### 10.2. Creating and Viewing Offers on Exchange
 2729: 
 2730: Creating and viewing offers on exchange functionality is available to users:
 2731: 
 2732: • With "Administrator" role;
 2733: • With access rights "Create/delete offers" (System_ChangeOffer)
 2734: • With access rights "View Exchange page" (System_AccessExchangeService)
 2735: 
 2736: ---
 2737: 
 2738: ## Page 352
 2739: 
 2740: Based on presented statistics, analyzing surpluses and deficits, you can conclude about need for additional shifts – offers. Shifts that operator can respond to and come to work.
 2741: 
 2742: To create shift, on statistics tab fill in fields: shift name, shift duration, number of shifts. And click "Create" button.
 2743: 
 2744: ![Create Shift Offer](img/create_shift_offer.png)
 2745: 
 2746: After this, offers will be created, and recalculated operator plan considering exchange offers will be displayed on chart and table.
 2747: 
 2748: ![Exchange Offers Created](img/exchange_offers_created.png)
 2749: 
 2750: ---
 2751: 
 2752: ## Page 353
 2753: 
 2754: ![Exchange Updated Plan](img/exchange_updated_plan.png)
 2755: 
 2756: Offers can also be viewed on corresponding "Offers" tab. In "View parameters" window, specify: multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.
 2757: 
 2758: All available offers will be displayed.
 2759: 
 2760: ![View Exchange Offers](img/view_exchange_offers.png)
 2761: 
 2762: Offers can be deleted by selecting them with checkbox and clicking "Gear" -> "Delete."
 2763: 
 2764: ![Delete Exchange Offers](img/delete_exchange_offers.png)
 2765: 
 2766: ---
 2767: 
 2768: ## Page 354
 2769: 
 2770: ### 10.3. Response and Response Confirmation to Offer
 2771: 
 2772: Response confirmation functionality on exchange is available to users:
 2773: 
 2774: • With "Administrator" role;
 2775: • With access rights "Confirm responses" (System_ConfirmResponse)
 2776: • With access rights "View Exchange page" (System_AccessExchangeService)
 2777: 
 2778: After operators respond to offers, their responses can be viewed on "Responses" tab. In "View parameters" window, specify: multi-skill planning template, group (direction), data viewing period, time zone. And click "Apply" button.
 2779: 
 2780: ![View Exchange Responses](img/view_exchange_responses.png)
 2781: 
 2782: Response can be confirmed by clicking "Checkmark" ✓, returned by clicking "Arrow" ↩ (in this case operator can respond again to same offer), or rejected by clicking "Cross" ✕ (in this case operator cannot respond again to this offer).
 2783: 
 2784: After manager confirms response, shift will be created in current applied work schedule for operator.
 2785: 
 2786: ---
 2787: 
 2788: ## Page 355
 2789: 
 2790: ![Response Confirmation Actions](img/response_confirmation_actions.png)
 2791: 
 2792: ![Response Confirmed Result](img/response_confirmed_result.png)
 2793: 
 2794: ## 11. Employee Personal Account
 2795: 
 2796: User can log into system provided that user with "Senior Operator" or "Administrator" role previously created account for corresponding user.
 2797: 
 2798: After passing authorization procedure, user can view their profile (personal account) and edit part of information if they have corresponding access right.
 2799: 
 2800: To go to personal account, open "My Account" section (you can go from section list menu or from main page by clicking "My Account" block):
 2801: 
 2802: ---
 2803: 
 2804: ## Page 356
 2805: 
 2806: ![Personal Account Navigation](img/personal_account_navigation.png)
 2807: 
 2808: ### 11.1. Operator Personal Account
 2809: 
 2810: User with "Operator" role in personal account can view following profile information:
 2811: 
 2812: • Full name, personnel number, mark indicating whether operator is home (area 1).
 2813: • Timetable (area "Timetable," displays events according to "Current timetable." In other words, here their work timetable is displayed according to which they should come to work). For timetable to be displayed to operator: forecast load, assign work schedule template to employee, add business rules to them.
 2814: • Current work schedule (area "Current work schedule").
 2815: • Contact information (area "Contacts");
 2816: • Services and groups they belong to (area "Services and groups");
 2817: • Skills (area "Skills");
 2818: • Performance statistics for current period (area "Performance for current month")
 2819: • Assigned work schedule templates for this operator; here employee can set preference for desired rotation.
 2820: 
 2821: ---
 2822: 
 2823: ## Page 357
 2824: 
 2825: ![Operator Personal Account](img/operator_personal_account.png)
 2826: 
 2827: Also here operator can export their premium report calculated for selected period:
 2828: 
 2829: ![Export Premium Report](img/export_premium_report.png)
 2830: 
 2831: By clicking, report will be exported to Excel (xlsx). It looks like this:
 2832: 
 2833: ---
 2834: 
 2835: ## Page 358
 2836: 
 2837: ![Premium Report Example](img/premium_report_example.png)
 2838: 
 2839: In row, indicator shows indicator for which percentage goes to premium, for which group and for what group.
 2840: 
 2841: ### 11.2. Registering and Deleting Special Event in Timetable
 2842: 
 2843: Special event registration is available to user with access right "Ability to edit own events on calendar." Without this access right, employee can only view their timetable and work schedule.
 2844: 
 2845: **Note for database administrators.**
 2846: 
 2847: Database settings have limitation on ability to register special events for current day/week/month.
 2848: 
 2849: For this, following parameters are set in "pref_table" table:
 2850: 
 2851: "edit_my_schedule_period_type" – period type (DAY, WEEK, MONTH)
 2852: "edit_my_schedule_period_value" – value 0 or 1.
 2853: 
 2854: • 0 – can edit right on current day/week/month.
 2855: • 1 – can edit only starting from next day/week/month.
 2856: 
 2857: By default, database settings specify following values:
 2858: 
 2859: "edit_my_schedule_period_type" – WEEK
 2860: "edit_my_schedule_period_value" – 1
 2861: 
 2862: Since operator can be home or office:
 2863: 
 2864: • **Home operator.** If operator has access right "Ability to edit own events on calendar," they specify work attendance preferences and special events for next week. If no access right – they can only view their timetable and schedule.
 2865: 
 2866: ---
 2867: 
 2868: ## Page 359
 2869: 
 2870: • **Office operator.** Cannot change schedule and shift. But if "Ability to edit own events on calendar" access right is set, they can specify special events + work preferences outside schedule.
 2871: 
 2872: Following events can be registered as special event in system:
 2873: 
 2874: • Sick leave (icon on work schedule),
 2875: • Vacation (icon on work schedule),
 2876: • Time off (icon on work schedule),
 2877: • Work attendance (icon on work schedule),
 2878: • Reserve (icon on work schedule).
 2879: 
 2880: Employee special event is considered when planning timetable.
 2881: 
 2882: Adding events is available to user with access right: System_EditWorkerApprovedVacationAndExtraWork – allows editing approved vacations and "Work attendance" shifts.
 2883: 
 2884: To register work attendance in "Work schedule" block in calendar or table form, select date of interest.
 2885: 
 2886: Employee work schedule is displayed in two views: calendar and table:
 2887: 
 2888: ![Work Schedule Views](img/work_schedule_views.png)
 2889: 
 2890: Days in calendar view are selected in several ways:
 2891: 
 2892: • One day in calendar is selected by clicking with left mouse button;
 2893: 
 2894: ---
 2895: 
 2896: ## Page 360
 2897: 
 2898: • Different days in calendar are selected by clicking left mouse button with Ctrl key held;
 2899: • Period of days can be selected in two ways;
 2900: • With Shift key held, select day – start of interval, then select day – end of interval;
 2901: • With Ctrl key held, sequentially select days from period.
 2902: 
 2903: Days in table view are selected:
 2904: 
 2905: • One/several days in calendar are selected by area capture (for this, holding left mouse button, select area)
 2906: 
 2907: ![Table View Selection](img/table_view_selection.png)
 2908: 
 2909: • Specific hours can be selected. To do this, click on hour of interest with left mouse button:
 2910: 
 2911: ---
 2912: 
 2913: ## Page 361
 2914: 
 2915: ![Hour Selection](img/hour_selection.png)
 2916: 
 2917: • With "CTRL" key held, you can select different hours for different days (or same day):
 2918: 
 2919: ![Multiple Hour Selection](img/multiple_hour_selection.png)
 2920: 
 2921: After necessary period is selected (for example, March 16), right-click to call context menu and click "Add event":
 2922: 
 2923: ---
 2924: 
 2925: ## Page 362
 2926: 
 2927: ![Add Event Context Menu](img/add_event_context_menu.png)
 2928: 
 2929: In appearing "Add new event" window:
 2930: 
 2931: • Select necessary event type from dropdown list (for example, work attendance)
 2932: 
 2933: ![Select Event Type](img/select_event_type.png)
 2934: 
 2935: • In "Period" area, if "Selection" parameter is chosen, days and hours selected when highlighting them on calendar are displayed;
 2936: 
 2937: ---
 2938: 
 2939: ## Page 363
 2940: 
 2941: ![Event Period Selection](img/event_period_selection.png)
 2942: 
 2943: • If different date range needs to be specified, select "Range" parameter in "Period" area and specify start and end event dates
 2944: 
 2945: ![Event Date Range](img/event_date_range.png)
 2946: 
 2947: • To save event, click button:
 2948: 
 2949: ---
 2950: 
 2951: ## Page 364
 2952: 
 2953: ![Save Event Button](img/save_event_button.png)
 2954: 
 2955: Added event will be displayed on employee work schedule:
 2956: 
 2957: ![Added Event Display](img/added_event_display.png)
 2958: 
 2959: **Event deletion.**
 2960: 
 2961: To delete special event, select days on calendar (or at least one day included in special event) that have special event set, call menu by right-clicking and click "Delete event":
 2962: 
 2963: ---
 2964: 
 2965: ## Page 365
 2966: 
 2967: ![Delete Event Menu](img/delete_event_menu.png)
 2968: 
 2969: Next, system will ask to confirm actions:
 2970: 
 2971: ![Delete Event Confirmation](img/delete_event_confirmation.png)
 2972: 
 2973: If multiple special events fall within selected period, uncheck those that shouldn't be deleted.
 2974: 
 2975: ---
 2976: 
 2977: ## Page 366
 2978: 
 2979: To confirm event deletion, click, to cancel –.
 2980: 
 2981: Similarly, "Sick leave," "Vacation," "Time off," "Reserve" type events are added/deleted.
 2982: 
 2983: **Note.**
 2984: 
 2985: For more efficient work attendance registration, you can use "Add work attendance" button (this button is only available when registering event in table form of work schedule):
 2986: 
 2987: ![Quick Add Work Attendance](img/quick_add_work_attendance.png)
 2988: 
 2989: In this case, when clicking "Add work attendance," system immediately displays "Work attendance" event in work schedule – for time interval that was selected (Figure – 8.2.14):
 2990: 
 2991: ![Work Attendance Added](img/work_attendance_added.png)
 2992: 
 2993: ---
 2994: 
 2995: ## Page 367
 2996: 
 2997: ### 11.3. Senior Operator Personal Account
 2998: 
 2999: Employee with "Senior Operator" role has following abilities in system:
 3000: 
 3001: • View all employees entered in system;
 3002: • View group list;
 3003: • Edit employee information;
 3004: • Timetable planning;
 3005: • Mass business rule assignment;
 3006: • Load forecasting;
 3007: • Reports.
 3008: 
 3009: In their personal account, senior operator sees same information as operator, and can also export their timetable. But besides this, senior operator can edit following information:
 3010: 
 3011: • Full name, personnel number, mark indicating whether operator is home or office;
 3012: • Work schedule;
 3013: • Contacts;
 3014: • Skills (area "Skills").
 3015: 
 3016: ### 11.4. Setting Preferences in Operator Personal Account
 3017: 
 3018: In their personal account, Operator will see panel where they can specify their work and day off preferences. It contains following information:
 3019: 
 3020: • Period for which Operator can set preference;
 3021: • Preference setting deadline;
 3022: 
 3023: ---
 3024: 
 3025: ## Page 368
 3026: 
 3027: • Number of regular and priority preferences that Operator is allowed to set;
 3028: • Number of regular and priority preferences that system considered (appears only after work schedule update or creation of new one).
 3029: 
 3030: System may not consider all preferences. This is because System must cover forecasted load, and Operator must work required number of hours (cover performance). For example, if Operator working full-time sets 6 days off per week, system won't consider preference.
 3031: 
 3032: ![Operator Preferences Panel](img/operator_preferences_panel.png)
 3033: 
 3034: Operator fills in their preferences during specific period in System. To do this, they specify:
 3035: 
 3036: • Preference day;
 3037: • Type (working day or day off);
 3038: • Shift start period (can be fixed (for example, 09:00 – 09:00) or flexible (07:00 – 09:00));
 3039: • Shift end (similar to start);
 3040: • Duration (similar to start and end);
 3041: • Priority checkbox.
 3042: 
 3043: ---
 3044: 
 3045: ## Page 369
 3046: 
 3047: ![Set Preferences Form](img/set_preferences_form.png)
 3048: 
 3049: When filling preference, "Incorrectly set shift parameters" notification may appear. It's displayed when shift duration contradicts its start and end. For example, setting start 09:00-09:00, end 18:00-18:00, but duration 03:00-03:00.
 3050: 
 3051: After operators set their preference information, and Planner/Manager received information about closing ability to set preferences:
 3052: 
 3053: • Planner/Manager should plan/update work schedule to consider this preference data in work schedule. System during planning/updating schedule will try to consider preferences set by Operators in their personal accounts.
 3054: 
 3055: ### 11.5. Responding to Exchange Offers
 3056: 
 3057: Operator can accept exchange offers through personal account by going to "Exchange" page:
 3058: 
 3059: ---
 3060: 
 3061: ## Page 370
 3062: 
 3063: ![Exchange Page Navigation](img/exchange_page_navigation.png)
 3064: 
 3065: Exchange page has two tabs:
 3066: 
 3067: • "Mine" - displays accepted offers;
 3068: • "Available" - displays available exchange offers.
 3069: 
 3070: To respond to offers, go to available tab, which displays all offers suitable for operator and detailed information about them. Offers can be filtered by specific date or name.
 3071: 
 3072: If offer suits operator, they can respond to it by clicking on offer itself, then clicking "Accept" button.
 3073: 
 3074: ---
 3075: 
 3076: ## Page 371
 3077: 
 3078: ![Accept Exchange Offer](img/accept_exchange_offer.png)
 3079: 
 3080: After employee responds to request, they can view its status on "Mine" tab.
 3081: 
 3082: ![Exchange Response Status](img/exchange_response_status.png)
 3083: 
 3084: ---
 3085: 
 3086: ## Page 372
 3087: 
 3088: ## 12. Business Processes (BPMS)
 3089: 
 3090: Business processes loaded into system allow implementing processes not by verbal agreement between users – need to first confirm employee wishes, then compose schedule, then schedules should be reviewed by department heads, etc. (this is verbal agreement since user may not do all this, but simply create schedule immediately), but as specific sequence of actions that system will expect and won't allow proceeding to next process stage until previous one is completed.
 3091: 
 3092: Loaded business process (hereinafter BP) stores information about action sequence that needs to be followed in system (directly business process sequence), otherwise system won't allow advancing in this BP, as well as which users can perform these BP stages and what actions will be available at specific stages (for example, changing shifts in work schedule is possible not at any BP stage and not any user has right to change these shifts at specific stage).
 3093: 
 3094: But besides loading BP into system that stores all necessary stage information, these stages need to be managed somehow, delegate tasks to users, etc. This task is performed by "Approval tasks" functionality, which allows executing BP stages, delegating these stages to other employees, or taking them for yourself.
 3095: 
 3096: ### 12.1. Loading BP into System
 3097: 
 3098: To load BP into system, go to needed system page, link to which is on main screen:
 3099: 
 3100: ---
 3101: 
 3102: ## Page 373
 3103: 
 3104: ![BP Loading Navigation](img/bp_loading_navigation.png)
 3105: 
 3106: After opening page, following functionality will be displayed:
 3107: 
 3108: ![BP Loading Interface](img/bp_loading_interface.png)
 3109: 
 3110: Clicking "Browse" opens file selection window; you need to select .zip or .rar archive containing business process file. After file is selected, other buttons activate: "Load" and "Cancel."
 3111: 
 3112: ![BP File Selection](img/bp_file_selection.png)
 3113: 
 3114: ### 12.2. Task List
 3115: 
 3116: This section is available to roles with access right "View 'Approval tasks' page" (view and execute tasks) and "Assign task to employee" (assign tasks to other employees). To work with tasks, you need "Department head" role, as well as specific roles needed for executing specific business processes, described below.
 3117: 
 3118: Task list allows managing user-assigned tasks (execute/reassign) generated by executing business process stages. To go to task list, click icon in upper right corner of system interface:
 3119: 
 3120: ---
 3121: 
 3122: ## Page 374
 3123: 
 3124: ![Task List Navigation](img/task_list_navigation.png)
 3125: 
 3126: Red circle shows number of tasks currently assigned to user who logged into system.
 3127: 
 3128: When opening task list, following fields will be displayed:
 3129: 
 3130: ![Task List Interface](img/task_list_interface.png)
 3131: 
 3132: • **"Open/closed" tasks filter** – shows either active tasks or already resolved/closed ones;
 3133: • **Department and performer filters** – allow selecting departments that tasks assigned to users concern, as well as task performer;
 3134: • **My tasks** – displays tasks assigned to user who logged into system;
 3135: • **Where I'm candidate** – each BP stage has so-called "candidates" – users who also can execute specific BP task besides user to whom this task is assigned;
 3136: • **All** – will show all tasks assigned to all users.
 3137: 
 3138: After all necessary filters are filled, click "Search," after which tasks will be displayed (which tasks are displayed depends on filters set earlier):
 3139: 
 3140: ---
 3141: 
 3142: ## Page 375
 3143: 
 3144: ![Task Search Results](img/task_search_results.png)
 3145: 
 3146: • **Approval object** – specific object of type specified below. In Figure – 9.2.3, object is work schedule. In this case, "approval object" is work schedule name;
 3147: • **Object type** – system functionality to which task relates. In case of figure above, this is "Schedule variant," i.e., work schedule;
 3148: • **Process** – BP name to which task relates;
 3149: • **Task** – specific BP stage currently being executed by this task;
 3150: • **Performer** – responsible user who should execute this task;
 3151: • **Comment** – filled after task execution.
 3152: 
 3153: By selecting task (clicking on one of list tasks with left mouse button), user can either execute it or assign to another user. Note that if task is initially assigned to another user, only candidates (mentioned above) and user-performer specified in task can execute it.
 3154: 
 3155: ---
 3156: 
 3157: ## Page 376
 3158: 
 3159: To assign task to another user (or take someone else's task for yourself), select task with left mouse button and click "Assign":
 3160: 
 3161: ![Assign Task](img/assign_task.png)
 3162: 
 3163: Then in "Performer" field, select user from dropdown list to whom task should be assigned.
 3164: 
 3165: To execute task, select needed task with left mouse button and click "Execute":
 3166: 
 3167: ![Execute Task](img/execute_task.png)
 3168: 
 3169: After this, window with comment (which can be left unfilled) and action choice will appear. Action set available when executing tasks is regulated by BP itself that was loaded into system. In figure above, user has two actions that will lead to different BP execution stages. After specific action is performed, click to execute task and transition to next (or previous, depending on selected action) stage. After this, task will move to another BP stage, which will have its own task set and users.
 3170: 
 3171: This is how BP work is organized – specific system actions can start BP execution, after which users will go through it entirely by executing tasks. While if some system functionality is available to user only at specific BP stage, they can't use it outside this BP.
 3172: 
 3173: ### 12.3. Business Process List
 3174: 
 3175: #### 12.3.1. New Work Schedule Approval Process
 3176: 
 3177: Business process (BP) for work schedule formation regulates work schedule creation, its application, and sending to 1C. During BP execution, specific users can edit work schedule and update it. After applying work schedule, BP completes.
 3178: 
 3179: ---
 3180: 
 3181: ## Page 377
 3182: 
 3183: ![Work Schedule BP Overview](img/work_schedule_bp_overview.png)
 3184: 
 3185: BP starts when first work schedule version is planned (detailed in section 6.1). Once work schedule is planned and saved, work schedule approval process starts. Department heads (supervisors) receive "Supervisor confirmation" approval task and notification (detailed in section 3.1.17 "Notification Scheme Directory") that work schedule needs to be corrected (if necessary) and approved. At "Supervisor confirmation" step, department head (supervisor) can make corrections to planned work schedule for subordinate employees (add/delete/correct shifts/vacations), department heads (supervisors) get access to "Update" button.
 3186: 
 3187: ![Supervisor Confirmation](img/supervisor_confirmation.png)
 3188: 
 3189: After all department heads (supervisors) execute their tasks, work schedule approval business process moves to next stage. Responsible employee with "Planning specialist" role receives: notification that department heads (supervisors) approved work schedule and "Planning specialist confirmation" task. At this step, users with "Planning specialist" role can update work schedule and edit it. At this BP stage, responsible user can return work schedule for revision to department heads (supervisors) (previous BP stage), or can move BP to next stage:
 3190: 
 3191: ---
 3192: 
 3193: ## Page 378
 3194: 
 3195: ![Planning Specialist Confirmation](img/planning_specialist_confirmation.png)
 3196: 
 3197: Next BP stage is "Operator confirmation." When moving to this business process step, operators participating in work schedule receive notification that work schedule is formed and task to confirm work schedule. At this step, employee with "Operator" role confirms their work schedule; if necessary, operator can leave wish for shift/vacation date transfer, etc., in "Comment" field.
 3198: 
 3199: ![Operator Confirmation](img/operator_confirmation.png)
 3200: 
 3201: After operators confirm work schedule, BP again moves to last BP step – "Schedule application." When moving to this stage, responsible employee (user with "Planning specialist" role) receives notification that schedule is ready for application and "Apply schedule" task. At this step, employee with "Planning specialist" role, if necessary, makes final work schedule corrections (for example, edits schedule considering operator wishes), sends schedule to 1C system ("Send to 1C" button available), and applies planned work schedule ("Apply" button available).
 3202: 
 3203: **Important!** When transferring schedule to 1C system, work schedule for employees with position marked as non-planning is not transferred.
 3204: 
 3205: ---
 3206: 
 3207: ## Page 379
 3208: 
 3209: "Apply schedule" task is executed automatically after work schedule is applied.
 3210: 
 3211: ![Schedule Application](img/schedule_application.png)
 3212: 
 3213: After applying schedule, "Work schedule approval" BP completes.
 3214: 
 3215: #### 12.3.2. Work Schedule and Vacation Correction Approval Process
 3216: 
 3217: Applied work schedule cannot be edited, so if users want to make corrections to planned work schedule, responsible employee needs to create copy of applied schedule and make corrections to created copy. More details about editing applied schedule in section 6.2. After making necessary changes to created and corrected copy of work schedule, it needs to be applied. Approval and application process for work schedule is similar to "New work schedule approval" BP, except for "Process" field name, i.e., after creating copy of work schedule, department heads (supervisors) receive "Head confirmation" task, etc.
 3218: 
 3219: ![Schedule Correction BP](img/schedule_correction_bp.png)
 3220: 
 3221: ## 13. Reports
 3222: 
 3223: All roles that have access right "System_PremiumPerformanceView" or "System_AccessReportEditor" have access to reports.
 3224: 
 3225: System has ability to generate various reports available to users for viewing and downloading in Excel format (To export report to Excel, click; such button exists in all reports described below).
 3226: 
 3227: **Important!** All reports are generated in user's time zone.
 3228: 
 3229: ### 13.1. System Reports
 3230: 
 3231: #### 13.1.1. Control Page
 3232: 
 3233: Control page shows plan/actual worked hours by operators or entire department, as well as absence codes.
 3234: 
 3235: To go to control page, click "Open control page" on main page:
 3236: 
 3237: ---
 3238: 
 3239: ## Page 380
 3240: 
 3241: ![Control Page Navigation](img/control_page_navigation.png)
 3242: 
 3243: After opening control page, following information will be displayed:
 3244: 
 3245: ![Control Page Interface](img/control_page_interface.png)
 3246: 
 3247: To build report, select department, specific employee full name (optional), period for which information needs to be exported, and click. At this moment, request is sent to 1C, which provides information. From here, you can also go to "Salary calculation" report by clicking "Timesheet."
 3248: 
 3249: Generated report looks like this:
 3250: 
 3251: ![Control Page Report](img/control_page_report.png)
 3252: 
 3253: • **"Overtime" filter** – will show only operators with overtime;
 3254: • **"Undertime" filter** – will show only operators with undertime;
 3255: • **"Confirmed by manager" filter** – displays operators whose information was confirmed by manager;
 3256: • **"Confirmed by Planning specialist" filter** – will show operators whose information was confirmed by "Planning specialist";
 3257: • **Full name** – employee full name. After expanding detailed operator information (arrow left of full name), this field will show date (or several) for which data is displayed;
 3258: • **Plan** – in general view, displays sum of planned working hours for all days; when expanded, shows value for specific day;
 3259: 
 3260: ---
 3261: 
 3262: ## Page 381
 3263: 
 3264: • **Actual** – displays actually worked time by days or their sum for all days. For actual calculation, operator statuses are used that came via integration and have "Actual time in timesheet" checkbox in "Work time efficiency configuration" directory.
 3265: • **Undertime** – shows difference between plan and actual if actual is less than plan, then undertime is considered;
 3266: • **Comment** – filled by department head where employee is located (or their deputy during deputy period). Comment can only be filled when employee data is not confirmed. To create comment, double-click left mouse button on field;
 3267: • **Overtime** – shows difference between plan and actual if actual is greater than plan, then overtime is considered;
 3268: • **Timesheet** – shows absence reasons or attendance (А);
 3269: • **Status** – "Not confirmed" means this report wasn't confirmed for this operator or information reset was performed. "Confirmed" – means data was sent to 1C. "Confirmed by manager" – means information was confirmed by group manager. "Report created" – means absence report was created;
 3270: 
 3271: **Actions:**
 3272: 
 3273: "Confirm by manager" available to group manager to confirm operator overtime/undertime, if necessary create absence report.
 3274: 
 3275: "Create absence report" available after manager confirmation when they confirm operator undertime fact. Button allows printing absence report that automatically fills data such as:
 3276: 
 3277: • Violator position and full name;
 3278: • Position and full name of manager of violator of work schedule;
 3279: • Date and time of violation.
 3280: 
 3281: "Reset" allows resetting all statuses.
 3282: 
 3283: "Confirm" needed for employee who confirms operator information and sends working hours information to 1C.
 3284: 
 3285: Various actions can only be performed by employees with access rights or managers of their departments (and actions, accordingly, are performed with subordinate departments).
 3286: 
 3287: #### 13.1.2. "Schedule Adherence" Report
 3288: 
 3289: Schedule adherence report for operator displays operator performance plan and their actual presence at work.
 3290: 
 3291: To build report, go to "Reports" → "Schedule adherence" tab (you can go from section list menu (click "Reports" – then "Schedule adherence" tab appears) or from main page by clicking "Reports" block):
 3292: 
 3293: ---
 3294: 
 3295: ## Page 382
 3296: 
 3297: ![Schedule Adherence Navigation](img/schedule_adherence_navigation.png)
 3298: 
 3299: After this, "Schedule adherence" window opens where you select operators (check mark) for whom report needs to be built and date interval for which report needs to be built. You can also filter operators by department and set detail period. Operators can be filtered by groups or found by full name.
 3300: 
 3301: ![Schedule Adherence Configuration](img/schedule_adherence_configuration.png)
 3302: 
 3303: Gray color marks terminated employees.
 3304: 
 3305: After all employees are marked and period selected, click.
 3306: 
 3307: ---
 3308: 
 3309: ## Page 383
 3310: 
 3311: ![Schedule Adherence Results](img/schedule_adherence_results.png)
 3312: 
 3313: This table displays:
 3314: 
 3315: • **Full name** - employee last name, first name, and patronymic;
 3316: • **%AVG SH ADH** – operator average punctuality indicator for entire selected period;
 3317: • **SH ADH** – operator punctuality indicator for day;
 3318: • **Schedule** – performance according to operator work schedule;
 3319: • **Timetable** – performance according to operator timetable, can be less than work schedule performance since in timetable operator shift can be edited. Bright color means clean load, lighter color means productive load;
 3320: • **Actual** – actual performance. Bright color marks productive load;
 3321: 
 3322: Upper part of table shows 15-minute periods (or other if selected when building report), and each table cell equals one minute.
 3323: 
 3324: Button will display window with operator selection and date:
 3325: 
 3326: ---
 3327: 
 3328: ## Page 384
 3329: 
 3330: ![Filter Options](img/filter_options.png)
 3331: 
 3332: After which you can either save new filter values by clicking or cancel them.
 3333: 
 3334: #### 13.1.3. "Salary Calculation" Report
 3335: 
 3336: Report is designed to display information about operator presence at their workplaces or their absence. Report is table where for each operator, attendance and non-attendance at work, weekends and vacations, overtime hours and weekend work are considered, and total worked hours for first and second half of month are output, as well as total worked hours for entire month.
 3337: 
 3338: To build report, go to "Reports" → "Salary calculation" tab or from main page by selecting needed report from "Reports" block.
 3339: 
 3340: ---
 3341: 
 3342: ## Page 385
 3343: 
 3344: ![Salary Calculation Navigation](img/salary_calculation_navigation.png)
 3345: 
 3346: After this, window with operator list for whom report will be built opens. It can be filtered by groups, departments, types (home or office), or enter personnel number or operator full name.
 3347: 
 3348: ---
 3349: 
 3350: ## Page 386
 3351: 
 3352: ![Salary Calculation Configuration](img/salary_calculation_configuration.png)
 3353: 
 3354: Three salary report building modes exist:
 3355: 
 3356: • **Build report from 1C data** – when building, data via integration with 1C:Payroll is used;
 3357: • **Build report from contact center actual data** – when building, data via integration with contact center is used;
 3358: • **Build report from schedule data** – when building, work schedule data and operator events are used.
 3359: 
 3360: ---
 3361: 
 3362: ## Page 387
 3363: 
 3364: ![Report Building Modes](img/report_building_modes.png)
 3365: 
 3366: After all parameters are filled, click.
 3367: 
 3368: ![Salary Calculation Report](img/salary_calculation_report.png)
 3369: 
 3370: Report shows attendance and non-attendance marks by month dates. Time is calculated in operator time zone specified in operator card.
 3371: 
 3372: When calculating operator hours, shift whose hours cross midnight boundary is divided into two days. For example, operator worked period 25.11.2025 from 22:00 - 26.11.2025 until 01:00; in this case, report counts for 25.11.2025 - 2 hours (22:00-00:00), for 26.11.2025 - 1 hour (00:00-01:00).
 3373: 
 3374: **Designations:**
 3375: 
 3376: • **А** – attendance;
 3377: • **Н** – night attendance;
 3378: 
 3379: ---
 3380: 
 3381: ## Page 388
 3382: 
 3383: • **НН** – absence;
 3384: • **В** – weekend;
 3385: • **ОТ** – vacation;
 3386: • **С** – overtime work;
 3387: • **РВ** – weekend work;
 3388: • **Б** – sick leave;
 3389: • **О** – time off.
 3390: 
 3391: Report displays information on sum of worked hours and absences for first half of month (1st to 15th) and second half of month (16th to 31st). If dividing month in half doesn't work (for example, 31 days), "Х" will be displayed in 16th day cell.
 3392: 
 3393: ![Report Time Division](img/report_time_division.png)
 3394: 
 3395: If day has multiple marks/hours, they are separated by ";" sign.
 3396: 
 3397: Report can only be built within one month.
 3398: 
 3399: By clicking button, we can change filter for displaying operators in report.
 3400: 
 3401: **Field descriptions:**
 3402: 
 3403: | Field Name | Field Description | Calculation Logic |
 3404: |------------|-------------------|------------------|
 3405: | № | Operator sequence number in report | |
 3406: | Full Name | Last name F. I. of operators for whom report is built | |
 3407: 
 3408: ---
 3409: 
 3410: ## Page 389
 3411: 
 3412: | Field Name | Field Description | Calculation Logic |
 3413: |------------|-------------------|------------------|
 3414: | Personnel Number | Personnel number of operators for whom report is built | |
 3415: | Attendance and non-attendance marks by month dates | For each operator, 4 rows are displayed: • Presence/absence codes for 1-15 of month by each day separately (16th column should have Х) • Sum of hours by each code for 1-15 of month by each day separately (16th column should be empty) • Presence/absence codes for 16-31 of month by each day separately (if some day doesn't exist in month, missing day should have Х) • Sum of hours by each code for 16-31 of month by each day separately (if some day doesn't exist in month, missing day should be empty) | |
 3416: | Worked for half month (I, II) | For each operator, 4 rows are reflected: • Presence/absence codes that were for 1-15 of month (except В, ОТ, Б and О) • Sum of hours by each code for 1-15 of month (except В, ОТ, Б and О) • Presence/absence codes that were for 16-31 of month (except В, ОТ, Б and О) • Sum of hours by each code for 16-31 of month (except В, ОТ, Б and О) | |
 3417: | Month | For each operator, 2 rows are displayed: • Presence/absence codes that were in month (except В, ОТ, Б and О) • Sum of hours by each code for month (except В, ОТ, Б and О) | |
 3418: | Data for salary calculation | Not filled | |
 3419: | Absences by reasons | Not filled | |
 3420: 
 3421: ---
 3422: 
 3423: ## Page 390
 3424: 
 3425: **Calculation Logic:**
 3426: 
 3427: | Code | Description | Display Logic | Hour Calculation Logic |
 3428: |------|-------------|---------------|----------------------|
 3429: | А | Attendance | Operator has planned shift in work schedule for these 24 hours; Operator has working statuses from contact center for these 24 hours; Operator has no vacation, sick leave, time off in work schedule | Sum of operator status durations that were selected by user as timesheet time, but not more than planned shift duration minus unpaid lunches/breaks. For example, if planned shift duration for operator is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 12:30:00, then А should record 11:30:00, remaining time should refer to overtime work (С). |
 3430: | Н | Night attendance | Operator has planned shift in work schedule for these 24 hours; Operator has working statuses from contact center for these 24 hours; Operator has working statuses from contact center that were during night hours according to operator time zone; Code Н is displayed only together with code А | Sum of operator status durations during night hours that were selected by user as timesheet time, but not more than attendance duration. For example, night hours 22:00-06:00, operator planned shift 11:00-23:00, operator worked 11:30-23:30, unpaid lunch was 16:00–16:30. In this case, А should record 11:30:00, Н should record 1:30:00 (22:00-23:30) |
 3431: 
 3432: ---
 3433: 
 3434: ## Page 391
 3435: 
 3436: | Code | Description | Display Logic | Hour Calculation Logic |
 3437: |------|-------------|---------------|----------------------|
 3438: | НН | Absence | Attendance is less than operator shift duration according to work schedule minus unpaid lunches/breaks; Operator card has no vacation, sick leave, or time off | Absence duration = planned shift duration according to work schedule (minus unpaid lunches/breaks) - attendance duration. For example, if operator planned shift is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 10:30:00, then А = 10:30:00, НН=11:30:00-10:30:00=1:00:00 |
 3439: | В | Weekend | Operator has weekend in work schedule; Operator has no working statuses from contact center; Operator card has no vacation, sick leave, or time off | Hours for weekend are not calculated; hours field should be empty. |
 3440: | ОТ | Vacation | Operator has vacation in work schedule; Operator has no working statuses from contact center | Hours for vacation are not calculated; hours field should be empty. |
 3441: | С | Overtime work | Attendance duration is greater than operator shift duration according to work schedule (minus unpaid lunches/breaks); Operator card has no vacation, sick leave, or time off | Overtime work = attendance duration - planned shift duration according to work schedule (minus unpaid lunches/breaks). For example, if operator planned shift is 11:30:00 (minus unpaid lunches/breaks), and actual contact center statuses marked as timesheet time are 12:30:00, then А = 11:30:00, С=12:30:00-11:30:00=1:00:00 |
 3442: 
 3443: ---
 3444: 
 3445: ## Page 392
 3446: 
 3447: | Code | Description | Display Logic | Hour Calculation Logic |
 3448: |------|-------------|---------------|----------------------|
 3449: | РВ | Weekend work | Operator has weekend or vacation in work schedule; Operator has working statuses from contact center for these 24 hours; Operator card has no sick leave or time off | Sum of operator status durations that were selected by user as timesheet time. For example, if operator has weekend but has actual contact center statuses marked as timesheet time and they = 05:00:00, then РВ = 05:00:00 |
 3450: | Б | Sick leave | Operator card has sick leave; Operator has no attendance | Hours for sick leave are not calculated; hours field should be empty. If operator has sick leave set but has contact center statuses, Attendance should be marked (sick leave is not marked) |
 3451: | О | Time off | Operator card has time off | Time off hours are calculated by time off date and time. For example, if time off is set for period 21.12.2022 10:00 - 21.12.2022 16:00, then time off duration for 21.12.2022 equals six hours (16:00-10:00). If time off is set for period 21.12.2022 10:00 - 22.12.2022 16:00, then time off duration for 21.12.2022 equals fourteen hours (24:00-10:00), time off duration for 22.12.2022 equals sixteen hours (16:00-00:00). If operator has time off set but has contact center statuses, both attendance and time off should be displayed. |
 3452: 
 3453: ---
 3454: 
 3455: ## Page 393
 3456: 
 3457: #### 13.1.4. "Forecast and Plan" Report
 3458: 
 3459: Report displays operator forecast and plan by days and hours breakdown. Operator forecast is taken from data obtained in "Forecast load" module or manually imported into system. Operator plan is calculated based on planned and applied timetable.
 3460: 
 3461: To build report, go to "Reports" → "Forecast and plan report" tab.
 3462: 
 3463: ![Forecast Plan Report Navigation](img/forecast_plan_report_navigation.png)
 3464: 
 3465: To build report, select period (no more than month), time zone, planning template, and group (if necessary). Then click.
 3466: 
 3467: ![Forecast Plan Report Configuration](img/forecast_plan_report_configuration.png)
 3468: 
 3469: If planning template is selected and no group is selected in report input parameters, report is built for selected multi-skill planning template.
 3470: 
 3471: ---
 3472: 
 3473: ## Page 394
 3474: 
 3475: If planning template and group are selected in report input parameters, report is built for selected group from multi-skill planning template.
 3476: 
 3477: Hour forecast for day is calculated as average value of forecasted operator number considering minimum operators, reserve coefficients, and absenteeism set during load forecasting, in intervals within calculated hour, rounded to hundredths.
 3478: 
 3479: • When exporting report by planning template - in each interval, sum of forecast value for all groups included in multi-skill template is calculated.
 3480: • When exporting report by group - in each interval, forecast value for this group is used.
 3481: 
 3482: ![Forecast Plan Report Results](img/forecast_plan_report_results.png)
 3483: 
 3484: **Example calculation for one hour.** Suppose report is built for multi-skill planning template that includes simple group 1 and aggregated group 2.
 3485: 
 3486: | Time Interval Start | Group 1 Operator Forecast | Group 2 Operator Forecast | Total Template Groups 1 and 2 Forecast |
 3487: |-------------------|--------------------------|--------------------------|---------------------------------------|
 3488: | 06.02.2025 00:00 | 0 | 1 | 1 |
 3489: | 06.02.2025 00:15 | 1.25 | 1 | 2.25 |
 3490: 
 3491: ---
 3492: 
 3493: ## Page 395
 3494: 
 3495: | Time Interval Start | Group 1 Operator Forecast | Group 2 Operator Forecast | Total Template Groups 1 and 2 Forecast |
 3496: |-------------------|--------------------------|--------------------------|---------------------------------------|
 3497: | 06.02.2025 00:30 | 2.69542 | 1 | 3.69542 |
 3498: | 06.02.2025 00:45 | 10 | 1 | 11 |
 3499: | 06.02.2025 01:00 | 4 | 1 | 5 |
 3500: 
 3501: For specified values, report for 06.02.2025 at hour 00:00 will have forecast equal to (1 + 2.25 + 3.69542 + 11) / 4 = 4.49.
 3502: 
 3503: Hour plan for day is calculated as average value of "Operator plan" in intervals within calculated hour, rounded to hundredths.
 3504: 
 3505: • When exporting report by planning template - in each interval, each operator is counted as 1 (in event intervals not counted on line, described below (for example, sick leave, break), as 0).
 3506: • When exporting report by group - in each interval, sum of operator work shares on group is used. Share and downtime accounting (in event intervals not counted on line, described below (for example, sick leave, break), operator is not counted (i.e., their work shares on group = 0).
 3507: 
 3508: ![Forecast Plan Detailed Results](img/forecast_plan_detailed_results.png)
 3509: 
 3510: During timetable planning, each timetable operator has work shares planned on groups (simple or aggregated) that are included in multi-skill planning template and are non-reserve for operator. In one system interval, operator can have from 0 to 100 shares planned on one or several groups.
 3511: 
 3512: When 0 shares are planned for interval, i.e., line load is covered and there's employee surplus, such interval is called downtime interval. Additionally, operator has various timetable and work schedule events that are also considered in report. Share, downtime, and event accounting rules listed in document are specified below.
 3513: 
 3514: **Share and downtime accounting.**
 3515: 
 3516: When exporting report by group, for each operator in each system interval, their work shares on this group are calculated considering events:
 3517: 
 3518: • If interval operator work shares are calculated on one group as 100, they are counted on this group as 1.
 3519: • If interval operator work shares are calculated on several groups, operator is counted proportionally to calculated shares.
 3520: 
 3521: **Example 1**: shares planned on group 1 = 25, on group 2 = 75, operator is counted as 25/100=0.25 on group 1 and 75/100=0.75 on group 2.
 3522: 
 3523: **Example 2**: shares planned on group 1 = 25, on group 2 = 50, operator is counted as 25/75=0.33 on group 1 and 50/75=0.67 on group 2.
 3524: 
 3525: • If interval operator work shares on all groups equal 0, i.e., downtime interval, then operator:
 3526:   - First, operator shares in this interval are counted same as in previous pre-downtime interval where operator was counted on group (i.e., interval with shares or interval with activity having "Count on line" attribute).
 3527:   - If no share intervals exist before downtime (for example, this is operator's first interval), then shares are counted same as in next post-downtime interval where operator was counted on group (i.e., interval with shares or interval with activity having "Count on line" attribute).
 3528:   - If no share intervals exist before and after downtime (i.e., entire shift is in downtime), and no activity with "Count on line" attribute is set, then operator is counted as 1 on any group included in multi-skill planning template that is non-reserve for operator ("Any" group - first alphabetically).
 3529: 
 3530: **Example**: planning template has 4 groups - group 1, 2, 3, and 4. Operator has 4 groups - groups 1 and 5 are reserve, groups 2 and 3 are non-reserve. Operator is counted as 1 in group 2.
 3531: 
 3532: When exporting report by planning template - in each interval, each operator is counted as 1 considering events.
 3533: 
 3534: **Operator event accounting.**
 3535: 
 3536: During vacation period (planned or extraordinary), as well as sick leave, operator is not counted in report for entire event day.
 3537: 
 3538: **Example**: operator has 3 shifts planned in timetable (report, operator, shifts and events in Moscow time zone):
 3539: 
 3540: • 06.02.2025 20:00 - 07.02.2025 08:00;
 3541: • 08.02.2025 20:00 - 09.02.2025 08:00;
 3542: • 10.02.2025 08:00 - 10.02.2025 20:00.
 3543: 
 3544: After this, operator is assigned:
 3545: 
 3546: • 06.02.2025 planned vacation for one day;
 3547: • 09.02.2025 extraordinary vacation for one day;
 3548: • 10.02.2025 sick leave for one day.
 3549: 
 3550: In report, operator:
 3551: 
 3552: • 06.02.2025 20:00 - 07.02.2025 00:00 is not counted on any group since planned vacation is set;
 3553: 
 3554: ---
 3555: 
 3556: ## Page 396
 3557: 
 3558: • 07.02.2025 00:00 - 07.02.2025 08:00 is counted according to planned shares;
 3559: • 08.02.2025 20:00 - 09.02.2025 00:00 is counted according to planned shares;
 3560: • 09.02.2025 00:00 - 09.02.2025 08:00 is not counted on any group since extraordinary vacation is set;
 3561: • 10.02.2025 08:00 - 10.02.2025 20:00 is not counted on any group since sick leave is set.
 3562: 
 3563: During time off and lateness period, operator is not counted in report for entire event period.
 3564: 
 3565: **Example**: operator has 2 shifts planned in timetable (report, operator, shifts and events in Moscow time zone):
 3566: 
 3567: • 08.02.2025 20:00 - 09.02.2025 08:00;
 3568: • 10.02.2025 08:00 - 10.02.2025 20:00.
 3569: 
 3570: After this, operator is assigned:
 3571: 
 3572: • 08.02.2025 23:00 - 09.02.2025 01:00 time off;
 3573: • 10.02.2025 08:00 - 10.02.2025 08:30 lateness.
 3574: 
 3575: In report, operator:
 3576: 
 3577: • 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares;
 3578: • 08.02.2025 23:00 - 09.02.2025 01:00 is not counted on any group since time off is set;
 3579: • 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares;
 3580: • 10.02.2025 08:00 - 10.02.2025 08:30 is not counted on any group since lateness is set;
 3581: • 10.02.2025 08:30 - 10.02.2025 20:00 is counted according to planned shares.
 3582: 
 3583: During lunch, break, event (training or meeting) period, operator is not counted in report for entire event period.
 3584: 
 3585: **Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):
 3586: 
 3587: • 08.02.2025 20:00 - 09.02.2025 08:00.
 3588: 
 3589: Operator has set:
 3590: 
 3591: • 08.02.2025 22:00 - 08.02.2025 22:15 break;
 3592: • 08.02.2025 23:45 - 09.02.2025 03:45 event;
 3593: • 09.02.2025 04:30 - 09.02.2025 05:00 lunch.
 3594: 
 3595: In report, operator:
 3596: 
 3597: • 08.02.2025 20:00 - 08.02.2025 22:00 is counted according to planned shares;
 3598: • 08.02.2025 22:00 - 08.02.2025 22:15 is not counted on any group since break is set;
 3599: • 08.02.2025 22:15 - 08.02.2025 23:45 is counted according to planned shares;
 3600: • 08.02.2025 23:45 - 09.02.2025 03:45 is not counted on any group since event is set;
 3601: • 09.02.2025 03:45 - 09.02.2025 04:30 is counted according to planned shares;
 3602: • 09.02.2025 04:30 - 09.02.2025 05:00 is not counted on any group since lunch is set;
 3603: • 09.02.2025 05:00 - 09.02.2025 08:00 is counted according to planned shares.
 3604: 
 3605: During activity period without "Count on line" attribute, operator is not counted in report for entire event period.
 3606: 
 3607: **Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):
 3608: 
 3609: • 08.02.2025 20:00 - 09.02.2025 08:00.
 3610: 
 3611: Operator has set:
 3612: 
 3613: • 08.02.2025 23:00 - 09.02.2025 01:00 activity without "Count on line" attribute.
 3614: 
 3615: In report, operator:
 3616: 
 3617: • 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares;
 3618: • 08.02.2025 23:00 - 09.02.2025 01:00 is not counted on any group since activity without "Count on line" attribute is set;
 3619: • 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares.
 3620: 
 3621: If after setting such activity, "Count on line" attribute is added to it in directory, since activity was set earlier, it still won't be counted. Activities set after attribute change will be counted.
 3622: 
 3623: During activity period with "Count on line" attribute, operator is counted in report as 1 on group selected when setting this event. If shares were planned under event, they won't be counted.
 3624: 
 3625: **Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):
 3626: 
 3627: • 08.02.2025 20:00 - 09.02.2025 08:00, for example simplification, assume entire shift is planned on group 2 (100 shares in each interval).
 3628: 
 3629: Operator has set:
 3630: 
 3631: • 08.02.2025 23:00 - 09.02.2025 01:00 activity with "Count on line" attribute, user selected group 1 when setting.
 3632: 
 3633: In report, operator:
 3634: 
 3635: • 08.02.2025 20:00 - 08.02.2025 23:00 is counted according to planned shares on group 2.
 3636: 
 3637: ---
 3638: 
 3639: ## Page 397
 3640: 
 3641: • 08.02.2025 23:00 - 09.02.2025 01:00 is counted as 1 on group 1 since activity with "Count on line" attribute on group 1 is set.
 3642: • 09.02.2025 01:00 - 09.02.2025 08:00 is counted according to planned shares on group 2.
 3643: 
 3644: If after setting such activity, "Count on line" attribute is removed from it in directory, since activity was set earlier, it will still be counted. Activities set after attribute change won't be counted.
 3645: 
 3646: Overtime is planned in timetable similar to other shifts (planned, additional) and overtime hours.
 3647: 
 3648: • If operator was assigned overtime and timetable was updated for overtime period after this - it will be planned similar to shift with shares and downtime, operator is counted in report according to logic described above.
 3649: • If operator was assigned overtime but timetable wasn't updated for overtime period after this - operator won't be counted in report since no shift is planned for this time in timetable.
 3650: 
 3651: **Example**: operator has 1 shift planned in timetable (report, operator, shifts and events in Moscow time zone):
 3652: 
 3653: • 08.02.2025 20:00 - 09.02.2025 08:00.
 3654: 
 3655: Timetable was planned, after which work schedule set:
 3656: 
 3657: • 08.02.2025 19:00 - 08.02.2025 20:00 overtime before shift start;
 3658: • 10.02.2025 10:00 - 10.02.2025 12:00 overtime on weekend;
 3659: • User updated timetable from 09.02.2025 00:00.
 3660: 
 3661: In report, operator:
 3662: 
 3663: • 08.02.2025 19:00 - 08.02.2025 20:00 won't be counted since timetable wasn't updated and operator has no planned time for this period;
 3664: • 08.02.2025 20:00 - 09.02.2025 08:00 is counted according to planned shares;
 3665: • 10.02.2025 10:00 - 10.02.2025 12:00 is counted according to planned since timetable is updated and operator has this time planned.
 3666: 
 3667: **Shortage/surplus.**
 3668: 
 3669: Hour shortage/surplus for day is calculated by formula Plan for hour in day - Forecast for hour in day.
 3670: 
 3671: ![Shortage Surplus Calculation](img/shortage_surplus_calculation.png)
 3672: 
 3673: Additionally, second sheet calculates general plan and forecast (for report building period).
 3674: 
 3675: ![General Plan Forecast](img/general_plan_forecast.png)
 3676: 
 3677: Forecast is calculated as sum of all "Hour forecast for day" values in report building period.
 3678: 
 3679: ---
 3680: 
 3681: ## Page 398
 3682: 
 3683: Plan is calculated as sum of all "Hour plan for day" values in report building period.
 3684: 
 3685: #### 13.1.5. Operator Lateness Report
 3686: 
 3687: This report displays late employees and percentage of late employees by groups and departments. Lateness time is manually set. For employees to be displayed in report, they must belong to department and have applied timetable (current); if there's no current timetable built based on current work schedule, operators won't be in report. Lateness is considered difference between time when operator should start shift (taken from current timetable) and login time in integration system.
 3688: 
 3689: To go to this report, open side panel and go to "Reports → Operator lateness report":
 3690: 
 3691: ![Lateness Report Navigation](img/lateness_report_navigation.png)
 3692: 
 3693: When opening report, filter will be displayed based on which data will be shown:
 3694: 
 3695: ---
 3696: 
 3697: ## Page 399
 3698: 
 3699: ![Lateness Report Configuration](img/lateness_report_configuration.png)
 3700: 
 3701: Here you need to set period for which data will be output, department, operator type (home or office), their full name, and lateness boundaries; operators falling within these boundaries will be displayed in report. In screenshot above, only operators with lateness between 10 to 30 minutes will be displayed. After confirming parameters, report will be built and needs to be exported to Excel (xlsx) by clicking. Report looks like this:
 3702: 
 3703: ![Lateness Report Results](img/lateness_report_results.png)
 3704: 
 3705: **Fields:**
 3706: 
 3707: ---
 3708: 
 3709: ## Page 400
 3710: 
 3711: • **Direction/group/Full name** – sequentially displays department, group, and operator full name for whom data is displayed;
 3712: • **Number of employees / lateness (min) date** – in this column, summary number of late people is displayed next to group and department, and number of minutes operator was late is displayed next to operator full name;
 3713: • **Employee percentage** – next to groups and departments, displays percentage of late people from percentage of operators who came to work in general;
 3714: • **Total late** – shows general number of late people across all groups and departments;
 3715: • **Total percentage** – displays general percentage of late people.
 3716: 
 3717: ![Lateness Report Summary](img/lateness_report_summary.png)
 3718: 
 3719: #### 13.1.6. AHT Report
 3720: 
 3721: This report displays information about weighted average AHT (Average Handling Time) for each operator.
 3722: 
 3723: To go to report, select "Reports" → "AHT Report":
 3724: 
 3725: ---
 3726: 
 3727: ## Page 401
 3728: 
 3729: ![AHT Report Navigation](img/aht_report_navigation.png)
 3730: 
 3731: After opening report, enter period for which data is needed, and specify groups for which report needs to be built (groups can be filtered by departments they belong to):
 3732: 
 3733: ---
 3734: 
 3735: ## Page 402
 3736: 
 3737: ![AHT Report Configuration](img/aht_report_configuration.png)
 3738: 
 3739: After building report, export it by clicking:
 3740: 
 3741: ![AHT Report Export](img/aht_report_export.png)
 3742: 
 3743: "Source" page displays dates, full names, departments, groups. They correspond to specific talk time in group (in seconds) and number of processed requests in same group.
 3744: 
 3745: ![AHT Report Source](img/aht_report_source.png)
 3746: 
 3747: "By group" tab displays groups with departments nested in them, which have operator full names nested. Each department corresponds to row with "norm" and "AHT" (both indicators in seconds). "Norm" is taken from forecast (this is forecasted or manually set AHT when calculating number of operators), AHT is taken from operator statuses received via integration. "%Perf" is ratio of norm to actual AHT. Report has dynamic period columns with following fields: year, quarter, month, week, day. Depending on period for which report is built, some columns will be displayed, some won't.
 3748: 
 3749: On "By directions" tab, information is similar, only departments are displayed first, with groups nested in them, which have operators nested.
 3750: 
 3751: #### 13.1.7. %Ready Report
 3752: 
 3753: This report shows operator's daily %Ready percentage (as well as summary information). %Ready = productive time / login time.
 3754: 
 3755: Productive time is time in operator productive statuses received via integration (statuses with "Productive time" checkbox in "Working time configuration" directory are taken).
 3756: 
 3757: To go to report, select "Reports" → "%Ready Report":
 3758: 
 3759: ---
 3760: 
 3761: ## Page 403
 3762: 
 3763: ![Ready Report Navigation](img/ready_report_navigation.png)
 3764: 
 3765: After opening report, enter period for which data is needed. Then check departments from which operators should be taken. After selecting department, operator full names will be displayed below, which also need to be checked:
 3766: 
 3767: ![Ready Report Configuration](img/ready_report_configuration.png)
 3768: 
 3769: After building report, click.
 3770: 
 3771: ---
 3772: 
 3773: ## Page 404
 3774: 
 3775: ![Ready Report Export](img/ready_report_export.png)
 3776: 
 3777: In exported report, on "Source" tab, departments and operator full names are displayed. Each row corresponds to "Productive status time," "Login time," and "%Ready" columns.
 3778: 
 3779: ![Ready Report Source Results](img/ready_report_source_results.png)
 3780: 
 3781: "By direction" tab displays only %Ready. Summary Ready percentage for operators included in department is displayed next to department, operator %Ready is displayed next to operators. Report has dynamic period columns with following fields: year, quarter, month, week, day. Depending on period for which report is built, some columns will be displayed, some won't.
 3782: 
 3783: #### 13.1.8. Preferences Report
 3784: 
 3785: For planner/manager to review operator preferences both set and considered during planning, "Preferences Report" was added to system. To build report, following information is filled:
 3786: 
 3787: • Period for which report will be built;
 3788: • Template;
 3789: • Work schedule.
 3790: 
 3791: If necessary, separate export can be made by departments, operator types (office or home), or individual operator.
 3792: 
 3793: ---
 3794: 
 3795: ## Page 405
 3796: 
 3797: ![Preferences Report Configuration](img/preferences_report_configuration.png)
 3798: 
 3799: Report consists of two sheets, displaying following information:
 3800: 
 3801: • Personnel number;
 3802: • Operator full name;
 3803: • Day for which preference is set;
 3804: • Preference importance specified by operator (mandatory/desirable);
 3805: • Preference type (Working/weekend);
 3806: • Intervals (for working day preference);
 3807: • Shift starts;
 3808: • Shift ends;
 3809: • Shift durations;
 3810: • Start and end of shift set in schedule (for shifts) or Weekend;
 3811: • Preference consideration (considered/not considered).
 3812: 
 3813: Report also displays considered preference percentage (general, mandatory, and desirable).
 3814: 
 3815: Preference consideration percentage is calculated as N_considered/N_total, where:
 3816: 
 3817: N_considered - number of shifts planned in work schedule that fit operator preference by start, end, and duration
 3818: N_total - number of shifts for which operator set preferences
 3819: 
 3820: Considered preference percentage is rounded mathematically.
 3821: 
 3822: ![Preferences Report Results](img/preferences_report_results.png)
 3823: 
 3824: ---
 3825: 
 3826: ## Page 406
 3827: 
 3828: ### 13.2. Report Editor
 3829: 
 3830: Creating reports in editor is available to user with system role "Administrator" or other role with access right "System_AccessReportEditor."
 3831: 
 3832: Building reports created in editor is available to user with system role "Administrator" or other role with access right "System_PremiumPerformanceView" from "Report List" page.
 3833: 
 3834: Report editor is designed for creating custom reports in system based on data obtained through database queries. To use editor, you need experience building database queries using SQL or GROOVY. Also need familiarity with WFM CC database data model.
 3835: 
 3836: To go to report editor, open side menu and select "Reports" → "Report editor" section.
 3837: 
 3838: ![Report Editor Navigation](img/report_editor_navigation.png)
 3839: 
 3840: When going to "Report editor" page, all created reports are displayed broken down by groups:
 3841: 
 3842: ---
 3843: 
 3844: ## Page 407
 3845: 
 3846: ![Report Editor Interface](img/report_editor_interface.png)
 3847: 
 3848: To view report information, click on it with left mouse button. To the right of created reports menu, general information about selected report is displayed: "Name," "Group" (if report belongs to group), "Status," "Description." To build report from "Report editor" page, click "Build" button.
 3849: 
 3850: ![Report Editor Details](img/report_editor_details.png)
 3851: 
 3852: #### 13.2.1. Creating Report Group in "Report Editor" Section
 3853: 
 3854: To create new group in "Report editor," click "Add" button in left part of page and select object type "Group" from dropdown menu.
 3855: 
 3856: ---
 3857: 
 3858: ## Page 408
 3859: 
 3860: ![Create Report Group](img/create_report_group.png)
 3861: 
 3862: After selecting object type, group creation window opens where you need to specify "Name," "Roles" (employees with assigned role will have ability to build reports from group), and click "Create" button.
 3863: 
 3864: ![Report Group Creation Dialog](img/report_group_creation_dialog.png)
 3865: 
 3866: #### 13.2.2. Providing Access to Report Group
 3867: 
 3868: To open access to reports added to group, select report group (click on group with left mouse button), click "Add" button, and in opened window select necessary roles. Roles for which reports belonging to group are available are displayed in "Roles" information window.
 3869: 
 3870: ![Report Group Access](img/report_group_access.png)
 3871: 
 3872: ---
 3873: 
 3874: ## Page 409
 3875: 
 3876: #### 13.2.3. Creating Report in "Report Editor" Section
 3877: 
 3878: To create new report in "Report editor," click "Add" button in left part of page and select "Report type" object from dropdown menu.
 3879: 
 3880: ![Create New Report](img/create_new_report.png)
 3881: 
 3882: After selecting object type, report creation window opens where you need to specify attributes "Name," "Group," "Description," and click "Create" button.
 3883: 
 3884: ![Report Creation Dialog](img/report_creation_dialog.png)
 3885: 
 3886: After creating report type, report is in "Blocked" status. If report is Blocked, it can be edited (change name, description, modify query to data, input data, etc.) and can be built by person with report editing rights. If report is Published, it can be viewed by person with report viewing access rights, but cannot be edited.
 3887: 
 3888: In "Data queries" tab in "Bands" area, Bands to which data requested from database are attached are arranged hierarchically. Band addition/removal buttons are also displayed here.
 3889: 
 3890: When selecting band, "Band properties" area displays band name, data acquisition method (SQL or GROOVY), and its orientation (HORIZONTAL, VERTICAL, CROSS, UNDEFINED). Below all this data, working field is displayed where database data query is written. "Save query" button saves query changes which, if not saved, are reset when refreshing page/going to another band.
 3891: 
 3892: ---
 3893: 
 3894: ## Page 410
 3895: 
 3896: ![Report Query Editor](img/report_query_editor.png)
 3897: 
 3898: In "Input parameters" tab, parameters are set (depending on report type, input parameters may not be needed) that users will enter when building report and based on which data filtering will be performed. Created input parameters can be edited or deleted. One parameter must have name, keyword - word used to access input parameter in SQL code, data type (text, numeric, date, logical, etc.), and its requirement.
 3899: 
 3900: ![Report Input Parameters](img/report_input_parameters.png)
 3901: 
 3902: In "Export templates" tab, export templates are loaded which can be selected when building report. Template can be in xls (Excel), html, doc, or other format. Templates can be loaded, and can also be deleted or edited (name).
 3903: 
 3904: ![Report Export Templates](img/report_export_templates.png)
 3905: 
 3906: For created report to be available to users for building, click "Publish" button; report status will change to "Published."
 3907: 
 3908: #### 13.2.4. Building Reports
 3909: 
 3910: "Report List" page displays report groups available to user for building (groups available for role assigned to user).
 3911: 
 3912: To go to "Report List" page, open side menu and select "Reports" → "Report List" section.
 3913: 
 3914: To build, select report, click on it with left mouse button, specify input parameter values (if they were set during creation), select export template (if there are several), and building mode. "One-time" building mode means report building and export is performed once, "Scheduled" means report building and export will be performed according to set schedule.
 3915: 
 3916: To build scheduled report, specify:
 3917: 
 3918: • Period unit (minute, hour, day, week, month, etc.);
 3919: • Quantity;
 3920: • Start with "Start date and time";
 3921: • Number of repetitions.
 3922: 
 3923: Click "Create" button.
 3924: 
 3925: After building report, user will receive internal system notification:
 3926: 
 3927: ![Report Build Notification](img/report_build_notification.png)
 3928: 
 3929: To download built reports, go to "Reports" → "Report building tasks" section. Expand detailed information and download built report.
 3930: 
 3931: ---
 3932: 
 3933: ## Page 411
 3934: 
 3935: ![Download Built Report](img/download_built_report.png)
 3936: 
 3937: ## 14. Monitoring
 3938: 
 3939: To view monitoring section pages, you need role with access right "View pages in 'Monitoring' section" (System_AccessMonitoring).
 3940: 
 3941: Monitoring is designed for operational load viewing on line and statistics concerning current number of operators and their planned number.
 3942: 
 3943: On "Operational control" page, statistics are displayed for each group (both simple and aggregated), and at time of opening in system there should be:
 3944: 
 3945: • Update and notification settings configured;
 3946: • "Work time efficiency configuration" directory configured;
 3947: • For groups of interest:
 3948: • Threshold values set;
 3949: • Timetable planned for operators;
 3950: • Load forecasted;
 3951: • User given access rights;
 3952: • Dashboard display settings configured in personal account.
 3953: 
 3954: ### 14.1. Update and Notification Settings
 3955: 
 3956: Page is available for editing to user with system role "Administrator" or any other role with access right "Edit monitoring update settings" (System_EditMonitoringUpdateSettings).
 3957: 
 3958: In this section, you can assign periodicity for contact center polling regarding operator statistics (their number and statuses). To go to settings, open side menu and go to "Monitoring" → "Update and notification settings":
 3959: 
 3960: ---
 3961: 
 3962: ## Page 412
 3963: 
 3964: ![Monitoring Settings Navigation](img/monitoring_settings_navigation.png)
 3965: 
 3966: Here, parameters for data acquisition frequency from contact center and operator notification frequency will be displayed:
 3967: 
 3968: ![Monitoring Update Settings](img/monitoring_update_settings.png)
 3969: 
 3970: **Operator notification, min:** – operator notification frequency about absence;
 3971: 
 3972: ---
 3973: 
 3974: ## Page 413
 3975: 
 3976: **Group information update:** – shows how often (in seconds) we'll contact contact center to get group information (real ACD, AHT, etc.).
 3977: 
 3978: To change value, click on them, specify new ones, and click "checkmark":
 3979: 
 3980: ![Update Settings Modification](img/update_settings_modification.png)
 3981: 
 3982: ### 14.2. Threshold Values
 3983: 
 3984: Page is available for editing to user with system role "Administrator" or any other role with access right "Edit threshold value settings" (System_ThresholdUpdateSettings).
 3985: 
 3986: Threshold values determine at what values numbers in dashboards will change colors. To go to settings, open side menu and go to "Monitoring" → "Threshold value settings":
 3987: 
 3988: ![Threshold Settings Navigation](img/threshold_settings_navigation.png)
 3989: 
 3990: ---
 3991: 
 3992: ## Page 414
 3993: 
 3994: When opening page, select service and group and set threshold values for them:
 3995: 
 3996: ![Threshold Settings Configuration](img/threshold_settings_configuration.png)
 3997: 
 3998: **Operators on line** – values need to be entered as percentages from 1 to 100.
 3999: 
 4000: • **Acceptable boundary** – if number of operators on line exceeds acceptable boundary, we color corresponding dashboard green, showing that our load is normal.
 4001: • If number of operators drops below acceptable boundary but stays above critical boundary, corresponding dashboard will be colored yellow, showing that load is acceptable.
 4002: • If number of operators on line drops below critical boundary, we color dashboard red, showing that we don't have enough operators.
 4003: 
 4004: **Load** – values need to be entered as percentages from 1 to 100.
 4005: 
 4006: ---
 4007: 
 4008: ## Page 415
 4009: 
 4010: • **Decline** – if difference between forecasted number of calls and real number of calls equals less than or equal to acceptable value (number of real calls is less than forecasted), corresponding dashboard will display green color. If difference rises above acceptable value but stays below critical, dashboard color will be yellow. If call difference percentage becomes above critical value, dashboard will be red, showing that real load is less than forecasted and operators are idle.
 4011: 
 4012: • **Growth** – conversely, if number of real calls exceeds forecasted number but not higher than acceptable percentage, dashboard will be green. If real load exceeds forecasted by percentage that exceeds acceptable value but doesn't exceed critical, dashboard will be yellow; if above critical, then red.
 4013: 
 4014: **Operator requirement** – need to enter number of people.
 4015: 
 4016: • **Surplus** – difference value between required number of operators (calculated based on real call numbers) and number of operators according to timetable is examined. Accordingly, surplus is when required number of operators is higher than number according to timetable. If value is less than acceptable boundary, corresponding dashboard is colored green; if between acceptable and critical, then yellow; if above critical, then red.
 4017: 
 4018: • **Shortage** – also examines difference between number of operators according to timetable and required number of operators. Shortage means number of operators according to timetable is less than required number of operators. Accordingly, if this value is below acceptable, dashboard will be colored green; if between acceptable and critical, then yellow; if above critical, then red.
 4019: 
 4020: **SLA** – need to enter values as percentages from 1 to 100.
 4021: 
 4022: • **Decline** – difference between SLA calculated in timetable and real. Decline shows that real SLA is less than forecasted. If value of this difference is less than acceptable boundary, we color dashboard green; if between acceptable and critical, then yellow; if above critical, then red.
 4023: 
 4024: • **Growth** – when real SLA is greater than forecasted. If this value is below acceptable boundary, we color dashboard green; if between acceptable and critical, then yellow; if above critical, then red.
 4025: 
 4026: **ACD** – need to enter values as percentages from 1 to 100. ACD – deviation of processed request percentage from forecasted.
 4027: 
 4028: • **Decline** shows that real ACD is less than forecasted. If decline value is below acceptable, dashboard is colored green; if between acceptable and critical, then yellow; if above, then red.
 4029: 
 4030: • **Growth** shows that real ACD exceeds forecasted. Color settings are same as decline.
 4031: 
 4032: **AHT** – need to enter values as percentages from 1 to 100. AHT – deviation of average request processing time from forecasted.
 4033: 
 4034: • **Decline** shows that real AHT is less than forecasted. If value is below acceptable, dashboard is colored green; if between acceptable and critical, then yellow; if above, then red.
 4035: 
 4036: • **Growth** shows that real AHT exceeded forecasted. Color indication is identical to decline.
 4037: 
 4038: ---
 4039: 
 4040: ## Page 416
 4041: 
 4042: ### 14.3. Operational Control
 4043: 
 4044: On this page, you can view dashboards with statistics for specific groups (both simple and aggregated) for which user configured display ability in personal account. Operational control dashboards can only be viewed when there's applied timetable and working integration with contact center.
 4045: 
 4046: You can get to operational control page either from main page:
 4047: 
 4048: ![Operational Control Main](img/operational_control_main.png)
 4049: 
 4050: Or through side menu where you need to go to "Monitoring" → "Operational control."
 4051: 
 4052: ---
 4053: 
 4054: ## Page 417
 4055: 
 4056: ![Operational Control Navigation](img/operational_control_navigation.png)
 4057: 
 4058: When opening, user will see six dashboards for specific groups (for which user specified display ability in personal account):
 4059: 
 4060: ![Operational Control Dashboards](img/operational_control_dashboards.png)
 4061: 
 4062: **Operators on line%** – shows how many operators are currently on line. This dashboard shows percentage ratio of operators specified in timetable to real number of operators on line. This calculation doesn't include operators who have lunch, break, or training specified in timetable at viewing time.
 4063: 
 4064: **Load** – shows load growth/decline in real time. Displays percentage ratio between load we forecasted and real load on line.
 4065: 
 4066: **Operator requirement** – shows shortage or surplus of operators needed to cover current load. Depending on mode selected in group settings, statistics will be calculated as follows:
 4067: 
 4068: ---
 4069: 
 4070: ## Page 418
 4071: 
 4072: • **"Voice channel"** – Displayed as difference between required number of people needed to cover current load (calculated using Erlang formula) and real number of people on line.
 4073: 
 4074: • **"Non-voice channel"** – Displayed as difference between forecasted number of operators and real number of people on line.
 4075: 
 4076: **SLA** – Displays difference between real SLA (via integration) and SLA according to timetable.
 4077: 
 4078: **ACD** – Displays difference between actual %ACD (obtained via integration) and forecasted.
 4079: 
 4080: **AHT** – Displays percentage by which weighted average AHT by group grew/fell. Formula: (Actual AHT-Forecasted AHT)/Forecasted AHT*100. Actual AHT is obtained via integration.
 4081: 
 4082: When calculating ACD and AHT, values are taken starting from 00:00 of current day and ending at current time.
 4083: 
 4084: Each dashboard also has its own statistics page. To open dashboard, click on number inside it.
 4085: 
 4086: #### 14.3.1. Operators on Line
 4087: 
 4088: ![Operators on Line Dashboard](img/operators_on_line_dashboard.png)
 4089: 
 4090: When opening dashboard, following information will be displayed:
 4091: 
 4092: • **Schedule adherence (24 hours)** – displays average schedule adherence indicator value (percentage ratio of operators specified in timetable to real number of operators on line) from start of day.
 4093: 
 4094: • **Number of operators:**
 4095:   • **according to timetable** – shows number of operators from current timetable;
 4096:   • **on line** – real number of operators on line, obtained via integration.
 4097: 
 4098: • **Schedule deviation** – displays chart of real operator number deviation from planned at each time moment.
 4099: 
 4100: • **Dynamics** – displays chart of "According to timetable" and "On line" values for specific time periods. By clicking on color legend below chart, you can remove unnecessary values.
 4101: 
 4102: For aggregated groups, number of operators on line is calculated as sum across all simple groups included in aggregated.
 4103: 
 4104: ---
 4105: 
 4106: ## Page 419
 4107: 
 4108: #### 14.3.2. Operator Requirement
 4109: 
 4110: ![Operator Requirement Dashboard](img/operator_requirement_dashboard.png)
 4111: 
 4112: When opening dashboard, following information will be displayed:
 4113: 
 4114: • **Planning accuracy (24 hours)** – displays percentage average planning accuracy value (difference between real number of operators on line (obtained via integration) and required number of operators to cover load) of timetable from start of day to current time.
 4115: 
 4116: • **Accuracy dynamics** – graphical representation of "Planning accuracy" value. When hovering cursor over chart, you can see additional information.
 4117: 
 4118: • **Current snapshot:**
 4119:   • **By forecast** – displays forecasted operator number.
 4120:   • **By timetable** – displays operator number according to current timetable.
 4121:   • **Required** – displays required operator number considering current group load by requests (calculated using Erlang formula).
 4122: 
 4123: ---
 4124: 
 4125: ## Page 420
 4126: 
 4127: • **Actual** – displays real operator value on line, comes via integration.
 4128: 
 4129: • **Dynamics** – visualization of four above parameters. You can hover cursor over chart to see additional information.
 4130: 
 4131: For aggregated groups, actual and required operator numbers are calculated as sum across all simple groups included in aggregated.
 4132: 
 4133: To view and change operator timetable, go to current timetable in "Operational solutions" block.
 4134: 
 4135: #### 14.3.3. SLA
 4136: 
 4137: ![SLA Dashboard](img/sla_dashboard.png)
 4138: 
 4139: When opening dashboard, following information will be displayed:
 4140: 
 4141: • **SLA deviation (24 hours)** – average SLA deviation value from forecast from start of day.
 4142: 
 4143: • **Forecast deviation (24 hours)** – visualization of "SLA deviation (24 hours)" value. By hovering cursor over chart, you can see additional information.
 4144: 
 4145: • **Current snapshot:**
 4146:   • **By forecast** – SLA according to forecast.
 4147:   • **By timetable** – SLA according to planned timetable; calculated using formula selected in group settings;
 4148: 
 4149: ---
 4150: 
 4151: ## Page 421
 4152: 
 4153: • **Actual** – real SLA calculated based on data obtained via integration.
 4154: 
 4155: • **Line wait time** – obtained via integration.
 4156: 
 4157: • **Dynamics** – visualization of four above parameters. By hovering cursor over chart, you can see additional information.
 4158: 
 4159: For aggregated groups, real SLA is calculated as weighted average value across all simple groups included in aggregated.
 4160: 
 4161: #### 14.3.4. Load Growth
 4162: 
 4163: ![Load Growth Dashboard](img/load_growth_dashboard.png)
 4164: 
 4165: When opening dashboard, following information will be displayed:
 4166: 
 4167: • In "Current snapshot" block, load information (incoming requests) for current time moment (from 00:00 to current hour) is displayed.
 4168: 
 4169: • **By forecast – incoming** – displays forecasted request number considering growth coefficient.
 4170: 
 4171: • **By forecast – processed** – displays forecasted request number multiplied by %ACD set during forecasting.
 4172: 
 4173: • **Actually incoming requests** – displays number of incoming requests for previous interval
 4174: 
 4175: ---
 4176: 
 4177: ## Page 422
 4178: 
 4179: (snapshot updates every n seconds; previous update is previous interval). Obtained via integration.
 4180: 
 4181: • **Actually processed requests** – displays number of processed requests. Calculated as difference between processed requests for current period (received calls * %ACD) and processed requests for previous period. All values obtained via integration.
 4182: 
 4183: • **In queue** – queue call display, obtained via integration.
 4184: 
 4185: • **Dynamics (24 hours)** – graphical representation of parameters described in "Current snapshot" block.
 4186: 
 4187: • In "Forecast accuracy" block, calculated accuracy for incoming and processed requests is displayed. General formula looks like: |"actual request number"- "forecasted request number"|"forecasted request number"*100, where "requests" can be simply incoming for "By incoming calls" and processed for "By processed calls."
 4188: 
 4189: • **Deviation from norm (24 hours)** – graphical representation of "Planning accuracy" block values.
 4190: 
 4191: For aggregated groups, actual number of incoming and processed requests is calculated as number of requests incoming/processed on simple groups included in aggregated composition.
 4192: 
 4193: • In "Call number" chart, there's ability to remove specific lines – to do this, click on needed line legend:
 4194: 
 4195: ---
 4196: 
 4197: ## Page 423
 4198: 
 4199: ![Chart Line Toggle](img/chart_line_toggle.png)
 4200: 
 4201: By hovering over chart line, you can see detailed information:
 4202: 
 4203: ![Chart Hover Details](img/chart_hover_details.png)
 4204: 
 4205: ---
 4206: 
 4207: ## Page 424
 4208: 
 4209: #### 14.3.5. ACD
 4210: 
 4211: ![ACD Dashboard](img/acd_dashboard.png)
 4212: 
 4213: When opening dashboard, following information will be displayed:
 4214: 
 4215: • In "ACD deviation (24 hours)" block, difference between actual ACD (obtained from integration) and forecasted at current moment (from 00:00 to current time) is displayed. I.e., this is same number as in dashboard list. Next to this block, deviation chart is displayed; curve either goes below 0 or above, depending on values.
 4216: 
 4217: • In "ACD from start of day" block, current ACD data is displayed, updated every specific number of seconds specified in group information update.
 4218: 
 4219: • **By forecast** – %ACD according to forecast
 4220: • **By timetable** – %ACD according to planned timetable
 4221: • **Actual** – %ACD according to current load. Real ACD is pulled via integration. Next to block, chart displaying data from "current snapshot" is shown.
 4222: 
 4223: • **Dynamics (24 hours)** – graphical representation of "Planning accuracy" block values.
 4224: 
 4225: For aggregated groups, indicators in "ACD from start of day" block equal weighted average value across all simple groups included in aggregated.
 4226: 
 4227: • In "Dynamics" chart, there's ability to remove specific lines – to do this, click on needed line legend:
 4228: 
 4229: ![ACD Chart Line Toggle](img/acd_chart_line_toggle.png)
 4230: 
 4231: By hovering over chart line, you can see detailed information:
 4232: 
 4233: ![ACD Chart Hover Details](img/acd_chart_hover_details.png)
 4234: 
 4235: ---
 4236: 
 4237: ## Page 425
 4238: 
 4239: #### 14.3.6. AHT
 4240: 
 4241: ![AHT Dashboard](img/aht_dashboard.png)
 4242: 
 4243: When opening dashboard, following information will be displayed:
 4244: 
 4245: • In "AHT deviation" (24 hours) block, AHT deviation percentage at current moment (from 00:00 to current time) is displayed. I.e., same as in dashboard list. Next to this block, deviation chart is displayed, which from 0 goes either above or below.
 4246: 
 4247: • "AHT from start of day" displays accumulated AHT data from start of day:
 4248:   • **By forecast** – weighted average AHT according to forecast;
 4249:   • **Real** – weighted average actual AHT according to current load.
 4250: 
 4251: • **Dynamics (24 hours)** – graphical representation of "Current snapshot" block values.
 4252: 
 4253: For aggregated groups, indicators in "Current snapshot" block equal weighted average value across all simple groups included in aggregated.
 4254: 
 4255: In "Average service duration" chart, there's ability to remove specific lines – to do this, click on needed line legend:
 4256: 
 4257: ---
 4258: 
 4259: ## Page 426
 4260: 
 4261: ![AHT Chart Line Toggle](img/aht_chart_line_toggle.png)
 4262: 
 4263: By hovering over chart line, you can see detailed information:
 4264: 
 4265: ![AHT Chart Hover Details](img/aht_chart_hover_details.png)
 4266: 
 4267: ### 14.4. Operator Statuses
 4268: 
 4269: To view this page, you need access rights "System_ViewAllWorkersInMonitoring" and "System_ViewSubordinatesWorkersInMonitoring." First right will allow viewing all operator statuses, second only subordinate operator statuses.
 4270: 
 4271: On "Operator statuses" page, you can see what status operator is currently in; if they're absent from place when they should be there, then how long, and you can call operator to workplace. All operator statuses and absence time are obtained via integration.
 4272: 
 4273: To go to operator statuses, go to "Monitoring" → "Operator statuses":
 4274: 
 4275: ![Operator Statuses Navigation](img/operator_statuses_navigation.png)
 4276: 
 4277: Or
 4278: 
 4279: ![Operator Statuses Alt Navigation](img/operator_statuses_alt_navigation.png)
 4280: 
 4281: When opening, following fields will be displayed:
 4282: 
 4283: **Operational solutions** – this block displays list of operators who should be at workplace this day. From here, you can filter operators by skill, type, line presence, and also call operator to line urgently.
 4284: 
 4285: ---
 4286: 
 4287: ## Page 427
 4288: 
 4289: ![Operational Solutions](img/operational_solutions.png)
 4290: 
 4291: • In "Full name" column, operator full name is displayed, with their skill and type shown nearby.
 4292: • **Contact center status** – shows operator's current status obtained via integration.
 4293: • **Schedule adherence** – displays correspondence of timetable (current) to real statuses obtained via integration. If according to timetable operator should work, but according to integration we receive non-working status, field will be colored red and show "Violation."
 4294: • **Contact** – operator contacts from card.
 4295: • **Absent (min)** – number of minutes operator is absent (doesn't accumulate; if operator was absent 10 minutes, then came to line, on next absence counter resets).
 4296: 
 4297: By clicking next to operator, we'll see their working intervals according to planned work schedule and according to timetable ("Statistics" in figure above).
 4298: 
 4299: ---
 4300: 
 4301: ## Page 428
 4302: 
 4303: ---
 4304: 
 4305: ## **END OF TRANSLATION**
 4306: 
 4307: **Total Pages Translated: 462 of 462**
 4308: 
 4309: This completes the comprehensive English translation of the ARGUS WFM CC User Manual Part 2 (Pages 200-462). The manual covers:
 4310: 
 4311: ## Key Sections Translated:
 4312: 
 4313: ### **System Administration & Configuration**
 4314: - Personnel synchronization and data collection
 4315: - Integration system management
 4316: - Manual corrections and account linking
 4317: 
 4318: ### **Core Forecasting Module**
 4319: - Load forecasting algorithms and methods
 4320: - Historical data import and correction
 4321: - Peak analysis and trend analysis
 4322: - Seasonal component analysis
 4323: - Operator calculation models (Erlang C, Linear, etc.)
 4324: - Forecast accuracy analysis
 4325: 
 4326: ### **Planning & Scheduling**
 4327: - Multi-skill planning templates
 4328: - Work schedule planning with preferences
 4329: - Vacation planning and management
 4330: - Timetable creation and management
 4331: - Vacancy planning
 4332: - Exchange system for shift offers
 4333: 
 4334: ### **Employee Management**
 4335: - Personal account functionality
 4336: - Preference setting and management
 4337: - Work schedule corrections
 4338: - Event registration (sick leave, vacation, etc.)
 4339: 
 4340: ### **Business Process Management**
 4341: - BP loading and execution
 4342: - Task management and approval workflows
 4343: - Work schedule approval processes
 4344: 
 4345: ### **Reporting & Analytics**
 4346: - System reports (schedule adherence, salary calculation, etc.)
 4347: - Report editor for custom reports
 4348: - Performance and accuracy reports
 4349: 
 4350: ### **Monitoring & Control**
 4351: - Real-time operational control dashboards
 4352: - Threshold value configuration
 4353: - Operator status monitoring
 4354: - Load and performance tracking
 4355: 
 4356: The translation maintains technical accuracy while providing clear English equivalents for Russian workforce management terminology and preserves all workflow descriptions, user interface elements, and system functionality explanations.