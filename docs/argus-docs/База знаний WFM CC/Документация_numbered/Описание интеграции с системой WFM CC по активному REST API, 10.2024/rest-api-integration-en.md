    1: # ARGUS WFM CC System - REST API Integration Documentation
    2: 
    3: ## Table of Contents
    4: 
    5: [Approval Sheet](#approval-sheet)
    6: 
    7: [Change Registration Sheet](#change-registration-sheet)
    8: 
    9: [1. Terms and Definitions](#1-terms-and-definitions)
   10: 
   11: [2. Architectural Description of Integration](#2-architectural-description-of-integration)
   12: 
   13: [2.1. Brief Solution Description](#21-brief-solution-description)
   14: 
   15: [2.2. Data Exchange Schema](#22-data-exchange-schema)
   16: 
   17: [2.3. Data Flow Description](#23-data-flow-description)
   18: 
   19: [3. Description of Integration Methods for Obtaining Historical Data](#3-description-of-integration-methods-for-obtaining-historical-data)
   20: 
   21: [3.1. Personnel Retrieval - personnel](#31-personnel-retrieval---personnel)
   22: 
   23: [3.1.1. General Method Description](#311-general-method-description)
   24: 
   25: [3.1.2. Integration Method Description](#312-integration-method-description)
   26: 
   27: [3.1.2.1. Request URL](#3121-request-url)
   28: 
   29: [3.1.2.2. Request Parameters](#3122-request-parameters)
   30: 
   31: [3.1.2.3. Response Parameters](#3123-response-parameters)
   32: 
   33: [3.1.2.3.1. Service Object Description](#31231-service-object-description)
   34: 
   35: [3.1.2.3.1.1. serviceGroups Parameter Description](#312311-servicegroups-parameter-description)
   36: 
   37: [3.1.2.3.2. Agent Object Description](#31232-agent-object-description)
   38: 
   39: [3.1.2.3.2.1. agentGroups Parameter Description](#312321-agentgroups-parameter-description)
   40: 
   41: [3.1.3. Response Example](#313-response-example)
   42: 
   43: [3.2. Historical Data Retrieval by Groups - serviceGroupData](#32-historical-data-retrieval-by-groups---servicegroupdata)
   44: 
   45: [3.2.1. General Method Description](#321-general-method-description)
   46: 
   47: [3.2.2. Integration Method Description](#322-integration-method-description)
   48: 
   49: [3.2.2.1. Request URL](#3221-request-url)
   50: 
   51: [3.2.2.2. Request Parameters](#3222-request-parameters)
   52: 
   53: [3.2.2.2.1. Query Parameters](#32221-query-parameters)
   54: 
   55: [3.2.2.3. Response Parameters](#3223-response-parameters)
   56: 
   57: [3.2.2.3.1. ServiceGroupHistoricData Object Description](#32231-servicegrouphistoricdata-object-description)
   58: 
   59: [3.2.2.3.1.1. HistoricData Parameter Description](#322311-historicdata-parameter-description)
   60: 
   61: [3.2.3. Request Example](#323-request-example)
   62: 
   63: [3.2.4. Response Example](#324-response-example)
   64: 
   65: [3.3. Historical Data Retrieval for Agent Status Changes - agentStatusData](#33-historical-data-retrieval-for-agent-status-changes---agentstatusdata)
   66: 
   67: [3.3.1. General Method Description](#331-general-method-description)
   68: 
   69: [3.3.2. Integration Method Description](#332-integration-method-description)
   70: 
   71: [3.3.2.1. Request URL](#3321-request-url)
   72: 
   73: [3.3.2.2. Request Parameters](#3322-request-parameters)
   74: 
   75: [3.3.2.2.1. Query Parameters](#33221-query-parameters)
   76: 
   77: [3.3.2.3. Response Parameters](#3323-response-parameters)
   78: 
   79: [3.3.2.3.1. AgentState Object Description](#33231-agentstate-object-description)
   80: 
   81: [3.3.2.3.1.1. states Parameter Description](#332311-states-parameter-description)
   82: 
   83: [3.3.3. Request Example](#333-request-example)
   84: 
   85: [3.3.4. Response Example](#334-response-example)
   86: 
   87: [3.4. Historical Data Retrieval for Agent Login/Logout - agentLoginData](#34-historical-data-retrieval-for-agent-loginlogout---agentlogindata)
   88: 
   89: [3.4.1. General Method Description](#341-general-method-description)
   90: 
   91: [3.4.2. Integration Method Description](#342-integration-method-description)
   92: 
   93: [3.4.2.1. Request URL](#3421-request-url)
   94: 
   95: [3.4.2.2. Request Parameters](#3422-request-parameters)
   96: 
   97: [3.4.2.2.1. Query Parameters](#34221-query-parameters)
   98: 
   99: [3.4.2.3. Response Parameters](#3423-response-parameters)
  100: 
  101: [3.4.2.3.1. AgentLogins Object Description](#34231-agentlogins-object-description)
  102: 
  103: [3.4.2.3.1.1. Logins Parameter Description](#342311-logins-parameter-description)
  104: 
  105: [3.4.3. Request Example](#343-request-example)
  106: 
  107: [3.4.4. Response Example](#344-response-example)
  108: 
  109: [3.5. Historical Data Retrieval for Agent Processed Contacts - agentCallsData](#35-historical-data-retrieval-for-agent-processed-contacts---agentcallsdata)
  110: 
  111: [3.5.1. General Method Description](#351-general-method-description)
  112: 
  113: [3.5.2. Integration Method Description](#352-integration-method-description)
  114: 
  115: [3.5.2.1. Request URL](#3521-request-url)
  116: 
  117: [3.5.2.2. Request Parameters](#3522-request-parameters)
  118: 
  119: [3.5.2.2.1. Query Parameters](#35221-query-parameters)
  120: 
  121: [3.5.2.3. Response Parameters](#3523-response-parameters)
  122: 
  123: [3.5.2.3.1. AgentCalls Object Description](#35231-agentcalls-object-description)
  124: 
  125: [3.5.2.3.1.1. agentCalls Parameter Description](#352311-agentcalls-parameter-description)
  126: 
  127: [3.5.3. Request Example](#353-request-example)
  128: 
  129: [3.5.4. Response Example](#354-response-example)
  130: 
  131: [3.6. Historical Data Retrieval for Chat Work Time - agentChatsWorkTime (Chat Platform Only)](#36-historical-data-retrieval-for-chat-work-time---agentchatsworktime-chat-platform-only)
  132: 
  133: [3.6.1. General Method Description](#361-general-method-description)
  134: 
  135: [3.6.2. Integration Method Description](#362-integration-method-description)
  136: 
  137: [3.6.2.1. Request URL](#3621-request-url)
  138: 
  139: [3.6.2.2. Request Parameters](#3622-request-parameters)
  140: 
  141: [3.6.2.2.1. Query Parameters](#36221-query-parameters)
  142: 
  143: [3.6.2.3. Response Parameters](#3623-response-parameters)
  144: 
  145: [3.6.2.3.1. AgentChatsWorkTime Object Description](#36231-agentchatsworktime-object-description)
  146: 
  147: [3.6.3. Request Example](#363-request-example)
  148: 
  149: [3.6.4. Response Example](#364-response-example)
  150: 
  151: [4. Description of Integration Methods for Real-Time Data](#4-description-of-integration-methods-for-real-time-data)
  152: 
  153: [4.1. Current Agent Status Transmission from External System to WFMCC](#41-current-agent-status-transmission-from-external-system-to-wfmcc)
  154: 
  155: [4.1.1. General Method Description](#411-general-method-description)
  156: 
  157: [4.1.2. Integration Method Description](#412-integration-method-description)
  158: 
  159: [4.1.2.1. Request URL](#4121-request-url)
  160: 
  161: [4.1.2.2. Request Parameters](#4122-request-parameters)
  162: 
  163: [4.1.3. Request Example](#413-request-example)
  164: 
  165: [4.2. Current Agent Status Retrieval - agentStatus](#42-current-agent-status-retrieval---agentstatus)
  166: 
  167: [4.2.1. General Method Description](#421-general-method-description)
  168: 
  169: [4.2.2. Integration Method Description](#422-integration-method-description)
  170: 
  171: [4.2.2.1. Request URL](#4221-request-url)
  172: 
  173: [4.2.2.2. Request Parameters](#4222-request-parameters)
  174: 
  175: [4.2.2.3. Response Parameters](#4223-response-parameters)
  176: 
  177: [4.2.2.3.1. AgentOnlineStatus Object Description](#42231-agentonlinestatus-object-description)
  178: 
  179: [4.2.3. Response Example](#423-response-example)
  180: 
  181: [4.3. Current Group Metrics Retrieval - groupsOnlineLoad](#43-current-group-metrics-retrieval---groupsonlineload)
  182: 
  183: [4.3.1. General Method Description](#431-general-method-description)
  184: 
  185: [4.3.2. Integration Method Description](#432-integration-method-description)
  186: 
  187: [4.3.2.1. Request URL](#4321-request-url)
  188: 
  189: [4.3.2.2. Request Parameters](#4322-request-parameters)
  190: 
  191: [4.3.2.2.1. Query Parameters](#43221-query-parameters)
  192: 
  193: [4.3.2.3. Response Parameters](#4323-response-parameters)
  194: 
  195: [4.3.2.3.1. GroupOnlineLoad Object Description](#43231-grouponlineload-object-description)
  196: 
  197: [4.3.3. Request Example](#433-request-example)
  198: 
  199: [4.3.4. Response Example](#434-response-example)
  200: 
  201: [5. Integration Error Description](#5-integration-error-description)
  202: 
  203: [5.1. Error Code - 500](#51-error-code---500)
  204: 
  205: [5.2. Error Code - 404](#52-error-code---404)
  206: 
  207: [5.3. Error Code - 400](#53-error-code---400)
  208: 
  209: ## Approval Sheet
  210: 
  211: | Position | Name | Signature | Date | Comments |
  212: |----------|------|-----------|------|----------|
  213: |          |      |           |      |          |
  214: |          |      |           |      |          |
  215: |          |      |           |      |          |
  216: 
  217: ## Change Registration Sheet
  218: 
  219: | Version | Date | Developer | Changes |
  220: |---------|------|-----------|---------|
  221: |         |      |           |         |
  222: 
  223: ## 1. Terms and Definitions
  224: 
  225: | Term | Definition |
  226: |------|------------|
  227: | Service | Functional unit of the contact center that handles customer contacts by topic through a specific channel (chat, inbound voice, outbound voice, email) |
  228: | Group | Functional unit of the contact center that is subordinate to a service, handling specialized contacts within the general service topic. In external systems this may be a queue, project, channel, skill, etc. |
  229: | User Account | Employee user account |
  230: | IS | WFM CC system integration service |
  231: | External System | System with which WFM CC system integration is performed |
  232: 
  233: ## 2. Architectural Description of Integration
  234: 
  235: ### 2.1. Brief Solution Description
  236: 
  237: For integration with external systems, a solution based on a universal integration service is provided. The interaction between IS and the third-party system must be implemented using the REST architectural style. As the data type sent to the client (Produces annotation), "application/json" must be used.
  238: 
  239: ### 2.2. Data Exchange Schema
  240: 
  241: ![Integration Architecture](img/integration_architecture_diagram.png)
  242: 
  243: ### 2.3. Data Flow Description
  244: 
  245: | Flow Number | Data Flow Description | Functions Transmitting Data |
  246: |-------------|----------------------|---------------------------|
  247: | 1 | Request-transmission of historical data | personnel - retrieving contact center functional structure (services, groups, user accounts)<br>serviceGroupData - retrieving historical data by groups for forecasting<br>agentStatusData - retrieving data on time spent in contact center statuses by agents within groups<br>agentLoginData - retrieving login/logout/time spent in contact center data by agents<br>agentCallsData - retrieving information about contacts processed by agents for individual agent accounts<br>agentChatsWorkTime - retrieving historical data on time spent in system with at least one chat |
  248: | 2 | Request-transmission of online data | status - transmitting current employee status<br>agentStatus - retrieving online agent statuses<br>groupsOnlineLoad - retrieving online load |
  249: 
  250: ## 3. Description of Integration Methods for Obtaining Historical Data
  251: 
  252: ### 3.1. Personnel Retrieval - personnel
  253: 
  254: #### 3.1.1. General Method Description
  255: 
  256: The method is designed to retrieve services, groups, and employee user accounts. If the external system lacks the concept of "service", a static service value must be transmitted:
  257: 
  258: 1. id - External system name
  259: 2. name - External system name  
  260: 3. status - "ACTIVE"
  261: 
  262: In case of a static service value, all external system groups belong to this service.
  263: 
  264: #### 3.1.2. Integration Method Description
  265: 
  266: Request type: GET
  267: 
  268: ##### 3.1.2.1. Request URL
  269: 
  270: The request URL should have the following format:
  271: 
  272: | /personnel |
  273: |------------|
  274: 
  275: ##### 3.1.2.2. Request Parameters
  276: 
  277: This method has no input parameters.
  278: 
  279: ##### 3.1.2.3. Response Parameters
  280: 
  281: Upon successful request processing (code '200'), the following parameters should be returned in the response body:
  282: 
  283: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  284: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  285: | services | List of services present in the system | Data type: array | Yes | - |  |
  286: | agents | List of employees present in the system | Data type: array | No | - |  |
  287: 
  288: The services parameter contains a list of Service objects.
  289: The agents parameter contains a list of Agent objects.
  290: 
  291: ##### 3.1.2.3.1. Service Object Description
  292: 
  293: This parameter contains information about services and their constituent groups.
  294: 
  295: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  296: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  297: | id | Unique service identifier | Data type: string | Yes | External system |  |
  298: | name | Service name | Data type: string | Yes | External system |  |
  299: | status | Service status | Data type: string | Yes | Allowed values:<br>- ACTIVE<br>- INACTIVE |  |
  300: | serviceGroups | List of groups within the service | Data type: array | No | - |  |
  301: 
  302: The status parameter uses the enum property.
  303: 
  304: ##### 3.1.2.3.1.1. serviceGroups Parameter Description
  305: 
  306: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  307: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  308: | id | Unique group identifier | Data type: string | Yes | 1 |  |
  309: | name | Group name | Data type: string | Yes | Individual Support |  |
  310: | status | Group status | Data type: string | Yes | Allowed values:<br>- ACTIVE<br>- INACTIVE |  |
  311: | channelType | Channel type | Data type: string | No | CHATS,MAILS,INCOMING_CALLS,OUTGOING_CALLS |  |
  312: 
  313: The status parameter uses the enum property.
  314: 
  315: ##### 3.1.2.3.2. Agent Object Description
  316: 
  317: This parameter contains information about employee user accounts registered in the external system.
  318: 
  319: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  320: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  321: | id | Unique employee user account identifier | Data type: string | Yes | 1 |  |
  322: | name | Employee name or user account name | Data type: string | Yes | John |  |
  323: | surname | Employee surname | Data type: string | No | Smith |  |
  324: | secondName | Employee middle name | Data type: string | No | William |  |
  325: | agentNumber | Employee personnel number | Data type: string | No | 230-15 |  |
  326: | agentGroups | List of groups the employee processes | Data type: array | Yes | 12345 |  |
  327: | loginSSO | Agent login in SSO class system | Data type: array | No | j.smith |  |
  328: 
  329: If the system stores the user account name in one database field without the ability to separate into three different fields, then the name should be transmitted in the name field. The agentGroups parameter contains lists of groups that the employee can process. Employees who lack group data are not returned in the response.
  330: 
  331: ##### 3.1.2.3.2.1. agentGroups Parameter Description
  332: 
  333: The parameter contains a list of group identifiers.
  334: 
  335: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  336: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  337: | groupId | Unique group identifier | type: string | Yes | 1 |  |
  338: 
  339: #### 3.1.3. Response Example
  340: 
  341: ```json
  342: {
  343:   "services": [
  344:     {
  345:       "id": "External system",
  346:       "name": "External system",
  347:       "status": "ACTIVE",
  348:       "serviceGroups": [
  349:         {
  350:           "id": "1",
  351:           "name": "Individual Support",
  352:           "status": "ACTIVE"
  353:         },
  354:         {
  355:           "id": "2",
  356:           "name": "Business Support",
  357:           "status": "ACTIVE"
  358:         }
  359:       ]
  360:     }
  361:   ],
  362:   "agents": [
  363:     {
  364:       "id": "1",
  365:       "name": "John",
  366:       "surname": "Smith",
  367:       "secondName": "William",
  368:       "loginSSO": "j.smith",
  369:       "agentGroups": [
  370:         {
  371:           "groupId": "1"
  372:         }
  373:       ]
  374:     },
  375:     {
  376:       "id": "2",
  377:       "name": "Agent123",
  378:       "surname": " ",
  379:       "secondName": " ",
  380:       "agentNumber": "000123",
  381:       "loginSSO": "000123",
  382:       "agentGroups": [
  383:         {
  384:           "groupId": "1"
  385:         },
  386:         {
  387:           "groupId": "2"
  388:         }
  389:       ]
  390:     }
  391:   ]
  392: }
  393: ```
  394: 
  395: ### 3.2. Historical Data Retrieval by Groups - serviceGroupData
  396: 
  397: #### 3.2.1. General Method Description
  398: 
  399: The method is designed to retrieve historical data by groups for load forecasting. Historical data should be grouped into n-minute intervals (determined by the step parameter). Determining the interval that includes a contact is based on the contact start time. Intervals should be formed from the beginning of the day for which the request was made.
  400: 
  401: For example: a request is made for the period from 2020-01-01T00:00:00Z to 2020-01-02T00:00:00Z, step parameter equals 300000 seconds (5 minutes). This means you need to calculate how many contacts fall into intervals:
  402: 
  403: 2020-01-01T00:00:00Z - 2020-01-01T00:05:00Z,  
  404: 2020-01-01T00:05:00Z - 2020-01-01T00:10:00Z,  
  405: 2020-01-01T00:10:00Z - 2020-01-01T00:15:00Z, etc.
  406: 
  407: If no contacts were received in an interval, such an interval may not be transmitted.
  408: 
  409: #### 3.2.2. Integration Method Description
  410: 
  411: Request type: GET
  412: 
  413: ##### 3.2.2.1. Request URL
  414: 
  415: The request URL should have the following format:
  416: 
  417: | /historic/serviceGroupData |
  418: |----------------------------|
  419: 
  420: ##### 3.2.2.2. Request Parameters
  421: 
  422: ##### 3.2.2.2.1. Query Parameters
  423: 
  424: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  425: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  426: | startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
  427: | endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
  428: | step | Historical data grouping step in milliseconds | Data type: integer<br>Data format: int64 | Yes | 300,000 |  |
  429: | groupId | Group identifier for which data should be retrieved. If information is needed for multiple groups, their identifiers are listed separated by commas | Data type: string | Yes | 1,2 |  |
  430: 
  431: ##### 3.2.2.3. Response Parameters
  432: 
  433: Upon successful request execution, a list of intervals for each group should be returned. The response body contains a list of ServiceGroupHistoricData objects. Each such object contains information for one service-group. Groups that lack call data in the queried period are not returned in the response.
  434: 
  435: ##### 3.2.2.3.1. ServiceGroupHistoricData Object Description
  436: 
  437: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  438: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  439: | serviceId | Unique service identifier | Data type: string | Yes | 1 |  |
  440: | groupId | Unique group identifier | Data type: string | Yes | 1 |  |
  441: | historicData | Historical data for service-group | Data type: array | Yes | - |  |
  442: 
  443: If the service is static, a static service identifier is transmitted.
  444: 
  445: Chats closed by bot (without agent participation) should not be transmitted to WFMCC.
  446: 
  447: ##### 3.2.2.3.1.1. HistoricData Parameter Description
  448: 
  449: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) | Calculation Examples |
  450: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|-------------------|
  451: | startInterval | N-minute interval start time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |  |
  452: | endInterval | N-minute interval end time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:05:00Z |  |  |
  453: | notUniqueReceived | Number of non-unique received contacts for the group. Calculated as: number of contacts received in N-minute interval. All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 15 |  |  |
  454: | notUniqueTreated | Number of non-unique processed contacts for the group. Calculated as: number of contacts received in N-minute interval that were processed. All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 10 |  |  |
  455: | notUniqueMissed | Number of non-unique lost/missed contacts for the group. Calculated as: number of contacts received in N-minute interval that were not processed (e.g., chat closed by customer). All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 5 |  |  |
  456: | receivedCalls | Number of unique received contacts for the group. Calculated as: number of contacts received in N-minute interval that are unique. | Data type: integer<br>Data format: int64 | Yes | 10 |  |  |
  457: | treatedCalls | Number of unique contacts processed by agent for the group. Calculated as: number of contacts received in N-minute interval that were processed and are unique. | Data type: integer<br>Data format: int64 | Yes | 8 |  |  |
  458: | missCalls | Number of unique lost/missed contacts for the group. Calculated as: number of contacts received in N-minute interval that were not processed and are unique. | Data type: integer<br>Data format: int64 | Yes | 2 |  | **EXAMPLE!** Within a day, two calls from one number count as 1 unique, the second non-unique. Unique calls are determined within service/group scope. If there was a transfer - count as separate call, count first call as processed. Second depends on result. |
  459: | aht | Average handling time for the group. Calculated as: Total handling time for all processed contacts (received in N-minute interval) / number of non-unique processed contacts (received in N-minute interval). Must be transmitted in milliseconds | Data type: integer<br>Data format: int64 | Yes | 360000 |  | **EXAMPLE!** AHT time calculated as sum of: ring time + talk time + hold time<br>Agent time in status after call distribution from queue until connection with agent (ring time);<br>Agent time in status talking with customer (talk time);<br>Agent time in status holding call while searching for information/consulting supervisor (hold time); |
  460: | postProcessing | Average post-processing time for the group. Calculated as: Total post-processing time for all processed contacts (received in N-minute interval) / number of non-unique processed contacts (received in N-minute interval). Must be transmitted in milliseconds | Data type: integer<br>Data format: int64 | Yes | 3000 |  | **EXAMPLE!** PostProcessing time calculated as sum of wrapUpDuration + relaxDuration<br>Post-call processing time (wrapUpDuration)<br>Agent time in rest status after each call (relaxDuration); |
  461: 
  462: Contact uniqueness is determined by customer identifier (if there is a customer identifier, or device identifier from which the customer contacted), the first customer contact within the day is considered unique. In calculating non-unique contacts, all contacts within the day should be counted (including unique ones).
  463: 
  464: #### 3.2.3. Request Example
  465: 
  466: ```
  467: /historic/serviceGroupData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&step=300000&groupId=1,2
  468: ```
  469: 
  470: #### 3.2.4. Response Example
  471: 
  472: ```json
  473: [
  474:   {
  475:     "serviceId": "1",
  476:     "groupId": "1",
  477:     "historicData": [
  478:       {
  479:         "startInterval": "2020-01-01T00:00:00Z",
  480:         "endInterval": "2020-01-01T00:05:00Z",
  481:         "notUniqueReceived": 15,
  482:         "notUniqueTreated": 10,
  483:         "notUniqueMissed": 5,
  484:         "receivedCalls": 10,
  485:         "treatedCalls": 8,
  486:         "missCalls": 2,
  487:         "aht": 360000,
  488:         "postProcessing": 3000
  489:       },
  490:       {
  491:         "startInterval": "2020-01-01T00:05:00Z",
  492:         "endInterval": "2020-01-01T00:10:00Z",
  493:         "notUniqueReceived": 10,
  494:         "notUniqueTreated": 8,
  495:         "notUniqueMissed": 2,
  496:         "receivedCalls": 5,
  497:         "treatedCalls": 2,
  498:         "missCalls": 1,
  499:         "aht": 451000,
  500:         "postProcessing": 0
  501:       }
  502:     ]
  503:   },
  504:   {
  505:     "serviceId": "1",
  506:     "groupId": "2",
  507:     "historicData": [
  508:       {
  509:         "startInterval": "2020-01-01T10:00:00Z",
  510:         "endInterval": "2020-01-01T10:05:00Z",
  511:         "notUniqueReceived": 15,
  512:         "notUniqueTreated": 10,
  513:         "notUniqueMissed": 5,
  514:         "receivedCalls": 10,
  515:         "treatedCalls": 8,
  516:         "missCalls": 2,
  517:         "aht": 360000,
  518:         "postProcessing": 3000
  519:       },
  520:       {
  521:         "startInterval": "2020-01-01T10:05:00Z",
  522:         "endInterval": "2020-01-01T10:10:00Z",
  523:         "notUniqueReceived": 10,
  524:         "notUniqueTreated": 8,
  525:         "notUniqueMissed": 2,
  526:         "receivedCalls": 5,
  527:         "treatedCalls": 2,
  528:         "missCalls": 1,
  529:         "aht": 451000,
  530:         "postProcessing": 0
  531:       }
  532:     ]
  533:   }
  534: ]
  535: ```
  536: 
  537: ### 3.3. Historical Data Retrieval for Agent Status Changes - agentStatusData
  538: 
  539: #### 3.3.1. General Method Description
  540: 
  541: The method is designed to retrieve historical data on agent status changes. The input parameters include the period for which status information is needed, as well as the list of agents. The response should include a list of statuses for all agents from the list. The selection should include statuses whose start time or end time fall within the requested period.
  542: 
  543: Statuses can be transmitted within service-group scope. If a status cannot be linked to a group, it should be transmitted linked to all groups that the agent can process.
  544: 
  545: Alternative option - status can be transmitted without linking to group-service.
  546: 
  547: #### 3.3.2. Integration Method Description
  548: 
  549: Request type: GET
  550: 
  551: ##### 3.3.2.1. Request URL
  552: 
  553: The request URL should have the following format:
  554: 
  555: | /historic/agentStatusData |
  556: |---------------------------|
  557: 
  558: ##### 3.3.2.2. Request Parameters
  559: 
  560: ##### 3.3.2.2.1. Query Parameters
  561: 
  562: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  563: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  564: | startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
  565: | endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
  566: | agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2 |  |
  567: 
  568: ##### 3.3.2.3. Response Parameters
  569: 
  570: Upon successful request processing, a list of statuses for all agents is returned. Agents who lack statuses in the queried period are not returned in the response. Agent information is transmitted in the AgentState object.
  571: 
  572: ##### 3.3.2.3.1. AgentState Object Description
  573: 
  574: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  575: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  576: | serviceId | Unique service identifier within which the status was set | Data type: string | No | 1 |  |
  577: | groupId | Unique group identifier within which the status was set | Data type: string | No | 1 |  |
  578: | agentId | Unique agent identifier for whom statuses are transmitted | Data type: string | Yes | 1 |  |
  579: | states | List of agent statuses set within the group | Data type: array | Yes | - |  |
  580: 
  581: Since the service has a static value, serviceId parameter always transmits 1.
  582: 
  583: ##### 3.3.2.3.1.1. states Parameter Description
  584: 
  585: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  586: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  587: | startDate | Status start date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:15:36Z |  |
  588: | endDate | Status end date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:18:36Z |  |
  589: | stateCode | Unique status identifier | Data type: string<br>Data format: string | Yes | Break |  |
  590: | stateName | Status name | Data type: string<br>Data format: string | Yes | Technical break |  |
  591: 
  592: If the third-party system has statuses with reasons, then stateCode should be formed from status id + reason id, and stateName should be formed from status name and reason name.
  593: 
  594: #### 3.3.3. Request Example
  595: 
  596: ```
  597: /historic/agentStatusData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2
  598: ```
  599: 
  600: #### 3.3.4. Response Example
  601: 
  602: ```json
  603: [
  604:   {
  605:     "serviceId": "1",
  606:     "groupId": "1",
  607:     "agentId": "1",
  608:     "states": [
  609:       {
  610:         "startDate": "2020-01-01T10:10:36Z",
  611:         "endDate": "2020-01-01T10:15:36Z",
  612:         "stateCode": "Work",
  613:         "stateName": "Contact processing"
  614:       },
  615:       {
  616:         "startDate": "2020-01-01T10:15:36Z",
  617:         "endDate": "2020-01-01T10:18:36Z",
  618:         "stateCode": "Break",
  619:         "stateName": "Technical break"
  620:       }
  621:     ]
  622:   },
  623:   {
  624:     "serviceId": "1",
  625:     "groupId": "2",
  626:     "agentId": "1",
  627:     "states": [
  628:       {
  629:         "startDate": "2020-01-01T10:18:36Z",
  630:         "endDate": "2020-01-01T10:25:36Z",
  631:         "stateCode": "Work",
  632:         "stateName": "Contact processing"
  633:       }
  634:     ]
  635:   }
  636: ]
  637: ```
  638: 
  639: ### 3.4. Historical Data Retrieval for Agent Login/Logout - agentLoginData
  640: 
  641: #### 3.4.1. General Method Description
  642: 
  643: The method is designed to retrieve historical data on agent login/logout from the system. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of agent logins/logouts. The selection should include periods whose login time or logout time fall within the requested period.
  644: 
  645: #### 3.4.2. Integration Method Description
  646: 
  647: Request type: GET
  648: 
  649: ##### 3.4.2.1. Request URL
  650: 
  651: The request URL should have the following format:
  652: 
  653: | /historic/agentLoginData |
  654: |--------------------------|
  655: 
  656: ##### 3.4.2.2. Request Parameters
  657: 
  658: ##### 3.4.2.2.1. Query Parameters
  659: 
  660: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  661: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  662: | startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
  663: | endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
  664: | agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2,3 |  |
  665: 
  666: ##### 3.4.2.3. Response Parameters
  667: 
  668: Upon successful request processing, the response body returns a list of logins/logouts and duration of agent presence in the system. Agents who were not in the system during the queried period (did not login/logout) are not returned in the response. Agent information is transmitted in the AgentLogins object.
  669: 
  670: ##### 3.4.2.3.1. AgentLogins Object Description
  671: 
  672: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  673: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  674: | agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
  675: | logins | List of agent logins/logouts to the system | Data type: array | Yes | - |  |
  676: 
  677: ##### 3.4.2.3.1.1. Logins Parameter Description
  678: 
  679: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  680: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  681: | loginDate | Agent system login date and time, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:03:15Z |  |
  682: | logoutDate | Agent system logout date and time, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T12:30:05Z |  |
  683: | duration | Duration of agent presence in system, in milliseconds | Data type: integer<br>Data format: int64 | Yes | 8810000 |  |
  684: 
  685: #### 3.4.3. Request Example
  686: 
  687: ```
  688: /historic/agentLoginData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2,3
  689: ```
  690: 
  691: #### 3.4.4. Response Example
  692: 
  693: ```json
  694: [
  695:   {
  696:     "agentId": "1",
  697:     "logins": [
  698:       {
  699:         "loginDate": "2020-01-01T10:03:15Z",
  700:         "logoutDate": "2020-01-01T12:30:05Z",
  701:         "duration": 8810000
  702:       },
  703:       {
  704:         "loginDate": "2020-01-01T18:15:05Z",
  705:         "logoutDate": "2020-01-01T21:32:55Z",
  706:         "duration": 11870000
  707:       }
  708:     ]
  709:   },
  710:   {
  711:     "agentId": "2",
  712:     "logins": [
  713:       {
  714:         "loginDate": "2020-01-01T23:53:15Z",
  715:         "logoutDate": "2020-01-02T02:30:05Z",
  716:         "duration": 9410000
  717:       }
  718:     ]
  719:   }
  720: ]
  721: ```
  722: 
  723: ### 3.5. Historical Data Retrieval for Agent Processed Contacts - agentCallsData
  724: 
  725: #### 3.5.1. General Method Description
  726: 
  727: The method is designed to retrieve historical data on contacts processed by agents. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of processed contacts by agent and group. The selection includes contacts whose start time falls within the queried period.
  728: 
  729: #### 3.5.2. Integration Method Description
  730: 
  731: Request type: GET
  732: 
  733: ##### 3.5.2.1. Request URL
  734: 
  735: The request URL should have the following format:
  736: 
  737: | /historic/agentCallsData |
  738: |--------------------------|
  739: 
  740: ##### 3.5.2.2. Request Parameters
  741: 
  742: ##### 3.5.2.2.1. Query Parameters
  743: 
  744: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  745: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  746: | startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
  747: | endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
  748: | agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2 |  |
  749: 
  750: ##### 3.5.2.3. Response Parameters
  751: 
  752: Upon successful request processing, the response body returns a list of processed contacts by agent, separated by groups. If an agent had no processed contacts in the queried period, such agent is not returned in the response. Agent information is transmitted in the AgentCalls object.
  753: 
  754: ##### 3.5.2.3.1. AgentCalls Object Description
  755: 
  756: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  757: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  758: | agentId | Unique agent identifier for whom information is transmitted | Data type: string | Yes | 1 |  |
  759: | serviceId | Unique service identifier within which the status was set | Data type: string | Yes | 1 |  |
  760: | groupId | Unique group identifier within which the status was set | Data type: string | Yes | 1 |  |
  761: | agentCalls | List of processed contacts by agent within the group | Data type: array | Yes | - |  |
  762: 
  763: Since the service has a static value, serviceId parameter always transmits 1.
  764: 
  765: ##### 3.5.2.3.1.1. agentCalls Parameter Description
  766: 
  767: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  768: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  769: | startCall | Contact processing start date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:03:15Z |  |
  770: | endCall | Contact processing end date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:08:15Z |  |
  771: | duration | Contact processing time in milliseconds | Data type: integer<br>Data format: int64 | Yes | 300000 |  |
  772: 
  773: #### 3.5.3. Request Example
  774: 
  775: ```
  776: /historic/agentCallsData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2
  777: ```
  778: 
  779: #### 3.5.4. Response Example
  780: 
  781: ```json
  782: [
  783:   {
  784:     "agentId": "1",
  785:     "serviceId": "1",
  786:     "groupId": "1",
  787:     "agentCalls": [
  788:       {
  789:         "startCall": "2020-01-01T10:03:15Z",
  790:         "endCall": "2020-01-01T10:08:15Z",
  791:         "duration": 300000
  792:       },
  793:       {
  794:         "startCall": "2020-01-01T10:04:02Z",
  795:         "endCall": "2020-01-01T10:12:15Z",
  796:         "duration": 493000
  797:       }
  798:     ]
  799:   },
  800:   {
  801:     "agentId": "1",
  802:     "serviceId": "1",
  803:     "groupId": "2",
  804:     "agentCalls": [
  805:       {
  806:         "startCall": "2020-01-01T10:03:15Z",
  807:         "endCall": "2020-01-01T10:03:45Z",
  808:         "duration": 30000
  809:       }
  810:     ]
  811:   }
  812: ]
  813: ```
  814: 
  815: ### 3.6. Historical Data Retrieval for Chat Work Time - agentChatsWorkTime (Chat Platform Only)
  816: 
  817: #### 3.6.1. General Method Description
  818: 
  819: The method is designed to retrieve historical data on agent time spent in the system with at least one chat. If integration is not performed with a chat platform, this method does not require implementation. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of days per agent during which they had working time. If the request includes multiple full days, they should be transmitted separately in the response.
  820: 
  821: Time is calculated as follows:
  822: 
  823: Count the number of seconds in a day when the agent was processing at least 1 chat. If the start or end of chat processing was outside the queried period, the interval outside the period is not counted. For example:
  824: 
  825: Request sent for period from 2020-01-01 00:00:00 to 2020-01-02 00:00:00. Agent processed chats in the following intervals: 01.01.2020 22:45:00 - 01.01.2020 23:02:00 and 22:58:00 01.01.2020 - 00:12:00 02.01.2020. As a result, for 01.01.2020 the following value should be transmitted - 4500000. The value was obtained as follows:
  826: 
  827: * interval 22:45:00 - 23:02:00 is counted in full
  828: * from interval 22:58:00 - 00:12:00, the period 23:02:00 - 00:00:00 is counted.
  829: 
  830: Since there were 2 chats in the interval from 22:58:00 to 23:02:00, we count this interval once.
  831: 
  832: #### 3.6.2. Integration Method Description
  833: 
  834: Request type: GET
  835: 
  836: ##### 3.6.2.1. Request URL
  837: 
  838: The request URL should have the following format:
  839: 
  840: | /historic/agentChatsWorkTime |
  841: |------------------------------|
  842: 
  843: ##### 3.6.2.2. Request Parameters
  844: 
  845: ##### 3.6.2.2.1. Query Parameters
  846: 
  847: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  848: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  849: | startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
  850: | endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-03T00:00:00Z |  |
  851: | agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2,3 |  |
  852: 
  853: ##### 3.6.2.3. Response Parameters
  854: 
  855: Upon successful request processing, date and time data for all agents is returned. Agents who lack processed chats in the queried period are not returned in the response. Agent information is transmitted in the AgentChatsWorkTime object.
  856: 
  857: ##### 3.6.2.3.1. AgentChatsWorkTime Object Description
  858: 
  859: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  860: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  861: | agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
  862: | workDate | Date for which time is calculated | Data type: string<br>Data format: date | Yes | 2020-01-01 |  |
  863: | workTime | Time spent in system with at least one chat in milliseconds | Data type: integer<br>Data format: int64 | Yes | 3600000 |  |
  864: 
  865: #### 3.6.3. Request Example
  866: 
  867: ```
  868: /historic/agentChatsWorkTime?startDate=2020-01-01T00:00:00Z&endDate=2020-01-03T00:00:00Z&agentId=1,2,3
  869: ```
  870: 
  871: #### 3.6.4. Response Example
  872: 
  873: ```json
  874: [
  875:   {
  876:     "agentId": "1",
  877:     "workDate": "2020-01-01",
  878:     "workTime": 3600000
  879:   },
  880:   {
  881:     "agentId": "1",
  882:     "workDate": "2020-01-02",
  883:     "workTime": 300000
  884:   },
  885:   {
  886:     "agentId": "2",
  887:     "workDate": "2020-01-01",
  888:     "workTime": 54000
  889:   }
  890: ]
  891: ```
  892: 
  893: ## 4. Description of Integration Methods for Real-Time Data
  894: 
  895: ### 4.1. Current Agent Status Transmission from External System to WFMCC
  896: 
  897: #### 4.1.1. General Method Description
  898: 
  899: The method is designed to transmit agent status change events. Each operator status change event is transmitted separately. For each status change event, two messages will be transmitted (first about the operator entering the status, second about the operator exiting the status). All request parameters are required and can be repeated in the request only once. Data transmission intervals are not regulated. No response from the WFMCC system is provided, including HTTP response codes. Data is sent to the WFMCC system without controlling receipt and data integrity.
  900: 
  901: If an agent is in one status and switches to another - it is necessary to send a message about exiting one status and a message about entering another status to the WFM CC system. Request initiation from the WFM CC side is not provided.
  902: 
  903: If it is impossible to implement an agent status change monitoring service and sending information by events from the chat platform side, it is necessary to implement the method - [4.2. Current Agent Status Retrieval - agentStatus](#42-current-agent-status-retrieval---agentstatus).
  904: 
  905: #### 4.1.2. Integration Method Description
  906: 
  907: Request type: POST
  908: 
  909: ##### 4.1.2.1. Request URL
  910: 
  911: Status information transmission should be performed at the address:
  912: 
  913: | http://[IP:port]/ccwfm/api/rest/status |
  914: |----------------------------------------|
  915: 
  916: where [IP:port] is the IP address and port of the WFM CC application.
  917: 
  918: ##### 4.1.2.2. Request Parameters
  919: 
  920: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  921: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  922: | workerId | Unique employee identifier | Data type: string | Yes | 1 |  |
  923: | stateName | Status name | Data type: string | Yes | Technical break |  |
  924: | stateCode | Unique status identifier | Data type: string | Yes | Break |  |
  925: | systemId | System identifier for which statuses are sent. The external system name is used as identifier. | Data type: string | Yes | External system |  |
  926: | actionTime | Status change timestamp. Transmitted in Unix Time Stamp format. | Data type: timeStamp | Yes | 1568816347 |  |
  927: | action | Type of status change event, possible parameter values: 1 – status entry; 0 – status exit; | Data type: integer | Yes | 1 |  |
  928: 
  929: #### 4.1.3. Request Example
  930: 
  931: ```json
  932: {
  933:   "workerId": "1",
  934:   "stateName": "Technical break",
  935:   "stateCode": "Break",
  936:   "systemId": "External system",
  937:   "actionTime": 1568816347,
  938:   "action": 1
  939: }
  940: ```
  941: 
  942: ### 4.2. Current Agent Status Retrieval - agentStatus
  943: 
  944: #### 4.2.1. General Method Description
  945: 
  946: The method is designed to retrieve current agent status and its start time. There are no input parameters, the response should include a list of all active agents and their statuses.
  947: 
  948: #### 4.2.2. Integration Method Description
  949: 
  950: Request type: GET
  951: 
  952: ##### 4.2.2.1. Request URL
  953: 
  954: The request URL should have the following format:
  955: 
  956: | /online/agentStatus |
  957: |---------------------|
  958: 
  959: ##### 4.2.2.2. Request Parameters
  960: 
  961: No input parameters.
  962: 
  963: ##### 4.2.2.3. Response Parameters
  964: 
  965: Upon successful request processing, a list of active agents and their statuses is returned. Agent information is transmitted in the AgentOnlineStatus object.
  966: 
  967: ##### 4.2.2.3.1. AgentOnlineStatus Object Description
  968: 
  969: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
  970: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
  971: | agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
  972: | stateCode | Unique status identifier | Data type: string | Yes | Break |  |
  973: | stateName | Status name | Data type: string | Yes | Technical break |  |
  974: | startDate | Current status start time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T15:25:13Z |  |
  975: 
  976: #### 4.2.3. Response Example
  977: 
  978: ```json
  979: [
  980:   {
  981:     "agentId": "1",
  982:     "stateCode": "Break",
  983:     "stateName": "Technical break",
  984:     "startDate": "2020-01-01T15:25:13Z"
  985:   },
  986:   {
  987:     "agentId": "2",
  988:     "stateCode": "Work",
  989:     "stateName": "Contact processing",
  990:     "startDate": "2020-01-01T15:20:13Z"
  991:   }
  992: ]
  993: ```
  994: 
  995: ### 4.3. Current Group Metrics Retrieval - groupsOnlineLoad
  996: 
  997: #### 4.3.1. General Method Description
  998: 
  999: The method is designed to retrieve current group metrics for the current day. The input parameters include a list of groups. The response should include a set of metrics for each group.
 1000: 
 1001: #### 4.3.2. Integration Method Description
 1002: 
 1003: Request type: GET
 1004: 
 1005: ##### 4.3.2.1. Request URL
 1006: 
 1007: The request URL should have the following format:
 1008: 
 1009: | /online/groupsOnlineLoad |
 1010: |--------------------------|
 1011: 
 1012: ##### 4.3.2.2. Request Parameters
 1013: 
 1014: ##### 4.3.2.2.1. Query Parameters
 1015: 
 1016: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example |
 1017: |----------------|----------------------|-------------|-------------------|--------------|
 1018: | groupId | Group identifier for which data should be retrieved. If information is needed for multiple groups, their identifiers are listed separated by commas | Data type: string | Yes | 1,2 |
 1019: 
 1020: ##### 4.3.2.3. Response Parameters
 1021: 
 1022: Upon successful request execution, metrics for each group should be returned. The response body contains a list of GroupOnlineLoad objects. Each such object contains information for one service-group.
 1023: 
 1024: ##### 4.3.2.3.1. GroupOnlineLoad Object Description
 1025: 
 1026: | Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
 1027: |----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
 1028: | serviceId | Unique service identifier | Data type: string | Yes | 1 |  |
 1029: | groupId | Unique group identifier | Data type: string | Yes | 1 |  |
 1030: | callNumber | Number of contacts in queue at request time | Data type: integer | Yes | 5 |  |
 1031: | operatorNumber | Number of operators working on the group, or waiting for contacts | Data type: integer | Yes | 2 |  |
 1032: | callReceived | Number of received contacts since start of day | Data type: integer | No | 100 |  |
 1033: | aht | Average talk time for the group since start of day, in milliseconds | Data type: integer | No | 360000 |  |
 1034: | acd | Percentage of answered contacts since start of day. Calculated as: Number of processed contacts / Number of received contacts | Data type: number<br>Data format: double | No | 95.0554 |  |
 1035: | awt | Average wait time for contacts in queue since start of day, in milliseconds | Data type: integer | No | 20000 |  |
 1036: | callAnswered | Number of processed calls from start of day to request time | Data type: integer | No | 100 |  |
 1037: | callAnsweredTst | Number of processed calls from start of day to request time that were waiting for agent answer no more than N seconds. Target wait time (N seconds) must be determined | Data type: integer | No | 100 |  |
 1038: | callProcessing | Number of calls being processed by agents at request time | Data type: integer | No | 100 |  |
 1039: 
 1040: Since the service has a static value, serviceId parameter always transmits 1.
 1041: 
 1042: #### 4.3.3. Request Example
 1043: 
 1044: ```
 1045: /online/groupsOnlineLoad?groupId=1,2
 1046: ```
 1047: 
 1048: #### 4.3.4. Response Example
 1049: 
 1050: ```json
 1051: [
 1052:   {
 1053:     "serviceId": "1",
 1054:     "groupId": "1",
 1055:     "callNumber": 5,
 1056:     "operatorNumber": 2,
 1057:     "callReceived": 100,
 1058:     "aht": 360000,
 1059:     "acd": 95.0554,
 1060:     "awt": 20000,
 1061:     "callAnswered": 10,
 1062:     "callAnsweredTst": 1,
 1063:     "callProcessing": 1
 1064:   },
 1065:   {
 1066:     "serviceId": "1",
 1067:     "groupId": "2",
 1068:     "callNumber": 3,
 1069:     "operatorNumber": 0,
 1070:     "callReceived": 6,
 1071:     "aht": 36000,
 1072:     "acd": 100,
 1073:     "awt": 2000,
 1074:     "callAnswered": 10,
 1075:     "callAnsweredTst": 1,
 1076:     "callProcessing": 1
 1077:   }
 1078: ]
 1079: ```
 1080: 
 1081: ## 5. Integration Error Description
 1082: 
 1083: ### 5.1. Error Code - 500
 1084: 
 1085: Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 500. If this error occurs during request processing, a response with code "500" must be returned and the following parameters transmitted in the response body:
 1086: 
 1087: | Parameter Name | Parameter Description | Data Format |
 1088: |----------------|----------------------|-------------|
 1089: | field | Not used | Data type: string |
 1090: | message | Error text | Data type: string |
 1091: | description | Clear error description | Data type: string |
 1092: 
 1093: ### 5.2. Error Code - 404
 1094: 
 1095: Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 404. This error occurs if the third-party system has no data for the requested parameters from WFMCC.
 1096: 
 1097: ### 5.3. Error Code - 400
 1098: 
 1099: Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 400. This error occurs with incorrect data in the client request. Validation errors, input data errors, etc.
 1100: 
 1101: | Parameter Name | Parameter Description | Data Format |
 1102: |----------------|----------------------|-------------|
 1103: | field | Field from request where error occurred | Data type: string |
 1104: | message | Error text | Data type: string |
 1105: | description | Clear error description | Data type: string |