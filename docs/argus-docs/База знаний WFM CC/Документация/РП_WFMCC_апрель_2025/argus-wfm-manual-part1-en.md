# ARGUS WFM CC User Manual
## Workforce Management for Call Centre - User Guide (April 2025)

### Table of Contents

1. [Introduction](#introduction)
   1. [About the ARGUS WFM CC System](#about-system)
   2. [Goals of the ARGUS WFM CC System](#system-goals)
   3. [Automation Object Characteristics](#automation-characteristics)
   4. [Roles in the ARGUS WFM CC System](#system-roles)

2. [Getting Started](#getting-started)
   1. [System Login](#system-login)
   2. [General Interface Description](#interface-description)

3. [Administrator Workstation](#administrator-workstation)
   1. [Reference Configuration](#reference-configuration)
      1. [Work Rules Reference](#work-rules-reference)
      2. [Events Reference](#events-reference)
      3. [Production Calendar Reference](#production-calendar-reference)
      4. [Roles Reference](#roles-reference)
      5. [Positions Reference](#positions-reference)
      6. [Work Time Efficiency Configuration Reference](#work-time-efficiency-reference)
      7. [Special Events Reference](#special-events-reference)
      8. [Labor Standards Reference](#labor-standards-reference)
      9. [Breaks/Lunches Reference](#breaks-lunches-reference)
      10. [Vacation Schemes Reference](#vacation-schemes-reference)
      11. [Integration Systems Reference](#integration-systems-reference)
      12. [Absence Reasons Reference](#absence-reasons-reference)
      13. [Time Zones Reference](#time-zones-reference)
      14. [Notification Scheme Reference](#notification-scheme-reference)
      15. [Preferences Reference](#preferences-reference)
      16. [Exchange Rules Settings Reference](#exchange-rules-reference)
      17. [Payroll Report Reference](#payroll-report-reference)
      18. [Channel Type Reference](#channel-type-reference)
   2. [Personnel Configuration](#personnel-configuration)
      1. [Employees](#employees)
      2. [Groups](#groups)
      3. [Services](#services)
      4. [Departments](#departments)
      5. [Mass Assignment of Business Rules and Vacation Schemes](#mass-assignment-business-rules)
      6. [Mass Assignment of Work Hours](#mass-assignment-work-hours)
      7. [Personnel Synchronization Reference](#personnel-synchronization-reference)
      8. [Operator Data Collection](#operator-data-collection)

4. [Load Forecasting in ARGUS WFM CC System](#load-forecasting)
5. [Load Viewing](#load-viewing)
6. [Multi-skill Planning Template](#multi-skill-planning-template)
7. [Work Schedule Planning](#work-schedule-planning)
8. [Timetable Planning](#timetable-planning)
9. [Vacancy Planning](#vacancy-planning)
10. [Exchange](#exchange)
11. [Employee Personal Cabinet](#employee-personal-cabinet)
12. [Business Processes (BPMS)](#business-processes)
13. [Reports](#reports)
14. [Monitoring](#monitoring)

---

## 1. Introduction {#introduction}

### 1.1 About the ARGUS WFM CC System {#about-system}

**Full Name:** Call Center Management System "ARGUS Workforce Management for Call Centre"  
**Short Name:** "ARGUS WFM CC" System

**System Purpose:**
The "ARGUS WFM CC" system allows improving call center work quality through:

- Building optimal balance between required staffing levels and expected work volume
- Planning employee work schedules based on work volume and qualifications
- Forecasting call center load and its even distribution among employees
- Strict schedule compliance

### 1.2 Goals of the ARGUS WFM CC System {#system-goals}

Thanks to the system's ability to forecast incoming call center load and plan optimal schedules based on it:

- **Improved call center resource efficiency:** During low load periods, operators don't idle on the line and can be engaged in alternative work, while during medium load periods, operator workload is distributed evenly
- **Improved customer service quality** through reduced queue waiting time; during peak loads, sufficient operators are available on the line
- **Improved call center management efficiency** - senior operators - through automation of schedule and work shift creation

### 1.3 Automation Object Characteristics {#automation-characteristics}

The automation objects include the following Customer services:

- **Senior operators** performing coordinating and administrative roles within operator groups
- **Call center operators** handling incoming calls

Senior operators in their activities manage personnel, operator work schedules - shifts, vacations, sick leaves, time off, regulate mass events - training, meetings within operator groups. They create operator work schedules during the day - call handling time, lunch, technological breaks.

Operators in their activities handle incoming calls to the call center. For this activity, they need to understand and know in advance when according to the schedule they should be at their workplace to handle calls, when they can take lunch breaks, technological breaks.

### 1.4 Roles in the ARGUS WFM CC System {#system-roles}

The system has the following system roles:

1. **Operator** - belongs to one or several operator groups, handles calls coming to these groups or waiting in their call queues. The operator should be able to view their work schedule for proper workday organization - time periods allocated for technological breaks, lunch breaks, planned regular events - training, meetings, and actual working hours when the operator should be at their workplace taking calls.

2. **Senior Operator** - along with regular operator functions, performs coordinating and administrative functions within the operator groups they belong to.

   Senior operator functions not automated by WFM:
   - Consulting operators during call handling
   - Monitoring operator calls

   Administrative functions automated by WFM:
   - Setting up operators in the system
   - Creating operator work schedules
   - Setting operator work schedules/shifts

3. **Administrator** - configures the system: maintaining work schedules, personnel structure, managing rights and user accounts, configuring and updating references

## 2. Getting Started {#getting-started}

### 2.1 System Login {#system-login}

To start working with the "ARGUS WFM CC" system:

1. Open a browser (Mozilla Firefox, Microsoft Edge, Google Chrome, Opera, etc.)
2. Enter the address provided by the system administrator in the browser address bar

After entering the address, a start page opens requesting login and password for system access (login and password are provided by the WFM CC system administration representative):

![Login Screen](img/login-screen.png)

3. When login and password are entered correctly, the main system page opens
4. If incorrect login or password is entered, an appropriate error message is displayed:

![Login Error](img/login-error.png)

### 2.2 General Interface Description {#interface-description}

After correct login and password entry, the system start page opens:

![Main Interface](img/main-interface.png)

Depending on access rights (Area 1), the following dashboards will be available to the user:

- **References:** Services, Groups, Employees, Work Schedule Templates, Roles, Business Rules
- **Forecasting Module**
- **Planning Module**
- **My Cabinet**
- **Reports**
- **Monitoring**
- **BPMS**

In the upper left part (Area 2) are located:
- Return to start page button
- Context menu button with list of sections (Figure 2.2.2) available to the user (depending on assigned access rights). Complete list of access rights is shown in figure 2.2.2:

![Context Menu](img/context-menu.png)

To close the sections list menu, click the close button.

In the upper right part (Area 3, Figure 2.2.1) are located:

**Employee search bar** by surname (search by partial or full match):

![Employee Search](img/employee-search.png)

To go to employee card, click on employee name with left mouse button.

- **"My Notifications" button** for notification availability
- **"My Profile" button**

![Profile Button](img/profile-button.png)

Clicking "My Profile" button navigates to user's "Personal Cabinet".

- **System information button:**

![System Info](img/system-info.png)

Selecting this will generate an error report:

![Error Report](img/error-report.png)

To save the generated error report, click "Save report".

To continue working in "ARGUS WFM CC", refresh the page (upon refresh, the page where the error occurred will open) or click the Argus logo (start page will open).

Selecting this will automatically start downloading the "ARGUS WFM CC" system user manual file.

**Language button** indicates the interface is displayed in Russian. To switch interface display to English, click it and select English.

**Exit button** - logout from "ARGUS WFM CC" system.

## 3. Administrator Workstation {#administrator-workstation}

### 3.1 Reference Configuration {#reference-configuration}

#### 3.1.1 Work Rules Reference {#work-rules-reference}

The reference is available for viewing to users with "View Work Rules Reference" access right (System_AccessWorkerRule).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Rules Reference" access right (System_EditWorkerRule).

**Important!** Work rules are created in the employee's local time zone. When creating a work rule from 10:00-18:00 for both employees in Moscow (UTC+3) and employees in Vladivostok (UTC+10), shifts for both employees will be planned from 10:00-18:00.

To access the reference, open the side menu and select "References" → "Work Rules" tab or open the reference from the system start page, "Work Rules Configuration" dashboard:

![Work Rules Reference](img/work-rules-reference.png)

By default, the system displays all active work rules (button pressed).

To view all work rules (active/deactivated) or only deactivated ones, click the corresponding button. To view only work rules with/without rotation/all rules, click and select the needed filter:

![Work Rules Filters](img/work-rules-filters.png)

If the rules list is large, you can use the search function by name for convenience. Start typing the work rule name in the search bar and the reference will display all rules with matches:

![Work Rules Search](img/work-rules-search.png)

##### 3.1.1.1 Work Rule Mode Differences

The reference allows creating work rules in two modes: with rotation and without rotation.

In "With rotation" mode, when creating a rule, you can specify the order in which work and rest days will alternate for the operator assigned this rule. The specified alternation of work and rest days will be strictly followed from week to week:

![With Rotation Mode](img/with-rotation-mode.png)

In "Without rotation" mode, when creating a rule, you can specify the number of rest days the operator should have per week:

![Without Rotation Mode](img/without-rotation-mode.png)

The system, based on continuous rest norm verification from the "Labor Standards" reference, will set the number and order of rest days per week that won't violate the continuous rest norm. Rest days may change from week to week.

Example for 24-hour continuous rest norm per week:
- Week 1 – RWRWRRR
- Week 2 – WRRRRWR  
- Week 3 – RRRWWRR

Example for 42-hour continuous rest norm per week:
- Week 1 – RRWWRRR
- Week 2 – WWRRRRR
- Week 3 – RWWRRRR

##### 3.1.1.2 Viewing Work Rules

In the work rules list, click on the rule of interest. The following information will be displayed to the right:

![Work Rule Details](img/work-rule-details.png)

- **"Work Rules"** - Shows rule name, mode, number of shifts, their start time and duration, and number of rotations (if "With rotation" mode is set). This section has an "Edit" button allowing rule modification after creation.

- **"Rule Assignment"** - Lists surnames of people assigned this rule. This section has an "Assign" button allowing rule assignment to operators after creation.

##### 3.1.1.3 Creating Work Rules

**With Rotation Mode**

To create a new work rule, click the "Create work rule" button:

![Create Work Rule](img/create-work-rule.png)

Select "With rotation" mode:

![Select Rotation Mode](img/select-rotation-mode.png)

The "Work Rule Configuration" window opens:

![Work Rule Configuration](img/work-rule-configuration.png)

In this window, specify:
- Any rule name
- Whether the rule should consider the production calendar. If checked, when planning schedules, shifts won't be placed on holidays even if work quota isn't covered. On pre-holiday days, shift duration from the rule will be reduced by one hour if strict duration is set. For flexible shift duration, this setting won't be considered.
- Whether to set mandatory shifts by day type. If checked, in the "Shifts" step you can set a mandatory shift that will be placed in the employee's schedule if rest day falls according to rotation.
- Time zone for rule creation
- Whether to set rotation by day type in the week. If checked, in the "Shift Rotations" step, for each weekday you can set a specific work day that will be considered if a non-rest day falls according to rotation.

Click "Forward" to proceed to "Shifts" configuration.

In this window, specify shift start time (mandatory) and shift duration (mandatory):

![Shift Configuration](img/shift-configuration.png)

For shift start and duration, specify fixed or flexible period. If shift should start strictly at 09:00, specify period 09:00 – 09:00 in the start field. If start can be flexible day to day, specify range, e.g., 08:00 – 10:00. The system will automatically select start time from the given range for each work day. Same applies for duration.

To add additional shift, click the + button next to "Work Day 1".
To remove one of created shifts, click the - button next to "Work Day N".

For shift to always start at the same time, specify equal left and right boundaries for start time (Example: 12:00-12:00).
For shift to always have the same duration, specify equal left and right boundaries for shift duration (Example: 09:00-09:00).

**Important!** Start and duration step depends on the step setting configured in the system database during deployment. If 30-minute step is set, you cannot specify start time like 09:00-09:20 or duration 11:00-11:20.

To add split shift (when operator should work several hours at the beginning of the day and several hours at the end), click + next to "Shift №1".
To remove split shifts, click - next to "Shift №N".

![Split Shift Configuration](img/split-shift-configuration.png)

Click "Forward" to proceed to "Shift Rotations" configuration or "Back" for previous "General Information" step. In "Shift Rotations" window, specify work/rest day alternation and add shift rotations if necessary:

![Shift Rotations](img/shift-rotations.png)

To change work/rest day and/or shift alternation (if there's more than one), double-click left mouse button on selected day:

![Edit Rotation](img/edit-rotation.png)

**Important!** By default, all rotations start with work day. This condition reduces the number of necessary rotations.

Click "Forward" to proceed to "Shift Distances" configuration or "Back" for previous "Shifts" step. In "Shift Distances" window, set minimum distance between shifts (how many hours later the next shift can start after the previous one ends) and maximum consecutive hours sum (sum of hours without unpaid breaks/lunches between continuous rest standards).

Shift distance configuration is only available if flexible duration by start and/or shift duration was set in the "Shifts" step.

![Shift Distances](img/shift-distances.png)

Work rule assignment will be described later in section 3.1.1.4 Work Rule Assignment.

**Without Rotation Mode**

To create a new work rule, click "Create work rule" and select "Without rotation" mode:

![Without Rotation Setup](img/without-rotation-setup.png)

In the "Work Schedule Configuration" dialog on the "General Information" tab, specify the rule name:

![General Info Setup](img/general-info-setup.png)

Specify whether the rule should consider production calendar. If checked, when planning schedules, shifts won't be placed on holidays even if work quota isn't covered. On pre-holiday days, shift duration from the rule will be reduced by one hour if strict duration is set. For flexible shift duration, this setting won't be considered.

Specify time zone for rule creation.

Click "Forward" to proceed to "Shifts" configuration.

In this window, specify shift start time (mandatory) and shift duration (mandatory):

![Shifts Without Rotation](img/shifts-without-rotation.png)

To add additional shift, click + next to "Work Day 1".
To remove created shifts, click - next to "Work Day N".

For shift to always start at same time, specify equal left and right boundaries for start time (Example: 12:00-12:00).
For shift to always have same duration, specify equal left and right boundaries for shift duration (Example: 08:00-08:00).

**Important!** Start and duration step depends on the step setting configured in system database during deployment. If 30-minute step is set, you cannot specify start like 09:00-09:20 or duration 11:00-11:20.

To add split shift (when operator should work several hours at beginning and end of day), click + next to "Shift №1".
To remove split shifts, click - next to "Shift №N".

![Split Shifts Setup](img/split-shifts-setup.png)

Click "Forward" to proceed to "Rest Days" configuration or "Back" for previous "General Information" step.

On "Rest Days" tab, information about continuous rest norm specified in "Labor Standards" reference is pulled. Specify number of rest days:

![Rest Days Configuration](img/rest-days-configuration.png)

**Important!** "Number of rest days" item is checked non-strictly by the system during schedule formation. Strict check is "Continuous rest norm". This means the system cannot put fewer rest days per week than specified in continuous rest norm, but "Number of rest days" item will be followed after all other checks are completed - Work period quota and Load coverage.

Click "Forward" to proceed to "Shift Distances" configuration or "Back" for previous "Rest Days" step. In "Shift Distances" window, set minimum distance between shifts (how many hours later next shift can start after previous one ends) and maximum consecutive hours sum (sum of hours without unpaid breaks/lunches between continuous rest standards).

Shift distance configuration is only available if flexible duration by start and/or shift duration was set in "Shifts" step.

![Shift Distances Without Rotation](img/shift-distances-without-rotation.png)

Work rule assignment will be described later in section 3.1.1.4 Work Rule Assignment.

##### 3.1.1.4 Work Rule Assignment

Work rule assignment is done for a period:

![Rule Assignment Period](img/rule-assignment-period.png)

This means only one work rule can be assigned to one employee for the same time interval.

Operators in the list can be sorted by departments. To search for specific operator, start typing their surname in the "Full Name" field.

To assign rule to specific operator, select this operator by checking the left checkbox:

![Select Individual Operator](img/select-individual-operator.png)

To assign schedule to all operators, select the topmost checkbox to the left of "Personnel Number" column:

![Select All Operators](img/select-all-operators.png)

If selected operators already have assigned rule for selected period, system will show warning:

![Assignment Warning](img/assignment-warning.png)

For assignments to take effect, click "Save".

##### 3.1.1.5 Editing Work Rules

To edit work rule, select it in the list and click "Edit" button in the right part:

![Edit Work Rule](img/edit-work-rule.png)

The system creates a copy of the work rule that can be edited and assigned to employees. By default, the system completely copies all settings to the new rule:

![Work Rule Copy](img/work-rule-copy.png)

Work rule editing functionality is similar to work rule creation functionality. For more details on working in "Work Rule Configuration" window, see section 3.1.1.3.

##### 3.1.1.6 Deleting, Deactivating, Activating Work Rules

To delete previously created work rule, select it in the list and click "Delete work rule" button:

![Delete Work Rule](img/delete-work-rule.png)

**Important!** If the selected work rule for deletion was assigned to employees, the system won't allow deletion since it references other system records. Such rule can only be deactivated.

![Cannot Delete Rule](img/cannot-delete-rule.png)

To deactivate previously created work rule, select it in the list and click "Deactivate work rule" button:

![Deactivate Work Rule](img/deactivate-work-rule.png)

To restore (activate) previously deactivated work rule, set "Inactive" filter, select it in the list and click "Activate work rule" button:

![Activate Work Rule](img/activate-work-rule.png)

#### 3.1.2 Events Reference {#events-reference}

The reference is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit Events Reference" access right (System_EditEventTemplate).

![Events Reference](img/events-reference.png)

To open the reference, go to "References" → "Events" tab.

The "Events" reference is designed for creating intraday call center events.

On the "Internal Activities" tab, "Training" and "Meeting" type events are created.
On the "Projects" tab, outgoing activities are created.

When opening the reference, you'll see:

![Events Reference Interface](img/events-reference-interface.png)

Event filters – "All", "Active", "Inactive". Depending on selected filter, corresponding events will be displayed in the system.

Event types – "Internal Activities", "Projects". List of created events (if any) with information about them.

##### 3.1.2.1 Creating Internal Activities

To create an event, click the create button. In the opened "Event Configuration" dialog, fill the following parameters:

![Event Configuration](img/event-configuration.png)

- **Type** - select event type from dropdown:

![Event Type Selection](img/event-type-selection.png)

- **Name, Description** – specify event name and brief description
- **Regularity** – select frequency of the event from list:

![Event Regularity](img/event-regularity.png)

###### 3.1.2.1.1 Events with "Once a day", "Once a week", "Once a month" regularity

For events with "Once a day", "Once a week", "Once a month" regularity, specify:

- **Weekdays** (all weekdays selected by default): to select specific weekdays when event will be conducted. Uncheck days when event won't be conducted in the dropdown:

![Weekday Selection](img/weekday-selection.png)

- **Time interval**: specify time period when it's appropriate to conduct the event. For example, 12:00 – 16:00
- **Time zone**: specify time zone applied to this event. Without time zone selection, time will be saved as local – independent of time zone

For example, meetings should occur twice a week, professional development courses – once a month, English training – once a week. Accordingly, when "ARGUS WFM CC" system suggests registering events in schedule, it will analyze whether sufficient time has passed since the previous event for each individual participant (operator).

- **Event duration, min**: specify event duration in minutes

When "ARGUS WFM CC" system suggests registering events in schedule, it will look for free intervals for operators, analyze their length, and if operator's free interval length equals or exceeds event duration, system can suggest such interval.

- **Sign**: for individual event click individual, for group event click group
- **Number of participants**: this parameter appears when clicking group in "Sign" area. Specify minimum and maximum number of participants who can attend the event

![Participant Number](img/participant-number.png)

- **Groups**: if employees from specific group should participate in event, select it from dropdown (by checking):

![Group Selection](img/group-selection.png)

- **Employees**: if only specific employees should participate in event, start typing employee surname and system will display matches. Click on employee with left mouse button to select:

![Employee Selection](img/employee-selection.png)

To add another employee, repeat the operation:

![Add Employee](img/add-employee.png)

To remove employee, click the X button.

**Important!** Employee search also depends on "Groups" parameter. If specific group was selected, system searches employees only within that group.

**Combine with other events during the day**: if this checkbox is checked, system can combine different types of events for one operator during the day.

![Combine Events](img/combine-events.png)

###### 3.1.2.1.2 Events with "Specify event day" regularity

For events with "Specify event day" regularity, fill:

- **Event day**: specify specific day when event should take place. For example, 22.02.2023:

![Event Day](img/event-day.png)

- **Start time**: specify specific time when event should start in HH:MM format. For example, 13:00:

![Start Time](img/start-time.png)

- **Time zone, Event duration, Groups, Employees, Combine with other events during the day**: filled similarly to "Once a day", "Once a week", "Once a month" regularity

After filling all necessary parameters, click save to save the event:

![Save Event](img/save-event.png)

Saved event will be displayed in the reference:

![Saved Event Display](img/saved-event-display.png)

To edit event, click edit button. "Event Configuration" window opens, then change parameters described above and save changes.

To delete event from reference, click delete button.

**Note:** When "ARGUS WFM CC" system suggests registering event in schedule, for "group" event:

- System will look for common free intervals for all group employees (or groups) if "Employees" parameter is not filled and "Groups" parameter specifies one or several groups
- System will look for common free intervals for specific employees if "Employees" parameter is filled
- Additionally, system analyzes "Number of participants" parameter (minimum number). When searching for common free intervals, system analyzes minimum number of participants specified in event settings and looks for common free intervals available to at least as many employees as specified in event settings

##### 3.1.2.2 Creating Outgoing Projects

To create "Project", go to corresponding tab in "Events" reference and click create:

![Create Project](img/create-project.png)

In the opened "Event Configuration" dialog, fill the following parameters:

![Project Configuration](img/project-configuration.png)

- **Type**: select event type
- **Name, Description**: specify event name and brief description
- **Mode**: mode determines priority when planning event; what's more important – incoming load or outgoing project

When assigning projects, HHL (highest load hours) intervals are determined. HHL determination method is similar to peak determination method in "Peak Analysis" in forecasting module with small differences in coefficients. HHL are intervals (both external and internal) that exceed upper boundary.

"Incoming load priority over outgoing project" – project won't be placed in HHL.
"Outgoing project priority over incoming load" – project can be placed in HHL.

- **Priority**: determines priority over other projects. Higher number means higher priority over other projects
- **Weekdays** (all weekdays selected by default): to select specific weekdays when event will be conducted. Uncheck days when event won't be conducted in dropdown:

![Project Weekdays](img/project-weekdays.png)

- **Time interval**: specify time period when it's appropriate to conduct event. For example, 12:00 – 16:00
- **Event duration, min**: specify event duration in minutes
- **Planned term**: specify dates when event will be planned in schedule
- **AHT**: specify expected call handling time
- **OSS**: specify operator utilization
- **Work plan calls/surveys**: specify number of calls that need to be processed within the project
- **Group**: select groups from which operators will be chosen for project
- **Employees**: select specific employees who will work on project. Must be selected unlike "Internal Activities"

After filling all necessary parameters, click save to save the event.

#### 3.1.3 Production Calendar Reference {#production-calendar-reference}

The reference is available for viewing to users with "Administrator" system role or any other role with "View Production Calendar page" access right (System_AccessCalendar).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Production Calendar page" access right (System_EditCalendar).

This reference maintains calendar with work, rest, pre-holiday and holiday days for considering day types when planning vacations. If employee vacation falls on holiday, system will automatically extend vacation considering production calendar.

![Production Calendar](img/production-calendar.png)

To access the reference, open side menu and select "References" → "Production Calendar" tab.

To start working, you need to load production calendar in XML format.

Ready-to-import Russian Federation calendar files can be obtained from the resource by link.

When opening the reference, production calendar for current year opens by default, where each year day is colored according to legend:

![Calendar Legend](img/calendar-legend.png)

If necessary, you can hide production calendar display in work schedule by unchecking the corresponding checkbox.

##### 3.1.3.1 Importing Production Calendar

To load production calendar, click import button. In opened "Production Calendar Import" window, select weekdays that will be considered rest days by default, then click file selection button and import.

Loaded production calendar looks as follows:

![Loaded Calendar](img/loaded-calendar.png)

##### 3.1.3.2 Editing Production Calendar

To edit loaded production calendar, select day of interest and choose type to change to in right menu:

![Edit Calendar](img/edit-calendar.png)

After selecting type, day will be colored according to legend:

![Calendar Color Change](img/calendar-color-change.png)

When changing type to "Holiday", system will additionally request specifying which event the holiday is dedicated to:

![Holiday Event](img/holiday-event.png)

To save changes, click save button, to cancel changes – cancel button.

#### 3.1.4 Roles Reference {#roles-reference}

The reference is available for viewing to users with "View Roles Reference" access right (System_AccessRoleList).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Roles Reference" access right (System_EditRole).

This reference regulates access rights to system functions. Roles are set with access rights assigned for viewing and editing specific system functions. Later, created or existing roles will be assigned to users.

To access the reference, open side menu and select "References" → "Roles" tab, or go from sections list menu or from main page by clicking "Role Configuration" block:

![Roles Reference Access](img/roles-reference-access.png)

![Roles Reference Interface](img/roles-reference-interface.png)

By default, system displays all active roles (button pressed). To view all roles (active/deactivated) or only deactivated ones, click corresponding button.

If roles list is large, start typing role name in search bar for convenience, system will display matching roles:

![Roles Search](img/roles-search.png)

The reference contains 3 system roles: Administrator, Senior Operator, Operator. These roles are non-editable, each has its own set of access rights:

![System Roles](img/system-roles.png)

##### 3.1.4.1 Creating Role

To create new business role, click "Create new role" button:

![Create Role](img/create-role.png)

"Name", "Description" fields appear in right part. Below these fields, access rights that need to be assigned to the created role are displayed.

![Role Configuration](img/role-configuration.png)

To create role, fill mandatory "Name" field. For convenience, you can add role description and check "Default role" checkbox if you want created role to be automatically assigned to all employees created in system:

![Role Settings](img/role-settings.png)

Then click "Save" button.

After this, new role appears in business roles list on left:

![New Role Display](img/new-role-display.png)

Now you need to assign access rights to created role. Select role in list and in right part, check needed access rights by checking checkbox:

![Assign Access Rights](img/assign-access-rights.png)

##### 3.1.4.2 Editing Role

To edit created role, select it in list and change name/description in right part. To save changes, click save button.

List of assigned access rights is edited by checking/unchecking checkbox:

![Edit Role Rights](img/edit-role-rights.png)

##### 3.1.4.3 Deleting Role

To delete previously created role, select it in list and click "Delete role" button:

![Delete Role](img/delete-role.png)

##### 3.1.4.4 Deactivating Role

To deactivate role, select it in list and click "Deactivate role" button:

![Deactivate Role](img/deactivate-role.png)

##### 3.1.4.5 Restoring Role

To restore/activate previously deactivated role, select it in list and click "Activate role" button:

![Restore Role](img/restore-role.png)

#### 3.1.5 Positions Reference {#positions-reference}

The reference is available for viewing to users with "View Positions Reference" access right (System_AccessPositionList).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Positions Reference" access right (System_EditPosition).

This reference is needed for configuring positions for which work schedule planning will be performed.

To access the reference, open side menu and select "References" → "Positions" tab:

![Positions Reference](img/positions-reference.png)

The reference contains list of employee positions present in the system.

![Positions List](img/positions-list.png)

Position reference population occurs automatically through integration with 1C system (with appropriate configuration).

**Important!** If synchronization with 1C system is absent, position list is added through system database by ARGUS NTC specialists.

Upon receiving position through integration, it's assigned name corresponding to employee positions name in 1C system and external identifier "External System Key".

For correct system operation and correct work schedule planning, responsible employee needs to set "Planning Participation" attribute for each position in "Positions" reference. By default, all positions received from 1C system participate in work schedule and timetable planning.

To change "Planning Participation" attribute, left-click on area containing general position information ("Name", "External System Key", "Planning Participation") and uncheck "Planning Participation" attribute:

![Edit Position Planning](img/edit-position-planning.png)

#### 3.1.6 Work Time Efficiency Configuration Reference {#work-time-efficiency-reference}

The reference is available for viewing to users with "View Work Time Efficiency Configuration Reference" access right (System_AccessOperatorState).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Time Efficiency Configuration Reference" access right (System_EditOperatorState).

In this reference, it's determined which work statuses coming through integration with contact center will have parameters like "productive time", "net load", etc.

Statuses received from contact center and their assigned parameters will be needed by system for calculations in reports (both in report editor and outside it) and when working with monitoring.

Open reference through side menu:

![Work Time Efficiency Reference](img/work-time-efficiency-reference.png)

To configure reference, you need to fill "Historical Reports", "Operational Control" and "Payroll Report" tabs to set correspondence between statuses operators can be in with events in System, and configure report calculations based on operator's actual work time.

"Historical Reports" tab contains statuses that will be used in reports.

- **Status**: status name (more technical) coming from contact center. For example, "READY" shows operator is ready to take call
- **Name**: status name understandable to user. Can have same value as "status"
- **Description**: status description
- **Productive time**: status when operator is at workplace and ready to work
- **Net load**: status when operator takes incoming contact
- **Talk time**: status denoting operator talk status. Post-processing, for example, can also be marked as "Talk time"
- **Break**: operator rest status. Can be lunch, break, etc.
- **Actual timesheet time**: if status is marked with this checkbox, it will be considered when calculating actual time in control tool
- **Productive work time**: if status is marked with this checkbox, it will be considered when calculating productivity in "Bonus Report". If "Productivity" standard value is specified in "Bonus Indicators", statuses marked with this checkbox will be used
- **Post-call processing**: if status is marked with this checkbox, it will be considered when calculating useful time, which will be used in "KPI" report and "Workplace Report 2"

![Historical Reports Configuration](img/historical-reports-configuration.png)

On "Operational Control" tab, statuses are displayed for which you need to set one of correspondences for monitoring: "Online", "Online – not processing calls", "Absent".

This setting allows configuring status correspondence for displaying operator schedule compliance and violations in "Monitoring" - "Operator Statuses" block.

Status correspondence is set using dropdown. To set correspondence for status, click dropdown next to status (initially empty) and select needed one.

- **Online** – operator is online and taking contacts
- **Online – not processing calls** – operator is online but not processing contacts  
- **Absent** – operator is not online now but is at work

All changes in this reference are saved automatically.

![Operational Control Configuration](img/operational-control-configuration.png)

On "Payroll Report" tab, specify whether to consider or not consider status when calculating actual time in "Payroll Report".

![Payroll Report Configuration](img/payroll-report-configuration.png)

#### 3.1.7 Special Events Reference {#special-events-reference}

The reference is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Special Events Reference" access right (System_AccessForecastSpecialEvent).

The reference is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit Special Events Reference" access right (System_EditForecastSpecialEvent).

"Special Events" reference is designed for entering events that cannot be forecasted – city-specific holidays, mass events, etc. On such days, load sharply increases or conversely drops. If normal staffing is deployed as for "regular" days, in first case there will be operator shortage and SLA will subsequently drop, in second case there will be many extra operators sitting idle.

During special event action, forecasted load for affected groups will be multiplied by set coefficient.

To access the reference, open side menu and select "References" → "Special Events Reference" tab:

![Special Events Reference](img/special-events-reference.png)

![Special Events Interface](img/special-events-interface.png)

##### 3.1.7.1 Creating Special Event

To create special event, click "Add" button. In opened "Special Event Configuration" dialog, fill following parameters:

![Special Event Configuration](img/special-event-configuration.png)

- **Active**: specify special event action period with minute precision and time zone
- **Name, Description**: specify special event name and brief description
- **Service, Group**: select service from dropdown, then groups included in selected service
- **Coefficient**: specify coefficient by which load (number of contacts) obtained during forecasting should be multiplied. Value 1 and above – increases number of calls. Value 0 to 1 – decreases number of calls (e.g., coefficient 0.5 decreases number of calls by half)

When creating special event, you can specify several action periods for correcting coefficient (added by clicking "+"). If periods overlap with other events' action periods, System considers all of them.

For example, 3 special events with coefficients 1.25, 1.35 and 2.15 affect forecasted interval. Then for this interval, load will be increased 2.75 times:
- 1.25 – 1 = 0.25
- 1.35 – 1 = 0.35  
- 2.15 – 1 = 1.15
- 1 + 0.25 + 0.35 + 1.15 = 2.75

![Multiple Coefficients](img/multiple-coefficients.png)

After filling all parameters, click save button to save event. Saved event will be displayed in reference:

![Saved Special Event](img/saved-special-event.png)

The following example shows how this setting affects obtained load change using special event in figure above.

Load obtained before special event appearance in reference:

![Load Before Event](img/load-before-event.png)

After adding special event to reference and re-obtaining forecasts, you can notice how number of recalculated contacts changed in next figure – on next tab, number of operators in this period will also be increased:

![Load After Event](img/load-after-event.png)

##### 3.1.7.2 Editing Special Event

To edit special event, click edit button. "Special Event Configuration" window opens. Change parameters described in previous section and save changes.

**Important**: For edited event to apply, forecast must be updated.

##### 3.1.7.3 Deleting Special Event

To delete special event from reference, click delete button.

**Important**: System will only allow deleting special event that was never considered when obtaining forecast.

**Note 1:** System allows creating identical special events in reference. In this case, when obtaining forecasts, coefficient of special event created later is applied.

**Note 2:** System allows creating overlapping events. With such overlapping events in forecasted intervals:
- In non-overlapping segments, load is multiplied by corresponding coefficients
- In overlapping segment – load is multiplied by coefficient of special event created last

#### 3.1.8 Labor Standards Reference {#labor-standards-reference}

The reference is available for viewing to users with "View Labor Standards Reference" access right (System_AccessWorkNorm).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Labor Standards Reference" access right (System_EditWorkNorm).

This reference configures labor standard parameters considered or not considered when creating work schedule templates and planning work schedules.

To access the reference, open side menu and select "References" → "Labor Standards" tab:

![Labor Standards Reference](img/labor-standards-reference.png)

After accessing the reference, following window is displayed:

![Labor Standards Interface](img/labor-standards-interface.png)

![Labor Standards Details](img/labor-standards-details.png)

**Rest norm** determines number of continuous rest hours for operator per calendar week. For example, if you set 48-hour norm, it means operator must rest two consecutive days. This setting also affects ability to add additional shift to operator in planned work schedule.

When planning and editing schedule, system can behave differently depending on settings. Select most suitable option from proposed:

- **Ignore**: system will plan employee schedules according to their work rules and load, but weekly rest norm may not be observed. During manual corrections, system will allow setting any shift regardless of specified rest norm
- **Consider**: system will plan work schedules with strict rest norm consideration. When attempting manual corrections violating weekly rest norm, user will receive notification about inability to perform this action
- **Warn**: system will plan work schedules with strict rest norm consideration. When attempting manual corrections violating weekly rest norm, user will receive warning that changes violate weekly rest norm
- **Use only during planning**: rest norm will be considered only during work schedule planning. During manual corrections, system will allow setting any shift regardless of specified rest norm – warning won't appear

![Rest Norm Configuration](img/rest-norm-configuration.png)

**Weekly norm** is used to check possibility of adding additional shifts to operator when correcting planned work schedule. When attempting to add additional shift to operator during work schedule planning, system will rely on reference settings and "Weekly hours norm" value in operator card.

When planning and editing schedule, system can behave differently depending on settings. Select most suitable option from proposed:

- **Ignore**: reference setting is ignored, can add shift to employee regardless of their norm
- **Consider**: if additional shift cannot be added to employee due to weekly hours norm excess, user will receive warning and shift won't be assigned
- **Warn**: if additional shift cannot be added to employee due to weekly hours norm excess, user will receive warning and choice: add shift or refuse
- **Consider during planning**: weekly norm will be considered only during work schedule planning, during manual shift addition norm won't be considered (similar to "Ignore" checkbox)

![Weekly Norm Configuration](img/weekly-norm-configuration.png)

**Night time** is used to determine hours considered night time (according to Labor Code from 22:00 – 06:00) and parameters that will determine system behavior when assigning work schedule templates and planning work schedules. These hours work together with individual employee card settings. If employee doesn't have "Night work" parameter set, system will monitor that employee isn't assigned shift overlapping night time specified in reference.

Also specify % night work supplement that will be considered when calculating schedule cost.

Select most suitable option from proposed:

- **Ignore**: night hours not considered
- **Consider**: used when attempting to assign work schedule template to employee individually who doesn't have "Night work" checkbox set, warning appears and schedule isn't assigned. When attempting mass work schedule template assignment, employees without "Night work" checkbox will be grayed out and cannot be selected for template assignment
- **Warn**: during individual work schedule template assignment to employee without "Night work" checkbox, user will see warning about individual settings violation and be offered choice: assign template anyway or not. During mass assignment, behavior is same
- **Use only during planning**: night time will be considered only during work schedule planning, during manual shift addition night time won't be considered, similar to "Ignore" checkbox

![Night Time Configuration](img/night-time-configuration.png)

**Daily norm** determines operator shift duration. System checks shift duration in work schedule template and shift duration set in operator card – operator will get minimum duration from these two values.

Select most suitable system behavior with reference settings:

- **Ignore**: reference settings and individual daily hours value set in operator card not considered
- **Consider**: during work schedule planning, operators will get minimum shift duration value (either reference or individual). During manual shift duration correction, operator's individual duration is also considered. If new shift duration exceeds norm during correction, user will receive warning and duration won't change
- **Warn**: considered during manual shift duration correction. If shift duration exceeds norm, user will receive warning and choice: change duration anyway or refuse
- **Use only during planning**: similar to "Consider" option but without conditions for manual correction

![Daily Norm Configuration](img/daily-norm-configuration.png)

**Accumulated vacation days**. Reference determines whether accumulated vacation days will be considered when manually adding vacation in vacation schedule planning, operator card and formed work schedule.

- **Ignore**: when attempting to add vacation to operator, remaining vacation days number not considered
- **Consider**: when manually adding vacation to operator, remaining vacation days number will be considered. If vacation days insufficient, system will show warning and not assign vacation
- **Warn**: if operator doesn't have enough vacation days, warning will be issued when adding with choice: assign vacation or not

![Vacation Days Configuration](img/vacation-days-configuration.png)

![Vacation Days Settings](img/vacation-days-settings.png)

**Time interval for obtaining accumulated vacation days and method of obtaining these days**

This setting sets time period for which system will take accumulated vacation days from 1C during personnel structure update, and you need to select work hours obtaining option: from 1C or enter work hours manually (either massively or in operator card).

![Vacation Days Interval](img/vacation-days-interval.png)

**Shift exchange periods**. This setting helps avoid payroll calculation period problems for employees.

In this block, you can highlight month date boundaries within which shift exchange/work coverage between employees is possible. Add several periods within month by clicking + and specify date range boundaries within which employees can exchange shifts. When creating shift exchange request, limitation check set in current block will be performed.

Example: shifts can be exchanged from 1st to 14th and from 15th to 31st. In this case, if employee wants to exchange January 10th shift, they must work until January 14th inclusive.

![Exchange Periods](img/exchange-periods.png)

**Allowable overtime hours amount**

This setting helps prevent excessive employee overtime. Specify maximum overtime hours operator can work per week and year. If when setting additional shift in schedule, employee's total overtime hours per week/year exceeds norm specified in reference, system will show warning (if "Warn" is set) or prohibit additional shift setting (if "Consider" is set).

#### 3.1.9 Breaks/Lunches Reference {#breaks-lunches-reference}

The reference is available for viewing to users with "View Labor Standards Reference" access right (System_AccessWorkNorm).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Labor Standards Reference" access right (System_EditWorkNorm).

In reference, you can set number and duration of lunches/breaks for shift of specific type and duration. Reference information is used for operator schedule planning.

To access reference, open side menu and select "References → Breaks/lunches" tab.

![Breaks Lunches Reference](img/breaks-lunches-reference.png)

When opening reference, following window is displayed:

![Breaks Lunches Interface](img/breaks-lunches-interface.png)

In left "Shifts" block, set shift duration and type. To create new shift, click + and fill following parameters:

![Create Shift](img/create-shift.png)

Shift duration is specified in hour intervals.

For example, for schedules 8:00-20:00, 9:00-21:00 and 10:00-22:00, shift duration will be 12 hours, for schedules 8:00-16:00, 9:00-17:00, 10:00-18:00 – 8 hours. To include full interval, specify duration in "11:59-12:01" format.

![Shift Duration](img/shift-duration.png)

**Shift type**

Specify one of three shift types – day, night and mixed. Shift type depends on night time hours set in "Labor Standards" reference (according to Labor Code from 22:00 – 06:00). Shift type determines ability to set day and night lunches/breaks. For mixed shift, you need to set night duration and day duration – total hours falling on night and day time (see example in figure).

**Note:** For night shift, you can set maximum duration not exceeding total night hours duration set in "Labor Standards": if it's from 22:00 to 6:00, night shift duration cannot be more than 8 hours.

![Shift Type Configuration](img/shift-type-configuration.png)

**Lunch/break order**

Set one of two modes: "Consider lunch/break order" and "Don't consider lunch/break order". Selected mode determines whether system can automatically arrange set lunches/breaks under load in schedule or will follow strict lunch/break order.

**Maximum/minimum time without break**

In maximum and minimum time without break columns, specify time within which employee can be without break. Time without break should be multiple of set system interval.

![Break Time Configuration](img/break-time-configuration.png)

To save all set shift parameters, click save button. To edit reference record, click edit button – interface identical to creation interface. To delete record, click delete button.

In right "Business Rules" block, business rules for lunches/breaks are set for each created shift.

To create new business rule for shift, click + and fill following parameters:

![Business Rule Configuration](img/business-rule-configuration.png)

**Note:** "Lunch start interval (from shift beginning)" parameter will only appear if "Don't consider lunch/break order" mode was selected for shift and break type will be "Lunch break". In "Lunch start interval" field, period from shift beginning when system can plan lunch break for employees is specified.

![Lunch Start Interval](img/lunch-start-interval.png)

**Type**

Set one of two types: lunch or technological break.

**Duration (min)** can only be multiple of initially set system intervals.

**Paid**: checkbox allows considering break in timesheet. For example, if 12-hour shift has 4 breaks: 2 unpaid 30-minute lunches and 2 paid 15-minute technological breaks, then 11 full hours will go to timesheet (for payment).

To save all set break parameters, click save button. To edit reference record, click edit button (interface identical to creation interface); to delete record, click delete button.

#### 3.1.10 Vacation Schemes Reference {#vacation-schemes-reference}

The reference is available for viewing to users with "View Vacation Schemes Reference" access right (System_AccessVacationScheme).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Vacation Schemes Reference" access right (System_EditVacationScheme).

This reference configures vacation schemes that determine duration and number of vacations.

Later (during work schedule and timetable planning), these schemes are used for assigning vacations to operators.

Vacation scheme can be assigned to specific operator in their card or massively.

To access reference, open side menu and select "References" → "Vacation Schemes" tab:

![Vacation Schemes Reference](img/vacation-schemes-reference.png)

##### 3.1.10.1 Viewing Reference

When opening reference, following window is displayed:

![Vacation Schemes Interface](img/vacation-schemes-interface.png)

**Name**: vacation scheme name.

**1st, 2nd,…, nth Vacation**: number of days in specific vacation (see figure, first vacation has 7 rest days, second has 14).

On this page, you can create new reference record or edit existing one.

##### 3.1.10.2 Creating New Vacation Scheme

To create new vacation scheme, click create button in "Vacation Schemes" reference.

![Create Vacation Scheme](img/create-vacation-scheme.png)

In opened window, enter name and number of vacation days. Number of vacations can be adjusted by clicking + to add or – to remove.

![Vacation Scheme Details](img/vacation-scheme-details.png)

**Note 1**: vacation period alternation doesn't matter. For example, schemes 7-14-7, 7-7-14 and 14-7-7 are equivalent.

To save all set parameters, click save button.

##### 3.1.10.3 Editing Vacation Scheme

To delete vacation scheme, click delete button in "Vacation Schemes" reference and confirm or cancel action by selecting corresponding button.

![Delete Vacation Scheme](img/delete-vacation-scheme.png)

To change number of vacation days or scheme name, click edit button, make necessary corrections and confirm or cancel them.

![Edit Vacation Scheme](img/edit-vacation-scheme.png)

#### 3.1.11 Integration Systems Reference {#integration-systems-reference}

The reference is available for viewing to users with "View Integration Systems Reference" access right (System_IntegrationSystemView).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Integration Systems Reference" access right (System_IntegrationSystemEdit).

This reference configures parameters for interaction with integration systems participating in specific processes in WFM CC: obtaining historical data, personnel structure, etc.

To access reference, open side menu and select "References" → "Integration Systems" tab:

![Integration Systems Reference](img/integration-systems-reference.png)

In opened window, fill following parameters:

![Integration Systems Configuration](img/integration-systems-configuration.png)

**System**: integration system name.

**Personnel structure access point**: WSDL containing personnel structure obtaining methods structure from integration system.

**Shift sending access point**: WSDL containing shift transmission methods structure to integration system.

**Call center historical data access point**: WSDL containing historical data obtaining methods structure needed for load forecasting from integration system.

**Operator historical data access point**: WSDL containing operator historical data obtaining methods structure. For example, for calculating operator's actual work output from integration system.

**Operator chat work access point**: WSDL containing methods structure for obtaining number of processed chats, time, etc.

**Monitoring data access point**: WSDL containing methods structure for obtaining real-time load for monitoring operation.

**System identifier**: external system identifier; needed for correct integration system identification.

**SSO**: checkbox marking connection between operator account authorization in Windows and operator account in WFM CC.

**Is master system**: checkbox marking whether this integration system is main; used during personnel synchronization. If system is main, WFM will only link its account but cannot edit employee data.

**Delete button**: deletes integration system record.

To edit record field, left-click on needed field:

![Edit Integration System](img/edit-integration-system.png)

To create new integration system record, click create button:

![Create Integration System](img/create-integration-system.png)

In "Add new integration system" window, fill all required integration system data and click "Confirm" button.

![Integration System Details](img/integration-system-details.png)

#### 3.1.12 Absence Reasons Reference {#absence-reasons-reference}

The reference is available for viewing to users with "View Absence Reasons Reference" access right (System_AccessAbsenceReasons).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Absence Reasons Reference" access right (System_EditAbsenceReasons).

This reference specifies all possible reasons for operator absence from line. Later used for creating special event in operator card.

To access reference, open side menu and select "References → Absence Reasons" tab.

![Absence Reasons Reference](img/absence-reasons-reference.png)

Reference has filtering by active/inactive/all records:

![Absence Reasons Filter](img/absence-reasons-filter.png)

To create absence reason, click create button. In opened window, fill following parameters:

![Create Absence Reason](img/create-absence-reason.png)

Check "Consider in %absenteeism report" checkbox for absence reasons that will be subtracted from planned employee number when generating "%absenteeism Report".

To edit absence reason, click edit button or delete button to remove.

#### 3.1.13 Time Zones Reference {#time-zones-reference}

The reference is available for viewing to users with "View Time Zones Reference" access right (System_AccessTimeZone).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Time Zones Reference" access right (System_EditTimeZone).

Reference allows setting time zones that affect time display in system. Values set in this reference can be seen in other sections in "Time Zones" field.

To access reference, open side menu and select "References" → "Time Zones" tab:

![Time Zones Reference](img/time-zones-reference.png)

Reference consists of following parameters:

![Time Zones Configuration](img/time-zones-configuration.png)

- **Time zone**: select time zone from dropdown
- **Interface display**: set name that will be displayed in all forms where time zones are used

To add new record, click create button.

![Create Time Zone](img/create-time-zone.png)

To save, click save button or cancel button to cancel.

To edit time zone interface display, click edit button. Change parameters and click apply button or cancel button to cancel.

To delete time zone from reference, click delete button.

#### 3.1.14 Notification Scheme Reference {#notification-scheme-reference}

The reference is available for viewing to users with "View Absence Reasons Reference" access right (System_AccessAbsenceReasons).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Absence Reasons Reference" access right (System_EditAbsenceReasons).

Reference determines which actions users will be notified about and which role users need to be notified.

To access reference, open side menu and select "References" → "Notification Schemes" tab.

![Notification Schemes Reference](img/notification-schemes-reference.png)

Reference consists of following parameters:

![Notification Schemes Interface](img/notification-schemes-interface.png)

To add new notification scheme, click create button. For each scheme, configuration form opens. Following is detailed description of notification scheme configuration by sections:

- Work schedule planning
- Operator events
- Operator shifts  
- Requests
- Operator schedules
- Monitoring
- Integrations
- Preferences
- Acknowledgments

##### 3.1.14.1 Work Schedule Planning

In "Work Schedule Planning" section, notifications that system will send during various work schedule actions are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Work schedule creation**: notification sent when work schedule is created
- **Applied work schedule copy creation**: notification sent when clicking "Edit" button for applied work schedule
- **Schedule confirmation**: notification sent when work schedule is confirmed by all responsible users
- **Schedule return for revision**: notification sent when schedule is returned for revision before approval
- **Schedule application pending**: notification sent after schedule approval before application
- **Schedule application**: notification sent when schedule is applied
- **Approval process started**: notification about need to confirm operator wishes for work schedules and vacations sent when operator wish approval process is started
- **Operator wishes confirmed by managers**: notification sent after managers confirm wishes in multi-skill planning template
- **Outdated shift exchange/transfer and vacation requests**: notification sent when shift exchange/transfer and vacation request is outdated due to schedule changes

![Work Schedule Planning Events](img/work-schedule-planning-events.png)

**Recipient**: select users who will receive corresponding notifications.

**Important!** In "Recipients" field, you can check "Employees" checkbox; list of employees who will receive notifications is regulated by business processes.

**Important!** When selecting "Employees" checkbox in "Recipients" section, notifications will be sent according to business process regulated list.

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

##### 3.1.14.2 Operator Events

In "Operator Events" section, notifications that system will send when adding specific special events in operator card are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Sick leave creation**: notification sent when sick leave is created in employee card
- **Sick leave deletion**: notification sent when sick leave is deleted in employee card  
- **Sick leave change**: notification sent when sick leave is deleted from employee card
- **Time off creation**: notification sent when time off is created in employee card
- **Time off deletion**: notification sent when time off is deleted in employee card
- **Time off change**: notification sent when time off is changed in employee card
- **Planned vacation addition**: notification sent when planned vacation is added to employee
- **Planned vacation deletion**: notification sent when planned vacation is deleted
- **Planned vacation change**: notification sent when planned vacation is changed
- **Unscheduled vacation addition**: notification sent when unscheduled vacation is added
- **Unscheduled vacation deletion**: notification sent when unscheduled vacation is deleted
- **Unscheduled vacation change**: notification sent when unscheduled vacation is changed
- **Reserve addition**: notification sent when reserve is added
- **Reserve deletion**: notification sent when reserve is deleted
- **Reserve change**: notification sent when reserve is changed

![Operator Events Configuration](img/operator-events-configuration.png)

**Recipient**: select users who will receive corresponding notifications. For example, if "Employees" checkbox is selected in "Recipient", notification will go to employees whose cards had sick leave set.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

##### 3.1.14.3 Operator Shifts

In "Operator Shifts" section, notifications that system will send during various events related to work schedule correction are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Shift creation**: creating planned shift for operator
- **Shift deletion**: deleting planned shift for operator
- **Additional shift creation**: creating additional shift for operator
- **Additional shift deletion**: deleting additional shift for operator
- **Overtime shift creation**: creating planned shift for operator with overtime hours before or after shift
- **Overtime hours deletion**: deleting overtime hours from shift
- **Shift change**: changing operator shift
- **Additional shift change**: changing operator additional shift
- **Overtime shift change**: changing operator shift with overtime hours

![Operator Shifts Configuration](img/operator-shifts-configuration.png)

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

##### 3.1.14.4 Requests

In "Requests" section, notifications that system will send during various request-related events are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Shift exchange request confirmation**: notification about manager's agreement with shift exchange request between operators
- **Shift transfer request confirmation**: notification about manager's agreement with operator shift transfer request
- **Vacation exchange request confirmation**: notification about manager's agreement with vacation exchange request between operators
- **Vacation transfer request confirmation**: notification about manager's agreement with operator vacation transfer request
- **Shift exchange request cancellation**: notification about manager canceling shift exchange request between operators (re-creating request is possible)
- **Shift transfer request cancellation**: notification about manager canceling operator shift transfer request (re-creating request is possible)
- **Vacation exchange request cancellation**: notification about manager canceling vacation exchange request between operators (re-creating request is possible)
- **Vacation transfer request cancellation**: notification about manager canceling operator vacation transfer request (re-creating request is possible)
- **Shift exchange request rejection**: notification about manager rejecting shift exchange request between operators (re-creating request for these dates is impossible, request author will work selected shift*)
- **Shift transfer request rejection**: notification about manager rejecting operator shift transfer request (re-creating request for these dates is impossible, request author will work selected shift*)
- **Vacation exchange request rejection**: notification about manager rejecting shift exchange request between operators (re-creating request for these dates is impossible, request author will go on vacation on original dates*)
- **Vacation transfer request rejection**: notification about manager rejecting vacation transfer request (re-creating request for these dates is impossible, request author will go on vacation on original dates*)
- **Sick leave creation request confirmation**: notification about manager's agreement with sick leave creation request
- **Time off creation request confirmation**: notification about manager's agreement with time off creation request
- **Unscheduled vacation creation request confirmation**: notification about manager's agreement with unscheduled vacation creation request
- **Sick leave creation request cancellation**: notification about manager canceling sick leave creation request (re-creating request is possible)
- **Time off creation request cancellation**: notification about manager canceling time off creation request (re-creating request is possible)
- **Unscheduled vacation creation request cancellation**: notification about manager canceling unscheduled vacation creation request (re-creating request is possible)
- **Sick leave creation request rejection**: notification about manager rejecting sick leave creation request (re-creating request is impossible, operator won't go on sick leave on selected dates*)
- **Time off creation request rejection**: notification about manager rejecting time off creation request (re-creating request is impossible, operator won't take time off on selected dates*)
- **Unscheduled vacation creation request rejection**: notification about manager rejecting unscheduled vacation creation request (re-creating request is impossible, operator won't take unscheduled vacation on selected dates*)

*rejection means operator cannot create repeat request for selected dates. However, manager can still manually add event to calendar

![Requests Configuration](img/requests-configuration.png)

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

##### 3.1.14.5 Operator Schedules

In "Operator Schedules" section, notifications that system will send during various schedule-related actions are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Current schedule update**: if "Employees" is specified in "Recipient", notification will go to employees whose shifts fell under schedule update period
- **Manual current schedule change**: if when editing lunches/breaks/shifts etc. for operators "Employees" is specified in "Recipient", notification will go to employees whose schedule was changed
- **Operator call to shift**: if when creating "Call to work" event in current schedule "Employees" is specified in "Recipient", notification will go to employees who were called to work
- **Operator call to workplace**: if when calling operator from monitoring page "Employees" is specified in "Recipient", notification will go to employees who were called
- **Lunch start approaching**: notification sent N minutes before lunch start (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose lunch is approaching
- **Break start approaching**: notification sent N minutes before break start (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose break is approaching
- **Lunch end approaching**: notification sent N minutes before lunch end (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose lunch is ending
- **Break end approaching**: notification sent N minutes before break end (configured in "Notification Parameters"). If "Employees" is specified in "Recipient", notification will go to employees whose break is ending
- **Operator didn't come online**: notification sent by monitoring if operator has work time but is not at place (not logged into contact center system or contact center status doesn't correspond to work). If "Employees" is selected in "Recipient", notification will be sent to employees absent from workplace
- **Channel switch approaching**: notification sent N minutes before switching to one of channels specified in "Channel Type" reference and entered on "Current Schedule" page by manager

![Operator Schedules Configuration](img/operator-schedules-configuration.png)

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

**Notification Parameters** – parameters according to which notifications will be sent. Contains time before which employees should be notified about upcoming events.

![Notification Parameters](img/notification-parameters.png)

##### 3.1.14.6 Monitoring

In "Monitoring" section, notifications that system will send during various monitoring-related events are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **SLA deviation (relative to threshold values)**: SLA indicator in specific group went beyond lower/upper boundary
- **Online operators number deviation (relative to threshold values)**: "% operators online" indicator in specific group went beyond lower/upper boundary
- **Load deviation (relative to threshold values)**: load deviation indicator in specific group went beyond lower/upper boundary
- **Operator requirement deviation (relative to threshold values)**: difference between actual number of operators (online) and forecasted number of operators in specific group went beyond lower/upper boundary
- **ACD deviation (relative to threshold values)**: ACD indicator in specific group went beyond lower/upper boundary
- **AHT deviation (relative to threshold values)**: AHT indicator in specific group went beyond lower/upper boundary

![Monitoring Configuration](img/monitoring-configuration.png)

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

**Notification Parameters** – parameters according to which notifications will be sent. Contains monitoring indicators update frequency.

![Monitoring Parameters](img/monitoring-parameters.png)

##### 3.1.14.7 Integrations

In "Integrations" section, notifications that system will send for single event type – personnel synchronization error are configured.

Select "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

![Integrations Configuration](img/integrations-configuration.png)

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

##### 3.1.14.8 Preferences

In "Preferences" section, notifications that system will send during preference-related events are configured.

Select each "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

**Event Type:**

- **Opening preference entry possibility**: notification with information about preference entry period and time is sent when preference entry possibility opens
- **Closing preference entry possibility**: notification about possibility to update work schedule after entering preferences is sent when preference entry period is closed

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

![Preferences Configuration](img/preferences-configuration.png)

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

After operator receives information about preference entry possibility, operator should go to their personal cabinet and specify needed preferences.

##### 3.1.14.9 Acknowledgments

In "Acknowledgments" section, notifications that system will send for single event type – work schedule acknowledgment confirmation are configured. This is notification with information about need to confirm in personal cabinet that operator has acknowledged work schedule.

Select "Event Type" and configure appropriate parameters in "Recipient", "Channels" and "Message Text" sections.

![Acknowledgments Configuration](img/acknowledgments-configuration.png)

**Recipient**: select users who will receive corresponding notifications.

- **Employees**: notification will be sent to employees according to selected event
- **Managers**: notification will be sent to department managers. With appropriate hierarchy configuration, notifications will be sent not only to operator's direct manager but also to manager's manager, etc.
- **Roles**: notification will be sent to users with specific system roles
- **Individual employees**: notification will be sent to specific employees selected from dropdown

**Channels**: select channels through which notifications will be sent.

- **Internal system notifications**: notifications will come to WFM CC system, can be seen in upper right corner
- **Mobile push notification**: notifications will come to smartphone with installed mobile app and enabled notifications
- **Internal system notification and mobile push**: notifications will come both to WFM CC system and smartphone with installed mobile app
- **E-mail**: notification will come to user's email if specified in operator card contacts
- **SMS, Viber**: notification will come by SMS and Viber messenger if corresponding data is specified in operator card

**Message text**: edit message that will come to user with notification. Text is generated automatically when selecting event type but can be changed if necessary. Variables are not recommended to change.

#### 3.1.15 Preferences Reference {#preferences-reference}

The reference is available for viewing to users with "Access to edit Preferences reference" access right (System_AccessWish).

The reference is available for editing to users with "Administrator" system role or any other role with "Access to edit Preferences reference" access right (System_EditWish).

Reference allows reducing number of manual work schedule corrections by planners/managers and increasing operator loyalty by considering their work schedule preferences during planning with maximum possible preservation of required call center level.

To access reference, open side menu and select "References" → "Preferences" tab.

![Preferences Reference](img/preferences-reference.png)

To create new preference, click create button and in appeared window enter parameters specified below and click "Forward" button:

- Name
- Time zone
- When to enter preferences (period during which preferences can be entered)
- For which period to enter preferences
- Regular and priority preferences limit

![Preferences Configuration](img/preferences-configuration.png)

In next window, select Operators who will have possibility to enter preferences. Select Operators through filters or check corresponding checkbox next to surname.

![Preferences Operators](img/preferences-operators.png)

To complete, click "Save" button, to make changes use "Back" button.

When planner/manager creates rule for preference configuration, system will notify about this:

- Operators/managers - when preference entry possibility is open
- Planners/managers - when preference entry possibility is closed

For notifying responsible employees about preferences, "Notification Schemes" reference should be configured in system ("Work Schedule Planning" page).

#### 3.1.16 Exchange Rules Settings Reference {#exchange-rules-reference}

The reference is available for viewing to users with "View Exchange Rules Settings Reference" access right (System_AccessRequestRule).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Exchange Rules Settings Reference" access right (System_EditRequestRule).

Reference allows configuring conditions for creating shift/vacation exchange requests and conditions for creating event requests from operators (sick leave/time off/unscheduled vacation).

To access reference, open side menu and select "References" → "Exchange Rules Settings" tab.

![Exchange Rules Reference](img/exchange-rules-reference.png)

Reference contains following settings:

- Request limitation by functional structure
- Request limitation by organizational structure
- Enabling/disabling mandatory comment when creating request
- Selection of available events for request creation

![Exchange Rules Settings](img/exchange-rules-settings.png)

"Functional Groups" section has two settings: "Consider" or "Don't consider".

When setting "Consider" marker, shift/vacation exchange requests will be visible only to employees with similar functional groups configuration, i.e., employees who belong to same groups. If at least one group differs, request won't be displayed.

When setting "Don't consider" marker, shift/vacation exchange request will be visible to all available employees in system.

![Functional Groups Setting](img/functional-groups-setting.png)

"Organizational Structure" section is responsible for configuring limitations for viewing shift/vacation exchange requests within organizational structure. When selecting specific department, requests will be distributed only to employees within it. If specific department isn't selected, requests from this department will be visible to all other employees.

![Organizational Structure Setting](img/organizational-structure-setting.png)

"Mandatory Comment" section: when enabling mandatory comment, employee will be required to leave comment when creating request, which will be displayed in request itself.

![Mandatory Comment Setting](img/mandatory-comment-setting.png)

"Creating Event Setting Requests" section is responsible for configuring event types for which operator can create requests. For example, when selecting "Sick Leave", "Time Off", "Unscheduled Vacation" events, operator can create requests for these events through personal cabinet.

![Event Setting Requests](img/event-setting-requests.png)

To save changes, click "Apply" button.

#### 3.1.17 Payroll Report Reference {#payroll-report-reference}

The reference is available for viewing to users with "View Payroll Report Reference" access right (System_AccessPayrollReport).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Payroll Report Reference" access right (System_EditPayrollReport).

To access reference, open side menu and select "References" → "Payroll Report" tab.

![Payroll Report Reference](img/payroll-report-reference.png)

Reference contains following settings:

- Build mode
- Overtime hours consideration
- Sick leave display
- Time off display

![Payroll Report Settings](img/payroll-report-settings.png)

In "Report build mode" section, report building parameters are selected: building report by 1C data, building report by actual contact center data, building report by schedule data. If these parameters are checked with checkbox, build mode can be selected when creating report.

![Report Build Mode](img/report-build-mode.png)

In "Overtime hours and weekend work" section, overtime hours and weekends consideration in report by actual contact center data is configured.

![Overtime Configuration](img/overtime-configuration.png)

In "Sick leave display" section, sick leave consideration set in employee card when building payroll report is configured.

![Sick Leave Display](img/sick-leave-display.png)

In "Time off display" section, time off consideration set in employee card when building payroll report is configured.

![Time Off Display](img/time-off-display.png)

To save changes, click "Apply" button.

#### 3.1.18 Channel Type Reference {#channel-type-reference}

The reference is available for viewing to users with "Access to view Channel Type reference" access right (System_AccessChannelType).

The reference is available for editing to users with "Administrator" system role or any other role with "Access to edit Channel Type reference" access right (System_EditChannelType).

Reference allows creating/editing/deleting new channel types.

To access reference, open side menu and select "References" → "Channel Type" tab.

![Channel Type Reference](img/channel-type-reference.png)

Created channels are presented as table with following fields:

- **External ID**: channel type received through integration
- **Channel name**: channel name for display in system UI
- **Planning only within channel**: attribute of possibility to plan simultaneously with other channels
- **Channel color**: channel color designation that will be displayed in employee schedule in personal cabinet

![Channel Type Table](img/channel-type-table.png)

To add new channels, click create button. In opened window, fill all specified parameters.

![Create Channel Type](img/create-channel-type.png)

To delete channel, click delete button and confirm/cancel action.

![Delete Channel Type](img/delete-channel-type.png)

When making changes in this reference, no additional confirmation is needed, all changes are saved automatically.

Additional confirmation of changes in this reference is not required, changes are saved automatically.

### 3.2 Personnel Configuration {#personnel-configuration}

**Functional structure** – type of personnel structure where departments are created according to type of work they perform.

**Organizational structure** – obligations, authorities and interactions by which organization performs its functions.

**Department** – part of organizational structure.

**Manager** – user who is department manager. This setting is made in "Departments" reference in Personnel → Departments section.

**Deputy** – user who is deputy department manager. This setting should be made in "Departments" reference in Personnel → Departments section.

**Service** – functional unit serving tasks on particular topic.

**Simple group** – functional unit that is child to service and serves highly specialized tasks within service's general topic.

**Aggregated group** – functional unit that is child to service and includes simple groups. Aggregated groups are created in WFM CC system, i.e., not transmitted through integration.

#### 3.2.1 Employees {#employees}

The reference is available for viewing to users with "View Employees page" access right (System_AccessWorkerList).

The reference is available for editing to users with "Administrator" system role or any other role with "Edit Work Schedule Templates reference" access right (System_EditScheduleTemplate).

To account for employees in load forecasting and schedule creation in "ARGUS WFM CC" system, you need to create their cards.

The "Employees" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Employees" block:

![Employees Section Access](img/employees-section-access.png)

![Employees Main Page](img/employees-main-page.png)

By default, system displays only active employees (button pressed). To view all employees (active/deactivated) or only deactivated ones, click corresponding button.

For search convenience, use search: start typing employee name and system will display matches by coincidence, you can also filter operator list by department:

![Employee Search Filter](img/employee-search-filter.png)

In employee list, click on employee of interest. Following information will be displayed to the right of selected employee.

Upper part of card (figure 3.2.1.4):

- Surname, Name, Patronymic
- Personnel number
- Information about whether employee is home operator
- Hire date
- Termination date
- ID (internal and external)
- Position
- Time zone
- Department

![Employee Card Upper](img/employee-card-upper.png)

You can go to department by clicking its name. Also in employee card there's possibility to specify comment in free form that won't be visible to employee themselves.

Employee card consists of following information blocks:

- **Current employee work schedule** – shifts and rotation assigned to employee. Work schedule and rotation are needed to determine employee's work and non-work days. Different colors on schedule show different shifts (light green shifts were assigned manually, red ones automatically planned by System). Same shows employee vacation types and their dates.

![Current Work Schedule](img/current-work-schedule.png)

- **Individual business rules for lunches/breaks** (figure 3.2.1.9) that need to be considered when planning employee work schedule. They're needed so system considers breaks/lunches when planning schedule and automatically places them depending on operator load. Creation logic is similar to "Lunches/Breaks" reference. Individual business rules take precedence over general lunch/break business rules.

![Individual Business Rules](img/individual-business-rules.png)

- **Planned services and groups** that employee can handle. To edit groups list, click gear icon. By checking corresponding checkboxes, select main groups that will be planned first.

![Planned Services Groups](img/planned-services-groups.png)

- **Contacts**: contains contact information for communicating with employee (email address, landline phone, mobile phone, other (e.g., Telegram login)). Specifying email is additional channel for receiving notifications (with appropriate "Notification Schemes" reference and Server configuration).

![Employee Contacts](img/employee-contacts.png)

- **WFM Account**: account that employee will use to access System. When creating, you need to specify login and password. Creation time is recorded automatically. We recommend mandatory password change on first system login. For this, specify any past date in "Password valid until" field.

WFM account can be blocked: manually by clicking gear, when entering wrong password more than 5 times, when receiving termination date through integration and automatic employee card deactivation.

![WFM Account](img/wfm-account.png)

- **Individual settings**: considered when building work schedule.
  - **Rate** indicates whether employee works full workday (e.g., working 40 hours per week in 5/2 schedule is rate 1.0, working 20 hours per week is rate 0.5). Rate participates in work hours calculation (if it comes through integration, not set manually).
  - **Cost** based on which schedule cost will be calculated. Reference value is set in "Bonus Indicators" reference, individual value in employee card.
  - **Night work** shows whether employee will work night time (night time is set in labor standards configuration). If checkbox isn't checked, system cannot assign night shifts to employee.
  - **Weekend work** shows whether employee can be brought to work on their day off.
  - **Overtime work** determines whether system can add work hours above established norm (adding additional shifts, weekend calls, etc.).
  - **Weekly hours norm (in hours)** – value setting allowable operator work limit per week. Considered when adding additional shifts during work schedule planning; comes through integration.
  - **Daily hours norm (in hours)** overrides daily shift duration during work schedule planning, i.e., if employee has 7 hours per day and work schedule template has 9-hour shift, employee will get 7-hour shift during work schedule planning; comes through integration.

![Individual Settings](img/individual-settings.png)

**Note**: By default, settings in "Labor Standards" reference are set to "Ignore", i.e., by default values specified in individual settings won't be considered; rate will equal one.

- **External system accounts**: attached to employee through integration or manually (through account mapping on "Personnel" → "Personnel Synchronization" page).

![External System Accounts](img/external-system-accounts.png)

- **Vacations**: combination of consecutive days that employee can take as desired vacation (with checkbox checked). Vacation scheme is created on "References" → "Vacation Scheme" page, massively assigned on "Personnel" → "Business Rules" tab.

![Employee Vacations](img/employee-vacations.png)

- **Schedule**: shows employee's shifts, lunches/breaks and events (see "Current Schedule") according to which they should work. Schedule can also be seen in personal cabinet and exported to Excel.

![Employee Schedule](img/employee-schedule.png)

- **Work hours**: shows number of hours operator should work for specific period (year, quarter, month – depending on system setting). Work hours can be assigned manually through card or "Personnel" → "Work Hours" page, and also received automatically through integration with ERP system (e.g., 1C:Payroll).

![Employee Work Hours](img/employee-work-hours.png)

- **Work rules**: show start, duration and shift rotation for selected time period.

On "Shift Rotations" tab, you can check checkboxes:
  - **Assigned**: rotations that system considers when planning work schedule. If several are selected, any of them is chosen depending on need.
  - **Wishes**: rotations that will be prioritized when planning work schedule. Wish can be marked by operator themselves in personal cabinet (from all checkboxes in this area only this one is available to them), or can be set by senior operator or administrator.
  - **Lock scheme**: only this rotation will be used for work schedule planning.

![Work Rules](img/work-rules.png)

- **Roles**: responsible for access rights to System functionality. Each role can be configured by User so employees see only blocks from their responsibility area (see "Roles" Reference).

![Employee Roles](img/employee-roles.png)

- **Skills**: used when filtering employees in schedule, monitoring and reporting. You can specify level (beginner, intermediate, champion) and English language proficiency attribute (yes, no).

**Important!** Skills don't affect planning processes.

![Employee Skills](img/employee-skills.png)

##### 3.2.1.1 Creating and Editing Employee Card

Employee card is important system element as it stores information about specific employee's schedule, individual parameter settings, and allows "ARGUS WFM CC" system to consider employee's work schedule when planning schedule.

To create employee card, click create button:

![Create Employee](img/create-employee.png)

Unfilled card of employee being created will be displayed on right:

![Empty Employee Card](img/empty-employee-card.png)

Specify:

- **Employee full name**: mandatory fields. If no patronymic – put space
- **Personnel number**: comes through integration or filled manually
- **Home operator**: filled manually when necessary. This attribute allows separating office and home employees
- **Termination date**: comes through integration or filled manually
- **Hire date**: comes through integration or filled manually
- **Employee location time zone**: selected from dropdown (filled in "Time Zones" reference)
- **Department**: comes through integration or filled in "Personnel" - "Departments" block
- **Position**: comes through integration or filled manually from dropdown (entered in "Positions" reference through database when no integration)
- **External ID**: comes through integration
- **Comment**: filled manually when necessary

To save, click save button. Employee card editing will only be possible after saving mandatory information.

Function for editing "Full Name", "Personnel Number" and "Home Operator" mark is similar to creation function. To edit previously entered parameters, left-click on any of above fields – they become available for editing, then change needed parameter and click save.

![Edit Employee Basic Info](img/edit-employee-basic-info.png)

Work schedule in employee card is displayed in two views: calendar and tabular:

![Work Schedule Views](img/work-schedule-views.png)

- **Calendar view**: displays employee work days
- **Tabular view**: displays work hours (horizontally) for employee by days (vertically)

To change time zone in which work schedule is displayed in tabular view, select desired one from dropdown:

Work schedule is needed for system to determine work and non-work days. Rotation is needed to determine work day, weekend and shift sequence.

**Services and groups**: displays information about which group and service employee belongs to. When clicking gear, this list can be edited.

![Edit Services Groups](img/edit-services-groups.png)

**WFM Account**: for system login, employee needs to create account and assign role with access rights for correct system operation.

To create and edit user accounts, you need "Edit employee account" access right (System_EditLogin).

To create account, click "Create" button:

![Create Account](img/create-account.png)

Specify mandatory parameters – account login and password. Additionally, you can specify email address. To save data, click save button:

![Account Details](img/account-details.png)

After creating account, you can specify password validity period. For this, left-click on "Password valid until" field and select date in calendar:

![Password Validity](img/password-validity.png)

To save data, click save button.

**Example**: When employee will soon go on vacation or maternity leave, senior operator can limit password validity date.

To delete created account, click gear button and select "Delete" from context menu:

![Delete Account](img/delete-account.png)

Then system will ask to confirm action:

![Confirm Delete Account](img/confirm-delete-account.png)

To confirm deletion, click "Yes", to cancel – "No".

To change account password (for security), click gear button and select "Change password" from context menu:

![Change Password](img/change-password.png)

Then enter new password and repeat it:

![Enter New Password](img/enter-new-password.png)

To save new password, click save button.

To block account, click gear button and select "Block" from context menu:

![Block Account](img/block-account.png)

Blocked account will display "Blocked since" field showing account blocking date and time:

![Blocked Account Display](img/blocked-account-display.png)

To unblock account, click gear button and select "Unblock" from context menu:

![Unblock Account](img/unblock-account.png)

**Example**: When employee goes on vacation, maternity leave or takes extended sick leave, senior operator should block account, upon return – reactivate it. When blocking password, employee will be displayed in list as active.

**Roles**: to assign role to employee, check checkbox. To change employee role, uncheck checkbox. One employee can have multiple roles.

![Assign Roles](img/assign-roles.png)

To assign role to operator, you need "Edit Roles block" access right (System_EditWorkerRole).

**Skills**: to assign appropriate skill level, mark by left-clicking:

![Assign Skills](img/assign-skills.png)

To change previously marked level (was "Beginner", became "Intermediate"), left-click on different level (click "Intermediate").

If employee knows English, click button. In "English proficiency" parameter, button will change appearance.

**Contacts**: to add employee contact data, click button and select contact type from dropdown menu:

![Add Contact](img/add-contact.png)

After selecting contact type, fill "Value" and "Description" fields:

![Contact Details](img/contact-details.png)

To save data, click save button.

To delete, click delete button, to edit – edit button.

**Vacations**: to create individual vacation scheme setting, set "Minimum time between vacations (Days)", "Maximum vacation shift" and "Vacation scheme":

![Vacation Settings](img/vacation-settings.png)

- **Minimum time between vacations (Days)** – select how many days should pass from last vacation end to assign new vacation
- **Maximum vacation shift** – determines number of days by which already assigned employee vacation can be moved during work schedule planning (specified in days)
- **Vacation scheme** – vacation scheme created in "Vacation Schemes" reference is selected here. Vacation scheme sets number of vacations and their duration

##### 3.2.1.2 Adding, Deleting Employee Special Events

Event addition is available to users:
- with "Administrator" system role or any other role with access rights:
- System_AddVacationWithoutChecks – allows adding "Planned vacation" and "Unscheduled vacation" events without mandatory checks

Event editing is available to users with access rights:
- System_EditMySchedule – allows editing own events in calendar
- System_EditMySickLeave – editing "Sick leave" event
- System_EditMyCompLeave – editing "Time off" event
- System_EditMyPlannedVacation – editing "Desired vacation" event
- System_EditWorkerApprovedVacationAndExtraWork – allows editing approved vacations and "Call to work" shifts
- System_EditWorkerPlannedVacation – allows deleting desired vacation

Special event represents employee event going beyond their work schedule.

Following events can be registered as special in system:
- Sick leave (icon on work schedule)
- Vacation (icon on work schedule)
- Time off (icon on work schedule)
- Call to work (icon on work schedule)
- Reserve (icon on work schedule)

Employee special event is considered when planning schedule.

**Adding Special Event**

**Example 1**: Employee got sick, goes on vacation, took time off. Manager needs to record this event to not consider employee in load forecasting and schedule creation for these dates.

To add special event, open their card, "Current Work Schedule" block.

Employee work schedule is displayed in two views: calendar and tabular:

![Special Event Calendar](img/special-event-calendar.png)

Days in calendar view are selected in several ways:
- One day in calendar is selected by left mouse click
- Different days in calendar are selected by left mouse click with CTRL pressed
- Period of days can be selected in two ways:
  - With SHIFT pressed, select day – interval start, then select day – interval end
  - With CTRL pressed, sequentially select days from period

Days in tabular view are selected:
- One/several days in calendar are selected by area capture. For this, select area while holding left mouse button:

![Tabular Selection Area](img/tabular-selection-area.png)

![Tabular Selection Result](img/tabular-selection-result.png)

- You can select specific hours. For this, left-click on hour of interest:

![Select Specific Hours](img/select-specific-hours.png)

- With CTRL pressed, you can select different hours from different days or from one day:

![Multiple Hour Selection](img/multiple-hour-selection.png)

After selecting required period, call context menu with right mouse button and click "Add event":

![Add Event Context](img/add-event-context.png)

![Add Event Dialog](img/add-event-dialog.png)

In appeared "Add special event" window:
- Select required event type from dropdown. If "Time off" is selected, absence reasons from "Absence Reasons" reference will additionally be pulled for it
- By default, "Selection" parameter is selected in "Period" area. Below are displayed days and hours selected when highlighting them on calendar:

![Event Period Selection](img/event-period-selection.png)

- If you need to specify different date range, select "Range" parameter in "Period" area and specify event start and end date:

![Event Date Range](img/event-date-range.png)

- To save special event, click save button.

Added special event will be displayed on employee work schedule:

![Added Special Event](img/added-special-event.png)

**Deleting Special Event**

To delete special event, select days (or at least one day included in special event) on calendar that have special event, call menu by right-clicking and click "Delete event":

![Delete Event Context](img/delete-event-context.png)

![Delete Event Dialog](img/delete-event-dialog.png)

Then system will ask to confirm action:

![Confirm Delete Event](img/confirm-delete-event.png)

If selected period included several special events, uncheck those that shouldn't be deleted.

To confirm special event deletion, click confirm button, to cancel – cancel button.

**Adding Vacation**

Operator can add desired vacation in personal cabinet if assigned System_EditMyPlannedVacation access right.

Manager or any other user with System_AddVacationWithoutChecks access right can assign planned vacation and unscheduled vacation.

Vacations have three types:
- **Desired vacation**: set by operator themselves in their personal cabinet (same as operator card). Is operator's wish for vacation dates, considered when planning vacation
- **Planned vacation**: planned by system under load based on operator's desired vacation or set by operator's manager after reviewing operator's wish or without review. This vacation type is considered when planning work schedules and vacations
- **Unscheduled vacation**: unplanned vacation (unpaid vacation, vacation at own expense, sick leave vacation, etc.) set by manager. Considered when planning vacations and work schedules

To add Desired vacation, right-click any date in tabular or calendar view, then "Add event" and select Desired vacation:

![Add Desired Vacation](img/add-desired-vacation.png)

In opened window, select "Vacation scheme", vacation creation method ("Period" or "Calendar days"), specify vacation dates according to "Vacation schemes".

**Note**: When setting vacations according to "Vacation schemes", there's no need to follow vacation sequence set in selected scheme, it's sufficient to follow total number of vacations and days in vacations.

If "Period" vacation creation method is selected:
- Need to specify vacation start and end date
- Vacation doesn't shift if holidays fall in its period (e.g., vacation set from 25.04 to 08.05. Despite one holiday falling in this period: "May 1", vacation doesn't shift. Work return date – 09.05)
- From accumulated vacation days, number of days considering holidays is subtracted (e.g., vacation set for 14 days with 1 holiday in period. 13 days are subtracted from accumulated days, not 14)

If "Calendar days" vacation creation method is selected:
- Need to specify vacation start date and number of vacation days (vacation end date will be pulled automatically)
- Vacation shifts by number of holidays (e.g., vacation set for 14 calendar days from 25.04 to 08.05. This period includes one holiday "May 1", so vacation shifts to 09.05. But "May 9" is also holiday, so vacation shifts again. Work return date – 11.05)
- From accumulated vacation days, number of days without considering holidays is subtracted (in above example, 14 vacation days will be subtracted from accumulated days)

**Note**: When selecting vacation dates, consider individual vacation scheme settings. If they are violated, user will receive warning and vacation won't be assigned. However, if manager assigns vacation, they'll get "Confirm" button to assign schedule bypassing operator's personal vacation settings. Also consider "Accumulated vacation days" setting from "Labor Standards" reference. If vacation is set exceeding accumulated days, depending on settings system will either allow assigning such vacation, show warning and not assign vacation, or show warning and offer to assign vacation anyway.

When setting vacation dates, user is helped by field showing accumulated vacation days number – number of vacation days remaining for operator after assigning vacation dates. Days number comes through 1C integration. Example: operator has 10 vacation days remaining on 01.06.2018. Once vacation is set from 01.06.2018 to 07.06.2018, they'll have 3 vacation days left and same value will be displayed in "Accumulated days number" field.

Without 1C integration, accumulated vacation days number can be entered by script through database by ARGUS NTC specialists, but most often this field is ignored in such cases.

After filling all data, confirm vacation creation or cancel changes. After creating vacation, it can be seen by setting "Desired vacation" filter (if desired vacation was created) or "Planned vacation" filter (if planned vacation was created) in tabular mode.

![Vacation Filter](img/vacation-filter.png)

**Unscheduled Vacation**

To add unscheduled vacation, right-click needed date in tabular or calendar mode and click "Add event" and select "Unscheduled vacation" event:

![Add Unscheduled Vacation](img/add-unscheduled-vacation.png)

When selecting "Unscheduled vacation" type, specify vacation start and end date in dialog. If there's additional setting, fill "Comment" field.

When adding "Unscheduled vacation" to employee, accumulated vacation days are not subtracted.

![Unscheduled Vacation Details](img/unscheduled-vacation-details.png)

##### 3.2.1.3 Viewing Work Hours Statistics for Current Period, Individual Work Hours Standard Correction

Correction actions are available to users with "Administrator" role or any other role with "Assign work hours for period in employee card" access right (System_EditWorkerNormHours).

**Work hours** – number of hours operator should work during reporting period.

Each operator can have their own work hours, so WFM CC system implements possibility to set work hours standard individually (see below) and massively (3.2.6. Mass Work Hours Assignment).

**Reporting period** – period for which operator should work their work hours.

To calculate work hours by standard and work hours by schedule in "Work hours by years" area, select needed year:

![Work Hours By Years](img/work-hours-by-years.png)

Below year selection, table with following data will be displayed:
- **Period**: current reporting period
- **Standard**: number of hours operator should work during reporting period in current month
- **By schedule**: number of work hours in shift (according to work schedule assigned to employee) and all work call wishes (if operator is home) for current month reporting period

![Work Hours Table](img/work-hours-table.png)

Values in this table are displayed according to setting in "Mass Work Hours Assignment" section. In cases of individual operator work hours, system allows correcting them in this table.

To assign individual work hours standard, select needed year, left-click on "Work hours" column and specify hours in HH:M format in available input fields (e.g., 1972:0 if work hours are annual).

To get work hours standard from 1C through integration, select year for which to get work hours and click get button.

![Get Work Hours](img/get-work-hours.png)

If work hours were previously received for operator for entire year, but after receiving value they resign (same year), to update work hours value need to re-request it in 1C by clicking get button.

##### 3.2.1.4 Employee Deactivation and Activation

To deactivate employee card, select them in list and click "Deactivate employee" button. If employee has account for system login, it's automatically blocked upon deactivation.

![Deactivate Employee](img/deactivate-employee.png)

**Example**: If employee went on extended vacation, sick leave or maternity leave, and senior operator finds it inconvenient that they're displayed in employee list, senior operator can deactivate employee.

**Important!** When employee who needs to be deactivated participates in current schedule at deactivation moment and after, then:

1) In deactivated employee's work schedule after deactivation, shifts will be displayed according to current schedule
2) When creating schedule that intersects current schedule, deactivated employee will be displayed in new schedule. To prevent this, after employee deactivation, coordinator should update current schedule with "Update only changed intervals" parameter

To restore (activate) previously deactivated employee, select them in list and click "Activate employee" button. Since employee account is blocked upon deactivation, after restoring such employee, their account needs to be unblocked:

![Activate Employee](img/activate-employee.png)

**Example**: If employee returned from maternity leave, their card needs to be activated.

##### 3.2.1.5 Shift Exchange

Operator can exchange shifts or vacation with other operators. For shift exchange, work schedule must be planned. Exchange request is created from operator's personal card:

![Shift Exchange](img/shift-exchange.png)

Select shift in tabular or calendar view with left mouse button, call context menu with right mouse button and select "Shift exchange". In opened window, specify shift work date:

![Shift Exchange Dialog](img/shift-exchange-dialog.png)

Shift exchange request appears on WFM CC main screen. Depending on who views requests, display will change.

If viewed by employee who cannot accept exchange request:

![Cannot Accept Exchange](img/cannot-accept-exchange.png)

If viewed by employee who can accept shift exchange request:

![Can Accept Exchange](img/can-accept-exchange.png)

If viewed by operator themselves:

![Own Exchange Request](img/own-exchange-request.png)

Operator can cancel shift exchange request by clicking cancel button. They see not only their request but also requests from operators in same parent department.

When shift exchange request appears, any operator from same parent department who has matching rest and work days with exchange wish and same shift duration can agree to shift exchange.

If shift exchange request is confirmed by another operator, request is displayed to employee manager. Manager needs to either confirm or reject exchange request. In manager's personal cabinet, exchange request is displayed as follows:

![Manager Exchange View](img/manager-exchange-view.png)

If shift exchange request is confirmed by department manager, request status changes to "Confirmed".

![Confirmed Exchange](img/confirmed-exchange.png)

If request is rejected, status changes to "rejected":

![Rejected Exchange](img/rejected-exchange.png)

**Important!** If operator has exchange request in "Not confirmed", "Confirmed", "Awaiting confirmation" statuses, they cannot agree to other requests where "Required replacement date" and/or "Work date" match.

##### 3.2.1.6 Vacation Exchange

Operators can exchange vacations through personal cabinet. Functionality is similar to shift exchange. Operators exchanging vacations must be in same department and vacation days number must match. Only planned vacations can be exchanged. To exchange vacation, go to personal cabinet, select your approved vacation and click "Vacation exchange":

![Vacation Exchange](img/vacation-exchange.png)

Then set vacation date you want to exchange to:

![Vacation Exchange Date](img/vacation-exchange-date.png)

Operator who created request can cancel it. Operator who wants to accept vacation exchange should click accept button when they see suitable vacation:

![Accept Vacation Exchange](img/accept-vacation-exchange.png)

After which status changes to "Awaiting approval":

![Vacation Exchange Awaiting](img/vacation-exchange-awaiting.png)

Now exchange must be confirmed by Department Manager:

![Manager Vacation Approval](img/manager-vacation-approval.png)

Similar to shift exchange, status can change to "Confirmed" if request was approved or "Rejected" if request was rejected:

![Vacation Exchange Confirmed](img/vacation-exchange-confirmed.png)

##### 3.2.1.7 Vacation Transfer

If operator needs to change planned vacation dates during the year, operator can submit vacation transfer request through Personal Cabinet. For this, in Personal Cabinet select vacation, right-click and select "Vacation transfer":

![Vacation Transfer](img/vacation-transfer.png)

Then set new vacation start date:

![Vacation Transfer Date](img/vacation-transfer-date.png)

After "Vacation transfer" confirmation by department manager where operator belongs, vacation transfer request appears on start page. Manager can confirm or reject transfer, and also cancel request completely. When selecting "Cancel request" option, manager completely cancels vacation exchange possibility for selected dates.

![Manager Vacation Transfer](img/manager-vacation-transfer.png)

![Vacation Transfer Actions](img/vacation-transfer-actions.png)

When manager confirms "Vacation transfer" request, planned vacation date is updated in applied work schedule and employee's Personal Cabinet.

#### 3.2.2 Groups {#groups}

The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Groups page" access right (System_AccessGroupList).

The page is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit groups" access right (System_EditGroup).

To unite employees by their functional duties, "ARGUS WFM CC" system implements possibility of creating groups.

The "Groups" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Groups" block:

![Groups Section Access](img/groups-section-access.png)

![Groups Main Page](img/groups-main-page.png)

By default, system displays all active groups of all types (button pressed). To view all groups (active/deactivated) or only deactivated ones, click corresponding button. To view only simple/aggregated/all groups, click and select needed filter:

![Groups Filters](img/groups-filters.png)

For search, start typing group name in search bar and system will display matches:

![Groups Search](img/groups-search.png)

In groups list, click on group of interest. Complete information about selected group will be displayed to the right:

![Group Details](img/group-details.png)

Group card consists of following blocks:

- **General information**
  - Group name
  - Description: free field for filling. For example, you can specify what exactly the group does
  - External ID: appears if group is created through integration with contact center
  - Integration system: system from which group was received (see "Integration Systems" reference)
  - Group type: simple or aggregated. Difference is that aggregated group can include several simple ones. Aggregation is useful for mass load forecasting
  - Channel type: group belonging to channel type if same-name reference is filled
  - Priority: number from 1 to 100 showing significance of group during planning (where 1 is least, 100 is most)

- **Services**: displays services that include this group. Clicking service name allows going to service card

**Note**: aggregated group should belong to same service as simple groups included in this aggregated group

- **Monitoring settings**: select what data will be used for calculating value on "Resource Requirements" dashboard:
  - Channel type: Voice channel, Non-voice channel, Non-voice channel considering SLA (operator number calculation by voice channel algorithm but considering simultaneous contacts number)
  - SLA calculation: Reverse Erlang formula, Actually processed calls

- **Group structure**: multi-level functional group structure consisting of segments

- **Default operator number forecast parameters**: specify operator calculation parameters that will be automatically set when forecasting load and subsequent operator number calculation

- **Default parameters**: select "Forecast accuracy calculation mode" using marker - By intervals, By hours, By days

- **Operators**: displays operators included in group. If user views "aggregated" group, instead of "Operators" area they'll have "Simple groups" area:

![Aggregated Group Simple Groups](img/aggregated-group-simple-groups.png)

##### 3.2.2.1 Creating New Group

To create new group, click create button and select group type – simple or aggregated.

![Create Group Type](img/create-group-type.png)

Then group creation template appears on right. Mandatory fields – "Name", "Priority" (default 1). "External ID" field will only be filled if group came to WFM CC through integration from external system.

![Group Creation Template](img/group-creation-template.png)

After filling above fields, click save button to save.

To add operators to new group, click add button in "Operators" area. In opened window, select operators who will belong to this group. Search is implemented by "Surname" and "Personnel Number" fields. To save selected operator composition, click save button.

![Add Operators to Group](img/add-operators-to-group.png)

##### 3.2.2.2 Editing Group Description and Operator Composition

To edit group, select it in list and left-click on area with group name and description in right part – change description and click save button.

![Edit Group Description](img/edit-group-description.png)

**Example 1**: Group got new tasks → change group description.

**Example 2**: New employee skills appeared. Accordingly, employees can perform new tasks → add them to groups for consideration in load forecasting.

**Example 3**: Operator was promoted or got certain skills and transferred to another group → remove employee from group since we no longer consider them in forecasting for this group, and add them to another group since we now consider them in forecast for another.

To add operators to new group, in opened window select operators who will belong to new group. Search is implemented by "Surname" and "Personnel Number" fields. To save selected operator composition, click save button. Added employees will be displayed in "Operators" area:

![Added Operators Display](img/added-operators-display.png)

To remove previously added employees from group, select them in list using checkbox and click "Delete":

![Remove Operators from Group](img/remove-operators-from-group.png)

System will ask to confirm action. Click "Yes" to confirm, "No" to cancel:

![Confirm Remove Operators](img/confirm-remove-operators.png)

##### 3.2.2.3 Group Deletion and Deactivation

To deactivate, select group from list and click deactivate button:

![Deactivate Group](img/deactivate-group.png)

Deactivated group can be restored. For this, select inactive filter, then needed group and click activate button:

![Activate Group](img/activate-group.png)

To delete group, select needed active or deactivated group and click delete button. Deleted group cannot be restored.

![Delete Group](img/delete-group.png)

#### 3.2.3 Services {#services}

The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Services page" access right (System_AccessServiceList).

The page is available for editing to users with "Administrator" system role or any other role with "Edit services" access right (System_EditService).

Created services are considered by "ARGUS WFM CC" system when planning load and creating schedules.

The "Services" section can be accessed either through "Personnel" tab from sections list menu or from main page by clicking "Services" block:

![Services Section Access](img/services-section-access.png)

By default, system displays all active services (button pressed). To view all services (active/deactivated) or only deactivated ones, click corresponding button.

For search, start typing service name in search bar and system will display matches:

![Services Search](img/services-search.png)

In services list, click on service of interest. Following information will be displayed to the right:

![Service Details](img/service-details.png)

Group card consists of following blocks:

- **General information**
  - Service name
  - Description: free field for filling. For example, you can specify what exactly the service does
  - External ID: external service ID by which integration determines service in its structure
  - Integration system: system from which service was received (see "Integration Systems" reference)

- **Groups**: displays groups included in service

- **Operators** area displays operators included in selected group in "Groups" area

##### 3.2.3.1 Creating Service

To create new service, click create button, then fill data.

![Create Service](img/create-service.png)

Only "Name" field is mandatory. "Description" and "External ID" are not mandatory, but "External ID" field is necessary for contact center synchronization. After filling information, click save button to save.

Then use search or checkbox to select group that will belong to service and click save button to save.

![Select Service Groups](img/select-service-groups.png)

![Service Groups Display](img/service-groups-display.png)

##### 3.2.3.2 Editing Service Description and Operator Composition of Groups Included in Services

To edit service description, select it in list, left-click on area with service name and description in right part, change any field and click save button.

**Example**: Service got new functional duties. We recommend editing its name and description.

![Edit Service Description](img/edit-service-description.png)

**Editing Operator Composition**

If you select previously added group in "Groups" area, system will display all employees included in group below ("Operators" area):

![Service Operators Display](img/service-operators-display.png)

Employees included in group can be filtered by department.

To add new operators to group, click "Add" button and in appeared window select employee(s) using checkbox and click save button.

**Example**: Employees got new skills – means employees can perform new tasks. To consider them in load forecasting, employees need to be added to corresponding groups.

##### 3.2.3.3 Service Deactivation and Deletion

To deactivate service, select needed service from list then click deactivate button:

![Deactivate Service](img/deactivate-service.png)

To restore deactivated service, select inactive filter, then select needed service and click activate button:

![Activate Service](img/activate-service.png)

To delete service, select active or deactivated service and click delete button:

![Delete Service](img/delete-service.png)

Deleted service cannot be restored.

#### 3.2.4 Departments {#departments}

The page is available for viewing to users with "Administrator", "Senior Operator" system role or any other role with "View Departments page" access right (System_DepartmentsView).

The page is available for editing to users with "Administrator", "Senior Operator" system role or any other role with "Edit organizational structure" access right (System_DepartmentsEdit).

Departments store organizational structure of operators, their hierarchy and department managers. Structure itself can be created manually or received through integration, depending on personnel structure receiving settings. Unlike groups, one operator can only be in one department.

To view departments, open side menu and go to "Personnel → Departments".

![Departments Access](img/departments-access.png)

When opening page, following information will be displayed:

![Departments Interface](img/departments-interface.png)

Left side shows department structure. Departments can be parent and child. To create department, click create button. Name department and select its manager from dropdown. Manager plays important (main) role in work schedule confirmation, can also build department reports but only for their own. To deactivate department, click deactivate button.

Upper part of page shows department information: external id (comes through integration with external systems), its manager, name and "Participates in approval" checkbox. This checkbox allows department manager, their deputy and child department managers to participate in work schedule approval processes, work schedule change approval, operator wish approval.

To change department information, click on corresponding field. To change manager, enter their surname and select suitable employee from dropdown.

Below is information about deputies and operators included in department.

Deputy performs same actions as manager in system but only during their substitution.

![Department Deputies](img/department-deputies.png)

Possibility to assign deputies is available to users with "Administrator", "Senior Operator" system role or any other role with "Assign manager deputies" access right (System_DeputyEdit).

During manager absence, deputy becomes department manager. Direct manager retains their rights. To add deputy, click add button, enter deputy surname and period when they will substitute manager:

![Add Deputy](img/add-deputy.png)

To delete deputy, click delete button.

Employees in department show names and positions that also come through integration. To manually add employee, click add button and enter their name and click save button.

![Add Employee to Department](img/add-employee-to-department.png)

Employees can be moved between departments. For this, select needed operators, click move button and select department to transfer employees to.

![Move Employees](img/move-employees.png)

Department employees and department structure itself come through integration with external systems. If employee was moved from parent department received through synchronization to manually created child department, during re-synchronization this operator will remain in child department. Also if integration provides information that parent department is deactivated, all its manually created child departments will also be deactivated.

#### 3.2.5 Mass Assignment of Business Rules and Vacation Schemes {#mass-assignment-business-rules}

When configuring employee cards, assigning business rules to specific employee was described. For convenience, "ARGUS WFM CC" system implements possibility of mass business rule assignment to group of employees working under one standard ("Business Rules" section).

"Business Rules" section can be accessed either through "Personnel" tab from sections list menu "Business Rules" or from main page by clicking "Mass Assignment" button.

![Mass Assignment Access](img/mass-assignment-access.png)

Left part of page displays employee list:

![Mass Assignment Employee List](img/mass-assignment-employee-list.png)

By default, system displays employee list for all groups. To filter employee list, use following parameters:

- **Departments**: allows filtering operator list by department they belong to
- **Segment**: allows filtering operator list by segment they belong to
- **Groups**: allows filtering operator list by checking checkbox next to desired group
- **Type**: allows filtering operator list by selecting one of options (office or home operators)
- **Search**: allows selecting specific operators by entering Surname and Personnel Number (search by full or partial match)

To assign lunch/break business rule, use same logic described in section 3.1.11 "Lunches/Breaks Reference".

To assign vacation schemes, fill vacation parameters and select needed vacation scheme (can select more than one).

![Vacation Scheme Assignment](img/vacation-scheme-assignment.png)

**Minimum time between vacations (Days)**: specify number of days that should pass from last vacation end to assign new vacation.

**Maximum vacation shift**: specify number of days by which already assigned employee vacation can be moved during work schedule planning (specified in days).

**Vacation scheme**: select vacation scheme from previously created in "Vacation Schemes" reference. Vacation scheme sets number of vacations and their duration.

After forming business rules, they need to be mass assigned to employees. For this, select needed employees in list (by checking checkbox) and click "Apply to selected" button.

![Apply to Selected](img/apply-to-selected.png)

In case of successful assignment, system will display corresponding message:

![Assignment Success](img/assignment-success.png)

#### 3.2.6 Mass Assignment of Work Hours {#mass-assignment-work-hours}

Mass work hours assignment is available to users with "Administrator" role or any other role with "Mass work hours assignment for period" access right (System_AccessNormHours).

**Work hours** – number of hours operator should work during reporting period.

For convenience, WFM CC system implements possibility to assign work hours standard massively (work hours are set for year, quarter or month). Work hours can be assigned manually or received through integration. By default – through integration.

To open section, go to "Personnel" → "Work Hours" tab:

![Work Hours Access](img/work-hours-access.png)

**Manual Work Hours Assignment**

On opened mass assignment page, fill following parameters:

![Work Hours Assignment](img/work-hours-assignment.png)

- **Service**: select from dropdown
- **Group**: select from dropdown. List will display groups included in previously selected service
- **Department**: select department if necessary
- **Year**: select year for which work hours standard is planned

After filling above parameters, section with two blocks will be displayed:

![Work Hours Blocks](img/work-hours-blocks.png)

Block 1 is table with following columns:

- **Work hours**: specify work hours for selected period of specified year. If work hours are quarterly/monthly, need to specify for each quarter/month
- **Reporting period start**: pulled automatically
- **Reporting period end**: pulled automatically

After specifying all parameters, click confirm button to confirm changes or cancel button to cancel.

![Work Hours Confirmation](img/work-hours-confirmation.png)

After saving work hours standards in block 1, select employees (included in specified group) in block 2 who need mass work hours standard assignment. To select all employees, check topmost checkbox:

![Select All Employees](img/select-all-employees.png)

To select individual operators, check checkbox next to them:

![Select Individual Employees](img/select-individual-employees.png)

Click apply button to apply specified parameters.

System will report successful work hours standard assignment for selected employees.

![Work Hours Assignment Success](img/work-hours-assignment-success.png)

Assigned work hours will be displayed in selected employee cards.

**Getting Work Hours Through Integration**

If setting allowing getting load through integration is enabled (set in database), "Assign" button will be replaced with "Get":

![Get Work Hours Integration](img/get-work-hours-integration.png)

To get work hours through integration, select service, group and year. Then select employees for whom to get work hours and click get button.

![Get Work Hours Process](img/get-work-hours-process.png)

Now work hours are received and recorded in operator card.

#### 3.2.7 Personnel Synchronization Reference {#personnel-synchronization-reference}

The reference is available for viewing to users with "Administrator" system role or any other role with "View Personnel Synchronization page" access rights (System_AccessSynchronizationPersonnel).

"Update Settings" block is available to users with "Administrator" system role or any other role with "Configure automatic personnel synchronization" access rights (System_EditSynchronizationPersonnel).

Possibility to perform actions in "Personnel Synchronization" block is available to users with "Administrator" role or any other role with "Perform personnel synchronization" access right (System_AccessSynchronization).

"Personnel Synchronization" reference settings are applied to set parameters according to which automatic synchronization of groups, services and departments between WFM CC and external systems will be performed, namely: through integration, information about created/edited services/groups/departments/employees in external system will be transmitted to WFM CC system, including information about group inclusion in services, employees in groups.

Automatic personnel synchronization uses integration procedures between interacting external systems and "ARGUS WFM CC".

Also this reference implements possibility to analyze received data from external system and apply this data in WFM.

To access reference, open side menu and select "Personnel" → "Personnel Synchronization" tab:

![Personnel Synchronization Access](img/personnel-synchronization-access.png)

Opened page consists of update settings blocks and "Personnel Synchronization" block:

![Personnel Synchronization Interface](img/personnel-synchronization-interface.png)

To change update settings parameters, click on settings block field and set necessary values.

![Update Settings](img/update-settings.png)

**Personnel data receiving frequency from contact center**

Select one of three from dropdown: monthly/weekly/daily. Depending on selected frequency, update parameters can be different.

- **Receiving frequency = Monthly**

![Monthly Frequency](img/monthly-frequency.png)

  - Week number in month: select which week of month to perform personnel synchronization: first/second/third/fourth/last
  - Weekday: select weekday when update will be performed. If week number is first and weekday is Saturday, personnel synchronization will be performed on Saturday of first week
  - Time: specify forecast update time
  - Time zone: specify update time zone

- **Receiving frequency = Weekly**

![Weekly Frequency](img/weekly-frequency.png)

  - Weekday: select weekday when update will be performed
  - Time: specify forecast update time
  - Time zone: specify update time zone

- **Receiving frequency = Daily**

![Daily Frequency](img/daily-frequency.png)

  - Time: specify forecast update time
  - Time zone: specify update time zone

To save changes, click save button.

**Personnel Synchronization Block**

In "Personnel Synchronization" block, you can perform following actions:

- **Get personnel structure**: receives current personnel structure from external system
- **Apply changes**: applies changes received from external system to WFM CC
- **View changes**: allows viewing what changes will be applied before actually applying them

![Personnel Sync Actions](img/personnel-sync-actions.png)

When getting personnel structure, system will display received data and allow analyzing it before applying. This helps ensure correct data before making changes to WFM CC system.

#### 3.2.8 Operator Data Collection {#operator-data-collection}

This section allows collecting and analyzing various operator data for reporting and analytics purposes. Data can be collected automatically through integration or entered manually.

Available data collection includes:
- Work time statistics
- Call handling metrics
- Schedule adherence data
- Performance indicators

![Operator Data Collection](img/operator-data-collection.png)

Data collection helps in:
- Performance analysis
- Schedule optimization
- Resource planning
- Compliance monitoring

---

## 4. Load Forecasting in ARGUS WFM CC System {#load-forecasting}

The load forecasting module is one of the core components of the ARGUS WFM CC system. It allows predicting future call volumes and operator requirements based on historical data analysis, seasonal patterns, and special events.

### Key Forecasting Features:

- **Historical Data Analysis**: Import and analyze past call volumes and handling times
- **Trend Analysis**: Identify long-term patterns in call volume changes
- **Seasonal Component Analysis**: Account for daily, weekly, monthly, and yearly seasonal variations
- **Peak Analysis**: Identify and smooth out anomalous peak values
- **Special Events**: Configure special dates that affect normal call patterns
- **Multiple Forecasting Models**: Support for different calculation methods including Erlang C, Linear models, and SLA-based approaches

### Forecasting Process:

1. **Data Import**: Historical call data is imported from external systems or files
2. **Data Validation**: Review and clean historical data, excluding outliers
3. **Trend Analysis**: Identify underlying growth or decline patterns
4. **Seasonal Analysis**: Calculate seasonal coefficients for different time periods
5. **Forecast Generation**: Generate future call volume predictions
6. **Operator Calculation**: Convert call forecasts to operator requirements
7. **Forecast Accuracy**: Monitor and improve forecast precision over time

![Load Forecasting Process](img/load-forecasting-process.png)

The forecasting module integrates closely with scheduling to ensure optimal staffing levels while maintaining service quality standards.

---

## 5. Load Viewing {#load-viewing}

The Load Viewing module provides comprehensive visibility into current and forecasted workload across all groups and services.

### 5.1 Viewing Load for Groups

Load can be viewed at different organizational levels:
- Service level aggregation
- Individual group details
- Time-based filtering (daily, weekly, monthly)
- Real-time vs. forecasted comparisons

### 5.2 Forecast Corrections

The system allows making adjustments to generated forecasts:

#### 5.2.1 Updating Forecasted Operator Numbers
Modify predicted operator requirements based on business changes or new information.

#### 5.2.2 Operator Count Adjustment with Reserve Coefficient
Apply safety margins to ensure adequate staffing during uncertain periods.

#### 5.2.3 Call Volume Adjustment with Growth Factor
Adjust forecasted call volumes to account for business growth or decline.

#### 5.2.4 Forecast Adjustment with Minimum Operator Count
Set minimum staffing levels regardless of forecasted demand.

### 5.3 Load Import from File

Alternative method to input load data:

#### 5.3.1 Import Ready Call Forecast
Import pre-calculated call volume predictions from external sources.

#### 5.3.2 Import Ready Operator Forecast
Import pre-calculated operator requirement forecasts.

---

*[This translation covers pages 1-199 of the 462-page document. The translation maintains the original structure, technical terminology, and formatting while providing clear English equivalents for all Russian terms and concepts.]*