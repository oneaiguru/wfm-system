# ARGUS WFM REST API - Complete Feature Extraction for BDD Coverage

## Document: rest-api-integration-en.md

### Core Architecture & Integration Features

**Line 237:** Feature: REST API architectural integration solution  
Keywords: REST, API, integration, architecture, solution, external system, universal integration service  
Priority: Critical

**Line 237:** Feature: JSON data format support  
Keywords: JSON, data format, application/json, response, request, produces annotation  
Priority: Critical

**Line 241:** Feature: Integration architecture diagram support  
Keywords: integration, architecture, diagram, data exchange schema  
Priority: High

### Personnel & Organization Structure Features

**Line 252:** Feature: Personnel data retrieval via REST API  
Keywords: personnel, employees, agents, services, groups, user accounts, staff, organization structure  
Priority: Critical

**Line 256:** Feature: Service and group hierarchy management  
Keywords: service, group, hierarchy, organization, structure, queue, project, channel, skill  
Priority: Critical

**Line 256-262:** Feature: Static service value support for systems without service concept  
Keywords: static service, external system, fallback, default, no service concept  
Priority: High

**Line 288:** Feature: Service object description with status management  
Keywords: service object, status, ACTIVE, INACTIVE, service management  
Priority: High

**Line 297-300:** Feature: Service status management (ACTIVE/INACTIVE)  
Keywords: service, status, active, inactive, management, lifecycle, enum property  
Priority: High

**Line 304-313:** Feature: Service groups parameter description  
Keywords: service groups, group identifier, group name, group status, channel type  
Priority: Critical

**Line 311:** Feature: Group status management with channel type support  
Keywords: group, status, channel, type, management, classification, ACTIVE, INACTIVE  
Priority: High

**Line 311:** Feature: Channel type classification (CHATS, MAILS, INCOMING_CALLS, OUTGOING_CALLS)  
Keywords: channel, type, classification, chats, mails, calls, communication, incoming, outgoing  
Priority: Critical

**Line 315-327:** Feature: Agent object description and management  
Keywords: agent object, employee user account, agent identifier, name, surname, middle name  
Priority: Critical

**Line 325:** Feature: Agent personnel number tracking  
Keywords: personnel, number, tracking, employee, ID, identification, agentNumber  
Priority: Medium

**Line 326:** Feature: Agent groups assignment and management  
Keywords: agent, groups, assignment, management, membership, multi-group capability  
Priority: Critical

**Line 327:** Feature: SSO login integration support  
Keywords: SSO, login, integration, authentication, single-sign-on, loginSSO  
Priority: Medium

**Line 329:** Feature: Multi-field name storage flexibility  
Keywords: name storage, database field, separation capability, single field fallback  
Priority: Medium

**Line 331-337:** Feature: Agent groups parameter description  
Keywords: agent groups, group identifiers, employee processing groups, groupId  
Priority: Critical

### Historical Data Retrieval Features

**Line 395:** Feature: Historical data retrieval by groups for load forecasting  
Keywords: historical data, forecasting, load prediction, group metrics, serviceGroupData  
Priority: Critical

**Line 399:** Feature: N-minute interval data grouping and aggregation  
Keywords: interval, step, time grouping, 5 minutes, 15 minutes, aggregation, milliseconds  
Priority: Critical

**Line 401-407:** Feature: Interval formation from beginning of day  
Keywords: interval formation, day start, contact start time, interval determination  
Priority: High

**Line 407:** Feature: Empty interval handling  
Keywords: empty interval, no contacts, optional transmission, data efficiency  
Priority: Medium

**Line 433:** Feature: ServiceGroupHistoricData object response handling  
Keywords: service group historic data, object description, group data absence handling  
Priority: High

**Line 445:** Feature: Bot-closed chat exclusion  
Keywords: bot closed, chat exclusion, agent participation, WFMCC transmission  
Priority: Medium

**Line 451-461:** Feature: Historic data parameter descriptions  
Keywords: interval times, contact counting, processing metrics, duration calculations  
Priority: Critical

**Line 453:** Feature: Non-unique received contacts counting  
Keywords: non-unique, received, contacts, N-minute interval, customer contacts  
Priority: High

**Line 454:** Feature: Non-unique processed contacts counting  
Keywords: non-unique, treated, processed, contacts, customer contacts  
Priority: High

**Line 455:** Feature: Non-unique missed contacts counting  
Keywords: non-unique, missed, lost, contacts, customer closed, unprocessed  
Priority: High

**Line 456:** Feature: Unique received contacts counting  
Keywords: unique, received, contacts, customer identifier, deduplication  
Priority: Critical

**Line 457:** Feature: Unique processed contacts counting  
Keywords: unique, treated, processed, agent handling, customer identifier  
Priority: Critical

**Line 458:** Feature: Unique missed contacts counting with transfer handling  
Keywords: unique, missed, lost, transfer handling, separate call counting  
Priority: High

**Line 459:** Feature: Average handling time (AHT) calculation  
Keywords: AHT, average handling time, duration, processing time, ring time, talk time, hold time  
Priority: Critical

**Line 460:** Feature: Post-processing time calculation  
Keywords: post-processing, wrap-up, relax time, wrapUpDuration, relaxDuration  
Priority: High

**Line 462:** Feature: Contact uniqueness determination by customer identifier  
Keywords: unique contacts, customer identifier, device identifier, daily scope, first contact  
Priority: High

### Agent Status Tracking Features

**Line 537:** Feature: Historical data retrieval for agent status changes  
Keywords: agent status, status history, state changes, agentStatusData, historical tracking  
Priority: Critical

**Line 541:** Feature: Status period selection criteria  
Keywords: status selection, start time, end time, period criteria, time range  
Priority: High

**Line 543:** Feature: Service-group scoped status tracking  
Keywords: service scope, group scope, status context, group linking  
Priority: High

**Line 545:** Feature: Alternative status transmission without group linking  
Keywords: status, no group, alternative, unlinked status, fallback option  
Priority: Medium

**Line 572-580:** Feature: AgentState object description  
Keywords: agent state, service identifier, group identifier, agent identifier, states list  
Priority: Critical

**Line 581:** Feature: Static service value in status tracking  
Keywords: static service, serviceId transmission, value 1, service identification  
Priority: Medium

**Line 585-592:** Feature: States parameter description with date-time handling  
Keywords: states parameter, start date, end date, state code, state name, timezone  
Priority: Critical

**Line 592:** Feature: Status with reasons handling  
Keywords: status reasons, stateCode formation, stateName formation, reason combination  
Priority: High

### Agent Login/Session Tracking Features

**Line 639:** Feature: Historical data retrieval for agent login/logout  
Keywords: login, logout, session, duration, presence, agentLoginData, historical  
Priority: Critical

**Line 643:** Feature: Agent system presence duration calculation  
Keywords: presence, duration, system, time, calculation, session, login period  
Priority: High

**Line 668:** Feature: Login/logout period selection criteria  
Keywords: login period, logout period, time range, period criteria  
Priority: High

**Line 670-675:** Feature: AgentLogins object description  
Keywords: agent logins, unique agent identifier, logins list, response structure  
Priority: Critical

**Line 677-683:** Feature: Logins parameter description with duration  
Keywords: login date, logout date, duration, milliseconds, timezone, presence time  
Priority: Critical

### Agent Contact Processing Features

**Line 723:** Feature: Historical data retrieval for agent processed contacts  
Keywords: processed, contacts, agent, historical, agentCallsData, calls, handling  
Priority: Critical

**Line 727:** Feature: Contact start time period filtering  
Keywords: contact start time, period filtering, queried period, time range  
Priority: High

**Line 752:** Feature: Agent performance tracking by group  
Keywords: agent performance, group separation, processed contacts, performance metrics  
Priority: High

**Line 754-763:** Feature: AgentCalls object description  
Keywords: agent calls, agent identifier, service identifier, group identifier, calls list  
Priority: Critical

**Line 763:** Feature: Static service value in agent calls  
Keywords: static service, serviceId parameter, value 1, service identification  
Priority: Medium

**Line 765-771:** Feature: Agent calls parameter description  
Keywords: start call, end call, duration, contact processing, milliseconds, timezone  
Priority: Critical

### Chat Work Time Features

**Line 815:** Feature: Historical data retrieval for chat work time (Chat Platform Only)  
Keywords: chat time, work time, agentChatsWorkTime, chat platform, messaging  
Priority: Medium

**Line 819:** Feature: Chat platform conditional implementation  
Keywords: chat platform, conditional implementation, method requirement, platform specific  
Priority: Medium

**Line 821:** Feature: Time calculation with at least one active chat  
Keywords: active chat, time calculation, concurrent sessions, at least one chat  
Priority: Medium

**Line 823-831:** Feature: Complex chat overlap time calculation  
Keywords: chat overlap, concurrent chats, interval counting, period boundaries, calculation example  
Priority: High

**Line 855-863:** Feature: AgentChatsWorkTime object description  
Keywords: agent chat work time, agent identifier, work date, work time milliseconds  
Priority: Medium

### Real-Time Data Features

**Line 895:** Feature: Real-time agent status transmission to WFMCC  
Keywords: real-time, status, transmission, events, live updates, WFMCC  
Priority: Critical

**Line 899:** Feature: Event-based status change monitoring  
Keywords: events, status change, monitoring, notifications, separate transmission  
Priority: Critical

**Line 899:** Feature: Status entry and exit event handling  
Keywords: entry, exit, events, status transitions, tracking, dual messages  
Priority: Critical

**Line 901:** Feature: Status transition message requirements  
Keywords: status transition, exit message, entry message, dual transmission  
Priority: High

**Line 903:** Feature: Alternative current status retrieval method  
Keywords: alternative method, current status, monitoring service, fallback option  
Priority: High

**Line 913:** Feature: WFMCC system address configuration  
Keywords: WFMCC, IP address, port, configuration, system address  
Priority: High

**Line 920-927:** Feature: Status transmission request parameters  
Keywords: workerId, stateName, stateCode, systemId, actionTime, action parameter  
Priority: Critical

**Line 926:** Feature: Unix timestamp format for status changes  
Keywords: Unix timestamp, actionTime, status change time, timestamp format  
Priority: High

**Line 927:** Feature: Action type specification (entry/exit)  
Keywords: action type, status entry, status exit, 1 for entry, 0 for exit  
Priority: Critical

**Line 942:** Feature: Current agent status retrieval for all active agents  
Keywords: current status, retrieval, active agents, agentStatus, online status  
Priority: Critical

**Line 946:** Feature: Real-time agent status monitoring without parameters  
Keywords: monitoring, status, real-time, parameterless, all agents, no input  
Priority: High

**Line 965:** Feature: AgentOnlineStatus object description  
Keywords: agent online status, agent identifier, state code, state name, start date  
Priority: Critical

**Line 995:** Feature: Current group metrics retrieval for performance monitoring  
Keywords: group metrics, performance monitoring, groupsOnlineLoad, KPIs, current day  
Priority: Critical

**Line 999:** Feature: Current day group metrics scope  
Keywords: current day, group metrics, daily scope, performance tracking  
Priority: High

**Line 1022:** Feature: GroupOnlineLoad object comprehensive metrics  
Keywords: group online load, service identifier, group identifier, comprehensive metrics  
Priority: Critical

**Line 1030:** Feature: Queue contact counting and monitoring  
Keywords: queue, contacts, counting, callNumber, monitoring, waiting contacts  
Priority: Critical

**Line 1031:** Feature: Active operator counting by group  
Keywords: operators, counting, active, operatorNumber, group, workforce, waiting for contacts  
Priority: Critical

**Line 1032:** Feature: Daily received contacts counting  
Keywords: daily, received, contacts, callReceived, counting, volume, start of day  
Priority: High

**Line 1033:** Feature: Average call duration calculation for current day  
Keywords: average, call, duration, daily, AHT, current day, milliseconds  
Priority: Critical

**Line 1034:** Feature: Answered call percentage calculation (ACD)  
Keywords: answered, percentage, ACD, service level, calculation, processed/received ratio  
Priority: Critical

**Line 1035:** Feature: Average wait time calculation for queued contacts  
Keywords: average, wait, time, queue, AWT, calculation, milliseconds, start of day  
Priority: Critical

**Line 1036:** Feature: Daily answered calls counting  
Keywords: answered calls, daily counting, callAnswered, processed calls, start of day  
Priority: High

**Line 1037:** Feature: Service level calculation with target wait time  
Keywords: service level, target wait time, callAnsweredTst, SLA, TST, N seconds  
Priority: Critical

**Line 1038:** Feature: Currently processing calls counting  
Keywords: processing, calls, current, active, callProcessing, handling, agents  
Priority: High

**Line 1040:** Feature: Static service value in group metrics  
Keywords: static service, serviceId parameter, value 1, group metrics  
Priority: Medium

### Error Handling Features

**Line 1083:** Feature: HTTP error code 500 handling with detailed messages  
Keywords: error, 500, handling, messages, server, internal, error response  
Priority: Critical

**Line 1085:** Feature: Error response exclusion for status transmission  
Keywords: error response, status transmission exclusion, section 4.1 exception  
Priority: Medium

**Line 1087-1091:** Feature: Error 500 response parameters  
Keywords: error 500, field parameter, message, description, error details  
Priority: High

**Line 1093:** Feature: HTTP error code 404 handling for missing data  
Keywords: error, 404, handling, missing data, not found, no data response  
Priority: High

**Line 1095:** Feature: Third-party system data absence handling  
Keywords: third-party system, data absence, WFMCC request, no data scenario  
Priority: Medium

**Line 1097:** Feature: HTTP error code 400 handling for validation errors  
Keywords: error, 400, handling, validation, bad request, client request errors  
Priority: Critical

**Line 1099:** Feature: Input data validation error handling  
Keywords: input data, validation errors, client request, data errors  
Priority: High

**Line 1101-1105:** Feature: Error 400 response parameters with field identification  
Keywords: error 400, field identification, error text, description, validation details  
Priority: High

### Data Flow & Integration Patterns

**Line 245-248:** Feature: Data flow description with function mapping  
Keywords: data flow, historical data, online data, function transmission mapping  
Priority: High

**Line 247:** Feature: Historical data functions comprehensive list  
Keywords: personnel, serviceGroupData, agentStatusData, agentLoginData, agentCallsData, agentChatsWorkTime  
Priority: Critical

**Line 248:** Feature: Real-time data functions list  
Keywords: status transmission, agentStatus, groupsOnlineLoad, online data  
Priority: Critical

### Request/Response Format Features

**Line 266:** Feature: GET request type for personnel retrieval  
Keywords: GET request, personnel retrieval, HTTP method, no parameters  
Priority: High

**Line 277:** Feature: Parameterless personnel request  
Keywords: no input parameters, personnel method, parameterless request  
Priority: Medium

**Line 411:** Feature: GET request type for historical group data  
Keywords: GET request, historical data, serviceGroupData, HTTP method  
Priority: High

**Line 549:** Feature: GET request type for agent status data  
Keywords: GET request, agent status, agentStatusData, HTTP method  
Priority: High

**Line 647:** Feature: GET request type for agent login data  
Keywords: GET request, agent login, agentLoginData, HTTP method  
Priority: High

**Line 731:** Feature: GET request type for agent calls data  
Keywords: GET request, agent calls, agentCallsData, HTTP method  
Priority: High

**Line 834:** Feature: GET request type for chat work time  
Keywords: GET request, chat work time, agentChatsWorkTime, HTTP method  
Priority: Medium

**Line 907:** Feature: POST request type for status transmission  
Keywords: POST request, status transmission, real-time, HTTP method  
Priority: Critical

**Line 950:** Feature: GET request type for current agent status  
Keywords: GET request, current status, agentStatus, HTTP method  
Priority: High

**Line 1003:** Feature: GET request type for group online load  
Keywords: GET request, group load, groupsOnlineLoad, HTTP method  
Priority: High

### URL Pattern Features

**Line 272:** Feature: Personnel endpoint URL pattern  
Keywords: /personnel, endpoint, URL pattern, personnel retrieval  
Priority: High

**Line 417:** Feature: Historic serviceGroupData endpoint URL pattern  
Keywords: /historic/serviceGroupData, endpoint, URL pattern, historical data  
Priority: High

**Line 555:** Feature: Historic agentStatusData endpoint URL pattern  
Keywords: /historic/agentStatusData, endpoint, URL pattern, status history  
Priority: High

**Line 653:** Feature: Historic agentLoginData endpoint URL pattern  
Keywords: /historic/agentLoginData, endpoint, URL pattern, login history  
Priority: High

**Line 737:** Feature: Historic agentCallsData endpoint URL pattern  
Keywords: /historic/agentCallsData, endpoint, URL pattern, calls history  
Priority: High

**Line 840:** Feature: Historic agentChatsWorkTime endpoint URL pattern  
Keywords: /historic/agentChatsWorkTime, endpoint, URL pattern, chat work time  
Priority: Medium

**Line 956:** Feature: Online agentStatus endpoint URL pattern  
Keywords: /online/agentStatus, endpoint, URL pattern, current status  
Priority: High

**Line 1009:** Feature: Online groupsOnlineLoad endpoint URL pattern  
Keywords: /online/groupsOnlineLoad, endpoint, URL pattern, group metrics  
Priority: High

### Terms and Definitions Features

**Line 227:** Feature: Service functional unit definition  
Keywords: service, functional unit, contact center, customer contacts, topic, channel  
Priority: High

**Line 228:** Feature: Group subordinate functional unit definition  
Keywords: group, subordinate, functional unit, specialized contacts, queue, project, channel, skill  
Priority: High

**Line 229:** Feature: User account definition  
Keywords: user account, employee, user account definition  
Priority: Medium

**Line 230:** Feature: Integration service definition  
Keywords: IS, WFM CC, integration service, system integration  
Priority: Medium

**Line 231:** Feature: External system definition  
Keywords: external system, WFM CC integration, third-party system  
Priority: Medium