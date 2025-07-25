

## **Table system.absent\_reason**

Reasons for absence

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint |  |
| 2 | name | text | Status |
| 3 | description | text | Description |
| 4 | status | text | Status records |
| 5 | use\_in\_absenteeism\_report | boolean | \- |

	

## **Table system.absenteeism**

Handbook "Percentage of Absenteeism"

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint |  |
| 2 | period | int8range | The period for which the absence percentage applies |
| 3 | abs | double precision | percentage of absence |

## **Table system.actual\_load\_interval**

Actual load data for a specific time interval

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Unique identifier |
| 2 | start\_timestamp | timestamp with time zone | Beginning of the period |
| 3 | end\_timestamp | timestamp with time zone | End of the period |
| 4 | call\_number | integer | Number of calls |
| 5 | operator\_number | integer | Number of operators |
| 6 | average\_call\_duration | integer | Average call handling time |
| 7 | service\_level | integer | Quality of service |
| 8 | required\_operator\_number | integer | How many operators are needed to maintain the required service level? |
| 9 | forecast\_start | timestamp with time zone | Time to call getOnlineLoad method |
| 10 | service\_id | bigint | Service ID |
| 11 | group\_id | bigint | Group ID |
| 12 | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 13 | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 14 | bkp$\_forecast\_start | timestamp without time zone | \- |

## **Table system.area**

Sites

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Unique identifier of the site its name |
| 2 | foreign\_id | character varying | \- |
| 3 | status | character varying | Status |

		

## **Table system.business\_event**

The fact of the event

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Unique event identifier |
| 2 | event\_template\_id | bigint | The template from which the event was created |
| 3 | start\_timestamp | timestamp with time zone | Current start time of the event |
| 4 | end\_timestamp | timestamp with time zone | Current end time of the event |
| 5 | create\_timestamp | timestamp with time zone | Event creation time |
| 6 | author\_id | bigint | The operator who created the event |
| 7  | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 8  | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 9  | bkp$\_create\_timestamp | timestamp without time zone | \- |

## **Table system.call\_number\_vw**

Historical data on the number of calls received

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | group\_id | bigint | Group ID |
| 2 | group\_name | character varying | Group name |
| 3 | start\_timestamp | timestamp with time zone | Start time moment |
| 4 | end\_timestamp | timestamp with time zone | End time moment |
| 5 | historic\_call\_number | integer | Number of historical calls |
| 6 | not\_unique\_received | integer | Non-unique accepted |
| 7 | not\_unique\_treated | integer | Non-unique lost |
| 8 | not\_unique\_missed | integer | Non-unique ones are omitted |
| 9 | unique\_recieved | integer | Unique accepted |
| 10 | miss\_call | integer | Missed calls |

## **Table system.contact**

Contact of employee/client/group etc.

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Unique contact identifier |
| 2  | contact\_type | character varying | Contact type |
| 3  | text\_value | character varying | Text value of contact |
| 4  | description | character varying | Free text description of the contact |
| 5  | is\_main | boolean | Is the contact the primary one among others of the same type? |

## **Table system.customer\_config\_item**

Customer configuration

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | param | character varying | Configuration parameter name |
| 2  | value | character varying | Text value of the parameter |

## **system.department table**

Directory of departments

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | ID records |
| 2  | parent\_id | bigint | Parent unit |
| 3  | name | text | Name of the department |
| 4  | uid | text | external system identifier |
| 5  | status | character varying | Unit status |

## **Table system.department\_chief**

Table for storing department heads

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | department\_id | bigint | Record IDs |
| 2  | worker\_id | bigint | ID worker a \- he is also the head/deputy of the department |
| 3  | valid\_from | date | Start date of substitution |
| 4  | valid\_to | date | End date of substitution |
| 5  | role | character varying | The role of the leader |
| 6  | bkp$\_valid\_from | timestamp without time zone | \- |
| 7  | bkp$\_valid\_to | timestamp without time zone | \- |

## **Table system.desired\_schedule\_vw**

Preferred Operator Work Schedule Template

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | department\_name | text | Name of the department |
| 6 | status | character varying | Status |
| 7 | operator\_type | character varying | Operator type |
| 8 | desired\_work\_schedule | character varying | Preferred work schedule |
| 9 | is\_priority | boolean | is\_priority |

## **Table system.dirty\_context**

For dirty purposes (to make context dirty)

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | \- |

## **Table system.employment\_rate**

Directory Percentage of Employment

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Unique identifier |
| 2  | percent | double precision | Employment percentage |
| 3  | month | integer | Month number 1..12 |

## **Table system.employment\_rate\_group**

Denouement reference: employment percentage-group

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | employment\_rate\_id | bigint | Directory entry identifier |
| 2  | group\_id | bigint | Group ID |

## **Table system.entity\_package**

Contains a list of all currently deployed system modules

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | entity\_package\_id | bigint | Unique module identifier, defined by developers |
| 2  | entity\_package\_name | character varying | System name of the module |
| 3  | package\_desc | character varying | User-friendly description of the module |
| 4  | scheme\_name | character varying | The name of the schema containing the data structures for the current module |
| 5  | depends\_on\_entity\_package\_id | bigint | A reference to a module that the current module depends on |
| 6  | is\_sys | boolean | TRUE if system. System package is always deployed, not a shipping option. |
| 7  | appserver\_project | character varying | The project in the appserver repository that contains the implementation of this module. If null, this module has no implementation on the appserver. If the implementation in appserver is inseparable from the parent implementation (depends\_on), then the name of the parent appserver\_project should be specified. Note: usually one java-project is specified, although there is a project and a project-ui in appserver |

## **Table system.event\_template**

Mass Event Template

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Unique template identifier |
| 2 | type | character varying | Type of event (training, meeting, etc.) |
| 3 | name | character varying | Event Title |
| 4 | description | character varying | Description of the event |
| 5 | period\_type | character varying | Frequency of the event (daily/weekly/monthly) |
| 6 | min\_workers | integer | Minimum number of participants for the event |
| 7 | max\_workers | integer | Maximum number of event participants |
| 8 | my\_start | time without time zone | Minimum event start time (in ms from the start of the day) |
| 9 | max\_end | time without time zone | Maximum event end time (in ms from the start of the day) |
| 10 | duration | bigint | Event duration in milliseconds |
| 11 | week\_days | character varying | Days of the week on which the event can be held |
| 12 | max\_simultaneous | integer | Maximum number of events that can be held simultaneously (are overlaps possible) |
| 13 | status | character varying | Template Status |
| 14 | start\_timestamp | timestamp with time zone | Event start time |
| 15 | end\_timestamp | timestamp with time zone | Event end time |
| 16 | work\_plan | bigint | Work plan. calls/questionnaires |
| 17 | aht | bigint | Average processing time |
| 18 | occ | bigint | Operators' Employment |
| 19 | dtype | text | Event Type(EventTemplate, ProjectEventTemplate) |
| 20 | project\_event\_mode | character varying | Project mode (load priority) |
| 21 | priority | integer | Project Priority |
| 22 | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 23 | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 24 | bkp$\_my\_start | bigint | \- |
| 25 | bkp$\_max\_end | bigint | \- |
| 26 | time\_zone | character varying | \- |
| 27 | is\_combine\_events | boolean | Combine with other activities during the day |
| 28 | valid\_from | timestamp without time zone | Local date-time of the start of the event period |
| 29 | valid\_to | timestamp without time zone | Local date-time of the end of the event period (exclusive) |

## **Table system.event\_template\_group**

Possible participant of the event

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | event\_template\_id | bigint | Event template |
| 2  | group\_id | bigint | Group \- a possible participant of the event |

## **Table system.event\_template\_worker**

Possible participant of the event

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | event\_template\_id | bigint | Event template |
| 2  | worker\_id | bigint | Operator \- a possible participant in the event |

## **The system.event\_type table**

Table of types of events that can occur in the system.

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Identifier |
| 2  | keyword | character varying | Unique key for the event type. |
| 3  | name | character varying | Category name. |
| 4  | category | character varying | Event category. |
| 5  | default\_message\_template | character varying | The template for the notification that will be used by default. |
| 6  | specific\_properties | character varying | A list of specific parameters that can be used in a message template. |
| 7  | business\_critical | boolean | Whether delivery of a notification of this type is business critical. |
| 8  | version | bigint | The version of the record, incremented when changed. |

## **Table system.forecast\_interval**

Forecast for a specific time interval

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | start\_timestamp | timestamp with time zone | Home forecast |
| 2  | end\_timestamp | timestamp with time zone | End of prediction |
| 3  | call\_number | double precision | Number of calls |
| 4  | operator\_number | double precision | Number of operators |
| 5  | call\_number\_coefficient | real | Growth rate |
| 6  | operator\_number\_coefficient | real | Safety factor |
| 7  | required\_operator\_number | double precision | Required number of operators |
| 8  | min\_count\_operators | double precision | Minimum number of operators |
| 9  | forecast\_special\_event\_id | bigint | Special event that the interval falls on |
| 10  | actual\_service\_level | integer | service level on the interval |
| 11  | actual\_occupancy | double precision | operator workload level on the interval |
| 12  | avg\_handling\_time | integer | Average processing time |
| 13  | service\_id | bigint | link to service |
| 14  | group\_id | bigint | link to the group |
| 15  | service\_level | integer | maximum service level (SLA) |
| 16  | min\_service\_level | integer | minimum service level agreement (SLA) |
| 17  | avg\_waiting\_time | integer | call waiting time |
| 18  | acd | integer | Percentage of calls on which operators are calculated |
| 19  | absenteeism\_coefficient | real | Absence rate |
| 20  | parallel\_requests | integer | Simultaneously processed requests (for calls 1\) |
| 21  | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 22  | bkp$\_end\_timestamp | timestamp without time zone | \- |

## **Table system.forecast\_special\_event**

Special Events Directory

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | ID records |
| 2  | start\_time | timestamp with time zone | Special event start time |
| 3  | end\_time | timestamp with time zone | Special event end time |
| 4  | name | character varying | Name of special event |
| 5  | description | character varying | Description of a special event |
| 6  | coefficient | real | Event coefficient |
| 7  | version | bigint | Version |
| 8  | status | character varying | Status |
| 9  | bkp$\_start\_time | timestamp without time zone | \- |
| 10  | bkp$\_end\_time | timestamp without time zone | \- |

## **Table system.forecast\_special\_event\_service\_group**

Possible participants of the special event

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | forecast\_special\_event\_id | bigint | Special event ID from forecast\_sepcial\_event |
| 2  | service\_id | bigint | Service ID |
| 3  | group\_id | bigint | Group ID |

## **Talitsa system.forecast\_vw**

\-

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | group\_name | character varying | \- |
| 2 | start\_timestamp | timestamp with time zone | \- |
| 3 | end\_timestamp | timestamp with time zone | \- |
| 4 | forecast\_call\_number | double precision | \- |
| 5 | aht | integer | \- |
| 6 | absenteeism\_coefficient | real | \- |
| 7 | forecast\_operator\_number | double precision | \- |
| 8 | call\_number\_coefficient | real | \- |

## **Table system.group\_l**

A group of call center employees who share some common characteristic, such as occupation

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique group identifier |
| 2  | name | character varying | Group name |
| 3  | description | character varying | Group Description |
| 4  | foreign\_id | text | External system identifier for integration |
| 5  | status | character varying | Status |
| 6  | version | bigint | Version |
| 7  | config\_string | character varying | Configuration of forecasting parameters (which are then pulled into the forecasting module when forecasting the required quantity |
| 8  | system\_id | integer | Integrated system |
| 9  | type | character varying | Group type |
| 10  | parent\_id | bigint | Parent group |
| 11  | monitoring\_config | text | \- |
| 12  | priority | integer | \- |
| 13 | analysis\_mode | character varying | \- |

## **Table sandstem.group\_worker**

Group-employee denouement

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | Idishnik bundles |
| 2 | group\_id | bigint | The group the employee belongs to |
| 3 | worker\_id | bigint | An employee who is part of a group |
| 4 | priority | integer | Priority of employee entry into the group |
| 5 | operators\_on\_line\_notification | boolean | Alerts on decrease/increase of operators on the line |
| 6 | actual\_load\_notification | boolean | Load decrease/increase alerts |
| 7 | operators\_requirement\_notification | boolean | Operator Need Alerts |
| 8 | sla\_notification | boolean | Alerts on SLA decrease/increase |

## **Table system.groups\_vw**

Information about groups

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | group\_id | bigint | Group ID |
| 2 | name | character varying | Group name |
| 3 | foreign\_id | text | Group ID in external system |
| 4 | parent\_id | bigint | Parent group ID |
| 5 | system\_id | character varying | External system name |
| 6 | service\_name | character varying | Name of service |
| 7 | service\_foreign\_id | text | External system identifier |

## **Table system.historical\_data**

Historical data storage model

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | service\_id | bigint | Unique identifier of the service to which the historical data belongs |
| 2  | group\_id | bigint | Unique identifier of the group to which the historical data belongs |
| 3  | start\_timestamp | timestamp with time zone | Start of 15 minute interval |
| 4  | end\_timestamp | timestamp with time zone | End of 15 minute interval |
| 5  | historic\_call\_number | integer | Unique processed requests |
| 6  | miss\_call | integer | Unique missed calls |
| 7  | historic\_aht | integer | Average talk time (this also includes the time it takes to dial outgoing calls) |
| 8  | duration\_postprocessing | integer | Average duration of call post-processing |
| 9  | change\_historic\_call | integer | Modified unique processed |
| 10  | change\_miss\_call | integer | Modified Unique Missing |
| 11  | change\_historic\_aht | integer | changed processing time |
| 12  | change\_duration\_postprocessing | integer | changed post processing time |
| 13  | status | character varying | interval status |
| 14  | not\_unique\_received | integer | Non-unique incoming requests |
| 15  | not\_unique\_treated | integer | Non-unique processed requests |
| 16  | not\_unique\_missed | integer | Non-unique missing |
| 17  | unique\_recieved | integer | Unique incoming requests |
| 18  | change\_not\_unique\_received | integer | Modified non-unique incoming requests |
| 19  | change\_not\_unique\_treated | integer | Modified non-unique processed requests |
| 20  | change\_not\_unique\_missed | integer | Modified non-unique missed hits |
| 21  | change\_unique\_recieved | integer | Modified unique incoming requests |
| 22  | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 23  | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 24 | status\_call | character varying | \- |
| 25 | status\_aht | character varying | \- |

## **The system.http\_session\_history table**

The table contains the history of http sessions with entry and exit times

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | http\_session\_number | bigint | Table entry ID |
| 2  | http\_session\_id | character varying | http session id |
| 3  | user\_name | character varying | System user |
| 4  | login\_id | bigint | Login ID |
| 5  | worker\_id | bigint | Employee ID |
| 6  | logon\_time | timestamp with time zone | User login date |
| 7  | logoff\_time | timestamp with time zone | User logout date |
| 8  | bkp$\_logon\_time | timestamp without time zone | \- |
| 9  | bkp$\_logoff\_time | timestamp without time zone | \- |

## **The system.integration\_info table**

Record of differences in employee information in the WFM system and the Central Office of the Ministry of Justice

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | protei\_foreign\_id | character varying | External system identifier for integration |
| 3  | protei\_name | character varying | Employee name in external system |
| 4  | protei\_surname | character varying | Employee's last name in the external system |
| 5  | protei\_second\_name | character varying | Employee's patronymic in the external system |
| 6  | protein\_status | character varying | Employee status (active/inactive) |
| 7  | worker\_id | bigint | Employee ID in the WFM system |

## **Table system.integration\_info\_group**

Denouement information about the employee from the COV-group

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | integration\_info\_id | bigint | Information about the employee from the Center of Public Relations |
| 2  | group\_id | bigint | Group |

## **Table system.integration\_system**

Integration systems

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Integration system feature for Single sign-on (SSO) |
| 2  | integration\_system\_name | text | System name |
| 3  | personnel\_endpoint | text | Endpoint of the integration system |
| 4  | system\_id | character varying | External system identifier |
| 5  | personnel\_master | boolean | Master system sign for staff |
| 6  | historical\_data\_endpoint | text | Access point for obtaining historical data for forecasting |
| 7  | operators\_data\_endpoint | text | Access point for obtaining source data from operators |
| 8  | work\_chat\_data\_end\_point | text | Access point for receiving data on chats |
| 9  | account\_authorization\_endpoint | text | Access point for obtaining a UZ to log in to the system |
| 10  | monitoring\_provider\_endpoint | text | url for monitoring this integration system |
| 11  | sms\_notification\_config | text | \- |
| 12  | sso | boolean | \- |
| 13  | is\_sys | boolean | \- |
| 14 | match\_type | character varying | Mapping attribute for staff synchronization |
| 15 | ignore\_case | boolean | Ignore case when matching UZs |
| 16 | online\_status\_by\_endpoint\_enabled | boolean | a sign of receiving online operator statuses through the specified monitoring access point |

## **Table system.kpi\_change\_fact**

The value of the indicator set manually by the manager

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | worker\_id | bigint | Employee |
| 3  | group\_id | bigint | Group |
| 4  | kpi\_performance\_id | bigint | KPI |
| 5  | year | smallint | Year |
| 6  | month | text | Month |
| 7  | value | double precision | Meaning |

## **Table system.kpi\_chats\_norm**

Chat Guidelines

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | chats\_session | integer | Chats in session The number of chats the operator handled at one time |
| 3  | norm | double precision | Standard value of the indicator Number of chats that an operator must process, given a certain number of chats in a package |

## **Table system.kpi\_chats\_norm\_service\_groups**

Table linking group/service to chat norm

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | kpi\_chats\_norm\_id | bigint | Norm ID records from kpi\_chats\_norm |
| 2  | service\_id | bigint | Service ID |
| 3  | group\_id | bigint | Group ID |

## **Table system.kpi\_import**

Table for storing KPI indicators uploaded by the user

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | worker\_id | bigint | Employee ID |
| 3  | date | date | Import date |
| 4  | kpi\_id | bigint | Identifier of the imported indicator |
| 5  | group\_id | bigint | Group ID |
| 6  | value | double precision | Imported indicator value |

## **Table system.kpi\_influence**

Table for storing KPI indicators uploaded by the user

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | kpi\_performance\_id | bigint | Service ID |
| 3  | value | number range | Group ID |
| 4  | percent\_formula | double precision | Event coefficient |

## **Table system.kpi\_letters\_norm**

Norma \- letters

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | letter\_category | text | Post Category |
| 3  | norm\_time | bigint | Standard processing time |

## **Table system.kpi\_letters\_norm\_service\_groups**

Services-groups for kpi\_letters\_norm

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | kpi\_letters\_norm\_id | bigint | Letter norm ID from kpi\_letters\_norm |
| 2  | service\_id | bigint | Service ID |
| 3  | group\_id | bigint | Group ID |

## **Table system.kpi\_letters\_vw**

KPI for letters

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | date | date | Date |
| 3 | group\_id | bigint | Group ID |
| 4 | letter\_category | text | Category of letters |
| 5 | letters\_number | integer | Number of letters |
| 6 | norm\_time | bigint | Standard time |

## **Table system.kpi\_norm**

Standards of indicators from "Premium indicators"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Norm ID |
| 2  | kpi\_performance\_id | bigint | Indicator ID from "Premium Indicators" |
| 3  | type\_kpi\_group | text | Type of standard (voice calls, etc.) |
| 4  | position\_id | bigint | Job title |
| 5  | department\_id | bigint | Subdivision |
| 6  | normative\_value | text | Standard value of the indicator |
| 7  | kpi\_interval\_type | text | Interval type ("hour, working time", etc.) |

## **Table system.kpi\_norm\_service\_groups**

Linking the standard from kpi\_norm and service/group

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | kpi\_norm\_id | bigint | Norm ID from kpi\_norm |
| 2  | service\_id | bigint | Service ID |
| 3  | group\_id | bigint | Group ID |

## **Table system.kpi\_norm\_vw**

KPI standards

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | date\_from | timestamp with time zone | Start date |
| 2 | date\_to | timestamp with time zone | End date |
| 3 | worker\_id | bigint | Employee ID |
| 4 | last\_name | character varying | Family name |
| 5 | first\_name | character varying | Name |
| 6 | second\_name | character varying | Surname |
| 7 | department\_id | bigint | Division ID |
| 8 | position\_id | bigint | Position ID |
| 9 | call\_number | bigint | Number of calls |
| 10 | call\_time | bigint | Call duration |
| 11 | group\_id | bigint | Group ID |
| 12 | group\_name | character varying | Group name |
| 13 | normative\_value | text | Standard values |
| 14 | id | bigint | Identifier |
| 15 | kpi\_norm\_id | bigint | Identifier |

## **Table system.kpi\_percent**

Positions Share in bonus

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | kpi\_performance\_id | bigint | Indicator |
| 3  | share\_value | double precision | The meaning of the share |

## **Table system.kpi\_percent\_department**

Table for connection of "Shares in premium" and divisions

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | kpi\_percent\_id | bigint | Bonus share record ID from kpi\_percent |
| 2  | departments\_id | bigint | Unit ID |

## **Table system.kpi\_percent\_position**

Table for the connection between "Shares in the bonus" and the operator's position

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | kpi\_percent\_id | bigint | Bonus share record ID from kpi\_percent |
| 2  | positions\_id | bigint | Job ID |

## **Table system.kpi\_performance**

Indicators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | name | text | Name of the indicator |
| 3  | is\_sys | boolean | System entry flag |
| 4  | status | text | Status |

## **Table system.kpi\_position\_pay\_type**

Hourly rate and bonus standard

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Surrogate ID |
| 2  | department\_id | bigint | Department ID |
| 3  | position\_id | bigint | Job Id |
| 4  | hour\_rate | double precision | Meaning of hourly rate |
| 5  | bonus | double precision | Percentage of bonus for position |
| 6  | bonus\_mentor | double precision | Maximum bonus percentage for the Mentoring indicator |

## **Table system.kpi\_worker\_chats\_work\_time**

Table for storing information about the operator's working time

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee ID |
| 2  | date | date | The date for which the information is stored |
| 3  | work\_time | bigint | Received working time |

## **Table system.kpi\_worker\_letters**

Number of processed letters by operators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee |
| 2  | date | date | Date |
| 3  | group\_id | bigint | Group |
| 4  | letter\_category | text | Category of letters |
| 5  | letters\_number | integer | Number of letters |

## **Table system.last\_online\_load**

The table contains the latest online load data checked for deviations for each group.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | service\_id | integer | Link to the service. |
| 2  | group\_id | integer | Link to the group. |
| 3  | online\_load\_date | timestamp with time zone | Online load date. |

## **Table system.log**

Event log

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Unique event identifier |
| 2  | dtype | character varying | Event type |
| 3  | start\_timestamp | timestamp with time zone | Event start time |
| 4  | end\_timestamp | timestamp with time zone | Event end time |
| 5  | message | text | Human-readable description of the event |
| 6  | result | text | Human-readable description of the result |
| 7  | successful | boolean | Was the operation successful? |
| 8  | worker\_id | bigint | The user who caused the event to be executed. null if system |
| 9  | object\_id | bigint | The identifier of the object associated with the event |
| 10  | object\_type | character varying | The type of object associated with the event |
| 11  | parent\_id | bigint | Parent record for grouping events |
| 12  | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 13  | bkp$\_end\_timestamp | timestamp without time zone | \- |

## **Table system.login**

Credentials of users registered in the system

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | uid | bigint | Unique user identifier |
| 2  | username | character varying | Unique username |
| 3  | password | character varying | Hashed user password |
| 4  | salt | character varying | Additional lines for password encryption (Salt is a term from cryptography) |
| 5  | description | character varying | Description of the current user |
| 6  | email | character varying | The user's primary email used to notify about changes to their account information |
| 7  | worker\_id | bigint | Reference to the employee for whom the current login is defined |
| 8  | logon\_time | timestamp with time zone | Date and time of the current user's last login |
| 9  | expiry\_date | timestamp with time zone | The expiration date of the current user's password. After reaching this date, the user must change the password to a new one. If null, the password will never expire. |
| 10  | lock\_date | timestamp with time zone | Date and time of login blocking |
| 11  | created | timestamp with time zone | Date and time of login creation |
| 12 | local | character varying | User language |
| 13 | is\_sys | boolean | If 1, the user is considered a system user and cannot be deleted using the administration tool. |
| 14 | bkp$\_logon\_time | timestamp without time zone | \- |
| 15 | bkp$\_expiry\_date | timestamp without time zone | \- |
| 16 | bkp$\_lock\_date | timestamp without time zone | \- |
| 17 | bkp$\_created | timestamp without time zone | \- |
| 18 | failed\_attempts | integer | Number of unsuccessful login attempts in a row |

## **Table system.norm\_status**

Directory "Accounting of the statuses of the Center of Public Service"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | state\_id | bigint | The type of status that will be taken into account |
| 3  | service\_id | bigint | Service |
| 4  | operator\_type | character varying | Operator type |
| 5  | pay\_type\_id | bigint | Payment type |
| 6  | productivity | boolean | What hours to consider when calculating output |
| 7  | payment | boolean | What hours to consider when calculating payment |

## **Table system.norm\_week\_change**

Table with the history of changes in the standard hours per week

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | worker\_id | bigint | Employee ID |
| 3 | norm\_week | bigint | Standard hours per week in milliseconds |
| 4 | change\_date | date | Date changes |

## **System tablem.notification**

The fact of notifying/notifying an employee about something

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique notification identifier |
| 2  | dtype | character varying | Alert type (class) |
| 3  | message | character varying | Text message |
| 4  | result | character varying | Alert text result |
| 5  | author\_id | bigint | Author (creator) of the notification |
| 6  | recipient\_id | bigint | Notification recipient |
| 7  | create\_timestamp | timestamp with time zone | Moment of creation |
| 8  | send\_timestamp | timestamp with time zone | Moment of dispatch |
| 9  | reply\_timestamp | timestamp with time zone | The moment of receiving the answer |
| 10  | status | character varying | Alert status |
| 11  | channel | character varying | Employee Alert Type |
| 12  | bkp$\_create\_timestamp | timestamp without time zone | \- |
| 13  | bkp$\_send\_timestamp | timestamp without time zone | \- |
| 14  | bkp$\_reply\_timestamp | timestamp without time zone | \- |
| 15  | foreign\_id | character varying | \- |
| 16  | link | text | Link |

## **Table system.notification\_event\_recipient**

Notification event

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Identifier |
| 2  | name | text | Name |
| 3  | system\_name | text | System name |
| 4  | description | text | Description |
| 5  | status | character varying | Status |
| 6  | event\_group | text | Event Group |
| 7  | notifying\_chiefs\_level | integer | Number of notified senior managers |

## **Таблица system.notification\_event\_recipient\_role**

Table for linking notification event and role

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | event\_id | bigint | Event ID from notification |
| 2  | role\_id | bigint | ID roll |

## **Table system.notification\_issue**

\-

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | \- |
| 2  | plan\_interval\_id | bigint | \- |
| 3  | event\_type\_id | bigint | \- |
| 4  | creation\_date | timestamp without time zone | \- |
| 5  | notified | boolean | \- |

## **The system.notification\_metadata table**

Notification metadata (parameters)

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | notification\_id | bigint | The notification you are looking for |
| 2  | key | character varying | Parameter name |
| 3  | value | character varying | Parameter value |

## **Table system.notification\_push\_token**

Push Notification Token Storage

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | worker\_id | bigint | Employee ID |
| 2  | token | text | Token |
| 3 | token\_type | text | \- |

## **Table system.notification\_scheme**

Table with settings for generating notifications.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Identifier. |
| 2  | event\_type\_id | bigint | Link to the event type for which we are setting up a notification. |
| 3  | message\_template | character varying | Notification template. |
| 4  | notify\_workers | boolean | Flag that determines whether workers should be notified. Workers are determined from the context of the business process. |
| 5  | notify\_managers | boolean | Flag that determines the need to notify managers. Managers are determined for employees. |
| 6  | managers\_hierarchy\_depth | bigint | Integer value defining the "Hierarchy Gap" for searching managers. Relevant if the notify\_managers field is True. |
| 7  | notify\_roles | boolean | Flag that determines whether employees should be notified based on business roles. Notified roles are in a separate junction table. |
| 8  | notify\_specific\_workers | boolean | Flag that determines the need to notify specific workers. The workers to be notified are in a separate junction table. |
| 9  | enable | boolean | A flag that determines whether notification for this scheme is enabled or disabled. |
| 10  | version | bigint | The version of the record, incremented when changed. |

## **Table system.notification\_scheme\_channel**

Table of mapping between channels and notification schemes.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
| 2  | channel | character varying | Notification channel. |

## **Table system.notification\_scheme\_role**

A table of the mapping between notification schemes and the roles to be notified.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
| 2  | role\_id | bigint | Link to the role. |

## **Table system.notification\_scheme\_worker**

A table of the links between notification schemes and the specific employees who need to be notified.

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | notification\_scheme\_id | bigint | Link to notification scheme. |
| 2  | worker\_id | bigint | Link to employee. |

## **Table system.old\_personal\_information\_vw**

Old personal information

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | operator\_type | character varying | Operator type |
| 6 | position\_name | text | Position name |
| 7 | employment | date | Date of employment |
| 8 | department\_name | text | Name of the department |
| 9 | group\_name | character varying | Group name |
| 10 | status | character varying | Status |
| 11 | group\_id | bigint | Group ID |
| 12 | position\_id | bigint | Position ID |
| 13 | department\_id | bigint | Division ID |

## **Table system.online\_load**

Online load for a specific time interval

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier of the load for a specific interval |
| 2  | date\_time | timestamp with time zone | Load time |
| 3  | call\_number | integer | Number of calls |
| 4  | operator\_number | integer | Number of operators |
| 5  | group\_id | integer | Unique identifier of the operator group to which the load belongs |
| 6  | service\_id | integer | Unique identifier of the service to which the load belongs |
| 7  | service\_level | integer | Current quality of service |
| 8  | required\_operator\_number | integer | Required number of operators |
| 9  | call\_received | integer | Number of received requests (cumulatively from the beginning of the day) |
| 10  | aht | bigint | Average talk time in the group (cumulatively from the beginning of the day), in milliseconds |
| 11  | acd | double precision | Percentage of accepted requests (cumulatively from the beginning of the day) |
| 12  | awt | bigint | Average subscriber waiting time in queue from the beginning of the day |
| 13  | bkp$\_date\_time | timestamp without time zone | \- |
| 14 | call\_answered | integer | Number of calls processed (from the beginning of the day to the moment of the request) |
| 15 | call\_answered\_tst | integer | The number of processed calls that waited in the queue for less than N seconds (from the beginning of the day to the moment of the request) |
| 16 | call\_processing | integer | Number of calls in progress for operators at the time of the request |

## **Table system.operator\_event\_vw**

Operator Events

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | event\_type | character varying | Event type |
| 6 | start\_timestamp | timestamp with time zone | Start time moment |
| 7 | end\_timestamp | timestamp with time zone | End time moment |
| 8 | event\_status | character varying | Event status |
| 9 | dtype | character varying | Type Discriminator |

## **Table system.operator\_load**

A table storing the number and time of calls processed by the operator

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Operator identifier |
| 2  | service\_id | bigint | The service within which the operator worked |
| 3  | group\_id | bigint | The group in which the operator worked |
| 4  | date\_from | timestamp with time zone | Beginning of the period |
| 5  | date\_to | timestamp with time zone | End of the period |
| 6  | call\_time | bigint | Non-unique request processing time in milliseconds |
| 7  | call\_number | bigint | Number of processed non-unique requests |
| 8  | bkp$\_date\_from | timestamp without time zone | \- |
| 9  | bkp$\_date\_to | timestamp without time zone | \- |

## **Table system.operator\_load\_vw**

Number and time of calls processed by the operator

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | department\_name | text | Name of the department |
| 6 | date\_from | timestamp with time zone | Start date |
| 7 | date\_to | timestamp with time zone | End date |
| 8 | call\_time | bigint | Call duration |
| 9 | call\_number | bigint | Number of calls |
| 10 | system\_id | character varying | System ID |
| 11 | group\_name | character varying | Group name |
| 12 | position\_id | bigint | Position ID |
| 13 | department\_id | bigint | Division ID |
| 14 | group\_id | bigint | Group ID |

## **Table system.operator\_login\_time**

Table storing login/logout/stay time in the integration system

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | ID worker а |
| 2  | system\_id | bigint | Integration system ID |
| 3  | login\_time | timestamp with time zone | Date, time of entry |
| 4  | logout\_time | timestamp with time zone | Date, time of release |
| 5  | login\_duration | bigint | Time spent in the COV |
| 6  | bkp$\_login\_time | timestamp without time zone | \- |
| 7  | bkp$\_logout\_time | timestamp without time zone | \- |

## **Table system.operator\_login\_time\_vw**

Operator login/logout time

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | system\_name | character varying | System name |
| 6 | login\_time | timestamp with time zone | Login time |
| 7 | logout\_time | timestamp with time zone | Logout time |
| 8 | login\_duration | bigint | Login duration |
| 9 | department\_name | text | Name of the department |

## **Table system.operator\_outgoing\_calls**

Outgoing Call Results

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Operator ID |
| 2  | service\_id | bigint | The service within which the operator worked |
| 3  | group\_id | bigint | The group in which the operator worked |
| 4  | date | date | Day |
| 5  | result\_code | text | Code of the result marked in the COV |
| 6  | result\_description | text | The name of the result marked in the COV |
| 7  | call\_number | integer | Number of processed non-unique requests |

## **Table system.operator\_outgoing\_calls\_vw**

Results of outgoing calls from operators

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | first\_name | character varying | Name |
| 2 | second\_name | character varying | Surname |
| 3 | last\_name | character varying | Family name |
| 4 | system\_id | character varying | System ID |
| 5 | group\_name | character varying | Group name |
| 6 | date | date | Date |
| 7 | result\_code | text | Result code |
| 8 | result\_description | text | Description of the result |
| 9 | call\_number | integer | Number of calls |

## **Table system.operator\_overtime\_vw**

Operator login/logout time

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Name of the department |
| 2 | date | timestamp without time zone | Name of the department |
| 3 | duration | numeric | Name of the department |

## **Table system.operator\_schedule\_vw**

Operators schedule

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | last\_name | character varying | Family name |
| 3 | first\_name | character varying | Name |
| 4 | second\_name | character varying | Surname |
| 5 | position\_name | text | Position name |
| 6 | department\_name | text | Name of the department |
| 7 | valid\_from | date | Valid from |
| 8 | valid\_to | date | Valid until |

## **The system.operator\_state table**

Handbook "Configuration of working time efficiency"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier of the operator status |
| 2  | state\_id | character varying | Status ID in the CAC (foreignId) |
| 3  | state | character varying | Status name in the COV |
| 4  | state\_name | character varying | Status name (to be displayed in the report) |
| 5  | description | character varying | Status Description |
| 6  | is\_productive | boolean | Is the current status productive time? |
| 7  | is\_work\_load | boolean | Is the current status a net load? |
| 8  | absence | boolean | Is the current status time away? |
| 9  | system\_id | bigint | The COV from which the status was received |
| 10  | is\_talk\_time | boolean | Checkbox "Talk time" |
| 11  | is\_break | boolean | Cheboks "Break Time" |
| 12  | is\_fact\_time | boolean | Actual time indicator in the timesheet |
| 13  | is\_productive\_work\_time | boolean | Signs of a productive working time |
| 14  | line\_state\_type | character varying | Possible operator statuses on the line |
| 15  | is\_after\_call\_work | boolean | Post-call processing |
| 16  | is\_operator\_active | boolean | Indication that the operator is online and active |
| 17  | color | character varying | Display color in reports |
| 18 | is\_billable\_time | boolean | Paid time indicator |

## **Table system.operator\_status\_vw**

Operator statuses

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | \- |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | state\_name | character varying | Status name |
| 6 | date\_from | timestamp with time zone | Start date |
| 7 | date\_to | timestamp with time zone | End date |
| 8 | duration\_in\_state | bigint | Duration in status |
| 9 | is\_productive | boolean | is\_productive |
| 10 | is\_work\_load | boolean | is\_work\_load |
| 11 | system\_id | character varying | System ID |
| 12 | is\_talk\_time | boolean | is\_talk\_time |
| 13 | is\_fact\_time | boolean | is\_fact\_time |
| 14 | group\_name | character varying | Group name |
| 15 | group\_id | bigint | Group ID |
| 16 | position\_name | text | Position name |
| 17 | department\_name | text | Name of the department |
| 18 | is\_break | boolean | is\_break |
| 19 | foreign\_id | text | External identifier |
| 20 | is\_after\_call\_work | boolean | is\_after\_call\_work |

## **Table system.operator\_status\_vw\_old**

Operator statuses (old)

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | \- |
| 2 | first\_name | character varying | \- |
| 3 | second\_name | character varying | \- |
| 4 | last\_name | character varying | \- |
| 5 | state\_name | character varying | \- |
| 6 | date\_from | timestamp with time zone | \- |
| 7 | date\_to | timestamp with time zone | \- |
| 8 | duration\_in\_state | bigint | \- |
| 9 | is\_productive | boolean | \- |
| 10 | is\_work\_load | boolean | \- |
| 11 | system\_id | character varying | \- |
| 12 | is\_talk\_time | boolean | \- |
| 13 | payment | boolean | \- |
| 14 | group\_name | character varying | \- |
| 15 | position\_name | text | \- |
| 16 | department\_name | text | \- |
| 17 | is\_break | boolean | \- |
| 18 | foreign\_id | text |  |

## **Table system.pay\_type**

Directory "Payment Type"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique payment type identifier |
| 2  | name | character varying | Payment type name |
| 3  | description | character varying | Payment type comment |

## **Table system.permission**

Contains the basic system privileges that govern user access to views, frames, and functions. Entries in this table can only be added by developers when implementing the corresponding functionality.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | character varying | Unique string identifier of the privilege |
| 2  | parent\_id | character varying | A reference to a parent privilege, without which the current privilege has no meaning. If the current privilege is assigned but the parent privilege is not, the parent privilege is assigned implicitly. A similar rule applies to the entire privilege tree |
| 3  | entity\_package\_id | bigint | A reference to the module that implements the function protected by this privilege. |

## **Table system.personal\_information\_vw**

Personal information

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | first\_name | character varying | Name |
| 3 | second\_name | character varying | Surname |
| 4 | last\_name | character varying | Family name |
| 5 | operator\_type | character varying | Operator type |
| 6 | employment | date | Date of employment |
| 7 | dismissal | date | Absence |
| 8 | status | character varying | Status |
| 9 | position\_id | bigint | Position ID |
| 10 | department\_id | bigint | Division ID |
| 11 | position\_name | text | Position name |
| 12 | department\_name | text | Name of the department |
| 13 | comment | character varying | Comment |
| 14 | tab\_no | character varying | Personnel number |
| 15 | zone\_display\_name | character varying | \- |

## **Table system.plan\_interval**

Employee work interval from the schedule plan

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | dtype | text | Interval type (ShiftPlanInterval, BreakPlanInterval, etc.) |
| 3  | solution\_id | bigint | The schedule to which the interval belongs |
| 4  | worker\_id | bigint | The employee to whom this interval applies |
| 5  | my\_start | timestamp with time zone | Minimum start time of the interval |
| 6  | max\_end | timestamp with time zone | Maximum end time of the interval |
| 7  | start\_timestamp | timestamp with time zone | Actual start time of the interval |
| 8  | end\_timestamp | timestamp with time zone | The current moment of the end of the interval |
| 9  | type | character varying | Interval Type (IntervalType) |
| 10  | status | character varying | Interval status (active/inactive) |
| 11  | service\_group\_plan\_id | bigint | The service-group plan to which the interval belongs |
| 12  | shift\_plan\_interval\_id | bigint | The shift plan to which the interval belongs (office operators only) |
| 13  | business\_event\_id | bigint | The event to which the interval relates |
| 14  | fraction | integer | The share with which the employee is involved in the project (%) |
| 15  | info | text | Raw data |
| 16  | bkp$\_my\_start | timestamp without time zone | \- |
| 17  | bkp$\_max\_end | timestamp without time zone | \- |
| 18  | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 19  | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 20 | is\_payable | boolean | \- |

## **Table system.plan\_interval\_service\_group\_plan**

Uncoupling PlanInterval and ServiceGroupPlan

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | plan\_id | bigint | PlanInterval Identifier |
| 2  | service\_group\_plan\_id | bigint | ServiceGroupPlan Identifier |

## **Table system. planned\_worker\_wish**

Table of planned preferences

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | operating\_schedule\_planning\_task\_id | bigint | The task within which the preference was planned |
| 3 | worker\_wish\_id | bigint | Preference entered |
| 4 | duration | bigint | Duration of the planned shift in milliseconds |
| 5 | adjusted\_duration | bigint | Shift duration in milliseconds, including unpaid breaks |
| 6 | start | timestamp with time zone | Shift start date |

## **Table system.planning\_schedule\_designation**

Linking the employee, the schedule and the planned work schedule

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee ID |
| 2  | schedule\_id | bigint | Work schedule identifier |
| 3  | operating\_schedule\_solution\_id | bigint | Work Schedule Planning Solution Identifier |
| 4  | status | character varying | Status |
| 5  | valid\_from | date | Applied since (date) |
| 6  | valid\_to | date | Applied on(date) |
| 7  | id | bigint | ID records |
| 8  | surplus | character varying | a sign that the operator is redundant on different days from the beginning of the period in different groups |
| 9 | operating\_schedule\_planning\_task\_id | bigint | Planning task |

## **Table system.planning\_task**

Planning task

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | \- |
| 2  | author\_id | bigint | Link to the employee who created the task |
| 3  | creation\_date | timestamp with time zone | Task creation time |
| 4  | end\_date | timestamp with time zone | Task completion time |
| 5  | solution\_id | bigint | Link to the work schedule |
| 6  | state | character varying | Planning Task Status |
| 7  | result | character varying | Planning result in Json format |
| 8  | config | character varying | Scheduling configuration in Json format |
| 9  | replanning | boolean | Is this task a rescheduling task? |
| 10  | error\_message | character varying | Description of planning error |
| 11  | version | bigint | \- |
| 12  | dtype | character varying | \- |
| 13  | replanning\_time | timestamp with time zone | the exact time from which we update the schedule |

## **Table system. planning\_task\_extension**

Extended information on the planning task

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | planning\_task\_id | bigint | Planning task identifier |
| 3 | dtype | character varying | Type of extended information on the planning task |
| 4 | created\_at | timestamp with time zone | Date-time of creation of extended information |
| 5 | info | character varying | String representation of extended task information |

## **Table system.position**

Directory of Jobs

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | name | text | Job Title |
| 3  | uid | text | external system identifier |
| 4  | status | character varying | Position status |
| 5  | is\_planning | boolean | Are employees with this position involved in planning? |

## **The system.position\_role table**

Roles Positions

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Identifier |
| 2  | role | text | Role name |
| 3  | position\_id | bigint | Job ID |

## **Table system.possible\_worker\_schedule\_template**

Work schedule template assigned to operator

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Table entry ID |
| 2  | worker\_id | bigint | ID worker а |
| 3  | schedule\_template\_id | bigint | Work Schedule Template ID |
| 4  | is\_priority | boolean | Is this template a priority? |
| 5  | possible\_rotation | character varying | Marked template rotations |
| 6  | bkp$\_possible\_rotation | character varying | \- |

## **Table system.pref\_table**

Imported from Argus infrastructure

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | pref\_name | character varying | name options |
| 2  | pref\_value | text | value options |
| 3  | pref\_comment | character varying | option comment |
| 4  | pref\_display\_name | character varying | option display name |
| 5  | pref\_category\_id | integer | Options category |
| 6  | pref\_data\_type | integer | Type options |

## **Table system.proc\_def\_template**

Imported from Argus infrastructure

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | schedule\_planning\_template\_id | bigint | \- |
| 3 | proc\_def\_id | character varying | \- |
| 4 | proc\_def\_key | character varying | \- |

## **Table system.production\_calendar**

Production calendar

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | year | bigint | Unique identifier of the production calendar and its year |
| 2  | config\_string | text | Configuration in xml form |
| 3  | version | bigint | \- |
| 4 | display\_in\_work\_schedule | boolean | Display in work schedule |

## **Table system.report\_band\_model**

Band model from the Report Editor. Each report has records in this table.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID is in the box |
| 1  | id | bigint | ID is in the box |
| 2  | name | character varying | Band name (mostly empty) |
| 2  | name | character varying | Band name (mostly empty) |
| 3  | keyword | character varying | Description of the band |
| 3  | description | character varying | Description of the band |
| 4  | keyword | character varying | The keyword of the band, we see it in the editor when we create a band (as a name) |
| 4  | version | bigint | The keyword of the band, we see it in the editor when we create a band (as a name) |
| 5  | status | character varying | The Stause Band |
| 5  | parent\_id | bigint | The Stause Band |
| 6  | orientation | character varying | Version Band |
| 6  | version | bigint | Version Band |
| 7  | query | character varying | Parent Band ID |
| 7  | parent\_id | bigint | Parent Band ID |
| 8  | orientation | character varying | Text orientation in band |
| 8  | ordinal\_number | integer | Text orientation in band |
| 9  | query | text | Directly query, written to the band |
| 9  | data\_loader\_type | character varying | Directly query, written to the band |
| 10  | dtype | character varying | Sequence number within the report |
| 10  | ordinal\_number | integer | Sequence number within the report |
| 11  | data\_loader\_type | character varying | The type of query we use to load data (SQl/Groovy) |

## **The system.report\_group\_roles table**

Linking the name of the report group and the roles to whom the group is available

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | group\_name | text | Group name |
| 2  | role\_id | bigint | Role |

## **Table system.report\_model\_template**

Template model for the report from the "Report Editor"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Template ID |
| 1  | id | bigint | Template ID |
| 2  | file\_name | character varying | Template file name |
| 2  | file\_name | character varying | Template filename |
| 3  | description | character varying | Template File Description |
| 3  | creation\_date | timestamp without time zone | Template File Description |
| 4  | creation\_date | timestamp with time zone | Date of creation |
| 4  | template | about | Date of creation |
| 5  | mime\_type | character varying | Reports the ID in which the template is loaded |
| 5  | template | about | Reports the ID in which the template is loaded |
| 6  | description | character varying | Attached document format (XML/HTML) |
| 6  | mime\_type | character varying | Attached document format (XML/HTML) |
| 7  | bkp$\_creation\_date | timestamp without time zone | \- |
| 7  | version | bigint | \- |
| 8  | report\_type\_id | bigint | \- |

## **Table system.report\_task**

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | \- |
| 1  | id | bigint | \- |
| 2  | name | character varying | \- |
| 2  | report\_type\_id | bigint | \- |
| 3  | creation\_date | timestamp with time zone | \- |
| 3  | creation\_date | timestamp with time zone | \- |
| 4  | end\_date | timestamp with time zone | \- |
| 4  | end\_date | timestamp with time zone | \- |
| 5  | state | character varying | \- |
| 5  | state | character varying | \- |
| 6  | param\_values | character varying | \- |
| 6  | initiator\_id | bigint | \- |
| 7  | template\_id | bigint | \- |
| 8  | output\_format | character varying | \- |
| 9  | type | character varying | Type of tasks |
| 9  | foreign\_id | character varying | Type of tasks |
| 10  | link | character varying | \- |
| 11  | error | character varying | \- |
| 12  | execution\_date | timestamp with time zone | \- |
| 13  | expiration\_date | timestamp with time zone | \- |
| 14  | period\_config\_id | bigint | \- |
| 15  | dtype | character varying | \- |
| 16  | callback\_url | text | \- |
| 17  | num\_repeats | integer | \- |

## **Table system.report\_task\_result**

Result of completing the task of building a report

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Identifier |
| 2  | state | character varying | State |
| 3  | submitted\_at | timestamp with time zone | Time to receive a response |
| 4  | report\_task\_id | bigint | Report generation task ID |
| 5  | link | character varying | Link to the result |
| 6  | error | character varying | Error message |
| 7  | foreign\_id | character varying | Identifier in external system |

## **Table system.report\_type**

Report model from the "Report Editor"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | The report ID |
| 1  | id | bigint | The report ID |
| 2  | name | character varying | Title of the report |
| 2  | name | character varying | Title of the report |
| 3  | description | character varying | Report Description |
| 3  | keyword | character varying | Report Description |
| 4  | keyword | character varying | Report keyword, almost never used (name instead) |
| 4  | description | character varying | Report keyword, almost never used (name instead) |
| 5  | status | character varying | Status report |
| 5  | version | bigint | Status report |
| 6  | root\_band\_id | bigint | Report version |
| 6  | version | bigint | Report version |
| 7  | group\_id | bigint | ID property from type\_property\_holder |
| 7  | property\_holder\_id | bigint | ID property from type\_property\_holder |
| 8  | root\_band\_id | bigint | ID of the parent band in this report |
| 8  | state | character varying | ID of the parent band in this report |
| 9  | state | character varying | Report status (locked/published) |
| 9  | dtype | character varying | Report status (locked/published) |

## **Table system.report\_type\_report\_model\_template**

Linking a report from the Report Editor and a data template

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | report\_type\_id | bigint | The report ID |
| 2  | report\_model\_template\_id | bigint | Template ID |

## **Table system.role**

Contains a list of user roles that can be configured by the administrator. Roles determine what privileges the current user has.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier of the user role, generated automatically |
| 2  | name | character varying | User-friendly short name of the role |
| 3  | description | character varying | User-friendly, detailed description of the role |
| 4  | status | character varying | Role status, one of the values ​​"ACTIVE", "DEPRECATED", "DISABLED" |
| 5  | is\_sys | boolean | If 1, the role is considered system and cannot be deleted or changed. |
| 6  | version | bigint | Version |
| 7  | is\_default | boolean | Indicates that the role is default for all employees |

## **Table system.role\_permissions**

Contains privilege assignments to a specific role.

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | role\_id | bigint | Reference to the role for which the privilege is defined |
| 2  | permission\_id | character varying | A reference to a privilege that is defined for the current role. |

## **Table system.schedule**

Working hours

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique work schedule identifier |
| 2  | name | character varying | Unique name of the work schedule |
| 3  | config\_string | character varying | Configuration of work schedule in xml form |
| 4 | version | bigint | Version |
| 5  | schedule\_template\_id | bigint | Job Schedule Template ID from schedule\_template |
| 6  | info | text | Raw data |
| 7  | info\_json | text | schedule changes in JSON format |
| 8  | bkp$\_config\_string | character varying | \- |
| 9  | bkp$\_info | text | \- |

## **Table system.schedule\_interval**

Schedule work interval

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique record identifier |
| 2  | schedule\_id | bigint | The work schedule to which the interval belongs |
| 3  | rotation | integer | Team number |
| 4  | shift\_number | integer | Shift number |
| 5  | my\_start | timestamp with time zone | Beginning of interval |
| 6  | max\_start | timestamp with time zone | End of interval |
| 7  | duration | bigint | Shift duration |
| 8  | step | bigint | Step in milliseconds (15min or 5min) |
| 9  | max\_duration | bigint | Maximum shift duration |
| 10  | additional\_shift | boolean | A sign that this is an extra shift |
| 11  | adjusted\_duration | bigint | Shift duration in milliseconds, including unpaid breaks |
| 12  | bkp$\_my\_start | timestamp without time zone | \- |
| 13  | bkp$\_max\_start | timestamp without time zone | \- |
| 14  | overtime\_duration\_before\_shift | bigint | Overtime duration before shift in milliseconds |
| 15  | overtime\_duration\_after\_shift | bigint | Overtime duration after shift in milliseconds |
| 16 | contract\_id | bigint | Contract identifier from an external system if this shift was created using an exchange |

## **Table system.schedule\_planning\_solution**

A schedule plan based on a template for one or more groups

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | Unique identifier |
| 2 | template\_id | bigint | The template from which the plan was created |
| 3 | update\_timestamp | timestamp with time zone | The moment of the last schedule update, used for versioning |
| 4 | start\_date | date | Start of the schedule period |
| 5 | end\_date | date | End of schedule period |
| 6 | comment | character varying | An arbitrary comment describing the schedule. Used to differentiate it from other schedule options. |
| 7 | config\_string | text | xml configuration used for planning. Includes both Optaplanner settings and weighting factors |
| 8 | result\_string | text | xml-planning result (last) |
| 9 | name | character varying | Schedule name |
| 10 | dtype | character varying | Schedule plan type (OperatingScheduleSolution,Timetable system.cheduleSolution) |
| 11 | used\_work\_schedule\_templates | boolean | Identify the used work schedule template |
| 12 | stat\_by\_years\_string | text | \- |
| 13 | stat\_by\_months\_string | text | \- |
| 14 | stat\_by\_days\_string | text | \- |
| 15 | bkp$\_update\_timestamp | timestamp without time zone | \- |
| 16 | cost | numeric | \- |
| 17 | parent\_id | bigint | Parent schedule ID |
| 18 | create\_timestamp | timestamp with time zone | Moment of creation |

## **Table system.schedule\_planning\_template**

Schedule Planning Template

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | name | character varying | Template name |
| 3  | status | character varying | Template Status |

## **Таблица system.schedule\_possible\_worker\_schedule\_template**

Linking the planned work schedule and work schedule templates of the employees who will participate in the planning

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | solution\_id | bigint | Planned Work Schedule Identifier |
| 2  | schedule\_template\_id | bigint | Identifiers of work schedule templates that participate in planning |

## **Table system.schedule\_solution\_schedule\_template**

Linking the planned work schedule and schedule templates that were additionally specified before planning

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | solution\_id | bigint | Planned Work Schedule Identifier |
| 2  | schedule\_template\_id | bigint | Identifier of work schedule templates that we additionally specify during planning |

## **Table system.schedule\_template**

Work Schedule Template

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Template ID |
| 2  | name | character varying | Template name |
| 3  | config\_string | character varying | template config (with frequency of changes/rotations, etc.) |
| 4  | status | character varying | template status (active/deactivated) |
| 5  | breaks\_config | text | Configure the PSU for the template |
| 6  | bkp$\_config\_string | character varying | \- |

## **Table system.scheme\_vacation**

Vacation schemes

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique record identifier |
| 2  | name | character varying | Record Title |
| 3  | config\_string | text | Configuration in which we store the duration of vacations |

## **System.service table**

Service in call center terms. Contains one or more groups

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique service identifier |
| 2  | name | character varying | Name of the service |
| 3  | description | character varying | Description of service |
| 4  | foreign\_id | text | External system identifier for integration |
| 5  | status | character varying | Status |
| 6  | version | bigint | Version |
| 7  | system\_id | integer | External system identifier |

## **The system.service\_group table**

Service-Group Interchange

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | service\_id | bigint | The service the group is a part of |
| 2  | group\_id | bigint | Group included in the service |

## **Table system.service\_group\_plan**

A group work plan for a specific forecast within the schedule

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | solution\_id | bigint | Schedule plan ID from schedule\_planning\_solution |
| 3  | service\_id | bigint | Service ID |
| 4  | group\_id | bigint | Group ID |
| 5  | stat\_by\_years\_string | text | \- |
| 6  | stat\_by\_months\_string | text | \- |
| 7  | stat\_by\_days\_string | text | \- |

## **Table system.shift\_break**

Entry from the Lunch and Break Directory Scheme

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Unique record identifier |
| 2  | shift\_breaks\_config\_id | bigint | Unique record identifier |
| 3  | my\_start | bigint | Minimum start of break interval relative to shift start in ms |
| 4  | max\_start | bigint | Maximum start of break interval relative to shift start in ms |
| 5  | shift\_type | character varying | Day or night |
| 6  | is\_payable | boolean | Is the interval paid? |
| 7  | duration | bigint | Duration in ms |
| 8  | word\_num | bigint | Serial number |
| 9  | interval\_type | character varying | Interval type |

## **Table system.shift\_breaks\_config**

Lunch and Break Configuration Handbook

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique record identifier |
| 2  | worker\_id | bigint | Employee |
| 3  | min\_shift\_duration | bigint | Minimum shift duration in ms |
| 4  | max\_shift\_duration | bigint | Maximum shift duration in ms |
| 5  | shift\_type | character varying | Shift type |
| 6  | breaks\_order\_type | character varying | Type of lunch and break order |
| 7  | min\_day\_duration | bigint | Minimum daily shift duration in ms |
| 8  | max\_day\_duration | bigint | Maximum daily shift duration in ms |
| 9  | min\_night\_duration | bigint | Minimum night shift duration in ms |
| 10  | max\_night\_duration | bigint | Maximum night shift duration in ms |
| 11  | min\_break\_distance | bigint | Minimum time without interruption in ms |
| 12  | max\_break\_distance | bigint | Maximum time without interruption in ms |

## **Table system.solution\_apply\_range**

Periods of solution activity

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | solution\_id | bigint | Solution ID |
| 2  | start\_date | date | Beginning of the period |
| 3  | end\_date | date | End of the period |

## **Table system.statistic\_indicator**

Call Service Statistical Indicators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique indicator identifier |
| 2  | name | text | Unique indicator code |
| 3  | is\_sys | boolean | System entry flag |

## **Table system.statuses\_vw**

Status information

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | state\_id | character varying | Status ID |
| 2 | state\_name | character varying | Status name |
| 3 | system\_id | character varying | External system identifier |
| 4 | is\_productive | boolean | Is the current status productive time? |
| 5 | is\_work\_load | boolean | Is the current status a net load? |
| 6 | absence | boolean | Is the current status time away? |
| 7 | is\_talk\_time | boolean | Checkbox "Talk time" |
| 8 | is\_break | boolean | Cheboks "Break Time" |
| 9 | is\_fact\_time | boolean | Actual time indicator in the timesheet |
| 10 | is\_productive\_work\_time | boolean | Signs of a productive working time |
| 11 | is\_after\_call\_work | boolean | Post-call processing |
| 12 | is\_operator\_active | boolean | Operator active and on lines |

## **The system.system\_timezone table**

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | zone\_id | character varying | \- |
| 2  | zone\_display\_name | character varying | \- |

## **Table system.template\_service\_group**

Service-Group Decoupling in Schedule Planning Template

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | template\_id | bigint | Schedule Planning Template |
| 2  | service\_id | bigint | Service |
| 3  | group\_id | bigint | Group |

## **Table system.threshold\_index**

Threshold values ​​of operational indicators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier of the load for a specific interval |
| 2  | description | character varying | Name of the indicator |
| 3  | bound\_crit\_upturn\_threshold | integer | Critical threshold value when the indicator increases |
| 4  | bound\_crit\_downturn\_threshold | integer | Critical threshold value when the indicator declines |
| 5  | bound\_acceptable\_upturn\_threshold | integer | Acceptable threshold value for growth of the indicator |
| 6  | bound\_acceptable\_downturn\_threshold | integer | Acceptable threshold value when the indicator declines |
| 7  | group\_id | integer | Unique identifier of the operator group to which the indicator belongs |
| 8  | service\_id | integer | Unique identifier of the service to which the metric belongs |

## **Table system.type\_property**

Stores a list of incoming report parameters

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Parameter ID |
| 2  | holder\_id | bigint | Holder ID |
| 3  | keyword | character varying | A keyword that is referenced in the report itself in query |
| 4  | dtype | character varying | Parameter data type (text/date, etc.) |
| 5  | name | character varying | Parameter name |
| 6  | description | character varying | Parameter Description |
| 7  | status | character varying | Parameter status |
| 8  | version | bigint | Parameter version |
| 9  | hint | character varying | A tooltip that appears when you hover over a parameter name when creating a report. |
| 10  | required | boolean | Checkbox "Required" |
| 11  | readonly | boolean | Checkbox "Read only" (not set in reports) |
| 12  | secured | boolean | The parameter becomes protected and cannot be read or written to, not the name of a specific access right. |
| 13  | indexed | boolean | Parameter indexed |
| 14  | filtered | boolean | The parameter is used for filtering. |
| 15  | statical | boolean | The parameter is read-only. |
| 16  | sys | boolean | Is it a system parameter (not specified in the report) |
| 17  | txt\_default | character varying | The default parameter value |
| 18  | txt\_pattern | character varying | The default parameter template |
| 19  | txt\_lines | integer | Number of lines for text input for a parameter with the type "text" |
| 20  | double\_default | double precision | Default dotted number |
| 21  | double\_min\_value | double precision | Minimum value of a digit with a dot |
| 22  | double\_max\_value | double precision | Maximum value of a digit with a dot |
| 23  | double\_precision | integer | Precision after decimal point for digit with dot |
| 24  | bool\_default | boolean | Default checkbox for type "Boolean" |
| 25  | date\_pattern | character varying | Parameter date format for type "Date" |
| 26  | date\_default | timestamp with time zone | Default date for type "Date" |
| 27  | date\_default\_start | timestamp with time zone | Date from: default |
| 28  | date\_default\_end | timestamp with time zone | Date by: default |
| 29  | ordinal\_number | integer | Parameter order |
| 30  | long\_default | bigint | Default long format number |
| 31  | long\_min\_value | bigint | Minimum number of long format |
| 32  | long\_max\_value | bigint | Maximum number of long format |
| 33  | unique | boolean | Should the parameter be unique? |
| 34  | txtarr\_default | ARRAY | Array of default text values |
| 35  | lkparr\_default | ARRAY | User guide with multi-selection |
| 36  | group\_id | bigint | ID of the parameter group to which this parameter belongs from type\_property\_group |
| 37  | hidden | boolean | Hidden (not used in reports) |
| 38  | bkp$\_date\_default | timestamp without time zone | \- |
| 39  | bkp$\_date\_default\_start | timestamp without time zone | \- |
| 40  | bkp$\_date\_default\_end | timestamp without time zone | \- |
| 41  | query | text | Request text |

## **The system.type\_property\_group table**

Stores groups of type\_property parameters

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Parameter group ID |
| 2  | keyword | character varying | Keyword |
| 3  | name | character varying | Name |
| 4  | description | character varying | Description |
| 5  | status | character varying | Status |
| 6  | ordinal\_number | integer | Order of parameter group |
| 7  | holder\_id | bigint | Holder ID |
| 8  | version | bigint | Version |

## **Table system.type\_property\_holder**

Holder for parameters, includes parameters from type\_property

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Holder ID |
| 2  | keyword | character varying | Keyword |
| 3  | name | character varying | Name |
| 4  | description | character varying | Description |
| 5  | status | character varying | Status |
| 6  | version | bigint | Version |

## **Table system.unpaid\_break\_rules**

Unpaid breaks from "Labor Standards"

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | ID records |
| 2  | my\_shift | bigint | Minimum shift time (shift duration) |
| 3  | type | character varying | Shift type |
| 4  | max\_shift | bigint | Maximum shift time (shift duration) |
| 5  | max\_day\_duration | bigint | Minimum duration of day shift |
| 6  | min\_day\_duration | bigint | Maximum duration of day shift |
| 7  | min\_night\_duration | bigint | Minimum duration of night shift |
| 8  | max\_night\_duration | bigint | Maximum duration of night shift |
| 9  | day\_break | bigint | Day break |
| 10  | night\_break | bigint | Night break |

## **Table system.user\_request**

User requests

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Application ID |
| 2  | create\_timestamp | timestamp with time zone | Date of application creation |
| 3  | author\_id | bigint | Requester ID |
| 4  | state | character varying | Application status |
| 5  | dtype | character varying | Application type |
| 6  | parent\_id | bigint | Identifier of the request originator |
| 7  | source\_start | timestamp with time zone | Initial time of the event start |
| 8  | expected\_start | date | The date to which the transfer is expected |
| 9  | supervisor\_id | bigint | ID of the manager who confirmed the application |
| 10  | worker\_from\_id | bigint | ID of the employee who created the request |
| 11  | worker\_to\_id | bigint | ID of the employee who accepted the application |
| 12  | vacation\_transfer\_id | bigint | Vacation ID to transfer |
| 13  | vacation\_from\_id | bigint | Sender's side leave ID |
| 14  | vacation\_to\_id | bigint | Recipient Party Leave Identifier |
| 15  | schedule\_interval\_transfer\_id | bigint | Shift ID to transfer |
| 16  | schedule\_interval\_from\_id | bigint | Sender side change identifier |
| 17  | schedule\_interval\_to\_id | bigint | Recipient Party Change Identifier |
| 18 | expected\_time\_start | time without time zone | Expected time of event |

## **Table system.user\_schedule\_planning\_config**

Stored User Scheduling Settings

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | name | character varying | Configuration name |
| 3  | description | character varying | Description of the config |
| 4  | config\_string | text | xml configuration used for planning. Includes both Optaplanner settings and weighting factors |
| 5  | version | integer | Version |

## **Table system.wish\_access**

Preferences Setting Reference

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | wish\_name | character varying | Name for preference setting |
| 3 | time\_zone | character varying | Time zone of the period when operators have the opportunity to enter preferences |
| 4 | open\_date\_time | timestamp with time zone | The beginning of the period when operators have the opportunity to enter preferences |
| 5 | closed\_date\_time | timestamp with time zone | End of the period when operators have the opportunity to enter preferences |
| 6 | start\_date | date | Start of the period for which operators can enter preferences |
| 7 | end\_date | date | End of the period for which operators can enter preferences |
| 8 | limit\_normal\_wish | integer | The maximum number of normal preferences an operator can enter |
| 9 | limit\_priority\_wish | integer | The maximum number of preferences that an operator can mark as a priority |

## **Table system.wish\_access\_worker**

Preferences Settings Reference Table

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | worker\_id | bigint | Preference |
| 3 | wish\_access\_id | bigint | \- |

## **Table system.work\_hours**

Handbook "Accounting of working hours"

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | id | bigint | Unique identifier |
| 2  | plan\_interval\_type | character varying | The type of interval to be taken into account |
| 3  | service\_id | bigint | Service |
| 4  | operator\_type | character varying | Operator type |
| 5  | pay\_type\_id | bigint | Payment type |
| 6  | productivity | boolean | What hours to consider when calculating output |
| 7  | payment | boolean | What hours to consider when calculating payment |

## **Table system.work\_rule**

Rules of work

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Rule ID |
| 2 | status | character varying | Activity status |
| 3 | with\_rotation | boolean | With or without rotation |
| 4 | config\_string | text | Rules configuration string in JSON format |
| 5 | name | character varying | Rule name |
| 6 | version | bigint | \- |
| 7 | production\_calendar | boolean | production calendar accounting flag |
| 8 | time\_zone | character varying | The time zone for which the work rule was assigned |
| 9 | used\_when\_planning\_vacancies | boolean | Can it be selected when planning vacancies? |

## **Table system.work\_rule\_designation**

Assigning work rules to operators

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1 | id | bigint | Assignment Record ID |
| 2 | worker\_id | bigint | Operator ID |
| 3 | work\_rule\_id | bigint | Work rule identifier |
| 4 | config\_string | text | \- |
| 5 | start\_date | date | Start period rules |
| 6 | end\_date | date | End of the rule validity period |
| 7 | version | bigint | \- |

## **system.worker table**

Call center employee

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | Unique employee identifier |
| 2 | is\_sys | boolean | Is the employee systemic? |
| 3 | tab\_no | character varying | Employee ID number |
| 4 | first\_name | character varying | Employee name |
| 5 | second\_name | character varying | Employee's patronymic |
| 6 | last\_name | character varying | Employee's last name |
| 7 | operator\_type | character varying | Operator type (home or office) |
| 8 | status | character varying | Record status (active or not) |
| 9 | breaks\_config | text | Configuration of employee breaks in xml format |
| 10 | version | bigint | Version |
| 11 | skill\_level | character varying | Employee skill level |
| 12 | can\_speak\_english | boolean | Does the employee speak a foreign language? |
| 13 | norm\_hours\_config | text | Configuration of the employee's production standard in xml format |
| 14 | foreign\_id | text | External system identifier for integration |
| 15 | telegram\_chat\_id | bigint | ID of the chat in telegram with the bot WfmCc |
| 16 | pay\_type\_id | integer | Employee payment type |
| 17 | is\_night\_work | boolean | Sign of work at night |
| 18 | norm\_day | bigint | Standard hours per day |
| 19 | norm\_week | bigint | Standard hours per week |
| 20 | employee\_rate | real | Bid |
| 21 | vacation\_config | text | vacation business rules settings |
| 22 | can\_work\_at\_weekends | boolean | An indication that a worker can work on weekends |
| 23 | can\_work\_over\_time | boolean | A sign that a worker may work overtime |
| 24 | employment | date | Date of employment |
| 25 | dismissal | date | Date of dismissal |
| 26 | accumulated\_vacation\_days | text | Accumulated vacation days |
| 27 | department\_id | bigint | Subdivision |
| 28 | position\_id | bigint | Job title |
| 29 | bkp$\_norm\_hours\_config | character varying | \- |
| 30 | time\_zone | character varying | Employee time zone |
| 31 | bkp$\_accumulated\_vacation\_days | character varying | \- |
| 32 | cost | numeric | Cost of an employee's hour of work |
| 33 | comment | character varying | \- |
| 34 | sn | character varying | Operator ID in lk |
| 35 | db\_id | character varying | Master system identifier in lk |
| 36 | area\_id | bigint | Name of the site in lk |

## **Table system.worker\_actual\_kpi**

Up-to-date information on KPI indicators for operators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Unique employee identifier in the system |
| 2  | aht | integer | Average operator talk time in milliseconds, obtained using the integration method |

## **Table system. worker\_actual\_schedules\_vw**

Changes in current employee schedules

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | worker\_id | bigint | Employee ID |
| 2 | worker\_tz | character varying | Employee time zone |
| 3 | sol\_id | bigint | Employee Schedule Solution ID |
| 4 | sol\_template\_id | bigint | Employee Schedule Planning Template ID |
| 5 | sol\_interval\_duration | bigint | IntervalDuration of employee schedule |
| 6 | psd\_id | bigint | Employee Schedule PSD ID |
| 7 | psd\_start\_date | date | Schedule start date |
| 8 | psd\_end\_date\_exclusive | date | Schedule end date (exclusive) |
| 9 | and\_id | bigint | Employee schedule shift ID |
| 10 | si\_duration | bigint | Basic shift duration, msec |
| 11 | si\_adjusted\_duration | bigint | Shift duration with unpaid lunches and breaks, msec |
| 12 | si\_overtime\_duration\_before\_shift | bigint | Overtime shift duration before the main shift time, msec |
| 13 | si\_overtime\_duration\_after\_shift | bigint | Overtime shift duration after main shift time, msec |
| 14 | say\_my\_start | timestamp with time zone | Minimum start time of the main work of the shift |
| 15 | si\_max\_start | timestamp with time zone | Maximum start time of the main work of the shift |
| 16 | si\_start\_with\_overtime | timestamp with time zone | Shift start time including overtime |
| 17 | si\_duration\_with\_overtime | bigint | Shift duration including overtime, msec |
| 18 | si\_min\_end\_exclusive | timestamp with time zone | Shift end time from minimum shift start time for main duration |
| 19 | si\_end\_with\_overtime\_exclusive | timestamp with time zone | Shift end time from minimum shift start time taking into account overtime |
| 20 | si\_with\_overtime | boolean | Sign whether the shift is with overtime or not |
| 21 | si\_additional | boolean | Sign, additional shift or not |

## **Table system.worker\_actual\_status**

Information about the current status of the operator

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Unique employee identifier |
| 2  | operator\_state\_id | bigint | Current employee status identifier (according to data from the CSO) |
| 3  | last\_online\_time | timestamp with time zone | The time when the operator was last on the line (according to the current status) |
| 4  | seconds\_in\_state | bigint | The time the operator has been in the current status in seconds |
| 5  | last\_update\_time | timestamp with time zone | Time of last status request |
| 6  | bkp$\_last\_online\_time | timestamp without time zone | \- |
| 7  | bkp$\_last\_update\_time | timestamp without time zone | \- |

## **Table system.worker\_change\_status\_log**

Information about the operator's status as a Call Center

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Operator |
| 2  | state\_id | bigint | Status type |
| 3  | date\_from | timestamp with time zone | The time when the operator started being in the current status |
| 4  | date\_to | timestamp with time zone | End time of the operator's current status |
| 5  | system\_id | bigint | External system identifier |
| 6  | bkp$\_date\_from | timestamp without time zone | \- |
| 7  | bkp$\_date\_to | timestamp without time zone | \- |
| 8  | foreign\_login\_id | text | External employee identifier |

## **Table system.worker\_contact**

Employee-contact denouement

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee with contact |
| 2  | contact\_id | bigint | Employee contact |

## **Table system.worker\_foreign\_login**

Linking a worker and its logins to external integration systems

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | login\_foreign\_id | text | External account foreign\_id |
| 2  | system\_id | bigint | Accounting system |
| 3  | worker\_id | bigint | Worker |
| 4  | login\_name | text | Account name |

## **Table system.worker\_foreign\_login\_group**

Interchange worker\_foreign\_login \- group

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | foreign\_id | text | External account id |
| 2  | system\_id | bigint | Accounting system |
| 3  | group\_id | bigint | Accounting group |

## **Table system.worker\_historic\_status**

Table storing the statuses of operators received from integration systems

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | ID worker а |
| 2  | service\_id | bigint | Service ID |
| 3  | group\_id | bigint | Group ID |
| 4  | state\_id | bigint | Integration system status ID |
| 5  | date\_from | timestamp with time zone | Status start date |
| 6  | date\_to | timestamp with time zone | Status End Date |
| 7  | duration\_in\_state | bigint | Time spent in status |
| 8  | bkp$\_date\_from | timestamp without time zone | \- |
| 9  | bkp$\_date\_to | timestamp without time zone | \- |
| 10 | system\_id | integer | \- |
| 11 | id | integer | \- |

## **Table system.worker\_historical\_fact**

Historical fact about the employee

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee |
| 2  | creation\_date | timestamp with time zone | Time of change |
| 3  | fact\_type | text | Type of change |
| 4  | new\_value | text | New meaning |
| 5  | initiator | text | Change initiator |
| 6  | id | bigint | ID records |
| 7  | bkp$\_creation\_date | timestamp without time zone | \- |

## **Table system.worker\_icon**

Employee icon

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee ID |
| 2  | photo | bytea | Icon |

## **Table system.worker\_monitoring\_config**

Configuration of display of monitoring widgets for operators

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Operator ID |
| 2  | service\_id | bigint | Service identifier |
| 3  | group\_id | bigint | Group ID |
| 4  | statistic\_indicator\_id | bigint | Statistical indicator identifier |
| 5  | is\_notification | boolean | Notifying the operator about changes in this indicator |

## **Table system.worker\_position**

History of the positions of co-workers

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique record identifier |
| 2  | worker\_id | bigint | Employee |
| 3  | position\_id | bigint | Job title |
| 4  | change\_date | date | Date of change of position |

## **Table system.worker\_role**

Assigning a role to an employee

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | worker\_id | bigint | Employee wanted |
| 2  | role\_id | bigint | Assigned role |

## **Table system.worker\_schedule**

Assigning a work schedule to an employee

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique record identifier |
| 2  | worker\_id | bigint | Employee |
| 3  | schedule\_id | bigint | Work schedule assigned to an employee |
| 4  | rotation | integer | The number of the team in which the employee works |
| 5  | valid\_from | date | Start of the schedule period for this employee |
| 6  | valid\_to | date | End of the schedule period for this employee |

## **Table system.worker\_schedule\_event**

Special Employee Event

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | Unique record identifier |
| 2 | worker\_id | bigint | Employee |
| 3 | start\_timestamp | timestamp with time zone | The moment the event starts |
| 4 | end\_timestamp | timestamp with time zone | The moment the event ends |
| 5 | event\_type | character varying | Event type |
| 6 | comment | character varying | Free commentary on the event |
| 7 | dtype | character varying | Entity Discriminator |
| 8 | scheme\_vacation\_id | bigint | Dismissal scheme |
| 9 | pinned | boolean | Fixed event (does not move when scheduling) |
| 10 | priority | boolean | Priority for planning |
| 11 | status | character varying | Event status (active/inactive) |
| 12 | schedule\_designation\_id | bigint | Assignment to employee |
| 13 | absent\_reason\_id | bigint | Reason for absence |
| 14 | bkp$\_start\_timestamp | timestamp without time zone | \- |
| 15 | bkp$\_end\_timestamp | timestamp without time zone | \- |
| 16 | duration\_in\_days | bigint | Duration of vacation in days |
| 17 | number\_of\_holidays | bigint | Number of holidays |

## **Table system.worker\_scheme\_vacation**

Employee Interchange \- Vacation Scheme

| Serial number | Designation | Data type | Description |
| ----- | ----- | ----- | ----- |
| 1  | worker\_id | bigint | Employee |
| 2  | scheme\_vacation\_id | bigint | Scheme |
| 3  | is\_main | boolean | Basic scheme |

## **Table system.worker\_timesheet\_status**

Entity describing changes to the timesheet

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | id | bigint | Unique identifier |
| 2  | change\_time | timestamp with time zone | Time of change |
| 3  | change\_worker\_id | bigint | The employee who made the changes |
| 4  | worker\_id | bigint | Employee |
| 5  | foreign\_id | text | Employee in the integration system |
| 6  | record\_date | timestamp with time zone | The date for which the information was saved |
| 7  | status | character varying | Status |
| 8  | comment | text | Comment |
| 9  | bkp$\_change\_time | timestamp without time zone | \- |
| 10  | bkp$\_record\_date | timestamp without time zone | \- |

## **Table system. worker\_wish**

Table with entered user preferences

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1 | id | bigint | \- |
| 2 | worker\_id | bigint | Preference related operator |
| 3 | wish\_access\_id | bigint | Preference |
| 4 | wish\_date | date | The date on which the operator sets the preference |
| 5 | wish\_day\_type | character varying | Day type \- working day or day off |
| 6 | start\_interval\_min | bigint | Minimum shift start time in milliseconds from the start of the day |
| 7 | start\_interval\_max | bigint | Maximum shift start time in milliseconds from the start of the day |
| 8 | end\_interval\_min | bigint | Minimum shift end time in milliseconds from the start of the day |
| 9 | end\_interval\_max | bigint | Maximum shift end time in milliseconds from the start of the day |
| 10 | duration\_interval\_min | bigint | Minimum shift duration in milliseconds |
| 11 | duration\_interval\_max | bigint | Maximum shift duration in milliseconds |
| 12 | priority | boolean | Priority Preference or Normal |

## **Table system.x\_clear\_log**

Log cleaning of obsolete data

| Serial number | Designation | Data type | Description |
| :---- | :---- | :---- | :---- |
| 1  | executed\_at | timestamp without time zone | Cleaning start time |
| 2  | table\_name | text | Clearable table |
| 3  | execution\_time | interval | Cleaning duration |
| 4  | rows\_affected | bigint | Records removed |
| 5  | error\_msg | text | Error message |

