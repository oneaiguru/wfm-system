    1: 
    2: 
    3: Table of contents
    4: 
    5: [Approval sheet	4](#approval-sheet)
    6: 
    7: [Change registration sheet	5](#change-registration-sheet)
    8: 
    9: [Terms and definitions	6](#terms-and-definitions)
   10: 
   11: [1\. integration points	7](#1.-integration-points)
   12: 
   13: [2\. Concept of problem solving	9](#2.-concept-of-problem-solving)
   14: 
   15: [1C ZUP database is published on the Web server.	9](#1c-zup-database-is-published-on-the-web-server.)
   16: 
   17: [3\. description of the exchange rules.	10](#3.-description-of-the-exchange-rules.)
   18: 
   19: [3.1. data on employees and leave balances retrieved	10](#3.1.-data-on-employees-and-leave-balances-retrieved)
   20: 
   21: [3.1.1 Employee data	10](#3.1.1-employee-data)
   22: 
   23: [3.1.2 Data by subdivision	11](#3.1.2-data-by-division)
   24: 
   25: [3.1.3 Algorithm for calculating vacation balances	11](#3.1.3-algorithm-for-calculating-vacation-balances)
   26: 
   27: [3.1.4 Exchange with the WFM system	12](#3.1.4-exchange-with-the-wfm-system)
   28: 
   29: [3.1.4.1 Description of method	13](#3.1.4.1-description-of-method)
   30: 
   31: [3.2. getNormHours \- Time norm according to the production calendar	16](#3.2.-getnormhours---time-norm-according-to-the-production-calendar)
   32: 
   33: [3.2.1 Calculation algorithm	16](#3.2.1-algorithm-calculation)
   34: 
   35: [3.2.2 Exchange with the WFM system	17](#3.2.2-exchange-with-the-wfm-system)
   36: 
   37: [3.2.2.1 Description of the getNormHours method	17](#3.2.2.1-description-of-the-getnormhours-method)
   38: 
   39: [3.2.3 Actualization of Time Standards according to the production calendar	20](#3.2.3-actualization-of-time-standards-according-to-the-production-calendar)
   40: 
   41: [3.2.4 Time rate per week	21](#3.2.4-time-rate-per-week)
   42: 
   43: [3.3. sendSchedule \- Work schedules	21](#3.3.-sendschedule---work-schedules)
   44: 
   45: [3.3.1 Calculation algorithm	21](#3.3.1-calculation-algorithm)
   46: 
   47: [3.3.2 Exchange with the WFM system	22](#3.3.2-exchange-with-the-wfm-system)
   48: 
   49: [3.3.2.1 Description of the sendSchedule method	23](#3.3.2.1-description-of-the-sendschedule-method)
   50: 
   51: [3.4. getTimetypeInfo \- timesheet	24](#3.4.-gettimetypeinfo---timesheet)
   52: 
   53: [3.4.1 Calculation algorithm	24](#3.4.1-calculation-algorithm)
   54: 
   55: [3.4.2 Exchange with the WFM system	24](#3.4.2-exchange-with-the-wfm-system)
   56: 
   57: [3.4.2.1 Description of getTimetypeInfo method	25](#3.4.2.1-description-of-gettimetypeinfo-method)
   58: 
   59: [3.5. sendFactWorkTime \- General description of the exchange algorithm when working with the Operator Work Monitoring Tool (WFM-system)	27](#3.5.-sendfactworktime---general-description-of-the-exchange-algorithm-when-working-with-the-operator-work-monitoring-tool-\(wfm-system\))
   60: 
   61: [3.5.1 Deviations with time type "RW", "RWN", "NN", "C" (integration point of the timesheet)	27](#3.5.1-deviations-with-time-type-"rw",-"rwn",-"nn",-"c"-\(integration-point-of-the-timesheet\))
   62: 
   63: [3.5.1.1 Calculation algorithm	28](#3.5.1.1-calculation-algorithm)
   64: 
   65: [3.5.1.2 Exchange with the WFM system	28](#3.5.1.2-exchange-with-the-wfm-system)
   66: 
   67: [3.5.1.2.1 Description of the sendFactWorkTime method	28](#3.5.1.2.1-description-of-the-sendfactworktime-method)
   68: 
   69: [3.5.2 Filling in other fields of created documents	30](#3.5.2-filling-in-other-fields-of-created-documents)
   70: 
   71: [3.5.3 Conducting documents	31](#3.5.3-conducting-documents)
   72: 
   73: [4\. Initial data upload	32](#4.-initial-data-upload)
   74: 
   75: [5\. Necessary improvements to the 1C ZUP configuration	33](#5.-necessary-improvements-to-the-1c-zup-configuration)
   76: 
   77: [6\. Requirements for setting access rights for the integration system user	34](#6.-requirements-for-setting-up-access-rights-for-the-integration-system-user)
   78: 
   79: [7\. Requirements for customization of 1C: Salary and Personnel Management	35](#7.-requirements-for-customization-of-1c:-salary-and-personnel-management)
   80: 
   81: [8\. Appendices	36](#8.-appendices)
   82: 
   83: [8.1 Appendix 1\. List of 1C \- JSON fields	36](#8.1-appendix-1.-list-of-1c---json-fields)
   84: 
   85: [8.2 Appendix 2\. Correspondence of time types to 1C ZUP documents	36](#8.2-appendix-2.-correspondence-of-time-types-to-1c-zup-documents)
   86: 
   87: 	
   88: 
   89: # **Approval sheet**  {#approval-sheet}
   90: 
   91: | Position | NAME | Caption | Date | Note |
   92: | :---- | :---- | :---- | :---- | :---- |
   93: |  |  |  |  |  |
   94: |  |  |  |  |  |
   95: |  |  |  |  |  |
   96: |  |  |  |  |  |
   97: 
   98: # **Change registration sheet** {#change-registration-sheet}
   99: 
  100: | Version | Date | Performer | Changes |
  101: | :---- | :---- | :---- | :---- |
  102: |  |  |  |  |
  103: |  |  |  |  |
  104: 
  105: # **Terms and definitions** {#terms-and-definitions}
  106: 
  107: | term | Determination |
  108: | :---- | :---- |
  109: | 1C ZUP, 1C | 1C Salary and Personnel Management CORP configuration, version 3.1 |
  110: | UID | Unique identifier |
  111: | MS. | Information Register |
  112: | RH | Accumulation register |
  113: | Accumulation register | Time rate according to the production calendar |
  114: | Time rate per week | The length of the working week established for an employee |
  115: 
  116: # **1\. integration points** {#1.-integration-points}
  117: 
  118: * Work schedules
  119: 
  120: It is necessary to load into 1C: ZUP 3.1 the work schedules of employees, which can be individualized in the process of planning, linking work schedules to employees
  121: 
  122: * Vacation schedules
  123: 
  124: It is necessary to upload from WFM the vacation schedules of operators in Excel format with the following fields filled in:
  125: 
  126: * Employee \- full name of the employee
  127: 
  128: * Type of leave \- automatically set to "Basic"
  129: 
  130: * The start date is the date the vacation begins
  131: 
  132: * The end date is the date on which the vacation ends
  133: 
  134: | № | Name | Document |
  135: | :---: | ----- | :---: |
  136: | 1\. | Example of an upload file | ![][image1] |
  137: 
  138: The file should be uploaded to the 1C system in the document "Vacation Schedule".
  139: 
  140: * Normative \- employee's time rate according to the production calendar
  141: 
  142: It is necessary to upload from 1C the normative output of an employee for the year when uploading the employee himself, on request at dismissal
  143: 
  144: * Vacation balances
  145: 
  146: It is necessary to be able to upload from 1C the remaining vacation days of an employee as of the requested date
  147: 
  148: * Timesheets
  149: 
  150: Planning of work schedules and calculation of actually worked time is performed on the WFM-system side. Accounting of deviations is performed on the side of 1C: ZUP 3.1. Two-way data exchange is required.
  151: 
  152: The WFM-system is the source of generation of the timesheet.
  153: 
  154: * The "I", "N" and "B" time types are defined on the 1C side after loading the work schedule from WFM.
  155: 
  156: * Deviations from the schedule with time type "RV", "RVN", "NV", "C" are initiated in the WFM system. The actual deviation time (date, deviation start time, deviation end time) is transferred from WFM to 1C.
  157: 
  158: * Determination of the time type is performed on the 1C side based on the deviation of the plan from the fact.
  159: 
  160: * Depending on the result of determining the type of time, 1C automatically creates the corresponding document.
  161: 
  162: * Types of time whose input source is 1C: ZUP are listed in [Appendix 2 to the CHTZ](#bookmark=id.p44tylnl4mal).
  163: 
  164: # **2\. Concept of problem solving** {#2.-concept-of-problem-solving}
  165: 
  166: ## **1C ZUP database is published on the Web server.** {#1c-zup-database-is-published-on-the-web-server.}
  167: 
  168: This requires:
  169: 
  170: * Web server installation (Apache or IIS)
  171: 
  172: * Installing the web server extension on the 1C Platform
  173: 
  174: An http service is created in the 1C base.
  175: 
  176: As described below, methods are implemented that generate data packets in JSON format on requests.
  177: 
  178: **Exchange with the server**
  179: 
  180: The server must respond to each request with a status (HTTP status) of 200 or 500
  181: 
  182: * 200 if the request is successfully processed
  183: 
  184: * 500 if there is an error in the request
  185: 
  186: The format of the response from the server is JSON.
  187: 
  188: All access to the server is made via a single address like [http://servername/instancename/hs/apiname.](http://servername/instancename/hs/apiname)
  189: 
  190: Accesses to the server are formed in the form of POST and GET requests.
  191: 
  192: # **3\. description of the exchange rules.** {#3.-description-of-the-exchange-rules.}
  193: 
  194: ## **3.1. data on employees and leave balances retrieved** {#3.1.-data-on-employees-and-leave-balances-retrieved}
  195: 
  196: ### **3.1.1 Employee data** {#3.1.1-employee-data}
  197: 
  198: Data should be uploaded only for employees in the group of subdivisions selected as the exchange subdivision in the register "WFM accounting subdivisions"
  199: 
  200: Discharge Rules:
  201: 
  202: * Employees hired are uploaded (Hire Date filled in).
  203: 
  204: * Terminated employees are uploaded within one month of the termination date (necessary to ensure that WFM receives the termination date). Employees terminated more than one month ago are not included in the upload. When the dismissal date is received in WFM, the employee is deactivated (deactivation occurs the day after the dismissal).
  205: 
  206: * Data on employees received from the system registers (full name, position, etc.) are unloaded as of the current date (date of sending a request from WFM).
  207: 
  208: Sources for obtaining employee data:
  209: 
  210: |  | Data | Data source |
  211: | :---- | :---- | :---- |
  212: | 1 | employee ID | Employees directory |
  213: | 2 | Tab. number | Employees directory |
  214: | 3 | Date of employment | RS Current personnel data of employees |
  215: | 4 | Date of termination | RS Current personnel data of employees |
  216: | 5 | Surname | RS Current personnel data of employees |
  217: | 6 | Name | RS Current personnel data of employees |
  218: | 7 | Patronymic | RS Current personnel data of employees |
  219: | 8 | PID of the post | RS Personnel history of employees |
  220: | 9 | Position | RS Personnel history of employees |
  221: | 10 | Date of change of position | RS Personnel history of employees |
  222: | 10 | Unit ID | RS Personnel history of employees |
  223: | 11 | Number of rates | RS Personnel history of employees |
  224: | 12 | Hours per week | RS Personnel history of employees |
  225: | 13 | Date of norm change per week | RS Personnel history of employees |
  226: | 14 | SN | RS Current personnel data of employees |
  227: | 15 | Db\_ID | RS Current personnel data of employees |
  228: | 16 | area | RS Current personnel data of employees |
  229: 
  230: ### 
  231: 
  232: ### **3.1.2 Data by division** {#3.1.2-data-by-division}
  233: 
  234: Divisions are unloaded as a two-level hierarchy. The subdivisions are unloaded:
  235: 
  236: ![/download/attachments/276529242/image2023-10-25%2014%3A33%3A12.png?version=1\&modificationDate=1698233595000\&api=v2][image2]
  237: 
  238: ### **3.1.3 Algorithm for calculating vacation balances** {#3.1.3-algorithm-for-calculating-vacation-balances}
  239: 
  240: Data on employee vacation balances are not stored in 1C objects. Therefore, leave balances for integration purposes are calculated by calculation.
  241: 
  242: 1. Periods of accrual of regular vacation entitlement are determined. This calculation is performed using the standard 1C ZUP algorithm. Currently, the calculation is organized in such a way that each month has only one entitlement accrual date (below is a description of the calculation algorithm from the official ITS site)
  243: 
  244: 2. The number of vacation days for one month (basic vacation and additional vacation, if any) is determined. This calculation is carried out using the standard 1C ZUP algorithm
  245: 
  246: 3. As of the date transferred from WFM of the beginning of the period, the leave balance is calculated. Leave balance is calculated based on leave entitlements and the amount of leave actually used
  247: 
  248: If the transferred beginning date of the period is less than the beginning of the current month, the leave balance is calculated as of the current month's entitlement accrual date
  249: 
  250: 1. The number of vacation days entitlement is then added to the Vacation Balance on each regular entitlement accrual date
  251: 
  252: Calculation algorithm of 1C ZUP version higher than 3.1.7
  253: 
  254: *In version 3.1.7, the algorithm for accruing earned vacation has been refined.*
  255: 
  256: *It should be recalled that the rules for accrual of earned vacation are determined by [**p. 35 of USSR NKT .04.1930 No. 169:35. 35 of Decree of**](https://its.1c.ru/db/garant/content/81735/1/35) the decree of 30the USSR NKT 30.04.1930 No. 169:35. When calculating the periods of work entitling to proportional additional vacation or vacation compensation upon dismissal, surpluses of less than half a month are excluded from the calculation, and surpluses of at least half a month are rounded up to a full month.*
  257: 
  258: *The regulation does not define how to calculate half a month. In the previous implementation, the duration of the calendar month in which most of the month worked fell was used to calculate the half-month. But because of the different number of days in calendar months, there were situations when no accrual occurred during a calendar month, or, on the contrary, accrual occurred twice in a calendar month.*
  259: 
  260: *For example, an employee is hired on the 17th day. Most of the period 17.07.16 \- 16.08.16 falls in August, accordingly, it was considered that the duration of the month is 31 days, half of the month worked at the end of the day 01.08.16. The next period 17.08.16 \- 16.09.16. Most of the period falls in September, accordingly, it was considered that the duration of the month is 30 days, half of the month worked at the end of the day 31.08.16. As a result, in August, the rights were accrued twice.*
  261: 
  262: *Now the algorithm has been changed:*
  263: 
  264: * If half a month or more is worked in the calendar month in which the working year begins, we define the vesting date for each calendar month as the end of the previous working month plus half of the month's duration. In this case, we limit the date of accrual of rights to the end of the month. For example, the working year starts on February 15, 17\. The condition "half of the month or more worked" is met, 14 days were worked in February. The dates of rights accrual will be:
  265: 
  266:   * 28.02.17 (14.02.17 \+ 14 days)
  267: 
  268:   * 30.03.17 (14.03.17 \+ 16 days)
  269: 
  270:   * 29.04.17 (14.04.17 \+ 15 days)
  271: 
  272:   * Etc.
  273: 
  274:   * If less than half of the calendar month in which the working year begins is worked, the accrual of rights will take place when the sum of the "scraps" equals 15 days. For example, the working year starts on 20.02.17. The dates of rights accrual will be:
  275: 
  276:     * 06.03.17 (9 days worked in February and 6 in March).
  277: 
  278:     * 06.04.17 (9 days worked in February and 6 in April).
  279: 
  280:     * 06.05.17 (9 days worked in February and 6 in May).
  281: 
  282:     * Etc.
  283: 
  284:     * The exception is the situation when the working year begins on the 17th day of a month in which there are 31 days. In this case, rights accrual occurs when the sum of the "trims" equals 16 days. For example, the working year starts on 17.01.17. The dates of rights accrual will be:
  285: 
  286:       * 01.02.17 (15 days worked in January and 1 in February).
  287: 
  288:       * 01.03.17 (15 days worked in January and 1 in March).
  289: 
  290:       * 01.04.17 (15 days worked in January and 1 in April).
  291: 
  292:       * Etc.
  293: 
  294: Source: ITS website [https://its.1c.ru/db/updinfo\#content:572:1:issogl1\_3](https://its.1c.ru/db/updinfo#content:572:1:issogl1_3)
  295: 
  296: ### **3.1.4 Exchange with the WFM system** {#3.1.4-exchange-with-the-wfm-system}
  297: 
  298: * On request initiated in the WFM system: method agents
  299: 
  300: * [When initially uploading data](#bookmark=id.kx0ow0k9oepv)
  301: 
  302: **Direction of exchange: 1C \-\> WFM**
  303: 
  304: * The request is automatically initiated by the WFM system once a day (depending on the time set) or at the request of the WFM user.
  305: 
  306: * This query combines data on departments, employees, and employee leave balances
  307: 
  308: * The data is uploaded for all employees meeting the selection conditions (selection conditions are described above in the Employee Data section)
  309: 
  310: * The period passed in the request from WFM is used to retrieve vacation balances
  311: 
  312: * The data is grouped into arrays: an array of departments, an array of employees with a nested array of employee vacation balances.
  313: 
  314: ### **3.1.4.1 Description of method** {#3.1.4.1-description-of-method}
  315: 
  316: 1\. Input data (WFM-\>1C)
  317: 
  318: | № | Data | Name in 1C | Example | Type | Commentary |
  319: | :---- | :---- | :---- | :---- | :---- | :---- |
  320: | 1 | Start of the period for requesting leave balances | startDate | 2019-01-01 | Date | date |
  321: | 2 | End of leave balances request period | endDate | 2019-12-31 | Date | date |
  322: 
  323: **Request format from WFM**
  324: 
  325: Method: **GET**
  326: 
  327: Template:/agents/{startDate}/{endDate}
  328: 
  329: 2\. Returned data (1C-\>WFM)
  330: 
  331: | № | Data |  | Name in 1C | Example | Type | Indication that the parameter is mandatory | Commentary |
  332: | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  333: | 1 | Divisions |  | AR\_departments |  | Array | Yes | Array of subdivisions |
  334: | 2 |  | Unit ID | departmentId | 15fcd79e-7352-11e6-80ef-00155d6651df | String | Yes |  |
  335: | 3 |  | Name of division | department | Customer Service Department No. 1 | String | Yes |  |
  336: | 4 |  | UID of the superior unit | parentDepartmentId | b306e82b-74df-11e6-80ef-00155d6651df | String | Yes |  |
  337: | 5 | Employees |  | AR\_agents |  | Array | Yes | Employee data array |
  338: | 6 |  | employee ID | agentId | 7135c70d-b771-11e9-8101-00505690fbe1 |  | Yes |  |
  339: | 7 |  | Job number | tabN | 10-000 | String | Yes |  |
  340: | 8 |  | Surname | lastname | Zubkov | String | Yes |  |
  341: | 9 |  | Name | firstname | Savely | String | Yes |  |
  342: | 10 |  | Patronymic | secondname | Petrovich | String | Yes |  |
  343: | 11 |  | Date of employment | startwork | 2016-09-01 | Date | Yes | date |
  344: | 12 |  | Date of termination | finishwork | 2016-09-01 | Date | No | It's not being sent to a working employee. If fired, the Dismissal Date is not sent from 1c |
  345: | 13 |  | PID of the post | positionId | 79bc9e60-a283-11e7-80f5-00155df19317 | String | Yes |  |
  346: | 14 |  | Job title | position | Leading specialist | String | Yes |  |
  347: | 15 |  | Date of change of position | positionChangeDate | 2016-09-10 | Date | No | date |
  348: | 16 |  | Unit ID | departmentId | 15fcd79e-7352-11e6-80ef-00155d6651df | String | Yes |  |
  349: | 17 |  | Number of rates | rate | 0,5 | number | No |  |
  350: | 18 |  | Login | Login | d6651df | String | No | Additional props |
  351: | 19 |  | Rate per week | normWeek | 40 | number | Yes |  |
  352: | 20 |  | Date of norm change per week | normWeekChangeDate | 2016-09-10 | Date | Yes | If the operator is newly employed, the date of employment is sent. Next, the date of norm change per week and the new norm value in normWeek are sent |
  353: | 21 |  | Additional field 1  | SN | 12345678978 | String | No | Any necessary parameter can be passed to the field |
  354: | 22 |  | Additional ID | Db\_ID | 123647382342 | String | No | It is possible to transfer the ID of another system if necessary |
  355: | 23 |  | Platform | area | Yekaterinburg | String | No | Site. The location of the operator. The field may contain the city of registration or the city from which the employee plans to operate. |
  356: | 24 | Vacation balances |  | AR\_vacation |  | Array | No | Vacation balances data array |
  357: | 25 |  | Date | date | 2019-08-27 | Date | No | Date of accrual of regular vacation entitlement |
  358: | 26 |  | Number of days | vacation | 11.67 | number | No | Accumulated vacation days balance |
  359: 
  360: **Response Format:**
  361: 
  362: |  \[   {     { "AR\_departments": \[       {         "departmentId": "03d19161-7352-11e6-80ef-00155d6651df",         { "department": { "service department",         "parent\_departmentId": "03d19161-7352-11e6-80ef-00155d6651df"       },       {         "departmentId": "15fcd79e-7352-11e6-80ef-00155d6651df",         { "department": "Customer service department: customer service group No. 3",         "parent\_departmentId": "03d19161-7352-11e6-80ef-00155d6651df"       }     \],     { "AR\_agents": \[       {         "agentId": "162a53e3-7a51-11e6-80ec-00155d00edab",  "tabN": "223-16",  }, "lastname": "Shastny",  }, "firstname": "Nikita",  }, "secondname": "Alekseevich",         { "startwork": "2016-09-01",         }, "finishwork": null,         "positionId": "79bc9e60-a283-11e7-80f5-00155df19317",         { "position": "Senior Professional",         "positionChangeDate": "2016-09-01",         "departmentId": "b306e82b-74df-11e6-80ef-00155d6651df",         "rate": 1,         "Login": "d6651df",         { "normWeek": 40,         "normWeekChangeDate": "2016-09-01",         "SN": "12345678978",         "Db\_ID": "123647382342",         }, "area": "Yekaterinburg",         { "AR\_vacation": \[           {             "date": "2019-10-16",             { "vacation": 4.67           },           {             "date": "2019-11-15",             { "vacation": 7.00333           }         \]       },       {         "agentId": "ddecd30a-7a52-11e6-80ec-00155d00edab",  "tabN": "224-16",  }, "lastname": "Levine",  }, "firstname": "alina",  }, "secondname": "Vitalievna",         { "startwork": "2016-09-01",         }, "finishwork": null,         "positionId": "79bc9e60-a283-11e7-80f5-00155df19317",         { "position": "Senior Professional",         "positionChangeDate": "2016-09-01",         "departmentId": "b306e82b-74df-11e6-80ef-00155d6651df",         "rate": 1,         { "normWeek": 40,         "normWeekChangeDate": "2016-09-01",         { "AR\_vacation": \[           {  "date": "2019-10-27",             { "vacation": 25.67           },           {  "date": "2019-11-26",             { "vacation": 28.00333           }         \]       }     \]   } \]  |
  363: | :---- |
  364: 
  365: ## **3.2. getNormHours \- Time norm according to the production calendar** {#3.2.-getnormhours---time-norm-according-to-the-production-calendar}
  366: 
  367: * From the WFM-system will be transmitted [*the weekly time rate*](#bookmark=id.ukvjlujg1t3n) for the employee
  368: 
  369: * From 1C: Output rate for an employee
  370: 
  371: ### **3.2.1 Algorithm calculation** {#3.2.1-algorithm-calculation}
  372: 
  373: The time rate is calculated according to the formula:
  374: 
  375: **Time** *rate* **for the period** \= (Time rate per week / 5 \* Number of working days of a 5-day working week \- Number of hours by which working hours are reduced on the eve of public holidays) \* *Employee rate*
  376: 
  377: Due to the fact that in 1C ZUP, when setting the weekly norm, the reduction of the norm is immediately taken into account, the multiplication by the rate is not performed when calculating the standard of performance.
  378: 
  379: **Data sources for calculation in 1C ZUP**
  380: 
  381: | № | Formula component | Data source | Data |
  382: | :---- | :---- | :---- | :---- |
  383: | 1 | Time rate per week | The parameter is transferred from WFM | normWeek |
  384: | 2 | Number of days of 5-day working week | RS Production calendar data | Sum of days with Day Type Business or Pre-Holiday |
  385: | 3 | Number of hours by which working hours are reduced on the eve of non-working holidays | RS Production calendar data | Sum of days with Day Type Pre-holiday (1 hour each) |
  386: | 4 | Type of Production Calendar for calculation | Reference Guide Employee's work schedule | Production calendar |
  387: 
  388: **Important: the** type of Production Calendar is set in the employee's main schedule in 1C ZUP (Work Schedules directory). If an employee works according to a regional production calendar, this regional calendar must be specified in 1C in the employee's main schedule.
  389: 
  390: Reference case
  391: 
  392: The data is calculated according to the RF Production Calendar 2018\.
  393: 
  394: |  | Period: 01.01.2018 \- 31.12.2018 |  |  |  |  |  |
  395: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  396: | Time rate per week | 40 | 40 | 36 | 36 | 30 | 30 |
  397: | Bid | 1 | 0,5 | 1 | 0,25 | 1 | 0,75 |
  398: | Number of calendar working days for the period | 247 | 247 | 247 | 247 | 247 | 247 |
  399: | Number of hours of pre-holiday days for the period | 6 | 6 | 6 | 6 | 6 | 6 |
  400: | Total production rate (hours) | 1970 | 985 | 1772,4 | 886,2 | 1476 | 1107 |
  401: 
  402: Calculation examples for different periods:
  403: 
  404: |  | 01.04.2018 \- 31.12.2018 |  |  | 29.06.2018 \- 31.12.2018 |  |  | 03.01.2018 \- 21.05.2018 |  |  |
  405: | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  406: | Length of the working week | 40 | 36 | 36 | 40 | 36 | 36 | 40 | 36 | 36 |
  407: | Bid | 1 | 1 | 0,75 | 1 | 1 | 0,75 | 1 | 1 | 0,75 |
  408: | Number of calendar working days for the period | 191 | 191 | 191 | 131 | 131 | 131 | 89 | 89 | 89 |
  409: | Number of hours of pre-holiday days for the period | 4 | 4 | 4 | 1 | 1 | 1 | 4 | 4 | 4 |
  410: | Total production rate (hours) | 1524 | 1371,2 | 1028,4 | 1047 | 942,2 | 706,65 | 708 | 636,8 | 477,6 |
  411: 
  412: ### **3.2.2 Exchange with the WFM system** {#3.2.2-exchange-with-the-wfm-system}
  413: 
  414: * On request initiated in the WFM system: method getNormHours
  415: 
  416: * [When initially uploading data](#bookmark=id.kx0ow0k9oepv)
  417: 
  418: **Direction of exchange: 1C \-\> WFM**
  419: 
  420: * At the time the request is sent to WFM, the Weekly Time Norm must be filled in, as well as the date the weekly norm was changed.
  421: 
  422: * If the startDate is less than the hire date, the performance standard will be calculated from the hire date to the endDate.
  423: 
  424: * If the End of Period (endDate) parameter is greater than the Dismissal Date, the standard will be calculated from the StartDate to the Dismissal Date.
  425: 
  426: * If the startDate is less than the hire date and the endDate is greater than the quit date, the performance standard will be calculated from the Hire Date to the Quit Date.
  427: 
  428: ### **3.2.2.1 Description of the getNormHours method** {#3.2.2.1-description-of-the-getnormhours-method}
  429: 
  430: 1\. Input data (WFM-\>1C)
  431: 
  432: | № | Data |  | Name in 1C | Example | Type | Obligatory characteristic | Commentary |
  433: | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  434: | 1 | Beginning of the period for calculating the standard of performance |  | startDate | 2019-01-01 | Date | Yes | date |
  435: | 2 | End of the performance standard calculation period |  | endDate | 2019-12-31 | Date | Yes | date |
  436: | 3 | Calculation mode \- month/quarter/year |  | calculationMode | month / quarter / year | String | Yes |  |
  437: | 4 | Employees |  | AR\_agents |  | Array | Yes |  |
  438: | 5 |  | employee ID | agentId | e09df265-7bf4-11e2-9362-001b11b25590 | String | Yes |  |
  439: | 6 |  | Rate per week | AR\_norms |  | Array | Yes |  |
  440: | 7 |  | Time rate per week | normWeek | 36 | number | Yes |  |
  441: | 8 |  | Date of norm change per week | changeDate | 2019-12-31 | Date | No |  |
  442: 
  443: **Request format from WFM**
  444: 
  445: Method: **POST**
  446: 
  447: | Request key | request\_body |
  448: | :---- | :---- |
  449: | getNormHours |  {  "startDate": "2019-01-0",  "endDate": "2019-12-31",  "calculationMode": "quarter" ,  { "AR\_agents":  \[   {     "agentId":"333da0b4-7bff-11e2-9362-001b11b25590", { "AR\_norms" :     \[      {        "normWeek":40,        "changeDate": "2019-03-01"      },      {        "normWeek":20,        "changeDate": "2019-06-01"      },      {        "normWeek":40,        "changeDate": "2019-09-01"      }     \]   },   {     "agentId":"742d89c8-bbfd-11e8-9bce-c809addd7c9c", { "AR\_norms" :     \[      {        "normWeek":36,        "changeDate": "2019-01-01".      }     \]   }  \]}  |
  450: 
  451: 2\. Returned data (1C-\>WFM)
  452: 
  453: | № | Data | Name in 1C | Example | Type | Obligatory characteristic | Commentary |
  454: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  455: | 1 | employee ID | agentId | e09df265-7bf4-11e2-9362-001b11b25590 | String | Yes |  |
  456: | 2 | Time rate according to the production calendar depending on the mode of calculation | normHours | 1970 | number | Yes |  |
  457: | 3 | Settlement start date | startDate | 2018-01-01 | date  | Yes | For the mode: month \- the first day of the month, quarter is the first day of the quarter, year \- the first day of the year, If the hire date is greater than the beginning of the period, the hire date will be passed as the first day of the month/quarter/year |
  458: | 4 | Settlement end date | endDate | 2018-12-31 | date | Yes | For the mode month \- last day of the month quarter year \- the last day of the year If the termination date is less than the end of the period, the termination date will be passed as the last day of the month/quarter/ |
  459: 
  460: **Response Format:**
  461: 
  462: | \[{{ "agentId":"f693f3b1-fec4-11ec-80ed-00155d161a16",{ "normHours":454,"startDate":"2023-01-01","endDate":"2023-03-31"},{"agentId":"f693f3b1-fec4-11ec-80ed-00155d161a16",{ "normHours":488,"startDate":"2023-04-01","endDate":"2023-06-30"},{"agentId":"f693f3b1-fec4-11ec-80ed-00155d161a16",{ "normHours":520,"startDate":"2023-07-01","endDate":"2023-09-30"},{"agentId":"f693f3b1-fec4-11ec-80ed-00155d161a16",{ "normHours":511,"startDate":"2023-10-01","endDate":"2023-12-31"}\] |
  463: | :---- |
  464: 
  465: ### **3.2.3 Actualization of Time Standards according to the production calendar** {#3.2.3-actualization-of-time-standards-according-to-the-production-calendar}
  466: 
  467: *Updating the Time Standards on the production calendar is done:*
  468: 
  469: 1. If the employee's weekly time standard is changed, it is necessary to synchronize the personnel (Agents method) first, so that the WFMCC system receives from 1C the new weekly standard and the date when this standard was changed.
  470: 
  471: 2. When an employee is terminated (to adjust the schedule)
  472: 
  473: The request is initiated by the WFM user. The query can be passed either for a specific employee or for a group of operators.
  474: 
  475: ### **3.2.4 Time rate per week** {#3.2.4-time-rate-per-week}
  476: 
  477: The value of the weekly time standard is set in the WFM system for each employee by integration with the 1C system. The 1C system transmits the weekly norm value and the date of the weekly norm change in the Agents method.
  478: 
  479: The obtained values are passed to 1C as parameters in the getNormHours request \- getting "Production norms by production calendar".
  480: 
  481: If the employee has just been hired, the 1C system will pass the employee's date of hire in the weekly norm change date.
  482: 
  483: The WFMCC system will transfer the weekly rate change date and weekly rate received from 1C to the 1C system when a workout is requested.
  484: 
  485: If during the reporting period there were several normative changes per week \- WFMCC system will send to 1C all dates of normative changes and corresponding normative values per week.
  486: 
  487: ## **3.3. sendSchedule \- Work schedules** {#3.3.-sendschedule---work-schedules}
  488: 
  489: Employee work schedules are uploaded from the WFM-system. In the 1C ZUP system the document Individual schedule of an employee is created on the basis of the uploaded data.
  490: 
  491: The Individual Schedule document is generated for a full month for one employee. Accordingly, when uploading data for the year, 12 Individual schedules will be created for one employee.
  492: 
  493: To unambiguously determine the number of days in a month of the year, schedules are created based on data from the RF Production Calendar.
  494: 
  495: Possible scenarios for uploading work schedules from WFM to 1C:
  496: 
  497: * One-time upload of schedules for the year for all employees
  498: 
  499: * When hiring a new employee
  500: 
  501: * Updating the employee's schedule to meet the performance standard
  502: 
  503: * Updating an employee's schedule upon termination of employment
  504: 
  505: * Changing the work schedule when manually adjusting the schedule in WFM
  506: 
  507: ### **3.3.1 Calculation algorithm** {#3.3.1-calculation-algorithm}
  508: 
  509: **Accounting of transient shifts.** According to the Customer's ToR: "Night hours are tabulated by a whole shift, for example, if a shift started at 19:00 on 01.02.2018 and ended at 07:00 on 02.02.2018, then the hours are loaded into the timesheet in accordance with the hours worked for 01.02.2018, i.e. if an employee worked the whole shift (12 hours), then the timesheet for 01.02.2018 should contain 12 hours".
  510: 
  511: Thus, Shift Date \= Start Date of the shift period.
  512: 
  513: Rules for determining the type of time:
  514: 
  515: * "H" \- shift entry into the interval 22:00:00-05:59:59
  516: 
  517: * "I" \- shift entry into the interval 06:00:00-21:59:59
  518: 
  519: * "B" \- no shift for the day of the month
  520: 
  521: Subtraction of the duration of unpaid breaks takes place on the WFM side of the system.
  522: 
  523: ### **3.3.2 Exchange with the WFM system** {#3.3.2-exchange-with-the-wfm-system}
  524: 
  525: * On request initiated in the WFM system: method sendSchedule
  526: 
  527: **Direction of exchange: WFM \-\> 1C**
  528: 
  529: * From the WFM system, the dates of work shifts with the number of day and night hours (minus the duration of unpaid breaks) are uploaded.
  530: 
  531: * The number of hours is unloaded in milliseconds. Conversion to hours takes place on the 1C side.
  532: 
  533: * If no shift is transferred from WFM on the date of the month, a day off (B) is set in the schedule for that day.
  534: 
  535: * If an employee's hire date is greater than the start date of the schedule period, then:
  536: 
  537:   * Schedules for months prior to the month of hire will not be created;
  538: 
  539:   * The first schedule will be created in the month of hire, with the days from the beginning of the month to the hire date filled with blank values.
  540: 
  541:   * If an employee has a layoff date less than the end date of the schedule period, then:
  542: 
  543:     * Schedules for the months following the month of layoff will not be created;
  544: 
  545:     * The last schedule will be created in the month of layoff, with the days from the layoff date to the month end date filled with blank values.
  546: 
  547: * If you pass an empty array for an employee (no shifts), no schedules will be created.
  548: 
  549: * When uploading, the Employee and Schedule Formation Period parameters are checked. If an employee already has an Individual schedule (for a full month) for the period being uploaded, the system makes changes to the existing schedule. If there is no schedule, a new one is created.
  550: 
  551: * If in 1C there is an individual schedule (in the Carried out state) for an employee for a month that is not full, the schedule from WFM will not be created. An error message will be sent.
  552: 
  553: * When creating charts, a check is performed to see if the transferred period is included in a closed period (in this case, a closed period is a period earlier than the beginning of the current month). For example, if the current month is September, and the transferred period is January-December, the charts will be created from September to December.
  554: 
  555: * If the RF production calendar is not loaded in 1C for the transferred period, schedules will not be created. An error message will be sent.
  556: 
  557: Error messages
  558: 
  559: | Cause of error | Message to user WFM |
  560: | :---- | :---- |
  561: | The end date of the schedule download period is less than the current month | "It is forbidden to modify schedules for past periods. Individual schedules have not been created." |
  562: | Production calendar not loaded for the period of schedules creation | "For 2021, the RF production calendar has not been filled in\! Individual schedules have not been created." |
  563: | In 1C there is a held individual schedule for not a full month | "For September 2019, there is a part-month schedule for an employee. Delete this schedule in 1C:ZUP and re-upload the schedules from WFM.". |
  564: | No data on shifts | "There is no data for the employee. Individual schedules have not been created." |
  565: 
  566: ### **3.3.2.1 Description of the sendSchedule method** {#3.3.2.1-description-of-the-sendschedule-method}
  567: 
  568: 1\. Input data (WFM-\>1C)
  569: 
  570: | № | Data |  | Name in 1C | Example | Type | Commentary |
  571: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  572: | 1 | employee ID |  | agentID | e09df265-7bf4-11e2-9362-001b11b25590 | String |  |
  573: | 2 | Beginning of the charting period |  | period1 | 2018-08-01T00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  574: | 3 | End of charting period |  | period2 | 2018-12-31T00:00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  575: | 4 | Shift array |  | shift |  | Array | Array of operator shifts in the transferred period |
  576: | 5 |  | Shift start date | date\_start | 2018-08-01T07:00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  577: | 6 |  | Number of day shift hours | daily\_hours | 12600000 | number | Duration after subtracting the duration of unpaid breaks. In milliseconds |
  578: | 7 |  | Number of night shift hours | night\_hours | 27000000 | number | Duration after subtracting the duration of unpaid breaks. In milliseconds |
  579: 
  580: **Request format from WFM**
  581: 
  582: Method: **POST**
  583: 
  584: | Request key | request\_body |
  585: | :---- | :---- |
  586: | sendSchedule |  {"agentId":"e09df265-7bf4-11e2-9362-001b11b25590","period1":"2018-08-01T00:00:00Z","period2":"2018-12-31T00:00:00Z","shift":\[{"date\_start":"2018-08-01T19:00:00Z","daily\_hours":"12600000","night\_hours":"27000000"},{"date\_start":"2018-08-03T19:00:00Z","daily\_hours":"12600000","night\_hours":"27000000"},\]}  |
  587: 
  588: 2\. Returned data (1C-\>WFM)
  589: 
  590: | № | Data | Name in 1C | Example | Type | Commentary |
  591: | :---- | :---- | :---- | :---- | :---- | :---- |
  592: | 1 | Result | result | true | String | Result of schedule processing in 1C. The document "Individual work schedule" is executed \- true, not executed \- false. |
  593: | 2 | Message | message | "Individual schedules are created in the 1C:ZUP base" | String | User-friendly description of the result |
  594: 
  595: **Response Format:**
  596: 
  597: | { { "result": "true", "message": "Individual schedules have been created in the 1C:ZUP database"}  |
  598: | :---- |
  599: 
  600: ## **3.4. getTimetypeInfo \- timesheet** {#3.4.-gettimetypeinfo---timesheet}
  601: 
  602: The definition of the time type is performed on the 1C ZUP side.
  603: 
  604: With the exception of time types "RV", "RVN", "HH", "C" (the rules are described in the previous section), other time types are initiated by creating and executing the corresponding documents by the 1C ZUP user. The list of correspondence of time types and documents is shown in [Appendix 2](#bookmark=id.p44tylnl4mal).
  605: 
  606: ### **3.4.1 Calculation algorithm** {#3.4.1-calculation-algorithm}
  607: 
  608: Determination of the type of time for each day is made according to the algorithms of 1C ZUP taking into account the preemptive rules.
  609: 
  610: The rules for displacing one type of time by another depend on the setting of priorities of accrual types in the 1C ZUP system.
  611: 
  612: For example, if an employee has two types of deviation recorded on the same day: Absenteeism and Sick Leave, time type B (sick leave) will be transferred to WFM. Since sick leave has a higher priority according to the preemptive rules.
  613: 
  614: ### **3.4.2 Exchange with the WFM system** {#3.4.2-exchange-with-the-wfm-system}
  615: 
  616: * On request initiated in the WFM system: method getTimetypeInfo
  617: 
  618: **Direction of exchange: 1C \-\> WFM**
  619: 
  620: * This method is used
  621: 
  622:   * to generate timesheets in WFM
  623: 
  624:   * to determine the type of time when a deviation of fact from plan is detected in WFM
  625: 
  626:   * to generate a report on deviations for the period
  627: 
  628: * When generating a timesheet in WFM, the WFM system will mass query the operators for a certain period for each day for deviation types. The period of generation is specified by the user in the WFM system.
  629: 
  630: * To generate the timesheet, the following must be uploaded
  631: 
  632:   * time type data for each day of the month
  633: 
  634:   * data for filling in the "No-shows by reason" block
  635: 
  636:   * data for filling in the "Worked for" block (worked for the first, second half of the month, month)
  637: 
  638: ### **3.4.2.1 Description of getTimetypeInfo method** {#3.4.2.1-description-of-gettimetypeinfo-method}
  639: 
  640: 1\. Input data (WFM-\>1C)
  641: 
  642: | № | Data |  | Name in 1C | Example | Type | Commentary |
  643: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  644: | 1 | Beginning of the period |  | date\_start | 2018-01-01T00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  645: | 2 | End of period |  | date\_end | 2018-12-31T00:00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  646: | 3 | Employees |  | AR\_agents |  | Array |  |
  647: | 4 |  | employee ID | agentId | e09df265-7bf4-11e2-9362-001b11b25590 | String | Mandatory parameter |
  648: 
  649: **Request format from WFM**
  650: 
  651: Method: **POST**
  652: 
  653: | Request key | request\_body |
  654: | :---- | :---- |
  655: | getTimetypeInfo |  {{ "date\_start": "2019-02-01T00:00:00","date\_end": "2019-02-28T00:00:00",{ "AR\_agents":\[{"agentId":"333da0b4-7bff-11e2-9362-001b11b25590"},{"agentId":"742d89c8-bbfd-11e8-9bce-c809addd7c9c"},\]}  |
  656: 
  657: 2\. Returned data (1C-\>WFM)
  658: 
  659: | № | Data |  | Name in 1C | Example | Type | Commentary |
  660: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  661: | 1 | employee ID |  | agentId | e09df265-7bf4-11e2-9362-001b11b25590 | String |  |
  662: | 2 | Array of dates and time types |  | AR\_date |  | Array | Data for filling in the main block of the timesheet |
  663: | 3 |  | Date | date | 2018-01-01T00:00:00Z | Date | UTC ISO8601 |
  664: | 4 |  | Time type (Letter code) | timetype | Я | String |  |
  665: | 5 |  | Number of hours | hours | 11 | number | If the time type does not have a number of hours, 0 will be transmitted |
  666: | 6 | Data array on no-shows |  | AR\_N |  | Array | Data for completing the block "No-shows by reason" |
  667: | 7 |  | Time type (Letter code) | timetype\_N | HH | String |  |
  668: | 8 |  | Number of days (hours) | hours\_N | 2(6) | String | In the whole-day type, the deviation is only the number of days. For example, OT 14 (14 days of vacation) |
  669: | 9 | Days for the 1st half of the month |  | half1\_days | 5 | number | Data for filling in the "Worked for" block The number of working days and hours is transferred. 1st half of the month \- in any month counts from the 1st to the 15th day inclusive. |
  670: | 10 | Hours for the 1st half of the month |  | half1\_hours | 43 | number |  |
  671: | 11 | Days for the 2nd half of the month |  | half2\_days | 7 | number |  |
  672: | 12 | Hours for the 2nd half of the month |  | half2\_hours | 60 | number |  |
  673: 
  674: **Response Format:**
  675: 
  676: | \[    {        "agentId": "8695b47a-7cbe-11e2-9368-001b11b25590",        { "AR\_date": \[            {                "date": "2018-03-27T21:00:00Z",                { "timetype": { "self",                { "hours": 11            },            {                "date": "2018-03-27T21:00:00Z",                { "timetype": "c",                { "hours": 2,75            },            {                "date": "2018-03-28T21:00:00Z", { "timetype": { "en",                "hours": 0            }        \],        { "AR\_N": \[            { }, "timetype\_N": { "timetype\_N",                "hours\_N": "2(5)"            },            { { "timetype\_N": "OT",                "hours\_N": "5"            }        \],        { "half1\_days": 6,        "half1\_hours": 61,        "half2\_days": 7,        "half2\_hours": 68    },    {        "agentId": "333da084-7bff-11e2-9362-001b11b25590",        { "AR\_date": \[            {                "date": "2018-02-28T21:00:00Z",                { "timetype": { "l",                { "hours": 8            }        \],        { "AR\_N": \[\],        { "half1\_days": 9,        "half1\_hours": 71,        "half2\_days": 11,        "half2\_hours": 88    }\] |
  677: | :---- |
  678: 
  679: ## **3.5. sendFactWorkTime \- General description of the exchange algorithm when working with the Operator Work Monitoring Tool (WFM-system)** {#3.5.-sendfactworktime---general-description-of-the-exchange-algorithm-when-working-with-the-operator-work-monitoring-tool-(wfm-system)}
  680: 
  681: The tool uses two methods of querying 1C ZUP:
  682: 
  683: 1. Request from 1C of registered types of deviations and events according to the planned work schedule. Necessary to get up-to-date information on the availability of deviation documents registered in the 1C system.
  684: 
  685: **The method is described in the item [Time Sheet](#bookmark=id.uod7md27lci)**
  686: 
  687: 1. Creation of deviation documents in 1C with the type of time RV, RVN, NV, S.
  688: 
  689: The event occurs when the responsible employee confirms in WFM that the actual time worked deviates from the planned time.
  690: 
  691: **The method is described under [Deviations with time type "RV", "RVN", "NV", "C"](#bookmark=id.6pbx2ipg3wgf)**
  692: 
  693: ### **3.5.1 Deviations with time type "RW", "RWN", "NN", "C" (integration point of the timesheet)** {#3.5.1-deviations-with-time-type-"rw",-"rwn",-"nn",-"c"-(integration-point-of-the-timesheet)}
  694: 
  695: Deviations from the schedule with time type "RV", "RVN", "NV", "C" are initiated in the WFM system. The actual deviation time is transferred from WFM to 1C.
  696: 
  697: Determination of the time type is performed on the 1C side based on the deviation of the plan from the fact.
  698: 
  699: Depending on the result of determining the type of time, 1C automatically creates the corresponding document:
  700: 
  701: * "RV", "RVN" \- document Work on holidays and weekends
  702: 
  703: * "Absence" \- document Absence (sickness, absenteeism, failure to appear) with the reason of absence "Absence for an unexplained reason"
  704: 
  705: * "C" \- document Overtime work
  706: 
  707: The document is carried out programmatically at creation. Carrying out in the mode of subsystem Personnel.
  708: 
  709: If the document was created by mistake, it is necessary to delete it in 1C and upload it from WFM again. Or correct the document in 1C.
  710: 
  711: ### **3.5.1.1 Calculation algorithm** {#3.5.1.1-calculation-algorithm}
  712: 
  713: The employee's deviation period is uploaded from the WFM system.
  714: 
  715: Determination of Time Type is based on comparison of actual data transferred from WFM with planned data of the work schedule.
  716: 
  717: | Plan (hour) | Actual deviation (hour) | Interval entry | Type of time, h |
  718: | :---- | :---- | :---- | :---- |
  719: | 0 | 8 | 06:00 \- 22:00 | RV 8\. |
  720: | 0 | 4 | 22:00 \- 06:00 | WFH 4 |
  721: | 8 | 0 |  | HH 8 |
  722: | 8 | 4 |  | HH 4 |
  723: | 8 | 10 |  | С 2 |
  724: 
  725: ### **3.5.1.2 Exchange with the WFM system** {#3.5.1.2-exchange-with-the-wfm-system}
  726: 
  727: * On request initiated in the WFM system: method sendFactWorkTime
  728: 
  729: (the conditions under which the request is initiated are described in the case studies on working with the Operator Control Tool in the WFM system).
  730: 
  731: **Direction of exchange: WFM \-\> 1C**
  732: 
  733: * The periods of deviations are reflected by 15 minutes (600000 ms) each
  734: 
  735: * The conversion to hours takes place on the 1C side.
  736: 
  737: ### **3.5.1.2.1 Description of the sendFactWorkTime method** {#3.5.1.2.1-description-of-the-sendfactworktime-method}
  738: 
  739: 1\. Input data (WFM-\>1C)
  740: 
  741: | № | Data |  | Name in 1C | Example | Type | Commentary |
  742: | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
  743: | 1 | employee ID |  | agentId | e09df265-7bf4-11e2-9362-001b11b25590 | String | Mandatory parameter |
  744: | 2 | Responsible Officer |  | initiator\_name | Ivanov I.I. | String | Initiator of rejection document creation (in 1C will be added to the document comment) |
  745: | 3 | Shift start date |  | date\_start | 2018-12-31T00:00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  746: | 4 | Periods in the system |  | loginfo |  | Array |  |
  747: | 5 |  | Date, time of entry | start | 2018-12-31T00:00:00:00Z | Date | ISO8601 format (transmission in UTC, offset or local is possible) |
  748: | 6 |  | Length of time in the system | time | 900000 | number | Data is transmitted for 15 minutes at a time In milliseconds |
  749: 
  750: **Request format from WFM**
  751: 
  752: Method: **POST**
  753: 
  754: | Request key | request\_body |
  755: | :---- | :---- |
  756: | sendFactWorkTime |  {"agentId": "333da0b4-7bff-11e2-9362-001b11b25590","initiator\_name": "Ivanov I.I.""date\_start": "2019-02-01T18:00:00","loginfo":\[{"start":"2019-02-01T18:00:00","time":600000},{"start":"2019-02-01T20:20:00","time":580000}\]}  |
  757: 
  758: 2\. Returned data (1C-\>WFM)
  759: 
  760: | № | Data | Name in 1C | Example | Type | Commentary |
  761: | :---- | :---- | :---- | :---- | :---- | :---- |
  762: | 1 | Result | result | true | Boolean | In case of successful document creation \- true; in case of errors (document not created) \- false |
  763: | 2 | Name of the created document | doc | No-show | String / null | List of values: Weekend Work, Working Overtime, Failure to appear; If the document is not created, returns null. |
  764: 
  765: **Response Format:**
  766: 
  767: With success:
  768: 
  769: |     {                "result": true,                { "doc": "Weekend Work."            }  |
  770: | :---- |
  771: 
  772: In error:
  773: 
  774: | {                "result": false,                "doc": null            } |
  775: | :---- |
  776: 
  777: ### **3.5.2 Filling in other fields of created documents** {#3.5.2-filling-in-other-fields-of-created-documents}
  778: 
  779: Common Fields:
  780: 
  781: * Document date \- sets the current date (upload date)
  782: 
  783: * Document number \- formed automatically by the system when recording
  784: 
  785: * Organization \- formed on the basis of the employee's current personnel data
  786: 
  787: * Month \- sets the month of the document date (month of upload)
  788: 
  789: * Comment \- "Upload from WFM \[Date, time\] \[Name of responsible person from WFM\]"
  790: 
  791: * Responsible \- the service user "WFM-system" is set.
  792: 
  793: Document "Work on holidays and weekends"
  794: 
  795: * Compensation method "Increased payment"
  796: 
  797: * Payment is made "By the hour."
  798: 
  799: * The "Employee consent is required", "Consent to work on a weekend and public holiday has been obtained" checkboxes are checked
  800: 
  801: Document "Absence (sickness, absenteeism, failure to appear)"
  802: 
  803: * Reason for absence "Unexplained absence"
  804: 
  805: * If Actual \= 0
  806: 
  807:   * The "Absence for part of shift" checkbox is not selected
  808: 
  809:   * If Actual \> 0 but less than Plan
  810: 
  811:     * The "Absence for part of the shift" checkbox is checked
  812: 
  813:     * depending on the time of absence, either a Daytime Unexplained Absence or a Nighttime Unexplained Absence (if the period of time of absence includes daytime and nighttime, 2 documents will be created).
  814: 
  815: Document "Overtime work"
  816: 
  817: * Compensation method "Increased payment"
  818: 
  819: * The "Consent for overtime has been obtained" checkboxes are checked
  820: 
  821: ### **3.5.3 Conducting documents** {#3.5.3-conducting-documents}
  822: 
  823: The documents are executed in the Personnel subsystem mode. The document requires confirmation in the Salary subsystem (signs Calculation approved, Time taken into account is set by the employee of the calculation department).
  824: 
  825: # **4\. Initial data upload** {#4.-initial-data-upload}
  826: 
  827: Before you start using the integration, the initial loading of data into the WFM system from 1C ZUP is performed.
  828: 
  829: Loading is done in stages:
  830: 
  831: 1. The WFM system initiates a query for employees (agents method). This will load the department structure, positions, employee data and leave balances.
  832: 
  833: 2. The WFM system initiates a request for the norm of time according to the production calendar (method [getNormHours](#bookmark=id.8gdje1powo6m)). Beforehand, WFM sets the NormHours per week for employees (if the norm differs from the default 40 hours).
  834: 
  835: # **5\. Necessary improvements to the 1C ZUP configuration** {#5.-necessary-improvements-to-the-1c-zup-configuration}
  836: 
  837: The implementation is done through the extensions mechanism (without changing the configuration).
  838: 
  839: To solve the problem, the following metadata object is created in the extension for the 1C Salary and HR Management CORP configuration:
  840: 
  841: * HTTP service "wfm\_Energosbyt\_ExchangeWFM"
  842: 
  843: All methods and business logic are described in the HTTP service module.
  844: 
  845: # **6\. Requirements for setting up access rights for the integration system user** {#6.-requirements-for-setting-up-access-rights-for-the-integration-system-user}
  846: 
  847: | Task | Access level |
  848: | :---- | :---- |
  849: | Making changes to the 1C:ZUP configuration | Full rights in the 1C database |
  850: | Installation of the web server extension module to the 1C platform | Administrator rights on the server |
  851: | Web server installation | Administrator rights on the server |
  852: | Publishing HTTP service | Administrator rights in 1C database, Administrator rights on the server |
  853: 
  854: # **7\. Requirements for customization of 1C: Salary and Personnel Management** {#7.-requirements-for-customization-of-1c:-salary-and-personnel-management}
  855: 
  856: |  | Integration point with WFM system | Requirements for customization of 1C ZUP |
  857: | :---- | :---- | :---- |
  858: | 1 | Time sheet (all deviations) | Time types of accruals used in deviation documents must be configured in accordance with [Appendix 2](#bookmark=id.p44tylnl4mal) "Matching Time Types to 1C ZUP Documents" |
  859: | 2 | Time sheet (definition of time type) | The rules for displacing time types in the accrual settings (Priority tab) must be consistent with the accounting rules  |
  860: | 3 | Creation of documents with time type "RV", "RVN", "NV", "C" | The accruals and withholdings composition setting must be set: Night watches Overtime Truancy and absenteeism Including intra-shift shifts Work on holidays and weekends |
  861: | 4 | Time rate according to the production calendar | The employee's work schedule (assigned by personnel documents) must be completed: Production calendar for the employee (if the employee works according to the regional production calendar, the corresponding calendar must be set up) Summarized timekeeping  |
  862: | 5 | Employee data | Employees exchanged with WFM must belong to the "Customer Service" division, directory element code "CFR000260". |
  863: | 6 | Work schedules | The RF Production Calendar must be completed for the period of creating individual schedules |
  864: | 7 | Connecting to HTTP service | A user for the WFM system (WFMSystem) must be created in the database. Permissions Full. Without displaying in the selection list. |
  865: 
  866: # **8\. Appendices** {#8.-appendices}
  867: 
  868: ## **8.1 Appendix 1\. List of 1C \- JSON fields** {#8.1-appendix-1.-list-of-1c---json-fields}
  869: 
  870: | Data | Name |
  871: | :---- | :---- |
  872: | Employee ID | agentID |
  873: | Tab. number | tabN |
  874: | Date of employment | startwork |
  875: | Date of termination | finishwork |
  876: | Surname | lastname |
  877: | Name | firstname |
  878: | Patronymic | secondname |
  879: | PID of the post | positionID |
  880: | Position | position |
  881: | Unit ID | departmentId |
  882: | Division | department |
  883: | Time rate according to the production calendar | normHours |
  884: | Time rate per week | normWeek |
  885: | Vacation balance | vacation |
  886: | Type of time | timetype |
  887: | Start date | period1 |
  888: | End date | period2 |
  889: | Day | day |
  890: | Date | date |
  891: | Number of hours | hours |
  892: | Bid | rate |
  893: 
  894: ## **8.2 Appendix 2\. Correspondence of time types to 1C ZUP documents** {#8.2-appendix-2.-correspondence-of-time-types-to-1c-zup-documents}
  895: 
  896: | Designation | Deciphering | Description | Display in the absence control tool in "Event in 1C" | Document in 1C ZUP |
  897: | :---- | :---- | :---- | :---- | :---- |
  898: | PR | Truancy | Absenteeism (absence without a valid excuse for more than 4 consecutive hours or during the entire working day regardless of its continuation) | The WFM system receives from the 1C system through integration, i.e. the event registered in the 1C system must be displayed | Absence (Sickness, absenteeism, failure to appear). Reason for absence \- Absenteeism |
  899: | RP | Simple | Downtime due to employer's fault |  | Employee downtime. Type of downtime \- Through the fault of the employer |
  900: | PC | Professional development | In-service training |  | Absence with pay. Type of absence \- Professional development |
  901: | OT | Vacation | Annual basic paid vacation |  | Vacation |
  902: | OD | Additional vacation | Annual additional paid vacation |  | Vacation. Provide additional vacation. Code of accrual time type \- OD |
  903: | У | Additional leave (paid study leave) | Additional training leave with average earnings for employees combining work and training |  | Vacation. Provide additional vacation. Code of accrual time type \- U |
  904: | UD | Additional leave (unpaid study leave) | Additional leave in connection with training without pay |  | Vacation. Provide additional vacation. Code of accrual time type \- UD |
  905: | Р | Maternity leave | Maternity leave (leave in connection with the adoption of a newborn child) |  | Sick leave. Reason for incapacity for work \- Maternity leave. |
  906: | OW | Parental leave | Leave to care for a child under the age of three years |  | Parental leave |
  907: | DO | Leave without pay with employer's authorization | Leave without pay granted to an employee by the employer's authorization |  | Leave of absence without pay. Type of leave \- Leave without pay in accordance with Part 1 of Article 128 of the Labor Code of the Russian Federation. |
  908: | Б | Sick leave | Temporary disability |  | Sick leave. The reason for the disability is Illness or injury (other than work-related injuries) |
  909: | Т | Unpaid sick leave | Temporary incapacity for work without assignment of benefit in cases provided for by law |  | Time sheet / Absence (sickness, absenteeism, no-show) (note 2 after 1C modification: Payment \- Assign allowance \= False) |
  910: | Г | Fulfillment of public duties | Absences for the period of fulfillment of state or public duties |  | Absence with pay. Type of absence \- Performance of public duties |
  911: | OV | Additional days off (rest days) | Additional days off (paid) |  | Absence with pay. Type of absence \- Additional days off (paid) |
  912: | MO | Medical examination | Absence from work due to medical examination |  | Report Card / Absence with pay. Type of absence \- Time of medical examination |
  913: | CR | Nursing breaks | Absence from the workplace due to nursing breaks |  | Absence with pay. Type of absence \- Breaks for feeding the baby |
  914: | NA | Serving administrative detention | Absence from the workplace due to serving an administrative arrest |  | report card |
  915: | NZ | Suspension of work in case of delayed salary payment | Time of suspension of work in case of delay in payment of wages |  | Absence with pay. Type of absence \- Suspension of work in case of delayed salary payment |
  916: | NB | Suspension without pay | Suspension from work (preventing from work) for reasons stipulated by law, without payroll deduction |  | report card |
  917: | BUT | Suspension with pay | Suspension from work (preventing from work) with payment (allowance) in accordance with the legislation  |  | Absence with pay. Type of absence \- Suspension with pay. |
  918: | GP | Downtime due to employee's fault | Downtime due to employee's fault |  | Employee Downtime. Type of downtime \- Through employee's fault |
  919: | NP | Downtime beyond the control of the employer and employee | Downtime for reasons beyond the control of the employer and the employee |  | Employee downtime. Type of downtime \- Beyond the control of the employer and the employee |
  920: | ZB | Strike | Strike (under the conditions and in the manner prescribed by law) |  | Absence with pay. Type of absence \- Strike |
  921: | NS | Part-time work | Duration of part-time work on the employer's initiative in cases stipulated by the legislation |  | Employee, with a Part-Time Schedule. |
  922: | SP | Time of enforced absenteeism | Time of forced absenteeism in case of recognition of dismissal, transfer to another job or suspension from work as unlawful, with reinstatement to the previous job |  | Absence with pay. Type of Absence \- Time of Involuntary Absence. |
  923: | HR | Reduced working hours in accordance with the law | Reduced working hours against the normal working hours in cases stipulated by legislation |  | Employee type of time schedule of which \- Reduced working hours in accordance with the law |
  924: | DB | Additional leave without pay | Annual additional leave without pay |  | Leave of absence without pay. Type of leave \- Accrual with type of working time DB |
  925: | OZ | Leave without pay in accordance with the law | Leave without pay under conditions stipulated by the current legislation of the Russian Federation |  | Leave of absence without pay. Type of leave \- Leave without pay in accordance with Part 2 of Article 128 of the Labor Code of the Russian Federation |
  926: | UW | Reduced time of on-the-job trainees | Reduced working hours for on-the-job trainees with partial salary retention |  | Employee type of schedule time of which \- On-the-job training time reduction |
  927: | PM | Advanced training in another area | In-service training in another location |  | Absence with pay. Type of absence \- Professional development in another area |
  928: | К | Business trip | Business trip |  | Business trip |
  929: | VM | Shift | Duration of shift work |  | Employee whose type of schedule time is shift work |
  930: 
  931: [image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGcAAABCCAYAAABKIMh8AAAEBUlEQVR4Xu2aPYsUQRCG7ycIJqbmYmJgbCr+AdHYwEwQ5EADM4XTyFTwA48zEC9QMTK6wEMQQTASBBPNRBCETVbedXpoHqp7untn9+a0Hiimqrqmu/atm7mFu40NxylhPgHYk9NBocTdO1vzzWtXl7Ld3efcNgl7cjoolJC4s9msyVoGxJ6cDgolxhjO/v7b4gGxJ6eDQokxhiO/dEDsyemgUGKs4ZQOiD05HRRKjDkc2dCA2JPTQaEExa0xaziy3IDYk9MhcR7u7syPXD/TbI/eveiH8HRne2FhSJYR9uR0SByK3WJ8UlLmw6lA4lDoFuMQUubDqUDixCKf3Do///n710K07fev+/y5+1d6MeX7cNaAxKHQt9486IXTsJT7+O1zn2O9D2dFSBwKLfv64/tCOD09l5/dXvh6omSsDcM5/vhSb4pP7d3szYfTgMSh0LILT2704oVBbb66tzDW+nBWhMSh0MH2vnzoBdRrjescTon5cCqQOBTaGo6eHq5zOIz5JPlwKpE4FFqm15fQ75jwWtMXBRlrfTgrQuJQ6PjrtIYUvhAEWB+GUWI+nAokDoV++WlvIVr8KgtPj1UfhnPs4uneFB89e6I3H04DEicWOf6WpifGysv34awBiUOhW4yvr5T5cCqQOBS6xTiElPlwKpA4Y/7JYMh8OBVQKCEBKepY5sOpgEIJH85EoFDChzMRKJTw4UwECiV8OBOBQgkfzkSgUGKMf2RPmfYm7MnpoFAHAXtyHMdxHOcv+iVp2WGipd+We9aO1aSVmzKHrd9irA8W53JPVC5O1Vs1zMVrOdibVZ9as86MY+s+K2dRUlOEtQkbin3GsZ+LmbPW4muAcYBnDfmM4/NK6nJ+TElNMdYGuQOsNV7pxzGvgaE8SZ2Vq7fqmA85yw9Y9wgrtxTWhrnmrDVerVzqSphnHLDOsnzGsZ/qhXVDfsDKLYW1Ya4JrjGmn6rhvgHmGQesPXM+45TPONUv44B1bzPWBjwgtphcXOpz39x5hLVWfWo95zOOfWuvmJKa0Vj5AaDlvJZ7/gnW/cFbzmu5x3Ecx3FWifXNK4ZxjppaZwAOhjkrzlFT20T46WHjtJJ8gD5rY3K1cS6mdD9irTHHWDBnnc3e2Tf3GIQ3c4Oa2PKZ4xkpP455D3Pcg7WBmnwux/NyPq9V8KZlYstnvcitCeWDhTi+Bn8oT2ryVk4wz7Mtcj1l4U1jxEMNhxqupeLWK6nJWznBPGPBz2bVFMEbx4hzjeXWrdr4GmA+t2cJVn0uZ53Feua5Xkz4cNYGzJXEqVyq0ThPi9dTPs/k/jHWGnPWXqka1sYWcgHusXYOvIEBSvorqTl0xD8xUybXY27NcRzHcRzH+e/4A4VYK3qpGPNcAAAAAElFTkSuQmCC>
  932: 
  933: [image2]: <data:image/png;base64,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>