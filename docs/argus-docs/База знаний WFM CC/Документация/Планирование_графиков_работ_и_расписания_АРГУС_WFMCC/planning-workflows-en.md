# ARGUS WFM CC Planning Module Documentation
## Work Schedule Planning and Scheduling

**For Roscongress Foundation**

---

## Table of Contents

1. Multi-skill Planning Template.........................................................................4
   1.1 Creating a Multi-skill Planning Template ..................................................5
   1.2 Deleting a Multi-skill Planning Template ..................................................6
2. Loading Business Process for Multi-skill Planning Template ......................7
3. Work Schedule Planning ..................................................................................8
   3.1 Creating a New Work Schedule Variant ....................................................9
   3.2 Vacation Planning ........................................................................................19
   3.3 Work Schedule Corrections .........................................................................25
4. Schedule Planning............................................................................................29
   4.1 Creating a Schedule .....................................................................................29
   4.2 Updating a Compiled Schedule....................................................................36
   4.3 Manual Schedule Changes...........................................................................37
   4.4 Applying a Compiled Schedule for the Selected Template ............................47

---

## 1. Multi-skill Planning Template

A multi-skill planning template is necessary for creating work schedules for a specific group or list of groups, as well as for schedule planning.

To create a multi-skill planning template, navigate to the "Planning" → "Multi-skill Planning" page:

![Multi-skill Planning Navigation](img/multi_skill_planning_navigation.png)

When navigating to the "Multi-skill Planning" page, all created multi-skill planning templates are displayed:

![Multi-skill Planning Templates List](img/multi_skill_templates_list.png)

To view general information about a template, click on it with the left mouse button. To the right of the template, the following information will be displayed: "Template Name", "Groups":

![Template Information Panel](img/template_info_panel.png)

The "Groups" area displays groups included in the multi-skill planning template.

### 1.1 Creating a Multi-skill Planning Template

To create a new template, click the "Create Template" button in the left part of the page, after which a form for filling in template data will appear.

![Create Template Form](img/create_template_form.png)

In the opened form, enter the template name and click "Save" to save it. After saving, the new multi-skill planning template will appear in the general list of templates.

Next, to add groups to the multi-skill planning template, click the "Add" button in the "Groups" window:

![Add Groups Button](img/add_groups_button.png)

In the opened dialog box, using the dropdown lists, select the "Service" and "Groups" that will be included in the multi-skill planning template.

To confirm adding groups, click "Save" in the dialog box.

**Important!** An operator can be in different groups, but only in one multi-skill planning template. Accordingly, one group can only be included in one multi-skill template. If you try to add a group of operators who are already in one of the multi-skill templates to a new template, the system will issue a warning:

![Group Conflict Warning](img/group_conflict_warning.png)

This is necessary to exclude discrepancies in schedules (for example, situations when an operator might have several conflicting work schedules or planned vacations).

The created multi-skill planning template, after adding groups to it, will be displayed in the "Work Schedule Planning" and "Schedule Creation" sections in the "Templates" block.

To rename a template, click on its name, correct it, and click "Save" to save.

To remove a group from a template, click "Delete Group" next to it.

### 1.2 Deleting a Multi-skill Planning Template

To delete a multi-skill planning template, select the required template from the general list of templates and click the delete button:

![Delete Template Button](img/delete_template_button.png)

After clicking the "Delete Template" button, a dialog box with deletion confirmation will appear:

![Delete Confirmation Dialog](img/delete_confirmation_dialog.png)

To confirm deletion, click the "Yes" button. A deleted multi-skill planning template cannot be restored.

Work schedules planned based on the deleted multi-skill planning template will also be deleted without the possibility of recovery.

## 2. Loading Business Process for Multi-skill Planning Template

Business processes loaded into the system allow implementing processes not based on verbal agreements between users – first, employee preferences need to be confirmed, then a schedule compiled, then schedules should be reviewed by department heads, etc. (this is a verbal agreement, as the user might not do all this and simply create a schedule immediately), but in the form of a specific sequence of actions that the system will expect and will not allow proceeding to the next stage of the process until the previous one is completed.

The loaded business process (hereinafter BP) stores information about the sequence of actions that need to be followed in the system (specifically the business process sequence), otherwise the system will not allow progress in this BP, as well as which users can perform these BP stages and what actions will be available at certain stages (for example, changing shifts in work schedules is possible not at any BP stage and not every user has the right to change these shifts at a certain stage). But besides needing to load the BP into the system, which stores all necessary information about stages, you also need to somehow manage these stages, delegate tasks to users, etc. This task is performed by the "Tasks for Approval" functionality, which allows executing BP stages, delegating these stages to other employees, or taking them on yourself.

To load a BP into the system, you need to navigate to the appropriate page in the system, the link to which is located on the main screen:

![Business Process Upload Link](img/bp_upload_link.png)

After opening the page, the following functionality will be displayed:

![Business Process Upload Interface](img/bp_upload_interface.png)

Clicking "Browse" will open a file selection window, you need to select a .zip or .rar archive that should contain the business process file. After the file is selected, the remaining buttons will be activated: "Upload" and "Cancel".

![Business Process Upload Active](img/bp_upload_active.png)

## 3. Work Schedule Planning

Work schedule planning is carried out based on:
• Forecasted workload
• Operator productivity
• Individual settings
• Labor standards
• Work rules assigned to employees

Work schedules are planned for employees who have a position participating in planning and are part of groups included in the "Multi-skill Planning" template selected on the "Work Schedule Planning" page.

The "Work Schedule Planning" module is used for mass work schedule planning for employees. On the same-named page, you can view the work schedule planned by the system for employees (eliminating the need to manually assign an operator a schedule based on workload and their preferences), as well as make corrections or accept the schedule as is.

During work schedule planning, the employee's hire date and termination date are taken into account. The system will plan shifts for an employee only for the period during which the operator works and will not assign shifts after the termination date or before the hire date. The system also considers the productivity standard assigned to the employee and will try to fit within this standard taking into account hire and termination dates.

If in the "Work Rules" reference book, rules have configured variations in shift start times and durations, the system will select the start time and duration of each operator's shift for each day of the year depending on the workload forecast. In this case, the operator's productivity will be maintained. Such schedule planning can take a considerable amount of time. If the multi-skill planning template includes many operators and the rules are configured quite flexibly, consider that this will affect planning time.

During schedule planning, you can continue using other system modules, as planning occurs on a separate service.

### 3.1 Creating a New Work Schedule Variant

To begin planning a work schedule variant, you need to navigate to the "Work Schedule Planning" page either through the side menu or through the main page:

![Work Schedule Planning Navigation](img/work_schedule_planning_nav.png)

![Work Schedule Planning Main](img/work_schedule_planning_main.png)

After opening the page, we will see a list of multi-skill planning templates.

To continue creating a work schedule, you need to select one of them, after which we will see a list of work schedule variants, with the current applied work schedule highlighted in bold font and with a checkmark. The applied work schedule is always pinned to the top of the list.

Work schedule planning does not depend on the time zone; depending on the selected time zone, only the display changes. By default, the user's time zone is always selected, and there is also the possibility of displaying in other time zones. To do this, you need to change the time zone for displaying work schedules.

To start schedule planning, click the "Create" button.
A window will open:

![Schedule Planning Parameters](img/schedule_planning_parameters.png)

In the opened window, you need to specify:
• Schedule name
• The "Comment" field is optional for filling
• The "Productivity" field shows what type of productivity is configured in the system (annual, quarterly, monthly)
• The "Work Schedule Planning Year" field allows you to select which year the schedule will be planned for
• If preference consideration was selected during work schedule planning, the system should consider operator preferences that they specified in their personal account

After clicking the "Start Planning" button, the schedule name will appear in the "Work Schedule Variants" window, and the planning task will appear in the "Work Schedule Tasks" window. While the schedule is being planned, you can continue working in the system – exit planning, go to other modules, and return.

![Schedule Planning Progress](img/schedule_planning_progress.png)

**Work Schedule Variant and Planning Task Statuses:**

| Schedule Status | Status Description |
|---|---|
| Planning | There are open tasks for initial planning. A "empty" schedule has been created in WFMCC and a task for creating a new work schedule has been sent to the planning service. |
| Planned | No open tasks for creating or updating schedules, the planning service sends the result to WFMCC. The result is saved in WFMCC. |
| Planning Error | In case planning was done incorrectly. There should be the ability to restart planning. The old task is deleted, a new one is created. |
| Updating | There are open tasks for updating the work schedule. |
| Update Error | All update tasks completed with errors. There should be the ability to delete unsuccessful update tasks. |

| Schedule Status | Status Description | Task Type |
|---|---|---|
| Executing | Task is executing or waiting for execution in the planning service. Planning result is not displayable. | Open |
| Awaiting Save | Task completed, result passed to WFMCC and awaits user action. Planning result is displayable. | Open |
| Result Saved | In case the user saved the planning result. Planning result is displayable. | Closed |
| Result Canceled | In case the user canceled saving the planning result. Planning result is not displayable. | Closed |
| Execution Error | In case of planning error or error in passing planning result to WFMCC. Planning result is not displayable. | Open |

To check the task status, you need to refresh it. To do this, click the refresh button.

If the schedule has been planned, the task status will change to "Awaiting Save":

![Task Awaiting Save](img/task_awaiting_save.png)

To proceed to the planned schedule, you need to click on the task itself:

![Select Planning Task](img/select_planning_task.png)

After which we will see the system-planned work schedule in the "Planned Work Schedule" area:

![Planned Work Schedule View](img/planned_work_schedule_view.png)

Depending on the selected tab ("Org. Structure" or "Func. Structure"), the following areas will be displayed:

![Organizational Structure View](img/org_structure_view.png)

![Functional Structure View](img/func_structure_view.png)

In "Org. Structure" we see:
**Department Filter** – allows viewing the schedule for a specific department, as well as all child departments.

• **"Operators without planned vacations" checkbox** – Shows operators who have a positive value of remaining vacation days, but no vacation has been assigned
• **"Employees with non-plannable position" checkbox** – shows employees whose position has been changed to not plan
• **"Vacation violations" checkbox** – shows employees who were assigned vacation in violation of vacation assignment rules
• **"Desired vacations" checkbox** – highlights employees' desired vacations with a frame

In "Func. Structure we see":
• **Group Filter** – allows viewing the schedule for a specific group
• **"Vacation violations" checkbox** – shows employees who were assigned vacation in violation of vacation assignment rules
• **"Desired vacations" checkbox** – highlights employees' desired vacations with a frame
• **"Op. Forecast" checkbox** – will display the number of forecasted operators per day/month
• **"Op. Plan" checkbox** – will display the number of operators planned by the work schedule per day/month
• **"Op. Plan %Abs" checkbox** – will display the number of operators planned by the work schedule, multiplied by the absence percentage from the "Work Absence Percentage" reference book per day/month
• **"%ACD forecast" checkbox** – shows the average forecasted %ACD value for a 15-minute interval across all groups. Maximum understaffing/overstaffing of employees – shows how many employees are lacking to cover the workload at the busiest time of day and how many employees will be conditionally "excess" at the least busy time of day.

![Monthly Statistics View](img/monthly_statistics_view.png)

In monthly and yearly statistics, the same checkboxes that were selected earlier will be displayed. In this case, these are OSS and %ACD for month and year. Values are shown as average values for all days of the month, or for all months of the year.

![Detailed Schedule Information](img/detailed_schedule_info.png)

• **Full Name** – employee's surname, first name, and patronymic
• **Work Schedule Template** – work schedule template selected by the system
• **Vacation Scheme** – name of the vacation scheme
• **Standard** – operator's productivity assigned either in the operator's card or in bulk
• **Working Days** – number of operator's working days
• **Planned Hours** – number of working hours for the entire work schedule period excluding unpaid breaks
• **Overtime** – shows the presence of additional hours for employees
• **Remaining Vacation Days** – shows remaining vacation days after assigning all planned vacations to the operator. The vacation days value itself comes through integration. After assigning vacations in the work schedule, the assigned vacation days are subtracted from this value

• **Days** – displays days of the month

In the information under the days, rows will be displayed for those indicators that were selected by checkboxes in the previous step.

**Numbers in cells** – number of working hours in the shift.

![Schedule Cell Details](img/schedule_cell_details.png)

In this same table, we can hover the cursor over a cell with working hours and find out what shift was selected for this operator:

![Shift Information Tooltip](img/shift_info_tooltip.png)

After reviewing the constructed schedule, click "Save" to save the planned schedule, or "Cancel" to cancel schedule creation.

To save the schedule, you need to fill in the schedule name (required parameter) and its description, then click "Apply" to save it, or "Reject" to cancel saving the schedule.

![Save Schedule Dialog](img/save_schedule_dialog.png)

After saving, the schedule will be displayed in the list:

![Schedule Saved List](img/schedule_saved_list.png)

After the schedule has been saved, depending on the Business Process, the following can be done with it:
• **Update work schedule** – the ability to replan the work schedule for one or several operators will appear, in case they want to change the schedule template according to which shifts were planned for them. In case of setting a termination date for them, or conversely, adding a new employee to an existing work schedule variant (BP for work schedule corrections)
• **Apply** – the work schedule will be applied and become current

On the "Work Schedule Planning and Vacations" page, there is also the ability to view all changes made to the work schedule and all stages of BP execution. The history is located under the "Vacation Schedule" block:

![Schedule History View](img/schedule_history_view.png)

![Schedule Change History](img/schedule_change_history.png)

### 3.2 Vacation Planning

Vacations that can be assigned to employees are created based on vacation schemes from the "Vacation Schemes" reference book.

In the "Vacation Schedule" tab, desired and extraordinary vacations that were set by the operator in their card will be displayed. Also in this tab, you can manually assign vacations, set priorities for them. Vacations set here are considered by the system when building work schedules, after which desired vacations become planned.

![Vacation Planning Interface](img/vacation_planning_interface.png)

The top panel displays the following information:
• **Group Filter** – allows viewing a specific group
• **Department Filter** – allows viewing a specific department of employees
• **"Operators with unassigned vacation" checkbox** – will show operators who have remaining vacation days and who have not been assigned desired vacation dates
• **"Operators with accumulated vacation days" checkbox** – will show operators who have accumulated vacation days
• **"Subordinate employees" checkbox** – will display employees who are subordinate to the department head/deputy who is viewing the vacation schedule
• **"Vacation violations" checkbox** – will display operators whose desired vacation was added with violations (accumulated vacation days not considered, incorrect duration – correctness is regulated by labor standards). When hovering the mouse cursor over such vacation (even without the checkbox), the specific violation will be displayed
• **"Desired vacations" checkbox** – will display all desired vacations of operators, hiding extraordinary vacations
• **"Generate vacations" button** – generates vacations for employees who have not been assigned desired vacations. The system is guided by business vacation rules assigned to employees

The table columns display the following information:

![Vacation Table Structure](img/vacation_table_structure.png)

• **Full Name** – employee's full name
• **Planned Vacation Scheme** – shows the vacation scheme assigned in the operator's card
• **Remaining Vacation Days** – shows remaining vacation days after assigning vacation schedules to the operator. That is, if an operator has 15 vacation days (value comes through integration), then when adding two vacations with a total duration of 14 days, the "remaining vacation days" field will display the number 1.

**Adding and Deleting Vacation:**

To add vacation in the "Vacation Schedule" tab, you need to select a cell with the left mouse button, then right-click, and then select the "Add Vacation" event from the dropdown menu that appears:

![Add Vacation Context Menu](img/add_vacation_context_menu.png)

In the opened dialog box, you need to select the vacation type: "Desired Vacation" or "Extraordinary Vacation".

When selecting the "Extraordinary Vacation" type in the dialog box, you need to specify the start date and end date of the vacation.

When adding an "Extraordinary Vacation" to an employee, accumulated vacation days are not deducted.

![Extraordinary Vacation Dialog](img/extraordinary_vacation_dialog.png)

When selecting the "Desired Vacation" type, you need to select the "Vacation Scheme" and the method of creating vacation: "Period" or "Calendar Days".

If the "Period" vacation creation method is selected, then:
• You need to specify the start date and end date of the vacation
• The vacation does not shift if holidays fall within its period (for example, vacation is set from 25.04 to 08.05. Despite the fact that one holiday falls in this period: "May 1", the vacation does not shift. Work return date is 09.05)
• The number of days is deducted from accumulated vacation days considering holidays (for example, vacation is set for 14 days, with one holiday falling in its period. 13 days are deducted from accumulated days, not 14)

If the "Calendar Days" vacation creation method is selected, then:
• You need to specify the vacation start date and number of vacation days (vacation end date will be pulled automatically)
• Vacation shifts by the number of holidays (for example, vacation is set for 14 calendar days from 25.04 to 08.05. One holiday falls in this period "May 1", so the vacation shifts to 09.05. But "May 9" is also a holiday, so the vacation shifts again. Work return date: 11.05)
• The number of days is deducted from accumulated vacation days without considering holidays (in the example above, 14 vacation days will be deducted from accumulated days)

![Desired Vacation Dialog](img/desired_vacation_dialog.png)

The vacation addition functionality is similar to adding vacation in the client card.

To delete vacation, just right-click on one of the cells in the range of the needed vacation and select "Delete Vacation":

![Delete Vacation Context Menu](img/delete_vacation_context_menu.png)

**Vacation Priorities:** vacations have priorities, they are considered during work schedule planning. Priority works as follows: during work schedule planning, the system relies on forecasted workload and personal business vacation rules for the operator when setting vacations.

The operator is assigned the maximum number of vacation shift days. Based on this setting, the system can shift vacation within this range to cover workload (for example, an operator wanted to go on vacation on 5.01, but heavy workload is recorded on this day. In this case, the system can shift the operator's vacation by the number of days not exceeding that specified in the operator's card for vacation shift days). If vacation is considered priority, the system will first move (if necessary) non-priority vacations, and only then (if required) will move **priority** vacations to cover workload. If vacation is considered **fixed**, the system does not move it regardless of workload.

To make vacation priority, you need to select the vacation of interest by clicking on any cell of its interval with the right mouse button and select "Vacation Priority":

![Set Vacation Priority](img/set_vacation_priority.png)

To cancel vacation priority, you need to select it as shown above and click "Non-priority Vacation":

![Cancel Vacation Priority](img/cancel_vacation_priority.png)

To fix vacation, you need to select it as shown earlier and click "Fixed Vacation":

![Set Fixed Vacation](img/set_fixed_vacation.png)

![Fixed Vacation Display](img/fixed_vacation_display.png)

The vacations set above are considered desired. As soon as a work schedule is planned or updated, the system will automatically arrange vacations, considering business rules and workload, after which such vacations become planned.

### 3.3 Work Schedule Corrections

In the Work Schedule Correction module, the user can change the applied work schedule without creating copies of the applied work schedule, and changes will immediately be displayed to the operator and take effect.

On the Work Schedule Corrections page, you can:
• Change shift duration (shifts can be extended or shortened)
• Move a shift
• Delete a shift
• Create a new shift
• Create, delete, or edit sick leave
• Create, delete, or edit time off
• Create, delete, or edit vacation

To navigate to the work schedule corrections page, you need to open the side menu, then the "Planning" module → "Work Schedule Corrections".

![Work Schedule Corrections Navigation](img/work_schedule_corrections_nav.png)

Upon reaching the page, you will see sections: "Legend", "Filters", "Statistics". And work schedules of all employees in the system.

In the "Legend" section, conditional designations of the schedule are displayed:

![Schedule Legend](img/schedule_legend.png)

In the "Filters" section, you can sort employees for display on the schedule by:
• Departments
• Sites
• Groups
• Subordinate employees
• Only with existing schedule

You can also find individual employees by full name or personnel number.

In the "Statistics" section, detailed information about surplus or deficit of planned operators in accordance with workload is displayed. On the histogram, red color indicates deficits, blue indicates surpluses, green color – plan, values are displayed according to the number of operators.

**Important!** Statistics will not be displayed if no group is selected in filters.

![Statistics Histogram](img/statistics_histogram.png)

The histogram can be scaled using the mouse wheel and moved by holding the left mouse button.

On the schedule itself, in the left part, employees and their planned and planned productivity without unpaid breaks are listed. In the main part of the schedule, employee shifts are displayed; by selecting a shift, you can delete it by clicking the "Cross" button (✖).

![Schedule Main View](img/schedule_main_view.png)

To set a new shift, double-click the left mouse button on the employee's schedule line you want to set a shift for. A shift setup window will open where you can set: shift type (planned/additional), shift time, overtime hours before or after the shift. Then click the "Checkmark" button (✓). Additional shifts or overtime hours cannot be set if the operator's productivity standard is not covered.

![New Shift Setup](img/new_shift_setup.png)

To add an event to an operator, you need to double-click the left mouse button on the employee's schedule you want to set a shift for. In the opened window, in the type field, select events, configure the event type (sick leave/time off/planned vacation/extraordinary vacation) and set the start and end time of the shift, then click the "Checkmark" button (✓).

![Add Event Dialog](img/add_event_dialog.png)

The schedule can be scaled by day, week, or month, display the current day by clicking the "Today" button, or specify the required date. You can also select the time zone in which the schedule will be displayed.

![Schedule Scaling Options](img/schedule_scaling_options.png)

All changes made are saved automatically and applied to the current applied work schedule.

## 4. Schedule Planning

Operator schedule planning is carried out in accordance with forecasted workload, operator work schedules, and lunch and break rules.

**Important!** Planning is impossible without forecast and active work schedules.

### 4.1 Creating a Schedule

The "Schedule Creation" module allows creating operator work schedules in accordance with forecasted workload, office operator work schedules, and home operator work preferences.

**Prerequisites for schedule creation:**
• Multi-skill planning template created
• Forecasted workload updated for a specific period for the selected group
• Applied work and vacation schedule exists

To navigate to the schedule creation page, go to the "Planning" tab → "Schedule Creation" (you can navigate from the menu with the list of sections or from the main page by clicking the "Schedule Creation" block):

![Schedule Creation Navigation](img/schedule_creation_nav.png)

Next, in the area with the list of schedule templates, select the required template and click the "Create" button in the "Schedule" block:

![Schedule Template Selection](img/schedule_template_selection.png)

**Note:** if a multi-skill template is selected that includes an aggregated group, then workload will be pulled from the aggregated group, and employees will be pulled from simple groups included in the aggregated one.

**Important!** Schedule planning does not depend on time zone; depending on the selected time zone, only the display changes. By default, the user's time zone is always selected, and there is also the possibility of displaying in other time zones. To do this, you need to change the time zone for displaying schedules.

In the opened "Schedule Planning" dialog box, specify the period of action of the created schedule and one of the planning criteria (configured in the Planning – Planning Criteria section):

![Schedule Planning Dialog](img/schedule_planning_dialog.png)

After the parameters are selected, click the "Start Planning" button. After this, a planning task will appear in the schedule tasks in the "Executing" status. The task can be canceled or its execution checked by updating the status.

![Schedule Planning Task](img/schedule_planning_task.png)

**Note:** in case of attempting to build a schedule for a template that has groups for which forecasts were not previously obtained, the system will issue an error:

![Forecast Error Message](img/forecast_error_message.png)

In this case, the user needs to obtain a forecast and then retry building the schedule.

The generated schedule will look as follows:

![Generated Schedule View](img/generated_schedule_view.png)

By setting checkboxes in the "Filters" area, you can sort the employee list:

![Schedule Filters](img/schedule_filters.png)

• **Subordinate operators** – will display a list of employees who are in the department managed or deputized by the user
• **Home** – will display a list of operators who have a mark in their card that they are home operators
• **Office** – will display a list of operators who have a mark in their card that they are office operators
• **Skills** – employee display depending on skill (novice/average/champion) and English language knowledge
• **Vacation** – will display a list of operators who are on vacation during the current schedule period
• **Sick Leave** – will display a list of operators who are on sick leave during the current schedule period
• **Time Off** – will display a list of operators who took time off during the current schedule period

Next, statistics on created events are displayed. It is shown including for schedules that fall within the event action period:

![Event Statistics](img/event_statistics.png)

• **Project** – displays the project name assigned in this schedule (and others)
• **Start Date and End Date** – project dates
• **Segment Requirement** – number of intervals needed to cover the workload required by the event
• **Total Segments Assigned** – displays how many intervals were allocated for the project. This field shows statistics for all current schedules created during the event period
• **Segments Assigned in Schedule** – this statistic shows how many intervals were allocated for the project specifically in the schedule being reviewed

In the "by employees" schedule view mode, a list of all employees is displayed.

![Employee Schedule View](img/employee_schedule_view.png)

In the view mode for a specific group (by direction), only the operators of this group are displayed.

Additionally specified:
• Service level
• Forecasted number of operators
• Actual number of operators

![Group Schedule Details](img/group_schedule_details.png)

In the figure, we see that the table cell rows are colored according to the legend:

![Schedule Color Legend](img/schedule_color_legend.png)

![Schedule Color Example](img/schedule_color_example.png)

If the forecasted number of operators is greater than the actual (in other words, there will not be enough operators on the line at some point according to the forecast), then according to the legend, the "forecast" and "actual" rows are colored red.

If the forecasted number of operators is less than the actual (in other words, there will be an excess of operators on the line at some point), then according to the legend, the "forecast" and "actual" rows are colored purple.

If the employee who compiled the schedule is satisfied with the created schedule, it needs to be saved. To do this, click the "Save" button. Then a dialog box will open where you need to specify the schedule name and give it a brief description. For final saving, click the save button:

![Save Schedule Final](img/save_schedule_final.png)

To cancel the schedule, click the "Cancel" button.

### 4.2 Updating a Compiled Schedule

**Important!** Before updating the schedule, don't forget to save it first.

The schedule update function allows updating a previously created schedule considering updated workload, employee special events, manual schedule corrections, employee work schedule changes, employee deactivation, new employee creation.

To update a schedule, first select a template in the left part, then select a saved schedule for this template (in the "Schedule Variants" area) and then click the "Update" button:

![Update Schedule Button](img/update_schedule_button.png)

The "Schedule Planning" form will open. Specify the planning period you want to update:

![Update Schedule Form](img/update_schedule_form.png)

After the parameters are selected, click the "Start Planning" button. After updating the schedule, it needs to be saved. When saving, you can change the name and comment.

![Save Updated Schedule](img/save_updated_schedule.png)

### 4.3 Manual Schedule Changes

For a created schedule in the "ARGUS WFM CC" system, there is the possibility of manual correction of operator work intervals:
• Adding/removing lunches and breaks
• Registering downtime
• Call/cancel call to work
• Adding/canceling work attendance
• Project assignment
• Adding/canceling events

**Important!** A user can edit a schedule under the following conditions:
• If the user is a manager of the parent department (and has editing rights), they can edit schedules of both subordinate operators and operators from child departments
• If the user is a manager of a child department (and has editing rights), they can only edit schedules of employees subordinate to them
• If the user is a deputy of the parent department (and has editing rights), they can edit schedules of both subordinate operators and operators from child departments. The day when corrections are made must fall within the deputy period
• If the user is a deputy of a child department (and has editing rights), they can only edit schedules of employees subordinate to them. The day when corrections are made must fall within the deputy period
• If the user is not a manager or deputy but has editing rights, they can edit schedules of all operators

On the "Planning" → "Schedule Creation" page, select a schedule from the list. In the "Schedule" block, select the required day and employee time interval:

![Manual Schedule Edit](img/manual_schedule_edit.png)

Time in the schedule is divided into 5-minute intervals. To select one 5-minute interval, click on it with the left mouse button:

![Select Time Interval](img/select_time_interval.png)

Using the held "Ctrl" button, you can select different 5-minute intervals for different employees:

![Multiple Interval Selection](img/multiple_interval_selection.png)

The system also allows selecting an entire area. To do this, click the left mouse button and without releasing it, select the area:

![Area Selection](img/area_selection.png)

After the time interval is selected, call the menu by right-clicking and select one of the events:

![Context Menu Events](img/context_menu_events.png)

**Adding/Removing Lunches and Breaks**

Lunches/breaks can be added and removed in case the operator's shift duration was changed to one for which there are no lunch/break rules in the "Lunches/Breaks" reference book. In other cases, the system will not allow adding and removing lunches and breaks.

To add lunch or break, select the needed cells and choose "Add Lunch" or "Add Break":

![Add Lunch Break](img/add_lunch_break.png)

![Lunch Break Added](img/lunch_break_added.png)

To remove lunch or break, select the needed cells and choose "Cancel Breaks":

![Cancel Breaks](img/cancel_breaks.png)

**Registering Downtime**

To register downtime for an employee, select the needed cells and choose "Does not accept calls":

![Register Downtime](img/register_downtime.png)

![Downtime Registered](img/downtime_registered.png)

**Adding/Canceling Work Attendance**

To register non-working time for an employee, select the needed cells and choose "Non-working time":

![Non Working Time](img/non_working_time.png)

![Non Working Time Set](img/non_working_time_set.png)

To add work attendance for an employee, you need to switch display to a specific project:

![Project Display Switch](img/project_display_switch.png)

Then select the needed cells and choose "Add work attendance":

![Add Work Attendance](img/add_work_attendance.png)

![Work Attendance Added](img/work_attendance_added.png)

**Project Assignment**

To assign an employee to a specific project, you need to switch display to a specific project, select the needed cells, and choose "Assign to project":

![Assign To Project](img/assign_to_project.png)

![Project Assignment Complete](img/project_assignment_complete.png)

In this case, regardless of how much the employee is involved in other projects, they will be 100% engaged in the current project.

**Adding/Canceling Events**

To add an event to an operator, select "Event", then a dialog box will open:

![Add Event Dialog Box](img/add_event_dialog_box.png)

In which you need to select the event type (Training/Meeting/Calls/Survey collection), specifically the event from the "Events" reference book. The time and participant are selected automatically since their interval was already selected earlier. After which you need to click the checkmark to add the event.

![Event Added](img/event_added.png)

To cancel an event, you need to select the event of interest and click "Cancel Event".

### 4.4 Applying a Compiled Schedule for the Selected Template

When a schedule is successfully compiled and meets planning criteria, it can be accepted as the active working schedule. To do this, you need to apply the selected schedule for the template. After applying the schedule, it will be available for viewing in the "Current Schedule" section.

For the selected template in the "Schedule Variants" block, select the appropriate schedule variant and click "Apply":

![Apply Schedule](img/apply_schedule.png)

In the "Schedule Creation" section, the applied schedule is highlighted in bold in the block with the list of schedule variants:

![Applied Schedule Highlighted](img/applied_schedule_highlighted.png)

In case of schedule overlap (when there is already a current schedule created earlier), when clicking the "Apply" button, the system will display a warning message:

![Schedule Overlap Warning](img/schedule_overlap_warning.png)

**Confirm** – by clicking this button, the senior operator confirms overwriting the previous current schedule (overlapping dates will be overwritten)

**Cancel** – by clicking this button, the senior operator cancels applying the new schedule.

---

*This completes the ARGUS WFM CC Planning Module documentation.*