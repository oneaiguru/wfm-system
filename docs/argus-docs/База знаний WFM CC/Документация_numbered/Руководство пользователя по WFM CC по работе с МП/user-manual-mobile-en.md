    1: # ARGUS WFM CC User Manual
    2: ## Workforce Management for Call Centre - User Guide (April 2025)
    3: 
    4: ### Table of Contents
    5: 
    6: 1. [Introduction](#introduction)
    7:    1. [About the ARGUS WFM CC System](#about-system)
    8:    2. [Goals of the ARGUS WFM CC System](#system-goals)
    9:    3. [Automation Object Characteristics](#automation-characteristics)
   10:    4. [Roles in the ARGUS WFM CC System](#system-roles)
   11: 
   12: 2. [Getting Started](#getting-started)
   13:    1. [System Login](#system-login)
   14:    2. [General Interface Description](#interface-description)
   15: 
   16: 3. [Administrator Workstation](#administrator-workstation)
   17:    1. [Reference Configuration](#reference-configuration)
   18:       1. [Work Rules Reference](#work-rules-reference)
   19:       2. [Events Reference](#events-reference)
   20:       3. [Production Calendar Reference](#production-calendar-reference)
   21:       4. [Roles Reference](#roles-reference)
   22:       5. [Positions Reference](#positions-reference)
   23:       6. [Work Time Efficiency Configuration Reference](#work-time-efficiency-reference)
   24:       7. [Special Events Reference](#special-events-reference)
   25:       8. [Labor Standards Reference](#labor-standards-reference)
   26:       9. [Breaks/Lunches Reference](#breaks-lunches-reference)
   27:       10. [Vacation Schemes Reference](#vacation-schemes-reference)
   28:       11. [Integration Systems Reference](#integration-systems-reference)
   29:       12. [Absence Reasons Reference](#absence-reasons-reference)
   30:       13. [Time Zones Reference](#time-zones-reference)
   31:       14. [Notification Scheme Reference](#notification-scheme-reference)
   32:       15. [Preferences Reference](#preferences-reference)
   33:       16. [Exchange Rules Settings Reference](#exchange-rules-reference)
   34:       17. [Payroll Report Reference](#payroll-report-reference)
   35:       18. [Channel Type Reference](#channel-type-reference)
   36:    2. [Personnel Configuration](#personnel-configuration)
   37:       1. [Employees](#employees)
   38:       2. [Groups](#groups)
   39:       3. [Services](#services)
   40:       4. [Departments](#departments)
   41:       5. [Mass Assignment of Business Rules and Vacation Schemes](#mass-assignment-business-rules)
   42:       6. [Mass Assignment of Work Hours](#mass-assignment-work-hours)
   43:       7. [Personnel Synchronization Reference](#personnel-synchronization-reference)
   44:       8. [Operator Data Collection](#operator-data-collection)
   45: 
   46: 4. [Load Forecasting in ARGUS WFM CC System](#load-forecasting)
   47: 5. [Load Viewing](#load-viewing)
   48: 6. [Multi-skill Planning Template](#multi-skill-planning-template)
   49: 7. [Work Schedule Planning](#work-schedule-planning)
   50: 8. [Timetable Planning](#timetable-planning)
   51: 9. [Vacancy Planning](#vacancy-planning)
   52: 10. [Exchange](#exchange)
   53: 11. [Employee Personal Cabinet](#employee-personal-cabinet)
   54: 12. [Business Processes (BPMS)](#business-processes)
   55: 13. [Reports](#reports)
   56: 14. [Monitoring](#monitoring)
   57: 
   58: ---
   59: 
   60: ## 1. Introduction {#introduction}
   61: 
   62: ### 1.1 About the ARGUS WFM CC System {#about-system}
   63: 
   64: **Full Name:** Call Center Management System "ARGUS Workforce Management for Call Centre"  
   65: **Short Name:** "ARGUS WFM CC" System
   66: 
   67: **System Purpose:**
   68: The "ARGUS WFM CC" system allows improving call center work quality through:
   69: 
   70: - Building optimal balance between required staffing levels and expected work volume
   71: - Planning employee work schedules based on work volume and qualifications
   72: - Forecasting call center load and its even distribution among employees
   73: - Strict schedule compliance
   74: 
   75: ### 1.2 Goals of the ARGUS WFM CC System {#system-goals}
   76: 
   77: Thanks to the system's ability to forecast incoming call center load and plan optimal schedules based on it:
   78: 
   79: - **Improved call center resource efficiency:** During low load periods, operators don't idle on the line and can be engaged in alternative work, while during medium load periods, operator workload is distributed evenly
   80: - **Improved customer service quality** through reduced queue waiting time; during peak loads, sufficient operators are available on the line
   81: - **Improved call center management efficiency** - senior operators - through automation of schedule and work shift creation
   82: 
   83: ### 1.3 Automation Object Characteristics {#automation-characteristics}
   84: 
   85: The automation objects include the following Customer services:
   86: 
   87: - **Senior operators** performing coordinating and administrative roles within operator groups
   88: - **Call center operators** handling incoming calls
   89: 
   90: Senior operators in their activities manage personnel, operator work schedules - shifts, vacations, sick leaves, time off, regulate mass events - training, meetings within operator groups. They create operator work schedules during the day - call handling time, lunch, technological breaks.
   91: 
   92: Operators in their activities handle incoming calls to the call center. For this activity, they need to understand and know in advance when according to the schedule they should be at their workplace to handle calls, when they can take lunch breaks, technological breaks.
   93: 
   94: ### 1.4 Roles in the ARGUS WFM CC System {#system-roles}
   95: 
   96: The system has the following system roles:
   97: 
   98: 1. **Operator** - belongs to one or several operator groups, handles calls coming to these groups or waiting in their call queues. The operator should be able to view their work schedule for proper workday organization - time periods allocated for technological breaks, lunch breaks, planned regular events - training, meetings, and actual working hours when the operator should be at their workplace taking calls.
   99: 
  100: 2. **Senior Operator** - along with regular operator functions, performs coordinating and administrative functions within the operator groups they belong to.
  101: 
  102:    Senior operator functions not automated by WFM:
  103:    - Consulting operators during call handling
  104:    - Monitoring operator calls
  105: 
  106:    Administrative functions automated by WFM:
  107:    - Setting up operators in the system
  108:    - Creating operator work schedules
  109:    - Setting operator work schedules/shifts
  110: 
  111: 3. **Administrator** - configures the system: maintaining work schedules, personnel structure, managing rights and user accounts, configuring and updating references
  112: 
  113: ## 2. Getting Started {#getting-started}
  114: 
  115: ### 2.1 System Login {#system-login}
  116: 
  117: To start working with the "ARGUS WFM CC" system:
  118: 
  119: 1. Open a browser (Mozilla Firefox, Microsoft Edge, Google Chrome, Opera, etc.)
  120: 2. Enter the address provided by the system administrator in the browser address bar
  121: 
  122: After entering the address, a start page opens requesting login and password for system access (login and password are provided by the WFM CC system administration representative):
  123: 
  124: ![Login Screen](img/login-screen.png)
  125: 
  126: 3. When login and password are entered correctly, the main system page opens
  127: 4. If incorrect login or password is entered, an appropriate error message is displayed:
  128: 
  129: ![Login Error](img/login-error.png)
  130: 
  131: ### 2.2 General Interface Description {#interface-description}
  132: 
  133: After correct login and password entry, the system start page opens:
  134: 
  135: ![Main Interface](img/main-interface.png)
  136: 
  137: Depending on access rights (Area 1), the following dashboards will be available to the user:
  138: 
  139: - **References:** Services, Groups, Employees, Work Schedule Templates, Roles, Business Rules
  140: - **Forecasting Module**
  141: - **Planning Module**
  142: - **My Cabinet**
  143: - **Reports**
  144: - **Monitoring**
  145: - **BPMS**
  146: 
  147: In the upper left part (Area 2) are located:
  148: - Return to start page button
  149: - Context menu button with list of sections (Figure 2.2.2) available to the user (depending on assigned access rights). Complete list of access rights is shown in figure 2.2.2:
  150: 
  151: ![Context Menu](img/context-menu.png)
  152: 
  153: To close the sections list menu, click the close button.
  154: 
  155: In the upper right part (Area 3, Figure 2.2.1) are located:
  156: 
  157: **Employee search bar** by surname (search by partial or full match):
  158: 
  159: ![Employee Search](img/employee-search.png)
  160: 
  161: To go to employee card, click on employee name with left mouse button.
  162: 
  163: - **"My Notifications" button** for notification availability
  164: - **"My Profile" button**
  165: 
  166: ![Profile Button](img/profile-button.png)
  167: 
  168: Clicking "My Profile" button navigates to user's "Personal Cabinet".
  169: 
  170: - **System information button:**
  171: 
  172: ![System Info](img/system-info.png)
  173: 
  174: Selecting this will generate an error report:
  175: 
  176: ![Error Report](img/error-report.png)
  177: 
  178: To save the generated error report, click "Save report".
  179: 
  180: To continue working in "ARGUS WFM CC", refresh the page (upon refresh, the page where the error occurred will open) or click the Argus logo (start page will open).
  181: 
  182: Selecting this will automatically start downloading the "ARGUS WFM CC" system user manual file.
  183: 
  184: **Language button** indicates the interface is displayed in Russian. To switch interface display to English, click it and select English.
  185: 
  186: **Exit button** - logout from "ARGUS WFM CC" system.
  187: 
  188: ## 3. Administrator Workstation {#administrator-workstation}
  189: 
  190: ### 3.1 Reference Configuration {#reference-configuration}
  191: 
  192: #### 3.1.1 Work Rules Reference {#work-rules-reference}
  193: 
  194: The reference is available for viewing to users with "View Work Rules Reference" access right (System_AccessWorkerRule).
  195: 
  196: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Rules Reference" access right (System_EditWorkerRule).
  197: 
  198: **Important!** Work rules are created in the employee's local time zone. When creating a work rule from 10:00-18:00 for both employees in Moscow (UTC+3) and employees in Vladivostok (UTC+10), shifts for both employees will be planned from 10:00-18:00.
  199: 
  200: To access the reference, open the side menu and select "References" → "Work Rules" tab or open the reference from the system start page, "Work Rules Configuration" dashboard:
  201: 
  202: ![Work Rules Reference](img/work-rules-reference.png)
  203: 
  204: By default, the system displays all active work rules (button pressed).
  205: 
  206: To view all work rules (active/deactivated) or only deactivated ones, click the corresponding button. To view only work rules with/without rotation/all rules, click and select the needed filter:
  207: 
  208: ![Work Rules Filters](img/work-rules-filters.png)
  209: 
  210: If the rules list is large, you can use the search function by name for convenience. Start typing the work rule name in the search bar and the reference will display all rules with matches:
  211: 
  212: ![Work Rules Search](img/work-rules-search.png)
  213: 
  214: ##### 3.1.1.1 Work Rule Mode Differences
  215: 
  216: The reference allows creating work rules in two modes: with rotation and without rotation.
  217: 
  218: In "With rotation" mode, when creating a rule, you can specify the order in which work and rest days will alternate for the operator assigned this rule. The specified alternation of work and rest days will be strictly followed from week to week:
  219: 
  220: ![With Rotation Mode](img/with-rotation-mode.png)
  221: 
  222: In "Without rotation" mode, when creating a rule, you can specify the number of rest days the operator should have per week:
  223: 
  224: ![Without Rotation Mode](img/without-rotation-mode.png)
  225: 
  226: The system, based on continuous rest norm verification from the "Labor Standards" reference, will set the number and order of rest days per week that won't violate the continuous rest norm. Rest days may change from week to week.
  227: 
  228: Example for 24-hour continuous rest norm per week:
  229: - Week 1 – RWRWRRR
  230: - Week 2 – WRRRRWR  
  231: - Week 3 – RRRWWRR
  232: 
  233: Example for 42-hour continuous rest norm per week:
  234: - Week 1 – RRWWRRR
  235: - Week 2 – WWRRRRR
  236: - Week 3 – RWWRRRR
  237: 
  238: ##### 3.1.1.2 Viewing Work Rules
  239: 
  240: In the work rules list, click on the rule of interest. The following information will be displayed to the right:
  241: 
  242: ![Work Rule Details](img/work-rule-details.png)
  243: 
  244: - **"Work Rules"** - Shows rule name, mode, number of shifts, their start time and duration, and number of rotations (if "With rotation" mode is set). This section has an "Edit" button allowing rule modification after creation.
  245: 
  246: - **"Rule Assignment"** - Lists surnames of people assigned this rule. This section has an "Assign" button allowing rule assignment to operators after creation.
  247: 
  248: ##### 3.1.1.3 Creating Work Rules
  249: 
  250: **With Rotation Mode**
  251: 
  252: To create a new work rule, click the "Create work rule" button:
  253: 
  254: ![Create Work Rule](img/create-work-rule.png)
  255: 
  256: Select "With rotation" mode:
  257: 
  258: ![Select Rotation Mode](img/select-rotation-mode.png)
  259: 
  260: The "Work Rule Configuration" window opens:
  261: 
  262: ![Work Rule Configuration](img/work-rule-configuration.png)
  263: 
  264: In this window, specify:
  265: - Any rule name
  266: - Whether the rule should consider the production calendar. If checked, when planning schedules, shifts won't be placed on holidays even if work quota isn't covered. On pre-holiday days, shift duration from the rule will be reduced by one hour if strict duration is set. For flexible shift duration, this setting won't be considered.
  267: - Whether to set mandatory shifts by day type. If checked, in the "Shifts" step you can set a mandatory shift that will be placed in the employee's schedule if rest day falls according to rotation.
  268: - Time zone for rule creation
  269: - Whether to set rotation by day type in the week. If checked, in the "Shift Rotations" step, for each weekday you can set a specific work day that will be considered if a non-rest day falls according to rotation.
  270: 
  271: Click "Forward" to proceed to "Shifts" configuration.
  272: 
  273: In this window, specify shift start time (mandatory) and shift duration (mandatory):
  274: 
  275: ![Shift Configuration](img/shift-configuration.png)
  276: 
  277: For shift start and duration, specify fixed or flexible period. If shift should start strictly at 09:00, specify period 09:00 – 09:00 in the start field. If start can be flexible day to day, specify range, e.g., 08:00 – 10:00. The system will automatically select start time from the given range for each work day. Same applies for duration.
  278: 
  279: To add additional shift, click the + button next to "Work Day 1".
  280: To remove one of created shifts, click the - button next to "Work Day N".
  281: 
  282: For shift to always start at the same time, specify equal left and right boundaries for start time (Example: 12:00-12:00).
  283: For shift to always have the same duration, specify equal left and right boundaries for shift duration (Example: 09:00-09:00).
  284: 
  285: **Important!** Start and duration step depends on the step setting configured in the system database during deployment. If 30-minute step is set, you cannot specify start time like 09:00-09:20 or duration 11:00-11:20.
  286: 
  287: To add split shift (when operator should work several hours at the beginning of the day and several hours at the end), click + next to "Shift №1".
  288: To remove split shifts, click - next to "Shift №N".
  289: 
  290: ![Split Shift Configuration](img/split-shift-configuration.png)
  291: 
  292: Click "Forward" to proceed to "Shift Rotations" configuration or "Back" for previous "General Information" step. In "Shift Rotations" window, specify work/rest day alternation and add shift rotations if necessary:
  293: 
  294: ![Shift Rotations](img/shift-rotations.png)
  295: 
  296: To change work/rest day and/or shift alternation (if there's more than one), double-click left mouse button on selected day:
  297: 
  298: ![Edit Rotation](img/edit-rotation.png)
  299: 
  300: **Important!** By default, all rotations start with work day. This condition reduces the number of necessary rotations.
  301: 
  302: Click "Forward" to proceed to "Shift Distances" configuration or "Back" for previous "Shifts" step. In "Shift Distances" window, set minimum distance between shifts (how many hours later the next shift can start after the previous one ends) and maximum consecutive hours sum (sum of hours without unpaid breaks/lunches between continuous rest standards).
  303: 
  304: Shift distance configuration is only available if flexible duration by start and/or shift duration was set in the "Shifts" step.
  305: 
  306: ![Shift Distances](img/shift-distances.png)
  307: 
  308: Work rule assignment will be described later in section 3.1.1.4 Work Rule Assignment.
  309: 
  310: **Without Rotation Mode**
  311: 
  312: To create a new work rule, click "Create work rule" and select "Without rotation" mode:
  313: 
  314: ![Without Rotation Setup](img/without-rotation-setup.png)
  315: 
  316: In the "Work Schedule Configuration" dialog on the "General Information" tab, specify the rule name:
  317: 
  318: ![General Info Setup](img/general-info-setup.png)
  319: 
  320: Specify whether the rule should consider production calendar. If checked, when planning schedules, shifts won't be placed on holidays even if work quota isn't covered. On pre-holiday days, shift duration from the rule will be reduced by one hour if strict duration is set. For flexible shift duration, this setting won't be considered.
  321: 
  322: Specify time zone for rule creation.
  323: 
  324: Click "Forward" to proceed to "Shifts" configuration.
  325: 
  326: In this window, specify shift start time (mandatory) and shift duration (mandatory):
  327: 
  328: ![Shifts Without Rotation](img/shifts-without-rotation.png)
  329: 
  330: To add additional shift, click + next to "Work Day 1".
  331: To remove created shifts, click - next to "Work Day N".
  332: 
  333: For shift to always start at same time, specify equal left and right boundaries for start time (Example: 12:00-12:00).
  334: For shift to always have same duration, specify equal left and right boundaries for shift duration (Example: 08:00-08:00).
  335: 
  336: **Important!** Start and duration step depends on the step setting configured in system database during deployment. If 30-minute step is set, you cannot specify start like 09:00-09:20 or duration 11:00-11:20.
  337: 
  338: To add split shift (when operator should work several hours at beginning and end of day), click + next to "Shift №1".
  339: To remove split shifts, click - next to "Shift №N".
  340: 
  341: ![Split Shifts Setup](img/split-shifts-setup.png)
  342: 
  343: Click "Forward" to proceed to "Rest Days" configuration or "Back" for previous "General Information" step.
  344: 
  345: On "Rest Days" tab, information about continuous rest norm specified in "Labor Standards" reference is pulled. Specify number of rest days:
  346: 
  347: ![Rest Days Configuration](img/rest-days-configuration.png)
  348: 
  349: **Important!** "Number of rest days" item is checked non-strictly by the system during schedule formation. Strict check is "Continuous rest norm". This means the system cannot put fewer rest days per week than specified in continuous rest norm, but "Number of rest days" item will be followed after all other checks are completed - Work period quota and Load coverage.
  350: 
  351: Click "Forward" to proceed to "Shift Distances" configuration or "Back" for previous "Rest Days" step. In "Shift Distances" window, set minimum distance between shifts (how many hours later next shift can start after previous one ends) and maximum consecutive hours sum (sum of hours without unpaid breaks/lunches between continuous rest standards).
  352: 
  353: Shift distance configuration is only available if flexible duration by start and/or shift duration was set in "Shifts" step.
  354: 
  355: ![Shift Distances Without Rotation](img/shift-distances-without-rotation.png)
  356: 
  357: Work rule assignment will be described later in section 3.1.1.4 Work Rule Assignment.
  358: 
  359: ##### 3.1.1.4 Work Rule Assignment
  360: 
  361: Work rule assignment is done for a period:
  362: 
  363: ![Rule Assignment Period](img/rule-assignment-period.png)
  364: 
  365: This means only one work rule can be assigned to one employee for the same time interval.
  366: 
  367: Operators in the list can be sorted by departments. To search for specific operator, start typing their surname in the "Full Name" field.
  368: 
  369: To assign rule to specific operator, select this operator by checking the left checkbox:
  370: 
  371: ![Select Individual Operator](img/select-individual-operator.png)
  372: 
  373: To assign schedule to all operators, select the topmost checkbox to the left of "Personnel Number" column:
  374: 
  375: ![Select All Operators](img/select-all-operators.png)
  376: 
  377: If selected operators already have assigned rule for selected period, system will show warning:
  378: 
  379: ![Assignment Warning](img/assignment-warning.png)
  380: 
  381: For assignments to take effect, click "Save".
  382: 
  383: ##### 3.1.1.5 Editing Work Rules
  384: 
  385: To edit work rule, select it in the list and click "Edit" button in the right part:
  386: 
  387: ![Edit Work Rule](img/edit-work-rule.png)
  388: 
  389: The system creates a copy of the work rule that can be edited and assigned to employees. By default, the system completely copies all settings to the new rule:
  390: 
  391: ![Work Rule Copy](img/work-rule-copy.png)
  392: 
  393: Work rule editing functionality is similar to work rule creation functionality. For more details on working in "Work Rule Configuration" window, see section 3.1.1.3.
  394: 
  395: ##### 3.1.1.6 Deleting, Deactivating, Activating Work Rules
  396: 
  397: To delete previously created work rule, select it in the list and click "Delete work rule" button:
  398: 
  399: ![Delete Work Rule](img/delete-work-rule.png)
  400: 
  401: **Important!** If the selected work rule for deletion was assigned to employees, the system won't allow deletion since it references other system records. Such rule can only be deactivated.
  402: 
  403: ![Cannot Delete Rule](img/cannot-delete-rule.png)
  404: 
  405: To deactivate previously created work rule, select it in the list and click "Deactivate work rule" button:
  406: 
  407: ![Deactivate Work Rule](img/deactivate-work-rule.png)
  408: 
  409: To restore (activate) previously deactivated work rule, set "Inactive" filter, select it in the list and click "Activate work rule" button:
  410: 
  411: ![Activate Work Rule](img/activate-work-rule.png)
  412: 
  413: #### 3.1.2 Events Reference {#events-reference}
  414: 
  415: The reference is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit Events Reference" access right (System_EditEventTemplate).
  416: 
  417: ![Events Reference](img/events-reference.png)
  418: 
  419: To open the reference, go to "References" → "Events" tab.
  420: 
  421: The "Events" reference is designed for creating intraday call center events.
  422: 
  423: On the "Internal Activities" tab, "Training" and "Meeting" type events are created.
  424: On the "Projects" tab, outgoing activities are created.
  425: 
  426: When opening the reference, you'll see:
  427: 
  428: ![Events Reference Interface](img/events-reference-interface.png)
  429: 
  430: Event filters – "All", "Active", "Inactive". Depending on selected filter, corresponding events will be displayed in the system.
  431: 
  432: Event types – "Internal Activities", "Projects". List of created events (if any) with information about them.
  433: 
  434: ##### 3.1.2.1 Creating Internal Activities
  435: 
  436: To create an event, click the create button. In the opened "Event Configuration" dialog, fill the following parameters:
  437: 
  438: ![Event Configuration](img/event-configuration.png)
  439: 
  440: - **Type** - select event type from dropdown:
  441: 
  442: ![Event Type Selection](img/event-type-selection.png)
  443: 
  444: - **Name, Description** – specify event name and brief description
  445: - **Regularity** – select frequency of the event from list:
  446: 
  447: ![Event Regularity](img/event-regularity.png)
  448: 
  449: ###### 3.1.2.1.1 Events with "Once a day", "Once a week", "Once a month" regularity
  450: 
  451: For events with "Once a day", "Once a week", "Once a month" regularity, specify:
  452: 
  453: - **Weekdays** (all weekdays selected by default): to select specific weekdays when event will be conducted. Uncheck days when event won't be conducted in the dropdown:
  454: 
  455: ![Weekday Selection](img/weekday-selection.png)
  456: 
  457: - **Time interval**: specify time period when it's appropriate to conduct the event. For example, 12:00 – 16:00
  458: - **Time zone**: specify time zone applied to this event. Without time zone selection, time will be saved as local – independent of time zone
  459: 
  460: For example, meetings should occur twice a week, professional development courses – once a month, English training – once a week. Accordingly, when "ARGUS WFM CC" system suggests registering events in schedule, it will analyze whether sufficient time has passed since the previous event for each individual participant (operator).
  461: 
  462: - **Event duration, min**: specify event duration in minutes
  463: 
  464: When "ARGUS WFM CC" system suggests registering events in schedule, it will look for free intervals for operators, analyze their length, and if operator's free interval length equals or exceeds event duration, system can suggest such interval.
  465: 
  466: - **Sign**: for individual event click individual, for group event click group
  467: - **Number of participants**: this parameter appears when clicking group in "Sign" area. Specify minimum and maximum number of participants who can attend the event
  468: 
  469: ![Participant Number](img/participant-number.png)
  470: 
  471: - **Groups**: if employees from specific group should participate in event, select it from dropdown (by checking):
  472: 
  473: ![Group Selection](img/group-selection.png)
  474: 
  475: - **Employees**: if only specific employees should participate in event, start typing employee surname and system will display matches. Click on employee with left mouse button to select:
  476: 
  477: ![Employee Selection](img/employee-selection.png)
  478: 
  479: To add another employee, repeat the operation:
  480: 
  481: ![Add Employee](img/add-employee.png)
  482: 
  483: To remove employee, click the X button.
  484: 
  485: **Important!** Employee search also depends on "Groups" parameter. If specific group was selected, system searches employees only within that group.
  486: 
  487: **Combine with other events during the day**: if this checkbox is checked, system can combine different types of events for one operator during the day.
  488: 
  489: ![Combine Events](img/combine-events.png)
  490: 
  491: ###### 3.1.2.1.2 Events with "Specify event day" regularity
  492: 
  493: For events with "Specify event day" regularity, fill:
  494: 
  495: - **Event day**: specify specific day when event should take place. For example, 22.02.2023:
  496: 
  497: ![Event Day](img/event-day.png)
  498: 
  499: - **Start time**: specify specific time when event should start in HH:MM format. For example, 13:00:
  500: 
  501: ![Start Time](img/start-time.png)
  502: 
  503: - **Time zone, Event duration, Groups, Employees, Combine with other events during the day**: filled similarly to "Once a day", "Once a week", "Once a month" regularity
  504: 
  505: After filling all necessary parameters, click save to save the event:
  506: 
  507: ![Save Event](img/save-event.png)
  508: 
  509: Saved event will be displayed in the reference:
  510: 
  511: ![Saved Event Display](img/saved-event-display.png)
  512: 
  513: To edit event, click edit button. "Event Configuration" window opens, then change parameters described above and save changes.
  514: 
  515: To delete event from reference, click delete button.
  516: 
  517: **Note:** When "ARGUS WFM CC" system suggests registering event in schedule, for "group" event:
  518: 
  519: - System will look for common free intervals for all group employees (or groups) if "Employees" parameter is not filled and "Groups" parameter specifies one or several groups
  520: - System will look for common free intervals for specific employees if "Employees" parameter is filled
  521: - Additionally, system analyzes "Number of participants" parameter (minimum number). When searching for common free intervals, system analyzes minimum number of participants specified in event settings and looks for common free intervals available to at least as many employees as specified in event settings
  522: 
  523: ##### 3.1.2.2 Creating Outgoing Projects
  524: 
  525: To create "Project", go to corresponding tab in "Events" reference and click create:
  526: 
  527: ![Create Project](img/create-project.png)
  528: 
  529: In the opened "Event Configuration" dialog, fill the following parameters:
  530: 
  531: ![Project Configuration](img/project-configuration.png)
  532: 
  533: - **Type**: select event type
  534: - **Name, Description**: specify event name and brief description
  535: - **Mode**: mode determines priority when planning event; what's more important – incoming load or outgoing project
  536: 
  537: When assigning projects, HHL (highest load hours) intervals are determined. HHL determination method is similar to peak determination method in "Peak Analysis" in forecasting module with small differences in coefficients. HHL are intervals (both external and internal) that exceed upper boundary.
  538: 
  539: "Incoming load priority over outgoing project" – project won't be placed in HHL.
  540: "Outgoing project priority over incoming load" – project can be placed in HHL.
  541: 
  542: - **Priority**: determines priority over other projects. Higher number means higher priority over other projects
  543: - **Weekdays** (all weekdays selected by default): to select specific weekdays when event will be conducted. Uncheck days when event won't be conducted in dropdown:
  544: 
  545: ![Project Weekdays](img/project-weekdays.png)
  546: 
  547: - **Time interval**: specify time period when it's appropriate to conduct event. For example, 12:00 – 16:00
  548: - **Event duration, min**: specify event duration in minutes
  549: - **Planned term**: specify dates when event will be planned in schedule
  550: - **AHT**: specify expected call handling time
  551: - **OSS**: specify operator utilization
  552: - **Work plan calls/surveys**: specify number of calls that need to be processed within the project
  553: - **Group**: select groups from which operators will be chosen for project
  554: - **Employees**: select specific employees who will work on project. Must be selected unlike "Internal Activities"
  555: 
  556: After filling all necessary parameters, click save to save the event.
  557: 
  558: #### 3.1.3 Production Calendar Reference {#production-calendar-reference}
  559: 
  560: The reference is available for viewing to users with "Administrator" system role or any other role with "View Production Calendar page" access right (System_AccessCalendar).
  561: 
  562: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Production Calendar page" access right (System_EditCalendar).
  563: 
  564: This reference maintains calendar with work, rest, pre-holiday and holiday days for considering day types when planning vacations. If employee vacation falls on holiday, system will automatically extend vacation considering production calendar.
  565: 
  566: ![Production Calendar](img/production-calendar.png)
  567: 
  568: To access the reference, open side menu and select "References" → "Production Calendar" tab.
  569: 
  570: To start working, you need to load production calendar in XML format.
  571: 
  572: Ready-to-import Russian Federation calendar files can be obtained from the resource by link.
  573: 
  574: When opening the reference, production calendar for current year opens by default, where each year day is colored according to legend:
  575: 
  576: ![Calendar Legend](img/calendar-legend.png)
  577: 
  578: If necessary, you can hide production calendar display in work schedule by unchecking the corresponding checkbox.
  579: 
  580: ##### 3.1.3.1 Importing Production Calendar
  581: 
  582: To load production calendar, click import button. In opened "Production Calendar Import" window, select weekdays that will be considered rest days by default, then click file selection button and import.
  583: 
  584: Loaded production calendar looks as follows:
  585: 
  586: ![Loaded Calendar](img/loaded-calendar.png)
  587: 
  588: ##### 3.1.3.2 Editing Production Calendar
  589: 
  590: To edit loaded production calendar, select day of interest and choose type to change to in right menu:
  591: 
  592: ![Edit Calendar](img/edit-calendar.png)
  593: 
  594: After selecting type, day will be colored according to legend:
  595: 
  596: ![Calendar Color Change](img/calendar-color-change.png)
  597: 
  598: When changing type to "Holiday", system will additionally request specifying which event the holiday is dedicated to:
  599: 
  600: ![Holiday Event](img/holiday-event.png)
  601: 
  602: To save changes, click save button, to cancel changes – cancel button.
  603: 
  604: #### 3.1.4 Roles Reference {#roles-reference}
  605: 
  606: The reference is available for viewing to users with "View Roles Reference" access right (System_AccessRoleList).
  607: 
  608: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Roles Reference" access right (System_EditRole).
  609: 
  610: This reference regulates access rights to system functions. Roles are set with access rights assigned for viewing and editing specific system functions. Later, created or existing roles will be assigned to users.
  611: 
  612: To access the reference, open side menu and select "References" → "Roles" tab, or go from sections list menu or from main page by clicking "Role Configuration" block:
  613: 
  614: ![Roles Reference Access](img/roles-reference-access.png)
  615: 
  616: ![Roles Reference Interface](img/roles-reference-interface.png)
  617: 
  618: By default, system displays all active roles (button pressed). To view all roles (active/deactivated) or only deactivated ones, click corresponding button.
  619: 
  620: If roles list is large, start typing role name in search bar for convenience, system will display matching roles:
  621: 
  622: ![Roles Search](img/roles-search.png)
  623: 
  624: The reference contains 3 system roles: Administrator, Senior Operator, Operator. These roles are non-editable, each has its own set of access rights:
  625: 
  626: ![System Roles](img/system-roles.png)
  627: 
  628: ##### 3.1.4.1 Creating Role
  629: 
  630: To create new business role, click "Create new role" button:
  631: 
  632: ![Create Role](img/create-role.png)
  633: 
  634: "Name", "Description" fields appear in right part. Below these fields, access rights that need to be assigned to the created role are displayed.
  635: 
  636: ![Role Configuration](img/role-configuration.png)
  637: 
  638: To create role, fill mandatory "Name" field. For convenience, you can add role description and check "Default role" checkbox if you want created role to be automatically assigned to all employees created in system:
  639: 
  640: ![Role Settings](img/role-settings.png)
  641: 
  642: Then click "Save" button.
  643: 
  644: After this, new role appears in business roles list on left:
  645: 
  646: ![New Role Display](img/new-role-display.png)
  647: 
  648: Now you need to assign access rights to created role. Select role in list and in right part, check needed access rights by checking checkbox:
  649: 
  650: ![Assign Access Rights](img/assign-access-rights.png)
  651: 
  652: ##### 3.1.4.2 Editing Role
  653: 
  654: To edit created role, select it in list and change name/description in right part. To save changes, click save button.
  655: 
  656: List of assigned access rights is edited by checking/unchecking checkbox:
  657: 
  658: ![Edit Role Rights](img/edit-role-rights.png)
  659: 
  660: ##### 3.1.4.3 Deleting Role
  661: 
  662: To delete previously created role, select it in list and click "Delete role" button:
  663: 
  664: ![Delete Role](img/delete-role.png)
  665: 
  666: ##### 3.1.4.4 Deactivating Role
  667: 
  668: To deactivate role, select it in list and click "Deactivate role" button:
  669: 
  670: ![Deactivate Role](img/deactivate-role.png)
  671: 
  672: ##### 3.1.4.5 Restoring Role
  673: 
  674: To restore/activate previously deactivated role, select it in list and click "Activate role" button:
  675: 
  676: ![Restore Role](img/restore-role.png)
  677: 
  678: #### 3.1.5 Positions Reference {#positions-reference}
  679: 
  680: The reference is available for viewing to users with "View Positions Reference" access right (System_AccessPositionList).
  681: 
  682: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Positions Reference" access right (System_EditPosition).
  683: 
  684: This reference is needed for configuring positions for which work schedule planning will be performed.
  685: 
  686: To access the reference, open side menu and select "References" → "Positions" tab:
  687: 
  688: ![Positions Reference](img/positions-reference.png)
  689: 
  690: The reference contains list of employee positions present in the system.
  691: 
  692: ![Positions List](img/positions-list.png)
  693: 
  694: Position reference population occurs automatically through integration with 1C system (with appropriate configuration).
  695: 
  696: **Important!** If synchronization with 1C system is absent, position list is added through system database by ARGUS NTC specialists.
  697: 
  698: Upon receiving position through integration, it's assigned name corresponding to employee positions name in 1C system and external identifier "External System Key".
  699: 
  700: For correct system operation and correct work schedule planning, responsible employee needs to set "Planning Participation" attribute for each position in "Positions" reference. By default, all positions received from 1C system participate in work schedule and timetable planning.
  701: 
  702: To change "Planning Participation" attribute, left-click on area containing general position information ("Name", "External System Key", "Planning Participation") and uncheck "Planning Participation" attribute:
  703: 
  704: ![Edit Position Planning](img/edit-position-planning.png)
  705: 
  706: #### 3.1.6 Work Time Efficiency Configuration Reference {#work-time-efficiency-reference}
  707: 
  708: The reference is available for viewing to users with "View Work Time Efficiency Configuration Reference" access right (System_AccessOperatorState).
  709: 
  710: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Time Efficiency Configuration Reference" access right (System_EditOperatorState).
  711: 
  712: In this reference, it's determined which work statuses coming through integration with contact center will have parameters like "productive time", "net load", etc.
  713: 
  714: Statuses received from contact center and their assigned parameters will be needed by system for calculations in reports (both in report editor and outside it) and when working with monitoring.
  715: 
  716: Open reference through side menu:
  717: 
  718: ![Work Time Efficiency Reference](img/work-time-efficiency-reference.png)
  719: 
  720: To configure reference, you need to fill "Historical Reports", "Operational Control" and "Payroll Report" tabs to set correspondence between statuses operators can be in with events in System, and configure report calculations based on operator's actual work time.
  721: 
  722: "Historical Reports" tab contains statuses that will be used in reports.
  723: 
  724: - **Status**: status name (more technical) coming from contact center. For example, "READY" shows operator is ready to take call
  725: - **Name**: status name understandable to user. Can have same value as "status"
  726: - **Description**: status description
  727: - **Productive time**: status when operator is at workplace and ready to work
  728: - **Net load**: status when operator takes incoming contact
  729: - **Talk time**: status denoting operator talk status. Post-processing, for example, can also be marked as "Talk time"
  730: - **Break**: operator rest status. Can be lunch, break, etc.
  731: - **Actual timesheet time**: if status is marked with this checkbox, it will be considered when calculating actual time in control tool
  732: - **Productive work time**: if status is marked with this checkbox, it will be considered when calculating productivity in "Bonus Report". If "Productivity" standard value is specified in "Bonus Indicators", statuses marked with this checkbox will be used
  733: - **Post-call processing**: if status is marked with this checkbox, it will be considered when calculating useful time, which will be used in "KPI" report and "Workplace Report 2"
  734: 
  735: ![Historical Reports Configuration](img/historical-reports-configuration.png)
  736: 
  737: On "Operational Control" tab, statuses are displayed for which you need to set one of correspondences for monitoring: "Online", "Online – not processing calls", "Absent".
  738: 
  739: This setting allows configuring status correspondence for displaying operator schedule compliance and violations in "Monitoring" - "Operator Statuses" block.
  740: 
  741: Status correspondence is set using dropdown. To set correspondence for status, click dropdown next to status (initially empty) and select needed one.
  742: 
  743: - **Online** – operator is online and taking contacts
  744: - **Online – not processing calls** – operator is online but not processing contacts  
  745: - **Absent** – operator is not online now but is at work
  746: 
  747: All changes in this reference are saved automatically.
  748: 
  749: ![Operational Control Configuration](img/operational-control-configuration.png)
  750: 
  751: On "Payroll Report" tab, specify whether to consider or not consider status when calculating actual time in "Payroll Report".
  752: 
  753: ![Payroll Report Configuration](img/payroll-report-configuration.png)
  754: 
  755: #### 3.1.7 Special Events Reference {#special-events-reference}
  756: 
  757: The reference is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Special Events Reference" access right (System_AccessForecastSpecialEvent).
  758: 
  759: The reference is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit Special Events Reference" access right (System_EditForecastSpecialEvent).
  760: 
  761: "Special Events" reference is designed for entering events that cannot be forecasted – city-specific holidays, mass events, etc. On such days, load sharply increases or conversely drops. If normal staffing is deployed as for "regular" days, in first case there will be operator shortage and SLA will subsequently drop, in second case there will be many extra operators sitting idle.
  762: 
  763: During special event action, forecasted load for affected groups will be multiplied by set coefficient.
  764: 
  765: To access the reference, open side menu and select "References" → "Special Events Reference" tab:
  766: 
  767: ![Special Events Reference](img/special-events-reference.png)
  768: 
  769: ![Special Events Interface](img/special-events-interface.png)
  770: 
  771: ##### 3.1.7.1 Creating Special Event
  772: 
  773: To create special event, click "Add" button. In opened "Special Event Configuration" dialog, fill following parameters:
  774: 
  775: ![Special Event Configuration](img/special-event-configuration.png)
  776: 
  777: - **Active**: specify special event action period with minute precision and time zone
  778: - **Name, Description**: specify special event name and brief description
  779: - **Service, Group**: select service from dropdown, then groups included in selected service
  780: - **Coefficient**: specify coefficient by which load (number of contacts) obtained during forecasting should be multiplied. Value 1 and above – increases number of calls. Value 0 to 1 – decreases number of calls (e.g., coefficient 0.5 decreases number of calls by half)
  781: 
  782: When creating special event, you can specify several action periods for correcting coefficient (added by clicking "+"). If periods overlap with other events' action periods, System considers all of them.
  783: 
  784: For example, 3 special events with coefficients 1.25, 1.35 and 2.15 affect forecasted interval. Then for this interval, load will be increased 2.75 times:
  785: - 1.25 – 1 = 0.25
  786: - 1.35 – 1 = 0.35  
  787: - 2.15 – 1 = 1.15
  788: - 1 + 0.25 + 0.35 + 1.15 = 2.75
  789: 
  790: ![Multiple Coefficients](img/multiple-coefficients.png)
  791: 
  792: After filling all parameters, click save button to save event. Saved event will be displayed in reference:
  793: 
  794: ![Saved Special Event](img/saved-special-event.png)
  795: 
  796: The following example shows how this setting affects obtained load change using special event in figure above.
  797: 
  798: Load obtained before special event appearance in reference:
  799: 
  800: ![Load Before Event](img/load-before-event.png)
  801: 
  802: After adding special event to reference and re-obtaining forecasts, you can notice how number of recalculated contacts changed in next figure – on next tab, number of operators in this period will also be increased:
  803: 
  804: ![Load After Event](img/load-after-event.png)
  805: 
  806: ##### 3.1.7.2 Editing Special Event
  807: 
  808: To edit special event, click edit button. "Special Event Configuration" window opens. Change parameters described in previous section and save changes.
  809: 
  810: **Important**: For edited event to apply, forecast must be updated.
  811: 
  812: ##### 3.1.7.3 Deleting Special Event
  813: 
  814: To delete special event from reference, click delete button.
  815: 
  816: **Important**: System will only allow deleting special event that was never considered when obtaining forecast.
  817: 
  818: **Note 1:** System allows creating identical special events in reference. In this case, when obtaining forecasts, coefficient of special event created later is applied.
  819: 
  820: **Note 2:** System allows creating overlapping events. With such overlapping events in forecasted intervals:
  821: - In non-overlapping segments, load is multiplied by corresponding coefficients
  822: - In overlapping segment – load is multiplied by coefficient of special event created last
  823: 
  824: #### 3.1.8 Labor Standards Reference {#labor-standards-reference}
  825: 
  826: The reference is available for viewing to users with "View Labor Standards Reference" access right (System_AccessWorkNorm).
  827: 
  828: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Labor Standards Reference" access right (System_EditWorkNorm).
  829: 
  830: This reference configures labor standard parameters considered or not considered when creating work schedule templates and planning work schedules.
  831: 
  832: To access the reference, open side menu and select "References" → "Labor Standards" tab:
  833: 
  834: ![Labor Standards Reference](img/labor-standards-reference.png)
  835: 
  836: After accessing the reference, following window is displayed:
  837: 
  838: ![Labor Standards Interface](img/labor-standards-interface.png)
  839: 
  840: ![Labor Standards Details](img/labor-standards-details.png)
  841: 
  842: **Rest norm** determines number of continuous rest hours for operator per calendar week. For example, if you set 48-hour norm, it means operator must rest two consecutive days. This setting also affects ability to add additional shift to operator in planned work schedule.
  843: 
  844: When planning and editing schedule, system can behave differently depending on settings. Select most suitable option from proposed:
  845: 
  846: - **Ignore**: system will plan employee schedules according to their work rules and load, but weekly rest norm may not be observed. During manual corrections, system will allow setting any shift regardless of specified rest norm
  847: - **Consider**: system will plan work schedules with strict rest norm consideration. When attempting manual corrections violating weekly rest norm, user will receive notification about inability to perform this action
  848: - **Warn**: system will plan work schedules with strict rest norm consideration. When attempting manual corrections violating weekly rest norm, user will receive warning that changes violate weekly rest norm
  849: - **Use only during planning**: rest norm will be considered only during work schedule planning. During manual corrections, system will allow setting any shift regardless of specified rest norm – warning won't appear
  850: 
  851: ![Rest Norm Configuration](img/rest-norm-configuration.png)
  852: 
  853: **Weekly norm** is used to check possibility of adding additional shifts to operator when correcting planned work schedule. When attempting to add additional shift to operator during work schedule planning, system will rely on reference settings and "Weekly hours norm" value in operator card.
  854: 
  855: When planning and editing schedule, system can behave differently depending on settings. Select most suitable option from proposed:
  856: 
  857: - **Ignore**: reference setting is ignored, can add shift to employee regardless of their norm
  858: - **Consider**: if additional shift cannot be added to employee due to weekly hours norm excess, user will receive warning and shift won't be assigned
  859: - **Warn**: if additional shift cannot be added to employee due to weekly hours norm excess, user will receive warning and choice: add shift or refuse
  860: - **Consider during planning**: weekly norm will be considered only during work schedule planning, during manual shift addition norm won't be considered (similar to "Ignore" checkbox)
  861: 
  862: ![Weekly Norm Configuration](img/weekly-norm-configuration.png)
  863: 
  864: **Night time** is used to determine hours considered night time (according to Labor Code from 22:00 – 06:00) and parameters that will determine system behavior when assigning work schedule templates and planning work schedules. These hours work together with individual employee card settings. If employee doesn't have "Night work" parameter set, system will monitor that employee isn't assigned shift overlapping night time specified in reference.
  865: 
  866: Also specify % night work supplement that will be considered when calculating schedule cost.
  867: 
  868: Select most suitable option from proposed:
  869: 
  870: - **Ignore**: night hours not considered
  871: - **Consider**: used when attempting to assign work schedule template to employee individually who doesn't have "Night work" checkbox set, warning appears and schedule isn't assigned. When attempting mass work schedule template assignment, employees without "Night work" checkbox will be grayed out and cannot be selected for template assignment
  872: - **Warn**: during individual work schedule template assignment to employee without "Night work" checkbox, user will see warning about individual settings violation and be offered choice: assign template anyway or not. During mass assignment, behavior is same
  873: - **Use only during planning**: night time will be considered only during work schedule planning, during manual shift addition night time won't be considered, similar to "Ignore" checkbox
  874: 
  875: ![Night Time Configuration](img/night-time-configuration.png)
  876: 
  877: **Daily norm** determines operator shift duration. System checks shift duration in work schedule template and shift duration set in operator card – operator will get minimum duration from these two values.
  878: 
  879: Select most suitable system behavior with reference settings:
  880: 
  881: - **Ignore**: reference settings and individual daily hours value set in operator card not considered
  882: - **Consider**: during work schedule planning, operators will get minimum shift duration value (either reference or individual). During manual shift duration correction, operator's individual duration is also considered. If new shift duration exceeds norm during correction, user will receive warning and duration won't change
  883: - **Warn**: considered during manual shift duration correction. If shift duration exceeds norm, user will receive warning and choice: change duration anyway or refuse
  884: - **Use only during planning**: similar to "Consider" option but without conditions for manual correction
  885: 
  886: ![Daily Norm Configuration](img/daily-norm-configuration.png)
  887: 
  888: **Accumulated vacation days**. Reference determines whether accumulated vacation days will be considered when manually adding vacation in vacation schedule planning, operator card and formed work schedule.
  889: 
  890: - **Ignore**: when attempting to add vacation to operator, remaining vacation days number not considered
  891: - **Consider**: when manually adding vacation to operator, remaining vacation days number will be considered. If vacation days insufficient, system will show warning and not assign vacation
  892: - **Warn**: if operator doesn't have enough vacation days, warning will be issued when adding with choice: assign vacation or not
  893: 
  894: ![Vacation Days Configuration](img/vacation-days-configuration.png)
  895: 
  896: ![Vacation Days Settings](img/vacation-days-settings.png)
  897: 
  898: **Time interval for obtaining accumulated vacation days and method of obtaining these days**
  899: 
  900: This setting sets time period for which system will take accumulated vacation days from 1C during personnel structure update, and you need to select work hours obtaining option: from 1C or enter work hours manually (either massively or in operator card).
  901: 
  902: ![Vacation Days Interval](img/vacation-days-interval.png)
  903: 
  904: **Shift exchange periods**. This setting helps avoid payroll calculation period problems for employees.
  905: 
  906: In this block, you can highlight month date boundaries within which shift exchange/work coverage between employees is possible. Add several periods within month by clicking + and specify date range boundaries within which employees can exchange shifts. When creating shift exchange request, limitation check set in current block will be performed.
  907: 
  908: Example: shifts can be exchanged from 1st to 14th and from 15th to 31st. In this case, if employee wants to exchange January 10th shift, they must work until January 14th inclusive.
  909: 
  910: ![Exchange Periods](img/exchange-periods.png)
  911: 
  912: **Allowable overtime hours amount**
  913: 
  914: This setting helps prevent excessive employee overtime. Specify maximum overtime hours operator can work per week and year. If when setting additional shift in schedule, employee's total overtime hours per week/year exceeds norm specified in reference, system will show warning (if "Warn" is set) or prohibit additional shift setting (if "Consider" is set).
  915: 
  916: #### 3.1.9 Breaks/Lunches Reference {#breaks-lunches-reference}
  917: 
  918: The reference is available for viewing to users with "View Labor Standards Reference" access right (System_AccessWorkNorm).
  919: 
  920: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Labor Standards Reference" access right (System_EditWorkNorm).
  921: 
  922: In reference, you can set number and duration of lunches/breaks for shift of specific type and duration. Reference information is used for operator schedule planning.
  923: 
  924: To access reference, open side menu and select "References → Breaks/lunches" tab.
  925: 
  926: ![Breaks Lunches Reference](img/breaks-lunches-reference.png)
  927: 
  928: When opening reference, following window is displayed:
  929: 
  930: ![Breaks Lunches Interface](img/breaks-lunches-interface.png)
  931: 
  932: In left "Shifts" block, set shift duration and type. To create new shift, click + and fill following parameters:
  933: 
  934: ![Create Shift](img/create-shift.png)
  935: 
  936: Shift duration is specified in hour intervals.
  937: 
  938: For example, for schedules 8:00-20:00, 9:00-21:00 and 10:00-22:00, shift duration will be 12 hours, for schedules 8:00-16:00, 9:00-17:00, 10:00-18:00 – 8 hours. To include full interval, specify duration in "11:59-12:01" format.
  939: 
  940: ![Shift Duration](img/shift-duration.png)
  941: 
  942: **Shift type**
  943: 
  944: Specify one of three shift types – day, night and mixed. Shift type depends on night time hours set in "Labor Standards" reference (according to Labor Code from 22:00 – 06:00). Shift type determines ability to set day and night lunches/breaks. For mixed shift, you need to set night duration and day duration – total hours falling on night and day time (see example in figure).
  945: 
  946: **Note:** For night shift, you can set maximum duration not exceeding total night hours duration set in "Labor Standards": if it's from 22:00 to 6:00, night shift duration cannot be more than 8 hours.
  947: 
  948: ![Shift Type Configuration](img/shift-type-configuration.png)
  949: 
  950: **Lunch/break order**
  951: 
  952: Set one of two modes: "Consider lunch/break order" and "Don't consider lunch/break order". Selected mode determines whether system can automatically arrange set lunches/breaks under load in schedule or will follow strict lunch/break order.
  953: 
  954: **Maximum/minimum time without break**
  955: 
  956: In maximum and minimum time without break columns, specify time within which employee can be without break. Time without break should be multiple of set system interval.
  957: 
  958: ![Break Time Configuration](img/break-time-configuration.png)
  959: 
  960: To save all set shift parameters, click save button. To edit reference record, click edit button – interface identical to creation interface. To delete record, click delete button.
  961: 
  962: In right "Business Rules" block, business rules for lunches/breaks are set for each created shift.
  963: 
  964: To create new business rule for shift, click + and fill following parameters:
  965: 
  966: ![Business Rule Configuration](img/business-rule-configuration.png)
  967: 
  968: **Note:** "Lunch start interval (from shift beginning)" parameter will only appear if "Don't consider lunch/break order" mode was selected for shift and break type will be "Lunch break". In "Lunch start interval" field, period from shift beginning when system can plan lunch break for employees is specified.
  969: 
  970: ![Lunch Start Interval](img/lunch-start-interval.png)
  971: 
  972: **Type**
  973: 
  974: Set one of two types: lunch or technological break.
  975: 
  976: **Duration (min)** can only be multiple of initially set system intervals.
  977: 
  978: **Paid**: checkbox allows considering break in timesheet. For example, if 12-hour shift has 4 breaks: 2 unpaid 30-minute lunches and 2 paid 15-minute technological breaks, then 11 full hours will go to timesheet (for payment).
  979: 
  980: To save all set break parameters, click save button. To edit reference record, click edit button (interface identical to creation interface); to delete record, click delete button.
  981: 
  982: #### 3.1.10 Vacation Schemes Reference {#vacation-schemes-reference}
  983: 
  984: The reference is available for viewing to users with "View Vacation Schemes Reference" access right (System_AccessVacationScheme).
  985: 
  986: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Vacation Schemes Reference" access right (System_EditVacationScheme).
  987: 
  988: This reference configures vacation schemes that determine duration and number of vacations.
  989: 
  990: Later (during work schedule and timetable planning), these schemes are used for assigning vacations to operators.
  991: 
  992: Vacation scheme can be assigned to specific operator in their card or massively.
  993: 
  994: To access reference, open side menu and select "References" → "Vacation Schemes" tab:
  995: 
  996: ![Vacation Schemes Reference](img/vacation-schemes-reference.png)
  997: 
  998: ##### 3.1.10.1 Viewing Reference
  999: 
 1000: When opening reference, following window is displayed:
 1001: 
 1002: ![Vacation Schemes Interface](img/vacation-schemes-interface.png)
 1003: 
 1004: **Name**: vacation scheme name.
 1005: 
 1006: **1st, 2nd,…, nth Vacation**: number of days in specific vacation (see figure, first vacation has 7 rest days, second has 14).
 1007: 
 1008: On this page, you can create new reference record or edit existing one.
 1009: 
 1010: ##### 3.1.10.2 Creating New Vacation Scheme
 1011: 
 1012: To create new vacation scheme, click create button in "Vacation Schemes" reference.
 1013: 
 1014: ![Create Vacation Scheme](img/create-vacation-scheme.png)
 1015: 
 1016: In opened window, enter name and number of vacation days. Number of vacations can be adjusted by clicking + to add or – to remove.
 1017: 
 1018: ![Vacation Scheme Details](img/vacation-scheme-details.png)
 1019: 
 1020: **Note 1**: vacation period alternation doesn't matter. For example, schemes 7-14-7, 7-7-14 and 14-7-7 are equivalent.
 1021: 
 1022: To save all set parameters, click save button.
 1023: 
 1024: ##### 3.1.10.3 Editing Vacation Scheme
 1025: 
 1026: To delete vacation scheme, click delete button in "Vacation Schemes" reference and confirm or cancel action by selecting corresponding button.
 1027: 
 1028: ![Delete Vacation Scheme](img/delete-vacation-scheme.png)
 1029: 
 1030: To change number of vacation days or scheme name, click edit button, make necessary corrections and confirm or cancel them.
 1031: 
 1032: ![Edit Vacation Scheme](img/edit-vacation-scheme.png)
 1033: 
 1034: #### 3.1.11 Integration Systems Reference {#integration-systems-reference}
 1035: 
 1036: The reference is available for viewing to users with "View Integration Systems Reference" access right (System_IntegrationSystemView).
 1037: 
 1038: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Integration Systems Reference" access right (System_IntegrationSystemEdit).
 1039: 
 1040: This reference configures parameters for interaction with integration systems participating in specific processes in WFM CC: obtaining historical data, personnel structure, etc.
 1041: 
 1042: To access reference, open side menu and select "References" → "Integration Systems" tab:
 1043: 
 1044: ![Integration Systems Reference](img/integration-systems-reference.png)
 1045: 
 1046: In opened window, fill following parameters:
 1047: 
 1048: ![Integration Systems Configuration](img/integration-systems-configuration.png)
 1049: 
 1050: **System**: integration system name.
 1051: 
 1052: **Personnel structure access point**: WSDL containing personnel structure obtaining methods structure from integration system.
 1053: 
 1054: **Shift sending access point**: WSDL containing shift transmission methods structure to integration system.
 1055: 
 1056: **Call center historical data access point**: WSDL containing historical data obtaining methods structure needed for load forecasting from integration system.
 1057: 
 1058: **Operator historical data access point**: WSDL containing operator historical data obtaining methods structure. For example, for calculating operator's actual work output from integration system.
 1059: 
 1060: **Operator chat work access point**: WSDL containing methods structure for obtaining number of processed chats, time, etc.
 1061: 
 1062: **Monitoring data access point**: WSDL containing methods structure for obtaining real-time load for monitoring operation.
 1063: 
 1064: **System identifier**: external system identifier; needed for correct integration system identification.
 1065: 
 1066: **SSO**: checkbox marking connection between operator account authorization in Windows and operator account in WFM CC.
 1067: 
 1068: **Is master system**: checkbox marking whether this integration system is main; used during personnel synchronization. If system is main, WFM will only link its account but cannot edit employee data.
 1069: 
 1070: **Delete button**: deletes integration system record.
 1071: 
 1072: To edit record field, left-click on needed field:
 1073: 
 1074: ![Edit Integration System](img/edit-integration-system.png)
 1075: 
 1076: To create new integration system record, click create button:
 1077: 
 1078: ![Create Integration System](img/create-integration-system.png)
 1079: 
 1080: In "Add new integration system" window, fill all required integration system data and click "Confirm" button.
 1081: 
 1082: ![Integration System Details](img/integration-system-details.png)
 1083: 
 1084: #### 3.1.12 Absence Reasons Reference {#absence-reasons-reference}
 1085: 
 1086: The reference is available for viewing to users with "View Absence Reasons Reference" access right (System_AccessAbsenceReasons).
 1087: 
 1088: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Absence Reasons Reference" access right (System_EditAbsenceReasons).
 1089: 
 1090: This reference specifies all possible reasons for operator absence from line. Later used for creating special event in operator card.
 1091: 
 1092: To access reference, open side menu and select "References → Absence Reasons" tab.
 1093: 
 1094: ![Absence Reasons Reference](img/absence-reasons-reference.png)
 1095: 
 1096: Reference has filtering by active/inactive/all records:
 1097: 
 1098: ![Absence Reasons Filter](img/absence-reasons-filter.png)
 1099: 
 1100: To create absence reason, click create button. In opened window, fill following parameters:
 1101: 
 1102: ![Create Absence Reason](img/create-absence-reason.png)
 1103: 
 1104: Check "Consider in %absenteeism report" checkbox for absence reasons that will be subtracted from planned employee number when generating "%absenteeism Report".
 1105: 
 1106: To edit absence reason, click edit button or delete button to remove.
 1107: 
 1108: #### 3.1.13 Time Zones Reference {#time-zones-reference}
 1109: 
 1110: The reference is available for viewing to users with "View Time Zones Reference" access right (System_AccessTimeZone).
 1111: 
 1112: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Time Zones Reference" access right (System_EditTimeZone).
 1113: 
 1114: Reference allows setting time zones that affect time display in system. Values set in this reference can be seen in other sections in "Time Zones" field.
 1115: 
 1116: To access reference, open side menu and select "References" → "Time Zones" tab:
 1117: 
 1118: ![Time Zones Reference](img/time-zones-reference.png)
 1119: 
 1120: Reference consists of following parameters:
 1121: 
 1122: ![Time Zones Configuration](img/time-zones-configuration.png)
 1123: 
 1124: - **Time zone**: select time zone from dropdown
 1125: - **Interface display**: set name that will be displayed in all forms where time zones are used
 1126: 
 1127: To add new record, click create button.
 1128: 
 1129: ![Create Time Zone](img/create-time-zone.png)
 1130: 
 1131: To save, click save button or cancel button to cancel.
 1132: 
 1133: To edit time zone interface display, click edit button. Change parameters and click apply button or cancel button to cancel.
 1134: 
 1135: To delete time zone from reference, click delete button.
 1136: 
 1137: #### 3.1.14 Notification Scheme Reference {#notification-scheme-reference}
 1138: 
 1139: The reference is available for viewing to users with "View Absence Reasons Reference" access right (System_AccessAbsenceReasons).
 1140: 
 1141: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Absence Reasons Reference" access right (System_EditAbsenceReasons).
 1142: 
 1143: Reference determines which actions users will be notified about and which role users need to be notified.
 1144: 
 1145: To access reference, open side menu and select "References" → "Notification Schemes" tab.
 1146: 
 1147: ![Notification Schemes Reference](img/notification-schemes-reference.png)
 1148: 
 1149: Reference consists of following parameters:
 1150: 
 1151: ![Notification Schemes Interface](img/notification-schemes-interface.png)
 1152: 
 1153: To add new notification scheme, click create button. For each scheme, configuration form opens. Following is detailed description of notification scheme configuration by sections:
 1154: 
 1155: - Work schedule planning
 1156: - Operator events
 1157: - Operator shifts  
 1158: - Requests
 1159: - Operator schedules
 1160: - Monitoring
 1161: - Integrations
 1162: - Preferences
 1163: - Acknowledgments
 1164: 
 1165: ##### 3.1.14.1 Work Schedule Planning
 1166: 
 1167: In "Work Schedule Planning" section, notifications that system will send during various work schedule actions are configured.
 1168: 
 1169: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1170: 
 1171: **Event Type:**
 1172: 
 1173: - **Work schedule creation**: notification sent when work schedule is created
 1174: - **Applied work schedule copy creation**: notification sent when clicking "Edit" button for applied work schedule
 1175: - **Schedule confirmation**: notification sent when work schedule is confirmed by all responsible users
 1176: - **Schedule return for revision**: notification sent when schedule is returned for revision before approval
 1177: - **Schedule application pending**: notification sent after schedule approval before application
 1178: - **Schedule application**: notification sent when schedule is applied
 1179: - **Approval process started**: notification about need to confirm operator wishes for work schedules and vacations sent when operator wish approval process is started
 1180: - **Operator wishes confirmed by managers**: notification sent after managers confirm wishes in multi-skill planning template
 1181: - **Outdated shift exchange/transfer and vacation requests**: notification sent when shift exchange/transfer and vacation request is outdated due to schedule changes
 1182: 
 1183: ![Work Schedule Planning Events](img/work-schedule-planning-events.png)
 1184: 
 1185: **Recipient**: select users who will receive corresponding notifications.
 1186: 
 1187: **Important!** In "Recipients" field, you can check "Employees" checkbox; list of employees who will receive notifications is regulated by business processes.
 1188: 
 1189: **Important!** When selecting "Employees" checkbox in "Recipients" section, notifications will be sent according to business process regulated list.
 1190: 
 1191: **Channels**: select channels through which notifications will be sent.
 1192: 
 1193: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1194: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1195: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1196: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1197: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1198: 
 1199: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1200: 
 1201: ##### 3.1.14.2 Operator Events
 1202: 
 1203: In "Operator Events" section, notifications that system will send when adding specific special events in operator card are configured.
 1204: 
 1205: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1206: 
 1207: **Event Type:**
 1208: 
 1209: - **Sick leave creation**: notification sent when sick leave is created in employee card
 1210: - **Sick leave deletion**: notification sent when sick leave is deleted in employee card  
 1211: - **Sick leave change**: notification sent when sick leave is deleted from employee card
 1212: - **Time off creation**: notification sent when time off is created in employee card
 1213: - **Time off deletion**: notification sent when time off is deleted in employee card
 1214: - **Time off change**: notification sent when time off is changed in employee card
 1215: - **Planned vacation addition**: notification sent when planned vacation is added to employee
 1216: - **Planned vacation deletion**: notification sent when planned vacation is deleted
 1217: - **Planned vacation change**: notification sent when planned vacation is changed
 1218: - **Unscheduled vacation addition**: notification sent when unscheduled vacation is added
 1219: - **Unscheduled vacation deletion**: notification sent when unscheduled vacation is deleted
 1220: - **Unscheduled vacation change**: notification sent when unscheduled vacation is changed
 1221: - **Reserve addition**: notification sent when reserve is added
 1222: - **Reserve deletion**: notification sent when reserve is deleted
 1223: - **Reserve change**: notification sent when reserve is changed
 1224: 
 1225: ![Operator Events Configuration](img/operator-events-configuration.png)
 1226: 
 1227: **Recipient**: select users who will receive corresponding notifications. For example, if "Employees" checkbox is selected in "Recipient", notification will go to employees whose cards had sick leave set.
 1228: 
 1229: - **Employees**: notification will be sent to employees according to selected event
 1230: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1231: - **Roles**: notification will be sent to users with specific system roles
 1232: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1233: 
 1234: **Channels**: select channels through which notifications will be sent.
 1235: 
 1236: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1237: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1238: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1239: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1240: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1241: 
 1242: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1243: 
 1244: ##### 3.1.14.3 Operator Shifts
 1245: 
 1246: In "Operator Shifts" section, notifications that system will send during various events related to work schedule correction are configured.
 1247: 
 1248: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1249: 
 1250: **Event Type:**
 1251: 
 1252: - **Shift creation**: creating planned shift for operator
 1253: - **Shift deletion**: deleting planned shift for operator
 1254: - **Additional shift creation**: creating additional shift for operator
 1255: - **Additional shift deletion**: deleting additional shift for operator
 1256: - **Overtime shift creation**: creating planned shift for operator with overtime hours before or after shift
 1257: - **Overtime hours deletion**: deleting overtime hours from shift
 1258: - **Shift change**: changing operator shift
 1259: - **Additional shift change**: changing operator additional shift
 1260: - **Overtime shift change**: changing operator shift with overtime hours
 1261: 
 1262: ![Operator Shifts Configuration](img/operator-shifts-configuration.png)
 1263: 
 1264: **Recipient**: select users who will receive corresponding notifications.
 1265: 
 1266: - **Employees**: notification will be sent to employees according to selected event
 1267: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1268: - **Roles**: notification will be sent to users with specific system roles
 1269: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1270: 
 1271: **Channels**: select channels through which notifications will be sent.
 1272: 
 1273: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1274: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1275: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1276: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1277: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1278: 
 1279: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1280: 
 1281: ##### 3.1.14.4 Requests
 1282: 
 1283: In "Requests" section, notifications that system will send during various request-related events are configured.
 1284: 
 1285: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1286: 
 1287: **Event Type:**
 1288: 
 1289: - **Shift exchange request confirmation**: notification about manager's agreement with shift exchange request between operators
 1290: - **Shift transfer request confirmation**: notification about manager's agreement with operator shift transfer request
 1291: - **Vacation exchange request confirmation**: notification about manager's agreement with vacation exchange request between operators
 1292: - **Vacation transfer request confirmation**: notification about manager's agreement with operator vacation transfer request
 1293: - **Shift exchange request cancellation**: notification about manager canceling shift exchange request between operators (re-creating request is possible)
 1294: - **Shift transfer request cancellation**: notification about manager canceling operator shift transfer request (re-creating request is possible)
 1295: - **Vacation exchange request cancellation**: notification about manager canceling vacation exchange request between operators (re-creating request is possible)
 1296: - **Vacation transfer request cancellation**: notification about manager canceling operator vacation transfer request (re-creating request is possible)
 1297: - **Shift exchange request rejection**: notification about manager rejecting shift exchange request between operators (re-creating request for these dates is impossible, request author will work selected shift*)
 1298: - **Shift transfer request rejection**: notification about manager rejecting operator shift transfer request (re-creating request for these dates is impossible, request author will work selected shift*)
 1299: - **Vacation exchange request rejection**: notification about manager rejecting shift exchange request between operators (re-creating request for these dates is impossible, request author will go on vacation on original dates*)
 1300: - **Vacation transfer request rejection**: notification about manager rejecting vacation transfer request (re-creating request for these dates is impossible, request author will go on vacation on original dates*)
 1301: - **Sick leave creation request confirmation**: notification about manager's agreement with sick leave creation request
 1302: - **Time off creation request confirmation**: notification about manager's agreement with time off creation request
 1303: - **Unscheduled vacation creation request confirmation**: notification about manager's agreement with unscheduled vacation creation request
 1304: - **Sick leave creation request cancellation**: notification about manager canceling sick leave creation request (re-creating request is possible)
 1305: - **Time off creation request cancellation**: notification about manager canceling time off creation request (re-creating request is possible)
 1306: - **Unscheduled vacation creation request cancellation**: notification about manager canceling unscheduled vacation creation request (re-creating request is possible)
 1307: - **Sick leave creation request rejection**: notification about manager rejecting sick leave creation request (re-creating request is impossible, operator won't go on sick leave on selected dates*)
 1308: - **Time off creation request rejection**: notification about manager rejecting time off creation request (re-creating request is impossible, operator won't take time off on selected dates*)
 1309: - **Unscheduled vacation creation request rejection**: notification about manager rejecting unscheduled vacation creation request (re-creating request is impossible, operator won't take unscheduled vacation on selected dates*)
 1310: 
 1311: *rejection means operator cannot create repeat request for selected dates. However, manager can still manually add event to calendar
 1312: 
 1313: ![Requests Configuration](img/requests-configuration.png)
 1314: 
 1315: **Recipient**: select users who will receive corresponding notifications.
 1316: 
 1317: - **Employees**: notification will be sent to employees according to selected event
 1318: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1319: - **Roles**: notification will be sent to users with specific system roles
 1320: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1321: 
 1322: **Channels**: select channels through which notifications will be sent.
 1323: 
 1324: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1325: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1326: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1327: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1328: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1329: 
 1330: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1331: 
 1332: ##### 3.1.14.5 Operator Schedules
 1333: 
 1334: In "Operator Schedules" section, notifications that system will send during various schedule-related actions are configured.
 1335: 
 1336: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1337: 
 1338: **Event Type:**
 1339: 
 1340: - **Current schedule update**: if "Employees" is specified in "Recipient", notification will go to employees whose shifts fell under schedule update period
 1341: - **Manual current schedule change**: if when editing lunches/breaks/shifts etc. for operators "Employees" is specified in "Recipient", notification will go to employees whose schedule was changed
 1342: - **Operator call to shift**: if when creating "Call to work" event in current schedule "Employees" is specified in "Recipient", notification will go to employees who were called to work
 1343: - **Operator call to workplace**: if when calling operator from monitoring page "Employees" is specified in "Recipient", notification will go to employees who were called
 1344: - **Lunch start approaching**: notification sent N minutes before lunch start (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose lunch is approaching
 1345: - **Break start approaching**: notification sent N minutes before break start (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose break is approaching
 1346: - **Lunch end approaching**: notification sent N minutes before lunch end (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose lunch is ending
 1347: - **Break end approaching**: notification sent N minutes before break end (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose break is ending
 1348: - **Operator didn't come online**: notification sent by monitoring if operator has work time but is not at place (not logged into contact center system or contact center status doesn't correspond to work). If "Employees" is selected in "Recipient", notification will be sent to employees absent from workplace
 1349: - **Channel switch approaching**: notification sent N minutes before switching to one of channels specified in "Channel Type" reference and entered on "Current Schedule" page by manager
 1350: 
 1351: ![Operator Schedules Configuration](img/operator-schedules-configuration.png)
 1352: 
 1353: **Recipient**: select users who will receive corresponding notifications.
 1354: 
 1355: - **Employees**: notification will be sent to employees according to selected event
 1356: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1357: - **Roles**: notification will be sent to users with specific system roles
 1358: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1359: 
 1360: **Channels**: select channels through which notifications will be sent.
 1361: 
 1362: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1363: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1364: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1365: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1366: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1367: 
 1368: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1369: 
 1370: **Notification Parameters** – parameters according to which notifications will be sent. Contains time before which employees should be notified about upcoming events.
 1371: 
 1372: ![Notification Parameters](img/notification-parameters.png)
 1373: 
 1374: ##### 3.1.14.6 Monitoring
 1375: 
 1376: In "Monitoring" section, notifications that system will send during various monitoring-related events are configured.
 1377: 
 1378: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1379: 
 1380: **Event Type:**
 1381: 
 1382: - **SLA deviation (relative to threshold values)**: SLA indicator in specific group went beyond lower/upper boundary
 1383: - **Online operators number deviation (relative to threshold values)**: "% operators online" indicator in specific group went beyond lower/upper boundary
 1384: - **Load deviation (relative to threshold values)**: load deviation indicator in specific group went beyond lower/upper boundary
 1385: - **Operator requirement deviation (relative to threshold values)**: difference between actual number of operators (online) and forecasted number of operators in specific group went beyond lower/upper boundary
 1386: - **ACD deviation (relative to threshold values)**: ACD indicator in specific group went beyond lower/upper boundary
 1387: - **AHT deviation (relative to threshold values)**: AHT indicator in specific group went beyond lower/upper boundary
 1388: 
 1389: ![Monitoring Configuration](img/monitoring-configuration.png)
 1390: 
 1391: **Recipient**: select users who will receive corresponding notifications.
 1392: 
 1393: - **Employees**: notification will be sent to employees according to selected event
 1394: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1395: - **Roles**: notification will be sent to users with specific system roles
 1396: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1397: 
 1398: **Channels**: select channels through which notifications will be sent.
 1399: 
 1400: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1401: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1402: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1403: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1404: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1405: 
 1406: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1407: 
 1408: **Notification Parameters** – parameters according to which notifications will be sent. Contains monitoring indicators update frequency.
 1409: 
 1410: ![Monitoring Parameters](img/monitoring-parameters.png)
 1411: 
 1412: ##### 3.1.14.7 Integrations
 1413: 
 1414: In "Integrations" section, notifications that system will send for single event type – personnel synchronization error are configured.
 1415: 
 1416: Select "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1417: 
 1418: **Recipient**: select users who will receive corresponding notifications.
 1419: 
 1420: - **Employees**: notification will be sent to employees according to selected event
 1421: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1422: - **Roles**: notification will be sent to users with specific system roles
 1423: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1424: 
 1425: ![Integrations Configuration](img/integrations-configuration.png)
 1426: 
 1427: **Channels**: select channels through which notifications will be sent.
 1428: 
 1429: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1430: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1431: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1432: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1433: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1434: 
 1435: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1436: 
 1437: ##### 3.1.14.8 Preferences
 1438: 
 1439: In "Preferences" section, notifications that system will send during preference-related events are configured.
 1440: 
 1441: Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1442: 
 1443: **Event Type:**
 1444: 
 1445: - **Opening preference entry possibility**: notification with information about preference entry period and time is sent when preference entry possibility opens
 1446: - **Closing preference entry possibility**: notification about possibility to update work schedule after entering preferences is sent when preference entry period is closed
 1447: 
 1448: **Recipient**: select users who will receive corresponding notifications.
 1449: 
 1450: - **Employees**: notification will be sent to employees according to selected event
 1451: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1452: - **Roles**: notification will be sent to users with specific system roles
 1453: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1454: 
 1455: ![Preferences Configuration](img/preferences-configuration.png)
 1456: 
 1457: **Channels**: select channels through which notifications will be sent.
 1458: 
 1459: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1460: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1461: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1462: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1463: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1464: 
 1465: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1466: 
 1467: After operator receives information about preference entry possibility, operator should go to their personal cabinet and specify needed preferences.
 1468: 
 1469: ##### 3.1.14.9 Acknowledgments
 1470: 
 1471: In "Acknowledgments" section, notifications that system will send for single event type – work schedule acknowledgment confirmation are configured. This is notification with information about need to confirm in personal cabinet that operator has acknowledged work schedule.
 1472: 
 1473: Select "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.
 1474: 
 1475: ![Acknowledgments Configuration](img/acknowledgments-configuration.png)
 1476: 
 1477: **Recipient**: select users who will receive corresponding notifications.
 1478: 
 1479: - **Employees**: notification will be sent to employees according to selected event
 1480: - **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
 1481: - **Roles**: notification will be sent to users with specific system roles
 1482: - **Individual employees**: notification will be sent to specific employees selected from dropdown
 1483: 
 1484: **Channels**: select channels through which notifications will be sent.
 1485: 
 1486: - **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
 1487: - **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
 1488: - **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
 1489: - **E-mail**: notification will come to user's email if specified in operator card contacts
 1490: - **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card
 1491: 
 1492: **Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.
 1493: 
 1494: #### 3.1.15 Preferences Reference {#preferences-reference}
 1495: 
 1496: The reference is available for viewing to users with "Access to edit Preferences reference" access right (System_AccessWish).
 1497: 
 1498: The reference is available for editing to users with "Administrator" system role or any other role with "Access to edit Preferences reference" access right (System_EditWish).
 1499: 
 1500: Reference allows reducing number of manual work schedule corrections by planners/managers and increasing operator loyalty by considering their work schedule preferences during planning with maximum possible preservation of required call center level.
 1501: 
 1502: To access reference, open side menu and select "References" → "Preferences" tab.
 1503: 
 1504: ![Preferences Reference](img/preferences-reference.png)
 1505: 
 1506: To create new preference, click create button and in appeared window enter parameters specified below and click "Forward" button:
 1507: 
 1508: - Name
 1509: - Time zone
 1510: - When to enter preferences (period during which preferences can be entered)
 1511: - For which period to enter preferences
 1512: - Regular and priority preferences limit
 1513: 
 1514: ![Preferences Configuration](img/preferences-configuration.png)
 1515: 
 1516: In next window, select Operators who will have possibility to enter preferences. Select Operators through filters or check corresponding checkbox next to surname.
 1517: 
 1518: ![Preferences Operators](img/preferences-operators.png)
 1519: 
 1520: To complete, click "Save" button, to make changes use "Back" button.
 1521: 
 1522: When planner/manager creates rule for preference configuration, system will notify about this:
 1523: 
 1524: - Operators/managers - when preference entry possibility is open
 1525: - Planners/managers - when preference entry possibility is closed
 1526: 
 1527: For notifying responsible employees about preferences, "Notification Schemes" reference should be configured in system ("Work Schedule Planning" page).
 1528: 
 1529: #### 3.1.16 Exchange Rules Settings Reference {#exchange-rules-reference}
 1530: 
 1531: The reference is available for viewing to users with "View Exchange Rules Settings Reference" access right (System_AccessRequestRule).
 1532: 
 1533: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Exchange Rules Settings Reference" access right (System_EditRequestRule).
 1534: 
 1535: Reference allows configuring conditions for creating shift/vacation exchange requests and conditions for creating event requests from operators (sick leave/time off/unscheduled vacation).
 1536: 
 1537: To access reference, open side menu and select "References" → "Exchange Rules Settings" tab.
 1538: 
 1539: ![Exchange Rules Reference](img/exchange-rules-reference.png)
 1540: 
 1541: Reference contains following settings:
 1542: 
 1543: - Request limitation by functional structure
 1544: - Request limitation by organizational structure
 1545: - Enabling/disabling mandatory comment when creating request
 1546: - Selection of available events for request creation
 1547: 
 1548: ![Exchange Rules Settings](img/exchange-rules-settings.png)
 1549: 
 1550: "Functional Groups" section has two settings: "Consider" or "Don't consider".
 1551: 
 1552: When setting "Consider" marker, shift/vacation exchange requests will be visible only to employees with similar functional groups configuration, i.e., employees who belong to same groups. If at least one group differs, request won't be displayed.
 1553: 
 1554: When setting "Don't consider" marker, shift/vacation exchange request will be visible to all available employees in system.
 1555: 
 1556: ![Functional Groups Setting](img/functional-groups-setting.png)
 1557: 
 1558: "Organizational Structure" section is responsible for configuring limitations for viewing shift/vacation exchange requests within organizational structure. When selecting specific department, requests will be distributed only to employees within it. If specific department isn't selected, requests from this department will be visible to all other employees.
 1559: 
 1560: ![Organizational Structure Setting](img/organizational-structure-setting.png)
 1561: 
 1562: "Mandatory Comment" section: when enabling mandatory comment, employee will be required to leave comment when creating request, which will be displayed in request itself.
 1563: 
 1564: ![Mandatory Comment Setting](img/mandatory-comment-setting.png)
 1565: 
 1566: "Creating Event Setting Requests" section is responsible for configuring event types for which operator can create requests. For example, when selecting "Sick Leave", "Time Off", "Unscheduled Vacation" events, operator can create requests for these events through personal cabinet.
 1567: 
 1568: ![Event Setting Requests](img/event-setting-requests.png)
 1569: 
 1570: To save changes, click "Apply" button.
 1571: 
 1572: #### 3.1.17 Payroll Report Reference {#payroll-report-reference}
 1573: 
 1574: The reference is available for viewing to users with "View Payroll Report Reference" access right (System_AccessPayrollReport).
 1575: 
 1576: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Payroll Report Reference" access right (System_EditPayrollReport).
 1577: 
 1578: To access reference, open side menu and select "References" → "Payroll Report" tab.
 1579: 
 1580: ![Payroll Report Reference](img/payroll-report-reference.png)
 1581: 
 1582: Reference contains following settings:
 1583: 
 1584: - Build mode
 1585: - Overtime hours consideration
 1586: - Sick leave display
 1587: - Time off display
 1588: 
 1589: ![Payroll Report Settings](img/payroll-report-settings.png)
 1590: 
 1591: In "Report build mode" section, report building parameters are selected: building report by 1C data, building report by actual contact center data, building report by schedule data. If these parameters are checked with checkbox, build mode can be selected when creating report.
 1592: 
 1593: ![Report Build Mode](img/report-build-mode.png)
 1594: 
 1595: In "Overtime hours and weekend work" section, overtime hours and weekends consideration in report by actual contact center data is configured.
 1596: 
 1597: ![Overtime Configuration](img/overtime-configuration.png)
 1598: 
 1599: In "Sick leave display" section, sick leave consideration set in employee card when building payroll report is configured.
 1600: 
 1601: ![Sick Leave Display](img/sick-leave-display.png)
 1602: 
 1603: In "Time off display" section, time off consideration set in employee card when building payroll report is configured.
 1604: 
 1605: ![Time Off Display](img/time-off-display.png)
 1606: 
 1607: To save changes, click "Apply" button.
 1608: 
 1609: #### 3.1.18 Channel Type Reference {#channel-type-reference}
 1610: 
 1611: The reference is available for viewing to users with "Access to view Channel Type reference" access right (System_AccessChannelType).
 1612: 
 1613: The reference is available for editing to users with "Administrator" system role or any other role with "Access to edit Channel Type reference" access right (System_EditChannelType).
 1614: 
 1615: Reference allows creating/editing/deleting new channel types.
 1616: 
 1617: To access reference, open side menu and select "References" → "Channel Type" tab.
 1618: 
 1619: ![Channel Type Reference](img/channel-type-reference.png)
 1620: 
 1621: Created channels are presented as table with following fields:
 1622: 
 1623: - **External ID**: channel type received through integration
 1624: - **Channel name**: channel name for display in system UI
 1625: - **Planning only within channel**: attribute of possibility to plan simultaneously with other channels
 1626: - **Channel color**: channel color designation that will be displayed in employee schedule in personal cabinet
 1627: 
 1628: ![Channel Type Table](img/channel-type-table.png)
 1629: 
 1630: To add new channels, click create button. In opened window, fill all specified parameters.
 1631: 
 1632: ![Create Channel Type](img/create-channel-type.png)
 1633: 
 1634: To delete channel, click delete button and confirm/cancel action.
 1635: 
 1636: ![Delete Channel Type](img/delete-channel-type.png)
 1637: 
 1638: When making changes in this reference, no additional confirmation is needed, all changes are saved automatically.
 1639: 
 1640: Additional confirmation of changes in this reference is not required, changes are saved automatically.
 1641: 
 1642: ### 3.2 Personnel Configuration {#personnel-configuration}
 1643: 
 1644: **Functional structure** – type of personnel structure where departments are created according to type of work they perform.
 1645: 
 1646: **Organizational structure** – obligations, authorities and interactions by which organization performs its functions.
 1647: 
 1648: **Department** – part of organizational structure.
 1649: 
 1650: **Manager** – user who is department manager. This setting is made in "Departments" reference in Personnel → Departments section.
 1651: 
 1652: **Deputy** – user who is deputy department manager. This setting should be made in "Departments" reference in Personnel → Departments section.
 1653: 
 1654: **Service** – functional unit serving tasks on particular topic.
 1655: 
 1656: **Simple group** – functional unit that is child to service and serves highly specialized tasks within service's general topic.
 1657: 
 1658: **Aggregated group** – functional unit that is child to service and includes simple groups. Aggregated groups are created in WFM CC system, i.e., not transmitted through integration.
 1659: 
 1660: #### 3.2.1 Employees {#employees}
 1661: 
 1662: The reference is available for viewing to users with "View Employees page" access right (System_AccessWorkerList).
 1663: 
 1664: The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Schedule Templates reference" access right (System_EditScheduleTemplate).
 1665: 
 1666: To account for employees in load forecasting and schedule creation in "ARGUS WFM CC" system, you need to create their cards.
 1667: 
 1668: The "Employees" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Employees" block:
 1669: 
 1670: ![Employees Section Access](img/employees-section-access.png)
 1671: 
 1672: ![Employees Main Page](img/employees-main-page.png)
 1673: 
 1674: By default, system displays only active employees (button pressed). To view all employees (active/deactivated) or only deactivated ones, click corresponding button.
 1675: 
 1676: For search convenience, use search: start typing employee name and system will display matches by coincidence, you can also filter operator list by department:
 1677: 
 1678: ![Employee Search Filter](img/employee-search-filter.png)
 1679: 
 1680: In employee list, click on employee of interest. Following information will be displayed to the right of selected employee.
 1681: 
 1682: Upper part of card (figure 3.2.1.4):
 1683: 
 1684: - Surname, Name, Patronymic
 1685: - Personnel number
 1686: - Information about whether employee is home operator
 1687: - Hire date
 1688: - Termination date
 1689: - ID (internal and external)
 1690: - Position
 1691: - Time zone
 1692: - Department
 1693: 
 1694: ![Employee Card Upper](img/employee-card-upper.png)
 1695: 
 1696: You can go to department by clicking its name. Also in employee card there's possibility to specify comment in free form that won't be visible to employee themselves.
 1697: 
 1698: Employee card consists of following information blocks:
 1699: 
 1700: - **Current employee work schedule** – shifts and rotation assigned to employee. Work schedule and rotation are needed to determine employee's work and non-work days. Different colors on schedule show different shifts (light green shifts were assigned manually, red ones automatically planned by System). Same shows employee vacation types and their dates.
 1701: 
 1702: ![Current Work Schedule](img/current-work-schedule.png)
 1703: 
 1704: - **Individual business rules for lunches/breaks** (figure 3.2.1.9) that need to be considered when planning employee work schedule. They're needed so system considers breaks/lunches when planning schedule and automatically places them depending on operator load. Creation logic is similar to "Lunches/Breaks" reference. Individual business rules take precedence over general lunch/break business rules.
 1705: 
 1706: ![Individual Business Rules](img/individual-business-rules.png)
 1707: 
 1708: - **Planned services and groups** that employee can handle. To edit groups list, click gear icon. By checking corresponding checkboxes, select main groups that will be planned first.
 1709: 
 1710: ![Planned Services Groups](img/planned-services-groups.png)
 1711: 
 1712: - **Contacts**: contains contact information for communicating with employee (email address, landline phone, mobile phone, other (e.g., Telegram login)). Specifying email is additional channel for receiving notifications (with appropriate "Notification Schemes" reference and Server configuration).
 1713: 
 1714: ![Employee Contacts](img/employee-contacts.png)
 1715: 
 1716: - **WFM Account**: account that employee will use to access System. When creating, you need to specify login and password. Creation time is recorded automatically. We recommend mandatory password change on first system login. For this, specify any past date in "Password valid until" field.
 1717: 
 1718: WFM account can be blocked: manually by clicking gear, when entering wrong password more than 5 times, when receiving termination date through integration and automatic employee card deactivation.
 1719: 
 1720: ![WFM Account](img/wfm-account.png)
 1721: 
 1722: - **Individual settings**: considered when building work schedule.
 1723:   - **Rate** indicates whether employee works full workday (e.g., working 40 hours per week in 5/2 schedule is rate 1.0, working 20 hours per week is rate 0.5). Rate participates in work hours calculation (if it comes through integration, not set manually).
 1724:   - **Cost** based on which schedule cost will be calculated. Reference value is set in "Bonus Indicators" reference, individual value in employee card.
 1725:   - **Night work** shows whether employee will work night time (night time is set in labor standards configuration). If checkbox isn't checked, system cannot assign night shifts to employee.
 1726:   - **Weekend work** shows whether employee can be brought to work on their day off.
 1727:   - **Overtime work** determines whether system can add work hours above established norm (adding additional shifts, weekend calls, etc.).
 1728:   - **Weekly hours norm (in hours)** – value setting allowable operator work limit per week. Considered when adding additional shifts during work schedule planning; comes through integration.
 1729:   - **Daily hours norm (in hours)** overrides daily shift duration during work schedule planning, i.e., if employee has 7 hours per day and work schedule template has 9-hour shift, employee will get 7-hour shift during work schedule planning; comes through integration.
 1730: 
 1731: ![Individual Settings](img/individual-settings.png)
 1732: 
 1733: **Note**: By default, settings in "Labor Standards" reference are set to "Ignore", i.e., by default values specified in individual settings won't be considered; rate will equal one.
 1734: 
 1735: - **External system accounts**: attached to employee through integration or manually (through account mapping on "Personnel" → "Personnel Synchronization" page).
 1736: 
 1737: ![External System Accounts](img/external-system-accounts.png)
 1738: 
 1739: - **Vacations**: combination of consecutive days that employee can take as desired vacation (with checkbox checked). Vacation scheme is created on "References" → "Vacation Scheme" page, massively assigned on "Personnel" → "Business Rules" tab.
 1740: 
 1741: ![Employee Vacations](img/employee-vacations.png)
 1742: 
 1743: - **Schedule**: shows employee's shifts, lunches/breaks and events (see "Current Schedule") according to which they should work. Schedule can also be seen in personal cabinet and exported to Excel.
 1744: 
 1745: ![Employee Schedule](img/employee-schedule.png)
 1746: 
 1747: - **Work hours**: shows number of hours operator should work for specific period (year, quarter, month – depending on system setting). Work hours can be assigned manually through card or "Personnel" → "Work Hours" page, and also received automatically through integration with ERP system (e.g., 1C:Payroll).
 1748: 
 1749: ![Employee Work Hours](img/employee-work-hours.png)
 1750: 
 1751: - **Work rules**: show start, duration and shift rotation for selected time period.
 1752: 
 1753: On "Shift Rotations" tab, you can check checkboxes:
 1754:   - **Assigned**: rotations that system considers when planning work schedule. If several are selected, any of them is chosen depending on need.
 1755:   - **Wishes**: rotations that will be prioritized when planning work schedule. Wish can be marked by operator themselves in personal cabinet (from all checkboxes in this area only this one is available to them), or can be set by senior operator or administrator.
 1756:   - **Lock scheme**: only this rotation will be used for work schedule planning.
 1757: 
 1758: ![Work Rules](img/work-rules.png)
 1759: 
 1760: - **Roles**: responsible for access rights to System functionality. Each role can be configured by User so employees see only blocks from their responsibility area (see "Roles" Reference).
 1761: 
 1762: ![Employee Roles](img/employee-roles.png)
 1763: 
 1764: - **Skills**: used when filtering employees in schedule, monitoring and reporting. You can specify level (beginner, intermediate, champion) and English language proficiency attribute (yes, no).
 1765: 
 1766: **Important!** Skills don't affect planning processes.
 1767: 
 1768: ![Employee Skills](img/employee-skills.png)
 1769: 
 1770: ##### 3.2.1.1 Creating and Editing Employee Card
 1771: 
 1772: Employee card is important system element as it stores information about specific employee's schedule, individual parameter settings, and allows "ARGUS WFM CC" system to consider employee's work schedule when planning schedule.
 1773: 
 1774: To create employee card, click create button:
 1775: 
 1776: ![Create Employee](img/create-employee.png)
 1777: 
 1778: Unfilled card of employee being created will be displayed on right:
 1779: 
 1780: ![Empty Employee Card](img/empty-employee-card.png)
 1781: 
 1782: Specify:
 1783: 
 1784: - **Employee full name**: mandatory fields. If no patronymic – put space
 1785: - **Personnel number**: comes through integration or filled manually
 1786: - **Home operator**: filled manually when necessary. This attribute allows separating office and home employees
 1787: - **Termination date**: comes through integration or filled manually
 1788: - **Hire date**: comes through integration or filled manually
 1789: - **Employee location time zone**: selected from dropdown (filled in "Time Zones" reference)
 1790: - **Department**: comes through integration or filled in "Personnel" - "Departments" block
 1791: - **Position**: comes through integration or filled manually from dropdown (entered in "Positions" reference through database when no integration)
 1792: - **External ID**: comes through integration
 1793: - **Comment**: filled manually when necessary
 1794: 
 1795: To save, click save button. Employee card editing will only be possible after saving mandatory information.
 1796: 
 1797: Function for editing "Full Name", "Personnel Number" and "Home Operator" mark is similar to creation function. To edit previously entered parameters, left-click on any of above fields – they become available for editing, then change needed parameter and click save.
 1798: 
 1799: ![Edit Employee Basic Info](img/edit-employee-basic-info.png)
 1800: 
 1801: Work schedule in employee card is displayed in two views: calendar and tabular:
 1802: 
 1803: ![Work Schedule Views](img/work-schedule-views.png)
 1804: 
 1805: - **Calendar view**: displays employee work days
 1806: - **Tabular view**: displays work hours (horizontally) for employee by days (vertically)
 1807: 
 1808: To change time zone in which work schedule is displayed in tabular view, select desired one from dropdown:
 1809: 
 1810: Work schedule is needed for system to determine work and non-work days. Rotation is needed to determine work day, weekend and shift sequence.
 1811: 
 1812: **Services and groups**: displays information about which group and service employee belongs to. When clicking gear, this list can be edited.
 1813: 
 1814: ![Edit Services Groups](img/edit-services-groups.png)
 1815: 
 1816: **WFM Account**: for system login, employee needs to create account and assign role with access rights for correct system operation.
 1817: 
 1818: To create and edit user accounts, you need "Edit employee account" access right (System_EditLogin).
 1819: 
 1820: To create account, click "Create" button:
 1821: 
 1822: ![Create Account](img/create-account.png)
 1823: 
 1824: Specify mandatory parameters – account login and password. Additionally, you can specify email address. To save data, click save button:
 1825: 
 1826: ![Account Details](img/account-details.png)
 1827: 
 1828: After creating account, you can specify password validity period. For this, left-click on "Password valid until" field and select date in calendar:
 1829: 
 1830: ![Password Validity](img/password-validity.png)
 1831: 
 1832: To save data, click save button.
 1833: 
 1834: **Example**: When employee will soon go on vacation or maternity leave, senior operator can limit password validity date.
 1835: 
 1836: To delete created account, click gear button and select "Delete" from context menu:
 1837: 
 1838: ![Delete Account](img/delete-account.png)
 1839: 
 1840: Then system will ask to confirm action:
 1841: 
 1842: ![Confirm Delete Account](img/confirm-delete-account.png)
 1843: 
 1844: To confirm deletion, click "Yes", to cancel – "No".
 1845: 
 1846: To change account password (for security), click gear button and select "Change password" from context menu:
 1847: 
 1848: ![Change Password](img/change-password.png)
 1849: 
 1850: Then enter new password and repeat it:
 1851: 
 1852: ![Enter New Password](img/enter-new-password.png)
 1853: 
 1854: To save new password, click save button.
 1855: 
 1856: To block account, click gear button and select "Block" from context menu:
 1857: 
 1858: ![Block Account](img/block-account.png)
 1859: 
 1860: Blocked account will display "Blocked since" field showing account blocking date and time:
 1861: 
 1862: ![Blocked Account Display](img/blocked-account-display.png)
 1863: 
 1864: To unblock account, click gear button and select "Unblock" from context menu:
 1865: 
 1866: ![Unblock Account](img/unblock-account.png)
 1867: 
 1868: **Example**: When employee goes on vacation, maternity leave or takes extended sick leave, senior operator should block account, upon return – reactivate it. When blocking password, employee will be displayed in list as active.
 1869: 
 1870: **Roles**: to assign role to employee, check checkbox. To change employee role, uncheck checkbox. One employee can have multiple roles.
 1871: 
 1872: ![Assign Roles](img/assign-roles.png)
 1873: 
 1874: To assign role to operator, you need "Edit Roles block" access right (System_EditWorkerRole).
 1875: 
 1876: **Skills**: to assign appropriate skill level, mark by left-clicking:
 1877: 
 1878: ![Assign Skills](img/assign-skills.png)
 1879: 
 1880: To change previously marked level (was "Beginner", became "Intermediate"), left-click on different level (click "Intermediate").
 1881: 
 1882: If employee knows English, click button. In "English proficiency" parameter, button will change appearance.
 1883: 
 1884: **Contacts**: to add employee contact data, click button and select contact type from dropdown menu:
 1885: 
 1886: ![Add Contact](img/add-contact.png)
 1887: 
 1888: After selecting contact type, fill "Value" and "Description" fields:
 1889: 
 1890: ![Contact Details](img/contact-details.png)
 1891: 
 1892: To save data, click save button.
 1893: 
 1894: To delete, click delete button, to edit – edit button.
 1895: 
 1896: **Vacations**: to create individual vacation scheme setting, set "Minimum time between vacations (Days)", "Maximum vacation shift" and "Vacation scheme":
 1897: 
 1898: ![Vacation Settings](img/vacation-settings.png)
 1899: 
 1900: - **Minimum time between vacations (Days)** – select how many days should pass from last vacation end to assign new vacation
 1901: - **Maximum vacation shift** – determines number of days by which already assigned employee vacation can be moved during work schedule planning (specified in days)
 1902: - **Vacation scheme** – vacation scheme created in "Vacation Schemes" reference is selected here. Vacation scheme sets number of vacations and their duration
 1903: 
 1904: ##### 3.2.1.2 Adding, Deleting Employee Special Events
 1905: 
 1906: Event addition is available to users:
 1907: - with "Administrator" system role or any other role with access rights:
 1908: - System_AddVacationWithoutChecks – allows adding "Planned vacation" and "Unscheduled vacation" events without mandatory checks
 1909: 
 1910: Event editing is available to users with access rights:
 1911: - System_EditMySchedule – allows editing own events in calendar
 1912: - System_EditMySickLeave – editing "Sick leave" event
 1913: - System_EditMyCompLeave – editing "Time off" event
 1914: - System_EditMyPlannedVacation – editing "Desired vacation" event
 1915: - System_EditWorkerApprovedVacationAndExtraWork – allows editing approved vacations and "Call to work" shifts
 1916: - System_EditWorkerPlannedVacation – allows deleting desired vacation
 1917: 
 1918: Special event represents employee event going beyond their work schedule.
 1919: 
 1920: Following events can be registered as special in system:
 1921: - Sick leave (icon on work schedule)
 1922: - Vacation (icon on work schedule)
 1923: - Time off (icon on work schedule)
 1924: - Call to work (icon on work schedule)
 1925: - Reserve (icon on work schedule)
 1926: 
 1927: Employee special event is considered when planning schedule.
 1928: 
 1929: **Adding Special Event**
 1930: 
 1931: **Example 1**: Employee got sick, goes on vacation, took time off. Manager needs to record this event to not consider employee in load forecasting and schedule creation for these dates.
 1932: 
 1933: To add special event, open their card, "Current Work Schedule" block.
 1934: 
 1935: Employee work schedule is displayed in two views: calendar and tabular:
 1936: 
 1937: ![Special Event Calendar](img/special-event-calendar.png)
 1938: 
 1939: Days in calendar view are selected in several ways:
 1940: - One day in calendar is selected by left mouse click
 1941: - Different days in calendar are selected by left mouse click with CTRL pressed
 1942: - Period of days can be selected in two ways:
 1943:   - With SHIFT pressed, select day – interval start, then select day – interval end
 1944:   - With CTRL pressed, sequentially select days from period
 1945: 
 1946: Days in tabular view are selected:
 1947: - One/several days in calendar are selected by area capture. For this, select area while holding left mouse button:
 1948: 
 1949: ![Tabular Selection Area](img/tabular-selection-area.png)
 1950: 
 1951: ![Tabular Selection Result](img/tabular-selection-result.png)
 1952: 
 1953: - You can select specific hours. For this, left-click on hour of interest:
 1954: 
 1955: ![Select Specific Hours](img/select-specific-hours.png)
 1956: 
 1957: - With CTRL pressed, you can select different hours from different days or from one day:
 1958: 
 1959: ![Multiple Hour Selection](img/multiple-hour-selection.png)
 1960: 
 1961: After selecting required period, call context menu with right mouse button and click "Add event":
 1962: 
 1963: ![Add Event Context](img/add-event-context.png)
 1964: 
 1965: ![Add Event Dialog](img/add-event-dialog.png)
 1966: 
 1967: In appeared "Add special event" window:
 1968: - Select required event type from dropdown. If "Time off" is selected, absence reasons from "Absence Reasons" reference will additionally be pulled for it
 1969: - By default, "Selection" parameter is selected in "Period" area. Below are displayed days and hours selected when highlighting them on calendar:
 1970: 
 1971: ![Event Period Selection](img/event-period-selection.png)
 1972: 
 1973: - If you need to specify different date range, select "Range" parameter in "Period" area and specify event start and end date:
 1974: 
 1975: ![Event Date Range](img/event-date-range.png)
 1976: 
 1977: - To save special event, click save button.
 1978: 
 1979: Added special event will be displayed on employee work schedule:
 1980: 
 1981: ![Added Special Event](img/added-special-event.png)
 1982: 
 1983: **Deleting Special Event**
 1984: 
 1985: To delete special event, select days (or at least one day included in special event) on calendar that have special event, call menu by right-clicking and click "Delete event":
 1986: 
 1987: ![Delete Event Context](img/delete-event-context.png)
 1988: 
 1989: ![Delete Event Dialog](img/delete-event-dialog.png)
 1990: 
 1991: Then system will ask to confirm action:
 1992: 
 1993: ![Confirm Delete Event](img/confirm-delete-event.png)
 1994: 
 1995: If selected period included several special events, uncheck those that shouldn't be deleted.
 1996: 
 1997: To confirm special event deletion, click confirm button, to cancel – cancel button.
 1998: 
 1999: **Adding Vacation**
 2000: 
 2001: Operator can add desired vacation in personal cabinet if assigned System_EditMyPlannedVacation access right.
 2002: 
 2003: Manager or any other user with System_AddVacationWithoutChecks access right can assign planned vacation and unscheduled vacation.
 2004: 
 2005: Vacations have three types:
 2006: - **Desired vacation**: set by operator themselves in their personal cabinet (same as operator card). Is operator's wish for vacation dates, considered when planning vacation
 2007: - **Planned vacation**: planned by system under load based on operator's desired vacation or set by operator's manager after reviewing operator's wish or without review. This vacation type is considered when planning work schedules and vacations
 2008: - **Unscheduled vacation**: unplanned vacation (unpaid vacation, vacation at own expense, sick leave vacation, etc.) set by manager. Considered when planning vacations and work schedules
 2009: 
 2010: To add Desired vacation, right-click any date in tabular or calendar view, then "Add event" and select Desired vacation:
 2011: 
 2012: ![Add Desired Vacation](img/add-desired-vacation.png)
 2013: 
 2014: In opened window, select "Vacation scheme", vacation creation method ("Period" or "Calendar days"), specify vacation dates according to "Vacation schemes".
 2015: 
 2016: **Note**: When setting vacations according to "Vacation schemes", there's no need to follow vacation sequence set in selected scheme, it's sufficient to follow total number of vacations and days in vacations.
 2017: 
 2018: If "Period" vacation creation method is selected:
 2019: - Need to specify vacation start and end date
 2020: - Vacation doesn't shift if holidays fall in its period (e.g., vacation set from 25.04 to 08.05. Despite one holiday falling in this period: "May 1", vacation doesn't shift. Work return date – 09.05)
 2021: - From accumulated vacation days, number of days considering holidays is subtracted (e.g., vacation set for 14 days with 1 holiday in period. 13 days are subtracted from accumulated days, not 14)
 2022: 
 2023: If "Calendar days" vacation creation method is selected:
 2024: - Need to specify vacation start date and number of vacation days (vacation end date will be pulled automatically)
 2025: - Vacation shifts by number of holidays (e.g., vacation set for 14 calendar days from 25.04 to 08.05. This period includes one holiday "May 1", so vacation shifts to 09.05. But "May 9" is also holiday, so vacation shifts again. Work return date – 11.05)
 2026: - From accumulated vacation days, number of days without considering holidays is subtracted (in above example, 14 vacation days will be subtracted from accumulated days)
 2027: 
 2028: **Note**: When selecting vacation dates, consider individual vacation scheme settings. If they are violated, user will receive warning and vacation won't be assigned. However, if manager assigns vacation, they'll get "Confirm" button to assign schedule bypassing operator's personal vacation settings. Also consider "Accumulated vacation days" setting from "Labor Standards" reference. If vacation is set exceeding accumulated days, depending on settings system will either allow assigning such vacation, show warning and not assign vacation, or show warning and offer to assign vacation anyway.
 2029: 
 2030: When setting vacation dates, user is helped by field showing accumulated vacation days number – number of vacation days remaining for operator after assigning vacation dates. Days number comes through 1C integration. Example: operator has 10 vacation days remaining on 01.06.2018. Once vacation is set from 01.06.2018 to 07.06.2018, they'll have 3 vacation days left and same value will be displayed in "Accumulated days number" field.
 2031: 
 2032: Without 1C integration, accumulated vacation days number can be entered by script through database by ARGUS NTC specialists, but most often this field is ignored in such cases.
 2033: 
 2034: After filling all data, confirm vacation creation or cancel changes. After creating vacation, it can be seen by setting "Desired vacation" filter (if desired vacation was created) or "Planned vacation" filter (if planned vacation was created) in tabular mode.
 2035: 
 2036: ![Vacation Filter](img/vacation-filter.png)
 2037: 
 2038: **Unscheduled Vacation**
 2039: 
 2040: To add unscheduled vacation, right-click needed date in tabular or calendar mode and click "Add event" and select "Unscheduled vacation" event:
 2041: 
 2042: ![Add Unscheduled Vacation](img/add-unscheduled-vacation.png)
 2043: 
 2044: When selecting "Unscheduled vacation" type, specify vacation start and end date in dialog. If there's additional setting, fill "Comment" field.
 2045: 
 2046: When adding "Unscheduled vacation" to employee, accumulated vacation days are not subtracted.
 2047: 
 2048: ![Unscheduled Vacation Details](img/unscheduled-vacation-details.png)
 2049: 
 2050: ##### 3.2.1.3 Viewing Work Hours Statistics for Current Period, Individual Work Hours Standard Correction
 2051: 
 2052: Correction actions are available to users with "Administrator" role or any other role with "Assign work hours for period in employee card" access right (System_EditWorkerNormHours).
 2053: 
 2054: **Work hours** – number of hours operator should work during reporting period.
 2055: 
 2056: Each operator can have their own work hours, so WFM CC system implements possibility to set work hours standard individually (see below) and massively (3.2.6. Mass Work Hours Assignment).
 2057: 
 2058: **Reporting period** – period for which operator should work their work hours.
 2059: 
 2060: To calculate work hours by standard and work hours by schedule in "Work hours by years" area, select needed year:
 2061: 
 2062: ![Work Hours By Years](img/work-hours-by-years.png)
 2063: 
 2064: Below year selection, table with following data will be displayed:
 2065: - **Period**: current reporting period
 2066: - **Standard**: number of hours operator should work during reporting period in current month
 2067: - **By schedule**: number of work hours in shift (according to work schedule assigned to employee) and all work call wishes (if operator is home) for current month reporting period
 2068: 
 2069: ![Work Hours Table](img/work-hours-table.png)
 2070: 
 2071: Values in this table are displayed according to setting in "Mass Work Hours Assignment" section. In cases of individual operator work hours, system allows correcting them in this table.
 2072: 
 2073: To assign individual work hours standard, select needed year, left-click on "Work hours" column and specify hours in HH:M format in available input fields (e.g., 1972:0 if work hours are annual).
 2074: 
 2075: To get work hours standard from 1C through integration, select year for which to get work hours and click get button.
 2076: 
 2077: ![Get Work Hours](img/get-work-hours.png)
 2078: 
 2079: If work hours were previously received for operator for entire year, but after receiving value they resign (same year), to update work hours value need to re-request it in 1C by clicking get button.
 2080: 
 2081: ##### 3.2.1.4 Employee Deactivation and Activation
 2082: 
 2083: To deactivate employee card, select them in list and click "Deactivate employee" button. If employee has account for system login, it's automatically blocked upon deactivation.
 2084: 
 2085: ![Deactivate Employee](img/deactivate-employee.png)
 2086: 
 2087: **Example**: If employee went on extended vacation, sick leave or maternity leave, and senior operator finds it inconvenient that they're displayed in employee list, senior operator can deactivate employee.
 2088: 
 2089: **Important!** When employee who needs to be deactivated participates in current schedule at deactivation moment and after, then:
 2090: 
 2091: 1) In deactivated employee's work schedule after deactivation, shifts will be displayed according to current schedule
 2092: 2) When creating schedule that intersects current schedule, deactivated employee will be displayed in new schedule. To prevent this, after employee deactivation, coordinator should update current schedule with "Update only changed intervals" parameter
 2093: 
 2094: To restore (activate) previously deactivated employee, select them in list and click "Activate employee" button. Since employee account is blocked upon deactivation, after restoring such employee, their account needs to be unblocked:
 2095: 
 2096: ![Activate Employee](img/activate-employee.png)
 2097: 
 2098: **Example**: If employee returned from maternity leave, their card needs to be activated.
 2099: 
 2100: ##### 3.2.1.5 Shift Exchange
 2101: 
 2102: Operator can exchange shifts or vacation with other operators. For shift exchange, work schedule must be planned. Exchange request is created from operator's personal card:
 2103: 
 2104: ![Shift Exchange](img/shift-exchange.png)
 2105: 
 2106: Select shift in tabular or calendar view with left mouse button, call context menu with right mouse button and select "Shift exchange". In opened window, specify shift work date:
 2107: 
 2108: ![Shift Exchange Dialog](img/shift-exchange-dialog.png)
 2109: 
 2110: Shift exchange request appears on WFM CC main screen. Depending on who views requests, display will change.
 2111: 
 2112: If viewed by employee who cannot accept exchange request:
 2113: 
 2114: ![Cannot Accept Exchange](img/cannot-accept-exchange.png)
 2115: 
 2116: If viewed by employee who can accept shift exchange request:
 2117: 
 2118: ![Can Accept Exchange](img/can-accept-exchange.png)
 2119: 
 2120: If viewed by operator themselves:
 2121: 
 2122: ![Own Exchange Request](img/own-exchange-request.png)
 2123: 
 2124: Operator can cancel shift exchange request by clicking cancel button. They see not only their request but also requests from operators in same parent department.
 2125: 
 2126: When shift exchange request appears, any operator from same parent department who has matching rest and work days with exchange wish and same shift duration can agree to shift exchange.
 2127: 
 2128: If shift exchange request is confirmed by another operator, request is displayed to employee manager. Manager needs to either confirm or reject exchange request. In manager's personal cabinet, exchange request is displayed as follows:
 2129: 
 2130: ![Manager Exchange View](img/manager-exchange-view.png)
 2131: 
 2132: If shift exchange request is confirmed by department manager, request status changes to "Confirmed".
 2133: 
 2134: ![Confirmed Exchange](img/confirmed-exchange.png)
 2135: 
 2136: If request is rejected, status changes to "rejected":
 2137: 
 2138: ![Rejected Exchange](img/rejected-exchange.png)
 2139: 
 2140: **Important!** If operator has exchange request in "Not confirmed", "Confirmed", "Awaiting confirmation" statuses, they cannot agree to other requests where "Required replacement date" and/or "Work date" match.
 2141: 
 2142: ##### 3.2.1.6 Vacation Exchange
 2143: 
 2144: Operators can exchange vacations through personal cabinet. Functionality is similar to shift exchange. Operators exchanging vacations must be in same department and vacation days number must match. Only planned vacations can be exchanged. To exchange vacation, go to personal cabinet, select your approved vacation and click "Vacation exchange":
 2145: 
 2146: ![Vacation Exchange](img/vacation-exchange.png)
 2147: 
 2148: Then set vacation date you want to exchange to:
 2149: 
 2150: ![Vacation Exchange Date](img/vacation-exchange-date.png)
 2151: 
 2152: Operator who created request can cancel it. Operator who wants to accept vacation exchange should click accept button when they see suitable vacation:
 2153: 
 2154: ![Accept Vacation Exchange](img/accept-vacation-exchange.png)
 2155: 
 2156: After which status changes to "Awaiting approval":
 2157: 
 2158: ![Vacation Exchange Awaiting](img/vacation-exchange-awaiting.png)
 2159: 
 2160: Now exchange must be confirmed by Department Manager:
 2161: 
 2162: ![Manager Vacation Approval](img/manager-vacation-approval.png)
 2163: 
 2164: Similar to shift exchange, status can change to "Confirmed" if request was approved or "Rejected" if request was rejected:
 2165: 
 2166: ![Vacation Exchange Confirmed](img/vacation-exchange-confirmed.png)
 2167: 
 2168: ##### 3.2.1.7 Vacation Transfer
 2169: 
 2170: If operator needs to change planned vacation dates during the year, operator can submit vacation transfer request through Personal Cabinet. For this, in Personal Cabinet select vacation, right-click and select "Vacation transfer":
 2171: 
 2172: ![Vacation Transfer](img/vacation-transfer.png)
 2173: 
 2174: Then set new vacation start date:
 2175: 
 2176: ![Vacation Transfer Date](img/vacation-transfer-date.png)
 2177: 
 2178: After "Vacation transfer" confirmation by department manager where operator belongs, vacation transfer request appears on start page. Manager can confirm or reject transfer, and also cancel request completely. When selecting "Cancel request" option, manager completely cancels vacation exchange possibility for selected dates.
 2179: 
 2180: ![Manager Vacation Transfer](img/manager-vacation-transfer.png)
 2181: 
 2182: ![Vacation Transfer Actions](img/vacation-transfer-actions.png)
 2183: 
 2184: When manager confirms "Vacation transfer" request, planned vacation date is updated in applied work schedule and employee's Personal Cabinet.
 2185: 
 2186: #### 3.2.2 Groups {#groups}
 2187: 
 2188: The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Groups page" access right (System_AccessGroupList).
 2189: 
 2190: The page is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit groups" access right (System_EditGroup).
 2191: 
 2192: To unite employees by their functional duties, "ARGUS WFM CC" system implements possibility of creating groups.
 2193: 
 2194: The "Groups" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Groups" block:
 2195: 
 2196: ![Groups Section Access](img/groups-section-access.png)
 2197: 
 2198: ![Groups Main Page](img/groups-main-page.png)
 2199: 
 2200: By default, system displays all active groups of all types (button pressed). To view all groups (active/deactivated) or only deactivated ones, click corresponding button. To view only simple/aggregated/all groups, click and select needed filter:
 2201: 
 2202: ![Groups Filters](img/groups-filters.png)
 2203: 
 2204: For search, start typing group name in search bar and system will display matches:
 2205: 
 2206: ![Groups Search](img/groups-search.png)
 2207: 
 2208: In groups list, click on group of interest. Complete information about selected group will be displayed to the right:
 2209: 
 2210: ![Group Details](img/group-details.png)
 2211: 
 2212: Group card consists of following blocks:
 2213: 
 2214: - **General information**
 2215:   - Group name
 2216:   - Description: free field for filling. For example, you can specify what exactly the group does
 2217:   - External ID: appears if group is created through integration with contact center
 2218:   - Integration system: system from which group was received (see "Integration Systems" reference)
 2219:   - Group type: simple or aggregated. Difference is that aggregated group can include several simple ones. Aggregation is useful for mass load forecasting
 2220:   - Channel type: group belonging to channel type if same-name reference is filled
 2221:   - Priority: number from 1 to 100 showing significance of group during planning (where 1 is least, 100 is most)
 2222: 
 2223: - **Services**: displays services that include this group. Clicking service name allows going to service card
 2224: 
 2225: **Note**: aggregated group should belong to same service as simple groups included in this aggregated group
 2226: 
 2227: - **Monitoring settings**: select what data will be used for calculating value on "Resource Requirements" dashboard:
 2228:   - Channel type: Voice channel, Non-voice channel, Non-voice channel considering SLA (operator number calculation by voice channel algorithm but considering simultaneous contacts number)
 2229:   - SLA calculation: Reverse Erlang formula, Actually processed calls
 2230: 
 2231: - **Group structure**: multi-level functional group structure consisting of segments
 2232: 
 2233: - **Default operator number forecast parameters**: specify operator calculation parameters that will be automatically set when forecasting load and subsequent operator number calculation
 2234: 
 2235: - **Default parameters**: select "Forecast accuracy calculation mode" using marker - By intervals, By hours, By days
 2236: 
 2237: - **Operators**: displays operators included in group. If user views "aggregated" group, instead of "Operators" area they'll have "Simple groups" area:
 2238: 
 2239: ![Aggregated Group Simple Groups](img/aggregated-group-simple-groups.png)
 2240: 
 2241: ##### 3.2.2.1 Creating New Group
 2242: 
 2243: To create new group, click create button and select group type – simple or aggregated.
 2244: 
 2245: ![Create Group Type](img/create-group-type.png)
 2246: 
 2247: Then group creation template appears on right. Mandatory fields – "Name", "Priority" (default 1). "External ID" field will only be filled if group came to WFM CC through integration from external system.
 2248: 
 2249: ![Group Creation Template](img/group-creation-template.png)
 2250: 
 2251: After filling above fields, click save button to save.
 2252: 
 2253: To add operators to new group, click add button in "Operators" area. In opened window, select operators who will belong to this group. Search is implemented by "Surname" and "Personnel Number" fields. To save selected operator composition, click save button.
 2254: 
 2255: ![Add Operators to Group](img/add-operators-to-group.png)
 2256: 
 2257: ##### 3.2.2.2 Editing Group Description and Operator Composition
 2258: 
 2259: To edit group, select it in list and left-click on area with group name and description in right part – change description and click save button.
 2260: 
 2261: ![Edit Group Description](img/edit-group-description.png)
 2262: 
 2263: **Example 1**: Group got new tasks → change group description.
 2264: 
 2265: **Example 2**: New employee skills appeared. Accordingly, employees can perform new tasks → add them to groups for consideration in load forecasting.
 2266: 
 2267: **Example 3**: Operator was promoted or got certain skills and transferred to another group → remove employee from group since we no longer consider them in forecasting for this group, and add them to another group since we now consider them in forecast for another.
 2268: 
 2269: To add operators to new group, in opened window select operators who will belong to new group. Search is implemented by "Surname" and "Personnel Number" fields. To save selected operator composition, click save button. Added employees will be displayed in "Operators" area:
 2270: 
 2271: ![Added Operators Display](img/added-operators-display.png)
 2272: 
 2273: To remove previously added employees from group, select them in list using checkbox and click "Delete":
 2274: 
 2275: ![Remove Operators from Group](img/remove-operators-from-group.png)
 2276: 
 2277: System will ask to confirm action. Click "Yes" to confirm, "No" to cancel:
 2278: 
 2279: ![Confirm Remove Operators](img/confirm-remove-operators.png)
 2280: 
 2281: ##### 3.2.2.3 Group Deletion and Deactivation
 2282: 
 2283: To deactivate, select group from list and click deactivate button:
 2284: 
 2285: ![Deactivate Group](img/deactivate-group.png)
 2286: 
 2287: Deactivated group can be restored. For this, select inactive filter, then needed group and click activate button:
 2288: 
 2289: ![Activate Group](img/activate-group.png)
 2290: 
 2291: To delete group, select needed active or deactivated group and click delete button. Deleted group cannot be restored.
 2292: 
 2293: ![Delete Group](img/delete-group.png)
 2294: 
 2295: #### 3.2.3 Services {#services}
 2296: 
 2297: The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Services page" access right (System_AccessServiceList).
 2298: 
 2299: The page is available for editing to users with "Administrator" system role or any other role with "Edit services" access right (System_EditService).
 2300: 
 2301: Created services are considered by "ARGUS WFM CC" system when planning load and creating schedules.
 2302: 
 2303: The "Services" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Services" block:
 2304: 
 2305: ![Services Section Access](img/services-section-access.png)
 2306: 
 2307: By default, system displays all active services (button pressed). To view all services (active/deactivated) or only deactivated ones, click corresponding button.
 2308: 
 2309: For search, start typing service name in search bar and system will display matches:
 2310: 
 2311: ![Services Search](img/services-search.png)
 2312: 
 2313: In services list, click on service of interest. Following information will be displayed to the right:
 2314: 
 2315: ![Service Details](img/service-details.png)
 2316: 
 2317: Group card consists of following blocks:
 2318: 
 2319: - **General information**
 2320:   - Service name
 2321:   - Description: free field for filling. For example, you can specify what exactly the service does
 2322:   - External ID: external service ID by which integration determines service in its structure
 2323:   - Integration system: system from which service was received (see "Integration Systems" reference)
 2324: 
 2325: - **Groups**: displays groups included in service
 2326: 
 2327: - **Operators** area displays operators included in selected group in "Groups" area
 2328: 
 2329: ##### 3.2.3.1 Creating Service
 2330: 
 2331: To create new service, click create button, then fill data.
 2332: 
 2333: ![Create Service](img/create-service.png)
 2334: 
 2335: Only "Name" field is mandatory. "Description" and "External ID" are not mandatory, but "External ID" field is necessary for contact center synchronization. After filling information, click save button to save.
 2336: 
 2337: Then use search or checkbox to select group that will belong to service and click save button to save.
 2338: 
 2339: ![Select Service Groups](img/select-service-groups.png)
 2340: 
 2341: ![Service Groups Display](img/service-groups-display.png)
 2342: 
 2343: ##### 3.2.3.2 Editing Service Description and Operator Composition of Groups Included in Services
 2344: 
 2345: To edit service description, select it in list, left-click on area with service name and description in right part, change any field and click save button.
 2346: 
 2347: **Example**: Service got new functional duties. We recommend editing its name and description.
 2348: 
 2349: ![Edit Service Description](img/edit-service-description.png)
 2350: 
 2351: **Editing Operator Composition**
 2352: 
 2353: If you select previously added group in "Groups" area, system will display all employees included in group below ("Operators" area):
 2354: 
 2355: ![Service Operators Display](img/service-operators-display.png)
 2356: 
 2357: Employees included in group can be filtered by department.
 2358: 
 2359: To add new operators to group, click "Add" button and in appeared window select employee(s) using checkbox and click save button.
 2360: 
 2361: **Example**: Employees got new skills – means employees can perform new tasks. To consider them in load forecasting, employees need to be added to corresponding groups.
 2362: 
 2363: ##### 3.2.3.3 Service Deactivation and Deletion
 2364: 
 2365: To deactivate service, select needed service from list then click deactivate button:
 2366: 
 2367: ![Deactivate Service](img/deactivate-service.png)
 2368: 
 2369: To restore deactivated service, select inactive filter, then select needed service and click activate button:
 2370: 
 2371: ![Activate Service](img/activate-service.png)
 2372: 
 2373: To delete service, select active or deactivated service and click delete button:
 2374: 
 2375: ![Delete Service](img/delete-service.png)
 2376: 
 2377: Deleted service cannot be restored.
 2378: 
 2379: #### 3.2.4 Departments {#departments}
 2380: 
 2381: The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Departments page" access right (System_DepartmentsView).
 2382: 
 2383: The page is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit organizational structure" access right (System_DepartmentsEdit).
 2384: 
 2385: Departments store organizational structure of operators, their hierarchy and department managers. Structure itself can be created manually or received through integration, depending on personnel structure receiving settings. Unlike groups, one operator can only be in one department.
 2386: 
 2387: To view departments, open side menu and go to "Personnel → Departments".
 2388: 
 2389: ![Departments Access](img/departments-access.png)
 2390: 
 2391: When opening page, following information will be displayed:
 2392: 
 2393: ![Departments Interface](img/departments-interface.png)
 2394: 
 2395: Left side shows department structure. Departments can be parent and child. To create department, click create button. Name department and select its manager from dropdown. Manager plays important (main) role in work schedule confirmation, can also build department reports but only for their own. To deactivate department, click deactivate button.
 2396: 
 2397: Upper part of page shows department information: external id (comes through integration with external systems), its manager, name and "Participates in approval" checkbox. This checkbox allows department manager, their deputy and child department managers to participate in work schedule approval processes, work schedule change approval, operator wish approval.
 2398: 
 2399: To change department information, click on corresponding field. To change manager, enter their surname and select suitable employee from dropdown.
 2400: 
 2401: Below is information about deputies and operators included in department.
 2402: 
 2403: Deputy performs same actions as manager in system but only during their substitution.
 2404: 
 2405: ![Department Deputies](img/department-deputies.png)
 2406: 
 2407: Possibility to assign deputies is available to users with "Administrator", "Senior Operator" system role or any other role with "Assign manager deputies" access right (System_DeputyEdit).
 2408: 
 2409: During manager absence, deputy becomes department manager. Direct manager retains their rights. To add deputy, click add button, enter deputy surname and period when they will substitute manager:
 2410: 
 2411: ![Add Deputy](img/add-deputy.png)
 2412: 
 2413: To delete deputy, click delete button.
 2414: 
 2415: Employees in department show names and positions that also come through integration. To manually add employee, click add button and enter their name and click save button.
 2416: 
 2417: ![Add Employee to Department](img/add-employee-to-department.png)
 2418: 
 2419: Employees can be moved between departments. For this, select needed operators, click move button and select department to transfer employees to.
 2420: 
 2421: ![Move Employees](img/move-employees.png)
 2422: 
 2423: Department employees and department structure itself come through integration with external systems. If employee was moved from parent department received through synchronization to manually created child department, during re-synchronization this operator will remain in child department. Also if integration provides information that parent department is deactivated, all its manually created child departments will also be deactivated.
 2424: 
 2425: #### 3.2.5 Mass Assignment of Business Rules and Vacation Schemes {#mass-assignment-business-rules}
 2426: 
 2427: When configuring employee cards, assigning business rules to specific employee was described. For convenience, "ARGUS WFM CC" system implements possibility of mass business rule assignment to group of employees working under one standard ("Business Rules" section).
 2428: 
 2429: "Business Rules" section can be accessed either through "Personnel" tab from sections list menu "Business Rules" or from main page by clicking "Mass Assignment" button.
 2430: 
 2431: ![Mass Assignment Access](img/mass-assignment-access.png)
 2432: 
 2433: Left part of page displays employee list:
 2434: 
 2435: ![Mass Assignment Employee List](img/mass-assignment-employee-list.png)
 2436: 
 2437: By default, system displays employee list for all groups. To filter employee list, use following parameters:
 2438: 
 2439: - **Departments**: allows filtering operator list by department they belong to
 2440: - **Segment**: allows filtering operator list by segment they belong to
 2441: - **Groups**: allows filtering operator list by checking checkbox next to desired group
 2442: - **Type**: allows filtering operator list by selecting one of options (office or home operators)
 2443: - **Search**: allows selecting specific operators by entering Surname and Personnel Number (search by full or partial match)
 2444: 
 2445: To assign lunch/break business rule, use same logic described in section 3.1.11 "Lunches/Breaks Reference".
 2446: 
 2447: To assign vacation schemes, fill vacation parameters and select needed vacation scheme (can select more than one).
 2448: 
 2449: ![Vacation Scheme Assignment](img/vacation-scheme-assignment.png)
 2450: 
 2451: **Minimum time between vacations (Days)**: specify number of days that should pass from last vacation end to assign new vacation.
 2452: 
 2453: **Maximum vacation shift**: specify number of days by which already assigned employee vacation can be moved during work schedule planning (specified in days).
 2454: 
 2455: **Vacation scheme**: select vacation scheme from previously created in "Vacation Schemes" reference. Vacation scheme sets number of vacations and their duration.
 2456: 
 2457: After forming business rules, they need to be mass assigned to employees. For this, select needed employees in list (by checking checkbox) and click "Apply to selected" button.
 2458: 
 2459: ![Apply to Selected](img/apply-to-selected.png)
 2460: 
 2461: In case of successful assignment, system will display corresponding message:
 2462: 
 2463: ![Assignment Success](img/assignment-success.png)
 2464: 
 2465: #### 3.2.6 Mass Assignment of Work Hours {#mass-assignment-work-hours}
 2466: 
 2467: Mass work hours assignment is available to users with "Administrator" role or any other role with "Mass work hours assignment for period" access right (System_AccessNormHours).
 2468: 
 2469: **Work hours** – number of hours operator should work during reporting period.
 2470: 
 2471: For convenience, WFM CC system implements possibility to assign work hours standard massively (work hours are set for year, quarter or month). Work hours can be assigned manually or received through integration. By default – through integration.
 2472: 
 2473: To open section, go to "Personnel" → "Work Hours" tab:
 2474: 
 2475: ![Work Hours Access](img/work-hours-access.png)
 2476: 
 2477: **Manual Work Hours Assignment**
 2478: 
 2479: On opened mass assignment page, fill following parameters:
 2480: 
 2481: ![Work Hours Assignment](img/work-hours-assignment.png)
 2482: 
 2483: - **Service**: select from dropdown
 2484: - **Group**: select from dropdown. List will display groups included in previously selected service
 2485: - **Department**: select department if necessary
 2486: - **Year**: select year for which work hours standard is planned
 2487: 
 2488: After filling above parameters, section with two blocks will be displayed:
 2489: 
 2490: ![Work Hours Blocks](img/work-hours-blocks.png)
 2491: 
 2492: Block 1 is table with following columns:
 2493: 
 2494: - **Work hours**: specify work hours for selected period of specified year. If work hours are quarterly/monthly, need to specify for each quarter/month
 2495: - **Reporting period start**: pulled automatically
 2496: - **Reporting period end**: pulled automatically
 2497: 
 2498: After specifying all parameters, click confirm button to confirm changes or cancel button to cancel.
 2499: 
 2500: ![Work Hours Confirmation](img/work-hours-confirmation.png)
 2501: 
 2502: After saving work hours standards in block 1, select employees (included in specified group) in block 2 who need mass work hours standard assignment. To select all employees, check topmost checkbox:
 2503: 
 2504: ![Select All Employees](img/select-all-employees.png)
 2505: 
 2506: To select individual operators, check checkbox next to them:
 2507: 
 2508: ![Select Individual Employees](img/select-individual-employees.png)
 2509: 
 2510: Click apply button to apply specified parameters.
 2511: 
 2512: System will report successful work hours standard assignment for selected employees.
 2513: 
 2514: ![Work Hours Assignment Success](img/work-hours-assignment-success.png)
 2515: 
 2516: Assigned work hours will be displayed in selected employee cards.
 2517: 
 2518: **Getting Work Hours Through Integration**
 2519: 
 2520: If setting allowing getting load through integration is enabled (set in database), "Assign" button will be replaced with "Get":
 2521: 
 2522: ![Get Work Hours Integration](img/get-work-hours-integration.png)
 2523: 
 2524: To get work hours through integration, select service, group and year. Then select employees for whom to get work hours and click get button.
 2525: 
 2526: ![Get Work Hours Process](img/get-work-hours-process.png)
 2527: 
 2528: Now work hours are received and recorded in operator card.
 2529: 
 2530: #### 3.2.7 Personnel Synchronization Reference {#personnel-synchronization-reference}
 2531: 
 2532: The reference is available for viewing to users with "Administrator" system role or any other role with "View Personnel Synchronization page" access rights (System_AccessSynchronizationPersonnel).
 2533: 
 2534: "Update Settings" block is available to users with "Administrator" system role or any other role with "Configure automatic personnel synchronization" access rights (System_EditSynchronizationPersonnel).
 2535: 
 2536: Possibility to perform actions in "Personnel Synchronization" block is available to users with "Administrator" role or any other role with "Perform personnel synchronization" access right (System_AccessSynchronization).
 2537: 
 2538: "Personnel Synchronization" reference settings are applied to set parameters according to which automatic synchronization of groups, services and departments between WFM CC and external systems will be performed, namely: through integration, information about created/edited services/groups/departments/employees in external system will be transmitted to WFM CC system, including information about group inclusion in services, employees in groups.
 2539: 
 2540: Automatic personnel synchronization uses integration procedures between interacting external systems and "ARGUS WFM CC".
 2541: 
 2542: Also this reference implements possibility to analyze received data from external system and apply this data in WFM.
 2543: 
 2544: To access reference, open side menu and select "Personnel" → "Personnel Synchronization" tab:
 2545: 
 2546: ![Personnel Synchronization Access](img/personnel-synchronization-access.png)
 2547: 
 2548: Opened page consists of update settings blocks and "Personnel Synchronization" block:
 2549: 
 2550: ![Personnel Synchronization Interface](img/personnel-synchronization-interface.png)
 2551: 
 2552: To change update settings parameters, click on settings block field and set necessary values.
 2553: 
 2554: ![Update Settings](img/update-settings.png)
 2555: 
 2556: **Personnel data receiving frequency from contact center**
 2557: 
 2558: Select one of three from dropdown: monthly/weekly/daily. Depending on selected frequency, update parameters can be different.
 2559: 
 2560: - **Receiving frequency = Monthly**
 2561: 
 2562: ![Monthly Frequency](img/monthly-frequency.png)
 2563: 
 2564:   - Week number in month: select which week of month to perform personnel synchronization: first/second/third/fourth/last
 2565:   - Weekday: select weekday when update will be performed. If week number is first and weekday is Saturday, personnel synchronization will be performed on Saturday of first week
 2566:   - Time: specify forecast update time
 2567:   - Time zone: specify update time zone
 2568: 
 2569: - **Receiving frequency = Weekly**
 2570: 
 2571: ![Weekly Frequency](img/weekly-frequency.png)
 2572: 
 2573:   - Weekday: select weekday when update will be performed
 2574:   - Time: specify forecast update time
 2575:   - Time zone: specify update time zone
 2576: 
 2577: - **Receiving frequency = Daily**
 2578: 
 2579: ![Daily Frequency](img/daily-frequency.png)
 2580: 
 2581:   - Time: specify forecast update time
 2582:   - Time zone: specify update time zone
 2583: 
 2584: To save changes, click save button.
 2585: 
 2586: **Personnel Synchronization Block**
 2587: 
 2588: In "Personnel Synchronization" block, you can perform following actions:
 2589: 
 2590: - **Get personnel structure**: receives current personnel structure from external system
 2591: - **Apply changes**: applies changes received from external system to WFM CC
 2592: - **View changes**: allows viewing what changes will be applied before actually applying them
 2593: 
 2594: ![Personnel Sync Actions](img/personnel-sync-actions.png)
 2595: 
 2596: When getting personnel structure, system will display received data and allow analyzing it before applying. This helps ensure correct data before making changes to WFM CC system.
 2597: 
 2598: #### 3.2.8 Operator Data Collection {#operator-data-collection}
 2599: 
 2600: This section allows collecting and analyzing various operator data for reporting and analytics purposes. Data can be collected automatically through integration or entered manually.
 2601: 
 2602: Available data collection includes:
 2603: - Work time statistics
 2604: - Call handling metrics
 2605: - Schedule adherence data
 2606: - Performance indicators
 2607: 
 2608: ![Operator Data Collection](img/operator-data-collection.png)
 2609: 
 2610: Data collection helps in:
 2611: - Performance analysis
 2612: - Schedule optimization
 2613: - Resource planning
 2614: - Compliance monitoring
 2615: 
 2616: ---
 2617: 
 2618: ## 4. Load Forecasting in ARGUS WFM CC System {#load-forecasting}
 2619: 
 2620: The load forecasting module is one of the core components of the ARGUS WFM CC system. It allows predicting future call volumes and operator requirements based on historical data analysis, seasonal patterns, and special events.
 2621: 
 2622: ### Key Forecasting Features:
 2623: 
 2624: - **Historical Data Analysis**: Import and analyze past call volumes and handling times
 2625: - **Trend Analysis**: Identify long-term patterns in call volume changes
 2626: - **Seasonal Component Analysis**: Account for daily, weekly, monthly, and yearly seasonal variations
 2627: - **Peak Analysis**: Identify and smooth out anomalous peak values
 2628: - **Special Events**: Configure special dates that affect normal call patterns
 2629: - **Multiple Forecasting Models**: Support for different calculation methods including Erlang C, Linear models, and SLA-based approaches
 2630: 
 2631: ### Forecasting Process:
 2632: 
 2633: 1. **Data Import**: Historical call data is imported from external systems or files
 2634: 2. **Data Validation**: Review and clean historical data, excluding outliers
 2635: 3. **Trend Analysis**: Identify underlying growth or decline patterns
 2636: 4. **Seasonal Analysis**: Calculate seasonal coefficients for different time periods
 2637: 5. **Forecast Generation**: Generate future call volume predictions
 2638: 6. **Operator Calculation**: Convert call forecasts to operator requirements
 2639: 7. **Forecast Accuracy**: Monitor and improve forecast precision over time
 2640: 
 2641: ![Load Forecasting Process](img/load-forecasting-process.png)
 2642: 
 2643: The forecasting module integrates closely with scheduling to ensure optimal staffing levels while maintaining service quality standards.
 2644: 
 2645: ---
 2646: 
 2647: ## 5. Load Viewing {#load-viewing}
 2648: 
 2649: The Load Viewing module provides comprehensive visibility into current and forecasted workload across all groups and services.
 2650: 
 2651: ### 5.1 Viewing Load for Groups
 2652: 
 2653: Load can be viewed at different organizational levels:
 2654: - Service level aggregation
 2655: - Individual group details
 2656: - Time-based filtering (daily, weekly, monthly)
 2657: - Real-time vs. forecasted comparisons
 2658: 
 2659: ### 5.2 Forecast Corrections
 2660: 
 2661: The system allows making adjustments to generated forecasts:
 2662: 
 2663: #### 5.2.1 Updating Forecasted Operator Numbers
 2664: Modify predicted operator requirements based on business changes or new information.
 2665: 
 2666: #### 5.2.2 Operator Count Adjustment with Reserve Coefficient
 2667: Apply safety margins to ensure adequate staffing during uncertain periods.
 2668: 
 2669: #### 5.2.3 Call Volume Adjustment with Growth Factor
 2670: Adjust forecasted call volumes to account for business growth or decline.
 2671: 
 2672: #### 5.2.4 Forecast Adjustment with Minimum Operator Count
 2673: Set minimum staffing levels regardless of forecasted demand.
 2674: 
 2675: ### 5.3 Load Import from File
 2676: 
 2677: Alternative method to input load data:
 2678: 
 2679: #### 5.3.1 Import Ready Call Forecast
 2680: Import pre-calculated call volume predictions from external sources.
 2681: 
 2682: #### 5.3.2 Import Ready Operator Forecast
 2683: Import pre-calculated operator requirement forecasts.
 2684: 
 2685: ---
 2686: 
 2687: *[This translation covers pages 1-199 of the 462-page document. The translation maintains the original structure, technical terminology, and formatting while providing clear English equivalents for all Russian terms and concepts.]*