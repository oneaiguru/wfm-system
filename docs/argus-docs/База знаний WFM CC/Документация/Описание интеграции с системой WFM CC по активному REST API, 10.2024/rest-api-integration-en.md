# ARGUS WFM CC System - REST API Integration Documentation

## Table of Contents

[Approval Sheet](#approval-sheet)

[Change Registration Sheet](#change-registration-sheet)

[1. Terms and Definitions](#1-terms-and-definitions)

[2. Architectural Description of Integration](#2-architectural-description-of-integration)

[2.1. Brief Solution Description](#21-brief-solution-description)

[2.2. Data Exchange Schema](#22-data-exchange-schema)

[2.3. Data Flow Description](#23-data-flow-description)

[3. Description of Integration Methods for Obtaining Historical Data](#3-description-of-integration-methods-for-obtaining-historical-data)

[3.1. Personnel Retrieval - personnel](#31-personnel-retrieval---personnel)

[3.1.1. General Method Description](#311-general-method-description)

[3.1.2. Integration Method Description](#312-integration-method-description)

[3.1.2.1. Request URL](#3121-request-url)

[3.1.2.2. Request Parameters](#3122-request-parameters)

[3.1.2.3. Response Parameters](#3123-response-parameters)

[3.1.2.3.1. Service Object Description](#31231-service-object-description)

[3.1.2.3.1.1. serviceGroups Parameter Description](#312311-servicegroups-parameter-description)

[3.1.2.3.2. Agent Object Description](#31232-agent-object-description)

[3.1.2.3.2.1. agentGroups Parameter Description](#312321-agentgroups-parameter-description)

[3.1.3. Response Example](#313-response-example)

[3.2. Historical Data Retrieval by Groups - serviceGroupData](#32-historical-data-retrieval-by-groups---servicegroupdata)

[3.2.1. General Method Description](#321-general-method-description)

[3.2.2. Integration Method Description](#322-integration-method-description)

[3.2.2.1. Request URL](#3221-request-url)

[3.2.2.2. Request Parameters](#3222-request-parameters)

[3.2.2.2.1. Query Parameters](#32221-query-parameters)

[3.2.2.3. Response Parameters](#3223-response-parameters)

[3.2.2.3.1. ServiceGroupHistoricData Object Description](#32231-servicegrouphistoricdata-object-description)

[3.2.2.3.1.1. HistoricData Parameter Description](#322311-historicdata-parameter-description)

[3.2.3. Request Example](#323-request-example)

[3.2.4. Response Example](#324-response-example)

[3.3. Historical Data Retrieval for Agent Status Changes - agentStatusData](#33-historical-data-retrieval-for-agent-status-changes---agentstatusdata)

[3.3.1. General Method Description](#331-general-method-description)

[3.3.2. Integration Method Description](#332-integration-method-description)

[3.3.2.1. Request URL](#3321-request-url)

[3.3.2.2. Request Parameters](#3322-request-parameters)

[3.3.2.2.1. Query Parameters](#33221-query-parameters)

[3.3.2.3. Response Parameters](#3323-response-parameters)

[3.3.2.3.1. AgentState Object Description](#33231-agentstate-object-description)

[3.3.2.3.1.1. states Parameter Description](#332311-states-parameter-description)

[3.3.3. Request Example](#333-request-example)

[3.3.4. Response Example](#334-response-example)

[3.4. Historical Data Retrieval for Agent Login/Logout - agentLoginData](#34-historical-data-retrieval-for-agent-loginlogout---agentlogindata)

[3.4.1. General Method Description](#341-general-method-description)

[3.4.2. Integration Method Description](#342-integration-method-description)

[3.4.2.1. Request URL](#3421-request-url)

[3.4.2.2. Request Parameters](#3422-request-parameters)

[3.4.2.2.1. Query Parameters](#34221-query-parameters)

[3.4.2.3. Response Parameters](#3423-response-parameters)

[3.4.2.3.1. AgentLogins Object Description](#34231-agentlogins-object-description)

[3.4.2.3.1.1. Logins Parameter Description](#342311-logins-parameter-description)

[3.4.3. Request Example](#343-request-example)

[3.4.4. Response Example](#344-response-example)

[3.5. Historical Data Retrieval for Agent Processed Contacts - agentCallsData](#35-historical-data-retrieval-for-agent-processed-contacts---agentcallsdata)

[3.5.1. General Method Description](#351-general-method-description)

[3.5.2. Integration Method Description](#352-integration-method-description)

[3.5.2.1. Request URL](#3521-request-url)

[3.5.2.2. Request Parameters](#3522-request-parameters)

[3.5.2.2.1. Query Parameters](#35221-query-parameters)

[3.5.2.3. Response Parameters](#3523-response-parameters)

[3.5.2.3.1. AgentCalls Object Description](#35231-agentcalls-object-description)

[3.5.2.3.1.1. agentCalls Parameter Description](#352311-agentcalls-parameter-description)

[3.5.3. Request Example](#353-request-example)

[3.5.4. Response Example](#354-response-example)

[3.6. Historical Data Retrieval for Chat Work Time - agentChatsWorkTime (Chat Platform Only)](#36-historical-data-retrieval-for-chat-work-time---agentchatsworktime-chat-platform-only)

[3.6.1. General Method Description](#361-general-method-description)

[3.6.2. Integration Method Description](#362-integration-method-description)

[3.6.2.1. Request URL](#3621-request-url)

[3.6.2.2. Request Parameters](#3622-request-parameters)

[3.6.2.2.1. Query Parameters](#36221-query-parameters)

[3.6.2.3. Response Parameters](#3623-response-parameters)

[3.6.2.3.1. AgentChatsWorkTime Object Description](#36231-agentchatsworktime-object-description)

[3.6.3. Request Example](#363-request-example)

[3.6.4. Response Example](#364-response-example)

[4. Description of Integration Methods for Real-Time Data](#4-description-of-integration-methods-for-real-time-data)

[4.1. Current Agent Status Transmission from External System to WFMCC](#41-current-agent-status-transmission-from-external-system-to-wfmcc)

[4.1.1. General Method Description](#411-general-method-description)

[4.1.2. Integration Method Description](#412-integration-method-description)

[4.1.2.1. Request URL](#4121-request-url)

[4.1.2.2. Request Parameters](#4122-request-parameters)

[4.1.3. Request Example](#413-request-example)

[4.2. Current Agent Status Retrieval - agentStatus](#42-current-agent-status-retrieval---agentstatus)

[4.2.1. General Method Description](#421-general-method-description)

[4.2.2. Integration Method Description](#422-integration-method-description)

[4.2.2.1. Request URL](#4221-request-url)

[4.2.2.2. Request Parameters](#4222-request-parameters)

[4.2.2.3. Response Parameters](#4223-response-parameters)

[4.2.2.3.1. AgentOnlineStatus Object Description](#42231-agentonlinestatus-object-description)

[4.2.3. Response Example](#423-response-example)

[4.3. Current Group Metrics Retrieval - groupsOnlineLoad](#43-current-group-metrics-retrieval---groupsonlineload)

[4.3.1. General Method Description](#431-general-method-description)

[4.3.2. Integration Method Description](#432-integration-method-description)

[4.3.2.1. Request URL](#4321-request-url)

[4.3.2.2. Request Parameters](#4322-request-parameters)

[4.3.2.2.1. Query Parameters](#43221-query-parameters)

[4.3.2.3. Response Parameters](#4323-response-parameters)

[4.3.2.3.1. GroupOnlineLoad Object Description](#43231-grouponlineload-object-description)

[4.3.3. Request Example](#433-request-example)

[4.3.4. Response Example](#434-response-example)

[5. Integration Error Description](#5-integration-error-description)

[5.1. Error Code - 500](#51-error-code---500)

[5.2. Error Code - 404](#52-error-code---404)

[5.3. Error Code - 400](#53-error-code---400)

## Approval Sheet

| Position | Name | Signature | Date | Comments |
|----------|------|-----------|------|----------|
|          |      |           |      |          |
|          |      |           |      |          |
|          |      |           |      |          |

## Change Registration Sheet

| Version | Date | Developer | Changes |
|---------|------|-----------|---------|
|         |      |           |         |

## 1. Terms and Definitions

| Term | Definition |
|------|------------|
| Service | Functional unit of the contact center that handles customer contacts by topic through a specific channel (chat, inbound voice, outbound voice, email) |
| Group | Functional unit of the contact center that is subordinate to a service, handling specialized contacts within the general service topic. In external systems this may be a queue, project, channel, skill, etc. |
| User Account | Employee user account |
| IS | WFM CC system integration service |
| External System | System with which WFM CC system integration is performed |

## 2. Architectural Description of Integration

### 2.1. Brief Solution Description

For integration with external systems, a solution based on a universal integration service is provided. The interaction between IS and the third-party system must be implemented using the REST architectural style. As the data type sent to the client (Produces annotation), "application/json" must be used.

### 2.2. Data Exchange Schema

![Integration Architecture](img/integration_architecture_diagram.png)

### 2.3. Data Flow Description

| Flow Number | Data Flow Description | Functions Transmitting Data |
|-------------|----------------------|---------------------------|
| 1 | Request-transmission of historical data | personnel - retrieving contact center functional structure (services, groups, user accounts)<br>serviceGroupData - retrieving historical data by groups for forecasting<br>agentStatusData - retrieving data on time spent in contact center statuses by agents within groups<br>agentLoginData - retrieving login/logout/time spent in contact center data by agents<br>agentCallsData - retrieving information about contacts processed by agents for individual agent accounts<br>agentChatsWorkTime - retrieving historical data on time spent in system with at least one chat |
| 2 | Request-transmission of online data | status - transmitting current employee status<br>agentStatus - retrieving online agent statuses<br>groupsOnlineLoad - retrieving online load |

## 3. Description of Integration Methods for Obtaining Historical Data

### 3.1. Personnel Retrieval - personnel

#### 3.1.1. General Method Description

The method is designed to retrieve services, groups, and employee user accounts. If the external system lacks the concept of "service", a static service value must be transmitted:

1. id - External system name
2. name - External system name  
3. status - "ACTIVE"

In case of a static service value, all external system groups belong to this service.

#### 3.1.2. Integration Method Description

Request type: GET

##### 3.1.2.1. Request URL

The request URL should have the following format:

| /personnel |
|------------|

##### 3.1.2.2. Request Parameters

This method has no input parameters.

##### 3.1.2.3. Response Parameters

Upon successful request processing (code '200'), the following parameters should be returned in the response body:

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| services | List of services present in the system | Data type: array | Yes | - |  |
| agents | List of employees present in the system | Data type: array | No | - |  |

The services parameter contains a list of Service objects.
The agents parameter contains a list of Agent objects.

##### 3.1.2.3.1. Service Object Description

This parameter contains information about services and their constituent groups.

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| id | Unique service identifier | Data type: string | Yes | External system |  |
| name | Service name | Data type: string | Yes | External system |  |
| status | Service status | Data type: string | Yes | Allowed values:<br>- ACTIVE<br>- INACTIVE |  |
| serviceGroups | List of groups within the service | Data type: array | No | - |  |

The status parameter uses the enum property.

##### 3.1.2.3.1.1. serviceGroups Parameter Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| id | Unique group identifier | Data type: string | Yes | 1 |  |
| name | Group name | Data type: string | Yes | Individual Support |  |
| status | Group status | Data type: string | Yes | Allowed values:<br>- ACTIVE<br>- INACTIVE |  |
| channelType | Channel type | Data type: string | No | CHATS,MAILS,INCOMING_CALLS,OUTGOING_CALLS |  |

The status parameter uses the enum property.

##### 3.1.2.3.2. Agent Object Description

This parameter contains information about employee user accounts registered in the external system.

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| id | Unique employee user account identifier | Data type: string | Yes | 1 |  |
| name | Employee name or user account name | Data type: string | Yes | John |  |
| surname | Employee surname | Data type: string | No | Smith |  |
| secondName | Employee middle name | Data type: string | No | William |  |
| agentNumber | Employee personnel number | Data type: string | No | 230-15 |  |
| agentGroups | List of groups the employee processes | Data type: array | Yes | 12345 |  |
| loginSSO | Agent login in SSO class system | Data type: array | No | j.smith |  |

If the system stores the user account name in one database field without the ability to separate into three different fields, then the name should be transmitted in the name field. The agentGroups parameter contains lists of groups that the employee can process. Employees who lack group data are not returned in the response.

##### 3.1.2.3.2.1. agentGroups Parameter Description

The parameter contains a list of group identifiers.

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| groupId | Unique group identifier | type: string | Yes | 1 |  |

#### 3.1.3. Response Example

```json
{
  "services": [
    {
      "id": "External system",
      "name": "External system",
      "status": "ACTIVE",
      "serviceGroups": [
        {
          "id": "1",
          "name": "Individual Support",
          "status": "ACTIVE"
        },
        {
          "id": "2",
          "name": "Business Support",
          "status": "ACTIVE"
        }
      ]
    }
  ],
  "agents": [
    {
      "id": "1",
      "name": "John",
      "surname": "Smith",
      "secondName": "William",
      "loginSSO": "j.smith",
      "agentGroups": [
        {
          "groupId": "1"
        }
      ]
    },
    {
      "id": "2",
      "name": "Agent123",
      "surname": " ",
      "secondName": " ",
      "agentNumber": "000123",
      "loginSSO": "000123",
      "agentGroups": [
        {
          "groupId": "1"
        },
        {
          "groupId": "2"
        }
      ]
    }
  ]
}
```

### 3.2. Historical Data Retrieval by Groups - serviceGroupData

#### 3.2.1. General Method Description

The method is designed to retrieve historical data by groups for load forecasting. Historical data should be grouped into n-minute intervals (determined by the step parameter). Determining the interval that includes a contact is based on the contact start time. Intervals should be formed from the beginning of the day for which the request was made.

For example: a request is made for the period from 2020-01-01T00:00:00Z to 2020-01-02T00:00:00Z, step parameter equals 300000 seconds (5 minutes). This means you need to calculate how many contacts fall into intervals:

2020-01-01T00:00:00Z - 2020-01-01T00:05:00Z,  
2020-01-01T00:05:00Z - 2020-01-01T00:10:00Z,  
2020-01-01T00:10:00Z - 2020-01-01T00:15:00Z, etc.

If no contacts were received in an interval, such an interval may not be transmitted.

#### 3.2.2. Integration Method Description

Request type: GET

##### 3.2.2.1. Request URL

The request URL should have the following format:

| /historic/serviceGroupData |
|----------------------------|

##### 3.2.2.2. Request Parameters

##### 3.2.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
| endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
| step | Historical data grouping step in milliseconds | Data type: integer<br>Data format: int64 | Yes | 300,000 |  |
| groupId | Group identifier for which data should be retrieved. If information is needed for multiple groups, their identifiers are listed separated by commas | Data type: string | Yes | 1,2 |  |

##### 3.2.2.3. Response Parameters

Upon successful request execution, a list of intervals for each group should be returned. The response body contains a list of ServiceGroupHistoricData objects. Each such object contains information for one service-group. Groups that lack call data in the queried period are not returned in the response.

##### 3.2.2.3.1. ServiceGroupHistoricData Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| serviceId | Unique service identifier | Data type: string | Yes | 1 |  |
| groupId | Unique group identifier | Data type: string | Yes | 1 |  |
| historicData | Historical data for service-group | Data type: array | Yes | - |  |

If the service is static, a static service identifier is transmitted.

Chats closed by bot (without agent participation) should not be transmitted to WFMCC.

##### 3.2.2.3.1.1. HistoricData Parameter Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) | Calculation Examples |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|-------------------|
| startInterval | N-minute interval start time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |  |
| endInterval | N-minute interval end time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:05:00Z |  |  |
| notUniqueReceived | Number of non-unique received contacts for the group. Calculated as: number of contacts received in N-minute interval. All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 15 |  |  |
| notUniqueTreated | Number of non-unique processed contacts for the group. Calculated as: number of contacts received in N-minute interval that were processed. All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 10 |  |  |
| notUniqueMissed | Number of non-unique lost/missed contacts for the group. Calculated as: number of contacts received in N-minute interval that were not processed (e.g., chat closed by customer). All customer contacts within the day are counted. | Data type: integer<br>Data format: int64 | Yes | 5 |  |  |
| receivedCalls | Number of unique received contacts for the group. Calculated as: number of contacts received in N-minute interval that are unique. | Data type: integer<br>Data format: int64 | Yes | 10 |  |  |
| treatedCalls | Number of unique contacts processed by agent for the group. Calculated as: number of contacts received in N-minute interval that were processed and are unique. | Data type: integer<br>Data format: int64 | Yes | 8 |  |  |
| missCalls | Number of unique lost/missed contacts for the group. Calculated as: number of contacts received in N-minute interval that were not processed and are unique. | Data type: integer<br>Data format: int64 | Yes | 2 |  | **EXAMPLE!** Within a day, two calls from one number count as 1 unique, the second non-unique. Unique calls are determined within service/group scope. If there was a transfer - count as separate call, count first call as processed. Second depends on result. |
| aht | Average handling time for the group. Calculated as: Total handling time for all processed contacts (received in N-minute interval) / number of non-unique processed contacts (received in N-minute interval). Must be transmitted in milliseconds | Data type: integer<br>Data format: int64 | Yes | 360000 |  | **EXAMPLE!** AHT time calculated as sum of: ring time + talk time + hold time<br>Agent time in status after call distribution from queue until connection with agent (ring time);<br>Agent time in status talking with customer (talk time);<br>Agent time in status holding call while searching for information/consulting supervisor (hold time); |
| postProcessing | Average post-processing time for the group. Calculated as: Total post-processing time for all processed contacts (received in N-minute interval) / number of non-unique processed contacts (received in N-minute interval). Must be transmitted in milliseconds | Data type: integer<br>Data format: int64 | Yes | 3000 |  | **EXAMPLE!** PostProcessing time calculated as sum of wrapUpDuration + relaxDuration<br>Post-call processing time (wrapUpDuration)<br>Agent time in rest status after each call (relaxDuration); |

Contact uniqueness is determined by customer identifier (if there is a customer identifier, or device identifier from which the customer contacted), the first customer contact within the day is considered unique. In calculating non-unique contacts, all contacts within the day should be counted (including unique ones).

#### 3.2.3. Request Example

```
/historic/serviceGroupData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&step=300000&groupId=1,2
```

#### 3.2.4. Response Example

```json
[
  {
    "serviceId": "1",
    "groupId": "1",
    "historicData": [
      {
        "startInterval": "2020-01-01T00:00:00Z",
        "endInterval": "2020-01-01T00:05:00Z",
        "notUniqueReceived": 15,
        "notUniqueTreated": 10,
        "notUniqueMissed": 5,
        "receivedCalls": 10,
        "treatedCalls": 8,
        "missCalls": 2,
        "aht": 360000,
        "postProcessing": 3000
      },
      {
        "startInterval": "2020-01-01T00:05:00Z",
        "endInterval": "2020-01-01T00:10:00Z",
        "notUniqueReceived": 10,
        "notUniqueTreated": 8,
        "notUniqueMissed": 2,
        "receivedCalls": 5,
        "treatedCalls": 2,
        "missCalls": 1,
        "aht": 451000,
        "postProcessing": 0
      }
    ]
  },
  {
    "serviceId": "1",
    "groupId": "2",
    "historicData": [
      {
        "startInterval": "2020-01-01T10:00:00Z",
        "endInterval": "2020-01-01T10:05:00Z",
        "notUniqueReceived": 15,
        "notUniqueTreated": 10,
        "notUniqueMissed": 5,
        "receivedCalls": 10,
        "treatedCalls": 8,
        "missCalls": 2,
        "aht": 360000,
        "postProcessing": 3000
      },
      {
        "startInterval": "2020-01-01T10:05:00Z",
        "endInterval": "2020-01-01T10:10:00Z",
        "notUniqueReceived": 10,
        "notUniqueTreated": 8,
        "notUniqueMissed": 2,
        "receivedCalls": 5,
        "treatedCalls": 2,
        "missCalls": 1,
        "aht": 451000,
        "postProcessing": 0
      }
    ]
  }
]
```

### 3.3. Historical Data Retrieval for Agent Status Changes - agentStatusData

#### 3.3.1. General Method Description

The method is designed to retrieve historical data on agent status changes. The input parameters include the period for which status information is needed, as well as the list of agents. The response should include a list of statuses for all agents from the list. The selection should include statuses whose start time or end time fall within the requested period.

Statuses can be transmitted within service-group scope. If a status cannot be linked to a group, it should be transmitted linked to all groups that the agent can process.

Alternative option - status can be transmitted without linking to group-service.

#### 3.3.2. Integration Method Description

Request type: GET

##### 3.3.2.1. Request URL

The request URL should have the following format:

| /historic/agentStatusData |
|---------------------------|

##### 3.3.2.2. Request Parameters

##### 3.3.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
| endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
| agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2 |  |

##### 3.3.2.3. Response Parameters

Upon successful request processing, a list of statuses for all agents is returned. Agents who lack statuses in the queried period are not returned in the response. Agent information is transmitted in the AgentState object.

##### 3.3.2.3.1. AgentState Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| serviceId | Unique service identifier within which the status was set | Data type: string | No | 1 |  |
| groupId | Unique group identifier within which the status was set | Data type: string | No | 1 |  |
| agentId | Unique agent identifier for whom statuses are transmitted | Data type: string | Yes | 1 |  |
| states | List of agent statuses set within the group | Data type: array | Yes | - |  |

Since the service has a static value, serviceId parameter always transmits 1.

##### 3.3.2.3.1.1. states Parameter Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Status start date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:15:36Z |  |
| endDate | Status end date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:18:36Z |  |
| stateCode | Unique status identifier | Data type: string<br>Data format: string | Yes | Break |  |
| stateName | Status name | Data type: string<br>Data format: string | Yes | Technical break |  |

If the third-party system has statuses with reasons, then stateCode should be formed from status id + reason id, and stateName should be formed from status name and reason name.

#### 3.3.3. Request Example

```
/historic/agentStatusData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2
```

#### 3.3.4. Response Example

```json
[
  {
    "serviceId": "1",
    "groupId": "1",
    "agentId": "1",
    "states": [
      {
        "startDate": "2020-01-01T10:10:36Z",
        "endDate": "2020-01-01T10:15:36Z",
        "stateCode": "Work",
        "stateName": "Contact processing"
      },
      {
        "startDate": "2020-01-01T10:15:36Z",
        "endDate": "2020-01-01T10:18:36Z",
        "stateCode": "Break",
        "stateName": "Technical break"
      }
    ]
  },
  {
    "serviceId": "1",
    "groupId": "2",
    "agentId": "1",
    "states": [
      {
        "startDate": "2020-01-01T10:18:36Z",
        "endDate": "2020-01-01T10:25:36Z",
        "stateCode": "Work",
        "stateName": "Contact processing"
      }
    ]
  }
]
```

### 3.4. Historical Data Retrieval for Agent Login/Logout - agentLoginData

#### 3.4.1. General Method Description

The method is designed to retrieve historical data on agent login/logout from the system. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of agent logins/logouts. The selection should include periods whose login time or logout time fall within the requested period.

#### 3.4.2. Integration Method Description

Request type: GET

##### 3.4.2.1. Request URL

The request URL should have the following format:

| /historic/agentLoginData |
|--------------------------|

##### 3.4.2.2. Request Parameters

##### 3.4.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
| endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
| agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2,3 |  |

##### 3.4.2.3. Response Parameters

Upon successful request processing, the response body returns a list of logins/logouts and duration of agent presence in the system. Agents who were not in the system during the queried period (did not login/logout) are not returned in the response. Agent information is transmitted in the AgentLogins object.

##### 3.4.2.3.1. AgentLogins Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
| logins | List of agent logins/logouts to the system | Data type: array | Yes | - |  |

##### 3.4.2.3.1.1. Logins Parameter Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| loginDate | Agent system login date and time, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:03:15Z |  |
| logoutDate | Agent system logout date and time, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T12:30:05Z |  |
| duration | Duration of agent presence in system, in milliseconds | Data type: integer<br>Data format: int64 | Yes | 8810000 |  |

#### 3.4.3. Request Example

```
/historic/agentLoginData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2,3
```

#### 3.4.4. Response Example

```json
[
  {
    "agentId": "1",
    "logins": [
      {
        "loginDate": "2020-01-01T10:03:15Z",
        "logoutDate": "2020-01-01T12:30:05Z",
        "duration": 8810000
      },
      {
        "loginDate": "2020-01-01T18:15:05Z",
        "logoutDate": "2020-01-01T21:32:55Z",
        "duration": 11870000
      }
    ]
  },
  {
    "agentId": "2",
    "logins": [
      {
        "loginDate": "2020-01-01T23:53:15Z",
        "logoutDate": "2020-01-02T02:30:05Z",
        "duration": 9410000
      }
    ]
  }
]
```

### 3.5. Historical Data Retrieval for Agent Processed Contacts - agentCallsData

#### 3.5.1. General Method Description

The method is designed to retrieve historical data on contacts processed by agents. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of processed contacts by agent and group. The selection includes contacts whose start time falls within the queried period.

#### 3.5.2. Integration Method Description

Request type: GET

##### 3.5.2.1. Request URL

The request URL should have the following format:

| /historic/agentCallsData |
|--------------------------|

##### 3.5.2.2. Request Parameters

##### 3.5.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
| endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-02T00:00:00Z |  |
| agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2 |  |

##### 3.5.2.3. Response Parameters

Upon successful request processing, the response body returns a list of processed contacts by agent, separated by groups. If an agent had no processed contacts in the queried period, such agent is not returned in the response. Agent information is transmitted in the AgentCalls object.

##### 3.5.2.3.1. AgentCalls Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| agentId | Unique agent identifier for whom information is transmitted | Data type: string | Yes | 1 |  |
| serviceId | Unique service identifier within which the status was set | Data type: string | Yes | 1 |  |
| groupId | Unique group identifier within which the status was set | Data type: string | Yes | 1 |  |
| agentCalls | List of processed contacts by agent within the group | Data type: array | Yes | - |  |

Since the service has a static value, serviceId parameter always transmits 1.

##### 3.5.2.3.1.1. agentCalls Parameter Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startCall | Contact processing start date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:03:15Z |  |
| endCall | Contact processing end date and time with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T10:08:15Z |  |
| duration | Contact processing time in milliseconds | Data type: integer<br>Data format: int64 | Yes | 300000 |  |

#### 3.5.3. Request Example

```
/historic/agentCallsData?startDate=2020-01-01T00:00:00Z&endDate=2020-01-02T00:00:00Z&agentId=1,2
```

#### 3.5.4. Response Example

```json
[
  {
    "agentId": "1",
    "serviceId": "1",
    "groupId": "1",
    "agentCalls": [
      {
        "startCall": "2020-01-01T10:03:15Z",
        "endCall": "2020-01-01T10:08:15Z",
        "duration": 300000
      },
      {
        "startCall": "2020-01-01T10:04:02Z",
        "endCall": "2020-01-01T10:12:15Z",
        "duration": 493000
      }
    ]
  },
  {
    "agentId": "1",
    "serviceId": "1",
    "groupId": "2",
    "agentCalls": [
      {
        "startCall": "2020-01-01T10:03:15Z",
        "endCall": "2020-01-01T10:03:45Z",
        "duration": 30000
      }
    ]
  }
]
```

### 3.6. Historical Data Retrieval for Chat Work Time - agentChatsWorkTime (Chat Platform Only)

#### 3.6.1. General Method Description

The method is designed to retrieve historical data on agent time spent in the system with at least one chat. If integration is not performed with a chat platform, this method does not require implementation. The input parameters include the period for which information is needed, as well as the list of agents. The response should include a list of days per agent during which they had working time. If the request includes multiple full days, they should be transmitted separately in the response.

Time is calculated as follows:

Count the number of seconds in a day when the agent was processing at least 1 chat. If the start or end of chat processing was outside the queried period, the interval outside the period is not counted. For example:

Request sent for period from 2020-01-01 00:00:00 to 2020-01-02 00:00:00. Agent processed chats in the following intervals: 01.01.2020 22:45:00 - 01.01.2020 23:02:00 and 22:58:00 01.01.2020 - 00:12:00 02.01.2020. As a result, for 01.01.2020 the following value should be transmitted - 4500000. The value was obtained as follows:

* interval 22:45:00 - 23:02:00 is counted in full
* from interval 22:58:00 - 00:12:00, the period 23:02:00 - 00:00:00 is counted.

Since there were 2 chats in the interval from 22:58:00 to 23:02:00, we count this interval once.

#### 3.6.2. Integration Method Description

Request type: GET

##### 3.6.2.1. Request URL

The request URL should have the following format:

| /historic/agentChatsWorkTime |
|------------------------------|

##### 3.6.2.2. Request Parameters

##### 3.6.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| startDate | Date and time of historical data period start, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-01T00:00:00Z |  |
| endDate | Date and time of historical data period end, with timezone | Data type: string<br>Data format: date-time | Yes | 2020-01-03T00:00:00Z |  |
| agentId | Agent identifier for which historical data should be retrieved. If information is needed for multiple agents, their identifiers are listed separated by commas. | Data type: string | Yes | 1,2,3 |  |

##### 3.6.2.3. Response Parameters

Upon successful request processing, date and time data for all agents is returned. Agents who lack processed chats in the queried period are not returned in the response. Agent information is transmitted in the AgentChatsWorkTime object.

##### 3.6.2.3.1. AgentChatsWorkTime Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
| workDate | Date for which time is calculated | Data type: string<br>Data format: date | Yes | 2020-01-01 |  |
| workTime | Time spent in system with at least one chat in milliseconds | Data type: integer<br>Data format: int64 | Yes | 3600000 |  |

#### 3.6.3. Request Example

```
/historic/agentChatsWorkTime?startDate=2020-01-01T00:00:00Z&endDate=2020-01-03T00:00:00Z&agentId=1,2,3
```

#### 3.6.4. Response Example

```json
[
  {
    "agentId": "1",
    "workDate": "2020-01-01",
    "workTime": 3600000
  },
  {
    "agentId": "1",
    "workDate": "2020-01-02",
    "workTime": 300000
  },
  {
    "agentId": "2",
    "workDate": "2020-01-01",
    "workTime": 54000
  }
]
```

## 4. Description of Integration Methods for Real-Time Data

### 4.1. Current Agent Status Transmission from External System to WFMCC

#### 4.1.1. General Method Description

The method is designed to transmit agent status change events. Each operator status change event is transmitted separately. For each status change event, two messages will be transmitted (first about the operator entering the status, second about the operator exiting the status). All request parameters are required and can be repeated in the request only once. Data transmission intervals are not regulated. No response from the WFMCC system is provided, including HTTP response codes. Data is sent to the WFMCC system without controlling receipt and data integrity.

If an agent is in one status and switches to another - it is necessary to send a message about exiting one status and a message about entering another status to the WFM CC system. Request initiation from the WFM CC side is not provided.

If it is impossible to implement an agent status change monitoring service and sending information by events from the chat platform side, it is necessary to implement the method - [4.2. Current Agent Status Retrieval - agentStatus](#42-current-agent-status-retrieval---agentstatus).

#### 4.1.2. Integration Method Description

Request type: POST

##### 4.1.2.1. Request URL

Status information transmission should be performed at the address:

| http://[IP:port]/ccwfm/api/rest/status |
|----------------------------------------|

where [IP:port] is the IP address and port of the WFM CC application.

##### 4.1.2.2. Request Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| workerId | Unique employee identifier | Data type: string | Yes | 1 |  |
| stateName | Status name | Data type: string | Yes | Technical break |  |
| stateCode | Unique status identifier | Data type: string | Yes | Break |  |
| systemId | System identifier for which statuses are sent. The external system name is used as identifier. | Data type: string | Yes | External system |  |
| actionTime | Status change timestamp. Transmitted in Unix Time Stamp format. | Data type: timeStamp | Yes | 1568816347 |  |
| action | Type of status change event, possible parameter values: 1 – status entry; 0 – status exit; | Data type: integer | Yes | 1 |  |

#### 4.1.3. Request Example

```json
{
  "workerId": "1",
  "stateName": "Technical break",
  "stateCode": "Break",
  "systemId": "External system",
  "actionTime": 1568816347,
  "action": 1
}
```

### 4.2. Current Agent Status Retrieval - agentStatus

#### 4.2.1. General Method Description

The method is designed to retrieve current agent status and its start time. There are no input parameters, the response should include a list of all active agents and their statuses.

#### 4.2.2. Integration Method Description

Request type: GET

##### 4.2.2.1. Request URL

The request URL should have the following format:

| /online/agentStatus |
|---------------------|

##### 4.2.2.2. Request Parameters

No input parameters.

##### 4.2.2.3. Response Parameters

Upon successful request processing, a list of active agents and their statuses is returned. Agent information is transmitted in the AgentOnlineStatus object.

##### 4.2.2.3.1. AgentOnlineStatus Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| agentId | Unique agent identifier | Data type: string | Yes | 1 |  |
| stateCode | Unique status identifier | Data type: string | Yes | Break |  |
| stateName | Status name | Data type: string | Yes | Technical break |  |
| startDate | Current status start time | Data type: string<br>Data format: date-time | Yes | 2020-01-01T15:25:13Z |  |

#### 4.2.3. Response Example

```json
[
  {
    "agentId": "1",
    "stateCode": "Break",
    "stateName": "Technical break",
    "startDate": "2020-01-01T15:25:13Z"
  },
  {
    "agentId": "2",
    "stateCode": "Work",
    "stateName": "Contact processing",
    "startDate": "2020-01-01T15:20:13Z"
  }
]
```

### 4.3. Current Group Metrics Retrieval - groupsOnlineLoad

#### 4.3.1. General Method Description

The method is designed to retrieve current group metrics for the current day. The input parameters include a list of groups. The response should include a set of metrics for each group.

#### 4.3.2. Integration Method Description

Request type: GET

##### 4.3.2.1. Request URL

The request URL should have the following format:

| /online/groupsOnlineLoad |
|--------------------------|

##### 4.3.2.2. Request Parameters

##### 4.3.2.2.1. Query Parameters

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example |
|----------------|----------------------|-------------|-------------------|--------------|
| groupId | Group identifier for which data should be retrieved. If information is needed for multiple groups, their identifiers are listed separated by commas | Data type: string | Yes | 1,2 |

##### 4.3.2.3. Response Parameters

Upon successful request execution, metrics for each group should be returned. The response body contains a list of GroupOnlineLoad objects. Each such object contains information for one service-group.

##### 4.3.2.3.1. GroupOnlineLoad Object Description

| Parameter Name | Parameter Description | Data Format | Required Parameter | Data Example | Parameter Calculation Description in Contact Center (filled by contact center/chat platform vendor) |
|----------------|----------------------|-------------|-------------------|--------------|--------------------------------------------------------------------------------------------------|
| serviceId | Unique service identifier | Data type: string | Yes | 1 |  |
| groupId | Unique group identifier | Data type: string | Yes | 1 |  |
| callNumber | Number of contacts in queue at request time | Data type: integer | Yes | 5 |  |
| operatorNumber | Number of operators working on the group, or waiting for contacts | Data type: integer | Yes | 2 |  |
| callReceived | Number of received contacts since start of day | Data type: integer | No | 100 |  |
| aht | Average talk time for the group since start of day, in milliseconds | Data type: integer | No | 360000 |  |
| acd | Percentage of answered contacts since start of day. Calculated as: Number of processed contacts / Number of received contacts | Data type: number<br>Data format: double | No | 95.0554 |  |
| awt | Average wait time for contacts in queue since start of day, in milliseconds | Data type: integer | No | 20000 |  |
| callAnswered | Number of processed calls from start of day to request time | Data type: integer | No | 100 |  |
| callAnsweredTst | Number of processed calls from start of day to request time that were waiting for agent answer no more than N seconds. Target wait time (N seconds) must be determined | Data type: integer | No | 100 |  |
| callProcessing | Number of calls being processed by agents at request time | Data type: integer | No | 100 |  |

Since the service has a static value, serviceId parameter always transmits 1.

#### 4.3.3. Request Example

```
/online/groupsOnlineLoad?groupId=1,2
```

#### 4.3.4. Response Example

```json
[
  {
    "serviceId": "1",
    "groupId": "1",
    "callNumber": 5,
    "operatorNumber": 2,
    "callReceived": 100,
    "aht": 360000,
    "acd": 95.0554,
    "awt": 20000,
    "callAnswered": 10,
    "callAnsweredTst": 1,
    "callProcessing": 1
  },
  {
    "serviceId": "1",
    "groupId": "2",
    "callNumber": 3,
    "operatorNumber": 0,
    "callReceived": 6,
    "aht": 36000,
    "acd": 100,
    "awt": 2000,
    "callAnswered": 10,
    "callAnsweredTst": 1,
    "callProcessing": 1
  }
]
```

## 5. Integration Error Description

### 5.1. Error Code - 500

Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 500. If this error occurs during request processing, a response with code "500" must be returned and the following parameters transmitted in the response body:

| Parameter Name | Parameter Description | Data Format |
|----------------|----------------------|-------------|
| field | Not used | Data type: string |
| message | Error text | Data type: string |
| description | Clear error description | Data type: string |

### 5.2. Error Code - 404

Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 404. This error occurs if the third-party system has no data for the requested parameters from WFMCC.

### 5.3. Error Code - 400

Each request (except [4.1. Current Agent Status Transmission](#41-current-agent-status-transmission-from-external-system-to-wfmcc)) provides a response for error code 400. This error occurs with incorrect data in the client request. Validation errors, input data errors, etc.

| Parameter Name | Parameter Description | Data Format |
|----------------|----------------------|-------------|
| field | Field from request where error occurred | Data type: string |
| message | Error text | Data type: string |
| description | Clear error description | Data type: string |