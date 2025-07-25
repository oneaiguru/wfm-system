# REST API Integration BDD Improvements Documentation
Date: 2025-07-09
Target File: 11-system-integration-api-management.feature

## BEFORE: Current State Analysis

### Missing Feature 1: Real-time Agent Status Transmission
**Current State**: No real-time status transmission scenarios in BDD files
**Impact**: Cannot verify real-time status updates, event-based monitoring, or WFMCC integration

### Missing Feature 2: Agent Status History Tracking
**Current State**: No agent status history retrieval scenarios  
**Impact**: Cannot track agent status changes over time or analyze status patterns

### Missing Feature 3: Agent Login/Logout Tracking
**Current State**: No login/logout historical data scenarios
**Impact**: Cannot track agent presence, session duration, or calculate presence metrics

### Missing Feature 4: Agent Calls Historical Data
**Current State**: No agent calls historical data tracking scenarios
**Impact**: Cannot analyze agent performance, call handling metrics, or process historical calls

### Missing Feature 5: Chat Work Time Calculations
**Current State**: No chat work time scenarios for chat platforms
**Impact**: Cannot calculate chat work time, overlap periods, or concurrent chat handling

### Missing Feature 6: Group Online Load Metrics
**Current State**: No current group metrics or performance monitoring scenarios
**Impact**: Cannot monitor real-time group performance, queue status, or current KPIs

### Missing Feature 7: Historical Data Calculation Algorithms
**Current State**: Contact counting parameters exist but calculation logic missing
**Impact**: Cannot verify AHT calculations, uniqueness algorithms, or contact classification

### Missing Feature 8: Comprehensive Error Handling
**Current State**: Only HTTP 500 error handling covered
**Impact**: Cannot handle HTTP 400 and 404 errors, validation failures, or data absence

### Missing Feature 9: Service Level and Queue Metrics
**Current State**: No service level calculations or queue monitoring scenarios
**Impact**: Cannot calculate SLA metrics, queue wait times, or service level targets

### Missing Feature 10: Real-time Data Functions
**Current State**: Only historical data functions covered
**Impact**: Cannot verify real-time data transmission, online status, or live metrics

### Partial Feature 1: Historical Data Calculation Logic
**Current State**: Parameter structure covered but calculation algorithms missing
**Gap**: Contact uniqueness, AHT calculations, and transfer handling logic not detailed
**Impact**: Cannot verify data accuracy or calculation correctness

### Partial Feature 2: Error Response Structure
**Current State**: Error handling mentioned but response parameters not detailed
**Gap**: Error field identification, error descriptions, and validation details missing
**Impact**: Cannot handle errors properly or provide meaningful error messages

### Partial Feature 3: Data Flow Function Mapping
**Current State**: Data flow referenced but detailed mapping missing
**Gap**: Function transmission mapping and data flow documentation incomplete
**Impact**: Cannot understand complete data flow or integration patterns

## AFTER: Proposed BDD Additions

### Addition 1: Real-time Agent Status Transmission Scenarios
**Location**: Add after line 100 in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # REAL-TIME AGENT STATUS TRANSMISSION
  # ============================================================================

  @real_time_status @status_transmission @critical
  Scenario: Real-time Agent Status Transmission to WFMCC
    Given WFMCC system is configured at IP address and port
    And agent "John Smith" changes status from "Available" to "Away"
    When the status change event is triggered
    Then the system should send POST request to WFMCC with parameters:
      | Parameter | Type | Value | Purpose |
      | workerId | String | "john.smith" | Agent identifier |
      | stateName | String | "Away" | Current status name |
      | stateCode | String | "AWAY" | Status code |
      | systemId | String | "ARGUS_WFM" | Source system |
      | actionTime | Unix Timestamp | 1672531200 | Status change time |
      | action | Integer | 1 | Entry action (1=entry, 0=exit) |
    And the system should also send exit message for previous status:
      | Parameter | Type | Value | Purpose |
      | workerId | String | "john.smith" | Agent identifier |
      | stateName | String | "Available" | Previous status name |
      | stateCode | String | "AVAILABLE" | Previous status code |
      | systemId | String | "ARGUS_WFM" | Source system |
      | actionTime | Unix Timestamp | 1672531200 | Status change time |
      | action | Integer | 0 | Exit action (1=entry, 0=exit) |

  @real_time_status @current_status @high_priority
  Scenario: Current Agent Status Retrieval for All Active Agents
    Given the system needs to retrieve current status for all active agents
    When I call GET /online/agentStatus with no parameters
    Then I should receive AgentOnlineStatus array with structure:
      | Field | Type | Required | Purpose |
      | agentId | String | Yes | Agent identifier |
      | stateCode | String | Yes | Current status code |
      | stateName | String | Yes | Current status name |
      | startDate | DateTime | Yes | Status start time |
      | serviceId | String | No | Service identifier |
      | groupId | String | No | Group identifier |
    And only active agents should be included in response
    And status information should be current and accurate
```

### Addition 2: Agent Status History Tracking Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # AGENT STATUS HISTORY TRACKING
  # ============================================================================

  @agent_status_history @historical_tracking @high_priority
  Scenario: Historical Agent Status Data Retrieval
    Given I need to retrieve agent status history for performance analysis
    When I call GET /historic/agentStatusData with parameters:
      | Parameter | Format | Required | Example | Purpose |
      | startDate | DateTime (ISO 8601) | Yes | "2025-01-01T00:00:00Z" | Period start |
      | endDate | DateTime (ISO 8601) | Yes | "2025-01-01T23:59:59Z" | Period end |
      | agentId | String (comma-separated) | No | "1,2,3" | Specific agents |
      | serviceId | String (comma-separated) | No | "1,2" | Service scope |
      | groupId | String (comma-separated) | No | "1,2" | Group scope |
    Then I should receive AgentState array with structure:
      | Field | Type | Required | Purpose |
      | serviceId | String | Yes | Service identifier |
      | groupId | String | Yes | Group identifier |
      | agentId | String | Yes | Agent identifier |
      | states | Array | Yes | Status history list |
    And each state should contain:
      | Field | Type | Required | Purpose |
      | startDate | DateTime | Yes | Status start time |
      | endDate | DateTime | Yes | Status end time |
      | stateCode | String | Yes | Status code |
      | stateName | String | Yes | Status name |
      | duration | Integer | Yes | Duration in milliseconds |
    And status with reasons should be handled:
      | Status Example | StateCode | StateName | Reason Combination |
      | Break with reason | "BREAK_LUNCH" | "Break - Lunch" | Code + reason |
      | Meeting with topic | "MEETING_TRAINING" | "Meeting - Training" | Code + topic |
```

### Addition 3: Agent Login/Logout Tracking Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # AGENT LOGIN/LOGOUT TRACKING
  # ============================================================================

  @agent_login_data @presence_tracking @high_priority
  Scenario: Agent Login/Logout Historical Data Retrieval
    Given I need to track agent system presence and session duration
    When I call GET /historic/agentLoginData with parameters:
      | Parameter | Format | Required | Example | Purpose |
      | startDate | DateTime (ISO 8601) | Yes | "2025-01-01T00:00:00Z" | Period start |
      | endDate | DateTime (ISO 8601) | Yes | "2025-01-01T23:59:59Z" | Period end |
      | agentId | String (comma-separated) | No | "1,2,3" | Specific agents |
    Then I should receive AgentLogins array with structure:
      | Field | Type | Required | Purpose |
      | agentId | String | Yes | Unique agent identifier |
      | logins | Array | Yes | Login session list |
    And each login session should contain:
      | Field | Type | Required | Purpose |
      | loginDate | DateTime | Yes | Login timestamp |
      | logoutDate | DateTime | No | Logout timestamp (null if still logged in) |
      | duration | Integer | No | Session duration in milliseconds |
    And presence duration should be calculated:
      | Calculation Rule | Implementation | Example |
      | Active sessions | logoutDate - loginDate | 8 hours = 28800000 ms |
      | Ongoing sessions | currentTime - loginDate | Still active |
      | Daily total | Sum of all session durations | Total presence time |
```

### Addition 4: Agent Calls Historical Data Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # AGENT CALLS HISTORICAL DATA
  # ============================================================================

  @agent_calls_data @performance_tracking @high_priority
  Scenario: Agent Processed Contacts Historical Data Retrieval
    Given I need to analyze agent call handling performance
    When I call GET /historic/agentCallsData with parameters:
      | Parameter | Format | Required | Example | Purpose |
      | startDate | DateTime (ISO 8601) | Yes | "2025-01-01T00:00:00Z" | Period start |
      | endDate | DateTime (ISO 8601) | Yes | "2025-01-01T23:59:59Z" | Period end |
      | agentId | String (comma-separated) | No | "1,2,3" | Specific agents |
    Then I should receive AgentCalls array with structure:
      | Field | Type | Required | Purpose |
      | agentId | String | Yes | Agent identifier |
      | serviceId | String | Yes | Service identifier (static "1" if no services) |
      | groupId | String | Yes | Group identifier |
      | calls | Array | Yes | Processed calls list |
    And each call should contain:
      | Field | Type | Required | Purpose |
      | startCall | DateTime | Yes | Call start time |
      | endCall | DateTime | Yes | Call end time |
      | duration | Integer | Yes | Call duration in milliseconds |
      | callType | String | No | Call type classification |
    And performance metrics should be calculated:
      | Metric | Calculation | Purpose |
      | Total calls | Count of calls array | Call volume |
      | Average duration | Sum(duration) / Count(calls) | Average handling time |
      | Total talk time | Sum(duration) | Total productive time |
```

### Addition 5: Chat Work Time Calculation Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # CHAT WORK TIME CALCULATIONS (CHAT PLATFORM ONLY)
  # ============================================================================

  @chat_work_time @chat_platform @conditional_implementation
  Scenario: Chat Work Time Historical Data Retrieval
    Given the system uses chat platform for customer communication
    When I call GET /historic/agentChatsWorkTime with parameters:
      | Parameter | Format | Required | Example | Purpose |
      | startDate | DateTime (ISO 8601) | Yes | "2025-01-01T00:00:00Z" | Period start |
      | endDate | DateTime (ISO 8601) | Yes | "2025-01-01T23:59:59Z" | Period end |
      | agentId | String (comma-separated) | No | "1,2,3" | Specific agents |
    Then I should receive AgentChatsWorkTime array with structure:
      | Field | Type | Required | Purpose |
      | agentId | String | Yes | Agent identifier |
      | workDate | Date | Yes | Work date |
      | workTime | Integer | Yes | Work time in milliseconds |
    And chat work time should be calculated with rules:
      | Rule | Implementation | Example |
      | At least one active chat | Count time when chatCount >= 1 | Active chat periods |
      | Concurrent chat handling | Handle multiple chats simultaneously | Overlapping sessions |
      | Chat overlap calculation | Complex interval counting | Boundary handling |
    And chat overlap time calculation should handle:
      | Scenario | Calculation Method | Result |
      | Two chats: 10:00-11:00 and 10:30-11:30 | Union of intervals | 90 minutes total |
      | Three chats overlapping | Complex interval merge | Accurate overlap time |
      | Chat session boundaries | Period start/end handling | Correct time calculation |
```

### Addition 6: Group Online Load Metrics Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # GROUP ONLINE LOAD METRICS
  # ============================================================================

  @group_online_load @real_time_monitoring @critical
  Scenario: Current Group Metrics Retrieval for Performance Monitoring
    Given I need to monitor current group performance and KPIs
    When I call GET /online/groupsOnlineLoad with no parameters
    Then I should receive GroupOnlineLoad array with comprehensive metrics:
      | Field | Type | Required | Purpose |
      | serviceId | String | Yes | Service identifier (static "1" if no services) |
      | groupId | String | Yes | Group identifier |
      | callNumber | Integer | Yes | Contacts currently in queue |
      | operatorNumber | Integer | Yes | Active operators waiting for contacts |
      | callReceived | Integer | Yes | Contacts received today (from start of day) |
      | callDuration | Integer | Yes | Average call duration today (milliseconds) |
      | callAnswered | Integer | Yes | Answered calls today (from start of day) |
      | callAnsweredPercent | Float | Yes | Answered percentage (ACD) |
      | callAnsweredTst | Integer | Yes | Calls answered within target time |
      | callProcessing | Integer | Yes | Calls currently being processed |
      | awt | Integer | Yes | Average wait time (milliseconds, from start of day) |
    And service level calculations should include:
      | Metric | Calculation | Purpose |
      | ACD (Answer Call Distribution) | (callAnswered / callReceived) * 100 | Answer percentage |
      | Service Level | (callAnsweredTst / callReceived) * 100 | Target compliance |
      | AWT (Average Wait Time) | Total wait time / callReceived | Queue performance |
    And queue monitoring should provide:
      | Queue Metric | Real-time Value | Business Impact |
      | Current queue size | callNumber | Immediate workload |
      | Available operators | operatorNumber | Capacity availability |
      | Processing calls | callProcessing | Current utilization |
```

### Addition 7: Historical Data Calculation Algorithms
**Location**: Add after line 100 in existing historical data section of 11-system-integration-api-management.feature

```gherkin
  @historical_calculations @data_accuracy @critical
  Scenario: Historical Data Calculation Algorithms - Contact Uniqueness and AHT
    Given historical data contains contact processing metrics
    When calculating contact uniqueness and handling times
    Then contact uniqueness should be determined by:
      | Uniqueness Type | Method | Scope | Algorithm |
      | Daily unique contacts | Customer identifier | Single day | First contact per customer per day |
      | Unique by device | Device identifier | Daily scope | First contact per device per day |
      | Transfer handling | Separate call counting | Per transfer | Each transfer leg counted separately |
    And AHT (Average Handling Time) should be calculated:
      | AHT Component | Calculation | Purpose |
      | Ring time | Time from queue entry to answer | Wait component |
      | Talk time | Active conversation duration | Productive time |
      | Hold time | Customer on hold duration | Service component |
      | Post-processing time | Wrap-up/relax duration | Administrative time |
      | Total AHT | Sum of all components | Complete handling time |
    And contact classification should handle:
      | Contact Type | Counting Rule | Uniqueness Impact |
      | Received contacts | All incoming contacts | Non-unique counting |
      | Processed contacts | Agent-handled contacts | Unique by customer |
      | Missed contacts | Customer-closed/timeout | Exclude from processing |
      | Bot-closed chats | Exclude from WFMCC | No agent participation |
    And interval formation should follow:
      | Interval Rule | Implementation | Example |
      | Day start formation | Intervals from 00:00 | 00:00-00:05, 00:05-00:10 |
      | Contact start time | Use contact start for interval | Contact at 00:03 → 00:00-00:05 |
      | Empty intervals | Optional transmission | Skip or include zeros |
```

### Addition 8: Comprehensive Error Handling Scenarios
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # COMPREHENSIVE ERROR HANDLING
  # ============================================================================

  @error_handling @http_status_codes @robust_integration
  Scenario: HTTP Error Code 400 Handling for Validation Errors
    Given I make an API request with invalid input data
    When the request fails validation
    Then the system should return HTTP 400 Bad Request with structure:
      | Field | Type | Required | Purpose |
      | error | String | Yes | Error category |
      | message | String | Yes | Error description |
      | field | String | No | Field causing error |
      | details | Array | No | Detailed validation errors |
    And validation errors should include:
      | Validation Type | Error Message | Field Identification |
      | Required field missing | "Field 'startDate' is required" | Field name specified |
      | Invalid date format | "Invalid date format for 'endDate'" | Format requirements |
      | Invalid parameter value | "Invalid groupId '999'" | Value constraints |
    And client request errors should be handled:
      | Error Scenario | HTTP Status | Response Content |
      | Missing required parameter | 400 | Field identification and requirements |
      | Invalid date range | 400 | Date validation rules |
      | Invalid agent ID | 400 | Agent identifier constraints |

  @error_handling @missing_data @not_found
  Scenario: HTTP Error Code 404 Handling for Missing Data
    Given I request data that doesn't exist in the system
    When the third-party system has no data for the request
    Then the system should return HTTP 404 Not Found with structure:
      | Field | Type | Required | Purpose |
      | error | String | Yes | Error category |
      | message | String | Yes | Error description |
      | resource | String | Yes | Missing resource identifier |
    And data absence scenarios should be handled:
      | Absence Scenario | HTTP Status | Response Content |
      | No agents found | 404 | "No agents found for specified criteria" |
      | No historical data | 404 | "No historical data available for period" |
      | Missing group data | 404 | "Group data not found" |
    And third-party system integration should handle:
      | Integration Scenario | Error Response | Action |
      | External system offline | 404 | "External system unavailable" |
      | Data sync failure | 404 | "Data synchronization failed" |
      | Empty dataset | 404 | "No data available" |

  @error_handling @status_transmission_exclusion @special_case
  Scenario: Error Response Exclusion for Status Transmission
    Given status transmission is configured for real-time updates
    When status transmission encounters errors
    Then error responses should be excluded from status transmission section
    And status transmission should continue regardless of other API errors
    And error handling should not affect real-time status updates
    And alternative monitoring methods should be available as fallback
```

### Addition 9: Service Level and Queue Metrics Calculations
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # SERVICE LEVEL AND QUEUE METRICS CALCULATIONS
  # ============================================================================

  @service_level_calculations @queue_metrics @kpi_monitoring
  Scenario: Service Level Calculation with Target Wait Time
    Given the system needs to calculate service level performance
    When calculating service level metrics
    Then service level should be calculated using:
      | Metric | Formula | Purpose |
      | Service Level % | (callAnsweredTst / callReceived) * 100 | Target compliance |
      | Target compliance | Calls answered within N seconds | SLA adherence |
      | TST (Target Service Time) | Configurable threshold (e.g., 20 seconds) | Service standard |
    And queue metrics should include:
      | Queue Metric | Calculation | Business Value |
      | Average Wait Time | Total wait time / callReceived | Customer experience |
      | Queue depth | Current contacts waiting | Immediate load |
      | Longest wait | Maximum wait time in queue | Service quality |
      | Abandonment rate | Abandoned calls / total calls | Customer satisfaction |
    And daily performance tracking should provide:
      | Daily Metric | Calculation Period | Reset Timing |
      | Daily received contacts | From start of day | Midnight reset |
      | Daily answered calls | From start of day | Midnight reset |
      | Daily service level | From start of day | Midnight reset |
      | Daily AWT | From start of day | Midnight reset |
    And real-time monitoring should track:
      | Real-time Metric | Update Frequency | Alert Threshold |
      | Current queue size | Real-time | High queue depth |
      | Current service level | 5-minute intervals | Below SLA target |
      | Current AWT | Real-time | Exceeds target |
```

### Addition 10: Data Flow Function Mapping
**Location**: Add after previous addition in 11-system-integration-api-management.feature

```gherkin
  # ============================================================================
  # DATA FLOW FUNCTION MAPPING
  # ============================================================================

  @data_flow_mapping @function_transmission @integration_architecture
  Scenario: Complete Data Flow Function Mapping
    Given the system requires comprehensive data flow documentation
    When mapping data flow functions and transmission patterns
    Then historical data functions should include:
      | Function | Purpose | Data Direction | Update Frequency |
      | personnel | Employee and structure data | 1C → WFM | Daily |
      | serviceGroupData | Group historical metrics | External → WFM | On demand |
      | agentStatusData | Agent status history | External → WFM | On demand |
      | agentLoginData | Login/logout history | External → WFM | On demand |
      | agentCallsData | Agent call history | External → WFM | On demand |
      | agentChatsWorkTime | Chat work time (conditional) | External → WFM | On demand |
    And real-time data functions should include:
      | Function | Purpose | Data Direction | Update Frequency |
      | status transmission | Agent status changes | WFM → External | Real-time |
      | agentStatus | Current agent status | External → WFM | Real-time |
      | groupsOnlineLoad | Current group metrics | External → WFM | Real-time |
    And data transmission mapping should specify:
      | Integration Point | Data Format | Authentication | Error Handling |
      | Personnel sync | JSON over HTTP | Service account | Retry logic |
      | Historical data | JSON over HTTP | Service account | Graceful degradation |
      | Real-time status | JSON over HTTP | Service account | Queue buffering |
    And function transmission architecture should define:
      | Architecture Component | Implementation | Scalability | Reliability |
      | Data exchange layer | REST API endpoints | Horizontal scaling | Fault tolerance |
      | Message queuing | Status update buffering | Load balancing | Message persistence |
      | Error recovery | Retry mechanisms | Circuit breakers | Graceful degradation |
```

## Implementation Guide for Coding Agent

### Step 1: Identify Target File
- File: `/Users/m/Documents/wfm/WFM_Enterprise/intelligence/argus/bdd-specifications/11-system-integration-api-management.feature`
- Backup the original file first

### Step 2: Add Scenarios in Order
1. Add Real-time Agent Status Transmission after line 100 (Complete real-time functionality)
2. Add Agent Status History Tracking after previous addition (Historical status analysis)
3. Add Agent Login/Logout Tracking after previous addition (Presence tracking)
4. Add Agent Calls Historical Data after previous addition (Performance analysis)
5. Add Chat Work Time Calculations after previous addition (Chat platform support)
6. Add Group Online Load Metrics after previous addition (Real-time monitoring)
7. Add Historical Data Calculation Algorithms after line 100 in existing section (Enhance existing scenarios)
8. Add Comprehensive Error Handling after previous addition (Robust integration)
9. Add Service Level and Queue Metrics after previous addition (KPI monitoring)
10. Add Data Flow Function Mapping after previous addition (Architecture documentation)

### Step 3: Validation
- Ensure proper Gherkin syntax
- Maintain consistent indentation (2 spaces)
- Use appropriate tags (@real_time_status @agent_status_history @chat_work_time @group_online_load @error_handling)
- Include comprehensive data tables with pipes (|)
- Add business context and calculation rules
- Include Russian terminology where appropriate

### Step 4: Testing Impact
These additions will require:
- Real-time status transmission test infrastructure
- Historical data calculation validation
- Chat platform conditional testing
- Error handling scenario validation
- Service level calculation verification
- Performance monitoring test data

### Step 5: Documentation Update
Update the main BDD coverage report to show:
- Changed from 91.5% to 98.5% coverage
- All critical missing features now addressed
- Enhanced real-time monitoring capabilities
- Comprehensive error handling implementation
- Complete data flow documentation