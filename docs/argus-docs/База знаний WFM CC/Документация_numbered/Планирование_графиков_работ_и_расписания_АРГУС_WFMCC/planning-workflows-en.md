    1: # ARGUS WFM CC Planning Module Documentation
    2: ## Work Schedule Planning and Scheduling
    3: 
    4: **For Roscongress Foundation**
    5: 
    6: ---
    7: 
    8: ## Table of Contents
    9: 
   10: 1. Multi-skill Planning Template.........................................................................4
   11:    1.1 Creating a Multi-skill Planning Template ..................................................5
   12:    1.2 Deleting a Multi-skill Planning Template ..................................................6
   13: 2. Loading Business Process for Multi-skill Planning Template ......................7
   14: 3. Work Schedule Planning ..................................................................................8
   15:    3.1 Creating a New Work Schedule Variant ....................................................9
   16:    3.2 Vacation Planning ........................................................................................19
   17:    3.3 Work Schedule Corrections .........................................................................25
   18: 4. Schedule Planning............................................................................................29
   19:    4.1 Creating a Schedule .....................................................................................29
   20:    4.2 Updating a Compiled Schedule....................................................................36
   21:    4.3 Manual Schedule Changes...........................................................................37
   22:    4.4 Applying a Compiled Schedule for the Selected Template ............................47
   23: 
   24: ---
   25: 
   26: ## 1. Multi-skill Planning Template
   27: 
   28: A multi-skill planning template is necessary for creating work schedules for a specific group or list of groups, as well as for schedule planning.
   29: 
   30: To create a multi-skill planning template, navigate to the "Planning" → "Multi-skill Planning" page:
   31: 
   32: ![Multi-skill Planning Navigation](img/multi_skill_planning_navigation.png)
   33: 
   34: When navigating to the "Multi-skill Planning" page, all created multi-skill planning templates are displayed:
   35: 
   36: ![Multi-skill Planning Templates List](img/multi_skill_templates_list.png)
   37: 
   38: To view general information about a template, click on it with the left mouse button. To the right of the template, the following information will be displayed: "Template Name", "Groups":
   39: 
   40: ![Template Information Panel](img/template_info_panel.png)
   41: 
   42: The "Groups" area displays groups included in the multi-skill planning template.
   43: 
   44: ### 1.1 Creating a Multi-skill Planning Template
   45: 
   46: To create a new template, click the "Create Template" button in the left part of the page, after which a form for filling in template data will appear.
   47: 
   48: ![Create Template Form](img/create_template_form.png)
   49: 
   50: In the opened form, enter the template name and click "Save" to save it. After saving, the new multi-skill planning template will appear in the general list of templates.
   51: 
   52: Next, to add groups to the multi-skill planning template, click the "Add" button in the "Groups" window:
   53: 
   54: ![Add Groups Button](img/add_groups_button.png)
   55: 
   56: In the opened dialog box, using the dropdown lists, select the "Service" and "Groups" that will be included in the multi-skill planning template.
   57: 
   58: To confirm adding groups, click "Save" in the dialog box.
   59: 
   60: **Important!** An operator can be in different groups, but only in one multi-skill planning template. Accordingly, one group can only be included in one multi-skill template. If you try to add a group of operators who are already in one of the multi-skill templates to a new template, the system will issue a warning:
   61: 
   62: ![Group Conflict Warning](img/group_conflict_warning.png)
   63: 
   64: This is necessary to exclude discrepancies in schedules (for example, situations when an operator might have several conflicting work schedules or planned vacations).
   65: 
   66: The created multi-skill planning template, after adding groups to it, will be displayed in the "Work Schedule Planning" and "Schedule Creation" sections in the "Templates" block.
   67: 
   68: To rename a template, click on its name, correct it, and click "Save" to save.
   69: 
   70: To remove a group from a template, click "Delete Group" next to it.
   71: 
   72: ### 1.2 Deleting a Multi-skill Planning Template
   73: 
   74: To delete a multi-skill planning template, select the required template from the general list of templates and click the delete button:
   75: 
   76: ![Delete Template Button](img/delete_template_button.png)
   77: 
   78: After clicking the "Delete Template" button, a dialog box with deletion confirmation will appear:
   79: 
   80: ![Delete Confirmation Dialog](img/delete_confirmation_dialog.png)
   81: 
   82: To confirm deletion, click the "Yes" button. A deleted multi-skill planning template cannot be restored.
   83: 
   84: Work schedules planned based on the deleted multi-skill planning template will also be deleted without the possibility of recovery.
   85: 
   86: ## 2. Loading Business Process for Multi-skill Planning Template
   87: 
   88: Business processes loaded into the system allow implementing processes not based on verbal agreements between users – first, employee preferences need to be confirmed, then a schedule compiled, then schedules should be reviewed by department heads, etc. (this is a verbal agreement, as the user might not do all this and simply create a schedule immediately), but in the form of a specific sequence of actions that the system will expect and will not allow proceeding to the next stage of the process until the previous one is completed.
   89: 
   90: The loaded business process (hereinafter BP) stores information about the sequence of actions that need to be followed in the system (specifically the business process sequence), otherwise the system will not allow progress in this BP, as well as which users can perform these BP stages and what actions will be available at certain stages (for example, changing shifts in work schedules is possible not at any BP stage and not every user has the right to change these shifts at a certain stage). But besides needing to load the BP into the system, which stores all necessary information about stages, you also need to somehow manage these stages, delegate tasks to users, etc. This task is performed by the "Tasks for Approval" functionality, which allows executing BP stages, delegating these stages to other employees, or taking them on yourself.
   91: 
   92: To load a BP into the system, you need to navigate to the appropriate page in the system, the link to which is located on the main screen:
   93: 
   94: ![Business Process Upload Link](img/bp_upload_link.png)
   95: 
   96: After opening the page, the following functionality will be displayed:
   97: 
   98: ![Business Process Upload Interface](img/bp_upload_interface.png)
   99: 
  100: Clicking "Browse" will open a file selection window, you need to select a .zip or .rar archive that should contain the business process file. After the file is selected, the remaining buttons will be activated: "Upload" and "Cancel".
  101: 
  102: ![Business Process Upload Active](img/bp_upload_active.png)
  103: 
  104: ## 3. Work Schedule Planning
  105: 
  106: Work schedule planning is carried out based on:
  107: • Forecasted workload
  108: • Operator productivity
  109: • Individual settings
  110: • Labor standards
  111: • Work rules assigned to employees
  112: 
  113: Work schedules are planned for employees who have a position participating in planning and are part of groups included in the "Multi-skill Planning" template selected on the "Work Schedule Planning" page.
  114: 
  115: The "Work Schedule Planning" module is used for mass work schedule planning for employees. On the same-named page, you can view the work schedule planned by the system for employees (eliminating the need to manually assign an operator a schedule based on workload and their preferences), as well as make corrections or accept the schedule as is.
  116: 
  117: During work schedule planning, the employee's hire date and termination date are taken into account. The system will plan shifts for an employee only for the period during which the operator works and will not assign shifts after the termination date or before the hire date. The system also considers the productivity standard assigned to the employee and will try to fit within this standard taking into account hire and termination dates.
  118: 
  119: If in the "Work Rules" reference book, rules have configured variations in shift start times and durations, the system will select the start time and duration of each operator's shift for each day of the year depending on the workload forecast. In this case, the operator's productivity will be maintained. Such schedule planning can take a considerable amount of time. If the multi-skill planning template includes many operators and the rules are configured quite flexibly, consider that this will affect planning time.
  120: 
  121: During schedule planning, you can continue using other system modules, as planning occurs on a separate service.
  122: 
  123: ### 3.1 Creating a New Work Schedule Variant
  124: 
  125: To begin planning a work schedule variant, you need to navigate to the "Work Schedule Planning" page either through the side menu or through the main page:
  126: 
  127: ![Work Schedule Planning Navigation](img/work_schedule_planning_nav.png)
  128: 
  129: ![Work Schedule Planning Main](img/work_schedule_planning_main.png)
  130: 
  131: After opening the page, we will see a list of multi-skill planning templates.
  132: 
  133: To continue creating a work schedule, you need to select one of them, after which we will see a list of work schedule variants, with the current applied work schedule highlighted in bold font and with a checkmark. The applied work schedule is always pinned to the top of the list.
  134: 
  135: Work schedule planning does not depend on the time zone; depending on the selected time zone, only the display changes. By default, the user's time zone is always selected, and there is also the possibility of displaying in other time zones. To do this, you need to change the time zone for displaying work schedules.
  136: 
  137: To start schedule planning, click the "Create" button.
  138: A window will open:
  139: 
  140: ![Schedule Planning Parameters](img/schedule_planning_parameters.png)
  141: 
  142: In the opened window, you need to specify:
  143: • Schedule name
  144: • The "Comment" field is optional for filling
  145: • The "Productivity" field shows what type of productivity is configured in the system (annual, quarterly, monthly)
  146: • The "Work Schedule Planning Year" field allows you to select which year the schedule will be planned for
  147: • If preference consideration was selected during work schedule planning, the system should consider operator preferences that they specified in their personal account
  148: 
  149: After clicking the "Start Planning" button, the schedule name will appear in the "Work Schedule Variants" window, and the planning task will appear in the "Work Schedule Tasks" window. While the schedule is being planned, you can continue working in the system – exit planning, go to other modules, and return.
  150: 
  151: ![Schedule Planning Progress](img/schedule_planning_progress.png)
  152: 
  153: **Work Schedule Variant and Planning Task Statuses:**
  154: 
  155: | Schedule Status | Status Description |
  156: |---|---|
  157: | Planning | There are open tasks for initial planning. A "empty" schedule has been created in WFMCC and a task for creating a new work schedule has been sent to the planning service. |
  158: | Planned | No open tasks for creating or updating schedules, the planning service sends the result to WFMCC. The result is saved in WFMCC. |
  159: | Planning Error | In case planning was done incorrectly. There should be the ability to restart planning. The old task is deleted, a new one is created. |
  160: | Updating | There are open tasks for updating the work schedule. |
  161: | Update Error | All update tasks completed with errors. There should be the ability to delete unsuccessful update tasks. |
  162: 
  163: | Schedule Status | Status Description | Task Type |
  164: |---|---|---|
  165: | Executing | Task is executing or waiting for execution in the planning service. Planning result is not displayable. | Open |
  166: | Awaiting Save | Task completed, result passed to WFMCC and awaits user action. Planning result is displayable. | Open |
  167: | Result Saved | In case the user saved the planning result. Planning result is displayable. | Closed |
  168: | Result Canceled | In case the user canceled saving the planning result. Planning result is not displayable. | Closed |
  169: | Execution Error | In case of planning error or error in passing planning result to WFMCC. Planning result is not displayable. | Open |
  170: 
  171: To check the task status, you need to refresh it. To do this, click the refresh button.
  172: 
  173: If the schedule has been planned, the task status will change to "Awaiting Save":
  174: 
  175: ![Task Awaiting Save](img/task_awaiting_save.png)
  176: 
  177: To proceed to the planned schedule, you need to click on the task itself:
  178: 
  179: ![Select Planning Task](img/select_planning_task.png)
  180: 
  181: After which we will see the system-planned work schedule in the "Planned Work Schedule" area:
  182: 
  183: ![Planned Work Schedule View](img/planned_work_schedule_view.png)
  184: 
  185: Depending on the selected tab ("Org. Structure" or "Func. Structure"), the following areas will be displayed:
  186: 
  187: ![Organizational Structure View](img/org_structure_view.png)
  188: 
  189: ![Functional Structure View](img/func_structure_view.png)
  190: 
  191: In "Org. Structure" we see:
  192: **Department Filter** – allows viewing the schedule for a specific department, as well as all child departments.
  193: 
  194: • **"Operators without planned vacations" checkbox** – Shows operators who have a positive value of remaining vacation days, but no vacation has been assigned
  195: • **"Employees with non-plannable position" checkbox** – shows employees whose position has been changed to not plan
  196: • **"Vacation violations" checkbox** – shows employees who were assigned vacation in violation of vacation assignment rules
  197: • **"Desired vacations" checkbox** – highlights employees' desired vacations with a frame
  198: 
  199: In "Func. Structure we see":
  200: • **Group Filter** – allows viewing the schedule for a specific group
  201: • **"Vacation violations" checkbox** – shows employees who were assigned vacation in violation of vacation assignment rules
  202: • **"Desired vacations" checkbox** – highlights employees' desired vacations with a frame
  203: • **"Op. Forecast" checkbox** – will display the number of forecasted operators per day/month
  204: • **"Op. Plan" checkbox** – will display the number of operators planned by the work schedule per day/month
  205: • **"Op. Plan %Abs" checkbox** – will display the number of operators planned by the work schedule, multiplied by the absence percentage from the "Work Absence Percentage" reference book per day/month
  206: • **"%ACD forecast" checkbox** – shows the average forecasted %ACD value for a 15-minute interval across all groups. Maximum understaffing/overstaffing of employees – shows how many employees are lacking to cover the workload at the busiest time of day and how many employees will be conditionally "excess" at the least busy time of day.
  207: 
  208: ![Monthly Statistics View](img/monthly_statistics_view.png)
  209: 
  210: In monthly and yearly statistics, the same checkboxes that were selected earlier will be displayed. In this case, these are OSS and %ACD for month and year. Values are shown as average values for all days of the month, or for all months of the year.
  211: 
  212: ![Detailed Schedule Information](img/detailed_schedule_info.png)
  213: 
  214: • **Full Name** – employee's surname, first name, and patronymic
  215: • **Work Schedule Template** – work schedule template selected by the system
  216: • **Vacation Scheme** – name of the vacation scheme
  217: • **Standard** – operator's productivity assigned either in the operator's card or in bulk
  218: • **Working Days** – number of operator's working days
  219: • **Planned Hours** – number of working hours for the entire work schedule period excluding unpaid breaks
  220: • **Overtime** – shows the presence of additional hours for employees
  221: • **Remaining Vacation Days** – shows remaining vacation days after assigning all planned vacations to the operator. The vacation days value itself comes through integration. After assigning vacations in the work schedule, the assigned vacation days are subtracted from this value
  222: 
  223: • **Days** – displays days of the month
  224: 
  225: In the information under the days, rows will be displayed for those indicators that were selected by checkboxes in the previous step.
  226: 
  227: **Numbers in cells** – number of working hours in the shift.
  228: 
  229: ![Schedule Cell Details](img/schedule_cell_details.png)
  230: 
  231: In this same table, we can hover the cursor over a cell with working hours and find out what shift was selected for this operator:
  232: 
  233: ![Shift Information Tooltip](img/shift_info_tooltip.png)
  234: 
  235: After reviewing the constructed schedule, click "Save" to save the planned schedule, or "Cancel" to cancel schedule creation.
  236: 
  237: To save the schedule, you need to fill in the schedule name (required parameter) and its description, then click "Apply" to save it, or "Reject" to cancel saving the schedule.
  238: 
  239: ![Save Schedule Dialog](img/save_schedule_dialog.png)
  240: 
  241: After saving, the schedule will be displayed in the list:
  242: 
  243: ![Schedule Saved List](img/schedule_saved_list.png)
  244: 
  245: After the schedule has been saved, depending on the Business Process, the following can be done with it:
  246: • **Update work schedule** – the ability to replan the work schedule for one or several operators will appear, in case they want to change the schedule template according to which shifts were planned for them. In case of setting a termination date for them, or conversely, adding a new employee to an existing work schedule variant (BP for work schedule corrections)
  247: • **Apply** – the work schedule will be applied and become current
  248: 
  249: On the "Work Schedule Planning and Vacations" page, there is also the ability to view all changes made to the work schedule and all stages of BP execution. The history is located under the "Vacation Schedule" block:
  250: 
  251: ![Schedule History View](img/schedule_history_view.png)
  252: 
  253: ![Schedule Change History](img/schedule_change_history.png)
  254: 
  255: ### 3.2 Vacation Planning
  256: 
  257: Vacations that can be assigned to employees are created based on vacation schemes from the "Vacation Schemes" reference book.
  258: 
  259: In the "Vacation Schedule" tab, desired and extraordinary vacations that were set by the operator in their card will be displayed. Also in this tab, you can manually assign vacations, set priorities for them. Vacations set here are considered by the system when building work schedules, after which desired vacations become planned.
  260: 
  261: ![Vacation Planning Interface](img/vacation_planning_interface.png)
  262: 
  263: The top panel displays the following information:
  264: • **Group Filter** – allows viewing a specific group
  265: • **Department Filter** – allows viewing a specific department of employees
  266: • **"Operators with unassigned vacation" checkbox** – will show operators who have remaining vacation days and who have not been assigned desired vacation dates
  267: • **"Operators with accumulated vacation days" checkbox** – will show operators who have accumulated vacation days
  268: • **"Subordinate employees" checkbox** – will display employees who are subordinate to the department head/deputy who is viewing the vacation schedule
  269: • **"Vacation violations" checkbox** – will display operators whose desired vacation was added with violations (accumulated vacation days not considered, incorrect duration – correctness is regulated by labor standards). When hovering the mouse cursor over such vacation (even without the checkbox), the specific violation will be displayed
  270: • **"Desired vacations" checkbox** – will display all desired vacations of operators, hiding extraordinary vacations
  271: • **"Generate vacations" button** – generates vacations for employees who have not been assigned desired vacations. The system is guided by business vacation rules assigned to employees
  272: 
  273: The table columns display the following information:
  274: 
  275: ![Vacation Table Structure](img/vacation_table_structure.png)
  276: 
  277: • **Full Name** – employee's full name
  278: • **Planned Vacation Scheme** – shows the vacation scheme assigned in the operator's card
  279: • **Remaining Vacation Days** – shows remaining vacation days after assigning vacation schedules to the operator. That is, if an operator has 15 vacation days (value comes through integration), then when adding two vacations with a total duration of 14 days, the "remaining vacation days" field will display the number 1.
  280: 
  281: **Adding and Deleting Vacation:**
  282: 
  283: To add vacation in the "Vacation Schedule" tab, you need to select a cell with the left mouse button, then right-click, and then select the "Add Vacation" event from the dropdown menu that appears:
  284: 
  285: ![Add Vacation Context Menu](img/add_vacation_context_menu.png)
  286: 
  287: In the opened dialog box, you need to select the vacation type: "Desired Vacation" or "Extraordinary Vacation".
  288: 
  289: When selecting the "Extraordinary Vacation" type in the dialog box, you need to specify the start date and end date of the vacation.
  290: 
  291: When adding an "Extraordinary Vacation" to an employee, accumulated vacation days are not deducted.
  292: 
  293: ![Extraordinary Vacation Dialog](img/extraordinary_vacation_dialog.png)
  294: 
  295: When selecting the "Desired Vacation" type, you need to select the "Vacation Scheme" and the method of creating vacation: "Period" or "Calendar Days".
  296: 
  297: If the "Period" vacation creation method is selected, then:
  298: • You need to specify the start date and end date of the vacation
  299: • The vacation does not shift if holidays fall within its period (for example, vacation is set from 25.04 to 08.05. Despite the fact that one holiday falls in this period: "May 1", the vacation does not shift. Work return date is 09.05)
  300: • The number of days is deducted from accumulated vacation days considering holidays (for example, vacation is set for 14 days, with one holiday falling in its period. 13 days are deducted from accumulated days, not 14)
  301: 
  302: If the "Calendar Days" vacation creation method is selected, then:
  303: • You need to specify the vacation start date and number of vacation days (vacation end date will be pulled automatically)
  304: • Vacation shifts by the number of holidays (for example, vacation is set for 14 calendar days from 25.04 to 08.05. One holiday falls in this period "May 1", so the vacation shifts to 09.05. But "May 9" is also a holiday, so the vacation shifts again. Work return date: 11.05)
  305: • The number of days is deducted from accumulated vacation days without considering holidays (in the example above, 14 vacation days will be deducted from accumulated days)
  306: 
  307: ![Desired Vacation Dialog](img/desired_vacation_dialog.png)
  308: 
  309: The vacation addition functionality is similar to adding vacation in the client card.
  310: 
  311: To delete vacation, just right-click on one of the cells in the range of the needed vacation and select "Delete Vacation":
  312: 
  313: ![Delete Vacation Context Menu](img/delete_vacation_context_menu.png)
  314: 
  315: **Vacation Priorities:** vacations have priorities, they are considered during work schedule planning. Priority works as follows: during work schedule planning, the system relies on forecasted workload and personal business vacation rules for the operator when setting vacations.
  316: 
  317: The operator is assigned the maximum number of vacation shift days. Based on this setting, the system can shift vacation within this range to cover workload (for example, an operator wanted to go on vacation on 5.01, but heavy workload is recorded on this day. In this case, the system can shift the operator's vacation by the number of days not exceeding that specified in the operator's card for vacation shift days). If vacation is considered priority, the system will first move (if necessary) non-priority vacations, and only then (if required) will move **priority** vacations to cover workload. If vacation is considered **fixed**, the system does not move it regardless of workload.
  318: 
  319: To make vacation priority, you need to select the vacation of interest by clicking on any cell of its interval with the right mouse button and select "Vacation Priority":
  320: 
  321: ![Set Vacation Priority](img/set_vacation_priority.png)
  322: 
  323: To cancel vacation priority, you need to select it as shown above and click "Non-priority Vacation":
  324: 
  325: ![Cancel Vacation Priority](img/cancel_vacation_priority.png)
  326: 
  327: To fix vacation, you need to select it as shown earlier and click "Fixed Vacation":
  328: 
  329: ![Set Fixed Vacation](img/set_fixed_vacation.png)
  330: 
  331: ![Fixed Vacation Display](img/fixed_vacation_display.png)
  332: 
  333: The vacations set above are considered desired. As soon as a work schedule is planned or updated, the system will automatically arrange vacations, considering business rules and workload, after which such vacations become planned.
  334: 
  335: ### 3.3 Work Schedule Corrections
  336: 
  337: In the Work Schedule Correction module, the user can change the applied work schedule without creating copies of the applied work schedule, and changes will immediately be displayed to the operator and take effect.
  338: 
  339: On the Work Schedule Corrections page, you can:
  340: • Change shift duration (shifts can be extended or shortened)
  341: • Move a shift
  342: • Delete a shift
  343: • Create a new shift
  344: • Create, delete, or edit sick leave
  345: • Create, delete, or edit time off
  346: • Create, delete, or edit vacation
  347: 
  348: To navigate to the work schedule corrections page, you need to open the side menu, then the "Planning" module → "Work Schedule Corrections".
  349: 
  350: ![Work Schedule Corrections Navigation](img/work_schedule_corrections_nav.png)
  351: 
  352: Upon reaching the page, you will see sections: "Legend", "Filters", "Statistics". And work schedules of all employees in the system.
  353: 
  354: In the "Legend" section, conditional designations of the schedule are displayed:
  355: 
  356: ![Schedule Legend](img/schedule_legend.png)
  357: 
  358: In the "Filters" section, you can sort employees for display on the schedule by:
  359: • Departments
  360: • Sites
  361: • Groups
  362: • Subordinate employees
  363: • Only with existing schedule
  364: 
  365: You can also find individual employees by full name or personnel number.
  366: 
  367: In the "Statistics" section, detailed information about surplus or deficit of planned operators in accordance with workload is displayed. On the histogram, red color indicates deficits, blue indicates surpluses, green color – plan, values are displayed according to the number of operators.
  368: 
  369: **Important!** Statistics will not be displayed if no group is selected in filters.
  370: 
  371: ![Statistics Histogram](img/statistics_histogram.png)
  372: 
  373: The histogram can be scaled using the mouse wheel and moved by holding the left mouse button.
  374: 
  375: On the schedule itself, in the left part, employees and their planned and planned productivity without unpaid breaks are listed. In the main part of the schedule, employee shifts are displayed; by selecting a shift, you can delete it by clicking the "Cross" button (✖).
  376: 
  377: ![Schedule Main View](img/schedule_main_view.png)
  378: 
  379: To set a new shift, double-click the left mouse button on the employee's schedule line you want to set a shift for. A shift setup window will open where you can set: shift type (planned/additional), shift time, overtime hours before or after the shift. Then click the "Checkmark" button (✓). Additional shifts or overtime hours cannot be set if the operator's productivity standard is not covered.
  380: 
  381: ![New Shift Setup](img/new_shift_setup.png)
  382: 
  383: To add an event to an operator, you need to double-click the left mouse button on the employee's schedule you want to set a shift for. In the opened window, in the type field, select events, configure the event type (sick leave/time off/planned vacation/extraordinary vacation) and set the start and end time of the shift, then click the "Checkmark" button (✓).
  384: 
  385: ![Add Event Dialog](img/add_event_dialog.png)
  386: 
  387: The schedule can be scaled by day, week, or month, display the current day by clicking the "Today" button, or specify the required date. You can also select the time zone in which the schedule will be displayed.
  388: 
  389: ![Schedule Scaling Options](img/schedule_scaling_options.png)
  390: 
  391: All changes made are saved automatically and applied to the current applied work schedule.
  392: 
  393: ## 4. Schedule Planning
  394: 
  395: Operator schedule planning is carried out in accordance with forecasted workload, operator work schedules, and lunch and break rules.
  396: 
  397: **Important!** Planning is impossible without forecast and active work schedules.
  398: 
  399: ### 4.1 Creating a Schedule
  400: 
  401: The "Schedule Creation" module allows creating operator work schedules in accordance with forecasted workload, office operator work schedules, and home operator work preferences.
  402: 
  403: **Prerequisites for schedule creation:**
  404: • Multi-skill planning template created
  405: • Forecasted workload updated for a specific period for the selected group
  406: • Applied work and vacation schedule exists
  407: 
  408: To navigate to the schedule creation page, go to the "Planning" tab → "Schedule Creation" (you can navigate from the menu with the list of sections or from the main page by clicking the "Schedule Creation" block):
  409: 
  410: ![Schedule Creation Navigation](img/schedule_creation_nav.png)
  411: 
  412: Next, in the area with the list of schedule templates, select the required template and click the "Create" button in the "Schedule" block:
  413: 
  414: ![Schedule Template Selection](img/schedule_template_selection.png)
  415: 
  416: **Note:** if a multi-skill template is selected that includes an aggregated group, then workload will be pulled from the aggregated group, and employees will be pulled from simple groups included in the aggregated one.
  417: 
  418: **Important!** Schedule planning does not depend on time zone; depending on the selected time zone, only the display changes. By default, the user's time zone is always selected, and there is also the possibility of displaying in other time zones. To do this, you need to change the time zone for displaying schedules.
  419: 
  420: In the opened "Schedule Planning" dialog box, specify the period of action of the created schedule and one of the planning criteria (configured in the Planning – Planning Criteria section):
  421: 
  422: ![Schedule Planning Dialog](img/schedule_planning_dialog.png)
  423: 
  424: After the parameters are selected, click the "Start Planning" button. After this, a planning task will appear in the schedule tasks in the "Executing" status. The task can be canceled or its execution checked by updating the status.
  425: 
  426: ![Schedule Planning Task](img/schedule_planning_task.png)
  427: 
  428: **Note:** in case of attempting to build a schedule for a template that has groups for which forecasts were not previously obtained, the system will issue an error:
  429: 
  430: ![Forecast Error Message](img/forecast_error_message.png)
  431: 
  432: In this case, the user needs to obtain a forecast and then retry building the schedule.
  433: 
  434: The generated schedule will look as follows:
  435: 
  436: ![Generated Schedule View](img/generated_schedule_view.png)
  437: 
  438: By setting checkboxes in the "Filters" area, you can sort the employee list:
  439: 
  440: ![Schedule Filters](img/schedule_filters.png)
  441: 
  442: • **Subordinate operators** – will display a list of employees who are in the department managed or deputized by the user
  443: • **Home** – will display a list of operators who have a mark in their card that they are home operators
  444: • **Office** – will display a list of operators who have a mark in their card that they are office operators
  445: • **Skills** – employee display depending on skill (novice/average/champion) and English language knowledge
  446: • **Vacation** – will display a list of operators who are on vacation during the current schedule period
  447: • **Sick Leave** – will display a list of operators who are on sick leave during the current schedule period
  448: • **Time Off** – will display a list of operators who took time off during the current schedule period
  449: 
  450: Next, statistics on created events are displayed. It is shown including for schedules that fall within the event action period:
  451: 
  452: ![Event Statistics](img/event_statistics.png)
  453: 
  454: • **Project** – displays the project name assigned in this schedule (and others)
  455: • **Start Date and End Date** – project dates
  456: • **Segment Requirement** – number of intervals needed to cover the workload required by the event
  457: • **Total Segments Assigned** – displays how many intervals were allocated for the project. This field shows statistics for all current schedules created during the event period
  458: • **Segments Assigned in Schedule** – this statistic shows how many intervals were allocated for the project specifically in the schedule being reviewed
  459: 
  460: In the "by employees" schedule view mode, a list of all employees is displayed.
  461: 
  462: ![Employee Schedule View](img/employee_schedule_view.png)
  463: 
  464: In the view mode for a specific group (by direction), only the operators of this group are displayed.
  465: 
  466: Additionally specified:
  467: • Service level
  468: • Forecasted number of operators
  469: • Actual number of operators
  470: 
  471: ![Group Schedule Details](img/group_schedule_details.png)
  472: 
  473: In the figure, we see that the table cell rows are colored according to the legend:
  474: 
  475: ![Schedule Color Legend](img/schedule_color_legend.png)
  476: 
  477: ![Schedule Color Example](img/schedule_color_example.png)
  478: 
  479: If the forecasted number of operators is greater than the actual (in other words, there will not be enough operators on the line at some point according to the forecast), then according to the legend, the "forecast" and "actual" rows are colored red.
  480: 
  481: If the forecasted number of operators is less than the actual (in other words, there will be an excess of operators on the line at some point), then according to the legend, the "forecast" and "actual" rows are colored purple.
  482: 
  483: If the employee who compiled the schedule is satisfied with the created schedule, it needs to be saved. To do this, click the "Save" button. Then a dialog box will open where you need to specify the schedule name and give it a brief description. For final saving, click the save button:
  484: 
  485: ![Save Schedule Final](img/save_schedule_final.png)
  486: 
  487: To cancel the schedule, click the "Cancel" button.
  488: 
  489: ### 4.2 Updating a Compiled Schedule
  490: 
  491: **Important!** Before updating the schedule, don't forget to save it first.
  492: 
  493: The schedule update function allows updating a previously created schedule considering updated workload, employee special events, manual schedule corrections, employee work schedule changes, employee deactivation, new employee creation.
  494: 
  495: To update a schedule, first select a template in the left part, then select a saved schedule for this template (in the "Schedule Variants" area) and then click the "Update" button:
  496: 
  497: ![Update Schedule Button](img/update_schedule_button.png)
  498: 
  499: The "Schedule Planning" form will open. Specify the planning period you want to update:
  500: 
  501: ![Update Schedule Form](img/update_schedule_form.png)
  502: 
  503: After the parameters are selected, click the "Start Planning" button. After updating the schedule, it needs to be saved. When saving, you can change the name and comment.
  504: 
  505: ![Save Updated Schedule](img/save_updated_schedule.png)
  506: 
  507: ### 4.3 Manual Schedule Changes
  508: 
  509: For a created schedule in the "ARGUS WFM CC" system, there is the possibility of manual correction of operator work intervals:
  510: • Adding/removing lunches and breaks
  511: • Registering downtime
  512: • Call/cancel call to work
  513: • Adding/canceling work attendance
  514: • Project assignment
  515: • Adding/canceling events
  516: 
  517: **Important!** A user can edit a schedule under the following conditions:
  518: • If the user is a manager of the parent department (and has editing rights), they can edit schedules of both subordinate operators and operators from child departments
  519: • If the user is a manager of a child department (and has editing rights), they can only edit schedules of employees subordinate to them
  520: • If the user is a deputy of the parent department (and has editing rights), they can edit schedules of both subordinate operators and operators from child departments. The day when corrections are made must fall within the deputy period
  521: • If the user is a deputy of a child department (and has editing rights), they can only edit schedules of employees subordinate to them. The day when corrections are made must fall within the deputy period
  522: • If the user is not a manager or deputy but has editing rights, they can edit schedules of all operators
  523: 
  524: On the "Planning" → "Schedule Creation" page, select a schedule from the list. In the "Schedule" block, select the required day and employee time interval:
  525: 
  526: ![Manual Schedule Edit](img/manual_schedule_edit.png)
  527: 
  528: Time in the schedule is divided into 5-minute intervals. To select one 5-minute interval, click on it with the left mouse button:
  529: 
  530: ![Select Time Interval](img/select_time_interval.png)
  531: 
  532: Using the held "Ctrl" button, you can select different 5-minute intervals for different employees:
  533: 
  534: ![Multiple Interval Selection](img/multiple_interval_selection.png)
  535: 
  536: The system also allows selecting an entire area. To do this, click the left mouse button and without releasing it, select the area:
  537: 
  538: ![Area Selection](img/area_selection.png)
  539: 
  540: After the time interval is selected, call the menu by right-clicking and select one of the events:
  541: 
  542: ![Context Menu Events](img/context_menu_events.png)
  543: 
  544: **Adding/Removing Lunches and Breaks**
  545: 
  546: Lunches/breaks can be added and removed in case the operator's shift duration was changed to one for which there are no lunch/break rules in the "Lunches/Breaks" reference book. In other cases, the system will not allow adding and removing lunches and breaks.
  547: 
  548: To add lunch or break, select the needed cells and choose "Add Lunch" or "Add Break":
  549: 
  550: ![Add Lunch Break](img/add_lunch_break.png)
  551: 
  552: ![Lunch Break Added](img/lunch_break_added.png)
  553: 
  554: To remove lunch or break, select the needed cells and choose "Cancel Breaks":
  555: 
  556: ![Cancel Breaks](img/cancel_breaks.png)
  557: 
  558: **Registering Downtime**
  559: 
  560: To register downtime for an employee, select the needed cells and choose "Does not accept calls":
  561: 
  562: ![Register Downtime](img/register_downtime.png)
  563: 
  564: ![Downtime Registered](img/downtime_registered.png)
  565: 
  566: **Adding/Canceling Work Attendance**
  567: 
  568: To register non-working time for an employee, select the needed cells and choose "Non-working time":
  569: 
  570: ![Non Working Time](img/non_working_time.png)
  571: 
  572: ![Non Working Time Set](img/non_working_time_set.png)
  573: 
  574: To add work attendance for an employee, you need to switch display to a specific project:
  575: 
  576: ![Project Display Switch](img/project_display_switch.png)
  577: 
  578: Then select the needed cells and choose "Add work attendance":
  579: 
  580: ![Add Work Attendance](img/add_work_attendance.png)
  581: 
  582: ![Work Attendance Added](img/work_attendance_added.png)
  583: 
  584: **Project Assignment**
  585: 
  586: To assign an employee to a specific project, you need to switch display to a specific project, select the needed cells, and choose "Assign to project":
  587: 
  588: ![Assign To Project](img/assign_to_project.png)
  589: 
  590: ![Project Assignment Complete](img/project_assignment_complete.png)
  591: 
  592: In this case, regardless of how much the employee is involved in other projects, they will be 100% engaged in the current project.
  593: 
  594: **Adding/Canceling Events**
  595: 
  596: To add an event to an operator, select "Event", then a dialog box will open:
  597: 
  598: ![Add Event Dialog Box](img/add_event_dialog_box.png)
  599: 
  600: In which you need to select the event type (Training/Meeting/Calls/Survey collection), specifically the event from the "Events" reference book. The time and participant are selected automatically since their interval was already selected earlier. After which you need to click the checkmark to add the event.
  601: 
  602: ![Event Added](img/event_added.png)
  603: 
  604: To cancel an event, you need to select the event of interest and click "Cancel Event".
  605: 
  606: ### 4.4 Applying a Compiled Schedule for the Selected Template
  607: 
  608: When a schedule is successfully compiled and meets planning criteria, it can be accepted as the active working schedule. To do this, you need to apply the selected schedule for the template. After applying the schedule, it will be available for viewing in the "Current Schedule" section.
  609: 
  610: For the selected template in the "Schedule Variants" block, select the appropriate schedule variant and click "Apply":
  611: 
  612: ![Apply Schedule](img/apply_schedule.png)
  613: 
  614: In the "Schedule Creation" section, the applied schedule is highlighted in bold in the block with the list of schedule variants:
  615: 
  616: ![Applied Schedule Highlighted](img/applied_schedule_highlighted.png)
  617: 
  618: In case of schedule overlap (when there is already a current schedule created earlier), when clicking the "Apply" button, the system will display a warning message:
  619: 
  620: ![Schedule Overlap Warning](img/schedule_overlap_warning.png)
  621: 
  622: **Confirm** – by clicking this button, the senior operator confirms overwriting the previous current schedule (overlapping dates will be overwritten)
  623: 
  624: **Cancel** – by clicking this button, the senior operator cancels applying the new schedule.
  625: 
  626: ---
  627: 
  628: *This completes the ARGUS WFM CC Planning Module documentation.*