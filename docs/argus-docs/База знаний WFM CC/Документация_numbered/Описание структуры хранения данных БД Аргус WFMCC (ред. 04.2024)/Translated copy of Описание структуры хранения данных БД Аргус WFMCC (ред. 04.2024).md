    1: 
    2: 
    3: ## **Table system.absent\_reason**
    4: 
    5: Reasons for absence
    6: 
    7: | Serial number | Designation | Data type | Description |
    8: | ----- | ----- | ----- | ----- |
    9: | 1 | id | bigint |  |
   10: | 2 | name | text | Status |
   11: | 3 | description | text | Description |
   12: | 4 | status | text | Status records |
   13: | 5 | use\_in\_absenteeism\_report | boolean | \- |
   14: 
   15: 	
   16: 
   17: ## **Table system.absenteeism**
   18: 
   19: Handbook "Percentage of Absenteeism"
   20: 
   21: | Serial number | Designation | Data type | Description |
   22: | ----- | ----- | ----- | ----- |
   23: | 1 | id | bigint |  |
   24: | 2 | period | int8range | The period for which the absence percentage applies |
   25: | 3 | abs | double precision | percentage of absence |
   26: 
   27: ## **Table system.actual\_load\_interval**
   28: 
   29: Actual load data for a specific time interval
   30: 
   31: | Serial number | Designation | Data type | Description |
   32: | ----- | ----- | ----- | ----- |
   33: | 1 | id | bigint | Unique identifier |
   34: | 2 | start\_timestamp | timestamp with time zone | Beginning of the period |
   35: | 3 | end\_timestamp | timestamp with time zone | End of the period |
   36: | 4 | call\_number | integer | Number of calls |
   37: | 5 | operator\_number | integer | Number of operators |
   38: | 6 | average\_call\_duration | integer | Average call handling time |
   39: | 7 | service\_level | integer | Quality of service |
   40: | 8 | required\_operator\_number | integer | How many operators are needed to maintain the required service level? |
   41: | 9 | forecast\_start | timestamp with time zone | Time to call getOnlineLoad method |
   42: | 10 | service\_id | bigint | Service ID |
   43: | 11 | group\_id | bigint | Group ID |
   44: | 12 | bkp$\_start\_timestamp | timestamp without time zone | \- |
   45: | 13 | bkp$\_end\_timestamp | timestamp without time zone | \- |
   46: | 14 | bkp$\_forecast\_start | timestamp without time zone | \- |
   47: 
   48: ## **Table system.area**
   49: 
   50: Sites
   51: 
   52: | Serial number | Designation | Data type | Description |
   53: | ----- | ----- | ----- | ----- |
   54: | 1 | id | bigint | Unique identifier of the site its name |
   55: | 2 | foreign\_id | character varying | \- |
   56: | 3 | status | character varying | Status |
   57: 
   58: 		
   59: 
   60: ## **Table system.business\_event**
   61: 
   62: The fact of the event
   63: 
   64: | Serial number | Designation | Data type | Description |
   65: | ----- | ----- | ----- | ----- |
   66: | 1 | id | bigint | Unique event identifier |
   67: | 2 | event\_template\_id | bigint | The template from which the event was created |
   68: | 3 | start\_timestamp | timestamp with time zone | Current start time of the event |
   69: | 4 | end\_timestamp | timestamp with time zone | Current end time of the event |
   70: | 5 | create\_timestamp | timestamp with time zone | Event creation time |
   71: | 6 | author\_id | bigint | The operator who created the event |
   72: | 7  | bkp$\_start\_timestamp | timestamp without time zone | \- |
   73: | 8  | bkp$\_end\_timestamp | timestamp without time zone | \- |
   74: | 9  | bkp$\_create\_timestamp | timestamp without time zone | \- |
   75: 
   76: ## **Table system.call\_number\_vw**
   77: 
   78: Historical data on the number of calls received
   79: 
   80: | Serial number | Designation | Data type | Description |
   81: | ----- | ----- | ----- | ----- |
   82: | 1 | group\_id | bigint | Group ID |
   83: | 2 | group\_name | character varying | Group name |
   84: | 3 | start\_timestamp | timestamp with time zone | Start time moment |
   85: | 4 | end\_timestamp | timestamp with time zone | End time moment |
   86: | 5 | historic\_call\_number | integer | Number of historical calls |
   87: | 6 | not\_unique\_received | integer | Non-unique accepted |
   88: | 7 | not\_unique\_treated | integer | Non-unique lost |
   89: | 8 | not\_unique\_missed | integer | Non-unique ones are omitted |
   90: | 9 | unique\_recieved | integer | Unique accepted |
   91: | 10 | miss\_call | integer | Missed calls |
   92: 
   93: ## **Table system.contact**
   94: 
   95: Contact of employee/client/group etc.
   96: 
   97: | Serial number | Designation | Data type | Description |
   98: | ----- | ----- | ----- | ----- |
   99: | 1  | id | bigint | Unique contact identifier |
  100: | 2  | contact\_type | character varying | Contact type |
  101: | 3  | text\_value | character varying | Text value of contact |
  102: | 4  | description | character varying | Free text description of the contact |
  103: | 5  | is\_main | boolean | Is the contact the primary one among others of the same type? |
  104: 
  105: ## **Table system.customer\_config\_item**
  106: 
  107: Customer configuration
  108: 
  109: | Serial number | Designation | Data type | Description |
  110: | ----- | ----- | ----- | ----- |
  111: | 1  | param | character varying | Configuration parameter name |
  112: | 2  | value | character varying | Text value of the parameter |
  113: 
  114: ## **system.department table**
  115: 
  116: Directory of departments
  117: 
  118: | Serial number | Designation | Data type | Description |
  119: | ----- | ----- | ----- | ----- |
  120: | 1  | id | bigint | ID records |
  121: | 2  | parent\_id | bigint | Parent unit |
  122: | 3  | name | text | Name of the department |
  123: | 4  | uid | text | external system identifier |
  124: | 5  | status | character varying | Unit status |
  125: 
  126: ## **Table system.department\_chief**
  127: 
  128: Table for storing department heads
  129: 
  130: | Serial number | Designation | Data type | Description |
  131: | ----- | ----- | ----- | ----- |
  132: | 1  | department\_id | bigint | Record IDs |
  133: | 2  | worker\_id | bigint | ID worker a \- he is also the head/deputy of the department |
  134: | 3  | valid\_from | date | Start date of substitution |
  135: | 4  | valid\_to | date | End date of substitution |
  136: | 5  | role | character varying | The role of the leader |
  137: | 6  | bkp$\_valid\_from | timestamp without time zone | \- |
  138: | 7  | bkp$\_valid\_to | timestamp without time zone | \- |
  139: 
  140: ## **Table system.desired\_schedule\_vw**
  141: 
  142: Preferred Operator Work Schedule Template
  143: 
  144: | Serial number | Designation | Data type | Description |
  145: | ----- | ----- | ----- | ----- |
  146: | 1 | worker\_id | bigint | Employee ID |
  147: | 2 | first\_name | character varying | Name |
  148: | 3 | second\_name | character varying | Surname |
  149: | 4 | last\_name | character varying | Family name |
  150: | 5 | department\_name | text | Name of the department |
  151: | 6 | status | character varying | Status |
  152: | 7 | operator\_type | character varying | Operator type |
  153: | 8 | desired\_work\_schedule | character varying | Preferred work schedule |
  154: | 9 | is\_priority | boolean | is\_priority |
  155: 
  156: ## **Table system.dirty\_context**
  157: 
  158: For dirty purposes (to make context dirty)
  159: 
  160: | Serial number | Designation | Data type | Description |
  161: | ----- | ----- | ----- | ----- |
  162: | 1  | id | bigint | \- |
  163: 
  164: ## **Table system.employment\_rate**
  165: 
  166: Directory Percentage of Employment
  167: 
  168: | Serial number | Designation | Data type | Description |
  169: | ----- | ----- | ----- | ----- |
  170: | 1  | id | bigint | Unique identifier |
  171: | 2  | percent | double precision | Employment percentage |
  172: | 3  | month | integer | Month number 1..12 |
  173: 
  174: ## **Table system.employment\_rate\_group**
  175: 
  176: Denouement reference: employment percentage-group
  177: 
  178: | Serial number | Designation | Data type | Description |
  179: | ----- | ----- | ----- | ----- |
  180: | 1  | employment\_rate\_id | bigint | Directory entry identifier |
  181: | 2  | group\_id | bigint | Group ID |
  182: 
  183: ## **Table system.entity\_package**
  184: 
  185: Contains a list of all currently deployed system modules
  186: 
  187: | Serial number | Designation | Data type | Description |
  188: | :---- | :---- | :---- | :---- |
  189: | 1  | entity\_package\_id | bigint | Unique module identifier, defined by developers |
  190: | 2  | entity\_package\_name | character varying | System name of the module |
  191: | 3  | package\_desc | character varying | User-friendly description of the module |
  192: | 4  | scheme\_name | character varying | The name of the schema containing the data structures for the current module |
  193: | 5  | depends\_on\_entity\_package\_id | bigint | A reference to a module that the current module depends on |
  194: | 6  | is\_sys | boolean | TRUE if system. System package is always deployed, not a shipping option. |
  195: | 7  | appserver\_project | character varying | The project in the appserver repository that contains the implementation of this module. If null, this module has no implementation on the appserver. If the implementation in appserver is inseparable from the parent implementation (depends\_on), then the name of the parent appserver\_project should be specified. Note: usually one java-project is specified, although there is a project and a project-ui in appserver |
  196: 
  197: ## **Table system.event\_template**
  198: 
  199: Mass Event Template
  200: 
  201: | Serial number | Designation | Data type | Description |
  202: | ----- | ----- | ----- | ----- |
  203: | 1 | id | bigint | Unique template identifier |
  204: | 2 | type | character varying | Type of event (training, meeting, etc.) |
  205: | 3 | name | character varying | Event Title |
  206: | 4 | description | character varying | Description of the event |
  207: | 5 | period\_type | character varying | Frequency of the event (daily/weekly/monthly) |
  208: | 6 | min\_workers | integer | Minimum number of participants for the event |
  209: | 7 | max\_workers | integer | Maximum number of event participants |
  210: | 8 | my\_start | time without time zone | Minimum event start time (in ms from the start of the day) |
  211: | 9 | max\_end | time without time zone | Maximum event end time (in ms from the start of the day) |
  212: | 10 | duration | bigint | Event duration in milliseconds |
  213: | 11 | week\_days | character varying | Days of the week on which the event can be held |
  214: | 12 | max\_simultaneous | integer | Maximum number of events that can be held simultaneously (are overlaps possible) |
  215: | 13 | status | character varying | Template Status |
  216: | 14 | start\_timestamp | timestamp with time zone | Event start time |
  217: | 15 | end\_timestamp | timestamp with time zone | Event end time |
  218: | 16 | work\_plan | bigint | Work plan. calls/questionnaires |
  219: | 17 | aht | bigint | Average processing time |
  220: | 18 | occ | bigint | Operators' Employment |
  221: | 19 | dtype | text | Event Type(EventTemplate, ProjectEventTemplate) |
  222: | 20 | project\_event\_mode | character varying | Project mode (load priority) |
  223: | 21 | priority | integer | Project Priority |
  224: | 22 | bkp$\_start\_timestamp | timestamp without time zone | \- |
  225: | 23 | bkp$\_end\_timestamp | timestamp without time zone | \- |
  226: | 24 | bkp$\_my\_start | bigint | \- |
  227: | 25 | bkp$\_max\_end | bigint | \- |
  228: | 26 | time\_zone | character varying | \- |
  229: | 27 | is\_combine\_events | boolean | Combine with other activities during the day |
  230: | 28 | valid\_from | timestamp without time zone | Local date-time of the start of the event period |
  231: | 29 | valid\_to | timestamp without time zone | Local date-time of the end of the event period (exclusive) |
  232: 
  233: ## **Table system.event\_template\_group**
  234: 
  235: Possible participant of the event
  236: 
  237: | Serial number | Designation | Data type | Description |
  238: | ----- | ----- | ----- | ----- |
  239: | 1  | event\_template\_id | bigint | Event template |
  240: | 2  | group\_id | bigint | Group \- a possible participant of the event |
  241: 
  242: ## **Table system.event\_template\_worker**
  243: 
  244: Possible participant of the event
  245: 
  246: | Serial number | Designation | Data type | Description |
  247: | ----- | ----- | ----- | ----- |
  248: | 1  | event\_template\_id | bigint | Event template |
  249: | 2  | worker\_id | bigint | Operator \- a possible participant in the event |
  250: 
  251: ## **The system.event\_type table**
  252: 
  253: Table of types of events that can occur in the system.
  254: 
  255: | Serial number | Designation | Data type | Description |
  256: | ----- | ----- | ----- | ----- |
  257: | 1  | id | bigint | Identifier |
  258: | 2  | keyword | character varying | Unique key for the event type. |
  259: | 3  | name | character varying | Category name. |
  260: | 4  | category | character varying | Event category. |
  261: | 5  | default\_message\_template | character varying | The template for the notification that will be used by default. |
  262: | 6  | specific\_properties | character varying | A list of specific parameters that can be used in a message template. |
  263: | 7  | business\_critical | boolean | Whether delivery of a notification of this type is business critical. |
  264: | 8  | version | bigint | The version of the record, incremented when changed. |
  265: 
  266: ## **Table system.forecast\_interval**
  267: 
  268: Forecast for a specific time interval
  269: 
  270: | Serial number | Designation | Data type | Description |
  271: | ----- | ----- | ----- | ----- |
  272: | 1  | start\_timestamp | timestamp with time zone | Home forecast |
  273: | 2  | end\_timestamp | timestamp with time zone | End of prediction |
  274: | 3  | call\_number | double precision | Number of calls |
  275: | 4  | operator\_number | double precision | Number of operators |
  276: | 5  | call\_number\_coefficient | real | Growth rate |
  277: | 6  | operator\_number\_coefficient | real | Safety factor |
  278: | 7  | required\_operator\_number | double precision | Required number of operators |
  279: | 8  | min\_count\_operators | double precision | Minimum number of operators |
  280: | 9  | forecast\_special\_event\_id | bigint | Special event that the interval falls on |
  281: | 10  | actual\_service\_level | integer | service level on the interval |
  282: | 11  | actual\_occupancy | double precision | operator workload level on the interval |
  283: | 12  | avg\_handling\_time | integer | Average processing time |
  284: | 13  | service\_id | bigint | link to service |
  285: | 14  | group\_id | bigint | link to the group |
  286: | 15  | service\_level | integer | maximum service level (SLA) |
  287: | 16  | min\_service\_level | integer | minimum service level agreement (SLA) |
  288: | 17  | avg\_waiting\_time | integer | call waiting time |
  289: | 18  | acd | integer | Percentage of calls on which operators are calculated |
  290: | 19  | absenteeism\_coefficient | real | Absence rate |
  291: | 20  | parallel\_requests | integer | Simultaneously processed requests (for calls 1\) |
  292: | 21  | bkp$\_start\_timestamp | timestamp without time zone | \- |
  293: | 22  | bkp$\_end\_timestamp | timestamp without time zone | \- |
  294: 
  295: ## **Table system.forecast\_special\_event**
  296: 
  297: Special Events Directory
  298: 
  299: | Serial number | Designation | Data type | Description |
  300: | ----- | ----- | ----- | ----- |
  301: | 1  | id | bigint | ID records |
  302: | 2  | start\_time | timestamp with time zone | Special event start time |
  303: | 3  | end\_time | timestamp with time zone | Special event end time |
  304: | 4  | name | character varying | Name of special event |
  305: | 5  | description | character varying | Description of a special event |
  306: | 6  | coefficient | real | Event coefficient |
  307: | 7  | version | bigint | Version |
  308: | 8  | status | character varying | Status |
  309: | 9  | bkp$\_start\_time | timestamp without time zone | \- |
  310: | 10  | bkp$\_end\_time | timestamp without time zone | \- |
  311: 
  312: ## **Table system.forecast\_special\_event\_service\_group**
  313: 
  314: Possible participants of the special event
  315: 
  316: | Serial number | Designation | Data type | Description |
  317: | ----- | ----- | ----- | ----- |
  318: | 1  | forecast\_special\_event\_id | bigint | Special event ID from forecast\_sepcial\_event |
  319: | 2  | service\_id | bigint | Service ID |
  320: | 3  | group\_id | bigint | Group ID |
  321: 
  322: ## **Talitsa system.forecast\_vw**
  323: 
  324: \-
  325: 
  326: | Serial number | Designation | Data type | Description |
  327: | ----- | ----- | ----- | ----- |
  328: | 1 | group\_name | character varying | \- |
  329: | 2 | start\_timestamp | timestamp with time zone | \- |
  330: | 3 | end\_timestamp | timestamp with time zone | \- |
  331: | 4 | forecast\_call\_number | double precision | \- |
  332: | 5 | aht | integer | \- |
  333: | 6 | absenteeism\_coefficient | real | \- |
  334: | 7 | forecast\_operator\_number | double precision | \- |
  335: | 8 | call\_number\_coefficient | real | \- |
  336: 
  337: ## **Table system.group\_l**
  338: 
  339: A group of call center employees who share some common characteristic, such as occupation
  340: 
  341: | Serial number | Designation | Data type | Description |
  342: | :---- | :---- | :---- | :---- |
  343: | 1  | id | bigint | Unique group identifier |
  344: | 2  | name | character varying | Group name |
  345: | 3  | description | character varying | Group Description |
  346: | 4  | foreign\_id | text | External system identifier for integration |
  347: | 5  | status | character varying | Status |
  348: | 6  | version | bigint | Version |
  349: | 7  | config\_string | character varying | Configuration of forecasting parameters (which are then pulled into the forecasting module when forecasting the required quantity |
  350: | 8  | system\_id | integer | Integrated system |
  351: | 9  | type | character varying | Group type |
  352: | 10  | parent\_id | bigint | Parent group |
  353: | 11  | monitoring\_config | text | \- |
  354: | 12  | priority | integer | \- |
  355: | 13 | analysis\_mode | character varying | \- |
  356: 
  357: ## **Table sandstem.group\_worker**
  358: 
  359: Group-employee denouement
  360: 
  361: | Serial number | Designation | Data type | Description |
  362: | :---- | :---- | :---- | :---- |
  363: | 1 | id | bigint | Idishnik bundles |
  364: | 2 | group\_id | bigint | The group the employee belongs to |
  365: | 3 | worker\_id | bigint | An employee who is part of a group |
  366: | 4 | priority | integer | Priority of employee entry into the group |
  367: | 5 | operators\_on\_line\_notification | boolean | Alerts on decrease/increase of operators on the line |
  368: | 6 | actual\_load\_notification | boolean | Load decrease/increase alerts |
  369: | 7 | operators\_requirement\_notification | boolean | Operator Need Alerts |
  370: | 8 | sla\_notification | boolean | Alerts on SLA decrease/increase |
  371: 
  372: ## **Table system.groups\_vw**
  373: 
  374: Information about groups
  375: 
  376: | Serial number | Designation | Data type | Description |
  377: | :---- | :---- | :---- | :---- |
  378: | 1 | group\_id | bigint | Group ID |
  379: | 2 | name | character varying | Group name |
  380: | 3 | foreign\_id | text | Group ID in external system |
  381: | 4 | parent\_id | bigint | Parent group ID |
  382: | 5 | system\_id | character varying | External system name |
  383: | 6 | service\_name | character varying | Name of service |
  384: | 7 | service\_foreign\_id | text | External system identifier |
  385: 
  386: ## **Table system.historical\_data**
  387: 
  388: Historical data storage model
  389: 
  390: | Serial number | Designation | Data type | Description |
  391: | :---- | :---- | :---- | :---- |
  392: | 1  | service\_id | bigint | Unique identifier of the service to which the historical data belongs |
  393: | 2  | group\_id | bigint | Unique identifier of the group to which the historical data belongs |
  394: | 3  | start\_timestamp | timestamp with time zone | Start of 15 minute interval |
  395: | 4  | end\_timestamp | timestamp with time zone | End of 15 minute interval |
  396: | 5  | historic\_call\_number | integer | Unique processed requests |
  397: | 6  | miss\_call | integer | Unique missed calls |
  398: | 7  | historic\_aht | integer | Average talk time (this also includes the time it takes to dial outgoing calls) |
  399: | 8  | duration\_postprocessing | integer | Average duration of call post-processing |
  400: | 9  | change\_historic\_call | integer | Modified unique processed |
  401: | 10  | change\_miss\_call | integer | Modified Unique Missing |
  402: | 11  | change\_historic\_aht | integer | changed processing time |
  403: | 12  | change\_duration\_postprocessing | integer | changed post processing time |
  404: | 13  | status | character varying | interval status |
  405: | 14  | not\_unique\_received | integer | Non-unique incoming requests |
  406: | 15  | not\_unique\_treated | integer | Non-unique processed requests |
  407: | 16  | not\_unique\_missed | integer | Non-unique missing |
  408: | 17  | unique\_recieved | integer | Unique incoming requests |
  409: | 18  | change\_not\_unique\_received | integer | Modified non-unique incoming requests |
  410: | 19  | change\_not\_unique\_treated | integer | Modified non-unique processed requests |
  411: | 20  | change\_not\_unique\_missed | integer | Modified non-unique missed hits |
  412: | 21  | change\_unique\_recieved | integer | Modified unique incoming requests |
  413: | 22  | bkp$\_start\_timestamp | timestamp without time zone | \- |
  414: | 23  | bkp$\_end\_timestamp | timestamp without time zone | \- |
  415: | 24 | status\_call | character varying | \- |
  416: | 25 | status\_aht | character varying | \- |
  417: 
  418: ## **The system.http\_session\_history table**
  419: 
  420: The table contains the history of http sessions with entry and exit times
  421: 
  422: | Serial number | Designation | Data type | Description |
  423: | :---- | :---- | :---- | :---- |
  424: | 1  | http\_session\_number | bigint | Table entry ID |
  425: | 2  | http\_session\_id | character varying | http session id |
  426: | 3  | user\_name | character varying | System user |
  427: | 4  | login\_id | bigint | Login ID |
  428: | 5  | worker\_id | bigint | Employee ID |
  429: | 6  | logon\_time | timestamp with time zone | User login date |
  430: | 7  | logoff\_time | timestamp with time zone | User logout date |
  431: | 8  | bkp$\_logon\_time | timestamp without time zone | \- |
  432: | 9  | bkp$\_logoff\_time | timestamp without time zone | \- |
  433: 
  434: ## **The system.integration\_info table**
  435: 
  436: Record of differences in employee information in the WFM system and the Central Office of the Ministry of Justice
  437: 
  438: | Serial number | Designation | Data type | Description |
  439: | :---- | :---- | :---- | :---- |
  440: | 1  | id | bigint | Unique identifier |
  441: | 2  | protei\_foreign\_id | character varying | External system identifier for integration |
  442: | 3  | protei\_name | character varying | Employee name in external system |
  443: | 4  | protei\_surname | character varying | Employee's last name in the external system |
  444: | 5  | protei\_second\_name | character varying | Employee's patronymic in the external system |
  445: | 6  | protein\_status | character varying | Employee status (active/inactive) |
  446: | 7  | worker\_id | bigint | Employee ID in the WFM system |
  447: 
  448: ## **Table system.integration\_info\_group**
  449: 
  450: Denouement information about the employee from the COV-group
  451: 
  452: | Serial number | Designation | Data type | Description |
  453: | :---- | :---- | :---- | :---- |
  454: | 1  | integration\_info\_id | bigint | Information about the employee from the Center of Public Relations |
  455: | 2  | group\_id | bigint | Group |
  456: 
  457: ## **Table system.integration\_system**
  458: 
  459: Integration systems
  460: 
  461: | Serial number | Designation | Data type | Description |
  462: | :---- | :---- | :---- | :---- |
  463: | 1  | id | bigint | Integration system feature for Single sign-on (SSO) |
  464: | 2  | integration\_system\_name | text | System name |
  465: | 3  | personnel\_endpoint | text | Endpoint of the integration system |
  466: | 4  | system\_id | character varying | External system identifier |
  467: | 5  | personnel\_master | boolean | Master system sign for staff |
  468: | 6  | historical\_data\_endpoint | text | Access point for obtaining historical data for forecasting |
  469: | 7  | operators\_data\_endpoint | text | Access point for obtaining source data from operators |
  470: | 8  | work\_chat\_data\_end\_point | text | Access point for receiving data on chats |
  471: | 9  | account\_authorization\_endpoint | text | Access point for obtaining a UZ to log in to the system |
  472: | 10  | monitoring\_provider\_endpoint | text | url for monitoring this integration system |
  473: | 11  | sms\_notification\_config | text | \- |
  474: | 12  | sso | boolean | \- |
  475: | 13  | is\_sys | boolean | \- |
  476: | 14 | match\_type | character varying | Mapping attribute for staff synchronization |
  477: | 15 | ignore\_case | boolean | Ignore case when matching UZs |
  478: | 16 | online\_status\_by\_endpoint\_enabled | boolean | a sign of receiving online operator statuses through the specified monitoring access point |
  479: 
  480: ## **Table system.kpi\_change\_fact**
  481: 
  482: The value of the indicator set manually by the manager
  483: 
  484: | Serial number | Designation | Data type | Description |
  485: | :---- | :---- | :---- | :---- |
  486: | 1  | id | bigint | ID records |
  487: | 2  | worker\_id | bigint | Employee |
  488: | 3  | group\_id | bigint | Group |
  489: | 4  | kpi\_performance\_id | bigint | KPI |
  490: | 5  | year | smallint | Year |
  491: | 6  | month | text | Month |
  492: | 7  | value | double precision | Meaning |
  493: 
  494: ## **Table system.kpi\_chats\_norm**
  495: 
  496: Chat Guidelines
  497: 
  498: | Serial number | Designation | Data type | Description |
  499: | :---- | :---- | :---- | :---- |
  500: | 1  | id | bigint | ID records |
  501: | 2  | chats\_session | integer | Chats in session The number of chats the operator handled at one time |
  502: | 3  | norm | double precision | Standard value of the indicator Number of chats that an operator must process, given a certain number of chats in a package |
  503: 
  504: ## **Table system.kpi\_chats\_norm\_service\_groups**
  505: 
  506: Table linking group/service to chat norm
  507: 
  508: | Serial number | Designation | Data type | Description |
  509: | :---- | :---- | :---- | :---- |
  510: | 1  | kpi\_chats\_norm\_id | bigint | Norm ID records from kpi\_chats\_norm |
  511: | 2  | service\_id | bigint | Service ID |
  512: | 3  | group\_id | bigint | Group ID |
  513: 
  514: ## **Table system.kpi\_import**
  515: 
  516: Table for storing KPI indicators uploaded by the user
  517: 
  518: | Serial number | Designation | Data type | Description |
  519: | :---- | :---- | :---- | :---- |
  520: | 1  | id | bigint | ID records |
  521: | 2  | worker\_id | bigint | Employee ID |
  522: | 3  | date | date | Import date |
  523: | 4  | kpi\_id | bigint | Identifier of the imported indicator |
  524: | 5  | group\_id | bigint | Group ID |
  525: | 6  | value | double precision | Imported indicator value |
  526: 
  527: ## **Table system.kpi\_influence**
  528: 
  529: Table for storing KPI indicators uploaded by the user
  530: 
  531: | Serial number | Designation | Data type | Description |
  532: | :---- | :---- | :---- | :---- |
  533: | 1  | id | bigint | ID records |
  534: | 2  | kpi\_performance\_id | bigint | Service ID |
  535: | 3  | value | number range | Group ID |
  536: | 4  | percent\_formula | double precision | Event coefficient |
  537: 
  538: ## **Table system.kpi\_letters\_norm**
  539: 
  540: Norma \- letters
  541: 
  542: | Serial number | Designation | Data type | Description |
  543: | :---- | :---- | :---- | :---- |
  544: | 1  | id | bigint | ID records |
  545: | 2  | letter\_category | text | Post Category |
  546: | 3  | norm\_time | bigint | Standard processing time |
  547: 
  548: ## **Table system.kpi\_letters\_norm\_service\_groups**
  549: 
  550: Services-groups for kpi\_letters\_norm
  551: 
  552: | Serial number | Designation | Data type | Description |
  553: | :---- | :---- | :---- | :---- |
  554: | 1  | kpi\_letters\_norm\_id | bigint | Letter norm ID from kpi\_letters\_norm |
  555: | 2  | service\_id | bigint | Service ID |
  556: | 3  | group\_id | bigint | Group ID |
  557: 
  558: ## **Table system.kpi\_letters\_vw**
  559: 
  560: KPI for letters
  561: 
  562: | Serial number | Designation | Data type | Description |
  563: | ----- | ----- | ----- | ----- |
  564: | 1 | worker\_id | bigint | Employee ID |
  565: | 2 | date | date | Date |
  566: | 3 | group\_id | bigint | Group ID |
  567: | 4 | letter\_category | text | Category of letters |
  568: | 5 | letters\_number | integer | Number of letters |
  569: | 6 | norm\_time | bigint | Standard time |
  570: 
  571: ## **Table system.kpi\_norm**
  572: 
  573: Standards of indicators from "Premium indicators"
  574: 
  575: | Serial number | Designation | Data type | Description |
  576: | :---- | :---- | :---- | :---- |
  577: | 1  | id | bigint | Norm ID |
  578: | 2  | kpi\_performance\_id | bigint | Indicator ID from "Premium Indicators" |
  579: | 3  | type\_kpi\_group | text | Type of standard (voice calls, etc.) |
  580: | 4  | position\_id | bigint | Job title |
  581: | 5  | department\_id | bigint | Subdivision |
  582: | 6  | normative\_value | text | Standard value of the indicator |
  583: | 7  | kpi\_interval\_type | text | Interval type ("hour, working time", etc.) |
  584: 
  585: ## **Table system.kpi\_norm\_service\_groups**
  586: 
  587: Linking the standard from kpi\_norm and service/group
  588: 
  589: | Serial number | Designation | Data type | Description |
  590: | ----- | ----- | ----- | ----- |
  591: | 1  | kpi\_norm\_id | bigint | Norm ID from kpi\_norm |
  592: | 2  | service\_id | bigint | Service ID |
  593: | 3  | group\_id | bigint | Group ID |
  594: 
  595: ## **Table system.kpi\_norm\_vw**
  596: 
  597: KPI standards
  598: 
  599: | Serial number | Designation | Data type | Description |
  600: | ----- | ----- | ----- | ----- |
  601: | 1 | date\_from | timestamp with time zone | Start date |
  602: | 2 | date\_to | timestamp with time zone | End date |
  603: | 3 | worker\_id | bigint | Employee ID |
  604: | 4 | last\_name | character varying | Family name |
  605: | 5 | first\_name | character varying | Name |
  606: | 6 | second\_name | character varying | Surname |
  607: | 7 | department\_id | bigint | Division ID |
  608: | 8 | position\_id | bigint | Position ID |
  609: | 9 | call\_number | bigint | Number of calls |
  610: | 10 | call\_time | bigint | Call duration |
  611: | 11 | group\_id | bigint | Group ID |
  612: | 12 | group\_name | character varying | Group name |
  613: | 13 | normative\_value | text | Standard values |
  614: | 14 | id | bigint | Identifier |
  615: | 15 | kpi\_norm\_id | bigint | Identifier |
  616: 
  617: ## **Table system.kpi\_percent**
  618: 
  619: Positions Share in bonus
  620: 
  621: | Serial number | Designation | Data type | Description |
  622: | :---- | :---- | :---- | :---- |
  623: | 1  | id | bigint | ID records |
  624: | 2  | kpi\_performance\_id | bigint | Indicator |
  625: | 3  | share\_value | double precision | The meaning of the share |
  626: 
  627: ## **Table system.kpi\_percent\_department**
  628: 
  629: Table for connection of "Shares in premium" and divisions
  630: 
  631: | Serial number | Designation | Data type | Description |
  632: | :---- | :---- | :---- | :---- |
  633: | 1  | kpi\_percent\_id | bigint | Bonus share record ID from kpi\_percent |
  634: | 2  | departments\_id | bigint | Unit ID |
  635: 
  636: ## **Table system.kpi\_percent\_position**
  637: 
  638: Table for the connection between "Shares in the bonus" and the operator's position
  639: 
  640: | Serial number | Designation | Data type | Description |
  641: | :---- | :---- | :---- | :---- |
  642: | 1  | kpi\_percent\_id | bigint | Bonus share record ID from kpi\_percent |
  643: | 2  | positions\_id | bigint | Job ID |
  644: 
  645: ## **Table system.kpi\_performance**
  646: 
  647: Indicators
  648: 
  649: | Serial number | Designation | Data type | Description |
  650: | :---- | :---- | :---- | :---- |
  651: | 1  | id | bigint | ID records |
  652: | 2  | name | text | Name of the indicator |
  653: | 3  | is\_sys | boolean | System entry flag |
  654: | 4  | status | text | Status |
  655: 
  656: ## **Table system.kpi\_position\_pay\_type**
  657: 
  658: Hourly rate and bonus standard
  659: 
  660: | Serial number | Designation | Data type | Description |
  661: | :---- | :---- | :---- | :---- |
  662: | 1  | id | bigint | Surrogate ID |
  663: | 2  | department\_id | bigint | Department ID |
  664: | 3  | position\_id | bigint | Job Id |
  665: | 4  | hour\_rate | double precision | Meaning of hourly rate |
  666: | 5  | bonus | double precision | Percentage of bonus for position |
  667: | 6  | bonus\_mentor | double precision | Maximum bonus percentage for the Mentoring indicator |
  668: 
  669: ## **Table system.kpi\_worker\_chats\_work\_time**
  670: 
  671: Table for storing information about the operator's working time
  672: 
  673: | Serial number | Designation | Data type | Description |
  674: | :---- | :---- | :---- | :---- |
  675: | 1  | worker\_id | bigint | Employee ID |
  676: | 2  | date | date | The date for which the information is stored |
  677: | 3  | work\_time | bigint | Received working time |
  678: 
  679: ## **Table system.kpi\_worker\_letters**
  680: 
  681: Number of processed letters by operators
  682: 
  683: | Serial number | Designation | Data type | Description |
  684: | :---- | :---- | :---- | :---- |
  685: | 1  | worker\_id | bigint | Employee |
  686: | 2  | date | date | Date |
  687: | 3  | group\_id | bigint | Group |
  688: | 4  | letter\_category | text | Category of letters |
  689: | 5  | letters\_number | integer | Number of letters |
  690: 
  691: ## **Table system.last\_online\_load**
  692: 
  693: The table contains the latest online load data checked for deviations for each group.
  694: 
  695: | Serial number | Designation | Data type | Description |
  696: | :---- | :---- | :---- | :---- |
  697: | 1  | service\_id | integer | Link to the service. |
  698: | 2  | group\_id | integer | Link to the group. |
  699: | 3  | online\_load\_date | timestamp with time zone | Online load date. |
  700: 
  701: ## **Table system.log**
  702: 
  703: Event log
  704: 
  705: | Serial number | Designation | Data type | Description |
  706: | ----- | ----- | ----- | ----- |
  707: | 1  | id | bigint | Unique event identifier |
  708: | 2  | dtype | character varying | Event type |
  709: | 3  | start\_timestamp | timestamp with time zone | Event start time |
  710: | 4  | end\_timestamp | timestamp with time zone | Event end time |
  711: | 5  | message | text | Human-readable description of the event |
  712: | 6  | result | text | Human-readable description of the result |
  713: | 7  | successful | boolean | Was the operation successful? |
  714: | 8  | worker\_id | bigint | The user who caused the event to be executed. null if system |
  715: | 9  | object\_id | bigint | The identifier of the object associated with the event |
  716: | 10  | object\_type | character varying | The type of object associated with the event |
  717: | 11  | parent\_id | bigint | Parent record for grouping events |
  718: | 12  | bkp$\_start\_timestamp | timestamp without time zone | \- |
  719: | 13  | bkp$\_end\_timestamp | timestamp without time zone | \- |
  720: 
  721: ## **Table system.login**
  722: 
  723: Credentials of users registered in the system
  724: 
  725: | Serial number | Designation | Data type | Description |
  726: | :---- | :---- | :---- | :---- |
  727: | 1  | uid | bigint | Unique user identifier |
  728: | 2  | username | character varying | Unique username |
  729: | 3  | password | character varying | Hashed user password |
  730: | 4  | salt | character varying | Additional lines for password encryption (Salt is a term from cryptography) |
  731: | 5  | description | character varying | Description of the current user |
  732: | 6  | email | character varying | The user's primary email used to notify about changes to their account information |
  733: | 7  | worker\_id | bigint | Reference to the employee for whom the current login is defined |
  734: | 8  | logon\_time | timestamp with time zone | Date and time of the current user's last login |
  735: | 9  | expiry\_date | timestamp with time zone | The expiration date of the current user's password. After reaching this date, the user must change the password to a new one. If null, the password will never expire. |
  736: | 10  | lock\_date | timestamp with time zone | Date and time of login blocking |
  737: | 11  | created | timestamp with time zone | Date and time of login creation |
  738: | 12 | local | character varying | User language |
  739: | 13 | is\_sys | boolean | If 1, the user is considered a system user and cannot be deleted using the administration tool. |
  740: | 14 | bkp$\_logon\_time | timestamp without time zone | \- |
  741: | 15 | bkp$\_expiry\_date | timestamp without time zone | \- |
  742: | 16 | bkp$\_lock\_date | timestamp without time zone | \- |
  743: | 17 | bkp$\_created | timestamp without time zone | \- |
  744: | 18 | failed\_attempts | integer | Number of unsuccessful login attempts in a row |
  745: 
  746: ## **Table system.norm\_status**
  747: 
  748: Directory "Accounting of the statuses of the Center of Public Service"
  749: 
  750: | Serial number | Designation | Data type | Description |
  751: | :---- | :---- | :---- | :---- |
  752: | 1  | id | bigint | Unique identifier |
  753: | 2  | state\_id | bigint | The type of status that will be taken into account |
  754: | 3  | service\_id | bigint | Service |
  755: | 4  | operator\_type | character varying | Operator type |
  756: | 5  | pay\_type\_id | bigint | Payment type |
  757: | 6  | productivity | boolean | What hours to consider when calculating output |
  758: | 7  | payment | boolean | What hours to consider when calculating payment |
  759: 
  760: ## **Table system.norm\_week\_change**
  761: 
  762: Table with the history of changes in the standard hours per week
  763: 
  764: | Serial number | Designation | Data type | Description |
  765: | :---- | :---- | :---- | :---- |
  766: | 1 | id | bigint | \- |
  767: | 2 | worker\_id | bigint | Employee ID |
  768: | 3 | norm\_week | bigint | Standard hours per week in milliseconds |
  769: | 4 | change\_date | date | Date changes |
  770: 
  771: ## **System tablem.notification**
  772: 
  773: The fact of notifying/notifying an employee about something
  774: 
  775: | Serial number | Designation | Data type | Description |
  776: | :---- | :---- | :---- | :---- |
  777: | 1  | id | bigint | Unique notification identifier |
  778: | 2  | dtype | character varying | Alert type (class) |
  779: | 3  | message | character varying | Text message |
  780: | 4  | result | character varying | Alert text result |
  781: | 5  | author\_id | bigint | Author (creator) of the notification |
  782: | 6  | recipient\_id | bigint | Notification recipient |
  783: | 7  | create\_timestamp | timestamp with time zone | Moment of creation |
  784: | 8  | send\_timestamp | timestamp with time zone | Moment of dispatch |
  785: | 9  | reply\_timestamp | timestamp with time zone | The moment of receiving the answer |
  786: | 10  | status | character varying | Alert status |
  787: | 11  | channel | character varying | Employee Alert Type |
  788: | 12  | bkp$\_create\_timestamp | timestamp without time zone | \- |
  789: | 13  | bkp$\_send\_timestamp | timestamp without time zone | \- |
  790: | 14  | bkp$\_reply\_timestamp | timestamp without time zone | \- |
  791: | 15  | foreign\_id | character varying | \- |
  792: | 16  | link | text | Link |
  793: 
  794: ## **Table system.notification\_event\_recipient**
  795: 
  796: Notification event
  797: 
  798: | Serial number | Designation | Data type | Description |
  799: | :---- | :---- | :---- | :---- |
  800: | 1  | id | bigint | Identifier |
  801: | 2  | name | text | Name |
  802: | 3  | system\_name | text | System name |
  803: | 4  | description | text | Description |
  804: | 5  | status | character varying | Status |
  805: | 6  | event\_group | text | Event Group |
  806: | 7  | notifying\_chiefs\_level | integer | Number of notified senior managers |
  807: 
  808: ## **Таблица system.notification\_event\_recipient\_role**
  809: 
  810: Table for linking notification event and role
  811: 
  812: | Serial number | Designation | Data type | Description |
  813: | :---- | :---- | :---- | :---- |
  814: | 1  | event\_id | bigint | Event ID from notification |
  815: | 2  | role\_id | bigint | ID roll |
  816: 
  817: ## **Table system.notification\_issue**
  818: 
  819: \-
  820: 
  821: | Serial number | Designation | Data type | Description |
  822: | ----- | ----- | ----- | ----- |
  823: | 1  | id | bigint | \- |
  824: | 2  | plan\_interval\_id | bigint | \- |
  825: | 3  | event\_type\_id | bigint | \- |
  826: | 4  | creation\_date | timestamp without time zone | \- |
  827: | 5  | notified | boolean | \- |
  828: 
  829: ## **The system.notification\_metadata table**
  830: 
  831: Notification metadata (parameters)
  832: 
  833: | Serial number | Designation | Data type | Description |
  834: | ----- | ----- | ----- | ----- |
  835: | 1  | notification\_id | bigint | The notification you are looking for |
  836: | 2  | key | character varying | Parameter name |
  837: | 3  | value | character varying | Parameter value |
  838: 
  839: ## **Table system.notification\_push\_token**
  840: 
  841: Push Notification Token Storage
  842: 
  843: | Serial number | Designation | Data type | Description |
  844: | ----- | ----- | ----- | ----- |
  845: | 1  | worker\_id | bigint | Employee ID |
  846: | 2  | token | text | Token |
  847: | 3 | token\_type | text | \- |
  848: 
  849: ## **Table system.notification\_scheme**
  850: 
  851: Table with settings for generating notifications.
  852: 
  853: | Serial number | Designation | Data type | Description |
  854: | :---- | :---- | :---- | :---- |
  855: | 1  | id | bigint | Identifier. |
  856: | 2  | event\_type\_id | bigint | Link to the event type for which we are setting up a notification. |
  857: | 3  | message\_template | character varying | Notification template. |
  858: | 4  | notify\_workers | boolean | Flag that determines whether workers should be notified. Workers are determined from the context of the business process. |
  859: | 5  | notify\_managers | boolean | Flag that determines the need to notify managers. Managers are determined for employees. |
  860: | 6  | managers\_hierarchy\_depth | bigint | Integer value defining the "Hierarchy Gap" for searching managers. Relevant if the notify\_managers field is True. |
  861: | 7  | notify\_roles | boolean | Flag that determines whether employees should be notified based on business roles. Notified roles are in a separate junction table. |
  862: | 8  | notify\_specific\_workers | boolean | Flag that determines the need to notify specific workers. The workers to be notified are in a separate junction table. |
  863: | 9  | enable | boolean | A flag that determines whether notification for this scheme is enabled or disabled. |
  864: | 10  | version | bigint | The version of the record, incremented when changed. |
  865: 
  866: ## **Table system.notification\_scheme\_channel**
  867: 
  868: Table of mapping between channels and notification schemes.
  869: 
  870: | Serial number | Designation | Data type | Description |
  871: | :---- | :---- | :---- | :---- |
  872: | 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
  873: | 2  | channel | character varying | Notification channel. |
  874: 
  875: ## **Table system.notification\_scheme\_role**
  876: 
  877: A table of the mapping between notification schemes and the roles to be notified.
  878: 
  879: | Serial number | Designation | Data type | Description |
  880: | :---- | :---- | :---- | :---- |
  881: | 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
  882: | 2  | role\_id | bigint | Link to the role. |
  883: 
  884: ## **Table system.notification\_scheme\_worker**
  885: 
  886: A table of the links between notification schemes and the specific employees who need to be notified.
  887: 
  888: | Serial number | Designation | Data type | Description |
  889: | ----- | ----- | ----- | ----- |
  890: | 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
  891: | 2  | worker\_id | bigint | Link to employee. |
  892: 
  893: ## **Table system.old\_personal\_information\_vw**
  894: 
  895: Old personal information
  896: 
  897: | Serial number | Designation | Data type | Description |
  898: | ----- | ----- | ----- | ----- |
  899: | 1 | worker\_id | bigint | Employee ID |
  900: | 2 | first\_name | character varying | Name |
  901: | 3 | second\_name | character varying | Surname |
  902: | 4 | last\_name | character varying | Family name |
  903: | 5 | operator\_type | character varying | Operator type |
  904: | 6 | position\_name | text | Position name |
  905: | 7 | employment | date | Date of employment |
  906: | 8 | department\_name | text | Name of the department |
  907: | 9 | group\_name | character varying | Group name |
  908: | 10 | status | character varying | Status |
  909: | 11 | group\_id | bigint | Group ID |
  910: | 12 | position\_id | bigint | Position ID |
  911: | 13 | department\_id | bigint | Division ID |
  912: 
  913: ## **Table system.online\_load**
  914: 
  915: Online load for a specific time interval
  916: 
  917: | Serial number | Designation | Data type | Description |
  918: | :---- | :---- | :---- | :---- |
  919: | 1  | id | bigint | Unique identifier of the load for a specific interval |
  920: | 2  | date\_time | timestamp with time zone | Load time |
  921: | 3  | call\_number | integer | Number of calls |
  922: | 4  | operator\_number | integer | Number of operators |
  923: | 5  | group\_id | integer | Unique identifier of the operator group to which the load belongs |
  924: | 6  | service\_id | integer | Unique identifier of the service to which the load belongs |
  925: | 7  | service\_level | integer | Current quality of service |
  926: | 8  | required\_operator\_number | integer | Required number of operators |
  927: | 9  | call\_received | integer | Number of received requests (cumulatively from the beginning of the day) |
  928: | 10  | aht | bigint | Average talk time in the group (cumulatively from the beginning of the day), in milliseconds |
  929: | 11  | acd | double precision | Percentage of accepted requests (cumulatively from the beginning of the day) |
  930: | 12  | awt | bigint | Average subscriber waiting time in queue from the beginning of the day |
  931: | 13  | bkp$\_date\_time | timestamp without time zone | \- |
  932: | 14 | call\_answered | integer | Number of calls processed (from the beginning of the day to the moment of the request) |
  933: | 15 | call\_answered\_tst | integer | The number of processed calls that waited in the queue for less than N seconds (from the beginning of the day to the moment of the request) |
  934: | 16 | call\_processing | integer | Number of calls in progress for operators at the time of the request |
  935: 
  936: ## **Table system.operator\_event\_vw**
  937: 
  938: Operator Events
  939: 
  940: | Serial number | Designation | Data type | Description |
  941: | ----- | ----- | ----- | ----- |
  942: | 1 | worker\_id | bigint | Employee ID |
  943: | 2 | first\_name | character varying | Name |
  944: | 3 | second\_name | character varying | Surname |
  945: | 4 | last\_name | character varying | Family name |
  946: | 5 | event\_type | character varying | Event type |
  947: | 6 | start\_timestamp | timestamp with time zone | Start time moment |
  948: | 7 | end\_timestamp | timestamp with time zone | End time moment |
  949: | 8 | event\_status | character varying | Event status |
  950: | 9 | dtype | character varying | Type Discriminator |
  951: 
  952: ## **Table system.operator\_load**
  953: 
  954: A table storing the number and time of calls processed by the operator
  955: 
  956: | Serial number | Designation | Data type | Description |
  957: | :---- | :---- | :---- | :---- |
  958: | 1  | worker\_id | bigint | Operator identifier |
  959: | 2  | service\_id | bigint | The service within which the operator worked |
  960: | 3  | group\_id | bigint | The group in which the operator worked |
  961: | 4  | date\_from | timestamp with time zone | Beginning of the period |
  962: | 5  | date\_to | timestamp with time zone | End of the period |
  963: | 6  | call\_time | bigint | Non-unique request processing time in milliseconds |
  964: | 7  | call\_number | bigint | Number of processed non-unique requests |
  965: | 8  | bkp$\_date\_from | timestamp without time zone | \- |
  966: | 9  | bkp$\_date\_to | timestamp without time zone | \- |
  967: 
  968: ## **Table system.operator\_load\_vw**
  969: 
  970: Number and time of calls processed by the operator
  971: 
  972: | Serial number | Designation | Data type | Description |
  973: | ----- | ----- | ----- | ----- |
  974: | 1 | worker\_id | bigint | Employee ID |
  975: | 2 | first\_name | character varying | Name |
  976: | 3 | second\_name | character varying | Surname |
  977: | 4 | last\_name | character varying | Family name |
  978: | 5 | department\_name | text | Name of the department |
  979: | 6 | date\_from | timestamp with time zone | Start date |
  980: | 7 | date\_to | timestamp with time zone | End date |
  981: | 8 | call\_time | bigint | Call duration |
  982: | 9 | call\_number | bigint | Number of calls |
  983: | 10 | system\_id | character varying | System ID |
  984: | 11 | group\_name | character varying | Group name |
  985: | 12 | position\_id | bigint | Position ID |
  986: | 13 | department\_id | bigint | Division ID |
  987: | 14 | group\_id | bigint | Group ID |
  988: 
  989: ## **Table system.operator\_login\_time**
  990: 
  991: Table storing login/logout/stay time in the integration system
  992: 
  993: | Serial number | Designation | Data type | Description |
  994: | :---- | :---- | :---- | :---- |
  995: | 1  | worker\_id | bigint | ID worker а |
  996: | 2  | system\_id | bigint | Integration system ID |
  997: | 3  | login\_time | timestamp with time zone | Date, time of entry |
  998: | 4  | logout\_time | timestamp with time zone | Date, time of release |
  999: | 5  | login\_duration | bigint | Time spent in the COV |
 1000: | 6  | bkp$\_login\_time | timestamp without time zone | \- |
 1001: | 7  | bkp$\_logout\_time | timestamp without time zone | \- |
 1002: 
 1003: ## **Table system.operator\_login\_time\_vw**
 1004: 
 1005: Operator login/logout time
 1006: 
 1007: | Serial number | Designation | Data type | Description |
 1008: | ----- | ----- | ----- | ----- |
 1009: | 1 | worker\_id | bigint | Employee ID |
 1010: | 2 | first\_name | character varying | Name |
 1011: | 3 | second\_name | character varying | Surname |
 1012: | 4 | last\_name | character varying | Family name |
 1013: | 5 | system\_name | character varying | System name |
 1014: | 6 | login\_time | timestamp with time zone | Login time |
 1015: | 7 | logout\_time | timestamp with time zone | Logout time |
 1016: | 8 | login\_duration | bigint | Login duration |
 1017: | 9 | department\_name | text | Name of the department |
 1018: 
 1019: ## **Table system.operator\_outgoing\_calls**
 1020: 
 1021: Outgoing Call Results
 1022: 
 1023: | Serial number | Designation | Data type | Description |
 1024: | :---- | :---- | :---- | :---- |
 1025: | 1  | worker\_id | bigint | Operator ID |
 1026: | 2  | service\_id | bigint | The service within which the operator worked |
 1027: | 3  | group\_id | bigint | The group in which the operator worked |
 1028: | 4  | date | date | Day |
 1029: | 5  | result\_code | text | Code of the result marked in the COV |
 1030: | 6  | result\_description | text | The name of the result marked in the COV |
 1031: | 7  | call\_number | integer | Number of processed non-unique requests |
 1032: 
 1033: ## **Table system.operator\_outgoing\_calls\_vw**
 1034: 
 1035: Results of outgoing calls from operators
 1036: 
 1037: | Serial number | Designation | Data type | Description |
 1038: | ----- | ----- | ----- | ----- |
 1039: | 1 | first\_name | character varying | Name |
 1040: | 2 | second\_name | character varying | Surname |
 1041: | 3 | last\_name | character varying | Family name |
 1042: | 4 | system\_id | character varying | System ID |
 1043: | 5 | group\_name | character varying | Group name |
 1044: | 6 | date | date | Date |
 1045: | 7 | result\_code | text | Result code |
 1046: | 8 | result\_description | text | Description of the result |
 1047: | 9 | call\_number | integer | Number of calls |
 1048: 
 1049: ## **Table system.operator\_overtime\_vw**
 1050: 
 1051: Operator login/logout time
 1052: 
 1053: | Serial number | Designation | Data type | Description |
 1054: | ----- | ----- | ----- | ----- |
 1055: | 1 | worker\_id | bigint | Name of the department |
 1056: | 2 | date | timestamp without time zone | Name of the department |
 1057: | 3 | duration | numeric | Name of the department |
 1058: 
 1059: ## **Table system.operator\_schedule\_vw**
 1060: 
 1061: Operators schedule
 1062: 
 1063: | Serial number | Designation | Data type | Description |
 1064: | ----- | ----- | ----- | ----- |
 1065: | 1 | worker\_id | bigint | Employee ID |
 1066: | 2 | last\_name | character varying | Family name |
 1067: | 3 | first\_name | character varying | Name |
 1068: | 4 | second\_name | character varying | Surname |
 1069: | 5 | position\_name | text | Position name |
 1070: | 6 | department\_name | text | Name of the department |
 1071: | 7 | valid\_from | date | Valid from |
 1072: | 8 | valid\_to | date | Valid until |
 1073: 
 1074: ## **The system.operator\_state table**
 1075: 
 1076: Handbook "Configuration of working time efficiency"
 1077: 
 1078: | Serial number | Designation | Data type | Description |
 1079: | :---- | :---- | :---- | :---- |
 1080: | 1  | id | bigint | Unique identifier of the operator status |
 1081: | 2  | state\_id | character varying | Status ID in the CAC (foreignId) |
 1082: | 3  | state | character varying | Status name in the COV |
 1083: | 4  | state\_name | character varying | Status name (to be displayed in the report) |
 1084: | 5  | description | character varying | Status Description |
 1085: | 6  | is\_productive | boolean | Is the current status productive time? |
 1086: | 7  | is\_work\_load | boolean | Is the current status a net load? |
 1087: | 8  | absence | boolean | Is the current status time away? |
 1088: | 9  | system\_id | bigint | The COV from which the status was received |
 1089: | 10  | is\_talk\_time | boolean | Checkbox "Talk time" |
 1090: | 11  | is\_break | boolean | Cheboks "Break Time" |
 1091: | 12  | is\_fact\_time | boolean | Actual time indicator in the timesheet |
 1092: | 13  | is\_productive\_work\_time | boolean | Signs of a productive working time |
 1093: | 14  | line\_state\_type | character varying | Possible operator statuses on the line |
 1094: | 15  | is\_after\_call\_work | boolean | Post-call processing |
 1095: | 16  | is\_operator\_active | boolean | Indication that the operator is online and active |
 1096: | 17  | color | character varying | Display color in reports |
 1097: | 18 | is\_billable\_time | boolean | Paid time indicator |
 1098: 
 1099: ## **Table system.operator\_status\_vw**
 1100: 
 1101: Operator statuses
 1102: 
 1103: | Serial number | Designation | Data type | Description |
 1104: | ----- | ----- | ----- | ----- |
 1105: | 1 | worker\_id | bigint | \- |
 1106: | 2 | first\_name | character varying | Name |
 1107: | 3 | second\_name | character varying | Surname |
 1108: | 4 | last\_name | character varying | Family name |
 1109: | 5 | state\_name | character varying | Status name |
 1110: | 6 | date\_from | timestamp with time zone | Start date |
 1111: | 7 | date\_to | timestamp with time zone | End date |
 1112: | 8 | duration\_in\_state | bigint | Duration in status |
 1113: | 9 | is\_productive | boolean | is\_productive |
 1114: | 10 | is\_work\_load | boolean | is\_work\_load |
 1115: | 11 | system\_id | character varying | System ID |
 1116: | 12 | is\_talk\_time | boolean | is\_talk\_time |
 1117: | 13 | is\_fact\_time | boolean | is\_fact\_time |
 1118: | 14 | group\_name | character varying | Group name |
 1119: | 15 | group\_id | bigint | Group ID |
 1120: | 16 | position\_name | text | Position name |
 1121: | 17 | department\_name | text | Name of the department |
 1122: | 18 | is\_break | boolean | is\_break |
 1123: | 19 | foreign\_id | text | External identifier |
 1124: | 20 | is\_after\_call\_work | boolean | is\_after\_call\_work |
 1125: 
 1126: ## **Table system.operator\_status\_vw\_old**
 1127: 
 1128: Operator statuses (old)
 1129: 
 1130: | Serial number | Designation | Data type | Description |
 1131: | ----- | ----- | ----- | ----- |
 1132: | 1 | worker\_id | bigint | \- |
 1133: | 2 | first\_name | character varying | \- |
 1134: | 3 | second\_name | character varying | \- |
 1135: | 4 | last\_name | character varying | \- |
 1136: | 5 | state\_name | character varying | \- |
 1137: | 6 | date\_from | timestamp with time zone | \- |
 1138: | 7 | date\_to | timestamp with time zone | \- |
 1139: | 8 | duration\_in\_state | bigint | \- |
 1140: | 9 | is\_productive | boolean | \- |
 1141: | 10 | is\_work\_load | boolean | \- |
 1142: | 11 | system\_id | character varying | \- |
 1143: | 12 | is\_talk\_time | boolean | \- |
 1144: | 13 | payment | boolean | \- |
 1145: | 14 | group\_name | character varying | \- |
 1146: | 15 | position\_name | text | \- |
 1147: | 16 | department\_name | text | \- |
 1148: | 17 | is\_break | boolean | \- |
 1149: | 18 | foreign\_id | text |  |
 1150: 
 1151: ## **Table system.pay\_type**
 1152: 
 1153: Directory "Payment Type"
 1154: 
 1155: | Serial number | Designation | Data type | Description |
 1156: | :---- | :---- | :---- | :---- |
 1157: | 1  | id | bigint | Unique payment type identifier |
 1158: | 2  | name | character varying | Payment type name |
 1159: | 3  | description | character varying | Payment type comment |
 1160: 
 1161: ## **Table system.permission**
 1162: 
 1163: Contains the basic system privileges that govern user access to views, frames, and functions. Entries in this table can only be added by developers when implementing the corresponding functionality.
 1164: 
 1165: | Serial number | Designation | Data type | Description |
 1166: | :---- | :---- | :---- | :---- |
 1167: | 1  | id | character varying | Unique string identifier of the privilege |
 1168: | 2  | parent\_id | character varying | A reference to a parent privilege, without which the current privilege has no meaning. If the current privilege is assigned but the parent privilege is not, the parent privilege is assigned implicitly. A similar rule applies to the entire privilege tree |
 1169: | 3  | entity\_package\_id | bigint | A reference to the module that implements the function protected by this privilege. |
 1170: 
 1171: ## **Table system.personal\_information\_vw**
 1172: 
 1173: Personal information
 1174: 
 1175: | Serial number | Designation | Data type | Description |
 1176: | ----- | ----- | ----- | ----- |
 1177: | 1 | worker\_id | bigint | Employee ID |
 1178: | 2 | first\_name | character varying | Name |
 1179: | 3 | second\_name | character varying | Surname |
 1180: | 4 | last\_name | character varying | Family name |
 1181: | 5 | operator\_type | character varying | Operator type |
 1182: | 6 | employment | date | Date of employment |
 1183: | 7 | dismissal | date | Absence |
 1184: | 8 | status | character varying | Status |
 1185: | 9 | position\_id | bigint | Position ID |
 1186: | 10 | department\_id | bigint | Division ID |
 1187: | 11 | position\_name | text | Position name |
 1188: | 12 | department\_name | text | Name of the department |
 1189: | 13 | comment | character varying | Comment |
 1190: | 14 | tab\_no | character varying | Personnel number |
 1191: | 15 | zone\_display\_name | character varying | \- |
 1192: 
 1193: ## **Table system.plan\_interval**
 1194: 
 1195: Employee work interval from the schedule plan
 1196: 
 1197: | Serial number | Designation | Data type | Description |
 1198: | :---- | :---- | :---- | :---- |
 1199: | 1  | id | bigint | Unique identifier |
 1200: | 2  | dtype | text | Interval type (ShiftPlanInterval, BreakPlanInterval, etc.) |
 1201: | 3  | solution\_id | bigint | The schedule to which the interval belongs |
 1202: | 4  | worker\_id | bigint | The employee to whom this interval applies |
 1203: | 5  | my\_start | timestamp with time zone | Minimum start time of the interval |
 1204: | 6  | max\_end | timestamp with time zone | Maximum end time of the interval |
 1205: | 7  | start\_timestamp | timestamp with time zone | Actual start time of the interval |
 1206: | 8  | end\_timestamp | timestamp with time zone | The current moment of the end of the interval |
 1207: | 9  | type | character varying | Interval Type (IntervalType) |
 1208: | 10  | status | character varying | Interval status (active/inactive) |
 1209: | 11  | service\_group\_plan\_id | bigint | The service-group plan to which the interval belongs |
 1210: | 12  | shift\_plan\_interval\_id | bigint | The shift plan to which the interval belongs (office operators only) |
 1211: | 13  | business\_event\_id | bigint | The event to which the interval relates |
 1212: | 14  | fraction | integer | The share with which the employee is involved in the project (%) |
 1213: | 15  | info | text | Raw data |
 1214: | 16  | bkp$\_my\_start | timestamp without time zone | \- |
 1215: | 17  | bkp$\_max\_end | timestamp without time zone | \- |
 1216: | 18  | bkp$\_start\_timestamp | timestamp without time zone | \- |
 1217: | 19  | bkp$\_end\_timestamp | timestamp without time zone | \- |
 1218: | 20 | is\_payable | boolean | \- |
 1219: 
 1220: ## **Table system.plan\_interval\_service\_group\_plan**
 1221: 
 1222: Uncoupling PlanInterval and ServiceGroupPlan
 1223: 
 1224: | Serial number | Designation | Data type | Description |
 1225: | :---- | :---- | :---- | :---- |
 1226: | 1  | plan\_id | bigint | PlanInterval Identifier |
 1227: | 2  | service\_group\_plan\_id | bigint | ServiceGroupPlan Identifier |
 1228: 
 1229: ## **Table system. planned\_worker\_wish**
 1230: 
 1231: Table of planned preferences
 1232: 
 1233: | Serial number | Designation | Data type | Description |
 1234: | :---- | :---- | :---- | :---- |
 1235: | 1 | id | bigint | \- |
 1236: | 2 | operating\_schedule\_planning\_task\_id | bigint | The task within which the preference was planned |
 1237: | 3 | worker\_wish\_id | bigint | Preference entered |
 1238: | 4 | duration | bigint | Duration of the planned shift in milliseconds |
 1239: | 5 | adjusted\_duration | bigint | Shift duration in milliseconds, including unpaid breaks |
 1240: | 6 | start | timestamp with time zone | Shift start date |
 1241: 
 1242: ## **Table system.planning\_schedule\_designation**
 1243: 
 1244: Linking the employee, the schedule and the planned work schedule
 1245: 
 1246: | Serial number | Designation | Data type | Description |
 1247: | :---- | :---- | :---- | :---- |
 1248: | 1  | worker\_id | bigint | Employee ID |
 1249: | 2  | schedule\_id | bigint | Work schedule identifier |
 1250: | 3  | operating\_schedule\_solution\_id | bigint | Work Schedule Planning Solution Identifier |
 1251: | 4  | status | character varying | Status |
 1252: | 5  | valid\_from | date | Applied since (date) |
 1253: | 6  | valid\_to | date | Applied on(date) |
 1254: | 7  | id | bigint | ID records |
 1255: | 8  | surplus | character varying | a sign that the operator is redundant on different days from the beginning of the period in different groups |
 1256: | 9 | operating\_schedule\_planning\_task\_id | bigint | Planning task |
 1257: 
 1258: ## **Table system.planning\_task**
 1259: 
 1260: Planning task
 1261: 
 1262: | Serial number | Designation | Data type | Description |
 1263: | :---- | :---- | :---- | :---- |
 1264: | 1  | id | bigint | \- |
 1265: | 2  | author\_id | bigint | Link to the employee who created the task |
 1266: | 3  | creation\_date | timestamp with time zone | Task creation time |
 1267: | 4  | end\_date | timestamp with time zone | Task completion time |
 1268: | 5  | solution\_id | bigint | Link to the work schedule |
 1269: | 6  | state | character varying | Planning Task Status |
 1270: | 7  | result | character varying | Planning result in Json format |
 1271: | 8  | config | character varying | Scheduling configuration in Json format |
 1272: | 9  | replanning | boolean | Is this task a rescheduling task? |
 1273: | 10  | error\_message | character varying | Description of planning error |
 1274: | 11  | version | bigint | \- |
 1275: | 12  | dtype | character varying | \- |
 1276: | 13  | replanning\_time | timestamp with time zone | the exact time from which we update the schedule |
 1277: 
 1278: ## **Table system. planning\_task\_extension**
 1279: 
 1280: Extended information on the planning task
 1281: 
 1282: | Serial number | Designation | Data type | Description |
 1283: | :---- | :---- | :---- | :---- |
 1284: | 1 | id | bigint | \- |
 1285: | 2 | planning\_task\_id | bigint | Planning task identifier |
 1286: | 3 | dtype | character varying | Type of extended information on the planning task |
 1287: | 4 | created\_at | timestamp with time zone | Date-time of creation of extended information |
 1288: | 5 | info | character varying | String representation of extended task information |
 1289: 
 1290: ## **Table system.position**
 1291: 
 1292: Directory of Jobs
 1293: 
 1294: | Serial number | Designation | Data type | Description |
 1295: | :---- | :---- | :---- | :---- |
 1296: | 1  | id | bigint | ID records |
 1297: | 2  | name | text | Job Title |
 1298: | 3  | uid | text | external system identifier |
 1299: | 4  | status | character varying | Position status |
 1300: | 5  | is\_planning | boolean | Are employees with this position involved in planning? |
 1301: 
 1302: ## **The system.position\_role table**
 1303: 
 1304: Roles Positions
 1305: 
 1306: | Serial number | Designation | Data type | Description |
 1307: | :---- | :---- | :---- | :---- |
 1308: | 1  | id | bigint | Identifier |
 1309: | 2  | role | text | Role name |
 1310: | 3  | position\_id | bigint | Job ID |
 1311: 
 1312: ## **Table system.possible\_worker\_schedule\_template**
 1313: 
 1314: Work schedule template assigned to operator
 1315: 
 1316: | Serial number | Designation | Data type | Description |
 1317: | :---- | :---- | :---- | :---- |
 1318: | 1  | id | bigint | Table entry ID |
 1319: | 2  | worker\_id | bigint | ID worker а |
 1320: | 3  | schedule\_template\_id | bigint | Work Schedule Template ID |
 1321: | 4  | is\_priority | boolean | Is this template a priority? |
 1322: | 5  | possible\_rotation | character varying | Marked template rotations |
 1323: | 6  | bkp$\_possible\_rotation | character varying | \- |
 1324: 
 1325: ## **Table system.pref\_table**
 1326: 
 1327: Imported from Argus infrastructure
 1328: 
 1329: | Serial number | Designation | Data type | Description |
 1330: | :---- | :---- | :---- | :---- |
 1331: | 1  | pref\_name | character varying | name options |
 1332: | 2  | pref\_value | text | value options |
 1333: | 3  | pref\_comment | character varying | option comment |
 1334: | 4  | pref\_display\_name | character varying | option display name |
 1335: | 5  | pref\_category\_id | integer | Options category |
 1336: | 6  | pref\_data\_type | integer | Type options |
 1337: 
 1338: ## **Table system.proc\_def\_template**
 1339: 
 1340: Imported from Argus infrastructure
 1341: 
 1342: | Serial number | Designation | Data type | Description |
 1343: | :---- | :---- | :---- | :---- |
 1344: | 1 | id | bigint | \- |
 1345: | 2 | schedule\_planning\_template\_id | bigint | \- |
 1346: | 3 | proc\_def\_id | character varying | \- |
 1347: | 4 | proc\_def\_key | character varying | \- |
 1348: 
 1349: ## **Table system.production\_calendar**
 1350: 
 1351: Production calendar
 1352: 
 1353: | Serial number | Designation | Data type | Description |
 1354: | :---- | :---- | :---- | :---- |
 1355: | 1  | year | bigint | Unique identifier of the production calendar and its year |
 1356: | 2  | config\_string | text | Configuration in xml form |
 1357: | 3  | version | bigint | \- |
 1358: | 4 | display\_in\_work\_schedule | boolean | Display in work schedule |
 1359: 
 1360: ## **Table system.report\_band\_model**
 1361: 
 1362: Band model from the Report Editor. Each report has records in this table.
 1363: 
 1364: | Serial number | Designation | Data type | Description |
 1365: | :---- | :---- | :---- | :---- |
 1366: | 1  | id | bigint | ID is in the box |
 1367: | 1  | id | bigint | ID is in the box |
 1368: | 2  | name | character varying | Band name (mostly empty) |
 1369: | 2  | name | character varying | Band name (mostly empty) |
 1370: | 3  | keyword | character varying | Description of the band |
 1371: | 3  | description | character varying | Description of the band |
 1372: | 4  | keyword | character varying | The keyword of the band, we see it in the editor when we create a band (as a name) |
 1373: | 4  | version | bigint | The keyword of the band, we see it in the editor when we create a band (as a name) |
 1374: | 5  | status | character varying | The Stause Band |
 1375: | 5  | parent\_id | bigint | The Stause Band |
 1376: | 6  | orientation | character varying | Version Band |
 1377: | 6  | version | bigint | Version Band |
 1378: | 7  | query | character varying | Parent Band ID |
 1379: | 7  | parent\_id | bigint | Parent Band ID |
 1380: | 8  | orientation | character varying | Text orientation in band |
 1381: | 8  | ordinal\_number | integer | Text orientation in band |
 1382: | 9  | query | text | Directly query, written to the band |
 1383: | 9  | data\_loader\_type | character varying | Directly query, written to the band |
 1384: | 10  | dtype | character varying | Sequence number within the report |
 1385: | 10  | ordinal\_number | integer | Sequence number within the report |
 1386: | 11  | data\_loader\_type | character varying | The type of query we use to load data (SQl/Groovy) |
 1387: 
 1388: ## **The system.report\_group\_roles table**
 1389: 
 1390: Linking the name of the report group and the roles to whom the group is available
 1391: 
 1392: | Serial number | Designation | Data type | Description |
 1393: | :---- | :---- | :---- | :---- |
 1394: | 1  | group\_name | text | Group name |
 1395: | 2  | role\_id | bigint | Role |
 1396: 
 1397: ## **Table system.report\_model\_template**
 1398: 
 1399: Template model for the report from the "Report Editor"
 1400: 
 1401: | Serial number | Designation | Data type | Description |
 1402: | :---- | :---- | :---- | :---- |
 1403: | 1  | id | bigint | Template ID |
 1404: | 1  | id | bigint | Template ID |
 1405: | 2  | file\_name | character varying | Template file name |
 1406: | 2  | file\_name | character varying | Template filename |
 1407: | 3  | description | character varying | Template File Description |
 1408: | 3  | creation\_date | timestamp without time zone | Template File Description |
 1409: | 4  | creation\_date | timestamp with time zone | Date of creation |
 1410: | 4  | template | about | Date of creation |
 1411: | 5  | mime\_type | character varying | Reports the ID in which the template is loaded |
 1412: | 5  | template | about | Reports the ID in which the template is loaded |
 1413: | 6  | description | character varying | Attached document format (XML/HTML) |
 1414: | 6  | mime\_type | character varying | Attached document format (XML/HTML) |
 1415: | 7  | bkp$\_creation\_date | timestamp without time zone | \- |
 1416: | 7  | version | bigint | \- |
 1417: | 8  | report\_type\_id | bigint | \- |
 1418: 
 1419: ## **Table system.report\_task**
 1420: 
 1421: | Serial number | Designation | Data type | Description |
 1422: | :---- | :---- | :---- | :---- |
 1423: | 1  | id | bigint | \- |
 1424: | 1  | id | bigint | \- |
 1425: | 2  | name | character varying | \- |
 1426: | 2  | report\_type\_id | bigint | \- |
 1427: | 3  | creation\_date | timestamp with time zone | \- |
 1428: | 3  | creation\_date | timestamp with time zone | \- |
 1429: | 4  | end\_date | timestamp with time zone | \- |
 1430: | 4  | end\_date | timestamp with time zone | \- |
 1431: | 5  | state | character varying | \- |
 1432: | 5  | state | character varying | \- |
 1433: | 6  | param\_values | character varying | \- |
 1434: | 6  | initiator\_id | bigint | \- |
 1435: | 7  | template\_id | bigint | \- |
 1436: | 8  | output\_format | character varying | \- |
 1437: | 9  | type | character varying | Type of tasks |
 1438: | 9  | foreign\_id | character varying | Type of tasks |
 1439: | 10  | link | character varying | \- |
 1440: | 11  | error | character varying | \- |
 1441: | 12  | execution\_date | timestamp with time zone | \- |
 1442: | 13  | expiration\_date | timestamp with time zone | \- |
 1443: | 14  | period\_config\_id | bigint | \- |
 1444: | 15  | dtype | character varying | \- |
 1445: | 16  | callback\_url | text | \- |
 1446: | 17  | num\_repeats | integer | \- |
 1447: 
 1448: ## **Table system.report\_task\_result**
 1449: 
 1450: Result of completing the task of building a report
 1451: 
 1452: | Serial number | Designation | Data type | Description |
 1453: | :---- | :---- | :---- | :---- |
 1454: | 1  | id | bigint | Identifier |
 1455: | 2  | state | character varying | State |
 1456: | 3  | submitted\_at | timestamp with time zone | Time to receive a response |
 1457: | 4  | report\_task\_id | bigint | Report generation task ID |
 1458: | 5  | link | character varying | Link to the result |
 1459: | 6  | error | character varying | Error message |
 1460: | 7  | foreign\_id | character varying | Identifier in external system |
 1461: 
 1462: ## **Table system.report\_type**
 1463: 
 1464: Report model from the "Report Editor"
 1465: 
 1466: | Serial number | Designation | Data type | Description |
 1467: | :---- | :---- | :---- | :---- |
 1468: | 1  | id | bigint | The report ID |
 1469: | 1  | id | bigint | The report ID |
 1470: | 2  | name | character varying | Title of the report |
 1471: | 2  | name | character varying | Title of the report |
 1472: | 3  | description | character varying | Report Description |
 1473: | 3  | keyword | character varying | Report Description |
 1474: | 4  | keyword | character varying | Report keyword, almost never used (name instead) |
 1475: | 4  | description | character varying | Report keyword, almost never used (name instead) |
 1476: | 5  | status | character varying | Status report |
 1477: | 5  | version | bigint | Status report |
 1478: | 6  | root\_band\_id | bigint | Report version |
 1479: | 6  | version | bigint | Report version |
 1480: | 7  | group\_id | bigint | ID property from type\_property\_holder |
 1481: | 7  | property\_holder\_id | bigint | ID property from type\_property\_holder |
 1482: | 8  | root\_band\_id | bigint | ID of the parent band in this report |
 1483: | 8  | state | character varying | ID of the parent band in this report |
 1484: | 9  | state | character varying | Report status (locked/published) |
 1485: | 9  | dtype | character varying | Report status (locked/published) |
 1486: 
 1487: ## **Table system.report\_type\_report\_model\_template**
 1488: 
 1489: Linking a report from the Report Editor and a data template
 1490: 
 1491: | Serial number | Designation | Data type | Description |
 1492: | :---- | :---- | :---- | :---- |
 1493: | 1  | report\_type\_id | bigint | The report ID |
 1494: | 2  | report\_model\_template\_id | bigint | Template ID |
 1495: 
 1496: ## **Table system.role**
 1497: 
 1498: Contains a list of user roles that can be configured by the administrator. Roles determine what privileges the current user has.
 1499: 
 1500: | Serial number | Designation | Data type | Description |
 1501: | :---- | :---- | :---- | :---- |
 1502: | 1  | id | bigint | Unique identifier of the user role, generated automatically |
 1503: | 2  | name | character varying | User-friendly short name of the role |
 1504: | 3  | description | character varying | User-friendly, detailed description of the role |
 1505: | 4  | status | character varying | Role status, one of the values ​​"ACTIVE", "DEPRECATED", "DISABLED" |
 1506: | 5  | is\_sys | boolean | If 1, the role is considered system and cannot be deleted or changed. |
 1507: | 6  | version | bigint | Version |
 1508: | 7  | is\_default | boolean | Indicates that the role is default for all employees |
 1509: 
 1510: ## **Table system.role\_permissions**
 1511: 
 1512: Contains privilege assignments to a specific role.
 1513: 
 1514: | Serial number | Designation | Data type | Description |
 1515: | :---- | :---- | :---- | :---- |
 1516: | 1  | role\_id | bigint | Reference to the role for which the privilege is defined |
 1517: | 2  | permission\_id | character varying | A reference to a privilege that is defined for the current role. |
 1518: 
 1519: ## **Table system.schedule**
 1520: 
 1521: Working hours
 1522: 
 1523: | Serial number | Designation | Data type | Description |
 1524: | :---- | :---- | :---- | :---- |
 1525: | 1  | id | bigint | Unique work schedule identifier |
 1526: | 2  | name | character varying | Unique name of the work schedule |
 1527: | 3  | config\_string | character varying | Configuration of work schedule in xml form |
 1528: | 4 | version | bigint | Version |
 1529: | 5  | schedule\_template\_id | bigint | Job Schedule Template ID from schedule\_template |
 1530: | 6  | info | text | Raw data |
 1531: | 7  | info\_json | text | schedule changes in JSON format |
 1532: | 8  | bkp$\_config\_string | character varying | \- |
 1533: | 9  | bkp$\_info | text | \- |
 1534: 
 1535: ## **Table system.schedule\_interval**
 1536: 
 1537: Schedule work interval
 1538: 
 1539: | Serial number | Designation | Data type | Description |
 1540: | :---- | :---- | :---- | :---- |
 1541: | 1  | id | bigint | Unique record identifier |
 1542: | 2  | schedule\_id | bigint | The work schedule to which the interval belongs |
 1543: | 3  | rotation | integer | Team number |
 1544: | 4  | shift\_number | integer | Shift number |
 1545: | 5  | my\_start | timestamp with time zone | Beginning of interval |
 1546: | 6  | max\_start | timestamp with time zone | End of interval |
 1547: | 7  | duration | bigint | Shift duration |
 1548: | 8  | step | bigint | Step in milliseconds (15min or 5min) |
 1549: | 9  | max\_duration | bigint | Maximum shift duration |
 1550: | 10  | additional\_shift | boolean | A sign that this is an extra shift |
 1551: | 11  | adjusted\_duration | bigint | Shift duration in milliseconds, including unpaid breaks |
 1552: | 12  | bkp$\_my\_start | timestamp without time zone | \- |
 1553: | 13  | bkp$\_max\_start | timestamp without time zone | \- |
 1554: | 14  | overtime\_duration\_before\_shift | bigint | Overtime duration before shift in milliseconds |
 1555: | 15  | overtime\_duration\_after\_shift | bigint | Overtime duration after shift in milliseconds |
 1556: | 16 | contract\_id | bigint | Contract identifier from an external system if this shift was created using an exchange |
 1557: 
 1558: ## **Table system.schedule\_planning\_solution**
 1559: 
 1560: A schedule plan based on a template for one or more groups
 1561: 
 1562: | Serial number | Designation | Data type | Description |
 1563: | :---- | :---- | :---- | :---- |
 1564: | 1 | id | bigint | Unique identifier |
 1565: | 2 | template\_id | bigint | The template from which the plan was created |
 1566: | 3 | update\_timestamp | timestamp with time zone | The moment of the last schedule update, used for versioning |
 1567: | 4 | start\_date | date | Start of the schedule period |
 1568: | 5 | end\_date | date | End of schedule period |
 1569: | 6 | comment | character varying | An arbitrary comment describing the schedule. Used to differentiate it from other schedule options. |
 1570: | 7 | config\_string | text | xml configuration used for planning. Includes both Optaplanner settings and weighting factors |
 1571: | 8 | result\_string | text | xml-planning result (last) |
 1572: | 9 | name | character varying | Schedule name |
 1573: | 10 | dtype | character varying | Schedule plan type (OperatingScheduleSolution,Timetable system.cheduleSolution) |
 1574: | 11 | used\_work\_schedule\_templates | boolean | Identify the used work schedule template |
 1575: | 12 | stat\_by\_years\_string | text | \- |
 1576: | 13 | stat\_by\_months\_string | text | \- |
 1577: | 14 | stat\_by\_days\_string | text | \- |
 1578: | 15 | bkp$\_update\_timestamp | timestamp without time zone | \- |
 1579: | 16 | cost | numeric | \- |
 1580: | 17 | parent\_id | bigint | Parent schedule ID |
 1581: | 18 | create\_timestamp | timestamp with time zone | Moment of creation |
 1582: 
 1583: ## **Table system.schedule\_planning\_template**
 1584: 
 1585: Schedule Planning Template
 1586: 
 1587: | Serial number | Designation | Data type | Description |
 1588: | :---- | :---- | :---- | :---- |
 1589: | 1  | id | bigint | Unique identifier |
 1590: | 2  | name | character varying | Template name |
 1591: | 3  | status | character varying | Template Status |
 1592: 
 1593: ## **Таблица system.schedule\_possible\_worker\_schedule\_template**
 1594: 
 1595: Linking the planned work schedule and work schedule templates of the employees who will participate in the planning
 1596: 
 1597: | Serial number | Designation | Data type | Description |
 1598: | :---- | :---- | :---- | :---- |
 1599: | 1  | solution\_id | bigint | Planned Work Schedule Identifier |
 1600: | 2  | schedule\_template\_id | bigint | Identifiers of work schedule templates that participate in planning |
 1601: 
 1602: ## **Table system.schedule\_solution\_schedule\_template**
 1603: 
 1604: Linking the planned work schedule and schedule templates that were additionally specified before planning
 1605: 
 1606: | Serial number | Designation | Data type | Description |
 1607: | :---- | :---- | :---- | :---- |
 1608: | 1  | solution\_id | bigint | Planned Work Schedule Identifier |
 1609: | 2  | schedule\_template\_id | bigint | Identifier of work schedule templates that we additionally specify during planning |
 1610: 
 1611: ## **Table system.schedule\_template**
 1612: 
 1613: Work Schedule Template
 1614: 
 1615: | Serial number | Designation | Data type | Description |
 1616: | :---- | :---- | :---- | :---- |
 1617: | 1  | id | bigint | Template ID |
 1618: | 2  | name | character varying | Template name |
 1619: | 3  | config\_string | character varying | template config (with frequency of changes/rotations, etc.) |
 1620: | 4  | status | character varying | template status (active/deactivated) |
 1621: | 5  | breaks\_config | text | Configure the PSU for the template |
 1622: | 6  | bkp$\_config\_string | character varying | \- |
 1623: 
 1624: ## **Table system.scheme\_vacation**
 1625: 
 1626: Vacation schemes
 1627: 
 1628: | Serial number | Designation | Data type | Description |
 1629: | :---- | :---- | :---- | :---- |
 1630: | 1  | id | bigint | Unique record identifier |
 1631: | 2  | name | character varying | Record Title |
 1632: | 3  | config\_string | text | Configuration in which we store the duration of vacations |
 1633: 
 1634: ## **System.service table**
 1635: 
 1636: Service in call center terms. Contains one or more groups
 1637: 
 1638: | Serial number | Designation | Data type | Description |
 1639: | :---- | :---- | :---- | :---- |
 1640: | 1  | id | bigint | Unique service identifier |
 1641: | 2  | name | character varying | Name of the service |
 1642: | 3  | description | character varying | Description of service |
 1643: | 4  | foreign\_id | text | External system identifier for integration |
 1644: | 5  | status | character varying | Status |
 1645: | 6  | version | bigint | Version |
 1646: | 7  | system\_id | integer | External system identifier |
 1647: 
 1648: ## **The system.service\_group table**
 1649: 
 1650: Service-Group Interchange
 1651: 
 1652: | Serial number | Designation | Data type | Description |
 1653: | :---- | :---- | :---- | :---- |
 1654: | 1  | service\_id | bigint | The service the group is a part of |
 1655: | 2  | group\_id | bigint | Group included in the service |
 1656: 
 1657: ## **Table system.service\_group\_plan**
 1658: 
 1659: A group work plan for a specific forecast within the schedule
 1660: 
 1661: | Serial number | Designation | Data type | Description |
 1662: | :---- | :---- | :---- | :---- |
 1663: | 1  | id | bigint | Unique identifier |
 1664: | 2  | solution\_id | bigint | Schedule plan ID from schedule\_planning\_solution |
 1665: | 3  | service\_id | bigint | Service ID |
 1666: | 4  | group\_id | bigint | Group ID |
 1667: | 5  | stat\_by\_years\_string | text | \- |
 1668: | 6  | stat\_by\_months\_string | text | \- |
 1669: | 7  | stat\_by\_days\_string | text | \- |
 1670: 
 1671: ## **Table system.shift\_break**
 1672: 
 1673: Entry from the Lunch and Break Directory Scheme
 1674: 
 1675: | Serial number | Designation | Data type | Description |
 1676: | ----- | ----- | ----- | ----- |
 1677: | 1  | id | bigint | Unique record identifier |
 1678: | 2  | shift\_breaks\_config\_id | bigint | Unique record identifier |
 1679: | 3  | my\_start | bigint | Minimum start of break interval relative to shift start in ms |
 1680: | 4  | max\_start | bigint | Maximum start of break interval relative to shift start in ms |
 1681: | 5  | shift\_type | character varying | Day or night |
 1682: | 6  | is\_payable | boolean | Is the interval paid? |
 1683: | 7  | duration | bigint | Duration in ms |
 1684: | 8  | word\_num | bigint | Serial number |
 1685: | 9  | interval\_type | character varying | Interval type |
 1686: 
 1687: ## **Table system.shift\_breaks\_config**
 1688: 
 1689: Lunch and Break Configuration Handbook
 1690: 
 1691: | Serial number | Designation | Data type | Description |
 1692: | :---- | :---- | :---- | :---- |
 1693: | 1  | id | bigint | Unique record identifier |
 1694: | 2  | worker\_id | bigint | Employee |
 1695: | 3  | min\_shift\_duration | bigint | Minimum shift duration in ms |
 1696: | 4  | max\_shift\_duration | bigint | Maximum shift duration in ms |
 1697: | 5  | shift\_type | character varying | Shift type |
 1698: | 6  | breaks\_order\_type | character varying | Type of lunch and break order |
 1699: | 7  | min\_day\_duration | bigint | Minimum daily shift duration in ms |
 1700: | 8  | max\_day\_duration | bigint | Maximum daily shift duration in ms |
 1701: | 9  | min\_night\_duration | bigint | Minimum night shift duration in ms |
 1702: | 10  | max\_night\_duration | bigint | Maximum night shift duration in ms |
 1703: | 11  | min\_break\_distance | bigint | Minimum time without interruption in ms |
 1704: | 12  | max\_break\_distance | bigint | Maximum time without interruption in ms |
 1705: 
 1706: ## **Table system.solution\_apply\_range**
 1707: 
 1708: Periods of solution activity
 1709: 
 1710: | Serial number | Designation | Data type | Description |
 1711: | :---- | :---- | :---- | :---- |
 1712: | 1  | solution\_id | bigint | Solution ID |
 1713: | 2  | start\_date | date | Beginning of the period |
 1714: | 3  | end\_date | date | End of the period |
 1715: 
 1716: ## **Table system.statistic\_indicator**
 1717: 
 1718: Call Service Statistical Indicators
 1719: 
 1720: | Serial number | Designation | Data type | Description |
 1721: | :---- | :---- | :---- | :---- |
 1722: | 1  | id | bigint | Unique indicator identifier |
 1723: | 2  | name | text | Unique indicator code |
 1724: | 3  | is\_sys | boolean | System entry flag |
 1725: 
 1726: ## **Table system.statuses\_vw**
 1727: 
 1728: Status information
 1729: 
 1730: | Serial number | Designation | Data type | Description |
 1731: | ----- | ----- | ----- | ----- |
 1732: | 1 | state\_id | character varying | Status ID |
 1733: | 2 | state\_name | character varying | Status name |
 1734: | 3 | system\_id | character varying | External system identifier |
 1735: | 4 | is\_productive | boolean | Is the current status productive time? |
 1736: | 5 | is\_work\_load | boolean | Is the current status a net load? |
 1737: | 6 | absence | boolean | Is the current status time away? |
 1738: | 7 | is\_talk\_time | boolean | Checkbox "Talk time" |
 1739: | 8 | is\_break | boolean | Cheboks "Break Time" |
 1740: | 9 | is\_fact\_time | boolean | Actual time indicator in the timesheet |
 1741: | 10 | is\_productive\_work\_time | boolean | Signs of a productive working time |
 1742: | 11 | is\_after\_call\_work | boolean | Post-call processing |
 1743: | 12 | is\_operator\_active | boolean | Operator active and on lines |
 1744: 
 1745: ## **The system.system\_timezone table**
 1746: 
 1747: | Serial number | Designation | Data type | Description |
 1748: | :---- | :---- | :---- | :---- |
 1749: | 1  | zone\_id | character varying | \- |
 1750: | 2  | zone\_display\_name | character varying | \- |
 1751: 
 1752: ## **Table system.template\_service\_group**
 1753: 
 1754: Service-Group Decoupling in Schedule Planning Template
 1755: 
 1756: | Serial number | Designation | Data type | Description |
 1757: | :---- | :---- | :---- | :---- |
 1758: | 1  | template\_id | bigint | Schedule Planning Template |
 1759: | 2  | service\_id | bigint | Service |
 1760: | 3  | group\_id | bigint | Group |
 1761: 
 1762: ## **Table system.threshold\_index**
 1763: 
 1764: Threshold values ​​of operational indicators
 1765: 
 1766: | Serial number | Designation | Data type | Description |
 1767: | :---- | :---- | :---- | :---- |
 1768: | 1  | id | bigint | Unique identifier of the load for a specific interval |
 1769: | 2  | description | character varying | Name of the indicator |
 1770: | 3  | bound\_crit\_upturn\_threshold | integer | Critical threshold value when the indicator increases |
 1771: | 4  | bound\_crit\_downturn\_threshold | integer | Critical threshold value when the indicator declines |
 1772: | 5  | bound\_acceptable\_upturn\_threshold | integer | Acceptable threshold value for growth of the indicator |
 1773: | 6  | bound\_acceptable\_downturn\_threshold | integer | Acceptable threshold value when the indicator declines |
 1774: | 7  | group\_id | integer | Unique identifier of the operator group to which the indicator belongs |
 1775: | 8  | service\_id | integer | Unique identifier of the service to which the metric belongs |
 1776: 
 1777: ## **Table system.type\_property**
 1778: 
 1779: Stores a list of incoming report parameters
 1780: 
 1781: | Serial number | Designation | Data type | Description |
 1782: | :---- | :---- | :---- | :---- |
 1783: | 1  | id | bigint | Parameter ID |
 1784: | 2  | holder\_id | bigint | Holder ID |
 1785: | 3  | keyword | character varying | A keyword that is referenced in the report itself in query |
 1786: | 4  | dtype | character varying | Parameter data type (text/date, etc.) |
 1787: | 5  | name | character varying | Parameter name |
 1788: | 6  | description | character varying | Parameter Description |
 1789: | 7  | status | character varying | Parameter status |
 1790: | 8  | version | bigint | Parameter version |
 1791: | 9  | hint | character varying | A tooltip that appears when you hover over a parameter name when creating a report. |
 1792: | 10  | required | boolean | Checkbox "Required" |
 1793: | 11  | readonly | boolean | Checkbox "Read only" (not set in reports) |
 1794: | 12  | secured | boolean | The parameter becomes protected and cannot be read or written to, not the name of a specific access right. |
 1795: | 13  | indexed | boolean | Parameter indexed |
 1796: | 14  | filtered | boolean | The parameter is used for filtering. |
 1797: | 15  | statical | boolean | The parameter is read-only. |
 1798: | 16  | sys | boolean | Is it a system parameter (not specified in the report) |
 1799: | 17  | txt\_default | character varying | The default parameter value |
 1800: | 18  | txt\_pattern | character varying | The default parameter template |
 1801: | 19  | txt\_lines | integer | Number of lines for text input for a parameter with the type "text" |
 1802: | 20  | double\_default | double precision | Default dotted number |
 1803: | 21  | double\_min\_value | double precision | Minimum value of a digit with a dot |
 1804: | 22  | double\_max\_value | double precision | Maximum value of a digit with a dot |
 1805: | 23  | double\_precision | integer | Precision after decimal point for digit with dot |
 1806: | 24  | bool\_default | boolean | Default checkbox for type "Boolean" |
 1807: | 25  | date\_pattern | character varying | Parameter date format for type "Date" |
 1808: | 26  | date\_default | timestamp with time zone | Default date for type "Date" |
 1809: | 27  | date\_default\_start | timestamp with time zone | Date from: default |
 1810: | 28  | date\_default\_end | timestamp with time zone | Date by: default |
 1811: | 29  | ordinal\_number | integer | Parameter order |
 1812: | 30  | long\_default | bigint | Default long format number |
 1813: | 31  | long\_min\_value | bigint | Minimum number of long format |
 1814: | 32  | long\_max\_value | bigint | Maximum number of long format |
 1815: | 33  | unique | boolean | Should the parameter be unique? |
 1816: | 34  | txtarr\_default | ARRAY | Array of default text values |
 1817: | 35  | lkparr\_default | ARRAY | User guide with multi-selection |
 1818: | 36  | group\_id | bigint | ID of the parameter group to which this parameter belongs from type\_property\_group |
 1819: | 37  | hidden | boolean | Hidden (not used in reports) |
 1820: | 38  | bkp$\_date\_default | timestamp without time zone | \- |
 1821: | 39  | bkp$\_date\_default\_start | timestamp without time zone | \- |
 1822: | 40  | bkp$\_date\_default\_end | timestamp without time zone | \- |
 1823: | 41  | query | text | Request text |
 1824: 
 1825: ## **The system.type\_property\_group table**
 1826: 
 1827: Stores groups of type\_property parameters
 1828: 
 1829: | Serial number | Designation | Data type | Description |
 1830: | :---- | :---- | :---- | :---- |
 1831: | 1  | id | bigint | Parameter group ID |
 1832: | 2  | keyword | character varying | Keyword |
 1833: | 3  | name | character varying | Name |
 1834: | 4  | description | character varying | Description |
 1835: | 5  | status | character varying | Status |
 1836: | 6  | ordinal\_number | integer | Order of parameter group |
 1837: | 7  | holder\_id | bigint | Holder ID |
 1838: | 8  | version | bigint | Version |
 1839: 
 1840: ## **Table system.type\_property\_holder**
 1841: 
 1842: Holder for parameters, includes parameters from type\_property
 1843: 
 1844: | Serial number | Designation | Data type | Description |
 1845: | :---- | :---- | :---- | :---- |
 1846: | 1  | id | bigint | Holder ID |
 1847: | 2  | keyword | character varying | Keyword |
 1848: | 3  | name | character varying | Name |
 1849: | 4  | description | character varying | Description |
 1850: | 5  | status | character varying | Status |
 1851: | 6  | version | bigint | Version |
 1852: 
 1853: ## **Table system.unpaid\_break\_rules**
 1854: 
 1855: Unpaid breaks from "Labor Standards"
 1856: 
 1857: | Serial number | Designation | Data type | Description |
 1858: | :---- | :---- | :---- | :---- |
 1859: | 1  | id | bigint | ID records |
 1860: | 2  | my\_shift | bigint | Minimum shift time (shift duration) |
 1861: | 3  | type | character varying | Shift type |
 1862: | 4  | max\_shift | bigint | Maximum shift time (shift duration) |
 1863: | 5  | max\_day\_duration | bigint | Minimum duration of day shift |
 1864: | 6  | min\_day\_duration | bigint | Maximum duration of day shift |
 1865: | 7  | min\_night\_duration | bigint | Minimum duration of night shift |
 1866: | 8  | max\_night\_duration | bigint | Maximum duration of night shift |
 1867: | 9  | day\_break | bigint | Day break |
 1868: | 10  | night\_break | bigint | Night break |
 1869: 
 1870: ## **Table system.user\_request**
 1871: 
 1872: User requests
 1873: 
 1874: | Serial number | Designation | Data type | Description |
 1875: | :---- | :---- | :---- | :---- |
 1876: | 1  | id | bigint | Application ID |
 1877: | 2  | create\_timestamp | timestamp with time zone | Date of application creation |
 1878: | 3  | author\_id | bigint | Requester ID |
 1879: | 4  | state | character varying | Application status |
 1880: | 5  | dtype | character varying | Application type |
 1881: | 6  | parent\_id | bigint | Identifier of the request originator |
 1882: | 7  | source\_start | timestamp with time zone | Initial time of the event start |
 1883: | 8  | expected\_start | date | The date to which the transfer is expected |
 1884: | 9  | supervisor\_id | bigint | ID of the manager who confirmed the application |
 1885: | 10  | worker\_from\_id | bigint | ID of the employee who created the request |
 1886: | 11  | worker\_to\_id | bigint | ID of the employee who accepted the application |
 1887: | 12  | vacation\_transfer\_id | bigint | Vacation ID to transfer |
 1888: | 13  | vacation\_from\_id | bigint | Sender's side leave ID |
 1889: | 14  | vacation\_to\_id | bigint | Recipient Party Leave Identifier |
 1890: | 15  | schedule\_interval\_transfer\_id | bigint | Shift ID to transfer |
 1891: | 16  | schedule\_interval\_from\_id | bigint | Sender side change identifier |
 1892: | 17  | schedule\_interval\_to\_id | bigint | Recipient Party Change Identifier |
 1893: | 18 | expected\_time\_start | time without time zone | Expected time of event |
 1894: 
 1895: ## **Table system.user\_schedule\_planning\_config**
 1896: 
 1897: Stored User Scheduling Settings
 1898: 
 1899: | Serial number | Designation | Data type | Description |
 1900: | :---- | :---- | :---- | :---- |
 1901: | 1  | id | bigint | Unique identifier |
 1902: | 2  | name | character varying | Configuration name |
 1903: | 3  | description | character varying | Description of the config |
 1904: | 4  | config\_string | text | xml configuration used for planning. Includes both Optaplanner settings and weighting factors |
 1905: | 5  | version | integer | Version |
 1906: 
 1907: ## **Table system.wish\_access**
 1908: 
 1909: Preferences Setting Reference
 1910: 
 1911: | Serial number | Designation | Data type | Description |
 1912: | :---- | :---- | :---- | :---- |
 1913: | 1 | id | bigint | \- |
 1914: | 2 | wish\_name | character varying | Name for preference setting |
 1915: | 3 | time\_zone | character varying | Time zone of the period when operators have the opportunity to enter preferences |
 1916: | 4 | open\_date\_time | timestamp with time zone | The beginning of the period when operators have the opportunity to enter preferences |
 1917: | 5 | closed\_date\_time | timestamp with time zone | End of the period when operators have the opportunity to enter preferences |
 1918: | 6 | start\_date | date | Start of the period for which operators can enter preferences |
 1919: | 7 | end\_date | date | End of the period for which operators can enter preferences |
 1920: | 8 | limit\_normal\_wish | integer | The maximum number of normal preferences an operator can enter |
 1921: | 9 | limit\_priority\_wish | integer | The maximum number of preferences that an operator can mark as a priority |
 1922: 
 1923: ## **Table system.wish\_access\_worker**
 1924: 
 1925: Preferences Settings Reference Table
 1926: 
 1927: | Serial number | Designation | Data type | Description |
 1928: | :---- | :---- | :---- | :---- |
 1929: | 1 | id | bigint | \- |
 1930: | 2 | worker\_id | bigint | Preference |
 1931: | 3 | wish\_access\_id | bigint | \- |
 1932: 
 1933: ## **Table system.work\_hours**
 1934: 
 1935: Handbook "Accounting of working hours"
 1936: 
 1937: | Serial number | Designation | Data type | Description |
 1938: | ----- | ----- | ----- | ----- |
 1939: | 1  | id | bigint | Unique identifier |
 1940: | 2  | plan\_interval\_type | character varying | The type of interval to be taken into account |
 1941: | 3  | service\_id | bigint | Service |
 1942: | 4  | operator\_type | character varying | Operator type |
 1943: | 5  | pay\_type\_id | bigint | Payment type |
 1944: | 6  | productivity | boolean | What hours to consider when calculating output |
 1945: | 7  | payment | boolean | What hours to consider when calculating payment |
 1946: 
 1947: ## **Table system.work\_rule**
 1948: 
 1949: Rules of work
 1950: 
 1951: | Serial number | Designation | Data type | Description |
 1952: | ----- | ----- | ----- | ----- |
 1953: | 1 | id | bigint | Rule ID |
 1954: | 2 | status | character varying | Activity status |
 1955: | 3 | with\_rotation | boolean | With or without rotation |
 1956: | 4 | config\_string | text | Rules configuration string in JSON format |
 1957: | 5 | name | character varying | Rule name |
 1958: | 6 | version | bigint | \- |
 1959: | 7 | production\_calendar | boolean | production calendar accounting flag |
 1960: | 8 | time\_zone | character varying | The time zone for which the work rule was assigned |
 1961: | 9 | used\_when\_planning\_vacancies | boolean | Can it be selected when planning vacancies? |
 1962: 
 1963: ## **Table system.work\_rule\_designation**
 1964: 
 1965: Assigning work rules to operators
 1966: 
 1967: | Serial number | Designation | Data type | Description |
 1968: | ----- | ----- | ----- | ----- |
 1969: | 1 | id | bigint | Assignment Record ID |
 1970: | 2 | worker\_id | bigint | Operator ID |
 1971: | 3 | work\_rule\_id | bigint | Work rule identifier |
 1972: | 4 | config\_string | text | \- |
 1973: | 5 | start\_date | date | Start period rules |
 1974: | 6 | end\_date | date | End of the rule validity period |
 1975: | 7 | version | bigint | \- |
 1976: 
 1977: ## **system.worker table**
 1978: 
 1979: Call center employee
 1980: 
 1981: | Serial number | Designation | Data type | Description |
 1982: | :---- | :---- | :---- | :---- |
 1983: | 1 | id | bigint | Unique employee identifier |
 1984: | 2 | is\_sys | boolean | Is the employee systemic? |
 1985: | 3 | tab\_no | character varying | Employee ID number |
 1986: | 4 | first\_name | character varying | Employee name |
 1987: | 5 | second\_name | character varying | Employee's patronymic |
 1988: | 6 | last\_name | character varying | Employee's last name |
 1989: | 7 | operator\_type | character varying | Operator type (home or office) |
 1990: | 8 | status | character varying | Record status (active or not) |
 1991: | 9 | breaks\_config | text | Configuration of employee breaks in xml format |
 1992: | 10 | version | bigint | Version |
 1993: | 11 | skill\_level | character varying | Employee skill level |
 1994: | 12 | can\_speak\_english | boolean | Does the employee speak a foreign language? |
 1995: | 13 | norm\_hours\_config | text | Configuration of the employee's production standard in xml format |
 1996: | 14 | foreign\_id | text | External system identifier for integration |
 1997: | 15 | telegram\_chat\_id | bigint | ID of the chat in telegram with the bot WfmCc |
 1998: | 16 | pay\_type\_id | integer | Employee payment type |
 1999: | 17 | is\_night\_work | boolean | Sign of work at night |
 2000: | 18 | norm\_day | bigint | Standard hours per day |
 2001: | 19 | norm\_week | bigint | Standard hours per week |
 2002: | 20 | employee\_rate | real | Bid |
 2003: | 21 | vacation\_config | text | vacation business rules settings |
 2004: | 22 | can\_work\_at\_weekends | boolean | An indication that a worker can work on weekends |
 2005: | 23 | can\_work\_over\_time | boolean | A sign that a worker may work overtime |
 2006: | 24 | employment | date | Date of employment |
 2007: | 25 | dismissal | date | Date of dismissal |
 2008: | 26 | accumulated\_vacation\_days | text | Accumulated vacation days |
 2009: | 27 | department\_id | bigint | Subdivision |
 2010: | 28 | position\_id | bigint | Job title |
 2011: | 29 | bkp$\_norm\_hours\_config | character varying | \- |
 2012: | 30 | time\_zone | character varying | Employee time zone |
 2013: | 31 | bkp$\_accumulated\_vacation\_days | character varying | \- |
 2014: | 32 | cost | numeric | Cost of an employee's hour of work |
 2015: | 33 | comment | character varying | \- |
 2016: | 34 | sn | character varying | Operator ID in lk |
 2017: | 35 | db\_id | character varying | Master system identifier in lk |
 2018: | 36 | area\_id | bigint | Name of the site in lk |
 2019: 
 2020: ## **Table system.worker\_actual\_kpi**
 2021: 
 2022: Up-to-date information on KPI indicators for operators
 2023: 
 2024: | Serial number | Designation | Data type | Description |
 2025: | :---- | :---- | :---- | :---- |
 2026: | 1  | worker\_id | bigint | Unique employee identifier in the system |
 2027: | 2  | aht | integer | Average operator talk time in milliseconds, obtained using the integration method |
 2028: 
 2029: ## **Table system. worker\_actual\_schedules\_vw**
 2030: 
 2031: Changes in current employee schedules
 2032: 
 2033: | Serial number | Designation | Data type | Description |
 2034: | :---- | :---- | :---- | :---- |
 2035: | 1 | worker\_id | bigint | Employee ID |
 2036: | 2 | worker\_tz | character varying | Employee time zone |
 2037: | 3 | sol\_id | bigint | Employee Schedule Solution ID |
 2038: | 4 | sol\_template\_id | bigint | Employee Schedule Planning Template ID |
 2039: | 5 | sol\_interval\_duration | bigint | IntervalDuration of employee schedule |
 2040: | 6 | psd\_id | bigint | Employee Schedule PSD ID |
 2041: | 7 | psd\_start\_date | date | Schedule start date |
 2042: | 8 | psd\_end\_date\_exclusive | date | Schedule end date (exclusive) |
 2043: | 9 | and\_id | bigint | Employee schedule shift ID |
 2044: | 10 | si\_duration | bigint | Basic shift duration, msec |
 2045: | 11 | si\_adjusted\_duration | bigint | Shift duration with unpaid lunches and breaks, msec |
 2046: | 12 | si\_overtime\_duration\_before\_shift | bigint | Overtime shift duration before the main shift time, msec |
 2047: | 13 | si\_overtime\_duration\_after\_shift | bigint | Overtime shift duration after main shift time, msec |
 2048: | 14 | say\_my\_start | timestamp with time zone | Minimum start time of the main work of the shift |
 2049: | 15 | si\_max\_start | timestamp with time zone | Maximum start time of the main work of the shift |
 2050: | 16 | si\_start\_with\_overtime | timestamp with time zone | Shift start time including overtime |
 2051: | 17 | si\_duration\_with\_overtime | bigint | Shift duration including overtime, msec |
 2052: | 18 | si\_min\_end\_exclusive | timestamp with time zone | Shift end time from minimum shift start time for main duration |
 2053: | 19 | si\_end\_with\_overtime\_exclusive | timestamp with time zone | Shift end time from minimum shift start time taking into account overtime |
 2054: | 20 | si\_with\_overtime | boolean | Sign whether the shift is with overtime or not |
 2055: | 21 | si\_additional | boolean | Sign, additional shift or not |
 2056: 
 2057: ## **Table system.worker\_actual\_status**
 2058: 
 2059: Information about the current status of the operator
 2060: 
 2061: | Serial number | Designation | Data type | Description |
 2062: | :---- | :---- | :---- | :---- |
 2063: | 1  | worker\_id | bigint | Unique employee identifier |
 2064: | 2  | operator\_state\_id | bigint | Current employee status identifier (according to data from the CSO) |
 2065: | 3  | last\_online\_time | timestamp with time zone | The time when the operator was last on the line (according to the current status) |
 2066: | 4  | seconds\_in\_state | bigint | The time the operator has been in the current status in seconds |
 2067: | 5  | last\_update\_time | timestamp with time zone | Time of last status request |
 2068: | 6  | bkp$\_last\_online\_time | timestamp without time zone | \- |
 2069: | 7  | bkp$\_last\_update\_time | timestamp without time zone | \- |
 2070: 
 2071: ## **Table system.worker\_change\_status\_log**
 2072: 
 2073: Information about the operator's status as a Call Center
 2074: 
 2075: | Serial number | Designation | Data type | Description |
 2076: | :---- | :---- | :---- | :---- |
 2077: | 1  | worker\_id | bigint | Operator |
 2078: | 2  | state\_id | bigint | Status type |
 2079: | 3  | date\_from | timestamp with time zone | The time when the operator started being in the current status |
 2080: | 4  | date\_to | timestamp with time zone | End time of the operator's current status |
 2081: | 5  | system\_id | bigint | External system identifier |
 2082: | 6  | bkp$\_date\_from | timestamp without time zone | \- |
 2083: | 7  | bkp$\_date\_to | timestamp without time zone | \- |
 2084: | 8  | foreign\_login\_id | text | External employee identifier |
 2085: 
 2086: ## **Table system.worker\_contact**
 2087: 
 2088: Employee-contact denouement
 2089: 
 2090: | Serial number | Designation | Data type | Description |
 2091: | :---- | :---- | :---- | :---- |
 2092: | 1  | worker\_id | bigint | Employee with contact |
 2093: | 2  | contact\_id | bigint | Employee contact |
 2094: 
 2095: ## **Table system.worker\_foreign\_login**
 2096: 
 2097: Linking a worker and its logins to external integration systems
 2098: 
 2099: | Serial number | Designation | Data type | Description |
 2100: | :---- | :---- | :---- | :---- |
 2101: | 1  | login\_foreign\_id | text | External account foreign\_id |
 2102: | 2  | system\_id | bigint | Accounting system |
 2103: | 3  | worker\_id | bigint | Worker |
 2104: | 4  | login\_name | text | Account name |
 2105: 
 2106: ## **Table system.worker\_foreign\_login\_group**
 2107: 
 2108: Interchange worker\_foreign\_login \- group
 2109: 
 2110: | Serial number | Designation | Data type | Description |
 2111: | :---- | :---- | :---- | :---- |
 2112: | 1  | foreign\_id | text | External account id |
 2113: | 2  | system\_id | bigint | Accounting system |
 2114: | 3  | group\_id | bigint | Accounting group |
 2115: 
 2116: ## **Table system.worker\_historic\_status**
 2117: 
 2118: Table storing the statuses of operators received from integration systems
 2119: 
 2120: | Serial number | Designation | Data type | Description |
 2121: | :---- | :---- | :---- | :---- |
 2122: | 1  | worker\_id | bigint | ID worker а |
 2123: | 2  | service\_id | bigint | Service ID |
 2124: | 3  | group\_id | bigint | Group ID |
 2125: | 4  | state\_id | bigint | Integration system status ID |
 2126: | 5  | date\_from | timestamp with time zone | Status start date |
 2127: | 6  | date\_to | timestamp with time zone | Status End Date |
 2128: | 7  | duration\_in\_state | bigint | Time spent in status |
 2129: | 8  | bkp$\_date\_from | timestamp without time zone | \- |
 2130: | 9  | bkp$\_date\_to | timestamp without time zone | \- |
 2131: | 10 | system\_id | integer | \- |
 2132: | 11 | id | integer | \- |
 2133: 
 2134: ## **Table system.worker\_historical\_fact**
 2135: 
 2136: Historical fact about the employee
 2137: 
 2138: | Serial number | Designation | Data type | Description |
 2139: | :---- | :---- | :---- | :---- |
 2140: | 1  | worker\_id | bigint | Employee |
 2141: | 2  | creation\_date | timestamp with time zone | Time of change |
 2142: | 3  | fact\_type | text | Type of change |
 2143: | 4  | new\_value | text | New meaning |
 2144: | 5  | initiator | text | Change initiator |
 2145: | 6  | id | bigint | ID records |
 2146: | 7  | bkp$\_creation\_date | timestamp without time zone | \- |
 2147: 
 2148: ## **Table system.worker\_icon**
 2149: 
 2150: Employee icon
 2151: 
 2152: | Serial number | Designation | Data type | Description |
 2153: | :---- | :---- | :---- | :---- |
 2154: | 1  | worker\_id | bigint | Employee ID |
 2155: | 2  | photo | bytea | Icon |
 2156: 
 2157: ## **Table system.worker\_monitoring\_config**
 2158: 
 2159: Configuration of display of monitoring widgets for operators
 2160: 
 2161: | Serial number | Designation | Data type | Description |
 2162: | :---- | :---- | :---- | :---- |
 2163: | 1  | worker\_id | bigint | Operator ID |
 2164: | 2  | service\_id | bigint | Service identifier |
 2165: | 3  | group\_id | bigint | Group ID |
 2166: | 4  | statistic\_indicator\_id | bigint | Statistical indicator identifier |
 2167: | 5  | is\_notification | boolean | Notifying the operator about changes in this indicator |
 2168: 
 2169: ## **Table system.worker\_position**
 2170: 
 2171: History of the positions of co-workers
 2172: 
 2173: | Serial number | Designation | Data type | Description |
 2174: | :---- | :---- | :---- | :---- |
 2175: | 1  | id | bigint | Unique record identifier |
 2176: | 2  | worker\_id | bigint | Employee |
 2177: | 3  | position\_id | bigint | Job title |
 2178: | 4  | change\_date | date | Date of change of position |
 2179: 
 2180: ## **Table system.worker\_role**
 2181: 
 2182: Assigning a role to an employee
 2183: 
 2184: | Serial number | Designation | Data type | Description |
 2185: | :---- | :---- | :---- | :---- |
 2186: | 1  | worker\_id | bigint | Employee wanted |
 2187: | 2  | role\_id | bigint | Assigned role |
 2188: 
 2189: ## **Table system.worker\_schedule**
 2190: 
 2191: Assigning a work schedule to an employee
 2192: 
 2193: | Serial number | Designation | Data type | Description |
 2194: | :---- | :---- | :---- | :---- |
 2195: | 1  | id | bigint | Unique record identifier |
 2196: | 2  | worker\_id | bigint | Employee |
 2197: | 3  | schedule\_id | bigint | Work schedule assigned to an employee |
 2198: | 4  | rotation | integer | The number of the team in which the employee works |
 2199: | 5  | valid\_from | date | Start of the schedule period for this employee |
 2200: | 6  | valid\_to | date | End of the schedule period for this employee |
 2201: 
 2202: ## **Table system.worker\_schedule\_event**
 2203: 
 2204: Special Employee Event
 2205: 
 2206: | Serial number | Designation | Data type | Description |
 2207: | :---- | :---- | :---- | :---- |
 2208: | 1 | id | bigint | Unique record identifier |
 2209: | 2 | worker\_id | bigint | Employee |
 2210: | 3 | start\_timestamp | timestamp with time zone | The moment the event starts |
 2211: | 4 | end\_timestamp | timestamp with time zone | The moment the event ends |
 2212: | 5 | event\_type | character varying | Event type |
 2213: | 6 | comment | character varying | Free commentary on the event |
 2214: | 7 | dtype | character varying | Entity Discriminator |
 2215: | 8 | scheme\_vacation\_id | bigint | Dismissal scheme |
 2216: | 9 | pinned | boolean | Fixed event (does not move when scheduling) |
 2217: | 10 | priority | boolean | Priority for planning |
 2218: | 11 | status | character varying | Event status (active/inactive) |
 2219: | 12 | schedule\_designation\_id | bigint | Assignment to employee |
 2220: | 13 | absent\_reason\_id | bigint | Reason for absence |
 2221: | 14 | bkp$\_start\_timestamp | timestamp without time zone | \- |
 2222: | 15 | bkp$\_end\_timestamp | timestamp without time zone | \- |
 2223: | 16 | duration\_in\_days | bigint | Duration of vacation in days |
 2224: | 17 | number\_of\_holidays | bigint | Number of holidays |
 2225: 
 2226: ## **Table system.worker\_scheme\_vacation**
 2227: 
 2228: Employee Interchange \- Vacation Scheme
 2229: 
 2230: | Serial number | Designation | Data type | Description |
 2231: | ----- | ----- | ----- | ----- |
 2232: | 1  | worker\_id | bigint | Employee |
 2233: | 2  | scheme\_vacation\_id | bigint | Scheme |
 2234: | 3  | is\_main | boolean | Basic scheme |
 2235: 
 2236: ## **Table system.worker\_timesheet\_status**
 2237: 
 2238: Entity describing changes to the timesheet
 2239: 
 2240: | Serial number | Designation | Data type | Description |
 2241: | :---- | :---- | :---- | :---- |
 2242: | 1  | id | bigint | Unique identifier |
 2243: | 2  | change\_time | timestamp with time zone | Time of change |
 2244: | 3  | change\_worker\_id | bigint | The employee who made the changes |
 2245: | 4  | worker\_id | bigint | Employee |
 2246: | 5  | foreign\_id | text | Employee in the integration system |
 2247: | 6  | record\_date | timestamp with time zone | The date for which the information was saved |
 2248: | 7  | status | character varying | Status |
 2249: | 8  | comment | text | Comment |
 2250: | 9  | bkp$\_change\_time | timestamp without time zone | \- |
 2251: | 10  | bkp$\_record\_date | timestamp without time zone | \- |
 2252: 
 2253: ## **Table system. worker\_wish**
 2254: 
 2255: Table with entered user preferences
 2256: 
 2257: | Serial number | Designation | Data type | Description |
 2258: | :---- | :---- | :---- | :---- |
 2259: | 1 | id | bigint | \- |
 2260: | 2 | worker\_id | bigint | Preference related operator |
 2261: | 3 | wish\_access\_id | bigint | Preference |
 2262: | 4 | wish\_date | date | The date on which the operator sets the preference |
 2263: | 5 | wish\_day\_type | character varying | Day type \- working day or day off |
 2264: | 6 | start\_interval\_min | bigint | Minimum shift start time in milliseconds from the start of the day |
 2265: | 7 | start\_interval\_max | bigint | Maximum shift start time in milliseconds from the start of the day |
 2266: | 8 | end\_interval\_min | bigint | Minimum shift end time in milliseconds from the start of the day |
 2267: | 9 | end\_interval\_max | bigint | Maximum shift end time in milliseconds from the start of the day |
 2268: | 10 | duration\_interval\_min | bigint | Minimum shift duration in milliseconds |
 2269: | 11 | duration\_interval\_max | bigint | Maximum shift duration in milliseconds |
 2270: | 12 | priority | boolean | Priority Preference or Normal |
 2271: 
 2272: ## **Table system.x\_clear\_log**
 2273: 
 2274: Log cleaning of obsolete data
 2275: 
 2276: | Serial number | Designation | Data type | Description |
 2277: | :---- | :---- | :---- | :---- |
 2278: | 1  | executed\_at | timestamp without time zone | Cleaning start time |
 2279: | 2  | table\_name | text | Clearable table |
 2280: | 3  | execution\_time | interval | Cleaning duration |
 2281: | 4  | rows\_affected | bigint | Records removed |
 2282: | 5  | error\_msg | text | Error message |
 2283: 
